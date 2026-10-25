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
    'one adapter keeps validated journal indexes across three shadow states',
    () async {
      final fixture = await ResourceFixture.create();
      addTearDown(fixture.dispose);
      final imported = await fixture.import();
      final created = await fixture.resources.mutate(
        'characterStudio.character.create',
        {'name': 'Reviewer', 'tilesetId': imported.createdTilesetId},
      );
      final characterId = created.manifest.characters.single.id;
      final adapter = LocalResourceAdapter(
        session: fixture.session,
        mapAdapter: fixture.maps,
      );
      addTearDown(adapter.dispose);
      final outside = Zone.current;
      final observed = <String, _ObservedFile>{};
      final historyPath =
          '${fixture.root.path}/.pokemap/authoring/history.jsonl';
      final ledgerPath =
          '${fixture.root.path}/.pokemap/authoring/idempotency.jsonl';
      final mapBefore = await fixture.mapFile.readAsBytes();
      await IOOverrides.runZoned(
        () async {
          for (final value in <bool?>[true, false, null]) {
            final receipt = await adapter.mutate(
              'characterStudio.character.update',
              {'characterId': characterId, 'contactShadow': value},
            );
            expect(receipt.manifest.characters.single.contactShadow, value);
            final saved = ProjectManifest.fromJson(
              jsonDecode(await fixture.manifestFile.readAsString())
                  as Map<String, dynamic>,
            );
            expect(saved.characters.single.contactShadow, value);
          }
        },
        createFile: (path) {
          final file = outside.run(() => File(path));
          return file.path == historyPath || file.path == ledgerPath
              ? observed.putIfAbsent(file.path, () => _ObservedFile(file))
              : file;
        },
      );
      expect(observed[historyPath]!.reads, 1);
      expect(observed[ledgerPath]!.reads, 1);
      expect(await fixture.mapFile.readAsBytes(), mapBefore);
      await adapter.dispose();
      await expectLater(
        adapter.mutate('characterStudio.character.update', {
          'characterId': characterId,
          'contactShadow': true,
        }),
        throwsA(isA<ResourceFailure>()),
      );
      expect(observed[historyPath]!.reads, 1);
      expect(observed[ledgerPath]!.reads, 1);
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'a failed initial attach is discarded before retrying the same adapter',
    () async {
      final fixture = await ResourceFixture.create();
      addTearDown(fixture.dispose);
      final adapter = LocalResourceAdapter(
        session: fixture.session,
        mapAdapter: fixture.maps,
      );
      addTearDown(adapter.dispose);
      final mapPath = fixture.mapFile.path;
      final observed = _ObservedFile(fixture.mapFile)..failNextOpen = true;
      final outside = Zone.current;
      final before = await fixture.manifestFile.readAsBytes();
      await expectLater(
        IOOverrides.runZoned(
          () => adapter.mutate('project.actor_contact_shadows.configure', {
            'enabled': true,
          }),
          createFile: (path) {
            final file = outside.run(() => File(path));
            return file.path == mapPath ? observed : file;
          },
        ),
        throwsA(isA<ResourceFailure>()),
      );
      expect(observed.failNextOpen, isFalse);
      expect(await fixture.manifestFile.readAsBytes(), before);
      final receipt = await adapter.mutate(
        'project.actor_contact_shadows.configure',
        {'enabled': true},
      );
      expect(receipt.manifest.settings.actorContactShadowsByDefault, isTrue);
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test('a warm mutation preserves a concurrent manifest writer', () async {
    final fixture = await ResourceFixture.create();
    addTearDown(fixture.dispose);
    List<int>? externalBytes;
    final adapter = LocalResourceAdapter(
      session: fixture.session,
      mapAdapter: fixture.maps,
      beforeTransactionPrecondition: () async {
        if (externalBytes != null) {
          await fixture.manifestFile.writeAsBytes(externalBytes, flush: true);
        }
      },
    );
    addTearDown(adapter.dispose);
    final initial = await adapter.mutate(
      'project.actor_contact_shadows.configure',
      {'enabled': true},
    );
    externalBytes = utf8.encode(
      jsonEncode(
        initial.manifest.copyWith(name: 'Concurrent warm writer').toJson(),
      ),
    );
    await expectLater(
      adapter.mutate('project.actor_contact_shadows.configure', {
        'enabled': false,
      }),
      throwsA(isA<ResourceFailure>()),
    );
    expect(await fixture.manifestFile.readAsBytes(), externalBytes);
  }, timeout: const Timeout(Duration(seconds: 20)));
}

final class _ObservedFile implements File {
  _ObservedFile(this.delegate);

  final File delegate;
  int reads = 0;
  bool failNextOpen = false;

  @override
  String get path => delegate.path;

  @override
  Uri get uri => delegate.uri;

  @override
  Directory get parent => delegate.parent;

  @override
  Future<Uint8List> readAsBytes() {
    reads++;
    return delegate.readAsBytes();
  }

  @override
  Stream<List<int>> openRead([int? start, int? end]) =>
      delegate.openRead(start, end);

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) {
    if (failNextOpen) {
      failNextOpen = false;
      return Future.error(const FileSystemException('Injected attach failure'));
    }
    return delegate.open(mode: mode);
  }

  @override
  Future<String> resolveSymbolicLinks() => delegate.resolveSymbolicLinks();

  @override
  Future<FileStat> stat() => delegate.stat();

  @override
  Future<bool> exists() => delegate.exists();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
