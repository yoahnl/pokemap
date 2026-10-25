import 'dart:typed_data';
import 'dart:ui';

import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart' show SizedBox;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_depth_of_field.dart';
import 'package:map_render_3d/src/spatial_pixel_material.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';
import 'package:map_render_3d/src/spatial_render_context.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('presentation synchronizes without advancing the simulation', () {
    final backend = _Backend();
    final controller = SpatialSceneController();
    addTearDown(controller.dispose);
    final game = SpatialSceneGame(
      SpatialSceneView(
        scene: MapSpatialScene(width: 8, depth: 8),
        models: const [],
        loadModel: (_) async => Uint8List(0),
        controller: controller,
        onCell: (_, _) {},
        background: const Color(0xff000000),
        ground: const Color(0xff000000),
        edge: const Color(0xff000000),
        errorBuilder: (_, _) => const SizedBox(),
      ),
      onPreviewStatus: (_) {},
      onSurfaceChanged: () {},
    );
    final context = game.context as SpatialRenderContext;
    for (final enabled in [false, true, false, true]) {
      controller.depthOfFieldProfile = SpatialDepthOfFieldProfile(
        enabled: enabled,
        strength: .6,
        focusRange: 5,
      );
      game.syncDepthOfField();
      expect(context.depthOfField != null, enabled);
      expect(game.device.postProcess != null, enabled);
      if (enabled) {
        expect(
          context.depthOfField!.profile,
          same(controller.depthOfFieldProfile),
        );
      }
    }
    expect(backend.allocations, 0);
    expect(backend.loads, 0);
  });

  test('partial target allocation is retried without poisoning dimensions', () {
    final backend = _Backend()..failAllocation = 2;
    final effect = SpatialDepthOfField(backend)
      ..profile = SpatialDepthOfFieldProfile(enabled: true);
    void depth() => effect.renderDepth(
      size: const Size(64, 64),
      view: Matrix4.identity(),
      projection: Matrix4.identity(),
      draw: (_, _) {},
    );
    expect(depth, throwsStateError);
    backend.failAllocation = null;
    depth();
    expect(backend.allocations, 4);
    expect(effect.depthPasses, 1);
  });

  test('partial compositor buffer initialization can recover', () {
    final backend = _Backend()..failBufferWrite = true;
    final effect = SpatialDepthOfField(backend)
      ..profile = SpatialDepthOfFieldProfile(enabled: true);
    effect.renderDepth(
      size: const Size(64, 64),
      view: Matrix4.identity(),
      projection: Matrix4.identity(),
      draw: (_, _) {},
    );
    final color = _Target();
    expect(
      () => effect.compositeTexture(color, const Size(64, 64)),
      throwsStateError,
    );
    backend.failBufferWrite = false;
    effect.compositeTexture(color, const Size(64, 64));
    expect(effect.compositePasses, 1);
  });
  test('depth culling follows each source pose before pipeline binding', () {
    final backend = _Backend();
    final effect = SpatialDepthOfField(backend)
      ..profile = SpatialDepthOfFieldProfile(enabled: true);
    final source = SpatialPixelMaterial(Texture.standard);
    effect.renderDepth(
      size: const Size(64, 64),
      view: Matrix4.identity(),
      projection: Matrix4.identity(),
      draw: (_, materialFor) {
        for (final cull in [
          CullMode.backFace,
          CullMode.none,
          CullMode.frontFace,
        ]) {
          source.cullMode = cull;
          expect(materialFor(source).cullMode, cull);
        }
      },
    );
  });
  test('disabled skips GPU work and local adjustments reuse depth targets', () {
    final backend = _Backend();
    final effect = SpatialDepthOfField(backend);
    void depth() => effect.renderDepth(
      size: const Size(960, 600),
      view: Matrix4.identity(),
      projection: Matrix4.identity(),
      draw: (_, _) {},
    );
    depth();
    expect(backend.allocations, 0);
    expect(backend.passes, 0);
    expect(backend.loads, 0);
    effect.profile = SpatialDepthOfFieldProfile(enabled: true);
    depth();
    final color = _Target();
    effect.compositeTexture(color, const Size(960, 600));
    expect(backend.allocations, 2);
    expect(backend.passes, 2);
    effect.profile = SpatialDepthOfFieldProfile(
      enabled: true,
      strength: .6,
      focusRange: 18,
    );
    depth();
    effect.compositeTexture(color, const Size(960, 600));
    expect(backend.allocations, 2);
    expect(backend.loads, 1);
    expect(backend.passes, 4);
    effect.profile = SpatialDepthOfFieldProfile();
    depth();
    expect(
      effect.compositeTexture(color, const Size(960, 600)),
      same(color.colorTexture),
    );
    expect(backend.passes, 4);
    expect(backend.allocations, 2);
  });
  test('sharp zone follows camera depth with a gradual bounded blur', () {
    final profile = SpatialDepthOfFieldProfile(
      enabled: true,
      strength: .5,
      focusRange: 12,
    );
    for (final depth in [34.0, 38.0, 40.0, 42.0, 46.0]) {
      expect(profile.blurAtDepth(depth, focusDepth: 40), 0);
    }
    expect(profile.blurAtDepth(49, focusDepth: 40), closeTo(.25, .000001));
    expect(profile.blurAtDepth(52, focusDepth: 40), .5);
    expect(profile.blurAtDepth(28, focusDepth: 40), .5);
    expect(profile.blurAtDepth(70, focusDepth: 70), 0);
  });

  test('disabled or zero strength leaves every depth sharp', () {
    for (final profile in [
      SpatialDepthOfFieldProfile(),
      SpatialDepthOfFieldProfile(enabled: true, strength: 0),
    ]) {
      expect(profile.active, isFalse);
      expect(profile.blurAtDepth(100, focusDepth: 30), 0);
    }
  });

  test('invalid and nonfinite profiles are rejected', () {
    for (final strength in [-.1, 1.1, double.nan, double.infinity]) {
      expect(
        () => SpatialDepthOfFieldProfile(strength: strength),
        throwsArgumentError,
      );
    }
    for (final range in [1.9, 40.1, double.nan, double.infinity]) {
      expect(
        () => SpatialDepthOfFieldProfile(focusRange: range),
        throwsArgumentError,
      );
    }
  });
}

final class _Backend extends GpuBackend {
  int allocations = 0, passes = 0, loads = 0;
  int? failAllocation;
  bool failBufferWrite = false;
  @override
  GpuRenderTarget createRenderTarget({
    required int width,
    required int height,
    required Color clearValue,
  }) {
    allocations++;
    if (allocations == failAllocation) throw StateError('Allocation failed');
    return _Target();
  }

  @override
  GpuFrame beginFrame() => _Frame(this);
  @override
  GpuShaderLibrary loadShaderLibrary(String assetName) {
    loads++;
    return _Library();
  }

  @override
  GpuPipeline createPipeline({
    required GpuShader vertexShader,
    required GpuShader fragmentShader,
  }) => _Pipeline();
  @override
  GpuBuffer createBuffer({
    required GpuStorageMode storageMode,
    required int sizeInBytes,
  }) => _Buffer(this);
  @override
  GpuTexture createTexture({
    required GpuStorageMode storageMode,
    required int width,
    required int height,
    required GpuPixelFormat format,
  }) => throw UnimplementedError();
}

final class _Target implements GpuRenderTarget {
  @override
  final colorTexture = _Texture();
}

final class _Texture implements GpuTexture {
  @override
  void write(ByteData data) {}
  @override
  Image asImage() => throw UnimplementedError();
}

final class _Frame implements GpuFrame {
  _Frame(this.backend);
  final _Backend backend;
  @override
  GpuRenderPass beginRenderPass(
    GpuRenderTarget target, {
    required BlendState blend,
    required DepthStencilState depthStencil,
  }) {
    backend.passes++;
    return _Pass();
  }

  @override
  void end() {}
}

final class _Pass implements GpuRenderPass {
  @override
  void bindPipeline(GpuPipeline pipeline, CullMode cullMode) {}
  @override
  void bindVertexBuffer(GpuBufferView view, int vertexCount) {}
  @override
  void bindIndexBuffer(
    GpuBufferView view,
    GpuIndexType indexType,
    int indexCount,
  ) {}
  @override
  void bindUniform(GpuUniformSlot slot, ByteData data) {}
  @override
  void bindTexture(GpuUniformSlot slot, GpuTexture texture) {}
  @override
  void clearBindings() {}
  @override
  void draw() {}
  @override
  void submit() {}
}

final class _Buffer implements GpuBuffer {
  _Buffer(this.backend);
  final _Backend backend;
  @override
  void write(ByteData data, {int destinationOffsetInBytes = 0}) {
    if (backend.failBufferWrite) throw StateError('Buffer write failed');
  }
}

final class _Library implements GpuShaderLibrary {
  @override
  GpuShader operator [](String entryPoint) => _Shader();
}

final class _Shader implements GpuShader {
  @override
  GpuUniformSlot getUniformSlot(String slot) => _Slot();
}

final class _Slot implements GpuUniformSlot {
  @override
  int? get sizeInBytes => null;
  @override
  int? getMemberOffsetInBytes(String member) => null;
}

final class _Pipeline implements GpuPipeline {}
