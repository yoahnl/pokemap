# NS-STORYLINES-V1-00 — Storyline Semantics & Usable Authoring Contract

## 1. Executive summary

Storylines V0 est techniquement valide, mais pas encore assez utilisable comme produit auteur.

Le problème principal n'est pas la compilation, les tests ou le design system. Le problème est sémantique : les lots V0 ont laissé l'UI deviner les frontières entre Storyline, Chapter, Story Step, Scene, Event, Cutscene et Outcome.

Contrat V1 :

- Une Storyline est une ligne narrative complète ou semi-complète.
- Une Storyline contient des Chapters.
- Un Chapter organise des Story Steps et des Scenes liées.
- Une Story Step est un jalon durable de progression.
- Une Scene est une séquence orchestrée jouée par le joueur ou le runtime.
- Une Scene peut produire des inputs/outputs/outcomes qui font diverger ou converger la Storyline.
- L'onglet `Graph` explique le comportement global.
- Le deuxième onglet doit devenir `Structure`, pas `Étapes` ni `Scènes`.
- Toute UI visible en V1 doit être utilisable, informative, ou masquée.

Prochain lot recommandé : `NS-STORYLINES-V1-01 — Storyline Authoring Model Decision`.

## 2. Inputs read

Fichiers lus :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/storylines/road_map_storylines.md`
- `reports/narrativeStudio/storylines/ns_storylines_checkpoint_v0_acceptance.md`
- `reports/narrativeStudio/storylines/ns_storylines_11_interaction_wiring_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_01_read_model_data_contract_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_00_current_state_target_gap_audit.md`
- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/test/storylines_workspace_shell_test.dart`
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`

Fichiers optionnels absents :

```text
MISSING reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_creation_product_contract.md
MISSING reports/gameplay/narrative_studio_product_model_v0.md
MISSING reports/gameplay/narrative_studio_readiness_audit.md
```

## 3. Why V0 is technically valid but not product-usable enough

Storylines V0 a prouvé :

- workspace présent ;
- global stories réelles listées ;
- sélection locale fonctionnelle ;
- header / KPI / graph / inspector / chapters synchronisés ;
- actions futures non mutantes ;
- anti-fake stable ;
- design system respecté.

Mais V0 ne suffit pas comme expérience auteur :

- trop de contrôles visibles mais inutilisables ;
- plusieurs boutons `+` sans intention claire ;
- tabs `Étapes`, `Scènes`, `Statistiques`, `Tests` visibles alors que non utiles en V1 initiale ;
- sections futures trop présentes ;
- graph encore plus visuel que sémantique ;
- confusion entre progression durable et contenu joué ;
- confusion entre scene métier, cutscene, event, step et outcome.

Conclusion : V0 reste une fondation technique acceptable. V1 doit repartir d'un contrat produit explicite.

## 4. Canonical product model

Modèle canonique recommandé :

```text
Storyline
  -> Chapter
    -> Story Step
      -> linked Scene(s)
        -> Scene Input
        -> Scene Output
        -> Scene Outcome
```

Phrase canonique :

```text
Une Storyline contient des Chapters.
Un Chapter organise des Story Steps.
Des Scenes sont liées à ces Steps ou directement au Chapter.
```

Pourquoi cette phrase est préférable à "un Chapter contient seulement des Scenes" :

- elle garde la mémoire de progression durable dans `Story Step` ;
- elle garde le contenu joué/orchestré dans `Scene` ;
- elle permet d'afficher aux créateurs des scènes dans les chapitres sans confondre scène et progression ;
- elle permet au graph de représenter les branches/outcomes sans exposer tous les détails internes d'une scène.

## 5. Storyline / Chapter / Story Step / Scene boundaries

| Concept | User meaning | Owns progression? | Plays content? | Produces outcomes? | Persistent? | Notes |
|---|---|---|---|---|---|---|
| Storyline | Ligne narrative complète ou semi-complète | Yes, via chapters/steps | No | Yes, via child outcomes | Yes | Main story, side quest, tutorial, epilogue, episode. |
| Chapter | Grand moment narratif structurant | Partly | No | Indirect | Yes | Organise steps and linked scenes. |
| Story Step | Jalon durable de progression | Yes | No | Indirect | Yes | Answers: active, done, unlocked. |
| Event | Déclencheur authoré sur map ou système | No | No | No | Yes | Starts/conditions a Scene. |
| Scene | Séquence orchestrée jouée | No | Yes | Yes | Usually yes | Can include dialogue, choice, combat, cinematic, reward. |
| Scene Outcome | Résultat nommé d'une Scene | Yes, by effect | No | Yes | Yes | Drives divergence/convergence. |
| Cinematic | Mise en scène audiovisuelle | No | Yes | Possible via Scene | Asset/linked | Content inside/linked to Scene. |
| Dialogue Yarn | Dialogue scripté | No | Yes | Possible via choices | Asset/linked | Content inside/linked to Scene. |
| Fact | Vérité persistante | Yes | No | No | Yes | State used by conditions. |
| World Rule | Changement visible du monde | Yes | No | No | Yes | World behavior/visibility consequence. |
| Validator | Feedback auteur | No | No | No | No | Checks authoring coherence. |

Boundary rules :

- Story Step is not a Scene.
- Scene is not a Cutscene.
- Event is not a Scene; it triggers one.
- Dialogue and Cinematic are content that can be used inside a Scene.
- Outcome is the named result of a Scene or branch.

## 6. Scene inputs, outputs and outcomes

Scene input :

```text
Condition or trigger required to enter or branch inside a Scene.
```

Examples :

- player talks to NPC ;
- fact already exists ;
- story step active ;
- previous battle won/lost ;
- previous dialogue choice selected ;
- player owns item ;
- map event triggered.

Scene output :

```text
Effect produced by the Scene while it runs or when it completes.
```

Examples :

- fact added ;
- story step activated/completed ;
- item given ;
- battle launched ;
- world rule enabled ;
- side quest made available ;
- branch chosen.

Scene outcome :

```text
Named result that the Storyline graph can reason about.
```

Examples :

- `accepted_help`
- `refused_help`
- `rival_defeated`
- `rival_lost`
- `guardian_warned`
- `mist_source_found`

Important :

- Internal outputs can change the Scene's internal flow.
- Final Scene Outcomes can change the Storyline's next available paths.
- The graph should show major outcomes, not every internal scripting detail.

## 7. Graph tab purpose

`Graph` is the macro understanding view.

It answers :

```text
How does this story unfold?
Where does it branch?
Where does it converge?
When does a side quest become available?
Which choices, scenes or outcomes affect progression?
```

Graph should show :

| Graph element | Represents | Source data | V1 initial? | Notes |
|---|---|---|---|---|
| Storyline | Narrative lane/root | Storyline model | Yes | Main and side quest lanes. |
| Chapter | Macro story segment | Chapter model | Yes | Primary graph blocks. |
| Story Step | Progression milestone | Story Step model | Yes | Shown selectively. |
| Scene | Important playable sequence | Scene link/model | Partial | Show important scenes, not every internal node. |
| Scene Outcome | Branch/convergence result | Outcome model | Yes | Key to meaningful graph. |
| Side Quest | Optional storyline | Storyline type `sideQuest` | Yes | Not localEventFlow. |
| Availability window | When side quest can start/end | Conditions/outcomes | Yes | Attached to main story timing. |
| Convergence | Branch merge | Outcome/step relation | Yes | Explains story recovery points. |
| World change | Persistent world consequence | Fact / World Rule | Later | Avoid overloading V1 initial. |

Graph must not be a detailed Scene Builder.

## 8. Structure tab purpose

Recommended second tab name : `Structure`.

Rejected names :

- `Étapes` : too technical and confusing.
- `Scènes` : scenes are already a global module and live inside/under chapter structure.
- `Chapitres` : acceptable V0 wording, but too narrow for V1 authoring.
- `Chapitres & scènes` : accurate but less scalable.
- `Plan` : friendly, but less explicit for an authoring tool.

`Structure` should be the creation and organization tab.

It answers :

```text
What is this Storyline made of?
What chapters exist?
What steps structure each chapter?
What scenes are linked or missing?
What still needs authoring?
```

| Structure item | Created here? | Edited here? | Linked here? | Future? | Notes |
|---|---|---|---|---|---|
| Storyline | Yes | Yes | No | V1 initial | Name, description, type. |
| Chapter | Yes | Yes | No | V1 initial | Ordered under Storyline. |
| Story Step | Yes | Yes | Yes | V1 initial | Durable progression milestone. |
| Scene placeholder | Yes | Yes | Yes | V1 initial | Lets creator plan before full Scene Builder. |
| Existing Scene | No | Limited | Yes | V1 initial | Link existing content. |
| Dialogue | No | No | Yes | Later | Created in Dialogue module or Scene Builder. |
| Cinematic | No | No | Yes | Later | Linked via Scene. |
| Battle | No | No | Yes | Later | Linked via Scene outcome/content. |
| Fact | No | Limited | Yes | Later | Pickers, not raw flags. |
| World Rule | No | Limited | Yes | Later | Pickers, not raw internals. |

## 9. UI usefulness rule

V1 rule :

```text
Every visible UI element must be usable, informative, or hidden.
```

Avoid :

- decorative disabled buttons ;
- duplicate `+` buttons without clear scope ;
- visible tabs for unavailable features ;
- large "coming soon" sections ;
- fake KPIs ;
- sections that promise missing product capabilities.

## 10. Current UI element triage

| UI element | Current issue | V1 decision | Visibility | Required before activation |
|---|---|---|---|---|
| Nouvelle storyline | Visible but disabled | Render usable | Visible only when creation flow exists | Storyline model decision. |
| Button `+` in Storylines panel | Duplicates Nouvelle storyline | Merge/scope clearly | Hide or make same creation entry | Single creation contract. |
| Nouveau chapitre | Visible but disabled | Render usable in Structure | Visible after chapter creation supported | Chapter model + command. |
| Recherche | Visible but disabled | Hide until useful | Hide V1 initial unless filtering works | Search/filter implementation. |
| Valider | Visible but disabled | Keep as informative only or hide | Visible only if checker exists | Validation rules. |
| Notifications | Shell-level, not Storylines-specific | Keep app-level if real | Existing app decision | Notification source. |
| Paramètres | Shell-level, not Storylines-specific | Keep app-level if real | Existing app decision | Settings action. |
| Graph | Useful macro view | Keep | Visible | Graph read model. |
| Chapitres | Too narrow V1 label | Rename to Structure | Visible | Structure authoring model. |
| Étapes | Wrong global tab | Remove | Hidden | Steps shown inside Structure. |
| Scènes | Wrong global tab | Remove | Hidden | Scenes linked inside Structure; global module remains sidebar. |
| Statistiques | Not V1 initial | Hide | Hidden | Real metrics. |
| Tests | Wrong wording | Replace with Validation later | Hidden until usable | Validator contract. |
| KPI | Some helpful, some weak | Keep only useful KPIs | Visible only if sourced | Real counts/status. |
| Quêtes annexes à venir | Promises missing model | Replace with side quest Storylines when model exists | Hide or empty informative | Storyline type `sideQuest`. |
| Tags à venir | No data source | Hide | Hidden | Tags model. |
| World rules à venir | No binding | Hide | Hidden | World Rule relation. |
| Activité récente à venir | No source | Hide | Hidden | Activity/audit model. |

## 11. Side quest semantics

A side quest is a Storyline with type `sideQuest`.

It can have :

- its own chapters ;
- its own story steps ;
- its own scenes ;
- its own scene outcomes ;
- availability conditions ;
- optional completion ;
- consequences that affect facts, world rules or the main storyline.

It must not be inferred from `localEventFlow`.

Graph representation options :

- secondary lane attached to a main chapter ;
- optional branch block ;
- availability window ;
- side quest node group ;
- contribution line back to main outcome.

V1 initial recommendation :

```text
Show side quests as secondary lanes or optional blocks attached to availability windows.
```

## 12. Event / Scene / Map relationship

Product chain :

```text
Map Element
  -> Event
    -> Scene
      -> Scene Outcome
        -> Fact / Story Step / World Rule
          -> Storyline Graph update
```

Definitions :

- Map Element : object, NPC, zone, trigger, interactable.
- Event : authored trigger or condition on that element.
- Scene : orchestrated playable/narrative sequence.
- Scene Outcome : named result of the sequence.
- Fact : persistent truth.
- Story Step : durable progression state.
- World Rule : visible world behavior/state change.

Non-technical creator wording :

```text
Quand le joueur parle à Maël,
si l'étape "Aller au port" n'est pas terminée,
alors jouer la scène "Maël donne la mission",
puis marquer l'étape "Aller au port" comme active.
```

The UI should expose this as guided pickers and plain labels, not raw ids or flags.

## 13. V1 usable target

V1 initial mandatory :

- create a main storyline ;
- create a side quest storyline ;
- edit storyline name / description / type ;
- create a chapter ;
- create a story step ;
- create a scene placeholder ;
- link an existing scene ;
- see Structure with chapters, steps and linked scenes ;
- see Graph generated from real data ;
- see missing required pieces clearly ;
- avoid raw flag/id editing.

V1 later :

- validation tab ;
- richer side quest availability ;
- scene outcome editing ;
- fact/world rule pickers ;
- graph convergence editing ;
- chapter editorial statuses ;
- filters/search/sort.

V2 / future :

- advanced graph editing ;
- drag/drop graph layout ;
- minimap/zoom active ;
- analytics/statistics ;
- activity history ;
- complex branching diagnostics.

## 14. Open decisions

- Dedicated `StorylineAsset` vs enriched `ScenarioAsset`.
- Whether Chapter owns Story Steps directly, or only orders them.
- Whether Scene can attach directly to Chapter without Step.
- Minimum Scene placeholder shape.
- Scene Outcome schema.
- Side quest availability model.
- How main story uniqueness is enforced.
- Whether `Structure` is final tab label.
- How much validation belongs inside Storylines vs global Validator.

## 15. Recommended next lots

- `NS-STORYLINES-V1-01 — Storyline Authoring Model Decision`
- `NS-STORYLINES-V1-02 — Create Main Storyline Flow`
- `NS-STORYLINES-V1-03 — Create Side Quest Storyline Flow`
- `NS-STORYLINES-V1-04 — Storyline Type / Status / Validation`
- `NS-STORYLINES-V1-05 — Side Quest Graph Integration`
- `NS-STORYLINES-V1-06 — V1 Visual Graph Enrichment`

Do not start V1-01 inside this lot.

## 16. Roadmap update

Roadmap updated :

- V0 remains `ACCEPTED WITH V1 LIMITATIONS`.
- `NS-STORYLINES-V1-00` added/marked DONE.
- `NS-STORYLINES-V1-00` renamed from creation contract to semantics reset / usable authoring contract.
- Current lot is `NS-STORYLINES-V1-00`.
- Current lot status is DONE.
- Next recommended lot is `NS-STORYLINES-V1-01 — Storyline Authoring Model Decision`.
- Changelog entry added.

## 17. Commands run

Initial Git :

```text
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Read/audit :

```text
wc -l [required files]
rg -n "Roadmap status:|Current lot:|Current lot status:|Next recommended lot:|NS-STORYLINES-V1|V1 Creation|Storyline Creation Product Contract|CHECKPOINT" reports/narrativeStudio/storylines/road_map_storylines.md
rg -n "class ScenarioAsset|enum ScenarioScope|class ProjectManifest|scenarios|metadata" packages/map_core/lib/src/models/scenario_asset.dart packages/map_core/lib/src/models/project_manifest.dart packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
rg -n "Graph|Chapitres|Étapes|Scènes|Statistiques|Tests|Nouveau chapitre|Nouvelle storyline|Quêtes annexes|Tags|World Rules|Activité" packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_shell_test.dart
```

Final Git :

```text
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Tests / analyze :

```text
Not run. Documentation-only lot. No Dart code or test modified.
```

## 18. Evidence Pack

Git branch initiale :

```text
main
```

Git status initial exact :

```text
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? reports/narrativeStudio/storylines/ns_storylines_checkpoint_v0_acceptance.md
```

Git diff --stat initial :

```text
 .../storylines/road_map_storylines.md              | 36 ++++++++++++++--------
 1 file changed, 23 insertions(+), 13 deletions(-)
```

Git diff --name-only initial :

```text
reports/narrativeStudio/storylines/road_map_storylines.md
```

Git diff --check initial :

```text
Sortie : <vide>
```

Liste des fichiers lus : voir section 2.

Liste des fichiers absents mais attendus :

```text
MISSING reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_creation_product_contract.md
MISSING reports/gameplay/narrative_studio_product_model_v0.md
MISSING reports/gameplay/narrative_studio_readiness_audit.md
```

Git status final exact :

```text
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_semantics_and_usable_authoring_contract.md
```

Git diff --stat final :

```text
 .../storylines/road_map_storylines.md              | 54 ++++++++++++++++++----
 1 file changed, 46 insertions(+), 8 deletions(-)
```

Git diff --name-only final :

```text
reports/narrativeStudio/storylines/road_map_storylines.md
```

Git diff --check final :

```text
Sortie : <vide>
```

Diff complet de `road_map_storylines.md` :

```diff
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index 2016e6e5..58d2f08d 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -301,6 +301,8 @@ Interprétation V0 :
 | NS-STORYLINES-10 | Storyline Visual Harmonization / Visual Gate V0 | visual gate | DONE | NS-STORYLINES-11 |
 | NS-STORYLINES-11 | Storylines Interaction Wiring V0 | editor UI / test | DONE | NS-STORYLINES-CHECKPOINT |
 | NS-STORYLINES-CHECKPOINT | Storylines V0 Acceptance Checkpoint | checkpoint | DONE | NS-STORYLINES-V1-00 |
+| NS-STORYLINES-V1-00 | Storyline Semantics Reset / Usable Authoring Contract | product contract | DONE | NS-STORYLINES-V1-01 |
+| NS-STORYLINES-V1-01 | Storyline Authoring Model Decision | model decision | TODO | NS-STORYLINES-V1-02 |
 
 ## 9. Detailed lots
 
@@ -600,7 +602,31 @@ Interprétation V0 :
 - Design system impact : gate confirmé, aucun `Color(0x...)` / `Colors.*`.
 - Verdict : ACCEPTED V0 WITH V1 LIMITATIONS.
 - Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-V1-00 — Storyline Creation Product Contract.
+- Prochain lot attendu : NS-STORYLINES-V1-00 — Storyline Semantics Reset / Usable Authoring Contract.
 
+### NS-STORYLINES-V1-00 — Storyline Semantics Reset / Usable Authoring Contract
+
+- Type : product-contract / design-only / documentation-only.
+- Objectif : clarifier le modèle produit Storylines V1 avant toute nouvelle implémentation.
+- Résultat : contrat sémantique créé ; boundaries Storyline / Chapter / Story Step / Scene clarifiées ; Graph et Structure définis ; triage UI V1 documenté.
+- Fichiers créés/modifiés : `reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_semantics_and_usable_authoring_contract.md`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
+- Non-objectifs respectés : aucun code, widget, modèle, test, screenshot ou bouton activé.
+- Dépendances : NS-STORYLINES-CHECKPOINT.
+- Critères d'acceptation : contrat produit clair, matrices obligatoires, actions V1 utiles définies, `localEventFlow` exclu comme `sideQuest` par défaut.
+- Tests exécutés : aucun, lot documentation-only.
+- Analyse exécutée : aucune, lot documentation-only.
+- Note produit : le problème principal était sémantique / produit, pas technique ; Storylines V0 reste une fondation valide mais V1 doit rendre la création et l'organisation réellement utilisables.
+- Statut : DONE.
+- Prochain lot attendu : NS-STORYLINES-V1-01 — Storyline Authoring Model Decision.
+
+### NS-STORYLINES-V1-01 — Storyline Authoring Model Decision
+
+- Type : model decision / product architecture.
+- Objectif : décider le modèle durable pour créer et relier Storylines, Chapters, Story Steps et Scenes.
+- Non-objectifs : pas d'UI avant décision modèle.
+- Dépendances : NS-STORYLINES-V1-00.
+- Statut : TODO.
+- Prochain lot attendu : NS-STORYLINES-V1-02.
 
 ## 10. Update protocol for every future lot
 
@@ -718,10 +744,10 @@ Décision temporaire :
 ## 13. Current status
 
 ```text
-Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS
-Current lot: NS-STORYLINES-CHECKPOINT
+Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 PRODUCT CONTRACT ACTIVE
+Current lot: NS-STORYLINES-V1-00
 Current lot status: DONE
-Next recommended lot: NS-STORYLINES-V1-00 — Storyline Creation Product Contract
+Next recommended lot: NS-STORYLINES-V1-01 — Storyline Authoring Model Decision
 ```
 
 | Lot | Status | Last update | Notes |
@@ -739,7 +765,9 @@ Next recommended lot: NS-STORYLINES-V1-00 — Storyline Creation Product Contrac
 | NS-STORYLINES-09 | DONE | 2026-05-28 | Chapters inspector / step ordering read-only livré sans scène fake. |
 | NS-STORYLINES-10 | DONE | 2026-05-28 | Visual harmonization Graph/Chapitres et Visual Gate complet livrés sans nouvelle feature. |
 | NS-STORYLINES-11 | DONE | 2026-05-28 | Interaction wiring V0 livré : sélection locale de globalStory existante, synchronisation zones read-only, actions futures non mutantes, notes V1 Creation Readiness. |
-| NS-STORYLINES-CHECKPOINT | DONE | 2026-05-28 | Storylines V0 acceptance checkpoint livré : ACCEPTED V0 WITH V1 LIMITATIONS ; prochaine phase recommandée V1 creation contract. |
+| NS-STORYLINES-CHECKPOINT | DONE | 2026-05-28 | Storylines V0 acceptance checkpoint livré : ACCEPTED V0 WITH V1 LIMITATIONS ; prochaine phase recommandée V1 semantic/product contract. |
+| NS-STORYLINES-V1-00 | DONE | 2026-05-28 | Reset sémantique produit livré : Storylines V0 techniquement valide, V1 doit clarifier et rendre utilisables Storyline / Chapter / Story Step / Scene / Graph / Structure. |
+| NS-STORYLINES-V1-01 | TODO | 2026-05-28 | Storyline Authoring Model Decision. |
 
 ## 14. V1 Creation Readiness Notes
 
@@ -757,17 +785,27 @@ Pré-requis recommandés pour activer la création Storylines V1 :
 - Création : storyline principale et quête annexe prévues pour V1 uniquement, pas en V0.
 - Boutons activables plus tard : `Nouvelle storyline`, `+`, `Nouveau chapitre`, validation narrative et création de quête annexe après contrat modèle + tests anti-fake.
 
-Suite V1 documentaire possible, sans démarrage dans V0 :
+Suite V1 documentaire recommandée :
 
-- `NS-STORYLINES-V1-00 — Storyline Creation Product Contract`
+- `NS-STORYLINES-V1-00 — Storyline Semantics Reset / Usable Authoring Contract`
 - `NS-STORYLINES-V1-01 — Storyline Authoring Model Decision`
 - `NS-STORYLINES-V1-02 — Create Main Storyline Flow`
 - `NS-STORYLINES-V1-03 — Create Side Quest Storyline Flow`
 - `NS-STORYLINES-V1-04 — Storyline Type / Status / Validation`
 - `NS-STORYLINES-V1-05 — Side Quest Graph Integration`
+- `NS-STORYLINES-V1-06 — V1 Visual Graph Enrichment`
 
 ## 15. Changelog
 
+### 2026-05-28 — NS-STORYLINES-V1-00
+
+- Reset sémantique produit Storylines V1 livré.
+- Clarification : le problème principal n'était pas technique mais sémantique / produit.
+- Storylines V0 reste valide comme fondation, mais V1 doit rendre la création et l'organisation réellement utilisables.
+- Contrat canonique documenté : Storyline, Chapter, Story Step, Scene, Scene inputs/outputs/outcomes, Side Quest, Event/Scene/Map chain.
+- Décision produit recommandée : deux onglets principaux `Graph` et `Structure`; pas d'onglets globaux `Étapes` ou `Scènes`.
+- Prochain lot recommandé : `NS-STORYLINES-V1-01 — Storyline Authoring Model Decision`.
+
 ### 2026-05-28 — NS-STORYLINES-CHECKPOINT
 
 - Storylines V0 accepté avec limites V1 documentées.
@@ -775,7 +813,7 @@ Suite V1 documentaire possible, sans démarrage dans V0 :
 - Design System Gate confirmé : aucun `Color(0x...)` / `Colors.*`.
 - Visual Gate final inventorié : captures NS10 et NS11 recommandées pour structure/theme/overflow, avec limite Ahem.
 - Limites V0 actées : pas de création storyline, pas de quête annexe, pas de modèle `StorylineAsset`, pas de graph editing, pas de scène métier finale.
- Prochain lot recommandé : `NS-STORYLINES-V1-00 — Storyline Creation Product Contract`.
+- Prochain lot recommandé : `NS-STORYLINES-V1-00 — Storyline Semantics Reset / Usable Authoring Contract`.
 
 ### 2026-05-28 — NS-STORYLINES-11-bis
```

Contenu complet du rapport créé :

```text
Le contenu complet du rapport créé est le présent document, du titre "# NS-STORYLINES-V1-00 — Storyline Semantics & Usable Authoring Contract" jusqu'à la section "## 19. Self-review".
```

Justification de l'absence de tests Flutter :

```text
Lot documentation-only. Aucun code Dart, test, widget, modèle ou screenshot modifié.
```

Auto-review critique :

```text
- Le contrat recommande `Structure`, mais laisse ce nom comme décision ouverte si le produit préfère `Chapitres & scènes`.
- Le contrat affirme que Scene peut être liée à Step ou Chapter ; V1-01 doit décider le modèle exact.
- Le rapport ne résout pas le schéma de Scene Outcome ; il le met explicitement dans les décisions ouvertes.
- Le worktree contenait déjà les changements checkpoint au début du lot ; ils sont documentés comme préexistants dans le Git initial.
```

## 19. Self-review

Critères relus :

- Aucun code modifié : oui.
- Aucun test modifié : oui.
- Aucun screenshot modifié : oui.
- Modèle Storyline / Chapter / Story Step / Scene clarifié : oui.
- Scene inputs / outputs / outcomes clarifiés : oui.
- Rôle Graph clarifié : oui.
- Rôle second onglet clarifié : oui, recommandation `Structure`.
- Éléments UI triés : oui.
- Boutons inutilisables identifiés : oui.
- Cible V1 utilisable formulée : oui.
- Quêtes annexes définies : oui.
- `localEventFlow` exclu comme `sideQuest` par défaut : oui.
- Relation Map Element -> Event -> Scene -> Outcome -> Fact / Step / World Rule expliquée : oui.
- Roadmap mise à jour : oui.
- Prochain lot V1-01 : oui.
- `git diff --check` propre : oui.
