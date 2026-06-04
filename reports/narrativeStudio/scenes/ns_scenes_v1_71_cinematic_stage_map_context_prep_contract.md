# NS-SCENES-V1-71 — Cinematic Stage / Map Context Prep Contract

## 1. Résumé exécutif

V1-71 définit où se passe une cinématique. V1-71 ne l'affiche pas encore en jeu.

Ce lot est strictement documentaire. Il cadre le futur contexte de stage avant toute preview réelle : map cible, mode de décor, acteurs présents, bindings vers joueur/entités/cinematic-only, positions initiales, cibles de déplacement map-aware, diagnostics et trajectoire d'implémentation.

Décision : retenir une option hybride. Le contexte stage par défaut doit vivre côté `CinematicAsset`, parce que la Cinematics Library et le Cinematic Builder doivent pouvoir diagnostiquer et préparer une preview sans dépendre d'une Scene ou d'un Event. Les overrides Scene/Event restent possibles plus tard, mais hors V0.

Adaptation d'audit importante : `CinematicAsset.mapId` existe déjà. Le futur V1-72 ne doit donc pas créer deux IDs de map concurrents. Il doit soit traiter ce champ existant comme l'ancre Stage Map V0, soit migrer explicitement sa responsabilité dans un objet `stageContext` compatible. Dans tous les cas, `mapId` seul ne suffit pas : il manque encore `backdropMode`, actor bindings, initial placements et movement target bindings.

## 2. Gate 0

Commande `pwd` :

```text
/Users/karim/Project/pokemonProject
```

Commande `git branch --show-current` :

```text
main
```

Commande `git status --short --untracked-files=all` :

```text
<vide>
```

Commande `git diff --stat` :

```text
<vide>
```

Commande `git diff --name-only` :

```text
<vide>
```

Commande `git log --oneline -n 15` :

```text
edf3d1bd feat(narrative): add cinematic timeline duration validation diagnostics polish v0 (NS-SCENES-V1-70)
875404af feat(narrative): add cinematic timeline duration resize handles v0 (NS-SCENES-V1-69)
263233b4 feat(narrative): add cinematic timeline duration inspector editing v0 (NS-SCENES-V1-68)
c8bb19a2 feat(narrative): add cinematic timeline duration editing resize prep contract (NS-SCENES-V1-67)
e67e71c7 feat(narrative): add cinematic timeline mouse probe help selection explanation v0 (NS-SCENES-V1-66)
46cc0eb4 feat(narrative): add cinematic timeline mouse probe UX polish clear controls v0 (NS-SCENES-V1-65)
95e79063 feat(narrative): add cinematic timeline mouse probe boundary snap v0 (NS-SCENES-V1-64)
86004392 feat(narrative): add cinematic timeline mouse probe polish boundary snap prep v0 (NS-SCENES-V1-63)
79414165 feat(narrative): add cinematic timeline mouse time probe playhead drag v0 (NS-SCENES-V1-62)
044155fc feat(narrative): add cinematic timeline mouse playhead scrub prep contract (NS-SCENES-V1-61)
32f92c54 feat(narrative): add cinematic timeline keyboard navigation polish help overlay v0 (NS-SCENES-V1-60)
ede69519 feat(narrative): add cinematic timeline lane vertical navigation v0 (NS-SCENES-V1-59)
e1e83cd9 feat(narrative): add cinematic timeline lane vertical navigation prep contract (NS-SCENES-V1-58)
26958d88 feat(narrative): add cinematic timeline keyboard navigation selection polish v0 (NS-SCENES-V1-57)
af8a3bf9 feat(narrative): add cinematic timeline bar geometry duration scale correction v0 (NS-SCENES-V1-56)
```

Le working tree était propre au Gate 0.

## 3. Fichiers lus

Instructions et prompt : `AGENTS.md`, `agent_rules.md`, `skills/README.md`, `skills/writing-plans/SKILL.md`, `skills/verification-before-completion/SKILL.md`, prompt V1-71.

Roadmaps et rapports : `reports/narrativeStudio/scenes/road_map_scenes.md`, `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`, rapports V1-70, V1-69, V1-68, V1-67, V1-50, V1-49, V1-41 et V1-37.

Core cinematic : `packages/map_core/lib/src/models/cinematic_asset.dart`, `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`, `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`, `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart`, `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`.

Core map/project : `packages/map_core/lib/src/models/project_manifest.dart`, `packages/map_core/lib/src/models/map_data.dart`, `packages/map_core/lib/src/models/map_event_definition.dart`, `packages/map_core/lib/src/models/map_entity_payloads.dart`, `packages/map_core/lib/src/models/geometry.dart`, `packages/map_core/lib/src/collision/player_collision_conventions_v1.dart`.

Editor audit : recherches ciblées dans `packages/map_editor/lib` autour de `MapEditor`, `MapWorkspace`, `EntityPropertiesPanel`, `EventPropertiesPanel`, `MapEntity`, `MapEventDefinition`, `mapId`, `entityId` et `eventId`.

## 4. Pourquoi ce lot existe maintenant

Les lots V1-51 à V1-70 ont solidifié la timeline cinematic : barres proportionnelles, curseur de sélection, repère souris, snap, aide, édition de durée, resize droit et diagnostics de durée. Le Builder ressemble maintenant à un outil d'authoring visuel.

Mais une question produit reste ouverte : où se passe la cinématique ?

Aujourd'hui on peut authorer des acteurs requis, des orientations et des déplacements vers des cibles cinematic abstraites. On ne sait pas encore dire si la cinématique est liée à une map du projet, si un acteur représente le joueur, une entité de map ou un personnage purement cinematic, ni où ces acteurs commencent dans une future preview.

V1-71 existe pour cadrer ce verrou avant de coder un modèle qui deviendrait coûteux à corriger.

## 5. Pourquoi ce lot est documentaire

Le contexte stage touche plusieurs frontières : modèle cinematic, modèle map, entités, events, preview editor future et runtime cinematic futur. Coder directement créerait un risque de duplication de `mapId`, de binding trop runtime-aware, de picker map prématuré ou de preview faussement réelle.

Ce lot s'arrête donc à un contrat : concepts, options, décisions, diagnostics et tests futurs. Aucun modèle Dart, widget Flutter, runtime, test, screenshot ou générateur n'est modifié.

## 6. État actuel après V1-70

Déjà disponible :

- `CinematicAsset` canonique dans `map_core`.
- `ProjectManifest.cinematics`.
- `Cinematics Library` et `Cinematic Builder`.
- `requiredActors` pour lister les acteurs cinematic abstraits.
- `movementTargets` pour les cibles authoring stables.
- blocs `wait`, `fade`, `camera`, `actorFace`, `actorMove`.
- timeline par lanes, layout temporel dérivé, curseur, repère souris, snap, aides, duration editing, resize droit et diagnostics de durée.

Encore absent :

- contexte stage structuré ;
- map backdrop ;
- actor binding joueur / entité / cinematic-only ;
- position initiale actor-aware ;
- target binding map-aware ;
- preview réelle ;
- rendu d'acteurs ;
- lecture runtime cinematic visuelle map-aware.

## 7. Pass A — Audit CinematicAsset / requiredActors / movementTargets

`CinematicAsset` contient déjà :

- `id`, `title`, `description`, `storylineId`, `chapterId`;
- `mapId`;
- `tags`;
- `requiredActors: List<CinematicActorRef>`;
- `movementTargets: List<CinematicMovementTargetRef>`;
- `timeline`;
- `notes`, `metadata`, `legacyBridge`.

Constat clé : `mapId` est déjà sérialisé/désérialisé. Il peut servir d'ancre Stage Map V0, mais il ne définit pas le décor à afficher, les bindings d'acteurs, les positions initiales ni les sources map-aware des cibles.

`CinematicActorRef` est une référence authoring stable et lisible, mais abstraite. Elle dit qu'un acteur est requis par la cinématique ; elle ne dit pas si cet acteur est le joueur, une entité de map, un event, un acteur temporaire ou un acteur encore non bindé.

`CinematicMovementTargetRef` est aussi stable et lisible. V1-49 et V1-50 ont volontairement protégé ces cibles comme objets cinematic, avec labels, descriptions et usages. Elles ne doivent pas être supprimées ni remplacées par des IDs map directs.

## 8. Pass B — Audit actorMove et cibles authoring actuelles

`actorMove` pointe vers un `actorId` et un `targetId`. Le `actorId` doit correspondre à `requiredActors`; le `targetId` doit correspondre à `movementTargets`.

Le mode de chemin reste borné : pas de pathfinding, pas de collision, pas de runtime movement réel. La timeline dérive `startMs/endMs` à partir de la séquence linéaire et des `durationMs`.

Décision V1-71 : ne pas muter `actorMove`. Le bloc doit continuer de pointer vers `targetId`. La future liaison map-aware doit être une couche optionnelle attachée à la cible ou au stage context, pas un remplacement du step.

## 9. Pass C — Audit map/project model disponible

`ProjectManifest` contient déjà `maps: List<ProjectMapEntry>` et `cinematics: List<CinematicAsset>`.

`ProjectMapEntry` fournit `id`, `name`, `relativePath`, `groupId`, `role` et `sortOrder`. C'est suffisant pour vérifier qu'un `mapId` cinematic référence une map déclarée dans le projet.

`MapData` contient `id`, `name`, `size`, `tilesetId`, `layers`, `placedElements`, `entities`, `connections`, `warps`, `triggers`, `gameplayZones`, `mapMetadata`, `properties` et `events`.

Le modèle map donne donc des sources authoring réelles pour une future preview : dimensions de map, entités placées et events positionnés. Mais V1-71 ne les charge pas et ne les affiche pas.

## 10. Pass D — Audit map entities / NPC / events / spawn-like data

`MapEntity` contient `id`, `name`, `kind`, `pos`, `size`, `npc`, `sign`, `item`, `spawn`, `editorVisual`, `blocksMovement` et `properties`.

`MapEntityNpcData` donne un label métier (`displayName`), une direction (`facing`), un `visualElementId`, un `trainerId`, un `characterId`, du dialogue et des règles de mouvement/visibilité.

`MapEntitySpawnData` contient `spawnKey`, `role`, `facing` et `categoryTag`. C'est une source candidate pour plus tard, mais pas un binding V0 obligatoire.

`MapEventDefinition` contient `id`, `title`, `pages`, `position`, `type` et `metadata`. `EventPosition` donne `layerId`, `x`, `y`. Les events peuvent donc servir de cibles map-aware futures, mais leur sémantique est différente d'une entité visible.

Décision V0 : accepter `mapEntity` et `mapEvent` comme cibles map-aware conceptuelles, mais garder `mapEvent` hors actor binding V0. Les events sont de bons points/cibles, pas forcément des acteurs.

## 11. Pass E — Audit future preview requirements

Une preview réelle aura besoin de :

- savoir quelle map sert de backdrop ;
- savoir si le backdrop est absent ou vient d'une map projet ;
- résoudre les acteurs visibles ;
- connaître les positions initiales ;
- résoudre la position des cibles de déplacement ;
- lire la timeline dérivée ;
- afficher une caméra initiale ;
- dégrader proprement si le contexte est incomplet.

Ce qui manque maintenant n'est pas le playback, mais la résolution authoring. La preview doit pouvoir dire : map inconnue, acteur non bindé, position initiale manquante, cible utilisée mais non résolue.

## 12. Design Gate — Cinematic Stage / Map Context Prep Contract

1. Le Builder a besoin d'un contexte map/stage maintenant parce que la timeline est lisible, mais les acteurs et déplacements restent flottants sans décor ni source spatiale.
2. `CinematicAsset` existe déjà avec `mapId`, `requiredActors`, `movementTargets` et `timeline`.
3. `requiredActors` liste les acteurs cinematic abstraits requis, avec IDs stables, mais sans binding concret.
4. `movementTargets` liste des cibles authoring stables, labels et descriptions, mais sans source map.
5. Pour afficher une preview réelle il manque backdrop map, actor bindings, positions initiales, target bindings, caméra initiale et diagnostics readiness.
6. Pour savoir qui est l'acteur il manque un `CinematicActorBinding`.
7. Pour savoir où commence l'acteur il manque un `CinematicActorInitialPlacement`.
8. Le contexte stage par défaut doit vivre dans `CinematicAsset`; les overrides Scene/Event sont reportés.
9. Le contexte stage doit être optionnel en V0 pour préserver les drafts abstraits.
10. Oui, une cinématique peut exister sans map ; elle reste sandbox/abstraite.
11. Oui, une cinématique peut être globale ou abstraite, tant qu'elle n'annonce pas une preview réelle.
12. La map se choisit par référence à `ProjectManifest.maps`, jamais par données codées dans le produit.
13. Le joueur se représente par un binding `player`, unique en V0.
14. Un PNJ de map se représente par un binding `mapEntity`, résolu sur la map stage.
15. Un acteur cinematic-only se représente par un binding `cinematicOnly`, sans écriture map/runtime.
16. Un acteur non encore bindé se représente par `unbound`, autorisé en draft avec warning/readiness.
17. Les positions initiales se définissent par source nommée : entité map, cible de mouvement, point stage nommé ou unset.
18. Non, les coordonnées libres ne doivent pas être l'expérience V0 par défaut.
19. Oui, préférer points nommés, cibles cinematic, entities et events aux coordonnées libres.
20. Les `movementTargets` deviennent map-aware via un binding optionnel séparé, sans changer `actorMove.targetId`.
21. Une map inconnue devient `stageMapUnknown`, severity error si `mapId` est renseigné.
22. Un binding cassé devient `actorBindingMapEntityUnknown` ou diagnostic équivalent, severity error si la source déclarée est introuvable.
23. Une cible map-aware cassée devient `movementTargetBindingUnknownTarget`, `movementTargetBindingMapEntityUnknown` ou `movementTargetBindingMapEventUnknown`.
24. Les cibles abstraites existantes restent valides et protégées ; le binding map-aware est optionnel.
25. La future preview est préparée par diagnostics readiness, pas par rendu dans V1-71.
26. Le runtime cinematic V0 actuel reste inchangé ; le stage context est d'abord authoring/preview.
27. Le pathfinding est évité en gardant `pathMode` borné et en résolvant seulement des positions/cibles.
28. La dépendance à Map Editor UI est évitée : le contrat dépend de modèles core, pas de widgets editor.
29. La timeline libre est évitée : aucun `startMs/endMs` persistant, aucun drag/reorder/overlap authorable.
30. Prochain lot recommandé : `NS-SCENES-V1-72 — Cinematic Stage / Map Context Core Model V0`.

## 13. Concepts retenus

`CinematicStageContext` décrit le décor d'une cinématique : map cible éventuelle, mode de décor, acteurs présents, positions initiales et cibles utilisables par les blocs.

Il ne décrit pas le runtime playback complet, la timeline, les consequences gameplay, les triggers de Scene ou l'exécution map.

`Stage Map` désigne la map projet utilisée comme référence authoring/preview. En V0 elle reste optionnelle. Si elle est absente, la cinématique reste authorable mais la preview réelle doit se désactiver ou se dégrader.

`Actor Binding` relie un acteur cinematic abstrait à une source concrète ou semi-concrète : joueur, entité de map, acteur cinematic-only ou non bindé.

`Initial Placement` décrit où l'acteur apparaît au début de la preview/cinematic. V0 doit privilégier les sources nommées plutôt que la saisie libre de coordonnées.

`Map-aware Movement Target` désigne une cible cinematic stable qui peut être liée à une source map. La cible garde son `targetId`; le binding ajoute la résolution spatiale.

## 14. Options de Stage Context comparées

### Pass F — Options de Stage Context

Option A — pas de stage context encore.

- Avantage : aucun risque modèle.
- Inconvénient : preview réelle impossible, acteurs flottants, cibles non liées au monde.
- Verdict : rejetée, car V1-70 a rendu le Builder assez mûr pour cadrer ce manque.

Option B — stage context minimal dans `CinematicAsset`.

- Avantage : cinématique autonome, diagnostics Library/Builder simples, preview future directe.
- Inconvénient : modèle plus riche, risque de mélanger authoring/runtime si mal borné.
- Verdict : bonne base, mais insuffisante pour la réutilisation future.

Option C — stage context porté par Scene/CinematicNode.

- Avantage : une même cinématique peut être jouée dans des contextes différents.
- Inconvénient : preview standalone moins claire, bindings dispersés, complexité prématurée.
- Verdict : à garder comme override futur, pas V0.

Option D — stage context porté par MapEvent.

- Avantage : proche du déclencheur runtime.
- Inconvénient : couple Cinematic à Event, mauvais pour la Library, trop étroit.
- Verdict : rejetée pour le défaut V0.

Option E — hybride : défaut dans `CinematicAsset`, overrides futurs dans Scene/Event.

- Avantage : bon pour Builder/Library/preview, progressif, compatible réutilisation future.
- Inconvénient : exige de ne pas coder les overrides tout de suite.
- Verdict : retenue.

## 15. Option recommandée

Option E est retenue avec adaptation d'audit : le `mapId` déjà présent dans `CinematicAsset` doit être considéré dans le design V1-72.

Contrat de décision :

- `CinematicAsset` porte le contexte stage par défaut.
- `CinematicAsset.mapId` ne doit pas être dupliqué sans migration explicite.
- Scene/Event overrides restent hors V0.
- La Library et le Builder peuvent diagnostiquer un contexte incomplet.
- Les drafts abstraits restent autorisés.

## 16. Contrat recommandé Stage Context V0

### Pass G — Contrat recommandé Stage Context V0

Modèle conceptuel futur :

```text
CinematicStageContext
  mapId?: String
  backdropMode: none | projectMap
  actorBindings: List<CinematicActorBinding>
  initialPlacements: List<CinematicActorInitialPlacement>
  movementTargetBindings: List<CinematicMovementTargetBinding>
```

Point de vigilance V1-72 : si `mapId` reste au niveau `CinematicAsset`, alors `CinematicStageContext.mapId` ne doit pas créer une seconde source de vérité. Le rapport recommande de traiter `CinematicAsset.mapId` comme ancre Stage Map V0 et d'ajouter le reste du contrat autour de cette ancre.

`mapId` :

- optionnel en V0 ;
- référence une entrée de `ProjectManifest.maps` si présent ;
- si absent, la preview réelle reste indisponible ou sandbox ;
- erreur si renseigné mais inconnu.

`backdropMode` :

- `none` ;
- `projectMap`.

Interdits V0 : image externe, URL, asset path manuel, fichier arbitraire.

## 17. Contrat recommandé Actor Binding V0

### Pass H — Contrat recommandé Actor Binding V0

Types V0 :

- `player` : un acteur cinematic représente le joueur ; un seul binding player par cinématique.
- `mapEntity` : un acteur cinematic représente une entité de la map stage.
- `cinematicOnly` : un acteur existe uniquement pour la cinématique, sans écriture map/runtime.
- `unbound` : un acteur reste non lié pendant le draft.

Types reportés :

- `mapEvent` comme acteur ;
- `runtimeSpawn` ;
- `partyMember` ;
- `battleTrainer` ;
- `dynamicNpc`.

Règles no-code :

- les pickers futurs doivent afficher label lisible, type et ID secondaire discret ;
- un changement de map doit invalider/diagnostiquer les bindings mapEntity cassés ;
- un actor required non bindé ne bloque pas l'authoring, mais bloque ou dégrade la preview réelle ;
- cinematic-only ne crée aucune entité dans la map.

## 18. Contrat recommandé Initial Placement V0

Options V0 :

- `fromMapEntity` : utiliser la position de l'entité bindée ;
- `fromMovementTarget` : utiliser une cible cinematic existante ;
- `namedStagePoint` ou `cinematicOnlyTarget` : utiliser un point nommé du stage cinematic ;
- `unset` : autorisé en draft, warning/readiness pour preview.

Options reportées :

- coordonnées libres saisies directement ;
- position runtime actuelle ;
- point de pathfinding ;
- zone aléatoire ;
- spawn runtime dynamique.

Pourquoi éviter les coordonnées libres en V0 : elles sont peu no-code, fragiles selon taille de tiles/map et donnent une fausse précision avant que la preview réelle existe.

## 19. Contrat recommandé Movement Targets Map-aware V0

### Pass I — Contrat recommandé Movement Targets Map-aware V0

Les `movementTargets` actuelles restent la source stable pour `actorMove.targetId`.

Ajouter conceptuellement une couche optionnelle :

```text
CinematicMovementTargetBinding
  targetId: String
  targetKind: abstractPoint | mapEntity | mapEvent | namedStagePoint
  sourceId?: String
```

Règles :

- `actorMove` continue de pointer vers `targetId` ;
- les labels/descriptions/usages V1-49/V1-50 restent valides ;
- une cible utilisée peut rester abstraite ;
- si une preview réelle est demandée, une cible utilisée mais non résolue produit un diagnostic readiness ;
- `mapEntity` et `mapEvent` nécessitent une map stage résolue.

Reportés : coordonnées libres, path nodes, zones/polygones, target runtime dynamique.

## 20. Diagnostics futurs recommandés

Diagnostics stage :

- `stageMapUnknown` : error si `mapId` est renseigné mais absent de `ProjectManifest.maps`.
- `stageMapMissingForPreview` : warning/readiness si la preview réelle est demandée sans map stage.

Diagnostics actor binding :

- `actorBindingMissing` : warning en draft, bloque la preview réelle si acteur requis visible.
- `actorBindingMapEntityUnknown` : error si binding mapEntity pointe vers une entité absente.
- `actorBindingDuplicatePlayer` : error.
- `actorBindingRequiresStageMap` : error si mapEntity est déclaré sans map stage résolue.
- `actorInitialPlacementMissing` : warning en draft, readiness blocker pour preview.
- `actorInitialPlacementTargetUnknown` : error si la source déclarée est introuvable.

Diagnostics target binding :

- `movementTargetBindingUnknownTarget` : error.
- `movementTargetBindingMapEntityUnknown` : error.
- `movementTargetBindingMapEventUnknown` : error.
- `movementTargetBindingRequiresStageMap` : error pour source map-aware sans map stage.
- `movementTargetUsedButUnboundForPreview` : warning/readiness blocker selon mode preview.

Diagnostics preview readiness :

- `previewUnavailableNoStageMap` : warning/readiness.
- `previewUnavailableUnboundActors` : warning/readiness.
- `previewUnavailableMissingInitialPlacement` : warning/readiness.

Drafts autorisés : une cinématique sans map, avec acteur unbound ou placement unset, reste authorable. Elle ne doit simplement pas promettre une preview réelle complète.

## 21. Relation avec preview future

La preview future aura besoin de :

- map backdrop ;
- caméra initiale ;
- acteurs visibles ;
- positions initiales ;
- facing ;
- positions des movement targets ;
- timeline time/layout dérivé.

V1-71 ne code aucun rendu. Roadmap preview recommandée :

1. Stage Context core.
2. Editor Stage/Actor Binding.
3. Readiness diagnostics visibles.
4. Map Backdrop Preview.
5. Actor Display Preview.
6. Playback local editor.

## 22. Relation avec runtime cinematic

Le Stage Context est d'abord un contrat authoring/preview. Il pourra plus tard alimenter le runtime cinematic, mais V1-71 ne branche rien.

Interdits confirmés :

- mutation `GameState` ;
- spawn runtime ;
- téléportation ;
- déplacement runtime réel ;
- pathfinding ;
- combat ;
- conséquence gameplay ;
- modification d'adapter runtime.

## 23. Relation avec duration/timeline

Le Stage Context ne change rien à :

- `durationMs` ;
- resize droit ;
- validation durée ;
- timeline linéaire ;
- `startMs/endMs` dérivés ;
- repère souris ;
- aides timeline ;
- transports disabled.

Ce lot pivote vers map/acteurs sans transformer la timeline en timeline libre.

## 24. Non-objectifs confirmés

Confirmé :

- pas de code Dart produit ;
- pas de widget Flutter ;
- pas de modification package ;
- pas de modification `CinematicAsset` ;
- pas de modification `ProjectManifest` ;
- pas de modification `MapData` ;
- pas de map picker ;
- pas d'actor binding codé ;
- pas de preview réelle ;
- pas de runtime cinematic map-aware ;
- pas de playback ;
- pas de timer/ticker/controller ;
- pas de seek/scrub ;
- pas de pathfinding ;
- pas de collision ;
- pas de warp ;
- pas de screenshot ;
- pas de build_runner ;
- pas d'outil image IA ;
- pas de données produit codées.

## 25. Roadmap post V1-71

### Pass J — Tests futurs requis

V1-72 — Stage / Map Context Core Model V0 :

- `serializes cinematic stage context with optional mapId`
- `diagnoses unknown stage map`
- `allows cinematic without stage map as draft`
- `serializes actor binding player`
- `serializes actor binding mapEntity`
- `serializes actor binding cinematicOnly`
- `diagnoses unknown actor binding target`
- `diagnoses duplicate player actor binding`
- `serializes initial placement from movement target`
- `diagnoses missing initial placement for preview readiness`
- `serializes movement target binding mapEntity`
- `diagnoses movement target binding unknown target`
- `does not modify timeline steps when stage context changes`
- `does not modify durationMs/startMs/endMs`

V1-73 — Stage / Map Context Editor V0 :

- `shows map picker in Cinematic Builder`
- `selects project map as stage context`
- `clears invalid actor bindings when map changes only with explicit confirmation`
- `shows actor binding section`
- `binds actor to player`
- `binds actor to map entity`
- `marks actor as cinematic-only`
- `shows initial placement picker`
- `shows movement target binding picker`
- `does not expose raw JSON`
- `does not mutate timeline steps`
- `does not enable preview playback`

V1-74+ — Preview Prep :

- `preview readiness reports missing map`
- `preview readiness reports unbound actor`
- `preview readiness reports missing initial placement`
- `map backdrop preview uses selected stage map`
- `actor display preview uses actor bindings`
- `no runtime GameState mutation`

### Pass K — Roadmap post V1-71

Prochain lot exact recommandé :

```text
NS-SCENES-V1-72 — Cinematic Stage / Map Context Core Model V0
```

Objectif : implémenter le modèle authoring minimal du Stage Context dans `CinematicAsset` ou autour de son `mapId` existant, avec `backdropMode`, actor bindings, initial placements, movement target bindings et diagnostics core. Sans UI lourde, sans preview réelle et sans runtime.

Correction roadmap : l'ancien `NS-SCENES-V1-72 — Cinematic Timeline Scroll / Visibility Polish V0` est déplacé explicitement en `NS-SCENES-V1-80 — Cinematic Timeline Scroll / Visibility Polish V0`.

## 26. Commandes exécutées

Commandes Gate 0 exécutées avant modification :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 15
```

Commandes d'audit exécutées :

```bash
rg -n "class .*Map|MapData|MapEventDefinition|MapEntity|Npc|Spawn|spawn|mapId|entityId|eventId" packages/map_core packages/map_editor
rg -n "ProjectManifest.*maps|maps:" packages/map_core
rg -n "EntityPropertiesPanel|EventPropertiesPanel|MapEditor|MapWorkspace" packages/map_editor
sed -n '1,260p' packages/map_core/lib/src/models/cinematic_asset.dart
sed -n '1,260p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '1,260p' packages/map_core/lib/src/models/map_data.dart
sed -n '1,260p' packages/map_core/lib/src/models/map_event_definition.dart
sed -n '1,260p' packages/map_core/lib/src/models/map_entity_payloads.dart
```

Commandes de validation finale :

```bash
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --name-only -- packages
rg -n "CinematicStageContext|StageContext|actorBinding|initialPlacement|movementTargetBinding|backdropMode|stageMap|previewReady" packages/map_core packages/map_editor || true
rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|playCinematic|runtimePreview|previewRuntime|startPlayback|seek|scrub|scrubber|Timer\\(|Ticker|AnimationController|isPlaying|currentTimeMs|playbackTimeMs" reports/narrativeStudio/scenes/ns_scenes_v1_71_cinematic_stage_map_context_prep_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
rg -n "gpt-image-2|image_generation|generate image|AI image|image model" reports/narrativeStudio/scenes/ns_scenes_v1_71_cinematic_stage_map_context_prep_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" reports/narrativeStudio/scenes/ns_scenes_v1_71_cinematic_stage_map_context_prep_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
```

Sortie `git diff --check` :

```text
<vide>
```

Sortie `git diff --stat` :

```text
 .../scenes/road_map_scene_builder_authoring.md     | 21 +++++++++++++---
 reports/narrativeStudio/scenes/road_map_scenes.md  | 29 +++++++++++++++++-----
 2 files changed, 41 insertions(+), 9 deletions(-)
```

Sortie `git diff --name-only` :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Note Git : le rapport V1-71 est un fichier nouveau non suivi. Conformément à l'interdiction de `git add`, il apparaît dans `git status --short --untracked-files=all`, mais pas dans `git diff --stat` ni `git diff --name-only`.

Sortie `git status --short --untracked-files=all` :

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_71_cinematic_stage_map_context_prep_contract.md
```

## 27. Checks anti-scope

Sortie `git diff --name-only -- packages` :

```text
<vide>
```

Sortie recherche anti-code stage context dans packages :

```text
<vide>
```

Interprétation : aucun fichier package n'est modifié et aucune nouvelle occurrence Stage Context n'est introduite dans `packages/map_core` ou `packages/map_editor`.

Sortie recherche anti-runtime dans les modifications documentaires :

```text
Sortie non vide, composée uniquement d'occurrences documentaires dans le rapport V1-71 et d'occurrences historiques dans les roadmaps.
Les matches V1-71 portent sur le Gate 0 historique, les non-objectifs, la commande de vérification, les hunks de roadmap reproduits et l'auto-review.
Les matches roadmaps portent sur des lots passés V1-26 à V1-70 et sur leurs limites documentées.
```

Interprétation : les occurrences sont documentaires, dans les non-objectifs, relations ou commandes de vérification. Aucun code runtime n'est ajouté.

Sortie recherche anti-image IA :

```text
Sortie non vide uniquement parce que la commande de vérification anti-image IA est elle-même inscrite dans le rapport V1-71.
```

Interprétation : les occurrences éventuelles sont des interdictions anti-scope. Aucun outil image IA n'a été appelé.

Sortie recherche anti-données produit nommées :

```text
Sortie non vide, composée uniquement d'occurrences historiques ou anti-scope dans les roadmaps et dans les hunks reproduits du rapport V1-71.
Les matches V1-71 correspondent à la commande de vérification et aux limites de roadmap reproduites.
Les matches roadmaps correspondent aux anciennes mentions de golden slice, aux interdictions de hardcode et aux limites "pas de données produit".
```

Interprétation : les occurrences éventuelles sont historiques ou anti-scope dans les roadmaps/rapports. Aucun seed ni donnée produit n'est ajouté.

## 28. Evidence Pack

Fichiers modifiés par V1-71 :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_71_cinematic_stage_map_context_prep_contract.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Hunks complets des roadmaps modifiées :

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index 37d83d72..fd00d5be 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande
 
 ```text
-NS-SCENES-V1-71 — Cinematic Stage / Map Context Prep Contract
+NS-SCENES-V1-72 — Cinematic Stage / Map Context Core Model V0
 ```
 
 ## Principes
@@ -104,8 +104,9 @@ NS-SCENES-V1-71 — Cinematic Stage / Map Context Prep Contract
 | NS-SCENES-V1-68 | Cinematic Timeline Duration Inspector Editing V0 | editor / authoring | Ajouter l'edition no-code de `durationMs` depuis l'inspecteur pour les blocs authoring-owned supportes. | Pas de resize souris, pas de drag de bloc, pas de playback, pas de seek runtime, pas de timeline libre, pas de `startMs/endMs` persistants. | Builder cinematics, operations authoring core, tests widget/core cibles, rapport, screenshot. | DONE : presets courts, champ numerique borne, +/-100, validation min/max core, `actorFace.durationMs`, recalcul layout derive, clear probe apres acceptation, non-owned non editables. | Ouvrir trop de blocs non possedes ; exposer JSON/IDs ; faire croire a un playback. | DONE : durees editables depuis l'inspecteur, non-mutation runtime, transports disabled. | V1-67. |
 | NS-SCENES-V1-69 | Cinematic Timeline Duration Resize Handles V0 | editor / authoring | Ajouter un handle de resize uniquement sur le bord droit des barres editables, reutilisant les bornes et validations V1-68. | Pas de drag du bloc entier, pas de bord gauche, pas de changement de lane, pas de reorder, pas de playback, pas de `startMs/endMs` persistants. | Builder cinematics, tests widget drag/resize, rapport, screenshot si lot UI. | DONE : handle droit sur selection editable, augmentation/diminution, clamp min/max, snap 100 ms, clear probe, selection preservee, non-owned et marker sans handle. | Hit testing trop large ; confusion avec probe souris ; casser les proportions de timeline. | DONE : resize borne et lisible, sans timeline libre. | V1-68. |
 | NS-SCENES-V1-70 | Cinematic Timeline Duration Validation / Diagnostics Polish V0 | editor / ui-polish | Consolider les messages d'erreur, bornes, feedback no-code et diagnostics autour de l'edition/resize de duree. | Pas de nouveau modele temporel, pas de playback, pas de seek runtime, pas de timeline libre, pas de drag/reorder de blocs. | Builder cinematics, diagnostics core, tests widget/core, rapport, screenshot. | DONE : aide bornes min/max/pas 100 ms, erreurs inline, feedback clamp, non-editables expliques, diagnostics duree renforces, Visual Gate. | Dupliquer la validation core ; transformer le polish en nouveau pouvoir de montage. | DONE : edition de duree plus explicite, sans elargir le contrat V1-68/V1-69. | V1-69. |
-| NS-SCENES-V1-71 | Cinematic Stage / Map Context Prep Contract | doc / interaction-contract | Cadrer le contexte de scene cinematic avant preview reelle : map cible, decor, acteurs, bindings, positions initiales, cibles map-aware. | Pas de preview reelle, pas de runtime cinematic map-aware, pas de playback, pas de pathfinding, pas de mutation gameplay, pas de donnees Selbrume codees. | Rapport V1-71, roadmaps, audit contrats map/actors si necessaire. | TODO : contrat clair, options comparees, limites runtime/authoring, tests futurs. | Confondre contexte stage avec runtime preview ; coder les bindings trop tot ; hardcoder le golden slice. | TODO : prochain verrou produit map/acteurs/context explicite avant implementation. | V1-70. |
-| NS-SCENES-V1-72 | Cinematic Timeline Scroll / Visibility Polish V0 | editor / ui-polish | Backlog futur : polir la visibilite des blocs/repere/selection quand les interactions clavier ou souris placent l'element cible hors de la vue utile. | Pas de playback, seek runtime, scrubber runtime, transport fonctionnel, drag/resize/reorder, mutation JSON, runtime, zoom temporel ou changement de modele. | Builder cinematics, tests widget, rapport, screenshot. | TODO : scroll automatique/visibilite controles, proportions timeline preservees, selection/probe non mutants. | Casser les proportions visees ; confondre scroll de vue et navigation temporelle ; ajouter un pouvoir de montage. | TODO : visibilite plus fiable, sans nouveau pouvoir temporel. | V1-69 ou lot de polish dedie. |
+| NS-SCENES-V1-71 | Cinematic Stage / Map Context Prep Contract | doc / interaction-contract | Cadrer le contexte de scene cinematic avant preview reelle : map cible, decor, acteurs, bindings, positions initiales, cibles map-aware. | Pas de preview reelle, pas de runtime cinematic map-aware, pas de playback, pas de pathfinding, pas de mutation gameplay, pas de donnees Selbrume codees. | Rapport V1-71, roadmaps, audit contrats map/actors. | DONE : option hybride retenue, mapId/backdropMode, actor bindings, initial placements, movement target bindings, diagnostics et tests futurs cadres. | Confondre contexte stage avec runtime preview ; coder les bindings trop tot ; hardcoder le golden slice. | DONE : prochain verrou produit map/acteurs/context explicite avant implementation. | V1-70. |
+| NS-SCENES-V1-72 | Cinematic Stage / Map Context Core Model V0 | core / authoring | Implementer le modele authoring minimal du Stage Context dans CinematicAsset : mapId optionnel, backdropMode, actorBindings, initialPlacements, movementTargetBindings et diagnostics core. | Pas d'UI lourde, pas de preview reelle, pas de runtime cinematic map-aware, pas de playback, pas de pathfinding, pas de donnees Selbrume codees. | `cinematic_asset.dart`, diagnostics cinematic, tests JSON/diagnostics/authoring, rapport. | TODO : serialization, diagnostics stage/bindings/targets, drafts autorises, aucune mutation timeline. | Dupliquer `mapId` existant ; coder la preview trop tot ; bloquer les cinematics abstraites. | TODO : contrat V1-71 materialise en modele core minimal et diagnostiquable. | V1-71. |
+| NS-SCENES-V1-80 | Cinematic Timeline Scroll / Visibility Polish V0 | editor / ui-polish | Backlog futur : polir la visibilite des blocs/repere/selection quand les interactions clavier ou souris placent l'element cible hors de la vue utile. | Pas de playback, seek runtime, scrubber runtime, transport fonctionnel, drag/resize/reorder, mutation JSON, runtime, zoom temporel ou changement de modele. | Builder cinematics, tests widget, rapport, screenshot. | TODO : scroll automatique/visibilite controles, proportions timeline preservees, selection/probe non mutants. | Casser les proportions visees ; confondre scroll de vue et navigation temporelle ; ajouter un pouvoir de montage. | TODO : visibilite plus fiable, sans nouveau pouvoir temporel. | Backlog post stage/map context. |
 
 ## Mise a jour V1-66
 
@@ -1090,6 +1091,20 @@ Limites : pas de nouveau modele temporel, pas de changement de bornes/pas, pas d
 
 Prochain lot exact recommande : `NS-SCENES-V1-71 — Cinematic Stage / Map Context Prep Contract`.
 
+## Mise a jour V1-71
+
+Statut : `NS-SCENES-V1-71 — Cinematic Stage / Map Context Prep Contract` est DONE.
+
+Decision : V1-71 est documentaire et retient une option hybride : `CinematicAsset` porte le contexte stage par defaut pour rendre la Library/Builder/previews futures comprehensibles, tandis que les overrides Scene/Event restent un futur explicite. L'audit note que `CinematicAsset.mapId` existe deja, mais reste insuffisant seul pour une preview reelle.
+
+Contrat retenu : map cible optionnelle, `backdropMode` `none | projectMap`, actor bindings V0 `player | mapEntity | cinematicOnly | unbound`, initial placements par source nommee, movement target bindings map-aware optionnels et diagnostics previews/readiness sans bloquer les drafts abstraits.
+
+Preuve : rapport V1-71, Gate 0 propre, audit `CinematicAsset` / `requiredActors` / `movementTargets`, audit `MapData.entities`, `MapData.events`, `MapEntity.pos`, `MapEventDefinition.position`, `MapEntitySpawnData`, checks anti-scope et `git diff --check`.
+
+Limites : aucun code produit, package, test, modele JSON, map picker, actor binding code, preview reelle, runtime, pathfinding, screenshot, build_runner, image IA ou donnees Selbrume.
+
+Correction roadmap : `NS-SCENES-V1-72 — Cinematic Timeline Scroll / Visibility Polish V0` est deplace en backlog `NS-SCENES-V1-80 — Cinematic Timeline Scroll / Visibility Polish V0`. Le prochain lot exact devient `NS-SCENES-V1-72 — Cinematic Stage / Map Context Core Model V0`.
+
 ## Selbrume golden slice
 
 Avant le golden slice, il faut au minimum :
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 768e3d46..51ebd407 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -125,18 +125,19 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-68 — Cinematic Timeline Duration Inspector Editing V0 | DONE | Edition no-code de `durationMs` depuis l'inspecteur pour `wait`, `fade`, `camera`, `actorFace` et `actorMove`, avec validation core min/max, champ numerique, presets courts, +/-100 ms, recalcul layout derive, clear du probe apres acceptation, Visual Gate, sans resize, playback ni timeline libre. |
 | NS-SCENES-V1-69 — Cinematic Timeline Duration Resize Handles V0 | DONE | Handle droit uniquement sur les barres editables `wait`, `fade`, `camera`, `actorFace` et `actorMove`, visible sur selection, resize souris de `durationMs` via validations V1-68, quantification 100 ms, clamp min/max, clear probe, `selectedStepId` preserve, blocs suivants recalcules par layout derive, Visual Gate, sans drag de bloc, bord gauche, lane/reorder, playback, timeline libre ni `startMs/endMs` persistants. |
 | NS-SCENES-V1-70 — Cinematic Timeline Duration Validation / Diagnostics Polish V0 | DONE | Messages d'erreur, bornes min/max, pas 100 ms, feedback clamp resize, explication blocs non editables et diagnostics duree consolides, sans elargir le modele temporel. |
-| NS-SCENES-V1-71 — Cinematic Stage / Map Context Prep Contract | TODO | Cadrer map cible, decor, acteurs, bindings, positions initiales et cibles map-aware avant toute preview cinematic reelle. |
-| NS-SCENES-V1-72 — Cinematic Timeline Scroll / Visibility Polish V0 | TODO | Backlog futur : polir le scroll automatique et la visibilite des blocs/selection/probe apres les lots de duree, en preservant les proportions de timeline demandees par Karim. |
+| NS-SCENES-V1-71 — Cinematic Stage / Map Context Prep Contract | DONE | Contrat documentaire du futur contexte stage : option hybride retenue, mapId/backdropMode, actor bindings, positions initiales, targets map-aware, diagnostics futurs et roadmap post-V1-71 cadres sans code produit. |
+| NS-SCENES-V1-72 — Cinematic Stage / Map Context Core Model V0 | TODO | Implementer le modele authoring minimal du Stage Context dans CinematicAsset : mapId optionnel, backdropMode, actorBindings, initialPlacements, movementTargetBindings et diagnostics core, sans UI lourde ni preview reelle. |
+| NS-SCENES-V1-80 — Cinematic Timeline Scroll / Visibility Polish V0 | TODO | Backlog futur : polir le scroll automatique et la visibilite des blocs/selection/probe apres le cadrage stage/map, en preservant les proportions de timeline demandees par Karim. |
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-71 — Cinematic Stage / Map Context Prep Contract`
+`NS-SCENES-V1-72 — Cinematic Stage / Map Context Core Model V0`
 
-Raison : V1-70 ferme le polish duration autour de l'edition et du resize. Le prochain verrou produit est de cadrer le contexte cinematic map/stage avant toute preview reelle : map cible, decor, acteurs, bindings, positions initiales et cibles map-aware.
+Raison : V1-71 a tranche le contrat stage/map sans code produit. Le prochain verrou produit est de materialiser ce contrat dans le modele core authoring minimal, avec diagnostics, sans UI lourde, preview reelle ou runtime.
 
-Ordre apres V1-70 : `NS-SCENES-V1-71 — Cinematic Stage / Map Context Prep Contract`.
+Ordre apres V1-71 : `NS-SCENES-V1-72 — Cinematic Stage / Map Context Core Model V0`.
 
-Le lot `NS-SCENES-V1-67 — Cinematic Timeline Scroll / Visibility Polish V0` precedemment recommande est remplace par `NS-SCENES-V1-67 — Cinematic Timeline Duration Editing / Resize Prep Contract` et deplace en backlog futur comme `NS-SCENES-V1-72 — Cinematic Timeline Scroll / Visibility Polish V0`.
+Le lot `NS-SCENES-V1-67 — Cinematic Timeline Scroll / Visibility Polish V0` precedemment recommande est remplace par `NS-SCENES-V1-67 — Cinematic Timeline Duration Editing / Resize Prep Contract`, puis deplace en backlog futur. Il etait stocke comme `NS-SCENES-V1-72 — Cinematic Timeline Scroll / Visibility Polish V0`; V1-72 devient maintenant le modele core Stage/Map Context, et le polish scroll/visibility est deplace explicitement en `NS-SCENES-V1-80 — Cinematic Timeline Scroll / Visibility Polish V0`.
 
 Note : l'overview n'affiche plus `Facts — necessite un modele`; Facts et Regles du monde pointent maintenant vers des workspaces actifs.
 
@@ -154,6 +155,22 @@ Preuve : rapport V1-70, evidence pack, capture `reports/narrativeStudio/scenes/s
 
 Prochain lot exact : `NS-SCENES-V1-71 — Cinematic Stage / Map Context Prep Contract`.
 
+## Mise a jour V1-71
+
+Statut : `NS-SCENES-V1-71 — Cinematic Stage / Map Context Prep Contract` est DONE.
+
+Decision : V1-71 retient une option hybride : contexte stage par defaut porte par `CinematicAsset`, avec overrides Scene/Event futurs explicitement hors V0. L'audit confirme que `CinematicAsset.mapId` existe deja comme ancre map simple, mais qu'il manque encore un contrat structure pour `backdropMode`, actor bindings, initial placements et movement target bindings.
+
+Contrat recommande : `mapId` optionnel, `backdropMode` limite a `none | projectMap`, actor bindings V0 `player | mapEntity | cinematicOnly | unbound`, initial placements par source nommee (`fromMapEntity`, `fromMovementTarget`, `namedStagePoint`, `unset`) et movement target bindings optionnels vers `abstractPoint`, `mapEntity`, `mapEvent` ou `namedStagePoint`.
+
+Diagnostics futurs recommandes : map stage inconnue, map manquante pour preview, binding acteur absent/casse, double binding player, placement initial manquant/casse, target binding inconnu/casse et readiness preview indisponible. Les drafts restent authorables ; la preview reelle devra se desactiver ou degrader tant que le contexte n'est pas resolu.
+
+Limites : lot documentaire uniquement, aucun code produit, package, test, screenshot, build_runner, model JSON, picker map, actor binding code, preview reelle, runtime, pathfinding ou donnees Selbrume.
+
+Preuve : rapport `reports/narrativeStudio/scenes/ns_scenes_v1_71_cinematic_stage_map_context_prep_contract.md`, Gate 0 propre, audits core/map/editor documentes, checks anti-scope et `git diff --check` propre.
+
+Prochain lot exact : `NS-SCENES-V1-72 — Cinematic Stage / Map Context Core Model V0`.
+
 ## Mise a jour V1-51
 
 Statut : `NS-SCENES-V1-51 — Cinematic Timeline Time Axis / Bar Layout V0` est DONE.
```

Le rapport V1-71 est ce fichier. Il contient le Gate 0, les passes A-K, le Design Gate, les contrats recommandés, les diagnostics futurs, les tests futurs, les commandes exécutées, les checks anti-scope et l'auto-review.

## 29. Auto-review critique

1. V1-71 a-t-il modifié du code produit ? Non.
2. V1-71 a-t-il modifié un package ? Non.
3. V1-71 a-t-il modifié un test ? Non.
4. V1-71 a-t-il modifié `CinematicAsset` ? Non.
5. V1-71 a-t-il modifié `ProjectManifest` ? Non.
6. V1-71 a-t-il codé un map picker ? Non.
7. V1-71 a-t-il codé actor binding ? Non.
8. V1-71 a-t-il codé une preview réelle ? Non.
9. V1-71 a-t-il modifié le runtime ? Non.
10. V1-71 a-t-il ajouté playback/currentTimeMs/isPlaying ? Non.
11. V1-71 a-t-il ajouté pathfinding ? Non.
12. V1-71 a-t-il ajouté des données produit nommées ? Non.
13. Les options de Stage Context sont-elles comparées ? Oui.
14. L'option retenue est-elle claire ? Oui, Option E hybride.
15. Le contrat mapId/backdropMode est-il défini ? Oui.
16. Le contrat actor binding est-il défini ? Oui.
17. Le contrat initial placement est-il défini ? Oui.
18. Le contrat movement target map-aware est-il défini ? Oui.
19. Les diagnostics futurs sont-ils listés ? Oui.
20. La relation avec la preview future est-elle claire ? Oui.
21. La relation avec le runtime cinematic est-elle claire ? Oui.
22. Les tests futurs V1-72/V1-73 sont-ils listés ? Oui.
23. Le prochain lot exact est-il recommandé ? Oui, V1-72 Stage / Map Context Core Model V0.
24. L'Evidence Pack est-il complet sans placeholders ? Oui. Les recherches anti-runtime et anti-données nommées sont très verbeuses à cause des roadmaps historiques ; le rapport consigne leur interprétation exacte de scope plutôt que de créer une récursion de matches en recopiant leur sortie intégrale dans le fichier recherché.

Auto-critique : le point le plus sensible est la coexistence entre `CinematicAsset.mapId` et le futur `CinematicStageContext.mapId`. V1-72 devra traiter explicitement cette compatibilité pour éviter une double source de vérité.

## 30. Verdict final

V1-71 est DONE.

Le lot a produit un contrat stage/map complet sans modifier le code produit. Le prochain verrou recommandé est :

```text
NS-SCENES-V1-72 — Cinematic Stage / Map Context Core Model V0
```

Critères remplis : rapport créé, roadmaps mises à jour, options comparées, contrat mapId/backdropMode défini, actor bindings définis, initial placements définis, movement targets map-aware définies, diagnostics futurs listés, tests futurs listés, prochain lot recommandé, aucun package modifié.
