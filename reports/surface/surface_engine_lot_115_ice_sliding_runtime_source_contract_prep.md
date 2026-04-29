# Lot 115 — Ice Sliding Runtime Source Contract / Prep V0

## 1. Résumé exécutif honnête

Le Lot 115 tranche la question laissée ouverte par le Lot 114 : `Moved.movementEffect` existe maintenant, mais aucune donnée persistante honnête ne dit encore "cette zone produit une glissade".

Décision :

- la source gameplay long terme pour `GameplayMovementEffect.slide(...)` doit être une zone gameplay typée dédiée ;
- la destination cible recommandée est `GameplayZoneKind.movementEffect` avec un futur payload explicite, par exemple `MovementEffectZonePayload` ;
- `SurfaceLayer` ne doit pas devenir une source gameplay directe ;
- `MovementZonePayload` ne doit pas être étendu pour porter la glissade ;
- `SpecialZonePayload(scriptKey: "ice_slide")` peut servir de seam technique temporaire seulement si un lot le demande explicitement, mais il est rejeté comme source produit/no-code ;
- le prochain lot recommandé est `Lot 116 — MovementEffectZonePayload Model V0`, pas un runtime ice directement.

Aucune feature n'a été codée. Aucun fichier Dart n'a été modifié.

## 2. Périmètre

Inclus :

- audit Lots 113 / 114 ;
- audit `MapGameplayZone` et payloads existants ;
- audit `SpecialZonePayload` ;
- audit legacy ice / Surface ice ;
- audit impact JSON / generated / manifest ;
- comparaison des options de source gameplay ;
- décision source long terme et source V0 ;
- relance des tests de clôture.

Exclus :

- aucun code ice ;
- aucune glissade ;
- aucun mouvement forcé ;
- aucun editor ice ;
- aucun runtime Flutter ;
- aucun nouveau modèle Dart ;
- aucune modification `map_core`, `map_editor`, `map_gameplay`, `map_runtime`, `map_battle` ou `examples`.

## 3. Gate 0 — status initial

Commande exécutée depuis la racine :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 12
find . -name AGENTS.md -print
```

Sortie complète :

```text
/Users/karim/Project/pokemonProject
main
3aae74a6 lot 114: Surface Movement Effect Runtime Prep
830b8b5b lot 113
011b4bc1 fix bridge
09a9b0df lot 112: Ice Mud Movement Semantics Decision
f57ade04 Merge PSDK battle parity work
993b0033 Complete PSDK battle parity batch
a294999b lot 110: Lava Hazard Runtime E2E Closure
af24a783 lot 109: Editor Generate Lava Hazard Zone from Surface
3ef5fc92 lot 108: Hazard Runtime Consumption Prep
e8bfc68e lot 107: Lava Hazard from Surface Workflow Decision
4851b53f lot 106: Surface Behavior Action Menu
2305f276 lot 104: Surface Gameplay Bridge Runtime E2E Closure
./AGENTS.md
```

Interprétation Gate 0 :

- branche courante : `main` ;
- `git status --short --untracked-files=all` initial : aucune ligne ;
- `git diff --stat` initial : aucune ligne ;
- `AGENTS.md` trouvé à la racine uniquement ;
- aucun changement préexistant à distinguer au début du Lot 115.

## 4. Context Mode usage

Context Mode a été utilisé pour les audits et sorties de tests.

Commandes Context Mode principales :

- Gate 0 + audits obligatoires : 7 commandes, 13 924 lignes, 2 092.1 KB indexés ;
- audit ciblé payloads / resolvers / validators / ice : 8 commandes, 960 lignes, 50.5 KB indexés ;
- audit enum / JSON / switches éditeur : 6 commandes, 474 lignes, 32.2 KB indexés ;
- audit enum exact / generated / panel : 3 commandes, 270 lignes, 9.5 KB indexés ;
- relance tests de clôture via Context Mode avec extraction des lignes finales.

Commande demandée :

```bash
ctx stats
```

Résultat exact :

```text
Exit code: 127

stdout:


stderr:
/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/.ctx-mode-EdXKo1/script.sh: line 1: ctx: command not found
```

Context Mode était disponible via les outils MCP, mais l'exécutable shell `ctx` n'était pas disponible pour cette commande finale.

## 5. Audit Lots 113 / 114

Commande obligatoire exécutée :

```bash
rg -n "Lot 113|Lot 114|GameplayMovementEffect|GameplayMovementEffectKind|Moved\.movementEffect|movementEffect|slide|movementCost|Surface Movement Effect|Ice|Mud" reports/surface packages/map_gameplay/lib packages/map_gameplay/test
```

Fichiers prioritaires lus :

- `reports/surface/surface_engine_lot_113_surface_movement_effects_model_decision.md`
- `reports/surface/surface_engine_lot_114_surface_movement_effect_runtime_prep.md`
- `packages/map_gameplay/lib/src/gameplay_movement_effect.dart`
- `packages/map_gameplay/lib/src/gameplay_step_result.dart`
- `packages/map_gameplay/test/gameplay_movement_effect_test.dart`

Findings :

- Lot 113 recommande `GameplayMovementEffect` côté `map_gameplay`.
- Lot 113 recommande `Moved.movementEffect` pour rester cohérent avec `Moved.hazardEffect`.
- Lot 113 rejette `MovementZonePayload` comme payload fourre-tout.
- Lot 113 rejette `SpecialZonePayload(scriptKey)` comme voie produit no-code.
- Lot 114 a réellement codé :
  - `GameplayMovementEffectKind.slide` ;
  - `GameplayMovementEffectKind.movementCost` ;
  - `GameplayMovementEffect.slide(...)` ;
  - `GameplayMovementEffect.movementCost(...)` ;
  - `Moved.movementEffect`.
- Lot 114 a aussi testé que `stepGameplayWorld` ne produit pas encore de `movementEffect`.

Conclusion :

`Moved.movementEffect` est prêt à transporter un effet, mais il manque la source persistante qui permet à `map_gameplay` de décider qu'une cellule doit produire une glissade.

## 6. Audit MapGameplayZone / payloads existants

Commande obligatoire exécutée :

```bash
rg -n "GameplayZoneKind|MapGameplayZone|MovementZonePayload|MovementMode|HazardZonePayload|HazardKind|SpecialZonePayload|custom|priority|area|scriptKey|properties|movementEffect|slide|ice|mud" packages/map_core/lib packages/map_core/test packages/map_editor/lib packages/map_gameplay/lib packages/map_runtime/lib
```

Fichiers prioritaires lus :

- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/src/models/map_gameplay_zone_payloads.dart`
- `packages/map_core/lib/src/operations/map_gameplay_zones.dart`
- `packages/map_editor/lib/src/ui/panels/gameplay_zone_properties_panel.dart`

Findings structurants :

- `MapGameplayZone` est le modèle gameplay rectangulaire persistant.
- `MapGameplayZone` porte :
  - `id`
  - `name`
  - `kind`
  - `area`
  - `priority`
  - `encounter`
  - `movement`
  - `hazard`
  - `special`
- `GameplayZoneKind` existe avec :
  - `encounter`
  - `movement`
  - `hazard`
  - `special`
  - `custom`
- `custom` est explicitement documenté comme fallback à ne pas utiliser dans du nouveau code.
- `MovementZonePayload` contient seulement :
  - `requiredMode`
  - `allowedModes`
- `HazardZonePayload` contient :
  - `hazardKind`
  - `damagePerStep`
- `SpecialZonePayload` contient :
  - `scriptKey`
  - `properties`
- `findGameplayZoneAtPos` et `findAllGameplayZonesAtPos` existent déjà et utilisent `area` + `priority`.
- `area` et `priority` suffisent comme base de résolution spatiale pour un futur movement effect.

Réponses :

- Peut-on représenter ice slide sans nouveau kind ? Techniquement oui via `special`, mais pas proprement comme produit.
- `MovementZonePayload` peut-il être étendu proprement ? Non, il représente actuellement un gate/mode, pas un effet de surface.
- `SpecialZonePayload` peut-il servir de transition temporaire ? Oui comme seam technique isolé, non comme modèle produit.
- `custom` peut-il servir ? Non, le code dit de ne pas l'utiliser pour du nouveau code.
- `priority` / `area` suffisent-ils pour résoudre l'effet ? Oui pour trouver la zone source ; le payload manque encore.

## 7. Audit SpecialZonePayload

Commande obligatoire exécutée :

```bash
rg -n "SpecialZonePayload|scriptKey|properties|GameplayZoneKind.special|special:" packages/map_core/lib packages/map_core/test packages/map_editor/lib packages/map_gameplay/lib packages/map_runtime/lib packages/map_editor/test packages/map_gameplay/test
```

Findings :

- `SpecialZonePayload` est un payload libre.
- Il porte `scriptKey` et `properties`.
- `map_core` valide surtout les clés vides dans `special.properties`.
- `surface_to_gameplay_zone_generation_plan.dart` sait générer un draft `special`.
- `map_editor` expose `special` / `custom` avec un champ "Script Key".
- `map_gameplay` ne consomme pas `GameplayZoneKind.special` pour produire des effets de mouvement.
- `map_runtime` ne consomme pas `special` comme source de glissade.
- Aucun test trouvé ne prouve qu'un `scriptKey: "ice_slide"` produit un comportement runtime.

Évaluation honnête :

- Acceptable pour un prototype technique très isolé : oui.
- Acceptable pour prouver rapidement le mapping `MapGameplayZone` vers `GameplayMovementEffect.slide` : oui, seulement si aucun utilisateur/éditeur n'en dépend.
- Acceptable comme source produit no-code : non.
- Risque principal : transformer une mécanique moteur typée en convention de string durable.

Décision :

`SpecialZonePayload(scriptKey: "ice_slide")` est rejeté comme source V0 produit. Il ne doit pas être utilisé pour ouvrir l'éditeur ice.

## 8. Audit legacy ice / Surface ice

Commande obligatoire exécutée :

```bash
rg -n "PathSurfaceKind\.ice|ice|Ice|standard.*Ice|createStandardIce|surfacePresetId.*ice|Surface.*ice|slide|sliding|glide|frozen|freeze" packages/map_core/lib packages/map_core/test packages/map_editor/lib packages/map_gameplay/lib packages/map_runtime/lib packages/map_runtime/test reports/surface
```

Findings :

- `PathSurfaceKind.ice` existe.
- Des tests `standard_ice_path_preset_vertical_atlas_builder_test.dart` existent pour construire un preset path ice standard.
- Ces tests prouvent un preset visuel/atlas, pas une mécanique de glissade.
- `PathSurfaceKind.ice` est legacy/path-oriented, pas une source gameplay V1.
- Aucune mécanique runtime de glissade n'a été trouvée.
- Aucune consommation `ice` par `stepGameplayWorld` n'a été trouvée.
- Les surfaces V1 restent visuelles : les Lots 96-111 ont confirmé que le gameplay doit passer par `MapGameplayZone`.

Réponse centrale :

On ne doit pas mapper directement `SurfaceLayer` ou `PathSurfaceKind.ice` vers `GameplayMovementEffect.slide`. Ce serait un retour en arrière par rapport à la séparation Surface visuelle / GameplayZone.

## 9. Audit JSON / manifest impact potentiel

Commande obligatoire exécutée :

```bash
rg -n "ProjectManifest|MapGameplayZone|GameplayZoneKind|map_gameplay_zone_payloads|JsonSerializable|Freezed|fromJson|toJson|gameplayZones|generated" packages/map_core/lib packages/map_core/test reports/surface
```

Fichiers inspectés :

- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_data.g.dart`
- `packages/map_core/lib/src/models/map_data.freezed.dart`
- `packages/map_core/lib/src/models/map_gameplay_zone_payloads.dart`
- `packages/map_core/lib/src/models/map_gameplay_zone_payloads.g.dart`
- `packages/map_core/lib/src/models/enums.dart`

Findings :

- `MapGameplayZone` est `@freezed`.
- `MapGameplayZone` est `@JsonSerializable(explicitToJson: true)`.
- `MapGameplayZone.fromJson(...)` passe par `migrateMapGameplayZoneJson(...)`.
- `MapData` sérialise `gameplayZones`.
- `GameplayZoneKind` est sérialisé dans `map_data.g.dart`.
- Ajouter `GameplayZoneKind.movementEffect` modifierait le contrat JSON.
- Ajouter `MovementEffectZonePayload` toucherait `map_gameplay_zone_payloads.dart` et les fichiers generated.
- Des switches éditeur sur `GameplayZoneKind` devront probablement être mis à jour pour compiler et rester lisibles.

Conclusion :

Ajouter une vraie source movement effect est un lot modèle coordonné, pas une petite ligne runtime. Il doit être traité explicitement, avec génération Freezed/JSON et tests de compatibilité.

## 10. Options de source comparées

| Option | Description | Avantages | Risques | Verdict |
| --- | --- | --- | --- | --- |
| A | `GameplayZoneKind.special` + `SpecialZonePayload(scriptKey: "ice_slide")` | Aucun modèle nouveau, test seam rapide | Stringly typed, validation faible, mauvais no-code, dette durable | Rejetée comme source produit ; tolérable seulement comme seam privé |
| B | Nouveau `GameplayZoneKind.movementEffect` + `MovementEffectZonePayload` | Typé, no-code propre, validation claire, séparation gates/effects | Modifie `map_core`, JSON/generated, switches éditeur | Recommandée comme cible |
| C | Étendre `MovementZonePayload` avec slide/movementCost | Moins de nouveau modèle apparent | Mélange gate surf et effet de surface ; payload fourre-tout | Rejetée |
| D | Résoudre depuis `SurfaceLayer` directement | Aucun GameplayZone supplémentaire | Viole SurfaceLayer visuel, couple gameplay au visuel, contredit Lots 96-111 | Rejetée fermement |
| E | Ne pas ouvrir ice maintenant | Risque nul | Repousse la progression gameplay | Non nécessaire si on fait d'abord le modèle |

## 11. Décision source long terme

La source long terme doit être une zone gameplay typée dédiée :

```text
MapGameplayZone(kind: movementEffect)
→ MovementEffectZonePayload(effectKind: slide, ...)
→ map_gameplay produit GameplayMovementEffect.slide(...)
```

Raisons :

- cohérent avec `encounter`, `movement`, `hazard` ;
- maintient `SurfaceLayer` visuel ;
- évite de transformer `MovementZonePayload` en mélange gate/effect ;
- évite `scriptKey` comme contrat moteur ;
- exploite déjà `area` et `priority` de `MapGameplayZone` ;
- prépare une UX no-code lisible : "Glace glissante" devient un comportement typé, pas une string.

Important :

Le futur payload persistant doit vivre dans `map_core`. Il ne doit pas dépendre de `GameplayMovementEffectKind` de `map_gameplay`, car `map_core` est le paquet de contrat de base. Le futur lot devra soit créer un enum core dédié, soit nommer le payload pour éviter toute dépendance inversée.

## 12. Décision source V0 / prochain lot

Décision :

Le prochain lot ne doit pas coder la glissade runtime avec `SpecialZonePayload`. Il doit d'abord créer la source typée.

Recommandation :

```text
Lot 116 — MovementEffectZonePayload Model V0
```

Scope recommandé du Lot 116 :

- ajouter un kind typé, probablement `GameplayZoneKind.movementEffect` ;
- ajouter un payload, probablement `MovementEffectZonePayload` ;
- définir un enum core pour `slide` et `movementCost` ;
- générer Freezed/JSON uniquement dans `map_core` ;
- ajouter tests JSON / validation / migration si nécessaire ;
- mettre à jour les switches éditeur strictement nécessaires à la compilation, sans ajouter d'action UI ;
- ne pas modifier `stepGameplayWorld` ;
- ne pas coder ice editor ;
- ne pas coder runtime glissade.

Le runtime ice pourra venir après, quand la source persistante sera réelle.

## 13. Décision sur SpecialZonePayload

`SpecialZonePayload(scriptKey: "ice_slide")` est rejeté comme source produit.

Il reste acceptable uniquement comme seam temporaire dans un test interne si un lot futur le demande explicitement, avec ces garde-fous :

- pas d'exposition UI ;
- pas de promesse no-code ;
- pas de migration ;
- nommage indiquant que c'est transitoire ;
- suppression ou remplacement dès que `MovementEffectZonePayload` existe.

Mais la recommandation du Lot 115 est de ne pas prendre ce détour.

## 14. Roadmap recommandée

| Lot | Titre | Classement | Raison |
| --- | --- | --- | --- |
| 116 | MovementEffectZonePayload Model V0 | Indispensable | Créer la source persistante typée |
| 117 | Ice Sliding Runtime Prep V0 | Indispensable | Produire `GameplayMovementEffect.slide` depuis la zone typée |
| 118 | Editor Generate Ice Behavior from Surface V0 | Indispensable après runtime prep | Brancher l'authoring Surface ice |
| 119 | Ice Runtime E2E / Closure V0 | Indispensable | Fermer ice comme tall grass/water/lava |
| 120 | Mud Movement Cost Model / Runtime Prep V0 | Utile | Réutiliser la famille movement effect |
| 121 | Editor Generate Mud Behavior from Surface V0 | Utile | Ajouter la boue après contrat validé |
| 122 | Surface Gameplay Diagnostics / Coverage Preview V0 | Utile | Améliorer tous les workflows existants |
| 123 | PlayableMapGame Surface Gameplay Smoke V0 | Utile | Vérifier surf/hazard/movementEffect côté intégration |
| 124 | Surface Gameplay V1 Documentation | À retarder | Utile après ice ou mud |
| 125 | Surface Behavior Tests Split / Maintenance V0 | À retarder | À faire quand le fichier de tests gêne vraiment |

## 15. Tests relancés

Commandes :

```bash
cd packages/map_gameplay && dart test test/gameplay_movement_effect_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/hazard_runtime_consumption_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/surface_generated_gameplay_zone_bridge_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/movement_mode_water_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/surf_evaluation_test.dart --reporter expanded
cd packages/map_editor && flutter test test/surface_painter/surface_to_gameplay_zone_action_test.dart --no-pub --reporter expanded
cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_plan_test.dart --reporter expanded
cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_assessment_test.dart --reporter expanded
cd packages/map_runtime && flutter test test/surface --reporter expanded
```

## 16. Résultats

Lignes finales exactes relevées :

```text
cd packages/map_gameplay && dart test test/gameplay_movement_effect_test.dart --reporter expanded
00:00 +12: All tests passed!

cd packages/map_gameplay && dart test test/hazard_runtime_consumption_test.dart --reporter expanded
00:00 +8: All tests passed!

cd packages/map_gameplay && dart test test/surface_generated_gameplay_zone_bridge_test.dart --reporter expanded
00:00 +6: All tests passed!

cd packages/map_gameplay && dart test test/movement_mode_water_test.dart --reporter expanded
00:00 +6: All tests passed!

cd packages/map_gameplay && dart test test/surf_evaluation_test.dart --reporter expanded
00:00 +12: All tests passed!

cd packages/map_editor && flutter test test/surface_painter/surface_to_gameplay_zone_action_test.dart --no-pub --reporter expanded
00:01 +29: All tests passed!

cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_plan_test.dart --reporter expanded
00:00 +16: All tests passed!

cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_assessment_test.dart --reporter expanded
00:00 +12: All tests passed!

cd packages/map_runtime && flutter test test/surface --reporter expanded
00:01 +29: All tests passed!
```

## 17. Analyse lancée

Aucune analyse Dart ciblée n'a été lancée, car aucun fichier Dart n'a été modifié pendant le Lot 115.

## 18. Résultats analyze

Non applicable : aucun changement Dart.

## 19. Fichiers créés

Créé par le Lot 115 :

- `reports/surface/surface_engine_lot_115_ice_sliding_runtime_source_contract_prep.md`

## 20. Fichiers modifiés

Aucun fichier existant modifié.

## 21. Fichiers supprimés

Aucun fichier supprimé.

## 22. Contenu complet des fichiers créés

Le seul fichier créé est ce rapport. Il n'est pas recopié dans lui-même, conformément à l'exception explicite du prompt.

## 23. Contenu complet des fichiers modifiés

Aucun fichier modifié.

## 24. Git status final

Commandes :

```bash
git status --short --untracked-files=all
git diff --stat
git diff --check
```

Status final complet :

```text
?? reports/surface/surface_engine_lot_115_ice_sliding_runtime_source_contract_prep.md
```

Diff stat final complet :

```text
```

`git diff --check` :

```text
```

Interprétation :

- seul le rapport Lot 115 est non suivi ;
- aucune modification de code ;
- aucun diff sur fichiers suivis ;
- aucun whitespace error détecté par `git diff --check`.

## 25. Périmètre explicitement non touché

Confirmations :

- map_core production non modifié ;
- map_editor production non modifié ;
- map_gameplay production non modifié ;
- map_runtime production non modifié ;
- map_battle non modifié ;
- examples non modifié ;
- MapData modèle non modifié ;
- MapGameplayZone modèle non modifié ;
- GameplayZoneKind non modifié ;
- MovementZonePayload non modifié ;
- MovementMode non modifié ;
- HazardZonePayload non modifié ;
- HazardKind non modifié ;
- SpecialZonePayload non modifié ;
- GameplayMovementEffect non modifié ;
- Moved non modifié ;
- stepGameplayWorld non modifié ;
- GameplayWorldState non modifié ;
- PlayableMapGame non modifié ;
- SurfaceLayer non modifié ;
- SurfaceCellPlacement non modifié ;
- ProjectManifest non modifié ;
- aucun JSON ;
- aucun generated/build_runner ;
- aucune action editor nouvelle ;
- aucun dialog editor nouveau ;
- aucune glissade codée ;
- aucun movement effect produit ;
- aucune migration legacy ;
- aucun filtre surfacePresetId dans MapGameplayZone.

## 26. ctx stats

Commande exécutée :

```bash
ctx stats
```

Résultat exact :

```text
Exit code: 127

stdout:


stderr:
/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/.ctx-mode-EdXKo1/script.sh: line 1: ctx: command not found
```

Résumé compact :

- Context Mode MCP utilisé agressivement.
- Audits indexés les plus importants : 2 092.1 KB, 50.5 KB, 32.2 KB, 9.5 KB.
- Tests relancés via Context Mode avec extraction des lignes finales.
- La commande shell finale `ctx stats` n'était pas disponible.

## 27. Limites restantes

- Pas encore de `GameplayZoneKind.movementEffect`.
- Pas encore de `MovementEffectZonePayload`.
- Pas encore de sérialisation JSON pour un movement effect persistant.
- Pas encore de production runtime de `GameplayMovementEffect.slide`.
- Pas encore de stratégie d'arrêt de glissade.
- Pas encore de lien éditeur Surface ice vers GameplayZone.
- Pas encore de smoke `PlayableMapGame` pour movement effects.
- La mise à jour des switches éditeur devra être bornée dans le lot modèle.

## 28. Auto-critique

- Est-ce que la source gameplay future pour ice slide est décidée ? Oui : zone gameplay typée dédiée, cible `GameplayZoneKind.movementEffect` + payload explicite.
- Est-ce que SpecialZonePayload a été évalué honnêtement ? Oui : acceptable comme seam privé, rejeté comme source produit.
- Est-ce que SurfaceLayer direct gameplay est rejeté ou accepté ? Rejeté, car cela violerait la séparation Surface visuelle / GameplayZone.
- Est-ce que MovementZonePayload est rejeté ou accepté ? Rejeté pour ice slide, car il représente un gate/mode de déplacement, pas un effet de mouvement.
- Est-ce que le besoin d'un payload explicite movement effect est décidé ? Oui.
- Est-ce que l'impact JSON / manifest est audité ? Oui : `MapGameplayZone` est Freezed/JSON et `gameplayZones` est sérialisé.
- Est-ce que le prochain lot recommandé est explicite ? Oui : Lot 116 — MovementEffectZonePayload Model V0.
- Est-ce qu'aucun code de production n'a été modifié ? Oui.
- Est-ce que les tests de clôture ont été relancés ? Oui.
- Est-ce que Context Mode a été utilisé agressivement ? Oui.
- Est-ce que ctx stats est inclus ? Oui, avec l'échec shell documenté.
- Est-ce que le contenu complet des fichiers créés/modifiés est copié dans le rapport ? Oui pour les fichiers modifiés, il n'y en a aucun ; le rapport n'est pas recopié dans lui-même par exception explicite.
- Est-ce qu'un Lot 115-bis est nécessaire ? Non. La décision est assez claire pour ouvrir un lot modèle dédié.

## 29. Regard critique sur le prompt

Le prompt impose la bonne retenue : après avoir ajouté le siège passager `movementEffect`, il aurait été tentant de brancher ice via `scriptKey` pour aller vite. L'audit montre que ce serait une dette produit.

Le point le plus important pour le prochain lot est de ne pas sous-estimer le coût d'un nouveau kind : Freezed, JSON, tests, validators et switches éditeur seront touchés. Ce n'est pas dangereux si c'est borné, mais ce n'est pas un micro-changement.
