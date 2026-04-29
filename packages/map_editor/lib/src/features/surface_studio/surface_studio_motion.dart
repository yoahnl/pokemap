import 'package:flutter/animation.dart';

abstract final class SurfaceStudioMotion {
  static const fast = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 180);
  static const panelSlide = Duration(milliseconds: 240);
  static const stepTransition = Duration(milliseconds: 260);
  static const accordion = Duration(milliseconds: 180);
  static const dragFeedback = Duration(milliseconds: 100);

  static const easeOut = Curves.easeOutCubic;
  static const easeInOut = Curves.easeInOutCubic;
}
