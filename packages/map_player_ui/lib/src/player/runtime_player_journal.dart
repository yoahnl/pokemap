import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_input_scope.dart';
import '../foundation/player_menu_components.dart';
import '../foundation/player_paged_layout.dart';
import '../theme/pokemap_player_menu_theme.dart';

class RuntimePlayerJournal extends StatefulWidget {
  const RuntimePlayerJournal({super.key, required this.detail});

  final RuntimePlayerPauseDetailSnapshot detail;

  @override
  State<RuntimePlayerJournal> createState() => _RuntimePlayerJournalState();
}

class _RuntimePlayerJournalState extends State<RuntimePlayerJournal> {
  final _focusNodes = <String, FocusNode>{};
  String? _selectedId;

  RuntimePlayerDetailEntrySnapshot? get _selected =>
      widget.detail.entries
          .where((entry) => entry.id == _selectedId)
          .firstOrNull ??
      widget.detail.entries.firstOrNull;

  FocusNode _focusNode(String id) =>
      _focusNodes.putIfAbsent(id, () => FocusNode(debugLabel: 'Journal $id'));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ModalRoute.of(context)?.isCurrent != false) {
        final selected = _selected;
        if (selected != null) _focusNode(selected.id).requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(RuntimePlayerJournal oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ids = widget.detail.entries.map((entry) => entry.id).toSet();
    for (final id in _focusNodes.keys.toList()) {
      if (!ids.contains(id)) _focusNodes.remove(id)!.dispose();
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _select(String id, {bool requestFocus = false}) {
    if (_selectedId != id) setState(() => _selectedId = id);
    if (requestFocus) _focusNode(id).requestFocus();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final delta = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowDown => 1,
      LogicalKeyboardKey.arrowUp => -1,
      _ => 0,
    };
    if (delta == 0 || widget.detail.entries.isEmpty) {
      return KeyEventResult.ignored;
    }
    final index = widget.detail.entries.indexWhere(
      (entry) => entry.id == _selected?.id,
    );
    final next = (index + delta).clamp(0, widget.detail.entries.length - 1);
    _select(widget.detail.entries[next].id, requestFocus: true);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    final selected = _selected;
    final companion = PlayerCompanionScope.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final wide =
        (companion || MediaQuery.sizeOf(context).aspectRatio > 1) &&
        scale < 1.8;
    return Focus(
      onKeyEvent: _onKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final list = PlayerPagedList(
            key: const ValueKey('journal-list'),
            revealChildKey: selected == null
                ? null
                : ValueKey('journal-entry-${selected.id}'),
            children: [
              for (final entry in widget.detail.entries)
                PlayerMenuSelectableRow(
                  key: ValueKey('journal-entry-${entry.id}'),
                  id: 'journal-entry-${entry.id}',
                  label: [
                    entry.title,
                    if (entry.subtitle case final subtitle?) subtitle,
                  ].join(' · '),
                  labelStyle: theme.label.copyWith(
                    fontSize: companion ? 12 : 14,
                    height: 1.35,
                  ),
                  minimumHeight: companion ? 64 : 56,
                  contentPadding: EdgeInsets.all(companion ? 8 : 12),
                  selected: entry.id == selected?.id,
                  focusNode: _focusNode(entry.id),
                  onFocusChanged: (focused) {
                    if (focused) _select(entry.id);
                  },
                  onPressed: () => _select(entry.id, requestFocus: true),
                ),
            ],
          );
          final detail = PlayerMenuPanel(
            key: const ValueKey('journal-detail'),
            padding: EdgeInsets.all(companion ? 12 : 16),
            child: PlayerPagedList(
              key: ValueKey('journal-detail-${selected?.id}'),
              children: [
                if (selected != null) ...[
                  Text(
                    selected.title,
                    key: const ValueKey('journal-selected-title'),
                    style: theme.title.copyWith(
                      fontSize: companion ? 16 : 20,
                      height: 1.3,
                    ),
                  ),
                  if (selected.subtitle case final subtitle?)
                    Text(
                      subtitle,
                      key: const ValueKey('journal-selected-subtitle'),
                      style: theme.body.copyWith(
                        fontSize: companion ? 13 : 16,
                        height: 1.4,
                      ),
                    ),
                  if (selected.trailingLabel case final trailing?)
                    Text(
                      trailing,
                      key: const ValueKey('journal-selected-status'),
                      style: theme.meta.copyWith(color: theme.secondary),
                    ),
                  if (selected.progress case final progress?)
                    LinearProgressIndicator(
                      key: const ValueKey('journal-selected-progress'),
                      value: progress,
                      color: theme.accent,
                      backgroundColor: theme.recessed,
                    ),
                ],
                if (widget.detail.message case final message?)
                  Text(message, style: theme.body),
              ],
            ),
          );
          return SizedBox.expand(
            key: const ValueKey('runtime-player-detail-quests'),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: companion ? 11 : 42, child: list),
                      SizedBox(width: companion ? 12 : 20),
                      Expanded(flex: companion ? 10 : 58, child: detail),
                    ],
                  )
                : PlayerPagedList(
                    children: [
                      SizedBox(
                        height: math.min(
                          constraints.maxHeight * .5,
                          widget.detail.entries.length.clamp(1, 3) *
                                  (scale >= 1.8 ? 116.0 : 72.0) -
                              8,
                        ),
                        child: list,
                      ),
                      SizedBox(
                        height: math.min(244 * scale, constraints.maxHeight),
                        child: detail,
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
