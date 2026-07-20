import 'dart:convert' show utf8;

import 'package:meta/meta.dart' show immutable;

import '../models/border_signed_int64.dart';

final BigInt _uint64Modulus = BigInt.one << 64;
final BigInt _uint64Mask = _uint64Modulus - BigInt.one;
final BigInt _fnv1a64Offset = BigInt.parse('cbf29ce484222325', radix: 16);
final BigInt _fnv1a64Prime = BigInt.parse('00000100000001B3', radix: 16);
final BigInt _xorshift64StarMultiplier =
    BigInt.parse('2545F4914F6CDD1D', radix: 16);
final BigInt _zeroStateFallback = BigInt.parse('9E3779B97F4A7C15', radix: 16);
final BigInt _maximumUint32 = BigInt.parse('4294967295');

const List<int> _borderRngV1Prefix = <int>[
  0x62,
  0x6f,
  0x72,
  0x64,
  0x65,
  0x72,
  0x5f,
  0x72,
  0x6e,
  0x67,
  0x5f,
  0x76,
  0x31,
];
const int _textComponentTag = 0x01;
const int _signedInt64ComponentTag = 0x02;

/// One typed component of a deterministic Border RNG key.
sealed class BorderRngKeyComponent {
  const BorderRngKeyComponent._();

  const factory BorderRngKeyComponent.text(String value) =
      _BorderTextRngKeyComponent;

  const factory BorderRngKeyComponent.signedInt64(
    BorderSignedInt64 value,
  ) = _BorderSignedInt64RngKeyComponent;
}

final class _BorderTextRngKeyComponent extends BorderRngKeyComponent {
  const _BorderTextRngKeyComponent(this.value) : super._();

  final String value;
}

final class _BorderSignedInt64RngKeyComponent extends BorderRngKeyComponent {
  const _BorderSignedInt64RngKeyComponent(this.value) : super._();

  final BorderSignedInt64 value;
}

/// Encodes the canonical `border_rng_v1` typed, length-prefixed preimage.
List<int> encodeBorderRngKey(Iterable<BorderRngKeyComponent> components) {
  final encoded = <int>[..._borderRngV1Prefix];
  for (final component in components) {
    switch (component) {
      case _BorderTextRngKeyComponent(:final value):
        _appendComponent(
          encoded,
          tag: _textComponentTag,
          payload: _encodeStrictUtf8(value),
        );
      case _BorderSignedInt64RngKeyComponent(:final value):
        _appendComponent(
          encoded,
          tag: _signedInt64ComponentTag,
          payload: _encodeSignedInt64(value.value),
        );
    }
  }
  return List<int>.unmodifiable(encoded);
}

/// Computes FNV-1a 64 with an explicit modulo-2^64 reduction per byte.
BigInt borderFnv1a64(Iterable<int> bytes) {
  var hash = _fnv1a64Offset;
  for (final byte in bytes) {
    if (byte < 0 || byte > 0xff) {
      throw ArgumentError.value(byte, 'bytes', 'must contain only bytes');
    }
    hash ^= BigInt.from(byte);
    hash = (hash * _fnv1a64Prime) & _uint64Mask;
  }
  return hash;
}

/// Exact, portable xorshift64* stream for local Border generation choices.
final class BorderDeterministicRng {
  factory BorderDeterministicRng.fromComponents(
    Iterable<BorderRngKeyComponent> components,
  ) {
    return BorderDeterministicRng.fromState(
      borderFnv1a64(encodeBorderRngKey(components)),
    );
  }

  /// Restores a raw unsigned 64-bit xorshift state.
  ///
  /// This low-level constructor makes persisted/debug golden state replay
  /// possible. A zero state is replaced only when the next value is drawn.
  factory BorderDeterministicRng.fromState(BigInt state) {
    if (state.isNegative || state > _uint64Mask) {
      throw ArgumentError.value(
        state,
        'state',
        'must fit the unsigned 64-bit range',
      );
    }
    return BorderDeterministicRng._(state);
  }

  BorderDeterministicRng._(this._state);

  BigInt _state;

  BigInt nextUint64() {
    var value = _state == BigInt.zero ? _zeroStateFallback : _state;
    value ^= value >> 12;
    value &= _uint64Mask;
    value ^= value << 25;
    value &= _uint64Mask;
    value ^= value >> 27;
    value &= _uint64Mask;
    _state = value;
    return (value * _xorshift64StarMultiplier) & _uint64Mask;
  }

  int nextIndex(int exclusiveUpperBound) {
    if (exclusiveUpperBound <= 0) {
      throw ArgumentError.value(
        exclusiveUpperBound,
        'exclusiveUpperBound',
        'must be positive',
      );
    }
    return (nextUint64() % BigInt.from(exclusiveUpperBound)).toInt();
  }
}

/// One ID-stable weighted candidate used by Border generation.
@immutable
final class BorderWeightedCandidate<T> {
  const BorderWeightedCandidate({
    required this.id,
    required this.value,
    required this.weight,
  });

  final String id;
  final T value;
  final int weight;
}

/// Chooses after filtering non-positive weights and sorting by stable ID.
///
/// Returns `null` without advancing [rng] when no candidate is eligible.
BorderWeightedCandidate<T>? chooseBorderWeightedCandidate<T>(
  BorderDeterministicRng rng,
  Iterable<BorderWeightedCandidate<T>> candidates,
) {
  final eligible = candidates
      .where((candidate) => candidate.weight > 0)
      .toList(growable: false)
    ..sort((first, second) => first.id.compareTo(second.id));
  if (eligible.isEmpty) {
    return null;
  }

  var totalWeight = BigInt.zero;
  String? previousId;
  for (final candidate in eligible) {
    if (candidate.id == previousId) {
      throw ArgumentError.value(
        candidate.id,
        'candidates',
        'positive candidate IDs must be unique',
      );
    }
    previousId = candidate.id;
    totalWeight += BigInt.from(candidate.weight);
  }

  var selectedWeight = rng.nextUint64() % totalWeight;
  for (final candidate in eligible) {
    final weight = BigInt.from(candidate.weight);
    if (selectedWeight < weight) {
      return candidate;
    }
    selectedWeight -= weight;
  }
  throw StateError('A positive weighted Border candidate must be selected');
}

void _appendComponent(
  List<int> destination, {
  required int tag,
  required List<int> payload,
}) {
  if (BigInt.from(payload.length) > _maximumUint32) {
    throw ArgumentError.value(
      payload.length,
      'payload',
      'must fit an unsigned 32-bit length',
    );
  }
  destination
    ..add(tag)
    ..add((payload.length >> 24) & 0xff)
    ..add((payload.length >> 16) & 0xff)
    ..add((payload.length >> 8) & 0xff)
    ..add(payload.length & 0xff)
    ..addAll(payload);
}

List<int> _encodeSignedInt64(BigInt value) {
  var unsigned = value.isNegative ? value + _uint64Modulus : value;
  final result = List<int>.filled(8, 0);
  for (var index = result.length - 1; index >= 0; index -= 1) {
    result[index] = (unsigned & BigInt.from(0xff)).toInt();
    unsigned >>= 8;
  }
  return result;
}

List<int> _encodeStrictUtf8(String value) {
  for (var index = 0; index < value.length; index += 1) {
    final codeUnit = value.codeUnitAt(index);
    final isLeadingSurrogate = codeUnit >= 0xd800 && codeUnit <= 0xdbff;
    final isTrailingSurrogate = codeUnit >= 0xdc00 && codeUnit <= 0xdfff;
    if (isLeadingSurrogate) {
      final nextIndex = index + 1;
      if (nextIndex >= value.length) {
        throw ArgumentError.value(
          value,
          'value',
          'must not contain unpaired UTF-16 surrogates',
        );
      }
      final nextCodeUnit = value.codeUnitAt(nextIndex);
      if (nextCodeUnit < 0xdc00 || nextCodeUnit > 0xdfff) {
        throw ArgumentError.value(
          value,
          'value',
          'must not contain unpaired UTF-16 surrogates',
        );
      }
      index = nextIndex;
    } else if (isTrailingSurrogate) {
      throw ArgumentError.value(
        value,
        'value',
        'must not contain unpaired UTF-16 surrogates',
      );
    }
  }
  return utf8.encode(value);
}
