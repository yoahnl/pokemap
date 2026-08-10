import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/character_animation_matrix_model.dart';
import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';

class AnimationMatrix extends StatefulWidget {
  const AnimationMatrix({
    super.key,
    required this.model,
    required this.selectedKey,
    required this.onSelected,
  });

  final CharacterAnimationMatrixModel model;
  final CharacterAnimationSlotKey? selectedKey;
  final ValueChanged<CharacterAnimationSlotKey> onSelected;

  @override
  State<AnimationMatrix> createState() => _AnimationMatrixState();
}

class _AnimationMatrixState extends State<AnimationMatrix> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'Animation matrix');
  CharacterAnimationMatrixFilter _filter = CharacterAnimationMatrixFilter.all;
  bool _focused = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleSlots = widget.model.slotsFor(_filter);
    return PokeMapPanel(
      key: const ValueKey<String>('animation-matrix'),
      padding: EdgeInsets.zero,
      expandChild: true,
      child: Focus(
        key: const ValueKey<String>('animation-matrix-focus-ring'),
        focusNode: _focusNode,
        onFocusChange: (focused) => setState(() => _focused = focused),
        onKeyEvent: (_, event) => _handleKey(event, visibleSlots),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Matrice des animations',
                        style: TextStyle(
                          color: context.pokeMapColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${visibleSlots.length} slots visibles · flèches pour naviguer',
                        style: TextStyle(
                          color: context.pokeMapColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  PokeMapSegmentedTabs(
                    tabs: [
                      _filterTab(
                        CharacterAnimationMatrixFilter.all,
                        key: 'all',
                        label: 'Tous',
                        icon: CupertinoIcons.square_grid_2x2,
                      ),
                      _filterTab(
                        CharacterAnimationMatrixFilter.missing,
                        key: 'missing',
                        label: 'À compléter',
                        icon: CupertinoIcons.exclamationmark_triangle,
                      ),
                      _filterTab(
                        CharacterAnimationMatrixFilter.ready,
                        key: 'ready',
                        label: 'Prêts',
                        icon: CupertinoIcons.check_mark_circled,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: context.pokeMapColors.divider, height: 1),
            Expanded(
              child: visibleSlots.isEmpty
                  ? const PokeMapEmptyState(
                      title: 'Aucun slot pour ce filtre',
                      description: 'Choisissez un autre état de la matrice.',
                      icon: Icon(CupertinoIcons.line_horizontal_3_decrease),
                      compact: true,
                    )
                  : ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        for (final row in widget.model.rows)
                          if (row.slots.any(visibleSlots.contains)) ...[
                            _AnimationMatrixRow(
                              row: row,
                              visibleSlots: visibleSlots,
                              selectedKey: widget.selectedKey,
                              matrixFocused: _focused,
                              onSelected: _select,
                            ),
                            const SizedBox(height: 10),
                          ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  PokeMapSegmentedTab _filterTab(
    CharacterAnimationMatrixFilter filter, {
    required String key,
    required String label,
    required IconData icon,
  }) {
    return PokeMapSegmentedTab(
      key: ValueKey<String>('animation-matrix-filter-$key'),
      label: label,
      selected: _filter == filter,
      icon: icon,
      onTap: () => _setFilter(filter),
    );
  }

  void _setFilter(CharacterAnimationMatrixFilter filter) {
    if (_filter == filter) return;
    setState(() => _filter = filter);
    final slots = widget.model.slotsFor(filter);
    if (slots.isEmpty) return;
    if (!slots.any((slot) => slot.key == widget.selectedKey)) {
      widget.onSelected(slots.first.key);
    }
    _focusNode.requestFocus();
  }

  void _select(CharacterAnimationSlotKey key) {
    widget.onSelected(key);
    _focusNode.requestFocus();
  }

  KeyEventResult _handleKey(
    KeyEvent event,
    List<CharacterAnimationMatrixSlot> visibleSlots,
  ) {
    if (event is! KeyDownEvent || visibleSlots.isEmpty) {
      return KeyEventResult.ignored;
    }
    final delta = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowRight || LogicalKeyboardKey.arrowDown => 1,
      LogicalKeyboardKey.arrowLeft || LogicalKeyboardKey.arrowUp => -1,
      _ => 0,
    };
    if (delta == 0) return KeyEventResult.ignored;
    final current = visibleSlots.indexWhere(
      (slot) => slot.key == widget.selectedKey,
    );
    final index = current < 0 ? 0 : (current + delta) % visibleSlots.length;
    final normalized = index < 0 ? visibleSlots.length - 1 : index;
    widget.onSelected(visibleSlots[normalized].key);
    return KeyEventResult.handled;
  }
}

class _AnimationMatrixRow extends StatelessWidget {
  const _AnimationMatrixRow({
    required this.row,
    required this.visibleSlots,
    required this.selectedKey,
    required this.matrixFocused,
    required this.onSelected,
  });

  final CharacterAnimationMatrixRow row;
  final List<CharacterAnimationMatrixSlot> visibleSlots;
  final CharacterAnimationSlotKey? selectedKey;
  final bool matrixFocused;
  final ValueChanged<CharacterAnimationSlotKey> onSelected;

  @override
  Widget build(BuildContext context) {
    final slots = row.slots.where(visibleSlots.contains).toList();
    return Semantics(
      container: true,
      label: 'Animation ${row.displayName}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.displayName,
                  style: TextStyle(
                    color: context.pokeMapColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              PokeMapBadge(
                label: row.required
                    ? 'Requise'
                    : row.mode.name == 'single'
                    ? 'Slot unique'
                    : 'Optionnelle',
                variant: row.required
                    ? PokeMapBadgeVariant.error
                    : PokeMapBadgeVariant.neutral,
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var index = 0; index < slots.length; index++) ...[
                  SizedBox(
                    width: row.mode.name == 'single' ? 220 : 150,
                    child: _AnimationSlotCell(
                      slot: slots[index],
                      selected: selectedKey == slots[index].key,
                      focused: matrixFocused && selectedKey == slots[index].key,
                      onTap: () => onSelected(slots[index].key),
                    ),
                  ),
                  if (index != slots.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimationSlotCell extends StatelessWidget {
  const _AnimationSlotCell({
    required this.slot,
    required this.selected,
    required this.focused,
    required this.onTap,
  });

  final CharacterAnimationMatrixSlot slot;
  final bool selected;
  final bool focused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, variant, icon) = switch (slot.status) {
      CharacterAnimationSlotStatus.defined => (
        '${slot.frameCount} ${slot.frameCount == 1 ? 'frame' : 'frames'}',
        PokeMapBadgeVariant.success,
        CupertinoIcons.check_mark_circled_solid,
      ),
      CharacterAnimationSlotStatus.missingRequired => (
        'Requis manquant',
        PokeMapBadgeVariant.error,
        CupertinoIcons.xmark_circle_fill,
      ),
      CharacterAnimationSlotStatus.missingOptional => (
        'Optionnel manquant',
        PokeMapBadgeVariant.warning,
        CupertinoIcons.minus_circle,
      ),
      CharacterAnimationSlotStatus.invalid => (
        'Invalide',
        PokeMapBadgeVariant.error,
        CupertinoIcons.exclamationmark_triangle_fill,
      ),
    };
    return PokeMapCard(
      key: ValueKey<String>('animation-slot-${slot.key.stableId}'),
      selected: selected,
      focused: focused,
      onTap: onTap,
      keyboardInteractive: false,
      semanticLabel: '${slot.label}, $label',
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _statusColor(context, slot.status), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  slot.label,
                  style: TextStyle(
                    color: context.pokeMapColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          PokeMapBadge(label: label, variant: variant),
          if (slot.issue case final issue?) ...[
            const SizedBox(height: 6),
            Text(
              issue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.pokeMapColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Color _statusColor(BuildContext context, CharacterAnimationSlotStatus status) {
  return switch (status) {
    CharacterAnimationSlotStatus.defined => context.pokeMapColors.success,
    CharacterAnimationSlotStatus.missingRequired ||
    CharacterAnimationSlotStatus.invalid => context.pokeMapColors.error,
    CharacterAnimationSlotStatus.missingOptional =>
      context.pokeMapColors.warning,
  };
}
