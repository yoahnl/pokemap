import 'package:flutter/widgets.dart';
import 'package:map_runtime/map_runtime.dart';

class PlayerInputScope extends InheritedWidget {
  const PlayerInputScope({
    super.key,
    required this.activeInputSource,
    required super.child,
  });

  final PlayerInputSource? activeInputSource;

  static PlayerInputSource of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<PlayerInputScope>()
          ?.activeInputSource ??
      PlayerInputSource.touch;

  static bool usesController(BuildContext context) => switch (of(context)) {
    PlayerInputSource.controller || PlayerInputSource.keyboard => true,
    _ => false,
  };

  static bool usesKeyboard(
    BuildContext context, {
    PlayerInputSource? fallback,
  }) =>
      (context
              .dependOnInheritedWidgetOfExactType<PlayerInputScope>()
              ?.activeInputSource ??
          fallback ??
          PlayerInputSource.touch) ==
      PlayerInputSource.keyboard;

  @override
  bool updateShouldNotify(PlayerInputScope oldWidget) =>
      activeInputSource != oldWidget.activeInputSource;
}

class PlayerCompanionScope extends InheritedWidget {
  const PlayerCompanionScope({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PlayerCompanionScope>() !=
      null;

  @override
  bool updateShouldNotify(PlayerCompanionScope oldWidget) => false;
}

class PlayerHardwareInputScope extends InheritedTheme {
  const PlayerHardwareInputScope({
    super.key,
    required this.route,
    required super.child,
  });

  final KeyEventResult Function(KeyEvent event) route;

  static PlayerHardwareInputScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PlayerHardwareInputScope>();

  @override
  Widget wrap(BuildContext context, Widget child) =>
      PlayerHardwareInputScope(route: route, child: child);

  @override
  bool updateShouldNotify(PlayerHardwareInputScope oldWidget) =>
      route != oldWidget.route;
}
