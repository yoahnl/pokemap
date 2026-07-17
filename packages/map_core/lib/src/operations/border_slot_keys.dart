import 'dart:convert' show utf8;

import 'package:crypto/crypto.dart' show sha256;

import '../exceptions/map_exceptions.dart';
import '../models/border_materialization.dart';
import '../models/border_value_objects.dart';
import '../models/geometry.dart';

const String borderSlotKeyV1Prefix = 'border-slot-v1:';

const List<int> _borderSlotV1Magic = <int>[
  0x62,
  0x6f,
  0x72,
  0x64,
  0x65,
  0x72,
  0x5f,
  0x73,
  0x6c,
  0x6f,
  0x74,
  0x5f,
  0x76,
  0x31,
];
const int _textTag = 0x01;
const int _signedInt64Tag = 0x02;

final BigInt _signedInt64Min = BigInt.parse('-9223372036854775808');
final BigInt _signedInt64Max = BigInt.parse('9223372036854775807');
final BigInt _uint64Modulus = BigInt.one << 64;
final BigInt _maximumSafeJsonInteger = BigInt.parse('9007199254740991');

/// Builds a geometry-local V1 key for one region boundary slot.
String buildBorderRegionSlotKey({
  required String featureId,
  required GridPos interiorCell,
  required BorderCardinalDirection side,
  required int passIndex,
  required BorderPrimitiveRole role,
  required int rank,
  required int ordinalLocal,
}) {
  _requireStableText(featureId, 'featureId');
  _requireNonNegativeCell(interiorCell, 'interiorCell');
  _requireNonNegative(passIndex, 'passIndex');
  _requireNonNegative(rank, 'rank');
  _requireNonNegative(ordinalLocal, 'ordinalLocal');

  return _slotKey(<_SlotComponent>[
    const _TextSlotComponent('region'),
    _TextSlotComponent(featureId),
    _IntegerSlotComponent(interiorCell.x),
    _IntegerSlotComponent(interiorCell.y),
    _TextSlotComponent(borderCardinalDirectionV1WireName(side)),
    _IntegerSlotComponent(passIndex),
    _TextSlotComponent(borderPrimitiveRoleV1WireName(role)),
    _IntegerSlotComponent(rank),
    _IntegerSlotComponent(ordinalLocal),
  ]);
}

/// Builds a direction-independent V1 key for one unit-cardinal line edge.
String buildBorderLineSlotKey({
  required String featureId,
  required String strokeId,
  required GridPos edgeStart,
  required GridPos edgeEnd,
  required int passIndex,
  required BorderPrimitiveRole role,
  required int rank,
  required int ordinalLocal,
}) {
  _requireStableText(featureId, 'featureId');
  _requireStableText(strokeId, 'strokeId');
  _requireNonNegativeCell(edgeStart, 'edgeStart');
  _requireNonNegativeCell(edgeEnd, 'edgeEnd');
  _requireUnitCardinalEdge(edgeStart, edgeEnd);
  _requireNonNegative(passIndex, 'passIndex');
  _requireNonNegative(rank, 'rank');
  _requireNonNegative(ordinalLocal, 'ordinalLocal');

  final startComesFirst = edgeStart.y < edgeEnd.y ||
      (edgeStart.y == edgeEnd.y && edgeStart.x <= edgeEnd.x);
  final endpointA = startComesFirst ? edgeStart : edgeEnd;
  final endpointB = startComesFirst ? edgeEnd : edgeStart;

  return _slotKey(<_SlotComponent>[
    const _TextSlotComponent('line'),
    _TextSlotComponent(featureId),
    _TextSlotComponent(strokeId),
    _IntegerSlotComponent(endpointA.x),
    _IntegerSlotComponent(endpointA.y),
    _IntegerSlotComponent(endpointB.x),
    _IntegerSlotComponent(endpointB.y),
    _IntegerSlotComponent(passIndex),
    _TextSlotComponent(borderPrimitiveRoleV1WireName(role)),
    _IntegerSlotComponent(rank),
    _IntegerSlotComponent(ordinalLocal),
  ]);
}

/// Builds a topology- and side-independent V1 key for one connected-line node.
///
/// A node keeps the same identity when its authored neighbours change (for
/// example, from a cap to a straight segment) or when the visual side is
/// inverted. This lets local overrides and deterministic variant selection
/// survive those edits.
String buildBorderConnectedLineNodeSlotKey({
  required String featureId,
  required String strokeId,
  required GridPos cell,
  required int passIndex,
  required BorderPrimitiveRole role,
  required int rank,
  required int ordinalLocal,
}) {
  _requireStableText(featureId, 'featureId');
  _requireStableText(strokeId, 'strokeId');
  _requireNonNegativeCell(cell, 'cell');
  _requireNonNegative(passIndex, 'passIndex');
  _requireNonNegative(rank, 'rank');
  _requireNonNegative(ordinalLocal, 'ordinalLocal');

  return _slotKey(<_SlotComponent>[
    const _TextSlotComponent('connected-line-node'),
    _TextSlotComponent(featureId),
    _TextSlotComponent(strokeId),
    _IntegerSlotComponent(cell.x),
    _IntegerSlotComponent(cell.y),
    _IntegerSlotComponent(passIndex),
    _TextSlotComponent(_connectedLineNodeRoleWireName(role)),
    _IntegerSlotComponent(rank),
    _IntegerSlotComponent(ordinalLocal),
  ]);
}

String _connectedLineNodeRoleWireName(BorderPrimitiveRole role) =>
    switch (role) {
      BorderPrimitiveRole.lineCap ||
      BorderPrimitiveRole.lineStraight ||
      BorderPrimitiveRole.lineCorner =>
        'lineNode',
      _ => throw const ValidationException(
          'connected-line node role must be cap, straight, or corner',
        ),
    };

/// Captures the complete persisted V1 draw-order tuple at resolution time.
BorderStableOrderKey buildBorderStableOrderKey({
  required BorderDrawBand drawBand,
  required int mapWidth,
  required GridPos anchorCell,
  required int passIndex,
  required int rank,
  required int ordinalLocal,
  required String slotKey,
}) {
  if (mapWidth <= 0) {
    throw const ValidationException('mapWidth must be > 0');
  }
  _requirePortableNonNegative(mapWidth, 'mapWidth');
  _requireNonNegativeCell(anchorCell, 'anchorCell');
  if (anchorCell.x >= mapWidth) {
    throw const ValidationException('anchorCell.x must be within mapWidth');
  }
  _requireNonNegative(passIndex, 'passIndex');
  _requireNonNegative(rank, 'rank');
  _requireNonNegative(ordinalLocal, 'ordinalLocal');
  _requireStableText(slotKey, 'slotKey');

  final rowMajor = BigInt.from(anchorCell.y) * BigInt.from(mapWidth) +
      BigInt.from(anchorCell.x);
  if (rowMajor > _maximumSafeJsonInteger) {
    throw const ValidationException(
      'anchorRowMajor must remain exactly representable on every target',
    );
  }

  return BorderStableOrderKey(
    drawBandIndex: borderDrawBandV1Index(drawBand),
    anchorRowMajor: rowMajor.toInt(),
    passIndex: passIndex,
    rank: rank,
    ordinalLocal: ordinalLocal,
    slotKey: slotKey,
  );
}

sealed class _SlotComponent {
  const _SlotComponent();
}

final class _TextSlotComponent extends _SlotComponent {
  const _TextSlotComponent(this.value);

  final String value;
}

final class _IntegerSlotComponent extends _SlotComponent {
  const _IntegerSlotComponent(this.value);

  final int value;
}

String _slotKey(List<_SlotComponent> components) {
  final bytes = <int>[..._borderSlotV1Magic];
  for (final component in components) {
    switch (component) {
      case _TextSlotComponent(:final value):
        _appendComponent(bytes, _textTag, _encodeStrictUtf8(value));
      case _IntegerSlotComponent(:final value):
        _appendComponent(bytes, _signedInt64Tag, _encodeSignedInt64(value));
    }
  }
  return '$borderSlotKeyV1Prefix${sha256.convert(bytes)}';
}

void _appendComponent(List<int> output, int tag, List<int> payload) {
  if (payload.length > 0xffffffff) {
    throw ArgumentError.value(payload.length, 'payload', 'exceeds uint32');
  }
  output
    ..add(tag)
    ..add((payload.length >> 24) & 0xff)
    ..add((payload.length >> 16) & 0xff)
    ..add((payload.length >> 8) & 0xff)
    ..add(payload.length & 0xff)
    ..addAll(payload);
}

List<int> _encodeSignedInt64(int value) {
  final exact = BigInt.from(value);
  if (exact < _signedInt64Min || exact > _signedInt64Max) {
    throw const ValidationException('slot integer must fit signed int64');
  }
  var unsigned = exact.isNegative ? exact + _uint64Modulus : exact;
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
    if (codeUnit >= 0xd800 && codeUnit <= 0xdbff) {
      if (index + 1 >= value.length) {
        throw ValidationException('text contains an unpaired surrogate');
      }
      final trailing = value.codeUnitAt(index + 1);
      if (trailing < 0xdc00 || trailing > 0xdfff) {
        throw ValidationException('text contains an unpaired surrogate');
      }
      index += 1;
    } else if (codeUnit >= 0xdc00 && codeUnit <= 0xdfff) {
      throw ValidationException('text contains an unpaired surrogate');
    }
  }
  return utf8.encode(value);
}

void _requireStableText(String value, String field) {
  if (value.trim().isEmpty || value != value.trim()) {
    throw ValidationException('$field must be nonblank and already trimmed');
  }
  _encodeStrictUtf8(value);
}

void _requireNonNegativeCell(GridPos cell, String field) {
  if (cell.x < 0 || cell.y < 0) {
    throw ValidationException('$field coordinates must be >= 0');
  }
  _requirePortableNonNegative(cell.x, '$field.x');
  _requirePortableNonNegative(cell.y, '$field.y');
}

void _requireNonNegative(int value, String field) {
  if (value < 0) {
    throw ValidationException('$field must be >= 0');
  }
  _requirePortableNonNegative(value, field);
}

void _requirePortableNonNegative(int value, String field) {
  if (BigInt.from(value) > _maximumSafeJsonInteger) {
    throw ValidationException(
      '$field must remain exactly representable on every target',
    );
  }
}

void _requireUnitCardinalEdge(GridPos start, GridPos end) {
  final deltaX = BigInt.from(start.x) - BigInt.from(end.x);
  final deltaY = BigInt.from(start.y) - BigInt.from(end.y);
  if (deltaX.abs() + deltaY.abs() != BigInt.one) {
    throw const ValidationException(
      'line endpoints must form one unit-cardinal edge',
    );
  }
}
