import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/data/local_working_catalog_adapter.dart';
import 'package:avelune_studio/features/resources/domain/working_catalog_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../tool/create_example_project.dart';

void main() {
  late Directory root;
  late LocalProjectSessionAdapter sessions;
  late ProjectSession session;
  late LocalWorkingCatalogAdapter adapter;
  late ProjectManifest source;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('studio_working_catalog_');
    await writeExampleProject(root);
    final file = File('${root.path}/project.json');
    final manifest = ProjectManifest.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
    final element = manifest.elements.first;
    await file.delete();
    source = manifest.copyWith(
      elements: [
        for (var index = 0; index < 125; index++)
          element.copyWith(
            id: 'decor_${index.toString().padLeft(3, '0')}',
            name: 'Décor ${index.toString().padLeft(3, '0')}',
          ),
      ],
    );
    await WorkingProjectCatalog.create(
      store: await CatalogStorageStore.open(projectRoot: root.path),
      projectId: 'studio-working-test',
      project: source,
    );
    sessions = LocalProjectSessionAdapter();
    session = await sessions.open(await root.resolveSymbolicLinks());
    adapter = LocalWorkingCatalogAdapter(session);
  });

  tearDown(() async {
    await adapter.close();
    await sessions.close(session);
    await root.delete(recursive: true);
  });

  test('native session queries later pages and opens only selected preview definitions', () async {
    expect(session.storage, ProjectSessionStorage.workingCatalog);
    final first = await adapter.query(kind: 'element', text: '');
    expect(first.items, hasLength(50));
    expect(first.total, 125);
    final next = await adapter.query(
      kind: 'element',
      text: '',
      cursor: first.nextCursor,
    );
    expect(next.items, hasLength(50));
    expect(
      next.items
          .map((entry) => entry.id)
          .toSet()
          .intersection(first.items.map((entry) => entry.id).toSet()),
      isEmpty,
    );
    final found = await adapter.query(kind: 'element', text: 'Décor 124');
    expect(found.items.single.id, 'decor_124');
    final detail = await adapter.open(found.items.single);
    expect(detail.definitions.elements.map((entry) => entry.id), ['decor_124']);
    expect(detail.definitions.tilesets.map((entry) => entry.id), ['atelier']);
    expect(detail.definitions.characters, isEmpty);
    expect(detail.revision, found.revision);
  });

  test('metadata save survives close and reopen without replacing descriptor or maps', () async {
    final descriptor = await File('${root.path}/project.json').readAsBytes();
    final mapFile = File('${root.path}/maps/jardin.json');
    final mapBytes = await mapFile.readAsBytes();
    final found = await adapter.query(kind: 'element', text: 'Décor 124');
    final detail = await adapter.open(found.items.single);
    final saved = await adapter.save(
      detail.entry,
      WorkingCatalogDraft.fromEntry(detail.entry).copyWith(
        name: 'Bosquet enregistré',
        description: 'Lieu ombragé',
        tags: ['forêt', 'bosquet'],
        placementContext: 'exterior',
      ),
      revision: detail.revision,
    );
    expect(saved.entry.name, 'Bosquet enregistré');
    expect(saved.entry.description, 'Lieu ombragé');
    expect(saved.entry.tags, ['forêt', 'bosquet']);
    expect(saved.entry.placementContext, 'exterior');
    expect(await File('${root.path}/project.json').readAsBytes(), descriptor);
    expect(await mapFile.readAsBytes(), mapBytes);
    await adapter.close();
    await sessions.close(session);
    session = await sessions.open(await root.resolveSymbolicLinks());
    adapter = LocalWorkingCatalogAdapter(session);
    final reopened = await adapter.query(
      kind: 'element',
      text: 'Bosquet enregistré',
      placementContext: 'exterior',
    );
    expect(reopened.items.single.id, 'decor_124');
    final current = await adapter.open(reopened.items.single);
    expect(current.definitions.elements.single.name, 'Bosquet enregistré');
    final cleared = await adapter.save(
      current.entry,
      WorkingCatalogDraft.fromEntry(current.entry)
          .copyWith(description: '', placementContext: ''),
      revision: current.revision,
    );
    expect(cleared.entry.description, isEmpty);
    expect(cleared.entry.placementContext, isEmpty);
  });

  test('concurrent metadata publication rejects a stale draft', () async {
    final other = LocalWorkingCatalogAdapter(session);
    addTearDown(other.close);
    final page = await adapter.query(kind: 'element', text: 'Décor 124');
    final first = await adapter.open(page.items.single);
    final stale = await other.open(page.items.single);
    await adapter.save(
      first.entry,
      WorkingCatalogDraft.fromEntry(first.entry)
          .copyWith(name: 'Version publiée'),
      revision: first.revision,
    );
    await expectLater(
      other.save(
        stale.entry,
        WorkingCatalogDraft.fromEntry(stale.entry)
            .copyWith(name: 'Brouillon périmé'),
        revision: stale.revision,
      ),
      throwsA(anything),
    );
    expect(
      (await adapter.query(
        kind: 'element',
        text: 'Version publiée',
      )).items.single.name,
      'Version publiée',
    );
    expect(
      (await adapter.query(kind: 'element', text: 'Brouillon périmé')).items,
      isEmpty,
    );
  });

  test(
    'portable projects remain browsable and refuse metadata writes',
    () async {
      await adapter.close();
      await sessions.close(session);
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      final current = (await store.openSnapshot())!;
      final publication = PortableCatalogPublication.encodeProject(source);
      await store.publish(
        publication.storage,
        expectedRootRevision: current.rootRevision,
      );
      await File('${root.path}/project.json')
          .writeAsString(jsonEncode(publication.descriptor));
      session = await sessions.open(await root.resolveSymbolicLinks());
      expect(session.storage, ProjectSessionStorage.portableCatalog);
      adapter = LocalWorkingCatalogAdapter(session);
      final page = await adapter.query(kind: 'element', text: 'Décor 124');
      final detail = await adapter.open(page.items.single);
      expect(detail.definitions.elements.single.id, 'decor_124');
      await expectLater(
        adapter.save(
          detail.entry,
          WorkingCatalogDraft.fromEntry(detail.entry)
              .copyWith(name: 'Interdit'),
          revision: detail.revision,
        ),
        throwsStateError,
      );
    },
  );
}
