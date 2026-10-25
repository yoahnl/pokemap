import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
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
