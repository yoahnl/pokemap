import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

const narrativeCommandPaletteKey =
    ValueKey<String>('narrative-command-palette');
const narrativeCommandPaletteSearchKey =
    ValueKey<String>('narrative-command-palette-search');

enum NarrativeCommandPaletteActionKind {
  navigation,
  create,
  validate,
  preview,
  save,
}

@immutable
final class NarrativeCommandPaletteAction {
  const NarrativeCommandPaletteAction({
    required this.id,
    required this.label,
    required this.kind,
    required this.onInvoke,
    this.description,
    this.shortcutLabel,
    this.enabled = true,
  });

  final String id;
  final String label;
  final String? description;
  final String? shortcutLabel;
  final NarrativeCommandPaletteActionKind kind;
  final VoidCallback onInvoke;
  final bool enabled;
}

Future<void> showNarrativeCommandPalette({
  required BuildContext context,
  required NarrativeGlobalSearchIndex index,
  required List<NarrativeCommandPaletteAction> actions,
  required ValueChanged<NarrativeGlobalSearchEntry> onOpenEntry,
}) {
  final colors = context.pokeMapColors;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fermer la palette de commandes',
    barrierColor: colors.chromeBackground.withValues(alpha: 0.8),
    transitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      void dismiss() => Navigator.of(dialogContext).pop();
      return NarrativeCommandPalette(
        index: index,
        actions: actions,
        onOpenEntry: (entry) {
          dismiss();
          onOpenEntry(entry);
        },
        onDismiss: dismiss,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

/// Keyboard-first project search and command launcher.
///
/// The widget consumes a prebuilt immutable index. It never reads disk or
/// performs navigation itself, which keeps stale-result handling and unsaved
/// document guards owned by the product shell.
class NarrativeCommandPalette extends StatefulWidget {
  const NarrativeCommandPalette({
    super.key,
    required this.index,
    required this.actions,
    required this.onOpenEntry,
    required this.onDismiss,
  });

  final NarrativeGlobalSearchIndex index;
  final List<NarrativeCommandPaletteAction> actions;
  final ValueChanged<NarrativeGlobalSearchEntry> onOpenEntry;
  final VoidCallback onDismiss;

  @override
  State<NarrativeCommandPalette> createState() =>
      _NarrativeCommandPaletteState();
}

class _NarrativeCommandPaletteState extends State<NarrativeCommandPalette> {
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _searchFocus = FocusNode(debugLabel: 'command-palette');
  String _query = '';
  int _queryRevision = 0;
  int _selectedIndex = -1;

  @override
  void dispose() {
    _queryController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<_PaletteItem> _items() {
    final normalized = _query.trim().toLowerCase();
    final actions = widget.actions.where((action) {
      if (normalized.isEmpty) return true;
      return action.label.toLowerCase().contains(normalized) ||
          action.id.toLowerCase().contains(normalized);
    });
    final response = widget.index.search(
      NarrativeGlobalSearchQuery(
        text: _query,
        limit: 40,
        requestRevision: _queryRevision,
      ),
    );
    if (response.isStaleComparedTo(widget.index) ||
        response.requestRevision != _queryRevision) {
      return const [];
    }
    return [
      for (final action in actions) _PaletteItem.action(action),
      for (final result in response.results) _PaletteItem.entry(result.entry),
    ];
  }

  void _setQuery(String value) {
    setState(() {
      _query = value;
      _queryRevision++;
      _selectedIndex = -1;
    });
  }

  void _moveSelection(int delta) {
    final items = _items();
    if (items.isEmpty) return;
    setState(() {
      _selectedIndex = (_selectedIndex + delta).clamp(0, items.length - 1);
    });
  }

  void _activateSelected() {
    final items = _items();
    if (items.isEmpty) return;
    final index = _selectedIndex < 0 ? 0 : _selectedIndex;
    items[index].activate(widget);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final items = _items();
    return SafeArea(
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): widget.onDismiss,
          const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
              _moveSelection(1),
          const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
              _moveSelection(-1),
          const SingleActivator(LogicalKeyboardKey.enter): _activateSelected,
        },
        child: FocusTraversalGroup(
          child: Center(
            child: Material(
              type: MaterialType.transparency,
              child: Semantics(
                key: narrativeCommandPaletteKey,
                container: true,
                scopesRoute: true,
                namesRoute: true,
                label: 'Recherche globale Narrative Studio',
                explicitChildNodes: true,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 520,
                    maxWidth: 720,
                    maxHeight: 640,
                  ),
                  child: PokeMapPanel(
                    expandChild: true,
                    padding: const EdgeInsets.all(12),
                    header: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.command,
                            color: colors.brandPrimary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Aller à…',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const PokeMapBadge(label: '⌘ K'),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PokeMapSearchField(
                          key: narrativeCommandPaletteSearchKey,
                          controller: _queryController,
                          focusNode: _searchFocus,
                          autofocus: true,
                          hintText: 'Rechercher un asset, ID ou diagnostic…',
                          semanticLabel: 'Recherche globale',
                          onChanged: _setQuery,
                          onSubmitted: (_) => _activateSelected(),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: items.isEmpty
                              ? const PokeMapEmptyState(
                                  title: 'Aucun résultat',
                                  description:
                                      'Essayez un label, un ID, un tag ou une map.',
                                  icon: Icon(CupertinoIcons.search),
                                )
                              : ListView.separated(
                                  itemCount: items.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 6),
                                  itemBuilder: (context, index) =>
                                      _PaletteItemTile(
                                    item: items[index],
                                    selected: index == _selectedIndex,
                                    onTap: () => items[index].activate(widget),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _PaletteItem {
  const _PaletteItem._({this.action, this.entry});

  const _PaletteItem.action(NarrativeCommandPaletteAction action)
      : this._(action: action);

  const _PaletteItem.entry(NarrativeGlobalSearchEntry entry)
      : this._(entry: entry);

  final NarrativeCommandPaletteAction? action;
  final NarrativeGlobalSearchEntry? entry;

  void activate(NarrativeCommandPalette palette) {
    final command = action;
    if (command != null) {
      if (!command.enabled) return;
      palette.onDismiss();
      command.onInvoke();
      return;
    }
    palette.onOpenEntry(entry!);
  }
}

class _PaletteItemTile extends StatelessWidget {
  const _PaletteItemTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _PaletteItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final action = item.action;
    final entry = item.entry;
    final label = action?.label ?? entry!.label;
    final detail = action == null ? entry!.technicalId : action.description;
    final badge = action == null
        ? _kindLabel(entry!.kind)
        : _actionKindLabel(action.kind);
    final enabled = action?.enabled ?? true;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: '$label, $badge',
      child: PokeMapCard(
        selected: selected,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onTap: enabled ? onTap : null,
        child: Row(
          children: [
            PokeMapIconTile(
              icon: _iconFor(item),
              size: 32,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: enabled ? colors.textPrimary : colors.textDisabled,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            PokeMapBadge(label: action?.shortcutLabel ?? badge),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(_PaletteItem item) {
  final action = item.action;
  if (action != null) {
    return switch (action.kind) {
      NarrativeCommandPaletteActionKind.navigation =>
        CupertinoIcons.arrow_right_circle,
      NarrativeCommandPaletteActionKind.create => CupertinoIcons.add_circled,
      NarrativeCommandPaletteActionKind.validate =>
        CupertinoIcons.checkmark_shield,
      NarrativeCommandPaletteActionKind.preview => CupertinoIcons.play_circle,
      NarrativeCommandPaletteActionKind.save => CupertinoIcons.floppy_disk,
    };
  }
  return switch (item.entry!.kind) {
    NarrativeGlobalSearchKind.map => CupertinoIcons.map,
    NarrativeGlobalSearchKind.storyline => CupertinoIcons.book,
    NarrativeGlobalSearchKind.chapter => CupertinoIcons.bookmark,
    NarrativeGlobalSearchKind.step => CupertinoIcons.flag,
    NarrativeGlobalSearchKind.scene => CupertinoIcons.layers,
    NarrativeGlobalSearchKind.event => CupertinoIcons.bolt_circle,
    NarrativeGlobalSearchKind.cinematic => CupertinoIcons.film,
    NarrativeGlobalSearchKind.dialogue => CupertinoIcons.chat_bubble_2,
    NarrativeGlobalSearchKind.fact => CupertinoIcons.doc_text,
    NarrativeGlobalSearchKind.worldRule => CupertinoIcons.gear_alt,
    NarrativeGlobalSearchKind.media => CupertinoIcons.music_note_2,
    NarrativeGlobalSearchKind.diagnostic =>
      CupertinoIcons.exclamationmark_triangle,
  };
}

String _kindLabel(NarrativeGlobalSearchKind kind) => switch (kind) {
      NarrativeGlobalSearchKind.map => 'Map',
      NarrativeGlobalSearchKind.storyline => 'Storyline',
      NarrativeGlobalSearchKind.chapter => 'Chapitre',
      NarrativeGlobalSearchKind.step => 'Étape',
      NarrativeGlobalSearchKind.scene => 'Scène',
      NarrativeGlobalSearchKind.event => 'Événement',
      NarrativeGlobalSearchKind.cinematic => 'Cinématique',
      NarrativeGlobalSearchKind.dialogue => 'Dialogue',
      NarrativeGlobalSearchKind.fact => 'Fact',
      NarrativeGlobalSearchKind.worldRule => 'World Rule',
      NarrativeGlobalSearchKind.media => 'Média',
      NarrativeGlobalSearchKind.diagnostic => 'Diagnostic',
    };

String _actionKindLabel(NarrativeCommandPaletteActionKind kind) =>
    switch (kind) {
      NarrativeCommandPaletteActionKind.navigation => 'Navigation',
      NarrativeCommandPaletteActionKind.create => 'Créer',
      NarrativeCommandPaletteActionKind.validate => 'Valider',
      NarrativeCommandPaletteActionKind.preview => 'Aperçu',
      NarrativeCommandPaletteActionKind.save => 'Enregistrer',
    };
