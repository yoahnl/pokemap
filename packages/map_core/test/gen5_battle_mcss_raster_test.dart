import 'dart:typed_data';

import 'package:test/test.dart';

import '../../../tools/gen5_battle_sprite/indexed_atlas.dart';
import '../../../tools/gen5_battle_sprite/mcss_bin.dart';
import '../../../tools/gen5_battle_sprite/mcss_pose.dart';
import '../../../tools/gen5_battle_sprite/mcss_raster.dart';
import '../../../tools/gen5_battle_sprite/multicell.dart';
import '../../../tools/gen5_battle_sprite/nanr.dart';
import '../../../tools/gen5_battle_sprite/nmcr.dart';

void main() {
  final pixels = Uint8List(256 * 128)
    ..[0] = 1
    ..[1] = 2
    ..[256] = 3
    ..[257] = 4
    ..[2] = 5
    ..[3] = 6
    ..[258] = 7
    ..[259] = 8
    ..[254] = 9
    ..[255] = 10;
  final atlas = Gen5IndexedAtlas.fromIndices(pixels);

  test(
    'approximates the DS orthographic vertical transform around the viewport center',
    () {
      final above = approximateGen5McssDsOrthoY(idealOriginY: 32);
      expect(above.originY, 31.5);
      expect(above.projectedScaleY, 129 / 128);

      final below = approximateGen5McssDsOrthoY(idealOriginY: 160);
      expect(below.originY, 160.5);
      expect(below.projectedScaleY, 129 / 128);

      final cropped = approximateGen5McssDsOrthoY(
        idealOriginY: 56,
        viewportCenterY: 64,
      );
      expect(cropped.originY, 55.9375);
      expect(cropped.projectedScaleY, 129 / 128);
    },
  );

  test('rejects invalid DS orthographic placement', () {
    expect(
      () => approximateGen5McssDsOrthoY(idealOriginY: double.nan),
      throwsFormatException,
    );
    expect(
      () => approximateGen5McssDsOrthoY(
        idealOriginY: 32,
        viewportCenterY: double.negativeInfinity,
      ),
      throwsFormatException,
    );
    expect(
      () => approximateGen5McssDsOrthoY(idealOriginY: double.maxFinite),
      throwsFormatException,
    );
  });

  test('scales projected vertical coordinates after parent rotation', () {
    final raster = rasterizeGen5McssOpaque(
      atlas: atlas,
      nodes: [_node(parentRotation: 16384)],
      width: 2,
      height: 4,
      originX: 2,
      originY: 0,
      projectedScaleY: 2,
    );
    expect(raster.indices, [3, 1, 3, 1, 4, 2, 4, 2]);
  });

  test(
    'projects a camera and pose from the same submission epoch in fixed point',
    () {
      const identity = <int>[
        4096,
        0,
        0,
        0,
        0,
        4096,
        0,
        0,
        0,
        0,
        4096,
        0,
        0,
        0,
        0,
        4096,
      ];
      final projected = projectGen5McssCameraFx(
        poseEpoch: 42,
        cameraEpoch: 42,
        positionFx: [2048, -1024, 4096],
        cameraFx: identity,
        projectionFx: identity,
      );
      expect(projected, (xFx: 262144, yFx: -98304, zFx: -4096));

      final rounded = projectGen5McssCameraFx(
        poseEpoch: 42,
        cameraEpoch: 42,
        positionFx: [1, -1, 0],
        cameraFx: identity,
        projectionFx: [
          4096,
          0,
          0,
          0,
          0,
          4096,
          0,
          0,
          0,
          0,
          4096,
          0,
          0,
          0,
          0,
          8192,
        ],
      );
      expect(rounded, (xFx: 128, yFx: 0, zFx: 0));
    },
  );

  test(
    'rejects mismatched camera epochs and invalid fixed-point projections',
    () {
      const identity = <int>[
        4096,
        0,
        0,
        0,
        0,
        4096,
        0,
        0,
        0,
        0,
        4096,
        0,
        0,
        0,
        0,
        4096,
      ];
      expect(
        () => projectGen5McssCameraFx(
          poseEpoch: 41,
          cameraEpoch: 42,
          positionFx: [0, 0, 0],
          cameraFx: identity,
          projectionFx: identity,
        ),
        throwsFormatException,
      );
      expect(
        () => projectGen5McssCameraFx(
          poseEpoch: 42,
          cameraEpoch: 42,
          positionFx: [0, 0, 0],
          cameraFx: identity,
          projectionFx: List.filled(16, 0),
        ),
        throwsFormatException,
      );
      expect(
        () => projectGen5McssCameraFx(
          poseEpoch: 42,
          cameraEpoch: 42,
          positionFx: [0, 0, 2147483648],
          cameraFx: identity,
          projectionFx: identity,
        ),
        throwsFormatException,
      );
      expect(
        () => projectGen5McssCameraFx(
          poseEpoch: 42,
          cameraEpoch: 42,
          positionFx: [0, 0, 0],
          cameraFx: List.filled(15, 0),
          projectionFx: identity,
        ),
        throwsFormatException,
      );
      expect(
        () => projectGen5McssCameraFx(
          poseEpoch: 42,
          cameraEpoch: 42,
          positionFx: [0, 0, 0],
          cameraFx: List.filled(16, 2147483647),
          projectionFx: List.filled(16, 2147483647),
        ),
        throwsFormatException,
      );
    },
  );

  test('projects fixed orthographic coordinates before viewport rounding', () {
    expect(projectGen5McssDsOrthoViewportFx(xFx: 0, yFx: 0), (x: 128, y: 96));
    expect(projectGen5McssDsOrthoViewportFx(xFx: 0, yFx: 20360), (
      x: 128,
      y: 91,
    ));
    expect(projectGen5McssDsOrthoViewportFx(xFx: -524288, yFx: 0), (
      x: 0,
      y: 96,
    ));
    expect(
      () => projectGen5McssDsOrthoViewportFx(xFx: 0, yFx: 400000),
      throwsFormatException,
    );
    expect(
      () => projectGen5McssDsOrthoViewportFx(xFx: 2147483648, yFx: 0),
      throwsFormatException,
    );
  });

  test('samples a scaled axis-aligned quad at integer pixel coordinates', () {
    final raster = rasterizeGen5McssDsUvAlignedLinearOpaque(
      atlas: _patternAtlas(),
      width: 7,
      height: 11,
      frontToBack: [
        (
          left: 0,
          top: 0,
          right: 7,
          bottom: 11,
          uLeft: 0,
          uRight: 256,
          vTop: 0,
          vBottom: 256,
        ),
      ],
    );
    expect(raster.indices, [
      1,
      3,
      5,
      7,
      10,
      12,
      14,
      4,
      6,
      8,
      10,
      13,
      15,
      2,
      7,
      9,
      11,
      13,
      1,
      3,
      5,
      13,
      15,
      2,
      4,
      7,
      9,
      11,
      1,
      3,
      5,
      7,
      10,
      12,
      14,
      7,
      9,
      11,
      13,
      1,
      3,
      5,
      10,
      12,
      14,
      1,
      4,
      6,
      8,
      1,
      3,
      5,
      7,
      10,
      12,
      14,
      4,
      6,
      8,
      10,
      13,
      15,
      2,
      10,
      12,
      14,
      1,
      4,
      6,
      8,
      13,
      15,
      2,
      4,
      7,
      9,
      11,
    ]);
  });

  test(
    'interpolates reversed texture coordinates across mirrored atlas edges',
    () {
      final raster = rasterizeGen5McssDsUvAlignedLinearOpaque(
        atlas: _patternAtlas(),
        width: 13,
        height: 9,
        frontToBack: [
          (
            left: 0,
            top: 0,
            right: 13,
            bottom: 9,
            uLeft: 4176,
            uRight: 4048,
            vTop: 2128,
            vBottom: 2000,
          ),
        ],
      );
      expect(raster.indices.take(13), [2, 3, 4, 4, 5, 6, 6, 7, 7, 7, 6, 6, 5]);
      expect(raster.indices.skip(52).take(13), [
        14,
        15,
        1,
        1,
        2,
        3,
        3,
        4,
        4,
        4,
        3,
        3,
        2,
      ]);
      expect(raster.indices.skip(104).take(13), [
        11,
        12,
        13,
        13,
        14,
        15,
        15,
        1,
        1,
        1,
        15,
        15,
        14,
      ]);

      final negative = rasterizeGen5McssDsUvAlignedLinearOpaque(
        atlas: _patternAtlas(),
        width: 7,
        height: 11,
        frontToBack: [
          (
            left: 0,
            top: 0,
            right: 7,
            bottom: 11,
            uLeft: 192,
            uRight: -64,
            vTop: 192,
            vBottom: -64,
          ),
        ],
      );
      expect(negative.indices.take(7), [4, 1, 14, 12, 9, 7, 8]);
      expect(negative.indices.skip(35).take(7), [10, 7, 5, 3, 15, 13, 14]);
      expect(negative.indices.skip(70).take(7), [4, 1, 14, 12, 9, 7, 8]);
    },
  );

  test('composes axis-aligned quads front to back through transparency', () {
    final transparent = Gen5IndexedAtlas.fromIndices(
      Uint8List.fromList(pixels)..[1] = 0,
    );
    final raster = rasterizeGen5McssDsUvAlignedLinearOpaque(
      atlas: transparent,
      width: 2,
      height: 2,
      frontToBack: [
        (
          left: 0,
          top: 0,
          right: 2,
          bottom: 2,
          uLeft: 0,
          uRight: 32,
          vTop: 0,
          vBottom: 32,
        ),
        (
          left: 0,
          top: 0,
          right: 2,
          bottom: 2,
          uLeft: 32,
          uRight: 64,
          vTop: 0,
          vBottom: 32,
        ),
      ],
    );
    expect(raster.indices, [1, 6, 3, 4]);
  });

  test('rejects invalid or unclipped UV-aligned quads', () {
    expect(
      () => rasterizeGen5McssDsUvAlignedLinearOpaque(
        atlas: atlas,
        width: 2,
        height: 2,
        frontToBack: [
          (
            left: -1,
            top: 0,
            right: 2,
            bottom: 2,
            uLeft: 0,
            uRight: 32,
            vTop: 0,
            vBottom: 32,
          ),
        ],
      ),
      throwsFormatException,
    );
    expect(
      () => rasterizeGen5McssDsUvAlignedLinearOpaque(
        atlas: atlas,
        width: 2,
        height: 2,
        frontToBack: [
          (
            left: 0,
            top: 0,
            right: 0,
            bottom: 2,
            uLeft: 0,
            uRight: 32,
            vTop: 0,
            vBottom: 32,
          ),
        ],
      ),
      throwsFormatException,
    );
    expect(
      () => rasterizeGen5McssDsUvAlignedLinearOpaque(
        atlas: atlas,
        width: 2,
        height: 2,
        frontToBack: [
          (
            left: 0,
            top: 0,
            right: 2,
            bottom: 2,
            uLeft: -32769,
            uRight: 32,
            vTop: 0,
            vBottom: 32,
          ),
        ],
      ),
      throwsFormatException,
    );
    expect(
      () => rasterizeGen5McssDsUvAlignedLinearOpaque(
        atlas: atlas,
        width: 257,
        height: 2,
        frontToBack: [],
      ),
      throwsFormatException,
    );
  });

  test('bounds work for UV-aligned quad submissions', () {
    const quad = (
      left: 0,
      top: 0,
      right: 256,
      bottom: 192,
      uLeft: 0,
      uRight: 256,
      vTop: 0,
      vBottom: 256,
    );
    expect(
      () => rasterizeGen5McssDsUvAlignedLinearOpaque(
        atlas: atlas,
        width: 256,
        height: 192,
        frontToBack: List.filled(342, quad),
      ),
      throwsFormatException,
    );
  });

  test(
    'rasterizes indexed quads and converts palette zero to transparency',
    () {
      final raster = rasterizeGen5McssOpaque(
        atlas: atlas,
        nodes: [_node()],
        width: 3,
        height: 3,
        originX: 0,
        originY: 0,
      );
      expect(raster.indices, [1, 2, 0, 3, 4, 0, 0, 0, 0]);
      expect(() => raster.indices[0] = 9, throwsUnsupportedError);

      final palette = List.generate(16, (i) => (r: i, g: i * 2, b: i * 3));
      expect(raster.rgba(palette).take(12), [
        1,
        2,
        3,
        255,
        2,
        4,
        6,
        255,
        0,
        0,
        0,
        0,
      ]);
    },
  );

  test(
    'preserves front-to-back order while transparent texels reveal the next quad',
    () {
      final transparentPixels = Uint8List.fromList(pixels)..[1] = 0;
      final transparentAtlas = Gen5IndexedAtlas.fromIndices(transparentPixels);
      final raster = rasterizeGen5McssOpaque(
        atlas: transparentAtlas,
        nodes: [_node(), _node(textureX: 2)],
        width: 2,
        height: 2,
        originX: 0,
        originY: 0,
      );
      expect(raster.indices, [1, 6, 3, 4]);

      final reversed = rasterizeGen5McssOpaque(
        atlas: transparentAtlas,
        nodes: [_node(), _node(textureX: 2)],
        width: 2,
        height: 2,
        originX: 0,
        originY: 0,
        reverse: true,
      );
      expect(reversed.indices, [5, 6, 7, 8]);
    },
  );

  test('rotates a cell around its origin and clips to the viewport', () {
    final raster = rasterizeGen5McssOpaque(
      atlas: atlas,
      nodes: [_node(rotation: 16384)],
      width: 2,
      height: 2,
      originX: 2,
      originY: 0,
    );
    expect(raster.indices, [3, 1, 4, 2]);

    final clipped = rasterizeGen5McssOpaque(
      atlas: atlas,
      nodes: [_node()],
      width: 1,
      height: 2,
      originX: -1,
      originY: 0,
    );
    expect(clipped.indices, [2, 4]);
  });

  test(
    'mirrors geometry and texture when the horizontal scale is negative',
    () {
      final raster = rasterizeGen5McssOpaque(
        atlas: atlas,
        nodes: [_node()],
        width: 2,
        height: 2,
        originX: 2,
        originY: 0,
        spriteScaleX: -16,
      );
      expect(raster.indices, [2, 1, 4, 3]);
    },
  );

  test('applies node translation and local scaling to sampled texels', () {
    final raster = rasterizeGen5McssOpaque(
      atlas: atlas,
      nodes: [_node(x: 1, scaleX: 8192)],
      width: 6,
      height: 1,
      originX: 0,
      originY: 0,
    );
    expect(raster.indices, [0, 1, 1, 2, 2, 0]);
  });

  test('uses the secondary-cell submission order', () {
    const secondary = Gen5McssQuad(0, 0, 8192, 8192, 8192, 0);
    final nodes = [_node(secondary: secondary)];
    final forward = rasterizeGen5McssOpaque(
      atlas: atlas,
      nodes: nodes,
      width: 2,
      height: 2,
      originX: 0,
      originY: 0,
    );
    final reverse = rasterizeGen5McssOpaque(
      atlas: atlas,
      nodes: nodes,
      width: 2,
      height: 2,
      originX: 0,
      originY: 0,
      reverse: true,
    );
    expect(forward.indices, [5, 6, 7, 8]);
    expect(reverse.indices, [1, 2, 3, 4]);
  });

  test('mirrors texture coordinates across the atlas edge', () {
    final raster = rasterizeGen5McssOpaque(
      atlas: atlas,
      nodes: [_node(textureX: 254, width: 16384)],
      width: 4,
      height: 1,
      originX: 0,
      originY: 0,
    );
    expect(raster.indices, [9, 10, 10, 9]);
  });

  test('samples at pixel centers without rounding the sprite origin', () {
    final onCenter = rasterizeGen5McssOpaque(
      atlas: atlas,
      nodes: [_node()],
      width: 3,
      height: 1,
      originX: 0.5,
      originY: 0,
    );
    final pastCenter = rasterizeGen5McssOpaque(
      atlas: atlas,
      nodes: [_node()],
      width: 3,
      height: 1,
      originX: 0.5001,
      originY: 0,
    );
    expect(onCenter.indices, [1, 2, 0]);
    expect(pastCenter.indices, [0, 1, 2]);
  });

  test('rejects invalid viewport, coordinates and palette', () {
    expect(
      () => rasterizeGen5McssOpaque(
        atlas: atlas,
        nodes: [_node()],
        width: 0,
        height: 2,
        originX: 0,
        originY: 0,
      ),
      throwsFormatException,
    );
    expect(
      () => rasterizeGen5McssOpaque(
        atlas: atlas,
        nodes: [_node()],
        width: 2,
        height: 2,
        originX: 0,
        originY: 0,
        projectedScaleY: double.infinity,
      ),
      throwsFormatException,
    );
    expect(
      () => rasterizeGen5McssOpaque(
        atlas: atlas,
        nodes: List.filled(4097, _node()),
        width: 2,
        height: 2,
        originX: 0,
        originY: 0,
      ),
      throwsFormatException,
    );
    expect(
      () => rasterizeGen5McssOpaque(
        atlas: atlas,
        nodes: [_node(width: -4096)],
        width: 2,
        height: 2,
        originX: 0,
        originY: 0,
      ),
      throwsFormatException,
    );
    expect(
      () => rasterizeGen5McssOpaque(
        atlas: atlas,
        nodes: [_node()],
        width: 1025,
        height: 2,
        originX: 0,
        originY: 0,
      ),
      throwsFormatException,
    );
    expect(
      () => rasterizeGen5McssOpaque(
        atlas: atlas,
        nodes: [_node()],
        width: 2,
        height: 2,
        originX: double.nan,
        originY: 0,
      ),
      throwsFormatException,
    );
    final raster = rasterizeGen5McssOpaque(
      atlas: atlas,
      nodes: [_node()],
      width: 2,
      height: 2,
      originX: 0,
      originY: 0,
    );
    expect(() => raster.rgba([(r: 0, g: 0, b: 0)]), throwsFormatException);
    expect(
      () => raster.rgba(
        List.generate(16, (i) => (r: i == 1 ? 256 : 0, g: 0, b: 0)),
      ),
      throwsFormatException,
    );
  });
}

Gen5IndexedAtlas _patternAtlas() {
  final values = Uint8List(256 * 128);
  for (var y = 0; y < 128; y++) {
    for (var x = 0; x < 256; x++) {
      values[y * 256 + x] = 1 + (x + 3 * y) % 15;
    }
  }
  return Gen5IndexedAtlas.fromIndices(values);
}

Gen5McssActiveNode _node({
  int textureX = 0,
  int rotation = 0,
  int x = 0,
  int scaleX = 4096,
  int parentRotation = 0,
  int width = 8192,
  Gen5McssQuad? secondary,
}) {
  final frame = Gen5NitroFrame(
    targetIndex: 0,
    duration: 1,
    marker: 0,
    transformType: 1,
    rotation: rotation,
    scaleX: scaleX,
    scaleY: 4096,
    translateX: 0,
    translateY: 0,
  );
  final parent = Gen5NitroFrame(
    targetIndex: 0,
    duration: 1,
    marker: 0,
    transformType: 1,
    rotation: parentRotation,
    scaleX: 4096,
    scaleY: 4096,
    translateX: 0,
    translateY: 0,
  );
  final quad = Gen5McssQuad(0, 0, width, 8192, textureX * 4096, 0);
  const empty = Gen5McssQuad(0, 0, 0, 0, 0, 0);
  return Gen5McssActiveNode(
    Gen5ActiveNode(
      record: Gen5NmcrRecord(0, x, 0, 0),
      localFrame: frame,
      parentFrame: parent,
    ),
    Gen5McssCell(quad, secondary ?? empty),
  );
}
