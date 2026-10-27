import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/features/saves/data/repositories/hub_save_codec_executor.dart';
import 'package:pokemap_hub/features/saves/data/repositories/hub_save_repository_impl.dart';
import 'package:pokemap_hub/features/saves/data/repositories/save_slot_integrity.dart';
import 'package:pokemap_hub/features/saves/domain/entities/save_storage_diagnostic.dart';
import 'package:test/test.dart';

const _codec = SaveEnvelopeCodec();

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('p5-codec-test-');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
    'real workers preserve Unicode bytes and checksum without store captures',
    () async {
      final port = RawReceivePort();
      addTearDown(port.close);
      final runner = _Runner(owner: port);
      final envelope = _envelope(1);
      final stages = <SaveWriteStage>[];
      final store = HubSaveStore(
        supportRoot: root,
        identity: _identity(),
        codecExecutor: HubSaveCodecExecutor(runner: runner.run),
        faultHook: (stage) async {
          expect(port.sendPort, isA<SendPort>());
          stages.add(stage);
        },
      );

      final confirmed = await store.writeVerified(envelope);
      final reopened = await HubSaveStore(
        supportRoot: root,
        identity: _identity(),
      ).read(envelope.address);

      expect(await _current(root).readAsBytes(), _codec.encodeUtf8(envelope));
      expect(confirmed.checksum, envelope.checksum);
      expect(reopened.envelope!.state, envelope.state);
      expect(stages.last, SaveWriteStage.afterCurrentConfirmed);
    },
  );

  test(
    'reserves the slot before waiting for its first validation worker',
    () async {
      final runner = _Runner(gateAt: 1);
      final first = HubSaveStore(
        supportRoot: root,
        identity: _identity(),
        codecExecutor: HubSaveCodecExecutor(runner: runner.run),
      );
      final second = HubSaveStore(
        supportRoot: root,
        identity: _identity(),
        codecExecutor: HubSaveCodecExecutor(runner: runner.run),
      );
      final firstWrite = first.writeVerified(_envelope(1));
      await runner.entered.future;
      final secondWrite = second.writeVerified(_envelope(2));
      await Future<void>(() {});

      try {
        expect(runner.phases, ['hub-save.validate']);
        expect(await Directory(p.join(root.path, 'saves')).exists(), isFalse);
      } finally {
        runner.release.complete();
        await Future.wait([firstWrite, secondWrite]);
      }

      expect(
        (await first.read(_envelope(1).address)).envelope!.saveId,
        _envelope(2).saveId,
      );
      expect(
        _codec.decode(await _backup(root).readAsString()).saveId,
        _envelope(1).saveId,
      );
    },
  );

  test(
    'does not acknowledge persistence before the confirmation worker returns',
    () async {
      final runner = _Runner(gateAt: 4);
      final store = HubSaveStore(
        supportRoot: root,
        identity: _identity(),
        codecExecutor: HubSaveCodecExecutor(runner: runner.run),
      );
      var acknowledged = false;
      final writing = store.writeVerified(_envelope(1)).then((value) {
        acknowledged = true;
        return value;
      });
      await runner.entered.future;
      await Future<void>(() {});

      try {
        expect(runner.phases.last, 'hub-save.decode');
        expect(await _current(root).exists(), isTrue);
        expect(acknowledged, isFalse);
      } finally {
        runner.release.complete();
        await writing;
      }
      expect((await writing).checksum, _envelope(1).checksum);
      expect(acknowledged, isTrue);
    },
  );

  test(
    'offloads each verification on first write, rotation, replay and read',
    () async {
      final runner = _Runner();
      final store = HubSaveStore(
        supportRoot: root,
        identity: _identity(),
        codecExecutor: HubSaveCodecExecutor(runner: runner.run),
      );

      await store.writeVerified(_envelope(1));
      expect(runner.phases, [
        'hub-save.validate',
        'hub-save.encode',
        'hub-save.decode',
        'hub-save.decode',
      ]);
      runner.phases.clear();
      await store.writeVerified(_envelope(2));
      expect(runner.phases, [
        'hub-save.validate',
        'hub-save.encode',
        'hub-save.decode',
        'hub-save.decode-candidate',
        'hub-save.decode',
      ]);
      final backupBytes = await _backup(root).readAsBytes();
      runner.phases.clear();
      await store.writeVerified(_envelope(2));
      expect(runner.phases, [
        'hub-save.validate',
        'hub-save.encode',
        'hub-save.decode',
        'hub-save.decode-candidate',
      ]);
      expect(await _backup(root).readAsBytes(), backupBytes);
      runner.phases.clear();
      await store.read(_envelope(2).address);
      expect(runner.phases, ['hub-save.decode-candidate']);
    },
  );

  test(
    'worker failure before IO leaves the storage namespace untouched',
    () async {
      final runner = _Runner(failAt: 1);
      final store = HubSaveStore(
        supportRoot: root,
        identity: _identity(),
        codecExecutor: HubSaveCodecExecutor(runner: runner.run),
      );

      await expectLater(
        store.writeVerified(_envelope(1)),
        throwsA(
          isA<HubSaveCodecExecutionException>().having(
            (error) => error.cause,
            'cause',
            isA<StateError>(),
          ),
        ),
      );
      expect(await Directory(p.join(root.path, 'saves')).exists(), isFalse);
      await store.writeVerified(_envelope(2));
      expect((await store.read(_envelope(2).address)).canContinue, isTrue);
    },
  );

  test(
    'worker failure at confirmation preserves the recoverable generation',
    () async {
      final runner = _Runner(failAt: 4);
      final store = HubSaveStore(
        supportRoot: root,
        identity: _identity(),
        codecExecutor: HubSaveCodecExecutor(runner: runner.run),
      );

      await expectLater(
        store.writeVerified(_envelope(1)),
        throwsA(
          isA<HubSaveCodecExecutionException>().having(
            (error) => error.cause,
            'cause',
            isA<StateError>(),
          ),
        ),
      );
      final reopened = await HubSaveStore(
        supportRoot: root,
        identity: _identity(),
      ).read(_envelope(1).address);
      expect(reopened.envelope!.checksum, _envelope(1).checksum);
    },
  );

  test(
    'worker decode retains the injected byte limit and expected address',
    () async {
      const executor = HubSaveCodecExecutor();
      final envelope = _envelope(1);
      final source = _codec.encode(envelope);
      await expectLater(
        executor.decode(
          codec: const SaveEnvelopeCodec(maxEncodedBytes: 20),
          source: source,
          address: envelope.address,
          acceptedSaveFormats: {2},
        ),
        throwsA(_contract(SaveContractErrorCode.sizeLimitExceeded)),
      );
      await expectLater(
        executor.decode(
          codec: _codec,
          source: source,
          address: SaveSlotAddress(
            gameId: envelope.gameId,
            profileId: 'other-player',
            slotId: envelope.slotId,
          ),
          acceptedSaveFormats: {2},
        ),
        throwsA(_contract(SaveContractErrorCode.addressMismatch)),
      );
      await expectLater(
        executor.decode(
          codec: _codec,
          source: source,
          address: envelope.address,
          acceptedSaveFormats: {1},
        ),
        throwsA(_contract(SaveContractErrorCode.unsupportedSaveFormat)),
      );
    },
  );

  for (final failure in [
    IsolateSpawnException('candidate worker unavailable'),
    RemoteError('candidate worker unavailable', 'remote stack'),
  ]) {
    for (final withBackup in [false, true]) {
      test(
        '${failure.runtimeType} during read preserves a valid slot with backup=$withBackup',
        () async {
          final healthy = HubSaveStore(
            supportRoot: root,
            identity: _identity(),
          );
          await healthy.writeVerified(_envelope(1));
          if (withBackup) await healthy.writeVerified(_envelope(2));
          final before = await _slotFiles(root);
          final runner = _Runner(
            failPhase: 'hub-save.decode-candidate',
            failure: failure,
          );
          final unavailable = HubSaveStore(
            supportRoot: root,
            identity: _identity(),
            codecExecutor: HubSaveCodecExecutor(runner: runner.run),
          );

          await expectLater(
            unavailable.read(_envelope(1).address),
            throwsA(_executionFailure(failure)),
          );
          final after = await _slotFiles(root);
          expect(after.$1, before.$1);
          expect(after.$2, before.$2);
          final continued = await HubSaveStore(
            supportRoot: root,
            identity: _identity(),
          ).findContinue(profileId: 'player-1');
          expect(
            continued!.envelope!.checksum,
            _envelope(withBackup ? 2 : 1).checksum,
          );
        },
      );
    }

    test(
      '${failure.runtimeType} during write preserves current and backup',
      () async {
        final healthy = HubSaveStore(supportRoot: root, identity: _identity());
        await healthy.writeVerified(_envelope(1));
        await healthy.writeVerified(_envelope(2));
        final before = await _slotFiles(root);
        final runner = _Runner(
          failPhase: 'hub-save.decode-candidate',
          failure: failure,
        );
        final unavailable = HubSaveStore(
          supportRoot: root,
          identity: _identity(),
          codecExecutor: HubSaveCodecExecutor(runner: runner.run),
        );

        await expectLater(
          unavailable.writeVerified(_envelope(3)),
          throwsA(_executionFailure(failure)),
        );
        final after = await _slotFiles(root);
        expect(after.$1, before.$1);
        expect(after.$2, before.$2);
        final continued = await HubSaveStore(
          supportRoot: root,
          identity: _identity(),
        ).findContinue(profileId: 'player-1');
        expect(continued!.envelope!.checksum, _envelope(2).checksum);
      },
    );
  }

  test(
    'isValid propagates worker execution failure without judging the file',
    () async {
      await HubSaveStore(
        supportRoot: root,
        identity: _identity(),
      ).writeVerified(_envelope(1));
      final runner = _Runner(
        failPhase: 'hub-save.decode-candidate',
        failure: IsolateSpawnException('worker unavailable'),
      );
      final integrity = SaveSlotIntegrity(
        supportRoot: root,
        identity: _identity(),
        codec: _codec,
        compatibilityEvaluator: const SaveCompatibilityEvaluator(),
        codecExecutor: HubSaveCodecExecutor(runner: runner.run),
      );
      final before = await _slotFiles(root);

      await expectLater(
        integrity.isValid(_current(root), _envelope(1).address),
        throwsA(isA<HubSaveCodecExecutionException>()),
      );
      final after = await _slotFiles(root);
      expect(after.$1, before.$1);
      expect(after.$2, before.$2);
    },
  );

  for (final operation in ['Continue', 'listSlots']) {
    test(
      '$operation reports an unavailable worker instead of hiding the slot',
      () async {
        await HubSaveStore(
          supportRoot: root,
          identity: _identity(),
        ).writeVerified(_envelope(1));
        final failure = IsolateSpawnException('candidate worker unavailable');
        final runner = _Runner(
          failPhase: 'hub-save.decode-candidate',
          failure: failure,
        );
        final unavailable = HubSaveStore(
          supportRoot: root,
          identity: _identity(),
          codecExecutor: HubSaveCodecExecutor(runner: runner.run),
        );
        final before = await _slotFiles(root);

        await expectLater(
          operation == 'Continue'
              ? unavailable.findContinue(profileId: 'player-1')
              : unavailable.listSlots(profileId: 'player-1'),
          throwsA(_executionFailure(failure)),
        );
        final after = await _slotFiles(root);
        expect(after.$1, before.$1);
        expect(after.$2, before.$2);
      },
    );
  }

  test(
    'recovery propagates worker execution failure before changing files',
    () async {
      final healthy = HubSaveStore(supportRoot: root, identity: _identity());
      await healthy.writeVerified(_envelope(1));
      await healthy.writeVerified(_envelope(2));
      final runner = _Runner(
        failPhase: 'hub-save.decode-candidate',
        failure: IsolateSpawnException('worker unavailable'),
      );
      final integrity = SaveSlotIntegrity(
        supportRoot: root,
        identity: _identity(),
        codec: _codec,
        compatibilityEvaluator: const SaveCompatibilityEvaluator(),
        codecExecutor: HubSaveCodecExecutor(runner: runner.run),
      );
      final before = await _slotFiles(root);

      await expectLater(
        integrity.restoreAnyValidCurrent(
          slot: _current(root).parent,
          address: _envelope(1).address,
          temporary: File(p.join(_current(root).parent.path, 'missing.tmp')),
        ),
        throwsA(isA<HubSaveCodecExecutionException>()),
      );
      final after = await _slotFiles(root);
      expect(after.$1, before.$1);
      expect(after.$2, before.$2);
    },
  );

  test(
    'failed recovery keeps the original interruption and worker failure',
    () async {
      final healthy = HubSaveStore(supportRoot: root, identity: _identity());
      await healthy.writeVerified(_envelope(1));
      await healthy.writeVerified(_envelope(2));
      final original = StateError('original write interruption');
      final runner = _Runner(
        failPhase: 'hub-save.decode-candidate',
        failure: IsolateSpawnException('recovery worker unavailable'),
      );
      final failing = HubSaveStore(
        supportRoot: root,
        identity: _identity(),
        codecExecutor: HubSaveCodecExecutor(runner: runner.run),
        faultHook: (stage) async {
          if (stage == SaveWriteStage.afterTemporaryVerified) throw original;
        },
      );
      final before = await _slotFiles(root);

      await expectLater(
        failing.writeVerified(_envelope(3)),
        throwsA(
          isA<HubSaveCodecExecutionException>()
              .having(
                (error) => error.operation,
                'operation',
                'hub-save.decode-candidate',
              )
              .having(
                (error) => error.cause,
                'cause',
                isA<IsolateSpawnException>(),
              )
              .having(
                (error) => error.precedingError,
                'preceding error',
                same(original),
              ),
        ),
      );
      final after = await _slotFiles(root);
      expect(after.$1, before.$1);
      expect(after.$2, before.$2);
    },
  );

  test('store verification retains its custom codec byte limit', () async {
    final store = HubSaveStore(
      supportRoot: root,
      identity: _identity(),
      codec: const SaveEnvelopeCodec(maxEncodedBytes: 20),
    );
    await expectLater(
      store.writeVerified(_envelope(1)),
      throwsA(
        isA<SaveStorageException>()
            .having(
              (error) => error.code,
              'code',
              SaveStorageErrorCode.writeInterrupted,
            )
            .having(
              (error) => error.cause,
              'cause',
              _contract(SaveContractErrorCode.sizeLimitExceeded),
            ),
      ),
    );
  });

  test(
    'migration snapshot encoding runs through the same pure worker boundary',
    () async {
      final source = _envelope(1, identity: _identity(format: 1));
      await HubSaveStore(
        supportRoot: root,
        identity: _identity(format: 1),
      ).writeVerified(source);
      final runner = _Runner();
      final store = HubSaveStore(
        supportRoot: root,
        identity: _identity(),
        codecExecutor: HubSaveCodecExecutor(runner: runner.run),
      );
      final migrated = await store.migrate(
        address: source.address,
        engine: SaveMigrationEngine(
          migrations: [
            SaveStateMigration(
              fromFormat: 1,
              toFormat: 2,
              migrate: (state) => {...state, 'migrated': true},
            ),
          ],
        ),
        newSaveId: _envelope(2).saveId,
        updatedAt: _envelope(2).updatedAt,
      );

      expect(runner.phases, [
        'hub-save.decode-candidate',
        'hub-save.encode',
        'hub-save.decode-candidate',
        'hub-save.encode',
        'hub-save.decode',
        'hub-save.decode-candidate',
        'hub-save.decode',
      ]);
      expect(
        await migrated.snapshot.primaryFile.readAsBytes(),
        _codec.encodeUtf8(source),
      );
      expect(migrated.envelope.saveFormat, 2);
      expect(migrated.envelope.state['migrated'], isTrue);
    },
  );

  test(
    'validation worker rejects a changed checksum before creating storage',
    () async {
      final json = _codec.toJson(_envelope(1));
      json['state'] = {'marker': 'tampered'};
      final tampered = _codec.decodeJson(json, verifyChecksum: false);
      final store = HubSaveStore(supportRoot: root, identity: _identity());

      await expectLater(
        store.writeVerified(tampered),
        throwsA(_contract(SaveContractErrorCode.checksumMismatch)),
      );
      expect(await Directory(p.join(root.path, 'saves')).exists(), isFalse);
    },
  );

  test(
    'incompatible validation result is rejected before filesystem creation',
    () async {
      final store = HubSaveStore(supportRoot: root, identity: _identity());
      await expectLater(
        store.writeVerified(
          _envelope(1, identity: _identity(compatibility: 'other')),
        ),
        throwsA(
          isA<SaveStorageException>().having(
            (error) => error.code,
            'code',
            SaveStorageErrorCode.invalidEnvelope,
          ),
        ),
      );
      expect(await Directory(p.join(root.path, 'saves')).exists(), isFalse);
    },
  );

  test(
    'candidate worker preserves old formats and cross-game compatibility',
    () async {
      const executor = HubSaveCodecExecutor();
      final old = _envelope(
        1,
        identity: _identity(format: 1, gameId: 'games.example.other'),
      );
      final decoded = await executor.decodeCandidate(
        codec: _codec,
        source: _codec.encode(old),
        address: _envelope(1).address,
        currentSaveFormat: 2,
      );
      expect(decoded.gameId, old.gameId);
      expect(decoded.saveFormat, 1);
      expect(decoded.checksum, old.checksum);
      await expectLater(
        executor.decodeCandidate(
          codec: _codec,
          source: _codec.encode(old),
          address: SaveSlotAddress(
            gameId: old.gameId,
            profileId: 'other-player',
            slotId: old.slotId,
          ),
          currentSaveFormat: 2,
        ),
        throwsA(_contract(SaveContractErrorCode.addressMismatch)),
      );
    },
  );

  test(
    'candidate worker retains corruption and future contract error codes',
    () async {
      const executor = HubSaveCodecExecutor();
      final envelope = _envelope(1);
      Future<SaveEnvelope> decode(String source) => executor.decodeCandidate(
        codec: _codec,
        source: source,
        address: envelope.address,
        currentSaveFormat: 2,
      );
      await expectLater(decode('{broken'), throwsFormatException);
      await expectLater(decode('[]'), throwsFormatException);
      final altered = _codec.toJson(envelope);
      altered['state'] = {'marker': 'corrupted'};
      await expectLater(
        decode(jsonEncode(altered)),
        throwsA(_contract(SaveContractErrorCode.checksumMismatch)),
      );
      altered['saveFormat'] = 3;
      await expectLater(
        decode(jsonEncode(altered)),
        throwsA(_contract(SaveContractErrorCode.unsupportedSaveFormat)),
      );
      altered['schemaVersion'] = 2;
      await expectLater(
        decode(jsonEncode(altered)),
        throwsA(_contract(SaveContractErrorCode.unsupportedSchema)),
      );
    },
  );
}

final class _Runner {
  _Runner({this.gateAt, this.failAt, this.owner, this.failPhase, this.failure});

  final int? gateAt;
  final int? failAt;
  final Object? owner;
  final String? failPhase;
  final Object? failure;
  final phases = <String?>[];
  final entered = Completer<void>();
  final release = Completer<void>();
  int calls = 0;

  Future<T> run<T>(
    FutureOr<T> Function() operation, {
    String? debugName,
  }) async {
    phases.add(debugName);
    final call = ++calls;
    if (call == gateAt) {
      entered.complete();
      await release.future;
    }
    if (call == failAt) throw StateError('injected worker failure');
    if (debugName == failPhase && failure != null) throw failure!;
    return Isolate.run(operation, debugName: debugName);
  }
}

Matcher _contract(SaveContractErrorCode code) =>
    isA<SaveContractException>().having((error) => error.code, 'code', code);

Matcher _executionFailure(Object failure) =>
    isA<HubSaveCodecExecutionException>()
        .having(
          (error) => error.operation,
          'operation',
          'hub-save.decode-candidate',
        )
        .having((error) => error.cause, 'cause', same(failure));

Future<(List<String>, Map<String, List<int>>)> _slotFiles(
  Directory root,
) async {
  final paths = <String>[];
  final bytes = <String, List<int>>{};
  final slot = _current(root).parent;
  await for (final entry in slot.list(recursive: true, followLinks: false)) {
    final path = p.relative(entry.path, from: slot.path);
    paths.add(path);
    if (entry is File) bytes[path] = await entry.readAsBytes();
  }
  paths.sort();
  return (paths, bytes);
}

File _current(Directory root) => File(
  p.join(
    root.path,
    'saves',
    'games.example.codec',
    'player-1',
    'slot-1',
    'save.json',
  ),
);

File _backup(Directory root) =>
    File(p.join(_current(root).parent.path, 'save.backup.json'));

GameIdentity _identity({
  int format = 2,
  String gameId = 'games.example.codec',
  String compatibility = 'campaign-v1',
}) => GameIdentity(
  gameId: gameId,
  gameVersion: '1.0.0',
  projectFormat: ProjectFormat.v9,
  saveFormat: format,
  compatibilityId: compatibility,
);

SaveEnvelope _envelope(int revision, {GameIdentity? identity}) => _codec.create(
  identity: identity ?? _identity(),
  profileId: 'player-1',
  slotId: 'slot-1',
  saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c$revision',
  createdAt: DateTime.utc(2026, 10, 27),
  updatedAt: DateTime.utc(2026, 10, 27, 0, revision),
  status: SaveStatus.active,
  playTimeSeconds: revision,
  state: {
    'marker': revision,
    'unicode': 'Évoli à l’aube 🌅 — 日本語',
    'nested': {
      'list': [true, null, 4.5, 'sauvegardé'],
    },
  },
);
