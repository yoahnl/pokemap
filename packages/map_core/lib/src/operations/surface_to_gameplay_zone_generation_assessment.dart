import '../exceptions/map_exceptions.dart';
import 'surface_to_gameplay_zone_generation_plan.dart';

enum SurfaceGameplayZoneGenerationAssessmentStatus {
  ready,
  needsReview,
  blocked,
}

final class SurfaceGameplayZoneGenerationAssessmentPolicy {
  SurfaceGameplayZoneGenerationAssessmentPolicy({
    required this.maxExtraCellRatioBeforeWarning,
    required this.maxExtraCellRatioBeforeBlocking,
    required this.maxGeneratedZonesBeforeWarning,
    required this.maxGeneratedZonesBeforeBlocking,
  }) {
    _validateRatio(
      maxExtraCellRatioBeforeWarning,
      'maxExtraCellRatioBeforeWarning',
    );
    _validateRatio(
      maxExtraCellRatioBeforeBlocking,
      'maxExtraCellRatioBeforeBlocking',
    );
    if (maxExtraCellRatioBeforeBlocking < maxExtraCellRatioBeforeWarning) {
      throw const ValidationException(
        'maxExtraCellRatioBeforeBlocking must be >= maxExtraCellRatioBeforeWarning',
      );
    }
    if (maxGeneratedZonesBeforeWarning <= 0) {
      throw const ValidationException(
        'maxGeneratedZonesBeforeWarning must be positive',
      );
    }
    if (maxGeneratedZonesBeforeBlocking <= 0) {
      throw const ValidationException(
        'maxGeneratedZonesBeforeBlocking must be positive',
      );
    }
    if (maxGeneratedZonesBeforeBlocking < maxGeneratedZonesBeforeWarning) {
      throw const ValidationException(
        'maxGeneratedZonesBeforeBlocking must be >= maxGeneratedZonesBeforeWarning',
      );
    }
  }

  static final defaultPolicy = SurfaceGameplayZoneGenerationAssessmentPolicy(
    maxExtraCellRatioBeforeWarning: 0,
    maxExtraCellRatioBeforeBlocking: 0.25,
    maxGeneratedZonesBeforeWarning: 8,
    maxGeneratedZonesBeforeBlocking: 32,
  );

  final double maxExtraCellRatioBeforeWarning;
  final double maxExtraCellRatioBeforeBlocking;
  final int maxGeneratedZonesBeforeWarning;
  final int maxGeneratedZonesBeforeBlocking;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SurfaceGameplayZoneGenerationAssessmentPolicy &&
            other.maxExtraCellRatioBeforeWarning ==
                maxExtraCellRatioBeforeWarning &&
            other.maxExtraCellRatioBeforeBlocking ==
                maxExtraCellRatioBeforeBlocking &&
            other.maxGeneratedZonesBeforeWarning ==
                maxGeneratedZonesBeforeWarning &&
            other.maxGeneratedZonesBeforeBlocking ==
                maxGeneratedZonesBeforeBlocking;
  }

  @override
  int get hashCode => Object.hash(
        maxExtraCellRatioBeforeWarning,
        maxExtraCellRatioBeforeBlocking,
        maxGeneratedZonesBeforeWarning,
        maxGeneratedZonesBeforeBlocking,
      );
}

final class SurfaceGameplayZoneGenerationAssessmentMessage {
  const SurfaceGameplayZoneGenerationAssessmentMessage({
    required this.severity,
    required this.title,
    required this.description,
    this.diagnosticKind,
  });

  final SurfaceGameplayZoneGenerationDiagnosticSeverity severity;
  final String title;
  final String description;
  final SurfaceGameplayZoneGenerationDiagnosticKind? diagnosticKind;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SurfaceGameplayZoneGenerationAssessmentMessage &&
            other.severity == severity &&
            other.title == title &&
            other.description == description &&
            other.diagnosticKind == diagnosticKind;
  }

  @override
  int get hashCode => Object.hash(
        severity,
        title,
        description,
        diagnosticKind,
      );
}

final class SurfaceGameplayZoneGenerationAssessment {
  SurfaceGameplayZoneGenerationAssessment({
    required this.plan,
    required this.status,
    required Iterable<SurfaceGameplayZoneGenerationAssessmentMessage> messages,
    required this.extraCellRatio,
    required this.coveragePercent,
    required this.summaryTitle,
    required this.summaryDescription,
  }) : messages =
            List<SurfaceGameplayZoneGenerationAssessmentMessage>.unmodifiable(
          messages,
        );

  final SurfaceGameplayZoneGenerationPlan plan;
  final SurfaceGameplayZoneGenerationAssessmentStatus status;
  final List<SurfaceGameplayZoneGenerationAssessmentMessage> messages;
  final double extraCellRatio;
  final double coveragePercent;
  final String summaryTitle;
  final String summaryDescription;

  bool get canApply =>
      status != SurfaceGameplayZoneGenerationAssessmentStatus.blocked;

  bool get requiresReview =>
      status == SurfaceGameplayZoneGenerationAssessmentStatus.needsReview;

  bool get hasErrors => errorMessages.isNotEmpty;

  bool get hasWarnings => warningMessages.isNotEmpty;

  List<SurfaceGameplayZoneGenerationAssessmentMessage> get infoMessages =>
      List<SurfaceGameplayZoneGenerationAssessmentMessage>.unmodifiable(
        messages.where(
          (message) =>
              message.severity ==
              SurfaceGameplayZoneGenerationDiagnosticSeverity.info,
        ),
      );

  List<SurfaceGameplayZoneGenerationAssessmentMessage> get warningMessages =>
      List<SurfaceGameplayZoneGenerationAssessmentMessage>.unmodifiable(
        messages.where(
          (message) =>
              message.severity ==
              SurfaceGameplayZoneGenerationDiagnosticSeverity.warning,
        ),
      );

  List<SurfaceGameplayZoneGenerationAssessmentMessage> get errorMessages =>
      List<SurfaceGameplayZoneGenerationAssessmentMessage>.unmodifiable(
        messages.where(
          (message) =>
              message.severity ==
              SurfaceGameplayZoneGenerationDiagnosticSeverity.error,
        ),
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SurfaceGameplayZoneGenerationAssessment &&
            other.plan == plan &&
            other.status == status &&
            _listEquals(other.messages, messages) &&
            other.extraCellRatio == extraCellRatio &&
            other.coveragePercent == coveragePercent &&
            other.summaryTitle == summaryTitle &&
            other.summaryDescription == summaryDescription;
  }

  @override
  int get hashCode => Object.hash(
        plan,
        status,
        Object.hashAll(messages),
        extraCellRatio,
        coveragePercent,
        summaryTitle,
        summaryDescription,
      );
}

SurfaceGameplayZoneGenerationAssessment assessSurfaceGameplayZoneGenerationPlan(
  SurfaceGameplayZoneGenerationPlan plan, {
  SurfaceGameplayZoneGenerationAssessmentPolicy? policy,
}) {
  final effectivePolicy =
      policy ?? SurfaceGameplayZoneGenerationAssessmentPolicy.defaultPolicy;
  final coverage = plan.coverage;
  final extraCellRatio =
      coverage.extraCellCount / _positiveDenominator(coverage.sourceCellCount);
  final coveragePercent = coverage.coveredSourceCellCount /
      _positiveDenominator(coverage.sourceCellCount);
  final messages = <SurfaceGameplayZoneGenerationAssessmentMessage>[];

  var blocked = false;
  var needsReview = false;

  if (plan.generatedZones.isEmpty) {
    blocked = true;
    messages.add(
      const SurfaceGameplayZoneGenerationAssessmentMessage(
        severity: SurfaceGameplayZoneGenerationDiagnosticSeverity.error,
        title: 'Aucune zone générée',
        description: 'Le plan ne contient aucune zone gameplay à créer.',
        diagnosticKind:
            SurfaceGameplayZoneGenerationDiagnosticKind.noGeneratedZone,
      ),
    );
  }

  for (final diagnostic in plan.diagnostics) {
    switch (diagnostic.severity) {
      case SurfaceGameplayZoneGenerationDiagnosticSeverity.error:
        blocked = true;
      case SurfaceGameplayZoneGenerationDiagnosticSeverity.warning:
        needsReview = true;
      case SurfaceGameplayZoneGenerationDiagnosticSeverity.info:
        break;
    }
    messages.add(_messageForDiagnostic(diagnostic));
  }

  if (coverage.extraCellCount > 0 &&
      extraCellRatio >= effectivePolicy.maxExtraCellRatioBeforeBlocking) {
    blocked = true;
    messages.add(
      SurfaceGameplayZoneGenerationAssessmentMessage(
        severity: SurfaceGameplayZoneGenerationDiagnosticSeverity.error,
        title: 'Trop de cellules hors surface',
        description:
            '${coverage.extraCellCount} cellules hors surface seraient incluses '
            '(${_formatPercent(extraCellRatio)} de la surface source).',
        diagnosticKind:
            SurfaceGameplayZoneGenerationDiagnosticKind.extraCellsIncluded,
      ),
    );
  } else if (coverage.extraCellCount > 0 &&
      extraCellRatio > effectivePolicy.maxExtraCellRatioBeforeWarning) {
    needsReview = true;
  }

  if (coverage.zoneCount >= effectivePolicy.maxGeneratedZonesBeforeBlocking) {
    blocked = true;
    messages.add(
      SurfaceGameplayZoneGenerationAssessmentMessage(
        severity: SurfaceGameplayZoneGenerationDiagnosticSeverity.error,
        title: 'Trop de zones générées',
        description:
            '${coverage.zoneCount} zones seraient générées. Réduisez la surface '
            'ou choisissez une autre stratégie.',
        diagnosticKind:
            SurfaceGameplayZoneGenerationDiagnosticKind.tooManyRectangles,
      ),
    );
  } else if (coverage.zoneCount >
      effectivePolicy.maxGeneratedZonesBeforeWarning) {
    needsReview = true;
    messages.add(
      SurfaceGameplayZoneGenerationAssessmentMessage(
        severity: SurfaceGameplayZoneGenerationDiagnosticSeverity.warning,
        title: 'Beaucoup de zones générées',
        description:
            '${coverage.zoneCount} zones seront créées. Vérifiez que le résultat '
            'reste lisible.',
        diagnosticKind:
            SurfaceGameplayZoneGenerationDiagnosticKind.tooManyRectangles,
      ),
    );
  }

  if (coverage.isExact) {
    messages.add(
      const SurfaceGameplayZoneGenerationAssessmentMessage(
        severity: SurfaceGameplayZoneGenerationDiagnosticSeverity.info,
        title: 'Couverture exacte',
        description:
            'Toutes les cellules source sont couvertes sans cellule hors surface.',
      ),
    );
  }

  final status = blocked
      ? SurfaceGameplayZoneGenerationAssessmentStatus.blocked
      : needsReview
          ? SurfaceGameplayZoneGenerationAssessmentStatus.needsReview
          : SurfaceGameplayZoneGenerationAssessmentStatus.ready;
  messages.insert(0, _summaryMessageForStatus(status));

  return SurfaceGameplayZoneGenerationAssessment(
    plan: plan,
    status: status,
    messages: messages,
    extraCellRatio: extraCellRatio,
    coveragePercent: coveragePercent,
    summaryTitle: _summaryTitleForStatus(status),
    summaryDescription: _summaryDescriptionForStatus(status),
  );
}

void _validateRatio(double value, String label) {
  if (value < 0 || value > 1) {
    throw ValidationException('$label must be between 0 and 1');
  }
}

double _positiveDenominator(int value) {
  if (value <= 0) return 1;
  return value.toDouble();
}

SurfaceGameplayZoneGenerationAssessmentMessage _messageForDiagnostic(
  SurfaceGameplayZoneGenerationDiagnostic diagnostic,
) {
  switch (diagnostic.kind) {
    case SurfaceGameplayZoneGenerationDiagnosticKind.extraCellsIncluded:
      return SurfaceGameplayZoneGenerationAssessmentMessage(
        severity: diagnostic.severity,
        title: 'Cellules hors surface incluses',
        description: diagnostic.message,
        diagnosticKind: diagnostic.kind,
      );
    case SurfaceGameplayZoneGenerationDiagnosticKind.tooManyRectangles:
      return SurfaceGameplayZoneGenerationAssessmentMessage(
        severity: diagnostic.severity,
        title: 'Beaucoup de zones générées',
        description: diagnostic.message,
        diagnosticKind: diagnostic.kind,
      );
    case SurfaceGameplayZoneGenerationDiagnosticKind
          .overlapsExistingGameplayZone:
      return SurfaceGameplayZoneGenerationAssessmentMessage(
        severity: diagnostic.severity,
        title: 'Zones existantes chevauchées',
        description: diagnostic.message,
        diagnosticKind: diagnostic.kind,
      );
    case SurfaceGameplayZoneGenerationDiagnosticKind.zoneIdCollisionResolved:
      return SurfaceGameplayZoneGenerationAssessmentMessage(
        severity: diagnostic.severity,
        title: 'IDs ajustés',
        description: diagnostic.message,
        diagnosticKind: diagnostic.kind,
      );
    case SurfaceGameplayZoneGenerationDiagnosticKind.noGeneratedZone:
      return SurfaceGameplayZoneGenerationAssessmentMessage(
        severity: diagnostic.severity,
        title: 'Aucune zone générée',
        description: diagnostic.message,
        diagnosticKind: diagnostic.kind,
      );
    case SurfaceGameplayZoneGenerationDiagnosticKind.emptySource:
      return SurfaceGameplayZoneGenerationAssessmentMessage(
        severity: diagnostic.severity,
        title: 'Surface vide',
        description: diagnostic.message,
        diagnosticKind: diagnostic.kind,
      );
    case SurfaceGameplayZoneGenerationDiagnosticKind.missingSurfacePresetId:
      return SurfaceGameplayZoneGenerationAssessmentMessage(
        severity: diagnostic.severity,
        title: 'Surface introuvable',
        description: diagnostic.message,
        diagnosticKind: diagnostic.kind,
      );
    case SurfaceGameplayZoneGenerationDiagnosticKind.unsupportedBehavior:
      return SurfaceGameplayZoneGenerationAssessmentMessage(
        severity: diagnostic.severity,
        title: 'Comportement non supporté',
        description: diagnostic.message,
        diagnosticKind: diagnostic.kind,
      );
  }
}

SurfaceGameplayZoneGenerationAssessmentMessage _summaryMessageForStatus(
  SurfaceGameplayZoneGenerationAssessmentStatus status,
) {
  return SurfaceGameplayZoneGenerationAssessmentMessage(
    severity: switch (status) {
      SurfaceGameplayZoneGenerationAssessmentStatus.ready =>
        SurfaceGameplayZoneGenerationDiagnosticSeverity.info,
      SurfaceGameplayZoneGenerationAssessmentStatus.needsReview =>
        SurfaceGameplayZoneGenerationDiagnosticSeverity.warning,
      SurfaceGameplayZoneGenerationAssessmentStatus.blocked =>
        SurfaceGameplayZoneGenerationDiagnosticSeverity.error,
    },
    title: _summaryTitleForStatus(status),
    description: _summaryDescriptionForStatus(status),
  );
}

String _summaryTitleForStatus(
  SurfaceGameplayZoneGenerationAssessmentStatus status,
) {
  return switch (status) {
    SurfaceGameplayZoneGenerationAssessmentStatus.ready =>
      'Plan prêt à appliquer',
    SurfaceGameplayZoneGenerationAssessmentStatus.needsReview =>
      'Plan à vérifier',
    SurfaceGameplayZoneGenerationAssessmentStatus.blocked => 'Plan bloqué',
  };
}

String _summaryDescriptionForStatus(
  SurfaceGameplayZoneGenerationAssessmentStatus status,
) {
  return switch (status) {
    SurfaceGameplayZoneGenerationAssessmentStatus.ready =>
      'La génération peut être appliquée sans alerte importante.',
    SurfaceGameplayZoneGenerationAssessmentStatus.needsReview =>
      'Vérifiez la couverture et les avertissements avant de créer les zones.',
    SurfaceGameplayZoneGenerationAssessmentStatus.blocked =>
      'Corrigez la surface ou choisissez une autre stratégie avant de continuer.',
  };
}

String _formatPercent(double ratio) {
  return '${(ratio * 100).toStringAsFixed(1)}%';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
