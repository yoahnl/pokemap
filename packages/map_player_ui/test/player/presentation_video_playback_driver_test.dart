import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/presentation_renderer.dart';

void main() {
  test('initializes and applies mixer volume before playback', () async {
    final controller = _RecordingController();
    final driver = VideoPlayerPresentationPlaybackDriver(
      controllerFactory: (_) => controller,
    );

    final handle = await driver.prepare(
      Uri.parse('file:///opening.mp4'),
      initialVolume: 0.2,
    );
    await driver.play(handle);
    await driver.setVolume(handle, 0.1);

    expect(
        controller.events, ['initialize', 'volume:0.2', 'play', 'volume:0.1']);
    expect(driver.buildVideo(handle), isA<ColoredBox>());

    await driver.dispose(handle);
    expect(controller.events.last, 'dispose');
  });

  test('disposes an allocated controller when preparation fails', () async {
    final controller = _RecordingController()..failVolume = true;
    final driver = VideoPlayerPresentationPlaybackDriver(
      controllerFactory: (_) => controller,
    );

    await expectLater(
      driver.prepare(Uri.parse('file:///opening.mp4'), initialVolume: 0),
      throwsStateError,
    );

    expect(controller.events, ['initialize', 'volume:0.0', 'dispose']);
    expect(driver.activeDecoderCount, 0);
  });
}

final class _RecordingController implements PresentationVideoController {
  final events = <String>[];
  bool failVolume = false;

  @override
  Widget buildVideo() => const ColoredBox(color: Colors.black);

  @override
  Future<void> dispose() async => events.add('dispose');

  @override
  Future<void> initialize() async => events.add('initialize');

  @override
  Future<void> play() async => events.add('play');

  @override
  Future<void> setVolume(double volume) async {
    events.add('volume:$volume');
    if (failVolume) throw StateError('volume failed');
  }
}
