import 'dart:collection';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Border RLE V1 constants and dimensions', () {
    test('exposes the bounded V1 wire limits', () {
      expect(borderRleV1Prefix, 'border-rle-v1:');
      expect(borderRleMaxDimension, 8192);
      expect(borderRleMaxDecodedCells, 67108864);
    });

    test('checks dimensions and their overflow-safe product', () {
      expect(checkedBorderRleCellCount(width: 1, height: 1), 1);
      expect(
        checkedBorderRleCellCount(width: 8192, height: 8192),
        borderRleMaxDecodedCells,
      );
    });

    test('rejects dimensions outside the closed V1 bounds', () {
      for (final width in <int>[-1, 0, 8193]) {
        expect(
          () => checkedBorderRleCellCount(width: width, height: 1),
          _formatExceptionAt(r'$.width'),
          reason: 'width: $width',
        );
      }
      for (final height in <int>[-1, 0, 8193]) {
        expect(
          () => checkedBorderRleCellCount(width: 1, height: height),
          _formatExceptionAt(r'$.height'),
          reason: 'height: $height',
        );
      }
    });

    test('preserves a caller-supplied path in dimension failures', () {
      expect(
        () => checkedBorderRleCellCount(
          width: 8193,
          height: 1,
          path: r'$.geometry',
        ),
        _formatExceptionAt(r'$.geometry.width'),
      );
    });
  });

  group('Border RLE V1 encoding', () {
    test('encodes the canonical empty and singleton forms', () {
      expect(encodeBorderRleMask(const <bool>[]), 'border-rle-v1:0:0:');
      expect(encodeBorderRleMask(const <bool>[false]), 'border-rle-v1:1:0:1');
      expect(encodeBorderRleMask(const <bool>[true]), 'border-rle-v1:1:1:1');
    });

    test('coalesces all-same and alternating values canonically', () {
      expect(
        encodeBorderRleMask(const <bool>[false, false, false, false]),
        'border-rle-v1:4:0:4',
      );
      expect(
        encodeBorderRleMask(const <bool>[true, true, true]),
        'border-rle-v1:3:1:3',
      );
      expect(
        encodeBorderRleMask(const <bool>[false, true, false, true]),
        'border-rle-v1:4:0:1,1,1,1',
      );
    });

    test('keeps runs continuous across conceptual row boundaries', () {
      // Conceptual 2x2 rows: 00 / 01. The zero run crosses the row boundary.
      expect(
        encodeBorderRleMask(const <bool>[false, false, false, true]),
        'border-rle-v1:4:0:3,1',
      );
    });

    test('encodes mixed runs without redundant separators', () {
      expect(
        encodeBorderRleMask(
          const <bool>[true, true, false, true, true, true, false, false],
        ),
        'border-rle-v1:8:1:2,1,3,2',
      );
    });

    test('rejects a reported decoded length above the V1 bound eagerly', () {
      final oversized = _ReportedLengthBoolList(
        borderRleMaxDecodedCells + 1,
      );

      expect(() => encodeBorderRleMask(oversized), throwsArgumentError);
      expect(oversized.readCount, 0);
    });
  });

  group('Border RLE V1 validation and decoding', () {
    test('round-trips canonical masks', () {
      final masks = <List<bool>>[
        const <bool>[],
        const <bool>[false],
        const <bool>[true],
        const <bool>[false, false, false, false],
        const <bool>[true, false, true, false, true],
        const <bool>[true, true, false, false, false, true, false],
      ];

      for (final mask in masks) {
        final encoded = encodeBorderRleMask(mask);
        expect(
          () => validateBorderRleMask(
            encoded,
            expectedLength: mask.length,
          ),
          returnsNormally,
        );
        expect(
          decodeBorderRleMask(encoded, expectedLength: mask.length),
          mask,
        );
      }
    });

    test('validates the maximum decoded boundary without allocating it', () {
      expect(
        () => validateBorderRleMask(
          'border-rle-v1:67108864:1:67108864',
          expectedLength: borderRleMaxDecodedCells,
        ),
        returnsNormally,
      );
      expect(
        () => validateBorderRleMask(
          'border-rle-v1:67108864:0:1,67108863',
          expectedLength: borderRleMaxDecodedCells,
        ),
        returnsNormally,
      );
    });

    test('detects filled cells at the maximum boundary without decoding', () {
      expect(
        borderRleMaskHasTrue(
          'border-rle-v1:67108864:0:67108864',
          expectedLength: borderRleMaxDecodedCells,
        ),
        isFalse,
      );
      expect(
        borderRleMaskHasTrue(
          'border-rle-v1:67108864:1:67108864',
          expectedLength: borderRleMaxDecodedCells,
        ),
        isTrue,
      );
      expect(
        borderRleMaskHasTrue(
          'border-rle-v1:67108864:0:1,67108863',
          expectedLength: borderRleMaxDecodedCells,
        ),
        isTrue,
      );
    });

    test('rejects an invalid expected length as a caller error', () {
      for (final expectedLength in <int>[-1, borderRleMaxDecodedCells + 1]) {
        expect(
          () => validateBorderRleMask(
            'border-rle-v1:0:0:',
            expectedLength: expectedLength,
          ),
          throwsArgumentError,
        );
        expect(
          () => decodeBorderRleMask(
            'border-rle-v1:0:0:',
            expectedLength: expectedLength,
          ),
          throwsArgumentError,
        );
      }
    });

    test('rejects non-string values at the requested path', () {
      for (final value in <Object?>[null, 1, true, <Object?>[]]) {
        expect(
          () => validateBorderRleMask(
            value,
            expectedLength: 0,
            path: r'$.mask',
          ),
          _formatExceptionAt(r'$.mask'),
          reason: 'value: $value',
        );
      }
    });

    test('reports unsupported versions distinctly from malformed headers', () {
      expect(
        () => validateBorderRleMask(
          'border-rle-v2:1:0:1',
          expectedLength: 1,
        ),
        _formatExceptionContaining(r'$', 'unsupported Border RLE version'),
      );
      expect(
        () => validateBorderRleMask('not-rle', expectedLength: 1),
        _formatExceptionContaining(r'$', 'Border RLE V1'),
      );
    });

    test('accepts only the exact canonical empty form', () {
      expect(
        () => validateBorderRleMask(
          'border-rle-v1:0:0:',
          expectedLength: 0,
        ),
        returnsNormally,
      );

      for (final value in <String>[
        'border-rle-v1:0:1:',
        'border-rle-v1:0:0:0',
        'border-rle-v1:0:0:1',
        'border-rle-v1:0:0:,',
      ]) {
        expect(
          () => validateBorderRleMask(value, expectedLength: 0),
          _formatExceptionAt(r'$'),
          reason: value,
        );
      }
    });

    test('rejects missing or trailing header fields', () {
      for (final value in <String>[
        '',
        'border-rle-v1:',
        'border-rle-v1:1',
        'border-rle-v1:1:',
        'border-rle-v1:1:0',
        'border-rle-v1:1:0:',
        'border-rle-v1:1:0:1:',
      ]) {
        expect(
          () => validateBorderRleMask(value, expectedLength: 1),
          _formatExceptionAt(r'$'),
          reason: value,
        );
      }
    });

    test('rejects non-canonical declared-length decimals', () {
      for (final encodedLength in <String>[
        '',
        '01',
        '+1',
        '-1',
        ' 1',
        '1 ',
        '１',
      ]) {
        expect(
          () => validateBorderRleMask(
            'border-rle-v1:$encodedLength:0:1',
            expectedLength: 1,
          ),
          _formatExceptionAt(r'$'),
          reason: 'decoded length: "$encodedLength"',
        );
      }
    });

    test('rejects a declared length mismatch and max plus one', () {
      expect(
        () => validateBorderRleMask(
          'border-rle-v1:2:0:2',
          expectedLength: 1,
        ),
        _formatExceptionAt(r'$'),
      );
      expect(
        () => validateBorderRleMask(
          'border-rle-v1:67108865:0:67108865',
          expectedLength: borderRleMaxDecodedCells,
        ),
        _formatExceptionAt(r'$'),
      );
    });

    test('rejects missing, multi-character, and non-binary first bits', () {
      for (final value in <String>[
        'border-rle-v1:1::1',
        'border-rle-v1:1:00:1',
        'border-rle-v1:1:2:1',
        'border-rle-v1:1:x:1',
        'border-rle-v1:1:１:1',
      ]) {
        expect(
          () => validateBorderRleMask(value, expectedLength: 1),
          _formatExceptionAt(r'$'),
          reason: value,
        );
      }
    });

    test('rejects non-positive and non-canonical run decimals', () {
      for (final run in <String>[
        '',
        '0',
        '01',
        '+1',
        '-1',
        ' 1',
        '1 ',
        '１',
        'a',
      ]) {
        expect(
          () => validateBorderRleMask(
            'border-rle-v1:1:0:$run',
            expectedLength: 1,
          ),
          _formatExceptionAt(r'$'),
          reason: 'run: "$run"',
        );
      }
    });

    test('rejects empty run tokens, trailing separators, and suffixes', () {
      for (final value in <String>[
        'border-rle-v1:2:0:,2',
        'border-rle-v1:2:0:1,,1',
        'border-rle-v1:2:0:1,',
        'border-rle-v1:2:0:2suffix',
        'border-rle-v1:2:0:2:extra',
      ]) {
        expect(
          () => validateBorderRleMask(value, expectedLength: 2),
          _formatExceptionAt(r'$'),
          reason: value,
        );
      }
    });

    test('rejects run underfill and overfill', () {
      expect(
        () => validateBorderRleMask(
          'border-rle-v1:3:0:2',
          expectedLength: 3,
        ),
        _formatExceptionAt(r'$'),
      );
      expect(
        () => validateBorderRleMask(
          'border-rle-v1:3:0:4',
          expectedLength: 3,
        ),
        _formatExceptionAt(r'$'),
      );
      expect(
        () => validateBorderRleMask(
          'border-rle-v1:3:0:2,2',
          expectedLength: 3,
        ),
        _formatExceptionAt(r'$'),
      );
    });

    test('rejects disproportionate attacker input before reading its tail', () {
      final payload = '9' * 100000;
      final encoded = 'border-rle-v1:1:0:$payload';

      final error = _captureFormatException(
        () => validateBorderRleMask(
          encoded,
          expectedLength: 1,
          path: r'$.snapshot.occupancyMaskRle',
        ),
      );
      expect(error.message, startsWith(r'$.snapshot.occupancyMaskRle:'));
      expect(error.message.toString(), isNot(contains(payload)));
    });

    test('bounds an oversized token even at the maximum expected length', () {
      final payload = '9' * 100000;
      final encoded = 'border-rle-v1:67108864:0:$payload';

      expect(
        () => validateBorderRleMask(
          encoded,
          expectedLength: borderRleMaxDecodedCells,
        ),
        _formatExceptionAt(r'$'),
      );
    });

    test('visits only canonical true runs without decoding a mask', () {
      final visited = <(int, int)>[];

      visitBorderRleTrueRuns(
        'border-rle-v1:9:0:2,3,1,2,1',
        expectedLength: 9,
        visitor: (start, end) => visited.add((start, end)),
      );

      expect(visited, [(2, 5), (6, 8)]);
    });

    test('validates the complete payload before invoking a true-run visitor',
        () {
      var visits = 0;

      expect(
        () => visitBorderRleTrueRuns(
          'border-rle-v1:4:1:2,1',
          expectedLength: 4,
          visitor: (_, __) => visits += 1,
        ),
        _formatExceptionAt(r'$'),
      );
      expect(visits, 0);
    });
  });
}

Matcher _formatExceptionAt(String path) => throwsA(
      isA<FormatException>().having(
        (error) => error.message.toString(),
        'message',
        startsWith('$path:'),
      ),
    );

Matcher _formatExceptionContaining(String path, String text) => throwsA(
      isA<FormatException>().having(
        (error) => error.message.toString(),
        'message',
        allOf(startsWith('$path:'), contains(text)),
      ),
    );

FormatException _captureFormatException(void Function() action) {
  try {
    action();
  } on FormatException catch (error) {
    return error;
  }
  throw StateError('Expected a FormatException');
}

final class _ReportedLengthBoolList extends ListBase<bool> {
  _ReportedLengthBoolList(this._length);

  final int _length;
  int readCount = 0;

  @override
  int get length => _length;

  @override
  set length(int value) => throw UnsupportedError('immutable');

  @override
  bool operator [](int index) {
    readCount += 1;
    throw StateError('oversized list must be rejected before reading');
  }

  @override
  void operator []=(int index, bool value) =>
      throw UnsupportedError('immutable');
}
