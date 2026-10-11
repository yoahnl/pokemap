import 'package:map_core/map_core.dart';

import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../references/resource_library_scope_guard.dart';
import 'resource_information_document.dart';
import 'tileset_actions.dart';

final class ResourceLibraryActions {
  const ResourceLibraryActions();

  static final descriptors = [
    for (final operation in ['create', 'update', 'delete'])
      visualLibraryDescriptor(
          'resource.family.$operation', 'Manage one shared resource family',
          resourceKinds: const [
            'project',
            'resourceFamily'
          ],
          inputSchema: {
            'type': 'object',
            'additionalProperties': false,
            'required': ['familyId', if (operation != 'delete') 'name'],
            'properties': {
              'familyId': {'type': 'string', 'minLength': 1},
              if (operation != 'delete')
                'name': {'type': 'string', 'minLength': 1},
              if (operation != 'delete')
                'parentId': {
                  'type': ['string', 'null'],
                  'minLength': 1
                },
            },
          }),
    visualLibraryDescriptor('resource.classify',
        'Classify one typed resource and configure its project or map scope',
        resourceKinds: const [
          'project',
          'resourceLibraryEntry'
        ],
        inputSchema: {
          'type': 'object',
          'additionalProperties': false,
          'required': ['resourceKind', 'resourceId'],
          'properties': {
            'resourceKind': {
              'type': 'string',
              'enum': ResourceLibraryCatalog.resourceKinds.toList()
            },
            'resourceId': {'type': 'string', 'minLength': 1},
            'familyId': {
              'type': ['string', 'null'],
              'minLength': 1
            },
            'mapId': {
              'type': ['string', 'null'],
              'minLength': 1
            },
          },
        }),
  ];

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final project = context.snapshot.manifest;
    final catalog = project.resourceLibraryCatalog;
    final values = context.request.parameters;
    final parameters = VisualLibraryParameters(values);
    final action = context.request.actionId;
    final ResourceLibraryCatalog next;
    try {
      if (action == 'resource.classify') {
        parameters
            .allow(const {'resourceKind', 'resourceId', 'familyId', 'mapId'});
        final kind = parameters.string('resourceKind');
        final id = parameters.string('resourceId');
        if (!resourceLibraryResourceExists(project, kind, id)) {
          throw VisualLibraryException('resource_library.resource_unknown',
              'The typed resource does not exist.');
        }
        final previous = catalog.entryFor(kind, id);
        final entry = ResourceLibraryEntry(
          resourceKind: kind,
          resourceId: id,
          familyId: values.containsKey('familyId')
              ? _nullableIdentifier(values['familyId'])
              : previous?.familyId,
          mapId: values.containsKey('mapId')
              ? _nullableIdentifier(values['mapId'])
              : previous?.mapId,
        );
        next = ResourceLibraryCatalog(families: catalog.families, entries: [
          for (final existing in catalog.entries)
            if (existing.identity != entry.identity) existing,
          if (entry.familyId != null || entry.mapId != null) entry,
        ]);
      } else {
        parameters.allow(action == 'resource.family.delete'
            ? const {'familyId'}
            : const {'familyId', 'name', 'parentId'});
        final id = parameters.string('familyId');
        if (ResourceLibraryCatalog.predefinedFamilies
            .any((family) => family.id == id)) {
          throw VisualLibraryException('resource_library.predefined_family',
              'Predefined resource families cannot be changed.');
        }
        final previous =
            catalog.families.where((family) => family.id == id).firstOrNull;
        if (action == 'resource.family.create' && previous != null ||
            action != 'resource.family.create' && previous == null) {
          throw VisualLibraryException(
              'resource_library.family_unknown_or_duplicate',
              'The resource family identity is unavailable.');
        }
        if (action == 'resource.family.delete' &&
            (catalog.families.any((family) => family.parentId == id) ||
                catalog.entries.any((entry) => entry.familyId == id))) {
          throw VisualLibraryException('resource_library.family_not_empty',
              'Move the classified resources and child families before deleting this family.');
        }
        if (!const {
          'resource.family.create',
          'resource.family.update',
          'resource.family.delete'
        }.contains(action)) {
          throw VisualLibraryException('resource_library.action_unsupported',
              'Unsupported resource library action.');
        }
        next = ResourceLibraryCatalog(families: [
          for (final family in catalog.families)
            if (family.id != id) family,
          if (action != 'resource.family.delete')
            ResourceFamily(
                id: id,
                name: parameters.string('name'),
                parentId: values.containsKey('parentId')
                    ? _nullableIdentifier(values['parentId'])
                    : previous?.parentId),
        ], entries: catalog.entries);
      }
      final updated = project.copyWith(resourceLibraryCatalog: next);
      validateResourceLibraryTargets(updated);
      return guardResourceLibraryMutation(
          context,
          buildVisualManifestDraft(context.snapshot, updated,
              encodedManifest:
                  encodeResourceInformationDocument(context.snapshot, updated),
              operation: action,
              path: '/resourceLibraryCatalog',
              before: catalog.toJson(),
              after: next.toJson()));
    } on ArgumentError catch (error) {
      throw VisualLibraryException(
          'resource_library.invalid', error.message.toString());
    } on FormatException catch (error) {
      throw VisualLibraryException(
          'resource_library.invalid', error.message.toString());
    }
  }
}

String? _nullableIdentifier(Object? value) {
  if (value == null) return null;
  if (value is! String || value.isEmpty || value != value.trim()) {
    throw ArgumentError.value(
        value, 'resourceLibrary', 'expected null or nonblank trimmed identity');
  }
  return value;
}
