# Lot 4e — Battle UI Visual Lock Report

## Executive Summary

Le lot 4e ferme proprement la partie la plus fragile du lot 4d :

- les rects de scène restent pilotés par un layout pur déjà introduit au lot 4d ;
- le back sprite joueur est abaissé et borné pour ne plus recroiser le HUD ennemi ;
- le sprite ennemi garde un vrai gap avec le HUD ennemi ;
- les HUDs ont maintenant un layout interne mesuré, ce qui évite les collisions entre `name`, `gender`, `Lv`, `HP`, barre HP et valeur HP ;
- le menu root `FIGHT / BAG / POKÉMON / RUN` garde sa structure Pokémon-like mais mesure explicitement ses zones texte pour éviter les débordements ;
- la prompt box ne répète plus inutilement la même question dans la body line ;
- des captures PNG ont été réellement produites pour les viewports produit demandés.

Le lot reste strictement côté `map_runtime`. Aucun fichier `map_battle` n’a été modifié.

Point honnête important :

- les captures générées dans ce repo utilisent encore des silhouettes/fallbacks visuels plutôt que de vrais sprites Pokémon détaillés, parce que le golden slice local ne contient pas de media Pokémon battle authorés dans `data/pokemon/media`.
- ces captures prouvent bien l’absence d’overlap grossier, le placement relatif, les HUDs, les panneaux et le menu ;
- elles ne prouvent pas à elles seules une validation artistique finale pixel-perfect face au GIF de référence.

## Initial Git State

Pré-gates exécutés au début du lot 4e :

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
```

Résultat réel initial :

- worktree propre ;
- aucun fichier modifié ;
- aucun fichier non tracké.

## Files Read

Fichiers relus avant modification :

- `/Users/karim/Project/pokemonProject/reports/lot-4d-battle-scene-responsive-staging-report.md`
- `/Users/karim/Project/pokemonProject/reports/lot-4c-battle-ui-sprites-zone-backgrounds-corrective-report.md`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_scene_layout.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_scene_combatant_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_scene_hud_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_pokemon_sprite_resolver.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_scene_layout_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_overlay_component_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_command_menu_component_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_pokemon_sprite_resolver_test.dart`

## Captures Inspected

Références effectivement inspectées :

- GIF local :
  - `/Users/karim/Desktop/OPEyTO4.gif`
- planche-contact extraite du GIF :
  - `/tmp/opeyto4_frames/contact_sheet.png`
- captures utilisateur accessibles :
  - `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/TemporaryItems/NSIRD_screencaptureui_ryBcv1/Screenshot 2026-04-20 at 11.17.39.png`
  - `/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/TemporaryItems/NSIRD_screencaptureui_fllMVa/Screenshot 2026-04-20 at 11.18.55.png`

Capture demandée mais non accessible localement pendant ce lot :

- `/Users/karim/Desktop/Screenshot 2026-04-20 at 11.33.25.png`

## Visual Diagnosis From Current Captures

Diagnostic visuel ayant motivé le patch :

1. le back sprite joueur était trop haut par rapport au GIF de référence ;
2. le sprite joueur pouvait recroiser visuellement la zone du HUD ennemi ;
3. les HUDs étaient trop fragiles face aux combinaisons `name + gender + level + HP value` ;
4. le layout interne des HUDs était trop “à la main”, donc des collisions internes restaient possibles ;
5. le root menu était structurellement meilleur qu’avant, mais les labels/subtitles restaient trop dépendants de la place disponible ;
6. la prompt box répétait inutilement la même question quand la narration retombait sur le prompt courant ;
7. la différence avec le GIF restait nette sur la composition perçue :
   - HUD ennemi pas assez compact / verrouillé ;
   - sprite joueur encore trop haut ou trop libre ;
   - HUD joueur pas assez strictement protégé ;
   - menu root encore plus “runtime polished” que “Pokémon-like lock”.

## Main Differences With The GIF

Le GIF de référence montre :

- un HUD ennemi très compact, haut et bien dégagé ;
- un sprite joueur très bas, massif et franchement ancré à gauche ;
- un sprite ennemi plus petit, haut/droite, séparé du HUD ennemi ;
- un HUD joueur stable à droite/bas sans recouvrir le battler ;
- une command box très lisible, en deux zones claires.

Le lot 4e ne cherche pas le pixel-perfect, mais rapproche explicitement ces relations :

- priorité stricte à l’absence d’overlap entre HUD ennemi et battlers ;
- battler joueur plus bas que dans le lot 4d ;
- menu root 2x2 plus robuste au texte ;
- prompt box moins redondante.

## Corrections Applied

### Player Sprite

- `BattleSceneLayout` a été retouché pour baisser le `playerSpriteRect` et son `playerFootAnchor` perçu ;
- une contrainte testée empêche maintenant le recouvrement avec `enemyHudRect.inflate(8)` ;
- la relation plateforme joueur / foot anchor est testée explicitement.

### Enemy Sprite

- `BattleSceneLayout` garde un `enemySpriteRect` plus petit que le joueur ;
- la relation `enemySpriteRect` / `enemyHudRect.inflate(8)` est maintenant testée explicitement ;
- le gap visuel par rapport au HUD ennemi est borné sur les viewports produit.

### Platforms

- les plateformes restent liées aux `footAnchor` calculés par le layout pur ;
- les tests verrouillent l’alignement plateforme/sprite pour joueur et ennemi.

### HUDs

Ajout d’un layout interne pur :

- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_scene_hud_layout.dart`

Ce layout mesure et borne :

- `nameRect`
- `genderRect`
- `levelRect`
- `statusRect`
- `hpLabelRect`
- `hpBarRect`
- `hpValueRect`

Conséquences :

- le niveau garde la priorité à droite ;
- le nom peut être comprimé sans pousser le niveau hors HUD ;
- la valeur numérique HP disparaît sur HUD compact avant de provoquer un overlap ;
- les textes visibles restent dans le HUD.

### Menu

Le root menu a été renforcé côté `battle_command_panel_component.dart` :

- snapshots mesurés des boutons root ;
- `titleRect` / `subtitleRect` calculés explicitement ;
- taille de police ajustée pour tenir dans le bouton ;
- subtitle masqué si la place devient insuffisante ;
- `POKÉMON` et `Unavailable` ne débordent plus dans les tests ciblés.

### Prompt Box

La narration secondaire est maintenant nettoyée :

- si la narration retombe exactement sur le prompt principal, la body line ne le répète plus ;
- fallback discret utilisé : `Choisis une action.`

## Modified Files

Fichiers effectivement modifiés/créés pendant le lot 4e :

- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_scene_layout.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_scene_combatant_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_scene_hud_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_scene_hud_layout.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_scene_layout_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_scene_hud_layout_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_overlay_component_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_command_menu_component_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_pokemon_sprite_resolver_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/tool/render_lot_4e_battle_visuals_test.dart`

## Strategy Retained

Le lot 4d avait déjà la bonne architecture de base. Le lot 4e l’a gardée et l’a resserrée :

1. ne pas refaire l’architecture ;
2. corriger le layout pur uniquement là où la perception restait mauvaise ;
3. ajouter un layout interne pur pour les HUDs ;
4. ajouter un layout mesuré pour les boutons root ;
5. produire de vraies captures au lieu de se contenter de tests de rect.

## Viewports Validated

### Table

| Viewport | Mode | Scale |
| --- | --- | --- |
| `390x844` | `stacked` | `0.406` |
| `528x467` | `split` | `0.550` |
| `844x390` | `split` | `0.618` |
| `960x540` | `split` | `1.000` |
| `1012x467` | `split` | `0.852` |
| `1280x720` | `split` | `1.000` |
| `1600x900` | `split` | `1.000` |
| `1024x768` | `split` | `1.000` |

### Main Layout Snapshots

#### `390x844`

- `enemyHudRect = Rect.fromLTRB(6.5, 402.2, 91.8, 429.9)`
- `playerHudRect = Rect.fromLTRB(271.4, 493.2, 370.5, 522.5)`
- `enemySpriteRect = Rect.fromLTRB(251.5, 423.4, 336.8, 485.9)`
- `playerSpriteRect = Rect.fromLTRB(-35.3, 442.9, 106.8, 529.8)`
- `commandPanelRect = Rect.fromLTRB(12.0, 545.0, 378.0, 832.0)`

Notes :

- stacked mode lisible ;
- le joueur reste au-dessus du panel ;
- crop gauche du joueur acceptable mais visiblement présent.

#### `528x467`

- `enemyHudRect = Rect.fromLTRB(8.8, 111.9, 124.3, 149.3)`
- `playerHudRect = Rect.fromLTRB(367.4, 235.1, 501.6, 274.7)`
- `enemySpriteRect = Rect.fromLTRB(340.5, 140.5, 456.0, 225.2)`
- `playerSpriteRect = Rect.fromLTRB(-47.8, 166.9, 144.7, 284.6)`
- `commandPanelRect = Rect.fromLTRB(16.0, 301.0, 512.0, 453.0)`

Notes :

- viewport critique issu des retours produit ;
- plus d’overlap évident HUD ennemi / joueur ;
- crop gauche du joueur reste assumé.

#### `844x390`

- `enemyHudRect = Rect.fromLTRB(135.2, 12.9, 265.0, 55.0)`
- `playerHudRect = Rect.fromLTRB(538.2, 151.4, 689.1, 195.9)`
- `enemySpriteRect = Rect.fromLTRB(507.9, 45.1, 637.7, 140.3)`
- `playerSpriteRect = Rect.fromLTRB(71.5, 74.8, 287.9, 207.1)`
- `commandPanelRect = Rect.fromLTRB(16.0, 224.0, 828.0, 376.0)`

Notes :

- paysage mobile lisible ;
- menu root garde sa grille 2x2 ;
- HUD joueur dégagé du battler.

#### `960x540`

- `enemyHudRect = Rect.fromLTRB(16.0, 32.7, 226.0, 100.7)`
- `playerHudRect = Rect.fromLTRB(668.0, 256.7, 912.0, 328.7)`
- `enemySpriteRect = Rect.fromLTRB(619.0, 84.7, 829.0, 238.7)`
- `playerSpriteRect = Rect.fromLTRB(-87.0, 132.7, 263.0, 346.7)`
- `commandPanelRect = Rect.fromLTRB(16.0, 366.7, 944.0, 526.0)`

Notes :

- viewport de référence du layout ;
- relation proche de la composition Pokémon-like voulue ;
- encore non vendable comme “pixel-perfect GIF clone”.

#### `1012x467`

- `enemyHudRect = Rect.fromLTRB(110.9, 14.8, 289.7, 72.7)`
- `playerHudRect = Rect.fromLTRB(666.1, 205.6, 873.9, 266.9)`
- `enemySpriteRect = Rect.fromLTRB(624.4, 59.1, 803.2, 190.2)`
- `playerSpriteRect = Rect.fromLTRB(23.2, 100.0, 321.2, 282.2)`
- `commandPanelRect = Rect.fromLTRB(16.0, 301.0, 996.0, 453.0)`

Notes :

- viewport produit explicitement demandé ;
- plus d’overlap structurel évident ;
- HUD et panel restent lisibles.

#### `1280x720`

- `enemyHudRect = Rect.fromLTRB(176.0, 190.0, 386.0, 258.0)`
- `playerHudRect = Rect.fromLTRB(828.0, 414.0, 1072.0, 486.0)`
- `enemySpriteRect = Rect.fromLTRB(779.0, 242.0, 989.0, 396.0)`
- `playerSpriteRect = Rect.fromLTRB(73.0, 290.0, 423.0, 504.0)`
- `commandPanelRect = Rect.fromLTRB(16.0, 524.0, 1264.0, 706.0)`

Notes :

- wide desktop sans inflation supplémentaire ;
- tailles perçues bornées ;
- battlers non dispersés.

## Captures Produced

Captures réellement générées :

- `/Users/karim/Project/pokemonProject/reports/visual/lot-4e/battle-390x844.png`
- `/Users/karim/Project/pokemonProject/reports/visual/lot-4e/battle-528x467.png`
- `/Users/karim/Project/pokemonProject/reports/visual/lot-4e/battle-844x390.png`
- `/Users/karim/Project/pokemonProject/reports/visual/lot-4e/battle-960x540.png`
- `/Users/karim/Project/pokemonProject/reports/visual/lot-4e/battle-1012x467.png`
- `/Users/karim/Project/pokemonProject/reports/visual/lot-4e/battle-1280x720.png`

### Visual Before/After Notes

- les captures montrent bien la disparition des overlaps structurels qui restaient problématiques dans les retours utilisateur ;
- le joueur reste plus bas et plus large que l’ennemi ;
- le HUD ennemi reste compact et séparé du battler ;
- le HUD joueur reste au-dessus du panel ;
- le menu root tient sur petit format sans collision visible.

Note honnête :

- comme le repo local ne fournit pas de media Pokémon battle authorés dans le golden slice utilisé par cet utilitaire, les PNG produits affichent des fallback silhouettes plutôt que des sprites Pokémon détaillés.
- elles sont donc valides pour l’anti-overlap, le staging, les HUDs et les panneaux, mais pas pour juger la fidélité finale d’un sprite pixel-art réel face au GIF.

## What The Tests Prove

Les tests ajoutés/renforcés prouvent :

- absence d’overlap layout critique sur les viewports produit ;
- stabilité de taille perçue entre référence et wide desktop ;
- relation correcte entre sprites, plateformes, HUDs et panel ;
- robustesse interne du HUD pour textes longs/courts ;
- robustesse du root menu pour labels et subtitles ;
- non-duplication du prompt principal dans la narration secondaire ;
- maintien des comportements fonctionnels existants du menu et du runtime battle.

## What The Captures Prove

Les captures prouvent visuellement :

- qu’aucun chevauchement évident ne subsiste entre battlers/HUDs/panel sur les viewports demandés ;
- que le panel bas et le root menu tiennent visuellement sur portrait et paysage ;
- que la scène est plus proche de la hiérarchie Pokémon-like voulue.

## What Remains Subjective

Reste subjectif, donc non “mathématiquement clos” par ce lot :

- la sensation exacte de proximité avec le GIF Pokémon ;
- le dosage précis du crop gauche du joueur ;
- la taille artistique idéale des battlers si de vrais sprites pixel-art de production sont branchés plus tard ;
- un éventuel dernier pass purement DA sur palettes, contours et chrome visuel.

## Validations Executed

### Runtime Analyze

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter analyze --no-pub \
  lib/src/presentation/flame/battle_scene_layout.dart \
  lib/src/presentation/flame/battle_overlay_component.dart \
  lib/src/presentation/flame/battle_scene_combatant_component.dart \
  lib/src/presentation/flame/battle_scene_hud_component.dart \
  lib/src/presentation/flame/battle_command_panel_component.dart \
  lib/src/presentation/flame/battle_command_menu_model.dart \
  lib/src/presentation/flame/battle_scene_hud_layout.dart \
  test/battle_scene_layout_test.dart \
  test/battle_scene_hud_layout_test.dart \
  test/battle_overlay_component_test.dart \
  test/battle_command_menu_component_test.dart \
  test/battle_pokemon_sprite_resolver_test.dart \
  tool/render_lot_4e_battle_visuals_test.dart
```

Résultat :

- `No issues found!`

### Runtime Tests

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter test test/battle_scene_hud_layout_test.dart
flutter test \
  test/battle_scene_layout_test.dart \
  test/battle_overlay_component_test.dart \
  test/battle_command_menu_component_test.dart \
  test/battle_pokemon_sprite_resolver_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart \
  test/wild_battle_end_to_end_flow_test.dart
flutter test tool/render_lot_4e_battle_visuals_test.dart -r compact
```

Résultat :

- tous verts.

### Host Smoke

```bash
cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host
flutter test test/phase_a_golden_slice_launch_test.dart
```

Résultat :

- vert.

## Risks Remaining

- les captures générées localement utilisent des fallback silhouettes, pas des sprites pixel-art de production ;
- le lot ferme bien l’anti-overlap et la robustesse typographique, mais un jugement produit final peut encore demander un micro-pass purement artistique ;
- le utilitaire de capture est volontairement un outil de lot, pas un système de screenshot générique.

## Final Git State

État git final utile :

```text
 M examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart
 M examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_scene_combatant_component.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_scene_hud_component.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_scene_layout.dart
 M packages/map_runtime/test/battle_command_menu_component_test.dart
 M packages/map_runtime/test/battle_overlay_component_test.dart
 M packages/map_runtime/test/battle_pokemon_sprite_resolver_test.dart
 M packages/map_runtime/test/battle_scene_layout_test.dart
?? packages/map_runtime/lib/src/presentation/flame/battle_scene_hud_layout.dart
?? packages/map_runtime/test/battle_scene_hud_layout_test.dart
?? packages/map_runtime/tool/render_lot_4e_battle_visuals_test.dart
?? reports/lot-4e-battle-ui-visual-lock-report.md
?? reports/visual/lot-4e/battle-1012x467.png
?? reports/visual/lot-4e/battle-1280x720.png
?? reports/visual/lot-4e/battle-390x844.png
?? reports/visual/lot-4e/battle-528x467.png
?? reports/visual/lot-4e/battle-844x390.png
?? reports/visual/lot-4e/battle-960x540.png
```

Lecture honnête :

- le worktree final reste majoritairement dirty sur la surface `map_runtime` attendue, plus le report et les captures générées du lot ;
- un addendum post-lot a aussi modifié deux fichiers de `examples/playable_runtime_host` pour corriger un blocage réel du bouton `Lancer` sur projet desktop ;
- aucun fichier `map_battle`, `map_core` ou `map_editor` n’a été touché ;
- aucun commit, reset ou discard n’a été fait.

## Post-Lot Addendum — Example Host Launch Stall

Addendum ajouté après clôture fonctionnelle du lot 4e, parce qu’un bug réel de runtime host a été signalé juste après :

- sur certains projets desktop réels, cliquer sur `Lancer` laissait l’écran bloqué sur `Chargement...` ;
- le problème n’était pas dans `map_runtime` ni dans `loadRuntimeMapBundle` ;
- le problème venait du host example quand aucun `runtime_host_launch_save.json` n’était présent et que le fallback de seed de démo parcourait inutilement tout `data/pokemon/species`.

### Root Cause Confirmed

Cause confirmée localement :

- `loadRuntimeMapBundle(...)` retournait correctement ;
- `loadRuntimeHostLaunchSaveData(...)` retournait `null` correctement ;
- le blocage se produisait dans `buildRuntimeHostLaunchDemoPartySeed(...)` ;
- ce chemin scannait et parseait l’ensemble des espèces locales avant de choisir un Pokémon de démo préféré ;
- sur un vrai projet desktop avec beaucoup d’espèces ou un fichier espèce cassé non pertinent, cela pouvait soit ralentir fortement, soit casser le fallback de seed, ce qui laissait l’UI visuellement bloquée sur `Chargement...`.

### Files Modified In This Addendum

Fichiers touchés par cet addendum post-lot :

- `/Users/karim/Project/pokemonProject/examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart`
- `/Users/karim/Project/pokemonProject/examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart`

### Fix Applied

Correction appliquée :

- ajout d’un fast-path de résolution d’espèce préférée (`squirtle`, `carapuce`) par nom de fichier avant le scan complet ;
- si une espèce préférée valide est trouvée, le host ne parse plus inutilement tout le dossier `species/` ;
- le scan complet reste disponible en fallback si aucune espèce préférée n’est trouvée ;
- un test de non-régression prouve maintenant qu’un fichier espèce JSON cassé non pertinent ne bloque plus la préparation du Pokémon de démo si un `squirtle` valide est déjà présent.

### Additional Validations Executed

Commandes réellement relancées pour cet addendum :

```bash
cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host
flutter analyze --no-pub lib/src/runtime_demo_party_seed.dart test/runtime_demo_party_seed_test.dart
flutter test test/runtime_demo_party_seed_test.dart test/runtime_launch_save_test.dart test/project_loader_page_test.dart test/phase_a_golden_slice_launch_test.dart
```

Résultat :

- `flutter analyze` vert ;
- tous les tests ciblés host verts.

### Real-Project Reproduction Note

Reproduction locale faite sur le vrai projet utilisateur :

- `/Users/karim/Desktop/my_new_project/project.json`

Observation après correctif :

- `loadRuntimeMapBundle(...)` OK ;
- `loadRuntimeHostLaunchSaveData(...)` retourne `null` comme attendu sans bloquer ;
- `buildRuntimeHostLaunchDemoPartySeed(...)` revient en environ `142ms` sur ce projet au lieu de laisser le host collé visuellement sur `Chargement...`.

Note d’honnêteté :

- cette correction est hors périmètre strict de la battle UI visuelle du lot 4e ;
- elle a été ajoutée dans ce report uniquement pour garder l’historique du worktree et des fixes réellement appliqués cohérent avec l’état courant du repo.

## Final Decision

Décision honnête :

- le lot 4e est réussi sur son objectif strict `anti-overlap + HUD typography + capture-driven polish` ;
- le sprite joueur ne recroise plus la zone du HUD ennemi dans le contrat testé ;
- le sprite ennemi garde un gap avec le HUD ennemi ;
- les HUDs sont nettement plus robustes ;
- le menu root tient mieux les petits formats ;
- la prompt box ne duplique plus inutilement la question ;
- aucune logique battle-core n’a été rouverte ;
- le rendu est clairement meilleur et plus verrouillé qu’au lot 4d ;
- mais il serait malhonnête de vendre ce lot comme une validation artistique finale absolue face au GIF tant que les captures repo-locales ne branchent pas de vrais sprites Pokémon de production.
