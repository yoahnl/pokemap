import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';
import 'package:flame_3d/model.dart';

import 'animated_render_model.dart';
import 'spatial_pixel_material.dart';

Future<int> spatialImageRgbaBytes(
  Uint8List bytes, {
  required int maximumBytes,
}) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  ui.ImageDescriptor? descriptor;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    return runtimeImageRgbaByteLength(
      descriptor.width,
      descriptor.height,
      maximumBytes: maximumBytes,
    );
  } finally {
    descriptor?.dispose();
    buffer.dispose();
  }
}

Future<({int resident, int transient, int retainedStaticResident})>
spatialModelResourceEstimate(
  Uint8List bytes,
  RuntimeResourceReservation reservation, {
  Object? Function(String source) decodeJson = jsonDecode,
}) async {
  if (bytes.length < 28) throw const FormatException('Invalid GLB header.');
  final header = ByteData.sublistView(bytes);
  final jsonLength = header.getUint32(12, Endian.little);
  if (jsonLength > bytes.length - 28) {
    throw const FormatException('Invalid GLB JSON length.');
  }
  final source = Uint8List.sublistView(bytes, 20, 20 + jsonLength);
  final metadataBytes = _modelJsonObjectBudget(source);
  reservation.resize(
    residentBytes: _product(metadataBytes, 2),
    transientBytes: _sum([
      _product(bytes.length, 4),
      _product(metadataBytes, 4),
    ]),
  );
  final json = decodeJson(utf8.decode(source)) as Map<String, dynamic>;
  var geometryBytes = 0;
  final accessors = (json['accessors'] as List?) ?? const [];
  for (final raw in accessors) {
    final value = raw as Map;
    final count = value['count'] as int;
    if (count < 0) throw const FormatException('Invalid GLB accessor count.');
    final components = switch (value['type']) {
      'SCALAR' => 1,
      'VEC2' => 2,
      'VEC3' => 3,
      'VEC4' || 'MAT2' => 4,
      'MAT3' => 9,
      'MAT4' => 16,
      _ => throw const FormatException('Unsupported GLB accessor type.'),
    };
    geometryBytes = _sum([
      geometryBytes,
      _product(_product(count, components), 32),
    ]);
  }
  final nodes = (json['nodes'] as List?) ?? const [];
  geometryBytes = _sum([geometryBytes, _product(nodes.length, 1024)]);
  final instancesByMesh = <int, int>{};
  for (final node in nodes) {
    final mesh = node['mesh'] as int?;
    if (mesh != null)
      instancesByMesh.update(mesh, (value) => value + 1, ifAbsent: () => 1);
  }
  for (final (meshIndex, mesh)
      in ((json['meshes'] as List?) ?? const []).indexed) {
    for (final primitive in (mesh['primitives'] as List?) ?? const []) {
      final index =
          primitive['indices'] as int? ??
          (primitive['attributes'] as Map)['POSITION'] as int?;
      if (index != null)
        geometryBytes = _sum([
          geometryBytes,
          _product(
            _product(accessors[index]['count'] as int, 128),
            instancesByMesh[meshIndex] ?? 1,
          ),
        ]);
    }
  }
  var pixels = 0;
  reservation.resize(
    residentBytes: _sum([
      geometryBytes,
      _product(bytes.length, 2),
      _product(metadataBytes, 2),
    ]),
    transientBytes: _sum([
      _product(bytes.length, 4),
      geometryBytes,
      _product(metadataBytes, 4),
    ]),
  );
  final binaryOffset = 28 + jsonLength;
  final views = (json['bufferViews'] as List?) ?? const [];
  for (final raw in (json['images'] as List?) ?? const []) {
    final image = raw as Map;
    if (image['uri'] != null || image['bufferView'] is! int) {
      throw const FormatException('Runtime GLB images must be embedded.');
    }
    final view = views[image['bufferView'] as int] as Map;
    final offset = view['byteOffset'] as int? ?? 0;
    final length = view['byteLength'] as int;
    if (offset < 0 ||
        offset > bytes.length - binaryOffset ||
        length < 0 ||
        length > bytes.length - binaryOffset - offset) {
      throw const FormatException('Invalid embedded GLB image bounds.');
    }
    final start = binaryOffset + offset;
    pixels = _sum([
      pixels,
      await spatialImageRgbaBytes(
        Uint8List.sublistView(bytes, start, start + length),
        maximumBytes: reservation.profile.maximumResidentBytes ~/ 2,
      ),
    ]);
    reservation.ensureCurrent();
    reservation.resize(
      residentBytes: _sum([
        geometryBytes,
        _product(bytes.length, 2),
        _product(pixels, 2),
        _product(metadataBytes, 2),
      ]),
      transientBytes: _sum([
        _product(bytes.length, 4),
        geometryBytes,
        _product(pixels, 2),
        _product(metadataBytes, 4),
      ]),
    );
  }
  return (
    retainedStaticResident: _sum([geometryBytes, _product(pixels, 2)]),
    resident: _sum([
      geometryBytes,
      _product(bytes.length, 2),
      _product(pixels, 2),
      _product(metadataBytes, 2),
    ]),
    transient: _sum([
      _product(bytes.length, 4),
      geometryBytes,
      _product(pixels, 2),
      _product(metadataBytes, 4),
    ]),
  );
}

int spatialRetainedModelResourceBytes(
  Model model, {
  required int staticResidentBytes,
}) {
  final values = <int>[staticResidentBytes, 1024];
  final materials = <Object>{};
  int nameBytes(String? name) => _sum([128, _product(name?.length ?? 0, 8)]);
  for (final node in model.nodes.values) {
    values.addAll([
      512,
      nameBytes(node.name),
      _product(node.joints.length, 1024),
    ]);
    final surfaces = node.mesh?.surfaces;
    if (surfaces == null) continue;
    for (final surface in surfaces) {
      values.add(256);
      final material = surface.material;
      if (materials.add(material)) {
        values.add(16384);
        if (material is SpatialPixelMaterial)
          values.add(nameBytes(material.sourceMaterialName));
      }
    }
  }
  for (final clip in model.animations) {
    values.addAll([1024, nameBytes(clip.name)]);
    for (final node in clip.nodes.values) {
      values.add(512);
      for (final channel in node.channels) {
        values.addAll([512, _product(channel.animation.values.length, 512)]);
      }
    }
  }
  if (model is AnimatedRenderModel) {
    values.addAll([
      _product(model.textures.length, 256),
      _product(model.textureWrapModes.length, 128),
    ]);
    for (final bindings in model.materialBindings.values) {
      values.addAll([256, _product(bindings.length, 32)]);
    }
    for (final clip in model.materialAnimations.clips) {
      values.addAll([1024, nameBytes(clip.name)]);
      for (final track in clip.tracks) {
        values.addAll([
          1024,
          nameBytes(track.interpolation),
          _product(track.times.length, 64),
          _product(track.textureIndices?.length ?? 0, 32),
        ]);
        for (final transform in track.transforms) {
          values.add(_sum([128, _product(transform.length, 32)]));
        }
      }
    }
  }
  return _sum(values);
}

const _maximumResourceBytes = 0x1fffffffffffff;

int _product(int value, int factor) {
  if (value < 0 ||
      factor < 0 ||
      (factor != 0 && value > _maximumResourceBytes ~/ factor)) {
    throw const RuntimeResourceAdmissionException('model_resource_bytes');
  }
  return value * factor;
}

int _sum(List<int> values) {
  var total = 0;
  for (final value in values) {
    if (value < 0 || value > _maximumResourceBytes - total) {
      throw const RuntimeResourceAdmissionException('model_resource_bytes');
    }
    total += value;
  }
  return total;
}

int _modelJsonObjectBudget(Uint8List source) {
  var depth = 0, tokens = 0;
  var quoted = false, escaped = false, atom = false;
  for (final c in source) {
    if (quoted) {
      if (escaped) {
        escaped = false;
      } else if (c == 92) {
        escaped = true;
      } else if (c == 34) {
        quoted = false;
      }
      continue;
    }
    if (c == 34) {
      quoted = true;
      atom = false;
      tokens++;
    } else if (c == 123 || c == 91) {
      depth++;
      tokens++;
      atom = false;
    } else if (c == 125 || c == 93) {
      depth--;
      atom = false;
    } else if (c == 44 || c == 58 || c <= 32) {
      atom = false;
    } else if (!atom) {
      tokens++;
      atom = true;
    }
    if (depth < 0 || depth > 64) {
      throw const FormatException('GLB JSON depth exceeds its runtime limit.');
    }
    if (tokens > 100000) {
      throw const FormatException(
        'GLB JSON values exceed their runtime limit.',
      );
    }
  }
  if (quoted || escaped || depth != 0 || tokens == 0) {
    throw const FormatException('Incomplete GLB JSON document.');
  }
  return tokens * 128;
}
