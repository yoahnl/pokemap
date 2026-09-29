import 'dart:convert';

import '../collision/pixel_rect.dart';
import '../exceptions/map_exceptions.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/project_manifest.dart';
import 'map_placed_element_footprint.dart';

Iterable<PixelRect> resolveMapPlacedElementCollisionRects({
  required MapPlacedElement instance,
  required ProjectElementEntry element,
  required PixelSize tileSize,
}) sync* {
  if (!instance.applyCollision || element.collisionProfile == null) return;
  yield* PreparedMapPlacedElementCollision(
    element: element,
    tileSize: tileSize,
  ).resolve(instance);
}

final class PreparedMapPlacedElementCollision {
  PreparedMapPlacedElementCollision({
    required this.element,
    required this.tileSize,
  }) {
    final mask = element.collisionProfile?.collisionMask;
    if (mask == null || mask.widthPx <= 0 || mask.heightPx <= 0) return;
    final raw = mask.dataBase64.trim();
    if (raw.isEmpty) return;
    _encoded = base64.normalize(raw);
    final padding = _encoded.endsWith('==')
        ? 2
        : (_encoded.endsWith('=') ? 1 : 0);
    final byteLength = _encoded.length ~/ 4 * 3 - padding;
    final total = BigInt.from(mask.widthPx) * BigInt.from(mask.heightPx);
    if (total > BigInt.from(9007199254740991) ||
        BigInt.from(byteLength) < (total + BigInt.from(7)) ~/ BigInt.from(8)) {
      throw const FormatException(
        'Packed collision mask dimensions exceed its payload',
      );
    }
  }

  final ProjectElementEntry element;
  final PixelSize tileSize;
  String _encoded = '';
  int get retainedBytes =>
      identical(_encoded, element.collisionProfile?.collisionMask?.dataBase64)
      ? 0
      : _encoded.length * 2;

  bool _solid(int index) {
    final bit = (index ~/ 8) * 8 + 7 - index % 8;
    final code = _encoded.codeUnitAt(bit ~/ 6);
    final value = code >= 65 && code <= 90
        ? code - 65
        : code >= 97 && code <= 122
        ? code - 71
        : code >= 48 && code <= 57
        ? code + 4
        : code == 43
        ? 62
        : 63;
    return value & (1 << (5 - bit % 6)) != 0;
  }

  Iterable<PixelRect> resolve(MapPlacedElement instance) sync* {
    final profile = element.collisionProfile;
    if (!instance.applyCollision || profile == null) return;
    final geometry = resolveMapPlacedElementGeometry(
      instance: instance,
      element: element,
      tileSize: tileSize,
    );
    final footprint = resolveMapPlacedElementFootprint(
      instance: instance,
      element: element,
    );
    final mask = profile.collisionMask;
    PixelRect project(PixelRect rect) {
      final left = _scaleBoundary(
        rect.leftPx,
        geometry.pixelSize.width,
        geometry.naturalPixelSize.width,
      );
      final top = _scaleBoundary(
        rect.topPx,
        geometry.pixelSize.height,
        geometry.naturalPixelSize.height,
      );
      final right = _scaleBoundary(
        rect.leftPx + rect.widthPx,
        geometry.pixelSize.width,
        geometry.naturalPixelSize.width,
        ceil: true,
      );
      final bottom = _scaleBoundary(
        rect.topPx + rect.heightPx,
        geometry.pixelSize.height,
        geometry.naturalPixelSize.height,
        ceil: true,
      );
      return PixelRect(
        leftPx: _checkedSum(geometry.logicalRect.leftPx, left),
        topPx: _checkedSum(geometry.logicalRect.topPx, top),
        widthPx: right - left,
        heightPx: bottom - top,
      );
    }

    if (mask == null) {
      for (final cell in profile.cells) {
        final destination = footprint.sourceToDestination(cell);
        yield project(
          PixelRect(
            leftPx: destination.x * tileSize.width,
            topPx: destination.y * tileSize.height,
            widthPx: tileSize.width,
            heightPx: tileSize.height,
          ),
        );
      }
      return;
    }
    if (mask.widthPx <= 0 || mask.heightPx <= 0) return;
    if (_encoded.isEmpty) return;
    final nativeSize = footprint.quarterTurns == 0
        ? GridSize(width: mask.widthPx, height: mask.heightPx)
        : GridSize(
            width: geometry.naturalPixelSize.width,
            height: geometry.naturalPixelSize.height,
          );
    _checkedSum(
      geometry.logicalRect.leftPx,
      _scaleBoundary(
        nativeSize.width,
        geometry.pixelSize.width,
        geometry.naturalPixelSize.width,
        ceil: true,
      ),
    );
    _checkedSum(
      geometry.logicalRect.topPx,
      _scaleBoundary(
        nativeSize.height,
        geometry.pixelSize.height,
        geometry.naturalPixelSize.height,
        ceil: true,
      ),
    );
    final transform = QuarterTurnPixelTransform(
      sourcePixelSize: GridSize(width: mask.widthPx, height: mask.heightPx),
      destinationPixelSize: nativeSize,
      quarterTurns: footprint.quarterTurns,
    );

    for (var y = 0; y < mask.heightPx; y++) {
      var x = 0;
      while (x < mask.widthPx) {
        if (!_solid(y * mask.widthPx + x)) {
          x++;
          continue;
        }
        final start = x++;
        while (x < mask.widthPx && _solid(y * mask.widthPx + x)) {
          x++;
        }
        final native = transform.sourcePixelRectToDestinationPixelRect(
          PixelRect(leftPx: start, topPx: y, widthPx: x - start, heightPx: 1),
        );
        if (native.widthPx > 0 && native.heightPx > 0) yield project(native);
      }
    }
  }
}

int _scaleBoundary(int value, int target, int natural, {bool ceil = false}) {
  if (target == natural) return value;
  if (value <= 9007199254740991 ~/ target) {
    final numerator = value * target;
    return numerator ~/ natural + (ceil && numerator % natural != 0 ? 1 : 0);
  }
  final numerator = BigInt.from(value) * BigInt.from(target);
  final denominator = BigInt.from(natural);
  final result =
      numerator ~/ denominator +
      (ceil && numerator % denominator != BigInt.zero
          ? BigInt.one
          : BigInt.zero);
  if (result > BigInt.from(9007199254740991)) {
    throw const ValidationException(
      'Collision geometry exceeds exact integer representation',
    );
  }
  return result.toInt();
}

int _checkedSum(int origin, int boundary) {
  final result = BigInt.from(origin) + BigInt.from(boundary);
  if (result.abs() > BigInt.from(9007199254740991)) {
    throw const ValidationException(
      'Collision geometry exceeds exact integer representation',
    );
  }
  return result.toInt();
}
