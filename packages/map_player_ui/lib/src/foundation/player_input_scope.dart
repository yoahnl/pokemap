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

  @override
  bool updateShouldNotify(PlayerInputScope oldWidget) =>
      activeInputSource != oldWidget.activeInputSource;
}

class PlayerCompanionScope extends InheritedWidget {
  const PlayerCompanionScope({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PlayerCompanionScope>() != null;

  @override
  bool updateShouldNotify(PlayerCompanionScope oldWidget) => false;
}
