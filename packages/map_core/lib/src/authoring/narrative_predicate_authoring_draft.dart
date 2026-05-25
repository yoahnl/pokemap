import 'package:meta/meta.dart' show immutable;

import '../models/map_entity_payloads.dart';
import '../read_models/narrative_reference_picker_read_models.dart';

const String _scenarioOutcomePrefix = 'scenario.outcome.';
const String _battleOutcomePrefix = 'battle:';

enum NarrativePredicateAuthoringKind {
  storyFlagSet,
  stepCompleted,
  cutsceneCompleted,
  chapterCompleted,
}

enum NarrativeVisibilityRuleAuthoringMode {
  always,
  visibleWhen,
  hiddenWhen,
}

enum NarrativePredicateAuthoringDiagnosticSeverity {
  error,
  warning,
}

enum NarrativePredicateAuthoringDiagnosticKind {
  emptyReferenceId,
  emptyDialogueId,
  missingPredicate,
  unsupportedPredicateKind,
  unsupportedVisibilityRuleMode,
  scenarioOutcomeBattleOutcomeConfusion,
}

@immutable
final class NarrativePredicateAuthoringDraft {
  const NarrativePredicateAuthoringDraft({
    required this.kind,
    required this.refId,
  });

  final NarrativePredicateAuthoringKind kind;
  final String refId;
}

@immutable
final class NarrativeVisibilityRuleAuthoringDraft {
  const NarrativeVisibilityRuleAuthoringDraft.always()
      : mode = NarrativeVisibilityRuleAuthoringMode.always,
        predicate = null;

  const NarrativeVisibilityRuleAuthoringDraft.visibleWhen({
    this.predicate,
  }) : mode = NarrativeVisibilityRuleAuthoringMode.visibleWhen;

  const NarrativeVisibilityRuleAuthoringDraft.hiddenWhen({
    this.predicate,
  }) : mode = NarrativeVisibilityRuleAuthoringMode.hiddenWhen;

  final NarrativeVisibilityRuleAuthoringMode mode;
  final NarrativePredicateAuthoringDraft? predicate;
}

@immutable
final class NarrativeConditionalDialogueAuthoringDraft {
  const NarrativeConditionalDialogueAuthoringDraft({
    required this.dialogueId,
    this.predicate,
    this.scriptPathRelative = '',
    this.startNode,
  });

  final String dialogueId;
  final NarrativePredicateAuthoringDraft? predicate;
  final String scriptPathRelative;
  final String? startNode;
}

@immutable
final class NarrativePredicateAuthoringDiagnostic {
  const NarrativePredicateAuthoringDiagnostic({
    required this.severity,
    required this.kind,
    required this.message,
    required this.path,
    this.referencedId,
  });

  final NarrativePredicateAuthoringDiagnosticSeverity severity;
  final NarrativePredicateAuthoringDiagnosticKind kind;
  final String message;
  final String path;
  final String? referencedId;
}

NarrativePredicateAuthoringDraft
    createNarrativePredicateAuthoringDraftFromReferenceOption(
  NarrativePredicateReferencePickerOption option,
) {
  final referenceId = option.referenceId.trim();
  return NarrativePredicateAuthoringDraft(
    kind: switch (option.referenceKind) {
      NarrativePredicateReferenceKind.storyFlag =>
        NarrativePredicateAuthoringKind.storyFlagSet,
      NarrativePredicateReferenceKind.storyStep =>
        NarrativePredicateAuthoringKind.stepCompleted,
      NarrativePredicateReferenceKind.cutscene =>
        NarrativePredicateAuthoringKind.cutsceneCompleted,
      NarrativePredicateReferenceKind.scenarioOutcome =>
        NarrativePredicateAuthoringKind.storyFlagSet,
      NarrativePredicateReferenceKind.battleOutcome =>
        NarrativePredicateAuthoringKind.storyFlagSet,
    },
    refId: referenceId,
  );
}

MapEntityRuntimePredicate
    compileNarrativePredicateAuthoringDraftToRuntimePredicate(
  NarrativePredicateAuthoringDraft draft,
) {
  _throwIfInvalid(validateNarrativePredicateAuthoringDraft(draft));
  return MapEntityRuntimePredicate(
    kind: _runtimePredicateKindForAuthoringKind(draft.kind),
    refId: draft.refId.trim(),
  );
}

MapEntityNpcVisibilityRule
    compileNarrativeVisibilityRuleAuthoringDraftToNpcVisibilityRule(
  NarrativeVisibilityRuleAuthoringDraft draft,
) {
  _throwIfInvalid(validateNarrativeVisibilityRuleAuthoringDraft(draft));
  return switch (draft.mode) {
    NarrativeVisibilityRuleAuthoringMode.always =>
      const MapEntityNpcVisibilityRule(mode: MapEntityNpcVisibilityMode.always),
    NarrativeVisibilityRuleAuthoringMode.visibleWhen =>
      MapEntityNpcVisibilityRule(
        mode: MapEntityNpcVisibilityMode.visibleWhen,
        predicate: compileNarrativePredicateAuthoringDraftToRuntimePredicate(
          draft.predicate!,
        ),
      ),
    NarrativeVisibilityRuleAuthoringMode.hiddenWhen =>
      MapEntityNpcVisibilityRule(
        mode: MapEntityNpcVisibilityMode.hiddenWhen,
        predicate: compileNarrativePredicateAuthoringDraftToRuntimePredicate(
          draft.predicate!,
        ),
      ),
  };
}

MapEntityConditionalDialogue
    compileNarrativeConditionalDialogueAuthoringDraftToConditionalDialogue(
  NarrativeConditionalDialogueAuthoringDraft draft,
) {
  _throwIfInvalid(validateNarrativeConditionalDialogueAuthoringDraft(draft));
  return MapEntityConditionalDialogue(
    when: compileNarrativePredicateAuthoringDraftToRuntimePredicate(
      draft.predicate!,
    ),
    dialogue: DialogueRef(
      dialogueId: draft.dialogueId.trim(),
      scriptPathRelative: draft.scriptPathRelative.trim(),
      startNode: _trimOptional(draft.startNode),
    ),
  );
}

List<NarrativePredicateAuthoringDiagnostic>
    validateNarrativePredicateAuthoringDraft(
  NarrativePredicateAuthoringDraft draft,
) {
  final diagnostics = <NarrativePredicateAuthoringDiagnostic>[];
  final refId = draft.refId.trim();

  if (refId.isEmpty) {
    _addDiagnostic(
      diagnostics,
      kind: NarrativePredicateAuthoringDiagnosticKind.emptyReferenceId,
      message: 'Predicate reference id is required.',
      path: 'refId',
    );
  } else if (draft.kind != NarrativePredicateAuthoringKind.storyFlagSet &&
      _isTechnicalFlagReference(refId)) {
    _addDiagnostic(
      diagnostics,
      kind: NarrativePredicateAuthoringDiagnosticKind
          .scenarioOutcomeBattleOutcomeConfusion,
      message:
          'Scenario outcome and battle outcome references must stay technical '
          'story flag predicates.',
      path: 'refId',
      referencedId: refId,
    );
  }

  return List<NarrativePredicateAuthoringDiagnostic>.unmodifiable(diagnostics);
}

List<NarrativePredicateAuthoringDiagnostic>
    validateNarrativeVisibilityRuleAuthoringDraft(
  NarrativeVisibilityRuleAuthoringDraft draft,
) {
  final diagnostics = <NarrativePredicateAuthoringDiagnostic>[];
  switch (draft.mode) {
    case NarrativeVisibilityRuleAuthoringMode.always:
      break;
    case NarrativeVisibilityRuleAuthoringMode.visibleWhen:
    case NarrativeVisibilityRuleAuthoringMode.hiddenWhen:
      final predicate = draft.predicate;
      if (predicate == null) {
        _addDiagnostic(
          diagnostics,
          kind: NarrativePredicateAuthoringDiagnosticKind.missingPredicate,
          message: 'Conditional visibility requires a predicate.',
          path: 'predicate',
        );
      } else {
        diagnostics.addAll(validateNarrativePredicateAuthoringDraft(predicate));
      }
  }

  return List<NarrativePredicateAuthoringDiagnostic>.unmodifiable(diagnostics);
}

List<NarrativePredicateAuthoringDiagnostic>
    validateNarrativeConditionalDialogueAuthoringDraft(
  NarrativeConditionalDialogueAuthoringDraft draft,
) {
  final diagnostics = <NarrativePredicateAuthoringDiagnostic>[];
  if (draft.dialogueId.trim().isEmpty) {
    _addDiagnostic(
      diagnostics,
      kind: NarrativePredicateAuthoringDiagnosticKind.emptyDialogueId,
      message: 'Conditional dialogue id is required.',
      path: 'dialogueId',
    );
  }

  final predicate = draft.predicate;
  if (predicate == null) {
    _addDiagnostic(
      diagnostics,
      kind: NarrativePredicateAuthoringDiagnosticKind.missingPredicate,
      message: 'Conditional dialogue requires a predicate.',
      path: 'predicate',
    );
  } else {
    diagnostics.addAll(validateNarrativePredicateAuthoringDraft(predicate));
  }

  return List<NarrativePredicateAuthoringDiagnostic>.unmodifiable(diagnostics);
}

MapEntityRuntimePredicateKind _runtimePredicateKindForAuthoringKind(
  NarrativePredicateAuthoringKind kind,
) {
  return switch (kind) {
    NarrativePredicateAuthoringKind.storyFlagSet =>
      MapEntityRuntimePredicateKind.storyFlagSet,
    NarrativePredicateAuthoringKind.stepCompleted =>
      MapEntityRuntimePredicateKind.stepCompleted,
    NarrativePredicateAuthoringKind.cutsceneCompleted =>
      MapEntityRuntimePredicateKind.cutsceneCompleted,
    NarrativePredicateAuthoringKind.chapterCompleted =>
      MapEntityRuntimePredicateKind.chapterCompleted,
  };
}

void _throwIfInvalid(
  List<NarrativePredicateAuthoringDiagnostic> diagnostics,
) {
  if (diagnostics.any(
    (diagnostic) =>
        diagnostic.severity ==
        NarrativePredicateAuthoringDiagnosticSeverity.error,
  )) {
    final summary = diagnostics
        .map((diagnostic) => '${diagnostic.kind.name}:${diagnostic.path}')
        .join(', ');
    throw StateError('Invalid narrative predicate authoring draft: $summary');
  }
}

void _addDiagnostic(
  List<NarrativePredicateAuthoringDiagnostic> diagnostics, {
  required NarrativePredicateAuthoringDiagnosticKind kind,
  required String message,
  required String path,
  NarrativePredicateAuthoringDiagnosticSeverity severity =
      NarrativePredicateAuthoringDiagnosticSeverity.error,
  String? referencedId,
}) {
  diagnostics.add(
    NarrativePredicateAuthoringDiagnostic(
      severity: severity,
      kind: kind,
      message: message,
      path: path,
      referencedId: referencedId,
    ),
  );
}

bool _isTechnicalFlagReference(String refId) =>
    refId.startsWith(_scenarioOutcomePrefix) ||
    refId.startsWith(_battleOutcomePrefix);

String? _trimOptional(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
