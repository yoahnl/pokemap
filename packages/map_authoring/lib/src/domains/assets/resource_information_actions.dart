import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'tileset_actions.dart';
import 'resource_information_document.dart';

part 'resource_information_smart_categories.dart';

final class ResourceInformationActions {
  const ResourceInformationActions();

  static final descriptors = [
    _informationDescriptor('tileset.metadata.update', {
      'tilesetId': _identitySchema,
      'name': _nameSchema,
      'folderId': {
        'type': ['string', 'null']
      },
    }),
    _informationDescriptor('element.category.assign', {
      'elementId': _identitySchema,
      'categoryId': _identitySchema,
    }),
    _informationDescriptor('smart_tile.category.upsert', {
      'category': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['id', 'name'],
        'properties': {
          'id': _identitySchema,
          'name': _nameSchema,
          'sortOrder': {'type': 'integer'},
        },
      },
    }),
    _informationDescriptor(
        'smart_tile.category.delete',
        {
          'categoryId': _identitySchema,
        },
        high: true),
    _informationDescriptor('smart_tile.preset.category.assign', {
      'presetId': _identitySchema,
      'categoryId': {'type': 'string'},
    }),
  ];

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final input = context.request.parameters;
    final parameters = VisualLibraryParameters(input);
    final original = context.snapshot.manifest;
    final operation = context.request.actionId;
    final ProjectManifest next;
    final String path;
    switch (operation) {
      case 'tileset.metadata.update':
        parameters.allow(const {'tilesetId', 'name', 'folderId'});
        final id = parameters.string('tilesetId');
        final name = resourceInformationName(input['name']);
        final folderId = input['folderId'];
        if (!input.containsKey('folderId') ||
            folderId != null && (folderId is! String || folderId.isEmpty)) {
          throw VisualLibraryException('visual.parameter_invalid',
              'A folder identity or explicit null is required.');
        }
        next = updateTileset(original,
            tilesetId: id, name: name, folderId: folderId as String?);
        path = '/tilesets/$id';
      case 'element.category.assign':
        parameters.allow(const {'elementId', 'categoryId'});
        final id = parameters.string('elementId');
        final category = parameters.string('categoryId');
        if (!original.elements.any((element) => element.id == id)) {
          throw VisualLibraryException('element.unknown', 'Unknown décor.');
        }
        if (!original.elementCategories.any((entry) => entry.id == category)) {
          throw VisualLibraryException('element_category.unknown',
              'The décor destination category no longer exists.');
        }
        next = original.copyWith(elements: [
          for (final element in original.elements)
            if (element.id == id)
              element.copyWith(categoryId: category)
            else
              element,
        ]);
        path = '/elements/$id/categoryId';
      case 'smart_tile.category.upsert':
        parameters.allow(const {'category'});
        final value = parameters.object('category');
        VisualLibraryParameters(value).allow(const {'id', 'name', 'sortOrder'});
        final category =
            ProjectSmartTileCategory.fromJson(Map<String, dynamic>.from(value));
        next = upsertSmartCategory(original, category);
        path = '/smartTileCatalog/categories/${category.id}';
      case 'smart_tile.category.delete':
        parameters.allow(const {'categoryId'});
        final id = parameters.string('categoryId');
        next = deleteSmartCategory(original, id);
        path = '/smartTileCatalog/categories/$id';
      case 'smart_tile.preset.category.assign':
        parameters.allow(const {'presetId', 'categoryId'});
        final category = input['categoryId'];
        if (category is! String || category != category.trim()) {
          throw VisualLibraryException('visual.parameter_invalid',
              'The terrain category identity is invalid.');
        }
        final id = parameters.string('presetId');
        next = assignSmartCategory(original, id, category);
        path = '/smartTileCatalog/presets/$id/categoryId';
      default:
        throw VisualLibraryException('visual.action_unsupported',
            'Unsupported resource information operation.');
    }
    return buildVisualManifestDraft(context.snapshot, next,
        encodedManifest:
            encodeResourceInformationDocument(context.snapshot, next),
        operation: operation,
        path: path,
        after: input,
        referenceImpact: const {
          'logicalOrganizationOnly': true,
          'pixelContentUnchanged': true,
          'mapsUnchanged': true,
          'authoringDraftsUnchanged': true,
        });
  }

  ProjectManifest updateTileset(
    ProjectManifest manifest, {
    required String tilesetId,
    required String name,
    required String? folderId,
  }) {
    if (!manifest.tilesets.any((entry) => entry.id == tilesetId)) {
      throw VisualLibraryException('tileset.unknown', 'Unknown image planche.');
    }
    if (folderId != null &&
        !manifest.tilesetFolders.any((folder) => folder.id == folderId)) {
      throw VisualLibraryException('tileset_folder.unknown',
          'The image destination folder no longer exists.');
    }
    final normalized = resourceInformationName(name);
    return manifest.copyWith(tilesets: [
      for (final entry in manifest.tilesets)
        if (entry.id == tilesetId)
          entry.copyWith(name: normalized, folderId: folderId)
        else
          entry,
    ]);
  }
}

String resourceInformationName(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw VisualLibraryException('visual.name_invalid',
        'The resource or container name cannot be empty.');
  }
  return value.trim();
}

const _identitySchema = {'type': 'string', 'minLength': 1};
const _nameSchema = {'type': 'string', 'minLength': 1};

AuthoringActionDescriptor _informationDescriptor(
        String id, Map<String, Object?> properties,
        {bool high = false}) =>
    AuthoringActionDescriptor(
      id: id,
      version: 1,
      summary: 'Edit logical resource information: $id',
      inputSchemaId: 'pokemap.authoring.$id.input.v1',
      outputSchemaId: 'pokemap.authoring.visual_library.mutation.v1',
      riskLevel: high ? AuthoringRiskLevel.high : AuthoringRiskLevel.medium,
      resourceKinds: switch (id) {
        'tileset.metadata.update' => const ['project', 'tileset'],
        'element.category.assign' => const ['project', 'element'],
        'smart_tile.preset.category.assign' => const [
            'project',
            'smartTilePreset'
          ],
        _ => const ['project'],
      },
      capabilityIds: const ['authoring.visual_library'],
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.atomic,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable
      ],
      extensions: {
        'inputSchema': {
          'type': 'object',
          'additionalProperties': false,
          'required': properties.keys.toList(),
          'properties': properties
        }
      },
    );
