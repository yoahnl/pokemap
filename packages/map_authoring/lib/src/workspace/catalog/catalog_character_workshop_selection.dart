part of 'catalog_workshop_selection.dart';

const _characterDefinitionCreationActions = {
  'characterStudio.portraitState.create',
  'characterStudio.animationDefinition.create',
};

bool _supportsCharacterWorkshop(
    String action, Map<String, Object?>? parameters) {
  if (_characterDefinitionCreationActions.contains(action) ||
      const {
        'characterStudio.animationClip.upsert',
        'characterStudio.animationClip.delete',
        'characterStudio.character.portrait.assign',
        'characterStudio.character.portrait.clear',
      }.contains(action)) {
    return true;
  }
  return action == 'characterStudio.asset.import' &&
      parameters?['binding'] is Map;
}

Future<CatalogWorkshopSelection> _readCharacterWorkshop({
  required CatalogProjectReader reader,
  required ProjectHandle projectHandle,
  required String actionId,
  required Map<String, Object?> parameters,
}) async {
  final createsDefinition =
      _characterDefinitionCreationActions.contains(actionId);
  final imports = actionId == 'characterStudio.asset.import';
  final binding = imports ? parameters['binding'] as Map : parameters;
  final characterId = binding['characterId'];
  if (!createsDefinition && (characterId is! String || characterId.isEmpty)) {
    throw const FormatException(
        'catalog.character_workshop: character required');
  }
  final selected = await reader.withMetadataFields({'settings'});
  return selected.read((catalog) async {
    await reader.store.requireMetadataIndexAdmission(catalog.snapshot);
    final selection = ProjectCatalogSelection(catalog);
    final target = createsDefinition
        ? null
        : CatalogDefinitionKey(
            CatalogDefinitionKind.character, characterId as String);
    final roots = <CatalogDefinitionKey>{
      if (createsDefinition) ...await selection.characterStudioDefinitionKeys(),
      if (target != null) target,
      if (binding['portraitStateId'] case final String id)
        CatalogDefinitionKey(CatalogDefinitionKind.characterStudioDefinition,
            jsonEncode(['characterPortraitState', id])),
      if (binding['definitionId'] case final String id)
        CatalogDefinitionKey(CatalogDefinitionKind.characterStudioDefinition,
            jsonEncode(['characterAnimationDefinition', id])),
    };
    var manifest = await selection.resolve(roots);
    final settings = manifest.settings;
    manifest = manifest.copyWith(
      settings: ProjectSettings(
        dimension: settings.dimension,
        spatialCamera: settings.spatialCamera,
        tileWidth: settings.tileWidth,
        tileHeight: settings.tileHeight,
      ),
    );
    final values = <String, List<int>>{};
    final paths = <String, String>{};
    final revisions = <String, String?>{};
    Future<void> readFile(String identity, String path) async {
      final payload = await reader.store.gateway.captureResourcePayload(path);
      revisions[path] = payload?.resourceRevision;
      if (payload == null) return;
      try {
        values[identity] = await payload.readBytes();
        paths[identity] = path;
      } finally {
        await payload.release();
      }
    }

    if (imports || actionId == 'characterStudio.character.portrait.assign') {
      await readFile(assetCatalogResourceIdentity, assetCatalogStorageKey);
    }
    if (imports) {
      final path = parameters['logicalPath'];
      if (path is! String ||
          !path.startsWith('assets/') ||
          path
              .split('/')
              .any((segment) => segment.isEmpty || segment.startsWith('.')) ||
          path.contains('\\')) {
        throw const FormatException(
            'catalog.character_workshop: invalid asset path');
      }
      revisions[path] = await reader.store.gateway.readResourceRevision(path);
      if (revisions[path] != null) {
        throw const FormatException(
            'catalog.character_workshop: asset already exists');
      }
      final handle = parameters['artifactHandle'];
      final digest = handle is String
          ? RegExp(r'^artifact://sha256/([a-f0-9]{64})$')
              .firstMatch(handle)
              ?.group(1)
          : null;
      if (digest != null) {
        await readFile(assetBlobResourceIdentity('sha256:$digest'),
            'assets/.pokemap-store/$digest.blob');
      }
    }

    final section = createsDefinition ? 'characterStudioCatalog' : 'characters';
    final bytes = utf8.encode(jsonEncode(manifest.toJson()));
    final snapshot = ProjectSnapshot(
      projectHandle: projectHandle,
      materializedCatalogProject: true,
      revision:
          CatalogWorkshopSelection.fingerprint(selected.revision, revisions),
      manifest: manifest,
      maps: const [],
      availableProjectSections: {'settings', section},
      resourceBytes: {...values, 'project': bytes},
      resourceStorageKeys: {...paths, 'project': 'project.json'},
      resourceFingerprints: {
        'project': computeAuthoringBytesFingerprint(bytes,
            logicalName: 'project.json'),
        for (final entry in paths.entries) entry.key: revisions[entry.value]!,
      },
    );
    final result = CatalogWorkshopSelection._(
      selected,
      snapshot,
      {section},
      revisions,
      resourceCounts: {
        if (target != null)
          target.kind: await CatalogResourcePositions.read(
              catalog.snapshot, target.kind),
      },
      resourceReplacements: {if (target != null) target},
    );
    await result.requireCurrent();
    return result;
  });
}
