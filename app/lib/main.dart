import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/root/root_screen.dart';
import 'services/tema_repository.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: CalisteniaApp()));
}

class CalisteniaApp extends ConsumerWidget {
  const CalisteniaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Aplica o accent do tema escolhido antes de montar o ThemeData.
    final tema = ref.watch(temaProvider).value ?? TemaApp.azul;
    AppColors.aplicarTema(tema);
    return MaterialApp(
      title: 'Calis Cronômetro',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const RootScreen(),
    );
  }
}
