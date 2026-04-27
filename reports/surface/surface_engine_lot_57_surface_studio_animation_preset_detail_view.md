# Lot 57 — Surface Studio Animation Detail / Preset Detail V0

## Résumé exécutif

Implémentation de deux vues **lecture seule** `SurfaceStudioAnimationDetailView` et `SurfaceStudioPresetDetailView` dans `map_editor`, consommant exclusivement `SurfaceStudioReadModel` (listes `animations` / `presets` et lignes `SurfaceStudioAnimationReadModel` / `SurfaceStudioPresetReadModel` du Lot 51). Intégration dans `SurfaceStudioCatalogBrowser` à la suite d’`SurfaceStudioAtlasDetailView`. Aucun changement `map_core`, pas de provider, pas d’I/O, pas d’édition. Tests widget dédiés + ajustement des tests browser / panel / workspace. Suite `test/surface_studio/` (7 fichiers) : **163** tests, ligne finale : `+163: All tests passed!`. Analyse : `No issues found!`. Suite `flutter test` **complète** `map_editor` : **636** passés, **41** échoués (dette préexistante, hors Surface Studio).

## Passes (obligatoires)

1. **Audit / architecture** : reprise du browser Lot 54/56, read models Lot 51, pattern `EditorChrome` / îlots.  
2. **Implémentation** : vues + branchement browser.  
3. **Tests** : 22 + 22 cas + régressions intégration.  
4. **Validation** : `dart format`, `flutter test` ciblé, suite combinée `surface_studio`, `flutter analyze`, `dart test` map_core `surface_studio_read_model_test.dart`.  
5. **Review critique** : vérification read-only, pas de recalcul d’ids référencés côté UI, labels FR pour rôles.  
6. **Evidence Pack** : ce fichier (sections A–D ci-dessous).

## Tableau des lots 39–61 (obligatoire)

| Lot | Intitulé | Statut |
|-----|----------|--------|
| 39 | ProjectSurfaceAtlas JSON Codec V0 | fait |
| 40 | Surface TileRef / AnimationFrame JSON Codec V0 | fait |
| 41 | SurfaceAnimationTimeline JSON Codec V0 | fait |
| 42 | ProjectSurfaceAnimation JSON Codec V0 | fait |
| 43 | SurfaceVariantAnimationRef JSON Codec V0 | fait |
| 44 | SurfaceVariantAnimationRefSet JSON Codec V0 | fait |
| 45 | ProjectSurfacePreset JSON Codec V0 | fait |
| 46 | ProjectSurfaceCatalog JSON Codec V0 | fait |
| 47 | Surface JSON Golden Samples / Characterization | fait |
| 48 | ProjectManifest Surface Integration Prep | fait |
| 49 | ProjectManifest Surface Integration V0 | fait |
| 50 | Surface Catalog Manifest Operations / Use Cases Prep | fait |
| 51 | Surface Studio Read Model Prep | fait |
| 52 | Surface Studio Panel Shell V0 | fait |
| 53 | Surface Studio Workspace Entry V0 | fait |
| 54 | Surface Studio Catalog Browser V0 | fait |
| 55 | Surface Studio Catalog Diagnostics View V0 | fait |
| 56 | Surface Studio Atlas Detail / Empty State V0 | fait |
| **57** | **Surface Studio Animation Detail / Preset Detail V0** | **ce lot** |
| 58 | Surface Studio Selection State V0 | prochain probable |
| 59 | Surface Studio Authoring Prep V0 | ensuite probable |
| 60 | Surface Studio Atlas Authoring Prep V0 | ensuite probable |
| 61 | Surface Studio Animation Authoring Prep V0 | ensuite probable |

## `git status --short --untracked-files=all`

### Initial (début de session agent — snapshot conversation)

```
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/standard_path_preset_vertical_atlas_builder.dart
?? packages/map_core/test/standard_path_preset_vertical_atlas_builder_test.dart
?? reports/surface/surface_engine_lot_15_standard_path_preset_vertical_atlas_builder.md
```

(Travail **hors Lot 57** : lots map_core 15/16 non commités. Le Lot 57 ne les modifie pas.)

### Final (après implémentation Lot 57, lecture seule)

```
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart
 M packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_animation_detail_view.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_preset_detail_view.dart
?? packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart
?? reports/surface/surface_engine_lot_57_surface_studio_animation_preset_detail_view.md
```

## Changements préexistants vs Lot 57

- **Préexistants (non modifiés par ce lot)** : chemins `map_core` / rapport Lot 15 listés au statut initial.  
- **Introduits par Lot 57** : 4 chemins `map_editor` (2 lib + 2 test) + 1 rapport ; modifications 4 fichiers `map_editor` (browser + 3 tests).

## Fichiers consultés (audit)

- `surface_studio_catalog_browser.dart`, `surface_studio_atlas_detail_view.dart`, `surface_studio_diagnostics_view.dart`, `surface_studio_panel.dart`  
- Tests existants `surface_studio_*_test.dart`  
- `packages/map_core/lib/src/operations/surface_studio_read_model.dart` (lecture seule)  
- Rapports Surface 54–56 (contexte)

## Décisions d’architecture (condensé)

- Vues **StatelessWidget** ; données = `readModel` uniquement.  
- Pas de `ProjectSurfaceCatalog` direct dans l’UI ; pas de recompute de `referencedAtlasIds` / `referencedAnimationIds` / rôles.  
- Diagnostics : non réaffichés ici (restent dans `SurfaceStudioPanel`).  
- Ordre : itération sur `readModel.animations` / `readModel.presets` telles que listées.  
- **Pourquoi read-only** : même contrat que Lots 52–56 — pas d’édition auteur dans cette couche.  
- **Pourquoi read models** : seule source de vérité pour champs dérivés (compteurs, listes, couverture) sans dupliquer la logique du Lot 51.

## Pourquoi pas de modification `map_core`

Les champs requis existent déjà sur `SurfaceStudioAnimationReadModel` / `SurfaceStudioPresetReadModel` ; l’UI ne fait qu’afficher.

---

## A. Fichiers créés — contenu intégral

### A.1 `packages/map_editor/lib/src/features/surface_studio/surface_studio_animation_detail_view.dart`

\`\`\`dart
// Surface Studio — détail des animations (Lot 57).
//
// Lecture seule : affiche uniquement [SurfaceStudioReadModel.animations] et les
// champs dérivés de [SurfaceStudioAnimationReadModel] (Lot 51). Aucun catalogue
// brut, aucun re-calcul des atlas référencés, aucun JSON, aucun I/O, aucune
// mutation de manifest.

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';

/// Textes visibles (aucun nom de type interne dans l’UI).
class SurfaceStudioAnimationDetailViewLabels {
  const SurfaceStudioAnimationDetailViewLabels._();

  static const String title = 'Animations Surface';
  static const String emptyTitle = 'Aucune animation Surface';
  static const String emptyHint =
      'Les animations décrivent les frames utilisées par les surfaces animées.';

  static const String labelIdentifiant = 'Identifiant';
  static const String labelFrames = 'Frames';
  static const String labelDureeTotale = 'Durée totale';
  static const String labelAtlasRef = 'Atlas référencés';
  static const String labelSync = 'Groupe de synchronisation';
  static const String labelCategorie = 'Catégorie';
  static const String labelOrdre = 'Ordre';

  static const String syncAucun = 'Aucun groupe';
  static const String categorieAucune = 'Aucune catégorie';
  static const String aucunAtlas = 'Aucun atlas référencé';

  static String framesLigne(int n) {
    if (n <= 1) {
      return '1 frame';
    }
    return '$n frames';
  }

  static String atlasRefSummary(int n) {
    if (n <= 0) {
      return aucunAtlas;
    }
    if (n == 1) {
      return '1 atlas référencé';
    }
    return '$n atlas référencés';
  }
}

/// Fiches animations **lecture seule** : ordre = [SurfaceStudioReadModel.animations].
class SurfaceStudioAnimationDetailView extends StatelessWidget {
  const SurfaceStudioAnimationDetailView({
    super.key,
    required this.readModel,
  });

  final SurfaceStudioReadModel readModel;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          SurfaceStudioAnimationDetailViewLabels.title,
          style: TextStyle(
            color: label,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        if (readModel.animations.isEmpty) ...[
          Text(
            SurfaceStudioAnimationDetailViewLabels.emptyTitle,
            style: TextStyle(
              color: subtle,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            SurfaceStudioAnimationDetailViewLabels.emptyHint,
            style: TextStyle(
              color: subtle,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ] else
          ...readModel.animations.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AnimationFiche(
                row: row,
                label: label,
                subtle: subtle,
              ),
            ),
          ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context),
          width: 1,
        ),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: child,
    );
  }
}

class _KeyVal extends StatelessWidget {
  const _KeyVal({
    required this.k,
    required this.v,
    required this.valueColor,
  });

  final String k;
  final String v;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '$k : $v',
        style: TextStyle(
          color: valueColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
      ),
    );
  }
}

class _AnimationFiche extends StatelessWidget {
  const _AnimationFiche({
    required this.row,
    required this.label,
    required this.subtle,
  });

  final SurfaceStudioAnimationReadModel row;
  final Color label;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    final refIds = row.referencedAtlasIds;
    final nAtlas = refIds.length;
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.name,
            style: TextStyle(
              color: label,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          _KeyVal(
            k: SurfaceStudioAnimationDetailViewLabels.labelIdentifiant,
            v: row.id,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioAnimationDetailViewLabels.labelFrames,
            v: SurfaceStudioAnimationDetailViewLabels.framesLigne(
              row.frameCount,
            ),
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioAnimationDetailViewLabels.labelDureeTotale,
            v: '${row.totalDurationMs} ms',
            valueColor: label,
          ),
          const SizedBox(height: 4),
          Text(
            SurfaceStudioAnimationDetailViewLabels.labelAtlasRef,
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              SurfaceStudioAnimationDetailViewLabels.atlasRefSummary(nAtlas),
              style: TextStyle(
                color: label,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (nAtlas > 0)
            ...refIds.map(
              (id) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  id,
                  style: TextStyle(
                    color: label,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          _KeyVal(
            k: SurfaceStudioAnimationDetailViewLabels.labelSync,
            v: row.syncGroupId == null || row.syncGroupId!.isEmpty
                ? SurfaceStudioAnimationDetailViewLabels.syncAucun
                : row.syncGroupId!,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioAnimationDetailViewLabels.labelCategorie,
            v: row.categoryId == null || row.categoryId!.isEmpty
                ? SurfaceStudioAnimationDetailViewLabels.categorieAucune
                : row.categoryId!,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioAnimationDetailViewLabels.labelOrdre,
            v: row.sortOrder.toString(),
            valueColor: label,
          ),
        ],
      ),
    );
  }
}
```

### A.2 `packages/map_editor/lib/src/features/surface_studio/surface_studio_preset_detail_view.dart`

```dart
// Surface Studio — détail des presets (Lot 57).
//
// Lecture seule : affiche uniquement [SurfaceStudioReadModel.presets] et les
// champs dérivés de [SurfaceStudioPresetReadModel] (Lot 51). Aucun catalogue
// brut, aucun re-calcul des animations liées ni des rôles, aucun JSON, aucun I/O,
// aucune mutation de manifest.

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';

/// Libellé français pour [SurfaceVariantRole] (affichage auteur, pas le nom d’énum brut).
String surfaceStudioSurfaceVariantRoleLabel(SurfaceVariantRole role) {
  switch (role) {
    case SurfaceVariantRole.isolated:
      return 'Isolé';
    case SurfaceVariantRole.endNorth:
      return 'Fin nord';
    case SurfaceVariantRole.endEast:
      return 'Fin est';
    case SurfaceVariantRole.endSouth:
      return 'Fin sud';
    case SurfaceVariantRole.endWest:
      return 'Fin ouest';
    case SurfaceVariantRole.horizontal:
      return 'Horizontal';
    case SurfaceVariantRole.vertical:
      return 'Vertical';
    case SurfaceVariantRole.cornerNE:
      return 'Coin nord-est';
    case SurfaceVariantRole.cornerSE:
      return 'Coin sud-est';
    case SurfaceVariantRole.cornerSW:
      return 'Coin sud-ouest';
    case SurfaceVariantRole.cornerNW:
      return 'Coin nord-ouest';
    case SurfaceVariantRole.innerCornerNE:
      return 'Coin intérieur nord-est';
    case SurfaceVariantRole.innerCornerSE:
      return 'Coin intérieur sud-est';
    case SurfaceVariantRole.innerCornerSW:
      return 'Coin intérieur sud-ouest';
    case SurfaceVariantRole.innerCornerNW:
      return 'Coin intérieur nord-ouest';
    case SurfaceVariantRole.teeNorth:
      return 'T nord';
    case SurfaceVariantRole.teeEast:
      return 'T est';
    case SurfaceVariantRole.teeSouth:
      return 'T sud';
    case SurfaceVariantRole.teeWest:
      return 'T ouest';
    case SurfaceVariantRole.cross:
      return 'Croix';
  }
}

/// Textes visibles (aucun nom de type interne dans l’UI).
class SurfaceStudioPresetDetailViewLabels {
  const SurfaceStudioPresetDetailViewLabels._();

  static const String title = 'Presets Surface';
  static const String emptyTitle = 'Aucun preset Surface';
  static const String emptyHint =
      'Les presets associent des rôles de surface à des animations.';

  static const String labelIdentifiant = 'Identifiant';
  static const String labelVariantes = 'Variantes';
  static const String labelRoles = 'Rôles';
  static const String labelAnimationsLiees = 'Animations liées';
  static const String labelCouverture = 'Couverture standard';
  static const String labelCategorie = 'Catégorie';
  static const String labelOrdre = 'Ordre';

  static const String categorieAucune = 'Aucune catégorie';
  static const String couverturePleine = 'Rôles standards complets';
  static const String couverturePartielle = 'Rôles standards incomplets';
  static const String aucuneAnimLiee = 'Aucune animation liée';

  static String variantesLigne(int n) {
    if (n <= 1) {
      return '1 variante';
    }
    return '$n variantes';
  }

  static String animationsLieesSummary(int n) {
    if (n <= 0) {
      return aucuneAnimLiee;
    }
    if (n == 1) {
      return '1 animation liée';
    }
    return '$n animations liées';
  }
}

/// Fiches presets **lecture seule** : ordre = [SurfaceStudioReadModel.presets].
class SurfaceStudioPresetDetailView extends StatelessWidget {
  const SurfaceStudioPresetDetailView({
    super.key,
    required this.readModel,
  });

  final SurfaceStudioReadModel readModel;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          SurfaceStudioPresetDetailViewLabels.title,
          style: TextStyle(
            color: label,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        if (readModel.presets.isEmpty) ...[
          Text(
            SurfaceStudioPresetDetailViewLabels.emptyTitle,
            style: TextStyle(
              color: subtle,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            SurfaceStudioPresetDetailViewLabels.emptyHint,
            style: TextStyle(
              color: subtle,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ] else
          ...readModel.presets.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PresetFiche(
                row: row,
                label: label,
                subtle: subtle,
              ),
            ),
          ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context),
          width: 1,
        ),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: child,
    );
  }
}

class _KeyVal extends StatelessWidget {
  const _KeyVal({
    required this.k,
    required this.v,
    required this.valueColor,
  });

  final String k;
  final String v;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '$k : $v',
        style: TextStyle(
          color: valueColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
      ),
    );
  }
}

class _PresetFiche extends StatelessWidget {
  const _PresetFiche({
    required this.row,
    required this.label,
    required this.subtle,
  });

  final SurfaceStudioPresetReadModel row;
  final Color label;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    final animIds = row.referencedAnimationIds;
    final nAnim = animIds.length;
    final roleLabels = row.roles.map(surfaceStudioSurfaceVariantRoleLabel);
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.name,
            style: TextStyle(
              color: label,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          _KeyVal(
            k: SurfaceStudioPresetDetailViewLabels.labelIdentifiant,
            v: row.id,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioPresetDetailViewLabels.labelVariantes,
            v: SurfaceStudioPresetDetailViewLabels.variantesLigne(
              row.variantCount,
            ),
            valueColor: label,
          ),
          const SizedBox(height: 4),
          Text(
            SurfaceStudioPresetDetailViewLabels.labelRoles,
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          ...roleLabels.map(
            (r) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                r,
                style: TextStyle(
                  color: label,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            SurfaceStudioPresetDetailViewLabels.labelAnimationsLiees,
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              SurfaceStudioPresetDetailViewLabels.animationsLieesSummary(
                nAnim,
              ),
              style: TextStyle(
                color: label,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (nAnim > 0)
            ...animIds.map(
              (id) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  id,
                  style: TextStyle(
                    color: label,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            SurfaceStudioPresetDetailViewLabels.labelCouverture,
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              row.coversStandardRoles
                  ? SurfaceStudioPresetDetailViewLabels.couverturePleine
                  : SurfaceStudioPresetDetailViewLabels.couverturePartielle,
              style: TextStyle(
                color: label,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _KeyVal(
            k: SurfaceStudioPresetDetailViewLabels.labelCategorie,
            v: row.categoryId == null || row.categoryId!.isEmpty
                ? SurfaceStudioPresetDetailViewLabels.categorieAucune
                : row.categoryId!,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioPresetDetailViewLabels.labelOrdre,
            v: row.sortOrder.toString(),
            valueColor: label,
          ),
        ],
      ),
    );
  }
}
```

### A.3 `packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart`

```dart
// Tests widget — Surface Studio animation detail (Lot 57).
// API publique `map_core` uniquement (pas de `package:map_core/src/...`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_animation_detail_view.dart';

void main() {
  group('SurfaceStudioAnimationDetailView (Lot 57)', () {
    testWidgets('1. title Animations Surface', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioAnimationDetailView(readModel: _emptyReadModel())),
      );
      expect(find.text('Animations Surface'), findsOneWidget);
    });

    testWidgets('2. empty: main message', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioAnimationDetailView(readModel: _emptyReadModel())),
      );
      expect(find.text('Aucune animation Surface'), findsOneWidget);
    });

    testWidgets('3. empty: explainer', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioAnimationDetailView(readModel: _emptyReadModel())),
      );
      final t = _allText(tester);
      expect(
        t.contains('frames') || t.contains('surfaces animées'),
        isTrue,
      );
    });

    testWidgets('4. simple: name and id', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _oneAnimationReadModel(),
          ),
        ),
      );
      expect(find.text('Water Loop'), findsOneWidget);
      expect(
        find.textContaining('Identifiant : water-loop'),
        findsOneWidget,
      );
    });

    testWidgets('5. simple: 1 frame', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _oneAnimationReadModel(),
          ),
        ),
      );
      expect(find.textContaining('Frames : 1 frame'), findsOneWidget);
    });

    testWidgets('6. simple: total duration 120 ms', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _oneAnimationReadModel(),
          ),
        ),
      );
      expect(find.textContaining('Durée totale : 120 ms'), findsOneWidget);
    });

    testWidgets('7. simple: referenced atlas', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _oneAnimationReadModel(),
          ),
        ),
      );
      expect(find.text('Atlas référencés'), findsOneWidget);
      expect(find.text('water-atlas'), findsOneWidget);
    });

    testWidgets('8. two referenced atlases order', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _animationTwoAtlasesReadModel(),
          ),
        ),
      );
      expect(find.text('2 atlas référencés'), findsOneWidget);
      final t = _allText(tester);
      expect(t.indexOf('atlas-b'), lessThan(t.indexOf('atlas-a')));
    });

    testWidgets('9. no sync group', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _oneAnimationReadModel(),
          ),
        ),
      );
      expect(
        find.textContaining('Groupe de synchronisation : Aucun groupe'),
        findsOneWidget,
      );
    });

    testWidgets('10. sync group water', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _animationWithSyncAndCategoryReadModel(),
          ),
        ),
      );
      expect(
        find.textContaining('Groupe de synchronisation : water'),
        findsOneWidget,
      );
    });

    testWidgets('11. no category', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _oneAnimationReadModel(),
          ),
        ),
      );
      expect(
        find.textContaining('Catégorie : Aucune catégorie'),
        findsOneWidget,
      );
    });

    testWidgets('12. category', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _animationWithSyncAndCategoryReadModel(),
          ),
        ),
      );
      expect(
        find.textContaining('Catégorie : animated-surfaces'),
        findsOneWidget,
      );
    });

    testWidgets('13. sortOrder', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _oneAnimationReadModel(),
          ),
        ),
      );
      expect(find.textContaining('Ordre : 42'), findsOneWidget);
    });

    testWidgets('14. referenced atlas order preserved b,a,c', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _animationThreeAtlasesReadModel(),
          ),
        ),
      );
      final t = _allText(tester);
      expect(t.indexOf('atlas-b'), lessThan(t.indexOf('atlas-a')));
      expect(t.indexOf('atlas-a'), lessThan(t.indexOf('atlas-c')));
    });

    testWidgets('15. animation order preserved a,b,c', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _multipleAnimationsReadModel(),
          ),
        ),
      );
      final t = _allText(tester);
      expect(t.indexOf('water-a'), lessThan(t.indexOf('water-b')));
      expect(t.indexOf('water-b'), lessThan(t.indexOf('water-c')));
    });

    testWidgets('16. does not sort by sortOrder', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _animationSortOrderContradictionReadModel(),
          ),
        ),
      );
      final t = _allText(tester);
      expect(t.indexOf('first'), lessThan(t.indexOf('second')));
    });

    testWidgets('17. no TextField', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _oneAnimationReadModel(),
          ),
        ),
      );
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('18. no active edit save affordances', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _oneAnimationReadModel(),
          ),
        ),
      );
      for (final s in <String>[
        'Créer',
        'Modifier',
        'Supprimer',
        'Enregistrer',
        'Sauvegarder',
        'Save',
        'Delete',
        'Edit',
      ]) {
        expect(find.text(s), findsNothing);
      }
    });

    testWidgets('19. no internal type names in UI', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _oneAnimationReadModel(),
          ),
        ),
      );
      expect(find.textContaining('ProjectSurfaceAnimation'), findsNothing);
      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
      expect(
          find.textContaining('SurfaceStudioAnimationReadModel'), findsNothing);
      expect(find.textContaining('SurfaceAnimationTimeline'), findsNothing);
    });

    testWidgets('20. read model with diagnostics builds', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _readModelWithDiagnosticsAndAnimation(),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('loop'), findsOneWidget);
    });

    testWidgets('21. no ProviderScope', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SurfaceStudioAnimationDetailView(
            readModel: _emptyReadModel(),
          ),
        ),
      );
      expect(find.text('Animations Surface'), findsOneWidget);
    });

    testWidgets('22. accepts bounded width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: SurfaceStudioAnimationDetailView(
                  readModel: _oneAnimationReadModel(),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}

String _allText(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((e) => e.data ?? '')
      .join('\n');
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );
}

SurfaceAtlasGeometry _g2x2() => SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
      gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
      layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
    );

SurfaceStudioReadModel _emptyReadModel() =>
    buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());

SurfaceStudioReadModel _oneAnimationReadModel() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'water-atlas',
    name: 'Water Atlas',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
    durationMs: 120,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'water-loop',
    name: 'Water Loop',
    sortOrder: 42,
    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[f]),
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas],
      animations: <ProjectSurfaceAnimation>[anim],
    ),
  );
}

SurfaceStudioReadModel _animationWithSyncAndCategoryReadModel() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'a',
    name: 'A',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
    durationMs: 120,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'x',
    name: 'X',
    syncGroupId: 'water',
    categoryId: 'animated-surfaces',
    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[f]),
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas],
      animations: <ProjectSurfaceAnimation>[anim],
    ),
  );
}

SurfaceStudioReadModel _animationTwoAtlasesReadModel() {
  final ga = _g2x2();
  final gb = SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 16, height: 16),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
  final a = ProjectSurfaceAtlas(
      id: 'atlas-a', name: 'A', tilesetId: 't', geometry: ga);
  final b = ProjectSurfaceAtlas(
      id: 'atlas-b', name: 'B', tilesetId: 't', geometry: gb);
  final frames = <SurfaceAnimationFrame>[
    SurfaceAnimationFrame(
      tileRef: SurfaceAtlasTileRef(atlasId: 'atlas-b', column: 0, row: 0),
      durationMs: 10,
    ),
    SurfaceAnimationFrame(
      tileRef: SurfaceAtlasTileRef(atlasId: 'atlas-a', column: 0, row: 0),
      durationMs: 10,
    ),
  ];
  final anim = ProjectSurfaceAnimation(
    id: 'anim2',
    name: 'Anim2',
    timeline: SurfaceAnimationTimeline(frames: frames),
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[a, b],
      animations: <ProjectSurfaceAnimation>[anim],
    ),
  );
}

SurfaceStudioReadModel _animationThreeAtlasesReadModel() {
  final g = _g2x2();
  final ba = ProjectSurfaceAtlas(
    id: 'atlas-b',
    name: 'B',
    tilesetId: 't',
    geometry: g,
  );
  final aa = ProjectSurfaceAtlas(
    id: 'atlas-a',
    name: 'A2',
    tilesetId: 't',
    geometry: g,
  );
  final ca = ProjectSurfaceAtlas(
    id: 'atlas-c',
    name: 'C',
    tilesetId: 't',
    geometry: g,
  );
  final frames = <SurfaceAnimationFrame>[
    SurfaceAnimationFrame(
      tileRef: SurfaceAtlasTileRef(atlasId: 'atlas-b', column: 0, row: 0),
      durationMs: 1,
    ),
    SurfaceAnimationFrame(
      tileRef: SurfaceAtlasTileRef(atlasId: 'atlas-a', column: 0, row: 0),
      durationMs: 1,
    ),
    SurfaceAnimationFrame(
      tileRef: SurfaceAtlasTileRef(atlasId: 'atlas-c', column: 0, row: 0),
      durationMs: 1,
    ),
  ];
  final anim = ProjectSurfaceAnimation(
    id: 'tri',
    name: 'Tri',
    timeline: SurfaceAnimationTimeline(frames: frames),
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[ba, aa, ca],
      animations: <ProjectSurfaceAnimation>[anim],
    ),
  );
}

SurfaceStudioReadModel _multipleAnimationsReadModel() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'w',
    name: 'W',
    tilesetId: 't',
    geometry: g,
  );
  SurfaceAnimationFrame f() => SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(atlasId: 'w', column: 0, row: 0),
        durationMs: 1,
      );
  final a = ProjectSurfaceAnimation(
    id: 'water-a',
    name: 'water-a',
    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[f()]),
  );
  final b = ProjectSurfaceAnimation(
    id: 'water-b',
    name: 'water-b',
    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[f()]),
  );
  final c = ProjectSurfaceAnimation(
    id: 'water-c',
    name: 'water-c',
    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[f()]),
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas],
      animations: <ProjectSurfaceAnimation>[a, b, c],
    ),
  );
}

SurfaceStudioReadModel _animationSortOrderContradictionReadModel() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'w',
    name: 'W',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'w', column: 0, row: 0),
    durationMs: 1,
  );
  final first = ProjectSurfaceAnimation(
    id: 'f',
    name: 'first',
    sortOrder: 99,
    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[f]),
  );
  final second = ProjectSurfaceAnimation(
    id: 's',
    name: 'second',
    sortOrder: 1,
    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[f]),
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas],
      animations: <ProjectSurfaceAnimation>[first, second],
    ),
  );
}

SurfaceStudioReadModel _readModelWithDiagnosticsAndAnimation() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'w',
    name: 'W',
    tilesetId: 't',
    geometry: g,
  );
  final fr = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'w', column: 0, row: 0),
    durationMs: 10,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'loop',
    name: 'loop',
    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[fr]),
  );
  final bad = SurfaceVariantAnimationRefSet(
    refs: <SurfaceVariantAnimationRef>[
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'nope',
      ),
    ],
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas],
      animations: <ProjectSurfaceAnimation>[anim],
      presets: <ProjectSurfacePreset>[
        ProjectSurfacePreset(
          id: 'p',
          name: 'p',
          variantAnimations: bad,
        ),
      ],
    ),
  );
}
```

### A.4 `packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart`

```dart
// Tests widget — Surface Studio preset detail (Lot 57).
// API publique `map_core` uniquement (pas de `package:map_core/src/...`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_preset_detail_view.dart';

void main() {
  group('SurfaceStudioPresetDetailView (Lot 57)', () {
    testWidgets('23. title Presets Surface', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPresetDetailView(readModel: _emptyReadModel())),
      );
      expect(find.text('Presets Surface'), findsOneWidget);
    });

    testWidgets('24. empty: main message', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPresetDetailView(readModel: _emptyReadModel())),
      );
      expect(find.text('Aucun preset Surface'), findsOneWidget);
    });

    testWidgets('25. empty: explainer', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPresetDetailView(readModel: _emptyReadModel())),
      );
      final t = _allText(tester);
      expect(t.contains('rôles') || t.contains('animations'), isTrue);
    });

    testWidgets('26. simple: name and id', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(readModel: _onePresetReadModel()),
        ),
      );
      expect(find.text('Water Surface'), findsOneWidget);
      expect(
        find.textContaining('Identifiant : water-surface'),
        findsOneWidget,
      );
    });

    testWidgets('27. 1 variante', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(readModel: _onePresetReadModel()),
        ),
      );
      expect(find.textContaining('Variantes : 1 variante'), findsOneWidget);
    });

    testWidgets('28. isolated role humanized', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(readModel: _onePresetReadModel()),
        ),
      );
      expect(find.text('Isolé'), findsOneWidget);
    });

    testWidgets('29. multiple roles order', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _multipleRolesReadModel(),
          ),
        ),
      );
      final t = _allText(tester);
      expect(t.indexOf('Croix'), lessThan(t.indexOf('Isolé')));
      expect(t.indexOf('Isolé'), lessThan(t.indexOf('Horizontal')));
    });

    testWidgets('30. one linked animation', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(readModel: _onePresetReadModel()),
        ),
      );
      expect(find.text('Animations liées'), findsOneWidget);
      expect(find.text('1 animation liée'), findsOneWidget);
      expect(find.text('water-loop'), findsOneWidget);
    });

    testWidgets('31. two linked animations order', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _presetTwoAnimationsReadModel(),
          ),
        ),
      );
      expect(find.text('2 animations liées'), findsOneWidget);
      final t = _allText(tester);
      expect(t.indexOf('water-b'), lessThan(t.indexOf('water-a')));
    });

    testWidgets('32. covers standard false', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(readModel: _onePresetReadModel()),
        ),
      );
      expect(find.text('Rôles standards incomplets'), findsOneWidget);
    });

    testWidgets('33. covers standard true', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _presetCompleteRolesReadModel(),
          ),
        ),
      );
      expect(find.text('Rôles standards complets'), findsOneWidget);
    });

    testWidgets('34. no category', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(readModel: _onePresetReadModel()),
        ),
      );
      expect(
        find.textContaining('Catégorie : Aucune catégorie'),
        findsOneWidget,
      );
    });

    testWidgets('35. category', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _presetWithCategoryReadModel(),
          ),
        ),
      );
      expect(
        find.textContaining('Catégorie : animated-surfaces'),
        findsOneWidget,
      );
    });

    testWidgets('36. sortOrder', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _onePresetReadModel(),
          ),
        ),
      );
      expect(find.textContaining('Ordre : 42'), findsOneWidget);
    });

    testWidgets('37. preset order preserved', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _multiplePresetsReadModel(),
          ),
        ),
      );
      final t = _allText(tester);
      expect(t.indexOf('water-surface'), lessThan(t.indexOf('lava-surface')));
      expect(t.indexOf('lava-surface'), lessThan(t.indexOf('grass-surface')));
    });

    testWidgets('38. does not sort by sortOrder', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _presetSortOrderContradictionReadModel(),
          ),
        ),
      );
      final t = _allText(tester);
      expect(t.indexOf('first'), lessThan(t.indexOf('second')));
    });

    testWidgets('39. no TextField', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _onePresetReadModel(),
          ),
        ),
      );
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('40. no active edit save affordances', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _onePresetReadModel(),
          ),
        ),
      );
      for (final s in <String>[
        'Créer',
        'Modifier',
        'Supprimer',
        'Enregistrer',
        'Sauvegarder',
        'Save',
        'Delete',
        'Edit',
      ]) {
        expect(find.text(s), findsNothing);
      }
    });

    testWidgets('41. no internal type names in UI', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _onePresetReadModel(),
          ),
        ),
      );
      expect(find.textContaining('ProjectSurfacePreset'), findsNothing);
      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
      expect(find.textContaining('SurfaceStudioPresetReadModel'), findsNothing);
      expect(
          find.textContaining('SurfaceVariantAnimationRefSet'), findsNothing);
    });

    testWidgets('42. read model with diagnostics builds', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _readModelWithDiagnosticsAndPreset(),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Water Surface'), findsOneWidget);
    });

    testWidgets('43. no ProviderScope', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SurfaceStudioPresetDetailView(
            readModel: _emptyReadModel(),
          ),
        ),
      );
      expect(find.text('Presets Surface'), findsOneWidget);
    });

    testWidgets('44. accepts bounded width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: SurfaceStudioPresetDetailView(
                  readModel: _onePresetReadModel(),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}

String _allText(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((e) => e.data ?? '')
      .join('\n');
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );
}

SurfaceAtlasGeometry _g2x2() => SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
      gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
      layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
    );

SurfaceStudioReadModel _emptyReadModel() =>
    buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());

SurfaceAnimationFrame _oneFrame() => SurfaceAnimationFrame(
      tileRef: SurfaceAtlasTileRef(atlasId: 'w', column: 0, row: 0),
      durationMs: 10,
    );

SurfaceStudioReadModel _onePresetReadModel() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'w',
    name: 'W',
    tilesetId: 't',
    geometry: g,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'water-loop',
    name: 'L',
    timeline:
        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: <SurfaceVariantAnimationRef>[
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'water-loop',
      ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'water-surface',
    name: 'Water Surface',
    sortOrder: 42,
    variantAnimations: refs,
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas],
      animations: <ProjectSurfaceAnimation>[anim],
      presets: <ProjectSurfacePreset>[preset],
    ),
  );
}

SurfaceStudioReadModel _multipleRolesReadModel() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'w',
    name: 'W',
    tilesetId: 't',
    geometry: g,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'a1',
    name: 'A1',
    timeline:
        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
  );
  final anim2 = ProjectSurfaceAnimation(
    id: 'a2',
    name: 'A2',
    timeline:
        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
  );
  final anim3 = ProjectSurfaceAnimation(
    id: 'a3',
    name: 'A3',
    timeline:
        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: <SurfaceVariantAnimationRef>[
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.cross,
        animationId: 'a1',
      ),
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'a2',
      ),
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.horizontal,
        animationId: 'a3',
      ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'm',
    name: 'M',
    variantAnimations: refs,
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas],
      animations: <ProjectSurfaceAnimation>[anim, anim2, anim3],
      presets: <ProjectSurfacePreset>[preset],
    ),
  );
}

SurfaceStudioReadModel _presetTwoAnimationsReadModel() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'w',
    name: 'W',
    tilesetId: 't',
    geometry: g,
  );
  final fa = ProjectSurfaceAnimation(
    id: 'water-a',
    name: 'WA',
    timeline:
        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
  );
  final fb = ProjectSurfaceAnimation(
    id: 'water-b',
    name: 'WB',
    timeline:
        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: <SurfaceVariantAnimationRef>[
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'water-b',
      ),
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.horizontal,
        animationId: 'water-a',
      ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'p2',
    name: 'P2',
    variantAnimations: refs,
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas],
      animations: <ProjectSurfaceAnimation>[fa, fb],
      presets: <ProjectSurfacePreset>[preset],
    ),
  );
}

SurfaceStudioReadModel _presetWithCategoryReadModel() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'w',
    name: 'W',
    tilesetId: 't',
    geometry: g,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'water-loop',
    name: 'L',
    timeline:
        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: <SurfaceVariantAnimationRef>[
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'water-loop',
      ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'water-surface',
    name: 'Water Surface',
    categoryId: 'animated-surfaces',
    variantAnimations: refs,
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas],
      animations: <ProjectSurfaceAnimation>[anim],
      presets: <ProjectSurfacePreset>[preset],
    ),
  );
}

SurfaceStudioReadModel _presetCompleteRolesReadModel() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'w',
    name: 'W',
    tilesetId: 't',
    geometry: g,
  );
  const loopId = 'std-loop';
  final anim = ProjectSurfaceAnimation(
    id: loopId,
    name: 'Std',
    timeline:
        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: <SurfaceVariantAnimationRef>[
      for (final role in standardSurfaceVariantRoleOrder)
        SurfaceVariantAnimationRef(
          role: role,
          animationId: loopId,
        ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'full',
    name: 'Full',
    variantAnimations: refs,
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas],
      animations: <ProjectSurfaceAnimation>[anim],
      presets: <ProjectSurfacePreset>[preset],
    ),
  );
}

SurfaceStudioReadModel _multiplePresetsReadModel() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'w',
    name: 'W',
    tilesetId: 't',
    geometry: g,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'loop',
    name: 'L',
    timeline:
        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
  );
  ProjectSurfacePreset mk(String id, String name) {
    return ProjectSurfacePreset(
      id: id,
      name: name,
      variantAnimations: SurfaceVariantAnimationRefSet(
        refs: <SurfaceVariantAnimationRef>[
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.isolated,
            animationId: 'loop',
          ),
        ],
      ),
    );
  }

  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas],
      animations: <ProjectSurfaceAnimation>[anim],
      presets: <ProjectSurfacePreset>[
        mk('water-surface', 'WS'),
        mk('lava-surface', 'LS'),
        mk('grass-surface', 'GS'),
      ],
    ),
  );
}

SurfaceStudioReadModel _presetSortOrderContradictionReadModel() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'w',
    name: 'W',
    tilesetId: 't',
    geometry: g,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'loop',
    name: 'L',
    timeline:
        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
  );
  ProjectSurfacePreset p(String id, String name, int so) {
    return ProjectSurfacePreset(
      id: id,
      name: name,
      sortOrder: so,
      variantAnimations: SurfaceVariantAnimationRefSet(
        refs: <SurfaceVariantAnimationRef>[
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.isolated,
            animationId: 'loop',
          ),
        ],
      ),
    );
  }

  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas],
      animations: <ProjectSurfaceAnimation>[anim],
      presets: <ProjectSurfacePreset>[
        p('a', 'first', 99),
        p('b', 'second', 1),
      ],
    ),
  );
}

SurfaceStudioReadModel _readModelWithDiagnosticsAndPreset() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'w',
    name: 'W',
    tilesetId: 't',
    geometry: g,
  );
  final unusedAtlas = ProjectSurfaceAtlas(
    id: 'orphan-atlas',
    name: 'Orphan',
    tilesetId: 't',
    geometry: g,
  );
  final okAnim = ProjectSurfaceAnimation(
    id: 'ok',
    name: 'ok',
    timeline:
        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: <SurfaceVariantAnimationRef>[
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'ok',
      ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'p',
    name: 'Water Surface',
    variantAnimations: refs,
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas, unusedAtlas],
      animations: <ProjectSurfaceAnimation>[okAnim],
      presets: <ProjectSurfacePreset>[preset],
    ),
  );
}
```

---

## B. Fichiers modifiés

### B.1 Contenu intégral `surface_studio_catalog_browser.dart` (post–Lot 57)

```dart
// Surface Studio — navigateur de catalogue lecture seule (Lot 54).
//
// Consomme uniquement [SurfaceStudioReadModel] (Lot 51) : pas de
// re-calcul de diagnostics, pas de JSON, pas de fichier, pas de mutation
// de manifest, pas d’I/O, pas d’état mutable.

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_animation_detail_view.dart';
import 'surface_studio_atlas_detail_view.dart';
import 'surface_studio_preset_detail_view.dart';

/// Libellés visibles (aucun nom de type Dart interne).
class SurfaceStudioCatalogBrowserLabels {
  const SurfaceStudioCatalogBrowserLabels._();

  static const String title = 'Catalogue Surface';
  static const String emptyGlobal = 'Le catalogue Surface est vide';
  static const String emptyGlobalHint =
      'Les prochains lots permettront d’ajouter des atlas, des animations et des presets.';
  static const String sectionAtlas = 'Atlas';
  static const String sectionAnimations = 'Animations';
  static const String sectionPresets = 'Presets';
  static const String emptyAtlas = 'Aucun atlas Surface';
  static const String emptyAnimations = 'Aucune animation Surface';
  static const String emptyPresets = 'Aucun preset Surface';

  static const String labelId = 'Identifiant';
  static const String labelTileset = 'Tileset';
  static const String labelTile = 'Tile';
  static const String labelGrid = 'Grille';
  static const String labelLayout = 'Layout';
  static const String labelUsedBy = 'Utilisé par';

  static const String labelFrames = 'Frames';
  static const String labelTotalDuration = 'Durée totale';
  static const String labelRefAtlases = 'Atlas référencés';
  static const String labelSync = 'Groupe de synchronisation';
  static const String labelCategory = 'Catégorie';

  static const String labelVariants = 'Variantes';
  static const String labelRoles = 'Rôles';
  static const String labelPresetAnimationRefs = 'Animations liées';
  static const String labelCoverage = 'Couverture standard';
  static const String coverageFull = 'Rôles standards complets';
  static const String coveragePartial = 'Rôles standards incomplets';

  static const String notUsed = 'Non utilisé';

  static String usedByAnimations(int n) {
    if (n <= 0) {
      return notUsed;
    }
    if (n == 1) {
      return 'Utilisé par 1 animation';
    }
    return 'Utilisé par $n animations';
  }

  static String frameLabel(int n) {
    if (n <= 1) {
      return '1 frame';
    }
    return '$n frames';
  }

  static String variantLabel(int n) {
    if (n <= 1) {
      return '1 variante';
    }
    return '$n variantes';
  }
}

/// Navigateur de catalogue **lecture seule** : seules les listes et champs
/// dérivés du [SurfaceStudioReadModel] sont affichés (ordre source).
class SurfaceStudioCatalogBrowser extends StatelessWidget {
  const SurfaceStudioCatalogBrowser({
    super.key,
    required this.readModel,
  });

  final SurfaceStudioReadModel readModel;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          SurfaceStudioCatalogBrowserLabels.title,
          style: TextStyle(
            color: label,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        if (readModel.isEmpty) ...[
          Text(
            SurfaceStudioCatalogBrowserLabels.emptyGlobal,
            style: TextStyle(
              color: label,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            SurfaceStudioCatalogBrowserLabels.emptyGlobalHint,
            style: TextStyle(
              color: subtle,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
        ],
        SurfaceStudioAtlasDetailView(readModel: readModel),
        const SizedBox(height: 18),
        SurfaceStudioAnimationDetailView(readModel: readModel),
        const SizedBox(height: 18),
        SurfaceStudioPresetDetailView(readModel: readModel),
      ],
    );
  }
}
```

---

## C. Diffs complets (git read-only)

### C.1 `git diff` — surface_studio_catalog_browser.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart
index 627f253e..7520c398 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart
@@ -8,7 +8,9 @@ import 'package:flutter/cupertino.dart';
 import 'package:map_core/map_core.dart';
 
 import '../../ui/shared/cupertino_editor_widgets.dart';
+import 'surface_studio_animation_detail_view.dart';
 import 'surface_studio_atlas_detail_view.dart';
+import 'surface_studio_preset_detail_view.dart';
 
 /// Libellés visibles (aucun nom de type Dart interne).
 class SurfaceStudioCatalogBrowserLabels {
@@ -122,258 +124,10 @@ class SurfaceStudioCatalogBrowser extends StatelessWidget {
         ],
         SurfaceStudioAtlasDetailView(readModel: readModel),
         const SizedBox(height: 18),
-        _SectionHeader(
-          title: SurfaceStudioCatalogBrowserLabels.sectionAnimations,
-          subtle: subtle,
-        ),
-        const SizedBox(height: 8),
-        if (readModel.animations.isEmpty)
-          _EmptyLine(
-            text: SurfaceStudioCatalogBrowserLabels.emptyAnimations,
-            subtle: subtle,
-          )
-        else
-          ...readModel.animations.map(
-            (row) => Padding(
-              padding: const EdgeInsets.only(bottom: 10),
-              child: _AnimationCard(row: row, label: label),
-            ),
-          ),
+        SurfaceStudioAnimationDetailView(readModel: readModel),
         const SizedBox(height: 18),
-        _SectionHeader(
-          title: SurfaceStudioCatalogBrowserLabels.sectionPresets,
-          subtle: subtle,
-        ),
-        const SizedBox(height: 8),
-        if (readModel.presets.isEmpty)
-          _EmptyLine(
-            text: SurfaceStudioCatalogBrowserLabels.emptyPresets,
-            subtle: subtle,
-          )
-        else
-          ...readModel.presets.map(
-            (row) => Padding(
-              padding: const EdgeInsets.only(bottom: 10),
-              child: _PresetCard(row: row, label: label),
-            ),
-          ),
+        SurfaceStudioPresetDetailView(readModel: readModel),
       ],
     );
   }
 }
-
-class _SectionHeader extends StatelessWidget {
-  const _SectionHeader({required this.title, required this.subtle});
-
-  final String title;
-  final Color subtle;
-
-  @override
-  Widget build(BuildContext context) {
-    return Text(
-      title,
-      style: TextStyle(
-        color: subtle,
-        fontSize: 11,
-        fontWeight: FontWeight.w800,
-        letterSpacing: 0.6,
-      ),
-    );
-  }
-}
-
-class _EmptyLine extends StatelessWidget {
-  const _EmptyLine({
-    required this.text,
-    required this.subtle,
-  });
-
-  final String text;
-  final Color subtle;
-
-  @override
-  Widget build(BuildContext context) {
-    return Text(
-      text,
-      style: TextStyle(
-        color: subtle,
-        fontSize: 13,
-        fontWeight: FontWeight.w500,
-        fontStyle: FontStyle.italic,
-      ),
-    );
-  }
-}
-
-class _BrowserCard extends StatelessWidget {
-  const _BrowserCard({required this.child});
-
-  final Widget child;
-
-  @override
-  Widget build(BuildContext context) {
-    return Container(
-      padding: const EdgeInsets.all(14),
-      decoration: BoxDecoration(
-        color: EditorChrome.elevatedPanelBackground(context),
-        borderRadius: BorderRadius.circular(14),
-        border: Border.all(
-          color: EditorChrome.editorIslandRim(context),
-          width: 1,
-        ),
-        boxShadow: EditorChrome.sectionCardShadows(context),
-      ),
-      child: child,
-    );
-  }
-}
-
-class _KeyVal extends StatelessWidget {
-  const _KeyVal({
-    required this.k,
-    required this.v,
-    required this.valueColor,
-  });
-
-  final String k;
-  final String v;
-  final Color valueColor;
-
-  @override
-  Widget build(BuildContext context) {
-    return Padding(
-      padding: const EdgeInsets.only(top: 4),
-      child: Text(
-        '$k : $v',
-        style: TextStyle(
-          color: valueColor,
-          fontSize: 13,
-          fontWeight: FontWeight.w500,
-          height: 1.3,
-        ),
-      ),
-    );
-  }
-}
-
-class _AnimationCard extends StatelessWidget {
-  const _AnimationCard({
-    required this.row,
-    required this.label,
-  });
-
-  final SurfaceStudioAnimationReadModel row;
-  final Color label;
-
-  @override
-  Widget build(BuildContext context) {
-    final refLine = row.referencedAtlasIds.join(' ');
-    return _BrowserCard(
-      child: Column(
-        crossAxisAlignment: CrossAxisAlignment.start,
-        children: [
-          Text(
-            row.name,
-            style: TextStyle(
-              color: label,
-              fontSize: 15,
-              fontWeight: FontWeight.w800,
-            ),
-          ),
-          _KeyVal(
-            k: SurfaceStudioCatalogBrowserLabels.labelId,
-            v: row.id,
-            valueColor: label,
-          ),
-          _KeyVal(
-            k: SurfaceStudioCatalogBrowserLabels.labelFrames,
-            v: SurfaceStudioCatalogBrowserLabels.frameLabel(row.frameCount),
-            valueColor: label,
-          ),
-          _KeyVal(
-            k: SurfaceStudioCatalogBrowserLabels.labelTotalDuration,
-            v: '${row.totalDurationMs} ms',
-            valueColor: label,
-          ),
-          if (row.syncGroupId != null)
-            _KeyVal(
-              k: SurfaceStudioCatalogBrowserLabels.labelSync,
-              v: row.syncGroupId!,
-              valueColor: label,
-            ),
-          if (row.categoryId != null)
-            _KeyVal(
-              k: SurfaceStudioCatalogBrowserLabels.labelCategory,
-              v: row.categoryId!,
-              valueColor: label,
-            ),
-          _KeyVal(
-            k: SurfaceStudioCatalogBrowserLabels.labelRefAtlases,
-            v: refLine.isEmpty ? '—' : refLine,
-            valueColor: label,
-          ),
-        ],
-      ),
-    );
-  }
-}
-
-String _roleLabel(SurfaceVariantRole r) => r.name;
-
-class _PresetCard extends StatelessWidget {
-  const _PresetCard({
-    required this.row,
-    required this.label,
-  });
-
-  final SurfaceStudioPresetReadModel row;
-  final Color label;
-
-  @override
-  Widget build(BuildContext context) {
-    final roleLine = row.roles.map(_roleLabel).join(' ');
-    final animLine = row.referencedAnimationIds.join(' ');
-    return _BrowserCard(
-      child: Column(
-        crossAxisAlignment: CrossAxisAlignment.start,
-        children: [
-          Text(
-            row.name,
-            style: TextStyle(
-              color: label,
-              fontSize: 15,
-              fontWeight: FontWeight.w800,
-            ),
-          ),
-          _KeyVal(
-            k: SurfaceStudioCatalogBrowserLabels.labelId,
-            v: row.id,
-            valueColor: label,
-          ),
-          _KeyVal(
-            k: SurfaceStudioCatalogBrowserLabels.labelVariants,
-            v: SurfaceStudioCatalogBrowserLabels.variantLabel(row.variantCount),
-            valueColor: label,
-          ),
-          _KeyVal(
-            k: SurfaceStudioCatalogBrowserLabels.labelRoles,
-            v: roleLine,
-            valueColor: label,
-          ),
-          _KeyVal(
-            k: SurfaceStudioCatalogBrowserLabels.labelPresetAnimationRefs,
-            v: animLine.isEmpty ? '—' : animLine,
-            valueColor: label,
-          ),
-          _KeyVal(
-            k: SurfaceStudioCatalogBrowserLabels.labelCoverage,
-            v: row.coversStandardRoles
-                ? SurfaceStudioCatalogBrowserLabels.coverageFull
-                : SurfaceStudioCatalogBrowserLabels.coveragePartial,
-            valueColor: label,
-          ),
-        ],
-      ),
-    );
-  }
-}
```

### C.2 `git diff` — test/surface_studio/

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart b/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart
index f9a8f2e9..032c54d4 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart
@@ -36,8 +36,8 @@ void main() {
         _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
       );
       expect(find.text('Atlas Surface'), findsOneWidget);
-      expect(find.text('Animations'), findsOneWidget);
-      expect(find.text('Presets'), findsOneWidget);
+      expect(find.text('Animations Surface'), findsOneWidget);
+      expect(find.text('Presets Surface'), findsOneWidget);
     });
 
     testWidgets('5. minimal catalog: atlas details (736-tile grid)', (
@@ -74,8 +74,8 @@ void main() {
         find.textContaining('Identifiant : water-isolated-loop'),
         findsOneWidget,
       );
-      expect(find.textContaining('1 frame'), findsOneWidget);
-      expect(find.textContaining('120 ms'), findsOneWidget);
+      expect(find.textContaining('Frames : 1 frame'), findsOneWidget);
+      expect(find.textContaining('Durée totale : 120 ms'), findsOneWidget);
       expect(find.textContaining('water-atlas'), findsWidgets);
     });
 
@@ -89,15 +89,12 @@ void main() {
         findsOneWidget,
       );
       expect(find.textContaining('Variantes : 1 variante'), findsOneWidget);
-      expect(find.textContaining('Rôles : isolated'), findsOneWidget);
-      expect(
-        find.textContaining('Animations liées : water-isolated-loop'),
-        findsOneWidget,
-      );
-      expect(
-        find.textContaining('Couverture standard : Rôles standards incomplets'),
-        findsOneWidget,
-      );
+      expect(find.text('Isolé'), findsOneWidget);
+      expect(find.text('Animations liées'), findsOneWidget);
+      expect(find.text('1 animation liée'), findsOneWidget);
+      // Id visible dans la fiche atlas (utilisé par …) et dans le preset.
+      expect(find.text('water-isolated-loop'), findsNWidgets(2));
+      expect(find.text('Rôles standards incomplets'), findsOneWidget);
     });
 
     testWidgets('8. full animation: sync group and category', (tester) async {
@@ -153,7 +150,12 @@ void main() {
           ),
         ),
       );
-      expect(find.textContaining('atlas-b atlas-a'), findsOneWidget);
+      // Ordre visible dans la fiche animation (pas le blob texte global : les ids
+      // apparaissent aussi dans les fiches atlas).
+      expect(
+        tester.getTopLeft(find.text('atlas-b')).dy,
+        lessThan(tester.getTopLeft(find.text('atlas-a')).dy),
+      );
     });
 
     testWidgets('12. preset referenced animation ids deduped order', (
@@ -168,7 +170,10 @@ void main() {
           ),
         ),
       );
-      expect(find.textContaining('anim-b anim-a'), findsOneWidget);
+      expect(
+        tester.getTopLeft(find.text('anim-b').first).dy,
+        lessThan(tester.getTopLeft(find.text('anim-a').first).dy),
+      );
     });
 
     testWidgets('13. preset roles source order', (tester) async {
@@ -182,8 +187,12 @@ void main() {
         ),
       );
       expect(
-        find.textContaining('Rôles : cross isolated horizontal'),
-        findsOneWidget,
+        tester.getTopLeft(find.text('Croix')).dy,
+        lessThan(tester.getTopLeft(find.text('Isolé')).dy),
+      );
+      expect(
+        tester.getTopLeft(find.text('Isolé')).dy,
+        lessThan(tester.getTopLeft(find.text('Horizontal')).dy),
       );
     });
 
@@ -355,6 +364,35 @@ void main() {
       );
       expect(find.text('Catalogue Surface'), findsOneWidget);
     });
+
+    testWidgets('45. Lot 57 — browser integrates Animation Detail', (
+      tester,
+    ) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.text('Animations Surface'), findsOneWidget);
+      expect(find.text('Water Isolated Loop'), findsOneWidget);
+      expect(find.textContaining('Durée totale'), findsOneWidget);
+    });
+
+    testWidgets('46. Lot 57 — browser integrates Preset Detail',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.text('Presets Surface'), findsOneWidget);
+      expect(find.text('Water Surface'), findsOneWidget);
+      expect(find.text('Rôles standards incomplets'), findsOneWidget);
+    });
+
+    testWidgets('47. Lot 57 — browser keeps Atlas Detail', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.text('Atlas Surface'), findsOneWidget);
+      expect(find.text('Water Atlas'), findsOneWidget);
+    });
   });
 }
 
diff --git a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
index c69f3701..b7249e85 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
@@ -230,6 +230,9 @@ void main() {
         _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
       );
       expect(find.text('Catalogue Surface'), findsOneWidget);
+      expect(find.text('Atlas Surface'), findsOneWidget);
+      expect(find.text('Animations Surface'), findsOneWidget);
+      expect(find.text('Presets Surface'), findsOneWidget);
       expect(find.text('Water Atlas'), findsOneWidget);
       expect(find.text('Water Isolated Loop'), findsOneWidget);
       expect(find.text('Water Surface'), findsOneWidget);
@@ -268,10 +271,24 @@ void main() {
       );
       expect(find.text('Catalogue Surface'), findsOneWidget);
       expect(find.text('Atlas Surface'), findsOneWidget);
+      expect(find.text('Animations Surface'), findsOneWidget);
+      expect(find.text('Presets Surface'), findsOneWidget);
       expect(find.text('Diagnostics Surface'), findsOneWidget);
       expect(find.text('Water Atlas'), findsOneWidget);
     });
 
+    testWidgets(
+        '48. Lot 57 — panel shows Atlas / Animations / Presets / Diagnostics',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.text('Atlas Surface'), findsOneWidget);
+      expect(find.text('Animations Surface'), findsOneWidget);
+      expect(find.text('Presets Surface'), findsOneWidget);
+      expect(find.text('Diagnostics Surface'), findsOneWidget);
+    });
+
     testWidgets('30. Lot 55 — surfaceCatalog unchanged after panel pump',
         (tester) async {
       final cat = _minimalWaterCatalog();
diff --git a/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart b/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
index 58110bdb..29e7f9c8 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
@@ -104,7 +104,11 @@ void main() {
       expect(find.byType(SurfaceStudioPanel), findsOneWidget);
       expect(find.text('Catalogue Surface'), findsOneWidget);
       expect(find.text('Atlas Surface'), findsOneWidget);
+      expect(find.text('Animations Surface'), findsOneWidget);
+      expect(find.text('Presets Surface'), findsOneWidget);
       expect(find.text('Water Atlas'), findsOneWidget);
+      expect(find.text('Water Isolated Loop'), findsOneWidget);
+      expect(find.text('Water Surface'), findsOneWidget);
       expect(find.text('Diagnostics Surface'), findsOneWidget);
     });
 
```

### C.3 Diffs `/dev/null` (fichiers nouveaux) — équivalent `git add -N` + `git diff`

#### packages/map_editor/lib/src/features/surface_studio/surface_studio_animation_detail_view.dart

```diff
diff --git a/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/surface_studio/surface_studio_animation_detail_view.dart b/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/surface_studio/surface_studio_animation_detail_view.dart
new file mode 100644
index 00000000..88a0f27a
--- /dev/null
+++ b/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/surface_studio/surface_studio_animation_detail_view.dart
@@ -0,0 +1,267 @@
+// Surface Studio — détail des animations (Lot 57).
+//
+// Lecture seule : affiche uniquement [SurfaceStudioReadModel.animations] et les
+// champs dérivés de [SurfaceStudioAnimationReadModel] (Lot 51). Aucun catalogue
+// brut, aucun re-calcul des atlas référencés, aucun JSON, aucun I/O, aucune
+// mutation de manifest.
+
+import 'package:flutter/cupertino.dart';
+import 'package:map_core/map_core.dart';
+
+import '../../ui/shared/cupertino_editor_widgets.dart';
+
+/// Textes visibles (aucun nom de type interne dans l’UI).
+class SurfaceStudioAnimationDetailViewLabels {
+  const SurfaceStudioAnimationDetailViewLabels._();
+
+  static const String title = 'Animations Surface';
+  static const String emptyTitle = 'Aucune animation Surface';
+  static const String emptyHint =
+      'Les animations décrivent les frames utilisées par les surfaces animées.';
+
+  static const String labelIdentifiant = 'Identifiant';
+  static const String labelFrames = 'Frames';
+  static const String labelDureeTotale = 'Durée totale';
+  static const String labelAtlasRef = 'Atlas référencés';
+  static const String labelSync = 'Groupe de synchronisation';
+  static const String labelCategorie = 'Catégorie';
+  static const String labelOrdre = 'Ordre';
+
+  static const String syncAucun = 'Aucun groupe';
+  static const String categorieAucune = 'Aucune catégorie';
+  static const String aucunAtlas = 'Aucun atlas référencé';
+
+  static String framesLigne(int n) {
+    if (n <= 1) {
+      return '1 frame';
+    }
+    return '$n frames';
+  }
+
+  static String atlasRefSummary(int n) {
+    if (n <= 0) {
+      return aucunAtlas;
+    }
+    if (n == 1) {
+      return '1 atlas référencé';
+    }
+    return '$n atlas référencés';
+  }
+}
+
+/// Fiches animations **lecture seule** : ordre = [SurfaceStudioReadModel.animations].
+class SurfaceStudioAnimationDetailView extends StatelessWidget {
+  const SurfaceStudioAnimationDetailView({
+    super.key,
+    required this.readModel,
+  });
+
+  final SurfaceStudioReadModel readModel;
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        Text(
+          SurfaceStudioAnimationDetailViewLabels.title,
+          style: TextStyle(
+            color: label,
+            fontSize: 16,
+            fontWeight: FontWeight.w800,
+            letterSpacing: -0.2,
+          ),
+        ),
+        const SizedBox(height: 10),
+        if (readModel.animations.isEmpty) ...[
+          Text(
+            SurfaceStudioAnimationDetailViewLabels.emptyTitle,
+            style: TextStyle(
+              color: subtle,
+              fontSize: 14,
+              fontWeight: FontWeight.w600,
+              fontStyle: FontStyle.italic,
+            ),
+          ),
+          const SizedBox(height: 6),
+          Text(
+            SurfaceStudioAnimationDetailViewLabels.emptyHint,
+            style: TextStyle(
+              color: subtle,
+              fontSize: 12,
+              fontWeight: FontWeight.w500,
+              height: 1.35,
+            ),
+          ),
+        ] else
+          ...readModel.animations.map(
+            (row) => Padding(
+              padding: const EdgeInsets.only(bottom: 10),
+              child: _AnimationFiche(
+                row: row,
+                label: label,
+                subtle: subtle,
+              ),
+            ),
+          ),
+      ],
+    );
+  }
+}
+
+class _DetailCard extends StatelessWidget {
+  const _DetailCard({required this.child});
+
+  final Widget child;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      padding: const EdgeInsets.all(14),
+      decoration: BoxDecoration(
+        color: EditorChrome.elevatedPanelBackground(context),
+        borderRadius: BorderRadius.circular(14),
+        border: Border.all(
+          color: EditorChrome.editorIslandRim(context),
+          width: 1,
+        ),
+        boxShadow: EditorChrome.sectionCardShadows(context),
+      ),
+      child: child,
+    );
+  }
+}
+
+class _KeyVal extends StatelessWidget {
+  const _KeyVal({
+    required this.k,
+    required this.v,
+    required this.valueColor,
+  });
+
+  final String k;
+  final String v;
+  final Color valueColor;
+
+  @override
+  Widget build(BuildContext context) {
+    return Padding(
+      padding: const EdgeInsets.only(top: 4),
+      child: Text(
+        '$k : $v',
+        style: TextStyle(
+          color: valueColor,
+          fontSize: 13,
+          fontWeight: FontWeight.w500,
+          height: 1.3,
+        ),
+      ),
+    );
+  }
+}
+
+class _AnimationFiche extends StatelessWidget {
+  const _AnimationFiche({
+    required this.row,
+    required this.label,
+    required this.subtle,
+  });
+
+  final SurfaceStudioAnimationReadModel row;
+  final Color label;
+  final Color subtle;
+
+  @override
+  Widget build(BuildContext context) {
+    final refIds = row.referencedAtlasIds;
+    final nAtlas = refIds.length;
+    return _DetailCard(
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          Text(
+            row.name,
+            style: TextStyle(
+              color: label,
+              fontSize: 15,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          _KeyVal(
+            k: SurfaceStudioAnimationDetailViewLabels.labelIdentifiant,
+            v: row.id,
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: SurfaceStudioAnimationDetailViewLabels.labelFrames,
+            v: SurfaceStudioAnimationDetailViewLabels.framesLigne(
+              row.frameCount,
+            ),
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: SurfaceStudioAnimationDetailViewLabels.labelDureeTotale,
+            v: '${row.totalDurationMs} ms',
+            valueColor: label,
+          ),
+          const SizedBox(height: 4),
+          Text(
+            SurfaceStudioAnimationDetailViewLabels.labelAtlasRef,
+            style: TextStyle(
+              color: subtle,
+              fontSize: 11,
+              fontWeight: FontWeight.w800,
+              letterSpacing: 0.4,
+            ),
+          ),
+          Padding(
+            padding: const EdgeInsets.only(top: 2),
+            child: Text(
+              SurfaceStudioAnimationDetailViewLabels.atlasRefSummary(nAtlas),
+              style: TextStyle(
+                color: label,
+                fontSize: 13,
+                fontWeight: FontWeight.w600,
+              ),
+            ),
+          ),
+          if (nAtlas > 0)
+            ...refIds.map(
+              (id) => Padding(
+                padding: const EdgeInsets.only(top: 2),
+                child: Text(
+                  id,
+                  style: TextStyle(
+                    color: label,
+                    fontSize: 13,
+                    fontWeight: FontWeight.w600,
+                  ),
+                ),
+              ),
+            ),
+          _KeyVal(
+            k: SurfaceStudioAnimationDetailViewLabels.labelSync,
+            v: row.syncGroupId == null || row.syncGroupId!.isEmpty
+                ? SurfaceStudioAnimationDetailViewLabels.syncAucun
+                : row.syncGroupId!,
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: SurfaceStudioAnimationDetailViewLabels.labelCategorie,
+            v: row.categoryId == null || row.categoryId!.isEmpty
+                ? SurfaceStudioAnimationDetailViewLabels.categorieAucune
+                : row.categoryId!,
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: SurfaceStudioAnimationDetailViewLabels.labelOrdre,
+            v: row.sortOrder.toString(),
+            valueColor: label,
+          ),
+        ],
+      ),
+    );
+  }
+}
```

#### packages/map_editor/lib/src/features/surface_studio/surface_studio_preset_detail_view.dart

```diff
diff --git a/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/surface_studio/surface_studio_preset_detail_view.dart b/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/surface_studio/surface_studio_preset_detail_view.dart
new file mode 100644
index 00000000..be999f3c
--- /dev/null
+++ b/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/surface_studio/surface_studio_preset_detail_view.dart
@@ -0,0 +1,351 @@
+// Surface Studio — détail des presets (Lot 57).
+//
+// Lecture seule : affiche uniquement [SurfaceStudioReadModel.presets] et les
+// champs dérivés de [SurfaceStudioPresetReadModel] (Lot 51). Aucun catalogue
+// brut, aucun re-calcul des animations liées ni des rôles, aucun JSON, aucun I/O,
+// aucune mutation de manifest.
+
+import 'package:flutter/cupertino.dart';
+import 'package:map_core/map_core.dart';
+
+import '../../ui/shared/cupertino_editor_widgets.dart';
+
+/// Libellé français pour [SurfaceVariantRole] (affichage auteur, pas le nom d’énum brut).
+String surfaceStudioSurfaceVariantRoleLabel(SurfaceVariantRole role) {
+  switch (role) {
+    case SurfaceVariantRole.isolated:
+      return 'Isolé';
+    case SurfaceVariantRole.endNorth:
+      return 'Fin nord';
+    case SurfaceVariantRole.endEast:
+      return 'Fin est';
+    case SurfaceVariantRole.endSouth:
+      return 'Fin sud';
+    case SurfaceVariantRole.endWest:
+      return 'Fin ouest';
+    case SurfaceVariantRole.horizontal:
+      return 'Horizontal';
+    case SurfaceVariantRole.vertical:
+      return 'Vertical';
+    case SurfaceVariantRole.cornerNE:
+      return 'Coin nord-est';
+    case SurfaceVariantRole.cornerSE:
+      return 'Coin sud-est';
+    case SurfaceVariantRole.cornerSW:
+      return 'Coin sud-ouest';
+    case SurfaceVariantRole.cornerNW:
+      return 'Coin nord-ouest';
+    case SurfaceVariantRole.innerCornerNE:
+      return 'Coin intérieur nord-est';
+    case SurfaceVariantRole.innerCornerSE:
+      return 'Coin intérieur sud-est';
+    case SurfaceVariantRole.innerCornerSW:
+      return 'Coin intérieur sud-ouest';
+    case SurfaceVariantRole.innerCornerNW:
+      return 'Coin intérieur nord-ouest';
+    case SurfaceVariantRole.teeNorth:
+      return 'T nord';
+    case SurfaceVariantRole.teeEast:
+      return 'T est';
+    case SurfaceVariantRole.teeSouth:
+      return 'T sud';
+    case SurfaceVariantRole.teeWest:
+      return 'T ouest';
+    case SurfaceVariantRole.cross:
+      return 'Croix';
+  }
+}
+
+/// Textes visibles (aucun nom de type interne dans l’UI).
+class SurfaceStudioPresetDetailViewLabels {
+  const SurfaceStudioPresetDetailViewLabels._();
+
+  static const String title = 'Presets Surface';
+  static const String emptyTitle = 'Aucun preset Surface';
+  static const String emptyHint =
+      'Les presets associent des rôles de surface à des animations.';
+
+  static const String labelIdentifiant = 'Identifiant';
+  static const String labelVariantes = 'Variantes';
+  static const String labelRoles = 'Rôles';
+  static const String labelAnimationsLiees = 'Animations liées';
+  static const String labelCouverture = 'Couverture standard';
+  static const String labelCategorie = 'Catégorie';
+  static const String labelOrdre = 'Ordre';
+
+  static const String categorieAucune = 'Aucune catégorie';
+  static const String couverturePleine = 'Rôles standards complets';
+  static const String couverturePartielle = 'Rôles standards incomplets';
+  static const String aucuneAnimLiee = 'Aucune animation liée';
+
+  static String variantesLigne(int n) {
+    if (n <= 1) {
+      return '1 variante';
+    }
+    return '$n variantes';
+  }
+
+  static String animationsLieesSummary(int n) {
+    if (n <= 0) {
+      return aucuneAnimLiee;
+    }
+    if (n == 1) {
+      return '1 animation liée';
+    }
+    return '$n animations liées';
+  }
+}
+
+/// Fiches presets **lecture seule** : ordre = [SurfaceStudioReadModel.presets].
+class SurfaceStudioPresetDetailView extends StatelessWidget {
+  const SurfaceStudioPresetDetailView({
+    super.key,
+    required this.readModel,
+  });
+
+  final SurfaceStudioReadModel readModel;
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        Text(
+          SurfaceStudioPresetDetailViewLabels.title,
+          style: TextStyle(
+            color: label,
+            fontSize: 16,
+            fontWeight: FontWeight.w800,
+            letterSpacing: -0.2,
+          ),
+        ),
+        const SizedBox(height: 10),
+        if (readModel.presets.isEmpty) ...[
+          Text(
+            SurfaceStudioPresetDetailViewLabels.emptyTitle,
+            style: TextStyle(
+              color: subtle,
+              fontSize: 14,
+              fontWeight: FontWeight.w600,
+              fontStyle: FontStyle.italic,
+            ),
+          ),
+          const SizedBox(height: 6),
+          Text(
+            SurfaceStudioPresetDetailViewLabels.emptyHint,
+            style: TextStyle(
+              color: subtle,
+              fontSize: 12,
+              fontWeight: FontWeight.w500,
+              height: 1.35,
+            ),
+          ),
+        ] else
+          ...readModel.presets.map(
+            (row) => Padding(
+              padding: const EdgeInsets.only(bottom: 10),
+              child: _PresetFiche(
+                row: row,
+                label: label,
+                subtle: subtle,
+              ),
+            ),
+          ),
+      ],
+    );
+  }
+}
+
+class _DetailCard extends StatelessWidget {
+  const _DetailCard({required this.child});
+
+  final Widget child;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      padding: const EdgeInsets.all(14),
+      decoration: BoxDecoration(
+        color: EditorChrome.elevatedPanelBackground(context),
+        borderRadius: BorderRadius.circular(14),
+        border: Border.all(
+          color: EditorChrome.editorIslandRim(context),
+          width: 1,
+        ),
+        boxShadow: EditorChrome.sectionCardShadows(context),
+      ),
+      child: child,
+    );
+  }
+}
+
+class _KeyVal extends StatelessWidget {
+  const _KeyVal({
+    required this.k,
+    required this.v,
+    required this.valueColor,
+  });
+
+  final String k;
+  final String v;
+  final Color valueColor;
+
+  @override
+  Widget build(BuildContext context) {
+    return Padding(
+      padding: const EdgeInsets.only(top: 4),
+      child: Text(
+        '$k : $v',
+        style: TextStyle(
+          color: valueColor,
+          fontSize: 13,
+          fontWeight: FontWeight.w500,
+          height: 1.3,
+        ),
+      ),
+    );
+  }
+}
+
+class _PresetFiche extends StatelessWidget {
+  const _PresetFiche({
+    required this.row,
+    required this.label,
+    required this.subtle,
+  });
+
+  final SurfaceStudioPresetReadModel row;
+  final Color label;
+  final Color subtle;
+
+  @override
+  Widget build(BuildContext context) {
+    final animIds = row.referencedAnimationIds;
+    final nAnim = animIds.length;
+    final roleLabels = row.roles.map(surfaceStudioSurfaceVariantRoleLabel);
+    return _DetailCard(
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          Text(
+            row.name,
+            style: TextStyle(
+              color: label,
+              fontSize: 15,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          _KeyVal(
+            k: SurfaceStudioPresetDetailViewLabels.labelIdentifiant,
+            v: row.id,
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: SurfaceStudioPresetDetailViewLabels.labelVariantes,
+            v: SurfaceStudioPresetDetailViewLabels.variantesLigne(
+              row.variantCount,
+            ),
+            valueColor: label,
+          ),
+          const SizedBox(height: 4),
+          Text(
+            SurfaceStudioPresetDetailViewLabels.labelRoles,
+            style: TextStyle(
+              color: subtle,
+              fontSize: 11,
+              fontWeight: FontWeight.w800,
+              letterSpacing: 0.4,
+            ),
+          ),
+          ...roleLabels.map(
+            (r) => Padding(
+              padding: const EdgeInsets.only(top: 2),
+              child: Text(
+                r,
+                style: TextStyle(
+                  color: label,
+                  fontSize: 13,
+                  fontWeight: FontWeight.w600,
+                ),
+              ),
+            ),
+          ),
+          const SizedBox(height: 4),
+          Text(
+            SurfaceStudioPresetDetailViewLabels.labelAnimationsLiees,
+            style: TextStyle(
+              color: subtle,
+              fontSize: 11,
+              fontWeight: FontWeight.w800,
+              letterSpacing: 0.4,
+            ),
+          ),
+          Padding(
+            padding: const EdgeInsets.only(top: 2),
+            child: Text(
+              SurfaceStudioPresetDetailViewLabels.animationsLieesSummary(
+                nAnim,
+              ),
+              style: TextStyle(
+                color: label,
+                fontSize: 13,
+                fontWeight: FontWeight.w600,
+              ),
+            ),
+          ),
+          if (nAnim > 0)
+            ...animIds.map(
+              (id) => Padding(
+                padding: const EdgeInsets.only(top: 2),
+                child: Text(
+                  id,
+                  style: TextStyle(
+                    color: label,
+                    fontSize: 13,
+                    fontWeight: FontWeight.w600,
+                  ),
+                ),
+              ),
+            ),
+          const SizedBox(height: 4),
+          Text(
+            SurfaceStudioPresetDetailViewLabels.labelCouverture,
+            style: TextStyle(
+              color: subtle,
+              fontSize: 11,
+              fontWeight: FontWeight.w800,
+              letterSpacing: 0.4,
+            ),
+          ),
+          Padding(
+            padding: const EdgeInsets.only(top: 2),
+            child: Text(
+              row.coversStandardRoles
+                  ? SurfaceStudioPresetDetailViewLabels.couverturePleine
+                  : SurfaceStudioPresetDetailViewLabels.couverturePartielle,
+              style: TextStyle(
+                color: label,
+                fontSize: 13,
+                fontWeight: FontWeight.w600,
+              ),
+            ),
+          ),
+          _KeyVal(
+            k: SurfaceStudioPresetDetailViewLabels.labelCategorie,
+            v: row.categoryId == null || row.categoryId!.isEmpty
+                ? SurfaceStudioPresetDetailViewLabels.categorieAucune
+                : row.categoryId!,
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: SurfaceStudioPresetDetailViewLabels.labelOrdre,
+            v: row.sortOrder.toString(),
+            valueColor: label,
+          ),
+        ],
+      ),
+    );
+  }
+}
```

#### packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart

```diff
diff --git a/Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart b/Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart
new file mode 100644
index 00000000..31f68f81
--- /dev/null
+++ b/Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart
@@ -0,0 +1,561 @@
+// Tests widget — Surface Studio animation detail (Lot 57).
+// API publique `map_core` uniquement (pas de `package:map_core/src/...`).
+
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_animation_detail_view.dart';
+
+void main() {
+  group('SurfaceStudioAnimationDetailView (Lot 57)', () {
+    testWidgets('1. title Animations Surface', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioAnimationDetailView(readModel: _emptyReadModel())),
+      );
+      expect(find.text('Animations Surface'), findsOneWidget);
+    });
+
+    testWidgets('2. empty: main message', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioAnimationDetailView(readModel: _emptyReadModel())),
+      );
+      expect(find.text('Aucune animation Surface'), findsOneWidget);
+    });
+
+    testWidgets('3. empty: explainer', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioAnimationDetailView(readModel: _emptyReadModel())),
+      );
+      final t = _allText(tester);
+      expect(
+        t.contains('frames') || t.contains('surfaces animées'),
+        isTrue,
+      );
+    });
+
+    testWidgets('4. simple: name and id', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAnimationDetailView(
+            readModel: _oneAnimationReadModel(),
+          ),
+        ),
+      );
+      expect(find.text('Water Loop'), findsOneWidget);
+      expect(
+        find.textContaining('Identifiant : water-loop'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('5. simple: 1 frame', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAnimationDetailView(
+            readModel: _oneAnimationReadModel(),
+          ),
+        ),
+      );
+      expect(find.textContaining('Frames : 1 frame'), findsOneWidget);
+    });
+
+    testWidgets('6. simple: total duration 120 ms', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAnimationDetailView(
+            readModel: _oneAnimationReadModel(),
+          ),
+        ),
+      );
+      expect(find.textContaining('Durée totale : 120 ms'), findsOneWidget);
+    });
+
+    testWidgets('7. simple: referenced atlas', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAnimationDetailView(
+            readModel: _oneAnimationReadModel(),
+          ),
+        ),
+      );
+      expect(find.text('Atlas référencés'), findsOneWidget);
+      expect(find.text('water-atlas'), findsOneWidget);
+    });
+
+    testWidgets('8. two referenced atlases order', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAnimationDetailView(
+            readModel: _animationTwoAtlasesReadModel(),
+          ),
+        ),
+      );
+      expect(find.text('2 atlas référencés'), findsOneWidget);
+      final t = _allText(tester);
+      expect(t.indexOf('atlas-b'), lessThan(t.indexOf('atlas-a')));
+    });
+
+    testWidgets('9. no sync group', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAnimationDetailView(
+            readModel: _oneAnimationReadModel(),
+          ),
+        ),
+      );
+      expect(
+        find.textContaining('Groupe de synchronisation : Aucun groupe'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('10. sync group water', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAnimationDetailView(
+            readModel: _animationWithSyncAndCategoryReadModel(),
+          ),
+        ),
+      );
+      expect(
+        find.textContaining('Groupe de synchronisation : water'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('11. no category', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAnimationDetailView(
+            readModel: _oneAnimationReadModel(),
+          ),
+        ),
+      );
+      expect(
+        find.textContaining('Catégorie : Aucune catégorie'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('12. category', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAnimationDetailView(
+            readModel: _animationWithSyncAndCategoryReadModel(),
+          ),
+        ),
+      );
+      expect(
+        find.textContaining('Catégorie : animated-surfaces'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('13. sortOrder', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAnimationDetailView(
+            readModel: _oneAnimationReadModel(),
+          ),
+        ),
+      );
+      expect(find.textContaining('Ordre : 42'), findsOneWidget);
+    });
+
+    testWidgets('14. referenced atlas order preserved b,a,c', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAnimationDetailView(
+            readModel: _animationThreeAtlasesReadModel(),
+          ),
+        ),
+      );
+      final t = _allText(tester);
+      expect(t.indexOf('atlas-b'), lessThan(t.indexOf('atlas-a')));
+      expect(t.indexOf('atlas-a'), lessThan(t.indexOf('atlas-c')));
+    });
+
+    testWidgets('15. animation order preserved a,b,c', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAnimationDetailView(
+            readModel: _multipleAnimationsReadModel(),
+          ),
+        ),
+      );
+      final t = _allText(tester);
+      expect(t.indexOf('water-a'), lessThan(t.indexOf('water-b')));
+      expect(t.indexOf('water-b'), lessThan(t.indexOf('water-c')));
+    });
+
+    testWidgets('16. does not sort by sortOrder', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAnimationDetailView(
+            readModel: _animationSortOrderContradictionReadModel(),
+          ),
+        ),
+      );
+      final t = _allText(tester);
+      expect(t.indexOf('first'), lessThan(t.indexOf('second')));
+    });
+
+    testWidgets('17. no TextField', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAnimationDetailView(
+            readModel: _oneAnimationReadModel(),
+          ),
+        ),
+      );
+      expect(find.byType(TextField), findsNothing);
+    });
+
+    testWidgets('18. no active edit save affordances', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAnimationDetailView(
+            readModel: _oneAnimationReadModel(),
+          ),
+        ),
+      );
+      for (final s in <String>[
+        'Créer',
+        'Modifier',
+        'Supprimer',
+        'Enregistrer',
+        'Sauvegarder',
+        'Save',
+        'Delete',
+        'Edit',
+      ]) {
+        expect(find.text(s), findsNothing);
+      }
+    });
+
+    testWidgets('19. no internal type names in UI', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAnimationDetailView(
+            readModel: _oneAnimationReadModel(),
+          ),
+        ),
+      );
+      expect(find.textContaining('ProjectSurfaceAnimation'), findsNothing);
+      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
+      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
+      expect(
+          find.textContaining('SurfaceStudioAnimationReadModel'), findsNothing);
+      expect(find.textContaining('SurfaceAnimationTimeline'), findsNothing);
+    });
+
+    testWidgets('20. read model with diagnostics builds', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAnimationDetailView(
+            readModel: _readModelWithDiagnosticsAndAnimation(),
+          ),
+        ),
+      );
+      expect(tester.takeException(), isNull);
+      expect(find.text('loop'), findsOneWidget);
+    });
+
+    testWidgets('21. no ProviderScope', (tester) async {
+      await tester.pumpWidget(
+        MaterialApp(
+          home: SurfaceStudioAnimationDetailView(
+            readModel: _emptyReadModel(),
+          ),
+        ),
+      );
+      expect(find.text('Animations Surface'), findsOneWidget);
+    });
+
+    testWidgets('22. accepts bounded width', (tester) async {
+      await tester.pumpWidget(
+        MaterialApp(
+          home: Center(
+            child: SizedBox(
+              width: 320,
+              child: SingleChildScrollView(
+                child: SurfaceStudioAnimationDetailView(
+                  readModel: _oneAnimationReadModel(),
+                ),
+              ),
+            ),
+          ),
+        ),
+      );
+      expect(tester.takeException(), isNull);
+    });
+  });
+}
+
+String _allText(WidgetTester tester) {
+  return tester
+      .widgetList<Text>(find.byType(Text))
+      .map((e) => e.data ?? '')
+      .join('\n');
+}
+
+Widget _wrap(Widget child) {
+  return MaterialApp(
+    home: SingleChildScrollView(
+      child: Padding(
+        padding: const EdgeInsets.all(16),
+        child: child,
+      ),
+    ),
+  );
+}
+
+SurfaceAtlasGeometry _g2x2() => SurfaceAtlasGeometry(
+      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+      gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
+      layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+    );
+
+SurfaceStudioReadModel _emptyReadModel() =>
+    buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());
+
+SurfaceStudioReadModel _oneAnimationReadModel() {
+  final g = _g2x2();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'water-atlas',
+    name: 'Water Atlas',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final f = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
+    durationMs: 120,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'water-loop',
+    name: 'Water Loop',
+    sortOrder: 42,
+    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[f]),
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: <ProjectSurfaceAtlas>[atlas],
+      animations: <ProjectSurfaceAnimation>[anim],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _animationWithSyncAndCategoryReadModel() {
+  final g = _g2x2();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'a',
+    name: 'A',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final f = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
+    durationMs: 120,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'x',
+    name: 'X',
+    syncGroupId: 'water',
+    categoryId: 'animated-surfaces',
+    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[f]),
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: <ProjectSurfaceAtlas>[atlas],
+      animations: <ProjectSurfaceAnimation>[anim],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _animationTwoAtlasesReadModel() {
+  final ga = _g2x2();
+  final gb = SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: 16, height: 16),
+    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
+    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+  );
+  final a = ProjectSurfaceAtlas(
+      id: 'atlas-a', name: 'A', tilesetId: 't', geometry: ga);
+  final b = ProjectSurfaceAtlas(
+      id: 'atlas-b', name: 'B', tilesetId: 't', geometry: gb);
+  final frames = <SurfaceAnimationFrame>[
+    SurfaceAnimationFrame(
+      tileRef: SurfaceAtlasTileRef(atlasId: 'atlas-b', column: 0, row: 0),
+      durationMs: 10,
+    ),
+    SurfaceAnimationFrame(
+      tileRef: SurfaceAtlasTileRef(atlasId: 'atlas-a', column: 0, row: 0),
+      durationMs: 10,
+    ),
+  ];
+  final anim = ProjectSurfaceAnimation(
+    id: 'anim2',
+    name: 'Anim2',
+    timeline: SurfaceAnimationTimeline(frames: frames),
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: <ProjectSurfaceAtlas>[a, b],
+      animations: <ProjectSurfaceAnimation>[anim],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _animationThreeAtlasesReadModel() {
+  final g = _g2x2();
+  final ba = ProjectSurfaceAtlas(
+    id: 'atlas-b',
+    name: 'B',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final aa = ProjectSurfaceAtlas(
+    id: 'atlas-a',
+    name: 'A2',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final ca = ProjectSurfaceAtlas(
+    id: 'atlas-c',
+    name: 'C',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final frames = <SurfaceAnimationFrame>[
+    SurfaceAnimationFrame(
+      tileRef: SurfaceAtlasTileRef(atlasId: 'atlas-b', column: 0, row: 0),
+      durationMs: 1,
+    ),
+    SurfaceAnimationFrame(
+      tileRef: SurfaceAtlasTileRef(atlasId: 'atlas-a', column: 0, row: 0),
+      durationMs: 1,
+    ),
+    SurfaceAnimationFrame(
+      tileRef: SurfaceAtlasTileRef(atlasId: 'atlas-c', column: 0, row: 0),
+      durationMs: 1,
+    ),
+  ];
+  final anim = ProjectSurfaceAnimation(
+    id: 'tri',
+    name: 'Tri',
+    timeline: SurfaceAnimationTimeline(frames: frames),
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: <ProjectSurfaceAtlas>[ba, aa, ca],
+      animations: <ProjectSurfaceAnimation>[anim],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _multipleAnimationsReadModel() {
+  final g = _g2x2();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'w',
+    name: 'W',
+    tilesetId: 't',
+    geometry: g,
+  );
+  SurfaceAnimationFrame f() => SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(atlasId: 'w', column: 0, row: 0),
+        durationMs: 1,
+      );
+  final a = ProjectSurfaceAnimation(
+    id: 'water-a',
+    name: 'water-a',
+    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[f()]),
+  );
+  final b = ProjectSurfaceAnimation(
+    id: 'water-b',
+    name: 'water-b',
+    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[f()]),
+  );
+  final c = ProjectSurfaceAnimation(
+    id: 'water-c',
+    name: 'water-c',
+    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[f()]),
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: <ProjectSurfaceAtlas>[atlas],
+      animations: <ProjectSurfaceAnimation>[a, b, c],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _animationSortOrderContradictionReadModel() {
+  final g = _g2x2();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'w',
+    name: 'W',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final f = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'w', column: 0, row: 0),
+    durationMs: 1,
+  );
+  final first = ProjectSurfaceAnimation(
+    id: 'f',
+    name: 'first',
+    sortOrder: 99,
+    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[f]),
+  );
+  final second = ProjectSurfaceAnimation(
+    id: 's',
+    name: 'second',
+    sortOrder: 1,
+    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[f]),
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: <ProjectSurfaceAtlas>[atlas],
+      animations: <ProjectSurfaceAnimation>[first, second],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _readModelWithDiagnosticsAndAnimation() {
+  final g = _g2x2();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'w',
+    name: 'W',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final fr = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'w', column: 0, row: 0),
+    durationMs: 10,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'loop',
+    name: 'loop',
+    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[fr]),
+  );
+  final bad = SurfaceVariantAnimationRefSet(
+    refs: <SurfaceVariantAnimationRef>[
+      SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.isolated,
+        animationId: 'nope',
+      ),
+    ],
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: <ProjectSurfaceAtlas>[atlas],
+      animations: <ProjectSurfaceAnimation>[anim],
+      presets: <ProjectSurfacePreset>[
+        ProjectSurfacePreset(
+          id: 'p',
+          name: 'p',
+          variantAnimations: bad,
+        ),
+      ],
+    ),
+  );
+}
```

#### packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart

```diff
diff --git a/Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart b/Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart
new file mode 100644
index 00000000..f9b44ebe
--- /dev/null
+++ b/Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart
@@ -0,0 +1,645 @@
+// Tests widget — Surface Studio preset detail (Lot 57).
+// API publique `map_core` uniquement (pas de `package:map_core/src/...`).
+
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_preset_detail_view.dart';
+
+void main() {
+  group('SurfaceStudioPresetDetailView (Lot 57)', () {
+    testWidgets('23. title Presets Surface', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPresetDetailView(readModel: _emptyReadModel())),
+      );
+      expect(find.text('Presets Surface'), findsOneWidget);
+    });
+
+    testWidgets('24. empty: main message', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPresetDetailView(readModel: _emptyReadModel())),
+      );
+      expect(find.text('Aucun preset Surface'), findsOneWidget);
+    });
+
+    testWidgets('25. empty: explainer', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPresetDetailView(readModel: _emptyReadModel())),
+      );
+      final t = _allText(tester);
+      expect(t.contains('rôles') || t.contains('animations'), isTrue);
+    });
+
+    testWidgets('26. simple: name and id', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPresetDetailView(readModel: _onePresetReadModel()),
+        ),
+      );
+      expect(find.text('Water Surface'), findsOneWidget);
+      expect(
+        find.textContaining('Identifiant : water-surface'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('27. 1 variante', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPresetDetailView(readModel: _onePresetReadModel()),
+        ),
+      );
+      expect(find.textContaining('Variantes : 1 variante'), findsOneWidget);
+    });
+
+    testWidgets('28. isolated role humanized', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPresetDetailView(readModel: _onePresetReadModel()),
+        ),
+      );
+      expect(find.text('Isolé'), findsOneWidget);
+    });
+
+    testWidgets('29. multiple roles order', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPresetDetailView(
+            readModel: _multipleRolesReadModel(),
+          ),
+        ),
+      );
+      final t = _allText(tester);
+      expect(t.indexOf('Croix'), lessThan(t.indexOf('Isolé')));
+      expect(t.indexOf('Isolé'), lessThan(t.indexOf('Horizontal')));
+    });
+
+    testWidgets('30. one linked animation', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPresetDetailView(readModel: _onePresetReadModel()),
+        ),
+      );
+      expect(find.text('Animations liées'), findsOneWidget);
+      expect(find.text('1 animation liée'), findsOneWidget);
+      expect(find.text('water-loop'), findsOneWidget);
+    });
+
+    testWidgets('31. two linked animations order', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPresetDetailView(
+            readModel: _presetTwoAnimationsReadModel(),
+          ),
+        ),
+      );
+      expect(find.text('2 animations liées'), findsOneWidget);
+      final t = _allText(tester);
+      expect(t.indexOf('water-b'), lessThan(t.indexOf('water-a')));
+    });
+
+    testWidgets('32. covers standard false', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPresetDetailView(readModel: _onePresetReadModel()),
+        ),
+      );
+      expect(find.text('Rôles standards incomplets'), findsOneWidget);
+    });
+
+    testWidgets('33. covers standard true', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPresetDetailView(
+            readModel: _presetCompleteRolesReadModel(),
+          ),
+        ),
+      );
+      expect(find.text('Rôles standards complets'), findsOneWidget);
+    });
+
+    testWidgets('34. no category', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPresetDetailView(readModel: _onePresetReadModel()),
+        ),
+      );
+      expect(
+        find.textContaining('Catégorie : Aucune catégorie'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('35. category', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPresetDetailView(
+            readModel: _presetWithCategoryReadModel(),
+          ),
+        ),
+      );
+      expect(
+        find.textContaining('Catégorie : animated-surfaces'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('36. sortOrder', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPresetDetailView(
+            readModel: _onePresetReadModel(),
+          ),
+        ),
+      );
+      expect(find.textContaining('Ordre : 42'), findsOneWidget);
+    });
+
+    testWidgets('37. preset order preserved', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPresetDetailView(
+            readModel: _multiplePresetsReadModel(),
+          ),
+        ),
+      );
+      final t = _allText(tester);
+      expect(t.indexOf('water-surface'), lessThan(t.indexOf('lava-surface')));
+      expect(t.indexOf('lava-surface'), lessThan(t.indexOf('grass-surface')));
+    });
+
+    testWidgets('38. does not sort by sortOrder', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPresetDetailView(
+            readModel: _presetSortOrderContradictionReadModel(),
+          ),
+        ),
+      );
+      final t = _allText(tester);
+      expect(t.indexOf('first'), lessThan(t.indexOf('second')));
+    });
+
+    testWidgets('39. no TextField', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPresetDetailView(
+            readModel: _onePresetReadModel(),
+          ),
+        ),
+      );
+      expect(find.byType(TextField), findsNothing);
+    });
+
+    testWidgets('40. no active edit save affordances', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPresetDetailView(
+            readModel: _onePresetReadModel(),
+          ),
+        ),
+      );
+      for (final s in <String>[
+        'Créer',
+        'Modifier',
+        'Supprimer',
+        'Enregistrer',
+        'Sauvegarder',
+        'Save',
+        'Delete',
+        'Edit',
+      ]) {
+        expect(find.text(s), findsNothing);
+      }
+    });
+
+    testWidgets('41. no internal type names in UI', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPresetDetailView(
+            readModel: _onePresetReadModel(),
+          ),
+        ),
+      );
+      expect(find.textContaining('ProjectSurfacePreset'), findsNothing);
+      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
+      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
+      expect(find.textContaining('SurfaceStudioPresetReadModel'), findsNothing);
+      expect(
+          find.textContaining('SurfaceVariantAnimationRefSet'), findsNothing);
+    });
+
+    testWidgets('42. read model with diagnostics builds', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPresetDetailView(
+            readModel: _readModelWithDiagnosticsAndPreset(),
+          ),
+        ),
+      );
+      expect(tester.takeException(), isNull);
+      expect(find.text('Water Surface'), findsOneWidget);
+    });
+
+    testWidgets('43. no ProviderScope', (tester) async {
+      await tester.pumpWidget(
+        MaterialApp(
+          home: SurfaceStudioPresetDetailView(
+            readModel: _emptyReadModel(),
+          ),
+        ),
+      );
+      expect(find.text('Presets Surface'), findsOneWidget);
+    });
+
+    testWidgets('44. accepts bounded width', (tester) async {
+      await tester.pumpWidget(
+        MaterialApp(
+          home: Center(
+            child: SizedBox(
+              width: 320,
+              child: SingleChildScrollView(
+                child: SurfaceStudioPresetDetailView(
+                  readModel: _onePresetReadModel(),
+                ),
+              ),
+            ),
+          ),
+        ),
+      );
+      expect(tester.takeException(), isNull);
+    });
+  });
+}
+
+String _allText(WidgetTester tester) {
+  return tester
+      .widgetList<Text>(find.byType(Text))
+      .map((e) => e.data ?? '')
+      .join('\n');
+}
+
+Widget _wrap(Widget child) {
+  return MaterialApp(
+    home: SingleChildScrollView(
+      child: Padding(
+        padding: const EdgeInsets.all(16),
+        child: child,
+      ),
+    ),
+  );
+}
+
+SurfaceAtlasGeometry _g2x2() => SurfaceAtlasGeometry(
+      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+      gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
+      layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+    );
+
+SurfaceStudioReadModel _emptyReadModel() =>
+    buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());
+
+SurfaceAnimationFrame _oneFrame() => SurfaceAnimationFrame(
+      tileRef: SurfaceAtlasTileRef(atlasId: 'w', column: 0, row: 0),
+      durationMs: 10,
+    );
+
+SurfaceStudioReadModel _onePresetReadModel() {
+  final g = _g2x2();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'w',
+    name: 'W',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'water-loop',
+    name: 'L',
+    timeline:
+        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
+  );
+  final refs = SurfaceVariantAnimationRefSet(
+    refs: <SurfaceVariantAnimationRef>[
+      SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.isolated,
+        animationId: 'water-loop',
+      ),
+    ],
+  );
+  final preset = ProjectSurfacePreset(
+    id: 'water-surface',
+    name: 'Water Surface',
+    sortOrder: 42,
+    variantAnimations: refs,
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: <ProjectSurfaceAtlas>[atlas],
+      animations: <ProjectSurfaceAnimation>[anim],
+      presets: <ProjectSurfacePreset>[preset],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _multipleRolesReadModel() {
+  final g = _g2x2();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'w',
+    name: 'W',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'a1',
+    name: 'A1',
+    timeline:
+        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
+  );
+  final anim2 = ProjectSurfaceAnimation(
+    id: 'a2',
+    name: 'A2',
+    timeline:
+        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
+  );
+  final anim3 = ProjectSurfaceAnimation(
+    id: 'a3',
+    name: 'A3',
+    timeline:
+        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
+  );
+  final refs = SurfaceVariantAnimationRefSet(
+    refs: <SurfaceVariantAnimationRef>[
+      SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.cross,
+        animationId: 'a1',
+      ),
+      SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.isolated,
+        animationId: 'a2',
+      ),
+      SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.horizontal,
+        animationId: 'a3',
+      ),
+    ],
+  );
+  final preset = ProjectSurfacePreset(
+    id: 'm',
+    name: 'M',
+    variantAnimations: refs,
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: <ProjectSurfaceAtlas>[atlas],
+      animations: <ProjectSurfaceAnimation>[anim, anim2, anim3],
+      presets: <ProjectSurfacePreset>[preset],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _presetTwoAnimationsReadModel() {
+  final g = _g2x2();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'w',
+    name: 'W',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final fa = ProjectSurfaceAnimation(
+    id: 'water-a',
+    name: 'WA',
+    timeline:
+        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
+  );
+  final fb = ProjectSurfaceAnimation(
+    id: 'water-b',
+    name: 'WB',
+    timeline:
+        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
+  );
+  final refs = SurfaceVariantAnimationRefSet(
+    refs: <SurfaceVariantAnimationRef>[
+      SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.isolated,
+        animationId: 'water-b',
+      ),
+      SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.horizontal,
+        animationId: 'water-a',
+      ),
+    ],
+  );
+  final preset = ProjectSurfacePreset(
+    id: 'p2',
+    name: 'P2',
+    variantAnimations: refs,
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: <ProjectSurfaceAtlas>[atlas],
+      animations: <ProjectSurfaceAnimation>[fa, fb],
+      presets: <ProjectSurfacePreset>[preset],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _presetWithCategoryReadModel() {
+  final g = _g2x2();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'w',
+    name: 'W',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'water-loop',
+    name: 'L',
+    timeline:
+        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
+  );
+  final refs = SurfaceVariantAnimationRefSet(
+    refs: <SurfaceVariantAnimationRef>[
+      SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.isolated,
+        animationId: 'water-loop',
+      ),
+    ],
+  );
+  final preset = ProjectSurfacePreset(
+    id: 'water-surface',
+    name: 'Water Surface',
+    categoryId: 'animated-surfaces',
+    variantAnimations: refs,
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: <ProjectSurfaceAtlas>[atlas],
+      animations: <ProjectSurfaceAnimation>[anim],
+      presets: <ProjectSurfacePreset>[preset],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _presetCompleteRolesReadModel() {
+  final g = _g2x2();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'w',
+    name: 'W',
+    tilesetId: 't',
+    geometry: g,
+  );
+  const loopId = 'std-loop';
+  final anim = ProjectSurfaceAnimation(
+    id: loopId,
+    name: 'Std',
+    timeline:
+        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
+  );
+  final refs = SurfaceVariantAnimationRefSet(
+    refs: <SurfaceVariantAnimationRef>[
+      for (final role in standardSurfaceVariantRoleOrder)
+        SurfaceVariantAnimationRef(
+          role: role,
+          animationId: loopId,
+        ),
+    ],
+  );
+  final preset = ProjectSurfacePreset(
+    id: 'full',
+    name: 'Full',
+    variantAnimations: refs,
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: <ProjectSurfaceAtlas>[atlas],
+      animations: <ProjectSurfaceAnimation>[anim],
+      presets: <ProjectSurfacePreset>[preset],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _multiplePresetsReadModel() {
+  final g = _g2x2();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'w',
+    name: 'W',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'loop',
+    name: 'L',
+    timeline:
+        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
+  );
+  ProjectSurfacePreset mk(String id, String name) {
+    return ProjectSurfacePreset(
+      id: id,
+      name: name,
+      variantAnimations: SurfaceVariantAnimationRefSet(
+        refs: <SurfaceVariantAnimationRef>[
+          SurfaceVariantAnimationRef(
+            role: SurfaceVariantRole.isolated,
+            animationId: 'loop',
+          ),
+        ],
+      ),
+    );
+  }
+
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: <ProjectSurfaceAtlas>[atlas],
+      animations: <ProjectSurfaceAnimation>[anim],
+      presets: <ProjectSurfacePreset>[
+        mk('water-surface', 'WS'),
+        mk('lava-surface', 'LS'),
+        mk('grass-surface', 'GS'),
+      ],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _presetSortOrderContradictionReadModel() {
+  final g = _g2x2();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'w',
+    name: 'W',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'loop',
+    name: 'L',
+    timeline:
+        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
+  );
+  ProjectSurfacePreset p(String id, String name, int so) {
+    return ProjectSurfacePreset(
+      id: id,
+      name: name,
+      sortOrder: so,
+      variantAnimations: SurfaceVariantAnimationRefSet(
+        refs: <SurfaceVariantAnimationRef>[
+          SurfaceVariantAnimationRef(
+            role: SurfaceVariantRole.isolated,
+            animationId: 'loop',
+          ),
+        ],
+      ),
+    );
+  }
+
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: <ProjectSurfaceAtlas>[atlas],
+      animations: <ProjectSurfaceAnimation>[anim],
+      presets: <ProjectSurfacePreset>[
+        p('a', 'first', 99),
+        p('b', 'second', 1),
+      ],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _readModelWithDiagnosticsAndPreset() {
+  final g = _g2x2();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'w',
+    name: 'W',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final unusedAtlas = ProjectSurfaceAtlas(
+    id: 'orphan-atlas',
+    name: 'Orphan',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final okAnim = ProjectSurfaceAnimation(
+    id: 'ok',
+    name: 'ok',
+    timeline:
+        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
+  );
+  final refs = SurfaceVariantAnimationRefSet(
+    refs: <SurfaceVariantAnimationRef>[
+      SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.isolated,
+        animationId: 'ok',
+      ),
+    ],
+  );
+  final preset = ProjectSurfacePreset(
+    id: 'p',
+    name: 'Water Surface',
+    variantAnimations: refs,
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: <ProjectSurfaceAtlas>[atlas, unusedAtlas],
+      animations: <ProjectSurfaceAnimation>[okAnim],
+      presets: <ProjectSurfacePreset>[preset],
+    ),
+  );
+}
```

---

## D. Sorties de commandes (reproduction exacte)

### D.1 flutter test animation_detail (dernière ligne)

```

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart                                                           
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart                                                           
00:01 +0: SurfaceStudioAnimationDetailView (Lot 57) 1. title Animations Surface                                                                                                                        
00:01 +1: SurfaceStudioAnimationDetailView (Lot 57) 1. title Animations Surface                                                                                                                        
00:01 +1: SurfaceStudioAnimationDetailView (Lot 57) 2. empty: main message                                                                                                                             
00:01 +2: SurfaceStudioAnimationDetailView (Lot 57) 2. empty: main message                                                                                                                             
00:01 +2: SurfaceStudioAnimationDetailView (Lot 57) 3. empty: explainer                                                                                                                                
00:01 +3: SurfaceStudioAnimationDetailView (Lot 57) 3. empty: explainer                                                                                                                                
00:01 +3: SurfaceStudioAnimationDetailView (Lot 57) 4. simple: name and id                                                                                                                             
00:01 +4: SurfaceStudioAnimationDetailView (Lot 57) 4. simple: name and id                                                                                                                             
00:01 +4: SurfaceStudioAnimationDetailView (Lot 57) 5. simple: 1 frame                                                                                                                                 
00:01 +5: SurfaceStudioAnimationDetailView (Lot 57) 5. simple: 1 frame                                                                                                                                 
00:01 +5: SurfaceStudioAnimationDetailView (Lot 57) 6. simple: total duration 120 ms                                                                                                                   
00:01 +6: SurfaceStudioAnimationDetailView (Lot 57) 6. simple: total duration 120 ms                                                                                                                   
00:01 +6: SurfaceStudioAnimationDetailView (Lot 57) 7. simple: referenced atlas                                                                                                                        
00:01 +7: SurfaceStudioAnimationDetailView (Lot 57) 7. simple: referenced atlas                                                                                                                        
00:01 +7: SurfaceStudioAnimationDetailView (Lot 57) 8. two referenced atlases order                                                                                                                    
00:01 +8: SurfaceStudioAnimationDetailView (Lot 57) 8. two referenced atlases order                                                                                                                    
00:01 +8: SurfaceStudioAnimationDetailView (Lot 57) 9. no sync group                                                                                                                                   
00:01 +9: SurfaceStudioAnimationDetailView (Lot 57) 9. no sync group                                                                                                                                   
00:01 +9: SurfaceStudioAnimationDetailView (Lot 57) 10. sync group water                                                                                                                               
00:01 +10: SurfaceStudioAnimationDetailView (Lot 57) 10. sync group water                                                                                                                              
00:01 +10: SurfaceStudioAnimationDetailView (Lot 57) 11. no category                                                                                                                                   
00:01 +11: SurfaceStudioAnimationDetailView (Lot 57) 11. no category                                                                                                                                   
00:01 +11: SurfaceStudioAnimationDetailView (Lot 57) 12. category                                                                                                                                      
00:01 +12: SurfaceStudioAnimationDetailView (Lot 57) 12. category                                                                                                                                      
00:01 +12: SurfaceStudioAnimationDetailView (Lot 57) 13. sortOrder                                                                                                                                     
00:01 +13: SurfaceStudioAnimationDetailView (Lot 57) 13. sortOrder                                                                                                                                     
00:01 +13: SurfaceStudioAnimationDetailView (Lot 57) 14. referenced atlas order preserved b,a,c                                                                                                        
00:01 +14: SurfaceStudioAnimationDetailView (Lot 57) 14. referenced atlas order preserved b,a,c                                                                                                        
00:01 +14: SurfaceStudioAnimationDetailView (Lot 57) 15. animation order preserved a,b,c                                                                                                               
00:01 +15: SurfaceStudioAnimationDetailView (Lot 57) 15. animation order preserved a,b,c                                                                                                               
00:01 +15: SurfaceStudioAnimationDetailView (Lot 57) 16. does not sort by sortOrder                                                                                                                    
00:01 +16: SurfaceStudioAnimationDetailView (Lot 57) 16. does not sort by sortOrder                                                                                                                    
00:01 +16: SurfaceStudioAnimationDetailView (Lot 57) 17. no TextField                                                                                                                                  
00:01 +17: SurfaceStudioAnimationDetailView (Lot 57) 17. no TextField                                                                                                                                  
00:01 +17: SurfaceStudioAnimationDetailView (Lot 57) 18. no active edit save affordances                                                                                                               
00:01 +18: SurfaceStudioAnimationDetailView (Lot 57) 18. no active edit save affordances                                                                                                               
00:01 +18: SurfaceStudioAnimationDetailView (Lot 57) 19. no internal type names in UI                                                                                                                  
00:01 +19: SurfaceStudioAnimationDetailView (Lot 57) 19. no internal type names in UI                                                                                                                  
00:01 +19: SurfaceStudioAnimationDetailView (Lot 57) 20. read model with diagnostics builds                                                                                                            
00:01 +20: SurfaceStudioAnimationDetailView (Lot 57) 20. read model with diagnostics builds                                                                                                            
00:01 +20: SurfaceStudioAnimationDetailView (Lot 57) 21. no ProviderScope                                                                                                                              
00:02 +20: SurfaceStudioAnimationDetailView (Lot 57) 21. no ProviderScope                                                                                                                              
00:02 +21: SurfaceStudioAnimationDetailView (Lot 57) 21. no ProviderScope                                                                                                                              
00:02 +21: SurfaceStudioAnimationDetailView (Lot 57) 22. accepts bounded width                                                                                                                         
00:02 +22: SurfaceStudioAnimationDetailView (Lot 57) 22. accepts bounded width                                                                                                                         
00:02 +22: All tests passed!
```

### D.2 flutter test preset_detail (dernière ligne)

```

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart                                                              
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart                                                              
00:01 +0: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface                                                                                                                             
00:01 +1: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface                                                                                                                             
00:01 +1: SurfaceStudioPresetDetailView (Lot 57) 24. empty: main message                                                                                                                               
00:01 +2: SurfaceStudioPresetDetailView (Lot 57) 24. empty: main message                                                                                                                               
00:01 +2: SurfaceStudioPresetDetailView (Lot 57) 25. empty: explainer                                                                                                                                  
00:01 +3: SurfaceStudioPresetDetailView (Lot 57) 25. empty: explainer                                                                                                                                  
00:01 +3: SurfaceStudioPresetDetailView (Lot 57) 26. simple: name and id                                                                                                                               
00:01 +4: SurfaceStudioPresetDetailView (Lot 57) 26. simple: name and id                                                                                                                               
00:01 +4: SurfaceStudioPresetDetailView (Lot 57) 27. 1 variante                                                                                                                                        
00:01 +5: SurfaceStudioPresetDetailView (Lot 57) 27. 1 variante                                                                                                                                        
00:01 +5: SurfaceStudioPresetDetailView (Lot 57) 28. isolated role humanized                                                                                                                           
00:01 +6: SurfaceStudioPresetDetailView (Lot 57) 28. isolated role humanized                                                                                                                           
00:01 +6: SurfaceStudioPresetDetailView (Lot 57) 29. multiple roles order                                                                                                                              
00:01 +7: SurfaceStudioPresetDetailView (Lot 57) 29. multiple roles order                                                                                                                              
00:01 +7: SurfaceStudioPresetDetailView (Lot 57) 30. one linked animation                                                                                                                              
00:01 +8: SurfaceStudioPresetDetailView (Lot 57) 30. one linked animation                                                                                                                              
00:01 +8: SurfaceStudioPresetDetailView (Lot 57) 31. two linked animations order                                                                                                                       
00:01 +9: SurfaceStudioPresetDetailView (Lot 57) 31. two linked animations order                                                                                                                       
00:01 +9: SurfaceStudioPresetDetailView (Lot 57) 32. covers standard false                                                                                                                             
00:01 +10: SurfaceStudioPresetDetailView (Lot 57) 32. covers standard false                                                                                                                            
00:01 +10: SurfaceStudioPresetDetailView (Lot 57) 33. covers standard true                                                                                                                             
00:01 +11: SurfaceStudioPresetDetailView (Lot 57) 33. covers standard true                                                                                                                             
00:01 +11: SurfaceStudioPresetDetailView (Lot 57) 34. no category                                                                                                                                      
00:01 +12: SurfaceStudioPresetDetailView (Lot 57) 34. no category                                                                                                                                      
00:01 +12: SurfaceStudioPresetDetailView (Lot 57) 35. category                                                                                                                                         
00:01 +13: SurfaceStudioPresetDetailView (Lot 57) 35. category                                                                                                                                         
00:01 +13: SurfaceStudioPresetDetailView (Lot 57) 36. sortOrder                                                                                                                                        
00:01 +14: SurfaceStudioPresetDetailView (Lot 57) 36. sortOrder                                                                                                                                        
00:01 +14: SurfaceStudioPresetDetailView (Lot 57) 37. preset order preserved                                                                                                                           
00:01 +15: SurfaceStudioPresetDetailView (Lot 57) 37. preset order preserved                                                                                                                           
00:01 +15: SurfaceStudioPresetDetailView (Lot 57) 38. does not sort by sortOrder                                                                                                                       
00:01 +16: SurfaceStudioPresetDetailView (Lot 57) 38. does not sort by sortOrder                                                                                                                       
00:01 +16: SurfaceStudioPresetDetailView (Lot 57) 39. no TextField                                                                                                                                     
00:01 +17: SurfaceStudioPresetDetailView (Lot 57) 39. no TextField                                                                                                                                     
00:01 +17: SurfaceStudioPresetDetailView (Lot 57) 40. no active edit save affordances                                                                                                                  
00:01 +18: SurfaceStudioPresetDetailView (Lot 57) 40. no active edit save affordances                                                                                                                  
00:01 +18: SurfaceStudioPresetDetailView (Lot 57) 41. no internal type names in UI                                                                                                                     
00:01 +19: SurfaceStudioPresetDetailView (Lot 57) 41. no internal type names in UI                                                                                                                     
00:01 +19: SurfaceStudioPresetDetailView (Lot 57) 42. read model with diagnostics builds                                                                                                               
00:01 +20: SurfaceStudioPresetDetailView (Lot 57) 42. read model with diagnostics builds                                                                                                               
00:01 +20: SurfaceStudioPresetDetailView (Lot 57) 43. no ProviderScope                                                                                                                                 
00:01 +21: SurfaceStudioPresetDetailView (Lot 57) 43. no ProviderScope                                                                                                                                 
00:01 +21: SurfaceStudioPresetDetailView (Lot 57) 44. accepts bounded width                                                                                                                            
00:02 +21: SurfaceStudioPresetDetailView (Lot 57) 44. accepts bounded width                                                                                                                            
00:02 +22: SurfaceStudioPresetDetailView (Lot 57) 44. accepts bounded width                                                                                                                            
00:02 +22: All tests passed!
```

### D.3 Suite combinée surface_studio (7 fichiers) — dernière ligne

```

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart                                                           
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart                                                           
00:01 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: ... (Lot 57) 1. title Animations Surface                         
00:02 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: ... (Lot 57) 1. title Animations Surface                         
00:02 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface    
00:02 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface    
00:02 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface    
00:02 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface    
00:02 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface    
00:02 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface    
00:02 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface    
00:02 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface         
00:02 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface         
00:02 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface        
00:02 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface        
00:02 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface        
00:02 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface        
00:02 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface        
00:02 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface        
00:02 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface        
00:02 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface        
00:02 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface        
00:02 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface        
00:02 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface        
00:02 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface        
00:02 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:02 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:02 +24: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:02 +25: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:02 +26: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:02 +27: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:02 +28: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:02 +29: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:02 +30: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:02 +31: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:02 +32: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:02 +33: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:02 +34: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:02 +35: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:02 +36: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:02 +37: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:02 +38: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:02 +39: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:02 +40: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                 
00:02 +41: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                 
00:02 +42: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                 
00:02 +43: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                 
00:02 +44: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                 
00:02 +45: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                 
00:02 +46: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                 
00:02 +47: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                 
00:02 +48: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                 
00:02 +49: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: ... (Lot 57) 38. does not sort by sortOrder                        
00:02 +50: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 4. clean: counts zero          
00:02 +51: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 4. clean: counts zero          
00:02 +52: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 2. empty catalog: global empty message                   
00:02 +53: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 2. empty catalog: global empty message                   
00:02 +54: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 2. empty catalog: global empty message                   
00:02 +55: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 5. error missingPresetAnimation
00:02 +56: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 5. error missingPresetAnimation
00:02 +57: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 11. categoryId set            
00:02 +58: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 3. empty catalog: per-section empty lines                
00:02 +59: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: ... (Lot 57) 41. no internal type names in UI                      
00:02 +60: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 6. error missingAnimationAtlas 
00:02 +61: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 6. error missingAnimationAtlas 
00:02 +62: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 4. minimal catalog: section headers visible              
00:02 +63: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 4. minimal catalog: section headers visible              
00:02 +64: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 4. minimal catalog: section headers visible              
00:02 +65: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 4. minimal catalog: section headers visible              
00:02 +66: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 4. minimal catalog: section headers visible              
00:02 +67: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 4. minimal catalog: section headers visible              
00:02 +68: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 4. minimal catalog: section headers visible              
00:02 +69: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 4. minimal catalog: section headers visible              
00:02 +70: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 15. used by two animations    
00:02 +71: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 9. warning unusedAnimation     
00:02 +72: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 5. minimal catalog: atlas details (736-tile grid)        
00:02 +73: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 5. minimal catalog: atlas details (736-tile grid)        
00:02 +74: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: ... (Lot 55) 10. mixed: Erreurs and Avertissements sections          
00:02 +75: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 6. minimal catalog: animation details                    
00:02 +76: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 6. minimal catalog: animation details                    
00:02 +77: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 11. mixed: summary counts      
00:02 +78: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: ... (Lot 56) 18. not sorted by sortOrder (First before Second)      
00:02 +79: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 7. minimal catalog: preset details                       
00:02 +80: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 7. minimal catalog: preset details                       
00:02 +81: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 19. no TextField              
00:02 +82: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 8. full animation: sync group and category               
00:02 +83: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 8. full animation: sync group and category               
00:02 +84: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 20. no active edit/save copy  
00:02 +85: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: ... (Lot 55) 14. warnings only: no errors line empty section         
00:02 +86: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 9. atlas used by two animations  
00:02 +87: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 9. atlas used by two animations  
00:02 +88: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: ... (Lot 55) 15. errors only: no warnings line empty section         
00:02 +89: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: ... (Lot 56) 22. builds with diagnostics in read model, no throw    
00:02 +90: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 10. atlas unused                 
00:02 +91: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 16. no TextField               
00:02 +92: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 16. no TextField               
00:02 +93: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 11. animation referenced atlas ids deduped order         
00:02 +94: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 28. bounded width, no throw   
00:02 +95: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 17. no fix affordances on view 
00:02 +96: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 12. preset referenced animation ids deduped order        
00:02 +97: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 12. preset referenced animation ids deduped order        
00:02 +98: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 12. preset referenced animation ids deduped order        
00:02 +99: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: ... (Lot 56) 30. layout rowsAreVariants (fallback string)           
00:02 +100: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: ... (Lot 55) 19. many diagnostics build without throw               
00:02 +101: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 13. preset roles source order   
00:02 +102: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: ... (Lot 56) 31. layout grid (fallback string)                     
00:02 +103: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: ... (Lot 55) 20. messages follow readModel.diagnostics              
00:02 +104: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 14. atlas order preserved       
00:02 +105: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 14. atlas order preserved       
00:02 +106: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 26. bounded width             
00:03 +106: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 26. bounded width             
00:03 +107: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 15. animation order preserved   
00:03 +108: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 15. animation order preserved   
00:03 +109: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 15. animation order preserved   
00:03 +109: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 16. preset order preserved      
00:03 +110: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 16. preset order preserved      
00:03 +110: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 17. order is list order not sortOrder                   
00:03 +111: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 17. order is list order not sortOrder                   
00:03 +111: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 18. browser in scrollable ancestor                      
00:03 +112: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 18. browser in scrollable ancestor                      
00:03 +112: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 19. no TextField in browser     
00:03 +113: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 19. no TextField in browser     
00:03 +113: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 20. browser has no active edit affordances              
00:03 +114: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                 
00:03 +115: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                 
00:03 +116: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                 
00:03 +117: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                 
00:03 +118: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                 
00:03 +119: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                 
00:03 +120: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                 
00:03 +121: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                 
00:03 +122: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                 
00:03 +123: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                 
00:03 +124: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                 
00:03 +124: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 2. read-only badge is visible                      
00:03 +125: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 2. read-only badge is visible                      
00:03 +125: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 3. three counters are zero for empty catalog       
00:03 +126: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 3. three counters are zero for empty catalog       
00:03 +126: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 4. empty catalog shows empty state copy            
00:03 +127: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 4. empty catalog shows empty state copy            
00:03 +127: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 5. minimal catalog shows 1/1/1                     
00:03 +128: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 5. minimal catalog shows 1/1/1                     
00:03 +128: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 6. non-empty shows catalog browser content         
00:03 +129: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 6. non-empty shows catalog browser content         
00:03 +129: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 7. clean diagnostics for minimal coherent catalog  
00:03 +130: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 7. clean diagnostics for minimal coherent catalog  
00:03 +130: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 8. warning state when unused atlas                 
00:03 +131: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 8. warning state when unused atlas                 
00:03 +131: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 9. error state when preset animation missing       
00:03 +132: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 9. error state when preset animation missing       
00:03 +132: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 10. future action labels are visible               
00:03 +133: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 10. future action labels are visible               
00:03 +133: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 11. future actions are disabled (onPressed null)   
00:03 +134: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 11. future actions are disabled (onPressed null)   
00:03 +134: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 12. section placeholder titles are visible         
00:03 +135: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 12. section placeholder titles are visible         
00:03 +135: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 13. SurfaceStudioPanelFromManifest uses manifest catalog          
00:03 +136: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 13. SurfaceStudioPanelFromManifest uses manifest catalog          
00:03 +136: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 14. manifest is not mutated after pump             
00:03 +137: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 14. manifest is not mutated after pump             
00:03 +137: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... 15. does not require provider setup — panel builds without ProviderScope   
00:04 +137: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... 15. does not require provider setup — panel builds without ProviderScope   
00:04 +138: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... 15. does not require provider setup — panel builds without ProviderScope   
00:04 +138: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 16. content is in a scrollable                     
00:04 +139: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 16. content is in a scrollable                     
00:04 +139: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 17. no internal domain type names in user-visible strings         
00:04 +140: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 17. no internal domain type names in user-visible strings         
00:04 +140: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 18. error read model does not throw on build       
00:04 +141: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 18. error read model does not throw on build       
00:04 +141: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 19. warning read model does not throw on build     
00:04 +142: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 19. warning read model does not throw on build     
00:04 +142: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 20. displayed counts match read model summary      
00:04 +143: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 20. displayed counts match read model summary      
00:04 +143: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 22. no TextField in panel                          
00:04 +144: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 22. no TextField in panel                          
00:04 +144: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 23. no save affordances                            
00:04 +145: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 23. no save affordances                            
00:04 +145: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 22. panel shows catalog browser for minimal catalog
00:04 +146: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 22. panel shows catalog browser for minimal catalog
00:04 +146: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 24. test file uses public map_core only (smoke)    
00:04 +147: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 24. test file uses public map_core only (smoke)    
00:04 +147: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 25. Lot 55 — clean diagnostics view in panel       
00:04 +148: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 25. Lot 55 — clean diagnostics view in panel       
00:04 +148: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 26. Lot 55 — error diagnostics visible in panel    
00:04 +149: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 26. Lot 55 — error diagnostics visible in panel    
00:04 +149: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 27. Lot 55 — browser and diagnostics cohabit (minimal cat)        
00:04 +150: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 27. Lot 55 — browser and diagnostics cohabit (minimal cat)        
00:04 +150: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... 52) 48. Lot 57 — panel shows Atlas / Animations / Presets / Diagnostics    
00:04 +151: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... 52) 48. Lot 57 — panel shows Atlas / Animations / Presets / Diagnostics    
00:04 +151: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 30. Lot 55 — surfaceCatalog unchanged after panel pump            
00:04 +152: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 30. Lot 55 — surfaceCatalog unchanged after panel pump            
00:05 +152: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 30. Lot 55 — surfaceCatalog unchanged after panel pump            
00:06 +152: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 30. Lot 55 — surfaceCatalog unchanged after panel pump            
00:06 +152: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart                                                               
00:06 +152: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) EditorWorkspaceMode.surfaceStudio exists in enum  
00:06 +153: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) EditorWorkspaceMode.surfaceStudio exists in enum  
00:06 +153: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:07 +153: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:07 +154: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:07 +154: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) subtitle mentions animated surfaces (Surfaces animées)  
00:07 +155: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) subtitle mentions animated surfaces (Surfaces animées)  
00:07 +155: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) Terrain / Surface Studio / Path Library order in column 
00:07 +156: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) Terrain / Surface Studio / Path Library order in column 
00:07 +156: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:07 +157: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:07 +157: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... 53) EditorCanvasHost builds SurfaceStudioPanel in surface mode   
00:07 +158: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... 53) EditorCanvasHost builds SurfaceStudioPanel in surface mode   
00:07 +158: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) works without an active map (no map required)     
00:08 +158: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) works without an active map (no map required)     
00:08 +159: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) works without an active map (no map required)     
00:08 +159: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) panel shows 1/1/1 from manifest when catalog is minimal 
00:08 +160: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) panel shows 1/1/1 from manifest when catalog is minimal 
00:08 +160: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... future action CupertinoButtons are disabled, no TextField        
00:08 +161: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... future action CupertinoButtons are disabled, no TextField        
00:08 +161: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry (Lot 53) no Surface save button labels
00:08 +162: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry (Lot 53) no Surface save button labels
00:08 +162: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) no internal type names in visible shell copy      
00:08 +163: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) no internal type names in visible shell copy      
00:08 +163: All tests passed!
```

**Total tests suite combinée** : 163.

### D.4 flutter analyze (13 chemins)

```
Analyzing 13 items...                                           
No issues found! (ran in 1.7s)
```

### D.5 dart test map_core surface_studio_read_model_test (dernière ligne)

```

00:00 [32m+0[0m: [1m[90mloading test/surface_studio_read_model_test.dart[0m[0m                                                                                                                                             
00:00 [32m+0[0m: Surface Studio read model (Lot 51) 1. empty catalog: summary, lists, clean diagnostics[0m                                                                                                       
00:00 [32m+1[0m: Surface Studio read model (Lot 51) 1. empty catalog: summary, lists, clean diagnostics[0m                                                                                                       
00:00 [32m+1[0m: Surface Studio read model (Lot 51) 2. buildSurfaceStudioReadModel uses manifest catalog; no manifest mutation[0m                                                                                
00:00 [32m+2[0m: Surface Studio read model (Lot 51) 2. buildSurfaceStudioReadModel uses manifest catalog; no manifest mutation[0m                                                                                
00:00 [32m+2[0m: Surface Studio read model (Lot 51) 3. minimal water — summary counts and non-empty[0m                                                                                                           
00:00 [32m+3[0m: Surface Studio read model (Lot 51) 3. minimal water — summary counts and non-empty[0m                                                                                                           
00:00 [32m+3[0m: Surface Studio read model (Lot 51) 4. minimal water — atlas row main fields[0m                                                                                                                  
00:00 [32m+4[0m: Surface Studio read model (Lot 51) 4. minimal water — atlas row main fields[0m                                                                                                                  
00:00 [32m+4[0m: Surface Studio read model (Lot 51) 5. atlas rows preserve catalog order[0m                                                                                                                      
00:00 [32m+5[0m: Surface Studio read model (Lot 51) 5. atlas rows preserve catalog order[0m                                                                                                                      
00:00 [32m+5[0m: Surface Studio read model (Lot 51) 6. atlas usedByAnimationIds — two animations, one atlas[0m                                                                                                   
00:00 [32m+6[0m: Surface Studio read model (Lot 51) 6. atlas usedByAnimationIds — two animations, one atlas[0m                                                                                                   
00:00 [32m+6[0m: Surface Studio read model (Lot 51) 7. atlas usedByAnimationIds — one animation twice same atlas[0m                                                                                              
00:00 [32m+7[0m: Surface Studio read model (Lot 51) 7. atlas usedByAnimationIds — one animation twice same atlas[0m                                                                                              
00:00 [32m+7[0m: Surface Studio read model (Lot 51) 8. minimal water — animation row main fields[0m                                                                                                              
00:00 [32m+8[0m: Surface Studio read model (Lot 51) 8. minimal water — animation row main fields[0m                                                                                                              
00:00 [32m+8[0m: Surface Studio read model (Lot 51) 9. animation rows preserve catalog order[0m                                                                                                                  
00:00 [32m+9[0m: Surface Studio read model (Lot 51) 9. animation rows preserve catalog order[0m                                                                                                                  
00:00 [32m+9[0m: Surface Studio read model (Lot 51) 10. animation referencedAtlasIds — first appearance order[0m                                                                                                 
00:00 [32m+10[0m: Surface Studio read model (Lot 51) 10. animation referencedAtlasIds — first appearance order[0m                                                                                                
00:00 [32m+10[0m: Surface Studio read model (Lot 51) 11. animation read model does not validate atlas existence[0m                                                                                               
00:00 [32m+11[0m: Surface Studio read model (Lot 51) 11. animation read model does not validate atlas existence[0m                                                                                               
00:00 [32m+11[0m: Surface Studio read model (Lot 51) 12. minimal water — preset row main fields[0m                                                                                                               
00:00 [32m+12[0m: Surface Studio read model (Lot 51) 12. minimal water — preset row main fields[0m                                                                                                               
00:00 [32m+12[0m: Surface Studio read model (Lot 51) 13. preset rows preserve catalog order[0m                                                                                                                   
00:00 [32m+13[0m: Surface Studio read model (Lot 51) 13. preset rows preserve catalog order[0m                                                                                                                   
00:00 [32m+13[0m: Surface Studio read model (Lot 51) 14. preset referencedAnimationIds — dedupe keeps order[0m                                                                                                   
00:00 [32m+14[0m: Surface Studio read model (Lot 51) 14. preset referencedAnimationIds — dedupe keeps order[0m                                                                                                   
00:00 [32m+14[0m: Surface Studio read model (Lot 51) 15. preset read model does not validate animation existence[0m                                                                                              
00:00 [32m+15[0m: Surface Studio read model (Lot 51) 15. preset read model does not validate animation existence[0m                                                                                              
00:00 [32m+15[0m: Surface Studio read model (Lot 51) 16. full water — preset role order cross, isolated, horizontal[0m                                                                                           
00:00 [32m+16[0m: Surface Studio read model (Lot 51) 16. full water — preset role order cross, isolated, horizontal[0m                                                                                           
00:00 [32m+16[0m: Surface Studio read model (Lot 51) 17. minimal water — diagnostics clean flags on read model[0m                                                                                                
00:00 [32m+17[0m: Surface Studio read model (Lot 51) 17. minimal water — diagnostics clean flags on read model[0m                                                                                                
00:00 [32m+17[0m: Surface Studio read model (Lot 51) 18. diagnostics error — missing animation atlas[0m                                                                                                          
00:00 [32m+18[0m: Surface Studio read model (Lot 51) 18. diagnostics error — missing animation atlas[0m                                                                                                          
00:00 [32m+18[0m: Surface Studio read model (Lot 51) 19. diagnostics error — missing preset animation[0m                                                                                                         
00:00 [32m+19[0m: Surface Studio read model (Lot 51) 19. diagnostics error — missing preset animation[0m                                                                                                         
00:00 [32m+19[0m: Surface Studio read model (Lot 51) 20. diagnostics warning — unused atlas[0m                                                                                                                   
00:00 [32m+20[0m: Surface Studio read model (Lot 51) 20. diagnostics warning — unused atlas[0m                                                                                                                   
00:00 [32m+20[0m: Surface Studio read model (Lot 51) 21. root lists are unmodifiable[0m                                                                                                                          
00:00 [32m+21[0m: Surface Studio read model (Lot 51) 21. root lists are unmodifiable[0m                                                                                                                          
00:00 [32m+21[0m: Surface Studio read model (Lot 51) 22. nested lists are unmodifiable[0m                                                                                                                        
00:00 [32m+22[0m: Surface Studio read model (Lot 51) 22. nested lists are unmodifiable[0m                                                                                                                        
00:00 [32m+22[0m: Surface Studio read model (Lot 51) 23. builder does not order by sortOrder — source list order[0m                                                                                              
00:00 [32m+23[0m: Surface Studio read model (Lot 51) 23. builder does not order by sortOrder — source list order[0m                                                                                              
00:00 [32m+23[0m: Surface Studio read model (Lot 51) 24. builder does not mutate the source catalog[0m                                                                                                           
00:00 [32m+24[0m: Surface Studio read model (Lot 51) 24. builder does not mutate the source catalog[0m                                                                                                           
00:00 [32m+24[0m: Surface Studio read model (Lot 51) 25. value equality of read models for equivalent catalogs[0m                                                                                                
00:00 [32m+25[0m: Surface Studio read model (Lot 51) 25. value equality of read models for equivalent catalogs[0m                                                                                                
00:00 [32m+25[0m: Surface Studio read model (Lot 51) 26. inequality when content differs[0m                                                                                                                      
00:00 [32m+26[0m: Surface Studio read model (Lot 51) 26. inequality when content differs[0m                                                                                                                      
00:00 [32m+26[0m: Surface Studio read model (Lot 51) 27. public export — map_core[0m                                                                                                                             
00:00 [32m+27[0m: Surface Studio read model (Lot 51) 27. public export — map_core[0m                                                                                                                             
00:00 [32m+27[0m: Surface Studio read model (Lot 51) 28. ProjectManifest toJson still Lot 49 — surfaceCatalog only[0m                                                                                            
00:00 [32m+28[0m: Surface Studio read model (Lot 51) 28. ProjectManifest toJson still Lot 49 — surfaceCatalog only[0m                                                                                            
00:00 [32m+28[0m: Surface Studio read model (Lot 51) 29. Lot 47 fixtures — valid JSON, no top-level surfaceCatalog[0m                                                                                            
00:00 [32m+29[0m: Surface Studio read model (Lot 51) 29. Lot 47 fixtures — valid JSON, no top-level surfaceCatalog[0m                                                                                            
00:00 [32m+29[0m: Surface Studio read model (Lot 51) 30. no Flutter / Riverpod in surface read model public API[0m                                                                                               
00:00 [32m+30[0m: Surface Studio read model (Lot 51) 30. no Flutter / Riverpod in surface read model public API[0m                                                                                               
00:00 [32m+30[0m: All tests passed![0m
```

### D.6 flutter test map_editor complet (dernière ligne, dette préexistante)

```

00:54 +636 -41: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: load use case reads the synced catalog after a real sync                   
00:54 +636 -41: Some tests failed.
```


## Fichiers formatés (dart format)

```text
lib/src/features/surface_studio/surface_studio_catalog_browser.dart
test/surface_studio/surface_studio_animation_detail_view_test.dart
test/surface_studio/surface_studio_preset_detail_view_test.dart
test/surface_studio/surface_studio_catalog_browser_test.dart
test/surface_studio/surface_studio_panel_test.dart
test/surface_studio/surface_studio_workspace_entry_test.dart
```

Binaire : `dart format` (PATH).

## Vérification anti-mojibake

Contrôle manuel / lecture UTF-8 des fichiers créés ou modifiés par le Lot 57 : pas de séquences type `Ã` / `â€™` visibles.

## Autocritique / points de vigilance

- Labels `SurfaceStudioCatalogBrowserLabels.sectionAnimations` / `sectionPresets` restent dans le fichier sans usage direct des titres de section (titres portés par les vues détail) : nettoyage futur hors scope.
- Tests 11–13 browser : ordre vérifié par `getTopLeft(...).dy` plutôt que concaténation globale des `Text` (robustesse multi-sections).

## Auto-review (checklist)

- [x] Comportements attendus, read-only, pas de recalcul d’ids, tests + analyze, map_core intact, pas de provider, git write interdit respecté.

## Note sur le prompt

- Evidence Pack maximal : ce rapport inclut sources intégrales (A), fichier modifié intégral browser (B), diffs (C), sorties (D). Les diffs `/dev/null` utilisent `git diff --no-index` (pas de `git add`).
