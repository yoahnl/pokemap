import 'dart:math' as math;

import 'package:meta/meta.dart' show immutable;
import 'package:xml/xml.dart';

import '../models/smart_tile.dart';

enum TiledWangSetType { corner, edge, mixed }

@immutable
final class TiledWangImportException implements Exception {
  const TiledWangImportException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'TiledWangImportException($code): $message';
}

@immutable
final class TiledAnimationFrame {
  const TiledAnimationFrame({required this.tileId, required this.durationMs});

  final int tileId;
  final int durationMs;
}

@immutable
final class TiledTileMetadata {
  TiledTileMetadata({
    required this.tileId,
    required this.probability,
    Iterable<TiledAnimationFrame> animation = const <TiledAnimationFrame>[],
  }) : animation = List<TiledAnimationFrame>.unmodifiable(animation);

  final int tileId;
  final double probability;
  final List<TiledAnimationFrame> animation;
}

@immutable
final class TiledWangColor {
  const TiledWangColor({
    required this.name,
    required this.colorArgb,
    required this.representativeTileId,
  });

  final String name;
  final int colorArgb;
  final int? representativeTileId;
}

@immutable
final class TiledWangTile {
  TiledWangTile({required this.tileId, required Iterable<int> wangIds})
      : wangIds = List<int>.unmodifiable(wangIds);

  final int tileId;
  final List<int> wangIds;
}

@immutable
final class TiledWangSet {
  TiledWangSet({
    required this.name,
    required this.type,
    required Iterable<TiledWangColor> colors,
    required Iterable<TiledWangTile> tiles,
  })  : colors = List<TiledWangColor>.unmodifiable(colors),
        tiles = List<TiledWangTile>.unmodifiable(tiles);

  final String name;
  final TiledWangSetType type;
  final List<TiledWangColor> colors;
  final List<TiledWangTile> tiles;
}

/// Neutral representation of the portable subset of a Tiled TSX tileset.
///
/// PokeMap does not retain or execute this format. The document only feeds the
/// native Smart Tile compiler during an explicit import.
@immutable
final class TiledWangTilesetDocument {
  TiledWangTilesetDocument({
    required this.name,
    required this.imageSource,
    required this.imageWidth,
    required this.imageHeight,
    required this.tileWidth,
    required this.tileHeight,
    required this.tileCount,
    required this.columns,
    required this.rows,
    required this.margin,
    required this.spacing,
    required Map<int, TiledTileMetadata> tiles,
    required Iterable<TiledWangSet> wangSets,
  })  : tiles = Map<int, TiledTileMetadata>.unmodifiable(tiles),
        wangSets = List<TiledWangSet>.unmodifiable(wangSets);

  final String name;
  final String imageSource;
  final int imageWidth;
  final int imageHeight;
  final int tileWidth;
  final int tileHeight;
  final int tileCount;
  final int columns;
  final int rows;
  final int margin;
  final int spacing;
  final Map<int, TiledTileMetadata> tiles;
  final List<TiledWangSet> wangSets;
}

@immutable
final class TiledWangSetSelection {
  const TiledWangSetSelection({
    required this.wangSetIndex,
    required this.usage,
  });

  final int wangSetIndex;
  final SmartTileUsage usage;
}

@immutable
final class TiledWangImportBundle {
  TiledWangImportBundle({
    required this.atlas,
    required Iterable<ProjectSmartTileMaterial> materials,
    required Iterable<ProjectSmartTileAnimation> animations,
    required Iterable<ProjectSmartTilePreset> presets,
  })  : materials = List<ProjectSmartTileMaterial>.unmodifiable(materials),
        animations = List<ProjectSmartTileAnimation>.unmodifiable(animations),
        presets = List<ProjectSmartTilePreset>.unmodifiable(presets);

  final ProjectSmartTileAtlas atlas;
  final List<ProjectSmartTileMaterial> materials;
  final List<ProjectSmartTileAnimation> animations;
  final List<ProjectSmartTilePreset> presets;

  Map<String, Object?> toJson() => <String, Object?>{
        'atlas': atlas.toJson(),
        'materials': materials.map((item) => item.toJson()).toList(),
        'animations': animations.map((item) => item.toJson()).toList(),
        'presets': presets.map((item) => item.toJson()).toList(),
      };
}

TiledWangTilesetDocument parseTiledWangTileset(String source) {
  final XmlDocument xml;
  try {
    xml = XmlDocument.parse(source.trim());
  } on XmlParserException catch (error) {
    throw TiledWangImportException(
      'smart_tile.tiled.xml_invalid',
      'Le fichier TSX est invalide : ${error.message}',
    );
  }
  final root = xml.rootElement;
  if (root.name.local != 'tileset') {
    throw const TiledWangImportException(
      'smart_tile.tiled.root_invalid',
      'Le document doit contenir un tileset TSX à sa racine.',
    );
  }

  final name = _canonicalName(root.getAttribute('name'), 'Tileset Tiled');
  final tileWidth = _positiveIntAttribute(root, 'tilewidth');
  final tileHeight = _positiveIntAttribute(root, 'tileheight');
  final tileCount = _positiveIntAttribute(root, 'tilecount');
  final columns = _nonNegativeIntAttribute(root, 'columns');
  if (columns == 0) {
    throw const TiledWangImportException(
      'smart_tile.tiled.image_collection_unsupported',
      'Les TSX composés d’une image par tuile ne sont pas encore pris en charge.',
    );
  }
  final margin = _nonNegativeIntAttribute(root, 'margin', fallback: 0);
  final spacing = _nonNegativeIntAttribute(root, 'spacing', fallback: 0);
  final images = root.findElements('image').toList(growable: false);
  if (images.length != 1) {
    throw const TiledWangImportException(
      'smart_tile.tiled.source_image_required',
      'Le TSX doit référencer exactement une image atlas.',
    );
  }
  final image = images.single;
  final imageSource = image.getAttribute('source')?.trim() ?? '';
  if (imageSource.isEmpty) {
    throw const TiledWangImportException(
      'smart_tile.tiled.source_image_required',
      'L’image atlas du TSX ne possède pas de chemin source.',
    );
  }
  final imageWidth = _positiveIntAttribute(image, 'width');
  final imageHeight = _positiveIntAttribute(image, 'height');
  final rows = (tileCount + columns - 1) ~/ columns;

  final tileMetadata = <int, TiledTileMetadata>{};
  for (final tile in root.findElements('tile')) {
    final tileId = _tileId(tile, tileCount: tileCount);
    final probability = _probability(tile.getAttribute('probability'));
    final animation = <TiledAnimationFrame>[];
    final animationElements = tile.findElements('animation').toList();
    if (animationElements.length > 1) {
      throw TiledWangImportException(
        'smart_tile.tiled.animation_invalid',
        'La tuile $tileId possède plusieurs blocs d’animation.',
      );
    }
    if (animationElements.isNotEmpty) {
      for (final frame in animationElements.single.findElements('frame')) {
        final frameTileId = _requiredIntAttribute(frame, 'tileid');
        final durationMs = _positiveIntAttribute(frame, 'duration');
        if (frameTileId < 0 || frameTileId >= tileCount) {
          throw TiledWangImportException(
            'smart_tile.tiled.animation_frame_out_of_bounds',
            'L’animation de la tuile $tileId référence la tuile $frameTileId hors atlas.',
          );
        }
        animation.add(
          TiledAnimationFrame(tileId: frameTileId, durationMs: durationMs),
        );
      }
      if (animation.isEmpty) {
        throw TiledWangImportException(
          'smart_tile.tiled.animation_invalid',
          'L’animation de la tuile $tileId ne contient aucune image.',
        );
      }
    }
    tileMetadata[tileId] = TiledTileMetadata(
      tileId: tileId,
      probability: probability,
      animation: animation,
    );
  }

  final wangSets = <TiledWangSet>[];
  final wangSetContainers = root.findElements('wangsets').toList();
  if (wangSetContainers.length > 1) {
    throw const TiledWangImportException(
      'smart_tile.tiled.wang_sets_invalid',
      'Le TSX contient plusieurs catalogues Wang concurrents.',
    );
  }
  if (wangSetContainers.isNotEmpty) {
    for (final wangSet in wangSetContainers.single.findElements('wangset')) {
      final colors = <TiledWangColor>[];
      for (final color in wangSet.findElements('wangcolor')) {
        final rawTileId = _requiredIntAttribute(color, 'tile');
        colors.add(
          TiledWangColor(
            name: _canonicalName(
              color.getAttribute('name'),
              'Matériau ${colors.length + 1}',
            ),
            colorArgb: _parseColor(color.getAttribute('color')),
            representativeTileId: rawTileId < 0 ? null : rawTileId,
          ),
        );
      }
      if (colors.isEmpty) {
        throw const TiledWangImportException(
          'smart_tile.tiled.wang_colors_required',
          'Un Wang Set importé doit contenir au moins un matériau.',
        );
      }
      final wangTiles = <TiledWangTile>[];
      for (final wangTile in wangSet.findElements('wangtile')) {
        final tileId = _tileId(wangTile, tileCount: tileCount, field: 'tileid');
        final rawWangId = wangTile.getAttribute('wangid')?.trim() ?? '';
        final values = rawWangId
            .split(',')
            .map((value) => int.tryParse(value.trim()))
            .toList(growable: false);
        if (values.length != 8 || values.any((value) => value == null)) {
          throw TiledWangImportException(
            'smart_tile.tiled.wang_id_invalid',
            'La tuile Wang $tileId doit définir exactement huit positions.',
          );
        }
        final wangIds = values.cast<int>();
        if (wangIds.any((value) => value < 0 || value > colors.length)) {
          throw TiledWangImportException(
            'smart_tile.tiled.wang_color_out_of_bounds',
            'La tuile Wang $tileId référence un matériau inexistant.',
          );
        }
        wangTiles.add(TiledWangTile(tileId: tileId, wangIds: wangIds));
      }
      if (wangTiles.isEmpty) {
        throw const TiledWangImportException(
          'smart_tile.tiled.wang_tiles_required',
          'Un Wang Set importé doit contenir au moins une tuile Wang.',
        );
      }
      wangSets.add(
        TiledWangSet(
          name: _canonicalName(
            wangSet.getAttribute('name'),
            'Wang Set ${wangSets.length + 1}',
          ),
          type: _wangSetType(wangSet.getAttribute('type')),
          colors: colors,
          tiles: wangTiles,
        ),
      );
    }
  }
  if (wangSets.isEmpty) {
    throw const TiledWangImportException(
      'smart_tile.tiled.wang_sets_required',
      'Le TSX ne contient aucun Wang Set importable.',
    );
  }

  return TiledWangTilesetDocument(
    name: name,
    imageSource: imageSource,
    imageWidth: imageWidth,
    imageHeight: imageHeight,
    tileWidth: tileWidth,
    tileHeight: tileHeight,
    tileCount: tileCount,
    columns: columns,
    rows: rows,
    margin: margin,
    spacing: spacing,
    tiles: tileMetadata,
    wangSets: wangSets,
  );
}

TiledWangImportBundle compileTiledWangImport({
  required TiledWangTilesetDocument document,
  required String importId,
  required String tilesetId,
  required Iterable<TiledWangSetSelection> selections,
}) {
  final canonicalImportId = importId.trim();
  final canonicalTilesetId = tilesetId.trim();
  if (canonicalImportId.isEmpty || canonicalImportId != importId) {
    throw const TiledWangImportException(
      'smart_tile.tiled.import_id_invalid',
      'L’identifiant technique de l’import est invalide.',
    );
  }
  if (canonicalTilesetId.isEmpty || canonicalTilesetId != tilesetId) {
    throw const TiledWangImportException(
      'smart_tile.tiled.tileset_id_invalid',
      'Le tileset canonique de destination est invalide.',
    );
  }
  final selected = selections.toList(growable: false);
  if (selected.isEmpty) {
    throw const TiledWangImportException(
      'smart_tile.tiled.selection_required',
      'Sélectionnez au moins un Wang Set et son usage.',
    );
  }
  final selectedIndexes = <int>{};
  for (final selection in selected) {
    if (selection.wangSetIndex < 0 ||
        selection.wangSetIndex >= document.wangSets.length) {
      throw const TiledWangImportException(
        'smart_tile.tiled.selection_out_of_bounds',
        'La sélection référence un Wang Set inexistant.',
      );
    }
    if (!selectedIndexes.add(selection.wangSetIndex)) {
      throw const TiledWangImportException(
        'smart_tile.tiled.selection_duplicate',
        'Un Wang Set ne peut être sélectionné qu’une seule fois.',
      );
    }
  }

  final atlasId = '$canonicalImportId-atlas';
  final atlas = ProjectSmartTileAtlas(
    id: atlasId,
    name: document.name,
    tilesetId: canonicalTilesetId,
    cellWidth: document.tileWidth,
    cellHeight: document.tileHeight,
    marginX: document.margin,
    marginY: document.margin,
    spacingX: document.spacing,
    spacingY: document.spacing,
    columns: document.columns,
    rows: document.rows,
  );
  final materials = <ProjectSmartTileMaterial>[];
  final animationsByTile = <int, ProjectSmartTileAnimation>{};
  final presets = <ProjectSmartTilePreset>[];

  for (final selection in selected) {
    final setIndex = selection.wangSetIndex;
    final wangSet = document.wangSets[setIndex];
    final prefix = '$canonicalImportId-w$setIndex';
    final materialIds = <String>[];
    for (var colorIndex = 0; colorIndex < wangSet.colors.length; colorIndex++) {
      final color = wangSet.colors[colorIndex];
      final materialId = '$prefix-material-${colorIndex + 1}';
      materialIds.add(materialId);
      materials.add(
        ProjectSmartTileMaterial(
          id: materialId,
          name: color.name,
          connectionGroupId: '$prefix-connection',
          editorColorArgb: color.colorArgb,
          sortOrder: colorIndex,
        ),
      );
    }

    final grouped = <String, List<TiledWangTile>>{};
    for (final tile in wangSet.tiles) {
      grouped
          .putIfAbsent(tile.wangIds.join(','), () => <TiledWangTile>[])
          .add(tile);
    }
    final rules = <SmartTileRule>[];
    final scenarios = <SmartTileCoverageScenario>[];
    var ruleIndex = 0;
    for (final tiles in grouped.values) {
      final wangIds = tiles.first.wangIds;
      final signature = _signature(
        type: wangSet.type,
        wangIds: wangIds,
        materialIds: materialIds,
      );
      final exactSignature = _exactSignature(
        type: wangSet.type,
        wangIds: wangIds,
        materialIds: materialIds,
      );
      final candidates = <SmartTileCandidate>[];
      for (var candidateIndex = 0;
          candidateIndex < tiles.length;
          candidateIndex++) {
        final tile = tiles[candidateIndex];
        final metadata = document.tiles[tile.tileId];
        final animationFrames =
            metadata?.animation ?? const <TiledAnimationFrame>[];
        final SmartTileVisualSource source;
        if (animationFrames.isEmpty) {
          source = SmartTileVisualSource.frame(
            frame: _frameRef(atlasId, document.columns, tile.tileId),
          );
        } else {
          final animation = animationsByTile.putIfAbsent(
            tile.tileId,
            () => ProjectSmartTileAnimation(
              id: '$canonicalImportId-animation-${tile.tileId}',
              name: '${document.name} — tuile ${tile.tileId}',
              frames: <ProjectSmartTileAnimationFrame>[
                for (final frame in animationFrames)
                  ProjectSmartTileAnimationFrame(
                    frame: _frameRef(
                      atlasId,
                      document.columns,
                      frame.tileId,
                    ),
                    durationMs: frame.durationMs,
                  ),
              ],
            ),
          );
          source = SmartTileVisualSource.animation(animationId: animation.id);
        }
        candidates.add(
          SmartTileCandidate(
            id: '$prefix-rule-$ruleIndex-candidate-$candidateIndex',
            weight: math.max(
              1,
              ((metadata?.probability ?? 1) * 1000).round(),
            ),
            parts: <SmartTileVisualPart>[
              SmartTileVisualPart(source: source),
            ],
          ),
        );
      }
      rules.add(
        SmartTileRule(
          id: '$prefix-rule-$ruleIndex',
          centerMatch: const SmartTileSlotMatch.any(),
          signature: signature,
          candidates: candidates,
        ),
      );
      scenarios.add(
        SmartTileCoverageScenario(
          id: '$prefix-scenario-$ruleIndex',
          centerMaterialId: materialIds.first,
          signature: exactSignature,
        ),
      );
      ruleIndex += 1;
    }
    final (topology, templateHint) = _nativeShape(wangSet.type);
    presets.add(
      ProjectSmartTilePreset(
        id: '$prefix-preset',
        name: wangSet.name,
        usage: selection.usage,
        topology: topology,
        templateHint: templateHint,
        status: SmartTilePresetStatus.draft,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.explicit,
          requiredScenarios: scenarios,
        ),
        transformPolicy: const SmartTileTransformPolicy(),
        defaultMaterialId: materialIds.first,
        allowedMaterialIds: materialIds,
        rules: rules,
        tags: const <String>['imported', 'tiled-wang'],
        sortOrder: setIndex,
      ),
    );
  }

  return TiledWangImportBundle(
    atlas: atlas,
    materials: materials,
    animations: animationsByTile.values,
    presets: presets,
  );
}

SmartTileFrameRef _frameRef(String atlasId, int columns, int tileId) {
  return SmartTileFrameRef(
    atlasId: atlasId,
    column: tileId % columns,
    row: tileId ~/ columns,
  );
}

SmartTileSignature _signature({
  required TiledWangSetType type,
  required List<int> wangIds,
  required List<String> materialIds,
}) {
  SmartTileSlotMatch slot(int index, {required bool active}) {
    if (!active) return const SmartTileSlotMatch.any();
    final colorId = wangIds[index];
    return colorId == 0
        ? const SmartTileSlotMatch.empty()
        : SmartTileSlotMatch.material(materialIds[colorId - 1]);
  }

  final edges = type != TiledWangSetType.corner;
  final corners = type != TiledWangSetType.edge;
  return SmartTileSignature(
    northEdge: slot(0, active: edges),
    northEastCorner: slot(1, active: corners),
    eastEdge: slot(2, active: edges),
    southEastCorner: slot(3, active: corners),
    southEdge: slot(4, active: edges),
    southWestCorner: slot(5, active: corners),
    westEdge: slot(6, active: edges),
    northWestCorner: slot(7, active: corners),
  );
}

SmartTileExactSignature _exactSignature({
  required TiledWangSetType type,
  required List<int> wangIds,
  required List<String> materialIds,
}) {
  String? slot(int index, {required bool active}) {
    if (!active || wangIds[index] == 0) return null;
    return materialIds[wangIds[index] - 1];
  }

  final edges = type != TiledWangSetType.corner;
  final corners = type != TiledWangSetType.edge;
  return SmartTileExactSignature(
    northEdge: slot(0, active: edges),
    northEastCorner: slot(1, active: corners),
    eastEdge: slot(2, active: edges),
    southEastCorner: slot(3, active: corners),
    southEdge: slot(4, active: edges),
    southWestCorner: slot(5, active: corners),
    westEdge: slot(6, active: edges),
    northWestCorner: slot(7, active: corners),
  );
}

(SmartTileTopology, SmartTileTemplateHint) _nativeShape(
  TiledWangSetType type,
) {
  return switch (type) {
    TiledWangSetType.corner => (
        SmartTileTopology.wangCorner4,
        SmartTileTemplateHint.corner16,
      ),
    TiledWangSetType.edge => (
        SmartTileTopology.wangEdge4,
        SmartTileTemplateHint.edge16,
      ),
    TiledWangSetType.mixed => (
        SmartTileTopology.wang8,
        SmartTileTemplateHint.mixed256,
      ),
  };
}

TiledWangSetType _wangSetType(String? value) {
  return switch (value?.trim().toLowerCase()) {
    'corner' => TiledWangSetType.corner,
    'edge' => TiledWangSetType.edge,
    'mixed' => TiledWangSetType.mixed,
    _ => throw TiledWangImportException(
        'smart_tile.tiled.wang_type_unsupported',
        'Le type de Wang Set « ${value ?? ''} » n’est pas pris en charge.',
      ),
  };
}

int _tileId(
  XmlElement element, {
  required int tileCount,
  String field = 'id',
}) {
  final value = _requiredIntAttribute(element, field);
  if (value < 0 || value >= tileCount) {
    throw TiledWangImportException(
      'smart_tile.tiled.tile_out_of_bounds',
      'La tuile $value est hors des limites du tileset.',
    );
  }
  return value;
}

int _positiveIntAttribute(XmlElement element, String field) {
  final value = _requiredIntAttribute(element, field);
  if (value <= 0) {
    throw TiledWangImportException(
      'smart_tile.tiled.number_invalid',
      'L’attribut $field doit être strictement positif.',
    );
  }
  return value;
}

int _nonNegativeIntAttribute(
  XmlElement element,
  String field, {
  int? fallback,
}) {
  final raw = element.getAttribute(field);
  if (raw == null && fallback != null) return fallback;
  final value = int.tryParse(raw ?? '');
  if (value == null || value < 0) {
    throw TiledWangImportException(
      'smart_tile.tiled.number_invalid',
      'L’attribut $field doit être un entier positif ou nul.',
    );
  }
  return value;
}

int _requiredIntAttribute(XmlElement element, String field) {
  final value = int.tryParse(element.getAttribute(field) ?? '');
  if (value == null) {
    throw TiledWangImportException(
      'smart_tile.tiled.number_invalid',
      'L’attribut $field doit être un entier.',
    );
  }
  return value;
}

double _probability(String? raw) {
  if (raw == null) return 1;
  final value = double.tryParse(raw);
  if (value == null || !value.isFinite || value < 0) {
    throw const TiledWangImportException(
      'smart_tile.tiled.probability_invalid',
      'Une probabilité de tuile Tiled est invalide.',
    );
  }
  return value;
}

int _parseColor(String? raw) {
  final value = raw?.trim() ?? '';
  if (!value.startsWith('#')) {
    throw const TiledWangImportException(
      'smart_tile.tiled.color_invalid',
      'Une couleur Wang est invalide.',
    );
  }
  final hex = value.substring(1);
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null || (hex.length != 6 && hex.length != 8)) {
    throw const TiledWangImportException(
      'smart_tile.tiled.color_invalid',
      'Une couleur Wang est invalide.',
    );
  }
  return hex.length == 6 ? 0xff000000 | parsed : parsed;
}

String _canonicalName(String? value, String fallback) {
  final canonical = value?.trim() ?? '';
  return canonical.isEmpty ? fallback : canonical;
}
