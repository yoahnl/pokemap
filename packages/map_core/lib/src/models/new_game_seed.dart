import 'package:meta/meta.dart' show immutable;

import 'narrative_value.dart';
import 'save_data.dart';

const int newGameSeedSchemaVersion = 1;

@immutable
final class NewGameSeed {
  NewGameSeed({
    required this.operationId,
    required this.projectRevision,
    required this.slotId,
    required this.draftId,
    required this.draftRevision,
    required this.playerName,
    required this.avatarCharacterId,
    required this.pronounSet,
    required this.starterOptionId,
    required Map<String, NarrativeValue> variables,
  }) : variables = Map<String, NarrativeValue>.unmodifiable(variables);

  final int schemaVersion = newGameSeedSchemaVersion;
  final String operationId;
  final String projectRevision;
  final String slotId;
  final String draftId;
  final int draftRevision;
  final String playerName;
  final String? avatarCharacterId;
  final PlayerPronounSet pronounSet;
  final String? starterOptionId;
  final Map<String, NarrativeValue> variables;

  @override
  String toString() =>
      'NewGameSeed(operationId: $operationId, projectRevision: '
      '$projectRevision, slotId: $slotId, draftId: $draftId, '
      'draftRevision: $draftRevision, variableCount: ${variables.length})';
}
