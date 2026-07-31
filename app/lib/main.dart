import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/root/root_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: CalisteniaApp()));
}

class CalisteniaApp extends StatelessWidget {
  const CalisteniaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calis Cronômetro',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const RootScreen(),
    );
  }
}
