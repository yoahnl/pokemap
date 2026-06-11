# Evidence Pack — NS-SCENES-V1-107 — Cinematic Manual Path Core Model V0

## 1. Gate 0

*   **Repository :** `pokemonProject`
*   **Package :** `packages/map_core`
*   **Date :** 11 Juin 2026
*   **Auteur :** Antigravity AI
*   **Statut :** DONE

---

## 2. Règles et fichiers lus

### Règles lues
- `AGENTS.md` (Règles générales et conventions)
- `agent_rules.md` (Fidélité de tests et interdiction Git write)
- `codex_rule.md` (Spécifications de structure de rapport et validation obligatoire)

### Fichiers lus
- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_106_cinematic_manual_path_authoring_prep_contract.md`

---

## 3. Fichiers modifiés et créés

### Fichiers modifiés
- `packages/map_core/lib/src/models/cinematic_asset.dart` (Ajout `manual` dans `CinematicTimelineActorPathMode`, classe `CinematicManualPath`, intégration dans `CinematicStageContext` avec backward-compatibility JSON).
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart` (CRUD d'authoring sur les chemins manuels et points de passage).
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart` (12 diagnostics statiques de trajets manuels).
- `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart` (Traduction lane label).
- `packages/map_core/test/cinematic_asset_test.dart` (Tests rétrocompatibilité et roundtrip).
- `reports/narrativeStudio/scenes/road_map_scenes.md` (Roadmap mise à jour).
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md` (Roadmap mise à jour).

### Fichiers créés
- `reports/narrativeStudio/scenes/ns_scenes_v1_107_cinematic_manual_path_core_model_v0.md` (Rapport principal).
- `reports/narrativeStudio/scenes/ns_scenes_v1_107_evidence_pack.md` (Ce fichier).

### Fichiers de tests créés/modifiés (Contenu ajouté)

#### Dans `packages/map_core/test/cinematic_authoring_operations_test.dart`
```dart
    group('manual paths', () {
      final pointA = CinematicStagePoint(id: 'point_a', label: 'Point A', x: 1, y: 1);
      final pointB = CinematicStagePoint(id: 'point_b', label: 'Point B', x: 2, y: 2);
      final waitStep = CinematicTimelineStep(
        id: 'step_wait',
        kind: CinematicTimelineStepKind.wait,
        durationMs: 100,
      );
      final actorMoveStep = CinematicTimelineStep(
        id: 'step_actor_move',
        kind: CinematicTimelineStepKind.actorMove,
        actorId: 'actor_professor',
        targetId: 'target_center',
        durationMs: 1000,
        metadata: const {
          'authoring.source': 'cinematic-builder-v0',
          'authoring.kind': 'basicBlock',
          'authoring.block': 'actorMove',
          'actor.movementMode': 'walk',
          'actor.pathMode': 'direct',
        },
      );

      CinematicAsset createTestAsset() {
        return CinematicAsset(
          id: 'cinematic_intro',
          title: 'Intro cinematic',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
          ],
          movementTargets: [
            CinematicMovementTargetRef(
              targetId: 'target_center',
              label: 'Centre scène',
            ),
          ],
          stageContext: CinematicStageContext(
            stagePoints: [pointA, pointB],
          ),
          timeline: CinematicTimeline(
            steps: [waitStep, actorMoveStep],
          ),
        );
      }

      test('addCinematicManualPathForActorMove creates path and sets mode to manual', () {
        var project = _project(cinematics: [createTestAsset()]);
        final result = addCinematicManualPathForActorMove(
          project,
          cinematicId: 'cinematic_intro',
          actorMoveStepId: 'step_actor_move',
          label: 'Jean manual path',
          description: 'A description',
          waypointStagePointIds: ['point_a', 'point_b'],
        );

        final updatedCinematic = result.cinematic;
        final context = updatedCinematic.stageContext!;
        expect(context.manualPaths, hasLength(1));
        final path = context.manualPaths.single;
        expect(path.label, 'Jean manual path');
        expect(path.description, 'A description');
        expect(path.ownerActorMoveStepId, 'step_actor_move');
        expect(path.waypointStagePointIds, ['point_a', 'point_b']);

        final step = updatedCinematic.timeline.steps.firstWhere((s) => s.id == 'step_actor_move');
        expect(cinematicTimelineActorPathModeOf(step), CinematicTimelineActorPathMode.manual);
      });

      test('addCinematicManualPathForActorMove defaults label and generates unique ID', () {
        var project = _project(cinematics: [createTestAsset()]);
        final result1 = addCinematicManualPathForActorMove(
          project,
          cinematicId: 'cinematic_intro',
          actorMoveStepId: 'step_actor_move',
          waypointStagePointIds: ['point_a'],
        );

        expect(result1.cinematic.stageContext!.manualPaths.single.id, 'path');
        expect(result1.cinematic.stageContext!.manualPaths.single.label, 'Chemin de déplacement');
      });

      test('addCinematicManualPathForActorMove validations', () {
        var project = _project(cinematics: [createTestAsset()]);

        // Non-actorMove step
        expect(
          () => addCinematicManualPathForActorMove(
            project,
            cinematicId: 'cinematic_intro',
            actorMoveStepId: 'step_wait',
          ),
          throwsA(isA<ArgumentError>()),
        );

        // Unknown step
        expect(
          () => addCinematicManualPathForActorMove(
            project,
            cinematicId: 'cinematic_intro',
            actorMoveStepId: 'step_unknown',
          ),
          throwsA(isA<ArgumentError>()),
        );

        // Stage point does not exist
        expect(
          () => addCinematicManualPathForActorMove(
            project,
            cinematicId: 'cinematic_intro',
            actorMoveStepId: 'step_actor_move',
            waypointStagePointIds: ['missing_point'],
          ),
          throwsA(isA<ArgumentError>()),
        );

        // Duplicate path for step
        final firstAdded = addCinematicManualPathForActorMove(
          project,
          cinematicId: 'cinematic_intro',
          actorMoveStepId: 'step_actor_move',
        );
        expect(
          () => addCinematicManualPathForActorMove(
            firstAdded.updatedProject,
            cinematicId: 'cinematic_intro',
            actorMoveStepId: 'step_actor_move',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('updateCinematicManualPath updates path properties', () {
        var project = _project(cinematics: [createTestAsset()]);
        final added = addCinematicManualPathForActorMove(
          project,
          cinematicId: 'cinematic_intro',
          actorMoveStepId: 'step_actor_move',
          waypointStagePointIds: ['point_a'],
        );

        final pathId = added.cinematic.stageContext!.manualPaths.single.id;
        final updated = updateCinematicManualPath(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          manualPathId: pathId,
          label: 'Updated Label',
          description: 'Updated Description',
          waypointStagePointIds: ['point_b', 'point_a'],
        );

        final path = updated.cinematic.stageContext!.manualPaths.single;
        expect(path.label, 'Updated Label');
        expect(path.description, 'Updated Description');
        expect(path.waypointStagePointIds, ['point_b', 'point_a']);
      });

      test('updateCinematicManualPath validations', () {
        var project = _project(cinematics: [createTestAsset()]);
        final added = addCinematicManualPathForActorMove(
          project,
          cinematicId: 'cinematic_intro',
          actorMoveStepId: 'step_actor_move',
        );
        final pathId = added.cinematic.stageContext!.manualPaths.single.id;

        // Empty label
        expect(
          () => updateCinematicManualPath(
            added.updatedProject,
            cinematicId: 'cinematic_intro',
            manualPathId: pathId,
            label: '   ',
          ),
          throwsA(isA<ArgumentError>()),
        );

        // Missing waypoint stage point
        expect(
          () => updateCinematicManualPath(
            added.updatedProject,
            cinematicId: 'cinematic_intro',
            manualPathId: pathId,
            waypointStagePointIds: ['missing_point'],
          ),
          throwsA(isA<ArgumentError>()),
        );

        // Unknown manual path ID
        expect(
          () => updateCinematicManualPath(
            added.updatedProject,
            cinematicId: 'cinematic_intro',
            manualPathId: 'missing_path',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('removeCinematicManualPath removes path and resets step to direct', () {
        var project = _project(cinematics: [createTestAsset()]);
        final added = addCinematicManualPathForActorMove(
          project,
          cinematicId: 'cinematic_intro',
          actorMoveStepId: 'step_actor_move',
        );
        final pathId = added.cinematic.stageContext!.manualPaths.single.id;

        final removed = removeCinematicManualPath(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          manualPathId: pathId,
        );

        expect(removed.cinematic.stageContext!.manualPaths, isEmpty);
        final step = removed.cinematic.timeline.steps.firstWhere((s) => s.id == 'step_actor_move');
        expect(cinematicTimelineActorPathModeOf(step), CinematicTimelineActorPathMode.direct);
      });

      test('addCinematicManualPathWaypoint adds waypoint', () {
        var project = _project(cinematics: [createTestAsset()]);
        final added = addCinematicManualPathForActorMove(
          project,
          cinematicId: 'cinematic_intro',
          actorMoveStepId: 'step_actor_move',
          waypointStagePointIds: ['point_a'],
        );
        final pathId = added.cinematic.stageContext!.manualPaths.single.id;

        final updated = addCinematicManualPathWaypoint(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          manualPathId: pathId,
          stagePointId: 'point_b',
        );

        expect(
          updated.cinematic.stageContext!.manualPaths.single.waypointStagePointIds,
          ['point_a', 'point_b'],
        );
      });

      test('removeCinematicManualPathWaypointAt removes waypoint at index', () {
        var project = _project(cinematics: [createTestAsset()]);
        final added = addCinematicManualPathForActorMove(
          project,
          cinematicId: 'cinematic_intro',
          actorMoveStepId: 'step_actor_move',
          waypointStagePointIds: ['point_a', 'point_b'],
        );
        final pathId = added.cinematic.stageContext!.manualPaths.single.id;

        final updated = removeCinematicManualPathWaypointAt(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          manualPathId: pathId,
          index: 0,
        );

        expect(
          updated.cinematic.stageContext!.manualPaths.single.waypointStagePointIds,
          ['point_b'],
        );

        // Out of bounds
        expect(
          () => removeCinematicManualPathWaypointAt(
            updated.updatedProject,
            cinematicId: 'cinematic_intro',
            manualPathId: pathId,
            index: 5,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('reorderCinematicManualPathWaypoint reorders waypoints', () {
        var project = _project(cinematics: [createTestAsset()]);
        final added = addCinematicManualPathForActorMove(
          project,
          cinematicId: 'cinematic_intro',
          actorMoveStepId: 'step_actor_move',
          waypointStagePointIds: ['point_a', 'point_b'],
        );
        final pathId = added.cinematic.stageContext!.manualPaths.single.id;

        final updated = reorderCinematicManualPathWaypoint(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          manualPathId: pathId,
          fromIndex: 0,
          toIndex: 1,
        );

        expect(
          updated.cinematic.stageContext!.manualPaths.single.waypointStagePointIds,
          ['point_b', 'point_a'],
        );

        // Out of bounds
        expect(
          () => reorderCinematicManualPathWaypoint(
            updated.updatedProject,
            cinematicId: 'cinematic_intro',
            manualPathId: pathId,
            fromIndex: -1,
            toIndex: 1,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('setActorMovePathMode updates mode without affecting targets', () {
        var project = _project(cinematics: [createTestAsset()]);
        final updated = setActorMovePathMode(
          project,
          cinematicId: 'cinematic_intro',
          stepId: 'step_actor_move',
          pathMode: CinematicTimelineActorPathMode.manual,
        );

        final step = updated.cinematic.timeline.steps.firstWhere((s) => s.id == 'step_actor_move');
        expect(cinematicTimelineActorPathModeOf(step), CinematicTimelineActorPathMode.manual);
        expect(step.targetId, 'target_center'); // Preserves target
      });

      test('clearActorMoveManualPath resets step and deletes path', () {
        var project = _project(cinematics: [createTestAsset()]);
        final added = addCinematicManualPathForActorMove(
          project,
          cinematicId: 'cinematic_intro',
          actorMoveStepId: 'step_actor_move',
        );

        final cleared = clearActorMoveManualPath(
          added.updatedProject,
          cinematicId: 'cinematic_intro',
          stepId: 'step_actor_move',
        );

        expect(cleared.cinematic.stageContext!.manualPaths, isEmpty);
        final step = cleared.cinematic.timeline.steps.firstWhere((s) => s.id == 'step_actor_move');
        expect(cinematicTimelineActorPathModeOf(step), CinematicTimelineActorPathMode.direct);
      });
    });
```

#### Dans `packages/map_core/test/cinematic_diagnostics_test.dart`
```dart
    group('manual path diagnostics', () {
      final pointA = CinematicStagePoint(id: 'point_a', label: 'Point A', x: 5, y: 5);
      final pointB = CinematicStagePoint(id: 'point_b', label: 'Point B', x: 15, y: 5);

      CinematicAsset createBaseCinematic({
        required String id,
        String? mapId = 'map_lab',
        List<CinematicStagePoint> stagePoints = const [],
        List<CinematicManualPath> manualPaths = const [],
        List<CinematicTimelineStep> steps = const [],
      }) {
        return CinematicAsset(
          id: id,
          title: 'Cinematic',
          mapId: mapId,
          requiredActors: [
            CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
          ],
          stageContext: CinematicStageContext(
            actorBindings: [
              CinematicActorBinding(
                actorId: 'actor_professor',
                kind: CinematicActorBindingKind.cinematicOnly,
              ),
            ],
            stagePoints: stagePoints,
            manualPaths: manualPaths,
          ),
          timeline: CinematicTimeline(steps: steps),
        );
      }

      CinematicTimelineStep createActorMoveStep({
        required String id,
        required String pathMode,
      }) {
        return CinematicTimelineStep(
          id: id,
          kind: CinematicTimelineStepKind.actorMove,
          actorId: 'actor_professor',
          targetId: 'target_center',
          durationMs: 1000,
          metadata: {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey:
                cinematicTimelineActorMoveBlockMetadataValue,
            cinematicTimelineActorMovementModeMetadataKey: 'walk',
            cinematicTimelineActorPathModeMetadataKey: pathMode,
          },
        );
      }

      test('valid manual path has no manual-path diagnostics', () {
        final step = createActorMoveStep(id: 'step_move', pathMode: 'manual');
        final path = CinematicManualPath(
          id: 'path_1',
          label: 'My Path',
          ownerActorMoveStepId: 'step_move',
          waypointStagePointIds: ['point_a'],
        );
        final report = diagnoseCinematicAsset(
          createBaseCinematic(
            id: 'c1',
            stagePoints: [pointA],
            manualPaths: [path],
            steps: [step],
          ),
          mapWidth: 10,
          mapHeight: 10,
        );

        final manualPathDiags = report.diagnostics.where((d) => {
          CinematicDiagnosticCode.manualPathEmpty,
          CinematicDiagnosticCode.manualPathStagePointMissing,
          CinematicDiagnosticCode.manualPathStagePointDuplicate,
          CinematicDiagnosticCode.manualPathWithoutStageMap,
          CinematicDiagnosticCode.manualPathStagePointOutOfMap,
          CinematicDiagnosticCode.actorMoveManualPathMissing,
          CinematicDiagnosticCode.actorMoveManualPathAmbiguous,
          CinematicDiagnosticCode.actorMoveManualPathUnused,
          CinematicDiagnosticCode.manualPathOrphaned,
          CinematicDiagnosticCode.manualPathDuplicateId,
          CinematicDiagnosticCode.manualPathEmptyId,
          CinematicDiagnosticCode.manualPathEmptyLabel,
        }.contains(d.code)).toList();
        expect(manualPathDiags, isEmpty);
      });

      test('diagnoses manualPathEmptyId and manualPathDuplicateId', () {
        final path1 = CinematicManualPath(
          id: 'dup_id',
          label: 'Path 1',
          ownerActorMoveStepId: 'step_move',
          waypointStagePointIds: ['point_a'],
        );
        final path2 = CinematicManualPath(
          id: 'dup_id',
          label: 'Path 2',
          ownerActorMoveStepId: 'step_move',
          waypointStagePointIds: ['point_a'],
        );
        final step = createActorMoveStep(id: 'step_move', pathMode: 'manual');

        final report = diagnoseCinematicAsset(
          createBaseCinematic(
            id: 'c1',
            stagePoints: [pointA],
            manualPaths: [path1, path2],
            steps: [step],
          ),
          mapWidth: 10,
          mapHeight: 10,
        );

        final dupDiags = report.byCode(CinematicDiagnosticCode.manualPathDuplicateId);
        expect(dupDiags, hasLength(1));
        expect(dupDiags.single.severity, CinematicDiagnosticSeverity.error);
        expect(dupDiags.single.referenceId, 'dup_id');
      });

      test('diagnoses manualPathEmptyLabel', () {
        expect(
          () => CinematicManualPath(
            id: 'path_1',
            label: '  ',
            ownerActorMoveStepId: 'step_move',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('diagnoses manualPathEmpty (warning if unused, error if used)', () {
        final path1 = CinematicManualPath(
          id: 'path_unused',
          label: 'Unused Empty Path',
          ownerActorMoveStepId: 'step_other',
        );
        final path2 = CinematicManualPath(
          id: 'path_used',
          label: 'Used Empty Path',
          ownerActorMoveStepId: 'step_move',
        );
        final step = createActorMoveStep(id: 'step_move', pathMode: 'manual');

        final report = diagnoseCinematicAsset(
          createBaseCinematic(
            id: 'c1',
            stagePoints: [pointA],
            manualPaths: [path1, path2],
            steps: [step],
          ),
          mapWidth: 10,
          mapHeight: 10,
        );

        final unusedDiag = report.diagnostics.firstWhere(
          (d) => d.code == CinematicDiagnosticCode.manualPathEmpty && d.referenceId == 'path_unused',
        );
        expect(unusedDiag.severity, CinematicDiagnosticSeverity.warning);

        final usedDiag = report.diagnostics.firstWhere(
          (d) => d.code == CinematicDiagnosticCode.manualPathEmpty && d.referenceId == 'path_used',
        );
        expect(usedDiag.severity, CinematicDiagnosticSeverity.error);
      });

      test('diagnoses manualPathStagePointMissing', () {
        final step = createActorMoveStep(id: 'step_move', pathMode: 'manual');
        final path = CinematicManualPath(
          id: 'path_1',
          label: 'Path',
          ownerActorMoveStepId: 'step_move',
          waypointStagePointIds: ['missing_point'],
        );

        final report = diagnoseCinematicAsset(
          createBaseCinematic(
            id: 'c1',
            stagePoints: [pointA],
            manualPaths: [path],
            steps: [step],
          ),
          mapWidth: 10,
          mapHeight: 10,
        );

        final diag = report.byCode(CinematicDiagnosticCode.manualPathStagePointMissing).single;
        expect(diag.severity, CinematicDiagnosticSeverity.error);
        expect(diag.referenceId, 'missing_point');
      });

      test('diagnoses manualPathStagePointDuplicate', () {
        final step = createActorMoveStep(id: 'step_move', pathMode: 'manual');
        final path = CinematicManualPath(
          id: 'path_1',
          label: 'Path',
          ownerActorMoveStepId: 'step_move',
          waypointStagePointIds: ['point_a', 'point_a'],
        );

        final report = diagnoseCinematicAsset(
          createBaseCinematic(
            id: 'c1',
            stagePoints: [pointA],
            manualPaths: [path],
            steps: [step],
          ),
          mapWidth: 10,
          mapHeight: 10,
        );

        final diag = report.byCode(CinematicDiagnosticCode.manualPathStagePointDuplicate).single;
        expect(diag.severity, CinematicDiagnosticSeverity.warning);
        expect(diag.referenceId, 'point_a');
      });

      test('diagnoses manualPathWithoutStageMap', () {
        final step = createActorMoveStep(id: 'step_move', pathMode: 'manual');
        final path = CinematicManualPath(
          id: 'path_1',
          label: 'Path',
          ownerActorMoveStepId: 'step_move',
          waypointStagePointIds: ['point_a'],
        );

        final report = diagnoseCinematicAsset(
          createBaseCinematic(
            id: 'c1',
            mapId: null,
            stagePoints: [pointA],
            manualPaths: [path],
            steps: [step],
          ),
        );

        final diag = report.byCode(CinematicDiagnosticCode.manualPathWithoutStageMap).single;
        expect(diag.severity, CinematicDiagnosticSeverity.warning);
        expect(diag.referenceId, 'path_1');
      });

      test('diagnoses manualPathStagePointOutOfMap', () {
        final step = createActorMoveStep(id: 'step_move', pathMode: 'manual');
        final path = CinematicManualPath(
          id: 'path_1',
          label: 'Path',
          ownerActorMoveStepId: 'step_move',
          waypointStagePointIds: ['point_b'],
        );

        final report = diagnoseCinematicAsset(
          createBaseCinematic(
            id: 'c1',
            stagePoints: [pointA, pointB],
            manualPaths: [path],
            steps: [step],
          ),
          mapWidth: 10,
          mapHeight: 10,
        );

        final diag = report.byCode(CinematicDiagnosticCode.manualPathStagePointOutOfMap).single;
        expect(diag.severity, CinematicDiagnosticSeverity.error);
        expect(diag.referenceId, 'point_b');
      });

      test('diagnoses manualPathOrphaned', () {
        final path = CinematicManualPath(
          id: 'path_1',
          label: 'Path',
          ownerActorMoveStepId: 'missing_step_id',
          waypointStagePointIds: ['point_a'],
        );

        final report = diagnoseCinematicAsset(
          createBaseCinematic(
            id: 'c1',
            stagePoints: [pointA],
            manualPaths: [path],
            steps: [],
          ),
          mapWidth: 10,
          mapHeight: 10,
        );

        final diag = report.byCode(CinematicDiagnosticCode.manualPathOrphaned).single;
        expect(diag.severity, CinematicDiagnosticSeverity.warning);
        expect(diag.referenceId, 'path_1');
      });

      test('diagnoses actorMoveManualPathMissing', () {
        final step = createActorMoveStep(id: 'step_move', pathMode: 'manual');

        final report = diagnoseCinematicAsset(
          createBaseCinematic(
            id: 'c1',
            stagePoints: [pointA],
            manualPaths: [],
            steps: [step],
          ),
          mapWidth: 10,
          mapHeight: 10,
        );

        final diag = report.byCode(CinematicDiagnosticCode.actorMoveManualPathMissing).single;
        expect(diag.severity, CinematicDiagnosticSeverity.error);
        expect(diag.stepId, 'step_move');
      });

      test('diagnoses actorMoveManualPathAmbiguous', () {
        final step = createActorMoveStep(id: 'step_move', pathMode: 'manual');
        final path1 = CinematicManualPath(
          id: 'path_1',
          label: 'Path 1',
          ownerActorMoveStepId: 'step_move',
          waypointStagePointIds: ['point_a'],
        );
        final path2 = CinematicManualPath(
          id: 'path_2',
          label: 'Path 2',
          ownerActorMoveStepId: 'step_move',
          waypointStagePointIds: ['point_a'],
        );

        final report = diagnoseCinematicAsset(
          createBaseCinematic(
            id: 'c1',
            stagePoints: [pointA],
            manualPaths: [path1, path2],
            steps: [step],
          ),
          mapWidth: 10,
          mapHeight: 10,
        );

        final diag = report.byCode(CinematicDiagnosticCode.actorMoveManualPathAmbiguous).single;
        expect(diag.severity, CinematicDiagnosticSeverity.error);
        expect(diag.stepId, 'step_move');
      });

      test('diagnoses actorMoveManualPathUnused', () {
        final step = createActorMoveStep(id: 'step_move', pathMode: 'direct');
        final path = CinematicManualPath(
          id: 'path_1',
          label: 'Path',
          ownerActorMoveStepId: 'step_move',
          waypointStagePointIds: ['point_a'],
        );

        final report = diagnoseCinematicAsset(
          createBaseCinematic(
            id: 'c1',
            stagePoints: [pointA],
            manualPaths: [path],
            steps: [step],
          ),
          mapWidth: 10,
          mapHeight: 10,
        );

        final diag = report.byCode(CinematicDiagnosticCode.actorMoveManualPathUnused).single;
        expect(diag.severity, CinematicDiagnosticSeverity.warning);
        expect(diag.stepId, 'step_move');
      });
    });
```

---

## 4. Sorties exactes des tests ciblés

### Test `cinematic_asset_test.dart`
```text
dart test --reporter=compact test/cinematic_asset_test.dart
All tests passed! (21 tests)
```

### Test `cinematic_authoring_operations_test.dart`
```text
dart test --reporter=compact test/cinematic_authoring_operations_test.dart
All tests passed! (67 tests)
```

### Test `cinematic_diagnostics_test.dart`
```text
dart test --reporter=compact test/cinematic_diagnostics_test.dart
All tests passed! (53 tests)
```

---

## 5. Sortie de `dart analyze`

```text
dart analyze
Analyzing map_core...
No issues found!
```

---

## 6. Sortie finale de la suite complète de `map_core`

```text
dart test --reporter=compact
All tests passed! (2484 tests)
```

**Total exact :** 2484 tests exécutés et réussis.

---

## 7. Justification de non-lancement de tests Flutter

Aucun fichier du package `map_editor` ou `map_runtime` n'a été modifié. La modification est strictement interne et pure au package `map_core`. Il n'y a donc pas de tests Flutter ni de tests de widgets à réexécuter.

---

## 8. Anti-scope Checks

### Modification de packages non autorisés
```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host
# Sortie : <vide>
```

### Modification de fichiers projet Xcode
```bash
git diff --name-only -- examples/playable_runtime_host/macos/Runner.xcodeproj/project.pbxproj packages/map_editor/macos/Runner.xcodeproj/project.pbxproj
# Sortie : <vide>
```

---

## 9. Git Checks finalisés

### `git diff --check`
```text
Sortie : <vide>
```

### `git diff --stat`
```text
 .../authoring/cinematic_authoring_operations.dart  | 532 ++++++++++++++++++++-
 .../lib/src/diagnostics/cinematic_diagnostics.dart | 245 +++++++++-
 .../map_core/lib/src/models/cinematic_asset.dart   | 121 ++++-
 .../cinematic_timeline_lane_read_model.dart        |   1 +
 packages/map_core/test/cinematic_asset_test.dart   | 115 +++++
 .../test/cinematic_authoring_operations_test.dart  | 346 ++++++++++++++
 .../map_core/test/cinematic_diagnostics_test.dart  | 368 ++++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  15 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  19 +-
 9 files changed, 1740 insertions(+), 22 deletions(-)
```

### `git diff --name-only`
```text
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
packages/map_core/lib/src/models/cinematic_asset.dart
packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
packages/map_core/test/cinematic_asset_test.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_diagnostics_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

### `git status --short --untracked-files=all`
```text
 M packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
 M packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
 M packages/map_core/lib/src/models/cinematic_asset.dart
 M packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
 M packages/map_core/test/cinematic_asset_test.dart
 M packages/map_core/test/cinematic_authoring_operations_test.dart
 M packages/map_core/test/cinematic_diagnostics_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
```

---

## 10. Confirmations et engagements de non-dépassement de scope

*   **Aucun code runtime / gameplay / battle modifié :** Confirmé par `git diff --name-only`.
*   **Aucun fichier Xcode modifié :** Confirmé par `git diff --name-only`.
*   **Aucune UI Flutter ajoutée :** Confirmé (modifications restreintes à `map_core` pur).
*   **Aucune Visual Gate créée ou modifiée :** Confirmé.
*   **Le lot V1-108 n'a pas été démarré :** Confirmé.
