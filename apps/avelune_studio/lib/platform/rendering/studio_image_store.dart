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
      maximumDecodeBytes: maximumBytes < 64 * 1024 * 1024
          ? maximumBytes
          : 64 * 1024 * 1024,
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
  Set<String> priority = {};
  String? _loading;
  bool _closed = false;
  int _clock = 0;
  int evictions = 0;

  int get decodedBytes => images.values.toSet().fold(
    0,
    (total, image) => total + image.width * image.height * 4,
  );
  Set<String> get _pinned => _leases.values.expand((ids) => ids).toSet();
  bool get closed => _closed;

  void retain(Object owner, Set<String> ids) {
    if (_closed) return;
    _leases[owner] = ids;
    for (final id in ids) {
      final image = images[id];
      if (image != null) _used[image] = ++_clock;
      unawaited(request(id, retry: _pressure.contains(id)));
    }
  }

  void release(Object owner) {
    _leases.remove(owner);
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
    for (final id in _pressure.where(pinned.contains).toList()) {
      unawaited(request(id, retry: true));
    }
  }

  Future<void> request(
    String id, {
    bool retry = false,
    bool retainUntilComplete = false,
  }) {
    if (_closed || images.containsKey(id)) return Future.value();
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
            error.cause == WorkspaceResourceCause.memoryPressure) {
          _pressure.add(id);
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

  void _reserve(int requiredBytes) {
    if (_closed) throw StateError('Ressources fermées');
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
      if (decodedBytes + requiredBytes <= maximumBytes) break;
      images.removeWhere((id, value) => identical(value, image));
      _used.remove(image);
      _cache.evictImage(image);
      evictions++;
    }
    if (decodedBytes + requiredBytes > maximumBytes) {
      throw const StudioResourceFailure(
        WorkspaceResourceCause.memoryPressure,
        'Les images visibles occupent le budget disponible',
      );
    }
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
  }
}
