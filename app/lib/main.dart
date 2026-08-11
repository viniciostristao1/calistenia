import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/root/root_screen.dart';
import 'firebase_options.dart';
import 'services/sync_service.dart';
import 'services/tema_repository.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'util/messenger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Crashlytics: manda para o painel todo erro de Flutter e todo erro assíncrono
  // não tratado, COM stack trace — assim um "erro interno" reportado pelo usuário
  // chega diagnosticável, sem depender de repro. (Só relatório Dart; o plugin
  // Gradle de símbolos NDK não é necessário para esses casos.)
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: CalisteniaApp()));
}

class CalisteniaApp extends ConsumerWidget {
  const CalisteniaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ref.watch(temaProvider).value ?? TemaApp.ambar;
    ref.watch(syncProvider); // mantém a sincronização ativa (conforme o login)
    return MaterialApp(
      title: 'Calis Timer',
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(tema),
      // Troca de tema instantânea (sem a animação padrão que dava "delay").
      themeAnimationDuration: Duration.zero,
      home: const RootScreen(),
    );
  }
}
