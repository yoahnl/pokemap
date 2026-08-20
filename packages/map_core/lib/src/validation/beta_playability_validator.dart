import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/project_manifest.dart';
import '../models/project_trainer.dart';
import '../models/save_data.dart';
import 'player_roster_validation.dart';
import 'shop_state_validator.dart';

enum BetaPlayabilityDiagnosticSeverity {
  error,
  warning,
  info,
}

enum BetaPlayabilityDiagnosticKind {
  missingMap,
  missingStartMap,
  missingPlayerSpawn,
  invalidDefaultSpawn,
  missingTrainerReference,
  trainerHasEmptyTeam,
  trainerPokemonMissingSpecies,
  trainerPokemonMissingMoves,

  /// Deux dresseurs du manifest portent le même identifiant — le second
  /// écraserait silencieusement le premier à la résolution.
  duplicateTrainerId,

  /// L'équipe d'un dresseur dépasse les six membres du roster de combat.
  trainerTeamTooLarge,

  /// Le niveau d'un membre d'équipe sort des bornes du ruleset (1..maxLevel).
  trainerPokemonLevelOutOfBounds,

  /// L'objet tenu d'un membre n'existe pas dans le catalogue du projet — le
  /// runtime refuserait le lancement du combat, donc on bloque avant.
  trainerPokemonUnknownHeldItem,

  /// L'ability overridée d'un membre n'existe pas dans le catalogue.
  trainerPokemonUnknownAbility,

  /// Un membre référence une forme : la bêta ne les hydrate pas — la promesse
  /// authorée serait silencieusement ignorée en combat.
  trainerPokemonFormNotSupported,

  /// Des équipes référencent objets ou abilities mais les catalogues n'ont
  /// pas été fournis : la gate n'a pas pu se prononcer, ce qui n'est pas un
  /// blanc-seing.
  trainerReferencesNotEvaluated,
  missingPokemonSpecies,
  missingPokemonMove,
  missingStarterOrInitialPartySource,
  missingCapturePrerequisite,
  missingSaveLoadPrerequisite,

  /// Une carte exige une capacité terrain que le projet ne peut pas fournir.
  ///
  /// BETA-SYS-005. La gate validait maps, spawns, dresseurs, espèces, starters,
  /// capture et sauvegarde — mais rien sur les capacités terrain, alors que
  /// BETA-SYS-002 a fait de Surf la seule porte signée du parcours bêta. Une
  /// zone d'eau exigeant Surf dans un projet dont le catalogue n'a pas la
  /// capacité est infranchissable pour toujours, sans un mot.
  missingFieldAbilityPrerequisite,

  /// Les catalogues Pokémon du projet portent des erreurs bloquantes.
  ///
  /// BETA-SYS-005. Le validateur de cohérence existait et était consommé par le
  /// chemin d'EXPORT, mais pas par cette gate : un appelant qui invoquait la
  /// gate pure sans injecter le rapport obtenait un verdict optimiste.
  pokemonCatalogHasBlockingErrors,

  /// La cohérence des catalogues Pokémon n'a pas été évaluée.
  ///
  /// Distinct de « tout va bien ». Ne pas savoir devait être visible, sinon
  /// l'absence de composition restait indétectable — c'est exactement ce qui a
  /// laissé cinq validateurs de domaine hors de la gate.
  pokemonCatalogCoherenceNotEvaluated,

  /// Une boutique du projet porte un défaut qui bloque le parcours.
  ///
  /// BETA-SYS-005. ShopStateValidator existait et n'était appelé que par le
  /// contrôleur de simulation de l'éditeur : une boutique incohérente passait
  /// l'export sans un mot, alors qu'elle bloque le parcours si le joueur y
  /// achète une Poké Ball obligatoire.
  shopStateIssue,

  /// Les références d'objets des boutiques n'ont pas été vérifiées.
  ///
  /// La gate ne reçoit pas toujours le catalogue d'objets. Deux des huit
  /// contrôles de boutique en dépendent ; les six autres sont structurels et
  /// tournent quand même. Le manque est nommé plutôt que masqué.
  shopItemReferencesNotEvaluated,

  /// Le roster initial du projet est structurellement invalide.
  ///
  /// BETA-SYS-005. validatePlayerRoster n'avait AUCUN appelant dans tout le
  /// dépôt. La gate vérifiait déjà les RÉFÉRENCES du roster initial (espèce et
  /// capacité inconnues, via des ensembles), mais pas sa STRUCTURE : une party
  /// initiale de plus de six Pokémon passait l'authoring sans un mot et jetait
  /// un StateError au démarrage de la nouvelle partie — chez le joueur, pas
  /// chez l'auteur. Et une espèce vide disparaissait des ensembles, donc
  /// n'était jamais signalée.
  initialRosterStructurallyInvalid,

  /// La party initiale pleine rend tout choix de starter impossible.
  ///
  /// Mesuré sur new_game_state_builder : une party initiale de six avec des
  /// starters déclarés fait jeter starterPartyFull sur CHAQUE choix. Le projet
  /// est authorable et injouable.
  starterCannotJoinFullInitialParty,
}

class BetaPlayabilityDiagnostic {
  const BetaPlayabilityDiagnostic({
    required this.kind,
    required this.severity,
    required this.message,
    required this.actionHint,
    this.path,
    this.mapId,
    this.entityId,
    this.trainerId,
    this.speciesId,
    this.moveId,
  });

  final BetaPlayabilityDiagnosticKind kind;
  final BetaPlayabilityDiagnosticSeverity severity;
  final String message;
  final String actionHint;
  final String? path;
  final String? mapId;
  final String? entityId;
  final String? trainerId;
  final String? speciesId;
  final String? moveId;
}

class BetaPlayabilityValidationContext {
  const BetaPlayabilityValidationContext({
    this.mapsById = const <String, MapData>{},
    this.startMapId,
    this.knownSpeciesIds = const <String>{},
    this.knownMoveIds = const <String>{},
    this.speciesCatalogIsAuthoritative = false,
    this.moveCatalogIsAuthoritative = false,
    this.initialPartySpeciesIds = const <String>{},
    this.initialPartyMoveIds = const <String>{},
    this.requiresInitialParty = true,
    this.requiresTrainerBattle = true,
    this.requiresCapture = false,
    this.hasCaptureItemSource = false,
    this.requiresSaveLoad = true,
    this.hasSaveLoadSupport = true,
    this.pokemonCatalogErrorCount,
    this.knownItemIds,
    this.knownAbilityIds,
    this.initialParty = const <PlayerPokemon>[],
    this.starterOptionCount = 0,
  });

  final Map<String, MapData> mapsById;
  final String? startMapId;
  final Set<String> knownSpeciesIds;
  final Set<String> knownMoveIds;
  final bool speciesCatalogIsAuthoritative;
  final bool moveCatalogIsAuthoritative;
  final Set<String> initialPartySpeciesIds;
  final Set<String> initialPartyMoveIds;
  final bool requiresInitialParty;
  final bool requiresTrainerBattle;
  final bool requiresCapture;
  final bool hasCaptureItemSource;
  final bool requiresSaveLoad;
  final bool hasSaveLoadSupport;

  /// Nombre d'erreurs du rapport de cohérence des catalogues Pokémon.
  ///
  /// `null` signifie « non évalué », ce qui n'est PAS « aucune erreur » : la
  /// gate le dit alors explicitement au lieu de conclure que tout va bien.
  final int? pokemonCatalogErrorCount;

  /// Identifiants d'objets du projet, ou `null` quand ils n'ont pas été chargés.
  ///
  /// `null` n'est PAS l'ensemble vide : un ensemble vide déclarerait toute
  /// référence d'objet inconnue et produirait de faux diagnostics.
  final Set<String>? knownItemIds;

  /// Identifiants d'abilities du projet, même sémantique tri-état que
  /// [knownItemIds] — BETA-TRN-003.
  final Set<String>? knownAbilityIds;

  /// Roster initial du projet, tel que la nouvelle partie le construira.
  ///
  /// Distinct des ensembles [initialPartySpeciesIds] et [initialPartyMoveIds] :
  /// les ensembles suffisent aux contrôles de RÉFÉRENCES mais perdent la
  /// structure — le nombre de membres, et les espèces vides qu'un `trim`
  /// fait disparaître.
  final List<PlayerPokemon> initialParty;

  /// Nombre d'options de starter déclarées par le projet.
  final int starterOptionCount;
}

class BetaPlayabilityValidationResult {
  BetaPlayabilityValidationResult(
    Iterable<BetaPlayabilityDiagnostic> diagnostics,
  ) : diagnostics = List<BetaPlayabilityDiagnostic>.unmodifiable(diagnostics);

  final List<BetaPlayabilityDiagnostic> diagnostics;

  bool get hasErrors => diagnostics.any(
        (diagnostic) =>
            diagnostic.severity == BetaPlayabilityDiagnosticSeverity.error,
      );

  bool get isPlayable => !hasErrors;
}

BetaPlayabilityValidationResult validateBetaPlayability(
  ProjectManifest manifest, {
  BetaPlayabilityValidationContext context =
      const BetaPlayabilityValidationContext(),
}) {
  final diagnostics = <BetaPlayabilityDiagnostic>[];

  if (manifest.maps.isEmpty) {
    diagnostics.add(
      const BetaPlayabilityDiagnostic(
        kind: BetaPlayabilityDiagnosticKind.missingMap,
        severity: BetaPlayabilityDiagnosticSeverity.error,
        message: 'The project does not reference any playable map.',
        actionHint: 'Add at least one map to the project manifest.',
        path: 'manifest.maps',
      ),
    );
    return BetaPlayabilityValidationResult(diagnostics);
  }

  final knownSpeciesIds = _trimmedSet(context.knownSpeciesIds);
  final knownMoveIds = _trimmedSet(context.knownMoveIds);
  final manifestMapIds = manifest.maps
      .map((entry) => entry.id.trim())
      .where((id) => id.isNotEmpty)
      .toSet();
  final explicitStartMapId = context.startMapId?.trim();
  final startMapId = explicitStartMapId != null && explicitStartMapId.isNotEmpty
      ? explicitStartMapId
      : manifest.maps.first.id.trim();

  if (!manifestMapIds.contains(startMapId)) {
    diagnostics.add(
      BetaPlayabilityDiagnostic(
        kind: BetaPlayabilityDiagnosticKind.missingStartMap,
        severity: BetaPlayabilityDiagnosticSeverity.error,
        message: 'The requested start map "$startMapId" is not in the project.',
        actionHint: 'Choose an existing project map as the beta start map.',
        path: 'manifest.maps',
        mapId: startMapId,
      ),
    );
  }

  for (final mapEntry in manifest.maps) {
    final mapId = mapEntry.id.trim();
    if (mapId.isEmpty) {
      continue;
    }
    if (!context.mapsById.containsKey(mapId)) {
      diagnostics.add(
        BetaPlayabilityDiagnostic(
          kind: BetaPlayabilityDiagnosticKind.missingMap,
          severity: BetaPlayabilityDiagnosticSeverity.error,
          message: 'The map "$mapId" is referenced but was not provided.',
          actionHint:
              'Load or provide the map data referenced by the manifest.',
          path: 'mapsById.$mapId',
          mapId: mapId,
        ),
      );
    }
  }

  final startMap = context.mapsById[startMapId];
  if (startMap != null) {
    _validateStartMapSpawn(startMap, diagnostics);
  }

  _validateInitialParty(
    context,
    knownSpeciesIds: knownSpeciesIds,
    knownMoveIds: knownMoveIds,
    diagnostics: diagnostics,
  );

  _validateTrainers(
    manifest,
    context.mapsById.values,
    knownSpeciesIds: knownSpeciesIds,
    knownMoveIds: knownMoveIds,
    speciesCatalogIsAuthoritative: context.speciesCatalogIsAuthoritative,
    moveCatalogIsAuthoritative: context.moveCatalogIsAuthoritative,
    requiresTrainerBattle: context.requiresTrainerBattle,
    knownItemIds: context.knownItemIds,
    knownAbilityIds: context.knownAbilityIds,
    diagnostics: diagnostics,
  );

  if (context.requiresCapture && !context.hasCaptureItemSource) {
    diagnostics.add(
      const BetaPlayabilityDiagnostic(
        kind: BetaPlayabilityDiagnosticKind.missingCapturePrerequisite,
        severity: BetaPlayabilityDiagnosticSeverity.warning,
        message: 'Capture is required but no capture item source is declared.',
        actionHint:
            'Provide a minimal bag/capture item source before relying on wild capture.',
        path: 'beta.capture',
      ),
    );
  }

  _appendFieldAbilityPrerequisiteDiagnostics(context, diagnostics);
  _appendPokemonCatalogCoherenceDiagnostics(manifest, context, diagnostics);
  _appendShopStateDiagnostics(manifest, context, diagnostics);
  _appendInitialRosterDiagnostics(context, diagnostics);

  if (context.requiresSaveLoad && !context.hasSaveLoadSupport) {
    diagnostics.add(
      const BetaPlayabilityDiagnostic(
        kind: BetaPlayabilityDiagnosticKind.missingSaveLoadPrerequisite,
        severity: BetaPlayabilityDiagnosticSeverity.error,
        message: 'Save/load support is required but not available in context.',
        actionHint:
            'Wire the existing save/load repository or disable this beta requirement.',
        path: 'beta.saveLoad',
      ),
    );
  }

  return BetaPlayabilityValidationResult(diagnostics);
}

/// Structure du roster initial, composée depuis validatePlayerRoster.
///
/// Les RÉFÉRENCES (espèce ou capacité inconnues) restent au contrôle existant
/// de la gate, fondé sur les ensembles : le validateur roster est donc appelé
/// SANS catalogues, ce qui limite exprès sa contribution à la structure.
/// Lui passer les catalogues produirait un doublon par référence inconnue —
/// même défaut signalé deux fois sous deux codes.
void _appendInitialRosterDiagnostics(
  BetaPlayabilityValidationContext context,
  List<BetaPlayabilityDiagnostic> diagnostics,
) {
  if (context.initialParty.isEmpty) {
    return;
  }
  final issues = validatePlayerRoster(
    party: PlayerParty(members: context.initialParty),
    storage: const PokemonStorage(),
    knownSpeciesIds: null,
    knownMoveIds: null,
  );
  for (final issue in issues) {
    diagnostics.add(
      BetaPlayabilityDiagnostic(
        kind: BetaPlayabilityDiagnosticKind.initialRosterStructurallyInvalid,
        severity: BetaPlayabilityDiagnosticSeverity.error,
        message: '${issue.code.name}: ${issue.message}',
        actionHint:
            'Fix the new game initial party before shipping the beta slice.',
        path: issue.path,
      ),
    );
  }
  if (context.starterOptionCount > 0 &&
      context.initialParty.length >= maxPlayerPartySize) {
    diagnostics.add(
      const BetaPlayabilityDiagnostic(
        kind: BetaPlayabilityDiagnosticKind.starterCannotJoinFullInitialParty,
        severity: BetaPlayabilityDiagnosticSeverity.error,
        message: 'The initial party is already full, so every declared '
            'starter choice will fail at new game.',
        actionHint: 'Remove a member from the initial party or drop the '
            'starter options.',
        path: 'beta.initialParty.starterCapacity',
      ),
    );
  }
}

/// Codes de boutique qui ne dépendent pas du catalogue d'objets.
///
/// Six des huit contrôles de ShopStateValidator sont purement structurels. Les
/// deux autres — référence d'objet inconnue, et condition « quantité d'objet »
/// — ont besoin des identifiants réels ; sans eux, ils produiraient un faux
/// diagnostic sur chaque entrée de boutique.
///
/// Conséquence assumée : quand le catalogue manque, la gate perd aussi les
/// références de condition NON liées aux objets (badge, carte, étape), parce que
/// le validateur les regroupe sous un seul code. C'est une perte conservatrice —
/// aucun faux positif — et elle disparaît dès qu'un appelant fournit le
/// catalogue.
const Set<String> _itemAgnosticShopDiagnosticCodes = <String>{
  'SHOP_STATE_CLOSED_WITHOUT_MESSAGE',
  'SHOP_STATE_DUPLICATE_ID',
  'SHOP_STATE_EQUAL_PRIORITY_IDENTICAL_CONDITION',
  'SHOP_STATE_INVALID_PRICE',
  'SHOP_STATE_INVALID_STOCK',
  'SHOP_STATE_OPEN_EMPTY_CATALOGUE',
};

/// État des boutiques, composé directement.
///
/// Contrairement à la cohérence Pokémon, dont la gate reçoit un verdict digéré,
/// ShopStateValidator est pur sur le manifeste : la gate l'APPELLE. C'est une
/// composition plus forte, parce qu'aucun appelant ne peut oublier de la
/// déclencher.
void _appendShopStateDiagnostics(
  ProjectManifest project,
  BetaPlayabilityValidationContext context,
  List<BetaPlayabilityDiagnostic> diagnostics,
) {
  if (project.shops.isEmpty) {
    return;
  }
  final knownItemIds = context.knownItemIds;
  final shopDiagnostics = ShopStateValidator(
    project: project,
    knownItemIds: knownItemIds ?? const <String>{},
  ).validate();
  if (knownItemIds == null) {
    diagnostics.add(
      const BetaPlayabilityDiagnostic(
        kind: BetaPlayabilityDiagnosticKind.shopItemReferencesNotEvaluated,
        severity: BetaPlayabilityDiagnosticSeverity.warning,
        message: 'Shop item references were not checked because the project '
            'item catalog was not provided to the beta verdict.',
        actionHint: 'Pass the project item ids into the beta playability '
            'context to check shop entries and item conditions.',
        path: 'beta.shops.itemReferences',
      ),
    );
  }
  for (final shopDiagnostic in shopDiagnostics) {
    if (knownItemIds == null &&
        !_itemAgnosticShopDiagnosticCodes.contains(shopDiagnostic.code)) {
      continue;
    }
    diagnostics.add(
      BetaPlayabilityDiagnostic(
        kind: BetaPlayabilityDiagnosticKind.shopStateIssue,
        severity: switch (shopDiagnostic.severity) {
          ShopStateDiagnosticSeverity.error =>
            BetaPlayabilityDiagnosticSeverity.error,
          ShopStateDiagnosticSeverity.warning =>
            BetaPlayabilityDiagnosticSeverity.warning,
          ShopStateDiagnosticSeverity.info =>
            BetaPlayabilityDiagnosticSeverity.info,
        },
        message: '${shopDiagnostic.code}: ${shopDiagnostic.message}',
        actionHint: 'Fix the shop definition before shipping the beta slice.',
        path: shopDiagnostic.path,
      ),
    );
  }
}

/// Cohérence des catalogues Pokémon, telle qu'on la lui a donnée.
///
/// La gate ne charge pas les documents Pokémon et n'a pas à le faire : elle
/// reçoit le verdict du validateur de domaine. Ce qui change avec BETA-SYS-005,
/// c'est qu'elle DIT quand on ne lui a rien donné, au lieu de laisser croire
/// que la question a été posée.
void _appendPokemonCatalogCoherenceDiagnostics(
  ProjectManifest project,
  BetaPlayabilityValidationContext context,
  List<BetaPlayabilityDiagnostic> diagnostics,
) {
  if (!project.pokemon.enabled) {
    return;
  }
  final errorCount = context.pokemonCatalogErrorCount;
  if (errorCount == null) {
    diagnostics.add(
      const BetaPlayabilityDiagnostic(
        kind:
            BetaPlayabilityDiagnosticKind.pokemonCatalogCoherenceNotEvaluated,
        severity: BetaPlayabilityDiagnosticSeverity.warning,
        message: 'Pokemon catalog coherence was not evaluated for this beta '
            'verdict, so the verdict cannot speak for the catalogs.',
        actionHint: 'Pass the PokemonCatalogCoherenceReport error count into '
            'the beta playability context.',
        path: 'beta.pokemonCatalog.coherence',
      ),
    );
    return;
  }
  if (errorCount <= 0) {
    return;
  }
  diagnostics.add(
    BetaPlayabilityDiagnostic(
      kind: BetaPlayabilityDiagnosticKind.pokemonCatalogHasBlockingErrors,
      severity: BetaPlayabilityDiagnosticSeverity.error,
      message: 'The Pokemon catalogs carry $errorCount blocking coherence '
          'error(s), so the project cannot be exported or played.',
      actionHint: 'Fix the Pokemon catalog diagnostics before shipping the '
          'beta slice.',
      path: 'beta.pokemonCatalog.coherence',
    ),
  );
}

/// Capacités terrain exigées par les cartes, confrontées au catalogue.
///
/// Le calcul se fait ICI, depuis `mapsById` que la gate reçoit déjà : aucun
/// appelant n'a à fournir un fait de plus, donc aucune chance d'oublier de le
/// câbler. C'est exactement ce qui est arrivé aux cinq validateurs de domaine
/// que cette gate ne compose toujours pas.
///
/// La règle est volontairement étroite, et c'est un choix : elle ne signale que
/// l'impossibilité ABSOLUE — la capacité n'existe pas dans le catalogue de
/// capacités, donc aucun Pokémon ne pourra jamais la connaître. Savoir si une
/// ESPÈCE peut l'apprendre demande les learnsets, que la gate n'a pas ; refuser
/// sur cette base-là produirait des faux positifs sur des projets jouables.
void _appendFieldAbilityPrerequisiteDiagnostics(
  BetaPlayabilityValidationContext context,
  List<BetaPlayabilityDiagnostic> diagnostics,
) {
  if (!context.moveCatalogIsAuthoritative) {
    return;
  }
  final requiredByMapId = <String, Set<MovementMode>>{};
  for (final entry in context.mapsById.entries) {
    for (final zone in entry.value.gameplayZones) {
      final movement = zone.movement;
      if (movement == null) continue;
      final modes = <MovementMode>{
        movement.requiredMode,
        ...movement.allowedModes,
      }..remove(MovementMode.walk);
      if (modes.isEmpty) continue;
      requiredByMapId.putIfAbsent(entry.key, () => <MovementMode>{})
          .addAll(modes);
    }
  }
  for (final mapId in requiredByMapId.keys.toList()..sort()) {
    for (final mode in requiredByMapId[mapId]!.toList()
      ..sort((left, right) => left.name.compareTo(right.name))) {
      final ability = _fieldAbilityForMovementMode(mode);
      if (ability == null) continue;
      if (context.knownMoveIds.contains(ability.moveId)) continue;
      diagnostics.add(
        BetaPlayabilityDiagnostic(
          kind: BetaPlayabilityDiagnosticKind.missingFieldAbilityPrerequisite,
          severity: BetaPlayabilityDiagnosticSeverity.error,
          message:
              'Map "$mapId" has a zone requiring ${mode.name} movement, but the '
              'move catalog has no "${ability.moveId}" move, so no Pokemon can '
              'ever provide it.',
          actionHint:
              'Add the "${ability.moveId}" move to the catalog, or remove the '
              '${mode.name} requirement from the zone.',
          path: 'beta.fieldAbility.${ability.moveId}',
          mapId: mapId,
          moveId: ability.moveId,
        ),
      );
    }
  }
}

/// Capacité terrain qui ouvre un mode de déplacement, ou `null`.
FieldAbility? _fieldAbilityForMovementMode(MovementMode mode) {
  return switch (mode) {
    MovementMode.surf => FieldAbility.surf,
    _ => null,
  };
}

void _validateStartMapSpawn(
  MapData startMap,
  List<BetaPlayabilityDiagnostic> diagnostics,
) {
  final defaultSpawnId = startMap.mapMetadata.defaultSpawnId?.trim();
  if (defaultSpawnId != null && defaultSpawnId.isNotEmpty) {
    final defaultSpawn = _firstWhereOrNull(
      startMap.entities,
      (entity) => entity.id.trim() == defaultSpawnId,
    );
    if (defaultSpawn == null ||
        defaultSpawn.kind != MapEntityKind.spawn ||
        !_isInsideMap(startMap, defaultSpawn)) {
      diagnostics.add(
        BetaPlayabilityDiagnostic(
          kind: BetaPlayabilityDiagnosticKind.invalidDefaultSpawn,
          severity: BetaPlayabilityDiagnosticSeverity.error,
          message:
              'The default spawn "$defaultSpawnId" is missing or unusable.',
          actionHint:
              'Point defaultSpawnId to a spawn entity inside the start map bounds.',
          path: 'mapsById.${startMap.id}.mapMetadata.defaultSpawnId',
          mapId: startMap.id,
          entityId: defaultSpawnId,
        ),
      );
    }
    return;
  }

  final playerStart = _firstWhereOrNull(
    startMap.entities,
    (entity) =>
        entity.kind == MapEntityKind.spawn &&
        entity.spawn?.role == EntitySpawnRole.playerStart &&
        _isInsideMap(startMap, entity),
  );

  if (playerStart == null) {
    diagnostics.add(
      BetaPlayabilityDiagnostic(
        kind: BetaPlayabilityDiagnosticKind.missingPlayerSpawn,
        severity: BetaPlayabilityDiagnosticSeverity.error,
        message:
            'The start map "${startMap.id}" does not contain a valid player spawn.',
        actionHint:
            'Add a player_start spawn entity or set a valid defaultSpawnId.',
        path: 'mapsById.${startMap.id}.entities',
        mapId: startMap.id,
      ),
    );
  }
}

void _validateInitialParty(
  BetaPlayabilityValidationContext context, {
  required Set<String> knownSpeciesIds,
  required Set<String> knownMoveIds,
  required List<BetaPlayabilityDiagnostic> diagnostics,
}) {
  final initialSpeciesIds = _trimmedSet(context.initialPartySpeciesIds);
  final initialMoveIds = _trimmedSet(context.initialPartyMoveIds);

  if (context.requiresInitialParty && initialSpeciesIds.isEmpty) {
    diagnostics.add(
      const BetaPlayabilityDiagnostic(
        kind: BetaPlayabilityDiagnosticKind.missingStarterOrInitialPartySource,
        severity: BetaPlayabilityDiagnosticSeverity.warning,
        message: 'No starter or initial party source is declared.',
        actionHint:
            'Provide an initial party source before expecting a complete beta start.',
        path: 'beta.initialParty',
      ),
    );
  }

  if (context.speciesCatalogIsAuthoritative || knownSpeciesIds.isNotEmpty) {
    for (final speciesId in initialSpeciesIds) {
      if (!knownSpeciesIds.contains(speciesId)) {
        diagnostics.add(
          BetaPlayabilityDiagnostic(
            kind: BetaPlayabilityDiagnosticKind.missingPokemonSpecies,
            severity: BetaPlayabilityDiagnosticSeverity.error,
            message:
                'Initial party species "$speciesId" is missing from known species.',
            actionHint: 'Add the species to the project Pokemon catalog.',
            path: 'beta.initialParty.species',
            speciesId: speciesId,
          ),
        );
      }
    }
  }

  if (context.moveCatalogIsAuthoritative || knownMoveIds.isNotEmpty) {
    for (final moveId in initialMoveIds) {
      if (!knownMoveIds.contains(moveId)) {
        diagnostics.add(
          BetaPlayabilityDiagnostic(
            kind: BetaPlayabilityDiagnosticKind.missingPokemonMove,
            severity: BetaPlayabilityDiagnosticSeverity.error,
            message:
                'Initial party move "$moveId" is missing from known moves.',
            actionHint: 'Add the move to the project move catalog.',
            path: 'beta.initialParty.moves',
            moveId: moveId,
          ),
        );
      }
    }
  }
}

void _validateTrainers(
  ProjectManifest manifest,
  Iterable<MapData> maps, {
  required Set<String> knownSpeciesIds,
  required Set<String> knownMoveIds,
  required bool speciesCatalogIsAuthoritative,
  required bool moveCatalogIsAuthoritative,
  required bool requiresTrainerBattle,
  required Set<String>? knownItemIds,
  required Set<String>? knownAbilityIds,
  required List<BetaPlayabilityDiagnostic> diagnostics,
}) {
  if (!requiresTrainerBattle) {
    return;
  }

  final trainersById = <String, ProjectTrainerEntry>{};
  for (final trainer in manifest.trainers) {
    final trainerId = trainer.id.trim();
    if (trainerId.isEmpty) {
      continue;
    }
    if (trainersById.containsKey(trainerId)) {
      diagnostics.add(
        BetaPlayabilityDiagnostic(
          kind: BetaPlayabilityDiagnosticKind.duplicateTrainerId,
          severity: BetaPlayabilityDiagnosticSeverity.error,
          message: 'Trainer id "$trainerId" is declared more than once.',
          actionHint: 'Give every trainer a unique id.',
          path: 'manifest.trainers.$trainerId',
          trainerId: trainerId,
        ),
      );
      continue;
    }
    trainersById[trainerId] = trainer;
  }

  final validatedTrainerIds = <String>{};
  for (final map in maps) {
    for (final entity in map.entities) {
      final trainerId = entity.npc?.trainerId?.trim();
      if (entity.kind != MapEntityKind.npc ||
          trainerId == null ||
          trainerId.isEmpty) {
        continue;
      }

      final trainer = trainersById[trainerId];
      if (trainer == null) {
        diagnostics.add(
          BetaPlayabilityDiagnostic(
            kind: BetaPlayabilityDiagnosticKind.missingTrainerReference,
            severity: BetaPlayabilityDiagnosticSeverity.error,
            message:
                'NPC "${entity.id}" references missing trainer "$trainerId".',
            actionHint:
                'Create the referenced trainer or update the NPC trainer reference.',
            path: 'mapsById.${map.id}.entities.${entity.id}.npc.trainerId',
            mapId: map.id,
            entityId: entity.id,
            trainerId: trainerId,
          ),
        );
        continue;
      }

      if (validatedTrainerIds.add(trainerId)) {
        _validateTrainerTeam(
          trainer,
          manifest: manifest,
          mapId: map.id,
          entityId: entity.id,
          knownSpeciesIds: knownSpeciesIds,
          knownMoveIds: knownMoveIds,
          speciesCatalogIsAuthoritative: speciesCatalogIsAuthoritative,
          moveCatalogIsAuthoritative: moveCatalogIsAuthoritative,
          knownItemIds: knownItemIds,
          knownAbilityIds: knownAbilityIds,
          diagnostics: diagnostics,
        );
      }
    }
  }
}

void _validateTrainerTeam(
  ProjectTrainerEntry trainer, {
  required ProjectManifest manifest,
  required String mapId,
  required String entityId,
  required Set<String> knownSpeciesIds,
  required Set<String> knownMoveIds,
  required bool speciesCatalogIsAuthoritative,
  required bool moveCatalogIsAuthoritative,
  required Set<String>? knownItemIds,
  required Set<String>? knownAbilityIds,
  required List<BetaPlayabilityDiagnostic> diagnostics,
}) {
  final trainerId = trainer.id.trim();
  if (trainer.team.isEmpty) {
    diagnostics.add(
      BetaPlayabilityDiagnostic(
        kind: BetaPlayabilityDiagnosticKind.trainerHasEmptyTeam,
        severity: BetaPlayabilityDiagnosticSeverity.error,
        message: 'Trainer "$trainerId" has no usable team.',
        actionHint: 'Add at least one Pokemon to the trainer team.',
        path: 'manifest.trainers.$trainerId.team',
        mapId: mapId,
        entityId: entityId,
        trainerId: trainerId,
      ),
    );
    return;
  }

  if (trainer.team.length > 6) {
    diagnostics.add(
      BetaPlayabilityDiagnostic(
        kind: BetaPlayabilityDiagnosticKind.trainerTeamTooLarge,
        severity: BetaPlayabilityDiagnosticSeverity.error,
        message: 'Trainer "$trainerId" has ${trainer.team.length} Pokemon; '
            'a battle roster holds at most 6.',
        actionHint: 'Reduce the trainer team to at most six Pokemon.',
        path: 'manifest.trainers.$trainerId.team',
        mapId: mapId,
        entityId: entityId,
        trainerId: trainerId,
      ),
    );
  }

  final maxLevel = manifest.pokemon.ruleset.maxLevel;
  var referencesUnevaluatedCatalog = false;

  for (var index = 0; index < trainer.team.length; index += 1) {
    final pokemon = trainer.team[index];
    final speciesId = pokemon.speciesId.trim();
    final pokemonPath = 'manifest.trainers.$trainerId.team.$index';

    if (pokemon.level < 1 || pokemon.level > maxLevel) {
      diagnostics.add(
        BetaPlayabilityDiagnostic(
          kind: BetaPlayabilityDiagnosticKind.trainerPokemonLevelOutOfBounds,
          severity: BetaPlayabilityDiagnosticSeverity.error,
          message: 'Trainer "$trainerId" has a Pokemon at level '
              '${pokemon.level}; the ruleset allows 1..$maxLevel.',
          actionHint: 'Set the level within the ruleset bounds.',
          path: '$pokemonPath.level',
          mapId: mapId,
          entityId: entityId,
          trainerId: trainerId,
          speciesId: speciesId.isEmpty ? null : speciesId,
        ),
      );
    }

    final heldItemId = pokemon.heldItemId?.trim();
    if (heldItemId != null && heldItemId.isNotEmpty) {
      if (knownItemIds == null) {
        referencesUnevaluatedCatalog = true;
      } else if (!knownItemIds.contains(heldItemId)) {
        diagnostics.add(
          BetaPlayabilityDiagnostic(
            kind: BetaPlayabilityDiagnosticKind.trainerPokemonUnknownHeldItem,
            severity: BetaPlayabilityDiagnosticSeverity.error,
            message: 'Trainer "$trainerId" holds unknown item "$heldItemId"; '
                'the runtime would refuse to start this battle.',
            actionHint: 'Add the item to the project item catalog.',
            path: '$pokemonPath.heldItemId',
            mapId: mapId,
            entityId: entityId,
            trainerId: trainerId,
            speciesId: speciesId.isEmpty ? null : speciesId,
          ),
        );
      }
    }

    final abilityId = pokemon.abilityId?.trim();
    if (abilityId != null && abilityId.isNotEmpty) {
      if (knownAbilityIds == null) {
        referencesUnevaluatedCatalog = true;
      } else if (!knownAbilityIds.contains(abilityId)) {
        diagnostics.add(
          BetaPlayabilityDiagnostic(
            kind: BetaPlayabilityDiagnosticKind.trainerPokemonUnknownAbility,
            severity: BetaPlayabilityDiagnosticSeverity.error,
            message:
                'Trainer "$trainerId" overrides unknown ability "$abilityId".',
            actionHint: 'Add the ability to the project ability catalog.',
            path: '$pokemonPath.abilityId',
            mapId: mapId,
            entityId: entityId,
            trainerId: trainerId,
            speciesId: speciesId.isEmpty ? null : speciesId,
          ),
        );
      }
    }

    final formId = pokemon.formId?.trim();
    if (formId != null && formId.isNotEmpty) {
      diagnostics.add(
        BetaPlayabilityDiagnostic(
          kind: BetaPlayabilityDiagnosticKind.trainerPokemonFormNotSupported,
          severity: BetaPlayabilityDiagnosticSeverity.error,
          message: 'Trainer "$trainerId" authors form "$formId"; the beta '
              'runtime does not hydrate forms, so the promise would be '
              'silently dropped in battle.',
          actionHint: 'Remove the formId until forms are supported.',
          path: '$pokemonPath.formId',
          mapId: mapId,
          entityId: entityId,
          trainerId: trainerId,
          speciesId: speciesId.isEmpty ? null : speciesId,
        ),
      );
    }

    if (speciesId.isEmpty) {
      diagnostics.add(
        BetaPlayabilityDiagnostic(
          kind: BetaPlayabilityDiagnosticKind.trainerPokemonMissingSpecies,
          severity: BetaPlayabilityDiagnosticSeverity.error,
          message: 'Trainer "$trainerId" has a Pokemon without speciesId.',
          actionHint: 'Set a speciesId on every trainer Pokemon.',
          path: '$pokemonPath.speciesId',
          mapId: mapId,
          entityId: entityId,
          trainerId: trainerId,
        ),
      );
    } else if ((speciesCatalogIsAuthoritative || knownSpeciesIds.isNotEmpty) &&
        !knownSpeciesIds.contains(speciesId)) {
      diagnostics.add(
        BetaPlayabilityDiagnostic(
          kind: BetaPlayabilityDiagnosticKind.missingPokemonSpecies,
          severity: BetaPlayabilityDiagnosticSeverity.error,
          message:
              'Trainer "$trainerId" references unknown species "$speciesId".',
          actionHint: 'Add the species to the project Pokemon catalog.',
          path: '$pokemonPath.speciesId',
          mapId: mapId,
          entityId: entityId,
          trainerId: trainerId,
          speciesId: speciesId,
        ),
      );
    }

    final moveIds = pokemon.moves
        .map((moveId) => moveId.trim())
        .where((id) => id.isNotEmpty);
    if (moveIds.isEmpty) {
      diagnostics.add(
        BetaPlayabilityDiagnostic(
          kind: BetaPlayabilityDiagnosticKind.trainerPokemonMissingMoves,
          severity: BetaPlayabilityDiagnosticSeverity.error,
          message: 'Trainer "$trainerId" has a Pokemon without moves.',
          actionHint: 'Set at least one move on every trainer Pokemon.',
          path: '$pokemonPath.moves',
          mapId: mapId,
          entityId: entityId,
          trainerId: trainerId,
          speciesId: speciesId.isEmpty ? null : speciesId,
        ),
      );
      continue;
    }

    if (!moveCatalogIsAuthoritative && knownMoveIds.isEmpty) {
      continue;
    }

    for (final moveId in moveIds) {
      if (!knownMoveIds.contains(moveId)) {
        diagnostics.add(
          BetaPlayabilityDiagnostic(
            kind: BetaPlayabilityDiagnosticKind.missingPokemonMove,
            severity: BetaPlayabilityDiagnosticSeverity.error,
            message: 'Trainer "$trainerId" references unknown move "$moveId".',
            actionHint: 'Add the move to the project move catalog.',
            path: '$pokemonPath.moves',
            mapId: mapId,
            entityId: entityId,
            trainerId: trainerId,
            speciesId: speciesId.isEmpty ? null : speciesId,
            moveId: moveId,
          ),
        );
      }
    }
  }

  if (referencesUnevaluatedCatalog) {
    // « Pas évalué » n'est pas « aucune erreur » : des membres référencent des
    // objets ou des abilities mais le catalogue correspondant n'a pas été
    // fourni — la gate le dit au lieu de laisser croire que tout va bien.
    diagnostics.add(
      BetaPlayabilityDiagnostic(
        kind: BetaPlayabilityDiagnosticKind.trainerReferencesNotEvaluated,
        severity: BetaPlayabilityDiagnosticSeverity.error,
        message: 'Trainer "$trainerId" references held items or abilities, '
            'but the matching catalogs were not provided to the gate.',
        actionHint:
            'Run the validation with the project item and ability catalogs.',
        path: 'manifest.trainers.$trainerId.team',
        mapId: mapId,
        entityId: entityId,
        trainerId: trainerId,
      ),
    );
  }
}

bool _isInsideMap(MapData map, MapEntity entity) {
  final pos = entity.pos;
  return pos.x >= 0 &&
      pos.y >= 0 &&
      pos.x < map.size.width &&
      pos.y < map.size.height;
}

Set<String> _trimmedSet(Iterable<String> values) {
  return values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet();
}

T? _firstWhereOrNull<T>(Iterable<T> values, bool Function(T value) test) {
  for (final value in values) {
    if (test(value)) {
      return value;
    }
  }
  return null;
}
