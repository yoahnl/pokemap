import 'dart:collection';

import 'package:map_core/map_core.dart';

import 'smart_tile_connection_profile.dart';

enum SmartTilePathPatternId { classic, closedContour }

enum SmartTilePathPatternSlotGroup { primary, corners }

final class SmartTilePathPatternSlot {
  const SmartTilePathPatternSlot({
    required this.mask,
    required this.label,
    required this.group,
    required this.column,
    required this.row,
  });

  final int mask;
  final String label;
  final SmartTilePathPatternSlotGroup group;
  final int column;
  final int row;
}

final class SmartTilePathPattern {
  SmartTilePathPattern({
    required this.id,
    required this.label,
    required this.description,
    required this.configuration,
    required this.primaryColumns,
    required this.primaryRows,
    required Iterable<SmartTilePathPatternSlot> slots,
    this.cornerColumns = 0,
    this.cornerRows = 0,
  }) : slots = UnmodifiableListView<SmartTilePathPatternSlot>(
         List<SmartTilePathPatternSlot>.of(slots),
       );

  final SmartTilePathPatternId id;
  final String label;
  final String description;
  final SmartTileConnectionConfiguration configuration;
  final int primaryColumns;
  final int primaryRows;
  final int cornerColumns;
  final int cornerRows;
  final List<SmartTilePathPatternSlot> slots;

  List<SmartTilePathPatternSlot> get primarySlots =>
      List<SmartTilePathPatternSlot>.unmodifiable(
        slots.where(
          (slot) => slot.group == SmartTilePathPatternSlotGroup.primary,
        ),
      );

  List<SmartTilePathPatternSlot> get cornerSlots =>
      List<SmartTilePathPatternSlot>.unmodifiable(
        slots.where(
          (slot) => slot.group == SmartTilePathPatternSlotGroup.corners,
        ),
      );

  Set<int> get requiredMasks =>
      Set<int>.unmodifiable(slots.map((slot) => slot.mask));
}

final SmartTilePathPattern classicSmartTilePathPattern = SmartTilePathPattern(
  id: SmartTilePathPatternId.classic,
  label: 'Chemin classique',
  description: 'Segments, virages, extrémités et intersections.',
  configuration: const SmartTileConnectionConfiguration(
    topology: SmartTileTopology.cardinal4,
    templateHint: SmartTileTemplateHint.edge16,
  ),
  primaryColumns: 4,
  primaryRows: 4,
  slots: const <SmartTilePathPatternSlot>[
    SmartTilePathPatternSlot(
      mask: 0x0,
      label: 'Îlot',
      group: SmartTilePathPatternSlotGroup.primary,
      column: 0,
      row: 0,
    ),
    SmartTilePathPatternSlot(
      mask: smartTileNorthBit,
      label: 'Extrémité nord',
      group: SmartTilePathPatternSlotGroup.primary,
      column: 1,
      row: 0,
    ),
    SmartTilePathPatternSlot(
      mask: smartTileEastBit,
      label: 'Extrémité est',
      group: SmartTilePathPatternSlotGroup.primary,
      column: 2,
      row: 0,
    ),
    SmartTilePathPatternSlot(
      mask: smartTileSouthBit,
      label: 'Extrémité sud',
      group: SmartTilePathPatternSlotGroup.primary,
      column: 3,
      row: 0,
    ),
    SmartTilePathPatternSlot(
      mask: smartTileWestBit,
      label: 'Extrémité ouest',
      group: SmartTilePathPatternSlotGroup.primary,
      column: 0,
      row: 1,
    ),
    SmartTilePathPatternSlot(
      mask: smartTileNorthBit | smartTileSouthBit,
      label: 'Segment vertical',
      group: SmartTilePathPatternSlotGroup.primary,
      column: 1,
      row: 1,
    ),
    SmartTilePathPatternSlot(
      mask: smartTileEastBit | smartTileWestBit,
      label: 'Segment horizontal',
      group: SmartTilePathPatternSlotGroup.primary,
      column: 2,
      row: 1,
    ),
    SmartTilePathPatternSlot(
      mask: smartTileNorthBit | smartTileEastBit,
      label: 'Virage nord-est',
      group: SmartTilePathPatternSlotGroup.primary,
      column: 3,
      row: 1,
    ),
    SmartTilePathPatternSlot(
      mask: smartTileEastBit | smartTileSouthBit,
      label: 'Virage sud-est',
      group: SmartTilePathPatternSlotGroup.primary,
      column: 0,
      row: 2,
    ),
    SmartTilePathPatternSlot(
      mask: smartTileSouthBit | smartTileWestBit,
      label: 'Virage sud-ouest',
      group: SmartTilePathPatternSlotGroup.primary,
      column: 1,
      row: 2,
    ),
    SmartTilePathPatternSlot(
      mask: smartTileWestBit | smartTileNorthBit,
      label: 'Virage nord-ouest',
      group: SmartTilePathPatternSlotGroup.primary,
      column: 2,
      row: 2,
    ),
    SmartTilePathPatternSlot(
      mask: smartTileNorthBit | smartTileEastBit | smartTileSouthBit,
      label: 'Jonction vers l’ouest',
      group: SmartTilePathPatternSlotGroup.primary,
      column: 3,
      row: 2,
    ),
    SmartTilePathPatternSlot(
      mask: smartTileEastBit | smartTileSouthBit | smartTileWestBit,
      label: 'Jonction vers le nord',
      group: SmartTilePathPatternSlotGroup.primary,
      column: 0,
      row: 3,
    ),
    SmartTilePathPatternSlot(
      mask: smartTileSouthBit | smartTileWestBit | smartTileNorthBit,
      label: 'Jonction vers l’est',
      group: SmartTilePathPatternSlotGroup.primary,
      column: 1,
      row: 3,
    ),
    SmartTilePathPatternSlot(
      mask: smartTileWestBit | smartTileNorthBit | smartTileEastBit,
      label: 'Jonction vers le sud',
      group: SmartTilePathPatternSlotGroup.primary,
      column: 2,
      row: 3,
    ),
    SmartTilePathPatternSlot(
      mask: smartTileCardinalMask,
      label: 'Croisement',
      group: SmartTilePathPatternSlotGroup.primary,
      column: 3,
      row: 3,
    ),
  ],
);

final SmartTilePathPattern closedContourSmartTilePathPattern =
    SmartTilePathPattern(
      id: SmartTilePathPatternId.closedContour,
      label: 'Contour fermé',
      description: 'Une zone remplie, ses bords et ses angles rentrants.',
      configuration: const SmartTileConnectionConfiguration(
        topology: SmartTileTopology.wangCorner4,
        templateHint: SmartTileTemplateHint.corner12,
      ),
      primaryColumns: 3,
      primaryRows: 3,
      cornerColumns: 2,
      cornerRows: 2,
      slots: const <SmartTilePathPatternSlot>[
        SmartTilePathPatternSlot(
          mask: smartTileSouthEastBit,
          label: 'Coin extérieur haut gauche',
          group: SmartTilePathPatternSlotGroup.primary,
          column: 0,
          row: 0,
        ),
        SmartTilePathPatternSlot(
          mask: smartTileSouthWestBit | smartTileSouthEastBit,
          label: 'Bord haut',
          group: SmartTilePathPatternSlotGroup.primary,
          column: 1,
          row: 0,
        ),
        SmartTilePathPatternSlot(
          mask: smartTileSouthWestBit,
          label: 'Coin extérieur haut droit',
          group: SmartTilePathPatternSlotGroup.primary,
          column: 2,
          row: 0,
        ),
        SmartTilePathPatternSlot(
          mask: smartTileNorthEastBit | smartTileSouthEastBit,
          label: 'Bord gauche',
          group: SmartTilePathPatternSlotGroup.primary,
          column: 0,
          row: 1,
        ),
        SmartTilePathPatternSlot(
          mask: smartTileCornerMask,
          label: 'Centre rempli',
          group: SmartTilePathPatternSlotGroup.primary,
          column: 1,
          row: 1,
        ),
        SmartTilePathPatternSlot(
          mask: smartTileNorthWestBit | smartTileSouthWestBit,
          label: 'Bord droit',
          group: SmartTilePathPatternSlotGroup.primary,
          column: 2,
          row: 1,
        ),
        SmartTilePathPatternSlot(
          mask: smartTileNorthEastBit,
          label: 'Coin extérieur bas gauche',
          group: SmartTilePathPatternSlotGroup.primary,
          column: 0,
          row: 2,
        ),
        SmartTilePathPatternSlot(
          mask: smartTileNorthWestBit | smartTileNorthEastBit,
          label: 'Bord bas',
          group: SmartTilePathPatternSlotGroup.primary,
          column: 1,
          row: 2,
        ),
        SmartTilePathPatternSlot(
          mask: smartTileNorthWestBit,
          label: 'Coin extérieur bas droit',
          group: SmartTilePathPatternSlotGroup.primary,
          column: 2,
          row: 2,
        ),
        SmartTilePathPatternSlot(
          mask: 0xE0,
          label: 'Coin intérieur haut gauche',
          group: SmartTilePathPatternSlotGroup.corners,
          column: 0,
          row: 0,
        ),
        SmartTilePathPatternSlot(
          mask: 0xD0,
          label: 'Coin intérieur haut droit',
          group: SmartTilePathPatternSlotGroup.corners,
          column: 1,
          row: 0,
        ),
        SmartTilePathPatternSlot(
          mask: 0xB0,
          label: 'Coin intérieur bas droit',
          group: SmartTilePathPatternSlotGroup.corners,
          column: 1,
          row: 1,
        ),
        SmartTilePathPatternSlot(
          mask: 0x70,
          label: 'Coin intérieur bas gauche',
          group: SmartTilePathPatternSlotGroup.corners,
          column: 0,
          row: 1,
        ),
      ],
    );

final List<SmartTilePathPattern> smartTilePathPatterns =
    UnmodifiableListView<SmartTilePathPattern>(<SmartTilePathPattern>[
      classicSmartTilePathPattern,
      closedContourSmartTilePathPattern,
    ]);

SmartTilePathPattern smartTilePathPatternById(SmartTilePathPatternId id) =>
    switch (id) {
      SmartTilePathPatternId.classic => classicSmartTilePathPattern,
      SmartTilePathPatternId.closedContour => closedContourSmartTilePathPattern,
    };

SmartTilePathPattern? smartTilePathPatternForConfiguration({
  required SmartTileTopology topology,
  required SmartTileTemplateHint templateHint,
}) => smartTilePathPatterns
    .where(
      (pattern) =>
          pattern.configuration.topology == topology &&
          pattern.configuration.templateHint == templateHint,
    )
    .firstOrNull;
