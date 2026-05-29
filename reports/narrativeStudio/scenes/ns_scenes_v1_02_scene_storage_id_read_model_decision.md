# NS-SCENES-V1-02 — Scene Storage / ID / Read Model Decision

## 1. Executive summary

Verdict architectural : retenir l'option D.

Option retenue : `SceneAsset` authoring dedie + `ScenarioAsset` conserve comme legacy/runtime bridge temporaire.

Options rejetees :

- Option A pure : nouveau `SceneAsset` sans bridge runtime. Trop propre sur papier, mais coupe PokeMap de l'execution deja presente.
- Option B : `ScenarioAsset` devient Scene V1. Trop dangereux : le modele est utile mais porte deja trop de dette legacy.
- Option C : wrapper uniquement autour de `ScenarioAsset`. Insuffisant : l'authoring resterait prisonnier du modele legacy.

Impact roadmap : il faut inserer un lot core avant l'UI. Le prochain lot recommande devient :

`NS-SCENES-V1-03 — Scene Core Model V0`

Risques majeurs :

- Churn generated files quand `ProjectManifest.scenes` sera ajoute plus tard.
- Double systeme temporaire `scenes` + `scenarios`.
- Adapter runtime a maintenir tant que SceneRuntime natif n'existe pas.
- Migration manuelle legacy a cadrer strictement pour eviter des conversions silencieuses.

## 2. Current storage inventory

| Item | Role actuel | Format / stockage | Stabilite | Utilite Scene V1 | Danger si reutilise directement | Recommandation |
|---|---|---|---|---|---|---|
| `ProjectManifest.scenarios` | Stocke les scenarios legacy/executables. | Liste JSON `scenarios` de `ScenarioAsset`. | Stable mais legacy/transitoire. | Bridge runtime temporaire, compat anciens projets. | Devenir Scene V1 par accident. | Garder, ne pas supprimer, ne pas utiliser comme modele authoring canonique. |
| `ProjectManifest.scripts` | Catalogue scripts projet. | Liste JSON d'entrees script. | Stable. | Backend optionnel pour ActionNode avance. | UX trop technique si expose brut. | Garder comme backend, pas comme UX principale. |
| `ProjectManifest.dialogues` | Catalogue dialogues/Yarn. | Liste JSON `ProjectDialogueEntry`. | Stable. | Source de `YarnDialogueNode`. | Yarn pourrait porter progression globale. | Garder, Scene lit outcomes. |
| `ProjectManifest.storylines` | Source Storylines V1. | Liste JSON `StorylineAsset`, absent/null -> `[]`. | Recente mais canonique. | Futur lien StoryStep -> Scene. | Branchement premature sceneLink. | Garder separe, lien apres Scene stable. |
| `MapEventDefinition` | Events map a pages conditionnelles. | Dans maps / modele map event. | Utile, RPG-like. | Declencheur futur Event -> Scene. | Event peut etre confondu avec Scene. | Adapter : Event lance Scene, ne contient pas la Scene. |
| `ScenarioAsset` | Graphe scenario global/local. | Freezed JSON, nodes/edges/payload/metadata. | Execute partiellement. | Runtime bridge, migration manuelle future. | Trop generique, scopes confus. | Legacy + bridge temporaire. |
| `ScriptAsset` | Sequence de commandes runtime. | Freezed JSON. | Stable. | Backend d'actions. | Low-code brut. | Wrapper par ActionNode. |
| `ScriptCondition` | Conditions techniques. | Freezed JSON. | Stable. | Backend ConditionNode. | Flags techniques en UX. | Wrapper par condition authoring. |
| Cutscene runtime/editor | Cutscene Studio compile vers ScenarioAsset ; runtime cutscene execute steps. | Metadata + ScenarioAsset + runtime classes. | Fonctionnel mais semantique floue. | Inspiration/bridge. | Confond Scene et Cinematic. | Ne pas reutiliser comme Scene V1 directement. |
| `ScenarioRuntimeExecutor` | Bridge execution scenario. | Runtime Dart, source events/effects/actions. | MVP utile. | Adapter temporaire `SceneAsset -> ScenarioRuntime`. | Limites et vocabulaire legacy. | Backend temporaire, pas contrat produit. |

## 3. Options comparison

### Option A — Nouveau SceneAsset dedie

Description : creer un modele `SceneAsset` pur et ignorer le scenario legacy pour Scene V1.

Avantages :

- Clarite produit maximale.
- Modele authoring propre.
- Pas de fuite legacy dans l'UI.

Inconvenients :

- Pas de reutilisation runtime immediate.
- Il faut recreer plus vite un executor Scene.
- Coexistence legacy reste a traiter quand meme.

Cout : eleve.

Migration : aucune automatique, mais il faut un import manuel plus tard.

Compatibilite ancien projet : bonne en lecture si `scenarios` restent, mais pas de pont.

Impact runtime : gros travail.

Impact editor : propre.

Impact tests : nouveaux tests core/editor/runtime a creer.

Dette probable : faible cote modele, elevee cote runtime initial.

Verdict : rejete comme option pure ; trop couteux sans bridge.

### Option B — ScenarioAsset devient Scene V1

Description : declarer `ScenarioAsset.localEventFlow` comme Scene V1.

Avantages :

- Reutilise stockage existant.
- Runtime bridge deja partiel.
- Moins de generated churn.

Inconvenients :

- Mauvaise clarte produit.
- Payloads trop generiques.
- Metadata deja chargee.
- Cutscene/Scenario/Scene restent confondus.
- Scene Builder futur herite des limites legacy.

Cout : faible a court terme, eleve a long terme.

Migration : simple en apparence, dangereuse semantiquement.

Compatibilite ancien projet : forte mais ambiguë.

Impact runtime : faible.

Impact editor : dette forte.

Impact tests : risque de tests qui verrouillent le mauvais contrat.

Dette probable : tres forte.

Verdict : rejete.

### Option C — Scene V1 comme wrapper/adaptateur autour de ScenarioAsset

Description : creer une facade Scene read/write mais persister uniquement `ScenarioAsset`.

Avantages :

- Masque une partie du legacy.
- Reutilise runtime et JSON.
- Peut aider la transition.

Inconvenients :

- Le stockage reste legacy.
- La facade peut mentir sur les garanties.
- Les IDs/ports/payloads Scene doivent etre encodes dans ScenarioAsset/metadata.
- Le runtime et l'editor restent couples a la forme legacy.

Cout : moyen.

Migration : faible court terme, complexe si on veut sortir du wrapper.

Compatibilite ancien projet : bonne.

Impact runtime : faible/moyen.

Impact editor : moyen, mais fragile.

Impact tests : tests d'adapter nombreux.

Dette probable : forte.

Verdict : rejete comme strategie principale ; utile comme read-only import/adapter legacy.

### Option D — SceneAsset authoring + ScenarioAsset runtime bridge temporaire

Description : creer un nouveau `SceneAsset` canonique pour l'authoring/storage Scene V1, ajouter plus tard `ProjectManifest.scenes`, conserver `ProjectManifest.scenarios` comme legacy, puis fournir des adapters explicites :

- `SceneAsset -> SceneRuntimeExecutableModel`
- possiblement `SceneAsset -> ScenarioAsset` bridge temporaire
- `ScenarioAsset -> SceneLegacyReadModel` read-only ou import manuel plus tard

Avantages :

- Clarite produit forte.
- Runtime existant reutilisable pendant transition.
- Legacy non destructif.
- UI Scene Builder future basee sur le bon contrat.
- Migration manuelle possible plus tard.

Inconvenients :

- Deux systemes coexistent temporairement.
- Nouveau modele + generated + tests core requis.
- Adapter temporaire a maintenir.

Cout : moyen/eleve, mais controle.

Migration : prudente, manuelle, non destructive.

Compatibilite ancien projet : forte si `scenes` absent/null -> `[]` et `scenarios` conserves.

Impact runtime : progressif.

Impact editor : propre.

Impact tests : clair : tests core modele/codec/read models + tests adapters.

Dette probable : faible a moyenne, borne par lots.

Verdict : retenu.

### Matrice de decision

Scores : 1 faible, 5 fort.

| Critere | Option A | Option B | Option C | Option D |
|---|---:|---:|---:|---:|
| Clarite produit | 5 | 1 | 3 | 5 |
| No-code authoring | 5 | 2 | 3 | 5 |
| Compatibilite runtime existant | 1 | 5 | 4 | 4 |
| Faible risque dette legacy | 5 | 1 | 2 | 4 |
| Facilite de test | 4 | 3 | 2 | 4 |
| Facilite de migration | 3 | 2 | 2 | 4 |
| Qualite futur Scene Builder | 5 | 2 | 3 | 5 |
| Separation layout/runtime | 5 | 2 | 3 | 5 |
| Securite ProjectManifest | 4 | 3 | 3 | 4 |
| Total | 37 | 21 | 25 | 40 |

Decision ferme : Option D.

## 4. Recommended storage architecture

Faut-il creer un nouveau `SceneAsset` ?

Oui. `SceneAsset` doit devenir le modele canonique authoring/domain de Scene V1.

Faut-il ajouter `ProjectManifest.scenes` ?

Oui, dans un lot code futur. Il doit etre absent/null compatible et decoder en `[]`, comme `ProjectManifest.storylines`.

Faut-il garder `ProjectManifest.scenarios` ?

Oui. Il reste supporte pour compat legacy, Cutscene Studio existant et runtime bridge actuel.

Faut-il migrer automatiquement les scenarios existants ?

Non. Pas de conversion silencieuse `ScenarioAsset -> SceneAsset`.

Faut-il creer un adapter `ScenarioAsset -> Scene read model` ?

Oui, mais read-only/import manuel plus tard. Il doit afficher clairement le statut legacy.

Faut-il creer un adapter `SceneAsset -> Scenario runtime` ?

Oui, comme bridge temporaire possible, tant que SceneRuntime natif n'existe pas. Cet adapter ne doit pas devenir le contrat produit.

Canonique :

- `ProjectManifest.scenes` futur.
- `SceneAsset`.
- `SceneGraph`.
- Payloads types.
- Diagnostics Scene.

Legacy :

- `ProjectManifest.scenarios`.
- `ScenarioAsset.globalStory`.
- `ScenarioAsset.localEventFlow`.
- Cutscene Studio compile vers ScenarioAsset.

Bridge temporaire :

- `SceneAsset -> SceneRuntimeExecutableModel`.
- Optionnellement `SceneAsset -> ScenarioAsset` pour execution MVP.
- `ScenarioAsset -> SceneLegacyReadModel` read-only/import manuel.

Interdit :

- `ScenarioAsset.localEventFlow` comme Scene V1 canonique.
- Migration automatique destructive.
- Logic critical in metadata.
- StorylineStep.sceneLinkIds branche avant Scene stable.

## 5. Proposed SceneAsset shape

Forme conceptuelle future, sans code :

| Champ | Obligatoire | Optionnel | Derive | Editor-only | Runtime-relevant | Notes |
|---|---:|---:|---:|---:|---:|---|
| `id` | oui | non | non | non | oui | Stable, unique project-wide. |
| `name` | oui | non | non | non | oui | Nom utilisateur mutable. |
| `description` | non | oui | non | non | non | Aide authoring. |
| `storylineId` | non | oui | non | non | non/futur | Lien authoring futur, pas obligatoire. |
| `chapterId` | non | oui | non | non | non/futur | Seulement si lien Storylines stabilise. |
| `tags` | non | oui | non | non | non | Organisation library. |
| `graph` | oui | non | non | non | oui | Logique d'orchestration. |
| `layout` | non | oui | non | oui | non | Positions editor, separe du graph runtime. |
| `declaredOutcomes` | oui | non | non | non | oui | Outcomes de Scene. |
| `authoringState` | non | non | oui | oui | non | Derive diagnostics ; peut etre stocke seulement si decision future. |
| `metadata` | non | oui | non | non | non | Non critique uniquement. |
| `createdAt` | non | rejete V1 | non | non | non | Rejete en V1 pour eviter churn de diffs. |
| `updatedAt` | non | rejete V1 | non | non | non | Rejete en V1 pour eviter churn de diffs. |

Interdit dans `SceneAsset` :

- Yarn text complet inline.
- Combat complet inline.
- World rules cachees.
- Facts sous forme de blob libre.
- Layout comme condition runtime.
- ScenarioAsset entier embarque.

## 6. SceneGraph / SceneGraphLayout storage decision

Decision : layout persiste separement du `SceneGraph`, dans un objet editor-only attache a `SceneAsset`.

Strategie recommandee :

```text
SceneAsset
  graph: SceneGraph
  layout: SceneGraphLayout
```

`SceneGraph` :

- nodes ;
- edges ;
- ports ;
- declared outcomes ;
- payloads types.

`SceneGraphLayout` :

- positions par `nodeId` ;
- points/anchors edge optionnels ;
- zoom/pan non persistants en V1 sauf decision UI future ;
- aucune logique runtime.

Pourquoi pas inline dans SceneGraph ?

- Les tests runtime ne doivent pas casser pour un deplacement visuel.
- Les diffs logiques doivent rester lisibles.
- Runtime doit ignorer le layout.

Pourquoi pas non persiste ?

- Le Scene Builder a besoin de positions stables entre sessions.
- Recalculer tout le layout rend l'authoring frustrant.

## 7. ID strategy

Regles globales :

- Noms utilisateurs != IDs techniques.
- Aucun ID ne depend d'une position visuelle.
- Aucun ID ne depend d'un texte Yarn mutable.
- Aucun ID Selbrume hardcode.
- Rename ne change pas l'ID.
- IDs generes par operations authoring, pas par widgets seuls.

| ID | Scope unicite | Stabilite | Format recommande | Generateur | Visible utilisateur | Collisions / rename |
|---|---|---|---|---|---|---|
| `sceneId` | Projet | Stable | `scene_<slug>_<shortId>` ou slug unique preserve | Operation authoring core/editor | Non par defaut | Collision check project-wide ; rename garde id. |
| `graphId` | Scene | Stable optionnel | `graph_main` ou UUID court | Creation Scene | Non | Peut etre omis si une scene = un graph V1. |
| `nodeId` | SceneGraph | Stable | `node_<kind>_<shortId>` | Operation graph | Non | Unique dans graph ; jamais derive de position. |
| `edgeId` | SceneGraph | Stable | `edge_<shortId>` | Operation graph | Non | Unique dans graph ; source/target change ne force pas id sauf recréation. |
| `portId` | Node | Stable par kind/payload | `completed`, `true`, `outcome:<id>` | Node kind / payload | Oui comme label lisible | Outcome rename doit etre operation explicite. |
| `outcomeId` | Scene | Stable | `outcome_<slug>` ou slug controle | Operation outcome | Peut etre affiche | Rename label separe de id si besoin. |
| `layoutNodeId` | Layout | Reference nodeId | meme que `nodeId` | Layout service | Non | Supprimer node supprime layout entry. |
| `layoutEdgeId` | Layout | Reference edgeId | meme que `edgeId` | Layout service | Non | Supprimer edge supprime layout entry. |

Recommendation `graphId` :

- Ne pas imposer `graphId` en V1 si une Scene contient un seul graph.
- Ajouter seulement si V1-03 voit un besoin de versioning/multi-graph.

## 8. Read model strategy

| Read model | Consommateur | Contenu | Source | Derive/persiste | Package futur probable | Dependances | Ne doit pas contenir |
|---|---|---|---|---|---|---|---|
| `SceneLibraryReadModel` | Tree panel editor | sceneId, name, tags, diagnostics summary, linked storyline refs | `ProjectManifest.scenes` | derive | `map_core` read_models ou `map_editor` projection | map_core models | Widgets, colors. |
| `SceneGraphReadModel` | Graph canvas editor | nodes, edges, ports, layout, diagnostic badges | SceneAsset + diagnostics | derive | `map_core` pure or editor-specific if layout UI-heavy | SceneAsset | Runtime callbacks. |
| `SceneNodeReadModel` | Node widget/inspector | title, kind, payload summary, ports, status | SceneNode | derive | `map_core`/`map_editor` split | SceneGraph | Flutter widgets. |
| `SceneEdgeReadModel` | Graph canvas | source/target/label/kind/status | SceneEdge + ports | derive | `map_core`/`map_editor` split | SceneGraph | Conditions hidden on edge. |
| `SceneNodeInspectorReadModel` | Inspector editor | editable fields, warnings, refs | SceneNode + project refs | derive | `map_editor` application layer | map_core refs | Runtime state. |
| `SceneDiagnosticReadModel` | Validation panel/tree badges | diagnostics grouped by scene/node/edge | validator output | derive | `map_core` validator + editor projection | SceneAsset | Fix mutations. |
| `SceneRuntimeExecutableModel` | Runtime | executable intents, transitions, refs | SceneAsset compiled/adapted | derive/build artifact | `map_core` pure model or `map_runtime` adapter | no Flutter | Layout, editor notes. |

Distinction :

- Authoring model : persisted source (`SceneAsset`).
- Editor read model : UI-friendly projection.
- Runtime executable model : stripped, deterministic runtime form.
- Validation diagnostics : derived, not stored as truth.

## 9. Public API / package boundary decision

### `packages/map_core`

Responsabilites futures :

- `SceneAsset`, `SceneGraph`, nodes, edges, layout value objects.
- JSON codecs/generated files.
- Pure validators and diagnostics.
- Pure read models if UI-agnostic.

Interdictions :

- No Flutter.
- No editor widget state.
- No runtime Flame callbacks.

Risques si mal placee :

- Coupler authoring to editor/runtime.

### `packages/map_gameplay`

Responsabilites futures :

- Conditions/mutations pures on `GameState`.
- Fact/world state evaluation when introduced.

Interdictions :

- No Flutter.
- No editor authoring UI.

Risques :

- Scene execution rules hidden outside narrative contract.

### `packages/map_runtime`

Responsabilites futures :

- Execute runtime model.
- Dialogue/battle/cinematic handoff.
- Adapter `SceneRuntimeExecutableModel` to Flame/runtime effects.

Interdictions :

- No storage schema ownership.
- No authoring decisions.

Risques :

- Runtime becomes source of product truth.

### `packages/map_editor`

Responsabilites futures :

- UI Scene Builder.
- Providers, commands, dialogs.
- Design system integration.
- Editor read model composition if UI-specific.

Interdictions :

- No domain model definitions.
- No logic critical only in widgets.
- No hardcoded Selbrume.

Risques :

- In-memory UI state diverges from ProjectManifest.

## 10. JSON / persistence strategy future

Recommendation :

- Use existing project pattern: Freezed/json_serializable or same generated approach as neighboring models.
- `ProjectManifest.scenes` future should decode missing or null as `[]`.
- Invalid scene objects should fail validation, not be silently corrected by UI.
- If JSON shape needs migration, use explicit project migration operation, not hidden editor load magic.

Needs future build_runner ?

Yes, the future model lot will likely modify `map_core` generated files and run build_runner. Not in V1-02.

Compat behavior :

- `scenes` absent : `[]`.
- `scenes` null : `[]`.
- `scenes` invalid type : validation/load error or robust decode decision in V1-03, but not silent mutation.
- Existing `scenarios` untouched.

Golden fixtures futures :

- Project without scenes.
- Project with empty scenes.
- Project with one minimal scene.
- Project with missing refs diagnostics.
- Project with legacy scenarios + scenes side by side.

Migration strategy :

- No automatic destructive migration.
- Optional manual import/preview later.
- Explicit report of legacy scenarios not converted.

V1-03 implication :

The next lot must be a `map_core` code lot if it creates `SceneAsset` and `ProjectManifest.scenes`.

## 11. Legacy coexistence strategy

`ScenarioAsset` support :

- Remains supported.
- Becomes legacy/transitional for Narrative Studio Scenes.
- Not deleted.

Future Scene Builder creation :

- Should create `SceneAsset`, not `ScenarioAsset`.
- Should not compile to `ScenarioAsset` at save time unless a deliberate bridge/export command exists.

Read-only adapter :

- Recommended for legacy visibility.
- Must label legacy status.
- Must not silently convert.

Manual migration :

- Possible later via preview/import.
- Must be non destructive.

`ScenarioRuntimeExecutor` :

- Can serve as backend temporary adapter.
- Must not define the product model.
- If `SceneAsset -> ScenarioAsset` bridge is used, it should be explicit and tested.

Cutscene Studio :

- Continues to exist for legacy flows.
- Must not become Cinematic V1 without semantic cleanup.
- Must not be used as Scene Builder by renaming only.

## 12. Migration strategy

### Projets sans scenes

Decode `scenes` as empty list. No mutation on load. UI shows honest empty state.

### Projets avec scenarios existants

Keep `scenarios`. Do not convert. Optional legacy read-only panel/adapters later.

### Projets avec storylines existantes

Keep storylines. `sceneLinkIds` remain disabled/unlinked until Scene stable.

### Projets avec `StorylineStep.sceneLinkIds` vide

No action. Empty remains valid.

### Projets avec cutscenes/scenarios legacy

Keep working path. Future manual import can propose `SceneAsset` draft, with diff/preview.

Policy :

- No automatic destructive migration.
- No silent ScenarioAsset -> SceneAsset conversion.
- Reading old projects stays compatible.
- Import/migration, if any, is explicit user action with evidence.

## 13. Impact on roadmap

Roadmap actuelle ne doit pas passer directement au shell UI.

Raison :

- Le shell Scenes sans `SceneAsset` canonique risque de recreer des fake scenes.
- Scene tree/read-only graph ont besoin d'un storage/read model.
- `ProjectManifest.scenes` et codecs doivent exister avant une UI utile.

Roadmap corrigee :

| Lot | Statut cible | Objectif |
|---|---|---|
| NS-SCENES-V1-03 — Scene Core Model V0 | TODO | Ajouter `SceneAsset`, graph/layout value objects, `ProjectManifest.scenes`, codec/tests core. |
| NS-SCENES-V1-04 — Workspace Shell Scenes | TODO | Ajouter le shell editor Scenes sans authoring profond. |
| NS-SCENES-V1-05 — Scene Tree Panel Read-only | TODO | Lire `ProjectManifest.scenes` et afficher la bibliotheque. |
| NS-SCENES-V1-06 — Graph Read-only Skeleton | TODO | Afficher graph Scene V1 read-only. |
| NS-SCENES-V1-07 — Node Inspector Read-only | TODO | Inspecter nodes. |
| NS-SCENES-V1-08 — Authoring Minimal Scene Draft | TODO | Creer/editer scene draft minimale. |
| NS-SCENES-V1-09 — Scene Validation Diagnostics | TODO | Diagnostics graph/refs/outcomes. |
| NS-SCENES-V1-10 — Runtime Execution Prep | TODO | Adapter runtime. |
| NS-SCENES-V1-11 — StorylineStep to Scene Link | TODO | Brancher StorylineStep quand Scene stable. |

## 14. Decision records

### ADR-SCENE-001 — Scene storage strategy

Decision : creer un futur `SceneAsset` canonique et `ProjectManifest.scenes`.

Rationale : Scene V1 a un contrat produit trop different de `ScenarioAsset`.

Consequences : lot core model requis avant UI.

Rejected alternatives : `ScenarioAsset` comme Scene V1 ; wrapper-only.

Follow-up lot : `NS-SCENES-V1-03 — Scene Core Model V0`.

### ADR-SCENE-002 — Scene IDs strategy

Decision : IDs stables, scopes explicites, jamais derives de layout ou texte mutable.

Rationale : authoring no-code et graph editor ont besoin de refs robustes.

Consequences : operations authoring doivent generer et dedupliquer IDs.

Rejected alternatives : IDs bases sur noms affiches ou positions.

Follow-up lot : `NS-SCENES-V1-03`.

### ADR-SCENE-003 — SceneGraph layout strategy

Decision : persister un `SceneGraphLayout` separe du graph logique.

Rationale : editor a besoin de positions stables ; runtime ne doit pas dependre du layout.

Consequences : read models editor combinent graph + layout ; runtime executable ignore layout.

Rejected alternatives : layout inline dans nodes runtime ; layout non persiste.

Follow-up lot : `NS-SCENES-V1-03`.

### ADR-SCENE-004 — Read model split

Decision : separer authoring model, editor read model, diagnostics et runtime executable model.

Rationale : evite de faire dependre runtime de widgets ou layout.

Consequences : plus de types/projections, mais boundaries nettes.

Rejected alternatives : un seul modele pour tout.

Follow-up lot : `NS-SCENES-V1-03` puis `V1-05/V1-06`.

### ADR-SCENE-005 — Legacy Scenario coexistence

Decision : `ScenarioAsset` reste supporte comme legacy/bridge temporaire.

Rationale : projets existants et runtime bridge actuel ne doivent pas casser.

Consequences : double systeme temporaire ; besoin labels legacy et adapters.

Rejected alternatives : suppression ou conversion automatique.

Follow-up lot : `NS-SCENES-V1-10` pour runtime prep, migration manuelle plus tard.

### ADR-SCENE-006 — Migration policy

Decision : aucune migration automatique destructive ; seulement compat lecture et import manuel futur.

Rationale : ScenarioAsset ne mappe pas proprement au contrat Scene V1.

Consequences : anciens scenarios restent visibles/supportes mais non convertis.

Rejected alternatives : conversion silencieuse au load.

Follow-up lot : lot import/preview dedie apres model stable.

## 15. Recommendation for next lot

Prochain lot recommande :

`NS-SCENES-V1-03 — Scene Core Model V0`

Pourquoi :

- Le storage est decide : `SceneAsset` dedie + `ProjectManifest.scenes`.
- Une UI shell sans modele canonique creerait du vide ou du fake.
- Les read-only panels ont besoin d'un modele et de codecs.

Packages concernes probables :

- `packages/map_core`

Fichiers probables :

- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/map_core.dart`
- generated files associes
- tests core scene asset/json/project manifest

Tests probables :

- SceneAsset pure model.
- JSON codec.
- ProjectManifest.scenes absent/null -> [].
- IDs/reference validation minimale.
- No migration from scenarios.

Risques :

- Churn generated files.
- Trop gros modele au premier lot.
- Sur-modelisation avant UI.

Non-objectifs V1-03 :

- Pas de workspace UI.
- Pas de runtime executor.
- Pas de StorylineStep sceneLink.
- Pas de Selbrume scene fixture.

## 16. Evidence Pack

### pwd

```text
/Users/karim/Project/pokemonProject
```

### git branch --show-current

```text
main
```

### git status initial exact

```text
Sortie : <vide>
```

### git diff --stat initial

```text
Sortie : <vide>
```

### git log --oneline -n 10

```text
00bcaa4d chore: auto-commit changes
a85fc3c4 docs(scenes): add scene system audit and roadmap v1.0.0
af6c491b feat(storylines): update structure layout and tests v1.1.1
04cce3b7 feat(storylines): add structure layout chapter/step readability v1.1.0
2c536dbd feat(storylines): fix graph focus layout canvas priority
a428448e feat(storylines): fix Selbrume graph layout side quest rendering v0
4acf8c3f feat(storylines): add Selbrume storylines demo seed v0
b26ae424 docs(storylines): reorganize v1 screenshots and add checkpoint acceptance report
63a005e3 feat(storylines): add visual graph enrichment v1.12
db1bc6e3 docs(storylines): reorganize v1 screenshots and reports for side quest attachment
```

### Commandes principales executees

```text
pwd; git branch --show-current; git status --short --untracked-files=all; git diff --stat; git log --oneline -n 10
python3 mandatory file existence check
python3 keyword/headings summaries for scene reports and Selbrume narrative doc
python3 storage/model keyword extraction for map_core files
python3 runtime/editor keyword extraction for scenario/cutscene files
python3 roadmap line inspection
git diff -- reports/narrativeStudio/scenes/road_map_scenes.md
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

### Fichiers inspectes

```text
AGENTS.md
agent_rules.md
skills/README.md
reports/narrativeStudio/scenes/ns_scenes_v1_00_scene_system_scope_current_state_audit.md
reports/narrativeStudio/scenes/ns_scenes_v1_01_scene_product_model_graph_contract.md
reports/narrativeStudio/scenes/road_map_scenes.md
MVP Selbrume/narrative_studio.md
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/project_manifest.freezed.dart
packages/map_core/lib/src/models/project_manifest.g.dart
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/script_asset.dart
packages/map_core/lib/src/models/script_conditions.dart
packages/map_core/lib/src/models/map_event_definition.dart
packages/map_core/lib/src/models/storyline_asset.dart
packages/map_core/lib/map_core.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/application/cutscene_runtime_models.dart
packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart
```

### Fichiers absents eventuels

```text
Sortie : <vide>
```

### git status final exact

```text
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_02_scene_storage_id_read_model_decision.md
```

### git diff --stat final

```text
 reports/narrativeStudio/scenes/road_map_scenes.md | 43 +++++++++++++++++------
 1 file changed, 32 insertions(+), 11 deletions(-)
```

### git diff --name-only final

```text
reports/narrativeStudio/scenes/road_map_scenes.md
```

### git diff --check final

```text
Sortie : <vide>
```

### Contenu complet du rapport cree

Le present fichier est le rapport cree pour `NS-SCENES-V1-02`. Son contenu complet est constitue par toutes les sections de ce document.

### Diff complet de `road_map_scenes.md`

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index c168de48..325a9137 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -38,21 +38,42 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 |---|---|---|
 | NS-SCENES-V1-00 — Scene System Scope / Current State Audit | DONE | Audit documentaire de l'existant, definition Scene V1, frontieres produit et roadmap. |
 | NS-SCENES-V1-01 — Scene Product Model / Graph Contract | DONE | Contrat produit Scene V1 formalise : definitions Scene/Graph/Node/Edge/Port/Outcome, taxonomie nodes/edges, payloads minimaux/interdits, diagnostics et runtime intents. |
-| NS-SCENES-V1-02 — Scene Storage / ID / Read Model Decision | TODO | Decider ou stocker les Scenes, quels IDs, quels read models, et la strategie de migration/compat legacy. |
-| NS-SCENES-V1-03 — Workspace Shell Scenes | TODO | Creer le shell editor `Scenes` sans authoring profond ni runtime. |
-| NS-SCENES-V1-04 — Scene Tree Panel Read-only | TODO | Afficher une arborescence de scenes reelles ou fixtures explicites, sans fake fallback. |
-| NS-SCENES-V1-05 — Graph Read-only Skeleton | TODO | Afficher un graph Scene V1 read-only avec start/end et nodes reels du read model. |
-| NS-SCENES-V1-06 — Node Inspector Read-only | TODO | Inspecteur contextuel read-only pour node selectionne, conditions, sorties et notes. |
-| NS-SCENES-V1-07 — Authoring Minimal Scene Draft | TODO | Creer/editer une scene draft minimale, sans brancher Storylines ni runtime complet. |
-| NS-SCENES-V1-08 — Scene Validation Diagnostics | TODO | Diagnostics de graphe : start/end, edges invalides, nodes incomplets, refs manquantes, outcomes orphelins. |
-| NS-SCENES-V1-09 — Runtime Execution Prep | TODO | Adapter ou wrapper les briques runtime existantes pour preparer l'execution Scene V1. |
-| NS-SCENES-V1-10 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres stabilisation du modele Scene V1. |
+| NS-SCENES-V1-02 — Scene Storage / ID / Read Model Decision | DONE | Decision retenue : `SceneAsset` authoring dedie + `ProjectManifest.scenes` futur, avec `ScenarioAsset` conserve comme legacy/runtime bridge temporaire et sans migration automatique. |
+| NS-SCENES-V1-03 — Scene Core Model V0 | TODO | Ajouter le modele core `SceneAsset`, graph/layout value objects, `ProjectManifest.scenes`, exports et tests JSON/core. |
+| NS-SCENES-V1-04 — Workspace Shell Scenes | TODO | Creer le shell editor `Scenes` sans authoring profond ni runtime. |
+| NS-SCENES-V1-05 — Scene Tree Panel Read-only | TODO | Afficher une arborescence de scenes reelles depuis `ProjectManifest.scenes`, sans fake fallback. |
+| NS-SCENES-V1-06 — Graph Read-only Skeleton | TODO | Afficher un graph Scene V1 read-only avec start/end et nodes reels du read model. |
+| NS-SCENES-V1-07 — Node Inspector Read-only | TODO | Inspecteur contextuel pour node selectionne, conditions, sorties et notes. |
+| NS-SCENES-V1-08 — Authoring Minimal Scene Draft | TODO | Creer/editer une scene draft minimale, sans brancher Storylines ni runtime complet. |
+| NS-SCENES-V1-09 — Scene Validation Diagnostics | TODO | Diagnostics de graphe : start/end, edges invalides, nodes incomplets, refs manquantes, outcomes orphelins. |
+| NS-SCENES-V1-10 — Runtime Execution Prep | TODO | Adapter ou wrapper les briques runtime existantes pour preparer l'execution Scene V1. |
+| NS-SCENES-V1-11 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres stabilisation du modele Scene V1. |

 ## Prochain lot recommande

-`NS-SCENES-V1-02 — Scene Storage / ID / Read Model Decision`
+`NS-SCENES-V1-03 — Scene Core Model V0`

-Raison : le contrat produit SceneGraph est pose ; le prochain blocage est maintenant de decider storage, IDs stables, layout, read model editor/runtime et coexistence avec `ProjectManifest.scenarios`.
+Raison : la decision storage/IDs/read models est tranchee ; une UI Scenes sans modele core creerait du faux. Le prochain lot doit poser `SceneAsset`, `ProjectManifest.scenes`, graph/layout et tests core avant le shell editor.
+
+## Decisions V1-02
+
+- Option retenue : `SceneAsset` authoring dedie + `ScenarioAsset` runtime bridge temporaire.
+- Futur storage canonique : `ProjectManifest.scenes`, absent/null compatible vers `[]`.
+- `ProjectManifest.scenarios` reste supporte comme legacy ; aucune suppression.
+- Aucune migration automatique `ScenarioAsset -> SceneAsset`.
+- Layout persiste dans un `SceneGraphLayout` separe du graph logique ; runtime ignore le layout.
+- IDs stables : jamais derives du nom utilisateur, du texte Yarn, de la position visuelle ou de Selbrume.
+- Read models separes : authoring model, editor read model, diagnostics, runtime executable model.
+
+## Limites V1-02
+
+- Aucun `SceneAsset` code.
+- Aucun `ProjectManifest.scenes` code.
+- Aucun codec JSON.
+- Aucun build_runner.
+- Aucun workspace UI.
+- Aucun runtime Scene.
+- Aucun sceneLink Storylines.

 ## Decisions V1-01
```

### Tests / analyze

```text
Non executes : lot documentation-only, architecture-decision-only, no-code, no-test-change. Aucun test/analyze requis.
```

### Auto-review critique

- La recommandation insere un lot core model avant l'UI ; cela ralentit l'apparition visuelle de Scenes, mais evite un shell vide ou fake.
- Option D ajoute une coexistence temporaire ; la dette est acceptable seulement si le bridge reste explicitement temporaire.
- Le rapport ne definit pas encore la forme Dart exacte, volontairement reservee a V1-03.
- Le rejet de `createdAt/updatedAt` en V1 peut etre reconsidere plus tard, mais protege les diffs au demarrage.

### Regard critique sur le prompt

- Le prompt demandait de trancher sans implementation ; c'est coherent, mais V1-03 devra probablement etre un lot code `map_core`, donc la roadmap UI initiale doit etre decalee.
- La liste d'options pouvait melanger Option A et D ; la decision retient D car elle garde le nouveau modele canonique tout en conservant un pont runtime pragmatique.
- Selbrume reste utile comme scenario produit, mais aucune scene Selbrume ne doit etre creee avant un seed/demo explicite.
