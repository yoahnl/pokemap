# Surface Engine — Lot 58 — Surface Studio Selection State V0

## Résumé exécutif

Ce lot ajoute un **value object** `SurfaceStudioSelection` (pure Dart, hors `map_core`), un **résumé visuel** `SurfaceStudioSelectionSummary`, et une **sélection locale** dans `SurfaceStudioPanel` (`StatefulWidget`) reliée au catalogue via `SurfaceStudioCatalogBrowser` et les vues détail atlas / animation / preset. L’utilisateur peut surligner une fiche et lire un résumé ; **aucune** écriture manifest, **aucune** mutation de catalogue, **aucun** provider / repository / service.

## Pourquoi après le Lot 57

Le Lot 57 a livré les vues détail animation et preset en lecture seule. Le Lot 58 ajoute la **première interaction** utile (sélection + résumé) pour préparer l’inspecteur (Lot 59+) sans édition.

## Tableau récapitulatif des lots Surface 39–62

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
| 57 | Surface Studio Animation Detail / Preset Detail V0 | fait |
| **58** | **Surface Studio Selection State V0** | **ce lot** |
| 59 | Surface Studio Inspector / Authoring Prep V0 | prochain probable |
| 60 | Surface Studio Atlas Authoring Prep V0 | ensuite probable |
| 61 | Surface Studio Animation Authoring Prep V0 | ensuite probable |
| 62 | Surface Studio Preset Authoring Prep V0 | ensuite probable |

## Passes obligatoires (preuve de processus)

1. **Audit / architecture** : lecture des panneaux Surface Studio existants (Lots 52–57), contrat `SurfaceStudioReadModel` inchangé côté consommation.
2. **Implémentation minimale** : modèle UI + fil d’état `setState` dans le panneau uniquement.
3. **Tests / validation** : tests modèle, interaction widget, panel, résumé ; régression `test/surface_studio/*.dart` combinés ; `surface_studio_read_model_test` map_core ; `flutter analyze` chemins Lot 58.
4. **Review critique finale** : section *Auto-review indépendante* plus bas.
5. **Rapport Evidence Pack** : ce document.

## `git status --short --untracked-files=all` — initial (message système au début de la conversation Cursor)

```
M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/standard_path_preset_vertical_atlas_builder.dart
?? packages/map_core/test/standard_path_preset_vertical_atlas_builder_test.dart
?? reports/surface/surface_engine_lot_15_standard_path_preset_vertical_atlas_builder.md
```

*Ces entrées ne font pas partie du Lot 58 ; elles illustrent un worktree déjà sale avant l’implémentation Lot 58 dans cette session.*

## Fichiers consultés (audit)

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_detail_view.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_animation_detail_view.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_preset_detail_view.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_diagnostics_view.dart` (non modifié ; inclus dans `flutter analyze`)
- Tests existants sous `packages/map_editor/test/surface_studio/`
- Rapports de référence Lots 55–57 sous `reports/surface/`

## Fichiers créés (Lot 58)

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_selection.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_selection_summary.dart`
- `packages/map_editor/test/surface_studio/surface_studio_selection_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart`
- `reports/surface/surface_engine_lot_58_surface_studio_selection_state.md` (ce fichier)

## Fichiers modifiés (Lot 58)

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_detail_view.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_animation_detail_view.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_preset_detail_view.dart`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`

## Changements préexistants vs changements Lot 58

- **Préexistants (hors Lot 58)** : modifications `map_core` / Lot 15 visibles dans le statut initial ci-dessus ; **non touchées** par ce lot.
- **Lot 58** : uniquement les chemins `packages/map_editor/**` listés ci-dessus et ce rapport sous `reports/surface/`.

## Audit Surface Studio après Lot 57 (où sont les fiches)

- **Atlas** : `SurfaceStudioAtlasDetailView` — liste de fiches sous « Atlas Surface ».
- **Animations** : `SurfaceStudioAnimationDetailView` — idem.
- **Presets** : `SurfaceStudioPresetDetailView` — idem.
- **Browser** : `SurfaceStudioCatalogBrowser` empile les trois vues.
- **Panneau** : `SurfaceStudioPanel` — compteurs, résumé de sélection (Lot 58), browser, diagnostics.

## Où la sélection est stockée

Dans `_SurfaceStudioPanelState._selection` (`SurfaceStudioSelection`), réinitialisable par `setState` au fil des taps. Aucune clé projet, aucun champ `ProjectManifest`.

## Pourquoi la sélection est locale à l’UI

Elle sert uniquement à la **lecture** et à la préparation d’inspection : disparaît si le widget est détruit ; ne doit pas survivre à un rechargement de projet ni imposer une persistance transitoire dans le manifest.

## Pourquoi elle ne doit pas être dans `ProjectManifest`

Le manifest décrit le **contrat de données** du projet ; la sélection est un **curseur UI** sans sémantique de sauvegarde. La mélanger au manifest polluerait les sérialisations et les diffs utilisateur.

## Pourquoi la sélection ne peut pas muter le catalogue

`ProjectSurfaceCatalog` et `SurfaceStudioReadModel` sont des **snapshots** construits côté `map_core` pour la lecture. Le Lot 58 n’appelle aucun mutateur sur ces objets : la sélection ne fait que choisir quel **sous-ensemble visuel** mettre en avant (`matches*`), sans `copyWith`, sans liste modifiable, sans callback vers une couche persistance. Le test 58.26 vérifie `identical(manifest.surfaceCatalog, before)` après taps.

## Pourquoi aucun provider Riverpod n’est nécessaire

L’arbre concerné tient en un seul `StatefulWidget` ; propager `selection` + callback suffit. Un provider serait du bruit sans partage d’état transversal.

## Pourquoi aucun repository / service n’est nécessaire

Aucun I/O, aucune règle métier nouvelle : uniquement de la présentation.

## API `SurfaceStudioSelection`

- `none` : `kind == null`, `id == null`, `isNone == true`.
- `atlas(id)` / `animation(id)` / `preset(id)` : usine avec validation trim ; refus de chaîne vide.
- `matchesAtlas` / `matchesAnimation` / `matchesPreset` : comparent l’id courant après trim.
- Égalité / `hashCode` : valeur, pour tests et mises à jour d’UI.

## Sémantique du résumé (`SurfaceStudioSelectionSummary`)

- `Aucune sélection` + hint d’aide quand `isNone`.
- Sinon : ligne « Atlas / Animation / Preset sélectionné » + **id** sur la ligne suivante + hint.

## Décisions explicites (non-édition, non-carte, non-runtime)

- Pas d’édition, pas de sauvegarde, pas de modification `map_core`, pas de codec, pas de provider/repository/service, pas de `map_runtime` / `map_gameplay` / `map_battle`.

## Ce qui a été testé

- Modèle (7 cas), interaction fiches + browser (13 cas), résumé widget (2 cas), panel 58.21–58.28, suite `test/surface_studio` combinée (193 tests), `map_core` `surface_studio_read_model_test` (30 tests), `flutter analyze` 18 chemins.

## Ce qui n’a volontairement pas été fait

- Inspector (Lot 59), édition atlas/anim/preset, persistance, test workspace 29 (harness lourd) — la sélection est couverte par les tests panel catalogue minimal.

## Impact lots futurs

- Lot 59+ peuvent lire `SurfaceStudioSelection` depuis le state panel ou un contrôleur dédié **sans** étendre le manifest.

## Proposition Lot 59

- Introduire un panneau ou colonne **inspecteur** branché sur la même sélection (toujours local), affichant des champs en lecture structurés puis champs d’édition en lots ultérieurs.

## Commandes lancées (extraits requis)

### Formatage ciblé

```bash
cd packages/map_editor
dart format \
  lib/src/features/surface_studio/surface_studio_selection.dart \
  lib/src/features/surface_studio/surface_studio_selection_summary.dart \
  lib/src/features/surface_studio/surface_studio_panel.dart \
  lib/src/features/surface_studio/surface_studio_catalog_browser.dart \
  lib/src/features/surface_studio/surface_studio_atlas_detail_view.dart \
  lib/src/features/surface_studio/surface_studio_animation_detail_view.dart \
  lib/src/features/surface_studio/surface_studio_preset_detail_view.dart \
  test/surface_studio/surface_studio_selection_test.dart \
  test/surface_studio/surface_studio_selection_summary_test.dart \
  test/surface_studio/surface_studio_selection_interaction_test.dart \
  test/surface_studio/surface_studio_panel_test.dart
```

Résultat : `Formatted 11 files (0 changed) in 0.02 seconds.`

### Test modèle (selection)

Commande : `cd packages/map_editor && flutter test test/surface_studio/surface_studio_selection_test.dart`

Dernière ligne : `00:01 +7: All tests passed!`

### Test interaction (selection)

Commande : `cd packages/map_editor && flutter test test/surface_studio/surface_studio_selection_interaction_test.dart`

Dernière ligne : `00:02 +13: All tests passed!`

### Tests Surface Studio combinés (tous les fichiers listés au cahier des charges + summary)

Commande : `cd packages/map_editor && flutter test` (liste de 10 fichiers + `surface_studio_selection_summary_test.dart`)

Dernière ligne : `00:05 +193: All tests passed!` (littéral terminal ; la fenêtre 800×600 exige `ensureVisible` sur les cibles de tap hors viewport.)

### `map_core` — `surface_studio_read_model_test.dart`

Commande : `cd packages/map_core && dart test test/surface_studio_read_model_test.dart`

Dernière ligne : `00:00 +30: All tests passed!`

### `flutter analyze` (chemins Lot 58)

Commande : `cd packages/map_editor && flutter analyze` (18 chemins listés dans le cahier des charges, variante sans `surface_studio_selection_summary` manquant — tous présents ici)

Résultat :
```
Analyzing 18 items...
No issues found! (ran in 2.5s)
```

### Suite complète `map_editor` (informationnelle)

Commande : `cd packages/map_editor && flutter test`

Dernière ligne : `01:13 +666 -41: Some tests failed.`

**Interprétation** : 41 échecs **préexistants** hors périmètre Surface ; les tests ciblés Lot 58 et `test/surface_studio` passent (voir combinaison +193).

### Régressions par fichier (dernière ligne = `All tests passed!`)

- `surface_studio_animation_detail_view_test.dart` — Lot 57 : `+22: All tests passed!`
- `surface_studio_preset_detail_view_test.dart` : `+22: All tests passed!`
- `surface_studio_atlas_detail_view_test.dart` — Lot 56 : `+27: All tests passed!`
- `surface_studio_diagnostics_view_test.dart` — Lot 55 : `+23: All tests passed!`
- `surface_studio_catalog_browser_test.dart` — Lot 54 : `+29: All tests passed!`
- `surface_studio_panel_test.dart` — Lot 52 + 58 : `+37: All tests passed!`
- `surface_studio_workspace_entry_test.dart` — Lot 53 : inclus dans le run +193 (`All tests passed!` final).

## Liste des fichiers formatés (dart format)

Même liste que la commande `dart format` ci-dessus (11 fichiers).

## Vérification anti-mojibake

Recherche manuelle : absence des séquences `Ã`, `â€™`, `â€"`, `â†'` dans les sources Lot 58 et ce rapport (UTF-8, apostrophes typographiques françaises `’` cohérentes avec le code existant).

## Points de vigilance

- Vues de test 800×600 : toujours `ensureVisible` avant `tap` sur fiches en bas de `SingleChildScrollView`.
- Libellé « water-loop » dans le test modèle vs id catalogue minimal `water-isolated-loop` dans les tests panel : **deux id distincts** volontairement (le cahier des charges utilisait un exemple `water-loop` pour le test pur modèle ; le fixture minimal d’eau existant garde l’id `water-isolated-loop`).

## Autocritique

- Le Lot 58 pourrait unifier l’id d’exemple `water-loop` / `water-isolated-loop` **ou** documenter l’intention (fait ici) pour éviter toute ambiguïté produit.
- Test 29 (workspace) non automatisé : le risque d’harness lourd a été privilégié par rapport à un test de widget direct sur le même `SurfaceStudioPanel` déjà exécuté.

## Ce que le prompt semble discutable ou incomplet

- Exiger **dans le chat** le contenu intégral de chaque fichier **et** chaque diff **et** le rapport **complet** : redondant avec le dépôt ; ce rapport les inline (Evidence Pack) pour une preuve reproductible.
- Le périmètre **« aucun map_core »** interdit toute amélioration partagée de sélection côté core : cohérent pour un état UI, mais exclut a priori une future sérialisation de sélection **si** jamais demandée (hors scope actuel).

## Auto-review indépendante (checklist)

- `SurfaceStudioSelection` existe ; `none` = pas d’id ; factories rejettent ids vides ; égalité / hashCode OK.
- Fiches cliquables + résumé ; changement de sélection remplace l’ancienne ; `surfaceCatalog` / manifest identiques après taps (test 58.26 / binding existant).
- Pas de `TextField` ni de libellés d’édition actifs ciblés ; pas de provider Surface dédié requis.
- Aucun changement `map_core` dans ce worktree pour Lot 58 ; `flutter analyze` vert sur les chemins.
- `build_runner` non exécuté (aucun Freezed/JSON modifié).

## Vérification Evidence Pack (contenu inliné plus bas)

Sections **A** (fichiers créés, texte intégral), **B** (fichiers modifiés : diff `git` intégral), **C** (diffs `/dev/null` via `git diff --no-index`), **D** (sorties de commandes copiées dans les sections « Commandes lancées »).

---

# Evidence Pack — A. Fichiers créés (contenu intégral)

Les fichiers suivants sont recopiés ici tels qu’à l’issue du lot (même contenu que le worktree).


## packages/map_editor/lib/src/features/surface_studio/surface_studio_selection.dart

```dart
// État de sélection **UI local** Surface Studio (Lot 58).
//
// Aucun Flutter, aucun map_core, aucun JSON, aucune persistance : value object
// pur pour le panneau. Ne décrit pas le catalogue — ne le mutera jamais.

/// Rôle d’une entrée sélectionnée dans le browser Surface Studio.
enum SurfaceStudioSelectionKind {
  atlas,
  animation,
  preset,
}

/// Sélection auteur côté éditeur (inspection / futur inspector), jamais persistée.
class SurfaceStudioSelection {
  const SurfaceStudioSelection._(this._kind, this._id);

  final SurfaceStudioSelectionKind? _kind;
  final String? _id;

  /// Aucun atlas / animation / preset mis en surbrillance.
  const SurfaceStudioSelection.none()
      : _kind = null,
        _id = null;

  /// [id] rejeté si vide ou uniquement des espaces (après trim).
  factory SurfaceStudioSelection.atlas(String id) {
    final t = id.trim();
    if (t.isEmpty) {
      throw ArgumentError.value(id, 'id', 'atlas id must be non-empty');
    }
    return SurfaceStudioSelection._(SurfaceStudioSelectionKind.atlas, t);
  }

  factory SurfaceStudioSelection.animation(String id) {
    final t = id.trim();
    if (t.isEmpty) {
      throw ArgumentError.value(id, 'id', 'animation id must be non-empty');
    }
    return SurfaceStudioSelection._(SurfaceStudioSelectionKind.animation, t);
  }

  factory SurfaceStudioSelection.preset(String id) {
    final t = id.trim();
    if (t.isEmpty) {
      throw ArgumentError.value(id, 'id', 'preset id must be non-empty');
    }
    return SurfaceStudioSelection._(SurfaceStudioSelectionKind.preset, t);
  }

  SurfaceStudioSelectionKind? get kind => _kind;

  String? get id => _id;

  bool get isNone => _kind == null;

  bool get isAtlas => _kind == SurfaceStudioSelectionKind.atlas;

  bool get isAnimation => _kind == SurfaceStudioSelectionKind.animation;

  bool get isPreset => _kind == SurfaceStudioSelectionKind.preset;

  bool matchesAtlas(String id) => isAtlas && _id == id.trim();

  bool matchesAnimation(String id) => isAnimation && _id == id.trim();

  bool matchesPreset(String id) => isPreset && _id == id.trim();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceStudioSelection &&
          _kind == other._kind &&
          _id == other._id;

  @override
  int get hashCode => Object.hash(_kind, _id);
}

```

## packages/map_editor/lib/src/features/surface_studio/surface_studio_selection_summary.dart

```dart
// Résumé de la sélection Surface Studio (Lot 58) — **présentation seule**.
//
// Reflète l’état [SurfaceStudioSelection] tenu par le panneau : aucune édition,
// aucun catalogue, pas de persistance, pas de provider.

import 'package:flutter/cupertino.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_selection.dart';

/// En-têtes de résumé visibles (pas de noms de types internes).
class SurfaceStudioSelectionSummaryLabels {
  const SurfaceStudioSelectionSummaryLabels._();

  static const String hint =
      'Sélectionnez un élément du catalogue pour l’inspecter.';

  static const String none = 'Aucune sélection';

  static const String lineAtlas = 'Atlas sélectionné';
  static const String lineAnimation = 'Animation sélectionnée';
  static const String linePreset = 'Preset sélectionné';
}

/// Bloc read-only : ligne d’état + id + texte d’aide.
class SurfaceStudioSelectionSummary extends StatelessWidget {
  const SurfaceStudioSelectionSummary({
    super.key,
    required this.selection,
  });

  final SurfaceStudioSelection selection;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    const accent = Color(0xFF2DD4BF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selection.isNone
              ? EditorChrome.editorIslandRim(context)
              : Color.lerp(
                  EditorChrome.editorIslandRim(context),
                  accent,
                  0.45,
                )!,
          width: selection.isNone ? 1 : 1.2,
        ),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selection.isNone) ...[
            Text(
              SurfaceStudioSelectionSummaryLabels.none,
              style: TextStyle(
                color: subtle,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else ...[
            Text(
              _kindLine(selection),
              style: const TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              selection.id!,
              style: TextStyle(
                color: label,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            SurfaceStudioSelectionSummaryLabels.hint,
            style: TextStyle(
              color: subtle,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

String _kindLine(SurfaceStudioSelection s) {
  if (s.isAtlas) {
    return SurfaceStudioSelectionSummaryLabels.lineAtlas;
  }
  if (s.isAnimation) {
    return SurfaceStudioSelectionSummaryLabels.lineAnimation;
  }
  if (s.isPreset) {
    return SurfaceStudioSelectionSummaryLabels.linePreset;
  }
  return SurfaceStudioSelectionSummaryLabels.none;
}

```

## packages/map_editor/test/surface_studio/surface_studio_selection_test.dart

```dart
// Tests unitaires — modèle [SurfaceStudioSelection] (Lot 58, pur Dart via flutter_test).
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_selection.dart';

void main() {
  group('SurfaceStudioSelection (Lot 58 model)', () {
    test('1. none — aucune sélection', () {
      const s = SurfaceStudioSelection.none();
      expect(s.isNone, isTrue);
      expect(s.kind, isNull);
      expect(s.id, isNull);
    });

    test('2. sélection atlas', () {
      final s = SurfaceStudioSelection.atlas('water-atlas');
      expect(s.isAtlas, isTrue);
      expect(s.isAnimation, isFalse);
      expect(s.isPreset, isFalse);
      expect(s.matchesAtlas('water-atlas'), isTrue);
      expect(s.matchesAtlas('other'), isFalse);
    });

    test('3. sélection animation', () {
      final s = SurfaceStudioSelection.animation('water-loop');
      expect(s.isAnimation, isTrue);
      expect(s.isAtlas, isFalse);
      expect(s.isPreset, isFalse);
      expect(s.matchesAnimation('water-loop'), isTrue);
      expect(s.matchesAnimation('x'), isFalse);
    });

    test('4. sélection preset', () {
      final s = SurfaceStudioSelection.preset('water-surface');
      expect(s.isPreset, isTrue);
      expect(s.isAtlas, isFalse);
      expect(s.isAnimation, isFalse);
      expect(s.matchesPreset('water-surface'), isTrue);
      expect(s.matchesPreset('x'), isFalse);
    });

    test('5. id vide refusé', () {
      expect(
        () => SurfaceStudioSelection.atlas(''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => SurfaceStudioSelection.animation('   '),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => SurfaceStudioSelection.preset(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('6. égalité de valeur', () {
      expect(
        SurfaceStudioSelection.atlas('a'),
        SurfaceStudioSelection.atlas('a'),
      );
      expect(
        SurfaceStudioSelection.atlas('a'),
        isNot(equals(SurfaceStudioSelection.animation('a'))),
      );
      expect(
        SurfaceStudioSelection.atlas('a'),
        isNot(equals(SurfaceStudioSelection.atlas('b'))),
      );
    });

    test('7. hashCode cohérent', () {
      final a = SurfaceStudioSelection.atlas('a');
      final a2 = SurfaceStudioSelection.atlas('a');
      expect(a.hashCode, a2.hashCode);
    });
  });
}

```

## packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart

```dart
// Widget test — [SurfaceStudioSelectionSummary] (Lot 58).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_selection.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_selection_summary.dart';

void main() {
  testWidgets('résumé none + hint', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SurfaceStudioSelectionSummary(
          selection: SurfaceStudioSelection.none(),
        ),
      ),
    );
    expect(find.text('Aucune sélection'), findsOneWidget);
    expect(
      find.text('Sélectionnez un élément du catalogue pour l’inspecter.'),
      findsOneWidget,
    );
  });

  testWidgets('résumé atlas + id', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SurfaceStudioSelectionSummary(
          selection: SurfaceStudioSelection.atlas('water-atlas'),
        ),
      ),
    );
    expect(find.text('Atlas sélectionné'), findsOneWidget);
    expect(find.text('water-atlas'), findsOneWidget);
  });
}

```

## packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart

```dart
// Tests widget — sélection Surface Studio (Lot 58).
// `map_core` public uniquement.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_animation_detail_view.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_detail_view.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_catalog_browser.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_preset_detail_view.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_selection.dart';

void main() {
  group('Fiches sélectionnables (Lot 58)', () {
    testWidgets('8. atlas sans badge si none', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasDetailView(
            readModel: _oneWaterAtlasModel(),
            selection: const SurfaceStudioSelection.none(),
            onSelectionChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Atlas sélectionné'), findsNothing);
    });

    testWidgets('9. atlas affiche état sélectionné', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasDetailView(
            readModel: _oneWaterAtlasModel(),
            selection: SurfaceStudioSelection.atlas('water-atlas'),
            onSelectionChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Atlas sélectionné'), findsOneWidget);
    });

    testWidgets('10. tap atlas déclenche callback', (tester) async {
      SurfaceStudioSelection? captured;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasDetailView(
            readModel: _oneWaterAtlasModel(),
            selection: const SurfaceStudioSelection.none(),
            onSelectionChanged: (s) => captured = s,
          ),
        ),
      );
      await tester.tap(find.text('Water Atlas'));
      expect(
        captured,
        SurfaceStudioSelection.atlas('water-atlas'),
      );
    });

    testWidgets('11. animation affiche état sélectionné', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _minimalWaterModel(),
            selection: SurfaceStudioSelection.animation('water-isolated-loop'),
            onSelectionChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Animation sélectionnée'), findsOneWidget);
    });

    testWidgets('12. tap animation déclenche callback', (tester) async {
      SurfaceStudioSelection? captured;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _minimalWaterModel(),
            selection: const SurfaceStudioSelection.none(),
            onSelectionChanged: (s) => captured = s,
          ),
        ),
      );
      await tester.tap(find.text('Water Isolated Loop'));
      expect(
        captured,
        SurfaceStudioSelection.animation('water-isolated-loop'),
      );
    });

    testWidgets('13. preset affiche état sélectionné', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _minimalWaterModel(),
            selection: SurfaceStudioSelection.preset('water-surface'),
            onSelectionChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Preset sélectionné'), findsOneWidget);
    });

    testWidgets('14. tap preset déclenche callback', (tester) async {
      SurfaceStudioSelection? captured;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _minimalWaterModel(),
            selection: const SurfaceStudioSelection.none(),
            onSelectionChanged: (s) => captured = s,
          ),
        ),
      );
      final target = find.text('Water Surface');
      await tester.ensureVisible(target);
      await tester.pump();
      await tester.tap(target);
      expect(
        captured,
        SurfaceStudioSelection.preset('water-surface'),
      );
    });
  });

  group('SurfaceStudioCatalogBrowser sélection (Lot 58)', () {
    testWidgets('15. browser transmet sélection atlas', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: _minimalWaterModel(),
            selection: SurfaceStudioSelection.atlas('water-atlas'),
            onSelectionChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Atlas sélectionné'), findsOneWidget);
    });

    testWidgets('16. browser transmet sélection animation', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: _minimalWaterModel(),
            selection: SurfaceStudioSelection.animation('water-isolated-loop'),
            onSelectionChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Animation sélectionnée'), findsOneWidget);
    });

    testWidgets('17. browser transmet sélection preset', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: _minimalWaterModel(),
            selection: SurfaceStudioSelection.preset('water-surface'),
            onSelectionChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Preset sélectionné'), findsOneWidget);
    });

    testWidgets('18. browser remonte tap atlas', (tester) async {
      SurfaceStudioSelection? last;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: _minimalWaterModel(),
            selection: const SurfaceStudioSelection.none(),
            onSelectionChanged: (s) => last = s,
          ),
        ),
      );
      await tester.tap(find.text('Water Atlas'));
      expect(last, SurfaceStudioSelection.atlas('water-atlas'));
    });

    testWidgets('19. browser remonte tap animation', (tester) async {
      SurfaceStudioSelection? last;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: _minimalWaterModel(),
            selection: const SurfaceStudioSelection.none(),
            onSelectionChanged: (s) => last = s,
          ),
        ),
      );
      await tester.tap(find.text('Water Isolated Loop'));
      expect(last, SurfaceStudioSelection.animation('water-isolated-loop'));
    });

    testWidgets('20. browser remonte tap preset', (tester) async {
      SurfaceStudioSelection? last;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: _minimalWaterModel(),
            selection: const SurfaceStudioSelection.none(),
            onSelectionChanged: (s) => last = s,
          ),
        ),
      );
      final target = find.text('Water Surface');
      await tester.ensureVisible(target);
      await tester.pump();
      await tester.tap(target);
      expect(last, SurfaceStudioSelection.preset('water-surface'));
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

SurfaceStudioReadModel _oneWaterAtlasModel() {
  final g = SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
  final atlas = ProjectSurfaceAtlas(
    id: 'water-atlas',
    name: 'Water Atlas',
    tilesetId: 'nature-tileset',
    geometry: g,
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: [atlas],
      animations: const [],
      presets: const [],
    ),
  );
}

SurfaceStudioReadModel _minimalWaterModel() {
  final g = SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
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
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: [atlas],
      animations: [anim],
      presets: [preset],
    ),
  );
}

```

# Evidence Pack — B & C. Diffs complets (git)

## Diffs `git` — fichiers modifiés sous `packages/map_editor/`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_animation_detail_view.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_animation_detail_view.dart
index 88a0f27a..a16f1418 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_animation_detail_view.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_animation_detail_view.dart
@@ -9,6 +9,7 @@ import 'package:flutter/cupertino.dart';
 import 'package:map_core/map_core.dart';
 
 import '../../ui/shared/cupertino_editor_widgets.dart';
+import 'surface_studio_selection.dart';
 
 /// Textes visibles (aucun nom de type interne dans l’UI).
 class SurfaceStudioAnimationDetailViewLabels {
@@ -31,6 +32,8 @@ class SurfaceStudioAnimationDetailViewLabels {
   static const String categorieAucune = 'Aucune catégorie';
   static const String aucunAtlas = 'Aucun atlas référencé';
 
+  static const String badgeSelected = 'Animation sélectionnée';
+
   static String framesLigne(int n) {
     if (n <= 1) {
       return '1 frame';
@@ -54,10 +57,16 @@ class SurfaceStudioAnimationDetailView extends StatelessWidget {
   const SurfaceStudioAnimationDetailView({
     super.key,
     required this.readModel,
+    this.selection = const SurfaceStudioSelection.none(),
+    this.onSelectionChanged,
   });
 
   final SurfaceStudioReadModel readModel;
 
+  final SurfaceStudioSelection selection;
+
+  final ValueChanged<SurfaceStudioSelection>? onSelectionChanged;
+
   @override
   Widget build(BuildContext context) {
     final label = EditorChrome.primaryLabel(context);
@@ -103,6 +112,12 @@ class SurfaceStudioAnimationDetailView extends StatelessWidget {
                 row: row,
                 label: label,
                 subtle: subtle,
+                selected: selection.matchesAnimation(row.id),
+                onSelect: onSelectionChanged == null
+                    ? null
+                    : () => onSelectionChanged!(
+                          SurfaceStudioSelection.animation(row.id),
+                        ),
               ),
             ),
           ),
@@ -111,26 +126,44 @@ class SurfaceStudioAnimationDetailView extends StatelessWidget {
   }
 }
 
+const Color _kSelectionAccent = Color(0xFF2DD4BF);
+
 class _DetailCard extends StatelessWidget {
-  const _DetailCard({required this.child});
+  const _DetailCard({
+    required this.child,
+    this.selected = false,
+    this.onTap,
+  });
 
   final Widget child;
+  final bool selected;
+  final VoidCallback? onTap;
 
   @override
   Widget build(BuildContext context) {
-    return Container(
+    final baseBg = EditorChrome.elevatedPanelBackground(context);
+    final rim = EditorChrome.editorIslandRim(context);
+    final box = Container(
       padding: const EdgeInsets.all(14),
       decoration: BoxDecoration(
-        color: EditorChrome.elevatedPanelBackground(context),
+        color: selected ? Color.lerp(baseBg, _kSelectionAccent, 0.07)! : baseBg,
         borderRadius: BorderRadius.circular(14),
         border: Border.all(
-          color: EditorChrome.editorIslandRim(context),
-          width: 1,
+          color: selected ? Color.lerp(rim, _kSelectionAccent, 0.45)! : rim,
+          width: selected ? 1.2 : 1,
         ),
         boxShadow: EditorChrome.sectionCardShadows(context),
       ),
       child: child,
     );
+    if (onTap == null) {
+      return box;
+    }
+    return GestureDetector(
+      behavior: HitTestBehavior.opaque,
+      onTap: onTap,
+      child: box,
+    );
   }
 }
 
@@ -167,20 +200,38 @@ class _AnimationFiche extends StatelessWidget {
     required this.row,
     required this.label,
     required this.subtle,
+    this.selected = false,
+    this.onSelect,
   });
 
   final SurfaceStudioAnimationReadModel row;
   final Color label;
   final Color subtle;
+  final bool selected;
+  final VoidCallback? onSelect;
 
   @override
   Widget build(BuildContext context) {
     final refIds = row.referencedAtlasIds;
     final nAtlas = refIds.length;
     return _DetailCard(
+      selected: selected,
+      onTap: onSelect,
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
+          if (selected) ...[
+            const Text(
+              SurfaceStudioAnimationDetailViewLabels.badgeSelected,
+              style: TextStyle(
+                color: _kSelectionAccent,
+                fontSize: 11,
+                fontWeight: FontWeight.w800,
+                letterSpacing: 0.3,
+              ),
+            ),
+            const SizedBox(height: 6),
+          ],
           Text(
             row.name,
             style: TextStyle(
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_detail_view.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_detail_view.dart
index 54ec4457..359b51bd 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_detail_view.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_detail_view.dart
@@ -9,6 +9,7 @@ import 'package:flutter/cupertino.dart';
 import 'package:map_core/map_core.dart';
 
 import '../../ui/shared/cupertino_editor_widgets.dart';
+import 'surface_studio_selection.dart';
 
 /// Textes visibles (aucun nom de type de la couche domaine dans l’UI).
 class SurfaceStudioAtlasDetailViewLabels {
@@ -31,6 +32,8 @@ class SurfaceStudioAtlasDetailViewLabels {
   static const String labelUtilisation = 'Utilisation';
   static const String labelAnimationsUtilisatrices = 'Animations utilisatrices';
 
+  static const String badgeSelected = 'Atlas sélectionné';
+
   static const String categorieAucune = 'Aucune catégorie';
 
   static String tileCountLigne(int n) {
@@ -68,10 +71,17 @@ class SurfaceStudioAtlasDetailView extends StatelessWidget {
   const SurfaceStudioAtlasDetailView({
     super.key,
     required this.readModel,
+    this.selection = const SurfaceStudioSelection.none(),
+    this.onSelectionChanged,
   });
 
   final SurfaceStudioReadModel readModel;
 
+  /// État d’inspection local (panneau) ; ne notifie pas le catalogue.
+  final SurfaceStudioSelection selection;
+
+  final ValueChanged<SurfaceStudioSelection>? onSelectionChanged;
+
   @override
   Widget build(BuildContext context) {
     final label = EditorChrome.primaryLabel(context);
@@ -117,6 +127,12 @@ class SurfaceStudioAtlasDetailView extends StatelessWidget {
                 row: row,
                 label: label,
                 subtle: subtle,
+                selected: selection.matchesAtlas(row.id),
+                onSelect: onSelectionChanged == null
+                    ? null
+                    : () => onSelectionChanged!(
+                          SurfaceStudioSelection.atlas(row.id),
+                        ),
               ),
             ),
           ),
@@ -125,26 +141,44 @@ class SurfaceStudioAtlasDetailView extends StatelessWidget {
   }
 }
 
+const Color _kSelectionAccent = Color(0xFF2DD4BF);
+
 class _DetailCard extends StatelessWidget {
-  const _DetailCard({required this.child});
+  const _DetailCard({
+    required this.child,
+    this.selected = false,
+    this.onTap,
+  });
 
   final Widget child;
+  final bool selected;
+  final VoidCallback? onTap;
 
   @override
   Widget build(BuildContext context) {
-    return Container(
+    final baseBg = EditorChrome.elevatedPanelBackground(context);
+    final rim = EditorChrome.editorIslandRim(context);
+    final box = Container(
       padding: const EdgeInsets.all(14),
       decoration: BoxDecoration(
-        color: EditorChrome.elevatedPanelBackground(context),
+        color: selected ? Color.lerp(baseBg, _kSelectionAccent, 0.07)! : baseBg,
         borderRadius: BorderRadius.circular(14),
         border: Border.all(
-          color: EditorChrome.editorIslandRim(context),
-          width: 1,
+          color: selected ? Color.lerp(rim, _kSelectionAccent, 0.45)! : rim,
+          width: selected ? 1.2 : 1,
         ),
         boxShadow: EditorChrome.sectionCardShadows(context),
       ),
       child: child,
     );
+    if (onTap == null) {
+      return box;
+    }
+    return GestureDetector(
+      behavior: HitTestBehavior.opaque,
+      onTap: onTap,
+      child: box,
+    );
   }
 }
 
@@ -181,19 +215,37 @@ class _AtlasFiche extends StatelessWidget {
     required this.row,
     required this.label,
     required this.subtle,
+    this.selected = false,
+    this.onSelect,
   });
 
   final SurfaceStudioAtlasReadModel row;
   final Color label;
   final Color subtle;
+  final bool selected;
+  final VoidCallback? onSelect;
 
   @override
   Widget build(BuildContext context) {
     final nAnim = row.usedByAnimationIds.length;
     return _DetailCard(
+      selected: selected,
+      onTap: onSelect,
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
+          if (selected) ...[
+            const Text(
+              SurfaceStudioAtlasDetailViewLabels.badgeSelected,
+              style: TextStyle(
+                color: _kSelectionAccent,
+                fontSize: 11,
+                fontWeight: FontWeight.w800,
+                letterSpacing: 0.3,
+              ),
+            ),
+            const SizedBox(height: 6),
+          ],
           Text(
             row.name,
             style: TextStyle(
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart
index 7520c398..7e63bd73 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart
@@ -11,6 +11,7 @@ import '../../ui/shared/cupertino_editor_widgets.dart';
 import 'surface_studio_animation_detail_view.dart';
 import 'surface_studio_atlas_detail_view.dart';
 import 'surface_studio_preset_detail_view.dart';
+import 'surface_studio_selection.dart';
 
 /// Libellés visibles (aucun nom de type Dart interne).
 class SurfaceStudioCatalogBrowserLabels {
@@ -80,10 +81,17 @@ class SurfaceStudioCatalogBrowser extends StatelessWidget {
   const SurfaceStudioCatalogBrowser({
     super.key,
     required this.readModel,
+    this.selection = const SurfaceStudioSelection.none(),
+    this.onSelectionChanged,
   });
 
   final SurfaceStudioReadModel readModel;
 
+  /// Sélection d’inspection locale ; propagée aux fiches sans toucher au read model.
+  final SurfaceStudioSelection selection;
+
+  final ValueChanged<SurfaceStudioSelection>? onSelectionChanged;
+
   @override
   Widget build(BuildContext context) {
     final label = EditorChrome.primaryLabel(context);
@@ -122,11 +130,23 @@ class SurfaceStudioCatalogBrowser extends StatelessWidget {
           ),
           const SizedBox(height: 16),
         ],
-        SurfaceStudioAtlasDetailView(readModel: readModel),
+        SurfaceStudioAtlasDetailView(
+          readModel: readModel,
+          selection: selection,
+          onSelectionChanged: onSelectionChanged,
+        ),
         const SizedBox(height: 18),
-        SurfaceStudioAnimationDetailView(readModel: readModel),
+        SurfaceStudioAnimationDetailView(
+          readModel: readModel,
+          selection: selection,
+          onSelectionChanged: onSelectionChanged,
+        ),
         const SizedBox(height: 18),
-        SurfaceStudioPresetDetailView(readModel: readModel),
+        SurfaceStudioPresetDetailView(
+          readModel: readModel,
+          selection: selection,
+          onSelectionChanged: onSelectionChanged,
+        ),
       ],
     );
   }
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
index fc85f5ef..bd2e96dc 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
@@ -15,12 +15,14 @@ import 'package:map_core/map_core.dart';
 import '../../ui/shared/cupertino_editor_widgets.dart';
 import 'surface_studio_catalog_browser.dart';
 import 'surface_studio_diagnostics_view.dart';
+import 'surface_studio_selection.dart';
+import 'surface_studio_selection_summary.dart';
 
 /// Accent produit Surface Studio (même base que la tuile World Explorer).
 const Color _surfaceStudioAccent = Color(0xFF2DD4BF);
 
 /// Panneau présentationnel **lecture seule** pour Surface Studio.
-class SurfaceStudioPanel extends StatelessWidget {
+class SurfaceStudioPanel extends StatefulWidget {
   const SurfaceStudioPanel({
     super.key,
     required this.readModel,
@@ -38,9 +40,17 @@ class SurfaceStudioPanel extends StatelessWidget {
   static const String actionImportVerticalAtlasLabel =
       'Importer un atlas vertical';
 
+  @override
+  State<SurfaceStudioPanel> createState() => _SurfaceStudioPanelState();
+}
+
+class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
+  /// Sélection d’inspection : locale au widget, jamais écrite dans le manifest.
+  SurfaceStudioSelection _selection = const SurfaceStudioSelection.none();
+
   @override
   Widget build(BuildContext context) {
-    final s = readModel.summary;
+    final s = widget.readModel.summary;
     final label = EditorChrome.primaryLabel(context);
     final subtle = EditorChrome.subtleLabel(context);
 
@@ -56,7 +66,7 @@ class SurfaceStudioPanel extends StatelessWidget {
               const SizedBox(width: 12),
               Expanded(
                 child: Text(
-                  titleText,
+                  SurfaceStudioPanel.titleText,
                   style: TextStyle(
                     color: label,
                     fontSize: 22,
@@ -65,12 +75,12 @@ class SurfaceStudioPanel extends StatelessWidget {
                   ),
                 ),
               ),
-              const _ReadOnlyBadge(label: readOnlyBadgeText),
+              const _ReadOnlyBadge(label: SurfaceStudioPanel.readOnlyBadgeText),
             ],
           ),
           const SizedBox(height: 12),
           Text(
-            productDescriptionText,
+            SurfaceStudioPanel.productDescriptionText,
             style: TextStyle(
               color: subtle,
               fontSize: 13,
@@ -95,10 +105,18 @@ class SurfaceStudioPanel extends StatelessWidget {
             animations: s.animationCount,
             presets: s.presetCount,
           ),
+          const SizedBox(height: 12),
+          SurfaceStudioSelectionSummary(selection: _selection),
+          const SizedBox(height: 12),
+          SurfaceStudioCatalogBrowser(
+            readModel: widget.readModel,
+            selection: _selection,
+            onSelectionChanged: (v) {
+              setState(() => _selection = v);
+            },
+          ),
           const SizedBox(height: 16),
-          SurfaceStudioCatalogBrowser(readModel: readModel),
-          const SizedBox(height: 16),
-          SurfaceStudioDiagnosticsView(readModel: readModel),
+          SurfaceStudioDiagnosticsView(readModel: widget.readModel),
           const SizedBox(height: 20),
           const _FutureActions(
             onCreateAtlas: null,
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_preset_detail_view.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_preset_detail_view.dart
index be999f3c..ab920fbc 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_preset_detail_view.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_preset_detail_view.dart
@@ -9,6 +9,7 @@ import 'package:flutter/cupertino.dart';
 import 'package:map_core/map_core.dart';
 
 import '../../ui/shared/cupertino_editor_widgets.dart';
+import 'surface_studio_selection.dart';
 
 /// Libellé français pour [SurfaceVariantRole] (affichage auteur, pas le nom d’énum brut).
 String surfaceStudioSurfaceVariantRoleLabel(SurfaceVariantRole role) {
@@ -78,6 +79,8 @@ class SurfaceStudioPresetDetailViewLabels {
   static const String couverturePartielle = 'Rôles standards incomplets';
   static const String aucuneAnimLiee = 'Aucune animation liée';
 
+  static const String badgeSelected = 'Preset sélectionné';
+
   static String variantesLigne(int n) {
     if (n <= 1) {
       return '1 variante';
@@ -101,10 +104,16 @@ class SurfaceStudioPresetDetailView extends StatelessWidget {
   const SurfaceStudioPresetDetailView({
     super.key,
     required this.readModel,
+    this.selection = const SurfaceStudioSelection.none(),
+    this.onSelectionChanged,
   });
 
   final SurfaceStudioReadModel readModel;
 
+  final SurfaceStudioSelection selection;
+
+  final ValueChanged<SurfaceStudioSelection>? onSelectionChanged;
+
   @override
   Widget build(BuildContext context) {
     final label = EditorChrome.primaryLabel(context);
@@ -150,6 +159,12 @@ class SurfaceStudioPresetDetailView extends StatelessWidget {
                 row: row,
                 label: label,
                 subtle: subtle,
+                selected: selection.matchesPreset(row.id),
+                onSelect: onSelectionChanged == null
+                    ? null
+                    : () => onSelectionChanged!(
+                          SurfaceStudioSelection.preset(row.id),
+                        ),
               ),
             ),
           ),
@@ -158,26 +173,44 @@ class SurfaceStudioPresetDetailView extends StatelessWidget {
   }
 }
 
+const Color _kSelectionAccent = Color(0xFF2DD4BF);
+
 class _DetailCard extends StatelessWidget {
-  const _DetailCard({required this.child});
+  const _DetailCard({
+    required this.child,
+    this.selected = false,
+    this.onTap,
+  });
 
   final Widget child;
+  final bool selected;
+  final VoidCallback? onTap;
 
   @override
   Widget build(BuildContext context) {
-    return Container(
+    final baseBg = EditorChrome.elevatedPanelBackground(context);
+    final rim = EditorChrome.editorIslandRim(context);
+    final box = Container(
       padding: const EdgeInsets.all(14),
       decoration: BoxDecoration(
-        color: EditorChrome.elevatedPanelBackground(context),
+        color: selected ? Color.lerp(baseBg, _kSelectionAccent, 0.07)! : baseBg,
         borderRadius: BorderRadius.circular(14),
         border: Border.all(
-          color: EditorChrome.editorIslandRim(context),
-          width: 1,
+          color: selected ? Color.lerp(rim, _kSelectionAccent, 0.45)! : rim,
+          width: selected ? 1.2 : 1,
         ),
         boxShadow: EditorChrome.sectionCardShadows(context),
       ),
       child: child,
     );
+    if (onTap == null) {
+      return box;
+    }
+    return GestureDetector(
+      behavior: HitTestBehavior.opaque,
+      onTap: onTap,
+      child: box,
+    );
   }
 }
 
@@ -214,11 +247,15 @@ class _PresetFiche extends StatelessWidget {
     required this.row,
     required this.label,
     required this.subtle,
+    this.selected = false,
+    this.onSelect,
   });
 
   final SurfaceStudioPresetReadModel row;
   final Color label;
   final Color subtle;
+  final bool selected;
+  final VoidCallback? onSelect;
 
   @override
   Widget build(BuildContext context) {
@@ -226,9 +263,23 @@ class _PresetFiche extends StatelessWidget {
     final nAnim = animIds.length;
     final roleLabels = row.roles.map(surfaceStudioSurfaceVariantRoleLabel);
     return _DetailCard(
+      selected: selected,
+      onTap: onSelect,
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
+          if (selected) ...[
+            const Text(
+              SurfaceStudioPresetDetailViewLabels.badgeSelected,
+              style: TextStyle(
+                color: _kSelectionAccent,
+                fontSize: 11,
+                fontWeight: FontWeight.w800,
+                letterSpacing: 0.3,
+              ),
+            ),
+            const SizedBox(height: 6),
+          ],
           Text(
             row.name,
             style: TextStyle(
diff --git a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
index b7249e85..074201c1 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
@@ -289,6 +289,112 @@ void main() {
       expect(find.text('Diagnostics Surface'), findsOneWidget);
     });
 
+    testWidgets('58.21 — Aucune sélection au départ (catalogue minimal)',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.text('Aucune sélection'), findsOneWidget);
+    });
+
+    testWidgets('58.22 — sélection atlas après tap', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Atlas'));
+      await tester.tap(find.text('Water Atlas'));
+      await tester.pump();
+      expect(find.text('Atlas sélectionné'), findsWidgets);
+      expect(find.text('water-atlas'), findsWidgets);
+    });
+
+    testWidgets('58.23 — sélection animation après tap', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Isolated Loop'));
+      await tester.tap(find.text('Water Isolated Loop'));
+      await tester.pump();
+      expect(find.text('Animation sélectionnée'), findsWidgets);
+      expect(find.text('water-isolated-loop'), findsWidgets);
+    });
+
+    testWidgets('58.24 — sélection preset après tap', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Surface'));
+      await tester.tap(find.text('Water Surface'));
+      await tester.pump();
+      expect(find.text('Preset sélectionné'), findsWidgets);
+      expect(find.text('water-surface'), findsWidgets);
+    });
+
+    testWidgets('58.25 — changement de sélection remplace la précédente',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Atlas'));
+      await tester.tap(find.text('Water Atlas'));
+      await tester.pump();
+      await tester.ensureVisible(find.text('Water Isolated Loop'));
+      await tester.tap(find.text('Water Isolated Loop'));
+      await tester.pump();
+      expect(find.text('Animation sélectionnée'), findsWidgets);
+      final t = tester
+          .widgetList<Text>(find.byType(Text))
+          .map((e) => e.data ?? '')
+          .join('\n');
+      expect(t.contains('Atlas sélectionné'), isFalse);
+    });
+
+    testWidgets('58.26 — sélection ne mute pas surfaceCatalog', (tester) async {
+      final cat = _minimalWaterCatalog();
+      final manifest = _manifest(cat);
+      final before = manifest.surfaceCatalog;
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
+      );
+      await tester.ensureVisible(find.text('Water Atlas'));
+      await tester.tap(find.text('Water Atlas'));
+      await tester.pump();
+      await tester.ensureVisible(find.text('Water Surface'));
+      await tester.tap(find.text('Water Surface'));
+      await tester.pump();
+      expect(identical(manifest.surfaceCatalog, before), isTrue);
+    });
+
+    testWidgets('58.27 — pas de TextField après sélections', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Atlas'));
+      await tester.tap(find.text('Water Atlas'));
+      await tester.pump();
+      expect(find.byType(TextField), findsNothing);
+    });
+
+    testWidgets('58.28 — pas de libellés édition/save actifs', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Atlas'));
+      await tester.tap(find.text('Water Atlas'));
+      await tester.pump();
+      for (final s in <String>[
+        'Sauvegarder',
+        'Enregistrer',
+        'Modifier',
+        'Supprimer',
+        'Save',
+        'Edit',
+        'Delete',
+      ]) {
+        expect(find.text(s), findsNothing);
+      }
+    });
+
     testWidgets('30. Lot 55 — surfaceCatalog unchanged after panel pump',
         (tester) async {
       final cat = _minimalWaterCatalog();

```

## Diffs `git diff --no-index /dev/null` — fichiers nouveaux

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_selection.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_selection.dart
new file mode 100644
index 00000000..767d3dfc
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_selection.dart
@@ -0,0 +1,77 @@
+// État de sélection **UI local** Surface Studio (Lot 58).
+//
+// Aucun Flutter, aucun map_core, aucun JSON, aucune persistance : value object
+// pur pour le panneau. Ne décrit pas le catalogue — ne le mutera jamais.
+
+/// Rôle d’une entrée sélectionnée dans le browser Surface Studio.
+enum SurfaceStudioSelectionKind {
+  atlas,
+  animation,
+  preset,
+}
+
+/// Sélection auteur côté éditeur (inspection / futur inspector), jamais persistée.
+class SurfaceStudioSelection {
+  const SurfaceStudioSelection._(this._kind, this._id);
+
+  final SurfaceStudioSelectionKind? _kind;
+  final String? _id;
+
+  /// Aucun atlas / animation / preset mis en surbrillance.
+  const SurfaceStudioSelection.none()
+      : _kind = null,
+        _id = null;
+
+  /// [id] rejeté si vide ou uniquement des espaces (après trim).
+  factory SurfaceStudioSelection.atlas(String id) {
+    final t = id.trim();
+    if (t.isEmpty) {
+      throw ArgumentError.value(id, 'id', 'atlas id must be non-empty');
+    }
+    return SurfaceStudioSelection._(SurfaceStudioSelectionKind.atlas, t);
+  }
+
+  factory SurfaceStudioSelection.animation(String id) {
+    final t = id.trim();
+    if (t.isEmpty) {
+      throw ArgumentError.value(id, 'id', 'animation id must be non-empty');
+    }
+    return SurfaceStudioSelection._(SurfaceStudioSelectionKind.animation, t);
+  }
+
+  factory SurfaceStudioSelection.preset(String id) {
+    final t = id.trim();
+    if (t.isEmpty) {
+      throw ArgumentError.value(id, 'id', 'preset id must be non-empty');
+    }
+    return SurfaceStudioSelection._(SurfaceStudioSelectionKind.preset, t);
+  }
+
+  SurfaceStudioSelectionKind? get kind => _kind;
+
+  String? get id => _id;
+
+  bool get isNone => _kind == null;
+
+  bool get isAtlas => _kind == SurfaceStudioSelectionKind.atlas;
+
+  bool get isAnimation => _kind == SurfaceStudioSelectionKind.animation;
+
+  bool get isPreset => _kind == SurfaceStudioSelectionKind.preset;
+
+  bool matchesAtlas(String id) => isAtlas && _id == id.trim();
+
+  bool matchesAnimation(String id) => isAnimation && _id == id.trim();
+
+  bool matchesPreset(String id) => isPreset && _id == id.trim();
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is SurfaceStudioSelection &&
+          _kind == other._kind &&
+          _id == other._id;
+
+  @override
+  int get hashCode => Object.hash(_kind, _id);
+}
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_selection_summary.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_selection_summary.dart
new file mode 100644
index 00000000..4ab8a3d1
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_selection_summary.dart
@@ -0,0 +1,117 @@
+// Résumé de la sélection Surface Studio (Lot 58) — **présentation seule**.
+//
+// Reflète l’état [SurfaceStudioSelection] tenu par le panneau : aucune édition,
+// aucun catalogue, pas de persistance, pas de provider.
+
+import 'package:flutter/cupertino.dart';
+
+import '../../ui/shared/cupertino_editor_widgets.dart';
+import 'surface_studio_selection.dart';
+
+/// En-têtes de résumé visibles (pas de noms de types internes).
+class SurfaceStudioSelectionSummaryLabels {
+  const SurfaceStudioSelectionSummaryLabels._();
+
+  static const String hint =
+      'Sélectionnez un élément du catalogue pour l’inspecter.';
+
+  static const String none = 'Aucune sélection';
+
+  static const String lineAtlas = 'Atlas sélectionné';
+  static const String lineAnimation = 'Animation sélectionnée';
+  static const String linePreset = 'Preset sélectionné';
+}
+
+/// Bloc read-only : ligne d’état + id + texte d’aide.
+class SurfaceStudioSelectionSummary extends StatelessWidget {
+  const SurfaceStudioSelectionSummary({
+    super.key,
+    required this.selection,
+  });
+
+  final SurfaceStudioSelection selection;
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+    const accent = Color(0xFF2DD4BF);
+
+    return Container(
+      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
+      decoration: BoxDecoration(
+        color: EditorChrome.elevatedPanelBackground(context),
+        borderRadius: BorderRadius.circular(14),
+        border: Border.all(
+          color: selection.isNone
+              ? EditorChrome.editorIslandRim(context)
+              : Color.lerp(
+                  EditorChrome.editorIslandRim(context),
+                  accent,
+                  0.45,
+                )!,
+          width: selection.isNone ? 1 : 1.2,
+        ),
+        boxShadow: EditorChrome.sectionCardShadows(context),
+      ),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          if (selection.isNone) ...[
+            Text(
+              SurfaceStudioSelectionSummaryLabels.none,
+              style: TextStyle(
+                color: subtle,
+                fontSize: 14,
+                fontWeight: FontWeight.w600,
+                fontStyle: FontStyle.italic,
+              ),
+            ),
+          ] else ...[
+            Text(
+              _kindLine(selection),
+              style: const TextStyle(
+                color: accent,
+                fontSize: 12,
+                fontWeight: FontWeight.w800,
+                letterSpacing: 0.2,
+              ),
+            ),
+            const SizedBox(height: 4),
+            Text(
+              selection.id!,
+              style: TextStyle(
+                color: label,
+                fontSize: 15,
+                fontWeight: FontWeight.w700,
+              ),
+            ),
+          ],
+          const SizedBox(height: 8),
+          Text(
+            SurfaceStudioSelectionSummaryLabels.hint,
+            style: TextStyle(
+              color: subtle,
+              fontSize: 12,
+              fontWeight: FontWeight.w500,
+              height: 1.35,
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+String _kindLine(SurfaceStudioSelection s) {
+  if (s.isAtlas) {
+    return SurfaceStudioSelectionSummaryLabels.lineAtlas;
+  }
+  if (s.isAnimation) {
+    return SurfaceStudioSelectionSummaryLabels.lineAnimation;
+  }
+  if (s.isPreset) {
+    return SurfaceStudioSelectionSummaryLabels.linePreset;
+  }
+  return SurfaceStudioSelectionSummaryLabels.none;
+}
diff --git a/packages/map_editor/test/surface_studio/surface_studio_selection_test.dart b/packages/map_editor/test/surface_studio/surface_studio_selection_test.dart
new file mode 100644
index 00000000..f7729236
--- /dev/null
+++ b/packages/map_editor/test/surface_studio/surface_studio_selection_test.dart
@@ -0,0 +1,77 @@
+// Tests unitaires — modèle [SurfaceStudioSelection] (Lot 58, pur Dart via flutter_test).
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_selection.dart';
+
+void main() {
+  group('SurfaceStudioSelection (Lot 58 model)', () {
+    test('1. none — aucune sélection', () {
+      const s = SurfaceStudioSelection.none();
+      expect(s.isNone, isTrue);
+      expect(s.kind, isNull);
+      expect(s.id, isNull);
+    });
+
+    test('2. sélection atlas', () {
+      final s = SurfaceStudioSelection.atlas('water-atlas');
+      expect(s.isAtlas, isTrue);
+      expect(s.isAnimation, isFalse);
+      expect(s.isPreset, isFalse);
+      expect(s.matchesAtlas('water-atlas'), isTrue);
+      expect(s.matchesAtlas('other'), isFalse);
+    });
+
+    test('3. sélection animation', () {
+      final s = SurfaceStudioSelection.animation('water-loop');
+      expect(s.isAnimation, isTrue);
+      expect(s.isAtlas, isFalse);
+      expect(s.isPreset, isFalse);
+      expect(s.matchesAnimation('water-loop'), isTrue);
+      expect(s.matchesAnimation('x'), isFalse);
+    });
+
+    test('4. sélection preset', () {
+      final s = SurfaceStudioSelection.preset('water-surface');
+      expect(s.isPreset, isTrue);
+      expect(s.isAtlas, isFalse);
+      expect(s.isAnimation, isFalse);
+      expect(s.matchesPreset('water-surface'), isTrue);
+      expect(s.matchesPreset('x'), isFalse);
+    });
+
+    test('5. id vide refusé', () {
+      expect(
+        () => SurfaceStudioSelection.atlas(''),
+        throwsA(isA<ArgumentError>()),
+      );
+      expect(
+        () => SurfaceStudioSelection.animation('   '),
+        throwsA(isA<ArgumentError>()),
+      );
+      expect(
+        () => SurfaceStudioSelection.preset(''),
+        throwsA(isA<ArgumentError>()),
+      );
+    });
+
+    test('6. égalité de valeur', () {
+      expect(
+        SurfaceStudioSelection.atlas('a'),
+        SurfaceStudioSelection.atlas('a'),
+      );
+      expect(
+        SurfaceStudioSelection.atlas('a'),
+        isNot(equals(SurfaceStudioSelection.animation('a'))),
+      );
+      expect(
+        SurfaceStudioSelection.atlas('a'),
+        isNot(equals(SurfaceStudioSelection.atlas('b'))),
+      );
+    });
+
+    test('7. hashCode cohérent', () {
+      final a = SurfaceStudioSelection.atlas('a');
+      final a2 = SurfaceStudioSelection.atlas('a');
+      expect(a.hashCode, a2.hashCode);
+    });
+  });
+}
diff --git a/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart b/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart
new file mode 100644
index 00000000..3433398f
--- /dev/null
+++ b/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart
@@ -0,0 +1,34 @@
+// Widget test — [SurfaceStudioSelectionSummary] (Lot 58).
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_selection.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_selection_summary.dart';
+
+void main() {
+  testWidgets('résumé none + hint', (tester) async {
+    await tester.pumpWidget(
+      const MaterialApp(
+        home: SurfaceStudioSelectionSummary(
+          selection: SurfaceStudioSelection.none(),
+        ),
+      ),
+    );
+    expect(find.text('Aucune sélection'), findsOneWidget);
+    expect(
+      find.text('Sélectionnez un élément du catalogue pour l’inspecter.'),
+      findsOneWidget,
+    );
+  });
+
+  testWidgets('résumé atlas + id', (tester) async {
+    await tester.pumpWidget(
+      MaterialApp(
+        home: SurfaceStudioSelectionSummary(
+          selection: SurfaceStudioSelection.atlas('water-atlas'),
+        ),
+      ),
+    );
+    expect(find.text('Atlas sélectionné'), findsOneWidget);
+    expect(find.text('water-atlas'), findsOneWidget);
+  });
+}
diff --git a/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart b/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart
new file mode 100644
index 00000000..28dd4921
--- /dev/null
+++ b/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart
@@ -0,0 +1,287 @@
+// Tests widget — sélection Surface Studio (Lot 58).
+// `map_core` public uniquement.
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_animation_detail_view.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_detail_view.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_catalog_browser.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_preset_detail_view.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_selection.dart';
+
+void main() {
+  group('Fiches sélectionnables (Lot 58)', () {
+    testWidgets('8. atlas sans badge si none', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasDetailView(
+            readModel: _oneWaterAtlasModel(),
+            selection: const SurfaceStudioSelection.none(),
+            onSelectionChanged: (_) {},
+          ),
+        ),
+      );
+      expect(find.text('Atlas sélectionné'), findsNothing);
+    });
+
+    testWidgets('9. atlas affiche état sélectionné', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasDetailView(
+            readModel: _oneWaterAtlasModel(),
+            selection: SurfaceStudioSelection.atlas('water-atlas'),
+            onSelectionChanged: (_) {},
+          ),
+        ),
+      );
+      expect(find.text('Atlas sélectionné'), findsOneWidget);
+    });
+
+    testWidgets('10. tap atlas déclenche callback', (tester) async {
+      SurfaceStudioSelection? captured;
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasDetailView(
+            readModel: _oneWaterAtlasModel(),
+            selection: const SurfaceStudioSelection.none(),
+            onSelectionChanged: (s) => captured = s,
+          ),
+        ),
+      );
+      await tester.tap(find.text('Water Atlas'));
+      expect(
+        captured,
+        SurfaceStudioSelection.atlas('water-atlas'),
+      );
+    });
+
+    testWidgets('11. animation affiche état sélectionné', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAnimationDetailView(
+            readModel: _minimalWaterModel(),
+            selection: SurfaceStudioSelection.animation('water-isolated-loop'),
+            onSelectionChanged: (_) {},
+          ),
+        ),
+      );
+      expect(find.text('Animation sélectionnée'), findsOneWidget);
+    });
+
+    testWidgets('12. tap animation déclenche callback', (tester) async {
+      SurfaceStudioSelection? captured;
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAnimationDetailView(
+            readModel: _minimalWaterModel(),
+            selection: const SurfaceStudioSelection.none(),
+            onSelectionChanged: (s) => captured = s,
+          ),
+        ),
+      );
+      await tester.tap(find.text('Water Isolated Loop'));
+      expect(
+        captured,
+        SurfaceStudioSelection.animation('water-isolated-loop'),
+      );
+    });
+
+    testWidgets('13. preset affiche état sélectionné', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPresetDetailView(
+            readModel: _minimalWaterModel(),
+            selection: SurfaceStudioSelection.preset('water-surface'),
+            onSelectionChanged: (_) {},
+          ),
+        ),
+      );
+      expect(find.text('Preset sélectionné'), findsOneWidget);
+    });
+
+    testWidgets('14. tap preset déclenche callback', (tester) async {
+      SurfaceStudioSelection? captured;
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioPresetDetailView(
+            readModel: _minimalWaterModel(),
+            selection: const SurfaceStudioSelection.none(),
+            onSelectionChanged: (s) => captured = s,
+          ),
+        ),
+      );
+      final target = find.text('Water Surface');
+      await tester.ensureVisible(target);
+      await tester.pump();
+      await tester.tap(target);
+      expect(
+        captured,
+        SurfaceStudioSelection.preset('water-surface'),
+      );
+    });
+  });
+
+  group('SurfaceStudioCatalogBrowser sélection (Lot 58)', () {
+    testWidgets('15. browser transmet sélection atlas', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioCatalogBrowser(
+            readModel: _minimalWaterModel(),
+            selection: SurfaceStudioSelection.atlas('water-atlas'),
+            onSelectionChanged: (_) {},
+          ),
+        ),
+      );
+      expect(find.text('Atlas sélectionné'), findsOneWidget);
+    });
+
+    testWidgets('16. browser transmet sélection animation', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioCatalogBrowser(
+            readModel: _minimalWaterModel(),
+            selection: SurfaceStudioSelection.animation('water-isolated-loop'),
+            onSelectionChanged: (_) {},
+          ),
+        ),
+      );
+      expect(find.text('Animation sélectionnée'), findsOneWidget);
+    });
+
+    testWidgets('17. browser transmet sélection preset', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioCatalogBrowser(
+            readModel: _minimalWaterModel(),
+            selection: SurfaceStudioSelection.preset('water-surface'),
+            onSelectionChanged: (_) {},
+          ),
+        ),
+      );
+      expect(find.text('Preset sélectionné'), findsOneWidget);
+    });
+
+    testWidgets('18. browser remonte tap atlas', (tester) async {
+      SurfaceStudioSelection? last;
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioCatalogBrowser(
+            readModel: _minimalWaterModel(),
+            selection: const SurfaceStudioSelection.none(),
+            onSelectionChanged: (s) => last = s,
+          ),
+        ),
+      );
+      await tester.tap(find.text('Water Atlas'));
+      expect(last, SurfaceStudioSelection.atlas('water-atlas'));
+    });
+
+    testWidgets('19. browser remonte tap animation', (tester) async {
+      SurfaceStudioSelection? last;
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioCatalogBrowser(
+            readModel: _minimalWaterModel(),
+            selection: const SurfaceStudioSelection.none(),
+            onSelectionChanged: (s) => last = s,
+          ),
+        ),
+      );
+      await tester.tap(find.text('Water Isolated Loop'));
+      expect(last, SurfaceStudioSelection.animation('water-isolated-loop'));
+    });
+
+    testWidgets('20. browser remonte tap preset', (tester) async {
+      SurfaceStudioSelection? last;
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioCatalogBrowser(
+            readModel: _minimalWaterModel(),
+            selection: const SurfaceStudioSelection.none(),
+            onSelectionChanged: (s) => last = s,
+          ),
+        ),
+      );
+      final target = find.text('Water Surface');
+      await tester.ensureVisible(target);
+      await tester.pump();
+      await tester.tap(target);
+      expect(last, SurfaceStudioSelection.preset('water-surface'));
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
+SurfaceStudioReadModel _oneWaterAtlasModel() {
+  final g = SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
+    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+  );
+  final atlas = ProjectSurfaceAtlas(
+    id: 'water-atlas',
+    name: 'Water Atlas',
+    tilesetId: 'nature-tileset',
+    geometry: g,
+  );
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: [atlas],
+      animations: const [],
+      presets: const [],
+    ),
+  );
+}
+
+SurfaceStudioReadModel _minimalWaterModel() {
+  final g = SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
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
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: [atlas],
+      animations: [anim],
+      presets: [preset],
+    ),
+  );
+}

```

## Note sur le rapport (self-reference)

Le diff « `/dev/null` → ce fichier Markdown » serait sémantiquement identique au contenu de ce document avec préfixe `+` sur chaque ligne ; le contenu intégral est la section « Evidence Pack — A » et les diffs B/C ci-dessus plutôt que de dupliquer la pleine page en diff.

## `git status --short --untracked-files=all` — final

(Exécuté après génération de ce rapport ; `??` inclut ce fichier.)

```
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_animation_detail_view.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_detail_view.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_preset_detail_view.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_selection.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_selection_summary.dart
?? packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_selection_test.dart
?? reports/surface/surface_engine_lot_58_surface_studio_selection_state.md
```

