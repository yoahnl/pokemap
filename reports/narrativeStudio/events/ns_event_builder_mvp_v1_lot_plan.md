# NS-EVENT-PLAN-001 — Event Builder MVP / V1 Lot Plan & Technical Roadmap

## 1. Résumé exécutif

Lot exécuté :

```text
NS-EVENT-PLAN-001 — Event Builder MVP / V1 Lot Plan & Technical Roadmap
```

Nature du lot :

```text
audit + plan produit/technique
doc-only
aucune implémentation
```

Verdict :

```text
Event Builder actuel : PARTIAL, mais prêt à planifier.
MVP Event Builder ultra-minimal : 6-8 lots.
MVP Event Builder honnête utilisable : 10-14 lots.
V1 proche de l'image fournie : 18-24 lots.
Version prudente PokeMap avec audits, tests, visual gates, runtime et bis : 24-32 lots.
```

La réponse courte à la question "combien de lots ?" est donc :

```text
Pour un MVP sérieux : environ 12 lots.
Pour une V1 proche de l'image : environ 22 lots.
Pour une V1 robuste façon PokeMap/Codex avec preuves, bis et gates : plutôt 28 lots.
```

Une estimation à 6 lots est réaliste uniquement pour un prototype strictement minimal qui réutilise l'EventPropertiesPanel existant, limite l'Event à un lien `MapEventPage -> Scene V1`, et repousse outcomes, réactions, changements du monde, palette, drag/drop, simulation et validator global. Elle ne permet pas d'atteindre l'UI cible.

L'image fournie a été ouverte localement depuis :

```text
/Users/karim/Desktop/assets/pokeMap/définitive/4 - événements/1 - événements.png
```

Elle n'est pas un contrat pixel-perfect, mais elle montre clairement une cible V1 ambitieuse : liste groupée d'événements, bibliothèque de blocs, flow editor central, inspecteur complet, résultats possibles, réactions par outcome, changements du monde, validation et aperçu.

Recommandation principale :

```text
Commencer par NS-EVENT-01 — Event Builder Existing Surface / Contract Alignment Audit.
```

Ne pas commencer par le canvas drag/drop. Le premier verrou est le contrat produit : Event déclenche, Scene orchestre, Event persiste les conséquences choisies. Il faut l'aligner avec les briques déjà présentes avant de dessiner le bel éditeur.

## 2. Confirmation du scope

Ce lot a respecté le périmètre documentaire :

- aucun code Dart modifié ;
- aucun modèle modifié ;
- aucun widget créé ;
- aucun provider/repository/runtime bridge créé ;
- aucun test de production créé ;
- aucune fixture Selbrume finale créée ;
- aucun `project.json` modifié ;
- aucune roadmap vivante modifiée ;
- aucun commit créé.

Fichier créé :

```text
reports/narrativeStudio/events/ns_event_builder_mvp_v1_lot_plan.md
```

## 3. État Git initial

Commandes exécutées au début :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 20
```

Sortie utile exacte :

```text
/Users/karim/Project/pokemonProject
main
05e70a57 NS-STUDIO-PRODUCT-BETA-READINESS — Audit de préparation pour la bêta de Narrative Studio
da9cce15 NS-SCENES-V1-138 — Selbrume Golden Slice Content Inventory Asset Gap Audit
80dd997a NS-SCENES-V1-137 — Narrative Studio Golden Slice Authoring Readiness Selbrume Demo Content Plan
703c5702 NS-SCENES-V1-136-BIS — Cinematic Builder Legacy Widget Expectations Cleanup
0f9c5cfe NS-SCENES-V1-136 — Cinematic Builder V1 Closure Readiness Audit
2bd11dda NS-SCENES-V1-135 — Cinematic Builder V1 Camera Closure Polish Gate
179cd6aa NS-SCENES-V1-134 — Cinematic Camera Geometry Preview UI V0
28d0e46e NS-SCENES-V1-133 — Cinematic Camera Geometry Playback State V0
d4e0b28b NS-SCENES-V1-132 — Cinematic Camera Target Zoom Editor UI V0
882c2c23 NS-SCENES-V1-131 — Cinematic Camera Target Zoom Core Model V0
a7bb9b42 update selbrume
4c3040a3 update selbrume
47660d78 NS-SCENES-V1-130 — Cinematic Camera Target Zoom Authoring Prep Contract
2344303e update selbrume
3edcfe36 Allow deeper cinematic timeline zoom out
6bb457a4 Polish cinematic emote dropdowns
f16314fe NS-SCENES-V1-129 — Cinematic Emote Preview Playback UI V0
6da6410f NS-SCENES-V1-128 — Cinematic Emote Block Editor UI V0
af8be4ac update selbrume
d864d502 NS-SCENES-V1-128 — Cinematic Timeline Zoom Controller V0
```

`git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` n'ont affiché aucune ligne au Gate 0.

## 4. Règles et skills lus

Fichiers lus :

```text
AGENTS.md
agent_rules.md
codex_rule.md
skills/README.md
skills/writing-plans/SKILL.md
skills/verification-before-completion/SKILL.md
skills/test-driven-development/SKILL.md
```

Application :

- `writing-plans` : utilisé pour structurer une roadmap lot-par-lot concrète.
- `verification-before-completion` : utilisé pour exiger `git diff --check` et état Git final avant clôture.
- `test-driven-development` : lu, mais non appliqué à du code car le lot est audit/plan uniquement.

## 5. Fichiers et sources audités

Sources produit :

```text
MVP Selbrume/narrative_studio.md
MVP Selbrume/checklist_beta_pokemap.md
MVP Selbrume/selbrume.md
MVP Selbrume/road_map_phase_1.md
MVP Selbrume/road_map_phase_7.md
reports/narrativeStudio/ns_studio_product_beta_readiness_audit.md
reports/narrativeStudio/ns_studio_product_beta_readiness_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_00_scene_system_scope_current_state_audit.md
reports/narrativeStudio/scenes/ns_scenes_v1_138_selbrume_golden_slice_content_inventory_asset_gap_audit.md
reports/gameplay/ns_gs/ns_gs_01_golden_slice_exact_specification.md
reports/gameplay/ns_gs/ns_gs_03_content_inventory_fixture_plan.md
reports/gameplay/ns_gs/ns_gs_09_yarn_outcome_scene_branch_readiness.md
reports/gameplay/ns_gs/ns_gs_10_world_rules_conditional_presence_readiness.md
reports/gameplay/ns_gs/ns_gs_12_editor_authored_golden_slice_validation.md
```

Sources code principales :

```text
packages/map_core/lib/src/models/map_event_definition.dart
packages/map_core/lib/src/operations/map_events.dart
packages/map_core/lib/src/diagnostics/event_scene_link_diagnostics.dart
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/lib/src/models/scene_consequence.dart
packages/map_core/lib/src/models/world_rule.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/lib/src/validation/beta_playability_validator.dart
packages/map_editor/lib/src/ui/panels/event_properties_panel.dart
packages/map_editor/lib/src/ui/panels/world_rule_target_section.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart
packages/map_gameplay/lib/src/event_page_resolver.dart
packages/map_gameplay/lib/src/game_state_mutations.dart
```

Tests inventoriés :

```text
packages/map_core/test/map_events_test.dart
packages/map_core/test/event_scene_link_diagnostics_test.dart
packages/map_core/test/narrative_event_source_authoring_operations_test.dart
packages/map_core/test/narrative_validator_test.dart
packages/map_core/test/beta_playability_validator_test.dart
packages/map_editor/test/event_properties_panel_scene_target_test.dart
packages/map_editor/test/facts_world_rules_manager_test.dart
packages/map_runtime/test/scene_event_runtime_hook_test.dart
packages/map_runtime/test/p3_event_source_bridge_validation_test.dart
packages/map_runtime/test/p3_fact_world_rule_projection_test.dart
packages/map_runtime/test/scene_runtime_golden_slice_smoke_test.dart
```

## 6. Preuves clés trouvées dans le repo

### 6.1 Grammaire produit Event

Extrait utile de `MVP Selbrume/narrative_studio.md` :

```text
Event = pourquoi / quand quelque chose démarre.
Scene = ce qui se déroule une fois que c’est démarré.
```

Structure recommandée dans la même source :

```text
Déclencheur
Conditions
Actions
Récompenses
Changements de monde
Comportement
```

### 6.2 Checklist bêta

Extrait utile de `MVP Selbrume/checklist_beta_pokemap.md` :

```text
⬜ 🔥 Event → Scene → Dialogue → Outcome → Fact/Step
⬜ 🔥 World rules visibles en runtime
⬜ 🔥 Dialogue conditionnel après progression
⬜ 🔥 Persistance des events/scènes déjà consommés
```

### 6.3 Modèle event actuel

`MapEventDefinition` existe et porte :

```text
id
title
pages
position
type
metadata
```

`MapEventPage` porte :

```text
condition
script
spriteId
message
sceneTarget
isHidden
isDisabled
metadata
```

`MapEventSceneTarget` existe, mais son commentaire est explicite :

```text
Ce contrat ne lance rien en runtime. Il dit seulement que la page active de
l'event pointe vers une [SceneAsset] existante dans le manifest projet.
```

### 6.4 Opérations Event actuelles

`packages/map_core/lib/src/operations/map_events.dart` fournit notamment :

```text
addMapEventToMap
updateMapEventOnMap
moveMapEventOnMap
removeMapEventFromMap
addPageToMapEvent
updatePageOnMapEvent
setMapEventPageSceneTarget
clearMapEventPageSceneTarget
removePageFromMapEvent
```

Implication : les primitives de mutation map/event existent déjà. Le futur Event Builder ne part pas de zéro.

### 6.5 UI Event actuelle

`EventPropertiesPanel` existe et contient déjà :

```text
event-scene-target-dropdown
Scene V1
Aucune Scene V1
Aucune Scene V1 disponible
Retirer Scene
Lien authoring uniquement, runtime Scene à venir.
JSON brut
Event consommé
```

Implication : l'UI actuelle est un inspecteur Map Event, pas encore l'Event Builder cible.

### 6.6 Diagnostics Event -> Scene

`EventSceneLinkDiagnosticCode` contient :

```text
eventSceneTargetUnknown
eventSceneTargetEmpty
eventSceneTargetDisabledPage
eventSceneTargetSceneHasErrors
eventSceneTargetRuntimePlanNotBuildable
eventSceneTargetMixedLegacyContent
```

Implication : les diagnostics du lien Scene existent, mais pas encore l'orchestration complète de l'Event Builder cible.

### 6.7 Runtime hook Event -> Scene

`SceneEventRuntimeHook.runForEventPage` existe et :

- ignore une page sans `sceneTarget` ;
- échoue clairement si la scene manque ;
- vérifie les diagnostics scene ;
- construit un `SceneRuntimePlan` ;
- exécute `SceneRuntimeExecutor` ;
- collecte les `SceneConsequence` ;
- applique les conséquences via `SceneConsequenceRuntimeWriter` si un `GameState` est fourni.

Implication importante : le rapport de readiness précédent était plus sévère côté produit que côté runtime. Techniquement, un hook existe. Le chantier Event Builder doit donc surtout aligner contrat, authoring, UX, diagnostics et smoke end-to-end.

## 7. État actuel du repo par brique

| Brique | Statut | Preuve trouvée | Risque | Impact lots |
|---|---|---|---|---|
| Modèle Event / MapEventDefinition | DONE | `map_event_definition.dart` | Modèle RPG pages legacy, pas modèle Event Builder riche. | Réutilisable mais adaptation read model nécessaire. |
| Source d'événement | PARTIAL | Event position/type + narrative event source authoring ops. | Source encore dispersée entre map event, scenario source, scene condition. | 1-2 lots d'alignement. |
| Trigger | PARTIAL | `MapEventType.actor/object/triggerZone/effect`, EventPageResolver. | Pas de trigger no-code riche interaction/zone/item/fin scène. | 1 lot core/read model + 1 UI. |
| Conditions | PARTIAL | `ScriptCondition`, scene conditions, fact/step/event consumed. | `JSON brut` encore visible dans panel. | 2 lots pour MVP no-code propre. |
| Actions | PARTIAL | `sceneTarget`, legacy script/message, Scene runtime actions. | Event actions directes non modélisées comme blocs UI. | 2-3 lots. |
| Outcomes | PARTIAL | Scene outcomes, Yarn/Battle outcomes, runtime tests. | Où vivent les outcomes côté Event reste à cadrer. | 2 lots minimum. |
| Consequences / Reactions | PARTIAL | `SceneConsequence`, `SceneConsequenceRuntimeWriter`. | Réactions par outcome absentes côté Event Builder. | 3-4 lots. |
| Facts | DONE | `NarrativeFact`, authoring/tests. | Besoin pickers no-code dans Event Builder. | 1 lot UI intégration. |
| Story Steps | PARTIAL | Storyline/steps models/tests. | Lien Step completion depuis Event à clarifier. | 1-2 lots. |
| World Rules | DONE/PARTIAL | WorldRule model/UI/projection tests. | Event Builder ne doit pas devenir World Rules editor. | 1 lot d'intégration liens. |
| Event -> Scene | PARTIAL_READY | `MapEventSceneTarget`, diagnostics, runtime hook. | Wording UI encore "runtime à venir". | 2 lots pour fermeture produit. |
| Event -> Dialogue | MISSING_DIRECT | Dialogue passe plutôt par Scene. | Risque de court-circuiter Scene. | Hors MVP direct, via Scene. |
| Event -> Cinematic | MISSING_DIRECT | Cinematic passe plutôt par Scene. | Risque de Scene Builder bis. | Hors MVP direct, via Scene. |
| Event -> Battle | MISSING_DIRECT/PARTIAL | Battle outcome adapter dans Scene runtime. | Couplage battle à Event si mal cadré. | V1 via outcome reactions, pas MVP direct. |
| Runtime bridge Event -> Scene | PARTIAL_READY | `SceneEventRuntimeHook` + tests. | Pas encore prouvé depuis UI Event Builder cible. | 1-2 lots smoke/bridge. |
| Persistence event consumed/facts/steps | PARTIAL_READY | GameState consumedEventIds + mutations + writer. | Frontière Event consomme vs Scene consomme à décider. | 2 lots. |
| Diagnostics Event | PARTIAL_READY | `event_scene_link_diagnostics.dart`. | Pas encore diagnostics Event Builder complet. | 2 lots. |
| Validator global | PARTIAL/MISSING_UI | Core validators, sidebar non branchée. | Bêta bloquée. | 2-3 lots. |
| UI Event list | PARTIAL | EventPropertiesPanel liste map events. | Pas list groupée Narrative Studio comme image. | 2 lots. |
| UI Event editor | PARTIAL | Inspector panel actuel. | Pas flow central. | 4-6 lots. |
| UI palette / bibliothèque | MISSING | Aucun Event Builder palette trouvé. | Gros morceau UI. | 2 lots. |
| UI central flow builder | MISSING | Image cible seulement. | Peut exploser si drag/drop libre. | 3-5 lots. |
| UI inspector | PARTIAL | EventPropertiesPanel. | Inspecteur cible plus riche. | 2-3 lots. |
| Preview map | PARTIAL | Map canvas events, map inspector. | Event Builder preview dédiée absente. | V1/polish. |
| Simulation / tester | MISSING | Runtime tests mais pas UI tester. | Risque de promettre trop tôt. | V1 tardive. |
| Visual gate / screenshots | MISSING pour Event Builder | Image fournie externe. | Chaque lot UI demandera gates. | 3-5 lots de gate/polish. |
| Tests existants | PARTIAL_READY | Core/editor/runtime tests listés. | Pas encore tests Event Builder cible. | Tests à chaque lot. |

## 8. Analyse de l'UI cible fournie

### 8.1 Sidebar globale / shell PokeMap

Utilité produit : situer Event Builder comme surface Narrative Studio au même niveau que Storylines, Scènes, Cinématiques, Dialogues, Facts et World Rules.

Complexité technique : M.

Dépendances :

- `narrative_studio_sidebar.dart` ;
- routing workspace mode ;
- icônes/design system.

Statut : V1, pas MVP strict si l'Event Builder peut d'abord être ouvert depuis un workspace existant.

Tests nécessaires :

- l'entrée Événements est visible ;
- sélectionne le bon workspace ;
- ne casse pas Scènes/Cinématiques/Facts.

Visual gate : écran global avec Événements sélectionné.

### 8.2 Navigation Narrative Studio

Utilité : réduire la confusion entre Map Events, Scene Builder et Event Builder.

Complexité : M.

MVP ou V1 : MVP honnête.

Risque : nommer "Événements" alors que l'ancien Map Event inspector existe déjà ; il faut distinguer "Map Event technique" et "Event narratif no-code".

### 8.3 Liste des événements

Utilité : créer la vue d'ensemble du chantier narratif local, groupée par map/zone.

Complexité : M.

MVP : oui, version simple.

V1 : groupements, statuts, recherche, compteur, badges Actif/Brouillon/Inactif.

Composants nécessaires :

- read model Event list ;
- groupement map/zone ;
- status dérivé ;
- empty state ;
- sélection.

Tests :

- liste groupée ;
- recherche ;
- sélection ;
- statut brouillon/inactif/actif ;
- event sans scene ou condition invalide.

### 8.4 Bibliothèque d'éléments

Utilité : guider le créateur, éviter le JSON/script libre.

Complexité : M/L.

MVP : palette par clic uniquement, sans drag/drop.

V1 : catégories Déclencheurs, Conditions, Actions, Résultats, Réactions, Monde ; drag/drop optionnel ou clic-to-add.

Risque : si la palette arrive avant les contrats core, elle devient décorative.

### 8.5 Canvas central / Flow editor

Utilité : visualiser la grammaire canonique de l'event.

Complexité : L.

MVP : flow vertical non libre, sections fixes.

V1 : slots droppables, outcomes branchés, réactions par outcome.

À éviter : graph libre à la Scene Builder. L'Event Builder doit rester un formulaire/blocs structurés.

### 8.6 Blocs Déclencheur / Conditions / Actions / Résultats / Réactions / Monde

Utilité : rendre la grammaire visible.

Complexité : L.

MVP :

- Déclencheur simple ;
- Conditions Fact/Step ;
- Action Jouer Scene ;
- Conséquences SetFact/CompleteStep/MarkEventConsumed.

V1 :

- Lancer combat ;
- résultats victoire/défaite/échec ;
- réactions par outcome ;
- changements du monde ;
- récompenses simples.

### 8.7 Droppable slots

Utilité : rendre l'ajout pédagogique.

Complexité : M/L.

MVP : non. Remplacer par boutons `+ Ajouter`.

V1 : oui si le design system et tests widget peuvent le couvrir proprement.

### 8.8 Inspecteur d'événement

Utilité : édition précise, sans surcharger le flow central.

Complexité : M.

MVP : oui, inspecteur borné pour déclencheur/source/conditions/comportement.

V1 : réactions, réutilisation, reset, priorité, diagnostics inline.

### 8.9 Validation / aperçu

Utilité : indispensable pour ne pas mentir au créateur.

Complexité : M/L.

MVP : bouton Valider local + diagnostics.

V1 : Aperçu/test de l'event dans un contexte simulé.

### 8.10 États et statuts

Utilité : distinguer actif, brouillon, inactif, invalide.

Complexité : M.

MVP : `Actif` si trigger + scene + diagnostics P0 clean ; `Brouillon` sinon ; `Inactif` si disabled.

V1 : statuts par outcome/reaction et statut global Project Health.

## 9. Version MVP réduite proposée

L'UI cible est trop ambitieuse pour un premier MVP si l'on respecte la méthode PokeMap. Le MVP honnête doit être plus petit :

```text
Liste événements
Sélection événement
Sections fixes : Déclencheur / Conditions / Action principale / Conséquences / Comportement
Pas de drag/drop
Pas de graph libre
Pas de résultats victory/defeat au premier lot UI
Pas de simulation complexe
```

Le MVP doit fermer le verrou produit suivant :

```text
Un créateur peut créer ou éditer un Event no-code qui lance une Scene et pose des conséquences simples, avec diagnostics et sauvegarde projet.
```

## 10. Fonctionnalités MVP strictes

Le plus petit Event Builder honnête doit permettre :

1. Lister les events par map active ou projet.
2. Créer/éditer un event.
3. Attacher un event à une source simple :
   - PNJ ;
   - zone trigger.
4. Choisir un trigger simple :
   - interaction PNJ ;
   - entrée zone.
5. Choisir une Scene liée.
6. Ajouter conditions simples :
   - Fact vrai/faux ;
   - Story Step active/completed ;
   - Event consommé/non consommé.
7. Ajouter conséquences simples :
   - SetFact ;
   - CompleteStep ;
   - MarkEventConsumed.
8. Diagnostiquer les erreurs P0 :
   - cible absente ;
   - Scene manquante ;
   - Scene non buildable ;
   - fact/step inconnu ;
   - event sans action ;
   - event sans trigger.
9. Sauvegarder dans le projet via les opérations existantes.
10. Prouver Event -> Scene -> Outcome -> Fact/Step par tests ciblés et smoke.

Hors MVP :

- drag/drop complet ;
- flow graph libre ;
- conditions imbriquées ;
- récompenses avancées ;
- battle authoring complet ;
- changement du monde avancé ;
- templates avancés ;
- simulation complexe ;
- visual diff du monde ;
- runtime de toutes les actions possibles ;
- édition de dialogue/cinematic/battle depuis l'Event Builder.

## 11. Fonctionnalités V1 proches de l'image

V1 proche de l'image doit ajouter :

- liste groupée par map/zone ;
- statuts actif/brouillon/inactif ;
- bibliothèque de blocs catégorisée ;
- ajout par clic, puis drag/drop si validé ;
- flow central vertical ;
- résultats possibles victoire/défaite/échec ;
- réactions par outcome ;
- changements du monde ;
- inspecteur complet ;
- validation Event ;
- aperçu/test ;
- visual gates desktop ;
- UX polish.

Découpage :

| Fonctionnalité | MVP obligatoire | V1 souhaitable | V2 à repousser |
|---|---:|---:|---:|
| Liste events simple | Oui | Oui | Non |
| Liste groupée map/zone | Non | Oui | Non |
| Déclencheur PNJ/zone | Oui | Oui | Non |
| Conditions Fact/Step/Event consumed | Oui | Oui | Non |
| Action Jouer Scene | Oui | Oui | Non |
| Combat direct depuis Event | Non | Oui via Scene/outcome | Authoring battle complet |
| Outcomes victory/defeat | Non | Oui | Branches avancées |
| Réactions par outcome | Non | Oui | Conditions imbriquées |
| SetFact / CompleteStep / MarkConsumed | Oui | Oui | Scripts libres |
| Changement dialogue PNJ | Non | Oui | Diff visuel monde complet |
| Bibliothèque de blocs | Partielle | Oui | Templates avancés |
| Drag/drop | Non | Option V1 tardive | Graph libre |
| Simulation UI | Non | Oui simple | Debugger runtime complet |
| Validator global | Oui pour MVP honnête | Oui | Validator parfait assets/audio |

## 12. Découpage lot par lot

### Phase A — Audit et cadrage

### NS-EVENT-01 — Event Builder Existing Surface / Contract Alignment Audit

Type : audit.

Objectif : figer la frontière Event/Scene/WorldRule/Validator avant le code.

Pourquoi ce lot existe : le repo contient déjà `MapEventDefinition`, `EventPropertiesPanel`, `SceneEventRuntimeHook`, `SceneConsequenceRuntimeWriter` et diagnostics. Il faut éviter de créer un second système Event.

Scope exact :

- auditer `MapEventDefinition`, `MapEventPage`, `MapEventSceneTarget`, `ScriptCondition`, `SceneConsequence`, `WorldRule`, `GameState` ;
- décider le contrat Event MVP ;
- décider ce qui reste dans Scene ;
- décider si Event porte seulement une action Scene ou aussi des consequences directes ;
- produire une matrice de mapping image -> repo.

Non-objectifs :

- aucun code ;
- aucun widget ;
- aucune migration ;
- aucune donnée Selbrume.

Packages/fichiers probables :

```text
reports/narrativeStudio/events/ns_event_01_existing_surface_contract_alignment.md
packages/map_core/lib/src/models/map_event_definition.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart
packages/map_editor/lib/src/ui/panels/event_properties_panel.dart
```

Tests attendus : aucun, doc-only.

Visual gate : non.

Critères d'acceptation :

- contrat Event MVP écrit ;
- frontières Event/Scene/WorldRule validées ;
- liste des modèles à réutiliser ;
- décisions restantes explicites.

Risque : faible.

Complexité : S.

Probabilité de bis : moyenne, si les frontières Event/Scene sont contestées.

### NS-EVENT-02 — Event MVP Data Contract Prep

Type : modèle / contrat.

Objectif : définir le contrat authoring MVP sans casser le JSON existant.

Scope exact :

- caractériser si le MVP enrichit `MapEventPage.metadata` ou ajoute des champs typés ;
- définir trigger kind, source binding, condition bindings, action bindings, consequence bindings ;
- écrire tests RED pour encode/decode backward-compatible ;
- ne pas encore créer l'UI.

Non-objectifs :

- pas de runtime ;
- pas de widget ;
- pas de drag/drop ;
- pas de Selbrume.

Packages/fichiers probables :

```text
packages/map_core/lib/src/models/map_event_definition.dart
packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart
packages/map_core/lib/map_core.dart
packages/map_core/test/map_events_test.dart
packages/map_core/test/event_builder_authoring_operations_test.dart
```

Tests attendus :

- ancien event sans Event Builder metadata reste lisible ;
- event trigger PNJ encode/decode ;
- event trigger zone encode/decode ;
- conditions Fact/Step/Event consumed encode/decode ;
- consequence SetFact/CompleteStep/MarkConsumed encode/decode.

Visual gate : non.

Critères d'acceptation :

- contrat stable ;
- pas de migration forcée ;
- API pure map_core exportée ;
- tests passent.

Risque : moyen.

Complexité : M.

Probabilité de bis : moyenne.

### Phase B — Core contracts / read models

### NS-EVENT-03 — Event Builder Read Model V0

Type : core / read model.

Objectif : produire un read model pur pour la liste et le flow Event Builder.

Scope exact :

- dériver events par map/zone ;
- dériver statut Actif/Brouillon/Inactif/Invalide ;
- dériver sections Déclencheur/Conditions/Actions/Conséquences ;
- labels no-code ;
- aucune UI.

Non-objectifs :

- pas de mutation ;
- pas de runtime ;
- pas de drag/drop.

Fichiers probables :

```text
packages/map_core/lib/src/read_models/event_builder_read_model.dart
packages/map_core/test/event_builder_read_model_test.dart
```

Tests attendus :

- event complet -> Actif ;
- event sans scene -> Brouillon ;
- page disabled -> Inactif ;
- scene manquante -> Invalide ;
- labels masquent les IDs techniques.

Visual gate : non.

Complexité : M.

Probabilité de bis : faible.

### NS-EVENT-04 — Event Builder Pure Authoring Operations V0

Type : core / authoring.

Objectif : fournir des opérations pures pour créer/mettre à jour un event MVP.

Scope exact :

- create event draft ;
- update trigger ;
- update scene action ;
- add/remove condition ;
- add/remove consequence ;
- set behavior one-shot/reusable/disabled ;
- préserver les champs legacy existants.

Non-objectifs :

- pas d'UI ;
- pas de runtime ;
- pas de JSON brut exposé.

Tests attendus :

- création draft unique ;
- update trigger PNJ ;
- update trigger zone ;
- conditions normalisées ;
- consequences normalisées ;
- legacy message/script préservés ou signalés selon contrat.

Complexité : M.

Probabilité de bis : moyenne.

### NS-EVENT-05 — Event Builder Diagnostics V0

Type : diagnostics.

Objectif : compléter les diagnostics Event Builder au-delà du seul lien Scene.

Scope exact :

- event sans trigger ;
- event sans action ;
- condition fact inconnue ;
- condition step inconnue ;
- consequence fact inconnue ;
- scene action manquante ;
- mixed legacy content ;
- action non supportée MVP.

Non-objectifs :

- pas de Validator UI global ;
- pas de correction automatique.

Fichiers probables :

```text
packages/map_core/lib/src/diagnostics/event_builder_diagnostics.dart
packages/map_core/test/event_builder_diagnostics_test.dart
```

Tests attendus :

- chaque diagnostic P0 ;
- labels no-code ;
- diagnostic severity ;
- event valide sans diagnostic error.

Complexité : M.

Probabilité de bis : faible.

### Phase C — UI shell et liste

### NS-EVENT-06 — Narrative Studio Events Workspace Shell V0

Type : UI.

Objectif : ajouter une surface `Événements` sans flow editor complet.

Scope exact :

- entrée sidebar Narrative Studio ;
- workspace vide ;
- chargement read model ;
- empty state ;
- pas d'édition.

Non-objectifs :

- pas de flow ;
- pas de palette ;
- pas de runtime.

Fichiers probables :

```text
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

Tests attendus :

- entrée Événements visible ;
- sélection ouvre workspace ;
- empty state sans event ;
- autres workspaces non cassés.

Visual gate attendu :

```text
reports/narrativeStudio/events/screenshots/ns_event_06_events_workspace_shell_v0.png
```

Complexité : M.

Probabilité de bis : faible.

### NS-EVENT-07 — Event List Grouped by Map V0

Type : UI / read model integration.

Objectif : lister les events groupés par map avec statuts.

Scope exact :

- liste groupée par map ;
- recherche ;
- compteur ;
- badges Actif/Brouillon/Inactif/Invalide ;
- sélection event.

Non-objectifs :

- pas de création ;
- pas de flow editor.

Tests attendus :

- groupement map ;
- status badge ;
- recherche filtre ;
- sélection stable.

Visual gate : liste events avec un event sélectionné.

Complexité : M.

Probabilité de bis : moyenne.

### NS-EVENT-08 — Event Draft Creation / Selection V0

Type : UI + authoring.

Objectif : créer un brouillon Event MVP depuis le workspace.

Scope exact :

- bouton `Nouvel événement` ;
- générer ID stable non final ;
- créer event sur map active ;
- sélectionner le draft ;
- sauvegarder en mémoire projet comme les autres editor operations.

Non-objectifs :

- pas de templates avancés ;
- pas de Selbrume final.

Tests attendus :

- création draft ;
- ID unique ;
- sélection immédiate ;
- suppression contrôlée si nécessaire.

Visual gate : draft visible en liste.

Complexité : M.

Probabilité de bis : moyenne.

### Phase D — Event editor MVP

### NS-EVENT-09 — Event Flow Read-Only MVP

Type : UI.

Objectif : afficher le flow central en lecture seule à partir du read model.

Scope exact :

- sections fixes Déclencheur / Conditions / Action / Conséquences / Comportement ;
- labels no-code ;
- état incomplet lisible ;
- pas encore d'édition inline.

Non-objectifs :

- pas de drag/drop ;
- pas de résultats victory/defeat ;
- pas de simulation.

Tests attendus :

- event complet affiche les sections ;
- event incomplet affiche des placeholders humains ;
- IDs techniques absents comme workflow principal.

Visual gate : flow read-only.

Complexité : M.

Probabilité de bis : faible.

### NS-EVENT-10 — Trigger Editor MVP

Type : UI + authoring.

Objectif : éditer le déclencheur PNJ/zone.

Scope exact :

- type Interaction PNJ / Entrée zone ;
- cible via picker map entity/event/zone existant ;
- portée map ;
- fallback si aucune cible.

Non-objectifs :

- pas item/object advanced ;
- pas fin de scène ;
- pas multiple triggers.

Tests attendus :

- sélectionner PNJ ;
- sélectionner zone ;
- cible absente diagnostic ;
- pas de champ ID libre.

Visual gate : inspecteur déclencheur.

Complexité : M/L.

Probabilité de bis : moyenne.

### NS-EVENT-11 — Conditions Editor MVP

Type : UI + authoring.

Objectif : éditer conditions Fact/Step/Event consumed.

Scope exact :

- mode toutes conditions ;
- ajouter/supprimer condition ;
- picker Fact ;
- picker Story Step ;
- picker Event consumed ;
- opérateurs simples vrai/faux/active/completed.

Non-objectifs :

- pas OR groups ;
- pas conditions imbriquées ;
- pas script variable libre ;
- pas JSON brut.

Tests attendus :

- add fact condition ;
- add step condition ;
- add event consumed ;
- remove condition ;
- diagnostics target missing.

Visual gate : conditions dans flow et inspecteur.

Complexité : L.

Probabilité de bis : élevée.

### NS-EVENT-12 — Scene Action Editor MVP

Type : UI + authoring.

Objectif : choisir une Scene comme action principale.

Scope exact :

- picker Scene ;
- affichage diagnostics scene ;
- préservation legacy content selon contrat ;
- wording runtime honnête mis à jour si hook actif.

Non-objectifs :

- pas action battle directe ;
- pas action dialogue directe ;
- pas multi-action.

Tests attendus :

- choisir scene ;
- retirer scene ;
- scene manquante ;
- scene non buildable.

Visual gate : action Jouer une scène.

Complexité : M.

Probabilité de bis : moyenne.

### NS-EVENT-13 — Consequences MVP

Type : UI + authoring.

Objectif : ajouter SetFact / CompleteStep / MarkEventConsumed.

Scope exact :

- section Conséquences ;
- picker Fact ;
- picker Step ;
- option consommer event ;
- write model compatible `SceneConsequenceRuntimeWriter` ou contrat Event dédié.

Non-objectifs :

- pas rewards ;
- pas world changes avancés ;
- pas outcome-specific reactions.

Tests attendus :

- set fact ;
- complete step ;
- mark event consumed ;
- normalize duplicates ;
- diagnostic fact/step missing.

Visual gate : conséquences visibles.

Complexité : L.

Probabilité de bis : élevée.

### Phase E — Diagnostics / validator / runtime MVP

### NS-EVENT-14 — Event Builder Local Validation UI V0

Type : UI diagnostics.

Objectif : bouton `Valider` local + affichage diagnostics no-code pour l'event sélectionné.

Scope exact :

- diagnostics P0/P1 ;
- message lisible ;
- liens vers section concernée ;
- statut global event.

Non-objectifs :

- pas validator projet complet ;
- pas correction automatique.

Tests attendus :

- event valide ;
- event sans trigger ;
- event sans scene ;
- fact missing ;
- scene non buildable.

Visual gate : diagnostics local event.

Complexité : M.

Probabilité de bis : moyenne.

### NS-EVENT-15 — Runtime Event -> Scene MVP Smoke

Type : runtime / tests.

Objectif : prouver qu'un event authoré MVP peut lancer une Scene et écrire conséquences dans GameState.

Scope exact :

- utiliser `SceneEventRuntimeHook` ;
- fixture projet authorée MVP ;
- event page sceneTarget ;
- consequence SetFact/CompleteStep/Consumed ;
- save/load non requis dans ce lot.

Non-objectifs :

- pas UI ;
- pas Selbrume final ;
- pas combat complet.

Tests attendus :

```text
packages/map_runtime/test/event_builder_mvp_runtime_smoke_test.dart
```

Cas :

- event sans scene -> notHandled ;
- scene valide -> completed ;
- consequence sans GameState -> erreur contrôlée ;
- GameState mis à jour.

Visual gate : non.

Complexité : M.

Probabilité de bis : moyenne.

### NS-EVENT-16 — Event Consumed / Save-Load Persistence Gate

Type : runtime / persistence tests.

Objectif : prouver que consumed events et facts survivent save/load.

Scope exact :

- GameState consumedEventIds ;
- facts/story flags selon contrat ;
- file save repository ou use case existant ;
- no UI.

Non-objectifs :

- pas de vraie démo Selbrume ;
- pas de menu save.

Tests attendus :

- mark consumed puis save/load ;
- fact set puis save/load ;
- step completion si représenté dans GameState.

Complexité : M.

Probabilité de bis : moyenne.

### NS-EVENT-17 — MVP Visual Gate / Closure

Type : UI gate / rapport.

Objectif : fermer le MVP Event Builder utilisable.

Scope exact :

- screenshot avec liste + event sélectionné + trigger + condition + scene + consequence ;
- rapport MVP ;
- tests ciblés ;
- anti-scope runtime si non touché.

Non-objectifs :

- pas V1 image complète ;
- pas drag/drop.

Critères :

- MVP honnête authorable ;
- diagnostics event ;
- runtime smoke prouvé ;
- visual gate.

Complexité : S/M.

Probabilité de bis : moyenne.

### Phase F — V1 proche de l'image

### NS-EVENT-18 — Event Element Library V1

Type : UI.

Objectif : bibliothèque d'éléments par catégories.

Scope exact :

- Déclencheurs ;
- Conditions ;
- Actions ;
- Résultats ;
- Réactions ;
- Monde ;
- ajout par clic.

Non-objectifs :

- pas drag/drop ;
- pas templates complexes.

Tests : clic ajoute au bon slot.

Visual gate : bibliothèque visible.

Complexité : M.

Probabilité de bis : moyenne.

### NS-EVENT-19 — Outcomes / Results V1

Type : core + UI.

Objectif : représenter les résultats possibles `Victoire`, `Défaite`, `Échec`.

Scope exact :

- read model outcome lanes ;
- action battle via Scene ou binding symbolique ;
- pas de battle authoring complet ;
- branch labels no-code.

Non-objectifs :

- pas battle engine ;
- pas équipes dresseur.

Tests :

- outcomes dérivés ;
- victory/defeat branch ;
- unknown outcome diagnostic.

Visual gate : résultats possibles.

Complexité : L.

Probabilité de bis : élevée.

### NS-EVENT-20 — Outcome Reactions V1

Type : core + UI + runtime tests.

Objectif : réactions par outcome.

Scope exact :

- victory reactions ;
- defeat reactions ;
- set fact per outcome ;
- scene per outcome ;
- reward placeholder borné si supporté.

Non-objectifs :

- pas système complet rewards/items si les modèles ne sont pas prêts ;
- pas économie complète.

Tests :

- outcome victory set fact ;
- outcome defeat set fact ;
- unknown outcome ignored/diagnosed ;
- ordering preserved.

Visual gate : colonnes réactions.

Complexité : L.

Probabilité de bis : élevée.

### NS-EVENT-21 — World Changes V1

Type : core + UI.

Objectif : section Changements du monde.

Scope exact :

- changer dialogue PNJ via world rule ou binding validé ;
- débloquer quête/story step ;
- activer/désactiver élément si déjà supporté ;
- messages no-code.

Non-objectifs :

- pas visual diff complet ;
- pas map editing direct depuis Event.

Tests :

- world change crée binding valide ;
- target missing diagnostic ;
- World Rules restent séparées.

Visual gate : section Monde.

Complexité : L.

Probabilité de bis : élevée.

### NS-EVENT-22 — Behavior / Reuse / Priority V1

Type : core + UI.

Objectif : comportement `Une seule fois`, `Jamais`, `Priorité normale`.

Scope exact :

- one-shot ;
- reusable ;
- reset policy none ;
- priority normal/high/low si nécessaire ;
- persistence consumed.

Non-objectifs :

- pas scheduler complexe ;
- pas reset conditionnel avancé.

Tests :

- one-shot marks consumed ;
- consumed event no longer triggers ;
- reusable remains available ;
- priority ordering when multiple events same tile.

Complexité : M/L.

Probabilité de bis : moyenne.

### NS-EVENT-23 — Drag/Drop Slots V1

Type : UI.

Objectif : rendre les slots droppables comme l'image.

Scope exact :

- drag depuis bibliothèque ;
- drop dans slot compatible ;
- refus no-code si incompatible ;
- clavier/souris accessibles.

Non-objectifs :

- pas graph libre ;
- pas reorder complexe.

Tests :

- drag condition vers Conditions ;
- drag action vers Actions ;
- drop incompatible affiche message ;
- pas de mutation si drop refusé.

Visual gate : slots droppables.

Complexité : L.

Probabilité de bis : élevée.

### NS-EVENT-24 — Event Preview / Test Harness V1

Type : UI + runtime harness.

Objectif : bouton Aperçu/Test sans lancer une vraie session complète.

Scope exact :

- simulation contrôlée avec contexte choisi ;
- lire diagnostics ;
- afficher résultat attendu ;
- ne pas muter project data.

Non-objectifs :

- pas runtime playable complet ;
- pas save réel ;
- pas debugger pas-à-pas.

Tests :

- preview event valide ;
- preview event bloqué condition ;
- preview no mutation.

Visual gate : panneau aperçu.

Complexité : L.

Probabilité de bis : élevée.

### NS-EVENT-25 — Validator Global Integration V1

Type : validator UI.

Objectif : brancher Event Builder au Validateur Narrative Studio.

Scope exact :

- afficher diagnostics event dans Validator ;
- compter blockers ;
- liens vers event ;
- projet jouable narratif partiel.

Non-objectifs :

- pas validator assets/audio complet ;
- pas résolution automatique.

Tests :

- validator voit event sans trigger ;
- validator voit scene missing ;
- validator voit world rule broken ;
- navigation vers event.

Visual gate : Validateur branché.

Complexité : L.

Probabilité de bis : élevée.

### NS-EVENT-26 — Selbrume-like Event Builder Smoke

Type : fixture / runtime / editor validation.

Objectif : prouver un flux proche rival port sans écrire la donnée finale Selbrume.

Scope exact :

- fixture test hors `selbrume/project.json` ;
- event rival-like ;
- scene ;
- battle stub si nécessaire ;
- outcome fact ;
- world rule projection.

Non-objectifs :

- pas contenu final ;
- pas IDs canoniques si V1-138-bis non clos.

Tests :

- Event -> Scene -> Dialogue -> Battle outcome -> Fact/Step ;
- world rule visible ;
- consumed persisted.

Visual gate : optionnelle si UI stable.

Complexité : L.

Probabilité de bis : élevée.

### NS-EVENT-27 — Event Builder V1 Polish / Closure Gate

Type : polish / visual gate / rapport.

Objectif : fermer la V1 proche de l'image.

Scope exact :

- wording ;
- densité UI ;
- states empty/error/loading ;
- visual gate ;
- tests V1 ;
- rapport de clôture.

Non-objectifs :

- pas V2 ;
- pas templates avancés ;
- pas runtime complet hors Event.

Critères :

- UI proche de l'image ;
- MVP + V1 tests verts ;
- validator branché ;
- runtime smoke vert ;
- limites V2 explicites.

Complexité : M.

Probabilité de bis : moyenne.

## 13. Estimation du nombre de lots

| Périmètre | Nombre de lots estimé | Commentaire |
|---|---:|---|
| MVP ultra-minimal | 6-8 | Liste simple, trigger, scene action, diagnostics locaux, runtime smoke minimal. Pas proche de l'image. |
| MVP honnête utilisable | 10-14 | Flow fixe, conditions, consequences, validation locale, persistence gate, visual gate. |
| V1 proche de l'image | 18-24 | Bibliothèque, grouped list, outcomes, reactions, world changes, inspecteur complet, preview/test. |
| V1 robuste avec runtime + diagnostics + visual gates | 24-32 | Méthode PokeMap complète avec audits, bis, tests, validator, Selbrume-like smoke, closure gate. |

Répartition réaliste :

| Catégorie | Lots estimés |
|---|---:|
| Audit/design | 2-3 |
| Modèle/core/read models | 4-6 |
| UI shell/list/editor | 7-10 |
| Runtime/persistence | 3-5 |
| Tests/visual gates | 4-6 |
| Polish/closure | 2-4 |
| Bis probables | 4-8 |

Conclusion honnête :

```text
12 lots pour un MVP sérieux.
22 lots pour une V1 proche de l'image.
28 lots pour une trajectoire prudente PokeMap avec preuves et bis.
```

## 14. Dépendances et blockers

### 14.1 Dépendances techniques

- `MapEventDefinition` doit rester backward-compatible.
- `MapEventPage.sceneTarget` existe et doit être réutilisé ou migré prudemment.
- `SceneEventRuntimeHook` existe et doit rester la base runtime Event -> Scene.
- `SceneConsequenceRuntimeWriter` doit être la référence pour écrire facts/steps/consumed.
- Les pickers doivent utiliser les read models existants quand possible.
- Les diagnostics Event Builder doivent compléter, pas remplacer, `EventSceneLinkDiagnostics`.

### 14.2 Dépendances produit

- Confirmer que l'Event lance principalement une Scene.
- Confirmer que Dialogue/Cinematic/Battle restent orchestrés par Scene pour MVP.
- Confirmer que l'Event peut porter des conséquences persistantes simples.
- Confirmer que les réactions par outcome sont V1, pas MVP strict.

### 14.3 Dépendances runtime

- Définir qui consomme l'event : Event lui-même, Scene consequence, ou behavior policy.
- Définir comment un outcome runtime retourne vers Event reactions.
- Définir si battle victory/defeat est lu par Scene ou Event.
- Définir comment Save/Load prouve consumed/facts/steps.

### 14.4 Dépendances UI/design system

- Surface Events dans Narrative Studio.
- Composants list/palette/flow/inspector basés design system.
- Pas de couleurs hardcodées.
- Visual gates obligatoires pour lots UI.

### 14.5 Dépendances Selbrume

- V1-138-bis doit trancher Lysa/Lyra/rival.
- V1-138-bis doit trancher Port des Brisants.
- Aucun Event Builder lot ne doit créer la donnée finale Selbrume avant ces décisions.

## 15. Décisions à prendre avant code

| Décision | Recommandation |
|---|---|
| Event doit-il toujours lancer une Scene ? | MVP : oui, action principale = Scene. V1 : actions directes bornées possibles mais secondaires. |
| Où vivent les outcomes ? | La Scene émet l'outcome ; l'Event peut réagir à cet outcome en V1. |
| Où vivent les conséquences ? | Conséquences simples authorables côté Event, écrites via writer runtime contrôlé. |
| Event consomme-t-il lui-même ? | Oui via behavior `Une seule fois`, mais implémenté comme consequence/policy explicite. |
| Qu'est-ce qui est persisté dans GameState ? | consumedEventIds, facts/story flags, step completion selon modèles existants. |
| Frontière Event Builder / Scene Builder ? | Event déclenche et persiste ; Scene orchestre dialogue/cinematic/battle. |
| Frontière Event Builder / World Rules ? | Event produit facts/consumed ; World Rules projettent ces facts dans la map. |
| Frontière Event Builder / Dialogue/Yarn ? | Event ne contient pas le texte ; il lance une Scene qui lance Yarn. |
| Victory/defeat sans coupler au battle ? | V1 : lire outcomes de Scene/Battle adapter ; Event ne connaît que labels d'outcome. |

## 16. Trajectoire recommandée

Je recommande de commencer par :

```text
NS-EVENT-01 — Event Builder Existing Surface / Contract Alignment Audit
```

Je déconseille de commencer par :

```text
un canvas drag/drop
une palette V1 complète
une simulation runtime UI
une intégration Selbrume finale
```

Le premier lot doit surtout éviter une erreur chère : créer un nouveau modèle Event Builder alors que `MapEventDefinition`, `SceneEventRuntimeHook`, `SceneConsequenceRuntimeWriter` et les diagnostics Event->Scene existent déjà.

Prochain lot exact recommandé :

```text
NS-EVENT-01 — Event Builder Existing Surface / Contract Alignment Audit
```

Objectif :

```text
Aligner le contrat Event Builder MVP avec les modèles/runtimes existants, décider la frontière Event/Scene/WorldRule, et figer le plan de modèle avant toute UI.
```

Critère de sortie :

```text
Un agent peut écrire NS-EVENT-02 sans deviner où stocker trigger, conditions, actions, consequences, behavior et outcomes.
```

## 17. Evidence Pack

### 17.1 Commandes exécutées

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 20
sed -n '1,260p' AGENTS.md
sed -n '1,240p' agent_rules.md
sed -n '1,260p' codex_rule.md
sed -n '1,260p' skills/README.md
sed -n '1,260p' skills/writing-plans/SKILL.md
sed -n '1,260p' skills/verification-before-completion/SKILL.md
sed -n '1,520p' skills/test-driven-development/SKILL.md
rg -n "Event Builder|Map Events View|Event =|Scene =|Validator|World Rule|Fact|Outcome|consequence|Event Source|Scene Builder" 'MVP Selbrume/narrative_studio.md' 'MVP Selbrume/checklist_beta_pokemap.md' 'MVP Selbrume/selbrume.md' 'MVP Selbrume/road_map_phase_1.md' 'MVP Selbrume/road_map_phase_7.md'
rg -n "class MapEventDefinition|class MapEvent|MapEventSceneTarget|MapEventTrigger|MapEventCondition|MapEventPage|event.*consum|consumed" packages/map_core/lib packages/map_editor/lib packages/map_runtime/lib packages/map_gameplay/lib
rg -n "Event Builder|event builder|event-scene-target|Scene V1|Lien authoring|MapEvent|event properties|EventProperties|event source|source.*event" packages/map_editor/lib packages/map_editor/test reports/narrativeStudio reports/gameplay
sed -n '1,240p' packages/map_core/lib/src/models/map_event_definition.dart
sed -n '1,320p' packages/map_core/lib/src/operations/map_events.dart
sed -n '1020,1150p' packages/map_editor/lib/src/ui/panels/event_properties_panel.dart
sed -n '1560,1590p' packages/map_editor/lib/src/ui/panels/event_properties_panel.dart
sed -n '1,260p' packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart
rg --files packages | rg -i "event.*test|scene_event|event_scene|scenario_runtime|world_rule|narrative_validator|beta_playability|facts_world|event_properties"
sed -n '1,300p' packages/map_core/lib/src/diagnostics/event_scene_link_diagnostics.dart
sed -n '1,180p' packages/map_runtime/test/scene_event_runtime_hook_test.dart
sed -n '1,120p' packages/map_editor/test/event_properties_panel_scene_target_test.dart
find reports/narrativeStudio -maxdepth 2 -type d | sort
sed -n '330,380p' 'MVP Selbrume/narrative_studio.md'
sed -n '1200,1300p' 'MVP Selbrume/narrative_studio.md'
sed -n '1330,1360p' 'MVP Selbrume/narrative_studio.md'
sed -n '40,65p' 'MVP Selbrume/checklist_beta_pokemap.md'
sed -n '145,180p' 'MVP Selbrume/checklist_beta_pokemap.md'
```

### 17.2 Sorties utiles exactes

Image ouverte :

```text
/Users/karim/Desktop/assets/pokeMap/définitive/4 - événements/1 - événements.png
```

Répertoire de sortie :

```text
reports/narrativeStudio/events
```

Preuve `EventPropertiesPanel` :

```text
event-scene-target-dropdown
Scene V1
Aucune Scene V1
Aucune Scene V1 disponible
Retirer Scene
Lien authoring uniquement, runtime Scene à venir.
JSON brut
Event consommé
```

Preuve runtime :

```text
SceneEventRuntimeHook.runForEventPage
SceneRuntimeExecutor
SceneConsequenceRuntimeWriter
SceneEventRuntimeHookResult.completed
SceneEventRuntimeHookResult.failed
```

Preuve tests :

```text
packages/map_core/test/map_events_test.dart
packages/map_core/test/event_scene_link_diagnostics_test.dart
packages/map_editor/test/event_properties_panel_scene_target_test.dart
packages/map_runtime/test/scene_event_runtime_hook_test.dart
packages/map_runtime/test/p3_event_source_bridge_validation_test.dart
packages/map_runtime/test/p3_fact_world_rule_projection_test.dart
```

### 17.3 Fichiers créés

```text
reports/narrativeStudio/events/ns_event_builder_mvp_v1_lot_plan.md
```

### 17.4 Fichiers modifiés

```text
reports/narrativeStudio/events/ns_event_builder_mvp_v1_lot_plan.md
```

### 17.5 Fichiers supprimés

```text
<aucun>
```

### 17.6 Tests et analyse

Aucun test Dart/Flutter n'a été exécuté.

Raison :

```text
Le lot est doc-only et ne modifie aucun code produit, aucun test, aucun modèle, aucune fixture et aucun runtime.
```

Validation applicable :

```text
git diff --check
```

sera exécuté en clôture.

## 18. Verdict des passes type sub-agents

| Passe | Verdict |
|---|---|
| Sub-agent Audit / Architecture | Event Builder actuel PARTIAL ; bases core/runtime existent ; éviter un second modèle. |
| Sub-agent Implémentation | Aucun code à produire ; rapport unique seulement. |
| Sub-agent Tests | Tests existants identifiés ; aucun test à lancer pour doc-only. |
| Sub-agent Build / Validation | À compléter par `git diff --check` et état Git final. |
| Sub-agent Critique finale | Le plan doit commencer par contrat/audit, pas par UI drag/drop. |

## 19. Auto-review critique

Ce que ce plan suppose :

- `MapEventDefinition` reste la base Event map ;
- l'action principale MVP est `Scene V1` ;
- Event ne remplace pas Scene ;
- outcomes complexes restent V1, pas MVP strict ;
- World Rules restent une surface séparée qui consomme facts/events/steps.

Ce qui reste incertain :

- le stockage final des conditions/consequences Event Builder ;
- la compatibilité exacte entre `SceneConsequence` et consequences Event ;
- le statut de `ScriptCondition` legacy ;
- le niveau d'exposition de `ScenarioAsset` dans les lots Event ;
- la stratégie de migration des events existants.

Ce qui peut faire exploser le nombre de lots :

- vouloir le drag/drop dès le début ;
- vouloir victory/defeat/rewards avant le runtime smoke ;
- vouloir un Preview/Test complet avant les diagnostics ;
- mélanger Event Builder et Scene Builder ;
- écrire Selbrume final pendant que les IDs ne sont pas confirmés.

Ce qui peut réduire le nombre de lots :

- réutiliser strictement `MapEventSceneTarget` et `SceneEventRuntimeHook` ;
- limiter le MVP à un seul action type `Jouer une Scene` ;
- repousser drag/drop et outcomes à V1 ;
- garder les world changes comme facts/world rules simples.

Points à confirmer par Karim avant implémentation :

1. Le MVP Event lance-t-il toujours une Scene, ou faut-il une action directe Dialogue/Battle dès le MVP ?
2. Les réactions victory/defeat sont-elles obligatoires en MVP ou acceptées en V1 ?
3. Le drag/drop est-il obligatoire ou le clic-to-add suffit-il pour V1 initiale ?
4. L'Event doit-il porter les récompenses argent/objet, ou ces récompenses doivent-elles rester dans Battle/Scene pour commencer ?
5. L'Event Builder doit-il vivre dans Narrative Studio uniquement, ou aussi remplacer progressivement l'ancien Map Event inspector ?

Critique du prompt :

- Le prompt est bon comme cadrage de roadmap, mais l'UI cible est une V1, pas un MVP.
- Le prompt mélange volontairement Event, Battle, Facts, World Rules et Validator ; le plan doit les séparer en lots.
- L'image montre des blocs `Donner argent` et `Donner objet`, mais ces actions touchent gameplay/bag/economy et ne doivent pas entrer dans le MVP sans contrat mécanique.
- Le plan ne doit pas promettre une V1 proche de l'image en moins de 18 lots ; ce serait une estimation optimiste non fiable.

## 20. Limites de l'audit

- L'application n'a pas été lancée.
- Aucun test widget ou runtime n'a été relancé.
- L'analyse se fonde sur fichiers, rapports, image fournie et symboles existants.
- Les coûts de lots supposent la méthode habituelle : tests, evidence packs, visual gates pour UI, bis possibles.

## 21. État Git final et validation

Commandes finales exécutées :

```bash
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Sortie exacte de `git status --short --untracked-files=all` :

```text
?? reports/narrativeStudio/events/ns_event_builder_mvp_v1_lot_plan.md
```

Sortie exacte de `git diff --stat` :

```text
<vide>
```

Sortie exacte de `git diff --name-only` :

```text
<vide>
```

Sortie exacte de `git diff --check` :

```text
<vide>
```

Verdict validation :

```text
NS-EVENT-PLAN-001 : DONE documentaire.
Seul le rapport demandé a été créé.
Aucun code produit modifié.
Aucun test produit modifié.
Aucune roadmap modifiée.
Aucune donnée Selbrume modifiée.
```
