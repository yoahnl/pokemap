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
      expect(decoded.legacyBridge?.scenarioId, 'scenario_legacy_intro');
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
  });
}
