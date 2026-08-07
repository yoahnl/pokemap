import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub.dart';

void main() {
  test('installs a hash-bound editor export and consumes the pair', () async {
    final inbox = await Directory.systemTemp.createTemp('hub-export-inbox-');
    addTearDown(() => inbox.delete(recursive: true));
    final package = await _writeRequest(inbox, requestId: 'export-001');
    var calls = 0;
    GamePackageInstallSource? observedSource;
    final consumer = EditorExportInstallInbox(
      inbox: inbox,
      installer: (
        file, {
        required source,
        required cancellationToken,
        onProgress,
      }) async {
        calls++;
        observedSource = source;
        expect(file.path, package.path);
        expect(cancellationToken.isCancelled, isFalse);
      },
    );

    final results = await consumer.consumePending();

    expect(results, hasLength(1));
    expect(results.single.status, EditorExportInstallStatus.installed);
    expect(calls, 1);
    expect(observedSource, GamePackageInstallSource.localExport);
    expect(await package.exists(), isFalse);
    expect(
      await File(p.join(inbox.path, 'export-001.request.json')).exists(),
      isFalse,
    );
  });

  test('keeps package and request when installation fails', () async {
    final inbox = await Directory.systemTemp.createTemp('hub-export-inbox-');
    addTearDown(() => inbox.delete(recursive: true));
    final package = await _writeRequest(inbox, requestId: 'export-002');
    final request = File(p.join(inbox.path, 'export-002.request.json'));
    final consumer = EditorExportInstallInbox(
      inbox: inbox,
      installer: (
        file, {
        required source,
        required cancellationToken,
        onProgress,
      }) async {
        throw const FileSystemException('simulated install failure');
      },
    );

    final results = await consumer.consumePending();

    expect(results.single.status, EditorExportInstallStatus.failed);
    expect(results.single.code, 'installationFailed');
    expect(await package.exists(), isTrue);
    expect(await request.exists(), isTrue);
  });

  test('rejects a digest mismatch without invoking the installer', () async {
    final inbox = await Directory.systemTemp.createTemp('hub-export-inbox-');
    addTearDown(() => inbox.delete(recursive: true));
    final package = await _writeRequest(inbox, requestId: 'export-003');
    await package.writeAsString('modified', flush: true);
    var called = false;
    final consumer = EditorExportInstallInbox(
      inbox: inbox,
      installer: (
        file, {
        required source,
        required cancellationToken,
        onProgress,
      }) async {
        called = true;
      },
    );

    final results = await consumer.consumePending();

    expect(results.single.status, EditorExportInstallStatus.failed);
    expect(results.single.code, 'digestMismatch');
    expect(called, isFalse);
    expect(await package.exists(), isTrue);
  });

  test('consumes requests in deterministic filename order', () async {
    final inbox = await Directory.systemTemp.createTemp('hub-export-inbox-');
    addTearDown(() => inbox.delete(recursive: true));
    await _writeRequest(inbox, requestId: 'export-020');
    await _writeRequest(inbox, requestId: 'export-010');
    final observed = <String>[];
    final consumer = EditorExportInstallInbox(
      inbox: inbox,
      installer: (
        file, {
        required source,
        required cancellationToken,
        onProgress,
      }) async {
        observed.add(p.basename(file.path));
      },
    );

    final results = await consumer.consumePending();

    expect(
      results.map((result) => result.requestId),
      <String>['export-010', 'export-020'],
    );
    expect(
      observed,
      <String>['export-010.pokemapgame', 'export-020.pokemapgame'],
    );
  });

  test('refuses a package symlink before hashing or installation', () async {
    final inbox = await Directory.systemTemp.createTemp('hub-export-inbox-');
    final outside =
        await Directory.systemTemp.createTemp('hub-export-outside-');
    addTearDown(() async {
      await inbox.delete(recursive: true);
      await outside.delete(recursive: true);
    });
    final bytes = <int>[1, 2, 3];
    final outsidePackage = File(p.join(outside.path, 'outside.pokemapgame'));
    await outsidePackage.writeAsBytes(bytes, flush: true);
    const requestId = 'export-030';
    const packageName = '$requestId.pokemapgame';
    await Link(p.join(inbox.path, packageName)).create(outsidePackage.path);
    final request = GamePackageInstallRequest(
      requestId: requestId,
      packageFileName: packageName,
      packageSha256: sha256.convert(bytes).toString(),
      createdAt: DateTime.utc(2026, 7, 25),
    );
    await File(p.join(inbox.path, '$requestId.request.json')).writeAsBytes(
      const GamePackageInstallRequestCodec().encodeCanonicalUtf8(request),
      flush: true,
    );
    var called = false;
    final consumer = EditorExportInstallInbox(
      inbox: inbox,
      installer: (
        file, {
        required source,
        required cancellationToken,
        onProgress,
      }) async {
        called = true;
      },
    );

    final results = await consumer.consumePending();

    expect(results.single.code, 'packageMissingOrUnsafe');
    expect(called, isFalse);
  });
}

Future<File> _writeRequest(
  Directory inbox, {
  required String requestId,
}) async {
  final package = File(p.join(inbox.path, '$requestId.pokemapgame'));
  final bytes = <int>[1, 2, 3, 4, 5];
  await package.writeAsBytes(bytes, flush: true);
  final request = GamePackageInstallRequest(
    requestId: requestId,
    packageFileName: p.basename(package.path),
    packageSha256: sha256.convert(bytes).toString(),
    createdAt: DateTime.utc(2026, 7, 25),
  );
  await File(p.join(inbox.path, '$requestId.request.json')).writeAsBytes(
    const GamePackageInstallRequestCodec().encodeCanonicalUtf8(request),
    flush: true,
  );
  return package;
}
