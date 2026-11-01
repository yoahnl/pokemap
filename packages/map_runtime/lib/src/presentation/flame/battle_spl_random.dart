final class BattleSplRandom {
  BattleSplRandom({required int seed}) : _state = seed {
    if (seed < 0 || seed > 0xffffffff) {
      throw const FormatException('Invalid SPL random seed');
    }
  }

  int _state;

  int get state => _state;

  int next() {
    final low = _state % 65536;
    final high = _state ~/ 65536;
    final lowProduct = low * 0xf715 + 0xb173;
    final highProduct =
        high * 0xf715 + low * 0x5eed + 0x1b0c + lowProduct ~/ 65536;
    _state = (highProduct % 65536) * 65536 + lowProduct % 65536;
    return _state;
  }

  int fixedPoint({required int bits}) {
    if (bits < 1 || bits > 32) throw ArgumentError.value(bits, 'bits');
    final value = next();
    final signed = value >= 0x80000000 ? value - 0x100000000 : value;
    return _signedShiftRight(signed, 32 - bits);
  }

  int vary(int value, {required int variance}) {
    if (value < -2147483648 || value > 2147483647) {
      throw ArgumentError.value(value, 'value');
    }
    if (variance < 0 || variance > 255) {
      throw ArgumentError.value(variance, 'variance');
    }
    final factor = 255 + variance - ((variance * (next() >> 24)) >> 7);
    final product = value * factor;
    if (product < -2147483648 || product > 2147483647) {
      throw const FormatException('SPL random variance overflows 32 bits');
    }
    return _signedShiftRight(product, 8);
  }

  int range(int magnitude) {
    if (magnitude < 0 || magnitude > 4202512) {
      throw ArgumentError.value(magnitude, 'magnitude');
    }
    return _signedShiftRight(magnitude * (next() >> 23) - magnitude * 256, 8);
  }

  static int _signedShiftRight(int value, int bits) {
    var divisor = 1;
    for (var index = 0; index < bits; index++) {
      divisor *= 2;
    }
    return value >= 0 ? value ~/ divisor : -((-value + divisor - 1) ~/ divisor);
  }
}
