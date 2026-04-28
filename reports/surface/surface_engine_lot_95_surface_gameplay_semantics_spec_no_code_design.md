# Lot 95 — Surface Gameplay Semantics Spec / No-Code Design V1

## 1. Résumé exécutif honnête

Le Lot 95 spécifie la future couche **Surface Gameplay Semantics** sans coder de feature.

Décision principale : `SurfaceCatalog` reste un système visuel. Les atlas, animations, presets, placements et renderer Surface ne doivent pas porter les règles gameplay. Les comportements comme eau surfable, herbe haute avec rencontres, glace glissante, lave dangereuse, boue ralentissante ou effets de pas doivent vivre dans un futur catalogue séparé, lisible no-code, qui référence les surfaces visuelles par `surfacePresetId`.

Verdict : la prochaine étape recommandée est **Lot 96 — Surface Gameplay Semantics Model V0**, mais seulement après validation de cette spec.

## 2. Périmètre

Inclus :

- audit compact du repo ;
- formalisation Visual Surface vs Gameplay Semantics ;
- comparaison des options de stockage ;
- granularité des règles ;
- modèle conceptuel non codé ;
- UX no-code cible ;
- diagnostics futurs ;
- helpers runtime futurs ;
- roadmap post Lot 95 ;
- relance des tests runtime Surface de clôture.

Exclus :

- aucun code de production ;
- aucun modèle Dart ;
- aucun codec JSON ;
- aucun `ProjectManifest` ;
- aucun gameplay surf ;
- aucun tall grass encounter ;
- aucune collision Surface ;
- aucune modification Surface Studio / Surface Painter ;
- aucune migration legacy.

## 3. Gate 0 — status initial

Commandes exécutées depuis la racine :

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
?? reports/surface/surface_engine_lot_94_pack_runtime_surface_closure_and_gameplay_semantics_decision.md
```

`git diff --stat` initial :

```text
```

`git log --oneline -n 10` initial :

```text
83654389 feat: add surface runtime test files and golden slice reports
1f900e67 feat(map_runtime): render surface layers
da2b244d feat(map_runtime): add surface runtime resolver
32fbb0b5 feat(map_editor): improve surface mapping editor
d5561df7 feat(map_editor): edit surface role animation mapping
935a0036 feat(map_editor): animate surface editor previews
fe03b827 feat(map_editor): render surface atlas tile previews
5814f6e9 feat(map): add surface role resolver preview
f8859a06 feat(map_editor): improve surface painter and studio workflow ux
b20287da feat(map_editor): redesign surface studio workflow
```

Changements préexistants :

- `reports/surface/surface_engine_lot_94_pack_runtime_surface_closure_and_gameplay_semantics_decision.md`

Changements du Lot 95 :

- ce rapport.

## 4. Context Mode usage

Context Mode est disponible partiellement dans cette session :

- `ctx_doctor` fonctionne ;
- `ctx_index` fonctionne ;
- `ctx_stats` fonctionne ;
- `ctx_batch_execute` et `ctx_search` ne sont pas exposés dans les outils disponibles de cette session, même après upgrade shell ; la session devra être redémarrée pour récupérer les nouveaux outils MCP.

Usage effectué :

- index du rapport Lot 89 ;
- index du rapport Lot 90 ;
- index du rapport Lot 91 ;
- index du rapport Lot 92-pack ;
- index du rapport Lot 93-pack ;
- index du rapport Lot 94-pack ;
- `ctx_doctor` pour vérifier FTS5 / SQLite / hook ;
- `ctx_stats` en fin de lot.

Les recherches shell ont été gardées compactes : sorties par counts, listes courtes de fichiers et lignes finales de tests.

## 5. Audit repository findings

Commandes d'audit lancées :

```bash
rg -n "SurfaceLayer|SurfaceCellPlacement|surfacePresetId|ProjectSurfacePreset|ProjectSurfaceCatalog|surfaceCatalog" packages/map_core packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle
rg -n "Encounter|encounter|EncounterTable|wild|Wild|battle|Battle|grass|tall|surf|water|collision|movement|passable|walkable|tile behavior|terrain" packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle packages/map_editor
rg -n "MapEntity|MapLayer|CollisionLayer|PathLayer|TerrainLayer|MapData|GameState|Player|movement|warp|trigger|zone|spawn" packages/map_core packages/map_runtime packages/map_gameplay
rg -n "Lot 94|Runtime Surface|Gameplay Semantics|Surface Gameplay|SurfaceCatalog" reports/surface
```

Résumés compacts :

- Références Surface visuelles : `map_core` 1154 hits, `map_editor` 581 hits, `map_runtime` 150 hits.
- Références gameplay / battle / movement : `map_battle` 13012 hits, `map_runtime` 12478 hits, `map_core` 3825 hits, `map_editor` 3550 hits, `map_gameplay` 288 hits.
- Références map/entity/movement : `map_core` 2816 hits, `map_runtime` 2356 hits, `map_gameplay` 558 hits.
- Références rapports Surface : `reports/surface` 5968 hits.

Findings :

- Les surfaces visuelles vivent dans `map_core` (`surface.dart`, `map_layer`, codecs, diagnostics, `surface_layer_placements`) et dans `map_editor` pour authoring.
- Le rendu Surface runtime vit dans `map_runtime/src/surface` et `MapLayersComponent`.
- Le gameplay mouvement/monde vit surtout dans `map_gameplay` (`gameplay_world_state`, `gameplay_step`, `surf_evaluation`, encounters).
- Les encounters et battle handoff sont déjà des concepts runtime/gameplay existants, mais pas reliés aux `SurfaceLayer`.
- Les modèles à ne pas polluer : `ProjectSurfacePreset`, `ProjectSurfaceAnimation`, `ProjectSurfaceAtlas`, `ProjectSurfaceCatalog`, `SurfaceLayer`, `SurfaceCellPlacement`, renderer runtime.
- Points d'intégration naturels futurs : `map_core` pour modèles purs + diagnostics, `map_editor` pour UI no-code, `map_gameplay` pour résolution movement/encounters, `map_runtime` pour relier bundle/position joueur/battle handoff.
- Risque principal : faire porter à un preset visuel des responsabilités gameplay, ce qui couplerait animation, rendu et règles.

## 6. Rappel Runtime Surface V0 fermé

Le Lot 94 a fermé le Runtime Surface V0 visuel :

- collecte tilesets Surface ;
- resolver runtime pur ;
- rendu Flame réel ;
- animation via `_animElapsed` ;
- ordre de rendu durci ;
- assets manquants / catalogue incomplet sans crash ;
- golden slice disque réel ;
- smoke `RuntimeMapGame` et `PlayableMapGame`.

Cette fermeture concerne le rendu visuel, pas le gameplay.

## 7. Problème à résoudre

Objectif produit :

```text
Surface visuelle = ce que je vois
Comportement de surface = ce que ça fait
```

Un utilisateur no-code doit pouvoir configurer :

- eau surfable ;
- herbe haute avec rencontres ;
- glace glissante ;
- lave dangereuse ;
- boue ralentissante ;
- effets de pas ;
- conditions badge / flag / capacité.

Sans comprendre :

- `SurfaceVariantRole` ;
- `SurfaceRuntimeRenderInstruction` ;
- `ProjectSurfaceAnimation` ;
- frames / atlas / column / row ;
- JSON ;
- enum Dart interne.

## 8. Décision centrale : visual surface vs gameplay semantics

Décision :

```text
Une surface visuelle reste visuelle.
Le gameplay est une couche séparée qui référence les surfaces visuelles.
```

Conséquences :

- Le renderer Surface ne sait pas qu'une surface est surfable.
- Le système de rencontre ne sait pas comment l'eau est animée.
- Les comportements gameplay ne dépendent pas des frames d'animation.
- `surfacePresetId` devient le pont stable entre visuel et gameplay.

## 9. Options comparées

### Option A — comportements dans `ProjectSurfacePreset`

Avantages :

- simple à trouver depuis un placement ;
- donne l'impression d'un modèle unique.

Inconvénients :

- pollue un preset visuel ;
- lie animation/rendu et gameplay ;
- rend tallGrass/water/lava/ice plus difficiles à composer ;
- complique migration et diagnostics ;
- force les éditeurs visuels à connaître le gameplay.

Verdict : rejetée.

### Option B — comportements dans `SurfaceLayer` / `SurfaceCellPlacement`

Avantages :

- permet des overrides locaux ;
- proche de la donnée placée.

Inconvénients :

- duplication massive par cellule ;
- difficile à éditer no-code ;
- risque de casser le painter ;
- rend les règles globales illisibles.

Verdict : rejetée pour V0. À garder comme idée d'override futur rare.

### Option C — catalogue séparé de semantics gameplay

Avantages :

- sépare visuel et gameplay ;
- permet des cartes no-code claires ;
- facilite diagnostics ;
- compatible avec plusieurs presets cibles ;
- extensible vers encounters, hazards, movement, requirements.

Inconvénients :

- nouveau modèle à concevoir ;
- nécessite résolution runtime supplémentaire ;
- nécessite UI dédiée.

Verdict : recommandé.

## 10. Décision de stockage des comportements

Verdict V1 :

```text
Créer plus tard un catalogue séparé :
ProjectSurfaceGameplayCatalog
```

Ce catalogue référence les presets visuels par `surfacePresetId`, mais ne connaît pas :

- atlas ;
- animation ;
- frame ;
- rôle autotile ;
- renderer.

Il devra probablement être intégré à `ProjectManifest` plus tard, mais pas dans ce lot.

## 11. Granularité des règles

Options comparées :

- règle par `surfacePresetId` ;
- règle par layer ;
- règle par cellule ;
- règle par zone ;
- règle hybride.

Verdict V1 :

```text
règle principale par surfacePresetId
```

Raison :

- correspond au modèle no-code "cette surface water fait X" ;
- évite la duplication ;
- reste compatible avec le painter ;
- marche pour water, tallGrass, ice, lava, mud.

Futurs overrides possibles :

- override par layer pour une map spéciale ;
- override par zone pour une région ;
- override par cellule pour puzzle avancé.

Mais pas en V0.

## 12. Modèle conceptuel recommandé

Noms comparés :

- `ProjectSurfaceGameplayCatalog` : explicite, aligné projet.
- `SurfaceBehaviorCatalog` : plus court, mais moins clair sur gameplay.
- `SurfaceSemanticsCatalog` : précis, mais plus technique.

Recommandation :

```text
ProjectSurfaceGameplayCatalog
SurfaceGameplayRule
SurfaceGameplayTarget
SurfaceGameplayBehavior
SurfaceGameplayRequirement
```

Structure conceptuelle non codée :

```text
ProjectSurfaceGameplayCatalog
- rules: List<SurfaceGameplayRule>

SurfaceGameplayRule
- id
- name
- target
- behavior
- enabled
- sortOrder

SurfaceGameplayTarget
- surfacePresetIds: List<String>

SurfaceGameplayBehavior
- kind: encounterArea | surfable | movementModifier | hazard | footstepEffect
- encounterTableId?
- encounterMode?
- canSurf?
- movementCost?
- slideMode?
- damagePerStep?
- hazardEffectId?
- footstepEffectId?
- requirements?

SurfaceGameplayRequirement
- requiredBadgeIds?
- requiredFlagIds?
- requiredAbilityIds?
- blockedMessage?
```

Note : ceci est une spec, pas une implémentation. Les noms pourront changer au Lot 96.

## 13. UX no-code recommandée

Écran futur recommandé :

```text
Surface Behaviors Studio
```

Nom utilisateur FR possible :

```text
Comportements de surface
```

Workflow no-code :

1. Choisir une surface peignable.
2. Choisir un comportement.
3. Configurer les options.
4. Voir un résumé lisible.
5. Corriger les diagnostics.

Ne jamais faire de dropdown principal avec des enums techniques.

Cartes utilisateur :

```text
Eau surfable
- Surface : water
- Nécessite : badge Surf / flag story_has_surf
- Message si bloqué : "Il faut pouvoir surfer."
```

```text
Herbe haute
- Surface : tall_grass
- Table de rencontres : route_1_grass
- Déclenchement : en marchant
```

```text
Lave dangereuse
- Surface : lava
- Dégâts : 5 PV par pas
- Bloque sans protection : oui
```

```text
Glace glissante
- Surface : ice
- Mouvement : glissade jusqu'à obstacle
```

## 14. Comportements cibles

### Tall grass

Décision :

```text
tallGrass = surface visuelle + behavior encounterArea
```

V1 :

- cible un ou plusieurs `surfacePresetId` ;
- référence une `encounterTableId` ;
- déclenchement en marchant ;
- chance / steps / cooldown plus tard.

### Surfable water

Décision :

```text
water = surface visuelle + behavior surfable
```

V1 :

- `canSurf = true` ;
- requirements optionnels plus tard ;
- transition de locomotion hors V0 ;
- message bloquant no-code.

### Ice

Décision :

```text
ice = movement modifier / forced sliding future
```

V1 :

- behavior `movementModifier` ;
- champ conceptuel `slideMode`;
- résolution mouvement dans `map_gameplay`.

### Lava

Décision :

```text
lava = hazard / damage per step future
```

V1 :

- behavior `hazard`;
- `damagePerStep`;
- `hazardEffectId` optionnel.

### Mud

Décision :

```text
mud = movement cost / speed modifier future
```

V1 :

- behavior `movementModifier`;
- `movementCost`;
- peut ralentir ou changer animation de pas.

### Legacy PathSurfaceKind

Décision :

- rester compatible ;
- ne pas mélanger migration et semantics V1 ;
- migration legacy dans un lot dédié ;
- ancien water/lava/ice/tallGrass peut inspirer les presets/règles mais ne doit pas dicter le nouveau modèle.

## 15. Diagnostics futurs

Errors :

- rule references missing `surfacePresetId`;
- encounter behavior without `encounterTableId`;
- unknown behavior kind;
- invalid movement modifier value;
- hazard without effect or damage configuration when required.

Warnings :

- multiple conflicting behaviors on same surface;
- surfable behavior with impossible requirement;
- behavior defined but surface never used;
- surface visually placed but no behavior;
- encounter table exists but no reachable surface uses it.

Info :

- visual surface has no gameplay, treated as decorative;
- rule disabled;
- multiple surfaces share same behavior intentionally.

## 16. Runtime futur

Helpers conceptuels à prévoir :

```text
resolveSurfaceGameplayAtPosition(...)
resolveSurfaceBehaviorsForPreset(...)
resolvePlayerCurrentSurface(...)
canEnterSurface(...)
shouldTriggerEncounterOnStep(...)
resolveMovementModifier(...)
resolveHazardEffectOnStep(...)
```

Dépendances futures :

- `SurfaceLayer` placements ;
- `surfacePresetId` à la position joueur ;
- `ProjectSurfaceGameplayCatalog` ;
- `GameState` ;
- flags / inventory / badges / abilities si existants ;
- encounter tables ;
- battle handoff.

Principe :

```text
map_gameplay résout les comportements.
map_runtime orchestre avec le bundle et le handoff.
Le renderer Surface ne participe pas.
```

## 17. Intégration éditeur future

`map_editor` devra fournir :

- un écran "Comportements de surface" ;
- sélection d'une surface peignable ;
- choix d'un comportement ;
- champs no-code guidés ;
- aperçu des surfaces concernées ;
- diagnostics utilisateur.

Surface Studio reste centré sur les surfaces visuelles. Le nouvel écran peut être adjacent mais ne doit pas transformer Surface Studio en éditeur gameplay tentaculaire.

## 18. Risques et anti-patterns

Anti-patterns à éviter :

- ajouter `isSurfable` dans `ProjectSurfacePreset`;
- ajouter `encounterTableId` dans `SurfaceAnimationFrame`;
- faire lire le renderer par le système de rencontres ;
- dupliquer le comportement dans chaque `SurfaceCellPlacement`;
- mélanger migration legacy et nouvelle semantics ;
- exposer `SurfaceVariantRole` dans l'UX gameplay ;
- faire dépendre `map_gameplay` de Flutter/Flame ;
- faire dépendre `map_core` du runtime.

Risques :

- conflits entre plusieurs règles ;
- UX trop technique ;
- modèle trop flexible trop tôt ;
- migration legacy plus complexe que prévu ;
- surf/tallGrass ont des besoins différents malgré une infrastructure commune.

## 19. Roadmap post Lot 95

Roadmap recommandée :

| Lot | Sujet |
| --- | --- |
| Lot 96 | Surface Gameplay Semantics Model V0 |
| Lot 97 | Surface Gameplay Semantics Diagnostics V0 |
| Lot 98 | Surface Gameplay Semantics JSON Codec V0 |
| Lot 99 | ProjectManifest Surface Gameplay Integration V0 |
| Lot 100 | Surface Behavior Studio Shell V0 |
| Lot 101 | Assign Behavior to Surface Preset V0 |
| Lot 102 | Runtime Surface Behavior Resolver V0 |
| Lot 103 | Tall Grass Encounter Behavior V0 |
| Lot 104 | Surfable Water Behavior V0 |

Prochain lot recommandé :

```text
Lot 96 — Surface Gameplay Semantics Model V0
```

Pourquoi : il faut définir les types purs avant diagnostics, JSON, UI ou runtime.

## 20. Tests relancés

Commandes :

```bash
cd packages/map_runtime && flutter test test/surface
cd packages/map_runtime && flutter test test/runtime_manifest_tilesets_surface_layer_test.dart
cd packages/map_runtime && flutter test test/map_layers_component_render_pass_test.dart
```

Analyse Dart ciblée :

```text
Aucune analyse Dart ciblée nécessaire : aucun fichier Dart modifié.
```

## 21. Résultats

Résultats :

```text
flutter test test/surface
00:05 +29: All tests passed!
```

```text
flutter test test/runtime_manifest_tilesets_surface_layer_test.dart
00:01 +1: All tests passed!
```

```text
flutter test test/map_layers_component_render_pass_test.dart
00:01 +2: All tests passed!
```

## 22. Fichiers créés

- `reports/surface/surface_engine_lot_95_surface_gameplay_semantics_spec_no_code_design.md`

## 23. Fichiers modifiés

Aucun fichier existant modifié.

## 24. Fichiers supprimés

Aucun.

## 25. Git status final

Gate final après écriture du rapport :

```text
?? reports/surface/surface_engine_lot_94_pack_runtime_surface_closure_and_gameplay_semantics_decision.md
?? reports/surface/surface_engine_lot_95_surface_gameplay_semantics_spec_no_code_design.md
```

`git diff --stat` final :

```text
```

Recherche fichiers temporaires :

```text
```

`git diff --check` :

```text
```

## 26. Périmètre explicitement non touché

Confirmé :

- `map_core` non modifié ;
- `map_editor` non modifié ;
- `map_runtime` production non modifié ;
- `map_gameplay` non modifié ;
- `map_battle` non modifié ;
- `ProjectManifest` non modifié ;
- `surface.dart` non modifié ;
- `surface_catalog.dart` non modifié ;
- codecs Surface non modifiés ;
- aucune migration legacy ;
- aucun gameplay surf codé ;
- aucun tall grass encounter codé ;
- aucune collision Surface codée ;
- aucune nouvelle clock runtime ;
- aucun changement JSON ;
- aucun changement Surface Studio ;
- aucun changement Surface Painter.

## 27. ctx stats

Résumé compact `ctx stats` :

```text
74.2K tokens saved · 98.7% reduction · 19 min
Without context-mode: 293.5 KB
With context-mode: 3.9 KB
289.6 KB kept out of conversation
13 calls
ctx_index: 7 calls, 97.1 KB saved
ctx_doctor: 3 calls, 82.2 KB saved
ctx_stats: 2 calls, 67.2 KB saved
ctx_upgrade: 1 call, 37.4 KB saved
v1.0.100 visible in current session; upgrade to v1.0.103 requires session restart
```

## 28. Limites restantes

- Cette spec ne crée pas encore le modèle.
- Les requirements badge/flag/ability doivent être alignés avec les systèmes existants avant code.
- La migration legacy water/grass reste à auditer.
- La collision Surface reste hors scope.
- Les noms proposés sont conceptuels.
- Le prochain lot doit rester prudent pour éviter un gros modèle trop abstrait.

## 29. Auto-critique

La spec est volontairement conservatrice. Elle protège le rendu Surface, mais elle reporte beaucoup de décisions d'implémentation concrètes au Lot 96 : structure exacte, JSON, `ProjectManifest`, compat legacy.

Le risque restant est de sous-estimer les besoins différents entre water/surf et tallGrass/encounters. Ils doivent partager le mécanisme de ciblage par surface, pas forcément les mêmes sous-modèles.

## 30. Regard critique sur le prompt

Le prompt est bien cadré : il interdit le code et force la séparation visuel/gameplay au bon moment.

Point discutable : il demande Context Mode très agressif, mais cette session n'expose pas encore `ctx_batch_execute`/`ctx_search` malgré l'upgrade. Le rapport documente cette limite et compense par des sorties compactes.

## Evidence Pack

Status initial : section 3.

Commandes d'audit : section 5.

Findings importants : sections 5 à 18.

Tests relancés : sections 20 et 21.

Contenu du rapport créé : non recopié récursivement.

## Auto-review obligatoire

- Est-ce que la séparation visual/gameplay est claire ? Oui.
- Est-ce que ProjectSurfacePreset reste visuel ? Oui.
- Est-ce que le gameplay est placé dans une couche séparée ? Oui.
- Est-ce que tallGrass est spécifié conceptuellement ? Oui.
- Est-ce que surfable water est spécifié conceptuellement ? Oui.
- Est-ce que ice/lava/mud sont cadrés ? Oui.
- Est-ce que l’UX no-code est décrite ? Oui.
- Est-ce que les diagnostics futurs sont listés ? Oui.
- Est-ce que la roadmap post Lot 95 est claire ? Oui.
- Est-ce que les tests runtime Surface ont été relancés ? Oui.
- Est-ce que Context Mode a été utilisé agressivement ? Partiellement oui : outils exposés utilisés, outils d'exécution/recherche Context Mode indisponibles dans cette session.
- Est-ce que ctx stats est inclus ? Oui.
- Est-ce qu’un Lot 95-bis est nécessaire ? Non. Le prochain lot utile est Lot 96, modèle V0, après validation de cette spec.
