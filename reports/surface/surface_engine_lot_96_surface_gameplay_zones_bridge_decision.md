# Lot 96 — Surface ↔ Gameplay Zones Bridge Decision V0

## 1. Résumé exécutif honnête

Le Lot 96 remplace le plan précédent `ProjectSurfaceGameplayCatalog`.

Décision : **ne pas créer de nouveau catalogue gameplay Surface en V0**. Le projet possède déjà `MapGameplayZone`, avec des payloads typés `EncounterZonePayload`, `MovementZonePayload`, `HazardZonePayload`, `SpecialZonePayload`. Cette couche doit rester la source gameplay principale.

Les `SurfaceLayer` restent strictement visuels. Le bon chemin est un bridge d'authoring : aider l'utilisateur à créer ou mettre à jour des `MapGameplayZone` à partir des surfaces peintes, sans fusionner visuel et gameplay.

Décision finale :

- Ne pas créer `ProjectSurfaceGameplayCatalog`.
- Ne pas créer `SurfaceGameplayRule`.
- Ne pas créer `SurfaceGameplayBehavior`.
- Réutiliser `MapGameplayZone`.
- Garder `SurfaceLayer` visuel.
- Court terme : zones gameplay indépendantes + workflow "créer depuis surface".
- Moyen terme : génération one-shot / mise à jour manuelle depuis SurfaceLayer.
- Long terme : étudier un filtre optionnel `surfacePresetId` sur `MapGameplayZone`, mais pas en V0.

## 2. Périmètre

Inclus :

- audit des zones gameplay existantes ;
- audit éditeur ;
- audit runtime/gameplay ;
- audit surfaces visuelles ;
- comparaison des options de bridge ;
- stratégie tall grass / surf / lava / ice / mud ;
- décision synchronisation ;
- roadmap corrigée.

Exclus :

- aucun code de production ;
- aucun modèle Dart ;
- aucun codec JSON ;
- aucune modification `ProjectManifest` ;
- aucune migration ;
- aucun gameplay surf/tallGrass codé ;
- aucune modification renderer ;
- aucune modification Surface Studio / Surface Painter.

## 3. Gate 0 — status initial

Commandes exécutées :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
```

Résultat :

```text
/Users/karim/Project/pokemonProject
main
```

`git status --short --untracked-files=all` initial :

```text
```

`git diff --stat` initial :

```text
```

`git log --oneline -n 10` initial :

```text
a4d62f39 lot 94/95: Surface Gameplay
83654389 feat: add surface runtime test files and golden slice reports
1f900e67 feat(map_runtime): render surface layers
da2b244d feat(map_runtime): add surface runtime resolver
32fbb0b5 feat(map_editor): improve surface mapping editor
d5561df7 feat(map_editor): edit surface role animation mapping
935a0036 feat(map_editor): animate surface editor previews
fe03b827 feat(map_editor): render surface atlas tile previews
5814f6e9 feat(map): add surface role resolver preview
f8859a06 feat(map_editor): improve surface painter and studio workflow ux
```

Changements préexistants : aucun.

## 4. Context Mode usage

Context Mode utilisé :

- `ctx_index` sur les fichiers clés de zones gameplay, surfaces et runtime ;
- `tool_search` pour ré-exposer les outils Context Mode après compactage ;
- `ctx_stats` en fin de lot ;
- sorties shell gardées compactes.

Limite : le binaire shell `ctx` n'est pas disponible dans le `PATH` (`ctx: command not found`). Les outils MCP Context Mode sont disponibles après découverte via `tool_search`. Les fichiers volumineux ont été indexés et les commandes shell ont été limitées à des extraits/agrégats.

Fichiers indexés :

- `map_gameplay_zone_payloads.dart`
- `map_data.dart`
- `map_gameplay_zones.dart`
- `gameplay_zone_editing_service.dart`
- `gameplay_zone_use_cases.dart`
- `gameplay_zone_properties_panel.dart`
- `gameplay_encounter.dart`
- `gameplay_step.dart`
- `surf_evaluation.dart`
- `gameplay_world_state.dart`
- `playable_map_game.dart`
- `map_layer.dart`
- `surface_layer_placements.dart`

## 5. Audit MapGameplayZone / payloads

Commandes :

```bash
rg -n "MapGameplayZone|GameplayZoneKind|EncounterZonePayload|MovementZonePayload|HazardZonePayload|SpecialZonePayload|EncounterKind|MovementMode|HazardKind|FieldAbility" packages/map_core/lib packages/map_core/test
```

Résumé :

- `MapData` contient `gameplayZones: List<MapGameplayZone>`.
- `MapGameplayZone` contient `id`, `name`, `kind`, `area`, `priority`, et payloads optionnels.
- `area` est un `MapRect` rectangulaire.
- `priority` résout les superpositions ; plus haut = prioritaire.
- `findGameplayZoneAtPos` retourne la zone couvrant la position, avec priorité.
- `findAllGameplayZonesAtPos` retourne toutes les zones couvrantes triées.
- mutations existantes : add/update/remove.
- validations existantes : id, duplication, area, payload attendu selon kind, background encounter.

Kinds disponibles :

- `encounter`
- `movement`
- `hazard`
- `special`
- `custom` fallback, à éviter dans du nouveau code.

Payloads disponibles :

- `EncounterZonePayload`: `encounterTableId`, `encounterKind`, `battleBackgroundRelativePath`.
- `MovementZonePayload`: `requiredMode`, `allowedModes`.
- `HazardZonePayload`: `hazardKind`, `damagePerStep`.
- `SpecialZonePayload`: `scriptKey`, `properties`.

Enums utiles :

- `MovementMode.walk/surf/fly/cut/strength/rockSmash`.
- `HazardKind.lava/poison/swamp/pitfall/other`.
- `EncounterKind.walk/surf/headbutt/oldRod/goodRod/superRod`.
- `FieldAbility.surf/cut/strength/flash/rockSmash/waterfall/dive`.

## 6. Audit éditeur gameplay zones

Commandes :

```bash
rg -n "GameplayZone|gameplay zone|gameplay_zone|addGameplayZone|updateGameplayZone|selectGameplayZone|placeOrSelectGameplayZoneAt|GameplayZoneEditing" packages/map_editor/lib packages/map_editor/test
```

Fichiers lus/indexés :

- `gameplay_zone_editing_service.dart`
- `gameplay_zone_editing_coordinator.dart`
- `gameplay_zone_use_cases.dart`
- `gameplay_zone_properties_panel.dart`

Résumé :

- L'éditeur sait créer une zone depuis une cellule ou un rectangle.
- La zone par défaut est `GameplayZoneKind.encounter`.
- Les use cases appellent les opérations `map_core`.
- Le panel expose les champs de base : id, nom, kind, priorité.
- Il expose les payloads encounter/movement/hazard/special.
- Encounter permet table, kind et background de battle.
- Movement expose `requiredMode`.
- Hazard expose `hazardKind` et `damagePerStep`.
- Special expose `scriptKey`.

Limites UX actuelles :

- workflow encore orienté zone dessinée, pas surface peinte ;
- pas d'action "créer zone depuis surface" ;
- pas de visualisation des SurfaceLayer dans l'éditeur de zone ;
- pas de sync ou diagnostics Surface ↔ GameplayZone.

Point de branchement naturel :

- ajouter plus tard une action editor "Créer une zone gameplay depuis cette surface" qui produit des `MapGameplayZone` existantes.

## 7. Audit runtime gameplay / encounters / surf

Commandes :

```bash
rg -n "checkEncounterAtPlayerPosition|GameplayEncounter|EncounterZone|surf|Surf|MovementMode|HazardKind|gameplayZones|GameplayStep|step|movement|passable|canEnter|currentSurface" packages/map_gameplay/lib packages/map_runtime/lib packages/map_core/lib
```

Findings :

- `checkEncounterAtPlayerPosition` résout une zone `GameplayZoneKind.encounter` couvrant la position joueur.
- Il filtre par `EncounterKind`.
- Il lit `encounterTableId`, valide la table, lance le roll, puis produit `GameplayEncounter`.
- `PlayableMapGame` choisit `EncounterKind.surf` si le joueur est en `MovementMode.surf`, sinon `walk`.
- `evaluateSurfAttempt` existe déjà et vérifie : cible eau, déjà surf, Pokémon capable, ability débloquée.
- `GameplayWorldState` construit un cache des cellules eau à partir d'anciens path presets water et des `MapGameplayZone.movement` qui autorisent/requièrent surf.
- `MovementZonePayload(requiredMode: surf)` est déjà un mécanisme naturel pour eau surfable.
- Hazards sont modélisés mais l'audit ne prouve pas une consommation gameplay complète comparable aux encounters/surf.

Ce qui manque pour relier SurfaceLayer au gameplay :

- une requête "quelles cellules Surface ont tel `surfacePresetId` ?";
- un workflow editor pour générer zone(s) depuis SurfaceLayer ;
- une décision sur formes irrégulières ;
- diagnostics sur désynchronisation surface/zone ;
- éventuellement, plus tard, un filtre `surfacePresetId` sur `MapGameplayZone`.

## 8. Audit SurfaceLayer / Surface Painter / Surface runtime

Commandes :

```bash
rg -n "SurfaceLayer|SurfaceCellPlacement|surfacePresetId|ProjectSurfacePreset|SurfacePainter|surface_painter|SurfaceRuntime" packages/map_core/lib packages/map_editor/lib packages/map_runtime/lib packages/map_runtime/test packages/map_editor/test
```

Findings :

- `SurfaceCellPlacement` contient uniquement `x`, `y`, `surfacePresetId`.
- `SurfaceLayer` stocke des placements sparse.
- `surface_layer_placements.dart` documente que les placements gardent seulement `x/y/surfacePresetId`; le rôle autotile est recalculé.
- Surface Painter crée/sélectionne une `SurfaceLayer` et peint des placements.
- Runtime Surface résout les instructions et rend les tiles animées.
- Aucun champ gameplay n'existe dans `SurfaceLayer` ou `SurfaceCellPlacement`.

Conclusion :

`SurfaceLayer` est proprement visuel. Il ne faut pas y ajouter `behaviorId`.

## 9. Problème réel à résoudre

Le problème n'est plus "créer une couche gameplay Surface".

Le problème réel :

```text
Comment faire coopérer SurfaceLayer visuel et MapGameplayZone gameplay
sans double système et sans polluer le modèle visuel ?
```

## 10. Options comparées

### Option A — Indépendance totale

L'utilisateur peint les surfaces, puis dessine des `MapGameplayZone`.

Avantages :

- modèle existant ;
- aucune migration ;
- aucun JSON nouveau ;
- runtime déjà partiellement compatible.

Inconvénients :

- double saisie ;
- UX moins no-code ;
- risque de désynchronisation.

Verdict : acceptable court terme, mais UX insuffisante seule.

### Option B — Génération de zones depuis SurfaceLayer

L'utilisateur peint une surface puis génère une ou plusieurs `MapGameplayZone`.

Avantages :

- réutilise `MapGameplayZone` ;
- garde `SurfaceLayer` visuel ;
- UX claire ;
- pas de nouveau modèle gameplay.

Inconvénients :

- `SurfaceLayer` sparse ;
- `MapGameplayZone` rectangulaire ;
- formes irrégulières difficiles ;
- sync future complexe.

Verdict : recommandé V0/V1 sous forme one-shot ou mise à jour manuelle.

### Option C — `MapGameplayZone` avec filtre optionnel `surfacePresetId`

Une zone reste rectangulaire mais ne s'applique qu'aux cellules ayant tel preset.

Avantages :

- combine zone et surface ;
- évite explosion de rectangles ;
- bon contrôle no-code.

Inconvénients :

- modifie modèle + JSON ;
- diagnostics nécessaires ;
- migration nécessaire ;
- doit être conçu proprement.

Verdict : piste long terme, pas V0.

### Option D — `SurfaceLayer` porte un behaviorId

Avantages :

- simple en apparence.

Inconvénients :

- pollue le visuel ;
- duplique `MapGameplayZone` ;
- mélange renderer et gameplay ;
- rend les zones existantes concurrentes.

Verdict : rejeté.

## 11. Décision retenue

Décision Lot 96 :

- Ne pas créer `ProjectSurfaceGameplayCatalog`.
- Ne pas créer `SurfaceGameplayRule`.
- Ne pas créer `SurfaceGameplayBehavior`.
- Réutiliser `MapGameplayZone` comme source gameplay principale.
- Garder `SurfaceLayer` strictement visuel.
- Concevoir un bridge d'authoring Surface → GameplayZone.
- V0 : zones indépendantes + workflow "créer depuis surface".
- V1 : génération one-shot / mise à jour manuelle.
- Plus tard : étudier filtre optionnel `surfacePresetId` dans `MapGameplayZone`.
- Pas de synchronisation live.

## 12. Tall grass strategy

Court terme :

- utiliser `MapGameplayZone(kind: encounter)`;
- payload `EncounterZonePayload(encounterKind: walk, encounterTableId: ...)`;
- l'utilisateur dessine la zone ou la génère depuis une surface `tall_grass`.

Moyen terme :

- action editor "Créer zone de rencontres depuis surface tall_grass";
- preview des cellules couvertes ;
- diagnostic si surface peinte mais aucune zone encounter.

Long terme :

- filtre `surfacePresetId` si les zones rectangulaires couvrent trop large.

## 13. Surfable water strategy

Court terme :

- utiliser `MapGameplayZone(kind: movement)`;
- payload `MovementZonePayload(requiredMode: MovementMode.surf)` ou allowed modes incluant surf.

Pourquoi :

- `GameplayWorldState` sait déjà intégrer les zones movement qui exigent/autorisent surf dans le cache eau.
- `evaluateSurfAttempt` existe déjà.
- `PlayableMapGame` sait dialoguer autour de Surf.

Moyen terme :

- workflow "Créer zone Surf depuis surface water";
- génération de rectangles ou zones couvrantes ;
- diagnostics sur trous/overlaps.

À ne pas faire :

- mettre `isSurfable` dans `ProjectSurfacePreset`;
- rendre le renderer responsable du surf.

## 14. Lava / ice / mud strategy

Lava :

- utiliser `MapGameplayZone(kind: hazard)`;
- `HazardZonePayload(hazardKind: lava, damagePerStep: X)`;
- consommation gameplay complète à vérifier dans un futur lot.

Ice :

- probablement `GameplayZoneKind.movement` ou `special`;
- les enums indiquent "glace" dans les commentaires de movement, mais aucun `slideMode` dédié n'a été observé ;
- future extension nécessaire pour glissade réelle.

Mud :

- `HazardKind.swamp` existe et peut représenter marais/enlisement ;
- ralentissement précis non confirmé dans runtime ;
- futur champ movement modifier possible, mais pas maintenant.

## 15. Synchronisation SurfaceLayer ↔ GameplayZone

Options :

- pas de synchronisation ;
- génération one-shot ;
- mise à jour manuelle depuis surface ;
- synchronisation live.

Verdict :

```text
V0 : génération one-shot ou mise à jour manuelle.
Pas de synchronisation live.
```

Pourquoi :

- live sync peut écraser une zone modifiée à la main ;
- risque undo/redo ;
- formes sparse vs rectangles ;
- génération doit rester explicite et prévisualisée.

## 16. UX no-code recommandée

Workflow futur :

1. L'utilisateur peint une surface.
2. Il sélectionne une action "Créer une zone gameplay depuis cette surface".
3. Il choisit : rencontre, surf, danger, mouvement, spécial.
4. L'éditeur montre une preview des cellules/rectangles qui seront créés.
5. L'utilisateur confirme.
6. Des `MapGameplayZone` existantes sont créées.
7. L'utilisateur peut les éditer dans le panel gameplay zone actuel.

Libellés :

- "Herbe haute avec rencontres"
- "Eau surfable"
- "Lave dangereuse"
- "Glace glissante"
- "Boue ralentissante"

Ne pas exposer :

- `SurfaceRuntimeRenderInstruction`
- `SurfaceVariantRole`
- `MapGameplayZone.kind` comme concept principal utilisateur
- JSON

## 17. Risques et anti-patterns

Risques :

- explosion de rectangles pour surfaces irrégulières ;
- zone générée puis surface modifiée ;
- zone manuelle écrasée par régénération ;
- confusion entre zone gameplay et surface visuelle ;
- future migration legacy water/tallGrass.

Anti-patterns :

- créer un catalogue gameplay Surface parallèle ;
- ajouter `behaviorId` dans `SurfaceCellPlacement`;
- ajouter `isSurfable` dans `ProjectSurfacePreset`;
- sync live implicite ;
- faire dépendre `map_gameplay` du renderer Surface.

## 18. Roadmap post Lot 96

Roadmap corrigée :

| Lot | Sujet |
| --- | --- |
| Lot 97 | Surface → GameplayZone Authoring Workflow Spec V1 |
| Lot 98 | Surface to Gameplay Zone Generation Model V0 |
| Lot 99 | Surface to Gameplay Zone Generation Preview / Diagnostics V0 |
| Lot 100 | Editor Generate Gameplay Zone from Surface V0 |
| Lot 101 | Tall Grass from Surface Workflow V0 |
| Lot 102 | Surfable Water from Surface Workflow V0 |
| Lot 103 | Runtime Surface-position Query Helper V0 |
| Lot 104 | GameplayZone surfacePresetId Filter Decision / Model V0 |

Prochain lot recommandé :

```text
Lot 97 — Surface → GameplayZone Authoring Workflow Spec V1
```

Raison : préciser l'UX et la génération avant de coder des modèles ou opérations.

## 19. Tests relancés

Commandes :

```bash
cd packages/map_core && dart test test/map_gameplay_zone_validation_test.dart
cd packages/map_gameplay && dart test
cd packages/map_gameplay && dart test test/surf_evaluation_test.dart test/script_system_integration_test.dart
cd packages/map_runtime && flutter test test/surface
```

Analyse Dart ciblée :

```text
Aucune analyse Dart ciblée nécessaire : aucun fichier Dart modifié.
```

## 20. Résultats

`map_core` zone validation :

```text
00:00 +1: All tests passed!
```

`map_gameplay && dart test` :

```text
FAILED — dette existante hors Lot 96.
Erreur principale : plusieurs tests construisent ProjectManifest sans surfaceCatalog requis.
Exemples : runtime_movement_collision_regression_test.dart, movement_mode_water_test.dart, placed_elements_collision_test.dart, placed_element_behaviors_test.dart, multi_behavior_resolution_test.dart, path_animation_triggers_test.dart.
Fin : 00:00 +51 -6: Some tests failed.
```

Tests ciblés gameplay/surf/flags :

```text
dart test test/surf_evaluation_test.dart test/script_system_integration_test.dart
00:00 +31: All tests passed!
```

Runtime Surface :

```text
flutter test test/surface
00:04 +29: All tests passed!
```

## 21. Fichiers créés

- `reports/surface/surface_engine_lot_96_surface_gameplay_zones_bridge_decision.md`

## 22. Fichiers modifiés

Aucun fichier existant modifié.

## 23. Fichiers supprimés

Aucun.

## 24. Git status final

Commandes de gate final :

```bash
git status --short --untracked-files=all
git diff --stat
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
git diff --check
```

`git status --short --untracked-files=all` final :

```text
?? reports/surface/surface_engine_lot_96_surface_gameplay_zones_bridge_decision.md
```

`git diff --stat` final :

```text
```

Note : `git diff --stat` est vide parce que le seul changement du lot est un nouveau rapport non tracké.

Recherche fichiers temporaires :

```text
```

`git diff --check` :

```text
```

Changements préexistants : aucun.

Changements du Lot 96 : création du rapport Markdown.

## 25. Périmètre explicitement non touché

Confirmé :

- `map_core` non modifié ;
- `map_editor` non modifié ;
- `map_runtime` production non modifié ;
- `map_gameplay` non modifié ;
- `map_battle` non modifié ;
- `ProjectManifest` non modifié ;
- `surface.dart` non modifié ;
- `surface_catalog.dart` non modifié ;
- `map_layer.dart` non modifié ;
- `map_gameplay_zone_payloads.dart` non modifié ;
- aucun JSON ;
- aucun generated/build_runner ;
- aucune migration legacy ;
- aucun gameplay surf codé ;
- aucun tall grass encounter codé ;
- aucune collision Surface codée ;
- aucun Surface Studio ;
- aucun Surface Painter.

## 26. ctx stats

Commande demandée :

```bash
ctx stats
```

Résultat shell :

```text
zsh:1: command not found: ctx
```

Fallback MCP Context Mode utilisé : `ctx_stats`.

Résumé compact :

```text
175.9K tokens saved
98.9% reduction
694.7 KB without context-mode
7.8 KB with context-mode
686.9 KB kept out of conversation
29 calls
v1.0.100
Update available: v1.0.100 -> v1.0.103
```

Répartition :

```text
ctx_index   20 calls  326.9 KB saved
ctx_stats    4 calls  203.2 KB saved
ctx_doctor   3 calls   97.2 KB saved
ctx_upgrade  1 call    44.2 KB saved
ctx_execute  1 call     8.8 KB saved
```

## 27. Limites restantes

- Les formes sparse Surface vers rectangles GameplayZone doivent être spécifiées.
- `map_gameplay` global est rouge sur dette préexistante `surfaceCatalog`.
- Hazards/movement avancés existent en payload, mais consommation runtime complète non garantie.
- Aucun modèle de filtre `surfacePresetId` décidé pour V0.
- Pas de preview/génération codée.

## 28. Auto-critique

La décision est plus saine que le Lot 95 initial : elle évite un système parallèle. Mais elle révèle une dette : la génération Surface → zones rectangulaires peut être non triviale pour les formes organiques. Il faudra une spec UX avant code.

La suite doit résister à la tentation de modifier `MapGameplayZone` tout de suite. Le bon prochain pas est un workflow spec, pas un modèle.

## 29. Regard critique sur le prompt

Le prompt corrige utilement la trajectoire. Il force l'audit avant modèle et empêche de créer une couche concurrente. C'est exactement le bon réflexe après découverte d'un système existant.

Seul point délicat : il demande `map_gameplay && dart test`, mais la suite globale est actuellement cassée par une dette hors lot. Le rapport documente l'échec et ajoute une vérification ciblée verte.

## Evidence Pack

Status initial : section 3.

Commandes d'audit : sections 5 à 8.

Findings importants : sections 5 à 18.

Tests relancés : sections 19 et 20.

Contenu du rapport créé : non recopié récursivement.

## Auto-review obligatoire

- Est-ce que MapGameplayZone existant a été audité ? Oui.
- Est-ce que le précédent plan ProjectSurfaceGameplayCatalog est abandonné ? Oui.
- Est-ce que SurfaceLayer reste strictement visuel ? Oui.
- Est-ce que MapGameplayZone reste source gameplay principale ? Oui.
- Est-ce que les options de bridge ont été comparées ? Oui.
- Est-ce que tallGrass a une stratégie claire ? Oui.
- Est-ce que surfable water a une stratégie claire ? Oui.
- Est-ce que lava/ice/mud sont cadrés ? Oui.
- Est-ce que la synchronisation SurfaceLayer ↔ GameplayZone est décidée ? Oui.
- Est-ce que la roadmap post Lot 96 est corrigée ? Oui.
- Est-ce que les tests pertinents ont été relancés ? Oui.
- Est-ce que Context Mode a été utilisé agressivement ? Partiellement oui : outils exposés utilisés, `ctx_batch_execute/ctx_search` indisponibles dans cette session.
- Est-ce que ctx stats est inclus ? Oui, via MCP Context Mode ; le binaire shell `ctx` est absent du `PATH`.
- Est-ce qu’un Lot 96-bis est nécessaire ? Non. Le prochain lot recommandé est Lot 97, spec workflow Surface → GameplayZone.
