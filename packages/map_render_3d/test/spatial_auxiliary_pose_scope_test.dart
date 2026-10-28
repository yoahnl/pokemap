import 'dart:typed_data';
import 'dart:ui' hide FragmentShader;

import 'package:flame_3d/components.dart';
import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/flutter_frame_graphics_device.dart';
import 'package:map_render_3d/src/spatial_lighting_preview.dart';
import 'package:map_render_3d/src/spatial_pixel_material.dart';
import 'package:map_render_3d/src/spatial_point_light.dart';
import 'package:map_render_3d/src/spatial_point_shadow.dart';
import 'package:map_render_3d/src/spatial_render_context.dart';
import 'package:map_render_3d/src/spatial_shadow_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final flags in [2, 4, 6]) {
    test('auxiliary passes $flags avoid copying the outer pose', () {
      final baseline = _Fixture(0)..render();
      final fixture = _Fixture(flags)..render();
      expect(baseline.context.countedModel.clones, 0);
      expect(
        fixture.context.countedModel.clones -
            baseline.context.countedModel.clones,
        0,
        reason: 'Captures copy into pooled snapshots; replays reuse a scratch.',
      );
      expect(
        fixture.context.countedModel.copies -
            baseline.context.countedModel.copies,
        0,
        reason: 'Auxiliary contexts must not overwrite the color model.',
      );
      _expectDraws(fixture, flags);
      _expectRestored(fixture);
    });
  }

  test('mask and blend keep pass filtering, uniforms and color order', () {
    final baseline = _Fixture(0, mixedAlpha: true)..render();
    final fixture = _Fixture(6, mixedAlpha: true)..render();
    expect(baseline.context.countedModel.clones, 1);
    expect(
      fixture.context.countedModel.clones -
          baseline.context.countedModel.clones,
      0,
    );
    expect(
      fixture.context.countedModel.copies -
          baseline.context.countedModel.copies,
      0,
    );
    _expectDraws(fixture, 6, blended: true);
    _expectRestored(fixture);
  });

  test('instance and shadow IDs select only the eligible auxiliary draws', () {
    final fixture = _Fixture(6, filterCasters: true)..render();
    final draws = fixture.backend.draws;
    expect(
      draws.where((draw) => draw.path == 'shadow').map((draw) => draw.name),
      ['pose-0'],
    );
    expect(
      draws.where((draw) => draw.path == 'point').map((draw) => draw.name),
      List.filled(6, 'pose-1'),
    );
    expect(draws.where((draw) => draw.path == 'color'), hasLength(3));
    expect(fixture.context.shadowStats.casterDrawCount, 1);
    expect(fixture.context.shadowStats.pointCasterDrawCount, 6);
    expect(fixture.context.countedModel.clones, 0);
    _expectRestored(fixture);
  });

  test('disabled shadows skip every shadow pass and keep the color pass', () {
    final fixture = _Fixture(6);
    fixture.context.shadowsEnabled = false;
    fixture.render();
    final draws = fixture.backend.draws;
    expect(draws.where((draw) => draw.path == 'shadow'), isEmpty);
    expect(draws.where((draw) => draw.path == 'point'), isEmpty);
    expect(
      draws.where((draw) => draw.path == 'color').map((draw) => draw.name),
      ['pose-0', 'pose-1', 'pose-2'],
    );
    expect(fixture.context.shadowStats.casterDrawCount, 0);
    expect(fixture.context.shadowStats.pointCasterDrawCount, 0);
    expect(fixture.context.shadowFrame, isNull);
    expect(fixture.context.pointShadowFrame, isNull);
    _expectRestored(fixture);
  });

  for (final failure in ['pipeline', 'geometry']) {
    for (final flags in [2, 4]) {
      test(
        'failed $failure in auxiliary pass $flags restores the next frame',
        () {
          final fixture = _Fixture(flags);
          fixture.backend.failure = failure;
          expect(fixture.render, throwsStateError);
          _expectRestored(fixture);
          fixture.backend
            ..failure = null
            ..draws.clear();
          fixture.device.colorContexts.clear();
          fixture.render(submit: false);
          expect(fixture.backend.draws, isEmpty);
          expect(fixture.device.colorContexts, isEmpty);
          fixture.render();
          _expectDraws(fixture, flags);
          _expectRestored(fixture);
        },
      );
    }
  }
}

void _expectDraws(_Fixture fixture, int flags, {bool blended = false}) {
  final draws = fixture.backend.draws;
  final color = draws.where((draw) => draw.path == 'color').toList();
  expect(color.map((draw) => draw.name), ['pose-0', 'pose-1', 'pose-2']);
  expect(fixture.context.drawCount, 1);
  final casters = blended ? 2 : 3;
  expect(
    draws.where((draw) => draw.path == 'shadow'),
    hasLength(flags & 2 == 0 ? 0 : casters),
  );
  expect(
    draws.where((draw) => draw.path == 'point'),
    hasLength(flags & 4 == 0 ? 0 : casters * 6),
  );
  expect(
    fixture.context.shadowStats.casterDrawCount,
    flags & 2 == 0 ? 0 : casters,
  );
  expect(
    fixture.context.shadowStats.pointCasterDrawCount,
    flags & 4 == 0 ? 0 : casters * 6,
  );
  expect(fixture.context.shadowStats.hiddenDrawCount, 0);
  expect(
    fixture.context.shadowStats.pointShadowLightCount,
    flags & 4 == 0 ? 0 : 1,
  );
  for (final draw in draws) {
    final index = int.parse(draw.name.substring(5));
    final expectedModel = _model(index);
    if (draw.path == 'shadow') {
      expectedModel.setTranslationRaw(-3 + index * 2, 0, -index * 2);
    }
    _expectMatrix(draw.field('VertexInfo', 'model', 16), expectedModel);
    final face = draw.path == 'point'
        ? draw.field('PointDepth', 'tile', 4)[2].toInt()
        : null;
    final camera = draw.path == 'shadow'
        ? spatialShadowProjection(
            fixture.context.lighting.shadow!,
            fixture.context.lighting.sunDirection,
            origin: fixture.context.lighting.shadow!.center,
          )
        : face != null
        ? spatialPointShadowProjection(
            fixture.context.lighting.pointLights.single,
            face,
          )
        : null;
    _expectMatrix(
      draw.field('VertexInfo', 'view', 16),
      camera?.view ?? Matrix4.identity(),
    );
    _expectMatrix(
      draw.field('VertexInfo', 'projection', 16),
      camera?.projection ?? Matrix4.identity(),
    );
    _expectMatrix(draw.field('JointMatrices', 'joints', 16), _joint(index));
    _expectVector(draw.field('Material', 'albedoColor', 4), _color(index));
    _expectVector(draw.field('Material', 'uvRect', 4), [
      .1 * index,
      .2,
      .7,
      .8,
    ]);
    _expectVector(draw.field('Material', 'uvTransformU', 4), [
      2 + index.toDouble(),
      0,
      .125 * index,
      0,
    ]);
    _expectVector(draw.field('Material', 'uvTransformV', 4), [
      0,
      3 + index.toDouble(),
      .25 * index,
      0,
    ]);
    _expectVector(draw.field('Material', 'wrapModes', 2), [33648, 33071]);
    expect(draw.texture, same(fixture.textures[index].resource));
    expect(draw.cull, _cull(index));
    expect(
      draw.field('Material', 'alphaMode', 1).single,
      blended ? index + 1 : 1,
    );
    expect(draw.field('Material', 'alphaCutoff', 1).single, .5);
    if (draw.path == 'point') {
      expect(draw.field('PointDepth', 'tile', 4)[2], inInclusiveRange(0, 5));
    }
  }
  expect(fixture.device.colorContexts.map((draw) => draw.instance), [
    'instance-0',
    'instance-1',
    'instance-2',
  ]);
  expect(
    fixture.device.colorContexts.map((draw) => draw.shadow),
    blended
        ? ['shadow-0', 'shadow-1', 'outer-shadow']
        : ['shadow-0', 'shadow-1', 'shadow-2'],
  );
  for (final draw in fixture.device.colorContexts) {
    final index = int.parse(draw.instance!.substring(9));
    _expectMatrix(draw.model, _model(index));
    _expectMatrix(draw.joint, _joint(index));
  }
}

void _expectRestored(_Fixture fixture) {
  _expectMatrix(fixture.context.model.storage, fixture.outerModel);
  expect(fixture.context.jointsInfo.jointTransforms, same(fixture.outerJoints));
  expect(fixture.context.sourceInstanceId, 'outer-instance');
  expect(fixture.context.sourceShadowId, 'outer-shadow');
  for (final surface in fixture.surfaces) {
    expect(surface.material, same(fixture.restingSurfaceMaterial));
  }
  for (final material in fixture.materials.toSet()) {
    expect(material.albedoColor, const Color(0xffaabbcc));
    expect(material.albedoTexture, same(fixture.restingTexture));
    expect(material.cullMode, CullMode.none);
    if (material is SpatialPixelMaterial) {
      _expectVector(material.uvRect.storage, [0, 0, 1, 1]);
      _expectVector(material.uvTransformU.storage, [1, 0, .75, 0]);
      _expectVector(material.uvTransformV.storage, [0, 1, .5, 0]);
      expect(material.activeWrapS, 33071);
      expect(material.activeWrapT, 10497);
      expect(material.shadowSamplePosition!.storage, [7, 8, 9]);
    }
  }
}

void _expectMatrix(List<double> actual, Matrix4 expected) =>
    _expectVector(actual, expected.storage);

void _expectVector(List<double> actual, List<double> expected) {
  expect(actual, hasLength(expected.length));
  for (var index = 0; index < expected.length; index++) {
    expect(actual[index], closeTo(expected[index], .000001));
  }
}

Matrix4 _model(int index) =>
    Matrix4.translationValues(-2 + index * 2, 0, -2 - index * 2);
Matrix4 _joint(int index) =>
    Matrix4.translationValues(index + 1, index + 2, index + 3);
List<double> _color(int index) => [(.2 + index * .2), .4, .6, .8];
CullMode _cull(int index) =>
    [CullMode.backFace, CullMode.none, CullMode.frontFace][index];

class _Fixture {
  _Fixture(int flags, {bool mixedAlpha = false, bool filterCasters = false}) {
    device = _Device(backend)..renderSize = const Size(64, 64);
    context = _Context(device)
      ..setCamera(Matrix4.identity(), Matrix4.identity());
    device.context = context;
    context
      ..shadowAntialiasingEnabled = false
      ..lighting = SpatialLightingProfile.stylized(
        surfaceStrength: 0,
        shadow: flags == 0 || flags & 2 != 0
            ? SpatialShadowProfile(
                casterInstanceIds: flags == 0
                    ? {}
                    : filterCasters
                    ? {'shadow-0'}
                    : {'shadow-0', 'instance-1', 'shadow-2'},
                center: (x: 1, y: 0, z: -2),
                extent: 32,
                depth: 64,
                resolution: 64,
              )
            : null,
        pointShadowCasterInstanceIds: flags & 4 == 0
            ? {}
            : filterCasters
            ? {'shadow-1'}
            : {'instance-0', 'shadow-1', 'instance-2'},
        pointLights: flags & 4 == 0
            ? []
            : [SpatialPointLight(position: (x: 0, y: 3, z: -4), radius: 20)],
      );
    final shared = SpatialPixelMaterial(
      restingTexture,
      alphaMode: Model3dAlphaMode.opaque,
      alphaCutoff: .5,
    );
    materials = [
      for (var index = 0; index < 3; index++)
        if (mixedAlpha)
          SpatialPixelMaterial(
            restingTexture,
            alphaMode: Model3dAlphaMode.values[index],
            alphaCutoff: .5,
          )
        else
          shared,
    ];
    surfaces = [
      for (var index = 0; index < 3; index++)
        _Surface('pose-$index', materials[index]),
    ];
  }

  final backend = _Backend();
  final restingTexture = Texture(ByteData(4), width: 1, height: 1);
  final textures = [
    for (var index = 0; index < 3; index++)
      Texture(ByteData(4), width: 1, height: 1),
  ];
  final restingSurfaceMaterial = UnlitMaterial();
  final outerModel = Matrix4.translationValues(11, 12, 13);
  final outerJoints = [Matrix4.translationValues(21, 22, 23)];
  late final _Device device;
  late final _Context context;
  late final List<UnlitMaterial> materials;
  late final List<_Surface> surfaces;

  void render({bool submit = true}) {
    device.begin();
    device.beginPass(const Size(64, 64));
    try {
      if (submit) context.submitDraw(_Object(_capture), Matrix4.identity());
      context.flush();
    } finally {
      device.end();
    }
  }

  void _capture() {
    try {
      for (var index = 0; index < 3; index++) {
        context.model.setFrom(_model(index));
        context.jointsInfo.jointTransforms = [_joint(index)];
        context
          ..sourceInstanceId = 'instance-$index'
          ..sourceShadowId = 'shadow-$index';
        final channels = _color(index);
        final material = materials[index]
          ..albedoTexture = textures[index]
          ..albedoColor = Color.from(
            alpha: channels[3],
            red: channels[0],
            green: channels[1],
            blue: channels[2],
          )
          ..cullMode = _cull(index);
        if (material is SpatialPixelMaterial) {
          material
            ..uvRect.setValues(.1 * index, .2, .7, .8)
            ..shadowSamplePosition = Vector3(index.toDouble(), 1, 2)
            ..applyAnimation(
              [
                2 + index.toDouble(),
                0,
                0,
                3 + index.toDouble(),
                .125 * index,
                .25 * index,
              ],
              texture: textures[index],
              wrapModes: (wrapS: 33648, wrapT: 33071),
            );
        }
        surfaces[index].material = material;
        context.drawSurface(surfaces[index]);
      }
    } finally {
      context.model.setFrom(outerModel);
      context.jointsInfo.jointTransforms = outerJoints;
      context
        ..sourceInstanceId = 'outer-instance'
        ..sourceShadowId = 'outer-shadow';
      for (final surface in surfaces) {
        surface.material = restingSurfaceMaterial;
      }
      for (final material in materials.toSet()) {
        material
          ..albedoTexture = restingTexture
          ..albedoColor = const Color(0xffaabbcc)
          ..cullMode = CullMode.none;
        if (material is SpatialPixelMaterial) {
          material
            ..uvRect.setValues(0, 0, 1, 1)
            ..shadowSamplePosition = Vector3(7, 8, 9)
            ..applyAnimation(
              [1, 0, 0, 1, .75, .5],
              texture: restingTexture,
              wrapModes: (wrapS: 33071, wrapT: 10497),
            );
        }
      }
    }
  }
}

class _Context extends SpatialRenderContext {
  _Context(super.device);
  final countedModel = _CountingMatrix();
  @override
  Matrix4 get model => countedModel;
}

class _CountingMatrix extends Matrix4 {
  _CountingMatrix() : super.zero();
  int clones = 0, copies = 0;
  @override
  Matrix4 clone() {
    clones++;
    return super.clone();
  }

  @override
  void setFrom(Matrix4 other) {
    copies++;
    super.setFrom(other);
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

class _Device extends FlutterFrameGraphicsDevice {
  _Device(GpuBackend backend) : super(backend: backend);
  late _Context context;
  final colorContexts =
      <
        ({
          String? instance,
          String? shadow,
          List<double> model,
          List<double> joint,
        })
      >[];
  @override
  void bindGeometry(Surface surface) {
    colorContexts.add((
      instance: context.sourceInstanceId,
      shadow: context.sourceShadowId,
      model: context.model.storage.toList(),
      joint: context.jointsInfo.jointTransforms.isEmpty
          ? Matrix4.identity().storage.toList()
          : context.jointsInfo.jointTransforms.single.storage.toList(),
    ));
    super.bindGeometry(surface);
  }
}

final class _Backend extends GpuBackend {
  final draws = <_Draw>[];
  final slots = <String, _Slot>{};
  String? failure;
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
  GpuShaderLibrary loadShaderLibrary(String assetName) => _Library(this);
  @override
  GpuPipeline createPipeline({
    required GpuShader vertexShader,
    required GpuShader fragmentShader,
  }) => _Pipeline((fragmentShader as _Shader).entry);
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

class _Draw {
  _Draw(
    this.backend,
    this.name,
    this.path,
    this.cull,
    this.uniforms,
    this.texture,
  );
  final _Backend backend;
  final String name, path;
  final CullMode cull;
  final Map<String, List<double>> uniforms;
  final GpuTexture? texture;
  List<double> field(String slot, String member, int count) {
    final offset = backend.slots[slot]!.members.indexOf(member) * 16;
    return uniforms[slot]!.sublist(offset, offset + count);
  }
}

class _Frame implements GpuFrame {
  _Frame(this.backend);
  final _Backend backend;
  @override
  GpuRenderPass beginRenderPass(
    GpuRenderTarget target, {
    required BlendState blend,
    required DepthStencilState depthStencil,
  }) => _Pass(backend);
  @override
  void end() {}
}

class _Pass implements GpuRenderPass {
  _Pass(this.backend);
  final _Backend backend;
  final uniforms = <String, List<double>>{};
  String path = '', name = '';
  CullMode cull = CullMode.none;
  GpuTexture? texture;
  @override
  void bindPipeline(GpuPipeline pipeline, CullMode cullMode) {
    final entry = (pipeline as _Pipeline).entry;
    path = entry == 'ShadowDepthFragment'
        ? 'shadow'
        : entry == 'PointShadowDepthFragment'
        ? 'point'
        : 'color';
    cull = cullMode;
    if (path != 'color' && backend.failure == 'pipeline')
      throw StateError('pipeline failed');
  }

  @override
  void bindUniform(GpuUniformSlot slot, ByteData data) =>
      uniforms[(slot as _Slot).name] = data.buffer
          .asFloat32List(data.offsetInBytes, data.lengthInBytes ~/ 4)
          .toList();
  @override
  void bindTexture(GpuUniformSlot slot, GpuTexture value) {
    if ((slot as _Slot).name == 'albedoTexture') texture = value;
  }

  @override
  void bindVertexBuffer(GpuBufferView view, int vertexCount) {
    name = (view.buffer as _Buffer).name;
    if (path != 'color' && backend.failure == 'geometry')
      throw StateError('geometry failed');
  }

  @override
  void bindIndexBuffer(
    GpuBufferView view,
    GpuIndexType indexType,
    int indexCount,
  ) {}
  @override
  void clearBindings() {
    uniforms.clear();
    texture = null;
  }

  @override
  void draw() => backend.draws.add(
    _Draw(backend, name, path, cull, Map.of(uniforms), texture),
  );
  @override
  void submit() {}
}

class _Library implements GpuShaderLibrary {
  _Library(this.backend);
  final _Backend backend;
  @override
  GpuShader operator [](String entryPoint) => _Shader(backend, entryPoint);
}

class _Shader implements GpuShader {
  _Shader(this.backend, this.entry);
  final _Backend backend;
  final String entry;
  @override
  GpuUniformSlot getUniformSlot(String slot) =>
      backend.slots.putIfAbsent(slot, () => _Slot(slot));
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

class _Pipeline implements GpuPipeline {
  _Pipeline(this.entry);
  final String entry;
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
