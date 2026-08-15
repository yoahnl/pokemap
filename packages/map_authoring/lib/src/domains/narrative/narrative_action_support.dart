import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';
import '../maps/map_lifecycle_adapter.dart';

AuthoringActionDescriptor narrativeActionDescriptor(
  String id,
  String summary, {
  List<String> resourceKinds = const ['project'],
  AuthoringRiskLevel risk = AuthoringRiskLevel.medium,
}) =>
    AuthoringActionDescriptor(
      id: id,
      version: 1,
      summary: summary,
      inputSchemaId: 'pokemap.authoring/$id.input.v1',
      outputSchemaId: 'pokemap.authoring/$id.output.v1',
      riskLevel: risk,
      resourceKinds: resourceKinds,
      capabilityIds: const ['authoring.narrative.modern'],
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.atomic,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
    );

AuthoringMutationDraft narrativeProjectDraft(
  ProjectSnapshot snapshot,
  ProjectManifest projected, {
  required String operation,
  required String path,
  Object? before,
  Object? after,
  Map<String, Object?> preview = const {},
}) {
  final project = AuthoringResourceRef(
    kind: 'project',
    id: 'project',
    revision: snapshot.resourceFingerprints['project'],
  );
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: [
        AuthoringResourceChange(
          resource: project,
          storageKey: 'project.json',
          beforeBytes: snapshot.resourceBytes('project'),
          afterBytes: encodeProjectAuthoringDocument(snapshot, projected),
        ),
      ],
      diff: AuthoringDiff([
        AuthoringDiffEntry(
          operation:
              operation.endsWith('.delete') || operation.endsWith('.remove')
                  ? AuthoringDiffOperation.remove
                  : before == null
                      ? AuthoringDiffOperation.add
                      : AuthoringDiffOperation.replace,
          resource: project,
          path: path,
          before: before,
          after: after,
        ),
      ]),
    ),
    preview: {'operation': operation, 'path': path, ...preview},
  );
}

Map<String, dynamic> narrativeObjectParameter(
  Map<String, Object?> parameters,
  String key,
) {
  final raw = parameters[key];
  if (raw is! Map) {
    throw ArgumentError.value(raw, key, 'must be a JSON object');
  }
  return Map<String, dynamic>.from(raw);
}

String narrativeStringParameter(
  Map<String, Object?> parameters,
  String key,
) {
  final value = parameters[key];
  if (value is! String || value.trim().isEmpty || value != value.trim()) {
    throw ArgumentError.value(value, key, 'must be a nonblank trimmed string');
  }
  return value;
}

void rejectUnknownNarrativeParameters(
  Map<String, Object?> parameters,
  Set<String> allowed,
) {
  final unknown =
      parameters.keys.where((key) => !allowed.contains(key)).toList()..sort();
  if (unknown.isNotEmpty) {
    throw ArgumentError.value(unknown, 'parameters', 'contains unknown keys');
  }
}
