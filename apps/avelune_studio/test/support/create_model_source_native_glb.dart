import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as image;

Uint8List source(
  int color, {
  bool animated = true,
  int columns = 32,
  int rows = 16,
  double widthScale = 1,
  double heightScale = 1,
}) {
  final vertices = <double>[], normals = <double>[], uvs = <double>[];
  for (var y = 0; y < rows; y++) {
    for (var x = 0; x < columns; x++) {
      for (final p in [
        [x, y],
        [x + 1, y],
        [x, y + 1],
        [x + 1, y],
        [x + 1, y + 1],
        [x, y + 1],
      ]) {
        vertices.addAll([
          (p[0] / columns - .5) * widthScale,
          p[1] / rows * 2 * heightScale,
          0,
        ]);
        normals.addAll([0, 0, 1]);
        uvs.addAll([p[0] / columns, p[1] / rows]);
      }
    }
  }
  final binary = BytesBuilder(),
      views = <Map<String, Object?>>[],
      accessors = <Map<String, Object?>>[];
  int floats(
    List<double> values,
    String type,
    int count, {
    List<double>? min,
    List<double>? max,
  }) {
    final data = ByteData(values.length * 4);
    for (var i = 0; i < values.length; i++) {
      data.setFloat32(i * 4, values[i], Endian.little);
    }
    views.add({
      'buffer': 0,
      'byteOffset': binary.length,
      'byteLength': data.lengthInBytes,
    });
    binary.add(data.buffer.asUint8List());
    accessors.add({
      'bufferView': views.length - 1,
      'componentType': 5126,
      'count': count,
      'type': type,
      'min': ?min,
      'max': ?max,
    });
    return accessors.length - 1;
  }

  final position = floats(
    vertices,
    'VEC3',
    vertices.length ~/ 3,
    min: [-.5 * widthScale, 0, 0],
    max: [.5 * widthScale, 2 * heightScale, 0],
  );
  final normal = floats(normals, 'VEC3', normals.length ~/ 3),
      uv = floats(uvs, 'VEC2', uvs.length ~/ 2);
  int? time, translation;
  if (animated) {
    time = floats([0, 2], 'SCALAR', 2, min: [0], max: [2]);
    translation = floats([0, 0, 0, 0, .15, 0], 'VEC3', 2);
  }
  final bitmap = image.Image(width: 256, height: 256);
  for (var y = 0; y < 256; y++) {
    for (var x = 0; x < 256; x++) {
      bitmap.setPixelRgb(
        x,
        y,
        (color + x ~/ 16 * 7) % 256,
        (80 + y ~/ 16 * 5) % 256,
        90,
      );
    }
  }
  final png = image.encodePng(bitmap);
  views.add({
    'buffer': 0,
    'byteOffset': binary.length,
    'byteLength': png.length,
  });
  binary.add(png);
  final document = {
    'asset': {'version': '2.0'},
    'scene': 0,
    'scenes': [
      {
        'nodes': [0],
      },
    ],
    'nodes': [
      {'mesh': 0},
    ],
    'meshes': [
      {
        'primitives': [
          {
            'attributes': {
              'POSITION': position,
              'NORMAL': normal,
              'TEXCOORD_0': uv,
            },
            'material': 0,
          },
        ],
      },
    ],
    'materials': [
      {
        'doubleSided': true,
        'pbrMetallicRoughness': {
          'baseColorTexture': {'index': 0},
        },
      },
    ],
    'textures': [
      {'source': 0, 'sampler': 0},
    ],
    'samplers': [
      {'magFilter': 9728, 'minFilter': 9728},
    ],
    'images': [
      {'bufferView': views.length - 1, 'mimeType': 'image/png'},
    ],
    'buffers': [
      {'byteLength': binary.length},
    ],
    'bufferViews': views,
    'accessors': accessors,
    if (animated)
      'animations': [
        for (final name in ['Open', 'Close'])
          {
            'name': name,
            'samplers': [
              {'input': time, 'output': translation, 'interpolation': 'LINEAR'},
            ],
            'channels': [
              {
                'sampler': 0,
                'target': {'node': 0, 'path': 'translation'},
              },
            ],
          },
      ],
  };
  final json = utf8.encode(jsonEncode(document)), bin = binary.takeBytes();
  final jl = (json.length + 3) & ~3, bl = (bin.length + 3) & ~3;
  final bytes = Uint8List(28 + jl + bl), header = ByteData.sublistView(bytes);
  header.setUint32(0, 0x46546c67, Endian.little);
  header.setUint32(4, 2, Endian.little);
  header.setUint32(8, bytes.length, Endian.little);
  header.setUint32(12, jl, Endian.little);
  header.setUint32(16, 0x4e4f534a, Endian.little);
  bytes.fillRange(20, 20 + jl, 32);
  bytes.setRange(20, 20 + json.length, json);
  header.setUint32(20 + jl, bl, Endian.little);
  header.setUint32(24 + jl, 0x004e4942, Endian.little);
  bytes.setRange(28 + jl, 28 + jl + bin.length, bin);
  return bytes;
}
