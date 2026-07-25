import 'dart:async';

import '../presentation/flame/runtime_input_event.dart';

enum PlayerInputAction { up, down, left, right, confirm, back, menu }

enum PlayerInputSource { keyboard, gamepad, touch }

enum PlayerInputSurface { gameplay, title, pause, result, credits, blocked }

final class PlayerInputCommand {
  const PlayerInputCommand._({
    required this.action,
    required this.source,
    required this.phase,
    required this.isRepeat,
  });

  const PlayerInputCommand.press(
    PlayerInputAction action, {
    required PlayerInputSource source,
    bool isRepeat = false,
  }) : this._(
          action: action,
          source: source,
          phase: RuntimeInputEventPhase.press,
          isRepeat: isRepeat,
        );

  const PlayerInputCommand.release(
    PlayerInputAction action, {
    required PlayerInputSource source,
  }) : this._(
          action: action,
          source: source,
          phase: RuntimeInputEventPhase.release,
          isRepeat: false,
        );

  final PlayerInputAction action;
  final PlayerInputSource source;
  final RuntimeInputEventPhase phase;
  final bool isRepeat;

  bool get isPress => phase == RuntimeInputEventPhase.press;
}

typedef PlayerInputSurfaceReader = PlayerInputSurface Function();
typedef PlayerGameplayInputRoute = bool Function(RuntimeInputEvent event);
typedef PlayerSurfaceInputRoute = FutureOr<void> Function(
  PlayerInputCommand command,
);
typedef PlayerMenuToggle = FutureOr<void> Function();

PlayerInputCommand playerInputCommandFromRuntimeEvent(
  RuntimeInputEvent event, {
  required PlayerInputSource source,
}) {
  final action = switch (event.control) {
    RuntimeInputControl.up => PlayerInputAction.up,
    RuntimeInputControl.down => PlayerInputAction.down,
    RuntimeInputControl.left => PlayerInputAction.left,
    RuntimeInputControl.right => PlayerInputAction.right,
    RuntimeInputControl.primary => PlayerInputAction.confirm,
    RuntimeInputControl.secondary => PlayerInputAction.back,
    RuntimeInputControl.menu => PlayerInputAction.menu,
  };
  return event.isPress
      ? PlayerInputCommand.press(
          action,
          source: source,
          isRepeat: event.isRepeat,
        )
      : PlayerInputCommand.release(action, source: source);
}

/// Single player-input authority above Flame and Flutter player surfaces.
///
/// Menu/Start is intercepted here, so a pause activation can never also reach
/// the world. The same rule applies to title/result/credits navigation.
final class PlayerInputRouter {
  const PlayerInputRouter({
    required PlayerInputSurfaceReader surface,
    required PlayerGameplayInputRoute routeGameplay,
    required PlayerSurfaceInputRoute routeSurface,
    required PlayerMenuToggle toggleMenu,
    required void Function() releaseGameplayDirections,
  })  : _surface = surface,
        _routeGameplay = routeGameplay,
        _routeSurface = routeSurface,
        _toggleMenu = toggleMenu,
        _releaseGameplayDirections = releaseGameplayDirections;

  final PlayerInputSurfaceReader _surface;
  final PlayerGameplayInputRoute _routeGameplay;
  final PlayerSurfaceInputRoute _routeSurface;
  final PlayerMenuToggle _toggleMenu;
  final void Function() _releaseGameplayDirections;

  Future<bool> route(PlayerInputCommand command) async {
    if (command.isRepeat && !_isDirectional(command.action)) {
      return true;
    }
    final surface = _surface();
    if (surface == PlayerInputSurface.blocked) return true;

    if (command.action == PlayerInputAction.menu) {
      if (!command.isPress) return true;
      if (surface == PlayerInputSurface.gameplay ||
          surface == PlayerInputSurface.pause) {
        _releaseGameplayDirections();
        await _toggleMenu();
      }
      return true;
    }

    if (surface == PlayerInputSurface.gameplay) {
      return _routeGameplay(_runtimeEvent(command));
    }

    await _routeSurface(command);
    return true;
  }

  RuntimeInputEvent _runtimeEvent(PlayerInputCommand command) {
    final control = switch (command.action) {
      PlayerInputAction.up => RuntimeInputControl.up,
      PlayerInputAction.down => RuntimeInputControl.down,
      PlayerInputAction.left => RuntimeInputControl.left,
      PlayerInputAction.right => RuntimeInputControl.right,
      PlayerInputAction.confirm => RuntimeInputControl.primary,
      PlayerInputAction.back => RuntimeInputControl.secondary,
      PlayerInputAction.menu => RuntimeInputControl.menu,
    };
    return command.isPress
        ? RuntimeInputEvent.press(control, isRepeat: command.isRepeat)
        : RuntimeInputEvent.release(control);
  }

  bool _isDirectional(PlayerInputAction action) =>
      action == PlayerInputAction.up ||
      action == PlayerInputAction.down ||
      action == PlayerInputAction.left ||
      action == PlayerInputAction.right;
}
