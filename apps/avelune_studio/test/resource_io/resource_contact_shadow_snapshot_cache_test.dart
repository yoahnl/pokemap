import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'resource_fixture.dart';

void main() {
  test(
    'contact shadow mutation avoids redundant canonical map snapshots',
    () async {
      final fixture = await ResourceFixture.create();
      addTearDown(fixture.dispose);
      final outside = Zone.current;
      final observed = _CountingMapFile(fixture.mapFile);
      final mapPath = fixture.mapFile.path;
      int? readsBeforeReconciliation;
      final adapter = LocalResourceAdapter(
        session: fixture.session,
        mapAdapter: fixture.maps,
        beforeReconciliation: () async {
          readsBeforeReconciliation = observed.reads;
        },
      );
      addTearDown(adapter.dispose);
      final mapBefore = await fixture.mapFile.readAsBytes();
      final receipt = await IOOverrides.runZoned(
        () => adapter.mutate('project.actor_contact_shadows.configure', {
          'enabled': true,
        }),
        createFile: (path) {
          final file = outside.run(() => File(path));
          return file.path == mapPath ? observed : file;
        },
      );
      expect(receipt.manifest.settings.actorContactShadowsByDefault, isTrue);
      expect(await fixture.mapFile.readAsBytes(), mapBefore);
      expect(readsBeforeReconciliation, 4);
      expect(observed.reads, 4);
      final saved = ProjectManifest.fromJson(
        jsonDecode(await fixture.manifestFile.readAsString())
            as Map<String, dynamic>,
      );
      expect(saved.settings.actorContactShadowsByDefault, isTrue);
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test('contact shadow mutation reuses certified binary fingerprints after commit', () async {
    final fixture = await ResourceFixture.create();
    addTearDown(fixture.dispose);
    await fixture.import();
    final outside = Zone.current;
    final storePrefix = '${fixture.root.path}/assets/.pokemap-store/';
    final observed = <String, _CountingMapFile>{};
    int streams() =>
        observed.values.fold(0, (total, file) => total + file.streamReads);
    int? beforeWrite;
    int? afterCommit;
    final adapter = LocalResourceAdapter(
      session: fixture.session,
      mapAdapter: fixture.maps,
      beforeTransactionPrecondition: () async => beforeWrite = streams(),
      beforeReconciliation: () async => afterCommit = streams(),
    );
    addTearDown(adapter.dispose);
    final receipt = await IOOverrides.runZoned(
      () => adapter.mutate('project.actor_contact_shadows.configure', {
        'enabled': true,
      }),
      createFile: (path) {
        final file = outside.run(() => File(path));
        return file.path.startsWith(storePrefix)
            ? observed.putIfAbsent(file.path, () => _CountingMapFile(file))
            : file;
      },
    );
    expect(receipt.manifest.settings.actorContactShadowsByDefault, isTrue);
    expect(observed, isNotEmpty);
    expect(beforeWrite, greaterThan(0));
    expect(afterCommit, beforeWrite);
    expect(streams(), beforeWrite);
  }, timeout: const Timeout(Duration(seconds: 20)));

  test(
    'contact shadow mutation preserves a concurrent manifest writer',
    () async {
      final fixture = await ResourceFixture.create();
      addTearDown(fixture.dispose);
      final before = ProjectManifest.fromJson(
        jsonDecode(await fixture.manifestFile.readAsString())
            as Map<String, dynamic>,
      );
      final externalBytes = utf8.encode(
        jsonEncode(before.copyWith(name: 'Concurrent writer').toJson()),
      );
      final mapBefore = await fixture.mapFile.readAsBytes();
      var writerCalls = 0;
      var reconciled = false;
      final adapter = LocalResourceAdapter(
        session: fixture.session,
        mapAdapter: fixture.maps,
        beforeTransactionPrecondition: () async {
          writerCalls++;
          await fixture.manifestFile.writeAsBytes(externalBytes, flush: true);
        },
        beforeReconciliation: () async => reconciled = true,
      );
      addTearDown(adapter.dispose);
      await expectLater(
        adapter.mutate('project.actor_contact_shadows.configure', {
          'enabled': true,
        }),
        throwsA(
          isA<ResourceFailure>().having(
            (failure) => failure.partialReceipt,
            'published receipt',
            isNull,
          ),
        ),
      );
      expect(writerCalls, 1);
      expect(reconciled, isFalse);
      expect(await fixture.manifestFile.readAsBytes(), externalBytes);
      expect(await fixture.mapFile.readAsBytes(), mapBefore);
      final preserved = ProjectManifest.fromJson(
        jsonDecode(await fixture.manifestFile.readAsString())
            as Map<String, dynamic>,
      );
      expect(preserved.name, 'Concurrent writer');
      expect(preserved.settings.actorContactShadowsByDefault, isFalse);
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );
}

final class _CountingMapFile implements File {
  _CountingMapFile(this.delegate);

  final File delegate;
  int reads = 0;
  int streamReads = 0;

  @override
  String get path => delegate.path;

  @override
  bool get isAbsolute => delegate.isAbsolute;

  @override
  Future<Uint8List> readAsBytes() {
    reads++;
    return delegate.readAsBytes();
  }

  @override
  Stream<List<int>> openRead([int? start, int? end]) {
    streamReads++;
    return delegate.openRead(start, end);
  }

  @override
  Future<String> resolveSymbolicLinks() => delegate.resolveSymbolicLinks();

  @override
  Future<FileStat> stat() => delegate.stat();

  @override
  Future<bool> exists() => delegate.exists();

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) =>
      delegate.open(mode: mode);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
