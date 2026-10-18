import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/nota.dart';
import '../services/idioma_repository.dart';
import '../services/notas_repository.dart';
import '../services/tema_repository.dart';
import '../theme/app_colors.dart';
import '../l10n/strings.dart';

/// Botão do bloco de notas p/ a AppBar do Check-in — fica À ESQUERDA da
/// pílula de moedas ([MoedasBadge]). Abre a folha [_BlocoNotasSheet].
class NotasButton extends ConsumerWidget {
  const NotasButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(temaProvider);
    final idioma = ref.watch(idiomaProvider).value ?? Idioma.pt;
    final s = Strings(idioma);
    final qtd = ref.watch(notasProvider).value?.length ?? 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: s.blocoNotas,
          icon: const Icon(Icons.sticky_note_2_outlined),
          onPressed: () => abrirBlocoNotas(context),
        ),
        if (qtd > 0)
          Positioned(
            right: 6,
            top: 6,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: context.accent,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$qtd',
                  style: TextStyle(
                    color: context.onAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Abre o bloco de notas (folha modal).
Future<void> abrirBlocoNotas(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _BlocoNotasSheet(),
    );

String _duas(int n) => n.toString().padLeft(2, '0');

String _fmtData(DateTime d) =>
    '${_duas(d.day)}/${_duas(d.month)} ${_duas(d.hour)}:${_duas(d.minute)}';

/// Folha do BLOCO DE NOTAS: várias notas livres + barra de ferramentas com
/// desfazer, editar, limpar, copiar e fechar.
class _BlocoNotasSheet extends ConsumerStatefulWidget {
  const _BlocoNotasSheet();

  @override
  ConsumerState<_BlocoNotasSheet> createState() => _BlocoNotasSheetState();
}

class _BlocoNotasSheetState extends ConsumerState<_BlocoNotasSheet> {
  /// Lendo/escrevendo (true) ou só lendo (false). Alternado pelo botão EDITAR.
  bool _editando = true;

  /// Pilha p/ o DESFAZER: snapshots da lista antes de cada mudança
  /// (adicionar, editar, limpar, excluir). Máx 30.
  final List<List<Nota>> _historico = [];

  final Map<String, TextEditingController> _ctls = {};
  final Map<String, FocusNode> _focos = {};
  final Map<String, Timer> _debounce = {};
  String? _focoPendente;

  @override
  void dispose() {
    for (final c in _ctls.values) {
      c.dispose();
    }
    for (final f in _focos.values) {
      f.dispose();
    }
    for (final t in _debounce.values) {
      t.cancel();
    }
    super.dispose();
  }

  void _empilhar(List<Nota> atuais) {
    final copia = List<Nota>.of(
      atuais.map((n) => Nota(id: n.id, texto: n.texto)),
    );
    if (_historico.isNotEmpty) {
      final topo = _historico.last;
      if (_mesmoConteudo(topo, copia)) return;
    }
    _historico.add(copia);
    if (_historico.length > 30) _historico.removeAt(0);
  }

  bool _mesmoConteudo(List<Nota> a, List<Nota> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].texto != b[i].texto) return false;
    }
    return true;
  }

  void _sincronizarEstrutura(List<Nota> notas) {
    final ids = notas.map((n) => n.id).toSet();
    for (final id in _ctls.keys.toList()) {
      if (!ids.contains(id)) {
        _ctls[id]?.dispose();
        _ctls.remove(id);
        _focos[id]?.dispose();
        _focos.remove(id);
        _debounce[id]?.cancel();
        _debounce.remove(id);
      }
    }
    for (final n in notas) {
      _ctls.putIfAbsent(n.id, () => TextEditingController(text: n.texto));
      _focos.putIfAbsent(n.id, FocusNode.new);
    }
  }

  /// Após DESFAZER / LIMPAR TUDO: joga o texto restaurado nos controles.
  void _recarregarTextos(List<Nota> notas) {
    for (final n in notas) {
      final c = _ctls[n.id];
      if (c != null && c.text != n.texto) {
        c.text = n.texto;
        c.selection = TextSelection.collapsed(offset: c.text.length);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(temaProvider);
    final idioma = ref.watch(idiomaProvider).value ?? Idioma.pt;
    final s = Strings(idioma);
    final async = ref.watch(notasProvider);
    final notas = async.value ?? const <Nota>[];
    _sincronizarEstrutura(notas);

    if (_focoPendente != null) {
      final id = _focoPendente!;
      _focoPendente = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focos[id]?.requestFocus();
      });
    }

    final podeDesfazer = _historico.isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.lineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.sticky_note_2_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.blocoNotas,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  s.notasQtd(notas.length),
                  style: TextStyle(color: AppColors.dim, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Barra de ferramentas: desfazer · editar · limpar · copiar · fechar.
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Ferramenta(
                    icone: Icons.undo_rounded,
                    rotulo: s.desfazer,
                    habilitado: podeDesfazer,
                    onTap: podeDesfazer ? () => _desfazer(s) : null,
                  ),
                  _Ferramenta(
                    icone: _editando
                        ? Icons.done_rounded
                        : Icons.edit_outlined,
                    rotulo: s.editar,
                    habilitado: true,
                    ativo: _editando,
                    onTap: () => setState(() => _editando = !_editando),
                  ),
                  _Ferramenta(
                    icone: Icons.cleaning_services_outlined,
                    rotulo: s.limpar,
                    habilitado: notas.isNotEmpty,
                    onTap: notas.isNotEmpty
                        ? () => _confirmarLimparTudo(s)
                        : null,
                  ),
                  _Ferramenta(
                    icone: Icons.copy_rounded,
                    rotulo: s.copiar,
                    habilitado: notasParaTexto(notas).isNotEmpty,
                    onTap: notasParaTexto(notas).isNotEmpty
                        ? () => _copiarTudo(s, notas)
                        : null,
                  ),
                  _Ferramenta(
                    icone: Icons.close_rounded,
                    rotulo: s.fechar,
                    habilitado: true,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: async.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Center(child: Text('$e')),
                data: (_) {
                  if (notas.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.note_alt_outlined,
                            size: 48,
                            color: AppColors.dim2,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            s.nenhumaNota,
                            style: TextStyle(color: AppColors.dim),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 420),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: notas.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) =>
                          _NotaCard(
                            indice: i,
                            nota: notas[i],
                            ctl: _ctls[notas[i].id]!,
                            foco: _focos[notas[i].id]!,
                            editando: _editando,
                            s: s,
                            onTapCampo: () => _empilhar(notas),
                            onChanged: (v) =>
                                _editarTexto(notas, notas[i].id, v),
                            onLimpar: () =>
                                _limparUma(s, notas, notas[i].id),
                            onCopiar: () =>
                                _copiarUma(s, notas[i].texto),
                            onExcluir: () =>
                                _excluir(s, notas, notas[i].id),
                          ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: context.accent,
                side: BorderSide(color: context.accent),
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => _adicionar(),
              icon: const Icon(Icons.add),
              label: Text(s.novaNota),
            ),
          ],
        ),
      ),
    );
  }

  void _editarTexto(List<Nota> notas, String id, String valor) {
    // Snapshot UMA vez por sessão de edição (no 1º toque já empilhou; aqui
    // só agenda o salvamento com debounce p/ não gravar a cada tecla).
    _debounce[id]?.cancel();
    final ctl = _ctls[id];
    _debounce[id] = Timer(const Duration(milliseconds: 500), () async {
      await ref.read(notasProvider.notifier).atualizar(id, ctl?.text ?? valor);
    });
  }

  Future<void> _adicionar() async {
    final notas = ref.read(notasProvider).value ?? const <Nota>[];
    _empilhar(notas);
    final id = await ref.read(notasProvider.notifier).adicionar();
    setState(() => _focoPendente = id);
  }

  Future<void> _desfazer(Strings s) async {
    if (_historico.isEmpty) return;
    final anterior = _historico.removeLast();
    for (final t in _debounce.values) {
      t.cancel();
    }
    _debounce.clear();
    await ref.read(notasProvider.notifier).restaurar(anterior);
    if (mounted) {
      _sincronizarEstrutura(anterior);
      _recarregarTextos(anterior);
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.desfeito)));
    }
  }

  Future<void> _limparUma(
    Strings s,
    List<Nota> notas,
    String id,
  ) async {
    final ctl = _ctls[id];
    if (ctl == null || ctl.text.isEmpty) return;
    _empilhar(notas);
    ctl.clear();
    await ref.read(notasProvider.notifier).limparTexto(id);
  }

  Future<void> _excluir(Strings s, List<Nota> notas, String id) async {
    _empilhar(notas);
    await ref.read(notasProvider.notifier).remover(id);
    if (mounted) setState(() {});
  }

  Future<void> _confirmarLimparTudo(Strings s) async {
    final notas = ref.read(notasProvider).value ?? const <Nota>[];
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(s.limparNotasTitulo),
        content: Text(s.limparNotasDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              s.apagar,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    _empilhar(notas);
    for (final t in _debounce.values) {
      t.cancel();
    }
    _debounce.clear();
    await ref.read(notasProvider.notifier).limparTudo();
    if (mounted) setState(() {});
  }

  Future<void> _copiarTudo(Strings s, List<Nota> notas) async {
    final texto = notasParaTexto(notas);
    if (texto.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: texto));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(s.copiado)));
  }

  Future<void> _copiarUma(Strings s, String texto) async {
    if (texto.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: texto.trim()));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(s.copiado)));
  }
}

/// Um botão da barra de ferramentas do bloco (ícone + rótulo pequeno).
class _Ferramenta extends StatelessWidget {
  const _Ferramenta({
    required this.icone,
    required this.rotulo,
    required this.habilitado,
    this.ativo = false,
    this.onTap,
  });

  final IconData icone;
  final String rotulo;
  final bool habilitado;
  final bool ativo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cor = !habilitado
        ? AppColors.dim2
        : ativo
        ? context.accent
        : AppColors.text;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: habilitado ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, size: 22, color: cor),
              const SizedBox(height: 3),
              Text(
                rotulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: ativo ? FontWeight.w800 : FontWeight.w500,
                  color: cor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Um cartão de nota: título + data + ações (copiar/limpar/excluir) + campo.
class _NotaCard extends StatelessWidget {
  const _NotaCard({
    required this.indice,
    required this.nota,
    required this.ctl,
    required this.foco,
    required this.editando,
    required this.s,
    required this.onTapCampo,
    required this.onChanged,
    required this.onLimpar,
    required this.onCopiar,
    required this.onExcluir,
  });

  final int indice;
  final Nota nota;
  final TextEditingController ctl;
  final FocusNode foco;
  final bool editando;
  final Strings s;
  final VoidCallback onTapCampo;
  final ValueChanged<String> onChanged;
  final VoidCallback onLimpar;
  final VoidCallback onCopiar;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${s.notaTitulo} ${indice + 1} · ${_fmtData(nota.atualizadoEm)}',
                  style: TextStyle(
                    color: AppColors.dim,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: s.copiar,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.copy_rounded, size: 17, color: AppColors.dim),
                onPressed: onCopiar,
              ),
              IconButton(
                tooltip: s.limpar,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.cleaning_services_outlined,
                  size: 17,
                  color: AppColors.dim,
                ),
                onPressed: onLimpar,
              ),
              IconButton(
                tooltip: s.excluirNota,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.dim,
                ),
                onPressed: onExcluir,
              ),
            ],
          ),
          TextField(
            controller: ctl,
            focusNode: foco,
            readOnly: !editando,
            minLines: 2,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 14,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: editando ? s.notaDica : null,
              hintStyle: TextStyle(color: AppColors.dim2),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.only(
                left: 2,
                right: 6,
                top: 2,
              ),
            ),
            onTap: onTapCampo,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
