import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _mapId = 'p5_beta_validator_map';
const _spawnId = 'p5_beta_validator_spawn';
const _npcId = 'p5_beta_validator_trainer_npc';
const _trainerId = 'p5_beta_validator_trainer';
const _starterSpeciesId = 'p5_beta_validator_starter';
const _enemySpeciesId = 'p5_beta_validator_enemy';
const _starterMoveId = 'p5_beta_validator_starter_move';
const _enemyMoveId = 'p5_beta_validator_enemy_move';

void main() {
  group('validateBetaPlayability', () {
    test('accepts a minimal beta-ready project without blocking errors', () {
      // RESSERREMENT ASSUMÉ, BETA-SYS-005. Ce cas passait sans fournir de
      // verdict de cohérence des catalogues Pokémon, et obtenait pourtant un
      // rapport vide — un blanc-seing sur une question jamais posée. La gate
      // exige désormais qu'on la lui pose : `pokemonCatalogErrorCount: 0` veut
      // dire « évaluée, aucune erreur », ce qui n'est pas la même chose que
      // `null`, « pas évaluée ».
      final result = validateBetaPlayability(
        _manifest(),
        context: BetaPlayabilityValidationContext(
          pokemonCatalogErrorCount: 0,
          mapsById: <String, MapData>{_mapId: _map()},
          knownSpeciesIds: const <String>{_starterSpeciesId, _enemySpeciesId},
          knownMoveIds: const <String>{_starterMoveId, _enemyMoveId},
          initialPartySpeciesIds: const <String>{_starterSpeciesId},
          initialPartyMoveIds: const <String>{_starterMoveId},
          requiresCapture: true,
          hasCaptureItemSource: true,
        ),
      );

      expect(result.hasErrors, isFalse);
      expect(result.isPlayable, isTrue);
      expect(result.diagnostics, isEmpty);
    });

    test('refuses a project whose shop carries a blocking issue', () {
      // BETA-SYS-005. ShopStateValidator existait et n'était appelé que par le
      // contrôleur de simulation de l'éditeur : une boutique incohérente
      // passait l'export sans un mot, alors qu'elle bloque le parcours si le
      // joueur y achète une Poké Ball obligatoire.
      final diagnostics = _shopDiagnostics(
        _validateWithShops(
          shops: <ShopDefinition>[_shop(price: -5)],
          knownItemIds: const <String>{'poke-ball'},
        ),
      );

      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.message, contains('SHOP_STATE_INVALID_PRICE'));
      expect(
        diagnostics.single.severity,
        BetaPlayabilityDiagnosticSeverity.error,
      );
      expect(diagnostics.single.path, contains('shops.beta_shop'));
    });

    test('checks shop item references when the item catalog is provided', () {
      final diagnostics = _shopDiagnostics(
        _validateWithShops(
          shops: <ShopDefinition>[_shop(itemId: 'ghost-item')],
          knownItemIds: const <String>{'poke-ball'},
        ),
      );

      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.message, contains('SHOP_STATE_UNKNOWN_ITEM'));
    });

    test('suppresses item reference checks when the catalog is absent', () {
      // Le point délicat du lot. Sans catalogue, l'ensemble vide déclarerait
      // TOUTE référence d'objet inconnue : la gate perdrait sa crédibilité sur
      // un faux diagnostic par entrée de boutique. Les six contrôles
      // structurels tournent quand même, et le manque est nommé.
      final result = _validateWithShops(
        shops: <ShopDefinition>[_shop(itemId: 'ghost-item')],
        knownItemIds: null,
      );

      expect(_shopDiagnostics(result), isEmpty);
      expect(
        result.diagnostics.where(
          (diagnostic) =>
              diagnostic.kind ==
              BetaPlayabilityDiagnosticKind.shopItemReferencesNotEvaluated,
        ),
        hasLength(1),
      );
    });

    test('still catches a structural shop issue without the item catalog', () {
      // Le pendant du cas précédent : la suppression doit être chirurgicale, pas
      // un abandon. Un prix négatif ne dépend d'aucun catalogue.
      final diagnostics = _shopDiagnostics(
        _validateWithShops(
          shops: <ShopDefinition>[_shop(price: -5)],
          knownItemIds: null,
        ),
      );

      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.message, contains('SHOP_STATE_INVALID_PRICE'));
    });

    test('a project without shops is never asked about them', () {
      final result = _validateWithShops(
        shops: const <ShopDefinition>[],
        knownItemIds: null,
      );

      expect(_shopDiagnostics(result), isEmpty);
      expect(
        result.diagnostics.where(
          (diagnostic) =>
              diagnostic.kind ==
              BetaPlayabilityDiagnosticKind.shopItemReferencesNotEvaluated,
        ),
        isEmpty,
      );
    });

    test('refuses a project whose pokemon catalogs carry blocking errors', () {
      // BETA-SYS-005. Le validateur de cohérence existait et le chemin d'EXPORT
      // le consommait, mais le verdict de jouabilité lui-même l'ignorait : un
      // appelant de la gate pure obtenait un blanc-seing sur les catalogues.
      final result = _validateWithCoherence(errorCount: 3);
      final diagnostics = _coherenceDiagnostics(result);

      expect(diagnostics, hasLength(1));
      expect(
        diagnostics.single.kind,
        BetaPlayabilityDiagnosticKind.pokemonCatalogHasBlockingErrors,
      );
      expect(
        diagnostics.single.severity,
        BetaPlayabilityDiagnosticSeverity.error,
      );
      expect(diagnostics.single.message, contains('3'));
      expect(result.hasErrors, isTrue);
    });

    test('says so when the pokemon coherence was never evaluated', () {
      // Ne pas savoir n'est pas « tout va bien », et c'est ce silence qui a
      // laissé cinq validateurs de domaine hors de la gate sans que rien ne le
      // signale. Un avertissement plutôt qu'une erreur : l'appelant n'a pas
      // forcément accès au rapport, mais il doit lire que la question n'a pas
      // été posée.
      final diagnostics = _coherenceDiagnostics(
        _validateWithCoherence(errorCount: null),
      );

      expect(diagnostics, hasLength(1));
      expect(
        diagnostics.single.kind,
        BetaPlayabilityDiagnosticKind.pokemonCatalogCoherenceNotEvaluated,
      );
      expect(
        diagnostics.single.severity,
        BetaPlayabilityDiagnosticSeverity.warning,
      );
    });

    test('an evaluated catalog with zero errors says nothing', () {
      // Le contre-exemple : sans lui, un diagnostic permanent passerait pour
      // correct.
      expect(_coherenceDiagnostics(_validateWithCoherence(errorCount: 0)),
          isEmpty);
    });

    test('a project without pokemon is not asked about its catalogs', () {
      // Un projet qui n'active pas les Pokémon n'a pas de catalogues à valider :
      // l'avertissement « non évalué » y serait du bruit pur.
      final diagnostics = _coherenceDiagnostics(
        validateBetaPlayability(
          _manifest(pokemonEnabled: false),
          context: BetaPlayabilityValidationContext(
            mapsById: <String, MapData>{_mapId: _map()},
            knownSpeciesIds: const <String>{_starterSpeciesId},
            knownMoveIds: const <String>{_starterMoveId},
            initialPartySpeciesIds: const <String>{_starterSpeciesId},
            initialPartyMoveIds: const <String>{_starterMoveId},
          ),
        ),
      );

      expect(diagnostics, isEmpty);
    });

    test('validateNarrativeProject hands the item ids to the shop checks', () {
      // TRANSMISSION, distincte de l'application. Sans ce cas, le champ
      // knownItemIds du contexte serait inatteignable depuis l'entrée publique,
      // donc mort-né : aucun appelant de production ne pourrait jamais fournir
      // le catalogue, et la gate resterait bloquée sur « non vérifié » pour
      // toujours.
      final report = validateNarrativeProject(
        _manifest(shops: <ShopDefinition>[_shop(itemId: 'ghost-item')]),
        maps: <MapData>[_map()],
        knownSpeciesIds: const <String>{_starterSpeciesId, _enemySpeciesId},
        knownMoveIds: const <String>{_starterMoveId, _enemyMoveId},
        knownItemIds: const <String>{'poke-ball'},
      );

      expect(
        report.diagnostics.where(
          (diagnostic) =>
              diagnostic.message.contains('SHOP_STATE_UNKNOWN_ITEM'),
        ),
        hasLength(1),
      );
    });

    test('validateNarrativeProject hands the coherence count to the gate', () {
      // La TRANSMISSION, distincte de l'application : la gate peut savoir
      // refuser sans que personne ne lui donne le compte. Sans ce cas, couper le
      // passage dans narrative_project_validator laissait tout vert — mesuré.
      final report = validateNarrativeProject(
        _manifest(),
        maps: <MapData>[_map()],
        knownSpeciesIds: const <String>{_starterSpeciesId, _enemySpeciesId},
        knownMoveIds: const <String>{_starterMoveId, _enemyMoveId},
        pokemonCatalogErrorCount: 7,
      );

      expect(
        report.diagnostics.where(
          (diagnostic) => diagnostic.message.contains('7 blocking coherence'),
        ),
        hasLength(1),
      );
    });

    test('diagnoses a surf zone the move catalog cannot ever satisfy', () {
      // BETA-SYS-005. La gate validait maps, spawns, dresseurs, espèces,
      // starters, capture et sauvegarde — rien sur les capacités terrain, alors
      // que BETA-SYS-002 a fait de Surf la seule porte signée du parcours bêta.
      // Une zone d'eau exigeant Surf dans un projet dont le catalogue n'a pas la
      // capacité est infranchissable pour toujours, et ça passait sans un mot.
      final diagnostics = _fieldAbilityDiagnostics(
        _validateWithSurfMaps(<String, MapData>{_mapId: _mapWithSurfZone()}),
      );

      expect(diagnostics, hasLength(1));
      expect(
        diagnostics.single.severity,
        BetaPlayabilityDiagnosticSeverity.error,
      );
      expect(diagnostics.single.mapId, _mapId);
      expect(diagnostics.single.moveId, 'surf');
      expect(diagnostics.single.actionHint, contains('surf'));
    });

    test('accepts the same surf zone once the catalog carries the move', () {
      // Le contre-exemple, sans lequel un diagnostic permanent passerait pour
      // correct.
      final diagnostics = _fieldAbilityDiagnostics(
        _validateWithSurfMaps(
          <String, MapData>{_mapId: _mapWithSurfZone()},
          knownMoveIds: const <String>{_starterMoveId, _enemyMoveId, 'surf'},
        ),
      );

      expect(diagnostics, isEmpty);
    });

    test('says nothing when the move catalog is not authoritative', () {
      // Ne pas savoir n'est pas la même chose que savoir que c'est cassé. Un
      // projet dont le catalogue n'a pas été chargé ne doit pas être déclaré
      // injouable sur cette base.
      final diagnostics = _fieldAbilityDiagnostics(
        _validateWithSurfMaps(
          <String, MapData>{_mapId: _mapWithSurfZone()},
          moveCatalogIsAuthoritative: false,
        ),
      );

      expect(diagnostics, isEmpty);
    });

    test('reports one diagnostic per map, in a stable order', () {
      // Critère « deterministic report ». Les cartes viennent d'une Map, dont
      // l'ordre d'itération suit l'insertion : deux projets identiques rangés
      // différemment produiraient deux rapports différents, et un rapport de
      // gate qui change d'ordre est illisible en revue.
      final maps = <String, MapData>{
        'zeta_map': _mapWithSurfZone(id: 'zeta_map'),
        _mapId: _mapWithSurfZone(),
        'alpha_map': _mapWithSurfZone(id: 'alpha_map'),
      };

      final first = _fieldAbilityDiagnostics(_validateWithSurfMaps(maps));
      final reversed = _fieldAbilityDiagnostics(
        _validateWithSurfMaps(<String, MapData>{
          for (final key in maps.keys.toList().reversed) key: maps[key]!,
        }),
      );

      expect(first.map((diagnostic) => diagnostic.mapId).toList(), <String>[
        'alpha_map',
        _mapId,
        'zeta_map',
      ]);
      expect(
        reversed.map((diagnostic) => diagnostic.mapId).toList(),
        first.map((diagnostic) => diagnostic.mapId).toList(),
        reason: 'the report must not depend on how the maps were inserted',
      );
    });

    test('diagnoses an empty manifest map list', () {
      final result = validateBetaPlayability(
        const ProjectManifest(
          name: 'P5 Beta Validator Missing Maps',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
        ),
      );

      expect(result.hasErrors, isTrue);
      expect(result.diagnostics.single.kind,
          BetaPlayabilityDiagnosticKind.missingMap);
      expect(result.diagnostics.single.severity,
          BetaPlayabilityDiagnosticSeverity.error);
      expect(result.diagnostics.single.actionHint, isNotEmpty);
    });

    test('diagnoses a manifest map missing from mapsById', () {
      final result = validateBetaPlayability(_manifest());

      expect(
        _kinds(result),
        contains(BetaPlayabilityDiagnosticKind.missingMap),
      );
      final diagnostic = result.diagnostics.firstWhere(
        (diagnostic) =>
            diagnostic.kind == BetaPlayabilityDiagnosticKind.missingMap,
      );
      expect(diagnostic.mapId, _mapId);
      expect(diagnostic.path, 'mapsById.p5_beta_validator_map');
    });

    test('diagnoses an invalid default spawn id', () {
      final result = validateBetaPlayability(
        _manifest(),
        context: BetaPlayabilityValidationContext(
          mapsById: <String, MapData>{
            _mapId: _map(defaultSpawnId: 'missing_spawn'),
          },
          initialPartySpeciesIds: const <String>{_starterSpeciesId},
        ),
      );

      expect(
        _kinds(result),
        contains(BetaPlayabilityDiagnosticKind.invalidDefaultSpawn),
      );
      final diagnostic = result.diagnostics.firstWhere(
        (diagnostic) =>
            diagnostic.kind ==
            BetaPlayabilityDiagnosticKind.invalidDefaultSpawn,
      );
      expect(diagnostic.mapId, _mapId);
      expect(diagnostic.message, contains('missing_spawn'));
    });

    test('diagnoses a start map without a player spawn', () {
      final result = validateBetaPlayability(
        _manifest(),
        context: BetaPlayabilityValidationContext(
          mapsById: <String, MapData>{_mapId: _mapWithoutSpawn()},
          initialPartySpeciesIds: const <String>{_starterSpeciesId},
        ),
      );

      expect(
        _kinds(result),
        contains(BetaPlayabilityDiagnosticKind.missingPlayerSpawn),
      );
    });

    test('diagnoses an NPC trainer reference missing from the manifest', () {
      final result = validateBetaPlayability(
        _manifest(trainers: const <ProjectTrainerEntry>[]),
        context: BetaPlayabilityValidationContext(
          mapsById: <String, MapData>{_mapId: _map()},
          initialPartySpeciesIds: const <String>{_starterSpeciesId},
        ),
      );

      expect(
        _kinds(result),
        contains(BetaPlayabilityDiagnosticKind.missingTrainerReference),
      );
      final diagnostic = result.diagnostics.firstWhere(
        (diagnostic) =>
            diagnostic.kind ==
            BetaPlayabilityDiagnosticKind.missingTrainerReference,
      );
      expect(diagnostic.mapId, _mapId);
      expect(diagnostic.entityId, _npcId);
      expect(diagnostic.trainerId, _trainerId);
      expect(diagnostic.actionHint, contains('trainer'));
    });

    test('diagnoses a referenced trainer with an empty team', () {
      final result = validateBetaPlayability(
        _manifest(
          trainers: const <ProjectTrainerEntry>[
            ProjectTrainerEntry(
              id: _trainerId,
              name: 'P5 Beta Trainer',
              trainerClass: 'Runtime Tester',
            ),
          ],
        ),
        context: BetaPlayabilityValidationContext(
          mapsById: <String, MapData>{_mapId: _map()},
          initialPartySpeciesIds: const <String>{_starterSpeciesId},
        ),
      );

      expect(
        _kinds(result),
        contains(BetaPlayabilityDiagnosticKind.trainerHasEmptyTeam),
      );
    });

    test('diagnoses trainer pokemon species missing from known species', () {
      final result = validateBetaPlayability(
        _manifest(),
        context: BetaPlayabilityValidationContext(
          mapsById: <String, MapData>{_mapId: _map()},
          knownSpeciesIds: const <String>{_starterSpeciesId},
          knownMoveIds: const <String>{_enemyMoveId},
          initialPartySpeciesIds: const <String>{_starterSpeciesId},
        ),
      );

      final diagnostic = result.diagnostics.firstWhere(
        (diagnostic) =>
            diagnostic.kind ==
            BetaPlayabilityDiagnosticKind.missingPokemonSpecies,
      );
      expect(diagnostic.trainerId, _trainerId);
      expect(diagnostic.speciesId, _enemySpeciesId);
    });

    test('diagnoses trainer pokemon move missing from known moves', () {
      final result = validateBetaPlayability(
        _manifest(),
        context: BetaPlayabilityValidationContext(
          mapsById: <String, MapData>{_mapId: _map()},
          knownSpeciesIds: const <String>{_starterSpeciesId, _enemySpeciesId},
          knownMoveIds: const <String>{_starterMoveId},
          initialPartySpeciesIds: const <String>{_starterSpeciesId},
        ),
      );

      final diagnostic = result.diagnostics.firstWhere(
        (diagnostic) =>
            diagnostic.kind == BetaPlayabilityDiagnosticKind.missingPokemonMove,
      );
      expect(diagnostic.trainerId, _trainerId);
      expect(diagnostic.moveId, _enemyMoveId);
    });

    test('treats an explicitly empty Pokemon catalog as authoritative', () {
      final result = validateBetaPlayability(
        _manifest(),
        context: BetaPlayabilityValidationContext(
          mapsById: <String, MapData>{_mapId: _map()},
          speciesCatalogIsAuthoritative: true,
          moveCatalogIsAuthoritative: true,
          initialPartySpeciesIds: const <String>{_starterSpeciesId},
          initialPartyMoveIds: const <String>{_starterMoveId},
        ),
      );

      final missingSpecies = result.diagnostics
          .where(
            (diagnostic) =>
                diagnostic.kind ==
                BetaPlayabilityDiagnosticKind.missingPokemonSpecies,
          )
          .map((diagnostic) => diagnostic.speciesId)
          .toSet();
      final missingMoves = result.diagnostics
          .where(
            (diagnostic) =>
                diagnostic.kind ==
                BetaPlayabilityDiagnosticKind.missingPokemonMove,
          )
          .map((diagnostic) => diagnostic.moveId)
          .toSet();

      expect(missingSpecies, {_starterSpeciesId, _enemySpeciesId});
      expect(missingMoves, {_starterMoveId, _enemyMoveId});
    });

    test('warns honestly when no starter or initial party source is provided',
        () {
      final result = validateBetaPlayability(
        _manifest(),
        context: BetaPlayabilityValidationContext(
          mapsById: <String, MapData>{_mapId: _map()},
        ),
      );

      final diagnostic = result.diagnostics.firstWhere(
        (diagnostic) =>
            diagnostic.kind ==
            BetaPlayabilityDiagnosticKind.missingStarterOrInitialPartySource,
      );
      expect(diagnostic.severity, BetaPlayabilityDiagnosticSeverity.warning);
      expect(result.hasErrors, isFalse);
    });

    test('diagnoses capture and save-load prerequisites when requested', () {
      final result = validateBetaPlayability(
        _manifest(),
        context: BetaPlayabilityValidationContext(
          mapsById: <String, MapData>{_mapId: _map()},
          initialPartySpeciesIds: const <String>{_starterSpeciesId},
          requiresCapture: true,
          hasCaptureItemSource: false,
          hasSaveLoadSupport: false,
        ),
      );

      expect(
        _kinds(result),
        containsAll(<BetaPlayabilityDiagnosticKind>{
          BetaPlayabilityDiagnosticKind.missingCapturePrerequisite,
          BetaPlayabilityDiagnosticKind.missingSaveLoadPrerequisite,
        }),
      );
      expect(result.hasErrors, isTrue);
    });

    test('does not hardcode any Selbrume ids in diagnostics', () {
      final result = validateBetaPlayability(
        _manifest(trainers: const <ProjectTrainerEntry>[]),
        context: BetaPlayabilityValidationContext(
          mapsById: <String, MapData>{_mapId: _map()},
        ),
      );

      final text = result.diagnostics
          .map(
            (diagnostic) => <String?>[
              diagnostic.message,
              diagnostic.actionHint,
              diagnostic.mapId,
              diagnostic.entityId,
              diagnostic.trainerId,
              diagnostic.speciesId,
              diagnostic.moveId,
              diagnostic.path,
            ].whereType<String>().join(' '),
          )
          .join(' ')
          .toLowerCase();

      expect(text, isNot(contains('selbrume')));
    });
  });
}

Set<BetaPlayabilityDiagnosticKind> _kinds(
  BetaPlayabilityValidationResult result,
) {
  return result.diagnostics.map((diagnostic) => diagnostic.kind).toSet();
}

ProjectManifest _manifest({
  List<ProjectTrainerEntry>? trainers,
  bool pokemonEnabled = true,
  List<ShopDefinition> shops = const <ShopDefinition>[],
}) {
  return ProjectManifest(
    name: 'P5 Beta Validator Project',
    pokemon: ProjectPokemonConfig(
      ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      enabled: pokemonEnabled,
    ),
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'P5 Beta Validator Field',
        relativePath: 'maps/p5_beta_validator_map.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    trainers: trainers ?? <ProjectTrainerEntry>[_trainer()],
    shops: shops,
  );
}

/// Carte du parcours bêta portant une zone d'eau qui exige Surf.
MapData _mapWithSurfZone({String id = _mapId}) {
  final base = _map();
  return base.copyWith(
    id: id,
    gameplayZones: <MapGameplayZone>[
      const MapGameplayZone(
        id: 'water',
        name: 'Water',
        kind: GameplayZoneKind.movement,
        area: MapRect(
          pos: GridPos(x: 4, y: 4),
          size: GridSize(width: 1, height: 1),
        ),
        movement: MovementZonePayload(requiredMode: MovementMode.surf),
      ),
    ],
  );
}

ShopDefinition _shop({String itemId = 'poke-ball', int price = 200}) {
  return ShopDefinition(
    id: 'beta_shop',
    label: 'Beta Shop',
    entries: <ShopEntryDefinition>[
      ShopEntryDefinition(itemId: itemId, price: price),
    ],
  );
}

BetaPlayabilityValidationResult _validateWithShops({
  required List<ShopDefinition> shops,
  required Set<String>? knownItemIds,
}) {
  return validateBetaPlayability(
    _manifest(shops: shops),
    context: BetaPlayabilityValidationContext(
      pokemonCatalogErrorCount: 0,
      knownItemIds: knownItemIds,
      mapsById: <String, MapData>{_mapId: _map()},
      knownSpeciesIds: const <String>{_starterSpeciesId, _enemySpeciesId},
      knownMoveIds: const <String>{_starterMoveId, _enemyMoveId},
      initialPartySpeciesIds: const <String>{_starterSpeciesId},
      initialPartyMoveIds: const <String>{_starterMoveId},
    ),
  );
}

List<BetaPlayabilityDiagnostic> _shopDiagnostics(
  BetaPlayabilityValidationResult result,
) {
  return result.diagnostics
      .where(
        (diagnostic) =>
            diagnostic.kind == BetaPlayabilityDiagnosticKind.shopStateIssue,
      )
      .toList(growable: false);
}

BetaPlayabilityValidationResult _validateWithCoherence({
  required int? errorCount,
}) {
  return validateBetaPlayability(
    _manifest(),
    context: BetaPlayabilityValidationContext(
      pokemonCatalogErrorCount: errorCount,
      mapsById: <String, MapData>{_mapId: _map()},
      knownSpeciesIds: const <String>{_starterSpeciesId, _enemySpeciesId},
      knownMoveIds: const <String>{_starterMoveId, _enemyMoveId},
      initialPartySpeciesIds: const <String>{_starterSpeciesId},
      initialPartyMoveIds: const <String>{_starterMoveId},
    ),
  );
}

List<BetaPlayabilityDiagnostic> _coherenceDiagnostics(
  BetaPlayabilityValidationResult result,
) {
  const kinds = <BetaPlayabilityDiagnosticKind>{
    BetaPlayabilityDiagnosticKind.pokemonCatalogHasBlockingErrors,
    BetaPlayabilityDiagnosticKind.pokemonCatalogCoherenceNotEvaluated,
  };
  return result.diagnostics
      .where((diagnostic) => kinds.contains(diagnostic.kind))
      .toList(growable: false);
}

BetaPlayabilityValidationResult _validateWithSurfMaps(
  Map<String, MapData> maps, {
  Set<String> knownMoveIds = const <String>{_starterMoveId, _enemyMoveId},
  bool moveCatalogIsAuthoritative = true,
}) {
  return validateBetaPlayability(
    _manifest(),
    context: BetaPlayabilityValidationContext(
      mapsById: maps,
      knownSpeciesIds: const <String>{_starterSpeciesId, _enemySpeciesId},
      knownMoveIds: knownMoveIds,
      moveCatalogIsAuthoritative: moveCatalogIsAuthoritative,
      initialPartySpeciesIds: const <String>{_starterSpeciesId},
      initialPartyMoveIds: const <String>{_starterMoveId},
    ),
  );
}

List<BetaPlayabilityDiagnostic> _fieldAbilityDiagnostics(
  BetaPlayabilityValidationResult result,
) {
  return result.diagnostics
      .where(
        (diagnostic) =>
            diagnostic.kind ==
            BetaPlayabilityDiagnosticKind.missingFieldAbilityPrerequisite,
      )
      .toList(growable: false);
}

MapData _map({String? defaultSpawnId = _spawnId}) {
  return MapData(
    id: _mapId,
    name: 'P5 Beta Validator Field',
    size: const GridSize(width: 6, height: 6),
    entities: const <MapEntity>[
      MapEntity(
        id: _spawnId,
        name: 'P5 Beta Validator Spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 2, y: 2),
        spawn: MapEntitySpawnData(
          spawnKey: _spawnId,
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
      MapEntity(
        id: _npcId,
        name: 'P5 Beta Validator Trainer NPC',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 3, y: 2),
        npc: MapEntityNpcData(
          displayName: 'P5 Beta Trainer',
          trainerId: _trainerId,
        ),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: defaultSpawnId),
  );
}

MapData _mapWithoutSpawn() {
  return const MapData(
    id: _mapId,
    name: 'P5 Beta Validator Field',
    size: GridSize(width: 6, height: 6),
    entities: <MapEntity>[
      MapEntity(
        id: _npcId,
        name: 'P5 Beta Validator Trainer NPC',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 3, y: 2),
        npc: MapEntityNpcData(
          displayName: 'P5 Beta Trainer',
          trainerId: _trainerId,
        ),
      ),
    ],
  );
}

ProjectTrainerEntry _trainer() {
  return const ProjectTrainerEntry(
    id: _trainerId,
    name: 'P5 Beta Trainer',
    trainerClass: 'Runtime Tester',
    team: <ProjectTrainerPokemonEntry>[
      ProjectTrainerPokemonEntry(
        speciesId: _enemySpeciesId,
        level: 4,
        moves: <String>[_enemyMoveId],
      ),
    ],
  );
}
