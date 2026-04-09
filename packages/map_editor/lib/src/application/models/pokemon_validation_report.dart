enum PokemonValidationSeverity {
  warning,
  error,
}

class PokemonValidationIssue {
  const PokemonValidationIssue({
    required this.severity,
    required this.code,
    required this.message,
    required this.location,
  });

  final PokemonValidationSeverity severity;
  final String code;
  final String message;
  final String location;
}

class PokemonValidationReport {
  const PokemonValidationReport({
    required this.issues,
  });

  final List<PokemonValidationIssue> issues;

  bool get isValid =>
      !issues.any((issue) => issue.severity == PokemonValidationSeverity.error);

  bool get hasWarnings =>
      issues.any((issue) => issue.severity == PokemonValidationSeverity.warning);

  int get errorCount => issues
      .where((issue) => issue.severity == PokemonValidationSeverity.error)
      .length;

  int get warningCount => issues
      .where((issue) => issue.severity == PokemonValidationSeverity.warning)
      .length;
}
