import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/flame.dart';
import 'package:flame_3d/model.dart';
import 'package:flame_3d/core.dart';
import 'package:flame_3d/src/parser/glb_parser.dart';
import 'package:flame_3d/src/parser/gltf/gltf_root.dart';
import 'package:flame_3d/src/parser/gltf/image.dart' as gltf;
import 'package:flame_3d/resources.dart' as resources;
import 'package:map_core/map_core.dart';

import 'animated_render_model.dart';
import 'glb_renderer_layout.dart';
import 'spatial_model_source_admission.dart';
import 'spatial_resource_admission.dart';

final class ModelByteLoader {
  static int _sequence = 0;

  static Future<bool> preloadCached(
    Map<String, Future<Model>> cache,
    Map<String, Future<Uint8List> Function()> sources, {
    bool Function()? isCurrent,
    RuntimeResourceBudget? budget,
    void Function(String key, RuntimeResourceReservation reservation)?
    onResident,
  }) async {
    final entries = sources.entries.iterator;
    var failed = false;
    Future<void> loadNext() async {
      while (!failed && (isCurrent?.call() ?? true) && entries.moveNext()) {
        final entry = entries.current;
        try {
          await loadCached(
            cache,
            entry.key,
            entry.value,
            budget: budget,
            isCurrent: budget == null ? null : isCurrent,
            onResident: onResident,
          );
        } on Object {
          if (!(isCurrent?.call() ?? true)) return;
          failed = true;
          rethrow;
        }
      }
    }

    await Future.wait([for (var index = 0; index < 4; index++) loadNext()]);
    return isCurrent?.call() ?? true;
  }

  static Future<Model> loadCached(
    Map<String, Future<Model>> cache,
    String key,
    Future<Uint8List> Function() read, {
    RuntimeResourceBudget? budget,
    bool Function()? isCurrent,
    void Function(String key, RuntimeResourceReservation reservation)?
    onResident,
  }) async {
    final pending = cache.putIfAbsent(key, () async {
      final reservation = await budget?.acquire(
        residentBytes: 1,
        transientBytes: budget.profile.maximumEncodedBytes,
        isCurrent: isCurrent);
      try {
        reservation?.ensureCurrent();
        final bytes = await read();
        reservation?.ensureCurrent();
        return await load(
          bytes,
          budget: budget,
          reservation: reservation,
          isCurrent: isCurrent,
          onResident: onResident == null
              ? null
              : (lease) => onResident(key, lease),
        );
      } catch (_) {
        reservation?.release();
        rethrow;
      }
    });
    try {
      return await pending;
    } on Object {
      if (identical(cache[key], pending)) cache.remove(key);
      rethrow;
    }
  }

  static Future<Model> load(
    Uint8List bytes, {
    RuntimeResourceBudget? budget,
    RuntimeResourceReservation? reservation,
    bool Function()? isCurrent,
    void Function(RuntimeResourceReservation reservation)? onResident,
    Future<ui.Codec> Function(Uint8List bytes)? codecLoader,
  }) async {
    final controller = budget ?? RuntimeResourceBudget();
    final lease = reservation ?? await controller.acquire(isCurrent: isCurrent);
    try {
      lease.ensureCurrent();
      if (bytes.length > controller.profile.maximumEncodedBytes) {
        throw const RuntimeResourceAdmissionException('encoded_bytes');
      }
      lease.resize(residentBytes: 0, transientBytes: bytes.length * 2);
      final estimate = await spatialModelResourceEstimate(bytes, lease);
      lease.resize(
        residentBytes: estimate.resident,
        transientBytes: estimate.transient,
      );
      final model = await _loadAdmitted(bytes, lease, codecLoader);
      lease.ensureCurrent();
      lease.commit();
      if (onResident == null) {
        lease.release();
      } else {
        onResident(lease);
      }
      return model;
    } catch (_) {
      lease.release();
      rethrow;
    }
  }

  static Future<Model> _loadAdmitted(
    Uint8List bytes,
    RuntimeResourceReservation reservation,
    Future<ui.Codec> Function(Uint8List bytes)? codecLoader,
  ) async {
    final current = Flame.assets;
    final cache = current is _ModelAssetsCache
        ? current
        : _ModelAssetsCache(current);
    Flame.assets = cache;
    final key = '__avelune_model_${_sequence++}.glb';
    final normalized = normalizeGlbAccessors(bytes);
    final layout = GlbRendererLayout(normalized);
    cache.models[key] = normalized;
    try {
      final materialAnimations = Model3dMaterialAnimations.fromGlbJson(
        layout.json,
      );
      final glb = await GlbParser().parseGlb(key);
      final json = glb.jsonChunk();
      final imageDefinitions = (json['images'] as List?) ?? const [];
      final root = await GltfRoot.from(
        prefix: '',
        json: {...json, 'images': <Object>[]},
        chunks: glb.binaryChunks().toList(),
      );
      root.images.addAll([
        for (final raw in imageDefinitions)
          _OwnedGltfImage.parse(
            root,
            Map<String, Object?>.from(raw as Map),
            reservation,
            codecLoader,
          ),
      ]);
      for (final image in root.images) {
        reservation.ensureCurrent();
        await image.init();
      }
      reservation.ensureCurrent();
      final model = root.toFlameModel();
      for (final node in model.nodes.values) {
        final mesh = node.mesh;
        if (mesh != null) {
          var determinant = node.transform.determinant();
          var parentIndex = node.parentNodeIndex;
          while (parentIndex != null) {
            final parent = model.nodes[parentIndex]!;
            determinant *= parent.transform.determinant();
            parentIndex = parent.parentNodeIndex;
          }
          layout.apply(
            node.nodeIndex,
            mesh,
            mirroredTransform: determinant < 0,
          );
        }
      }
      final animations = [
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
      ];
      if (materialAnimations.clips.isEmpty) {
        final result = Model(nodes: model.nodes, animations: animations);
        registerSpatialModelClipSource(
          result,
          layout.json,
          hasMaterialAnimations: false,
        );
        return result;
      }
      final targets = {
        for (final clip in materialAnimations.clips)
          for (final track in clip.tracks) track.materialIndex,
      };
      final result = AnimatedRenderModel(
        nodes: model.nodes,
        animations: animations,
        materialAnimations: materialAnimations,
        materialBindings: {
          for (final target in targets)
            target: layout.materialBindings[target] ?? [],
        },
        textures: [
          for (final texture in root.textures) texture.toFlameTexture(),
        ],
        textureWrapModes: [
          for (final texture in (layout.json['textures'] as List?) ?? const [])
            _textureWrapModes(layout.json, texture as Map<String, dynamic>),
        ],
      );
      registerSpatialModelClipSource(
        result,
        layout.json,
        hasMaterialAnimations: true,
      );
      return result;
    } finally {
      cache.models.remove(key);
    }
  }
}

({int wrapS, int wrapT}) _textureWrapModes(
  Map<String, dynamic> json,
  Map<String, dynamic> texture,
) {
  final samplerIndex = texture['sampler'] as int?;
  final sampler = samplerIndex == null
      ? null
      : json['samplers'][samplerIndex] as Map<String, dynamic>;
  return (
    wrapS: sampler?['wrapS'] as int? ?? 10497,
    wrapT: sampler?['wrapT'] as int? ?? 10497,
  );
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
  _ModelAssetsCache(this.delegate) : super(bundle: delegate.bundle);

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

final class _OwnedGltfImage extends gltf.Image {
  _OwnedGltfImage.parse(
    GltfRoot root,
    Map<String, Object?> json,
    this.reservation,
    this.codecLoader,
  ) : super.parse(root, json);
  final RuntimeResourceReservation reservation;
  final Future<ui.Codec> Function(Uint8List bytes)? codecLoader;

  @override
  Future<resources.ImageTexture> loadData() async {
    reservation.ensureCurrent();
    final bytes = await data();
    reservation.ensureCurrent();
    final codec = await (codecLoader ?? ui.instantiateImageCodec)(bytes);
    ui.Image? image;
    try {
      image = (await codec.getNextFrame()).image;
      reservation.ensureCurrent();
      final pixels = await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      reservation.ensureCurrent();
      if (pixels == null) {
        throw StateError('Model texture pixels are unavailable.');
      }
      return resources.ImageTexture(
        pixels,
        width: image.width,
        height: image.height,
      );
    } finally {
      image?.dispose();
      codec.dispose();
    }
  }
}
