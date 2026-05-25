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

  if (knownSpeciesIds.isNotEmpty) {
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

  if (knownMoveIds.isNotEmpty) {
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
    } else if (knownSpeciesIds.isNotEmpty &&
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

    if (knownMoveIds.isEmpty) {
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
