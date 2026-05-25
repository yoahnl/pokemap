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
      final result = validateBetaPlayability(
        _manifest(),
        context: BetaPlayabilityValidationContext(
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
}) {
  return ProjectManifest(
    name: 'P5 Beta Validator Project',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'P5 Beta Validator Field',
        relativePath: 'maps/p5_beta_validator_map.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    trainers: trainers ?? <ProjectTrainerEntry>[_trainer()],
  );
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
