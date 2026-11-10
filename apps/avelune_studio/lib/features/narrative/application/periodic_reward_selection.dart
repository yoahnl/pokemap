import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core_domain.dart';

class PeriodicRewardSelection {
  PeriodicRewardSelection({
    this.initial,
    this.initialExpectedValue = true,
    this.read,
    required this.changed,
  }) {
    _sceneId = initial?.sceneId;
    _reference = initial;
    _expected = initialExpectedValue;
  }
  final PeriodicRewardReference? initial;
  final bool initialExpectedValue;
  final Future<AuthoringQueryPage> Function(AuthoringQueryRequest)? read;
  final void Function() changed;
  final _scenes = <PeriodicRewardSceneChoice>[];
  final _nodes = <PeriodicRewardNodeChoice>[];
  String? _sceneId, _cursor, _error;
  PeriodicRewardReference? _reference;
  bool _loading = false, _expected = true, _disposed = false;
  int _generation = 0;

  List<PeriodicRewardSceneChoice> get scenes => List.unmodifiable(_scenes);
  List<PeriodicRewardNodeChoice> get nodes => List.unmodifiable(_nodes);
  String? get sceneId => _sceneId;
  String? get cursor => _cursor;
  String? get error => _error;
  bool get loading => _loading;
  bool get expected => _expected;
  set expected(bool value) => _update(() => _expected = value);
  PeriodicRewardNodeChoice? get selected =>
      _nodes.where((node) => node.reference == _reference).firstOrNull;
  PeriodicRewardReference? get applicable =>
      _loading || _error != null ? null : selected?.reference;
  bool get unresolved => initial != null && selected == null && !_loading;

  void _update(void Function() update) {
    if (_disposed) return;
    update();
    changed();
  }

  void selectScene(String id) {
    if (_disposed) return;
    _update(() {
      _sceneId = id;
      _reference = null;
    });
    _loadNodes(id);
  }

  void selectNode(String id) => _update(
    () => _reference = _nodes
        .where((node) => node.nodeId == id)
        .firstOrNull
        ?.reference,
  );
  void dispose() {
    _disposed = true;
    _generation++;
  }

  Future<void> loadScenes({bool more = false}) async {
    if (_disposed) return;
    final scope = read;
    if (scope == null) {
      _error = 'Les récompenses publiées sont indisponibles dans cet atelier. La condition existante est conservée.';
      return;
    }
    final generation = ++_generation;
    _update(() {
      _loading = true;
      _error = null;
      if (!more) _nodes.clear();
    });
    try {
      final page = await scope(
        AuthoringQueryRequest(
          resourceKind: 'periodicRewardScene',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.summary,
          pageSize: 30,
          cursor: more ? _cursor : null,
        ),
      );
      if (_disposed || generation != _generation) return;
      _update(() {
        if (!more) _scenes.clear();
        _scenes.addAll(
          page.items.map(
            (value) => PeriodicRewardSceneChoice.fromJson(
              Map<String, dynamic>.from(value),
            ),
          ),
        );
        _cursor = page.nextCursor;
      });
      final initial = this.initial;
      if (!more &&
          initial != null &&
          !_scenes.any((scene) => scene.sceneId == initial.sceneId)) {
        final selected = await scope(
          AuthoringQueryRequest(
            resourceKind: 'periodicRewardScene',
            operation: AuthoringQueryOperation.get,
            view: AuthoringQueryView.summary,
            ids: [initial.sceneId],
          ),
        );
        if (_disposed || generation != _generation) return;
        _update(
          () => _scenes.addAll(
            selected.items.map(
              (value) => PeriodicRewardSceneChoice.fromJson(
                Map<String, dynamic>.from(value),
              ),
            ),
          ),
        );
      }
      if (!more && _sceneId != null) await _loadNodes(_sceneId!);
    } catch (error) {
      if (!_disposed && generation == _generation) {
        _update(
          () => _error = 'Source publiée indisponible ou modifiée. Actualisez les choix. La condition existante est conservée.',
        );
      }
    } finally {
      if (!_disposed && generation == _generation) {
        _update(() => _loading = false);
      }
    }
  }

  Future<void> _loadNodes(String sceneId) async {
    if (_disposed) return;
    final source = _scenes
        .where((value) => value.sceneId == sceneId)
        .firstOrNull;
    final scope = read;
    final generation = ++_generation;
    _update(() {
      _loading = source != null && scope != null;
      _error = null;
      _nodes.clear();
    });
    if (source == null || scope == null) return;
    try {
      String? cursor;
      do {
        final page = await scope(
          AuthoringQueryRequest(
            resourceKind: 'periodicRewardNode',
            operation: AuthoringQueryOperation.list,
            view: AuthoringQueryView.summary,
            filters: {'sceneId': sceneId},
            extensions: {'sourceRevision': source.revision},
            pageSize: 100,
            cursor: cursor,
          ),
        );
        if (_disposed || generation != _generation) return;
        _update(
          () => _nodes.addAll(
            page.items.map(
              (value) => PeriodicRewardNodeChoice.fromJson(
                Map<String, dynamic>.from(value),
              ),
            ),
          ),
        );
        cursor = page.nextCursor;
      } while (cursor != null);
    } catch (error) {
      if (!_disposed && generation == _generation) {
        _update(
          () => _error = 'Cette scène publiée a changé ou reste indisponible. Choisissez sa version enregistrée ; les modifications en brouillon ne sont pas des sources publiées.',
        );
      }
    } finally {
      if (!_disposed && generation == _generation) {
        _update(() => _loading = false);
      }
    }
  }
}
