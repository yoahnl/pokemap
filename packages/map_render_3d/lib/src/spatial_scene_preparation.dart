import 'dart:async';
import 'dart:typed_data';

import 'package:flame_3d/model.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_core/map_core.dart';

import 'model_byte_loader.dart';
import 'spatial_ground.dart';

final class SpatialScenePreparation {
  const SpatialScenePreparation({
    required this.map,
    required this.project,
    required this.loadModel,
    required this.loadGroundImage,
    required this.resourceIdentity,
    required this.resourceBudget,
    required this.isCurrent,
  });

  final MapData map;
  final ProjectManifest project;
  final Future<Uint8List> Function(String id) loadModel;
  final Future<Uint8List> Function(String id) loadGroundImage;
  final String resourceIdentity;
  final RuntimeResourceBudget resourceBudget;
  final bool Function() isCurrent;
}

final class SpatialSceneResourcePreparation {
  SpatialSceneResourcePreparation(
    this.request, {
    required Map<String, Future<Model>> modelCache,
    required Map<String, Future<Texture>> groundTextureCache,
    required bool Function() isCurrent,
  }) : _models = Map.of(modelCache),
       _textures = Map.of(groundTextureCache),
       _initialModels = modelCache.keys.toSet(),
       _initialTextures = groundTextureCache.keys.toSet(),
       _sourceCurrent = isCurrent;

  final SpatialScenePreparation request;
  final Map<String, Future<Model>> _models;
  final Map<String, Future<Texture>> _textures;
  final Set<String> _initialModels, _initialTextures;
  final bool Function() _sourceCurrent;
  final _modelLeases = <String, RuntimeResourceReservation>{};
  final _textureLeases = <String, RuntimeResourceReservation>{};
  Map<String, Future<Model>>? _adoptedModels;
  Map<String, Future<Texture>>? _adoptedTextures;
  Map<String, RuntimeResourceReservation>? _adoptedModelLeases;
  Map<String, RuntimeResourceReservation>? _adoptedTextureLeases;
  Future<bool>? _pending;
  bool _discarded = false, _committed = false, _ready = false;

  bool get isCurrent => !_discarded && request.isCurrent() && _sourceCurrent();
  Future<bool> prepare() => _pending ??= _prepare();

  Future<bool> _prepare() async {
    try {
      if (!isCurrent) return false;
      final project = request.project;
      final map = projectSpatialSmartTileModels(
        map: request.map,
        catalog: project.smartTileCatalog,
        sourceCellWidth: project.settings.tileWidth,
        sourceCellHeight: project.settings.tileHeight,
      );
      final scene = map.spatialScene;
      if (scene == null) throw StateError('A spatial destination is required.');
      final definitions = {
        for (final model in project.models3d) model.id: model,
      };
      final prepared = <String>{};
      final instances = scene.instances.iterator;
      var failed = false;
      Future<void> loadNext() async {
        while (!failed && isCurrent && instances.moveNext()) {
          final instance = instances.current;
          try {
            final definition = definitions[instance.modelId];
            if (definition == null) {
              throw StateError('Model missing: ${instance.modelId}');
            }
            if (!prepared.add(definition.sourceAssetId)) continue;
            await ModelByteLoader.loadCached(
              _models,
              definition.sourceAssetId,
              () => request.loadModel(definition.id),
              budget: request.resourceBudget,
              isCurrent: () => isCurrent,
              onResident: (key, lease) {
                if (!isCurrent) {
                  lease.release();
                  return;
                }
                _modelLeases[key] = lease;
              },
            );
            await Future<void>.delayed(Duration.zero);
          } on Object {
            failed = true;
            rethrow;
          }
        }
      }

      await Future.wait([loadNext(), loadNext()]);
      final ground = SpatialGroundPlan(map, project);
      for (final id in ground.imageIds) {
        if (!isCurrent) {
          discard();
          return false;
        }
        await _textures.putIfAbsent(
          id,
          () => loadSpatialGroundTextureFromSource(
            () => request.loadGroundImage(id),
            transparentColor: project.tilesets
                .where((entry) => entry.id == id)
                .firstOrNull
                ?.transparentColor,
            budget: request.resourceBudget,
            isCurrent: () => isCurrent,
            onResident: (lease) {
              if (!isCurrent) {
                lease.release();
                return;
              }
              _textureLeases[id] = lease;
            },
          ),
        );
        await Future<void>.delayed(Duration.zero);
      }
      if (!isCurrent) {
        discard();
        return false;
      }
      _ready = true;
      return true;
    } on Object {
      final cancelled = !isCurrent;
      discard();
      if (cancelled) return false;
      rethrow;
    }
  }

  void adoptInto(
    Map<String, Future<Model>> models,
    Map<String, Future<Texture>> textures,
    Map<String, RuntimeResourceReservation> modelLeases,
    Map<String, RuntimeResourceReservation> textureLeases,
  ) {
    if (!_ready || !isCurrent || _committed || _adoptedModels != null) {
      throw StateError('The destination resources are not ready for adoption.');
    }
    _adoptedModels = models;
    _adoptedTextures = textures;
    _adoptedModelLeases = modelLeases;
    _adoptedTextureLeases = textureLeases;
    for (final key in _models.keys.where(
      (key) => !_initialModels.contains(key),
    )) {
      if (models.containsKey(key) && !identical(models[key], _models[key])) {
        _modelLeases.remove(key)?.release();
        continue;
      }
      models[key] = _models[key]!;
      if (_modelLeases[key] case final lease?) modelLeases[key] = lease;
    }
    for (final key in _textures.keys.where(
      (key) => !_initialTextures.contains(key),
    )) {
      if (textures.containsKey(key) &&
          !identical(textures[key], _textures[key])) {
        _textureLeases.remove(key)?.release();
        continue;
      }
      textures[key] = _textures[key]!;
      if (_textureLeases[key] case final lease?) textureLeases[key] = lease;
    }
  }

  void commit() {
    if (_discarded || _adoptedModels == null) {
      throw StateError('The destination resources have not been adopted.');
    }
    _committed = true;
    _modelLeases.clear();
    _textureLeases.clear();
    _models.clear();
    _textures.clear();
    _initialModels.clear();
    _initialTextures.clear();
  }

  void discard() {
    if (_discarded || _committed) return;
    _discarded = true;
    for (final entry in _modelLeases.entries) {
      if (identical(_adoptedModels?[entry.key], _models[entry.key])) {
        _adoptedModels?.remove(entry.key);
        if (identical(_adoptedModelLeases?[entry.key], entry.value)) {
          _adoptedModelLeases?.remove(entry.key);
        }
      }
      entry.value.release();
    }
    for (final entry in _textureLeases.entries) {
      if (identical(_adoptedTextures?[entry.key], _textures[entry.key])) {
        _adoptedTextures?.remove(entry.key);
        if (identical(_adoptedTextureLeases?[entry.key], entry.value)) {
          _adoptedTextureLeases?.remove(entry.key);
        }
      }
      entry.value.release();
    }
    _modelLeases.clear();
    _textureLeases.clear();
    _models.clear();
    _textures.clear();
    _initialModels.clear();
    _initialTextures.clear();
  }
}
