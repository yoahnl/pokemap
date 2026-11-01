import 'package:test/test.dart';

import '../../../tools/gen5_battle_sprite/mcss_bin.dart';
import '../../../tools/gen5_battle_sprite/mcss_pose.dart';
import '../../../tools/gen5_battle_sprite/mcss_submission.dart';
import '../../../tools/gen5_battle_sprite/multicell.dart';
import '../../../tools/gen5_battle_sprite/nanr.dart';
import '../../../tools/gen5_battle_sprite/nmcr.dart';

void main() {
  const primary = Gen5McssQuad(0, 0, 4096, 4096, 0, 0);
  const secondary = Gen5McssQuad(0, 0, 8192, 4096, 0, 4096);
  const absent = Gen5McssQuad(0, 0, 0, 0, 0, 0);
  const frame = Gen5NitroFrame(
    targetIndex: 0,
    duration: 1,
    marker: 0,
    transformType: 0,
    rotation: 0,
    scaleX: 4096,
    scaleY: 4096,
    translateX: 0,
    translateY: 0,
  );
  const node = Gen5ActiveNode(
    record: Gen5NmcrRecord(0, 0, 0, 0),
    localFrame: frame,
    parentFrame: frame,
  );
  const nodes = [
    Gen5McssActiveNode(node, Gen5McssCell(primary, secondary)),
    Gen5McssActiveNode(node, Gen5McssCell(primary, absent)),
  ];

  test('opaque submission advances depth after each quad', () {
    final result = planGen5McssSubmission(nodes, alpha: 31, reverse: false);
    expect(result.map((e) => e.nodeIndex), [0, 0, 1]);
    expect(result.map((e) => e.quad), [secondary, primary, primary]);
    expect(result.map((e) => e.depth), [0, -256, -512]);
    expect(result.map((e) => e.polygonId), [0, 0, 0]);
  });

  test('translucency reverses nodes but not the quad submission order', () {
    final result = planGen5McssSubmission(nodes, alpha: 10, reverse: false);
    expect(result.map((e) => e.nodeIndex), [1, 0, 0]);
    expect(result.map((e) => e.quad), [primary, secondary, primary]);
    expect(result.map((e) => e.depth), [0, 256, 512]);
    expect(result.map((e) => e.polygonId), [1, 0, 0]);
  });

  test('reverse changes both node traversal and quad submission order', () {
    for (final alpha in [10, 31]) {
      final result = planGen5McssSubmission(nodes, alpha: alpha, reverse: true);
      expect(result.map((e) => e.nodeIndex), [1, 0, 0]);
      expect(result.map((e) => e.quad), [primary, primary, secondary]);
      expect(result.map((e) => e.depth), [0, 256, 512]);
    }
  });

  test(
    'orthographic depth and vertical flip preserve secondary UV adjustment',
    () {
      final result = planGen5McssSubmission(
        nodes,
        alpha: 31,
        reverse: false,
        ortho: true,
        flipV: true,
      );
      expect(result.map((e) => e.depth), [0, -1024, -2048]);
      expect(result.first.textureY, secondary.textureY + secondary.height);
      expect(result[1].textureY, primary.textureY);
    },
  );

  test('rejects alpha outside the DS polygon range', () {
    expect(
      () => planGen5McssSubmission(nodes, alpha: 32, reverse: false),
      throwsRangeError,
    );
  });

  test('uses custom and near projection depths and clamps polygon IDs', () {
    final many = List<Gen5McssActiveNode>.filled(65, nodes.last);
    final custom = planGen5McssSubmission(
      many,
      alpha: 1,
      reverse: false,
      cellDepth: 7,
    );
    expect(custom.first.nodeIndex, 64);
    expect(custom.first.polygonId, 63);
    expect(custom[1].depth, 7);
    final near = planGen5McssSubmission(
      nodes,
      alpha: 1,
      reverse: false,
      ortho: true,
      orthoNear: true,
      cellDepth: 7,
      forcePolygonZero: true,
    );
    expect(near.map((e) => e.depth), [0, 256, 512]);
    expect(near.map((e) => e.polygonId), [0, 0, 0]);
  });

  test('follows the captured Moustillon quad and clip-depth sequence', () {
    final captured = List<Gen5McssActiveNode>.generate(
      9,
      (i) => Gen5McssActiveNode(
        node,
        Gen5McssCell(primary, i == 4 ? secondary : absent),
      ),
    );
    final result = planGen5McssSubmission(
      captured,
      alpha: 31,
      reverse: false,
      ortho: true,
      orthoNear: true,
    );
    const gpuClipDepths = [
      -3677,
      -3676,
      -3675,
      -3674,
      -3673,
      -3672,
      -3671,
      -3670,
      -3669,
      -3668,
    ];
    expect(result.map((e) => e.nodeIndex), [0, 1, 2, 3, 4, 4, 5, 6, 7, 8]);
    for (var i = 0; i < result.length; i++) {
      expect(result[i].depth, -256 * i);
      expect(gpuClipDepths[i] - gpuClipDepths.first, i);
    }
    expect(result[4].quad, same(secondary));
    expect(result[5].quad, same(primary));
  });
}
