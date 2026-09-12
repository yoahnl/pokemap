import '../presentation/flame/runtime_input_event.dart';
import 'player_input.dart';

final class PlayerInputOwner {
  const PlayerInputOwner(this.source, {this.deviceId = ''});

  final PlayerInputSource source;
  final String deviceId;

  @override
  bool operator ==(Object other) =>
      other is PlayerInputOwner &&
      source == other.source &&
      deviceId == other.deviceId;

  @override
  int get hashCode => Object.hash(source, deviceId);
}

final class PlayerInputSourcePolicy {
  PlayerInputSourcePolicy({required this.touchAvailable})
      : _presentationOwner = PlayerInputOwner(touchAvailable
            ? PlayerInputSource.touch
            : PlayerInputSource.keyboard);

  final bool touchAvailable;
  PlayerInputOwner _presentationOwner;
  bool _hasIntentionalInput = false;
  bool _initialInventoryReceived = false;
  Set<String> _connectedControllers = {};
  final Map<RuntimeInputControl, PlayerInputOwner> _held = {};
  final Set<(PlayerInputOwner, RuntimeInputControl, String)> _physicalPresses =
      {};

  PlayerInputSource get activeSource => _presentationOwner.source;
  String? get activeControllerId => activeSource == PlayerInputSource.controller
      ? _presentationOwner.deviceId
      : null;
  Set<String> get connectedControllers =>
      Set.unmodifiable(_connectedControllers);

  void recognizeTouch() {
    if (touchAvailable) {
      _select(const PlayerInputOwner(PlayerInputSource.touch));
    }
  }

  void recognizeSource(PlayerInputOwner owner) => _select(owner);

  List<RuntimeInputEvent> releaseAll() {
    final events = releaseHeld();
    _physicalPresses.clear();
    return events;
  }

  List<RuntimeInputEvent> releaseHeld() {
    final events =
        _held.keys.map(RuntimeInputEvent.release).toList(growable: false);
    _held.clear();
    return events;
  }

  List<RuntimeInputEvent> updateControllers(Set<String> ids) {
    final removed = _connectedControllers.difference(ids);
    final releases = <RuntimeInputEvent>[];
    for (final id in removed) {
      releases.addAll(releaseOwner(
          PlayerInputOwner(PlayerInputSource.controller, deviceId: id)));
    }
    _connectedControllers = Set.of(ids);
    if (!_initialInventoryReceived && !_hasIntentionalInput && ids.isNotEmpty) {
      _presentationOwner =
          PlayerInputOwner(PlayerInputSource.controller, deviceId: ids.first);
    } else if (activeSource == PlayerInputSource.controller &&
        !ids.contains(activeControllerId)) {
      _presentationOwner = PlayerInputOwner(touchAvailable
          ? PlayerInputSource.touch
          : PlayerInputSource.keyboard);
    }
    _initialInventoryReceived = true;
    return releases;
  }

  List<RuntimeInputEvent> route(
    RuntimeInputEvent event, {
    required PlayerInputOwner owner,
    String inputId = '',
  }) {
    final key = (owner, event.control, inputId);
    if (!event.isPress) {
      if (!_physicalPresses.remove(key)) return const [];
      if (_held[event.control] != owner) return const [];
      if (_physicalPresses
          .any((key) => key.$1 == owner && key.$2 == event.control)) {
        return const [];
      }
      _held.remove(event.control);
      return [event];
    }
    if (event.isRepeat) {
      if (_physicalPresses.contains(key) &&
          _held[event.control] == owner &&
          _presentationOwner == owner &&
          _isDirection(event.control)) {
        return [event];
      }
      return const [];
    }
    if (!_physicalPresses.add(key)) return const [];
    _select(owner);
    if (_isMovement(event.control) && _held[event.control] == owner) {
      return const [];
    }
    final events = <RuntimeInputEvent>[];
    if (_isMovement(event.control)) {
      for (final entry in _held.entries.toList(growable: false)) {
        if (_isMovement(entry.key) && entry.value != owner) {
          _held.remove(entry.key);
          events.add(RuntimeInputEvent.release(entry.key));
        }
      }
    }
    _held[event.control] = owner;
    events.add(event);
    return events;
  }

  List<RuntimeInputEvent> releaseMovement() {
    final controls = _held.keys.where(_isMovement).toList(growable: false);
    for (final control in controls) {
      _held.remove(control);
    }
    return controls.map(RuntimeInputEvent.release).toList(growable: false);
  }

  List<RuntimeInputEvent> releaseOwner(PlayerInputOwner owner) {
    final controls = _held.entries
        .where((entry) => entry.value == owner)
        .map((entry) => entry.key)
        .toList(growable: false);
    for (final control in controls) {
      _held.remove(control);
    }
    _physicalPresses.removeWhere((entry) => entry.$1 == owner);
    return controls.map(RuntimeInputEvent.release).toList(growable: false);
  }

  void _select(PlayerInputOwner owner) {
    if (owner.source == PlayerInputSource.mouse) return;
    _hasIntentionalInput = true;
    _presentationOwner = owner;
    if (owner.source == PlayerInputSource.controller) {
      _connectedControllers.add(owner.deviceId);
    }
  }

  static bool _isDirection(RuntimeInputControl control) =>
      control == RuntimeInputControl.up ||
      control == RuntimeInputControl.down ||
      control == RuntimeInputControl.left ||
      control == RuntimeInputControl.right;

  static bool _isMovement(RuntimeInputControl control) =>
      _isDirection(control) || control == RuntimeInputControl.sprint;
}
