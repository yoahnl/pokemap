import 'dart:math';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

import '../../project_session/domain/project_session.dart';
import '../domain/working_catalog_port.dart';

final class LocalWorkingCatalogAdapter implements WorkingCatalogPort {
  LocalWorkingCatalogAdapter(this.session);

  final ProjectSession session;
  Future<_CatalogSession>? _opening;
  bool _closed = false;

  Future<_CatalogSession> _session() {
    if (_closed) throw StateError('Le projet est fermé.');
    return _opening ??= _open();
  }

  Future<_CatalogSession> _open() async {
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final service = ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    );
    final reads = AuthoringReadApi(
      openService: service,
      snapshotLoader: snapshots,
    );
    final opened = await reads.openProject(session.directoryPath);
    if (_closed) {
      await reads.closeWorkspace(opened.workspaceHandle);
      throw StateError('Le projet est fermé.');
    }
    return _CatalogSession(
      service: service,
      reads: reads,
      mutations: LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: snapshots,
      ),
      opened: opened,
      policy: policy,
      shadows: LocalCharacterContactShadowAuthoring(policy: policy),
    );
  }

  @override
  Future<WorkingCatalogPage> query({
    required String kind,
    required String text,
    String? cursor,
    String? placementContext,
  }) async {
    final active = await _session();
    final page = await active.reads.queryProject(
      active.opened.projectHandle,
      AuthoringQueryRequest(
        resourceKind: kind,
        operation: text.trim().isEmpty
            ? AuthoringQueryOperation.list
            : AuthoringQueryOperation.search,
        searchTerm: text,
        pageSize: 50,
        cursor: cursor,
        filters: {'placementContext': ?placementContext},
      ),
    );
    return WorkingCatalogPage(
      revision: page.snapshotRevision,
      items: page.items.map((item) => _entry(kind, item)),
      total: page.totalAvailable,
      nextCursor: page.nextCursor,
    );
  }

  @override
  Future<WorkingCatalogDetail> open(WorkingCatalogEntry entry) async {
    final active = await _session();
    final page = await active.reads.queryProject(
      active.opened.projectHandle,
      AuthoringQueryRequest(
        resourceKind: entry.kind,
        operation: AuthoringQueryOperation.get,
        view: AuthoringQueryView.detail,
        ids: [entry.id],
      ),
    );
    if (page.items.length != 1) {
      throw StateError('Cette ressource n’existe plus.');
    }
    final project = await active.service.catalogProject(
      active.opened.projectHandle,
    );
    if (project == null) {
      throw StateError('Le catalogue du projet est indisponible.');
    }
    if (project.revision != page.snapshotRevision) {
      throw StateError(
        'La bibliothèque a changé pendant l’ouverture. Réessayez.',
      );
    }
    final kind = entry.kind == 'borderBlueprint'
        ? CatalogDefinitionKind.borderRecord
        : CatalogDefinitionKind.values.byName(entry.kind);
    final projection = await project.read(
      (catalog) =>
          ProjectCatalogSelection(catalog)
              .resolve([CatalogDefinitionKey(kind, entry.id)]),
    );
    final shadow =
        entry.kind == 'character' &&
            session.storage == ProjectSessionStorage.workingCatalog
        ? await active.shadows.inspect(
            projectRoot: session.directoryPath,
            characterId: entry.id,
          )
        : null;
    final detail = WorkingCatalogDetail(
      entry: _entry(entry.kind, {
        ...page.items.single,
        if (shadow != null) 'contactShadow': shadow['contactShadow'],
      }),
      revision: page.snapshotRevision,
      definitions: projection,
      contactShadowProjectDefault:
          shadow?['projectDefault'] as bool? ??
          projection.settings.actorContactShadowsByDefault,
    );
    if (shadow != null && shadow['revision'] != detail.revision) {
      throw StateError(
        'La bibliothèque a changé pendant l’ouverture. Réessayez.',
      );
    }
    active.detail = detail;
    return detail;
  }

  @override
  Future<WorkingCatalogDetail> save(
    WorkingCatalogEntry entry,
    WorkingCatalogDraft draft, {
    required String revision,
  }) async {
    if (session.storage == ProjectSessionStorage.portableCatalog) {
      throw StateError('Ce projet publié est en lecture seule.');
    }
    if (!draft.valid) throw StateError('Vérifiez le nom et la description.');
    final active = await _session();
    final current = active.detail;
    if (current == null ||
        current.entry.identity != entry.identity ||
        current.revision != revision) {
      throw StateError('Rouvrez la ressource avant de l’enregistrer.');
    }
    if (draft.contactShadow != current.entry.contactShadow) {
      if (entry.kind != 'character' ||
          !draft.sameMetadata(WorkingCatalogDraft.fromEntry(current.entry))) {
        throw StateError(
          'Enregistrez les informations et le réglage d’ombre séparément.',
        );
      }
      final result = await active.shadows.set(
        projectRoot: session.directoryPath,
        expectedRevision: revision,
        characterId: entry.id,
        enabled: draft.contactShadow,
        operationId:
            'studio_shadow_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}',
      );
      final updated = WorkingCatalogDetail(
        entry: WorkingCatalogEntry(
          id: current.entry.id,
          kind: current.entry.kind,
          name: current.entry.name,
          description: current.entry.description,
          tags: current.entry.tags,
          placementContext: current.entry.placementContext,
          familyId: current.entry.familyId,
          contactShadow: result.afterValue,
        ),
        revision: result.afterRevision,
        definitions: current.definitions,
        contactShadowProjectDefault: current.contactShadowProjectDefault,
      );
      active.detail = updated;
      active.metadataNeedsRefresh = true;
      return updated;
    }
    if (active.attached && active.metadataNeedsRefresh) {
      await active.mutations.detachWorkspace(active.opened.workspaceHandle);
      active.attached = false;
    }
    if (!active.attached) {
      await active.mutations.attachProject(
        projectRootPath: session.directoryPath,
        workspaceHandle: active.opened.workspaceHandle,
        projectHandle: active.opened.projectHandle,
      );
      active.attached = true;
      active.metadataNeedsRefresh = false;
    }
    final id =
        'studio_catalog_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
    final planned = await active.mutations.planMutation(
      active.opened.projectHandle,
      AuthoringRequest(
        requestId: id,
        actionId: 'catalog.definition.update',
        actionVersion: 1,
        workspaceHandle: active.opened.workspaceHandle.value,
        expectedRevision: revision,
        idempotencyKey: id,
        parameters: {
          'resourceKind': entry.kind,
          'id': entry.id,
          'name': draft.name.trim(),
          'description': draft.description.trim().isEmpty
              ? null
              : draft.description.trim(),
          if (entry.supportsTags) 'tags': draft.tags,
          'placementContext': draft.placementContext.isEmpty
              ? null
              : draft.placementContext,
        },
      ),
    );
    try {
      await active.mutations.applyMutation(
        active.opened.projectHandle,
        planId: planned.planId,
        operationId: id,
      );
    } catch (failure, stack) {
      late final AuthoringMutationResult recovered;
      try {
        recovered = await active.mutations.recoverMutation(
          active.opened.projectHandle,
          operationId: id,
        );
      } catch (_) {
        Error.throwWithStackTrace(failure, stack);
      }
      if (recovered.receipt.status.name != 'applied' &&
          recovered.receipt.extensions['recoveryOutcome'] != 'resumed') {
        rethrow;
      }
    }
    try {
      await active.shadows.close();
      active.shadows = LocalCharacterContactShadowAuthoring(
        policy: active.policy,
      );
      return await open(entry);
    } catch (failure) {
      throw StateError(
        'La ressource a été enregistrée, mais sa relecture a échoué. Actualisez la bibliothèque avant une nouvelle modification. $failure',
      );
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    final opening = _opening;
    if (opening == null) return;
    late final _CatalogSession active;
    try {
      active = await opening;
    } catch (_) {
      return;
    }
    try {
      if (active.attached) {
        await active.mutations.detachWorkspace(active.opened.workspaceHandle);
      }
    } finally {
      try {
        await active.shadows.close();
      } finally {
        await active.reads.closeWorkspace(active.opened.workspaceHandle);
      }
    }
  }

  @override
  Future<void> recover(String operationId) async {
    final active = await _session();
    if (!active.attached) {
      await active.mutations.attachProject(
        projectRootPath: session.directoryPath,
        workspaceHandle: active.opened.workspaceHandle,
        projectHandle: active.opened.projectHandle,
      );
      active.attached = true;
    }
    await active.mutations.recoverMutation(
      active.opened.projectHandle,
      operationId: operationId,
    );
  }
}

WorkingCatalogEntry _entry(String kind, Map<String, Object?> item) =>
    WorkingCatalogEntry(
      id: item['id']! as String,
      kind: kind,
      name: item['name'] as String? ?? item['id']! as String,
      description: item['description'] as String? ?? '',
      tags:
          (item['tags'] as List?)?.cast<String>().toList(growable: false) ??
          const [],
      placementContext: item['placementContext'] as String? ?? '',
      familyId: item['familyId'] as String? ?? '',
      contactShadow: item['contactShadow'] as bool?,
    );

final class _CatalogSession {
  _CatalogSession({
    required this.service,
    required this.reads,
    required this.mutations,
    required this.opened,
    required this.shadows,
    required this.policy,
  });
  final ProjectOpenService service;
  final AuthoringReadApi reads;
  final LocalMapAuthoringMutationApi mutations;
  final OpenedProject opened;
  final WorkspacePolicy policy;
  LocalCharacterContactShadowAuthoring shadows;
  WorkingCatalogDetail? detail;
  bool attached = false;
  bool metadataNeedsRefresh = false;
}
