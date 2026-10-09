import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flame_3d/core.dart';
import 'package:flame_3d/model.dart';
import 'package:flame_3d/resources.dart';
import 'package:flame_3d/src/parser/gltf/animation_interpolation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_render_3d/src/animated_render_model.dart';
import 'package:map_render_3d/src/spatial_pixel_material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('material clips play without manufacturing a node animation', () async {
    final model = await ModelByteLoader.load(_animatedTriangle());
    expect(model.animations, isEmpty);
    final component = AnimatedModelComponent(model: model)
      ..bindAnimation(0, loop: false, speed: 2);
    component.update(.2);
    expect(component.playback.clock, closeTo(.4, 1e-9));
    component.playback.paused = true;
    component.update(4);
    expect(component.playback.clock, closeTo(.4, 1e-9));
    component.playback.paused = false;
    component.update(4);
    expect(component.playback.clock, 1);
    component.playback.restart();
    expect(component.playback.clock, 0);
    expect(component.playback.paused, isFalse);
    component.stopAnimation();
    component.update(1);
    expect(component.playback.clock, 0);
  });

  test(
    'cached material clips retain independent clocks during rebuilds',
    () async {
      final model = await ModelByteLoader.load(_animatedTriangle());
      final first = AnimatedModelComponent(model: model)..bindAnimation(0);
      final second = AnimatedModelComponent(model: model)..bindAnimation(0);
      first.update(.4);
      second.update(.7);
      final rebuilt = AnimatedModelComponent(
        model: model,
        playback: ModelPlaybackState.from(first.playback),
      )..bindAnimation(0);
      rebuilt.update(.2);
      expect(first.playback.clock, .4);
      expect(second.playback.clock, .7);
      expect(rebuilt.playback.clock, closeTo(.6, 1e-9));
      rebuilt.bindAnimation(null);
      expect(rebuilt.playback.clock, 0);
      expect(first.playback.clock, .4);
    },
  );
  test(
    'mixed animations retain each period through clip loops and commands',
    () {
      final source = _metadata(nodeAnimationIndex: 0);
      final model = AnimatedRenderModel(
        nodes: {},
        animations: [_nodeClip()],
        materialAnimations: source,
      );
      final component = AnimatedModelComponent(model: model)..bindAnimation(1);
      expect(component.animationCount, 2);
      component.update(2.2);
      expect(component.playback.clock, closeTo(.2, 1e-9));
      expect(component.playback.materialTimeSeconds, closeTo(2.2, 1e-9));
      expect(
        component.playback
            .maybeTransform(0, Matrix4.identity())
            .getTranslation()
            .x,
        closeTo(1.4, 1e-6),
      );
      expect(
        source.clips.single.tracks.single
            .sample(component.playback.materialTimeSeconds)
            .transform[4],
        closeTo(.7 / 1.5, 1e-9),
      );
      component.bindRuntimeState(
        SpatialModelRuntimeState(
          modelId: 'model',
          animationIndex: 1,
          normalizedTime: .75,
          blocksMovement: true,
        ),
        authoredAnimationIndex: 1,
      );
      expect(component.playback.clock, 1.5);
      expect(
        component.playback
            .maybeTransform(0, Matrix4.identity())
            .getTranslation()
            .x,
        2.25,
      );
      component.bindRuntimeState(null, authoredAnimationIndex: 1);
      expect(component.playback.clock, closeTo(.2, 1e-9));
      expect(component.playback.materialTimeSeconds, closeTo(2.2, 1e-9));
      component.update(.2);
      expect(
        component.playback
            .maybeTransform(0, Matrix4.identity())
            .getTranslation()
            .x,
        closeTo(1.8, 1e-6),
      );
    },
  );

  test('material pose resets between cached instances and reuses textures', () {
    final firstTexture = ColorTexture(const Color(0xffff0000));
    final secondTexture = ColorTexture(const Color(0xff0000ff));
    final material = SpatialPixelMaterial(firstTexture)
      ..uvRect.setValues(.2, .3, .4, .5);
    final animation = _metadata(pattern: true);
    final model = AnimatedRenderModel(
      nodes: {},
      animations: [],
      materialAnimations: animation,
      materialBindings: {
        0: [material],
      },
      textures: [firstTexture, secondTexture],
    );
    model.applyMaterialPose(animation.clips.single, 1, loop: true);
    expect(material.albedoTexture, same(secondTexture));
    expect(material.uvTransformU.z, closeTo(2 / 3, 1e-6));
    expect(material.uvRect, Vector4(.2, .3, .4, .5));
    model.applyMaterialPose(animation.clips.single, .2, loop: true);
    expect(material.albedoTexture, same(firstTexture));
    expect(material.uvTransformU.z, closeTo(.2 / 1.5, 1e-6));
    model.applyMaterialPose(null, 0, loop: false);
    expect(material.albedoTexture, same(firstTexture));
    expect(material.uvTransformU, Vector4(1, 0, 0, 0));
    expect(material.uvTransformV, Vector4(0, 1, 0, 0));
    expect(material.uvRect, Vector4(.2, .3, .4, .5));
  });

  test(
    'PAT uses each texture sampler at key boundaries and restores defaults',
    () async {
      final model =
          await ModelByteLoader.load(_patternTriangle()) as AnimatedRenderModel;
      expect(model.textureWrapModes, [
        (wrapS: 33071, wrapT: 33071),
        (wrapS: 10497, wrapT: 33648),
      ]);
      final material = model.materialBindings[0]!.single;
      final initialTexture = material.albedoTexture;
      final clip = model.materialAnimations.clips.single;
      model.applyMaterialPose(clip, 0, loop: false);
      expect(material.activeWrapS, 33071);
      expect(material.activeWrapT, 33071);
      expect(material.albedoTexture, same(model.textures[0]));
      model.applyMaterialPose(clip, .999, loop: false);
      expect(material.activeWrapS, 33071);
      model.applyMaterialPose(clip, 1, loop: false);
      expect(material.activeWrapS, 10497);
      expect(material.activeWrapT, 33648);
      expect(material.albedoTexture, same(model.textures[1]));
      model.resetMaterialPose();
      expect(material.activeWrapS, 33071);
      expect(material.activeWrapT, 33071);
      expect(material.albedoTexture, same(initialTexture));
      model.applyMaterialPose(clip, 1, loop: true);
      expect(material.activeWrapS, 33071);
      expect(material.activeWrapT, 33071);
    },
  );

  test(
    'preview selects material names and validates combined indices',
    () async {
      final model = await ModelByteLoader.load(_animatedTriangle());
      final component = AnimatedModelComponent(model: model);
      component.playAnimationByName('Water movement');
      component.update(.4);
      component.playAnimationByIndex(0, resetClock: false);
      expect(component.playback.clock, .4);
      expect(component.playback.materialTimeSeconds, .4);
      expect(() => component.bindAnimation(1), throwsRangeError);
      expect(() => component.bindAnimation(-1), throwsRangeError);
    },
  );
}

Model3dMaterialAnimations _metadata({
  int? nodeAnimationIndex,
  bool pattern = false,
}) => Model3dMaterialAnimations.fromGlbJson({
  'materials': [{}],
  'textures': [{}, {}],
  if (nodeAnimationIndex != null) 'animations': [{}],
  'extras': {
    'aveluneMaterialAnimations': {
      'schemaVersion': 1,
      'clips': [
        {
          'name': 'Mixed ambient',
          'durationSeconds': 2,
          if (nodeAnimationIndex != null)
            'nodeAnimationIndex': nodeAnimationIndex,
          'tracks': [
            {
              'materialIndex': 0,
              'durationSeconds': 1.5,
              'times': [0, .75, 1.5],
              'transforms': [
                [1, 0, 0, 1, 0, 0],
                [1, 0, 0, 1, .5, .25],
                [1, 0, 0, 1, 1, .5],
              ],
              'interpolation': 'LINEAR',
              if (pattern) 'textureIndices': [0, 1, 0],
            },
          ],
        },
      ],
    },
  },
});

ModelAnimation _nodeClip() => ModelAnimation(
  name: 'Node ambient',
  nodes: {
    0: AbsoluteNodeAnimation(
      channels: [
        EndpointSafeAnimationController(
          animation: TranslationAnimationSpline.from(
            interpolation: AnimationInterpolation.linear,
            times: [0, 1.5],
            values: [Vector3.zero(), Vector3(3, 0, 0)],
          ),
        ),
      ],
    ),
  },
);

Uint8List _animatedTriangle() {
  final binary = ByteData(36);
  final coordinates = [0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0];
  for (var i = 0; i < coordinates.length; i++) {
    binary.setFloat32(i * 4, coordinates[i], Endian.little);
  }
  final json = utf8.encode(
    jsonEncode({
      'asset': {'version': '2.0'},
      'scene': 0,
      'scenes': [
        {
          'nodes': [0],
        },
      ],
      'nodes': [
        {'name': 'Water', 'mesh': 0},
      ],
      'buffers': [
        {'byteLength': 36},
      ],
      'bufferViews': [
        {'buffer': 0, 'byteLength': 36},
      ],
      'accessors': [
        {'bufferView': 0, 'componentType': 5126, 'count': 3, 'type': 'VEC3'},
      ],
      'materials': [
        {'name': 'Water', 'pbrMetallicRoughness': {}},
      ],
      'meshes': [
        {
          'primitives': [
            {
              'attributes': {'POSITION': 0},
              'material': 0,
            },
          ],
        },
      ],
      'extras': {
        'aveluneMaterialAnimations': {
          'schemaVersion': 1,
          'clips': [
            {
              'name': 'Water movement',
              'durationSeconds': 1,
              'tracks': [
                {
                  'materialIndex': 0,
                  'times': [0, 1],
                  'transforms': [
                    [1, 0, 0, 1, 0, 0],
                    [1, 0, 0, 1, .5, .25],
                  ],
                  'interpolation': 'LINEAR',
                },
              ],
            },
          ],
        },
      },
    }),
  );
  final jsonSize = (json.length + 3) ~/ 4 * 4;
  final bytes = Uint8List(12 + 8 + jsonSize + 8 + 36);
  final data = ByteData.sublistView(bytes);
  data.setUint32(0, 0x46546c67, Endian.little);
  data.setUint32(4, 2, Endian.little);
  data.setUint32(8, bytes.length, Endian.little);
  data.setUint32(12, jsonSize, Endian.little);
  data.setUint32(16, 0x4e4f534a, Endian.little);
  bytes.fillRange(20, 20 + jsonSize, 32);
  bytes.setRange(20, 20 + json.length, json);
  data.setUint32(20 + jsonSize, 36, Endian.little);
  data.setUint32(24 + jsonSize, 0x004e4942, Endian.little);
  bytes.setRange(28 + jsonSize, bytes.length, binary.buffer.asUint8List());
  return bytes;
}

Uint8List _patternTriangle() {
  final base = _animatedTriangle();
  final length = ByteData.sublistView(base).getUint32(12, Endian.little);
  final json =
      jsonDecode(utf8.decode(base.sublist(20, 20 + length)))
          as Map<String, dynamic>;
  final png = img.encodePng(img.Image(width: 1, height: 1));
  final binary = Uint8List(60 + png.length);
  binary.setRange(0, 36, base.sublist(28 + length, 64 + length));
  final uv = ByteData.sublistView(binary);
  for (final (index, value) in [0.0, 0.0, 1.0, 0.0, 0.0, 1.0].indexed) {
    uv.setFloat32(36 + index * 4, value, Endian.little);
  }
  binary.setRange(60, binary.length, png);
  json['buffers'][0]['byteLength'] = binary.length;
  json['bufferViews'].addAll([
    {'buffer': 0, 'byteOffset': 36, 'byteLength': 24},
    {'buffer': 0, 'byteOffset': 60, 'byteLength': png.length},
  ]);
  json['accessors'].add({
    'bufferView': 1,
    'componentType': 5126,
    'count': 3,
    'type': 'VEC2',
  });
  json['meshes'][0]['primitives'][0]['attributes']['TEXCOORD_0'] = 1;
  json['materials'][0]['pbrMetallicRoughness']['baseColorTexture'] = {
    'index': 0,
  };
  json['images'] = [
    {'bufferView': 2, 'mimeType': 'image/png'},
  ];
  json['samplers'] = [
    {'wrapS': 33071, 'wrapT': 33071},
    {'wrapS': 10497, 'wrapT': 33648},
  ];
  json['textures'] = [
    {'source': 0, 'sampler': 0},
    {'source': 0, 'sampler': 1},
  ];
  json['extras']['aveluneMaterialAnimations']['clips'][0]['tracks'][0]['textureIndices'] =
      [0, 1];
  final text = utf8.encode(jsonEncode(json));
  final jsonLength = (text.length + 3) ~/ 4 * 4;
  final binLength = (binary.length + 3) ~/ 4 * 4;
  final result = Uint8List(28 + jsonLength + binLength);
  final header = ByteData.sublistView(result);
  header.setUint32(0, 0x46546c67, Endian.little);
  header.setUint32(4, 2, Endian.little);
  header.setUint32(8, result.length, Endian.little);
  header.setUint32(12, jsonLength, Endian.little);
  header.setUint32(16, 0x4e4f534a, Endian.little);
  result.fillRange(20, 20 + jsonLength, 32);
  result.setRange(20, 20 + text.length, text);
  header.setUint32(20 + jsonLength, binLength, Endian.little);
  header.setUint32(24 + jsonLength, 0x004e4942, Endian.little);
  result.setRange(28 + jsonLength, 28 + jsonLength + binary.length, binary);
  return result;
}
