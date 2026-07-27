import 'dart:collection';

import 'package:flutter/services.dart';
import 'package:gamepads/gamepads.dart';
import 'package:map_runtime/map_runtime.dart';

enum PlayerControlDevice { keyboard, gamepad, touch }

final class PlayerControlConflict {
  const PlayerControlConflict({
    required this.device,
    required this.inputId,
    required this.control,
  });

  final PlayerControlDevice device;
  final String inputId;
  final RuntimeInputControl control;
}

final class PlayerControlRebindResult {
  const PlayerControlRebindResult({
    required this.profile,
    this.conflict,
  });

  final PlayerControlProfile profile;
  final PlayerControlConflict? conflict;

  bool get hasConflict => conflict != null;
}

/// Persistable physical-input profile shared by the player and the Hub.
final class PlayerControlProfile {
  PlayerControlProfile({
    required Map<RuntimeInputControl, String> keyboard,
    required Map<RuntimeInputControl, String> gamepad,
    required Map<RuntimeInputControl, String> touch,
  })  : keyboard = UnmodifiableMapView(Map.of(keyboard)),
        gamepad = UnmodifiableMapView(Map.of(gamepad)),
        touch = UnmodifiableMapView(Map.of(touch)) {
    for (final device in PlayerControlDevice.values) {
      final bindings = _bindings(device);
      if (!bindings.keys.toSet().containsAll(RuntimeInputControl.values)) {
        throw FormatException('Incomplete ${device.name} control profile.');
      }
      if (bindings.values.toSet().length != bindings.length) {
        throw FormatException('Conflicting ${device.name} control profile.');
      }
    }
  }

  static final PlayerControlProfile standard = PlayerControlProfile(
    keyboard: const <RuntimeInputControl, String>{
      RuntimeInputControl.up: 'arrowUp',
      RuntimeInputControl.down: 'arrowDown',
      RuntimeInputControl.left: 'arrowLeft',
      RuntimeInputControl.right: 'arrowRight',
      RuntimeInputControl.primary: 'keyE',
      RuntimeInputControl.secondary: 'escape',
      RuntimeInputControl.menu: 'keyM',
    },
    gamepad: const <RuntimeInputControl, String>{
      RuntimeInputControl.up: 'dpadUp',
      RuntimeInputControl.down: 'dpadDown',
      RuntimeInputControl.left: 'dpadLeft',
      RuntimeInputControl.right: 'dpadRight',
      RuntimeInputControl.primary: 'a',
      RuntimeInputControl.secondary: 'b',
      RuntimeInputControl.menu: 'start',
    },
    touch: const <RuntimeInputControl, String>{
      RuntimeInputControl.up: 'joystickUp',
      RuntimeInputControl.down: 'joystickDown',
      RuntimeInputControl.left: 'joystickLeft',
      RuntimeInputControl.right: 'joystickRight',
      RuntimeInputControl.primary: 'primaryButton',
      RuntimeInputControl.secondary: 'secondaryButton',
      RuntimeInputControl.menu: 'menuButton',
    },
  );

  final Map<RuntimeInputControl, String> keyboard;
  final Map<RuntimeInputControl, String> gamepad;
  final Map<RuntimeInputControl, String> touch;

  factory PlayerControlProfile.fromJson(Object? source) {
    if (source is! Map<String, dynamic>) {
      throw const FormatException('Control profile must be an object.');
    }
    return PlayerControlProfile(
      keyboard: _decodeBindings(source['keyboard']),
      gamepad: _decodeBindings(source['gamepad']),
      touch: _decodeBindings(source['touch']),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': 1,
        'keyboard': _encodeBindings(keyboard),
        'gamepad': _encodeBindings(gamepad),
        'touch': _encodeBindings(touch),
      };

  String bindingFor(
    PlayerControlDevice device,
    RuntimeInputControl control,
  ) =>
      _bindings(device)[control]!;

  PlayerControlRebindResult rebind({
    required PlayerControlDevice device,
    required RuntimeInputControl control,
    required String inputId,
  }) {
    final normalized = inputId.trim();
    final current = _bindings(device);
    for (final entry in current.entries) {
      if (entry.key != control && entry.value == normalized) {
        return PlayerControlRebindResult(
          profile: this,
          conflict: PlayerControlConflict(
            device: device,
            inputId: normalized,
            control: entry.key,
          ),
        );
      }
    }
    final next = Map<RuntimeInputControl, String>.of(current)
      ..[control] = normalized;
    return PlayerControlRebindResult(
      profile: _copyDevice(device, next),
    );
  }

  PlayerControlProfile resetDevice(PlayerControlDevice device) =>
      _copyDevice(device, standard._bindings(device));

  PlayerControlProfile swapBindings({
    required PlayerControlDevice device,
    required RuntimeInputControl first,
    required RuntimeInputControl second,
  }) {
    final next = Map<RuntimeInputControl, String>.of(_bindings(device));
    final firstBinding = next[first]!;
    next[first] = next[second]!;
    next[second] = firstBinding;
    return _copyDevice(device, next);
  }

  RuntimeInputControl? controlForGamepadButton(GamepadButton button) =>
      _controlForInput(PlayerControlDevice.gamepad, button.name);

  RuntimeInputControl? controlForTouchInput(String inputId) =>
      _controlForInput(PlayerControlDevice.touch, inputId);

  RuntimeInputEvent? runtimeEventFromKeyEvent(KeyEvent event) {
    final inputId = _keyboardInputId(event.logicalKey);
    final control = inputId == null
        ? null
        : _controlForInput(PlayerControlDevice.keyboard, inputId);
    final resolved = control ??
        (this == standard
            ? runtimeInputControlFromLogicalKey(event.logicalKey)
            : null);
    if (resolved == null) return null;
    if (event is KeyRepeatEvent) {
      return RuntimeInputEvent.press(resolved, isRepeat: true);
    }
    if (event is KeyDownEvent) return RuntimeInputEvent.press(resolved);
    if (event is KeyUpEvent) return RuntimeInputEvent.release(resolved);
    return null;
  }

  String glyphFor(
    PlayerControlDevice device,
    RuntimeInputControl control,
  ) =>
      glyphForInput(bindingFor(device, control));

  static String glyphForInput(String inputId) => _glyphs[inputId] ?? inputId;

  Map<RuntimeInputControl, String> _bindings(PlayerControlDevice device) =>
      switch (device) {
        PlayerControlDevice.keyboard => keyboard,
        PlayerControlDevice.gamepad => gamepad,
        PlayerControlDevice.touch => touch,
      };

  RuntimeInputControl? _controlForInput(
    PlayerControlDevice device,
    String inputId,
  ) {
    for (final entry in _bindings(device).entries) {
      if (entry.value == inputId) return entry.key;
    }
    return null;
  }

  PlayerControlProfile _copyDevice(
    PlayerControlDevice device,
    Map<RuntimeInputControl, String> bindings,
  ) =>
      PlayerControlProfile(
        keyboard: device == PlayerControlDevice.keyboard ? bindings : keyboard,
        gamepad: device == PlayerControlDevice.gamepad ? bindings : gamepad,
        touch: device == PlayerControlDevice.touch ? bindings : touch,
      );

  @override
  bool operator ==(Object other) =>
      other is PlayerControlProfile &&
      _mapsEqual(keyboard, other.keyboard) &&
      _mapsEqual(gamepad, other.gamepad) &&
      _mapsEqual(touch, other.touch);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(
          keyboard.entries.map((entry) => Object.hash(entry.key, entry.value)),
        ),
        Object.hashAll(
          gamepad.entries.map((entry) => Object.hash(entry.key, entry.value)),
        ),
        Object.hashAll(
          touch.entries.map((entry) => Object.hash(entry.key, entry.value)),
        ),
      );
}

const Map<String, LogicalKeyboardKey> playerKeyboardInputs =
    <String, LogicalKeyboardKey>{
  'arrowUp': LogicalKeyboardKey.arrowUp,
  'arrowDown': LogicalKeyboardKey.arrowDown,
  'arrowLeft': LogicalKeyboardKey.arrowLeft,
  'arrowRight': LogicalKeyboardKey.arrowRight,
  'keyW': LogicalKeyboardKey.keyW,
  'keyA': LogicalKeyboardKey.keyA,
  'keyS': LogicalKeyboardKey.keyS,
  'keyD': LogicalKeyboardKey.keyD,
  'keyE': LogicalKeyboardKey.keyE,
  'keyQ': LogicalKeyboardKey.keyQ,
  'keyZ': LogicalKeyboardKey.keyZ,
  'keyX': LogicalKeyboardKey.keyX,
  'space': LogicalKeyboardKey.space,
  'enter': LogicalKeyboardKey.enter,
  'escape': LogicalKeyboardKey.escape,
  'tab': LogicalKeyboardKey.tab,
  'keyM': LogicalKeyboardKey.keyM,
};

const List<String> playerGamepadInputs = <String>[
  'dpadUp',
  'dpadDown',
  'dpadLeft',
  'dpadRight',
  'a',
  'b',
  'x',
  'y',
  'back',
  'start',
];

const List<String> playerTouchInputs = <String>[
  'joystickUp',
  'joystickDown',
  'joystickLeft',
  'joystickRight',
  'primaryButton',
  'secondaryButton',
  'menuButton',
];

const Map<String, String> _glyphs = <String, String>{
  'arrowUp': '↑',
  'arrowDown': '↓',
  'arrowLeft': '←',
  'arrowRight': '→',
  'keyW': 'W',
  'keyA': 'A',
  'keyS': 'S',
  'keyD': 'D',
  'keyE': 'E',
  'keyQ': 'Q',
  'keyZ': 'Z',
  'keyX': 'X',
  'space': 'Space',
  'enter': 'Enter',
  'escape': 'Esc',
  'tab': 'Tab',
  'keyM': 'M',
  'dpadUp': 'D-pad ↑',
  'dpadDown': 'D-pad ↓',
  'dpadLeft': 'D-pad ←',
  'dpadRight': 'D-pad →',
  'a': 'A',
  'b': 'B',
  'x': 'X',
  'y': 'Y',
  'back': 'Back',
  'start': 'Start',
  'joystickUp': 'Stick ↑',
  'joystickDown': 'Stick ↓',
  'joystickLeft': 'Stick ←',
  'joystickRight': 'Stick →',
  'primaryButton': 'A',
  'secondaryButton': 'B',
  'menuButton': '☰',
};

String? _keyboardInputId(LogicalKeyboardKey key) {
  for (final entry in playerKeyboardInputs.entries) {
    if (entry.value == key) return entry.key;
  }
  return null;
}

Map<RuntimeInputControl, String> _decodeBindings(Object? source) {
  if (source is! Map<String, dynamic>) {
    throw const FormatException('Device bindings must be an object.');
  }
  return <RuntimeInputControl, String>{
    for (final control in RuntimeInputControl.values)
      control: switch (source[control.name]) {
        final String value when value.trim().isNotEmpty => value.trim(),
        _ => throw FormatException('Missing binding for ${control.name}.'),
      },
  };
}

Map<String, String> _encodeBindings(
  Map<RuntimeInputControl, String> source,
) =>
    <String, String>{
      for (final entry in source.entries) entry.key.name: entry.value,
    };

bool _mapsEqual(
  Map<RuntimeInputControl, String> left,
  Map<RuntimeInputControl, String> right,
) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) return false;
  }
  return true;
}
