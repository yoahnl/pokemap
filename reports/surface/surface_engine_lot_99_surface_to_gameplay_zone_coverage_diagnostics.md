# Lot 99 — Surface to GameplayZone Coverage / Diagnostics V0

## 1. Résumé exécutif honnête

Le Lot 99 ajoute une couche pure d'évaluation autour du plan Surface -> GameplayZone créé au Lot 98. Le nouveau code ne crée aucune zone dans une map réelle : il lit un `SurfaceGameplayZoneGenerationPlan`, produit un statut produit (`ready`, `needsReview`, `blocked`), calcule `extraCellRatio` et `coveragePercent`, expose des messages utilisateur filtrables par sévérité, et applique une policy de seuils UX configurable.

Le périmètre reste volontairement serré : `MapGameplayZone` est réutilisé, `SurfaceLayer` reste visuel, aucun JSON n'est ajouté, aucun runtime/editor/gameplay/battle n'est touché. Les tests ciblés, les régressions utiles, le test complet `map_core` et l'analyse ciblée passent.

## 2. Périmètre

Inclus dans le Lot 99 :

- création de `surface_to_gameplay_zone_generation_assessment.dart` dans `map_core` ;
- création de `surface_to_gameplay_zone_generation_assessment_test.dart` ;
- export public de l'assessment via `packages/map_core/lib/map_core.dart` ;
- rapport Lot 99.

Hors périmètre respecté :

- pas de modification `MapData` ;
- pas de modification `MapGameplayZone` ;
- pas de modification `SurfaceLayer` ou `SurfaceCellPlacement` ;
- pas de `ProjectManifest`, JSON, build_runner, editor, runtime, gameplay ou battle ;
- pas de gameplay surf/tall grass/hazard runtime.

Changements préexistants : aucun changement local au Gate 0.

Changements du Lot 99 : les deux fichiers Dart de l'assessment, l'export barrel `map_core.dart`, et ce rapport.

## 3. Gate 0 — status initial

Commandes exécutées avant modification :

```text
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
```

Sorties :

```text
PWD
/Users/karim/Project/pokemonProject
BRANCH
main
STATUS

DIFF_STAT

LOG
70b0f90d lot 98/95: Surface Gameplay - Surface to Gameplay Zone Generation Plan
8d62718f lot 97/95: Surface Gameplay - Surface Gameplay Zone Authoring Workflow Spec
ac7984f2 lot 96/95: Surface Gameplay - Zones Bridge Decision Report
a4d62f39 lot 94/95: Surface Gameplay
83654389 feat: add surface runtime test files and golden slice reports
1f900e67 feat(map_runtime): render surface layers
da2b244d feat(map_runtime): add surface runtime resolver
32fbb0b5 feat(map_editor): improve surface mapping editor
d5561df7 feat(map_editor): edit surface role animation mapping
935a0036 feat(map_editor): animate surface editor previews
```

## 4. Context Mode usage

Context Mode MCP a été utilisé pour l'audit, les recherches repo, les sorties de tests larges, le test complet `map_core`, l'analyse ciblée, et les résumés de status/diff.

Le binaire shell `ctx` n'est pas disponible dans ce terminal :

```text
ctx --help && ctx stats
zsh:1: command not found: ctx
```

Le serveur MCP Context Mode est disponible :

```text
context-mode doctor
- [x] Server test: PASS
- [x] FTS5 / SQLite: PASS
- [x] Hook script: PASS — /opt/homebrew/lib/node_modules/context-mode/hooks/pretooluse.mjs
- [x] Version: v1.0.100
```

Stats compactes disponibles via les appels MCP :

```text
Audit Lot 99 : 10 commandes, 4048 lignes, 283.1 KB indexés, 55 sections.
Tests/analyze Lot 99 : 6 commandes, 1362 lignes, 210.0 KB indexés, 7 sections.
Sorties finales compactes : capturées via ctx_execute avec codes de sortie.
```

## 5. Audit Lot 98

Commandes d'audit lancées :

```text
rg -n "SurfaceGameplayZoneGenerationPlan|SurfaceGameplayZoneCoverageReport|SurfaceGameplayZoneGenerationDiagnostic|SurfaceGameplayZoneGenerationStrategy|SurfaceGameplayZoneBehaviorDraft|createSurfaceGameplayZoneGenerationPlan" packages/map_core/lib packages/map_core/test reports/surface
```

Fichiers lus en priorité :

```text
packages/map_core/lib/src/operations/surface_to_gameplay_zone_generation_plan.dart
packages/map_core/test/surface_to_gameplay_zone_generation_plan_test.dart
reports/surface/surface_engine_lot_98_surface_to_gameplay_zone_generation_plan.md
```

Findings importants :

- `SurfaceGameplayZoneGenerationPlan` est déjà immuable côté listes (`generatedZones`, `rectangles`, `diagnostics`).
- `SurfaceGameplayZoneCoverageReport` expose déjà `sourceCellCount`, `coveredSourceCellCount`, `missingSourceCellCount`, `extraCellCount`, `zoneCount`, `isExact`.
- Les diagnostics existants couvrent `emptySource`, `missingSurfacePresetId`, `noGeneratedZone`, `extraCellsIncluded`, `tooManyRectangles`, `overlapsExistingGameplayZone`, `unsupportedBehavior`, `zoneIdCollisionResolved`.
- Le Lot 98 ne doit pas être recodé : l'assessment se pose au-dessus du plan existant.

## 6. Audit diagnostics / presentation existants

Commandes d'audit lancées :

```text
rg -n "DiagnosticsPresentation|Presentation|Summary|Assessment|Readiness|hasBlocking|hasWarnings|severity|warning|error|info|message|label" packages/map_core/lib/src/operations packages/map_core/test
```

Fichiers lus en priorité :

```text
packages/map_core/lib/src/operations/surface_catalog_diagnostics_presentation.dart
packages/map_core/lib/src/operations/surface_catalog_diagnostics_summary.dart
```

Findings importants :

- Les diagnostics Surface Catalog utilisent déjà une séparation summary / presentation.
- Les conventions locales favorisent des classes finales pures, des listes `List.unmodifiable`, et des helpers booléens (`hasErrors`, `hasWarnings`).
- Les messages de présentation restent dérivés des diagnostics au lieu de modifier les diagnostics source.
- L'assessment Lot 99 réutilise cette logique sans introduire de dépendance editor/runtime.

## 7. Décision de design

Décision : créer une couche pure `SurfaceGameplayZoneGenerationAssessment` au-dessus du plan Lot 98.

Cette couche :

- ne mute pas le plan ;
- ne mute pas les `MapGameplayZone` générées ;
- ne crée aucune zone dans une `MapData` ;
- réutilise `SurfaceGameplayZoneGenerationDiagnosticSeverity` ;
- ajoute des seuils UX configurables ;
- produit des messages prêts à présenter dans une UI future.

Décision importante : les seuils sont des garde-fous UX, pas des règles moteur. Le plan reste la source technique ; l'assessment traduit ce plan en readiness produit.

## 8. Policy / thresholds

Modèle créé : `SurfaceGameplayZoneGenerationAssessmentPolicy`.

Valeurs par défaut :

```text
maxExtraCellRatioBeforeWarning = 0.0
maxExtraCellRatioBeforeBlocking = 0.25
maxGeneratedZonesBeforeWarning = 8
maxGeneratedZonesBeforeBlocking = 32
```

Validations :

- ratios entre 0 et 1 ;
- ratio blocking >= ratio warning ;
- thresholds de zones strictement positifs ;
- threshold zones blocking >= threshold zones warning.

## 9. Assessment status

Enum créé : `SurfaceGameplayZoneGenerationAssessmentStatus`.

Valeurs :

```text
ready       = plan applicable sans alerte importante
needsReview = plan applicable mais demande attention utilisateur
blocked     = plan non applicable sans correction
```

Règles principales :

- `ready` si aucun diagnostic bloquant, aucune cellule extra, zone count raisonnable, pas de warning significatif ;
- `needsReview` si warnings non bloquants : cellules extra sous seuil bloquant, overlaps, id collision resolved, trop de rectangles sous seuil bloquant ;
- `blocked` si diagnostic error, aucune zone, ratio extra >= seuil bloquant, zoneCount >= seuil bloquant.

## 10. Messages utilisateur

Modèle créé : `SurfaceGameplayZoneGenerationAssessmentMessage`.

Champs :

```text
severity
title
description
diagnosticKind optionnel
```

Messages couverts :

- `Plan prêt à appliquer` ;
- `Plan à vérifier` ;
- `Plan bloqué` ;
- `Couverture exacte` ;
- `Cellules hors surface incluses` ;
- `Trop de cellules hors surface` ;
- `Beaucoup de zones générées` ;
- `Trop de zones générées` ;
- `Zones existantes chevauchées` ;
- `IDs ajustés` ;
- `Aucune zone générée` ;
- `Surface vide` ;
- `Surface introuvable` ;
- `Comportement non supporté`.

## 11. Fonction assessSurfaceGameplayZoneGenerationPlan

Fonction créée :

```text
assessSurfaceGameplayZoneGenerationPlan(plan, {policy})
```

Elle retourne un `SurfaceGameplayZoneGenerationAssessment` contenant :

- le plan source ;
- le status ;
- les messages ;
- `extraCellRatio` ;
- `coveragePercent` ;
- `summaryTitle` ;
- `summaryDescription` ;
- helpers `canApply`, `requiresReview`, `hasErrors`, `hasWarnings`, `infoMessages`, `warningMessages`, `errorMessages`.

Contraintes respectées :

- pas de mutation du plan ;
- pas de mutation des generatedZones ;
- pas de mutation de map ;
- pas de dépendance editor/runtime ;
- déterministe et testé.

## 12. Tests lancés

Commandes lancées :

```text
cd packages/map_core && dart test --no-color test/surface_to_gameplay_zone_generation_assessment_test.dart --reporter expanded
cd packages/map_core && dart test --no-color test/surface_to_gameplay_zone_generation_plan_test.dart --reporter expanded
cd packages/map_core && dart test --no-color test/map_gameplay_zone_validation_test.dart --reporter expanded
cd packages/map_core && dart test --no-color test/surface_layer_placements_test.dart --reporter expanded
cd packages/map_core && dart test --no-color --reporter expanded
```

## 13. Résultats

Sorties finales exactes des tests :

```text
## assessment
00:00 +10: assessment messages and immutability assessment does not mutate the source plan
00:00 +11: assessment messages and immutability assessment messages and assessment support value equality
00:00 +12: All tests passed!
EXIT_CODE=0

## generation_plan
00:00 +14: diagnostics and immutability plan lists are immutable
00:00 +15: diagnostics and immutability coverage and diagnostics support value equality
00:00 +16: All tests passed!
EXIT_CODE=0

## gameplay_zone_validation
00:00 +0: loading test/map_gameplay_zone_validation_test.dart
00:00 +0: Map gameplay zone battle background validation rejects encounter zone backgrounds that escape the project
00:00 +1: All tests passed!
EXIT_CODE=0

## surface_layer_placements
00:00 +12: SurfaceLayer placement operations resizeMapData keeps in-bounds SurfaceLayer placements only
00:00 +13: SurfaceLayer placement operations generic MapLayer helpers tolerate SurfaceLayer
00:00 +14: All tests passed!
EXIT_CODE=0

## map_core_full
00:02 +1281: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 30. public surface export: ProjectSurfaceCatalog from map_core
00:02 +1282: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 31. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 33 -> 49)
00:02 +1283: All tests passed!
EXIT_CODE=0
```

## 14. Analyse lancée

Commande lancée :

```text
cd packages/map_core && dart analyze lib/src/operations/surface_to_gameplay_zone_generation_assessment.dart test/surface_to_gameplay_zone_generation_assessment_test.dart lib/map_core.dart
```

## 15. Résultats analyze

Sortie exacte :

```text
Analyzing surface_to_gameplay_zone_generation_assessment.dart, surface_to_gameplay_zone_generation_assessment_test.dart, map_core.dart...
No issues found!
EXIT_CODE=0
```

## 16. Fichiers créés

```text
packages/map_core/lib/src/operations/surface_to_gameplay_zone_generation_assessment.dart
packages/map_core/test/surface_to_gameplay_zone_generation_assessment_test.dart
reports/surface/surface_engine_lot_99_surface_to_gameplay_zone_coverage_diagnostics.md
```

## 17. Fichiers modifiés

```text
packages/map_core/lib/map_core.dart
```

## 18. Fichiers supprimés

```text
Aucun fichier supprimé.
```

## 19. Contenu complet des fichiers créés

### packages/map_core/lib/src/operations/surface_to_gameplay_zone_generation_assessment.dart

```dart
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
```

### packages/map_core/test/surface_to_gameplay_zone_generation_assessment_test.dart

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SurfaceGameplayZoneGenerationAssessmentPolicy', () {
    test('default policy is valid', () {
      expect(
        SurfaceGameplayZoneGenerationAssessmentPolicy
            .defaultPolicy.maxExtraCellRatioBeforeWarning,
        0,
      );
      expect(
        SurfaceGameplayZoneGenerationAssessmentPolicy
            .defaultPolicy.maxExtraCellRatioBeforeBlocking,
        0.25,
      );
      expect(
        SurfaceGameplayZoneGenerationAssessmentPolicy
            .defaultPolicy.maxGeneratedZonesBeforeWarning,
        8,
      );
      expect(
        SurfaceGameplayZoneGenerationAssessmentPolicy
            .defaultPolicy.maxGeneratedZonesBeforeBlocking,
        32,
      );
    });

    test('rejects invalid ratios and thresholds', () {
      expect(
        () => SurfaceGameplayZoneGenerationAssessmentPolicy(
          maxExtraCellRatioBeforeWarning: -0.1,
          maxExtraCellRatioBeforeBlocking: 0.25,
          maxGeneratedZonesBeforeWarning: 8,
          maxGeneratedZonesBeforeBlocking: 32,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => SurfaceGameplayZoneGenerationAssessmentPolicy(
          maxExtraCellRatioBeforeWarning: 0,
          maxExtraCellRatioBeforeBlocking: 1.1,
          maxGeneratedZonesBeforeWarning: 8,
          maxGeneratedZonesBeforeBlocking: 32,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => SurfaceGameplayZoneGenerationAssessmentPolicy(
          maxExtraCellRatioBeforeWarning: 0.5,
          maxExtraCellRatioBeforeBlocking: 0.25,
          maxGeneratedZonesBeforeWarning: 8,
          maxGeneratedZonesBeforeBlocking: 32,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => SurfaceGameplayZoneGenerationAssessmentPolicy(
          maxExtraCellRatioBeforeWarning: 0,
          maxExtraCellRatioBeforeBlocking: 0.25,
          maxGeneratedZonesBeforeWarning: 0,
          maxGeneratedZonesBeforeBlocking: 32,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => SurfaceGameplayZoneGenerationAssessmentPolicy(
          maxExtraCellRatioBeforeWarning: 0,
          maxExtraCellRatioBeforeBlocking: 0.25,
          maxGeneratedZonesBeforeWarning: 8,
          maxGeneratedZonesBeforeBlocking: 7,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('assessSurfaceGameplayZoneGenerationPlan ready', () {
    test('marks an exact greedy rectangle plan ready', () {
      final assessment = assessSurfaceGameplayZoneGenerationPlan(
        _planForCells(
          const [
            GridPos(x: 0, y: 0),
            GridPos(x: 1, y: 0),
            GridPos(x: 0, y: 1),
            GridPos(x: 1, y: 1),
          ],
          strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
        ),
      );

      expect(
        assessment.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.ready,
      );
      expect(assessment.canApply, isTrue);
      expect(assessment.requiresReview, isFalse);
      expect(assessment.extraCellRatio, 0);
      expect(assessment.coveragePercent, 1);
      expect(assessment.summaryTitle, 'Plan prêt à appliquer');
      expect(
        assessment.messages.map((message) => message.title),
        contains('Couverture exacte'),
      );
    });
  });

  group('assessSurfaceGameplayZoneGenerationPlan needsReview', () {
    test('marks bounding-box extra cells as needsReview below blocking ratio',
        () {
      final assessment = assessSurfaceGameplayZoneGenerationPlan(
        _planForCells(
          const [
            GridPos(x: 0, y: 0),
            GridPos(x: 1, y: 0),
            GridPos(x: 2, y: 0),
            GridPos(x: 0, y: 1),
            GridPos(x: 1, y: 1),
          ],
          strategy: SurfaceGameplayZoneGenerationStrategy.boundingBox,
        ),
      );

      expect(
        assessment.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.needsReview,
      );
      expect(assessment.canApply, isTrue);
      expect(assessment.requiresReview, isTrue);
      expect(assessment.extraCellRatio, closeTo(1 / 5, 0.0001));
      expect(
        assessment.warningMessages.map((message) => message.title),
        contains('Cellules hors surface incluses'),
      );
    });

    test('presents overlap and id collision diagnostics for review', () {
      final plan = createSurfaceGameplayZoneGenerationPlan(
        source: _source(const [GridPos(x: 0, y: 0)]),
        behavior: _encounterBehavior(),
        strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
        zoneIdPrefix: 'grass',
        zoneNamePrefix: 'Grass',
        existingZones: const [
          MapGameplayZone(
            id: 'grass',
            kind: GameplayZoneKind.encounter,
            area: MapRect(
              pos: GridPos(x: 0, y: 0),
              size: GridSize(width: 1, height: 1),
            ),
          ),
        ],
      );
      final assessment = assessSurfaceGameplayZoneGenerationPlan(plan);

      expect(
        assessment.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.needsReview,
      );
      expect(
        assessment.warningMessages.map((message) => message.title),
        contains('Zones existantes chevauchées'),
      );
      expect(
        assessment.infoMessages.map((message) => message.title),
        contains('IDs ajustés'),
      );
    });

    test('marks too many rectangles warning as needsReview under blocking', () {
      final plan = createSurfaceGameplayZoneGenerationPlan(
        source: _source(
          const [
            GridPos(x: 0, y: 0),
            GridPos(x: 2, y: 0),
            GridPos(x: 4, y: 0),
          ],
        ),
        behavior: _encounterBehavior(),
        strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
        zoneIdPrefix: 'grass',
        zoneNamePrefix: 'Grass',
        maxRectanglesWarningThreshold: 2,
      );
      final assessment = assessSurfaceGameplayZoneGenerationPlan(plan);

      expect(
        assessment.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.needsReview,
      );
      expect(
        assessment.warningMessages.map((message) => message.title),
        contains('Beaucoup de zones générées'),
      );
    });
  });

  group('assessSurfaceGameplayZoneGenerationPlan blocked', () {
    test('blocks when extra cell ratio reaches blocking threshold', () {
      final assessment = assessSurfaceGameplayZoneGenerationPlan(
        _planForCells(
          const [
            GridPos(x: 0, y: 0),
            GridPos(x: 3, y: 0),
          ],
          strategy: SurfaceGameplayZoneGenerationStrategy.boundingBox,
        ),
      );

      expect(
        assessment.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
      );
      expect(assessment.canApply, isFalse);
      expect(assessment.requiresReview, isFalse);
      expect(
        assessment.errorMessages.map((message) => message.title),
        contains('Plan bloqué'),
      );
      expect(
        assessment.errorMessages.map((message) => message.title),
        contains('Trop de cellules hors surface'),
      );
    });

    test('blocks when generated zone count reaches blocking threshold', () {
      final assessment = assessSurfaceGameplayZoneGenerationPlan(
        _planForCells(
          const [
            GridPos(x: 0, y: 0),
            GridPos(x: 2, y: 0),
            GridPos(x: 4, y: 0),
          ],
          strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
        ),
        policy: SurfaceGameplayZoneGenerationAssessmentPolicy(
          maxExtraCellRatioBeforeWarning: 0,
          maxExtraCellRatioBeforeBlocking: 0.25,
          maxGeneratedZonesBeforeWarning: 2,
          maxGeneratedZonesBeforeBlocking: 3,
        ),
      );

      expect(
        assessment.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
      );
      expect(
        assessment.errorMessages.map((message) => message.title),
        contains('Trop de zones générées'),
      );
    });

    test('blocks a plan with an existing error diagnostic or no zones', () {
      final base = _planForCells(
        const [GridPos(x: 0, y: 0)],
        strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
      );
      final errored = SurfaceGameplayZoneGenerationPlan(
        source: base.source,
        behavior: base.behavior,
        strategy: base.strategy,
        generatedZones: base.generatedZones,
        rectangles: base.rectangles,
        coverage: base.coverage,
        diagnostics: const [
          SurfaceGameplayZoneGenerationDiagnostic(
            severity: SurfaceGameplayZoneGenerationDiagnosticSeverity.error,
            kind: SurfaceGameplayZoneGenerationDiagnosticKind.noGeneratedZone,
            message: 'No zones.',
          ),
        ],
      );
      final empty = SurfaceGameplayZoneGenerationPlan(
        source: base.source,
        behavior: base.behavior,
        strategy: base.strategy,
        generatedZones: const [],
        rectangles: const [],
        coverage: const SurfaceGameplayZoneCoverageReport(
          sourceCellCount: 1,
          coveredSourceCellCount: 0,
          missingSourceCellCount: 1,
          extraCellCount: 0,
          zoneCount: 0,
        ),
        diagnostics: const [],
      );

      expect(
        assessSurfaceGameplayZoneGenerationPlan(errored).status,
        SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
      );
      expect(
        assessSurfaceGameplayZoneGenerationPlan(empty).status,
        SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
      );
    });
  });

  group('assessment messages and immutability', () {
    test('messages are immutable and helper filters are stable', () {
      final assessment = assessSurfaceGameplayZoneGenerationPlan(
        _planForCells(
          const [
            GridPos(x: 0, y: 0),
            GridPos(x: 1, y: 0),
            GridPos(x: 2, y: 0),
            GridPos(x: 0, y: 1),
            GridPos(x: 1, y: 1),
          ],
          strategy: SurfaceGameplayZoneGenerationStrategy.boundingBox,
        ),
      );

      expect(() => assessment.messages.clear(), throwsUnsupportedError);
      expect(
        assessment.warningMessages.map((message) => message.title),
        contains('Cellules hors surface incluses'),
      );
      expect(assessment.errorMessages, isEmpty);
      expect(assessment.infoMessages, isEmpty);
    });

    test('assessment does not mutate the source plan', () {
      final plan = createSurfaceGameplayZoneGenerationPlan(
        source: _source(const [GridPos(x: 0, y: 0)]),
        behavior: _encounterBehavior(),
        strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
        zoneIdPrefix: 'grass',
        zoneNamePrefix: 'Grass',
      );
      final originalZones = List<MapGameplayZone>.of(plan.generatedZones);
      final originalDiagnostics =
          List<SurfaceGameplayZoneGenerationDiagnostic>.of(plan.diagnostics);

      final assessment = assessSurfaceGameplayZoneGenerationPlan(plan);

      expect(plan.generatedZones, originalZones);
      expect(plan.diagnostics, originalDiagnostics);
      expect(assessment.plan, same(plan));
      expect(assessment.plan.generatedZones.single.id, 'grass');
    });

    test('assessment messages and assessment support value equality', () {
      final first = assessSurfaceGameplayZoneGenerationPlan(
        _planForCells(
          const [GridPos(x: 0, y: 0)],
          strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
        ),
      );
      final second = assessSurfaceGameplayZoneGenerationPlan(
        _planForCells(
          const [GridPos(x: 0, y: 0)],
          strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
        ),
      );

      expect(
        const SurfaceGameplayZoneGenerationAssessmentMessage(
          severity: SurfaceGameplayZoneGenerationDiagnosticSeverity.info,
          title: 'Couverture exacte',
          description: 'Toutes les cellules source sont couvertes.',
        ),
        const SurfaceGameplayZoneGenerationAssessmentMessage(
          severity: SurfaceGameplayZoneGenerationDiagnosticSeverity.info,
          title: 'Couverture exacte',
          description: 'Toutes les cellules source sont couvertes.',
        ),
      );
      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });
  });
}

SurfaceGameplayZoneGenerationPlan _planForCells(
  List<GridPos> cells, {
  required SurfaceGameplayZoneGenerationStrategy strategy,
}) {
  return createSurfaceGameplayZoneGenerationPlan(
    source: _source(cells),
    behavior: _encounterBehavior(),
    strategy: strategy,
    zoneIdPrefix: 'grass',
    zoneNamePrefix: 'Grass',
  );
}

SurfaceGameplayZoneGenerationSource _source(List<GridPos> cells) {
  return SurfaceGameplayZoneGenerationSource(
    surfaceLayerId: 'surfaces',
    surfaceLayerName: 'Surfaces',
    surfacePresetId: 'tall_grass',
    cells: cells,
  );
}

SurfaceGameplayZoneBehaviorDraft _encounterBehavior() {
  return SurfaceGameplayZoneBehaviorDraft.encounter(
    const EncounterZonePayload(
      encounterTableId: 'route-1',
      encounterKind: EncounterKind.walk,
    ),
  );
}
```

### reports/surface/surface_engine_lot_99_surface_to_gameplay_zone_coverage_diagnostics.md

```text
Le rapport lui-même n'est pas recopié récursivement, conformément à l'exception demandée.
```

## 20. Contenu complet des fichiers modifiés

### packages/map_core/lib/map_core.dart

```dart
library map_core;

export 'src/models/enums.dart';
export 'src/models/geometry.dart';
export 'src/models/tileset.dart';
export 'src/models/map_data.dart';
export 'src/models/element_collision_profile.dart';
export 'src/models/map_entity_payloads.dart';
export 'src/models/map_entity_editor_visual.dart';
export 'src/models/map_gameplay_zone_payloads.dart';
export 'src/models/map_layer.dart';
export 'src/models/map_metadata.dart';
export 'src/models/project_manifest.dart';
export 'src/models/save_data.dart';
export 'src/models/game_state.dart';
export 'src/models/pokemon_move.dart';
export 'src/models/pokemon_move_accuracy.dart';
export 'src/models/pokemon_move_effect.dart';
export 'src/models/script_asset.dart';
export 'src/models/script_conditions.dart';
export 'src/models/map_event_definition.dart';
export 'src/models/project_trainer.dart';
export 'src/models/scenario_asset.dart';
export 'src/models/visual_frame_json.dart';
export 'src/models/surface.dart';
export 'src/models/surface_catalog.dart';
export 'src/operations/map_resize.dart';
export 'src/operations/map_paint.dart';
export 'src/operations/map_collision.dart';
export 'src/operations/map_path.dart';
export 'src/operations/map_terrain.dart';
export 'src/operations/map_terrain_autotile.dart';
export 'src/operations/tile_visual_frame_timeline.dart';
export 'src/operations/tile_visual_frame_vertical_atlas.dart';
export 'src/operations/path_variant_vertical_atlas_mapping.dart';
export 'src/operations/path_preset_vertical_atlas_builder.dart';
export 'src/operations/terrain_path_variant_vertical_atlas_layout.dart';
export 'src/operations/standard_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_water_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_lava_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_ice_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_tall_grass_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_surface_preset_builder.dart';
export 'src/operations/surface_catalog_diagnostics.dart';
export 'src/operations/surface_catalog_authoring_diagnostics.dart';
export 'src/operations/surface_catalog_diagnostics_summary.dart';
export 'src/operations/surface_catalog_diagnostics_presentation.dart';
export 'src/operations/surface_atlas_json_codec.dart';
export 'src/operations/surface_animation_frame_json_codec.dart';
export 'src/operations/surface_animation_timeline_json_codec.dart';
export 'src/operations/project_surface_animation_json_codec.dart';
export 'src/operations/surface_variant_animation_ref_json_codec.dart';
export 'src/operations/surface_variant_animation_ref_set_json_codec.dart';
export 'src/operations/project_surface_preset_json_codec.dart';
export 'src/operations/project_surface_catalog_json_codec.dart';
export 'src/operations/project_manifest_surface_catalog_operations.dart';
export 'src/operations/surface_studio_read_model.dart';
export 'src/operations/legacy_path_surface_view.dart';
export 'src/operations/legacy_terrain_surface_view.dart';
export 'src/operations/legacy_project_surface_catalog_view.dart';
export 'src/operations/legacy_surface_catalog_diagnostics.dart';
export 'src/operations/legacy_surface_usage_view.dart';
export 'src/operations/legacy_surface_usage_diagnostics.dart';
export 'src/operations/legacy_surface_audit_report.dart';
export 'src/operations/path_animation_rules.dart';
export 'src/operations/element_collision_mask_codec.dart';
export 'src/collision/pixel_rect.dart';
export 'src/collision/player_collision_conventions_v1.dart';
export 'src/collision/element_collision_legacy_migration.dart';
export 'src/operations/map_layers.dart';
export 'src/operations/surface_layer_placements.dart';
export 'src/operations/surface_to_gameplay_zone_generation_assessment.dart';
export 'src/operations/surface_to_gameplay_zone_generation_plan.dart';
export 'src/operations/surface_variant_role_resolver.dart';
export 'src/operations/map_connections.dart';
export 'src/operations/map_entities.dart';
export 'src/operations/map_events.dart';
export 'src/operations/map_placed_elements.dart';
export 'src/operations/map_placed_element_animation.dart';
export 'src/operations/map_entity_collision_footprint.dart';
export 'src/operations/map_triggers.dart';
export 'src/operations/map_warps.dart';
export 'src/operations/map_gameplay_zones.dart';
export 'src/operations/map_map_metadata.dart';
export 'src/operations/game_state_persistence.dart';
export 'src/operations/tileset_library_tree.dart';
export 'src/operations/dialogue_library_tree.dart';
export 'src/operations/project_dialogue_refs.dart';
export 'src/validation/validators.dart';
export 'src/validation/dialogue_validation.dart';
export 'src/validation/entity_editor_visual_validation.dart';
export 'src/exceptions/map_exceptions.dart';
export 'src/io/legacy_editor_json_compat.dart';
```

## 21. Git status final

Status final exact après création de ce rapport :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/surface_to_gameplay_zone_generation_assessment.dart
?? packages/map_core/test/surface_to_gameplay_zone_generation_assessment_test.dart
?? reports/surface/surface_engine_lot_99_surface_to_gameplay_zone_coverage_diagnostics.md
```

Diff stat final tracked :

```text
 packages/map_core/lib/map_core.dart | 1 +
 1 file changed, 1 insertion(+)
```

Les fichiers créés non suivis sont listés dans le status final et dans la section fichiers créés.

## 22. Périmètre explicitement non touché

Confirmation :

```text
MapData non modifié
MapGameplayZone non modifié
SurfaceLayer non modifié
SurfaceCellPlacement non modifié
ProjectManifest non modifié
surface.dart non modifié
surface_catalog.dart non modifié
map_layer.dart non modifié
map_gameplay_zone_payloads.dart non modifié
map_editor non modifié
map_runtime non modifié
map_gameplay non modifié
map_battle non modifié
aucun JSON
aucun generated/build_runner
aucun gameplay surf codé
aucun tall grass encounter codé
aucune collision Surface codée
aucun Surface Studio
aucun Surface Painter
aucune migration legacy
```

Note : `map_core.dart` est modifié uniquement pour exporter la nouvelle opération pure.

## 23. ctx stats

Le binaire `ctx` n'est pas disponible dans le shell de cette session, donc `ctx stats` CLI ne peut pas produire de sortie. Context Mode MCP a bien été utilisé.

Résumé compact disponible :

```text
ctx CLI: unavailable (zsh:1: command not found: ctx)
Context Mode MCP doctor: PASS, version v1.0.100
Audit batch: 10 commandes, 4048 lignes, 283.1 KB indexés, 55 sections
Tests/analyze batch: 6 commandes, 1362 lignes, 210.0 KB indexés, 7 sections
```

## 24. Limites restantes

- L'assessment reste une couche de présentation pure : il ne choisit pas automatiquement une stratégie alternative.
- Les messages sont prêts pour une UI future, mais aucune UI n'est branchée dans ce lot.
- Les seuils par défaut sont prudents et devront être validés en contexte d'usage réel au Lot 100.
- Les diagnostics ne couvrent pas encore de filtre `surfacePresetId` dans `MapGameplayZone`, car ce modèle n'existe pas et ne doit pas être ajouté maintenant.

## 25. Auto-critique

- Est-ce qu'un assessment pur du plan Surface -> GameplayZone existe ? Oui.
- Est-ce que le plan du Lot 98 reste non muté ? Oui.
- Est-ce que ready / needsReview / blocked existent ? Oui.
- Est-ce que les seuils UX sont configurables ? Oui.
- Est-ce que les extra cells sont évaluées ? Oui.
- Est-ce que too many rectangles est évalué ? Oui.
- Est-ce que overlaps existing zones est présenté ? Oui.
- Est-ce que les messages utilisateur sont prêts pour l'UI future ? Oui.
- Est-ce qu'aucune map réelle n'est mutée ? Oui.
- Est-ce que SurfaceLayer reste visuel ? Oui.
- Est-ce que MapGameplayZone est réutilisé au lieu de dupliqué ? Oui.
- Est-ce que les tests ciblés passent ? Oui.
- Est-ce que map_core complet passe ? Oui.
- Est-ce que dart analyze ciblé passe ? Oui.
- Est-ce que Context Mode a été utilisé agressivement ? Oui, via MCP ; le CLI `ctx` est indisponible.
- Est-ce que ctx stats est inclus ? Oui, avec les stats MCP disponibles et l'indisponibilité CLI documentée.
- Est-ce que le contenu complet des fichiers créés/modifiés est copié dans le rapport ? Oui, sauf le rapport lui-même par exception explicite.
- Est-ce qu'un Lot 99-bis est nécessaire ? Non. Le lot couvre l'assessment demandé, les seuils, messages, tests, analyse et rapport.

## 26. Regard critique sur le prompt

Le prompt est très cadrant et utile. La contrainte importante est la coexistence entre Context Mode et Evidence Pack complet : elle est saine, car Context Mode aide l'agent pendant le travail mais ne suffit pas au reviewer humain. Le seul point ambigu est `ctx stats` quand le binaire CLI n'est pas disponible alors que le MCP l'est ; le rapport documente cette différence et fournit les statistiques MCP exploitables.
