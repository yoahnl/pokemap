import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:pokemap_hub/pokemap_hub.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late File legacy;
  late HubSaveStore store;
  late LegacyGlobalSaveImporter importer;
  late SaveSlotAddress address;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('pokemap-legacy-import-');
    legacy = File('${root.path}/historical-game_save.json');
    await legacy.writeAsString(
      '{"saveId":"legacy-1","currentMapId":"port","debug":false}',
      flush: true,
    );
    final identity = GameIdentity(
      gameId: 'games.example.legacy',
      gameVersion: '1.0.0',
      projectFormat: ProjectFormat.v2,
      saveFormat: 1,
      compatibilityId: 'campaign-v1',
    );
    store = HubSaveStore(supportRoot: root, identity: identity);
    importer = LegacyGlobalSaveImporter(store: store);
    address = SaveSlotAddress(
      gameId: identity.gameId,
      profileId: 'player-1',
      slotId: 'slot-1',
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('requires preview and explicit confirmation', () async {
    final preview = await importer.inspect(
      sourceFile: legacy,
      decoder: _decoder,
    );

    expect(preview.sourceBytes, greaterThan(0));
    expect(preview.sourceSha256, hasLength(64));
    expect(preview.state['currentMapId'], 'port');
    await expectLater(
      () => importer.import(
        preview: preview,
        address: address,
        saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
        importedAt: DateTime.utc(2026, 7, 25, 10),
        confirmed: false,
      ),
      throwsA(
        isA<LegacySaveImportException>().having(
          (error) => error.code,
          'code',
          LegacySaveImportErrorCode.confirmationRequired,
        ),
      ),
    );
    expect((await store.read(address)).status, SaveSlotReadStatus.missing);
  });

  test('imports by copy with origin metadata and preserves source bytes',
      () async {
    final before = await legacy.readAsBytes();
    final preview = await importer.inspect(
      sourceFile: legacy,
      decoder: _decoder,
    );

    final envelope = await importer.import(
      preview: preview,
      address: address,
      saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
      importedAt: DateTime.utc(2026, 7, 25, 10),
      confirmed: true,
    );

    expect(envelope.origin!.kind, SaveOriginKind.legacyGlobalSave);
    expect(envelope.origin!.importedAt, DateTime.utc(2026, 7, 25, 10));
    expect(envelope.state, <String, Object?>{'currentMapId': 'port'});
    expect(await legacy.readAsBytes(), before);
    expect((await store.read(address)).envelope, envelope);
  });

  test('rejects a source changed after preview', () async {
    final preview = await importer.inspect(
      sourceFile: legacy,
      decoder: _decoder,
    );
    await legacy.writeAsString('{"currentMapId":"changed"}', flush: true);

    await expectLater(
      () => importer.import(
        preview: preview,
        address: address,
        saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
        importedAt: DateTime.utc(2026, 7, 25, 10),
        confirmed: true,
      ),
      throwsA(
        isA<LegacySaveImportException>().having(
          (error) => error.code,
          'code',
          LegacySaveImportErrorCode.sourceChanged,
        ),
      ),
    );
  });

  test('requires a separate overwrite confirmation for a non-empty slot',
      () async {
    final preview = await importer.inspect(
      sourceFile: legacy,
      decoder: _decoder,
    );
    await store.write(
      const SaveEnvelopeCodec().create(
        identity: store.identity,
        profileId: 'player-1',
        slotId: 'slot-1',
        saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c2',
        createdAt: DateTime.utc(2026, 7, 25, 9),
        updatedAt: DateTime.utc(2026, 7, 25, 9),
        status: SaveStatus.active,
        playTimeSeconds: 1,
        state: <String, Object?>{'currentMapId': 'existing'},
      ),
    );

    await expectLater(
      () => importer.import(
        preview: preview,
        address: address,
        saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
        importedAt: DateTime.utc(2026, 7, 25, 10),
        confirmed: true,
        overwriteConfirmed: false,
      ),
      throwsA(
        isA<LegacySaveImportException>().having(
          (error) => error.code,
          'code',
          LegacySaveImportErrorCode.overwriteConfirmationRequired,
        ),
      ),
    );
    expect(
      (await store.read(address)).envelope!.state['currentMapId'],
      'existing',
    );
  });
}

Map<String, Object?> _decoder(Map<String, Object?> legacy) => <String, Object?>{
      'currentMapId': legacy['currentMapId'],
    };
