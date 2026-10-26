import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

Future<Directory> requireStudioCaptureRoot(String configuredPath) async {
  const ownedRoots = {
    '/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/l6-catalog-qualification-20261018/captures':
        'avelune-studio-l6-catalog-capture@1',
    '/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/avelune-cs-native-20261016-143230-captures':
        'avelune-studio-native-cs-capture@1',
    '/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/Valbois-studio-capture-20261008':
        'avelune-studio-valbois2-capture@1',
    '/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/nb2-modular-qa-20261011/captures':
        'avelune-studio-modular-nb2-capture@1',
  };
  final temporaryRoot = await Directory.systemTemp.resolveSymbolicLinks();
  final temporaryCaptureParent = p.join(
    temporaryRoot,
    'avelune-studio-captures',
  );
  final temporaryRun =
      p.isAbsolute(configuredPath) &&
      p.normalize(configuredPath) == configuredPath &&
      p.dirname(configuredPath) == temporaryCaptureParent &&
      RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_-]{0,79}$')
          .hasMatch(p.basename(configuredPath));
  const qaRoots = {
    '/Users/karim/Library/Caches/AveluneQA',
    '/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Library/Caches/AveluneQA',
  };
  final qaRun =
      p.isAbsolute(configuredPath) &&
      p.normalize(configuredPath) == configuredPath &&
      p.basename(configuredPath) == 'captures' &&
      qaRoots.contains(p.dirname(p.dirname(configuredPath))) &&
      RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_-]{0,79}$')
          .hasMatch(p.basename(p.dirname(configuredPath)));
  final expectedMarker = temporaryRun || qaRun
      ? 'avelune-studio-capture@1'
      : ownedRoots[configuredPath];
  if (expectedMarker == null ||
      await FileSystemEntity.type(configuredPath, followLinks: false) !=
          FileSystemEntityType.directory ||
      await Directory(configuredPath).resolveSymbolicLinks() !=
          configuredPath) {
    throw StateError(
      'MARIONETTE_CAPTURE_ROOT must be a canonical owned run under '
      '$temporaryCaptureParent/<runid>, '
      '${qaRoots.map((root) => '$root/<task>/captures').join(', ')}, '
      'or an existing owned legacy capture root.',
    );
  }
  final marker = File(p.join(configuredPath, '.avelune-studio-capture-owner'));
  if (await FileSystemEntity.type(marker.path, followLinks: false) !=
          FileSystemEntityType.file ||
      (temporaryRun || qaRun
              ? await marker.readAsString()
              : (await marker.readAsString()).trim()) !=
          expectedMarker) {
    throw StateError('The Studio capture ownership marker is missing.');
  }
  return Directory(configuredPath);
}

final class StudioFrameRecorder {
  StudioFrameRecorder({
    required this.captureRoot,
    required this.boundaryKey,
    this.sourceMetadata = const {},
  });

  final Directory captureRoot;
  final GlobalKey boundaryKey;
  final Map<String, Object?> sourceMetadata;
  final _clock = Stopwatch();
  final _frames = <Map<String, Object?>>[];
  Timer? _timer, _limit;
  Future<void>? _pending;
  Future<Map<String, Object?>>? _stopFuture;
  Directory? _directory;
  DateTime? _startedAt, _stoppedAt;
  bool _running = false, _finishing = false, _starting = false;
  int _fps = 15, _maxDurationSeconds = 300, _dropped = 0, _errors = 0;
  String? _lastError, _stopReason;

  Map<String, Object?> get snapshot => {
    'running': _running,
    'source': sourceMetadata,
    'finishing': _finishing,
    'directory': _directory?.path,
    'metadataPath': _directory == null
        ? null
        : p.join(_directory!.path, 'metadata.json'),
    'fps': _fps,
    'maxDurationSeconds': _maxDurationSeconds,
    'pixelRatio': 1.0,
    'startedAt': _startedAt?.toIso8601String(),
    'stoppedAt': _stoppedAt?.toIso8601String(),
    'elapsedMicros': _clock.elapsedMicroseconds,
    'capturedFrames': _frames.length,
    'droppedFrames': _dropped,
    'errors': _errors,
    'lastError': _lastError,
    'stopReason': _stopReason,
  };

  Future<Map<String, Object?>> start({
    int fps = 15,
    int maxDurationSeconds = 300,
  }) async {
    if (fps < 10 ||
        fps > 20 ||
        maxDurationSeconds < 1 ||
        maxDurationSeconds > 300) {
      throw ArgumentError(
        'Capture must use 10–20 fps and last at most 300 seconds.',
      );
    }
    if (_running || _finishing || _starting) {
      throw StateError('A Studio recording is already active.');
    }
    _starting = true;
    try {
      final parent = Directory(p.join(captureRoot.path, 'recordings'));
      final type = await FileSystemEntity.type(parent.path, followLinks: false);
      if (type == FileSystemEntityType.notFound) {
        await parent.create();
      } else if (type != FileSystemEntityType.directory) {
        throw StateError(
          'The owned recording directory must not be a symlink.',
        );
      }
      if (await parent.resolveSymbolicLinks() != p.normalize(parent.path)) {
        throw StateError('The owned recording directory must be canonical.');
      }
      _directory = await parent.createTemp('take-');
      _frames.clear();
      _dropped = _errors = 0;
      _lastError = _stopReason = null;
      _fps = fps;
      _maxDurationSeconds = maxDurationSeconds;
      _startedAt = DateTime.now().toUtc();
      _stoppedAt = null;
      _stopFuture = null;
      _clock
        ..reset()
        ..start();
      _running = true;
      _pending = _captureFrame();
      await _pending;
      _pending = null;
      if (!_running) return await _stopFuture!;
      if (_frames.isEmpty) {
        await stop(reason: 'captureError');
        throw StateError(_lastError ?? 'The Studio has no painted frame.');
      }
      var previousTick = 0;
      _timer = Timer.periodic(Duration(microseconds: 1000000 ~/ fps), (timer) {
        _dropped += timer.tick - previousTick - 1;
        previousTick = timer.tick;
        if (!_running) return;
        if (_pending != null) {
          _dropped++;
          return;
        }
        _pending = _captureFrame().whenComplete(() => _pending = null);
      });
      final remaining = Duration(seconds: maxDurationSeconds) - _clock.elapsed;
      if (remaining <= Duration.zero) {
        return await stop(reason: 'durationLimit');
      }
      _limit = Timer(remaining, () {
        unawaited(
          stop(reason: 'durationLimit').catchError((Object error) {
            _errors++;
            _lastError = error.toString();
            return snapshot;
          }),
        );
      });
      return snapshot;
    } finally {
      _starting = false;
    }
  }

  Future<void> _captureFrame() async {
    ui.Image? image;
    final elapsed = _clock.elapsedMicroseconds;
    final at = DateTime.now().toUtc();
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary ||
          !boundary.hasSize ||
          boundary.size.isEmpty) {
        throw StateError('The Studio capture surface is unavailable.');
      }
      if (boundary.debugNeedsPaint) {
        _dropped++;
        return;
      }
      image = await boundary.toImage(pixelRatio: 1);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) {
        throw StateError('The painted frame could not be encoded.');
      }
      final file = 'frame_${_frames.length.toString().padLeft(6, '0')}.png';
      await File(p.join(_directory!.path, file)).writeAsBytes(
        png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
      );
      _frames.add({
        'file': file,
        'timestamp': at.toIso8601String(),
        'elapsedMicros': elapsed,
        'captureDurationMicros': _clock.elapsedMicroseconds - elapsed,
        'width': image.width,
        'height': image.height,
      });
    } on Object catch (error) {
      _errors++;
      _dropped++;
      _lastError = error.toString();
    } finally {
      image?.dispose();
    }
  }

  Future<Map<String, Object?>> stop({String reason = 'requested'}) {
    if (_stopFuture case final stopping?) return stopping;
    if (_starting && !_running) {
      return Future.error(
        StateError('The Studio recording is still preparing.'),
      );
    }
    if (!_running) return Future.value(snapshot);
    _running = false;
    _finishing = true;
    _timer?.cancel();
    _limit?.cancel();
    _stopReason = reason;
    return _stopFuture = _finish();
  }

  Future<Map<String, Object?>> _finish() async {
    try {
      await _pending;
      _clock.stop();
      _stoppedAt = DateTime.now().toUtc();
      final stoppedSnapshot = {...snapshot, 'finishing': false};
      final receipt = {
        'schemaVersion': 1,
        ...stoppedSnapshot,
        'frames': _frames,
      };
      await File(p.join(_directory!.path, 'metadata.json')).writeAsString(
        const JsonEncoder.withIndent('  ').convert(receipt),
        flush: true,
      );
      return stoppedSnapshot;
    } finally {
      _finishing = false;
    }
  }
}
