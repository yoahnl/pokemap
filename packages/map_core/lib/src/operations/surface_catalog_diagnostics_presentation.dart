// Surface catalog — modèle de présentation auteur (Lot 38).
//
// Brique **pure** pour une future panneau « Surface Diagnostics » ou équivalent,
// **sans** dépendre de Flutter, sans l10n, sans widgets : on structure ce que le
// rapport, le summary et le découpage par [SurfaceCatalogDiagnosticSeverity]
// impliquent déjà, pour qu’une couche UI puisse s’y brancher plus tard.
//
// * Ne **remplace** ni [SurfaceCatalogDiagnosticsReport] ni
//   [SurfaceCatalogDiagnosticsSummary] : ce sont des champs de la présentation
//   pour garder le lien avec la source d’analyse.
// * Regroupement **seulement** par severity : deux sections possibles, dans
//   l’ordre volontaire [errors] puis [warnings] (même si le rapport mélangeait
//   warning/error dans un autre ordre).
// * Aucun [SurfaceCatalogDiagnostic] n’est **créé** ni **cloné** ici (références
//   héritées du rapport) ; l’ordre relatif des entrées d’une même severity dans
//   le rapport d’origine est **préservé** dans chaque sous-liste.

import 'package:meta/meta.dart' show immutable;

import 'surface_catalog_diagnostics.dart';
import 'surface_catalog_diagnostics_summary.dart';

// --- Comparaison ordonnée (égalité des listes) ---

bool _diagnosticsListEqualInOrder(
  List<SurfaceCatalogDiagnostic> a,
  List<SurfaceCatalogDiagnostic> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

bool _sectionListEqualInOrder(
  List<SurfaceCatalogDiagnosticsPresentationSection> a,
  List<SurfaceCatalogDiagnosticsPresentationSection> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// Axe d’en-tête de panneau : erreurs, puis avertissements.
enum SurfaceCatalogDiagnosticsPresentationSectionKind {
  errors,
  warnings,
}

/// Un **groupe non vide** de diagnostics d’une même [SurfaceCatalogDiagnosticSeverity]
/// (erreurs ou avertissements) pour l’affichage structuré.
@immutable
final class SurfaceCatalogDiagnosticsPresentationSection {
  SurfaceCatalogDiagnosticsPresentationSection({
    required this.kind,
    required this.severity,
    required List<SurfaceCatalogDiagnostic> diagnostics,
  }) : diagnostics = List<SurfaceCatalogDiagnostic>.unmodifiable(
          List<SurfaceCatalogDiagnostic>.from(diagnostics),
        ) {
    assert(
      (kind == SurfaceCatalogDiagnosticsPresentationSectionKind.errors &&
              severity == SurfaceCatalogDiagnosticSeverity.error) ||
          (kind == SurfaceCatalogDiagnosticsPresentationSectionKind.warnings &&
              severity == SurfaceCatalogDiagnosticSeverity.warning),
      'kind/severity cohérents pour errors|warnings',
    );
  }

  final SurfaceCatalogDiagnosticsPresentationSectionKind kind;
  final SurfaceCatalogDiagnosticSeverity severity;
  final List<SurfaceCatalogDiagnostic> diagnostics;

  int get count => diagnostics.length;
  bool get isEmpty => diagnostics.isEmpty;
  bool get isNotEmpty => diagnostics.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceCatalogDiagnosticsPresentationSection &&
          other.kind == kind &&
          other.severity == severity &&
          _diagnosticsListEqualInOrder(
            other.diagnostics,
            diagnostics,
          );

  @override
  int get hashCode => Object.hash(
        kind,
        severity,
        Object.hashAll(diagnostics),
      );
}

/// Vue prête auteur (rapport + summary + plages errors/warnings + sections).
@immutable
final class SurfaceCatalogDiagnosticsPresentation {
  SurfaceCatalogDiagnosticsPresentation({
    required this.report,
    required this.summary,
    required List<SurfaceCatalogDiagnostic> errors,
    required List<SurfaceCatalogDiagnostic> warnings,
    required List<SurfaceCatalogDiagnosticsPresentationSection> sections,
  })  : errors = List<SurfaceCatalogDiagnostic>.unmodifiable(
          List<SurfaceCatalogDiagnostic>.from(errors),
        ),
        warnings = List<SurfaceCatalogDiagnostic>.unmodifiable(
          List<SurfaceCatalogDiagnostic>.from(warnings),
        ),
        sections =
            List<SurfaceCatalogDiagnosticsPresentationSection>.unmodifiable(
          List<SurfaceCatalogDiagnosticsPresentationSection>.from(sections),
        );

  final SurfaceCatalogDiagnosticsReport report;
  final SurfaceCatalogDiagnosticsSummary summary;
  final List<SurfaceCatalogDiagnostic> errors;
  final List<SurfaceCatalogDiagnostic> warnings;
  final List<SurfaceCatalogDiagnosticsPresentationSection> sections;

  /// Délègue à [summary] (pas de re-logique côté présentation).
  bool get isClean => summary.isClean;

  /// Délègue à [summary].
  bool get hasDiagnostics => summary.hasDiagnostics;

  /// Délègue à [summary].
  bool get hasErrors => summary.hasErrors;

  /// Délègue à [summary].
  bool get hasWarnings => summary.hasWarnings;

  /// Délègue à [summary].
  bool get hasOnlyWarnings => summary.hasOnlyWarnings;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceCatalogDiagnosticsPresentation &&
          other.report == report &&
          other.summary == summary &&
          _diagnosticsListEqualInOrder(other.errors, errors) &&
          _diagnosticsListEqualInOrder(other.warnings, warnings) &&
          _sectionListEqualInOrder(other.sections, sections);

  @override
  int get hashCode => Object.hash(
        report,
        summary,
        Object.hashAll(errors),
        Object.hashAll(warnings),
        Object.hashAll(sections),
      );
}

/// Construit un [SurfaceCatalogDiagnosticsPresentation] à partir de [report]
/// en conservant l’**instance** de rapport ([identical] dans la présentation) ;
/// pas de tri par kind, message ni id.
SurfaceCatalogDiagnosticsPresentation
    buildSurfaceCatalogDiagnosticsPresentation(
  SurfaceCatalogDiagnosticsReport report,
) {
  final summary = summarizeSurfaceCatalogDiagnostics(report);
  final err = <SurfaceCatalogDiagnostic>[];
  final warn = <SurfaceCatalogDiagnostic>[];
  for (final d in report.diagnostics) {
    if (d.severity == SurfaceCatalogDiagnosticSeverity.error) {
      err.add(d);
    } else if (d.severity == SurfaceCatalogDiagnosticSeverity.warning) {
      warn.add(d);
    }
  }

  final sections = <SurfaceCatalogDiagnosticsPresentationSection>[];
  if (err.isNotEmpty) {
    sections.add(
      SurfaceCatalogDiagnosticsPresentationSection(
        kind: SurfaceCatalogDiagnosticsPresentationSectionKind.errors,
        severity: SurfaceCatalogDiagnosticSeverity.error,
        diagnostics: err,
      ),
    );
  }
  if (warn.isNotEmpty) {
    sections.add(
      SurfaceCatalogDiagnosticsPresentationSection(
        kind: SurfaceCatalogDiagnosticsPresentationSectionKind.warnings,
        severity: SurfaceCatalogDiagnosticSeverity.warning,
        diagnostics: warn,
      ),
    );
  }

  return SurfaceCatalogDiagnosticsPresentation(
    report: report,
    summary: summary,
    errors: err,
    warnings: warn,
    sections: sections,
  );
}
