import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/features/saves/data/repositories/hub_save_repository_impl.dart';
import 'package:pokemap_hub/features/saves/domain/entities/save_storage_diagnostic.dart';
import 'package:pokemap_hub/features/session/application/gateways/hub_player_save_gateway.dart';
import 'package:pokemap_hub/features/session/application/services/hub_session_checkpoint_committer.dart';

void main() {
  const codec = SaveEnvelopeCodec();
  const mapper = GameStateSaveEnvelopeMapper();
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('avelune-baseline-continue-');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  for (final gameVersion in ['1.2.0', '1.3.0']) {
    test(
      'cold Hub instances continue baseline progress with game $gameVersion',
      () async {
        final bytes = _fixtureBytes('active-2d-save.json');
        final originalIdentity = _identity();
        final current = await _installBytes(root, originalIdentity, bytes);
        final firstGateway = HubPlayerSaveGateway(
          store: HubSaveStore(supportRoot: root, identity: originalIdentity),
        );
        final before = await firstGateway.readSummary(
          _address(originalIdentity),
        );
        final previousHandle = await firstGateway.openReadHandle(
          _address(originalIdentity),
        );
        expect(before?.canContinue, isTrue);
        expect(before?.playTimeSeconds, 7265);
        expect(before?.status, SaveStatus.active);

        final upgradedIdentity = _identity(gameVersion: gameVersion);
        final freshGateway = HubPlayerSaveGateway(
          store: HubSaveStore(supportRoot: root, identity: upgradedIdentity),
        );
        final address = _address(upgradedIdentity);
        final latest = await freshGateway.readLatestSummary();
        final summary = await freshGateway.readSummary(address);
        final envelope = await freshGateway.readLaunchableEnvelope(address);

        expect(latest?.address, address);
        expect(summary?.canContinue, isTrue);
        expect(summary?.unavailableReason, isNull);
        expect(summary?.playTimeSeconds, 7265);
        expect(await freshGateway.openReadHandle(address), previousHandle);
        expect(envelope, isNotNull);
        expect(envelope!.gameVersion, '1.2.0');
        expect(envelope.saveFormat, 2);
        expect(envelope.compatibilityId, 'baseline-campaign');
        expect(codec.verifyChecksum(envelope), isTrue);
        _expectProgress(mapper.restore(envelope));
        expect(await current.readAsBytes(), bytes);
      },
    );
  }

  test(
    'completed baseline retains its journal and authored continuation refusal',
    () async {
      final bytes = _fixtureBytes('completed-spatial-save.json');
      final identity = _identity(spatial: true);
      final current = await _installBytes(root, identity, bytes);
      final store = HubSaveStore(supportRoot: root, identity: identity);
      final gateway = HubPlayerSaveGateway(store: store);
      final address = _address(identity);

      final summary = await gateway.readSummary(address);
      final stored = await store.read(address);

      expect(stored.status, SaveSlotReadStatus.valid);
      expect(summary?.status, SaveStatus.completed);
      expect(summary?.canContinue, isFalse);
      expect(
        summary?.unavailableReason,
        PlayerSaveUnavailableReason.postGameContinuationRefused,
      );
      expect(await gateway.openReadHandle(address), isNull);
      expect(await gateway.readLaunchableEnvelope(address), isNull);
      final state = mapper.restore(stored.envelope!);
      expect(state.playerSpatialPosition?.x, 4.25);
      expect(state.playerSpatialPosition?.z, 7.75);
      expect(
        state.completionPartyJournal.records.single.endingId,
        'harbor-victory',
      );
      expect(
        state
            .completionPartyJournal
            .records
            .single
            .party
            .members
            .single
            .individualId,
        'baseline-starter-001',
      );
      expect(await current.readAsBytes(), bytes);
    },
  );

  test(
    'future save format is unavailable and preserves current and backup bytes',
    () async {
      final identity = _identity();
      final baseline = _fixtureBytes('active-2d-save.json');
      final future = _futureBytes('saveFormat');
      final current = await _installBytes(root, identity, future);
      final backup = File(p.join(current.parent.path, 'save.backup.json'));
      await backup.writeAsBytes(baseline, flush: true);
      final store = HubSaveStore(supportRoot: root, identity: identity);
      final gateway = HubPlayerSaveGateway(store: store);
      final address = _address(identity);

      final read = await store.read(address);
      final summary = await gateway.readSummary(address);

      expect(read.status, SaveSlotReadStatus.incompatible);
      expect(
        read.diagnostics.single.code,
        SaveStorageDiagnosticCode.saveFormatFuture,
      );
      expect(summary?.canContinue, isFalse);
      expect(
        summary?.unavailableReason,
        PlayerSaveUnavailableReason.incompatibleVersion,
      );
      expect(await gateway.readLaunchableEnvelope(address), isNull);
      expect(await current.readAsBytes(), future);
      expect(await backup.readAsBytes(), baseline);
      expect(
        Directory(p.join(current.parent.path, 'quarantine')).existsSync(),
        isFalse,
      );
    },
  );

  test(
    'future envelope schema stays unavailable without moving either generation',
    () async {
      final identity = _identity();
      final baseline = _fixtureBytes('active-2d-save.json');
      final future = _futureBytes('schemaVersion');
      final current = await _installBytes(root, identity, future);
      final backup = File(p.join(current.parent.path, 'save.backup.json'));
      await backup.writeAsBytes(baseline, flush: true);
      final store = HubSaveStore(supportRoot: root, identity: identity);

      final read = await store.read(_address(identity));

      expect(read.status, SaveSlotReadStatus.incompatible);
      expect(read.source, SaveSlotSource.current);
      final gateway = HubPlayerSaveGateway(store: store);
      final summary = await gateway.readSummary(_address(identity));
      expect(summary?.canContinue, isFalse);
      expect(
        summary?.unavailableReason,
        PlayerSaveUnavailableReason.incompatibleVersion,
      );
      expect(await gateway.readLaunchableEnvelope(_address(identity)), isNull);
      expect(await current.readAsBytes(), future);
      expect(await backup.readAsBytes(), baseline);
      expect(
        Directory(p.join(current.parent.path, 'quarantine')).existsSync(),
        isFalse,
      );
    },
  );

  test(
    'a valid checkpoint cannot overwrite an unknown future envelope schema',
    () async {
      final identity = _identity();
      final baseline = _fixtureBytes('active-2d-save.json');
      final future = _futureBytes('schemaVersion');
      final current = await _installBytes(root, identity, future);
      final backup = File(p.join(current.parent.path, 'save.backup.json'));
      await backup.writeAsBytes(baseline, flush: true);
      final store = HubSaveStore(supportRoot: root, identity: identity);
      final proposed = codec.decodeUtf8(baseline);

      await expectLater(
        store.writeVerified(proposed),
        throwsA(isA<SaveStorageException>()),
      );

      expect(await current.readAsBytes(), future);
      expect(await backup.readAsBytes(), baseline);
      expect(
        Directory(p.join(current.parent.path, 'quarantine')).existsSync(),
        isFalse,
      );
    },
  );

  test(
    'rejects an incompatible write before changing baseline generations',
    () async {
      final identity = _identity();
      final baseline = _fixtureBytes('active-2d-save.json');
      final current = await _installBytes(root, identity, baseline);
      final backup = File(p.join(current.parent.path, 'save.backup.json'));
      await backup.writeAsBytes(baseline, flush: true);
      final future = codec.decodeUtf8(
        _futureBytes('saveFormat', changeShape: false),
        acceptedSaveFormats: {999},
      );
      final store = HubSaveStore(supportRoot: root, identity: identity);

      await expectLater(
        store.writeVerified(future),
        throwsA(
          isA<SaveContractException>().having(
            (error) => error.code,
            'code',
            SaveContractErrorCode.unsupportedSaveFormat,
          ),
        ),
      );

      expect(await current.readAsBytes(), baseline);
      expect(await backup.readAsBytes(), baseline);
      _expectProgress(
        mapper.restore((await store.read(_address(identity))).envelope!),
      );
    },
  );

  test(
    'write recovery cannot replace an unknown future primary with its backup',
    () async {
      final identity = _identity();
      final baseline = _fixtureBytes('active-2d-save.json');
      final future = _futureBytes('schemaVersion');
      final current = await _installBytes(root, identity, future);
      final backup = File(p.join(current.parent.path, 'save.backup.json'));
      await backup.writeAsBytes(baseline, flush: true);
      final store = HubSaveStore(
        supportRoot: root,
        identity: identity,
        faultHook: (stage) async {
          if (stage == SaveWriteStage.afterTemporaryFlushed) {
            throw StateError('injected recovery before primary validation');
          }
        },
      );

      await expectLater(
        store.writeVerified(codec.decodeUtf8(baseline)),
        throwsA(isA<SaveStorageException>()),
      );

      expect(await current.readAsBytes(), future);
      expect(await backup.readAsBytes(), baseline);
      expect(
        Directory(p.join(current.parent.path, 'quarantine')).existsSync(),
        isFalse,
      );
    },
  );

  for (final failureStage in [
    SaveWriteStage.afterTemporaryVerified,
    SaveWriteStage.afterCurrentStagedAsBackup,
  ]) {
    test(
      'failed ${failureStage.name} checkpoint retains baseline generations',
      () async {
        final identity = _identity();
        final baseline = _fixtureBytes('active-2d-save.json');
        final current = await _installBytes(root, identity, baseline);
        final backup = File(p.join(current.parent.path, 'save.backup.json'));
        await backup.writeAsBytes(baseline, flush: true);
        final envelope = codec.decodeUtf8(baseline);
        final proposedState =
            jsonDecode(utf8.decode(baseline))['state'] as Map<String, dynamic>;
        (proposedState['trainerProfile'] as Map<String, dynamic>)['money'] =
            4444;
        final gateway = HubPlayerSaveGateway(
          store: HubSaveStore(
            supportRoot: root,
            identity: identity,
            faultHook: (stage) async {
              if (stage == failureStage) {
                throw StateError('injected ${stage.name}');
              }
            },
          ),
        );

        await expectLater(
          gateway.commit(
            GameSessionCheckpointCommit(
              descriptor: _context(identity),
              checkpoint: GameSessionCheckpoint(
                saveId: envelope.saveId,
                createdAt: envelope.createdAt,
                updatedAt: DateTime.utc(2026, 10, 24, 12, 1),
                playTimeSeconds: 7325,
                state: proposedState,
              ),
              status: SaveStatus.active,
            ),
          ),
          throwsA(
            isA<HubSessionCheckpointException>().having(
              (error) => error.code,
              'code',
              HubSessionCheckpointErrorCode.writeFailed,
            ),
          ),
        );

        expect(await current.readAsBytes(), baseline);
        expect(await backup.readAsBytes(), baseline);
        final freshGateway = HubPlayerSaveGateway(
          store: HubSaveStore(supportRoot: root, identity: identity),
        );
        final recovered = await freshGateway.readLaunchableEnvelope(
          _address(identity),
        );
        expect(recovered, isNotNull);
        _expectProgress(mapper.restore(recovered!));
      },
    );
  }
}

List<int> _fixtureBytes(String name) => File(
  p.join(
    '..',
    '..',
    'packages',
    'map_core',
    'test',
    'fixtures',
    'compatibility',
    'avelune_studio_0_3_31_331',
    name,
  ),
).readAsBytesSync();

List<int> _futureBytes(String field, {bool changeShape = true}) {
  const codec = SaveEnvelopeCodec();
  final json = jsonDecode(
    utf8.decode(_fixtureBytes('active-2d-save.json')),
  ) as Map<String, dynamic>;
  json[field] = 999;
  if (changeShape) {
    json['futureEnvelopeField'] = {'revision': 999};
    if (field == 'saveFormat') json['projectFormat'] = 'v999';
  }
  json['checksum'] = {
    'algorithm': 'sha256',
    'value': codec.computeChecksum(json),
  };
  return utf8.encode(jsonEncode(json));
}

Future<File> _installBytes(
  Directory root,
  GameIdentity identity,
  List<int> bytes,
) async {
  final slot = Directory(
    p.join(root.path, 'saves', identity.gameId, 'player-1', 'slot-1'),
  );
  await slot.create(recursive: true);
  final current = File(p.join(slot.path, 'save.json'));
  await current.writeAsBytes(bytes, flush: true);
  return current;
}

GameIdentity _identity({String gameVersion = '1.2.0', bool spatial = false}) =>
    GameIdentity(
      gameId: spatial
          ? 'games.example.baseline-spatial'
          : 'games.example.baseline',
      gameVersion: gameVersion,
      projectFormat: spatial ? ProjectFormat.v9 : ProjectFormat.v8,
      saveFormat: 2,
      compatibilityId: 'baseline-campaign',
    );

SaveSlotAddress _address(GameIdentity identity) => SaveSlotAddress(
  gameId: identity.gameId,
  profileId: 'player-1',
  slotId: 'slot-1',
);

GameSessionPublicContext _context(GameIdentity identity) =>
    GameSessionPublicContext(
      protocolVersion: 1,
      sessionId: 'baseline-continue',
      identity: identity,
      profileId: 'player-1',
      slotId: 'slot-1',
      launchMode: GameSessionLaunchMode.continueGame,
      runtimeApiVersion: '1.0.0',
      grantedCapabilities: {},
      locale: 'fr-FR',
      accessibility: const GameSessionAccessibilityOptions(),
    );

void _expectProgress(GameState state) {
  expect(state.saveId, '65edb580-8467-4ee5-9ad3-03a9f266dd95');
  expect(state.currentMapId, 'harbor');
  expect(state.playerPosition, const GridPos(x: 4, y: 7));
  expect(state.trainerProfile.money, 4321);
  expect(state.trainerProfile.badgeIds, ['harbor-badge']);
  expect(state.storyFlags.activeFlags, {'intro-complete', 'harbor-gate-open'});
  expect(
    state.narrativeFactRuntimeState.valueFor('story.badge.count')?.intValue,
    1,
  );
  expect(
    {for (final entry in state.bag.entries) entry.itemId: entry.quantity},
    {'potion': 7, 'poke-ball': 3, 'harbor-key': 1},
  );
  final starter = state.party.members.single;
  expect(starter.individualId, 'baseline-starter-001');
  expect(starter.level, 18);
  expect(starter.experience, 5832);
  expect(starter.currentHp, 27);
  expect(starter.currentPpByMoveId, {'thunder-shock': 19, 'quick-attack': 12});
  expect(
    state.pokemonStorage.boxes.single.pokemon.single.individualId,
    'baseline-boxed-001',
  );
}
