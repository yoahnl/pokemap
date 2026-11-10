import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

class StudioPlaytestStatus {
  const StudioPlaytestStatus({
    this.ready = false,
    this.busy = false,
    this.hasSave = false,
    this.paused = false,
    this.message,
  });

  final bool ready;
  final bool busy;
  final bool hasSave;
  final bool paused;
  final String? message;
}

class StudioPlaytestControls {
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

class StudioSpatialExplorationCommands {
  const StudioSpatialExplorationCommands({
    required this.movement,
    this.session,
  });

  final SpatialMovementController movement;
  final SpatialExplorationSession? session;

  SpatialMovementController get _movement => session?.movement ?? movement;

  void resetPosition() {
    if (session?.transitioning.value ?? false) return;
    session?.closeDialogue();
    session?.dialoguePaused = false;
    if (session case final session?) {
      session.resetPosition();
    } else {
      _movement.reset();
    }
  }

  void togglePause() {
    final paused = !(session?.dialoguePaused ?? _movement.paused);
    session?.dialoguePaused = paused;
    _movement.setPaused(
      (session?.presentationPaused ?? paused) ||
          (session?.interactionActive.value ?? false) ||
          (session?.transitioning.value ?? false),
    );
  }

  void toggleDiagonal() =>
      _movement.setDiagonalMovement(!_movement.allowDiagonalMovement);
}
