import '../exceptions/map_exceptions.dart';
import 'smart_tile_to_gameplay_zone_generation_plan.dart';

enum SmartTileGameplayZoneGenerationAssessmentStatus {
  ready,
  needsReview,
  blocked,
}

final class SmartTileGameplayZoneGenerationAssessmentPolicy {
  SmartTileGameplayZoneGenerationAssessmentPolicy({
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

  static final defaultPolicy = SmartTileGameplayZoneGenerationAssessmentPolicy(
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
        other is SmartTileGameplayZoneGenerationAssessmentPolicy &&
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

final class SmartTileGameplayZoneGenerationAssessmentMessage {
  const SmartTileGameplayZoneGenerationAssessmentMessage({
    required this.severity,
    required this.title,
    required this.description,
    this.diagnosticKind,
  });

  final SmartTileGameplayZoneGenerationDiagnosticSeverity severity;
  final String title;
  final String description;
  final SmartTileGameplayZoneGenerationDiagnosticKind? diagnosticKind;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SmartTileGameplayZoneGenerationAssessmentMessage &&
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

final class SmartTileGameplayZoneGenerationAssessment {
  SmartTileGameplayZoneGenerationAssessment({
    required this.plan,
    required this.status,
    required Iterable<SmartTileGameplayZoneGenerationAssessmentMessage>
        messages,
    required this.extraCellRatio,
    required this.coveragePercent,
    required this.summaryTitle,
    required this.summaryDescription,
  }) : messages =
            List<SmartTileGameplayZoneGenerationAssessmentMessage>.unmodifiable(
          messages,
        );

  final SmartTileGameplayZoneGenerationPlan plan;
  final SmartTileGameplayZoneGenerationAssessmentStatus status;
  final List<SmartTileGameplayZoneGenerationAssessmentMessage> messages;
  final double extraCellRatio;
  final double coveragePercent;
  final String summaryTitle;
  final String summaryDescription;

  bool get canApply =>
      status != SmartTileGameplayZoneGenerationAssessmentStatus.blocked;

  bool get requiresReview =>
      status == SmartTileGameplayZoneGenerationAssessmentStatus.needsReview;

  bool get hasErrors => errorMessages.isNotEmpty;

  bool get hasWarnings => warningMessages.isNotEmpty;

  List<SmartTileGameplayZoneGenerationAssessmentMessage> get infoMessages =>
      List<SmartTileGameplayZoneGenerationAssessmentMessage>.unmodifiable(
        messages.where(
          (message) =>
              message.severity ==
              SmartTileGameplayZoneGenerationDiagnosticSeverity.info,
        ),
      );

  List<SmartTileGameplayZoneGenerationAssessmentMessage> get warningMessages =>
      List<SmartTileGameplayZoneGenerationAssessmentMessage>.unmodifiable(
        messages.where(
          (message) =>
              message.severity ==
              SmartTileGameplayZoneGenerationDiagnosticSeverity.warning,
        ),
      );

  List<SmartTileGameplayZoneGenerationAssessmentMessage> get errorMessages =>
      List<SmartTileGameplayZoneGenerationAssessmentMessage>.unmodifiable(
        messages.where(
          (message) =>
              message.severity ==
              SmartTileGameplayZoneGenerationDiagnosticSeverity.error,
        ),
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SmartTileGameplayZoneGenerationAssessment &&
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

SmartTileGameplayZoneGenerationAssessment
    assessSmartTileGameplayZoneGenerationPlan(
  SmartTileGameplayZoneGenerationPlan plan, {
  SmartTileGameplayZoneGenerationAssessmentPolicy? policy,
}) {
  final effectivePolicy =
      policy ?? SmartTileGameplayZoneGenerationAssessmentPolicy.defaultPolicy;
  final coverage = plan.coverage;
  final extraCellRatio =
      coverage.extraCellCount / _positiveDenominator(coverage.sourceCellCount);
  final coveragePercent = coverage.coveredSourceCellCount /
      _positiveDenominator(coverage.sourceCellCount);
  final messages = <SmartTileGameplayZoneGenerationAssessmentMessage>[];

  var blocked = false;
  var needsReview = false;

  if (plan.generatedZones.isEmpty) {
    blocked = true;
    messages.add(
      const SmartTileGameplayZoneGenerationAssessmentMessage(
        severity: SmartTileGameplayZoneGenerationDiagnosticSeverity.error,
        title: 'Aucune zone générée',
        description: 'Le plan ne contient aucune zone gameplay à créer.',
        diagnosticKind:
            SmartTileGameplayZoneGenerationDiagnosticKind.noGeneratedZone,
      ),
    );
  }

  for (final diagnostic in plan.diagnostics) {
    switch (diagnostic.severity) {
      case SmartTileGameplayZoneGenerationDiagnosticSeverity.error:
        blocked = true;
      case SmartTileGameplayZoneGenerationDiagnosticSeverity.warning:
        needsReview = true;
      case SmartTileGameplayZoneGenerationDiagnosticSeverity.info:
        break;
    }
    messages.add(_messageForDiagnostic(diagnostic));
  }

  if (coverage.extraCellCount > 0 &&
      extraCellRatio >= effectivePolicy.maxExtraCellRatioBeforeBlocking) {
    blocked = true;
    messages.add(
      SmartTileGameplayZoneGenerationAssessmentMessage(
        severity: SmartTileGameplayZoneGenerationDiagnosticSeverity.error,
        title: 'Trop de cellules hors surface',
        description:
            '${coverage.extraCellCount} cellules hors surface seraient incluses '
            '(${_formatPercent(extraCellRatio)} de la surface source).',
        diagnosticKind:
            SmartTileGameplayZoneGenerationDiagnosticKind.extraCellsIncluded,
      ),
    );
  } else if (coverage.extraCellCount > 0 &&
      extraCellRatio > effectivePolicy.maxExtraCellRatioBeforeWarning) {
    needsReview = true;
  }

  if (coverage.zoneCount >= effectivePolicy.maxGeneratedZonesBeforeBlocking) {
    blocked = true;
    messages.add(
      SmartTileGameplayZoneGenerationAssessmentMessage(
        severity: SmartTileGameplayZoneGenerationDiagnosticSeverity.error,
        title: 'Trop de zones générées',
        description:
            '${coverage.zoneCount} zones seraient générées. Réduisez la surface '
            'ou choisissez une autre stratégie.',
        diagnosticKind:
            SmartTileGameplayZoneGenerationDiagnosticKind.tooManyRectangles,
      ),
    );
  } else if (coverage.zoneCount >
      effectivePolicy.maxGeneratedZonesBeforeWarning) {
    needsReview = true;
    messages.add(
      SmartTileGameplayZoneGenerationAssessmentMessage(
        severity: SmartTileGameplayZoneGenerationDiagnosticSeverity.warning,
        title: 'Beaucoup de zones générées',
        description:
            '${coverage.zoneCount} zones seront créées. Vérifiez que le résultat '
            'reste lisible.',
        diagnosticKind:
            SmartTileGameplayZoneGenerationDiagnosticKind.tooManyRectangles,
      ),
    );
  }

  if (coverage.isExact) {
    messages.add(
      const SmartTileGameplayZoneGenerationAssessmentMessage(
        severity: SmartTileGameplayZoneGenerationDiagnosticSeverity.info,
        title: 'Couverture exacte',
        description:
            'Toutes les cellules source sont couvertes sans cellule hors surface.',
      ),
    );
  }

  final status = blocked
      ? SmartTileGameplayZoneGenerationAssessmentStatus.blocked
      : needsReview
          ? SmartTileGameplayZoneGenerationAssessmentStatus.needsReview
          : SmartTileGameplayZoneGenerationAssessmentStatus.ready;
  messages.insert(0, _summaryMessageForStatus(status));

  return SmartTileGameplayZoneGenerationAssessment(
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

SmartTileGameplayZoneGenerationAssessmentMessage _messageForDiagnostic(
  SmartTileGameplayZoneGenerationDiagnostic diagnostic,
) {
  switch (diagnostic.kind) {
    case SmartTileGameplayZoneGenerationDiagnosticKind.extraCellsIncluded:
      return SmartTileGameplayZoneGenerationAssessmentMessage(
        severity: diagnostic.severity,
        title: 'Cellules hors surface incluses',
        description: diagnostic.message,
        diagnosticKind: diagnostic.kind,
      );
    case SmartTileGameplayZoneGenerationDiagnosticKind.tooManyRectangles:
      return SmartTileGameplayZoneGenerationAssessmentMessage(
        severity: diagnostic.severity,
        title: 'Beaucoup de zones générées',
        description: diagnostic.message,
        diagnosticKind: diagnostic.kind,
      );
    case SmartTileGameplayZoneGenerationDiagnosticKind
          .overlapsExistingGameplayZone:
      return SmartTileGameplayZoneGenerationAssessmentMessage(
        severity: diagnostic.severity,
        title: 'Zones existantes chevauchées',
        description: diagnostic.message,
        diagnosticKind: diagnostic.kind,
      );
    case SmartTileGameplayZoneGenerationDiagnosticKind.zoneIdCollisionResolved:
      return SmartTileGameplayZoneGenerationAssessmentMessage(
        severity: diagnostic.severity,
        title: 'IDs ajustés',
        description: diagnostic.message,
        diagnosticKind: diagnostic.kind,
      );
    case SmartTileGameplayZoneGenerationDiagnosticKind.noGeneratedZone:
      return SmartTileGameplayZoneGenerationAssessmentMessage(
        severity: diagnostic.severity,
        title: 'Aucune zone générée',
        description: diagnostic.message,
        diagnosticKind: diagnostic.kind,
      );
    case SmartTileGameplayZoneGenerationDiagnosticKind.emptySource:
      return SmartTileGameplayZoneGenerationAssessmentMessage(
        severity: diagnostic.severity,
        title: 'Smart Tile vide',
        description: diagnostic.message,
        diagnosticKind: diagnostic.kind,
      );
    case SmartTileGameplayZoneGenerationDiagnosticKind.missingSmartTilePresetId:
      return SmartTileGameplayZoneGenerationAssessmentMessage(
        severity: diagnostic.severity,
        title: 'Preset Smart Tile introuvable',
        description: diagnostic.message,
        diagnosticKind: diagnostic.kind,
      );
    case SmartTileGameplayZoneGenerationDiagnosticKind.missingMaterialId:
      return SmartTileGameplayZoneGenerationAssessmentMessage(
        severity: diagnostic.severity,
        title: 'Matériau Smart Tile introuvable',
        description: diagnostic.message,
        diagnosticKind: diagnostic.kind,
      );
    case SmartTileGameplayZoneGenerationDiagnosticKind.unsupportedBehavior:
      return SmartTileGameplayZoneGenerationAssessmentMessage(
        severity: diagnostic.severity,
        title: 'Comportement non supporté',
        description: diagnostic.message,
        diagnosticKind: diagnostic.kind,
      );
  }
}

SmartTileGameplayZoneGenerationAssessmentMessage _summaryMessageForStatus(
  SmartTileGameplayZoneGenerationAssessmentStatus status,
) {
  return SmartTileGameplayZoneGenerationAssessmentMessage(
    severity: switch (status) {
      SmartTileGameplayZoneGenerationAssessmentStatus.ready =>
        SmartTileGameplayZoneGenerationDiagnosticSeverity.info,
      SmartTileGameplayZoneGenerationAssessmentStatus.needsReview =>
        SmartTileGameplayZoneGenerationDiagnosticSeverity.warning,
      SmartTileGameplayZoneGenerationAssessmentStatus.blocked =>
        SmartTileGameplayZoneGenerationDiagnosticSeverity.error,
    },
    title: _summaryTitleForStatus(status),
    description: _summaryDescriptionForStatus(status),
  );
}

String _summaryTitleForStatus(
  SmartTileGameplayZoneGenerationAssessmentStatus status,
) {
  return switch (status) {
    SmartTileGameplayZoneGenerationAssessmentStatus.ready =>
      'Plan prêt à appliquer',
    SmartTileGameplayZoneGenerationAssessmentStatus.needsReview =>
      'Plan à vérifier',
    SmartTileGameplayZoneGenerationAssessmentStatus.blocked => 'Plan bloqué',
  };
}

String _summaryDescriptionForStatus(
  SmartTileGameplayZoneGenerationAssessmentStatus status,
) {
  return switch (status) {
    SmartTileGameplayZoneGenerationAssessmentStatus.ready =>
      'La génération peut être appliquée sans alerte importante.',
    SmartTileGameplayZoneGenerationAssessmentStatus.needsReview =>
      'Vérifiez la couverture et les avertissements avant de créer les zones.',
    SmartTileGameplayZoneGenerationAssessmentStatus.blocked =>
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
