import 'package:flutter/foundation.dart';

enum StudioAppearance { dark, light }

enum StudioAppearanceFailure { load, save }

abstract interface class StudioAppearanceStore {
  Future<StudioAppearance?> load();
  Future<void> save(StudioAppearance appearance);
}

final class MemoryStudioAppearanceStore implements StudioAppearanceStore {
  MemoryStudioAppearanceStore([this._appearance]);

  StudioAppearance? _appearance;

  @override
  Future<StudioAppearance?> load() async => _appearance;

  @override
  Future<void> save(StudioAppearance appearance) async =>
      _appearance = appearance;
}

class StudioAppearancePreferences extends ChangeNotifier {
  StudioAppearancePreferences(this.store);

  final StudioAppearanceStore store;
  StudioAppearance _appearance = StudioAppearance.dark;
  StudioAppearanceFailure? _error;
  Future<void>? _loading;
  var _loaded = false;
  var _saving = false;
  var _disposed = false;

  StudioAppearance get appearance => _appearance;
  StudioAppearanceFailure? get error => _error;
  bool get loaded => _loaded;
  bool get saving => _saving;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      _appearance = await store.load() ?? StudioAppearance.dark;
    } on Object {
      _error = StudioAppearanceFailure.load;
    }
    _loaded = true;
    _notify();
  }

  Future<void> select(StudioAppearance appearance) async {
    if (!_loaded) await load();
    if (_disposed || _saving || appearance == _appearance) return;
    final previous = _appearance;
    _appearance = appearance;
    _error = null;
    _saving = true;
    _notify();
    try {
      await store.save(appearance);
    } on Object {
      _appearance = previous;
      _error = StudioAppearanceFailure.save;
    } finally {
      _saving = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
