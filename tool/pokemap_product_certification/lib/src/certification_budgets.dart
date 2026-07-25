final class ProductCertificationBudgets {
  const ProductCertificationBudgets._();

  static const int libraryGameCount = 100;
  static const int speciesCatalogCount = 2000;

  /// Conservative CI reference budget, not a universal device percentile.
  static const Duration libraryLoad = Duration(seconds: 5);

  /// Conservative CI reference budget, including export and hostile reopen.
  static const Duration catalogExportAndInspection = Duration(seconds: 30);

  /// A long operation must publish an observable stage before this interval.
  static const Duration opaqueProgressSilence = Duration(seconds: 2);
}

final class ProductCertificationMeasurement {
  const ProductCertificationMeasurement._({
    required this.id,
    required this.elapsed,
    required this.budget,
    required this.passed,
  });

  factory ProductCertificationMeasurement.evaluate({
    required String id,
    required Duration elapsed,
    required Duration budget,
  }) {
    if (id.trim().isEmpty || elapsed.isNegative || budget <= Duration.zero) {
      throw ArgumentError('Measurement id, elapsed and budget are invalid.');
    }
    return ProductCertificationMeasurement._(
      id: id,
      elapsed: elapsed,
      budget: budget,
      passed: elapsed <= budget,
    );
  }

  final String id;
  final Duration elapsed;
  final Duration budget;
  final bool passed;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'elapsedMs': elapsed.inMilliseconds,
        'budgetMs': budget.inMilliseconds,
        'passed': passed,
      };
}
