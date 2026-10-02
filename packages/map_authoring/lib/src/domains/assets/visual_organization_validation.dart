part of 'visual_organization_actions.dart';

void _validateOrganizationObject(Map<String, Object?> value, String parentKey) {
  final parameters = VisualLibraryParameters(value);
  parameters.allow({'id', 'name', parentKey, 'sortOrder'});
  parameters.string('id');
  resourceInformationName(value['name']);
  final parent = value[parentKey];
  if (parent != null &&
          (parent is! String || parent.isEmpty || parent != parent.trim()) ||
      value.containsKey('sortOrder') && value['sortOrder'] is! int) {
    throw VisualLibraryException('visual.parameter_invalid',
        'The container parent or display order is invalid.');
  }
}

ProjectManifest _updateProjectVisualGrid(
  ProjectManifest manifest, {
  required int tileWidth,
  required int tileHeight,
  required double displayScale,
}) {
  if (tileWidth <= 0 ||
      tileHeight <= 0 ||
      !displayScale.isFinite ||
      displayScale <= 0) {
    throw VisualLibraryException('visual_grid.invalid',
        'The project visual grid values must be positive.');
  }
  final mismatches = <String>[];
  for (final tileset in manifest.tilesets) {
    final source = tileset.source;
    if (source is ProjectRegularAtlasTilesetSource &&
        (source.tileWidth != tileWidth || source.tileHeight != tileHeight)) {
      mismatches.add(tileset.id);
    }
  }
  if (mismatches.isNotEmpty) {
    throw VisualLibraryException('visual_grid.tileset_mismatch',
        'Every regular atlas must use the project visual grid.',
        details: {'tilesetIds': mismatches..sort()});
  }
  return manifest.copyWith(
      settings: manifest.settings.copyWith(
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          displayScale: displayScale));
}

ProjectTilesetFolder _tilesetFolder(ProjectManifest manifest, String folderId) {
  for (final folder in manifest.tilesetFolders) {
    if (folder.id == folderId) return folder;
  }
  throw VisualLibraryException(
      'tileset_folder.unknown', 'The tileset folder identity is unknown.',
      details: {'folderId': folderId});
}

ProjectElementCategory _elementCategory(
    ProjectManifest manifest, String categoryId) {
  for (final category in manifest.elementCategories) {
    if (category.id == categoryId) return category;
  }
  throw VisualLibraryException(
      'element_category.unknown', 'The element category identity is unknown.',
      details: {'categoryId': categoryId});
}

Map<String, Object?> _organizationIdSchema(String id) => {
      'type': 'object',
      'additionalProperties': false,
      'required': [id],
      'properties': {
        id: {'type': 'string', 'minLength': 1}
      },
    };

Map<String, Object?> _organizationObjectSchema(String field, String parent) => {
      'type': 'object',
      'additionalProperties': false,
      'required': [field],
      'properties': {
        field: {
          'type': 'object',
          'additionalProperties': false,
          'required': ['id', 'name'],
          'properties': {
            'id': {'type': 'string', 'minLength': 1},
            'name': {'type': 'string', 'minLength': 1},
            parent: {
              'type': ['string', 'null']
            },
            'sortOrder': {'type': 'integer'},
          },
        }
      },
    };

void _validateOrganizationParent(
    String id, String? parent, Map<String, String?> hierarchy, String family) {
  if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]*$').hasMatch(id)) {
    throw VisualLibraryException(
        '$family.identity_invalid', 'The container identity is invalid.');
  }
  final visited = <String>{id};
  var cursor = parent;
  while (cursor != null) {
    if (!visited.add(cursor)) {
      throw VisualLibraryException('$family.cycle',
          'A container cannot be moved inside itself or its descendants.');
    }
    if (!hierarchy.containsKey(cursor)) {
      throw VisualLibraryException(
          '$family.parent_missing', 'The destination parent no longer exists.');
    }
    cursor = hierarchy[cursor];
  }
}
