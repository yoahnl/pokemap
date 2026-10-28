import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flame_3d/graphics.dart';
import 'package:flutter/foundation.dart' show LicenseRegistry;
import 'package:flutter/widgets.dart' show SizedBox;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_depth_of_field.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';
import 'package:map_render_3d/src/spatial_upscaler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('an output no larger than the input is presented untouched', () {
    final backend = _Backend();
    final upscaler = SpatialUpscaler(backend);
    final input = _Texture();
    for (final output in [const Size(960, 540), const Size(640, 360)]) {
      expect(
        upscaler.upscale(input, const Size(960, 540), output),
        same(input),
      );
    }
    expect(backend.allocations, 0);
    expect(backend.passes, isEmpty);
    expect(backend.loads, 0);
  });

  test('EASU then RCAS upscale into reused output targets', () {
    final backend = _Backend();
    final upscaler = SpatialUpscaler(backend);
    final input = _Texture();
    final first = upscaler.upscale(
      input,
      const Size(960, 540),
      const Size(1920, 1080),
    );
    expect(backend.passes.map((pass) => pass.texture), [
      same(input),
      same(backend.targets[0].colorTexture),
    ]);
    expect(first, same(backend.targets[1].colorTexture));
    final easu = backend.passes[0].uniforms['Easu']!;
    expect(
      [for (var i = 0; i < 4; i++) easu.getFloat32(i * 4, Endian.little)],
      [960, 540, 1920, 1080],
    );
    final rcas = backend.passes[1].uniforms['Rcas']!;
    expect(rcas.getFloat32(0, Endian.little), 1920);
    expect(rcas.getFloat32(4, Endian.little), 1080);
    expect(
      rcas.getFloat32(8, Endian.little),
      closeTo(math.pow(2, -SpatialUpscaler.sharpnessStops), 1e-6),
    );

    upscaler.upscale(input, const Size(960, 540), const Size(1920, 1080));
    expect(backend.allocations, 2);
    expect(backend.loads, 1);
    expect(upscaler.passes, 4);
    upscaler.upscale(input, const Size(640, 360), const Size(1280, 720));
    expect(backend.allocations, 4);
    expect(upscaler.targetAllocations, 4);
  });

  test('FSR becomes the post process only below native resolution', () {
    final controller = SpatialSceneController();
    addTearDown(controller.dispose);
    SpatialSceneGame game(double scale) => SpatialSceneGame(
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
        renderResolutionScale: scale,
      ),
      onPreviewStatus: (_) {},
      onSurfaceChanged: () {},
    );
    final reduced = game(.5);
    reduced.syncDepthOfField();
    expect(reduced.device.postProcess, isNull);
    controller.upscaling = SpatialUpscaling.fsr1;
    reduced.syncDepthOfField();
    expect(reduced.device.postProcess, isNotNull);
    expect(reduced.device.secondaryColorClearValue, isNull);
    final native = game(1)..syncDepthOfField();
    expect(native.device.postProcess, isNull);
    controller.depthOfFieldProfile = SpatialDepthOfFieldProfile(enabled: true);
    native.syncDepthOfField();
    expect(native.device.postProcess, isNotNull);
    expect(
      native.device.secondaryColorClearValue,
      SpatialDepthOfField.depthClearValue,
    );
  });

  test('the FSR notice reaches the licenses once a scene exists', () async {
    _Backend();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(
        message!.buffer.asUint8List(
          message.offsetInBytes,
          message.lengthInBytes,
        ),
      );
      if (key != SpatialUpscaler.licenseAsset) return null;
      return ByteData.sublistView(
        File('assets/shaders/fsr1-LICENSE.txt').readAsBytesSync(),
      );
    });
    addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));
    final controller = SpatialSceneController();
    addTearDown(controller.dispose);
    SpatialSceneGame(
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
    final notices = <String>[];
    await for (final entry in LicenseRegistry.licenses) {
      if (entry.packages.contains(SpatialUpscaler.licensedPackage)) {
        notices.add(entry.paragraphs.map((paragraph) => paragraph.text).join());
      }
    }
    expect(notices, hasLength(1));
    expect(notices.single, contains('Advanced Micro Devices'));
    expect(notices.single, contains('Permission is hereby granted'));
  });
}

final class _Backend extends GpuBackend {
  int allocations = 0, loads = 0;
  final targets = <_Target>[];
  final passes = <_Pass>[];

  @override
  GpuRenderTarget createRenderTarget({
    required int width,
    required int height,
    required Color clearValue,
    Color? secondaryColorClearValue,
  }) {
    allocations++;
    final target = _Target();
    targets.add(target);
    return target;
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
  }) => _Buffer();

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

  @override
  GpuTexture? get secondaryColorTexture => null;
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
    final pass = _Pass();
    backend.passes.add(pass);
    return pass;
  }

  @override
  void end() {}
}

final class _Pass implements GpuRenderPass {
  final uniforms = <String, ByteData>{};
  GpuTexture? texture;

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
      uniforms[(slot as _Slot).name] = ByteData.sublistView(
        Uint8List.fromList(data.buffer.asUint8List()),
      );

  @override
  void bindTexture(GpuUniformSlot slot, GpuTexture texture) =>
      this.texture = texture;

  @override
  void clearBindings() {}

  @override
  void draw() {}

  @override
  void submit() {}
}

final class _Buffer implements GpuBuffer {
  @override
  void write(ByteData data, {int destinationOffsetInBytes = 0}) {}
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
