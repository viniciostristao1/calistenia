import 'package:flutter/material.dart';

/// Catálogo dos CARDS motivacionais (as 16 cartas iniciais). Cada card é uma arte
/// própria (`assets/cards/`) com título, selo e uma cor de destaque (aprox. da
/// borda neon — usada só em acentos da UI; a arte já carrega o visual).
class CardMotivacao {
  final String id; // estável (serve ao save/sync): 'meta', 'cuidado'…
  final String asset; // caminho do PNG recortado
  final String titulo; // "META"
  final String selo; // "FOCO"
  final Color cor; // acento (borda neon aproximada)
  const CardMotivacao(this.id, this.asset, this.titulo, this.selo, this.cor);
}

/// Quantas moedas ($) cada marco de sequência dá, e de quantos em quantos dias.
const int kMoedasPorMarco = 10;
const int kMarcoDias = 3; // a cada 3 dias de sequência consecutiva
const int kCustoCard = 50; // custo de 1 card (compra surpresa)

/// Card ganho de graça no começo (p/ o pré-treino não ficar vazio).
const String kCardInicial = 'meta';

const List<CardMotivacao> todosCards = <CardMotivacao>[
  // Imagem 1 (01–08)
  CardMotivacao(
    'meta',
    'assets/cards/card_01_meta.png',
    'Meta',
    'Foco',
    Color(0xFF3B82F6),
  ),
  CardMotivacao(
    'cuidado',
    'assets/cards/card_02_cuidado.png',
    'Cuidado',
    'Equilíbrio',
    Color(0xFF31C971),
  ),
  CardMotivacao(
    'saude',
    'assets/cards/card_03_saude.png',
    'Saúde',
    'Longevidade',
    Color(0xFFF5A524),
  ),
  CardMotivacao(
    'bem-estar',
    'assets/cards/card_04_bem-estar.png',
    'Bem estar',
    'Equilíbrio',
    Color(0xFFB152D8),
  ),
  CardMotivacao(
    'vontade',
    'assets/cards/card_05_vontade.png',
    'Vontade',
    'Motivação',
    Color(0xFFFF4D4D),
  ),
  CardMotivacao(
    'disciplina',
    'assets/cards/card_06_disciplina.png',
    'Disciplina',
    'Hábito',
    Color(0xFF3B82F6),
  ),
  CardMotivacao(
    'conquista',
    'assets/cards/card_07_conquista.png',
    'Conquista',
    'Resultado',
    Color(0xFFF5A524),
  ),
  CardMotivacao(
    'beneficio',
    'assets/cards/card_08_beneficio.png',
    'Benefício',
    'Longo prazo',
    Color(0xFF34D1C9),
  ),
  // Imagem 2 (09–16)
  CardMotivacao(
    'equilibrio',
    'assets/cards/card_09_equilibrio.png',
    'Equilíbrio',
    'Vida',
    Color(0xFFB152D8),
  ),
  CardMotivacao(
    'liberdade',
    'assets/cards/card_10_liberdade.png',
    'Liberdade',
    'Sonhos',
    Color(0xFFF5A524),
  ),
  CardMotivacao(
    'forca',
    'assets/cards/card_11_forca.png',
    'Força',
    'Resistência',
    Color(0xFF3B82F6),
  ),
  CardMotivacao(
    'consistencia',
    'assets/cards/card_12_consistencia.png',
    'Consistência',
    'Hábito',
    Color(0xFF31C971),
  ),
  CardMotivacao(
    'constancia',
    'assets/cards/card_13_constancia.png',
    'Constância',
    'Processo',
    Color(0xFF9B6CFF),
  ),
  CardMotivacao(
    'evolucao',
    'assets/cards/card_14_evolucao.png',
    'Evolução',
    'Progresso',
    Color(0xFFF5A524),
  ),
  CardMotivacao(
    'progresso',
    'assets/cards/card_15_progresso.png',
    'Progresso',
    'Evolução',
    Color(0xFF3B82F6),
  ),
  CardMotivacao(
    'plano',
    'assets/cards/card_16_plano.png',
    'Plano',
    'Estratégia',
    Color(0xFFFF5DA2),
  ),
];

/// Total de cards do catálogo (p/ "coleção completa").
int get totalCardsCatalogo => todosCards.length;

/// Busca um card pelo id (ou `null`).
CardMotivacao? cardPorId(String id) {
  for (final c in todosCards) {
    if (c.id == id) return c;
  }
  return null;
}
