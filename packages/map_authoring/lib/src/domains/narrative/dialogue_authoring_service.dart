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
