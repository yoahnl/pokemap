# Lot 107 — Lava Hazard from Surface Decision / Prep V0

## 1. Résumé exécutif honnête

Le modèle `hazard/lava` existe déjà côté `map_core`, et la brique pure du bridge Surface -> GameplayZone sait déjà générer un `MapGameplayZone(kind: hazard)` avec :

```text
HazardZonePayload(hazardKind: HazardKind.lava, damagePerStep: 5)
```

Mais le runtime/gameplay overworld ne consomme pas encore les zones hazard. Aucun chemin `map_gameplay` ou `map_runtime` ne lit `GameplayZoneKind.hazard`, `HazardZonePayload`, `damagePerStep` ou `zone.hazard` pour appliquer des dégâts, produire un événement, modifier le `GameState`, afficher un feedback, ou bloquer/altérer un mouvement.

Décision : ne pas coder l'action editor "Lave dangereuse" au prochain lot immédiat. Le prochain lot recommandé est :

```text
Lot 108 — Hazard Runtime Consumption Prep V0
```

Objectif : définir et prouver la consommation gameplay minimale des hazards overworld avant de créer une action editor qui générerait une zone actuellement inerte.

## 2. Périmètre

Inclus :

- audit du menu Lot 106 ;
- audit `HazardZonePayload` / `HazardKind` ;
- audit consommation gameplay/runtime hazards ;
- audit des surfaces lava visuelles ;
- audit des tests hazard existants ;
- décision payload lava V0 ;
- décision `damagePerStep` ;
- stratégie cellules lava ;
- UX future recommandée ;
- diagnostics UX futurs ;
- recommandation du prochain lot ;
- relance des tests pertinents.

Exclus :

- aucune action UI lava ;
- aucun dialog lava ;
- aucun runtime hazard ;
- aucune modification modèle ;
- aucun code production.

## 3. Gate 0 — status initial

Commandes exécutées avant modification :

```text
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
find . -name AGENTS.md -print
```

Sortie initiale :

```text
## pwd
/Users/karim/Project/pokemonProject

## git branch --show-current
main

## git status --short --untracked-files=all
(empty)

## git diff --stat
(empty)

## git log --oneline -n 10
4851b53f lot 106: Surface Behavior Action Menu
2305f276 lot 104: Surface Gameplay Bridge Runtime E2E Closure
8b5c3728 lot 103: Editor Generate Surfable Water Gameplay Zone from Surface
6a3db8e3 lot 101: Tall Grass Surface Workflow Hardening - Batch Apply
b224b0f6 fix: resolve RenderFlex overflow errors in layers and surface panels
888f1339 fix: resolve RenderFlex overflow errors in layers and surface panels
58ab7070 lot 100/95: Editor Generate Gameplay Zone from Surface
15fa925c lot 99/95: Surface Gameplay - Surface to Gameplay Zone Coverage Diagnostics
70b0f90d lot 98/95: Surface Gameplay - Surface to Gameplay Zone Generation Plan
8d62718f lot 97/95: Surface Gameplay - Surface to Gameplay Zone Authoring Workflow Spec

## find . -name AGENTS.md -print
./AGENTS.md
```

Changements préexistants : aucun.

Changements du Lot 107 : création du présent rapport uniquement.

## 4. Context Mode usage

Context Mode a été utilisé pour les audits et sorties potentiellement longues :

- Gate 0 ;
- audit Lot 106 ;
- audit model/payload hazard ;
- audit gameplay/runtime hazard ;
- audit surfaces lava visuelles ;
- audit tests hazard existants ;
- tests de non-régression.

Commandes d'audit principales :

```text
rg -n "SurfaceBehaviorActionMenu|Créer un comportement depuis cette surface|Herbe haute avec rencontres|Eau surfable|SurfaceToGameplayZoneDialog|SurfableWaterSurfaceGameplayZoneDialog|applyTallGrassEncounterGameplayZonePlan|applySurfableWaterGameplayZonePlan" packages/map_editor/lib packages/map_editor/test reports/surface
rg -n "HazardZonePayload|HazardKind|GameplayZoneKind.hazard|hazardKind|damagePerStep|hazard:" packages/map_core/lib packages/map_core/test packages/map_editor/lib packages/map_editor/test packages/map_gameplay/lib packages/map_gameplay/test packages/map_runtime/lib packages/map_runtime/test
rg -n "HazardKind|HazardZonePayload|damagePerStep|GameplayZoneKind.hazard|hazard|stepGameplayWorld|GameplayStep|GameState|hp|damage|poison|lava|swamp|pitfall" packages/map_gameplay/lib packages/map_gameplay/test packages/map_core/lib packages/map_core/test
rg -n "HazardKind|damagePerStep|hazard|GameplayZoneKind.hazard|stepGameplayWorld|GameplayStep|GameState|party|hp|PlayableMapGame|timeline|feedback|damage" packages/map_runtime/lib packages/map_runtime/test packages/map_gameplay/lib packages/map_gameplay/test
rg -n "lava|Lava|surfacePresetId|ProjectSurfacePreset|SurfaceLayer|SurfacePainter|SurfacePalettePanel|SurfaceBehaviorActionMenu|surfaceCatalog" packages/map_core/lib packages/map_editor/lib packages/map_runtime/lib packages/map_editor/test packages/map_runtime/test
rg -n "hazard|HazardKind|damagePerStep|lava|swamp|pitfall|GameplayZoneKind.hazard|stepGameplayWorld|surface_generated_gameplay_zone_bridge" packages/map_core/test packages/map_gameplay/test packages/map_editor/test packages/map_runtime/test
```

## 5. Audit Surface Behavior Action Menu

Le Lot 106 a créé `SurfaceBehaviorActionMenu`, utilisé par `SurfacePainterPanel`.

État actuel :

- le bouton principal est `Créer un comportement depuis cette surface` ;
- il ouvre un `CupertinoActionSheet` ;
- il propose `Herbe haute avec rencontres` ;
- il propose `Eau surfable` ;
- le choix tall grass ouvre `SurfaceToGameplayZoneDialog` ;
- le choix water ouvre `SurfableWaterSurfaceGameplayZoneDialog` ;
- les helpers métier existants restent `applyTallGrassEncounterGameplayZonePlan(...)` et `applySurfableWaterGameplayZonePlan(...)`.

Ce qu'il faudrait ajouter pour lava plus tard :

- un troisième choix `Lave dangereuse` ;
- un dialog spécifique `Créer une zone de lave dangereuse` ;
- un presenter lava qui construit un plan hazard ;
- un helper d'application lava qui refuse les plans non hazard/lava ou `damagePerStep <= 0`.

Le menu V0 est prêt à accueillir un troisième comportement parce que l'action sheet est déjà un routeur de comportements, mais il ne faut pas l'étendre tant que la consommation runtime hazard n'est pas prouvée.

## 6. Audit HazardZonePayload / HazardKind

Fichier principal :

```text
packages/map_core/lib/src/models/map_gameplay_zone_payloads.dart
```

Structure exacte :

```text
HazardZonePayload({
  hazardKind: HazardKind.other par défaut,
  damagePerStep: 0 par défaut,
})
```

`damagePerStep` est un `int` non nullable. Il est optionnel au sens constructeur grâce à la valeur par défaut `0`, mais il n'est pas nullable.

Valeurs existantes de `HazardKind` :

```text
lava
poison
swamp
pitfall
other
```

`HazardKind.lava` existe donc déjà.

Validation `map_core` :

- `addGameplayZoneToMap` et `updateGameplayZoneOnMap` valident id, duplicate id, area non vide, area dans la map, special property keys ;
- aucune validation spécifique `hazardKind` / `damagePerStep` n'interdit `damagePerStep == 0` ;
- aucune validation ne force un payload hazard quand `kind == hazard`.

Panel éditeur existant :

- `GameplayZonePropertiesPanel` expose `GameplayZoneKind.hazard` ;
- le panel expose un dropdown `Hazard Kind` avec toutes les valeurs `HazardKind` ;
- le panel expose `Damage / step` ;
- l'input accepte uniquement des chiffres ;
- la sauvegarde construit `HazardZonePayload(hazardKind: _hazardKind, damagePerStep: _hazardDamagePerStep)`.

## 7. Audit consommation gameplay hazards

Résultat brutal : les hazards overworld ne sont pas consommés aujourd'hui par `map_gameplay`.

Points vérifiés :

- `stepGameplayWorld(...)` traite `MoveIntent` et `InteractIntent`.
- `_resolveMove(...)` gère out-of-bounds, connexions, eau/surf, collision pixel, warp, comportements de placed elements, signaux path animation, puis retourne `Moved`.
- `GameplayWorldState` construit un cache water depuis legacy `PathLayer` water et depuis `MapGameplayZone(kind: movement)` surf.
- Aucun cache équivalent hazard n'existe.
- `GameplayStepResult` ne contient pas de résultat `HazardTriggered`, `DamageApplied`, `PlayerDamaged`, ou équivalent.
- La recherche ciblée sur `packages/map_gameplay/lib` ne trouve pas d'usage production de `GameplayZoneKind.hazard`, `HazardZonePayload`, `damagePerStep`, `zone.hazard`.

Conclusion : `HazardZonePayload` est actuellement un modèle authoring/serialization/editor, pas une mécanique gameplay consommée.

## 8. Audit runtime / PlayableMapGame hazards

`PlayableMapGame` consomme les résultats de `stepGameplayWorld(...)` :

- `Blocked` ;
- `Moved` ;
- `WarpTriggered` ;
- `ConnectionTriggered` ;
- `PlacedElementInteracted` ;
- `MapEventInteracted` via les chemins existants.

Il existe un feedback spécifique pour water blocked via `waterRequiresSurf`, mais aucun feedback hazard overworld.

La recherche ciblée sur `packages/map_runtime/lib` ne trouve pas de consommation production de :

```text
GameplayZoneKind.hazard
HazardKind
HazardZonePayload
damagePerStep
zone.hazard
```

Les occurrences `hazard` dans `map_runtime` concernent surtout les hazards de combat comme Stealth Rock / Spikes ou des visuels de moves poison/lava. Elles ne prouvent pas une mécanique overworld lava.

Conclusion : un lot runtime/gameplay hazard est nécessaire avant d'exposer lava comme comportement editor réellement actif.

## 9. Audit Surface lava visuel

Constats :

- Des surfaces/presets de test utilisent déjà des ids/noms comme `lava`, `lava-surface`, `lava-atlas`.
- Le legacy path possède `PathSurfaceKind.lava` et un builder `standard-lava`.
- Les nouvelles `ProjectSurfacePreset` restent visuelles et ne portent pas de champ `isLava`, `hazardKind`, tag ou catégorie gameplay.
- Les `SurfaceCellPlacement` ne stockent que `x`, `y`, `surfacePresetId`.

Conséquence UX :

- le futur workflow ne doit pas deviner de manière autoritaire qu'une surface est de la lave ;
- il peut afficher un warning si l'id/nom ne ressemble pas à `lava` / `lave` ;
- la confirmation utilisateur reste indispensable ;
- ne pas ajouter `hazardKind` ou `isLava` à `ProjectSurfacePreset`.

## 10. Audit tests hazards existants

Tests trouvés :

- `packages/map_core/test/surface_to_gameplay_zone_generation_plan_test.dart` contient déjà `generates lava hazard payload` avec `HazardKind.lava` et `damagePerStep: 5`.
- `packages/map_core/test/standard_lava_path_preset_vertical_atlas_builder_test.dart` couvre le legacy path preset lava visuel.
- Plusieurs tests Surface utilisent `surfacePresetId: lava` ou `lava-surface` pour les surfaces visuelles.
- Des tests runtime/battle mentionnent des hazards de combat, mais ce sont des mécaniques battle, pas overworld.

Tests absents :

- aucun test `map_gameplay` ne prouve `damagePerStep` sur une zone hazard overworld ;
- aucun test `map_runtime` ne prouve un feedback/dégât lava overworld ;
- aucun test ne prouve un résultat `HazardTriggered` ou équivalent, car ce résultat n'existe pas.

## 11. Options de payload lava

Option A :

```text
HazardZonePayload(hazardKind: HazardKind.lava, damagePerStep: 5)
```

Avantages :

- compatible avec le modèle actuel ;
- déjà testé dans le plan pur ;
- lisible no-code ;
- évite une zone lava sans effet chiffré.

Inconvénients :

- le runtime n'applique pas encore les dégâts.

Option B :

```text
HazardZonePayload(hazardKind: HazardKind.lava, damagePerStep: 0)
```

Avantage :

- compatible modèle.

Inconvénient :

- zone dangereuse vide, mensongère côté produit.

Option C :

```text
SpecialZonePayload(scriptKey: ...)
```

Avantage :

- pourrait déléguer à du script.

Inconvénients :

- contourne le modèle hazard existant ;
- moins no-code ;
- dilue la décision `MapGameplayZone(kind: hazard)`.

Option D :

```text
ne pas coder l'éditeur tant que le runtime hazard n'est pas prouvé
```

Avantage :

- évite une action UI qui produit un comportement inerte.

Inconvénient :

- retarde la feature visible.

## 12. Décision payload V0

Décision payload V0 :

```text
HazardZonePayload(
  hazardKind: HazardKind.lava,
  damagePerStep: 5,
)
```

La valeur `5` est recommandée comme défaut produit V0, pas comme règle moteur. Le futur dialog devra afficher clairement `Dégâts par pas` et permettre de changer la valeur.

## 13. Décision damagePerStep

Décision : `damagePerStep` doit être positif pour confirmer une zone lava.

Règle UX recommandée :

- champ `Dégâts par pas` prérempli à `5` ;
- confirmation bloquée si valeur vide, non numérique ou `<= 0` ;
- ne pas créer de lava hazard avec `damagePerStep == 0`.

Justification :

- le modèle autorise `0`, mais la promesse utilisateur `Lave dangereuse` implique un effet ;
- `0` reste utile au modèle générique pour d'autres hazards ou compatibilité, mais pas pour lava V0.

## 14. Stratégie source/cellules lava

Décision : la zone hazard lava doit couvrir les cellules lava elles-mêmes.

Elle ne doit pas être générée sur les bords.

Raison :

- l'effet hazard doit s'appliquer quand le joueur entre/marche sur une cellule dangereuse ;
- cette stratégie correspond aux décisions tall grass et water : les zones gameplay couvrent les cellules peintes sources ;
- `greedyRectangles` reste la stratégie recommandée pour éviter d'inclure des cellules hors surface.

## 15. UX future recommandée

Workflow futur si le runtime hazard est prêt :

```text
Surface lava peinte
→ Créer un comportement depuis cette surface
→ Lave dangereuse
→ dialog "Créer une zone de lave dangereuse"
→ Dégâts par pas = 5 par défaut
→ preview textuelle assessment
→ confirmation
→ MapGameplayZone(kind: hazard)
```

Libellés recommandés :

- menu : `Lave dangereuse` ;
- dialog : `Créer une zone de lave dangereuse` ;
- champ : `Dégâts par pas` ;
- bouton : `Créer la zone de lave`.

Ne pas demander en V0 :

- `scriptKey` ;
- badge ;
- ability ;
- encounter table ;
- movement mode.

## 16. Diagnostics UX futurs

Blocking :

- aucune map active ;
- aucun calque Surface cible ;
- aucun preset Surface sélectionné ;
- aucun placement pour le preset ;
- `damagePerStep` manquant ;
- `damagePerStep <= 0` ;
- plan sans zone générée ;
- runtime hazard non supporté si l'action editor était tentée avant le lot runtime.

Warning :

- surface choisie pas clairement nommée `lava` / `lave` ;
- surface très irrégulière ;
- trop de rectangles générés ;
- overlap avec une zone hazard existante ;
- zone déjà dangereuse sur tout ou partie de la surface.

Info :

- couverture exacte ;
- nombre de cellules source ;
- nombre de zones générées ;
- ids ajustés pour éviter collision.

## 17. Conditions pour coder le prochain lot

Conditions déjà remplies :

- `HazardKind.lava` existe ;
- `HazardZonePayload` existe ;
- `damagePerStep` est utilisable ;
- le plan Surface -> GameplayZone sait générer `kind: hazard` ;
- le menu Lot 106 peut accueillir un troisième comportement ;
- les tests map_core hazard payload passent.

Condition non remplie :

- consommation runtime/gameplay hazard non prouvée.

Décision : le prochain lot ne doit pas être l'action editor lava. Il doit d'abord préparer/prouver la consommation hazard.

## 18. Roadmap post Lot 107

Roadmap recommandée :

| Lot | Sujet | Nature | But |
| --- | --- | --- | --- |
| 108 | Hazard Runtime Consumption Prep V0 | gameplay/runtime decision + tests | Définir comment `stepGameplayWorld` expose/applique un hazard overworld |
| 109 | Editor Generate Lava Hazard Zone from Surface V0 | editor | Ajouter `Lave dangereuse` au menu et créer les zones hazard/lava |
| 110 | Lava Hazard Runtime E2E / Closure V0 | gameplay/runtime tests | Prouver surface lava -> generated hazard -> effet runtime |
| 111 | Ice / Mud Movement Semantics Decision V0 | décision | Trancher movement/special/futur modèle |
| 112 | Surface Gameplay Bridge Diagnostics / Preview Map V0 | UX | Preview graphique coverage/overlap |

## 19. Tests relancés

Commandes :

```text
cd packages/map_editor && flutter test test/surface_painter/surface_to_gameplay_zone_action_test.dart --no-pub --reporter expanded
cd packages/map_gameplay && dart test test/surface_generated_gameplay_zone_bridge_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/movement_mode_water_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/surf_evaluation_test.dart --reporter expanded
cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_plan_test.dart --reporter expanded
cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_assessment_test.dart --reporter expanded
cd packages/map_core && dart test test/standard_lava_path_preset_vertical_atlas_builder_test.dart --reporter expanded
```

Le test `standard_lava_path_preset_vertical_atlas_builder_test.dart` a été relancé comme test lava existant, mais il couvre le legacy path lava visuel, pas le hazard overworld.

## 20. Résultats

```text
map_editor behavior menu bridge: 00:01 +17: All tests passed!
map_gameplay surface bridge E2E: 00:00 +3: All tests passed!
map_gameplay movement_mode_water: 00:00 +6: All tests passed!
map_gameplay surf_evaluation: 00:00 +12: All tests passed!
map_core generation_plan hazard payload included: 00:00 +16: All tests passed!
map_core generation_assessment: 00:00 +12: All tests passed!
map_core legacy standard lava path preset: 00:00 +28: All tests passed!
```

## 21. Analyse lancée

Aucune analyse Dart ciblée lancée.

Justification : aucun fichier Dart n'a été modifié dans le Lot 107.

## 22. Résultats analyze

Sans objet pour ce lot documentaire.

## 23. Fichiers créés

- `reports/surface/surface_engine_lot_107_lava_hazard_from_surface_workflow_decision.md`

## 24. Fichiers modifiés

Aucun fichier existant modifié.

## 25. Fichiers supprimés

Aucun fichier supprimé.

## 26. Contenu complet des fichiers créés

Le seul fichier créé par le Lot 107 est le présent rapport :

```text
reports/surface/surface_engine_lot_107_lava_hazard_from_surface_workflow_decision.md
```

Conformément à l'exception explicite du prompt, ce rapport ne se recopie pas récursivement dans lui-même.

## 27. Contenu complet des fichiers modifiés

Aucun fichier existant modifié.

## 28. Git status final

Commande :

```text
git status --short --untracked-files=all
git diff --stat
```

Sortie :

```text
?? reports/surface/surface_engine_lot_107_lava_hazard_from_surface_workflow_decision.md
```

`git diff --stat` ne produit aucune ligne parce que le seul changement Lot 107 est un fichier non suivi.

## 29. Périmètre explicitement non touché

Confirmé :

- `MapData` modèle non modifié ;
- `MapGameplayZone` modèle non modifié ;
- `HazardZonePayload` non modifié ;
- `HazardKind` non modifié ;
- `SurfaceLayer` non modifié ;
- `SurfaceCellPlacement` non modifié ;
- `ProjectManifest` non modifié ;
- `surface.dart` non modifié ;
- `surface_catalog.dart` non modifié ;
- `map_layer.dart` non modifié ;
- `map_gameplay_zone_payloads.dart` non modifié ;
- `map_editor` production non modifié ;
- `map_runtime` production non modifié ;
- `map_gameplay` production non modifié ;
- `map_battle` non modifié ;
- aucun JSON ;
- aucun generated/build_runner ;
- aucun gameplay hazard codé ;
- aucune collision Surface codée ;
- aucune migration legacy ;
- aucun filtre `surfacePresetId` dans `MapGameplayZone` ;
- aucun lava/ice/mud codé ;
- aucune nouvelle action UI codée.

## 30. ctx stats

Commande demandée :

```text
ctx stats
```

Résultat shell :

```text
zsh:1: command not found: ctx
```

Le binaire `ctx` n'est pas disponible dans le shell. Les outils MCP Context Mode sont disponibles et ont été utilisés. Diagnostic MCP :

```text
context-mode doctor
- Runtimes: 7/11 (64%) — javascript, shell, python, ruby, rust, php, perl
- Performance: NORMAL — install Bun for 3-5x speed boost
- Server test: PASS
- FTS5 / SQLite: PASS — native module works
- Hook script: PASS — /opt/homebrew/lib/node_modules/context-mode/hooks/pretooluse.mjs
- Version: v1.0.100
```

Stats compactes observées :

```text
Gate 0: sortie capturée via Context Mode.
Audit Lot 107: 7 commandes, 3282 lignes, 400.7KB indexés, 13 sections indexées, 5 requêtes.
Tests Lot 107: 7 commandes de test capturées avec lignes finales exactes.
```

## 31. Limites restantes

- Les hazards overworld sont modélisés mais pas consommés.
- Pas de résultat gameplay hazard.
- Pas de mutation HP/party/GameState.
- Pas de feedback runtime hazard.
- Pas de test E2E lava gameplay.
- Pas de dialog editor lava.
- Pas de validation automatique qu'un preset Surface est bien lava.
- Pas de migration legacy lava vers SurfaceLayer + hazard.

## 32. Auto-critique

- Est-ce que `HazardZonePayload` a été audité ? Oui.
- Est-ce que `HazardKind.lava` existe ? Oui.
- Est-ce que `damagePerStep` est compris ? Oui.
- Est-ce que la consommation gameplay des hazards a été auditée ? Oui.
- Est-ce que `PlayableMapGame`/runtime hazard a été audité ? Oui.
- Est-ce que le workflow Lot 106 peut accueillir lava ? Oui.
- Est-ce que le payload lava V0 est décidé ? Oui.
- Est-ce que `damagePerStep` est obligatoire ou par défaut ? Oui : défaut UX explicite `5`, confirmation future bloquée si `<= 0`.
- Est-ce que les zones lava doivent couvrir les cellules lava elles-mêmes ? Oui.
- Est-ce que l'UX future est claire ? Oui.
- Est-ce que les diagnostics UX futurs sont listés ? Oui.
- Est-ce que le prochain lot peut coder lava editor ? Non. Il faut d'abord un lot de consommation runtime/gameplay hazard.
- Est-ce qu'aucun code de production n'a été modifié ? Oui.
- Est-ce que les tests pertinents ont été relancés ? Oui.
- Est-ce que Context Mode a été utilisé agressivement ? Oui.
- Est-ce que ctx stats est inclus ? Oui, avec mention explicite que le binaire shell est absent et que les stats disponibles viennent des outils MCP Context Mode.
- Est-ce que le contenu complet des fichiers créés/modifiés est copié dans le rapport ? Oui pour les fichiers modifiés ; exception anti-récursion appliquée au seul fichier créé.
- Est-ce qu'un Lot 107-bis est nécessaire ? Non. La décision est claire : modèle prêt, runtime pas prêt, prochain lot runtime prep.

## 33. Regard critique sur le prompt

Le prompt force la bonne décision : ne pas confondre payload existant et comportement runtime réel. C'est exactement le piège du lot lava : le modèle donne l'impression que tout est prêt, mais l'audit montre que `damagePerStep` n'a pas encore de consommateur overworld.

La contrainte de ne pas coder est utile. Sans elle, il aurait été tentant d'ajouter `Lave dangereuse` au menu Lot 106 et de créer des zones hazard qui ne font rien côté gameplay.
