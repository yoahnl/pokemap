import 'package:flutter/widgets.dart';

enum AveluneBreakpointClass { compact, regular, large }

/// Aspect ratio of the console experience, taken from the iPhone preset the
/// approved prototype was captured on (393 x 852).
///
/// The room geometry is portrait and scroll-free by contract, and the credenza
/// scales off the content width, so a landscape window cannot simply stretch it.
/// Surfaces wider than this ratio letterbox the scene instead.
const double kAvelunePortraitAspectRatio = 393 / 852;

abstract final class AveluneBreakpoints {
  static const double minimumContentWidth = 280;
  static const double minimumContentHeight = 480;
  static const double regularMinimumWidth = 350;
  static const double regularMinimumHeight = 700;
  static const double largeMinimumWidth = 410;
  static const double largeMinimumHeight = 820;

  static AveluneBreakpointClass resolve(Size availableSize) {
    if (availableSize.width >= largeMinimumWidth &&
        availableSize.height >= largeMinimumHeight) {
      return AveluneBreakpointClass.large;
    }
    if (availableSize.width >= regularMinimumWidth &&
        availableSize.height >= regularMinimumHeight) {
      return AveluneBreakpointClass.regular;
    }
    return AveluneBreakpointClass.compact;
  }
}
