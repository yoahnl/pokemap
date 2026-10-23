import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flame_3d/components.dart';
import 'package:flame_3d/game.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_pixel_material.dart';
import 'package:map_render_3d/src/spatial_render_context.dart';

void main() {
  test('a house shadow darkens its ground instead of hiding the ground', () {
    final harness = _Harness();
    final shadow = _surface(
      'shadow',
      _material(
        Model3dAlphaMode.blend,
        const Color(0x00000000).withValues(alpha: 9 / 31),
      ),
      depth: .2,
      localZ: 9.8,
    );
    final wall = _surface(
      'wall',
      _material(Model3dAlphaMode.opaque, const Color(0xffaa0000)),
      depth: .9,
    );
    final ground = _surface(
      'ground',
      _material(Model3dAlphaMode.opaque, const Color(0xff40c080)),
      depth: .6,
    );
    harness.submit(-10, (context) {
      context.model.setFrom(Matrix4.translationValues(0, 0, -10));
      context.drawSurface(shadow);
      context.drawSurface(wall);
    });
    harness.submit(-1, (context) {
      context.model.setFrom(Matrix4.translationValues(0, 0, -1));
      context.drawSurface(ground);
    });

    harness.context.flush();

    expect(harness.device.names, ['wall', 'ground', 'shadow']);
    final factor = 1 - 9 / 31;
    expect(harness.device.pixel[0], closeTo(64 / 255 * factor, 1e-7));
    expect(harness.device.pixel[1], closeTo(192 / 255 * factor, 1e-7));
    expect(harness.device.pixel[2], closeTo(128 / 255 * factor, 1e-7));
    expect(harness.device.pixel[3], closeTo(1, 1e-7));
  });

  test('transparent surfaces within one object compose from far to near', () {
    final harness = _Harness();
    final ground = _surface(
      'ground',
      _material(Model3dAlphaMode.opaque, const Color(0xff00ff00)),
      depth: .9,
      localZ: -20,
    );
    final near = _surface(
      'near',
      _material(
        Model3dAlphaMode.blend,
        const Color(0xff0000ff).withValues(alpha: .5),
      ),
      depth: .2,
      localZ: -1,
    );
    final far = _surface(
      'far',
      _material(
        Model3dAlphaMode.blend,
        const Color(0xffff0000).withValues(alpha: .5),
      ),
      depth: .7,
      localZ: -10,
    );
    harness.submit(-1, (context) {
      context.model.setIdentity();
      context.drawSurface(near);
      context.drawSurface(far);
      context.drawSurface(ground);
    });

    harness.context.flush();

    expect(harness.device.names, ['ground', 'far', 'near']);
    expect(harness.device.pixel[0], closeTo(.25, 1e-7));
    expect(harness.device.pixel[1], closeTo(.25, 1e-7));
    expect(harness.device.pixel[2], closeTo(.5, 1e-7));
    expect(harness.device.pixel[3], closeTo(1, 1e-7));
  });

  test('a turned camera sorts translucency by view depth', () {
    final harness = _Harness();
    harness.context.setCamera(Matrix4.rotationY(math.pi), Matrix4.identity());
    final ground = _surface(
      'ground',
      _material(Model3dAlphaMode.opaque, const Color(0xff00ff00)),
      depth: .9,
      localZ: 20,
    );
    final near = _surface(
      'near',
      _material(
        Model3dAlphaMode.blend,
        const Color(0xff0000ff).withValues(alpha: .5),
      ),
      depth: .2,
      localZ: 1,
    );
    final far = _surface(
      'far',
      _material(
        Model3dAlphaMode.blend,
        const Color(0xffff0000).withValues(alpha: .5),
      ),
      depth: .7,
      localZ: 10,
    );
    harness.submit(1, (context) {
      context.model.setIdentity();
      context.drawSurface(near);
      context.drawSurface(far);
      context.drawSurface(ground);
    });

    harness.context.flush();

    expect(harness.device.names, ['ground', 'far', 'near']);
    expect(harness.device.pixel[0], closeTo(.25, 1e-7));
    expect(harness.device.pixel[1], closeTo(.25, 1e-7));
    expect(harness.device.pixel[2], closeTo(.5, 1e-7));
    expect(harness.device.pixel[3], closeTo(1, 1e-7));
  });

  test('opaque mask and legacy actor materials retain immediate ordering', () {
    final harness = _Harness();
    final shadow = _surface(
      'shadow',
      _material(Model3dAlphaMode.blend, const Color(0x80000000)),
      depth: .2,
    );
    final opaque = _surface(
      'opaque',
      _material(Model3dAlphaMode.opaque, const Color(0xffffffff)),
      depth: .8,
    );
    final mask = _surface(
      'mask',
      _material(Model3dAlphaMode.mask, const Color(0x33ffffff)),
      depth: .7,
    );
    final actor = _surface(
      'legacy-actor',
      _material(null, const Color(0xffffffff)),
      depth: .6,
    );
    harness.submit(-1, (context) {
      context.model.setIdentity();
      for (final surface in [shadow, opaque, mask, actor]) {
        context.drawSurface(surface);
      }
    });

    harness.context.flush();

    expect(harness.device.names, ['opaque', 'mask', 'legacy-actor', 'shadow']);
    expect(harness.device.snapshots.map((value) => value.alphaMode), [
      Model3dAlphaMode.opaque,
      Model3dAlphaMode.mask,
      null,
      Model3dAlphaMode.blend,
    ]);
  });

  test('an opaque wall still occludes transparent geometry behind it', () {
    final harness = _Harness();
    final wall = _surface(
      'wall',
      _material(Model3dAlphaMode.opaque, const Color(0xffcc8800)),
      depth: .2,
      localZ: -1,
    );
    final shadow = _surface(
      'behind',
      _material(
        Model3dAlphaMode.blend,
        const Color(0xff0000ff).withValues(alpha: .7),
      ),
      depth: .7,
      localZ: -10,
    );
    harness.submit(-10, (context) {
      context.model.setIdentity();
      context.drawSurface(shadow);
    });
    harness.submit(-1, (context) {
      context.model.setIdentity();
      context.drawSurface(wall);
    });

    harness.context.flush();

    expect(harness.device.pixel, [204 / 255, 136 / 255, 0, 1]);
  });

  test('shared animated materials retain the state of each submitted pose', () {
    final harness = _Harness();
    final material = _material(
      Model3dAlphaMode.blend,
      const Color(0xffff0000).withValues(alpha: .4),
    );
    final firstTexture = Texture(ByteData(4), width: 1, height: 1);
    final secondTexture = Texture(ByteData(4), width: 1, height: 1);
    final joint = Matrix4.translationValues(1, 2, 3);
    final first = _surface('first-pose', material, depth: .8);
    final second = _surface('second-pose', material, depth: .2);
    harness.submit(-1, (context) {
      context.model.setFrom(Matrix4.translationValues(0, 0, -10));
      context.jointsInfo.jointTransforms = [joint];
      material
        ..uvRect.setValues(.1, .2, .3, .4)
        ..cullMode = CullMode.frontFace
        ..applyAnimation(
          [2, 0, 0, 3, .125, .25],
          texture: firstTexture,
          wrapModes: (wrapS: 33648, wrapT: 33071),
        );
      context.drawSurface(first);
      joint.setTranslationRaw(7, 8, 9);
      context.model.setFrom(Matrix4.translationValues(0, 0, -1));
      material
        ..albedoColor = const Color(0xff0000ff).withValues(alpha: .7)
        ..uvRect.setValues(.5, .6, .7, .8)
        ..cullMode = CullMode.backFace
        ..applyAnimation(
          [4, 0, 0, 5, .375, .5],
          texture: secondTexture,
          wrapModes: (wrapS: 10497, wrapT: 10497),
        );
      context.drawSurface(second);
    });

    harness.context.flush();

    final poses = harness.device.snapshots;
    expect(poses.map((value) => value.name), ['first-pose', 'second-pose']);
    expect(poses[0].model, Matrix4.translationValues(0, 0, -10).storage);
    expect(poses[1].model, Matrix4.translationValues(0, 0, -1).storage);
    expect(poses[0].joints.single, Matrix4.translationValues(1, 2, 3).storage);
    expect(poses[1].joints.single, Matrix4.translationValues(7, 8, 9).storage);
    expect(poses[0].color, const Color(0xffff0000).withValues(alpha: .4));
    expect(poses[1].color, const Color(0xff0000ff).withValues(alpha: .7));
    expect(poses[0].texture, same(firstTexture));
    expect(poses[1].texture, same(secondTexture));
    _expectVector(poses[0].uvRect, [.1, .2, .3, .4]);
    _expectVector(poses[1].uvRect, [.5, .6, .7, .8]);
    expect(poses[0].uvU, [2, 0, .125, 0]);
    expect(poses[1].uvU, [4, 0, .375, 0]);
    expect(poses[0].uvV, [0, 3, .25, 0]);
    expect(poses[1].uvV, [0, 5, .5, 0]);
    expect(poses[0].wrap, (33648, 33071));
    expect(poses[1].wrap, (10497, 10497));
    expect(poses[0].cull, CullMode.frontFace);
    expect(poses[1].cull, CullMode.backFace);
    expect(material.albedoTexture, same(secondTexture));
    expect(material.albedoColor, const Color(0xff0000ff).withValues(alpha: .7));
    expect(
      harness.context.model.storage,
      Matrix4.translationValues(0, 0, -1).storage,
    );
    expect(
      harness.context.jointsInfo.jointTransforms.single.storage,
      Matrix4.translationValues(7, 8, 9).storage,
    );
  });

  test('equal-depth translucent surfaces retain submission order', () {
    final harness = _Harness();
    final material = _material(Model3dAlphaMode.blend, const Color(0x80000000));
    harness.submit(-1, (context) {
      context.model.setIdentity();
      for (final name in ['first', 'second', 'third']) {
        context.drawSurface(_surface(name, material, depth: .5));
      }
    });

    harness.context.flush();

    expect(harness.device.names, ['first', 'second', 'third']);
  });

  test('shared surfaces retain poses reset by each object before replay', () {
    final harness = _Harness();
    final material = _material(Model3dAlphaMode.blend, const Color(0xffffffff));
    final restingTexture = material.albedoTexture;
    final firstTexture = Texture(ByteData(4), width: 1, height: 1);
    final secondTexture = Texture(ByteData(4), width: 1, height: 1);
    final shared = _surface('shared', material, depth: .5);

    void submitPose(double z, Color color, Texture texture, double offset) {
      harness.submit(z, (context) {
        context.model.setFrom(Matrix4.translationValues(0, 0, z));
        try {
          material
            ..albedoColor = color
            ..cullMode = CullMode.frontFace
            ..applyAnimation([1, 0, 0, 1, offset, 0], texture: texture);
          context.drawSurface(shared);
        } finally {
          material
            ..resetAnimation()
            ..albedoColor = const Color(0xffffffff)
            ..cullMode = CullMode.none;
        }
      });
    }

    final red = const Color(0xffff0000).withValues(alpha: .4);
    final blue = const Color(0xff0000ff).withValues(alpha: .7);
    submitPose(-10, red, firstTexture, .125);
    submitPose(-1, blue, secondTexture, .375);

    harness.context.flush();

    final poses = harness.device.snapshots;
    expect(poses, hasLength(2));
    expect(poses[0].color, red);
    expect(poses[1].color, blue);
    expect(poses[0].texture, same(firstTexture));
    expect(poses[1].texture, same(secondTexture));
    expect(poses[0].uvU, [1, 0, .125, 0]);
    expect(poses[1].uvU, [1, 0, .375, 0]);
    expect(poses[0].model, Matrix4.translationValues(0, 0, -10).storage);
    expect(poses[1].model, Matrix4.translationValues(0, 0, -1).storage);
    expect(poses.map((value) => value.cull), everyElement(CullMode.frontFace));
    expect(shared.material, same(material));
    expect(material.albedoTexture, same(restingTexture));
    expect(material.albedoColor, const Color(0xffffffff));
    expect(material.uvTransformU.storage, [1, 0, 0, 0]);
    expect(material.cullMode, CullMode.none);
  });

  test(
    'a failed translucent draw restores state and clears the next frame',
    () {
      final harness = _Harness();
      final material = _material(
        Model3dAlphaMode.blend,
        const Color(0x80000000),
      );
      harness.device.failNextName = 'abandoned';
      harness.submit(-1, (context) {
        context.model.setFrom(Matrix4.translationValues(0, 0, -10));
        try {
          context.drawSurface(_surface('abandoned', material, depth: .5));
        } finally {
          context.model.setFrom(Matrix4.translationValues(0, 0, -1));
          material.albedoColor = const Color(0x800000ff);
        }
      });

      expect(harness.context.flush, throwsStateError);
      expect(material.albedoColor, const Color(0x800000ff));
      expect(
        harness.context.model.storage,
        Matrix4.translationValues(0, 0, -1).storage,
      );
      harness.device.snapshots.clear();
      expect(harness.context.flush, returnsNormally);
      expect(harness.device.snapshots, isEmpty);
    },
  );
}

void _expectVector(List<double> actual, List<double> expected) {
  expect(actual, hasLength(expected.length));
  for (var i = 0; i < expected.length; i++) {
    expect(actual[i], closeTo(expected[i], 1e-6));
  }
}

_ProbeMaterial _material(Model3dAlphaMode? mode, Color color) =>
    _ProbeMaterial(mode)..albedoColor = color;

_ProbeSurface _surface(
  String name,
  _ProbeMaterial material, {
  required double depth,
  double localZ = 0,
}) => _ProbeSurface(name, material, depth, localZ);

class _Harness {
  _Harness() {
    context = SpatialRenderContext(device);
    context.setCamera(Matrix4.identity(), Matrix4.identity());
    device.context = context;
  }

  final device = _PixelDevice();
  late final RenderContext3D context;

  void submit(double originZ, void Function(RenderContext3D) draw) => context
      .submitDraw(_DrawObject(draw), Matrix4.translationValues(0, 0, originZ));
}

class _DrawObject extends Object3D {
  _DrawObject(this.drawContents);
  final void Function(RenderContext3D) drawContents;

  @override
  void draw(RenderContext context) => drawContents(context as RenderContext3D);
}

class _ProbeSurface extends Surface {
  _ProbeSurface(this.name, _ProbeMaterial material, this.depth, double z)
    : super(
        vertices: [
          Vertex(position: Vector3(-1, 0, z), texCoord: Vector2.zero()),
          Vertex(position: Vector3(1, 0, z), texCoord: Vector2.zero()),
          Vertex(position: Vector3(0, 1, z), texCoord: Vector2.zero()),
        ],
        indices: [0, 1, 2],
        material: material,
      );

  final String name;
  final double depth;
}

class _Snapshot {
  _Snapshot(_ProbeSurface surface, RenderContext3D context)
    : name = surface.name,
      model = context.model.storage.toList(),
      joints = [
        for (final joint in context.jointsInfo.jointTransforms)
          joint.storage.toList(),
      ],
      color = (surface.material as SpatialPixelMaterial).albedoColor,
      texture = (surface.material as SpatialPixelMaterial).albedoTexture,
      uvRect = (surface.material as SpatialPixelMaterial).uvRect.storage
          .toList(),
      uvU = (surface.material as SpatialPixelMaterial).uvTransformU.storage
          .toList(),
      uvV = (surface.material as SpatialPixelMaterial).uvTransformV.storage
          .toList(),
      wrap = (
        (surface.material as SpatialPixelMaterial).activeWrapS,
        (surface.material as SpatialPixelMaterial).activeWrapT,
      ),
      alphaMode = (surface.material as SpatialPixelMaterial).alphaMode,
      cull = surface.material.cullMode;

  final String name;
  final List<double> model;
  final List<List<double>> joints;
  final Color color;
  final Texture texture;
  final List<double> uvRect, uvU, uvV;
  final (int, int) wrap;
  final Model3dAlphaMode? alphaMode;
  final CullMode cull;
}

class _PixelDevice extends GraphicsDevice {
  _PixelDevice() : super(backend: _UnusedBackend());
  late final RenderContext3D context;
  final snapshots = <_Snapshot>[];
  List<String> get names => snapshots.map((value) => value.name).toList();
  final pixel = <double>[0, 0, 0, 0];
  double depth = double.infinity;
  String? failNextName;

  @override
  void clearBindings() {}

  @override
  void bindPipeline(GpuPipeline pipeline, CullMode cullMode) {}

  @override
  void bindGeometry(Surface surface) {
    final probe = surface as _ProbeSurface;
    final state = _Snapshot(probe, context);
    snapshots.add(state);
    if (failNextName == probe.name) {
      failNextName = null;
      throw StateError('draw failed');
    }
    if (probe.depth >= depth) return;
    final alpha = state.alphaMode == Model3dAlphaMode.opaque
        ? 1.0
        : state.color.a;
    if (state.alphaMode == Model3dAlphaMode.mask && alpha < .5) return;
    final channels = [state.color.r, state.color.g, state.color.b];
    for (var i = 0; i < 3; i++) {
      pixel[i] = channels[i] * alpha + pixel[i] * (1 - alpha);
    }
    pixel[3] = alpha + pixel[3] * (1 - alpha);
    depth = probe.depth;
  }
}

class _ProbeMaterial extends SpatialPixelMaterial {
  _ProbeMaterial(Model3dAlphaMode? mode)
    : super(
        Texture(ByteData(4), width: 1, height: 1),
        alphaMode: mode,
        alphaCutoff: .5,
      );
  final _pipeline = _UnusedPipeline();
  final _vertex = _NoOpVertexShader();
  final _fragment = _NoOpFragmentShader();

  @override
  GpuPipeline get resource => _pipeline;

  @override
  VertexShader get vertexShader => _vertex;

  @override
  FragmentShader get fragmentShader => _fragment;

  @override
  void apply(covariant RenderContext3D context) {}
}

class _NoOpVertexShader extends VertexShader {
  _NoOpVertexShader() : super.fromAsset('unused');
  @override
  void bind(GraphicsDevice device) {}
}

class _NoOpFragmentShader extends FragmentShader {
  _NoOpFragmentShader() : super.fromAsset('unused');
  @override
  void bind(GraphicsDevice device) {}
}

class _UnusedPipeline implements GpuPipeline {}

final class _UnusedBackend extends GpuBackend {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}
