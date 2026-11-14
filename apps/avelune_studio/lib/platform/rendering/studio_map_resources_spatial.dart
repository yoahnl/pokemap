part of 'studio_map_resources.dart';

extension StudioMapResourcesSpatial on StudioMapResources {
  Future<Uint8List> _readGroundImage(String tilesetId) async {
    final tileset = manifest.tilesets
        .where((tileset) => tileset.id == tilesetId)
        .firstOrNull;
    if (tileset == null) {
      throw StateError('Image de terrain absente : $tilesetId');
    }
    return readGroundDefinition(tileset);
  }

  Future<Uint8List> _readGroundDefinition(ProjectTilesetEntry tileset) async {
    return Uint8List.fromList(
      await const LocalProjectFileReader().readBytes(
        projectRoot: projectRoot,
        relativePath: tileset.relativePath,
      ),
    );
  }

  Future<SpatialNpcPreview> _spatialPreview(MapData map) async {
    final frames = <String, SpatialActorVisual>{};
    final images = <String, ui.Image>{};
    if (!map.entities.any((entity) => entity.npc != null)) {
      return SpatialNpcPreview(frames, () {});
    }
    await initializeSpatialRenderer();
    final bundle = await loadStudioPreviewBundle(
      projectRoot: projectRoot,
      manifest: manifest,
      map: map,
    );
    final resolver = CharacterAnimationSourceResolver();
    final textures = <String, SpatialActorTexture>{};
    try {
      for (final entity in map.entities.where((entity) => entity.npc != null)) {
        final actor = manifest.characters
            .where((actor) => actor.id == entity.npc!.characterId)
            .firstOrNull;
        if (actor == null) {
          throw StateError('Personnage du PNJ absent : ${entity.name}');
        }
        final animation =
            actor.animations
                .where(
                  (clip) =>
                      clip.direction == entity.npc!.facing &&
                      clip.state == CharacterAnimationState.idle,
                )
                .firstOrNull ??
            actor.animations
                .where(
                  (clip) =>
                      clip.direction == entity.npc!.facing &&
                      clip.state == CharacterAnimationState.walk,
                )
                .firstOrNull;
        if (animation == null || animation.frames.isEmpty) {
          throw StateError('Animation du PNJ absente : ${entity.name}');
        }
        final asset = animation.sourceAssetId?.trim();
        final imageId = asset != null && asset.isNotEmpty
            ? characterAnimationRuntimeImageId(asset)
            : actor.tilesetId;
        if (!images.containsKey(imageId)) {
          final path = bundle.runtimeImageAbsolutePathsById[imageId];
          if (path == null) {
            throw StateError('Image du PNJ absente : ${entity.name}');
          }
          final codec = await ui.instantiateImageCodec(
            await File(path).readAsBytes(),
          );
          try {
            images[imageId] = (await codec.getNextFrame()).image;
          } finally {
            codec.dispose();
          }
          textures[imageId] = await SpatialActorTexture.fromImage(
            images[imageId]!,
          );
        }
        final source = resolver.resolveFrame(
          character: actor,
          animation: animation,
          frame: animation.frames.first,
          tileWidth: manifest.settings.tileWidth,
          tileHeight: manifest.settings.tileHeight,
          availableImageIds: images.keys.toSet(),
        );
        final image = images[imageId]!;
        if (source == null ||
            source.sourceRect.left < 0 ||
            source.sourceRect.top < 0 ||
            source.sourceRect.width <= 0 ||
            source.sourceRect.height <= 0 ||
            source.sourceRect.right > image.width ||
            source.sourceRect.bottom > image.height) {
          throw StateError('Frame du PNJ invalide : ${entity.name}');
        }
        final x = entity.pos.x + .5, z = entity.pos.y + .5;
        frames['npc:${entity.id}'] = SpatialActorVisual(
          x: x,
          y: map.spatialScene!.worldHeightAt(x, z),
          z: z,
          texture: textures[imageId]!,
          frame: source.sourceRect,
          contactShadow:
              actor.contactShadow ??
              manifest.settings.actorContactShadowsByDefault,
        );
      }
      return SpatialNpcPreview(frames, () {
        for (final image in images.values) {
          image.dispose();
        }
      });
    } on Object {
      for (final image in images.values) {
        image.dispose();
      }
      rethrow;
    }
  }

  Future<Uint8List> _readModel(String modelId) async {
    final model = manifest.models3d
        .where((item) => item.id == modelId)
        .firstOrNull;
    if (model == null) throw StateError('Modèle introuvable : $modelId');
    return readModelDefinition(model);
  }

  Future<Uint8List> _readModelDefinition(ProjectModel3dEntry model) async {
    final bytes = Uint8List.fromList(
      await const LocalProjectFileReader().readBytes(
        projectRoot: projectRoot,
        relativePath: model.relativePath,
      ),
    );
    await Isolate.run(() => const GlbModel3dInspector().inspect(bytes));
    return bytes;
  }
}
