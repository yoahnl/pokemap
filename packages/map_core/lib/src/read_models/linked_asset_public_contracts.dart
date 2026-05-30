import 'package:meta/meta.dart' show immutable;

import '../models/project_manifest.dart';
import '../models/project_trainer.dart';
import '../models/scenario_asset.dart';

const String _cutsceneStudioSchemaMetadataKey = 'authoring.cutsceneSchema';
const String _completedOutcomeId = 'completed';
const String _victoryOutcomeId = 'victory';
const String _defeatOutcomeId = 'defeat';

enum LinkedAssetContractDiagnosticSeverity {
  info,
  warning,
  error,
}

enum LinkedAssetContractDiagnosticCode {
  missingRef,
  unknownRef,
  missingLabel,
  rawTechnicalLabel,
  missingOutcomeContract,
  legacyBridge,
  unsupportedSource,
  emptyTrainerTeam,
}

enum LinkedAssetContractStatus {
  available,
  bridgeOnly,
  unavailable,
}

enum BattlePublicContractKind {
  trainer,
}

enum CinematicPublicContractSourceKind {
  scenarioBridge,
}

enum OutcomeProducerPublicContractKind {
  battle,
}

@immutable
final class LinkedAssetContractDiagnostic {
  const LinkedAssetContractDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    this.sourceId,
  });

  final LinkedAssetContractDiagnosticCode code;
  final LinkedAssetContractDiagnosticSeverity severity;
  final String message;
  final String? sourceId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkedAssetContractDiagnostic &&
          other.code == code &&
          other.severity == severity &&
          other.message == message &&
          other.sourceId == sourceId;

  @override
  int get hashCode => Object.hash(code, severity, message, sourceId);
}

@immutable
final class LinkedAssetOutcomeContract {
  const LinkedAssetOutcomeContract({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkedAssetOutcomeContract &&
          other.id == id &&
          other.label == label;

  @override
  int get hashCode => Object.hash(id, label);
}

@immutable
final class DialoguePublicContract {
  DialoguePublicContract({
    required this.id,
    required this.label,
    required this.sourceRef,
    required this.defaultStartNode,
    required List<String> availableStartNodes,
    required List<LinkedAssetOutcomeContract> declaredOutcomes,
    required List<LinkedAssetContractDiagnostic> diagnostics,
    required this.status,
  })  : availableStartNodes = List<String>.unmodifiable(availableStartNodes),
        declaredOutcomes =
            List<LinkedAssetOutcomeContract>.unmodifiable(declaredOutcomes),
        diagnostics =
            List<LinkedAssetContractDiagnostic>.unmodifiable(diagnostics);

  final String id;
  final String label;
  final String sourceRef;
  final String? defaultStartNode;
  final List<String> availableStartNodes;
  final List<LinkedAssetOutcomeContract> declaredOutcomes;
  final List<LinkedAssetContractDiagnostic> diagnostics;
  final LinkedAssetContractStatus status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DialoguePublicContract &&
          other.id == id &&
          other.label == label &&
          other.sourceRef == sourceRef &&
          other.defaultStartNode == defaultStartNode &&
          _listEquals(other.availableStartNodes, availableStartNodes) &&
          _listEquals(other.declaredOutcomes, declaredOutcomes) &&
          _listEquals(other.diagnostics, diagnostics) &&
          other.status == status;

  @override
  int get hashCode => Object.hash(
        id,
        label,
        sourceRef,
        defaultStartNode,
        Object.hashAll(availableStartNodes),
        Object.hashAll(declaredOutcomes),
        Object.hashAll(diagnostics),
        status,
      );
}

@immutable
final class BattlePublicContract {
  BattlePublicContract({
    required this.id,
    required this.battleRefId,
    required this.label,
    required this.battleKind,
    required this.trainerId,
    required this.trainerLabel,
    required List<LinkedAssetOutcomeContract> possibleOutcomes,
    required List<LinkedAssetContractDiagnostic> diagnostics,
    required this.status,
  })  : possibleOutcomes =
            List<LinkedAssetOutcomeContract>.unmodifiable(possibleOutcomes),
        diagnostics =
            List<LinkedAssetContractDiagnostic>.unmodifiable(diagnostics);

  final String id;
  final String battleRefId;
  final String label;
  final BattlePublicContractKind battleKind;
  final String trainerId;
  final String trainerLabel;
  final List<LinkedAssetOutcomeContract> possibleOutcomes;
  final List<LinkedAssetContractDiagnostic> diagnostics;
  final LinkedAssetContractStatus status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BattlePublicContract &&
          other.id == id &&
          other.battleRefId == battleRefId &&
          other.label == label &&
          other.battleKind == battleKind &&
          other.trainerId == trainerId &&
          other.trainerLabel == trainerLabel &&
          _listEquals(other.possibleOutcomes, possibleOutcomes) &&
          _listEquals(other.diagnostics, diagnostics) &&
          other.status == status;

  @override
  int get hashCode => Object.hash(
        id,
        battleRefId,
        label,
        battleKind,
        trainerId,
        trainerLabel,
        Object.hashAll(possibleOutcomes),
        Object.hashAll(diagnostics),
        status,
      );
}

@immutable
final class CinematicPublicContract {
  CinematicPublicContract({
    required this.id,
    required this.label,
    required this.sourceKind,
    required this.status,
    required this.linear,
    required List<String> requiredActors,
    required this.mapId,
    required List<LinkedAssetOutcomeContract> declaredOutputs,
    required List<LinkedAssetContractDiagnostic> diagnostics,
  })  : requiredActors = List<String>.unmodifiable(requiredActors),
        declaredOutputs =
            List<LinkedAssetOutcomeContract>.unmodifiable(declaredOutputs),
        diagnostics =
            List<LinkedAssetContractDiagnostic>.unmodifiable(diagnostics);

  final String id;
  final String label;
  final CinematicPublicContractSourceKind sourceKind;
  final LinkedAssetContractStatus status;
  final bool? linear;
  final List<String> requiredActors;
  final String? mapId;
  final List<LinkedAssetOutcomeContract> declaredOutputs;
  final List<LinkedAssetContractDiagnostic> diagnostics;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicPublicContract &&
          other.id == id &&
          other.label == label &&
          other.sourceKind == sourceKind &&
          other.status == status &&
          other.linear == linear &&
          _listEquals(other.requiredActors, requiredActors) &&
          other.mapId == mapId &&
          _listEquals(other.declaredOutputs, declaredOutputs) &&
          _listEquals(other.diagnostics, diagnostics);

  @override
  int get hashCode => Object.hash(
        id,
        label,
        sourceKind,
        status,
        linear,
        Object.hashAll(requiredActors),
        mapId,
        Object.hashAll(declaredOutputs),
        Object.hashAll(diagnostics),
      );
}

@immutable
final class OutcomeProducerPublicContract {
  OutcomeProducerPublicContract({
    required this.producerKind,
    required this.producerRef,
    required this.label,
    required this.status,
    required List<LinkedAssetOutcomeContract> outcomes,
    required List<LinkedAssetContractDiagnostic> diagnostics,
  })  : outcomes = List<LinkedAssetOutcomeContract>.unmodifiable(outcomes),
        diagnostics =
            List<LinkedAssetContractDiagnostic>.unmodifiable(diagnostics);

  final OutcomeProducerPublicContractKind producerKind;
  final String producerRef;
  final String label;
  final LinkedAssetContractStatus status;
  final List<LinkedAssetOutcomeContract> outcomes;
  final List<LinkedAssetContractDiagnostic> diagnostics;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutcomeProducerPublicContract &&
          other.producerKind == producerKind &&
          other.producerRef == producerRef &&
          other.label == label &&
          other.status == status &&
          _listEquals(other.outcomes, outcomes) &&
          _listEquals(other.diagnostics, diagnostics);

  @override
  int get hashCode => Object.hash(
        producerKind,
        producerRef,
        label,
        status,
        Object.hashAll(outcomes),
        Object.hashAll(diagnostics),
      );
}

@immutable
final class LinkedAssetContractsSnapshot {
  LinkedAssetContractsSnapshot({
    required List<DialoguePublicContract> dialogues,
    required List<BattlePublicContract> battles,
    required List<CinematicPublicContract> cinematics,
    required List<OutcomeProducerPublicContract> outcomeProducers,
    required this.actionContractsAvailable,
    required this.branchByOutcomeAvailable,
    required List<LinkedAssetContractDiagnostic> diagnostics,
  })  : dialogues = List<DialoguePublicContract>.unmodifiable(dialogues),
        battles = List<BattlePublicContract>.unmodifiable(battles),
        cinematics = List<CinematicPublicContract>.unmodifiable(cinematics),
        outcomeProducers =
            List<OutcomeProducerPublicContract>.unmodifiable(outcomeProducers),
        diagnostics =
            List<LinkedAssetContractDiagnostic>.unmodifiable(diagnostics);

  final List<DialoguePublicContract> dialogues;
  final List<BattlePublicContract> battles;
  final List<CinematicPublicContract> cinematics;
  final List<OutcomeProducerPublicContract> outcomeProducers;
  final bool actionContractsAvailable;
  final bool branchByOutcomeAvailable;
  final List<LinkedAssetContractDiagnostic> diagnostics;
}

List<DialoguePublicContract> buildDialoguePublicContracts(
  ProjectManifest project,
) {
  final contracts = project.dialogues.map((entry) {
    final id = entry.id.trim();
    final label = _labelOrId(entry.name, id);
    final diagnostics = <LinkedAssetContractDiagnostic>[
      ..._labelDiagnostics(
        rawLabel: entry.name,
        fallbackId: id,
        sourceId: id,
      ),
      const LinkedAssetContractDiagnostic(
        code: LinkedAssetContractDiagnosticCode.missingOutcomeContract,
        severity: LinkedAssetContractDiagnosticSeverity.warning,
        message: 'Dialogue outcomes are not exposed by a public contract yet.',
      ),
    ];
    if (id.isEmpty) {
      diagnostics.add(
        const LinkedAssetContractDiagnostic(
          code: LinkedAssetContractDiagnosticCode.missingRef,
          severity: LinkedAssetContractDiagnosticSeverity.error,
          message: 'Dialogue id is required for a stable Scene reference.',
        ),
      );
    }

    return DialoguePublicContract(
      id: id,
      label: label,
      sourceRef: entry.relativePath.trim(),
      defaultStartNode: _trimOrNull(entry.defaultStartNode),
      availableStartNodes: const [],
      declaredOutcomes: const [],
      diagnostics: diagnostics,
      status: id.isEmpty
          ? LinkedAssetContractStatus.unavailable
          : LinkedAssetContractStatus.available,
    );
  }).toList(growable: false);

  contracts.sort(
    _compareByLabelThen(
      (contract) => contract.label,
      (contract) => contract.id,
    ),
  );
  return List<DialoguePublicContract>.unmodifiable(contracts);
}

List<BattlePublicContract> buildBattlePublicContracts(ProjectManifest project) {
  final contracts = project.trainers.map((trainer) {
    final trainerId = trainer.id.trim();
    final trainerLabel = _labelOrId(trainer.name, trainerId);
    final battleRefId = 'trainer:$trainerId';
    final label = _battleLabel(trainer, trainerLabel, trainerId);
    final diagnostics = <LinkedAssetContractDiagnostic>[
      ..._labelDiagnostics(
        rawLabel: trainer.name,
        fallbackId: trainerId,
        sourceId: trainerId,
      ),
    ];
    if (trainerId.isEmpty) {
      diagnostics.add(
        const LinkedAssetContractDiagnostic(
          code: LinkedAssetContractDiagnosticCode.missingRef,
          severity: LinkedAssetContractDiagnosticSeverity.error,
          message: 'Trainer id is required for a stable battle reference.',
        ),
      );
    }
    if (trainer.team.isEmpty) {
      diagnostics.add(
        LinkedAssetContractDiagnostic(
          code: LinkedAssetContractDiagnosticCode.emptyTrainerTeam,
          severity: LinkedAssetContractDiagnosticSeverity.warning,
          message: 'Trainer battle has no authored team yet.',
          sourceId: trainerId.isEmpty ? null : trainerId,
        ),
      );
    }

    return BattlePublicContract(
      id: battleRefId,
      battleRefId: battleRefId,
      label: label,
      battleKind: BattlePublicContractKind.trainer,
      trainerId: trainerId,
      trainerLabel: trainerLabel,
      possibleOutcomes: const [
        LinkedAssetOutcomeContract(
          id: _victoryOutcomeId,
          label: 'Victory',
        ),
        LinkedAssetOutcomeContract(
          id: _defeatOutcomeId,
          label: 'Defeat',
        ),
      ],
      diagnostics: diagnostics,
      status: trainerId.isEmpty
          ? LinkedAssetContractStatus.unavailable
          : LinkedAssetContractStatus.available,
    );
  }).toList(growable: false);

  contracts.sort(
    _compareByLabelThen(
      (contract) => contract.label,
      (contract) => contract.id,
    ),
  );
  return List<BattlePublicContract>.unmodifiable(contracts);
}

List<CinematicPublicContract> buildCinematicPublicContracts(
  ProjectManifest project,
) {
  final contracts = <CinematicPublicContract>[];
  for (final scenario in project.scenarios) {
    if (!_isCutsceneStudioScenarioBridge(scenario)) {
      continue;
    }
    final id = scenario.id.trim();
    final label = _labelOrId(scenario.name, id);
    final diagnostics = <LinkedAssetContractDiagnostic>[
      ..._labelDiagnostics(
        rawLabel: scenario.name,
        fallbackId: id,
        sourceId: id,
      ),
      LinkedAssetContractDiagnostic(
        code: LinkedAssetContractDiagnosticCode.legacyBridge,
        severity: LinkedAssetContractDiagnosticSeverity.warning,
        message:
            'This cinematic contract is a ScenarioAsset bridge, not a canonical CinematicAsset.',
        sourceId: id,
      ),
    ];
    if (id.isEmpty) {
      diagnostics.add(
        const LinkedAssetContractDiagnostic(
          code: LinkedAssetContractDiagnosticCode.missingRef,
          severity: LinkedAssetContractDiagnosticSeverity.error,
          message:
              'Scenario id is required for a stable cinematic bridge reference.',
        ),
      );
    }

    contracts.add(
      CinematicPublicContract(
        id: id,
        label: label,
        sourceKind: CinematicPublicContractSourceKind.scenarioBridge,
        status: LinkedAssetContractStatus.bridgeOnly,
        linear: null,
        requiredActors: const [],
        mapId: null,
        declaredOutputs: const [
          LinkedAssetOutcomeContract(
            id: _completedOutcomeId,
            label: 'Completed',
          ),
        ],
        diagnostics: diagnostics,
      ),
    );
  }

  contracts.sort(
    _compareByLabelThen(
      (contract) => contract.label,
      (contract) => contract.id,
    ),
  );
  return List<CinematicPublicContract>.unmodifiable(contracts);
}

LinkedAssetContractsSnapshot buildLinkedAssetContractsSnapshot(
  ProjectManifest project,
) {
  final dialogues = buildDialoguePublicContracts(project);
  final battles = buildBattlePublicContracts(project);
  final cinematics = buildCinematicPublicContracts(project);
  final outcomeProducers = <OutcomeProducerPublicContract>[
    for (final battle in battles)
      OutcomeProducerPublicContract(
        producerKind: OutcomeProducerPublicContractKind.battle,
        producerRef: battle.battleRefId,
        label: battle.label,
        status: battle.status,
        outcomes: battle.possibleOutcomes,
        diagnostics: battle.diagnostics,
      ),
  ];

  final diagnostics = <LinkedAssetContractDiagnostic>[
    const LinkedAssetContractDiagnostic(
      code: LinkedAssetContractDiagnosticCode.unsupportedSource,
      severity: LinkedAssetContractDiagnosticSeverity.info,
      message:
          'Action/Consequence public contracts are not available in V0; ActionNode remains disabled.',
      sourceId: 'action',
    ),
    const LinkedAssetContractDiagnostic(
      code: LinkedAssetContractDiagnosticCode.unsupportedSource,
      severity: LinkedAssetContractDiagnosticSeverity.info,
      message:
          'BranchByOutcome remains disabled until outcome producers and mappings are explicit.',
      sourceId: 'branchByOutcome',
    ),
  ];

  return LinkedAssetContractsSnapshot(
    dialogues: dialogues,
    battles: battles,
    cinematics: cinematics,
    outcomeProducers: outcomeProducers,
    actionContractsAvailable: false,
    branchByOutcomeAvailable: false,
    diagnostics: diagnostics,
  );
}

String _battleLabel(
  ProjectTrainerEntry trainer,
  String trainerLabel,
  String trainerId,
) {
  final trainerClass = trainer.trainerClass.trim();
  if (trainerClass.isEmpty) {
    return trainerLabel;
  }
  if (trainerLabel == trainerId) {
    return trainerClass;
  }
  return '$trainerClass $trainerLabel';
}

bool _isCutsceneStudioScenarioBridge(ScenarioAsset scenario) {
  final schemaVersion =
      scenario.metadata[_cutsceneStudioSchemaMetadataKey]?.trim();
  return schemaVersion != null && schemaVersion.isNotEmpty;
}

List<LinkedAssetContractDiagnostic> _labelDiagnostics({
  required String rawLabel,
  required String fallbackId,
  required String sourceId,
}) {
  final trimmedLabel = rawLabel.trim();
  final diagnostics = <LinkedAssetContractDiagnostic>[];
  if (trimmedLabel.isEmpty) {
    diagnostics.add(
      LinkedAssetContractDiagnostic(
        code: LinkedAssetContractDiagnosticCode.missingLabel,
        severity: LinkedAssetContractDiagnosticSeverity.warning,
        message: 'Readable label is missing; technical id is used as fallback.',
        sourceId: sourceId.isEmpty ? null : sourceId,
      ),
    );
    diagnostics.add(
      LinkedAssetContractDiagnostic(
        code: LinkedAssetContractDiagnosticCode.rawTechnicalLabel,
        severity: LinkedAssetContractDiagnosticSeverity.warning,
        message: 'The public contract label falls back to a technical id.',
        sourceId: sourceId.isEmpty ? null : sourceId,
      ),
    );
  } else if (trimmedLabel == fallbackId && fallbackId.isNotEmpty) {
    diagnostics.add(
      LinkedAssetContractDiagnostic(
        code: LinkedAssetContractDiagnosticCode.rawTechnicalLabel,
        severity: LinkedAssetContractDiagnosticSeverity.warning,
        message: 'Readable label matches the technical id.',
        sourceId: sourceId,
      ),
    );
  }
  return diagnostics;
}

String _labelOrId(String label, String fallbackId) {
  final trimmedLabel = label.trim();
  if (trimmedLabel.isNotEmpty) {
    return trimmedLabel;
  }
  return fallbackId;
}

String? _trimOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

int Function(T, T) _compareByLabelThen<T>(
  String Function(T value) labelOf,
  String Function(T value) idOf,
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
  final lowerA = a.toLowerCase();
  final lowerB = b.toLowerCase();
  final byLower = lowerA.compareTo(lowerB);
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
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}
