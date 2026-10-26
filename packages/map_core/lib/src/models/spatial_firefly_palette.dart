enum SpatialFireflyColor {
  yellow(0xffef96),
  green(0xb8efcb),
  blue(0xbddfff),
  pink(0xf2c8e5);

  const SpatialFireflyColor(this.rgb);
  final int rgb;
}

SpatialFireflyColor? spatialFireflyColor({
  required int seed,
  required int index,
  double yellow = 1,
  double green = 0,
  double blue = 0,
  double pink = 0,
}) {
  final weights = [yellow, green, blue, pink];
  if (weights.any((value) => !value.isFinite || value < 0 || value > 1)) {
    throw const FormatException('Invalid firefly palette weight.');
  }
  final total = weights.fold<double>(0, (a, b) => a + b);
  if (total == 0) return null;
  var hash = (seed ^ (index * 0x9e3779b9)) & 0xffffffff;
  hash = ((hash ^ (hash >> 16)) * 0x85ebca6b) & 0xffffffff;
  hash = ((hash ^ (hash >> 13)) * 0xc2b2ae35) & 0xffffffff;
  hash ^= hash >> 16;
  var fraction = hash / 0x100000000 * total;
  for (var i = 0; i < weights.length; i++) {
    fraction -= weights[i];
    if (fraction < 0) return SpatialFireflyColor.values[i];
  }
  return SpatialFireflyColor.values.lastWhere(
    (color) => weights[color.index] > 0,
  );
}
