import 'dart:typed_data';
import 'dart:ui' hide FragmentShader;

import 'package:flame_3d/components.dart';
import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/model.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart' show SizedBox;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/flutter_frame_graphics_device.dart';
import 'package:map_render_3d/src/glb_renderer_layout.dart';
import 'package:map_render_3d/src/spatial_depth_of_field.dart';
import 'package:map_render_3d/src/spatial_model_source_admission.dart';
import 'package:map_render_3d/src/spatial_lighting_preview.dart';
import 'package:map_render_3d/src/spatial_point_light.dart';
import 'package:map_render_3d/src/spatial_shadow_profile.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';
import 'package:map_render_3d/src/spatial_pixel_material.dart';
import 'package:map_render_3d/src/spatial_render_context.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'prepared repeated static surfaces reduce real depth draws only',
    () async {
      final fixture = _Fixture(shadows: true);
      fixture.render();
      final before = fixture.drawCounts;
      fixture.clearDraws();
      await fixture.prepare();
      fixture.render();
      expect(before, {'depth': 3, 'shadow': 3, 'point': 4, 'color': 3});
      expect(fixture.drawCounts, {
        'depth': 1,
        'shadow': 3,
        'point': 4,
        'color': 3,
      });
      expect(fixture.device.colorOwners, fixture.owners);
      expect(fixture.device.colorInstanceIds, List.filled(3, 'same-id'));
      expect(fixture.device.colorShadowIds, [
        'map-0/same-id',
        'map-1/same-id',
        'map-2/same-id',
      ]);
      expect(fixture.context.sourceModelOwner, same(fixture.outerOwner));
      expect(fixture.context.model.storage, fixture.outerTransform.storage);
    },
  );

  test(
    'baked depth positions match shader float32 translation and attributes',
    () async {
      final fixture = _Fixture();
      fixture.transforms[0].setTranslationRaw(
        .33333334,
        .123456789,
        -1.23456789,
      );
      fixture.transforms[1].setTranslationRaw(1.7654321, 2.3456789, -2.1234567);
      fixture.transforms[2].setTranslationRaw(
        2.4567891,
        3.4567891,
        -3.33333334,
      );
      await fixture.prepare();
      fixture.render();
      final draw = fixture.depthDraws.single;
      expect(draw.vertexCount, 9);
      expect(draw.indexCount, 9);
      expect(draw.field('VertexInfo', 'model', 16), Matrix4.identity().storage);
      final floats = draw.geometry.buffer.asFloat32List(
        draw.geometry.offsetInBytes,
        9 * 20,
      );
      final original = fixture.colorDraws.first.geometry.buffer.asFloat32List(
        0,
        3 * 20,
      );
      for (var owner = 0; owner < 3; owner++) {
        for (var vertex = 0; vertex < 3; vertex++) {
          for (var axis = 0; axis < 3; axis++) {
            final expected = _float32(
              original[vertex * 20 + axis] +
                  _float32(fixture.transforms[owner].storage[12 + axis]),
            );
            expect(
              _float32Bits(floats[(owner * 3 + vertex) * 20 + axis]),
              _float32Bits(expected),
            );
          }
          expect(
            floats.sublist(
              (owner * 3 + vertex) * 20 + 3,
              (owner * 3 + vertex + 1) * 20,
            ),
            original.sublist(vertex * 20 + 3, (vertex + 1) * 20),
          );
        }
      }
      final indices = draw.geometry.buffer.asUint16List(9 * 80, 9);
      expect(indices, [0, 1, 2, 3, 4, 5, 6, 7, 8]);
      expect(draw.texture, same(fixture.material.albedoTexture.resource));
      expect(draw.field('Material', 'alphaMode', 1).single, 2);
      expect(draw.field('Material', 'alphaCutoff', 1).single, .5);
      expect(draw.field('Material', 'wrapModes', 2), [10497, 10497]);
    },
  );

  test(
    'two static GLB primitives share owners and batch independently',
    () async {
      final fixture = _Fixture();
      final second = SpatialModelSurface(
        vertices: [
          Vertex(
            position: Vector3(0, 0, .1),
            texCoord: Vector2.zero(),
            normal: Vector3(0, 0, 1),
          ),
          Vertex(
            position: Vector3(.5, 0, .1),
            texCoord: Vector2(1, 0),
            normal: Vector3(0, 0, 1),
          ),
          Vertex(
            position: Vector3(0, 1, .1),
            texCoord: Vector2(0, 1),
            normal: Vector3(0, 0, 1),
          ),
        ],
        indices: [0, 1, 2],
        material: SpatialPixelMaterial(
          fixture.texture,
          alphaMode: Model3dAlphaMode.mask,
          alphaCutoff: .5,
        ),
      );
      fixture.model.nodes.values.single.mesh!.addSurface(second);
      await fixture.prepare();
      fixture.render(allSurfaces: true);
      expect(fixture.registry.batchCount, 2);
      expect(fixture.depthDraws.map((draw) => draw.vertexCount), [9, 9]);
      expect(
        fixture.colorDraws.map((draw) => draw.vertexCount),
        List.filled(6, 3),
      );
    },
  );

  test(
    'missing and duplicate members replay only present original captures',
    () async {
      final fixture = _Fixture();
      await fixture.prepare();
      fixture.render(indices: [0, 2]);
      expect(fixture.depthDraws.map((draw) => draw.vertexCount), [3, 3]);
      expect(fixture.registry.batchCount, 1);
      fixture.clearDraws();
      fixture.render(indices: [0, 1, 1, 2]);
      expect(fixture.depthDraws.map((draw) => draw.vertexCount), [3, 3, 3, 3]);
      expect(fixture.registry.batchCount, 1);
      fixture.clearDraws();
      fixture.render();
      expect(fixture.depthDraws.single.vertexCount, 9);
    },
  );

  for (final mismatch in [
    'transform',
    'texture',
    'color',
    'uvRect',
    'uvTransform',
    'wrap',
    'cull',
    'joints',
    'source',
    'surfaceMaterial',
    'captureMaterial',
  ]) {
    test(
      '$mismatch mismatch uses originals and invalidates the local batch',
      () async {
        final fixture = _Fixture(count: 6);
        for (var index = 3; index < 6; index++) {
          fixture.transforms[index].setTranslationRaw(index + 8, 0, -2);
        }
        await fixture.prepare();
        expect(fixture.registry.batchCount, 2);
        final originalMaterial = fixture.surface.material;
        fixture.render(
          beforeCapture: (index) {
            if (index != 0) return;
            switch (mismatch) {
              case 'transform':
                fixture.context.model.translateByDouble(.1, 0, 0, 1);
              case 'texture':
                fixture.material.albedoTexture = Texture(
                  ByteData(4),
                  width: 1,
                  height: 1,
                );
              case 'color':
                fixture.material.albedoColor = const Color(0x80ffffff);
              case 'uvRect':
                fixture.material.uvRect.x = .25;
              case 'uvTransform':
                fixture.material.uvTransformU.z = .25;
              case 'wrap':
                fixture.material.applyAnimation(
                  [1, 0, 0, 1, 0, 0],
                  wrapModes: (wrapS: 33071, wrapT: 10497),
                );
              case 'cull':
                fixture.material.cullMode = CullMode.none;
              case 'joints':
                fixture.context.jointsInfo.jointTransforms = [
                  Matrix4.identity(),
                ];
              case 'source':
                fixture.current[0] = false;
              case 'surfaceMaterial':
                fixture.surface.material = SpatialPixelMaterial(
                  fixture.material.albedoTexture,
                );
              case 'captureMaterial':
                fixture.surface.material = SpatialPixelMaterial(
                  fixture.material.albedoTexture,
                );
            }
          },
          afterCapture: (index) {
            if (index != 0) return;
            fixture.surface.material = originalMaterial;
            fixture.material
              ..albedoTexture = fixture.texture
              ..albedoColor = const Color(0xffffffff)
              ..cullMode = CullMode.backFace
              ..resetAnimation();
            fixture.material.uvRect.setValues(0, 0, 1, 1);
          },
        );
        expect(fixture.depthDraws.map((draw) => draw.vertexCount), [
          3,
          3,
          3,
          9,
        ]);
        expect(fixture.registry.batchCount, 1);
      },
    );
  }

  for (final rejected in [
    'scale',
    'rotation',
    'perspective',
    'nonfinite',
    'blend',
    'normal',
    'animation',
    'skin',
    'morph',
    'materialAnimation',
    'unqualified',
    'nodeTransform',
    'multipleNodes',
    'duplicateSurface',
  ]) {
    test('$rejected sources stay on individual depth draws', () async {
      final fixture = _Fixture(
        normals: rejected != 'normal',
        blend: rejected == 'blend',
      );
      final document = <String, dynamic>{};
      switch (rejected) {
        case 'scale':
          for (final transform in fixture.transforms) {
            transform.scaleByDouble(2, 1, 1, 1);
          }
        case 'rotation':
          for (final transform in fixture.transforms) {
            transform.rotateY(.1);
          }
        case 'perspective':
          for (final transform in fixture.transforms) {
            transform.storage[3] = .001;
          }
        case 'nonfinite':
          for (final transform in fixture.transforms) {
            transform.storage[12] = double.infinity;
          }
        case 'animation':
          document['animations'] = [{}];
        case 'skin':
          document['skins'] = [{}];
        case 'morph':
          document['meshes'] = [
            {
              'weights': [1],
            },
          ];
        case 'nodeTransform':
          fixture.model.nodes.values.single.transform.translateByDouble(
            1,
            0,
            0,
            1,
          );
        case 'multipleNodes':
          fixture.model.nodes[1] = ModelNode.simple(nodeIndex: 1, mesh: null);
        case 'duplicateSurface':
          fixture.model.nodes.values.single.mesh!.addSurface(fixture.surface);
      }
      if (rejected == 'unqualified') {
        fixture.model = Model(nodes: fixture.model.nodes, animations: const []);
      } else {
        registerSpatialModelClipSource(
          fixture.model,
          document,
          hasMaterialAnimations: rejected == 'materialAnimation',
        );
      }
      await fixture.prepare();
      expect(fixture.registry.batchCount, 0);
      fixture.render();
      expect(fixture.depthDraws, hasLength(3));
    });
  }

  for (final failure in ['allocate', 'write']) {
    for (final completed in [0, 1]) {
      test(
        'optional $failure failure after $completed batches preserves original rendering and aborts remaining preparation',
        () async {
          final fixture = _Fixture(count: 300);
          for (var index = 0; index < 300; index++) {
            fixture.transforms[index].setTranslationRaw(
              (index ~/ 3) * 8 + (index % 3).toDouble(),
              0,
              -2,
            );
          }
          fixture.render(indices: [0, 1, 2]);
          expect(fixture.depthDraws, hasLength(3));
          final originalGeometry = fixture.depthDraws.first.geometry;
          final previousAttempts = fixture.backend.bufferAttempts;
          fixture.clearDraws();
          fixture.backend
            ..failure = failure
            ..failAtBuffer = previousAttempts + completed + 1;
          await fixture.prepare();
          expect(
            fixture.backend.bufferAttempts,
            previousAttempts + completed + 1,
          );
          expect(fixture.registry.batchCount, 0);
          expect(fixture.registry.retainedBytes, 0);
          expect(fixture.budget.residentBytes, 0);
          expect(fixture.budget.transientBytes, 0);
          expect(fixture.budget.activeDecodes, 0);
          expect(fixture.budget.pendingDecodes, 0);
          fixture.render(indices: [0, 1, 2]);
          expect(fixture.depthDraws, hasLength(3));
          expect(fixture.colorDraws, hasLength(3));
          expect(
            fixture.depthDraws.every(
              (draw) => identical(draw.geometry, originalGeometry),
            ),
            isTrue,
          );
          expect(
            fixture.backend.bufferAttempts,
            previousAttempts + completed + 1,
          );
        },
      );
    }
  }

  test('errors in the original geometry path still propagate', () {
    final fixture = _Fixture();
    fixture.backend.failure = 'allocate';
    expect(fixture.render, throwsStateError);
    expect(fixture.context.staticDepthBatches, isNull);
  });

  test('preparation waits for budget before allocating geometry and cancels on removal', () async {
    final fixture = _Fixture();
    final blocker = await fixture.budget.acquire();
    final pending = fixture.prepare();
    await Future<void>.delayed(Duration.zero);
    expect(fixture.budget.pendingDecodes, 1);
    expect(fixture.backend.buffers, isEmpty);
    fixture.registry.dispose();
    blocker.release();
    await pending;
    expect(fixture.registry.batchCount, 0);
    expect(fixture.budget.residentBytes, 0);
    expect(fixture.budget.transientBytes, 0);
    expect(fixture.backend.buffers, isEmpty);
  });

  test(
    'local invalidation also cancels an owner waiting for admission',
    () async {
      final fixture = _Fixture();
      final blocker = await fixture.budget.acquire();
      final pending = fixture.prepare();
      await Future<void>.delayed(Duration.zero);
      fixture.registry.invalidateOwner(fixture.owners.first);
      blocker.release();
      await pending;
      expect(fixture.registry.batchCount, 0);
      expect(fixture.budget.residentBytes, 0);
      expect(fixture.backend.buffers, isEmpty);
    },
  );

  test(
    'source changes while waiting for admission fall back without allocation',
    () async {
      final fixture = _Fixture();
      final blocker = await fixture.budget.acquire();
      final pending = fixture.prepare();
      await Future<void>.delayed(Duration.zero);
      fixture.model.nodes[1] = ModelNode.simple(nodeIndex: 1, mesh: null);
      blocker.release();
      await pending;
      expect(fixture.registry.batchCount, 0);
      expect(fixture.budget.residentBytes, 0);
      expect(fixture.backend.buffers, isEmpty);
    },
  );

  for (final mutation in ['invalidate', 'retain']) {
    test(
      '$mutation during preparation releases a published batch synchronously',
      () async {
        final fixture = _Fixture(count: 6);
        for (var index = 3; index < 6; index++) {
          fixture.transforms[index].setTranslationRaw(index + 8, 0, -2);
        }
        final preparing = fixture.prepare();
        await _waitForFirstBatch(fixture);
        final bytes = fixture.registry.retainedBytes;
        expect(bytes, greaterThan(0));
        if (mutation == 'invalidate') {
          fixture.registry.invalidateOwner(fixture.owners.first);
        } else {
          fixture.registry.retainOwners(fixture.owners.skip(3));
        }
        expect(fixture.registry.batchCount, 0);
        expect(fixture.registry.retainedBytes, 0);
        expect(fixture.budget.residentBytes, 0);
        await preparing;
        expect(fixture.registry.batchCount, 1);
        expect(fixture.registry.retainedBytes, bytes);
        expect(fixture.budget.residentBytes, bytes);
        fixture.render(indices: [3, 4, 5]);
        expect(fixture.depthDraws.single.vertexCount, 9);
      },
    );
  }

  test(
    'completion revalidates source guards changed after a batch was built',
    () async {
      final fixture = _Fixture(count: 6);
      for (var index = 3; index < 6; index++) {
        fixture.transforms[index].setTranslationRaw(index + 8, 0, -2);
      }
      final preparing = fixture.prepare();
      await _waitForFirstBatch(fixture);
      final bytes = fixture.registry.retainedBytes;
      fixture.current[0] = false;
      await preparing;
      expect(fixture.registry.batchCount, 1);
      expect(fixture.registry.retainedBytes, bytes);
      expect(fixture.budget.residentBytes, bytes);
      fixture.render(indices: [3, 4, 5]);
      expect(fixture.depthDraws.single.vertexCount, 9);
    },
  );

  test(
    'a new generation immediately prunes an already built stale batch',
    () async {
      final fixture = _Fixture(count: 6);
      for (var index = 3; index < 6; index++) {
        fixture.transforms[index].setTranslationRaw(index + 8, 0, -2);
      }
      final stale = fixture.prepare();
      await _waitForFirstBatch(fixture);
      final bytes = fixture.registry.retainedBytes;
      final current = fixture.context.prepareStaticDepthBatches(
        fixture.descriptors.skip(3),
        budget: fixture.budget,
      );
      expect(fixture.registry.batchCount, 0);
      expect(fixture.budget.residentBytes, 0);
      await Future.wait([stale, current]);
      expect(fixture.registry.batchCount, 1);
      expect(fixture.registry.retainedBytes, bytes);
      expect(fixture.budget.residentBytes, bytes);
      fixture.render(indices: [3, 4, 5]);
      expect(fixture.depthDraws.single.vertexCount, 9);
    },
  );

  for (final failure in ['pipeline', 'geometry']) {
    test(
      '$failure during batched depth leaves no stale frame state in the next generation',
      () async {
        final fixture = _Fixture(count: 6);
        for (var index = 3; index < 6; index++) {
          fixture.transforms[index].setTranslationRaw(index + 8, 0, -2);
        }
        await fixture.prepare();
        final bytes = fixture.registry.retainedBytes ~/ 2;
        fixture.backend.failure = failure;
        expect(fixture.render, throwsStateError);
        expect(fixture.context.sourceModelOwner, same(fixture.outerOwner));
        expect(fixture.context.model.storage, fixture.outerTransform.storage);
        fixture.backend.failure = null;
        fixture.clearDraws();
        final preparing = fixture.context.prepareStaticDepthBatches(
          fixture.descriptors.skip(3),
          budget: fixture.budget,
        );
        expect(fixture.registry.batchCount, 1);
        expect(fixture.budget.residentBytes, bytes);
        await preparing;
        fixture.render(indices: [3, 4, 5]);
        expect(fixture.depthDraws.single.vertexCount, 9);
        expect(fixture.registry.batchCount, 1);
        expect(fixture.budget.residentBytes, bytes);
        fixture.registry.dispose();
        expect(fixture.budget.residentBytes, 0);
      },
    );
  }

  test(
    'new preparation cancels stale queued generations and releases overlap',
    () async {
      final fixture = _Fixture();
      await fixture.prepare();
      final firstBytes = fixture.budget.residentBytes;
      final blocker = await fixture.budget.acquire();
      final old = fixture.prepare();
      await Future<void>.delayed(Duration.zero);
      fixture.transforms[0].translateByDouble(.125, 0, 0, 1);
      final next = fixture.prepare();
      blocker.release();
      await Future.wait([old, next]);
      expect(fixture.registry.batchCount, 1);
      expect(fixture.budget.residentBytes, firstBytes);
      expect(fixture.budget.peakBytes, greaterThanOrEqualTo(firstBytes * 2));
      expect(fixture.budget.transientBytes, 0);
      fixture.clearDraws();
      fixture.render();
      expect(fixture.depthDraws, hasLength(1));
    },
  );

  for (final limit in ['batch', 'cache', 'staging', 'budget']) {
    test(
      '$limit resource bound keeps original draws without retained leases',
      () async {
        final fixture = _Fixture();
        fixture.context.staticDepthBatches = SpatialStaticDepthBatches(
          maximumBatchBytes: limit == 'batch' ? 1 : 256 * 1024,
          maximumRetainedBytes: limit == 'cache' ? 1 : 4 * 1024 * 1024,
          maximumStagingBytes: limit == 'staging' ? 1 : 2 * 1024 * 1024,
        );
        final budget = limit == 'budget'
            ? RuntimeResourceBudget(
                profile: const RuntimeResourceProfile(maximumResidentBytes: 1),
              )
            : fixture.budget;
        await fixture.prepare(budget: budget);
        expect(fixture.registry.batchCount, 0);
        expect(budget.residentBytes, 0);
        expect(budget.transientBytes, 0);
        expect(fixture.backend.buffers, isEmpty);
        fixture.render();
        expect(fixture.depthDraws, hasLength(3));
      },
    );
  }

  test(
    'owner and cell caps split real batches and do not exceed uint16 indices',
    () async {
      final fixture = _Fixture(count: 35);
      for (final transform in fixture.transforms) {
        transform.setTranslationRaw(1, 0, -2);
      }
      fixture.transforms[34].setTranslationRaw(9, 0, -2);
      await fixture.prepare();
      fixture.render();
      expect(fixture.registry.batchCount, 3);
      expect(fixture.depthDraws.map((draw) => draw.vertexCount), [
        48,
        48,
        6,
        3,
      ]);
      expect(fixture.budget.residentBytes, fixture.registry.retainedBytes);
      expect(
        fixture.registry.retainedBytes,
        lessThanOrEqualTo(4 * 1024 * 1024),
      );
    },
  );

  test('owner invalidation releases only affected batches and disposal releases all', () async {
    final fixture = _Fixture(count: 6);
    for (var index = 3; index < 6; index++) {
      fixture.transforms[index].setTranslationRaw(index + 8, 0, -2);
    }
    await fixture.prepare();
    final before = fixture.registry.retainedBytes;
    fixture.registry.invalidateOwner(fixture.owners.first);
    expect(fixture.registry.batchCount, 1);
    expect(fixture.registry.retainedBytes, before ~/ 2);
    expect(fixture.budget.residentBytes, before ~/ 2);
    fixture.registry.dispose();
    fixture.registry.dispose();
    expect(fixture.registry.isDisposed, isTrue);
    expect(fixture.budget.residentBytes, 0);
    expect(fixture.budget.activeDecodes, 0);
  });

  test('SceneGame admits shared source owners and releases batches before source leases', () async {
    final fixture = _Fixture();
    final controller = SpatialSceneController();
    final definition = ProjectModel3dEntry(
      id: 'tree',
      name: 'Tree',
      sourceAssetId: 'tree-source',
      relativePath: 'assets/models3d/tree.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3(x: -.4, y: 0, z: 0),
          max: Model3dVector3(x: .4, y: .5, z: 0),
        ),
        meshCount: 1,
        triangleCount: 1,
      ),
    );
    final scene = MapSpatialScene(
      width: 8,
      depth: 8,
      instances: [
        for (var index = 0; index < 3; index++)
          SpatialModelInstance(
            id: 'tree-$index',
            modelId: 'tree',
            position: Model3dVector3(x: 1 + index.toDouble(), y: 0, z: 1),
          ),
      ],
    );
    final view = SpatialSceneView(
      scene: scene,
      models: [definition],
      staticDepthBatchesEnabled: true,
      resourceBudget: fixture.budget,
      loadModel: (_) async =>
          throw StateError('The shared source is already admitted'),
      controller: controller,
      onCell: (_, _) {},
      background: const Color(0xff000000),
      ground: const Color(0xff224422),
      edge: const Color(0xff111111),
      errorBuilder: (_, _) => const SizedBox(),
    );
    final game =
        SpatialSceneGame(view, onPreviewStatus: (_) {}, onSurfaceChanged: () {})
          ..onGameResize(Vector2(200, 200))
          ..sceneReady = true;
    addTearDown(() {
      game.onRemove();
      controller.dispose();
    });
    final sourceLease = await fixture.budget.acquire(residentBytes: 1024);
    sourceLease.commit();
    game.cache['tree-source'] = Future.value(fixture.model);
    game.modelReservations['tree-source'] = sourceLease;
    expect(await game.refresh(), isTrue);
    final registry = (game.context as SpatialRenderContext).staticDepthBatches!;
    expect(registry.batchCount, 1);
    for (final owner in game.animationModels.values) {
      expect(owner.model, same(fixture.model));
      expect(
        owner.model.nodes.values.single.mesh!.surfaces.single,
        same(fixture.surface),
      );
    }
    expect(fixture.budget.residentBytes, 1024 + registry.retainedBytes);
    game.animationModels.values.first.onRemove();
    expect(registry.batchCount, 0);
    expect(fixture.budget.residentBytes, 1024);
    await game.prepareStaticDepthBatches();
    game.onRemove();
    expect(registry.isDisposed, isTrue);
    expect(fixture.budget.residentBytes, 0);
    expect(fixture.budget.activeDecodes, 0);
  });

  test(
    'flush never initiates preparation or allocates another batch',
    () async {
      final fixture = _Fixture();
      fixture.render();
      expect(fixture.context.staticDepthBatches, isNull);
      await fixture.prepare();
      fixture.clearDraws();
      final before = fixture.backend.buffers.length;
      Future<void>? forbidden;
      fixture.render(
        beforeCapture: (index) {
          if (index == 0)
            forbidden = fixture.context.prepareStaticDepthBatches(
              fixture.descriptors,
              budget: fixture.budget,
            );
        },
      );
      await expectLater(forbidden!, throwsStateError);
      expect(fixture.backend.buffers, hasLength(before));
      expect(fixture.depthDraws, hasLength(1));
    },
  );
}

Future<void> _waitForFirstBatch(_Fixture fixture) async {
  for (
    var attempt = 0;
    attempt < 20 && fixture.registry.batchCount == 0;
    attempt++
  ) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(fixture.registry.batchCount, 1);
}

double _float32(double value) => (Float32List(1)..[0] = value)[0];
int _float32Bits(double value) =>
    (Float32List(1)..[0] = value).buffer.asUint32List()[0];

class _Fixture {
  _Fixture({
    int count = 3,
    bool normals = true,
    bool blend = false,
    bool shadows = false,
  }) {
    device = _Device(backend)..renderSize = const Size(64, 64);
    context = SpatialRenderContext(device)
      ..setCamera(Matrix4.identity(), Matrix4.identity());
    device.context = context;
    context.depthOfField = SpatialDepthOfField(device.backend)
      ..profile = SpatialDepthOfFieldProfile(enabled: true);
    material = SpatialPixelMaterial(
      texture,
      alphaMode: blend ? Model3dAlphaMode.blend : Model3dAlphaMode.mask,
      alphaCutoff: .5,
    )..cullMode = CullMode.backFace;
    surface = SpatialModelSurface(
      vertices: [
        Vertex(
          position: Vector3(-.33333334, 0, 0),
          texCoord: Vector2(.25, .5),
          normal: normals ? Vector3(0, 1, 0) : null,
          color: const Color(0xffabcdef),
        ),
        Vertex(
          position: Vector3(.33333334, 0, 0),
          texCoord: Vector2(.75, .5),
          normal: normals ? Vector3(0, 1, 0) : null,
        ),
        Vertex(
          position: Vector3(0, .5, 0),
          texCoord: Vector2(.5, 1),
          normal: normals ? Vector3(0, 1, 0) : null,
        ),
      ],
      indices: [0, 1, 2],
      material: material,
    );
    model = Model.simple(mesh: Mesh()..addSurface(surface));
    registerSpatialModelClipSource(model, {}, hasMaterialAnimations: false);
    owners = List.generate(count, (_) => Object());
    current = List.filled(count, true);
    transforms = List.generate(
      count,
      (i) => Matrix4.translationValues(i * 1.25, 0, -2),
    );
    if (shadows)
      context.lighting = SpatialLightingProfile.stylized(
        shadow: SpatialShadowProfile(
          casterInstanceIds: {for (var i = 0; i < count; i++) 'map-$i/same-id'},
          center: (x: 0, y: 0, z: -2),
          extent: 32,
          depth: 64,
          resolution: 64,
        ),
        pointShadowCasterInstanceIds: {
          for (var i = 0; i < count; i++) 'map-$i/same-id',
        },
        pointLights: [
          SpatialPointLight(position: (x: 0, y: 3, z: -4), radius: 20),
        ],
      );
    addTearDown(() {
      context.staticDepthBatches?.dispose();
      budget.dispose();
    });
  }
  final backend = _Backend();
  late final _Device device;
  late final SpatialRenderContext context;
  final texture = Texture(ByteData(4), width: 1, height: 1);
  late final SpatialPixelMaterial material;
  late final SpatialModelSurface surface;
  late Model model;
  late final List<Object> owners;
  late final List<bool> current;
  late final List<Matrix4> transforms;
  final outerOwner = Object();
  final outerTransform = Matrix4.translationValues(101, 102, 103);
  final budget = RuntimeResourceBudget(
    profile: const RuntimeResourceProfile(maximumConcurrentDecodes: 1),
  );
  SpatialStaticDepthBatches get registry => context.staticDepthBatches!;
  List<_Draw> get depthDraws =>
      backend.draws.where((draw) => draw.path == 'depth').toList();
  List<_Draw> get colorDraws =>
      backend.draws.where((draw) => draw.path == 'color').toList();
  Map<String, int> get drawCounts => {
    for (final path in ['depth', 'shadow', 'point', 'color'])
      path: backend.draws.where((draw) => draw.path == path).length,
  };
  List<SpatialStaticDepthOwner> get descriptors => [
    for (var i = 0; i < owners.length; i++)
      SpatialStaticDepthOwner(
        owner: owners[i],
        source: model,
        transform: transforms[i],
        isCurrent: () => current[i],
      ),
  ];
  Future<void> prepare({RuntimeResourceBudget? budget}) async {
    context.staticDepthBatches ??= SpatialStaticDepthBatches();
    await context.prepareStaticDepthBatches(
      descriptors,
      budget: budget ?? this.budget,
    );
  }

  void clearDraws() {
    backend.draws.clear();
    device.colorOwners.clear();
    device.colorInstanceIds.clear();
    device.colorShadowIds.clear();
  }

  void render({
    List<int>? indices,
    bool allSurfaces = false,
    void Function(int)? beforeCapture,
    void Function(int)? afterCapture,
  }) {
    device.begin();
    device.beginPass(const Size(64, 64));
    try {
      context.submitDraw(
        _Object(() {
          try {
            for (final i
                in indices ?? List.generate(owners.length, (index) => index)) {
              context.model.setFrom(transforms[i]);
              context.jointsInfo.jointTransforms = [];
              context.sourceModelOwner = owners[i];
              context.sourceInstanceId = 'same-id';
              context.sourceShadowId = 'map-$i/same-id';
              beforeCapture?.call(i);
              if (allSurfaces) {
                context.drawMesh(model.nodes.values.single.mesh!);
              } else {
                context.drawSurface(surface);
              }
              afterCapture?.call(i);
            }
          } finally {
            context.model.setFrom(outerTransform);
            context.sourceModelOwner = outerOwner;
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

class _Device extends FlutterFrameGraphicsDevice {
  _Device(GpuBackend backend) : super(backend: backend);
  late SpatialRenderContext context;
  final colorOwners = <Object?>[];
  final colorInstanceIds = <String?>[];
  final colorShadowIds = <String?>[];
  @override
  void bindGeometry(Surface surface) {
    colorOwners.add(context.sourceModelOwner);
    colorInstanceIds.add(context.sourceInstanceId);
    colorShadowIds.add(context.sourceShadowId);
    super.bindGeometry(surface);
  }
}

class _Object extends Object3D {
  _Object(this.capture);
  final void Function() capture;
  @override
  void draw(RenderContext context) => capture();
}

final class _Backend extends GpuBackend {
  final draws = <_Draw>[];
  final slots = <String, _Slot>{};
  final buffers = <_Buffer>[];
  String? failure;
  int bufferAttempts = 0;
  int? failAtBuffer;
  @override
  GpuFrame beginFrame() => _Frame(this);
  @override
  GpuRenderTarget createRenderTarget({
    required int width,
    required int height,
    required Color clearValue,
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
  }) {
    final attempt = ++bufferAttempts;
    if (failure == 'allocate' &&
        (failAtBuffer == null || failAtBuffer == attempt)) {
      throw StateError('optional batch allocation failed');
    }
    final buffer = _Buffer(
      'batch',
      sizeInBytes,
      beforeWrite: () {
        if (failure == 'write' &&
            (failAtBuffer == null || failAtBuffer == attempt)) {
          throw StateError('optional batch write failed');
        }
      },
    );
    buffers.add(buffer);
    return buffer;
  }

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
    this.geometry,
    this.vertexCount,
    this.indexCount,
  );
  final _Backend backend;
  final String name, path;
  final CullMode cull;
  final Map<String, List<double>> uniforms;
  final GpuTexture? texture;
  final ByteData geometry;
  final int vertexCount, indexCount;
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
  late _Buffer geometry;
  int vertices = 0, indices = 0;
  CullMode cull = CullMode.none;
  GpuTexture? texture;
  @override
  void bindPipeline(GpuPipeline pipeline, CullMode cullMode) {
    final entry = (pipeline as _Pipeline).entry;
    path = entry == 'CameraDepthFragment'
        ? 'depth'
        : entry == 'ShadowDepthFragment'
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
    geometry = view.buffer as _Buffer;
    vertices = vertexCount;
    name = geometry.name;
    if (path != 'color' && backend.failure == 'geometry')
      throw StateError('geometry failed');
  }

  @override
  void bindIndexBuffer(
    GpuBufferView view,
    GpuIndexType indexType,
    int indexCount,
  ) {
    indices = indexCount;
  }

  @override
  void clearBindings() {
    uniforms.clear();
    texture = null;
  }

  @override
  void draw() => backend.draws.add(
    _Draw(
      backend,
      name,
      path,
      cull,
      Map.of(uniforms),
      texture,
      geometry.data,
      vertices,
      indices,
    ),
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
  _Buffer(this.name, int size, {this.beforeWrite}) : data = ByteData(size);
  final void Function()? beforeWrite;
  final String name;
  final ByteData data;
  @override
  void write(ByteData source, {int destinationOffsetInBytes = 0}) {
    beforeWrite?.call();
    data.buffer.asUint8List().setRange(
      destinationOffsetInBytes,
      destinationOffsetInBytes + source.lengthInBytes,
      source.buffer.asUint8List(source.offsetInBytes, source.lengthInBytes),
    );
  }
}

class _Target implements GpuRenderTarget {
  @override
  final colorTexture = _Texture();
}

class _Texture implements GpuTexture {
  @override
  void write(ByteData data) {}
  @override
  Image asImage() => throw UnsupportedError('No readback in renderer tests.');
}
