import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flame_3d/core.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/skinned_mesh_partition.dart';

Vertex vertex(
  int index, {
  Vector3? position,
  Vector3? normal,
  bool withNormal = true,
  Vector4? joints,
  Vector4? weights,
}) => Vertex(
  position: position ?? Vector3(index.toDouble(), index * index.toDouble(), 1),
  texCoord: Vector2(index / 10, index / 20),
  color: Color.fromARGB(255, index * 20, 100, 200),
  normal: withNormal ? normal ?? Vector3(0, 0, 1) : null,
  joints:
      joints ?? Vector4(index * 4, index * 4 + 1, index * 4 + 2, index * 4 + 3),
  weights: weights ?? Vector4(.4, .3, .2, .1),
);

Vector3 posed(Vertex value, List<int> globals, int pose) {
  final point = value.position.mutable;
  final result = Vector3.zero();
  for (var i = 0; i < 4; i++) {
    final id = globals[i];
    final transform = Matrix4.translationValues(
      id * .07 + pose * .4,
      id * -.03 + pose * id * .001,
      pose * .5,
    )..rotateZ((id + pose) * .02);
    result.add(
      transform.transform3(point.clone())
        ..scale(value.weights!.mutable.storage[i]),
    );
  }
  return result;
}

void expectVector(Vector3 actual, Vector3 expected) {
  expect(actual.x, closeTo(expected.x, 1e-5));
  expect(actual.y, closeTo(expected.y, 1e-5));
  expect(actual.z, closeTo(expected.z, 1e-5));
}

void main() {
  test('preserves triangle order, attributes, weights and two poses', () {
    final vertices = [for (var i = 0; i < 6; i++) vertex(i)];
    final input = [0, 1, 2, 2, 3, 4, 4, 3, 5];
    final parts = partitionSkinnedMesh(
      verticesWithSkinJointIndices: vertices,
      triangleIndices: input,
    );

    expect(parts, hasLength(2));
    expect(parts.map((part) => part.skinJointToSurfaceJoint.length), [12, 16]);
    expect([
      for (final part in parts)
        for (final index in part.indices) part.sourceVertexIndices[index],
    ], input);
    for (final part in parts) {
      expect(part.skinJointToSurfaceJoint.length, lessThanOrEqualTo(16));
      final globalsByLocal = {
        for (final entry in part.skinJointToSurfaceJoint.entries)
          entry.value: entry.key,
      };
      for (final (local, source) in part.sourceVertexIndices.indexed) {
        final original = vertices[source];
        final result = part.vertices[local];
        expectVector(result.position.mutable, original.position.mutable);
        expectVector(result.normal!.mutable, original.normal!.mutable);
        expect(result.texCoord, original.texCoord);
        expect(result.color, original.color);
        final oldJoints = original.joints!.mutable.storage;
        final newJoints = result.joints!.mutable.storage;
        final oldWeights = original.weights!.mutable.storage;
        final newWeights = result.weights!.mutable.storage;
        final newGlobals = <int>[];
        for (var component = 0; component < 4; component++) {
          expect(newWeights[component], oldWeights[component]);
          expect(
            globalsByLocal[newJoints[component].toInt()],
            oldJoints[component].toInt(),
          );
          newGlobals.add(globalsByLocal[newJoints[component].toInt()]!);
        }
        for (final pose in [0, 1]) {
          expectVector(
            posed(result, newGlobals, pose),
            posed(original, [
              for (final joint in oldJoints) joint.toInt(),
            ], pose),
          );
        }
      }
    }
    expect(input, [0, 1, 2, 2, 3, 4, 4, 3, 5]);
    expect(vertices[4].joints!.mutable.storage, [16, 17, 18, 19]);
  });

  test('ignores zero weights and keeps every nonzero influence', () {
    final vertices = [
      vertex(0, joints: Vector4(1, 50, 51, 52), weights: Vector4(1, 0, 0, 0)),
      vertex(
        1,
        joints: Vector4(1, 2, 51, 52),
        weights: Vector4(.999999, .000001, 0, 0),
      ),
      vertex(2, joints: Vector4(1, 50, 51, 52), weights: Vector4(1, 0, 0, 0)),
    ];
    final part = partitionSkinnedMesh(
      verticesWithSkinJointIndices: vertices,
      triangleIndices: [0, 1, 2],
    ).single;
    expect(part.skinJointToSurfaceJoint.keys.toSet(), {1, 2});
    expect(part.vertices[1].weights!.y, closeTo(.000001, 1e-10));
    expect(part.vertices[1].joints!.y, part.skinJointToSurfaceJoint[2]);
  });

  test('calculates missing normals before the shared edge is split', () {
    final vertices = [
      vertex(
        0,
        position: Vector3(0, 0, 0),
        withNormal: false,
        joints: Vector4.all(2),
        weights: Vector4(1, 0, 0, 0),
      ),
      vertex(
        1,
        position: Vector3(1, 0, 0),
        withNormal: false,
        joints: Vector4.zero(),
        weights: Vector4(1, 0, 0, 0),
      ),
      vertex(
        2,
        position: Vector3(0, 1, 0),
        withNormal: false,
        joints: Vector4.zero(),
        weights: Vector4(1, 0, 0, 0),
      ),
      vertex(
        3,
        position: Vector3(1, 1, 1),
        withNormal: false,
        joints: Vector4.all(1),
        weights: Vector4(1, 0, 0, 0),
      ),
    ];
    final indices = [0, 1, 2, 1, 3, 2];
    final sharedNormal = Vector3(-1, -1, math.sqrt(3) + 1)..normalize();
    final expected = [
      Vector3(0, 0, 1),
      sharedNormal,
      sharedNormal,
      Vector3(-1, -1, 1)..normalize(),
    ];
    final parts = partitionSkinnedMesh(
      verticesWithSkinJointIndices: vertices,
      triangleIndices: indices,
      maximumJointsPerSurface: 2,
    );
    expect(parts, hasLength(2));
    for (final part in parts) {
      for (final (local, source) in part.sourceVertexIndices.indexed) {
        expectVector(part.vertices[local].normal!.mutable, expected[source]);
      }
    }
    final first = parts
        .first
        .vertices[parts.first.sourceVertexIndices.indexOf(1)]
        .normal!
        .mutable;
    final second = parts
        .last
        .vertices[parts.last.sourceVertexIndices.indexOf(1)]
        .normal!
        .mutable;
    expectVector(first, second);
    expect(first.x.abs() + first.y.abs(), greaterThan(.01));
  });

  test('splits a full vertex buffer without changing triangle order', () {
    final vertices = [
      for (var i = 0; i < 4; i++)
        vertex(i, joints: Vector4.zero(), weights: Vector4(1, 0, 0, 0)),
    ];
    final input = [0, 1, 2, 1, 3, 2];
    final parts = partitionSkinnedMesh(
      verticesWithSkinJointIndices: vertices,
      triangleIndices: input,
      maximumVerticesPerSurface: 3,
    );
    expect(parts, hasLength(2));
    expect(parts.map((part) => part.vertices.length), [3, 3]);
    expect([
      for (final part in parts)
        for (final index in part.indices) part.sourceVertexIndices[index],
    ], input);
  });

  test('retains a supplied normal when other normals need calculation', () {
    final supplied = Vector3(0, -1, 0);
    final vertices = [
      vertex(0, withNormal: false),
      vertex(1, normal: supplied),
      vertex(2, withNormal: false),
    ];
    final part = partitionSkinnedMesh(
      verticesWithSkinJointIndices: vertices,
      triangleIndices: [0, 1, 2],
    ).single;
    expectVector(part.vertices[1].normal!.mutable, supplied);
    expect(part.vertices[0].normal, isNotNull);
    expect(part.vertices[2].normal, isNotNull);
  });

  test('returns read-only partition lists and palette', () {
    final parts = partitionSkinnedMesh(
      verticesWithSkinJointIndices: [for (var i = 0; i < 3; i++) vertex(i)],
      triangleIndices: [0, 1, 2],
    );
    expect(() => parts.clear(), throwsUnsupportedError);
    expect(() => parts.single.vertices.clear(), throwsUnsupportedError);
    expect(() => parts.single.indices.clear(), throwsUnsupportedError);
    expect(
      () => parts.single.sourceVertexIndices.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => parts.single.skinJointToSurfaceJoint.clear(),
      throwsUnsupportedError,
    );
  });

  test('enforces input, output and surface budgets', () {
    final vertices = [for (var i = 0; i < 6; i++) vertex(i)];
    final indices = [0, 1, 2, 2, 3, 4, 4, 3, 5];
    expect(
      () => partitionSkinnedMesh(
        verticesWithSkinJointIndices: vertices,
        triangleIndices: indices,
        maximumInputVertices: 5,
      ),
      throwsFormatException,
    );
    expect(
      () => partitionSkinnedMesh(
        verticesWithSkinJointIndices: vertices,
        triangleIndices: indices,
        maximumInputTriangles: 2,
      ),
      throwsFormatException,
    );
    expect(
      () => partitionSkinnedMesh(
        verticesWithSkinJointIndices: vertices,
        triangleIndices: indices,
        maximumOutputVertices: 6,
      ),
      throwsFormatException,
    );
    expect(
      () => partitionSkinnedMesh(
        verticesWithSkinJointIndices: vertices,
        triangleIndices: indices,
        maximumSurfaces: 1,
      ),
      throwsFormatException,
    );
    expect(
      () => partitionSkinnedMesh(
        verticesWithSkinJointIndices: vertices,
        triangleIndices: indices,
        maximumJointsPerSurface: 3,
      ),
      throwsFormatException,
    );
    expect(
      () => partitionSkinnedMesh(
        verticesWithSkinJointIndices: vertices,
        triangleIndices: indices,
        maximumVerticesPerSurface: 65536,
      ),
      throwsArgumentError,
    );
  });

  test('rejects malformed geometry and skin data', () {
    final valid = [for (var i = 0; i < 3; i++) vertex(i)];
    expect(
      () => partitionSkinnedMesh(
        verticesWithSkinJointIndices: valid,
        triangleIndices: [],
      ),
      throwsFormatException,
    );
    expect(
      () => partitionSkinnedMesh(
        verticesWithSkinJointIndices: valid,
        triangleIndices: [0, 1],
      ),
      throwsFormatException,
    );
    expect(
      () => partitionSkinnedMesh(
        verticesWithSkinJointIndices: valid,
        triangleIndices: [0, 1, 3],
      ),
      throwsFormatException,
    );
    expect(
      () => partitionSkinnedMesh(
        verticesWithSkinJointIndices: [
          vertex(0, joints: Vector4(.5, 0, 0, 0)),
          valid[1],
          valid[2],
        ],
        triangleIndices: [0, 1, 2],
      ),
      throwsFormatException,
    );
    expect(
      () => partitionSkinnedMesh(
        verticesWithSkinJointIndices: [
          vertex(0, weights: Vector4(-.1, .5, .5, .1)),
          valid[1],
          valid[2],
        ],
        triangleIndices: [0, 1, 2],
      ),
      throwsFormatException,
    );
    expect(
      () => partitionSkinnedMesh(
        verticesWithSkinJointIndices: [
          vertex(0, weights: Vector4.zero()),
          valid[1],
          valid[2],
        ],
        triangleIndices: [0, 1, 2],
      ),
      throwsFormatException,
    );
    expect(
      () => partitionSkinnedMesh(
        verticesWithSkinJointIndices: [
          vertex(0, position: Vector3(double.nan, 0, 0)),
          valid[1],
          valid[2],
        ],
        triangleIndices: [0, 1, 2],
      ),
      throwsFormatException,
    );
  });
}
