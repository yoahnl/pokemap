part of 'local_resource_adapter.dart';

Future<ResourceMutationReceipt> _importResourceImage(
  LocalResourceAdapter adapter,
  ResourceImageImport request,
) {
  final id = adapter._identity('source');
  return adapter._run(
    'tileset.import_image',
    (_) => <String, Object?>{
      'tilesetId': id,
      'name': request.name.trim(),
      'tileWidth': request.tileWidth,
      'tileHeight': request.tileHeight,
    },
    sourcePath: request.sourcePath,
    createdTilesetId: id,
  );
}

Future<ResourceMutationReceipt> _saveResourceElement(
  LocalResourceAdapter adapter,
  ProjectElementEntry element,
) => adapter._run('element.upsert', (manifest) {
  final known = manifest.elementCategories.any(
    (category) => category.id == element.categoryId,
  );
  if (known) return <String, Object?>{'element': element.toJson()};
  final category = manifest.elementCategories.isEmpty
      ? const ProjectElementCategory(id: 'studio_decors', name: 'Décors')
      : manifest.elementCategories.first;
  return <String, Object?>{
    'element': element.copyWith(categoryId: category.id).toJson(),
    if (manifest.elementCategories.isEmpty) 'category': category.toJson(),
  };
});

Future<ResourceMutationReceipt> _importCharacterPortrait(
  LocalResourceAdapter adapter,
  CharacterPortraitImport request,
) {
  final assetId = adapter._identity('portrait');
  return adapter._run(
    'characterStudio.asset.import',
    (_) => <String, Object?>{
      'assetId': assetId,
      'logicalPath': 'assets/characters/${request.characterId}/$assetId.png',
      'mediaKind': 'portrait',
      'binding': <String, Object?>{
        'kind': 'portrait',
        'characterId': request.characterId,
        'portraitStateId': request.portraitStateId,
        'fitMode': 'contain',
      },
    },
    sourcePath: request.sourcePath,
  );
}
