import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_service.dart';
import '../../services/gamificacao_pref.dart';
import '../../services/som_repository.dart';
import '../../services/tema_repository.dart';
import '../../theme/app_colors.dart';

/// Configurações do app. Por ora: tema de destaque (azul / âmbar).
class ConfigScreen extends ConsumerWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ref.watch(temaProvider).value ?? TemaApp.ambar;
    final som = ref.watch(somProvider).value ?? true;
    final gami = ref.watch(gamificacaoProvider).value ?? true;
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text('Tema de destaque',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('A cor dos botões e destaques do app.',
              style: TextStyle(color: AppColors.dim, fontSize: 13)),
          const SizedBox(height: 14),
          _OpcaoTema(
            titulo: 'Azul',
            cor: AppColors.accentAzul,
            selecionado: tema == TemaApp.azul,
            onTap: () => ref.read(temaProvider.notifier).definir(TemaApp.azul),
          ),
          const SizedBox(height: 10),
          _OpcaoTema(
            titulo: 'Âmbar',
            cor: AppColors.accentAmbar,
            selecionado: tema == TemaApp.ambar,
            onTap: () => ref.read(temaProvider.notifier).definir(TemaApp.ambar),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: som,
            onChanged: (v) => ref.read(somProvider.notifier).definir(v),
            activeThumbColor: context.accent,
            title: const Text('Som',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            subtitle: const Text(
              'Bips nas transições e no fim do treino.',
              style: TextStyle(color: AppColors.dim, fontSize: 13),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: gami,
            onChanged: (v) => ref.read(gamificacaoProvider.notifier).definir(v),
            activeThumbColor: context.accent,
            title: const Text('Gamificação',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            subtitle: const Text(
              'Medalhas, troféus e a pergunta “treino completo?” no fim do treino.',
              style: TextStyle(color: AppColors.dim, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Conta',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          const Text(
            'Entre com Google para preparar o backup dos seus treinos na conta '
            '(a sincronização em si chega numa próxima versão).',
            style: TextStyle(color: AppColors.dim, fontSize: 13),
          ),
          const SizedBox(height: 12),
          const _SecaoConta(),
        ],
      ),
    );
  }
}

/// Login/logout com Google. Reage ao estado de autenticação em tempo real.
class _SecaoConta extends ConsumerStatefulWidget {
  const _SecaoConta();

  @override
  ConsumerState<_SecaoConta> createState() => _SecaoContaState();
}

class _SecaoContaState extends ConsumerState<_SecaoConta> {
  bool _ocupado = false;

  Future<void> _entrar() async {
    setState(() => _ocupado = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível entrar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _sair() async {
    setState(() => _ocupado = true);
    await ref.read(authServiceProvider).signOut();
    if (mounted) setState(() => _ocupado = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).asData?.value;

    if (_ocupado) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (user != null) {
      final nome = (user.displayName ?? '').trim();
      final email = user.email ?? '';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.surface2,
              foregroundImage:
                  user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              child: const Icon(Icons.person, color: AppColors.dim),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nome.isEmpty ? 'Conectado' : nome,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                  if (email.isNotEmpty)
                    Text(email,
                        style: const TextStyle(
                            color: AppColors.dim, fontSize: 12.5),
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            TextButton(
              onPressed: _sair,
              child: const Text('Sair'),
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.lineStrong),
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: _entrar,
      icon: const Icon(Icons.g_mobiledata, size: 28),
      label: const Text('Entrar com Google'),
    );
  }
}

class _OpcaoTema extends StatelessWidget {
  const _OpcaoTema({
    required this.titulo,
    required this.cor,
    required this.selecionado,
    required this.onTap,
  });

  final String titulo;
  final Color cor;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selecionado ? cor : AppColors.line,
            width: selecionado ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(titulo,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            if (selecionado) Icon(Icons.check_circle, color: cor),
          ],
        ),
      ),
    );
  }
}
