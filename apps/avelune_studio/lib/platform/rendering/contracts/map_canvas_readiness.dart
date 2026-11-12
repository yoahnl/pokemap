import 'dart:async';

import 'package:flutter/widgets.dart';

final class MapCanvasReadiness {
  MapCanvasReadiness({required this.onReady, required this.onFailed});

  final VoidCallback onReady;
  final ValueChanged<Object> onFailed;
  var _claimed = false;

  bool get claimed => _claimed;

  void claim() => _claimed = true;

  void ready() => scheduleMicrotask(onReady);

  void fail(Object failure) => scheduleMicrotask(() => onFailed(failure));
}

class MapCanvasReadinessScope extends InheritedWidget {
  const MapCanvasReadinessScope({
    super.key,
    required this.readiness,
    required super.child,
  });

  final MapCanvasReadiness readiness;

  static MapCanvasReadiness? maybeOf(BuildContext context) => context
      .getInheritedWidgetOfExactType<MapCanvasReadinessScope>()
      ?.readiness;

  @override
  bool updateShouldNotify(MapCanvasReadinessScope oldWidget) =>
      !identical(readiness, oldWidget.readiness);
}
