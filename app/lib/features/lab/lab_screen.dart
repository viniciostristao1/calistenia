import 'package:flutter/material.dart';

import '../../fx/fx.dart';
import '../../theme/app_colors.dart';

/// **Laboratório de Animações** — área isolada para testar as recompensas.
///
/// ⚠️ **Isolamento por construção:** esta tela importa **apenas `fx/`** — nunca
/// `services/`, `*_repository`, `shared_preferences` ou Firestore. Por isso é
/// impossível ela alterar XP, sequência, medalhas, insígnias ou qualquer estado
/// persistente. Ela fabrica dados fake e só dispara a camada de apresentação.
/// Não adicione imports de dados aqui (ver `ANIMACOES.md`).
class LabScreen extends StatefulWidget {
  const LabScreen({super.key});

  @override
  State<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LabScreen> {
  RewardType _selecionado = RewardType.star;
  FxParams _params = const FxParams();

  /// Valor exibido por efeitos que mostram número (ex.: "+XP").
  double _valor = 50;

  /// Muda a cada "Testar" para reiniciar o efeito no palco.
  int _token = 0;

  @override
  void initState() {
    super.initState();
    // Garante que as animações reais estejam ligadas mesmo se o Lab for aberto
    // isolado. Idempotente (já é chamado no main).
    registerBuiltInRewards();
  }

  void _testarNoPalco() => setState(() => _token++);

  void _testarComoOverlay() =>
      RewardFx.show(context, _selecionado, params: _params, value: _valor);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🧪 Laboratório de Animações')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _bannerIsolado(),
          const SizedBox(height: 14),
          _palco(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _testarNoPalco,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Testar no palco'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testarComoOverlay,
                  icon: const Icon(Icons.open_in_full_rounded),
                  label: const Text('Como overlay'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _titulo('Recompensa'),
          const SizedBox(height: 8),
          _grade(),
          const SizedBox(height: 20),
          _controles(),
        ],
      ),
    );
  }

  Widget _bannerIsolado() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.dim, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Área de testes isolada — não altera seu XP, sequência, '
                'medalhas nem qualquer progresso.',
                style: TextStyle(color: AppColors.dim, fontSize: 12.5),
              ),
            ),
          ],
        ),
      );

  Widget _palco() => Container(
        height: 280,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.lineStrong),
        ),
        clipBehavior: Clip.antiAlias,
        child: Center(
          // KeyedSubtree com _token reinicia o efeito a cada "Testar no palco".
          child: KeyedSubtree(
            key: ValueKey('$_selecionado-$_token'),
            child: RewardRegistry.build(context, _selecionado, _params,
                value: _valor),
          ),
        ),
      );

  Widget _grade() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final t in RewardType.values)
            ChoiceChip(
              selected: _selecionado == t,
              onSelected: (_) => setState(() {
                _selecionado = t;
                _token++;
              }),
              avatar: Icon(t.icon,
                  size: 18,
                  color: _selecionado == t ? context.onAccent : t.color(context)),
              label: Text(t.label),
              selectedColor: context.accent,
              labelStyle: TextStyle(
                color: _selecionado == t ? context.onAccent : AppColors.text,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: AppColors.surface,
            ),
        ],
      );

  Widget _controles() => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            leading: Icon(Icons.tune_rounded, color: context.accent),
            title: const Text('Controles',
                style: TextStyle(fontWeight: FontWeight.w700)),
            children: [
              _slider(
                'Velocidade', _params.speed, 0.25, 3, '${_params.speed.toStringAsFixed(2)}×',
                (v) => setState(() => _params = _params.copyWith(speed: v)),
              ),
              _slider(
                'Intensidade', _params.intensity, 0, 2, _params.intensity.toStringAsFixed(2),
                (v) => setState(() => _params = _params.copyWith(intensity: v)),
              ),
              _slider(
                'Escala', _params.scale, 0.5, 2, '${_params.scale.toStringAsFixed(2)}×',
                (v) => setState(() => _params = _params.copyWith(scale: v)),
              ),
              _slider(
                'Partículas', _params.particleCount.toDouble(), 0, 80, '${_params.particleCount}',
                (v) => setState(() => _params = _params.copyWith(particleCount: v.round())),
              ),
              _slider(
                'Duração', _params.duration.inMilliseconds.toDouble(), 200, 3000,
                '${_params.duration.inMilliseconds} ms',
                (v) => setState(() => _params =
                    _params.copyWith(duration: Duration(milliseconds: v.round()))),
              ),
              _slider(
                'Atraso', _params.delay.inMilliseconds.toDouble(), 0, 2000,
                '${_params.delay.inMilliseconds} ms',
                (v) => setState(() => _params =
                    _params.copyWith(delay: Duration(milliseconds: v.round()))),
              ),
              _slider(
                'Repetir', _params.repeat.toDouble(), 0, 5,
                _params.loopForever ? '∞ (loop)' : '${_params.repeat}×',
                (v) => setState(() => _params = _params.copyWith(repeat: v.round())),
              ),
              _slider(
                'Valor (+XP)', _valor, 0, 500, '${_valor.round()}',
                (v) => setState(() => _valor = v),
              ),
            ],
          ),
        ),
      );

  Widget _slider(String nome, double valor, double min, double max,
          String rotulo, ValueChanged<double> onChanged) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(nome,
                    style: TextStyle(color: AppColors.text, fontSize: 13.5)),
                Text(rotulo,
                    style: TextStyle(
                        color: context.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            Slider(
              value: valor.clamp(min, max),
              min: min,
              max: max,
              activeColor: context.accent,
              onChanged: onChanged,
            ),
          ],
        ),
      );

  Widget _titulo(String t) => Text(t,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16));
}
