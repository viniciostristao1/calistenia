import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Seletor de sub-abas no estilo **Sublinhado (abas clássicas)**: só texto, com
/// um traço sob a aba ativa. Usado na Progressão e no Check-in.
class SubAbas extends StatelessWidget {
  const SubAbas({
    super.key,
    required this.abas,
    required this.selecionado,
    required this.onSelect,
  });

  final List<String> abas;
  final int selecionado;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < abas.length; i++)
            Expanded(
              child: _Aba(
                label: abas[i],
                ativo: i == selecionado,
                onTap: () => onSelect(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _Aba extends StatelessWidget {
  const _Aba({required this.label, required this.ativo, required this.onTap});

  final String label;
  final bool ativo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cor = ativo ? context.accent : AppColors.dim;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: ativo ? FontWeight.w800 : FontWeight.w600,
                color: cor,
              ),
            ),
          ),
          // Traço sob a aba ativa (acompanha a linha divisória de baixo).
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 2.5,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: ativo ? context.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
