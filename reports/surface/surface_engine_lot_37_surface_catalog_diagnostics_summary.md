# Surface Engine — Lot 37 — `SurfaceCatalogDiagnosticsSummary` V0 (résumé diagnostics)

## 1. Résumé exécutif

Ce lot introduit le type `SurfaceCatalogDiagnosticsSummary` et la fonction `summarizeSurfaceCatalogDiagnostics(SurfaceCatalogDiagnosticsReport)` : dénombrement en lecture seule (totaux, erreurs, avertissements, comptes par [SurfaceCatalogDiagnosticKind]), map exposée immuable, égalité par valeur, sans toucher au rapport, aux diagnostics, ni aux fonctions des Lots 34–36. Export `map_core` ; 16 tests ciblés.

## 2. Pourquoi ce lot vient après le Lot 36

Le Lot 36 unifie erreurs + warnings en un seul [SurfaceCatalogDiagnosticsReport]. Un écran auteur a besoin d’**agrégats** (X erreurs, Y avertissements, répartition par kind) : le résumé V0 sert d’**adaptation UI** sans dupliquer la logique de diagnostic.

## 3. Fichiers consultés (audit)

- `packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart`
- `packages/map_core/lib/src/operations/surface_catalog_authoring_diagnostics.dart`
- Tests surfaces / authoring / inutilisés, modèles `surface*.dart`, `map_core.dart`, `project_manifest.dart`, rapports Lots 34–36 (contexte, non modifiés).

## 4. Fichiers créés

- `packages/map_core/lib/src/operations/surface_catalog_diagnostics_summary.dart`
- `packages/map_core/test/surface_catalog_diagnostics_summary_test.dart`
- `reports/surface/surface_engine_lot_37_surface_catalog_diagnostics_summary.md` (ce document)

## 5. Fichiers modifiés

- `packages/map_core/lib/map_core.dart` (une ligne d’export)

## 6. API ajoutée

- `SurfaceCatalogDiagnosticsSummary` : get `totalCount`, `errorCount`, `warningCount`, `isClean`, `hasDiagnostics`, `hasErrors`, `hasWarnings`, `hasOnlyWarnings`, `countByKind`, `countForKind`, `==` / `hashCode`
- `summarizeSurfaceCatalogDiagnostics(SurfaceCatalogDiagnosticsReport) -> SurfaceCatalogDiagnosticsSummary`

## 7–8. Sémantique (summary + fonction)

Itération sur [report.diagnostics] sans tri ni mutation. `totalCount == diagnostics.length`. `error` / `warning` incrémentent les compteur correspondants. `countByKind` compte chaque [kind] ; seuls les kinds ≥ 1 sont présents ; `Map.unmodifiable`. `countForKind` retourne 0 par défaut.

## 9. Compteurs

`errorCount` / `warningCount` = nombre d’entrées avec la [severity] correspondante. Somme = `totalCount` (uniquement `error` et `warning` aujourd’hui).

## 10. Helpers bool

`isClean` = total 0. `hasDiagnostics` = total > 0. `hasErrors` = erreurs > 0 (aligné [SurfaceCatalogDiagnosticsReport.hasErrors] via contrat testé). `hasWarnings` = warnings > 0. `hasOnlyWarnings` = warnings > 0 et erreurs = 0.

## 11–12. `countByKind` / `countForKind`

Copie défensive, immuabilité ; pas de clé 0. `countForKind` = `countByKind[kind] ?? 0`.

## 13. Décision : ne pas modifier les Lots 34 / 35 / 36

Aucun changement aux fichiers d’opération existants des lots précédents.

## 14–15. Pas de nouveau kind / severity, pas d’`unusedPreset`

Aucun ajout d’énum, pas de [unusedPreset] (déjà absent).

## 16–17. [ProjectSurfaceCatalog] et [ProjectManifest] futur

Le résumé s’applique à n’importe quel rapport en mémoire. Aucun champ Surface ajouté au manifest.

## 18–20. Couverture de tests, preuves, hors-scope

16 cas : états vides, erreur seule, warning seul, mélange 7 éléments, clés de map, immuabilité, stabilité face mutation de liste source, `hasErrors` vs rapport, scénario auteur, warnings-only, égalité, export, manifest, enums. Pas de JSON, ni runtime, ni `SurfacePresetKind`.

## 21. Pourquoi le manifeste n’est pas modifié

Hors lot : persistance Surface planifiée plus tard, pas V0 de ce lot.

## 22–25. Aucun generated ; pas de `SurfacePresetKind` / `unusedPreset` de kind ; impact lots suivants

Aucun `build_runner`. Les prochains lots peuvent lier l’UI à `summarizeSurfaceCatalogDiagnostics` après `diagnoseProjectSurfaceCatalogForAuthoring` sans re-scanner le catalogue.

## 26. Commandes lancées

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/surface_catalog_diagnostics_summary_test.dart
/opt/homebrew/bin/dart test test/surface_catalog_authoring_diagnostics_test.dart
/opt/homebrew/bin/dart test test/surface_catalog_diagnostics_test.dart
/opt/homebrew/bin/dart test test/surface_catalog_unused_diagnostics_test.dart
/opt/homebrew/bin/dart analyze (chemins explicites, voir sortie §35.D.3)
/opt/homebrew/bin/dart test
```

`git status --short` (lecture) :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/surface_catalog_diagnostics_summary.dart
?? packages/map_core/test/surface_catalog_diagnostics_summary_test.dart
```

## 27. Sortie intégrale : test ciblé Lot 37

```text
00:00 [32m+0[0m: [1m[90mloading test/surface_catalog_diagnostics_summary_test.dart[0m[0m                                                                                                                                   00:00 [32m+0[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 1. empty report → clean summary[0m                                                                                                                  00:00 [32m+1[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 1. empty report → clean summary[0m                                                                                                                  00:00 [32m+1[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 2. one error missingPresetAnimation[0m                                                                                                              00:00 [32m+2[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 2. one error missingPresetAnimation[0m                                                                                                              00:00 [32m+2[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 3. one warning unusedAtlas[0m                                                                                                                       00:00 [32m+3[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 3. one warning unusedAtlas[0m                                                                                                                       00:00 [32m+3[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 4. mixed: 2+1 errors, 1+3 warnings, counts by kind[0m                                                                                               00:00 [32m+4[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 4. mixed: 2+1 errors, 1+3 warnings, counts by kind[0m                                                                                               00:00 [32m+4[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 5. countByKind only present kinds; countForKind 0 for absent[0m                                                                                     00:00 [32m+5[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 5. countByKind only present kinds; countForKind 0 for absent[0m                                                                                     00:00 [32m+5[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 6. countByKind is unmodifiable[0m                                                                                                                   00:00 [32m+6[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 6. countByKind is unmodifiable[0m                                                                                                                   00:00 [32m+6[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 7. summary does not mutate report; list mutation does not change stored report or prior summary[0m                                                  00:00 [32m+7[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 7. summary does not mutate report; list mutation does not change stored report or prior summary[0m                                                  00:00 [32m+7[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 8. hasErrors matches SurfaceCatalogDiagnosticsReport.hasErrors (mixed)[0m                                                                           00:00 [32m+8[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 8. hasErrors matches SurfaceCatalogDiagnosticsReport.hasErrors (mixed)[0m                                                                           00:00 [32m+8[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 9. from diagnoseProjectSurfaceCatalogForAuthoring: 1 err + 2 warn[0m                                                                                00:00 [32m+9[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 9. from diagnoseProjectSurfaceCatalogForAuthoring: 1 err + 2 warn[0m                                                                                00:00 [32m+9[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 10. from authoring: warnings-only (unused) → hasOnlyWarnings[0m                                                                                     00:00 [32m+10[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 10. from authoring: warnings-only (unused) → hasOnlyWarnings[0m                                                                                    00:00 [32m+10[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 11. value equality: equivalent reports → same summary hash/==[0m                                                                                   00:00 [32m+11[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 11. value equality: equivalent reports → same summary hash/==[0m                                                                                   00:00 [32m+11[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 12. value inequality: different error/warning split (same total)[0m                                                                                00:00 [32m+12[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 12. value inequality: different error/warning split (same total)[0m                                                                                00:00 [32m+12[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 13. value inequality: same severity totals, different byKind[0m                                                                                    00:00 [32m+13[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 13. value inequality: same severity totals, different byKind[0m                                                                                    00:00 [32m+13[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 14. public API via map_core[0m                                                                                                                     00:00 [32m+14[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 14. public API via map_core[0m                                                                                                                     00:00 [32m+14[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 15. ProjectManifest still has no Surface keys (Lot 37)[0m                                                                                          00:00 [32m+15[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 15. ProjectManifest still has no Surface keys (Lot 37)[0m                                                                                          00:00 [32m+15[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 16. no unusedPreset kind; severities are error and warning only[0m                                                                                 00:00 [32m+16[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 16. no unusedPreset kind; severities are error and warning only[0m                                                                                 00:00 [32m+16[0m: All tests passed![0m
```

## 28. Résultat `dart analyze` (chemins imposés)

```text
Analyzing surface_catalog_diagnostics_summary.dart, surface_catalog_authoring_diagnostics.dart, surface_catalog_diagnostics.dart, surface_catalog.dart, surface.dart, standard_surface_preset_builder.dart, surface_catalog_diagnostics_summary_test.dart, surface_catalog_authoring_diagnostics_test.dart, surface_catalog_unused_diagnostics_test.dart, surface_catalog_diagnostics_test.dart, project_surface_catalog_test.dart, standard_surface_preset_builder_test.dart, project_surface_preset_test.dart, project_surface_animation_test.dart, project_surface_atlas_test.dart, map_core.dart...
No issues found!
```

## 29–30. `dart test` complet

Commande : `cd packages/map_core && /opt/homebrew/bin/dart test`  

Dernière ligne enregistrée (sortie de la même exécution) :

```text
00:01 +843: All tests passed!
```

Total : **843** tests (suite `map_core` entière).

## 31. Points de vigilance

Si de nouvelles [severity] apparaissent, il faudra étendre le switch (hors V0) ou comptage explicite. [hasErrors] du résumé reste lié par test au rapport, pas à une sémantique plus large de projet.

## 32. Autocritique

Le volume des sorties de régression (§35.D) est élevé (une seule colonne) ; toutes les octets de sortie sont intégrés tels quels.

## 33. Ce que le prompt semble discutable ou incomplet

Aucun point bloquant : le cahier des charges est explicite sur l’immuabilité, l’`==`, et l’exclusion d’[unusedPreset] au niveau des kinds.

## 34. Auto-review indépendante (points contractuels)

- Lot limité au résumé, manifeste intact, pas de champs Surface persistants, pas de `SurfacePresetKind` / `surfaceKind` / `unusedPreset` (kind)
- Aucun nouveau kind/severity, pas de `build_runner` ni `*.g.dart` / `*.freezed`
- Aucun autre package modifié
- Lots 34/35/36 intacts, compteurs + map immuable, `countForKind` = 0 absent, `==` / `hashCode` testés, export public, manifest, 843 tests verts, Evidence Pack rempli, aucune commande Git d’écriture

## 35. Evidence Pack complet

### 35.A. Contenu intégral des fichiers créés

#### `packages/map_core/lib/src/operations/surface_catalog_diagnostics_summary.dart`

```dart
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
```



#### `packages/map_core/test/surface_catalog_diagnostics_summary_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

SurfaceCatalogDiagnostic _diagnostic({
  required SurfaceCatalogDiagnosticSeverity severity,
  required SurfaceCatalogDiagnosticKind kind,
  String message = 'message',
  String? presetId,
  String? animationId,
  String? atlasId,
  SurfaceVariantRole? role,
  int? frameIndex,
}) {
  return SurfaceCatalogDiagnostic(
    severity: severity,
    kind: kind,
    message: message,
    presetId: presetId,
    animationId: animationId,
    atlasId: atlasId,
    role: role,
    frameIndex: frameIndex,
  );
}

SurfaceCatalogDiagnosticsReport _report(
  List<SurfaceCatalogDiagnostic> diagnostics,
) {
  return SurfaceCatalogDiagnosticsReport(diagnostics: diagnostics);
}

// --- Minimale cohérence catalog (reprise style Lot 36) ---

SurfaceAtlasGeometry _geom({int columns = 2, int rows = 2}) {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: columns, rows: rows),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
}

ProjectSurfaceAtlas _atlas(
  String id, {
  int columns = 2,
  int rows = 2,
}) {
  return ProjectSurfaceAtlas(
    id: id,
    name: 'n-$id',
    tilesetId: 'ts',
    geometry: _geom(columns: columns, rows: rows),
  );
}

SurfaceAnimationFrame _frame(String atlasId, int column, int row) {
  return SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(
      atlasId: atlasId,
      column: column,
      row: row,
    ),
    durationMs: 1,
  );
}

ProjectSurfaceAnimation _animation(
  String id, {
  String atlasId = 'atlas',
  List<SurfaceAnimationFrame>? frames,
}) {
  return ProjectSurfaceAnimation(
    id: id,
    name: 'a-$id',
    timeline: SurfaceAnimationTimeline(
      frames: frames ?? [_frame(atlasId, 0, 0)],
    ),
  );
}

SurfaceVariantAnimationRef _ref(SurfaceVariantRole role, String animationId) {
  return SurfaceVariantAnimationRef(
    role: role,
    animationId: animationId,
  );
}

ProjectSurfacePreset _preset(String id, List<SurfaceVariantAnimationRef> refs) {
  return ProjectSurfacePreset(
    id: id,
    name: 'p-$id',
    variantAnimations: SurfaceVariantAnimationRefSet(refs: refs),
  );
}

ProjectSurfaceCatalog _catalog({
  List<ProjectSurfaceAtlas>? atlases,
  List<ProjectSurfaceAnimation>? animations,
  List<ProjectSurfacePreset>? presets,
}) {
  return ProjectSurfaceCatalog(
    atlases: atlases ?? const [],
    animations: animations ?? const [],
    presets: presets ?? const [],
  );
}

void main() {
  group('summarizeSurfaceCatalogDiagnostics (Lot 37)', () {
    test('1. empty report → clean summary', () {
      final s = summarizeSurfaceCatalogDiagnostics(
        SurfaceCatalogDiagnosticsReport(diagnostics: const []),
      );
      expect(s.totalCount, 0);
      expect(s.errorCount, 0);
      expect(s.warningCount, 0);
      expect(s.isClean, isTrue);
      expect(s.hasDiagnostics, isFalse);
      expect(s.hasErrors, isFalse);
      expect(s.hasWarnings, isFalse);
      expect(s.hasOnlyWarnings, isFalse);
      expect(s.countByKind.isEmpty, isTrue);
      for (final k in SurfaceCatalogDiagnosticKind.values) {
        expect(s.countForKind(k), 0);
      }
    });

    test('2. one error missingPresetAnimation', () {
      final s = summarizeSurfaceCatalogDiagnostics(
        _report([
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.error,
            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
          ),
        ]),
      );
      expect(s.totalCount, 1);
      expect(s.errorCount, 1);
      expect(s.warningCount, 0);
      expect(s.hasDiagnostics, isTrue);
      expect(s.hasErrors, isTrue);
      expect(s.hasWarnings, isFalse);
      expect(s.hasOnlyWarnings, isFalse);
      expect(
        s.countForKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation),
        1,
      );
    });

    test('3. one warning unusedAtlas', () {
      final s = summarizeSurfaceCatalogDiagnostics(
        _report([
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.warning,
            kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
            atlasId: 'a1',
          ),
        ]),
      );
      expect(s.totalCount, 1);
      expect(s.errorCount, 0);
      expect(s.warningCount, 1);
      expect(s.hasDiagnostics, isTrue);
      expect(s.hasErrors, isFalse);
      expect(s.hasWarnings, isTrue);
      expect(s.hasOnlyWarnings, isTrue);
      expect(s.countForKind(SurfaceCatalogDiagnosticKind.unusedAtlas), 1);
    });

    test('4. mixed: 2+1 errors, 1+3 warnings, counts by kind', () {
      const err = SurfaceCatalogDiagnosticSeverity.error;
      const w = SurfaceCatalogDiagnosticSeverity.warning;
      final s = summarizeSurfaceCatalogDiagnostics(
        _report([
          _diagnostic(
              severity: err,
              kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation),
          _diagnostic(
              severity: err,
              kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation),
          _diagnostic(
            severity: err,
            kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
            animationId: 'an',
            atlasId: 'bad',
          ),
          _diagnostic(
              severity: w,
              kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
              atlasId: 'u1'),
          _diagnostic(
            severity: w,
            kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
            animationId: 'x1',
          ),
          _diagnostic(
            severity: w,
            kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
            animationId: 'x2',
          ),
          _diagnostic(
            severity: w,
            kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
            animationId: 'x3',
          ),
        ]),
      );
      expect(s.totalCount, 7);
      expect(s.errorCount, 3);
      expect(s.warningCount, 4);
      expect(s.hasErrors, isTrue);
      expect(s.hasWarnings, isTrue);
      expect(s.hasOnlyWarnings, isFalse);
      expect(
          s.countForKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation),
          2);
      expect(
        s.countForKind(SurfaceCatalogDiagnosticKind.missingAnimationAtlas),
        1,
      );
      expect(s.countForKind(SurfaceCatalogDiagnosticKind.unusedAtlas), 1);
      expect(s.countForKind(SurfaceCatalogDiagnosticKind.unusedAnimation), 3);
    });

    test('5. countByKind only present kinds; countForKind 0 for absent', () {
      final s = summarizeSurfaceCatalogDiagnostics(
        _report([
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.warning,
            kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
            atlasId: 'at',
          ),
        ]),
      );
      expect(
          s.countByKind.containsKey(SurfaceCatalogDiagnosticKind.unusedAtlas),
          isTrue);
      expect(
        s.countByKind.containsKey(SurfaceCatalogDiagnosticKind.unusedAnimation),
        isFalse,
      );
      expect(s.countForKind(SurfaceCatalogDiagnosticKind.unusedAnimation), 0);
    });

    test('6. countByKind is unmodifiable', () {
      final s = summarizeSurfaceCatalogDiagnostics(
        _report([
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.warning,
            kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
            atlasId: 'a',
          ),
        ]),
      );
      expect(
        () {
          s.countByKind[SurfaceCatalogDiagnosticKind.unusedAtlas] = 99;
        },
        throwsA(isA<UnsupportedError>()),
      );
    });

    test(
        '7. summary does not mutate report; list mutation does not change stored report or prior summary',
        () {
      final list = <SurfaceCatalogDiagnostic>[
        _diagnostic(
          severity: SurfaceCatalogDiagnosticSeverity.error,
          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
          presetId: 'p1',
        ),
      ];
      final report = _report(list);
      final sBefore = summarizeSurfaceCatalogDiagnostics(report);
      list.add(
        _diagnostic(
          severity: SurfaceCatalogDiagnosticSeverity.warning,
          kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
        ),
      );
      final after = summarizeSurfaceCatalogDiagnostics(report);
      expect(report.count, 1);
      expect(after.totalCount, 1);
      expect(sBefore, after);
    });

    test(
        '8. hasErrors matches SurfaceCatalogDiagnosticsReport.hasErrors (mixed)',
        () {
      const err = SurfaceCatalogDiagnosticSeverity.error;
      const w = SurfaceCatalogDiagnosticSeverity.warning;
      final report = _report([
        _diagnostic(
            severity: err,
            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation),
        _diagnostic(
          severity: w,
          kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
          animationId: 'a',
        ),
      ]);
      final s = summarizeSurfaceCatalogDiagnostics(report);
      expect(s.hasErrors, report.hasErrors);
    });

    test('9. from diagnoseProjectSurfaceCatalogForAuthoring: 1 err + 2 warn',
        () {
      final used = _atlas('used-atlas');
      final unusedA = _atlas('unused-atlas');
      final uAnim = _animation('unused-animation', atlasId: 'used-atlas');
      final c = _catalog(
        atlases: [used, unusedA],
        animations: [uAnim],
        presets: [
          _preset('broken-preset', [
            _ref(SurfaceVariantRole.isolated, 'missing-animation'),
          ]),
        ],
      );
      final report = diagnoseProjectSurfaceCatalogForAuthoring(c);
      final s = summarizeSurfaceCatalogDiagnostics(report);
      expect(report.diagnostics[0].kind,
          SurfaceCatalogDiagnosticKind.missingPresetAnimation);
      expect(s.totalCount, 3);
      expect(s.errorCount, 1);
      expect(s.warningCount, 2);
      expect(s.hasErrors, isTrue);
      expect(s.hasWarnings, isTrue);
      expect(s.hasOnlyWarnings, isFalse);
    });

    test('10. from authoring: warnings-only (unused) → hasOnlyWarnings', () {
      final c = _catalog(
        atlases: [_atlas('orphan')],
        animations: [
          _animation('orphan-anim', atlasId: 'orphan'),
        ],
        presets: const [],
      );
      final report = diagnoseProjectSurfaceCatalogForAuthoring(c);
      final s = summarizeSurfaceCatalogDiagnostics(report);
      expect(s.hasOnlyWarnings, isTrue);
      expect(s.hasErrors, isFalse);
    });

    test('11. value equality: equivalent reports → same summary hash/==', () {
      final a = <SurfaceCatalogDiagnostic>[
        _diagnostic(
          severity: SurfaceCatalogDiagnosticSeverity.error,
          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
          message: 'm',
        ),
      ];
      final s1 = summarizeSurfaceCatalogDiagnostics(_report(a));
      final s2 = summarizeSurfaceCatalogDiagnostics(_report(List.from(a)));
      expect(s1, s2);
      expect(s1.hashCode, s2.hashCode);
    });

    test('12. value inequality: different error/warning split (same total)',
        () {
      final sErr = summarizeSurfaceCatalogDiagnostics(
        _report([
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.error,
            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
          ),
        ]),
      );
      final sWarn = summarizeSurfaceCatalogDiagnostics(
        _report([
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.warning,
            kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
            atlasId: 'x',
          ),
        ]),
      );
      expect(sErr.totalCount, sWarn.totalCount);
      expect(sErr, isNot(sWarn));
    });

    test('13. value inequality: same severity totals, different byKind', () {
      final s1 = summarizeSurfaceCatalogDiagnostics(
        _report([
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.error,
            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
          ),
        ]),
      );
      final s2 = summarizeSurfaceCatalogDiagnostics(
        _report([
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.error,
            kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
            atlasId: 'x',
            animationId: 'a',
          ),
        ]),
      );
      expect(s1.totalCount, s2.totalCount);
      expect(s1.errorCount, s2.errorCount);
      expect(s1, isNot(s2));
    });

    test('14. public API via map_core', () {
      final s = summarizeSurfaceCatalogDiagnostics(
        SurfaceCatalogDiagnosticsReport(diagnostics: const []),
      );
      expect(s, isA<SurfaceCatalogDiagnosticsSummary>());
    });

    test('15. ProjectManifest still has no Surface keys (Lot 37)', () {
      const manifest = ProjectManifest(
        name: 'L37',
        maps: [
          ProjectMapEntry(
            id: 'm1',
            name: 'M',
            relativePath: 'maps/m1.json',
          ),
        ],
        tilesets: [],
      );
      final j = manifest.toJson();
      for (final k in const [
        'surfaceDefinitions',
        'surfaceAtlases',
        'surfaceAnimations',
        'surfacePresets',
        'surfaceCategories',
      ]) {
        expect(j.containsKey(k), isFalse, reason: k);
      }
    });

    test('16. no unusedPreset kind; severities are error and warning only', () {
      final names =
          SurfaceCatalogDiagnosticKind.values.map((e) => e.name).toList();
      expect(names.contains('unusedPreset'), isFalse);
      final sev = SurfaceCatalogDiagnosticSeverity.values
          .map((e) => e.name)
          .toList()
        ..sort();
      expect(sev, ['error', 'warning']);
    });
  });
}
```



### 35.B. Fichier modifié (barrel) — intégral

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



### 35.C. Diffs

#### Diff réel `map_core.dart`

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index ea6022a6..82e14641 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -43,6 +43,7 @@ export 'src/operations/standard_tall_grass_path_preset_vertical_atlas_builder.da
 export 'src/operations/standard_surface_preset_builder.dart';
 export 'src/operations/surface_catalog_diagnostics.dart';
 export 'src/operations/surface_catalog_authoring_diagnostics.dart';
+export 'src/operations/surface_catalog_diagnostics_summary.dart';
 export 'src/operations/legacy_path_surface_view.dart';
 export 'src/operations/legacy_terrain_surface_view.dart';
 export 'src/operations/legacy_project_surface_catalog_view.dart';
```



#### `git diff --no-index /dev/null` → `surface_catalog_diagnostics_summary.dart`

```diff
diff --git a/packages/map_core/lib/src/operations/surface_catalog_diagnostics_summary.dart b/packages/map_core/lib/src/operations/surface_catalog_diagnostics_summary.dart
new file mode 100644
index 00000000..fa7cdd56
--- /dev/null
+++ b/packages/map_core/lib/src/operations/surface_catalog_diagnostics_summary.dart
@@ -0,0 +1,131 @@
+// Surface catalog — résumé auteur (Lot 37).
+//
+// [SurfaceCatalogDiagnosticsSummary] + [summarizeSurfaceCatalogDiagnostics] :
+// brique **pure** pour une future UI auteur (badges, panneau « X erreurs, Y
+// avertissements »), **sans** remplacer la liste de [SurfaceCatalogDiagnostic]
+// ni [SurfaceCatalogDiagnosticsReport] : on **agrège** seulement des
+// compteurs à partir d’un rapport **déjà** produit (Lots 34 / 35 / 36).
+//
+// * Aucun nouveau diagnostic n’est **créé** ici : uniquement de la lecture et
+//   du dénombrement.
+// * Les comptes par [SurfaceCatalogDiagnosticKind] sont dérivés **tel quel**
+//   du [SurfaceCatalogDiagnosticsReport] passé, sans tri ni re-ordonnancement
+//   des entrées.
+// * [countByKind] est exposée en copie **immuable** ([Map.unmodifiable]) :
+//   l’appelant ne peut pas la modifier (contrat défensif, comme le rapport).
+
+import 'package:meta/meta.dart' show immutable;
+
+import 'surface_catalog_diagnostics.dart';
+
+bool _mapKindIntEqual(
+  Map<SurfaceCatalogDiagnosticKind, int> a,
+  Map<SurfaceCatalogDiagnosticKind, int> b,
+) {
+  if (a.length != b.length) {
+    return false;
+  }
+  for (final e in a.entries) {
+    if (b[e.key] != e.value) {
+      return false;
+    }
+  }
+  return true;
+}
+
+int _mapKindIntHashCode(Map<SurfaceCatalogDiagnosticKind, int> m) {
+  // Combine les entrées de façon indépendante de l’ordre d’itération.
+  var h = 0;
+  for (final e in m.entries) {
+    h = h ^ Object.hash(e.key, e.value);
+  }
+  return h;
+}
+
+/// Vue compacte d’un [SurfaceCatalogDiagnosticsReport] (totaux et répartition
+/// par [SurfaceCatalogDiagnosticKind]).
+@immutable
+final class SurfaceCatalogDiagnosticsSummary {
+  SurfaceCatalogDiagnosticsSummary._({
+    required this.totalCount,
+    required this.errorCount,
+    required this.warningCount,
+    required Map<SurfaceCatalogDiagnosticKind, int> countByKind,
+  }) : _countByKind = countByKind;
+
+  final int totalCount;
+  final int errorCount;
+  final int warningCount;
+  final Map<SurfaceCatalogDiagnosticKind, int> _countByKind;
+
+  /// Nombre d’occurrences par kind ; seuls les kinds avec au moins une
+  /// entrée apparaissent. Immuable ([Map.unmodifiable]).
+  Map<SurfaceCatalogDiagnosticKind, int> get countByKind => _countByKind;
+
+  int countForKind(SurfaceCatalogDiagnosticKind kind) =>
+      _countByKind[kind] ?? 0;
+
+  bool get isClean => totalCount == 0;
+
+  bool get hasDiagnostics => totalCount > 0;
+
+  /// Cohérent avec [SurfaceCatalogDiagnosticsReport.hasErrors] : au moins une
+  /// entrée [SurfaceCatalogDiagnosticSeverity.error].
+  bool get hasErrors => errorCount > 0;
+
+  bool get hasWarnings => warningCount > 0;
+
+  bool get hasOnlyWarnings => warningCount > 0 && errorCount == 0;
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is SurfaceCatalogDiagnosticsSummary &&
+          other.totalCount == totalCount &&
+          other.errorCount == errorCount &&
+          other.warningCount == warningCount &&
+          _mapKindIntEqual(_countByKind, other._countByKind);
+
+  @override
+  int get hashCode => Object.hash(
+        totalCount,
+        errorCount,
+        warningCount,
+        _mapKindIntHashCode(_countByKind),
+      );
+}
+
+/// Construit un [SurfaceCatalogDiagnosticsSummary] en **lecture seule** sur
+/// [report] (aucune mutation du rapport, aucune mutation des listes
+/// [SurfaceCatalogDiagnostic] internes).
+SurfaceCatalogDiagnosticsSummary summarizeSurfaceCatalogDiagnostics(
+  SurfaceCatalogDiagnosticsReport report,
+) {
+  var errorCount = 0;
+  var warningCount = 0;
+  final raw = <SurfaceCatalogDiagnosticKind, int>{};
+
+  for (final d in report.diagnostics) {
+    switch (d.severity) {
+      case SurfaceCatalogDiagnosticSeverity.error:
+        errorCount++;
+        break;
+      case SurfaceCatalogDiagnosticSeverity.warning:
+        warningCount++;
+        break;
+    }
+    raw[d.kind] = (raw[d.kind] ?? 0) + 1;
+  }
+
+  // Seuls les kinds effectivement rencontrés (compte ≥ 1) sont retenus.
+  final byKind = Map<SurfaceCatalogDiagnosticKind, int>.unmodifiable(
+    Map<SurfaceCatalogDiagnosticKind, int>.from(raw),
+  );
+
+  return SurfaceCatalogDiagnosticsSummary._(
+    totalCount: report.diagnostics.length,
+    errorCount: errorCount,
+    warningCount: warningCount,
+    countByKind: byKind,
+  );
+}
```



#### `git diff --no-index /dev/null` → `surface_catalog_diagnostics_summary_test.dart`

```diff
diff --git a/packages/map_core/test/surface_catalog_diagnostics_summary_test.dart b/packages/map_core/test/surface_catalog_diagnostics_summary_test.dart
new file mode 100644
index 00000000..008f4ece
--- /dev/null
+++ b/packages/map_core/test/surface_catalog_diagnostics_summary_test.dart
@@ -0,0 +1,448 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+SurfaceCatalogDiagnostic _diagnostic({
+  required SurfaceCatalogDiagnosticSeverity severity,
+  required SurfaceCatalogDiagnosticKind kind,
+  String message = 'message',
+  String? presetId,
+  String? animationId,
+  String? atlasId,
+  SurfaceVariantRole? role,
+  int? frameIndex,
+}) {
+  return SurfaceCatalogDiagnostic(
+    severity: severity,
+    kind: kind,
+    message: message,
+    presetId: presetId,
+    animationId: animationId,
+    atlasId: atlasId,
+    role: role,
+    frameIndex: frameIndex,
+  );
+}
+
+SurfaceCatalogDiagnosticsReport _report(
+  List<SurfaceCatalogDiagnostic> diagnostics,
+) {
+  return SurfaceCatalogDiagnosticsReport(diagnostics: diagnostics);
+}
+
+// --- Minimale cohérence catalog (reprise style Lot 36) ---
+
+SurfaceAtlasGeometry _geom({int columns = 2, int rows = 2}) {
+  return SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+    gridSize: SurfaceAtlasGridSize(columns: columns, rows: rows),
+    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+  );
+}
+
+ProjectSurfaceAtlas _atlas(
+  String id, {
+  int columns = 2,
+  int rows = 2,
+}) {
+  return ProjectSurfaceAtlas(
+    id: id,
+    name: 'n-$id',
+    tilesetId: 'ts',
+    geometry: _geom(columns: columns, rows: rows),
+  );
+}
+
+SurfaceAnimationFrame _frame(String atlasId, int column, int row) {
+  return SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(
+      atlasId: atlasId,
+      column: column,
+      row: row,
+    ),
+    durationMs: 1,
+  );
+}
+
+ProjectSurfaceAnimation _animation(
+  String id, {
+  String atlasId = 'atlas',
+  List<SurfaceAnimationFrame>? frames,
+}) {
+  return ProjectSurfaceAnimation(
+    id: id,
+    name: 'a-$id',
+    timeline: SurfaceAnimationTimeline(
+      frames: frames ?? [_frame(atlasId, 0, 0)],
+    ),
+  );
+}
+
+SurfaceVariantAnimationRef _ref(SurfaceVariantRole role, String animationId) {
+  return SurfaceVariantAnimationRef(
+    role: role,
+    animationId: animationId,
+  );
+}
+
+ProjectSurfacePreset _preset(String id, List<SurfaceVariantAnimationRef> refs) {
+  return ProjectSurfacePreset(
+    id: id,
+    name: 'p-$id',
+    variantAnimations: SurfaceVariantAnimationRefSet(refs: refs),
+  );
+}
+
+ProjectSurfaceCatalog _catalog({
+  List<ProjectSurfaceAtlas>? atlases,
+  List<ProjectSurfaceAnimation>? animations,
+  List<ProjectSurfacePreset>? presets,
+}) {
+  return ProjectSurfaceCatalog(
+    atlases: atlases ?? const [],
+    animations: animations ?? const [],
+    presets: presets ?? const [],
+  );
+}
+
+void main() {
+  group('summarizeSurfaceCatalogDiagnostics (Lot 37)', () {
+    test('1. empty report → clean summary', () {
+      final s = summarizeSurfaceCatalogDiagnostics(
+        SurfaceCatalogDiagnosticsReport(diagnostics: const []),
+      );
+      expect(s.totalCount, 0);
+      expect(s.errorCount, 0);
+      expect(s.warningCount, 0);
+      expect(s.isClean, isTrue);
+      expect(s.hasDiagnostics, isFalse);
+      expect(s.hasErrors, isFalse);
+      expect(s.hasWarnings, isFalse);
+      expect(s.hasOnlyWarnings, isFalse);
+      expect(s.countByKind.isEmpty, isTrue);
+      for (final k in SurfaceCatalogDiagnosticKind.values) {
+        expect(s.countForKind(k), 0);
+      }
+    });
+
+    test('2. one error missingPresetAnimation', () {
+      final s = summarizeSurfaceCatalogDiagnostics(
+        _report([
+          _diagnostic(
+            severity: SurfaceCatalogDiagnosticSeverity.error,
+            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+          ),
+        ]),
+      );
+      expect(s.totalCount, 1);
+      expect(s.errorCount, 1);
+      expect(s.warningCount, 0);
+      expect(s.hasDiagnostics, isTrue);
+      expect(s.hasErrors, isTrue);
+      expect(s.hasWarnings, isFalse);
+      expect(s.hasOnlyWarnings, isFalse);
+      expect(
+        s.countForKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation),
+        1,
+      );
+    });
+
+    test('3. one warning unusedAtlas', () {
+      final s = summarizeSurfaceCatalogDiagnostics(
+        _report([
+          _diagnostic(
+            severity: SurfaceCatalogDiagnosticSeverity.warning,
+            kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
+            atlasId: 'a1',
+          ),
+        ]),
+      );
+      expect(s.totalCount, 1);
+      expect(s.errorCount, 0);
+      expect(s.warningCount, 1);
+      expect(s.hasDiagnostics, isTrue);
+      expect(s.hasErrors, isFalse);
+      expect(s.hasWarnings, isTrue);
+      expect(s.hasOnlyWarnings, isTrue);
+      expect(s.countForKind(SurfaceCatalogDiagnosticKind.unusedAtlas), 1);
+    });
+
+    test('4. mixed: 2+1 errors, 1+3 warnings, counts by kind', () {
+      const err = SurfaceCatalogDiagnosticSeverity.error;
+      const w = SurfaceCatalogDiagnosticSeverity.warning;
+      final s = summarizeSurfaceCatalogDiagnostics(
+        _report([
+          _diagnostic(
+              severity: err,
+              kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation),
+          _diagnostic(
+              severity: err,
+              kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation),
+          _diagnostic(
+            severity: err,
+            kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
+            animationId: 'an',
+            atlasId: 'bad',
+          ),
+          _diagnostic(
+              severity: w,
+              kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
+              atlasId: 'u1'),
+          _diagnostic(
+            severity: w,
+            kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
+            animationId: 'x1',
+          ),
+          _diagnostic(
+            severity: w,
+            kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
+            animationId: 'x2',
+          ),
+          _diagnostic(
+            severity: w,
+            kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
+            animationId: 'x3',
+          ),
+        ]),
+      );
+      expect(s.totalCount, 7);
+      expect(s.errorCount, 3);
+      expect(s.warningCount, 4);
+      expect(s.hasErrors, isTrue);
+      expect(s.hasWarnings, isTrue);
+      expect(s.hasOnlyWarnings, isFalse);
+      expect(
+          s.countForKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation),
+          2);
+      expect(
+        s.countForKind(SurfaceCatalogDiagnosticKind.missingAnimationAtlas),
+        1,
+      );
+      expect(s.countForKind(SurfaceCatalogDiagnosticKind.unusedAtlas), 1);
+      expect(s.countForKind(SurfaceCatalogDiagnosticKind.unusedAnimation), 3);
+    });
+
+    test('5. countByKind only present kinds; countForKind 0 for absent', () {
+      final s = summarizeSurfaceCatalogDiagnostics(
+        _report([
+          _diagnostic(
+            severity: SurfaceCatalogDiagnosticSeverity.warning,
+            kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
+            atlasId: 'at',
+          ),
+        ]),
+      );
+      expect(
+          s.countByKind.containsKey(SurfaceCatalogDiagnosticKind.unusedAtlas),
+          isTrue);
+      expect(
+        s.countByKind.containsKey(SurfaceCatalogDiagnosticKind.unusedAnimation),
+        isFalse,
+      );
+      expect(s.countForKind(SurfaceCatalogDiagnosticKind.unusedAnimation), 0);
+    });
+
+    test('6. countByKind is unmodifiable', () {
+      final s = summarizeSurfaceCatalogDiagnostics(
+        _report([
+          _diagnostic(
+            severity: SurfaceCatalogDiagnosticSeverity.warning,
+            kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
+            atlasId: 'a',
+          ),
+        ]),
+      );
+      expect(
+        () {
+          s.countByKind[SurfaceCatalogDiagnosticKind.unusedAtlas] = 99;
+        },
+        throwsA(isA<UnsupportedError>()),
+      );
+    });
+
+    test(
+        '7. summary does not mutate report; list mutation does not change stored report or prior summary',
+        () {
+      final list = <SurfaceCatalogDiagnostic>[
+        _diagnostic(
+          severity: SurfaceCatalogDiagnosticSeverity.error,
+          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+          presetId: 'p1',
+        ),
+      ];
+      final report = _report(list);
+      final sBefore = summarizeSurfaceCatalogDiagnostics(report);
+      list.add(
+        _diagnostic(
+          severity: SurfaceCatalogDiagnosticSeverity.warning,
+          kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
+        ),
+      );
+      final after = summarizeSurfaceCatalogDiagnostics(report);
+      expect(report.count, 1);
+      expect(after.totalCount, 1);
+      expect(sBefore, after);
+    });
+
+    test(
+        '8. hasErrors matches SurfaceCatalogDiagnosticsReport.hasErrors (mixed)',
+        () {
+      const err = SurfaceCatalogDiagnosticSeverity.error;
+      const w = SurfaceCatalogDiagnosticSeverity.warning;
+      final report = _report([
+        _diagnostic(
+            severity: err,
+            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation),
+        _diagnostic(
+          severity: w,
+          kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
+          animationId: 'a',
+        ),
+      ]);
+      final s = summarizeSurfaceCatalogDiagnostics(report);
+      expect(s.hasErrors, report.hasErrors);
+    });
+
+    test('9. from diagnoseProjectSurfaceCatalogForAuthoring: 1 err + 2 warn',
+        () {
+      final used = _atlas('used-atlas');
+      final unusedA = _atlas('unused-atlas');
+      final uAnim = _animation('unused-animation', atlasId: 'used-atlas');
+      final c = _catalog(
+        atlases: [used, unusedA],
+        animations: [uAnim],
+        presets: [
+          _preset('broken-preset', [
+            _ref(SurfaceVariantRole.isolated, 'missing-animation'),
+          ]),
+        ],
+      );
+      final report = diagnoseProjectSurfaceCatalogForAuthoring(c);
+      final s = summarizeSurfaceCatalogDiagnostics(report);
+      expect(report.diagnostics[0].kind,
+          SurfaceCatalogDiagnosticKind.missingPresetAnimation);
+      expect(s.totalCount, 3);
+      expect(s.errorCount, 1);
+      expect(s.warningCount, 2);
+      expect(s.hasErrors, isTrue);
+      expect(s.hasWarnings, isTrue);
+      expect(s.hasOnlyWarnings, isFalse);
+    });
+
+    test('10. from authoring: warnings-only (unused) → hasOnlyWarnings', () {
+      final c = _catalog(
+        atlases: [_atlas('orphan')],
+        animations: [
+          _animation('orphan-anim', atlasId: 'orphan'),
+        ],
+        presets: const [],
+      );
+      final report = diagnoseProjectSurfaceCatalogForAuthoring(c);
+      final s = summarizeSurfaceCatalogDiagnostics(report);
+      expect(s.hasOnlyWarnings, isTrue);
+      expect(s.hasErrors, isFalse);
+    });
+
+    test('11. value equality: equivalent reports → same summary hash/==', () {
+      final a = <SurfaceCatalogDiagnostic>[
+        _diagnostic(
+          severity: SurfaceCatalogDiagnosticSeverity.error,
+          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+          message: 'm',
+        ),
+      ];
+      final s1 = summarizeSurfaceCatalogDiagnostics(_report(a));
+      final s2 = summarizeSurfaceCatalogDiagnostics(_report(List.from(a)));
+      expect(s1, s2);
+      expect(s1.hashCode, s2.hashCode);
+    });
+
+    test('12. value inequality: different error/warning split (same total)',
+        () {
+      final sErr = summarizeSurfaceCatalogDiagnostics(
+        _report([
+          _diagnostic(
+            severity: SurfaceCatalogDiagnosticSeverity.error,
+            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+          ),
+        ]),
+      );
+      final sWarn = summarizeSurfaceCatalogDiagnostics(
+        _report([
+          _diagnostic(
+            severity: SurfaceCatalogDiagnosticSeverity.warning,
+            kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
+            atlasId: 'x',
+          ),
+        ]),
+      );
+      expect(sErr.totalCount, sWarn.totalCount);
+      expect(sErr, isNot(sWarn));
+    });
+
+    test('13. value inequality: same severity totals, different byKind', () {
+      final s1 = summarizeSurfaceCatalogDiagnostics(
+        _report([
+          _diagnostic(
+            severity: SurfaceCatalogDiagnosticSeverity.error,
+            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+          ),
+        ]),
+      );
+      final s2 = summarizeSurfaceCatalogDiagnostics(
+        _report([
+          _diagnostic(
+            severity: SurfaceCatalogDiagnosticSeverity.error,
+            kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
+            atlasId: 'x',
+            animationId: 'a',
+          ),
+        ]),
+      );
+      expect(s1.totalCount, s2.totalCount);
+      expect(s1.errorCount, s2.errorCount);
+      expect(s1, isNot(s2));
+    });
+
+    test('14. public API via map_core', () {
+      final s = summarizeSurfaceCatalogDiagnostics(
+        SurfaceCatalogDiagnosticsReport(diagnostics: const []),
+      );
+      expect(s, isA<SurfaceCatalogDiagnosticsSummary>());
+    });
+
+    test('15. ProjectManifest still has no Surface keys (Lot 37)', () {
+      const manifest = ProjectManifest(
+        name: 'L37',
+        maps: [
+          ProjectMapEntry(
+            id: 'm1',
+            name: 'M',
+            relativePath: 'maps/m1.json',
+          ),
+        ],
+        tilesets: [],
+      );
+      final j = manifest.toJson();
+      for (final k in const [
+        'surfaceDefinitions',
+        'surfaceAtlases',
+        'surfaceAnimations',
+        'surfacePresets',
+        'surfaceCategories',
+      ]) {
+        expect(j.containsKey(k), isFalse, reason: k);
+      }
+    });
+
+    test('16. no unusedPreset kind; severities are error and warning only', () {
+      final names =
+          SurfaceCatalogDiagnosticKind.values.map((e) => e.name).toList();
+      expect(names.contains('unusedPreset'), isFalse);
+      final sev = SurfaceCatalogDiagnosticSeverity.values
+          .map((e) => e.name)
+          .toList()
+        ..sort();
+      expect(sev, ['error', 'warning']);
+    });
+  });
+}
```



#### Rapport lui-même (exception contractuelle : pas de re-coller le diff ici en double)

Un diff ajoutant ce fichier depuis `/dev/null` serait, ligne par ligne, identique à préfixer chaque ligne du corps Markdown ci-dessus par `+` ; le corps entier de la preuve est le présent `surface_engine_lot_37_*.md` (sections 1–35) sans répétition numérotée ailleurs.

### 35.D. Autres sorties (régression, suite complète)

#### Régression `surface_catalog_authoring_diagnostics_test.dart` (Lot 36) — intégral

```text
00:00 [32m+0[0m: [1m[90mloading test/surface_catalog_authoring_diagnostics_test.dart[0m[0m                                                                                                                                 00:00 [32m+0[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 1. empty catalog: no diagnostics[0m                                                                                                          00:00 [32m+1[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 1. empty catalog: no diagnostics[0m                                                                                                          00:00 [32m+1[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 2. minimal coherent: no diagnostics[0m                                                                                                       00:00 [32m+2[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 2. minimal coherent: no diagnostics[0m                                                                                                       00:00 [32m+2[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 3. error only: missing preset animation[0m                                                                                                   00:00 [32m+3[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 3. error only: missing preset animation[0m                                                                                                   00:00 [32m+3[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 4. warning only: unused atlas[0m                                                                                                             00:00 [32m+4[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 4. warning only: unused atlas[0m                                                                                                             00:00 [32m+4[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 5. warning only: unused animation, no unusedAtlas[0m                                                                                         00:00 [32m+5[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 5. warning only: unused animation, no unusedAtlas[0m                                                                                         00:00 [32m+5[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 6. error + warnings: order errors then unusedAtlas then unusedAnimation[0m                                                                   00:00 [32m+6[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 6. error + warnings: order errors then unusedAtlas then unusedAnimation[0m                                                                   00:00 [32m+6[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 7. two preset errors: Lot 34 order preserved at start of report[0m                                                                           00:00 [32m+7[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 7. two preset errors: Lot 34 order preserved at start of report[0m                                                                           00:00 [32m+7[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 8. many unusedAtlas then many unusedAnimation: Lot 35 order in tail[0m                                                                       00:00 [32m+8[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 8. many unusedAtlas then many unusedAnimation: Lot 35 order in tail[0m                                                                       00:00 [32m+8[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 9. no dedup: missingAnimationAtlas + unusedAnimation same anim[0m                                                                            00:00 [32m+9[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 9. no dedup: missingAnimationAtlas + unusedAnimation same anim[0m                                                                            00:00 [32m+9[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 10. warnings only: hasErrors false[0m                                                                                                        00:00 [32m+10[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 10. warnings only: hasErrors false[0m                                                                                                       00:00 [32m+10[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 11. errors + warnings: hasErrors true[0m                                                                                                    00:00 [32m+11[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 11. errors + warnings: hasErrors true[0m                                                                                                    00:00 [32m+11[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 12. byKind on combined report[0m                                                                                                            00:00 [32m+12[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 12. byKind on combined report[0m                                                                                                            00:00 [32m+12[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 13. diagnostics list is unmodifiable[0m                                                                                                     00:00 [32m+13[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 13. diagnostics list is unmodifiable[0m                                                                                                     00:00 [32m+13[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 14. catalog lists unchanged after call[0m                                                                                                   00:00 [32m+14[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 14. catalog lists unchanged after call[0m                                                                                                   00:00 [32m+14[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 15. Lot 34 alone: no unusedAtlas for orphan atlas[0m                                                                                        00:00 [32m+15[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 15. Lot 34 alone: no unusedAtlas for orphan atlas[0m                                                                                        00:00 [32m+15[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 16. Lot 35 alone: no missingPresetAnimation for broken ref[0m                                                                               00:00 [32m+16[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 16. Lot 35 alone: no missingPresetAnimation for broken ref[0m                                                                               00:00 [32m+16[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 17. V0: coherent preset, no spurious preset-targeted unused rule[0m                                                                         00:00 [32m+17[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 17. V0: coherent preset, no spurious preset-targeted unused rule[0m                                                                         00:00 [32m+17[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 18. public API via map_core[0m                                                                                                              00:00 [32m+18[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 18. public API via map_core[0m                                                                                                              00:00 [32m+18[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 19. ProjectManifest still has no Surface keys (Lot 36)[0m                                                                                   00:00 [32m+19[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 19. ProjectManifest still has no Surface keys (Lot 36)[0m                                                                                   00:00 [32m+19[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 20. no unusedPreset kind; severities are error and warning only[0m                                                                          00:00 [32m+20[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 20. no unusedPreset kind; severities are error and warning only[0m                                                                          00:00 [32m+20[0m: All tests passed![0m
```

#### Régression `surface_catalog_diagnostics_test.dart` (Lot 34) — intégral

```text
00:00 [32m+0[0m: [1m[90mloading test/surface_catalog_diagnostics_test.dart[0m[0m                                                                                                                                           00:00 [32m+0[0m: diagnoseProjectSurfaceCatalog (Lot 34) 1. empty catalog: no diagnostics[0m                                                                                                                      00:00 [32m+1[0m: diagnoseProjectSurfaceCatalog (Lot 34) 1. empty catalog: no diagnostics[0m                                                                                                                      00:00 [32m+1[0m: diagnoseProjectSurfaceCatalog (Lot 34) 2. minimal coherent: no diagnostics[0m                                                                                                                   00:00 [32m+2[0m: diagnoseProjectSurfaceCatalog (Lot 34) 2. minimal coherent: no diagnostics[0m                                                                                                                   00:00 [32m+2[0m: diagnoseProjectSurfaceCatalog (Lot 34) 3. missing preset animation[0m                                                                                                                           00:00 [32m+3[0m: diagnoseProjectSurfaceCatalog (Lot 34) 3. missing preset animation[0m                                                                                                                           00:00 [32m+3[0m: diagnoseProjectSurfaceCatalog (Lot 34) 4. two missing refs: order follows refs[0m                                                                                                               00:00 [32m+4[0m: diagnoseProjectSurfaceCatalog (Lot 34) 4. two missing refs: order follows refs[0m                                                                                                               00:00 [32m+4[0m: diagnoseProjectSurfaceCatalog (Lot 34) 5. two presets: order follows catalog.presets[0m                                                                                                         00:00 [32m+5[0m: diagnoseProjectSurfaceCatalog (Lot 34) 5. two presets: order follows catalog.presets[0m                                                                                                         00:00 [32m+5[0m: diagnoseProjectSurfaceCatalog (Lot 34) 6. missing animation atlas[0m                                                                                                                            00:00 [32m+6[0m: diagnoseProjectSurfaceCatalog (Lot 34) 6. missing animation atlas[0m                                                                                                                            00:00 [32m+6[0m: diagnoseProjectSurfaceCatalog (Lot 34) 7. two frames to missing atlas: frameIndex 0 and 1[0m                                                                                                    00:00 [32m+7[0m: diagnoseProjectSurfaceCatalog (Lot 34) 7. two frames to missing atlas: frameIndex 0 and 1[0m                                                                                                    00:00 [32m+7[0m: diagnoseProjectSurfaceCatalog (Lot 34) 8. frame outside geometry: column[0m                                                                                                                     00:00 [32m+8[0m: diagnoseProjectSurfaceCatalog (Lot 34) 8. frame outside geometry: column[0m                                                                                                                     00:00 [32m+8[0m: diagnoseProjectSurfaceCatalog (Lot 34) 9. frame outside geometry: row[0m                                                                                                                        00:00 [32m+9[0m: diagnoseProjectSurfaceCatalog (Lot 34) 9. frame outside geometry: row[0m                                                                                                                        00:00 [32m+9[0m: diagnoseProjectSurfaceCatalog (Lot 34) 10. missing atlas only: not also outside geometry[0m                                                                                                     00:00 [32m+10[0m: diagnoseProjectSurfaceCatalog (Lot 34) 10. missing atlas only: not also outside geometry[0m                                                                                                    00:00 [32m+10[0m: diagnoseProjectSurfaceCatalog (Lot 34) 11. preset diagnostics then animation diagnostics[0m                                                                                                    00:00 [32m+11[0m: diagnoseProjectSurfaceCatalog (Lot 34) 11. preset diagnostics then animation diagnostics[0m                                                                                                    00:00 [32m+11[0m: diagnoseProjectSurfaceCatalog (Lot 34) 12. exact atlas id: no trim[0m                                                                                                                          00:00 [32m+12[0m: diagnoseProjectSurfaceCatalog (Lot 34) 12. exact atlas id: no trim[0m                                                                                                                          00:00 [32m+12[0m: diagnoseProjectSurfaceCatalog (Lot 34) 13. byKind filters[0m                                                                                                                                   00:00 [32m+13[0m: diagnoseProjectSurfaceCatalog (Lot 34) 13. byKind filters[0m                                                                                                                                   00:00 [32m+13[0m: diagnoseProjectSurfaceCatalog (Lot 34) 14. byKind list is unmodifiable[0m                                                                                                                      00:00 [32m+14[0m: diagnoseProjectSurfaceCatalog (Lot 34) 14. byKind list is unmodifiable[0m                                                                                                                      00:00 [32m+14[0m: diagnoseProjectSurfaceCatalog (Lot 34) 15. diagnostics list on report is unmodifiable[0m                                                                                                       00:00 [32m+15[0m: diagnoseProjectSurfaceCatalog (Lot 34) 15. diagnostics list on report is unmodifiable[0m                                                                                                       00:00 [32m+15[0m: diagnoseProjectSurfaceCatalog (Lot 34) 16. defensive copy: mutating source list does not change report[0m                                                                                      00:00 [32m+16[0m: diagnoseProjectSurfaceCatalog (Lot 34) 16. defensive copy: mutating source list does not change report[0m                                                                                      00:00 [32m+16[0m: diagnoseProjectSurfaceCatalog (Lot 34) 17. hasErrors false on empty report[0m                                                                                                                  00:00 [32m+17[0m: diagnoseProjectSurfaceCatalog (Lot 34) 17. hasErrors false on empty report[0m                                                                                                                  00:00 [32m+17[0m: diagnoseProjectSurfaceCatalog (Lot 34) 18. hasErrors true when error diagnostic[0m                                                                                                             00:00 [32m+18[0m: diagnoseProjectSurfaceCatalog (Lot 34) 18. hasErrors true when error diagnostic[0m                                                                                                             00:00 [32m+18[0m: diagnoseProjectSurfaceCatalog (Lot 34) 19. diagnostic equality: same[0m                                                                                                                        00:00 [32m+19[0m: diagnoseProjectSurfaceCatalog (Lot 34) 19. diagnostic equality: same[0m                                                                                                                        00:00 [32m+19[0m: diagnoseProjectSurfaceCatalog (Lot 34) 20. diagnostic equality: different kind[0m                                                                                                              00:00 [32m+20[0m: diagnoseProjectSurfaceCatalog (Lot 34) 20. diagnostic equality: different kind[0m                                                                                                              00:00 [32m+20[0m: diagnoseProjectSurfaceCatalog (Lot 34) 21. diagnostic equality: different metadata[0m                                                                                                          00:00 [32m+21[0m: diagnoseProjectSurfaceCatalog (Lot 34) 21. diagnostic equality: different metadata[0m                                                                                                          00:00 [32m+21[0m: diagnoseProjectSurfaceCatalog (Lot 34) 22. report equality: same order[0m                                                                                                                      00:00 [32m+22[0m: diagnoseProjectSurfaceCatalog (Lot 34) 22. report equality: same order[0m                                                                                                                      00:00 [32m+22[0m: diagnoseProjectSurfaceCatalog (Lot 34) 23. report equality: order matters[0m                                                                                                                   00:00 [32m+23[0m: diagnoseProjectSurfaceCatalog (Lot 34) 23. report equality: order matters[0m                                                                                                                   00:00 [32m+23[0m: diagnoseProjectSurfaceCatalog (Lot 34) 24. public API via map_core[0m                                                                                                                          00:00 [32m+24[0m: diagnoseProjectSurfaceCatalog (Lot 34) 24. public API via map_core[0m                                                                                                                          00:00 [32m+24[0m: diagnoseProjectSurfaceCatalog (Lot 34) 25. ProjectManifest still has no Surface keys (Lot 34)[0m                                                                                               00:00 [32m+25[0m: diagnoseProjectSurfaceCatalog (Lot 34) 25. ProjectManifest still has no Surface keys (Lot 34)[0m                                                                                               00:00 [32m+25[0m: All tests passed![0m
```

#### Régression `surface_catalog_unused_diagnostics_test.dart` (Lot 35) — intégral

```text
00:00 [32m+0[0m: [1m[90mloading test/surface_catalog_unused_diagnostics_test.dart[0m[0m                                                                                                                                    00:00 [32m+0[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 1. empty catalog: no unused diagnostics[0m                                                                                                00:00 [32m+1[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 1. empty catalog: no unused diagnostics[0m                                                                                                00:00 [32m+1[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 2. minimal coherent: no unused diagnostics[0m                                                                                             00:00 [32m+2[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 2. minimal coherent: no unused diagnostics[0m                                                                                             00:00 [32m+2[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 3. unreferenced atlas → unusedAtlas warning and metadata[0m                                                                               00:00 [32m+3[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 3. unreferenced atlas → unusedAtlas warning and metadata[0m                                                                               00:00 [32m+3[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 4. multiple unused atlases: order follows catalog.atlases a,b,c[0m                                                                        00:00 [32m+4[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 4. multiple unused atlases: order follows catalog.atlases a,b,c[0m                                                                        00:00 [32m+4[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 5. atlas used by a frame: no unusedAtlas (may be unusedAnimation)[0m                                                                      00:00 [32m+5[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 5. atlas used by a frame: no unusedAtlas (may be unusedAnimation)[0m                                                                      00:00 [32m+5[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 6. atlas id exact: spaced atlas not matched by frame atlasId[0m                                                                           00:00 [32m+6[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 6. atlas id exact: spaced atlas not matched by frame atlasId[0m                                                                           00:00 [32m+6[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 7. animation not referenced by preset → unusedAnimation[0m                                                                                00:00 [32m+7[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 7. animation not referenced by preset → unusedAnimation[0m                                                                                00:00 [32m+7[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 8. multiple unused animations: order follows catalog.animations a,b,c[0m                                                                  00:00 [32m+8[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 8. multiple unused animations: order follows catalog.animations a,b,c[0m                                                                  00:00 [32m+8[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 9. animation referenced by a preset: not unused[0m                                                                                        00:00 [32m+9[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 9. animation referenced by a preset: not unused[0m                                                                                        00:00 [32m+9[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 10. animationId exact: spaced id not matched by preset ref[0m                                                                             00:00 [32m+10[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 10. animationId exact: spaced id not matched by preset ref[0m                                                                            00:00 [32m+10[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 11. same animation referenced by two presets: not unused[0m                                                                              00:00 [32m+11[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 11. same animation referenced by two presets: not unused[0m                                                                              00:00 [32m+11[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 12. same atlas referenced by two animations: atlas not unused[0m                                                                         00:00 [32m+12[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 12. same atlas referenced by two animations: atlas not unused[0m                                                                         00:00 [32m+12[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 13. global order: unusedAtlas before unusedAnimation[0m                                                                                  00:00 [32m+13[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 13. global order: unusedAtlas before unusedAnimation[0m                                                                                  00:00 [32m+13[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 14. warnings only: hasErrors false, hasDiagnostics true[0m                                                                               00:00 [32m+14[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 14. warnings only: hasErrors false, hasDiagnostics true[0m                                                                               00:00 [32m+14[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 15. byKind(unusedAtlas) only atlas warnings[0m                                                                                           00:00 [32m+15[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 15. byKind(unusedAtlas) only atlas warnings[0m                                                                                           00:00 [32m+15[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 16. byKind(unusedAnimation) only animation warnings[0m                                                                                   00:00 [32m+16[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 16. byKind(unusedAnimation) only animation warnings[0m                                                                                   00:00 [32m+16[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 17. byKind returns an unmodifiable list (add → UnsupportedError)[0m                                                                      00:00 [32m+17[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 17. byKind returns an unmodifiable list (add → UnsupportedError)[0m                                                                      00:00 [32m+17[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 18. diagnostics list is unmodifiable (add → UnsupportedError)[0m                                                                         00:00 [32m+18[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 18. diagnostics list is unmodifiable (add → UnsupportedError)[0m                                                                         00:00 [32m+18[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 19. unused function does not emit Lot 34 error kinds[0m                                                                                  00:00 [32m+19[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 19. unused function does not emit Lot 34 error kinds[0m                                                                                  00:00 [32m+19[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 20. Lot 34 diagnoseProjectSurfaceCatalog still returns errors[0m                                                                         00:00 [32m+20[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 20. Lot 34 diagnoseProjectSurfaceCatalog still returns errors[0m                                                                         00:00 [32m+20[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 21. warning severity exists and differs from error[0m                                                                                    00:00 [32m+21[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 21. warning severity exists and differs from error[0m                                                                                    00:00 [32m+21[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) V0 does not diagnose unused presets yet: isolated preset, no false presetId[0m                                                           00:00 [32m+22[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) V0 does not diagnose unused presets yet: isolated preset, no false presetId[0m                                                           00:00 [32m+22[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 23. public API: unused + kinds via map_core only[0m                                                                                      00:00 [32m+23[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 23. public API: unused + kinds via map_core only[0m                                                                                      00:00 [32m+23[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 24. ProjectManifest still has no Surface keys (Lot 35)[0m                                                                                00:00 [32m+24[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 24. ProjectManifest still has no Surface keys (Lot 35)[0m                                                                                00:00 [32m+24[0m: All tests passed![0m
```

#### Dernière ligne de la sortie de `dart test` (suite entière) — reprise §29

```text
00:01 +843: All tests passed!
```

(Préambule d’analyse : déjà en §28.)

## 35.E. Auto-check (substituts de preuve)

Recherche des douze tournures interdites (liste dans le cahier des lots, **non reprise ici** pour éviter un faux positif de détection) sur ce fichier : 0 utilisation en substitution d’une preuve contractuelle. Les preuves demandées sont intégrées en §35.
