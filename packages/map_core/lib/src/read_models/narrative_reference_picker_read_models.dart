import 'package:meta/meta.dart' show immutable;

import '../models/project_manifest.dart';
import '../models/project_trainer.dart';
import '../models/scenario_asset.dart';

const String _actionEmitOutcome = 'emitoutcome';
const String _actionSourceOutcome = 'sourceoutcome';
const String _actionStartTrainerBattle = 'starttrainerbattle';
const String _outcomeIdParam = 'outcomeId';
const String _battleIdParam = 'battleId';

enum NarrativeBattleOutcomeKind {
  victory,
  defeat,
}

@immutable
final class NarrativeScenarioPickerOption {
  NarrativeScenarioPickerOption({
    required this.scenarioId,
    required this.humanLabel,
    required this.description,
    required this.scope,
    required this.entryNodeId,
    required List<String> declaredOutcomeIds,
    required this.nodeCount,
    required this.edgeCount,
    required this.debugTechnicalLabel,
  }) : declaredOutcomeIds = List<String>.unmodifiable(declaredOutcomeIds);

  final String scenarioId;
  final String humanLabel;
  final String description;
  final ScenarioScope scope;
  final String entryNodeId;
  final List<String> declaredOutcomeIds;
  final int nodeCount;
  final int edgeCount;
  final String debugTechnicalLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeScenarioPickerOption &&
          other.scenarioId == scenarioId &&
          other.humanLabel == humanLabel &&
          other.description == description &&
          other.scope == scope &&
          other.entryNodeId == entryNodeId &&
          _listEquals(other.declaredOutcomeIds, declaredOutcomeIds) &&
          other.nodeCount == nodeCount &&
          other.edgeCount == edgeCount &&
          other.debugTechnicalLabel == debugTechnicalLabel;

  @override
  int get hashCode => Object.hash(
        scenarioId,
        humanLabel,
        description,
        scope,
        entryNodeId,
        Object.hashAll(declaredOutcomeIds),
        nodeCount,
        edgeCount,
        debugTechnicalLabel,
      );
}

@immutable
final class NarrativeOutcomePickerOption {
  NarrativeOutcomePickerOption({
    required this.outcomeId,
    required this.humanLabel,
    required List<String> declaredByScenarioIds,
    required List<String> emittedByScenarioIds,
    required List<String> consumedByScenarioIds,
    required this.debugTechnicalLabel,
  })  : declaredByScenarioIds =
            List<String>.unmodifiable(declaredByScenarioIds),
        emittedByScenarioIds = List<String>.unmodifiable(emittedByScenarioIds),
        consumedByScenarioIds =
            List<String>.unmodifiable(consumedByScenarioIds);

  final String outcomeId;
  final String humanLabel;
  final List<String> declaredByScenarioIds;
  final List<String> emittedByScenarioIds;
  final List<String> consumedByScenarioIds;
  final String debugTechnicalLabel;

  bool get isDeclared => declaredByScenarioIds.isNotEmpty;

  bool get isEmitted => emittedByScenarioIds.isNotEmpty;

  bool get isConsumed => consumedByScenarioIds.isNotEmpty;

  bool get isOrphan => !isDeclared || !isEmitted || !isConsumed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeOutcomePickerOption &&
          other.outcomeId == outcomeId &&
          other.humanLabel == humanLabel &&
          _listEquals(other.declaredByScenarioIds, declaredByScenarioIds) &&
          _listEquals(other.emittedByScenarioIds, emittedByScenarioIds) &&
          _listEquals(other.consumedByScenarioIds, consumedByScenarioIds) &&
          other.debugTechnicalLabel == debugTechnicalLabel;

  @override
  int get hashCode => Object.hash(
        outcomeId,
        humanLabel,
        Object.hashAll(declaredByScenarioIds),
        Object.hashAll(emittedByScenarioIds),
        Object.hashAll(consumedByScenarioIds),
        debugTechnicalLabel,
      );
}

@immutable
final class NarrativeBattleReferencePickerOption {
  NarrativeBattleReferencePickerOption({
    required this.battleReferenceId,
    required this.battleId,
    required this.humanLabel,
    required this.sourceScenarioId,
    required this.sourceNodeId,
    required this.trainerId,
    required this.trainerLabel,
    required this.trainerClass,
    required this.npcEntityId,
    required this.isTrainerKnown,
    required List<NarrativeBattleOutcomeKind> supportedOutcomeKinds,
    required this.debugTechnicalLabel,
  }) : supportedOutcomeKinds = List<NarrativeBattleOutcomeKind>.unmodifiable(
          supportedOutcomeKinds,
        );

  final String battleReferenceId;
  final String battleId;
  final String humanLabel;
  final String sourceScenarioId;
  final String sourceNodeId;
  final String trainerId;
  final String? trainerLabel;
  final String? trainerClass;
  final String npcEntityId;
  final bool isTrainerKnown;
  final List<NarrativeBattleOutcomeKind> supportedOutcomeKinds;
  final String debugTechnicalLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeBattleReferencePickerOption &&
          other.battleReferenceId == battleReferenceId &&
          other.battleId == battleId &&
          other.humanLabel == humanLabel &&
          other.sourceScenarioId == sourceScenarioId &&
          other.sourceNodeId == sourceNodeId &&
          other.trainerId == trainerId &&
          other.trainerLabel == trainerLabel &&
          other.trainerClass == trainerClass &&
          other.npcEntityId == npcEntityId &&
          other.isTrainerKnown == isTrainerKnown &&
          _listEquals(other.supportedOutcomeKinds, supportedOutcomeKinds) &&
          other.debugTechnicalLabel == debugTechnicalLabel;

  @override
  int get hashCode => Object.hash(
        battleReferenceId,
        battleId,
        humanLabel,
        sourceScenarioId,
        sourceNodeId,
        trainerId,
        trainerLabel,
        trainerClass,
        npcEntityId,
        isTrainerKnown,
        Object.hashAll(supportedOutcomeKinds),
        debugTechnicalLabel,
      );
}

List<NarrativeScenarioPickerOption> buildNarrativeScenarioPickerOptions(
  ProjectManifest manifest,
) {
  final options = manifest.scenarios.map((scenario) {
    final scenarioId = scenario.id.trim();
    return NarrativeScenarioPickerOption(
      scenarioId: scenarioId,
      humanLabel: _labelOrId(scenario.name, scenarioId),
      description: scenario.description.trim(),
      scope: scenario.scope,
      entryNodeId: scenario.entryNodeId.trim(),
      declaredOutcomeIds: _dedupeAndSort(scenario.declaredOutcomes),
      nodeCount: scenario.nodes.length,
      edgeCount: scenario.edges.length,
      debugTechnicalLabel: scenarioId,
    );
  }).toList(growable: false);

  options.sort(_compareByLabelThen(
      (option) => option.humanLabel, (option) => option.scenarioId));
  return List<NarrativeScenarioPickerOption>.unmodifiable(options);
}

List<NarrativeOutcomePickerOption> buildNarrativeOutcomePickerOptions(
  ProjectManifest manifest,
) {
  final byOutcomeId = <String, _MutableOutcomePickerOption>{};

  for (final scenario in manifest.scenarios) {
    final scenarioId = scenario.id.trim();
    for (final outcomeId in _dedupeAndSort(scenario.declaredOutcomes)) {
      byOutcomeId
          .putIfAbsent(outcomeId, () => _MutableOutcomePickerOption(outcomeId))
          .declaredByScenarioIds
          .add(scenarioId);
    }

    for (final node in scenario.nodes) {
      final actionKind = _normalizedActionKind(node);
      if (actionKind != _actionEmitOutcome &&
          actionKind != _actionSourceOutcome) {
        continue;
      }
      for (final outcomeId in _outcomeIdsForNode(node)) {
        final option = byOutcomeId.putIfAbsent(
          outcomeId,
          () => _MutableOutcomePickerOption(outcomeId),
        );
        if (actionKind == _actionEmitOutcome) {
          option.emittedByScenarioIds.add(scenarioId);
        } else {
          option.consumedByScenarioIds.add(scenarioId);
        }
      }
    }
  }

  final options = byOutcomeId.values.map((entry) {
    return NarrativeOutcomePickerOption(
      outcomeId: entry.outcomeId,
      humanLabel: _humanizeTechnicalId(entry.outcomeId),
      declaredByScenarioIds: _dedupeAndSort(entry.declaredByScenarioIds),
      emittedByScenarioIds: _dedupeAndSort(entry.emittedByScenarioIds),
      consumedByScenarioIds: _dedupeAndSort(entry.consumedByScenarioIds),
      debugTechnicalLabel: entry.outcomeId,
    );
  }).toList(growable: false);

  options.sort(_compareByLabelThen(
      (option) => option.humanLabel, (option) => option.outcomeId));
  return List<NarrativeOutcomePickerOption>.unmodifiable(options);
}

List<NarrativeBattleReferencePickerOption>
    buildNarrativeBattleReferencePickerOptions(ProjectManifest manifest) {
  final trainersById = <String, ProjectTrainerEntry>{
    for (final trainer in manifest.trainers)
      if (trainer.id.trim().isNotEmpty) trainer.id.trim(): trainer,
  };
  final options = <NarrativeBattleReferencePickerOption>[];

  for (final scenario in manifest.scenarios) {
    final scenarioId = scenario.id.trim();
    for (final node in scenario.nodes) {
      if (_normalizedActionKind(node) != _actionStartTrainerBattle) {
        continue;
      }

      final nodeId = node.id.trim();
      final trainerId = node.binding.trainerId?.trim() ?? '';
      final trainer = trainersById[trainerId];
      final authoredBattleId = node.payload.params[_battleIdParam]?.trim();
      final battleId = _firstNonBlank([
        authoredBattleId,
        trainerId,
        '$scenarioId:$nodeId',
      ]);
      final battleReferenceId = '$scenarioId:$nodeId';

      options.add(
        NarrativeBattleReferencePickerOption(
          battleReferenceId: battleReferenceId,
          battleId: battleId,
          humanLabel: _battleHumanLabel(
            trainer: trainer,
            trainerId: trainerId,
            battleId: battleId,
            battleReferenceId: battleReferenceId,
          ),
          sourceScenarioId: scenarioId,
          sourceNodeId: nodeId,
          trainerId: trainerId,
          trainerLabel: trainer?.name.trim(),
          trainerClass: trainer?.trainerClass.trim(),
          npcEntityId: node.binding.entityId?.trim() ?? '',
          isTrainerKnown: trainer != null,
          supportedOutcomeKinds: const [
            NarrativeBattleOutcomeKind.victory,
            NarrativeBattleOutcomeKind.defeat,
          ],
          debugTechnicalLabel: '$battleReferenceId -> $battleId',
        ),
      );
    }
  }

  options.sort(_compareByLabelThen(
      (option) => option.humanLabel, (option) => option.battleReferenceId));
  return List<NarrativeBattleReferencePickerOption>.unmodifiable(options);
}

class _MutableOutcomePickerOption {
  _MutableOutcomePickerOption(this.outcomeId);

  final String outcomeId;
  final List<String> declaredByScenarioIds = <String>[];
  final List<String> emittedByScenarioIds = <String>[];
  final List<String> consumedByScenarioIds = <String>[];
}

List<String> _outcomeIdsForNode(ScenarioNode node) {
  final values = <String>[
    node.binding.outcomeId ?? '',
    node.payload.params[_outcomeIdParam] ?? '',
  ];
  return _dedupeAndSort(values);
}

String _normalizedActionKind(ScenarioNode node) {
  return (node.payload.actionKind ?? '')
      .trim()
      .toLowerCase()
      .replaceAll('_', '');
}

String _labelOrId(String label, String id) {
  final trimmed = label.trim();
  return trimmed.isNotEmpty ? trimmed : id;
}

String _battleHumanLabel({
  required ProjectTrainerEntry? trainer,
  required String trainerId,
  required String battleId,
  required String battleReferenceId,
}) {
  if (trainer != null) {
    return _firstNonBlank([
      _joinNonBlank([trainer.trainerClass, trainer.name]),
      trainer.name,
      trainer.trainerClass,
      trainer.id,
    ]);
  }
  return _firstNonBlank([trainerId, battleId, battleReferenceId]);
}

String _joinNonBlank(Iterable<String?> values) {
  return values
      .map((value) => value?.trim() ?? '')
      .where((value) => value.isNotEmpty)
      .join(' ');
}

String _firstNonBlank(Iterable<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return '';
}

String _humanizeTechnicalId(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  final label = trimmed
      .split(RegExp(r'[._:\-\s]+'))
      .where((part) => part.isNotEmpty)
      .join(' ');
  return label.isEmpty ? trimmed : label;
}

List<String> _dedupeAndSort(Iterable<String> values) {
  final normalized = <String>{
    for (final value in values)
      if (value.trim().isNotEmpty) value.trim(),
  };
  final list = normalized.toList(growable: false);
  list.sort(_compareStringsCaseInsensitive);
  return list;
}

int Function(T a, T b) _compareByLabelThen<T>(
  String Function(T item) labelOf,
  String Function(T item) idOf,
) {
  return (a, b) {
    final byLabel = _compareStringsCaseInsensitive(labelOf(a), labelOf(b));
    if (byLabel != 0) {
      return byLabel;
    }
    return _compareStringsCaseInsensitive(idOf(a), idOf(b));
  };
}

int _compareStringsCaseInsensitive(String a, String b) {
  final byLower = a.toLowerCase().compareTo(b.toLowerCase());
  if (byLower != 0) {
    return byLower;
  }
  return a.compareTo(b);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
