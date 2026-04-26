// Surface catalog — résumé auteur (Lot 37).
//
// [SurfaceCatalogDiagnosticsSummary] + [summarizeSurfaceCatalogDiagnostics] :
// brique **pure** pour une future UI auteur (badges, panneau « X erreurs, Y
// avertissements »), **sans** remplacer la liste de [SurfaceCatalogDiagnostic]
// ni [SurfaceCatalogDiagnosticsReport] : on **agrège** seulement des
// compteurs à partir d’un rapport **déjà** produit (Lots 34 / 35 / 36).
//
// * Aucun nouveau diagnostic n’est **créé** ici : uniquement de la lecture et
//   du dénombrement.
// * Les comptes par [SurfaceCatalogDiagnosticKind] sont dérivés **tel quel**
//   du [SurfaceCatalogDiagnosticsReport] passé, sans tri ni re-ordonnancement
//   des entrées.
// * [countByKind] est exposée en copie **immuable** ([Map.unmodifiable]) :
//   l’appelant ne peut pas la modifier (contrat défensif, comme le rapport).

import 'package:meta/meta.dart' show immutable;

import 'surface_catalog_diagnostics.dart';

bool _mapKindIntEqual(
  Map<SurfaceCatalogDiagnosticKind, int> a,
  Map<SurfaceCatalogDiagnosticKind, int> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (final e in a.entries) {
    if (b[e.key] != e.value) {
      return false;
    }
  }
  return true;
}

int _mapKindIntHashCode(Map<SurfaceCatalogDiagnosticKind, int> m) {
  // Combine les entrées de façon indépendante de l’ordre d’itération.
  var h = 0;
  for (final e in m.entries) {
    h = h ^ Object.hash(e.key, e.value);
  }
  return h;
}

/// Vue compacte d’un [SurfaceCatalogDiagnosticsReport] (totaux et répartition
/// par [SurfaceCatalogDiagnosticKind]).
@immutable
final class SurfaceCatalogDiagnosticsSummary {
  SurfaceCatalogDiagnosticsSummary._({
    required this.totalCount,
    required this.errorCount,
    required this.warningCount,
    required Map<SurfaceCatalogDiagnosticKind, int> countByKind,
  }) : _countByKind = countByKind;

  final int totalCount;
  final int errorCount;
  final int warningCount;
  final Map<SurfaceCatalogDiagnosticKind, int> _countByKind;

  /// Nombre d’occurrences par kind ; seuls les kinds avec au moins une
  /// entrée apparaissent. Immuable ([Map.unmodifiable]).
  Map<SurfaceCatalogDiagnosticKind, int> get countByKind => _countByKind;

  int countForKind(SurfaceCatalogDiagnosticKind kind) =>
      _countByKind[kind] ?? 0;

  bool get isClean => totalCount == 0;

  bool get hasDiagnostics => totalCount > 0;

  /// Cohérent avec [SurfaceCatalogDiagnosticsReport.hasErrors] : au moins une
  /// entrée [SurfaceCatalogDiagnosticSeverity.error].
  bool get hasErrors => errorCount > 0;

  bool get hasWarnings => warningCount > 0;

  bool get hasOnlyWarnings => warningCount > 0 && errorCount == 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceCatalogDiagnosticsSummary &&
          other.totalCount == totalCount &&
          other.errorCount == errorCount &&
          other.warningCount == warningCount &&
          _mapKindIntEqual(_countByKind, other._countByKind);

  @override
  int get hashCode => Object.hash(
        totalCount,
        errorCount,
        warningCount,
        _mapKindIntHashCode(_countByKind),
      );
}

/// Construit un [SurfaceCatalogDiagnosticsSummary] en **lecture seule** sur
/// [report] (aucune mutation du rapport, aucune mutation des listes
/// [SurfaceCatalogDiagnostic] internes).
SurfaceCatalogDiagnosticsSummary summarizeSurfaceCatalogDiagnostics(
  SurfaceCatalogDiagnosticsReport report,
) {
  var errorCount = 0;
  var warningCount = 0;
  final raw = <SurfaceCatalogDiagnosticKind, int>{};

  for (final d in report.diagnostics) {
    switch (d.severity) {
      case SurfaceCatalogDiagnosticSeverity.error:
        errorCount++;
        break;
      case SurfaceCatalogDiagnosticSeverity.warning:
        warningCount++;
        break;
    }
    raw[d.kind] = (raw[d.kind] ?? 0) + 1;
  }

  // Seuls les kinds effectivement rencontrés (compte ≥ 1) sont retenus.
  final byKind = Map<SurfaceCatalogDiagnosticKind, int>.unmodifiable(
    Map<SurfaceCatalogDiagnosticKind, int>.from(raw),
  );

  return SurfaceCatalogDiagnosticsSummary._(
    totalCount: report.diagnostics.length,
    errorCount: errorCount,
    warningCount: warningCount,
    countByKind: byKind,
  );
}
