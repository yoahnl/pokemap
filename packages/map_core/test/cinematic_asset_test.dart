import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('CinematicAsset', () {
    test('round-trips a linear cinematic asset through JSON', () {
      final asset = CinematicAsset(
        id: 'cinematic_intro',
        title: 'Intro cinematic',
        description: 'Camera and actor beats.',
        storylineId: 'story_main',
        chapterId: 'chapter_1',
        mapId: 'map_lab',
        tags: const ['intro', 'camera'],
        requiredActors: [
          CinematicActorRef(
            actorId: 'actor_professor',
            label: 'Professor',
            entityId: 'entity_professor',
            role: 'speaker',
          ),
        ],
        movementTargets: [
          CinematicMovementTargetRef(
            targetId: 'target_center',
            label: 'Centre de scène',
            description: 'Point authoring stable.',
          ),
        ],
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'step_wait',
              kind: CinematicTimelineStepKind.wait,
              label: 'Wait',
              durationMs: 300,
            ),
            CinematicTimelineStep(
              id: 'step_dialogue',
              kind: CinematicTimelineStepKind.dialogueLine,
              actorId: 'actor_professor',
              dialogueText: 'Welcome.',
            ),
            CinematicTimelineStep(
              id: 'step_sound',
              kind: CinematicTimelineStepKind.sound,
              assetRef: 'sfx_chime',
            ),
          ],
        ),
        notes: 'Authoring note.',
        metadata: const {'author': 'test'},
        legacyBridge: CinematicLegacyBridge(
          sourceKind: CinematicLegacyBridgeSourceKind.cutsceneStudio,
          scenarioId: 'scenario_legacy_intro',
          cutsceneSchema: 'cutscene_studio_v2',
          notes: 'Imported later by an explicit tool.',
        ),
      );

      final json =
          jsonDecode(jsonEncode(asset.toJson())) as Map<String, dynamic>;
      final decoded = CinematicAsset.fromJson(json);

      expect(decoded, asset);
      expect(decoded.timeline.steps.map((step) => step.kind), [
        CinematicTimelineStepKind.wait,
        CinematicTimelineStepKind.dialogueLine,
        CinematicTimelineStepKind.sound,
      ]);
      expect(decoded.requiredActors.single.actorId, 'actor_professor');
      expect(decoded.movementTargets.single.targetId, 'target_center');
      expect(decoded.movementTargets.single.label, 'Centre de scène');
      expect(decoded.legacyBridge?.scenarioId, 'scenario_legacy_intro');
    });

    test('serializes cinematic stage context without duplicating map id', () {
      final asset = CinematicAsset(
        id: 'cinematic_stage_intro',
        title: 'Stage intro',
        mapId: 'map_lab',
        requiredActors: [
          CinematicActorRef(actorId: 'actor_player', label: 'Joueur'),
          CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
        ],
        movementTargets: [
          CinematicMovementTargetRef(
            targetId: 'target_center',
            label: 'Centre scene',
          ),
        ],
        stageContext: CinematicStageContext(
          backdropMode: CinematicStageBackdropMode.projectMap,
          actorBindings: [
            CinematicActorBinding(
              actorId: 'actor_player',
              kind: CinematicActorBindingKind.player,
            ),
            CinematicActorBinding(
              actorId: 'actor_professor',
              kind: CinematicActorBindingKind.mapEntity,
              mapEntityId: 'entity_professor',
            ),
          ],
          initialPlacements: [
            CinematicActorInitialPlacement(
              actorId: 'actor_professor',
              kind: CinematicActorInitialPlacementKind.fromMovementTarget,
              targetId: 'target_center',
            ),
          ],
          movementTargetBindings: [
            CinematicMovementTargetBinding(
              targetId: 'target_center',
              kind: CinematicMovementTargetBindingKind.mapEntity,
              sourceId: 'entity_stage_center',
            ),
          ],
        ),
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'step_actor_move',
              kind: CinematicTimelineStepKind.actorMove,
              actorId: 'actor_professor',
              targetId: 'target_center',
              durationMs: 1000,
            ),
          ],
        ),
      );

      final json =
          jsonDecode(jsonEncode(asset.toJson())) as Map<String, dynamic>;
      final stageJson = json['stageContext'] as Map<String, dynamic>;
      final encoded = jsonEncode(json);
      final decoded = CinematicAsset.fromJson(json);

      expect(json['mapId'], 'map_lab');
      expect(stageJson, isNot(contains('mapId')));
      expect(RegExp('"mapId"').allMatches(encoded), hasLength(1));
      expect(decoded, asset);
      expect(decoded.timeline.steps, asset.timeline.steps);
      expect(encoded, isNot(contains('startMs')));
      expect(encoded, isNot(contains('endMs')));
    });

    test(
        'serializes cinematic actor appearance binding for cinematic only actor',
        () {
      final asset = CinematicAsset(
        id: 'cinematic_character_intro',
        title: 'Character intro',
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
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'step_face',
              kind: CinematicTimelineStepKind.actorFace,
              actorId: 'actor_rival',
              metadata: const {
                'authoring.source': 'cinematic-builder-v0',
                'authoring.kind': 'basicBlock',
                'authoring.block': 'actorFace',
                'actor.direction': 'left',
              },
            ),
          ],
        ),
      );

      final json =
          jsonDecode(jsonEncode(asset.toJson())) as Map<String, dynamic>;
      final stageJson = json['stageContext'] as Map<String, dynamic>;
      final actorBindingJson = (stageJson['actorBindings'] as List<dynamic>)
          .single as Map<String, dynamic>;
      final appearanceBindingJson =
          (stageJson['actorAppearanceBindings'] as List<dynamic>).single
              as Map<String, dynamic>;
      final encoded = jsonEncode(json);
      final decoded = CinematicAsset.fromJson(json);

      expect(appearanceBindingJson, containsPair('actorId', 'actor_rival'));
      expect(
        appearanceBindingJson,
        containsPair('characterId', 'character_rival'),
      );
      expect(actorBindingJson, isNot(contains('characterId')));
      expect(decoded, asset);
      expect(
        decoded.stageContext?.actorAppearanceBindings.single.characterId,
        'character_rival',
      );
      expect(decoded.timeline.steps, asset.timeline.steps);
      expect(encoded, isNot(contains('startMs')));
      expect(encoded, isNot(contains('endMs')));
    });

    test('deserializes cinematic asset without actor appearance bindings', () {
      final decoded = CinematicAsset.fromJson({
        'id': 'cinematic_intro',
        'title': 'Intro cinematic',
        'stageContext': {
          'backdropMode': 'none',
          'actorBindings': [
            {'actorId': 'actor_rival', 'kind': 'cinematicOnly'},
          ],
          'initialPlacements': <Object>[],
          'movementTargetBindings': <Object>[],
        },
        'timeline': {'steps': <Object>[]},
      });

      expect(decoded.stageContext?.actorAppearanceBindings, isEmpty);
    });

    test('does not store character id inside actor binding', () {
      final context = CinematicStageContext(
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
      );

      final json = context.toJson();
      final actorBindingJson = (json['actorBindings'] as List<dynamic>).single
          as Map<String, dynamic>;
      final appearanceJson = (json['actorAppearanceBindings'] as List<dynamic>)
          .single as Map<String, dynamic>;

      expect(actorBindingJson, isNot(contains('characterId')));
      expect(appearanceJson, containsPair('characterId', 'character_rival'));
    });

    test('roundtrips actor appearance bindings in stage context', () {
      final context = CinematicStageContext(
        actorAppearanceBindings: [
          CinematicActorAppearanceBinding(
            actorId: 'actor_rival',
            characterId: 'character_rival',
          ),
          CinematicActorAppearanceBinding(
            actorId: 'actor_friend',
            characterId: 'character_friend',
          ),
        ],
      );

      final decoded = CinematicStageContext.fromJson(
        jsonDecode(jsonEncode(context.toJson())) as Map<String, dynamic>,
      );

      expect(decoded, context);
      expect(
          decoded.actorAppearanceBindings.map((binding) => binding.actorId), [
        'actor_rival',
        'actor_friend',
      ]);
    });

    test('keeps actorAppearanceBindings empty by default', () {
      final context = CinematicStageContext();

      expect(context.actorAppearanceBindings, isEmpty);
      expect(context.toJson(), contains('actorAppearanceBindings'));
      expect(context.toJson()['actorAppearanceBindings'], isEmpty);
    });

    test('does not persist startMs or endMs for actor appearance binding', () {
      final asset = CinematicAsset(
        id: 'cinematic_intro',
        title: 'Intro cinematic',
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
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'step_wait',
              kind: CinematicTimelineStepKind.wait,
              durationMs: 100,
            ),
          ],
        ),
      );

      final encoded = jsonEncode(asset.toJson());

      expect(encoded, isNot(contains('startMs')));
      expect(encoded, isNot(contains('endMs')));
    });

    test('defaults missing movement targets to an empty list', () {
      final decoded = CinematicAsset.fromJson({
        'id': 'cinematic_intro',
        'title': 'Intro cinematic',
        'timeline': {'steps': <Object>[]},
      });

      expect(decoded.movementTargets, isEmpty);
      expect(decoded.toJson(), containsPair('movementTargets', <Object>[]));
    });

    test('deserializes cinematic asset without stage context', () {
      final decoded = CinematicAsset.fromJson({
        'id': 'cinematic_intro',
        'title': 'Intro cinematic',
        'timeline': {'steps': <Object>[]},
      });

      expect(decoded.stageContext, isNull);
      expect(decoded.toJson(), isNot(contains('stageContext')));
    });

    test('serializes all V0 stage context enum variants', () {
      final context = CinematicStageContext(
        actorBindings: [
          CinematicActorBinding(
            actorId: 'actor_player',
            kind: CinematicActorBindingKind.player,
          ),
          CinematicActorBinding(
            actorId: 'actor_map',
            kind: CinematicActorBindingKind.mapEntity,
            mapEntityId: 'entity_map',
          ),
          CinematicActorBinding(
            actorId: 'actor_cinematic',
            kind: CinematicActorBindingKind.cinematicOnly,
          ),
          CinematicActorBinding(
            actorId: 'actor_unbound',
            kind: CinematicActorBindingKind.unbound,
          ),
        ],
        initialPlacements: [
          CinematicActorInitialPlacement(
            actorId: 'actor_player',
            kind: CinematicActorInitialPlacementKind.unset,
          ),
          CinematicActorInitialPlacement(
            actorId: 'actor_map',
            kind: CinematicActorInitialPlacementKind.fromMapEntity,
          ),
          CinematicActorInitialPlacement(
            actorId: 'actor_cinematic',
            kind: CinematicActorInitialPlacementKind.fromMovementTarget,
            targetId: 'target_center',
          ),
        ],
        movementTargetBindings: [
          CinematicMovementTargetBinding(
            targetId: 'target_abstract',
            kind: CinematicMovementTargetBindingKind.abstractPoint,
          ),
          CinematicMovementTargetBinding(
            targetId: 'target_entity',
            kind: CinematicMovementTargetBindingKind.mapEntity,
            sourceId: 'entity_target',
          ),
          CinematicMovementTargetBinding(
            targetId: 'target_event',
            kind: CinematicMovementTargetBindingKind.mapEvent,
            sourceId: 'event_target',
          ),
        ],
      );

      final decoded = CinematicStageContext.fromJson(
        jsonDecode(jsonEncode(context.toJson())) as Map<String, dynamic>,
      );

      expect(decoded, context);
      expect(decoded.actorBindings.map((binding) => binding.kind), [
        CinematicActorBindingKind.player,
        CinematicActorBindingKind.mapEntity,
        CinematicActorBindingKind.cinematicOnly,
        CinematicActorBindingKind.unbound,
      ]);
      expect(decoded.initialPlacements.map((placement) => placement.kind), [
        CinematicActorInitialPlacementKind.unset,
        CinematicActorInitialPlacementKind.fromMapEntity,
        CinematicActorInitialPlacementKind.fromMovementTarget,
      ]);
      expect(decoded.movementTargetBindings.map((binding) => binding.kind), [
        CinematicMovementTargetBindingKind.abstractPoint,
        CinematicMovementTargetBindingKind.mapEntity,
        CinematicMovementTargetBindingKind.mapEvent,
      ]);
    });

    test('keeps timeline steps linear and rejects branch/gameplay step kinds',
        () {
      expect(
        () => CinematicTimelineStep.fromJson({
          'id': 'step_branch',
          'kind': 'branch',
        }),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => CinematicTimelineStep.fromJson({
          'id': 'step_battle',
          'kind': 'battle',
        }),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => CinematicTimelineStep.fromJson({
          'id': 'step_set_fact',
          'kind': 'setFact',
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('requires stable id and readable title', () {
      expect(
        () => CinematicAsset(
          id: ' ',
          title: 'Intro',
          timeline: CinematicTimeline(),
        ),
        throwsA(anyOf(isA<ArgumentError>(), isA<ValidationException>())),
      );
      expect(
        () => CinematicAsset(
          id: 'cinematic_intro',
          title: ' ',
          timeline: CinematicTimeline(),
        ),
        throwsA(anyOf(isA<ArgumentError>(), isA<ValidationException>())),
      );
    });

    test('does not import Flutter, Flame, runtime, or editor packages', () {
      final source =
          File('lib/src/models/cinematic_asset.dart').readAsStringSync();

      expect(source, isNot(contains('package:flutter')));
      expect(source, isNot(contains('package:flame')));
      expect(source, isNot(contains('map_runtime')));
      expect(source, isNot(contains('map_editor')));
    });

    test('serializes cinematic stage points in stage context', () {
      final asset = CinematicAsset(
        id: 'cinematic_stage_points_test',
        title: 'Stage points test',
        requiredActors: const [],
        movementTargets: const [],
        stageContext: CinematicStageContext(
          stagePoints: [
            CinematicStagePoint(
              id: 'point_a',
              label: 'Point A',
              x: 10.5,
              y: 20.0,
              description: 'First test point',
            ),
            CinematicStagePoint(
              id: 'point_b',
              label: 'Point B',
              x: 15.0,
              y: 30.5,
            ),
          ],
        ),
        timeline: CinematicTimeline(steps: const []),
      );

      final json = jsonDecode(jsonEncode(asset.toJson())) as Map<String, dynamic>;
      final decoded = CinematicAsset.fromJson(json);

      expect(decoded.stageContext?.stagePoints, hasLength(2));
      final pA = decoded.stageContext!.stagePoints[0];
      expect(pA.id, 'point_a');
      expect(pA.label, 'Point A');
      expect(pA.x, 10.5);
      expect(pA.y, 20.0);
      expect(pA.description, 'First test point');

      final pB = decoded.stageContext!.stagePoints[1];
      expect(pB.id, 'point_b');
      expect(pB.label, 'Point B');
      expect(pB.x, 15.0);
      expect(pB.y, 30.5);
      expect(pB.description, isNull);
    });

    test('deserializes old cinematic stage context without stage points', () {
      final decoded = CinematicStageContext.fromJson(const {
        'backdropMode': 'none',
        'actorBindings': <Object>[],
        'initialPlacements': <Object>[],
        'movementTargetBindings': <Object>[],
      });
      expect(decoded.stagePoints, isEmpty);
    });

    test('preserves stage point order across json roundtrip', () {
      final context = CinematicStageContext(
        stagePoints: [
          CinematicStagePoint(id: 'point_a', label: 'Point A', x: 1, y: 1),
          CinematicStagePoint(id: 'point_b', label: 'Point B', x: 2, y: 2),
        ],
      );
      final json = jsonDecode(jsonEncode(context.toJson())) as Map<String, dynamic>;
      final decoded = CinematicStageContext.fromJson(json);
      expect(decoded.stagePoints.map((p) => p.id).toList(), ['point_a', 'point_b']);
    });
  });
}
