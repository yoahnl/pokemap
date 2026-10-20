import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

const _usage = 'dart run tool/generate_synthetic_catalog_project.dart '
    '--project-root <new-directory> --profile <new.json> --receipt <new.json> '
    '[--map-count 3] [--definition-count 32] [--atlas-count 4]';

Future<void> main(List<String> arguments) async {
  if (arguments.length == 1 && arguments.single == '--help') {
    stdout.writeln(_usage);
    return;
  }
  try {
    final values = <String, String>{};
    const allowed = {
      'project-root',
      'profile',
      'receipt',
      'map-count',
      'definition-count',
      'atlas-count',
    };
    for (var index = 0; index < arguments.length; index += 2) {
      final name = arguments[index];
      if (!name.startsWith('--') ||
          index + 1 >= arguments.length ||
          !allowed.contains(name.substring(2)) ||
          values.containsKey(name.substring(2))) {
        throw const FormatException(
            'Expected unique named options and values.');
      }
      values[name.substring(2)] = arguments[index + 1];
    }
    for (final key in ['project-root', 'profile', 'receipt']) {
      if (values[key]?.isNotEmpty != true) {
        throw FormatException('Missing --$key.');
      }
    }
    final report = await generateSyntheticCatalogProject(
        projectRoot: Directory(values['project-root']!),
        profileFile: File(values['profile']!),
        receiptFile: File(values['receipt']!),
        mapCount: int.parse(values['map-count'] ?? '3'),
        definitionCount: int.parse(values['definition-count'] ?? '32'),
        atlasCount: int.parse(values['atlas-count'] ?? '4'));
    stdout.writeln(jsonEncode({
      'status': 'generated',
      'kind': report['kind'],
      'parameters': report['parameters'],
      'sourceIdentitySha256': report['sourceIdentitySha256'],
      'totalBytes': report['totalBytes'],
      'receipt': p.normalize(p.absolute(values['receipt']!)),
    }));
  } on Object catch (error) {
    stderr.writeln('$error\n$_usage');
    exitCode = error is FormatException || error is ArgumentError ? 64 : 1;
  }
}

Future<Map<String, Object?>> generateSyntheticCatalogProject({
  required Directory projectRoot,
  required File profileFile,
  required File receiptFile,
  int mapCount = 3,
  int definitionCount = 32,
  int atlasCount = 4,
}) async {
  if (mapCount < 2 ||
      mapCount > 512 ||
      definitionCount < 1 ||
      definitionCount > 32768 ||
      atlasCount < 1 ||
      atlasCount > 64) {
    throw ArgumentError(
        'Require 2..512 maps, 1..32768 definitions, 1..64 atlases.');
  }
  final root = Directory(await _destinationPath(projectRoot.path));
  final profile = File(await _destinationPath(profileFile.path));
  final receipt = File(await _destinationPath(receiptFile.path));
  if (p.isWithin(root.path, profile.path) ||
      p.isWithin(root.path, receipt.path) ||
      p.equals(root.path, profile.path) ||
      p.equals(root.path, receipt.path) ||
      p.equals(profile.path, receipt.path)) {
    throw ArgumentError('Profile and receipt require distinct external paths.');
  }
  for (final path in [root.path, profile.path, receipt.path]) {
    if (await FileSystemEntity.type(path, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw FileSystemException('Destination already exists.', path);
    }
  }
  await root.create(recursive: true);
  final records = <AssetRecord>[];
  final tilesets = <ProjectTilesetEntry>[];
  Future<void> asset(String id, int size, int seed) async {
    final picture = image.Image(width: size, height: size, numChannels: 4);
    for (final pixel in picture) {
      pixel.setRgba(
          (seed * 37 + pixel.x ~/ 32 * 23) % 256,
          (seed * 71 + pixel.y ~/ 32 * 31) % 256,
          (seed * 19 + pixel.x % 32 + pixel.y % 32) % 256,
          255);
    }
    final bytes = image.encodePng(picture);
    final path = 'assets/$id.png';
    final artifact =
        ContentArtifactRef.fromBytes(bytes, mediaType: 'image/png');
    records.add(AssetRecord(
        id: '$id-image',
        logicalPath: path,
        artifact: artifact,
        usages: const ['tileset']));
    await _write(root, path, bytes);
    await _write(root, assetBlobStorageKey(artifact), bytes);
    tilesets.add(ProjectTilesetEntry(
        id: id,
        name: id,
        relativePath: path,
        source: ProjectTilesetSource.regularAtlas(
            assetId: '$id-image',
            pixelWidth: size,
            pixelHeight: size,
            tileWidth: 32,
            tileHeight: 32)));
  }

  for (var index = 0; index < atlasCount; index++) {
    await asset(_atlasId(index), 256, index + 1);
  }
  await asset('synthetic-player', 128, 257);
  final parameters = {
    'mapCount': mapCount,
    'definitionCount': definitionCount,
    'atlasCount': atlasCount,
    'mapWidth': 16,
    'mapHeight': 16,
    'atlasWidth': 256,
    'atlasHeight': 256,
  };
  final project = ProjectManifest(
      name: 'Synthetic catalog qualification',
      version: ProjectVersion.v8,
      maps: [
        for (var index = 0; index < mapCount; index++)
          ProjectMapEntry(
              id: _mapId(index),
              name: 'Synthetic map $index',
              relativePath: 'maps/${_mapId(index)}.json')
      ],
      tilesets: tilesets,
      elementCategories: const [
        ProjectElementCategory(
            id: 'synthetic-decor', name: 'Synthetic definitions')
      ],
      elements: [
        for (var index = 0; index < definitionCount; index++)
          ProjectElementEntry(
              id: _elementId(index),
              name: 'Synthetic definition $index',
              tilesetId: _atlasId(index % atlasCount),
              categoryId: 'synthetic-decor',
              frames: [
                TilesetVisualFrame(
                    source: TilesetSourceRect(
                        x: index ~/ atlasCount % 8,
                        y: index ~/ atlasCount ~/ 8 % 8,
                        width: 1,
                        height: 1))
              ])
      ],
      characters: [
        ProjectCharacterEntry(
            id: 'synthetic-player',
            name: 'Synthetic player',
            tilesetId: 'synthetic-player',
            frameWidth: 1,
            frameHeight: 1,
            animations: [
              for (var row = 0; row < EntityFacing.values.length; row++)
                CharacterAnimation(
                    state: CharacterAnimationState.walk,
                    direction: EntityFacing.values[row],
                    sourceAssetId: 'synthetic-player-image',
                    frames: [
                      for (var column = 0; column < 4; column++)
                        CharacterAnimationFrame(
                            source: TilesetSourceRect(
                                x: column * 32,
                                y: row * 32,
                                width: 32,
                                height: 32))
                    ])
            ])
      ],
      settings: const ProjectSettings(
          tileWidth: 32,
          tileHeight: 32,
          defaultPlayerCharacterId: 'synthetic-player'),
      pokemon: const ProjectPokemonConfig(
          enabled: false, ruleset: PokemonRulesetProfile.pokeMapBetaV1),
      newGame: ProjectNewGameConfig(
          enabled: true,
          startMapId: _mapId(0),
          startSpawnId: 'player-start',
          playerName: 'Synthetic player',
          playerAvatarCharacterIds: const ['synthetic-player']),
      dialogues: const [
        ProjectDialogueEntry(
            id: 'synthetic-welcome',
            name: 'Synthetic conversation',
            relativePath: 'dialogues/welcome.yarn',
            defaultStartNode: 'Start')
      ],
      facts: [
        NarrativeFactDefinition(
            id: 'fact.synthetic-conversation',
            label: 'Synthetic conversation completed')
      ],
      scenes: [_conversation(), _finish()],
      eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            _event('evt_019f0000-0000-7000-8000-000000000001', 'guide',
                'synthetic-conversation', NarrativeEventReusePolicy.reusable),
            _event('evt_019f0000-0000-7000-8000-000000000002', 'finish',
                'synthetic-finish', NarrativeEventReusePolicy.oneShot),
          ],
          legacyClaims: const []),
      globalProperties: {
        'syntheticQualification': {'version': 1, ...parameters}
      });
  await _write(root, assetCatalogStorageKey,
      utf8.encode(jsonEncode(AssetCatalog(records: records).toJson())));
  await _write(root, 'project.json', utf8.encode(jsonEncode(project.toJson())));
  await _write(
      root,
      'dialogues/welcome.yarn',
      utf8.encode(
          'title: Start\n---\nSynthetic conversation. Progress can be saved after this dialogue.\n===\n'));
  for (var index = 0; index < mapCount; index++) {
    final map = MapData(
        id: _mapId(index),
        name: 'Synthetic map $index',
        size: const GridSize(width: 16, height: 16),
        tilesetId: _atlasId(index % atlasCount),
        layers: [
          MapLayer.tile(
              id: 'ground',
              name: 'Ground',
              palette: [
                TileLayerPaletteEntry(
                    tilesetId: _atlasId(index % atlasCount), localTileId: 0)
              ],
              cells: List.filled(256, 1)),
          MapLayer.tile(id: 'decor', name: 'Decor', cells: List.filled(256, 0)),
          const MapLayer.object(id: 'events', name: 'Events')
        ],
        placedElements: [
          for (var item = 0; item < 2; item++)
            MapPlacedElement(
                id: 'decor-$item',
                layerId: 'decor',
                elementId: _elementId((index * 2 + item) % definitionCount),
                pos: GridPos(x: 5 + item, y: 5),
                applyCollision: false)
        ],
        mapMetadata: const MapMetadata(defaultSpawnId: 'player-start'),
        entities: [
          const MapEntity(
              id: 'player-start',
              name: 'Player start',
              kind: MapEntityKind.spawn,
              pos: GridPos(x: 2, y: 2),
              spawn: MapEntitySpawnData(
                  role: EntitySpawnRole.playerStart,
                  facing: EntityFacing.east)),
          if (index == 0) ...const [
            MapEntity(
                id: 'guide',
                name: 'Conversation',
                kind: MapEntityKind.custom,
                pos: GridPos(x: 3, y: 2),
                editorVisual: MapEntityEditorVisual(
                    elementId: 'synthetic-element-00000')),
            MapEntity(
                id: 'finish',
                name: 'Finish qualification',
                kind: MapEntityKind.custom,
                pos: GridPos(x: 12, y: 12),
                editorVisual: MapEntityEditorVisual(
                    elementId: 'synthetic-element-00000')),
          ]
        ],
        warps: [
          if (index + 1 < mapCount)
            MapWarp(
                id: 'next',
                pos: const GridPos(x: 14, y: 8),
                targetMapId: _mapId(index + 1),
                targetPos: const GridPos(x: 2, y: 8)),
          if (index > 0)
            MapWarp(
                id: 'previous',
                pos: const GridPos(x: 1, y: 8),
                targetMapId: _mapId(index - 1),
                targetPos: const GridPos(x: 13, y: 8))
        ]);
    await _write(root, project.maps[index].relativePath,
        utf8.encode(jsonEncode(map.toJson())));
  }
  final exportProfile = GamePackageExportProfile(
      gameId: 'games.avelune.synthetic-catalog-qualification',
      gameVersion: '0.1.0',
      title: 'Synthetic catalog qualification',
      authorName: 'Avelune qualification',
      defaultLocale: 'en',
      supportedLocales: const ['en']);
  await profile.parent.create(recursive: true);
  await profile.writeAsString('${jsonEncode(exportProfile.toJson())}\n',
      flush: true);
  final files = <Map<String, Object?>>[];
  await for (final entry in root.list(recursive: true, followLinks: false)) {
    if (entry is File) {
      files.add({
        'path': p.relative(entry.path, from: root.path),
        'bytes': await entry.length(),
        'sha256': (await sha256.bind(entry.openRead()).first).toString()
      });
    }
  }
  files.sort((a, b) => (a['path'] as String).compareTo(b['path'] as String));
  final report = <String, Object?>{
    'receiptVersion': 1,
    'kind': 'syntheticCatalogQualification',
    'parameters': parameters,
    'projectRoot': root.path,
    'profile': profile.path,
    'sourceIdentityAlgorithm':
        'sha256-json-sorted-file-path-bytes-sha256-records',
    'sourceIdentitySha256':
        sha256.convert(utf8.encode(jsonEncode(files))).toString(),
    'totalBytes':
        files.fold<int>(0, (total, file) => total + (file['bytes'] as int)),
    'files': files,
    'interaction': {
      'mapId': _mapId(0),
      'guideEntityId': 'guide',
      'factId': 'fact.synthetic-conversation',
      'dialogueId': 'synthetic-welcome',
      'finishEntityId': 'finish'
    },
  };
  await receipt.parent.create(recursive: true);
  await receipt.writeAsString('${jsonEncode(report)}\n', flush: true);
  return report;
}

Future<String> _destinationPath(String path) async {
  final absolute = p.normalize(p.absolute(path));
  var parent = p.dirname(absolute);
  final remaining = <String>[p.basename(absolute)];
  while (await FileSystemEntity.type(parent, followLinks: false) ==
      FileSystemEntityType.notFound) {
    remaining.insert(0, p.basename(parent));
    parent = p.dirname(parent);
  }
  final canonical = await Directory(parent).resolveSymbolicLinks();
  return p.joinAll([canonical, ...remaining]);
}

String _mapId(int index) => 'synthetic-map-${index.toString().padLeft(4, '0')}';
String _atlasId(int index) =>
    'synthetic-atlas-${index.toString().padLeft(3, '0')}';
String _elementId(int index) =>
    'synthetic-element-${index.toString().padLeft(5, '0')}';

Future<void> _write(Directory root, String path, List<int> bytes) async {
  final target = File(p.join(root.path, path));
  await target.parent.create(recursive: true);
  await target.writeAsBytes(bytes);
}

NarrativeEventRecord _event(String id, String entityId, String sceneId,
        NarrativeEventReusePolicy reuse) =>
    NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
            id: id,
            name: sceneId,
            source: NarrativeEventSourceRef.entityInteract(_mapId(0), entityId),
            conditions: const [],
            sceneId: sceneId,
            reusePolicy: reuse,
            priority: 0,
            order: entityId == 'guide' ? 0 : 1),
        enabled: true);

SceneAsset _conversation() => SceneAsset(
    id: 'synthetic-conversation',
    name: 'Synthetic conversation',
    graph: SceneGraph(startNodeId: 'start', nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
          id: 'dialogue',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(
              dialogueId: 'synthetic-welcome', yarnNodeName: 'Start')),
      SceneNode(
          id: 'remember',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(SceneConsequence.setFact(
              factId: 'fact.synthetic-conversation', value: true))),
      SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload:
              SceneEndPayload(outcomePolicy: SceneOutcomePolicy.progression)),
    ], edges: [
      SceneEdge(
          id: 'start-dialogue',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'dialogue',
          kind: SceneEdgeKind.defaultFlow),
      SceneEdge(
          id: 'dialogue-remember',
          fromNodeId: 'dialogue',
          fromPortId: 'completed',
          toNodeId: 'remember',
          kind: SceneEdgeKind.defaultFlow),
      SceneEdge(
          id: 'remember-end',
          fromNodeId: 'remember',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow),
    ]));

SceneAsset _finish() => SceneAsset(
    id: 'synthetic-finish',
    name: 'Finish synthetic qualification',
    graph: SceneGraph(startNodeId: 'start', nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
          id: 'finish',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(SceneConsequence.finishGame(
              endingId: 'synthetic-completed',
              outcome: SceneGameCompletionOutcome.completed,
              result: SceneFinishGameResult(
                  title: SceneLocalizedText(fallback: 'Completed'),
                  summary: SceneLocalizedText(
                      fallback: 'Synthetic qualification complete.')),
              postGamePolicy: ScenePostGamePolicy.returnToTitle))),
      SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload:
              SceneEndPayload(outcomePolicy: SceneOutcomePolicy.progression)),
    ], edges: [
      SceneEdge(
          id: 'start-finish',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'finish',
          kind: SceneEdgeKind.defaultFlow),
      SceneEdge(
          id: 'finish-end',
          fromNodeId: 'finish',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow),
    ]));
