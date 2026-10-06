part of 'local_resource_adapter.dart';

Future<ResourceMutationReceipt> _createBorder(
  LocalResourceAdapter adapter,
  BorderCreationRequest request,
) async {
  if (request.name.trim().isEmpty) {
    throw const ResourceFailure('Donnez un nom à la bordure.');
  }
  final baseline = await adapter.mapAdapter.resourceBaseline(adapter.session);
  final sources = await prepareBorderResources(
    manifest: baseline.manifest,
    projectRoot: adapter.session.directoryPath,
    request: request,
  );
  final id = request.blueprintId ?? adapter._identity('border');
  final existing = baseline.manifest.borderCatalog.recordById(id);
  final record = BorderBlueprintRecord(
    id: id,
    draft: BorderBlueprintDraft(
      baseRevision: existing?.latestPublished?.revision ?? 0,
      definition: BorderBlueprintDraftDefinition(
        name: request.name.trim(),
        previewSeed: BorderSignedInt64.zero,
        template: BorderBlueprintTemplate.connectedLine,
        primitives: [for (final source in sources) source.draft],
        defaults: BorderGenerationParams(
          irregularityPermille: 0,
          detailDensityPermille: 0,
          variationPermille: 0,
          maxOverlapPx: 8,
          gapTolerancePx: 1,
          depthRows: 1,
          allowAutoRotation: false,
        ),
        sortOrder:
            existing?.draft.definition.sortOrder ??
            baseline.manifest.borderCatalog.records.length,
      ),
    ),
  );
  final draftReceipt = existing?.draft == record.draft
      ? ResourceMutationReceipt(
          before: baseline.manifest,
          manifest: baseline.manifest,
          beforeRevision: baseline.revision,
          revision: baseline.revision,
          changedPaths: const [],
        )
      : await adapter._run(
          'border.blueprint.draft.upsert',
          (_) => {
            'record': encodeBorderBlueprintRecordJson(
              record,
              formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
            ),
          },
          expectedBeforeRevision: baseline.revision,
        );
  if (!request.publish) return draftReceipt;
  try {
    final published = await adapter._run(
      'border.blueprint.publish',
      (_) => {
        'blueprintId': id,
        'acceptedWarningCodes': request.acceptedWarningCodes,
      },
      borderSources: sources,
      expectedBeforeRevision: draftReceipt.revision,
    );
    return ResourceMutationReceipt(
      before: baseline.manifest,
      manifest: published.manifest,
      beforeRevision: baseline.revision,
      revision: published.revision,
      changedPaths: <String>{
        ...draftReceipt.changedPaths,
        ...published.changedPaths,
      }.toList(),
    );
  } on ResourceFailure catch (error) {
    throw ResourceFailure(
      'Le brouillon de bordure est conservé. ${error.message}',
      partialReceipt: draftReceipt,
      borderId: id,
      warningCodes: error.warningCodes,
    );
  }
}

ResourceFailure _resourceFailure(Object error) {
  if (error is MapAuthoringException &&
      error.code == 'border.blueprint.publication_invalid') {
    final diagnostics = error.details['diagnostics'];
    final messages = diagnostics is List
        ? diagnostics.whereType<Map>().map(_borderPublicationDiagnostic).toSet()
        : <String>{};
    return ResourceFailure(
      messages.isEmpty
          ? 'La bordure ne peut pas être publiée. Corrigez les décors sources, puis réassociez-les au patron.'
          : 'Publication bloquée :\n${messages.join('\n')}',
    );
  }
  if (error is MapAuthoringException &&
      error.code == 'border.blueprint.publication_warnings_unacknowledged') {
    final codes = error.details['unacknowledgedWarningCodes'];
    return ResourceFailure(
      'Vérifiez les raccords signalés avant de publier la bordure.',
      warningCodes: codes is List
          ? codes.whereType<String>().toList()
          : const [],
    );
  }
  return ResourceFailure('La ressource n’a pas été publiée : $error');
}

String _borderPublicationDiagnostic(Map diagnostic) {
  final parameters = diagnostic['parameters'] is Map
      ? diagnostic['parameters'] as Map
      : const <String, Object?>{};
  final sample = switch (parameters['sampleId']) {
    'longEdge' => 'Longue portion',
    'sharpCorner' => 'Angle prononcé',
    'endpoint' => 'Extrémité',
    'opening' => 'Ouverture',
    'sBend' => 'Courbe en S',
    'closedLoop' => 'Boucle fermée',
    _ => 'Aperçu de la bordure',
  };
  if (diagnostic['code'] == 'border.publication.connected_line_disconnected') {
    final gap = parameters['longestContiguousGapPx'];
    final tolerance = parameters['gapTolerancePx'];
    final measurement = gap is int && tolerance is int
        ? 'Un vide de $gap px dépasse les $tolerance px tolérés.'
        : 'Les pièces ne se raccordent pas.';
    return '$sample : $measurement Réassociez au patron des décors dont les segments et les angles se rejoignent au centre et aux bords de leur cadre.';
  }
  return '$sample : corrigez les décors sources, puis réassociez-les au patron et réessayez. Diagnostic : ${diagnostic['code']}.';
}

Future<String> _stageBorderFrame(
  LocalMapAuthoringMutationApi api,
  LocalArtifactStore artifacts,
  BorderResourceFrame frame,
  Map<String, String> handlesByPath,
  Set<String> stagedHandles,
) async {
  final existing = handlesByPath[frame.absolutePath];
  if (existing != null) return existing;
  await artifacts.authorizeSourceFile(frame.absolutePath);
  final staged = await api.stageArtifactFile(
    sourcePath: frame.absolutePath,
    declaredMediaType: 'image/png',
  );
  final handle = staged.reference.handle;
  handlesByPath[frame.absolutePath] = handle;
  stagedHandles.add(handle);
  return handle;
}
