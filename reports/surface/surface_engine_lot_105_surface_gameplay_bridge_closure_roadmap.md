# Lot 105 — Surface Gameplay Bridge Closure / Roadmap V1

## 1. Résumé exécutif honnête

Le bridge `SurfaceLayer` -> `MapGameplayZone` V0 est fermé pour le périmètre explicitement livré :

- `Surface tall_grass` peinte -> `MapGameplayZone(kind: encounter)` avec `EncounterKind.walk` ;
- `Surface water` peinte -> `MapGameplayZone(kind: movement)` avec `MovementZonePayload(requiredMode: MovementMode.surf)` ;
- génération pure sans mutation de map ;
- assessment produit `ready` / `needsReview` / `blocked` ;
- application batch côté éditeur ;
- preuve gameplay E2E côté `map_gameplay`.

La fermeture est une fermeture de bridge V0, pas une fermeture du Surface Gameplay complet. Lava, ice, mud, encounters surf, preview graphique, migration legacy, synchronisation live, filtre `surfacePresetId` dans `MapGameplayZone`, et smoke `PlayableMapGame` plus haut niveau restent hors périmètre.

Décision produit recommandée : le prochain lot doit être `Lot 106 — Surface Behavior Action Menu V0`, pour regrouper les actions Surface sous une entrée no-code unique avant d'ajouter lava/ice/mud.

## 2. Périmètre

Inclus :

- audit des rapports Lots 96 à 104 ;
- audit des briques code/tests existantes du bridge ;
- synthèse des garanties obtenues ;
- synthèse des limites restantes ;
- décision de clôture V0 ;
- comparaison des options de suite ;
- roadmap post Lot 105 ;
- relance des tests de clôture.

Exclus :

- aucun code de production ;
- aucun test Dart ajouté ou modifié ;
- aucune nouvelle action UI ;
- aucune modification modèle/payload/runtime/editor.

## 3. Gate 0 — status initial

Commande exécutée avant toute modification :

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
2305f276 lot 104: Surface Gameplay Bridge Runtime E2E Closure
8b5c3728 lot 103: Editor Generate Surfable Water Gameplay Zone from Surface
6a3db8e3 lot 101: Tall Grass Surface Workflow Hardening - Batch Apply
b224b0f6 fix: resolve RenderFlex overflow errors in layers and surface panels
888f1339 fix: resolve RenderFlex overflow errors in layers and surface panels
58ab7070 lot 100/95: Editor Generate Gameplay Zone from Surface
15fa925c lot 99/95: Surface Gameplay - Surface to Gameplay Zone Coverage Diagnostics
70b0f90d lot 98/95: Surface Gameplay - Surface to Gameplay Zone Generation Plan
8d62718f lot 97/95: Surface Gameplay - Surface to Gameplay Zone Authoring Workflow Spec
ac7984f2 lot 96/95: Surface Gameplay - Zones Bridge Decision Report

## find . -name AGENTS.md -print
./AGENTS.md
```

Changements préexistants : aucun.

## 4. Context Mode usage

Context Mode a été utilisé pour :

- Gate 0 ;
- audit `rg` des rapports Lots 96 à 104 ;
- audit code bridge `map_core` / `map_editor` / `map_gameplay` ;
- audit des tests de preuve ;
- relance et capture des sorties de tests longues ;
- synthèse des lignes clés sans injecter de gros outputs bruts dans la conversation.

Commandes d'audit principales lancées :

```text
rg -n "Lot 96|Lot 97|Lot 98|Lot 99|Lot 100|Lot 101|Lot 102|Lot 103|Lot 104|Surface Gameplay|GameplayZone|surfable|tall grass|waterRequiresSurf|Rendre cette eau surfable|Créer une zone de rencontre" reports/surface
rg -n "SurfaceGameplayZoneGenerationPlan|SurfaceGameplayZoneBehaviorDraft|createSurfaceGameplayZoneGenerationPlan|assessSurfaceGameplayZoneGenerationPlan|SurfaceGameplayZoneGenerationAssessment|applyGeneratedGameplayZones|applyTallGrassEncounterGameplayZonePlan|applySurfableWaterGameplayZonePlan|buildTallGrassEncounterSurfaceGameplayZonePreview|buildSurfableWaterSurfaceGameplayZonePreview|SurfaceToGameplayZoneDialog|SurfableWaterSurfaceGameplayZoneDialog" packages/map_core/lib packages/map_editor/lib packages/map_gameplay/test packages/map_core/test packages/map_editor/test
rg -n "surface_generated_gameplay_zone_bridge|movement_mode_water|surf_evaluation|surface_to_gameplay_zone_action|surface_to_gameplay_zone_generation_plan|surface_to_gameplay_zone_generation_assessment|waterRequiresSurf|checkEncounterAtPlayerPosition" packages/map_gameplay/test packages/map_editor/test packages/map_core/test
```

## 5. Audit Lots 96–104

Les rapports 96 à 104 sont présents sous `reports/surface/`. La chaîne auditée montre une progression cohérente :

- Lot 96 prend la décision architecturale : pas de catalogue gameplay parallèle, `MapGameplayZone` reste la source gameplay, `SurfaceLayer` reste visuel.
- Lot 97 transforme cette décision en UX no-code : choisir une surface, choisir un comportement, paramétrer, prévisualiser, confirmer.
- Lot 98 crée la brique pure de génération : source sparse -> rectangles -> `MapGameplayZone` candidates.
- Lot 99 ajoute la couche produit autour du plan : assessment, seuils, messages utilisateur.
- Lot 100 branche le premier cas éditeur : tall grass -> encounter/walk.
- Lot 101 durcit l'application avec un batch apply.
- Lot 102 décide surf sans coder : payload V0 `requiredMode: surf`, zones sur cellules water.
- Lot 103 branche water -> movement/surf côté éditeur.
- Lot 104 ferme par tests E2E gameplay : surface seule visuelle, zones générées consommées.

Findings importants :

- La trajectoire a évité `ProjectSurfaceGameplayCatalog`, `SurfaceGameplayRule` et `SurfaceGameplayBehavior` persistants.
- Les lots de code ont réutilisé les payloads existants `EncounterZonePayload` et `MovementZonePayload`.
- Le lien `SurfaceLayer` -> gameplay reste un workflow d'authoring, pas une dépendance runtime directe aux surfaces visuelles.
- La dette visible restante est maintenant davantage UX et roadmap que moteur V0.

## 6. Table de synthèse des lots

| Lot | Sujet | Nature | Fichiers principaux | Tests principaux | Garantie obtenue | Limites restantes | Statut |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 96 | Surface Gameplay Zones Bridge Decision | Décision architecture | `reports/surface/surface_engine_lot_96_surface_gameplay_zones_bridge_decision.md` | tests map_core/runtime existants relancés dans le lot | `MapGameplayZone` retenu, `SurfaceLayer` visuel, pas de catalogue gameplay parallèle | Pas de workflow codé | Fermé |
| 97 | Surface -> GameplayZone Authoring Workflow Spec | UX / architecture produit | `reports/surface/surface_engine_lot_97_surface_to_gameplay_zone_authoring_workflow_spec.md` | tests gameplay/surface relancés dans le lot | Assistant no-code spécifié, preview obligatoire, sparse -> rectangles analysé | Pas d'implémentation | Fermé |
| 98 | Generation Plan Model | Code pur map_core | `surface_to_gameplay_zone_generation_plan.dart`, test associé, export `map_core.dart` | `surface_to_gameplay_zone_generation_plan_test.dart`, map_core complet dans le lot | Plans déterministes, `boundingBox`, `greedyRectangles`, coverage, diagnostics, candidates `MapGameplayZone` | Pas d'assessment produit | Fermé |
| 99 | Coverage / Diagnostics Assessment | Code pur map_core | `surface_to_gameplay_zone_generation_assessment.dart`, test associé, export `map_core.dart` | `surface_to_gameplay_zone_generation_assessment_test.dart`, map_core complet dans le lot | `ready` / `needsReview` / `blocked`, messages UX, seuils policy | Pas d'UI | Fermé |
| 100 | Editor tall grass action | Code éditeur | `surface_to_gameplay_zone_*`, `surface_palette_panel.dart`, tests éditeur | `surface_to_gameplay_zone_action_test.dart`, surface_painter, map_core | Tall grass -> `MapGameplayZone encounter/walk` via plan + assessment | Multi-zones appliquées initialement par mutations répétées | Fermé |
| 101 | Tall grass hardening / batch apply | Code éditeur borné | `EditorNotifier.applyGeneratedGameplayZones`, action/tests renforcés | action test, surface_painter, map_selection, map_core | Batch apply, dirty state, sélection, non-mutation partielle | Pas de généralisation UX globale | Fermé |
| 102 | Surfable water decision | Documentation / décision | `surface_engine_lot_102_surfable_water_from_surface_workflow_decision.md` | surf/water, tall grass, map_core relancés | Payload surf V0 tranché : `MovementZonePayload(requiredMode: surf)` sur cellules water | Pas de bouton water codé | Fermé |
| 103 | Editor surfable water action | Code éditeur + fixture test si besoin | `surface_to_gameplay_zone_*`, tests éditeur | action test, surface_painter, surf/water, map_core | Water -> `MapGameplayZone movement/surf`, batch apply, no encounters surf | Pas de runtime modifié, pas de preview graphique | Fermé |
| 104 | Runtime E2E closure | Tests gameplay | `packages/map_gameplay/test/surface_generated_gameplay_zone_bridge_test.dart` | bridge E2E, movement water, surf evaluation, editor bridge, map_core | Preuve gameplay : surface seule visuelle, encounter consommée, water surf consommée | Smoke PlayableMapGame complet reporté | Fermé |

## 7. Audit code bridge Surface → GameplayZone

Briques pures `map_core` :

- `packages/map_core/lib/src/operations/surface_to_gameplay_zone_generation_plan.dart`
  - ligne 7 : `SurfaceGameplayZoneGenerationStrategy` ;
  - ligne 29 : `SurfaceGameplayZoneGenerationSource` ;
  - ligne 76 : `SurfaceGameplayZoneBehaviorDraft` ;
  - ligne 197 : `SurfaceGameplayZoneGenerationPlan` ;
  - ligne 262 : `createSurfaceGameplayZoneGenerationPlan(...)`.
- `packages/map_core/lib/src/operations/surface_to_gameplay_zone_generation_assessment.dart`
  - ligne 4 : `SurfaceGameplayZoneGenerationAssessmentStatus` ;
  - ligne 10 : `SurfaceGameplayZoneGenerationAssessmentPolicy` ;
  - ligne 82 : `SurfaceGameplayZoneGenerationAssessmentMessage` ;
  - ligne 114 : `SurfaceGameplayZoneGenerationAssessment` ;
  - ligne 198 : `assessSurfaceGameplayZoneGenerationPlan(...)`.

Briques éditeur :

- `packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_presenter.dart`
  - ligne 82 : preview tall grass ;
  - ligne 154 : création du plan tall grass ;
  - ligne 159 : `EncounterKind.walk` ;
  - ligne 167 : assessment tall grass ;
  - ligne 183 : preview water ;
  - ligne 244 : création du plan water ;
  - ligne 247 : `MovementZonePayload(requiredMode: MovementMode.surf)` ;
  - ligne 254 : assessment water.
- `packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_dialog.dart`
  - ligne 6 : dialog tall grass ;
  - ligne 146 : dialog water/surf.
- `packages/map_editor/lib/src/features/surface_painter/surface_to_gameplay_zone_action.dart`
  - ligne 5 : `applyTallGrassEncounterGameplayZonePlan(...)` ;
  - ligne 17 : appel à `notifier.applyGeneratedGameplayZones(...)` ;
  - ligne 24 : `applySurfableWaterGameplayZonePlan(...)` ;
  - ligne 36 : appel à `notifier.applyGeneratedGameplayZones(...)` ;
  - ligne 46 : validation `EncounterKind.walk` ;
  - ligne 52 : validation `MovementMode.surf`.
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
  - ligne 3288 : `applyGeneratedGameplayZones(...)`.

Tests E2E gameplay :

- `packages/map_gameplay/test/surface_generated_gameplay_zone_bridge_test.dart`
  - ligne 8 : groupe de test bridge ;
  - ligne 9 : `SurfaceLayer` seule reste visuelle ;
  - ligne 41 : water movement/surf consommé par le mouvement ;
  - ligne 91 : tall grass encounter consommé par les rencontres ;
  - lignes 143 et 156 : les plans viennent de `createSurfaceGameplayZoneGenerationPlan(...)`.

Conclusion code :

- tall grass et water utilisent la même chaîne conceptuelle : source Surface -> plan `greedyRectangles` -> assessment -> candidates `MapGameplayZone` -> batch apply ;
- la duplication volontaire restante dans presenter/dialog/action reste acceptable pour deux comportements seulement ;
- une généralisation prématurée aurait été plus risquée avant de connaître lava/ice/mud ;
- le prochain point naturel de généralisation est l'entrée UX, pas les modèles persistants.

## 8. Audit tests de preuve

Tests couvrant tall grass :

- `packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart`
  - presenter tall grass ;
  - dialog tall grass ;
  - action surface panel ;
  - application EditorNotifier ;
  - rejet des plans non encounter et non walk sans mutation.
- `packages/map_gameplay/test/surface_generated_gameplay_zone_bridge_test.dart`
  - generated tall grass encounter zones are consumed by encounters.

Tests couvrant water/surf :

- `packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart`
  - presenter water/surf ;
  - dialog water/surf ;
  - action surface panel ;
  - application EditorNotifier ;
  - rejet des plans non movement et non surf sans mutation.
- `packages/map_gameplay/test/surface_generated_gameplay_zone_bridge_test.dart`
  - generated water movement surf zones are consumed by movement.
- `packages/map_gameplay/test/movement_mode_water_test.dart`
  - `movement zone requiring surf is treated as water for walking mode`.
- `packages/map_gameplay/test/surf_evaluation_test.dart`
  - conditions Surf existantes.

Tests couvrant SurfaceLayer visuel / non-mutation :

- `surface_generated_gameplay_zone_bridge_test.dart` prouve que `SurfaceLayer` seule ne déclenche pas encounter et ne bloque pas water.
- `surface_to_gameplay_zone_action_test.dart` prouve que les applications editor n'altèrent pas la `SurfaceLayer` dans les cas multi-zone.
- Les tests Lot 98/99 verrouillent les plans/assessments immuables.

Tests manquants :

- pas de smoke `PlayableMapGame` complet croisant interaction Surf et encounter dans une boucle runtime haute ;
- pas de preview graphique de coverage ;
- pas de lava/ice/mud ;
- pas de test de migration legacy ;
- pas de test de filtre futur `surfacePresetId` dans `MapGameplayZone`, car ce filtre n'existe pas en V0.

## 9. Garanties obtenues

Le système garantit maintenant :

- `SurfaceLayer` reste visuel.
- `MapGameplayZone` reste la source gameplay principale.
- `ProjectSurfacePreset` n'est pas pollué par une sémantique gameplay persistante.
- Aucun `ProjectSurfaceGameplayCatalog` parallèle n'existe.
- Une surface `tall_grass` peut générer des zones `encounter`.
- Une surface `water` peut générer des zones `movement/surf`.
- Le plan est généré sans muter la map.
- L'assessment expose `ready`, `needsReview`, `blocked`.
- Le batch apply applique plusieurs zones via le seam éditeur existant.
- Les tests prouvent que `tall_grass` generated déclenche/autorise le flow encounter.
- Les tests prouvent que `water` generated bloque walking avec `waterRequiresSurf`.
- Les tests prouvent que `water` generated autorise le mouvement en `MovementMode.surf`.

## 10. Limites restantes

Limites V0 :

- pas de lava ;
- pas de ice ;
- pas de mud ;
- pas d'encounter surf ;
- pas de preview graphique de couverture ;
- pas de workflow unifié "Créer un comportement depuis cette surface" ;
- pas de filtre `surfacePresetId` dans `MapGameplayZone` ;
- pas de migration legacy `PathSurfaceKind` vers `SurfaceLayer + GameplayZone` ;
- pas de smoke `PlayableMapGame` complet pour les interactions ;
- pas de validation automatique qu'un preset water est réellement de l'eau ;
- pas de synchronisation live `SurfaceLayer` <-> `GameplayZone` après génération.

## 11. Décision : bridge V0 fermé ou non

Décision : oui, le bridge `SurfaceLayer` -> `MapGameplayZone` V0 est fermé pour le périmètre V0.

La fermeture couvre :

- `tall_grass -> encounter/walk` ;
- `water -> movement/surf` ;
- authoring éditeur ;
- génération pure ;
- assessment ;
- batch apply ;
- preuve gameplay E2E.

Décision complémentaire : non, le Surface Gameplay complet n'est pas terminé.

Ce qui reste à faire appartient à la V1 produit ou à des comportements futurs, pas à la fermeture du bridge V0.

## 12. Options de suite comparées

### Option A — UX regroupée avant nouveaux comportements

Créer une entrée unique :

```text
Créer un comportement depuis cette surface
```

Puis proposer :

- Herbe haute avec rencontres ;
- Eau surfable ;
- Lave dangereuse ;
- Glace glissante ;
- Boue / marais.

Avantages :

- évite un bouton par comportement ;
- réduit la surcharge de la palette Surface ;
- prépare lava/ice/mud proprement ;
- correspond à la spec no-code du Lot 97 ;
- garde les modèles actuels intacts.

Inconvénients :

- retarde le prochain comportement visible ;
- demande une petite refonte UI.

### Option B — Ajouter lava directement

Créer le workflow :

```text
Surface lava -> MapGameplayZone hazard/lava
```

Avantages :

- comportement visible rapidement ;
- réutilise le bridge existant ;
- bon test de l'extensibilité du plan.

Inconvénients :

- runtime hazard à auditer/prouver ;
- risque de multiplier les boutons dans la palette ;
- risque de coder une troisième exception UI avant de stabiliser l'entrée no-code.

### Option C — Runtime smoke PlayableMapGame

Tester plus haut :

```text
map avec generated water/tallGrass
PlayableMapGame démarre
interactions surf/encounter smoke
```

Avantages :

- preuve plus proche utilisateur ;
- utile avant polish produit ;
- peut détecter une rupture d'intégration runtime haute.

Inconvénients :

- plus lourd ;
- potentiellement bruité ;
- pas indispensable à la fermeture moteur V0 déjà prouvée côté `map_gameplay`.

## 13. Décision roadmap

Verdict recommandé : `Lot 106 — Surface Behavior Action Menu V0`.

But :

```text
Remplacer / regrouper les actions séparées de la palette Surface
par une entrée unique "Créer un comportement depuis cette surface".
```

Justification :

- Le bridge moteur V0 est fermé.
- Ajouter lava immédiatement créerait probablement une troisième action spécifique.
- La dette utilisateur visible est la multiplication des boutons, pas l'absence immédiate de lava.
- L'entrée unique prépare les cartes comportement du Lot 97.
- Le code peut rester spécifique sous le capot tant que l'UX devient cohérente.

## 14. Roadmap post Lot 105

Roadmap recommandée :

| Lot | Sujet | Statut recommandé | Risque principal |
| --- | --- | --- | --- |
| 106 | Surface Behavior Action Menu V0 | Indispensable | Petite refonte UI à garder bornée |
| 107 | Lava Hazard from Surface Decision / Prep V0 | Indispensable avant code lava | Runtime hazard potentiellement incomplet |
| 108 | Editor Generate Lava Hazard Zone from Surface V0 | Indispensable si Lot 107 valide | Bouton/action doit passer par le menu V0 |
| 109 | Lava Hazard Runtime E2E / Closure V0 | Indispensable après Lot 108 | Prouver damage/hazard sans surcoder |
| 110 | Ice / Mud Movement Semantics Decision V0 | Indispensable avant ice/mud | Modèle movement/special peut être insuffisant |
| 111 | Surface Gameplay Bridge Diagnostics / Preview Map V0 | Utile | Preview graphique peut gonfler l'UI |
| 112 | Legacy Surface Migration Audit V0 | A retarder jusqu'aux comportements stables | Migration large et risquée |
| 113 | Surface Gameplay Bridge Documentation V1 | Utile après UX menu | Documentation produit/dev à maintenir |
| 114 | Surface Studio Visual Mapping Redesign V2 | A retarder | Hors bridge gameplay, scope UX large |

Lots indispensables à court terme : 106, 107, 108, 109, 110.

Lots optionnels mais utiles : 111, 113.

Lots à retarder : 112, 114.

## 15. Tests relancés

Commandes exécutées :

```text
cd packages/map_gameplay && dart test test/surface_generated_gameplay_zone_bridge_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/movement_mode_water_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/surf_evaluation_test.dart --reporter expanded
cd packages/map_editor && flutter test test/surface_painter/surface_to_gameplay_zone_action_test.dart --no-pub --reporter expanded
cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_plan_test.dart --reporter expanded
cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_assessment_test.dart --reporter expanded
cd packages/map_runtime && flutter test test/surface --reporter expanded
```

Le test runtime Surface a été lancé parce que `packages/map_runtime/test/surface` existe et reste raisonnable pour une clôture.

## 16. Résultats

`map_gameplay` bridge E2E :

```text
00:00 +1: surface generated gameplay zone bridge generated water movement surf zones are consumed by movement
00:00 +2: surface generated gameplay zone bridge generated tall grass encounter zones are consumed by encounters
00:00 +3: All tests passed!
```

`map_gameplay` movement mode water :

```text
00:00 +4: movement mode water traversal solid collisions still block movement while surfing
00:00 +5: movement mode water traversal movement zone requiring surf is treated as water for walking mode
00:00 +6: All tests passed!
```

`map_gameplay` surf evaluation :

```text
00:00 +10: partyHasUsableFieldMove returns false when no member knows the move
00:00 +11: partyHasUsableFieldMove returns false for empty party
00:00 +12: All tests passed!
```

`map_editor` bridge actions :

```text
00:00 +14: EditorNotifier surfable water surface generation rejects non-movement plans without mutating the map
00:00 +15: EditorNotifier surfable water surface generation rejects movement plans that do not require surf without mutating
00:00 +16: All tests passed!
```

`map_core` generation plan :

```text
00:00 +14: diagnostics and immutability plan lists are immutable
00:00 +15: diagnostics and immutability coverage and diagnostics support value equality
00:00 +16: All tests passed!
```

`map_core` generation assessment :

```text
00:00 +10: assessment messages and immutability assessment does not mutate the source plan
00:00 +11: assessment messages and immutability assessment messages and assessment support value equality
00:00 +12: All tests passed!
```

`map_runtime` surface :

```text
00:01 +28: /Users/karim/Project/pokemonProject/packages/map_runtime/test/surface/surface_runtime_playable_host_smoke_test.dart: Surface runtime playable host smoke PlayableMapGame starts and ticks with a disk SurfaceLayer project
[runtime] Map loaded: surface-host-test, spawn at (0, 0)
00:01 +29: All tests passed!
```

## 17. Analyse lancée

Aucune analyse Dart ciblée lancée.

Justification : Lot 105 ne modifie aucun fichier Dart, aucun code de production, aucun test, aucun modèle, aucun export.

## 18. Résultats analyze

Sans objet pour ce lot documentaire.

## 19. Fichiers créés

- `reports/surface/surface_engine_lot_105_surface_gameplay_bridge_closure_roadmap.md`

## 20. Fichiers modifiés

Aucun fichier existant modifié.

## 21. Fichiers supprimés

Aucun fichier supprimé.

## 22. Contenu complet des fichiers créés

Le seul fichier créé par le Lot 105 est le présent rapport :

```text
reports/surface/surface_engine_lot_105_surface_gameplay_bridge_closure_roadmap.md
```

Conformément à l'exception explicite du prompt, ce rapport ne se recopie pas récursivement dans lui-même.

## 23. Contenu complet des fichiers modifiés

Aucun fichier existant modifié.

## 24. Git status final

Commande :

```text
git status --short --untracked-files=all
git diff --stat
```

Sortie :

```text
?? reports/surface/surface_engine_lot_105_surface_gameplay_bridge_closure_roadmap.md
```

`git diff --stat` ne produit aucune ligne parce que le seul changement Lot 105 est un fichier non suivi.

## 25. Périmètre explicitement non touché

Confirmé :

- `map_editor` production non modifié ;
- `map_runtime` production non modifié ;
- `map_gameplay` production non modifié ;
- `map_core` production non modifié ;
- `map_battle` non modifié ;
- `MapData` modèle non modifié ;
- `MapGameplayZone` modèle non modifié ;
- `MovementZonePayload` non modifié ;
- `EncounterZonePayload` non modifié ;
- `SurfaceLayer` non modifié ;
- `SurfaceCellPlacement` non modifié ;
- `ProjectManifest` non modifié ;
- `surface.dart` non modifié ;
- `surface_catalog.dart` non modifié ;
- `map_layer.dart` non modifié ;
- `map_gameplay_zone_payloads.dart` non modifié ;
- aucun JSON ;
- aucun generated/build_runner ;
- aucun runtime surf codé ;
- aucun encounter surf codé ;
- aucune collision Surface codée ;
- aucune migration legacy ;
- aucun filtre `surfacePresetId` dans `MapGameplayZone` ;
- aucun lava / ice / mud ;
- aucune nouvelle UI codée.

## 26. ctx stats

Commande demandée :

```text
ctx stats
```

Résultat :

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

Stats compactes disponibles via les retours MCP :

```text
ctx_batch_execute audit: 6 commandes, 1287 lignes, 206.3KB indexés, 8 sections indexées, 5 requêtes de recherche.
ctx_execute tests: sorties longues indexées en 7 sections.
ctx_execute lignes finales tests: sortie compacte directe, 7 commandes de test résumées.
```

## 27. Limites restantes détaillées

1. UX regroupée non codée : la palette Surface a encore des actions spécifiques.
2. Lava non audité en profondeur dans ce bloc : le comportement `hazard/lava` existe conceptuellement mais n'a pas sa preuve runtime V0.
3. Ice/mud non décidés : il faut trancher movement vs special vs futur modèle.
4. Encounters surf non ouverts : water/surf ne crée que du movement.
5. Preview graphique absente : l'utilisateur voit des messages, pas encore une overlay de couverture.
6. Pas de filtre `surfacePresetId` runtime dans `MapGameplayZone`.
7. Pas de synchronisation live : si la surface change après génération, les zones ne se mettent pas à jour automatiquement.
8. Pas de migration legacy : ancien terrain/path water/tallGrass non converti automatiquement.
9. Smoke `PlayableMapGame` complet interactionnel non ajouté : seul `map_runtime/test/surface` existant a été relancé.

## 28. Auto-critique

- Est-ce que les Lots 96–104 sont synthétisés ? Oui.
- Est-ce que les garanties du bridge V0 sont listées ? Oui.
- Est-ce que les limites restantes sont listées honnêtement ? Oui.
- Est-ce que le bridge Surface -> GameplayZone V0 est déclaré fermé ? Oui, pour le périmètre V0.
- Est-ce que tall_grass -> encounter est couvert ? Oui.
- Est-ce que water -> movement/surf est couvert ? Oui.
- Est-ce que SurfaceLayer reste visuel ? Oui.
- Est-ce que MapGameplayZone reste source gameplay principale ? Oui.
- Est-ce que les options de suite sont comparées ? Oui.
- Est-ce que la roadmap post Lot 105 est claire ? Oui.
- Est-ce que le prochain lot recommandé est explicite ? Oui, Lot 106.
- Est-ce qu'aucun code de production n'a été modifié ? Oui.
- Est-ce que les tests de clôture ont été relancés ? Oui.
- Est-ce que Context Mode a été utilisé agressivement ? Oui.
- Est-ce que ctx stats est inclus ? Oui, avec mention explicite que le binaire `ctx` est absent et que les stats disponibles viennent des outils MCP Context Mode.
- Est-ce que le contenu complet des fichiers créés/modifiés est copié dans le rapport ? Oui pour les fichiers modifiés ; pour le seul fichier créé, exception anti-récursion appliquée.
- Est-ce qu'un Lot 105-bis est nécessaire ? Non. Le bridge V0 est clos ; la suite est une roadmap V1, pas une correction de clôture.

## 29. Regard critique sur le prompt

Le prompt est utilement strict : il empêche de coder le Lot 106 en douce, force la distinction V0 fermé vs Surface Gameplay complet, et exige une preuve de non-régression.

Deux tensions restent à noter :

- demander le contenu complet du fichier créé alors que le seul fichier créé est le rapport impose naturellement l'exception anti-récursion ;
- relancer `map_runtime/test/surface` dans un lot documentaire est acceptable ici parce que le dossier existe et reste ciblé, mais ce test ne remplace pas un futur smoke interactionnel complet.

La recommandation Lot 106 est solide : maintenant que le bridge moteur est prouvé, il faut éviter d'empiler les boutons comportement par comportement.
