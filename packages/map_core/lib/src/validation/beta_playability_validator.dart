import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/project_manifest.dart';
import '../models/project_trainer.dart';

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
  required List<BetaPlayabilityDiagnostic> diagnostics,
}) {
  if (!requiresTrainerBattle) {
    return;
  }

  final trainersById = <String, ProjectTrainerEntry>{};
  for (final trainer in manifest.trainers) {
    final trainerId = trainer.id.trim();
    if (trainerId.isNotEmpty) {
      trainersById[trainerId] = trainer;
    }
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
          mapId: map.id,
          entityId: entity.id,
          knownSpeciesIds: knownSpeciesIds,
          knownMoveIds: knownMoveIds,
          speciesCatalogIsAuthoritative: speciesCatalogIsAuthoritative,
          moveCatalogIsAuthoritative: moveCatalogIsAuthoritative,
          diagnostics: diagnostics,
        );
      }
    }
  }
}

void _validateTrainerTeam(
  ProjectTrainerEntry trainer, {
  required String mapId,
  required String entityId,
  required Set<String> knownSpeciesIds,
  required Set<String> knownMoveIds,
  required bool speciesCatalogIsAuthoritative,
  required bool moveCatalogIsAuthoritative,
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

  for (var index = 0; index < trainer.team.length; index += 1) {
    final pokemon = trainer.team[index];
    final speciesId = pokemon.speciesId.trim();
    final pokemonPath = 'manifest.trainers.$trainerId.team.$index';

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
