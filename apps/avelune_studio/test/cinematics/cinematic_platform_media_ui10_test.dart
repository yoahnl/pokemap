import 'dart:io';

import 'package:avelune_studio/platform/rendering/studio_cinematic_media.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test(
    'runtime adapter resolves a real local media and releases its driver on restore',
    () async {
      final root = await Directory.systemTemp.createTemp('ui10_audio_');
      addTearDown(() => root.delete(recursive: true));
      final file = await File('${root.path}/fixture.wav').writeAsBytes([0, 1]);
      final driver = _AudioDriver();
      final adapter = StudioCinematicMedia(
        projectRoot: root.path,
        assets: [_asset('fixture.wav')],
        audioDriver: driver,
      );
      final checkpoint = await adapter.captureCheckpoint();
      await adapter.execute(_play());
      expect(driver.paths, [await file.resolveSymbolicLinks()]);
      expect(driver.active, 1);
      await adapter.restore(checkpoint);
      expect(driver.active, 0);
    },
  );

  test(
    'outside symlink and missing media fail before starting any driver',
    () async {
      final root = await Directory.systemTemp.createTemp('ui10_audio_root_');
      final outside = await Directory.systemTemp.createTemp(
        'ui10_audio_outside_',
      );
      addTearDown(() => root.delete(recursive: true));
      addTearDown(() => outside.delete(recursive: true));
      final file = await File('${outside.path}/foreign.wav').writeAsBytes([0]);
      await Link('${root.path}/escape.wav').create(file.path);
      final driver = _AudioDriver();
      for (final relative in ['escape.wav', 'missing.wav', '../foreign.wav']) {
        final adapter = StudioCinematicMedia(
          projectRoot: root.path,
          assets: [_asset(relative)],
          audioDriver: driver,
        );
        await expectLater(adapter.execute(_play()), throwsA(anything));
      }
      expect(driver.paths, isEmpty);
    },
  );

  test(
    'unavailable FX host rejects its capability instead of silently accepting',
    () async {
      final adapter = StudioCinematicMedia(projectRoot: '/unused', assets: []);
      await expectLater(
        adapter.execute(
          CinematicMediaPlaybackCommand.spawnFx(
            commandId: 'fx',
            assetId: 'sparkles',
            channel: 'fx',
            durationMs: 100,
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'reason',
            contains('runtime'),
          ),
        ),
      );
    },
  );
}

CinematicMediaAsset _asset(String path) => CinematicMediaAsset(
  id: 'audio',
  label: 'Fixture',
  kind: CinematicMediaAssetKind.sound,
  relativePath: path,
);
CinematicMediaPlaybackCommand _play() => CinematicMediaPlaybackCommand.play(
  commandId: 'play',
  assetId: 'audio',
  channel: 'sound',
);

class _AudioDriver implements FlameCinematicAudioDriver {
  final paths = <String>[];
  int active = 0;
  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    paths.add(path);
    active++;
    return Object();
  }

  @override
  Future<void> setVolume(Object handle, double volume) async {}
  @override
  Future<void> stop(Object handle) async {
    active--;
  }
}
