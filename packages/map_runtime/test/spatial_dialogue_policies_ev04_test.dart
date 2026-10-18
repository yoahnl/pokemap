import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/spatial/spatial_exploration_session.dart';
import 'package:map_runtime/src/application/dialogue_feedback_playback_port.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('spatial dialogue plays authored feedback exactly once through its native port', () async {
    final session = await _session(line: true);
    addTearDown(session.dispose);
    final audio = _Audio();
    session.dialogueFeedbackPlaybackPort = audio;
    final result = session.showDialogue(
      const DialogueRef(dialogueId: 'hello'),
      linePolicies: [
        SceneDialogueLinePolicy(
          nodeName: 'Start',
          lineIndex: 0,
          feedback: DialogueLineFeedback(
            segments: [DialogueTextSegment('Bonjour')],
            audioCue: DialogueAudioCue(mediaAssetId: 'sound', cueId: 'hello'),
          ),
        ),
      ],
    );
    await _until(() => session.dialoguePresentation.value != null);
    expect(audio.calls, ['hello']);
    session.confirmDialogue();
    expect((await result.timeout(const Duration(seconds: 2))).success, isTrue);
    expect(audio.calls, ['hello']);
  });

  for (final cancellation in const [
    SceneDialogueChoiceCancellation.disabled(),
    SceneDialogueChoiceCancellation.choice('no'),
    SceneDialogueChoiceCancellation.branch('cancel'),
  ]) {
    test(
      'spatial dialogue applies ${cancellation.kind.name} cancellation',
      () async {
        final session = await _session();
        addTearDown(session.dispose);
        final result = session.showDialogue(
          const DialogueRef(dialogueId: 'hello'),
          choicePolicies: [
            SceneDialogueChoicePolicy(
              nodeName: 'Start',
              defaultOutcomeId: 'no',
              cancellation: cancellation,
            ),
          ],
        );
        await _until(() => session.dialoguePresentation.value != null);
        expect(
          session.dialoguePresentation.value!.choices.last.selected,
          isTrue,
        );
        session.cancelDialogue();
        if (cancellation.kind == SceneDialogueChoiceCancellationKind.disabled) {
          expect(session.dialoguePresentation.value, isNotNull);
          session.confirmDialogue();
        }
        final outcome = await result.timeout(const Duration(seconds: 2));
        expect(outcome.success, isTrue);
        expect(
          outcome.outcomeId,
          cancellation.kind == SceneDialogueChoiceCancellationKind.branch
              ? 'cancel'
              : 'no',
        );
        expect(session.dialoguePresentation.value, isNull);
      },
    );
  }

  test(
    'spatial dialogue applies line feedback before displaying and advancing',
    () async {
      final session = await _session(line: true);
      addTearDown(session.dispose);
      final feedback = DialogueLineFeedback(
        segments: [
          DialogueTextSegment(
            'Bonjour',
            style: DialogueSegmentStyle(colorArgb: 0xff3050c8),
          ),
        ],
        revealIntervalMicros: 0,
        advance: DialogueLineAdvancePolicy.autoAfterReveal(100000),
      );
      final result = session.showDialogue(
        const DialogueRef(dialogueId: 'hello'),
        linePolicies: [
          SceneDialogueLinePolicy(
            nodeName: 'Start',
            lineIndex: 0,
            feedback: feedback,
          ),
        ],
      );
      await _until(() => session.dialoguePresentation.value != null);
      expect(session.dialoguePresentation.value!.segments, feedback.segments);
      expect(session.dialoguePresentation.value!.isAdvanceAvailable, isFalse);
      session.confirmDialogue();
      expect(session.dialoguePresentation.value, isNotNull);
      session.frame(.05);
      session.frame(.05);
      session.frame(.05);
      expect(
        (await result.timeout(const Duration(seconds: 2))).success,
        isTrue,
      );
    },
  );
}

Future<void> _until(bool Function() condition) async {
  for (var i = 0; i < 200 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(condition(), isTrue);
}

Future<SpatialExplorationSession> _session({bool line = false}) async {
  final root = await Directory.systemTemp.createTemp('ev04-spatial-dialogue-');
  addTearDown(() => root.delete(recursive: true));
  final path = '${root.path}/hero.png';
  await File(path)
      .writeAsBytes(image.encodePng(image.Image(width: 32, height: 32)));
  await File('${root.path}/hello.yarn').writeAsString(
    line
        ? '''
title: Start
---
Bonjour
===
'''
        : '''
title: Start
---
-> Oui
    <<outcome yes>>
-> Non
    <<outcome no>>
===
''',
  );
  final character = ProjectCharacterEntry(
    id: 'hero',
    name: 'Hero',
    tilesetId: 'unused',
    animations: [
      for (final direction in EntityFacing.values)
        CharacterAnimation(
          state: CharacterAnimationState.walk,
          direction: direction,
          sourceAssetId: 'hero',
          frames: const [
            CharacterAnimationFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 32),
              durationMs: 100,
            ),
          ],
        ),
    ],
  );
  return SpatialExplorationSession.load(
    RuntimeMapBundle(
      manifest: ProjectManifest(
        version: ProjectVersion.v9,
        name: 'EV04',
        settings: const ProjectSettings(
          dimension: ProjectDimension.threeD,
          defaultPlayerCharacterId: 'hero',
        ),
        maps: const [],
        tilesets: const [],
        characters: [character],
        cinematicMediaAssets: [
          CinematicMediaAsset(
            id: 'sound',
            label: 'Sound',
            kind: CinematicMediaAssetKind.sound,
            relativePath: 'sound.wav',
          ),
        ],
        dialogues: const [
          ProjectDialogueEntry(
            id: 'hello',
            name: 'Hello',
            relativePath: 'hello.yarn',
          ),
        ],
      ),
      map: MapData(
        version: ProjectVersion.v9,
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 8, height: 8),
        spatialScene: MapSpatialScene(
          width: 8,
          depth: 8,
          navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 4, z: 4)),
        ),
      ),
      projectRootDirectory: root.path,
      tilesetAbsolutePathsById: const {},
      characterAnimationAbsolutePathsByAssetId: {'hero': path},
    ),
  );
}

class _Audio implements DialogueFeedbackPlaybackPort {
  final calls = <String>[];
  @override
  Future<void> playCue(
    DialogueAudioCue cue, {
    required String playbackId,
  }) async {
    calls.add(cue.cueId);
  }
}
