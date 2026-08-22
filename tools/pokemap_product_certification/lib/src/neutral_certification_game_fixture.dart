import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
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
    this.trainerArena = false,
    this.economyTown = false,
    this.progressionArena = false,
    this.dialoguedPreSession = false,
  }) : assert(partySize == 1 || partySize == 2 || partySize == 6);

  final bool connectedMaps;

  /// BETA-CIN-083 : le parcours de presession dialogue vit en v7, parce que
  /// c'est la version qui porte les Presentations. Seul le MANIFESTE suit ce
  /// drapeau : les cartes restent en v6 dans un projet v7, exactement comme
  /// celles du vrai projet. Off par defaut, donc le paquet de release et
  /// toutes les gates existantes gardent leur forme exacte au bit pres.
  final bool dialoguedPreSession;

  ProjectVersion get projectVersion =>
      dialoguedPreSession ? ProjectVersion.v7 : ProjectVersion.v6;

  String get projectFormat => dialoguedPreSession ? 'v7' : 'v6';

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

  /// BETA-TRN-005 : la gate boss/rival a besoin d'une arène déterminée par
  /// les données — un rival récurrent battable au niveau de départ, un boss
  /// trop fort pour lui (la défaite du premier assaut est certaine) dont la
  /// victoire au retour, après l'XP du rival, débloque badge, flag et Surf.
  /// Off par défaut : les gates existantes gardent leur forme exacte.
  final bool trainerArena;

  /// BETA-ITM-008 : la gate économie a besoin d'une ville — l'arène du rival
  /// (la récompense de victoire porte des objets), une boutique à stock
  /// authoré, un ramassage d'objet par événement V2 (le canal production en
  /// mode v2Only), une CT compatible et un objet tenu porté au sac de départ.
  /// Implique l'arène. Off par défaut : les gates existantes gardent leur
  /// forme exacte.
  final bool economyTown;

  /// BETA-PRG-006 : la gate progression a besoin d'un lead à QUATRE attaques
  /// (chaque nouveau move force un prompt de remplacement), d'un learnset où
  /// deux moves tombent sur le grind (growl au 6, vine_whip au 7) et d'une
  /// évolution au niveau 7 — surcharges de DONNÉES par-dessus le seed, dans
  /// l'espace auteur de la fixture. Implique l'arène.
  final bool progressionArena;

  bool get _arenaEnabled => trainerArena || economyTown || progressionArena;

  bool get _actorTilesetEnabled => _arenaEnabled || dialoguedPreSession;

  static const String shopId = 'certification_shop';
  static const String machineItemId = 'certification-tm-growl';
  static const String heldItemId = 'certification-leftovers';
  static const String pickupItemId = 'super-potion';
  static const GridPos pickupCell = GridPos(x: 2, y: 3);
  static const String pickupTriggerId = 'certification_pickup_trigger';

  static const String rivalTrainerId = 'certification_rival';
  static const String bossTrainerId = 'certification_boss';
  static const String bossBadgeId = 'certification_tide_badge';
  static const String bossVictoryFlagId = 'story:certification_boss_beaten';
  static const GridPos rivalCell = GridPos(x: 0, y: 3);
  static const GridPos bossCell = GridPos(x: 3, y: 1);

  static const String encounterTableId = 'certification_grass_table';
  static const String encounterZoneId = 'certification_grass_zone';
  static const String weakBallItemId = 'poke-ball';
  static const String guaranteedBallItemId = 'certification-ball';
  static const GridPos encounterCell = GridPos(x: 1, y: 2);
  static const String completionTriggerId = 'certification_corner_trigger';

  static const String dawnKeeperCharacterId = 'keeper_dawn';
  static const String duskKeeperCharacterId = 'keeper_dusk';
  static const String actorTilesetId = 'certification_actor_tileset';
  static const String actorTilesetPath =
      'assets/tilesets/certification_actors.png';

  /// BETA-CIN-083 : les quatre medias du parcours dialogue.
  ///
  /// Les OCTETS sont de la graine, comme le tileset d'acteur ; les CLIPS qui
  /// les referencent sont authores par actions canoniques. La frontiere est
  /// deliberee : le risque nomme du ticket est une fixture qui contourne
  /// l'authoring, et c'est le parcours qui doit passer par les actions, pas la
  /// donnee de base. L'import transactionnel des medias est certifie ailleurs
  /// (BETA-CIN-029) et part d'un handle d'artefact local au transport, donc il
  /// ne peut pas vivre dans une sequence rejouee par les quatre.
  static const String backdropMediaId = 'media.tower_night';
  static const String backdropWideMediaId = 'media.tower_night_wide';
  static const String backdropTallMediaId = 'media.tower_night_tall';
  static const String lighthouseMusicMediaId = 'media.lighthouse_loop';

  static const List<_SeededMedia> _seededMedia = <_SeededMedia>[
    _SeededMedia(
      mediaId: backdropMediaId,
      label: 'La tour, composition partagee',
      kind: 'image',
      mediaType: 'image/png',
      container: 'png',
      codec: 'png',
      logicalPath: 'assets/presentation/images/tower_night.png',
      base64:
          'iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABLbSncAAAAG0lEQVR4nGNkGGjA'
          'yGgz0E5gZBz1Y9SPUT8G0A8AtOwCFmXCTsIAAAAASUVORK5CYII=',
      width: 24,
      height: 24,
    ),
    _SeededMedia(
      mediaId: backdropWideMediaId,
      label: 'La tour, cadrage paysage',
      kind: 'image',
      mediaType: 'image/png',
      container: 'png',
      codec: 'png',
      logicalPath: 'assets/presentation/images/tower_night_wide.png',
      base64:
          'iVBORw0KGgoAAAANSUhEUgAAACAAAAASCAIAAACIl0KCAAAAG0lEQVR4nGNkoBww'
          'MtoMtBMYGUf9GPVj1I8B9AMAwzMCTS9wU8UAAAAASUVORK5CYII=',
      width: 32,
      height: 18,
    ),
    _SeededMedia(
      mediaId: backdropTallMediaId,
      label: 'La tour, cadrage portrait',
      kind: 'image',
      mediaType: 'image/png',
      container: 'png',
      codec: 'png',
      logicalPath: 'assets/presentation/images/tower_night_tall.png',
      base64:
          'iVBORw0KGgoAAAANSUhEUgAAABIAAAAgCAIAAAD8GuqPAAAAGklEQVR4nGNkwAcY'
          'GW0G2gmMjKN+jPox6scA+gEAmn4CJfaXNe8AAAAASUVORK5CYII=',
      width: 18,
      height: 32,
    ),
    // La musique : une SEULE source, jamais de variante d'orientation. Le
    // schema du clip audio le refuse et le resolveur runtime l'ignore.
    _SeededMedia(
      mediaId: lighthouseMusicMediaId,
      label: 'Boucle du phare',
      kind: 'audio',
      mediaType: 'audio/ogg',
      container: 'ogg',
      codec: 'vorbis',
      logicalPath: 'assets/presentation/audio/lighthouse_loop.ogg',
      base64: 'T2dnUwAB',
    ),
  ];

  Future<void> _writeSeededMedia(Directory root) async {
    final store = Directory(p.join(root.path, 'assets', '.pokemap-store'));
    await store.create(recursive: true);
    final records = <Map<String, Object?>>[];
    final entries = <Map<String, Object?>>[];
    for (final media in _seededMedia) {
      final bytes = base64Decode(media.base64);
      // The fingerprint is a DOMAIN-FRAMED sha256, not a bare one, so it is
      // computed by the repository's own function rather than recomputed here:
      // a bare hash produces a blob the loader rejects as mismatched.
      final artifact = ContentArtifactRef.fromBytes(
        bytes,
        mediaType: media.mediaType,
      );
      await File(
        p.join(store.path, '${artifact.hexDigest}.blob'),
      ).writeAsBytes(bytes, flush: true);
      final assetId = 'asset.${media.mediaId}';
      records.add(<String, Object?>{
        'id': assetId,
        'logicalPath': media.logicalPath,
        'artifact': artifact.toJson(),
        'usages': const <Object?>[],
        'tags': const <String>['presentation'],
      });
      entries.add(<String, Object?>{
        'id': media.mediaId,
        'label': media.label,
        'kind': media.kind,
        'sourceAssetId': assetId,
        // La publication EXIGE une provenance authoree, et c'est justifie :
        // un paquet redistribuable doit pouvoir dire d'ou vient chaque media.
        // Ceux-ci sont generes par la fixture, donc rien de proprietaire.
        'provenance': const <String, Object?>{
          'source': 'Genere par la fixture de certification PokeMap',
          'creator': 'PokeMap Certification Studio',
        },
        'license': const <String, Object?>{
          'identifier': 'CC0-1.0',
          'name': 'Domaine public (media genere, aucune source tierce)',
        },
        'technicalMetadata': <String, Object?>{
          'mediaType': media.mediaType,
          'container': media.container,
          'codec': media.codec,
          'sizeBytes': bytes.length,
          if (media.width != null) 'width': media.width,
          if (media.height != null) 'height': media.height,
        },
      });
    }
    await _writeJson(
      File(p.join(root.path, 'assets', '.pokemap-assets.json')),
      <String, Object?>{'schemaVersion': 1, 'records': records},
    );
    await _writeJson(
      File(p.join(root.path, 'assets', '.pokemap-media.json')),
      <String, Object?>{'schemaVersion': 1, 'entries': entries},
    );
  }

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
        supportedProjectFormats: <String>{projectFormat},
        currentProjectFormat: projectFormat,
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
      version: projectVersion,
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
      tilesets: _actorTilesetEnabled
          ? const <ProjectTilesetEntry>[
              ProjectTilesetEntry(
                id: actorTilesetId,
                name: 'Certification actors',
                relativePath: actorTilesetPath,
              ),
            ]
          : const <ProjectTilesetEntry>[],
      characters: <ProjectCharacterEntry>[
        if (_arenaEnabled)
          const ProjectCharacterEntry(
            id: 'certification_actor',
            name: 'Certification actor',
            tilesetId: actorTilesetId,
          ),
        // BETA-CIN-083 : les deux silhouettes que le choix d'avatar propose.
        // Elles partagent le tileset d'acteur existant plutot que d'en
        // introduire un second — meme PNG, meme ecriture deterministe.
        if (dialoguedPreSession) ...const <ProjectCharacterEntry>[
          ProjectCharacterEntry(
            id: dawnKeeperCharacterId,
            name: 'Gardienne de l’aube',
            tilesetId: actorTilesetId,
          ),
          ProjectCharacterEntry(
            id: duskKeeperCharacterId,
            name: 'Gardien du crépuscule',
            tilesetId: actorTilesetId,
          ),
        ],
      ],
      dialogues: _arenaEnabled
          ? const <ProjectDialogueEntry>[
              ProjectDialogueEntry(
                id: 'dlg_certification_rival_pre',
                name: 'Rival pre-battle',
                relativePath: 'dialogues/certification_rival_pre.yarn',
              ),
              ProjectDialogueEntry(
                id: 'dlg_certification_rival_victory',
                name: 'Rival victory',
                relativePath: 'dialogues/certification_rival_victory.yarn',
              ),
              ProjectDialogueEntry(
                id: 'dlg_certification_boss_victory',
                name: 'Boss victory',
                relativePath: 'dialogues/certification_boss_victory.yarn',
              ),
            ]
          : const <ProjectDialogueEntry>[],
      badges: _arenaEnabled
          ? const <BadgeDefinition>[
              BadgeDefinition(
                id: bossBadgeId,
                label: 'Tide Badge',
                fieldAbilityUnlock: FieldAbility.surf,
              ),
            ]
          : const <BadgeDefinition>[],
      trainers: _arenaEnabled
          ? const <ProjectTrainerEntry>[
              ProjectTrainerEntry(
                id: rivalTrainerId,
                name: 'Rival Nao',
                trainerClass: 'Rival',
                templateKind: ProjectTrainerTemplateKind.rival,
                rematchPolicy: ProjectTrainerRematchPolicy.allowed,
                battleDifficulty: 1,
                moneyReward: 120,
                preBattleDialogueId: 'dlg_certification_rival_pre',
                victoryDialogueId: 'dlg_certification_rival_victory',
                rewardFlagIds: <String>['story:certification_rival_beaten'],
                rewardItemGrants: <ProjectTrainerItemGrant>[
                  ProjectTrainerItemGrant(itemId: 'antidote', quantity: 1),
                ],
                team: <ProjectTrainerPokemonEntry>[
                  ProjectTrainerPokemonEntry(
                    speciesId: 'bulbasaur',
                    level: 4,
                    moves: <String>['tackle'],
                  ),
                ],
              ),
              ProjectTrainerEntry(
                id: bossTrainerId,
                name: 'Harbormaster Sel',
                trainerClass: 'Gym Leader',
                templateKind: ProjectTrainerTemplateKind.gymLeader,
                battleDifficulty: 8,
                moneyReward: 600,
                victoryDialogueId: 'dlg_certification_boss_victory',
                rewardBadgeId: bossBadgeId,
                rewardFlagIds: <String>[bossVictoryFlagId],
                rewardFieldAbilityUnlock: FieldAbility.surf,
                team: <ProjectTrainerPokemonEntry>[
                  ProjectTrainerPokemonEntry(
                    speciesId: 'bulbasaur',
                    level: 6,
                    moves: <String>['tackle'],
                  ),
                ],
              ),
            ]
          : const <ProjectTrainerEntry>[],
      shops: economyTown
          ? const <ShopDefinition>[
              ShopDefinition(
                id: shopId,
                label: 'Échoppe du port',
                entries: <ShopEntryDefinition>[
                  ShopEntryDefinition(
                    itemId: 'potion',
                    price: 100,
                    sellPrice: 50,
                  ),
                  ShopEntryDefinition(
                    itemId: 'super-potion',
                    price: 250,
                    sellPrice: 125,
                  ),
                ],
              ),
            ]
          : const <ShopDefinition>[],
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
          PlayerPokemon(
            speciesId: 'bulbasaur',
            natureId: 'hardy',
            abilityId: 'overgrow',
            level: 5,
            currentHp: 20,
            // BETA-ITM-008 : growl est libre pour l'apprentissage par CT.
            knownMoveIds: economyTown
                ? const <String>['tackle']
                : progressionArena
                    ? const <String>[
                        'tackle',
                        'leer',
                        'quick_attack',
                        'tail_whip',
                      ]
                    : const <String>[],
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
            : economyTown
                ? const <BagEntry>[
                    BagEntry(itemId: 'potion', quantity: 4),
                    BagEntry(itemId: machineItemId, quantity: 1),
                    BagEntry(itemId: heldItemId, quantity: 1),
                  ]
                : trainerArena || progressionArena
                    ? const <BagEntry>[
                        BagEntry(itemId: 'potion', quantity: 4),
                      ]
                    : const <BagEntry>[],
        // BETA-CIN-083 : les deux silhouettes que le choix d'avatar du
        // parcours dialogue est autorise a proposer. Une option de choix
        // liee a avatarCharacterId doit etre declaree ici, sinon l'action
        // d'authoring la refuse — c'est la graine du projet, pas le parcours,
        // qui les declare, comme les especes et les objets des autres gates.
        playerAvatarCharacterIds: dialoguedPreSession
            ? const <String>[dawnKeeperCharacterId, duskKeeperCharacterId]
            : const <String>[],
      ),
      scenes: <SceneAsset>[
        _completionScene,
        if (economyTown) _pickupScene,
      ],
      // BETA-ENC-006 : le déclencheur mapEnter de la scène de complétion finit
      // le jeu AU BOOT (surface completion, autorité bloquée) — la gate de
      // démarrage certifie exactement cela, mais un journey overworld doit y
      // échapper. L'export exige une fin ATTEIGNABLE : la scène migre alors
      // sur un trigger d'entrée de case que le journey ne visite jamais.
      eventRegistry: economyTown
          ? _economyEventRegistry
          : encounterField || _arenaEnabled
              ? _cornerEventRegistry
              : _eventRegistry,
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
      triggers: <MapTrigger>[
        if (encounterField || _arenaEnabled)
          const MapTrigger(
            id: completionTriggerId,
            name: 'Certification corner',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 3, y: 3),
              size: GridSize(width: 1, height: 1),
            ),
          ),
        if (economyTown)
          const MapTrigger(
            id: pickupTriggerId,
            name: 'Certification pickup',
            type: TriggerType.event,
            area: MapRect(
              pos: pickupCell,
              size: GridSize(width: 1, height: 1),
            ),
          ),
      ],
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
      entities: <MapEntity>[
        const MapEntity(
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
        if (_arenaEnabled) ...const <MapEntity>[
          MapEntity(
            id: 'npc_certification_rival',
            name: 'Rival Nao',
            kind: MapEntityKind.npc,
            pos: rivalCell,
            blocksMovement: true,
            npc: MapEntityNpcData(
              displayName: 'Rival Nao',
              facing: EntityFacing.east,
              trainerId: rivalTrainerId,
              characterId: 'certification_actor',
              // En mode événementiel v2Only, l'interaction manuelle ne
              // retombe jamais sur le canal legacy : les dresseurs se
              // déclenchent par ligne de vue, comme en production.
              lineOfSightRange: 1,
            ),
          ),
          MapEntity(
            id: 'npc_certification_boss',
            name: 'Harbormaster Sel',
            kind: MapEntityKind.npc,
            pos: bossCell,
            blocksMovement: true,
            npc: MapEntityNpcData(
              displayName: 'Harbormaster Sel',
              facing: EntityFacing.west,
              trainerId: bossTrainerId,
              characterId: 'certification_actor',
              lineOfSightRange: 1,
            ),
          ),
        ],
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
    if (_arenaEnabled) {
      await _writeArenaDialogues(root);
    }
    if (_actorTilesetEnabled) {
      await _writeActorTileset(root);
    }
    if (dialoguedPreSession) {
      await _writeSeededMedia(root);
    }
    if (economyTown) {
      await _appendEconomyItemsToCatalog(root);
    }
    if (progressionArena) {
      await _overrideProgressionLearnsetAndEvolution(root);
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

  /// La CT growl (compatible learnset) et l'objet tenu à effet porté
  /// (leftovers) du parcours économie, déclarés DANS le catalogue projet.
  Future<void> _appendEconomyItemsToCatalog(Directory root) async {
    final itemsFile = File(
      p.join(root.path, 'data', 'pokemon', 'catalogs', 'items.json'),
    );
    final catalog =
        jsonDecode(await itemsFile.readAsString()) as Map<String, dynamic>;
    final entries = (catalog['entries'] as List).cast<Map<String, dynamic>>();
    entries.add(<String, Object?>{
      'id': machineItemId,
      'displayName': 'CT Grondement',
      'pocketId': 'machines',
      'tags': <String>['machine'],
      'machine': <String, Object?>{
        'moveId': 'growl',
        'kind': 'tm',
        'consumable': true,
      },
    });
    entries.add(<String, Object?>{
      'id': heldItemId,
      'displayName': 'Restes certifiés',
      'pocketId': 'held',
      'tags': <String>['held'],
      'heldEffectId': 'leftovers',
    });
    await _writeJson(itemsFile, catalog);
  }

  /// Surcharge le learnset et l'évolution du starter pour que le grind de la
  /// gate progression produise deux prompts d'apprentissage puis une
  /// proposition d'évolution — des données, pas du code.
  Future<void> _overrideProgressionLearnsetAndEvolution(Directory root) async {
    final learnsetFile = File(
      p.join(root.path, 'data', 'pokemon', 'learnsets', 'bulbasaur.json'),
    );
    final learnset =
        jsonDecode(await learnsetFile.readAsString()) as Map<String, dynamic>;
    learnset['levelUp'] = <Object?>[
      <String, Object?>{
        'moveId': 'tackle',
        'level': 1,
        'source': 'level_up',
        'versionGroup': 'demo',
      },
      <String, Object?>{
        'moveId': 'growl',
        'level': 6,
        'source': 'level_up',
        'versionGroup': 'demo',
      },
      <String, Object?>{
        'moveId': 'vine_whip',
        'level': 7,
        'source': 'level_up',
        'versionGroup': 'demo',
      },
    ];
    await _writeJson(learnsetFile, learnset);

    final evolutionFile = File(
      p.join(root.path, 'data', 'pokemon', 'evolutions', 'bulbasaur.json'),
    );
    final evolution =
        jsonDecode(await evolutionFile.readAsString()) as Map<String, dynamic>;
    final targets = (evolution['evolutions'] as List?)
        ?.cast<Map<String, dynamic>>();
    if (targets == null || targets.isEmpty) {
      throw StateError('The seed bulbasaur evolution file has no targets.');
    }
    targets.first['minLevel'] = 7;
    await _writeJson(evolutionFile, evolution);
  }

  Future<void> _writeActorTileset(Directory root) async {
    final file = File(p.join(root.path, actorTilesetPath));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
        '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
      flush: true,
    );
  }

  Future<void> _writeArenaDialogues(Directory root) async {
    final dialogues = Directory(p.join(root.path, 'dialogues'));
    await dialogues.create(recursive: true);
    const lines = <String, String>{
      'certification_rival_pre.yarn': 'On se mesure encore une fois ?',
      'certification_rival_victory.yarn': 'Bien joué… pour cette fois.',
      'certification_boss_victory.yarn':
          'Le port te reconnaît. Prends ce badge.',
    };
    for (final entry in lines.entries) {
      await File(p.join(dialogues.path, entry.key)).writeAsString(
        'title: Start\n---\n${entry.value}\n===\n',
        flush: true,
      );
    }
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

final NarrativeEventRegistry _economyEventRegistry = NarrativeEventRegistry(
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
    NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: 'evt_019abcde-7000-7000-8000-000000000003',
        name: 'Harbor pickup',
        source: NarrativeEventSourceRef.triggerEnter(
          NeutralCertificationGameFixture.fixedMapId,
          NeutralCertificationGameFixture.pickupTriggerId,
        ),
        conditions: const [],
        sceneId: 'scene.certification.pickup',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: 0,
        order: 1,
      ),
      enabled: true,
    ),
  ],
  legacyClaims: const [],
);

final SceneAsset _pickupScene = SceneAsset(
  id: 'scene.certification.pickup',
  name: 'Harbor pickup',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: <SceneNode>[
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'grant',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.giveItem(
            itemId: NeutralCertificationGameFixture.pickupItemId,
            quantity: 1,
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
        id: 'start-grant',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'grant',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'grant-end',
        fromNodeId: 'grant',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);

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

/// Un media seme : les octets et ce qu'il faut pour les declarer.
final class _SeededMedia {
  const _SeededMedia({
    required this.mediaId,
    required this.label,
    required this.kind,
    required this.mediaType,
    required this.container,
    required this.codec,
    required this.logicalPath,
    required this.base64,
    this.width,
    this.height,
  });

  final String mediaId;
  final String label;
  final String kind;
  final String mediaType;
  final String container;
  final String codec;
  final String logicalPath;
  final String base64;
  final int? width;
  final int? height;
}
