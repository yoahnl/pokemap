import 'dart:collection';

import 'package:map_core/map_core.dart';

/// Guides visually recognizable by artists when authoring a Smart Tile.
///
/// A guide only describes how already-authored atlas cells relate to native
/// PokeMap masks. It never parses or imports a Tiled file.
enum SmartTileGuideId { erwCorner16 }

final class SmartTileGuideCell {
  const SmartTileGuideCell({
    required this.number,
    required this.deltaColumn,
    required this.deltaRow,
    required this.mask,
    required this.roleLabel,
  });

  final int number;
  final int deltaColumn;
  final int deltaRow;
  final int mask;
  final String roleLabel;
}

final class SmartTileGuideDefinition {
  SmartTileGuideDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.columns,
    required this.rows,
    required this.templateHint,
    required this.topology,
    required Set<SmartTileUsage> supportedUsages,
    required List<SmartTileGuideCell> cells,
  })  : supportedUsages = Set<SmartTileUsage>.unmodifiable(supportedUsages),
        cells = List<SmartTileGuideCell>.unmodifiable(cells) {
    if (columns <= 0 || rows <= 0) {
      throw ArgumentError('A Smart Tile guide must have positive dimensions.');
    }
    if (this.cells.where((cell) => cell.number == 1).length != 1) {
      throw ArgumentError(
          'A Smart Tile guide must define one numbered anchor.');
    }
    if (this.cells.map((cell) => cell.number).toSet().length !=
        this.cells.length) {
      throw ArgumentError('Smart Tile guide numbers must be unique.');
    }
  }

  final SmartTileGuideId id;
  final String name;
  final String description;
  final int columns;
  final int rows;
  final SmartTileTemplateHint templateHint;
  final SmartTileTopology topology;
  final Set<SmartTileUsage> supportedUsages;
  final List<SmartTileGuideCell> cells;

  SmartTileGuideCell get anchorCell =>
      cells.singleWhere((cell) => cell.number == 1);

  SmartTileGuideCell cellByNumber(int number) =>
      cells.singleWhere((cell) => cell.number == number);

  Set<int> get requiredMasks =>
      Set<int>.unmodifiable(cells.map((cell) => cell.mask));

  List<SmartTileGuideCell> cellsForMask(int mask) =>
      List<SmartTileGuideCell>.unmodifiable(
        cells.where((cell) => cell.mask == mask),
      );
}

/// Native transcription of the numbered ERW guide selected by the user.
///
/// The source image is visually a ring. This five-by-five matrix
/// preserves that recognizable shape while keeping offsets expressed in atlas
/// cells. Its sixteen numbered cells represent twelve logical signatures; four
/// signatures deliberately expose a second visual variant. Number 1 is the
/// only anchor the user has to click.
final SmartTileGuideDefinition erwCorner16Guide = SmartTileGuideDefinition(
  id: SmartTileGuideId.erwCorner16,
  name: 'Guide ERW 16',
  description:
      '16 cellules, 12 raccords : choisissez uniquement la cellule nº 1.',
  columns: 5,
  rows: 5,
  templateHint: SmartTileTemplateHint.corner12,
  topology: SmartTileTopology.wangCorner4,
  supportedUsages: const <SmartTileUsage>{SmartTileUsage.path},
  cells: const <SmartTileGuideCell>[
    SmartTileGuideCell(
      number: 1,
      deltaColumn: 0,
      deltaRow: 0,
      mask: 0x10,
      roleLabel: 'Coin nord-ouest — variante A',
    ),
    SmartTileGuideCell(
      number: 2,
      deltaColumn: 0,
      deltaRow: -1,
      mask: 0xB0,
      roleLabel: 'Creux sud-est',
    ),
    SmartTileGuideCell(
      number: 3,
      deltaColumn: 1,
      deltaRow: -1,
      mask: 0x10,
      roleLabel: 'Coin nord-ouest — variante B',
    ),
    SmartTileGuideCell(
      number: 4,
      deltaColumn: 1,
      deltaRow: -2,
      mask: 0x90,
      roleLabel: 'Bord ouest',
    ),
    SmartTileGuideCell(
      number: 5,
      deltaColumn: 1,
      deltaRow: -3,
      mask: 0x80,
      roleLabel: 'Coin sud-ouest — variante A',
    ),
    SmartTileGuideCell(
      number: 6,
      deltaColumn: 0,
      deltaRow: -3,
      mask: 0xD0,
      roleLabel: 'Creux nord-est',
    ),
    SmartTileGuideCell(
      number: 7,
      deltaColumn: 0,
      deltaRow: -4,
      mask: 0x80,
      roleLabel: 'Coin sud-ouest — variante B',
    ),
    SmartTileGuideCell(
      number: 8,
      deltaColumn: -1,
      deltaRow: -4,
      mask: 0xC0,
      roleLabel: 'Bord sud',
    ),
    SmartTileGuideCell(
      number: 9,
      deltaColumn: -2,
      deltaRow: -4,
      mask: 0x40,
      roleLabel: 'Coin sud-est — variante A',
    ),
    SmartTileGuideCell(
      number: 10,
      deltaColumn: -2,
      deltaRow: -3,
      mask: 0xE0,
      roleLabel: 'Creux nord-ouest',
    ),
    SmartTileGuideCell(
      number: 11,
      deltaColumn: -3,
      deltaRow: -3,
      mask: 0x40,
      roleLabel: 'Coin sud-est — variante B',
    ),
    SmartTileGuideCell(
      number: 12,
      deltaColumn: -3,
      deltaRow: -2,
      mask: 0x60,
      roleLabel: 'Bord est',
    ),
    SmartTileGuideCell(
      number: 13,
      deltaColumn: -3,
      deltaRow: -1,
      mask: 0x20,
      roleLabel: 'Coin nord-est — variante A',
    ),
    SmartTileGuideCell(
      number: 14,
      deltaColumn: -2,
      deltaRow: -1,
      mask: 0x70,
      roleLabel: 'Creux sud-ouest',
    ),
    SmartTileGuideCell(
      number: 15,
      deltaColumn: -2,
      deltaRow: 0,
      mask: 0x20,
      roleLabel: 'Coin nord-est — variante B',
    ),
    SmartTileGuideCell(
      number: 16,
      deltaColumn: -1,
      deltaRow: 0,
      mask: 0x30,
      roleLabel: 'Bord nord',
    ),
  ],
);

List<SmartTileGuideDefinition> smartTileGuidesForUsage(
  SmartTileUsage usage,
) =>
    UnmodifiableListView<SmartTileGuideDefinition>(
      <SmartTileGuideDefinition>[
        if (erwCorner16Guide.supportedUsages.contains(usage)) erwCorner16Guide,
      ],
    );

SmartTileGuideDefinition smartTileGuideById(SmartTileGuideId id) =>
    switch (id) {
      SmartTileGuideId.erwCorner16 => erwCorner16Guide,
    };
