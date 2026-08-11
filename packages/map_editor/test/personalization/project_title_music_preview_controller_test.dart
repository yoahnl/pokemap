import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/personalization_hub.dart';

void main() {
  test(
    'title music preview toggles, tracks completion, and closes safely',
    () async {
      final driver = _AudioDriver();
      final controller = DefaultProjectTitleMusicPreviewController(
        driver: driver,
      );
      addTearDown(controller.close);
      final states = <bool>[];
      final subscription = controller.playingChanges.listen(states.add);
      addTearDown(subscription.cancel);
      final root = Directory.systemTemp.createTempSync('title-music-preview-');
      addTearDown(() => root.deleteSync(recursive: true));
      final file = File('${root.path}/theme.ogg')..writeAsBytesSync(<int>[0]);
      final alternate = File('${root.path}/alternate.ogg')
        ..writeAsBytesSync(<int>[0]);

      expect(await controller.toggle(file), isTrue);
      expect(controller.isPlaying, isTrue);
      expect(driver.playedPaths, <String>[file.path]);

      expect(await controller.toggle(alternate), isTrue);
      expect(controller.isPlaying, isTrue);
      expect(driver.stopCalls, 1);
      expect(driver.playedPaths, <String>[file.path, alternate.path]);

      expect(await controller.toggle(alternate), isFalse);
      expect(controller.isPlaying, isFalse);
      expect(driver.stopCalls, 2);

      expect(await controller.toggle(file), isTrue);
      driver.complete();
      await Future<void>.delayed(Duration.zero);
      expect(controller.isPlaying, isFalse);

      await controller.close();
      expect(driver.disposeCalls, 1);
      expect(states, <bool>[true, false, true, false]);
    },
  );
}

final class _AudioDriver implements ProjectTitleMusicAudioDriver {
  final StreamController<void> _completions =
      StreamController<void>.broadcast();
  final List<String> playedPaths = <String>[];
  int stopCalls = 0;
  int disposeCalls = 0;

  @override
  Stream<void> get onComplete => _completions.stream;

  void complete() => _completions.add(null);

  @override
  Future<void> play(String absolutePath) async {
    playedPaths.add(absolutePath);
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
    await _completions.close();
  }
}
