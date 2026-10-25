import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/data/local_working_catalog_adapter.dart';
import 'package:avelune_studio/features/resources/domain/working_catalog_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/stories/data/local_story_adapter.dart';
import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
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

  test(
    'library publication preserves a map draft and its subsequent durable save',
    () async {
      final mapFile = File('${root.path}/maps/jardin.json');
      final original = MapData(
        id: 'jardin',
        name: 'Jardin',
        size: const GridSize(width: 2, height: 2),
        visualStack: MapVisualStackConfig.canonicalV1,
        layers: const [
          TileLayer(id: 'ground', name: 'Sol', cells: [0, 0, 0, 0]),
        ],
      );
      await mapFile.writeAsString(jsonEncode(original.toJson()));
      final maps = MapWorkspaceController(session, LocalMapWorkspaceAdapter());
      addTearDown(maps.dispose);
      await maps.initialize();
      expect(maps.error, isNull);
      final draft = maps.active!;
      draft.commit(draft.current.copyWith(name: 'Jardin modifié'));
      final before = await mapFile.readAsBytes();
      final found = await adapter.query(kind: 'element', text: 'Décor 124');
      final detail = await adapter.open(found.items.single);
      await adapter.save(
        detail.entry,
        WorkingCatalogDraft.fromEntry(detail.entry)
            .copyWith(name: 'Décor renommé'),
        revision: detail.revision,
      );
      expect(await mapFile.readAsBytes(), before);
      await maps.refreshCatalogSelection();
      expect(maps.active, same(draft));
      expect(draft.dirty, isTrue);
      expect(await maps.save(draft), isTrue);
      expect(draft.error, isNull);
      final reopened = LocalMapWorkspaceAdapter();
      await reopened.loadCatalog(session);
      final restored = await reopened.loadMapSelection(
        session,
        source.maps.first,
      );
      expect(restored.document.map.name, 'Jardin modifié');
      expect(
        (await adapter.query(
          kind: 'element',
          text: 'Décor renommé',
        )).items.single.id,
        'decor_124',
      );
    },
  );

  test(
    'workshop publications retain the scoped map selection after reopening',
    () async {
      await File('${root.path}/maps/jardin.json').writeAsString(
        jsonEncode(
          MapData(
            id: 'jardin',
            name: 'Jardin',
            size: const GridSize(width: 2, height: 2),
            visualStack: MapVisualStackConfig.canonicalV1,
            layers: const [
              TileLayer(id: 'ground', name: 'Sol', cells: [0, 0, 0, 0]),
            ],
          ).toJson(),
        ),
      );
      final mapAdapter = LocalMapWorkspaceAdapter();
      final controller = MapWorkspaceController(session, mapAdapter);
      addTearDown(controller.dispose);
      await controller.initialize();
      expect(controller.error, isNull);
      final visual = controller.visualProject;
      await controller.ensureWorkshop(MapWorkspaceWorkshop.story);
      expect(controller.hasCompleteProject, isFalse);
      expect(controller.visualProject, same(visual));
      final story = LocalStoryAdapter(session: session, mapAdapter: mapAdapter);
      final factIds = <String>[];
      for (var index = 0; index < 2; index++) {
        final fact = addNarrativeFact(
          controller.project!,
          label: 'État $index',
        ).createdFact;
        factIds.add(fact.id);
        final receipt = await story.publishFact(base: null, current: fact);
        expect(receipt.before, controller.project);
        controller.acceptResources(receipt.before, receipt.manifest);
      }
      await controller.refreshCatalogSelection();
      expect(
        controller.project!.facts.map((value) => value.id),
        containsAll(factIds),
      );
      await controller.ensureWorkshop(MapWorkspaceWorkshop.dialogue);
      final dialogue = LocalDialogueAdapter(
        session: session,
        mapAdapter: mapAdapter,
      );
      const entry = ProjectDialogueEntry(
        id: 'local_dialogue',
        name: 'Dialogue local',
        relativePath: 'dialogues/local.yarn',
      );
      final created = await dialogue.publish(
        id: entry.id,
        base: null,
        entry: entry,
        source: 'title: Start\n---\nBonjour !\n===\n',
      );
      controller.acceptResources(
        created.resources.before,
        created.resources.manifest,
      );
      final changed = await dialogue.publish(
        id: entry.id,
        base: created.snapshot,
        entry: entry,
        source: 'title: Start\n---\nÀ bientôt !\n===\n',
      );
      controller.acceptResources(
        changed.resources.before,
        changed.resources.manifest,
      );
      expect((await dialogue.load(entry.id)).source, contains('À bientôt'));
      expect(controller.hasCompleteProject, isFalse);
      expect(
        controller.project!.facts.map((value) => value.id),
        containsAll(factIds),
      );
    },
  );

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
      final portableRoot = await Directory.systemTemp.createTemp(
        'studio_portable_catalog_',
      );
      addTearDown(() => portableRoot.delete(recursive: true));
      await writeExampleProject(portableRoot);
      final store = await CatalogStorageStore.open(
        projectRoot: portableRoot.path,
      );
      final publication = PortableCatalogPublication.encodeProject(source);
      await store.publish(publication.storage, expectedRootRevision: null);
      await File('${portableRoot.path}/project.json')
          .writeAsString(jsonEncode(publication.descriptor));
      session = await sessions.open(await portableRoot.resolveSymbolicLinks());
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
