import '../exceptions/map_exceptions.dart';
import '../operations/narrative_fact_runtime.dart';
import 'narrative_fact.dart';
import 'narrative_value.dart';

final class ProjectBattleSavingsConfig {
  const ProjectBattleSavingsConfig({
    required this.enabledFactId,
    required this.balanceFactId,
    required this.percentage,
    required this.maximumBalance,
  });

  static const capabilityId = 'project.battle-savings@1';

  factory ProjectBattleSavingsConfig.fromJson(Map<String, dynamic> json) {
    final enabled = json['enabledFactId'];
    final balance = json['balanceFactId'];
    final percentage = json['percentage'];
    final maximum = json['maximumBalance'];
    if (json.length != 4 ||
        enabled is! String ||
        balance is! String ||
        enabled.isEmpty ||
        enabled.trim() != enabled ||
        balance.isEmpty ||
        balance.trim() != balance ||
        enabled == balance ||
        percentage is! int ||
        percentage < 0 ||
        percentage > 100 ||
        maximum is! int ||
        maximum < 0 ||
        maximum > 9007199254740991) {
      throw const FormatException('Invalid battle savings policy.');
    }
    return ProjectBattleSavingsConfig(
      enabledFactId: enabled,
      balanceFactId: balance,
      percentage: percentage,
      maximumBalance: maximum,
    );
  }

  final String enabledFactId;
  final String balanceFactId;
  final int percentage;
  final int maximumBalance;

  void validate(Iterable<NarrativeFactDefinition> facts) {
    ProjectBattleSavingsConfig.fromJson(toJson());
    final definitions = facts.toList(growable: false);
    final resolver = NarrativeFactRuntimeResolver.fromFacts(definitions);
    for (final entry in {
      enabledFactId: NarrativeValueKind.boolean,
      balanceFactId: NarrativeValueKind.integer,
    }.entries) {
      final matches = definitions
          .where((fact) => fact.id == entry.key)
          .toList();
      if (matches.length != 1 ||
          matches.single.valueKind != entry.value ||
          resolver.issues.any((issue) => issue.factIds.contains(entry.key)) ||
          (entry.value == NarrativeValueKind.integer &&
              (matches.single.initialValue.intValue < 0 ||
                  matches.single.initialValue.intValue > maximumBalance))) {
        throw ValidationException(
          'Battle savings requires declared, unambiguous boolean and integer Facts.',
          code: 'battle_savings.fact_invalid',
          details: {'factId': entry.key},
        );
      }
    }
  }

  Map<String, dynamic> toJson() => {
    'enabledFactId': enabledFactId,
    'balanceFactId': balanceFactId,
    'percentage': percentage,
    'maximumBalance': maximumBalance,
  };

  @override
  bool operator ==(Object other) =>
      other is ProjectBattleSavingsConfig &&
      enabledFactId == other.enabledFactId &&
      balanceFactId == other.balanceFactId &&
      percentage == other.percentage &&
      maximumBalance == other.maximumBalance;

  @override
  int get hashCode =>
      Object.hash(enabledFactId, balanceFactId, percentage, maximumBalance);
}
