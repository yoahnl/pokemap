import 'package:flame/components.dart';
import 'dart:ui' show Rect;

typedef BattleLivePointResolver = Vector2? Function();
typedef BattleLiveRectResolver = Rect? Function();

typedef BattleBallLivePlacement = ({Vector2 targetCenter, double throwStartX, double cellSize});

abstract interface class BattleLiveAttachment {
  bool refreshAttachment();
}

void removeBattleLiveAttachment(Component component) {
  Future<void>.microtask(() {
    if (!component.isRemoving && !component.isRemoved) component.removeFromParent();
  });
}

bool refreshBattleLivePoint(BattleLivePointResolver? resolver, Vector2 point) {
  if (resolver == null) return true;
  final resolved = resolver();
  if (resolved == null || !resolved.x.isFinite || !resolved.y.isFinite) return false;
  point.setFrom(resolved);
  return true;
}

BattleLivePointResolver offsetBattleLivePoint(BattleLivePointResolver resolver, Vector2 offset) {
  final local = offset.clone();
  final point = Vector2.zero();
  return () {
    final anchor = resolver();
    if (anchor == null) return null;
    point.setValues(anchor.x + local.x, anchor.y + local.y);
    return point;
  };
}
