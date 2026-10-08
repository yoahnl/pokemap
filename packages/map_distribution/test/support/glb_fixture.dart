import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

List<int> coloredGlb(
    {int width = 4,
    double color = .25,
    void Function(Map<String, dynamic>)? edit}) {
  final source = triangleGlb();
  final length = ByteData.sublistView(Uint8List.fromList(source))
      .getUint32(12, Endian.little);
  final json = jsonDecode(utf8.decode(source.sublist(20, 20 + length)))
      as Map<String, dynamic>;
  final binary = Uint8List(36 + 3 * width * 4);
  binary.setRange(0, 36, source.sublist(28 + length, 64 + length));
  final data = ByteData.sublistView(binary);
  for (var i = 0; i < 3 * width; i++) {
    data.setFloat32(36 + i * 4, i % width == 3 ? 1 : color, Endian.little);
  }
  json['buffers'][0]['byteLength'] = binary.length;
  json['bufferViews']
      .add({'buffer': 0, 'byteOffset': 36, 'byteLength': 3 * width * 4});
  json['accessors'].add({
    'bufferView': 1,
    'componentType': 5126,
    'count': 3,
    'type': width == 3 ? 'VEC3' : 'VEC4'
  });
  json['meshes'][0]['primitives'][0]['attributes']['COLOR_0'] = 1;
  json['meshes'][0]['primitives'][0]['material'] = 0;
  json['materials'] = [
    {'name': 'BW2 cutout', 'alphaMode': 'MASK', 'alphaCutoff': .5}
  ];
  edit?.call(json);
  return encodeGlb(json, binary);
}

List<int> triangleGlb({void Function(Map<String, dynamic>)? edit}) {
  final binary = ByteData(36);
  final values = [0.0, 0.0, 0.0, 2.0, 0.0, 0.0, 0.0, 3.0, 0.0];
  for (var i = 0; i < values.length; i++) {
    binary.setFloat32(i * 4, values[i], Endian.little);
  }
  final json = <String, dynamic>{
    'asset': {'version': '2.0'},
    'scene': 0,
    'scenes': [
      {
        'nodes': [0]
      }
    ],
    'nodes': [
      {
        'mesh': 0,
        'translation': [10, 2, -1],
        'scale': [2, 1, 1]
      }
    ],
    'meshes': [
      {
        'primitives': [
          {
            'attributes': {'POSITION': 0}
          }
        ]
      }
    ],
    'buffers': [
      {'byteLength': 36}
    ],
    'bufferViews': [
      {'buffer': 0, 'byteLength': 36}
    ],
    'accessors': [
      {
        'bufferView': 0,
        'componentType': 5126,
        'count': 3,
        'type': 'VEC3',
        'min': [0, 0, 0],
        'max': [2, 3, 0]
      }
    ],
  };
  final mutable = jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
  edit?.call(mutable);
  return encodeGlb(mutable, binary.buffer.asUint8List());
}

List<int> encodeGlb(Map<String, dynamic> json, List<int> binary) {
  final text = utf8.encode(jsonEncode(json));
  final jsonLength = (text.length + 3) ~/ 4 * 4;
  final binLength = (binary.length + 3) ~/ 4 * 4;
  final output = Uint8List(12 + 8 + jsonLength + 8 + binLength);
  final header = ByteData.sublistView(output);
  header.setUint32(0, 0x46546c67, Endian.little);
  header.setUint32(4, 2, Endian.little);
  header.setUint32(8, output.length, Endian.little);
  header.setUint32(12, jsonLength, Endian.little);
  header.setUint32(16, 0x4e4f534a, Endian.little);
  output.fillRange(20, 20 + jsonLength, 32);
  output.setRange(20, 20 + text.length, text);
  header.setUint32(20 + jsonLength, binLength, Endian.little);
  header.setUint32(24 + jsonLength, 0x004e4942, Endian.little);
  output.setRange(28 + jsonLength, 28 + jsonLength + binary.length, binary);
  return output;
}

List<int> animatedGlb({void Function(Map<String, dynamic>)? edit}) {
  final base = triangleGlb();
  final header = ByteData.sublistView(Uint8List.fromList(base));
  final length = header.getUint32(12, Endian.little);
  final json = jsonDecode(utf8.decode(base.sublist(20, 20 + length)))
      as Map<String, dynamic>;
  final binary = Uint8List(68);
  binary.setRange(0, 36, base.sublist(28 + length, 64 + length));
  final data = ByteData.sublistView(binary);
  data.setFloat32(40, 2, Endian.little);
  data.setFloat32(56, 1, Endian.little);
  json['buffers'][0]['byteLength'] = 68;
  json['bufferViews'].addAll([
    {'buffer': 0, 'byteOffset': 36, 'byteLength': 8},
    {'buffer': 0, 'byteOffset': 44, 'byteLength': 24},
  ]);
  json['accessors'].addAll([
    {'bufferView': 1, 'componentType': 5126, 'count': 2, 'type': 'SCALAR'},
    {'bufferView': 2, 'componentType': 5126, 'count': 2, 'type': 'VEC3'},
  ]);
  json['materials'] = [
    {'name': 'Stone'}
  ];
  json['meshes'][0]['primitives'][0]['material'] = 0;
  json['animations'] = [
    {
      'name': 'Wind',
      'samplers': [
        {'input': 1, 'output': 2}
      ],
      'channels': [
        {
          'sampler': 0,
          'target': {'node': 0, 'path': 'translation'}
        }
      ]
    }
  ];
  final mutable = jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
  edit?.call(mutable);
  return encodeGlb(mutable, binary);
}

List<int> texturedGlb({bool oversized = false}) {
  final source = triangleGlb();
  final length = ByteData.sublistView(Uint8List.fromList(source))
      .getUint32(12, Endian.little);
  final json = jsonDecode(utf8.decode(source.sublist(20, 20 + length)))
      as Map<String, dynamic>;
  final png = Uint8List.fromList(img.encodePng(img.Image(width: 1, height: 1)));
  if (oversized) ByteData.sublistView(png).setUint32(16, 8192);
  final binary = Uint8List(60 + png.length);
  binary.setRange(0, 36, source.sublist(28 + length, 64 + length));
  binary.setRange(60, binary.length, png);
  json['buffers'][0]['byteLength'] = binary.length;
  json['bufferViews'].addAll([
    {'buffer': 0, 'byteOffset': 36, 'byteLength': 24},
    {'buffer': 0, 'byteOffset': 60, 'byteLength': png.length},
  ]);
  json['accessors'].add(
      {'bufferView': 1, 'componentType': 5126, 'count': 3, 'type': 'VEC2'});
  json['meshes'][0]['primitives'][0]['attributes']['TEXCOORD_0'] = 1;
  json['meshes'][0]['primitives'][0]['material'] = 0;
  json['images'] = [
    {'bufferView': 2, 'mimeType': 'image/png'}
  ];
  json['textures'] = [
    {'source': 0}
  ];
  json['materials'] = [
    {
      'pbrMetallicRoughness': {
        'baseColorTexture': {'index': 0}
      }
    }
  ];
  return encodeGlb(json, binary);
}
