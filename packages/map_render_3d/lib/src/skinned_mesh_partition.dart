import 'package:flame_3d/core.dart';
import 'package:flame_3d/resources.dart';

final class SkinnedMeshPartition {
  SkinnedMeshPartition({
    required List<Vertex> vertices,
    required List<int> indices,
    required List<int> sourceVertexIndices,
    required Map<int, int> skinJointToSurfaceJoint,
  }) : vertices = List.unmodifiable(vertices),
       indices = List.unmodifiable(indices),
       sourceVertexIndices = List.unmodifiable(sourceVertexIndices),
       skinJointToSurfaceJoint = Map.unmodifiable(skinJointToSurfaceJoint);

  final List<Vertex> vertices;
  final List<int> indices;
  final List<int> sourceVertexIndices;
  final Map<int, int> skinJointToSurfaceJoint;
}

List<SkinnedMeshPartition> partitionSkinnedMesh({
  required List<Vertex> verticesWithSkinJointIndices,
  required List<int> triangleIndices,
  int maximumJointsPerSurface = 16,
  int maximumInputVertices = 65535,
  int maximumInputTriangles = 200000,
  int maximumOutputVertices = 200000,
  int maximumVerticesPerSurface = 65535,
  int maximumSurfaces = 1024,
}) {
  final vertices = verticesWithSkinJointIndices;
  final indices = triangleIndices;
  if (maximumJointsPerSurface < 1 ||
      maximumJointsPerSurface > 16 ||
      maximumInputVertices < 1 ||
      maximumInputTriangles < 1 ||
      maximumOutputVertices < 1 ||
      maximumVerticesPerSurface < 3 ||
      maximumVerticesPerSurface > 65535 ||
      maximumSurfaces < 1) {
    throw ArgumentError('Invalid skin partition limits.');
  }
  if (vertices.isEmpty ||
      indices.isEmpty ||
      indices.length % 3 != 0 ||
      vertices.length > maximumInputVertices ||
      indices.length ~/ 3 > maximumInputTriangles) {
    throw const FormatException('Invalid or oversized skinned geometry.');
  }
  if (indices.any((index) => index < 0 || index >= vertices.length)) {
    throw const FormatException('Triangle index is outside the vertex buffer.');
  }
  for (final vertex in vertices) {
    _validateVertex(vertex);
  }

  final sourceNormals = vertices.any((vertex) => vertex.normal == null)
      ? Vertex.calculateVertexNormals([
          for (final vertex in vertices) vertex.position.mutable,
        ], indices)
      : null;
  if (sourceNormals != null &&
      sourceNormals.any((normal) => normal.storage.any((v) => !v.isFinite))) {
    throw const FormatException('Calculated source normals are invalid.');
  }

  final output = <SkinnedMeshPartition>[];
  var current = _PartitionBuilder();
  var outputVertices = 0;

  void completeCurrent() {
    if (current.indices.isEmpty) return;
    if (output.length >= maximumSurfaces) {
      throw const FormatException('Skin partition surface limit exceeded.');
    }
    output.add(current.finish());
    current = _PartitionBuilder();
  }

  for (var offset = 0; offset < indices.length; offset += 3) {
    final triangle = indices.sublist(offset, offset + 3);
    final sourceVertices = triangle.toSet();
    final triangleJoints = <int>{};
    for (final source in sourceVertices) {
      final vertex = vertices[source];
      final joints = vertex.joints!.mutable.storage;
      final weights = vertex.weights!.mutable.storage;
      for (var component = 0; component < 4; component++) {
        if (weights[component] > 0) {
          triangleJoints.add(joints[component].toInt());
        }
      }
    }
    if (triangleJoints.length > maximumJointsPerSurface ||
        sourceVertices.length > maximumVerticesPerSurface) {
      throw const FormatException('Triangle exceeds skin partition limits.');
    }
    final additionalJoints = triangleJoints.where(
      (joint) => !current.jointMap.containsKey(joint),
    );
    final additionalVertices = sourceVertices.where(
      (source) => !current.sourceToLocal.containsKey(source),
    );
    if (current.jointMap.length + additionalJoints.length >
            maximumJointsPerSurface ||
        current.vertices.length + additionalVertices.length >
            maximumVerticesPerSurface) {
      if (output.length + 1 >= maximumSurfaces) {
        throw const FormatException('Skin partition surface limit exceeded.');
      }
      completeCurrent();
    }
    for (final joint in triangleJoints) {
      current.jointMap.putIfAbsent(joint, () => current.jointMap.length);
    }
    for (final source in triangle) {
      var local = current.sourceToLocal[source];
      if (local == null) {
        if (outputVertices >= maximumOutputVertices) {
          throw const FormatException('Skin partition vertex limit exceeded.');
        }
        final vertex = vertices[source];
        final joints = vertex.joints!.mutable.storage;
        final weights = vertex.weights!.mutable.storage;
        final localized = Vector4.array([
          for (var component = 0; component < 4; component++)
            weights[component] > 0
                ? current.jointMap[joints[component].toInt()]!.toDouble()
                : 0,
        ]);
        local = current.vertices.length;
        current.sourceToLocal[source] = local;
        current.sourceVertexIndices.add(source);
        current.vertices.add(
          vertex.copyWith(
            normal: vertex.normal?.mutable ?? sourceNormals![source],
            joints: localized,
          ),
        );
        outputVertices++;
      }
      current.indices.add(local);
    }
  }
  completeCurrent();
  return List.unmodifiable(output);
}

void _validateVertex(Vertex vertex) {
  final joints = vertex.joints?.mutable.storage;
  final weights = vertex.weights?.mutable.storage;
  if (joints == null ||
      weights == null ||
      vertex.position.mutable.storage.any((value) => !value.isFinite) ||
      vertex.texCoord.mutable.storage.any((value) => !value.isFinite) ||
      (vertex.normal?.mutable.storage.any((value) => !value.isFinite) ??
          false)) {
    throw const FormatException('Invalid skinned vertex attributes.');
  }
  var totalWeight = 0.0;
  for (var component = 0; component < 4; component++) {
    final joint = joints[component];
    final weight = weights[component];
    if (!joint.isFinite ||
        joint < 0 ||
        joint > 65535 ||
        joint != joint.truncateToDouble() ||
        !weight.isFinite ||
        weight < 0 ||
        weight > 1) {
      throw const FormatException('Invalid joint index or skin weight.');
    }
    totalWeight += weight;
  }
  if (totalWeight == 0) {
    throw const FormatException('A skinned vertex has no active weights.');
  }
}

final class _PartitionBuilder {
  final vertices = <Vertex>[];
  final indices = <int>[];
  final sourceVertexIndices = <int>[];
  final sourceToLocal = <int, int>{};
  final jointMap = <int, int>{};

  SkinnedMeshPartition finish() => SkinnedMeshPartition(
    vertices: vertices,
    indices: indices,
    sourceVertexIndices: sourceVertexIndices,
    skinJointToSurfaceJoint: jointMap,
  );
}
