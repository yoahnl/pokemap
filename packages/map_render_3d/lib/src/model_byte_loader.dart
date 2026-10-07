import 'dart:typed_data';

import 'package:flame/cache.dart';
import 'package:flame/flame.dart';
import 'package:flame_3d/model.dart';
import 'package:flame_3d/parser.dart';
import 'package:flame_3d/core.dart';
import 'package:flame_3d/resources.dart';

import 'glb_renderer_layout.dart';
import 'spatial_pixel_material.dart';

final class ModelByteLoader {
  static int _sequence = 0;

  static Future<Model> loadCached(
    Map<String, Future<Model>> cache,
    String key,
    Future<Uint8List> Function() read,
  ) async {
    final pending = cache.putIfAbsent(key, () async => load(await read()));
    try {
      return await pending;
    } on Object {
      if (identical(cache[key], pending)) cache.remove(key);
      rethrow;
    }
  }

  static Future<Model> load(Uint8List bytes) async {
    final current = Flame.assets;
    final cache = current is _ModelAssetsCache
        ? current
        : _ModelAssetsCache(current);
    Flame.assets = cache;
    final key = '__avelune_model_${_sequence++}.glb';
    cache.models[key] = normalizeGlbAccessors(bytes);
    try {
      final model = await ModelParser.parse(key);
      for (final node in model.nodes.values) {
        for (final surface in node.mesh?.surfaces ?? <Surface>[]) {
          if (surface.material case final SpatialMaterial material) {
            surface.material = SpatialPixelMaterial(material.albedoTexture)
              ..albedoColor = material.albedoColor;
          }
        }
      }
      return Model(
        nodes: model.nodes,
        animations: [
          for (final clip in model.animations)
            ModelAnimation(
              name: clip.name,
              nodes: {
                for (final entry in clip.nodes.entries)
                  entry.key: AbsoluteNodeAnimation(
                    channels: [
                      for (final channel in entry.value.channels)
                        EndpointSafeAnimationController(
                          animation: channel.animation,
                        ),
                    ],
                  ),
              },
            ),
        ],
      );
    } finally {
      cache.models.remove(key);
    }
  }
}

class AbsoluteNodeAnimation extends NodeAnimation {
  AbsoluteNodeAnimation({required super.channels});

  @override
  void sampleInto(double time, Matrix4 matrix) {
    final translation = Vector3.zero();
    final rotation = Quaternion.identity();
    final scale = Vector3.all(1);
    matrix.decompose(translation, rotation, scale);
    for (final channel in channels) {
      final value = channel.sample(time);
      switch (channel.animation) {
        case TranslationAnimationSpline():
          translation.setFrom(value as Vector3);
        case RotationAnimationSpline():
          rotation.setFrom(value as Quaternion);
        case ScaleAnimationSpline():
          scale.setFrom(value as Vector3);
      }
    }
    matrix.setFrom(Matrix4.compose(translation, rotation, scale));
  }
}

class EndpointSafeAnimationController<T> extends AnimationController<T> {
  EndpointSafeAnimationController({required super.animation});

  @override
  T sample(double time) =>
      time >= lastTime ? animation.values.last.value : super.sample(time);
}

final class _ModelAssetsCache extends AssetsCache {
  _ModelAssetsCache(this.delegate)
    : super(prefix: delegate.prefix, bundle: delegate.bundle);

  final AssetsCache delegate;
  final Map<String, Uint8List> models = {};

  @override
  Future<Uint8List> readBinaryFile(String fileName, {String? package}) {
    final bytes = package == null ? models[fileName] : null;
    return bytes == null
        ? delegate.readBinaryFile(fileName, package: package)
        : Future.value(bytes);
  }

  @override
  Future<String> readFile(String fileName, {String? package}) =>
      delegate.readFile(fileName, package: package);

  @override
  Future<Map<String, dynamic>> readJson(String fileName, {String? package}) =>
      delegate.readJson(fileName, package: package);

  @override
  T fromCache<T>(String fileName) => delegate.fromCache<T>(fileName);

  @override
  void clear(String file) => delegate.clear(file);

  @override
  void clearCache() => delegate.clearCache();

  @override
  int get cacheCount => delegate.cacheCount;
}
