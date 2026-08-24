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

  /// Moves the decoder to [position].
  ///
  /// The runtime never seeks — it plays a cinematic straight through. A
  /// montage does nothing else: the author scrubs, steps and restarts, and
  /// the picture has to follow the playhead.
  Future<void> seek(Duration position);

  Future<void> dispose();
}

typedef PresentationVideoControllerFactory = PresentationVideoController
    Function(Uri source);

/// A video decoder a montage can drive: the runtime contract plus the seek and
/// the widget the Studio needs to show the picture where the playhead is.
abstract interface class PresentationStudioVideoPlayback {
  Future<Object> prepare(Uri source, {required double initialVolume});

  Future<void> play(Object handle);

  Future<void> pause(Object handle);

  Future<void> seek(Object handle, Duration position);

  Future<void> setVolume(Object handle, double volume);

  Widget buildVideo(Object handle);

  Future<void> dispose(Object handle);
}

final class VideoPlayerPresentationPlaybackDriver
    implements
        RuntimePresentationVideoPlaybackDriver,
        PresentationStudioVideoPlayback {
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

  @override
  Future<void> seek(Object handle, Duration position) =>
      _require(handle).seek(position);

  @override
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
  Future<void> seek(Duration position) => _controller.seekTo(position);

  @override
  Future<void> dispose() => _controller.dispose();
}
