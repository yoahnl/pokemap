import 'dart:async';
import 'dart:io';

import 'package:flame_audio/flame_audio.dart';

abstract interface class ProjectTitleMusicAudioDriver {
  Stream<void> get onComplete;

  Future<void> play(String absolutePath);

  Future<void> stop();

  Future<void> dispose();
}

final class FlameProjectTitleMusicAudioDriver
    implements ProjectTitleMusicAudioDriver {
  FlameProjectTitleMusicAudioDriver({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<void> get onComplete => _player.onPlayerComplete;

  @override
  Future<void> play(String absolutePath) async {
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.play(
      DeviceFileSource(absolutePath),
      mode: PlayerMode.mediaPlayer,
    );
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

abstract interface class ProjectTitleMusicPreviewController {
  bool get isPlaying;

  Stream<bool> get playingChanges;

  Future<bool> toggle(File file);

  Future<void> stop();

  Future<void> close();
}

final class DefaultProjectTitleMusicPreviewController
    implements ProjectTitleMusicPreviewController {
  DefaultProjectTitleMusicPreviewController({
    ProjectTitleMusicAudioDriver? driver,
  }) : _driver = driver ?? FlameProjectTitleMusicAudioDriver() {
    _completionSubscription = _driver.onComplete.listen((_) {
      _activePath = null;
      _setPlaying(false);
    });
  }

  final ProjectTitleMusicAudioDriver _driver;
  final StreamController<bool> _playingChanges =
      StreamController<bool>.broadcast();
  late final StreamSubscription<void> _completionSubscription;
  bool _isPlaying = false;
  bool _isClosed = false;
  String? _activePath;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Stream<bool> get playingChanges => _playingChanges.stream;

  @override
  Future<bool> toggle(File file) async {
    _ensureOpen();
    if (_isPlaying && _activePath == file.path) {
      await stop();
      return false;
    }
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw StateError('The title music preview file does not exist.');
    }
    if (_isPlaying) {
      await _driver.stop();
    }
    await _driver.play(file.path);
    _activePath = file.path;
    _setPlaying(true);
    return true;
  }

  @override
  Future<void> stop() async {
    _ensureOpen();
    if (!_isPlaying) return;
    await _driver.stop();
    _activePath = null;
    _setPlaying(false);
  }

  @override
  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    await _completionSubscription.cancel();
    await _driver.dispose();
    await _playingChanges.close();
    _isPlaying = false;
    _activePath = null;
  }

  void _setPlaying(bool value) {
    if (_isClosed || _isPlaying == value) return;
    _isPlaying = value;
    _playingChanges.add(value);
  }

  void _ensureOpen() {
    if (_isClosed) {
      throw StateError('The title music preview controller is closed.');
    }
  }
}
