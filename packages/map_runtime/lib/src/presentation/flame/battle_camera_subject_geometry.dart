import 'dart:ui';

final class BattleCameraSubjectGeometry {
  const BattleCameraSubjectGeometry({
    required this.foot,
    required this.bounds,
    required this.focusAnchor,
    this.animationEnvelope,
  });

  final Offset foot;
  final Rect bounds;
  final Offset focusAnchor;
  final Rect? animationEnvelope;

  Rect get framingBounds => animationEnvelope == null
      ? bounds
      : bounds.expandToInclude(animationEnvelope!);

  bool get isValid =>
      foot.dx.isFinite &&
      foot.dy.isFinite &&
      focusAnchor.dx.isFinite &&
      focusAnchor.dy.isFinite &&
      _validRect(bounds) &&
      _validRect(framingBounds);

  static bool _validRect(Rect value) =>
      value.left.isFinite &&
      value.top.isFinite &&
      value.right.isFinite &&
      value.bottom.isFinite &&
      !value.isEmpty;
}
