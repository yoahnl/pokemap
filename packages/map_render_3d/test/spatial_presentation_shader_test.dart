import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cutout modes reject before lighting with their original alpha', () {
    final fragment = File('shaders/pixel_material.frag').readAsStringSync();
    final main = fragment.substring(fragment.indexOf('void main()'));
    final lighting = main.indexOf('if (atmosphere.options.z < 0.5');
    final initialized = main.indexOf('outColor = color *');
    final rejections = [
      'if (material.alphaMode == 0.0 && color.a < material.alphaCutoff) discard;',
      'if (material.alphaMode == 2.0 && outColor.a < material.alphaCutoff) discard;',
    ];
    expect(RegExp(r'\bdiscard\s*;').allMatches(main), hasLength(2));
    for (final rejection in rejections) {
      expect(main.indexOf(rejection), greaterThan(initialized));
      expect(main.indexOf(rejection), lessThan(lighting));
    }
  });

  test(
    'cutouts keep derivatives and implicit albedo sampling before discard',
    () {
      final fragment = File('shaders/pixel_material.frag').readAsStringSync();
      final main = fragment.substring(fragment.indexOf('void main()'));
      final rejection = main.indexOf('discard;');
      for (final input in [
        'dFdx(fragPosition)',
        'dFdy(fragPosition)',
        'vec4 color = samplePixelColor();',
      ]) {
        expect(main.indexOf(input), greaterThanOrEqualTo(0));
        expect(main.indexOf(input), lessThan(rejection));
      }
      expect(
        RegExp(r'\b(?:dFdx|dFdy|samplePixelColor)\s*\(')
            .allMatches(main.substring(rejection)),
        isEmpty,
      );
      expect(RegExp(r'\btexture\s*\(').allMatches(fragment), isEmpty);
      final shadowSamples = RegExp(
        r'\btextureLod\((pointShadowTexture|shadowTexture), (.*), 0\.0\)',
      ).allMatches(fragment).toList();
      expect(shadowSamples, hasLength(3));
      expect(shadowSamples.map((sample) => sample.group(1)), [
        'pointShadowTexture',
        'shadowTexture',
        'shadowTexture',
      ]);
      expect(shadowSamples.map((sample) => sample.group(2)), [
        'sampleUv',
        '(subPixel + 0.5) / resolution',
        '(pixel + 0.5) / resolution',
      ]);
    },
  );

  test(
    'lighting and presentation preserve alpha before blend finalization',
    () {
      final fragment = File('shaders/pixel_material.frag').readAsStringSync();
      final main = fragment.substring(fragment.indexOf('void main()'));
      final lighting = main.indexOf('if (atmosphere.options.z < 0.5');
      final blend = main.lastIndexOf('if (material.alphaMode == 0.0)');
      final writes = RegExp(r'\b(color|outColor)(?:\.([rgba]+))?\s*[+*/-]?=')
          .allMatches(main.substring(lighting, blend))
          .toList();
      expect(writes, isNotEmpty);
      for (final write in writes) {
        expect(write.group(1), 'outColor');
        expect(write.group(2), 'rgb');
      }
      expect(
        main.substring(blend),
        contains('outColor.rgb *= material.albedoColor.a * fragColor.a;'),
      );
      expect(main.substring(blend), contains('outColor.rgb *= outColor.a;'));
      expect(main.substring(blend), contains('outColor.a = 1.0;'));
    },
  );

  test(
    'depth haze uses camera depth after emission and before alpha blending',
    () {
      final fragment = File('shaders/pixel_material.frag').readAsStringSync();
      expect(fragment, contains('fragViewDepth'));
      expect(
        fragment.indexOf('presentation.fogColor'),
        greaterThan(fragment.indexOf('vec3 litGlass')),
      );
      expect(
        fragment.indexOf('presentation.fogColor'),
        lessThan(fragment.lastIndexOf('if (material.alphaMode == 0.0)')),
      );
      for (final name in [
        'pixel_material.vert',
        'pixel_lit_material.vert',
        'pixel_ground.vert',
      ]) {
        final vertex = File('shaders/$name').readAsStringSync();
        expect(
          vertex,
          contains('fragViewDepth = -(vertex_info.view * world).z;'),
        );
      }
    },
  );
}
