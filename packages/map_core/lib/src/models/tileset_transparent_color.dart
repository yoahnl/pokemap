/// RGB color configured as transparent for a tileset.
final class TilesetTransparentColor {
  factory TilesetTransparentColor({
    required int red,
    required int green,
    required int blue,
  }) {
    _validateChannel(red, 'red');
    _validateChannel(green, 'green');
    _validateChannel(blue, 'blue');
    return TilesetTransparentColor._(red: red, green: green, blue: blue);
  }

  factory TilesetTransparentColor.fromHexRgb(String value) {
    final hex = value.startsWith('#') ? value.substring(1) : value;
    if (hex.length != 6 || !_isHexRgb(hex)) {
      throw ArgumentError.value(
        value,
        'value',
        'TilesetTransparentColor hex RGB must contain exactly '
            '6 hexadecimal characters.',
      );
    }

    return TilesetTransparentColor(
      red: int.parse(hex.substring(0, 2), radix: 16),
      green: int.parse(hex.substring(2, 4), radix: 16),
      blue: int.parse(hex.substring(4, 6), radix: 16),
    );
  }

  const TilesetTransparentColor._({
    required this.red,
    required this.green,
    required this.blue,
  });

  final int red;
  final int green;
  final int blue;

  String toHexRgb() {
    return _toHexChannel(red) + _toHexChannel(green) + _toHexChannel(blue);
  }

  bool matchesRgb({
    required int red,
    required int green,
    required int blue,
  }) {
    return this.red == red && this.green == green && this.blue == blue;
  }

  bool matchesArgb32(int argb) {
    final rgb = argb & 0x00ffffff;
    final red = (rgb >> 16) & 0xff;
    final green = (rgb >> 8) & 0xff;
    final blue = rgb & 0xff;
    return matchesRgb(red: red, green: green, blue: blue);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TilesetTransparentColor &&
            red == other.red &&
            green == other.green &&
            blue == other.blue;
  }

  @override
  int get hashCode => Object.hash(red, green, blue);
}

void _validateChannel(int value, String name) {
  if (value < 0 || value > 255) {
    throw ArgumentError.value(
      value,
      name,
      'TilesetTransparentColor $name must be between 0 and 255.',
    );
  }
}

bool _isHexRgb(String value) {
  for (var index = 0; index < value.length; index += 1) {
    final codeUnit = value.codeUnitAt(index);
    final isDigit = codeUnit >= 0x30 && codeUnit <= 0x39;
    final isUppercaseHex = codeUnit >= 0x41 && codeUnit <= 0x46;
    final isLowercaseHex = codeUnit >= 0x61 && codeUnit <= 0x66;
    if (!isDigit && !isUppercaseHex && !isLowercaseHex) {
      return false;
    }
  }
  return true;
}

String _toHexChannel(int value) {
  return value.toRadixString(16).padLeft(2, '0');
}
