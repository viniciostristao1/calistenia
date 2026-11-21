import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Item da barra flutuante (ícone + rótulo). Mesmos nomes/ícones/ordem da
/// [NavigationBar] original — só o visual mudou (v0.118.0).
class DestinoNavegacao {
  const DestinoNavegacao({
    required this.rotulo,
    required this.icone,
    required this.iconeSelecionado,
  });

  final String rotulo;
  final IconData icone;
  final IconData iconeSelecionado;
}

/// Barra de navegação flutuante em pílula (v0.118.0): contêiner único,
/// suspenso, cantos totalmente arredondados. Cada item tem ícone em cima e
/// texto embaixo; o selecionado ganha pílula menor atrás (accent translúcido)
/// com ícone+texto no accent. Cores só da paleta atual ([AppColors]).
class BarraNavegacaoFlutuante extends StatelessWidget {
  const BarraNavegacaoFlutuante({
    super.key,
    required this.destinos,
    required this.selecionado,
    required this.onSelect,
  }) : assert(destinos.length > 0);

  final List<DestinoNavegacao> destinos;
  final int selecionado;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            for (var i = 0; i < destinos.length; i++)
              Expanded(child: _ItemNavegacao(
                destino: destinos[i],
                selecionado: i == selecionado,
                onTap: () => onSelect(i),
              )),
          ],
        ),
      ),
    );
  }
}

/// Um item: ícone em cima + texto embaixo, centralizados, mesmo espaçamento.
/// Selecionado (suave, v0.119.0) = pílula accent translúcido atrás +
/// ícone/texto em accent; repouso = conteúdo em [AppColors.dim] (contraste
/// sobre o surface).
class _ItemNavegacao extends StatelessWidget {
  const _ItemNavegacao({
    required this.destino,
    required this.selecionado,
    required this.onTap,
  });

  final DestinoNavegacao destino;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final conteudo = selecionado ? context.accent : AppColors.dim;
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        decoration: BoxDecoration(
          color: selecionado
              ? context.accent.withValues(alpha: 0.20)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selecionado ? destino.iconeSelecionado : destino.icone,
              size: 24,
              color: conteudo,
            ),
            const SizedBox(height: 2),
            Text(
              destino.rotulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selecionado ? FontWeight.w800 : FontWeight.w600,
                color: conteudo,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
