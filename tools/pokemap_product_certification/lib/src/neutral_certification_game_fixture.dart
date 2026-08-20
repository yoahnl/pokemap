import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_editor/game_export.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

/// A deliberately non-Selbrume author project used only for product gates.
///
/// It is written as an author workspace, exported through `map_editor`, then
/// deleted before installation so the installed runtime cannot depend on it.
final class NeutralCertificationGameFixture {
  /// Writes two extra maps wired by warps when true. Off by default so the
  /// release artifact and the existing certifications keep their exact shape.
  const NeutralCertificationGameFixture({
    this.connectedMaps = false,
    this.partySize = 1,
    this.encounterField = false,
  }) : assert(partySize == 1 || partySize == 2 || partySize == 6);

  final bool connectedMaps;

  /// BETA-PTY-005 : la gate Party/PC exige deux membres — déposer l'unique
  /// Pokémon utilisable est refusé par la garde lastUsable. Un pour les autres
  /// gates, qui gardent leur forme exacte.
  final int partySize;

  /// BETA-ENC-006 : la gate rencontre → capture → Pokédex → stockage a besoin
  /// d'un terrain de rencontre entièrement déterministe PAR LES DONNÉES :
  /// une case d'herbe à 100 % de déclenchement, une seule espèce mono-niveau
  /// aux IVs figés (le maxHp du sauvage décide de l'issue du tirage de
  /// capture), et un sac de départ portant les deux Balls du scénario —
  /// la Poké Ball 1/1 dont l'échec est certain au seed générique du runtime,
  /// et une Ball 17/1 dont la réussite est une garantie mathématique
  /// (17 × 45 = 765, le plafond exact du dénominateur à PV pleins).
  /// Off par défaut : les gates existantes gardent leur forme exacte.
  final bool encounterField;

  static const String encounterTableId = 'certification_grass_table';
  static const String encounterZoneId = 'certification_grass_zone';
  static const String weakBallItemId = 'poke-ball';
  static const String guaranteedBallItemId = 'certification-ball';
  static const GridPos encounterCell = GridPos(x: 1, y: 2);
  static const String completionTriggerId = 'certification_corner_trigger';

  static const String fixedGameId = 'games.pokemap.certification.neutral';
  static const String fixedGameVersion = '1.0.0';
  static const String fixedMapId = 'neutral_harbor';
  static const String fixedSpawnId = 'neutral_spawn';
  static const String secondMapId = 'neutral_causeway';
  static const String thirdMapId = 'neutral_lighthouse';
  static const String secondSpawnId = 'neutral_causeway_spawn';
  static const String thirdSpawnId = 'neutral_lighthouse_spawn';

  String get gameId => fixedGameId;
  String get gameVersion => fixedGameVersion;
  String get mapId => fixedMapId;
  String get spawnId => fixedSpawnId;
  String get authorSecret => 'phase8-author-secret-must-never-ship';

  GamePackageExportProfile get exportProfile => GamePackageExportProfile(
    gameId: gameId,
    gameVersion: gameVersion,
    title: 'The Clockwork Harbor',
    description: 'A neutral PokeMap certification mini-game.',
    authorName: 'PokeMap Certification Studio',
    defaultLocale: 'en',
    supportedLocales: const <String>['en', 'fr'],
  );

  GamePackageHostCompatibility get hostCompatibility =>
      GamePackageHostCompatibility(
        hubVersion: Version.parse('1.2.0'),
        runtimeApiVersion: Version.parse('1.4.0'),
        capabilities: const <String>{
          'dialogue.choices@1',
          'map@1',
          'overworld.menu@1',
          'world.shop@1',
        },
        supportedProjectFormats: const <String>{'v6'},
        currentProjectFormat: 'v6',
        supportedSaveFormats: const <int>{1},
      );

  static MapData _linkedMap({
    required String id,
    required String name,
    required String spawnId,
    MapWarp? warp,
  }) =>
      MapData(
        id: id,
        name: name,
        version: ProjectVersion.v6,
        size: const GridSize(width: 4, height: 4),
        warps: warp == null ? const <MapWarp>[] : <MapWarp>[warp],
        entities: <MapEntity>[
          MapEntity(
            id: spawnId,
            name: '$name arrival',
            kind: MapEntityKind.spawn,
            pos: const GridPos(x: 1, y: 1),
            blocksMovement: false,
            spawn: const MapEntitySpawnData(
              role: EntitySpawnRole.playerStart,
              facing: EntityFacing.south,
            ),
          ),
        ],
        mapMetadata: MapMetadata(defaultSpawnId: spawnId),
      );

  Future<void> writeAuthorWorkspace(Directory root) async {
    await root.create(recursive: true);
    final manifest = ProjectManifest(
      name: 'The Clockwork Harbor',
      version: ProjectVersion.v6,
      maps: <ProjectMapEntry>[
        const ProjectMapEntry(
          id: fixedMapId,
          name: 'Clockwork Harbor',
          relativePath: 'maps/clockwork_harbor.json',
          role: MapRole.exterior,
        ),
        if (connectedMaps) ...const <ProjectMapEntry>[
          ProjectMapEntry(
            id: secondMapId,
            name: 'Neutral Causeway',
            relativePath: 'maps/neutral_causeway.json',
            role: MapRole.exterior,
          ),
          ProjectMapEntry(
            id: thirdMapId,
            name: 'Neutral Lighthouse',
            relativePath: 'maps/neutral_lighthouse.json',
            role: MapRole.interior,
          ),
        ],
      ],
      tilesets: const <ProjectTilesetEntry>[],
      encounterTables: encounterField
          ? <ProjectEncounterTable>[
              const ProjectEncounterTable(
                id: encounterTableId,
                name: 'Certification grass',
                encounterKind: EncounterKind.walk,
                chancePerStep: 1,
                entries: <ProjectEncounterEntry>[
                  // Ivysaur, PAS l'espèce du starter : le Pokédex de la gate
                  // doit discriminer « vu au combat fui » puis « capturé » —
                  // une espèce déjà possédée au départ ne prouverait rien.
                  ProjectEncounterEntry(
                    speciesId: 'ivysaur',
                    minLevel: 5,
                    maxLevel: 5,
                    pokemonOverrides: ProjectEncounterPokemonOverrides(
                      natureId: 'hardy',
                      abilityId: 'overgrow',
                      ivs: PokemonStatSpread(),
                      shinyPolicy: ProjectEncounterShinyPolicy.never,
                    ),
                  ),
                ],
              ),
            ]
          : const <ProjectEncounterTable>[],
      newGame: ProjectNewGameConfig(
        enabled: true,
        startMapId: fixedMapId,
        startSpawnId: fixedSpawnId,
        playerName: 'Ari',
        startingMoney: 300,
        initialParty: <PlayerPokemon>[
          const PlayerPokemon(
            speciesId: 'bulbasaur',
            natureId: 'hardy',
            abilityId: 'overgrow',
            level: 5,
            currentHp: 20,
          ),
          if (partySize > 1)
            const PlayerPokemon(
              speciesId: 'ivysaur',
              natureId: 'hardy',
              abilityId: 'overgrow',
              level: 7,
              currentHp: 22,
            ),
          // BETA-ENC-006 : la branche « party pleine -> PC » part d'une équipe
          // de six, en alternant les deux espèces du seed.
          for (var member = 2; member < partySize; member++)
            PlayerPokemon(
              speciesId: member.isEven ? 'bulbasaur' : 'ivysaur',
              natureId: 'hardy',
              abilityId: 'overgrow',
              level: 5 + member,
              currentHp: 18 + member,
            ),
        ],
        initialBag: encounterField
            ? const <BagEntry>[
                BagEntry(itemId: weakBallItemId, quantity: 1),
                BagEntry(itemId: guaranteedBallItemId, quantity: 1),
              ]
            : const <BagEntry>[],
      ),
      scenes: <SceneAsset>[_completionScene],
      // BETA-ENC-006 : le déclencheur mapEnter de la scène de complétion finit
      // le jeu AU BOOT (surface completion, autorité bloquée) — la gate de
      // démarrage certifie exactement cela, mais un journey overworld doit y
      // échapper. L'export exige une fin ATTEIGNABLE : la scène migre alors
      // sur un trigger d'entrée de case que le journey ne visite jamais.
      eventRegistry: encounterField ? _cornerEventRegistry : _eventRegistry,
      globalProperties: <String, Object?>{
        'certificationFixture': true,
        'apiKey': authorSecret,
      },
    );
    final manifestJson = manifest.toJson();
    final settings = Map<String, Object?>.from(manifestJson['settings'] as Map);
    settings['mistralApiKey'] = authorSecret;
    manifestJson['settings'] = settings;
    await _writeJson(File(p.join(root.path, 'project.json')), manifestJson);

    final map = MapData(
      id: fixedMapId,
      name: 'Clockwork Harbor',
      version: ProjectVersion.v6,
      size: const GridSize(width: 4, height: 4),
      triggers: encounterField
          ? const <MapTrigger>[
              MapTrigger(
                id: completionTriggerId,
                name: 'Certification corner',
                type: TriggerType.event,
                area: MapRect(
                  pos: GridPos(x: 3, y: 3),
                  size: GridSize(width: 1, height: 1),
                ),
              ),
            ]
          : const <MapTrigger>[],
      gameplayZones: encounterField
          ? const <MapGameplayZone>[
              MapGameplayZone(
                id: encounterZoneId,
                name: 'Certification grass',
                kind: GameplayZoneKind.encounter,
                area: MapRect(
                  pos: encounterCell,
                  size: GridSize(width: 1, height: 1),
                ),
                encounter: EncounterZonePayload(
                  encounterTableId: encounterTableId,
                  encounterKind: EncounterKind.walk,
                ),
              ),
            ]
          : const <MapGameplayZone>[],
      warps: connectedMaps
          ? const <MapWarp>[
              MapWarp(
                id: 'warp_harbor_to_causeway',
                pos: GridPos(x: 2, y: 1),
                targetMapId: secondMapId,
                targetPos: GridPos(x: 1, y: 1),
              ),
            ]
          : const <MapWarp>[],
      entities: const <MapEntity>[
        MapEntity(
          id: fixedSpawnId,
          name: 'Player arrival',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: const MapMetadata(defaultSpawnId: fixedSpawnId),
    );
    await _writeJson(
      File(p.join(root.path, 'maps', 'clockwork_harbor.json')),
      map.toJson(),
    );
    if (connectedMaps) {
      await _writeJson(
        File(p.join(root.path, 'maps', 'neutral_causeway.json')),
        _linkedMap(
          id: secondMapId,
          name: 'Neutral Causeway',
          spawnId: secondSpawnId,
          warp: const MapWarp(
            id: 'warp_causeway_to_lighthouse',
            pos: GridPos(x: 2, y: 1),
            targetMapId: thirdMapId,
            targetPos: GridPos(x: 1, y: 1),
          ),
        ).toJson(),
      );
      await _writeJson(
        File(p.join(root.path, 'maps', 'neutral_lighthouse.json')),
        _linkedMap(
          id: thirdMapId,
          name: 'Neutral Lighthouse',
          spawnId: thirdSpawnId,
        ).toJson(),
      );
    }
    await _writePokemonCatalogsWithMinimalMedia(root);
    if (encounterField) {
      await _appendGuaranteedBallToItemCatalog(root);
    }
    await File(
      p.join(root.path, 'LICENSE.txt'),
    ).writeAsString('PokeMap neutral certification fixture.', flush: true);

    // These author-only artifacts must be dropped by the runtime projection.
    await File(
      p.join(root.path, 'runtime_host_launch_save.json'),
    ).writeAsString('{}', flush: true);
    await File(
      p.join(root.path, 'debug.log'),
    ).writeAsString(authorSecret, flush: true);
    final saves = Directory(p.join(root.path, 'saves'));
    await saves.create(recursive: true);
    await File(
      p.join(saves.path, 'slot.json'),
    ).writeAsString(authorSecret, flush: true);
  }

  Future<void> writeSpeciesCatalog(Directory root, {required int count}) async {
    if (count < 2 || count > 10000) {
      throw ArgumentError.value(count, 'count', 'must be between 2 and 10000');
    }
    final species = Directory(p.join(root.path, 'data', 'pokemon', 'species'));
    await species.create(recursive: true);
    await for (final entity in species.list()) {
      if (entity is File &&
          p.basename(entity.path).endsWith('-clockling.json')) {
        await entity.delete();
      }
    }
    final template =
        jsonDecode(
              await File(
                p.join(species.path, '0001-bulbasaur.json'),
              ).readAsString(),
            )
            as Map<String, dynamic>;
    for (var start = 2; start < count; start += 64) {
      final end = (start + 64).clamp(0, count);
      await Future.wait(<Future<void>>[
        for (var index = start; index < end; index++)
          _writeJson(
            File(
              p.join(
                species.path,
                '${index.toString().padLeft(4, '0')}-clockling.json',
              ),
            ),
            _speciesFromTemplate(template, index),
          ),
      ]);
    }
  }

  Future<GamePackageExportArtifact> export(
    Directory authorRoot,
    File outputFile,
  ) => const GamePackageExportService().exportToFile(
    projectRoot: authorRoot,
    profile: exportProfile,
    outputFile: outputFile,
  );

  /// La Ball 17/1 du scénario de capture garantie, déclarée DANS le catalogue
  /// projet seedé pour rester connue de la validation d'export et du runtime.
  Future<void> _appendGuaranteedBallToItemCatalog(Directory root) async {
    final itemsFile = File(
      p.join(root.path, 'data', 'pokemon', 'catalogs', 'items.json'),
    );
    final catalog =
        jsonDecode(await itemsFile.readAsString()) as Map<String, dynamic>;
    final entries = (catalog['entries'] as List).cast<Map<String, dynamic>>();
    final template = entries.singleWhere(
      (entry) => entry['id'] == weakBallItemId,
    );
    final guaranteedBall =
        jsonDecode(jsonEncode(template)) as Map<String, dynamic>;
    guaranteedBall['id'] = guaranteedBallItemId;
    guaranteedBall['displayName'] = 'Certification Ball';
    (guaranteedBall['capture'] as Map<String, dynamic>)
      ..['rateNumerator'] = 17
      ..['rateDenominator'] = 1;
    entries.add(guaranteedBall);
    await _writeJson(itemsFile, catalog);
  }

  Future<void> _writePokemonCatalogsWithMinimalMedia(Directory root) async {
    await SeedPokemonDemoDataUseCase(
      snapshotController: FilePokemonReadRepository(),
    ).execute(ProjectFileSystem(root.path));
    final imageBytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
      '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );
    for (final speciesId in const <String>['bulbasaur', 'ivysaur']) {
      final frontPath = 'assets/pokemon/sprites/$speciesId/front.png';
      final backPath = 'assets/pokemon/sprites/$speciesId/back.png';
      await _writeJson(
        File(p.join(root.path, 'data', 'pokemon', 'media', '$speciesId.json')),
        <String, Object?>{
          'schemaVersion': currentPokemonDataSchemaVersion,
          'speciesId': speciesId,
          'defaultFormId': 'base',
          'variants': <String, Object?>{
            'base': <String, Object?>{
              'frontStatic': frontPath,
              'backStatic': backPath,
            },
          },
        },
      );
      for (final relativePath in <String>[frontPath, backPath]) {
        final file = File(p.join(root.path, relativePath));
        await file.parent.create(recursive: true);
        await file.writeAsBytes(imageBytes, flush: true);
      }
    }
  }
}

final NarrativeEventRegistry _cornerEventRegistry = NarrativeEventRegistry(
  schemaVersion: 1,
  mode: EventSystemMode.v2Only,
  records: <NarrativeEventRecord>[
    NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: 'evt_019abcde-7000-7000-8000-000000000002',
        name: 'Corner completion',
        source: NarrativeEventSourceRef.triggerEnter(
          NeutralCertificationGameFixture.fixedMapId,
          NeutralCertificationGameFixture.completionTriggerId,
        ),
        conditions: const [],
        sceneId: 'scene.certification.complete',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: 0,
        order: 0,
      ),
      enabled: true,
    ),
  ],
  legacyClaims: const [],
);

final NarrativeEventRegistry _eventRegistry = NarrativeEventRegistry(
  schemaVersion: 1,
  mode: EventSystemMode.v2Only,
  records: <NarrativeEventRecord>[
    NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: 'evt_019abcde-7000-7000-8000-000000000001',
        name: 'Runtime start',
        source: NarrativeEventSourceRef.mapEnter(
          NeutralCertificationGameFixture.fixedMapId,
        ),
        conditions: const [],
        sceneId: 'scene.certification.complete',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: 0,
        order: 0,
      ),
      enabled: true,
    ),
  ],
  legacyClaims: const [],
);

final SceneAsset _completionScene = SceneAsset(
  id: 'scene.certification.complete',
  name: 'Certification journey',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: <SceneNode>[
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'finish',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.finishGame(
            endingId: 'ending.certification.complete',
            outcome: SceneGameCompletionOutcome.completed,
            result: SceneFinishGameResult(
              title: SceneLocalizedText(fallback: 'Adventure complete'),
              summary: SceneLocalizedText(
                fallback: 'The certification journey reached its ending.',
              ),
            ),
            postGamePolicy: ScenePostGamePolicy.returnToTitle,
          ),
        ),
      ),
      SceneNode(
        id: 'end',
        kind: SceneNodeKind.end,
        payload: SceneEndPayload(outcomePolicy: SceneOutcomePolicy.progression),
      ),
    ],
    edges: <SceneEdge>[
      SceneEdge(
        id: 'start-finish',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'finish',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'finish-end',
        fromNodeId: 'finish',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);

Map<String, Object?> _speciesFromTemplate(
  Map<String, dynamic> template,
  int index,
) {
  final species = jsonDecode(jsonEncode(template)) as Map<String, dynamic>;
  final speciesId = 'clockling_$index';
  species['id'] = speciesId;
  species['slug'] = 'clockling-$index';
  species['nationalDex'] = index + 1;
  species['names'] = <String, String>{
    'en': 'Clockling $index',
    'fr': 'Horlogre $index',
  };
  (species['forms']! as Map<String, dynamic>)['baseFormId'] = speciesId;
  return species;
}

Future<void> _writeJson(File file, Map<String, Object?> value) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(value),
    flush: true,
  );
}
