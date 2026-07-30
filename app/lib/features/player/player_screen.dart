import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../models/fase.dart';
import '../../models/treino.dart';
import '../../theme/app_colors.dart';
import '../../util/format.dart';

/// Roda o cronômetro do treino: percorre a linha do tempo (preparação →
/// execução × reps → descanso) contando segundo a segundo, com pausa,
/// pular/voltar etapa e vibração nas transições. Mantém a tela ligada.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.treino});

  final Treino treino;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final List<Fase> _fases;
  int _idx = 0;
  int _restanteMs = 0;
  bool _running = false;
  bool _concluido = false;
  Timer? _timer;
  final Stopwatch _sw = Stopwatch();
  int _ultimoBip = -1;

  @override
  void initState() {
    super.initState();
    _fases = montarLinhaDoTempo(widget.treino);
    if (_fases.isNotEmpty) {
      _restanteMs = _fases[0].segundos * 1000;
      WidgetsBinding.instance.addPostFrameCallback((_) => _iniciar());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    final resto = auto ? _restanteMs : 0; // carrega o "estouro" p/ manter o ritmo
    _idx++;
    _ultimoBip = -1;
    _restanteMs = _fases[_idx].segundos * 1000 + resto;
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
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
              widget.treino.nome,
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
            'Etapa ${_idx + 1} de ${_fases.length}',
            style: const TextStyle(color: AppColors.dim, fontSize: 12),
          ),
        ],
      ),
    );
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
              Text(
                '$segundos',
                style: const TextStyle(
                  fontSize: 76,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                fase.tipo == FaseTipo.execucao
                    ? 'Repetição ${fase.rep}/${fase.totalReps}'
                    : (fase.tipo == FaseTipo.preparacao
                        ? 'Prepare-se'
                        : 'Recupere'),
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
          color: AppColors.exec,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _alternarPausa,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Icon(
                _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 40,
                color: AppColors.onAccent,
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
                const Icon(Icons.check_circle,
                    size: 88, color: AppColors.exec),
                const SizedBox(height: 20),
                const Text(
                  'Treino concluído!',
                  style:
                      TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.treino.nome} · ${fmtSeg(widget.treino.duracaoTotalSeg)}',
                  style: const TextStyle(color: AppColors.dim),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.exec,
                    foregroundColor: AppColors.onAccent,
                    minimumSize: const Size(220, 52),
                  ),
                  onPressed: _reiniciar,
                  icon: const Icon(Icons.replay),
                  label: const Text('Repetir treino'),
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
