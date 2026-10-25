import 'dart:ui' show Color;
import 'dart:developer' as developer;

import 'package:flame_3d/graphics.dart';

import 'spatial_shadow_target_native.dart'
    if (dart.library.js_interop) 'spatial_shadow_target_stub.dart'
    as platform;

final class SpatialShadowTarget {
  SpatialShadowTarget(
    GpuBackend backend, {
    required int width,
    required int height,
    bool antialiasing = true,
    bool preferMultisampling = true,
  }) {
    if (!antialiasing) {
      target = backend.createRenderTarget(
        width: width,
        height: height,
        clearValue: const Color(0xffffffff),
      );
      texture = target.colorTexture;
      samples = 1;
      supersampled = false;
      return;
    }
    final probe = backend.createRenderTarget(
      width: 1,
      height: 1,
      clearValue: const Color(0xffffffff),
    );
    final sampled = antialiasing && preferMultisampling
        ? platform.multisampleSpatialShadowTarget(
            backend,
            probe,
            width: width,
            height: height,
          )
        : null;
    var useSupersampling = sampled == null;
    GpuRenderTarget selected = probe;
    if (sampled == null) {
      try {
        selected = backend.createRenderTarget(
          width: width * 2,
          height: height * 2,
          clearValue: const Color(0xffffffff),
        );
      } on Exception catch (error) {
        developer.log(
          'Supersampled shadow allocation failed; keeping the logical resolution.',
          name: 'map_render_3d.shadows',
          error: error,
        );
        selected = backend.createRenderTarget(
          width: width,
          height: height,
          clearValue: const Color(0xffffffff),
        );
        useSupersampling = false;
      }
    }
    target = selected;
    supersampled = useSupersampling;
    texture = sampled ?? target.colorTexture;
    samples = sampled != null || supersampled ? 4 : 1;
  }

  late final GpuRenderTarget target;
  late final GpuTexture texture;
  late final int samples;
  late final bool supersampled;
  bool get multisampled => samples > 1 && !supersampled;
}
