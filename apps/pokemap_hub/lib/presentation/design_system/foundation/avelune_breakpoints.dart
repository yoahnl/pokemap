import 'package:flutter/widgets.dart';

enum AveluneBreakpointClass { compact, regular, large }

abstract final class AveluneBreakpoints {
  static const double minimumContentWidth = 280;
  static const double minimumContentHeight = 480;
  static const double minimumLandscapeContentWidth = 480;
  static const double minimumLandscapeContentHeight = 280;
  static const double landscapeMinimumAspectRatio = 1.2;
  static const double regularMinimumWidth = 350;
  static const double regularMinimumHeight = 700;
  static const double largeMinimumWidth = 410;
  static const double largeMinimumHeight = 820;

  static bool usesLandscapeLayout(Size availableSize) =>
      availableSize.width / availableSize.height >= landscapeMinimumAspectRatio;

  static bool supports(Size availableSize) =>
      usesLandscapeLayout(availableSize)
          ? availableSize.width >= minimumLandscapeContentWidth &&
              availableSize.height >= minimumLandscapeContentHeight
          : availableSize.width >= minimumContentWidth &&
              availableSize.height >= minimumContentHeight;

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
