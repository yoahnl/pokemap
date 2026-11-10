import 'package:map_core/map_core_domain.dart';

import 'event_labels.dart';
import 'event_map_loader.dart';
import 'event_workspace_controller.dart';

class EventSourceSelectionSession {
  EventSourceSelectionSession({
    required this.controller,
    required this.loader,
    required NarrativeEventRecord record,
    required this.changed,
  }) : _record = record {
    _load(eventMapId(eventSource(record)));
  }

  EventWorkspaceController controller;
  EventMapLoader loader;
  NarrativeEventRecord _record;
  final void Function() changed;
  bool _disposed = false;
  int _request = 0;
  int _mapRequest = 0;
  String? _mapId;
  MapData? _map;
  Future<MapData>? _pendingMap;
  NarrativeEventSourceKind? _choosing;

  String get recordId => _record.id;
  String? get mapId => _mapId;
  MapData? get map => _map;
  Future<MapData>? get pendingMap => _pendingMap;
  NarrativeEventSourceKind? get choosing => _choosing;
  bool get _closed => _disposed || controller.workspace.isDisposed;

  void configure({
    required EventWorkspaceController controller,
    required EventMapLoader loader,
    required NarrativeEventRecord record,
  }) {
    if (_disposed) return;
    final ownerChanged =
        !identical(this.controller, controller) ||
        !identical(this.loader, loader);
    final recordChanged = _record.id != record.id;
    final sourceChanged = eventSource(_record) != eventSource(record);
    final previousMap = eventMapId(eventSource(_record));
    this.controller = controller;
    this.loader = loader;
    _record = record;
    if (ownerChanged || recordChanged || sourceChanged) _request++;
    if (ownerChanged || recordChanged) _choosing = null;
    final nextMap = eventMapId(eventSource(record));
    if (ownerChanged || recordChanged || previousMap != nextMap) _load(nextMap);
  }

  void _load(String? id) {
    final request = ++_mapRequest;
    final owner = controller;
    final eventId = recordId;
    _mapId = id;
    _map = null;
    _pendingMap = id == null
        ? null
        : loader.load(id).then((loaded) {
            if (_closed ||
                request != _mapRequest ||
                !identical(owner, controller) ||
                eventId != recordId ||
                id != _mapId) {
              return loaded;
            }
            if (loaded.id == id) {
              _map = loaded;
              owner.acceptMap(loaded);
              changed();
            }
            return loaded;
          });
  }

  void selectMap(String? id) {
    if (_closed) return;
    _request++;
    _load(id);
    changed();
  }

  bool _current(int request, String eventId, EventWorkspaceController owner) =>
      !_closed &&
      request == _request &&
      eventId == recordId &&
      identical(owner, controller);

  Future<bool> choose(
    NarrativeEventSourceKind kind, {
    Future<NarrativeOutcomeRef?> Function()? chooseOutcome,
  }) async {
    if (_closed) return false;
    final request = ++_request;
    final owner = controller;
    final eventId = recordId;
    if (!await owner.prepare(mapIds: [?_mapId]) ||
        !_current(request, eventId, owner)) {
      return false;
    }
    if (kind == NarrativeEventSourceKind.outcomeReceived) {
      final outcome = await chooseOutcome?.call();
      if (outcome == null || !_current(request, eventId, owner)) return false;
      return owner.setSource(
        eventId,
        NarrativeEventSourceRef.outcomeReceived(outcome),
      );
    }
    _choosing = kind;
    changed();
    return true;
  }

  bool accept(NarrativeEventSourceRef source) {
    if (_closed ||
        _choosing != source.kind ||
        _mapId != eventMapId(source) ||
        _map?.id != _mapId) {
      return false;
    }
    if (!controller.setSource(recordId, source)) return false;
    _request++;
    _choosing = null;
    changed();
    return true;
  }

  void cancel() {
    if (_closed) return;
    _request++;
    _choosing = null;
    _load(eventMapId(eventSource(_record)));
    changed();
  }

  void dispose() {
    _disposed = true;
    _request++;
    _mapRequest++;
  }
}
