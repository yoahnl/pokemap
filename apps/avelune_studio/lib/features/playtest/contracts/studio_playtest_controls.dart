import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart' show PlaytestSpeed;

class StudioPlaytestStatus {
  const StudioPlaytestStatus({
    this.ready = false,
    this.busy = false,
    this.hasSave = false,
    this.paused = false,
    this.spatial = false,
    this.diagonal = false,
    this.message,
  });

  final bool ready;
  final bool busy;
  final bool hasSave;
  final bool paused;
  final bool spatial;
  final bool diagonal;
  final String? message;
}

class StudioPlaytestControls extends ChangeNotifier {
  Object? _owner;
  StudioPlaytestStatus Function()? _status;
  Future<void> Function()? _save;
  Future<void> Function()? _resume;
  Future<void> Function()? _newGame;
  Future<void> Function()? _togglePause;
  void Function(PlaytestSpeed)? _setSpeed;
  void Function()? _toggleDiagonal;
  void Function()? _requestClose;

  bool get attached => _owner != null;
  StudioPlaytestStatus get status =>
      _status?.call() ?? const StudioPlaytestStatus();
  bool get available => status.ready && !status.busy;
  bool get canResume => available && status.hasSave;

  void attach(
    Object owner, {
    required StudioPlaytestStatus Function() status,
    required Future<void> Function() save,
    required Future<void> Function() resume,
    required Future<void> Function() newGame,
    required Future<void> Function() togglePause,
    required void Function(PlaytestSpeed) setSpeed,
    required void Function() toggleDiagonal,
    required void Function() requestClose,
  }) {
    if (_owner != null && !identical(_owner, owner)) {
      throw StateError('Playtest controls already have an owner');
    }
    _owner = owner;
    _status = status;
    _save = save;
    _resume = resume;
    _newGame = newGame;
    _togglePause = togglePause;
    _setSpeed = setSpeed;
    _toggleDiagonal = toggleDiagonal;
    _requestClose = requestClose;
  }

  void detach(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _status = null;
    _save = null;
    _resume = null;
    _newGame = null;
    _togglePause = null;
    _setSpeed = null;
    _toggleDiagonal = null;
    _requestClose = null;
  }

  void statusChanged() => notifyListeners();

  void requestClose() => _requestClose?.call();

  Future<void> save() async {
    if (available) await _save?.call();
  }

  Future<void> resume() async {
    if (canResume) await _resume?.call();
  }

  Future<void> newGame() async {
    if (available) await _newGame?.call();
  }

  Future<void> togglePause() async {
    if (available) await _togglePause?.call();
  }

  void setTestSpeed(PlaytestSpeed speed) {
    if (available) _setSpeed?.call(speed);
  }

  void toggleDiagonal() {
    if (available) _toggleDiagonal?.call();
  }
}
