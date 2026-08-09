enum EncounterProbabilityIssue {
  invalidChancePerStep,
  nonPositiveWeight,
  zeroTotalWeight,
}

class EncounterEntryProbability {
  const EncounterEntryProbability({
    required this.weight,
    required this.relativeShare,
    required this.resolvedChancePerStep,
  });

  final int weight;
  final double? relativeShare;
  final double? resolvedChancePerStep;
}

class EncounterProbabilityProjection {
  const EncounterProbabilityProjection({
    required this.chancePerStep,
    required this.totalWeight,
    required this.entries,
    required this.issues,
  });

  final double chancePerStep;
  final int totalWeight;
  final List<EncounterEntryProbability> entries;
  final Set<EncounterProbabilityIssue> issues;

  bool get isValid => issues.isEmpty;
}

EncounterProbabilityProjection projectEncounterProbabilities({
  required double chancePerStep,
  required Iterable<int> weights,
}) {
  final orderedWeights = weights.toList(growable: false);
  final totalWeight = orderedWeights.fold<int>(
    0,
    (sum, weight) => sum + weight,
  );
  final issues = <EncounterProbabilityIssue>{};

  if (!chancePerStep.isFinite || chancePerStep < 0 || chancePerStep > 1) {
    issues.add(EncounterProbabilityIssue.invalidChancePerStep);
  }
  if (orderedWeights.any((weight) => weight <= 0)) {
    issues.add(EncounterProbabilityIssue.nonPositiveWeight);
  }
  if (totalWeight <= 0) {
    issues.add(EncounterProbabilityIssue.zeroTotalWeight);
  }

  final canProject = issues.isEmpty;
  final entries = orderedWeights
      .map((weight) {
        final relativeShare = canProject ? weight / totalWeight : null;
        return EncounterEntryProbability(
          weight: weight,
          relativeShare: relativeShare,
          resolvedChancePerStep: relativeShare == null
              ? null
              : chancePerStep * relativeShare,
        );
      })
      .toList(growable: false);

  return EncounterProbabilityProjection(
    chancePerStep: chancePerStep,
    totalWeight: totalWeight,
    entries: entries,
    issues: Set<EncounterProbabilityIssue>.unmodifiable(issues),
  );
}
