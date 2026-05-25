import 'package:meta/meta.dart' show immutable;

import '../read_models/narrative_reference_picker_read_models.dart';
import 'narrative_scenario_authoring_draft.dart';

const String _scenarioOutcomePrefix = 'scenario.outcome.';
const String _battleOutcomePrefix = 'battle:';

enum NarrativeOutcomeAuthoringDiagnosticSeverity {
  error,
  warning,
}

enum NarrativeOutcomeAuthoringDiagnosticKind {
  emptyOutcomeId,
  emptyBattleId,
  outcomeNotDeclared,
  declaredOutcomeNeverEmitted,
  battleOptionNotFound,
  missingTrainerReference,
  missingNpcEntityReference,
  scenarioOutcomeBattleOutcomeConfusion,
}

@immutable
final class NarrativeOutcomeAuthoringDiagnostic {
  const NarrativeOutcomeAuthoringDiagnostic({
    required this.severity,
    required this.kind,
    required this.message,
    required this.path,
    this.referencedId,
  });

  final NarrativeOutcomeAuthoringDiagnosticSeverity severity;
  final NarrativeOutcomeAuthoringDiagnosticKind kind;
  final String message;
  final String path;
  final String? referencedId;
}

NarrativeScenarioAuthoringDraft
    addDeclaredOutcomeToNarrativeScenarioAuthoringDraft(
  NarrativeScenarioAuthoringDraft draft,
  String outcomeId,
) {
  final trimmedOutcomeId = _requireRawScenarioOutcomeId(outcomeId);
  return _copyDraft(
    draft,
    declaredOutcomes: _dedupeTrimmed([
      ...draft.declaredOutcomes,
      trimmedOutcomeId,
    ]),
  );
}

NarrativeScenarioAuthoringDraft
    addEmitOutcomeActionToNarrativeScenarioAuthoringDraft(
  NarrativeScenarioAuthoringDraft draft,
  String outcomeId,
) {
  final trimmedOutcomeId = _requireRawScenarioOutcomeId(outcomeId);
  return _copyDraft(
    draft,
    actions: [
      ...draft.actions,
      NarrativeScenarioAuthoringActionDraft.emitOutcome(
        outcomeId: trimmedOutcomeId,
      ),
    ],
  );
}

NarrativeScenarioAuthoringSourceDraft
    createOutcomeReceivedSourceDraftFromNarrativeOutcomeOption(
  NarrativeOutcomePickerOption option,
) {
  return NarrativeScenarioAuthoringSourceDraft.outcomeReceived(
    outcomeId: _requireRawScenarioOutcomeId(option.outcomeId),
  );
}

NarrativeScenarioAuthoringDraft
    addStartTrainerBattleActionToNarrativeScenarioAuthoringDraft(
  NarrativeScenarioAuthoringDraft draft,
  NarrativeBattleReferencePickerOption battleOption, {
  String? npcEntityId,
}) {
  final battleId = _requireRawBattleId(battleOption.battleId);
  final trainerId = battleOption.trainerId.trim();
  if (trainerId.isEmpty) {
    throw ArgumentError.value(
      battleOption.trainerId,
      'battleOption.trainerId',
      'Trainer id is required.',
    );
  }

  return _copyDraft(
    draft,
    actions: [
      ...draft.actions,
      NarrativeScenarioAuthoringActionDraft.startTrainerBattle(
        trainerId: trainerId,
        battleId: battleId,
        npcEntityId: (npcEntityId ?? battleOption.npcEntityId).trim(),
      ),
    ],
  );
}

String narrativeScenarioOutcomeFlagReference(String outcomeId) {
  final trimmedOutcomeId = _requireRawScenarioOutcomeId(outcomeId);
  return '$_scenarioOutcomePrefix$trimmedOutcomeId';
}

String narrativeBattleOutcomeFlagReference(
  String battleId,
  NarrativeBattleOutcomeKind outcomeKind,
) {
  final trimmedBattleId = _requireRawBattleId(battleId);
  return '$_battleOutcomePrefix$trimmedBattleId:${outcomeKind.name}';
}

List<NarrativeOutcomeAuthoringDiagnostic>
    validateNarrativeOutcomeAuthoringDraft(
  NarrativeScenarioAuthoringDraft draft, {
  Iterable<NarrativeBattleReferencePickerOption> battleOptions = const [],
}) {
  final diagnostics = <NarrativeOutcomeAuthoringDiagnostic>[];
  final declaredOutcomeIds = <String>{};
  final emittedOutcomeIds = <String>{};

  for (final rawOutcomeId in draft.declaredOutcomes) {
    final outcomeId = rawOutcomeId.trim();
    if (outcomeId.isEmpty) {
      _addDiagnostic(
        diagnostics,
        kind: NarrativeOutcomeAuthoringDiagnosticKind.emptyOutcomeId,
        message: 'Declared outcome id is required.',
        path: 'declaredOutcomes',
      );
      continue;
    }
    _diagnoseScenarioOutcomeConfusion(
      diagnostics,
      outcomeId: outcomeId,
      path: 'declaredOutcomes',
    );
    declaredOutcomeIds.add(outcomeId);
  }

  final source = draft.source;
  if (source?.kind == NarrativeScenarioAuthoringSourceKind.outcomeReceived) {
    final outcomeId = source?.outcomeId.trim() ?? '';
    if (outcomeId.isEmpty) {
      _addDiagnostic(
        diagnostics,
        kind: NarrativeOutcomeAuthoringDiagnosticKind.emptyOutcomeId,
        message: 'Outcome received source requires an outcome id.',
        path: 'source.outcomeId',
      );
    } else {
      _diagnoseScenarioOutcomeConfusion(
        diagnostics,
        outcomeId: outcomeId,
        path: 'source.outcomeId',
      );
    }
  }

  for (var index = 0; index < draft.actions.length; index++) {
    final action = draft.actions[index];
    switch (action.kind) {
      case NarrativeScenarioAuthoringActionKind.emitOutcome:
        final outcomeId = action.outcomeId.trim();
        if (outcomeId.isEmpty) {
          _addDiagnostic(
            diagnostics,
            kind: NarrativeOutcomeAuthoringDiagnosticKind.emptyOutcomeId,
            message: 'Emitted outcome id is required.',
            path: 'actions[$index].outcomeId',
          );
          break;
        }
        _diagnoseScenarioOutcomeConfusion(
          diagnostics,
          outcomeId: outcomeId,
          path: 'actions[$index].outcomeId',
        );
        emittedOutcomeIds.add(outcomeId);
        if (!declaredOutcomeIds.contains(outcomeId)) {
          _addDiagnostic(
            diagnostics,
            severity: NarrativeOutcomeAuthoringDiagnosticSeverity.warning,
            kind: NarrativeOutcomeAuthoringDiagnosticKind.outcomeNotDeclared,
            message: 'Outcome "$outcomeId" is emitted but not declared.',
            path: 'actions[$index].outcomeId',
            referencedId: outcomeId,
          );
        }
      case NarrativeScenarioAuthoringActionKind.startTrainerBattle:
        _validateBattleAction(
          action,
          source: source,
          index: index,
          battleOptions: battleOptions,
          diagnostics: diagnostics,
        );
      case NarrativeScenarioAuthoringActionKind.setFlag:
      case NarrativeScenarioAuthoringActionKind.completeStep:
        break;
    }
  }

  for (final outcomeId in declaredOutcomeIds) {
    if (!emittedOutcomeIds.contains(outcomeId)) {
      _addDiagnostic(
        diagnostics,
        severity: NarrativeOutcomeAuthoringDiagnosticSeverity.warning,
        kind:
            NarrativeOutcomeAuthoringDiagnosticKind.declaredOutcomeNeverEmitted,
        message: 'Declared outcome "$outcomeId" is never emitted.',
        path: 'declaredOutcomes',
        referencedId: outcomeId,
      );
    }
  }

  return List<NarrativeOutcomeAuthoringDiagnostic>.unmodifiable(diagnostics);
}

NarrativeScenarioAuthoringDraft _copyDraft(
  NarrativeScenarioAuthoringDraft draft, {
  List<NarrativeScenarioAuthoringActionDraft>? actions,
  List<String>? declaredOutcomes,
}) {
  return NarrativeScenarioAuthoringDraft(
    scenarioId: draft.scenarioId,
    name: draft.name,
    description: draft.description,
    scope: draft.scope,
    source: draft.source,
    actions: actions ?? draft.actions,
    declaredOutcomes: declaredOutcomes ?? draft.declaredOutcomes,
    metadata: draft.metadata,
  );
}

void _validateBattleAction(
  NarrativeScenarioAuthoringActionDraft action, {
  required NarrativeScenarioAuthoringSourceDraft? source,
  required int index,
  required Iterable<NarrativeBattleReferencePickerOption> battleOptions,
  required List<NarrativeOutcomeAuthoringDiagnostic> diagnostics,
}) {
  final battleId = action.battleId.trim();
  final trainerId = action.trainerId.trim();
  final explicitNpcEntityId = action.npcEntityId.trim();
  final sourceNpcEntityId =
      source?.kind == NarrativeScenarioAuthoringSourceKind.entityInteract
          ? source?.entityId.trim() ?? ''
          : '';

  if (battleId.isEmpty) {
    _addDiagnostic(
      diagnostics,
      kind: NarrativeOutcomeAuthoringDiagnosticKind.emptyBattleId,
      message: 'Battle id is required.',
      path: 'actions[$index].battleId',
    );
  } else {
    _diagnoseBattleOutcomeConfusion(
      diagnostics,
      battleId: battleId,
      path: 'actions[$index].battleId',
    );
  }

  if (trainerId.isEmpty) {
    _addDiagnostic(
      diagnostics,
      kind: NarrativeOutcomeAuthoringDiagnosticKind.missingTrainerReference,
      message: 'Trainer id is required for startTrainerBattle.',
      path: 'actions[$index].trainerId',
    );
  }

  if (explicitNpcEntityId.isEmpty && sourceNpcEntityId.isEmpty) {
    _addDiagnostic(
      diagnostics,
      kind: NarrativeOutcomeAuthoringDiagnosticKind.missingNpcEntityReference,
      message: 'NPC entity id is required for startTrainerBattle.',
      path: 'actions[$index].npcEntityId',
    );
  }

  if (battleId.isEmpty || battleOptions.isEmpty) {
    return;
  }

  final optionFound = battleOptions.any((option) {
    final sameBattleId = option.battleId.trim() == battleId;
    final optionTrainerId = option.trainerId.trim();
    return sameBattleId && (trainerId.isEmpty || optionTrainerId == trainerId);
  });
  if (!optionFound) {
    _addDiagnostic(
      diagnostics,
      kind: NarrativeOutcomeAuthoringDiagnosticKind.battleOptionNotFound,
      message: 'No selectable battle option matches "$battleId".',
      path: 'actions[$index].battleId',
      referencedId: battleId,
    );
  }
}

void _diagnoseScenarioOutcomeConfusion(
  List<NarrativeOutcomeAuthoringDiagnostic> diagnostics, {
  required String outcomeId,
  required String path,
}) {
  if (!_looksLikeScenarioOrBattleFlag(outcomeId)) {
    return;
  }
  _addDiagnostic(
    diagnostics,
    kind: NarrativeOutcomeAuthoringDiagnosticKind
        .scenarioOutcomeBattleOutcomeConfusion,
    message:
        'Use a raw scenario outcome id here, not a scenario.outcome.* or battle:* flag.',
    path: path,
    referencedId: outcomeId,
  );
}

void _diagnoseBattleOutcomeConfusion(
  List<NarrativeOutcomeAuthoringDiagnostic> diagnostics, {
  required String battleId,
  required String path,
}) {
  if (!_looksLikeScenarioOrBattleFlag(battleId)) {
    return;
  }
  _addDiagnostic(
    diagnostics,
    kind: NarrativeOutcomeAuthoringDiagnosticKind
        .scenarioOutcomeBattleOutcomeConfusion,
    message:
        'Use a raw battle id here, not a scenario.outcome.* or battle:* flag.',
    path: path,
    referencedId: battleId,
  );
}

void _addDiagnostic(
  List<NarrativeOutcomeAuthoringDiagnostic> diagnostics, {
  required NarrativeOutcomeAuthoringDiagnosticKind kind,
  required String message,
  required String path,
  String? referencedId,
  NarrativeOutcomeAuthoringDiagnosticSeverity severity =
      NarrativeOutcomeAuthoringDiagnosticSeverity.error,
}) {
  diagnostics.add(
    NarrativeOutcomeAuthoringDiagnostic(
      severity: severity,
      kind: kind,
      message: message,
      path: path,
      referencedId: referencedId,
    ),
  );
}

String _requireRawScenarioOutcomeId(String outcomeId) {
  final trimmedOutcomeId = outcomeId.trim();
  if (trimmedOutcomeId.isEmpty) {
    throw ArgumentError.value(
        outcomeId, 'outcomeId', 'Outcome id is required.');
  }
  if (_looksLikeScenarioOrBattleFlag(trimmedOutcomeId)) {
    throw ArgumentError.value(
      outcomeId,
      'outcomeId',
      'Expected a raw scenario outcome id, not a stored outcome flag.',
    );
  }
  return trimmedOutcomeId;
}

String _requireRawBattleId(String battleId) {
  final trimmedBattleId = battleId.trim();
  if (trimmedBattleId.isEmpty) {
    throw ArgumentError.value(battleId, 'battleId', 'Battle id is required.');
  }
  if (_looksLikeScenarioOrBattleFlag(trimmedBattleId)) {
    throw ArgumentError.value(
      battleId,
      'battleId',
      'Expected a raw battle id, not a stored outcome flag.',
    );
  }
  return trimmedBattleId;
}

bool _looksLikeScenarioOrBattleFlag(String value) {
  return value.startsWith(_scenarioOutcomePrefix) ||
      value.startsWith(_battleOutcomePrefix);
}

List<String> _dedupeTrimmed(Iterable<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || !seen.add(trimmed)) {
      continue;
    }
    result.add(trimmed);
  }
  return List<String>.unmodifiable(result);
}
