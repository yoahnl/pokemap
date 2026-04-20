# Lot 4d — Battle Scene Responsive Staging / Pokémon-like Visual Lock

## 1. Résumé exécutif honnête

Le lot 4d est réussi au sens de son objectif technique :

- la battle scene consomme maintenant un layout pur et testable ;
- le staging des battlers ne dépend plus d'offsets répartis entre l'overlay et le composant combatant ;
- la taille perçue des sprites est bornée sur les viewports wide ;
- le panneau de commandes garde son mode `split` ou `stacked` selon un contrat explicite ;
- aucun code battle-core, IA, difficulté, Bag, inventaire, authoring ou background resolver métier n'a été rouvert.

Point d'honnêteté important :

- ce lot verrouille le contrat de layout ;
- il améliore fortement la stabilité visuelle ;
- il ne prouve pas à lui seul un rendu pixel-perfect face à la référence Pokémon-like ;
- il faut donc le lire comme un verrouillage de géométrie responsive, pas comme une promesse de parité visuelle absolue.

## 2. État git initial

Pré-gates réellement exécutés au début du lot :

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
```

Résultat observé :

- aucune sortie sur les trois commandes ;
- le worktree était propre au démarrage ;
- aucune suppression, aucun reset, aucun discard n'ont été faits.

## 3. Fichiers lus

- `reports/lot-4c-battle-ui-sprites-zone-backgrounds-corrective-report.md`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_scene_combatant_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_scene_hud_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_scene_backdrop_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_pokemon_sprite_resolver.dart`
- `packages/map_runtime/test/battle_overlay_component_test.dart`
- `packages/map_runtime/test/battle_command_menu_component_test.dart`
- `packages/map_runtime/test/battle_pokemon_sprite_resolver_test.dart`
- la capture de référence `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/TemporaryItems/NSIRD_screencaptureui_IFAbk9/Screenshot 2026-04-20 at 11.33.25.png`
- le GIF local `/Users/karim/Desktop/OPEyTO4.gif`

Note honnête sur le GIF :

- le GIF local était bien accessible ;
- son contenu réel n'était pas strictement identique à l'image Pokémon canonique montrée dans les messages précédents ;
- le lot 4d s'est donc aligné sur la structure produit explicitement demandée : ennemi haut/droite, joueur bas/gauche, HUD ennemi haut/gauche, HUD joueur bas/droite, command panel bas.

## 4. Fichiers modifiés

- `packages/map_runtime/lib/src/presentation/flame/battle_scene_layout.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_scene_combatant_component.dart`
- `packages/map_runtime/test/battle_scene_layout_test.dart`
- `packages/map_runtime/test/battle_overlay_component_test.dart`
- `packages/map_runtime/test/battle_command_menu_component_test.dart`
- `packages/map_runtime/test/battle_pokemon_sprite_resolver_test.dart`
- `reports/lot-4d-battle-scene-responsive-staging-report.md`

## 5. Diagnostic du problème visuel 4c

Le lot 4c était fonctionnellement OK :

- menus réels ;
- sprites front/back réels ;
- backgrounds trainer/zone/contextuels réels ;
- fallbacks images robustes.

Mais le staging visuel n'était pas clos pour quatre raisons :

1. la géométrie de scène était encore calculée dans l'overlay lui-même ;
2. le composant battler recréait une partie de sa propre géométrie locale ;
3. le scale dépendait trop directement du viewport disponible ;
4. les tests vérifiaient surtout quelques bornes globales, pas les relations de composition qui comptent vraiment.

Viewports qui donnaient une mauvaise perception avant ce lot :

- mobile portrait : empilement lisible, mais battlers trop soumis au viewport ;
- laptop / wide desktop : dispersion trop forte ou croissance perceptuelle non assez bornée ;
- petit paysage : risque de compromis implicite entre stage et command panel.

Diagnostic retenu :

- le vrai problème venait principalement de la relation `stage / command panel / anchors / rects de sprite`, pas du resolver sprite ni du menu lui-même ;
- il fallait sortir un contrat de layout pur au lieu d'ajouter encore quelques magic numbers dans Flame.

## 6. Stratégie de layout retenue

Stratégie retenue :

1. créer un layout pur `BattleSceneLayout` ;
2. y centraliser :
   - `sceneRect`
   - `stageRect`
   - `commandPanelRect`
   - `enemyHudRect`
   - `playerHudRect`
   - `enemySpriteRect`
   - `playerSpriteRect`
   - `enemyPlatformRect`
   - `playerPlatformRect`
   - `enemyFootAnchor`
   - `playerFootAnchor`
   - `commandPanelLayoutMode`
3. faire consommer ces rects explicitement par l'overlay ;
4. faire consommer des rects de sprite et de plateforme explicites par `BattleSceneCombatantComponent` ;
5. garder un scale plafonné à `1.0` pour éviter que les battlers gonflent en wide desktop.

Référence géométrique retenue :

- stage de référence : `960x330`
- panneau de commandes calculé séparément, puis stage fit au-dessus
- command panel :
  - `split` quand le paysage le permet
  - `stacked` en portrait ou très étroit
- joueur plus grand que l'ennemi
- joueur plus bas que l'ennemi
- ennemi plus à droite que le joueur
- plateforme joueur large et basse
- plateforme ennemi plus petite et plus haute

## 7. Contrat pur introduit

Nouveau fichier :

- [packages/map_runtime/lib/src/presentation/flame/battle_scene_layout.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_scene_layout.dart)

Ce que ce contrat calcule réellement :

- un `sceneRect` dans le viewport ;
- un `commandPanelRect` séparé et borné ;
- un `stageRect` bottom-aligned au-dessus du command panel ;
- les rects HUD, sprites et plateformes ;
- les foot anchors ;
- le mode `split` / `stacked`.

Décision importante :

- le scale du stage est plafonné à `1.0` ;
- sur desktop wide, on garde une perception stable au lieu de grossir les battlers indéfiniment ;
- sur mobile/petit paysage, le stage réduit proprement.

## 8. Table des viewports testés

| Viewport | Mode panneau | Vérifié |
| --- | --- | --- |
| `390x844` | `stacked` | oui |
| `640x360` | `split` | oui |
| `844x390` | `split` | oui |
| `960x540` | `split` | oui |
| `1280x720` | `split` | oui |
| `1600x900` | `split` | oui |
| `1024x768` | `split` | oui |

## 9. Manual visual checkpoints

Je n'ai pas produit de nouvelles captures locales pendant ce lot 4d.

Les checkpoints ci-dessous viennent du layout pur réellement calculé.

### `390x844`

- mode command panel : `stacked`
- player sprite rect : `(-13.3, 412.0, 178.8, 107.2)`
- enemy sprite rect : `(236.8, 409.5, 104.8, 73.9)`
- player HUD rect : `(260.0, 491.6, 116.2, 34.1)`
- enemy HUD rect : `(7.3, 404.7, 106.4, 34.1)`
- command panel rect : `(12.0, 545.0, 366.0, 287.0)`
- notes visuelles honnêtes :
  - portrait passe bien en stacked ;
  - le joueur reste lisible et plus grand que l'ennemi ;
  - léger crop gauche volontaire du joueur ;
  - HUDs compactés pour ne pas pousser les battlers hors scène.

### `844x390`

- mode command panel : `split`
- player sprite rect : `(105.0, 27.8, 272.0, 163.2)`
- enemy sprite rect : `(485.7, 24.1, 159.5, 112.5)`
- player HUD rect : `(520.9, 148.9, 176.8, 51.9)`
- enemy HUD rect : `(136.4, 16.7, 162.0, 51.9)`
- command panel rect : `(16.0, 224.0, 812.0, 152.0)`
- notes visuelles honnêtes :
  - petit paysage reste en split ;
  - battlers gardent une hiérarchie claire ;
  - aucun recouvrement HUD / command panel / battlers d'après le contrat.

### `960x540`

- mode command panel : `split`
- player sprite rect : `(-32.8, 56.7, 440.0, 264.0)`
- enemy sprite rect : `(583.0, 50.7, 258.0, 182.0)`
- player HUD rect : `(640.0, 252.7, 286.0, 84.0)`
- enemy HUD rect : `(18.0, 38.7, 262.0, 84.0)`
- command panel rect : `(16.0, 366.7, 928.0, 159.3)`
- notes visuelles honnêtes :
  - c'est la scène de référence du contrat ;
  - le joueur est grand, bas et légèrement crop à gauche ;
  - l'ennemi reste plus petit, plus haut et à droite.

### `1280x720`

- mode command panel : `split`
- player sprite rect : `(127.2, 214.0, 440.0, 264.0)`
- enemy sprite rect : `(743.0, 208.0, 258.0, 182.0)`
- player HUD rect : `(800.0, 410.0, 286.0, 84.0)`
- enemy HUD rect : `(178.0, 196.0, 262.0, 84.0)`
- command panel rect : `(16.0, 524.0, 1248.0, 182.0)`
- notes visuelles honnêtes :
  - tailles perçues identiques à la référence ;
  - le wide supplémentaire crée de la respiration autour, pas une inflation des sprites.

### `1600x900`

- mode command panel : `split`
- player sprite rect : `(287.2, 394.0, 440.0, 264.0)`
- enemy sprite rect : `(903.0, 388.0, 258.0, 182.0)`
- player HUD rect : `(960.0, 590.0, 286.0, 84.0)`
- enemy HUD rect : `(338.0, 376.0, 262.0, 84.0)`
- command panel rect : `(16.0, 704.0, 1568.0, 182.0)`
- notes visuelles honnêtes :
  - les battlers restent stables ;
  - le surplus de largeur n'écarte plus artificiellement la mise en scène.

## 10. Ce que les tests prouvent

### Layout pur

Nouveau fichier :

- [packages/map_runtime/test/battle_scene_layout_test.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_scene_layout_test.dart)

Ce que ces tests prouvent :

- tous les rects essentiels ont une taille positive ;
- `commandPanelRect`, `enemyHudRect`, `playerHudRect` restent dans la scène ;
- le joueur reste plus grand que l'ennemi ;
- le joueur reste plus bas que l'ennemi ;
- l'ennemi reste plus à droite que le joueur ;
- les sprites restent majoritairement dans le stage ;
- les plateformes restent centrées sur les foot anchors ;
- le mode `stacked` / `split` bascule correctement ;
- le wide desktop ne regonfle pas les battlers.

### Overlay

Fichier adapté :

- [packages/map_runtime/test/battle_overlay_component_test.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_overlay_component_test.dart)

Ce que les tests overlay prouvent :

- l'overlay consomme bien `BattleSceneLayout` ;
- les rects du layout pur sont effectivement ceux utilisés pour les battlers ;
- la stabilité wide desktop est respectée ;
- le portrait narrow reste en `stacked` ;
- `updateState(...)` ne dérive pas la géométrie.

### Combatant component

Fichier adapté :

- [packages/map_runtime/test/battle_pokemon_sprite_resolver_test.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_pokemon_sprite_resolver_test.dart)

Ce que les tests prouvent :

- le sprite garde un fit non étiré ;
- le sprite reste bottom-aligned sur le foot anchor ;
- la plateforme reste centrée sur le même foot anchor ;
- le fallback silhouette garde le même contrat de rects.

## 11. Ce que les tests ne prouvent pas

Les tests ne prouvent pas :

- une validation artistique pixel-perfect face au GIF ou à une capture de référence ;
- une perception exacte du “bon goût” visuel sur tous les appareils ;
- la qualité de textures, palettes ou décors ;
- la perfection des marges fines entre sprite et HUD dans tous les cas d'espèces.

Autrement dit :

- le lot 4d verrouille la géométrie responsive ;
- il ne prétend pas fermer définitivement la direction artistique battle.

## 12. Validations exécutées

Analyse ciblée runtime :

```bash
cd packages/map_runtime
flutter analyze --no-pub \
  lib/src/presentation/flame/battle_scene_layout.dart \
  lib/src/presentation/flame/battle_overlay_component.dart \
  lib/src/presentation/flame/battle_command_panel_component.dart \
  lib/src/presentation/flame/battle_scene_combatant_component.dart \
  lib/src/presentation/flame/battle_scene_hud_component.dart \
  test/battle_scene_layout_test.dart \
  test/battle_overlay_component_test.dart \
  test/battle_command_menu_component_test.dart \
  test/battle_pokemon_sprite_resolver_test.dart
```

Résultat :

- `No issues found!`

Tests runtime :

```bash
cd packages/map_runtime
flutter test \
  test/battle_scene_layout_test.dart \
  test/battle_overlay_component_test.dart \
  test/battle_command_menu_component_test.dart \
  test/battle_pokemon_sprite_resolver_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart \
  test/wild_battle_end_to_end_flow_test.dart
```

Résultat :

- vert

Smoke host :

```bash
cd examples/playable_runtime_host
flutter test test/phase_a_golden_slice_launch_test.dart
```

Résultat :

- vert

## 13. État git final

`git status --short --untracked-files=all` au moment du report :

```text
 M packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_scene_combatant_component.dart
 M packages/map_runtime/test/battle_command_menu_component_test.dart
 M packages/map_runtime/test/battle_overlay_component_test.dart
 M packages/map_runtime/test/battle_pokemon_sprite_resolver_test.dart
?? packages/map_runtime/lib/src/presentation/flame/battle_scene_layout.dart
?? packages/map_runtime/test/battle_scene_layout_test.dart
?? reports/lot-4d-battle-scene-responsive-staging-report.md
```

## 14. Risques restants

- le crop gauche du joueur est intentionnel et stable, mais peut encore demander un ajustement artistique fin ;
- le lot n'introduit pas de captures visuelles automatisées, donc la validation finale d'apparence reste humaine ;
- le GIF local accessible n'étant pas une copie exacte de la capture Pokémon classique, il faut éviter de sur-promettre une “parité GIF” littérale.

## 15. Décision finale honnête

Décision nette :

- le lot 4d est réussi sur son objectif de layout ;
- la scène battle est maintenant adossée à un contrat pur, testable et responsive ;
- les battlers ne dérivent plus librement avec la largeur d'écran ;
- le panneau bas reste responsive et cohérent avec le reste de la scène ;
- aucun code battle-core ou gameplay n'a été rouvert.

Conclusion honnête :

- ce lot ferme le problème d'architecture/layout ;
- il réduit fortement la dérive visuelle inter-viewports ;
- il ne faut toutefois pas prétendre que le rendu est validé pixel-perfect sans un dernier jugement visuel produit. 
