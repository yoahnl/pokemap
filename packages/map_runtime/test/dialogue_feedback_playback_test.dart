import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/dialogue_feedback_playback_port.dart';
import 'package:map_runtime/src/application/runtime_manifest_tilesets.dart';
import 'package:map_runtime/src/presentation/flame/flame_cinematic_media_playback_adapter.dart';
import 'package:map_runtime/src/presentation/flame/flame_dialogue_feedback_playback_adapter.dart';

void main() {
  test('applies the cue gain to playback and mixer registration', () async {
    final driver = _Driver();
    final player = _player(driver);
    await player.playCue(
      DialogueAudioCue(mediaAssetId: 'fanfare', cueId: 'item', volume: 0.8),
      playbackId: 'gain',
    );
    expect(driver.volumes, [0.8, 0.8]);
    await player.dispose();
    await driver.completed.close();
  });
  test('keeps a non-looping cue alive until natural completion', () async {
    final driver = _Driver();
    final player = _player(driver);
    await player.playCue(_cue(), playbackId: 'dialogue:item');
    await player.playCue(_cue(), playbackId: 'dialogue:item');
    expect(driver.paths, ['assets/item.ogg']);
    expect(driver.loops, [false]);
    expect(driver.stopped, isEmpty);
    driver.completed.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(driver.stopped, [driver.handle]);
    await player.dispose();
    expect(driver.stopped, hasLength(1));
    await driver.completed.close();
  });

  test('observes completion while mixer registration is pending', () async {
    final driver = _Driver()..volumeGate = Completer<void>();
    final player = _player(driver);
    final starting = player.playCue(_cue(), playbackId: 'dialogue:item');
    await driver.volumeEntered.future;
    driver.completed.add(null);
    await Future<void>.delayed(Duration.zero);
    driver.volumeGate!.complete();
    await starting;
    expect(driver.stopped, [driver.handle]);
    await player.dispose();
    await driver.completed.close();
  });

  test('shares a pending cue and releases a late handle on shutdown', () async {
    final driver = _Driver()..playGate = Completer<Object>();
    final player = _player(driver);
    final first = player.playCue(_cue(), playbackId: 'dialogue:item');
    final second = player.playCue(_cue(), playbackId: 'dialogue:item');
    final closing = player.dispose();
    driver.playGate!.complete(driver.handle);
    await Future.wait([first, second, closing]);
    expect(driver.paths, hasLength(1));
    expect(driver.stopped, [driver.handle]);
    await expectLater(
      player.playCue(_cue(), playbackId: 'later'),
      throwsStateError,
    );
    await driver.completed.close();
  });

  test(
    'rejects unknown, looping and non-sound media before playback',
    () async {
      for (final assets in [
        <CinematicMediaAsset>[],
        [_asset(loop: true)],
        [_asset(kind: CinematicMediaAssetKind.music)],
      ]) {
        final driver = _Driver();
        final player = _player(driver, assets: assets);
        await expectLater(
          player.playCue(_cue(), playbackId: 'dialogue:item'),
          throwsStateError,
        );
        expect(driver.paths, isEmpty);
        await player.dispose();
        await driver.completed.close();
      }
    },
  );

  test(
    'loads exact PNG bytes only from a registered regular project file',
    () async {
      final root = await Directory.systemTemp.createTemp('dialogue-icon-');
      addTearDown(() => root.delete(recursive: true));
      final file = File('${root.path}/icon.png');
      final bytes = _png();
      await file.writeAsBytes(bytes);
      final loader = ProjectDialogueIconLoader(
        projectRoot: root.path,
        absolutePathsByAssetId: {'pocket': file.path},
      );
      final actual = await loader.load('pocket');
      expect(actual, bytes);
      expect(() => actual[0] = 0, throwsUnsupportedError);
      await expectLater(loader.load('unknown'), throwsStateError);
      final link = Link('${root.path}/linked.png');
      await link.create(file.path);
      await expectLater(
        ProjectDialogueIconLoader(
          projectRoot: root.path,
          absolutePathsByAssetId: {'linked': link.path},
        ).load('linked'),
        throwsStateError,
      );
      expect(
        () => resolveDialogueFeedbackProjectFile(root.path, '../outside.png'),
        throwsStateError,
      );
    },
  );

  test(
    'resolves an explicitly referenced icon without placing it on the map',
    () {
      final project = ProjectManifest(
        name: 'Feedback',
        maps: [],
        tilesets: const [
          ProjectTilesetEntry(
            id: 'pocket',
            name: 'Pocket',
            relativePath: 'pocket.png',
          ),
          ProjectTilesetEntry(
            id: 'unused',
            name: 'Unused',
            relativePath: 'unused.png',
          ),
        ],
        scenes: [
          SceneAsset(
            id: 'pickup',
            name: 'Pickup',
            graph: SceneGraph(
              startNodeId: 'start',
              nodes: [
                SceneNode(id: 'start', kind: SceneNodeKind.start),
                SceneNode(
                  id: 'line',
                  kind: SceneNodeKind.yarnDialogue,
                  payload: SceneYarnDialoguePayload(
                    dialogueId: 'pickup',
                    linePolicies: [
                      SceneDialogueLinePolicy(
                        nodeName: 'Start',
                        lineIndex: 1,
                        feedback: DialogueLineFeedback(
                          segments: [
                            DialogueIconSegment(
                              assetId: 'pocket',
                              widthPx: 16,
                              heightPx: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              edges: [],
            ),
          ),
        ],
      );
      const map = MapData(
        id: 'route',
        name: 'Route',
        size: GridSize(width: 1, height: 1),
      );
      expect(collectAllRuntimeTilesetIds(map, project), {'pocket'});
    },
  );

  test('rejects malformed and oversized PNG headers before decoding', () {
    expect(() => validateDialogueIconPng(Uint8List(33)), throwsStateError);
    final tooWide = _png();
    ByteData.sublistView(tooWide).setUint32(16, 257);
    expect(() => validateDialogueIconPng(tooWide), throwsStateError);
    final empty = _png();
    ByteData.sublistView(empty).setUint32(20, 0);
    expect(() => validateDialogueIconPng(empty), throwsStateError);
    expect(() => validateDialogueIconPng(Uint8List(4194305)), throwsStateError);
  });
}

FlameDialogueFeedbackPlaybackAdapter _player(
  _Driver driver, {
  List<CinematicMediaAsset>? assets,
}) => FlameDialogueFeedbackPlaybackAdapter(
  mediaAssets: assets ?? [_asset()],
  resolvePath: (asset) => asset.relativePath,
  audioDriver: driver,
);

CinematicMediaAsset _asset({
  bool loop = false,
  CinematicMediaAssetKind kind = CinematicMediaAssetKind.sound,
}) => CinematicMediaAsset(
  id: 'fanfare',
  label: 'Item',
  kind: kind,
  relativePath: 'assets/item.ogg',
  loopByDefault: loop,
);

DialogueAudioCue _cue() =>
    DialogueAudioCue(mediaAssetId: 'fanfare', cueId: 'item');

Uint8List _png() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aUx8AAAAASUVORK5CYII=',
);

final class _Driver
    implements FlameCinematicAudioDriver, FlameCinematicAudioLoopDriver {
  final handle = Object();
  final paths = <String>[];
  final loops = <bool>[];
  final volumes = <double>[];
  final stopped = <Object>[];
  final completed = StreamController<void>.broadcast(sync: true);
  final volumeEntered = Completer<void>();
  Completer<void>? volumeGate;
  Completer<Object>? playGate;

  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    paths.add(path);
    loops.add(loop);
    volumes.add(volume);
    return playGate?.future ?? handle;
  }

  @override
  Future<void> setVolume(Object handle, double volume) async {
    volumes.add(volume);
    if (!volumeEntered.isCompleted) volumeEntered.complete();
    await volumeGate?.future;
  }

  @override
  Future<void> stop(Object handle) async => stopped.add(handle);

  @override
  Stream<void> onComplete(Object handle) => completed.stream;

  @override
  Future<void> seekAndResume(Object handle, Duration position) async {}
}
