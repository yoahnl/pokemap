part of 'local_presentation_adapter.dart';

extension LocalPresentationPublication on LocalPresentationAdapter {
  Future<PresentationPublicationReceipt> _publish({
    required PresentationCinematicAsset asset,
    required PresentationSourceSnapshot? base,
    String? folderId,
    bool changeFolder = false,
    PresentationSceneLink? link,
    List<PresentationStagedMedia> imports = const [],
    List<Map<String, Object?>> mediaBaselines = const [],
  }) {
    if (base != null && base.asset.id != asset.id) {
      throw const PresentationFailure('Identité de publication incorrecte.');
    }
    return _run(asset.id, 'presentationCinematic.publish', {
      'cinematic': encodePresentationCinematicAsset(asset),
      'expectedCinematic': base == null
          ? null
          : encodePresentationCinematicAsset(base.asset),
      'expectedEntry': base?.entry?.toJson(),
      'expectedMedia': _mediaDependencies(
        asset,
        base?.mediaBaselines ?? mediaBaselines,
      ),
      'folderId': folderId,
      'changeFolder': changeFolder,
      'imports': [
        for (final media in imports)
          {...media.parameters, 'expectedMedia': media.media.toJson()},
      ],
      if (link != null)
        'link': {
          'baseScene': link.baseScene.toJson(),
          'scene': link.scene.toJson(),
          'nodeId': link.nodeId,
          'targetNodeId': link.targetNodeId,
        },
    });
  }

  Future<PresentationPublicationReceipt> _createFolder({
    required String id,
    required String name,
    String? parentFolderId,
  }) => _run('', 'cinematicLibraryFolder.create', {
    'folderId': id,
    'family': 'presentation',
    'name': name,
    'parentFolderId': parentFolderId,
    'targetIndex': 0,
  });
  Future<PresentationPublicationReceipt> _delete(
    PresentationSourceSnapshot base,
  ) => _run(
    base.asset.id,
    base.entry == null
        ? 'presentationCinematic.delete'
        : 'cinematicLibraryAsset.delete',
    {
      'cinematicId': base.asset.id,
      if (base.entry != null) 'family': 'presentation',
    },
    base: base,
  );
  Future<PresentationPublicationReceipt> _setArchived(
    PresentationSourceSnapshot base,
    bool archived,
  ) => _run(base.asset.id, 'cinematicLibraryEntry.setArchived', {
    'family': 'presentation',
    'cinematicId': base.asset.id,
    'isArchived': archived,
  }, base: base);
  List<Map<String, Object?>> _mediaDependencies(
    PresentationCinematicAsset asset,
    List<Map<String, Object?>> values,
  ) {
    final catalog = ProjectMediaCatalog(
      entries: [
        for (final item in values)
          ProjectMediaAsset.fromJson(item['media'] as Map<String, Object?>),
      ],
    );
    final graph = PresentationReferenceGraph.build(
      cinematics: [asset],
      mediaCatalog: catalog,
    );
    final targets = <PresentationReferenceKey>{
      PresentationReferenceKey.presentationCinematic(asset.id),
    };
    bool added = true;
    while (added) {
      added = false;
      for (final edge in graph.edges) {
        if (targets.contains(edge.owner) && targets.add(edge.target)) {
          added = true;
        }
      }
    }
    return values
        .where(
          (item) => targets.contains(
            PresentationReferenceKey.media(
              (item['media'] as Map)['id'] as String,
            ),
          ),
        )
        .toList();
  }

  Future<PresentationPublicationReceipt> _run(
    String id,
    String actionId,
    Map<String, Object?> fields, {
    PresentationSourceSnapshot? base,
  }) => mapAdapter.withResourceMutation(() async {
    final baseline = await mapAdapter.resourceBaseline(
      session,
      refreshCatalog: true,
    );
    final connection = await LocalPresentationConnection.open(
      session,
      artifacts,
      faultInjector,
    );
    try {
      final snapshot = await connection.read();
      if (narrativeEventBytesFingerprint(snapshot.resourceBytes('project')) !=
          baseline.revision) {
        throw const PresentationFailure(
          'Le projet a changé pendant sa préparation.',
        );
      }
      if (base != null) {
        final current = _source(snapshot, id);
        if (current?.asset != base.asset || current?.entry != base.entry) {
          throw const PresentationFailure(
            'La présentation ou son classement a changé.',
          );
        }
      }
      final operation = _identity();
      final planned = await connection.api.planMutation(
        connection.opened.projectHandle,
        AuthoringRequest(
          requestId: operation,
          actionId: actionId,
          actionVersion: 1,
          workspaceHandle: connection.opened.workspaceHandle.value,
          expectedRevision: snapshot.revision,
          idempotencyKey: operation,
          parameters: fields,
        ),
      );
      final changes = planned.plan.changeSet.changes;
      if (changes.any(
        (c) =>
            c.storageKey != 'project.json' &&
            c.storageKey != 'assets/.pokemap-assets.json' &&
            c.storageKey != 'assets/.pokemap-media.json' &&
            !RegExp(
              r'^assets/\.pokemap-store/[a-f0-9]{64}\.blob$',
            ).hasMatch(c.storageKey),
      )) {
        throw const PresentationFailure(
          'La publication possède une portée inattendue.',
        );
      }
      final confirmation = actionId.endsWith('.delete')
          ? await connection.api.confirmMutation(
              connection.opened.projectHandle,
              planId: planned.planId,
            )
          : null;
      try {
        if (changes.isNotEmpty) {
          await connection.api.applyMutation(
            connection.opened.projectHandle,
            planId: planned.planId,
            operationId: operation,
            confirmationToken: confirmation?.confirmationToken,
          );
        }
      } catch (failure) {
        try {
          await connection.api.recoverMutation(
            connection.opened.projectHandle,
            operationId: operation,
          );
        } catch (_) {
          throw PresentationFailure(
            'Publication interrompue. Journal $operation conservé : $failure',
          );
        }
      }
      final after = await connection.read();
      for (final change in changes) {
        final actual = await const LocalProjectFileReader().readBytes(
          projectRoot: session.directoryPath,
          relativePath: change.storageKey,
        );
        if (narrativeEventBytesFingerprint(actual) !=
            narrativeEventBytesFingerprint(change.afterBytes!)) {
          throw const PresentationFailure(
            'Le reçu ne correspond pas au contenu publié.',
          );
        }
      }
      final receipt = ResourceMutationReceipt(
        before: baseline.manifest,
        manifest: after.manifest,
        beforeRevision: baseline.revision,
        revision: narrativeEventBytesFingerprint(
          after.resourceBytes('project'),
        ),
        changedPaths: changes.map((c) => c.storageKey).toList(),
      );
      await mapAdapter.acceptResourceMutation(session, receipt);
      return PresentationPublicationReceipt(
        resources: receipt,
        snapshot: _source(after, id),
      );
    } catch (failure) {
      if (failure is PresentationFailure) rethrow;
      throw PresentationFailure(
        'Publication refusée, brouillon conservé : $failure',
      );
    } finally {
      await connection.close();
    }
  });
}
