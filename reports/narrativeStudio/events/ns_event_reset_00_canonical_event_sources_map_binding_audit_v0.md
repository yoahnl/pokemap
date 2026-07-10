# NS-EVENT-RESET-00 — Canonical Event Sources & Map Binding Audit V0

## 1. Résumé exécutif

```text
Lot : NS-EVENT-RESET-00 — Canonical Event Sources & Event Builder V2 Ultra Roadmap
Nature : audit et décision documentaire uniquement
Verdict architecture : OPTION D — hybride projet + ancres de map
Implémentation : aucune
Migration exécutée : aucune
```

### Diagnostic principal

Le problème observé est confirmé. Le système V1 ne demande pas réellement
« quelle source du monde déclenche cet Event ? ». Il demande d'abord où placer
un `MapEventDefinition`, puis lui attribue un type `actor`, `object` ou
`triggerZone`. La position et le type servent donc de substitut à une référence
stable vers un PNJ, un objet ou une zone.

Le repository contient pourtant déjà une grammaire source-first dans un autre
pipeline : `mapEnter`, `triggerEnter`, `entityInteract` et
`outcomeReceived`. Cette grammaire est authorable et partiellement consommée par
`ScenarioRuntimeExecutor`, mais elle est portée par `ScenarioAsset`, pas par
l'Event Builder. Il existe donc deux pipelines concurrents et deux définitions
implicites de l'Event.

### Décision

Le futur Event canonique est un asset project-level fin, ici nommé
`NarrativeEventDefinition` à titre de contrat cible. Il possède exactement une
source typée, des conditions, une Scene cible et une politique de réutilisation.
Il ne possède aucune position.

```text
Une source réelle peut être référencée par 0..N Events.
Un Event V0 référence exactement une source.
Un Event V0 cible exactement une Scene.
```

La position et la géométrie restent chez leur propriétaire naturel :

- `MapEntity` pour un PNJ ou un objet ;
- `MapTrigger` pour une zone ;
- la map elle-même pour `mapEnter` ;
- aucun placement spatial pour `outcomeReceived`.

`MapEventDefinition` devient un format legacy lisible, un input de migration et
un adapter de compatibilité. Il n'est plus la cible d'écriture normale V2.
`ScenarioAsset` reste également lisible et exécutable pendant la transition,
mais ses nodes source ne deviennent pas le modèle Event canonique.

Le manifest porte un `NarrativeEventRegistry` versionné indépendamment de
`ProjectVersion`. Ce registry contient les records V2, le mode d'autorité
`legacyOnly | dualRead | v2Only` et les claims persistés qui empêchent un
fallback legacy après migration. Un record `draft` peut être incomplet ; seul un
record `configured` valide entre dans l'index runtime.

### Résultat du lot

```text
Architecture recommandée : hybride projet + ancres de map
Sources V0 : entityInteract, triggerEnter, mapEnter, outcomeReceived
Position sur l'Event : interdite
Migration : dual-read temporaire, single-write V2, preview opt-in et rollback
Roadmap : 12 phases, 44 lots au total
Prochain lot : NS-EVENT-V2-01 — Canonical Narrative Event Source Ref Contract V0
Blockers du document : aucun après corrections contradictoires
Blockers avant V2-01 : décisions registry/record/outcome listées en section 19
```

---

## 2. Observation utilisateur

L'observation utilisateur est valide : après avoir créé un Event en cliquant
sur une case, l'UI propose un déclencheur « Interaction avec un PNJ »,
« Interaction avec un objet » ou « Entrée dans une zone », sans demander quel
PNJ, quel objet ou quelle zone est concerné.

Le modèle mental affiché est :

```text
Quand le joueur interagit avec cette source réelle, déclencher cet Event.
```

Le modèle réellement authoré est plutôt :

```text
À cette position, créer un MapEventDefinition de type actor/object/triggerZone.
```

Cette différence n'est pas un défaut de wording. C'est une contradiction de
modèle. Renommer le position picker ou améliorer sa capture ne peut pas la
résoudre.

Le besoin produit canonique devient :

```text
Un Event n'est pas un élément placé sur une map.
Un Event est une règle liée à une source existante et stable.
```

La north star visuelle fournie est retenue comme objectif final de composition
et de densité. Son flow central reste une inspiration visuelle ; ses réactions,
résultats et changements du monde ne deviennent pas pour autant des propriétés
authorables de l'Event.

---

## 3. Usage MCP Dart

Le MCP Dart a été disponible et utilisé avant la décision.

### Roots inspectés

```text
packages/map_core
packages/map_editor
packages/map_runtime
packages/map_gameplay
```

### Symboles résolus ou tracés

```text
MapEventDefinition
EventPosition
MapEventType
MapData
MapEntity
MapTrigger
ProjectManifest
EventBuilderSourceBinding
NarrativeScenarioAuthoringSourceDraft
NarrativeEventSourcePickerOption
buildNarrativeEventSourcePickerOptions
ScenarioRuntimeSourceEvent
ScenarioRuntimeExecutor
GameState.consumedEventIds
EditorNotifier.createEventBuilderDraftEventAt
EditorState.selectedMapEventId
```

Le MCP a servi à confirmer les définitions et leurs emplacements. Les résultats
ont ensuite été recoupés par `rg`, `sed` et `nl`. Aucun usage MCP fictif et
aucune modification par MCP n'ont été effectués.

### Verdict MCP

```text
MCP Dart : PASS
Résultat : le constat initial est confirmé, avec une correction importante :
le repository possède déjà les quatre sources cibles, mais dans le pipeline
Scenario et non dans le modèle Event Builder canonique.
```

---

## 4. Sous-agents

Huit passes spécialisées ont été exécutées, puis deux reviews contradictoires
ont été réservées pour les trois livrables complets. L'orchestrateur principal a
arbitré les recommandations incompatibles.

| Passe | Mission | Verdict | Décision retenue |
|---|---|---|---|
| A — Product Model | comparer les modèles canoniques possibles | Option D recommandée | Event project-level fin, source typée |
| B — Existing Domain Inventory | inventorier les contrats et pipelines | inventaire PASS ; préférence in-place | inventaire retenu, recommandation in-place rejetée |
| C — Map Ownership | décider qui possède position et géométrie | PASS sans réserve | `MapEntity` / `MapTrigger` / map possèdent l'espace |
| D — Runtime Dispatch | tracer les quatre sources et le lifecycle | PARTIAL actuel | index et bridges V2 requis |
| E — Migration & Compatibility | proposer la transition legacy | GO sous garde-fous | dual-read, single-write, preview, rollback |
| F — UX & Information Architecture | définir le flux source-first | PASS conceptuel | intention → source → conditions → Scene → comportement |
| G — Visual Reference | mesurer la north star 1672 × 941 | PASS documentaire | grille et proportions transférées dans la spec visuelle |
| H — Tests & Validator | définir preuves et diagnostics | GO phasé | gate par contrat, migration, runtime, UI, Golden Slice |
| Reviewer R1 — Architecture | chercher duplication et migration fragile | FAIL initial → PASS final | registry/mode/claims, records, coordinator et roadmap corrigés |
| Reviewer R2 — UX / honnêteté fonctionnelle | chercher contrôles trompeurs et copie aveugle | FAIL initial → PASS final | affordances, responsive, pickers, migration UX et métrologie corrigés |
| Orchestrateur | synthèse et décision | Option D révisée | recommandations B/E in-place surclassées ; objections R1/R2 intégrées |

Les passes B et E ont proposé d'étendre `MapEventDefinition` en place. Cette
recommandation réduit le coût initial, mais ne peut pas représenter proprement
une source `outcomeReceived` sans map ni position et perpétue la confusion entre
source et placement. Elle est donc rejetée au profit d'un adapter legacy.

---

## 5. Inventaire actuel

### 5.1 Modèle map-local V1

`packages/map_core/lib/src/models/map_event_definition.dart:21` définit
`MapEventDefinition` avec :

```text
id
title
pages
EventPosition obligatoire
MapEventType
metadata
```

`EventPosition` contient `layerId`, `x` et `y`. `MapEventType` contient
`actor`, `object`, `triggerZone` et `effect`. Aucun champ n'identifie un
`MapEntity` ou un `MapTrigger` réel.

`packages/map_core/lib/src/models/map_data.dart:41` stocke
`List<MapEventDefinition> events` dans chaque `MapData`. L'unicité de l'ID est
donc naturellement locale à la map dans ce modèle.

### 5.2 Contrat Event Builder V1

`packages/map_core/lib/src/authoring/event_builder_contract.dart:8` déclare
explicitement `MapEventDefinition` / `MapEventPage` comme stockage canonique.

`EventBuilderSourceBinding` contient :

```text
eventId
eventTitle
eventType
EventPosition
```

Le nom « SourceBinding » ne désigne donc pas une source extérieure. Il réemballe
le MapEvent lui-même.

`packages/map_core/lib/src/authoring/event_builder_draft_creation_operations.dart:27`
refuse volontairement toute position implicite et exige un `EventPosition`.
Cette règle était sûre dans le modèle V1, mais elle révèle que la création reste
fondamentalement placement-first.

### 5.3 Authoring editor

`EventBuilderWorkspace` et `EventBuilderCreationPanel` demandent destination,
position puis création. `EditorNotifier.createEventBuilderDraftEventAt` écrit
un nouveau `MapEventDefinition` dans la map active. La sélection repose sur
`EditorState.selectedMapEventId` et la liste affichée vient de la map active.

Conséquences :

- impossible de créer naturellement un Event `outcomeReceived` ;
- impossible de lister correctement tous les Events du projet ;
- un changement de source est confondu avec un changement de position/type ;
- « Voir sur la carte » ne dispose pas d'une source stable à sélectionner ;
- le workflow normal expose la couche de stockage de la map.

### 5.4 Sources modernes déjà présentes

`packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart:16`
contient déjà les quatre kinds :

```text
mapEnter
triggerEnter
entityInteract
outcomeReceived
```

Les factories de `NarrativeScenarioAuthoringSourceDraft` portent les bonnes
références : `mapId`, `triggerId`, `entityId` ou `outcomeId`.

`packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart:482`
construit déjà des `NarrativeEventSourcePickerOption` à partir des maps,
triggers, entities et outcomes. Cette capacité est réutilisable comme catalog
ou comme source d'inspiration, mais son contrat ne doit pas être promu sans
audit de ses identités et diagnostics.

### 5.5 Propriétaires spatiaux existants

`packages/map_core/lib/src/models/map_data.dart:206` :

- `MapEntity.id` fournit l'identité stable dans une map ;
- `MapEntity.kind` distingue notamment PNJ, panneau, item, spawn et custom ;
- `MapEntity.pos` et `MapEntity.size` possèdent le placement.

`packages/map_core/lib/src/models/map_data.dart:337` :

- `MapTrigger.id` fournit l'identité stable dans une map ;
- `MapTrigger.type` porte son rôle ;
- `MapTrigger.area` possède la géométrie.

Ces modèles sont les propriétaires spatiaux cibles. Cependant, un MapEvent V1
peut être autonome et ne dupliquer aucune entity existante : le runtime le
cherche directement par coordonnées. Ce cas ne se convertit pas par simple
référence. Il reste sous adapter ou demande une matérialisation explicite de
`MapEntity` / `MapTrigger` dans V2-25.

### 5.6 Manifest projet

`packages/map_core/lib/src/models/project_manifest.dart:311` stocke déjà les
catalogues project-level, dont `scenarios` et `scenes`, mais ne possède aucun
registry Event global. `ProjectVersion` est partagé avec `MapData`; il ne doit
donc pas être incrémenté seulement pour Event V2. Le registry cible porte son
propre `schemaVersion`.

### 5.7 Runtime Scenario

`packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart:16`
définit les quatre événements source runtime. `ScenarioRuntimeExecutor` les
matche contre des nodes source Scenario et s'arrête au premier scénario/source
correspondant.

Les hooks de production existent pour :

```text
mapEnter
triggerEnter
entityInteract
outcomeReceived
```

Mais le pipeline reste incomplet : scan linéaire, wildcard de `mapId` vide,
reentrance outcome bornée seulement par profondeur, continuités transitoires,
couverture `mapEnter` incomplète au chargement de sauvegarde, et lifecycle
one-shot non unifié.

### 5.8 Runtime MapEvent

Le runtime conserve parallèlement un chemin `MapEventDefinition -> Scene` pour
les interactions actor/object. Le rapport NS-EVENT-35 prouve que
`MapEventType.triggerZone` n'est pas déclenché par l'entrée sur sa tuile dans ce
pipeline. La dette n'est donc pas seulement UX : les deux systèmes n'ont pas la
même couverture fonctionnelle.

### 5.9 Consommation persistée

`packages/map_core/lib/src/models/game_state.dart:102` stocke
`Set<String> consumedEventIds`. Les IDs n'y sont pas qualifiés par `mapId`, alors
que les MapEvents sont stockés map par map. Deux Events legacy partageant le
même ID peuvent donc entrer en collision dans la sauvegarde. Les mêmes IDs sont
référencés par conditions, World Rules, commandes et conséquences de Scene. Le
V2 doit introduire un namespace de progression séparé et migrer le graphe de
références complet, pas uniquement ce set.

### 5.10 Synthèse des pipelines

| Pipeline | Source de vérité | Source réelle | Cible | Couverture |
|---|---|---|---|---|
| Event Builder V1 | `MapData.events` | MapEvent placé | `SceneAsset` via page | actor/object ; triggerZone partiel |
| Scenario source-first | `ProjectManifest.scenarios` | map/trigger/entity/outcome | graph Scenario | quatre sources, lifecycle partiel |
| Event V2 cible | `ProjectManifest.eventRegistry` proposé | union source typée | une `SceneAsset` | à implémenter par lots |

---

## 6. Contradictions produit

1. **Source affichée, position stockée.** L'UI parle d'un PNJ ou d'un objet,
   mais n'en demande pas l'identité.
2. **Map obligatoire, source parfois non spatiale.** Un outcome n'a ni map ni
   case naturelle.
3. **Type et identité confondus.** `actor` dit comment imaginer l'Event, pas quel
   acteur le déclenche.
4. **Objet invisible implicite.** Cliquer sur une case crée une nouvelle chose
   abstraite alors que le monde contient déjà des entities et triggers.
5. **Liste locale présentée comme module global.** Le Narrative Studio doit
   montrer les Events du projet, pas uniquement ceux de la map active.
6. **Navigation cartographique non honnête.** Sans référence stable, « Voir sur
   la carte » ne peut pas garantir la sélection de la vraie source.
7. **North star trop expressive métier.** L'image montre résultats, réactions et
   changements comme blocs éditables. Dans PokeMap, ces éléments appartiennent
   à la Scene et doivent rester des projections en lecture seule.
8. **Terminologie technique dans le parcours.** Layers, draft et position picker
   décrivent le stockage, pas l'intention de l'auteur.

---

## 7. Contradictions techniques

1. **Deux canons actifs.** `MapData.events` et `ProjectManifest.scenarios`
   expriment deux règles de déclenchement concurrentes.
2. **Duplication des vocabulaires.** `MapEventType`,
   `EventBuilderTriggerKind`, `NarrativeScenarioAuthoringSourceKind` et
   `ScenarioRuntimeSourceType` se recouvrent sans contrat partagé.
3. **Ownership dupliqué.** `EventPosition` duplique la position déjà portée par
   `MapEntity`, ou remplace maladroitement `MapTrigger.area`.
4. **Identité locale versus état global.** Les IDs map-local alimentent un set
   global non qualifié dans `GameState`.
5. **Pas de registry Event projet.** Le manifest ne peut ni indexer ni valider
   globalement les Events V1.
6. **Résolution non indexée.** Le runtime Scenario parcourt scénarios puis nodes
   pour chaque occurrence.
7. **Wildcard silencieux.** Un `mapId` de binding vide peut matcher toute map
   dans le runtime Scenario.
8. **Ordre implicite.** Le premier scénario/node du manifest gagne ; la priorité
   n'est pas un contrat métier explicite.
9. **Lifecycle hétérogène.** Le one-shot MapEvent, les scénarios persistants et
   les outcomes n'ont pas une règle commune de consommation.
10. **Migration ambiguë.** Une position legacy ne suffit pas à identifier sans
    ambiguïté un `MapEntity` ou un `MapTrigger`.
11. **Navigation editor couplée à la map active.** La sélection actuelle ne
    porte pas un couple source stable `(mapId, sourceId)`.
12. **Continuité de sauvegarde partielle.** Les continuations runtime Scenario
    ne constituent pas encore un contrat durable commun.
13. **Aucune autorité persistée.** Rien ne dit au runtime qu'un MapEvent ou node
    Scenario a été revendiqué par le V2 ; un fallback peut donc le rejouer après
    consommation du nouvel Event.
14. **Brouillon et définition valide confondus.** L'UX promet `Décider plus
    tard`, mais un contrat à source/Scene obligatoires ne peut pas sérialiser cet
    état sans record distinct.

---

## 8. Options architecturales

### Option A — Étendre MapEventDefinition en place

Ajouter `entityId`, `triggerId`, `outcomeId` et rendre la position optionnelle.

Avantage : migration initiale plus petite et réutilisation directe du V1.

Rejet : le modèle reste map-local, mélange pages/présentation/source et traite
mal les Events non spatiaux. Il transforme une dette structurelle en union de
champs optionnels.

### Option B — Faire posséder l'Event par la source

Ajouter des Events dans `MapEntity`, `MapTrigger`, `MapData` et dans un catalog
outcome.

Avantage : proximité forte avec la source et navigation map simple.

Rejet : quatre emplacements d'écriture, liste projet difficile, migration et
validation fragmentées, duplication de lifecycle. Une source doit être
référencée, pas devenir un conteneur narratif.

### Option C — Promouvoir les nodes source Scenario comme Events

Déclarer `ScenarioAsset` canonique pour toute règle de déclenchement.

Avantage : les quatre sources et le runtime existent déjà.

Rejet : Event et orchestration redeviennent la même chose. L'Event Builder
deviendrait un second éditeur de graph Scenario, en contradiction avec
`Event déclenche ; Scene orchestre`.

### Option D — Asset Event project-level avec source typée

Créer un Event fin dans le manifest projet. Sa source référence la map,
l'entity, le trigger ou l'outcome existant. Les structures spatiales restent
dans les maps. Les deux pipelines legacy alimentent temporairement des adapters.

Avantage : modèle métier fidèle, sources non spatiales natives, index global,
validation et authoring unifiés.

Coût : nouveau contrat et migration explicite. Ce coût est choisi parce qu'il
traite la cause au lieu de prolonger le V1.

---

## 9. Matrice de décision

Échelle : 1 faible, 5 fort. Pour « risque migration », 5 signifie risque faible.

| Critère | Poids | A — in-place | B — source-owned | C — Scenario | D — project Event |
|---|---:|---:|---:|---:|---:|
| Fidélité « Event = règle liée à une source » | 5 | 3 | 4 | 3 | 5 |
| Sources non spatiales | 5 | 2 | 2 | 5 | 5 |
| Ownership de la position | 5 | 2 | 5 | 4 | 5 |
| Frontière Event / Scene | 5 | 3 | 4 | 1 | 5 |
| Registry et validation projet | 4 | 2 | 1 | 4 | 5 |
| Réutilisation des catalogs existants | 3 | 3 | 3 | 5 | 5 |
| Runtime déterministe indexable | 4 | 3 | 2 | 3 | 5 |
| Migration progressive | 4 | 4 | 2 | 3 | 4 |
| Authoring no-code source-first | 5 | 3 | 4 | 2 | 5 |
| Réversibilité avant publication | 3 | 4 | 2 | 3 | 4 |
| **Score pondéré / 215** |  | **119** | **119** | **131** | **208** |

La matrice ne prétend pas être une mesure scientifique. Elle rend explicite le
fait que l'Option D gagne principalement sur les invariants produit, la prise en
charge des sources non spatiales et la frontière Event/Scene.

---

## 10. Architecture recommandée

### 10.1 Canon

```text
ProjectManifest
└── eventRegistry: NarrativeEventRegistry
    ├── schemaVersion
    ├── mode: legacyOnly | dualRead | v2Only
    ├── records: List<NarrativeEventRecord>
    │   ├── draft: source/Scene optionnelles, jamais indexé
    │   └── configured: NarrativeEventDefinition + active/inactive
    └── legacyClaims: List<LegacySourceClaim>
        ├── provenance qualifiée MapEvent ou Scenario source node
        └── targetEventIds V2 non vides, ordonnés et validés
```

Le nom Dart définitif reste à confirmer dans V2-01/V2-02, mais le contrat
conceptuel est arrêté.

### 10.2 Cardinalités

```text
Source réelle 1 ─── référencée par 0..N Events
Event 1 ─── 1 Source V0
Event 1 ─── 1 Scene V0
Scene 1 ─── 0..N outcomes / branches / conséquences
```

### 10.3 Règle de résolution V0

Pour une occurrence source :

1. consulter `EventSystemMode` et les claims legacy ;
2. indexer structurellement par clé source exacte ;
3. retirer les records non configurés, inactifs ou consommés ;
4. évaluer les conditions dans `map_gameplay` ;
5. trier par `priority` décroissante ;
6. départager par `order` croissant ;
7. départager enfin par `eventId` ;
8. retourner `handled`, `claimedButIneligible` ou `noMatch` ;
9. exécuter un seul gagnant en V0.

Le multi-fire n'est pas interdit à long terme, mais il n'est pas implicite. Il
nécessiterait un contrat futur d'ordonnancement, d'erreur et de reentrance.

Lorsque plusieurs Events actifs partagent une source, l'authoring affiche les
concurrents, la `Priorité de déclenchement` et le gagnant projeté. `order` et le
tie-break par ID restent internes. Un ordre déterministe qui ne peut pas être
expliqué à l'auteur est un diagnostic bloquant, pas un succès silencieux.

`claimedButIneligible` interdit tout fallback MapEvent/Scenario : une source
migrée ne redevient pas legacy parce que son Event V2 est déjà consommé ou que
ses conditions sont fausses. `noMatch` autorise le chemin legacy uniquement si
le mode et l'absence de claim le permettent.

### 10.4 Frontières

```text
Event : déclenche une Scene.
Scene : orchestre dialogue, cinématique, combat et conséquences.
Yarn : produit dialogue et outcomes.
Fact : mémorise une vérité.
World Rule : projette passivement cette vérité.
```

L'Event Builder peut afficher les projections de Scene, jamais les authorer.

### 10.5 Statut des anciens modèles

- `MapEventDefinition` : lecture legacy, adapter, migration input.
- `ScenarioAsset` source nodes : lecture/runtime legacy, migration input si la
  forme est convertible sans perte.
- `NarrativeEventRegistry.mode/legacyClaims` : autorité persistée commune à
  l'editor et au runtime pendant la coexistence.
- `NarrativeEventSourcePickerOption` : catalog/read-model à réutiliser ou
  refactorer après contrat canonique, pas source de vérité.
- `MapEntity` / `MapTrigger` : sources spatiales canoniques.

---

## 11. Modèle cible

Le pseudo-contrat suivant est documentaire. Il ne constitue pas du code à
copier tel quel.

```text
NarrativeEventRecord
  draft: NarrativeEventDraft
  configured: NarrativeEventDefinition + active | inactive

NarrativeEventDraft
  id: ProjectEventId
  name: String
  source: NarrativeEventSourceRef?
  conditions: List<ScriptCondition>
  sceneId: SceneId?
  behavior: oneShot | reusable?

NarrativeEventDefinition
  id: ProjectEventId
  name: String
  source: NarrativeEventSourceRef
  conditions: List<ScriptCondition>
  sceneId: SceneId
  behavior: oneShot | reusable
  priority: int
  order: int
```

### Source union V0

```text
NarrativeEventSourceRef.entityInteract(mapId, entityId)
NarrativeEventSourceRef.triggerEnter(mapId, triggerId)
NarrativeEventSourceRef.mapEnter(mapId)
NarrativeEventSourceRef.outcomeReceived(
  producerKind,
  producerId,
  outcomeId,
)
```

La qualification outcome est retenue parce que `SceneOutcome.id` n'est local
qu'à sa Scene et que Yarn/Battle peuvent produire le même libellé technique. Un
outcome Scenario V1 non qualifié est placé sous une provenance
`legacyScenario(scenarioId)` par l'adapter ; il n'est pas promu silencieusement
comme ID global.

### Invariants

- aucun ID vide ;
- aucun couple partiel ;
- aucune coordonnée ;
- aucune copie de label source dans le contrat ;
- référence Scene obligatoire pour un record `configured` ;
- draft incomplet sérialisable mais jamais indexé ni exécutable ;
- conditions évaluées avec l'algèbre canonique existante ; la liste est un AND
  court-circuité dans l'ordre stocké et la liste vide vaut vrai ;
- ID Event unique au niveau projet ;
- exactement une source ;
- outcome, reaction, World Rule et conséquence absents de l'Event ;
- source key dérivée de la variante et de la provenance, jamais saisie
  manuellement ;
- seuls les records `configured + active` entrent dans l'index runtime.

Le picker actuel utilise une clé `outcomeReceived:$outcomeId` et un
`putIfAbsent`. Le V2 ne peut pas réutiliser cette déduplication : V2-10 doit
inventorier les producteurs et construire une référence qualifiée. V2-22 doit
propager cette même provenance dans l'occurrence runtime.

### Source et trigger ne sont pas synonymes

La source est l'origine stable de l'occurrence. Le déclencheur est la sémantique
d'occurrence (`interact`, `enter`, `received`). Dans V0, la variante typée encode
le couple valide pour empêcher `interact + MapTrigger` ou `enter + outcome`.
L'UI peut titrer le bloc « Déclencheur », tout en affichant la vraie source.

---

## 12. Ownership map / source / position

| Cas produit | Source canonique | Propriétaire position/géométrie | L'Event stocke |
|---|---|---|---|
| Parler à Lysa | `entityInteract(map_port_brisants, npc_lysa)` | `MapEntity.pos/size` | la référence seulement |
| Examiner un objet | `entityInteract(mapId, objectEntityId)` | `MapEntity.pos/size` | la référence seulement |
| Entrer dans une zone | `triggerEnter(mapId, triggerId)` | `MapTrigger.area` | la référence seulement |
| Entrer sur une map | `mapEnter(mapId)` | la map | la référence seulement |
| Recevoir un outcome | `outcomeReceived(producerKind, producerId, outcomeId)` | non spatial | la référence seulement |

### Éligibilité des sources spatiales V0

| Modèle | Éligibilité V0 | Décision |
|---|---|---|
| `MapEntity.npc/sign/item/custom` | oui si l'interaction runtime émet l'entity ID | source `entityInteract` |
| `MapEntity.spawn` | non | point de spawn système, diagnostic explicite |
| `MapTrigger.event/custom` | oui | source `triggerEnter` |
| `MapTrigger.warp/message/interaction/spawn/camera` | non par défaut | fonction système ou sémantique non `enter`; visible disabled avec raison |
| `MapPlacedElement` interactif | non dans l'union V0 | chemin gameplay distinct ; matérialiser une `MapEntity` ou lot futur dédié |
| MapEvent autonome V1 | legacy uniquement | adapter ou source explicite créée dans V2-25 |

### Cas invisibles

- un point d'entrée invisible 1 × 1 est un `MapTrigger` de zone minimale ;
- un interactable invisible est un `MapEntity` explicite `custom`, `sign` ou
  autre kind compatible ;
- une tuile brute n'est jamais une source narrative stable ;
- si l'auteur veut créer une nouvelle source spatiale, il le fait dans le Map
  Editor, qui possède l'édition de la géométrie.

### Navigation

`Voir sur la carte` doit :

1. ouvrir `mapId` ;
2. sélectionner `entityId` ou `triggerId` ;
3. centrer la caméra sur son footprint ;
4. conserver un chemin de retour vers l'Event ;
5. signaler une source supprimée au lieu d'utiliser une ancienne coordonnée.

---

## 13. Runtime target

### 13.1 Pipeline cible

```text
Occurrence monde
→ NarrativeEventSourceRef key
→ UnifiedEventDispatchCoordinator
→ registry mode + legacy claims
→ EventSourceIndex structurel
→ active / progression V2 / conditions dans map_gameplay
→ handled | claimedButIneligible | noMatch
→ Event gagnant ou fallback legacy autorisé
→ SceneRuntimeExecutor
→ succès / échec / continuation
→ lifecycle Event
→ outcomes Scene
→ nouveau dispatch outcome éventuel
```

### 13.2 Hooks V0

- `entityInteract` : après résolution de l'entity réellement visée ;
- `triggerEnter` : transition hors zone → dans zone, pas simple présence ;
- `mapEnter` : boot, warp, connection et loadGame réussi selon décision ;
- `outcomeReceived` : après émission persistée de l'outcome, avec garde de
  reentrance et provenance qualifiée.

`MapPlacedElementInteracted` reste hors du bridge `entityInteract` V0. Le
coordinateur est le seul endroit autorisé à décider V2 versus legacy ; les
quatre hooks ne lancent jamais directement les deux pipelines.

### 13.3 Lifecycle

- `oneShot` est consommé après réussite complète de la Scene ;
- `reusable` n'est pas consommé automatiquement ;
- un échec avant démarrage de Scene ne consomme pas ;
- une Scene suspendue ne consomme qu'à sa réussite finale ;
- reset durable et cooldown sont hors V0 ;
- l'état de continuation doit devenir sérialisable avant release V2.

La progression V2 utilise un set de `ProjectEventId` global séparé du legacy
`consumedEventIds`. La migration réécrit ou adapte conditions, World Rules,
commandes et conséquences qui référencent l'ancien ID ; elle ne mélange pas les
deux namespaces dans le même set.

### 13.4 Déterminisme et performance

Le runtime ne doit pas scanner tous les scénarios/nodes à chaque occurrence.
V2-04 construit uniquement l'index structurel source → records, sans dépendre du
`GameState` ni évaluer `ScriptCondition`. V2-17, dans `map_gameplay`, possède
l'éligibilité stateful et la décision d'autorité. Les performances doivent être
mesurées dans V2-04, V2-17 et V2-41 ; aucun objectif chiffré n'est inventé ici.

### 13.5 Compatibilité temporaire

Pendant `dualRead` :

1. lire le claim qualifié de la source legacy ;
2. si claim présent, retourner V2 `handled` ou `claimedButIneligible`, jamais
   fallback ;
3. si claim absent et V2 `noMatch`, autoriser l'adapter legacy ;
4. en `v2Only`, ne jamais dispatch legacy ;
5. en `legacyOnly`, ne jamais dispatch V2 ;
6. tracer provenance et autorité en debug.

---

## 14. Migration legacy

### 14.1 Principes

```text
read old before write new
preview before mutate
single-write V2 after opt-in
single-manifest staged replacement with recovery journal
unknown data preserved or migration blocked
rollback proven before activation
```

### 14.2 Étapes

1. inventorier tous les `MapData.events`, nodes source Scenario et
   `MapPlacedElement` concernés ;
2. construire le graphe complet des références d'Event : conditions, World
   Rules, commandes, conséquences, sauvegardes et diagnostics ;
3. détecter IDs dupliqués entre maps et usages `consumedEventIds` ;
4. produire une proposition source par Event sans écrire ;
5. classer `exact`, `ambiguous`, `unsupported`, `manual` ;
6. produire records, mappings de progression et `LegacySourceClaim` ;
7. afficher le diff et les références manquantes ;
8. demander un opt-in explicite ;
9. sauvegarder le manifest et ses hashes ;
10. écrire un journal `prepared`, puis le manifest stagé et le renommer
    unitairement ;
11. relire, comparer sémantiquement et marquer le journal `committed` ;
12. activer single-write V2 seulement après vérification ;
13. garder lecteurs legacy et authoring source Scenario verrouillé pour les
    claims pendant la fenêtre de support ;
14. ne déprécier V1 qu'au gate V2-43.

Il n'existe pas de transaction atomique portable sur plusieurs fichiers. La
stratégie évite d'en promettre une : les maps et Scenarios legacy restent
inchangés, tandis que le registry et les claims sont écrits dans le manifest.
V2-08 possède le plan pur et le receipt ; V2-16 possède le repository journalé
et la récupération après crash ; V2-33 possède l'UX de preview/confirmation.
Avant V2-33, l'UI ne propose que `Voir le diagnostic de conversion`.

### 14.3 Heuristiques admissibles

| Legacy | Candidat V2 | Auto-conversion |
|---|---|---|
| actor/object avec entity stable explicitement liée | `entityInteract` | oui si référence unique |
| actor/object avec une seule entity compatible au même footprint | `entityInteract` | preview, confirmation requise |
| triggerZone correspondant exactement à un `MapTrigger` | `triggerEnter` | oui si ID/aire non ambigus |
| triggerZone par coordonnée seulement | aucun | manuel ou création source explicite |
| effect | aucun canon V0 | unsupported/manual |
| MapEvent multi-page first-valid | plusieurs candidats ordonnés ou adapter | jamais automatique sans groupe de consommation et équivalence prouvée |
| MapEvent autonome sans entity/trigger | source à matérialiser | BLOCKED jusqu'à V2-25 ; aucune création implicite |
| MapPlacedElement interactif | source hors union V0 | legacy ou conversion explicite en `MapEntity` |
| node Scenario source + action convertible vers une Scene unique | Event V2 | seulement si preuve sans perte |
| graph Scenario complexe | bridge legacy | pas de conversion automatique |

### 14.4 Collisions d'IDs consommés

Une migration ne peut pas deviner quel Event map-local était consommé lorsque
deux maps partagent le même ID. Les choix possibles sont :

- bloquer et demander une résolution ;
- marquer toutes les correspondances comme consommées ;
- conserver une table d'alias qualifiée après choix utilisateur.

La roadmap recommande le blocage avec preview par défaut. Cette politique reste
une décision utilisateur ouverte.

### 14.5 Rollback

Le rollback immédiat restaure le manifest sauvegardé uniquement si son token de
révision n'a pas changé depuis la migration. Après un nouvel authoring V2, une
restauration brute écraserait des données : elle est interdite et remplacée par
une migration compensatoire guidée. Après publication V2-only, il faut un export
V1 explicite et loss-aware ou accepter le point de non-retour. Aucun simple
feature flag ne retransforme un outcome qualifié en MapEvent positionné.

---

## 15. Authoring target

### 15.1 Deux entrées, un seul modèle

**Depuis Narrative Studio**

```text
Créer un événement
→ choisir l'intention source
→ choisir la map si nécessaire
→ choisir le PNJ / objet / zone / outcome réel
→ ajouter conditions
→ choisir la Scene
→ choisir one-shot ou réutilisable
→ valider
```

**Depuis Map Editor**

```text
Sélectionner une entity ou un trigger
→ Créer un événement pour cette source
→ ouvrir l'Event Builder avec source préremplie
```

La création d'une nouvelle source spatiale reste une action du Map Editor. Le
Narrative Studio peut proposer « Créer une source sur la carte », puis revenir
au flow, mais il ne possède pas la géométrie.

### 15.2 Structure cible selon la north star

```text
Navigation Narrative Studio
Liste projet des événements
Bibliothèque d'éléments permanente
Éditeur central en flow
Inspecteur factuel
```

La bibliothèque permanente de l'image est retenue pour V2, contrairement à la
simplification temporaire de NS-EVENT-41. Elle ne doit montrer comme authorables
que les concepts supportés. Résultats, réactions et monde sont libellés
`Lecture seule`, `Défini dans la scène` ou `À venir`.

### 15.3 Flow central

```text
Déclencheur + source réelle
→ Conditions
→ Scene / action principale
→ Résultats possibles projetés
→ Conséquences projetées en lecture seule
→ Diagnostics
```

### 15.4 Liste et recherche

La liste est project-level et peut être groupée par map, outcome ou état
`source manquante`. Elle affiche source, Scene, statut et diagnostics sans
exposer les IDs techniques par défaut.

### 15.5 États obligatoires

- aucun Event ;
- source non choisie ;
- source supprimée ;
- source déjà liée à un ou plusieurs Events ;
- Scene manquante ;
- Event non atteignable ;
- conflit de priorité ;
- plusieurs Events actifs sur la même source, avec gagnant projeté et action de
  résolution ;
- legacy non migré ;
- lecture seule ;
- migration requise ;
- runtime non supporté dans la version courante.

---

## 16. Validator target

Les noms ci-dessous sont des codes proposés, pas des diagnostics déjà livrés.

### Erreurs bloquantes

```text
EV2_EVENT_ID_DUPLICATE
EV2_SOURCE_MISSING
EV2_SOURCE_MAP_MISSING
EV2_SOURCE_ENTITY_MISSING
EV2_SOURCE_TRIGGER_MISSING
EV2_SOURCE_OUTCOME_MISSING
EV2_SOURCE_OUTCOME_PROVENANCE_MISSING
EV2_SCENE_MISSING
EV2_SOURCE_KIND_INCOMPATIBLE
EV2_LEGACY_MIGRATION_AMBIGUOUS
EV2_LEGACY_CLAIM_CONFLICT
EV2_PROGRESSION_REFERENCE_AMBIGUOUS
EV2_RUNTIME_SOURCE_UNSUPPORTED
```

### Warnings

```text
EV2_SOURCE_CONFLICT_UNORDERED
EV2_EVENT_UNREACHABLE
EV2_EVENT_SHADOWED
EV2_LEGACY_ID_COLLISION
EV2_MAP_ENTER_LOAD_POLICY_UNRESOLVED
EV2_SCENE_PROJECTION_INCOMPLETE
EV2_SOURCE_DELETED_SINCE_OPEN
EV2_DRAFT_NOT_PUBLISHABLE
```

### Gates de preuve

| Gate | Preuve minimale |
|---|---|
| Contrat | JSON positif/négatif, invariants, versions |
| Migration | fixtures avant/après, dry-run, rollback, unknown fields |
| Catalog | quatre sources, IDs absents, suppression/rename |
| Runtime | positif, négatif, priorité, consumed, reentrance, save/load |
| Authoring | deux entrypoints, source réelle, undo/save/reload |
| UI | empty/error/loading/legacy, accessibilité, no overflow |
| Golden Slice | trois sources + chaîne Lysa réelle |
| Readiness | suites packages, build desktop, Visual Gate, corpus migration |

Une suite monolithique finale ne remplace pas ces gates locaux. Chaque lot doit
prouver son contrat au moment où il est introduit.

---

## 17. Golden Slice

### 17.1 Trois Events minimum

| Event | Source | Conditions | Scene | Comportement |
|---|---|---|---|---|
| Rencontre Lysa au port | `entityInteract(map_port_brisants, npc_lysa)` | étape « aller au port » active | rencontre Lysa | one-shot |
| Alerte entrée du port | `triggerEnter(map_port_brisants, zone_port_entry)` | non consommé | arrivée au port | one-shot |
| Indice du verre salin | `entityInteract(map_marais_salants, clue_glass_object)` | quête/enquête active | découverte indice | one-shot ou reusable décidé par contenu |

Le lot V2-34 doit utiliser les IDs réellement présents ou créer les sources via
les opérations Map Editor prévues. Aucun de ces IDs n'est écrit dans Selbrume au
cours de RESET-00.

### 17.2 Chaîne Lysa

```text
npc_lysa réel
→ Event source entityInteract
→ conditions de progression
→ Scene rencontre Lysa
→ Yarn et choix
→ Cinematic si prévue
→ combat trainer
→ outcome victoire/défaite
→ Fact
→ Story Step
→ World Rule passive
→ Validator
```

### 17.3 Preuves requises

- authoring depuis Narrative Studio ;
- authoring depuis une sélection Map Editor ;
- sauvegarde projet, fermeture, réouverture ;
- focus réel « Voir sur la carte » ;
- déclenchement runtime positif et négatif ;
- one-shot après succès, pas après échec ;
- outcome re-dispatch sans boucle ;
- sauvegarde/chargement sans redéclenchement illégitime ;
- projections Scene en lecture seule ;
- capture desktop comparée à la north star.

---

## 18. Risques

| Risque | Gravité | Réduction prévue |
|---|---|---|
| troisième modèle Event sans extinction des deux anciens | critique | adapters bornés, single-write V2, gate dépréciation |
| migration ambiguë par position | critique | preview, blocage, choix source explicite |
| collision `consumedEventIds` | critique | inventaire corpus et politique signée |
| double dispatch V1/V2 | critique | registry mode, claims persistés et coordinateur unique |
| fallback legacy après Event V2 consommé | critique | `claimedButIneligible` interdit le fallback |
| brouillon incomplet exécuté | critique | record union ; seuls `configured + active` sont indexés |
| référence legacy non migrée | critique | inventaire graphe conditions/règles/commandes/conséquences |
| Event Builder devient Scene Builder | élevée | projections read-only et contract tests |
| suppression d'une source casse silencieusement l'Event | élevée | diagnostics et source deletion workflow |
| mapEnter redéclenché au load | élevée | progression V2-18 et bridge dédié V2-19 |
| outcome recursion | élevée | queue/guard/idempotence et tests |
| continuité runtime perdue à la sauvegarde | élevée | continuation sérialisable avant release |
| performance de lookup | moyenne | index source et gate corpus |
| pixel-perfect au détriment de l'honnêteté | moyenne | écarts fonctionnels documentés |
| roadmap trop large | moyenne | lots S/M, entry/exit gates, chemin minimal séparé |
| rollback prétendu après données V2-only | élevée | point de non-retour explicite |

---

## 19. Décisions ouvertes

Les décisions suivantes doivent être confirmées avant ou pendant les lots
indiqués. Elles ne bloquent pas la clôture documentaire de RESET-00.

1. **Registry canonique.** Confirmer `ProjectManifest.eventRegistry` avec schema,
   mode, records et claims comme source de vérité V2 avant V2-03.
2. **Identité.** Confirmer des IDs Event globalement uniques et immuables après
   publication avant V2-02.
3. **Collisions legacy.** Choisir blocage manuel, consommation de toutes les
   correspondances ou alias qualifié avant V2-08.
4. **Conflit multi-Events.** Confirmer un seul gagnant par occurrence en V0 et
   une priorité no-code contextuelle avant V2-04/V2-30.
5. **Load game.** Confirmer si un chargement réussi émet `mapEnter` avant V2-19.
6. **Fenêtre V1.** Fixer la durée de dual-read et les conditions de dépréciation
   avant V2-43.
7. **Bibliothèque permanente.** Confirmer que la north star remplace sur ce
   point la simplification NS-EVENT-41 pour le V2 avant V2-26.
8. **Suppression de source.** Choisir blocage, désactivation automatique ou
   réparation guidée avant V2-14/V2-31.
9. **Identité outcome.** Confirmer la référence qualifiée
   `(producerKind, producerId, outcomeId)` avant V2-01/V2-10.
10. **Brouillons.** Confirmer l'union `NarrativeEventRecord.draft/configured` et
    la règle « seuls configured + active sont runtime » avant V2-02.
11. **Autorité dual-read.** Confirmer les modes registry et le claim bloquant
    tout fallback legacy avant V2-03/V2-17.

Recommandations de l'audit : oui à 1, 2, 4, 7, 9, 10 et 11 ; blocage guidé pour
3 et 8 ;
`mapEnter` au load uniquement après restauration complète et avec raison
d'occurrence explicite ; support V1 jusqu'au Go/No-Go V2-43 au minimum.

---

## 20. Roadmap recommandée

La roadmap vivante est créée dans
`MVP Selbrume/road_map_event_builder_v2.md`.

| Phase | Sujet | Lots |
|---|---|---:|
| A | Canonical Architecture Decisions | 1 |
| B | Domain Contracts | 4 |
| C | Legacy Adapters & Migration | 4 |
| D | Source Catalogs & Read Models | 4 |
| E | Authoring Operations | 4 |
| F | Runtime Dispatch | 6 |
| G | Map Editor Integration | 3 |
| H | Event Builder V2 UI | 5 |
| I | Validator & Diagnostics | 3 |
| J | Selbrume Golden Slice | 4 |
| K | Pixel-Perfect Visual Closure | 3 |
| L | Final Readiness Gate | 3 |
| **Total** | **12 phases** | **44 lots** |

Le total inclut RESET-00 et 43 lots futurs. La trajectoire minimale Golden Slice
ne constitue pas une release finale ; elle reporte migration complète, états
secondaires et pixel closure.

### Chemin critique minimal

```text
RESET-00
→ V2-01 → V2-02 → V2-03 → V2-04
→ V2-05 → V2-06 → V2-07 → V2-08
→ V2-09 → V2-10 → V2-11 → V2-12
→ V2-13 → V2-14 → V2-15 → V2-16
→ V2-17 → V2-18 → V2-19 → V2-20 → V2-21 → V2-22
→ V2-23 → V2-24 → [V2-25 si source Golden absente]
→ V2-26 → V2-27 → V2-28 → V2-29 → V2-30
→ V2-31 → V2-32
→ V2-34 → V2-35 → V2-36 → V2-37
```

### Chemin complet

```text
Phase A → B → C → D → E → F → G → H → I → J → K → L
```

Certaines branches sont parallélisables après stabilisation des contrats, mais
aucune UI ou migration ne doit précéder les contrats source/Event et leur JSON.

---

## 21. Prochain lot exact

```text
NS-EVENT-V2-01 — Canonical Narrative Event Source Ref Contract V0
```

### Scope strict proposé

- créer uniquement l'union typée des quatre sources ;
- aucune définition Event complète ;
- aucun stockage manifest ;
- aucun runtime ;
- aucune migration ;
- aucune UI ;
- tests JSON/invariants/source keys et compatibilité de lecture uniquement.

### Entry gate

- RESET-00 approuvé ;
- décision `ProjectManifest.eventRegistry`/schema/mode/claims confirmée ;
- politique d'identité globale Event confirmée ;
- référence outcome qualifiée confirmée ;
- union record `draft/configured` confirmée ;
- nom public du contrat validé.

---

## 22. Evidence Pack

### 22.1 Gate 0 exact

```text
$ pwd
/Users/karim/Project/pokemonProject

$ git branch --show-current
main

$ git status --short --untracked-files=all
 M packages/map_editor/pubspec.lock

$ git diff --stat
 packages/map_editor/pubspec.lock | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)

$ git diff --name-only
packages/map_editor/pubspec.lock
```

Le lockfile est un drift préexistant. Il n'a pas été modifié, restauré ou
revendiqué par ce lot.

```text
$ git log --oneline -n 30
56882754 NS-EVENT-41-bis: Truthful Stepper & Secondary Details Access Closure V0
ed91ca2c NS-EVENT-41: Event Builder Simplified Guided Configuration Layout V0
88314c22 NS-EVENT-40: Event Builder Shell-Level Pixel Polish & Real App Visual QA V0
89b81e47 NS-EVENT-39: Event Builder Reference UI Redesign / Flow-Based Layout V0
6fab98e4 NS-EVENT-38: Event Builder Map Placement & Post-Creation Guided Setup UX V0
c017dc8f NS-EVENT-37: Event Builder First Event Creation UX Simplification V0
786e86da NS-EVENT-36: Event Builder Real App Manual Creation Availability Fix / Layer Gate UX - PASS
fb440ae8 NS-EVENT-35: Event Builder Trigger Variants Runtime Handoff / Lifecycle Semantics Gate - PARTIAL
3f96204e NS-EVENT-34: Event Builder Runtime Handoff Smoke / Editor-authored Scene Target Gate - PASS
0b180895 NS-EVENT-33: Event Builder MVP Closure / End-to-End Authoring Readiness Gate - DONE
25cdf062 NS-EVENT-32: Event Builder World Rules Projection UX Closure / Validation Gate - DONE
972c73ad NS-EVENT-31: Implement Passive World Rules Projection UI V0 - DONE
a1480aeb NS-EVENT-30: Implement Passive World Rules Projection Read Model V0
3502ca74 NS-EVENT-29: Implement Linked Scene Consequences World Impact Projection Read Model V0
906809bb NS-EVENT-28: Polish Event Builder World Changes Read-only Projection UI
e13ebb6e NS-EVENT-27: Implement Event Builder Scene Outcomes and Lifecycle Projection UI V0
b7fce79e NS-EVENT-26: Implement Event Builder Scene Outcomes and Lifecycle Projection Read Model V0
36a8f362 NS-EVENT-25: Add outcomes, reactions, and consequences contract alignment audit report
8c2bb4b2 ns_event_v1: Ajout des composants de l'éditeur d'événements et rapports associés
54c59fba ns_event_16: Consolidation de la disposition des blocs et disponibilité de la création d'activation de carte
8b3866a8 ns_event_15: Ajout de l'auteur des types de déclencheurs pour les événements
8a5996be ns_event_14: Ajout des conditions de consommation d'événements
7f490b9e ns_event_13: Ajout de l'auteur des conditions de fait pour les événements
26bec474 ns_event_12: Ajout de l'auteur des comportements pour les événements
00698aea ns_event_11: Ajout de l'auteur des actions de scène pour les événements
fc0e0be0 ns_event_10: Ajout de la saisie du titre pour les brouillons d'événements
cdedbe6e ns_event_09: Fermeture du flux de création de brouillon
d3f1866f ns_event_08: Ajout du sélecteur de position explicite sur la carte pour la création de brouillon
30ae9429 ns_event_07: Ajout de l'entrée UI explicite pour la création de brouillon avec position
3bd06d2b ns_event_06: Ajout des opérations de création de brouillon pour l'éditeur d'événements
```

### 22.2 Image north star

```text
Chemin : /Users/karim/Desktop/assets/pokeMap/définitive/4 - événements/1 - événements.png
Dimensions : 1672 × 941
SHA-256 : 2072679b3b861a63c068628450705d39e70ad59dc5067e0a0bf91c0bcbe8c885
Statut : disponible et inspectée
```

### 22.3 Sources produit

- `MVP Selbrume/narrative_studio.md` ;
- `MVP Selbrume/selbrume.md` ;
- Golden Slice Lysa confirmé dans les deux documents.

### 22.4 Sources code principales

| Preuve | Fichier / zone |
|---|---|
| position obligatoire | `packages/map_core/lib/src/models/map_event_definition.dart:21` |
| MapEvents map-local | `packages/map_core/lib/src/models/map_data.dart:20` |
| source binding réemballe MapEvent | `packages/map_core/lib/src/authoring/event_builder_contract.dart:57` |
| position explicite à la création | `packages/map_core/lib/src/authoring/event_builder_draft_creation_operations.dart:27` |
| quatre sources authoring | `packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart:16` |
| picker quatre sources | `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart:482` |
| Event registry absent | `packages/map_core/lib/src/models/project_manifest.dart:311` |
| entity possède pos/size | `packages/map_core/lib/src/models/map_data.dart:206` |
| trigger possède area | `packages/map_core/lib/src/models/map_data.dart:337` |
| quatre sources runtime | `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart:16` |
| scan/premier match | `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:143` |
| wildcard map legacy | `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:1334` |
| consommation ID global nu | `packages/map_core/lib/src/models/game_state.dart:102` |
| triggerZone MapEvent partiel | `reports/narrativeStudio/events/ns_event_35_trigger_variants_runtime_handoff_lifecycle_semantics_gate.md` |

### 22.5 Fichiers créés

```text
reports/narrativeStudio/events/ns_event_reset_00_canonical_event_sources_map_binding_audit_v0.md
MVP Selbrume/road_map_event_builder_v2.md
reports/narrativeStudio/events/ns_event_reset_00_event_builder_v2_reference_ui_spec_v0.md
```

Le présent rapport est l'inventaire détaillé des décisions. La roadmap contient
les 44 lots avec scope, dépendances, fichiers probables, tests, rollback et
gates. La spécification visuelle contient les mesures et critères de fidélité.

### 22.6 Fichiers de production modifiés

```text
Aucun.
```

### 22.7 Tests, analyse et build

```text
flutter test : non exécuté, non applicable au lot documentaire
dart analyze : non exécuté, non applicable au lot documentaire
flutter analyze : non exécuté, non applicable au lot documentaire
build : non exécuté, explicitement non requis
build_runner : non exécuté, interdit
```

### 22.8 Gate final

```text
$ git status --short --untracked-files=all
 M packages/map_editor/pubspec.lock
?? "MVP Selbrume/road_map_event_builder_v2.md"
?? reports/narrativeStudio/events/ns_event_reset_00_canonical_event_sources_map_binding_audit_v0.md
?? reports/narrativeStudio/events/ns_event_reset_00_event_builder_v2_reference_ui_spec_v0.md

$ git diff --stat
 packages/map_editor/pubspec.lock | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)

$ git diff --name-only
packages/map_editor/pubspec.lock

$ git diff --check
[aucune sortie, exit 0]
```

`git diff` n'inclut pas les fichiers non suivis. Les trois documents ont donc
été contrôlés individuellement avec :

```text
git diff --no-index --check /dev/null <document>
```

Chaque commande a produit zéro warning de whitespace. Son exit `1` est le code
normal de `--no-index` lorsqu'un fichier diffère de `/dev/null`.

La recherche anti-scope requise retourne :

```text
packages/map_editor/pubspec.lock
```

Ce résultat est exactement le drift préexistant du Gate 0. Aucun autre chemin
de production n'apparaît. Le lockfile n'a pas été touché par RESET-00.

Contrôles structurels :

```text
Audit : 25 sections attendues
Spécification visuelle : 18 sections attendues
Roadmap : 12 phases
Roadmap : 44 lots, RESET-00 inclus
Champs obligatoires par lot : 20/20 présents sur chacun des 44 lots
Marqueur provisoire : aucun
Liens existants vérifiés : 19/19
```

Hashes des deux compagnons stables au moment du gate :

```text
a4604390efa462e45f78cc2543193305159a22187dc57fd7774a5e10e886f6ca  MVP Selbrume/road_map_event_builder_v2.md
a23f33b68d6232afa9551b1fd08ffb4e048247f474bfcc48b3e4b17dc45ea0ef  reports/narrativeStudio/events/ns_event_reset_00_event_builder_v2_reference_ui_spec_v0.md
```

Le hash du rapport qui contient ce bloc ne peut pas être auto-inscrit sans se
modifier lui-même ; il est recalculé après la dernière écriture dans le gate de
sortie externe.

---

## 23. Auto-review

### Ce que la décision résout

- elle rend les PNJ, objets, zones, maps et outcomes explicitement référencés ;
- elle supprime la position arbitraire du modèle Event ;
- elle permet une liste globale et un index source → Events ;
- elle conserve la frontière Event / Scene ;
- elle offre une migration progressive plutôt qu'une rupture ;
- elle exploite les sources déjà présentes sans promouvoir Scenario comme Event.

### Ce qu'elle ne prouve pas encore

- que `ProjectManifest.eventRegistry` et son codec indépendant restent simples
  après prototype JSON ;
- que chaque MapEvent legacy trouve une source sans intervention ;
- que le lifecycle one-shot proposé s'intègre à toutes les continuations Scene ;
- que l'index atteint une performance suffisante sur un corpus réel ;
- que la north star est réalisable pixel-perfect avec le shell actuel ;
- que tous les contenus Selbrume requis existent déjà sous les IDs proposés.

### Faiblesses conscientes

1. Option D introduit un nouveau modèle alors que deux modèles voisins existent.
   La roadmap compense par adapters, single-write et gate de dépréciation.
2. Quarante-quatre lots sont nombreux. Ce découpage est volontaire pour éviter
   un lot qui mélange schema, migration, runtime et UI, mais doit être réévalué
   après chaque phase.
3. La règle « un seul gagnant » simplifie le V0 et peut frustrer des auteurs qui
   veulent plusieurs réactions indépendantes. Une extension future doit être
   explicite, pas accidentelle.
4. La migration des MapEvents positionnés est intrinsèquement loss-aware. Le
   rapport refuse de promettre une conversion automatique totale.
5. La bibliothèque permanente augmente la densité. Elle est retenue parce que
   l'utilisateur désigne l'image comme objectif, avec responsive et modes
   compacts à valider en Phase K.

### Scope check

Le lot n'a modifié aucun contrat, aucun JSON, aucune map, aucun runtime, aucun
widget et aucun generated file. Il n'a pas commencé V2-01.

---

## 24. Review contradictoire

Deux reviewers read-only ont lu les trois documents. Ils n'ont modifié aucun
fichier. Chacun a rendu un FAIL initial, puis un spot-check PASS après
correction de tous les blockers.

### R1 — Architecture

| Objection initiale | Correction appliquée | Statut final |
|---|---|---|
| aucun propriétaire persistant du dispatch V1/V2 | registry mode + `LegacySourceClaim(targetEventIds)` + coordinateur unique | résolu |
| modèle toujours valide incapable de stocker un brouillon | union `NarrativeEventRecord.draft/configured` | résolu |
| chemin minimal omettait Phase C puis V2-12/24/30 | dépendances ajoutées ; V2-25 conditionnel | résolu |
| migration limitée à `consumedEventIds` | graphe conditions/Rules/commandes/conséquences/saves + namespace V2 | résolu |
| V2-04 et V2-17 dupliquaient le resolver | V2-04 index structurel ; V2-17 autorité/éligibilité `map_gameplay` | résolu |
| atomicité multi-fichiers irréaliste | plan pur V2-08, manifest journalé V2-16, UX V2-33, two-step V2-25 | résolu |
| MapEvent autonome traité comme position dupliquée | legacy/BLOCKED ou matérialisation explicite V2-25 | résolu |
| `ProjectVersion.v2` couplait manifest et maps | `NarrativeEventRegistry.schemaVersion` indépendant | résolu |
| kinds Entity/Trigger et MapPlacedElement non arbitrés | matrice d'éligibilité V0 explicite | résolu |
| outcome IDs locaux forcés globaux | `NarrativeOutcomeRef` qualifiée par producteur | résolu |
| conditions et cardinalité ambiguës | AND court-circuité, vide=true ; Event référence source | résolu |

Le dernier spot-check R1 a vérifié le chemin critique et l'entry gate V2-01 :

```text
Verdict final R1 Architecture : PASS
Nouveau blocker : aucun
```

### R2 — UX et honnêteté fonctionnelle

| Objection initiale | Correction appliquée | Statut final |
|---|---|---|
| faux drop targets décoratifs | grips/targets/textes absents jusqu'au drag/drop + clavier fonctionnels | résolu |
| cinq panneaux impossibles à 1440 | seuil 1480 avec équation ; bibliothèque escamotable sous 1480 | résolu |
| concurrence multi-Events invisible | concurrents, priorité humaine, gagnant projeté et action dédiée | résolu |
| choix de source non testable | matrice quatre pickers + persistance choisir/save/reopen | résolu |
| bibliothèque mélange Event-owned/Scene-owned | deux groupes, aucun Ajouter/grip côté Scene, `Ouvrir la Scene` | résolu |
| aucun propriétaire UX de migration | V2-33 possède preview/confirmation/recovery/rollback | résolu |
| vocabulaire trop moteur | glossaire no-code et libellés humains obligatoires | résolu |
| scroll/focus/3+ outcomes indécis | scrolls propriétaires, Escape/focus retour, branches en liste | résolu |
| mesures non reproductibles | toutes coordonnées `[E]`, DPR 1.0/normalisation, promotion `[M]` seulement avec artefact | résolu |

Le dernier spot-check R2 a vérifié le reclassement métrologique :

```text
Verdict final R2 UX / honnêteté : PASS
Nouveau blocker : aucun
```

### Verdict contradictoire consolidé

```text
Architecture : PASS
UX source-first : PASS documentaire
Honnêteté Event / Scene : PASS
Migration / rollback : PASS comme stratégie, non encore implémentée
Pixel fidelity : SPEC READY, preuve future V2-38 à V2-40
```

---

## 25. Critique du prompt

### Points solides

- le prompt nomme correctement le problème structurel ;
- il interdit de coder avant l'architecture et la migration ;
- il exige l'inventaire des contrats concurrents ;
- il protège Event ≠ Scene ;
- il impose une north star sans exiger une copie fonctionnelle aveugle ;
- il exige rollback, Golden Slice et preuves avant dépréciation.

### Hypothèses corrigées

1. Le runtime ne part pas de zéro : les quatre sources sont déjà présentes dans
   le pipeline Scenario.
2. `NarrativeEventSourcePickerOption` est utile mais n'est pas nécessairement le
   futur contrat canonique ; c'est un read model.
3. PNJ et objets partagent bien `MapEntity`, avec des kinds/payloads différents.
4. `triggerZone` existe dans `MapEventType`, mais son entrée de zone n'est pas
   fonctionnelle dans le pipeline MapEvent.
5. Une migration automatique générale serait dangereuse : la position seule
   ne prouve pas l'identité d'une source.

### Tensions du prompt

- Il exige une roadmap « exhaustive » et des lots petits, ce qui produit un
  document long. La roadmap est rendue vivante pour permettre sa réduction
  après chaque gate.
- Le doublon « un chemin critique est fourni » dans les critères est sans impact.
- `codex_rule.md` demande que le rapport reproduise le contenu complet de tous
  les fichiers créés. Appliquée au rapport lui-même, cette règle est
  auto-référentielle et impossible à satisfaire littéralement. Dupliquer les
  2 000+ lignes des deux autres livrables rendrait aussi la roadmap moins
  vérifiable. Ce lot fournit à la place les trois artefacts complets directement,
  leurs chemins, leur inventaire, puis leurs hashes au gate final.
- Le gate final attendu omet le drift `packages/map_editor/pubspec.lock` alors
  que le prompt autorise explicitement les drifts préexistants. Le statut final
  le séparera clairement.

### Recommandation pour les futurs prompts

Demander un Evidence Pack par phase plutôt qu'un rapport reproduisant ses propres
artefacts, fixer les décisions utilisateur obligatoires dès le début de V2-01,
et conserver la règle stricte « aucun lot ne mélange schema, migration, runtime
et UI ».
