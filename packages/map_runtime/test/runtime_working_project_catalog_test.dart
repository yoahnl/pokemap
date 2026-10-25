import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_project_catalog.dart';

void main() {
  for (final full in [false, true]) {
    test(
      'working runtime reads without creating absent authoring storage full=$full',
      () async {
        final f = await _Fixture.create();
        addTearDown(f.dispose);
        await Directory('${f.root.path}/.pokemap').delete(recursive: true);
        final before = await f.inventory();
        if (full) {
          expect(
            (await loadProjectManifestFromFile(f.path)).name,
            f.project.name,
          );
        } else {
          final catalog = await RuntimeProjectCatalog.open(f.path);
          addTearDown(catalog.dispose);
          expect(
            (await catalog.manifestForMap(f.map)).tilesets.single.id,
            'tile',
          );
        }
        expect(await Directory('${f.root.path}/.pokemap').exists(), isFalse);
        expect(await f.inventory(), before);
      },
    );
  }

  test('working runtime catalog resolves selected definitions without materializing unrelated assets', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final before = await f.inventory();
    final catalog = await RuntimeProjectCatalog.open(f.path);
    addTearDown(catalog.dispose);
    expect(catalog.projectMetadata.maps.single.id, 'room');
    expect(catalog.projectMetadata.tilesets, isEmpty);
    final selected = await catalog.manifestForMap(f.map);
    expect(selected.tilesets.map((entry) => entry.id), ['tile']);
    expect(await catalog.isCurrentPublication(), isTrue);
    expect(await f.inventory(), before);
  });

  test('full working manifest loader preserves every field and does not rewrite its source', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final before = await f.inventory();
    final project = await loadProjectManifestFromFile(f.path);
    expect(project.toJson(), f.project.toJson());
    expect(await f.inventory(), before);
  });

  for (final interrupted in [false, true]) {
    test(
      interrupted
          ? 'working runtime refuses a pending canonical HEAD transaction'
          : 'working publication checks HEAD when descriptor bytes remain identical',
      () async {
        final f = await _Fixture.create();
        addTearDown(f.dispose);
        final catalog = await RuntimeProjectCatalog.open(f.path);
        addTearDown(catalog.dispose);
        final descriptor = await File(f.path).readAsBytes();
        final working = await WorkingProjectCatalog.open(
          store: f.store,
          descriptor: WorkingProjectCatalogDescriptor(
            projectId: 'runtime-fixture',
          ),
        );
        addTearDown(working.close);
        final key = CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'tile');
        final current = (await working.lookup(key))!;
        final edited = working.replaceDefinitionValue(current, {
          ...Map<String, Object?>.from(current.payload['value']! as Map),
          'name': 'Changed',
        });
        final session = await CatalogEditingSession.open(
          store: f.store,
          projectId: 'runtime-fixture',
          actorId: 'fixture',
          faultInjector: (context) {
            if (interrupted &&
                context.checkpoint ==
                    AuthoringTransactionCheckpoint.afterJournalPrepared) {
              throw const AuthoringTransactionSimulatedCrash();
            }
          },
        );
        addTearDown(session.close);
        final plan = await session.planPatch(
          upserts: [edited],
          idempotencyKey: 'rename-tile',
          request: AuthoringRequest(
            requestId: 'rename-tile',
            actionId: 'catalog.definition.update',
            actionVersion: 1,
            workspaceHandle: 'workspace',
            expectedRevision: 'sha256:${working.root.sha256}',
            idempotencyKey: 'rename-tile',
            parameters: const {'id': 'tile', 'name': 'Changed'},
          ),
        );
        if (interrupted) {
          await expectLater(
            session.apply(plan, operationId: 'rename-operation'),
            throwsA(isA<AuthoringTransactionSimulatedCrash>()),
          );
          final before = await f.inventory();
          expect(await catalog.isCurrentPublication(), isFalse);
          await expectLater(
            RuntimeProjectCatalog.open(f.path),
            throwsA(
              isA<CatalogStorageException>().having(
                (error) => error.code,
                'code',
                'catalog.recovery_required',
              ),
            ),
          );
          await expectLater(
            loadProjectManifestFromFile(f.path),
            throwsA(isA<ProjectLoadException>()),
          );
          expect(await f.inventory(), before);
          return;
        }
        await session.apply(plan, operationId: 'rename-operation');
        expect(await File(f.path).readAsBytes(), descriptor);
        expect(await catalog.isCurrentPublication(), isFalse);
        final fresh = await RuntimeProjectCatalog.open(f.path);
        addTearDown(fresh.dispose);
        expect(fresh.identity, isNot(catalog.identity));
        expect(
          (await fresh.manifestForMap(f.map)).tilesets.single.name,
          'Changed',
        );
        expect(await fresh.isCurrentPublication(), isTrue);
        catalog.dispose();
        expect(await catalog.isCurrentPublication(), isFalse);
      },
    );
  }
  for (final quota in ['bytes', 'values']) {
    test('working runtime keeps the global $quota quota', () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      await expectLater(
        RuntimeProjectCatalog.open(
          f.path,
          limits: quota == 'bytes'
              ? CatalogStorageLimits(maxStoredBytes: 10)
              : null,
          maximumCatalogJsonValues: quota == 'values' ? 5 : 8000000,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  }

  for (final invalid in ['identity', 'head', 'future', 'objectSymlink']) {
    test('working runtime rejects $invalid without rewriting recoverable bytes', () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      if (invalid == 'identity') {
        await File('${f.root.path}/catalog/IDENTITY.json').writeAsString(
          canonicalAuthoringJson({
            'schemaVersion': 1,
            'projectId': 'foreign-project',
          }),
        );
      } else if (invalid == 'head') {
        await File('${f.root.path}/catalog/HEAD.json')
            .writeAsString('{"broken":true}');
      } else if (invalid == 'future') {
        final descriptor = jsonDecode(
          await File(f.path).readAsString(),
        ) as Map<String, dynamic>;
        descriptor['version'] = 999;
        await File(f.path).writeAsString(jsonEncode(descriptor));
      } else {
        final head = (await f.store.readHead())!;
        final object = File(
          '${f.root.path}/${PortableCatalogPublication.objectPath(head)}',
        );
        final external = File(
          '${f.root.parent.path}/${f.root.uri.pathSegments.where((part) => part.isNotEmpty).last}-external.json',
        );
        await external.writeAsBytes(await object.readAsBytes());
        addTearDown(() => external.delete());
        await object.delete();
        await Link(object.path).create(external.path);
      }
      final before = await f.inventory();
      await expectLater(
        RuntimeProjectCatalog.open(f.path),
        throwsA(isA<Object>()),
      );
      await expectLater(
        loadProjectManifestFromFile(f.path),
        throwsA(isA<Object>()),
      );
      expect(await f.inventory(), before);
    });
  }
}

final class _Fixture {
  _Fixture(this.root, this.store, this.project);
  final Directory root;
  final CatalogStorageStore store;
  final ProjectManifest project;
  String get path => '${root.path}/project.json';
  final map = const MapData(
    id: 'room',
    name: 'Room',
    size: GridSize(width: 2, height: 2),
    tilesetId: 'tile',
  );

  static Future<_Fixture> create() async {
    final root = await Directory.systemTemp.createTemp(
      'runtime-working-catalog-',
    );
    final project = ProjectManifest(
      name: 'Working runtime fixture',
      maps: const [
        ProjectMapEntry(
          id: 'room',
          name: 'Room',
          relativePath: 'maps/room.json',
        ),
      ],
      tilesets: [
        for (final id in ['tile', 'unused'])
          ProjectTilesetEntry(id: id, name: id, relativePath: 'assets/$id.png'),
      ],
    );
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final working = await WorkingProjectCatalog.create(
      store: store,
      projectId: 'runtime-fixture',
      project: project,
    );
    await working.close();
    await File('${root.path}/catalog/IDENTITY.json').writeAsString(
      canonicalAuthoringJson({
        'schemaVersion': 1,
        'projectId': 'runtime-fixture',
      }),
    );
    return _Fixture(root, store, project);
  }

  Future<Map<String, String>> inventory() async => {
    await for (final file in root.list(recursive: true, followLinks: false))
      if (file is File) file.path: base64Encode(await file.readAsBytes()),
  };

  Future<void> dispose() async => root.delete(recursive: true);
}
