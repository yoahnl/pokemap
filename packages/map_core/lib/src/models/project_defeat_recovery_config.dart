import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import '../operations/narrative_fact_runtime.dart';
import 'narrative_fact.dart';
import 'narrative_value.dart';

@immutable
final class ProjectDefeatRecoveryConfig {
  const ProjectDefeatRecoveryConfig({required this.recoveredFactId});

  factory ProjectDefeatRecoveryConfig.fromJson(Map<String, dynamic> json) {
    final id = json['recoveredFactId'];
    if (json.length != 1 || id is! String || id.isEmpty || id.trim() != id) {
      throw const FormatException(
        'defeatRecovery requires only a non-empty recoveredFactId.',
      );
    }
    return ProjectDefeatRecoveryConfig(recoveredFactId: id);
  }

  final String recoveredFactId;

  void validate(Iterable<NarrativeFactDefinition> facts) {
    final definitions = facts.toList(growable: false);
    final matches = definitions
        .where((fact) => fact.id == recoveredFactId)
        .toList(growable: false);
    final resolver = NarrativeFactRuntimeResolver.fromFacts(definitions);
    if (recoveredFactId.isEmpty ||
        recoveredFactId.trim() != recoveredFactId ||
        matches.length != 1 ||
        matches.single.valueKind != NarrativeValueKind.boolean ||
        resolver.issues.any(
          (issue) => issue.factIds.contains(recoveredFactId),
        )) {
      throw ValidationException(
        'Defeat recovery requires one unambiguous boolean Fact.',
        code: 'defeat_recovery.fact_invalid',
        details: {
          'path': r'$.defeatRecovery.recoveredFactId',
          'factId': recoveredFactId,
        },
      );
    }
  }

  Map<String, dynamic> toJson() => {'recoveredFactId': recoveredFactId};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectDefeatRecoveryConfig &&
          other.recoveredFactId == recoveredFactId;

  @override
  int get hashCode => recoveredFactId.hashCode;
}
