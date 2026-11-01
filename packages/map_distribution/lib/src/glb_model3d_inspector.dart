import 'static_png_validation.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:map_core/map_core.dart';
import 'package:image/image.dart' as img;

import 'game_package_format_exception.dart';
import 'raster_image_dimensions.dart';
import 'strict_json_structure_validator.dart';

final class GlbModel3dInspector {
  const GlbModel3dInspector(
      {this.maxTextureDimension = 4096,
      this.maxTexturePixels = 16777216,
      this.requireStaticTextures = false,
      this.experimentalSkinnedModels = false});

  final int maxTextureDimension;
  final int maxTexturePixels;
  final bool requireStaticTextures;
  final bool experimentalSkinnedModels;

  Model3dInspection inspect(List<int> bytes) {
    if (bytes.length < 28 || bytes.length > 128 * 1024 * 1024) {
      throw const FormatException(
          'GLB size must be between 28 bytes and 128 MiB.');
    }
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    if (data.getUint32(0, Endian.little) != 0x46546c67 ||
        data.getUint32(4, Endian.little) != 2 ||
        data.getUint32(8, Endian.little) != bytes.length) {
      throw const FormatException('A complete glTF 2.0 GLB is required.');
    }
    var offset = 12;
    Map<String, dynamic>? document;
    Uint8List? binary;
    var chunks = 0;
    while (offset < bytes.length) {
      if (offset + 8 > bytes.length) {
        throw const FormatException('Truncated GLB chunk.');
      }
      final length = data.getUint32(offset, Endian.little);
      final type = data.getUint32(offset + 4, Endian.little);
      offset += 8;
      if (length % 4 != 0 || offset + length > bytes.length) {
        throw const FormatException('Invalid GLB chunk bounds.');
      }
      if (chunks == 0 && type == 0x4e4f534a && length <= 8 * 1024 * 1024) {
        final source = utf8.decode(bytes.sublist(offset, offset + length));
        if (experimentalSkinnedModels) {
          try {
            const StrictJsonStructureValidator().validate(source,
                path: 'model.glb', maxDepth: 64, maxNodes: 50000);
          } on GamePackageFormatException {
            throw const FormatException('Invalid or overly complex GLB JSON.');
          }
        }
        document = _object(jsonDecode(source));
      } else if (chunks == 1 && type == 0x004e4942) {
        binary = Uint8List.fromList(bytes.sublist(offset, offset + length));
      } else {
        throw const FormatException('Only JSON and BIN chunks are supported.');
      }
      offset += length;
      chunks++;
    }
    if (document == null || binary == null) {
      throw const FormatException(
          'A standalone GLB requires JSON and BIN chunks.');
    }
    return _Inspection(
            document,
            ByteData.sublistView(binary),
            maxTextureDimension,
            maxTexturePixels,
            requireStaticTextures,
            experimentalSkinnedModels)
        .inspect();
  }
}

final class _Inspection {
  _Inspection(
      this.json,
      this.binary,
      this.maxTextureDimension,
      this.maxTexturePixels,
      this.requireStaticTextures,
      this.experimentalSkinnedModels);
  final int maxTextureDimension, maxTexturePixels;
  final bool requireStaticTextures;
  final bool experimentalSkinnedModels;
  final Map<String, dynamic> json;
  final ByteData binary;
  late final List<Map<String, dynamic>> views;
  late final List<Map<String, dynamic>> accessors;
  late final List<Map<String, dynamic>> meshes;
  late final List<Map<String, dynamic>> nodes;
  late final bool experimentalSkinnedScene;
  final Map<int, _Accessor> decoded = {};
  final Set<String> diagnostics = {};
  final Map<int, int> skinMaximumJoint = {};
  final Set<int> checkedSkinWeights = {};
  final Set<(int, int, int, int?)> checkedSkinPartitions = {};
  var skinPartitionWork = 0;
  var componentBudget = 0;
  var triangleCount = 0;
  var instanceTriangles = 0;
  final Set<int> usedMeshes = {};
  final Set<int> visitedNodes = {};
  final minimum = [double.infinity, double.infinity, double.infinity];
  final maximum = [
    double.negativeInfinity,
    double.negativeInfinity,
    double.negativeInfinity
  ];

  Model3dInspection inspect() {
    final asset = _object(json['asset']);
    if (asset['version'] != '2.0' ||
        (asset['minVersion'] != null && asset['minVersion'] != '2.0')) {
      throw const FormatException('Only glTF 2.0 is supported.');
    }
    final required = _list(json['extensionsRequired']);
    if (required.any((extension) => extension != 'KHR_materials_unlit')) {
      throw const FormatException('A required glTF extension is unsupported.');
    }
    final buffers = _objects(json['buffers'], 1);
    if (buffers.length != 1 || buffers.single.containsKey('uri')) {
      throw const FormatException(
          'GLB must embed one buffer without external URIs.');
    }
    final byteLength = _positiveInt(buffers.single['byteLength']);
    if (byteLength > binary.lengthInBytes ||
        binary.lengthInBytes - byteLength > 3) {
      throw const FormatException(
          'GLB buffer length does not match the BIN chunk.');
    }
    views = _objects(json['bufferViews'], 16384);
    accessors = _objects(json['accessors'], 16384);
    meshes = _objects(json['meshes'], 2048);
    nodes = _objects(json['nodes'], 4096);
    experimentalSkinnedScene = experimentalSkinnedModels &&
        (_list(json['skins']).isNotEmpty ||
            nodes.any((node) => node.containsKey('skin')));
    if (experimentalSkinnedScene &&
        _list(json['extensionsUsed'])
            .any((extension) => extension != 'KHR_materials_unlit')) {
      throw const FormatException('A skeletal model extension is unsupported.');
    }
    if (!experimentalSkinnedModels &&
        (_list(json['skins']).isNotEmpty ||
            nodes.any((node) => node.containsKey('skin')))) {
      throw const FormatException(
          'Skeletal models are unsupported in the initial 3D rendering profile.');
    }
    for (final view in views) {
      if (view['buffer'] != 0) {
        throw const FormatException(
            'Buffer view must reference the embedded buffer.');
      }
      final start = _nonnegativeInt(view['byteOffset'] ?? 0);
      final length = _positiveInt(view['byteLength']);
      if (start + length > byteLength) {
        throw const FormatException('Buffer view exceeds embedded buffer.');
      }
      final stride = view['byteStride'];
      if (stride != null &&
          (stride is! int || stride < 4 || stride > 252 || stride % 4 != 0)) {
        throw const FormatException('Invalid buffer view stride.');
      }
    }
    for (var i = 0; i < accessors.length; i++) {
      accessor(i);
    }
    final images = _objects(json['images'], 256);
    var texturePixels = 0;
    for (final image in images) {
      if (image.containsKey('uri')) {
        throw const FormatException(
            'Model images must be embedded; image URIs are unsupported.');
      }
      final view = views[_index(image['bufferView'], views.length)];
      if (image['mimeType'] != 'image/png' &&
          image['mimeType'] != 'image/jpeg') {
        throw const FormatException('Embedded textures must be PNG or JPEG.');
      }
      final bytes = binary.buffer.asUint8List(
          binary.offsetInBytes + (view['byteOffset'] as int? ?? 0),
          view['byteLength'] as int);
      final dimensions = decodeRasterImageDimensions(bytes,
          mediaType: image['mimeType'] as String);
      if (dimensions == null ||
          dimensions.width > maxTextureDimension ||
          dimensions.height > maxTextureDimension) {
        throw const FormatException(
            'Embedded textures must have valid dimensions of at most 4096 pixels per axis.');
      }
      texturePixels += dimensions.width * dimensions.height;
      if (texturePixels > maxTexturePixels) {
        throw const FormatException('Model texture pixel budget exceeded.');
      }
      try {
        final img.Image? decoded;
        if (requireStaticTextures && image['mimeType'] == 'image/png') {
          final decoder = validatedStaticPngDecoder(bytes,
              maxDimension: maxTextureDimension, maxPixels: maxTexturePixels);
          decoded = decoder.decodeFrame(0);
        } else {
          decoded = img.decodeImage(bytes);
        }
        if (decoded == null ||
            decoded.width != dimensions.width ||
            decoded.height != dimensions.height) {
          throw const FormatException('Embedded texture data is invalid.');
        }
      } on Object {
        throw const FormatException('Embedded texture data is invalid.');
      }
    }
    final samplers = _objects(json['samplers'], 1024);
    for (final sampler in samplers) {
      for (final axis in ['wrapS', 'wrapT']) {
        if (![10497, 33648, 33071].contains(sampler[axis] ?? 10497)) {
          throw const FormatException('Unsupported texture wrap mode.');
        }
      }
    }
    final textures = _objects(json['textures'], 1024);
    for (final texture in textures) {
      _index(texture['source'], images.length);
      if (texture['sampler'] != null) {
        _index(texture['sampler'], samplers.length);
      }
    }
    final materials = _materials(textures.length);
    for (final mesh in meshes) {
      if (mesh.containsKey('weights')) {
        throw const FormatException('Morph targets are unsupported.');
      }
      for (final primitive in _objects(mesh['primitives'], 4096)) {
        if ((primitive['mode'] ?? 4) != 4 || primitive.containsKey('targets')) {
          throw const FormatException(
              'Only triangle primitives without morph targets are supported.');
        }
        if (primitive['material'] == null) {
          diagnostics.add('renderer.missing_material_magenta');
        }
        if (primitive['material'] != null) {
          _index(primitive['material'], materials.length);
        }
        final attributes = _object(primitive['attributes']);
        if (experimentalSkinnedScene &&
            attributes.keys.any((key) => !const {
                  'POSITION',
                  'NORMAL',
                  'TEXCOORD_0',
                  'COLOR_0',
                  'JOINTS_0',
                  'WEIGHTS_0'
                }.contains(key))) {
          throw const FormatException(
              'A skeletal vertex attribute is unsupported.');
        }
        final positions =
            accessor(_index(attributes['POSITION'], accessors.length));
        if (positions.type != 'VEC3' || positions.componentType != 5126) {
          throw const FormatException(
              'Positions must be float VEC3 accessors.');
        }
        for (final entry in attributes.entries) {
          final values = accessor(_index(entry.value, accessors.length));
          if (values.count != positions.count) {
            throw const FormatException(
                'Vertex attributes must have matching counts.');
          }
          if (entry.key == 'NORMAL' &&
              (values.type != 'VEC3' ||
                  values.componentType != 5126 ||
                  values.normalized)) {
            throw const FormatException(
                'Normals must be nonnormalized float VEC3 accessors.');
          }
          if (entry.key.startsWith('COLOR_')) {
            if (entry.key != 'COLOR_0' ||
                !['VEC3', 'VEC4'].contains(values.type) ||
                values.componentType != 5126 ||
                values.normalized ||
                values.values.any((value) => value < 0 || value > 1)) {
              throw const FormatException(
                  'COLOR_0 must contain nonnormalized float RGB or RGBA values between zero and one.');
            }
          }
          if (entry.key == 'TANGENT') {
            diagnostics.add('renderer.ignored_${entry.key.toLowerCase()}');
          }
          if (entry.key.startsWith('TEXCOORD_') &&
              (values.type != 'VEC2' || values.componentType != 5126)) {
            throw const FormatException(
                'Texture coordinates must be float VEC2.');
          }
          if (entry.key.startsWith('JOINTS_') ||
              entry.key.startsWith('WEIGHTS_')) {
            if (!experimentalSkinnedModels) {
              throw const FormatException(
                  'Skeletal vertex attributes are unsupported in the initial 3D rendering profile.');
            }
            if (entry.key != 'JOINTS_0' && entry.key != 'WEIGHTS_0') {
              throw const FormatException(
                  'Additional skeletal vertex attributes are unsupported.');
            }
          }
        }
        if (experimentalSkinnedModels &&
            (attributes.containsKey('JOINTS_0') ||
                attributes.containsKey('WEIGHTS_0'))) {
          _validateSkinAttributes(attributes);
        }
        var count = positions.count;
        if (primitive['indices'] != null) {
          final indices =
              accessor(_index(primitive['indices'], accessors.length));
          if (indices.type != 'SCALAR' ||
              ![5121, 5123, 5125].contains(indices.componentType) ||
              indices.normalized) {
            throw const FormatException(
                'Indices must be unsigned scalar integers.');
          }
          for (final value in indices.values) {
            if (value >= positions.count || value > 65535) {
              throw const FormatException(
                  'Indices exceed the supported vertex range.');
            }
          }
          count = indices.count;
        } else if (count > 65536) {
          throw const FormatException(
              'A primitive supports at most 65536 nonindexed vertices.');
        }
        if (count % 3 != 0) {
          throw const FormatException(
              'Triangle vertex count must be divisible by three.');
        }
        triangleCount += count ~/ 3;
        if (triangleCount > 1000000) {
          throw const FormatException('Model triangle budget exceeded.');
        }
      }
    }
    final scenes = _objects(json['scenes'], 256);
    final scene = scenes[_index(json['scene'], scenes.length)];
    for (final root in _list(scene['nodes'])) {
      _visit(_index(root, nodes.length), _identity(), <int>{});
    }
    if (usedMeshes.isEmpty || minimum.any((v) => !v.isFinite)) {
      throw const FormatException(
          'The default scene must contain visible triangle geometry.');
    }
    if (experimentalSkinnedModels) {
      _validateExperimentalSkins();
    }
    final animations = _animations();
    final materialAnimations = Model3dMaterialAnimations.fromGlbJson(json);
    final sourceMaterials = _objects(json['materials'], 1024);
    final nodeAnimationCount = animations.length;
    for (var i = 0; i < materialAnimations.clips.length; i++) {
      final clip = materialAnimations.clips[i];
      for (final track in clip.tracks) {
        final pbr =
            sourceMaterials[track.materialIndex]['pbrMetallicRoughness'];
        if (pbr is! Map || pbr['baseColorTexture'] == null) {
          throw const FormatException(
              'Material animations require a base color texture.');
        }
      }
      animations.add(Model3dAnimation(
          index: nodeAnimationCount + i,
          name: clip.name,
          durationSeconds: clip.durationSeconds));
    }
    return Model3dInspection(
        bounds: Model3dBounds(
            min: Model3dVector3(x: minimum[0], y: minimum[1], z: minimum[2]),
            max: Model3dVector3(x: maximum[0], y: maximum[1], z: maximum[2])),
        meshCount: usedMeshes.length,
        triangleCount: instanceTriangles,
        materials: materials,
        animations: animations,
        diagnostics: diagnostics.toList()..sort());
  }

  _Accessor accessor(int index) {
    final cached = decoded[index];
    if (cached != null) return cached;
    final value = accessors[index];
    if (value.containsKey('sparse')) {
      throw const FormatException('Sparse accessors are unsupported.');
    }
    final view = views[_index(value['bufferView'], views.length)];
    final count = _positiveInt(value['count']);
    final type = value['type'];
    final components =
        const {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}[type];
    final componentType = value['componentType'];
    final width = const {
      5120: 1,
      5121: 1,
      5122: 2,
      5123: 2,
      5125: 4,
      5126: 4
    }[componentType];
    if (components == null || width == null) {
      throw const FormatException('Unsupported accessor type.');
    }
    componentBudget += count * components;
    if (componentBudget > 8000000) {
      throw const FormatException('Model accessor complexity budget exceeded.');
    }
    final offset = _nonnegativeInt(value['byteOffset'] ?? 0);
    final viewOffset = _nonnegativeInt(view['byteOffset'] ?? 0);
    final packed = components * width;
    final stride = view['byteStride'] as int? ?? packed;
    if (offset % width != 0 ||
        (offset + viewOffset) % width != 0 ||
        stride < packed ||
        stride % width != 0 ||
        offset + (count - 1) * stride + packed > view['byteLength']) {
      throw const FormatException(
          'Accessor exceeds or misaligns its buffer view.');
    }
    if (experimentalSkinnedScene &&
        (stride != packed ||
            ((view['byteLength'] as int) - offset) % stride != 0)) {
      throw const FormatException(
          'Accessor stride is unsupported by the skeletal loader.');
    }
    final normalized = value['normalized'] ?? false;
    if (normalized is! bool ||
        normalized && ![5120, 5121, 5122, 5123].contains(componentType)) {
      throw const FormatException('Invalid normalized accessor.');
    }
    final values = <double>[];
    final min = List.filled(components, double.infinity);
    final max = List.filled(components, double.negativeInfinity);
    for (var row = 0; row < count; row++) {
      for (var column = 0; column < components; column++) {
        final position = viewOffset + offset + row * stride + column * width;
        var number = switch (componentType) {
          5120 => binary.getInt8(position).toDouble(),
          5121 => binary.getUint8(position).toDouble(),
          5122 => binary.getInt16(position, Endian.little).toDouble(),
          5123 => binary.getUint16(position, Endian.little).toDouble(),
          5125 => binary.getUint32(position, Endian.little).toDouble(),
          _ => binary.getFloat32(position, Endian.little),
        };
        if (!number.isFinite) {
          throw const FormatException('Accessor contains nonfinite numbers.');
        }
        min[column] = math.min(min[column], number);
        max[column] = math.max(max[column], number);
        if (normalized) {
          number = switch (componentType) {
            5120 => math.max(number / 127, -1).toDouble(),
            5121 => number / 255,
            5122 => math.max(number / 32767, -1).toDouble(),
            _ => number / 65535
          };
        }
        values.add(number);
      }
    }
    for (final entry in {'min': min, 'max': max}.entries) {
      if (value[entry.key] == null) continue;
      final declared = _numbers(value[entry.key], components);
      for (var i = 0; i < components; i++) {
        if ((declared[i] - entry.value[i]).abs() >
            math.max(1e-6, entry.value[i].abs() * 1e-6)) {
          throw const FormatException(
              'Accessor declared bounds do not match its data.');
        }
      }
    }
    return decoded[index] = _Accessor(
        type as String, componentType as int, count, normalized, values);
  }

  void _validateSkinAttributes(Map<String, dynamic> attributes) {
    if (!attributes.containsKey('JOINTS_0') ||
        !attributes.containsKey('WEIGHTS_0')) {
      throw const FormatException(
          'Skinned primitives require joints and weights.');
    }
    final jointIndex = _index(attributes['JOINTS_0'], accessors.length);
    final weightIndex = _index(attributes['WEIGHTS_0'], accessors.length);
    final joints = accessor(jointIndex);
    final weights = accessor(weightIndex);
    if (joints.type != 'VEC4' ||
        ![5121, 5123].contains(joints.componentType) ||
        joints.normalized ||
        weights.type != 'VEC4' ||
        weights.componentType != 5126 ||
        weights.normalized ||
        joints.count != weights.count) {
      throw const FormatException('Unsupported skeletal accessor format.');
    }
    skinMaximumJoint.putIfAbsent(jointIndex, () {
      var maximum = 0;
      for (final joint in joints.values) {
        maximum = math.max(maximum, joint.toInt());
      }
      return maximum;
    });
    if (checkedSkinWeights.add(weightIndex)) {
      for (var vertex = 0; vertex < weights.count; vertex++) {
        var total = 0.0;
        for (var component = 0; component < 4; component++) {
          final weight = weights.values[vertex * 4 + component];
          if (weight < 0 || weight > 1) {
            throw const FormatException(
                'Skin weights must be between zero and one.');
          }
          total += weight;
        }
        if ((total - 1).abs() > 1e-4) {
          throw const FormatException('Skin weights must sum to one.');
        }
      }
    }
  }

  void _validateExperimentalSkins() {
    final skins = _objects(json['skins'], 256);
    final jointsBySkin = <List<int>>[];
    for (final skin in skins) {
      final joints = [
        for (final value in _list(skin['joints'])) _index(value, nodes.length)
      ];
      if (joints.isEmpty || joints.toSet().length != joints.length) {
        throw const FormatException('A skin requires distinct joints.');
      }
      if (skin['skeleton'] != null) {
        _index(skin['skeleton'], nodes.length);
      }
      if (skin['inverseBindMatrices'] != null) {
        final matrices =
            accessor(_index(skin['inverseBindMatrices'], accessors.length));
        if (matrices.type != 'MAT4' ||
            matrices.componentType != 5126 ||
            matrices.normalized ||
            matrices.count != joints.length) {
          throw const FormatException(
              'Inverse bind matrices must match the skin joints.');
        }
        for (var offset = 0; offset < matrices.values.length; offset += 16) {
          if (matrices.values[offset + 3] != 0 ||
              matrices.values[offset + 7] != 0 ||
              matrices.values[offset + 11] != 0 ||
              matrices.values[offset + 15] != 1) {
            throw const FormatException(
                'Inverse bind matrices must be affine.');
          }
        }
      }
      jointsBySkin.add(joints);
    }
    final dependencies = <int, Set<int>>{
      for (final node in visitedNodes) node: <int>{}
    };
    final parents = <int, int>{};
    for (final parent in visitedNodes) {
      for (final child in _list(nodes[parent]['children'])) {
        final index = _index(child, nodes.length);
        dependencies[index]!.add(parent);
        parents[index] = parent;
      }
    }
    final nodeOrder = <int, int>{};
    final subtreeEnd = <int, int>{};
    var nextOrder = 0;
    for (final node in visitedNodes) {
      nodeOrder[node] = nextOrder;
      subtreeEnd[node] = nextOrder++;
    }
    for (final node in visitedNodes.toList().reversed) {
      final parent = parents[node];
      if (parent != null) {
        subtreeEnd[parent] = math.max(subtreeEnd[parent]!, subtreeEnd[node]!);
      }
    }
    final checkedSkeletons = <int>{};
    var jointInstances = 0;
    for (var nodeIndex = 0; nodeIndex < nodes.length; nodeIndex++) {
      final node = nodes[nodeIndex];
      final meshValue = node['mesh'];
      final skinValue = node['skin'];
      if (skinValue != null && meshValue == null) {
        throw const FormatException('A skin requires a mesh.');
      }
      if (meshValue == null) continue;
      final mesh = meshes[_index(meshValue, meshes.length)];
      final skinIndex =
          skinValue == null ? null : _index(skinValue, jointsBySkin.length);
      final joints = skinIndex == null ? null : jointsBySkin[skinIndex];
      if (joints != null && visitedNodes.contains(nodeIndex)) {
        jointInstances += joints.length;
        if (jointInstances > 65536 ||
            joints.any((joint) => !visitedNodes.contains(joint))) {
          throw const FormatException('Skin joints exceed the scene limits.');
        }
        final skeleton = skins[skinIndex!]['skeleton'];
        if (skeleton != null && checkedSkeletons.add(skinIndex)) {
          final root = _index(skeleton, nodes.length);
          final start = nodeOrder[root];
          final end = subtreeEnd[root];
          if (start == null || end == null) {
            throw const FormatException(
                'Skeleton must be an ancestor of its joints.');
          }
          for (final joint in joints) {
            final order = nodeOrder[joint]!;
            if (order < start || order > end) {
              throw const FormatException(
                  'Skeleton must be an ancestor of its joints.');
            }
          }
        }
        dependencies[nodeIndex]!.addAll(joints);
      }
      final primitives = _objects(mesh['primitives'], 4096);
      if (joints != null && primitives.isEmpty) {
        throw const FormatException('A skinned mesh requires primitives.');
      }
      for (final primitive in primitives) {
        final attributes = _object(primitive['attributes']);
        final hasSkin = attributes.containsKey('JOINTS_0') ||
            attributes.containsKey('WEIGHTS_0');
        if (hasSkin != (joints != null)) {
          throw const FormatException(
              'Mesh skin and vertex attributes must match.');
        }
        if (joints == null) continue;
        final jointIndex = _index(attributes['JOINTS_0'], accessors.length);
        if (skinMaximumJoint[jointIndex]! >= joints.length) {
          throw const FormatException(
              'A vertex references a missing skin joint.');
        }
        final vertices =
            accessor(_index(attributes['POSITION'], accessors.length)).count;
        final indices = primitive['indices'] == null
            ? vertices
            : accessor(_index(primitive['indices'], accessors.length)).count;
        if (vertices > 65535 || indices ~/ 3 > 200000) {
          throw const FormatException(
              'Skinned geometry exceeds partition limits.');
        }
        _validateSkinPartition(
          _index(attributes['POSITION'], accessors.length),
          jointIndex,
          _index(attributes['WEIGHTS_0'], accessors.length),
          primitive['indices'] == null
              ? null
              : _index(primitive['indices'], accessors.length),
        );
      }
    }
    final dependants = <int, List<int>>{};
    final pending = <int, int>{};
    for (final entry in dependencies.entries) {
      pending[entry.key] = entry.value.length;
      for (final dependency in entry.value) {
        (dependants[dependency] ??= []).add(entry.key);
      }
    }
    final queue = <int>[
      for (final entry in pending.entries)
        if (entry.value == 0) entry.key
    ];
    for (var offset = 0; offset < queue.length; offset++) {
      for (final dependant in dependants[queue[offset]] ?? const <int>[]) {
        final remaining = pending[dependant]! - 1;
        pending[dependant] = remaining;
        if (remaining == 0) queue.add(dependant);
      }
    }
    if (queue.length != pending.length) {
      throw const FormatException(
          'Skin and scene dependencies must be acyclic.');
    }
    if (skins.isNotEmpty) diagnostics.add('bounds.static_scene_only');
  }

  void _validateSkinPartition(
      int positionIndex, int jointIndex, int weightIndex, int? indexIndex) {
    if (!checkedSkinPartitions
        .add((positionIndex, jointIndex, weightIndex, indexIndex))) {
      return;
    }
    final vertices = accessor(positionIndex).count;
    final indices = indexIndex == null ? null : accessor(indexIndex).values;
    final indexCount = indices?.length ?? vertices;
    skinPartitionWork += vertices + indexCount;
    if (skinPartitionWork > 8000000) {
      throw const FormatException('Skin partition inspection budget exceeded.');
    }
    final joints = accessor(jointIndex).values;
    final weights = accessor(weightIndex).values;
    final active = <int>{};
    for (var offset = 0; offset < weights.length; offset++) {
      if (weights[offset] > 0) active.add(joints[offset].toInt());
      if (active.length > 16) break;
    }
    if (active.length <= 16) return;
    final surfaceJoints = <int>{};
    final surfaceVertices = <int>{};
    var surfaceCount = 1;
    var outputVertices = 0;
    for (var offset = 0; offset < indexCount; offset += 3) {
      final triangleVertices = <int>{};
      final triangleJoints = <int>{};
      for (var corner = 0; corner < 3; corner++) {
        final vertex = indices == null
            ? offset + corner
            : indices[offset + corner].toInt();
        triangleVertices.add(vertex);
        for (var component = 0; component < 4; component++) {
          final index = vertex * 4 + component;
          if (weights[index] > 0) triangleJoints.add(joints[index].toInt());
        }
      }
      final additionalJoints = triangleJoints.difference(surfaceJoints).length;
      final additionalVertices =
          triangleVertices.difference(surfaceVertices).length;
      if (surfaceJoints.length + additionalJoints > 16 ||
          surfaceVertices.length + additionalVertices > 65535) {
        surfaceCount++;
        if (surfaceCount > 1024) {
          throw const FormatException('Skin partition surface limit exceeded.');
        }
        surfaceJoints.clear();
        surfaceVertices.clear();
      }
      outputVertices += triangleVertices.difference(surfaceVertices).length;
      if (outputVertices > 200000) {
        throw const FormatException('Skin partition vertex limit exceeded.');
      }
      surfaceJoints.addAll(triangleJoints);
      surfaceVertices.addAll(triangleVertices);
    }
  }

  List<Model3dMaterial> _materials(int textureCount) {
    final entries = _objects(json['materials'], 1024);
    for (final material in entries) {
      final mode = material['alphaMode'] ?? 'OPAQUE';
      if (!['OPAQUE', 'MASK', 'BLEND'].contains(mode) ||
          (mode == 'MASK' && material['alphaCutoff'] != .5) ||
          (mode != 'MASK' && material.containsKey('alphaCutoff')) ||
          (material.containsKey('doubleSided') &&
              material['doubleSided'] is! bool)) {
        throw const FormatException(
            'OPAQUE and BLEND forbid alpha cutoff; MASK requires cutoff 0.5; doubleSided must be boolean.');
      }
      for (final key in [
        'normalTexture',
        'occlusionTexture',
        'emissiveTexture'
      ]) {
        if (material[key] != null) {
          _index(_object(material[key])['index'], textureCount);
          diagnostics.add('renderer.ignored_$key');
        }
      }
      if (material['emissiveFactor'] != null) {
        _numbers(material['emissiveFactor'], 3);
        diagnostics.add('renderer.ignored_emissiveFactor');
      }
      final pbr = material['pbrMetallicRoughness'];
      if (pbr != null) {
        final value = _object(pbr);
        if (value['baseColorFactor'] != null) {
          final color = _numbers(value['baseColorFactor'], 4);
          if (color.any((v) => v < 0 || v > 1)) {
            throw const FormatException(
                'Material color factors must be between zero and one.');
          }
        }
        for (final key in ['baseColorTexture', 'metallicRoughnessTexture']) {
          if (value[key] != null) {
            final texture = _object(value[key]);
            _index(texture['index'], textureCount);
            if ((texture['texCoord'] ?? 0) != 0 ||
                texture.containsKey('extensions')) {
              throw const FormatException(
                  'Only untransformed TEXCOORD_0 textures are supported.');
            }
            if (key != 'baseColorTexture') {
              diagnostics.add('renderer.ignored_$key');
            }
          }
        }
        for (final key in ['metallicFactor', 'roughnessFactor']) {
          if (value[key] != null) {
            final factor = _number(value[key]);
            if (factor < 0 || factor > 1) {
              throw const FormatException(
                  'Material factors must be between zero and one.');
            }
            diagnostics.add('renderer.ignored_$key');
          }
        }
      }
    }
    return [
      for (var i = 0; i < entries.length; i++)
        Model3dMaterial(
            index: i,
            name: _label(entries[i]['name'], 'Material ${i + 1}'),
            alphaMode: switch (entries[i]['alphaMode']) {
              'MASK' => Model3dAlphaMode.mask,
              'BLEND' => Model3dAlphaMode.blend,
              _ => Model3dAlphaMode.opaque,
            },
            alphaCutoff: entries[i]['alphaMode'] == 'MASK' ? .5 : null,
            doubleSided: entries[i]['doubleSided'] as bool? ?? false)
    ];
  }

  void _visit(int index, List<double> parent, Set<int> ancestors) {
    if (ancestors.length > 128 ||
        !ancestors.add(index) ||
        !visitedNodes.add(index)) {
      throw const FormatException('Scene hierarchy must be a bounded tree.');
    }
    final node = nodes[index];
    if (node.containsKey('weights')) {
      throw const FormatException('Morph target weights are unsupported.');
    }
    final transform = _multiply(parent, _transform(node));
    if (transform.any((v) => !v.isFinite)) {
      throw const FormatException('Scene transform exceeds numeric bounds.');
    }
    if (node['mesh'] != null) {
      final meshIndex = _index(node['mesh'], meshes.length);
      usedMeshes.add(meshIndex);
      for (final primitive in _objects(meshes[meshIndex]['primitives'], 4096)) {
        final positions = accessor(_index(
            _object(primitive['attributes'])['POSITION'], accessors.length));
        final indices = primitive['indices'] == null
            ? null
            : accessor(_index(primitive['indices'], accessors.length)).values;
        final count = indices?.length ?? positions.count;
        instanceTriangles += count ~/ 3;
        if (instanceTriangles > 1000000) {
          throw const FormatException('Scene triangle budget exceeded.');
        }
        final offsets = indices?.map((index) => index.toInt() * 3) ??
            Iterable<int>.generate(positions.count, (index) => index * 3);
        for (final i in offsets) {
          for (var axis = 0; axis < 3; axis++) {
            final value = transform[axis] * positions.values[i] +
                transform[4 + axis] * positions.values[i + 1] +
                transform[8 + axis] * positions.values[i + 2] +
                transform[12 + axis];
            if (!value.isFinite || value.abs() > 1e12) {
              throw const FormatException(
                  'Model bounds exceed supported coordinates.');
            }
            minimum[axis] = math.min(minimum[axis], value);
            maximum[axis] = math.max(maximum[axis], value);
          }
        }
      }
    }
    for (final child in _list(node['children'])) {
      _visit(_index(child, nodes.length), transform, ancestors);
    }
    ancestors.remove(index);
  }

  List<Model3dAnimation> _animations() {
    final animations = _objects(json['animations'], 256);
    final result = <Model3dAnimation>[];
    for (var i = 0; i < animations.length; i++) {
      final animation = animations[i];
      final samplers = _objects(animation['samplers'], 4096);
      var duration = 0.0;
      if (samplers.isEmpty) {
        throw const FormatException('Animation must contain samplers.');
      }
      for (final sampler in samplers) {
        if (!['LINEAR', 'STEP']
            .contains(sampler['interpolation'] ?? 'LINEAR')) {
          throw const FormatException(
              'Only LINEAR and STEP animation interpolation is supported.');
        }
        final input = accessor(_index(sampler['input'], accessors.length));
        final output = accessor(_index(sampler['output'], accessors.length));
        if (input.type != 'SCALAR' ||
            input.componentType != 5126 ||
            input.count != output.count ||
            output.componentType != 5126) {
          throw const FormatException(
              'Invalid animation input and output accessors.');
        }
        var previous = -1.0;
        for (final time in input.values) {
          if (time < 0 || time <= previous) {
            throw const FormatException(
                'Animation keyframe times must strictly increase.');
          }
          previous = time;
        }
      }
      final channels = _objects(animation['channels'], 4096);
      if (channels.isEmpty) {
        throw const FormatException('Animation must contain channels.');
      }
      final targets = <String>{};
      for (final channel in channels) {
        final sampler = samplers[_index(channel['sampler'], samplers.length)];
        final target = _object(channel['target']);
        final node = _index(target['node'], nodes.length);
        final path = target['path'];
        if (!['translation', 'rotation', 'scale'].contains(path) ||
            !targets.add('$node:$path') ||
            nodes[node].containsKey('matrix') ||
            (experimentalSkinnedScene && !visitedNodes.contains(node))) {
          throw const FormatException(
              'Unsupported or duplicate animation target.');
        }
        final initialScale = nodes[node]['scale'];
        if (initialScale != null &&
            _numbers(initialScale, 3).any((value) => value <= 0)) {
          throw const FormatException(
              'Animated nodes require strictly positive initial scale components.');
        }
        final output = accessor(_index(sampler['output'], accessors.length));
        final input = accessor(_index(sampler['input'], accessors.length));
        duration = math.max(duration, input.values.last);
        if (output.type != (path == 'rotation' ? 'VEC4' : 'VEC3')) {
          throw const FormatException(
              'Animation output type does not match its target.');
        }
        if (experimentalSkinnedScene &&
            path == 'scale' &&
            output.values.any((value) => value <= 0)) {
          throw const FormatException(
              'Animated scale components must be positive.');
        }
        if (experimentalSkinnedScene && path == 'rotation') {
          for (var offset = 0; offset < output.values.length; offset += 4) {
            var squaredLength = 0.0;
            for (var component = 0; component < 4; component++) {
              final value = output.values[offset + component];
              squaredLength += value * value;
            }
            if ((squaredLength - 1).abs() > 1e-4) {
              throw const FormatException(
                  'Animated rotations must be unit quaternions.');
            }
          }
        }
      }
      if (duration <= 0) {
        throw const FormatException('Animation must have positive duration.');
      }
      result.add(Model3dAnimation(
          index: i,
          name: _label(animation['name'], 'Animation ${i + 1}'),
          durationSeconds: duration));
    }
    if (result.isNotEmpty) diagnostics.add('bounds.static_scene_only');
    return result;
  }
}

final class _Accessor {
  const _Accessor(
      this.type, this.componentType, this.count, this.normalized, this.values);
  final String type;
  final int componentType;
  final int count;
  final bool normalized;
  final List<double> values;
}

List<double> _transform(Map<String, dynamic> node) {
  if (node['matrix'] != null) {
    if (node.containsKey('translation') ||
        node.containsKey('rotation') ||
        node.containsKey('scale')) {
      throw const FormatException(
          'Node matrix and TRS are mutually exclusive.');
    }
    final matrix = _numbers(node['matrix'], 16);
    if (matrix[3] != 0 ||
        matrix[7] != 0 ||
        matrix[11] != 0 ||
        matrix[15] != 1) {
      throw const FormatException('Node matrix must be affine.');
    }
    return matrix;
  }
  final t = node['translation'] == null
      ? [0.0, 0.0, 0.0]
      : _numbers(node['translation'], 3);
  final s =
      node['scale'] == null ? [1.0, 1.0, 1.0] : _numbers(node['scale'], 3);
  final q = node['rotation'] == null
      ? [0.0, 0.0, 0.0, 1.0]
      : _numbers(node['rotation'], 4);
  if ((q.fold<double>(0, (sum, v) => sum + v * v) - 1).abs() > 1e-4) {
    throw const FormatException('Node rotation must be a unit quaternion.');
  }
  final x = q[0], y = q[1], z = q[2], w = q[3];
  return [
    (1 - 2 * y * y - 2 * z * z) * s[0],
    (2 * x * y + 2 * z * w) * s[0],
    (2 * x * z - 2 * y * w) * s[0],
    0,
    (2 * x * y - 2 * z * w) * s[1],
    (1 - 2 * x * x - 2 * z * z) * s[1],
    (2 * y * z + 2 * x * w) * s[1],
    0,
    (2 * x * z + 2 * y * w) * s[2],
    (2 * y * z - 2 * x * w) * s[2],
    (1 - 2 * x * x - 2 * y * y) * s[2],
    0,
    t[0],
    t[1],
    t[2],
    1
  ];
}

List<double> _identity() => [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
List<double> _multiply(List<double> a, List<double> b) => [
      for (var column = 0; column < 4; column++)
        for (var row = 0; row < 4; row++)
          a[row] * b[column * 4] +
              a[4 + row] * b[column * 4 + 1] +
              a[8 + row] * b[column * 4 + 2] +
              a[12 + row] * b[column * 4 + 3]
    ];
Map<String, dynamic> _object(Object? value) {
  if (value is! Map) throw const FormatException('Expected a GLB object.');
  return Map<String, dynamic>.from(value);
}

List<dynamic> _list(Object? value) {
  if (value == null) return const [];
  if (value is! List || value.length > 16384) {
    throw const FormatException('Invalid or oversized GLB array.');
  }
  return value;
}

List<Map<String, dynamic>> _objects(Object? value, int max) {
  final list = _list(value);
  if (list.length > max) {
    throw const FormatException('GLB object budget exceeded.');
  }
  return list.map(_object).toList();
}

int _index(Object? value, int length) {
  final index = _nonnegativeInt(value);
  if (index >= length) {
    throw const FormatException('GLB index is out of range.');
  }
  return index;
}

int _positiveInt(Object? value) {
  final number = _nonnegativeInt(value);
  if (number == 0) {
    throw const FormatException('Expected a positive GLB integer.');
  }
  return number;
}

int _nonnegativeInt(Object? value) {
  if (value is! int || value < 0) {
    throw const FormatException('Expected a nonnegative GLB integer.');
  }
  return value;
}

double _number(Object? value) {
  if (value is! num || !value.isFinite) {
    throw const FormatException('Expected a finite GLB number.');
  }
  return value.toDouble();
}

List<double> _numbers(Object? value, int count) {
  final list = _list(value);
  if (list.length != count) {
    throw const FormatException('Invalid GLB numeric tuple.');
  }
  return list.map(_number).toList();
}

String _label(Object? value, String fallback) =>
    value is String && value.trim().isNotEmpty && value.length <= 256
        ? value.trim()
        : fallback;
