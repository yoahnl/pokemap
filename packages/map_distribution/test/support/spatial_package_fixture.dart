import 'dart:convert';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'glb_fixture.dart';

Map<String, List<int>> spatialPayload({bool largeModel = false}) {
  final bytes = triangleGlb(edit: (json) {
    json['nodes'][0].remove('translation');
    json['nodes'][0].remove('scale');
    if (largeModel) json['extras'] = {'padding': 'x' * (1024 * 1024 + 1)};
  });
  final png = image.encodePng(image.Image(width: 32, height: 32));
  final records = <Map<String, Object?>>[];
  final payload = <String, List<int>>{};
  void asset(String id, String path, String mediaType, List<int> bytes) {
    final digest = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
          relativePath: 'artifact-content', bytes: bytes),
    ]);
    payload['project/$path'] = bytes;
    payload['project/assets/.pokemap-store/${digest.substring(7)}.blob'] =
        bytes;
    records.add({
      'id': id,
      'logicalPath': path,
      'artifact': {
        'digest': digest,
        'handle': 'artifact://sha256/${digest.substring(7)}',
        'mediaType': mediaType,
        'byteLength': bytes.length
      },
      'usages': <String>[],
      'tags': <String>[]
    });
  }

  asset(
      'model-source', 'assets/models3d/model.glb', 'model/gltf-binary', bytes);
  asset('hero-source', 'assets/hero.png', 'image/png', png);
  final project = ProjectManifest(
      name: 'Exploration',
      pokemon: const ProjectPokemonConfig(
          enabled: false, ruleset: PokemonRulesetProfile.pokeMapBetaV1),
      version: ProjectVersion.v9,
      settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
          defaultPlayerCharacterId: 'hero'),
      maps: [
        const ProjectMapEntry(
            id: 'map', name: 'Map', relativePath: 'maps/map.json')
      ],
      models3d: [
        ProjectModel3dEntry(
            id: 'model',
            name: 'Model',
            sourceAssetId: 'model-source',
            relativePath: 'assets/models3d/model.glb',
            inspection: const GlbModel3dInspector().inspect(bytes))
      ],
      tilesets: [
        const ProjectTilesetEntry(
            id: 'hero-atlas',
            name: 'Hero',
            relativePath: 'assets/hero.png',
            source: ProjectTilesetSource.regularAtlas(
                assetId: 'hero-source',
                pixelWidth: 32,
                pixelHeight: 32,
                tileWidth: 32,
                tileHeight: 32))
      ],
      characters: [
        ProjectCharacterEntry(
            id: 'hero',
            name: 'Hero',
            tilesetId: 'hero-atlas',
            animations: [
              for (final direction in [
                EntityFacing.north,
                EntityFacing.south,
                EntityFacing.east,
                EntityFacing.west
              ])
                CharacterAnimation(
                    state: CharacterAnimationState.walk,
                    direction: direction,
                    sourceAssetId: 'hero-source',
                    frames: [
                      const CharacterAnimationFrame(
                          source: TilesetSourceRect(
                              x: 0, y: 0, width: 32, height: 32))
                    ])
            ])
      ]);
  final map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v9,
      size: const GridSize(width: 8, height: 8),
      spatialScene: MapSpatialScene(
          width: 8,
          depth: 8,
          navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 6, z: 6)),
          instances: [
            SpatialModelInstance(
                id: 'placement',
                modelId: 'model',
                position: Model3dVector3.zero)
          ]));
  payload['project/project.json'] = utf8.encode(jsonEncode(project.toJson()));
  payload['project/maps/map.json'] = utf8.encode(jsonEncode(map.toJson()));
  payload['project/assets/.pokemap-assets.json'] =
      utf8.encode(jsonEncode({'schemaVersion': 1, 'records': records}));
  return payload;
}

GamePackageManifest spatialManifest(
        {List<String> capabilities = const ['map3d@1']}) =>
    const GamePackageManifestCodec().decodeJson({
      'packageFormat': 1,
      'gameId': 'games.example.exploration',
      'gameVersion': '0.1.0',
      'title': 'Exploration',
      'author': {'name': 'Example'},
      'compatibility': {
        'minHubVersion': '1.0.0',
        'runtimeApi': '>=1.0.0 <2.0.0',
        'projectFormat': 'v9',
        'saveFormat': 1,
        'compatibilityId': 'exploration',
        'requiredCapabilities': capabilities
      },
      'locales': {
        'default': 'fr',
        'supported': ['fr']
      },
      'content': {
        'fileCount': 1,
        'totalBytes': 1,
        'treeSha256': ContentTreeHasher.sha256Hex([
          GamePackageFileEntry(
              path: 'project/project.json', size: 1, sha256: '0' * 64)
        ]),
        'files': [
          {'path': 'project/project.json', 'size': 1, 'sha256': '0' * 64}
        ]
      },
    });
