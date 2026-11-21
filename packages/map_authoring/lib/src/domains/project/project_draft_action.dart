import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../narrative/narrative_action_support.dart';
import 'project_draft_edits.dart';

final class ProjectDraftAction {
  const ProjectDraftAction();

  static final descriptor = AuthoringActionDescriptor(
    id: ProjectDraftEdits.actionId,
    version: 1,
    summary: 'Publish the changed documents of a staged project draft',
    inputSchemaId: 'pokemap.authoring.project.publish_draft.input.v1',
    outputSchemaId: 'pokemap.authoring.project.publish_draft.output.v1',
    riskLevel: AuthoringRiskLevel.medium,
    resourceKinds: const ['project'],
    capabilityIds: const ['authoring.project_identity'],
    requiredPermissions: const [AuthoringPermission.projectWrite],
    guarantees: const [
      AuthoringGuarantee.atomic,
      AuthoringGuarantee.dryRun,
      AuthoringGuarantee.idempotent,
      AuthoringGuarantee.revisionChecked,
      AuthoringGuarantee.undoable,
    ],
    extensions: {
      'parameterNames': ['name', 'documents'],
      'inputSchema': {
        'type': 'object',
        'additionalProperties': false,
        'minProperties': 1,
        'properties': {
          'name': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['before', 'after'],
            'properties': {
              'before': {'type': 'string'},
              'after': {'type': 'string', 'minLength': 1},
            },
          },
          'documents': {
            'type': 'object',
            'additionalProperties': false,
            'minProperties': 1,
            'properties': {
              for (final field in [...ProjectDraftEdits.documentFields, 'borderCatalog'])
                field: {
                  'type': 'object',
                  'minProperties': 1,
                  'additionalProperties': {
                    'type': 'object',
                    'additionalProperties': false,
                    'required': ['before', 'after'],
                    'properties': {
                      'before': {'type': ['object', 'null']},
                      'after': {'type': ['object', 'null']},
                    },
                  },
                },
            },
          },
        },
      },
    },
  );

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final edits = ProjectDraftEdits.fromParameters(context.request.parameters);
    final snapshot = context.snapshot;
    final projected = edits.apply(snapshot.manifest);
    ProjectValidator.validateCatalogSelection(projected);
    return narrativeProjectDraft(
      snapshot,
      projected,
      operation: ProjectDraftEdits.actionId,
      path: '/',
      before: const {'status': 'staged'},
      after: {
        'sections': edits.fields.toList()..sort(),
        'documents': {
          for (final section in edits.documents.entries)
            section.key: section.value.keys.toList()..sort(),
        },
      },
    );
  }
}
