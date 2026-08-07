import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:pokemap_hub/features/session/domain/entities/save_read_handle.dart';

void main() {
  final identity = GameIdentity(
    gameId: 'org.example.adventure',
    gameVersion: '1.2.0',
    projectFormat: ProjectFormat.v2,
    saveFormat: 1,
    compatibilityId: 'story-v1',
  );

  test('save handle is stable, opaque, and scoped to the exact revision', () {
    const firstId = '550e8400-e29b-41d4-a716-446655440000';
    const nextId = '550e8400-e29b-41d4-a716-446655440001';
    final first = _envelope(identity, saveId: firstId);
    final same = _envelope(identity, saveId: firstId);
    final next = _envelope(identity, saveId: nextId);

    final firstHandle = hubSaveReadHandle(first);

    expect(firstHandle, hubSaveReadHandle(same));
    expect(firstHandle, startsWith('save-v1-'));
    expect(firstHandle, isNot(hubSaveReadHandle(next)));
    expect(firstHandle, isNot(contains(first.gameId)));
    expect(firstHandle, isNot(contains(first.profileId)));
    expect(firstHandle, isNot(contains(first.slotId)));
    expect(firstHandle, isNot(contains(first.saveId)));
  });
}

SaveEnvelope _envelope(
  GameIdentity identity, {
  required String saveId,
}) {
  return const SaveEnvelopeCodec().create(
    identity: identity,
    profileId: 'player-1',
    slotId: 'slot-1',
    saveId: saveId,
    createdAt: DateTime.utc(2026, 7, 25, 10),
    updatedAt: DateTime.utc(2026, 7, 25, 11),
    status: SaveStatus.active,
    playTimeSeconds: 120,
    state: <String, Object?>{'saveId': saveId},
  );
}
