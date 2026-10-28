import 'dart:typed_data';
import 'dart:ui' hide FragmentShader;

import 'package:flame_3d/components.dart';
import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/flutter_frame_graphics_device.dart';
import 'package:map_render_3d/src/spatial_atmosphere.dart';
import 'package:map_render_3d/src/spatial_lighting_preview.dart';
import 'package:map_render_3d/src/spatial_pixel_material.dart';
import 'package:map_render_3d/src/spatial_render_context.dart';
import 'package:map_render_3d/src/spatial_shadow_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('repeated decor surfaces draw once with every instance transform', () {
    final fixture = _Fixture();
    final tree = fixture.surface('tree', fixture.material());

    fixture.render([for (var index = 0; index < 5; index++) (tree, index)]);

    expect(fixture.backend.draws, isEmpty);
    expect(fixture.backend.instanced, hasLength(1));
    final draw = fixture.backend.instanced.single;
    expect(draw.vertexEntry, 'InstancedTextureVertex');
    expect(draw.geometry, 'tree');
    expect(draw.count, 5);
    for (var index = 0; index < 5; index++) {
      expect(
        draw.instances.sublist(index * 16, index * 16 + 16),
        _model(index).storage,
      );
    }
    expect(draw.uniforms['VertexInfo'], isNotNull);
    expect(draw.uniforms['Material'], isNotNull);
    expect(fixture.context.instancedDrawCount, 1);
  });

  test('a single surface and a differing pose keep the regular draw', () {
    final fixture = _Fixture();
    final material = fixture.material();
    final tree = fixture.surface('tree', material);
    final rock = fixture.surface('rock', material);

    fixture.render(
      [(tree, 0), (tree, 1), (tree, 2), (rock, 3)],
      before: (index) =>
          material.uvRect.setValues(index == 2 ? .5 : 0, 0, 1, 1),
    );

    expect(fixture.backend.instanced.single.count, 2);
    expect(fixture.backend.draws.map((draw) => draw.geometry), [
      'tree',
      'rock',
    ]);
  });

  test('materials lit by the atmosphere are never instanced', () {
    final fixture = _Fixture()
      ..context.atmosphereProfile = SpatialAtmosphereProfile(
        windows: [
          SpatialWindowGlow(
            target: const SpatialAtmosphereTarget(
              instanceId: 'decor-1',
              materialName: 'glass',
            ),
            uvRects: const [Rect.fromLTRB(0, 0, 1, 1)],
          ),
        ],
      );
    final house = fixture.surface(
      'house',
      fixture.material(sourceMaterialName: 'glass'),
    );

    fixture.render([for (var index = 0; index < 3; index++) (house, index)]);

    expect(fixture.backend.instanced, isEmpty);
    expect(fixture.backend.draws, hasLength(3));
  });

  test('blended surfaces stay in the sorted transparent pass', () {
    final fixture = _Fixture();
    final glass = fixture.surface(
      'glass',
      fixture.material(alphaMode: Model3dAlphaMode.blend),
    );

    fixture.render([for (var index = 0; index < 3; index++) (glass, index)]);

    expect(fixture.backend.instanced, isEmpty);
    expect(fixture.backend.draws, hasLength(3));
  });

  test('a pass without instancing draws every surface itself', () {
    final fixture = _Fixture(instancing: false);
    final tree = fixture.surface('tree', fixture.material());

    fixture.render([for (var index = 0; index < 4; index++) (tree, index)]);

    expect(fixture.backend.instanced, isEmpty);
    expect(fixture.backend.draws, hasLength(4));
    expect(fixture.context.instancedDrawCount, 0);
  });
}

Matrix4 _model(int index) =>
    Matrix4.translationValues(index * 2.0, 0, -index * 3.0);

class _Fixture {
  _Fixture({bool instancing = true}) : backend = _Backend(instancing) {
    device = FlutterFrameGraphicsDevice(backend: backend);
    context = SpatialRenderContext(device)
      ..setCamera(Matrix4.identity(), Matrix4.identity())
      ..shadowAntialiasingEnabled = false
      ..lighting = SpatialLightingProfile.stylized(
        surfaceStrength: 0,
        shadow: SpatialShadowProfile(casterInstanceIds: {}, resolution: 64),
      );
  }

  final _Backend backend;
  late final FlutterFrameGraphicsDevice device;
  late final SpatialRenderContext context;
  late final texture = Texture(ByteData(4), width: 1, height: 1);

  SpatialPixelMaterial material({
    Model3dAlphaMode alphaMode = Model3dAlphaMode.opaque,
    String? sourceMaterialName,
  }) => SpatialPixelMaterial(
    texture,
    alphaMode: alphaMode,
    alphaCutoff: .5,
    sourceMaterialName: sourceMaterialName,
  );

  _Surface surface(String name, Material material) => _Surface(name, material);

  void render(List<(Surface, int)> draws, {void Function(int index)? before}) {
    device.begin();
    device.beginPass(const Size(64, 64));
    try {
      context.submitDraw(
        _Object(() {
          for (final (surface, index) in draws) {
            before?.call(index);
            context
              ..model.setFrom(_model(index))
              ..sourceInstanceId = 'decor-$index';
            context.drawSurface(surface);
          }
        }),
        Matrix4.identity(),
      );
      context.flush();
    } finally {
      device.end();
    }
  }
}

class _Object extends Object3D {
  _Object(this.capture);
  final void Function() capture;
  @override
  void draw(RenderContext context) => capture();
}

class _Surface extends Surface {
  _Surface(String name, Material material)
    : buffer = _Buffer(name),
      super(
        vertices: [
          Vertex(position: Vector3(-.25, 0, 0), texCoord: Vector2.zero()),
          Vertex(position: Vector3(.25, 0, 0), texCoord: Vector2.zero()),
          Vertex(position: Vector3(0, .5, 0), texCoord: Vector2.zero()),
        ],
        indices: [0, 1, 2],
        material: material,
      );
  final _Buffer buffer;
  @override
  GpuBuffer createResource() => buffer;
}

typedef _Recorded = ({
  String geometry,
  String vertexEntry,
  Map<String, List<double>> uniforms,
});

typedef _InstancedDraw = ({
  String geometry,
  String vertexEntry,
  Map<String, List<double>> uniforms,
  List<double> instances,
  int count,
});

final class _Backend extends GpuBackend {
  _Backend(this.instancing);
  final bool instancing;
  final draws = <_Recorded>[];
  final instanced = <_InstancedDraw>[];
  @override
  GpuFrame beginFrame() => _Frame(this);
  @override
  GpuRenderTarget createRenderTarget({
    required int width,
    required int height,
    required Color clearValue,
    Color? secondaryColorClearValue,
  }) => _Target();
  @override
  GpuShaderLibrary loadShaderLibrary(String assetName) => _Library();
  @override
  GpuPipeline createPipeline({
    required GpuShader vertexShader,
    required GpuShader fragmentShader,
  }) => _Pipeline((vertexShader as _Shader).entry, instanced: false);
  @override
  GpuPipeline? createInstancedPipeline({
    required GpuShader vertexShader,
    required GpuShader fragmentShader,
    required GpuInstanceLayout layout,
  }) => instancing
      ? _Pipeline((vertexShader as _Shader).entry, instanced: true)
      : null;
  @override
  GpuBuffer createBuffer({
    required GpuStorageMode storageMode,
    required int sizeInBytes,
  }) => _Buffer('unused');
  @override
  GpuTexture createTexture({
    required GpuStorageMode storageMode,
    required int width,
    required int height,
    required GpuPixelFormat format,
  }) => _Texture();
}

class _Frame implements GpuFrame {
  _Frame(this.backend);
  final _Backend backend;
  @override
  GpuRenderPass beginRenderPass(
    GpuRenderTarget target, {
    required BlendState blend,
    required DepthStencilState depthStencil,
  }) => backend.instancing ? _InstancedPass(backend) : _Pass(backend);
  @override
  void end() {}
}

class _Pass implements GpuRenderPass {
  _Pass(this.backend);
  final _Backend backend;
  final uniforms = <String, List<double>>{};
  String geometry = '', vertexEntry = '';
  @override
  void bindPipeline(GpuPipeline pipeline, CullMode cullMode) =>
      vertexEntry = (pipeline as _Pipeline).vertexEntry;
  @override
  void bindUniform(GpuUniformSlot slot, ByteData data) =>
      uniforms[(slot as _Slot).name] = data.buffer
          .asFloat32List(data.offsetInBytes, data.lengthInBytes ~/ 4)
          .toList();
  @override
  void bindTexture(GpuUniformSlot slot, GpuTexture value) {}
  @override
  void bindVertexBuffer(GpuBufferView view, int vertexCount) =>
      geometry = (view.buffer as _Buffer).name;
  @override
  void bindIndexBuffer(
    GpuBufferView view,
    GpuIndexType indexType,
    int indexCount,
  ) {}
  @override
  void clearBindings() => uniforms.clear();
  @override
  void draw() {
    if (!vertexEntry.contains('Shadow')) {
      backend.draws.add((
        geometry: geometry,
        vertexEntry: vertexEntry,
        uniforms: Map.of(uniforms),
      ));
    }
  }

  @override
  void submit() {}
}

class _InstancedPass extends _Pass implements GpuInstancedRenderPass {
  _InstancedPass(super.backend);
  @override
  void drawInstances(ByteData instances, int instanceCount) =>
      backend.instanced.add((
        geometry: geometry,
        vertexEntry: vertexEntry,
        uniforms: Map.of(uniforms),
        instances: instances.buffer
            .asFloat32List(instances.offsetInBytes, instanceCount * 16)
            .toList(),
        count: instanceCount,
      ));
}

class _Pipeline implements GpuPipeline {
  _Pipeline(this.vertexEntry, {required this.instanced});
  final String vertexEntry;
  final bool instanced;
}

class _Library implements GpuShaderLibrary {
  @override
  GpuShader operator [](String entryPoint) => _Shader(entryPoint);
}

class _Shader implements GpuShader {
  _Shader(this.entry);
  final String entry;
  static final _slots = <String, _Slot>{};
  @override
  GpuUniformSlot getUniformSlot(String slot) =>
      _slots.putIfAbsent(slot, () => _Slot(slot));
}

class _Slot implements GpuUniformSlot {
  _Slot(this.name);
  final String name;
  final members = <String>[];
  @override
  int? get sizeInBytes => name.endsWith('Texture') ? null : 4096;
  @override
  int? getMemberOffsetInBytes(String member) {
    if (!members.contains(member)) members.add(member);
    return members.indexOf(member) * 64;
  }
}

class _Buffer implements GpuBuffer {
  _Buffer(this.name);
  final String name;
  @override
  void write(ByteData data, {int destinationOffsetInBytes = 0}) {}
}

class _Target implements GpuRenderTarget {
  @override
  final colorTexture = _Texture();

  @override
  GpuTexture? get secondaryColorTexture => null;
}

class _Texture implements GpuTexture {
  @override
  void write(ByteData data) {}
  @override
  Image asImage() => throw UnsupportedError('No readback in renderer tests.');
}
