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
  String? _error;
  bool _loaded = false;
  bool _disposed = false;
  Future<void>? _loading;

  String? get languageCode => _languageCode;
  String? get error => _error;
  bool get loaded => _loaded;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      _languageCode = await store.load();
    } on Object catch (failure) {
      _error = failure.toString();
    }
    _loaded = true;
    _notify();
  }

  Future<void> select(String? languageCode) async {
    if (languageCode == _languageCode) return;
    _languageCode = languageCode;
    _error = null;
    _notify();
    try {
      await store.save(languageCode);
    } on Object catch (failure) {
      _error = failure.toString();
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
