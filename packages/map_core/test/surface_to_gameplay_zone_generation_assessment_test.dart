import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SurfaceGameplayZoneGenerationAssessmentPolicy', () {
    test('default policy is valid', () {
      expect(
        SurfaceGameplayZoneGenerationAssessmentPolicy
            .defaultPolicy.maxExtraCellRatioBeforeWarning,
        0,
      );
      expect(
        SurfaceGameplayZoneGenerationAssessmentPolicy
            .defaultPolicy.maxExtraCellRatioBeforeBlocking,
        0.25,
      );
      expect(
        SurfaceGameplayZoneGenerationAssessmentPolicy
            .defaultPolicy.maxGeneratedZonesBeforeWarning,
        8,
      );
      expect(
        SurfaceGameplayZoneGenerationAssessmentPolicy
            .defaultPolicy.maxGeneratedZonesBeforeBlocking,
        32,
      );
    });

    test('rejects invalid ratios and thresholds', () {
      expect(
        () => SurfaceGameplayZoneGenerationAssessmentPolicy(
          maxExtraCellRatioBeforeWarning: -0.1,
          maxExtraCellRatioBeforeBlocking: 0.25,
          maxGeneratedZonesBeforeWarning: 8,
          maxGeneratedZonesBeforeBlocking: 32,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => SurfaceGameplayZoneGenerationAssessmentPolicy(
          maxExtraCellRatioBeforeWarning: 0,
          maxExtraCellRatioBeforeBlocking: 1.1,
          maxGeneratedZonesBeforeWarning: 8,
          maxGeneratedZonesBeforeBlocking: 32,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => SurfaceGameplayZoneGenerationAssessmentPolicy(
          maxExtraCellRatioBeforeWarning: 0.5,
          maxExtraCellRatioBeforeBlocking: 0.25,
          maxGeneratedZonesBeforeWarning: 8,
          maxGeneratedZonesBeforeBlocking: 32,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => SurfaceGameplayZoneGenerationAssessmentPolicy(
          maxExtraCellRatioBeforeWarning: 0,
          maxExtraCellRatioBeforeBlocking: 0.25,
          maxGeneratedZonesBeforeWarning: 0,
          maxGeneratedZonesBeforeBlocking: 32,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => SurfaceGameplayZoneGenerationAssessmentPolicy(
          maxExtraCellRatioBeforeWarning: 0,
          maxExtraCellRatioBeforeBlocking: 0.25,
          maxGeneratedZonesBeforeWarning: 8,
          maxGeneratedZonesBeforeBlocking: 7,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('assessSurfaceGameplayZoneGenerationPlan ready', () {
    test('marks an exact greedy rectangle plan ready', () {
      final assessment = assessSurfaceGameplayZoneGenerationPlan(
        _planForCells(
          const [
            GridPos(x: 0, y: 0),
            GridPos(x: 1, y: 0),
            GridPos(x: 0, y: 1),
            GridPos(x: 1, y: 1),
          ],
          strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
        ),
      );

      expect(
        assessment.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.ready,
      );
      expect(assessment.canApply, isTrue);
      expect(assessment.requiresReview, isFalse);
      expect(assessment.extraCellRatio, 0);
      expect(assessment.coveragePercent, 1);
      expect(assessment.summaryTitle, 'Plan prêt à appliquer');
      expect(
        assessment.messages.map((message) => message.title),
        contains('Couverture exacte'),
      );
    });
  });

  group('assessSurfaceGameplayZoneGenerationPlan needsReview', () {
    test('marks bounding-box extra cells as needsReview below blocking ratio',
        () {
      final assessment = assessSurfaceGameplayZoneGenerationPlan(
        _planForCells(
          const [
            GridPos(x: 0, y: 0),
            GridPos(x: 1, y: 0),
            GridPos(x: 2, y: 0),
            GridPos(x: 0, y: 1),
            GridPos(x: 1, y: 1),
          ],
          strategy: SurfaceGameplayZoneGenerationStrategy.boundingBox,
        ),
      );

      expect(
        assessment.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.needsReview,
      );
      expect(assessment.canApply, isTrue);
      expect(assessment.requiresReview, isTrue);
      expect(assessment.extraCellRatio, closeTo(1 / 5, 0.0001));
      expect(
        assessment.warningMessages.map((message) => message.title),
        contains('Cellules hors surface incluses'),
      );
    });

    test('presents overlap and id collision diagnostics for review', () {
      final plan = createSurfaceGameplayZoneGenerationPlan(
        source: _source(const [GridPos(x: 0, y: 0)]),
        behavior: _encounterBehavior(),
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
      final assessment = assessSurfaceGameplayZoneGenerationPlan(plan);

      expect(
        assessment.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.needsReview,
      );
      expect(
        assessment.warningMessages.map((message) => message.title),
        contains('Zones existantes chevauchées'),
      );
      expect(
        assessment.infoMessages.map((message) => message.title),
        contains('IDs ajustés'),
      );
    });

    test('marks too many rectangles warning as needsReview under blocking', () {
      final plan = createSurfaceGameplayZoneGenerationPlan(
        source: _source(
          const [
            GridPos(x: 0, y: 0),
            GridPos(x: 2, y: 0),
            GridPos(x: 4, y: 0),
          ],
        ),
        behavior: _encounterBehavior(),
        strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
        zoneIdPrefix: 'grass',
        zoneNamePrefix: 'Grass',
        maxRectanglesWarningThreshold: 2,
      );
      final assessment = assessSurfaceGameplayZoneGenerationPlan(plan);

      expect(
        assessment.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.needsReview,
      );
      expect(
        assessment.warningMessages.map((message) => message.title),
        contains('Beaucoup de zones générées'),
      );
    });
  });

  group('assessSurfaceGameplayZoneGenerationPlan blocked', () {
    test('blocks when extra cell ratio reaches blocking threshold', () {
      final assessment = assessSurfaceGameplayZoneGenerationPlan(
        _planForCells(
          const [
            GridPos(x: 0, y: 0),
            GridPos(x: 3, y: 0),
          ],
          strategy: SurfaceGameplayZoneGenerationStrategy.boundingBox,
        ),
      );

      expect(
        assessment.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
      );
      expect(assessment.canApply, isFalse);
      expect(assessment.requiresReview, isFalse);
      expect(
        assessment.errorMessages.map((message) => message.title),
        contains('Plan bloqué'),
      );
      expect(
        assessment.errorMessages.map((message) => message.title),
        contains('Trop de cellules hors surface'),
      );
    });

    test('blocks when generated zone count reaches blocking threshold', () {
      final assessment = assessSurfaceGameplayZoneGenerationPlan(
        _planForCells(
          const [
            GridPos(x: 0, y: 0),
            GridPos(x: 2, y: 0),
            GridPos(x: 4, y: 0),
          ],
          strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
        ),
        policy: SurfaceGameplayZoneGenerationAssessmentPolicy(
          maxExtraCellRatioBeforeWarning: 0,
          maxExtraCellRatioBeforeBlocking: 0.25,
          maxGeneratedZonesBeforeWarning: 2,
          maxGeneratedZonesBeforeBlocking: 3,
        ),
      );

      expect(
        assessment.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
      );
      expect(
        assessment.errorMessages.map((message) => message.title),
        contains('Trop de zones générées'),
      );
    });

    test('blocks a plan with an existing error diagnostic or no zones', () {
      final base = _planForCells(
        const [GridPos(x: 0, y: 0)],
        strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
      );
      final errored = SurfaceGameplayZoneGenerationPlan(
        source: base.source,
        behavior: base.behavior,
        strategy: base.strategy,
        generatedZones: base.generatedZones,
        rectangles: base.rectangles,
        coverage: base.coverage,
        diagnostics: const [
          SurfaceGameplayZoneGenerationDiagnostic(
            severity: SurfaceGameplayZoneGenerationDiagnosticSeverity.error,
            kind: SurfaceGameplayZoneGenerationDiagnosticKind.noGeneratedZone,
            message: 'No zones.',
          ),
        ],
      );
      final empty = SurfaceGameplayZoneGenerationPlan(
        source: base.source,
        behavior: base.behavior,
        strategy: base.strategy,
        generatedZones: const [],
        rectangles: const [],
        coverage: const SurfaceGameplayZoneCoverageReport(
          sourceCellCount: 1,
          coveredSourceCellCount: 0,
          missingSourceCellCount: 1,
          extraCellCount: 0,
          zoneCount: 0,
        ),
        diagnostics: const [],
      );

      expect(
        assessSurfaceGameplayZoneGenerationPlan(errored).status,
        SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
      );
      expect(
        assessSurfaceGameplayZoneGenerationPlan(empty).status,
        SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
      );
    });
  });

  group('assessment messages and immutability', () {
    test('messages are immutable and helper filters are stable', () {
      final assessment = assessSurfaceGameplayZoneGenerationPlan(
        _planForCells(
          const [
            GridPos(x: 0, y: 0),
            GridPos(x: 1, y: 0),
            GridPos(x: 2, y: 0),
            GridPos(x: 0, y: 1),
            GridPos(x: 1, y: 1),
          ],
          strategy: SurfaceGameplayZoneGenerationStrategy.boundingBox,
        ),
      );

      expect(() => assessment.messages.clear(), throwsUnsupportedError);
      expect(
        assessment.warningMessages.map((message) => message.title),
        contains('Cellules hors surface incluses'),
      );
      expect(assessment.errorMessages, isEmpty);
      expect(assessment.infoMessages, isEmpty);
    });

    test('assessment does not mutate the source plan', () {
      final plan = createSurfaceGameplayZoneGenerationPlan(
        source: _source(const [GridPos(x: 0, y: 0)]),
        behavior: _encounterBehavior(),
        strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
        zoneIdPrefix: 'grass',
        zoneNamePrefix: 'Grass',
      );
      final originalZones = List<MapGameplayZone>.of(plan.generatedZones);
      final originalDiagnostics =
          List<SurfaceGameplayZoneGenerationDiagnostic>.of(plan.diagnostics);

      final assessment = assessSurfaceGameplayZoneGenerationPlan(plan);

      expect(plan.generatedZones, originalZones);
      expect(plan.diagnostics, originalDiagnostics);
      expect(assessment.plan, same(plan));
      expect(assessment.plan.generatedZones.single.id, 'grass');
    });

    test('assessment messages and assessment support value equality', () {
      final first = assessSurfaceGameplayZoneGenerationPlan(
        _planForCells(
          const [GridPos(x: 0, y: 0)],
          strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
        ),
      );
      final second = assessSurfaceGameplayZoneGenerationPlan(
        _planForCells(
          const [GridPos(x: 0, y: 0)],
          strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
        ),
      );

      expect(
        const SurfaceGameplayZoneGenerationAssessmentMessage(
          severity: SurfaceGameplayZoneGenerationDiagnosticSeverity.info,
          title: 'Couverture exacte',
          description: 'Toutes les cellules source sont couvertes.',
        ),
        const SurfaceGameplayZoneGenerationAssessmentMessage(
          severity: SurfaceGameplayZoneGenerationDiagnosticSeverity.info,
          title: 'Couverture exacte',
          description: 'Toutes les cellules source sont couvertes.',
        ),
      );
      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });
  });
}

SurfaceGameplayZoneGenerationPlan _planForCells(
  List<GridPos> cells, {
  required SurfaceGameplayZoneGenerationStrategy strategy,
}) {
  return createSurfaceGameplayZoneGenerationPlan(
    source: _source(cells),
    behavior: _encounterBehavior(),
    strategy: strategy,
    zoneIdPrefix: 'grass',
    zoneNamePrefix: 'Grass',
  );
}

SurfaceGameplayZoneGenerationSource _source(List<GridPos> cells) {
  return SurfaceGameplayZoneGenerationSource(
    surfaceLayerId: 'surfaces',
    surfaceLayerName: 'Surfaces',
    surfacePresetId: 'tall_grass',
    cells: cells,
  );
}

SurfaceGameplayZoneBehaviorDraft _encounterBehavior() {
  return SurfaceGameplayZoneBehaviorDraft.encounter(
    const EncounterZonePayload(
      encounterTableId: 'route-1',
      encounterKind: EncounterKind.walk,
    ),
  );
}
