import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'tileset_actions.dart';
import 'resource_information_actions.dart';
import 'resource_information_document.dart';

part 'visual_organization_validation.dart';

/// Canonical authoring semantics for the visual-library hierarchy.
final class VisualOrganizationActions {
  const VisualOrganizationActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    visualLibraryDescriptor(
      'project.visual_grid.update',
      'Align the project visual grid with every regular atlas',
      resourceKinds: const ['project', 'tileset'],
    ),
    visualLibraryDescriptor(
      'tileset_folder.upsert',
      'Create or replace one tileset library folder',
      resourceKinds: const ['project', 'tilesetFolder'],
      inputSchema: _organizationObjectSchema('folder', 'parentFolderId'),
    ),
    visualLibraryDescriptor(
      'tileset_folder.delete',
      'Delete one empty tileset library folder',
      risk: AuthoringRiskLevel.high,
      resourceKinds: const ['project', 'tilesetFolder'],
      inputSchema: _organizationIdSchema('folderId'),
    ),
    visualLibraryDescriptor(
      'element_category.upsert',
      'Create or replace one visual element category',
      resourceKinds: const ['elementCategory', 'project'],
      inputSchema: _organizationObjectSchema('category', 'parentCategoryId'),
    ),
    visualLibraryDescriptor(
      'element_category.delete',
      'Delete one empty visual element category',
      risk: AuthoringRiskLevel.high,
      resourceKinds: const ['elementCategory', 'project'],
      inputSchema: _organizationIdSchema('categoryId'),
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = VisualLibraryParameters(context.request.parameters);
    switch (context.request.actionId) {
      case 'project.visual_grid.update':
        parameters.allow(const {'grid'});
        final grid = parameters.object('grid');
        const fields = {'tileWidth', 'tileHeight', 'displayScale'};
        if (grid.keys.any((key) => !fields.contains(key)) ||
            grid['tileWidth'] is! int ||
            grid['tileHeight'] is! int ||
            grid['displayScale'] is! num) {
          throw VisualLibraryException(
            'visual.parameter_invalid',
            'The project visual grid object is invalid.',
            details: const {'parameter': 'grid'},
          );
        }
        final next = updateProjectVisualGrid(
          context.snapshot.manifest,
          tileWidth: grid['tileWidth']! as int,
          tileHeight: grid['tileHeight']! as int,
          displayScale: (grid['displayScale']! as num).toDouble(),
        );
        return buildVisualManifestDraft(
          context.snapshot,
          next,
          operation: 'project.visual_grid.update',
          path: '/settings',
          before: context.snapshot.manifest.settings.toJson(),
          after: next.settings.toJson(),
        );
      case 'tileset_folder.upsert':
        parameters.allow(const {'folder'});
        _validateOrganizationObject(
            parameters.object('folder'), 'parentFolderId');
        final folder = ProjectTilesetFolder.fromJson(
          Map<String, dynamic>.from(parameters.object('folder')),
        );
        final next = upsertTilesetFolder(
          context.snapshot.manifest,
          folder: folder,
        );
        return buildVisualManifestDraft(
          context.snapshot,
          next,
          operation: 'tileset_folder.upsert',
          encodedManifest:
              encodeResourceInformationDocument(context.snapshot, next),
          path: '/tilesetFolders/${folder.id}',
          after: folder.toJson(),
        );
      case 'tileset_folder.delete':
        parameters.allow(const {'folderId'});
        final folderId = parameters.string('folderId');
        final current = _tilesetFolder(
          context.snapshot.manifest,
          folderId,
        );
        final next = deleteTilesetFolder(
          context.snapshot.manifest,
          folderId: folderId,
        );
        return buildVisualManifestDraft(
          context.snapshot,
          next,
          operation: 'tileset_folder.delete',
          encodedManifest:
              encodeResourceInformationDocument(context.snapshot, next),
          path: '/tilesetFolders/$folderId',
          before: current.toJson(),
        );
      case 'element_category.upsert':
        parameters.allow(const {'category'});
        _validateOrganizationObject(
            parameters.object('category'), 'parentCategoryId');
        final category = ProjectElementCategory.fromJson(
          Map<String, dynamic>.from(parameters.object('category')),
        );
        final next = upsertElementCategory(
          context.snapshot.manifest,
          category: category,
        );
        return buildVisualManifestDraft(
          context.snapshot,
          next,
          operation: 'element_category.upsert',
          encodedManifest:
              encodeResourceInformationDocument(context.snapshot, next),
          path: '/elementCategories/${category.id}',
          after: category.toJson(),
        );
      case 'element_category.delete':
        parameters.allow(const {'categoryId'});
        final categoryId = parameters.string('categoryId');
        final current = _elementCategory(
          context.snapshot.manifest,
          categoryId,
        );
        final next = deleteElementCategory(
          context.snapshot.manifest,
          categoryId: categoryId,
        );
        return buildVisualManifestDraft(
          context.snapshot,
          next,
          operation: 'element_category.delete',
          encodedManifest:
              encodeResourceInformationDocument(context.snapshot, next),
          path: '/elementCategories/$categoryId',
          before: current.toJson(),
        );
      default:
        throw VisualLibraryException(
          'visual.action_unsupported',
          'The requested visual organization action is unsupported.',
        );
    }
  }

  ProjectManifest upsertTilesetFolder(
    ProjectManifest manifest, {
    required ProjectTilesetFolder folder,
  }) {
    folder = folder.copyWith(name: resourceInformationName(folder.name));
    _validateOrganizationParent(
        folder.id,
        folder.parentFolderId,
        {
          for (final entry in manifest.tilesetFolders)
            entry.id: entry.parentFolderId,
        },
        'tileset_folder');
    final folders = [
      for (final current in manifest.tilesetFolders)
        if (current.id == folder.id) folder else current,
      if (!manifest.tilesetFolders.any((entry) => entry.id == folder.id))
        folder,
    ];
    return manifest.copyWith(tilesetFolders: folders);
  }

  ProjectManifest deleteTilesetFolder(
    ProjectManifest manifest, {
    required String folderId,
  }) {
    _tilesetFolder(manifest, folderId);
    final references = <String>[
      for (final folder in manifest.tilesetFolders)
        if (folder.parentFolderId == folderId) 'tilesetFolder:${folder.id}',
      for (final tileset in manifest.tilesets)
        if (tileset.folderId == folderId) 'tileset:${tileset.id}',
    ]..sort();
    if (references.isNotEmpty) {
      throw VisualLibraryException(
        'tileset_folder.references_blocking',
        'The tileset folder is not empty and cannot be deleted safely.',
        details: {'folderId': folderId, 'references': references},
      );
    }
    return manifest.copyWith(
      tilesetFolders: manifest.tilesetFolders
          .where((folder) => folder.id != folderId)
          .toList(growable: false),
    );
  }

  ProjectManifest upsertElementCategory(
    ProjectManifest manifest, {
    required ProjectElementCategory category,
  }) {
    category = category.copyWith(name: resourceInformationName(category.name));
    _validateOrganizationParent(
        category.id,
        category.parentCategoryId,
        {
          for (final entry in manifest.elementCategories)
            entry.id: entry.parentCategoryId,
        },
        'element_category');
    final categories = [
      for (final current in manifest.elementCategories)
        if (current.id == category.id) category else current,
      if (!manifest.elementCategories.any((entry) => entry.id == category.id))
        category,
    ];
    return manifest.copyWith(elementCategories: categories);
  }

  ProjectManifest deleteElementCategory(
    ProjectManifest manifest, {
    required String categoryId,
  }) {
    _elementCategory(manifest, categoryId);
    final references = <String>[
      for (final category in manifest.elementCategories)
        if (category.parentCategoryId == categoryId)
          'elementCategory:${category.id}',
      for (final element in manifest.elements)
        if (element.categoryId == categoryId) 'element:${element.id}',
    ]..sort();
    if (references.isNotEmpty) {
      throw VisualLibraryException(
        'element_category.references_blocking',
        'The element category is not empty and cannot be deleted safely.',
        details: {'categoryId': categoryId, 'references': references},
      );
    }
    return manifest.copyWith(
      elementCategories: manifest.elementCategories
          .where((category) => category.id != categoryId)
          .toList(growable: false),
    );
  }

  ProjectManifest updateProjectVisualGrid(
    ProjectManifest manifest, {
    required int tileWidth,
    required int tileHeight,
    required double displayScale,
  }) =>
      _updateProjectVisualGrid(manifest,
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          displayScale: displayScale);
}
