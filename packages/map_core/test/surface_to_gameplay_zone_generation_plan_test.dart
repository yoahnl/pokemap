import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SurfaceGameplayZoneGenerationSource', () {
    test('rejects an empty source', () {
      expect(
        () => SurfaceGameplayZoneGenerationSource(
          surfaceLayerId: 'surfaces',
          surfaceLayerName: 'Surfaces',
          surfacePresetId: 'tall_grass',
          cells: const [],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects an empty surfacePresetId', () {
      expect(
        () => SurfaceGameplayZoneGenerationSource(
          surfaceLayerId: 'surfaces',
          surfaceLayerName: 'Surfaces',
          surfacePresetId: '   ',
          cells: const [GridPos(x: 0, y: 0)],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('deduplicates coordinates and keeps a stable y/x order', () {
      final source = SurfaceGameplayZoneGenerationSource(
        surfaceLayerId: ' surfaces ',
        surfaceLayerName: ' Surfaces ',
        surfacePresetId: ' tall_grass ',
        cells: const [
          GridPos(x: 2, y: 1),
          GridPos(x: 0, y: 0),
          GridPos(x: 2, y: 1),
          GridPos(x: 1, y: 0),
        ],
      );

      expect(source.surfaceLayerId, 'surfaces');
      expect(source.surfaceLayerName, 'Surfaces');
      expect(source.surfacePresetId, 'tall_grass');
      expect(source.cells, const [
        GridPos(x: 0, y: 0),
        GridPos(x: 1, y: 0),
        GridPos(x: 2, y: 1),
      ]);
    });
  });

  group('createSurfaceGameplayZoneGenerationPlan boundingBox', () {
    test('generates one exact zone for a full rectangle', () {
      final plan = createSurfaceGameplayZoneGenerationPlan(
        source: _source(
          const [
            GridPos(x: 1, y: 1),
            GridPos(x: 2, y: 1),
            GridPos(x: 1, y: 2),
            GridPos(x: 2, y: 2),
          ],
        ),
        behavior: _tallGrassBehavior(),
        strategy: SurfaceGameplayZoneGenerationStrategy.boundingBox,
        zoneIdPrefix: 'tall-grass',
        zoneNamePrefix: 'Herbe haute',
      );

      expect(plan.generatedZones, hasLength(1));
      expect(plan.generatedZones.single.id, 'tall-grass');
      expect(plan.generatedZones.single.name, 'Herbe haute');
      expect(
        plan.generatedZones.single.area,
        const MapRect(
          pos: GridPos(x: 1, y: 1),
          size: GridSize(width: 2, height: 2),
        ),
      );
      expect(plan.coverage.isExact, isTrue);
      expect(plan.coverage.extraCellCount, 0);
      expect(plan.diagnostics, isEmpty);
    });

    test('generates one box with extra cells warning for an L shape', () {
      final plan = createSurfaceGameplayZoneGenerationPlan(
        source: _source(
          const [
            GridPos(x: 0, y: 0),
            GridPos(x: 1, y: 0),
            GridPos(x: 0, y: 1),
          ],
        ),
        behavior: _tallGrassBehavior(),
        strategy: SurfaceGameplayZoneGenerationStrategy.boundingBox,
        zoneIdPrefix: 'tall-grass',
        zoneNamePrefix: 'Herbe haute',
      );

      expect(plan.generatedZones, hasLength(1));
      expect(plan.coverage.sourceCellCount, 3);
      expect(plan.coverage.coveredSourceCellCount, 3);
      expect(plan.coverage.missingSourceCellCount, 0);
      expect(plan.coverage.extraCellCount, 1);
      expect(plan.coverage.isExact, isFalse);
      expect(
        plan.diagnostics,
        contains(
          const SurfaceGameplayZoneGenerationDiagnostic(
            severity: SurfaceGameplayZoneGenerationDiagnosticSeverity.warning,
            kind:
                SurfaceGameplayZoneGenerationDiagnosticKind.extraCellsIncluded,
            message: '1 extra cell will be included by generated rectangles.',
          ),
        ),
      );
    });
  });

  group('createSurfaceGameplayZoneGenerationPlan greedyRectangles', () {
    test('generates one exact zone for a full rectangle', () {
      final plan = createSurfaceGameplayZoneGenerationPlan(
        source: _source(
          const [
            GridPos(x: 2, y: 3),
            GridPos(x: 3, y: 3),
            GridPos(x: 2, y: 4),
            GridPos(x: 3, y: 4),
          ],
        ),
        behavior: _tallGrassBehavior(),
        strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
        zoneIdPrefix: 'grass',
        zoneNamePrefix: 'Grass',
      );

      expect(plan.generatedZones, hasLength(1));
      expect(plan.coverage.isExact, isTrue);
      expect(plan.rectangles.single.size, const GridSize(width: 2, height: 2));
    });

    test('splits an L shape into exact rectangles without extra cells', () {
      final plan = createSurfaceGameplayZoneGenerationPlan(
        source: _source(
          const [
            GridPos(x: 0, y: 0),
            GridPos(x: 1, y: 0),
            GridPos(x: 0, y: 1),
          ],
        ),
        behavior: _tallGrassBehavior(),
        strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
        zoneIdPrefix: 'grass',
        zoneNamePrefix: 'Grass',
      );

      expect(plan.generatedZones, hasLength(2));
      expect(plan.rectangles, const [
        MapRect(
          pos: GridPos(x: 0, y: 0),
          size: GridSize(width: 2, height: 1),
        ),
        MapRect(
          pos: GridPos(x: 0, y: 1),
          size: GridSize(width: 1, height: 1),
        ),
      ]);
      expect(plan.coverage.isExact, isTrue);
      expect(plan.coverage.extraCellCount, 0);
      expect(plan.coverage.missingSourceCellCount, 0);
    });

    test('creates one zone per separated island and ignores placement order',
        () {
      final first = createSurfaceGameplayZoneGenerationPlan(
        source: _source(
          const [
            GridPos(x: 5, y: 0),
            GridPos(x: 0, y: 0),
          ],
        ),
        behavior: _tallGrassBehavior(),
        strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
        zoneIdPrefix: 'island',
        zoneNamePrefix: 'Island',
      );
      final second = createSurfaceGameplayZoneGenerationPlan(
        source: _source(
          const [
            GridPos(x: 0, y: 0),
            GridPos(x: 5, y: 0),
          ],
        ),
        behavior: _tallGrassBehavior(),
        strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
        zoneIdPrefix: 'island',
        zoneNamePrefix: 'Island',
      );

      expect(first.rectangles, const [
        MapRect(
          pos: GridPos(x: 0, y: 0),
          size: GridSize(width: 1, height: 1),
        ),
        MapRect(
          pos: GridPos(x: 5, y: 0),
          size: GridSize(width: 1, height: 1),
        ),
      ]);
      expect(second.rectangles, first.rectangles);
      expect(first.generatedZones.map((zone) => zone.id), [
        'island-1',
        'island-2',
      ]);
    });
  });

  group('behavior drafts', () {
    test('generates tall grass encounter payload', () {
      final plan = _oneCellPlan(_tallGrassBehavior());
      final zone = plan.generatedZones.single;

      expect(zone.kind, GameplayZoneKind.encounter);
      expect(zone.encounter, isNotNull);
      expect(zone.encounter!.encounterTableId, 'route-1-grass');
      expect(zone.encounter!.encounterKind, EncounterKind.walk);
      expect(zone.movement, isNull);
      expect(zone.hazard, isNull);
    });

    test('generates surfable water movement payload', () {
      final plan = _oneCellPlan(
        SurfaceGameplayZoneBehaviorDraft.movement(
          const MovementZonePayload(requiredMode: MovementMode.surf),
        ),
      );
      final zone = plan.generatedZones.single;

      expect(zone.kind, GameplayZoneKind.movement);
      expect(zone.movement, isNotNull);
      expect(zone.movement!.requiredMode, MovementMode.surf);
      expect(zone.encounter, isNull);
      expect(zone.hazard, isNull);
    });

    test('generates lava hazard payload', () {
      final plan = _oneCellPlan(
        SurfaceGameplayZoneBehaviorDraft.hazard(
          const HazardZonePayload(
            hazardKind: HazardKind.lava,
            damagePerStep: 5,
          ),
        ),
      );
      final zone = plan.generatedZones.single;

      expect(zone.kind, GameplayZoneKind.hazard);
      expect(zone.hazard, isNotNull);
      expect(zone.hazard!.hazardKind, HazardKind.lava);
      expect(zone.hazard!.damagePerStep, 5);
      expect(zone.encounter, isNull);
      expect(zone.movement, isNull);
    });
  });

  group('diagnostics and immutability', () {
    test('warns when greedy rectangles exceed threshold', () {
      final plan = createSurfaceGameplayZoneGenerationPlan(
        source: _source(
          const [
            GridPos(x: 0, y: 0),
            GridPos(x: 2, y: 0),
            GridPos(x: 4, y: 0),
          ],
        ),
        behavior: _tallGrassBehavior(),
        strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
        zoneIdPrefix: 'grass',
        zoneNamePrefix: 'Grass',
        maxRectanglesWarningThreshold: 2,
      );

      expect(plan.generatedZones, hasLength(3));
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.kind),
        contains(SurfaceGameplayZoneGenerationDiagnosticKind.tooManyRectangles),
      );
    });

    test('warns about overlaps with existing gameplay zones', () {
      final existing = [
        const MapGameplayZone(
          id: 'existing',
          kind: GameplayZoneKind.encounter,
          area: MapRect(
            pos: GridPos(x: 0, y: 0),
            size: GridSize(width: 1, height: 1),
          ),
        ),
      ];
      final plan = createSurfaceGameplayZoneGenerationPlan(
        source: _source(const [GridPos(x: 0, y: 0)]),
        behavior: _tallGrassBehavior(),
        strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
        zoneIdPrefix: 'grass',
        zoneNamePrefix: 'Grass',
        existingZones: existing,
      );

      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.kind),
        contains(
          SurfaceGameplayZoneGenerationDiagnosticKind
              .overlapsExistingGameplayZone,
        ),
      );
      expect(existing.single.id, 'existing');
    });

    test('suffixes IDs that collide with existing zones', () {
      final plan = createSurfaceGameplayZoneGenerationPlan(
        source: _source(const [GridPos(x: 1, y: 1)]),
        behavior: _tallGrassBehavior(),
        strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
        zoneIdPrefix: 'grass',
        zoneNamePrefix: 'Grass',
        existingZones: const [
          MapGameplayZone(
            id: 'grass',
            kind: GameplayZoneKind.encounter,
            area: MapRect(
              pos: GridPos(x: 0, y: 0),
              size: GridSize(width: 1, height: 1),
            ),
          ),
        ],
      );

      expect(plan.generatedZones.single.id, 'grass-1');
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.kind),
        contains(
          SurfaceGameplayZoneGenerationDiagnosticKind.zoneIdCollisionResolved,
        ),
      );
    });

    test('plan lists are immutable', () {
      final plan = _oneCellPlan(_tallGrassBehavior());

      expect(() => plan.generatedZones.add(plan.generatedZones.single),
          throwsUnsupportedError);
      expect(() => plan.rectangles.clear(), throwsUnsupportedError);
      expect(() => plan.diagnostics.clear(), throwsUnsupportedError);
    });

    test('coverage and diagnostics support value equality', () {
      expect(
        const SurfaceGameplayZoneCoverageReport(
          sourceCellCount: 1,
          coveredSourceCellCount: 1,
          missingSourceCellCount: 0,
          extraCellCount: 0,
          zoneCount: 1,
        ),
        const SurfaceGameplayZoneCoverageReport(
          sourceCellCount: 1,
          coveredSourceCellCount: 1,
          missingSourceCellCount: 0,
          extraCellCount: 0,
          zoneCount: 1,
        ),
      );
      expect(
        const SurfaceGameplayZoneGenerationDiagnostic(
          severity: SurfaceGameplayZoneGenerationDiagnosticSeverity.info,
          kind: SurfaceGameplayZoneGenerationDiagnosticKind
              .zoneIdCollisionResolved,
          message: 'ID changed.',
        ),
        const SurfaceGameplayZoneGenerationDiagnostic(
          severity: SurfaceGameplayZoneGenerationDiagnosticSeverity.info,
          kind: SurfaceGameplayZoneGenerationDiagnosticKind
              .zoneIdCollisionResolved,
          message: 'ID changed.',
        ),
      );
    });
  });
}

SurfaceGameplayZoneGenerationSource _source(List<GridPos> cells) {
  return SurfaceGameplayZoneGenerationSource(
    surfaceLayerId: 'surfaces',
    surfaceLayerName: 'Surfaces',
    surfacePresetId: 'tall_grass',
    cells: cells,
  );
}

SurfaceGameplayZoneBehaviorDraft _tallGrassBehavior() {
  return SurfaceGameplayZoneBehaviorDraft.encounter(
    const EncounterZonePayload(
      encounterTableId: 'route-1-grass',
      encounterKind: EncounterKind.walk,
    ),
  );
}

SurfaceGameplayZoneGenerationPlan _oneCellPlan(
  SurfaceGameplayZoneBehaviorDraft behavior,
) {
  return createSurfaceGameplayZoneGenerationPlan(
    source: _source(const [GridPos(x: 0, y: 0)]),
    behavior: behavior,
    strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
    zoneIdPrefix: 'zone',
    zoneNamePrefix: 'Zone',
  );
}
