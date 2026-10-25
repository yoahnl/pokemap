import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_runtime/map_runtime.dart';

import '../localization/player_localizations.dart';
import '../foundation/player_input_scope.dart';
import '../foundation/player_paged_layout.dart';
import '../foundation/player_overworld_components.dart';
import '../theme/pokemap_player_overworld_theme.dart';
import 'player_control_profile.dart';

final class RuntimePlayerLocalActionNotification extends Notification {}

final class RuntimePlayerInputSourceNotification extends Notification {
  RuntimePlayerInputSourceNotification(this.source);
  final PlayerInputSource source;
}

class RuntimePlayerInputBindings extends StatefulWidget {
  const RuntimePlayerInputBindings({
    super.key,
    required this.child,
    this.controlProfile,
    this.hardwareGamepadEnabled = true,
  });

  final Widget child;
  final PlayerControlProfile? controlProfile;
  final bool hardwareGamepadEnabled;

  static bool hasOwner(BuildContext context) =>
      context.findAncestorStateOfType<_RuntimePlayerInputBindingsState>() !=
      null;

  @override
  State<RuntimePlayerInputBindings> createState() =>
      _RuntimePlayerInputBindingsState();
}

class _RuntimePlayerInputBindingsState
    extends State<RuntimePlayerInputBindings> {
  @override
  void initState() {
    super.initState();
    FocusManager.instance.addEarlyKeyEventHandler(_routeKeyEvent);
  }

  @override
  void dispose() {
    FocusManager.instance.removeEarlyKeyEventHandler(_routeKeyEvent);
    super.dispose();
  }

  KeyEventResult _routeKeyEvent(KeyEvent event) {
    final target = FocusManager.instance.primaryFocus?.context;
    if (!mounted ||
        target == null ||
        target.findAncestorStateOfType<_RuntimePlayerInputBindingsState>() !=
            this) {
      return KeyEventResult.ignored;
    }
    if (event.deviceType != ui.KeyEventDeviceType.gamepad &&
        (target.widget is EditableText ||
            target.findAncestorWidgetOfExactType<EditableText>() != null)) {
      return KeyEventResult.ignored;
    }
    final input = (widget.controlProfile ?? PlayerControlProfile.standard)
        .runtimeEventFromKeyEvent(event);
    if (input != null &&
        (input.control == RuntimeInputControl.previousTab ||
            input.control == RuntimeInputControl.nextTab) &&
        target.findAncestorWidgetOfExactType<RuntimePlayerTabActions>() ==
            null) {
      return KeyEventResult.ignored;
    }
    final authority = PlayerHardwareInputScope.maybeOf(context);
    if (authority != null) return authority.route(event);
    if (!widget.hardwareGamepadEnabled &&
        event.deviceType == ui.KeyEventDeviceType.gamepad) {
      return KeyEventResult.handled;
    }
    if (input == null ||
        Actions.maybeFind<RuntimePlayerLogicalIntent>(target) == null) {
      return KeyEventResult.ignored;
    }
    final source = event.deviceType == ui.KeyEventDeviceType.gamepad
        ? PlayerInputSource.controller
        : PlayerInputSource.keyboard;
    final command = playerInputCommandFromRuntimeEvent(input, source: source);
    final directional = switch (command.action) {
      PlayerInputAction.up ||
      PlayerInputAction.down ||
      PlayerInputAction.left ||
      PlayerInputAction.right => true,
      _ => false,
    };
    if (command.isPress && (!command.isRepeat || directional)) {
      Actions.invoke(
        target,
        RuntimePlayerLogicalIntent(command.action, source: source),
      );
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) =>
      Focus(skipTraversal: true, child: widget.child);
}

final class RuntimePlayerLogicalIntent extends Intent {
  const RuntimePlayerLogicalIntent(this.action, {required this.source});

  final PlayerInputAction action;
  final PlayerInputSource source;
}

/// Shared keyboard and logical-controller action layer for player surfaces.
class RuntimePlayerActions extends StatelessWidget {
  const RuntimePlayerActions({
    super.key,
    required this.onBack,
    required this.onMenu,
    required this.onInputSourceChanged,
    required this.child,
    this.includeDefaultKeyboardShortcuts = true,
    this.onPreviousTab,
    this.onNextTab,
  });

  final VoidCallback onBack;
  final VoidCallback onMenu;
  final ValueChanged<PlayerInputSource> onInputSourceChanged;
  final Widget child;
  final bool includeDefaultKeyboardShortcuts;
  final VoidCallback? onPreviousTab;
  final VoidCallback? onNextTab;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<RuntimePlayerInputSourceNotification>(
      onNotification: (notification) {
        onInputSourceChanged(notification.source);
        return false;
      },
      child: Shortcuts(
        shortcuts: includeDefaultKeyboardShortcuts
            ? const <ShortcutActivator, Intent>{
                SingleActivator(
                  LogicalKeyboardKey.arrowUp,
                ): RuntimePlayerLogicalIntent(
                  PlayerInputAction.up,
                  source: PlayerInputSource.keyboard,
                ),
                SingleActivator(
                  LogicalKeyboardKey.arrowDown,
                ): RuntimePlayerLogicalIntent(
                  PlayerInputAction.down,
                  source: PlayerInputSource.keyboard,
                ),
                SingleActivator(
                  LogicalKeyboardKey.arrowLeft,
                ): RuntimePlayerLogicalIntent(
                  PlayerInputAction.left,
                  source: PlayerInputSource.keyboard,
                ),
                SingleActivator(
                  LogicalKeyboardKey.arrowRight,
                ): RuntimePlayerLogicalIntent(
                  PlayerInputAction.right,
                  source: PlayerInputSource.keyboard,
                ),
                SingleActivator(
                  LogicalKeyboardKey.enter,
                  includeRepeats: false,
                ): RuntimePlayerLogicalIntent(
                  PlayerInputAction.confirm,
                  source: PlayerInputSource.keyboard,
                ),
                SingleActivator(LogicalKeyboardKey.enter):
                    DoNothingAndStopPropagationIntent(),
                SingleActivator(
                  LogicalKeyboardKey.space,
                  includeRepeats: false,
                ): RuntimePlayerLogicalIntent(
                  PlayerInputAction.confirm,
                  source: PlayerInputSource.keyboard,
                ),
                SingleActivator(LogicalKeyboardKey.space):
                    DoNothingAndStopPropagationIntent(),
                SingleActivator(
                  LogicalKeyboardKey.escape,
                ): RuntimePlayerLogicalIntent(
                  PlayerInputAction.back,
                  source: PlayerInputSource.keyboard,
                ),
                SingleActivator(
                  LogicalKeyboardKey.keyM,
                ): RuntimePlayerLogicalIntent(
                  PlayerInputAction.menu,
                  source: PlayerInputSource.keyboard,
                ),
              }
            : const <ShortcutActivator, Intent>{},
        child: Actions(
          actions: <Type, Action<Intent>>{
            RuntimePlayerLogicalIntent:
                CallbackAction<RuntimePlayerLogicalIntent>(onInvoke: _invoke),
          },
          child: Builder(
            key: const ValueKey<String>('runtime-player-actions-context'),
            builder: (_) => child,
          ),
        ),
      ),
    );
  }

  Object? _invoke(RuntimePlayerLogicalIntent intent) {
    onInputSourceChanged(intent.source);
    switch (intent.action) {
      case PlayerInputAction.up:
        FocusManager.instance.primaryFocus?.focusInDirection(
          TraversalDirection.up,
        );
      case PlayerInputAction.down:
        FocusManager.instance.primaryFocus?.focusInDirection(
          TraversalDirection.down,
        );
      case PlayerInputAction.left:
        FocusManager.instance.primaryFocus?.focusInDirection(
          TraversalDirection.left,
        );
      case PlayerInputAction.right:
        FocusManager.instance.primaryFocus?.focusInDirection(
          TraversalDirection.right,
        );
      case PlayerInputAction.confirm:
        final context = FocusManager.instance.primaryFocus?.context;
        if (context != null) Actions.invoke(context, const ActivateIntent());
      case PlayerInputAction.back:
        onBack();
      case PlayerInputAction.previousTab:
        onPreviousTab?.call();
      case PlayerInputAction.nextTab:
        onNextTab?.call();
      case PlayerInputAction.bicycle:
      case PlayerInputAction.sprint:
        break;
      case PlayerInputAction.menu:
        onMenu();
    }
    return null;
  }
}

/// Compact-only touch affordance for opening the runtime pause menu.
class RuntimePlayerTouchMenuButton extends StatelessWidget {
  const RuntimePlayerTouchMenuButton({
    super.key,
    required this.onPressed,
    this.activeInputSource,
    this.hitRegionKey,
    this.actionCapsule,
    this.opacity = 0.82,
  }) : assert(opacity >= 0.3 && opacity <= 1);

  final VoidCallback? onPressed;
  final PlayerInputSource? activeInputSource;
  final double opacity;
  final GlobalKey? hitRegionKey;
  final Widget? actionCapsule;

  @override
  Widget build(BuildContext context) {
    if (onPressed == null && actionCapsule == null)
      return const SizedBox.shrink();
    return Opacity(
      opacity: context.playerOverworldTheme.opaque ? 1 : opacity,
      child: PlayerOverworldControlsLayout(
        actionCapsule: actionCapsule,
        menuButton: SizedBox(
          key: hitRegionKey,
          child: PlayerOverworldMenuButton(
            key: const ValueKey('runtime-player-touch-menu-open'),
            label: context.playerL10n.menu,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}

class RuntimePlayerTabActions extends StatelessWidget {
  const RuntimePlayerTabActions({
    super.key,
    required this.onPreviousTab,
    required this.onNextTab,
    required this.child,
    this.resetToken,
  });

  final Object? resetToken;
  final VoidCallback onPreviousTab;
  final VoidCallback onNextTab;
  final Widget child;

  @override
  Widget build(BuildContext context) => Actions(
    actions: {
      RuntimePlayerLogicalIntent: CallbackAction<RuntimePlayerLogicalIntent>(
        onInvoke: (intent) {
          if (intent.action == PlayerInputAction.previousTab) {
            RuntimePlayerInputSourceNotification(intent.source)
                .dispatch(context);
            onPreviousTab();
            return null;
          }
          if (intent.action == PlayerInputAction.nextTab) {
            RuntimePlayerInputSourceNotification(intent.source)
                .dispatch(context);
            onNextTab();
            return null;
          }
          return Actions.maybeInvoke(context, intent);
        },
      ),
    },
    child: PlayerHorizontalSwipeRegion(
      resetToken: resetToken,
      onPrevious: () {
        RuntimePlayerInputSourceNotification(PlayerInputSource.touch)
            .dispatch(context);
        onPreviousTab();
      },
      onNext: () {
        RuntimePlayerInputSourceNotification(PlayerInputSource.touch)
            .dispatch(context);
        onNextTab();
      },
      child: child,
    ),
  );
}
