import 'package:flutter/widgets.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:video_player/video_player.dart';

import 'player_intro_video_controller.dart';

abstract interface class PresentationVideoController {
  Widget buildVideo();

  Future<void> initialize();

  Future<void> setVolume(double volume);

  Future<void> play();

  Future<void> pause();

  Future<void> dispose();
}

typedef PresentationVideoControllerFactory = PresentationVideoController
    Function(Uri source);

final class VideoPlayerPresentationPlaybackDriver
    implements RuntimePresentationVideoPlaybackDriver {
  VideoPlayerPresentationPlaybackDriver({
    PresentationVideoControllerFactory? controllerFactory,
  }) : _controllerFactory =
            controllerFactory ?? _VideoPlayerPresentationController.new;

  final PresentationVideoControllerFactory _controllerFactory;
  final Map<Object, PresentationVideoController> _controllers =
      <Object, PresentationVideoController>{};

  int get activeDecoderCount => _controllers.length;

  @override
  Future<Object> prepare(
    Uri source, {
    required double initialVolume,
  }) async {
    final controller = _controllerFactory(source);
    try {
      await controller.initialize();
      await controller.setVolume(initialVolume);
    } on Object {
      await controller.dispose();
      rethrow;
    }
    final handle = Object();
    _controllers[handle] = controller;
    return handle;
  }

  @override
  Future<void> play(Object handle) => _require(handle).play();

  @override
  Future<void> pause(Object handle) => _require(handle).pause();

  @override
  Future<void> setVolume(Object handle, double volume) =>
      _require(handle).setVolume(volume);

  Widget buildVideo(Object handle) => _require(handle).buildVideo();

  @override
  Future<void> dispose(Object handle) async {
    final controller = _controllers.remove(handle);
    if (controller != null) await controller.dispose();
  }

  PresentationVideoController _require(Object handle) {
    final controller = _controllers[handle];
    if (controller == null) {
      throw StateError('Presentation video decoder is unavailable.');
    }
    return controller;
  }
}

final class _VideoPlayerPresentationController
    implements PresentationVideoController {
  _VideoPlayerPresentationController(Uri source)
      : _controller = createPlayerIntroVideoController(source);

  final VideoPlayerController _controller;

  @override
  Widget buildVideo() => VideoPlayer(_controller);

  @override
  Future<void> initialize() => _controller.initialize();

  @override
  Future<void> setVolume(double volume) => _controller.setVolume(volume);

  @override
  Future<void> play() => _controller.play();

  @override
  Future<void> pause() => _controller.pause();

  @override
  Future<void> dispose() => _controller.dispose();
}
