import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_service.dart';
import '../../services/backup_service.dart';
import '../../services/gamificacao_pref.dart';
import '../../services/lembretes_service.dart';
import '../../services/som_repository.dart';
import '../../services/sync_service.dart';
import '../../services/tema_repository.dart';
import '../../services/treinos_repository.dart';
import '../../theme/app_colors.dart';
import '../../util/dias.dart';
import '../../util/gamificacao.dart' show diasAgendados;

/// Configurações do app: tema, som, gamificação, lembretes de treino, conta
/// (login + status da sincronização) e backup em arquivo.
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
          const Text('Tema',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Muda as cores e o visual do app inteiro.',
              style: TextStyle(color: AppColors.dim, fontSize: 13)),
          const SizedBox(height: 14),
          for (final o in const [
            (TemaApp.ambar, 'Âmbar', 'Âmbar sobre navy escuro (padrão)'),
            (TemaApp.azul, 'Azul', 'Azul sobre navy escuro'),
            (TemaApp.espresso, 'Expresso', 'Escuro amadeirado'),
            (TemaApp.madeira, 'Madeira', 'Bege claro amadeirado'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OpcaoTema(
                titulo: o.$2,
                subtitulo: o.$3,
                cor: AppColors.accentDoTema(o.$1),
                fundo: AppColors.fundoDoTema(o.$1),
                selecionado: tema == o.$1,
                onTap: () => ref.read(temaProvider.notifier).definir(o.$1),
              ),
            ),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: som,
            onChanged: (v) => ref.read(somProvider.notifier).definir(v),
            activeThumbColor: context.accent,
            title: const Text('Som',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            subtitle: Text(
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
            subtitle: Text(
              'Medalhas, troféus e a pergunta “treino completo?” no fim do treino.',
              style: TextStyle(color: AppColors.dim, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Lembretes de treino',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            'Uma notificação motivacional nos dias em que você tem treino '
            'agendado, no horário que escolher. Toca sozinha toda semana.',
            style: TextStyle(color: AppColors.dim, fontSize: 13),
          ),
          const SizedBox(height: 8),
          const _SecaoLembretes(),
          const SizedBox(height: 20),
          const Text('Conta',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            'Entre com Google para guardar treinos, check-ins e progressão na '
            'sua conta e recuperá-los em qualquer aparelho.',
            style: TextStyle(color: AppColors.dim, fontSize: 13),
          ),
          const SizedBox(height: 12),
          const _SecaoConta(),
          const SizedBox(height: 20),
          const Text('Backup em arquivo',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            'Uma segunda via, independente da conta: exporte tudo (treinos, '
            'progressão, check-ins, conquistas) num arquivo .json e restaure '
            'quando quiser.',
            style: TextStyle(color: AppColors.dim, fontSize: 13),
          ),
          const SizedBox(height: 12),
          const _SecaoBackup(),
        ],
      ),
    );
  }
}

/// "HH:MM" a partir de minutos do dia (0..1439).
String _hhmm(int minutos) {
  final h = (minutos ~/ 60).toString().padLeft(2, '0');
  final m = (minutos % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

/// Chave (liga/desliga) + horário por dia da semana que tem treino agendado.
class _SecaoLembretes extends ConsumerWidget {
  const _SecaoLembretes();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config =
        ref.watch(lembretesConfigProvider).value ?? LembretesConfig.vazio;
    final treinos = ref.watch(treinosProvider).value ?? const [];
    final dias = diasAgendados(treinos).toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: config.ativo,
          onChanged: (v) =>
              ref.read(lembretesConfigProvider.notifier).definirAtivo(v),
          activeThumbColor: context.accent,
          title: const Text('Lembrar de treinar',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          subtitle: Text(
            config.ativo
                ? 'Notificação ligada nos dias com treino.'
                : 'Desligado.',
            style: TextStyle(color: AppColors.dim, fontSize: 13),
          ),
        ),
        if (config.ativo)
          if (dias.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                'Nenhum treino agendado ainda. Marque os dias de um treino no '
                'editor para o lembrete aparecer aqui.',
                style: TextStyle(color: AppColors.dim, fontSize: 13),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < dias.length; i++) ...[
                    if (i > 0)
                      Divider(height: 1, color: AppColors.line),
                    _LinhaDiaHorario(
                      dia: dias[i],
                      minutos: config.horarioDe(dias[i]),
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: config.horaDe(dias[i]),
                            minute: config.minutoDe(dias[i]),
                          ),
                          helpText: 'Lembrete de ${nomesDiasLongos[dias[i]]}',
                        );
                        if (t != null) {
                          await ref
                              .read(lembretesConfigProvider.notifier)
                              .definirHorario(dias[i], t.hour * 60 + t.minute);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
      ],
    );
  }
}

class _LinhaDiaHorario extends StatelessWidget {
  const _LinhaDiaHorario({
    required this.dia,
    required this.minutos,
    required this.onTap,
  });

  final int dia; // 0=seg..6=dom
  final int minutos;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.notifications_active_outlined,
                size: 20, color: AppColors.dim),
            const SizedBox(width: 12),
            Expanded(
              child: Text(nomesDiasLongos[dia],
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Text(_hhmm(minutos),
                style: TextStyle(
                    color: context.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const SizedBox(width: 6),
            Icon(Icons.edit, size: 16, color: AppColors.dim),
          ],
        ),
      ),
    );
  }
}

/// Login/logout com Google + status da sincronização em tempo real.
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
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
                  foregroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: Icon(Icons.person, color: AppColors.dim),
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
                            style: TextStyle(
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
          ),
          const SizedBox(height: 8),
          const _StatusSync(),
        ],
      );
    }

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: BorderSide(color: AppColors.lineStrong),
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: _entrar,
      icon: const Icon(Icons.g_mobiledata, size: 28),
      label: const Text('Entrar com Google'),
    );
  }
}

/// Linha de status da sincronização (só aparece logado).
class _StatusSync extends ConsumerWidget {
  const _StatusSync();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(syncEstadoProvider);
    final (IconData icone, String texto, Color cor) = switch (estado.fase) {
      SyncFase.enviando => (
          Icons.sync,
          'Sincronizando…',
          AppColors.dim,
        ),
      SyncFase.ok => (
          Icons.cloud_done_outlined,
          'Sincronizado${_ha(estado.ultima)}',
          context.accent,
        ),
      SyncFase.erro => (
          Icons.cloud_off_outlined,
          'Sem sincronizar agora — checando conexão/permissão.',
          Colors.orangeAccent,
        ),
      _ => (
          Icons.cloud_queue_outlined,
          'Backup na nuvem ativo.',
          AppColors.dim,
        ),
    };
    return Row(
      children: [
        Icon(icone, size: 16, color: cor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(texto,
              style: TextStyle(color: cor, fontSize: 12.5)),
        ),
      ],
    );
  }

  String _ha(DateTime? t) {
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return ' · agora';
    if (d.inMinutes < 60) return ' · há ${d.inMinutes} min';
    if (d.inHours < 24) return ' · há ${d.inHours} h';
    return ' · há ${d.inDays} d';
  }
}

/// Exportar / importar o backup em arquivo.
class _SecaoBackup extends ConsumerStatefulWidget {
  const _SecaoBackup();

  @override
  ConsumerState<_SecaoBackup> createState() => _SecaoBackupState();
}

class _SecaoBackupState extends ConsumerState<_SecaoBackup> {
  bool _ocupado = false;

  Future<void> _exportar() async {
    setState(() => _ocupado = true);
    try {
      await exportarBackup();
    } catch (e) {
      _aviso('Não foi possível exportar: $e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _importar() async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Restaurar backup?'),
        content: const Text(
            'Os dados do arquivo vão SUBSTITUIR os treinos, progressão e '
            'check-ins atuais deste aparelho. Continuar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Restaurar')),
        ],
      ),
    );
    if (confirma != true) return;

    setState(() => _ocupado = true);
    try {
      final r = await importarBackup(ref);
      _aviso(r.mensagem);
    } catch (e) {
      _aviso('Falha ao importar: $e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  void _aviso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_ocupado) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text,
              side: BorderSide(color: AppColors.lineStrong),
              minimumSize: const Size.fromHeight(48),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _exportar,
            icon: const Icon(Icons.upload_file, size: 20),
            label: const Text('Exportar'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text,
              side: BorderSide(color: AppColors.lineStrong),
              minimumSize: const Size.fromHeight(48),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _importar,
            icon: const Icon(Icons.download, size: 20),
            label: const Text('Importar'),
          ),
        ),
      ],
    );
  }
}

class _OpcaoTema extends StatelessWidget {
  const _OpcaoTema({
    required this.titulo,
    required this.subtitulo,
    required this.cor,
    required this.fundo,
    required this.selecionado,
    required this.onTap,
  });

  final String titulo;
  final String subtitulo;
  final Color cor; // accent do tema
  final Color fundo; // fundo do tema (mini-preview)
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            // Mini-preview: o fundo do tema com uma bolinha do accent.
            Container(
              width: 42,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fundo,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.line),
              ),
              child: Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(subtitulo,
                      style: TextStyle(color: AppColors.dim, fontSize: 12)),
                ],
              ),
            ),
            if (selecionado) Icon(Icons.check_circle, color: cor),
          ],
        ),
      ),
    );
  }
}
