import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';

import 'tile_image_loader.dart';

final class RuntimeUiImageLease {
  RuntimeUiImageLease._(this.image, this._reservation);

  final ui.Image image;
  final RuntimeResourceReservation _reservation;
  bool _disposed = false;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    try {
      image.dispose();
    } finally {
      _reservation.release();
    }
  }
}

final class RuntimeOwnedImageCache {
  RuntimeOwnedImageCache({
    required this.loadLease,
    this.imageLoader,
    this.capacity = 96,
  });

  final Future<RuntimeUiImageLease> Function(String key) loadLease;
  final Future<ui.Image> Function(String key)? imageLoader;
  final int capacity;
  final Map<String, Future<ui.Image>> _pending = {};
  final Map<String, void Function()> _release = {};
  final Map<Object, Set<String>> _scopes = Map.identity();
  final Set<String> _retiredPending = {};
  bool _disposed = false;
  int actualLoadCount = 0;

  int get length => _pending.length;
  bool get isDisposed => _disposed;

  Object beginScope() {
    if (_disposed) throw StateError('Image cache is disposed.');
    final scope = Object();
    _scopes[scope] = {};
    return scope;
  }

  void endScope(Object scope, {bool trim = true}) {
    _scopes.remove(scope);
    if (trim) {
      trimUnused();
      final retained = {for (final keys in _scopes.values) ...keys};
      _retiredPending.addAll(
        _pending.keys.where(
          (key) => !_release.containsKey(key) && !retained.contains(key),
        ),
      );
    }
  }

  Future<ui.Image> load(String key) async {
    if (_disposed) throw StateError('Image cache is disposed.');
    _retiredPending.remove(key);
    for (final keys in _scopes.values) {
      keys.add(key);
    }
    final cached = _pending.remove(key);
    if (cached != null) {
      _pending[key] = cached;
      return cached;
    }
    trimUnused(maximumEntries: capacity - 1);
    final future = _load(key);
    _pending[key] = future;
    try {
      return await future;
    } catch (_) {
      if (identical(_pending[key], future)) _pending.remove(key);
      rethrow;
    }
  }

  void retain(String key) {
    for (final keys in _scopes.values) {
      keys.add(key);
    }
  }

  Future<ui.Image> _load(String key) async {
    actualLoadCount++;
    ui.Image image;
    void Function() release;
    final custom = imageLoader;
    if (custom != null) {
      image = await custom(key);
      release = image.dispose;
    } else {
      RuntimeUiImageLease lease;
      try {
        lease = await loadLease(key);
      } on RuntimeResourceAdmissionException catch (error) {
        if (error.reason.contains('cancel')) rethrow;
        trimUnused();
        lease = await loadLease(key);
      }
      image = lease.image;
      release = lease.dispose;
    }
    if (_disposed ||
        !_pending.containsKey(key) ||
        _retiredPending.remove(key)) {
      release();
      throw const RuntimeResourceAdmissionException('cancelled_or_closed');
    }
    _release[key] = release;
    return image;
  }

  void trimUnused({int maximumEntries = 0}) {
    final retained = {for (final keys in _scopes.values) ...keys};
    for (final key in _release.keys.toList(growable: false)) {
      if (_pending.length <= maximumEntries) break;
      if (retained.contains(key)) continue;
      _pending.remove(key);
      _release.remove(key)?.call();
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final release in _release.values) {
      release();
    }
    _release.clear();
    _pending.clear();
    _scopes.clear();
    _retiredPending.clear();
  }
}

Future<RuntimeUiImageLease> decodeRuntimeUiImage(
  Uint8List bytes, {
  RuntimeResourceBudget? resourceBudget,
  bool Function()? isCurrent,
  int retainedEncodedBytes = 0,
  RuntimeUiImageDecoder? decoder,
}) async {
  if (retainedEncodedBytes < 0) {
    throw ArgumentError.value(retainedEncodedBytes, 'retainedEncodedBytes');
  }
  final budget = resourceBudget ?? defaultRuntimeResourceBudget;
  _checkLength(bytes.length, budget);
  final reservation = await budget.acquire(
    transientBytes: bytes.length * 2,
    isCurrent: isCurrent,
  );
  return _decode(bytes, reservation, retainedEncodedBytes, decoder);
}

Future<RuntimeUiImageLease> loadRuntimeUiImageFromFilePath(
  String absolutePath, {
  RuntimeResourceBudget? resourceBudget,
  bool Function()? isCurrent,
}) async {
  final budget = resourceBudget ?? defaultRuntimeResourceBudget;
  final file = File(absolutePath);
  final length = await file.length();
  _checkLength(length, budget);
  final reservation = await budget.acquire(
    transientBytes: length * 2,
    isCurrent: isCurrent,
  );
  try {
    final bytes = await readRuntimeImageFileBytes(file, length);
    return await _decode(bytes, reservation, 0, null);
  } catch (_) {
    reservation.release();
    rethrow;
  }
}

void _checkLength(int length, RuntimeResourceBudget budget) {
  if (length <= 0 || length > budget.profile.maximumEncodedBytes) {
    throw const RuntimeResourceAdmissionException('encoded_bytes');
  }
}

Future<RuntimeUiImageLease> _decode(
  Uint8List bytes,
  RuntimeResourceReservation reservation,
  int retainedEncodedBytes,
  RuntimeUiImageDecoder? decoder,
) async {
  ui.Codec? codec;
  ui.Image? image;
  try {
    reservation.ensureCurrent();
    final dimensions = await inspectRuntimeImageDimensions(bytes);
    final residentLimit =
        reservation.profile.maximumResidentBytes - retainedEncodedBytes;
    final transientLimit =
        (reservation.profile.maximumTransientBytes - bytes.length * 2) ~/ 2;
    final pixels = runtimeImageRgbaByteLength(
      dimensions.width,
      dimensions.height,
      maximumBytes: residentLimit < transientLimit
          ? residentLimit
          : transientLimit,
    );
    reservation.resize(
      residentBytes: pixels + retainedEncodedBytes,
      transientBytes: bytes.length * 2 + pixels * 2,
    );
    if (decoder == null) {
      codec = await ui.instantiateImageCodec(bytes);
      image = (await codec.getNextFrame()).image;
    } else {
      image = await decoder(bytes);
    }
    if (image.width != dimensions.width || image.height != dimensions.height) {
      throw const RuntimeResourceAdmissionException(
        'decoded_dimensions_changed',
      );
    }
    reservation.ensureCurrent();
    reservation.commit();
    return RuntimeUiImageLease._(image, reservation);
  } catch (_) {
    image?.dispose();
    reservation.release();
    rethrow;
  } finally {
    codec?.dispose();
  }
}
