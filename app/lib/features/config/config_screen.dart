import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/tema_repository.dart';
import '../../theme/app_colors.dart';

/// Configurações do app. Por ora: tema de destaque (azul / âmbar).
class ConfigScreen extends ConsumerWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ref.watch(temaProvider).value ?? TemaApp.azul;
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
        ],
      ),
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
