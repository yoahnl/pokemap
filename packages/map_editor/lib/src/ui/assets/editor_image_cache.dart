import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:path/path.dart' as p;

import '../../application/services/editor_performance_telemetry.dart';

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

/// A successful result owns one disposable consumer handle.
///
/// Call [dispose] when the consumer no longer paints or inspects [image].
class EditorImageLoadResult {
  EditorImageLoadResult.success(ui.Image decodedImage)
    : image = decodedImage,
      failure = null,
      _lease = _EditorImageConsumerLease();

  const EditorImageLoadResult.failure(EditorImageFailure loadFailure)
    : image = null,
      failure = loadFailure,
      _lease = null;

  final ui.Image? image;
  final EditorImageFailure? failure;
  final _EditorImageConsumerLease? _lease;

  bool get isSuccess => image != null;

  /// Releases this consumer's image handle without affecting cache masters or
  /// handles owned by other consumers.
  void release() {
    final decodedImage = image;
    if (decodedImage != null) {
      _lease?.release(decodedImage);
    }
  }

  /// Alias for [release], suitable for widget and owner lifecycle methods.
  void dispose() => release();
}

class _EditorImageConsumerLease {
  var _released = false;

  void release(ui.Image image) {
    if (_released) return;
    _released = true;
    image.dispose();
  }
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
    required this.maximumDecodedBytes,
    required this.residentDecodedBytes,
    required this.peakDecodedBytes,
    required this.evictions,
    required this.inFlightLoads,
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
  final int maximumDecodedBytes;
  final int residentDecodedBytes;
  final int peakDecodedBytes;
  final int evictions;
  final int inFlightLoads;
  final bool isDisposed;
}

typedef EditorImageBytesTransform =
    FutureOr<Uint8List> Function(Uint8List bytes);

typedef EditorImageRetirementScheduler =
    void Function(void Function() disposeImage);

class EditorImageCache {
  static const int defaultMaximumDecodedBytes = 32 * 1024 * 1024;

  EditorImageCache({
    required this.sessionKey,
    this.maximumDecodedBytes = defaultMaximumDecodedBytes,
    EditorImageRetirementScheduler? retirementScheduler,
  }) : _scheduleRetirement =
           retirementScheduler ?? _scheduleAfterConsumerFrame {
    if (maximumDecodedBytes <= 0) {
      throw ArgumentError.value(
        maximumDecodedBytes,
        'maximumDecodedBytes',
        'must be positive',
      );
    }
  }

  final String sessionKey;
  final int maximumDecodedBytes;
  final EditorImageRetirementScheduler _scheduleRetirement;

  final Map<_EditorImageSlot, _EditorImageCacheEntry> _entries =
      <_EditorImageSlot, _EditorImageCacheEntry>{};
  final Expando<bool> _disposedImageIdentities = Expando<bool>(
    'disposed editor image',
  );

  var _hits = 0;
  var _misses = 0;
  var _invalidations = 0;
  var _missingFiles = 0;
  var _readFailures = 0;
  var _decodeFailures = 0;
  var _disposedImages = 0;
  var _residentDecodedBytes = 0;
  var _peakDecodedBytes = 0;
  var _evictions = 0;
  var _inFlightLoads = 0;
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
    maximumDecodedBytes: maximumDecodedBytes,
    residentDecodedBytes: _residentDecodedBytes,
    peakDecodedBytes: _peakDecodedBytes,
    evictions: _evictions,
    inFlightLoads: _inFlightLoads,
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
    EditorPerformanceTelemetry.incrementCounter(
      EditorPerformanceCounterName.filesystemMetadata,
    );
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
      EditorPerformanceTelemetry.incrementCounter(
        EditorPerformanceCounterName.filesystemMetadata,
        by: 2,
      );
      canonicalPath = p.normalize(await unresolvedFile.resolveSymbolicLinks());
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
      _touch(slot, current);
      return _acquireConsumer(current, canonicalPath: canonicalPath);
    }

    _misses += 1;
    if (current != null) {
      _invalidations += 1;
      _removeEntry(slot, current);
    }

    final future = _decode(
      canonicalPath,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      allowUpscaling: allowUpscaling,
      transformBytes: transformBytes,
    );
    final entry = _EditorImageCacheEntry(
      fingerprint: fingerprint,
      future: future,
    );
    _entries[slot] = entry;
    _trackDecode(slot, entry);
    return _acquireConsumer(entry, canonicalPath: canonicalPath);
  }

  Future<EditorImageLoadResult> loadCrop(
    String? path, {
    required ui.Rect sourceRect,
    String variantKey = 'original',
    String sourceVariantKey = 'original',
    EditorImageBytesTransform? transformBytes,
  }) async {
    final source = await load(
      path,
      variantKey: 'crop-source:$sourceVariantKey',
      transformBytes: transformBytes,
    );
    final sourceImage = source.image;
    if (sourceImage == null) return source;

    final rawPath = path?.trim() ?? '';
    final unresolvedFile = File(rawPath).absolute;
    late final String canonicalPath;
    late final FileStat stat;
    try {
      EditorPerformanceTelemetry.incrementCounter(
        EditorPerformanceCounterName.filesystemMetadata,
        by: 2,
      );
      canonicalPath = p.normalize(await unresolvedFile.resolveSymbolicLinks());
      stat = await File(canonicalPath).stat();
    } on Object catch (error) {
      source.dispose();
      _misses++;
      _readFailures++;
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
      variantKey:
          'crop:$variantKey:'
          '${sourceRect.left},${sourceRect.top},'
          '${sourceRect.width},${sourceRect.height}',
      targetWidth: null,
      targetHeight: null,
      allowUpscaling: true,
    );
    final fingerprint = _EditorImageFingerprint(
      byteLength: stat.size,
      modifiedMicros: stat.modified.microsecondsSinceEpoch,
    );
    final current = _entries[slot];
    if (current != null && current.fingerprint == fingerprint) {
      source.dispose();
      _hits++;
      _touch(slot, current);
      return _acquireConsumer(current, canonicalPath: canonicalPath);
    }

    _misses++;
    if (current != null) {
      _invalidations++;
      _removeEntry(slot, current);
    }
    final future = _cropImage(
      sourceImage,
      sourceRect: sourceRect,
      canonicalPath: canonicalPath,
    ).whenComplete(source.dispose);
    final entry = _EditorImageCacheEntry(
      fingerprint: fingerprint,
      future: future,
    );
    _entries[slot] = entry;
    _trackDecode(slot, entry);
    return _acquireConsumer(entry, canonicalPath: canonicalPath);
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
      EditorPerformanceTelemetry.incrementCounter(
        EditorPerformanceCounterName.filesystemMetadata,
      );
      canonicalPath = p.normalize(await file.resolveSymbolicLinks());
    } on Object {
      canonicalPath = p.normalize(file.path);
    }
    final matchingSlots = _entries.keys
        .where((slot) => slot.canonicalPath == canonicalPath)
        .toList(growable: false);
    for (final slot in matchingSlots) {
      final entry = _entries[slot];
      if (entry != null) {
        _invalidations += 1;
        _removeEntry(slot, entry);
      }
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final ownedEntries = _entries.values.toSet();
    _entries.clear();
    _residentDecodedBytes = 0;
    for (final entry in ownedEntries) {
      _requestRetirement(entry);
    }
  }

  Future<_EditorImageMasterResult> _decode(
    String canonicalPath, {
    required int? targetWidth,
    required int? targetHeight,
    required bool allowUpscaling,
    required EditorImageBytesTransform? transformBytes,
  }) async {
    Uint8List bytes;
    try {
      EditorPerformanceTelemetry.incrementCounter(
        EditorPerformanceCounterName.filesystemRead,
      );
      bytes = await File(canonicalPath).readAsBytes();
      if (bytes.isEmpty) {
        _readFailures += 1;
        return _EditorImageMasterResult.failure(
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
      return _EditorImageMasterResult.failure(
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
        return _EditorImageMasterResult.failure(
          EditorImageFailure(
            kind: EditorImageFailureKind.cacheDisposed,
            path: canonicalPath,
            message: 'The project session closed while the image was loading.',
          ),
        );
      }
      return _EditorImageMasterResult.success(frame.image);
    } on Object catch (error) {
      _decodeFailures += 1;
      return _EditorImageMasterResult.failure(
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

  Future<_EditorImageMasterResult> _cropImage(
    ui.Image source, {
    required ui.Rect sourceRect,
    required String canonicalPath,
  }) async {
    final width = sourceRect.width.round();
    final height = sourceRect.height.round();
    if (!sourceRect.left.isFinite ||
        !sourceRect.top.isFinite ||
        !sourceRect.width.isFinite ||
        !sourceRect.height.isFinite ||
        width <= 0 ||
        height <= 0 ||
        sourceRect.left < 0 ||
        sourceRect.top < 0 ||
        sourceRect.right > source.width ||
        sourceRect.bottom > source.height) {
      _decodeFailures++;
      return _EditorImageMasterResult.failure(
        EditorImageFailure(
          kind: EditorImageFailureKind.decodeFailed,
          path: canonicalPath,
          message: 'The requested image crop is outside the decoded source.',
        ),
      );
    }

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      source,
      sourceRect,
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      ui.Paint(),
    );
    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(width, height);
      if (_disposed) {
        _disposeImage(image);
        return _EditorImageMasterResult.failure(
          EditorImageFailure(
            kind: EditorImageFailureKind.cacheDisposed,
            path: canonicalPath,
            message: 'The project session closed while cropping an image.',
          ),
        );
      }
      return _EditorImageMasterResult.success(image);
    } on Object catch (error) {
      _decodeFailures++;
      return _EditorImageMasterResult.failure(
        EditorImageFailure(
          kind: EditorImageFailureKind.decodeFailed,
          path: canonicalPath,
          message: 'The decoded image crop could not be created.',
          cause: error,
        ),
      );
    } finally {
      picture.dispose();
    }
  }

  void _disposeImage(ui.Image image) {
    if (_disposedImageIdentities[image] == true) return;
    _disposedImageIdentities[image] = true;
    image.dispose();
    _disposedImages += 1;
  }

  Future<EditorImageLoadResult> _acquireConsumer(
    _EditorImageCacheEntry entry, {
    required String canonicalPath,
  }) async {
    entry.pendingAcquisitions++;
    try {
      final result = await entry.future;
      final failure = result.failure;
      if (failure != null) {
        return EditorImageLoadResult.failure(failure);
      }
      if (_disposed) {
        return EditorImageLoadResult.failure(
          EditorImageFailure(
            kind: EditorImageFailureKind.cacheDisposed,
            path: canonicalPath,
            message: 'The project session closed while the image was loading.',
          ),
        );
      }
      final image = result.image;
      if (image == null) {
        return EditorImageLoadResult.failure(
          EditorImageFailure(
            kind: EditorImageFailureKind.decodeFailed,
            path: canonicalPath,
            message: 'The decoded image is unavailable.',
          ),
        );
      }
      try {
        return EditorImageLoadResult.success(image.clone());
      } on Object catch (error) {
        return EditorImageLoadResult.failure(
          EditorImageFailure(
            kind: EditorImageFailureKind.cacheDisposed,
            path: canonicalPath,
            message: 'The project image became unavailable before acquisition.',
            cause: error,
          ),
        );
      }
    } finally {
      entry.pendingAcquisitions--;
      if (entry.retirementRequested && entry.pendingAcquisitions == 0) {
        _scheduleEntryRetirement(entry);
      }
    }
  }

  void _trackDecode(_EditorImageSlot slot, _EditorImageCacheEntry entry) {
    _inFlightLoads++;
    unawaited(
      entry.future.then<void>((result) {
        _inFlightLoads--;
        if (result.failure != null) {
          if (identical(_entries[slot], entry)) {
            _entries.remove(slot);
          }
          return;
        }
        final image = result.image;
        if (image == null) return;
        if (identical(_entries[slot], entry)) {
          _admitDecodedEntry(slot, entry, image);
        }
        if (_disposed) _requestRetirement(entry);
      }),
    );
  }

  void _admitDecodedEntry(
    _EditorImageSlot slot,
    _EditorImageCacheEntry entry,
    ui.Image image,
  ) {
    if (entry.decodedBytes == 0) {
      entry.decodedBytes = image.width * image.height * 4;
      _residentDecodedBytes += entry.decodedBytes;
      if (_residentDecodedBytes > _peakDecodedBytes) {
        _peakDecodedBytes = _residentDecodedBytes;
      }
    }
    while (_residentDecodedBytes > maximumDecodedBytes) {
      MapEntry<_EditorImageSlot, _EditorImageCacheEntry>? victim;
      for (final candidate in _entries.entries) {
        if (candidate.value.decodedBytes > 0) {
          victim = candidate;
          break;
        }
      }
      if (victim == null) break;
      _evictions++;
      _removeEntry(victim.key, victim.value);
      if (identical(victim.value, entry)) break;
    }
  }

  void _touch(_EditorImageSlot slot, _EditorImageCacheEntry entry) {
    if (!identical(_entries.remove(slot), entry)) return;
    _entries[slot] = entry;
  }

  void _removeEntry(_EditorImageSlot slot, _EditorImageCacheEntry entry) {
    if (identical(_entries[slot], entry)) {
      _entries.remove(slot);
      _residentDecodedBytes -= entry.decodedBytes;
    }
    _requestRetirement(entry);
  }

  void _requestRetirement(_EditorImageCacheEntry entry) {
    entry.retirementRequested = true;
    if (entry.pendingAcquisitions == 0) {
      _scheduleEntryRetirement(entry);
    }
  }

  void _scheduleEntryRetirement(_EditorImageCacheEntry entry) {
    if (entry.retirementScheduled) return;
    entry.retirementScheduled = true;
    unawaited(
      entry.future.then<void>((result) {
        final image = result.image;
        if (image != null) _scheduleImageDisposal(image);
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
  _EditorImageCacheEntry({required this.fingerprint, required this.future});

  final _EditorImageFingerprint fingerprint;
  final Future<_EditorImageMasterResult> future;
  int decodedBytes = 0;
  int pendingAcquisitions = 0;
  bool retirementRequested = false;
  bool retirementScheduled = false;
}

class _EditorImageMasterResult {
  const _EditorImageMasterResult.success(ui.Image decodedImage)
    : image = decodedImage,
      failure = null;

  const _EditorImageMasterResult.failure(EditorImageFailure loadFailure)
    : image = null,
      failure = loadFailure;

  final ui.Image? image;
  final EditorImageFailure? failure;
}
