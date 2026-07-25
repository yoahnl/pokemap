import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('pokemap-save-isolation-');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('isolates identical profile and slot ids between two games', () async {
    final first = HubSaveStore(
      supportRoot: root,
      identity: _identity('games.example.first'),
    );
    final second = HubSaveStore(
      supportRoot: root,
      identity: _identity('games.example.second'),
    );

    await first.write(_envelope(first.identity, marker: 'first'));
    await second.write(_envelope(second.identity, marker: 'second'));

    final firstRead = await first.read(_address(first.identity.gameId));
    final secondRead = await second.read(_address(second.identity.gameId));

    expect(firstRead.envelope!.state['marker'], 'first');
    expect(secondRead.envelope!.state['marker'], 'second');
    expect(
      File(
        p.join(
          root.path,
          'saves',
          'games.example.first',
          'player-1',
          'slot-1',
          'save.json',
        ),
      ).existsSync(),
      isTrue,
    );
    expect(
      () => first.read(_address(second.identity.gameId)),
      throwsA(
        isA<SaveStorageException>().having(
          (error) => error.code,
          'code',
          SaveStorageErrorCode.outOfScope,
        ),
      ),
    );
  });

  test('keeps profile display names separate from path identity', () async {
    final store = HubSaveStore(
      supportRoot: root,
      identity: _identity('games.example.first'),
    );

    await store.saveProfile(
      const SaveProfile(profileId: 'player-1', displayName: 'Karim / Joueur'),
    );

    expect(await store.listProfiles(), <SaveProfile>[
      const SaveProfile(profileId: 'player-1', displayName: 'Karim / Joueur'),
    ]);
    expect(
      Directory(
        p.join(
          root.path,
          'saves',
          'games.example.first',
          'Karim / Joueur',
        ),
      ).existsSync(),
      isFalse,
    );
  });

  test('rejects a symlink that redirects a game namespace', () async {
    final outside = await Directory.systemTemp.createTemp('pokemap-outside-');
    addTearDown(() async {
      if (await outside.exists()) await outside.delete(recursive: true);
    });
    final saves = Directory(p.join(root.path, 'saves'));
    await saves.create(recursive: true);
    await Link(p.join(saves.path, 'games.example.first')).create(outside.path);
    final store = HubSaveStore(
      supportRoot: root,
      identity: _identity('games.example.first'),
    );

    expect(
      () => store.write(_envelope(store.identity, marker: 'blocked')),
      throwsA(
        isA<SaveStorageException>().having(
          (error) => error.code,
          'code',
          SaveStorageErrorCode.pathEscapesRoot,
        ),
      ),
    );
    expect(await outside.list().toList(), isEmpty);
  });

  test('Continue selects the latest valid compatible slot', () async {
    final store = HubSaveStore(
      supportRoot: root,
      identity: _identity('games.example.first'),
    );
    await store.write(
      _envelope(
        store.identity,
        marker: 'older',
        slotId: 'slot-1',
        updatedAt: DateTime.utc(2026, 7, 25, 10),
      ),
    );
    await store.write(
      _envelope(
        store.identity,
        marker: 'newer',
        slotId: 'slot-2',
        updatedAt: DateTime.utc(2026, 7, 25, 11),
      ),
    );

    final latest = await store.findContinue(profileId: 'player-1');
    final slots = await store.listSlots(profileId: 'player-1');

    expect(latest!.address.slotId, 'slot-2');
    expect(
        slots.map((slot) => slot.address.slotId),
        containsAll(<String>[
          'slot-1',
          'slot-2',
        ]));
  });

  test('global Continue also discovers a valid profile missing UI metadata',
      () async {
    final store = HubSaveStore(
      supportRoot: root,
      identity: _identity('games.example.first'),
    );
    await store.write(_envelope(store.identity, marker: 'discoverable'));

    final latest = await store.findContinue();

    expect(latest!.envelope!.state['marker'], 'discoverable');
  });

  test('lists a misplaced cross-game save without exposing or deleting it',
      () async {
    final store = HubSaveStore(
      supportRoot: root,
      identity: _identity('games.example.first'),
    );
    final misplaced = _envelope(
      _identity('games.example.second'),
      marker: 'private-to-second',
    );
    final target = File(
      p.join(
        root.path,
        'saves',
        'games.example.first',
        'player-1',
        'slot-1',
        'save.json',
      ),
    );
    await target.parent.create(recursive: true);
    await target.writeAsString(
      const SaveEnvelopeCodec().encode(misplaced),
      flush: true,
    );

    final result = await store.read(_address(store.identity.gameId));

    expect(result.status, SaveSlotReadStatus.incompatible);
    expect(result.envelope, isNull);
    expect(
      result.diagnostics.single.code,
      SaveStorageDiagnosticCode.saveGameMismatch,
    );
    expect(await target.exists(), isTrue);
  });
}

GameIdentity _identity(String gameId) => GameIdentity(
      gameId: gameId,
      gameVersion: '1.0.0',
      projectFormat: ProjectFormat.v2,
      saveFormat: 1,
      compatibilityId: 'campaign-v1',
    );

SaveSlotAddress _address(String gameId, {String slotId = 'slot-1'}) =>
    SaveSlotAddress(
      gameId: gameId,
      profileId: 'player-1',
      slotId: slotId,
    );

SaveEnvelope _envelope(
  GameIdentity identity, {
  required String marker,
  String slotId = 'slot-1',
  DateTime? updatedAt,
}) =>
    const SaveEnvelopeCodec().create(
      identity: identity,
      profileId: 'player-1',
      slotId: slotId,
      saveId: slotId == 'slot-1'
          ? '018f255f-2d50-4f4f-8aa2-c893ae06b8c1'
          : '018f255f-2d50-4f4f-8aa2-c893ae06b8c2',
      createdAt: DateTime.utc(2026, 7, 25, 10),
      updatedAt: updatedAt ?? DateTime.utc(2026, 7, 25, 10),
      status: SaveStatus.active,
      playTimeSeconds: 0,
      state: <String, Object?>{'marker': marker},
    );
