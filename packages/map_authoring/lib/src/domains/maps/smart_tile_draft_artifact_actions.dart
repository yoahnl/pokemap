part of 'smart_tile_catalog_actions.dart';

AuthoringActionDescriptor _draftArtifactDescriptor() =>
    AuthoringActionDescriptor(
      id: 'smart_tile.preset.draft.import',
      version: 1,
      summary: 'Import one isolated Smart Tile draft from a verified JSON '
          'artifact of at most 8 MiB without replacing existing identities',
      inputSchemaId:
          'pokemap.authoring.smart_tile.preset.draft.import.input.v1',
      outputSchemaId: 'pokemap.authoring.smart_tile.mutation.v1',
      riskLevel: AuthoringRiskLevel.medium,
      resourceKinds: const [
        'project',
        'smartTileDraft',
        'smartTileAtlas',
        'smartTileMaterial',
        'smartTileAnimation',
      ],
      capabilityIds: const ['authoring.smart_tiles'],
      requiredPermissions: const [
        AuthoringPermission.projectWrite,
        AuthoringPermission.importRun,
      ],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.atomic,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
      extensions: {
        'maximumArtifactByteLength':
            SmartTileCatalogActions.maximumDraftArtifactBytes,
        'catalogFormatVersion': ProjectSmartTileCatalog.currentFormatVersion,
        'projectWidePreflight': true,
        'inputSchema': {
          'type': 'object',
          'additionalProperties': false,
          'required': ['draftId', 'artifactHandle'],
          'properties': {
            'draftId': {'type': 'string', 'minLength': 1, 'maxLength': 128},
            'artifactHandle': {'type': 'string', 'minLength': 1},
          },
        },
      },
    );

extension SmartTileDraftArtifactActions on SmartTileCatalogActions {
  Future<AuthoringMutationDraft> importDraft(
      AuthoringPlanningContext planning) async {
    if (planning.request.actionId != 'smart_tile.preset.draft.import') {
      throw semanticFailure('smart_tile.action_unsupported',
          'The requested action does not import a Smart Tile draft artifact.');
    }
    if (planning.request.actionVersion != 1) {
      throw semanticFailure('smart_tile.action_version_unsupported',
          'The requested Smart Tile catalog action version is unsupported.');
    }
    final parameters = SemanticParameters(planning.request.parameters,
        allowed: const {'draftId', 'artifactHandle'});
    final draftId = parameters.string('draftId');
    if (draftId.runes.length > 128) {
      throw semanticFailure('smart_tile.draft.identity_invalid',
          'A draft import identity must not exceed 128 characters.');
    }
    final handle = parameters.string('artifactHandle');
    final store = artifactStore;
    if (store == null) {
      throw semanticFailure('smart_tile.draft.artifact_store_required',
          'Smart Tile draft import requires an artifact store.');
    }
    final artifact = store.inspect(handle);
    if (artifact == null) {
      throw semanticFailure('smart_tile.draft.artifact_unavailable',
          'The staged Smart Tile draft is unknown or expired.');
    }
    if (artifact.mediaType != 'application/json') {
      throw semanticFailure('smart_tile.draft.artifact_media_type',
          'A Smart Tile draft artifact must be application/json.');
    }
    if (artifact.byteLength >
        SmartTileCatalogActions.maximumDraftArtifactBytes) {
      throw semanticFailure('smart_tile.draft.artifact_too_large',
          'A Smart Tile draft artifact must not exceed 8 MiB.');
    }
    final bytes = await store.read(handle);
    if (ContentArtifactRef.fromBytes(bytes, mediaType: artifact.mediaType) !=
        artifact) {
      throw semanticFailure('smart_tile.draft.artifact_changed',
          'The staged Smart Tile draft bytes changed after inspection.');
    }
    late final Map<String, Object?> document;
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) throw const FormatException();
      document = Map<String, Object?>.from(decoded);
    } on Object {
      throw semanticFailure('smart_tile.draft.artifact_invalid',
          'A Smart Tile draft artifact must contain one UTF-8 JSON object.');
    }
    final draft = _decode(document,
        field: 'draft', decode: ProjectSmartTileAuthoringDraft.fromJson);
    if (draft.targetPresetId.runes.length > 128 ||
        (draft.sourcePresetId?.runes.length ?? 0) > 128) {
      throw semanticFailure('smart_tile.draft.identity_invalid',
          'Draft preset identities must not exceed 128 characters.');
    }
    if (draft.id != draftId) {
      throw semanticFailure('smart_tile.draft.identity_mismatch',
          'The draft identity does not match the requested identity.');
    }
    final catalog = planning.snapshot.manifest.smartTileCatalog;
    final current = _findById(catalog.drafts, draftId, (item) => item.id);
    if (current != null && current != draft) {
      throw semanticFailure('smart_tile.draft.identity_conflict',
          'Draft import cannot replace a different existing draft.');
    }
    if (catalog.presets.any((value) => value.id == draft.targetPresetId)) {
      throw semanticFailure('smart_tile.draft.target_conflict',
          'Draft import cannot target an existing published preset.');
    }
    for (final (existing, incoming) in <(List<Object>, List<Object>)>[
      (catalog.atlases, draft.atlases),
      (catalog.materials, draft.materials),
      (catalog.animations, draft.animations),
    ]) {
      final jsonExisting = {
        for (final value in existing)
          _smartTileDependencyJson(value)['id']:
              _smartTileDependencyJson(value),
      };
      for (final value in incoming) {
        final json = _smartTileDependencyJson(value);
        final previous = jsonExisting[json['id']];
        if (previous != null &&
            canonicalAuthoringJson(previous) != canonicalAuthoringJson(json)) {
          throw semanticFailure('smart_tile.draft.dependency_identity_conflict',
              'Draft import cannot replace a different existing dependency.',
              details: {'resourceId': json['id']});
        }
      }
    }
    final mutation = _storeDraft(planning, draft, artifacts: [
      AuthoringArtifactRef(
        id: artifact.digest,
        mediaType: artifact.mediaType,
        uri: handle,
        byteLength: artifact.byteLength,
        sha256: artifact.hexDigest,
      ),
    ]);
    if (planning.request.dryRun) await store.release(handle);
    return mutation;
  }
}

Map<String, Object?> _smartTileDependencyJson(Object value) => switch (value) {
      ProjectSmartTileAtlas atlas => atlas.toJson(),
      ProjectSmartTileMaterial material => material.toJson(),
      ProjectSmartTileAnimation animation => animation.toJson(),
      _ => throw StateError('Unknown Smart Tile draft dependency.'),
    };
