import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('GameIdentity', () {
    test('accepts the Phase 0 identity contract', () {
      final identity = GameIdentity(
        gameId: 'games.example.complete',
        gameVersion: '1.2.0',
        projectFormat: ProjectFormat.v2,
        saveFormat: 1,
        compatibilityId: 'campaign-v1',
      );

      expect(identity.gameId, 'games.example.complete');
      expect(identity.gameVersion, '1.2.0');
      expect(identity.projectFormat, ProjectFormat.v2);
      expect(identity.saveFormat, 1);
      expect(identity.compatibilityId, 'campaign-v1');
    });

    test('rejects inferred, unsafe, or malformed identifiers', () {
      for (final gameId in <String>[
        'Selbrume',
        'games.example',
        'games.example.../other',
        '/games.example.complete',
      ]) {
        expect(
          () => GameIdentity(
            gameId: gameId,
            gameVersion: '1.0.0',
            projectFormat: ProjectFormat.v2,
            saveFormat: 1,
            compatibilityId: 'campaign-v1',
          ),
          throwsA(isA<SaveContractException>()),
          reason: gameId,
        );
      }
    });

    test('rejects invalid versions and compatibility identifiers', () {
      expect(
        () => GameIdentity(
          gameId: 'games.example.complete',
          gameVersion: '1.0',
          projectFormat: ProjectFormat.v2,
          saveFormat: 1,
          compatibilityId: 'campaign-v1',
        ),
        throwsA(isA<SaveContractException>()),
      );
      expect(
        () => GameIdentity(
          gameId: 'games.example.complete',
          gameVersion: '1.0.0',
          projectFormat: ProjectFormat.v2,
          saveFormat: -1,
          compatibilityId: 'Campaign v1',
        ),
        throwsA(isA<SaveContractException>()),
      );
    });
  });

  group('SaveSlotAddress', () {
    test('keeps display names out of path identity', () {
      final address = SaveSlotAddress(
        gameId: 'games.example.complete',
        profileId: 'player-1',
        slotId: 'slot_1',
      );

      expect(address.pathSegments, <String>[
        'games.example.complete',
        'player-1',
        'slot_1',
      ]);
    });

    test('rejects traversal, separators, Unicode, and empty local ids', () {
      for (final localId in <String>[
        '',
        '../player',
        'player/one',
        'Player',
        'joueur-é',
      ]) {
        expect(
          () => SaveSlotAddress(
            gameId: 'games.example.complete',
            profileId: localId,
            slotId: 'slot-1',
          ),
          throwsA(isA<SaveContractException>()),
          reason: localId,
        );
      }
    });
  });
}
