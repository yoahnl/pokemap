import 'dart:typed_data';
import 'dart:ui';

import 'package:flame_3d/graphics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart' show SizedBox;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_depth_of_field.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';

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
    for (final enabled in [false, true, false, true]) {
      controller.depthOfFieldProfile = SpatialDepthOfFieldProfile(
        enabled: enabled,
        strength: .6,
        focusRange: 5,
      );
      game.syncDepthOfField();
      expect(game.device.postProcess != null, enabled);
      expect(
        game.device.secondaryColorClearValue,
        enabled ? SpatialDepthOfField.depthClearValue : null,
      );
      expect(game.depthOfFieldFrame['enabled'], enabled);
      if (enabled) expect(game.depthOfFieldFrame['strength'], .6);
    }
    expect(backend.allocations, 0);
    expect(backend.loads, 0);
  });

  test('composite blurs the scene with the main pass depth attachment', () {
    final backend = _Backend();
    final effect = SpatialDepthOfField(backend)
      ..profile = SpatialDepthOfFieldProfile(enabled: true, focusRange: 12)
      ..focusDepth = 30;
    final color = _Target(secondary: true);
    final output = effect.compositeTexture(color, const Size(960, 540));
    expect(output, isNot(same(color.colorTexture)));
    expect(backend.textures['sceneTexture'], same(color.colorTexture));
    expect(backend.textures['depthTexture'], same(color.secondaryColorTexture));
    final uniforms = backend.uniforms['DepthOfField']!;
    expect(uniforms.getFloat32(0, Endian.little), 30);
    expect(uniforms.getFloat32(12, Endian.little), 126);
    expect(backend.passes, 1);
    expect(effect.compositePasses, 1);
  });

  test('without a depth attachment the scene is presented sharp', () {
    final backend = _Backend();
    final effect = SpatialDepthOfField(backend)
      ..profile = SpatialDepthOfFieldProfile(enabled: true);
    final color = _Target();
    expect(
      effect.compositeTexture(color, const Size(64, 64)),
      same(color.colorTexture),
    );
    expect(backend.allocations, 0);
    expect(backend.passes, 0);
    expect(backend.loads, 0);
  });

  test('partial target allocation is retried without poisoning dimensions', () {
    final backend = _Backend()..failAllocation = 1;
    final effect = SpatialDepthOfField(backend)
      ..profile = SpatialDepthOfFieldProfile(enabled: true);
    final color = _Target(secondary: true);
    void composite() => effect.compositeTexture(color, const Size(64, 64));
    expect(composite, throwsStateError);
    backend.failAllocation = null;
    composite();
    expect(backend.allocations, 2);
    expect(effect.targetAllocations, 1);
    expect(effect.compositePasses, 1);
  });

  test('partial compositor buffer initialization can recover', () {
    final backend = _Backend()..failBufferWrite = true;
    final effect = SpatialDepthOfField(backend)
      ..profile = SpatialDepthOfFieldProfile(enabled: true);
    final color = _Target(secondary: true);
    expect(
      () => effect.compositeTexture(color, const Size(64, 64)),
      throwsStateError,
    );
    backend.failBufferWrite = false;
    effect.compositeTexture(color, const Size(64, 64));
    expect(effect.compositePasses, 1);
  });

  test('disabled skips GPU work and local adjustments reuse the target', () {
    final backend = _Backend();
    final effect = SpatialDepthOfField(backend);
    final color = _Target(secondary: true);
    GpuTexture composite() =>
        effect.compositeTexture(color, const Size(960, 600));
    expect(composite(), same(color.colorTexture));
    expect(backend.allocations, 0);
    expect(backend.passes, 0);
    expect(backend.loads, 0);
    effect.profile = SpatialDepthOfFieldProfile(enabled: true);
    composite();
    expect(backend.allocations, 1);
    expect(backend.passes, 1);
    effect.profile = SpatialDepthOfFieldProfile(
      enabled: true,
      strength: .6,
      focusRange: 18,
    );
    composite();
    expect(backend.allocations, 1);
    expect(backend.loads, 1);
    expect(backend.passes, 2);
    effect.profile = SpatialDepthOfFieldProfile();
    expect(composite(), same(color.colorTexture));
    expect(backend.passes, 2);
    expect(backend.allocations, 1);
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
  final textures = <String, GpuTexture>{};
  final uniforms = <String, ByteData>{};
  int? failAllocation;
  bool failBufferWrite = false;
  @override
  GpuRenderTarget createRenderTarget({
    required int width,
    required int height,
    required Color clearValue,
    Color? secondaryColorClearValue,
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
  _Target({bool secondary = false})
    : secondaryColorTexture = secondary ? _Texture() : null;

  @override
  final colorTexture = _Texture();

  @override
  final GpuTexture? secondaryColorTexture;
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
    return _Pass(backend);
  }

  @override
  void end() {}
}

final class _Pass implements GpuRenderPass {
  _Pass(this.backend);
  final _Backend backend;
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
  void bindUniform(GpuUniformSlot slot, ByteData data) =>
      backend.uniforms[(slot as _Slot).name] = data;
  @override
  void bindTexture(GpuUniformSlot slot, GpuTexture texture) =>
      backend.textures[(slot as _Slot).name] = texture;
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
  GpuUniformSlot getUniformSlot(String slot) => _Slot(slot);
}

final class _Slot implements GpuUniformSlot {
  _Slot(this.name);
  final String name;
  @override
  int? get sizeInBytes => null;
  @override
  int? getMemberOffsetInBytes(String member) => null;
}

final class _Pipeline implements GpuPipeline {}
