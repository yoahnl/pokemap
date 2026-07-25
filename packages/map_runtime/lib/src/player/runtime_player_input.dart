import '../session/player_input.dart';

enum RuntimePlayerInputIntentType {
  moveFocus,
  confirm,
  back,
  openMenu,
  activatePointerTarget,
}

enum RuntimePlayerFocusDirection { up, down, left, right }

/// Layout-independent input intent consumed by runtime-owned player surfaces.
final class RuntimePlayerInputIntent {
  const RuntimePlayerInputIntent._({
    required this.type,
    required this.source,
    this.direction,
    this.targetId,
    required this.isPress,
    required this.isRepeat,
  });

  factory RuntimePlayerInputIntent.fromCommand(PlayerInputCommand command) {
    final direction = switch (command.action) {
      PlayerInputAction.up => RuntimePlayerFocusDirection.up,
      PlayerInputAction.down => RuntimePlayerFocusDirection.down,
      PlayerInputAction.left => RuntimePlayerFocusDirection.left,
      PlayerInputAction.right => RuntimePlayerFocusDirection.right,
      _ => null,
    };
    final type = switch (command.action) {
      PlayerInputAction.up ||
      PlayerInputAction.down ||
      PlayerInputAction.left ||
      PlayerInputAction.right =>
        RuntimePlayerInputIntentType.moveFocus,
      PlayerInputAction.confirm => RuntimePlayerInputIntentType.confirm,
      PlayerInputAction.back => RuntimePlayerInputIntentType.back,
      PlayerInputAction.menu => RuntimePlayerInputIntentType.openMenu,
    };
    return RuntimePlayerInputIntent._(
      type: type,
      source: command.source,
      direction: direction,
      isPress: command.isPress,
      isRepeat: command.isRepeat,
    );
  }

  factory RuntimePlayerInputIntent.activatePointerTarget({
    required PlayerInputSource source,
    required String targetId,
  }) {
    if (source != PlayerInputSource.mouse &&
        source != PlayerInputSource.touch) {
      throw ArgumentError.value(
        source,
        'source',
        'must be mouse or touch for pointer activation',
      );
    }
    if (targetId.trim().isEmpty) {
      throw ArgumentError.value(
        targetId,
        'targetId',
        'must identify an interactive player target',
      );
    }
    return RuntimePlayerInputIntent._(
      type: RuntimePlayerInputIntentType.activatePointerTarget,
      source: source,
      targetId: targetId,
      isPress: true,
      isRepeat: false,
    );
  }

  final RuntimePlayerInputIntentType type;
  final PlayerInputSource source;
  final RuntimePlayerFocusDirection? direction;
  final String? targetId;
  final bool isPress;
  final bool isRepeat;
}

/// Input metadata retained independently from responsive widget focus nodes.
final class RuntimePlayerInputState {
  const RuntimePlayerInputState({
    this.activeSource,
    this.logicalSelectionId,
  });

  final PlayerInputSource? activeSource;
  final String? logicalSelectionId;

  RuntimePlayerInputState record(
    RuntimePlayerInputIntent intent, {
    String? logicalSelectionId,
  }) {
    return RuntimePlayerInputState(
      activeSource: intent.source,
      logicalSelectionId: logicalSelectionId ?? this.logicalSelectionId,
    );
  }
}

enum PlayerTouchMenuButtonPresentation { hidden, prominent, subdued }

/// Keeps mobile touch affordances discoverable when a controller is active.
PlayerTouchMenuButtonPresentation playerTouchMenuButtonPresentation({
  required bool touchControlsAvailable,
  required PlayerInputSource? activeSource,
}) {
  if (!touchControlsAvailable) {
    return PlayerTouchMenuButtonPresentation.hidden;
  }
  if (activeSource == PlayerInputSource.controller) {
    return PlayerTouchMenuButtonPresentation.subdued;
  }
  return PlayerTouchMenuButtonPresentation.prominent;
}
