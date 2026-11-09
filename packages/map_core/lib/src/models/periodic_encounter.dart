enum PeriodicEncounterOutcome { victory, captured, fled }

final class PeriodicEncounterDefinition {
  PeriodicEncounterDefinition({
    required this.rewardId,
    required this.label,
    required Set<PeriodicEncounterOutcome> consumeOnOutcomes,
  }) : consumeOnOutcomes = Set.unmodifiable(consumeOnOutcomes) {
    if (rewardId.isEmpty || rewardId.trim() != rewardId ||
        label.isEmpty || label.trim() != label || consumeOnOutcomes.isEmpty) {
      throw ArgumentError('Periodic encounters require an identity, label and consuming outcomes.');
    }
  }

  factory PeriodicEncounterDefinition.fromJson(Map<String, dynamic> json) {
    const fields = {'schemaVersion', 'rewardId', 'label', 'consumeOnOutcomes'};
    final outcomes = json['consumeOnOutcomes'];
    if (json.length != fields.length || !json.keys.every(fields.contains) ||
        json['schemaVersion'] is! int || json['schemaVersion'] != 1 ||
        json['rewardId'] is! String || json['label'] is! String ||
        outcomes is! List || outcomes.isEmpty ||
        outcomes.any((value) => value is! String || !PeriodicEncounterOutcome.values.any((outcome) => outcome.name == value)) ||
        outcomes.toSet().length != outcomes.length) {
      throw const FormatException('Invalid or unsupported periodic encounter definition.');
    }
    try {
      return PeriodicEncounterDefinition(rewardId: json['rewardId'] as String,
        label: json['label'] as String,
        consumeOnOutcomes: outcomes.map((value) => PeriodicEncounterOutcome.values.byName(value as String)).toSet());
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String rewardId;
  final String label;
  final Set<PeriodicEncounterOutcome> consumeOnOutcomes;

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1, 'rewardId': rewardId, 'label': label,
    'consumeOnOutcomes': [for (final outcome in PeriodicEncounterOutcome.values) if (consumeOnOutcomes.contains(outcome)) outcome.name],
  };

  @override
  bool operator ==(Object other) => other is PeriodicEncounterDefinition &&
    other.rewardId == rewardId && other.label == label &&
    other.consumeOnOutcomes.length == consumeOnOutcomes.length && other.consumeOnOutcomes.containsAll(consumeOnOutcomes);

  @override
  int get hashCode => Object.hash(rewardId, label, Object.hashAllUnordered(consumeOnOutcomes));
}
