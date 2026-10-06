import 'package:flutter/foundation.dart';

/// Deep-links de navegação (ValueNotifier simples, sem depender da versão do
/// Riverpod para StateProvider).

/// Qual aba da barra inferior abrir (0=Treinos, 1=Check-in, 2=Progressão).
/// O `RootScreen` escuta e troca a aba; depois volta a null.
final abaSolicitada = ValueNotifier<int?>(null);

/// Qual sub-aba da Progressão abrir (0=Evolução, 1=Rating, 2=Cards, 3=Resumo).
/// A `ProgressaoScreen` escuta e troca o segmento; depois volta a null.
final progressaoVistaInicial = ValueNotifier<int?>(null);
