import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../models/exercicio.dart';
import '../../models/fase.dart';
import '../../models/registro_progressao.dart';
import '../../services/checkin_repository.dart';
import '../../services/progressao_repository.dart';
import '../../services/som_repository.dart';
import '../../theme/app_colors.dart';
import '../../util/format.dart';

/// Roda o cronômetro: percorre a linha do tempo (preparação → execução × reps
/// → descanso, por série) contando segundo a segundo, com pausa, pular/voltar
/// etapa e vibração nas transições. Mantém a tela ligada. Serve tanto para o
/// treino inteiro quanto para um único exercício (basta a lista `exercicios`).
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({
    super.key,
    required this.titulo,
    required this.exercicios,
  });

  final String titulo;
  final List<Exercicio> exercicios;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
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

  // Dois players PRÉ-CARREGADOS: em transições rápidas, recarregar o asset a
  // cada play() falhava/atrasava. Com a source já pronta + modo baixa latência,
  // tocar é instantâneo. `_beep` = troca de repetição; `_fim` = fim de série/treino.
  final AudioPlayer _beep = AudioPlayer(playerId: 'calis_beep');
  final AudioPlayer _fim = AudioPlayer(playerId: 'calis_fim');
  bool _somPronto = false;

  Future<void> _prepararSom() async {
    for (final (p, asset) in [
      (_beep, 'sounds/beep.wav'),
      (_fim, 'sounds/fim.wav'),
    ]) {
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setPlayerMode(PlayerMode.lowLatency);
      await p.setVolume(0.9);
      await p.setSource(AssetSource(asset));
    }
    _somPronto = true;
  }

  /// Toca o som pré-carregado [p] (do início) se o som estiver ligado.
  void _tocarSom(AudioPlayer p) {
    if (!(ref.read(somProvider).value ?? true)) return;
    if (_somPronto) {
      p.seek(Duration.zero);
      p.resume();
    } else {
      // fallback enquanto o pré-carregamento não terminou
      p.play(AssetSource(p == _fim ? 'sounds/fim.wav' : 'sounds/beep.wav'));
    }
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
    _prepararSom();
    _fases = montarLinhaDoTempoDe(widget.exercicios);
    _duracaoTotal = _fases.fold(0, (a, f) => a + f.segundos);
    if (_fases.isNotEmpty) {
      _restanteMs = _fases[0].segundos * 1000;
      WidgetsBinding.instance.addPostFrameCallback((_) => _iniciar());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _beep.dispose();
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
    final delta = _sw.elapsedMilliseconds;
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
    _tocarSom(fimDeSerie ? _fim : _beep);
    setState(() {});
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
    _tocarSom(_fim); // som de fim marcando o término
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
      _restanteMs = _fases.isEmpty ? 0 : _fases[0].segundos * 1000;
    });
    _iniciar();
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

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
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
              const Spacer(),
              Text(
                fase.exercicioNome,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _anel(cor, fracao, segundos, fase),
              const SizedBox(height: 20),
              _legendaProxima(proxima),
              const Spacer(),
              _controles(),
              const SizedBox(height: 12),
            ],
          ),
        ),
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

  /// Subtexto dentro do anel, conforme a fase.
  String _subtextoAnel(Fase f) {
    switch (f.tipo) {
      case FaseTipo.preparacao:
        return 'Prepare-se';
      case FaseTipo.descanso:
        return f.totalSeries > 1 ? 'Recupere · série ${f.serie}/${f.totalSeries}' : 'Recupere';
      case FaseTipo.execucao:
        final temReps = f.totalReps > 1;
        final temSeries = f.totalSeries > 1;
        if (temReps && temSeries) {
          return 'Série ${f.serie}/${f.totalSeries} · rep ${f.rep}/${f.totalReps}';
        }
        if (temReps) return 'Repetição ${f.rep}/${f.totalReps}';
        if (temSeries) return 'Série ${f.serie}/${f.totalSeries}';
        return 'Vai!';
    }
  }

  Widget _anel(Color cor, double fracao, int segundos, Fase fase) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 260,
            height: 260,
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
              const SizedBox(height: 6),
              SizedBox(
                width: 224,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$segundos',
                    style: const TextStyle(
                      fontSize: 150,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 88, color: context.accent),
                const SizedBox(height: 20),
                const Text(
                  'Check-in concluído',
                  style:
                      TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.titulo} · ${fmtSeg(_duracaoTotal)}',
                  style: const TextStyle(color: AppColors.dim),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: context.accent,
                    foregroundColor: context.onAccent,
                    minimumSize: const Size(220, 52),
                  ),
                  onPressed: _reiniciar,
                  icon: const Icon(Icons.replay),
                  label: const Text('Repetir treino'),
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
            ),
          ),
        ),
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
