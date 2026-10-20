import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

const _usage =
    'dart run tool/generate_double_battle_qualification_project.dart '
    '--project-root <new-directory> --profile <new.json> --receipt <new.json>';
const _mapId = 'qa-arena';
const _speciesIds = ['qa_orb_1', 'qa_orb_2', 'qa_orb_3', 'qa_orb_4'];
const _playerNames = ['Alpha', 'Bravo', 'Charlie', 'Delta'];

Future<void> main(List<String> arguments) async {
  if (arguments.length == 1 && arguments.single == '--help') {
    stdout.writeln(_usage);
    return;
  }
  try {
    final options = <String, String>{};
    for (var index = 0; index < arguments.length; index += 2) {
      final name = arguments[index];
      if (!const ['--project-root', '--profile', '--receipt'].contains(name) ||
          index + 1 >= arguments.length ||
          arguments[index + 1].isEmpty ||
          options.containsKey(name)) {
        throw const FormatException(
            'Expected unique named options and values.');
      }
      options[name] = arguments[index + 1];
    }
    if (options.length != 3) {
      throw const FormatException('Missing output paths.');
    }
    final report = await generateDoubleBattleQualificationProject(
        projectRoot: Directory(options['--project-root']!),
        profileFile: File(options['--profile']!),
        receiptFile: File(options['--receipt']!));
    stdout.writeln(jsonEncode(report));
  } on Object catch (error) {
    stderr.writeln('$error\n$_usage');
    exitCode = error is ArgumentError || error is FormatException ? 64 : 1;
  }
}

Future<Map<String, Object?>> generateDoubleBattleQualificationProject({
  required Directory projectRoot,
  required File profileFile,
  required File receiptFile,
}) async {
  final root = Directory(await _destination(projectRoot.path));
  final profile = File(await _destination(profileFile.path));
  final receipt = File(await _destination(receiptFile.path));
  if (p.equals(root.path, profile.path) ||
      p.equals(root.path, receipt.path) ||
      p.equals(profile.path, receipt.path) ||
      p.isWithin(root.path, profile.path) ||
      p.isWithin(root.path, receipt.path)) {
    throw ArgumentError('Profile and receipt require distinct external paths.');
  }
  for (final path in [root.path, profile.path, receipt.path]) {
    if (await FileSystemEntity.type(path, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw FileSystemException('Destination already exists.', path);
    }
  }
  final records = <AssetRecord>[];
  final artifacts = <NativeProjectCreationArtifact>[];
  void asset(String id, List<int> bytes, List<String> usages) {
    final reference =
        ContentArtifactRef.fromBytes(bytes, mediaType: 'image/png');
    records.add(AssetRecord(
        id: id,
        logicalPath: 'assets/$id.png',
        artifact: reference,
        usages: usages));
    artifacts
        .add(NativeProjectCreationArtifact(reference: reference, bytes: bytes));
  }

  asset('qa-ground', _ground(), ['tileset']);
  asset('qa-characters', _characters(), ['tileset', 'character']);
  for (var index = 0; index < _speciesIds.length; index++) {
    for (final back in [false, true]) {
      asset('${_speciesIds[index]}-${back ? 'back' : 'front'}',
          _orb(index, back: back), ['pokemon']);
    }
  }
  final project = ProjectManifest(
      name: 'Double battle qualification',
      version: ProjectVersion.v8,
      maps: const [
        ProjectMapEntry(
            id: _mapId,
            name: 'Qualification arena',
            relativePath: 'maps/arena.json')
      ],
      tilesets: const [
        ProjectTilesetEntry(
            id: 'qa-ground',
            name: 'Neutral arena',
            relativePath: 'assets/qa-ground.png',
            source: ProjectTilesetSource.regularAtlas(
                assetId: 'qa-ground',
                pixelWidth: 64,
                pixelHeight: 32,
                tileWidth: 32,
                tileHeight: 32)),
        ProjectTilesetEntry(
            id: 'qa-characters',
            name: 'Neutral characters',
            relativePath: 'assets/qa-characters.png',
            source: ProjectTilesetSource.regularAtlas(
                assetId: 'qa-characters',
                pixelWidth: 128,
                pixelHeight: 128,
                tileWidth: 32,
                tileHeight: 32))
      ],
      characters: [
        ProjectCharacterEntry(
            id: 'qa-player',
            name: 'Qualification actor',
            tilesetId: 'qa-characters',
            frameWidth: 1,
            frameHeight: 1,
            animations: [
              for (var row = 0; row < EntityFacing.values.length; row++)
                CharacterAnimation(
                    state: CharacterAnimationState.walk,
                    direction: EntityFacing.values[row],
                    sourceAssetId: 'qa-characters',
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
          tileWidth: 32, tileHeight: 32, defaultPlayerCharacterId: 'qa-player'),
      pokemon: const ProjectPokemonConfig(
          enabled: true, ruleset: PokemonRulesetProfile.standardV1),
      newGame: ProjectNewGameConfig(
          enabled: true,
          startMapId: _mapId,
          startSpawnId: 'player-start',
          playerName: 'Qualification',
          playerAvatarCharacterIds: const ['qa-player'],
          startingMoney: 100,
          initialBag: const [
            BagEntry(itemId: 'qa_potion', quantity: 1),
            BagEntry(itemId: 'qa_ether', quantity: 1)
          ],
          initialParty: [
            for (var index = 0; index < 4; index++)
              PlayerPokemon(
                  speciesId: _speciesIds[index],
                  natureId: 'hardy',
                  abilityId: 'overgrow',
                  level: 20,
                  nickname: _playerNames[index],
                  currentHp: 22 + index * 10,
                  heldItemId: index == 0 ? 'qa_recovery_band' : '',
                  knownMoveIds: const [
                    'qa_strike',
                    'qa_wave'
                  ],
                  currentPpByMoveId: {
                    'qa_strike': 4 + index,
                    'qa_wave': 3 + index
                  })
          ],
          initialFacts: const {'qa.victory': false, 'qa.defeat': false}),
      trainers: [
        _trainer('qa-balanced', 'First doubles', 15, 'qa_tap'),
        _trainer('qa-overpower', 'Defeat doubles', 90, 'qa_burst')
      ],
      facts: [
        NarrativeFactDefinition(
            id: 'qa.victory', label: 'Doubles victory witnessed'),
        NarrativeFactDefinition(
            id: 'qa.defeat', label: 'Doubles defeat witnessed')
      ],
      dialogues: const [
        ProjectDialogueEntry(
            id: 'qa-instructions',
            name: 'Qualification instructions',
            relativePath: 'dialogues/instructions.yarn',
            defaultStartNode: 'Start')
      ],
      scenes: [
        _battleScene('qa-balanced', 'balanced'),
        _battleScene('qa-overpower', 'overpower'),
        _healScene(),
        _finishScene()
      ],
      eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          legacyClaims: const [],
          records: [
            for (final (index, entityId)
                in ['balanced', 'overpower', 'healer', 'finish'].indexed)
              NarrativeEventRecord.configuredStructurallyUnchecked(
                  NarrativeEventDefinition(
                      id: 'evt_019f0000-0000-7000-8000-00000000001${index + 1}',
                      name: entityId,
                      source: NarrativeEventSourceRef.entityInteract(
                          _mapId, entityId),
                      conditions: const [],
                      sceneId:
                          entityId == 'healer' ? 'qa-heal' : 'qa-$entityId',
                      reusePolicy: NarrativeEventReusePolicy.reusable,
                      priority: 0,
                      order: index),
                  enabled: true)
          ]),
      globalProperties: const {
        'qualification': {
          'kind': 'doubleBattle',
          'version': 1,
          'activePerSide': 2,
          'trainersPerSide': 1
        }
      });
  final map = MapData(
      id: _mapId,
      name: 'Qualification arena',
      size: const GridSize(width: 12, height: 10),
      tilesetId: 'qa-ground',
      layers: [
        MapLayer.tile(id: 'ground', name: 'Ground', palette: const [
          TileLayerPaletteEntry(tilesetId: 'qa-ground', localTileId: 0),
          TileLayerPaletteEntry(tilesetId: 'qa-ground', localTileId: 1)
        ], cells: [
          for (var y = 0; y < 10; y++)
            for (var x = 0; x < 12; x++)
              x == 0 || x == 11 || y == 0 || y == 9 ? 2 : 1
        ]),
        const MapLayer.object(id: 'events', name: 'Actors')
      ],
      mapMetadata: const MapMetadata(defaultSpawnId: 'player-start'),
      entities: [
        const MapEntity(
            id: 'player-start',
            name: 'Player start',
            kind: MapEntityKind.spawn,
            pos: GridPos(x: 3, y: 5),
            spawn: MapEntitySpawnData(
                role: EntitySpawnRole.playerStart, facing: EntityFacing.north)),
        for (final (index, id) in ['balanced', 'overpower', 'healer'].indexed)
          MapEntity(
              id: id,
              name: ['First doubles', 'Defeat doubles', 'Heal party'][index],
              kind: MapEntityKind.npc,
              pos: GridPos(x: 3 + index * 3, y: 3),
              npc: MapEntityNpcData(
                  displayName: [
                    'First doubles',
                    'Defeat doubles',
                    'Heal party'
                  ][index],
                  characterId: 'qa-player',
                  facing: EntityFacing.south,
                  trainerId: id == 'healer' ? null : 'qa-$id')),
        const MapEntity(
            id: 'finish',
            name: 'Finish qualification',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 9, y: 7),
            npc: MapEntityNpcData(
                displayName: 'Finish qualification', characterId: 'qa-player'))
      ]);
  const service = NativeProjectCreationService();
  final prepared = await service.prepare(NativeProjectCreationInput(
      manifest: project,
      maps: [map],
      assetCatalog: AssetCatalog(records: records),
      artifacts: artifacts,
      dialogueSources: const {
        'qa-instructions':
            'title: Start\n---\nLeft: first doubles. Middle: defeat doubles. Right: heal party.\nUse the single Potion, restore PP, change the second active member, then win.\nSave after battle. Heal explicitly before testing the strong trainer.\nAfter defeat, one member recovers to 1 HP; the others remain fainted.\nThere is no full heal or teleport. Use the healer explicitly.\nBottom right: finish qualification after saving your results.\n===\n'
      },
      itemCatalog: _items(),
      pokemonCatalogs: _catalogs(),
      species: [for (var index = 0; index < 4; index++) _species(index)],
      learnsets: [
        for (final id in _speciesIds)
          PokemonLearnsetFile(
              speciesId: id, startingMoves: const ['qa_strike', 'qa_wave'])
      ],
      evolutions: [
        for (final id in _speciesIds) PokemonEvolutionFile(speciesId: id)
      ],
      media: [
        for (final id in _speciesIds)
          PokemonMediaFile(speciesId: id, defaultFormId: 'base', variants: {
            'base': PokemonMediaVariant(
                frontStatic: 'assets/$id-front.png',
                backStatic: 'assets/$id-back.png',
                icon: 'assets/$id-front.png',
                party: 'assets/$id-front.png')
          })
      ]));
  await root.parent.create(recursive: true);
  final plan = await service.plan(
      prepared: prepared,
      parentPath: root.parent.path,
      folderName: p.basename(root.path));
  final creation = await service.publish(plan);
  final exportProfile = GamePackageExportProfile(
      gameId: 'games.avelune.double-battle-qualification',
      gameVersion: '0.2.0',
      title: project.name,
      authorName: 'Avelune qualification',
      defaultLocale: 'en',
      supportedLocales: const ['en']);
  await profile.parent.create(recursive: true);
  await profile.writeAsString('${jsonEncode(exportProfile.toJson())}\n',
      flush: true);
  final files = <Map<String, Object?>>[];
  await for (final file in root.list(recursive: true, followLinks: false)) {
    final relative = p.relative(file.path, from: root.path);
    if (file is! File || p.split(relative).first == '.pokemap') continue;
    files.add({
      'path': relative,
      'bytes': await file.length(),
      'sha256': (await sha256.bind(file.openRead()).first).toString()
    });
  }
  files.sort((a, b) => (a['path'] as String).compareTo(b['path'] as String));
  final report = <String, Object?>{
    'receiptVersion': 1,
    'kind': 'doubleBattleQualification',
    'projectRoot': root.path,
    'profile': profile.path,
    'creationActionId': creation.transactionReceipt.actionId,
    'creationInventoryFingerprint': prepared.inventoryFingerprint,
    'sourceIdentityAlgorithm':
        'sha256-json-sorted-file-path-bytes-sha256-records',
    'sourceIdentitySha256':
        sha256.convert(utf8.encode(jsonEncode(files))).toString(),
    'totalBytes':
        files.fold<int>(0, (total, file) => total + (file['bytes'] as int)),
    'files': files,
    'scenario': {
      'mapId': _mapId,
      'start': [3, 5],
      'balancedEntityId': 'balanced',
      'overpowerEntityId': 'overpower',
      'healerEntityId': 'healer',
      'finishEntityId': 'finish',
      'victoryFactId': 'qa.victory',
      'defeatFactId': 'qa.defeat',
      'playerLabels': _playerNames,
      'playerInitialHp': [22, 32, 42, 52],
      'activePerSide': 2,
      'playerPartySize': 4,
      'opponentPartySize': 4,
      'trainersPerSide': 1,
      'checks': [
        'New Game',
        'two actions before turn',
        'target choice',
        'single potion debit',
        'PP restore',
        'second slot voluntary switch',
        'enemy reserve',
        'victory individual writeback',
        'explicit heal',
        'two distinct forced replacements',
        'defeat continueScene with one member at 1 HP, others fainted, no full heal or teleport',
        'save then Continue'
      ]
    }
  };
  await receipt.parent.create(recursive: true);
  await receipt.writeAsString('${jsonEncode(report)}\n', flush: true);
  return report;
}

ProjectTrainerEntry _trainer(String id, String name, int level, String move) =>
    ProjectTrainerEntry(
        id: id,
        name: name,
        trainerClass: 'Qualification',
        battleFormat: BattleFormat.doubles,
        battleDifficulty: 1,
        characterId: 'qa-player',
        moneyReward: 1,
        team: [
          for (final species in _speciesIds)
            ProjectTrainerPokemonEntry(
                speciesId: species,
                level: level,
                moves: [move],
                natureId: 'hardy',
                abilityId: 'overgrow')
        ]);

SceneAsset _battleScene(String trainerId, String entityId) => SceneAsset(
    id: trainerId,
    name: trainerId,
    graph: SceneGraph(startNodeId: 'start', nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
          id: 'battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
              battleKind: 'trainer',
              trainerId: trainerId,
              npcEntityId: entityId,
              defeatRecovery: SceneBattleDefeatRecovery.continueScene,
              declaredOutcomes: const ['victory', 'defeat'])),
      for (final outcome in ['victory', 'defeat'])
        SceneNode(
            id: outcome,
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
                SceneConsequence.setFact(factId: 'qa.$outcome', value: true))),
      SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload:
              SceneEndPayload(outcomePolicy: SceneOutcomePolicy.progression))
    ], edges: [
      _edge('start-battle', 'start', 'battle'),
      for (final outcome in ['victory', 'defeat']) ...[
        SceneEdge(
            id: 'battle-$outcome',
            fromNodeId: 'battle',
            fromPortId: outcome,
            toNodeId: outcome,
            kind: outcome == 'victory'
                ? SceneEdgeKind.battleVictory
                : SceneEdgeKind.battleDefeat),
        _edge('$outcome-end', outcome, 'end')
      ]
    ]));

SceneAsset _healScene() => SceneAsset(
    id: 'qa-heal',
    name: 'Explicit party heal',
    graph: SceneGraph(startNodeId: 'start', nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
          id: 'heal',
          kind: SceneNodeKind.action,
          payload:
              SceneActionPayload.consequence(SceneConsequence.healParty())),
      SceneNode(
          id: 'instructions',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(
              dialogueId: 'qa-instructions', yarnNodeName: 'Start')),
      SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload:
              SceneEndPayload(outcomePolicy: SceneOutcomePolicy.progression))
    ], edges: [
      _edge('start-heal', 'start', 'heal'),
      _edge('heal-instructions', 'heal', 'instructions'),
      _edge('instructions-end', 'instructions', 'end')
    ]));

SceneEdge _edge(String id, String from, String to) => SceneEdge(
    id: id,
    fromNodeId: from,
    fromPortId: 'completed',
    toNodeId: to,
    kind: SceneEdgeKind.defaultFlow);

SceneAsset _finishScene() => SceneAsset(
    id: 'qa-finish',
    name: 'Finish qualification',
    graph: SceneGraph(startNodeId: 'start', nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
          id: 'finish',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(SceneConsequence.finishGame(
              endingId: 'qa-finished',
              outcome: SceneGameCompletionOutcome.completed,
              result: SceneFinishGameResult(
                  title:
                      SceneLocalizedText(fallback: 'Qualification completed'),
                  summary: SceneLocalizedText(
                      fallback: 'Doubles qualification finished.')),
              postGamePolicy: ScenePostGamePolicy.returnToTitle))),
      SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload:
              SceneEndPayload(outcomePolicy: SceneOutcomePolicy.progression))
    ], edges: [
      _edge('start-finish', 'start', 'finish'),
      _edge('finish-end', 'finish', 'end')
    ]));

ProjectItemCatalog _items() => ProjectItemCatalog(schemaVersion: 1, entries: [
      ProjectItemDefinition(
          id: 'qa_potion',
          displayName: 'Single Potion',
          pocketId: 'medicine',
          uses: [
            ProjectItemUseDefinition(
                contexts: {
                  ProjectItemUseContext.battle,
                  ProjectItemUseContext.overworld
                },
                target: ProjectItemTargetKind.partyMember,
                consumption: ProjectItemConsumptionPolicy.onApplied,
                effect: const ProjectItemEffectDefinition.healHp(
                    mode: ProjectItemAmountMode.flat, amount: 20))
          ]),
      ProjectItemDefinition(
          id: 'qa_ether',
          displayName: 'Single Ether',
          pocketId: 'medicine',
          uses: [
            ProjectItemUseDefinition(
                contexts: {
                  ProjectItemUseContext.battle,
                  ProjectItemUseContext.overworld
                },
                target: ProjectItemTargetKind.partyMove,
                consumption: ProjectItemConsumptionPolicy.onApplied,
                effect: const ProjectItemEffectDefinition.restorePp(
                    mode: ProjectItemAmountMode.flat, amount: 5))
          ]),
      const ProjectItemDefinition(
          id: 'qa_recovery_band',
          displayName: 'Recovery Band',
          pocketId: 'items',
          heldEffectId: 'leftovers')
    ]);

List<PokemonCatalogFile> _catalogs() => [
      _catalog('moves', [
        for (final (id, name, power, target) in [
          ('qa_strike', 'Focused strike', 55, 'normal'),
          ('qa_wave', 'Wide wave', 35, 'allAdjacentFoes'),
          ('qa_tap', 'Gentle tap', 20, 'normal'),
          ('qa_burst', 'Heavy wave', 250, 'allAdjacentFoes')
        ])
          {
            'id': id,
            'name': name,
            'names': {'en': name},
            'type': 'normal',
            'category': 'physical',
            'target': target,
            'basePower': power,
            'accuracy': {'kind': 'percent', 'value': 100},
            'pp': 20,
            'engineSupportLevel': 'structured_supported'
          }
      ]),
      _catalog('abilities', [
        {
          'id': 'overgrow',
          'name': 'Overgrow',
          'names': {'en': 'Overgrow'}
        }
      ]),
      _catalog('natures', [
        {
          'id': 'hardy',
          'name': 'Hardy',
          'names': {'en': 'Hardy'},
          'increasedStat': null,
          'decreasedStat': null
        }
      ]),
      _catalog('types', [
        {
          'id': 'normal',
          'name': 'Normal',
          'names': {'en': 'Normal'}
        }
      ]),
      _catalog('growth_rates', [
        {'id': 'medium_fast', 'name': 'Medium fast'}
      ])
    ];

PokemonCatalogFile _catalog(String id, List<Map<String, dynamic>> entries) =>
    PokemonCatalogFile(
        schemaVersion: 1,
        kind: 'pokemon_catalog',
        catalog: id,
        meta: const PokemonDataMeta(
            description: 'Neutral doubles qualification data'),
        entries: entries);

PokemonSpeciesFile _species(int index) {
  final id = _speciesIds[index];
  return PokemonSpeciesFile.fromJson({
    'schemaVersion': 1,
    'id': id,
    'slug': id,
    'nationalDex': index + 1,
    'names': {'en': 'Orb ${index + 1}'},
    'speciesName': {'en': 'Qualification orb'},
    'genIntroduced': 1,
    'typing': {
      'types': ['normal']
    },
    'baseStats': {
      'hp': 100,
      'atk': 100,
      'def': 80,
      'spa': 80,
      'spd': 80,
      'spe': 80 + index,
      'bst': 520 + index
    },
    'abilities': {'primary': 'overgrow'},
    'breeding': {
      'genderRatio': {'male': 0.5, 'female': 0.5},
      'eggGroups': ['undiscovered'],
      'hatchCycles': 20
    },
    'progression': {
      'growthRateId': 'medium_fast',
      'baseExp': 1,
      'catchRate': 45,
      'baseFriendship': 50
    },
    'refs': {'learnset': id, 'evolution': id, 'media': id},
    'forms': {'baseFormId': id, 'isBaseForm': true, 'formId': 'base'},
    'classification': {'isEnabledInProject': true}
  });
}

List<int> _ground() {
  final picture = image.Image(width: 64, height: 32, numChannels: 4);
  for (final pixel in picture) {
    final border = pixel.x >= 32;
    final line = pixel.x % 32 == 0 || pixel.y == 0;
    pixel.setRgba(
        border
            ? 50
            : line
                ? 125
                : 145,
        border
            ? 65
            : line
                ? 150
                : 174,
        border
            ? 90
            : line
                ? 165
                : 186,
        255);
  }
  return image.encodePng(picture);
}

List<int> _characters() {
  final picture = image.Image(width: 128, height: 128, numChannels: 4);
  for (var row = 0; row < 4; row++) {
    for (var column = 0; column < 4; column++) {
      final left = column * 32;
      final top = row * 32;
      image.fillRect(picture,
          x1: left + 9,
          y1: top + 5,
          x2: left + 22,
          y2: top + 15,
          color: image.ColorRgba8(235, 205, 170, 255));
      image.fillRect(picture,
          x1: left + 8,
          y1: top + 16,
          x2: left + 23,
          y2: top + 26,
          color: image.ColorRgba8(60, 90 + row * 20, 190, 255));
      image.fillRect(picture,
          x1: left + 10,
          y1: top + 27,
          x2: left + 14,
          y2: top + 30 - column % 2,
          color: image.ColorRgba8(35, 45, 70, 255));
      image.fillRect(picture,
          x1: left + 18,
          y1: top + 27,
          x2: left + 22,
          y2: top + 29 + column % 2,
          color: image.ColorRgba8(35, 45, 70, 255));
    }
  }
  return image.encodePng(picture);
}

List<int> _orb(int index, {required bool back}) {
  final picture = image.Image(width: 64, height: 64, numChannels: 4);
  final colors = [
    (80, 160, 220),
    (220, 140, 70),
    (120, 190, 100),
    (180, 100, 200)
  ];
  final (r, g, b) = colors[index];
  image.fillCircle(picture,
      x: 32, y: 34, radius: 23, color: image.ColorRgba8(r, g, b, 255));
  image.fillCircle(picture,
      x: 24, y: 23, radius: 6, color: image.ColorRgba8(240, 240, 245, 255));
  if (!back) {
    for (final x in [25, 40]) {
      image.fillCircle(picture,
          x: x, y: 33, radius: 3, color: image.ColorRgba8(25, 30, 45, 255));
    }
  }
  for (var mark = 0; mark <= index; mark++) {
    image.fillRect(picture,
        x1: 22 + mark * 6,
        y1: 47,
        x2: 25 + mark * 6,
        y2: 51,
        color: image.ColorRgba8(30, 40, 60, 255));
  }
  return image.encodePng(picture);
}

Future<String> _destination(String path) async {
  final absolute = p.normalize(p.absolute(path));
  var parent = p.dirname(absolute);
  final remaining = <String>[p.basename(absolute)];
  while (await FileSystemEntity.type(parent, followLinks: false) ==
      FileSystemEntityType.notFound) {
    remaining.insert(0, p.basename(parent));
    parent = p.dirname(parent);
  }
  return p
      .joinAll([await Directory(parent).resolveSymbolicLinks(), ...remaining]);
}
