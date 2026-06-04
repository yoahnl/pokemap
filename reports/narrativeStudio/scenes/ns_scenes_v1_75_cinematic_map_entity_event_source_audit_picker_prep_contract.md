# NS-SCENES-V1-75 — Cinematic Map Entity/Event Source Audit / Picker Prep Contract

## 1. Résumé exécutif

V1-75 trouve les vraies sources `mapEntity` / `mapEvent`.
V1-75 ne sélectionne pas encore d’entités ou d’events.

Verdict : les entités et events fiables vivent dans `MapData`, pas dans `ProjectManifest.maps`. Le Cinematic Builder reçoit aujourd’hui uniquement `List<ProjectMapEntry>` via la Library, donc il peut choisir une map de scène mais ne peut pas encore lister ses `entities` ou `events`.

Recommandation : créer en V1-76 un catalogue pur `CinematicStageMapSourceCatalog` alimenté par une `MapData` fiable, idéalement obtenue côté éditeur via une lecture snapshot non destructive (`EditorNotifier.loadMapSnapshotById`) puis projetée par un helper sans Flutter. Les pickers actifs doivent attendre V1-77.

## 2. Gate 0

Commande exécutée depuis la racine avant modification :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 15
```

Sortie exacte :

```text
/Users/karim/Project/pokemonProject
main
fe619092 feat(narrative): add cinematic stage map context editor and diagnostics preview readiness polish v0 (NS-SCENES-V1-73-V1-74)
632e3747 feat(narrative): add cinematic stage map context core model v0 (NS-SCENES-V1-72)
e77212ff feat(narrative): add cinematic stage map context prep contract (NS-SCENES-V1-71)
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
```

Interprétation : `git status`, `git diff --stat` et `git diff --name-only` étaient vides avant V1-75. Les lots V1-73/V1-74 sont déjà intégrés dans le commit `fe619092`.

## 3. Fichiers lus

Instructions et roadmaps :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `skills/writing-plans/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_71_cinematic_stage_map_context_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_72_cinematic_stage_map_context_core_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_73_cinematic_stage_map_context_editor_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_73_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_74_cinematic_stage_context_diagnostics_preview_readiness_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_74_evidence_pack.md`

Core :

- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/read_models/facts_world_rules_manager_read_model.dart`

Editor :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/domain/repositories/repositories.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
- `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart`
- `packages/map_editor/lib/src/ui/panels/event_properties_panel.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `packages/map_editor/test/editor_notifier_map_snapshot_test.dart`
- `packages/map_core/test/cinematic_diagnostics_test.dart`
- `packages/map_core/test/cinematic_authoring_operations_test.dart`

## 4. Pourquoi ce lot existe maintenant

V1-73 a rendu le Stage Context éditable : map de scène, backdrop, actor bindings, placements initiaux et movement target bindings. V1-74 a rendu cette préparation lisible avec une checklist et des diagnostics humains.

Le verrou restant est volontaire : les options `mapEntity` et `mapEvent` sont visibles mais désactivées, parce que le Builder ne reçoit pas encore une source fiable `MapData.entities/events`.

## 5. Pourquoi ce lot est documentaire

Activer un picker sans source fiable créerait des références libres ou fausses. V1-75 devait donc répondre avant code :

- où vivent les entités et events réels ;
- comment charger la `MapData` sans changer de contexte utilisateur ;
- quel contrat pur donner au Builder ;
- quels diagnostics ajouter plus tard ;
- quel lot doit implémenter le catalogue puis les pickers.

Aucun package, test, widget, runtime, preview, screenshot ou outil image n’a été modifié par ce lot.

## 6. État actuel après V1-74

État confirmé :

- `CinematicAsset.mapId` est l’unique ancre Stage Map.
- `stageContext` ne contient pas `mapId`.
- `ProjectManifest.maps` alimente le picker de map.
- Le Builder affiche `mapEntity` et `mapEvent` mais les désactive avec messages honnêtes.
- La readiness affiche `Sources map-aware — À venir`.
- Les diagnostics core savent détecter les sources manquantes, mais pas encore les sources inconnues dans une `MapData`.

## 7. Pass A — Audit ProjectManifest.maps / ProjectMapEntry

Source auditée : `packages/map_core/lib/src/models/project_manifest.dart`.

Constat :

```text
ProjectManifest.maps: List<ProjectMapEntry>
ProjectMapEntry:
  id
  name
  relativePath
  groupId
  role
  sortOrder
```

`ProjectManifest.maps` est un catalogue metadata. Il ne contient ni layers, ni `entities`, ni `events`, ni taille, ni données de placement. Il donne l’id stable de la map, le label auteur et le chemin relatif permettant de charger la vraie `MapData`.

Conclusion : `ProjectManifest.maps` suffit pour choisir `CinematicAsset.mapId`, mais ne suffit pas pour un picker `mapEntity` ou `mapEvent`.

## 8. Pass B — Audit MapData et stockage des maps

Source auditée : `packages/map_core/lib/src/models/map_data.dart`.

Constat :

```text
MapData:
  id
  name
  size
  tilesetId
  layers
  placedElements
  entities: List<MapEntity>
  connections
  warps
  triggers
  gameplayZones
  mapMetadata
  properties
  events: List<MapEventDefinition>
```

Stockage et chargement côté editor :

- `MapRepository.loadMap(String path)` retourne une `MapData`.
- `FileMapRepository.loadMap` lit le JSON, migre via `migrateMapDataJson`, construit `MapData.fromJson`, puis valide.
- `LoadMapUseCase.execute(ProjectWorkspace fs, String relativePath)` résout `relativePath` via `fs.resolveMapPath`.
- `EditorNotifier.loadMapSnapshotById(mapId)` peut lire une map sans changer la map active.

Conclusion : la source fiable est `MapData`, chargée par `ProjectMapEntry.relativePath`. Le futur Builder ne doit pas lire le disque directement ; l’éditeur doit fournir une snapshot ou un catalogue.

## 9. Pass C — Audit entités de map

Source auditée : `MapData.entities` et `MapEntity`.

Champs utiles :

```text
MapEntity:
  id
  name
  kind
  pos
  size
  npc/sign/item/spawn/editorVisual
  blocksMovement
  properties
```

Labels no-code existants :

- `MapEntityDisplayX.inspectorHeadline` priorise `npc.displayName`, `sign.title`, `item.gameItemId`, `spawn.spawnKey`, puis `name`, puis `id`.
- Le read model World Rules utilise aussi `npc.displayName`, puis `name`, puis `id`.
- L’Entity Inspector affiche déjà les types `NPC`, `Sign`, `Item`, `Spawn`, `Custom`.

Stabilité :

- `MapEntity.id` est l’id stable à persister dans `CinematicActorBinding.mapEntityId` ou `CinematicMovementTargetBinding.sourceId`.
- `MapEntity.pos` et `size` donnent une position stable authoring.
- Le nom affiché peut changer ; il ne doit pas être la clé.

Recommandation V0 :

- Actor binding `mapEntity` : privilégier les entités visuelles avec identité stable et label affichable. En pratique V0 peut autoriser `npc` en premier choix, puis élargir aux autres `MapEntity` si le produit veut des acteurs non-PNJ.
- Movement target `mapEntity` : autoriser toute `MapEntity` avec position stable, en exposant le type et l’id en secondaire discret.

## 10. Pass D — Audit events de map

Source auditée : `MapData.events` et `MapEventDefinition`.

Champs utiles :

```text
MapEventDefinition:
  id
  title
  pages
  position
  type
  metadata

EventPosition:
  layerId
  x
  y
```

Labels no-code :

- Label primaire recommandé : `title` si non vide, sinon `id`.
- Id technique secondaire : `${mapId}:${event.id}`.
- Type secondaire possible : `actor`, `object`, `triggerZone`, `effect`.

Stabilité :

- `MapEventDefinition.id` est la clé stable.
- `EventPosition` donne une position authoring utilisable pour target.
- Les pages/conditions ne sont pas nécessaires pour un target V0.

Recommandation V0 :

- Ne pas lier un acteur directement à un event.
- Autoriser `mapEvent` seulement pour `movement target binding`.
- Un event positionné peut servir de point cible ; il ne doit pas devenir acteur V0.

## 11. Pass E — Audit Map Editor sources / panels / read models

Sources editor confirmées :

- `MapCanvas` lit `state.activeMap` et passe la `MapData` au painter.
- `MapGridPainter` parcourt `map.entities` et `map.events`.
- `EntityPropertiesPanel` parcourt `map.entities`.
- `EventPropertiesPanel` parcourt `map.events`.
- `FactsWorldRulesManagerReadModel` sait déjà construire des options `mapEntity`, `npcDialogue` et `mapEvent` à partir d’une liste de `MapData`.
- `EditorNotifier.loadMapSnapshotById` charge une map par id sans changer la map active.

Gaps :

- Le read model World Rules est orienté règles du monde, pas Stage Context cinematic.
- Les panels Map Editor sont des widgets UI, donc à ne pas importer dans le Builder.
- Le Builder ne doit pas dépendre du workspace map, de `MapCanvas` ou des panels.

Conclusion : réutiliser le modèle de projection pure est pertinent, mais avec un contrat dédié cinematic.

## 12. Pass F — Audit accès NarrativeWorkspaceCanvas / Cinematic Builder

Chemin actuel :

```text
NarrativeWorkspaceCanvas
  -> CinematicsLibraryWorkspace(project: ...)
  -> CinematicBuilderWorkspace(stageMaps: widget.project.maps)
```

Constat :

- `CinematicsLibraryWorkspace` instancie `CinematicBuilderWorkspace` avec `stageMaps: widget.project.maps`.
- `CinematicBuilderWorkspace` possède `final List<ProjectMapEntry> stageMaps`.
- Le Builder ne possède aucun champ `MapData`, aucun callback de chargement de source et aucun catalogue `entities/events`.
- Les boutons `Entité de map` et `Event de map` sont désactivés quand `asset.mapId` existe, avec message : le Builder ne reçoit pas encore les entités/events de la map.

Conclusion : le Builder ne peut pas lire les entités/events aujourd’hui. Il faudra lui passer un catalogue ou un état de source construit ailleurs.

## 13. Design Gate — Cinematic Map Entity/Event Source Audit / Picker Prep Contract

1. Pourquoi les options mapEntity/mapEvent sont-elles désactivées aujourd’hui ? Parce que le Builder reçoit seulement `ProjectMapEntry`, pas la `MapData`.
2. Que contient exactement ProjectManifest.maps ? Une liste de `ProjectMapEntry`.
3. ProjectManifest.maps contient-il MapData complet ou seulement des entrées metadata ? Seulement des entrées metadata.
4. Où vivent les entités d’une map ? Dans `MapData.entities`.
5. Où vivent les events d’une map ? Dans `MapData.events`.
6. Les entités/events ont-ils des IDs stables ? Oui : `MapEntity.id` et `MapEventDefinition.id`.
7. Les entités/events ont-ils des labels no-code ? Oui pour les entités via payload/name/id ; oui pour events via `title` puis id.
8. Les events ont-ils un nom lisible ou seulement un id ? Ils ont `title`; fallback id si vide.
9. Les entités/events sont-ils chargés en mémoire dans NarrativeWorkspaceCanvas ? Seulement si une `activeMap` est passée pour certains workspaces ; pas pour le Builder cinematic.
10. Le Cinematic Builder reçoit-il aujourd’hui MapData ? Non.
11. Faut-il passer MapData au Cinematic Builder ? Pas directement comme modèle brut principal ; mieux vaut passer un catalogue pur.
12. Faut-il créer un read model pur dédié ? Oui.
13. Faut-il réutiliser un read model Map Editor existant ? Seulement comme inspiration ; pas comme dépendance UI.
14. Comment éviter de coupler le Cinematic Builder à l’UI Map Editor ? Construire le catalogue hors widgets Map Editor, depuis `ProjectManifest + MapData`.
15. Comment éviter les IDs libres ? Utiliser un picker qui écrit uniquement des ids issus du catalogue.
16. Comment éviter les fake refs ? Ne jamais inventer d’options ; afficher `sources indisponibles` si la map ne charge pas.
17. Comment gérer une map stage absente ? Désactiver les options et demander de choisir une map de scène.
18. Comment gérer une map stage inconnue ? Garder `stageMapUnknown` et bloquer les sources.
19. Comment gérer une entité supprimée après binding ? Garder la ref, afficher diagnostic `actorBindingMapEntityUnknown` ou `movementTargetBindingMapEntityUnknown`, proposer de rechoisir.
20. Comment gérer un event supprimé après binding ? Garder la ref, afficher `movementTargetBindingMapEventUnknown`, proposer de rechoisir.
21. Comment afficher les labels dans le picker ? Label principal humain, type/kind en badge, id technique secondaire discret.
22. Comment afficher l’id technique en secondaire discret ? Sous-titre ou metadata line, jamais comme titre seul si un label existe.
23. Comment filtrer les entités pertinentes pour actor binding ? V0 : entités visuelles, surtout `npc`; toutes avec position et label possible si besoin.
24. Comment filtrer les entités pertinentes pour movement target binding ? Toute entité positionnée.
25. Comment filtrer les events pertinents pour movement target binding ? Tout `MapEventDefinition` positionné.
26. Les events peuvent-ils servir de position/target ? Oui, grâce à `EventPosition`; pas comme acteur V0.
27. Les entités peuvent-elles servir de position/target ? Oui, grâce à `MapEntity.pos` et `size`.
28. Faut-il supporter mapEvent dès le premier picker V0 ? Oui pour movement target, non pour actor binding.
29. Quels diagnostics futurs doivent être activés ? Unknown map entity/event, sources unavailable, source deleted.
30. Quel prochain lot exact est recommandé ? `NS-SCENES-V1-76 — Cinematic Stage Map Source Catalog V0`.

## 14. Problèmes identifiés

- `ProjectManifest.maps` peut être confondu avec `MapData` complet.
- Le Builder ne reçoit pas `MapData`.
- Les options map-aware sont visibles mais n’ont aucun catalogue de sources.
- Les diagnostics core actuels détectent des sources manquantes, pas encore des sources inconnues dans la map.
- Il existe une API snapshot editor utile, mais aucun contrat cinematic ne la consomme.
- Un picker direct sans catalogue risquerait des ids libres, des fake refs ou un couplage UI.

## 15. Options de source picker comparées

Option A — garder désactivé : sûr, mais bloque la progression map-aware.

Option B — passer `MapData` directement au Builder : simple, mais met de l’asynchrone et du modèle brut dans un widget dense.

Option C — créer un read model pur : testable et propre, mais demande un lot dédié.

Option D — réutiliser un read model Map Editor existant : cohérent mais risque de dépendre d’un domaine trop large.

Option E — hybride : créer un contrat cinematic pur, alimenté par une source editor fiable, en réutilisant les conventions de labels déjà présentes.

## 16. Option recommandée

Option E.

Le futur flux recommandé :

```text
CinematicAsset.mapId
  -> ProjectManifest.maps trouve ProjectMapEntry.relativePath
  -> editor charge MapData via snapshot non destructive
  -> helper pur construit CinematicStageMapSourceCatalog
  -> Builder consomme catalog/status, pas MapRepository ni widgets Map Editor
```

Cette option respecte le no-code, évite les ids libres et isole la logique testable.

## 17. Contrat recommandé Stage Map Source Catalog V0

Contrat conceptuel recommandé :

```text
CinematicStageMapSourceCatalog
  mapId
  mapLabel
  sourceStatus: available | missingMap | unavailable | loadError
  entities: List<CinematicStageMapEntitySource>
  events: List<CinematicStageMapEventSource>

CinematicStageMapEntitySource
  id
  label
  secondaryLabel
  kind
  canBindActor
  canBeMovementTarget
  positionSummary
  diagnostics

CinematicStageMapEventSource
  id
  label
  secondaryLabel
  kind
  canBeMovementTarget
  positionSummary
  diagnostics
```

Le contrat doit rester pur, testable, sans Flutter, sans runtime, sans `GameState`, sans pathfinding et sans coordonnées libres comme workflow principal.

## 18. Contrat recommandé actor binding mapEntity

Règles V0 :

- Si `mapId` absent : option disabled `Choisis d’abord une map de scène.`
- Si sources indisponibles : option disabled honnête.
- Si sources disponibles : picker d’entités.
- Sélection écrit `CinematicActorBinding(kind: mapEntity, mapEntityId: entity.id)`.
- Aucune saisie manuelle de `mapEntityId`.

Filtrage recommandé :

- V0 strict : `MapEntityKind.npc`.
- V0 extensible : toute entité avec position stable et label affichable, mais l’UI doit montrer le type.

## 19. Contrat recommandé movement target mapEntity

Règles V0 :

- Si `mapId` absent : disabled.
- Si catalogue entities disponible : picker d’entités positionnées.
- Sélection écrit `CinematicMovementTargetBinding(kind: mapEntity, sourceId: entity.id)`.
- `actorMove.targetId` reste une ref vers `movementTargets`, jamais un `mapEntityId`.

## 20. Contrat recommandé movement target mapEvent

Règles V0 :

- Si `mapId` absent : disabled.
- Si catalogue events disponible : picker d’events positionnés.
- Sélection écrit `CinematicMovementTargetBinding(kind: mapEvent, sourceId: event.id)`.
- Pas de binding acteur direct vers event.

## 21. Labels no-code et IDs secondaires

Entités :

- label primaire : `entity.inspectorHeadline` ou équivalent pur ;
- fallback : `entity.name`, puis `entity.id` ;
- secondaire : `${mapId}:${entity.id}` + kind ;
- position : secondaire, pas workflow principal.

Events :

- label primaire : `event.title`, fallback `event.id` ;
- secondaire : `${mapId}:${event.id}` + type ;
- position : secondaire, pas champ libre.

## 22. Diagnostics futurs recommandés

Déjà existants et confirmés :

- `actorBindingMapEntityMissingSource`
- `movementTargetBindingMissingSource`
- `movementTargetBindingRequiresStageMap`
- `stageMapUnknown`

À ajouter ou renforcer :

- `actorBindingMapEntityUnknown`
- `movementTargetBindingMapEntityUnknown`
- `movementTargetBindingMapEventUnknown`
- `stageMapSourcesUnavailable`
- `stageMapEntitySourceUnavailable`
- `stageMapEventSourceUnavailable`

Répartition :

- cohérence cinematic pure : `map_core` ;
- diagnostics dépendant d’une `MapData` chargée : futur helper/catalog pur si placé dans `map_core`, ou readiness editor si la source reste editor-only ;
- message UI : `map_editor`.

## 23. Relation avec Stage Context V1-72/V1-73/V1-74

V1-75 ne change pas le contrat V1-72 :

- `CinematicAsset.mapId` reste l’ancre map unique ;
- `stageContext` reste sans `mapId` ;
- `actorBindings` et `movementTargetBindings` restent optionnels ;
- `timeline.steps` reste inchangé ;
- `actorMove.targetId` reste une ref vers `movementTargets`.

V1-75 confirme le choix V1-73/V1-74 : les options map-aware devaient rester désactivées tant que la source `MapData` n’était pas cadrée.

## 24. Relation avec preview future

Les sources map-aware préparent :

- backdrop depuis map ;
- affichage d’acteurs ;
- placement initial ;
- résolution de cibles de mouvement.

V1-75 ne code aucune preview réelle, aucun actor display, aucune interpolation, aucune clock de playback et aucun contrôle de lecture.

## 25. Relation avec runtime

Les sources `mapEntity` / `mapEvent` sont d’abord un contrat authoring/preview. Elles pourront plus tard aider un runtime cinematic map-aware, mais V1-75 ne branche rien dans le runtime.

Termes runtime explicitement hors scope : `PlayableMapGame`, `SceneCinematicRuntimeAwaitableAdapter`, `GameState`, runtime map loading, spawn, collision, pathfinding, warp.

## 26. Tests futurs V1-76

Tests recommandés :

- `builds stage map source catalog from real map data`
- `lists map entities with stable ids and labels`
- `lists map events with stable ids and labels`
- `marks entities usable for actor binding`
- `marks entities usable for movement target binding`
- `marks events usable for movement target binding`
- `does not expose raw ids as primary labels`
- `handles empty map sources`
- `handles missing map data`
- `does not require runtime or GameState`

## 27. Tests futurs V1-77

Tests recommandés :

- `enables mapEntity actor binding when sources are available`
- `binds actor to selected map entity through picker`
- `does not expose mapEntityId text field`
- `enables movement target mapEntity binding when sources are available`
- `binds movement target to selected map entity`
- `enables movement target mapEvent binding when sources are available`
- `binds movement target to selected map event`
- `shows labels and technical ids as secondary text`
- `preserves CinematicAsset.mapId as unique map anchor`
- `does not mutate timeline steps`
- `does not enable preview playback`

## 28. Non-objectifs confirmés

Confirmé :

- pas de code Dart produit ;
- pas de modification `packages/` ;
- pas de test modifié ;
- pas de picker actif ;
- pas de sourceId / mapEntityId / eventId écrit par V1-75 ;
- pas de preview réelle ;
- pas de runtime ;
- pas de pathfinding ;
- pas de build_runner ;
- pas de screenshot ;
- pas d’image IA ;
- pas de données Selbrume, Maël, Lysa ou Port des Brisants codées.

## 29. Roadmap post V1-75

V1-75 peut être marqué DONE parce que l’audit est complet et doc-only.

Prochain lot exact recommandé :

```text
NS-SCENES-V1-76 — Cinematic Stage Map Source Catalog V0
```

Objectif V1-76 :

```text
Créer le read model pur / catalog de sources map-aware pour le Cinematic Builder :
entities/events réels d’une map, labels no-code, ids secondaires,
capabilities canBindActor/canBeMovementTarget,
sans UI picker actif, sans preview réelle et sans runtime.
```

V1-77 pourra ensuite activer les pickers.

## 30. Commandes exécutées

Commandes d’audit structurantes exécutées :

```bash
rg -n "class .*MapData|MapData\\(|ProjectMapEntry|maps:" packages/map_core packages/map_editor
rg -n "MapEntity|MapEntityPayload|entityId|entities|EntityProperties|EntityInspector|entity inspector" packages/map_core packages/map_editor
rg -n "MapEventDefinition|eventId|events|EventProperties|EventInspector|event properties" packages/map_core packages/map_editor
rg -n "loadMap|mapLoader|MapRepository|MapDataRepository|Tiled|mapAsset|contentLocation|mapPath" packages/map_core packages/map_editor
rg -n "ProjectManifest.*maps|project.maps|mapsBy|selectedMap|activeMap" packages/map_editor/lib/src
rg -n "stageContext|mapEntity|mapEvent|movementTargetBinding|actorBinding" packages/map_editor/lib/src/ui/canvas/cinematics packages/map_core/lib/src
```

Signaux exacts déterminants relevés :

```text
packages/map_core/lib/src/models/project_manifest.dart:316:    required List<ProjectMapEntry> maps,
packages/map_core/lib/src/models/project_manifest.dart:469:class ProjectMapEntry with _$ProjectMapEntry {
packages/map_core/lib/src/models/project_manifest.dart:470:  const factory ProjectMapEntry({
packages/map_core/lib/src/models/project_manifest.dart:471:    required String id,
packages/map_core/lib/src/models/project_manifest.dart:472:    required String name,
packages/map_core/lib/src/models/project_manifest.dart:473:    required String relativePath,
packages/map_core/lib/src/models/map_data.dart:31:    @Default([]) List<MapEntity> entities,
packages/map_core/lib/src/models/map_data.dart:41:    @Default([]) List<MapEventDefinition> events,
packages/map_core/lib/src/models/map_data.dart:206:class MapEntity with _$MapEntity {
packages/map_core/lib/src/models/map_event_definition.dart:21:class MapEventDefinition with _$MapEventDefinition {
packages/map_editor/lib/src/domain/repositories/repositories.dart:9:abstract class MapRepository {
packages/map_editor/lib/src/domain/repositories/repositories.dart:16:  Future<MapData> loadMap(String path);
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart:679:  Future<MapData?> loadMapSnapshotById(String mapId) async {
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart:237:        stageMaps: widget.project.maps,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:220:  final List<ProjectMapEntry> stageMaps;
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:3966:            'Le Builder ne reçoit pas encore les entités/events de la map.';
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:4258:            'Le Builder ne reçoit pas encore les entités/events de la map.';
```

Commandes de validation documentaires attendues :

```bash
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --name-only -- packages
rg -n "CinematicStageMapSourceCatalog|StageMapSourceCatalog|MapEntitySource|MapEventSource|canBindActor|canBeMovementTarget|mapEntity picker|mapEvent picker" packages/map_core packages/map_editor || true
rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|playCinematic|runtimePreview|previewRuntime|startPlayback|seek|scrub|scrubber|Timer\\(|Ticker|AnimationController|isPlaying|currentTimeMs|playbackTimeMs" reports/narrativeStudio/scenes/ns_scenes_v1_75_cinematic_map_entity_event_source_audit_picker_prep_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
rg -n "gpt-image-2|image_generation|generate image|AI image|image model" reports/narrativeStudio/scenes/ns_scenes_v1_75_cinematic_map_entity_event_source_audit_picker_prep_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" reports/narrativeStudio/scenes/ns_scenes_v1_75_cinematic_map_entity_event_source_audit_picker_prep_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
```

## 31. Checks anti-scope

Résultats après édition :

```bash
git diff --check
```

```text

```

```bash
git diff --stat
```

```text
 .../scenes/road_map_scene_builder_authoring.md     | 22 ++++++++++++++++++++--
 reports/narrativeStudio/scenes/road_map_scenes.md  | 22 ++++++++++++++++++----
 2 files changed, 38 insertions(+), 6 deletions(-)
```

Note : le rapport V1-75 est nouveau et non suivi, donc il apparaît dans `git status --short --untracked-files=all`, pas dans `git diff --stat`.

```bash
git diff --name-only
```

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

```bash
git status --short --untracked-files=all
```

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_75_cinematic_map_entity_event_source_audit_picker_prep_contract.md
```

```bash
git diff --name-only -- packages
```

```text

```

```bash
rg -n "CinematicStageMapSourceCatalog|StageMapSourceCatalog|MapEntitySource|MapEventSource|canBindActor|canBeMovementTarget|mapEntity picker|mapEvent picker" packages/map_core packages/map_editor || true
```

```text

```

Interprétation : aucun package n’a été modifié et aucune implémentation de catalogue/picker n’a été ajoutée dans `packages/`.

```bash
rg -n "gpt-image-2|image_generation|generate image|AI image|image model" reports/narrativeStudio/scenes/ns_scenes_v1_75_cinematic_map_entity_event_source_audit_picker_prep_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
```

```text
reports/narrativeStudio/scenes/ns_scenes_v1_75_cinematic_map_entity_event_source_audit_picker_prep_contract.md:608:rg -n "gpt-image-2|image_generation|generate image|AI image|image model" reports/narrativeStudio/scenes/ns_scenes_v1_75_cinematic_map_entity_event_source_audit_picker_prep_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
```

Interprétation : seule la commande anti-scope contient ces termes ; aucun outil image IA n’a été appelé.

Les recherches anti-runtime et anti-Selbrume retournent des mentions historiques nombreuses dans les roadmaps globales et des mentions de non-objectifs dans ce rapport. Elles ne signalent aucun fichier package modifié et aucune donnée produit ajoutée par V1-75.

## 32. Evidence Pack

Inventaire des preuves :

- Gate 0 complet : section 2.
- Fichiers lus : section 3.
- Passes A à L : sections 7 à 12, 15 à 17, 22, 26, 27 et 29.
- Roadmaps mises à jour : `road_map_scenes.md` et `road_map_scene_builder_authoring.md`.
- Aucun package modifié : `git diff --name-only -- packages` sort vide.
- Aucun test lancé : lot documentaire, conformément au prompt.

Hunks roadmap attendus :

```diff
road_map_scenes.md
-| NS-SCENES-V1-75 ... | TODO | Auditer les sources editor fiables ...
+| NS-SCENES-V1-75 ... | DONE | Audit documentaire des vraies sources `MapData.entities/events`...

road_map_scene_builder_authoring.md
-NS-SCENES-V1-75 — Cinematic Map Entity/Event Source Audit / Picker Prep Contract
+NS-SCENES-V1-76 — Cinematic Stage Map Source Catalog V0
```

## 33. Auto-review critique

1. Est-ce que V1-75 a modifié du code produit ? Non.
2. Est-ce que V1-75 a modifié un package ? Non.
3. Est-ce que V1-75 a modifié un test ? Non.
4. Est-ce que V1-75 a codé un picker mapEntity ? Non.
5. Est-ce que V1-75 a codé un picker mapEvent ? Non.
6. Est-ce que V1-75 a activé une option mapEntity/mapEvent ? Non.
7. Est-ce que V1-75 a exposé un ID libre ? Non.
8. Est-ce que V1-75 a exposé du JSON brut ? Non.
9. Est-ce que V1-75 a ajouté des coordonnées libres ? Non.
10. Est-ce que V1-75 a ajouté une preview réelle ? Non.
11. Est-ce que V1-75 a modifié le runtime ? Non.
12. Est-ce que V1-75 a ajouté du pathfinding ? Non.
13. Est-ce que V1-75 a ajouté des données Selbrume ? Non.
14. Est-ce que ProjectManifest.maps a été audité ? Oui.
15. Est-ce que MapData a été audité ? Oui.
16. Est-ce que les entités de map ont été auditées ? Oui.
17. Est-ce que les events de map ont été audités ? Oui.
18. Est-ce que les sources editor disponibles ont été auditées ? Oui.
19. Est-ce que les options de source picker sont comparées ? Oui.
20. Est-ce que l’option recommandée est claire ? Oui, Option E.
21. Est-ce que le contrat Stage Map Source Catalog V0 est défini ? Oui.
22. Est-ce que le contrat actor binding mapEntity est défini ? Oui.
23. Est-ce que le contrat movement target mapEntity est défini ? Oui.
24. Est-ce que le contrat movement target mapEvent est défini ? Oui.
25. Est-ce que les diagnostics futurs sont listés ? Oui.
26. Est-ce que les tests futurs sont listés ? Oui.
27. Est-ce que le prochain lot exact est recommandé ? Oui, V1-76.
28. Est-ce que l’Evidence Pack est complet sans placeholders ? Oui pour le périmètre documentaire. Limite honnête : les recherches anti-runtime et anti-Selbrume ciblent des roadmaps historiques très bavardes, donc le rapport en donne l’interprétation utile au scope V1-75 au lieu de recopier des centaines de lignes historiques sans lien avec les fichiers modifiés.

## 34. Verdict final

V1-75 est DONE.

Les sources réelles sont identifiées :

- maps : `ProjectManifest.maps` pour metadata et `relativePath` ;
- entités : `MapData.entities` ;
- events : `MapData.events` ;
- chargement fiable editor : `MapRepository` / `LoadMapUseCase` / `EditorNotifier.loadMapSnapshotById`.

Le Builder ne peut pas encore sélectionner d’entités ou d’events. Le prochain lot doit créer le catalogue pur `NS-SCENES-V1-76 — Cinematic Stage Map Source Catalog V0`, sans picker actif, sans preview réelle et sans runtime.
