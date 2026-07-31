# PMCP-050 — Contenu intégral des fichiers créés

Cette annexe reproduit intégralement les fichiers texte créés par le lot.

## `packages/map_authoring/lib/src/domains/narrative/dialogue_actions.dart`

```dart
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
```

## `packages/map_authoring/lib/src/domains/narrative/dialogue_authoring_service.dart`

```dart
import 'package:map_core/map_core.dart';

enum NarrativeAuthoringDiagnosticSeverity { warning, error }

final class DialogueAuthoringDiagnostic {
  const DialogueAuthoringDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    this.line,
    this.path,
  });

  final String code;
  final NarrativeAuthoringDiagnosticSeverity severity;
  final String message;
  final int? line;
  final String? path;

  Map<String, Object?> toJson() => {
        'code': code,
        'severity': severity.name,
        'message': message,
        if (line != null) 'line': line,
        if (path != null) 'path': path,
      };

  @override
  bool operator ==(Object other) =>
      other is DialogueAuthoringDiagnostic &&
      code == other.code &&
      severity == other.severity &&
      message == other.message &&
      line == other.line &&
      path == other.path;

  @override
  int get hashCode => Object.hash(code, severity, message, line, path);
}

final class DialogueAuthoringCompileResult {
  DialogueAuthoringCompileResult({
    required this.dialogueId,
    required this.startNode,
    required this.document,
    required Iterable<DialogueAuthoringDiagnostic> diagnostics,
    required Iterable<String> emittedOutcomes,
  })  : diagnostics = List.unmodifiable(diagnostics),
        emittedOutcomes = List.unmodifiable(emittedOutcomes);

  final String dialogueId;
  final String? startNode;
  final RuntimeDialogueDocument? document;
  final List<DialogueAuthoringDiagnostic> diagnostics;
  final List<String> emittedOutcomes;

  bool get canPublish =>
      document != null &&
      diagnostics.every(
        (diagnostic) =>
            diagnostic.severity != NarrativeAuthoringDiagnosticSeverity.error,
      );

  Map<String, Object?> toJson() => {
        'dialogueId': dialogueId,
        if (startNode != null) 'startNode': startNode,
        'canPublish': canPublish,
        if (document != null) 'document': document!.toJson(),
        'emittedOutcomes': emittedOutcomes,
        'diagnostics': [for (final item in diagnostics) item.toJson()],
      };
}

/// Strict authoring wrapper around the runtime Yarn subset compiler.
///
/// The runtime compiler intentionally ignores unsupported commands for legacy
/// tolerance. Authoring cannot do that safely, so every unknown command is a
/// blocking diagnostic with a source line before the runtime compiler runs.
final class DialogueAuthoringCompiler {
  const DialogueAuthoringCompiler({
    this.runtimeCompiler = const YarnDialogueCompiler(),
  });

  final YarnDialogueCompiler runtimeCompiler;

  DialogueAuthoringCompileResult compile({
    required ProjectDialogueEntry entry,
    required String source,
  }) {
    final diagnostics = <DialogueAuthoringDiagnostic>[];
    final lines = source.split('\n');
    final commandPattern = RegExp(r'<<\s*([^\s>]+)');
    for (var index = 0; index < lines.length; index++) {
      for (final match in commandPattern.allMatches(lines[index])) {
        final command = match.group(1) ?? '';
        if (!const {'jump', 'outcome'}.contains(command)) {
          diagnostics.add(
            DialogueAuthoringDiagnostic(
              code: 'yarn.command_unknown',
              severity: NarrativeAuthoringDiagnosticSeverity.error,
              message: 'The Yarn command is not supported by PokeMap runtime.',
              line: index + 1,
            ),
          );
        }
      }
    }

    RuntimeDialogueDocument? document;
    try {
      document = runtimeCompiler.compile(source);
    } on FormatException catch (error) {
      diagnostics.add(
        DialogueAuthoringDiagnostic(
          code: 'yarn.compile_failed',
          severity: NarrativeAuthoringDiagnosticSeverity.error,
          message: error.message.toString(),
        ),
      );
    }
    final outcomes = document == null ? <String>[] : _outcomes(document);
    final declared = {for (final item in entry.declaredOutcomes) item.id};
    for (final outcome in outcomes) {
      if (!declared.contains(outcome)) {
        diagnostics.add(
          DialogueAuthoringDiagnostic(
            code: 'dialogue.outcome_undeclared',
            severity: NarrativeAuthoringDiagnosticSeverity.error,
            message: 'Declare the emitted outcome "$outcome" first.',
            path: '/dialogues/${entry.id}/declaredOutcomes',
          ),
        );
      }
    }
    for (final outcome in declared.toList()..sort()) {
      if (!outcomes.contains(outcome)) {
        diagnostics.add(
          DialogueAuthoringDiagnostic(
            code: 'dialogue.outcome_unused',
            severity: NarrativeAuthoringDiagnosticSeverity.warning,
            message: 'The declared outcome "$outcome" is never emitted.',
            path: '/dialogues/${entry.id}/declaredOutcomes/$outcome',
          ),
        );
      }
    }
    final start = entry.defaultStartNode;
    if (document != null &&
        start != null &&
        !document.nodes.any((node) => node.title == start)) {
      diagnostics.add(
        DialogueAuthoringDiagnostic(
          code: 'dialogue.start_node_missing',
          severity: NarrativeAuthoringDiagnosticSeverity.error,
          message: 'The default start node does not exist in the Yarn source.',
          path: '/dialogues/${entry.id}/defaultStartNode',
        ),
      );
    }
    diagnostics.sort((left, right) {
      final line = (left.line ?? (1 << 30)).compareTo(
        right.line ?? (1 << 30),
      );
      if (line != 0) return line;
      final path = (left.path ?? '').compareTo(right.path ?? '');
      return path != 0 ? path : left.code.compareTo(right.code);
    });
    return DialogueAuthoringCompileResult(
      dialogueId: entry.id,
      startNode: entry.defaultStartNode,
      document: document,
      diagnostics: diagnostics,
      emittedOutcomes: outcomes,
    );
  }
}

final class DialogueSimulationTrace {
  DialogueSimulationTrace({
    required Iterable<String> transcript,
    required Iterable<String> selectedChoices,
    required Iterable<String> outcomes,
    required Iterable<String> visitedNodes,
    required this.terminated,
    required this.truncated,
  })  : transcript = List.unmodifiable(transcript),
        selectedChoices = List.unmodifiable(selectedChoices),
        outcomes = List.unmodifiable(outcomes),
        visitedNodes = List.unmodifiable(visitedNodes);

  final List<String> transcript;
  final List<String> selectedChoices;
  final List<String> outcomes;
  final List<String> visitedNodes;
  final bool terminated;
  final bool truncated;

  Map<String, Object?> toJson() => {
        'transcript': transcript,
        'selectedChoices': selectedChoices,
        'outcomes': outcomes,
        'visitedNodes': visitedNodes,
        'terminated': terminated,
        'truncated': truncated,
      };
}

final class DialogueSimulationService {
  const DialogueSimulationService();

  DialogueSimulationTrace simulate(
    DialogueAuthoringCompileResult compiled, {
    Map<String, int> choices = const {},
    int maximumSteps = 256,
  }) {
    if (!compiled.canPublish || compiled.document == null) {
      throw ArgumentError.value(compiled, 'compiled', 'must be publishable');
    }
    if (maximumSteps <= 0) {
      throw ArgumentError.value(
          maximumSteps, 'maximumSteps', 'must be positive');
    }
    final document = compiled.document!;
    final nodes = {for (final node in document.nodes) node.title: node};
    var current = compiled.startNode == null
        ? document.nodes.first
        : nodes[compiled.startNode]!;
    var pending = List<RuntimeDialogueStep>.from(current.steps);
    final transcript = <String>[];
    final selected = <String>[];
    final outcomes = <String>[];
    final visited = <String>[current.title];
    var operations = 0;
    var truncated = false;
    while (pending.isNotEmpty) {
      if (operations++ >= maximumSteps) {
        truncated = true;
        break;
      }
      final step = pending.removeAt(0);
      switch (step) {
        case RuntimeDialogueLine():
          transcript.add(step.text);
        case RuntimeDialogueJump():
          current = nodes[step.targetNode]!;
          visited.add(current.title);
          pending = List<RuntimeDialogueStep>.from(current.steps);
        case RuntimeDialogueChoiceBlock():
          final choiceIndex = choices[current.title] ?? 0;
          if (choiceIndex < 0 || choiceIndex >= step.choices.length) {
            throw ArgumentError.value(
              choiceIndex,
              'choices[${current.title}]',
              'must identify an available choice',
            );
          }
          final choice = step.choices[choiceIndex];
          selected.add(choice.text);
          if (choice.outcomeId != null) outcomes.add(choice.outcomeId!);
          pending.insertAll(0, choice.steps);
      }
    }
    return DialogueSimulationTrace(
      transcript: transcript,
      selectedChoices: selected,
      outcomes: outcomes,
      visitedNodes: visited,
      terminated: !truncated && pending.isEmpty,
      truncated: truncated,
    );
  }
}

final class DialogueLegacyMigrationPreview {
  DialogueLegacyMigrationPreview({
    required this.dialogueId,
    required this.sourcePath,
    required this.targetPath,
    required this.sourcePreservedVerbatim,
    required this.generatedYarn,
    required Iterable<DialogueAuthoringDiagnostic> diagnostics,
  }) : diagnostics = List.unmodifiable(diagnostics);

  final String dialogueId;
  final String sourcePath;
  final String targetPath;
  final String sourcePreservedVerbatim;
  final String generatedYarn;
  final List<DialogueAuthoringDiagnostic> diagnostics;

  Map<String, Object?> toJson() => {
        'dialogueId': dialogueId,
        'sourcePath': sourcePath,
        'targetPath': targetPath,
        'sourcePreserved': true,
        'generatedYarn': generatedYarn,
        'diagnostics': [for (final item in diagnostics) item.toJson()],
      };
}

final class DialogueLegacyMigrationService {
  const DialogueLegacyMigrationService();

  DialogueLegacyMigrationPreview preview({
    required ProjectDialogueEntry entry,
    required String source,
  }) {
    if (entry.relativePath.toLowerCase().endsWith('.yarn')) {
      throw ArgumentError.value(entry.relativePath, 'entry', 'is already Yarn');
    }
    final diagnostics = <DialogueAuthoringDiagnostic>[];
    final converted = <String>[];
    final lines = source.split('\n');
    for (var index = 0; index < lines.length; index++) {
      var line = lines[index];
      if (line.contains('<<') || line.contains('>>')) {
        line = line.replaceAll('<<', '‹‹').replaceAll('>>', '››');
        diagnostics.add(
          DialogueAuthoringDiagnostic(
            code: 'legacy.command_escaped',
            severity: NarrativeAuthoringDiagnosticSeverity.warning,
            message: 'A legacy command-like token was escaped as visible text.',
            line: index + 1,
          ),
        );
      }
      if (line.trim().isNotEmpty) converted.add(line);
    }
    if (converted.isEmpty) converted.add('(Dialogue vide)');
    final lastDot = entry.relativePath.lastIndexOf('.');
    final basePath = lastDot > entry.relativePath.lastIndexOf('/')
        ? entry.relativePath.substring(0, lastDot)
        : entry.relativePath;
    final title = entry.defaultStartNode?.trim().isNotEmpty ?? false
        ? entry.defaultStartNode!.trim()
        : entry.id;
    final generated = 'title: $title\n---\n${converted.join('\n')}\n===\n';
    return DialogueLegacyMigrationPreview(
      dialogueId: entry.id,
      sourcePath: entry.relativePath,
      targetPath: '$basePath.yarn',
      sourcePreservedVerbatim: source,
      generatedYarn: generated,
      diagnostics: diagnostics,
    );
  }
}

List<String> _outcomes(RuntimeDialogueDocument document) {
  final result = <String>{};
  void visit(List<RuntimeDialogueStep> steps) {
    for (final step in steps) {
      if (step is RuntimeDialogueChoiceBlock) {
        for (final choice in step.choices) {
          if (choice.outcomeId != null) result.add(choice.outcomeId!);
          visit(choice.steps);
        }
      }
    }
  }

  for (final node in document.nodes) {
    visit(node.steps);
  }
  return List.unmodifiable(result.toList()..sort());
}
```

## `packages/map_authoring/lib/src/domains/narrative/dialogue_source_store.dart`

```dart
String dialogueSourceResourceIdentity(String dialogueId) =>
    'dialogueSource:$dialogueId';

/// The manifest remains the sole authority for dialogue source storage keys.
/// This helper only centralizes path-free snapshot identities.
String dialogueSourceStorageKey(String relativePath) => relativePath;
```

## `packages/map_authoring/lib/src/domains/narrative/narrative_authoring_exception.dart`

```dart
import '../../contracts/json_contract_support.dart';

final class NarrativeAuthoringException implements Exception {
  NarrativeAuthoringException(
    this.code,
    this.message, {
    Map<String, Object?> details = const {},
  }) : details = freezeContractJsonObject(details, field: 'details');

  final String code;
  final String message;
  final Map<String, Object?> details;

  @override
  String toString() => 'NarrativeAuthoringException($code): $message';
}
```

## `packages/map_authoring/lib/src/domains/narrative/script_actions.dart`

```dart
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
```

## `packages/map_authoring/lib/src/domains/narrative/script_authoring_service.dart`

```dart
import 'package:map_core/map_core.dart';

import 'dialogue_authoring_service.dart';

final class ScriptAuthoringDiagnostic {
  const ScriptAuthoringDiagnostic({
    required this.code,
    required this.message,
    required this.path,
    this.severity = NarrativeAuthoringDiagnosticSeverity.error,
  });

  final String code;
  final String message;
  final String path;
  final NarrativeAuthoringDiagnosticSeverity severity;

  Map<String, Object?> toJson() => {
        'code': code,
        'message': message,
        'path': path,
        'severity': severity.name,
      };
}

final class ScriptEffectPreview {
  ScriptEffectPreview({
    required this.nodeId,
    required this.commandIndex,
    required this.type,
    required Map<String, String> parameters,
  }) : parameters = Map.unmodifiable(parameters);

  final String nodeId;
  final int commandIndex;
  final ScriptCommandType type;
  final Map<String, String> parameters;

  Map<String, Object?> toJson() => {
        'nodeId': nodeId,
        'commandIndex': commandIndex,
        'type': type.name,
        'parameters': parameters,
      };
}

final class ScriptSimulationTrace {
  ScriptSimulationTrace({
    required Iterable<ScriptAuthoringDiagnostic> diagnostics,
    required Iterable<String> visitedNodes,
    required Iterable<ScriptEffectPreview> effects,
    required this.terminated,
    required this.truncated,
  })  : diagnostics = List.unmodifiable(diagnostics),
        visitedNodes = List.unmodifiable(visitedNodes),
        effects = List.unmodifiable(effects);

  final List<ScriptAuthoringDiagnostic> diagnostics;
  final List<String> visitedNodes;
  final List<ScriptEffectPreview> effects;
  final bool terminated;
  final bool truncated;

  bool get canRun => diagnostics.every(
        (item) => item.severity != NarrativeAuthoringDiagnosticSeverity.error,
      );

  Map<String, Object?> toJson() => {
        'canRun': canRun,
        'visitedNodes': visitedNodes,
        'effects': [for (final effect in effects) effect.toJson()],
        'terminated': terminated,
        'truncated': truncated,
        'diagnostics': [for (final item in diagnostics) item.toJson()],
      };
}

/// Pure dry simulation: effects are described, never sent to runtime ports.
final class ScriptAuthoringSimulator {
  const ScriptAuthoringSimulator();

  List<ScriptAuthoringDiagnostic> validate(ScriptAsset script) {
    final diagnostics = <ScriptAuthoringDiagnostic>[];
    final nodes = <String, ScriptNode>{};
    for (var nodeIndex = 0; nodeIndex < script.nodes.length; nodeIndex++) {
      final node = script.nodes[nodeIndex];
      if (node.id.trim().isEmpty || nodes.containsKey(node.id)) {
        diagnostics.add(
          ScriptAuthoringDiagnostic(
            code: node.id.trim().isEmpty
                ? 'script.node_id_required'
                : 'script.node_id_duplicate',
            message: 'Script node identities must be nonblank and unique.',
            path: '/nodes/$nodeIndex/id',
          ),
        );
      } else {
        nodes[node.id] = node;
      }
    }
    if (!nodes.containsKey(script.defaultStartNode)) {
      diagnostics.add(
        const ScriptAuthoringDiagnostic(
          code: 'script.start_node_missing',
          message: 'The default start node does not exist.',
          path: '/defaultStartNode',
        ),
      );
    }
    for (var nodeIndex = 0; nodeIndex < script.nodes.length; nodeIndex++) {
      final node = script.nodes[nodeIndex];
      if (node.nextNodeId != null && !nodes.containsKey(node.nextNodeId)) {
        diagnostics.add(
          ScriptAuthoringDiagnostic(
            code: 'script.next_node_missing',
            message: 'The next node does not exist.',
            path: '/nodes/$nodeIndex/nextNodeId',
          ),
        );
      }
      for (var commandIndex = 0;
          commandIndex < node.commands.length;
          commandIndex++) {
        final command = node.commands[commandIndex];
        final path = '/nodes/$nodeIndex/commands/$commandIndex';
        final required = _requiredParameters[command.type] ?? const <String>[];
        for (final key in required) {
          if (command.params[key]?.trim().isEmpty ?? true) {
            diagnostics.add(
              ScriptAuthoringDiagnostic(
                code: 'script.parameter_required',
                message: 'The "$key" parameter is required.',
                path: '$path/params/$key',
              ),
            );
          }
        }
        if (command.type == ScriptCommandType.goto) {
          final target = command.params['nodeId'];
          if (target != null &&
              target.isNotEmpty &&
              !nodes.containsKey(target)) {
            diagnostics.add(
              ScriptAuthoringDiagnostic(
                code: 'script.goto_target_missing',
                message: 'The goto target does not exist.',
                path: '$path/params/nodeId',
              ),
            );
          }
        }
        if (command.type == ScriptCommandType.giveItem) {
          final quantity = int.tryParse(command.params['quantity'] ?? '1');
          if (quantity == null || quantity <= 0) {
            diagnostics.add(
              ScriptAuthoringDiagnostic(
                code: 'script.quantity_invalid',
                message: 'Item quantity must be a positive integer.',
                path: '$path/params/quantity',
              ),
            );
          }
        }
      }
    }
    diagnostics.sort((left, right) {
      final path = left.path.compareTo(right.path);
      return path != 0 ? path : left.code.compareTo(right.code);
    });
    return List.unmodifiable(diagnostics);
  }

  ScriptSimulationTrace simulate(
    ScriptAsset script, {
    int maximumNodeVisits = 128,
  }) {
    if (maximumNodeVisits <= 0) {
      throw ArgumentError.value(
        maximumNodeVisits,
        'maximumNodeVisits',
        'must be positive',
      );
    }
    final diagnostics = validate(script);
    if (diagnostics.any((item) =>
        item.severity == NarrativeAuthoringDiagnosticSeverity.error)) {
      return ScriptSimulationTrace(
        diagnostics: diagnostics,
        visitedNodes: const [],
        effects: const [],
        terminated: false,
        truncated: false,
      );
    }
    final nodes = {for (final node in script.nodes) node.id: node};
    var current = nodes[script.defaultStartNode]!;
    final visited = <String>[];
    final effects = <ScriptEffectPreview>[];
    var terminated = false;
    var truncated = false;
    for (var visit = 0; visit < maximumNodeVisits; visit++) {
      visited.add(current.id);
      String? jump;
      for (var index = 0; index < current.commands.length; index++) {
        final command = current.commands[index];
        if (command.type == ScriptCommandType.goto) {
          jump = command.params['nodeId'];
          break;
        }
        if (command.type == ScriptCommandType.end) {
          terminated = true;
          break;
        }
        effects.add(
          ScriptEffectPreview(
            nodeId: current.id,
            commandIndex: index,
            type: command.type,
            parameters: command.params,
          ),
        );
      }
      if (terminated) break;
      final next = jump ?? current.nextNodeId;
      if (next == null) {
        terminated = true;
        break;
      }
      current = nodes[next]!;
      if (visit == maximumNodeVisits - 1) truncated = true;
    }
    return ScriptSimulationTrace(
      diagnostics: diagnostics,
      visitedNodes: visited,
      effects: effects,
      terminated: terminated,
      truncated: truncated,
    );
  }
}

const Map<ScriptCommandType, List<String>> _requiredParameters = {
  ScriptCommandType.goto: ['nodeId'],
  ScriptCommandType.setFlag: ['flagName'],
  ScriptCommandType.clearFlag: ['flagName'],
  ScriptCommandType.setVariable: ['variableName', 'value'],
  ScriptCommandType.incrementVariable: ['variableName'],
  ScriptCommandType.openDialogue: ['filePath'],
  ScriptCommandType.warpPlayer: ['mapId'],
  ScriptCommandType.giveItem: ['itemId'],
  ScriptCommandType.unlockFieldAbility: ['ability'],
  ScriptCommandType.markEventConsumed: ['eventId'],
};
```

## `packages/map_authoring/test/domains/narrative/dialogue_script_authoring_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('dialogue and script authoring', () {
    test('strict Yarn compilation reports unknown commands and line numbers',
        () {
      final result = const DialogueAuthoringCompiler().compile(
        entry: _dialogue(),
        source: 'title: Start\n---\nBonjour\n<<teleport town>>\n===\n',
      );

      expect(result.canPublish, isFalse);
      expect(
        result.diagnostics
            .where((item) => item.code == 'yarn.command_unknown')
            .single,
        isA<DialogueAuthoringDiagnostic>()
            .having((value) => value.code, 'code', 'yarn.command_unknown')
            .having((value) => value.line, 'line', 4),
      );
    });

    test(
        'dialogue simulation exposes choices and outcomes without side effects',
        () {
      const source = '''
title: Start
---
Bonjour
-> Accepter
  <<outcome accepted>>
  Merci
-> Refuser
  <<outcome refused>>
  Au revoir
===
''';
      final compiled = const DialogueAuthoringCompiler().compile(
        entry: _dialogue(),
        source: source,
      );
      final trace = const DialogueSimulationService().simulate(
        compiled,
        choices: const {'Start': 1},
      );

      expect(compiled.canPublish, isTrue);
      expect(trace.transcript, ['Bonjour', 'Au revoir']);
      expect(trace.selectedChoices, ['Refuser']);
      expect(trace.outcomes, ['refused']);
      expect(trace.terminated, isTrue);
    });

    test('outcome removal is blocked while a Scene still consumes it', () {
      final manifest = _manifest(
        scenes: [_dialogueScene(outcomeId: 'accepted')],
      );
      final replacement = _dialogue().copyWith(
        declaredOutcomes: const [
          DialogueDeclaredOutcome(id: 'refused', label: 'Refuser'),
        ],
      );

      expect(
        () => const DialogueActions().update(
          manifest,
          entry: replacement,
        ),
        throwsA(
          isA<NarrativeAuthoringException>().having(
            (error) => error.code,
            'code',
            'dialogue.outcome_references_blocking',
          ),
        ),
      );
    });

    test('legacy migration keeps identity and an exact readable source', () {
      const legacy = 'Bonjour, dresseur !\n<<ancienne_commande>>\nAu revoir.';
      final preview = const DialogueLegacyMigrationService().preview(
        entry: ProjectDialogueEntry(
          id: 'intro',
          name: 'Intro',
          relativePath: 'dialogues/intro.txt',
        ),
        source: legacy,
      );

      expect(preview.dialogueId, 'intro');
      expect(preview.sourcePreservedVerbatim, legacy);
      expect(preview.targetPath, 'dialogues/intro.yarn');
      expect(preview.generatedYarn, contains('ancienne_commande'));
      expect(preview.diagnostics.map((item) => item.code),
          contains('legacy.command_escaped'));
    });

    test('script simulation previews effects and never executes them', () {
      const script = ScriptAsset(
        id: 'reward',
        nodes: [
          ScriptNode(
            id: 'start',
            commands: [
              ScriptCommand(
                type: ScriptCommandType.giveItem,
                params: {'itemId': 'potion', 'quantity': '2'},
              ),
              ScriptCommand(type: ScriptCommandType.end),
            ],
          ),
        ],
      );

      final trace = const ScriptAuthoringSimulator().simulate(script);

      expect(trace.canRun, isTrue);
      expect(trace.effects, hasLength(1));
      expect(trace.effects.single.type, ScriptCommandType.giveItem);
      expect(trace.effects.single.parameters['quantity'], '2');
      expect(trace.terminated, isTrue);
    });

    test('generic dispatcher exposes dialogue and script lifecycle actions',
        () {
      final ids = AuthoringMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();

      expect(
        ids,
        containsAll({
          'dialogue.create',
          'dialogue.update',
          'dialogue.source_update',
          'dialogue.delete',
          'dialogue.migrate_legacy',
          'script.upsert',
          'script.delete',
        }),
      );
      expect(MapMutationDispatcher.canonical().descriptors.length, ids.length);
    });

    test('source update plan/apply/undo restores exact Yarn bytes', () async {
      final directory = await Directory.systemTemp.createTemp(
        'pokemap_dialogue_transaction_',
      );
      addTearDown(() => directory.delete(recursive: true));
      await Directory('${directory.path}/dialogues').create();
      final original = utf8.encode(
        'title: Start\n---\nAncienne ligne\n-> Accepter\n'
        '  <<outcome accepted>>\n-> Refuser\n'
        '  <<outcome refused>>\n===\n',
      );
      final sourceFile = File('${directory.path}/dialogues/intro.yarn');
      await sourceFile.writeAsBytes(original);
      await File('${directory.path}/project.json').writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(_manifest().toJson())}\n',
      );
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: [directory.path],
        fileReader: reader,
      );
      final handles = WorkspaceHandleStore();
      final opened = await ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ).openProject(directory.path);
      final loader = ProjectSnapshotLoader(handles: handles);
      final api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: loader,
        clock: () => DateTime.utc(2026, 7, 31, 12),
      );
      await api.attachProject(
        projectRootPath: directory.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      final baseSnapshot = await loader.load(opened.projectHandle);
      final baseRevision = baseSnapshot.revision;
      final read = const ProjectQueryService().query(
        baseSnapshot,
        AuthoringQueryRequest(
          resourceKind: 'dialogue',
          operation: AuthoringQueryOperation.get,
          view: AuthoringQueryView.detail,
          ids: ['intro'],
        ),
      );
      expect(
        (read.items.single['source']! as Map)['text'],
        utf8.decode(original),
      );
      expect((read.items.single['compile']! as Map)['canPublish'], isTrue);
      const updated = 'title: Start\n---\nNouvelle ligne\n'
          '-> Accepter\n  <<outcome accepted>>\n'
          '-> Refuser\n  <<outcome refused>>\n===\n';

      final plan = await api.plan(
        opened.projectHandle,
        AuthoringRequest(
          requestId: 'req-dialogue-source-update',
          actionId: 'dialogue.source_update',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: const {'dialogueId': 'intro', 'source': updated},
          expectedRevision: baseRevision,
          idempotencyKey: 'idem-dialogue-source-update',
        ),
      );
      final applied = await api.apply(
        opened.projectHandle,
        planId: plan['planId']! as String,
        operationId: 'op-dialogue-source-update',
      );
      expect(await sourceFile.readAsString(), updated);
      final receipt = Map<String, Object?>.from(applied['receipt']! as Map);

      await api.undo(
        opened.projectHandle,
        entryId: receipt['receiptId']! as String,
        idempotencyKey: 'idem-dialogue-source-update-undo',
      );
      expect(await sourceFile.readAsBytes(), original);
    });
  });
}

ProjectDialogueEntry _dialogue() => const ProjectDialogueEntry(
      id: 'intro',
      name: 'Intro',
      relativePath: 'dialogues/intro.yarn',
      defaultStartNode: 'Start',
      declaredOutcomes: [
        DialogueDeclaredOutcome(id: 'accepted', label: 'Accepter'),
        DialogueDeclaredOutcome(id: 'refused', label: 'Refuser'),
      ],
    );

ProjectManifest _manifest({List<SceneAsset> scenes = const []}) =>
    ProjectManifest(
      name: 'Narrative fixture',
      maps: const [],
      tilesets: const [],
      dialogues: [_dialogue()],
      scenes: scenes,
    );

SceneAsset _dialogueScene({required String outcomeId}) => SceneAsset(
      id: 'intro_scene',
      name: 'Intro scene',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'dialogue',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(
              dialogueId: 'intro',
              expectedOutcomes: [outcomeId],
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'start_dialogue',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'dialogue',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'dialogue_outcome',
            fromNodeId: 'dialogue',
            fromPortId: outcomeId,
            toNodeId: 'end',
            kind: SceneEdgeKind.dialogueOutcome,
          ),
        ],
      ),
    );
```
