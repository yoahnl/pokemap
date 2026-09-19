import 'dart:async';

import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';

import 'package:avelune_studio/presentation/features/map_workspace/workspace_resource_diagnostic.dart';
import 'studio_resource_decoder.dart';

final class StudioImageStore {
  StudioImageStore({
    required String projectRoot,
    required this.maximumBytes,
    required this.paths,
    required this.colors,
    required this.changed,
    required this.failed,
    StudioImageDecoder decode = decodeRuntimeTilesetImage,
  }) {
    decoder = StudioResourceDecoder(
      projectRoot: projectRoot,
      maximumDecodeBytes: maximumBytes,
      reserve: _reserve,
      decode: decode,
    );
    _cache = RuntimeTilesetImageSingleFlightCache(
      loader: (paths, {transparentColorByTilesetId = const {}}) async => {
        for (final entry in paths.entries)
          entry.key: await decoder.load(
            entry.value,
            transparentColor: transparentColorByTilesetId[entry.key],
          ),
      },
    );
  }

  final int maximumBytes;
  final Map<String, String> paths;
  final Map<String, TilesetTransparentColor> colors;
  final void Function() changed;
  final void Function(String, StudioResourceFailure?) failed;
  late final StudioResourceDecoder decoder;
  late final RuntimeTilesetImageSingleFlightCache _cache;
  final Map<String, RuntimeTilesetImage> images = {};
  final Map<Object, Set<String>> _leases = {};
  final Map<String, Completer<void>> _queue = {};
  final Set<String> _explicitRequests = {};
  final Set<String> _failures = {};
  final Set<String> _pressure = {};
  final Map<RuntimeTilesetImage, int> _used = Map.identity();
  final Map<RuntimeTilesetImage, Set<Object>> _retired = Map.identity();
  final Set<String> _deterministicFailures = {};
  Set<String> priority = {};
  String? _loading;
  bool _closed = false;
  int _clock = 0;
  int evictions = 0;
  int peakAccountedBytes = 0;
  int get maximumWorkingBytes => maximumBytes + 256 * 1024 * 1024;

  int get decodedBytes => {
    ...images.values,
    ..._retired.keys,
  }.fold(0, (total, image) => total + image.width * image.height * 4);
  Set<String> get _pinned => _leases.values.expand((ids) => ids).toSet();
  bool get closed => _closed;

  void retain(Object owner, Set<String> ids) {
    if (_closed) return;
    final previous = _pinned;
    final bytes = decodedBytes;
    _releaseRetired(owner);
    _leases[owner] = ids;
    for (final id in ids) {
      final image = images[id];
      if (image != null) _used[image] = ++_clock;
      unawaited(request(id));
    }
    _retryAfterCapacityChange(previous, bytes);
  }

  void release(Object owner) {
    final previous = _pinned;
    final bytes = decodedBytes;
    _leases.remove(owner);
    _releaseRetired(owner);
    if (_closed && _leases.isEmpty) _finishDisposal();
    if (_closed) return;
    final pinned = _pinned;
    for (final entry in _queue.entries.toList()) {
      if (entry.key == _loading ||
          pinned.contains(entry.key) ||
          _explicitRequests.contains(entry.key)) {
        continue;
      }
      entry.value.complete();
      _queue.remove(entry.key);
    }
    _retryAfterCapacityChange(previous, bytes);
  }

  void _retryAfterCapacityChange(Set<String> previous, int bytes) {
    final pinned = _pinned;
    if (bytes <= decodedBytes &&
        !previous.difference(pinned).any(images.containsKey)) {
      return;
    }
    for (final id in _pressure.where(pinned.contains).toList()) {
      unawaited(request(id, retry: true));
    }
  }

  void _releaseRetired(Object owner) {
    for (final entry in _retired.entries.toList()) {
      entry.value.remove(owner);
      if (entry.value.isEmpty) {
        _retired.remove(entry.key);
        entry.key.dispose();
      }
    }
  }

  void invalidate(Set<String> ids) {
    final stale = {
      for (final id in ids)
        if (images[id] != null) images[id]!,
    };
    for (final image in stale) {
      final aliases = images.keys
          .where((id) => identical(images[id], image))
          .toSet();
      final owners = {
        for (final entry in _leases.entries)
          if (entry.value.any(aliases.contains)) entry.key,
      };
      images.removeWhere((id, value) => identical(value, image));
      _cache.evictImage(image, dispose: owners.isEmpty);
      _used.remove(image);
      if (owners.isNotEmpty) _retired[image] = owners;
      ids = {...ids, ...aliases};
    }
    for (final id in ids) {
      _failures.remove(id);
      _pressure.remove(id);
      _deterministicFailures.remove(id);
      failed(id, null);
    }
    for (final id in _pinned.intersection(ids)) {
      unawaited(request(id));
    }
  }

  Future<void> request(
    String id, {
    bool retry = false,
    bool retainUntilComplete = false,
  }) {
    if (_closed ||
        images.containsKey(id) ||
        _deterministicFailures.contains(id)) {
      return Future.value();
    }
    if (retry) _failures.remove(id);
    if (_failures.contains(id)) return Future.value();
    if (retainUntilComplete) _explicitRequests.add(id);
    final pending = _queue[id];
    if (pending != null) return pending.future;
    final completer = Completer<void>();
    _queue[id] = completer;
    scheduleMicrotask(_drain);
    return completer.future;
  }

  Future<void> get settled async {
    while (_queue.isNotEmpty) {
      await Future.wait(_queue.values.map((value) => value.future));
    }
  }

  Future<void> _drain() async {
    if (_closed || _loading != null || _queue.isEmpty) return;
    final id =
        priority.where(_queue.containsKey).firstOrNull ?? _queue.keys.first;
    final completer = _queue[id]!;
    _loading = id;
    try {
      final path = paths[id];
      if (path == null) {
        throw const StudioResourceFailure(
          WorkspaceResourceCause.unsupported,
          'Référence absente du manifeste ou chemin non pris en charge',
        );
      }
      final loaded = await _cache.loadById(
        {id: path},
        transparentColorByTilesetId: {if (colors[id] != null) id: colors[id]!},
      );
      if (!_closed) {
        images.addAll(loaded);
        for (final image in loaded.values) {
          _used[image] = ++_clock;
        }
        _failures.remove(id);
        _pressure.remove(id);
        failed(id, null);
      }
    } on Object catch (error) {
      if (!_closed) {
        _failures.add(id);
        if (error is StudioResourceFailure &&
            error.cause == WorkspaceResourceCause.memoryPressure &&
            error.retryable) {
          _pressure.add(id);
        }
        if (error is StudioResourceFailure && !error.retryable) {
          _deterministicFailures.add(id);
        }
        failed(
          id,
          error is StudioResourceFailure
              ? error
              : StudioResourceFailure(
                  WorkspaceResourceCause.readFailure,
                  error.toString(),
                ),
        );
      }
    } finally {
      _queue.remove(id);
      _explicitRequests.remove(id);
      _loading = null;
      if (!completer.isCompleted) completer.complete();
      if (!_closed) {
        changed();
        scheduleMicrotask(_drain);
      }
    }
  }

  void _reserve(int requiredBytes, int transientBytes) {
    if (_closed) throw StateError('Ressources fermées');
    if (transientBytes > maximumWorkingBytes) {
      throw StudioResourceFailure(
        WorkspaceResourceCause.memoryPressure,
        'Décodage complet estimé : $transientBytes octets ; budget total : $maximumWorkingBytes octets',
        retryable: false,
      );
    }
    final pinned = _pinned;
    final pinnedImages = {
      for (final id in pinned)
        if (images[id] != null) images[id]!,
    };
    final candidates =
        images.values
            .toSet()
            .where((image) => !pinnedImages.contains(image))
            .toList()
          ..sort((a, b) => (_used[a] ?? 0).compareTo(_used[b] ?? 0));
    for (final image in candidates) {
      if (decodedBytes + requiredBytes <= maximumBytes &&
          decodedBytes + transientBytes <= maximumWorkingBytes) {
        break;
      }
      images.removeWhere((id, value) => identical(value, image));
      _used.remove(image);
      _cache.evictImage(image);
      evictions++;
    }
    if (decodedBytes + requiredBytes > maximumBytes ||
        decodedBytes + transientBytes > maximumWorkingBytes) {
      throw StudioResourceFailure(
        WorkspaceResourceCause.memoryPressure,
        'Images retenues : $decodedBytes octets ; nouvelle image : $requiredBytes ; décodage estimé : $transientBytes ; budgets résident/total : $maximumBytes/$maximumWorkingBytes octets',
      );
    }
    final accounted = decodedBytes + transientBytes;
    if (accounted > peakAccountedBytes) peakAccountedBytes = accounted;
  }

  void close() {
    _closed = true;
    for (final entry in _queue.entries.toList()) {
      if (entry.key == _loading) continue;
      entry.value.complete();
      _queue.remove(entry.key);
    }
    if (_leases.isEmpty) _finishDisposal();
  }

  void _finishDisposal() {
    _cache.dispose();
    images.clear();
    _used.clear();
    for (final image in _retired.keys) {
      image.dispose();
    }
    _retired.clear();
  }
}
