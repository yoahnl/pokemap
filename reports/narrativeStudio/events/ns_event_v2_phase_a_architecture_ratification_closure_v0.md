# NS-EVENT-V2 - PHASE A - Architecture Ratification Closure V0

## 1. Résumé exécutif

```text
Lot : NS-EVENT-V2 - PHASE A
PHASE A : CLOSED
Gate de sortie : ACCEPTED
Architecture : Option D ratifiée avec corrections
Code de production : aucun
Phase B commencée : non
Blockers restants pour Phase B : aucun
```

Phase A transforme les recommandations de RESET-00 en vingt décisions
normatives. Le résultat est un Event project-level, une source typée réelle,
zéro position sur l'Event, exactement une Scene pour chaque Event configuré,
un registry projet versionné et une autorité runtime explicite.

Les corrections principales apportées à RESET-00 sont :

- Yarn n'est pas un producteur autonome V0 ; il réémet via la Scene ;
- les conditions Story Step sont exclues du V0 car leurs IDs ne sont pas
  globalement qualifiés et le contrat actuel ne les compile pas honnêtement ;
- une Scene active ne promet pas de reprise durable : save/load est refusé ;
- l'outbox outcome possède une machine de livraison et une limite de récursion ;
- les claims couvrent une cohorte legacy complète, pas une page ou un node nu ;
- publier produit `configured(enabled=false)` ; activer est une commande
  séparée ;
- le JSON V2 est closed-world et fail-closed sans perte de bytes inconnus.

## 2. Relation RESET-00 / Phase A

RESET-00 reste la baseline d'audit et son commit est toujours `HEAD` :
`d26bfa9c`. Aucun changement de production postérieur ne l'a rendu obsolète.

Phase A ne réécrit pas l'audit historique. Elle le surclasse par le ledger
`ADR-EV2-001..020` pour les décisions laissées ouvertes. Aucune erreur factuelle
majeure n'a nécessité d'addendum à l'audit.

La spécification visuelle RESET-00 a été corrigée, comme l'autorisait le prompt,
car les ADRs ratifiés invalidaient cinq formulations : winner statique, Yarn
autonome, conversion implicite d'une source supprimée, side sheet dite non
bloquante et publication confondue avec activation.

## 3. Usage MCP Dart

Le MCP Dart était disponible et a été utilisé avant écriture.

Roots ajoutés :

```text
file:///Users/karim/Project/pokemonProject/packages/map_core
file:///Users/karim/Project/pokemonProject/packages/map_editor
file:///Users/karim/Project/pokemonProject/packages/map_runtime
file:///Users/karim/Project/pokemonProject/packages/map_gameplay
```

Symboles résolus :

```text
MapEventDefinition
MapEventPage
EventPosition
MapEventType
MapEntity
MapTrigger
MapData
ProjectManifest
EventBuilderContractView
EventBuilderSourceBinding
EventBuilderTriggerBinding
NarrativeScenarioAuthoringSourceDraft
NarrativeScenarioAuthoringSourceKind
NarrativeEventSourcePickerOption
NarrativeEventSourceKind
ScenarioRuntimeSourceEvent
ScenarioRuntimeExecutor
GameState
SceneAsset
SceneConsequence
WorldRuleDefinition
EventBuilderWorkspace
NarrativeWorkspaceCanvas
EditorNotifier
EditorState
```

Constats MCP : le registry V2 n'existe pas ; les pipelines Scenario et MapEvent
restent concurrents ; `ProjectManifest` n'a aucun Event project-level ;
`GameState` ne possède que `consumedEventIds` legacy ; les opérations
`narrative_event_source_authoring_operations.dart` sont un pont Scenario actuel,
pas un registry V2.

## 4. Sous-agents

Six sous-agents réels, deux reviewers contradictoires et l'orchestrateur
principal ont été utilisés.

| Passe | Agent | Verdict initial | Arbitrage final |
|---|---|---|---|
| A - Domain Contract | Newton | ACCEPT with amendments | noms publics retenus ; Story Step exclu après preuve d'identité non qualifiée |
| B - Runtime Authority | Bohr | ACCEPT with amendment | reprise durable rejetée V0 ; save busy pendant Scene |
| C - Identity/Persistence | Huygens | ACCEPT with gates | UUIDv7, registry nullable, outbox ; battle public ref retenu |
| D - Migration | Poincare | CONDITIONAL PASS | claims par cohortes, tombstones fail-closed, rollback evidence-based |
| E - UX/Map Ownership | Zeno | PASS with corrections | liste projet, position map-owned, bibliothèque honnête |
| F - Phase Governance | Hilbert | BLOCKED avant artefacts | objections résolues par ledger, F1/F2 et Gate B |
| R1 - Architecture | Mencius | FAIL sur JSON/claims/lifecycle | PASS après quatre boucles de correction |
| R2 - Product/UX | Hooke | FAIL sur vérité UI | PASS après trois boucles de correction |
| Orchestrateur | principal | arbitrage | Phase A fermée après PASS R1/R2 |

Les agents étaient strictement read-only. Toute écriture documentaire a été
faite par l'orchestrateur.

## 5. Audit de fraîcheur du repository

### Contrats actuels

- `MapEventDefinition` exige `EventPosition` et contient des pages.
- `MapEntity` porte `pos/size` ; `MapTrigger` porte `area`.
- `ScenarioAsset` expose déjà quatre concepts source, mais sous bindings
  universels et outcomes non qualifiés.
- `EventBuilderContractView` reste basé sur un `MapEventDefinition` map-local.
- `ProjectManifest` contient Scenes/Scenarios/Facts/World Rules, sans registry.
- `GameState.consumedEventIds` est un set legacy nu.
- `ScenarioRuntimeExecutor` fait un first-match Scenario ; le chemin
  MapEvent-to-Scene reste séparé.
- `loadGame` ne produit actuellement aucun `mapEnter` équivalent.

### Risques initiaux

```text
double dispatch V1/V2
collision IDs map-locaux dans les saves
drop de JSON inconnu par codec généré
source supprimée rebranchée silencieusement
Story Step non qualifié
outcome Scene/Yarn/Battle ambigu
save pendant une Scene suspendue non sérialisable
Event Builder visuellement fidèle mais métier faux
```

### Verdict de fraîcheur

`PASS`. RESET-00 est la dernière révision Git et ses constats structurels sont
toujours présents. Phase A devait ratifier, pas réauditer une architecture déjà
remplacée.

## 6. Liste des décisions examinées

| ID | Sujet | Statut |
|---|---|---|
| A-01 | architecture canonique | Accepted |
| A-02 | Event canonique | Accepted |
| A-03 | source canonique | Accepted |
| A-04 | outcome qualifié | Accepted |
| A-05 | draft/configured | Accepted |
| A-06 | registry/JSON | Accepted |
| A-07 | modes/autorité | Accepted |
| A-08 | claims/cohortes | Accepted |
| A-09 | identité Event | Accepted |
| A-10 | propriété spatiale | Accepted |
| A-11 | plusieurs Events/source | Accepted |
| A-12 | conditions V0 | Accepted |
| A-13 | lifecycle | Accepted |
| A-14 | progression/outbox | Accepted |
| A-15 | mapEnter au load | Accepted |
| A-16 | suppression source | Accepted |
| A-17 | collisions migration | Accepted |
| A-18 | fenêtre dual-read | Accepted |
| A-19 | bibliothèque responsive | Accepted |
| A-20 | Event vers Scene | Accepted |

## 7. Décisions ratifiées

Les noms publics normatifs sont :

```text
NarrativeEventSourceRef
NarrativeEventSourceKind
NarrativeOutcomeRef
NarrativeOutcomeProducerKind
NarrativeEventCondition
NarrativeEventReusePolicy
NarrativeEventDefinition
NarrativeEventDraft
NarrativeEventRecord
NarrativeEventRegistry
EventSystemMode
LegacySourceRef
LegacySourceClaimMember
LegacySourceClaim
EventRegistryDecodeResult
NarrativeEventProgress
NarrativeOutcomeDelivery
ValidatedLegacyClaimIndex
```

Les quatre sources V0 sont :

```text
entityInteract(mapId, entityId)
triggerEnter(mapId, triggerId)
mapEnter(mapId)
outcomeReceived(NarrativeOutcomeRef)
```

## 8. Décisions rejetées

- Event positionné ou position optionnelle : rejeté.
- Source raw tile, label ou clé concaténée : rejeté.
- Event-owned outcomes/reactions/consequences/world mutations : rejeté.
- Yarn producer autonome V0 : rejeté.
- `ScriptCondition` arbitraire ou Story Step nu : rejeté.
- micro-actions directes dans Event : rejeté.
- publication active par défaut : rejeté.
- reprise à mi-Scene sans checkpoint sérialisable : rejeté.
- claim par page, bare nodeId ou claim partiel : rejeté.
- fallback legacy après claim ou échec V2 : rejeté.
- feature flag indépendant de `EventSystemMode` : rejeté.
- force-delete ou rebranchement par nom/position : rejeté.
- faux drag/drop et library Scene-owned authorable : rejeté.

## 9. Architecture canonique finale

```text
ProjectManifest
└── eventRegistry?
    ├── schemaVersion = 1
    ├── mode = legacyOnly | dualRead | v2Only
    ├── records
    │   ├── draft
    │   └── configured(definition, enabled)
    └── legacyClaims

NarrativeEventDefinition
├── source: NarrativeEventSourceRef
├── conditions: AND V0
├── sceneId: SceneAsset.id
├── reusePolicy
├── priority
└── order

MapEntity / MapTrigger / MapData
└── position, area ou identité map
```

## 10. Modèle conceptuel final

`NarrativeEventDefinition` possède exactement `id`, `name`, `source`,
`conditions`, `sceneId`, `reusePolicy`, `priority`, `order`.

`NarrativeEventDraft` garde les mêmes champs d'authoring, mais `source`,
`sceneId` et `reusePolicy` sont optionnels. Le draft n'est jamais indexé.

`NarrativeEventRecord.configured` porte `enabled`. La publication valide les
références et produit `enabled=false`. L'activation est séparée. Seuls les
records enabled dont les références sont contextuellement valides sont
dispatchables ; un conflit imported reste indexé et trié défensivement par ID.

Le JSON exact, les discriminants, les null policies, les résultats de decode et
les examples canoniques sont inscrits dans le ledger.

## 11. Event / Scene action policy

Option A est ratifiée : chaque Event configuré cible une Scene normale.

```text
Event déclenche.
Scene orchestre.
Cinematic met en scène.
Battle résout.
Fact persiste.
World Rule projette.
Validator diagnostique.
```

Une porte pure reste `MapWarp`. Un panneau/pickup natif peut rester map-owned si
son contrat gameplay suffit. Dès qu'une interaction est conditionnelle,
branchée ou persistante narrativement, elle suit Event -> Scene.

`Créer une Scene simple` peut accélérer l'authoring, mais crée un asset Scene
visible, ouvrable et évolutif. Aucun pseudo-asset Scene n'est caché dans l'Event.

## 12. Identités et namespaces

Event ID :

```text
evt_<uuid-v7 lowercase canonical>
^evt_[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$
```

Il est généré et figé dès le draft. Duplication = nouvel ID. Import collisionné
= annulation ou re-key explicite de toute la fermeture.

Outcome :

```text
scene          -> SceneAsset.id + SceneOutcome.id
battle         -> BattlePublicContract.battleRefId + outcomeId
legacyScenario -> ScenarioAsset.id + raw legacy outcomeId
```

Progression V2 :

```text
consumedNarrativeEventIds
pendingNarrativeOutcomeDeliveries
deliveredNarrativeOutcomeDeliveryIds
```

`consumedEventIds` reste legacy et séparé. Aucun namespace running/failed n'est
persisté en V0.

## 13. Registry / modes / claims

`ProjectManifest.eventRegistry` est nullable. Absent/null = `legacyOnly`
effectif et aucune écriture implicite. Le registry present exige quatre champs.

| Mode | Claim | Candidat V2 | Résultat |
|---|---|---|---|
| legacyOnly | inert | non évalué | legacy une fois |
| dualRead | absent | aucun | noMatch puis legacy |
| dualRead | absent | éligible | handled V2 |
| dualRead | valide | aucun éligible | claimedButIneligible, aucun fallback |
| dualRead | valide | éligible | handled V2 |
| v2Only | ignoré | aucun | noMatch, aucun legacy |
| v2Only | ignoré | éligible | handled V2 |

Un claim couvre une cohorte complète. Ses membres qualifient MapEvent ou
Scenario node. `cohortId`, fingerprints et receipt utilisent SHA-256 de JSON
RFC 8785 JCS avec préimages exactes. Phase B valide la structure ; Phase C la
complétude réelle du corpus.

Un registry non décodable bloque tout runtime/playtest. Une collision globale
de claims bloque le démarrage dualRead. Un claim décodé mais stale/partial
devient un tombstone per-source et retourne `claimedButIneligible` sans bloquer
les sources non liées.

## 14. Migration et rollback

```text
LEGACY_ONLY -> DRY_RUN -> PREPARED -> DUAL_READ -> V2_ONLY
                  \-> failure/revision mismatch -> BLOCKED or restore receipt
```

Le dry-run n'écrit rien. PREPARED exige backup, hashes, revisions et journal.
DUAL_READ ne commence qu'après commit puis reload sémantique.

Les collisions `consumedEventIds` ne sont jamais devinées. L'utilisateur choisit
consommer tous les groupes pour préserver le comportement legacy, sélectionne
explicitement des cibles avec receipt irréversible, ou annule.

Le point de non-retour simple est la première progression/référence V2 non
représentable exactement en legacy. Après ce point, changer seulement le mode
est interdit ; il faut une migration compensatoire testée.

## 15. Ownership map / source / position

| Source | Owner spatial | Event stocke |
|---|---|---|
| entityInteract | MapEntity.pos/size | mapId + entityId |
| triggerEnter | MapTrigger.area | mapId + triggerId |
| mapEnter | MapData.id | mapId |
| outcomeReceived | aucun | NarrativeOutcomeRef |

Un MapEvent autonome reste legacy ou passe par une matérialisation explicite
V2-25. Voir sur la carte résout la source courante ; aucune coordonnée n'est
copiée dans Event/Scene.

La suppression de source est bloquée tant que des dépendances existent.
`Détacher` est explicite et transforme en draft. Une suppression externe garde
la référence cassée et bloque, sans mutation au load.

## 16. Runtime semantics

- sélection : priority DESC, order ASC, eventId ASC ;
- un seul candidat par snapshot ; aucun second choix après échec d'exécution ;
- oneShot consommé après End + awaits + consequences + commit ;
- reusable jamais auto-consommé ;
- save/load refusé pendant Scene active ou delivery dispatching ;
- battle standalone commit puis outcome ;
- battle Scene-hosted write-back stagé dans le state parent ;
- outcomes Battle hébergés puis outcome Scene en FIFO après commit parent ;
- parent Scene fail = state Battle stagé et outcomes provisoires abandonnés ;
- outbox : pending -> dispatching mémoire -> delivered ;
- noMatch/ineligible terminaux ; consumer commencé puis fail terminal ;
- retry uniquement pour infrastructure avant planning, trois tentatives ;
- profondeur de corrélation maximale : 8 ;
- `mapEnter saveRestore` exactement une fois après restauration complète.

## 17. UX source-first

```text
Nom
-> type d'occurrence
-> source réelle
-> conditions
-> Scene
-> comportement
-> publier inactif
-> activer séparément
```

La liste est project-level. Les groupes map sont des facettes, pas des owners.
Les drafts sans source et Events outcome restent visibles.

L'état `Aucun élément déclencheur choisi` est distinct d'une source cassée : il
offre Choisir, aucun CTA map et bloque publication.

La concurrence affiche `Premier candidat évalué selon l'ordre actuel`, jamais
une promesse statique. Monter/Descendre et clavier remplacent un drag obligatoire.

## 18. North star et bibliothèque

Image vérifiée :

```text
/Users/karim/Desktop/assets/pokeMap/définitive/4 - événements/1 - événements.png
1672 x 941
SHA-256 2072679b3b861a63c068628450705d39e70ad59dc5067e0a0bf91c0bcbe8c885
```

Elle reste normative pour composition, densité et hiérarchie, pas pour ownership
métier.

| Largeur Narrative Studio | Bibliothèque |
|---|---|
| >= 1480 | inline permanente |
| 1280..1479 | side sheet modale, fond inerte, focus trap/retour, Escape |
| < 1280 | état desktop V0 non supporté, état/focus préservés |

La bibliothèque sépare `Configurer l'événement` de `Dans la Scene liée`.
Résultats/réactions/monde sont read-only. Aucun faux drag/drop.

## 19. Gouvernance par phases

```text
1 phase = 1 mission
1 ancien lot = 1 jalon interne
1 phase = 1 rapport + 1 Evidence Pack
```

Statuts : mission `PLANNED/READY/IN_PROGRESS/CLOSED/BLOCKED/ROLLED_BACK`, gate
`PENDING/ACCEPTED/REJECTED`, jalon `PLANNED/IN_PROGRESS/PASS/BLOCKED/WAIVED`.

Une invalidation d'ADR, migration ambiguë, vérification obligatoire échouée ou
preuve de rollback perdue arrête la mission et exige Blocker Report + nouvel ADR.

## 20. Mapping phases / jalons

| Mission | Jalons |
|---|---|
| A CLOSED | RESET-00 + ratification Phase A |
| B | V2-01..04 |
| C | V2-05..08 |
| D | V2-09..12 |
| E | V2-13..16 |
| F1 - Runtime Authority & Progress | V2-17..18 |
| F2 - Runtime Source Bridges | V2-19..22 |
| G | V2-23..25 |
| H | V2-26..30 |
| I | V2-31..33 |
| J | V2-34..37 |
| K | V2-38..40 |
| L | V2-41..43 |

Les 43 IDs V2 et RESET-00 sont conservés : 44 jalons tracés au total.

## 21. Entry Gate Phase B

Gate : `ACCEPTED`.

Phase B peut considérer immuables :

1. l'union source et ses quatre variants ;
2. l'outcome qualifié et ses trois producers V0 ;
3. l'ID UUIDv7 immuable dès le draft ;
4. les deux conditions V0 et l'AND ordonné ;
5. les champs exacts draft/definition/record ;
6. publication disabled puis activation ;
7. registry nullable, schema 1, JSON closed-world ;
8. `EventRegistryDecodeResult` et capability read-only/no-runtime ;
9. les trois modes et la truth table ;
10. les claims par cohortes et leurs préimages JCS ;
11. aucune position sur Event/Scene ;
12. exactement une Scene et aucune micro-action Event ;
13. arbitration, lifecycle, progression/outbox et rollback.

Phase B exécute V2-01..04 dans une mission unique. Elle ne touche ni runtime,
ni migration projet réelle, ni UI.

## 22. Risques résiduels

| Risque | Gate propriétaire |
|---|---|
| Fact default/override à résoudre canoniquement | F1/V2-17 avant runtime |
| battleRef public absent pour certains battles | D/V2-10 exclut ces producers |
| Scene-hosted Battle staging exige une vraie refonte | F2/V2-22 tests state parent |
| old writer peut dropper V2 | B/V2-03 preflight + minimum-version warning |
| delivered IDs non bornés V0 | L/V2-41 mesure de croissance |
| corpus Selbrume Scenario malformed signalé | C/V2-05 migration blocker local |
| product docs historiques montrent actions Event-owned | ledger normatif les surclasse ; H contract tests |

Aucun de ces risques ne demande une décision structurelle supplémentaire à
Phase B.

## 23. Décisions explicitement reportées

Ces éléments sont exclus, pas laissés indécis :

| Élément | Décision Phase A | Owner/gate de réouverture |
|---|---|---|
| Story Step condition | exclue V0 | ADR Storyline après identité qualifiée + migration completedStepIds |
| Yarn producer autonome | exclu V0 | nouveau contrat public Yarn hors Scene + ADR-EV2-004 |
| reprise durable mi-Scene | exclue V0 | checkpoint Scene complet + ADR-EV2-013 |
| compaction delivered IDs | aucune compaction V0 | mesure V2-41 puis ADR si nécessaire |
| Event micro-actions | exclues V0 | preuve corpus/usabilité Phase J + nouvel ADR |
| reset durable/calendar lifecycle | hors V0 | lot lifecycle ultérieur avec modèle explicite |

## 24. Evidence Pack

### 24.1 Gate 0 exact

```text
/Users/karim/Project/pokemonProject
main
 M packages/map_editor/pubspec.lock
 packages/map_editor/pubspec.lock | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)
packages/map_editor/pubspec.lock
d26bfa9c NS-EVENT-RESET-00: Canonical Event Sources & Event Builder V2 Ultra Roadmap
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
```

Le drift `packages/map_editor/pubspec.lock` est préexistant, non touché et non
revendiqué.

### 24.2 Fichiers créés

```text
MVP Selbrume/event_builder_v2_architecture_decisions.md
reports/narrativeStudio/events/ns_event_v2_phase_a_architecture_ratification_closure_v0.md
```

Le contenu complet du ledger est reproduit en Annexe A. Le rapport ne se
reproduit pas récursivement dans lui-même ; son contenu présent est l'artefact
complet directement inspectable.

### 24.3 Fichiers modifiés et zones

| Fichier | Zones | Raison / impact |
|---|---|---|
| `MVP Selbrume/road_map_event_builder_v2.md` | statut/execution model, Phase A/B, F1/F2, metadata missions, jalons V2, DAG, synthèse, prochain mission | pilotage phase-based et contrats alignés |
| `reports/.../ns_event_reset_00_event_builder_v2_reference_ui_spec_v0.md` | liste projet, library, concurrence, states, responsive, outcome picker, delete, publication/activation | corriger les contradictions avec ADR-EV2-004/005/011/016/019 |

L'audit RESET-00 n'est pas modifié. Aucun fichier de production, test, fixture,
generated, Selbrume ou package config n'est modifié par le lot.

### 24.4 Image

```text
Commande : shasum -a 256 <north-star>
Résultat : 2072679b3b861a63c068628450705d39e70ad59dc5067e0a0bf91c0bcbe8c885
Commande : sips -g pixelWidth -g pixelHeight <north-star>
Résultat : 1672 x 941
```

### 24.5 Tests, analyse et build

Aucun test Dart/Flutter n'a été créé, modifié ou lancé : la mission interdit le
code et le prompt demande des validations documentaires. Aucun `flutter analyze`,
`dart analyze`, build ou `build_runner` n'a été lancé. Cette exception directe
surclasse la règle générique `codex_rule.md` qui demande tests/build pour les
lots de code.

### 24.6 Validations documentaires finales

```text
Chemins obligatoires : PATHS_OK=20, exit 0
ADR_COUNT=20
ACCEPTED_COUNT=20
MILESTONES=43/43 uniques
F_SPLIT=OK
ENTRY_GATE=OK
LEDGER_APPENDIX=IDENTICAL
Markdown fences : OK sur ledger, roadmap et rapport
Recherche placeholders bloquants : aucun résultat
```

Commandes whitespace :

```text
git diff --check
exit 0, output vide

git diff --no-index --check /dev/null "MVP Selbrume/event_builder_v2_architecture_decisions.md"
exit 1 attendu pour fichier différent, output vide : aucun whitespace error

git diff --no-index --check /dev/null "reports/narrativeStudio/events/ns_event_v2_phase_a_architecture_ratification_closure_v0.md"
exit 1 attendu pour fichier différent, output vide : aucun whitespace error
```

Stat tracked final :

```text
MVP Selbrume/road_map_event_builder_v2.md          | 509 +++++++++++++++------
packages/map_editor/pubspec.lock                   |  16 +-
...set_00_event_builder_v2_reference_ui_spec_v0.md |  65 ++-
3 files changed, 420 insertions(+), 170 deletions(-)
```

Les nouveaux documents non suivis ne figurent pas dans `git diff --stat` :

```text
event_builder_v2_architecture_decisions.md : 1302 lignes, 53886 bytes
ns_event_v2_phase_a_architecture_ratification_closure_v0.md : artefact courant non suivi
```

Gate anti-scope :

```text
Commande : git diff --name-only -- packages/map_core packages/map_editor
           packages/map_runtime packages/map_gameplay packages/map_battle
           examples assets selbrume pubspec.yaml
Résultat : packages/map_editor/pubspec.lock
Interprétation : drift préexistant exact du Gate 0 ; aucune modification de ce lot.
```

État Git final :

```text
 M "MVP Selbrume/road_map_event_builder_v2.md"
 M packages/map_editor/pubspec.lock
 M reports/narrativeStudio/events/ns_event_reset_00_event_builder_v2_reference_ui_spec_v0.md
?? "MVP Selbrume/event_builder_v2_architecture_decisions.md"
?? reports/narrativeStudio/events/ns_event_v2_phase_a_architecture_ratification_closure_v0.md
```

## 25. Auto-review

### Ce qui est prouvé

- vingt ADRs complets et acceptés ;
- noms publics et wire format décidés ;
- quatre sources et trois outcome producers fermés ;
- position absente ;
- draft/configured/activation séparés ;
- modes/claims/rollback déterministes ;
- F1/F2 séparées ;
- 43 IDs V2 et RESET-00 conservés ;
- R1 et R2 passent après corrections.

### Faiblesses conscientes

- le ledger est long, car Phase B ne doit plus inventer le JSON ;
- les claims pinning ScenarioAsset complet sont conservateurs et peuvent
  provoquer des remigrations après une édition sans rapport direct ;
- le staging Battle/Scene est une exigence forte et coûteuse ;
- save busy pendant Scene est honnête mais moins confortable ;
- UUIDv7 et RFC 8785 introduiront des dépendances ou utilitaires à justifier en
  Phase B, sans changer le contrat.

### Scope check

Le lot reste documentaire. Il ne crée aucun contrat Dart, runtime, UI, feature
flag, migration, donnée Selbrume ou fichier generated.

## 26. Review contradictoire

### R1 Architecture

R1 a d'abord refusé : wire format incomplet, claims incapables de prouver leur
cohorte, state machine ambiguë, battle/outbox non transactionnels. Quatre boucles
ont ajouté JSON canonique, decode capability, cohort membership, matrices de
validité, ID regex, battle staging, outbox et claim validity levels.

Verdict final R1 :

```text
No remaining BLOCKER or MAJOR findings.
Verdict: PASS
```

### R2 Product / UX

R2 a d'abord refusé : winner statique, suppression silencieuse, Yarn autonome,
source non choisie absente, liste map-owned, modal contradictoire et publication
confondue avec activation. Trois boucles ont corrigé la spec et la roadmap.

Verdict final R2 :

```text
BLOCKER: None.
MAJOR: None.
Final verdict: PASS.
```

## 27. Critique du prompt

### Points solides

- force la ratification avant code ;
- exige MCP, adversarial reviews et Entry Gate ;
- protège Event != Scene et l'absence de position ;
- autorise à contester RESET-00 ;
- impose une gouvernance phase-based plus soutenable.

### Tensions corrigées

1. Le prompt suggérait Story Step si compilable ; le repo montre des IDs nus et
   un contrat Event Builder explicitement non compilable. Il est exclu V0.
2. Il demandait de décider resume après load ; le runtime n'a pas de checkpoint
   Scene. La décision sûre est save/load busy.
3. Il demandait unknown JSON preservation ; les codecs actuels droppent les
   inconnus. La solution est preflight + read-only/no-runtime, pas une promesse
   implicite du generated codec.
4. La règle générique tests/build de `codex_rule.md` est incompatible avec
   l'interdiction de code et le texte explicite de Phase A. Les gates
   documentaires remplacent ces commandes.
5. La north star montre des actions/projections trompeuses. Elle est normative
   pour composition uniquement.

### Recommandation de prompt futur

Le prochain prompt doit être une mission Phase B unique, charger ce ledger
comme immutable, exécuter V2-01..04 avec tests cumulés et s'arrêter au premier
écart de wire format ou d'invariant.

## 28. Verdict Phase A

```text
PHASE A : CLOSED
Gate : ACCEPTED
R1 Architecture : PASS
R2 Product / UX : PASS
Entry Gate Phase B : ACCEPTED
Blockers : aucun
Prochaine mission : PHASE B - Domain Contracts (V2-01 à V2-04)
```

## Annexe A - Contenu complet du ledger créé

````markdown
# Event Builder V2 - Architecture Decision Ledger

## Statut et autorite

```text
Lot de ratification : NS-EVENT-V2 - PHASE A
Date de ratification : 2026-07-10
Statut du ledger : ACCEPTED
Architecture : Event projet + source typee + ancres possedees par les maps
```

Ce ledger est normatif pour les Phases B a L. L'audit RESET-00 reste une preuve
historique ; en cas d'ecart, la decision `ADR-EV2-*` la plus recente gagne. Une
phase ne peut changer un invariant ci-dessous sans s'arreter, produire un
Blocker Report et faire accepter un nouvel ADR.

## Contrats publics ratifies

| Contrat | Forme V0 normative |
|---|---|
| `NarrativeEventSourceRef` | union `entityInteract`, `triggerEnter`, `mapEnter`, `outcomeReceived` |
| `NarrativeOutcomeRef` | `producerKind`, `producerId`, `outcomeId` |
| `NarrativeOutcomeProducerKind` | `scene`, `battle`, `legacyScenario` |
| `NarrativeEventCondition` | `fact`, `narrativeEventConsumed` |
| `NarrativeEventReusePolicy` | `oneShot`, `reusable` |
| `NarrativeEventDefinition` | Event configure sans statut runtime |
| `NarrativeEventDraft` | Event incomplet, jamais indexable |
| `NarrativeEventRecord` | union `draft` / `configured` ; `enabled` sur le variant configure |
| `NarrativeEventRegistry` | `schemaVersion`, `mode`, `records`, `legacyClaims` |
| `EventSystemMode` | `legacyOnly`, `dualRead`, `v2Only` |
| `LegacySourceRef` | union `mapEvent`, `scenarioSourceNode` |
| `LegacySourceClaimMember` | provenance legacy + empreinte du membre |
| `LegacySourceClaim` | cohorte complète, source V2, cibles, receipt |
| `NarrativeEventProgress` | consommation V2 et outbox d'outcomes qualifiees |
| `EventRegistryDecodeResult` | `absent`, `decoded`, `unsupported`, `invalid` |

## JSON canonique V0

### Règles communes

- Les discriminants sont des strings case-sensitive ; l'index d'un enum n'est
  jamais écrit.
- Tout champ indiqué ci-dessous est requis, sauf les trois champs optionnels du
  draft. Un champ requis absent ou `null` est une donnée V0 invalide.
- `source`, `sceneId` et `reusePolicy` d'un draft sont omis quand ils sont
  absents. Un `null` explicite à ces trois emplacements est accepté au decode et
  normalisé vers l'absence ; l'encodeur les omet toujours.
- Les collections sont requises et peuvent être vides. `conditions` ne vaut
  jamais `null`.
- Un champ inconnu ou discriminant inconnu est `unsupported`, car il peut venir
  d'un writer futur. Un champ V0 connu manquant, de mauvais type, vide ou hors
  invariant est `invalid`.
- Les identités sont opaques, case-sensitive, non vides et doivent déjà être
  égales à leur version `trim()`. Le decode rejette les espaces de bord ; il ne
  réécrit jamais une identité.

### Sources, outcomes et conditions

```json
{"kind":"entityInteract","mapId":"map_port","entityId":"npc_lysa"}
{"kind":"triggerEnter","mapId":"map_port","triggerId":"zone_entry"}
{"kind":"mapEnter","mapId":"map_port"}
{"kind":"outcomeReceived","outcome":{"producerKind":"scene","producerId":"scene_lysa","outcomeId":"victory"}}

{"kind":"fact","factId":"rival_defeated","expectedValue":true}
{"kind":"narrativeEventConsumed","eventId":"evt_019abcde-0000-7000-8000-000000000001","expectedValue":false}
```

Le JSON de `NarrativeOutcomeRef` contient exactement `producerKind`,
`producerId`, `outcomeId`. `NarrativeOutcomeProducerKind` accepte seulement
`scene`, `battle`, `legacyScenario`. `NarrativeEventCondition` utilise le même
discriminant `kind` avec les deux payloads exacts ci-dessus.

### Records

```json
{
  "state": "draft",
  "draft": {
    "id": "evt_019abcde-0000-7000-8000-000000000001",
    "name": "Rencontre Lysa",
    "conditions": [],
    "priority": 0,
    "order": 0
  }
}
```

```json
{
  "state": "configured",
  "definition": {
    "id": "evt_019abcde-0000-7000-8000-000000000001",
    "name": "Rencontre Lysa",
    "source": {"kind":"entityInteract","mapId":"map_port","entityId":"npc_lysa"},
    "conditions": [],
    "sceneId": "scene_lysa",
    "reusePolicy": "oneShot",
    "priority": 0,
    "order": 0
  },
  "enabled": false
}
```

Un record contient soit `draft`, soit `definition + enabled`, jamais les deux.
`NarrativeEventReusePolicy` est encodé par `oneShot` ou `reusable`.

### Claims et registry

```json
{
  "cohortId": "lsc_cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
  "source": {"kind":"entityInteract","mapId":"map_port","entityId":"npc_lysa"},
  "members": [
    {
      "provenance": {"kind":"mapEvent","mapId":"map_port","eventId":"lysa"},
      "sourceFingerprint": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    }
  ],
  "cohortFingerprint": "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
  "targetEventIds": ["evt_019abcde-0000-7000-8000-000000000001"],
  "migrationReceiptId": "evmr_019abcde-0000-7000-8000-000000000002"
}
```

`LegacySourceRef` encode exactement :

```json
{"kind":"mapEvent","mapId":"map_port","eventId":"lysa"}
{"kind":"scenarioSourceNode","scenarioId":"scenario_lysa","nodeId":"source"}
```

Le registry encode exactement :

```json
{
  "schemaVersion": 1,
  "mode": "legacyOnly",
  "records": [],
  "legacyClaims": []
}
```

### Décodage et capacité de sauvegarde

`decodeNarrativeEventRegistry(rawProjectJson)` retourne :

```text
EventRegistryDecodeResult.absent()
EventRegistryDecodeResult.decoded(registry)
EventRegistryDecodeResult.unsupported(rawEventRegistryJson, diagnostics)
EventRegistryDecodeResult.invalid(rawEventRegistryJson, diagnostics)
```

`absent` et `decoded` autorisent une session writable. `unsupported` et
`invalid` conservent le sous-arbre brut et n'autorisent qu'une session projet
read-only si le reste du manifest peut être décodé après isolement du registry ;
sinon l'ouverture échoue avec diagnostics. Dans ces deux états, save, migration,
export réécrit, auto-fix, playtest et runtime sont interdits. Ils ne deviennent
jamais `absent` ou `legacyOnly`. Le repository conserve les bytes UTF-8 originaux
jusqu'à fermeture ; `ProjectManifest.fromJson` ne peut pas être le seul
entrypoint de fichier V2. Seul un résultat `decoded` possède un `toJson`.

## Table de validité des records

| État | Validité structurelle | Validité contextuelle | Index runtime |
|---|---|---|---|
| draft | ID/name valides, `order >= 0`, options absentes ou structurelles, conditions structurelles | références présentes vérifiées comme diagnostics, sans obligation d'exister | jamais |
| configured disabled | définition complète et structurelle | chaque ID doit résoudre exactement un owner pour publication ; une casse externe reste chargeable mais invalide | jamais |
| configured enabled | définition complète et structurelle | source, Scene, Fact/Event refs résolvent exactement une cible ; conflit enabled `(source,priority,order)` = erreur d'authoring/mode avec ordre runtime défensif | indexé si ses références sont valides, y compris en conflit importé |

La publication exige la validité contextuelle du draft et produit
`configured(enabled=false)`. Elle n'est pas bloquée par un conflit avec un autre
record, car le nouveau record est désactivé. L'activation effectue le gate de
conflit. Un fichier externe contenant deux records enabled en conflit reste
chargeable : les deux records aux références valides restent dans l'index et le
runtime applique le tie-break `eventId`. Le validator bloque toute nouvelle
activation et toute transition de mode jusqu'à réparation.

---

## ADR-EV2-001 - Architecture canonique hybride

**Statut : Accepted**

**Contexte.** Le repository contient un Event map-local positionne, des sources
Scenario source-first et deux chemins runtime concurrents. Aucun des deux ne
porte seul le modele produit cible.

**Decision.** L'Event V2 est un asset project-level. Il reference exactement
une source typee. `MapEntity`, `MapTrigger` et `MapData` restent proprietaires
des ancres spatiales. `MapEventDefinition` et les nodes source Scenario sont des
entrees legacy temporaires, jamais le stockage d'authoring V2 normal.

**Invariants.** Une ecriture V2 cible uniquement le registry projet. Une source
reelle existe independamment de l'Event. L'autorite V1/V2 passe par un seul
coordinateur et par `EventSystemMode`.

**Consequences positives.** Les Events deviennent project-level, les outcomes
non spatiales deviennent naturelles et la position n'est plus dupliquee.

**Couts / consequences negatives.** Un nouveau contrat, des adapters et une
migration assistee sont necessaires avant le remplacement de V1.

**Alternatives rejetees.** Etendre `MapEventDefinition`, faire posseder l'Event
par la map, promouvoir Scenario en Event, ou stocker une position optionnelle.

**Criteres de reouverture.** Preuve qu'une source V0 ne peut pas etre exprimee
par une reference stable sans remettre de geometrie dans l'Event.

**Phases impactees.** B a L.

**Date / phase de ratification.** 2026-07-10 - Phase A.

---

## ADR-EV2-002 - Event configure canonique

**Statut : Accepted**

**Contexte.** Le contrat configure doit etre assez strict pour l'index runtime
et assez fin pour ne pas devenir un second moteur de Scene.

**Decision.** `NarrativeEventDefinition` contient exactement :

```text
id: String
name: String
source: NarrativeEventSourceRef
conditions: List<NarrativeEventCondition>
sceneId: String
reusePolicy: NarrativeEventReusePolicy
priority: int
order: int
```

`id`, `name` et `sceneId` sont non vides apres trim. `order` est positif ou nul.
`priority` est un entier signe. Le statut d'activation n'appartient pas a la
definition : il appartient au variant configure du record.

**Invariants.** Exactement une source, exactement une Scene, aucune position,
aucune action directe, aucun outcome, aucune branche, aucune consequence, aucun
label copie depuis une source et aucune metadata fourre-tout.

**Consequences positives.** Le modele configure est valide par construction et
les projections Scene restent hors du contrat Event.

**Couts / consequences negatives.** Les extensions futures exigent un schema
versionne et une nouvelle decision, pas une map de champs opaques.

**Alternatives rejetees.** `enabled` dans la definition, status enum dans la
definition, action union, position, payload polymorphe universel.

**Criteres de reouverture.** Besoin produit prouve qui ne peut etre porte ni par
la source, ni par la Scene, ni par le record d'activation.

**Phases impactees.** B, E, F1, H, I, J.

**Date / phase de ratification.** 2026-07-10 - Phase A.

---

## ADR-EV2-003 - Union de sources V0

**Statut : Accepted**

**Contexte.** Les champs universels optionnels et les cles concatenees du
pipeline Scenario permettent des combinaisons invalides et des outcomes non
qualifiees.

**Decision.** `NarrativeEventSourceRef` est une union fermee avec ces factories :

```text
entityInteract(mapId: String, entityId: String)
triggerEnter(mapId: String, triggerId: String)
mapEnter(mapId: String)
outcomeReceived(outcome: NarrativeOutcomeRef)
```

`NarrativeEventSourceKind` expose les quatre noms equivalents. Le JSON utilise
un discriminant textuel `kind`; l'ordre de l'enum n'est jamais serialise.

**Invariants.** Tous les IDs sont non vides. La reference ne stocke ni label,
ni position, ni taille, ni layer, ni raw tile. L'objet union lui-meme est la cle
structurelle ; aucune identite n'est reconstruite en decoupant une chaine.

**Consequences positives.** Les combinaisons invalides deviennent
inrepresentables et les index peuvent utiliser une egalite structurelle.

**Couts / consequences negatives.** Les catalogs et adapters doivent construire
le bon variant au lieu de remplir un sac de champs.

**Alternatives rejetees.** Champs `mapId/entityId/triggerId/outcomeId` tous
optionnels, ID technique concatene, source raw tile, source par position.

**Criteres de reouverture.** Nouvelle famille d'occurrence possedant une
identite stable, un owner clair et un runtime prouve.

**Phases impactees.** B a J.

**Date / phase de ratification.** 2026-07-10 - Phase A.

---

## ADR-EV2-004 - Provenance qualifiee des outcomes

**Statut : Accepted**

**Contexte.** `outcomeId` est local a son producteur. Scene, battle et Scenario
legacy peuvent employer le meme ID sans designer le meme fait.

**Decision.** `NarrativeOutcomeRef` contient trois champs non vides et
case-sensitive :

```text
producerKind: NarrativeOutcomeProducerKind
producerId: String
outcomeId: String
```

V0 ratifie `scene`, `battle` et `legacyScenario` :

- `scene` : `producerId = SceneAsset.id`, `outcomeId = SceneOutcome.id` ;
- `battle` : `producerId = BattlePublicContract.battleRefId` ; seuls les
  producteurs presents dans le contrat public Battle sont indexables ;
- `legacyScenario` : `producerId = ScenarioAsset.id`, ID outcome legacy brut.

Yarn n'est pas un producteur autonome V0. Un outcome de dialogue devient
observable par Event V2 uniquement quand la Scene qui orchestre Yarn le
re-emet comme outcome Scene. Un dialogue execute hors Scene reste legacy.

Une Battle autonome émet son outcome `battle` après commit de son write-back
dans le `GameState` autoritatif. Une Battle hébergée dans une Scene applique son
write-back à un `GameState` de travail détenu par l'exécution Scene ; ce state
n'est pas installé comme autoritatif avant le commit final parent. Le résultat
fournit son port de sortie à la Scene et mémorise une envelope provisoire.

Au succès final de la Scene, les write-backs Battle, conséquences Scene et
consommation Event sont installés ensemble. Les envelopes Battle hébergées sont
alors placées dans l'outbox dans leur ordre d'occurrence, puis l'outcome final
`scene` est ajouté en dernier. Les deux peuvent donc être observés. Si la Scene
échoue ou est annulée, son state de travail et ses outcomes Battle provisoires
sont abandonnés ; l'Event non consommé peut repartir sans dupliquer un write-back
déjà autoritatif. Les Events enfants démarrent seulement après le commit parent
et la libération de son lock d'exécution.

**Invariants.** Une reference identifie un type d'outcome, pas une occurrence.
Un request ID runtime, un label ou une normalisation `flee/fled` ne peut jamais
servir de `producerId`.

**Consequences positives.** Aucune collision cross-producteur ; la frontiere
Scene/Yarn reste explicite.

**Couts / consequences negatives.** Les battles sans `battleRefId` public stable
sont exclues du catalog jusqu'a disposer d'un contrat stable.

**Alternatives rejetees.** Outcome global nu, `yarn` V0, ID de requete runtime,
normalisation silencieuse des vocabulaires legacy.

**Criteres de reouverture.** Yarn expose un contrat public autonome, stable,
persistant et consommable hors Scene ; ou Battle change de reference publique.

**Phases impactees.** B, C, D, F2, H, I, J.

**Date / phase de ratification.** 2026-07-10 - Phase A.

---

## ADR-EV2-005 - Draft, configured, publication et activation

**Statut : Accepted**

**Contexte.** Un draft incomplet doit etre sauvegardable sans devenir un objet
runtime partiellement valide.

**Decision.** `NarrativeEventRecord` est une union avec discriminant JSON
`state` :

```text
draft(draft: NarrativeEventDraft)
configured(definition: NarrativeEventDefinition, enabled: bool)
```

`NarrativeEventDraft` contient :

```text
id: String
name: String
source: NarrativeEventSourceRef?
conditions: List<NarrativeEventCondition>
sceneId: String?
reusePolicy: NarrativeEventReusePolicy?
priority: int
order: int
```

La publication est une operation atomique qui preserve `id` et `order`, valide
toutes les references et produit un record configure avec `enabled = false`.
L'activation est une commande explicite separee. Seuls les records
`configured && enabled` entrent dans l'index runtime.

**Invariants.** Un draft n'est jamais indexe. `enabled` n'existe que sur le
variant configure. Une publication invalide n'ecrit rien.

**Consequences positives.** Les brouillons restent recuperables ; activation et
validite ne sont plus confondues.

**Couts / consequences negatives.** Le workflow comporte une etape explicite
d'activation et doit expliquer pourquoi un Event configure peut etre inactif.

**Alternatives rejetees.** Une classe a nombreux champs nullables toujours
runtime, publication active par defaut, statut stocke dans la definition.

**Criteres de reouverture.** Preuve UX que publication et activation separees
creent une erreur recurrente sans alternative gardant le fail-closed.

**Phases impactees.** B, E, F1, H, I.

**Date / phase de ratification.** 2026-07-10 - Phase A.

---

## ADR-EV2-006 - Registry, JSON et compatibilite

**Statut : Accepted**

**Contexte.** `ProjectManifest` n'a pas de registry Event et ses codecs generes
peuvent supprimer des champs inconnus lors d'une reecriture.

**Decision.** `ProjectManifest.eventRegistry` est un
`NarrativeEventRegistry?`. Le registry V0 contient, dans cet ordre JSON :

```text
schemaVersion: int              // V0 = 1
mode: EventSystemMode
records: List<NarrativeEventRecord>
legacyClaims: List<LegacySourceClaim>
```

Champ absent ou `null` signifie `legacyOnly` effectif et est omis a
l'encodage. Un registry present exige les quatre champs. Sa version est
independante de `ProjectVersion`. L'ordre des deux listes est preserve
exactement ; le runtime trie une copie et ne reecrit pas l'ordre d'authoring.

Le sous-arbre Event V2 est closed-world. Tout champ inconnu, discriminant
inconnu ou `schemaVersion` non supporte place le projet en lecture seule. Un
preflight codec conserve les bytes JSON originaux et interdit toute sauvegarde
qui les perdrait ; il ne transforme jamais un champ inconnu en champ connu.

**Invariants.** Aucun older-writer ne reecrit un projet V2 sans preuve de
support. Les cles connues ont un ordre stable. Aucune version Event ne modifie
l'enum de version partage avec les maps.

**Consequences positives.** Les projets V1 restent byte-inertes et les donnees
futures ne sont pas silencieusement detruites.

**Couts / consequences negatives.** Phase B doit fournir un codec/preflight
dedie au lieu de deleguer entierement au generated JSON.

**Alternatives rejetees.** Registry non nullable cree implicitement, bump de
`ProjectVersion`, drop des inconnus, map `extensions` qui deplace les inconnus.

**Criteres de reouverture.** Adoption d'un codec global qui prouve une
preservation equivalente des sous-arbres inconnus.

**Phases impactees.** B, C, E, F1, I, L.

**Date / phase de ratification.** 2026-07-10 - Phase A.

---

## ADR-EV2-007 - Modes et autorite unique

**Statut : Accepted**

**Contexte.** Les hooks Scenario et MapEvent peuvent aujourd'hui traiter la
meme intention sans arbitre persistant.

**Decision.** `EventSystemMode` possede exactement :

| Mode | Semantique runtime |
|---|---|
| `legacyOnly` | V2 et claims sont conserves mais non evalues ; le legacy traite une fois. |
| `dualRead` | Le coordinateur evalue V2 ; un claim bloque tout fallback ; sans claim, `noMatch` peut aller au legacy. |
| `v2Only` | Seul V2 traite ; `noMatch` ne produit aucun fallback legacy. |

Le planner retourne exactement `handled`, `claimedButIneligible` ou `noMatch`.
Un `handled` suivi d'un echec de Scene ne choisit ni autre Event ni legacy.
Un claim décodé mais contextuellement/corpus-invalide, ou dont tous les
candidats sont disabled, consumed, condition-false ou in-flight, retourne
`claimedButIneligible` pour sa source. Un registry non décodable n'atteint
jamais le planner.

En `dualRead`, un claim valide fait évaluer tous les records V2
`configured && enabled` portant exactement `claim.source`, pas seulement ses
`targetEventIds`. Un Event V2 créé plus tard sur cette source peut donc produire
`handled`. `targetEventIds` prouve la migration, mais ne définit ni le candidate
set ni son ordre. Si au moins un record de la source est éligible, le tri
ADR-EV2-011 choisit le candidat du snapshot ; si aucun ne l'est, le résultat est
`claimedButIneligible`. Un claim structurellement invalide ne planifie aucun
record, même non cible, et reste fail-closed.

Transitions normales : `legacyOnly -> dualRead -> v2Only`. Un projet neuf sans
source legacy peut passer directement de `legacyOnly` a `v2Only`. Un retour de
`v2Only` exige une migration inverse ; un simple toggle est interdit. Aucun
feature flag independant ne peut contredire le mode persiste.

**Invariants.** Une occurrence entre une seule fois dans le coordinateur. Un
claim present bloque le fallback meme sans candidat executable.

**Consequences positives.** Autorite observable, testable et persistante ; pas
de double dispatch.

**Couts / consequences negatives.** Tous les hooks legacy doivent deleguer leur
decision au coordinateur pendant la transition.

**Alternatives rejetees.** Deux dispatchers concurrents, feature flag externe,
fallback apres echec V2, fallback d'un claim consomme.

**Criteres de reouverture.** Preuve formelle qu'un quatrieme etat est requis et
qu'il ne peut etre represente par mode + claims + resultat du planner.

**Phases impactees.** B, C, F1, F2, J, L.

**Date / phase de ratification.** 2026-07-10 - Phase A.

---

## ADR-EV2-008 - Claims legacy et cohortes

**Statut : Accepted**

**Contexte.** Un claim partiel peut supprimer une partie d'un comportement ou
laisser un second handler legacy executer la meme occurrence.

**Decision.** `LegacySourceRef` est une union :

```text
mapEvent(mapId: String, eventId: String)
scenarioSourceNode(scenarioId: String, nodeId: String)
```

`LegacySourceClaimMember` contient `provenance: LegacySourceRef` et
`sourceFingerprint: String`. `LegacySourceClaim` contient :

```text
cohortId: String
source: NarrativeEventSourceRef
members: List<LegacySourceClaimMember>  // 1..N
cohortFingerprint: String
targetEventIds: List<String>       // 1..N, uniques, ordre canonique
migrationReceiptId: String
```

Un membre MapEvent porte tout `(mapId,eventId)`, jamais une page. Le receipt
detaille chaque page. Un membre Scenario porte `(scenarioId,nodeId)`. `members`
contient tous les handlers legacy capables de traiter la meme occurrence
normalisee vers `source`.

`cohortId` vaut `lsc_<sha256 hex>` calcule sur le JSON canonique de `source` et
la liste des provenances triee par `kind`, puis IDs en comparaison binaire.
Chaque empreinte vaut `sha256:<64 hex minuscules>`. `cohortFingerprint` couvre
`source`, les provenances et leurs empreintes. Les `targetEventIds` sont tries
lexicalement. Le receipt porte exactement le meme `cohortId`, les memes
membres, les mappings de pages et les hashes avant/apres.

Pour ces hashes, `JSON canonique` signifie RFC 8785 JCS encodé en UTF-8. Aucun
ordre de map Dart, pretty-printer ou choix d'échappement local n'entre dans
l'empreinte. Les préimages sont exactement :

```text
sourceFingerprint MapEvent = JCS({
  "kind": "mapEvent",
  "mapId": mapId,
  "event": MapEventDefinition.toJson() complet
})

sourceFingerprint Scenario = JCS({
  "kind": "scenarioSourceNode",
  "scenarioId": scenarioId,
  "nodeId": nodeId,
  "scenario": ScenarioAsset.toJson() complet
})

cohortId digest = SHA-256(JCS({
  "source": NarrativeEventSourceRef.toJson(),
  "provenances": LegacySourceRef.toJson() triées
}))

cohortFingerprint digest = SHA-256(JCS({
  "cohortId": cohortId,
  "members": [{"provenance": ..., "sourceFingerprint": ...}] triés
}))
```

Le fingerprint Scenario verrouille volontairement tout le `ScenarioAsset`
contenant le node claimé ; Phase C ne tente pas de deviner un sous-graphe
atteignable. Le fingerprint MapEvent verrouille toute la définition, toutes ses
pages et sa position legacy, mais pas les autres contenus de la map.

### Matrice de validité des claims

| Cas | Résultat decode/validation | Capacité runtime |
|---|---|---|
| clé requise absente/null, mauvais type, ID/hash mal formé, members/targets vides ou doublons internes | `EventRegistryDecodeResult.invalid` | aucun runtime/playtest, tous modes |
| champ/discriminant/schema inconnu | `EventRegistryDecodeResult.unsupported` | aucun runtime/playtest, tous modes |
| cohortId/source/provenance partagé entre plusieurs claims | registry décodé, `ValidatedLegacyClaimIndex.globalConflict` | `dualRead` ne démarre pas ; claims inertes en `legacyOnly`/`v2Only` |
| target absent, draft ou de source différente | registry décodé, claim contextuellement invalide pour sa source | `claimedButIneligible` sur cette source, aucun fallback ; autres sources continuent |
| membre/source orphelin, fingerprint stale, cohorte corpus partielle | registry décodé, claim corpus-invalide pour sa source | `claimedButIneligible` sur cette source, aucun fallback ; autres sources continuent |
| target disabled/consumed/condition-false/in-flight, claim autrement valide | claim valide, candidat inéligible | autre Event de même source peut gagner ; sinon `claimedButIneligible` |

`ValidatedLegacyClaimIndex` contient `canStartDualRead`, `validBySource` et
`invalidBySource`. Phase B valide forme, ordre, IDs, doublons et invariants entre
claims/records. Phase C ajoute les membres réellement découverts et les
empreintes corpus. V2-17 reçoit uniquement cet index validé, jamais la liste raw.
Une transition vers `dualRead` ou `v2Only` exige zéro issue claim ; un projet
déjà `v2Only` ignore les claims devenus orphelins mais les conserve pour audit.

**Invariants.** Un seul claim par `cohortId` et par `source`; une provenance ne
peut appartenir qu'a un claim. Chaque target existe comme record configured et
porte exactement la meme `source`; disabled/consumed peut ensuite rendre le
claim ineligible sans fallback. Claim décodé mais stale, partiel, orphelin ou
cible invalide : tombstone fail-closed pour sa source. Collision de cohorte,
source ou membre entre claims : démarrage `dualRead` bloqué globalement. Claim
non décodable : tout runtime/playtest bloqué. La liste cible ne définit jamais
la priorité.

Le registry construit deux index vers le même claim : `source -> cohortId` et
`member.provenance -> cohortId`. Une occurrence canonique consulte le premier ;
un adapter legacy fournit sa provenance et consulte le second. Les deux doivent
résoudre le même claim, sinon le registry est invalide et `dualRead` ne démarre
pas.

**Consequences positives.** La migration ne peut pas masquer un double handler
ni faire revivre un legacy consomme.

**Couts / consequences negatives.** Phase B valide forme, ordre, unicite et
calcul de `cohortId`. Phase C confronte membres/empreintes au corpus reel et
interdit l'activation d'une cohorte partielle.

**Alternatives rejetees.** Claim par page, bare `nodeId`, claim par nom,
premiere cible seulement, claim invalide traite comme absent.

**Criteres de reouverture.** Preuve qu'une nouvelle provenance legacy ne peut
etre qualifiee par une union fermee et integree a une cohorte.

**Phases impactees.** B, C, F1, F2, I, L.

**Date / phase de ratification.** 2026-07-10 - Phase A.

---

## ADR-EV2-009 - Identite globale et immuable

**Statut : Accepted**

**Contexte.** Les IDs MapEvent sont seulement uniques dans une map et peuvent
etre renommes. Ils ne conviennent pas aux references projet ou aux saves.

**Decision.** Un ID Event V2 est genere a la creation du draft sous la forme
`evt_<uuid-v7 canonique minuscule avec tirets>`. L'interface publique de
generation est `NarrativeEventIdGenerator.generate()`. L'ID est opaque,
case-sensitive et immuable des la creation du record. Aucun tri metier ne
depend de l'ordre temporel UUIDv7.

Le validateur exact est :

```text
^evt_[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$
```

Le generateur teste l'unicite contre tous les records du registry. Une
collision genere un nouvel UUID, jusqu'a 16 tentatives ; la 17e collision
retourne une erreur sans ecriture. Les IDs de map/source/Scene/Fact/outcome sont
des strings opaques non vides et sans espaces de bord. Un decode/import rejette
une identité différente de `value.trim()` au lieu de la normaliser. Seul `name`
est trimme comme texte auteur et doit rester non vide.

Renommer `name` ne change pas l'ID. Dupliquer cree un nouvel ID. Un import
preserve un ID valide sans collision ; en cas de collision, il annule ou
re-cle toute la fermeture importee avec une table old-to-new et reecrit toutes
ses references avant insertion. Une migration legacy genere toujours un ID V2
frais et conserve la provenance dans le claim/receipt.

**Invariants.** Unicite sur tout le projet et immutabilite des le draft. Une
insertion registry dupliquee echoue atomiquement. Aucun merge silencieux. Aucune
generation a partir du titre, de la map ou de la position.

**Consequences positives.** References et progression restent stables apres
renommage/deplacement ; les imports sont explicites.

**Couts / consequences negatives.** Un generateur UUIDv7 injectable et des
fixtures deterministes sont requis.

**Alternatives rejetees.** Slug titre, compteur map-local, position, UUID de
requete runtime, preservation automatique d'un ID legacy.

**Criteres de reouverture.** Collision prouvee du format ou contrainte
d'interoperabilite imposant un autre espace global stable.

**Phases impactees.** B, C, E, F1, I.

**Date / phase de ratification.** 2026-07-10 - Phase A.

---

## ADR-EV2-010 - Ownership spatial et MapEvents autonomes

**Statut : Accepted**

**Contexte.** V1 stocke une `EventPosition` alors que les entites et triggers
possedent deja leur geometrie.

**Decision.** `MapEntity` possede `pos/size`, `MapTrigger` possede `area`,
`MapData` possede l'identite map, `mapEnter` n'a pas de point et
`outcomeReceived` est non spatial. Event et Scene ne stockent aucune position,
geometrie, layer ou coordonnee cachee.

`Voir sur la carte` resout la source courante, ouvre la map, selectionne et
centre l'entite ou le trigger, avec retour au Narrative Studio. Un deplacement,
redimensionnement ou renommage qui garde les IDs conserve le lien.

Un `MapEventDefinition` autonome reste legacy ou est transforme par une action
explicite V2-25 qui materialise/selectionne une vraie source. Aucune source
n'est inferee par nom ou coordonnee.

**Invariants.** Changer `mapId`, l'ID de source ou son kind eligible est un
changement d'identite soumis aux dependances.

**Consequences positives.** Une seule verite spatiale et une navigation
source-first.

**Couts / consequences negatives.** Certains MapEvents ne sont pas migrables
sans decision utilisateur ou creation d'une source explicite.

**Alternatives rejetees.** Position Event, cache de position, mini-map comme
source, rapprochement par coordonnee.

**Criteres de reouverture.** Source spatiale prouvee sans owner map existant et
impossible a materialiser proprement.

**Phases impactees.** C, D, E, G, H, I, J.

**Date / phase de ratification.** 2026-07-10 - Phase A.

---

## ADR-EV2-011 - Plusieurs Events sur une source

**Statut : Accepted**

**Contexte.** Plusieurs intentions conditionnelles peuvent partager une source,
mais une occurrence ne doit pas lancer plusieurs Scenes ni dependre de l'ordre
d'un manifest.

**Decision.** Une source peut etre referencee par `0..N` Events. Le planner
evalue tous les records `configured && enabled` contre un meme snapshot
immuable, puis choisit un seul candidat par :

```text
priority decroissante
order croissant
eventId croissant, comparaison binaire et locale-independante
```

Le prochain candidat est considere lorsque les conditions d'un candidat plus
prioritaire sont fausses. Une fois un candidat selectionne, son echec
d'execution ne promeut pas le suivant.

`priority` est visible via les presets `Prioritaire = 100`, `Normale = 0` et
`Secondaire = -100`. `order` est source-local, positif ou nul, stable et gere
par Monter/Descendre ; sa valeur brute reste interne. Un nouveau candidat est
ajoute en fin de son groupe de priorite.

**Invariants.** Deux Events actifs de meme source avec meme `(priority,order)`
bloquent l'activation du second ; la publication disabled reste permise. Le
tie-break `eventId` protege seulement le runtime contre une donnee importee ou
corrompue. L'UI annonce `premier candidat
evalue`, jamais un résultat inconditionnel sans snapshot.

**Consequences positives.** Resolution deterministe, authorable sans drag et
compatible avec les conditions alternatives.

**Couts / consequences negatives.** L'authoring doit montrer les concurrents,
leur ordre et les conflits avant activation.

**Alternatives rejetees.** Fan-out V0, premier record du JSON, eventId comme
ordre normal, promotion apres echec, drag-only.

**Criteres de reouverture.** Cas produit exigeant plusieurs executions pour une
occurrence avec semantics transactionnelles et UX explicites.

**Phases impactees.** B, E, F1, H, I, J.

**Date / phase de ratification.** 2026-07-10 - Phase A.

---

## ADR-EV2-012 - Sous-ensemble de conditions V0

**Statut : Accepted**

**Contexte.** `ScriptCondition` est trop large et lie `eventIsConsumed` au
namespace legacy. Les Story Steps sont stockees comme IDs nus et ne sont pas
garanties uniques entre storylines ; le contrat Event Builder actuel reconnait
qu'il ne sait pas les compiler honnetement.

**Decision.** `NarrativeEventCondition` est une union V0 fermee :

```text
fact(factId: String, expectedValue: bool)
narrativeEventConsumed(eventId: String, expectedValue: bool)
```

La liste est un AND ordonne, evalue en court-circuit ; une liste vide vaut
`true`. L'ordre d'authoring est preserve. Les deux references sont non vides et
doivent exister. `narrativeEventConsumed` lit uniquement
`consumedNarrativeEventIds`.

Story Step, OR, NOT generique, arbre imbrique, flag brut, variable et condition
legacy sont exclus du V0. Story Step ne peut revenir qu'apres introduction d'une
reference qualifiee de step et migration du `completedStepIds` nu ; ce travail
appartient a une decision Storyline dediee, pas a Phase B.

**Invariants.** Aucun `ScriptCondition` arbitraire n'est serialise dans un Event
V2. Le resolver Fact utilise la semantique canonique de `NarrativeFactDefinition`
et doit prouver les valeurs par defaut avant l'activation runtime F1.

**Consequences positives.** Conditions simples, no-code et evaluables sans
collision avec la progression legacy.

**Couts / consequences negatives.** Les conditions Story Step visibles dans V1
restent legacy/read-only jusqu'a leur qualification.

**Alternatives rejetees.** Reutiliser `ScriptCondition`, encoder Story Step en
flag, garder `eventIsConsumed` sur le set legacy, accepter OR V0.

**Criteres de reouverture.** Reference Story Step globalement qualifiee,
migration save prouvee et evaluator canonique teste.

**Phases impactees.** B, C, E, F1, H, I.

**Date / phase de ratification.** 2026-07-10 - Phase A.

---

## ADR-EV2-013 - Lifecycle, succes et suspension

**Statut : Accepted**

**Contexte.** Le runtime Scene suspend actuellement ses dialogues/battles avec
des completers memoire et ne possede pas de checkpoint serialisable fiable.

**Decision.** `NarrativeEventReusePolicy` contient `oneShot` et `reusable` :

- `oneShot` est consomme uniquement apres End de Scene, fin de tous les awaits
  et commit reussi de toutes les consequences ;
- `reusable` n'est jamais consomme automatiquement ;
- plan invalide, refus de callback, annulation, echec de consequence ou echec
  de Scene ne consomme pas et n'emet pas d'outcome ;
- une execution active tient un lock en memoire et rend le meme Event
  ineligible jusqu'a sa fin ;
- une Scene suspendue reste active mais la sauvegarde et le chargement sont
  refuses avec un statut busy explicite.

V0 ne promet pas de reprise a mi-Scene apres load. Apres crash, l'Event non
consomme peut etre relance depuis sa source et recommence au debut. Une reprise
durable exige un nouvel ADR et un checkpoint Scene serialisable prouve.

Le commit final regroupe consequences Scene, consommation one-shot et insertion
des envelopes d'outcome dans l'outbox. Les outcomes sont dispatches apres ce
commit. Une erreur d'infrastructure avant planning laisse l'envelope pending.
Un consommateur déjà sélectionné qui échoue rend la delivery terminale
`delivered` avec diagnostic et sans retry automatique ; il n'annule pas le
succès du producteur.

`SceneConsequence.markEventConsumed` continue d'ecrire seulement
`consumedEventIds` legacy. Consommer arbitrairement un autre Event V2 est exclu
du V0.

**Invariants.** Aucun fallback ou candidat suivant apres selection. Aucune
consommation avant succes complet. Aucun save pendant une execution non
checkpointable.

**Consequences positives.** Semantique compatible avec le runtime actuel et pas
de fausse garantie de reprise.

**Couts / consequences negatives.** Le joueur ne peut pas sauvegarder pendant
une Scene Event active ; les Scenes longues devront fournir un feedback clair.

**Alternatives rejetees.** Consommer au demarrage, resume memoire apres load,
redemarrer le legacy apres echec V2, commande V2 de consommation arbitraire.

**Criteres de reouverture.** Checkpoint Scene versionne couvrant dialogue,
battle, cinematic, consequences et save round-trip sans double effet.

**Phases impactees.** F1, F2, I, J, L.

**Date / phase de ratification.** 2026-07-10 - Phase A.

---

## ADR-EV2-014 - Progression et outbox V2

**Statut : Accepted**

**Contexte.** `GameState.consumedEventIds` est legacy et collisionne des IDs
map-locaux. Les outcomes doivent survivre a un save entre commit producteur et
dispatch consommateur.

**Decision.** `GameState` et `SaveData` porteront un
`NarrativeEventProgress`, absent = valeur vide :

```text
consumedNarrativeEventIds: Set<String>
pendingNarrativeOutcomeDeliveries: List<NarrativeOutcomeDelivery>
deliveredNarrativeOutcomeDeliveryIds: Set<String>
```

`NarrativeOutcomeDelivery` contient :

```text
deliveryId: String
outcome: NarrativeOutcomeRef
causationExecutionId: String?
rootCorrelationId: String
depth: int
attemptCount: int
```

Les IDs d'occurrence utilisent `evx_<uuid-v7>`, `outd_<uuid-v7>` et
`corr_<uuid-v7>`. Les sets sont encodes en ordre lexical ; l'outbox preserve
FIFO. Une delivery racine a `depth = 0`; chaque outcome enfant conserve le
`rootCorrelationId` et incremente la profondeur. La profondeur maximale est 8.
V0 ne compacte pas le set delivered ; Phase L mesure sa croissance avant
release.

Le commit Event/Scene est l'installation atomique d'un nouveau `GameState`
autoritatif contenant consequences, consommation et envelopes pending. Il
devient durable disque uniquement lorsqu'un save normal de ce même state
réussit ; V0 ne prétend pas fournir un autosave transactionnel. Un crash avant
save restaure ensemble le dernier état, sa consommation et son outbox.

La machine de livraison est :

```text
pending -> dispatching (mémoire) -> delivered
```

- `noMatch` et `claimedButIneligible` sont terminaux : pending est retiré et
  l'ID devient delivered ;
- succès du consumer : même transition terminale ;
- échec après sélection/démarrage du consumer : terminal delivered avec
  diagnostic, sans retry automatique ; l'Event consumer reste non consommé ;
- erreur d'infrastructure avant tout planning : `attemptCount` augmente et la
  delivery reste pending ; trois tentatives totales sont autorisées, puis elle
  devient delivered avec diagnostic bloquant ;
- `depth > 8` devient delivered avec diagnostic de récursion, sans dispatch.

Le candidat sélectionné n'est pas persisté. Un retry ne replannifie que si aucune sélection
n'avait encore eu lieu ; dès qu'un Event est sélectionné, son exécution est
menée vers un état terminal avant la delivery suivante. Un save est refusé
pendant `dispatching`, mais il est permis avec des deliveries pending après une
erreur d'infrastructure afin de conserver leur retry au reload.

La transition terminale retire l'envelope pending et ajoute son ID au set
delivered dans un même commit `GameState`.

Aucun namespace persistant `running` n'est cree, car ADR-EV2-013 bloque save et
load pendant l'execution. Aucun namespace `failed` n'est persiste : l'echec
libere le lock, laisse l'Event non consomme et produit un diagnostic.

**Invariants.** `consumedEventIds` reste intact et n'est jamais consulte pour un
Event V2 normal. Les outcomes pending sont rejouees de facon idempotente ; les
delivered ne sont pas rejouees au load. Aucune delivery enfant n'est traitée
inline avant le commit de son parent.

**Consequences positives.** Progression globale sans collisions legacy et
dispatch outcome crash-safe.

**Couts / consequences negatives.** Le ledger delivered est non borne en V0 et
necessite une mesure de readiness.

**Alternatives rejetees.** Reutiliser le set legacy, persister un faux
checkpoint running, dropper les deliveries apres commit, namespace failed.

**Criteres de reouverture.** Checkpoint durable accepte par ADR-EV2-013 ou
preuve de croissance necessitant une compaction idempotente.

**Phases impactees.** F1, F2, J, L.

**Date / phase de ratification.** 2026-07-10 - Phase A.

---

## ADR-EV2-015 - mapEnter lors d'une restauration

**Statut : Accepted**

**Contexte.** Les chemins boot, warp et connection emettent actuellement des
mapEnter directs, tandis que `loadGame` restaure sans occurrence equivalente.

**Decision.** Toute activation map reussie recoit un `activationId` et une
raison exacte parmi `initialBoot`, `warp`, `connection`, `saveRestore`. Une
restauration reussie emet exactement un `mapEnter` avec `saveRestore`, meme sur
la meme map, apres restauration coherente de GameState, map, joueur, monde,
NPCs, trigger occupancy et phase overworld.

Un lancement depuis une vraie save est `saveRestore`, jamais aussi
`initialBoot`. Preload, load echoue ou rollback emet zero occurrence. Le
coordinateur partage la meme occurrence entre V2 et legacy ; chaque pipeline
n'en fabrique pas une copie.

Au load, les deliveries outcome pending sont remises dans la queue FIFO avant
le `mapEnter saveRestore`. Si une delivery change l'activation, l'occurrence
stale est invalidee par son `activationId` et la nouvelle activation emet sa
propre raison.

**Invariants.** Une occurrence maximum par activation terminee. Aucun test
`saveData != null` ne remplace une raison explicite.

**Consequences positives.** Les Events d'entree se comportent de facon
previsible au load sans double boot/load.

**Couts / consequences negatives.** Les fixtures et chemins de restauration
doivent devenir transactionnels et exposes a une queue commune.

**Alternatives rejetees.** Aucun mapEnter au load, emission avant restauration,
boot + load, un hook par pipeline.

**Criteres de reouverture.** Preuve gameplay qu'une categorie de restauration
doit volontairement supprimer l'occurrence, avec nouvelle raison explicite.

**Phases impactees.** F2, J, L.

**Date / phase de ratification.** 2026-07-10 - Phase A.

---

## ADR-EV2-016 - Suppression et changement de source

**Statut : Accepted**

**Contexte.** Supprimer ou renommer une entite/zone peut casser des Events et
claims ; une reaffectation par nom ou position serait silencieusement fausse.

**Decision.** Toute suppression, changement d'ID/map ou changement de kind qui
invalide l'eligibilite est bloque tant qu'un record ou claim reference la
source. Le dialogue liste les dependances et propose uniquement : ouvrir les
Events lies, reassigner explicitement, detacher explicitement, ou supprimer
l'Event separement.

Detacher convertit transactionnellement le record configure en draft sans
source, preserve ses autres champs et le rend non publiable. La mutation du
registry est sauvegardee et relue avant la suppression de la source map.
Pendant `dualRead`, une source couverte par claim est hash-pinned/read-only.

Une suppression externe conserve la reference pendante telle quelle, produit
un blocker `Source no longer exists` et n'effectue aucune mutation au load. La
reparation guidee peut ensuite reassigner ou detacher.

**Invariants.** Pas de force-delete V0, pas de remplacement par label/position,
pas d'auto-desactivation, pas de conversion implicite au chargement.

**Consequences positives.** Aucune perte de comportement cachee ; undo/recovery
peuvent couvrir une transaction explicite.

**Couts / consequences negatives.** La suppression demande une etape de
reparation quand des dependances existent.

**Alternatives rejetees.** Cascade silencieuse, meilleure correspondance par
nom, reference effacee au load, force-delete laissant un Event actif.

**Criteres de reouverture.** Transaction multi-fichiers prouvee permettant une
autre UX sans perte, double dispatch ni reference pendante invisible.

**Phases impactees.** C, E, G, H, I.

**Date / phase de ratification.** 2026-07-10 - Phase A.

---

## ADR-EV2-017 - Collisions d'identites legacy

**Statut : Accepted**

**Contexte.** Un meme ID MapEvent peut exister sur plusieurs maps alors que les
saves, conditions, World Rules et consequences legacy stockent parfois l'ID nu.

**Decision.** Les definitions map-locales sont qualifiees pendant l'inventaire
et recoivent des IDs V2 frais. Une reference ou un bit `consumedEventIds`
resolvant vers plusieurs candidats bloque toute conversion automatique.

Pour un bit consomme collisionne, l'assistant propose :

1. consommer tous les groupes cibles, ce qui preserve le comportement observable
   du set legacy global ;
2. choisir explicitement des cibles et signer un receipt de resolution
   irreversible ;
3. annuler la migration.

Il ne choisit jamais une cible seul. Les IDs legacy inconnus sans candidat sont
preserves comme tombstones avec warning. Pendant `dualRead`, le set legacy
reste inchange et le set V2 est additif. Toute reference nue doit avoir une
resolution unique ou rester bloquante.

**Invariants.** Pas de guess par map active, nom ou position. Chaque mapping est
dans le preview et le receipt. `v2Only` est bloque tant qu'une ambiguite reste.

**Consequences positives.** Migration loss-aware et comportement de save
auditable.

**Couts / consequences negatives.** Certains projets exigent une decision
humaine par collision.

**Alternatives rejetees.** Premiere map, premiere definition, fan-out cache,
drop des IDs inconnus, copie aveugle dans le set V2.

**Criteres de reouverture.** Nouvelle preuve de provenance dans les anciennes
saves permettant une resolution automatique univoque.

**Phases impactees.** C, F1, I, J, L.

**Date / phase de ratification.** 2026-07-10 - Phase A.

---

## ADR-EV2-018 - Fenetre dual-read et rollback

**Statut : Accepted**

**Contexte.** Une duree calendaire ne prouve ni migration complete ni absence
de double dispatch. Un retour aveugle a `legacyOnly` peut rejouer des one-shots.

**Decision.** `dualRead` n'a pas de timer projet. Il reste supporte au minimum
jusqu'au Go V2-43 et jusqu'a ce que chaque source legacy atteignable, reference
et save soit mappee avec zero claim invalide. Les lecteurs/importers legacy
restent disponibles au moins une release supportee apres la premiere release
qui active `v2Only` par defaut pour les projets eligibles.

La sortie exige les preuves V2-05/08, V2-16, V2-17/18, V2-19..22, V2-31/33,
V2-35..37, V2-41/42 et le Go explicite V2-43. Le point de non-retour simple est
la premiere progression/reference V2 persistee non representable exactement en
legacy, pas seulement le switch `v2Only`.

Avant ce point, rollback restaure backup + revisions/hashes inchanges via le
receipt. Apres, il faut une migration compensatoire testee ou rester fail-closed
en `dualRead`; changer seulement le mode est interdit.

**Invariants.** Preview sans ecriture, backup avant commit, reload semantique
apres commit, claims invalides en quarantaine sans fallback.

**Consequences positives.** Sortie fondee sur des preuves et rollback qui ne
duplique pas les recompenses.

**Couts / consequences negatives.** Les adapters restent maintenus au-dela de
la premiere migration reussie.

**Alternatives rejetees.** Delai fixe, retrait a V2-43 sans corpus, toggle de
mode comme rollback universel, suppression immediate des readers.

**Criteres de reouverture.** Migration inverse lossless prouvee pour toutes les
donnees V2-only et toutes les saves supportees.

**Phases impactees.** C, F1, F2, I, J, L.

**Date / phase de ratification.** 2026-07-10 - Phase A.

---

## ADR-EV2-019 - Bibliotheque et responsive desktop

**Statut : Accepted**

**Contexte.** La north star montre une bibliotheque permanente, mais cinq
panneaux deviennent illisibles a petite largeur. Les affordances Scene-owned de
l'image peuvent mentir si elles semblent authorables.

**Decision.** Les breakpoints utilisent la largeur logique totale du Narrative
Studio, navigation incluse :

| Largeur | Regle V0 |
|---|---|
| `1672 x 941` | cinq panneaux stricts ; budgets `191 / 266 / 213 / 565 / 388 px` |
| `> 1672` | bibliotheque inline max 213 px ; l'editeur central absorbe le surplus |
| `1480..1671` | cinq panneaux visibles avec budgets clamps de la spec RESET-00 |
| `1280..1479` | bibliotheque retiree inline et ouverte par bouton explicite dans une side sheet modale pour le focus |
| `< 1280` | etat V0 largeur non supportee, sans perte d'etat ni scroll horizontal cache |

La side sheet piege le focus, ferme avec Escape, rend le focus au bouton et
preserve categorie/scroll. Les items Event-owned s'ajoutent par clic,
Enter/Space ou actions contextuelles. Aucun drag/drop V0.

La bibliotheque separe :

- Event-owned authorable : source/declencheur, conditions V0, choix/ouverture de
  Scene, comportement ;
- Scene-owned read-only : outcomes, branches, reactions/consequences, battle,
  dialogue, cinematic et monde, avec `Ouvrir la Scene` ou `Voir le detail`.

**Invariants.** Aucun grip/drop target sans drag accessible reel. Aucun item
indisponible cliquable. Aucun contenu Scene presente comme ajoutable a l'Event.

**Consequences positives.** Fidelite north star a la largeur cible et parcours
accessible sous le seuil.

**Couts / consequences negatives.** Sous 1480, une action supplementaire est
necessaire pour consulter la bibliotheque.

**Alternatives rejetees.** Bibliotheque toujours cachee, cinq colonnes forcees a
1280, horizontal scroll, faux drag, boutons Scene-owned `Ajouter`.

**Criteres de reouverture.** Visual QA multi-viewport prouve qu'un breakpoint
produit un overflow ou une perte fonctionnelle avec ces regles.

**Phases impactees.** H, K, L.

**Date / phase de ratification.** 2026-07-10 - Phase A.

---

## ADR-EV2-020 - Event declenche, Scene orchestre

**Statut : Accepted**

**Contexte.** Des micro-events semblent favoriser des actions directes, mais un
sous-ensemble Event grandirait en second moteur de branches, consequences et
outcomes.

**Decision.** Option A est ratifiee : chaque Event configure cible exactement
une `SceneAsset` normale et visible. Event V2 ne possede aucune micro-action
directe.

La proliferation est evitee par classification et UX :

- une transition de porte pure appartient a `MapWarp` ;
- un panneau ou pickup natif peut rester map-owned seulement si son contrat
  gameplay reel suffit sans Event narratif ;
- des qu'il existe condition, orchestration, branche, consequence custom ou
  persistence narrative, le chemin est Event -> Scene ;
- `Creer une Scene simple` peut produire en une transaction une Scene template
  normale, ouvrable et evolutive, jamais un pseudo-asset cache dans l'Event.

Les projections Scene sont read-only dans Event Builder. Un action Scene non
supportee bloque la publication au lieu d'etendre le moteur Event.

**Invariants.** Event declenche. Scene orchestre. Cinematic met en scene. Battle
resout. Fact persiste. World Rule projette. Validator diagnostique.

**Consequences positives.** Un seul moteur d'orchestration et une frontiere
stable pour outcomes, branches et consequences.

**Couts / consequences negatives.** Les interactions simples narratives creent
une Scene, ce qui impose templates et navigation efficaces.

**Alternatives rejetees.** Union d'actions directes Event, Scene inline cachee,
combat/recompense/world mutation dans Event Builder.

**Criteres de reouverture.** Au gate Phase J, un corpus representatif prouve que
la majorite des Events necessitent seulement une operation atomique, que le
workflow Scene simple ne peut pas rester une transaction, et qu'une action
directe resterait sans branche, outcome ni consequence. Un nouvel ADR reste
obligatoire.

**Phases impactees.** B, D, E, F1, H, I, J, K.

**Date / phase de ratification.** 2026-07-10 - Phase A.

---

## Entry Gate normatif de Phase B

Phase B peut considerer immuables :

1. `NarrativeEventSourceRef` et ses quatre variants V0 exacts.
2. `NarrativeOutcomeRef` et les producers `scene`, `battle`, `legacyScenario` ;
   Yarn qualifie par la Scene.
3. Le format ID `evt_<uuid-v7>`, l'unicite projet et l'immutabilite des la
   creation du draft.
4. `NarrativeEventCondition` limite a Fact et Event V2 consomme, AND ordonne.
5. Les champs exacts de `NarrativeEventDraft`, `NarrativeEventDefinition` et
   `NarrativeEventRecord`, publication inactive par defaut.
6. `ProjectManifest.eventRegistry` nullable, schema V0 `1`, JSON strict et
   fail-closed sans perte des bytes inconnus.
7. `EventSystemMode`, la truth table d'autorite et l'absence de feature flag
   concurrent.
8. `LegacySourceRef`, les champs de `LegacySourceClaim`, la couverture de
   cohorte et l'absence de fallback sur claim.
9. L'absence absolue de position dans Event et Scene.
10. Un Event configure cible exactement une Scene ; aucune micro-action Event.
11. Le tri `priority DESC, order ASC, eventId ASC`, un seul candidat, conflit
    `(priority,order)` bloquant à l'activation.
12. Le lifecycle oneShot/reusable, le save bloque pendant Scene active et
    l'outbox outcome persistante.
13. La politique de collision, de suppression de source, de dual-read et de
    rollback.

Phase B ne peut modifier aucune de ces decisions. Elle doit s'arreter si un
contrat ne peut pas les encoder avec des tests JSON et de validation bornes.

---
````
