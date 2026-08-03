import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectSmartTileAuthoringDraft', () {
    test('round-trips every stable authoring stage', () {
      for (final stage in SmartTileAuthoringStage.values) {
        final draft = _draft(lastStage: stage);

        final decoded = ProjectSmartTileAuthoringDraft.fromJson(
          jsonDecode(jsonEncode(draft.toJson())) as Map<String, dynamic>,
        );

        expect(decoded, draft, reason: stage.name);
        expect(decoded.lastStage, stage);
      }
    });

    test('migrates a non-empty v2 catalog to v3 without inventing drafts', () {
      final catalog = ProjectSmartTileCatalog.fromJson(<String, dynamic>{
        'formatVersion': 2,
        'materials': <Object?>[
          <String, Object?>{
            'id': 'grass',
            'name': 'Grass',
            'connectionGroupId': 'ground',
          },
        ],
      });

      expect(catalog.formatVersion, 3);
      expect(catalog.materials.single.id, 'grass');
      expect(catalog.drafts, isEmpty);
      expect(catalog.toJson()['formatVersion'], 3);
    });

    test('v3 preserves an incomplete draft and keeps lists immutable', () {
      final catalog = ProjectSmartTileCatalog(
        drafts: <ProjectSmartTileAuthoringDraft>[_draft()],
      );

      final decoded = ProjectSmartTileCatalog.fromJson(
        jsonDecode(jsonEncode(catalog.toJson())) as Map<String, dynamic>,
      );

      expect(decoded, catalog);
      expect(decoded.isNotEmpty, isTrue);
      expect(decoded.presets, isEmpty);
      expect(decoded.drafts.single.lastStage, SmartTileAuthoringStage.image);
      expect(
        () => decoded.drafts.add(_draft(id: 'other', targetPresetId: 'other')),
        throwsUnsupportedError,
      );
    });

    test('strictly rejects fractional draft integer fields', () {
      final json = _draft().toJson();

      expect(
        () => ProjectSmartTileAuthoringDraft.fromJson(
          <String, dynamic>{...json, 'sortOrder': 1.5},
        ),
        throwsFormatException,
      );
      expect(
        () => ProjectSmartTileAuthoringDraft.fromJson(
          <String, dynamic>{...json, 'seedSalt': 2.5},
        ),
        throwsFormatException,
      );
    });

    test('catalog validation rejects duplicate targets but not incompleteness',
        () {
      final catalog = ProjectSmartTileCatalog(
        drafts: <ProjectSmartTileAuthoringDraft>[
          _draft(),
          _draft(id: 'second'),
        ],
      );

      final diagnostics = validateProjectSmartTileCatalog(
        catalog: catalog,
        projectTilesetIds: const <String>[],
      );

      expect(
        diagnostics.map((item) => item.code),
        contains('smart_tiles.draft.target_in_use'),
      );
      expect(
        diagnostics.map((item) => item.code),
        isNot(contains('smart_tiles.coverage.incomplete')),
      );
    });

    test('catalog validation checks references without requiring publication',
        () {
      final catalog = ProjectSmartTileCatalog(
        drafts: <ProjectSmartTileAuthoringDraft>[
          _draft().copyWith(
            sourcePresetId: 'missing-source',
            sourceTilesetIds: const <String>[],
            materials: const <ProjectSmartTileMaterial>[
              ProjectSmartTileMaterial(
                id: 'grass',
                name: 'Grass',
                connectionGroupId: 'ground',
                categoryId: 'missing-category',
              ),
            ],
            defaultMaterialId: 'grass',
            allowedMaterialIds: const <String>['grass'],
            fallbackRuleId: 'missing-fallback',
          ),
        ],
      );

      final codes = validateProjectSmartTileCatalog(
        catalog: catalog,
        projectTilesetIds: const <String>[],
      ).map((item) => item.code);

      expect(
        codes,
        containsAll(<String>[
          'smart_tiles.reference.preset_missing',
          'smart_tiles.reference.category_missing',
          'smart_tiles.reference.fallback_rule_missing',
        ]),
      );
      expect(codes, isNot(contains('smart_tiles.coverage.incomplete')));
    });

    test('runtime visual resolution never consults authoring drafts', () {
      const map = MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v5,
        size: GridSize(width: 1, height: 1),
        layers: <MapLayer>[
          MapLayer.smartTile(
            id: 'terrain',
            name: 'Terrain',
            presetId: 'grass',
            usage: SmartTileUsage.terrain,
            materialPalette: <String>['', 'grass'],
            field: SmartTileField.cell(semanticCells: <int>[1]),
          ),
        ],
      );
      final catalog = ProjectSmartTileCatalog(
        drafts: <ProjectSmartTileAuthoringDraft>[_draft()],
      );

      final visuals = resolveSmartTileLayerVisuals(
        map: map,
        layer: map.layers.single as SmartTileLayer,
        catalog: catalog,
        pass: SmartTileVisualPass.background,
      );

      expect(visuals, isEmpty);
      expect(catalog.presets, isEmpty);
    });
  });
}

ProjectSmartTileAuthoringDraft _draft({
  String id = 'draft-grass',
  String targetPresetId = 'grass',
  SmartTileAuthoringStage lastStage = SmartTileAuthoringStage.image,
}) {
  return ProjectSmartTileAuthoringDraft(
    id: id,
    targetPresetId: targetPresetId,
    name: 'Grass',
    usage: SmartTileUsage.terrain,
    lastStage: lastStage,
    sourceTilesetIds: const <String>['grass-image'],
  );
}
