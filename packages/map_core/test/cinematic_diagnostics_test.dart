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

    test('diagnoses wait duration below minimum', () {
      final report = diagnoseCinematicAsset(
        CinematicAsset(
          id: 'cinematic_intro',
          title: 'Intro cinematic',
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_wait',
                kind: CinematicTimelineStepKind.wait,
                durationMs: cinematicTimelineMinimumDurationMs - 1,
                metadata: const {
                  cinematicTimelineDraftMetadataKindKey:
                      cinematicTimelineBasicBlockMetadataKindValue,
                  cinematicTimelineDraftMetadataSourceKey:
                      cinematicTimelineDraftMetadataSourceValue,
                  cinematicTimelineAuthoringBlockMetadataKey: 'wait',
                },
              ),
            ],
          ),
        ),
      );

      final diagnostic = report
          .byCode(CinematicDiagnosticCode.cinematicInvalidStepDuration)
          .single;
      expect(diagnostic.stepId, 'step_wait');
      expect(diagnostic.message, contains('100 ms'));
      expect(diagnostic.message, contains('30000 ms'));
    });

    test('diagnoses actorMove duration below minimum', () {
      final report = diagnoseCinematicAsset(
        _actorMoveDiagnosticCinematic(
          durationMs: cinematicTimelineActorMoveMinimumDurationMs - 1,
        ),
      );

      final diagnostic = report
          .byCode(CinematicDiagnosticCode.cinematicActorMoveInvalidDuration)
          .single;
      expect(diagnostic.stepId, 'step_actor_move');
      expect(diagnostic.message, contains('200 ms'));
      expect(diagnostic.message, contains('30000 ms'));
    });

    test('diagnoses duration above maximum', () {
      final report = diagnoseCinematicAsset(
        CinematicAsset(
          id: 'cinematic_intro',
          title: 'Intro cinematic',
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_camera',
                kind: CinematicTimelineStepKind.camera,
                durationMs: cinematicTimelineMaximumDurationMs + 1,
                metadata: const {
                  cinematicTimelineDraftMetadataKindKey:
                      cinematicTimelineBasicBlockMetadataKindValue,
                  cinematicTimelineDraftMetadataSourceKey:
                      cinematicTimelineDraftMetadataSourceValue,
                  cinematicTimelineAuthoringBlockMetadataKey: 'camera',
                  cinematicTimelineCameraModeMetadataKey: 'hold',
                },
              ),
            ],
          ),
        ),
      );

      final diagnostic = report
          .byCode(CinematicDiagnosticCode.cinematicInvalidStepDuration)
          .single;
      expect(diagnostic.stepId, 'step_camera');
      expect(diagnostic.message, contains('30000 ms'));
    });

    test('does not diagnose missing duration when fallback is allowed', () {
      final report = diagnoseCinematicAsset(
        CinematicAsset(
          id: 'cinematic_intro',
          title: 'Intro cinematic',
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_face',
                kind: CinematicTimelineStepKind.actorFace,
                actorId: 'actor_professor',
                metadata: const {
                  cinematicTimelineDraftMetadataKindKey:
                      cinematicTimelineBasicBlockMetadataKindValue,
                  cinematicTimelineDraftMetadataSourceKey:
                      cinematicTimelineDraftMetadataSourceValue,
                  cinematicTimelineAuthoringBlockMetadataKey:
                      cinematicTimelineActorFaceBlockMetadataValue,
                  cinematicTimelineActorDirectionMetadataKey: 'right',
                },
              ),
            ],
          ),
          requiredActors: [
            CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
          ],
        ),
      );

      expect(
        report.byCode(CinematicDiagnosticCode.cinematicInvalidStepDuration),
        isEmpty,
      );
      expect(
        report
            .byCode(CinematicDiagnosticCode.cinematicActorMoveInvalidDuration),
        isEmpty,
      );
    });

    test('does not diagnose marker draft without duration as duration error',
        () {
      final report = diagnoseCinematicAsset(
        CinematicAsset(
          id: 'cinematic_intro',
          title: 'Intro cinematic',
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_marker',
                kind: CinematicTimelineStepKind.marker,
                metadata: const {
                  cinematicTimelineDraftMetadataKindKey:
                      cinematicTimelineDraftMetadataKindValue,
                  cinematicTimelineDraftMetadataSourceKey:
                      cinematicTimelineDraftMetadataSourceValue,
                },
              ),
            ],
          ),
        ),
      );

      expect(
        report.byCode(CinematicDiagnosticCode.cinematicInvalidStepDuration),
        isEmpty,
      );
      expect(
        report
            .byCode(CinematicDiagnosticCode.cinematicActorMoveInvalidDuration),
        isEmpty,
      );
    });

    test('diagnostics use the same bounds as authoring validation', () {
      final invalidBasicDuration = cinematicTimelineMinimumDurationMs - 1;
      final invalidActorMoveDuration =
          cinematicTimelineActorMoveMinimumDurationMs - 1;

      expect(
        () => validateCinematicTimelineDurationMs(
          invalidBasicDuration,
          argumentName: 'durationMs',
          minMs: cinematicTimelineMinimumDurationMs,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => validateCinematicTimelineDurationMs(
          invalidActorMoveDuration,
          argumentName: 'durationMs',
          minMs: cinematicTimelineActorMoveMinimumDurationMs,
        ),
        throwsA(isA<ArgumentError>()),
      );

      final report = diagnoseCinematicAsset(
        CinematicAsset(
          id: 'cinematic_intro',
          title: 'Intro cinematic',
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_wait',
                kind: CinematicTimelineStepKind.wait,
                durationMs: invalidBasicDuration,
                metadata: const {
                  cinematicTimelineDraftMetadataKindKey:
                      cinematicTimelineBasicBlockMetadataKindValue,
                  cinematicTimelineDraftMetadataSourceKey:
                      cinematicTimelineDraftMetadataSourceValue,
                  cinematicTimelineAuthoringBlockMetadataKey: 'wait',
                },
              ),
              CinematicTimelineStep(
                id: 'step_actor_move',
                kind: CinematicTimelineStepKind.actorMove,
                actorId: 'actor_professor',
                targetId: 'target_center',
                durationMs: invalidActorMoveDuration,
                metadata: const {
                  cinematicTimelineDraftMetadataKindKey:
                      cinematicTimelineBasicBlockMetadataKindValue,
                  cinematicTimelineDraftMetadataSourceKey:
                      cinematicTimelineDraftMetadataSourceValue,
                  cinematicTimelineAuthoringBlockMetadataKey:
                      cinematicTimelineActorMoveBlockMetadataValue,
                  cinematicTimelineActorMovementModeMetadataKey: 'walk',
                  cinematicTimelineActorPathModeMetadataKey: 'direct',
                },
              ),
            ],
          ),
          requiredActors: [
            CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
          ],
          movementTargets: [
            CinematicMovementTargetRef(
              targetId: 'target_center',
              label: 'Centre scene',
            ),
          ],
        ),
      );

      expect(
        report.byCode(CinematicDiagnosticCode.cinematicInvalidStepDuration),
        hasLength(1),
      );
      expect(
        report
            .byCode(CinematicDiagnosticCode.cinematicActorMoveInvalidDuration),
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

    test('V1-126 reports actorEmote missing and unknown refs', () {
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
                id: 'step_missing_refs',
                kind: CinematicTimelineStepKind.actorEmote,
                durationMs: 800,
                metadata: const {
                  'authoring.source': 'cinematic-builder-v0',
                  'authoring.kind': 'basicBlock',
                  'authoring.block': 'actorEmote',
                },
              ),
              CinematicTimelineStep(
                id: 'step_unknown_refs',
                kind: CinematicTimelineStepKind.actorEmote,
                actorId: 'actor_missing',
                durationMs: 800,
                metadata: const {
                  'authoring.source': 'cinematic-builder-v0',
                  'authoring.kind': 'basicBlock',
                  'authoring.block': 'actorEmote',
                  'actor.emoteId': 'missing_emote',
                },
              ),
            ],
          ),
        ),
      );

      expect(
        report
            .byCode(CinematicDiagnosticCode.cinematicActorEmoteMissingActorRef)
            .single
            .stepId,
        'step_missing_refs',
      );
      expect(
        report
            .byCode(CinematicDiagnosticCode.cinematicActorEmoteMissingEmoteRef)
            .single
            .stepId,
        'step_missing_refs',
      );
      expect(
        report
            .byCode(CinematicDiagnosticCode.cinematicActorEmoteUnknownActorRef)
            .single
            .referenceId,
        'actor_missing',
      );
      expect(
        report
            .byCode(CinematicDiagnosticCode.cinematicActorEmoteUnknownEmoteRef)
            .single
            .referenceId,
        'missing_emote',
      );
      expect(
        report.byCode(CinematicDiagnosticCode.cinematicUnknownActorRef),
        isEmpty,
      );
    });

    test('V1-126 reports actorEmote invalid duration without technical wording',
        () {
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
                id: 'step_bad_emote',
                kind: CinematicTimelineStepKind.actorEmote,
                actorId: 'actor_professor',
                durationMs: 0,
                metadata: const {
                  'authoring.source': 'cinematic-builder-v0',
                  'authoring.kind': 'basicBlock',
                  'authoring.block': 'actorEmote',
                  'actor.emoteId': 'question',
                },
              ),
            ],
          ),
        ),
      );

      final diagnostic = report
          .byCode(CinematicDiagnosticCode.cinematicActorEmoteInvalidDuration)
          .single;
      expect(diagnostic.stepId, 'step_bad_emote');
      expect(diagnostic.message, contains('émotion'));
      expect(diagnostic.message, isNot(contains('frameIndex')));
      expect(diagnostic.message, isNot(contains('sourceRect')));
      expect(diagnostic.message, isNot(contains('atlasRect')));
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

    test('diagnoses unknown stage map and projectMap backdrop readiness', () {
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
        cinematics: [
          _cinematic(
            id: 'cinematic_intro',
            mapId: 'map_missing',
            stageContext: CinematicStageContext(
              backdropMode: CinematicStageBackdropMode.projectMap,
            ),
          ),
          _cinematic(
            id: 'cinematic_draft',
            stageContext: CinematicStageContext(
              backdropMode: CinematicStageBackdropMode.projectMap,
            ),
          ),
        ],
      );

      final report = diagnoseCinematicsAgainstProject(project);

      final unknownMap =
          report.byCode(CinematicDiagnosticCode.stageMapUnknown).single;
      expect(unknownMap.severity, CinematicDiagnosticSeverity.error);
      expect(unknownMap.referenceId, 'map_missing');
      final requiresMap = report
          .byCode(CinematicDiagnosticCode.stageBackdropRequiresMap)
          .single;
      expect(requiresMap.severity, CinematicDiagnosticSeverity.warning);
      expect(requiresMap.cinematicId, 'cinematic_draft');
    });

    test('allows cinematic without stage context as draft', () {
      final report = diagnoseCinematicAsset(
        _cinematic(id: 'cinematic_intro'),
      );

      expect(report.byCode(CinematicDiagnosticCode.stageBackdropRequiresMap),
          isEmpty);
      expect(
          report.byCode(CinematicDiagnosticCode.actorBindingMissing), isEmpty);
      expect(
        report.byCode(CinematicDiagnosticCode.cinematicOnlyCharacterMissing),
        isEmpty,
      );
      expect(report.hasErrors, isFalse);
    });

    test('diagnoses actor appearance binding unknown actor', () {
      final report = diagnoseCinematicAsset(
        _cinematic(
          id: 'cinematic_intro',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
          ],
          stageContext: CinematicStageContext(
            actorBindings: [
              CinematicActorBinding(
                actorId: 'actor_rival',
                kind: CinematicActorBindingKind.cinematicOnly,
              ),
            ],
            actorAppearanceBindings: [
              CinematicActorAppearanceBinding(
                actorId: 'actor_missing',
                characterId: 'character_rival',
              ),
            ],
          ),
        ),
      );

      final diagnostic = report
          .byCode(CinematicDiagnosticCode.actorAppearanceBindingUnknownActor)
          .single;
      expect(diagnostic.severity, CinematicDiagnosticSeverity.error);
      expect(diagnostic.referenceId, 'actor_missing');
    });

    test('diagnoses actor appearance binding unknown character', () {
      final project = ProjectManifest(
        name: 'Cinematic diagnostics test',
        maps: const [],
        tilesets: const [],
        characters: [
          _character(id: 'character_known', name: 'Known'),
        ],
        cinematics: [
          _cinematic(
            id: 'cinematic_intro',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
            ],
            stageContext: CinematicStageContext(
              actorBindings: [
                CinematicActorBinding(
                  actorId: 'actor_rival',
                  kind: CinematicActorBindingKind.cinematicOnly,
                ),
              ],
              actorAppearanceBindings: [
                CinematicActorAppearanceBinding(
                  actorId: 'actor_rival',
                  characterId: 'character_missing',
                ),
              ],
            ),
          ),
        ],
      );

      final report = diagnoseCinematicsAgainstProject(project);

      final diagnostic = report
          .byCode(
              CinematicDiagnosticCode.actorAppearanceBindingUnknownCharacter)
          .single;
      expect(diagnostic.severity, CinematicDiagnosticSeverity.error);
      expect(diagnostic.referenceId, 'character_missing');
    });

    test('diagnoses actor appearance binding requiring cinematic only', () {
      final report = diagnoseCinematicAsset(
        _cinematic(
          id: 'cinematic_intro',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_player', label: 'Joueur'),
          ],
          stageContext: CinematicStageContext(
            actorBindings: [
              CinematicActorBinding(
                actorId: 'actor_player',
                kind: CinematicActorBindingKind.player,
              ),
            ],
            actorAppearanceBindings: [
              CinematicActorAppearanceBinding(
                actorId: 'actor_player',
                characterId: 'character_player',
              ),
            ],
          ),
        ),
      );

      final diagnostic = report
          .byCode(
            CinematicDiagnosticCode.actorAppearanceBindingRequiresCinematicOnly,
          )
          .single;
      expect(diagnostic.severity, CinematicDiagnosticSeverity.error);
      expect(diagnostic.referenceId, 'actor_player');
    });

    test('warns when cinematic only actor has no character appearance', () {
      final report = diagnoseCinematicAsset(
        _cinematic(
          id: 'cinematic_intro',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
          ],
          stageContext: CinematicStageContext(
            actorBindings: [
              CinematicActorBinding(
                actorId: 'actor_rival',
                kind: CinematicActorBindingKind.cinematicOnly,
              ),
            ],
          ),
        ),
      );

      final diagnostic = report
          .byCode(CinematicDiagnosticCode.cinematicOnlyCharacterMissing)
          .single;
      expect(diagnostic.severity, CinematicDiagnosticSeverity.warning);
      expect(diagnostic.referenceId, 'actor_rival');
    });

    test('warns when character library is unavailable for cinematic only actor',
        () {
      final project = ProjectManifest(
        name: 'Cinematic diagnostics test',
        maps: const [],
        tilesets: const [],
        cinematics: [
          _cinematic(
            id: 'cinematic_intro',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
            ],
            stageContext: CinematicStageContext(
              actorBindings: [
                CinematicActorBinding(
                  actorId: 'actor_rival',
                  kind: CinematicActorBindingKind.cinematicOnly,
                ),
              ],
            ),
          ),
        ],
      );

      final report = diagnoseCinematicsAgainstProject(project);

      final diagnostic = report
          .byCode(CinematicDiagnosticCode.characterLibraryUnavailable)
          .single;
      expect(diagnostic.severity, CinematicDiagnosticSeverity.warning);
      expect(diagnostic.referenceId, 'actor_rival');
    });

    test('warns when selected character has missing preview data if detectable',
        () {
      final project = ProjectManifest(
        name: 'Cinematic diagnostics test',
        maps: const [],
        tilesets: const [],
        characters: [
          const ProjectCharacterEntry(
            id: 'character_rival',
            name: 'Rival',
            tilesetId: '',
          ),
        ],
        cinematics: [
          _cinematic(
            id: 'cinematic_intro',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
            ],
            stageContext: CinematicStageContext(
              actorBindings: [
                CinematicActorBinding(
                  actorId: 'actor_rival',
                  kind: CinematicActorBindingKind.cinematicOnly,
                ),
              ],
              actorAppearanceBindings: [
                CinematicActorAppearanceBinding(
                  actorId: 'actor_rival',
                  characterId: 'character_rival',
                ),
              ],
            ),
          ),
        ],
      );

      final report = diagnoseCinematicsAgainstProject(project);

      expect(
        report.byCode(CinematicDiagnosticCode.characterAssetMissingSprite),
        hasLength(1),
      );
      expect(
        report.byCode(CinematicDiagnosticCode.characterAssetMissingPreviewData),
        hasLength(1),
      );
    });

    test('does not warn character missing for map entity actor', () {
      final report = diagnoseCinematicAsset(
        _cinematic(
          id: 'cinematic_intro',
          mapId: 'map_stage',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_npc', label: 'NPC'),
          ],
          stageContext: CinematicStageContext(
            actorBindings: [
              CinematicActorBinding(
                actorId: 'actor_npc',
                kind: CinematicActorBindingKind.mapEntity,
                mapEntityId: 'entity_npc',
              ),
            ],
          ),
        ),
      );

      expect(
        report.byCode(CinematicDiagnosticCode.cinematicOnlyCharacterMissing),
        isEmpty,
      );
    });

    test('does not warn character missing for player actor', () {
      final report = diagnoseCinematicAsset(
        _cinematic(
          id: 'cinematic_intro',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_player', label: 'Joueur'),
          ],
          stageContext: CinematicStageContext(
            actorBindings: [
              CinematicActorBinding(
                actorId: 'actor_player',
                kind: CinematicActorBindingKind.player,
              ),
            ],
          ),
        ),
      );

      expect(
        report.byCode(CinematicDiagnosticCode.cinematicOnlyCharacterMissing),
        isEmpty,
      );
    });

    test('does not warn character missing for unbound actor', () {
      final report = diagnoseCinematicAsset(
        _cinematic(
          id: 'cinematic_intro',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
          ],
          stageContext: CinematicStageContext(
            actorBindings: [
              CinematicActorBinding(
                actorId: 'actor_rival',
                kind: CinematicActorBindingKind.unbound,
              ),
            ],
          ),
        ),
      );

      expect(
        report.byCode(CinematicDiagnosticCode.cinematicOnlyCharacterMissing),
        isEmpty,
      );
    });

    test('does not diagnose old asset without stage context as error', () {
      final report = diagnoseCinematicAsset(_cinematic(id: 'cinematic_intro'));

      expect(
        report
            .byCode(CinematicDiagnosticCode.actorAppearanceBindingUnknownActor),
        isEmpty,
      );
      expect(
        report.byCode(
          CinematicDiagnosticCode.actorAppearanceBindingRequiresCinematicOnly,
        ),
        isEmpty,
      );
      expect(
        report.byCode(CinematicDiagnosticCode.cinematicOnlyCharacterMissing),
        isEmpty,
      );
      expect(report.hasErrors, isFalse);
    });

    test('diagnoses actor binding issues and preview readiness', () {
      final report = diagnoseCinematicAsset(
        _cinematic(
          id: 'cinematic_intro',
          mapId: null,
          requiredActors: [
            CinematicActorRef(actorId: 'actor_player', label: 'Joueur'),
            CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
            CinematicActorRef(actorId: 'actor_missing_binding', label: 'Extra'),
          ],
          stageContext: CinematicStageContext(
            actorBindings: [
              CinematicActorBinding(
                actorId: 'actor_player',
                kind: CinematicActorBindingKind.player,
              ),
              CinematicActorBinding(
                actorId: 'actor_professor',
                kind: CinematicActorBindingKind.player,
              ),
              CinematicActorBinding(
                actorId: 'actor_unknown',
                kind: CinematicActorBindingKind.cinematicOnly,
              ),
              CinematicActorBinding(
                actorId: 'actor_professor',
                kind: CinematicActorBindingKind.mapEntity,
              ),
            ],
          ),
        ),
      );

      expect(
        report.byCode(CinematicDiagnosticCode.actorBindingUnknownActor),
        hasLength(1),
      );
      expect(
        report.byCode(CinematicDiagnosticCode.actorBindingDuplicatePlayer),
        hasLength(1),
      );
      expect(
        report.byCode(CinematicDiagnosticCode.actorBindingRequiresStageMap),
        hasLength(1),
      );
      expect(
        report
            .byCode(CinematicDiagnosticCode.actorBindingMapEntityMissingSource),
        hasLength(1),
      );
      expect(
        report.byCode(CinematicDiagnosticCode.actorBindingMissing),
        hasLength(1),
      );
    });

    test('diagnoses initial placement issues and preview readiness', () {
      final report = diagnoseCinematicAsset(
        _cinematic(
          id: 'cinematic_intro',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
            CinematicActorRef(actorId: 'actor_extra', label: 'Extra'),
            CinematicActorRef(actorId: 'actor_no_placement', label: 'No place'),
          ],
          movementTargets: [
            CinematicMovementTargetRef(
              targetId: 'target_center',
              label: 'Centre scene',
            ),
          ],
          stageContext: CinematicStageContext(
            actorBindings: [
              CinematicActorBinding(
                actorId: 'actor_professor',
                kind: CinematicActorBindingKind.cinematicOnly,
              ),
            ],
            initialPlacements: [
              CinematicActorInitialPlacement(
                actorId: 'actor_missing',
                kind: CinematicActorInitialPlacementKind.unset,
              ),
              CinematicActorInitialPlacement(
                actorId: 'actor_professor',
                kind: CinematicActorInitialPlacementKind.fromMovementTarget,
                targetId: 'target_missing',
              ),
              CinematicActorInitialPlacement(
                actorId: 'actor_extra',
                kind: CinematicActorInitialPlacementKind.fromMapEntity,
              ),
            ],
          ),
        ),
      );

      expect(
        report
            .byCode(CinematicDiagnosticCode.actorInitialPlacementUnknownActor),
        hasLength(1),
      );
      expect(
        report
            .byCode(CinematicDiagnosticCode.actorInitialPlacementTargetUnknown),
        hasLength(1),
      );
      expect(
        report.byCode(
            CinematicDiagnosticCode.actorInitialPlacementRequiresBinding),
        hasLength(1),
      );
      expect(
        report.byCode(CinematicDiagnosticCode.actorInitialPlacementMissing),
        hasLength(1),
      );
    });

    test('diagnoses movement target binding issues', () {
      final report = diagnoseCinematicAsset(
        _cinematic(
          id: 'cinematic_intro',
          movementTargets: [
            CinematicMovementTargetRef(
              targetId: 'target_center',
              label: 'Centre scene',
            ),
            CinematicMovementTargetRef(
              targetId: 'target_abstract',
              label: 'Point abstrait',
            ),
          ],
          stageContext: CinematicStageContext(
            movementTargetBindings: [
              CinematicMovementTargetBinding(
                targetId: 'target_missing',
                kind: CinematicMovementTargetBindingKind.abstractPoint,
              ),
              CinematicMovementTargetBinding(
                targetId: 'target_center',
                kind: CinematicMovementTargetBindingKind.mapEntity,
              ),
              CinematicMovementTargetBinding(
                targetId: 'target_abstract',
                kind: CinematicMovementTargetBindingKind.abstractPoint,
              ),
            ],
          ),
        ),
      );

      expect(
        report
            .byCode(CinematicDiagnosticCode.movementTargetBindingUnknownTarget),
        hasLength(1),
      );
      expect(
        report.byCode(
            CinematicDiagnosticCode.movementTargetBindingRequiresStageMap),
        hasLength(1),
      );
      expect(
        report
            .byCode(CinematicDiagnosticCode.movementTargetBindingMissingSource),
        hasLength(1),
      );
      expect(report.hasErrors, isTrue);
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

    test('diagnoses duplicate stage point ids', () {
      final report = diagnoseCinematicAsset(
        CinematicAsset(
          id: 'cinematic_intro',
          title: 'Intro',
          stageContext: CinematicStageContext(
            stagePoints: [
              CinematicStagePoint(id: 'point_a', label: 'Point A', x: 1, y: 1),
              CinematicStagePoint(
                  id: 'point_a', label: 'Point A Duplicate', x: 2, y: 2),
            ],
          ),
          timeline: CinematicTimeline(),
        ),
      );

      final diagnostic =
          report.byCode(CinematicDiagnosticCode.stagePointDuplicateId).single;
      expect(diagnostic.severity, CinematicDiagnosticSeverity.error);
      expect(diagnostic.referenceId, 'point_a');
    });

    test('enforces non-empty label in CinematicStagePoint constructor', () {
      expect(
        () => CinematicStagePoint(id: 'point_a', label: ' ', x: 1, y: 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('diagnoses invalid stage point coordinates', () {
      final report = diagnoseCinematicAsset(
        CinematicAsset(
          id: 'cinematic_intro',
          title: 'Intro',
          stageContext: CinematicStageContext(
            stagePoints: [
              CinematicStagePoint(
                  id: 'point_a', label: 'Point A', x: double.nan, y: 1),
            ],
          ),
          timeline: CinematicTimeline(),
        ),
      );

      final diagnostic = report
          .byCode(CinematicDiagnosticCode.stagePointInvalidCoordinate)
          .single;
      expect(diagnostic.severity, CinematicDiagnosticSeverity.error);
      expect(diagnostic.referenceId, 'point_a');
    });

    test('diagnoses stage point without stage map', () {
      final report = diagnoseCinematicAsset(
        CinematicAsset(
          id: 'cinematic_intro',
          title: 'Intro',
          stageContext: CinematicStageContext(
            stagePoints: [
              CinematicStagePoint(id: 'point_a', label: 'Point A', x: 1, y: 1),
            ],
          ),
          timeline: CinematicTimeline(),
        ),
      );

      final diagnostic = report
          .byCode(CinematicDiagnosticCode.stagePointWithoutStageMap)
          .single;
      expect(diagnostic.severity, CinematicDiagnosticSeverity.warning);
    });

    test(
        'diagnoses stage point out of map bounds when map dimensions are available',
        () {
      final report = diagnoseCinematicAsset(
        CinematicAsset(
          id: 'cinematic_intro',
          title: 'Intro',
          mapId: 'map_stage',
          stageContext: CinematicStageContext(
            stagePoints: [
              CinematicStagePoint(
                  id: 'point_a', label: 'Point A', x: 25.5, y: 10),
              CinematicStagePoint(
                  id: 'point_b', label: 'Point B', x: 10, y: -1),
              CinematicStagePoint(
                  id: 'point_c', label: 'Point C', x: 10, y: 15),
            ],
          ),
          timeline: CinematicTimeline(),
        ),
        mapWidth: 20,
        mapHeight: 15,
      );

      final outOfMapDiagnostics =
          report.byCode(CinematicDiagnosticCode.stagePointOutOfMap);
      expect(outOfMapDiagnostics, hasLength(3));
      expect(outOfMapDiagnostics[0].referenceId, 'point_a');
      expect(outOfMapDiagnostics[1].referenceId, 'point_b');
      expect(outOfMapDiagnostics[2].referenceId, 'point_c');
    });

    test('diagnoses stage point initial placement issues', () {
      // 1. Valid case
      final validReport = diagnoseCinematicAsset(
        CinematicAsset(
          id: 'cinematic_valid',
          title: 'Valid',
          mapId: 'map_lab',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
          ],
          stageContext: CinematicStageContext(
            stagePoints: [
              CinematicStagePoint(id: 'point_a', label: 'Point A', x: 5, y: 5),
            ],
            initialPlacements: [
              CinematicActorInitialPlacement(
                actorId: 'actor_professor',
                kind: CinematicActorInitialPlacementKind.stagePoint,
                stagePointId: 'point_a',
              ),
            ],
          ),
          timeline: CinematicTimeline(),
        ),
        mapWidth: 10,
        mapHeight: 10,
      );
      expect(
          validReport.byCode(
              CinematicDiagnosticCode.actorInitialPlacementStagePointMissing),
          isEmpty);
      expect(
          validReport.byCode(CinematicDiagnosticCode
              .actorInitialPlacementStagePointWithoutStageMap),
          isEmpty);
      expect(
          validReport.byCode(
              CinematicDiagnosticCode.actorInitialPlacementStagePointOutOfMap),
          isEmpty);

      // 2. Missing stage point reference
      final missingReport = diagnoseCinematicAsset(
        CinematicAsset(
          id: 'cinematic_missing',
          title: 'Missing',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
          ],
          stageContext: CinematicStageContext(
            stagePoints: const [],
            initialPlacements: [
              CinematicActorInitialPlacement(
                actorId: 'actor_professor',
                kind: CinematicActorInitialPlacementKind.stagePoint,
                stagePointId: 'point_a',
              ),
            ],
          ),
          timeline: CinematicTimeline(),
        ),
      );
      final missingDiag = missingReport
          .byCode(
              CinematicDiagnosticCode.actorInitialPlacementStagePointMissing)
          .single;
      expect(missingDiag.severity, CinematicDiagnosticSeverity.error);
      expect(missingDiag.referenceId, 'actor_professor');

      // 3. Stage point initial placement without stage map
      final noMapReport = diagnoseCinematicAsset(
        CinematicAsset(
          id: 'cinematic_no_map',
          title: 'No Map',
          mapId: null,
          requiredActors: [
            CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
          ],
          stageContext: CinematicStageContext(
            stagePoints: [
              CinematicStagePoint(id: 'point_a', label: 'Point A', x: 5, y: 5),
            ],
            initialPlacements: [
              CinematicActorInitialPlacement(
                actorId: 'actor_professor',
                kind: CinematicActorInitialPlacementKind.stagePoint,
                stagePointId: 'point_a',
              ),
            ],
          ),
          timeline: CinematicTimeline(),
        ),
      );
      final noMapDiag = noMapReport
          .byCode(CinematicDiagnosticCode
              .actorInitialPlacementStagePointWithoutStageMap)
          .single;
      expect(noMapDiag.severity, CinematicDiagnosticSeverity.warning);
      expect(noMapDiag.referenceId, 'actor_professor');

      // 4. Stage point initial placement out of map bounds
      final outOfBoundsReport = diagnoseCinematicAsset(
        CinematicAsset(
          id: 'cinematic_out_of_bounds',
          title: 'Out of Bounds',
          mapId: 'map_lab',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
          ],
          stageContext: CinematicStageContext(
            stagePoints: [
              CinematicStagePoint(id: 'point_a', label: 'Point A', x: 15, y: 5),
            ],
            initialPlacements: [
              CinematicActorInitialPlacement(
                actorId: 'actor_professor',
                kind: CinematicActorInitialPlacementKind.stagePoint,
                stagePointId: 'point_a',
              ),
            ],
          ),
          timeline: CinematicTimeline(),
        ),
        mapWidth: 10,
        mapHeight: 10,
      );
      final outOfBoundsDiag = outOfBoundsReport
          .byCode(
              CinematicDiagnosticCode.actorInitialPlacementStagePointOutOfMap)
          .single;
      expect(outOfBoundsDiag.severity, CinematicDiagnosticSeverity.error);
      expect(outOfBoundsDiag.referenceId, 'actor_professor');
    });

    test('diagnoses movement target binding stage point issues', () {
      // 1. Valid case
      final validReport = diagnoseCinematicAsset(
        CinematicAsset(
          id: 'cinematic_valid',
          title: 'Valid',
          mapId: 'map_lab',
          movementTargets: [
            CinematicMovementTargetRef(
                targetId: 'target_center', label: 'Centre'),
          ],
          stageContext: CinematicStageContext(
            stagePoints: [
              CinematicStagePoint(id: 'point_a', label: 'Point A', x: 5, y: 5),
            ],
            movementTargetBindings: [
              CinematicMovementTargetBinding(
                targetId: 'target_center',
                kind: CinematicMovementTargetBindingKind.stagePoint,
                sourceId: 'point_a',
              ),
            ],
          ),
          timeline: CinematicTimeline(),
        ),
        mapWidth: 10,
        mapHeight: 10,
      );
      expect(
          validReport.byCode(
              CinematicDiagnosticCode.movementTargetBindingStagePointMissing),
          isEmpty);
      expect(
          validReport.byCode(CinematicDiagnosticCode
              .movementTargetBindingStagePointWithoutStageMap),
          isEmpty);
      expect(
          validReport.byCode(
              CinematicDiagnosticCode.movementTargetBindingStagePointOutOfMap),
          isEmpty);

      // 2. Missing stage point reference
      final missingReport = diagnoseCinematicAsset(
        CinematicAsset(
          id: 'cinematic_missing',
          title: 'Missing',
          movementTargets: [
            CinematicMovementTargetRef(
                targetId: 'target_center', label: 'Centre'),
          ],
          stageContext: CinematicStageContext(
            stagePoints: const [],
            movementTargetBindings: [
              CinematicMovementTargetBinding(
                targetId: 'target_center',
                kind: CinematicMovementTargetBindingKind.stagePoint,
                sourceId: 'point_a',
              ),
            ],
          ),
          timeline: CinematicTimeline(),
        ),
      );
      final missingDiag = missingReport
          .byCode(
              CinematicDiagnosticCode.movementTargetBindingStagePointMissing)
          .single;
      expect(missingDiag.severity, CinematicDiagnosticSeverity.error);
      expect(missingDiag.referenceId, 'target_center');

      // 3. Stage point movement target binding without stage map
      final noMapReport = diagnoseCinematicAsset(
        CinematicAsset(
          id: 'cinematic_no_map',
          title: 'No Map',
          mapId: null,
          movementTargets: [
            CinematicMovementTargetRef(
                targetId: 'target_center', label: 'Centre'),
          ],
          stageContext: CinematicStageContext(
            stagePoints: [
              CinematicStagePoint(id: 'point_a', label: 'Point A', x: 5, y: 5),
            ],
            movementTargetBindings: [
              CinematicMovementTargetBinding(
                targetId: 'target_center',
                kind: CinematicMovementTargetBindingKind.stagePoint,
                sourceId: 'point_a',
              ),
            ],
          ),
          timeline: CinematicTimeline(),
        ),
      );
      final noMapDiag = noMapReport
          .byCode(CinematicDiagnosticCode
              .movementTargetBindingStagePointWithoutStageMap)
          .single;
      expect(noMapDiag.severity, CinematicDiagnosticSeverity.warning);
      expect(noMapDiag.referenceId, 'target_center');

      // 4. Stage point movement target binding out of map bounds
      final outOfBoundsReport = diagnoseCinematicAsset(
        CinematicAsset(
          id: 'cinematic_out_of_bounds',
          title: 'Out of Bounds',
          mapId: 'map_lab',
          movementTargets: [
            CinematicMovementTargetRef(
                targetId: 'target_center', label: 'Centre'),
          ],
          stageContext: CinematicStageContext(
            stagePoints: [
              CinematicStagePoint(id: 'point_a', label: 'Point A', x: 15, y: 5),
            ],
            movementTargetBindings: [
              CinematicMovementTargetBinding(
                targetId: 'target_center',
                kind: CinematicMovementTargetBindingKind.stagePoint,
                sourceId: 'point_a',
              ),
            ],
          ),
          timeline: CinematicTimeline(),
        ),
        mapWidth: 10,
        mapHeight: 10,
      );
      final outOfBoundsDiag = outOfBoundsReport
          .byCode(
              CinematicDiagnosticCode.movementTargetBindingStagePointOutOfMap)
          .single;
      expect(outOfBoundsDiag.severity, CinematicDiagnosticSeverity.error);
      expect(outOfBoundsDiag.referenceId, 'target_center');
    });

    group('manual path diagnostics', () {
      final pointA =
          CinematicStagePoint(id: 'point_a', label: 'Point A', x: 5, y: 5);
      final pointB =
          CinematicStagePoint(id: 'point_b', label: 'Point B', x: 15, y: 5);

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

        final manualPathDiags = report.diagnostics
            .where((d) => {
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
                }.contains(d.code))
            .toList();
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

        final dupDiags =
            report.byCode(CinematicDiagnosticCode.manualPathDuplicateId);
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
          (d) =>
              d.code == CinematicDiagnosticCode.manualPathEmpty &&
              d.referenceId == 'path_unused',
        );
        expect(unusedDiag.severity, CinematicDiagnosticSeverity.warning);

        final usedDiag = report.diagnostics.firstWhere(
          (d) =>
              d.code == CinematicDiagnosticCode.manualPathEmpty &&
              d.referenceId == 'path_used',
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

        final diag = report
            .byCode(CinematicDiagnosticCode.manualPathStagePointMissing)
            .single;
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

        final diag = report
            .byCode(CinematicDiagnosticCode.manualPathStagePointDuplicate)
            .single;
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

        final diag = report
            .byCode(CinematicDiagnosticCode.manualPathWithoutStageMap)
            .single;
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

        final diag = report
            .byCode(CinematicDiagnosticCode.manualPathStagePointOutOfMap)
            .single;
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

        final diag =
            report.byCode(CinematicDiagnosticCode.manualPathOrphaned).single;
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

        final diag = report
            .byCode(CinematicDiagnosticCode.actorMoveManualPathMissing)
            .single;
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

        final diag = report
            .byCode(CinematicDiagnosticCode.actorMoveManualPathAmbiguous)
            .single;
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

        final diag = report
            .byCode(CinematicDiagnosticCode.actorMoveManualPathUnused)
            .single;
        expect(diag.severity, CinematicDiagnosticSeverity.warning);
        expect(diag.stepId, 'step_move');
      });
    });
  });
}

CinematicAsset _cinematic({
  required String id,
  String title = 'Intro cinematic',
  String? storylineId,
  String? chapterId,
  String? mapId,
  List<CinematicActorRef> requiredActors = const [],
  List<CinematicMovementTargetRef> movementTargets = const [],
  CinematicStageContext? stageContext,
  CinematicLegacyBridge? legacyBridge,
}) {
  return CinematicAsset(
    id: id,
    title: title,
    storylineId: storylineId,
    chapterId: chapterId,
    mapId: mapId,
    requiredActors: requiredActors,
    movementTargets: movementTargets,
    stageContext: stageContext,
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

CinematicAsset _actorMoveDiagnosticCinematic({required int durationMs}) {
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
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_actor_move',
          kind: CinematicTimelineStepKind.actorMove,
          actorId: 'actor_professor',
          targetId: 'target_center',
          durationMs: durationMs,
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey:
                cinematicTimelineActorMoveBlockMetadataValue,
            cinematicTimelineActorMovementModeMetadataKey: 'walk',
            cinematicTimelineActorPathModeMetadataKey: 'direct',
          },
        ),
      ],
    ),
  );
}

ProjectCharacterEntry _character({
  required String id,
  required String name,
}) {
  return ProjectCharacterEntry(
    id: id,
    name: name,
    tilesetId: 'tileset_characters',
    animations: const [
      CharacterAnimation(
        state: CharacterAnimationState.idle,
        direction: EntityFacing.south,
        frames: [
          CharacterAnimationFrame(
            source: TilesetSourceRect(x: 0, y: 0),
          ),
        ],
      ),
    ],
  );
}
