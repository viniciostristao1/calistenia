/// Imagens de fundo (motivacionais) disponíveis para o cronômetro.
/// São assets em `assets/fundos/`. Formato stories (9:16).
const fundosDisponiveis = <String>[
  'fundo1.jpg',
  'fundo2.jpg',
  'fundo3.jpg',
  'fundo4.jpg',
  'fundo5.jpg',
];

/// Caminho do asset a partir do nome guardado no treino.
String fundoAsset(String nome) => 'assets/fundos/$nome';
