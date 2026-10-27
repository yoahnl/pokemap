import 'dart:convert';

import 'package:map_core/map_core.dart';

import 'spatial_package_fixture.dart';

Map<String, List<int>> spatialFeaturePayload(String feature) {
  final files = spatialPayload();
  var project = ProjectManifest.fromJson(
      jsonDecode(utf8.decode(files['project/project.json']!)));
  if (feature == 'ladder') {
    final map = MapData.fromJson(
        jsonDecode(utf8.decode(files['project/maps/map.json']!)));
    files['project/maps/map.json'] =
        utf8.encode(jsonEncode(map.copyWith(warps: [
      MapWarp(
          id: 'stairs',
          pos: const GridPos(x: 1, y: 1),
          targetMapId: map.id,
          targetPos: const GridPos(x: 2, y: 1),
          ladder: MapWarpLadder())
    ]).toJson()));
  } else if (feature == 'cinematicConnected') {
    final map = MapData.fromJson(jsonDecode(utf8.decode(files['project/maps/map.json']!)));
    files['project/maps/map.json'] = utf8.encode(jsonEncode(map.copyWith(connections: [
      const MapConnection(direction: MapConnectionDirection.east, targetMapId: 'neighbor'),
    ]).toJson()));
    files['project/maps/neighbor.json'] = utf8.encode(jsonEncode(map.copyWith(
      id: 'neighbor', name: 'Neighbor',
      spatialScene: map.spatialScene!.copyWith(instances: []),
    ).toJson()));
    project = project.copyWith(maps: [...project.maps,
      const ProjectMapEntry(id: 'neighbor', name: 'Neighbor', relativePath: 'maps/neighbor.json'),
    ], cinematics: [
      CinematicAsset(id: 'connected', title: 'Connected', mapId: 'map',
        stageContext: CinematicStageContext(stagePoints: [
          CinematicStagePoint(id: 'outside', label: 'Outside', x: 8.5, y: 2.5),
        ]),
        timeline: CinematicTimeline(steps: [
          CinematicTimelineStep(id: 'wait', kind: CinematicTimelineStepKind.wait, durationMs: 20),
        ])),
    ]);
  } else if (feature == 'cinematicFade') {
    project = project.copyWith(cinematics: [
      CinematicAsset(id: 'fade', title: 'Fade', mapId: 'map',
        timeline: CinematicTimeline(steps: [
          CinematicTimelineStep(id: 'out', kind: CinematicTimelineStepKind.fade,
            durationMs: 200,
            metadata: const {cinematicTimelineFadeModeMetadataKey: 'fadeOut'}),
        ])),
    ]);
  } else if (feature == 'actorOcclusion') {
    final map = MapData.fromJson(jsonDecode(utf8.decode(files['project/maps/map.json']!)));
    project = project.copyWith(smartTileCatalog: ProjectSmartTileCatalog(
      atlases: const [ProjectSmartTileAtlas(id: 'grass-atlas', name: 'Grass', tilesetId: 'hero-atlas', columns: 1, rows: 1)],
      materials: const [ProjectSmartTileMaterial(id: 'grass', name: 'Grass', connectionGroupId: 'grass', pathSurfaceKind: PathSurfaceKind.tallGrass)],
      presets: [ProjectSmartTilePreset(id: 'grass', name: 'Grass', usage: SmartTileUsage.path,
        topology: SmartTileTopology.uniform, templateHint: SmartTileTemplateHint.simple,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        coverageProfile: const SmartTileCoverageProfile(mode: SmartTileCoverageMode.template),
        transformPolicy: const SmartTileTransformPolicy(), defaultMaterialId: 'grass', allowedMaterialIds: ['grass'],
        rules: [SmartTileRule(id: 'grass', centerMatch: const SmartTileSlotMatch.material('grass'),
          candidates: const [SmartTileCandidate(id: 'grass', parts: [SmartTileVisualPart(
            channel: SmartTileRenderChannel.actorOcclusion,
            source: SmartTileVisualSource.frame(frame: SmartTileFrameRef(atlasId: 'grass-atlas', column: 0, row: 0)),
          )])])])],
    ));
    files['project/maps/map.json'] = utf8.encode(jsonEncode(map.copyWith(layers: [
      ...map.layers, SmartTileLayer(id: 'grass', name: 'Grass', presetId: 'grass', usage: SmartTileUsage.path,
        materialPalette: const ['', 'grass'], field: SmartTileField.cell(semanticCells: [
          for (var i = 0; i < map.size.width * map.size.height; i++) i == 0 ? 1 : 0,
        ])),
    ]).toJson()));
  } else if (feature == 'camera') {
    final map = MapData.fromJson(
        jsonDecode(utf8.decode(files['project/maps/map.json']!)));
    files['project/maps/map.json'] = utf8.encode(jsonEncode(map
        .copyWith(
            spatialScene: map.spatialScene!.copyWith(
                camera: SpatialCameraProfile(
                    projection: SpatialCameraProjection.orthographic,
                    orthographicHeight: 12)))
        .toJson()));
  } else if (feature == 'companion') {
    project = project.copyWith(
      pokemon: project.pokemon.copyWith(enabled: true),
      partyCompanion:
          const ProjectPartyCompanionConfig(enabled: true, mappings: [
        PartyCompanionVisual(
            speciesId: 'clockbird', formId: 'bronze', characterId: 'hero')
      ]),
    );
    for (final entry in project.pokemon.catalogFiles.entries) {
      files['project/${entry.value}'] = utf8.encode(jsonEncode({
        'schemaVersion': 1,
        'catalog': entry.key,
        'entries': [
          if (entry.key == 'types') {'id': 'normal'},
          if (entry.key == 'abilities') {'id': 'calm'},
          if (entry.key == 'growth_rates') {'id': 'steady'},
        ],
      }));
    }
    files['project/data/pokemon/species/bronze-bird.json'] =
        utf8.encode(jsonEncode(const PokemonSpeciesFile(
      id: 'clockbird',
      slug: 'clockbird',
      nationalDex: 1,
      names: {'en': 'Clockbird'},
      speciesName: {'en': 'Clock Bird'},
      genIntroduced: 1,
      typing: PokemonSpeciesTyping(types: ['normal']),
      baseStats: PokemonSpeciesBaseStats(
          hp: 1, atk: 1, def: 1, spa: 1, spd: 1, spe: 1, bst: 6),
      abilities: PokemonSpeciesAbilities(primary: 'calm'),
      breeding: PokemonSpeciesBreeding(genderRatio: {}),
      progression: PokemonSpeciesProgression(
          growthRateId: 'steady',
          baseExp: 1,
          catchRate: 45,
          baseFriendship: 50),
      forms: PokemonSpeciesForms(
          baseFormId: 'clockbird', isBaseForm: true, formId: 'bronze'),
      refs: PokemonSpeciesRefs(
          learnset: 'clockbird', evolution: 'clockbird', media: 'clockbird'),
    ).toJson()));
    files['project/data/pokemon/learnsets/clockbird.json'] = utf8.encode(
        jsonEncode(const PokemonLearnsetFile(speciesId: 'clockbird').toJson()));
    files['project/data/pokemon/evolutions/clockbird.json'] = utf8.encode(
        jsonEncode(
            const PokemonEvolutionFile(speciesId: 'clockbird').toJson()));
    files['project/data/pokemon/media/clockbird.json'] = utf8.encode(jsonEncode(
        const PokemonMediaFile(
            speciesId: 'clockbird',
            defaultFormId: 'bronze',
            variants: {
          'bronze': PokemonMediaVariant(
              frontStatic: 'assets/hero.png', backStatic: 'assets/hero.png')
        }).toJson()));
  } else if (feature == 'contact') {
    project = project.copyWith(
      facts: [
        NarrativeFactDefinition(
            id: 'device-acquired', label: 'Device acquired'),
        NarrativeFactDefinition(id: 'mentor-known', label: 'Mentor known'),
      ],
      scenes: [featureScene('call'), featureScene('busy')],
      contactDevice: ProjectContactDeviceConfig(
        id: 'travel-device',
        label: 'Travel device',
        acquiredFactId: 'device-acquired',
        emptyMessage: 'No contacts',
        contacts: [
          ProjectContactEntryConfig(
              id: 'mentor',
              label: 'Mentor',
              registeredFactId: 'mentor-known',
              sceneId: 'call',
              unavailableSceneId: 'busy',
              characterId: 'hero')
        ],
      ),
    );
  } else if (feature == 'npcTrade') {
    project = project.copyWith(scenes: [
      featureScene('trade', command: SceneInteractiveCommand.openPartyTrade(
        npcOffer: NpcPokemonTradeOffer(id: 'fixed-offer', requestedSpeciesId: 'first',
          offeredPokemon: const PlayerPokemon(speciesId: 'second', natureId: 'hardy', abilityId: 'calm')))),
    ]);
  } else if (feature == 'audio' || feature == 'sceneMusic') {
    final sound = <int>[
      82,
      73,
      70,
      70,
      38,
      0,
      0,
      0,
      87,
      65,
      86,
      69,
      102,
      109,
      116,
      32,
      16,
      0,
      0,
      0,
      1,
      0,
      1,
      0,
      64,
      31,
      0,
      0,
      128,
      62,
      0,
      0,
      2,
      0,
      16,
      0,
      100,
      97,
      116,
      97,
      2,
      0,
      0,
      0,
      0,
      0
    ];
    files['project/assets/cue.wav'] = sound;
    final digest = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
          relativePath: 'artifact-content', bytes: sound),
    ]);
    files['project/assets/.pokemap-store/${digest.substring(7)}.blob'] = sound;
    final registry =
        jsonDecode(utf8.decode(files['project/assets/.pokemap-assets.json']!))
            as Map;
    (registry['records'] as List).add({
      'id': 'cue-source',
      'logicalPath': 'assets/cue.wav',
      'artifact': {
        'digest': digest,
        'handle': 'artifact://sha256/${digest.substring(7)}',
        'mediaType': 'audio/wav',
        'byteLength': sound.length
      },
      'usages': <String>[],
      'tags': <String>[],
    });
    files['project/assets/.pokemap-assets.json'] =
        utf8.encode(jsonEncode(registry));
    project = project.copyWith(
      cinematicMediaAssets: [
        CinematicMediaAsset(
            id: 'cue',
            label: 'Cue',
            kind: feature == 'sceneMusic' ? CinematicMediaAssetKind.music : CinematicMediaAssetKind.sound,
            relativePath: 'assets/cue.wav')
      ],
      scenes: [
        featureScene('sound',
            command: feature == 'sceneMusic' ? SceneInteractiveCommand.sceneMusic(operation: SceneMusicOperation.play, mediaAssetId: 'cue', volume: .7) : SceneInteractiveCommand.playSoundEffect(
                mediaAssetId: 'cue', volume: 1, waitForCompletion: true))
      ],
    );
  } else {
    throw ArgumentError.value(feature);
  }
  files['project/project.json'] = utf8.encode(jsonEncode(project.toJson()));
  return files;
}

SceneAsset featureScene(String id, {SceneInteractiveCommand? command}) =>
    SceneAsset(
      id: id,
      name: id,
      graph: SceneGraph(startNodeId: 'start', nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        if (command != null)
          SceneNode(
              id: 'action',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.interactive(command)),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ], edges: [
        SceneEdge(
            id: 'entry',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: command == null ? 'end' : 'action',
            kind: SceneEdgeKind.defaultFlow),
        if (command != null)
          for (final port in ['completed', 'blocked', 'cancelled'])
            SceneEdge(
                id: port,
                fromNodeId: 'action',
                fromPortId: port,
                toNodeId: 'end',
                kind: SceneEdgeKind.defaultFlow),
      ]),
    );
