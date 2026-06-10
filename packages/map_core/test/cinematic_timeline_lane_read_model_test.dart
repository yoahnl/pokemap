import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('buildCinematicTimelineLaneReadModel', () {
    test('groups timeline steps into deterministic lanes without mutation', () {
      final cinematic = _cinematic();
      final before = cinematic.toJson();

      final readModel = buildCinematicTimelineLaneReadModel(cinematic);
      final secondReadModel = buildCinematicTimelineLaneReadModel(cinematic);

      expect(cinematic.toJson(), before);
      expect(readModel.stepCount, 12);
      expect(readModel.laneCount, 10);
      expect(
        readModel.lanes.map((lane) => lane.laneId),
        [
          'camera',
          'actor:actor_professor',
          'actor:actor_rival',
          'actor:actor_missing',
          'dialogue',
          'fx',
          'audio',
          'transitions',
          'time-global',
          'other',
        ],
      );
      expect(
        secondReadModel.lanes.map((lane) => lane.laneId),
        readModel.lanes.map((lane) => lane.laneId),
      );

      final cameraLane = readModel.laneById('camera')!;
      expect(cameraLane.laneKind, CinematicTimelineLaneKind.camera);
      expect(cameraLane.label, 'Caméra');
      expect(cameraLane.steps.single.stepId, 'step_camera');
      expect(cameraLane.steps.single.stepIndex, 0);

      final professorLane = readModel.laneById('actor:actor_professor')!;
      expect(professorLane.laneKind, CinematicTimelineLaneKind.actor);
      expect(professorLane.actorId, 'actor_professor');
      expect(professorLane.actorLabel, 'Professor');
      expect(professorLane.steps.map((step) => step.stepId), [
        'step_face',
      ]);
      expect(professorLane.steps.single.actorLabel, 'Professor');
      expect(professorLane.steps.single.isAuthoringOwned, isTrue);
      expect(professorLane.steps.single.badges, contains('Builder V0'));

      final emptyActorLane = readModel.laneById('actor:actor_rival')!;
      expect(emptyActorLane.label, 'Acteur: Rival');
      expect(emptyActorLane.steps, isEmpty);

      final unknownActorLane = readModel.laneById('actor:actor_missing')!;
      expect(unknownActorLane.label, 'Acteur inconnu: actor_missing');
      expect(unknownActorLane.steps.single.stepId, 'step_move_unknown_actor');
      expect(unknownActorLane.steps.single.actorLabel, 'actor_missing');

      expect(readModel.laneById('dialogue')!.steps.single.stepId, 'step_line');
      expect(readModel.laneById('fx')!.steps.map((step) => step.stepId), [
        'step_shake',
        'step_fx',
      ]);
      expect(readModel.laneById('audio')!.steps.map((step) => step.stepId), [
        'step_sound',
        'step_music',
      ]);
      expect(
        readModel.laneById('transitions')!.steps.single.stepId,
        'step_fade',
      );
      expect(
        readModel.laneById('time-global')!.steps.map((step) => step.stepId),
        ['step_wait', 'step_marker'],
      );
      expect(readModel.laneById('other')!.steps.single.stepId, 'step_orphan');
    });

    test('exposes actorMove target and movement badges on actor lane', () {
      final cinematic = CinematicAsset(
        id: 'cinematic_actor_move',
        title: 'Actor move lane test',
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
              label: 'Déplacement Professor',
              actorId: 'actor_professor',
              targetId: 'target_center',
              durationMs: 1500,
              metadata: const {
                cinematicTimelineDraftMetadataKindKey:
                    cinematicTimelineBasicBlockMetadataKindValue,
                cinematicTimelineDraftMetadataSourceKey:
                    cinematicTimelineDraftMetadataSourceValue,
                cinematicTimelineAuthoringBlockMetadataKey:
                    cinematicTimelineActorMoveBlockMetadataValue,
                cinematicTimelineActorMovementModeMetadataKey: 'run',
                cinematicTimelineActorPathModeMetadataKey: 'direct',
              },
            ),
          ],
        ),
      );

      final readModel = buildCinematicTimelineLaneReadModel(cinematic);
      final actorLane = readModel.laneById('actor:actor_professor')!;
      final laneStep = actorLane.steps.single;

      expect(laneStep.stepId, 'step_actor_move');
      expect(laneStep.stepIndex, 0);
      expect(laneStep.kind, CinematicTimelineStepKind.actorMove);
      expect(laneStep.label, 'Professor → Centre scène');
      expect(laneStep.targetId, 'target_center');
      expect(laneStep.targetLabel, 'Centre scène');
      expect(laneStep.badges, contains('Builder V0'));
      expect(laneStep.badges, contains('Cible: Centre scène'));
      expect(laneStep.badges, contains('Course'));
      expect(laneStep.badges, contains('Direct'));
    });

    test('actorMove target can resolve from a cinematic stage point', () {
      final cinematic = CinematicAsset(
        id: 'cinematic_actor_move_stage_point',
        title: 'Actor move stage point lane test',
        requiredActors: [
          CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
        ],
        movementTargets: [
          CinematicMovementTargetRef(
            targetId: 'target_move_point',
            label: 'Move Target',
          ),
        ],
        stageContext: CinematicStageContext(
          stagePoints: [
            CinematicStagePoint(
              id: 'point_2',
              label: 'Point 2',
              x: 10,
              y: 15,
            ),
          ],
          movementTargetBindings: [
            CinematicMovementTargetBinding(
              targetId: 'target_move_point',
              kind: CinematicMovementTargetBindingKind.stagePoint,
              sourceId: 'point_2',
            ),
          ],
        ),
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'step_actor_move_sp',
              kind: CinematicTimelineStepKind.actorMove,
              label: 'Move to point 2',
              actorId: 'actor_professor',
              targetId: 'target_move_point',
              durationMs: 1500,
            ),
          ],
        ),
      );

      final readModel = buildCinematicTimelineLaneReadModel(cinematic);
      final actorLane = readModel.laneById('actor:actor_professor')!;
      final laneStep = actorLane.steps.single;

      expect(laneStep.targetLabel, 'Point 2');
    });

    test('actorMove target shows missing label when stage point is missing', () {
      final cinematic = CinematicAsset(
        id: 'cinematic_actor_move_stage_point_missing',
        title: 'Actor move stage point missing lane test',
        requiredActors: [
          CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
        ],
        movementTargets: [
          CinematicMovementTargetRef(
            targetId: 'target_move_point',
            label: 'Move Target',
          ),
        ],
        stageContext: CinematicStageContext(
          stagePoints: [], // No stage points
          movementTargetBindings: [
            CinematicMovementTargetBinding(
              targetId: 'target_move_point',
              kind: CinematicMovementTargetBindingKind.stagePoint,
              sourceId: 'point_2', // Missing
            ),
          ],
        ),
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'step_actor_move_sp',
              kind: CinematicTimelineStepKind.actorMove,
              label: 'Move to point 2',
              actorId: 'actor_professor',
              targetId: 'target_move_point',
              durationMs: 1500,
            ),
          ],
        ),
      );

      final readModel = buildCinematicTimelineLaneReadModel(cinematic);
      final actorLane = readModel.laneById('actor:actor_professor')!;
      final laneStep = actorLane.steps.single;

      expect(laneStep.targetLabel, '[Point de scène manquant]');
    });
  });
}

CinematicAsset _cinematic() {
  return CinematicAsset(
    id: 'cinematic_lane_test',
    title: 'Lane grouping test',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
      CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
    ],
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_camera',
          kind: CinematicTimelineStepKind.camera,
          label: 'Camera reveal',
          durationMs: 500,
        ),
        CinematicTimelineStep(
          id: 'step_face',
          kind: CinematicTimelineStepKind.actorFace,
          label: 'Professor turns',
          durationMs: 300,
          actorId: 'actor_professor',
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey:
                cinematicTimelineActorFaceBlockMetadataValue,
            cinematicTimelineActorDirectionMetadataKey: 'left',
          },
        ),
        CinematicTimelineStep(
          id: 'step_line',
          kind: CinematicTimelineStepKind.dialogueLine,
          label: 'Professor line',
          durationMs: 1200,
          actorId: 'actor_professor',
          dialogueText: 'Bienvenue.',
        ),
        CinematicTimelineStep(
          id: 'step_sound',
          kind: CinematicTimelineStepKind.sound,
          label: 'Door chime',
          durationMs: 200,
          assetRef: 'door_chime',
        ),
        CinematicTimelineStep(
          id: 'step_music',
          kind: CinematicTimelineStepKind.music,
          label: 'Theme',
          durationMs: 900,
          assetRef: 'intro_theme',
        ),
        CinematicTimelineStep(
          id: 'step_fade',
          kind: CinematicTimelineStepKind.fade,
          label: 'Fade in',
          durationMs: 600,
        ),
        CinematicTimelineStep(
          id: 'step_wait',
          kind: CinematicTimelineStepKind.wait,
          label: 'Beat',
          durationMs: 500,
        ),
        CinematicTimelineStep(
          id: 'step_shake',
          kind: CinematicTimelineStepKind.shake,
          label: 'Impact shake',
          durationMs: 150,
        ),
        CinematicTimelineStep(
          id: 'step_fx',
          kind: CinematicTimelineStepKind.fx,
          label: 'Spark',
          durationMs: 250,
        ),
        CinematicTimelineStep(
          id: 'step_marker',
          kind: CinematicTimelineStepKind.marker,
          label: 'Draft marker',
        ),
        CinematicTimelineStep(
          id: 'step_move_unknown_actor',
          kind: CinematicTimelineStepKind.actorMove,
          label: 'Unknown actor move',
          durationMs: 1000,
          actorId: 'actor_missing',
          targetId: 'target_center',
        ),
        CinematicTimelineStep(
          id: 'step_orphan',
          kind: CinematicTimelineStepKind.actorEmote,
          label: 'Orphan emote',
          durationMs: 100,
        ),
      ],
    ),
  );
}
