import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('sandbox player state', () {
    test('gameplay mutations change only the detached sandbox copy', () {
      const baseline = GameState(
        saveId: 'production-save',
        currentMapId: 'start',
        party: PlayerParty(
          members: [
            PlayerPokemon(
              speciesId: 'sproutle',
              level: 5,
              natureId: 'hardy',
              abilityId: 'overgrow',
              currentHp: 0,
            ),
          ],
        ),
      );
      final service = const SandboxPlayerStateService();
      final opened = service.open(sandboxId: 'test-run', state: baseline);
      final withItem = service.giveItem(opened, itemId: 'potion', quantity: 2);
      final healed = service.recoverParty(
        withItem,
        maxHpByPartyIndex: const {0: 20},
      );

      expect(baseline.bag.entries, isEmpty);
      expect(baseline.party.members.single.currentHp, 0);
      expect(healed.state.bag.entries.single.quantity, 2);
      expect(healed.state.party.members.single.currentHp, 20);
      expect(healed.productionWriteAllowed, isFalse);
      expect(healed.generation, 2);
    });

    test('diff reports changed JSON paths without exposing a write port', () {
      const baseline = GameState(saveId: 'save', currentMapId: 'start');
      final service = const SandboxPlayerStateService();
      final opened = service.open(sandboxId: 'diff-run', state: baseline);
      final updated = service.giveItem(opened, itemId: 'potion', quantity: 1);

      final diff = service.diff(updated);

      expect(diff.entries, isNotEmpty);
      expect(
          diff.entries.any((entry) => entry.path.startsWith('/bag')), isTrue);
      expect(
        () => const SandboxProductionWriteGuard().assertCanWriteProduction(),
        throwsA(isA<SandboxIsolationException>()),
      );
    });

    test('save inspector and migration delegate to canonical core contracts',
        () {
      const codec = SaveEnvelopeCodec();
      final sourceIdentity = GameIdentity(
        gameId: 'com.pokemap.sandbox',
        gameVersion: '1.0.0',
        projectFormat: ProjectFormat.v2,
        saveFormat: 0,
        compatibilityId: 'campaign-v1',
      );
      final source = codec.create(
        identity: sourceIdentity,
        profileId: 'profile',
        slotId: 'slot',
        saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
        createdAt: DateTime.utc(2026, 7, 31, 10),
        updatedAt: DateTime.utc(2026, 7, 31, 10),
        status: SaveStatus.active,
        playTimeSeconds: 10,
        origin: SaveOrigin(
          kind: SaveOriginKind.manualImport,
          importedAt: DateTime.utc(2026, 7, 31, 10),
        ),
        state: const {'legacy': true},
      );
      final engine = SaveMigrationEngine(
        migrations: [
          SaveStateMigration(
            fromFormat: 0,
            toFormat: 1,
            migrate: (state) => {...state, 'migrated': true},
          ),
        ],
      );
      final targetIdentity = GameIdentity(
        gameId: 'com.pokemap.sandbox',
        gameVersion: '1.1.0',
        projectFormat: ProjectFormat.v2,
        saveFormat: 1,
        compatibilityId: 'campaign-v1',
      );
      const service = SandboxPlayerStateService();

      final inspection = service.inspectEnvelope(source);
      final migrated = service.migrateEnvelope(
        engine: engine,
        source: source,
        targetIdentity: targetIdentity,
        newSaveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c2',
        updatedAt: DateTime.utc(2026, 7, 31, 11),
      );

      expect(inspection.checksumValid, isTrue);
      expect(migrated.saveFormat, 1);
      expect(migrated.state['migrated'], isTrue);
      expect(source.state.containsKey('migrated'), isFalse);
    });
  });
}
