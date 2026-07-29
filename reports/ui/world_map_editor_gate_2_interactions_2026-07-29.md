# World Map Editor — Gate 2 Interactions

Date de clôture : 2026-07-29

Verdict : **DONE**

Lots couverts :

- `INT-01` — arbitrage exclusif des interactions et rollback ;
- `INT-02` — navigation desktop complète ;
- `INT-03` — empreinte de gomme indépendante et visible.

Branche : `main`

Base fonctionnelle Gate 2 : `654543012`
HEAD code avant le présent Evidence Pack : `6a295bce037a080ff83b1e5585d5aaecd800785c`

## 1. Résumé de clôture

Gate 2 remplace les interactions concurrentes du canvas par une seule session
propriétaire, sépare la navigation des mutations de carte et donne à la gomme
une empreinte explicite qui vaut `1×1` par défaut.

Le résultat livré garantit notamment :

- une interaction transitoire possède au plus un pointeur et une seule issue,
  `commit` ou `rollback` ;
- `Escape`, `PointerCancel`, la perte de focus, un second pointeur ou un
  changement de boutons invalide restaurent exactement le checkpoint ;
- molette et pan trackpad déplacent la vue sans peindre ;
- `Cmd/Ctrl + molette` zoome sous le pointeur ;
- le pinch natif combine pan et zoom à partir d'un snapshot absolu, sans dérive ;
- `Space + clic principal` et le bouton du milieu déplacent la vue ;
- le clic droit reste réservé aux futures actions contextuelles ;
- les commandes `Fit`, `100 %`, recentrage, zoom arrière et zoom avant sont
  accessibles sur le canvas, au clavier et aux tailles desktop testées ;
- la gomme ne réutilise plus implicitement la taille du dernier objet ;
- les modes `1×1`, `pinceau précédent` figé et `personnalisé` sont visibles,
  bornés et partagés par la preview et le commit ;
- sauvegarde, undo et redo ne peuvent plus interférer avec une transaction de
  canvas encore active.

Statut proposé : **Gate 2 DONE, sans réserve bloquante**.

## 2. Source de vérité et critères de sortie

Le plan exécuté est :

[2026-07-29-world-map-gate-2-interactions.md](/Users/karim/Project/pokemonProject/docs/superpowers/plans/2026-07-29-world-map-gate-2-interactions.md)

Ce plan est volontairement ignoré par `/docs/*` dans `.gitignore`. Il reste
référencé et figé par SHA-256 dans la section 7.

| Lot | Critère principal | Preuve de sortie |
|---|---|---|
| `INT-01` | un propriétaire, une issue terminale, rollback exact | contrôleur pur, checkpoint historique, tests pointeur/widget |
| `INT-02` | naviguer ne mute jamais `MapData` | math viewport pure, routage wheel/pan/pinch, contrôles DS |
| `INT-03` | gomme indépendante, visible, `1×1` par défaut | union immutable, resolver commun preview/commit, dialogue DS |
| clôture | pas de faille inter-lots | interlock save/undo/redo, mixed-buttons, focus/a11y, responsive |

## 3. Audit initial et passes indépendantes

### 3.1 Audit initial

L'audit de départ a confirmé les défauts produit décrits par l'utilisateur :

1. plusieurs chemins d'entrée pouvaient se disputer un même geste ;
2. le pan pouvait tomber dans un chemin de peinture ;
3. la molette n'avait pas un contrat desktop explicite ;
4. le pinch natif n'avait pas de snapshot absolu unifié ;
5. l'annulation d'un geste ne restaurait pas partout l'état exact ;
6. la gomme héritait implicitement de la taille du pinceau actif ;
7. la preview et le commit d'effacement n'avaient pas un resolver unique ;
8. les commandes de navigation n'offraient pas une surface visible et
   accessible cohérente.

Verdict initial : **FAIL / Gate 2 non livrable**.

### 3.2 Revues de `INT-01`

La revue de contrat a validé :

- la table d'états explicite ;
- l'unicité du pointeur propriétaire ;
- l'idempotence terminale ;
- le rollback exact de la carte, du dirty state et de l'historique ;
- un stroke committé égal à une seule entrée undo ;
- le rejet du second pointeur et des entrées concurrentes.

Verdict final `INT-01` : **APPROVE**.

### 3.3 Revues de `INT-02`

Une première revue a trouvé un défaut **HIGH** : `localPan` était traité comme
une position alors qu'il s'agit d'un delta transformé. Un canvas décalé pouvait
donc polluer le pan natif.

Correction :

```text
PointerEvent.transformDeltaViaPositions(
  transform,
  event.pan,
  event.position,
  event.localPosition,
)
```

La seconde revue a validé l'ancrage du zoom, le snapshot pinch absolu, le
réservé clic droit, les raccourcis et les contrôles DS.

Verdict final `INT-02` : **APPROVE**.

### 3.4 Revues de `INT-03`

Une première revue a trouvé un défaut **HIGH** : l'empreinte active ne faisait
pas partie de la clé d'identité de la cible de geste. Un changement en cours de
drag pouvait donc conserver un contexte obsolète.

La régression a été reproduite en RED, puis l'identité de cible a intégré
l'empreinte figée. Toute modification de l'empreinte pendant le drag annule
maintenant la transaction et restaure le checkpoint.

Les revues domaine et UI ont ensuite validé :

- le défaut `1×1` ;
- le snapshot immuable du pinceau précédent ;
- les dimensions personnalisées `1..16` ;
- l'égalité preview/commit ;
- le clipping aux bords ;
- Tile, Collision, Terrain, Path et Surface ;
- le no-op sans entrée d'historique ;
- le dialogue, le libellé et le badge issus du design system.

Verdict final `INT-03` : **APPROVE**.

### 3.5 Audit d'architecture de clôture

La première passe de clôture a trouvé un défaut **HIGH** transversal :
`saveActiveMap`, `undoMap` et `redoMap` pouvaient agir alors qu'un
`mapStrokeStart` était encore actif. Les conséquences possibles étaient :

- persistance d'une carte partielle ;
- suppression du checkpoint sous le contrôleur de geste ;
- séparation incorrecte d'un stroke dans l'historique ;
- perte du redo.

Des tests RED ont démontré les trois comportements. Le correctif :

- refuse save/undo/redo pendant le stroke ;
- désactive leurs sélecteurs UI ;
- interdit un `partOfStroke` orphelin ;
- conserve carte, historique, preview et dirty state byte-for-byte.

Verdict après correction : **APPROVE**.

### 3.6 Audit UX, accessibilité et responsive

Trois défauts **HIGH** supplémentaires ont été reproduits :

1. `primary -> primary|secondary` pouvait committer une peinture partielle ou
   déplacer la vue avec un delta mixte ;
2. un `Focus` invisible du canvas entrait dans l'ordre Tab et l'activation
   clavier des commandes volait le focus ;
3. les cinq commandes de navigation pouvaient être clippées à `800×600` et au
   breakpoint `1000×800`.

Les trois correctifs ont été développés en TDD :

- égalité exacte des boutons pendant toute la session et annulation avant
  propagation du delta mixte ;
- canvas hors traversal/semantics, focus visible conservé pour Enter/Espace,
  retour du focus canvas après activation pointeur ;
- overlay borné dans le canvas et variantes DS label/compact avec `Wrap`.

Résultats des passes spécialisées :

- mixed-buttons : rollback exact de la peinture et arrêt du pan ;
- focus/a11y : `+21`, tous verts avec le guardrail ;
- responsive : `+37`, tous verts avec le guardrail ;
- critique finale sur les huit fichiers de remédiation : **APPROVE**, aucun
  Blocker, High ou Medium.

### 3.7 Matrice explicite des rôles de sub-agents

| Rôle obligatoire | Passe / périmètre | Résultat | Verdict |
|---|---|---|---|
| Audit / Architecture | contrats `INT-01..03`, puis interlock transversal | défauts High reproduits et corrigés ; re-revues sans High/Medium | **APPROVE** |
| Implémentation | trois lots, puis remédiations mixed-buttons, focus et responsive | TDD RED/GREEN, commits isolés, scope Gate 2 uniquement | **PASS** |
| Tests | inventaire final des 17 fichiers de tests, positifs/négatifs/garde-fous/non-régressions | aucun gap High/Medium ; gaps Low documentés | **PASS** |
| Build / Validation | binaire macOS, signature, analyse, tests courts, diff et worktree scopé | binaire arm64 valide, `+7`, analyse propre, zéro chemin Gate 2 sale | **PASS** |
| Critique finale | code de remédiation puis Evidence Pack | code approuvé ; première passe documentaire refusée, puis annexes et état Git corrigés et revalidés | **APPROVE** |

## 4. Décisions d'architecture

### 4.1 Propriété des interactions

```text
idle
  -> pendingPrimary
  -> paintingStroke | drawingZone | borderGesture

idle
  -> panning

idle
  -> trackpadPanZoom

chaque session
  -> commit une fois
  -> ou rollback une fois
```

Le contrôleur pur décide. `MapCanvas` route les événements. Les mutations
restent dans `EditorNotifier` et les contrôleurs d'édition existants.

### 4.2 Checkpoint et historique

Le checkpoint contient désormais la carte et le dirty state nécessaires à une
restauration exacte. Il n'est ni transformé en undo ni supprimé par une
commande globale tant que le geste est actif.

### 4.3 Navigation pure

`MapViewportNavigation` centralise :

- pan ;
- zoom sous un ancrage local ;
- pan + zoom absolus depuis un snapshot ;
- Fit avec padding et clamps ;
- retour à `100 %` ;
- recentrage au zoom courant.

Les gestes de navigation n'entrent jamais dans les opérations `MapData`.

### 4.4 Empreinte de gomme

```text
singleTile     -> 1×1
previousBrush  -> snapshot capturé une fois
custom         -> largeur/hauteur validées dans 1..16
```

La même empreinte résolue alimente la preview et la mutation. Collision garde
sa taille de pinceau uniquement pour la peinture.

### 4.5 Design system

Les nouvelles surfaces produit utilisent `PokeMapButton`,
`PokeMapIconButton`, `PokeMapBadge`, `PokeMapCard`, les dialogues et les tokens
du design system. La recherche dans le diff final ne trouve aucune nouvelle
couleur produit directe.

## 5. Inventaire complet des fichiers Gate 2

Diff mesuré entre la base Gate 2 `654543012` et le code final `6a295bce0` :

```text
35 files changed, 7498 insertions(+), 314 deletions(-)
```

### 5.1 Production

| Statut | Fichier | Zone précise / impact |
|---|---|---|
| M | `lib/src/application/models/map_history_snapshot.dart` | snapshot carte + dirty state |
| M | `lib/src/application/models/map_history_snapshot.freezed.dart` | génération du snapshot enrichi |
| M | `lib/src/application/services/editor_map_mutation_coordinator.dart` | début/fin/rollback de stroke |
| M | `lib/src/application/services/map_history_coordinator.dart` | checkpoint, rejet du `partOfStroke` orphelin |
| A | `lib/src/application/services/map_viewport_navigation.dart` | transform viewport pur complet |
| A | `lib/src/features/editor/application/map_canvas_interaction_controller.dart` | table d'états et arbitrage exclusif |
| M | `lib/src/features/editor/application/map_editing_controller.dart` | rollback et cycle transactionnel |
| M | `lib/src/features/editor/state/editor_notifier.dart` | viewport, gomme, interlock save/undo/redo |
| M | `lib/src/features/editor/state/editor_selectors.dart` | disponibilité des commandes pendant stroke |
| M | `lib/src/features/editor/state/editor_state.dart` | union d'empreinte de gomme |
| M | `lib/src/features/editor/state/editor_state.freezed.dart` | génération de l'union et de l'état |
| M | `lib/src/features/editor/state/models/editor_state_groups.dart` | égalité du groupe outil/gomme |
| M | `lib/src/features/surface_painter/surface_painting_controller.dart` | effacement rectangulaire Surface |
| M | `lib/src/ui/canvas/map_canvas.dart` | routage, boutons exacts, focus, preview et overlay |
| A | `lib/src/ui/canvas/map_canvas/map_canvas_navigation_controls.dart` | cinq commandes responsive DS |
| M | `lib/src/ui/design_system/design_system.dart` | export du dialogue gomme |
| A | `lib/src/ui/design_system/pokemap_eraser_footprint_dialog.dart` | configuration no-code de l'empreinte |
| M | `lib/src/ui/shared/top_toolbar.dart` | libellé gomme, dialogue, disponibilité globale |

Les chemins du tableau sont relatifs à
`packages/map_editor/`.

### 5.2 Tests

| Statut | Fichier | Contrat couvert |
|---|---|---|
| A | `test/application/services/map_viewport_navigation_test.dart` | pan, zoom ancré, pinch, Fit, 100 %, centre |
| M | `test/border_map_editing/pending_border_save_notifier_test.dart` | Border et interlock stroke actif |
| A | `test/editor_notifier_active_stroke_interlock_test.dart` | save/undo/redo refusés sans mutation |
| A | `test/editor_notifier_eraser_footprint_test.dart` | modes, snapshot, validation, couches |
| M | `test/editor_selectors_test.dart` | disponibilité commandes |
| M | `test/editor_state_groups_test.dart` | égalité état gomme |
| A | `test/features/editor/application/map_canvas_interaction_controller_test.dart` | table d'états pure |
| A | `test/map_canvas_eraser_footprint_ui_test.dart` | preview/badge/canvas |
| A | `test/map_canvas_interaction_arbitration_test.dart` | concurrence, rollback, mixed-buttons |
| M | `test/map_canvas_pointer_navigation_test.dart` | wheel, pinch, souris, focus, clavier |
| M | `test/map_editing_controller_test.dart` | checkpoint et historique |
| M | `test/narrative_event_source_dependency_guard_test.dart` | garde de dépendance ajustée au nouveau fichier |
| M | `test/surface_painter/surface_painting_controller_test.dart` | effacement Surface |
| M | `test/top_toolbar_test.dart` | gomme et disponibilité save/undo/redo |
| A | `test/ui/design_system/pokemap_eraser_footprint_dialog_test.dart` | dialogue, validation, Escape |
| A | `test/ui/shell/pokemap_map_navigation_responsive_test.dart` | 800, 1000, 1280 et 1800 px |
| M | `test/ui/shell/pokemap_topbar_command_groups_test.dart` | routage des commandes de zoom topbar |

## 6. Zones de diff significatives

### `INT-01`

```text
MapCanvasInteractionController
  beginPointer / updatePointer / finishPointer / cancelPointer
  one ownerPointerId
  exact initialButtons
  terminal result commit | rollback

MapEditingController
  beginStroke -> checkpoint
  endStroke   -> une entrée undo
  cancelStroke -> restauration exacte, aucun changement undo/redo

MapCanvas
  Listener interne valide les boutons avant GestureDetector
  second pointer / Escape / cancel / focus loss -> rollback
```

### `INT-02`

```text
MapViewportNavigation
  pan
  zoomAt
  panZoomFromStart
  fit
  actualSize
  recenter

MapCanvas
  PointerScrollEvent
    sans Cmd/Ctrl -> pan
    avec Cmd/Ctrl -> zoom sous pointeur
  PointerPanZoom*
    snapshot absolu, delta transformé
  Space + primary / middle -> pan
  right -> réservé
```

### `INT-03`

```text
EditorEraserFootprint
  singleTile
  previousBrush(size capturée)
  custom(size validée/cappée)

EditorNotifier
  resolveCurrentPaintFootprintForEraser
  setEraserFootprint*
  annulation du geste si la cible/empreinte change

MapCanvas + SurfacePaintingController
  une empreinte commune pour preview et commit
```

### Remédiations de clôture

```text
saveActiveMap / undoMap / redoMap
  mapStrokeStart != null -> unavailable / no-op

cancelPointerIfButtonsChanged
  buttons != initialButtons -> rollback avant delta

Focus canvas
  skipTraversal: true
  includeSemantics: false

Navigation controls
  parent Focus non focusable
  activation clavier conserve le focus de commande
  activation pointeur redonne le focus au canvas
  LayoutBuilder + Wrap sous 480 px de largeur canvas
```

## 7. Fichiers créés — contenu intégral vérifiable

Le contenu intégral de chaque fichier créé est accessible par le lien local.
Le nombre de lignes et le SHA-256 figent byte-for-byte la version auditée.
Le présent rapport est exclu afin d'éviter une auto-référence infinie.

| Contenu intégral | Lignes | SHA-256 |
|---|---:|---|
| [plan Gate 2](/Users/karim/Project/pokemonProject/docs/superpowers/plans/2026-07-29-world-map-gate-2-interactions.md) | 131 | `907c67fa4f519e4da3612ae8b335e8839ef5d47c833d03ec53bf08c3f9cf9fbc` |
| [map_viewport_navigation.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/map_viewport_navigation.dart) | 173 | `335a853e3cfafe89c90a26b6d879f839c63a3b4496a7fce2accd9b3007bee299` |
| [map_canvas_interaction_controller.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/application/map_canvas_interaction_controller.dart) | 359 | `41b61465d1dec0341f720558621cb65f541f4ee820e72c96b7f1b026414b4b36` |
| [map_canvas_navigation_controls.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_navigation_controls.dart) | 141 | `dea3a61b904ea781137c3bf3ca797ec37b1bf4bb3b35ee1d3951ab28a1457ceb` |
| [pokemap_eraser_footprint_dialog.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/design_system/pokemap_eraser_footprint_dialog.dart) | 538 | `4b47f285dadb272142b7ec77e73414635dd518a0b375cf58805447b53660eff1` |
| [map_viewport_navigation_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/application/services/map_viewport_navigation_test.dart) | 236 | `4ab48910ed3f643b7cfbf908b5f28d659330989803bc050431d933113cd56df3` |
| [editor_notifier_active_stroke_interlock_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/editor_notifier_active_stroke_interlock_test.dart) | 192 | `d55ebbd79ec520c4843a73672dac8bd25d01cdd3c5281c5ce03a4414af974289` |
| [editor_notifier_eraser_footprint_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/editor_notifier_eraser_footprint_test.dart) | 564 | `1cd70df9f8dbcbda3c88e13d77acc59adaba88837d2efc81da02c1e3db34f601` |
| [map_canvas_interaction_controller_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/features/editor/application/map_canvas_interaction_controller_test.dart) | 274 | `4a6a7a9634f439f8cefdce39f08220da0c3161346b6fe4bcd2431042c80ac51f` |
| [map_canvas_eraser_footprint_ui_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/map_canvas_eraser_footprint_ui_test.dart) | 122 | `8a8126f9b38a4efbbb7728c8ec9b1b720db647197fffc4cf874c30aac36be56c` |
| [map_canvas_interaction_arbitration_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/map_canvas_interaction_arbitration_test.dart) | 776 | `58b483b54a3c8ee65d02e7cf25d09956ca1cbb2d87d9a28ca19705098635fcc7` |
| [pokemap_eraser_footprint_dialog_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_eraser_footprint_dialog_test.dart) | 192 | `4a25587faf0a713f98e31815051f31c4eeb464712012a4303c90a8fe0c413848` |
| [pokemap_map_navigation_responsive_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/ui/shell/pokemap_map_navigation_responsive_test.dart) | 167 | `2455dc9d35d836e078139f474b542ea62332646cde942e15065a92667746101f` |

## 8. Commits par lot

| Lot | Commit | Diff |
|---|---|---:|
| prérequis Gate 1 | `654543012 feat(map-editor): establish canonical visual stack` | inventaire Gate 1 isolé |
| `INT-01` | `127f911c6 feat(map-editor): arbitrate canvas interactions` | 11 fichiers, +2036/-180 |
| `INT-02` | `fe4dfa4b6 feat(map-editor): complete desktop map navigation` | 11 fichiers, +1614/-28 |
| `INT-03` | `0859943bf feat(map-editor): add independent eraser footprints` | 18 fichiers, +2792/-58 |
| audit architecture | `8107bd4c6 fix(map-editor): interlock active canvas transactions` | 8 fichiers, +377/-18 |
| audit UX/a11y/responsive | `6a295bce0 fix(map-editor): close interaction audit gaps` | 8 fichiers, +742/-93 |

Le présent Evidence Pack doit être committé séparément sous :

```text
docs(map-editor): close Gate 2 interactions
```

## 9. Commandes et résultats exacts

### 9.1 TDD et validations ciblées

Les cycles RED ont reproduit avant correction :

- save persistant une carte partielle ;
- undo finalisant implicitement un stroke ;
- redo supprimant le redo pendant un stroke ;
- changement primary vers primary+secondary committant une peinture partielle ;
- pan acceptant un delta avec boutons mixtes ;
- arrêt Tab invisible ;
- clipping des commandes à `800×600` et `1000×800`.

Une première tentative de reconstruire automatiquement la matrice des 17
fichiers a passé la liste multi-ligne comme un seul argument sous `zsh`.
Elle a quitté avec `exit 1` et `Does not exist` avant d'exécuter un test. Ce
n'était pas un échec produit. La commande a été corrigée avec un tableau shell :

```bash
cd packages/map_editor
typeset -a test_files
while IFS= read -r file; do
  test_files+=("${file#packages/map_editor/}")
done < <(
  git -C ../.. diff --name-only 654543012..6a295bce0 \
    -- 'packages/map_editor/test/**/*.dart' \
       'packages/map_editor/test/*.dart'
)
flutter test "${test_files[@]}"
```

Matrice fraîche et reproductible des 17 fichiers de tests Gate 2 :

```text
gate2_test_files=17
00:04 +155: All tests passed!
exit 0
```

La matrice de remédiation historique, plus large sur certains guardrails
adjacents, avait également donné :

```text
00:04 +158: All tests passed!
exit 0
```

Critique finale indépendante des huit fichiers de remédiation :

```text
suite ciblée : +62: All tests passed!
guardrail design system : +3: All tests passed!
dart format : Formatted 8 files (0 changed)
flutter analyze : No issues found! (ran in 5.4s)
git diff --check : clean
```

### 9.2 Suite complète `map_editor`

Commande :

```bash
cd packages/map_editor
flutter test
```

Une exécution intermédiaire, après l'interlock mais avant réalignement des
anciens tests Border, a échoué exactement sur six attentes qui supposaient
encore que Save finalise un stroke actif :

```text
05:04 +4555 ~6 -6: Some tests failed.
```

Ces attentes contredisaient le nouveau contrat de sécurité. Elles ont été
réécrites pour prouver `unavailable`, zéro écriture et conservation exacte de
l'état pendant le stroke. L'exécution finale donne :

```text
04:53 +4571 ~6: All tests passed!
exit 0
```

Le marqueur `~6` correspond à six tests ignorés par la configuration courante.
Leur inventaire ne faisait pas partie de Gate 2 et n'a pas été reclassé ici.

### 9.3 Analyse statique

Commande :

```bash
cd packages/map_editor
flutter analyze
```

Résultat final :

```text
No issues found! (ran in 5.1s)
exit 0
```

### 9.4 Hygiène et design system

Commandes :

```bash
git diff --check 654543012..6a295bce0
git diff 654543012..6a295bce0 -- packages/map_editor/lib \
  | rg '^\+.*(Color\(0x|Colors\.|PokeMapPalette\.)'
```

Résultats :

```text
diff check : clean
no-new-direct-product-ui-colors
Gate 2 scoped worktree : clean
```

Validation fraîche du rôle Build / Validation :

```bash
cd packages/map_editor
flutter test \
  test/editor_notifier_active_stroke_interlock_test.dart \
  test/ui/shell/pokemap_map_navigation_responsive_test.dart
flutter analyze
file build/macos/Build/Products/Debug/PokeMap.app/Contents/MacOS/PokeMap
codesign --verify --deep --strict \
  build/macos/Build/Products/Debug/PokeMap.app
```

```text
+7: All tests passed!
No issues found! (ran in 5.2s)
Mach-O 64-bit executable arm64
valid on disk
satisfies its Designated Requirement
exit 0
```

Deux `Color(0x1A000000)` préexistaient dans `map_canvas.dart`. Ils ne sont pas
ajoutés par Gate 2 et le guardrail du design system reste vert.

### 9.5 Build macOS

Commande :

```bash
cd packages/map_editor
flutter build macos --debug
```

Résultat :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/PokeMap.app
exit 0
```

### 9.6 Smoke desktop

#### Smoke interactif `INT-02`

Une copie sandboxée de `examples/playable_runtime_host/golden_fangame_slice`
a été utilisée avec `dev/marionette_main.dart`.

Observations :

- projet `Golden Fangame Slice` chargé ;
- carte `Golden Town` ouverte ;
- zoom `100 -> 120 -> 100` ;
- `Fit -> 429 %` ;
- recentrage et pan observables ;
- aucune erreur runtime ;
- source et copie de fixture identiques après le smoke.

Capture éphémère :

```text
/tmp/pokemap-gate2-int02-smoke.png
1920×1080
SHA-256 15de5e45841ce1b87644ccb8e1df9e03ce679e25d9d3cb454b2fe78b5b9f9115
```

#### Smoke de clôture

Commande :

```bash
cd packages/map_editor
flutter run -d macos -t dev/marionette_main.dart \
  --dart-define=MARIONETTE_PROJECT_PATH=<copie sandboxée déterministe>
```

Résultats observables :

```text
✓ Built build/macos/Build/Products/Debug/PokeMap.app
Dart VM Service disponible
DTD connecté au package map_editor
widget tree : MapEditorApp -> EditorShellPage
projet : Golden Fangame Slice
status : Projet QA « Golden Fangame Slice » chargé
runtime errors : No runtime errors found.
fixture source/copie : identiques
application arrêtée proprement
copie temporaire déplacée dans la Corbeille
```

Limite explicite : la session macOS était verrouillée pendant ce dernier
smoke. Computer Use n'a donc pas pu relire ni actionner la fenêtre. Le démarrage,
le bootstrap projet, le widget tree et les erreurs runtime ont été vérifiés,
mais ce passage final ne constitue pas une nouvelle preuve visuelle.

Il ne remplace surtout pas un essai physique Magic Mouse/trackpad. Les gestes
sont couverts synthétiquement et par le smoke interactif précédent.

### 9.7 Packages non relancés

Le diff propre à Gate 2, mesuré après le prérequis `654543012`, ne change aucun
contrat `map_core` ou `map_runtime`. Leurs suites n'ont donc pas été relancées
pour la clôture Gate 2. Les changements Gate 1 correspondants ont leur propre
Evidence Pack et leur propre validation.

## 10. État Git initial

À l'entrée brute de Gate 2 :

```text
branch: main
HEAD: 839f6d5e4e4b7905aea401089a5289c5f13c719d
origin/main: 839f6d5e4e4b7905aea401089a5289c5f13c719d
113 entrées au total
```

Ces 113 entrées étaient composées de :

- 62 entrées utilisateur / autres lots déjà présentes avant Gate 1 ;
- 51 entrées Gate 1 documentées dans
  `world_map_editor_gate_1_wysiwyg_2026-07-28.md`.

Le prérequis Gate 1 a été isolé dans `654543012`. Après ce commit, les 62
entrées étrangères sont restées présentes et non indexées.

## 11. État Git final de l'implémentation et protocole de publication

```text
branch: main
HEAD: 6a295bce037a080ff83b1e5585d5aaecd800785c
origin/main: 839f6d5e4e4b7905aea401089a5289c5f13c719d
62 entrées étrangères
tous les chemins Gate 2 committés : clean
```

Sortie exacte de `git status --short --untracked-files=all` :

```text
 M .github/workflows/pokemap_hub_product_certification.yml
 M apps/pokemap_hub/integration_test/runtime_owned_player_flow_test.dart
 M apps/pokemap_hub/test/saves/hub_save_store_atomic_test.dart
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/authoring/scene_authoring_operations.dart
 M packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
 M packages/map_core/lib/src/models/narrative_command_descriptor.dart
 M packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart
 M packages/map_core/lib/src/read_models/narrative_command_catalog.dart
 M packages/map_core/lib/src/tooling/gameplay_roadmap_dashboard.dart
 M packages/map_core/test/gameplay_roadmap_dashboard_test.dart
 M packages/map_core/test/linked_asset_public_contracts_test.dart
 M packages/map_core/test/narrative_command_catalog_test.dart
 M packages/map_core/test/narrative_command_contract_parity_test.dart
 M packages/map_core/test/scene_authoring_operations_test.dart
 M packages/map_core/tool/generate_gameplay_roadmap_dashboard.dart
 M packages/map_editor/lib/game_export.dart
 M packages/map_editor/lib/src/application/services/narrative_template_catalog.dart
 M packages/map_editor/lib/src/features/game_export/application/game_package_export_profile.dart
 M packages/map_editor/lib/src/features/game_export/application/game_package_export_service.dart
 M packages/map_editor/lib/src/features/game_export/presentation/game_package_export_controller.dart
 M packages/map_editor/lib/src/features/game_export/presentation/game_package_export_dialog.dart
 M packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_action_builder.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_editor/test/cinematic_builder_characterization_performance_test.dart
 M packages/map_editor/test/event_builder_v2_template_sheet_test.dart
 M packages/map_editor/test/event_registry_persistence_performance_test.dart
 M packages/map_editor/test/game_export/game_export_test_fixture.dart
 M packages/map_editor/test/game_export/game_package_export_controller_test.dart
 M packages/map_editor/test/game_export/game_package_export_dialog_test.dart
 M packages/map_editor/test/game_export/game_package_export_service_test.dart
 M packages/map_editor/test/game_export/runtime_project_projection_builder_test.dart
 M packages/map_editor/test/narrative_event_authoring_snapshot_performance_test.dart
 M packages/map_editor/test/narrative_event_validation_incremental_performance_test.dart
 M packages/map_editor/test/narrative_global_search_performance_test.dart
 M packages/map_editor/test/narrative_large_project_workspace_performance_test.dart
 M packages/map_editor/test/narrative_template_catalog_test.dart
 M packages/map_editor/test/personalization/phase_6_personalization_studio_export_e2e_test.dart
 M packages/map_editor/test/scene_action_builder_test.dart
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart
 M packages/map_editor/test/ui/canvas/event_builder_v2_product_route_test.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_adapter.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_result.dart
 D packages/map_runtime/test/le_train_m00_external_runtime_smoke_test.dart
 M packages/map_runtime/test/narrative_command_runtime_parity_test.dart
 M packages/map_runtime/test/scene_battle_runtime_outcome_adapter_test.dart
 M reports/gameplay/evidence/ph_007_personalization_release_gate_receipt.json
 M tool/pokemap_product_certification/pubspec.lock
?? packages/gamepads_darwin/macos/gamepads_darwin/.swiftpm/xcode/xcuserdata/karim.xcuserdatad/xcschemes/xcschememanagement.plist
?? packages/gamepads_ios/ios/gamepads_ios/.swiftpm/xcode/xcuserdata/karim.xcuserdatad/xcschemes/xcschememanagement.plist
?? packages/map_core/lib/src/tooling/gameplay_roadmap_evidence.dart
?? packages/map_editor/dart_test.yaml
?? packages/map_editor/lib/src/features/game_export/application/game_package_gameplay_readiness_gate.dart
?? packages/map_runtime/test/rendered_map_pixel_smoke_test.dart
?? reports/gameplay/audit/avelune_pokemap_ultra_complete_product_audit_2026-07-28.md
?? reports/gameplay/avelune_pokemap_product_roadmap_2026-07-28.md
?? reports/gameplay/evidence/README.md
?? reports/gameplay/phase_0_truth_and_contract_gates_implementation_2026-07-28.md
```

Aucune de ces 62 entrées n'est indexée dans les commits Gate 2.

Ce bloc constitue le snapshot Git final de l'implémentation avant le commit
documentaire. Après création du présent rapport, l'état contient exactement
une 63e entrée Gate 2 :

```text
?? reports/ui/world_map_editor_gate_2_interactions_2026-07-29.md
```

Le protocole de publication indexe ce chemin seul, vérifie le diff staged,
committe `docs(map-editor): close Gate 2 interactions`, contrôle que les 62
entrées étrangères restent non staged, fetch `origin/main`, refuse toute
divergence distante, puis pousse `main` une seule fois sans force.

Un artefact Git ne peut pas contenir le hash de son propre commit sans
auto-référence. Le hash du commit documentaire, l'égalité
`HEAD == origin/main` et le `git status` post-push sont donc fournis dans le
handoff final de clôture, qui complète cet état Git final.

## 12. Non-objectifs

Gate 2 ne cherche pas à :

- déplacer les objets déjà posés — sujet de Gate 3 ;
- filtrer et mémoriser les catalogues de tilesets — sujet de Gate 4 ;
- refondre toute la structure du workspace — sujet de Gate 5 ;
- modifier les contrats de rendu Gate 1 ;
- certifier le ressenti d'un périphérique Apple physique ;
- nettoyer les changements utilisateur étrangers présents dans le worktree.

## 13. Risques résiduels

Risques non bloquants :

1. un test matériel Magic Mouse et trackpad reste nécessaire pour juger
   accélération, inertie et confort subjectif ;
2. le dialogue gomme peut devenir serré sous environ 320 px de hauteur, hors
   cible desktop principale ;
3. Escape et PointerCancel sont couverts par le contrôleur et les routes
   communes, mais chaque branche `drawingZone`/`borderGesture` n'a pas son
   propre E2E widget dédié ;
4. la matrice stylus, inverted stylus et périphériques inconnus n'est pas
   exhaustive ;
5. le responsive couvre les breakpoints produit principaux, pas chaque largeur
   arbitraire sous le minimum desktop.

## 14. Auto-critique finale

Points solides :

- les lots sont séparés en commits explicites ;
- les défauts de revue ont été reproduits avant correction ;
- les remédiations protègent les frontières entre interaction, historique,
  persistance et UI ;
- la suite complète et l'analyse statique sont vertes ;
- le worktree utilisateur a été préservé par staging chemin par chemin ;
- aucune nouvelle primitive visuelle ad hoc ni couleur produit directe.

Limites de cette clôture :

- le dernier smoke visuel n'a pas pu être rejoué sur une session verrouillée ;
- le coût du diff est important, surtout dans `map_canvas.dart` et les tests,
  même si chaque lot est isolé ;
- l'absence d'un service Marionette callable dans cette session a limité la
  dernière passe aux outils DTD et à Computer Use ;
- l'interlock Border a exigé de réaligner six anciens tests dont le contrat
  implicite était dangereux ; cette transition est documentée mais augmente la
  surface de revue.

Conclusion : aucun risque résiduel ne justifie de retenir Gate 2. La prochaine
étape logique est Gate 3, centrée sur la sélection et la manipulation directe
des objets déjà placés.

## 15. Annexes — contenu complet des fichiers créés

Les blocs ci-dessous reproduisent intégralement les 13 fichiers créés ou
rédigés pour Gate 2. Les tables de la section 7 fournissent leurs SHA-256.

### 15.1 `docs/superpowers/plans/2026-07-29-world-map-gate-2-interactions.md`

`````markdown
# World Map Editor Gate 2 — Interactions Implementation Plan

> **For Codex:** REQUIRED SUB-SKILL: Use subagent-driven-development to execute this plan task by task, with test-driven-development for every behavior change and verification-before-completion before every commit.

**Goal:** Deliver Gate 2 (`INT-01`, `INT-02`, `INT-03`) so map editing gestures are exclusive and rollback-safe, desktop navigation never edits the map, and the eraser owns a visible footprint that defaults to 1×1.

**Architecture:** Keep `MapData` mutations in `EditorNotifier`/the existing map editing controller, add one pure interaction arbiter as the owner of transient pointer sessions, and isolate viewport mathematics in a pure navigation service. Keep eraser configuration in editor-only state; both preview and commit resolve the same immutable footprint. UI additions use PokeMap design-system primitives and theme tokens.

**Tech Stack:** Dart 3, Flutter desktop, Riverpod, Freezed, Flutter widget tests, Marionette macOS smoke verification.

---

### Task 0: Preserve the completed Gate 1 prerequisite

**Files:**

- Commit only the Gate 1 inventory recorded in `reports/ui/world_map_editor_gate_1_wysiwyg_2026-07-28.md`.
- Preserve the pre-existing `gameplay_roadmap_evidence.dart` export hunk outside the commit.

**Steps:**

1. Run the three Gate 1 targeted suites from its Evidence Pack.
2. Stage the exact Gate 1 file inventory and only the visual-stack hunks in `packages/map_core/lib/map_core.dart`.
3. Run `git diff --cached --check`.
4. Commit `feat(map-editor): establish canonical visual stack`.

### Task 1: INT-01 — Exclusive interaction arbitration and rollback

**Files:**

- Create: `packages/map_editor/lib/src/features/editor/application/map_canvas_interaction_controller.dart`
- Create: `packages/map_editor/test/features/editor/application/map_canvas_interaction_controller_test.dart`
- Create: `packages/map_editor/test/map_canvas_interaction_arbitration_test.dart`
- Modify: `packages/map_editor/lib/src/application/services/map_history_coordinator.dart`
- Modify: `packages/map_editor/lib/src/application/services/editor_map_mutation_coordinator.dart`
- Modify: `packages/map_editor/lib/src/features/editor/application/map_editing_controller.dart`
- Modify: `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- Modify: `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- Modify: `packages/map_editor/test/map_editing_controller_test.dart`
- Modify: `packages/map_editor/test/map_canvas_pointer_navigation_test.dart`

**Steps:**

1. Write failing pure tests for the state table: pointer kind, exact buttons, Space/meta/control/shift/alt snapshots, single owner, second-pointer rejection, terminal idempotence, and scroll acceptance only while idle.
2. Write failing controller tests proving that cancelling a stroke restores the exact map and dirty state while leaving undo/redo unchanged, and that a multi-sample committed stroke produces exactly one undo entry.
3. Implement exclusive states `idle`, `pendingPrimary`, `panning`, `paintingStroke`, `drawingZone`, `borderGesture`, and `trackpadPanZoom`, with one owner pointer and one terminal result (`commit` or `rollback`).
4. Add rollback through the history, mutation, editing-controller, and notifier layers.
5. Route raw pointer and `GestureDetector` callbacks through the same arbiter. Navigation has priority over editing; mixed buttons are rejected; scroll cannot enter during an active interaction.
6. Add a dedicated canvas `FocusNode`. Escape rolls back the active stroke/draft/Border gesture; pointer cancel does the same. A normal pointer-up commits once.
7. Add widget tests with a paint tool active proving that pan/cancel/second pointer do not mutate `MapData`, dirty state, undo, or redo.
8. Run focused tests, `flutter analyze`, format checks, `git diff --check`, independent spec review, and independent code-quality review.
9. Commit only INT-01 files as `feat(map-editor): arbitrate canvas interactions`.

### Task 2: INT-02 — Complete desktop navigation

**Files:**

- Create: `packages/map_editor/lib/src/application/services/map_viewport_navigation.dart`
- Create: `packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_navigation_controls.dart`
- Create: `packages/map_editor/test/application/services/map_viewport_navigation_test.dart`
- Modify: `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- Modify: `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- Modify: `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- Modify: `packages/map_editor/test/map_canvas_pointer_navigation_test.dart`
- Modify: `packages/map_editor/test/top_toolbar_test.dart`

**Steps:**

1. Write failing pure tests for pan, zoom-under-pointer invariance, absolute pinch pan+scale, fit with padding/clamps, 100%, and recenter-at-current-zoom.
2. Implement an immutable viewport transform and atomic notifier setter.
3. Route wheel/two-finger scroll to pan. Route Cmd/Ctrl+wheel to multiplicative zoom under `event.localPosition`.
4. Handle `PointerPanZoomStart/Update/End` with an absolute gesture snapshot so pinch and simultaneous pan do not accumulate drift.
5. Implement Space+primary drag and middle-button drag through INT-01. Do not retain right-button pan; reserve it for contextual actions.
6. Add `grab`/`grabbing` cursors, `F` for Fit while the canvas owns focus, and loss-of-focus cleanup.
7. Add PokeMap design-system canvas controls for Fit, 100%, recenter, zoom out, and zoom in. Keep all colors token-backed.
8. Extend widget tests for mouse, trackpad, pinch, Meta/Ctrl wheel, Space drag, middle drag, painting-tool invariants, fit, reset, recenter, Escape, and focus.
9. Run the focused test set, `flutter analyze`, format checks, `git diff --check`, independent spec review, and independent code-quality review.
10. Run the macOS Marionette preflight and real debug-app smoke flow. Record synthetic-versus-physical-device limits explicitly.
11. Commit only INT-02 files as `feat(map-editor): complete desktop map navigation`.

### Task 3: INT-03 — Independent, visible eraser footprint

**Files:**

- Create: `packages/map_editor/lib/src/ui/design_system/pokemap_eraser_footprint_dialog.dart`
- Create: `packages/map_editor/test/editor_notifier_eraser_footprint_test.dart`
- Create: `packages/map_editor/test/ui/design_system/pokemap_eraser_footprint_dialog_test.dart`
- Modify: `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- Regenerate: `packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart`
- Modify: `packages/map_editor/lib/src/features/editor/state/models/editor_state_groups.dart`
- Modify: `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- Modify: `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- Modify: `packages/map_editor/lib/src/features/surface_painter/application/surface_painting_controller.dart`
- Modify: `packages/map_editor/lib/src/ui/design_system/design_system.dart`
- Modify: `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- Modify: `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- Modify: `packages/map_editor/test/editor_state_groups_test.dart`
- Modify: `packages/map_editor/test/editor_selectors_test.dart`
- Modify: `packages/map_editor/test/surface_painter/surface_painting_controller_test.dart`
- Modify: `packages/map_editor/test/top_toolbar_test.dart`

**Steps:**

1. Write failing tests proving that a multi-tile active brush still erases 1×1 by default.
2. Add an immutable Freezed eraser footprint union: `singleTile`, captured `previousBrush`, and validated/capped `custom`.
3. Write failing tests proving that “previous brush” captures once and remains unchanged after brush/layer changes.
4. Route Tile, Collision, Terrain, Path, and Surface erase preview and commit through one eraser-footprint resolver. Keep collision brush sizing exclusive to collision painting.
5. Add clipped rectangular Surface erasure as one map mutation.
6. Add a design-system custom-size dialog, an always-visible toolbar label (`Gomme W×H`), explicit mode choices, and a token-backed near-cursor `PokeMapBadge`.
7. Test preview/commit equality for every supported layer, edge clipping, invalid custom dimensions, no-op erasure, and one drag/one undo.
8. Regenerate only `editor_state.freezed.dart`.
9. Run focused tests, `flutter analyze`, format checks, `git diff --check`, independent spec review, and independent code-quality review.
10. Commit only INT-03 files as `feat(map-editor): add independent eraser footprints`.

### Task 4: Gate 2 closure, broad verification, and publication

**Files:**

- Create: `reports/ui/world_map_editor_gate_2_interactions_2026-07-29.md`

**Steps:**

1. Ask independent reviewers to audit architecture, UX/DS compliance, test completeness, and regression risk across all Gate 2 commits.
2. Remediate every blocking finding in the owning lot with an additional scoped fix commit if needed.
3. Run the full `packages/map_editor` Flutter test suite and analyzer.
4. Run relevant `map_core` and `map_runtime` suites/analyzers if Gate 2 changed or exercised their contracts.
5. Build the macOS debug application and replay the Marionette smoke flow.
6. Record initial/final Git states, all changed files, created-file hashes/content links, exact commands/results, sub-agent verdicts, risks, and self-critique under `codex_rule.md`.
7. Commit the Evidence Pack as `docs(map-editor): close Gate 2 interactions`.
8. Verify the commit series and that unrelated pre-existing changes remain unstaged.
9. Confirm the remote `main` tip has not diverged, then push `main` once without force.
`````

### 15.2 `packages/map_editor/lib/src/application/services/map_viewport_navigation.dart`

`````dart
import 'dart:math' as math;
import 'dart:ui';

/// Immutable camera transform for the world-map canvas.
///
/// World pixels are rendered with:
///
/// `viewportPoint = panOffset + worldPoint * zoom`
class MapViewport {
  const MapViewport({
    required this.zoom,
    required this.panOffset,
  }) : assert(zoom > 0);

  final double zoom;
  final Offset panOffset;
}

/// Pure desktop-navigation geometry shared by pointer events and UI controls.
abstract final class MapViewportNavigation {
  static const double minZoom = 0.1;
  static const double maxZoom = 5;
  static const double wheelZoomSensitivity = 0.002;

  static Offset worldPointAt({
    required MapViewport viewport,
    required Offset viewportPoint,
  }) {
    return (viewportPoint - viewport.panOffset) / viewport.zoom;
  }

  static MapViewport panBy({
    required MapViewport viewport,
    required Offset delta,
  }) {
    return MapViewport(
      zoom: viewport.zoom,
      panOffset: viewport.panOffset + delta,
    );
  }

  static MapViewport zoomAt({
    required MapViewport viewport,
    required Offset focalPoint,
    required double targetZoom,
  }) {
    final clampedZoom = _clampZoom(targetZoom);
    final worldAnchor = worldPointAt(
      viewport: viewport,
      viewportPoint: focalPoint,
    );
    return MapViewport(
      zoom: clampedZoom,
      panOffset: focalPoint - worldAnchor * clampedZoom,
    );
  }

  static MapViewport zoomFromScroll({
    required MapViewport viewport,
    required Offset focalPoint,
    required double scrollDeltaY,
  }) {
    if (scrollDeltaY.isNaN) {
      throw ArgumentError.value(scrollDeltaY, 'scrollDeltaY');
    }
    final factor = math.exp(-scrollDeltaY * wheelZoomSensitivity);
    return zoomAt(
      viewport: viewport,
      focalPoint: focalPoint,
      targetZoom: viewport.zoom * factor,
    );
  }

  /// Resolves a native trackpad gesture from its immutable start snapshot.
  ///
  /// Both [cumulativePan] and [scale] are absolute values for the gesture, not
  /// deltas. Recomputing from the start prevents drift and pinch jumps.
  static MapViewport panZoomFromStart({
    required MapViewport startViewport,
    required Offset startFocalPoint,
    required Offset cumulativePan,
    required double scale,
  }) {
    if (scale.isNaN || scale <= 0) {
      throw ArgumentError.value(scale, 'scale', 'must be positive');
    }
    final worldAnchor = worldPointAt(
      viewport: startViewport,
      viewportPoint: startFocalPoint,
    );
    final zoom = _clampZoom(startViewport.zoom * scale);
    final currentFocalPoint = startFocalPoint + cumulativePan;
    return MapViewport(
      zoom: zoom,
      panOffset: currentFocalPoint - worldAnchor * zoom,
    );
  }

  static MapViewport fitMap({
    required Size mapPixelSize,
    required Size viewportSize,
    double margin = 32,
  }) {
    _validateSize(mapPixelSize, 'mapPixelSize');
    _validateSize(viewportSize, 'viewportSize');
    if (!margin.isFinite || margin < 0) {
      throw ArgumentError.value(margin, 'margin', 'must be non-negative');
    }
    final availableWidth = viewportSize.width - margin * 2;
    final availableHeight = viewportSize.height - margin * 2;
    if (availableWidth <= 0 || availableHeight <= 0) {
      throw ArgumentError.value(
        margin,
        'margin',
        'must leave a positive viewport area',
      );
    }
    final zoom = _clampZoom(
      math.min(
        availableWidth / mapPixelSize.width,
        availableHeight / mapPixelSize.height,
      ),
    );
    return centerMap(
      mapPixelSize: mapPixelSize,
      viewportSize: viewportSize,
      zoom: zoom,
    );
  }

  static MapViewport centerMap({
    required Size mapPixelSize,
    required Size viewportSize,
    required double zoom,
  }) {
    _validateSize(mapPixelSize, 'mapPixelSize');
    _validateSize(viewportSize, 'viewportSize');
    final clampedZoom = _clampZoom(zoom);
    return MapViewport(
      zoom: clampedZoom,
      panOffset: viewportSize.center(Offset.zero) -
          mapPixelSize.center(Offset.zero) * clampedZoom,
    );
  }

  static MapViewport actualSize({
    required MapViewport viewport,
    required Size viewportSize,
  }) {
    _validateSize(viewportSize, 'viewportSize');
    return zoomAt(
      viewport: viewport,
      focalPoint: viewportSize.center(Offset.zero),
      targetZoom: 1,
    );
  }

  static double _clampZoom(double zoom) {
    if (zoom.isNaN || zoom <= 0) {
      throw ArgumentError.value(zoom, 'zoom', 'must be positive');
    }
    return zoom.clamp(minZoom, maxZoom).toDouble();
  }

  static void _validateSize(Size size, String name) {
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      throw ArgumentError.value(size, name, 'must be finite and positive');
    }
  }
}
`````

### 15.3 `packages/map_editor/lib/src/features/editor/application/map_canvas_interaction_controller.dart`

`````dart
/// Device families understood by the map-canvas interaction contract.
///
/// This deliberately mirrors Flutter pointer kinds without coupling the pure
/// arbiter to the widget layer.
enum MapCanvasPointerKind {
  mouse,
  trackpad,
  touch,
  stylus,
  invertedStylus,
  unknown,
}

/// Keyboard modifiers captured once, when an interaction takes ownership.
class MapCanvasInteractionModifiers {
  const MapCanvasInteractionModifiers({
    this.shift = false,
    this.alt = false,
    this.control = false,
    this.meta = false,
    this.space = false,
  });

  final bool shift;
  final bool alt;
  final bool control;
  final bool meta;
  final bool space;

  @override
  bool operator ==(Object other) {
    return other is MapCanvasInteractionModifiers &&
        other.shift == shift &&
        other.alt == alt &&
        other.control == control &&
        other.meta == meta &&
        other.space == space;
  }

  @override
  int get hashCode => Object.hash(shift, alt, control, meta, space);
}

/// Stable editor target captured before an interaction can mutate the map.
class MapCanvasInteractionContext {
  const MapCanvasInteractionContext({
    required this.projectRootPath,
    required this.mapId,
    required this.activeMapPath,
    required this.layerId,
    required this.toolKey,
    required this.targetId,
    required this.guidedNavigation,
  });

  final String? projectRootPath;
  final String? mapId;
  final String? activeMapPath;
  final String? layerId;
  final String toolKey;
  final String? targetId;
  final bool guidedNavigation;

  @override
  bool operator ==(Object other) {
    return other is MapCanvasInteractionContext &&
        other.projectRootPath == projectRootPath &&
        other.mapId == mapId &&
        other.activeMapPath == activeMapPath &&
        other.layerId == layerId &&
        other.toolKey == toolKey &&
        other.targetId == targetId &&
        other.guidedNavigation == guidedNavigation;
  }

  @override
  int get hashCode => Object.hash(
        projectRootPath,
        mapId,
        activeMapPath,
        layerId,
        toolKey,
        targetId,
        guidedNavigation,
      );
}

class MapCanvasInteractionInput {
  const MapCanvasInteractionInput({
    required this.pointerId,
    required this.pointerKind,
    required this.buttons,
    required this.modifiers,
    required this.context,
  });

  final int pointerId;
  final MapCanvasPointerKind pointerKind;
  final int buttons;
  final MapCanvasInteractionModifiers modifiers;
  final MapCanvasInteractionContext context;
}

enum MapCanvasInteractionKind {
  pendingPrimary,
  panning,
  paintingStroke,
  drawingZone,
  borderGesture,
  trackpadPanZoom,
}

class MapCanvasInteractionSession {
  const MapCanvasInteractionSession({
    required this.interactionId,
    required this.pointerId,
    required this.kind,
    required this.pointerKind,
    required this.buttonsAtStart,
    required this.modifiersAtStart,
    required this.contextAtStart,
  });

  final int interactionId;
  final int pointerId;
  final MapCanvasInteractionKind kind;
  final MapCanvasPointerKind pointerKind;
  final int buttonsAtStart;
  final MapCanvasInteractionModifiers modifiersAtStart;
  final MapCanvasInteractionContext contextAtStart;

  MapCanvasInteractionSession withKind(MapCanvasInteractionKind nextKind) {
    return MapCanvasInteractionSession(
      interactionId: interactionId,
      pointerId: pointerId,
      kind: nextKind,
      pointerKind: pointerKind,
      buttonsAtStart: buttonsAtStart,
      modifiersAtStart: modifiersAtStart,
      contextAtStart: contextAtStart,
    );
  }
}

enum MapCanvasInteractionStartStatus {
  started,
  ignored,
  rejectedBusy,
  rejectedButtons,
  rejectedPointerKind,
}

class MapCanvasInteractionStartResult {
  const MapCanvasInteractionStartResult({
    required this.status,
    this.session,
  });

  final MapCanvasInteractionStartStatus status;
  final MapCanvasInteractionSession? session;
}

enum MapCanvasInteractionTerminal {
  commit,
  rollback,
}

class MapCanvasInteractionEndResult {
  const MapCanvasInteractionEndResult({
    required this.session,
    required this.terminal,
  });

  final MapCanvasInteractionSession session;
  final MapCanvasInteractionTerminal terminal;
}

/// Owns the one and only transient map-canvas interaction.
///
/// The widget adapter remains responsible for effects (paint, pan, commit,
/// rollback). This class only decides who owns the gesture and guarantees that
/// repeated/non-owner terminal events are harmless.
class MapCanvasInteractionController {
  static const int _primaryButton = 0x01;
  static const int _secondaryButton = 0x02;
  static const int _tertiaryButton = 0x04;

  int _nextInteractionId = 1;
  MapCanvasInteractionSession? _activeSession;

  MapCanvasInteractionSession? get activeSession => _activeSession;
  bool get isIdle => _activeSession == null;
  bool get acceptsScroll => isIdle;

  bool ownsPointer(int pointerId) {
    return _activeSession?.pointerId == pointerId;
  }

  MapCanvasInteractionStartResult beginPointer(
    MapCanvasInteractionInput input,
  ) {
    if (_activeSession != null) {
      return const MapCanvasInteractionStartResult(
        status: MapCanvasInteractionStartStatus.rejectedBusy,
      );
    }
    if (input.buttons == 0) {
      return const MapCanvasInteractionStartResult(
        status: MapCanvasInteractionStartStatus.ignored,
      );
    }

    final primaryOnly = input.buttons == _primaryButton;
    final secondaryOnly = input.buttons == _secondaryButton;
    final tertiaryOnly = input.buttons == _tertiaryButton;
    if (secondaryOnly) {
      // Reserved for a future context action. It must never pan or edit.
      return const MapCanvasInteractionStartResult(
        status: MapCanvasInteractionStartStatus.ignored,
      );
    }
    final navigationRequested =
        tertiaryOnly || (primaryOnly && input.modifiers.space);

    if (navigationRequested) {
      if (input.pointerKind != MapCanvasPointerKind.mouse) {
        return const MapCanvasInteractionStartResult(
          status: MapCanvasInteractionStartStatus.rejectedPointerKind,
        );
      }
      return _start(input, MapCanvasInteractionKind.panning);
    }
    if (!primaryOnly) {
      return const MapCanvasInteractionStartResult(
        status: MapCanvasInteractionStartStatus.rejectedButtons,
      );
    }
    if (!_supportsPrimaryEditing(input.pointerKind)) {
      return const MapCanvasInteractionStartResult(
        status: MapCanvasInteractionStartStatus.rejectedPointerKind,
      );
    }
    return _start(input, MapCanvasInteractionKind.pendingPrimary);
  }

  MapCanvasInteractionStartResult beginPanZoom(
    MapCanvasInteractionInput input,
  ) {
    if (_activeSession != null) {
      return const MapCanvasInteractionStartResult(
        status: MapCanvasInteractionStartStatus.rejectedBusy,
      );
    }
    if (input.pointerKind != MapCanvasPointerKind.trackpad) {
      return const MapCanvasInteractionStartResult(
        status: MapCanvasInteractionStartStatus.rejectedPointerKind,
      );
    }
    if (input.buttons != 0) {
      return const MapCanvasInteractionStartResult(
        status: MapCanvasInteractionStartStatus.rejectedButtons,
      );
    }
    return _start(input, MapCanvasInteractionKind.trackpadPanZoom);
  }

  MapCanvasInteractionSession? promotePending({
    required int pointerId,
    required MapCanvasInteractionKind kind,
  }) {
    final current = _activeSession;
    if (current == null ||
        current.pointerId != pointerId ||
        current.kind != MapCanvasInteractionKind.pendingPrimary ||
        !_isPrimaryPromotion(kind)) {
      return null;
    }
    final promoted = current.withKind(kind);
    _activeSession = promoted;
    return promoted;
  }

  MapCanvasInteractionEndResult? cancelPointerIfButtonsChanged({
    required int pointerId,
    required int buttons,
  }) {
    final current = _activeSession;
    if (current == null ||
        current.pointerId != pointerId ||
        current.buttonsAtStart == buttons) {
      return null;
    }
    return _end(pointerId, MapCanvasInteractionTerminal.rollback);
  }

  MapCanvasInteractionEndResult? finishPointer(int pointerId) {
    return _end(pointerId, MapCanvasInteractionTerminal.commit);
  }

  MapCanvasInteractionEndResult? cancelPointer(int pointerId) {
    return _end(pointerId, MapCanvasInteractionTerminal.rollback);
  }

  MapCanvasInteractionEndResult? cancelActive() {
    final current = _activeSession;
    if (current == null) return null;
    _activeSession = null;
    return MapCanvasInteractionEndResult(
      session: current,
      terminal: MapCanvasInteractionTerminal.rollback,
    );
  }

  MapCanvasInteractionStartResult _start(
    MapCanvasInteractionInput input,
    MapCanvasInteractionKind kind,
  ) {
    final session = MapCanvasInteractionSession(
      interactionId: _nextInteractionId++,
      pointerId: input.pointerId,
      kind: kind,
      pointerKind: input.pointerKind,
      buttonsAtStart: input.buttons,
      modifiersAtStart: input.modifiers,
      contextAtStart: input.context,
    );
    _activeSession = session;
    return MapCanvasInteractionStartResult(
      status: MapCanvasInteractionStartStatus.started,
      session: session,
    );
  }

  MapCanvasInteractionEndResult? _end(
    int pointerId,
    MapCanvasInteractionTerminal terminal,
  ) {
    final current = _activeSession;
    if (current == null || current.pointerId != pointerId) return null;
    _activeSession = null;
    return MapCanvasInteractionEndResult(
      session: current,
      terminal: terminal,
    );
  }

  bool _supportsPrimaryEditing(MapCanvasPointerKind kind) {
    return kind == MapCanvasPointerKind.mouse ||
        kind == MapCanvasPointerKind.touch ||
        kind == MapCanvasPointerKind.stylus ||
        kind == MapCanvasPointerKind.invertedStylus;
  }

  bool _isPrimaryPromotion(MapCanvasInteractionKind kind) {
    return kind == MapCanvasInteractionKind.paintingStroke ||
        kind == MapCanvasInteractionKind.drawingZone ||
        kind == MapCanvasInteractionKind.borderGesture;
  }
}
`````

### 15.4 `packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_navigation_controls.dart`

`````dart
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Compact, design-system-only controls for the world-map viewport.
class MapCanvasNavigationControls extends StatelessWidget {
  const MapCanvasNavigationControls({
    super.key,
    required this.zoom,
    required this.onZoomOut,
    required this.onZoomIn,
    required this.onFit,
    required this.onActualSize,
    required this.onCenter,
  });

  final double zoom;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;
  final VoidCallback onFit;
  final VoidCallback onActualSize;
  final VoidCallback onCenter;

  static const double _wideLayoutMinWidth = 480;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < _wideLayoutMinWidth;
        return MouseRegion(
          cursor: SystemMouseCursors.basic,
          child: PokeMapCard(
            padding: const EdgeInsets.all(4),
            borderRadius: 8,
            child: compact ? _buildCompactControls() : _buildWideControls(),
          ),
        );
      },
    );
  }

  Widget _buildWideControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildZoomControls(),
        const SizedBox(width: 6),
        PokeMapButton(
          key: const ValueKey<String>('map-navigation-fit'),
          onPressed: onFit,
          variant: PokeMapButtonVariant.ghost,
          size: PokeMapButtonSize.small,
          child: const Text('Ajuster'),
        ),
        const SizedBox(width: 2),
        PokeMapButton(
          key: const ValueKey<String>('map-navigation-actual-size'),
          onPressed: onActualSize,
          variant: PokeMapButtonVariant.ghost,
          size: PokeMapButtonSize.small,
          child: const Text('100 %'),
        ),
        const SizedBox(width: 2),
        PokeMapButton(
          key: const ValueKey<String>('map-navigation-center'),
          onPressed: onCenter,
          variant: PokeMapButtonVariant.ghost,
          size: PokeMapButtonSize.small,
          child: const Text('Centrer'),
        ),
      ],
    );
  }

  Widget _buildCompactControls() {
    return Wrap(
      alignment: WrapAlignment.end,
      runAlignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        _buildZoomControls(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PokeMapIconButton(
              key: const ValueKey<String>('map-navigation-fit'),
              onPressed: onFit,
              icon: const Icon(
                CupertinoIcons.arrow_up_left_arrow_down_right,
              ),
              tooltip: 'Ajuster la carte',
            ),
            const SizedBox(width: 2),
            PokeMapIconButton(
              key: const ValueKey<String>('map-navigation-actual-size'),
              onPressed: onActualSize,
              icon: const Icon(CupertinoIcons.viewfinder),
              tooltip: 'Afficher à 100 %',
            ),
            const SizedBox(width: 2),
            PokeMapIconButton(
              key: const ValueKey<String>('map-navigation-center'),
              onPressed: onCenter,
              icon: const Icon(CupertinoIcons.scope),
              tooltip: 'Centrer la carte',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildZoomControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PokeMapIconButton(
          key: const ValueKey<String>('map-navigation-zoom-out'),
          onPressed: onZoomOut,
          icon: const Icon(CupertinoIcons.minus),
          tooltip: 'Zoom arrière',
          variant: PokeMapIconButtonVariant.soft,
        ),
        const SizedBox(width: 4),
        PokeMapBadge(label: '${(zoom * 100).round()} %'),
        const SizedBox(width: 4),
        PokeMapIconButton(
          key: const ValueKey<String>('map-navigation-zoom-in'),
          onPressed: onZoomIn,
          icon: const Icon(CupertinoIcons.plus),
          tooltip: 'Zoom avant',
          variant: PokeMapIconButtonVariant.soft,
        ),
      ],
    );
  }
}
`````

### 15.5 `packages/map_editor/lib/src/ui/design_system/pokemap_eraser_footprint_dialog.dart`

`````dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/theme.dart';
import 'pokemap_button.dart';
import 'pokemap_card.dart';
import 'pokemap_panel.dart';
import 'pokemap_text_field.dart';

const pokeMapEraserFootprintDialogKey =
    ValueKey<String>('pokemap-eraser-footprint-dialog');
const pokeMapEraserSingleTileChoiceKey =
    ValueKey<String>('pokemap-eraser-single-tile-choice');
const pokeMapEraserPreviousBrushChoiceKey =
    ValueKey<String>('pokemap-eraser-previous-brush-choice');
const pokeMapEraserCustomChoiceKey =
    ValueKey<String>('pokemap-eraser-custom-choice');
const pokeMapEraserWidthFieldKey =
    ValueKey<String>('pokemap-eraser-width-field');
const pokeMapEraserHeightFieldKey =
    ValueKey<String>('pokemap-eraser-height-field');
const pokeMapEraserFootprintApplyButtonKey =
    ValueKey<String>('pokemap-eraser-footprint-apply-button');

/// User-facing ways to define the footprint of the eraser.
enum PokeMapEraserFootprintMode {
  singleTile,
  previousBrush,
  custom,
}

/// Typed, validated choice returned by [showPokeMapEraserFootprintDialog].
///
/// This design-system contract deliberately does not depend on editor state or
/// notifier types. Feature code can map it to its own immutable domain model.
@immutable
final class PokeMapEraserFootprintResult {
  const PokeMapEraserFootprintResult._({
    required this.mode,
    required this.width,
    required this.height,
  })  : assert(width > 0),
        assert(height > 0);

  const PokeMapEraserFootprintResult.singleTile()
      : mode = PokeMapEraserFootprintMode.singleTile,
        width = 1,
        height = 1;

  const PokeMapEraserFootprintResult.previousBrush({
    required int width,
    required int height,
  }) : this._(
          mode: PokeMapEraserFootprintMode.previousBrush,
          width: width,
          height: height,
        );

  const PokeMapEraserFootprintResult.custom({
    required int width,
    required int height,
  }) : this._(
          mode: PokeMapEraserFootprintMode.custom,
          width: width,
          height: height,
        );

  final PokeMapEraserFootprintMode mode;
  final int width;
  final int height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PokeMapEraserFootprintResult &&
          mode == other.mode &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(mode, width, height);

  @override
  String toString() => 'PokeMapEraserFootprintResult($mode, $width × $height)';
}

/// Lets the author choose an eraser size without coupling it to the last brush.
///
/// [previousBrushSize] is optional because a project may not have used a paint
/// brush yet. Custom dimensions are validated inclusively from `1` to
/// [maxDimension]. Previous-brush dimensions stay exact and are only required
/// to be positive.
Future<PokeMapEraserFootprintResult?> showPokeMapEraserFootprintDialog(
  BuildContext context, {
  required PokeMapEraserFootprintResult initialValue,
  ({int width, int height})? previousBrushSize,
  required int maxDimension,
}) {
  assert(maxDimension > 0);
  final colors = context.pokeMapColors;
  return showGeneralDialog<PokeMapEraserFootprintResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fermer le réglage de la gomme',
    barrierColor: colors.chromeBackground.withValues(alpha: 0.78),
    transitionDuration: const Duration(milliseconds: 140),
    pageBuilder: (dialogContext, animation, secondaryAnimation) =>
        _PokeMapEraserFootprintDialog(
      initialValue: initialValue,
      previousBrushSize: previousBrushSize,
      maxDimension: maxDimension,
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final class _PokeMapEraserFootprintDialog extends StatefulWidget {
  const _PokeMapEraserFootprintDialog({
    required this.initialValue,
    required this.previousBrushSize,
    required this.maxDimension,
  });

  final PokeMapEraserFootprintResult initialValue;
  final ({int width, int height})? previousBrushSize;
  final int maxDimension;

  @override
  State<_PokeMapEraserFootprintDialog> createState() =>
      _PokeMapEraserFootprintDialogState();
}

final class _PokeMapEraserFootprintDialogState
    extends State<_PokeMapEraserFootprintDialog> {
  late PokeMapEraserFootprintMode _mode;
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late final FocusNode _widthFocusNode;

  ({int width, int height})? get _previousBrushSize {
    final supplied = widget.previousBrushSize;
    if (supplied != null && supplied.width > 0 && supplied.height > 0) {
      return supplied;
    }
    final initial = widget.initialValue;
    if (initial.mode == PokeMapEraserFootprintMode.previousBrush) {
      return (width: initial.width, height: initial.height);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    _mode = initial.mode == PokeMapEraserFootprintMode.previousBrush &&
            _previousBrushSize == null
        ? PokeMapEraserFootprintMode.singleTile
        : initial.mode;
    final initialCustomWidth =
        initial.mode == PokeMapEraserFootprintMode.custom ? initial.width : 1;
    final initialCustomHeight =
        initial.mode == PokeMapEraserFootprintMode.custom ? initial.height : 1;
    _widthController = TextEditingController(
      text: initialCustomWidth.toString(),
    );
    _heightController = TextEditingController(
      text: initialCustomHeight.toString(),
    );
    _widthFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _widthFocusNode.dispose();
    super.dispose();
  }

  int? _parseCustomDimension(TextEditingController controller) {
    final value = int.tryParse(controller.text.trim());
    if (value == null || value < 1 || value > widget.maxDimension) {
      return null;
    }
    return value;
  }

  String? _customError(TextEditingController controller) {
    if (_parseCustomDimension(controller) != null) return null;
    return 'Entrez un entier entre 1 et ${widget.maxDimension}.';
  }

  PokeMapEraserFootprintResult? get _result {
    switch (_mode) {
      case PokeMapEraserFootprintMode.singleTile:
        return const PokeMapEraserFootprintResult.singleTile();
      case PokeMapEraserFootprintMode.previousBrush:
        final size = _previousBrushSize;
        if (size == null) return null;
        return PokeMapEraserFootprintResult.previousBrush(
          width: size.width,
          height: size.height,
        );
      case PokeMapEraserFootprintMode.custom:
        final width = _parseCustomDimension(_widthController);
        final height = _parseCustomDimension(_heightController);
        if (width == null || height == null) return null;
        return PokeMapEraserFootprintResult.custom(
          width: width,
          height: height,
        );
    }
  }

  void _selectMode(PokeMapEraserFootprintMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    if (mode == PokeMapEraserFootprintMode.custom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _widthFocusNode.requestFocus();
      });
    }
  }

  void _submit() {
    final result = _result;
    if (result == null) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final viewport = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(680.0, math.max(340.0, viewport.width - 48));
    final dialogHeight = math.min(620.0, math.max(420.0, viewport.height - 48));
    final previousSize = _previousBrushSize;
    final result = _result;

    return SafeArea(
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context).pop(),
        },
        child: FocusTraversalGroup(
          child: Center(
            child: Material(
              type: MaterialType.transparency,
              child: Semantics(
                key: pokeMapEraserFootprintDialogKey,
                container: true,
                scopesRoute: true,
                namesRoute: true,
                label: 'Taille de la gomme',
                explicitChildNodes: true,
                child: SizedBox(
                  width: dialogWidth,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: dialogHeight),
                    child: PokeMapPanel(
                      padding: EdgeInsets.zero,
                      header: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                        child: Row(
                          children: [
                            Icon(
                              Icons.cleaning_services_rounded,
                              color: colors.mapAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Taille de la gomme',
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Choisissez son emprise sans modifier '
                                    'la taille de vos outils de peinture.',
                                    style: TextStyle(
                                      color: colors.textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      footer: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            PokeMapButton(
                              onPressed: () => Navigator.of(context).pop(),
                              variant: PokeMapButtonVariant.secondary,
                              child: const Text('Annuler'),
                            ),
                            const SizedBox(width: 8),
                            PokeMapButton(
                              key: pokeMapEraserFootprintApplyButtonKey,
                              onPressed: result == null ? null : _submit,
                              autofocus: result != null &&
                                  _mode != PokeMapEraserFootprintMode.custom,
                              child: const Text('Utiliser cette gomme'),
                            ),
                          ],
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final choices = <Widget>[
                                  _EraserModeChoice(
                                    buttonKey: pokeMapEraserSingleTileChoiceKey,
                                    label: 'Une case',
                                    detail: '1 × 1 case',
                                    selected: _mode ==
                                        PokeMapEraserFootprintMode.singleTile,
                                    onPressed: () => _selectMode(
                                      PokeMapEraserFootprintMode.singleTile,
                                    ),
                                  ),
                                  _EraserModeChoice(
                                    buttonKey:
                                        pokeMapEraserPreviousBrushChoiceKey,
                                    label: 'Pinceau précédent',
                                    detail: previousSize == null
                                        ? 'Aucun pinceau à reprendre'
                                        : '${previousSize.width} × '
                                            '${previousSize.height} cases',
                                    selected: _mode ==
                                        PokeMapEraserFootprintMode
                                            .previousBrush,
                                    onPressed: previousSize == null
                                        ? null
                                        : () => _selectMode(
                                              PokeMapEraserFootprintMode
                                                  .previousBrush,
                                            ),
                                  ),
                                  _EraserModeChoice(
                                    buttonKey: pokeMapEraserCustomChoiceKey,
                                    label: 'Personnalisée',
                                    detail: 'De 1 à ${widget.maxDimension}',
                                    selected: _mode ==
                                        PokeMapEraserFootprintMode.custom,
                                    onPressed: () => _selectMode(
                                      PokeMapEraserFootprintMode.custom,
                                    ),
                                  ),
                                ];
                                if (constraints.maxWidth < 560) {
                                  return Column(
                                    children: [
                                      for (var index = 0;
                                          index < choices.length;
                                          index++) ...[
                                        if (index > 0)
                                          const SizedBox(height: 8),
                                        choices[index],
                                      ],
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var index = 0;
                                        index < choices.length;
                                        index++) ...[
                                      if (index > 0) const SizedBox(width: 8),
                                      Expanded(child: choices[index]),
                                    ],
                                  ],
                                );
                              },
                            ),
                            if (_mode == PokeMapEraserFootprintMode.custom) ...[
                              const SizedBox(height: 18),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: PokeMapTextField(
                                      label: 'Largeur (cases)',
                                      controller: _widthController,
                                      focusNode: _widthFocusNode,
                                      fieldKey: pokeMapEraserWidthFieldKey,
                                      errorText: _customError(_widthController),
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.next,
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: PokeMapTextField(
                                      label: 'Hauteur (cases)',
                                      controller: _heightController,
                                      fieldKey: pokeMapEraserHeightFieldKey,
                                      errorText:
                                          _customError(_heightController),
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                      onSubmitted: (_) => _submit(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 18),
                            PokeMapCard(
                              selected: result != null,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.crop_free_rounded,
                                    color: result == null
                                        ? colors.error
                                        : colors.mapAccent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      result == null
                                          ? 'Corrigez la taille personnalisée.'
                                          : 'Taille choisie : ${result.width} × '
                                              '${result.height} '
                                              '${result.width * result.height > 1 ? 'cases' : 'case'}',
                                      style: TextStyle(
                                        color: result == null
                                            ? colors.error
                                            : colors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _EraserModeChoice extends StatelessWidget {
  const _EraserModeChoice({
    required this.buttonKey,
    required this.label,
    required this.detail,
    required this.selected,
    required this.onPressed,
  });

  final Key buttonKey;
  final String label;
  final String detail;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          selected: selected,
          inMutuallyExclusiveGroup: true,
          child: PokeMapButton(
            key: buttonKey,
            onPressed: onPressed,
            variant: PokeMapButtonVariant.secondary,
            isSelected: selected,
            size: PokeMapButtonSize.compact,
            child: Text(label),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: onPressed == null ? colors.textDisabled : colors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
`````

### 15.6 `packages/map_editor/test/application/services/map_viewport_navigation_test.dart`

`````dart
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/services/map_viewport_navigation.dart';

void main() {
  group('MapViewportNavigation pure geometry', () {
    test('pans without changing zoom', () {
      const initial = MapViewport(
        zoom: 1.5,
        panOffset: Offset(10, 20),
      );

      final result = MapViewportNavigation.panBy(
        viewport: initial,
        delta: const Offset(12, -8),
      );

      expect(result.zoom, 1.5);
      expect(result.panOffset, const Offset(22, 12));
    });

    test('zooms around the pointer without moving its world anchor', () {
      const initial = MapViewport(
        zoom: 2,
        panOffset: Offset(10, 20),
      );
      const pointer = Offset(110, 220);

      final result = MapViewportNavigation.zoomAt(
        viewport: initial,
        focalPoint: pointer,
        targetZoom: 4,
      );

      expect(result.zoom, 4);
      expect(result.panOffset, const Offset(-90, -180));
      expect(
        MapViewportNavigation.worldPointAt(
          viewport: result,
          viewportPoint: pointer,
        ),
        const Offset(50, 100),
      );
    });

    test('clamps zoom while preserving the pointer anchor', () {
      const initial = MapViewport(
        zoom: 1,
        panOffset: Offset(-50, 25),
      );
      const pointer = Offset(75, 125);
      final worldBefore = MapViewportNavigation.worldPointAt(
        viewport: initial,
        viewportPoint: pointer,
      );

      final result = MapViewportNavigation.zoomAt(
        viewport: initial,
        focalPoint: pointer,
        targetZoom: 99,
      );

      expect(result.zoom, MapViewportNavigation.maxZoom);
      expect(
        MapViewportNavigation.worldPointAt(
          viewport: result,
          viewportPoint: pointer,
        ),
        worldBefore,
      );
    });

    test('converts command wheel deltas to multiplicative anchored zoom', () {
      const initial = MapViewport(
        zoom: 2,
        panOffset: Offset(30, 40),
      );
      const pointer = Offset(330, 240);
      final worldBefore = MapViewportNavigation.worldPointAt(
        viewport: initial,
        viewportPoint: pointer,
      );

      final zoomIn = MapViewportNavigation.zoomFromScroll(
        viewport: initial,
        focalPoint: pointer,
        scrollDeltaY: -120,
      );
      final zoomOut = MapViewportNavigation.zoomFromScroll(
        viewport: initial,
        focalPoint: pointer,
        scrollDeltaY: 120,
      );

      expect(zoomIn.zoom, greaterThan(initial.zoom));
      expect(zoomOut.zoom, lessThan(initial.zoom));
      expect(
        MapViewportNavigation.worldPointAt(
          viewport: zoomIn,
          viewportPoint: pointer,
        ),
        worldBefore,
      );
      expect(
        MapViewportNavigation.worldPointAt(
          viewport: zoomOut,
          viewportPoint: pointer,
        ),
        worldBefore,
      );
    });

    test('resolves cumulative native pan and pinch from one start snapshot',
        () {
      const initial = MapViewport(
        zoom: 2,
        panOffset: Offset(10, 20),
      );
      const focalPoint = Offset(110, 220);

      final result = MapViewportNavigation.panZoomFromStart(
        startViewport: initial,
        startFocalPoint: focalPoint,
        cumulativePan: const Offset(20, -10),
        scale: 1.5,
      );

      expect(result.zoom, 3);
      expect(result.panOffset, const Offset(-20, -90));
      expect(
        MapViewportNavigation.worldPointAt(
          viewport: result,
          viewportPoint: focalPoint + const Offset(20, -10),
        ),
        const Offset(50, 100),
      );
    });

    test('repeated absolute pan zoom updates cannot accumulate drift', () {
      const initial = MapViewport(
        zoom: 1.25,
        panOffset: Offset(-30, 45),
      );
      const focalPoint = Offset(280, 190);

      MapViewport resolve(Offset pan, double scale) {
        return MapViewportNavigation.panZoomFromStart(
          startViewport: initial,
          startFocalPoint: focalPoint,
          cumulativePan: pan,
          scale: scale,
        );
      }

      final first = resolve(const Offset(12, -4), 1.2);
      final repeated = resolve(const Offset(12, -4), 1.2);
      final directFinal = resolve(const Offset(40, 18), 0.75);
      final finalAfterIntermediate = resolve(const Offset(40, 18), 0.75);

      expect(repeated.zoom, first.zoom);
      expect(repeated.panOffset, first.panOffset);
      expect(finalAfterIntermediate.zoom, directFinal.zoom);
      expect(finalAfterIntermediate.panOffset, directFinal.panOffset);
    });

    test('fits and centers the complete map with a safe margin', () {
      final result = MapViewportNavigation.fitMap(
        mapPixelSize: const Size(640, 320),
        viewportSize: const Size(1000, 700),
        margin: 40,
      );

      expect(result.zoom, 1.4375);
      expect(result.panOffset, const Offset(40, 120));
    });

    test('fit clamps tiny maps to the maximum zoom', () {
      final result = MapViewportNavigation.fitMap(
        mapPixelSize: const Size(8, 8),
        viewportSize: const Size(1000, 700),
      );

      expect(result.zoom, MapViewportNavigation.maxZoom);
      expect(result.panOffset, const Offset(480, 330));
    });

    test('fit clamps huge maps to the minimum zoom', () {
      final result = MapViewportNavigation.fitMap(
        mapPixelSize: const Size(20000, 10000),
        viewportSize: const Size(1000, 700),
      );

      expect(result.zoom, MapViewportNavigation.minZoom);
      expect(result.panOffset, const Offset(-500, -150));
    });

    test('centers the map without changing the current zoom', () {
      final result = MapViewportNavigation.centerMap(
        mapPixelSize: const Size(640, 320),
        viewportSize: const Size(1000, 700),
        zoom: 2,
      );

      expect(result.zoom, 2);
      expect(result.panOffset, const Offset(-140, 30));
    });

    test('sets 100 percent around the viewport center', () {
      const initial = MapViewport(
        zoom: 2,
        panOffset: Offset(-300, -100),
      );
      const viewportSize = Size(1000, 700);
      final center = viewportSize.center(Offset.zero);
      final worldBefore = MapViewportNavigation.worldPointAt(
        viewport: initial,
        viewportPoint: center,
      );

      final result = MapViewportNavigation.actualSize(
        viewport: initial,
        viewportSize: viewportSize,
      );

      expect(result.zoom, 1);
      expect(
        MapViewportNavigation.worldPointAt(
          viewport: result,
          viewportPoint: center,
        ),
        worldBefore,
      );
    });
  });
}
`````

### 15.7 `packages/map_editor/test/editor_notifier_active_stroke_interlock_test.dart`

`````dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core_providers.dart';
import 'package:map_editor/src/application/models/map_history_snapshot.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/border_map_editing/application/pending_border_save_guard.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('EditorNotifier active map stroke interlock', () {
    test('save performs no I/O and preserves the cancellable stroke', () async {
      final fixture = _createFixture();
      final before = fixture.notifier.state;

      final outcome = await fixture.notifier.saveActiveMap();

      expect(outcome, ActiveMapSaveOutcome.unavailable);
      expect(fixture.repository.savedMaps, isEmpty);
      expect(fixture.notifier.state, before);

      // A blocked global command must leave ownership with the canvas so its
      // normal rollback terminal can still restore the exact checkpoint.
      fixture.notifier.cancelMapStroke();
      expect(fixture.notifier.state.activeMap, _cleanMap);
      expect(fixture.notifier.state.mapStrokeStart, isNull);
      expect(fixture.notifier.state.mapUndoStack, before.mapUndoStack);
      expect(fixture.notifier.state.mapRedoStack, before.mapRedoStack);
    });

    test('undo leaves the live stroke and both history stacks untouched', () {
      final fixture = _createFixture();
      final before = fixture.notifier.state;

      fixture.notifier.undoMap();

      expect(fixture.notifier.state, before);
      fixture.notifier.cancelMapStroke();
      expect(fixture.notifier.state.activeMap, _cleanMap);
      expect(fixture.notifier.state.mapUndoStack, before.mapUndoStack);
      expect(fixture.notifier.state.mapRedoStack, before.mapRedoStack);
    });

    test('redo preserves a pre-existing redo stack during the live stroke', () {
      final fixture = _createFixture();
      final before = fixture.notifier.state;

      fixture.notifier.redoMap();

      expect(fixture.notifier.state, before);
      fixture.notifier.cancelMapStroke();
      expect(fixture.notifier.state.activeMap, _cleanMap);
      expect(fixture.notifier.state.mapUndoStack, before.mapUndoStack);
      expect(fixture.notifier.state.mapRedoStack, before.mapRedoStack);
    });
  });
}

({
  ProviderContainer container,
  EditorNotifier notifier,
  _RecordingMapRepository repository,
}) _createFixture() {
  final repository = _RecordingMapRepository();
  final container = ProviderContainer(
    overrides: <Override>[
      mapRepositoryProvider.overrideWith((ref) => repository),
    ],
  );
  addTearDown(container.dispose);
  final notifier = container.read(editorNotifierProvider.notifier)
    ..state = const EditorState(
      workspaceMode: EditorWorkspaceMode.map,
      project: _project,
      activeMap: _partialMap,
      activeMapPath: '/project/maps/town.json',
      activeLayerId: 'ground',
      savedMapSnapshot: _cleanMap,
      mapStrokeStart: MapHistorySnapshot(
        map: _cleanMap,
        activeLayerId: 'ground',
      ),
      mapUndoStack: <MapHistorySnapshot>[
        MapHistorySnapshot(map: _undoCandidate),
      ],
      mapRedoStack: <MapHistorySnapshot>[
        MapHistorySnapshot(map: _redoCandidate),
      ],
      canUndoMap: true,
      canRedoMap: true,
      isDirty: true,
    );
  return (
    container: container,
    notifier: notifier,
    repository: repository,
  );
}

class _RecordingMapRepository implements MapRepository {
  final List<MapData> savedMaps = <MapData>[];

  @override
  Future<void> deleteMap(String path) async {}

  @override
  Future<MapData> loadMap(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> renameMap(String oldPath, String newPath) async {}

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async {
    savedMaps.add(map);
  }
}

const _project = ProjectManifest(
  name: 'Demo',
  maps: <ProjectMapEntry>[
    ProjectMapEntry(
      id: 'town',
      name: 'Town',
      relativePath: 'maps/town.json',
    ),
  ],
  tilesets: <ProjectTilesetEntry>[],
  surfaceCatalog: ProjectSurfaceCatalog.empty(),
);

const _cleanMap = MapData(
  id: 'town',
  name: 'Town',
  size: GridSize(width: 2, height: 1),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Ground',
      tilesetId: 'world',
      tiles: <int>[1, 1],
    ),
  ],
);

const _partialMap = MapData(
  id: 'town',
  name: 'Town',
  size: GridSize(width: 2, height: 1),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Ground',
      tilesetId: 'world',
      tiles: <int>[0, 1],
    ),
  ],
);

const _undoCandidate = MapData(
  id: 'town',
  name: 'Town',
  size: GridSize(width: 2, height: 1),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Ground',
      tilesetId: 'world',
      tiles: <int>[2, 2],
    ),
  ],
);

const _redoCandidate = MapData(
  id: 'town',
  name: 'Town',
  size: GridSize(width: 2, height: 1),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Ground',
      tilesetId: 'world',
      tiles: <int>[3, 3],
    ),
  ],
);
`````

### 15.8 `packages/map_editor/test/editor_notifier_eraser_footprint_test.dart`

`````dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_tool_preview.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  group('EditorNotifier independent eraser footprint', () {
    test('a multi-tile active brush still erases 1x1 by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      const map = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 3, height: 3),
        layers: <MapLayer>[
          TileLayer(
            id: 'ground',
            name: 'Ground',
            tilesetId: 'world',
            tiles: <int>[7, 7, 7, 7, 7, 7, 7, 7, 7],
          ),
        ],
      );
      notifier.state = const EditorState(
        project: _projectWithLargeBrush,
        activeMap: map,
        activeLayerId: 'ground',
        activeTool: EditorToolType.eraser,
        activeBrush: EditorBrush.projectElement(elementId: 'house'),
        savedMapSnapshot: map,
      );

      final preview = notifier.resolveMapToolPreview(
        hoveredTile: const GridPos(x: 1, y: 1),
        tilesetColumnsById: const <String, int>{},
      );
      expect(preview?.size, const GridSize(width: 1, height: 1));

      notifier.beginMapStroke();
      notifier.eraseAt(const GridPos(x: 1, y: 1));
      notifier.endMapStroke();

      final state = container.read(editorNotifierProvider);
      final layer = state.activeMap!.layers.single as TileLayer;
      expect(layer.tiles, const <int>[7, 7, 7, 7, 0, 7, 7, 7, 7]);
      expect(state.mapUndoStack, hasLength(1));
      expect(state.isDirty, isTrue);
    });

    test(
        'previous brush captures once and ignores later brush, layer, and collision size changes',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithLayers(
        const <MapLayer>[
          TileLayer(
            id: 'ground',
            name: 'Ground',
            tilesetId: 'world',
            tiles: <int>[
              7,
              7,
              7,
              7,
              7,
              7,
              7,
              7,
              7,
              7,
              7,
              7,
              7,
              7,
              7,
              7,
            ],
          ),
          CollisionLayer(
            id: 'collision',
            name: 'Collision',
            collisions: <bool>[
              true,
              true,
              true,
              true,
              true,
              true,
              true,
              true,
              true,
              true,
              true,
              true,
              true,
              true,
              true,
              true,
            ],
          ),
        ],
      );
      notifier.state = EditorState(
        project: _projectWithLargeBrush,
        activeMap: map,
        activeLayerId: 'ground',
        activeTool: EditorToolType.eraser,
        activeBrush: const EditorBrush.projectElement(elementId: 'house'),
        savedMapSnapshot: map,
      );

      expect(notifier.capturePreviousBrushEraserFootprint(), isTrue);
      expect(
        notifier.state.eraserFootprint,
        const EditorEraserFootprint.previousBrush(
          size: GridSize(width: 2, height: 3),
        ),
      );
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(notifier.state.isDirty, isFalse);

      notifier.state = notifier.state.copyWith(
        activeBrush: const EditorBrush.none(),
      );
      notifier.setCollisionBrushSizeMode(CollisionBrushSizeMode.singleTile);
      notifier.setActiveLayer('collision');

      final preview = notifier.resolveMapToolPreview(
        hoveredTile: const GridPos(x: 1, y: 0),
        tilesetColumnsById: const <String, int>{},
      );
      expect(preview?.size, const GridSize(width: 2, height: 3));

      notifier.beginMapStroke();
      notifier.eraseAt(const GridPos(x: 1, y: 0));
      notifier.endMapStroke();

      final layer = notifier.state.activeMap!.layers[1] as CollisionLayer;
      expect(
        layer.collisions,
        const <bool>[
          true,
          false,
          false,
          true,
          true,
          false,
          false,
          true,
          true,
          false,
          false,
          true,
          true,
          true,
          true,
          true,
        ],
      );
    });

    test('custom dimensions are validated without touching map history', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapFor(_LayerKind.tile);
      notifier.state = EditorState(
        activeMap: map,
        activeLayerId: 'layer',
        activeTool: EditorToolType.eraser,
        savedMapSnapshot: map,
      );

      expect(notifier.setCustomEraserFootprint(width: 1, height: 1), isTrue);
      expect(notifier.setCustomEraserFootprint(width: 0, height: 1), isFalse);
      expect(notifier.setCustomEraserFootprint(width: -1, height: 1), isFalse);
      expect(
        notifier.setCustomEraserFootprint(
          width: kMaxEditorEraserFootprintDimension + 1,
          height: 1,
        ),
        isFalse,
      );
      expect(
        notifier.setCustomEraserFootprint(
          width: kMaxEditorEraserFootprintDimension,
          height: kMaxEditorEraserFootprintDimension,
        ),
        isTrue,
      );

      expect(
        notifier.state.eraserFootprint,
        const EditorEraserFootprint.custom(
          size: GridSize(
            width: kMaxEditorEraserFootprintDimension,
            height: kMaxEditorEraserFootprintDimension,
          ),
        ),
      );
      expect(notifier.state.activeMap, map);
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(notifier.state.mapRedoStack, isEmpty);
      expect(notifier.state.isDirty, isFalse);
    });

    for (final kind in _LayerKind.values) {
      test('${kind.name} preview and commit share the custom rectangle', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(editorNotifierProvider.notifier);
        final map = _mapFor(kind);
        notifier.state = EditorState(
          activeMap: map,
          activeLayerId: 'layer',
          activeTool: EditorToolType.eraser,
          eraserFootprint: const EditorEraserFootprint.custom(
            size: GridSize(width: 2, height: 2),
          ),
          savedMapSnapshot: map,
        );

        final preview = notifier.resolveMapToolPreview(
          hoveredTile: const GridPos(x: 1, y: 1),
          tilesetColumnsById: const <String, int>{},
        );
        expect(preview?.size, const GridSize(width: 2, height: 2));

        notifier.beginMapStroke();
        notifier.eraseAt(const GridPos(x: 1, y: 1));
        notifier.endMapStroke();

        final layer = notifier.state.activeMap!.layers.single;
        for (var y = 0; y < 4; y++) {
          for (var x = 0; x < 4; x++) {
            final shouldRemain = x < 1 || x > 2 || y < 1 || y > 2;
            expect(
              _isFilled(layer, x: x, y: y),
              shouldRemain,
              reason: '${kind.name} cell ($x,$y)',
            );
          }
        }
        expect(notifier.state.mapUndoStack, hasLength(1));
      });

      test('${kind.name} erase clips at the lower-right map edge', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(editorNotifierProvider.notifier);
        final map = _mapFor(kind);
        notifier.state = EditorState(
          activeMap: map,
          activeLayerId: 'layer',
          activeTool: EditorToolType.eraser,
          eraserFootprint: const EditorEraserFootprint.custom(
            size: GridSize(width: 2, height: 3),
          ),
          savedMapSnapshot: map,
        );

        final preview = notifier.resolveMapToolPreview(
          hoveredTile: const GridPos(x: 3, y: 3),
          tilesetColumnsById: const <String, int>{},
        );
        expect(preview?.size, const GridSize(width: 2, height: 3));

        notifier.beginMapStroke();
        notifier.eraseAt(const GridPos(x: 3, y: 3));
        notifier.endMapStroke();

        final layer = notifier.state.activeMap!.layers.single;
        for (var y = 0; y < 4; y++) {
          for (var x = 0; x < 4; x++) {
            expect(
              _isFilled(layer, x: x, y: y),
              x != 3 || y != 3,
              reason: '${kind.name} clipped cell ($x,$y)',
            );
          }
        }
      });
    }

    test('collision brush sizing affects collision paint but never eraser', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapFor(_LayerKind.collision);
      notifier.state = EditorState(
        project: _projectWithLargeBrush,
        activeMap: map,
        activeLayerId: 'layer',
        activeTool: EditorToolType.eraser,
        activeBrush: const EditorBrush.projectElement(elementId: 'house'),
        collisionBrushSizeMode: CollisionBrushSizeMode.brushFootprint,
        savedMapSnapshot: map,
      );

      MapToolPreview? preview() => notifier.resolveMapToolPreview(
            hoveredTile: const GridPos(x: 0, y: 0),
            tilesetColumnsById: const <String, int>{},
          );

      expect(preview()?.size, const GridSize(width: 1, height: 1));
      notifier.toggleCollisionBrushSizeMode();
      expect(preview()?.size, const GridSize(width: 1, height: 1));

      notifier.setCollisionBrushSizeMode(
        CollisionBrushSizeMode.brushFootprint,
      );
      notifier.selectTool(EditorToolType.collisionPaint);
      expect(preview()?.size, const GridSize(width: 2, height: 3));
    });

    test('invalid injected footprint is rejected before preview or commit', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapFor(_LayerKind.tile);
      notifier.state = EditorState(
        activeMap: map,
        activeLayerId: 'layer',
        activeTool: EditorToolType.eraser,
        eraserFootprint: const EditorEraserFootprint.previousBrush(
          size: GridSize(
            width: kMaxEditorEraserFootprintDimension + 1,
            height: 1,
          ),
        ),
        savedMapSnapshot: map,
      );

      expect(
        notifier.resolveMapToolPreview(
          hoveredTile: const GridPos(x: 0, y: 0),
          tilesetColumnsById: const <String, int>{},
        ),
        isNull,
      );
      notifier.eraseAt(const GridPos(x: 0, y: 0));

      expect(notifier.state.activeMap, map);
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(notifier.state.isDirty, isFalse);
      expect(notifier.state.errorMessage, contains('between 1 and'));
    });

    test('erasing an already empty rectangle is a clean no-op', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _emptyTileMap();
      notifier.state = EditorState(
        activeMap: map,
        activeLayerId: 'layer',
        activeTool: EditorToolType.eraser,
        eraserFootprint: const EditorEraserFootprint.custom(
          size: GridSize(width: 2, height: 2),
        ),
        savedMapSnapshot: map,
      );

      notifier.beginMapStroke();
      notifier.eraseAt(const GridPos(x: 1, y: 1));
      notifier.endMapStroke();

      expect(notifier.state.activeMap, same(map));
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(notifier.state.isDirty, isFalse);
    });

    test('multiple erase samples in one stroke create one undo entry', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapFor(_LayerKind.tile);
      notifier.state = EditorState(
        activeMap: map,
        activeLayerId: 'layer',
        activeTool: EditorToolType.eraser,
        eraserFootprint: const EditorEraserFootprint.custom(
          size: GridSize(width: 2, height: 1),
        ),
        savedMapSnapshot: map,
      );

      notifier.beginMapStroke();
      notifier.eraseAt(const GridPos(x: 0, y: 0));
      notifier.eraseAt(const GridPos(x: 2, y: 0));
      notifier.endMapStroke();

      expect(notifier.state.mapUndoStack, hasLength(1));
      expect(notifier.state.isDirty, isTrue);
      expect(
        (notifier.state.activeMap!.layers.single as TileLayer).tiles.take(4),
        everyElement(0),
      );

      notifier.undoMap();
      expect(notifier.state.activeMap, map);
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(notifier.state.isDirty, isFalse);
    });
  });
}

const _projectWithLargeBrush = ProjectManifest(
  name: 'Eraser Test',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'house',
      name: 'House',
      tilesetId: 'world',
      categoryId: 'buildings',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 3),
        ),
      ],
    ),
  ],
  surfaceCatalog: ProjectSurfaceCatalog.empty(),
);

enum _LayerKind { tile, collision, terrain, path, surface }

MapData _mapFor(_LayerKind kind) {
  const filledTiles = <int>[
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
  ];
  const filledFlags = <bool>[
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
  ];
  const filledTerrain = <TerrainType>[
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
  ];
  final layer = switch (kind) {
    _LayerKind.tile => const MapLayer.tile(
        id: 'layer',
        name: 'Tiles',
        tilesetId: 'world',
        tiles: filledTiles,
      ),
    _LayerKind.collision => const MapLayer.collision(
        id: 'layer',
        name: 'Collision',
        collisions: filledFlags,
      ),
    _LayerKind.terrain => const MapLayer.terrain(
        id: 'layer',
        name: 'Terrain',
        terrains: filledTerrain,
      ),
    _LayerKind.path => const MapLayer.path(
        id: 'layer',
        name: 'Path',
        presetId: 'road',
        cells: filledFlags,
      ),
    _LayerKind.surface => MapLayer.surface(
        id: 'layer',
        name: 'Surface',
        placements: <SurfaceCellPlacement>[
          for (var y = 0; y < 4; y++)
            for (var x = 0; x < 4; x++)
              SurfaceCellPlacement(
                x: x,
                y: y,
                surfacePresetId: 'water',
              ),
        ],
      ),
  };
  return _mapWithLayers(<MapLayer>[layer]);
}

MapData _emptyTileMap() {
  return _mapWithLayers(
    const <MapLayer>[
      MapLayer.tile(
        id: 'layer',
        name: 'Tiles',
        tilesetId: 'world',
        tiles: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
    ],
  );
}

MapData _mapWithLayers(List<MapLayer> layers) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 4, height: 4),
    layers: layers,
  );
}

bool _isFilled(MapLayer layer, {required int x, required int y}) {
  final index = y * 4 + x;
  return switch (layer) {
    TileLayer(:final tiles) => tiles[index] != 0,
    CollisionLayer(:final collisions) => collisions[index],
    TerrainLayer(:final terrains) => terrains[index] != TerrainType.none,
    PathLayer(:final cells) => cells[index],
    SurfaceLayer(:final placements) =>
      placements.any((placement) => placement.x == x && placement.y == y),
    _ => throw StateError('Unsupported layer: ${layer.runtimeType}'),
  };
}
`````

### 15.9 `packages/map_editor/test/features/editor/application/map_canvas_interaction_controller_test.dart`

`````dart
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/application/map_canvas_interaction_controller.dart';

void main() {
  group('MapCanvasInteractionController', () {
    test('resolves buttons and modifiers before any editing intent', () {
      final controller = MapCanvasInteractionController();

      final primary = controller.beginPointer(
        _input(buttons: kPrimaryButton),
      );
      expect(primary.status, MapCanvasInteractionStartStatus.started);
      expect(
        primary.session?.kind,
        MapCanvasInteractionKind.pendingPrimary,
      );
      expect(
        controller.cancelActive()?.terminal,
        MapCanvasInteractionTerminal.rollback,
      );

      final spacePrimary = controller.beginPointer(
        _input(
          pointerId: 2,
          buttons: kPrimaryButton,
          modifiers: const MapCanvasInteractionModifiers(space: true),
        ),
      );
      expect(spacePrimary.status, MapCanvasInteractionStartStatus.started);
      expect(
        spacePrimary.session?.kind,
        MapCanvasInteractionKind.panning,
      );
      expect(
        spacePrimary.session?.modifiersAtStart.space,
        isTrue,
      );
      controller.finishPointer(2);

      final secondary = controller.beginPointer(
        _input(pointerId: 12, buttons: kSecondaryButton),
      );
      expect(secondary.status, MapCanvasInteractionStartStatus.ignored);
      expect(controller.isIdle, isTrue);

      final middle = controller.beginPointer(
        _input(pointerId: 14, buttons: kTertiaryButton),
      );
      expect(
        middle.session?.kind,
        MapCanvasInteractionKind.panning,
      );
      controller.finishPointer(14);

      final mixed = controller.beginPointer(
        _input(
          pointerId: 99,
          buttons: kPrimaryButton | kSecondaryButton,
        ),
      );
      expect(
        mixed.status,
        MapCanvasInteractionStartStatus.rejectedButtons,
      );
      expect(controller.isIdle, isTrue);
    });

    test('keeps one exclusive owner and ignores non-owner terminals', () {
      final controller = MapCanvasInteractionController();
      final started = controller.beginPointer(
        _input(pointerId: 7, buttons: kPrimaryButton),
      );
      final interactionId = started.session!.interactionId;

      final second = controller.beginPointer(
        _input(pointerId: 8, buttons: kPrimaryButton),
      );
      expect(second.status, MapCanvasInteractionStartStatus.rejectedBusy);
      expect(controller.activeSession?.interactionId, interactionId);
      expect(controller.ownsPointer(7), isTrue);
      expect(controller.ownsPointer(8), isFalse);
      expect(controller.finishPointer(8), isNull);
      expect(controller.activeSession?.interactionId, interactionId);

      final promoted = controller.promotePending(
        pointerId: 7,
        kind: MapCanvasInteractionKind.paintingStroke,
      );
      expect(promoted?.kind, MapCanvasInteractionKind.paintingStroke);

      final finished = controller.finishPointer(7);
      expect(finished?.terminal, MapCanvasInteractionTerminal.commit);
      expect(finished?.session.interactionId, interactionId);
      expect(controller.finishPointer(7), isNull);
      expect(controller.isIdle, isTrue);
    });

    test(
        'changed move buttons rollback while matching moves and pointer up commit',
        () {
      final controller = MapCanvasInteractionController();
      controller.beginPointer(
        _input(pointerId: 41, buttons: kPrimaryButton),
      );
      controller.promotePending(
        pointerId: 41,
        kind: MapCanvasInteractionKind.paintingStroke,
      );

      expect(
        controller.cancelPointerIfButtonsChanged(
          pointerId: 41,
          buttons: kPrimaryButton,
        ),
        isNull,
      );
      expect(
        controller.cancelPointerIfButtonsChanged(
          pointerId: 99,
          buttons: kPrimaryButton | kSecondaryButton,
        ),
        isNull,
      );
      expect(
        controller.activeSession?.kind,
        MapCanvasInteractionKind.paintingStroke,
      );

      final mixed = controller.cancelPointerIfButtonsChanged(
        pointerId: 41,
        buttons: kPrimaryButton | kSecondaryButton,
      );
      expect(mixed?.terminal, MapCanvasInteractionTerminal.rollback);
      expect(
        mixed?.session.kind,
        MapCanvasInteractionKind.paintingStroke,
      );
      expect(controller.isIdle, isTrue);
      expect(
        controller.cancelPointerIfButtonsChanged(
          pointerId: 41,
          buttons: kPrimaryButton,
        ),
        isNull,
      );

      controller.beginPointer(
        _input(pointerId: 42, buttons: kPrimaryButton),
      );
      final missingButton = controller.cancelPointerIfButtonsChanged(
        pointerId: 42,
        buttons: 0,
      );
      expect(
        missingButton?.terminal,
        MapCanvasInteractionTerminal.rollback,
      );
      expect(controller.isIdle, isTrue);

      controller.beginPointer(
        _input(pointerId: 43, buttons: kPrimaryButton),
      );
      expect(
        controller.finishPointer(43)?.terminal,
        MapCanvasInteractionTerminal.commit,
      );
      expect(controller.isIdle, isTrue);
    });

    test('cancel is rollback, idempotent, and reopens scroll routing', () {
      final controller = MapCanvasInteractionController();
      expect(controller.acceptsScroll, isTrue);

      controller.beginPointer(
        _input(pointerId: 4, buttons: kPrimaryButton),
      );
      controller.promotePending(
        pointerId: 4,
        kind: MapCanvasInteractionKind.drawingZone,
      );
      expect(controller.acceptsScroll, isFalse);

      final cancelled = controller.cancelPointer(4);
      expect(cancelled?.terminal, MapCanvasInteractionTerminal.rollback);
      expect(
        cancelled?.session.kind,
        MapCanvasInteractionKind.drawingZone,
      );
      expect(controller.cancelPointer(4), isNull);
      expect(controller.acceptsScroll, isTrue);
    });

    test('pan zoom accepts only a trackpad while idle', () {
      final controller = MapCanvasInteractionController();

      final mouse = controller.beginPanZoom(
        _input(
          pointerId: 20,
          kind: MapCanvasPointerKind.mouse,
          buttons: 0,
        ),
      );
      expect(
        mouse.status,
        MapCanvasInteractionStartStatus.rejectedPointerKind,
      );

      final trackpad = controller.beginPanZoom(
        _input(
          pointerId: 21,
          kind: MapCanvasPointerKind.trackpad,
          buttons: 0,
        ),
      );
      expect(trackpad.status, MapCanvasInteractionStartStatus.started);
      expect(
        trackpad.session?.kind,
        MapCanvasInteractionKind.trackpadPanZoom,
      );
      expect(controller.finishPointer(21)?.terminal,
          MapCanvasInteractionTerminal.commit);
    });

    test('captures the complete modifier snapshot at interaction start', () {
      final controller = MapCanvasInteractionController();
      const modifiers = MapCanvasInteractionModifiers(
        shift: true,
        alt: true,
        control: true,
        meta: true,
      );

      final started = controller.beginPointer(
        _input(
          pointerId: 30,
          buttons: kPrimaryButton,
          modifiers: modifiers,
        ),
      );

      expect(started.session?.modifiersAtStart, modifiers);
      expect(started.session?.pointerKind, MapCanvasPointerKind.mouse);
      expect(started.session?.buttonsAtStart, kPrimaryButton);
      expect(started.session?.contextAtStart, _context);
    });
  });
}

MapCanvasInteractionInput _input({
  int pointerId = 1,
  MapCanvasPointerKind kind = MapCanvasPointerKind.mouse,
  int buttons = kPrimaryButton,
  MapCanvasInteractionModifiers modifiers =
      const MapCanvasInteractionModifiers(),
}) {
  return MapCanvasInteractionInput(
    pointerId: pointerId,
    pointerKind: kind,
    buttons: buttons,
    modifiers: modifiers,
    context: _context,
  );
}

const _context = MapCanvasInteractionContext(
  projectRootPath: '/projects/example',
  mapId: 'map',
  activeMapPath: '/projects/example/maps/map.json',
  layerId: 'ground',
  toolKey: 'tilePaint',
  targetId: null,
  guidedNavigation: false,
);
`````

### 15.10 `packages/map_editor/test/map_canvas_eraser_footprint_ui_test.dart`

`````dart
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/design_system/pokemap_badge.dart';

import 'shell_chrome_test_harness.dart';

void main() {
  testWidgets(
    'eraser hover shows one footprint preview and a non-interactive size badge',
    (tester) async {
      final map = buildShellChromeMap(
        width: 4,
        height: 4,
        layers: const <MapLayer>[
          MapLayer.tile(
            id: 'tiles',
            name: 'Tiles',
            tiles: <int>[
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
            ],
          ),
        ],
      );
      final initialState = EditorState(
        project: buildShellChromeProject(),
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: map,
        activeLayerId: 'tiles',
        activeTool: EditorToolType.eraser,
        eraserFootprint: const EditorEraserFootprint.custom(
          size: GridSize(width: 3, height: 2),
        ),
        savedMapSnapshot: map,
      );
      final container = await pumpEditorCanvasHostHarness(
        tester,
        initialState: initialState,
        surfaceSize: const Size(900, 700),
      );

      expect(find.text('Gomme 3×2'), findsNothing);

      final mapBox = tester.getRect(find.byType(MapCanvas));
      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(gesture.removePointer);
      await gesture.addPointer(
        location: mapBox.topLeft + const Offset(48, 48),
      );
      await gesture.moveTo(mapBox.topLeft + const Offset(48, 48));
      await tester.pump();

      expect(find.text('Gomme 3×2'), findsOneWidget);
      final badgeOverlay = find.byKey(
        const ValueKey<String>('eraser-footprint-cursor-badge'),
      );
      expect(
        find.descendant(
          of: badgeOverlay,
          matching: find.byType(PokeMapBadge),
        ),
        findsOneWidget,
      );
      final ignorePointer = tester.widget<IgnorePointer>(badgeOverlay);
      expect(ignorePointer.ignoring, isTrue);

      final customPaint = tester.widget<CustomPaint>(
        find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.painter is MapGridPainter,
        ),
      );
      final painter = customPaint.painter as MapGridPainter;
      expect(
        painter.toolPreview?.size,
        const GridSize(width: 3, height: 2),
      );
      expect(
        painter.hoveredTile,
        isNull,
        reason: 'The rectangular eraser preview replaces the generic 1x1 hover',
      );
      expect(container.read(editorNotifierProvider).isDirty, isFalse);

      container.read(editorNotifierProvider.notifier).state =
          initialState.copyWith(activeTool: EditorToolType.selection);
      await tester.pump();

      expect(find.text('Gomme 3×2'), findsNothing);
      final selectionPaint = tester.widget<CustomPaint>(
        find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.painter is MapGridPainter,
        ),
      );
      expect(
        (selectionPaint.painter as MapGridPainter).hoveredTile,
        const GridPos(x: 1, y: 1),
      );
    },
  );
}
`````

### 15.11 `packages/map_editor/test/map_canvas_interaction_arbitration_test.dart`

`````dart
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_history_snapshot.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

void main() {
  group('MapCanvas interaction arbitration', () {
    testWidgets(
      'pointer cancellation restores the exact stroke checkpoint and history',
      (tester) async {
        final container = _createContainer();
        const undoCheckpoint = MapHistorySnapshot(
          map: _historicalUndoMap,
          activeLayerId: 'collision',
        );
        const redoCheckpoint = MapHistorySnapshot(
          map: _historicalRedoMap,
          activeLayerId: 'collision',
        );
        container.read(editorNotifierProvider.notifier).state =
            const EditorState(
          project: _project,
          activeMap: _activeMap,
          activeLayerId: 'collision',
          activeTool: EditorToolType.collisionPaint,
          savedMapSnapshot: _activeMap,
          mapUndoStack: <MapHistorySnapshot>[undoCheckpoint],
          mapRedoStack: <MapHistorySnapshot>[redoCheckpoint],
          canUndoMap: true,
          canRedoMap: true,
        );
        final beforeJson = _activeMap.toJson();

        await _pumpCanvas(tester, container);
        final canvas = tester.getRect(find.byType(MapCanvas));
        final gesture = await tester.startGesture(
          canvas.topLeft + const Offset(16, 16),
          kind: ui.PointerDeviceKind.mouse,
        );
        await gesture.moveBy(const Offset(34, 0));
        await tester.pump();
        await gesture.moveBy(const Offset(34, 0));
        await tester.pump();

        final duringStroke = container.read(editorNotifierProvider);
        expect(
          (duringStroke.activeMap!.layers.single as CollisionLayer).collisions,
          const <bool>[
            true,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
          ],
        );
        expect(duringStroke.mapStrokeStart, isNotNull);
        expect(duringStroke.isDirty, isTrue);

        await gesture.cancel();
        await tester.pump();

        final cancelled = container.read(editorNotifierProvider);
        expect(cancelled.activeMap!.toJson(), beforeJson);
        expect(cancelled.mapStrokeStart, isNull);
        expect(
          cancelled.mapUndoStack,
          const <MapHistorySnapshot>[undoCheckpoint],
        );
        expect(
          cancelled.mapRedoStack,
          const <MapHistorySnapshot>[redoCheckpoint],
        );
        expect(cancelled.canUndoMap, isTrue);
        expect(cancelled.canRedoMap, isTrue);
        expect(cancelled.isDirty, isFalse);
      },
    );

    testWidgets(
      'changing buttons during paint rolls the exact transaction back',
      (tester) async {
        const pointer = 41;
        const undoCheckpoint = MapHistorySnapshot(
          map: _historicalUndoMap,
          activeLayerId: 'collision',
        );
        const redoCheckpoint = MapHistorySnapshot(
          map: _historicalRedoMap,
          activeLayerId: 'collision',
        );
        final container = _createContainer();
        container.read(editorNotifierProvider.notifier).state =
            const EditorState(
          project: _project,
          activeMap: _activeMap,
          activeLayerId: 'collision',
          activeTool: EditorToolType.collisionPaint,
          savedMapSnapshot: _activeMap,
          mapUndoStack: <MapHistorySnapshot>[undoCheckpoint],
          mapRedoStack: <MapHistorySnapshot>[redoCheckpoint],
          canUndoMap: true,
          canRedoMap: true,
        );
        final beforeJson = _activeMap.toJson();

        await _pumpCanvas(tester, container);
        final canvas = tester.getRect(find.byType(MapCanvas));
        final downPosition = canvas.topLeft + const Offset(16, 16);
        final gesture = await tester.startGesture(
          downPosition,
          pointer: pointer,
          kind: ui.PointerDeviceKind.mouse,
          buttons: kPrimaryButton,
        );
        await gesture.moveBy(const Offset(34, 0));
        await tester.pump();
        expect(
          container.read(editorNotifierProvider).mapStrokeStart,
          isNotNull,
        );

        await gesture.updateWithCustomEvent(
          PointerMoveEvent(
            pointer: pointer,
            kind: ui.PointerDeviceKind.mouse,
            device: 1,
            position: downPosition + const Offset(68, 0),
            delta: const Offset(34, 0),
            buttons: kPrimaryButton | kSecondaryButton,
          ),
        );
        await tester.pump();
        await gesture.up();
        await tester.pump();

        final rolledBack = container.read(editorNotifierProvider);
        expect(rolledBack.activeMap!.toJson(), beforeJson);
        expect(rolledBack.mapStrokeStart, isNull);
        expect(
          rolledBack.mapUndoStack,
          const <MapHistorySnapshot>[undoCheckpoint],
        );
        expect(
          rolledBack.mapRedoStack,
          const <MapHistorySnapshot>[redoCheckpoint],
        );
        expect(rolledBack.canUndoMap, isTrue);
        expect(rolledBack.canRedoMap, isTrue);
        expect(rolledBack.isDirty, isFalse);
      },
    );

    testWidgets('a multi-sample drag creates exactly one undo entry',
        (tester) async {
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'collision',
        activeTool: EditorToolType.collisionPaint,
        savedMapSnapshot: _activeMap,
      );

      await _pumpCanvas(tester, container);
      final canvas = tester.getRect(find.byType(MapCanvas));
      final gesture = await tester.startGesture(
        canvas.topLeft + const Offset(16, 16),
        kind: ui.PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(34, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(34, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      final committed = container.read(editorNotifierProvider);
      expect(
        (committed.activeMap!.layers.single as CollisionLayer).collisions,
        const <bool>[
          true,
          true,
          true,
          false,
          false,
          false,
          false,
          false,
        ],
      );
      expect(committed.mapStrokeStart, isNull);
      expect(committed.mapUndoStack, hasLength(1));
      expect(committed.mapRedoStack, isEmpty);
      expect(committed.canUndoMap, isTrue);
      expect(committed.isDirty, isTrue);

      container.read(editorNotifierProvider.notifier).undoMap();
      final undone = container.read(editorNotifierProvider);
      expect(undone.activeMap, _activeMap);
      expect(undone.isDirty, isFalse);
    });

    testWidgets(
      'middle-button drag pans without mutating the document or its history',
      (tester) async {
        final container = _createContainer();
        const historical = MapHistorySnapshot(
          map: _activeMap,
          activeLayerId: 'collision',
        );
        container.read(editorNotifierProvider.notifier).state =
            const EditorState(
          project: _project,
          activeMap: _activeMap,
          activeLayerId: 'collision',
          activeTool: EditorToolType.collisionPaint,
          savedMapSnapshot: _activeMap,
          mapUndoStack: <MapHistorySnapshot>[historical],
          canUndoMap: true,
          panOffset: Offset(10, 20),
        );
        final beforeJson = _activeMap.toJson();

        await _pumpCanvas(tester, container);
        final canvas = tester.getRect(find.byType(MapCanvas));
        final gesture = await tester.startGesture(
          canvas.center,
          kind: ui.PointerDeviceKind.mouse,
          buttons: kTertiaryButton,
        );
        await gesture.moveBy(const Offset(30, -12));
        await tester.pump();
        await gesture.up();
        await tester.pump();

        final navigated = container.read(editorNotifierProvider);
        expect(navigated.panOffset, const Offset(40, 8));
        expect(navigated.activeMap!.toJson(), beforeJson);
        expect(navigated.mapUndoStack, const <MapHistorySnapshot>[historical]);
        expect(navigated.mapRedoStack, isEmpty);
        expect(navigated.mapStrokeStart, isNull);
        expect(navigated.canUndoMap, isTrue);
        expect(navigated.isDirty, isFalse);
      },
    );

    testWidgets(
      'changing buttons during primary pan ignores the mixed delta and cancels',
      (tester) async {
        const pointer = 42;
        const historical = MapHistorySnapshot(
          map: _activeMap,
          activeLayerId: 'collision',
        );
        final container = _createContainer();
        container.read(editorNotifierProvider.notifier).state =
            const EditorState(
          project: _project,
          activeMap: _activeMap,
          activeLayerId: 'collision',
          activeTool: EditorToolType.collisionPaint,
          savedMapSnapshot: _activeMap,
          mapUndoStack: <MapHistorySnapshot>[historical],
          canUndoMap: true,
          panOffset: Offset(10, 20),
        );
        final beforeJson = _activeMap.toJson();

        await _pumpCanvas(tester, container);
        final canvas = tester.getRect(find.byType(MapCanvas));
        final downPosition = canvas.center;
        await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
        final gesture = await tester.startGesture(
          downPosition,
          pointer: pointer,
          kind: ui.PointerDeviceKind.mouse,
          buttons: kPrimaryButton,
        );
        await gesture.moveBy(const Offset(30, -12));
        await tester.pump();

        await gesture.updateWithCustomEvent(
          PointerMoveEvent(
            pointer: pointer,
            kind: ui.PointerDeviceKind.mouse,
            device: 1,
            position: downPosition + const Offset(48, -6),
            delta: const Offset(18, 6),
            buttons: kPrimaryButton | kSecondaryButton,
          ),
        );
        await tester.pump();
        await gesture.moveBy(const Offset(9, 4));
        await tester.pump();
        await gesture.up();
        await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
        await tester.pump();

        final cancelled = container.read(editorNotifierProvider);
        expect(cancelled.panOffset, const Offset(40, 8));
        expect(cancelled.activeMap!.toJson(), beforeJson);
        expect(cancelled.mapUndoStack, const <MapHistorySnapshot>[historical]);
        expect(cancelled.mapRedoStack, isEmpty);
        expect(cancelled.mapStrokeStart, isNull);
        expect(cancelled.canUndoMap, isTrue);
        expect(cancelled.isDirty, isFalse);
      },
    );

    testWidgets('Escape rolls an active paint gesture back exactly',
        (tester) async {
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'collision',
        activeTool: EditorToolType.collisionPaint,
        savedMapSnapshot: _activeMap,
      );
      final beforeJson = _activeMap.toJson();

      await _pumpCanvas(tester, container);
      final canvas = tester.getRect(find.byType(MapCanvas));
      final gesture = await tester.startGesture(
        canvas.topLeft + const Offset(16, 16),
        kind: ui.PointerDeviceKind.mouse,
      );
      await tester.pump();
      await gesture.moveBy(const Offset(34, 0));
      await tester.pump();
      expect(
        container.read(editorNotifierProvider).mapStrokeStart,
        isNotNull,
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      final cancelled = container.read(editorNotifierProvider);
      expect(cancelled.activeMap!.toJson(), beforeJson);
      expect(cancelled.mapStrokeStart, isNull);
      expect(cancelled.mapUndoStack, isEmpty);
      expect(cancelled.mapRedoStack, isEmpty);
      expect(cancelled.isDirty, isFalse);
    });

    testWidgets(
      'a child control cannot strand canvas ownership after pointer up',
      (tester) async {
        final container = _createContainer();
        container.read(editorNotifierProvider.notifier).state =
            const EditorState(
          project: _project,
          activeMap: _activeMap,
          activeLayerId: 'collision',
          activeTool: EditorToolType.collisionPaint,
          savedMapSnapshot: _activeMap,
        );

        await _pumpCanvas(tester, container);
        await tester.tap(
          find.byKey(
            const ValueKey<String>('shadow-light-preview-evening-button'),
          ),
        );
        await tester.pump();
        final canvasCenter = tester.getCenter(find.byType(MapCanvas));
        tester.binding.handlePointerEvent(
          PointerScrollEvent(
            position: canvasCenter,
            kind: ui.PointerDeviceKind.mouse,
            scrollDelta: const Offset(12, -8),
          ),
        );
        await tester.pump();

        final state = container.read(editorNotifierProvider);
        expect(state.panOffset, const Offset(-12, 8));
        expect(state.activeMap, _activeMap);
        expect(state.mapUndoStack, isEmpty);
        expect(state.isDirty, isFalse);
      },
    );

    testWidgets('changing tool mid-drag rolls the original transaction back',
        (tester) async {
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'collision',
        activeTool: EditorToolType.collisionPaint,
        savedMapSnapshot: _activeMap,
      );
      final beforeJson = _activeMap.toJson();

      await _pumpCanvas(tester, container);
      final canvas = tester.getRect(find.byType(MapCanvas));
      final gesture = await tester.startGesture(
        canvas.topLeft + const Offset(16, 16),
        kind: ui.PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(34, 0));
      await tester.pump();
      expect(
        container.read(editorNotifierProvider).mapStrokeStart,
        isNotNull,
      );

      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = notifier.state.copyWith(
        activeTool: EditorToolType.selection,
      );
      await tester.pump();
      await gesture.moveBy(const Offset(34, 0));
      await tester.pump();

      final rolledBack = container.read(editorNotifierProvider);
      expect(rolledBack.activeTool, EditorToolType.selection);
      expect(rolledBack.activeMap!.toJson(), beforeJson);
      expect(rolledBack.mapStrokeStart, isNull);
      expect(rolledBack.mapUndoStack, isEmpty);
      expect(rolledBack.isDirty, isFalse);

      await gesture.up();
      await tester.pump();
    });

    testWidgets(
        'changing eraser footprint mid-drag rolls the original transaction back',
        (tester) async {
      const filledMap = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 4, height: 2),
        layers: <MapLayer>[
          CollisionLayer(
            id: 'collision',
            name: 'Collision',
            collisions: <bool>[
              true,
              true,
              true,
              true,
              true,
              true,
              true,
              true,
            ],
          ),
        ],
      );
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        activeMap: filledMap,
        activeLayerId: 'collision',
        activeTool: EditorToolType.eraser,
        savedMapSnapshot: filledMap,
      );
      final beforeJson = filledMap.toJson();

      await _pumpCanvas(tester, container);
      final canvas = tester.getRect(find.byType(MapCanvas));
      final gesture = await tester.startGesture(
        canvas.topLeft + const Offset(16, 16),
        kind: ui.PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(34, 0));
      await tester.pump();
      expect(
        container.read(editorNotifierProvider).mapStrokeStart,
        isNotNull,
      );

      final notifier = container.read(editorNotifierProvider.notifier);
      expect(
        notifier.setCustomEraserFootprint(width: 2, height: 1),
        isTrue,
      );
      await tester.pump();
      await gesture.moveBy(const Offset(34, 0));
      await tester.pump();

      final rolledBack = container.read(editorNotifierProvider);
      expect(
        rolledBack.eraserFootprint,
        const EditorEraserFootprint.custom(
          size: GridSize(width: 2, height: 1),
        ),
      );
      expect(rolledBack.activeMap!.toJson(), beforeJson);
      expect(rolledBack.mapStrokeStart, isNull);
      expect(rolledBack.mapUndoStack, isEmpty);
      expect(rolledBack.isDirty, isFalse);

      await gesture.up();
      await tester.pump();
    });

    testWidgets('unmounting the canvas rolls an active stroke back',
        (tester) async {
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'collision',
        activeTool: EditorToolType.collisionPaint,
        savedMapSnapshot: _activeMap,
      );
      final beforeJson = _activeMap.toJson();

      await _pumpCanvas(tester, container);
      final canvas = tester.getRect(find.byType(MapCanvas));
      final gesture = await tester.startGesture(
        canvas.topLeft + const Offset(16, 16),
        kind: ui.PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(34, 0));
      await tester.pump();
      expect(
        container.read(editorNotifierProvider).mapStrokeStart,
        isNotNull,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SizedBox.shrink(),
        ),
      );
      await tester.pump();

      final rolledBack = container.read(editorNotifierProvider);
      expect(rolledBack.activeMap!.toJson(), beforeJson);
      expect(rolledBack.mapStrokeStart, isNull);
      expect(rolledBack.mapUndoStack, isEmpty);
      expect(rolledBack.isDirty, isFalse);

      await gesture.cancel();
    });

    testWidgets(
      'a cancelled physical pointer quarantines later pointers until release',
      (tester) async {
        final container = _createContainer();
        container.read(editorNotifierProvider.notifier).state =
            const EditorState(
          project: _project,
          activeMap: _activeMap,
          activeLayerId: 'collision',
          activeTool: EditorToolType.collisionPaint,
          savedMapSnapshot: _activeMap,
        );
        final beforeJson = _activeMap.toJson();

        await _pumpCanvas(tester, container);
        final canvas = tester.getRect(find.byType(MapCanvas));
        final first = await tester.startGesture(
          canvas.topLeft + const Offset(16, 16),
          pointer: 1,
          kind: ui.PointerDeviceKind.mouse,
        );
        await first.moveBy(const Offset(34, 0));
        await tester.pump();
        expect(
          container.read(editorNotifierProvider).mapStrokeStart,
          isNotNull,
        );

        await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        expect(
          container.read(editorNotifierProvider).activeMap!.toJson(),
          beforeJson,
        );

        final second = await tester.startGesture(
          canvas.topLeft + const Offset(16, 48),
          pointer: 2,
          kind: ui.PointerDeviceKind.mouse,
        );
        await second.moveBy(const Offset(34, 0));
        await tester.pump();
        expect(
          container.read(editorNotifierProvider).activeMap!.toJson(),
          beforeJson,
        );
        expect(
          container.read(editorNotifierProvider).mapStrokeStart,
          isNull,
        );

        await first.up();
        await tester.pump();
        await second.up();
        await tester.pump();

        final third = await tester.startGesture(
          canvas.topLeft + const Offset(16, 16),
          pointer: 3,
          kind: ui.PointerDeviceKind.mouse,
        );
        await third.moveBy(const Offset(34, 0));
        await tester.pump();
        await third.up();
        await tester.pump();

        final committed = container.read(editorNotifierProvider);
        expect(committed.activeMap, isNot(_activeMap));
        expect(committed.mapUndoStack, hasLength(1));
      },
    );

    testWidgets(
      'a second physical pointer rolls the owned transaction back',
      (tester) async {
        final container = _createContainer();
        container.read(editorNotifierProvider.notifier).state =
            const EditorState(
          project: _project,
          activeMap: _activeMap,
          activeLayerId: 'collision',
          activeTool: EditorToolType.collisionPaint,
          savedMapSnapshot: _activeMap,
        );
        final beforeJson = _activeMap.toJson();

        await _pumpCanvas(tester, container);
        final canvas = tester.getRect(find.byType(MapCanvas));
        final first = await tester.startGesture(
          canvas.topLeft + const Offset(16, 16),
          pointer: 11,
          kind: ui.PointerDeviceKind.touch,
        );
        await first.moveBy(const Offset(34, 0));
        await tester.pump();
        expect(
          container.read(editorNotifierProvider).mapStrokeStart,
          isNotNull,
        );

        final second = await tester.startGesture(
          canvas.topLeft + const Offset(16, 48),
          pointer: 12,
          kind: ui.PointerDeviceKind.touch,
        );
        await second.moveBy(const Offset(68, 0));
        await tester.pump();

        final rolledBack = container.read(editorNotifierProvider);
        expect(rolledBack.activeMap!.toJson(), beforeJson);
        expect(rolledBack.mapStrokeStart, isNull);
        expect(rolledBack.mapUndoStack, isEmpty);
        expect(rolledBack.isDirty, isFalse);

        await first.up();
        await second.up();
        await tester.pump();
      },
    );
  });
}

ProviderContainer _createContainer() {
  final container = ProviderContainer();
  final subscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() {
    subscription.close();
    container.dispose();
  });
  return container;
}

Future<void> _pumpCanvas(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.binding.setSurfaceSize(const Size(900, 700));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MacosTheme(
        data: MacosThemeData.light(),
        child: const MaterialApp(
          home: CupertinoPageScaffold(
            child: SizedBox.expand(child: MapCanvas()),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

const _project = ProjectManifest(
  name: 'interaction_arbitration_project',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
  surfaceCatalog: ProjectSurfaceCatalog.empty(),
);

const _activeMap = MapData(
  id: 'map',
  name: 'Map',
  size: GridSize(width: 4, height: 2),
  layers: <MapLayer>[
    CollisionLayer(
      id: 'collision',
      name: 'Collision',
      collisions: <bool>[
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
      ],
    ),
  ],
);

const _historicalUndoMap = MapData(
  id: 'undo_map',
  name: 'Undo checkpoint',
  size: GridSize(width: 1, height: 1),
  layers: <MapLayer>[
    CollisionLayer(
      id: 'collision',
      name: 'Collision',
      collisions: <bool>[false],
    ),
  ],
);

const _historicalRedoMap = MapData(
  id: 'redo_map',
  name: 'Redo checkpoint',
  size: GridSize(width: 1, height: 1),
  layers: <MapLayer>[
    CollisionLayer(
      id: 'collision',
      name: 'Collision',
      collisions: <bool>[true],
    ),
  ],
);
`````

### 15.12 `packages/map_editor/test/ui/design_system/pokemap_eraser_footprint_dialog_test.dart`

`````dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/pokemap_button.dart';
import 'package:map_editor/src/ui/design_system/pokemap_eraser_footprint_dialog.dart';

void main() {
  testWidgets('exposes the three modes and returns the previous brush size',
      (tester) async {
    PokeMapEraserFootprintResult? result;
    await _pumpLauncher(
      tester,
      onLaunch: (context) async {
        result = await showPokeMapEraserFootprintDialog(
          context,
          initialValue: const PokeMapEraserFootprintResult.singleTile(),
          previousBrushSize: (width: 3, height: 2),
          maxDimension: 8,
        );
      },
    );

    await tester.tap(find.text('Configurer la gomme'));
    await tester.pumpAndSettle();

    expect(find.byKey(pokeMapEraserFootprintDialogKey), findsOneWidget);
    expect(find.text('Une case'), findsOneWidget);
    expect(find.text('Pinceau précédent'), findsOneWidget);
    expect(find.text('Personnalisée'), findsOneWidget);
    expect(find.text('3 × 2 cases'), findsOneWidget);

    await tester.tap(find.byKey(pokeMapEraserPreviousBrushChoiceKey));
    await tester.pump();
    await tester.tap(find.byKey(pokeMapEraserFootprintApplyButtonKey));
    await tester.pumpAndSettle();

    expect(
      result,
      const PokeMapEraserFootprintResult.previousBrush(
        width: 3,
        height: 2,
      ),
    );
  });

  testWidgets('keeps the previous brush choice disabled when unavailable',
      (tester) async {
    await _pumpLauncher(
      tester,
      onLaunch: (context) => showPokeMapEraserFootprintDialog(
        context,
        initialValue: const PokeMapEraserFootprintResult.singleTile(),
        maxDimension: 8,
      ),
    );

    await tester.tap(find.text('Configurer la gomme'));
    await tester.pumpAndSettle();

    final previousButton = tester.widget<PokeMapButton>(
      find.byKey(pokeMapEraserPreviousBrushChoiceKey),
    );
    expect(previousButton.onPressed, isNull);
    expect(find.text('Aucun pinceau à reprendre'), findsOneWidget);
  });

  testWidgets('validates custom dimensions and submits valid values with Enter',
      (tester) async {
    PokeMapEraserFootprintResult? result;
    await _pumpLauncher(
      tester,
      onLaunch: (context) async {
        result = await showPokeMapEraserFootprintDialog(
          context,
          initialValue: const PokeMapEraserFootprintResult.singleTile(),
          previousBrushSize: (width: 2, height: 2),
          maxDimension: 8,
        );
      },
    );

    await tester.tap(find.text('Configurer la gomme'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(pokeMapEraserCustomChoiceKey));
    await tester.pump();

    await tester.enterText(find.byKey(pokeMapEraserWidthFieldKey), '0');
    await tester.enterText(find.byKey(pokeMapEraserHeightFieldKey), '9');
    await tester.pump();

    expect(
      find.text('Entrez un entier entre 1 et 8.'),
      findsNWidgets(2),
    );
    expect(_applyButton(tester).onPressed, isNull);

    await tester.enterText(find.byKey(pokeMapEraserWidthFieldKey), '4');
    await tester.enterText(find.byKey(pokeMapEraserHeightFieldKey), '3');
    await tester.pump();
    expect(_applyButton(tester).onPressed, isNotNull);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(
      result,
      const PokeMapEraserFootprintResult.custom(width: 4, height: 3),
    );
    expect(find.byKey(pokeMapEraserFootprintDialogKey), findsNothing);
  });

  testWidgets('cancel returns null', (tester) async {
    PokeMapEraserFootprintResult? result;
    var completed = false;
    await _pumpLauncher(
      tester,
      onLaunch: (context) async {
        result = await showPokeMapEraserFootprintDialog(
          context,
          initialValue: const PokeMapEraserFootprintResult.custom(
            width: 2,
            height: 3,
          ),
          maxDimension: 8,
        );
        completed = true;
      },
    );

    await tester.tap(find.text('Configurer la gomme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, isNull);
  });

  testWidgets('Escape returns null', (tester) async {
    PokeMapEraserFootprintResult? result;
    var completed = false;
    await _pumpLauncher(
      tester,
      onLaunch: (context) async {
        result = await showPokeMapEraserFootprintDialog(
          context,
          initialValue: const PokeMapEraserFootprintResult.singleTile(),
          maxDimension: 8,
        );
        completed = true;
      },
    );

    await tester.tap(find.text('Configurer la gomme'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, isNull);
    expect(tester.takeException(), isNull);
  });
}

PokeMapButton _applyButton(WidgetTester tester) => tester.widget<PokeMapButton>(
      find.byKey(pokeMapEraserFootprintApplyButtonKey),
    );

Future<void> _pumpLauncher(
  WidgetTester tester, {
  required Future<void> Function(BuildContext context) onLaunch,
}) async {
  tester.view.physicalSize = const Size(1000, 760);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => onLaunch(context),
            child: const Text('Configurer la gomme'),
          ),
        ),
      ),
    ),
  );
}
`````

### 15.13 `packages/map_editor/test/ui/shell/pokemap_map_navigation_responsive_test.dart`

`````dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  group('Map canvas navigation responsive shell layout', () {
    testWidgets('keeps every compact action visible and usable at 800x600',
        (tester) async {
      final container = await pumpEditorShellPage(
        tester,
        initialState: _editorState(),
        surfaceSize: const Size(800, 600),
      );

      _expectAllNavigationActionsInsideCanvas(tester);
      expect(find.byTooltip('Ajuster la carte'), findsOneWidget);
      expect(find.byTooltip('Afficher à 100 %'), findsOneWidget);
      expect(find.byTooltip('Centrer la carte'), findsOneWidget);

      await tester.tap(_navigationAction('map-navigation-zoom-out'));
      await tester.pump();

      expect(
        container.read(editorNotifierProvider).zoom,
        closeTo(1 / 1.2, 1e-6),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps every compact action visible at 1280x800',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: _editorState(),
        surfaceSize: const Size(1280, 800),
      );

      _expectAllNavigationActionsInsideCanvas(tester);
      expect(find.byTooltip('Ajuster la carte'), findsOneWidget);
      expect(find.byTooltip('Afficher à 100 %'), findsOneWidget);
      expect(find.byTooltip('Centrer la carte'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('wraps every action inside the narrow 1000x800 breakpoint',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: _editorState(),
        surfaceSize: const Size(1000, 800),
      );

      _expectAllNavigationActionsInsideCanvas(tester);
      expect(find.byTooltip('Ajuster la carte'), findsOneWidget);
      expect(find.byTooltip('Afficher à 100 %'), findsOneWidget);
      expect(find.byTooltip('Centrer la carte'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('retains labelled actions when the canvas is wide',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: _editorState(),
        surfaceSize: const Size(1800, 900),
      );

      _expectAllNavigationActionsInsideCanvas(tester);
      expect(
        find.descendant(
          of: _navigationAction('map-navigation-fit'),
          matching: find.text('Ajuster'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _navigationAction('map-navigation-actual-size'),
          matching: find.text('100 %'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _navigationAction('map-navigation-center'),
          matching: find.text('Centrer'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

Finder _navigationAction(String key) {
  return find.byKey(ValueKey<String>(key));
}

void _expectAllNavigationActionsInsideCanvas(WidgetTester tester) {
  final canvasRect = tester.getRect(find.byType(MapCanvas));
  for (final key in const <String>[
    'map-navigation-zoom-out',
    'map-navigation-zoom-in',
    'map-navigation-fit',
    'map-navigation-actual-size',
    'map-navigation-center',
  ]) {
    final actionRect = tester.getRect(_navigationAction(key));
    expect(
      actionRect.left,
      greaterThanOrEqualTo(canvasRect.left),
      reason: '$key must not be clipped on the left',
    );
    expect(
      actionRect.right,
      lessThanOrEqualTo(canvasRect.right),
      reason: '$key must not be clipped on the right',
    );
    expect(
      actionRect.top,
      greaterThanOrEqualTo(canvasRect.top),
      reason: '$key must not be clipped at the top',
    );
    expect(
      actionRect.bottom,
      lessThanOrEqualTo(canvasRect.bottom),
      reason: '$key must not be clipped at the bottom',
    );
  }
}

EditorState _editorState() {
  final map = buildShellChromeMap(
    id: 'responsive_navigation_map',
    name: 'Map',
    width: 8,
    height: 8,
    layers: const <MapLayer>[
      TileLayer(
        id: 'ground',
        name: 'Ground',
        tiles: <int>[],
      ),
    ],
  );
  return EditorState(
    projectRootPath: '/tmp/responsive_navigation_map',
    project: buildShellChromeProject(
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'responsive_navigation_map',
          name: 'Map',
          relativePath: 'maps/responsive_navigation_map.json',
        ),
      ],
    ),
    workspaceMode: EditorWorkspaceMode.map,
    activeMap: map,
    activeLayerId: 'ground',
    savedMapSnapshot: map,
  );
}
`````
