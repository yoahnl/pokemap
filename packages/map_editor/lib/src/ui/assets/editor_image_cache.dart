import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:path/path.dart' as p;

enum EditorImageFailureKind {
  invalidPath,
  missingFile,
  emptyFile,
  readFailed,
  decodeFailed,
  cacheDisposed,
}

class EditorImageFailure {
  const EditorImageFailure({
    required this.kind,
    required this.path,
    required this.message,
    this.cause,
  });

  final EditorImageFailureKind kind;
  final String path;
  final String message;
  final Object? cause;
}

class EditorImageLoadResult {
  const EditorImageLoadResult.success(ui.Image decodedImage)
      : image = decodedImage,
        failure = null;

  const EditorImageLoadResult.failure(EditorImageFailure loadFailure)
      : image = null,
        failure = loadFailure;

  final ui.Image? image;
  final EditorImageFailure? failure;

  bool get isSuccess => image != null;
}

class EditorImageCacheDiagnostics {
  const EditorImageCacheDiagnostics({
    required this.sessionKey,
    required this.entries,
    required this.hits,
    required this.misses,
    required this.invalidations,
    required this.missingFiles,
    required this.readFailures,
    required this.decodeFailures,
    required this.disposedImages,
    required this.isDisposed,
  });

  final String sessionKey;
  final int entries;
  final int hits;
  final int misses;
  final int invalidations;
  final int missingFiles;
  final int readFailures;
  final int decodeFailures;
  final int disposedImages;
  final bool isDisposed;
}

typedef EditorImageBytesTransform = FutureOr<Uint8List> Function(
  Uint8List bytes,
);

typedef EditorImageRetirementScheduler = void Function(
  void Function() disposeImage,
);

class EditorImageCache {
  EditorImageCache({
    required this.sessionKey,
    EditorImageRetirementScheduler? retirementScheduler,
  }) : _scheduleRetirement = retirementScheduler ?? _scheduleAfterConsumerFrame;

  final String sessionKey;
  final EditorImageRetirementScheduler _scheduleRetirement;

  final Map<_EditorImageSlot, _EditorImageCacheEntry> _entries =
      <_EditorImageSlot, _EditorImageCacheEntry>{};
  final Expando<bool> _disposedImageIdentities =
      Expando<bool>('disposed editor image');

  var _hits = 0;
  var _misses = 0;
  var _invalidations = 0;
  var _missingFiles = 0;
  var _readFailures = 0;
  var _decodeFailures = 0;
  var _disposedImages = 0;
  var _disposed = false;

  EditorImageCacheDiagnostics get diagnostics => EditorImageCacheDiagnostics(
        sessionKey: sessionKey,
        entries: _entries.length,
        hits: _hits,
        misses: _misses,
        invalidations: _invalidations,
        missingFiles: _missingFiles,
        readFailures: _readFailures,
        decodeFailures: _decodeFailures,
        disposedImages: _disposedImages,
        isDisposed: _disposed,
      );

  Future<EditorImageLoadResult> load(
    String? path, {
    String variantKey = 'original',
    int? targetWidth,
    int? targetHeight,
    bool allowUpscaling = true,
    EditorImageBytesTransform? transformBytes,
  }) async {
    final rawPath = path?.trim() ?? '';
    if (_disposed) {
      return EditorImageLoadResult.failure(
        EditorImageFailure(
          kind: EditorImageFailureKind.cacheDisposed,
          path: rawPath,
          message: 'The image cache for this project session is closed.',
        ),
      );
    }
    if (rawPath.isEmpty) {
      _misses += 1;
      return const EditorImageLoadResult.failure(
        EditorImageFailure(
          kind: EditorImageFailureKind.invalidPath,
          path: '',
          message: 'No image path was provided.',
        ),
      );
    }

    final unresolvedFile = File(rawPath).absolute;
    if (!await unresolvedFile.exists()) {
      _misses += 1;
      _missingFiles += 1;
      return EditorImageLoadResult.failure(
        EditorImageFailure(
          kind: EditorImageFailureKind.missingFile,
          path: p.normalize(unresolvedFile.path),
          message: 'The image file does not exist.',
        ),
      );
    }

    late final String canonicalPath;
    late final FileStat stat;
    try {
      canonicalPath = p.normalize(
        await unresolvedFile.resolveSymbolicLinks(),
      );
      stat = await File(canonicalPath).stat();
    } on Object catch (error) {
      _misses += 1;
      _readFailures += 1;
      return EditorImageLoadResult.failure(
        EditorImageFailure(
          kind: EditorImageFailureKind.readFailed,
          path: p.normalize(unresolvedFile.path),
          message: 'The image file metadata could not be read.',
          cause: error,
        ),
      );
    }

    final slot = _EditorImageSlot(
      canonicalPath: canonicalPath,
      variantKey: variantKey,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      allowUpscaling: allowUpscaling,
    );
    final fingerprint = _EditorImageFingerprint(
      byteLength: stat.size,
      modifiedMicros: stat.modified.microsecondsSinceEpoch,
    );
    final current = _entries[slot];
    if (current != null && current.fingerprint == fingerprint) {
      _hits += 1;
      return current.future;
    }

    _misses += 1;
    if (current != null) {
      _invalidations += 1;
      _retire(current.future);
    }

    late final Future<EditorImageLoadResult> future;
    future = _decode(
      canonicalPath,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      allowUpscaling: allowUpscaling,
      transformBytes: transformBytes,
    );
    _entries[slot] = _EditorImageCacheEntry(
      fingerprint: fingerprint,
      future: future,
    );
    unawaited(
      future.then((result) {
        if (result.failure != null &&
            identical(_entries[slot]?.future, future)) {
          _entries.remove(slot);
        }
        if (_disposed && result.image != null) {
          _scheduleImageDisposal(result.image!);
        }
      }),
    );
    return future;
  }

  Future<Map<String, EditorImageLoadResult>> loadMany(
    Map<String, String> paths, {
    String Function(String id)? variantKeyForId,
    int? targetWidth,
    int? targetHeight,
    bool allowUpscaling = true,
    EditorImageBytesTransform? Function(String id)? transformForId,
  }) async {
    final entries = await Future.wait(
      paths.entries.map((entry) async {
        final result = await load(
          entry.value,
          variantKey: variantKeyForId?.call(entry.key) ?? 'original',
          targetWidth: targetWidth,
          targetHeight: targetHeight,
          allowUpscaling: allowUpscaling,
          transformBytes: transformForId?.call(entry.key),
        );
        return MapEntry<String, EditorImageLoadResult>(entry.key, result);
      }),
    );
    return Map<String, EditorImageLoadResult>.fromEntries(entries);
  }

  Future<void> invalidate(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty || _disposed) return;
    final file = File(trimmed).absolute;
    String canonicalPath;
    try {
      canonicalPath = p.normalize(await file.resolveSymbolicLinks());
    } on Object {
      canonicalPath = p.normalize(file.path);
    }
    final matchingSlots = _entries.keys
        .where((slot) => slot.canonicalPath == canonicalPath)
        .toList(growable: false);
    for (final slot in matchingSlots) {
      final entry = _entries.remove(slot);
      if (entry != null) {
        _invalidations += 1;
        _retire(entry.future);
      }
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final ownedFutures = <Future<EditorImageLoadResult>>{
      ..._entries.values.map((entry) => entry.future),
    };
    _entries.clear();
    for (final future in ownedFutures) {
      unawaited(
        future.then((result) {
          final image = result.image;
          if (image != null) {
            _scheduleImageDisposal(image);
          }
        }),
      );
    }
  }

  Future<EditorImageLoadResult> _decode(
    String canonicalPath, {
    required int? targetWidth,
    required int? targetHeight,
    required bool allowUpscaling,
    required EditorImageBytesTransform? transformBytes,
  }) async {
    Uint8List bytes;
    try {
      bytes = await File(canonicalPath).readAsBytes();
      if (bytes.isEmpty) {
        _readFailures += 1;
        return EditorImageLoadResult.failure(
          EditorImageFailure(
            kind: EditorImageFailureKind.emptyFile,
            path: canonicalPath,
            message: 'The image file is empty.',
          ),
        );
      }
      if (transformBytes != null) {
        bytes = await transformBytes(bytes);
      }
    } on Object catch (error) {
      _readFailures += 1;
      return EditorImageLoadResult.failure(
        EditorImageFailure(
          kind: EditorImageFailureKind.readFailed,
          path: canonicalPath,
          message: 'The image bytes could not be read.',
          cause: error,
        ),
      );
    }

    ui.Codec? codec;
    try {
      codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        allowUpscaling: allowUpscaling,
      );
      final frame = await codec.getNextFrame();
      if (_disposed) {
        _disposeImage(frame.image);
        return EditorImageLoadResult.failure(
          EditorImageFailure(
            kind: EditorImageFailureKind.cacheDisposed,
            path: canonicalPath,
            message: 'The project session closed while the image was loading.',
          ),
        );
      }
      return EditorImageLoadResult.success(frame.image);
    } on Object catch (error) {
      _decodeFailures += 1;
      return EditorImageLoadResult.failure(
        EditorImageFailure(
          kind: EditorImageFailureKind.decodeFailed,
          path: canonicalPath,
          message: 'The image file could not be decoded.',
          cause: error,
        ),
      );
    } finally {
      codec?.dispose();
    }
  }

  void _disposeImage(ui.Image image) {
    if (_disposedImageIdentities[image] == true) return;
    _disposedImageIdentities[image] = true;
    image.dispose();
    _disposedImages += 1;
  }

  void _retire(Future<EditorImageLoadResult> future) {
    unawaited(
      future.then((result) {
        final image = result.image;
        if (image == null) return;
        _scheduleImageDisposal(image);
      }),
    );
  }

  void _scheduleImageDisposal(ui.Image image) {
    _scheduleRetirement(() => _disposeImage(image));
  }

  static void _scheduleAfterConsumerFrame(void Function() disposeImage) {
    final scheduler = SchedulerBinding.instance;
    scheduler.addPostFrameCallback((_) => disposeImage());
    scheduler.ensureVisualUpdate();
  }
}

class _EditorImageSlot {
  const _EditorImageSlot({
    required this.canonicalPath,
    required this.variantKey,
    required this.targetWidth,
    required this.targetHeight,
    required this.allowUpscaling,
  });

  final String canonicalPath;
  final String variantKey;
  final int? targetWidth;
  final int? targetHeight;
  final bool allowUpscaling;

  @override
  bool operator ==(Object other) {
    return other is _EditorImageSlot &&
        other.canonicalPath == canonicalPath &&
        other.variantKey == variantKey &&
        other.targetWidth == targetWidth &&
        other.targetHeight == targetHeight &&
        other.allowUpscaling == allowUpscaling;
  }

  @override
  int get hashCode => Object.hash(
        canonicalPath,
        variantKey,
        targetWidth,
        targetHeight,
        allowUpscaling,
      );
}

class _EditorImageFingerprint {
  const _EditorImageFingerprint({
    required this.byteLength,
    required this.modifiedMicros,
  });

  final int byteLength;
  final int modifiedMicros;

  @override
  bool operator ==(Object other) {
    return other is _EditorImageFingerprint &&
        other.byteLength == byteLength &&
        other.modifiedMicros == modifiedMicros;
  }

  @override
  int get hashCode => Object.hash(byteLength, modifiedMicros);
}

class _EditorImageCacheEntry {
  const _EditorImageCacheEntry({
    required this.fingerprint,
    required this.future,
  });

  final _EditorImageFingerprint fingerprint;
  final Future<EditorImageLoadResult> future;
}
