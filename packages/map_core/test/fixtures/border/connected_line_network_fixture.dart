import 'package:map_core/map_core.dart';

import 'post_and_rail_line_fixture.dart';

final class ConnectedLineNetworkFixture {
  ConnectedLineNetworkFixture({required this.networkAnchors}) {
    final anchors = networkAnchors
        ? const <BorderPrimitiveRole, BorderPixelPos>{
            BorderPrimitiveRole.lineCap: BorderPixelPos(x: 16, y: 16),
            BorderPrimitiveRole.lineStraight: BorderPixelPos(x: 16, y: 16),
            BorderPrimitiveRole.lineCorner: BorderPixelPos(x: 16, y: 16),
          }
        : const <BorderPrimitiveRole, BorderPixelPos>{
            BorderPrimitiveRole.lineCap: BorderPixelPos(x: 22, y: 30),
            BorderPrimitiveRole.lineStraight: BorderPixelPos(x: 16, y: 31),
            BorderPrimitiveRole.lineCorner: BorderPixelPos(x: 11, y: 31),
          };
    final primitives = <BorderPublishedPrimitive>[
      for (final entry in anchors.entries)
        fencePrimitive(
          id: entry.key.name,
          fingerprintCharacter: switch (entry.key) {
            BorderPrimitiveRole.lineCap => 'a',
            BorderPrimitiveRole.lineStraight => 'b',
            BorderPrimitiveRole.lineCorner => 'c',
            _ => throw StateError('Unexpected connected-line role'),
          },
          role: entry.key,
          width: 32,
          height: 32,
          allowFlipX: true,
          anchorPx: entry.value,
          occupancy: _networkMask(entry.key),
        ),
    ];
    request = PostAndRailLineFixture(
      template: BorderBlueprintTemplate.connectedLine,
      primitives: primitives,
      parameters: fenceParameters(gapTolerancePx: 1, maxOverlapPx: 8),
      mapSize: const GridSize(width: 12, height: 10),
      tileSizePx: const GridSize(width: 32, height: 32),
    ).request;
  }

  final bool networkAnchors;
  late final BorderResolutionRequest request;
}

List<bool> _networkMask(BorderPrimitiveRole role) {
  final pixels = List<bool>.filled(32 * 32, false);
  for (var x = 0; x < 32; x += 1) {
    pixels[16 * 32 + x] = true;
  }
  if (role == BorderPrimitiveRole.lineCorner) {
    for (var y = 0; y < 32; y += 1) {
      pixels[y * 32 + 16] = true;
    }
  }
  return pixels;
}
