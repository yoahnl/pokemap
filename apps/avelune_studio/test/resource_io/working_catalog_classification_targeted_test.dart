import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'working_catalog_classification_fixture.dart';

void main() {
  test('filing a resource never reads unrelated resources and writes the same files', () async {
    final written = <int, ({int objects, Set<String> files})>{};
    for (final unrelated in [0, 300, 900]) {
      final fixture = await ClassificationFixture.create(unrelated: unrelated);
      try {
        await fixture.openWorkspace();
        await fixture.workspace.ensureResourceKind('element');
        final blocked = <String, File>{};
        for (final file
            in fixture.root.listSync(recursive: true).whereType<File>()) {
          if (file.path.contains('/maps/') || file.path.contains('/assets/')) {
            blocked[file.path] = file;
            continue;
          }
          if (!file.path.contains('/catalog/objects/')) continue;
          final raw = jsonDecode(await file.readAsString());
          if (raw is Map && raw['type'] == 'leaf' && raw['entries'] is List) {
            final entries = raw['entries'] as List;
            if (entries.isNotEmpty &&
                entries.every(
                  (entry) => '${entry['key']['id']}'.contains('decor_'),
                )) {
              blocked[file.path] = file;
            }
          }
        }
        if (unrelated > 0) {
          expect(
            blocked.keys.where((path) => path.contains('/catalog/')),
            isNotEmpty,
          );
        }
        final before = _fileStamps(fixture.root);
        final attempts = <String>[];
        final outside = Zone.current;
        await IOOverrides.runZoned(
          () => fixture.classify('element', 'caisse', 'props'),
          createFile: (path) {
            final original = blocked[path];
            return original == null
                ? outside.run(() => File(path))
                : _UnreadableFile(original, attempts);
          },
        );
        expect(attempts, isEmpty);
        expect(fixture.phases, isNot(contains('attach.start')));
        final after = _fileStamps(fixture.root);
        final changed = {
          for (final entry in after.entries)
            if (before[entry.key] != entry.value)
              entry.key
                  .substring(fixture.root.path.length)
                  .replaceAll(RegExp(r'[0-9a-f]{32,64}'), '<sha>')
                  .replaceAll(RegExp(r'resource_[0-9_]+'), '<operation>'),
        };
        written[unrelated] = (
          objects: after.keys
              .where((path) => path.contains('/catalog/objects/'))
              .where((path) => !before.containsKey(path))
              .length,
          files: changed,
        );
        final persisted = await fixture.readPersistedCatalog();
        expect(persisted.entryFor('element', 'caisse')?.familyId, 'props');
        expect(persisted.entries.length, unrelated + 3);
      } finally {
        await fixture.dispose();
      }
    }
    expect(written[900]!.objects, written[300]!.objects);
    expect(written[300]!.objects, lessThanOrEqualTo(9));
    expect(written[300]!.files, written[0]!.files);
    expect(written[900]!.files, written[0]!.files);
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('clearing a classification and renaming a family stay targeted whatever the catalog size', () async {
    final written = <int, ({int objects, Set<String> files})>{};
    for (final unrelated in [0, 300, 900]) {
      final fixture = await ClassificationFixture.create(unrelated: unrelated);
      try {
        await fixture.openWorkspace();
        await fixture.workspace.ensureResourceKind('element');
        final blocked = <String, File>{};
        for (final file
            in fixture.root.listSync(recursive: true).whereType<File>()) {
          if (file.path.contains('/maps/') || file.path.contains('/assets/')) {
            blocked[file.path] = file;
            continue;
          }
          if (!file.path.contains('/catalog/objects/')) continue;
          final raw = jsonDecode(await file.readAsString());
          if (raw is Map && raw['type'] == 'leaf' && raw['entries'] is List) {
            final entries = raw['entries'] as List;
            if (entries.isNotEmpty &&
                entries.every(
                  (entry) => '${entry['key']['id']}'.contains('decor_'),
                )) {
              blocked[file.path] = file;
            }
          }
        }
        final attempts = <String>[];
        final outside = Zone.current;
        Future<void> guarded(Future<void> Function() body) =>
            IOOverrides.runZoned(
              body,
              createFile: (path) {
                final original = blocked[path];
                return original == null
                    ? outside.run(() => File(path))
                    : _UnreadableFile(original, attempts);
              },
            );
        final before = _fileStamps(fixture.root);
        fixture.phases.clear();
        await guarded(
          () => fixture.mutate('resource.classify', {
            'resourceKind': 'element',
            'resourceId': 'arbre',
            'description': null,
            'familyId': null,
            'mapId': null,
            'role': 'standard',
            'placementContext': null,
          }),
        );
        expect(fixture.phases, contains('plan.end'));
        expect(fixture.phases, isNot(contains('attach.start')));
        final after = _fileStamps(fixture.root);
        written[unrelated] = (
          objects: after.keys
              .where((path) => path.contains('/catalog/objects/'))
              .where((path) => !before.containsKey(path))
              .length,
          files: {
            for (final entry in after.entries)
              if (before[entry.key] != entry.value)
                entry.key
                    .substring(fixture.root.path.length)
                    .replaceAll(RegExp(r'[0-9a-f]{32,64}'), '<sha>')
                    .replaceAll(RegExp(r'resource_[0-9_]+'), '<operation>'),
          },
        );
        expect(
          fixture.workspace.project!.resourceLibraryCatalog.entryFor(
            'element',
            'arbre',
          ),
          isNull,
        );
        for (final (action, name) in [
          ('resource.family.create', 'Jardin'),
          ('resource.family.update', 'Potager'),
        ]) {
          fixture.phases.clear();
          await guarded(
            () => fixture.mutate(action, {
              'familyId': 'family_garden',
              'name': name,
              'parentId': null,
            }),
          );
          expect(fixture.phases, contains('plan.end'), reason: action);
          expect(fixture.phases, isNot(contains('attach.start')));
        }
        fixture.phases.clear();
        await guarded(
          () => fixture.mutate('resource.classify_batch', {
            'entries': [
              {
                'resourceKind': 'element',
                'resourceId': 'rocher',
                'familyId': null,
              },
              {
                'resourceKind': 'element',
                'resourceId': 'caisse',
                'familyId': 'family_garden',
              },
            ],
          }),
        );
        expect(fixture.phases, isNot(contains('attach.start')));
        expect(attempts, isEmpty);
        void expectCatalog(ResourceLibraryCatalog catalog) {
          expect(catalog.entryFor('element', 'arbre'), isNull);
          expect(catalog.entryFor('element', 'rocher'), isNull);
          expect(
            catalog.entryFor('element', 'caisse')?.familyId,
            'family_garden',
          );
          expect(
            catalog.families.singleWhere((f) => f.id == 'family_garden').name,
            'Potager',
          );
        }

        expectCatalog(fixture.workspace.project!.resourceLibraryCatalog);
        final persisted = await fixture.readPersistedCatalog();
        expectCatalog(persisted);
        expect(persisted.entries.length, unrelated + 1);
        await fixture.workspace.ensureResourceKind('tileset');
        expectCatalog(fixture.workspace.project!.resourceLibraryCatalog);
        await fixture.reopen();
        await fixture.workspace.ensureResourceKind('element');
        expectCatalog(fixture.workspace.project!.resourceLibraryCatalog);
      } finally {
        await fixture.dispose();
      }
    }
    for (final unrelated in [300, 900]) {
      expect(written[unrelated]!.objects, lessThanOrEqualTo(12));
      expect(written[unrelated]!.files, written[0]!.files);
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}

Map<String, (int, DateTime)> _fileStamps(Directory root) => {
  for (final file in root.listSync(recursive: true).whereType<File>())
    file.path: (file.lengthSync(), file.lastModifiedSync()),
};

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
