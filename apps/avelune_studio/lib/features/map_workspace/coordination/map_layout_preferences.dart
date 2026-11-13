import 'package:flutter/foundation.dart';

typedef MapLayoutSnapshot = ({bool mapOnly, bool navigatorCollapsed});

abstract interface class MapLayoutPreferencesStore {
  Future<MapLayoutSnapshot?> load();
  Future<void> save(MapLayoutSnapshot snapshot);
}

final class MemoryMapLayoutPreferencesStore
    implements MapLayoutPreferencesStore {
  MapLayoutSnapshot? value;

  @override
  Future<MapLayoutSnapshot?> load() async => value;

  @override
  Future<void> save(MapLayoutSnapshot snapshot) async => value = snapshot;
}

final class MapLayoutPreferences extends ChangeNotifier {
  MapLayoutPreferences([MapLayoutPreferencesStore? store])
    : _store = store ?? MemoryMapLayoutPreferencesStore();

  final MapLayoutPreferencesStore _store;
  bool _mapOnly = false, _navigatorCollapsed = false, _changed = false;
  Future<void> saved = Future.value();
  String? error;

  bool get mapOnly => _mapOnly;
  bool get navigatorCollapsed => _navigatorCollapsed;

  Future<void> load() async {
    try {
      final stored = await _store.load();
      if (stored != null && !_changed) {
        _mapOnly = stored.mapOnly;
        _navigatorCollapsed = stored.navigatorCollapsed;
        notifyListeners();
      }
    } on Object {
      error = 'Préférences de disposition illisibles : valeurs par défaut.';
    }
  }

  void update({bool? mapOnly, bool? navigatorCollapsed}) {
    final next = (
      mapOnly: mapOnly ?? _mapOnly,
      navigatorCollapsed: navigatorCollapsed ?? _navigatorCollapsed,
    );
    if (next.mapOnly == _mapOnly &&
        next.navigatorCollapsed == _navigatorCollapsed) {
      return;
    }
    _changed = true;
    _mapOnly = next.mapOnly;
    _navigatorCollapsed = next.navigatorCollapsed;
    notifyListeners();
    saved = saved.then((_) async {
      try {
        await _store.save(next);
        error = null;
      } on Object {
        error = 'Impossible d’enregistrer la disposition ; elle reste active pour cette session.';
      }
    });
  }
}
