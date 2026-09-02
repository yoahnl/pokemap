import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../application/smart_tile_form_projection.dart';
import '../../application/smart_tile_path_pattern.dart';

class SmartTilePathFillStage extends StatelessWidget {
  const SmartTilePathFillStage({
    super.key,
    required this.pattern,
    required this.forms,
    required this.selectedMask,
    required this.atlasWorkbench,
    required this.automaticPreview,
    required this.slotPreviewBuilder,
    required this.onSlotSelected,
    required this.onChangeImage,
    required this.onReset,
    required this.onContinue,
  });

  final SmartTilePathPattern pattern;
  final List<SmartTileFormReadModel> forms;
  final int? selectedMask;
  final Widget atlasWorkbench;
  final Widget automaticPreview;
  final Widget Function(int mask) slotPreviewBuilder;
  final ValueChanged<int> onSlotSelected;
  final VoidCallback onChangeImage;
  final VoidCallback onReset;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final mappedMasks = <int>{
      for (final form in forms)
        if (form.candidates.isNotEmpty) form.mask,
    };
    final mappedCount = pattern.requiredMasks.intersection(mappedMasks).length;
    final total = pattern.slots.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PokeMapSectionHeader(
          title: 'Remplir le patron',
          description:
              'Sélectionnez une case du patron, puis cliquez le morceau correspondant dans votre image.',
          trailing: PokeMapBadge(
            label: '$mappedCount / $total morceaux associés',
            variant: mappedCount == total
                ? PokeMapBadgeVariant.success
                : PokeMapBadgeVariant.info,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final panels = <Widget>[
              _SourcePanel(
                atlasWorkbench: atlasWorkbench,
                onChangeImage: onChangeImage,
              ),
              _PatternPanel(
                pattern: pattern,
                mappedMasks: mappedMasks,
                selectedMask: selectedMask,
                slotPreviewBuilder: slotPreviewBuilder,
                onSlotSelected: onSlotSelected,
              ),
              _PreviewPanel(
                mappedCount: mappedCount,
                total: total,
                child: automaticPreview,
              ),
            ];
            if (constraints.maxWidth >= 1120) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 6, child: panels[0]),
                  const SizedBox(width: 12),
                  Expanded(flex: 5, child: panels[1]),
                  const SizedBox(width: 12),
                  Expanded(flex: 6, child: panels[2]),
                ],
              );
            }
            if (constraints.maxWidth >= 760) {
              return Column(
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: panels[0]),
                      const SizedBox(width: 12),
                      Expanded(child: panels[1]),
                    ],
                  ),
                  const SizedBox(height: 12),
                  panels[2],
                ],
              );
            }
            return Column(
              children: <Widget>[
                panels[0],
                const SizedBox(height: 12),
                panels[1],
                const SizedBox(height: 12),
                panels[2],
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            PokeMapButton(
              key: const Key('smart-tiles-path-reset'),
              onPressed: onReset,
              variant: PokeMapButtonVariant.ghost,
              size: PokeMapButtonSize.small,
              leading: const Icon(CupertinoIcons.arrow_counterclockwise),
              child: const Text('Réinitialiser le patron'),
            ),
            const Spacer(),
            PokeMapButton(
              key: const Key('smart-tiles-path-fill-continue'),
              onPressed: onContinue,
              trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
              child: const Text('Tester ce chemin'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SourcePanel extends StatelessWidget {
  const _SourcePanel({
    required this.atlasWorkbench,
    required this.onChangeImage,
  });

  final Widget atlasWorkbench;
  final VoidCallback onChangeImage;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: PokeMapSectionHeader(
          title: 'Image source',
          description: 'Cliquez directement dans la grille de l’image.',
          trailing: PokeMapButton(
            key: const Key('smart-tiles-path-change-image'),
            onPressed: onChangeImage,
            variant: PokeMapButtonVariant.ghost,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.photo, size: 14),
            child: const Text('Changer l’image'),
          ),
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: atlasWorkbench,
    );
  }
}

class _PatternPanel extends StatelessWidget {
  const _PatternPanel({
    required this.pattern,
    required this.mappedMasks,
    required this.selectedMask,
    required this.slotPreviewBuilder,
    required this.onSlotSelected,
  });

  final SmartTilePathPattern pattern;
  final Set<int> mappedMasks;
  final int? selectedMask;
  final Widget Function(int mask) slotPreviewBuilder;
  final ValueChanged<int> onSlotSelected;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: PokeMapSectionHeader(
          title: 'Patron — ${pattern.label}',
          description: selectedMask == null
              ? 'Choisissez la prochaine case à remplir.'
              : 'Case choisie : cliquez maintenant dans l’image.',
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.start,
        children: <Widget>[
          _SlotGrid(
            key: const Key('smart-tiles-path-primary-grid'),
            columns: pattern.primaryColumns,
            rows: pattern.primaryRows,
            slots: pattern.primarySlots,
            mappedMasks: mappedMasks,
            selectedMask: selectedMask,
            slotPreviewBuilder: slotPreviewBuilder,
            onSlotSelected: onSlotSelected,
          ),
          if (pattern.cornerSlots.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Coins',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                _SlotGrid(
                  key: const Key('smart-tiles-path-corner-grid'),
                  columns: pattern.cornerColumns,
                  rows: pattern.cornerRows,
                  slots: pattern.cornerSlots,
                  mappedMasks: mappedMasks,
                  selectedMask: selectedMask,
                  slotPreviewBuilder: slotPreviewBuilder,
                  onSlotSelected: onSlotSelected,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SlotGrid extends StatelessWidget {
  const _SlotGrid({
    super.key,
    required this.columns,
    required this.rows,
    required this.slots,
    required this.mappedMasks,
    required this.selectedMask,
    required this.slotPreviewBuilder,
    required this.onSlotSelected,
  });

  final int columns;
  final int rows;
  final List<SmartTilePathPatternSlot> slots;
  final Set<int> mappedMasks;
  final int? selectedMask;
  final Widget Function(int mask) slotPreviewBuilder;
  final ValueChanged<int> onSlotSelected;

  @override
  Widget build(BuildContext context) {
    final byPosition = <(int, int), SmartTilePathPatternSlot>{
      for (final slot in slots) (slot.column, slot.row): slot,
    };
    const extent = 58.0;
    return SizedBox(
      width: columns * extent,
      height: rows * extent,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          childAspectRatio: 1,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: columns * rows,
        itemBuilder: (context, index) {
          final column = index % columns;
          final row = index ~/ columns;
          final slot = byPosition[(column, row)]!;
          return PokeMapSelectableTile(
            key: Key('smart-tiles-path-slot-${slot.mask}'),
            label: slot.label,
            selected: selectedMask == slot.mask,
            completed: mappedMasks.contains(slot.mask),
            onPressed: () => onSlotSelected(slot.mask),
            thumbnail: slotPreviewBuilder(slot.mask),
          );
        },
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.mappedCount,
    required this.total,
    required this.child,
  });

  final int mappedCount;
  final int total;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: PokeMapSectionHeader(
          title: 'Aperçu automatique',
          description: 'Le résultat se met à jour après chaque clic.',
          trailing: PokeMapBadge(
            label: '$mappedCount sur $total',
            variant: mappedCount == total
                ? PokeMapBadgeVariant.success
                : PokeMapBadgeVariant.info,
          ),
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: child,
    );
  }
}

class SmartTilePathAutomaticPreview extends StatelessWidget {
  const SmartTilePathAutomaticPreview({
    super.key,
    required this.pattern,
    required this.mappedMasks,
    required this.slotPreviewBuilder,
  });

  final SmartTilePathPattern pattern;
  final Set<int> mappedMasks;
  final Widget Function(int mask) slotPreviewBuilder;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final masks = pattern.id == SmartTilePathPatternId.closedContour
        ? _closedContourPreviewMasks()
        : _classicPathPreviewMasks();
    const columns = 7;
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceSubtle,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: mappedMasks.isEmpty
            ? const PokeMapEmptyState(
                title: 'Associez un premier morceau',
                description:
                    'L’aperçu du chemin apparaîtra ici dès votre premier clic dans l’image.',
                icon: Icon(CupertinoIcons.cursor_rays),
                compact: true,
              )
            : Padding(
                padding: const EdgeInsets.all(8),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    childAspectRatio: 1,
                  ),
                  itemCount: masks.length,
                  itemBuilder: (context, index) {
                    final mask = masks[index];
                    if (mask == null ||
                        !pattern.requiredMasks.contains(mask) ||
                        !mappedMasks.contains(mask)) {
                      return const SizedBox.shrink();
                    }
                    return FittedBox(
                      fit: BoxFit.fill,
                      child: SizedBox.square(
                        dimension: 48,
                        child: slotPreviewBuilder(mask),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

List<int?> _closedContourPreviewMasks() {
  const extent = 8;
  final corners = List<List<bool>>.generate(
    extent,
    (row) => List<bool>.generate(extent, (column) {
      final insideOuter = column >= 1 && column <= 6 && row >= 1 && row <= 6;
      final insideHole = column >= 3 && column <= 4 && row >= 3 && row <= 4;
      return insideOuter && !insideHole;
    }),
  );
  return <int?>[
    for (var row = 0; row < extent - 1; row += 1)
      for (var column = 0; column < extent - 1; column += 1)
        _cornerMaskAt(corners, column: column, row: row),
  ];
}

int? _cornerMaskAt(
  List<List<bool>> corners, {
  required int column,
  required int row,
}) {
  var mask = 0;
  if (corners[row][column]) mask |= smartTileNorthWestBit;
  if (corners[row][column + 1]) mask |= smartTileNorthEastBit;
  if (corners[row + 1][column + 1]) mask |= smartTileSouthEastBit;
  if (corners[row + 1][column]) mask |= smartTileSouthWestBit;
  return mask == 0 ? null : mask;
}

List<int?> _classicPathPreviewMasks() {
  const cells = <(int, int)>{
    (1, 1),
    (2, 1),
    (3, 1),
    (3, 2),
    (3, 3),
    (2, 3),
    (1, 3),
    (3, 4),
    (3, 5),
    (4, 3),
    (5, 3),
  };
  return <int?>[
    for (var row = 0; row < 7; row += 1)
      for (var column = 0; column < 7; column += 1)
        if (!cells.contains((column, row)))
          null
        else
          (cells.contains((column, row - 1)) ? smartTileNorthBit : 0) |
              (cells.contains((column + 1, row)) ? smartTileEastBit : 0) |
              (cells.contains((column, row + 1)) ? smartTileSouthBit : 0) |
              (cells.contains((column - 1, row)) ? smartTileWestBit : 0),
  ];
}
