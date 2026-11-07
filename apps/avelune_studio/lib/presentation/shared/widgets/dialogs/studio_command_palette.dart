import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../text/studio_search_text.dart';
import '../../../theme/studio_tokens.dart';
import '../buttons/studio_button.dart';
import '../feedback/studio_notice.dart';
import '../inputs/studio_search_field.dart';

final class StudioCommandEntry {
  const StudioCommandEntry({
    required this.id,
    required this.label,
    required this.group,
    required this.help,
    this.keywords = const [],
    this.shortcut,
    this.example,
    this.unavailable,
    this.executable = true,
  });

  final String id, label, group, help;
  final List<String> keywords;
  final String? shortcut, example, unavailable;
  final bool executable;

  bool get runnable => executable && unavailable == null;
}

List<StudioCommandEntry> studioCommandSearch(
  List<StudioCommandEntry> entries,
  String query,
) {
  final folded = studioSearchText(query).trim();
  if (folded.isEmpty) return entries;
  int score(StudioCommandEntry entry) {
    final label = studioSearchText(entry.label);
    if (label.startsWith(folded)) return 0;
    if (label.contains(folded)) return 1;
    if (entry.keywords.any(
      (keyword) => studioSearchText(keyword).contains(folded),
    )) {
      return 2;
    }
    return 3;
  }

  final matches = [
    for (final entry in entries)
      if (studioSearchMatches(
        '${entry.label} ${entry.keywords.join(' ')} ${entry.group} ${entry.help}',
        query,
      ))
        entry,
  ];
  final order = {for (var i = 0; i < entries.length; i++) entries[i]: i};
  matches.sort((left, right) {
    final byScore = score(left).compareTo(score(right));
    return byScore != 0 ? byScore : order[left]!.compareTo(order[right]!);
  });
  return matches;
}

Future<String?> showStudioCommandPalette(
  BuildContext context, {
  required List<StudioCommandEntry> entries,
  String title = 'Commandes et aide',
}) => showDialog<String>(
  context: context,
  builder: (_) => StudioCommandPalette(entries: entries, title: title),
);

class StudioCommandPalette extends StatefulWidget {
  const StudioCommandPalette({
    super.key,
    required this.entries,
    this.title = 'Commandes et aide',
  });

  final List<StudioCommandEntry> entries;
  final String title;

  @override
  State<StudioCommandPalette> createState() => _StudioCommandPaletteState();
}

class _StudioCommandPaletteState extends State<StudioCommandPalette> {
  final _query = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  var _index = 0;

  List<StudioCommandEntry> get _results =>
      studioCommandSearch(widget.entries, _query.text);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _move(int delta) {
    final count = _results.length;
    if (count == 0) return;
    setState(() => _index = (_index + delta).clamp(0, count - 1));
  }

  void _run(StudioCommandEntry entry) {
    if (!entry.runnable) return;
    Navigator.of(context).pop(entry.id);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final results = _results;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        _move(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _move(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter || LogicalKeyboardKey.numpadEnter:
        if (results.isNotEmpty) {
          _run(results[_index.clamp(0, results.length - 1)]);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        Navigator.of(context).pop();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = _results;
    final selected = results.isEmpty
        ? null
        : results[_index.clamp(0, results.length - 1)];
    final size = MediaQuery.sizeOf(context);
    final narrow = size.width < 760;
    final list = results.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Aucune commande ne correspond. Essayez « falaise », « porte » ou « sol ».',
              style: theme.textTheme.bodyMedium,
            ),
          )
        : ListView.builder(
            key: const ValueKey('command-palette-results'),
            controller: _scroll,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final entry = results[index];
              final active = entry == selected;
              return Semantics(
                selected: active,
                button: true,
                child: Material(
                  type: active
                      ? MaterialType.canvas
                      : MaterialType.transparency,
                  color: active ? theme.colorScheme.primaryContainer : null,
                  borderRadius: BorderRadius.circular(
                    StudioMetrics.controlRadius,
                  ),
                  child: InkWell(
                    key: ValueKey('command-${entry.id}'),
                    canRequestFocus: false,
                    borderRadius: BorderRadius.circular(
                      StudioMetrics.controlRadius,
                    ),
                    onTap: () => setState(() => _index = index),
                    onDoubleTap: () => _run(entry),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            !entry.executable
                                ? Icons.menu_book_outlined
                                : entry.unavailable != null
                                ? Icons.block
                                : Icons.play_arrow_outlined,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: active
                                  ? theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    )
                                  : theme.textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            entry.unavailable != null
                                ? '${entry.group} · indisponible'
                                : entry.group,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
    final detail = selected == null
        ? const SizedBox.shrink()
        : SingleChildScrollView(
            key: const ValueKey('command-palette-help'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(selected.label, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  selected.shortcut == null
                      ? selected.group
                      : '${selected.group} · ${selected.shortcut}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  selected.executable ? 'Comment faire' : 'Définition',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(selected.help),
                if (selected.example != null) ...[
                  const SizedBox(height: 8),
                  Text(selected.example!, style: theme.textTheme.bodySmall),
                ],
                if (selected.unavailable != null) ...[
                  const SizedBox(height: 12),
                  StudioNotice('Indisponible ici. ${selected.unavailable!}'),
                ],
                if (selected.executable) ...[
                  const SizedBox(height: 16),
                  StudioButton(
                    key: const ValueKey('command-palette-run'),
                    label: 'Utiliser cette commande',
                    icon: Icons.play_arrow_outlined,
                    onPressed: selected.runnable ? () => _run(selected) : null,
                  ),
                ],
              ],
            ),
          );
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: (size.height - 48).clamp(240, 560),
        ),
        child: Padding(
          padding: const EdgeInsets.all(StudioMetrics.panelPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Cherchez une commande, un geste ou un mot du lexique. Flèches pour parcourir, Entrée pour utiliser, Échap pour fermer.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Focus(
                onKeyEvent: _onKey,
                canRequestFocus: false,
                skipTraversal: true,
                child: StudioSearchField(
                  key: const ValueKey('command-palette-search'),
                  controller: _query,
                  focusNode: _focus,
                  label: 'Rechercher une commande ou une aide',
                  onChanged: (_) => setState(() => _index = 0),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: narrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: list),
                          const Divider(height: 16),
                          Expanded(child: detail),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: list),
                          const VerticalDivider(width: 24),
                          Expanded(flex: 4, child: detail),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
