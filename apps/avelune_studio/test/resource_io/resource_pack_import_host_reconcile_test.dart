import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart' show NativeResourcePackRef;

import '../../../../packages/map_authoring/test/domains/assets/resource_pack_import_fixture.dart';
import '../../../../packages/map_authoring/test/domains/assets/resource_pack_export_test.dart'
    show nativeImage;
import 'resource_pack_import_host_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('1282 distinct native aliases reconcile a real compact paginated receipt', () async {
    const count = 1282;
    final source = await ResourcePackImportFixture.create(
      sourceManifest: ProjectManifest(
        name: 'Bulk aliases',
        maps: [],
        settings: ProjectSettings(tileWidth: 2, tileHeight: 2),
        tilesets: [
          for (var i = 0; i < count; i++)
            ProjectTilesetEntry(
              id: 'atlas-$i',
              name: 'Atlas $i',
              relativePath: 'assets/image-$i.png',
              source: ProjectTilesetSource.regularAtlas(
                assetId: 'image-$i',
                pixelWidth: 2,
                pixelHeight: 2,
                tileWidth: 2,
                tileHeight: 2,
              ),
            ),
        ],
      ),
      sourceFiles: [
        for (var i = 0; i < count; i++)
          nativeImage(id: 'image-$i', path: 'assets/image-$i.png'),
      ],
      roots: [
        for (var i = 0; i < count; i++)
          NativeResourcePackRef(kind: ResourcePackKind.tileset, id: 'atlas-$i'),
      ],
    );
    late RecordingPackPort recording;
    final host = await ResourcePackTestHost.create(
      sourceFixture: source,
      wrapPack: (port) => recording = RecordingPackPort(port),
    );
    addTearDown(host.dispose);
    final beforeState = await host.resourceState();
    await host.prepare();
    await host.transfer.apply();
    expect(host.transfer.error, isNull);
    final actual = recording.projection!['receipt']! as Map;
    expect(
      (actual['diff']! as Map)['diffRef'],
      isA<String>(),
      reason:
          'receiptBytes=${utf8.encode(jsonEncode(actual)).length}, diffEntries=${(actual['diff']! as Map)['entries'] is List ? ((actual['diff']! as Map)['entries']! as List).length : 'paged'}',
    );
    expect(actual['affectedResources'], isA<Map>());
    expect(recording.receipt!.changedPaths.length, greaterThan(count));
    final afterState = await host.resourceState();
    final expected = <String, String?>{};
    for (final identity in {
      ...beforeState.fingerprints.keys,
      ...afterState.fingerprints.keys,
    }) {
      if (beforeState.fingerprints[identity] !=
          afterState.fingerprints[identity]) {
        expected[afterState.paths[identity] ?? beforeState.paths[identity]!] =
            afterState.fingerprints[identity];
      }
    }
    expect(recording.receipt!.changedPaths.toSet(), expected.keys.toSet());
    expect(recording.receipt!.pathRevisions, expected);
    expect(
      recording.receipt!.pathRevisions.length,
      recording.receipt!.changedPaths.length,
    );
    expect((await host.reopen()).tilesets, hasLength(count));
    final sentinelPath = recording.receipt!.changedPaths.lastWhere(
      (path) => path.endsWith('.png') && !path.contains('/blobs/'),
    );
    expect(
      recording.receipt!.changedPaths.indexOf(sentinelPath),
      greaterThan(recording.receipt!.changedPaths.length - 100),
    );
    final sentinel = File('${host.root.path}/$sentinelPath');
    final original = await sentinel.readAsBytes();
    try {
      final altered = [...original];
      altered[altered.length - 1] ^= 1;
      await sentinel.writeAsBytes(altered);
      await expectLater(
        host.pack.reconcile(recording.receipt!),
        throwsA(anything),
      );
    } finally {
      await sentinel.writeAsBytes(original);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('commit refresh failure retains actual receipt and navigation retry never applies twice', () async {
    var fail = true;
    final host = await ResourcePackTestHost.create(
      beforeReconciliation: () async {
        if (fail) throw StateError('refresh unavailable');
      },
    );
    addTearDown(host.dispose);
    await host.prepare();
    await host.transfer.apply();
    expect(host.transfer.requiresReconciliation, isTrue);
    expect(host.navigation.pendingReceipt, isNotNull);
    expect(await host.transfer.requestClose(), isFalse);
    final receipt = host.navigation.pendingReceipt!;
    expect(receipt.operationId, startsWith('studio_pack_'));
    expect(receipt.snapshotBeforeRevision, isNot(receipt.beforeRevision));
    expect(receipt.pathRevisions, isNotEmpty);
    final bytes = await host.manifestFile.readAsBytes();
    fail = false;
    expect(await host.navigation.retryReconciliation(), isTrue);
    expect(host.navigation.pendingReceipt, isNull);
    expect(host.transfer.requiresReconciliation, isFalse);
    expect(await host.transfer.requestClose(), isTrue);
    expect(await host.manifestFile.readAsBytes(), bytes);
  });

  test('invalid archive preserves the target', () async {
    final host = await ResourcePackTestHost.create();
    addTearDown(host.dispose);
    final before = await host.manifestFile.readAsBytes();
    await host.archiveFile.writeAsString('not an archive');
    await host.transfer.beginImport();
    expect(host.transfer.error, isNotNull);
    expect(await host.manifestFile.readAsBytes(), before);
  });
  test(
    'stale preparation refuses apply and preserves the newer target',
    () async {
      final host = await ResourcePackTestHost.create();
      addTearDown(host.dispose);
      await host.prepare();
      final changed = (await host.reopen()).copyWith(
        name: 'Changed after preparation',
      );
      await host.manifestFile.writeAsString(jsonEncode(changed.toJson()));
      final bytes = await host.manifestFile.readAsBytes();
      await host.transfer.apply();
      expect(host.transfer.error, isNotNull);
      expect(host.transfer.requiresRecovery, isFalse);
      expect(await host.manifestFile.readAsBytes(), bytes);
      expect((await host.reopen()).elements, isEmpty);
    },
  );
}
