import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/som_repository.dart';
import '../../services/tema_repository.dart';
import '../../theme/app_colors.dart';

/// Configurações do app. Por ora: tema de destaque (azul / âmbar).
class ConfigScreen extends ConsumerWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ref.watch(temaProvider).value ?? TemaApp.ambar;
    final som = ref.watch(somProvider).value ?? true;
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text('Tema de destaque',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('A cor dos botões e destaques do app.',
              style: TextStyle(color: AppColors.dim, fontSize: 13)),
          const SizedBox(height: 14),
          _OpcaoTema(
            titulo: 'Azul',
            cor: AppColors.accentAzul,
            selecionado: tema == TemaApp.azul,
            onTap: () => ref.read(temaProvider.notifier).definir(TemaApp.azul),
          ),
          const SizedBox(height: 10),
          _OpcaoTema(
            titulo: 'Âmbar',
            cor: AppColors.accentAmbar,
            selecionado: tema == TemaApp.ambar,
            onTap: () => ref.read(temaProvider.notifier).definir(TemaApp.ambar),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: som,
            onChanged: (v) => ref.read(somProvider.notifier).definir(v),
            activeThumbColor: context.accent,
            title: const Text('Som',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            subtitle: const Text(
              'Bips nas transições e no fim do treino.',
              style: TextStyle(color: AppColors.dim, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Conta',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          const Text(
            'Em breve: entrar com Google para salvar seus treinos na conta e '
            'recuperar ao trocar de celular.',
            style: TextStyle(color: AppColors.dim, fontSize: 13),
          ),
          const SizedBox(height: 12),
          const _BotaoGoogle(),
        ],
      ),
    );
  }
}

/// Botão "Entrar com Google" — visual pronto; a conexão real chega quando o
/// Firebase for configurado (ver IDEIAS.md). Por ora, avisa "em breve".
class _BotaoGoogle extends StatelessWidget {
  const _BotaoGoogle();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.lineStrong),
        minimumSize: const Size.fromHeight(50),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login com Google chega em breve.'),
          ),
        );
      },
      icon: const Icon(Icons.g_mobiledata, size: 28),
      label: const Text('Entrar com Google'),
    );
  }
}

class _OpcaoTema extends StatelessWidget {
  const _OpcaoTema({
    required this.titulo,
    required this.cor,
    required this.selecionado,
    required this.onTap,
  });

  final String titulo;
  final Color cor;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selecionado ? cor : AppColors.line,
            width: selecionado ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(titulo,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            if (selecionado) Icon(Icons.check_circle, color: cor),
          ],
        ),
      ),
    );
  }
}
