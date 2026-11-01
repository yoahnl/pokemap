import 'package:test/test.dart';

import '../../../tools/gen5_battle_sprite/mcss_bin.dart';
import '../../../tools/gen5_battle_sprite/mcss_geometry.dart';
import '../../../tools/gen5_battle_sprite/multicell.dart';
import '../../../tools/gen5_battle_sprite/nanr.dart';
import '../../../tools/gen5_battle_sprite/nmcr.dart';

void main() {
  test(
    'projects local quad corners with node translation and source units',
    () {
      const node = Gen5ActiveNode(
        record: Gen5NmcrRecord(0, 16, 32, 0),
        localFrame: Gen5NitroFrame(
          targetIndex: 0,
          duration: 1,
          marker: 0,
          transformType: 0,
          rotation: 0,
          scaleX: 4096,
          scaleY: 4096,
          translateX: 16,
          translateY: 16,
        ),
        parentFrame: Gen5NitroFrame(
          targetIndex: 0,
          duration: 1,
          marker: 0,
          transformType: 0,
          rotation: 0,
          scaleX: 4096,
          scaleY: 4096,
          translateX: 0,
          translateY: 0,
        ),
      );
      const quad = Gen5McssQuad(4096, 8192, 16384, 32768, 0, 0);
      final corners = gen5McssLocalCorners(node, quad);
      expect(corners.map((p) => p.x), [3.0, 3.0, 3.25, 3.25]);
      expect(corners.map((p) => p.y), [-1.0, -1.5, -1.5, -1.0]);
      final bounds = gen5McssLocalBounds(node, [quad]);
      expect(
        (bounds.left, bounds.top, bounds.right, bounds.bottom),
        (3.0, -1.5, 3.25, -1.0),
      );
    },
  );

  test('applies child scaling before its clockwise rotation', () {
    const node = Gen5ActiveNode(
      record: Gen5NmcrRecord(0, 0, 0, 0),
      localFrame: Gen5NitroFrame(
        targetIndex: 0,
        duration: 1,
        marker: 0,
        transformType: 1,
        rotation: 16384,
        scaleX: 8192,
        scaleY: 4096,
        translateX: 0,
        translateY: 0,
      ),
      parentFrame: Gen5NitroFrame(
        targetIndex: 0,
        duration: 1,
        marker: 0,
        transformType: 0,
        rotation: 0,
        scaleX: 4096,
        scaleY: 4096,
        translateX: 0,
        translateY: 0,
      ),
    );
    final corners = gen5McssLocalCorners(
      node,
      const Gen5McssQuad(4096, 0, 0, 0, 0, 0),
    );
    expect(corners.first.x, closeTo(0, 1e-12));
    expect(corners.first.y, closeTo(-2, 1e-12));
  });

  test('applies orthographic parent translation, scale and rotation', () {
    const node = Gen5ActiveNode(
      record: Gen5NmcrRecord(0, 0, 0, 0),
      localFrame: Gen5NitroFrame(
        targetIndex: 0,
        duration: 1,
        marker: 0,
        transformType: 0,
        rotation: 0,
        scaleX: 4096,
        scaleY: 4096,
        translateX: 0,
        translateY: 0,
      ),
      parentFrame: Gen5NitroFrame(
        targetIndex: 0,
        duration: 1,
        marker: 0,
        transformType: 1,
        rotation: 16384,
        scaleX: 8192,
        scaleY: 4096,
        translateX: 16,
        translateY: 32,
      ),
    );
    final corners = gen5McssOrthoCorners(
      node,
      const Gen5McssQuad(4096, 0, 0, 0, 0, 0),
      spriteScaleX: 2,
      spriteScaleY: 3,
    );
    expect(corners.first.x, closeTo(2, 1e-12));
    expect(corners.first.y, closeTo(-10, 1e-12));
  });

  test('mirrors the quad vertices and texture origin for negative scale', () {
    const node = Gen5ActiveNode(
      record: Gen5NmcrRecord(0, 0, 0, 0),
      localFrame: Gen5NitroFrame(
        targetIndex: 0,
        duration: 1,
        marker: 0,
        transformType: 0,
        rotation: 0,
        scaleX: 4096,
        scaleY: 4096,
        translateX: 0,
        translateY: 0,
      ),
      parentFrame: Gen5NitroFrame(
        targetIndex: 0,
        duration: 1,
        marker: 0,
        transformType: 0,
        rotation: 0,
        scaleX: 4096,
        scaleY: 4096,
        translateX: 0,
        translateY: 0,
      ),
    );
    const quad = Gen5McssQuad(4096, 0, 16384, 4096, 8192, 0);
    final p = gen5McssOrthoCorners(node, quad, spriteScaleX: -1);
    expect(p.map((v) => v.x), [-1.25, -1.25, -1.0, -1.0]);
    expect(gen5McssTextureX(quad, mirrored: true), 512 * 4096 - 8192 - 16384);
    expect(gen5McssTextureX(quad, mirrored: false), 8192);
  });

  test('rejects an anchor whose homogeneous w is zero', () {
    expect(
      () => gen5McssProjectAnchor([0, 0, 0], List<double>.filled(16, 0)),
      throwsFormatException,
    );
  });

  test('projects the anchor using the supplied view-projection matrix', () {
    final p = gen5McssProjectAnchor(
      [0.5, -0.25, -2],
      [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1],
    );
    expect((p.x, p.y, p.z), (64.0, -24.0, 2.0));
  });

  test('applies row-vector translation and divides x and y by w', () {
    final p = gen5McssProjectAnchor(
      [1, 2, 3],
      [2, 0, 0, 0, 0, 3, 0, 0, 0, 0, 4, 1, 5, 6, 7, 1],
    );
    expect((p.x, p.y, p.z), (224.0, 288.0, -19.0));
  });

  test('projects a sample anchor with the captured GPU projection matrix', () {
    final fixed = <int>[
      13146,
      0,
      0,
      0,
      0,
      17749,
      0,
      0,
      0,
      0,
      -4112,
      -4096,
      0,
      0,
      -8208,
      0,
    ];
    final matrix = fixed.map((value) => value / 4096).toList();
    final p = gen5McssProjectAnchor([1, 2, -10], matrix);
    expect(p.x, closeTo(41.08125, 1e-10));
    expect(p.y, closeTo(83.1984375, 1e-10));
    expect(p.z, closeTo(-8.03515625, 1e-10));
  });

  test('composes a perspective quad through parent, billboard and camera', () {
    const node = Gen5ActiveNode(
      record: Gen5NmcrRecord(0, 0, 0, 0),
      localFrame: Gen5NitroFrame(
        targetIndex: 0,
        duration: 1,
        marker: 0,
        transformType: 0,
        rotation: 0,
        scaleX: 4096,
        scaleY: 4096,
        translateX: 0,
        translateY: 0,
      ),
      parentFrame: Gen5NitroFrame(
        targetIndex: 0,
        duration: 1,
        marker: 0,
        transformType: 0,
        rotation: 0,
        scaleX: 4096,
        scaleY: 4096,
        translateX: 16,
        translateY: 0,
      ),
    );
    final corners = gen5McssPerspectiveClipCorners(
      node,
      const Gen5McssQuad(4096, 0, 4096, 4096, 0, 0),
      position: [1, 2, -5],
      billboard: [1, 0, 0, 0, 1, 0, 0, 0, 1],
      viewProjection: [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1],
      depth: 1024,
    );
    expect(
      (corners.first.x, corners.first.y, corners.first.z, corners.first.w),
      (3.0, 2.0, -4.75, 1.0),
    );
    expect(corners[2].x, 3.0625);
    expect(corners[2].y, 1.9375);
    final rotated = gen5McssPerspectiveClipCorners(
      node,
      const Gen5McssQuad(4096, 0, 4096, 4096, 0, 0),
      position: [1, 2, -5],
      billboard: [0, 1, 0, -1, 0, 0, 0, 0, 1],
      viewProjection: [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 4, -1, 2, 1],
    );
    expect(
      (rotated.first.x, rotated.first.y, rotated.first.z, rotated.first.w),
      (5.0, 3.0, -3.0, 1.0),
    );
  });

  test(
    'computes the captured Gruikui node zero in local sprite coordinates',
    () {
      const parent = Gen5NitroFrame(
        targetIndex: 0,
        duration: 6,
        marker: 0,
        transformType: 1,
        rotation: 0,
        scaleX: 4096,
        scaleY: 4096,
        translateX: 0,
        translateY: 0,
      );
      const child = Gen5NitroFrame(
        targetIndex: 13,
        duration: 6,
        marker: 0,
        transformType: 1,
        rotation: 0,
        scaleX: 4096,
        scaleY: 4096,
        translateX: 0,
        translateY: 0,
      );
      const node = Gen5ActiveNode(
        record: Gen5NmcrRecord(8, -10, -12, 0),
        localFrame: child,
        parentFrame: parent,
      );
      const quad = Gen5McssQuad(-2304, 4096, 32768, 32768, 360448, 0);
      final corners = gen5McssOrthoCorners(
        node,
        quad,
        spriteScaleX: 32,
        spriteScaleY: 32,
      );
      expect(corners.map((p) => p.x), [-38, -38, -22, -22]);
      expect(corners.map((p) => p.y), [56, 40, 40, 56]);
    },
  );

  test(
    'matches captured Moustillon quad edge vectors within fixed-point error',
    () {
      const parent = Gen5NitroFrame(
        targetIndex: 2,
        duration: 138,
        marker: 0,
        transformType: 0,
        rotation: 0,
        scaleX: 4096,
        scaleY: 4096,
        translateX: 0,
        translateY: 0,
      );
      const child = Gen5NitroFrame(
        targetIndex: 18,
        duration: 6,
        marker: 0,
        transformType: 1,
        rotation: 60075,
        scaleX: 4096,
        scaleY: 4096,
        translateX: -4,
        translateY: -8,
      );
      const node = Gen5ActiveNode(
        record: Gen5NmcrRecord(14, -5, -16, 0),
        localFrame: child,
        parentFrame: parent,
      );
      const quad = Gen5McssQuad(-1024, 1024, 32768, 32768, 1015808, 0);
      final corners = gen5McssOrthoCorners(
        node,
        quad,
        spriteScaleX: 16,
        spriteScaleY: 16,
      );
      const gpuClip = [(-735, 1244), (-607, 946), (-386, 1118), (-514, 1416)];
      for (var i = 1; i < 4; i++) {
        final expectedX = (gpuClip[i].$1 - gpuClip[0].$1) / 4096 * 128;
        final expectedY = (gpuClip[i].$2 - gpuClip[0].$2) / 4096 * 96;
        expect(corners[i].x - corners[0].x, closeTo(expectedX, 0.08));
        expect(corners[i].y - corners[0].y, closeTo(expectedY, 0.08));
      }
    },
  );

  test('matches all ten captured Moustillon quad edge vectors', () {
    const rows = <(int, int, int, List<(int, int)>)>[
      (32768, 32768, 60075, [(128, -298), (349, -126), (221, 172)]),
      (65536, 65536, 5461, [(-256, -596), (187, -940), (443, -344)]),
      (32768, 65536, 60075, [(256, -596), (478, -424), (221, 172)]),
      (98304, 98304, 0, [(0, -1032), (768, -1032), (768, 0)]),
      (98304, 65536, 182, [(-9, -688), (759, -706), (767, -18)]),
      (131072, 98304, 182, [(-13, -1032), (1010, -1055), (1023, -24)]),
      (32768, 65536, 60075, [(256, -596), (478, -424), (221, 172)]),
      (65536, 65536, 0, [(0, -688), (512, -688), (512, 0)]),
      (65536, 65536, 3640, [(-175, -647), (306, -882), (481, -235)]),
      (65536, 65536, 0, [(0, -688), (512, -688), (512, 0)]),
    ];
    const parent = Gen5NitroFrame(
      targetIndex: 2,
      duration: 138,
      marker: 0,
      transformType: 0,
      rotation: 0,
      scaleX: 4096,
      scaleY: 4096,
      translateX: 0,
      translateY: 0,
    );
    for (final (width, height, rotation, gpuEdges) in rows) {
      final node = Gen5ActiveNode(
        record: const Gen5NmcrRecord(0, 0, 0, 0),
        localFrame: Gen5NitroFrame(
          targetIndex: 0,
          duration: 6,
          marker: 0,
          transformType: 1,
          rotation: rotation,
          scaleX: 4096,
          scaleY: 4096,
          translateX: 0,
          translateY: 0,
        ),
        parentFrame: parent,
      );
      final corners = gen5McssOrthoCorners(
        node,
        Gen5McssQuad(0, 0, width, height, 0, 0),
        spriteScaleX: 16,
        spriteScaleY: 16,
      );
      for (var i = 1; i < 4; i++) {
        expect(
          corners[i].x - corners[0].x,
          closeTo(gpuEdges[i - 1].$1 / 32, 0.2),
        );
        expect(
          corners[i].y - corners[0].y,
          closeTo(gpuEdges[i - 1].$2 * 96 / 4096, 0.2),
        );
      }
    }
  });
}
