import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

Uint8List billboardGlb({
  required bool Function(int x, int y) opaque,
  String alphaMode = 'MASK',
  int size = 8,
}) {
  final image = img.Image(width: size, height: size, numChannels: 4);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      image.setPixelRgba(x, y, 40, 160, 60, opaque(x, y) ? 255 : 0);
    }
  }
  final png = img.encodePng(image);
  const positions = <double>[-1, 0, 0, 1, 0, 0, 1, 2, 0, -1, 2, 0];
  const normals = <double>[0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1];
  const uvs = <double>[0, 1, 1, 1, 1, 0, 0, 0];
  const indices = [0, 1, 2, 0, 2, 3];
  final geometry = ByteData(48 + 48 + 32 + 12);
  for (var i = 0; i < 12; i++) {
    geometry.setFloat32(i * 4, positions[i], Endian.little);
    geometry.setFloat32(48 + i * 4, normals[i], Endian.little);
  }
  for (var i = 0; i < 8; i++) {
    geometry.setFloat32(96 + i * 4, uvs[i], Endian.little);
  }
  for (var i = 0; i < 6; i++) {
    geometry.setUint16(128 + i * 2, indices[i], Endian.little);
  }
  final binary = Uint8List(140 + png.length)
    ..setRange(0, 140, geometry.buffer.asUint8List())
    ..setRange(140, 140 + png.length, png);
  final json = {
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
            'attributes': {'POSITION': 0, 'NORMAL': 1, 'TEXCOORD_0': 2},
            'indices': 3,
            'material': 0,
          },
        ],
      },
    ],
    'materials': [
      {
        'alphaMode': alphaMode,
        if (alphaMode == 'MASK') 'alphaCutoff': .5,
        'pbrMetallicRoughness': {
          'baseColorTexture': {'index': 0},
        },
      },
    ],
    'samplers': [
      {'magFilter': 9728, 'minFilter': 9728},
    ],
    'textures': [
      {'sampler': 0, 'source': 0},
    ],
    'images': [
      {'bufferView': 4, 'mimeType': 'image/png'},
    ],
    'buffers': [
      {'byteLength': binary.length},
    ],
    'bufferViews': [
      {'buffer': 0, 'byteOffset': 0, 'byteLength': 48},
      {'buffer': 0, 'byteOffset': 48, 'byteLength': 48},
      {'buffer': 0, 'byteOffset': 96, 'byteLength': 32},
      {'buffer': 0, 'byteOffset': 128, 'byteLength': 12},
      {'buffer': 0, 'byteOffset': 140, 'byteLength': png.length},
    ],
    'accessors': [
      {
        'bufferView': 0,
        'componentType': 5126,
        'count': 4,
        'type': 'VEC3',
        'min': [-1, 0, 0],
        'max': [1, 2, 0],
      },
      {'bufferView': 1, 'componentType': 5126, 'count': 4, 'type': 'VEC3'},
      {'bufferView': 2, 'componentType': 5126, 'count': 4, 'type': 'VEC2'},
      {'bufferView': 3, 'componentType': 5123, 'count': 6, 'type': 'SCALAR'},
    ],
  };
  final text = utf8.encode(jsonEncode(json));
  final jsonLength = (text.length + 3) ~/ 4 * 4;
  final binaryLength = (binary.length + 3) ~/ 4 * 4;
  final output = Uint8List(28 + jsonLength + binaryLength);
  final header = ByteData.sublistView(output)
    ..setUint32(0, 0x46546c67, Endian.little)
    ..setUint32(4, 2, Endian.little)
    ..setUint32(8, output.length, Endian.little)
    ..setUint32(12, jsonLength, Endian.little)
    ..setUint32(16, 0x4e4f534a, Endian.little);
  output.fillRange(20, 20 + jsonLength, 32);
  output.setRange(20, 20 + text.length, text);
  header
    ..setUint32(20 + jsonLength, binaryLength, Endian.little)
    ..setUint32(24 + jsonLength, 0x004e4942, Endian.little);
  output.setRange(28 + jsonLength, 28 + jsonLength + binary.length, binary);
  return output;
}

bool rightQuarterOpaque(int x, int y) => x >= 6;

bool everyTexelOpaque(int x, int y) => true;
