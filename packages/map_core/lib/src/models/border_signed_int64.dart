import 'package:meta/meta.dart' show immutable;

final BigInt _minimumBorderSignedInt64 = BigInt.parse('-9223372036854775808');
final BigInt _maximumBorderSignedInt64 = BigInt.parse('9223372036854775807');
final RegExp _canonicalBorderSignedInt64Pattern =
    RegExp(r'^(?:0|-[1-9][0-9]*|[1-9][0-9]*)$');

/// Exact signed 64-bit integer used by persisted Border seeds.
///
/// Dart integers compile to JavaScript numbers on the web. Keeping the value
/// as [BigInt] prevents signed 64-bit seeds from losing precision there.
@immutable
final class BorderSignedInt64 implements Comparable<BorderSignedInt64> {
  factory BorderSignedInt64(BigInt value) {
    if (value < _minimumBorderSignedInt64 ||
        value > _maximumBorderSignedInt64) {
      throw ArgumentError.value(
        value,
        'value',
        'must fit the signed 64-bit range',
      );
    }
    return BorderSignedInt64._(value);
  }

  factory BorderSignedInt64.fromInt(int value) =>
      BorderSignedInt64(BigInt.from(value));

  /// Parses a canonical base-10 representation without accepting aliases
  /// such as `+1`, `01`, whitespace, or `-0`.
  factory BorderSignedInt64.parse(String encoded) {
    if (encoded.length > 20 ||
        !_canonicalBorderSignedInt64Pattern.hasMatch(encoded)) {
      throw FormatException('Invalid canonical signed 64-bit integer');
    }

    final parsed = BigInt.parse(encoded);
    if (parsed < _minimumBorderSignedInt64 ||
        parsed > _maximumBorderSignedInt64) {
      throw FormatException('Signed 64-bit integer is out of range');
    }
    return BorderSignedInt64._(parsed);
  }

  const BorderSignedInt64._(this.value);

  static final BorderSignedInt64 minimum =
      BorderSignedInt64._(_minimumBorderSignedInt64);
  static final BorderSignedInt64 maximum =
      BorderSignedInt64._(_maximumBorderSignedInt64);
  static final BorderSignedInt64 zero = BorderSignedInt64._(BigInt.zero);

  final BigInt value;

  @override
  int compareTo(BorderSignedInt64 other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderSignedInt64 && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}
