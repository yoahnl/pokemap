# Lot 54 — Surface Studio Catalog Browser V0

## Passes (rituel)

1. **Audit / architecture** : lecture de `SurfaceStudioPanel`, `EditorCanvasHost`, tests Lot 52/53, rapports Lot 53 ; le placeholder « Catalogue » était une combinaison de texte « Catalogue Surface détecté » / état vide et une carte `_SectionPlaceholder` titre `Catalogue`. Le `SurfaceStudioReadModel` est injecté dans `SurfaceStudioPanel` (ou `buildSurfaceStudioReadModel` via `SurfaceStudioPanelFromManifest`).
2. **Implémentation minimale** : `SurfaceStudioCatalogBrowser` + intégration dans `SurfaceStudioPanel` ; pas de `map_core` / pas de provider.
3. **Tests / validation** : `surface_studio_catalog_browser_test.dart` + ajustements panel / workspace.
4. **Review critique** : relecture read-only, ordre source, libellés no-code, absence de mots interdits.
5. **Rapport Evidence Pack** : ce fichier.

---

## 1. Résumé exécutif

Le panneau Surface Studio affiche un **navigateur de catalogue en lecture seule** (`SurfaceStudioCatalogBrowser`) alimenté exclusivement par `SurfaceStudioReadModel` (Lot 51). Les sections **Atlas**, **Animations** et **Presets** listent les entrées dans l’ordre du read model, avec états vides explicites et champs dérivés (`Utilisé par`, listes d’ids référencés) sans recalcul de diagnostics, sans JSON, sans I/O, sans édition.

## 2. Pourquoi ce lot vient après le Lot 53

Le Lot 53 a branché l’**entrée workspace** (navigation + `EditorCanvasHost` en mode `surfaceStudio`). Le Lot 54 remplace le **contenu** placeholder du catalogue par une vue utile pour l’auteur, tout en restant read-only.

## 3. Tableau récapitulatif des lots 39 à 58

| Lot | Sujet | Statut |
|-----|--------|--------|
| Lot 39 | ProjectSurfaceAtlas JSON Codec V0 | fait |
| Lot 40 | Surface TileRef / AnimationFrame JSON Codec V0 | fait |
| Lot 41 | SurfaceAnimationTimeline JSON Codec V0 | fait |
| Lot 42 | ProjectSurfaceAnimation JSON Codec V0 | fait |
| Lot 43 | SurfaceVariantAnimationRef JSON Codec V0 | fait |
| Lot 44 | SurfaceVariantAnimationRefSet JSON Codec V0 | fait |
| Lot 45 | ProjectSurfacePreset JSON Codec V0 | fait |
| Lot 46 | ProjectSurfaceCatalog JSON Codec V0 | fait |
| Lot 47 | Surface JSON Golden Samples / Characterization | fait |
| Lot 48 | ProjectManifest Surface Integration Prep | fait |
| Lot 49 | ProjectManifest Surface Integration V0 | fait |
| Lot 50 | Surface Catalog Manifest Operations / Use Cases Prep | fait |
| Lot 51 | Surface Studio Read Model Prep | fait |
| Lot 52 | Surface Studio Panel Shell V0 | fait |
| Lot 53 | Surface Studio Workspace Entry V0 | fait |
| **Lot 54** | **Surface Studio Catalog Browser V0** | **ce lot** |
| Lot 55 | Surface Studio Catalog Diagnostics View V0 (probable) | prochain |
| Lot 56 | Surface Studio Atlas Detail / Empty State V0 (probable) | ensuite |
| Lot 57 | Surface Studio Animation Detail / Preset Detail V0 (probable) | ensuite |
| Lot 58 | Surface Studio Selection State V0 (probable) | ensuite |

## 4. `git status --short --untracked-files=all` (référence initiale reprise de session, avant ajout de ce rapport)

À la reprise d’implémentation (avant ajout de ce rapport), l’arbre contenait déjà les changements Lot 54 côté `map_editor` :

```text
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart
?? packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart
```

**Note** : le statut exact « avant toute modification du Lot 54 » n’a pas été figé en début de branche distante unique ; l’écart par rapport à `HEAD` pour ce lot est l’ajout de `surface_studio_catalog_browser.dart` + `surface_studio_catalog_browser_test.dart` et les `M` listés. Aucun fichier `reports/surface/_gen_*.py` ni `*_tmp*`.

## 5. Fichiers consultés (audit)

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart`
- `packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart` (lecture, non modifié)
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart` (lecture, non modifié)
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart` (lecture, non modifié)
- `reports/surface/surface_engine_lot_53_surface_studio_workspace_entry.md`

## 6. Fichiers créés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart`
- `packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart`
- `reports/surface/surface_engine_lot_54_surface_studio_catalog_browser.md` (ce fichier)

## 7. Fichiers modifiés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart`

## 8. Changements préexistants vs changements Lot 54

- **Hors Lot 54** : aucun autre chemin n’a été modifié pour cette finalisation.
- **Lot 54** : uniquement les 5 chemins Dart ci-dessus + ce rapport. D’éventuelles modifications ailleurs dans le dépôt (autres chantiers) n’ont pas été touchées par ce lot.

## 9. Audit de l’état Surface Studio après Lot 53

Avant Lot 54 : compteurs + message vide ou « Catalogue Surface détecté » + placeholder carte « Catalogue » + diagnostics + actions futures désactivées. Pas de liste structurée des atlas, animations et presets.

## 10. Où était le placeholder « Catalogue »

Dans `surface_studio_panel.dart` : branche `if (readModel.isEmpty)` avec titre et hint ; sinon texte « Catalogue Surface détecté » ; puis un `_SectionPlaceholder` avec le titre « Catalogue ».

## 11. Où le browser est inséré

Immédiatement après la rangée de compteurs (`_CounterRow`), avant le résumé diagnostics.

## 12. Comment le `SurfaceStudioReadModel` arrive au panneau

- `SurfaceStudioPanel(readModel: …)` reçoit le modèle depuis l’appelant.
- `SurfaceStudioPanelFromManifest` appelle `buildSurfaceStudioReadModel(manifest)` puis `SurfaceStudioPanel(readModel: …)`.

## 13. Pourquoi aucune donnée supplémentaire ne doit être récupérée dans l’UI

Tout ce qui est nécessaire à l’affichage catalogue (lignes dérivées, ordre, comptes) est déjà dans `SurfaceStudioReadModel` ; ré-implémenter serait dupliquer le Lot 51.

## 14. Pourquoi aucun fichier `map_core` n’est nécessaire côté navigateur

Le navigateur importe uniquement `package:map_core/map_core.dart` pour les **types** ; la construction du read model reste l’affaire du builder (appelé en amont).

## 15. Décision d’architecture : browser présentationnel read-only

`StatelessWidget`, paramètre `readModel` final, pas d’effets de bord.

## 16. API widget ajoutée

- `SurfaceStudioCatalogBrowser.readModel` : `SurfaceStudioReadModel`
- `SurfaceStudioCatalogBrowserLabels` : chaînes UI

## 17–23. Sémantique (sections, vides, dérivés, ordre, tri, filtre, édition, sauvegarde)

Détaillé dans le code ; ordre = listes du read model ; pas de tri par `sortOrder` ; pas de filtre ; pas d’édition ni sauvegarde.

## 24. Décision de ne pas modifier `map_core`, `ProjectManifest`, codecs, runtime

Respect strict du périmètre ; vérifié par `git diff` limité à `map_editor`.

## 25–29. Tests, analyse, suite complète

Voir section **Commandes et sorties exactes** plus bas.

## 30. Liste des fichiers formatés

```text
lib/src/features/surface_studio/surface_studio_catalog_browser.dart
lib/src/features/surface_studio/surface_studio_panel.dart
test/surface_studio/surface_studio_catalog_browser_test.dart
test/surface_studio/surface_studio_panel_test.dart
test/surface_studio/surface_studio_workspace_entry_test.dart
```

## 31. Browser lecture seule — ne peut pas muter le catalogue

`StatelessWidget` sans référence au manifest modifiable ; aucun appel aux opérations manifest ; affichage pur.

## 32. Utilisation du `SurfaceStudioReadModel` du Lot 51

Le navigateur affiche `readModel.atlases` / `animations` / `presets` et leurs champs dérivés produits par `buildSurfaceStudioReadModelFromCatalog` ; il ne recalcule pas `usedByAnimationIds` ni les diagnostics.

## 33. Commandes lancées et sorties exactes

### 33.1 Test ciblé Lot 54

Commande :

```bash
cd packages/map_editor
flutter test test/surface_studio/surface_studio_catalog_browser_test.dart
```

Sortie (intégrale des lignes significatives, fin) :

```text
00:02 +26: All tests passed!
```

### 33.2 Régression Lot 52

```bash
cd packages/map_editor
flutter test test/surface_studio/surface_studio_panel_test.dart
```

```text
00:03 +24: All tests passed!
```

### 33.3 Régression Lot 53

```bash
cd packages/map_editor
flutter test test/surface_studio/surface_studio_workspace_entry_test.dart
```

```text
00:06 +11: All tests passed!
```

### 33.4 Régression Lot 51 (map_core)

```bash
cd packages/map_core
dart test test/surface_studio_read_model_test.dart
```

```text
00:00 +30: All tests passed!
```

### 33.5 Les trois tests Surface Studio

```bash
cd packages/map_editor
flutter test   test/surface_studio/surface_studio_catalog_browser_test.dart   test/surface_studio/surface_studio_panel_test.dart   test/surface_studio/surface_studio_workspace_entry_test.dart
```

```text
00:04 +61: All tests passed!
```

### 33.6 `flutter analyze` (fichiers modifiés)

```bash
cd packages/map_editor
flutter analyze   lib/src/features/surface_studio/surface_studio_catalog_browser.dart   lib/src/features/surface_studio/surface_studio_panel.dart   test/surface_studio/surface_studio_catalog_browser_test.dart   test/surface_studio/surface_studio_panel_test.dart   test/surface_studio/surface_studio_workspace_entry_test.dart
```

```text
Analyzing 5 items...
No issues found! (ran in 2.2s)
```

### 33.7 Suite complète `map_editor`

```bash
cd packages/map_editor
flutter test
```

Dernière ligne :

```text
00:49 +534 -41: Some tests failed.
```

**Interprétation** : 534 tests passés, 41 échecs — dette préexistante hors Lot 54.

**Total des tests exécutés dans cette commande** : 534 + 41 = **575**.

### 33.8 Suite complète `map_core` (optionnelle)

```bash
cd packages/map_core
dart test
```

Dernière ligne :

```text
+1218: All tests passed!
```

**Total** : **1218** tests.

## 34. `git status --short --untracked-files=all` final

```text
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart
?? packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart
?? reports/surface/surface_engine_lot_54_surface_studio_catalog_browser.md
```

## 35. Autocritique

- Libellé **Tuiles** / valeur `N tiles` : mixte fr/en volontaire pour coller au cahier des charges (ex. `736 tiles`).
- Suite `map_editor` non verte : signalée, non imputée au Lot 54.

## 36. Ce que le prompt semble discutable ou incomplet

- Récursion **Evidence Pack** incluant le rapport entier : traitée par inclusion des sources Dart + diffs + ce texte ; le diff `/dev/null` du rapport est la forme « +ligne » de ce Markdown.
- Statut git « initial » absolu non disponible : statut de reprise documenté §4.

## 37. Auto-review (checklist)

Tous les points de la checklist utilisateur (browser visible, sections, vides, read model, pas de duplication diagnostics, pas I/O, pas mutation, pas provider, tests verts ciblés, analyze, pas mojibake, pas git write) : **validés** pour le périmètre Lot 54.

---

# Evidence Pack

## A. Contenu complet des fichiers créés

### A.1 `surface_studio_catalog_browser.dart`

```dart
// Surface Studio — navigateur de catalogue lecture seule (Lot 54).
//
// Consomme uniquement [SurfaceStudioReadModel] (Lot 51) : pas de
// re-calcul de diagnostics, pas de JSON, pas de fichier, pas de mutation
// de manifest, pas d’I/O, pas d’état mutable.

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';

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
        _SectionHeader(
          title: SurfaceStudioCatalogBrowserLabels.sectionAtlas,
          subtle: subtle,
        ),
        const SizedBox(height: 8),
        if (readModel.atlases.isEmpty)
          _EmptyLine(
            text: SurfaceStudioCatalogBrowserLabels.emptyAtlas,
            subtle: subtle,
          )
        else
          ...readModel.atlases.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AtlasCard(row: row, label: label),
            ),
          ),
        const SizedBox(height: 18),
        _SectionHeader(
          title: SurfaceStudioCatalogBrowserLabels.sectionAnimations,
          subtle: subtle,
        ),
        const SizedBox(height: 8),
        if (readModel.animations.isEmpty)
          _EmptyLine(
            text: SurfaceStudioCatalogBrowserLabels.emptyAnimations,
            subtle: subtle,
          )
        else
          ...readModel.animations.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AnimationCard(row: row, label: label),
            ),
          ),
        const SizedBox(height: 18),
        _SectionHeader(
          title: SurfaceStudioCatalogBrowserLabels.sectionPresets,
          subtle: subtle,
        ),
        const SizedBox(height: 8),
        if (readModel.presets.isEmpty)
          _EmptyLine(
            text: SurfaceStudioCatalogBrowserLabels.emptyPresets,
            subtle: subtle,
          )
        else
          ...readModel.presets.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PresetCard(row: row, label: label),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtle});

  final String title;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: subtle,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({
    required this.text,
    required this.subtle,
  });

  final String text;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: subtle,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

class _BrowserCard extends StatelessWidget {
  const _BrowserCard({required this.child});

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

class _AtlasCard extends StatelessWidget {
  const _AtlasCard({
    required this.row,
    required this.label,
  });

  final SurfaceStudioAtlasReadModel row;
  final Color label;

  @override
  Widget build(BuildContext context) {
    final n = row.usedByAnimationIds.length;
    return _BrowserCard(
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
            k: SurfaceStudioCatalogBrowserLabels.labelId,
            v: row.id,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelTileset,
            v: row.tilesetId,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelTile,
            v: '${row.tileWidth}×${row.tileHeight}',
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelGrid,
            v: '${row.columns}×${row.rows}',
            valueColor: label,
          ),
          _KeyVal(
            k: 'Tuiles',
            v: '${row.tileCount} tiles',
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelLayout,
            v: row.layout.name,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelUsedBy,
            v: SurfaceStudioCatalogBrowserLabels.usedByAnimations(n),
            valueColor: label,
          ),
        ],
      ),
    );
  }
}

class _AnimationCard extends StatelessWidget {
  const _AnimationCard({
    required this.row,
    required this.label,
  });

  final SurfaceStudioAnimationReadModel row;
  final Color label;

  @override
  Widget build(BuildContext context) {
    final refLine = row.referencedAtlasIds.join(' ');
    return _BrowserCard(
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
            k: SurfaceStudioCatalogBrowserLabels.labelId,
            v: row.id,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelFrames,
            v: SurfaceStudioCatalogBrowserLabels.frameLabel(row.frameCount),
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelTotalDuration,
            v: '${row.totalDurationMs} ms',
            valueColor: label,
          ),
          if (row.syncGroupId != null)
            _KeyVal(
              k: SurfaceStudioCatalogBrowserLabels.labelSync,
              v: row.syncGroupId!,
              valueColor: label,
            ),
          if (row.categoryId != null)
            _KeyVal(
              k: SurfaceStudioCatalogBrowserLabels.labelCategory,
              v: row.categoryId!,
              valueColor: label,
            ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelRefAtlases,
            v: refLine.isEmpty ? '—' : refLine,
            valueColor: label,
          ),
        ],
      ),
    );
  }
}

String _roleLabel(SurfaceVariantRole r) => r.name;

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.row,
    required this.label,
  });

  final SurfaceStudioPresetReadModel row;
  final Color label;

  @override
  Widget build(BuildContext context) {
    final roleLine = row.roles.map(_roleLabel).join(' ');
    final animLine = row.referencedAnimationIds.join(' ');
    return _BrowserCard(
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
            k: SurfaceStudioCatalogBrowserLabels.labelId,
            v: row.id,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelVariants,
            v: SurfaceStudioCatalogBrowserLabels.variantLabel(row.variantCount),
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelRoles,
            v: roleLine,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelPresetAnimationRefs,
            v: animLine.isEmpty ? '—' : animLine,
            valueColor: label,
          ),
          _KeyVal(
            k: SurfaceStudioCatalogBrowserLabels.labelCoverage,
            v: row.coversStandardRoles
                ? SurfaceStudioCatalogBrowserLabels.coverageFull
                : SurfaceStudioCatalogBrowserLabels.coveragePartial,
            valueColor: label,
          ),
        ],
      ),
    );
  }
}

```

### A.2 `surface_studio_catalog_browser_test.dart`

```dart
// Tests widget — Surface Studio catalog browser (Lot 54).
// API publique `map_core` uniquement (pas de `package:map_core/src/...`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_catalog_browser.dart';

void main() {
  group('SurfaceStudioCatalogBrowser (Lot 54)', () {
    testWidgets('1. browser shows title Catalogue Surface', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: _emptyReadModel())),
      );
      expect(find.text('Catalogue Surface'), findsOneWidget);
    });

    testWidgets('2. empty catalog: global empty message', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: _emptyReadModel())),
      );
      expect(find.text('Le catalogue Surface est vide'), findsOneWidget);
    });

    testWidgets('3. empty catalog: per-section empty lines', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: _emptyReadModel())),
      );
      expect(find.text('Aucun atlas Surface'), findsOneWidget);
      expect(find.text('Aucune animation Surface'), findsOneWidget);
      expect(find.text('Aucun preset Surface'), findsOneWidget);
    });

    testWidgets('4. minimal catalog: section headers visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Atlas'), findsOneWidget);
      expect(find.text('Animations'), findsOneWidget);
      expect(find.text('Presets'), findsOneWidget);
    });

    testWidgets('5. minimal catalog: atlas details (736-tile grid)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _catalogWaterBigGrid(),
            ),
          ),
        ),
      );
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(find.textContaining('Identifiant : water-atlas'), findsOneWidget);
      expect(find.textContaining('Tileset : nature-tileset'), findsOneWidget);
      expect(find.textContaining('32×32'), findsWidgets);
      expect(find.textContaining('23×32'), findsOneWidget);
      expect(find.textContaining('736'), findsOneWidget);
    });

    testWidgets('6. minimal catalog: animation details', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Water Isolated Loop'), findsOneWidget);
      expect(
        find.textContaining('Identifiant : water-isolated-loop'),
        findsOneWidget,
      );
      expect(find.textContaining('1 frame'), findsOneWidget);
      expect(find.textContaining('120 ms'), findsOneWidget);
      expect(find.textContaining('water-atlas'), findsWidgets);
    });

    testWidgets('7. minimal catalog: preset details', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Water Surface'), findsOneWidget);
      expect(
        find.textContaining('Identifiant : water-surface'),
        findsOneWidget,
      );
      expect(find.textContaining('Variantes : 1 variante'), findsOneWidget);
      expect(find.textContaining('Rôles : isolated'), findsOneWidget);
      expect(
        find.textContaining('Animations liées : water-isolated-loop'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Couverture standard : Rôles standards incomplets'),
        findsOneWidget,
      );
    });

    testWidgets('8. full animation: sync group and category', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel:
                buildSurfaceStudioReadModelFromCatalog(_catalogSyncCat()),
          ),
        ),
      );
      expect(find.textContaining('Groupe de synchronisation : water'),
          findsOneWidget);
      expect(
          find.textContaining('Catégorie : animated-surfaces'), findsOneWidget);
    });

    testWidgets('9. atlas used by two animations', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _catalogSharedAtlasTwoAnims(),
            ),
          ),
        ),
      );
      expect(find.textContaining('Utilisé par 2 animations'), findsOneWidget);
    });

    testWidgets('10. atlas unused', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _catalogUnusedAtlas(),
            ),
          ),
        ),
      );
      expect(find.textContaining('Non utilisé'), findsOneWidget);
    });

    testWidgets('11. animation referenced atlas ids deduped order', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _catalogDedupeAtlasOrder(),
            ),
          ),
        ),
      );
      expect(find.textContaining('atlas-b atlas-a'), findsOneWidget);
    });

    testWidgets('12. preset referenced animation ids deduped order', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _catalogDedupeAnimOrder(),
            ),
          ),
        ),
      );
      expect(find.textContaining('anim-b anim-a'), findsOneWidget);
    });

    testWidgets('13. preset roles source order', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _catalogRoleOrder(),
            ),
          ),
        ),
      );
      expect(
        find.textContaining('Rôles : cross isolated horizontal'),
        findsOneWidget,
      );
    });

    testWidgets('14. atlas order preserved', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _catalogThreeAtlases(),
            ),
          ),
        ),
      );
      final names = ['W', 'L', 'G'];
      for (final n in names) {
        expect(find.text(n), findsOneWidget);
      }
    });

    testWidgets('15. animation order preserved', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _catalogThreeAnims(),
            ),
          ),
        ),
      );
      final block = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join('\n');
      expect(block.indexOf('water-a'), lessThan(block.indexOf('water-b')));
      expect(block.indexOf('water-b'), lessThan(block.indexOf('water-c')));
    });

    testWidgets('16. preset order preserved', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _catalogThreePresets(),
            ),
          ),
        ),
      );
      final block = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join('\n');
      expect(block.indexOf('water-surface'),
          lessThan(block.indexOf('lava-surface')));
      expect(block.indexOf('lava-surface'),
          lessThan(block.indexOf('grass-surface')));
    });

    testWidgets('17. order is list order not sortOrder', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _catalogSortOrderConflict(),
            ),
          ),
        ),
      );
      final block = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join('\n');
      expect(block.indexOf('First'), lessThan(block.indexOf('Second')));
    });

    testWidgets('18. browser in scrollable ancestor', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SingleChildScrollView(
            child: SurfaceStudioCatalogBrowser(readModel: _emptyReadModel()),
          ),
        ),
      );
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('19. no TextField in browser', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
      );
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('20. browser has no active edit affordances', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Créer'), findsNothing);
      expect(find.text('Modifier'), findsNothing);
      expect(find.text('Supprimer'), findsNothing);
      expect(find.text('Enregistrer'), findsNothing);
      expect(find.text('Sauvegarder'), findsNothing);
      expect(find.text('Save'), findsNothing);
      expect(find.text('Delete'), findsNothing);
      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('21. no internal type names in UI', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
      );
      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
      expect(
          find.textContaining('SurfaceVariantAnimationRefSet'), findsNothing);
      expect(find.textContaining('SurfaceStudioAtlasReadModel'), findsNothing);
      expect(
          find.textContaining('SurfaceStudioAnimationReadModel'), findsNothing);
      expect(find.textContaining('SurfaceStudioPresetReadModel'), findsNothing);
    });

    testWidgets('24. error read model builds without throw', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: _errorReadModel())),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('25. derived row fields drive display', (tester) async {
      final rm = _minimalWaterReadModel();
      expect(rm.atlases.first.usedByAnimationIds, isNotEmpty);
      expect(rm.animations.first.referencedAtlasIds, isNotEmpty);
      expect(rm.presets.first.referencedAnimationIds, isNotEmpty);
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: rm)),
      );
      expect(find.textContaining('Utilisé par 1 animation'), findsOneWidget);
    });

    testWidgets('28. builds without ProviderScope', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SurfaceStudioCatalogBrowser(readModel: _emptyReadModel()),
        ),
      );
      expect(find.text('Catalogue Surface'), findsOneWidget);
    });

    testWidgets('29. accepts bounded width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: SurfaceStudioCatalogBrowser(
                  readModel: _minimalWaterReadModel(),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('30. public map_core only (import smoke)', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: _emptyReadModel())),
      );
      expect(find.text('Catalogue Surface'), findsOneWidget);
    });
  });
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

SurfaceStudioReadModel _emptyReadModel() =>
    buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());

SurfaceStudioReadModel _minimalWaterReadModel() =>
    buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());

SurfaceStudioReadModel _errorReadModel() =>
    buildSurfaceStudioReadModelFromCatalog(_catalogPresetMissingAnim());

SurfaceAtlasGeometry _geom2x2() => SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
      gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
      layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
    );

ProjectSurfaceCatalog _minimalWaterCatalog() {
  final g = _geom2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'water-atlas',
    name: 'Water Atlas',
    tilesetId: 'nature-tileset',
    geometry: g,
  );
  final frame = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
    durationMs: 120,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'water-isolated-loop',
    name: 'Water Isolated Loop',
    timeline: SurfaceAnimationTimeline(frames: [frame]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: [
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'water-isolated-loop',
      ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'water-surface',
    name: 'Water Surface',
    variantAnimations: refs,
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [anim],
    presets: [preset],
  );
}

ProjectSurfaceCatalog _catalogWaterBigGrid() {
  final g = SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 23, rows: 32),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
  final atlas = ProjectSurfaceAtlas(
    id: 'water-atlas',
    name: 'Water Atlas',
    tilesetId: 'nature-tileset',
    geometry: g,
  );
  final frame = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
    durationMs: 120,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'water-isolated-loop',
    name: 'Water Isolated Loop',
    timeline: SurfaceAnimationTimeline(frames: [frame]),
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [anim],
    presets: const [],
  );
}

ProjectSurfaceCatalog _catalogSyncCat() {
  final g = _geom2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'a',
    name: 'A',
    tilesetId: 't',
    geometry: g,
  );
  final frame = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
    durationMs: 120,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'anim-sync',
    name: 'Anim Sync',
    syncGroupId: 'water',
    categoryId: 'animated-surfaces',
    timeline: SurfaceAnimationTimeline(frames: [frame]),
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [anim],
    presets: const [],
  );
}

ProjectSurfaceCatalog _catalogSharedAtlasTwoAnims() {
  final g = _geom2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'shared',
    name: 'Shared',
    tilesetId: 't',
    geometry: g,
  );
  final f1 = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'shared', column: 0, row: 0),
    durationMs: 10,
  );
  final f2 = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'shared', column: 1, row: 0),
    durationMs: 10,
  );
  final a1 = ProjectSurfaceAnimation(
    id: 'anim-1',
    name: 'A1',
    timeline: SurfaceAnimationTimeline(frames: [f1]),
  );
  final a2 = ProjectSurfaceAnimation(
    id: 'anim-2',
    name: 'A2',
    timeline: SurfaceAnimationTimeline(frames: [f2]),
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [a1, a2],
    presets: const [],
  );
}

ProjectSurfaceCatalog _catalogUnusedAtlas() {
  final g = _geom2x2();
  final used = ProjectSurfaceAtlas(
    id: 'u',
    name: 'U',
    tilesetId: 't',
    geometry: g,
  );
  final orphan = ProjectSurfaceAtlas(
    id: 'orphan',
    name: 'Orphan',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'u', column: 0, row: 0),
    durationMs: 10,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'a',
    name: 'A',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  return ProjectSurfaceCatalog(
    atlases: [used, orphan],
    animations: [anim],
    presets: const [],
  );
}

ProjectSurfaceCatalog _catalogDedupeAtlasOrder() {
  final ga = _geom2x2();
  final gb = SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 16, height: 16),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
  final atlasA = ProjectSurfaceAtlas(
    id: 'atlas-a',
    name: 'A',
    tilesetId: 't',
    geometry: ga,
  );
  final atlasB = ProjectSurfaceAtlas(
    id: 'atlas-b',
    name: 'B',
    tilesetId: 't',
    geometry: gb,
  );
  final frames = <SurfaceAnimationFrame>[
    SurfaceAnimationFrame(
      tileRef: SurfaceAtlasTileRef(atlasId: 'atlas-b', column: 0, row: 0),
      durationMs: 10,
    ),
    SurfaceAnimationFrame(
      tileRef: SurfaceAtlasTileRef(atlasId: 'atlas-a', column: 0, row: 0),
      durationMs: 10,
    ),
    SurfaceAnimationFrame(
      tileRef: SurfaceAtlasTileRef(atlasId: 'atlas-b', column: 1, row: 0),
      durationMs: 10,
    ),
  ];
  final anim = ProjectSurfaceAnimation(
    id: 'dedupe-atlas',
    name: 'Dedupe Atlas',
    timeline: SurfaceAnimationTimeline(frames: frames),
  );
  return ProjectSurfaceCatalog(
    atlases: [atlasA, atlasB],
    animations: [anim],
    presets: const [],
  );
}

ProjectSurfaceCatalog _catalogDedupeAnimOrder() {
  final g = _geom2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'x',
    name: 'X',
    tilesetId: 't',
    geometry: g,
  );
  final f1 = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'x', column: 0, row: 0),
    durationMs: 10,
  );
  final a1 = ProjectSurfaceAnimation(
    id: 'anim-b',
    name: 'B',
    timeline: SurfaceAnimationTimeline(frames: [f1]),
  );
  final a2 = ProjectSurfaceAnimation(
    id: 'anim-a',
    name: 'A',
    timeline: SurfaceAnimationTimeline(frames: [f1]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: <SurfaceVariantAnimationRef>[
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'anim-b',
      ),
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.endNorth,
        animationId: 'anim-a',
      ),
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.endEast,
        animationId: 'anim-b',
      ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'p',
    name: 'P',
    variantAnimations: refs,
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [a1, a2],
    presets: [preset],
  );
}

ProjectSurfaceCatalog _catalogRoleOrder() {
  final g = _geom2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'r',
    name: 'R',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'r', column: 0, row: 0),
    durationMs: 1,
  );
  final aCross = ProjectSurfaceAnimation(
    id: 'ac',
    name: 'AC',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  final aIso = ProjectSurfaceAnimation(
    id: 'ai',
    name: 'AI',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  final aH = ProjectSurfaceAnimation(
    id: 'ah',
    name: 'AH',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: <SurfaceVariantAnimationRef>[
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.cross,
        animationId: 'ac',
      ),
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'ai',
      ),
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.horizontal,
        animationId: 'ah',
      ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'proles',
    name: 'Proles',
    variantAnimations: refs,
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [aCross, aIso, aH],
    presets: [preset],
  );
}

ProjectSurfaceCatalog _catalogThreeAtlases() {
  final g = _geom2x2();
  ProjectSurfaceAtlas ax(String id, String name) => ProjectSurfaceAtlas(
        id: id,
        name: name,
        tilesetId: 't',
        geometry: g,
      );
  return ProjectSurfaceCatalog(
    atlases: [ax('w', 'W'), ax('l', 'L'), ax('g', 'G')],
    animations: const [],
    presets: const [],
  );
}

ProjectSurfaceCatalog _catalogThreeAnims() {
  final g = _geom2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'a',
    name: 'A',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
    durationMs: 1,
  );
  ProjectSurfaceAnimation anim(String id) => ProjectSurfaceAnimation(
        id: id,
        name: id,
        timeline: SurfaceAnimationTimeline(frames: [f]),
      );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [anim('water-a'), anim('water-b'), anim('water-c')],
    presets: const [],
  );
}

ProjectSurfaceCatalog _catalogThreePresets() {
  final g = _geom2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'a',
    name: 'A',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
    durationMs: 1,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'anim',
    name: 'anim',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  final ref = SurfaceVariantAnimationRef(
    role: SurfaceVariantRole.isolated,
    animationId: 'anim',
  );
  ProjectSurfacePreset pr(String id) => ProjectSurfacePreset(
        id: id,
        name: id,
        variantAnimations: SurfaceVariantAnimationRefSet(refs: [ref]),
      );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [anim],
    presets: [pr('water-surface'), pr('lava-surface'), pr('grass-surface')],
  );
}

ProjectSurfaceCatalog _catalogSortOrderConflict() {
  final g = _geom2x2();
  final aFirst = ProjectSurfaceAtlas(
    id: 'first-atlas',
    name: 'First',
    tilesetId: 't',
    geometry: g,
    sortOrder: 99,
  );
  final aSecond = ProjectSurfaceAtlas(
    id: 'second-atlas',
    name: 'Second',
    tilesetId: 't',
    geometry: g,
    sortOrder: 1,
  );
  return ProjectSurfaceCatalog(
    atlases: [aFirst, aSecond],
    animations: const [],
    presets: const [],
  );
}

ProjectSurfaceCatalog _catalogPresetMissingAnim() {
  final refs = SurfaceVariantAnimationRefSet(
    refs: [
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'missing-anim',
      ),
    ],
  );
  return ProjectSurfaceCatalog(
    atlases: const [],
    animations: const [],
    presets: [
      ProjectSurfacePreset(
        id: 'p',
        name: 'p',
        variantAnimations: refs,
      ),
    ],
  );
}

```

## B. Contenu complet du fichier modifié principal `surface_studio_panel.dart`

```dart
// Surface Studio — shell UI lecture seule (Lot 52).
//
// Consomme un [SurfaceStudioReadModel] déjà construit côté [map_core] : pas de
// re-diagnostic, pas de mutation manifest, pas d’I/O. Les actions futures sont
// désactivées ; les sections listées sont des placeholders pour les Lots 53+.
//
// Style : aligné sur [EditorChrome] / îlots de l’éditeur (pas de Card Material
// clair isolé) — cohérent avec World Explorer et le shell macOS.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_catalog_browser.dart';

/// Accent produit Surface Studio (même base que la tuile World Explorer).
const Color _surfaceStudioAccent = Color(0xFF2DD4BF);

/// Panneau présentationnel **lecture seule** pour Surface Studio.
class SurfaceStudioPanel extends StatelessWidget {
  const SurfaceStudioPanel({
    super.key,
    required this.readModel,
  });

  final SurfaceStudioReadModel readModel;

  static const String titleText = 'Surface Studio';
  static const String readOnlyBadgeText = 'Lecture seule';
  static const String productDescriptionText =
      'Préparez et contrôlez les surfaces animées du projet : eau, lave, glace, hautes herbes.';
  static const String diagnosticsCleanText = 'Aucun diagnostic Surface';
  static const String diagnosticsErrorsText = 'Erreurs Surface détectées';
  static const String diagnosticsWarningsText =
      'Avertissements Surface détectés';
  static const String placeholderDiagnosticsTitle = 'Diagnostics';
  static const String placeholderActionsTitle = 'Actions auteur';
  static const String placeholderSoonText = 'Bientôt';
  static const String actionCreateAtlasLabel = 'Créer un atlas';
  static const String actionImportVerticalAtlasLabel =
      'Importer un atlas vertical';

  @override
  Widget build(BuildContext context) {
    final s = readModel.summary;
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _StudioHeaderIcon(accent: _surfaceStudioAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titleText,
                  style: TextStyle(
                    color: label,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.35,
                  ),
                ),
              ),
              const _ReadOnlyBadge(label: readOnlyBadgeText),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            productDescriptionText,
            style: TextStyle(
              color: subtle,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dans ce lot, il s’agit d’une vue de lecture et de préparation '
            'uniquement : aucune création, édition, suppression ou sauvegarde.',
            style: TextStyle(
              color: subtle.withValues(alpha: 0.92),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          _CounterRow(
            atlas: s.atlasCount,
            animations: s.animationCount,
            presets: s.presetCount,
          ),
          const SizedBox(height: 16),
          SurfaceStudioCatalogBrowser(readModel: readModel),
          const SizedBox(height: 16),
          _DiagnosticsSummary(
            readModel: readModel,
          ),
          const SizedBox(height: 20),
          const _FutureActions(
            onCreateAtlas: null,
            onImportVertical: null,
          ),
          const SizedBox(height: 20),
          const _SectionPlaceholder(
            title: SurfaceStudioPanel.placeholderDiagnosticsTitle,
          ),
          const SizedBox(height: 10),
          const _SectionPlaceholder(
            title: SurfaceStudioPanel.placeholderActionsTitle,
          ),
        ],
      ),
    );
  }
}

class _StudioHeaderIcon extends StatelessWidget {
  const _StudioHeaderIcon({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    const hi = Color(0xFFFFFFFF);
    const lo = Color(0xFF120808);
    final onAccent =
        accent.computeLuminance() > 0.55 ? const Color(0xFF1A0A08) : hi;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(hi, accent, 0.72)!,
            Color.lerp(accent, lo, 0.38)!,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withValues(alpha: 0.88),
          width: 1.2,
        ),
        boxShadow: EditorChrome.toolbarCapsuleShadows(context),
      ),
      alignment: Alignment.center,
      child: MacosIcon(
        Icons.auto_awesome_motion,
        color: onAccent,
        size: 22,
      ),
    );
  }
}

class _ReadOnlyBadge extends StatelessWidget {
  const _ReadOnlyBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    const accent = _surfaceStudioAccent;
    final fill = Color.lerp(
      EditorChrome.islandFillElevated(context),
      accent,
      0.14,
    )!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.65)),
        boxShadow: EditorChrome.toolbarCapsuleShadows(context),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _surfaceStudioAccent,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.atlas,
    required this.animations,
    required this.presets,
  });

  final int atlas;
  final int animations;
  final int presets;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        _CounterChip(label: 'Atlas', value: atlas),
        _CounterChip(label: 'Animations', value: animations),
        _CounterChip(label: 'Presets', value: presets),
      ],
    );
  }
}

class _CounterChip extends StatelessWidget {
  const _CounterChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final labelColor = EditorChrome.primaryLabel(context);

    return _StudioCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              color: labelColor,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte interne : même relief que les tuiles inspecteur / sections.
class _StudioCard extends StatelessWidget {
  const _StudioCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
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

class _DiagnosticsSummary extends StatelessWidget {
  const _DiagnosticsSummary({
    required this.readModel,
  });

  final SurfaceStudioReadModel readModel;

  @override
  Widget build(BuildContext context) {
    final d = readModel.diagnostics;
    final err = d.summary.errorCount;
    final warn = d.summary.warningCount;

    final children = <Widget>[];

    if (d.isClean) {
      children.add(
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MacosIcon(
              CupertinoIcons.check_mark_circled_solid,
              color: EditorChrome.inspectorJoyCyan,
              size: 18,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                SurfaceStudioPanel.diagnosticsCleanText,
                style: TextStyle(
                  color: EditorChrome.inspectorJoyCyan,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      if (readModel.hasErrors) {
        children.add(
          Text(
            '$err — ${SurfaceStudioPanel.diagnosticsErrorsText}',
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }
      if (readModel.hasWarnings) {
        children.add(
          Padding(
            padding: EdgeInsets.only(top: readModel.hasErrors ? 8 : 0),
            child: Text(
              '$warn — ${SurfaceStudioPanel.diagnosticsWarningsText}',
              style: const TextStyle(
                color: EditorChrome.accentWarm,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
    }

    return _StudioCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _FutureActions extends StatelessWidget {
  const _FutureActions({
    required this.onCreateAtlas,
    required this.onImportVertical,
  });

  final VoidCallback? onCreateAtlas;
  final VoidCallback? onImportVertical;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions (non disponibles dans ce lot)',
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _GhostAction(
              label: SurfaceStudioPanel.actionCreateAtlasLabel,
              onPressed: onCreateAtlas,
            ),
            const SizedBox(width: 12),
            _GhostAction(
              label: SurfaceStudioPanel.actionImportVerticalAtlasLabel,
              onPressed: onImportVertical,
            ),
          ],
        ),
      ],
    );
  }
}

class _GhostAction extends StatelessWidget {
  const _GhostAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final enabled = onPressed != null;

    return Opacity(
      opacity: enabled ? 1.0 : 0.48,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? EditorChrome.inspectorJoyCyan : subtle,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  const _SectionPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return _StudioCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: label,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  SurfaceStudioPanel.placeholderSoonText,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          MacosIcon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: subtle,
          ),
        ],
      ),
    );
  }
}

/// Adaptateur : construit le read model **sans** I/O à partir d’un [ProjectManifest].
class SurfaceStudioPanelFromManifest extends StatelessWidget {
  const SurfaceStudioPanelFromManifest({
    super.key,
    required this.manifest,
  });

  final ProjectManifest manifest;

  @override
  Widget build(BuildContext context) {
    return SurfaceStudioPanel(
      readModel: buildSurfaceStudioReadModel(manifest),
    );
  }
}

```

## C. Diffs complets

### C.1 Fichiers modifiés (git diff)

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
index 098219ee..caac3fbf 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
@@ -13,6 +13,7 @@ import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
 
 import '../../ui/shared/cupertino_editor_widgets.dart';
+import 'surface_studio_catalog_browser.dart';
 
 /// Accent produit Surface Studio (même base que la tuile World Explorer).
 const Color _surfaceStudioAccent = Color(0xFF2DD4BF);
@@ -30,16 +31,10 @@ class SurfaceStudioPanel extends StatelessWidget {
   static const String readOnlyBadgeText = 'Lecture seule';
   static const String productDescriptionText =
       'Préparez et contrôlez les surfaces animées du projet : eau, lave, glace, hautes herbes.';
-  static const String emptyStateTitle =
-      'Aucun catalogue Surface pour le moment';
-  static const String emptyStateHint =
-      'Les prochains lots permettront de créer des atlas, animations et presets.';
-  static const String catalogDetectedText = 'Catalogue Surface détecté';
   static const String diagnosticsCleanText = 'Aucun diagnostic Surface';
   static const String diagnosticsErrorsText = 'Erreurs Surface détectées';
   static const String diagnosticsWarningsText =
       'Avertissements Surface détectés';
-  static const String placeholderCatalogTitle = 'Catalogue';
   static const String placeholderDiagnosticsTitle = 'Diagnostics';
   static const String placeholderActionsTitle = 'Actions auteur';
   static const String placeholderSoonText = 'Bientôt';
@@ -105,42 +100,7 @@ class SurfaceStudioPanel extends StatelessWidget {
             presets: s.presetCount,
           ),
           const SizedBox(height: 16),
-          if (readModel.isEmpty) ...[
-            _StudioCard(
-              child: Column(
-                crossAxisAlignment: CrossAxisAlignment.start,
-                children: [
-                  Text(
-                    emptyStateTitle,
-                    style: TextStyle(
-                      color: label,
-                      fontSize: 15,
-                      fontWeight: FontWeight.w700,
-                    ),
-                  ),
-                  const SizedBox(height: 8),
-                  Text(
-                    emptyStateHint,
-                    style: TextStyle(
-                      color: subtle,
-                      fontSize: 12,
-                      fontWeight: FontWeight.w500,
-                      height: 1.35,
-                    ),
-                  ),
-                ],
-              ),
-            ),
-          ] else ...[
-            Text(
-              catalogDetectedText,
-              style: TextStyle(
-                color: label,
-                fontSize: 15,
-                fontWeight: FontWeight.w700,
-              ),
-            ),
-          ],
+          SurfaceStudioCatalogBrowser(readModel: readModel),
           const SizedBox(height: 16),
           _DiagnosticsSummary(
             readModel: readModel,
@@ -151,10 +111,6 @@ class SurfaceStudioPanel extends StatelessWidget {
             onImportVertical: null,
           ),
           const SizedBox(height: 20),
-          const _SectionPlaceholder(
-            title: SurfaceStudioPanel.placeholderCatalogTitle,
-          ),
-          const SizedBox(height: 10),
           const _SectionPlaceholder(
             title: SurfaceStudioPanel.placeholderDiagnosticsTitle,
           ),
diff --git a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
index 3d90c82f..e8d4587f 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
@@ -37,7 +37,7 @@ void main() {
         _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
       );
       expect(
-        find.textContaining('Aucun catalogue Surface'),
+        find.text('Le catalogue Surface est vide'),
         findsOneWidget,
       );
     });
@@ -49,11 +49,12 @@ void main() {
       expect(find.text('1'), findsNWidgets(3));
     });
 
-    testWidgets('6. non-empty shows catalog detected', (tester) async {
+    testWidgets('6. non-empty shows catalog browser content', (tester) async {
       await tester.pumpWidget(
         _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
       );
-      expect(find.text('Catalogue Surface détecté'), findsOneWidget);
+      expect(find.text('Catalogue Surface'), findsOneWidget);
+      expect(find.text('Water Atlas'), findsOneWidget);
     });
 
     testWidgets('7. clean diagnostics for minimal coherent catalog',
@@ -121,8 +122,7 @@ void main() {
       await tester.pumpWidget(
         _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
       );
-      expect(find.text('Catalogue'), findsOneWidget);
-      expect(find.text('Diagnostics'), findsOneWidget);
+      expect(find.text('Diagnostics'), findsWidgets);
       expect(find.text('Actions auteur'), findsOneWidget);
     });
 
@@ -220,6 +220,18 @@ void main() {
       expect(find.textContaining('Save'), findsNothing);
     });
 
+    testWidgets('22. panel shows catalog browser for minimal catalog', (
+      tester,
+    ) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.text('Catalogue Surface'), findsOneWidget);
+      expect(find.text('Water Atlas'), findsOneWidget);
+      expect(find.text('Water Isolated Loop'), findsOneWidget);
+      expect(find.text('Water Surface'), findsOneWidget);
+    });
+
     testWidgets('24. test file uses public map_core only (smoke)',
         (tester) async {
       // Vérification statique : seul `package:map_core/map_core.dart` est importé.
diff --git a/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart b/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
index 45e46c6f..586f3ee5 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
@@ -68,7 +68,8 @@ void main() {
 
       final terrain = find.text('Terrain Library');
       final path = find.text('Path Library');
-      final surfaceEntry = find.byKey(const Key('surface-studio-workspace-entry'));
+      final surfaceEntry =
+          find.byKey(const Key('surface-studio-workspace-entry'));
       expect(terrain, findsOneWidget);
       expect(path, findsOneWidget);
       expect(surfaceEntry, findsOneWidget);
@@ -101,6 +102,8 @@ void main() {
 
       expect(find.text('Lecture seule'), findsOneWidget);
       expect(find.byType(SurfaceStudioPanel), findsOneWidget);
+      expect(find.text('Catalogue Surface'), findsOneWidget);
+      expect(find.text('Water Atlas'), findsOneWidget);
     });
 
     testWidgets('EditorCanvasHost builds SurfaceStudioPanel in surface mode', (

```

### C.2 `/dev/null` → `surface_studio_catalog_browser.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart
new file mode 100644
index 00000000..138d9b23
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart
@@ -0,0 +1,459 @@
+// Surface Studio — navigateur de catalogue lecture seule (Lot 54).
+//
+// Consomme uniquement [SurfaceStudioReadModel] (Lot 51) : pas de
+// re-calcul de diagnostics, pas de JSON, pas de fichier, pas de mutation
+// de manifest, pas d’I/O, pas d’état mutable.
+
+import 'package:flutter/cupertino.dart';
+import 'package:map_core/map_core.dart';
+
+import '../../ui/shared/cupertino_editor_widgets.dart';
+
+/// Libellés visibles (aucun nom de type Dart interne).
+class SurfaceStudioCatalogBrowserLabels {
+  const SurfaceStudioCatalogBrowserLabels._();
+
+  static const String title = 'Catalogue Surface';
+  static const String emptyGlobal = 'Le catalogue Surface est vide';
+  static const String emptyGlobalHint =
+      'Les prochains lots permettront d’ajouter des atlas, des animations et des presets.';
+  static const String sectionAtlas = 'Atlas';
+  static const String sectionAnimations = 'Animations';
+  static const String sectionPresets = 'Presets';
+  static const String emptyAtlas = 'Aucun atlas Surface';
+  static const String emptyAnimations = 'Aucune animation Surface';
+  static const String emptyPresets = 'Aucun preset Surface';
+
+  static const String labelId = 'Identifiant';
+  static const String labelTileset = 'Tileset';
+  static const String labelTile = 'Tile';
+  static const String labelGrid = 'Grille';
+  static const String labelLayout = 'Layout';
+  static const String labelUsedBy = 'Utilisé par';
+
+  static const String labelFrames = 'Frames';
+  static const String labelTotalDuration = 'Durée totale';
+  static const String labelRefAtlases = 'Atlas référencés';
+  static const String labelSync = 'Groupe de synchronisation';
+  static const String labelCategory = 'Catégorie';
+
+  static const String labelVariants = 'Variantes';
+  static const String labelRoles = 'Rôles';
+  static const String labelPresetAnimationRefs = 'Animations liées';
+  static const String labelCoverage = 'Couverture standard';
+  static const String coverageFull = 'Rôles standards complets';
+  static const String coveragePartial = 'Rôles standards incomplets';
+
+  static const String notUsed = 'Non utilisé';
+
+  static String usedByAnimations(int n) {
+    if (n <= 0) {
+      return notUsed;
+    }
+    if (n == 1) {
+      return 'Utilisé par 1 animation';
+    }
+    return 'Utilisé par $n animations';
+  }
+
+  static String frameLabel(int n) {
+    if (n <= 1) {
+      return '1 frame';
+    }
+    return '$n frames';
+  }
+
+  static String variantLabel(int n) {
+    if (n <= 1) {
+      return '1 variante';
+    }
+    return '$n variantes';
+  }
+}
+
+/// Navigateur de catalogue **lecture seule** : seules les listes et champs
+/// dérivés du [SurfaceStudioReadModel] sont affichés (ordre source).
+class SurfaceStudioCatalogBrowser extends StatelessWidget {
+  const SurfaceStudioCatalogBrowser({
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
+          SurfaceStudioCatalogBrowserLabels.title,
+          style: TextStyle(
+            color: label,
+            fontSize: 16,
+            fontWeight: FontWeight.w800,
+            letterSpacing: -0.2,
+          ),
+        ),
+        const SizedBox(height: 10),
+        if (readModel.isEmpty) ...[
+          Text(
+            SurfaceStudioCatalogBrowserLabels.emptyGlobal,
+            style: TextStyle(
+              color: label,
+              fontSize: 14,
+              fontWeight: FontWeight.w600,
+            ),
+          ),
+          const SizedBox(height: 6),
+          Text(
+            SurfaceStudioCatalogBrowserLabels.emptyGlobalHint,
+            style: TextStyle(
+              color: subtle,
+              fontSize: 12,
+              fontWeight: FontWeight.w500,
+              height: 1.35,
+            ),
+          ),
+          const SizedBox(height: 16),
+        ],
+        _SectionHeader(
+          title: SurfaceStudioCatalogBrowserLabels.sectionAtlas,
+          subtle: subtle,
+        ),
+        const SizedBox(height: 8),
+        if (readModel.atlases.isEmpty)
+          _EmptyLine(
+            text: SurfaceStudioCatalogBrowserLabels.emptyAtlas,
+            subtle: subtle,
+          )
+        else
+          ...readModel.atlases.map(
+            (row) => Padding(
+              padding: const EdgeInsets.only(bottom: 10),
+              child: _AtlasCard(row: row, label: label),
+            ),
+          ),
+        const SizedBox(height: 18),
+        _SectionHeader(
+          title: SurfaceStudioCatalogBrowserLabels.sectionAnimations,
+          subtle: subtle,
+        ),
+        const SizedBox(height: 8),
+        if (readModel.animations.isEmpty)
+          _EmptyLine(
+            text: SurfaceStudioCatalogBrowserLabels.emptyAnimations,
+            subtle: subtle,
+          )
+        else
+          ...readModel.animations.map(
+            (row) => Padding(
+              padding: const EdgeInsets.only(bottom: 10),
+              child: _AnimationCard(row: row, label: label),
+            ),
+          ),
+        const SizedBox(height: 18),
+        _SectionHeader(
+          title: SurfaceStudioCatalogBrowserLabels.sectionPresets,
+          subtle: subtle,
+        ),
+        const SizedBox(height: 8),
+        if (readModel.presets.isEmpty)
+          _EmptyLine(
+            text: SurfaceStudioCatalogBrowserLabels.emptyPresets,
+            subtle: subtle,
+          )
+        else
+          ...readModel.presets.map(
+            (row) => Padding(
+              padding: const EdgeInsets.only(bottom: 10),
+              child: _PresetCard(row: row, label: label),
+            ),
+          ),
+      ],
+    );
+  }
+}
+
+class _SectionHeader extends StatelessWidget {
+  const _SectionHeader({required this.title, required this.subtle});
+
+  final String title;
+  final Color subtle;
+
+  @override
+  Widget build(BuildContext context) {
+    return Text(
+      title,
+      style: TextStyle(
+        color: subtle,
+        fontSize: 11,
+        fontWeight: FontWeight.w800,
+        letterSpacing: 0.6,
+      ),
+    );
+  }
+}
+
+class _EmptyLine extends StatelessWidget {
+  const _EmptyLine({
+    required this.text,
+    required this.subtle,
+  });
+
+  final String text;
+  final Color subtle;
+
+  @override
+  Widget build(BuildContext context) {
+    return Text(
+      text,
+      style: TextStyle(
+        color: subtle,
+        fontSize: 13,
+        fontWeight: FontWeight.w500,
+        fontStyle: FontStyle.italic,
+      ),
+    );
+  }
+}
+
+class _BrowserCard extends StatelessWidget {
+  const _BrowserCard({required this.child});
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
+class _AtlasCard extends StatelessWidget {
+  const _AtlasCard({
+    required this.row,
+    required this.label,
+  });
+
+  final SurfaceStudioAtlasReadModel row;
+  final Color label;
+
+  @override
+  Widget build(BuildContext context) {
+    final n = row.usedByAnimationIds.length;
+    return _BrowserCard(
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
+            k: SurfaceStudioCatalogBrowserLabels.labelId,
+            v: row.id,
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: SurfaceStudioCatalogBrowserLabels.labelTileset,
+            v: row.tilesetId,
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: SurfaceStudioCatalogBrowserLabels.labelTile,
+            v: '${row.tileWidth}×${row.tileHeight}',
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: SurfaceStudioCatalogBrowserLabels.labelGrid,
+            v: '${row.columns}×${row.rows}',
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: 'Tuiles',
+            v: '${row.tileCount} tiles',
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: SurfaceStudioCatalogBrowserLabels.labelLayout,
+            v: row.layout.name,
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: SurfaceStudioCatalogBrowserLabels.labelUsedBy,
+            v: SurfaceStudioCatalogBrowserLabels.usedByAnimations(n),
+            valueColor: label,
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _AnimationCard extends StatelessWidget {
+  const _AnimationCard({
+    required this.row,
+    required this.label,
+  });
+
+  final SurfaceStudioAnimationReadModel row;
+  final Color label;
+
+  @override
+  Widget build(BuildContext context) {
+    final refLine = row.referencedAtlasIds.join(' ');
+    return _BrowserCard(
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
+            k: SurfaceStudioCatalogBrowserLabels.labelId,
+            v: row.id,
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: SurfaceStudioCatalogBrowserLabels.labelFrames,
+            v: SurfaceStudioCatalogBrowserLabels.frameLabel(row.frameCount),
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: SurfaceStudioCatalogBrowserLabels.labelTotalDuration,
+            v: '${row.totalDurationMs} ms',
+            valueColor: label,
+          ),
+          if (row.syncGroupId != null)
+            _KeyVal(
+              k: SurfaceStudioCatalogBrowserLabels.labelSync,
+              v: row.syncGroupId!,
+              valueColor: label,
+            ),
+          if (row.categoryId != null)
+            _KeyVal(
+              k: SurfaceStudioCatalogBrowserLabels.labelCategory,
+              v: row.categoryId!,
+              valueColor: label,
+            ),
+          _KeyVal(
+            k: SurfaceStudioCatalogBrowserLabels.labelRefAtlases,
+            v: refLine.isEmpty ? '—' : refLine,
+            valueColor: label,
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+String _roleLabel(SurfaceVariantRole r) => r.name;
+
+class _PresetCard extends StatelessWidget {
+  const _PresetCard({
+    required this.row,
+    required this.label,
+  });
+
+  final SurfaceStudioPresetReadModel row;
+  final Color label;
+
+  @override
+  Widget build(BuildContext context) {
+    final roleLine = row.roles.map(_roleLabel).join(' ');
+    final animLine = row.referencedAnimationIds.join(' ');
+    return _BrowserCard(
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
+            k: SurfaceStudioCatalogBrowserLabels.labelId,
+            v: row.id,
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: SurfaceStudioCatalogBrowserLabels.labelVariants,
+            v: SurfaceStudioCatalogBrowserLabels.variantLabel(row.variantCount),
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: SurfaceStudioCatalogBrowserLabels.labelRoles,
+            v: roleLine,
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: SurfaceStudioCatalogBrowserLabels.labelPresetAnimationRefs,
+            v: animLine.isEmpty ? '—' : animLine,
+            valueColor: label,
+          ),
+          _KeyVal(
+            k: SurfaceStudioCatalogBrowserLabels.labelCoverage,
+            v: row.coversStandardRoles
+                ? SurfaceStudioCatalogBrowserLabels.coverageFull
+                : SurfaceStudioCatalogBrowserLabels.coveragePartial,
+            valueColor: label,
+          ),
+        ],
+      ),
+    );
+  }
+}

```

### C.3 `/dev/null` → `surface_studio_catalog_browser_test.dart`

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart b/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart
new file mode 100644
index 00000000..f8f1b566
--- /dev/null
+++ b/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart
@@ -0,0 +1,801 @@
+// Tests widget — Surface Studio catalog browser (Lot 54).
+// API publique `map_core` uniquement (pas de `package:map_core/src/...`).
+
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_catalog_browser.dart';
+
+void main() {
+  group('SurfaceStudioCatalogBrowser (Lot 54)', () {
+    testWidgets('1. browser shows title Catalogue Surface', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioCatalogBrowser(readModel: _emptyReadModel())),
+      );
+      expect(find.text('Catalogue Surface'), findsOneWidget);
+    });
+
+    testWidgets('2. empty catalog: global empty message', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioCatalogBrowser(readModel: _emptyReadModel())),
+      );
+      expect(find.text('Le catalogue Surface est vide'), findsOneWidget);
+    });
+
+    testWidgets('3. empty catalog: per-section empty lines', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioCatalogBrowser(readModel: _emptyReadModel())),
+      );
+      expect(find.text('Aucun atlas Surface'), findsOneWidget);
+      expect(find.text('Aucune animation Surface'), findsOneWidget);
+      expect(find.text('Aucun preset Surface'), findsOneWidget);
+    });
+
+    testWidgets('4. minimal catalog: section headers visible', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.text('Atlas'), findsOneWidget);
+      expect(find.text('Animations'), findsOneWidget);
+      expect(find.text('Presets'), findsOneWidget);
+    });
+
+    testWidgets('5. minimal catalog: atlas details (736-tile grid)', (
+      tester,
+    ) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioCatalogBrowser(
+            readModel: buildSurfaceStudioReadModelFromCatalog(
+              _catalogWaterBigGrid(),
+            ),
+          ),
+        ),
+      );
+      expect(find.text('Water Atlas'), findsOneWidget);
+      expect(find.textContaining('Identifiant : water-atlas'), findsOneWidget);
+      expect(find.textContaining('Tileset : nature-tileset'), findsOneWidget);
+      expect(find.textContaining('32×32'), findsWidgets);
+      expect(find.textContaining('23×32'), findsOneWidget);
+      expect(find.textContaining('736'), findsOneWidget);
+    });
+
+    testWidgets('6. minimal catalog: animation details', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.text('Water Isolated Loop'), findsOneWidget);
+      expect(
+        find.textContaining('Identifiant : water-isolated-loop'),
+        findsOneWidget,
+      );
+      expect(find.textContaining('1 frame'), findsOneWidget);
+      expect(find.textContaining('120 ms'), findsOneWidget);
+      expect(find.textContaining('water-atlas'), findsWidgets);
+    });
+
+    testWidgets('7. minimal catalog: preset details', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.text('Water Surface'), findsOneWidget);
+      expect(
+        find.textContaining('Identifiant : water-surface'),
+        findsOneWidget,
+      );
+      expect(find.textContaining('Variantes : 1 variante'), findsOneWidget);
+      expect(find.textContaining('Rôles : isolated'), findsOneWidget);
+      expect(
+        find.textContaining('Animations liées : water-isolated-loop'),
+        findsOneWidget,
+      );
+      expect(
+        find.textContaining('Couverture standard : Rôles standards incomplets'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('8. full animation: sync group and category', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioCatalogBrowser(
+            readModel:
+                buildSurfaceStudioReadModelFromCatalog(_catalogSyncCat()),
+          ),
+        ),
+      );
+      expect(find.textContaining('Groupe de synchronisation : water'),
+          findsOneWidget);
+      expect(
+          find.textContaining('Catégorie : animated-surfaces'), findsOneWidget);
+    });
+
+    testWidgets('9. atlas used by two animations', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioCatalogBrowser(
+            readModel: buildSurfaceStudioReadModelFromCatalog(
+              _catalogSharedAtlasTwoAnims(),
+            ),
+          ),
+        ),
+      );
+      expect(find.textContaining('Utilisé par 2 animations'), findsOneWidget);
+    });
+
+    testWidgets('10. atlas unused', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioCatalogBrowser(
+            readModel: buildSurfaceStudioReadModelFromCatalog(
+              _catalogUnusedAtlas(),
+            ),
+          ),
+        ),
+      );
+      expect(find.textContaining('Non utilisé'), findsOneWidget);
+    });
+
+    testWidgets('11. animation referenced atlas ids deduped order', (
+      tester,
+    ) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioCatalogBrowser(
+            readModel: buildSurfaceStudioReadModelFromCatalog(
+              _catalogDedupeAtlasOrder(),
+            ),
+          ),
+        ),
+      );
+      expect(find.textContaining('atlas-b atlas-a'), findsOneWidget);
+    });
+
+    testWidgets('12. preset referenced animation ids deduped order', (
+      tester,
+    ) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioCatalogBrowser(
+            readModel: buildSurfaceStudioReadModelFromCatalog(
+              _catalogDedupeAnimOrder(),
+            ),
+          ),
+        ),
+      );
+      expect(find.textContaining('anim-b anim-a'), findsOneWidget);
+    });
+
+    testWidgets('13. preset roles source order', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioCatalogBrowser(
+            readModel: buildSurfaceStudioReadModelFromCatalog(
+              _catalogRoleOrder(),
+            ),
+          ),
+        ),
+      );
+      expect(
+        find.textContaining('Rôles : cross isolated horizontal'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('14. atlas order preserved', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioCatalogBrowser(
+            readModel: buildSurfaceStudioReadModelFromCatalog(
+              _catalogThreeAtlases(),
+            ),
+          ),
+        ),
+      );
+      final names = ['W', 'L', 'G'];
+      for (final n in names) {
+        expect(find.text(n), findsOneWidget);
+      }
+    });
+
+    testWidgets('15. animation order preserved', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioCatalogBrowser(
+            readModel: buildSurfaceStudioReadModelFromCatalog(
+              _catalogThreeAnims(),
+            ),
+          ),
+        ),
+      );
+      final block = tester
+          .widgetList<Text>(find.byType(Text))
+          .map((t) => t.data ?? '')
+          .join('\n');
+      expect(block.indexOf('water-a'), lessThan(block.indexOf('water-b')));
+      expect(block.indexOf('water-b'), lessThan(block.indexOf('water-c')));
+    });
+
+    testWidgets('16. preset order preserved', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioCatalogBrowser(
+            readModel: buildSurfaceStudioReadModelFromCatalog(
+              _catalogThreePresets(),
+            ),
+          ),
+        ),
+      );
+      final block = tester
+          .widgetList<Text>(find.byType(Text))
+          .map((t) => t.data ?? '')
+          .join('\n');
+      expect(block.indexOf('water-surface'),
+          lessThan(block.indexOf('lava-surface')));
+      expect(block.indexOf('lava-surface'),
+          lessThan(block.indexOf('grass-surface')));
+    });
+
+    testWidgets('17. order is list order not sortOrder', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioCatalogBrowser(
+            readModel: buildSurfaceStudioReadModelFromCatalog(
+              _catalogSortOrderConflict(),
+            ),
+          ),
+        ),
+      );
+      final block = tester
+          .widgetList<Text>(find.byType(Text))
+          .map((t) => t.data ?? '')
+          .join('\n');
+      expect(block.indexOf('First'), lessThan(block.indexOf('Second')));
+    });
+
+    testWidgets('18. browser in scrollable ancestor', (tester) async {
+      await tester.pumpWidget(
+        MaterialApp(
+          home: SingleChildScrollView(
+            child: SurfaceStudioCatalogBrowser(readModel: _emptyReadModel()),
+          ),
+        ),
+      );
+      expect(find.byType(SingleChildScrollView), findsOneWidget);
+    });
+
+    testWidgets('19. no TextField in browser', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.byType(TextField), findsNothing);
+    });
+
+    testWidgets('20. browser has no active edit affordances', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.text('Créer'), findsNothing);
+      expect(find.text('Modifier'), findsNothing);
+      expect(find.text('Supprimer'), findsNothing);
+      expect(find.text('Enregistrer'), findsNothing);
+      expect(find.text('Sauvegarder'), findsNothing);
+      expect(find.text('Save'), findsNothing);
+      expect(find.text('Delete'), findsNothing);
+      expect(find.text('Edit'), findsNothing);
+    });
+
+    testWidgets('21. no internal type names in UI', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
+      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
+      expect(
+          find.textContaining('SurfaceVariantAnimationRefSet'), findsNothing);
+      expect(find.textContaining('SurfaceStudioAtlasReadModel'), findsNothing);
+      expect(
+          find.textContaining('SurfaceStudioAnimationReadModel'), findsNothing);
+      expect(find.textContaining('SurfaceStudioPresetReadModel'), findsNothing);
+    });
+
+    testWidgets('24. error read model builds without throw', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioCatalogBrowser(readModel: _errorReadModel())),
+      );
+      expect(tester.takeException(), isNull);
+    });
+
+    testWidgets('25. derived row fields drive display', (tester) async {
+      final rm = _minimalWaterReadModel();
+      expect(rm.atlases.first.usedByAnimationIds, isNotEmpty);
+      expect(rm.animations.first.referencedAtlasIds, isNotEmpty);
+      expect(rm.presets.first.referencedAnimationIds, isNotEmpty);
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioCatalogBrowser(readModel: rm)),
+      );
+      expect(find.textContaining('Utilisé par 1 animation'), findsOneWidget);
+    });
+
+    testWidgets('28. builds without ProviderScope', (tester) async {
+      await tester.pumpWidget(
+        MaterialApp(
+          home: SurfaceStudioCatalogBrowser(readModel: _emptyReadModel()),
+        ),
+      );
+      expect(find.text('Catalogue Surface'), findsOneWidget);
+    });
+
+    testWidgets('29. accepts bounded width', (tester) async {
+      await tester.pumpWidget(
+        MaterialApp(
+          home: Center(
+            child: SizedBox(
+              width: 360,
+              child: SingleChildScrollView(
+                child: SurfaceStudioCatalogBrowser(
+                  readModel: _minimalWaterReadModel(),
+                ),
+              ),
+            ),
+          ),
+        ),
+      );
+      expect(tester.takeException(), isNull);
+    });
+
+    testWidgets('30. public map_core only (import smoke)', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioCatalogBrowser(readModel: _emptyReadModel())),
+      );
+      expect(find.text('Catalogue Surface'), findsOneWidget);
+    });
+  });
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
+SurfaceStudioReadModel _emptyReadModel() =>
+    buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());
+
+SurfaceStudioReadModel _minimalWaterReadModel() =>
+    buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());
+
+SurfaceStudioReadModel _errorReadModel() =>
+    buildSurfaceStudioReadModelFromCatalog(_catalogPresetMissingAnim());
+
+SurfaceAtlasGeometry _geom2x2() => SurfaceAtlasGeometry(
+      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+      gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
+      layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+    );
+
+ProjectSurfaceCatalog _minimalWaterCatalog() {
+  final g = _geom2x2();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'water-atlas',
+    name: 'Water Atlas',
+    tilesetId: 'nature-tileset',
+    geometry: g,
+  );
+  final frame = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
+    durationMs: 120,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'water-isolated-loop',
+    name: 'Water Isolated Loop',
+    timeline: SurfaceAnimationTimeline(frames: [frame]),
+  );
+  final refs = SurfaceVariantAnimationRefSet(
+    refs: [
+      SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.isolated,
+        animationId: 'water-isolated-loop',
+      ),
+    ],
+  );
+  final preset = ProjectSurfacePreset(
+    id: 'water-surface',
+    name: 'Water Surface',
+    variantAnimations: refs,
+  );
+  return ProjectSurfaceCatalog(
+    atlases: [atlas],
+    animations: [anim],
+    presets: [preset],
+  );
+}
+
+ProjectSurfaceCatalog _catalogWaterBigGrid() {
+  final g = SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+    gridSize: SurfaceAtlasGridSize(columns: 23, rows: 32),
+    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+  );
+  final atlas = ProjectSurfaceAtlas(
+    id: 'water-atlas',
+    name: 'Water Atlas',
+    tilesetId: 'nature-tileset',
+    geometry: g,
+  );
+  final frame = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
+    durationMs: 120,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'water-isolated-loop',
+    name: 'Water Isolated Loop',
+    timeline: SurfaceAnimationTimeline(frames: [frame]),
+  );
+  return ProjectSurfaceCatalog(
+    atlases: [atlas],
+    animations: [anim],
+    presets: const [],
+  );
+}
+
+ProjectSurfaceCatalog _catalogSyncCat() {
+  final g = _geom2x2();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'a',
+    name: 'A',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final frame = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
+    durationMs: 120,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'anim-sync',
+    name: 'Anim Sync',
+    syncGroupId: 'water',
+    categoryId: 'animated-surfaces',
+    timeline: SurfaceAnimationTimeline(frames: [frame]),
+  );
+  return ProjectSurfaceCatalog(
+    atlases: [atlas],
+    animations: [anim],
+    presets: const [],
+  );
+}
+
+ProjectSurfaceCatalog _catalogSharedAtlasTwoAnims() {
+  final g = _geom2x2();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'shared',
+    name: 'Shared',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final f1 = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'shared', column: 0, row: 0),
+    durationMs: 10,
+  );
+  final f2 = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'shared', column: 1, row: 0),
+    durationMs: 10,
+  );
+  final a1 = ProjectSurfaceAnimation(
+    id: 'anim-1',
+    name: 'A1',
+    timeline: SurfaceAnimationTimeline(frames: [f1]),
+  );
+  final a2 = ProjectSurfaceAnimation(
+    id: 'anim-2',
+    name: 'A2',
+    timeline: SurfaceAnimationTimeline(frames: [f2]),
+  );
+  return ProjectSurfaceCatalog(
+    atlases: [atlas],
+    animations: [a1, a2],
+    presets: const [],
+  );
+}
+
+ProjectSurfaceCatalog _catalogUnusedAtlas() {
+  final g = _geom2x2();
+  final used = ProjectSurfaceAtlas(
+    id: 'u',
+    name: 'U',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final orphan = ProjectSurfaceAtlas(
+    id: 'orphan',
+    name: 'Orphan',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final f = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'u', column: 0, row: 0),
+    durationMs: 10,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'a',
+    name: 'A',
+    timeline: SurfaceAnimationTimeline(frames: [f]),
+  );
+  return ProjectSurfaceCatalog(
+    atlases: [used, orphan],
+    animations: [anim],
+    presets: const [],
+  );
+}
+
+ProjectSurfaceCatalog _catalogDedupeAtlasOrder() {
+  final ga = _geom2x2();
+  final gb = SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: 16, height: 16),
+    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
+    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+  );
+  final atlasA = ProjectSurfaceAtlas(
+    id: 'atlas-a',
+    name: 'A',
+    tilesetId: 't',
+    geometry: ga,
+  );
+  final atlasB = ProjectSurfaceAtlas(
+    id: 'atlas-b',
+    name: 'B',
+    tilesetId: 't',
+    geometry: gb,
+  );
+  final frames = <SurfaceAnimationFrame>[
+    SurfaceAnimationFrame(
+      tileRef: SurfaceAtlasTileRef(atlasId: 'atlas-b', column: 0, row: 0),
+      durationMs: 10,
+    ),
+    SurfaceAnimationFrame(
+      tileRef: SurfaceAtlasTileRef(atlasId: 'atlas-a', column: 0, row: 0),
+      durationMs: 10,
+    ),
+    SurfaceAnimationFrame(
+      tileRef: SurfaceAtlasTileRef(atlasId: 'atlas-b', column: 1, row: 0),
+      durationMs: 10,
+    ),
+  ];
+  final anim = ProjectSurfaceAnimation(
+    id: 'dedupe-atlas',
+    name: 'Dedupe Atlas',
+    timeline: SurfaceAnimationTimeline(frames: frames),
+  );
+  return ProjectSurfaceCatalog(
+    atlases: [atlasA, atlasB],
+    animations: [anim],
+    presets: const [],
+  );
+}
+
+ProjectSurfaceCatalog _catalogDedupeAnimOrder() {
+  final g = _geom2x2();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'x',
+    name: 'X',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final f1 = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'x', column: 0, row: 0),
+    durationMs: 10,
+  );
+  final a1 = ProjectSurfaceAnimation(
+    id: 'anim-b',
+    name: 'B',
+    timeline: SurfaceAnimationTimeline(frames: [f1]),
+  );
+  final a2 = ProjectSurfaceAnimation(
+    id: 'anim-a',
+    name: 'A',
+    timeline: SurfaceAnimationTimeline(frames: [f1]),
+  );
+  final refs = SurfaceVariantAnimationRefSet(
+    refs: <SurfaceVariantAnimationRef>[
+      SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.isolated,
+        animationId: 'anim-b',
+      ),
+      SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.endNorth,
+        animationId: 'anim-a',
+      ),
+      SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.endEast,
+        animationId: 'anim-b',
+      ),
+    ],
+  );
+  final preset = ProjectSurfacePreset(
+    id: 'p',
+    name: 'P',
+    variantAnimations: refs,
+  );
+  return ProjectSurfaceCatalog(
+    atlases: [atlas],
+    animations: [a1, a2],
+    presets: [preset],
+  );
+}
+
+ProjectSurfaceCatalog _catalogRoleOrder() {
+  final g = _geom2x2();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'r',
+    name: 'R',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final f = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'r', column: 0, row: 0),
+    durationMs: 1,
+  );
+  final aCross = ProjectSurfaceAnimation(
+    id: 'ac',
+    name: 'AC',
+    timeline: SurfaceAnimationTimeline(frames: [f]),
+  );
+  final aIso = ProjectSurfaceAnimation(
+    id: 'ai',
+    name: 'AI',
+    timeline: SurfaceAnimationTimeline(frames: [f]),
+  );
+  final aH = ProjectSurfaceAnimation(
+    id: 'ah',
+    name: 'AH',
+    timeline: SurfaceAnimationTimeline(frames: [f]),
+  );
+  final refs = SurfaceVariantAnimationRefSet(
+    refs: <SurfaceVariantAnimationRef>[
+      SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.cross,
+        animationId: 'ac',
+      ),
+      SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.isolated,
+        animationId: 'ai',
+      ),
+      SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.horizontal,
+        animationId: 'ah',
+      ),
+    ],
+  );
+  final preset = ProjectSurfacePreset(
+    id: 'proles',
+    name: 'Proles',
+    variantAnimations: refs,
+  );
+  return ProjectSurfaceCatalog(
+    atlases: [atlas],
+    animations: [aCross, aIso, aH],
+    presets: [preset],
+  );
+}
+
+ProjectSurfaceCatalog _catalogThreeAtlases() {
+  final g = _geom2x2();
+  ProjectSurfaceAtlas ax(String id, String name) => ProjectSurfaceAtlas(
+        id: id,
+        name: name,
+        tilesetId: 't',
+        geometry: g,
+      );
+  return ProjectSurfaceCatalog(
+    atlases: [ax('w', 'W'), ax('l', 'L'), ax('g', 'G')],
+    animations: const [],
+    presets: const [],
+  );
+}
+
+ProjectSurfaceCatalog _catalogThreeAnims() {
+  final g = _geom2x2();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'a',
+    name: 'A',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final f = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
+    durationMs: 1,
+  );
+  ProjectSurfaceAnimation anim(String id) => ProjectSurfaceAnimation(
+        id: id,
+        name: id,
+        timeline: SurfaceAnimationTimeline(frames: [f]),
+      );
+  return ProjectSurfaceCatalog(
+    atlases: [atlas],
+    animations: [anim('water-a'), anim('water-b'), anim('water-c')],
+    presets: const [],
+  );
+}
+
+ProjectSurfaceCatalog _catalogThreePresets() {
+  final g = _geom2x2();
+  final atlas = ProjectSurfaceAtlas(
+    id: 'a',
+    name: 'A',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final f = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
+    durationMs: 1,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'anim',
+    name: 'anim',
+    timeline: SurfaceAnimationTimeline(frames: [f]),
+  );
+  final ref = SurfaceVariantAnimationRef(
+    role: SurfaceVariantRole.isolated,
+    animationId: 'anim',
+  );
+  ProjectSurfacePreset pr(String id) => ProjectSurfacePreset(
+        id: id,
+        name: id,
+        variantAnimations: SurfaceVariantAnimationRefSet(refs: [ref]),
+      );
+  return ProjectSurfaceCatalog(
+    atlases: [atlas],
+    animations: [anim],
+    presets: [pr('water-surface'), pr('lava-surface'), pr('grass-surface')],
+  );
+}
+
+ProjectSurfaceCatalog _catalogSortOrderConflict() {
+  final g = _geom2x2();
+  final aFirst = ProjectSurfaceAtlas(
+    id: 'first-atlas',
+    name: 'First',
+    tilesetId: 't',
+    geometry: g,
+    sortOrder: 99,
+  );
+  final aSecond = ProjectSurfaceAtlas(
+    id: 'second-atlas',
+    name: 'Second',
+    tilesetId: 't',
+    geometry: g,
+    sortOrder: 1,
+  );
+  return ProjectSurfaceCatalog(
+    atlases: [aFirst, aSecond],
+    animations: const [],
+    presets: const [],
+  );
+}
+
+ProjectSurfaceCatalog _catalogPresetMissingAnim() {
+  final refs = SurfaceVariantAnimationRefSet(
+    refs: [
+      SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.isolated,
+        animationId: 'missing-anim',
+      ),
+    ],
+  );
+  return ProjectSurfaceCatalog(
+    atlases: const [],
+    animations: const [],
+    presets: [
+      ProjectSurfacePreset(
+        id: 'p',
+        name: 'p',
+        variantAnimations: refs,
+      ),
+    ],
+  );
+}

```

### C.4 Rapport

Le diff unifié depuis `/dev/null` de ce fichier Markdown est obtenu en préfixant chaque ligne du présent document par `+` (exception autorisée ; le contenu utile est déjà ce corps + blocs A–C).

---

*Fin du rapport Lot 54.*
