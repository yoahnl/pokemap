import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Smart Tile encounter sources', () {
    test('round-trips the encounter behavior on the layer', () {
      const layer = SmartTileLayer(
        id: 'grass',
        name: 'Tall grass',
        presetId: 'grass-preset',
        usage: SmartTileUsage.terrain,
        materialPalette: <String>['', 'tall_grass'],
        field: SmartTileField.cell(semanticCells: <int>[0, 1]),
        encounterBehavior: SmartTileEncounterBehavior(
          materialId: 'tall_grass',
          priority: 7,
          encounter: EncounterZonePayload(
            encounterTableId: 'route_grass',
            encounterKind: EncounterKind.walk,
            battleBackgroundRelativePath: 'assets/battle/forest.png',
          ),
        ),
      );

      final json = layer.toJson();
      final decoded = MapLayer.fromJson(json) as SmartTileLayer;

      expect(decoded, layer);
      expect(json['encounterBehavior'], <String, Object?>{
        'materialId': 'tall_grass',
        'priority': 7,
        'encounter': <String, Object?>{
          'encounterTableId': 'route_grass',
          'encounterKind': 'walk',
          'battleBackgroundRelativePath': 'assets/battle/forest.png',
          'battleMusicPath': null,
          'encounterMusicPath': null,
          // BETA-BAT-019 a ajouté ce champ au payload de rencontre ; cette
          // attente n'avait jamais suivi. La convention du modèle est de
          // sérialiser aussi le vide — les trois champs nuls au-dessus le
          // sont — donc c'est bien l'attente qui était périmée.
          'battleTransitionIds': <String>[],
        },
      });
    });

    test('resolves a painted cell without a gameplay zone', () {
      final map = _mapWithBehavior();

      final resolution = resolveEncounterSourceAtPosition(
        map,
        position: const GridPos(x: 1, y: 0),
        encounterKind: EncounterKind.walk,
      );

      expect(resolution.status, EncounterSourceResolutionStatus.resolved);
      expect(resolution.source?.kind, EncounterSourceKind.smartTileLayer);
      expect(resolution.source?.id, 'smart_tile_layer:grass');
      expect(resolution.source?.encounter.encounterTableId, 'route_grass');
      expect(resolution.source?.priority, 7);
      expect(
        findEncounterSource(
          map,
          kind: EncounterSourceKind.smartTileLayer,
          id: 'smart_tile_layer:grass',
        )?.encounter.encounterTableId,
        'route_grass',
      );
      expect(map.gameplayZones, isEmpty);
    });

    test('does not resolve an empty or hidden cell', () {
      final map = _mapWithBehavior();
      final hidden = map.copyWith(
        layers: <MapLayer>[
          (map.layers.single as SmartTileLayer).copyWith(isVisible: false),
        ],
      );

      expect(
        resolveEncounterSourceAtPosition(
          map,
          position: const GridPos(x: 0, y: 0),
          encounterKind: EncounterKind.walk,
        ).status,
        EncounterSourceResolutionStatus.noSource,
      );
      expect(
        resolveEncounterSourceAtPosition(
          hidden,
          position: const GridPos(x: 1, y: 0),
          encounterKind: EncounterKind.walk,
        ).status,
        EncounterSourceResolutionStatus.noSource,
      );
    });

    test('reports an ambiguity between a layer and a manual zone', () {
      final map = _mapWithBehavior().copyWith(
        gameplayZones: const <MapGameplayZone>[
          MapGameplayZone(
            id: 'manual-grass',
            kind: GameplayZoneKind.encounter,
            area: MapRect(
              pos: GridPos(x: 1, y: 0),
              size: GridSize(width: 1, height: 1),
            ),
            priority: 7,
            encounter: EncounterZonePayload(
              encounterTableId: 'route_grass',
              encounterKind: EncounterKind.walk,
              battleMusicPath: 'audio/manual-grass.ogg',
            ),
          ),
        ],
      );

      final resolution = resolveEncounterSourceAtPosition(
        map,
        position: const GridPos(x: 1, y: 0),
        encounterKind: EncounterKind.walk,
      );

      expect(resolution.status, EncounterSourceResolutionStatus.ambiguous);
      expect(
        resolution.ambiguousSourceIds,
        <String>['manual-grass', 'smart_tile_layer:grass'],
      );
      expect(
        () => MapValidator.validate(
          map,
          projectDialogueContext: _project(),
        ),
        _throwsCode('encounter.source_ambiguous'),
      );
    });

    test('validates material, visibility, table, and duplicate projections', () {
      final project = _project();
      final base = _mapWithBehavior();
      final layer = base.layers.single as SmartTileLayer;
      final invalidMaterial = base.copyWith(
        layers: <MapLayer>[
          layer.copyWith(
            encounterBehavior: layer.encounterBehavior!.copyWith(
              materialId: 'missing',
            ),
          ),
        ],
      );
      final hidden = base.copyWith(
        layers: <MapLayer>[layer.copyWith(isVisible: false)],
      );
      final empty = base.copyWith(
        layers: <MapLayer>[
          layer.copyWith(
            field: const SmartTileField.cell(
              semanticCells: <int>[0, 0, 0, 0, 0, 0],
            ),
          ),
        ],
      );
      final unknownTable = base.copyWith(
        layers: <MapLayer>[
          layer.copyWith(
            encounterBehavior: layer.encounterBehavior!.copyWith(
              encounter: layer.encounterBehavior!.encounter.copyWith(
                encounterTableId: 'missing',
              ),
            ),
          ),
        ],
      );
      final duplicated = base.copyWith(
        gameplayZones: const <MapGameplayZone>[
          MapGameplayZone(
            id: 'generated',
            kind: GameplayZoneKind.encounter,
            area: MapRect(
              pos: GridPos(x: 1, y: 0),
              size: GridSize(width: 1, height: 1),
            ),
            encounter: EncounterZonePayload(
              encounterTableId: 'route_grass',
              encounterKind: EncounterKind.walk,
            ),
            smartTileProvenance: SmartTileGameplayZoneProvenance(
              smartTileLayerId: 'grass',
              smartTilePresetId: 'grass-preset',
              materialId: 'tall_grass',
              behaviorKey: 'encounter.walk',
            ),
          ),
        ],
      );

      expect(
        () => MapValidator.validate(invalidMaterial),
        _throwsCode('smart_tile_encounter_material_unknown'),
      );
      expect(
        () => MapValidator.validate(hidden),
        _throwsCode('smart_tile_encounter_layer_hidden'),
      );
      expect(
        () => MapValidator.validate(empty),
        _throwsCode('smart_tile_encounter_layer_empty'),
      );
      expect(
        () => MapValidator.validate(
          unknownTable,
          projectDialogueContext: project,
        ),
        _throwsCode('encounter.table_unknown'),
      );
      expect(
        () => MapValidator.validate(
          duplicated,
          projectDialogueContext: project,
        ),
        _throwsCode('encounter.smart_tile_duplicate_representation'),
      );
    });
  });
}

Matcher _throwsCode(String code) {
  return throwsA(
    isA<ValidationException>().having(
      (error) => error.code,
      'code',
      code,
    ),
  );
}

MapData _mapWithBehavior() {
  return const MapData(
    id: 'route',
    name: 'Route',
    size: GridSize(width: 3, height: 2),
    layers: <MapLayer>[
      SmartTileLayer(
        id: 'grass',
        name: 'Tall grass',
        presetId: 'grass-preset',
        usage: SmartTileUsage.terrain,
        materialPalette: <String>['', 'tall_grass'],
        field: SmartTileField.cell(
          semanticCells: <int>[0, 1, 0, 0, 1, 0],
        ),
        encounterBehavior: SmartTileEncounterBehavior(
          materialId: 'tall_grass',
          priority: 7,
          encounter: EncounterZonePayload(
            encounterTableId: 'route_grass',
            encounterKind: EncounterKind.walk,
          ),
        ),
      ),
    ],
  );
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Project',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
    encounterTables: <ProjectEncounterTable>[
      ProjectEncounterTable(
        id: 'route_grass',
        name: 'Route grass',
        encounterKind: EncounterKind.walk,
        entries: <ProjectEncounterEntry>[
          ProjectEncounterEntry(
            speciesId: 'pidgey',
            minLevel: 3,
            maxLevel: 3,
          ),
        ],
      ),
    ],
    smartTileCatalog: ProjectSmartTileCatalog(
      materials: const <ProjectSmartTileMaterial>[
        ProjectSmartTileMaterial(
          id: 'tall_grass',
          name: 'Tall grass',
          connectionGroupId: 'ground',
        ),
      ],
      presets: const <ProjectSmartTilePreset>[
        ProjectSmartTilePreset(
          id: 'grass-preset',
          name: 'Grass',
          usage: SmartTileUsage.terrain,
          topology: SmartTileTopology.uniform,
          templateHint: SmartTileTemplateHint.simple,
          coveragePolicy: SmartTileCoveragePolicy.sparse,
          coverageProfile: SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.template,
          ),
          transformPolicy: SmartTileTransformPolicy(),
          defaultMaterialId: 'tall_grass',
          allowedMaterialIds: <String>['tall_grass'],
        ),
      ],
    ),
  );
}
