import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../tool/create_example_project.dart';

void main() {
  test('a working catalog classification survives loading another family and reopening', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    await fixture.openWorkspace();
    await fixture.workspace.ensureResourceKind('element');
    expect(
      fixture.workspace.project!.resourceLibraryCatalog
          .entryFor('element', 'arbre')
          ?.familyId,
      'props',
    );

    await fixture.classify('element', 'arbre', 'trees');
    expect(fixture.phases, contains('plan.end'));
    expect(fixture.phases, isNot(contains('attach.start')));
    expect(
      fixture.workspace.project!.resourceLibraryCatalog
          .entryFor('element', 'arbre')
          ?.familyId,
      'trees',
    );

    final written = await fixture.readPersistedCatalog();
    expect(written.entryFor('element', 'arbre')?.familyId, 'trees');

    await fixture.workspace.ensureResourceKind('tileset');
    expect(
      fixture.workspace.project!.resourceLibraryCatalog
          .entryFor('element', 'arbre')
          ?.familyId,
      'trees',
    );
    await fixture.workspace.ensureResourceKind('element');
    expect(
      fixture.workspace.project!.resourceLibraryCatalog
          .entryFor('element', 'arbre')
          ?.familyId,
      'trees',
    );

    final persisted = await fixture.readPersistedCatalog();
    expect(persisted.entryFor('element', 'arbre')?.familyId, 'trees');
    expect(persisted.entryFor('element', 'rocher')?.familyId, 'props');

    await fixture.reopen();
    await fixture.workspace.ensureResourceKind('element');
    expect(
      fixture.workspace.project!.resourceLibraryCatalog
          .entryFor('element', 'arbre')
          ?.familyId,
      'trees',
    );
  });

  test('a new family filled by a batch survives loading another family and reopening', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    await fixture.openWorkspace();
    await fixture.workspace.ensureResourceKind('element');
    await fixture.mutate('resource.family.create', {
      'familyId': 'family_garden',
      'name': 'Jardin',
      'parentId': null,
    });
    await fixture.mutate('resource.classify_batch', {
      'entries': [
        for (final id in ['arbre', 'caisse'])
          {
            'resourceKind': 'element',
            'resourceId': id,
            'familyId': 'family_garden',
          },
      ],
    });

    await fixture.workspace.ensureResourceKind('character');
    final catalog = fixture.workspace.project!.resourceLibraryCatalog;
    expect(catalog.entryFor('element', 'arbre')?.familyId, 'family_garden');
    expect(catalog.entryFor('element', 'caisse')?.familyId, 'family_garden');
    expect(
      catalog.effectiveFamilies.map((family) => family.id),
      contains('family_garden'),
    );

    final persisted = await fixture.readPersistedCatalog();
    expect(persisted.entryFor('element', 'caisse')?.familyId, 'family_garden');
    expect(persisted.entryFor('element', 'rocher')?.familyId, 'props');

    await fixture.reopen();
    await fixture.workspace.ensureResourceKind('element');
    expect(
      fixture.workspace.project!.resourceLibraryCatalog
          .entryFor('element', 'arbre')
          ?.familyId,
      'family_garden',
    );
  });

  test('filing a resource never reads unrelated resources and writes the same files', () async {
    final written = <int, ({int objects, Set<String> files})>{};
    for (final unrelated in [0, 300, 900]) {
      final fixture = await _Fixture.create(unrelated: unrelated);
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
    expect(written[300]!.objects, lessThanOrEqualTo(8));
    expect(written[300]!.files, written[0]!.files);
    expect(written[900]!.files, written[0]!.files);
  }, timeout: const Timeout(Duration(minutes: 3)));
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

final class _Fixture {
  _Fixture(this.root, this.sessions, this.session);

  final Directory root;
  final LocalProjectSessionAdapter sessions;
  ProjectSession session;
  late LocalMapWorkspaceAdapter maps;
  late MapWorkspaceController workspace;
  late LocalResourceAdapter resources;
  final phases = <String>[];
  bool _workspaceOpen = false;

  static Future<_Fixture> create({int unrelated = 0}) async {
    final root = await Directory.systemTemp.createTemp(
      'studio_classification_catalog_',
    );
    await writeExampleProject(root);
    final file = File('${root.path}/project.json');
    final original = ProjectManifest.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
    final extra = [
      for (var index = 0; index < unrelated; index++)
        original.elements.last.copyWith(
          id: 'decor_${index.toString().padLeft(4, '0')}',
          name: 'Décor $index',
        ),
    ];
    final source = original.copyWith(
      elements: [...original.elements, ...extra],
      resourceLibraryCatalog: ResourceLibraryCatalog(
        entries: [
          for (final id in ['arbre', 'rocher'])
            ResourceLibraryEntry(
              resourceKind: 'element',
              resourceId: id,
              familyId: 'props',
            ),
          for (final element in extra)
            ResourceLibraryEntry(
              resourceKind: 'element',
              resourceId: element.id,
              familyId: 'buildings',
              description: element.name,
            ),
        ],
      ),
    );
    await file.delete();
    await WorkingProjectCatalog.create(
      store: await CatalogStorageStore.open(projectRoot: root.path),
      projectId: 'studio-classification-test',
      project: source,
    );
    final sessions = LocalProjectSessionAdapter();
    final session = await sessions.open(await root.resolveSymbolicLinks());
    expect(session.storage, ProjectSessionStorage.workingCatalog);
    return _Fixture(root, sessions, session);
  }

  Future<void> openWorkspace() async {
    maps = LocalMapWorkspaceAdapter();
    workspace = MapWorkspaceController(session, maps);
    await workspace.initialize();
    expect(workspace.error, isNull);
    final entry = workspace.project!.maps.firstWhere(
      (entry) => entry.id == 'jardin',
    );
    await workspace.activate(entry);
    expect(workspace.error, isNull);
    resources = LocalResourceAdapter(
      session: session,
      mapAdapter: maps,
      mutationPhaseObserver: phases.add,
    );
    _workspaceOpen = true;
  }

  Future<void> classify(String kind, String id, String familyId) => mutate(
    'resource.classify',
    {'resourceKind': kind, 'resourceId': id, 'familyId': familyId},
  );

  Future<void> mutate(String action, Map<String, Object?> parameters) async {
    final revision = await resources.captureResourceRevision();
    final preparation = await resources.prepareOperation(
      action,
      parameters,
      expectedSnapshotRevision: revision,
    );
    final receipt = await resources.applyPrepared(preparation);
    _accept(receipt);
  }

  void _accept(ResourceMutationReceipt receipt) {
    workspace.acceptResources(receipt.before, receipt.manifest);
  }

  Future<ResourceLibraryCatalog> readPersistedCatalog() async {
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final catalog = await WorkingProjectCatalog.open(
      store: store,
      descriptor: WorkingProjectCatalogDescriptor(
        projectId: 'studio-classification-test',
      ),
    );
    try {
      final project = await catalog.exportProject();
      return project.resourceLibraryCatalog;
    } finally {
      await catalog.close();
    }
  }

  Future<void> reopen() async {
    await _closeWorkspace();
    await sessions.close(session);
    session = await sessions.open(await root.resolveSymbolicLinks());
    await openWorkspace();
  }

  Future<void> _closeWorkspace() async {
    if (!_workspaceOpen) return;
    _workspaceOpen = false;
    await resources.dispose();
    workspace.dispose();
  }

  Future<void> dispose() async {
    await _closeWorkspace();
    await sessions.close(session);
    await root.delete(recursive: true);
  }
}
