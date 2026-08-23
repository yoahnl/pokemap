import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'tileset_actions.dart';

const int _elementBatchUpsertLimit = 512;

final class ElementActions {
  const ElementActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    visualLibraryDescriptor(
      'element.upsert',
      'Create or replace one validated visual element',
    ),
    visualLibraryDescriptor(
      'element.batch_upsert',
      'Create or replace a validated batch of visual elements atomically',
    ),
    visualLibraryDescriptor(
      'element.delete',
      'Delete one unreferenced visual element',
      risk: AuthoringRiskLevel.high,
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = VisualLibraryParameters(context.request.parameters);
    switch (context.request.actionId) {
      case 'element.upsert':
        parameters.allow(const {'element'});
        final element = ProjectElementEntry.fromJson(
          Map<String, dynamic>.from(parameters.object('element')),
        );
        final next = upsert(
          context.snapshot.manifest,
          element: element,
          atlases: readTilesetAtlases(context.snapshot.manifest),
        );
        return buildVisualManifestDraft(
          context.snapshot,
          next,
          operation: 'element.upsert',
          path: '/elements/${element.id}',
          after: element.toJson(),
        );
      case 'element.batch_upsert':
        parameters.allow(const {'elements'});
        final elements = [
          for (final value in parameters.objects('elements'))
            ProjectElementEntry.fromJson(Map<String, dynamic>.from(value)),
        ];
        final next = upsertMany(
          context.snapshot.manifest,
          elements: elements,
          atlases: readTilesetAtlases(context.snapshot.manifest),
        );
        return buildVisualManifestDraft(
          context.snapshot,
          next,
          operation: 'element.batch_upsert',
          path: '/elements',
          after: {
            'elementIds': [for (final element in elements) element.id],
          },
        );
      case 'element.delete':
        parameters.allow(const {'elementId'});
        final elementId = parameters.string('elementId');
        final next = delete(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          elementId: elementId,
        );
        return buildVisualManifestDraft(
          context.snapshot,
          next,
          operation: 'element.delete',
          path: '/elements/$elementId',
          before: {'elementId': elementId},
          referenceImpact: {'references': const <String>[]},
        );
      default:
        throw VisualLibraryException(
          'visual.action_unsupported',
          'The requested element action is unsupported.',
        );
    }
  }

  ProjectManifest upsert(
    ProjectManifest manifest, {
    required ProjectElementEntry element,
    required Map<String, ProjectRegularAtlasTilesetSource> atlases,
  }) {
    if (!manifest.elementCategories.any(
      (category) => category.id == element.categoryId,
    )) {
      throw VisualLibraryException(
        'element.category_missing',
        'The element category is unknown.',
        details: {'categoryId': element.categoryId},
      );
    }
    if (element.frames.isEmpty) {
      throw VisualLibraryException(
        'element.frames_required',
        'An element requires at least one visual frame.',
      );
    }
    for (final frame in element.frames) {
      const TilesetActions().validateFrame(
        frame,
        owningTilesetId: element.tilesetId,
        atlases: atlases,
      );
    }
    final elements = [
      for (final existing in manifest.elements)
        if (existing.id != element.id) existing,
      element,
    ]..sort((left, right) => left.id.compareTo(right.id));
    return manifest.copyWith(elements: elements);
  }

  ProjectManifest upsertMany(
    ProjectManifest manifest, {
    required Iterable<ProjectElementEntry> elements,
    required Map<String, ProjectRegularAtlasTilesetSource> atlases,
  }) {
    final batch = elements.toList(growable: false);
    if (batch.isEmpty) {
      throw VisualLibraryException(
        'element.batch_empty',
        'An element batch requires at least one entry.',
      );
    }
    if (batch.length > _elementBatchUpsertLimit) {
      throw VisualLibraryException(
        'element.batch_limit_exceeded',
        'An element batch cannot exceed $_elementBatchUpsertLimit entries.',
        details: {
          'limit': _elementBatchUpsertLimit,
          'actual': batch.length,
        },
      );
    }
    final ids = <String>{};
    for (final element in batch) {
      if (!ids.add(element.id)) {
        throw VisualLibraryException(
          'element.batch_duplicate',
          'An element batch cannot contain duplicate identities.',
          details: {'elementId': element.id},
        );
      }
    }
    var result = manifest;
    for (final element in batch) {
      result = upsert(result, element: element, atlases: atlases);
    }
    return result;
  }

  ProjectManifest delete(
    ProjectManifest manifest, {
    required Iterable<MapData> maps,
    required String elementId,
  }) {
    if (!manifest.elements.any((element) => element.id == elementId)) {
      throw VisualLibraryException(
        'element.unknown',
        'The element identity is unknown.',
        details: {'elementId': elementId},
      );
    }
    final references = <String>{};
    for (final map in maps) {
      for (final placed in map.placedElements) {
        if (placed.elementId == elementId) {
          references.add('map:${map.id}:placedElement:${placed.id}');
        }
      }
    }
    for (final preset in manifest.environmentPresets) {
      if (preset.palette.any((item) => item.elementId == elementId)) {
        references.add('environmentPreset:${preset.id}');
      }
    }
    final ordered = references.toList()..sort();
    if (ordered.isNotEmpty) {
      throw VisualLibraryException(
        'element.references_blocking',
        'The element is still referenced and cannot be deleted safely.',
        details: {'elementId': elementId, 'references': ordered},
      );
    }
    return manifest.copyWith(
      elements: manifest.elements
          .where((element) => element.id != elementId)
          .toList(growable: false),
    );
  }
}
