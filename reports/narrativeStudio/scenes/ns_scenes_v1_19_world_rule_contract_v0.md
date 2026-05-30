# NS-SCENES-V1-19 — World Rule Contract V0

## Resume executif

Le lot `NS-SCENES-V1-19 — World Rule Contract V0` est realise en documentation-only.

Decision principale : une World Rule PokeMap doit devenir une regle authoring explicite, inspectable et validable, qui projette un changement visible ou actif du monde a partir de sources lisibles. Elle ne doit pas etre un script cache, une action one-shot de scene, ni une condition dissimulee dans un PNJ.

Le contrat recommande pour V0 :

- stockage futur au niveau projet, avec cible explicite map/entity/event/dialogue ;
- affichage contextuel aussi depuis la map et les entites ciblees ;
- sources V0 autorisees : Fact Registry fact, StoryStep completed/notCompleted, consumed event ;
- effets V0 prioritaires : presence/visibilite d'entite, dialogue conditionnel, disponibilite simple d'event ;
- effets repousses : collision dynamique, warp dynamique, ambience/map state global, rules derivees d'autres World Rules ;
- runtime futur par projection/resolution, sans mutation destructive des donnees de map.

Prochain lot exact recommande : `NS-SCENES-V1-20 — World Rules V0`.

## Raison du lot

V1-18 a ajoute une Fact Registry bool-first dans `ProjectManifest.facts`. Les conditions peuvent maintenant lire des sources metier lisibles, mais le systeme ne decrit pas encore comment un fait ou une step transforme le monde visible.

Sans contrat World Rule, PokeMap risquerait de repartir vers trois impasses :

- exposer des flags techniques dans l'UX ;
- cacher des conditions dans les payloads de PNJ ;
- encoder des changements de monde comme actions de Scene opaques.

Ce lot pose donc la frontiere :

- une condition lit ;
- une action ecrit ou produit une consequence ;
- une World Rule projette un changement visible/actif selon l'etat courant.

## Etat actuel du repo

Briques existantes utiles :

- `ProjectManifest.facts` stocke deja des Facts authoring bool-first via `NarrativeFactDefinition`.
- `GameState` stocke `storyFlags`, `progression.completedStepIds`, `progression.completedCutsceneIds`, `consumedEventIds`, `bag`, `party` et `scriptVariables`.
- `ScriptCondition` et `ScriptConditionEvaluator` savent lire flags, variables, party moves, event consumed, current map et field abilities.
- `MapEntityRuntimePredicate` sait lire `storyFlagSet/Unset`, `stepCompleted/NotCompleted`, `chapterCompleted/NotCompleted`, `cutsceneCompleted/NotCompleted`.
- `MapEntityNpcVisibilityRule` peut rendre un PNJ visible/masque selon un predicate.
- `MapEntityConditionalDialogue` choisit un dialogue selon un predicate.
- `MapEntityRuntimePredicateEvaluator` applique les predicates de presence et de dialogue sans mutation de GameState.
- `StepStudioWorldPresenceRule` lit des `worldChanges` legacy dans les metadata Step Studio et projette la presence de PNJ selon une step completee.
- `GameplayWorldState` accepte un `NpcMapPresencePredicate`, ce qui prouve que la presence PNJ peut influencer collision/interactions sans connaitre les flags dans `map_gameplay`.
- Le validator narratif connait deja des diagnostics autour des predicates de visibilite, dont `visibilityRuleConditionalMissingPredicate` et `worldRulePredicateEmptyRefId`.

Manques principaux :

- aucun modele canonique `WorldRule` n'existe ;
- aucune registry `ProjectManifest.worldRules` n'existe ;
- les rules existantes sont locales aux entites ou legacy Step Studio ;
- les effets collision/warp/map state ne sont pas formalises comme projections authoring ;
- les diagnostics World Rule ne couvrent pas encore sources inconnues, targets inconnues, conflits ou cycles.

Fichiers obligatoires absents : aucun.

## Definition produit

### World Rule

Une World Rule est une regle authoring declarative qui dit :

```text
Quand une source lisible vaut vrai,
appliquer un effet visible ou actif
sur une cible explicite du monde.
```

Elle doit etre inspectable depuis Narrative Studio et depuis le contexte map/entity lorsque c'est pertinent.

Elle n'est pas :

- un script arbitraire ;
- une action one-shot de Scene ;
- une condition cachee dans un PNJ ;
- un flag technique expose comme experience principale ;
- une mutation runtime irreversible des donnees authoring.

### World Rule Source

Source lisible qui pilote la regle. V0 recommande :

- Fact Registry fact ;
- StoryStep completed/notCompleted ;
- consumed event.

Sources futures :

- inventory/item ;
- party state ;
- trainer/battle outcome dedie ;
- dialogue outcome persistant ;
- variables typees authoring ;
- field ability ;
- map/player context.

### World Rule Target

Cible stable et explicite du monde. V0 recommande :

- map entity ;
- NPC dialogue assignment ;
- map event.

Cibles futures :

- door/collision proxy ;
- warp ;
- placed element ;
- environment/map ambience ;
- path/blocker state ;
- quest availability.

### World Rule Effect

Effet declaratif applique a la cible. V0 recommande :

- show/hide entity, ou visibleWhen/hiddenWhen ;
- override/select dialogue for NPC ;
- enable/disable event or event page when model support is explicit.

Effets repousses :

- mutation directe de collision layer ;
- activation/desactivation de warp ;
- deplacement d'entite ;
- changement de tiles/ambiance ;
- effets composites multi-target dans une seule rule.

### World Rule Priority

V0 doit eviter autant que possible les conflits par design. Quand plusieurs rules ciblent le meme target/effect, il faut une priorite explicite ou une erreur diagnostic.

Decision : V0 doit commencer avec une priorite numerique stable optionnelle ou un ordre declare. Si aucune priorite n'est definie et que deux rules affectent la meme cible/effect, le validator doit emettre un conflit.

### World Rule Diagnostic

Un diagnostic World Rule signale les sources, cibles, effets ou conflits invalides. Une World Rule invalide ne doit pas etre appliquee silencieusement par le runtime futur.

## Sources V0 analysees

| Source | Maturite actuelle | Picker requis | Reutilisable depuis Condition Source | V0 | Decision |
|---|---|---|---|---|---|
| Fact Registry fact | Mature authoring depuis V1-18, runtime mapping encore futur | Fact picker existant/futur | Oui | Oui | Source prioritaire V0. C'est le langage produit attendu pour les changements persistants. |
| StoryStep completed/notCompleted | Mature pour completed via `PlayerProgression.completedStepIds` | Storyline/Chapter/Step picker | Oui | Oui | Autorise pour progression narrative, sans brancher `sceneLinkIds`. |
| Consumed event | Mature dans `GameState.consumedEventIds` et `ScriptCondition.eventIsConsumed` | Map/Event picker | Oui | Oui limite | Utile pour etats locaux ; ne doit pas remplacer un Fact global. |
| Condition source reutilisable | Concept mature depuis V1-16/V1-17 | Selon source | Oui | Oui limite | V1-20 peut reutiliser le vocabulaire de ConditionSource, mais pas d'expression arbitraire. |
| ScriptCondition legacy | Backend mature | Non en UX directe | Non comme UX | Non | Autorise comme inspiration/backend, pas comme modele produit World Rule. |
| Inventory/item | State existe via `Bag` | Item picker | Future | Non | Reporter jusqu'au picker item et semantique quantite. |
| Party state | State existe via `PlayerParty` | Pokemon/move picker | Future | Non | Reporter jusqu'au picker party/move. |
| Dialogue/Battle outcome local | Partiel/legacy | Outcome picker/runtime plan | Future | Non | Outcome local non persistant ; doit passer par Scene edges/actions avant de devenir source. |
| World state derive | Non canonique | WorldRule picker | Non | Non | Eviter cycles et rules qui lisent leurs propres projections. |

Decision : V1-20 doit commencer avec `fact`, `storyStepCompletion` et `consumedEvent`, plus une forme atomique proche de `SceneConditionSource` si elle reste strictement bornee. `ScriptCondition` ne doit pas etre expose comme editeur de rules.

## Effets V0 analyses

| Effet | Existant technique | Maturite | V0 | Decision |
|---|---|---|---|---|
| Entity presence / visibility | `MapEntityNpcVisibilityRule`, `MapEntityRuntimePredicateEvaluator`, `NpcMapPresencePredicate` | Mature pour PNJ | Oui | Effet V0 prioritaire. Cible explicite : mapId + entityId. |
| NPC conditional dialogue | `MapEntityConditionalDialogue`, `resolveNpcDialogue` | Mature pour PNJ | Oui | Effet V0 prioritaire, avec dialogue picker obligatoire. |
| Event availability | `MapEventPage.isDisabled`, `isHidden`, `EventPageResolver` | Modele existe, integration a cadrer | Oui limite | Autoriser seulement si target event/page clair et validation possible. |
| Door open/closed | Peut etre represente par event/entity proxy, gate readiness tests | Partiel | Candidate limite | V0 via entity/event proxy seulement ; collision/warp dynamique repousses. |
| Collision enabled/disabled | Collision caches existent, pas de rule model | Risque eleve | Non | Reporter pour eviter mutation invisible de collision. |
| Warp enabled/disabled | `MapWarp` existe, pas de condition d'activation | Insuffisant | Non | Reporter jusqu'a un contrat warp availability. |
| Entity position/movement | Movement config existe | Insuffisant | Non | Reporter ; trop proche d'un script/cache mutable. |
| Map ambience/state | Pas de modele canonique | Insuffisant | Non | Reporter jusqu'a map state contract. |
| Dialogue assignment for non-NPC | Sign/dialogue refs existent | Partiel | Non V0 | Commencer par NPC. Etendre apres preuve. |

Decision : V1-20 doit implementer un noyau utile et petit : entity visibility/presence + NPC dialogue override + event availability si le contrat d'event target reste simple. Les collisions, warps et ambience attendront.

## Options de stockage comparees

### Option A — World Rules cachees dans les entites/maps

Principe : continuer a stocker les conditions directement dans `MapEntityNpcVisibilityRule`, `MapEntityConditionalDialogue` et `MapEventPage`.

Avantages :

- peu de schema nouveau ;
- runtime deja partiellement pret ;
- compatibilite avec l'existant.

Risques :

- rules difficiles a trouver depuis Narrative Studio ;
- duplication source/target/effect ;
- pas de vue globale des consequences ;
- l'UX redevient un editeur de payloads locaux.

Verdict : rejetee comme stockage canonique, mais utile comme backend de compatibilite/migration manuelle future.

### Option B — World Rules globales projet uniquement

Principe : stocker toutes les World Rules dans une future registry projet.

Avantages :

- inspectable et validable globalement ;
- bon alignement avec Facts et Scene Builder ;
- facilite validator et golden slice.

Risques :

- risque de couper la regle de son contexte map/entity ;
- authoring Map Editor moins naturel ;
- besoin de pickers targets solides.

Verdict : acceptable techniquement, mais trop abstrait seul.

### Option C — Registry projet canonique + projection contextuelle map/entity

Principe : les World Rules vivent dans une future registry projet, mais chaque rule cible explicitement un objet de monde et apparait aussi dans l'UI contextuelle de cette cible.

Avantages :

- vue globale dans Narrative Studio ;
- contexte naturel depuis Map Editor/entity inspector ;
- validator centralise ;
- runtime peut projeter par map/target sans transformer les maps en scripts caches.

Risques :

- necessite un modele de target propre ;
- demande une synchronisation UI entre vue globale et vue contextuelle.

Verdict : option retenue.

## Decision recommandee

Retenir Option C :

```text
WorldRule V0 = registry projet canonique
+ target explicite
+ affichage contextuel dans Map Editor
+ projection runtime future non destructive
```

Un futur modele pourrait porter conceptuellement :

```text
id
label
description
enabled
source
target
effect
priority
tags
metadata/debug
```

Mais V1-19 ne cree aucun modele Dart.

## Relation Scene / Fact / WorldRule

Contrat retenu :

- Scene orchestre une situation.
- Dialogue/Cinematic/Battle produisent des outcomes locaux.
- Action ou consequence persistante transforme un outcome local en Fact, Step completed ou event consumed.
- Fact est un etat persistant lisible.
- World Rule lit Facts/Steps/events et projette le monde visible/actif.

Un `SceneOutcome` ne devient pas automatiquement un Fact. Une World Rule ne doit pas ecrire un Fact. Une World Rule ne complete pas une StoryStep. Une action ecrit ; une World Rule projette.

## Strategie runtime future

Runtime futur recommande :

1. charger les maps et le manifest authoring ;
2. construire un index de World Rules valides par map/target ;
3. a chaque resolution de map/entity/event/dialogue, evaluer les sources contre `GameState` ;
4. retourner une vue effective du monde ;
5. ne jamais muter destructivement `MapData` ou `ProjectManifest` ;
6. invalider/recalculer apres mutations de `GameState` pertinentes : setFact, clearFact, completeStep, consumeEvent.

Le pattern existant `MapEntityRuntimePredicateEvaluator` + `NpcMapPresencePredicate` est une bonne inspiration. Le module Step Studio `StepStudioWorldPresenceRule` prouve le besoin, mais ne doit pas rester le modele produit final.

## Diagnostics recommandes

| Code conceptuel | Severity | Quand | Bloque runtime futur |
|---|---|---|---|
| `worldRuleSourceMissing` | error | source absente ou vide | Oui |
| `worldRuleSourceUnknown` | error | Fact/Step/Event reference introuvable | Oui |
| `worldRuleSourceUnsupported` | error | source future ou legacy brute non autorisee | Oui |
| `worldRuleTargetMissing` | error | target absent ou incomplet | Oui |
| `worldRuleTargetUnknown` | error | map/entity/event/dialogue introuvable | Oui |
| `worldRuleEffectMissing` | error | effect absent | Oui |
| `worldRuleEffectUnsupported` | error | effect non supporte V0 | Oui |
| `worldRuleEffectTargetMismatch` | error | effect incompatible avec target | Oui |
| `worldRuleConflict` | warning/error | plusieurs rules modifient le meme target/effect sans priorite claire | Oui si ambigu |
| `worldRuleCycle` | error | source depend d'un world state derive d'une World Rule | Oui |
| `worldRuleUsesRawTechnicalId` | warning | label utilisateur absent ou identique a l'id technique | Non |
| `worldRuleLegacyPredicateLeak` | warning | rule expose directement `ScriptCondition` ou flag legacy | Non en authoring, oui si runtime strict |

## UX future recommandee

V1-20/V1-21 UX cible :

- Narrative Studio : module "World Rules" avec liste globale, filtres par source, target, map et severity.
- Map Editor : panneau contextuel "Rules affectant cette entite/event".
- Fact Registry : section "utilise par X World Rules".
- Scene Builder : affichage non intrusif des actions/facts qui declenchent des World Rules futures.
- Validator : vue globale des conflicts et refs inconnues.

Workflow no-code attendu :

```text
Quand [Fact: Rival battu au port] est vrai
alors [PNJ: Lysa] utilise [Dialogue: apres combat]
```

Le createur doit choisir des labels/pickers, pas taper `storyFlagSet: rival_port_defeated`.

## Impact Selbrume

Le golden slice Selbrume demande au moins ces cas conceptuels :

- une victoire de combat pose un Fact persistant ;
- un PNJ change de dialogue selon ce Fact ;
- une porte ou un passage devient disponible ;
- des habitants redeviennent visibles ;
- une quete annexe devient disponible.

Avec le contrat V1-19 :

- changement de dialogue PNJ : V0 prioritaire ;
- presence/visibilite de PNJ : V0 prioritaire ;
- porte/passage : V0 seulement si represente comme event/entity proxy ; collision/warp dynamique repousses ;
- quete annexe : future Story/Quest contract, pas World Rule V0 pur ;
- ambiance de map : repoussee.

Conclusion : V1-20 peut debloquer une grande partie des consequences visibles du golden slice, mais ne doit pas promettre toutes les transformations de map.

## Roadmap mise a jour

Decision roadmap :

- `NS-SCENES-V1-19 — World Rule Contract V0` est DONE.
- `NS-SCENES-V1-20 — World Rules V0` devient le prochain lot exact.
- V1-20 doit coder petit : modele/authoring/validation de World Rules V0 selon ce contrat, avec effets limites.
- Scene Runtime Plan reste apres World Rules V0, afin de ne pas executer des scenes avant que les consequences visibles soient cadrables.

## Prochain lot exact

`NS-SCENES-V1-20 — World Rules V0`

Objectif recommande :

```text
Ajouter un premier modele/authoring/validation de World Rules V0 :
- sources Fact / Step completed / consumed event ;
- targets map entity + NPC dialogue + event simple ;
- effects visibility/presence, dialogue override, event availability limite ;
- diagnostics refs inconnues/conflits ;
- aucune execution Scene runtime.
```

## Fichiers crees/modifies

Fichiers crees :

- `reports/narrativeStudio/scenes/ns_scenes_v1_19_world_rule_contract_v0.md`

Fichiers modifies :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Tests / analyze

Lot documentation-only :

- Dart analyze non requis.
- Flutter analyze non requis.
- Dart test non requis.
- Flutter test non requis.
- Verification requise : `git diff --check`.

## Git status initial

Commande :

```bash
pwd
```

Sortie :

```text
/Users/karim/Project/pokemonProject
```

Commande :

```bash
git branch --show-current
```

Sortie :

```text
main
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie : <vide>

Commande :

```bash
git diff --stat
```

Sortie : <vide>

Commande :

```bash
git log --oneline -n 10
```

Sortie :

```text
1d5738d9 feat(scenes): add narrative fact registry and integrate into scene authoring
0d8f2b7c feat(scenes): implement scene condition authoring v0 and update workspace tests
8932f26b docs(scenes): add condition sources contract v0 and update roadmaps
385c2da3 docs(scenes): add prep condition sources roadmap review and roadmap updates
92d43017 chore(selbrume): update project.json configuration
eb2037bf feat(scenes): add wire anchor color coding and update screenshots
b98b4424 feat(scenes): add edge selection and deletion UX v0 with updated tests
a604c2c4 feat(scenes): add visual port connection UX v0 and update tests
82b0d2bc feat(scenes): add blueprint graph canvas foundation and update tests
1c5ee72d feat(scenes): implement edge authoring v0 and update tests
```

## Evidence Pack

### Liste des fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `/Users/karim/.codex/skills/.system/superpowers/brainstorming/SKILL.md`
- `/Users/karim/.codex/attachments/3eb078a7-9883-4882-a70d-e5ebc512cf5e/pasted-text.txt`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_16_condition_sources_contract_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_17_condition_authoring_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_18_fact_registry_v0.md`
- `MVP Selbrume/narrative_studio.md`
- `MVP Selbrume/selbrume.md`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/narrative_fact.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/storyline_asset.dart`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_core/lib/src/models/script_conditions.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/lib/src/authoring/narrative_predicate_authoring_draft.dart`
- `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart`
- `packages/map_core/test/narrative_validator_test.dart`
- `packages/map_core/test/narrative_validator_authoring_adapter_test.dart`
- `packages/map_core/test/map_entity_runtime_rules_serialization_test.dart`
- `packages/map_core/test/narrative_authoring_golden_path_test.dart`
- `packages/map_gameplay/lib/src/script_condition_evaluator.dart`
- `packages/map_gameplay/lib/src/event_page_resolver.dart`
- `packages/map_gameplay/lib/src/gameplay_world_state.dart`
- `packages/map_gameplay/test/npc_map_presence_predicate_test.dart`
- `packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart`
- `packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart`
- `packages/map_runtime/test/p3_fact_world_rule_projection_test.dart`
- `packages/map_runtime/test/key_item_door_gate_readiness_test.dart`
- `packages/map_runtime/test/world_rules_conditional_presence_readiness_test.dart`
- `packages/map_runtime/test/step_studio_world_presence_runtime_test.dart`
- `packages/map_editor/lib/src/features/map_entities/application/npc_runtime_rules_editor_mapping.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart`

### Contenu complet du rapport cree

Ce document constitue le contenu complet du rapport cree pour `NS-SCENES-V1-19 — World Rule Contract V0`.

### Git status final exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_19_world_rule_contract_v0.md
```

### Git diff --stat final

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../scenes/road_map_scene_builder_authoring.md     | 23 +++++++++++---
 reports/narrativeStudio/scenes/road_map_scenes.md  | 37 +++++++++++++++++++---
 2 files changed, 52 insertions(+), 8 deletions(-)
```

Note : `git diff --stat` ne liste pas le rapport cree non suivi ; il est visible dans `git status --short --untracked-files=all`.

### Git diff --name-only final

Commande :

```bash
git diff --name-only
```

Sortie :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

### Git diff --check final

Commande :

```bash
git diff --check
```

Sortie : <vide>

### Diff complet de road_map_scenes.md

Commande :

```bash
git diff -- reports/narrativeStudio/scenes/road_map_scenes.md
```

Sortie :

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index b807e8a5..89bd82e3 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -58,8 +58,8 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-16 — Condition Sources Contract V0 | DONE | Contrat no-code des sources de condition : sources V0 autorisees, sources reportees, mapping technique, operateurs, pickers et diagnostics, sans code ni UI. |
 | NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only) | DONE | `ConditionNode` configurable avec source structuree V0 depuis refs existantes : fact-like story flag, story step completion et event consumed, sans texte magique ni fake ref. |
 | NS-SCENES-V1-18 — Fact Registry V0 | DONE | Registry authoring de Facts lisibles bool-first dans `ProjectManifest.facts`, operations pures, JSON, diagnostics refs inconnues et picker Condition prioritaire. |
-| NS-SCENES-V1-19 — World Rule Contract V0 | TODO | Formaliser les World Rules comme regles visibles derivees de Facts/Steps/conditions, sans encore brancher tout le runtime. |
-| NS-SCENES-V1-20 — World Rules V0 | TODO | Premier authoring/validation de World Rules controlees : visibilite, dialogue, portes/collisions ou map state selon contrat. |
+| NS-SCENES-V1-19 — World Rule Contract V0 | DONE | Contrat produit/technique des World Rules V0 : registry projet future avec targets explicites, sources Fact/Step/Event, effets V0 limites et diagnostics requis. |
+| NS-SCENES-V1-20 — World Rules V0 | TODO | Premier modele/authoring/validation de World Rules controlees : entity visibility/presence, NPC dialogue override et event availability limite selon contrat V1-19. |
 | NS-SCENES-V1-21 — Scene Runtime Plan V0 | TODO | Ajouter un modele pur `SceneRuntimePlan` / intents dans `map_core`, compiler `SceneAsset` valide en plan executable sans layout ni Flutter. |
 | NS-SCENES-V1-22 — Payload Pickers V0 | TODO | Ajouter les pickers Yarn, cinematic, battle/action refs et limiter les IDs libres. |
 | NS-SCENES-V1-23 — Diagnostics Expansion | TODO | Etendre diagnostics aux refs, ports, outcomes non geres, unreachable/cycles et payloads incomplets. |
@@ -70,9 +70,38 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr

 ## Prochain lot recommande

-`NS-SCENES-V1-19 — World Rule Contract V0`
+`NS-SCENES-V1-20 — World Rules V0`

-Raison : V1-18 donne aux conditions une source Fact lisible, bool-first, sans exposer les flags techniques comme experience principale. Le prochain bloc doit cadrer les World Rules avant d'ajouter leurs modeles/UI, afin de decrire proprement les changements visibles du monde derives des Facts/Steps/conditions.
+Raison : V1-19 a cadre les World Rules sans code. Le prochain bloc peut maintenant implementer un premier modele/authoring/validation controle, en gardant les effets V0 petits et inspectables : presence/visibilite d'entite, dialogue PNJ conditionnel et disponibilite simple d'event.
+
+## Decisions V1-19
+
+- Lot documentation-only : aucun code, widget, modele Dart, runtime, test ou fixture n'est modifie.
+- Une World Rule est une regle authoring declarative, inspectable et validable qui projette un changement visible ou actif du monde depuis une source lisible.
+- Une World Rule n'est pas un script cache, une action one-shot, une condition dissimulee dans un PNJ ou un flag technique expose comme UX principale.
+- Stockage futur recommande : registry projet canonique, avec targets explicites et affichage contextuel depuis Map Editor/entity inspector.
+- Sources V0 recommandees : Fact Registry fact, StoryStep completed/notCompleted, consumed event ; `ScriptCondition` reste backend/legacy, pas surface produit.
+- Effets V0 prioritaires : presence/visibilite d'entite, dialogue conditionnel PNJ, disponibilite simple d'event si la cible est validee.
+- Effets repousses : collision dynamique, warp dynamique, deplacement d'entite, ambience/map state global et World Rule source derivee d'une autre World Rule.
+- Runtime futur recommande : projection/resolution non destructive depuis `GameState`, sans muter `MapData` ou `ProjectManifest`.
+- Diagnostics requis : source/target/effect manquants ou inconnus, mismatch target/effect, conflits de priorite, cycles et fuite d'IDs techniques.
+- Prochain lot exact : `NS-SCENES-V1-20 — World Rules V0`.
+
+## Limites V1-19
+
+- Aucun modele `WorldRule` n'est cree.
+- Aucun champ `ProjectManifest.worldRules` n'est ajoute.
+- Aucun runtime, gameplay, editor widget ou payload Scene n'est modifie.
+- Les portes/collisions/warps restent conceptuellement analyses mais non autorises comme effet V0 direct.
+- Aucune donnee Selbrume n'est creee.
+
+## Tests V1-19
+
+- Dart analyze non requis : lot documentation-only.
+- Flutter analyze non requis : lot documentation-only.
+- Dart test non requis : lot documentation-only.
+- Flutter test non requis : lot documentation-only.
+- Verification requise : `git diff --check`.

 ## Decisions V1-18
```

### Diff complet de road_map_scene_builder_authoring.md

Commande :

```bash
git diff -- reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Sortie :

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index 549640e5..1d771284 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande

 ```text
-NS-SCENES-V1-19 — World Rule Contract V0
+NS-SCENES-V1-20 — World Rules V0
 ```

 ## Principes
@@ -37,8 +37,8 @@ NS-SCENES-V1-19 — World Rule Contract V0
 | NS-SCENES-V1-16 | Condition Sources Contract V0 | doc / core-design | Definir les sources conditionnelles no-code, leur maturite, mapping technique, pickers, diagnostics et limite runtime. | Pas de Condition UI complete, pas de Fact Registry codee, pas de World Rule runtime. | rapport V1-16, roadmaps. | `git diff --check` uniquement. | Sur-documenter ; ou exposer `ScriptCondition` brut comme UX. | DONE : sources V0 autorisees/reportees, contrat conceptuel, operateurs, diagnostics et pickers definis. | V1-16-prep. |
 | NS-SCENES-V1-17 | Condition Authoring V0 (Existing Sources Only) | core / editor | Configurer un `ConditionNode` V0 avec sources existantes uniquement, sans texte magique ni fake refs. | Pas de runtime, pas d'expressions complexes, pas de sources non cadrees, pas de Yarn/Battle/Cinematic pickers. | scene authoring operations, inspector controls, diagnostics tests. | Tests payload condition, mutation ProjectManifest.scenes, diagnostics condition incomplete/valid. | Ouvrir trop tot un langage de conditions complet ; exposer flags bruts. | DONE : condition configurable via source structuree explicite, diagnostics bloquants si incomplete, picker limite aux refs existantes. | V1-16. |
 | NS-SCENES-V1-18 | Fact Registry V0 | core / editor | Ajouter une registry authoring de Facts lisibles, bool-first, avec labels, descriptions et categories pour pickers no-code. | Pas de World Rules completes, pas de runtime Scene complet, pas de types avances obligatoires. | `ProjectManifest`, operations facts, picker Condition, tests serialization/diagnostics. | DONE : tests registry JSON, operations pures, picker Fact, diagnostics refs inconnues. | Confondre Fact et StoryStep ; exposer seulement des IDs techniques. | DONE : Facts lisibles stockes dans `ProjectManifest.facts`, refs stables, picker prioritaire, fallback technique conserve. | V1-16, V1-17. |
-| NS-SCENES-V1-19 | World Rule Contract V0 | doc / core-design | Formaliser les World Rules comme regles visibles derivees de Facts/Steps/conditions. | Pas de runtime complet, pas de Map Editor lourd, pas de seed Selbrume. | rapport contractuel, event/map model audit. | `git diff --check` ou tests core si modele pur. | Faire des World Rules des scripts caches ; creer des boucles invisibles. | Types de regles, sources, effets, priorites et diagnostics de base definis. | V1-18 recommande. |
-| NS-SCENES-V1-20 | World Rules V0 | core / editor / gameplay | Premier authoring/validation de World Rules controlees : visibilite, dialogue, porte/collision ou map state selon contrat. | Pas de runtime Scene complet, pas de StorylineStep link. | map entity/world rule models si decide, editor picker, diagnostics. | Tests refs map/entity, evaluation pure, diagnostics. | Casser les predicates existants ; rendre le monde trop dynamique sans validation. | Regles visibles authorables et validables, sans flags bruts dans l'UX. | V1-19. |
+| NS-SCENES-V1-19 | World Rule Contract V0 | doc / core-design | Formaliser les World Rules comme regles visibles derivees de Facts/Steps/conditions. | Pas de modele, pas de runtime, pas de Map Editor lourd, pas de seed Selbrume. | rapport contractuel, event/map model audit. | DONE : `git diff --check`. | Faire des World Rules des scripts caches ; creer des boucles invisibles. | DONE : sources, targets, effets, stockage, priorites et diagnostics definis. | V1-18. |
+| NS-SCENES-V1-20 | World Rules V0 | core / editor / gameplay | Premier modele/authoring/validation de World Rules controlees : entity visibility/presence, NPC dialogue override et event availability limite. | Pas de runtime Scene complet, pas de StorylineStep link, pas de collision/warp dynamique direct. | map/world rule models si decide, authoring operations, editor picker, diagnostics. | Tests refs map/entity/event/dialogue, evaluation/projection pure, diagnostics conflits/refs inconnues. | Casser les predicates existants ; rendre le monde trop dynamique sans validation. | Regles visibles authorables et validables, sans flags bruts dans l'UX. | V1-19. |
 | NS-SCENES-V1-21 | Scene Runtime Plan V0 | core | Ajouter `SceneRuntimePlan`, intents, builder pur depuis `SceneAsset` valide. | Pas d'execution runtime, pas de Flutter, pas de `ScenarioAsset` auto. | `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`, tests core. | Draft minimal, yarn/battle/cinematic/action intents, diagnostics error bloque, layout ignore. | Figer trop tot un executor ; dupliquer ScenarioRuntime. | Plan pur testable, ignore layout, refuse scenes invalides. | V1-17, V1-18 utile. |
 | NS-SCENES-V1-22 | Payload Pickers V0 | editor / core | Remplacer IDs libres par pickers/drafts honnetes : Yarn, cinematic, battle, action. | Pas de full editor payload, pas de runtime. | workspace Scenes, inspector draft controls, projection refs. | Tests pickers refs reelles, refs inconnues diagnostic, boutons honnetes. | Faux contenus Selbrume, refs tapees a la main. | Node payloads configurables avec vraies refs ou drafts clairement invalides. | V1-17, V1-21 utile. |
 | NS-SCENES-V1-23 | Diagnostics Expansion | core / editor | Etendre diagnostics aux refs, ports requis, outcomes non geres, unreachable, cycles, sources conditions et facts/world rules. | Pas de correction auto, pas de Validator global complet. | `scene_diagnostics.dart`, UI diagnostics. | Tests refs inconnues, missing outputs, unreachable, cycles, severity. | Trop bloquer les drafts ; confusion warning/error. | Builder guide l'auteur sans empecher draft minimal valide. | V1-17, V1-18, V1-22. |
@@ -154,6 +154,20 @@ Limites : bool-only, pas de registry editor dediee, pas de World Rules, pas de r

 Prochain lot exact : `NS-SCENES-V1-19 — World Rule Contract V0`.

+## Mise a jour V1-19
+
+Statut : `NS-SCENES-V1-19 — World Rule Contract V0` est DONE.
+
+Decision : une World Rule V0 est une regle authoring declarative, inspectable et validable. Elle lit une source metier (`Fact`, `StoryStep completed/notCompleted`, `consumed event`) et projette un effet visible/actif sur une cible explicite du monde. Elle n'est pas un script cache, une action one-shot de Scene, une condition dissimulee dans un PNJ ou un flag technique expose comme UX principale.
+
+Stockage futur recommande : registry projet canonique avec targets explicites, plus affichage contextuel dans Map Editor/entity inspector. Les implementations existantes `MapEntityNpcVisibilityRule`, `MapEntityConditionalDialogue`, `MapEntityRuntimePredicateEvaluator`, `NpcMapPresencePredicate` et `StepStudioWorldPresenceRule` servent d'inspiration ou de bridge, pas de modele produit final.
+
+Effets V0 recommandes : presence/visibilite d'entite, dialogue conditionnel PNJ, disponibilite simple d'event si les refs sont validables. Les collisions dynamiques, warps dynamiques, deplacements d'entites et ambiances/map state sont repousses.
+
+Limites : aucun code, aucun widget, aucun modele Dart, aucun runtime et aucune donnee Selbrume ne sont ajoutes.
+
+Prochain lot exact : `NS-SCENES-V1-20 — World Rules V0`.
+
 ## Selbrume golden slice

 Avant le golden slice, il faut au minimum :
@@ -163,6 +177,7 @@ Avant le golden slice, il faut au minimum :
 - Visual Port Connection UX V0 pour rendre la construction de graph utilisable sans ambiguite.
 - Payload Pickers V0 pour Yarn, battle, cinematic/action.
 - Diagnostics Expansion.
+- World Rules V0 pour les consequences visibles controlees.
 - Scene Runtime Plan V0.
 - Event to Scene Trigger Prep.
 - Scene Runtime Executor MVP.
@@ -170,6 +185,6 @@ Avant le golden slice, il faut au minimum :
 Peut attendre apres le slice :

 - StorylineStep -> Scene Link complet.
-- World Rule editor complet.
+- World Rule editor avance au-dela des effets V0.
 - Fact registry avance.
 - Cinematic editor avance si une cinematic fixture controlee suffit.
```

## Auto-review critique

- Le contrat reste volontairement strict : il evite collision/warp/ambience en V0, meme si ces effets sont tres desirables pour Selbrume.
- Le choix "registry projet + projection contextuelle" ajoute un peu de complexite UX future, mais c'est le meilleur compromis pour eviter des rules cachees.
- Le rapport s'appuie sur des briques runtime existantes lues en audit, sans les modifier.
- Aucun modele Dart n'est cree dans ce lot, donc V1-20 devra encore trancher les noms exacts de types/champs.

## Regard critique sur le prompt

Le prompt est bien cadre et empeche de coder trop tot. Son exigence d'Evidence Pack complet pour un rapport qui s'auto-reference cree une tension pratique : le contenu complet du rapport est par definition le present fichier, et les sorties finales Git peuvent changer si on les reinsere apres capture. La solution retenue est de documenter l'evidence dans le rapport et de refaire les verifications finales en fin de lot.
