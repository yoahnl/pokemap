part of 'local_resource_adapter.dart';

const _characterWorkshopActions = {
  'characterStudio.animationClip.upsert',
  'characterStudio.animationClip.delete',
  'characterStudio.animationDefinition.create',
  'characterStudio.portraitState.create',
  'characterStudio.character.portrait.clear',
  'characterStudio.asset.import',
};

bool _createsWorkshopCharacterDefinition(String? action) =>
    action == 'characterStudio.portraitState.create' ||
    action == 'characterStudio.animationDefinition.create';

extension _LocalProjectCharacterWorkshop on LocalResourceAdapter {
  Future<ProjectCharacterWorkshopRead> _readWorkshopCharacter(
    String id, {
    required bool includeDefinitions,
  }) async {
    _requireAvailable();
    final result = await mapAdapter.readResourcePreviewWithRevision(
      session,
      'character',
      id,
      includeCharacterStudioDefinitions: includeDefinitions,
    );
    _requireAvailable();
    return result;
  }

  Future<ResourceMutationReceipt> _editWorkshopCharacter(
    String id,
    String action,
    Map<String, Object?> parameters,
    String revision,
    PickedProjectLibraryFile? image,
  ) {
    if (session.storage != ProjectSessionStorage.workingCatalog ||
        !_characterWorkshopActions.contains(action)) {
      throw const ResourceFailure('Cette modification est indisponible.');
    }
    final fields = <String, Object?>{
      ...parameters,
      if (!_createsWorkshopCharacterDefinition(action) && image == null)
        'characterId': id,
    };
    if (action == 'characterStudio.asset.import') {
      final binding = fields['binding'];
      if (image?.imageSize == null || binding is! Map<String, Object?>) {
        throw const ResourceFailure('Choisissez une image PNG.');
      }
      final assetId = _identity('character-image');
      fields
        ..['assetId'] = assetId
        ..['logicalPath'] = 'assets/characters/$id/$assetId.png'
        ..['binding'] = {...binding, 'characterId': id};
    }
    return _run(
      action,
      (_) => fields,
      sourcePath: image?.path,
      expectedSource: image?.artifact,
      expectedBeforeRevision: revision,
      scopedCharacterId: id,
    );
  }

  Future<void> _verifyWorkshopCharacter(
    String id,
    ResourceMutationReceipt receipt,
  ) async {
    final createsDefinition = _createsWorkshopCharacterDefinition(
      receipt.actionId,
    );
    final reread = await _readWorkshopCharacter(
      id,
      includeDefinitions: createsDefinition,
    );
    final actual = reread.project;
    final expected = receipt.manifest;
    if (reread.revision != receipt.revision ||
        (createsDefinition
            ? actual.characterStudioCatalog != expected.characterStudioCatalog
            : actual.characters.single != _workshopCharacter(expected, id))) {
      throw const ResourceFailure(
        'Le personnage a changé après la publication. Rouvrez son atelier.',
      );
    }
    if (receipt.actionId == 'characterStudio.asset.import') {
      await _verifyResourceReceiptPaths(session.directoryPath, receipt);
    }
  }
}

ProjectCharacterEntry? _workshopCharacter(ProjectManifest project, String id) =>
    project.characters.where((character) => character.id == id).firstOrNull;

ProjectManifest _mergeCharacterWorkshopProjection(
  ProjectManifest before,
  ProjectManifest projected,
  String id,
  String action,
) {
  if (_createsWorkshopCharacterDefinition(action)) {
    return before.copyWith(
      characterStudioCatalog: projected.characterStudioCatalog,
    );
  }
  final character = _workshopCharacter(projected, id);
  if (character == null) {
    throw const ResourceFailure('Le personnage est absent du plan.');
  }
  return before.copyWith(
    characters: [
      for (final old in before.characters) old.id == id ? character : old,
      if (_workshopCharacter(before, id) == null) character,
    ],
  );
}
