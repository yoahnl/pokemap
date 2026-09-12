import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/presentation_renderer.dart';

void main() {
  test('gives MP4 blobs a typed file until decoder disposal', () async {
    final directory = await Directory.systemTemp.createTemp('video-blob-test-');
    addTearDown(() => directory.delete(recursive: true));
    final bytes = <int>[0, 0, 0, 24, ...'ftypisom'.codeUnits, 0, 0, 2, 0];
    final original =
        await File('${directory.path}/video.blob').writeAsBytes(bytes);
    Uri? decoderSource;
    final driver = VideoPlayerPresentationPlaybackDriver(
      controllerFactory: (source) {
        decoderSource = source;
        return _RecordingController();
      },
    );

    final handle = await driver.prepare(original.uri, initialVolume: 0);

    expect(decoderSource, isNot(original.uri));
    expect(decoderSource!.path, endsWith('.mp4'));
    final decoderFile = File.fromUri(decoderSource!);
    expect(await decoderFile.readAsBytes(), bytes);
    await driver.dispose(handle);
    expect(await decoderFile.exists(), isFalse);
    expect(await decoderFile.parent.exists(), isFalse);
    expect(await original.readAsBytes(), bytes);
  });

  test('cleans materialized video when decoder preparation fails', () async {
    final directory = await Directory.systemTemp.createTemp('video-blob-test-');
    addTearDown(() => directory.delete(recursive: true));
    final original = await File('${directory.path}/video.blob').writeAsBytes(
      <int>[0, 0, 0, 24, ...'ftypmp42'.codeUnits, 0, 0, 0, 0],
    );
    Uri? decoderSource;
    final driver = VideoPlayerPresentationPlaybackDriver(
      controllerFactory: (source) {
        decoderSource = source;
        return _RecordingController()..failVolume = true;
      },
    );

    await expectLater(
        driver.prepare(original.uri, initialVolume: 0), throwsStateError);

    expect(decoderSource!.path, endsWith('.mp4'));
    expect(await File.fromUri(decoderSource!).parent.exists(), isFalse);
    expect(await original.exists(), isTrue);
    expect(driver.activeDecoderCount, 0);
  });

  test('does not disguise an unrecognized blob as MP4', () async {
    final directory = await Directory.systemTemp.createTemp('video-blob-test-');
    addTearDown(() => directory.delete(recursive: true));
    final original = await File('${directory.path}/video.blob').writeAsBytes(
      <int>[0x1a, 0x45, 0xdf, 0xa3, ...'webm'.codeUnits],
    );
    Uri? decoderSource;
    final driver = VideoPlayerPresentationPlaybackDriver(
      controllerFactory: (source) {
        decoderSource = source;
        return _RecordingController();
      },
    );

    final handle = await driver.prepare(original.uri, initialVolume: 0);

    expect(decoderSource, original.uri);
    await driver.dispose(handle);
    expect(await original.exists(), isTrue);
  });

  test('cleans materialized video when the controller factory throws',
      () async {
    final directory = await Directory.systemTemp.createTemp('video-blob-test-');
    addTearDown(() => directory.delete(recursive: true));
    final original = await File('${directory.path}/video.blob').writeAsBytes(
      <int>[0, 0, 0, 24, ...'ftypisom'.codeUnits, 0, 0, 0, 0],
    );
    Uri? decoderSource;
    final driver = VideoPlayerPresentationPlaybackDriver(
      controllerFactory: (source) {
        decoderSource = source;
        throw StateError('factory failed');
      },
    );

    await expectLater(
      driver.prepare(original.uri, initialVolume: 0),
      throwsStateError,
    );

    expect(await File.fromUri(decoderSource!).parent.exists(), isFalse);
    expect(await original.exists(), isTrue);
  });

  test('cleans materialized video even if decoder disposal fails', () async {
    final directory = await Directory.systemTemp.createTemp('video-blob-test-');
    addTearDown(() => directory.delete(recursive: true));
    final original = await File('${directory.path}/video.blob').writeAsBytes(
      <int>[0, 0, 0, 24, ...'ftypisom'.codeUnits, 0, 0, 0, 0],
    );
    Uri? decoderSource;
    final driver = VideoPlayerPresentationPlaybackDriver(
      controllerFactory: (source) {
        decoderSource = source;
        return _RecordingController()..failDispose = true;
      },
    );
    final handle = await driver.prepare(original.uri, initialVolume: 0);

    await expectLater(driver.dispose(handle), throwsStateError);

    expect(await File.fromUri(decoderSource!).parent.exists(), isFalse);
    expect(driver.activeDecoderCount, 0);
    expect(await original.exists(), isTrue);
  });

  test('disposal preserves another decoder using the same blob', () async {
    final directory = await Directory.systemTemp.createTemp('video-blob-test-');
    addTearDown(() => directory.delete(recursive: true));
    final original = await File('${directory.path}/video.blob').writeAsBytes(
      <int>[0, 0, 0, 24, ...'ftypisom'.codeUnits, 0, 0, 0, 0],
    );
    final decoderSources = <Uri>[];
    final driver = VideoPlayerPresentationPlaybackDriver(
      controllerFactory: (source) {
        decoderSources.add(source);
        return _RecordingController();
      },
    );
    final first = await driver.prepare(original.uri, initialVolume: 0);
    final second = await driver.prepare(original.uri, initialVolume: 0);

    await driver.dispose(first);

    expect(decoderSources[0], isNot(decoderSources[1]));
    expect(await File.fromUri(decoderSources[0]).exists(), isFalse);
    expect(await File.fromUri(decoderSources[1]).exists(), isTrue);
    await driver.dispose(second);
    expect(await File.fromUri(decoderSources[1]).exists(), isFalse);
    expect(await original.exists(), isTrue);
  });

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
    await driver.pause(handle);
    await driver.setVolume(handle, 0.1);

    expect(controller.events,
        ['initialize', 'volume:0.2', 'play', 'pause', 'volume:0.1']);
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
  bool failDispose = false;

  @override
  Widget buildVideo() => const ColoredBox(color: Colors.black);

  @override
  Future<void> dispose() async {
    events.add('dispose');
    if (failDispose) throw StateError('dispose failed');
  }

  @override
  Future<void> initialize() async => events.add('initialize');

  @override
  Future<void> play() async => events.add('play');

  @override
  Future<void> pause() async => events.add('pause');

  @override
  Future<void> seek(Duration position) async =>
      events.add('seek:${position.inMicroseconds}');

  @override
  Future<void> setVolume(double volume) async {
    events.add('volume:$volume');
    if (failVolume) throw StateError('volume failed');
  }
}
