import 'dart:async';
import 'dart:collection';

import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';
import 'project_resource_library.dart';
import 'resource_catalog.dart';

abstract interface class ProjectResourcePreviewPort {
  Future<ProjectManifest> readResourcePreview(
    ProjectSession session,
    String kind,
    String id,
  );
}

typedef ProjectResourcePreview = ({ResourceItem item, ProjectManifest project});

final class ProjectResourcePreviews {
  ProjectResourcePreviews(this._load);

  static const _maxConcurrent = 3;
  static const _cacheSize = 64;

  final Future<ProjectManifest> Function(ProjectLibraryItem) _load;
  final _resources = Expando<Map<String, ResourceItem>>();
  final _requests = <String, _PreviewRequest>{};
  final _waiting = Queue<_PreviewRequest>();
  int _running = 0;

  ProjectResourcePreviewLease acquire(ProjectLibraryItem entry) {
    final request = _requests.remove(entry.identity) ?? _enqueue(entry);
    _requests[entry.identity] = request;
    request.listeners++;
    _startWaiting();
    return ProjectResourcePreviewLease._(
      request.result.future,
      () => _release(request),
    );
  }

  _PreviewRequest _enqueue(ProjectLibraryItem entry) {
    final request = _PreviewRequest(entry);
    _waiting.add(request);
    return request;
  }

  void _release(_PreviewRequest request) {
    request.listeners--;
    if (request.listeners == 0 && _waiting.remove(request)) {
      _requests.remove(request.entry.identity);
      request.result.complete(null);
    }
    _trim();
  }

  void _startWaiting() {
    while (_running < _maxConcurrent && _waiting.isNotEmpty) {
      _running++;
      unawaited(_read(_waiting.removeFirst()));
    }
  }

  Future<void> _read(_PreviewRequest request) async {
    final identity = request.entry.identity;
    try {
      final project = await _load(request.entry);
      final items = _resources[project] ??= {
        for (final item in resourceCatalog(project)) item.identity: item,
      };
      final item = items[identity];
      request.result.complete(
        item == null ? null : (item: item, project: project),
      );
    } catch (error, stack) {
      _requests.remove(identity);
      request.result.completeError(error, stack);
    } finally {
      _running--;
      _trim();
      _startWaiting();
    }
  }

  void _trim() {
    if (_requests.length <= _cacheSize) return;
    final idle = _requests.values
        .where(
          (request) => request.listeners == 0 && request.result.isCompleted,
        )
        .take(_requests.length - _cacheSize)
        .toList(growable: false);
    for (final request in idle) {
      _requests.remove(request.entry.identity);
    }
  }
}

final class ProjectResourcePreviewLease {
  ProjectResourcePreviewLease._(this.result, this.release);

  final Future<ProjectResourcePreview?> result;
  final void Function() release;
}

final class _PreviewRequest {
  _PreviewRequest(this.entry);

  final ProjectLibraryItem entry;
  final result = Completer<ProjectResourcePreview?>();
  int listeners = 0;
}
