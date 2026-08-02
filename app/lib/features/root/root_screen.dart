import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../checkin/checkin_screen.dart';
import '../home/home_screen.dart';
import '../progressao/progressao_screen.dart';

/// Casca do app com a barra de abas embaixo: Treinos e Progressão.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _aba = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack preserva o estado de cada aba ao alternar.
      body: IndexedStack(
        index: _aba,
        children: const [HomeScreen(), CheckinScreen(), ProgressaoScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _aba,
        onDestinationSelected: (i) => setState(() => _aba = i),
        backgroundColor: AppColors.surface,
        indicatorColor: context.accent.withValues(alpha: 0.20),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.fitness_center_outlined),
            selectedIcon:
                Icon(Icons.fitness_center, color: context.accent),
            label: 'Treinos',
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: context.accent),
            label: 'Check-in',
          ),
          NavigationDestination(
            icon: const Icon(Icons.trending_up_outlined),
            selectedIcon: Icon(Icons.trending_up, color: context.accent),
            label: 'Progressão',
          ),
        ],
      ),
    );
  }
}
