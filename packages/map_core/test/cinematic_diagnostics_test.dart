import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Cinematic diagnostics', () {
    test('reports empty timeline as authoring warning', () {
      final report = diagnoseCinematicAsset(
        CinematicAsset(
          id: 'cinematic_empty',
          title: 'Empty cinematic',
          timeline: CinematicTimeline(),
        ),
      );

      final diagnostic =
          report.byCode(CinematicDiagnosticCode.cinematicEmptyTimeline).single;
      expect(diagnostic.severity, CinematicDiagnosticSeverity.warning);
      expect(diagnostic.cinematicId, 'cinematic_empty');
    });

    test('reports duplicate step ids and invalid durations', () {
      final report = diagnoseCinematicAsset(
        CinematicAsset(
          id: 'cinematic_intro',
          title: 'Intro cinematic',
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_wait',
                kind: CinematicTimelineStepKind.wait,
                durationMs: -1,
              ),
              CinematicTimelineStep(
                id: 'step_wait',
                kind: CinematicTimelineStepKind.marker,
              ),
            ],
          ),
        ),
      );

      expect(
        report.byCode(CinematicDiagnosticCode.cinematicDuplicateStepId),
        hasLength(1),
      );
      expect(
        report.byCode(CinematicDiagnosticCode.cinematicInvalidStepDuration),
        hasLength(1),
      );
    });

    test('reports legacy gameplay step leakage carried by metadata', () {
      final report = diagnoseCinematicAsset(
        CinematicAsset(
          id: 'cinematic_legacy',
          title: 'Legacy cinematic',
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_legacy',
                kind: CinematicTimelineStepKind.marker,
                metadata: const {'legacy.kind': 'setFact'},
              ),
            ],
          ),
        ),
      );

      final diagnostic = report
          .byCode(CinematicDiagnosticCode.cinematicUnsupportedGameplayStep)
          .single;
      expect(diagnostic.severity, CinematicDiagnosticSeverity.error);
      expect(diagnostic.stepId, 'step_legacy');
    });

    test('accepts authoring draft marker without gameplay diagnostics', () {
      final project = ProjectManifest(
        name: 'Cinematic diagnostics test',
        maps: const [],
        tilesets: const [],
        cinematics: [
          _cinematic(id: 'cinematic_intro'),
        ],
      );
      final result = addCinematicTimelineDraftStep(
        project,
        cinematicId: 'cinematic_intro',
      );

      final report = diagnoseCinematicAsset(result.cinematic);

      expect(isCinematicTimelineDraftStep(result.step), isTrue);
      expect(
        report.byCode(CinematicDiagnosticCode.cinematicUnsupportedGameplayStep),
        isEmpty,
      );
      expect(report.hasErrors, isFalse);
    });

    test('accepts authoring basic blocks without gameplay diagnostics', () {
      var project = ProjectManifest(
        name: 'Cinematic diagnostics test',
        maps: const [],
        tilesets: const [],
        cinematics: [
          CinematicAsset(
            id: 'cinematic_intro',
            title: 'Intro cinematic',
            timeline: CinematicTimeline(),
          ),
        ],
      );
      for (final blockKind in CinematicTimelineBasicBlockKind.values) {
        final result = addCinematicTimelineBasicBlockStep(
          project,
          cinematicId: 'cinematic_intro',
          blockKind: blockKind,
        );
        project = result.updatedProject;
        expect(isCinematicTimelineBasicBlockStep(result.step), isTrue);
      }

      final report = diagnoseCinematicAsset(project.cinematics.single);

      expect(
        report.byCode(CinematicDiagnosticCode.cinematicUnsupportedGameplayStep),
        isEmpty,
      );
      expect(
        report.byCode(CinematicDiagnosticCode.cinematicInvalidStepDuration),
        isEmpty,
      );
      expect(report.hasErrors, isFalse);
    });

    test('accepts valid actorFace authoring block', () {
      var project = ProjectManifest(
        name: 'Cinematic diagnostics test',
        maps: const [],
        tilesets: const [],
        cinematics: [
          CinematicAsset(
            id: 'cinematic_intro',
            title: 'Intro cinematic',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
            ],
            timeline: CinematicTimeline(),
          ),
        ],
      );
      final result = addCinematicTimelineActorFacingStep(
        project,
        cinematicId: 'cinematic_intro',
        actorId: 'actor_professor',
        direction: CinematicTimelineActorFacingDirection.down,
      );
      project = result.updatedProject;

      final report = diagnoseCinematicAsset(project.cinematics.single);

      expect(isCinematicTimelineActorFacingStep(result.step), isTrue);
      expect(
        report.byCode(CinematicDiagnosticCode.cinematicUnknownActorRef),
        isEmpty,
      );
      expect(report.hasErrors, isFalse);
    });

    test('reports actorFace with unknown actorId', () {
      final report = diagnoseCinematicAsset(
        CinematicAsset(
          id: 'cinematic_intro',
          title: 'Intro cinematic',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
          ],
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_actor_face',
                kind: CinematicTimelineStepKind.actorFace,
                actorId: 'actor_missing',
                metadata: const {
                  'authoring.source': 'cinematic-builder-v0',
                  'authoring.kind': 'basicBlock',
                  'authoring.block': 'actorFace',
                  'actor.direction': 'left',
                },
              ),
            ],
          ),
        ),
      );

      final diagnostic = report
          .byCode(CinematicDiagnosticCode.cinematicUnknownActorRef)
          .single;
      expect(diagnostic.severity, CinematicDiagnosticSeverity.error);
      expect(diagnostic.stepId, 'step_actor_face');
      expect(diagnostic.referenceId, 'actor_missing');
    });

    test('accepts valid actorMove authoring block without gameplay leakage',
        () {
      var project = ProjectManifest(
        name: 'Cinematic diagnostics test',
        maps: const [],
        tilesets: const [],
        cinematics: [
          CinematicAsset(
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
            timeline: CinematicTimeline(),
          ),
        ],
      );
      final result = addCinematicTimelineActorMoveStep(
        project,
        cinematicId: 'cinematic_intro',
        actorId: 'actor_professor',
        targetId: 'target_center',
        movementMode: CinematicTimelineActorMovementMode.walk,
      );
      project = result.updatedProject;

      final report = diagnoseCinematicAsset(project.cinematics.single);

      expect(isCinematicTimelineActorMoveStep(result.step), isTrue);
      expect(
        report.byCode(CinematicDiagnosticCode.cinematicUnknownActorRef),
        isEmpty,
      );
      expect(
        report
            .byCode(CinematicDiagnosticCode.cinematicUnknownMovementTargetRef),
        isEmpty,
      );
      expect(
        report.byCode(CinematicDiagnosticCode.cinematicUnsupportedGameplayStep),
        isEmpty,
      );
      expect(report.hasErrors, isFalse);
    });

    test('reports actorMove missing or unknown actor and target refs', () {
      final report = diagnoseCinematicAsset(
        CinematicAsset(
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
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_missing_refs',
                kind: CinematicTimelineStepKind.actorMove,
                durationMs: 1000,
                metadata: const {
                  'authoring.source': 'cinematic-builder-v0',
                  'authoring.kind': 'basicBlock',
                  'authoring.block': 'actorMove',
                  'actor.movementMode': 'walk',
                  'actor.pathMode': 'direct',
                },
              ),
              CinematicTimelineStep(
                id: 'step_unknown_refs',
                kind: CinematicTimelineStepKind.actorMove,
                actorId: 'actor_missing',
                targetId: 'target_missing',
                durationMs: 1000,
                metadata: const {
                  'authoring.source': 'cinematic-builder-v0',
                  'authoring.kind': 'basicBlock',
                  'authoring.block': 'actorMove',
                  'actor.movementMode': 'walk',
                  'actor.pathMode': 'direct',
                },
              ),
            ],
          ),
        ),
      );

      expect(
        report
            .byCode(CinematicDiagnosticCode.cinematicActorMoveMissingActorRef)
            .single
            .stepId,
        'step_missing_refs',
      );
      expect(
        report
            .byCode(CinematicDiagnosticCode.cinematicActorMoveMissingTargetRef)
            .single
            .stepId,
        'step_missing_refs',
      );
      expect(
        report
            .byCode(CinematicDiagnosticCode.cinematicUnknownActorRef)
            .single
            .referenceId,
        'actor_missing',
      );
      expect(
        report
            .byCode(CinematicDiagnosticCode.cinematicUnknownMovementTargetRef)
            .single
            .referenceId,
        'target_missing',
      );
    });

    test('reports actorMove invalid duration and movement metadata', () {
      final report = diagnoseCinematicAsset(
        CinematicAsset(
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
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_bad_move',
                kind: CinematicTimelineStepKind.actorMove,
                actorId: 'actor_professor',
                targetId: 'target_center',
                durationMs: 0,
                metadata: const {
                  'authoring.source': 'cinematic-builder-v0',
                  'authoring.kind': 'basicBlock',
                  'authoring.block': 'actorMove',
                  'actor.movementMode': 'dash',
                  'actor.pathMode': 'curve',
                },
              ),
            ],
          ),
        ),
      );

      expect(
        report
            .byCode(CinematicDiagnosticCode.cinematicActorMoveInvalidDuration)
            .single
            .stepId,
        'step_bad_move',
      );
      expect(
        report
            .byCode(
                CinematicDiagnosticCode.cinematicActorMoveInvalidMovementMode)
            .single
            .referenceId,
        'dash',
      );
      expect(
        report
            .byCode(
                CinematicDiagnosticCode.cinematicActorMoveUnsupportedPathMode)
            .single
            .referenceId,
        'curve',
      );
    });

    test('reports duplicate cinematic ids in a collection', () {
      final report = diagnoseCinematics([
        _cinematic(id: 'cinematic_intro'),
        _cinematic(id: 'cinematic_intro', title: 'Duplicate intro'),
      ]);

      final diagnostic =
          report.byCode(CinematicDiagnosticCode.cinematicDuplicateId).single;
      expect(diagnostic.severity, CinematicDiagnosticSeverity.error);
      expect(diagnostic.cinematicId, 'cinematic_intro');
    });

    test('reports unknown storyline, chapter, and map references', () {
      final project = ProjectManifest(
        name: 'Cinematic diagnostics test',
        maps: const [
          ProjectMapEntry(
            id: 'map_known',
            name: 'Known Map',
            relativePath: 'maps/map_known.json',
          ),
        ],
        tilesets: const [],
        storylines: [
          StorylineAsset(
            id: 'story_known',
            type: StorylineType.main,
            title: 'Known Story',
            chapters: [
              StorylineChapter(
                id: 'chapter_known',
                title: 'Known Chapter',
                order: 0,
              ),
            ],
          ),
        ],
        cinematics: [
          _cinematic(
            id: 'cinematic_intro',
            storylineId: 'story_missing',
            chapterId: 'chapter_missing',
            mapId: 'map_missing',
          ),
        ],
      );

      final report = diagnoseCinematicsAgainstProject(project);

      expect(
        report.byCode(CinematicDiagnosticCode.cinematicUnknownStorylineRef),
        hasLength(1),
      );
      expect(
        report.byCode(CinematicDiagnosticCode.cinematicUnknownChapterRef),
        hasLength(1),
      );
      expect(
        report.byCode(CinematicDiagnosticCode.cinematicUnknownMapRef),
        hasLength(1),
      );
    });

    test('reports legacy bridge without making it canonical runtime', () {
      final report = diagnoseCinematicAsset(
        _cinematic(
          id: 'cinematic_bridge',
          legacyBridge: CinematicLegacyBridge(
            sourceKind: CinematicLegacyBridgeSourceKind.scenarioAsset,
            scenarioId: 'scenario_bridge',
            cutsceneSchema: 'cutscene_studio_v2',
          ),
        ),
      );

      expect(
        report.byCode(CinematicDiagnosticCode.cinematicLegacyBridge),
        hasLength(1),
      );
      expect(
        report.byCode(
          CinematicDiagnosticCode.cinematicScenarioBridgeNotCanonical,
        ),
        hasLength(1),
      );
    });
  });
}

CinematicAsset _cinematic({
  required String id,
  String title = 'Intro cinematic',
  String? storylineId,
  String? chapterId,
  String? mapId,
  CinematicLegacyBridge? legacyBridge,
}) {
  return CinematicAsset(
    id: id,
    title: title,
    storylineId: storylineId,
    chapterId: chapterId,
    mapId: mapId,
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_wait',
          kind: CinematicTimelineStepKind.wait,
          durationMs: 100,
        ),
      ],
    ),
    legacyBridge: legacyBridge,
  );
}
