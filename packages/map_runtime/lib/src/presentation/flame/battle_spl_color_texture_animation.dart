typedef BattleSplRgb5 = ({int red, int green, int blue});

final class BattleSplColorAnimation {
  BattleSplColorAnimation({
    required this.start,
    required this.middle,
    required this.end,
    required this.fadeIn,
    required this.peak,
    required this.fadeOut,
    required this.interpolate,
  }) {
    if (!_validColor(start) ||
        !_validColor(middle) ||
        !_validColor(end) ||
        fadeIn < 0 ||
        fadeIn > peak ||
        peak > fadeOut ||
        fadeOut > 255) {
      throw const FormatException('Invalid SPL color animation');
    }
  }

  final BattleSplRgb5 start;
  final BattleSplRgb5 middle;
  final BattleSplRgb5 end;
  final int fadeIn;
  final int peak;
  final int fadeOut;
  final bool interpolate;

  BattleSplRgb5 valueAt(int lifeRate) {
    if (lifeRate < 0 || lifeRate > 255) {
      throw ArgumentError.value(lifeRate, 'lifeRate');
    }
    if (lifeRate < fadeIn) return start;
    if (lifeRate < peak) {
      if (!interpolate) return middle;
      return _blend(start, middle, lifeRate - fadeIn, peak - fadeIn);
    }
    if (lifeRate < fadeOut) {
      if (!interpolate) return end;
      return _blend(middle, end, lifeRate - peak, fadeOut - peak);
    }
    return end;
  }

  static bool _validColor(BattleSplRgb5 color) =>
      color.red >= 0 &&
      color.red <= 31 &&
      color.green >= 0 &&
      color.green <= 31 &&
      color.blue >= 0 &&
      color.blue <= 31;

  static BattleSplRgb5 _blend(
    BattleSplRgb5 from,
    BattleSplRgb5 to,
    int elapsed,
    int duration,
  ) => (
    red: from.red + ((to.red - from.red) * elapsed) ~/ duration,
    green: from.green + ((to.green - from.green) * elapsed) ~/ duration,
    blue: from.blue + ((to.blue - from.blue) * elapsed) ~/ duration,
  );
}

final class BattleSplTextureAnimation {
  BattleSplTextureAnimation({required List<int> textures, required this.step})
    : textures = List.unmodifiable(textures) {
    if (textures.isEmpty ||
        textures.length > 8 ||
        textures.any((value) => value < 0 || value > 255) ||
        step < 0 ||
        step > 255) {
      throw const FormatException('Invalid SPL texture animation');
    }
  }

  final List<int> textures;
  final int step;

  int valueAt({required int lifeRate, required int previousTexture}) {
    if (lifeRate < 0 || lifeRate > 255) {
      throw ArgumentError.value(lifeRate, 'lifeRate');
    }
    if (previousTexture < 0 || previousTexture > 255) {
      throw ArgumentError.value(previousTexture, 'previousTexture');
    }
    for (var index = 0; index < textures.length; index++) {
      if (lifeRate < step * (index + 1)) return textures[index];
    }
    return previousTexture;
  }
}
