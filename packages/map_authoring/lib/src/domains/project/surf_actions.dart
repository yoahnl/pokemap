import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';

final class SurfActions {
  const SurfActions();

  static final descriptor = AuthoringActionDescriptor(
    id: 'surf.configure',
    version: 1,
    summary: 'Configure Surf access, move requirements and movement speed',
    inputSchemaId: 'pokemap.authoring.surf.configure.input.v1',
    outputSchemaId: 'pokemap.authoring.surf.configure.output.v1',
    riskLevel: AuthoringRiskLevel.low,
    resourceKinds: const ['project', 'surfConfiguration'],
    capabilityIds: const ['authoring.surf', 'gameplay.surf@1'],
    requiredPermissions: const [AuthoringPermission.projectWrite],
    guarantees: const [
      AuthoringGuarantee.atomic,
      AuthoringGuarantee.dryRun,
      AuthoringGuarantee.idempotent,
      AuthoringGuarantee.revisionChecked,
      AuthoringGuarantee.undoable,
    ],
    extensions: const {
      'parameterNames': ['configuration'],
      'field': 'settings.surf',
      'inputSchema': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['configuration'],
        'properties': {
          'configuration': {
            'oneOf': [
              {'type': 'null'},
              {
                'type': 'object',
                'additionalProperties': false,
                'properties': {
                  'enabled': {'type': 'boolean'},
                  'requiresKnownMove': {'type': 'boolean'},
                  'accessMode': {
                    'enum': ['progression', 'always', 'condition']
                  },
                  'speedCellsPerSecond': {
                    'type': 'number',
                    'exclusiveMinimum': 0
                  },
                  'condition': {
                    'type': ['object', 'null']
                  },
                },
              },
            ],
          },
        },
      },
    },
  );

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = context.request.parameters;
    if (parameters.length != 1 || !parameters.containsKey('configuration')) {
      throw const FormatException(
          'Only the complete Surf configuration is accepted.');
    }
    final raw = parameters['configuration'];
    if (raw != null && raw is! Map) {
      throw const FormatException(
          'Surf configuration must be an object or null.');
    }
    final config = raw == null
        ? null
        : ProjectSurfSettings.fromJson(Map<String, dynamic>.from(raw as Map));
    final snapshot = context.snapshot;
    final manifest = snapshot.manifest;
    if (config?.condition case final condition?
        when config!.accessMode == ProjectSurfAccessMode.condition) {
      _validateReferences(condition, manifest, snapshot.itemCatalog);
    }
    final next =
        manifest.copyWith(settings: manifest.settings.copyWith(surf: config));
    if (jsonEncode(manifest.settings.surf?.toJson()) ==
        jsonEncode(config?.toJson())) {
      return AuthoringMutationDraft(
          changeSet: AuthoringChangeSet.noChanges(),
          preview: const {'operation': 'surf.configure', 'noOp': true});
    }
    final original =
        jsonDecode(utf8.decode(snapshot.authoringProjectBytes)) as Map;
    final document = Map<String, Object?>.from(original);
    final settings =
        Map<String, Object?>.from(document['settings'] as Map? ?? const {});
    if (config == null) {
      settings.remove('surf');
    } else {
      settings['surf'] = config.toJson();
    }
    document['settings'] = settings;
    final resource = AuthoringResourceRef(
        kind: 'project',
        id: 'project',
        revision: snapshot.resourceFingerprints['project']);
    return AuthoringMutationDraft(
      projectedProject: next,
      changeSet: AuthoringChangeSet(
          changes: [
            AuthoringResourceChange(
              resource: resource,
              storageKey: 'project.json',
              beforeBytes: snapshot.resourceBytes('project'),
              afterBytes: utf8.encode(jsonEncode(document)),
            )
          ],
          diff: AuthoringDiff([
            AuthoringDiffEntry(
              operation: AuthoringDiffOperation.replace,
              resource: resource,
              path: '/settings/surf',
              before: manifest.settings.surf?.toJson(),
              after: config?.toJson(),
            )
          ])),
      preview: const {'operation': 'surf.configure', 'path': '/settings/surf'},
    );
  }
}

void _validateReferences(ScriptCondition condition, ProjectManifest manifest,
    ProjectItemCatalog? items) {
  final params = condition.params;
  switch (condition.type) {
    case ScriptConditionType.factEquals:
      final id = params[ScriptConditionParams.factId];
      final fact = manifest.facts.where((value) => value.id == id).firstOrNull;
      if (fact == null ||
          fact.valueKind.wireName != params[ScriptConditionParams.valueType]) {
        throw const FormatException(
            'Surf condition requires an existing Fact with the matching value type.');
      }
    case ScriptConditionType.badgeOwned:
      if (!manifest.badges
          .any((value) => value.id == params[ScriptConditionParams.badgeId])) {
        throw const FormatException(
            'Surf condition references an unknown badge.');
      }
    case ScriptConditionType.playerOnMap:
      if (!manifest.maps
          .any((value) => value.id == params[ScriptConditionParams.mapId])) {
        throw const FormatException(
            'Surf condition references an unknown map.');
      }
    case ScriptConditionType.stepCompleted:
      if (!manifest.storylines.any((story) => story.chapters.any((chapter) =>
          chapter.steps.any(
              (step) => step.id == params[ScriptConditionParams.stepId])))) {
        throw const FormatException(
            'Surf condition references an unknown story step.');
      }
    case ScriptConditionType.itemQuantityAtLeast:
      if (items == null ||
          !items.entries
              .any((item) => item.id == params[ScriptConditionParams.itemId])) {
        throw const FormatException(
            'Surf condition references an unknown item.');
      }
    default:
      break;
  }
  for (final child in condition.children) {
    _validateReferences(child, manifest, items);
  }
}
