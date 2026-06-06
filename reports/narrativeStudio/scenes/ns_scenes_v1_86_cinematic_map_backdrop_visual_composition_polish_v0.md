# NS-SCENES-V1-86 — Cinematic Map Backdrop Visual Composition Polish V0

## 1. Verdict

Statut : `DONE`.

Phrase canonique : V1-86 rend le décor beaucoup plus lisible. V1-86 ne rend toujours pas la cinématique jouable.

Karim a explicitement demandé ce lot de polish avant de continuer vers l'Actor Display. La roadmap précédente proposait `NS-SCENES-V1-86 — Cinematic Actor Display Preview Prep Contract`; cette recommandation est volontairement repoussée en `NS-SCENES-V1-87`.

## 2. Objectif

Le but était de corriger la composition visuelle du backdrop map dans le Cinematic Builder après V1-85 :

- donner plus d'importance à la surface de carte ;
- éviter l'effet timbre-poste ;
- garder une carte proportionnelle ;
- rendre primitives, grille, chemin et ancres plus lisibles ;
- rendre la légende compacte et secondaire ;
- préserver timeline, pickers, inspector et transports disabled ;
- ne pas ouvrir les sujets actors/runtime/playback/tiles finales.

## 3. Gate 0

Répertoire : `/Users/karim/Project/pokemonProject`.

État initial V1-86 vérifié propre après auto-commit V1-85 :

```text
git status --short --untracked-files=all
<aucune sortie>
```

Dernier commit observé :

```text
c730bef3 feat(narrative): auto-commit changes
```

## 4. Fichiers lus

- `AGENTS.md`
- `skills/README.md`
- `skills/brainstorming/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/dispatching-parallel-agents/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- fichiers editor/core liés au Builder, au backdrop panel, au painter et aux tests.

## 5. Sub-agents

Les cinq passes spécialisées demandées ont été exécutées avec sub-agents réels.

Sub-agent A — UX/Layout : la carte paraissait trop petite parce que le chrome, les badges et la timeline consommaient la hauteur utile ; recommandation : viewport au moins 220 px côté court, badges/legend hors surface map, timeline préservée.

Sub-agent B — Density/Scaling : le fit proportionnel était sain, mais l'ancien inset fixe et la grille trop dense rendaient les cellules invisibles à faible échelle ; recommandation : inset adaptatif, grille masquée sous seuil, primitives renforcées.

Sub-agent C — Renderer/Design System : garder un mini `CustomPainter` editor-only, renforcer cadre/grille/chemins/ancres, et alimenter toutes les couleurs depuis les tokens/design system.

Sub-agent D — Tests/Anti-scope : ajouter une key de viewport réellement sur la map fitée, tester taille/ratio/légende, conserver transports disabled, ajouter Visual Gate V1-86, scanner runtime/actors/playback/couleurs hardcodées.

Sub-agent E — Product : divergence utile mais rejetée pour ce lot ; il voulait revenir à Actor Display selon l'ancienne roadmap. Arbitrage : Karim et le prompt V1-86 priment, Actor Display passe en V1-87.

## 6. Arbitrage

Décision retenue : ne pas toucher au read model core V1-85. Le problème V1-86 était principalement une composition UI/painter :

- adapter la hauteur preview/timeline seulement quand un backdrop est présent ;
- retirer les badges redondants sous la map ;
- mettre meta et légende dans un rail secondaire ;
- rendre la vraie surface map testable via une key dédiée ;
- améliorer le painter sans fake tiles ni runtime.

## 7. Design Gate — 25 réponses

1. La carte doit-elle devenir la priorité de la preview ? Oui.
2. La timeline doit-elle rester utilisable ? Oui, hauteur minimale conservée.
3. Peut-on lancer le runtime ? Non.
4. Peut-on utiliser Flame ou `PlayableMapGame` ? Non.
5. Peut-on rendre les vraies tiles/assets ? Non.
6. Peut-on rendre des acteurs ? Non.
7. Peut-on utiliser une image IA ? Non.
8. Peut-on inventer une fake map ? Non.
9. La carte doit-elle garder ses proportions ? Oui.
10. Le viewport doit-il être mesurable en test ? Oui, key dédiée.
11. Taille minimale retenue ? `shortestSide >= 220`.
12. La légende doit-elle rester dans la surface map ? Non, secondaire.
13. Les badges doivent-ils dominer la carte ? Non.
14. La grille doit-elle toujours s'afficher ? Non, seuil selon taille cellule.
15. Les chemins doivent-ils être plus lisibles ? Oui, ruban central.
16. Les ancres doivent-elles être plus visibles ? Oui, halo + core.
17. Les diagnostics doivent-ils pouvoir overflow ? Non, pills ellipsées.
18. Les couleurs peuvent-elles être hardcodées ? Non, tokens/design system.
19. Les pickers map-aware doivent-ils rester stables ? Oui.
20. Le Character Library picker doit-il rester stable ? Oui.
21. Les transports doivent-ils rester disabled ? Oui.
22. Le probe/timeline doivent-ils muter ? Non.
23. Le screenshot doit-il rester 1663 x 926 ? Oui.
24. Les roadmaps doivent-elles changer ? Oui, V1-86 DONE et Actor Display en V1-87.
25. V1-86 est-il une preview jouable ? Non.

## 8. Implémentation

### Layout Builder

`cinematic_builder_workspace.dart` adapte maintenant le calcul preview/timeline selon la présence du backdrop :

```dart
final timelineHeight = _builderTimelineHeight(
  constraints.maxHeight,
  hasBackdrop: widget.backdropPreviewModel != null,
);
```

Le mode backdrop utilise :

```dart
const _builderBackdropPreviewMinHeight = 400.0;
const _builderBackdropPreviewMaxHeight = 450.0;
const _builderBackdropTimelineMinHeight = 420.0;
const _builderBackdropTimelineMaxHeight = 620.0;
const _builderBackdropTimelinePreferredShare = 0.52;
```

### Preview Panel

`cinematic_map_backdrop_preview_panel.dart` affiche la map sur une surface plus utile, avec rail secondaire non compact :

```dart
return Row(
  key: const ValueKey('cinematic-builder-map-backdrop-visual-primitives'),
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    Expanded(child: _BackdropPrimitiveCanvas(...)),
    const SizedBox(width: 8),
    SizedBox(width: 330, child: Column(...)),
  ],
);
```

Le vrai viewport fit map est mesurable :

```dart
final scale = math.min(
  constraints.maxWidth / mapWidth,
  constraints.maxHeight / mapHeight,
);
final viewportWidth = mapWidth * scale;
final viewportHeight = mapHeight * scale;
```

### Painter

`cinematic_map_backdrop_visual_primitives_painter.dart` renforce :

- frame `strokeWidth = 1.4`;
- grille adaptative seulement si `cellSize >= 7`;
- major grid toutes les 5 cellules ;
- inset cellulaire adaptatif ;
- path en ruban ;
- anchors halo + core ;
- opacités par type de primitive.

## 9. Tests ajoutés / renforcés

Test principal renforcé :

```text
renders static map backdrop preview when backdrop model is available
```

Assertions clés :

- key `cinematic-builder-map-backdrop-visual-viewport`;
- `mapViewportSize.shortestSide >= 220`;
- ratio proche de `12 / 10`;
- légende secondaire ;
- absence `Collision`, `Couche collision`, `Professor Oak`.

Visual Gate ajoutée :

```text
captures V1-86 cinematic map backdrop visual composition when requested
```

Elle génère :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_86_cinematic_map_backdrop_visual_composition_polish_v0.png
```

## 10. Capture

Capture vérifiée :

```text
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
246K
SHA-256 0656ae62d62379dc9e8d9db154e3290c25d66f9dc6cd6b2e71c4547ac5e7661d
```

Inspection visuelle via `view_image` : la preview affiche une surface map structurelle plus large, la légende est secondaire, la timeline reste présente.

## 11. Commandes

RED :

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders static map backdrop preview when backdrop model is available'
Exit 1 — key viewport manquante puis viewport trop petit pendant l'itération.
```

GREEN ciblé :

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders static map backdrop preview when backdrop model is available'
+1 All tests passed!
```

Visual Gate :

```text
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_86_CAPTURE_CINEMATIC_MAP_BACKDROP_VISUAL_COMPOSITION=true --reporter=compact test/cinematic_builder_workspace_test.dart
+151 All tests passed!
```

Tests ciblés :

```text
cd packages/map_core && dart test --reporter=compact test/cinematic_map_backdrop_preview_model_test.dart
+19 All tests passed!

cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
+151 All tests passed!

cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
+15 All tests passed!
```

Analyse ciblée :

```text
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_visual_primitives_painter.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
No issues found! (ran in 1.3s)
```

Vérification large tentée :

```text
cd packages/map_editor && flutter test --reporter=compact
+2191 -18 Some tests failed.
```

Échecs visibles hors V1-86 : golden V1-29 `ns_scenes_v1_29_storyline_step_scene_link_v0.png` avec diff 0.61% / 7671 px, et erreurs Pokemon SDK converter.

Analyse globale tentée :

```text
cd packages/map_editor && flutter analyze
344 issues found.
```

Ca reste hors lot, majoritairement sur `lib/src/application/services/pokemon_sdk_move_catalog_converter.dart` et `sync_pokemon_sdk_moves_catalog_use_case.dart`.

## 12. Scans anti-scope

Diff V1-86 : aucune modification dans `packages/map_runtime`, `packages/map_gameplay`, `packages/map_battle`, `examples`, `selbrume`.

Le scan du diff ajouté ne trouve aucun ajout :

- runtime/Flame/`PlayableMapGame`;
- playback/timer/seek/scrub actif ;
- actor renderer/sprite actor ;
- fake map/fake tile/Selbrume ;
- couleurs hardcodées ajoutées ;
- image IA ou modèle image.

Hits non bloquants :

- `seek` / `scrub` apparaissent dans des assertions anti-scope existantes ;
- `CharacterAnimation` apparaît dans des fixtures/tests existants ;
- `Color(0x33000000)` / `Colors.transparent` existent déjà dans `cinematic_builder_workspace.dart`, mais le diff V1-86 n'en ajoute aucun.

## 13. Fichiers modifiés

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_visual_primitives_painter.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_86_cinematic_map_backdrop_visual_composition_polish_v0.png`
- `reports/narrativeStudio/scenes/ns_scenes_v1_86_cinematic_map_backdrop_visual_composition_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_86_evidence_pack.md`

## 14. Non-objectifs confirmés

V1-86 ne rend pas les vraies tiles/assets finales.

V1-86 ne rend aucun acteur.

V1-86 n'ajoute aucun runtime, Flame, playback, pathfinding, collision, trigger overlay, event overlay, entity overlay, mutation map/projet, donnée Selbrume ou image IA.

## 15. Limites

La preview reste une projection structurelle issue des primitives V1-85, pas une preview runtime. Les icônes/glyphes de certains boutons dans le screenshot de test peuvent rester liés au harness existant ; ce lot n'a pas touché au système d'icônes global.

## 16. Roadmap

Roadmaps mises à jour :

- V1-86 ajouté en `DONE`;
- prochain lot exact : `NS-SCENES-V1-87 — Cinematic Actor Display Preview Prep Contract`;
- note explicite : ce changement de séquence vient de la demande de Karim.

## 17. Evidence Pack

Voir :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_86_evidence_pack.md
```

