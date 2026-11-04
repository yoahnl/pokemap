import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:test/test.dart';

import '../../../tool/gen5_workshop_texture_baker.dart';

Uint8List _texture() {
  final value = image.Image(width: 2, height: 2, numChannels: 4);
  value.setPixelRgba(0, 0, 10, 0, 0, 255);
  value.setPixelRgba(1, 0, 20, 0, 0, 128);
  value.setPixelRgba(0, 1, 30, 0, 0, 64);
  value.setPixelRgba(1, 1, 40, 0, 0, 0);
  return Uint8List.fromList(image.encodePng(value));
}

List<List<int>> _red(Uint8List png) {
  final decoded = image.decodePng(png)!;
  return [
    for (var y = 0; y < decoded.height; y++)
      [for (var x = 0; x < decoded.width; x++) decoded.getPixel(x, y).r.toInt()],
  ];
}

void main() {
  test('bakes BW2 repeated and mirrored textures independently for parent and child', () {
    final original = _texture();
    final source = <String, dynamic>{
      'textures': [
        {'name': 'tex', 'repeat': 'st', 'flip': 'st'},
      ],
      'emitters': [
        {
          'textureRepeatShiftS': 1,
          'textureRepeatShiftT': 1,
          'flipTextureS': false,
          'flipTextureT': false,
          'childResource': {
            'textureRepeatShiftS': 0,
            'textureRepeatShiftT': 1,
            'flipTextureS': false,
            'flipTextureT': false,
          },
        },
      ],
    };
    final definition = <String, dynamic>{
      'schemaVersion': 10,
      'emitters': [
        {
          'appearance': {
            'initialTexture': 'tex',
            'textureAnimation': {'textures': ['tex']},
          },
          'child': {'texture': 'tex'},
        },
      ],
    };
    final result = Gen5WorkshopTextureBaker.bake(
      source: source,
      sourceEmitterIndices: [0],
      definition: definition,
      textures: {'tex': original},
    );
    final emitter = (result.definition['emitters'] as List).single as Map;
    final appearance = emitter['appearance'] as Map;
    final parent = appearance['initialTexture'] as String;
    final child = (emitter['child'] as Map)['texture'] as String;
    expect(parent, isNot('tex'));
    expect(child, isNot(parent));
    expect(((appearance['textureAnimation'] as Map)['textures'] as List).single, parent);
    expect(_red(result.textures[parent]!), [
      [10, 20, 20, 10],
      [30, 40, 40, 30],
      [30, 40, 40, 30],
      [10, 20, 20, 10],
    ]);
    expect(_red(result.textures[child]!), [
      [10, 20],
      [30, 40],
      [30, 40],
      [10, 20],
    ]);
    final parentImage = image.decodePng(result.textures[parent]!)!;
    expect(parentImage.getPixel(2, 0).a.toInt(), 128);
    expect(((definition['emitters'] as List).single as Map)['child'], {'texture': 'tex'});
  });

  test('bakes clamped coordinates and negative texture direction', () {
    final source = <String, dynamic>{
      'textures': [
        {'name': 'tex', 'repeat': 'none', 'flip': 'none'},
      ],
      'emitters': [
        {
          'textureRepeatShiftS': 1,
          'textureRepeatShiftT': 1,
          'flipTextureS': false,
          'flipTextureT': false,
          'childResource': {
            'textureRepeatShiftS': 0,
            'textureRepeatShiftT': 0,
            'flipTextureS': false,
            'flipTextureT': true,
          },
        },
      ],
    };
    final result = Gen5WorkshopTextureBaker.bake(
      source: source,
      sourceEmitterIndices: [0],
      definition: {
        'emitters': [
          {
            'appearance': {'initialTexture': 'tex', 'textureAnimation': null},
            'child': {'texture': 'tex'},
          },
        ],
      },
      textures: {'tex': _texture()},
    );
    final emitter = (result.definition['emitters'] as List).single as Map;
    final parent = (emitter['appearance'] as Map)['initialTexture'] as String;
    final child = (emitter['child'] as Map)['texture'] as String;
    expect(_red(result.textures[parent]!), [
      [10, 20, 20, 20],
      [30, 40, 40, 40],
      [30, 40, 40, 40],
      [30, 40, 40, 40],
    ]);
    expect(_red(result.textures[child]!), [
      [10, 20],
      [10, 20],
    ]);
  });
}
