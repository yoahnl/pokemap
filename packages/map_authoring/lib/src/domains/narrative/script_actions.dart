import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';
import '../maps/map_lifecycle_adapter.dart';
import 'dialogue_authoring_service.dart';
import 'narrative_authoring_exception.dart';
import 'script_authoring_service.dart';

final class ScriptActions {
  const ScriptActions({
    this.simulator = const ScriptAuthoringSimulator(),
  });

  final ScriptAuthoringSimulator simulator;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    _descriptor('script.upsert', 'Create or update a validated script'),
    _descriptor(
      'script.delete',
      'Delete an unreferenced script',
      risk: AuthoringRiskLevel.high,
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = _ScriptParameters(context.request.parameters);
    switch (context.request.actionId) {
      case 'script.upsert':
        parameters.allow(const {'entry'});
        final entry = parameters.entry();
        final before = context.snapshot.manifest.scripts
            .where((candidate) => candidate.id == entry.id)
            .firstOrNull;
        final projected = upsert(context.snapshot.manifest, entry: entry);
        return _draft(
          context.snapshot,
          projected,
          operation: context.request.actionId,
          path: '/scripts/${entry.id}',
          before: before?.toJson(),
          after: entry.toJson(),
          preview: simulator.simulate(entry.asset).toJson(),
        );
      case 'script.delete':
        parameters.allow(const {'scriptId'});
        final id = parameters.string('scriptId');
        final before = context.snapshot.manifest.scripts
            .where((candidate) => candidate.id == id)
            .firstOrNull;
        if (before == null) {
          throw NarrativeAuthoringException(
            'script.unknown',
            'The script identity is unknown.',
            details: {'scriptId': id},
          );
        }
        final projected = delete(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          scriptId: id,
        );
        return _draft(
          context.snapshot,
          projected,
          operation: context.request.actionId,
          path: '/scripts/$id',
          before: before.toJson(),
          preview: const {},
        );
      default:
        throw NarrativeAuthoringException(
          'script.action_unsupported',
          'The requested script action is unsupported.',
          details: {'actionId': context.request.actionId},
        );
    }
  }

  ProjectManifest upsert(
    ProjectManifest manifest, {
    required ProjectScriptEntry entry,
  }) {
    if (entry.id.trim().isEmpty || entry.id != entry.id.trim()) {
      throw NarrativeAuthoringException(
        'script.id_invalid',
        'The script identity must be nonblank and trimmed.',
      );
    }
    if (entry.asset.id != entry.id) {
      throw NarrativeAuthoringException(
        'script.asset_identity_mismatch',
        'The embedded script identity must match its project entry.',
      );
    }
    final diagnostics = simulator.validate(entry.asset);
    if (diagnostics.any((item) =>
        item.severity == NarrativeAuthoringDiagnosticSeverity.error)) {
      throw NarrativeAuthoringException(
        'script.validation_failed',
        'The script has blocking diagnostics.',
        details: {
          'diagnostics': [for (final item in diagnostics) item.toJson()],
        },
      );
    }
    final exists =
        manifest.scripts.any((candidate) => candidate.id == entry.id);
    return _validated(
      manifest.copyWith(
        scripts: exists
            ? [
                for (final candidate in manifest.scripts)
                  if (candidate.id == entry.id) entry else candidate,
              ]
            : [...manifest.scripts, entry],
      ),
    );
  }

  ProjectManifest delete(
    ProjectManifest manifest, {
    required Iterable<MapData> maps,
    required String scriptId,
  }) {
    if (!manifest.scripts.any((entry) => entry.id == scriptId)) {
      throw NarrativeAuthoringException(
        'script.unknown',
        'The script identity is unknown.',
        details: {'scriptId': scriptId},
      );
    }
    final without = manifest.copyWith(
      scripts: [
        for (final entry in manifest.scripts)
          if (entry.id != scriptId) entry,
      ],
    );
    final references = <String>{};
    if (_containsExactString(without.toJson(), scriptId)) {
      references.add('project');
    }
    for (final map in maps) {
      if (_containsExactString(map.toJson(), scriptId)) {
        references.add('map:${map.id}');
      }
    }
    if (references.isNotEmpty) {
      throw NarrativeAuthoringException(
        'script.references_blocking',
        'The script is still referenced and cannot be deleted.',
        details: {'references': references.toList()..sort()},
      );
    }
    return _validated(without);
  }
}

AuthoringActionDescriptor _descriptor(
  String id,
  String summary, {
  AuthoringRiskLevel risk = AuthoringRiskLevel.medium,
}) =>
    AuthoringActionDescriptor(
      id: id,
      version: 1,
      summary: summary,
      inputSchemaId: 'pokemap.authoring/$id.input.v1',
      outputSchemaId: 'pokemap.authoring/$id.output.v1',
      riskLevel: risk,
      resourceKinds: const ['project', 'script'],
      capabilityIds: const ['authoring.narrative.script'],
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.atomic,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
    );

AuthoringMutationDraft _draft(
  ProjectSnapshot snapshot,
  ProjectManifest projected, {
  required String operation,
  required String path,
  Object? before,
  Object? after,
  required Map<String, Object?> preview,
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
          operation: operation.endsWith('.delete')
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

ProjectManifest _validated(ProjectManifest manifest) {
  try {
    ProjectValidator.validate(manifest);
  } on Object catch (error) {
    throw NarrativeAuthoringException(
      'narrative.projected_state_invalid',
      'The script mutation would invalidate the project.',
      details: {'validationType': error.runtimeType.toString()},
    );
  }
  return manifest;
}

bool _containsExactString(Object? value, String expected) {
  if (value is String) return value == expected;
  if (value is List) {
    return value.any((item) => _containsExactString(item, expected));
  }
  if (value is Map) {
    return value.values.any((item) => _containsExactString(item, expected));
  }
  return false;
}

final class _ScriptParameters {
  _ScriptParameters(Map<String, Object?> values) : _values = values;

  final Map<String, Object?> _values;

  void allow(Set<String> allowed) {
    final unknown = _values.keys.where((key) => !allowed.contains(key)).toList()
      ..sort();
    if (unknown.isNotEmpty) {
      throw NarrativeAuthoringException(
        'narrative.parameters_unknown',
        'The request contains unsupported script parameters.',
        details: {'unknown': unknown},
      );
    }
  }

  String string(String key) {
    final value = _values[key];
    if (value is! String || value.trim().isEmpty || value != value.trim()) {
      throw NarrativeAuthoringException(
        'narrative.parameter_required',
        'A nonblank "$key" string is required.',
      );
    }
    return value;
  }

  ProjectScriptEntry entry() {
    final raw = _values['entry'];
    if (raw is! Map) {
      throw NarrativeAuthoringException(
        'script.entry_required',
        'A script entry object is required.',
      );
    }
    try {
      return ProjectScriptEntry.fromJson(Map<String, dynamic>.from(raw));
    } on Object {
      throw NarrativeAuthoringException(
        'script.entry_invalid',
        'The script entry cannot be decoded.',
      );
    }
  }
}
