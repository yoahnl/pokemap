import 'dart:async';

import 'package:avelune_studio/features/pokemon/application/pokemon_combat_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_combat_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  late _ControlledCombatPort port;
  late PokemonCombatController controller;
  late List<ProjectManifest> published;
  setUp(() {
    port = _ControlledCombatPort();
    published = [];
    controller = PokemonCombatController(
      port,
      changed: () {},
      projectChanged: published.add,
    );
  });
  tearDown(() => controller.dispose());

  test(
    'retained combat load cannot restore a removed character after receipt',
    () async {
      final pending = controller.load();
      expect(controller.characterDraftOwner('removed'), contains('en cours'));
      controller.reconcileCharacterReferences(_project('replacement'), {});
      port.pending.complete(_snapshot('removed'));
      await pending;
      expect(published, isEmpty);
      expect(controller.snapshot, isNull);
      expect(controller.loading, isFalse);
      port.pending = Completer<PokemonCombatSnapshot>();
      final fresh = controller.load();
      port.pending.complete(_snapshot('replacement'));
      await fresh;
      expect(
        controller.snapshot!.project.trainers.single.characterId,
        'replacement',
      );
      expect(published.single.trainers.single.characterId, 'replacement');
    },
  );

  test(
    'clean trainer and closed map refresh survive an obsolete reload',
    () async {
      controller.snapshot = _snapshot('removed');
      controller.selectTrainer(controller.snapshot!.project.trainers.single);
      final pending = controller.load(refresh: true);
      final updated = _snapshot('replacement');
      controller.reconcileCharacterReferences(updated.project, {
        'closed': updated.maps.single,
      });
      port.pending.complete(_snapshot('removed'));
      await pending;
      expect(controller.trainer!.current.characterId, 'replacement');
      expect(controller.trainer!.dirty, isFalse);
      expect(
        controller.snapshot!.maps.single.entities.single.npc!.characterId,
        'replacement',
      );
      expect(published, isEmpty);
    },
  );

  test('trainer guard includes both base and newly edited character', () {
    controller.snapshot = _snapshot('removed');
    controller.selectTrainer(controller.snapshot!.project.trainers.single);
    controller.editTrainer((value) => value.copyWith(characterId: 'other'));
    expect(controller.characterDraftOwner('removed'), contains('brouillon'));
    expect(controller.characterDraftOwner('other'), contains('brouillon'));
    expect(controller.characterDraftOwner('unrelated'), isNull);
    expect(
      () =>
          controller.reconcileCharacterReferences(_project('replacement'), {}),
      throwsStateError,
    );
    expect(controller.trainer!.current.characterId, 'other');
    expect(controller.trainer!.dirty, isTrue);
    expect(controller.snapshot!.project.trainers.single.characterId, 'removed');
  });

  test('invalid focused number guards the clean trainer reference', () {
    controller.snapshot = _snapshot('removed');
    controller.selectTrainer(controller.snapshot!.project.trainers.single);
    controller.editNumber('level', 'abc', (_) {});
    expect(controller.trainer!.dirty, isFalse);
    expect(controller.characterDraftOwner('removed'), contains('brouillon'));
    expect(
      () =>
          controller.reconcileCharacterReferences(_project('replacement'), {}),
      throwsStateError,
    );
    expect(controller.numericInputs['level'], 'abc');
    expect(controller.fieldErrors['level'], isNotNull);
  });

  test('unrelated trainer draft and field errors survive reconciliation', () {
    controller.snapshot = _snapshot('unrelated');
    controller.selectTrainer(controller.snapshot!.project.trainers.single);
    controller.editTrainer((value) => value.copyWith(name: 'Saisie conservée'));
    controller.editNumber('level', '-', (_) {});
    final draft = controller.trainer;
    expect(controller.characterDraftOwner('removed'), isNull);
    controller.reconcileCharacterReferences(_project('unrelated'), {});
    expect(controller.trainer, same(draft));
    expect(controller.trainer!.current.name, 'Saisie conservée');
    expect(controller.trainer!.dirty, isTrue);
    expect(controller.numericInputs['level'], '-');
    expect(controller.fieldErrors['level'], isNotNull);
  });

  test('unrelated encounter draft survives character reconciliation', () {
    controller.snapshot = _snapshot('removed');
    expect(controller.createTable('Brouillon'), isTrue);
    controller.editTable((value) => value.copyWith(chancePerStep: 41));
    final draft = controller.table;
    controller.reconcileCharacterReferences(_project('replacement'), {});
    expect(controller.table, same(draft));
    expect(controller.table!.current.chancePerStep, 41);
    expect(controller.table!.dirty, isTrue);
  });

  test('clean selected trainer removal clears only its selection', () {
    controller.snapshot = _snapshot('removed');
    controller.selectTrainer(controller.snapshot!.project.trainers.single);
    controller.search = 'Gare';
    controller.reconcileCharacterReferences(
      _project('replacement').copyWith(trainers: []),
      {},
    );
    expect(controller.trainer, isNull);
    expect(controller.search, 'Gare');
    expect(controller.snapshot!.project.trainers, isEmpty);
  });
}

ProjectManifest _project(String characterId) => ProjectManifest(
  name: 'Project',
  maps: const [
    ProjectMapEntry(
      id: 'closed',
      name: 'Carte fermée',
      relativePath: 'maps/closed.json',
    ),
  ],
  tilesets: [],
  trainers: [
    ProjectTrainerEntry(
      id: 'trainer',
      name: 'Gare',
      trainerClass: 'Dresseur',
      characterId: characterId,
    ),
  ],
);

PokemonCombatSnapshot _snapshot(String characterId) => PokemonCombatSnapshot(
  project: _project(characterId),
  maps: [
    MapData(
      id: 'closed',
      name: 'Carte fermée',
      size: const GridSize(width: 4, height: 4),
      entities: [
        MapEntity(
          id: 'npc',
          kind: MapEntityKind.npc,
          pos: const GridPos(x: 1, y: 1),
          npc: MapEntityNpcData(characterId: characterId),
        ),
      ],
    ),
  ],
);

final class _ControlledCombatPort implements PokemonCombatPort {
  Completer<PokemonCombatSnapshot> pending = Completer();

  @override
  Future<PokemonCombatSnapshot> load() => pending.future;

  @override
  Future<void> saveTable(
    ProjectEncounterTable? before,
    ProjectEncounterTable after,
  ) => throw UnimplementedError();

  @override
  Future<void> deleteTable(ProjectEncounterTable before) =>
      throw UnimplementedError();

  @override
  Future<void> saveTrainer(
    ProjectTrainerEntry? before,
    ProjectTrainerEntry after,
  ) => throw UnimplementedError();

  @override
  Future<void> deleteTrainer(ProjectTrainerEntry before) =>
      throw UnimplementedError();
}
