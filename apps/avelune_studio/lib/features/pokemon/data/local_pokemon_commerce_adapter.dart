import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../domain/pokemon_commerce_port.dart';

final class LocalPokemonCommerceAdapter implements PokemonCommercePort {
  const LocalPokemonCommerceAdapter({
    required this.session,
    required this.mapAdapter,
  });

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;

  @override
  Future<PokemonCommerceImportPreview> previewJson(
    String path, {
    required bool item,
  }) async {
    final document = jsonDecode(await File(path).readAsString());
    if (document is! Map<String, dynamic>) {
      throw const FormatException('Le JSON doit contenir une fiche unique.');
    }
    final snapshot = await load();
    if (item) {
      if (snapshot.catalog == null) {
        throw StateError(snapshot.problem ?? 'Catalogue indisponible.');
      }
      final definition = ProjectItemDefinition.fromJson(document);
      return PokemonCommerceImportPreview(
        item: definition,
        shop: null,
        existingItem: snapshot.catalog!.entries
            .where((value) => value.id == definition.id)
            .firstOrNull,
        existingShop: null,
      );
    }
    final definition = ShopDefinition.fromJson(document);
    return PokemonCommerceImportPreview(
      item: null,
      shop: definition,
      existingItem: null,
      existingShop: snapshot.shops
          .where((value) => value.id == definition.id)
          .firstOrNull,
    );
  }

  @override
  Future<PokemonCommerceSnapshot> load() => _withSnapshot((snapshot, _) async {
    final manifest = snapshot.manifest;
    final catalogPath = manifest.pokemon.catalogFiles['items'];
    final catalog = snapshot.itemCatalog;
    return PokemonCommerceSnapshot(
      project: manifest,
      catalog: catalog,
      shops: List.unmodifiable(manifest.shops),
      references: buildProjectItemReferenceIndex(
        project: manifest,
        maps: snapshot.maps,
        itemCatalog: catalog,
      ),
      narrativeReferences: buildNarrativeDependencyIndex(
        project: manifest,
        maps: snapshot.maps,
        itemCatalog: catalog,
      ),
      shopDiagnostics: ShopStateValidator(
        project: manifest,
        knownItemIds: {
          for (final item
              in catalog?.entries ?? const <ProjectItemDefinition>[])
            item.id,
        },
      ).validate(),
      catalogPath: catalogPath,
      problem: !manifest.pokemon.enabled
          ? 'La configuration Pokémon est désactivée.'
          : catalogPath == null
          ? 'Aucun catalogue d’objets n’est configuré pour ce projet.'
          : catalog == null
          ? 'Le catalogue d’objets est absent ou illisible.'
          : null,
    );
  });

  @override
  Future<void> saveItem(
    ProjectItemDefinition? before,
    ProjectItemDefinition after,
  ) => mapAdapter.withResourceMutation(
    () => _withSnapshot((snapshot, run) async {
      final catalog = snapshot.itemCatalog;
      if (catalog == null) throw StateError('Catalogue d’objets indisponible.');
      final current = catalog.entries
          .where((entry) => entry.id == after.id)
          .firstOrNull;
      if (!_same(current?.toJson(), before?.toJson())) {
        throw StateError(
          'Cet objet a changé sur le disque. Votre brouillon est conservé.',
        );
      }
      await run(
        before == null ? 'item.create' : 'item.update',
        before == null
            ? {'definition': after.toJson()}
            : {'itemId': after.id, 'definition': after.toJson()},
        snapshot.manifest.pokemon.catalogFiles['items'],
      );
    }),
  );

  @override
  Future<void> saveShop(
    ShopDefinition? before,
    ShopDefinition after,
  ) => mapAdapter.withResourceMutation(
    () => _withSnapshot((snapshot, run) async {
      final current = snapshot.manifest.shops
          .where((entry) => entry.id == after.id)
          .firstOrNull;
      if (!_same(current?.toJson(), before?.toJson())) {
        throw StateError(
          'Cette boutique a changé sur le disque. Votre brouillon est conservé.',
        );
      }
      await run('campaign.shop.upsert', {
        'value': after.toJson(),
      }, 'project.json');
      await mapAdapter.resourceBaseline(session, refreshCatalog: true);
    }),
  );

  Future<T> _withSnapshot<T>(
    Future<T> Function(
      ProjectSnapshot snapshot,
      Future<void> Function(String, Map<String, Object?>, String?) run,
    )
    operation,
  ) async {
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    ).openProject(session.directoryPath);
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
    );
    var attached = false;
    try {
      await api.attachProject(
        projectRootPath: session.directoryPath,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      attached = true;
      final snapshot = await snapshots.load(
        opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.editorReadProjection,
      );
      Future<void> run(
        String action,
        Map<String, Object?> parameters,
        String? path,
      ) async {
        if (path == null) throw StateError('Destination non configurée.');
        final id =
            'studio_commerce_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
        final planned = await api.planMutation(
          opened.projectHandle,
          AuthoringRequest(
            requestId: id,
            actionId: action,
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: id,
            parameters: parameters,
          ),
        );
        if (planned.plan.changeSet.changes.any(
          (change) => change.storageKey != path,
        )) {
          throw StateError(
            'La mutation vise une autre ressource que celle attendue.',
          );
        }
        try {
          await api.applyMutation(
            opened.projectHandle,
            planId: planned.planId,
            operationId: id,
          );
        } on Object catch (failure) {
          try {
            await api.recoverMutation(opened.projectHandle, operationId: id);
          } on Object {
            throw StateError(
              'Écriture interrompue ; journal $id conservé : $failure',
            );
          }
          rethrow;
        }
      }

      return await operation(snapshot, run);
    } finally {
      if (attached) await api.detachWorkspace(opened.workspaceHandle);
      handles.closeWorkspace(opened.workspaceHandle);
    }
  }

  bool _same(Object? first, Object? second) =>
      jsonEncode(first) == jsonEncode(second);
}
