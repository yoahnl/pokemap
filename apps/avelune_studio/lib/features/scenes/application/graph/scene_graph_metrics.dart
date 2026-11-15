abstract final class SceneGraphMetrics {
  static const double cardWidth = 220;
  static const double headerHeight = 28;
  static const double bodyHeight = 44;
  static const double portRowHeight = 22;
  static const double bottomPadding = 8;
  static const double columnGap = 90;
  static const double rowGap = 28;

  static double cardHeight(int outputCount) =>
      headerHeight + bodyHeight + outputCount * portRowHeight + bottomPadding;

  static double outputPortY(int index) =>
      headerHeight + bodyHeight + index * portRowHeight + portRowHeight / 2;

  static const double inputPortY = headerHeight / 2;
}
