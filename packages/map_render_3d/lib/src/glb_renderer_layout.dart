import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_core/map_core.dart';

import 'spatial_pixel_material.dart';

final class GlbRendererLayout {
  GlbRendererLayout(Uint8List bytes) {
    final length = ByteData.sublistView(bytes).getUint32(12, Endian.little);
    json =
        jsonDecode(utf8.decode(bytes.sublist(20, 20 + length)))
            as Map<String, dynamic>;
    binary = ByteData.sublistView(bytes, 28 + length);
    materials = [
      for (final (index, raw) in ((json['materials'] as List?) ?? []).indexed)
        _material(index, raw as Map<String, dynamic>),
    ];
    for (final raw in (json['samplers'] as List?) ?? []) {
      for (final axis in ['wrapS', 'wrapT']) {
        if (![10497, 33648, 33071].contains(raw[axis] ?? 10497)) {
          throw const FormatException('Unsupported GLB texture wrap mode.');
        }
      }
    }
  }

  late final Map<String, dynamic> json;
  late final ByteData binary;
  late final List<Model3dMaterial> materials;

  Model3dMaterial _material(int index, Map<String, dynamic> raw) {
    if ((raw.containsKey('doubleSided') && raw['doubleSided'] is! bool) ||
        ((raw['alphaMode'] ?? 'OPAQUE') != 'MASK' &&
            raw['alphaCutoff'] != null)) {
      throw const FormatException(
        'Invalid doubleSided or opaque cutoff material.',
      );
    }
    return Model3dMaterial(
      index: index,
      name: raw['name'] as String? ?? 'Material ${index + 1}',
      alphaMode: switch (raw['alphaMode']) {
        null || 'OPAQUE' => Model3dAlphaMode.opaque,
        'MASK' => Model3dAlphaMode.mask,
        'BLEND' => Model3dAlphaMode.blend,
        _ => throw const FormatException(
          'Only OPAQUE, MASK and BLEND GLB materials are supported.',
        ),
      },
      alphaCutoff: (raw['alphaCutoff'] as num?)?.toDouble(),
      doubleSided: raw['doubleSided'] as bool? ?? false,
    );
  }

  void apply(int nodeIndex, Mesh mesh, {bool mirroredTransform = false}) {
    final primitives =
        json['meshes'][json['nodes'][nodeIndex]['mesh']]['primitives'] as List;
    for (final (index, surface) in mesh.surfaces.toList().indexed) {
      final primitive = primitives[index] as Map<String, dynamic>;
      final materialIndex = primitive['material'] as int?;
      final source = surface.material;
      if (source is SpatialMaterial) {
        final profile = materialIndex == null ? null : materials[materialIndex];
        final raw = materialIndex == null
            ? null
            : json['materials'][materialIndex];
        final textureIndex =
            raw?['pbrMetallicRoughness']?['baseColorTexture']?['index'] as int?;
        final colorFactor =
            raw?['pbrMetallicRoughness']?['baseColorFactor'] as List?;
        final samplerIndex = textureIndex == null
            ? null
            : json['textures'][textureIndex]['sampler'] as int?;
        final sampler = samplerIndex == null
            ? null
            : json['samplers'][samplerIndex];
        surface.material =
            SpatialPixelMaterial(
                source.albedoTexture,
                alphaMode: profile?.alphaMode ?? Model3dAlphaMode.opaque,
                alphaCutoff: profile?.alphaCutoff ?? .5,
                wrapS: sampler?['wrapS'] as int? ?? 10497,
                wrapT: sampler?['wrapT'] as int? ?? 10497,
              )
              ..albedoColor = colorFactor == null
                  ? source.albedoColor
                  : Color.from(
                      red: (colorFactor[0] as num).toDouble(),
                      green: (colorFactor[1] as num).toDouble(),
                      blue: (colorFactor[2] as num).toDouble(),
                      alpha: (colorFactor[3] as num).toDouble(),
                    )
              ..cullMode = profile?.doubleSided == true
                  ? CullMode.none
                  : mirroredTransform
                  ? CullMode.frontFace
                  : CullMode.backFace;
      }
      final attributes = primitive['attributes'] as Map<String, dynamic>;
      if (attributes.keys.any(
        (key) => key.startsWith('COLOR_') && key != 'COLOR_0',
      )) {
        throw const FormatException('Only COLOR_0 is supported.');
      }
      final colorIndex = attributes['COLOR_0'] as int?;
      if (colorIndex == null) continue;
      final colorAccessor = json['accessors'][colorIndex];
      if (colorAccessor['count'] != surface.vertexCount) {
        throw const FormatException('COLOR_0 must match the vertex count.');
      }
      final width = switch (colorAccessor['type']) {
        'VEC3' => 3,
        'VEC4' => 4,
        _ => throw const FormatException('COLOR_0 must contain RGB or RGBA.'),
      };
      final colors = _floats(colorIndex, width);
      if (colors.any((value) => value < 0 || value > 1) ||
          colors.length ~/ width < surface.vertexCount) {
        throw const FormatException(
          'Invalid COLOR_0 normalized values or count.',
        );
      }
      final uvIndex = attributes['TEXCOORD_0'] as int?;
      final normalIndex = attributes['NORMAL'] as int?;
      final uvs = uvIndex == null ? null : _floats(uvIndex, 2);
      final normals = normalIndex == null ? null : _floats(normalIndex, 3);
      mesh.updateSurface(
        index,
        SpatialModelSurface(
          vertices: [
            for (var i = 0; i < surface.vertexCount; i++)
              Vertex(
                position: Vector3.array(surface.positions, i * 3),
                texCoord: uvs == null
                    ? Vector2.zero()
                    : Vector2.array(uvs, i * 2),
                normal: normals == null ? null : Vector3.array(normals, i * 3),
                color: Color.from(
                  alpha: width == 4 ? colors[i * width + 3] : 1,
                  red: colors[i * width],
                  green: colors[i * width + 1],
                  blue: colors[i * width + 2],
                ),
              ),
          ],
          indices: surface.indices.toList(),
          material: surface.material,
        ),
      );
    }
  }

  List<double> _floats(int index, int width) {
    final accessor = json['accessors'][index];
    if (accessor['componentType'] != 5126 ||
        (accessor['normalized'] ?? false) != false) {
      throw const FormatException(
        'Vertex values must be nonnormalized float accessors.',
      );
    }
    final view = json['bufferViews'][accessor['bufferView']];
    final offset =
        (view['byteOffset'] as int? ?? 0) +
        (accessor['byteOffset'] as int? ?? 0);
    final values = List<double>.generate(
      (accessor['count'] as int) * width,
      (i) => binary.getFloat32(offset + i * 4, Endian.little),
    );
    if (values.any((value) => !value.isFinite))
      throw const FormatException('Nonfinite vertex values.');
    return values;
  }
}

final class SpatialModelSurface extends Surface {
  SpatialModelSurface({
    required List<Vertex> vertices,
    required super.indices,
    required super.material,
  }) : vertexColors = List.unmodifiable(vertices.map((vertex) => vertex.color)),
       super(vertices: vertices);

  final List<Color> vertexColors;
}

Uint8List normalizeGlbAccessors(Uint8List bytes) {
  final header = ByteData.sublistView(bytes);
  final jsonLength = header.getUint32(12, Endian.little);
  final json =
      jsonDecode(utf8.decode(bytes.sublist(20, 20 + jsonLength)))
          as Map<String, dynamic>;
  final binOffset = 28 + jsonLength;
  final binary = BytesBuilder()..add(bytes.sublist(binOffset));
  final views = json['bufferViews'] as List;
  for (final raw in (json['materials'] as List? ?? const [])) {
    final material = raw as Map<String, dynamic>;
    material.putIfAbsent('pbrMetallicRoughness', () => <String, dynamic>{});
  }
  final accessors = json['accessors'] as List;
  for (final raw in accessors) {
    final accessor = raw as Map<String, dynamic>;
    final view = views[accessor['bufferView'] as int] as Map<String, dynamic>;
    final componentSize = switch (accessor['componentType']) {
      5120 || 5121 => 1,
      5122 || 5123 => 2,
      5125 || 5126 => 4,
      _ => throw const FormatException('Unsupported accessor component.'),
    };
    final components = switch (accessor['type']) {
      'SCALAR' => 1,
      'VEC2' => 2,
      'VEC3' => 3,
      'VEC4' || 'MAT2' => 4,
      'MAT3' => 9,
      'MAT4' => 16,
      _ => throw const FormatException('Unsupported accessor type.'),
    };
    final size = componentSize * components;
    final count = accessor['count'] as int;
    final stride = (view['byteStride'] as int?) ?? size;
    final start =
        binOffset +
        ((view['byteOffset'] as int?) ?? 0) +
        ((accessor['byteOffset'] as int?) ?? 0);
    final viewEnd =
        binOffset +
        ((view['byteOffset'] as int?) ?? 0) +
        (view['byteLength'] as int);
    if (count < 1 ||
        stride < size ||
        start < binOffset ||
        start + (count - 1) * stride + size > viewEnd ||
        viewEnd > bytes.length) {
      throw const FormatException('Accessor data exceeds its buffer view.');
    }
    final alignedOffset = (binary.length + 3) ~/ 4 * 4;
    if (alignedOffset > binary.length) {
      binary.add(Uint8List(alignedOffset - binary.length));
    }
    for (var i = 0; i < count; i++) {
      binary.add(
        Uint8List.sublistView(
          bytes,
          start + i * stride,
          start + i * stride + size,
        ),
      );
    }
    accessor['bufferView'] = views.length;
    accessor.remove('byteOffset');
    views.add({
      'buffer': 0,
      'byteOffset': alignedOffset,
      'byteLength': count * size,
    });
  }
  (json['buffers'] as List).first['byteLength'] = binary.length;
  final encoded = utf8.encode(jsonEncode(json));
  final paddedJson = (encoded.length + 3) ~/ 4 * 4;
  final paddedBinary = (binary.length + 3) ~/ 4 * 4;
  final result = Uint8List(28 + paddedJson + paddedBinary);
  final data = ByteData.sublistView(result);
  data.setUint32(0, 0x46546c67, Endian.little);
  data.setUint32(4, 2, Endian.little);
  data.setUint32(8, result.length, Endian.little);
  data.setUint32(12, paddedJson, Endian.little);
  data.setUint32(16, 0x4e4f534a, Endian.little);
  result.fillRange(20, 20 + paddedJson, 32);
  result.setRange(20, 20 + encoded.length, encoded);
  data.setUint32(20 + paddedJson, paddedBinary, Endian.little);
  data.setUint32(24 + paddedJson, 0x004e4942, Endian.little);
  result.setRange(
    28 + paddedJson,
    28 + paddedJson + binary.length,
    binary.takeBytes(),
  );
  return result;
}
