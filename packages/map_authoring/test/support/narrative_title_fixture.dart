import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

String narrativeTitleEvent(int index) =>
    'evt_019abcde-0000-7000-8000-${index.toRadixString(16).padLeft(12, '0')}';

NarrativeFactDefinition narrativeTitleFact(int index, {String? label}) =>
    NarrativeFactDefinition(
        id: 'fact_fact_$index',
        label: label ?? 'Fact $index',
        category: index.isEven ? 'quest' : '',
        tags: index == 0 ? const ['main'] : const []);

ProjectManifest narrativeTitleProject({int facts = 3, int unrelated = 0}) =>
    ProjectManifest(
      name: 'Narrative titles',
      maps: [
        for (var i = 0; i < unrelated; i++)
          ProjectMapEntry(
              id: 'map_$i', name: 'Map $i', relativePath: 'maps/map_$i.json'),
      ],
      tilesets: const [],
      scenes: [
        for (final (id, name) in [
          ('arrival', 'Arrival'),
          ('farewell', 'Farewell')
        ])
          SceneAsset(
              id: id,
              name: name,
              tags: id == 'arrival' ? const ['intro'] : const [],
              graph: SceneGraph(startNodeId: 'start', nodes: [
                SceneNode(id: 'start', kind: SceneNodeKind.start),
              ], edges: const [])),
      ],
      dialogues: const [
        ProjectDialogueEntry(
            id: 'greet',
            name: 'Greeting',
            relativePath: 'dialogues/greet.yarn',
            tags: ['npc']),
      ],
      facts: [for (var i = 0; i < facts; i++) narrativeTitleFact(i)],
      storylines: [
        StorylineAsset(
            id: 'main', type: StorylineType.main, title: 'Main quest'),
      ],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: [
          for (final (index, name) in [(1, 'Wake up'), (2, 'Leave home')])
            NarrativeEventRecord.draft(NarrativeEventDraft(
                id: narrativeTitleEvent(index),
                name: name,
                conditions: const [],
                priority: 0,
                order: index)),
        ],
        legacyClaims: const [],
      ),
    );

final class NarrativeTitleFixture {
  NarrativeTitleFixture._(this.root, this.opened, this.handles, this.api);

  final Directory root;
  final OpenedProject opened;
  final WorkspaceHandleStore handles;
  final LocalMapAuthoringMutationApi api;

  static Directory get qa =>
      Directory('/Users/karim/Library/Caches/AveluneQA/c1/narrative-titles');

  static Future<NarrativeTitleFixture> create(
      {int facts = 3,
      int unrelated = 0,
      Directory? at,
      ProjectManifest? project}) async {
    final root =
        at ?? await (await qa.create(recursive: true)).createTemp('project-');
    await root.create(recursive: true);
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final working = await WorkingProjectCatalog.create(
        store: store,
        projectId: 'narrative-titles',
        project: project ??
            narrativeTitleProject(facts: facts, unrelated: unrelated));
    await working.close();
    return attach(root);
  }

  static Future<NarrativeTitleFixture> attach(Directory root) async {
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
      catalogMetadataFields: {},
    ).openProject(root.path);
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      catalogFileReader: reader,
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
    );
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return NarrativeTitleFixture._(root, opened, handles, api);
  }

  Future<void> prepare(
          [String? scope = CatalogNarrativeTitles.preparationScope]) =>
      api.prepareWorkshopCatalog(opened.projectHandle, scope: scope);

  Future<CatalogSnapshot> snapshot() async {
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    return (await store.openRoot((await store.readHead())!)).snapshot;
  }

  Future<CatalogNarrativeTitleRead> read(String kind, [int page = 0]) async =>
      CatalogNarrativeTitles.read(await snapshot(), kind, page);

  Future<List<String>> titles(String kind, [int page = 0]) async =>
      switch (await read(kind, page)) {
        CatalogNarrativeTitlePage(:final entries) => [
            for (final entry in entries) entry.title
          ],
        CatalogNarrativeTitlesPreparationRequired(:final reason) => [
            'preparation:$reason'
          ],
      };

  Future<String> apply(
      String action, Map<String, Object?> parameters, String operation,
      {bool confirm = false}) async {
    final snapshot = await api.readWorkshopSnapshot(opened.projectHandle,
        actionId: action, parameters: parameters);
    final plan = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: operation,
            actionId: action,
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: operation,
            parameters: parameters,
            extensions: const {'workshopScope': true}));
    final token = confirm
        ? (await api.confirmMutation(opened.projectHandle, planId: plan.planId))
            .confirmationToken
        : null;
    return (await api.applyMutation(opened.projectHandle,
            planId: plan.planId,
            operationId: operation,
            confirmationToken: token))
        .receipt
        .receiptId;
  }

  Future<void> undo(String entryId, String key) =>
      api.undoMutation(opened.projectHandle,
          entryId: entryId, idempotencyKey: key);

  Future<void> redo(String entryId, String key) =>
      api.redoMutation(opened.projectHandle,
          entryId: entryId, idempotencyKey: key);

  Future<NarrativeTitleFixture> copy() async {
    final target = await qa.createTemp('copy-');
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final file =
          File('${target.path}/${entity.path.substring(root.path.length + 1)}');
      await file.parent.create(recursive: true);
      await entity.copy(file.path);
    }
    return attach(target);
  }

  Future<void> reattach() async {
    await api.detachWorkspace(opened.workspaceHandle);
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
  }

  Future<void> close({bool delete = true}) async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    if (delete) await root.delete(recursive: true);
  }
}
