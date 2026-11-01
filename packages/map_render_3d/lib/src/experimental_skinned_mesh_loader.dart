import 'package:flame_3d/core.dart';
import 'package:flame_3d/model.dart';
import 'package:flame_3d/resources.dart';
import 'package:flame_3d/src/parser/gltf/component_type.dart';
import 'package:flame_3d/src/parser/gltf/gltf_root.dart';
import 'package:flame_3d/src/parser/gltf/primitive_mode.dart';

import 'glb_renderer_layout.dart';
import 'skinned_mesh_partition.dart';

void partitionExperimentalSkinnedModel(Model model, GltfRoot root) {
  for (final node in model.nodes.values) {
    final mesh = node.mesh;
    if (mesh == null || node.joints.isEmpty) continue;
    final sourceMesh = root.nodes[node.nodeIndex].mesh?.get();
    if (sourceMesh == null ||
        sourceMesh.primitives.length != mesh.surfaceCount) {
      throw const FormatException(
        'Skinned mesh source does not match its surfaces.',
      );
    }
    final sourceSurfaces = mesh.surfaces.toList();
    final result = <Surface>[];
    for (final (index, primitive) in sourceMesh.primitives.indexed) {
      if (primitive.mode != PrimitiveMode.triangles ||
          primitive.targets.isNotEmpty ||
          primitive.attributes.keys.any(
            (key) =>
                key.startsWith('JOINTS_') && key != 'JOINTS_0' ||
                key.startsWith('WEIGHTS_') && key != 'WEIGHTS_0',
          )) {
        throw const FormatException(
          'Unsupported experimental skinned primitive.',
        );
      }
      final original = sourceSurfaces[index];
      final jointMap = original.jointMap;
      if (jointMap == null ||
          jointMap.isEmpty ||
          primitive.joints == null ||
          primitive.weights == null) {
        throw const FormatException(
          'A skinned primitive requires joints and weights.',
        );
      }
      if (jointMap.keys.any((joint) => !node.joints.containsKey(joint))) {
        throw const FormatException(
          'A skinned primitive references a missing joint.',
        );
      }
      final positionAccessor = primitive.positions?.get().rawAccessor;
      final normalAccessor = primitive.normals?.get().rawAccessor;
      final uvAccessor = primitive.texCoords?.get().rawAccessor;
      final jointAccessor = primitive.joints!.get().rawAccessor;
      final weightAccessor = primitive.weights!.get().rawAccessor;
      if (positionAccessor == null ||
          [positionAccessor, ?normalAccessor, ?uvAccessor, weightAccessor].any(
            (accessor) =>
                accessor.componentType != ComponentType.float ||
                accessor.normalized,
          ) ||
          ![
            ComponentType.unsignedByte,
            ComponentType.unsignedShort,
          ].contains(jointAccessor.componentType) ||
          jointAccessor.normalized) {
        throw const FormatException(
          'Unsupported experimental skinned accessor format.',
        );
      }
      final jointData = primitive.computeJointData();
      for (final weights in jointData.weights) {
        var sum = 0.0;
        for (final value in weights.storage) {
          if (!value.isFinite || value < 0 || value > 1) {
            throw const FormatException('Invalid skin weight.');
          }
          sum += value;
        }
        if (sum == 0) {
          throw const FormatException(
            'A skinned vertex has no active weights.',
          );
        }
      }
      if (jointMap.length <= 16) {
        result.add(original);
        continue;
      }
      final (vertices, indices) = primitive.toFlameVertices(
        jointData,
        Matrix4.identity(),
      );
      if (vertices.length != original.vertexCount ||
          indices.length != original.indices.length ||
          indices.indexed.any(
            (entry) => entry.$2 != original.indices[entry.$1],
          )) {
        throw const FormatException(
          'Skinned source vertex layout is inconsistent.',
        );
      }
      final globalByLocal = {
        for (final entry in jointData.jointMap.entries) entry.value: entry.key,
      };
      final colors = original is SpatialModelSurface
          ? original.vertexColors
          : null;
      final sourceVertices = <Vertex>[];
      for (final (vertexIndex, vertex) in vertices.indexed) {
        final joints = vertex.joints!.mutable.storage;
        final weights = vertex.weights!.mutable.storage;
        sourceVertices.add(
          vertex.copyWith(
            joints: Vector4.array([
              for (var component = 0; component < 4; component++)
                weights[component] > 0
                    ? globalByLocal[joints[component].toInt()]!.toDouble()
                    : 0,
            ]),
            color: colors?[vertexIndex],
          ),
        );
      }
      final partitions = partitionSkinnedMesh(
        verticesWithSkinJointIndices: sourceVertices,
        triangleIndices: indices,
      );
      for (final part in partitions) {
        result.add(
          SpatialModelSurface(
            vertices: part.vertices,
            indices: part.indices,
            material: original.material,
            materialIndex: original is SpatialModelSurface
                ? original.materialIndex
                : null,
            jointMap: part.skinJointToSurfaceJoint,
            transparentSortBounds: original.aabb,
          ),
        );
      }
    }
    mesh.updateSurfaces(
      (surfaces) => surfaces
        ..clear()
        ..addAll(result),
    );
  }
}
