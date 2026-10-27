part of 'spatial_render_context.dart';

final class SpatialStaticDepthOwner {
  SpatialStaticDepthOwner({
    required this.owner,
    required this.source,
    required Matrix4 transform,
    this.isCurrent,
  }) : transform = transform.clone();

  final Object owner;
  final Model source;
  final Matrix4 transform;
  final bool Function()? isCurrent;
}

final class SpatialStaticDepthBatches {
  SpatialStaticDepthBatches({
    this.maximumOwners = 16,
    this.maximumBatchBytes = 256 * 1024,
    this.maximumRetainedBytes = 4 * 1024 * 1024,
    this.maximumStagingBytes = 2 * 1024 * 1024,
  }) {
    if (maximumOwners < 2 ||
        maximumOwners > 16 ||
        maximumBatchBytes < 1 ||
        maximumBatchBytes > 256 * 1024 ||
        maximumRetainedBytes < 1 ||
        maximumRetainedBytes > 4 * 1024 * 1024 ||
        maximumStagingBytes < 1 ||
        maximumStagingBytes > 2 * 1024 * 1024) {
      throw ArgumentError('Invalid static depth batch limits.');
    }
  }

  final int maximumOwners, maximumBatchBytes;
  final int maximumRetainedBytes, maximumStagingBytes;
  final _batches = <_StaticDepthBatch>{};
  final _preparingBatches = <_StaticDepthBatch>{};
  final _byOwner = HashMap<Object, Map<Surface, _StaticDepthMember>>.identity();
  var _invalidOwners = Expando<bool>('static-depth-invalid-owner');
  Set<Object> _activeOwners = HashSet.identity();
  Future<void> _preparation = Future.value();
  final _candidates = <_StaticDepthBatch>{};
  final _valid = <_StaticDepthBatch>{};
  final _emitted = <_StaticDepthBatch>{};
  final _depthEntries = <_TransparentSurface>[];
  int _generation = 0, _retainedBytes = 0, _frame = 0;
  bool _disposed = false;

  int get batchCount => _batches.length;
  int get retainedBytes => _retainedBytes;
  bool get isDisposed => _disposed;

  Future<void> prepare(
    Iterable<SpatialStaticDepthOwner> sources, {
    required RuntimeResourceBudget budget,
  }) {
    if (_disposed) return Future.value();
    final ticket = ++_generation;
    _invalidOwners = Expando<bool>('static-depth-invalid-owner');
    final owners = sources.toList();
    retainOwners(owners.map((entry) => entry.owner));
    final pending = _preparation.then((_) => _prepare(owners, ticket, budget));
    _preparation = pending.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return pending;
  }

  void retainOwners(Iterable<Object> owners) {
    _activeOwners = HashSet.identity()..addAll(owners);
    for (final owner in _byOwner.keys.toList()) {
      if (!_activeOwners.contains(owner)) invalidateOwner(owner);
    }
  }

  bool _current(int ticket) => !_disposed && ticket == _generation;

  Future<void> _prepare(
    List<SpatialStaticDepthOwner> owners,
    int ticket,
    RuntimeResourceBudget budget,
  ) async {
    if (!_current(ticket)) return;
    final grouped = <(Surface, int, int), List<SpatialStaticDepthOwner>>{};
    final seen = HashSet<Object>.identity();
    final duplicateOwners = HashSet<Object>.identity();
    for (final descriptor in owners) {
      if (!seen.add(descriptor.owner)) duplicateOwners.add(descriptor.owner);
    }
    for (final descriptor in owners) {
      if (duplicateOwners.contains(descriptor.owner) ||
          _invalidOwners[descriptor.owner] == true ||
          !(descriptor.isCurrent?.call() ?? true) ||
          !_translationOnly(descriptor.transform))
        continue;
      final surfaces = _staticSurfaces(descriptor.source);
      if (surfaces == null) continue;
      for (final surface in surfaces) {
        final material = surface.material;
        if (material is! SpatialPixelMaterial ||
            material.alphaMode == Model3dAlphaMode.blend ||
            material.groundDepthOnly ||
            material.lightingRole != SpatialPixelLightingRole.surface)
          continue;
        final cellX = (descriptor.transform.storage[12] / 8).floor();
        final cellZ = (descriptor.transform.storage[14] / 8).floor();
        (grouped[(surface, cellX, cellZ)] ??= []).add(descriptor);
      }
    }
    var committed = false;
    try {
      for (final groupEntry in grouped.entries) {
        final group = groupEntry.value;
        final source = groupEntry.key.$1 as SpatialModelSurface;
        var start = 0;
        while (start < group.length) {
          if (!_current(ticket)) return;
          var count = (group.length - start).clamp(0, maximumOwners);
          while (count > 1 && !_fits(source, count)) {
            count--;
          }
          if (count < 2) break;
          final descriptors = group.sublist(start, start + count);
          start += count;
          final allocation = _allocation(source, count);
          if (_retainedBytes + allocation.resident > maximumRetainedBytes)
            continue;
          RuntimeResourceReservation? lease;
          try {
            lease = await budget.acquire(
              residentBytes: allocation.resident,
              transientBytes: allocation.staging,
              prefetch: true,
              isCurrent: () => _current(ticket),
            );
            lease.ensureCurrent();
            if (!_current(ticket)) continue;
            if (descriptors.any(
              (descriptor) =>
                  !_activeOwners.contains(descriptor.owner) ||
                  _invalidOwners[descriptor.owner] == true ||
                  !(descriptor.isCurrent?.call() ?? true) ||
                  !(_staticSurfaces(descriptor.source)?.contains(source) ??
                      false),
            )) {
              continue;
            }
            final material = source.material;
            if (material is! SpatialPixelMaterial ||
                material.alphaMode == Model3dAlphaMode.blend ||
                material.groundDepthOnly ||
                material.lightingRole != SpatialPixelLightingRole.surface)
              continue;
            final pose = _MaterialPose(material);
            final members = [
              for (final descriptor in descriptors)
                _StaticDepthMember(descriptor, source, material, pose),
            ];
            if (!members.every(_memberCurrent)) continue;
            final vertices = source.clipVertices;
            if (vertices.any(
              (vertex) =>
                  vertex.normal == null ||
                  ![
                    vertex.x,
                    vertex.y,
                    vertex.z,
                    vertex.u,
                    vertex.v,
                    vertex.r,
                    vertex.g,
                    vertex.b,
                    vertex.a,
                    vertex.normal!.x,
                    vertex.normal!.y,
                    vertex.normal!.z,
                  ].every((value) => value.isFinite),
            ))
              continue;
            late final Surface surface;
            try {
              final output = <Vertex>[];
              final indices = <int>[];
              for (final member in members) {
                final transform = member.descriptor.transform.storage;
                final x = _f32(transform[12]), y = _f32(transform[13]);
                final z = _f32(transform[14]);
                final offset = output.length;
                for (final vertex in vertices) {
                  output.add(
                    Vertex(
                      position: Vector3(
                        _f32(_f32(vertex.x) + x),
                        _f32(_f32(vertex.y) + y),
                        _f32(_f32(vertex.z) + z),
                      ),
                      texCoord: Vector2(vertex.u, vertex.v),
                      color: Color.from(
                        red: vertex.r,
                        green: vertex.g,
                        blue: vertex.b,
                        alpha: vertex.a,
                      ),
                      normal: Vector3(
                        vertex.normal!.x,
                        vertex.normal!.y,
                        vertex.normal!.z,
                      ),
                    ),
                  );
                }
                for (final index in source.indices) {
                  indices.add(index + offset);
                }
              }
              surface = Surface(
                vertices: output,
                indices: indices,
                material: members.first.material,
                calculateNormals: false,
              );
              surface.resource;
            } on Object {
              return;
            }
            lease.ensureCurrent();
            if (!_current(ticket) || !members.every(_memberCurrent)) continue;
            lease.commit();
            final batch = _StaticDepthBatch(
              members,
              surface,
              lease,
              allocation.resident,
            );
            lease = null;
            _publish(batch);
          } on RuntimeResourceAdmissionException {
            if (!_current(ticket)) return;
          } finally {
            lease?.release();
          }
          await Future<void>.delayed(Duration.zero);
        }
      }
      if (!_current(ticket)) return;
      for (final batch in _batches.toList()) {
        if (!_preparingBatches.contains(batch) ||
            !batch.members.every(_memberCurrent)) {
          _release(batch);
        }
      }
      committed = true;
    } finally {
      if (!committed) {
        for (final batch in _preparingBatches.toList()) {
          _release(batch);
        }
      }
      _preparingBatches.clear();
    }
  }

  void _publish(_StaticDepthBatch batch) {
    for (final member in batch.members) {
      final previous = _byOwner[member.descriptor.owner]?[member.surface];
      if (previous != null) _release(previous.batch);
    }
    _batches.add(batch);
    _preparingBatches.add(batch);
    _retainedBytes += batch.bytes;
    for (final member in batch.members) {
      (_byOwner[member.descriptor.owner] ??=
              HashMap.identity())[member.surface] =
          member;
    }
  }

  bool _fits(SpatialModelSurface source, int count) {
    final allocation = _allocation(source, count);
    return source.vertexCount > 0 &&
        source.indexCount > 0 &&
        source.vertexCount * count <= 65535 &&
        allocation.resident <= maximumBatchBytes &&
        allocation.staging <= maximumStagingBytes;
  }

  ({int resident, int staging}) _allocation(
    SpatialModelSurface source,
    int count,
  ) {
    final vertices = source.vertexCount * count;
    final indices = source.indexCount * count;
    return (
      resident: vertices * 172 + indices * 4 + 4096 + count * 1536,
      staging:
          vertices * 1024 +
          indices * 16 +
          source.vertexCount * 256 +
          4096 +
          count * 1536,
    );
  }

  bool _memberCurrent(_StaticDepthMember member) {
    final descriptor = member.descriptor;
    return _activeOwners.contains(descriptor.owner) &&
        _invalidOwners[descriptor.owner] != true &&
        (descriptor.isCurrent?.call() ?? true) &&
        _sourceCurrent(member) &&
        identical(member.surface.material, member.material) &&
        member.matchesMaterial();
  }

  bool _sourceCurrent(_StaticDepthMember member) {
    final source = member.descriptor.source;
    final node = member.node;
    return source.nodes.length == 1 &&
        identical(source.nodes.values.single, node) &&
        source.animations.isEmpty &&
        spatialModelClipSourceIssues(source)?.isEmpty == true &&
        node.joints.isEmpty &&
        node.parentNodeIndex == null &&
        _sameValues(node.transform.storage, _depthIdentity.storage) &&
        identical(node.mesh, member.mesh) &&
        member.mesh.surfaceCount == member.surfaceCount &&
        identical(
          member.mesh.surfaces.elementAt(member.surfaceIndex),
          member.surface,
        );
  }

  Iterable<_TransparentSurface> _select(List<_TransparentSurface> captured) {
    _depthEntries.clear();
    _candidates.clear();
    _valid.clear();
    _emitted.clear();
    if (_batches.isEmpty) return captured;
    final frame = ++_frame;
    for (final entry in captured) {
      final member = _byOwner[entry.owner]?[entry.surface];
      if (member == null) continue;
      if (member.frame != frame) {
        member.frame = frame;
        member.captures = 0;
      }
      member.captures++;
      member.captured = entry;
      _candidates.add(member.batch);
    }
    for (final batch in _candidates) {
      var complete = true, changed = false;
      for (final member in batch.members) {
        if (member.frame != frame || member.captures != 1) {
          complete = false;
          member.captured = null;
          continue;
        }
        final entry = member.captured!;
        if (!_memberCurrent(member) ||
            entry.joints.isNotEmpty ||
            !identical(entry.material, member.material) ||
            !_sameValues(
              entry.model.storage,
              member.descriptor.transform.storage,
            ) ||
            !member.matchesPose(entry.pose)) {
          changed = true;
        }
        member.captured = null;
      }
      if (changed) _release(batch);
      if (complete && !changed) _valid.add(batch);
    }
    for (final entry in captured) {
      final batch = _byOwner[entry.owner]?[entry.surface]?.batch;
      if (batch == null || !_valid.contains(batch)) {
        _depthEntries.add(entry);
      } else if (_emitted.add(batch)) {
        _depthEntries.add(batch.entry);
      }
    }
    return _depthEntries;
  }

  void _finishFrame() {
    _candidates.clear();
    _valid.clear();
    _emitted.clear();
    _depthEntries.clear();
  }

  void invalidateOwner(Object owner) {
    _invalidOwners[owner] = true;
    final batches =
        _byOwner[owner]?.values.map((member) => member.batch).toSet() ??
        <_StaticDepthBatch>{};
    for (final batch in batches) {
      _release(batch);
    }
  }

  void _release(_StaticDepthBatch batch) {
    if (!_batches.remove(batch)) return;
    _preparingBatches.remove(batch);
    _retainedBytes -= batch.bytes;
    for (final member in batch.members) {
      final index = _byOwner[member.descriptor.owner];
      if (identical(index?[member.surface], member))
        index?.remove(member.surface);
      if (index?.isEmpty ?? false) _byOwner.remove(member.descriptor.owner);
    }
    batch.lease.release();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    for (final batch in _batches.toList()) {
      _release(batch);
    }
    _activeOwners.clear();
    _invalidOwners = Expando<bool>('static-depth-invalid-owner');
    _byOwner.clear();
    _preparingBatches.clear();
    _candidates.clear();
    _valid.clear();
    _emitted.clear();
    _depthEntries.clear();
  }
}

final class _StaticDepthMember {
  _StaticDepthMember(this.descriptor, this.surface, this.material, this.pose)
    : node = descriptor.source.nodes.values.single,
      mesh = descriptor.source.nodes.values.single.mesh!,
      surfaceCount = descriptor.source.nodes.values.single.mesh!.surfaceCount,
      surfaceIndex = descriptor.source.nodes.values.single.mesh!.surfaces
          .toList()
          .indexOf(surface);
  final SpatialStaticDepthOwner descriptor;
  final SpatialModelSurface surface;
  final SpatialPixelMaterial material;
  final _MaterialPose pose;
  final ModelNode node;
  final Mesh mesh;
  final int surfaceCount, surfaceIndex;
  late final _StaticDepthBatch batch;
  int frame = 0, captures = 0;
  _TransparentSurface? captured;

  bool matchesMaterial() =>
      identical(pose.texture, material.albedoTexture) &&
      pose.color == material.albedoColor &&
      pose.cullMode == material.cullMode &&
      pose.wrapS == material.activeWrapS &&
      pose.wrapT == material.activeWrapT &&
      _sameValues(pose.rect.storage, material.uvRect.storage) &&
      _sameValues(pose.u.storage, material.uvTransformU.storage) &&
      _sameValues(pose.v.storage, material.uvTransformV.storage);

  bool matchesPose(_MaterialPose other) =>
      identical(pose.texture, other.texture) &&
      pose.color == other.color &&
      pose.cullMode == other.cullMode &&
      pose.wrapS == other.wrapS &&
      pose.wrapT == other.wrapT &&
      _sameValues(pose.rect.storage, other.rect.storage) &&
      _sameValues(pose.u.storage, other.u.storage) &&
      _sameValues(pose.v.storage, other.v.storage);
}

final class _StaticDepthBatch {
  _StaticDepthBatch(this.members, this.surface, this.lease, this.bytes) {
    for (final member in members) {
      member.batch = this;
    }
    entry = _TransparentSurface(
      surface: surface,
      material: members.first.material,
      pose: members.first.pose,
      model: Matrix4.identity(),
      joints: const [],
      depth: 0,
      sequence: 0,
      instanceId: null,
      shadowId: null,
      owner: null,
      worldBounds: surface.aabb,
    );
  }
  late final _TransparentSurface entry;
  final List<_StaticDepthMember> members;
  final Surface surface;
  final RuntimeResourceReservation lease;
  final int bytes;
}

Iterable<SpatialModelSurface>? _staticSurfaces(Model model) {
  if (model.animations.isNotEmpty ||
      model.nodes.length != 1 ||
      spatialModelClipSourceIssues(model)?.isEmpty != true)
    return null;
  final node = model.nodes.values.single;
  if (node.parentNodeIndex != null ||
      node.joints.isNotEmpty ||
      !_sameValues(node.transform.storage, _depthIdentity.storage))
    return null;
  final surfaces = node.mesh?.surfaces;
  if (surfaces == null ||
      surfaces.isEmpty ||
      surfaces.toSet().length != surfaces.length ||
      surfaces.any(
        (surface) =>
            surface is! SpatialModelSurface || surface.jointMap != null,
      ))
    return null;
  return surfaces.cast<SpatialModelSurface>();
}

final _depthIdentity = Matrix4.identity();
final _depthFloat = Float32List(1);
double _f32(double value) {
  _depthFloat[0] = value;
  return _depthFloat[0];
}

bool _translationOnly(Matrix4 matrix) {
  final values = matrix.storage;
  for (var index = 0; index < 16; index++) {
    if (index >= 12 && index <= 14) {
      if (!values[index].isFinite || !_f32(values[index]).isFinite)
        return false;
    } else if (values[index] != _depthIdentity.storage[index]) {
      return false;
    }
  }
  return true;
}

bool _sameValues(List<double> a, List<double> b) {
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}
