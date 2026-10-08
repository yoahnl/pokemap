import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('preserves the exact spatial feet anchor through every save projection',
      () {
    final position = PlayerSpatialPosition(x: 4.3125, z: 7.0625);
    final state = GameState(
      saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
      currentMapId: 'forest',
      playerPosition: const GridPos(x: 4, y: 7),
      playerSpatialPosition: position,
      playerFacing: EntityFacing.west,
      storyFlags: const StoryFlags(activeFlags: {'found-herb'}),
    );
    final json = strictGameStateSaveJson(state);
    final restored = gameStateFromStrictSaveJson(
        jsonDecode(jsonEncode(json)) as Map<String, dynamic>);
    expect(restored.playerSpatialPosition, position);
    expect(restored.playerPosition, state.playerPosition);
    expect(restored.playerFacing, EntityFacing.west);
    expect(restored.storyFlags.activeFlags, contains('found-herb'));

    final saveData = saveDataFromGameState(state);
    final decodedSave = SaveData.fromJson(
        jsonDecode(jsonEncode(saveData.toJson())) as Map<String, dynamic>);
    expect(decodedSave.playerSpatialPosition, position);
    expect(gameStateFromSaveData(decodedSave).playerSpatialPosition, position);
  });

  test('a 2D state has no spatial position', () {
    const state = GameState(saveId: 'two-dimensional');
    expect(gameStateFromStrictSaveJson(strictGameStateSaveJson(state))
        .playerSpatialPosition, isNull);
    expect(saveDataFromGameState(state).playerSpatialPosition, isNull);
  });

  test('rejects invalid coordinates and unsupported spatial save schemas', () {
    for (final value in [double.nan, double.infinity, -0.125]) {
      expect(() => PlayerSpatialPosition(x: value, z: 1),
          throwsFormatException);
      expect(() => PlayerSpatialPosition(x: 1, z: value),
          throwsFormatException);
    }
    final valid = PlayerSpatialPosition(x: 1.5, z: 2.5).toJson();
    expect(valid['schemaVersion'], 1);
    expect(() => PlayerSpatialPosition.fromJson({...valid, 'schemaVersion': 2}),
        throwsFormatException);
    expect(() => PlayerSpatialPosition.fromJson({...valid, 'y': 100}),
        throwsFormatException);
    expect(() => PlayerSpatialPosition.fromJson({...valid, 'x': '1.5'}),
        throwsFormatException);
    expect(() => PlayerSpatialPosition.fromJson({'x': 1.5, 'z': 2.5}),
        throwsFormatException);
  });

  test('the canonical envelope preserves spatial location and its checksum',
      () {
    final position = PlayerSpatialPosition(x: 3.9375, z: 2.0625);
    final envelope = const GameStateSaveEnvelopeMapper().create(
      identity: GameIdentity(
          gameId: 'org.example.valbois',
          gameVersion: '0.1.0',
          projectFormat: ProjectFormat.v9,
          saveFormat: 1,
          compatibilityId: 'valbois'),
      profileId: 'profile',
      slotId: 'slot',
      saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
      createdAt: DateTime.utc(2026, 10, 8),
      updatedAt: DateTime.utc(2026, 10, 8, 1),
      status: SaveStatus.active,
      playTimeSeconds: 60,
      gameState: GameState(
          saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
          currentMapId: 'village',
          playerPosition: const GridPos(x: 3, y: 2),
          playerSpatialPosition: position),
    );
    final decoded = const SaveEnvelopeCodec().decodeUtf8(
        const SaveEnvelopeCodec().encodeUtf8(envelope));
    final restored = const GameStateSaveEnvelopeMapper().restore(decoded);
    expect(restored.playerSpatialPosition, position);
    expect(const SaveEnvelopeCodec().verifyChecksum(decoded), isTrue);
  });

  test('rejects a spatial position contradicting its grid projection', () {
    final position = PlayerSpatialPosition(x: 3.9375, z: 2.0625);
    final state = GameState(saveId: 'spatial-save',
        playerPosition: const GridPos(x: 2, y: 2),
        playerSpatialPosition: position);
    expect(() => strictGameStateSaveJson(state), throwsStateError);
    expect(() => SaveData(saveId: 'spatial-save',
        playerPosition: const GridPos(x: 2, y: 2),
        playerSpatialPosition: position).normalized(), throwsStateError);
  });
}
