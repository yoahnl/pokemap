import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';

import '../contracts/artifact_ref.dart';
import '../domains/assets/asset_store.dart';
import 'project_creation_atlas.dart';
import 'project_creation_contracts.dart';

final class ProjectCreationKit {
  const ProjectCreationKit(this.manifest, this.files);
  final ProjectManifest manifest;
  final Map<String, List<int>> files;
}

ProjectCreationKit buildProjectCreationKit(ProjectCreationRequest request) {
  request.validate();
  final playable = request.template == ProjectCreationTemplate.playable;
  final map = playable ? _map(request) : null;
  final manifest = ProjectManifest(
    name: request.name.trim(),
    maps: [
      if (map != null)
        ProjectMapEntry(
            id: map.id, name: map.name, relativePath: 'maps/first-map.json')
    ],
    tilesets: [
      if (playable)
        ProjectTilesetEntry(
            id: 'starter',
            name: 'Kit original Avelune',
            relativePath: 'assets/starter.png',
            source: ProjectTilesetSource.regularAtlas(
              assetId: 'starter',
              tileWidth: request.tileSize,
              tileHeight: request.tileSize,
              pixelWidth: request.tileSize * 16,
              pixelHeight: request.tileSize * 4,
            ))
    ],
    settings: ProjectSettings(
        tileWidth: request.tileSize,
        tileHeight: request.tileSize,
        defaultMapWidth: request.mapWidth,
        defaultMapHeight: request.mapHeight,
        defaultPlayerCharacterId: playable ? 'player' : null),
    pokemon: const ProjectPokemonConfig(
        enabled: false, ruleset: PokemonRulesetProfile.pokeMapBetaV1),
    characters: [if (playable) _character(request.tileSize)],
    newGame: playable
        ? const ProjectNewGameConfig(
            enabled: true,
            startMapId: 'first-map',
            startSpawnId: 'player-start',
            playerName: 'Joueur',
            playerAvatarCharacterIds: ['player'])
        : const ProjectNewGameConfig(),
  );
  ProjectValidator.validate(manifest, maps: [if (map != null) map]);
  if (map != null) MapValidator.validate(map, projectDialogueContext: manifest);
  const encoder = JsonEncoder.withIndent('  ');
  final atlas = playable ? createProjectStarterAtlas(request.tileSize) : null;
  final artifact = atlas == null
      ? null
      : ContentArtifactRef.fromBytes(atlas, mediaType: 'image/png');
  return ProjectCreationKit(manifest, {
    'project.json': utf8.encode(encoder.convert(manifest.toJson())),
    if (map != null)
      'maps/first-map.json': utf8.encode(encoder.convert(map.toJson())),
    if (atlas != null && artifact != null) ...{
      'assets/starter.png': atlas,
      assetBlobStorageKey(artifact): atlas,
      assetCatalogStorageKey:
          utf8.encode(encoder.convert(AssetCatalog(records: [
        AssetRecord(
            id: 'starter',
            logicalPath: 'assets/starter.png',
            artifact: artifact,
            usages: ['tileset:starter', 'character:player'],
            tags: ['avelune-original-starter'])
      ]).toJson())),
    },
  });
}

List<int>? buildProjectCreationPreviewPng(ProjectCreationRequest request) {
  request.validateGeometry();
  if (request.template == ProjectCreationTemplate.empty) return null;
  final map = _map(request);
  final tile = math.min(request.tileSize,
      math.min(640 ~/ request.mapWidth, 480 ~/ request.mapHeight));
  final atlas = image.copyResize(
      image.decodePng(
          Uint8List.fromList(createProjectStarterAtlas(request.tileSize)))!,
      width: tile * 16,
      height: tile * 4,
      interpolation: image.Interpolation.nearest);
  final output = image.Image(
      width: request.mapWidth * tile,
      height: request.mapHeight * tile,
      numChannels: 4);
  final ground = map.layers.first as TileLayer;
  for (var y = 0; y < request.mapHeight; y++) {
    for (var x = 0; x < request.mapWidth; x++) {
      final localId = ground
          .palette[ground.cells[y * request.mapWidth + x] - 1].localTileId;
      image.compositeImage(output, atlas,
          dstX: x * tile,
          dstY: y * tile,
          srcX: localId * tile,
          srcY: 0,
          srcW: tile,
          srcH: tile,
          dstW: tile,
          dstH: tile);
    }
  }
  final source = _character(tile).animations.first.frames.first.source;
  final spawn = map.entities.single.pos;
  image.compositeImage(output, atlas,
      dstX: spawn.x * tile - tile ~/ 2,
      dstY: (spawn.y - 1) * tile,
      srcX: source.x,
      srcY: source.y,
      srcW: source.width,
      srcH: source.height,
      dstW: source.width,
      dstH: source.height);
  return image.encodePng(output);
}

ProjectCharacterEntry _character(int tileSize) => ProjectCharacterEntry(
      id: 'player',
      name: 'Voyageur Avelune',
      tilesetId: 'starter',
      frameWidth: 2,
      frameHeight: 2,
      animations: [
        for (final state in [
          CharacterAnimationState.idle,
          CharacterAnimationState.walk
        ])
          for (final direction in EntityFacing.values)
            CharacterAnimation(
                state: state,
                direction: direction,
                sourceAssetId: 'starter',
                frames: [
                  for (var step = 0;
                      step < (state == CharacterAnimationState.walk ? 2 : 1);
                      step++)
                    CharacterAnimationFrame(
                        source: TilesetSourceRect(
                            x: (direction.index * 2 + step) * tileSize * 2,
                            y: tileSize * 2,
                            width: tileSize * 2,
                            height: tileSize * 2),
                        durationMs: 180)
                ])
      ],
    );

MapData _map(ProjectCreationRequest request) => MapData(
      id: 'first-map',
      name: 'Première carte',
      size: GridSize(width: request.mapWidth, height: request.mapHeight),
      tilesetId: 'starter',
      layers: [
        TileLayer(id: 'ground', name: 'Sol', palette: const [
          TileLayerPaletteEntry(tilesetId: 'starter', localTileId: 0),
          TileLayerPaletteEntry(tilesetId: 'starter', localTileId: 1)
        ], cells: [
          for (var y = 0; y < request.mapHeight; y++)
            for (var x = 0; x < request.mapWidth; x++)
              y == request.mapHeight ~/ 2 ? 2 : 1
        ]),
        TileLayer(
            id: 'decor',
            name: 'Décors',
            cells: List.filled(request.mapWidth * request.mapHeight, 0)),
        CollisionLayer(id: 'collision', name: 'Limites', collisions: [
          for (var y = 0; y < request.mapHeight; y++)
            for (var x = 0; x < request.mapWidth; x++)
              x == 0 ||
                  y == 0 ||
                  x == request.mapWidth - 1 ||
                  y == request.mapHeight - 1
        ]),
      ],
      entities: [
        MapEntity(
            id: 'player-start',
            name: 'Départ du joueur',
            kind: MapEntityKind.spawn,
            pos: GridPos(x: request.mapWidth ~/ 2, y: request.mapHeight ~/ 2),
            spawn: const MapEntitySpawnData(role: EntitySpawnRole.playerStart),
            blocksMovement: false)
      ],
    );
