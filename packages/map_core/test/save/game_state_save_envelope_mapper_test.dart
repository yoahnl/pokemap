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

    expect(restored.saveId, envelope.saveId);
    expect(restored.currentMapId, 'port');
    expect(restored.playerPosition, const GridPos(x: 4, y: 7));
    expect(restored.storyFlags.activeFlags, contains('intro-complete'));
    expect(const SaveEnvelopeCodec().verifyChecksum(envelope), isTrue);
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
