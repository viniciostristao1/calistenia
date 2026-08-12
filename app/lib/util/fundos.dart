/// Imagens de fundo (motivacionais) disponíveis para o cronômetro.
/// São assets em `assets/fundos/` (soldados em treino, 1122×1402, JPG otimizado).
const fundosDisponiveis = <String>[
  'fundo1.jpg',
  'fundo2.jpg',
  'fundo3.jpg',
  'fundo4.jpg',
  'fundo5.jpg',
  'fundo6.jpg',
  'fundo7.jpg',
  'fundo8.jpg',
  'fundo9.jpg',
  'fundo10.jpg',
  'fundo11.jpg',
  'fundo12.jpg',
];

/// Caminho do asset a partir do nome guardado no treino.
String fundoAsset(String nome) => 'assets/fundos/$nome';
