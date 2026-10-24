import 'dart:typed_data';
import 'dart:ui';

import 'package:flame_3d/graphics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/spatial_shadow_map.dart';
import 'package:map_render_3d/src/spatial_shadow_profile.dart';
import 'package:map_render_3d/src/spatial_point_light.dart';

void main() {
  test('point maps render all six faces per light into one reused GPU atlas without ending caller frame', () {
    final backend = _Backend();
    final map = SpatialShadowMap(backend, ownsFrame: false);
    final lights = [
      SpatialPointLight(position: (x: 2, y: 3, z: 4), radius: 5),
      SpatialPointLight(position: (x: 8, y: 3, z: 4), radius: 5),
    ];
    var draws = 0;
    final first = map.renderPointLights(lights, (context, material, light) {
      draws++;
    });
    expect(draws, 12);
    expect(first!.lightCount, 2);
    expect(first.texture.width, 768);
    expect(first.texture.height, 1024);
    expect(backend.events.where((event) => event == 'submit'), hasLength(1));
    expect(backend.events, isNot(contains('end')));
    final second = map.renderPointLights(lights, (_, _, _) {});
    expect(second!.texture, same(first.texture));
    expect(map.pointTargetAllocations, 1);
    final before = backend.events.length;
    expect(map.renderPointLights([], (_, _, _) {}), isNull);
    expect(backend.events, hasLength(before));
  });
  test('shadow passes reuse their sampled GPU target and submit before the main draw', () {
    final backend = _Backend();
    final map = SpatialShadowMap(backend);
    final profile = SpatialShadowProfile(
      casterInstanceIds: {'house'},
      resolution: 64,
    );
    final first = map.render(profile, (x: -.65, y: .8, z: -.45), (
      context,
      material,
    ) {
      backend.events.add('casters');
    });
    expect(backend.events, [
      'allocate',
      'frame',
      'opaque-depth',
      'casters',
      'submit',
      'end',
    ]);
    final second = map.render(profile, (x: -.65, y: .8, z: -.45), (_, _) {});
    expect(first.texture, same(second.texture));
    expect(map.targetAllocations, 1);
    expect(first.texture.resource, same(backend.targets.first.colorTexture));
    map.render(
      SpatialShadowProfile(casterInstanceIds: {'house'}, resolution: 128),
      (x: -.65, y: .8, z: -.45),
      (_, _) {},
    );
    expect(map.targetAllocations, 2);
  });
  test('a shadow pass never ends a frame borrowed from the main renderer', () {
    final backend = _Backend();
    SpatialShadowMap(backend, ownsFrame: false).render(
      SpatialShadowProfile(casterInstanceIds: {'house'}, resolution: 64),
      (x: -.65, y: .8, z: -.45),
      (_, _) {},
    );
    expect(backend.events.last, 'submit');
    expect(backend.events, isNot(contains('end')));
  });
}

final class _Backend extends GpuBackend {
  final events = <String>[];
  final targets = <_Target>[];
  @override
  GpuRenderTarget createRenderTarget({
    required int width,
    required int height,
    required Color clearValue,
  }) {
    events.add('allocate');
    expect(clearValue, const Color(0xffffffff));
    final target = _Target();
    targets.add(target);
    return target;
  }

  @override
  GpuFrame beginFrame() {
    events.add('frame');
    return _Frame(events);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

final class _Target implements GpuRenderTarget {
  @override
  final GpuTexture colorTexture = _Texture();
}

final class _Texture implements GpuTexture {
  @override
  Image asImage() => throw StateError('Shadow maps must remain on the GPU.');
  @override
  void write(ByteData data) =>
      throw StateError('Shadow maps must be rendered, not uploaded.');
}

final class _Frame implements GpuFrame {
  _Frame(this.events);
  final List<String> events;
  @override
  GpuRenderPass beginRenderPass(
    GpuRenderTarget target, {
    required BlendState blend,
    required DepthStencilState depthStencil,
  }) {
    expect(blend, BlendState.opaque);
    expect(depthStencil, DepthStencilState.standard);
    events.add('opaque-depth');
    return _Pass(events);
  }

  @override
  void end() => events.add('end');
}

final class _Pass implements GpuRenderPass {
  _Pass(this.events);
  final List<String> events;
  @override
  void submit() => events.add('submit');
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}
