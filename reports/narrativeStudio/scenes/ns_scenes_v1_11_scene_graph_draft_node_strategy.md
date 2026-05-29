# NS-SCENES-V1-11 — Scene Graph Draft Node Strategy

## Résumé exécutif

Ce lot est documentation-only. Aucun code, widget, modèle, test ou runtime n'a été modifié.

Décision principale : retenir une stratégie **SceneAsset authoring avec drafts diagnostiqués**, mais avec une palette V0 très stricte. En V0, seuls les nodes `condition`, `merge` et `end` doivent devenir ajoutables, parce qu'ils peuvent être créés avec le modèle actuel sans référence inventée. `start` reste unique. `yarnDialogue`, `action`, `battle`, `cinematic` et `branchByOutcome` restent désactivés tant que leurs références, payloads ou sources d'outcomes ne sont pas honnêtes.

Prochain lot exact recommandé :

```text
NS-SCENES-V1-12 — Node Authoring V0
```

## Raison du lot

V1-08 permet de créer une scène minimale start/end. V1-09 encadre les diagnostics. V1-10 et V1-10-bis ont clarifié que le runtime ne doit pas être branché trop tôt et que le Scene Builder doit devenir Blueprint-like.

Le blocage actuel est donc simple : avant de coder une palette, il faut savoir quels nodes peuvent être ajoutés sans mentir. Un node actif ne doit jamais cacher une référence Yarn, battle, cinematic ou action inventée.

## Analyse du modèle actuel

Le modèle actuel est déjà strict sur les références critiques :

| Node kind | Payload actuel | Draft vide possible aujourd'hui ? | Conclusion V1-11 |
|---|---|---:|---|
| `start` | `SceneStartPayload(notes?)` | Oui | Non ajoutable : une scène a déjà un start unique. |
| `end` | `SceneEndPayload(sceneOutcomeId?, notes?)` | Oui | Ajoutable V0. |
| `yarnDialogue` | `SceneYarnDialoguePayload(dialogueId required, yarnNodeName?, expectedOutcomes, speakerHints)` | Non | Désactivé jusqu'à picker Yarn ou payload draft explicite. |
| `condition` | `SceneConditionPayload(conditionLabel?, conditionRef?, conditionDraft?)` | Oui | Ajoutable V0, avec diagnostic d'incomplétude futur. |
| `action` | `SceneActionPayload(actionKind required, parameters)` | Non | Désactivé jusqu'à registre/action picker ou `actionKind` draft officiel. |
| `battle` | `SceneBattlePayload(battleKind required, trainerId?, battleTemplateId?, npcEntityId?, declaredOutcomes)` | Non | Désactivé jusqu'à picker battle/trainer ou payload draft explicite. |
| `cinematic` | `SceneCinematicPayload(cinematicId required)` | Non | Désactivé jusqu'à picker cinematic. |
| `branchByOutcome` | `SceneBranchByOutcomePayload(sourceNodeId?, sourceOutcomeSetRef?, fallbackPolicy?)` | Oui | Désactivé V0 : sans source outcome et mappings, le node crée une fausse promesse de branchement. |
| `merge` | `SceneMergePayload(label?, notes?)` | Oui | Ajoutable V0. |

Les constructeurs protègent déjà plusieurs invariants : `SceneGraph.startNodeId` doit référencer un node existant de type `start`, les edges doivent référencer des nodes connus, et `SceneAsset.layout` ne peut pas pointer vers des nodes inconnus.

## Options comparées

| Option | Verdict | Analyse |
|---|---|---|
| Option A — Modèle strict + wizard complet | Rejetée pour V1-12 | Elle garde les payloads toujours complets, mais bloque l'expérience Blueprint-like : l'auteur ne peut pas poser un node puis le configurer. Elle force aussi les pickers avant tout node authoring. |
| Option B — `SceneAsset` accepte des payloads draft incomplets | Retenue avec garde-fous | `SceneAsset` est déjà le modèle authoring canonique. Il peut porter des drafts incomplets si les diagnostics les signalent et si le runtime refuse les scènes avec erreurs. Le garde-fou V0 est de n'activer que les nodes dont le draft est honnête aujourd'hui. |
| Option C — Modèle `SceneDraft` séparé | Rejetée en V1 | Trop lourd pour maintenant : double modèle, conversion, divergence editor/domain. À reconsidérer seulement si les drafts deviennent trop nombreux ou trop incompatibles avec le runtime. |

## Décision retenue

Retenir **Option B stricte** :

- `SceneAsset` reste le modèle authoring canonique.
- Certains drafts incomplets sont acceptables dans `SceneAsset`.
- Un draft incomplet doit produire un diagnostic lisible.
- Une scène avec diagnostic `error` ne doit pas être exécutable.
- Aucun node actif ne doit créer une référence factice.
- V1-12 doit activer seulement `condition`, `merge`, `end`.

Cette décision garde le style Blueprint-like sans transformer V1-12 en festival de fausses références.

## Nodes ajoutables V0

### `condition`

Label UI recommandé : `Condition`

Tone/icône recommandé : tone warning ou équivalent existant ; icône condition déjà utilisée par le graph read-only.

Payload exact V0 :

```text
SceneConditionPayload()
```

Le `title` du node peut être `Condition`. Le payload peut rester vide pour éviter d'inscrire un faux `conditionRef`. Le diagnostic futur `conditionIncomplete` doit guider la configuration.

Ports :

```text
inputs:
  - in
outputs:
  - true
  - false
```

Diagnostics attendus :

- `conditionIncomplete` si `conditionRef` et `conditionDraft` sont absents.
- `missingRequiredOutput` si `true` ou `false` n'est pas connecté quand l'edge authoring existera.

Risque principal : créer une condition vide qui paraît exécutable. Le diagnostic doit la rendre non exécutable tant qu'elle n'est pas configurée.

### `merge`

Label UI recommandé : `Merge`

Tone/icône recommandé : tone neutral ; icône merge déjà utilisée par le graph read-only.

Payload exact V0 :

```text
SceneMergePayload()
```

Ports :

```text
inputs:
  - in (multi-entrant conceptuel)
outputs:
  - completed
```

Diagnostics attendus :

- `mergeWithoutIncoming` futur warning si aucun edge entrant.
- `missingRequiredOutput` futur warning/error selon stratégie edge.

Risque principal : utiliser `merge` comme node décoratif. Ce risque reste acceptable en V0, car il ne porte aucune référence externe.

### `end`

Label UI recommandé : `Fin`

Tone/icône recommandé : tone info ; icône flag déjà utilisée.

Payload exact V0 :

```text
SceneEndPayload()
```

Ports :

```text
inputs:
  - in
outputs: []
```

Plusieurs `end` sont autorisés, car une scène peut avoir plusieurs fins/outcomes. Le premier draft V1-08 contient déjà `node_end`, donc V1-12 doit générer `node_end_2`, `node_end_3`, etc.

Diagnostics attendus :

- `endOutcomeUndeclared` si un `sceneOutcomeId` est renseigné mais absent de `declaredOutcomes`.
- `endWithoutIncoming` futur warning si aucune connexion entrante.

Risque principal : créer plusieurs fins sans outcomes. Ce n'est pas faux en V0 ; c'est un draft structurel acceptable.

## Nodes désactivés V0

| Node kind | Décision V0 | Raison |
|---|---|---|
| `start` | Désactivé | Une scène a un `startNodeId` unique. Ajouter un deuxième start casserait le modèle conceptuel. |
| `yarnDialogue` | Désactivé | `dialogueId` est obligatoire. Sans picker Yarn ou payload draft officiel, tout ID serait suspect. |
| `action` | Désactivé | `actionKind` est obligatoire. Un `draftAction` non officiel serait une fausse sémantique runtime. |
| `battle` | Désactivé | `battleKind` est obligatoire et les refs trainer/template doivent être réelles. |
| `cinematic` | Désactivé | `cinematicId` est obligatoire. Il faut un picker ou une stratégie draft explicite. |
| `branchByOutcome` | Désactivé | Le payload peut être vide, mais un branch sans source outcome ni mappings ment sur sa capacité à router. |

Les nodes désactivés peuvent apparaître dans la palette V1-12, mais uniquement avec un état disabled et une raison claire.

## Ports et outputs

| Node kind | Ajoutable V0 | Inputs | Outputs | Edge kinds attendus |
|---|---:|---|---|---|
| `start` | Non | [] | `completed` ou `default` | `defaultFlow` |
| `end` | Oui | `in` | [] | Entrants : tout edge compatible. |
| `condition` | Oui | `in` | `true`, `false` | `conditionTrue`, `conditionFalse` |
| `merge` | Oui | `in` multi-entrant | `completed` ou `default` | `defaultFlow` |
| `yarnDialogue` | Non | `in` | futur `completed`, `outcome:<id>` | `dialogueOutcome`, `defaultFlow` |
| `action` | Non | `in` | futur `completed`, peut-être `error` plus tard | `actionCompleted`, `error` |
| `battle` | Non | `in` | `victory`, `defeat` | `battleVictory`, `battleDefeat` |
| `cinematic` | Non | `in` | `completed` | `cinematicCompleted` |
| `branchByOutcome` | Non | `in` | futur `outcome:<id>`, `fallback` | `branchOutcome`, `defaultFlow` |

Ces ports doivent guider V1-13 Edge Authoring : aucun edge ne doit être créé sans `fromPortId` explicite.

## Payload drafts

Payloads autorisés en V0 :

```text
condition -> SceneConditionPayload()
merge     -> SceneMergePayload()
end       -> SceneEndPayload()
```

Payloads refusés en V0 :

```text
yarnDialogue -> pas de dialogueId fake
action       -> pas de actionKind bidon
battle       -> pas de battleKind/trainerId fake
cinematic    -> pas de cinematicId fake
branch       -> pas de source outcome fake
start        -> pas de deuxième start
```

Si V1-16 introduit des pickers ou un payload draft officiel, cette liste pourra être élargie.

## Diagnostics recommandés

| Code recommandé | Sévérité | Node kind | Déclenchement | Bloque runtime ? | Bloque authoring ? | Lot recommandé |
|---|---|---|---|---:|---:|---|
| `conditionIncomplete` | error | `condition` | `conditionRef` et `conditionDraft` absents. | Oui | Non |
| `missingRequiredOutput` | error | `condition`, `battle`, `branchByOutcome` | Un output requis n'a pas d'edge sortant. | Oui | Non | V1-13/V1-17 |
| `mergeWithoutIncoming` | warning | `merge` | Aucun edge entrant. | Non | Non | V1-17 |
| `endWithoutIncoming` | warning | `end` | Aucun edge entrant sauf scène draft volontaire. | Non | Non | V1-17 |
| `missingDialogueRef` | error | `yarnDialogue` | `dialogueId` absent ou inconnu si payload draft futur. | Oui | Non | V1-16/V1-17 |
| `missingActionKind` | error | `action` | `actionKind` absent ou non reconnu. | Oui | Non | V1-16/V1-17 |
| `missingBattleRef` | error | `battle` | `battleKind` ou référence battle/trainer nécessaire absente. | Oui | Non | V1-16/V1-17 |
| `missingCinematicRef` | error | `cinematic` | `cinematicId` absent ou inconnu. | Oui | Non | V1-16/V1-17 |
| `branchOutcomeSourceMissing` | error | `branchByOutcome` | `sourceNodeId` et `sourceOutcomeSetRef` absents. | Oui | Non | V1-16/V1-17 |
| `branchOutcomeMappingsMissing` | error | `branchByOutcome` | Aucun mapping outcome -> port/edge. | Oui | Non | V1-13/V1-17 |
| `unsupportedNodeKindForAuthoring` | info | nodes disabled | Palette affiche un node non activable en V0. | Non | Oui pour ce node | V1-12 |

Principe : authoring permissif, runtime strict. Les diagnostics `error` ne doivent pas empêcher de sauvegarder un draft, mais doivent empêcher l'exécution runtime future.

## Authoring operations recommandées

Opération pure à créer en V1-12, probablement dans `packages/map_core/lib/src/authoring/scene_authoring_operations.dart` :

```dart
SceneNodeDraftCreationResult addSceneNodeDraft(
  SceneAsset scene, {
  required SceneNodeKind kind,
  String? title,
  String? afterNodeId,
})
```

Résultat recommandé :

```dart
final class SceneNodeDraftCreationResult {
  const SceneNodeDraftCreationResult({
    required this.updatedScene,
    required this.createdNode,
  });

  final SceneAsset updatedScene;
  final SceneNode createdNode;
}
```

Règles :

- L'opération ne mute jamais l'objet original.
- Elle préserve les edges existants.
- Elle préserve `declaredOutcomes`.
- Elle ajoute un `SceneNodeLayout` pour le nouveau node.
- Elle refuse `start`.
- Elle refuse les kinds désactivés V0.
- Elle autorise plusieurs `end`.
- Elle retourne une erreur typée ou un `ArgumentError` clair pour les kinds non supportés.

IDs recommandés :

```text
condition -> node_condition, node_condition_2, node_condition_3
merge     -> node_merge, node_merge_2, node_merge_3
end       -> node_end_2, node_end_3
```

Layout recommandé :

```text
1. Si afterNodeId a un layout, placer le nouveau node à droite de ce node.
2. Sinon, placer à droite du node le plus à droite.
3. Sinon, position stable par index.
```

Contraintes :

- Aucun random.
- Aucun timestamp.
- Aucune donnée Selbrume.
- Aucune modification `ProjectManifest` dans l'opération `SceneAsset` pure.

Une opération editor peut ensuite appliquer l'updatedScene dans `ProjectManifest.scenes` en mémoire via le mécanisme existant d'`EditorNotifier`, comme V1-08 le fait pour la création de scène.

## UI palette recommandée pour V1-12

Placement recommandé : dans la barre compacte de l'arborescence ou dans la barre du graph, sous forme d'un bouton design-system :

```text
Ajouter un nœud
```

Menu V0 :

```text
Actifs :
- Condition
- Merge
- Fin

Désactivés :
- Début — déjà unique
- Dialogue Yarn — picker requis
- Action — registre d'actions requis
- Combat — picker battle/trainer requis
- Cinématique — picker cinematic requis
- Branche by outcome — source outcome requise
```

Comportement :

- Cliquer un node actif crée un vrai `SceneNode`.
- Le nouveau node est sélectionné localement.
- L'inspector read-only/draft affiche son payload et les diagnostics.
- Aucun edge n'est créé automatiquement en V1-12.
- Aucun bouton ne prétend configurer Yarn, battle ou cinematic avant picker.

## Impact Selbrume

Le golden slice Selbrume aura besoin de :

```text
YarnDialogueNode -> yarn_rival_intro
BranchByOutcomeNode -> confident / hesitant / aggressive
CinematicNode -> cinematic_rival_smiles / cinematic_rival_teases
BattleNode -> battle_rival_port
ActionNode -> facts / step completion plus tard
```

Ces nodes ne doivent pas être activés en V1-12 sans pickers ou payload drafts officiels. Pour Selbrume, la stratégie protège le slice au lieu de le ralentir : mieux vaut un builder qui refuse de mentir qu'une scène qui semble complète mais contient des IDs inventés.

Avant le golden slice, il faut encore :

- V1-12 Node Authoring V0.
- V1-13 Edge Authoring V0.
- V1-15 Scene Runtime Plan V0.
- V1-16 Payload Pickers V0.
- V1-17 Diagnostics Expansion.
- V1-18 Event to Scene Trigger Prep.
- V1-19 Scene Runtime Executor MVP.

## Prochain lot exact

```text
NS-SCENES-V1-12 — Node Authoring V0
```

Objectif recommandé : coder l'opération pure d'ajout de node draft et la palette minimale `Condition`, `Merge`, `Fin`, avec les autres nodes visibles mais désactivés.

## Fichiers créés/modifiés

Créé :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_11_scene_graph_draft_node_strategy.md
```

Modifiés :

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## Tests / analyze

Non requis : lot documentation-only, sans code, widget, modèle ni test.

Commande obligatoire exécutée :

```bash
git diff --check
```

Résultat final exact :

```text
Sortie : <vide>
```

## Git status initial

Commande :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git log --oneline -n 10
```

Sortie exacte :

```text
/Users/karim/Project/pokemonProject
main
4fbfead4 docs(scenes): add scene builder runtime and authoring roadmap alignment
68df7710 docs(scenes): add runtime execution preparation report
ba6ec6e2 feat(scenes): add scene validation diagnostics and update tests
f9095001 feat(scenes): add minimal scene draft authoring operations and tests
c1bf1c76 feat(scenes): add read-only node inspector and update workspace tests
e3b346c7 feat(scenes): harden graph read-only fallback layout and update tests
d97be401 chore: auto-commit changes
7fcd3c87 chore: auto-commit changes
6bbff623 scènes workspace shell UI
3253c8d5 chore: auto-commit changes
```

Interprétation :

```text
pwd : /Users/karim/Project/pokemonProject
git branch --show-current : main
git status initial : Sortie : <vide>
git diff --stat initial : Sortie : <vide>
```

## Evidence Pack

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
4fbfead4 docs(scenes): add scene builder runtime and authoring roadmap alignment
68df7710 docs(scenes): add runtime execution preparation report
ba6ec6e2 feat(scenes): add scene validation diagnostics and update tests
f9095001 feat(scenes): add minimal scene draft authoring operations and tests
c1bf1c76 feat(scenes): add read-only node inspector and update workspace tests
e3b346c7 feat(scenes): harden graph read-only fallback layout and update tests
d97be401 chore: auto-commit changes
7fcd3c87 chore: auto-commit changes
6bbff623 scènes workspace shell UI
3253c8d5 chore: auto-commit changes
```

### Liste des fichiers lus

```text
AGENTS.md
agent_rules.md
skills/README.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_10_bis_scene_builder_runtime_roadmap_alignment.md
reports/narrativeStudio/scenes/ns_scenes_v1_03_scene_core_model_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_08_authoring_minimal_scene_draft.md
reports/narrativeStudio/scenes/ns_scenes_v1_09_scene_validation_diagnostics.md
reports/narrativeStudio/scenes/ns_scenes_v1_10_runtime_execution_prep.md
MVP Selbrume/narrative_studio.md
MVP Selbrume/selbrume.md
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/lib/src/authoring/scene_authoring_operations.dart
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart
packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
```

### Contenu complet des fichiers Markdown créés

Fichier créé :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_11_scene_graph_draft_node_strategy.md
```

Contenu complet : le présent document.

### Diff complet de road_map_scenes.md

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 1396a697..c397abec 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -48,7 +48,7 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-09 — Scene Validation Diagnostics | DONE | Diagnostics Scene V1 purs dans `map_core` et affichage editor : erreurs/warnings de graph, layout et outcomes, sans mutation ni correction automatique. |
 | NS-SCENES-V1-10 — Runtime Execution Prep | DONE | Decision runtime Scene V1 : preparer un `SceneRuntimePlan` pur avant tout branchement runtime, utiliser `ScenarioRuntimeExecutor` seulement comme inspiration/bridge temporaire explicite. |
 | NS-SCENES-V1-10-bis — Scene Builder / Runtime Roadmap Alignment | DONE | Roadmap reconcilee : priorite au Scene Builder Blueprint-like, runtime plan conserve mais decale apres authoring graph minimal. |
-| NS-SCENES-V1-11 — Scene Graph Draft Node Strategy | TODO | Definir les nodes ajoutables, payload drafts, ports et limites pour eviter les fausses refs avant l'authoring actif. |
+| NS-SCENES-V1-11 — Scene Graph Draft Node Strategy | DONE | Strategie retenue : activer seulement Condition, Merge et Fin en V0 ; garder Start unique et desactiver Yarn/Action/Battle/Cinematic/Branch tant que les refs/payloads ne sont pas honnetes. |
 | NS-SCENES-V1-12 — Node Authoring V0 | TODO | Ajouter une palette de nodes et l'ajout read/write de nodes draft dans le graph Scene, sans payload picker avance. |
 | NS-SCENES-V1-13 — Edge Authoring V0 | TODO | Permettre la connexion explicite des ports/nodes avec validation de compatibilite, sans runtime. |
 | NS-SCENES-V1-14 — Layout Authoring V0 | TODO | Permettre le deplacement des nodes et la persistence de `SceneGraphLayout`, sans impact runtime. |
@@ -62,9 +62,32 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-11 — Scene Graph Draft Node Strategy`
+`NS-SCENES-V1-12 — Node Authoring V0`
 
-Raison : V1-10 tranche la strategie runtime, mais le Scene Builder ne permet pas encore de construire une scene. Avant de coder une palette ou des connexions, il faut definir les node drafts autorises, leurs ports, leurs payloads minimaux et les garde-fous anti-fake refs. Le `SceneRuntimePlan` reste necessaire, mais il vient apres un authoring graph minimal.
+Raison : V1-11 a tranche les node drafts autorises sans fake refs. Le prochain lot peut maintenant coder une palette minimale et une operation pure d'ajout de node draft pour Condition, Merge et Fin, sans ajouter de picker avance, sans edge authoring et sans runtime.
+
+## Decisions V1-11
+
+- Strategie retenue : `SceneAsset` reste le modele authoring canonique et peut porter certains drafts incomplets, mais seulement quand le payload est honnete et diagnostiquable.
+- Option B retenue avec garde-fous : pas de modele `SceneDraft` separe en V1, pas de wizard obligatoire pour chaque node, mais pas de reference factice.
+- Nodes ajoutables en V0 : `condition`, `merge`, `end`.
+- Nodes desactives en V0 : `start` (unique), `yarnDialogue`, `action`, `battle`, `cinematic`, `branchByOutcome`.
+- `condition` peut etre ajoute avec payload vide et diagnostic `conditionIncomplete` futur ; il expose `true` / `false`.
+- `merge` peut etre ajoute avec payload vide ; il sert a rejoindre plusieurs branches et expose `completed/default`.
+- `end` peut etre ajoute avec `SceneEndPayload` vide ; plusieurs fins sont autorisees.
+- `yarnDialogue`, `battle`, `cinematic` attendent des pickers ou une strategie explicite de payload draft.
+- `action` attend un registre/action picker ou un `actionKind` draft officiel, pas une chaine bidon.
+- `branchByOutcome` attend une strategie de source outcome et de mappings, meme si le modele accepte un payload vide.
+- Les diagnostics futurs devront bloquer l'execution runtime si un node draft reste incomplet.
+- Le prochain lot code seulement l'ajout de nodes draft V0 et la palette correspondante.
+
+## Limites V1-11
+
+- Documentation-only : aucun code, widget, modele ou test.
+- Aucune palette n'est codee.
+- Aucune operation d'authoring n'est codee.
+- Aucun diagnostic supplementaire n'est code.
+- Aucun runtime, event trigger ou StorylineStep link n'est branche.
 
 ## Decisions V1-10-bis
```

### Diff complet de road_map_scene_builder_authoring.md

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index d85c1ca2..22fd2b4b 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande
 
 ```text
-NS-SCENES-V1-11 — Scene Graph Draft Node Strategy
+NS-SCENES-V1-12 — Node Authoring V0
 ```
 
 ## Principes
@@ -25,8 +25,8 @@ NS-SCENES-V1-11 — Scene Graph Draft Node Strategy
 
 | ID | Titre | Type | Objectif | Non-objectifs | Fichiers probables | Tests attendus | Risques | Criteres d'acceptation | Dependances |
 |---|---|---|---|---|---|---|---|---|---|
-| NS-SCENES-V1-11 | Scene Graph Draft Node Strategy | doc-only / planning | Definir nodes ajoutables, defaults, ports, payload drafts, restrictions anti-fake refs. | Pas de UI, pas de runtime, pas de model change sauf recommandation. | `reports/narrativeStudio/scenes/ns_scenes_v1_11_scene_graph_draft_node_strategy.md`, roadmap. | Non requis hors `git diff --check`. | Trop de doc, ou inversement palette codee trop tot. | Liste claire des node drafts V0, ports, payloads autorises/interdits, prochain lot authoring. | V1-10-bis. |
-| NS-SCENES-V1-12 | Node Authoring V0 | core / editor | Ajouter palette minimale et creation de nodes draft dans `ProjectManifest.scenes` en memoire. | Pas de edge authoring avance, pas de pickers refs, pas de runtime. | `scene_authoring_operations.dart`, `scenes_workspace.dart`, tests Scenes. | Tests core operations + widget palette/add node + no fake refs. | Nodes inutilisables si payloads trop vides ; UI trop proche d'un builder complet. | Nodes autorises ajoutables, selection auto, inspector read-only ou draft, diagnostics mis a jour. | V1-11. |
+| NS-SCENES-V1-11 | Scene Graph Draft Node Strategy | doc-only / planning | Definir nodes ajoutables, defaults, ports, payload drafts, restrictions anti-fake refs. | Pas de UI, pas de runtime, pas de model change. | `reports/narrativeStudio/scenes/ns_scenes_v1_11_scene_graph_draft_node_strategy.md`, roadmap. | Non requis hors `git diff --check`. | Trop de doc, ou inversement palette codee trop tot. | DONE : Condition, Merge et Fin ajoutables V0 ; Yarn/Action/Battle/Cinematic/Branch desactives jusqu'aux refs/payloads honnetes. | V1-10-bis. |
+| NS-SCENES-V1-12 | Node Authoring V0 | core / editor | Ajouter palette minimale et creation de nodes draft `condition`, `merge`, `end` dans `ProjectManifest.scenes` en memoire. | Pas de edge authoring avance, pas de pickers refs, pas de runtime, pas de nodes Yarn/Action/Battle/Cinematic/Branch actifs. | `scene_authoring_operations.dart`, `scenes_workspace.dart`, tests Scenes. | Tests core operations + widget palette/add node + no fake refs. | Nodes inutilisables si diagnostics trop faibles ; UI trop proche d'un builder complet. | Nodes V0 autorises ajoutables, selection auto, inspector read-only/draft, diagnostics visibles, nodes desactives honnetes. | V1-11. |
 | NS-SCENES-V1-13 | Edge Authoring V0 | core / editor | Connecter explicitement ports/nodes, creer/supprimer edges simples, valider compatibilite. | Pas de drag complexe, pas de runtime, pas de auto-layout final. | operations core edges, `scene_graph_read_only_view.dart` evolue en graph draft view, tests. | Tests fromPortId, edge kind, incompatibilites, ProjectManifest non touche hors scenes. | Branches implicites, edges invalides, UX de connexion trop lourde. | Edge cree depuis port explicite, diagnostics edge visibles, aucun edge implicite par proximite. | V1-12. |
 | NS-SCENES-V1-14 | Layout Authoring V0 | editor | Deplacer nodes et persister `SceneGraphLayout` sans modifier le graph logique. | Pas de runtime, pas de minimap avancee, pas de auto-route edges final. | graph view, layout operations, widget tests. | Tests drag/persist layout, fallback non persiste, runtime data inchangee. | Coupler layout et runtime ; churn de diffs. | Positions stables sauvegardees, layout incomplet reste warning, aucun effet runtime. | V1-13. |
 | NS-SCENES-V1-15 | Scene Runtime Plan V0 | core | Ajouter `SceneRuntimePlan`, intents, builder pur depuis `SceneAsset` valide. | Pas d'execution runtime, pas de Flutter, pas de `ScenarioAsset` auto. | `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`, tests core. | Draft minimal, yarn/battle/cinematic/action intents, diagnostics error bloque, layout ignore. | Figer trop tot un executor ; dupliquer ScenarioRuntime. | Plan pur testable, ignore layout, refuse scenes invalides. | V1-13 ou V1-14. |
@@ -46,6 +46,14 @@ NS-SCENES-V1-11 — Scene Graph Draft Node Strategy
 | C — Hybride Blueprint + runtime plan | Retenue | Donne vite un builder utile, garde runtime plan proche, puis enchaine Event -> Scene avant StorylineStep. |
 | D — Event-first | Rejetee maintenant | Selbrume a besoin d'Event -> Scene, mais trop tot si le builder ne peut pas construire la scene cible. |
 
+## Mise a jour V1-11
+
+Statut : `NS-SCENES-V1-11 — Scene Graph Draft Node Strategy` est DONE.
+
+Decision : le premier authoring de nodes doit rester tres strict. En V0, seuls `condition`, `merge` et `end` deviennent ajoutables, car ils peuvent etre crees avec le modele actuel sans reference inventee. `start` reste unique. `yarnDialogue`, `action`, `battle`, `cinematic` et `branchByOutcome` restent visibles mais desactives dans la future palette tant que leurs refs, source outcomes ou action kinds ne sont pas honnetes.
+
+Prochain lot exact : `NS-SCENES-V1-12 — Node Authoring V0`.
+
 ## Selbrume golden slice
 
 Avant le golden slice, il faut au minimum :
```

### Tests ciblés

```text
Non requis : lot documentation-only, sans code, widget, modèle ni test.
```

### Analyze

```text
Non requis : lot documentation-only, sans code, widget, modèle ni test.
```

### git status final exact

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_11_scene_graph_draft_node_strategy.md
```

### git diff --stat final

```text
 .../scenes/road_map_scene_builder_authoring.md     | 14 ++++++++---
 reports/narrativeStudio/scenes/road_map_scenes.md  | 29 +++++++++++++++++++---
 2 files changed, 37 insertions(+), 6 deletions(-)
```

### git diff --name-only final

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

### git diff --check final

```text
Sortie : <vide>
```

## Auto-review critique

Ce qui est prouvé :

- Le lot est resté documentation-only.
- Les modèles core et fichiers editor ont été lus pour vérifier la stricte réalité des payloads.
- Les options strict/wizard, payload draft et modèle draft séparé sont comparées.
- La décision V0 évite les fake refs.
- Les roadmaps pointent maintenant vers V1-12 Node Authoring V0.

Ce qui n'est pas prouvé par ce lot :

- Aucune opération d'authoring n'est codée.
- Aucun diagnostic draft payload n'est codé.
- Aucune palette UI n'est codée.
- Aucun test n'est exécuté, parce que le lot ne modifie aucun code.

Risque restant :

- La stratégie est volontairement stricte. Elle ralentit l'arrivée de Yarn/Battle/Cinematic dans la palette, mais elle évite des scènes qui paraissent configurées alors qu'elles contiennent des IDs inventés.

## Regard critique sur le prompt

Le prompt est utile parce qu'il force la question importante : quels nodes peut-on ajouter sans mensonge produit ? Il est aussi volontairement exigeant pour un lot documentation-only, notamment sur l'Evidence Pack. Cette exigence est cohérente avec la suite, car V1-12 va écrire du code ; une stratégie ambiguë ici coûterait cher au lot suivant.

La recommandation initiale suggérait potentiellement `action` ou `branchByOutcome` en V0. L'analyse du modèle conduit à une réponse plus stricte : `action` exige `actionKind`, et `branchByOutcome` peut techniquement être vide mais n'a pas de sens authoring honnête sans source outcome. Les deux restent donc désactivés.
