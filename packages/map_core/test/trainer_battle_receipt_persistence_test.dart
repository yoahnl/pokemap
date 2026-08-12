import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('completed battle request ids survive every gameplay save bridge', () {
    const state = GameState(
      saveId: 'trainer-receipts',
      completedBattleRequestIds: <String>{
        'trainer-first-battle',
        'trainer-rematch',
      },
    );

    final strictReload = gameStateFromStrictSaveJson(
      strictGameStateSaveJson(state),
    );
    final saveDataReload = gameStateFromSaveData(
      SaveData.fromJson(saveDataFromGameState(state).toJson()),
    );

    expect(
      strictReload.completedBattleRequestIds,
      state.completedBattleRequestIds,
    );
    expect(
      saveDataReload.completedBattleRequestIds,
      state.completedBattleRequestIds,
    );
  });

  test('legacy saves default to an empty completed battle request ledger', () {
    final state = GameState.fromJson(const <String, dynamic>{
      'saveId': 'legacy',
    });
    final save = SaveData.fromJson(const <String, dynamic>{
      'saveId': 'legacy',
      'itemSystemSchemaVersion': currentItemSystemSaveSchemaVersion,
    });

    expect(state.completedBattleRequestIds, isEmpty);
    expect(save.completedBattleRequestIds, isEmpty);
  });

  test('trainer validation rejects duplicate ids and invalid rematch JSON', () {
    final duplicate = ProjectManifest(
      name: 'duplicate trainers',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      trainers: const <ProjectTrainerEntry>[
        ProjectTrainerEntry(id: 'trainer', name: 'First', trainerClass: 'Ace'),
        ProjectTrainerEntry(id: 'trainer', name: 'Second', trainerClass: 'Ace'),
      ],
    );

    expect(
      () => ProjectValidator.validate(duplicate),
      throwsA(
        isA<ValidationException>().having(
          (error) => error.message,
          'message',
          contains('Duplicate trainer ID'),
        ),
      ),
    );
    expect(
      () => ProjectTrainerEntry.fromJson(const <String, dynamic>{
        'id': 'trainer',
        'name': 'Trainer',
        'trainerClass': 'Ace',
        'rematchPolicy': 'inferred_from_dialogue',
      }),
      throwsA(isA<ArgumentError>()),
    );
  });
}
