const String borderRleV1Prefix = 'border-rle-v1:';
const int borderRleMaxDimension = 8192;
const int borderRleMaxDecodedCells = 67108864;

const String _borderRleVersionStem = 'border-rle-';
const int _asciiZero = 0x30;
const int _asciiNine = 0x39;
const int _colon = 0x3a;
const int _comma = 0x2c;

/// Validates V1 mask dimensions and returns their decoded cell count.
///
/// Dimensions are deliberately checked before multiplication so hostile or
/// corrupt input cannot make the product escape the V1 allocation bound.
int checkedBorderRleCellCount({
  required int width,
  required int height,
  String path = r'$',
}) {
  if (width < 1 || width > borderRleMaxDimension) {
    throw FormatException(
      '$path.width: must be between 1 and $borderRleMaxDimension',
    );
  }
  if (height < 1 || height > borderRleMaxDimension) {
    throw FormatException(
      '$path.height: must be between 1 and $borderRleMaxDimension',
    );
  }
  if (width > borderRleMaxDecodedCells ~/ height) {
    throw FormatException(
      '$path: dimensions exceed the Border RLE V1 decoded-cell limit',
    );
  }
  return width * height;
}

/// Encodes a row-major boolean mask using the canonical Border RLE V1 form.
String encodeBorderRleMask(List<bool> mask) {
  final length = mask.length;
  _checkExpectedLength(length, argumentName: 'mask.length');
  if (length == 0) {
    return '${borderRleV1Prefix}0:0:';
  }

  var current = mask[0];
  var runLength = 1;
  final output = StringBuffer()
    ..write(borderRleV1Prefix)
    ..write(length)
    ..write(':')
    ..write(current ? '1' : '0')
    ..write(':');

  for (var index = 1; index < length; index += 1) {
    final value = mask[index];
    if (value == current) {
      runLength += 1;
      continue;
    }
    output
      ..write(runLength)
      ..write(',');
    current = value;
    runLength = 1;
  }
  output.write(runLength);
  return output.toString();
}

/// Validates [value] as a canonical, bounded Border RLE V1 mask.
///
/// Validation does not allocate a decoded mask or a list of runs. The parser
/// scans ASCII code units once and accumulates only bounded integers.
void validateBorderRleMask(
  Object? value, {
  required int expectedLength,
  String path = r'$',
}) {
  _checkExpectedLength(expectedLength);
  if (value is! String) {
    _fail(path, 'expected a Border RLE V1 string');
  }
  _validateVersionPrefix(value, path);
  if (value.length > _maximumEncodedLength(expectedLength)) {
    _fail(path, 'Border RLE input is disproportionate to its decoded length');
  }
  _validateBorderRleV1(value, expectedLength: expectedLength, path: path);
}

/// Validates a canonical mask and reports whether it contains a filled cell.
///
/// Unlike [decodeBorderRleMask], this scans without allocating the decoded
/// boolean list. A non-empty canonical RLE alternates positive runs, so its
/// first bit and the presence of a second run are sufficient after validation.
bool borderRleMaskHasTrue(
  Object? value, {
  required int expectedLength,
  String path = r'$',
}) {
  validateBorderRleMask(
    value,
    expectedLength: expectedLength,
    path: path,
  );
  if (expectedLength == 0) {
    return false;
  }

  final encoded = value as String;
  final lengthSeparator = encoded.indexOf(
    ':',
    borderRleV1Prefix.length,
  );
  final firstBitIndex = lengthSeparator + 1;
  if (encoded.codeUnitAt(firstBitIndex) == _asciiZero + 1) {
    return true;
  }
  final runsStart = firstBitIndex + 2;
  return encoded.indexOf(',', runsStart) >= 0;
}

/// Decodes a canonical Border RLE V1 mask after validating it in full.
///
/// The result is allocated exactly once after validation. A second incremental
/// scan fills it directly, without retaining an intermediate run list.
List<bool> decodeBorderRleMask(
  Object? value, {
  required int expectedLength,
  String path = r'$',
}) {
  validateBorderRleMask(
    value,
    expectedLength: expectedLength,
    path: path,
  );
  final encoded = value as String;
  final decoded = List<bool>.filled(
    expectedLength,
    false,
    growable: false,
  );
  if (expectedLength == 0) {
    return decoded;
  }

  _fillBorderRleV1(
    encoded,
    decoded,
    expectedLength: expectedLength,
    path: path,
  );
  return decoded;
}

/// Visits the half-open row-major runs whose decoded value is `true`.
///
/// The canonical payload is validated before callbacks begin. The second scan
/// retains no decoded mask and therefore keeps structural projections bounded
/// independently from the mask area.
void visitBorderRleTrueRuns(
  Object? value, {
  required int expectedLength,
  required void Function(int startInclusive, int endExclusive) visitor,
  String path = r'$',
}) {
  validateBorderRleMask(
    value,
    expectedLength: expectedLength,
    path: path,
  );
  if (expectedLength == 0) {
    return;
  }
  _scanBorderRleV1(
    value as String,
    expectedLength: expectedLength,
    path: path,
    trueRunVisitor: visitor,
  );
}

void _validateBorderRleV1(
  String encoded, {
  required int expectedLength,
  required String path,
}) {
  _scanBorderRleV1(
    encoded,
    expectedLength: expectedLength,
    path: path,
  );
}

void _fillBorderRleV1(
  String encoded,
  List<bool> decoded, {
  required int expectedLength,
  required String path,
}) {
  _scanBorderRleV1(
    encoded,
    expectedLength: expectedLength,
    path: path,
    decoded: decoded,
  );
}

void _scanBorderRleV1(
  String encoded, {
  required int expectedLength,
  required String path,
  List<bool>? decoded,
  void Function(int startInclusive, int endExclusive)? trueRunVisitor,
}) {
  var index = borderRleV1Prefix.length;
  var declaredLength = 0;
  var declaredDigitCount = 0;
  while (index < encoded.length) {
    final codeUnit = encoded.codeUnitAt(index);
    if (codeUnit == _colon) {
      break;
    }
    if (codeUnit < _asciiZero || codeUnit > _asciiNine) {
      _fail(path, 'decoded length must be a canonical ASCII decimal');
    }
    if (declaredDigitCount == 0 && codeUnit == _asciiZero) {
      if (index + 1 < encoded.length &&
          encoded.codeUnitAt(index + 1) != _colon) {
        _fail(path, 'decoded length cannot contain leading zeros');
      }
    }
    final digit = codeUnit - _asciiZero;
    if (declaredLength > (borderRleMaxDecodedCells - digit) ~/ 10) {
      _fail(path, 'decoded length exceeds the Border RLE V1 limit');
    }
    declaredLength = declaredLength * 10 + digit;
    declaredDigitCount += 1;
    index += 1;
  }
  if (declaredDigitCount == 0) {
    _fail(path, 'missing decoded length');
  }
  if (index == encoded.length) {
    _fail(path, 'missing separator after decoded length');
  }
  index += 1;
  if (declaredLength != expectedLength) {
    _fail(path, 'decoded length does not match the expected length');
  }

  if (index >= encoded.length) {
    _fail(path, 'missing first-bit field');
  }
  final firstBitCode = encoded.codeUnitAt(index);
  if (firstBitCode != _asciiZero && firstBitCode != _asciiZero + 1) {
    _fail(path, 'first bit must be exactly 0 or 1');
  }
  final firstValue = firstBitCode == _asciiZero + 1;
  index += 1;
  if (index >= encoded.length || encoded.codeUnitAt(index) != _colon) {
    _fail(path, 'first bit must be exactly one digit followed by a colon');
  }
  index += 1;

  if (expectedLength == 0) {
    if (firstValue || index != encoded.length) {
      _fail(
          path, 'empty masks must use the exact form ${borderRleV1Prefix}0:0:');
    }
    return;
  }
  if (index >= encoded.length) {
    _fail(path, 'a non-empty mask requires at least one positive run');
  }

  var filled = 0;
  var value = firstValue;
  while (true) {
    var runLength = 0;
    var runDigitCount = 0;
    while (index < encoded.length) {
      final codeUnit = encoded.codeUnitAt(index);
      if (codeUnit == _comma) {
        break;
      }
      if (codeUnit < _asciiZero || codeUnit > _asciiNine) {
        _fail(path, 'run length must be a canonical ASCII decimal');
      }
      if (runDigitCount == 0 && codeUnit == _asciiZero) {
        if (index + 1 < encoded.length &&
            encoded.codeUnitAt(index + 1) != _comma) {
          _fail(path, 'run length cannot contain leading zeros');
        }
      }
      final digit = codeUnit - _asciiZero;
      if (runLength > (expectedLength - digit) ~/ 10) {
        _fail(path, 'run length exceeds the Border RLE V1 limit');
      }
      runLength = runLength * 10 + digit;
      runDigitCount += 1;
      index += 1;
    }
    if (runDigitCount == 0) {
      _fail(path, 'missing run length');
    }
    if (runLength == 0) {
      _fail(path, 'run length must be positive');
    }
    if (runLength > expectedLength - filled) {
      _fail(path, 'run lengths overfill the decoded mask');
    }
    final end = filled + runLength;
    if (value) {
      trueRunVisitor?.call(filled, end);
    }
    if (decoded != null) {
      for (var decodedIndex = filled; decodedIndex < end; decodedIndex += 1) {
        decoded[decodedIndex] = value;
      }
    }
    filled = end;
    if (index == encoded.length) {
      break;
    }
    index += 1;
    if (index >= encoded.length) {
      _fail(path, 'run list cannot end with a separator');
    }
    value = !value;
  }

  if (filled != expectedLength) {
    _fail(path, 'run lengths underfill the decoded mask');
  }
}

void _validateVersionPrefix(String value, String path) {
  if (value.startsWith(borderRleV1Prefix)) {
    return;
  }
  if (value.startsWith(_borderRleVersionStem)) {
    _fail(path, 'unsupported Border RLE version');
  }
  _fail(path, 'expected a Border RLE V1 string');
}

int _maximumEncodedLength(int expectedLength) {
  if (expectedLength == 0) {
    return borderRleV1Prefix.length + 4; // `0:0:`
  }
  final decimalDigits = _decimalDigitCount(expectedLength);
  final longestRunList = expectedLength * 2 - 1; // `1,1,...,1`
  return borderRleV1Prefix.length +
      decimalDigits +
      3 + // `:<firstBit>:`
      longestRunList;
}

int _decimalDigitCount(int value) {
  if (value < 10) return 1;
  if (value < 100) return 2;
  if (value < 1000) return 3;
  if (value < 10000) return 4;
  if (value < 100000) return 5;
  if (value < 1000000) return 6;
  if (value < 10000000) return 7;
  return 8;
}

void _checkExpectedLength(
  int expectedLength, {
  String argumentName = 'expectedLength',
}) {
  if (expectedLength < 0 || expectedLength > borderRleMaxDecodedCells) {
    throw ArgumentError.value(
      expectedLength,
      argumentName,
      'must be between 0 and $borderRleMaxDecodedCells',
    );
  }
}

Never _fail(String path, String message) {
  throw FormatException('$path: $message');
}
