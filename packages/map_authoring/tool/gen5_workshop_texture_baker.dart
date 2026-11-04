import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as image;

abstract final class Gen5WorkshopTextureBaker {
  static ({Map<String, dynamic> definition, Map<String, Uint8List> textures}) bake({
    required Map<String, dynamic> source,
    required List<int> sourceEmitterIndices,
    required Map<String, dynamic> definition,
    required Map<String, Uint8List> textures,
  }) {
    final copy = jsonDecode(jsonEncode(definition)) as Map<String, dynamic>;
    final emitters = (copy['emitters'] as List).cast<Map>();
    final originals = (source['emitters'] as List).cast<Map>();
    if (emitters.length != sourceEmitterIndices.length ||
        sourceEmitterIndices.any((index) => index < 0 || index >= originals.length)) {
      throw const FormatException('Invalid BW2 emitter mapping');
    }
    final metadata = {
      for (final entry in (source['textures'] as List).cast<Map>())
        entry['name'] as String: entry,
    };
    final baked = Map<String, Uint8List>.of(textures);

    String mapTexture(String name, Map settings) {
      final sx = settings['textureRepeatShiftS'] as int;
      final sy = settings['textureRepeatShiftT'] as int;
      final flipS = settings['flipTextureS'] as bool;
      final flipT = settings['flipTextureT'] as bool;
      if (sx < 0 || sx > 3 || sy < 0 || sy > 3) {
        throw const FormatException('Invalid BW2 texture repeat');
      }
      final original = textures[name];
      final texture = metadata[name];
      if (original == null || texture == null) {
        throw const FormatException('Missing BW2 texture');
      }
      final repeat = texture['repeat'];
      final flip = texture['flip'];
      if (!{'none', 's', 't', 'st'}.contains(repeat) ||
          !{'none', 's', 't', 'st'}.contains(flip)) {
        throw const FormatException('Invalid BW2 texture wrapping');
      }
      if (sx == 0 && sy == 0 && !flipS && !flipT) return name;
      final variant = '${name}__bw2_${sx}_${sy}_${flipS ? 1 : 0}_'
          '${flipT ? 1 : 0}_${repeat}_$flip';
      if (textures.containsKey(variant)) {
        throw const FormatException('BW2 texture name collision');
      }
      if (!baked.containsKey(variant)) {
        final input = image.decodePng(original);
        if (input == null) throw const FormatException('Invalid BW2 texture PNG');
        final width = input.width << sx;
        final height = input.height << sy;
        if (width > 2048 || height > 2048 || width * height > 4000000) {
          throw const FormatException('BW2 baked texture exceeds limits');
        }
        final output = image.Image(width: width, height: height, numChannels: 4);
        int coordinate(int value, int size, bool reverse, bool wrap, bool mirror) {
          final position = reverse ? -value - 1 : value;
          if (!wrap) return position.clamp(0, size - 1);
          final offset = position % size;
          final tile = (position - offset) ~/ size;
          return mirror && tile.isOdd ? size - offset - 1 : offset;
        }
        for (var y = 0; y < height; y++) {
          final sourceY = coordinate(y, input.height, flipT,
              (repeat as String).contains('t'), (flip as String).contains('t'));
          for (var x = 0; x < width; x++) {
            final sourceX = coordinate(x, input.width, flipS,
                repeat.contains('s'), flip.contains('s'));
            output.setPixel(x, y, input.getPixel(sourceX, sourceY));
          }
        }
        baked[variant] = Uint8List.fromList(image.encodePng(output));
      }
      return variant;
    }

    for (var i = 0; i < emitters.length; i++) {
      final original = originals[sourceEmitterIndices[i]];
      final appearance = emitters[i]['appearance'] as Map;
      appearance['initialTexture'] =
          mapTexture(appearance['initialTexture'] as String, original);
      final animation = appearance['textureAnimation'];
      if (animation is Map) {
        animation['textures'] = [
          for (final name in animation['textures'] as List)
            mapTexture(name as String, original),
        ];
      }
      final child = emitters[i]['child'];
      if (child is Map) {
        final childSource = original['childResource'];
        if (childSource is! Map) {
          throw const FormatException('Missing BW2 child emitter');
        }
        child['texture'] = mapTexture(child['texture'] as String, childSource);
      }
    }
    final used = <String>{};
    for (final emitter in emitters) {
      final appearance = emitter['appearance'] as Map;
      used.add(appearance['initialTexture'] as String);
      final animation = appearance['textureAnimation'];
      if (animation is Map) used.addAll((animation['textures'] as List).cast<String>());
      final child = emitter['child'];
      if (child is Map) used.add(child['texture'] as String);
    }
    return (
      definition: copy,
      textures: {for (final name in used) name: baked[name]!},
    );
  }
}
