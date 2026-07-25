import 'package:flutter/rendering.dart';

enum RuntimePlayerLayoutClass {
  compactPortrait,
  compactLandscape,
  expanded,
}

/// Classifies the actual Flutter viewport without platform assumptions.
RuntimePlayerLayoutClass classifyRuntimePlayerLayout(
  BoxConstraints constraints,
) {
  final width = constraints.maxWidth;
  final height = constraints.maxHeight;
  if (width >= 900 && height >= 560) {
    return RuntimePlayerLayoutClass.expanded;
  }
  if (height >= width * 1.1) {
    return RuntimePlayerLayoutClass.compactPortrait;
  }
  return RuntimePlayerLayoutClass.compactLandscape;
}
