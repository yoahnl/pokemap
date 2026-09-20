part of 'dialogue_workspace_controller.dart';

extension DialogueWorkspaceValidation on DialogueWorkspaceController {
  DialogueAuthoringCompileResult _compileDocument(
    DialogueWorkingState state, {
    String? startNode,
  }) {
    final result = _compile(
      state.entry.copyWith(
        defaultStartNode: startNode ?? state.entry.defaultStartNode,
      ),
      state.source,
    );
    final issues = validateDialogueDocument(
      state.document,
      declaredOutcomeIds: state.entry.declaredOutcomes.map((o) => o.id),
      project: project,
    );
    return DialogueAuthoringCompileResult(
      dialogueId: result.dialogueId,
      startNode: result.startNode,
      document: result.document,
      emittedOutcomes: result.emittedOutcomes,
      diagnostics: [
        ...result.diagnostics,
        for (final issue in issues)
          if (issue.severity == DialogueValidationSeverity.error)
            DialogueAuthoringDiagnostic(
              code: 'dialogue.structure_invalid',
              severity: NarrativeAuthoringDiagnosticSeverity.error,
              message: issue.message,
              path: issue.stepId,
            ),
      ],
    );
  }
}

String? _opaqueSourceProblem(String source) {
  var body = false, header = false;
  for (final line in source.split('\n')) {
    final text = line.trim();
    if (body) {
      if (text == '===') {
        body = false;
        header = false;
      }
      continue;
    }
    if (text.isEmpty) continue;
    if (text.startsWith('title:')) {
      header = true;
      continue;
    }
    if (header && text == '---') {
      body = true;
      continue;
    }
    if (header && RegExp(r'^[^:]+:').hasMatch(text)) continue;
    return 'Cette source contient des fragments hors des suites que l’éditeur ne peut pas conserver après modification. Consultation Yarn protégée.';
  }
  return null;
}
