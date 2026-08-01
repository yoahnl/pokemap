import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'tileset_actions.dart';

/// Canonical authoring semantics for the visual-library hierarchy.
final class VisualOrganizationActions {
  const VisualOrganizationActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    visualLibraryDescriptor(
      'tileset_folder.upsert',
      'Create or replace one tileset library folder',
      resourceKinds: const ['project', 'tilesetFolder'],
    ),
    visualLibraryDescriptor(
      'tileset_folder.delete',
      'Delete one empty tileset library folder',
      risk: AuthoringRiskLevel.high,
      resourceKinds: const ['project', 'tilesetFolder'],
    ),
    visualLibraryDescriptor(
      'element_category.upsert',
      'Create or replace one visual element category',
      resourceKinds: const ['elementCategory', 'project'],
    ),
    visualLibraryDescriptor(
      'element_category.delete',
      'Delete one empty visual element category',
      risk: AuthoringRiskLevel.high,
      resourceKinds: const ['elementCategory', 'project'],
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = VisualLibraryParameters(context.request.parameters);
    switch (context.request.actionId) {
      case 'tileset_folder.upsert':
        parameters.allow(const {'folder'});
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
          path: '/tilesetFolders/$folderId',
          before: current.toJson(),
        );
      case 'element_category.upsert':
        parameters.allow(const {'category'});
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
    final folders = [
      for (final current in manifest.tilesetFolders)
        if (current.id != folder.id) current,
      folder,
    ]..sort((left, right) => left.id.compareTo(right.id));
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
    final categories = [
      for (final current in manifest.elementCategories)
        if (current.id != category.id) current,
      category,
    ]..sort((left, right) => left.id.compareTo(right.id));
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
}

ProjectTilesetFolder _tilesetFolder(
  ProjectManifest manifest,
  String folderId,
) {
  for (final folder in manifest.tilesetFolders) {
    if (folder.id == folderId) return folder;
  }
  throw VisualLibraryException(
    'tileset_folder.unknown',
    'The tileset folder identity is unknown.',
    details: {'folderId': folderId},
  );
}

ProjectElementCategory _elementCategory(
  ProjectManifest manifest,
  String categoryId,
) {
  for (final category in manifest.elementCategories) {
    if (category.id == categoryId) return category;
  }
  throw VisualLibraryException(
    'element_category.unknown',
    'The element category identity is unknown.',
    details: {'categoryId': categoryId},
  );
}
