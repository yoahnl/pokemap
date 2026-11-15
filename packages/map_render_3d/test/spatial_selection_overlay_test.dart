import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flame_3d/game.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/spatial_selection.dart';

void main() {
  test('the selection frame is drawn by the overlay vertex stage', () {
    final frame = spatialSelectionFrame(
      Vector3.zero(),
      Vector3.all(1),
      .04,
      const Color(0xFF3366FF),
    );

    expect(frame, hasLength(12));
    for (final edge in frame) {
      final material = edge.mesh.surfaces.single.material as UnlitMaterial;
      expect(material.vertexShader.entryPoint, 'SelectionOverlayVertex');
      expect(material.fragmentShader.entryPoint, 'SelectionOverlayFragment');
      expect(material.albedoColor, const Color(0xFF3366FF));
    }
  });

  test('the overlay vertex stage pins visible vertices to the near plane', () {
    final vertex = File('shaders/selection_overlay.vert').readAsStringSync();
    final main = vertex.substring(vertex.indexOf('void main()'));

    expect(
      main,
      contains(
        'vec4 clip = vertex_info.projection * vertex_info.view * world;',
      ),
    );
    expect(main, contains('if (clip.w > 0.000001) clip.z = 0.0;'));
    expect(main, contains('gl_Position = clip;'));
    expect(main, contains('fragViewDepth = -(vertex_info.view * world).z;'));
  });

  test('the shipped pixel bundle contains the overlay vertex stage', () {
    final bundle = File('assets/shaders/pixel_material.shaderbundle')
        .readAsBytesSync();

    final names = latin1.decode(bundle);
    expect(names, contains('SelectionOverlayVertex'));
    expect(names, contains('SelectionOverlayFragment'));
  });
}
