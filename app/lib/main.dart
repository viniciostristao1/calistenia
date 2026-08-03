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
    final tema = ref.watch(temaProvider).value ?? TemaApp.ambar;
    return MaterialApp(
      title: 'Calis Timer',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(tema),
      // Troca de tema instantânea (sem a animação padrão que dava "delay").
      themeAnimationDuration: Duration.zero,
      home: const RootScreen(),
    );
  }
}
