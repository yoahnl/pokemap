import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const codec = SaveEnvelopeCodec();

  group('SaveMigrationEngine', () {
    test('migrates N to N+1 on a copy and re-signs the target', () {
      final source = _source(codec);
      final engine = SaveMigrationEngine(
        migrations: <SaveStateMigration>[
          SaveStateMigration(
            fromFormat: 0,
            toFormat: 1,
            migrate: (state) {
              final player = state['player']! as Map<String, Object?>;
              player['facing'] = 'south';
              return state;
            },
          ),
        ],
      );

      final migrated = engine.migrate(
        source: source,
        targetIdentity: _identity(saveFormat: 1, gameVersion: '1.3.0'),
        newSaveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c2',
        updatedAt: DateTime.utc(2026, 7, 25, 11),
      );

      expect(migrated.saveFormat, 1);
      expect(migrated.gameVersion, '1.3.0');
      expect(migrated.saveId, isNot(source.saveId));
      expect(migrated.createdAt, source.createdAt);
      expect(migrated.updatedAt, DateTime.utc(2026, 7, 25, 11));
      expect(
        migrated.state,
        <String, Object?>{
          'player': <String, Object?>{'x': 4, 'facing': 'south'},
        },
      );
      expect(
        source.state,
        <String, Object?>{
          'player': <String, Object?>{'x': 4},
        },
        reason: 'migrations must never mutate the source envelope',
      );
      expect(codec.verifyChecksum(migrated), isTrue);
    });

    test('reports a missing migration link without touching source', () {
      final source = _source(codec);
      final engine = SaveMigrationEngine(migrations: const []);

      expect(engine.hasChain(fromFormat: 0, toFormat: 1), isFalse);
      expect(
        () => engine.migrate(
          source: source,
          targetIdentity: _identity(saveFormat: 1),
          newSaveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c2',
          updatedAt: DateTime.utc(2026, 7, 25, 11),
        ),
        throwsA(
          isA<SaveMigrationException>().having(
            (error) => error.code,
            'code',
            SaveMigrationErrorCode.chainUnavailable,
          ),
        ),
      );
      expect(source.state['player'], <String, Object?>{'x': 4});
    });

    test('wraps a failed migration and leaves the source intact', () {
      final source = _source(codec);
      final engine = SaveMigrationEngine(
        migrations: <SaveStateMigration>[
          SaveStateMigration(
            fromFormat: 0,
            toFormat: 1,
            migrate: (state) {
              (state['player']! as Map<String, Object?>)['x'] = 99;
              throw StateError('migration failed');
            },
          ),
        ],
      );

      expect(
        () => engine.migrate(
          source: source,
          targetIdentity: _identity(saveFormat: 1),
          newSaveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c2',
          updatedAt: DateTime.utc(2026, 7, 25, 11),
        ),
        throwsA(
          isA<SaveMigrationException>().having(
            (error) => error.code,
            'code',
            SaveMigrationErrorCode.migrationFailed,
          ),
        ),
      );
      expect(source.state['player'], <String, Object?>{'x': 4});
    });

    test('rejects package identity scripts disguised as a migration target',
        () {
      final source = _source(codec);
      final engine = SaveMigrationEngine(
        migrations: <SaveStateMigration>[
          SaveStateMigration(
            fromFormat: 0,
            toFormat: 1,
            migrate: (state) => state,
          ),
        ],
      );

      expect(
        () => engine.migrate(
          source: source,
          targetIdentity: GameIdentity(
            gameId: 'games.example.other',
            gameVersion: '1.0.0',
            projectFormat: ProjectFormat.v2,
            saveFormat: 1,
            compatibilityId: 'campaign-v1',
          ),
          newSaveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c2',
          updatedAt: DateTime.utc(2026, 7, 25, 11),
        ),
        throwsA(
          isA<SaveMigrationException>().having(
            (error) => error.code,
            'code',
            SaveMigrationErrorCode.identityMismatch,
          ),
        ),
      );
    });

    test('requires updatedAt to advance', () {
      final source = _source(codec);
      final engine = SaveMigrationEngine(
        migrations: <SaveStateMigration>[
          SaveStateMigration(
            fromFormat: 0,
            toFormat: 1,
            migrate: (state) => state,
          ),
        ],
      );

      expect(
        () => engine.migrate(
          source: source,
          targetIdentity: _identity(saveFormat: 1),
          newSaveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c2',
          updatedAt: source.updatedAt,
        ),
        throwsA(
          isA<SaveMigrationException>().having(
            (error) => error.code,
            'code',
            SaveMigrationErrorCode.invalidTimeline,
          ),
        ),
      );
    });

    test('refuses a manually constructed source with a stale checksum', () {
      final source = _source(codec);
      final tampered = SaveEnvelope(
        schemaVersion: source.schemaVersion,
        gameId: source.gameId,
        profileId: source.profileId,
        slotId: source.slotId,
        saveId: source.saveId,
        createdAt: source.createdAt,
        updatedAt: source.updatedAt,
        gameVersion: source.gameVersion,
        projectFormat: source.projectFormat,
        saveFormat: source.saveFormat,
        compatibilityId: source.compatibilityId,
        status: source.status,
        playTimeSeconds: source.playTimeSeconds,
        state: const <String, Object?>{'tampered': true},
        checksum: source.checksum,
      );
      final engine = SaveMigrationEngine(
        migrations: <SaveStateMigration>[
          SaveStateMigration(
            fromFormat: 0,
            toFormat: 1,
            migrate: (state) => state,
          ),
        ],
      );

      expect(
        () => engine.migrate(
          source: tampered,
          targetIdentity: _identity(saveFormat: 1),
          newSaveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c2',
          updatedAt: DateTime.utc(2026, 7, 25, 11),
        ),
        throwsA(
          isA<SaveMigrationException>().having(
            (error) => error.code,
            'code',
            SaveMigrationErrorCode.invalidSource,
          ),
        ),
      );
    });
  });
}

SaveEnvelope _source(SaveEnvelopeCodec codec) => codec.create(
      identity: _identity(saveFormat: 0, gameVersion: '1.2.0'),
      profileId: 'player-1',
      slotId: 'slot-1',
      saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
      createdAt: DateTime.utc(2026, 7, 25, 10),
      updatedAt: DateTime.utc(2026, 7, 25, 10),
      status: SaveStatus.active,
      playTimeSeconds: 10,
      state: <String, Object?>{
        'player': <String, Object?>{'x': 4},
      },
    );

GameIdentity _identity({
  required int saveFormat,
  String gameVersion = '1.2.0',
}) =>
    GameIdentity(
      gameId: 'games.example.complete',
      gameVersion: gameVersion,
      projectFormat: ProjectFormat.v2,
      saveFormat: saveFormat,
      compatibilityId: 'campaign-v1',
    );
