import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/artifact_ref.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../ports/project_file_reader.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';
import '../maps/map_lifecycle_adapter.dart';
import 'dialogue_authoring_service.dart';
import 'dialogue_source_store.dart';
import 'narrative_authoring_exception.dart';

final class DialogueActions {
  const DialogueActions({
    this.compiler = const DialogueAuthoringCompiler(),
    this.migration = const DialogueLegacyMigrationService(),
  });

  final DialogueAuthoringCompiler compiler;
  final DialogueLegacyMigrationService migration;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    _descriptor('dialogue.create', 'Create a compiled Yarn dialogue'),
    _descriptor('dialogue.update', 'Update dialogue metadata and outcomes'),
    _descriptor('dialogue.source_update', 'Update and compile Yarn source'),
    _descriptor(
      'dialogue.delete',
      'Delete an unreferenced dialogue and source',
      risk: AuthoringRiskLevel.high,
    ),
    _descriptor(
      'dialogue.migrate_legacy',
      'Migrate legacy dialogue while preserving the original source',
      risk: AuthoringRiskLevel.medium,
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = _NarrativeParameters(context.request.parameters);
    switch (context.request.actionId) {
      case 'dialogue.create':
        parameters.allow(const {'entry', 'source'});
        final entry = parameters.dialogueEntry('entry');
        final source = parameters.text('source');
        final projected = create(
          context.snapshot.manifest,
          entry: entry,
          source: source,
        );
        return _manifestAndSourceDraft(
          context.snapshot,
          projected,
          operation: context.request.actionId,
          entry: entry,
          sourceBefore: null,
          sourceAfter: utf8.encode(source),
          manifestBefore: null,
          manifestAfter: entry.toJson(),
        );
      case 'dialogue.update':
        parameters.allow(const {'entry', 'outcomeReplacements'});
        final entry = parameters.dialogueEntry('entry');
        final projected = update(
          context.snapshot.manifest,
          entry: entry,
          outcomeReplacements: parameters.stringMap('outcomeReplacements'),
        );
        final before = _requireDialogue(context.snapshot.manifest, entry.id);
        return _manifestDraft(
          context.snapshot,
          projected,
          operation: context.request.actionId,
          path: '/dialogues/${entry.id}',
          before: before.toJson(),
          after: entry.toJson(),
        );
      case 'dialogue.source_update':
        parameters.allow(const {'dialogueId', 'source'});
        final entry = _requireDialogue(
          context.snapshot.manifest,
          parameters.string('dialogueId'),
        );
        final source = parameters.text('source');
        final result = compiler.compile(entry: entry, source: source);
        _requirePublishable(result);
        final identity = dialogueSourceResourceIdentity(entry.id);
        final before = context.snapshot.resourceBytes(identity);
        final after = utf8.encode(source);
        return _sourceOnlyDraft(
          context.snapshot,
          entry: entry,
          operation: context.request.actionId,
          before: before,
          after: after,
          preview: result.toJson(),
        );
      case 'dialogue.delete':
        parameters.allow(const {'dialogueId'});
        final id = parameters.string('dialogueId');
        final entry = _requireDialogue(context.snapshot.manifest, id);
        final projected = delete(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          dialogueId: id,
        );
        return _manifestAndSourceDraft(
          context.snapshot,
          projected,
          operation: context.request.actionId,
          entry: entry,
          sourceBefore: context.snapshot.resourceBytes(
            dialogueSourceResourceIdentity(id),
          ),
          sourceAfter: null,
          manifestBefore: entry.toJson(),
          manifestAfter: null,
        );
      case 'dialogue.migrate_legacy':
        parameters.allow(const {'dialogueId'});
        final id = parameters.string('dialogueId');
        final entry = _requireDialogue(context.snapshot.manifest, id);
        final sourceBytes = context.snapshot.resourceBytes(
          dialogueSourceResourceIdentity(id),
        );
        final source = _decodeSource(sourceBytes);
        final preview = migration.preview(entry: entry, source: source);
        final migratedEntry = entry.copyWith(relativePath: preview.targetPath);
        final result = compiler.compile(
          entry: migratedEntry,
          source: preview.generatedYarn,
        );
        _requirePublishable(result);
        final projected = _replaceDialogue(
          context.snapshot.manifest,
          migratedEntry,
        );
        return _legacyMigrationDraft(
          context.snapshot,
          projected,
          before: entry,
          after: migratedEntry,
          generatedSource: utf8.encode(preview.generatedYarn),
          preview: preview.toJson(),
        );
      default:
        throw NarrativeAuthoringException(
          'dialogue.action_unsupported',
          'The requested dialogue action is unsupported.',
          details: {'actionId': context.request.actionId},
        );
    }
  }

  ProjectManifest create(
    ProjectManifest manifest, {
    required ProjectDialogueEntry entry,
    required String source,
  }) {
    if (manifest.dialogues.any((candidate) => candidate.id == entry.id)) {
      throw NarrativeAuthoringException(
        'dialogue.id_conflict',
        'A dialogue already owns this identity.',
        details: {'dialogueId': entry.id},
      );
    }
    _requireDialoguePathAvailable(manifest, entry.relativePath);
    if (!entry.relativePath.toLowerCase().endsWith('.yarn')) {
      throw NarrativeAuthoringException(
        'dialogue.yarn_path_required',
        'New dialogues must use a .yarn project path.',
      );
    }
    _requirePublishable(compiler.compile(entry: entry, source: source));
    return _validated(
      manifest.copyWith(dialogues: [...manifest.dialogues, entry]),
    );
  }

  ProjectManifest update(
    ProjectManifest manifest, {
    required ProjectDialogueEntry entry,
    Map<String, String> outcomeReplacements = const {},
  }) {
    final before = _requireDialogue(manifest, entry.id);
    if (before.relativePath != entry.relativePath) {
      throw NarrativeAuthoringException(
        'dialogue.path_change_requires_migration',
        'Dialogue source paths can change only through an explicit migration.',
      );
    }
    var candidate = manifest;
    final nextOutcomes = {
      for (final outcome in entry.declaredOutcomes) outcome.id
    };
    for (final replacement in outcomeReplacements.entries) {
      if (!before.declaredOutcomes.any((item) => item.id == replacement.key) ||
          !nextOutcomes.contains(replacement.value)) {
        throw NarrativeAuthoringException(
          'dialogue.outcome_replacement_invalid',
          'Outcome replacements must map an existing outcome to a declared one.',
          details: {'from': replacement.key, 'to': replacement.value},
        );
      }
      candidate = replaceDialogueOutcomeSceneReferences(
        candidate,
        dialogueId: entry.id,
        fromOutcomeId: replacement.key,
        toOutcomeId: replacement.value,
      );
    }
    final removed = {
      for (final outcome in before.declaredOutcomes) outcome.id,
    }.difference(nextOutcomes);
    final blocking = [
      for (final outcome in removed)
        ...collectDialogueOutcomeSceneUsages(
          candidate,
          dialogueId: entry.id,
          outcomeId: outcome,
        ),
    ];
    if (blocking.isNotEmpty) {
      throw NarrativeAuthoringException(
        'dialogue.outcome_references_blocking',
        'A declared outcome is still consumed by a Scene.',
        details: {
          'references': [for (final usage in blocking) usage.path],
        },
      );
    }
    return _validated(_replaceDialogue(candidate, entry));
  }

  ProjectManifest delete(
    ProjectManifest manifest, {
    required Iterable<MapData> maps,
    required String dialogueId,
  }) {
    _requireDialogue(manifest, dialogueId);
    final index = buildNarrativeDependencyIndex(
      project: manifest,
      maps: maps.toList(),
    );
    final usages = index.usagesFor(
      NarrativeDependencyKey(
          NarrativeDependencyTargetKind.dialogue, dialogueId),
    );
    final scriptUsages = _scriptDialogueUsages(manifest, dialogueId);
    if (usages.isNotEmpty || scriptUsages.isNotEmpty) {
      throw NarrativeAuthoringException(
        'dialogue.references_blocking',
        'The dialogue is still referenced and cannot be deleted.',
        details: {
          'references': [
            ...usages.map((usage) => usage.path),
            ...scriptUsages,
          ]..sort(),
        },
      );
    }
    return _validated(
      manifest.copyWith(
        dialogues: [
          for (final entry in manifest.dialogues)
            if (entry.id != dialogueId) entry,
        ],
      ),
    );
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
      resourceKinds: const ['project', 'dialogue'],
      capabilityIds: const ['authoring.narrative.dialogue'],
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.atomic,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
    );

AuthoringMutationDraft _manifestDraft(
  ProjectSnapshot snapshot,
  ProjectManifest projected, {
  required String operation,
  required String path,
  Object? before,
  Object? after,
}) {
  final project = _projectRef(snapshot);
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: [_projectChange(snapshot, projected, project)],
      diff: AuthoringDiff([
        AuthoringDiffEntry(
          operation: operation.endsWith('.delete')
              ? AuthoringDiffOperation.remove
              : AuthoringDiffOperation.replace,
          resource: project,
          path: path,
          before: before,
          after: after,
        ),
      ]),
    ),
    preview: {'operation': operation, 'path': path},
  );
}

AuthoringMutationDraft _manifestAndSourceDraft(
  ProjectSnapshot snapshot,
  ProjectManifest projected, {
  required String operation,
  required ProjectDialogueEntry entry,
  required List<int>? sourceBefore,
  required List<int>? sourceAfter,
  Object? manifestBefore,
  Object? manifestAfter,
}) {
  final project = _projectRef(snapshot);
  final source = AuthoringResourceRef(
    kind: 'dialogue',
    id: entry.id,
    revision:
        snapshot.resourceFingerprints[dialogueSourceResourceIdentity(entry.id)],
  );
  final sourcePath = sourceAfter == null
      ? snapshot.resourceStorageKeys[dialogueSourceResourceIdentity(entry.id)]!
      : entry.relativePath;
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: [
        _projectChange(snapshot, projected, project),
        AuthoringResourceChange(
          resource: source,
          storageKey: sourcePath,
          beforeBytes: sourceBefore,
          afterBytes: sourceAfter,
        ),
      ],
      diff: AuthoringDiff([
        AuthoringDiffEntry(
          operation: operation.endsWith('.delete')
              ? AuthoringDiffOperation.remove
              : AuthoringDiffOperation.add,
          resource: project,
          path: '/dialogues/${entry.id}',
          before: manifestBefore,
          after: manifestAfter,
        ),
        AuthoringDiffEntry(
          operation: operation.endsWith('.delete')
              ? AuthoringDiffOperation.remove
              : AuthoringDiffOperation.add,
          resource: source,
          path: '/',
          before: sourceBefore == null ? null : _sourceSummary(sourceBefore),
          after: sourceAfter == null ? null : _sourceSummary(sourceAfter),
        ),
      ]),
    ),
    preview: {
      'operation': operation,
      'dialogueId': entry.id,
      'sourcePreservedForUndo': sourceBefore != null,
    },
  );
}

AuthoringMutationDraft _sourceOnlyDraft(
  ProjectSnapshot snapshot, {
  required ProjectDialogueEntry entry,
  required String operation,
  required List<int> before,
  required List<int> after,
  required Map<String, Object?> preview,
}) {
  final identity = dialogueSourceResourceIdentity(entry.id);
  final resource = AuthoringResourceRef(
    kind: 'dialogue',
    id: entry.id,
    revision: snapshot.resourceFingerprints[identity],
  );
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: [
        AuthoringResourceChange(
          resource: resource,
          storageKey: snapshot.resourceStorageKeys[identity]!,
          beforeBytes: before,
          afterBytes: after,
        ),
      ],
      diff: AuthoringDiff([
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.replace,
          resource: resource,
          path: '/',
          before: _sourceSummary(before),
          after: _sourceSummary(after),
        ),
      ]),
    ),
    preview: preview,
  );
}

AuthoringMutationDraft _legacyMigrationDraft(
  ProjectSnapshot snapshot,
  ProjectManifest projected, {
  required ProjectDialogueEntry before,
  required ProjectDialogueEntry after,
  required List<int> generatedSource,
  required Map<String, Object?> preview,
}) {
  final project = _projectRef(snapshot);
  final source = AuthoringResourceRef(kind: 'dialogue', id: after.id);
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: [
        _projectChange(snapshot, projected, project),
        AuthoringResourceChange(
          resource: source,
          storageKey: after.relativePath,
          beforeBytes: null,
          afterBytes: generatedSource,
        ),
      ],
      diff: AuthoringDiff([
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.replace,
          resource: project,
          path: '/dialogues/${after.id}',
          before: before.toJson(),
          after: after.toJson(),
        ),
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.add,
          resource: source,
          path: '/',
          after: _sourceSummary(generatedSource),
        ),
      ]),
    ),
    preview: {
      ...preview,
      'legacySourceRetainedAt': before.relativePath,
    },
  );
}

AuthoringResourceRef _projectRef(ProjectSnapshot snapshot) =>
    AuthoringResourceRef(
      kind: 'project',
      id: 'project',
      revision: snapshot.resourceFingerprints['project'],
    );

AuthoringResourceChange _projectChange(
  ProjectSnapshot snapshot,
  ProjectManifest projected,
  AuthoringResourceRef project,
) =>
    AuthoringResourceChange(
      resource: project,
      storageKey: 'project.json',
      beforeBytes: snapshot.resourceBytes('project'),
      afterBytes: encodeProjectAuthoringDocument(snapshot, projected),
    );

Map<String, Object?> _sourceSummary(List<int> bytes) {
  final artifact = ContentArtifactRef.fromBytes(
    bytes,
    mediaType: 'text/x-yarn',
  );
  return {
    'digest': artifact.digest,
    'byteLength': artifact.byteLength,
  };
}

ProjectDialogueEntry _requireDialogue(ProjectManifest manifest, String id) =>
    manifest.dialogues.where((entry) => entry.id == id).firstOrNull ??
    (throw NarrativeAuthoringException(
      'dialogue.unknown',
      'The dialogue identity is unknown.',
      details: {'dialogueId': id},
    ));

ProjectManifest _replaceDialogue(
  ProjectManifest manifest,
  ProjectDialogueEntry replacement,
) =>
    manifest.copyWith(
      dialogues: [
        for (final entry in manifest.dialogues)
          if (entry.id == replacement.id) replacement else entry,
      ],
    );

void _requireDialoguePathAvailable(ProjectManifest manifest, String path) {
  validateProjectRelativePath(path);
  if (manifest.dialogues.any((entry) => entry.relativePath == path) ||
      manifest.maps.any((entry) => entry.relativePath == path)) {
    throw NarrativeAuthoringException(
      'dialogue.path_conflict',
      'The requested dialogue source path is already owned.',
      details: {'relativePath': path},
    );
  }
}

void _requirePublishable(DialogueAuthoringCompileResult result) {
  if (!result.canPublish) {
    throw NarrativeAuthoringException(
      'dialogue.compile_blocking',
      'The dialogue source has blocking compile diagnostics.',
      details: {
        'diagnostics': [for (final item in result.diagnostics) item.toJson()],
      },
    );
  }
}

ProjectManifest _validated(ProjectManifest manifest) {
  try {
    ProjectValidator.validate(manifest);
  } on Object catch (error) {
    throw NarrativeAuthoringException(
      'narrative.projected_state_invalid',
      'The narrative mutation would invalidate the project.',
      details: {'validationType': error.runtimeType.toString()},
    );
  }
  return manifest;
}

String _decodeSource(List<int> bytes) {
  try {
    return utf8.decode(bytes, allowMalformed: false);
  } on Object {
    throw NarrativeAuthoringException(
      'dialogue.source_not_utf8',
      'The dialogue source is not valid UTF-8.',
    );
  }
}

List<String> _scriptDialogueUsages(ProjectManifest manifest, String id) {
  final entry = _requireDialogue(manifest, id);
  final result = <String>[];
  for (final script in manifest.scripts) {
    for (var nodeIndex = 0;
        nodeIndex < script.asset.nodes.length;
        nodeIndex++) {
      final node = script.asset.nodes[nodeIndex];
      for (var commandIndex = 0;
          commandIndex < node.commands.length;
          commandIndex++) {
        final command = node.commands[commandIndex];
        if (command.type == ScriptCommandType.openDialogue &&
            (command.params['dialogueId'] == id ||
                command.params['filePath'] == entry.relativePath)) {
          result.add(
            'scripts[${script.id}].nodes[$nodeIndex].commands[$commandIndex]',
          );
        }
      }
    }
  }
  return List.unmodifiable(result..sort());
}

final class _NarrativeParameters {
  _NarrativeParameters(Map<String, Object?> values) : _values = values;

  final Map<String, Object?> _values;

  void allow(Set<String> allowed) {
    final unknown = _values.keys.where((key) => !allowed.contains(key)).toList()
      ..sort();
    if (unknown.isNotEmpty) {
      throw NarrativeAuthoringException(
        'narrative.parameters_unknown',
        'The request contains unsupported narrative parameters.',
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

  String text(String key) {
    final value = _values[key];
    if (value is! String || value.isEmpty || value.contains('\u0000')) {
      throw NarrativeAuthoringException(
        'narrative.text_required',
        'A non-empty "$key" text value is required.',
      );
    }
    return value;
  }

  ProjectDialogueEntry dialogueEntry(String key) {
    final raw = _values[key];
    if (raw is! Map) {
      throw NarrativeAuthoringException(
        'dialogue.entry_required',
        'A dialogue entry object is required.',
      );
    }
    try {
      return ProjectDialogueEntry.fromJson(Map<String, dynamic>.from(raw));
    } on Object {
      throw NarrativeAuthoringException(
        'dialogue.entry_invalid',
        'The dialogue entry cannot be decoded.',
      );
    }
  }

  Map<String, String> stringMap(String key) {
    final raw = _values[key];
    if (raw == null) return const {};
    if (raw is! Map || raw.keys.any((item) => item is! String)) {
      throw NarrativeAuthoringException(
        'narrative.string_map_invalid',
        'The "$key" parameter must be a string map.',
      );
    }
    final result = <String, String>{};
    for (final entry in raw.entries) {
      if (entry.value is! String || (entry.value! as String).trim().isEmpty) {
        throw NarrativeAuthoringException(
          'narrative.string_map_invalid',
          'The "$key" parameter must contain nonblank strings.',
        );
      }
      result[entry.key! as String] = (entry.value! as String).trim();
    }
    return Map.unmodifiable(result);
  }
}
