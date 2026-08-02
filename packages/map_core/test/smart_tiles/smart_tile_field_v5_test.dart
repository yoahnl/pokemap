import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SmartTileField v5 persistence', () {
    const cases = <SmartTileField>[
      SmartTileField.cell(semanticCells: <int>[1, 2]),
      SmartTileField.corner(
        semanticCells: <int>[1, 2],
        corners: <int>[3, 4, 5, 6, 7, 8],
      ),
      SmartTileField.edge(
        semanticCells: <int>[1, 2],
        horizontalEdges: <int>[3, 4, 5, 6],
        verticalEdges: <int>[7, 8, 9],
      ),
      SmartTileField.mixed(
        semanticCells: <int>[1, 2],
        horizontalEdges: <int>[3, 4, 5, 6],
        verticalEdges: <int>[7, 8, 9],
        corners: <int>[10, 11, 12, 13, 14, 15],
      ),
    ];

    for (final field in cases) {
      test('${field.runtimeType} round-trips only its active lattices', () {
        final map = _mapV5(field: field);

        final json = map.toJson();
        final decoded = MapData.fromJson(json);

        expect(decoded, map);
        expect(json['version'], 'v5');
        final layerJson =
            (json['layers'] as List<Object?>).single as Map<String, dynamic>;
        final fieldJson = layerJson['field'] as Map<String, dynamic>;
        expect(fieldJson['semanticCells'], <int>[1, 2]);
        switch (field) {
          case SmartTileCellField():
            expect(fieldJson.keys, <String>{'kind', 'semanticCells'});
          case SmartTileCornerField():
            expect(
              fieldJson.keys,
              <String>{'kind', 'semanticCells', 'corners'},
            );
          case SmartTileEdgeField():
            expect(
              fieldJson.keys,
              <String>{
                'kind',
                'semanticCells',
                'horizontalEdges',
                'verticalEdges',
              },
            );
          case SmartTileMixedField():
            expect(
              fieldJson.keys,
              <String>{
                'kind',
                'semanticCells',
                'horizontalEdges',
                'verticalEdges',
                'corners',
              },
            );
        }
      });
    }

    test('rejects inactive lattices instead of dropping them', () {
      expect(
        () => SmartTileField.fromJson(<String, dynamic>{
          'kind': 'cell',
          'semanticCells': <int>[1],
          'corners': <int>[1, 1, 1, 1],
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('smart_tile_field_inactive_lattice'),
          ),
        ),
      );
    });

    test('rejects fractional lattice indexes instead of truncating them', () {
      expect(
        () => SmartTileField.fromJson(<String, dynamic>{
          'kind': 'cell',
          'semanticCells': <num>[1.5],
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('smart_tile_field_lattice_invalid'),
          ),
        ),
      );
    });

    test('rejects a fractional layer seed instead of truncating it', () {
      final json = _mapV5(
        field: const SmartTileField.cell(semanticCells: <int>[1, 1]),
      ).toJson();
      final layer =
          (json['layers']! as List<Object?>).single as Map<String, dynamic>;
      layer['layerSeed'] = 1.5;

      expect(
        () => MapData.fromJson(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('smart_tile_integer_invalid'),
          ),
        ),
      );
    });
  });

  group('Smart Tile topology compatibility', () {
    test('cell is valid only for uniform, cardinal, and blob topologies', () {
      for (final topology in <SmartTileTopology>[
        SmartTileTopology.uniform,
        SmartTileTopology.cardinal4,
        SmartTileTopology.blob8,
      ]) {
        expect(
          isSmartTileFieldCompatibleWithTopology(
            topology,
            const SmartTileField.cell(),
          ),
          isTrue,
        );
      }
      for (final topology in <SmartTileTopology>[
        SmartTileTopology.wangEdge4,
        SmartTileTopology.wangCorner4,
        SmartTileTopology.wang8,
      ]) {
        expect(
          isSmartTileFieldCompatibleWithTopology(
            topology,
            const SmartTileField.cell(),
          ),
          isFalse,
        );
      }
    });

    test('each Wang topology accepts exactly its matching field', () {
      expect(
        isSmartTileFieldCompatibleWithTopology(
          SmartTileTopology.wangEdge4,
          const SmartTileField.edge(),
        ),
        isTrue,
      );
      expect(
        isSmartTileFieldCompatibleWithTopology(
          SmartTileTopology.wangCorner4,
          const SmartTileField.corner(),
        ),
        isTrue,
      );
      expect(
        isSmartTileFieldCompatibleWithTopology(
          SmartTileTopology.wang8,
          const SmartTileField.mixed(),
        ),
        isTrue,
      );
      expect(
        isSmartTileFieldCompatibleWithTopology(
          SmartTileTopology.wang8,
          const SmartTileField.edge(),
        ),
        isFalse,
      );
    });
  });

  group('Smart Tile persisted identifier validation', () {
    final manifest = ProjectManifest(
      name: 'Project',
      version: ProjectVersion.v5,
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: <ProjectSmartTileMaterial>[
          ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Grass',
            connectionGroupId: 'ground',
          ),
        ],
        presets: <ProjectSmartTilePreset>[
          ProjectSmartTilePreset(
            id: 'grass',
            name: 'Grass',
            usage: SmartTileUsage.terrain,
            topology: SmartTileTopology.uniform,
            templateHint: SmartTileTemplateHint.simple,
            coveragePolicy: SmartTileCoveragePolicy.sparse,
            coverageProfile: SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.template,
            ),
            transformPolicy: SmartTileTransformPolicy(),
            defaultMaterialId: 'grass',
            allowedMaterialIds: <String>['grass'],
          ),
        ],
      ),
    );

    test('rejects a non-canonical preset id instead of trimming at lookup', () {
      final map = _canonicalIdentifierMap(
        presetId: ' grass ',
        materialPalette: const <String>['', 'grass'],
      );

      expect(
        () => MapValidator.validate(map, projectDialogueContext: manifest),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.code,
            'code',
            'smart_tile_layer_identifier_not_canonical',
          ),
        ),
      );
    });

    test('rejects non-canonical palette ids instead of trimming at lookup', () {
      final map = _canonicalIdentifierMap(
        presetId: 'grass',
        materialPalette: const <String>['', ' grass '],
      );

      expect(
        () => MapValidator.validate(map, projectDialogueContext: manifest),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.code,
            'code',
            'smart_tile_layer_identifier_not_canonical',
          ),
        ),
      );
    });
  });
}

MapData _mapV5({required SmartTileField field}) => MapData(
      id: 'field-map',
      name: 'Field map',
      version: ProjectVersion.v5,
      size: const GridSize(width: 2, height: 1),
      layers: <MapLayer>[
        MapLayer.smartTile(
          id: 'terrain',
          name: 'Terrain',
          presetId: 'grass-dirt',
          usage: SmartTileUsage.terrain,
          materialPalette: const <String>['', 'grass', 'dirt'],
          field: field,
        ),
      ],
    );

MapData _canonicalIdentifierMap({
  required String presetId,
  required List<String> materialPalette,
}) =>
    MapData(
      id: 'canonical-id-map',
      name: 'Canonical id map',
      version: ProjectVersion.v5,
      size: const GridSize(width: 1, height: 1),
      layers: <MapLayer>[
        MapLayer.smartTile(
          id: 'terrain',
          name: 'Terrain',
          presetId: presetId,
          usage: SmartTileUsage.terrain,
          materialPalette: materialPalette,
          field: const SmartTileField.cell(semanticCells: <int>[1]),
        ),
      ],
    );
