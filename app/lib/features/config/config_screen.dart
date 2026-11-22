import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/auth_service.dart';
import '../../services/backup_service.dart';
import '../../services/cards_repository.dart';
import '../../services/checkin_repository.dart';
import '../../services/conclusao_repository.dart';
import '../../services/conquistas_repository.dart';
import '../../services/escudo_repository.dart';
import '../../services/gamificacao_pref.dart';
import '../../services/idioma_repository.dart';
import '../../services/insignias_repository.dart';
import '../../services/lembretes_service.dart';
import '../../services/medidas_repository.dart';
import '../../services/notas_repository.dart';
import '../../services/progressao_repository.dart';
import '../../services/resumo_claude_service.dart';
import '../../services/som_repository.dart';
import '../../services/sync_service.dart';
import '../../services/tema_repository.dart';
import '../../services/treinos_repository.dart';
import '../../theme/app_colors.dart';
import '../../util/versao.dart';
import '../../util/dias.dart';
import '../../util/flags.dart';
import '../../util/gamificacao.dart' show diasAgendados;
import '../../l10n/strings.dart';
import '../lab/lab_screen.dart';

/// Configurações do app em lista única, agrupada por títulos curtos:
/// Aparência, Treino, Conta e Dados. Cada item tem título + uma linha curta +
/// seta (abre/expande) ou chave (liga/desliga). Só visual — nenhuma lógica
/// das opções foi alterada.
class ConfigScreen extends ConsumerWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final som = ref.watch(somProvider).value ?? true;
    final gami = ref.watch(gamificacaoProvider).value ?? true;
    final cardsPre = ref.watch(cardsPreTreinoProvider).value ?? true;
    final idioma = ref.watch(idiomaProvider).value ?? Idioma.pt;
    final s = Strings(idioma);
    return Scaffold(
      appBar: AppBar(title: Text(s.configTitulo)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _GrupoTitulo(s.grupoAparencia),
          const SizedBox(height: 8),
          const _Cartao(children: [_SecaoTema(), _Div(), _SecaoIdioma()]),
          const SizedBox(height: 16),
          _GrupoTitulo(s.grupoTreino),
          const SizedBox(height: 8),
          _Cartao(
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                value: som,
                onChanged: (v) =>
                    ref.read(somProvider.notifier).definir(v),
                activeThumbColor: context.accent,
                title: Text(
                  s.som,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  s.somDesc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.dim, fontSize: 13),
                ),
              ),
              const _Div(),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                value: gami,
                onChanged: (v) =>
                    ref.read(gamificacaoProvider.notifier).definir(v),
                activeThumbColor: context.accent,
                title: Text(
                  s.gamificacao,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  s.gamificacaoDesc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.dim, fontSize: 13),
                ),
              ),
              const _Div(),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                value: cardsPre,
                onChanged: (v) =>
                    ref.read(cardsPreTreinoProvider.notifier).definir(v),
                activeThumbColor: context.accent,
                title: const Text(
                  'Card antes do treino',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                subtitle: Text(
                  'Card motivacional ao iniciar o treino.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.dim, fontSize: 13),
                ),
              ),
              const _Div(),
              const _SecaoLembretes(),
              // 🧪 Laboratório de Animações = ferramenta de DEV. Só aparece no canal
              // de teste (build-apk com --dart-define=LAB=true); no build da Play
              // Store (build-aab, sem o flag) fica oculto. Ver util/flags.dart.
              if (kMostrarLab) ...[const _Div(), const _TileLab()],
            ],
          ),
          const SizedBox(height: 16),
          _GrupoTitulo(s.conta),
          const SizedBox(height: 8),
          _ItemExpansivel(
            titulo: s.conta,
            descricao: s.contaDesc,
            child: const _SecaoConta(),
          ),
          const SizedBox(height: 16),
          _GrupoTitulo(s.grupoDados),
          const SizedBox(height: 8),
          _ItemExpansivel(
            titulo: s.backupArquivo,
            descricao: s.backupDesc,
            child: const _SecaoBackup(),
          ),
          const SizedBox(height: 10),
          _ItemExpansivel(
            titulo: s.resumoClaudeTitulo,
            descricao: s.resumoClaudeDesc,
            child: const _SecaoResumoClaude(),
          ),
          const SizedBox(height: 28),
          Center(
            child: Text(
              'Calis Timer · v$kVersao',
              style: TextStyle(
                color: AppColors.dim2,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Título curto de grupo ("Aparência", "Treino"...): uma linha, sem descrição.
class _GrupoTitulo extends StatelessWidget {
  const _GrupoTitulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        texto,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.dim,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Cartão de grupo: fundo surface, cantos arredondados, borda sutil.
/// Os filhos cuidam do próprio respiro interno; [_Div] separa os itens.
class _Cartao extends StatelessWidget {
  const _Cartao({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Separador fino entre itens de um [_Cartao].
class _Div extends StatelessWidget {
  const _Div();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.line,
      indent: 14,
      endIndent: 14,
    );
  }
}

/// Item expansível: título + uma linha curta + seta (⌄/›); tocar abre o
/// conteúdo ([child]) dentro do próprio cartão. Usado por Conta, Backup e
/// Resumo — a lógica interna de cada um não mudou.
class _ItemExpansivel extends StatefulWidget {
  const _ItemExpansivel({
    required this.titulo,
    required this.descricao,
    required this.child,
  });

  final String titulo;
  final String descricao;
  final Widget child;

  @override
  State<_ItemExpansivel> createState() => _ItemExpansivelState();
}

class _ItemExpansivelState extends State<_ItemExpansivel> {
  bool _aberto = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _aberto = !_aberto),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.descricao,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.dim,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _aberto ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.dim,
                  ),
                ],
              ),
            ),
          ),
          if (_aberto)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}

/// Linha do Laboratório dentro do grupo Treino (só com o flag LAB de dev).
class _TileLab extends StatelessWidget {
  const _TileLab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Text('🧪', style: TextStyle(fontSize: 22)),
        title: const Text(
          'Laboratório de Animações',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        subtitle: Text(
          'Testes de animação, sem mexer no progresso.',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppColors.dim, fontSize: 13),
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.dim),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const LabScreen())),
      ),
    );
  }
}

class _SecaoTema extends ConsumerStatefulWidget {
  const _SecaoTema();

  @override
  ConsumerState<_SecaoTema> createState() => _SecaoTemaState();
}

class _SecaoTemaState extends ConsumerState<_SecaoTema> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final tema = ref.watch(temaProvider).value ?? TemaApp.ambar;
    final idioma = ref.watch(idiomaProvider).value ?? Idioma.pt;
    final s = Strings(idioma);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expandido = !_expandido),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.tema,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.temaDesc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.dim, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(
                _expandido ? Icons.expand_less : Icons.expand_more,
                color: AppColors.dim,
              ),
            ],
          ),
        ),
        if (_expandido) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              for (final o in const [
                (TemaApp.ambar, 'Âmbar'),
                (TemaApp.azul, 'Azul'),
              ])
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: o.$1 == TemaApp.ambar ? 5 : 0,
                      left: o.$1 == TemaApp.azul ? 5 : 0,
                    ),
                    child: _OpcaoTema(
                      titulo: o.$2,
                      cor: AppColors.accentDoTema(o.$1),
                      fundo: AppColors.fundoDoTema(o.$1),
                      selecionado: tema == o.$1,
                      onTap: () =>
                          ref.read(temaProvider.notifier).definir(o.$1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final o in const [
                (TemaApp.espresso, 'Expresso'),
                (TemaApp.madeira, 'Madeira'),
              ])
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: o.$1 == TemaApp.espresso ? 5 : 0,
                      left: o.$1 == TemaApp.madeira ? 5 : 0,
                    ),
                    child: _OpcaoTema(
                      titulo: o.$2,
                      cor: AppColors.accentDoTema(o.$1),
                      fundo: AppColors.fundoDoTema(o.$1),
                      selecionado: tema == o.$1,
                      onTap: () =>
                          ref.read(temaProvider.notifier).definir(o.$1),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
      ),
    );
  }
}

class _SecaoIdioma extends ConsumerStatefulWidget {
  const _SecaoIdioma();

  @override
  ConsumerState<_SecaoIdioma> createState() => _SecaoIdiomaState();
}

class _SecaoIdiomaState extends ConsumerState<_SecaoIdioma> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final idioma = ref.watch(idiomaProvider).value ?? Idioma.pt;
    final s = Strings(idioma);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expandido = !_expandido),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.idiomaLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.idiomaDesc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.dim, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(
                _expandido ? Icons.expand_less : Icons.expand_more,
                color: AppColors.dim,
              ),
            ],
          ),
        ),
        if (_expandido) ...[
          const SizedBox(height: 14),
          for (final o in Idioma.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _OpcaoIdioma(
                idioma: o,
                selecionado: idioma == o,
                onTap: () => ref.read(idiomaProvider.notifier).definir(o),
              ),
            ),
        ],
      ],
      ),
    );
  }
}

class _OpcaoIdioma extends StatelessWidget {
  const _OpcaoIdioma({
    required this.idioma,
    required this.selecionado,
    required this.onTap,
  });

  final Idioma idioma;
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
            color: selecionado ? context.accent : AppColors.line,
            width: selecionado ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(switch (idioma) {
              Idioma.pt => '🇧🇷',
              Idioma.en => '🇺🇸',
              Idioma.es => '🇪🇸',
            }, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                idioma.nomeNativo,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (selecionado) Icon(Icons.check_circle, color: context.accent),
          ],
        ),
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

class _SecaoLembretes extends ConsumerStatefulWidget {
  const _SecaoLembretes();

  @override
  ConsumerState<_SecaoLembretes> createState() => _SecaoLembretesState();
}

class _SecaoLembretesState extends ConsumerState<_SecaoLembretes> {
  bool _mostrarHorarios = false;

  @override
  Widget build(BuildContext context) {
    final config =
        ref.watch(lembretesConfigProvider).value ?? LembretesConfig.vazio;
    final treinos = ref.watch(treinosProvider).value ?? const [];
    final dias = diasAgendados(treinos).toList()..sort();
    final idioma = ref.watch(idiomaProvider).value ?? Idioma.pt;
    final s = Strings(idioma);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: config.ativo,
          onChanged: (v) {
            ref.read(lembretesConfigProvider.notifier).definirAtivo(v);
            if (!v) setState(() => _mostrarHorarios = false);
          },
          activeThumbColor: context.accent,
          title: Text(
            s.lembrarTreinar,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          subtitle: Text(
            config.ativo ? s.lembrarDescOn : s.lembrarDescOff,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.dim, fontSize: 13),
          ),
        ),
        if (config.ativo)
          if (dias.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                s.nenhumTreinoAgendado,
                style: TextStyle(color: AppColors.dim, fontSize: 13),
              ),
            )
          else ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                  side: BorderSide(color: AppColors.lineStrong),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () =>
                    setState(() => _mostrarHorarios = !_mostrarHorarios),
                icon: Icon(
                  _mostrarHorarios ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                ),
                label: Text(
                  _mostrarHorarios
                      ? s.ocultarHorarios
                      : '${s.gerenciarHorarios} · ${s.diasCount(dias.length)}',
                ),
              ),
            ),
            if (_mostrarHorarios) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < dias.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: AppColors.line),
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
                                .definirHorario(
                                  dias[i],
                                  t.hour * 60 + t.minute,
                                );
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
      ],
      ),
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
            Icon(
              Icons.notifications_active_outlined,
              size: 20,
              color: AppColors.dim,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                nomesDiasLongos[dia],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              _hhmm(minutos),
              style: TextStyle(
                color: context.accent,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Não foi possível entrar: $e')));
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
                      Text(
                        nome.isEmpty ? 'Conectado' : nome,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          style: TextStyle(
                            color: AppColors.dim,
                            fontSize: 12.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                TextButton(onPressed: _sair, child: const Text('Sair')),
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
      SyncFase.enviando => (Icons.sync, 'Sincronizando…', AppColors.dim),
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
          child: Text(texto, style: TextStyle(color: cor, fontSize: 12.5)),
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
          'check-ins atuais deste aparelho. Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Restaurar'),
          ),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
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

/// Resumo do treino para a Muse: copiar o dia (clipboard) ou gerar o arquivo
/// de 15 dias (share sheet) para colar/anexar no chat. Tudo local e offline —
/// só lê os repositórios, nunca envia nada sozinho.
class _SecaoResumoClaude extends ConsumerStatefulWidget {
  const _SecaoResumoClaude();

  @override
  ConsumerState<_SecaoResumoClaude> createState() =>
      _SecaoResumoClaudeState();
}

class _SecaoResumoClaudeState extends ConsumerState<_SecaoResumoClaude> {
  bool _ocupado = false;

  Future<void> _copiarHoje() async {
    final s = Strings(ref.read(idiomaProvider).value ?? Idioma.pt);
    setState(() => _ocupado = true);
    try {
      final texto = ResumoClaude.textoHoje(
        hoje: DateTime.now(),
        checkins: ref.read(checkinProvider).value ?? const [],
        conclusoes: ref.read(conclusaoProvider).value ?? const [],
        progressoes: ref.read(progressaoProvider).value ?? const [],
        treinos: ref.read(treinosProvider).value ?? const [],
        insignias: ref.read(insigniasProvider).value ?? const [],
        escudos: ref.read(escudoProvider).value ?? const [],
      );
      await Clipboard.setData(ClipboardData(text: texto));
      _aviso(s.resumoCopiado);
    } catch (e) {
      _aviso('Não foi possível copiar: $e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _gerarArquivo() async {
    final s = Strings(ref.read(idiomaProvider).value ?? Idioma.pt);
    setState(() => _ocupado = true);
    try {
      final agora = DateTime.now();
      final texto = ResumoClaude.arquivoQuinzena(
        hoje: agora,
        checkins: ref.read(checkinProvider).value ?? const [],
        conclusoes: ref.read(conclusaoProvider).value ?? const [],
        progressoes: ref.read(progressaoProvider).value ?? const [],
        treinos: ref.read(treinosProvider).value ?? const [],
        conquistas: ref.read(conquistasProvider).value ?? const [],
        insignias: ref.read(insigniasProvider).value ?? const [],
        escudos: ref.read(escudoProvider).value ?? const [],
        medidas: ref.read(medidasProvider).value ?? const [],
        notas: ref.read(notasProvider).value ?? const [],
      );
      final dir = await getTemporaryDirectory();
      final nome =
          'treino-${agora.year}-${agora.month.toString().padLeft(2, '0')}-${agora.day.toString().padLeft(2, '0')}.md';
      final arquivo = File('${dir.path}/$nome');
      await arquivo.writeAsString(texto);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(arquivo.path, mimeType: 'text/markdown')],
          subject: s.resumoClaudeTitulo,
          text: s.resumoArquivoTexto,
        ),
      );
    } catch (e) {
      _aviso('Não foi possível gerar: $e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  void _aviso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings(ref.watch(idiomaProvider).value ?? Idioma.pt);
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _copiarHoje,
            icon: const Icon(Icons.copy_rounded, size: 20),
            label: Text(s.copiarTreinoHoje),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text,
              side: BorderSide(color: AppColors.lineStrong),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _gerarArquivo,
            icon: const Icon(Icons.description_outlined, size: 20),
            label: Text(s.gerarArquivo15dias),
          ),
        ),
      ],
    );
  }
}

class _OpcaoTema extends StatelessWidget {
  const _OpcaoTema({
    required this.titulo,
    required this.cor,
    required this.fundo,
    required this.selecionado,
    required this.onTap,
  });

  final String titulo;
  final Color cor;
  final Color fundo;
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
              child: Text(
                titulo,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (selecionado) Icon(Icons.check_circle, color: cor),
          ],
        ),
      ),
    );
  }
}
