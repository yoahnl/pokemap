# Lot 112 — Ice / Mud Movement Semantics Decision V0

## 1. Résumé exécutif honnête

Lot 112 est un lot documentaire. Aucun code de production, test Dart, modèle, JSON, runtime Flutter ou UI editor n'a été modifié.

Décision principale :

```text
Ne pas coder ice ni mud maintenant.
Recommander Lot 113 — Surface Movement Effects Model Decision V0.
```

Raison : `ice` et `mud` ne sont pas de simples variantes de `movement`, `hazard` ou `special` existants.

- `ice` demande une sémantique de mouvement forcé : direction, glissade en chaîne, arrêt sur obstacle, interaction avec warp/connection/collision.
- `mud` demande une sémantique de coût ou ralentissement : coût de déplacement, cadence, éventuel enlisement, et distinction avec `swamp`.
- `MovementZonePayload` ne sait exprimer ni glissade ni coût de mouvement.
- `HazardKind.swamp` existe, mais le contrat hazard actuel expose surtout `damagePerStep` via `GameplayHazardEffect`; l'utiliser pour de la boue ralentissante mentirait sur l'intention produit.
- `SpecialZonePayload(scriptKey: ...)` est possible techniquement, mais trop faible pour un workflow no-code propre.

Conclusion : ice et mud doivent être cadrés par une famille de contrats `movement effect` avant tout authoring editor.

## 2. Périmètre

Inclus :

- audit Lot 111 ;
- audit modèles `GameplayZoneKind`, `MovementZonePayload`, `HazardZonePayload`, `SpecialZonePayload` ;
- audit moteur de mouvement `stepGameplayWorld` ;
- audit legacy/surface ice ;
- audit legacy/surface mud/swamp ;
- audit tests existants ;
- comparaison des options ice ;
- comparaison des options mud ;
- roadmap recommandée ;
- relance des tests de clôture.

Exclus :

- aucun bouton ice ;
- aucun bouton mud ;
- aucune glissade ;
- aucun ralentissement ;
- aucun movement cost ;
- aucune modification `map_core`, `map_editor`, `map_gameplay`, `map_runtime`, `map_battle`.

## 3. Gate 0 — status initial

Commandes exécutées depuis `/Users/karim/Project/pokemonProject` avant modification :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 12
find . -name AGENTS.md -print
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
```

`git status --short --untracked-files=all` :

```text
```

`git diff --stat` :

```text
```

`git log --oneline -n 12` :

```text
f57ade04 Merge PSDK battle parity work
993b0033 Complete PSDK battle parity batch
a294999b lot 110: Lava Hazard Runtime E2E Closure
af24a783 lot 109: Editor Generate Lava Hazard Zone from Surface
3ef5fc92 lot 108: Hazard Runtime Consumption Prep
e8bfc68e lot 107: Lava Hazard from Surface Workflow Decision
4851b53f lot 106: Surface Behavior Action Menu
2305f276 lot 104: Surface Gameplay Bridge Runtime E2E Closure
d9a1a3e3 Port PSDK battle parity moves
8b5c3728 lot 103: Editor Generate Surfable Water Gameplay Zone from Surface
6a3db8e3 lot 101: Tall Grass Surface Workflow Hardening - Batch Apply
b224b0f6 fix: resolve RenderFlex overflow errors in layers and surface panels
```

`find . -name AGENTS.md -print` :

```text
./AGENTS.md
```

Changements préexistants : aucun au Gate 0.

Changements du Lot 112 : création du présent rapport Markdown uniquement.

Note de fin de lot : le status final montre aussi des modifications `map_runtime` apparues après le Gate 0. Je n'ai édité aucun de ces fichiers, aucun objectif Lot 112 ne les touche, et je ne les ai pas annulées afin de respecter les règles de non-revert des changements non attribuables au lot.

## 4. Context Mode usage

Context Mode a été utilisé pour les recherches larges, lectures multi-fichiers, sorties de tests, sorties Git déjà connues et synthèse d'audit.

Outils/appels utilisés :

- `tool_search` pour exposer les outils Context Mode ;
- `ctx_search` sur les sources indexées Lot 111, payloads, `stepGameplayWorld`, tests hazard/lava ;
- `ctx_batch_execute` pour regrouper cinq audits ciblés et indexer `1101` lignes / `92.7KB` ;
- `ctx_execute` pour les tests ciblés ;
- `ctx_search` pour récupérer les lignes finales exactes des sorties indexées ;
- `ctx_execute` pour `ctx stats`.

Résumé compact des économies observables :

```text
ctx_batch_execute : 5 commandes, 1101 lignes, 92.7KB indexés.
surface_painter regression : 5 sections indexées, 14.8KB.
map_runtime surface smoke : 2 sections indexées, 6.4KB.
Total minimal explicitement rapporté par Context Mode : 113.9KB indexés hors sorties courtes.
```

La commande shell `ctx stats` n'est pas disponible dans cet environnement. Sa sortie exacte est incluse section 28.

## 5. Audit Lot 111

Commande obligatoire exécutée :

```bash
rg -n "Lot 111|Ice|Mud|ice|mud|movement semantics|Surface Gameplay V1|Lot 112|Moved.hazardEffect|waterRequiresSurf|Lave dangereuse" reports/surface
```

Lecture prioritaire :

```text
reports/surface/surface_engine_lot_111_surface_gameplay_v1_status_roadmap.md
```

Findings :

- Lot 111 déclare couverts `tall_grass`, `water/surf` et `lava/hazard` dans leur périmètre V0.
- Lot 111 recommande Lot 112 parce que `ice` et `mud` touchent potentiellement au moteur de mouvement.
- Lot 111 rappelle que `ice` peut nécessiter glissade, direction forcée, arrêt sur obstacle et chain movement.
- Lot 111 rappelle que `mud` peut nécessiter movement cost, ralentissement, hazard swamp ou un nouveau signal.
- Lot 111 avertit qu'une action editor ice/mud sans audit reproduirait le risque évité pour lava.

Garanties déjà acquises avant Lot 112 :

- `SurfaceLayer` reste visuel.
- `MapGameplayZone` reste la source gameplay principale.
- `ProjectSurfacePreset` reste visuel.
- Aucun `SurfaceGameplayCatalog` parallèle n'existe.
- Tall grass peut générer `MapGameplayZone(kind: encounter)`.
- Water peut générer `MapGameplayZone(kind: movement)` avec `MovementZonePayload(requiredMode: MovementMode.surf)`.
- Lava peut générer `MapGameplayZone(kind: hazard)` avec `HazardZonePayload(hazardKind: HazardKind.lava, damagePerStep > 0)`.
- Lava est observable côté gameplay via `Moved.hazardEffect`.

Limites ouvertes pour ice/mud :

- pas de glissade ;
- pas de mouvement forcé ;
- pas de coût de déplacement ;
- pas de ralentissement ;
- pas de workflow editor ice/mud ;
- pas de smoke `PlayableMapGame` pour ces comportements.

## 6. Audit modèles gameplay zone

Commande obligatoire exécutée :

```bash
rg -n "GameplayZoneKind|MovementZonePayload|MovementMode|HazardZonePayload|HazardKind|SpecialZonePayload|scriptKey|movementCost|speed|slow|swamp|ice|mud|sliding|slide" packages/map_core/lib packages/map_core/test packages/map_editor/lib packages/map_gameplay/lib packages/map_runtime/lib
```

Lectures prioritaires :

```text
packages/map_core/lib/src/models/map_gameplay_zone_payloads.dart
packages/map_core/lib/src/operations/map_gameplay_zones.dart
packages/map_editor/lib/src/ui/panels/gameplay_zone_properties_panel.dart
```

Findings précis :

- `GameplayZoneKind` contient `encounter`, `movement`, `hazard`, `special`, `custom`.
- `MovementZonePayload` contient `requiredMode` et `allowedModes`.
- `MovementMode` contient `walk`, `surf`, `fly`, `cut`, `strength`, `rockSmash`.
- Il n'existe pas de `MovementMode.ice`, `MovementMode.mud`, `MovementMode.slide`.
- Il n'existe pas de champ `movementCost`, `speedModifier`, `slow`, `friction`, `forcedDirection`, `slideDistance` ou équivalent dans `MovementZonePayload`.
- `HazardZonePayload` contient `hazardKind` et `damagePerStep`.
- `HazardKind` contient `lava`, `poison`, `swamp`, `pitfall`, `other`.
- `HazardKind.swamp` existe avec intention commentaire `Ralentissement / enlisement`, mais le payload ne sait porter qu'un dommage numérique direct.
- `SpecialZonePayload` contient `scriptKey` et `properties`.
- Le panel éditeur expose déjà movement, hazard et special comme types génériques de zones, mais cela ne donne pas une sémantique moteur pour ice/mud.

Réponse aux questions modèle :

- `MovementZonePayload` sait-il représenter un ralentissement ? Non.
- `MovementZonePayload` sait-il représenter une glissade ? Non.
- `HazardZonePayload` possède-t-il swamp ? Oui, via `HazardKind.swamp`.
- `SpecialZonePayload` peut-il porter un script générique ? Oui.
- Est-ce suffisant pour no-code ice/mud ? Non, pas sans contrat moteur explicite.

## 7. Audit moteur de mouvement

Commande obligatoire exécutée :

```bash
rg -n "stepGameplayWorld|MoveIntent|MovementMode|Moved|Blocked|Direction|pixelsPerStep|waterRequiresSurf|collision|warp|ConnectionTriggered|PlacedElementInteracted|pathAnimationSignals|playerMovementMode|movementMode" packages/map_gameplay/lib packages/map_gameplay/test packages/map_runtime/lib packages/map_runtime/test
```

Lectures prioritaires :

```text
packages/map_gameplay/lib/src/gameplay_step.dart
packages/map_gameplay/lib/src/gameplay_step_result.dart
packages/map_gameplay/lib/src/gameplay_world_state.dart
packages/map_gameplay/test/movement_mode_water_test.dart
packages/map_gameplay/test/hazard_runtime_consumption_test.dart
```

Findings :

- `stepGameplayWorld` résout un `GameplayIntent`.
- `MoveIntent` porte une direction et un `pixelsPerStep`.
- `_resolveMove` met d'abord à jour la direction du joueur.
- Le blocage `waterRequiresSurf` arrive avant résolution pixel/collision solide.
- La collision solide retourne `Blocked`.
- Les connections, warps et placed elements peuvent interrompre un `Moved` normal.
- `Moved` peut porter `hazardEffect` depuis Lot 108.
- Le hazard est exposé après un mouvement réussi vers la position finale.
- Un mouvement bloqué ne porte pas de hazard effect.
- Le moteur ne sait pas enchaîner automatiquement plusieurs déplacements.
- Le moteur n'a pas de notion de mouvement forcé.
- `pixelsPerStep` règle la granularité d'un pas demandé, pas une politique persistante de ralentissement no-code.

Pourquoi ice est plus risqué que lava :

- lava est un effet post-mouvement : entrer dans la case produit un effet observable ;
- ice est une transformation du mouvement lui-même : entrée, continuation, arrêt, collision, warp et input suivant doivent être définis.

Pourquoi mud est plus risqué que water/surf :

- water/surf est un gate binaire : walking bloque, surfing passe ;
- mud demande une cadence, un coût, une friction ou un effet de lenteur, donc une politique temporelle/mouvement inexistante aujourd'hui.

## 8. Audit ice legacy / surface

Commande obligatoire exécutée :

```bash
rg -n "PathSurfaceKind.ice|ice|Ice|standard.*Ice|Surface.*ice|surfacePresetId.*ice|glide|slide|sliding|frozen|freeze" packages/map_core/lib packages/map_core/test packages/map_editor/lib packages/map_gameplay/lib packages/map_runtime/lib packages/map_runtime/test reports/surface
```

Commande ciblée complémentaire exécutée via Context Mode :

```bash
rg -n "PathSurfaceKind\.ice|standard[_-]?ice|createStandardIce|surfacePresetId: 'ice'|surfacePresetId.*ice|\bIce\b|\bice\b|\bslide\b|\bsliding\b|\bglide\b|\bfrozen\b|\bfreeze\b" packages/map_core/lib packages/map_core/test packages/map_editor/lib packages/map_gameplay/lib packages/map_runtime/lib packages/map_runtime/test reports/surface | head -n 220
```

Findings :

- `PathSurfaceKind.ice` existe côté legacy path/surface.
- Un builder `standard_ice_path_preset_vertical_atlas_builder.dart` existe côté `map_core`.
- `standard_ice_path_preset_vertical_atlas_builder_test.dart` caractérise un preset visuel ice.
- Les rapports anciens notent explicitement que ce builder ne code pas mouvement, glissade, friction ou runtime.
- Les tests `surface_layer_placements_test.dart` manipulent `surfacePresetId: 'ice'` comme donnée de placement visuel.
- Aucun test gameplay ne prouve une glissade.
- Aucun runtime Flame ne consomme `ice` comme mouvement forcé.

Conclusion ice :

```text
ice existe comme surface/legacy visuel, pas comme comportement gameplay.
```

## 9. Audit mud / swamp legacy / surface

Commande obligatoire exécutée :

```bash
rg -n "mud|Mud|swamp|Swamp|PathSurfaceKind.swamp|HazardKind.swamp|movementCost|slow|speed|friction|surfacePresetId.*mud|surfacePresetId.*swamp" packages/map_core/lib packages/map_core/test packages/map_editor/lib packages/map_gameplay/lib packages/map_runtime/lib packages/map_runtime/test reports/surface
```

Commande ciblée complémentaire exécutée via Context Mode :

```bash
rg -n "PathSurfaceKind\.swamp|HazardKind\.swamp|surfacePresetId: 'mud'|surfacePresetId.*mud|surfacePresetId.*swamp|\bmud\b|\bMud\b|\bswamp\b|\bSwamp\b|\bmovementCost\b|\bslow\b|\bfriction\b" packages/map_core/lib packages/map_core/test packages/map_editor/lib packages/map_gameplay/lib packages/map_runtime/lib packages/map_runtime/test reports/surface | head -n 220
```

Findings :

- `PathSurfaceKind.swamp` existe.
- `HazardKind.swamp` existe.
- `legacy_editor_json_compat.dart` mappe legacy `mud` vers `swamp`.
- Des tests Surface utilisent `surfacePresetId: 'mud'` comme id visuel.
- `surface_runtime_resolver_test.dart` utilise une cellule `mud` pour le rendu Surface.
- Aucun `PathSurfaceKind.mud` n'existe dans l'enum.
- Aucun champ `movementCost` n'a été trouvé dans les modèles gameplay/surface.
- Les occurrences `speed` trouvées sont liées aux animations, aux stats Pokémon ou au battle runtime, pas à la vitesse overworld Surface.

Conclusion mud/swamp :

```text
swamp existe comme type legacy/hazard potentiel.
mud existe surtout comme id/preset visuel ou alias legacy.
Le ralentissement mud n'existe pas comme contrat gameplay.
```

## 10. Audit tests existants

Commande obligatoire exécutée :

```bash
rg -n "ice|mud|swamp|MovementMode|MovementZonePayload|HazardKind.swamp|stepGameplayWorld|pixelsPerStep|surface_generated_gameplay_zone_bridge|hazard_runtime_consumption|movement_mode_water" packages/map_core/test packages/map_gameplay/test packages/map_editor/test packages/map_runtime/test
```

Commande ciblée complémentaire exécutée via Context Mode :

```bash
rg -n "standard_ice_path_preset|HazardKind\.swamp|surface_generated_gameplay_zone_bridge|hazard_runtime_consumption|movement_mode_water|surfacePresetId: 'mud'|surfacePresetId: 'ice'|MovementZonePayload|stepGameplayWorld|pixelsPerStep" packages/map_core/test packages/map_gameplay/test packages/map_editor/test packages/map_runtime/test | head -n 220
```

Findings :

- Tests ice existants : `packages/map_core/test/standard_ice_path_preset_vertical_atlas_builder_test.dart`, centrés sur preset visuel/atlas.
- Tests ice gameplay : aucun trouvé.
- Tests mud/swamp existants : placements Surface et runtime resolver visuel avec `mud`, plus enum `HazardKind.swamp`.
- Tests mud gameplay slow/cost : aucun trouvé.
- Tests réutilisables pour futur Lot 113 :
  - `movement_mode_water_test.dart` pour pattern gate movement ;
  - `hazard_runtime_consumption_test.dart` pour pattern effet post-mouvement ;
  - `surface_generated_gameplay_zone_bridge_test.dart` pour pattern Surface -> GameplayZone -> gameplay ;
  - tests `surface_to_gameplay_zone_generation_plan` pour génération pure.

Tests manquants avant implémentation :

- caractérisation d'un effet de mouvement forcé ;
- caractérisation d'un effet movement cost/slow ;
- interaction avec collision solide ;
- interaction avec waterRequiresSurf ;
- interaction avec warp/connection ;
- interaction avec `Moved.hazardEffect` si une cellule combine hazard et movement effect.

## 11. Options ice comparées

| Option | Description | Avantages | Inconvénients | Verdict |
|---|---|---|---|---|
| Ice A | `MapGameplayZone(kind: movement)` avec mode existant | Réutilise `movement`; compatible modèle actuel | `MovementMode` décrit un mode du joueur, pas une surface qui force une glissade ; aucun champ direction/chain/stop | Rejetée pour V0 |
| Ice B | `MapGameplayZone(kind: special)` avec `scriptKey: "ice_slide"` | Aucun modèle nouveau ; possible à court terme | Trop string-based ; cache une mécanique moteur ; mauvais no-code | Rejetée comme solution principale |
| Ice C | Nouveau contrat gameplay spécifique plus tard | Honnête ; testable ; exprime forced movement/slide | Nécessite un lot runtime prep | Recommandée |
| Ice D | Ice visuel uniquement | Aucun risque moteur | Repousse un comportement Pokémon-like classique | Acceptable temporairement, pas comme roadmap |

## 12. Décision ice V0

Décision :

```text
Ice ne doit pas être codé avec les payloads actuels.
Ice doit attendre un contrat explicite de mouvement forcé / glissade.
```

Forme probable à décider au Lot 113 :

```text
GameplayMovementEffect
ForcedMovementEffect
SlideEffect
```

Questions à trancher avant code :

- l'effet est-il attaché à `Moved` comme `hazardEffect` ?
- l'effet est-il un nouveau résultat de step ?
- qui pilote le chain movement : `map_gameplay` ou `map_runtime` ?
- que se passe-t-il sur obstacle, warp, connection, placed element ?
- le joueur peut-il changer de direction pendant la glissade ?

## 13. Options mud comparées

| Option | Description | Avantages | Inconvénients | Verdict |
|---|---|---|---|---|
| Mud A | `MapGameplayZone(kind: movement)` avec movement cost futur | Sémantique correcte pour boue ralentissante | `movementCost` n'existe pas ; besoin contrat gameplay | Recommandée conceptuellement, après Lot 113 |
| Mud B | `MapGameplayZone(kind: hazard)` avec `HazardKind.swamp` | `HazardKind.swamp` existe ; réutilise `hazardEffect` | Boue ralentissante n'est pas forcément dégâts ; `damagePerStep` ne porte pas le slow | Rejetée pour mud slow pur |
| Mud C | `SpecialZonePayload(scriptKey: "mud_slow")` | Aucun modèle nouveau | Faiblement typé ; mauvais no-code ; fragile | Rejetée comme solution principale |
| Mud D | Mud visuel uniquement | Aucun risque moteur | Retarde un comportement utile | Acceptable temporairement |

## 14. Décision mud V0

Décision :

```text
Mud ralentissant doit être traité comme un futur movement effect / movement cost, pas comme hazard damage.
```

Nuance importante :

```text
Swamp dangereux peut rester candidat `HazardKind.swamp`.
Mud ralentissant ne doit pas être automatiquement mappé vers `HazardKind.swamp`.
```

Donc :

- `MovementZonePayload` actuel est insuffisant pour mud ;
- `HazardKind.swamp` est pertinent pour marais dangereux/enlisement si l'effet futur le définit ;
- `SpecialZonePayload` peut servir à des prototypes scriptés, mais ne doit pas devenir la voie no-code V0.

## 15. Décision : ice et mud ensemble ou séparés

Options comparées :

| Option | Description | Décision |
|---|---|---|
| A | traiter ice et mud dans le même futur lot runtime | Non : deux mécaniques différentes |
| B | traiter ice d'abord, mud ensuite | Oui après un lot commun de modèle |
| C | traiter mud d'abord, ice ensuite | Non : mud demande movement cost et valeur produit moins claire immédiatement |
| D | ne traiter aucun des deux maintenant | Non comme roadmap, oui pour le présent lot |

Décision :

```text
Ne pas coder ice et mud ensemble.
Faire d'abord un lot commun de décision modèle movement effects.
Puis traiter ice sliding avant mud movement cost.
```

Raison :

- ice et mud pointent tous deux vers une famille d'effets de mouvement ;
- ice demande mouvement forcé ;
- mud demande coût/ralentissement ;
- un socle commun évite deux solutions incompatibles ;
- les implémentations doivent ensuite rester séparées.

## 16. Roadmap recommandée

Prochain lot recommandé :

```text
Lot 113 — Surface Movement Effects Model Decision V0
```

But :

```text
Décider le contrat commun pour les effets de mouvement Surface avant glissade ou ralentissement.
```

Questions Lot 113 :

- `GameplayMovementEffect` ou effets séparés ?
- champ optionnel dans `Moved` ou helper pur ?
- forced movement piloté par gameplay ou runtime ?
- movement cost exprimé en coût abstrait, cadence, pixelsPerStep ou délai ?
- interaction avec collision, warp, waterRequiresSurf et hazardEffect ?

Roadmap post Lot 112 :

| Lot | Sujet | Classement | Risque principal |
|---|---|---|---|
| 113 | Surface Movement Effects Model Decision V0 | Indispensable | modèle trop générique ou trop string-based |
| 114 | Ice Sliding Runtime Prep V0 | Indispensable | chain movement / collision / warp |
| 115 | Editor Generate Ice Behavior from Surface V0 | Indispensable après runtime | bouton décoratif si runtime incomplet |
| 116 | Ice Runtime E2E / Closure V0 | Indispensable | preuve incomplète si pas de chain movement |
| 117 | Mud Movement Cost Decision / Prep V0 | Indispensable mais après ice | coût de mouvement non aligné runtime |
| 118 | Editor Generate Mud Behavior from Surface V0 | Utile après prep | confusion mud vs swamp |
| 119 | Surface Gameplay Diagnostics / Coverage Preview V0 | Utile | mini assistant trop lourd |
| 120 | PlayableMapGame Surface Gameplay Smoke V0 | Utile | tests Flame bruités |
| 121 | Surface Gameplay V1 Documentation | Utile | documentation prématurée si movement effects changent |
| 122 | Surface Behavior Tests Split / Maintenance V0 | À retarder | valeur produit faible mais dette réelle |

## 17. Tests relancés

Commandes exécutées :

```bash
cd packages/map_editor && flutter test test/surface_painter/surface_to_gameplay_zone_action_test.dart --no-pub --reporter expanded
cd packages/map_editor && flutter test test/surface_painter --no-pub --reporter expanded
cd packages/map_gameplay && dart test test/surface_generated_gameplay_zone_bridge_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/hazard_runtime_consumption_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/movement_mode_water_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/surf_evaluation_test.dart --reporter expanded
cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_plan_test.dart --reporter expanded
cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_assessment_test.dart --reporter expanded
cd packages/map_runtime && flutter test test/surface --reporter expanded
```

## 18. Résultats

Lignes finales exactes observées :

```text
surface_to_gameplay_zone_action_test.dart: 00:01 +29: All tests passed!
test/surface_painter: 00:02 +71: All tests passed!
surface_generated_gameplay_zone_bridge_test.dart: 00:00 +6: All tests passed!
hazard_runtime_consumption_test.dart: 00:00 +8: All tests passed!
movement_mode_water_test.dart: 00:00 +6: All tests passed!
surf_evaluation_test.dart: 00:00 +12: All tests passed!
surface_to_gameplay_zone_generation_plan_test.dart: 00:00 +16: All tests passed!
surface_to_gameplay_zone_generation_assessment_test.dart: 00:00 +12: All tests passed!
map_runtime test/surface: 00:01 +29: All tests passed!
```

Résultat global : tous les tests de clôture demandés sont verts.

## 19. Analyse lancée

Aucune analyse Dart ciblée lancée.

Justification :

```text
Aucun fichier Dart n'a été créé ou modifié dans le Lot 112.
```

## 20. Résultats analyze

Sans objet pour ce lot documentaire.

## 21. Fichiers créés

```text
reports/surface/surface_engine_lot_112_ice_mud_movement_semantics_decision.md
```

## 22. Fichiers modifiés

```text
Aucun fichier modifié par le Lot 112.
```

Modification non-Lot112 visible au status final :

```text
packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart
packages/map_runtime/test/runtime_battle_move_bridge_test.dart
packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
```

## 23. Fichiers supprimés

```text
Aucun.
```

## 24. Contenu complet des fichiers créés

Fichier créé :

```text
reports/surface/surface_engine_lot_112_ice_mud_movement_semantics_decision.md
```

Le contenu complet de ce fichier est le présent rapport. Il n'est pas dupliqué une seconde fois dans cette section afin de respecter l'exception explicite anti-récursion du prompt.

## 25. Contenu complet des fichiers modifiés

```text
Aucun fichier modifié par le Lot 112.
```

Des fichiers `map_runtime` apparaissent modifiés dans le status final, mais ils n'ont pas été modifiés par ce lot. Le diff inspecté concerne le bridge battle move / setup mapper, sans lien avec Surface Gameplay ice/mud.

Fichiers hors Lot 112 visibles :

```text
packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart
packages/map_runtime/test/runtime_battle_move_bridge_test.dart
packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
```

## 26. Git status final

Commandes exécutées :

```bash
git status --short --untracked-files=all
git diff --stat
git diff --check
rg -n <liste-des-formulations-interdites-du-prompt> reports/surface/surface_engine_lot_112_ice_mud_movement_semantics_decision.md || true
wc -l reports/surface/surface_engine_lot_112_ice_mud_movement_semantics_decision.md
```

`git status --short --untracked-files=all` :

```text
 M packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart
 M packages/map_runtime/test/runtime_battle_move_bridge_test.dart
 M packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
?? reports/surface/surface_engine_lot_112_ice_mud_movement_semantics_decision.md
```

`git diff --stat` :

```text
 .../application/runtime_battle_move_bridge.dart    |  74 +++++++++++++-
 .../test/runtime_battle_move_bridge_test.dart      | 101 +++++++++++++++++++
 .../test/runtime_battle_setup_mapper_test.dart     | 107 ++++++++++++++++++++-
 3 files changed, 278 insertions(+), 4 deletions(-)
```

`git diff --check` :

```text
```

Vérification des formulations interdites dans le rapport :

```text
```

Taille du rapport après la seconde mise à jour finale :

```text
     722 reports/surface/surface_engine_lot_112_ice_mud_movement_semantics_decision.md
```

## 27. Périmètre explicitement non touché

Confirmations :

- map_core production non modifié ;
- map_editor production non modifié ;
- map_gameplay production non modifié ;
- map_runtime production non modifié par le Lot 112 ;
- map_battle non modifié ;
- `MapData` modèle non modifié ;
- `MapGameplayZone` modèle non modifié ;
- `HazardZonePayload` non modifié ;
- `HazardKind` non modifié ;
- `MovementZonePayload` non modifié ;
- `MovementMode` non modifié ;
- `SpecialZonePayload` non modifié ;
- `EncounterZonePayload` non modifié ;
- `SurfaceLayer` non modifié ;
- `SurfaceCellPlacement` non modifié ;
- `ProjectManifest` non modifié ;
- aucun JSON ;
- aucun generated/build_runner ;
- aucune action editor nouvelle ;
- aucun dialog editor nouveau ;
- aucune glissade codée ;
- aucun ralentissement codé ;
- aucun movement cost codé ;
- aucun runtime `PlayableMapGame` modifié ;
- aucun feedback runtime Flutter ;
- aucune mutation `GameState` / party / HP ;
- aucune migration legacy ;
- aucun filtre `surfacePresetId` dans `MapGameplayZone`.

## 28. ctx stats

Commande exécutée :

```bash
ctx stats
```

Sortie exacte :

```text
Exit code: 127

stdout:


stderr:
/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/.ctx-mode-TsmjiL/script.sh: line 1: ctx: command not found
```

Synthèse Context Mode disponible malgré l'absence du CLI :

```text
ctx_batch_execute : 5 commandes, 1101 lignes, 92.7KB indexés.
surface_painter regression : 5 sections indexées, 14.8KB.
map_runtime surface smoke : 2 sections indexées, 6.4KB.
Total minimal explicitement rapporté : 113.9KB indexés.
```

## 29. Limites restantes

- Ice n'a pas encore de contrat de glissade.
- Mud n'a pas encore de contrat de ralentissement.
- `MovementZonePayload` ne porte pas de coût de déplacement.
- `HazardKind.swamp` n'est pas encore consommé comme ralentissement.
- `SpecialZonePayload` reste trop faible pour une UX no-code propre.
- Aucun `PlayableMapGame` smoke ne valide de future glissade ou lenteur.
- Les interactions avec warp/connection/collision doivent être décidées avant runtime ice.
- Mud et swamp doivent rester distingués produit : boue ralentissante vs marais dangereux/enlisement.

## 30. Auto-critique

- Est-ce que ice a été audité ? Oui.
- Est-ce que mud/swamp a été audité ? Oui.
- Est-ce que le moteur de mouvement a été audité ? Oui.
- Est-ce que `MovementZonePayload` est suffisant pour ice ? Non : il ne porte ni glissade, ni direction forcée, ni chain movement.
- Est-ce que `MovementZonePayload` est suffisant pour mud ? Non : il ne porte ni movement cost, ni slow, ni cadence.
- Est-ce que `SpecialZonePayload` est une bonne option ? Non comme voie principale : techniquement possible, mais trop string-based et peu no-code.
- Est-ce que `HazardKind.swamp` est pertinent pour mud ? Partiellement : pertinent pour swamp dangereux/enlisement, pas pour mud slow pur.
- Est-ce que ice et mud doivent être codés ensemble ? Non : même famille générale d'effets de mouvement, mais mécaniques différentes.
- Est-ce que le prochain lot recommandé est explicite ? Oui : Lot 113 — Surface Movement Effects Model Decision V0.
- Est-ce qu'aucun code de production n'a été modifié ? Oui par le Lot 112. L'état Git final contient une modification `map_runtime` hors Lot 112 apparue après le Gate 0 et non annulée.
- Est-ce que les tests de clôture ont été relancés ? Oui.
- Est-ce que Context Mode a été utilisé agressivement ? Oui.
- Est-ce que ctx stats est inclus ? Oui, avec la sortie exacte de la commande et la synthèse MCP disponible.
- Est-ce que le contenu complet des fichiers créés/modifiés est copié dans le rapport ? Oui pour les fichiers modifiés, aucun ; pour le fichier créé, le présent rapport n'est pas recopié récursivement conformément à l'exception explicite.
- Est-ce qu'un Lot 112-bis est nécessaire ? Non. La décision est nette : ne pas coder ice/mud avant un contrat movement effects.

## 31. Regard critique sur le prompt

Le prompt impose le bon tempo : après tall grass, water et lava, il empêche d'ajouter ice/mud par inertie. C'est particulièrement important parce que la glissade et le ralentissement touchent au coeur du mouvement, contrairement à lava V0 qui reste un effet observable après mouvement.

Le point le plus utile du prompt est la comparaison `movement` / `hazard` / `special` / futur modèle. Elle évite deux pièges : surcharger `MovementMode` avec une surface, ou cacher un comportement moteur dans un `scriptKey`.

La seule friction est l'exigence `ctx stats` alors que le CLI `ctx` n'est pas exposé dans cet environnement. Le rapport inclut donc la sortie exacte de la commande et les métriques MCP disponibles, ce qui donne une preuve honnête de l'usage Context Mode sans inventer de statistiques.
