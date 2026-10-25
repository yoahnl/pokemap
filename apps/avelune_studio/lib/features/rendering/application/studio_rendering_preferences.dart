import 'package:avelune_rendering/avelune_rendering.dart';
import 'package:flutter/foundation.dart';

abstract interface class StudioRenderingPreferencesStore {
  Future<int?> load();
  Future<void> save(int limit);
}

class StudioRenderingPreferences extends ChangeNotifier {
  StudioRenderingPreferences(this.store)
    : _savedLimit = AveluneFrameRate.limit {
    AveluneFrameRate.changes.addListener(_changed);
  }

  final StudioRenderingPreferencesStore store;
  Future<void>? _loading;
  Future<void>? _latestOperation;
  Future<void> _pending = Future.value();
  int _savedLimit;
  int _lastRequest = 0;
  int _pendingCount = 0;
  bool _loaded = false;
  bool _hasSaved = false;
  bool _disposed = false;
  String? _error;

  int get limit => AveluneFrameRate.limit;
  bool get loaded => _loaded;
  bool get saving => _pendingCount > 0;
  bool get hasSaved => _hasSaved;
  String? get error => _error;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final stored = await store.load();
      final value = stored ?? AveluneFrameRate.defaultLimit;
      if (!AveluneFrameRate.supportedLimits.contains(value)) {
        throw const FormatException('Unsupported rendering preference');
      }
      if (_disposed) return;
      _savedLimit = value;
      _hasSaved = stored != null;
      AveluneFrameRate.setLimit(value);
    } catch (_) {
      _error = 'Impossible de charger les préférences d’affichage.';
    } finally {
      _loaded = true;
      _changed();
    }
  }

  Future<void> setLimit(int value) async {
    if (!AveluneFrameRate.supportedLimits.contains(value)) {
      throw ArgumentError.value(value, 'value', 'Unsupported frame rate');
    }
    if (_disposed) throw StateError('Rendering preferences are disposed');
    if (!_loaded) await load();
    if (_disposed) throw StateError('Rendering preferences are disposed');
    if (value == limit && _error == null) {
      if (saving) await _latestOperation;
      return;
    }
    final request = ++_lastRequest;
    _pendingCount++;
    _error = null;
    AveluneFrameRate.setLimit(value);
    _changed();
    final operation = _pending.then((_) async {
      try {
        await store.save(value);
        _savedLimit = value;
        _hasSaved = true;
        if (request == _lastRequest) _error = null;
      } catch (_) {
        if (!_disposed && request == _lastRequest) {
          _error = 'Impossible d’enregistrer les préférences d’affichage. Votre dernier réglage enregistré a été rétabli.';
          AveluneFrameRate.setLimit(_savedLimit);
        }
        rethrow;
      } finally {
        _pendingCount--;
        _changed();
      }
    });
    _latestOperation = operation;
    _pending = operation.catchError((Object _) {});
    await operation;
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    AveluneFrameRate.changes.removeListener(_changed);
    super.dispose();
  }
}

class MemoryRenderingPreferencesStore
    implements StudioRenderingPreferencesStore {
  int? _limit;

  @override
  Future<int?> load() async => _limit;

  @override
  Future<void> save(int limit) async {
    _limit = limit;
  }
}
