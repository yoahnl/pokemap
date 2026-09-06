import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_runtime/map_runtime.dart';

import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import 'runtime_player_layout.dart';

final class RuntimePlayerLogicalIntent extends Intent {
  const RuntimePlayerLogicalIntent(
    this.action, {
    required this.source,
  });

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
  });

  final VoidCallback onBack;
  final VoidCallback onMenu;
  final ValueChanged<PlayerInputSource> onInputSourceChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowUp): RuntimePlayerLogicalIntent(
          PlayerInputAction.up,
          source: PlayerInputSource.keyboard,
        ),
        SingleActivator(LogicalKeyboardKey.arrowDown):
            RuntimePlayerLogicalIntent(
          PlayerInputAction.down,
          source: PlayerInputSource.keyboard,
        ),
        SingleActivator(LogicalKeyboardKey.arrowLeft):
            RuntimePlayerLogicalIntent(
          PlayerInputAction.left,
          source: PlayerInputSource.keyboard,
        ),
        SingleActivator(LogicalKeyboardKey.arrowRight):
            RuntimePlayerLogicalIntent(
          PlayerInputAction.right,
          source: PlayerInputSource.keyboard,
        ),
        SingleActivator(LogicalKeyboardKey.enter, includeRepeats: false):
            RuntimePlayerLogicalIntent(
          PlayerInputAction.confirm,
          source: PlayerInputSource.keyboard,
        ),
        SingleActivator(LogicalKeyboardKey.enter):
            DoNothingAndStopPropagationIntent(),
        SingleActivator(LogicalKeyboardKey.space, includeRepeats: false):
            RuntimePlayerLogicalIntent(
          PlayerInputAction.confirm,
          source: PlayerInputSource.keyboard,
        ),
        SingleActivator(LogicalKeyboardKey.space):
            DoNothingAndStopPropagationIntent(),
        SingleActivator(LogicalKeyboardKey.escape): RuntimePlayerLogicalIntent(
          PlayerInputAction.back,
          source: PlayerInputSource.keyboard,
        ),
        SingleActivator(LogicalKeyboardKey.keyM): RuntimePlayerLogicalIntent(
          PlayerInputAction.menu,
          source: PlayerInputSource.keyboard,
        ),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          RuntimePlayerLogicalIntent:
              CallbackAction<RuntimePlayerLogicalIntent>(
            onInvoke: _invoke,
          ),
        },
        child: Builder(
          key: const ValueKey<String>('runtime-player-actions-context'),
          builder: (_) => child,
        ),
      ),
    );
  }

  Object? _invoke(RuntimePlayerLogicalIntent intent) {
    onInputSourceChanged(intent.source);
    switch (intent.action) {
      case PlayerInputAction.up:
        FocusManager.instance.primaryFocus
            ?.focusInDirection(TraversalDirection.up);
      case PlayerInputAction.down:
        FocusManager.instance.primaryFocus
            ?.focusInDirection(TraversalDirection.down);
      case PlayerInputAction.left:
        FocusManager.instance.primaryFocus
            ?.focusInDirection(TraversalDirection.left);
      case PlayerInputAction.right:
        FocusManager.instance.primaryFocus
            ?.focusInDirection(TraversalDirection.right);
      case PlayerInputAction.confirm:
        final context = FocusManager.instance.primaryFocus?.context;
        if (context != null) Actions.invoke(context, const ActivateIntent());
      case PlayerInputAction.back:
        onBack();
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
    this.opacity = 0.82,
  }) : assert(opacity >= 0.3 && opacity <= 1);

  final VoidCallback? onPressed;
  final PlayerInputSource? activeInputSource;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (onPressed == null) return const SizedBox.shrink();
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (classifyRuntimePlayerLayout(constraints) ==
              RuntimePlayerLayoutClass.expanded) {
            return const SizedBox.shrink();
          }
          return Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(PlayerSpacing.sm),
              child: AnimatedOpacity(
                opacity: opacity *
                    (activeInputSource == PlayerInputSource.controller
                        ? .42
                        : 1),
                duration: context.playerMotion.fast,
                child: Material(
                  type: MaterialType.transparency,
                  child: IconButton.filled(
                    key: const ValueKey<String>(
                      'runtime-player-touch-menu-open',
                    ),
                    tooltip: context.playerL10n.pause,
                    onPressed: onPressed,
                    constraints: const BoxConstraints.tightFor(
                      width: 56,
                      height: 56,
                    ),
                    icon: const Icon(Icons.menu_rounded),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
