import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const mapper = GameStateSaveEnvelopeMapper();
  final identity = GameIdentity(
    gameId: 'games.example.runtime',
    gameVersion: '1.0.0',
    projectFormat: ProjectFormat.v2,
    saveFormat: 1,
    compatibilityId: 'campaign-v1',
  );

  test('round-trips the runtime-owned GameState inside SaveEnvelope', () {
    const state = GameState(
      saveId: 'legacy-runtime-id',
      currentMapId: 'port',
      playerPosition: GridPos(x: 4, y: 7),
      storyFlags: StoryFlags(activeFlags: <String>{'intro-complete'}),
    );

    final envelope = mapper.create(
      identity: identity,
      profileId: 'player-1',
      slotId: 'slot-1',
      saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
      createdAt: DateTime.utc(2026, 7, 25, 10),
      updatedAt: DateTime.utc(2026, 7, 25, 10),
      status: SaveStatus.active,
      playTimeSeconds: 5,
      gameState: state,
    );
    final restored = mapper.restore(envelope);

    expect(
      envelope.state['itemSystemSchemaVersion'],
      currentItemSystemSaveSchemaVersion,
    );
    expect(restored.saveId, envelope.saveId);
    expect(restored.currentMapId, 'port');
    expect(restored.playerPosition, const GridPos(x: 4, y: 7));
    expect(restored.storyFlags.activeFlags, contains('intro-complete'));
    expect(const SaveEnvelopeCodec().verifyChecksum(envelope), isTrue);
  });

  test('rejects a runtime state without the Item V1 schema marker', () {
    final envelope = const SaveEnvelopeCodec().create(
      identity: identity,
      profileId: 'player-1',
      slotId: 'slot-1',
      saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
      createdAt: DateTime.utc(2026, 7, 25, 10),
      updatedAt: DateTime.utc(2026, 7, 25, 10),
      status: SaveStatus.active,
      playTimeSeconds: 0,
      state: const GameState(
        saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
        currentMapId: 'port',
      ).toJson(),
    );

    expect(
      () => mapper.restore(envelope),
      throwsA(isA<UnsupportedSaveSchema>()),
    );
  });

  test('rejects a legacy bag field inside a marked runtime state', () {
    final state = strictGameStateSaveJson(
      const GameState(
        saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
        currentMapId: 'port',
        bag: Bag(entries: <BagEntry>[BagEntry(itemId: 'potion', quantity: 1)]),
      ),
    );
    final bag = Map<String, dynamic>.from(state['bag']! as Map);
    final entries = List<dynamic>.from(bag['entries']! as List);
    entries[0] = <String, dynamic>{
      ...Map<String, dynamic>.from(entries[0] as Map),
      'categoryId': 'medicine',
    };
    state['bag'] = <String, dynamic>{...bag, 'entries': entries};
    final envelope = const SaveEnvelopeCodec().create(
      identity: identity,
      profileId: 'player-1',
      slotId: 'slot-1',
      saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
      createdAt: DateTime.utc(2026, 7, 25, 10),
      updatedAt: DateTime.utc(2026, 7, 25, 10),
      status: SaveStatus.active,
      playTimeSeconds: 0,
      state: state,
    );

    expect(
      () => mapper.restore(envelope),
      throwsA(
        isA<UnsupportedSaveSchema>().having(
          (error) => error.path,
          'path',
          r'$.bag.entries[0].categoryId',
        ),
      ),
    );
  });

  test('rejects a state whose identity was altered inside the envelope', () {
    final envelope = const SaveEnvelopeCodec().create(
      identity: identity,
      profileId: 'player-1',
      slotId: 'slot-1',
      saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
      createdAt: DateTime.utc(2026, 7, 25, 10),
      updatedAt: DateTime.utc(2026, 7, 25, 10),
      status: SaveStatus.active,
      playTimeSeconds: 0,
      state: const GameState(
        saveId: 'different-id',
        currentMapId: 'port',
      ).toJson(),
    );

    expect(
      () => mapper.restore(envelope),
      throwsA(
        isA<SaveContractException>().having(
          (error) => error.code,
          'code',
          SaveContractErrorCode.invalidIdentity,
        ),
      ),
    );
  });
}
