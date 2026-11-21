import 'package:flutter/foundation.dart';

abstract interface class StudioLanguageStore {
  Future<String?> load();
  Future<void> save(String? languageCode);
}

final class MemoryStudioLanguageStore implements StudioLanguageStore {
  MemoryStudioLanguageStore([this.languageCode]);

  String? languageCode;

  @override
  Future<String?> load() async => languageCode;

  @override
  Future<void> save(String? languageCode) async =>
      this.languageCode = languageCode;
}

class StudioLanguagePreferences extends ChangeNotifier {
  StudioLanguagePreferences(this.store);

  final StudioLanguageStore store;
  String? _languageCode;
  StudioLanguageFailure? _error;
  bool _loaded = false;
  bool _saving = false;
  bool _disposed = false;
  Future<void>? _loading;

  String? get languageCode => _languageCode;
  StudioLanguageFailure? get error => _error;
  bool get loaded => _loaded;
  bool get saving => _saving;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      _languageCode = await store.load();
    } on Object {
      _error = StudioLanguageFailure.load;
    }
    _loaded = true;
    _notify();
  }

  Future<void> select(String? languageCode) async {
    if (!_loaded) await load();
    if (_disposed || _saving || languageCode == _languageCode) return;
    final saved = _languageCode;
    _saving = true;
    _languageCode = languageCode;
    _error = null;
    _notify();
    try {
      await store.save(languageCode);
    } on Object {
      _languageCode = saved;
      _error = StudioLanguageFailure.save;
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

enum StudioLanguageFailure { load, save }
