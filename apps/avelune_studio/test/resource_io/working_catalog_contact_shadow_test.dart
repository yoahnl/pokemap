import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/data/local_working_catalog_adapter.dart';
import 'package:avelune_studio/features/resources/domain/working_catalog_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../tool/create_example_project.dart';

void main() {
  test(
    'closing during initial opening releases the prepared shadow lease',
    () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final leases = Directory('${fixture.root.path}/catalog/leases');
      final initial = leases.existsSync() ? leases.listSync().length : 0;
      final opening = fixture.adapter.query(kind: 'character', text: '');
      final closing = fixture.adapter.close();
      await expectLater(opening, throwsStateError);
      await closing;
      expect(leases.existsSync() ? leases.listSync().length : 0, initial);
    },
  );

  test('initial library query prepares shadow admission before selecting a character', () async {
    final fixture = await _Fixture.create(unrelatedElements: 620);
    addTearDown(fixture.dispose);
    final blocked = <String, File>{};
    for (final file in Directory(
      '${fixture.root.path}/catalog/objects',
    ).listSync(recursive: true).whereType<File>()) {
      final raw = jsonDecode(await file.readAsString());
      if (raw is Map && raw['type'] == 'leaf' && raw['entries'] is List) {
        final entries = raw['entries'] as List;
        if (entries.isNotEmpty &&
            entries.every((entry) => entry['key']['kind'] == 'element')) {
          blocked[file.path] = file;
        }
      }
    }
    expect(blocked, isNotEmpty);
    final leases = Directory('${fixture.root.path}/catalog/leases');
    final beforeLeases = leases.existsSync() ? leases.listSync().length : 0;
    final page = await fixture.adapter.query(kind: 'character', text: '');
    final preparedLeases = leases.existsSync() ? leases.listSync().length : 0;
    expect(preparedLeases, beforeLeases + 1);
    final outside = Zone.current;
    final attempts = <String>[];
    final selected = await IOOverrides.runZoned(
      () => fixture.adapter.open(page.items.single),
      createFile: (path) {
        final original = blocked[path];
        return original == null
            ? outside.run(() => File(path))
            : _UnreadableFile(original, attempts);
      },
    );
    expect(selected.entry.id, 'guide');
    expect(attempts, isEmpty);
    expect(leases.listSync().length, preparedLeases);
  });

  for (final target in <bool?>[true, false, null]) {
    test(
      'first $target save after opening persists without unrelated reads',
      () async {
        final fixture = await _Fixture.create(
          initial: target == null ? false : null,
        );
        addTearDown(fixture.dispose);
        final detail = await fixture.open();
        final descriptor = await File('${fixture.root.path}/project.json')
            .readAsBytes();
        expect(descriptor.length, lessThan(4096));
        final map = await File('${fixture.root.path}/maps/jardin.json')
            .readAsBytes();
        final attempts = <String>[];
        final files = <String, File>{};
        for (final entry
            in fixture.root.listSync(recursive: true).whereType<File>()) {
          if (entry.path.contains('/maps/') ||
              entry.path.contains('/assets/')) {
            files[entry.path] = entry;
          }
        }
        late WorkingCatalogDetail saved;
        final outside = Zone.current;
        await IOOverrides.runZoned(
          () async {
            saved = await fixture.adapter.save(
              detail.entry,
              WorkingCatalogDraft.fromEntry(detail.entry)
                  .copyWith(contactShadow: target),
              revision: detail.revision,
            );
          },
          createFile: (path) {
            final original = files[path];
            return original == null
                ? outside.run(() => File(path))
                : _UnreadableFile(original, attempts);
          },
        );
        expect(attempts, isEmpty);
        expect(saved.entry.contactShadow, target);
        expect(identical(saved.definitions, detail.definitions), isTrue);
        expect(
          await File('${fixture.root.path}/project.json').readAsBytes(),
          descriptor,
        );
        expect(
          await File('${fixture.root.path}/maps/jardin.json').readAsBytes(),
          map,
        );
        await fixture.reopen();
        expect((await fixture.open()).entry.contactShadow, target);
      },
    );
  }

  test('mixed metadata and shadow edits are refused before writing', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final detail = await fixture.open();
    await expectLater(
      fixture.adapter.save(
        detail.entry,
        WorkingCatalogDraft.fromEntry(detail.entry)
            .copyWith(name: 'Renommé', contactShadow: true),
        revision: detail.revision,
      ),
      throwsStateError,
    );
    await fixture.reopen();
    final unchanged = await fixture.open();
    expect(unchanged.entry.name, detail.entry.name);
    expect(unchanged.entry.contactShadow, isNull);
    expect(unchanged.revision, detail.revision);
  });

  test(
    'metadata and shadow saves can alternate without stale sessions',
    () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      var detail = await fixture.open();
      detail = await fixture.adapter.save(
        detail.entry,
        WorkingCatalogDraft.fromEntry(detail.entry)
            .copyWith(name: 'Guide renommé'),
        revision: detail.revision,
      );
      expect(detail.entry.name, 'Guide renommé');
      detail = await fixture.adapter.save(
        detail.entry,
        WorkingCatalogDraft.fromEntry(detail.entry)
            .copyWith(contactShadow: true),
        revision: detail.revision,
      );
      expect(detail.entry.contactShadow, isTrue);
      detail = await fixture.adapter.save(
        detail.entry,
        WorkingCatalogDraft.fromEntry(detail.entry)
            .copyWith(description: 'Après ombre'),
        revision: detail.revision,
      );
      expect(detail.entry.description, 'Après ombre');
      detail = await fixture.adapter.save(
        detail.entry,
        WorkingCatalogDraft.fromEntry(detail.entry)
            .copyWith(contactShadow: false),
        revision: detail.revision,
      );
      expect(detail.entry.contactShadow, isFalse);
      await fixture.reopen();
      final saved = await fixture.open();
      expect(saved.entry.name, 'Guide renommé');
      expect(saved.entry.description, 'Après ombre');
      expect(saved.entry.contactShadow, isFalse);
    },
  );
}

class _Fixture {
  _Fixture(this.root, this.sessions, this.session, this.adapter);
  final Directory root;
  final LocalProjectSessionAdapter sessions;
  ProjectSession session;
  LocalWorkingCatalogAdapter adapter;

  static Future<_Fixture> create({
    bool? initial,
    int unrelatedElements = 0,
  }) async {
    final root = await Directory.systemTemp.createTemp(
      'studio_shadow_catalog_',
    );
    await writeExampleProject(root);
    final file = File('${root.path}/project.json');
    final original = ProjectManifest.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
    final source = original.copyWith(
      characters: [original.characters.single.copyWith(contactShadow: initial)],
      elements: unrelatedElements == 0
          ? original.elements
          : [
              for (var index = 0; index < unrelatedElements; index++)
                original.elements.first.copyWith(
                  id: 'decor_${index.toString().padLeft(4, '0')}',
                  name: 'Décor $index',
                ),
            ],
    );
    await file.delete();
    await WorkingProjectCatalog.create(
      store: await CatalogStorageStore.open(projectRoot: root.path),
      projectId: 'studio-shadow-test',
      project: source,
    );
    final sessions = LocalProjectSessionAdapter();
    final session = await sessions.open(await root.resolveSymbolicLinks());
    return _Fixture(
      root,
      sessions,
      session,
      LocalWorkingCatalogAdapter(session),
    );
  }

  Future<WorkingCatalogDetail> open() async {
    final page = await adapter.query(kind: 'character', text: '');
    return adapter.open(page.items.single);
  }

  Future<void> reopen() async {
    await adapter.close();
    await sessions.close(session);
    session = await sessions.open(await root.resolveSymbolicLinks());
    adapter = LocalWorkingCatalogAdapter(session);
  }

  Future<void> dispose() async {
    await adapter.close();
    await sessions.close(session);
    await root.delete(recursive: true);
  }
}

class _UnreadableFile implements File {
  _UnreadableFile(this.delegate, this.attempts);
  final File delegate;
  final List<String> attempts;
  Never deny() {
    attempts.add(path);
    throw StateError('Unrelated file read: $path');
  }

  @override
  String get path => delegate.path;
  @override
  Uri get uri => delegate.uri;
  @override
  bool get isAbsolute => delegate.isAbsolute;
  @override
  File get absolute => delegate.absolute;
  @override
  Directory get parent => delegate.parent;
  @override
  Future<Uint8List> readAsBytes() async => deny();
  @override
  Future<String> readAsString({Encoding encoding = utf8}) async => deny();
  @override
  Stream<List<int>> openRead([int? start, int? end]) => deny();
  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) async =>
      deny();
  @override
  Future<bool> exists() => delegate.exists();
  @override
  Future<FileStat> stat() => delegate.stat();
  @override
  Future<String> resolveSymbolicLinks() => delegate.resolveSymbolicLinks();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
