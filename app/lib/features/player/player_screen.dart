import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../models/conquista.dart';
import '../../models/exercicio.dart';
import '../../models/fase.dart';
import '../../models/registro_progressao.dart';
import '../../models/treino.dart';
import '../../services/checkin_repository.dart';
import '../../services/conclusao_repository.dart';
import '../../services/conquistas_repository.dart';
import '../../services/gamificacao_pref.dart';
import '../../services/progressao_repository.dart';
import '../../services/som_repository.dart';
import '../../services/treinos_repository.dart';
import '../../theme/app_colors.dart';
import '../../util/conquista_badge.dart';
import '../../util/format.dart';
import '../../util/frases.dart';
import '../../util/fundos.dart';
import '../../util/gamificacao.dart';

/// Roda o cronômetro: percorre a linha do tempo (preparação → execução × reps
/// → descanso, por série) contando segundo a segundo, com pausa, pular/voltar
/// etapa e vibração nas transições. Mantém a tela ligada. Serve tanto para o
/// treino inteiro quanto para um único exercício (basta a lista `exercicios`).
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({
    super.key,
    required this.titulo,
    required this.exercicios,
    this.treino,
  });

  final String titulo;
  final List<Exercicio> exercicios;

  /// Quando presente, esta sessão é um TREINO inteiro (não um exercício avulso)
  /// e, com a gamificação ligada, o fim pergunta se o treino foi concluído.
  final Treino? treino;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with WidgetsBindingObserver {
  late final List<Fase> _fases;
  late final int _duracaoTotal; // soma das fases, em segundos
  int _idx = 0;
  int _restanteMs = 0;
  bool _running = false;
  bool _concluido = false;
  Timer? _timer;
  final Stopwatch _sw = Stopwatch();
  int _ultimoBip = -1;
  final Set<int> _marcados = {}; // exercícios já registrados no check-in

  // Gamificação (só quando é um treino inteiro e a opção está ligada).
  bool? _respostaCompleto; // null = ainda não respondeu; true/false = respondeu
  List<TipoConquista> _novasConquistas = const []; // conquistas recém-obtidas
  String? _fraseIncompleto; // frase sorteada quando não completou

  String? _carimbo; // "Série 2/3 ✓" mostrado ao concluir uma série
  Timer? _carimboTimer;

  // POOL de players (baixa latência): reusar UM player a cada repetição curta
  // fazia o som falhar. Com vários players em rodízio, cada bip usa um livre.
  static const _nBeeps = 5;
  final List<AudioPlayer> _beeps =
      List.generate(_nBeeps, (i) => AudioPlayer(playerId: 'calis_beep$i'));
  final AudioPlayer _fim = AudioPlayer(playerId: 'calis_fim');
  int _beepIdx = 0;

  Future<void> _prepararSom() async {
    for (final p in [..._beeps, _fim]) {
      await p.setPlayerMode(PlayerMode.lowLatency);
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setVolume(1.0);
    }
  }

  /// Toca um efeito (fim de série ou bip) se o som estiver ligado.
  void _tocarSom({required bool fim}) {
    if (!(ref.read(somProvider).value ?? true)) return;
    if (fim) {
      _fim.play(AssetSource('sounds/fim.wav'));
      return;
    }
    // Rodízio: cada bip num player diferente (evita o "reuso rápido").
    final p = _beeps[_beepIdx];
    _beepIdx = (_beepIdx + 1) % _nBeeps;
    p.play(AssetSource('sounds/beep.wav'));
  }

  void _abrirAddProgressao() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddProgressaoSheet(exercicios: widget.exercicios),
    );
  }

  /// Check-in automático quando o exercício [ei] termina (uma vez por sessão).
  void _talvezMarcar(int ei) {
    if (_marcados.contains(ei)) return;
    _marcados.add(ei);
    if (ei >= 0 && ei < widget.exercicios.length) {
      ref.read(checkinProvider.notifier).registrar(widget.exercicios[ei]);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prepararSom();
    _fases = montarLinhaDoTempoDe(widget.exercicios);
    _duracaoTotal = _fases.fold(0, (a, f) => a + f.segundos);
    if (_fases.isNotEmpty) {
      _restanteMs = _fases[0].segundos * 1000;
      WidgetsBinding.instance.addPostFrameCallback((_) => _iniciar());
    }
  }

  /// Ao ir para segundo plano, pausa (o cronômetro não deve correr escondido, e
  /// isso evita o "travado" ao voltar); ao retomar, força um frame novo para o
  /// botão responder na hora.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      if (_running) _pausar();
    } else if (mounted && !_concluido) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _carimboTimer?.cancel();
    for (final p in _beeps) {
      p.dispose();
    }
    _fim.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _iniciar() {
    if (_fases.isEmpty || _concluido) return;
    WakelockPlus.enable();
    _sw
      ..reset()
      ..start();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), _tick);
    setState(() => _running = true);
  }

  void _pausar() {
    _timer?.cancel();
    _sw.stop();
    WakelockPlus.disable();
    setState(() => _running = false);
  }

  void _alternarPausa() => _running ? _pausar() : _iniciar();

  void _tick(Timer t) {
    // Limita o avanço por tick: se o app foi suspenso (tela apagada / economia
    // de bateria), o Stopwatch acumula segundos e o Timer volta com um delta
    // gigante — sem o teto, isso faz o cronômetro "pular" as fases até o fim.
    final delta = _sw.elapsedMilliseconds.clamp(0, 1000);
    _sw
      ..reset()
      ..start();
    _restanteMs -= delta;

    final segRestante = (_restanteMs / 1000).ceil();
    if (segRestante >= 1 && segRestante <= 3 && segRestante != _ultimoBip) {
      _ultimoBip = segRestante;
      HapticFeedback.lightImpact();
    }

    if (_restanteMs <= 0) {
      _avancar(auto: true);
    } else {
      setState(() {});
    }
  }

  void _avancar({bool auto = false}) {
    if (_idx >= _fases.length - 1) {
      _finalizar();
      return;
    }
    final faseTerm = _fases[_idx]; // a fase que está terminando
    final exAntes = faseTerm.exercicioIndex;
    final resto = auto ? _restanteMs : 0; // carrega o "estouro" p/ manter o ritmo
    _idx++;
    // Trocou de exercício? O anterior foi concluído -> check-in.
    if (_fases[_idx].exercicioIndex != exAntes) _talvezMarcar(exAntes);
    _ultimoBip = -1;
    _restanteMs = _fases[_idx].segundos * 1000 + resto;
    HapticFeedback.heavyImpact();
    // Última repetição da série = fim de série (som diferente); senão, bip.
    final fimDeSerie = faseTerm.tipo == FaseTipo.execucao &&
        faseTerm.rep == faseTerm.totalReps;
    _tocarSom(fim: fimDeSerie);
    if (fimDeSerie && faseTerm.totalSeries > 1) {
      _mostrarCarimbo(faseTerm.serie, faseTerm.totalSeries);
    }
    setState(() {});
  }

  /// Mostra o carimbo "Série X/Y ✓" por ~1,6s ao concluir uma série.
  void _mostrarCarimbo(int serie, int total) {
    _carimboTimer?.cancel();
    _carimbo = 'Série $serie/$total ✓';
    _carimboTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _carimbo = null);
    });
  }

  void _anterior() {
    _ultimoBip = -1;
    final gastou = _fases[_idx].segundos * 1000 - _restanteMs;
    if (gastou > 2000 || _idx == 0) {
      _restanteMs = _fases[_idx].segundos * 1000; // reinicia a etapa atual
    } else {
      _idx--;
      _restanteMs = _fases[_idx].segundos * 1000;
    }
    HapticFeedback.mediumImpact();
    setState(() {});
  }

  void _finalizar() {
    _timer?.cancel();
    _sw.stop();
    WakelockPlus.disable();
    HapticFeedback.heavyImpact();
    _tocarSom(fim: true); // som de fim marcando o término
    _talvezMarcar(_fases[_idx].exercicioIndex); // último exercício concluído
    setState(() {
      _concluido = true;
      _running = false;
    });
  }

  void _reiniciar() {
    setState(() {
      _idx = 0;
      _concluido = false;
      _ultimoBip = -1;
      _respostaCompleto = null;
      _novasConquistas = const [];
      _fraseIncompleto = null;
      _restanteMs = _fases.isEmpty ? 0 : _fases[0].segundos * 1000;
    });
    _iniciar();
  }

  /// Esta sessão pergunta "treino completo?" no fim? (Só para treino inteiro,
  /// com a gamificação ligada.)
  bool get _gamificaTreino =>
      widget.treino != null && (ref.read(gamificacaoProvider).value ?? true);

  /// "Sim, completei": registra a conclusão e avalia novas conquistas.
  Future<void> _marcarCompleto() async {
    final treino = widget.treino;
    if (treino == null) return;
    await ref.read(conclusaoProvider.notifier).registrar(treino);
    final concs = ref.read(conclusaoProvider).value ?? const [];
    final treinos = ref.read(treinosProvider).value ?? const [];
    final prog = ref.read(progressaoProvider).value ?? const [];
    final atuais = conquistasAtuais(concs, treinos, prog);
    final notifier = ref.read(conquistasProvider.notifier);
    final novas = await notifier.registrarNovas(atuais);
    await notifier.reconciliar(atuais); // move p/ histórico o que tiver caído
    if (!mounted) return;
    setState(() {
      _respostaCompleto = true;
      _novasConquistas = novas;
    });
  }

  /// "Não consegui hoje": sorteia uma frase de incentivo (o dia já entrou no
  /// check-in por exercício).
  void _marcarIncompleto() {
    setState(() {
      _respostaCompleto = false;
      _fraseIncompleto = fraseIncompletoAleatoria();
    });
  }

  Color _cor(FaseTipo t) => switch (t) {
        FaseTipo.preparacao => AppColors.prep,
        FaseTipo.execucao => AppColors.exec,
        FaseTipo.descanso => AppColors.rest,
      };

  @override
  Widget build(BuildContext context) {
    if (_fases.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Este treino não tem etapas.',
              style: TextStyle(color: AppColors.dim)),
        ),
      );
    }
    if (_concluido) return _telaConcluido();

    final fase = _fases[_idx];
    final cor = _cor(fase.tipo);
    final totalMs = (fase.segundos * 1000).clamp(1, 1 << 30);
    final fracao = (_restanteMs / totalMs).clamp(0.0, 1.0);
    final segundos = (_restanteMs / 1000).ceil().clamp(0, 99999);
    final proxima = _idx < _fases.length - 1 ? _fases[_idx + 1] : null;

    // Fundo do EXERCÍCIO da fase atual (muda ao longo do treino).
    final ei = fase.exercicioIndex;
    final fundo = (ei >= 0 && ei < widget.exercicios.length)
        ? widget.exercicios[ei].fundo
        : null;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          if (fundo != null) ...[
            Positioned.fill(
              child: Image.asset(fundoAsset(fundo), fit: BoxFit.cover),
            ),
            // Escurece a foto p/ o anel/números ficarem legíveis.
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.55)),
            ),
          ],
          SafeArea(
            child: Container(
              decoration: fundo != null
                  ? null
                  : BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [cor.withValues(alpha: 0.18), AppColors.bg],
                        stops: const [0, 0.5],
                      ),
                    ),
              child: Column(
                children: [
                  _barraTopo(),
                  const SizedBox(height: 8),
                  _progressoGeral(),
                  const Spacer(flex: 2),
                  Text(
                    fase.exercicioNome.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5),
                    textAlign: TextAlign.center,
                  ),
                  if (fase.totalReps > 1) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${fase.totalReps} repetições',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _contadorReps(fase),
                  const SizedBox(height: 10),
                  _anel(cor, fracao, segundos, fase),
                  const SizedBox(height: 20),
                  _legendaProxima(proxima),
                  const Spacer(flex: 3),
                  _controles(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (_carimbo != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0,
              right: 0,
              child: Center(child: _CarimboPill(texto: _carimbo!)),
            ),
        ],
      ),
    );
  }

  Widget _barraTopo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              widget.titulo,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressoGeral() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_idx + 1) / _fases.length,
              minHeight: 6,
              backgroundColor: AppColors.surface2,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.text),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _rotuloProgresso(),
            style: const TextStyle(color: AppColors.dim, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _rotuloProgresso() {
    final f = _fases[_idx];
    final ex = f.totalExercicios > 1
        ? 'Exercício ${f.exercicioIndex + 1}/${f.totalExercicios}'
        : f.exercicioNome;
    final ser = (f.serie > 0 && f.totalSeries > 1)
        ? ' · Série ${f.serie}/${f.totalSeries}'
        : '';
    return '$ex$ser';
  }

  /// Subtexto dentro do anel (só lado/série — as repetições viraram a caixa
  /// amarela acima do cronômetro).
  String _subtextoAnel(Fase f) {
    switch (f.tipo) {
      case FaseTipo.preparacao:
        return f.lado > 0 ? 'Prepare o lado ${f.lado}' : 'Prepare-se';
      case FaseTipo.descanso:
        return f.totalSeries > 1
            ? 'Recupere · série ${f.serie}/${f.totalSeries}'
            : 'Recupere';
      case FaseTipo.execucao:
        final partes = <String>[
          if (f.lado > 0) 'Lado ${f.lado}/2',
          if (f.totalSeries > 1) 'Série ${f.serie}/${f.totalSeries}',
        ];
        return partes.isEmpty ? 'Vai!' : partes.join(' · ');
    }
  }

  /// Caixa amarela com o contador de repetições ("5/22") acima do cronômetro,
  /// que sobe a cada repetição executada. Reserva a altura fixa (não pula o
  /// layout entre fases).
  Widget _contadorReps(Fase f) {
    final mostra = f.tipo == FaseTipo.execucao && f.totalReps > 1;
    return SizedBox(
      height: 54,
      child: mostra
          ? Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accentAmbar, // amarelo (fixo)
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${f.rep}/${f.totalReps}',
                  style: const TextStyle(
                    color: AppColors.onAccentAmbar, // preto sobre o amarelo
                    fontWeight: FontWeight.w800,
                    fontSize: 30,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _anel(Color cor, double fracao, int segundos, Fase fase) {
    return SizedBox(
      width: 292,
      height: 292,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 292,
            height: 292,
            child: CircularProgressIndicator(
              value: fracao,
              strokeWidth: 14,
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.surface2,
              valueColor: AlwaysStoppedAnimation(cor),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                fase.tipo.rotulo.toUpperCase(),
                style: TextStyle(
                  color: cor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                width: 270,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$segundos',
                    style: const TextStyle(
                      fontSize: 244,
                      fontWeight: FontWeight.w800,
                      height: 0.78,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _subtextoAnel(fase),
                style: const TextStyle(color: AppColors.dim, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendaProxima(Fase? proxima) {
    final txt = proxima == null
        ? 'A seguir: fim do treino'
        : 'A seguir: ${proxima.tipo.rotulo} · ${proxima.exercicioNome}'
            ' (${fmtSeg(proxima.segundos)})';
    return Text(
      txt,
      style: const TextStyle(color: AppColors.dim, fontSize: 13),
      textAlign: TextAlign.center,
    );
  }

  Widget _controles() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CtrlSecundario(
          icon: Icons.skip_previous_rounded,
          onTap: _anterior,
        ),
        const SizedBox(width: 28),
        Material(
          color: context.accent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _alternarPausa,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Icon(
                _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 40,
                color: context.onAccent,
              ),
            ),
          ),
        ),
        const SizedBox(width: 28),
        _CtrlSecundario(
          icon: Icons.skip_next_rounded,
          onTap: () => _avancar(),
        ),
      ],
    );
  }

  Widget _telaConcluido() {
    // Treino inteiro + gamificação ligada e ainda sem resposta -> pergunta.
    if (_gamificaTreino && _respostaCompleto == null) return _telaPergunta();
    if (_gamificaTreino && _respostaCompleto == false) return _telaIncompleto();
    return _telaSucesso();
  }

  /// Moldura comum das telas de fim (fundo + centralização vertical, rolando
  /// só quando o conteúdo não couber na tela).
  Widget _molduraFim(List<Widget> filhos) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: filhos,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _botoesFim({required String labelRepetir}) {
    return Column(
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: context.accent,
            foregroundColor: context.onAccent,
            minimumSize: const Size(220, 52),
          ),
          onPressed: _reiniciar,
          icon: const Icon(Icons.replay),
          label: Text(labelRepetir),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: context.accent,
            side: BorderSide(color: context.accent),
            minimumSize: const Size(220, 50),
          ),
          onPressed: _abrirAddProgressao,
          icon: const Icon(Icons.trending_up, size: 20),
          label: const Text('Adicionar à progressão'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Voltar'),
        ),
      ],
    );
  }

  /// Pergunta de conclusão: "Você completou o treino?".
  Widget _telaPergunta() {
    return _molduraFim([
      Icon(Icons.emoji_events_outlined, size: 80, color: context.accent),
      const SizedBox(height: 20),
      const Text(
        'Você completou o treino?',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Text(
        'Todas as repetições, do jeito que você planejou.',
        style: const TextStyle(color: AppColors.dim),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 28),
      FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: context.accent,
          foregroundColor: context.onAccent,
          minimumSize: const Size(240, 54),
        ),
        onPressed: _marcarCompleto,
        icon: const Icon(Icons.check_rounded),
        label: const Text('Sim, completei'),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.lineStrong),
          minimumSize: const Size(240, 52),
        ),
        onPressed: _marcarIncompleto,
        child: const Text('Não consegui hoje'),
      ),
    ]);
  }

  /// Treino concluído (respondeu "sim", ou sessão sem gamificação).
  Widget _telaSucesso() {
    final completou = _respostaCompleto == true;
    return _molduraFim([
      Icon(Icons.check_circle, size: 88, color: context.accent),
      const SizedBox(height: 20),
      Text(
        completou ? 'Treino completo!' : 'Check-in concluído',
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      Text(
        '${widget.titulo} · ${fmtSeg(_duracaoTotal)}',
        style: const TextStyle(color: AppColors.dim),
      ),
      if (_novasConquistas.isNotEmpty) ...[
        const SizedBox(height: 20),
        _NovasConquistas(tipos: _novasConquistas),
      ],
      const SizedBox(height: 32),
      _botoesFim(labelRepetir: 'Repetir treino'),
    ]);
  }

  /// Treino não concluído: frase de incentivo (o dia já entrou no check-in).
  Widget _telaIncompleto() {
    return _molduraFim([
      const Icon(Icons.self_improvement, size: 80, color: AppColors.prep),
      const SizedBox(height: 20),
      Text(
        _fraseIncompleto ?? 'Faz parte do processo. O importante é não parar!',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      const Text(
        'Seu esforço de hoje já entrou no check-in.',
        style: TextStyle(color: AppColors.dim),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 32),
      _botoesFim(labelRepetir: 'Tentar de novo'),
    ]);
  }
}

/// Faixa comemorativa das conquistas recém-desbloqueadas no fim do treino.
class _NovasConquistas extends StatelessWidget {
  const _NovasConquistas({required this.tipos});

  final List<TipoConquista> tipos;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.accent, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tipos.length > 1 ? '🎉 Novas conquistas!' : '🎉 Nova conquista!',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: context.accent),
          ),
          const SizedBox(height: 10),
          for (final t in tipos)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConquistaBadge(tipo: t, size: 26),
                  const SizedBox(width: 10),
                  Text(t.titulo,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Folha para registrar na progressão as repetições feitas de cada exercício
/// (aberta no fim do treino). Pré-preenche com as repetições configuradas.
class _AddProgressaoSheet extends ConsumerStatefulWidget {
  const _AddProgressaoSheet({required this.exercicios});

  final List<Exercicio> exercicios;

  @override
  ConsumerState<_AddProgressaoSheet> createState() =>
      _AddProgressaoSheetState();
}

class _AddProgressaoSheetState extends ConsumerState<_AddProgressaoSheet> {
  late final List<TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = widget.exercicios
        .map((e) => TextEditingController(text: '${e.repeticoes}'))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _salvar() {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(progressaoProvider.notifier);
    var n = 0;
    for (var i = 0; i < widget.exercicios.length; i++) {
      final v = int.tryParse(_ctrls[i].text);
      if (v == null || v < 0) continue;
      final e = widget.exercicios[i];
      final nome = e.nome.trim().isEmpty ? 'Exercício' : e.nome.trim();
      notifier.adicionar(RegistroProgressao(exercicio: nome, valor: v));
      n++;
    }
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(content: Text('Adicionado à progressão ($n)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.lineStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text('Adicionar à progressão',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Quantas repetições você fez de cada um?',
              style: TextStyle(color: AppColors.dim, fontSize: 13)),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (var i = 0; i < widget.exercicios.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: AppColors.corExercicio(
                                  widget.exercicios[i].corIndex),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              widget.exercicios[i].nome.trim().isEmpty
                                  ? 'Exercício'
                                  : widget.exercicios[i].nome,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(
                            width: 68,
                            child: TextField(
                              controller: _ctrls[i],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.accent,
              foregroundColor: context.onAccent,
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: _salvar,
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

/// Carimbo "Série X/Y ✓" que aparece por um instante ao concluir uma série.
class _CarimboPill extends StatelessWidget {
  const _CarimboPill({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.8 + 0.2 * t, child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: context.accent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: context.onAccent,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _CtrlSecundario extends StatelessWidget {
  const _CtrlSecundario({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(icon, size: 28, color: AppColors.text),
        ),
      ),
    );
  }
}
