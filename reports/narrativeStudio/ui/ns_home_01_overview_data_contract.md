# NS-HOME-01 — Narrative Overview Data Contract / Metric Semantics V0

## 1. Résumé exécutif

NS-HOME-01 verrouille la sémantique des données de la future page
`Narrative Studio / Aperçu`. La décision centrale est simple : cette page est
un dashboard auteur, jamais un dashboard de progression joueur.

Le contrat V0 retient uniquement des données calculables depuis le projet,
depuis les projections narratives existantes, ou depuis les validateurs déjà
présents. Toute donnée absente doit devenir un empty state honnête, rester
masquée, ou être reportée. Les chiffres de l'image de référence ne doivent
jamais être copiés dans le code.

Décision recommandée pour le prochain lot exact :

```text
NS-HOME-02 — NarrativeOverviewReadModel V0
```

Ce lot peut démarrer sans lot intermédiaire, à condition de respecter les
classifications ci-dessous : pas de quêtes réelles sans modèle Quest, pas de
Facts réels sans registre dédié, pas d'activité récente sans journal réel, pas
de notifications sans source.

## 2. Sources lues

Sources obligatoires lues :

- `AGENTS.md`
- `agent_rules.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_1.md`
- `reports/narrativeStudio/ui/ns_home_00_overview_roadmap_proposal.md`

Sources repo relues de manière ciblée :

- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/operations/narrative_validator.dart`
- `packages/map_core/lib/src/authoring/narrative_validator_authoring_adapter.dart`
- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart`
- `packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart`
- `packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart`
- `packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_model.dart`
- `packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_validation.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/ui/shared/status_bar.dart`

Signal important : `agent_rules.md` existe.

## 3. Décisions globales de sémantique

1. Le dashboard `Aperçu` est auteur-first. Il peut parler de chapitres,
   scènes, dialogues, problèmes, règles et préparation éditoriale. Il ne doit
   pas parler de sauvegarde joueur, progression runtime, pourcentage de
   completion de partie, slots, argent, badges, capture ou état de GameState.

2. Les sources V0 autorisées sont :
   - `ProjectManifest` pour l'identité projet, maps, dialogues, scénarios et
     métadonnées existantes ;
   - `ScenarioAsset` pour les scénarios `globalStory` et `localEventFlow` ;
   - `buildNarrativeWorkspaceProjection(...)` pour les storylines locales,
     steps, linked cutscenes, outcomes et world changes ;
   - `GlobalStoryStudioDocument` pour les chapitres quand la metadata existe,
     avec fallback "Histoire principale" explicitement identifié comme fallback ;
   - `StepStudioDocument` pour steps, conditions, outcomes, cutscenes et
     worldChanges ;
   - `Cutscene Studio` metadata pour distinguer une cinématique authorée d'un
     simple flow local ;
   - `ProjectDialogueEntry` et les fichiers Yarn lus par un futur read model
     pour compter les dialogues ou lignes ;
   - `NarrativeValidator`, `NarrativeValidatorAuthoringAdapter`,
     `DialogueEditorValidation` et `ProjectValidator` pour les problèmes
     ouverts.

3. Les sources V0 interdites pour ce dashboard sont :
   - `GameState`, `SaveData`, sauvegardes disque et runtime player ;
   - états PlayableMapGame, overlays runtime et notifications runtime ;
   - chiffres de la maquette ;
   - noms Selbrume hardcodés ;
   - états "Validé" ou "À jour" sans exécution d'un vrai validateur.

4. Décision V0 pour `Scènes` : une scène narrative est un élément authoré
   rattaché à une step et matérialisé par une cutscene ou un flow local
   compatible Cutscene Studio. On ne compte pas tous les `ScenarioAsset`, ni
   tous les blocks cutscene, ni une scène runtime. Si le lien Step Studio ->
   cutscene n'est pas disponible, la métrique doit être indisponible ou vide.

5. Décision V0 pour `Cinématiques` : une cinématique est un
   `ScenarioAsset.localEventFlow` portant la metadata Cutscene Studio
   `authoring.cutsceneSchema` ou `authoring.cutsceneFlow`. Les anciens local
   event flows sans metadata peuvent être listés comme candidats à migrer, mais
   pas additionnés comme cinématiques fiables.

6. Décision V0 pour `Quêtes` : il n'existe pas de modèle Quest first-class
   fiable. Le compteur `Quêtes` ne doit pas être affiché comme réel en V0. La
   carte peut exister comme empty state produit si la navigation future le
   demande, mais sans compteur.

7. Décision V0 pour `Facts` : il n'existe pas de registre Fact/lore/encyclopédie
   fiable. Le module reste un empty state ou un lot futur nécessitant un modèle.

8. Décision V0 pour `World Rules` : on ne parle pas de gameplay rules globales
   ni d'état de sauvegarde. La définition prudente est : règles authorées qui
   changent ou conditionnent la présence narrative dans le monde, notamment
   `StepStudioWorldChange` et prédicats de visibilité.

9. Décision V0 pour `Conditions narratives` : on compte les conditions
   authorées qui contrôlent l'activation, la complétion, la visibilité ou les
   dépendances narratives. On ne compte pas les valeurs runtime de flags dans
   une sauvegarde.

10. Décision V0 pour `Problèmes ouverts` : le compteur agrège les diagnostics
    auteur calculés. Il ne doit pas mélanger silencieusement un validator bêta
    gameplay, un état de sauvegarde, et une validation narrative. Le read model
    doit exposer la provenance des diagnostics.

11. Décision V0 pour `Statut éditorial` : si aucun validateur n'a tourné, le
    statut est `Non évalué`, jamais `À jour` ni `Validé`.

## 4. Classification complète des données

| Section | Donnée affichée | Classification | Décision V0 |
|---|---|---|---|
| KPI | Chapitres | `AVAILABLE_AFTER_READ_MODEL` | Compter les chapitres du Global Story Studio, fallback identifié séparément. |
| KPI | Scènes | `AVAILABLE_AFTER_READ_MODEL` | Compter les scènes narratives liées à des steps via cutscenes/flows authorés. |
| KPI | Cinématiques | `AVAILABLE_AFTER_READ_MODEL` | Compter seulement les local event flows compatibles Cutscene Studio. |
| KPI | Quêtes | `OUT_OF_SCOPE_V0` | Ne pas afficher de compteur réel sans modèle Quest. |
| KPI | Dialogues | `AVAILABLE_AFTER_READ_MODEL` | Compter les `ProjectDialogueEntry`; lignes Yarn après lecture fichier. |
| KPI | Problèmes ouverts | `AVAILABLE_AFTER_READ_MODEL` | Agréger les diagnostics auteur calculés. |
| Histoire principale | Titre | `AVAILABLE_AFTER_READ_MODEL` | Nom du scénario global principal ou empty state. |
| Histoire principale | Description / synopsis | `AVAILABLE_AFTER_READ_MODEL` | Description du scénario global ou future metadata narrative. |
| Histoire principale | Scènes liées | `AVAILABLE_AFTER_READ_MODEL` | Somme des cutscenes liées aux steps de l'histoire sélectionnée. |
| Histoire principale | Dialogues liés | `AVAILABLE_AFTER_READ_MODEL` | Dialogues référencés par les scènes/steps de l'histoire sélectionnée. |
| Histoire principale | Problèmes ouverts | `AVAILABLE_AFTER_READ_MODEL` | Diagnostics filtrés au scope de l'histoire principale. |
| Histoire principale | Liste des chapitres | `AVAILABLE_AFTER_READ_MODEL` | Chapitres du Global Story Studio. |
| Histoire principale | État de chaque chapitre | `AVAILABLE_AFTER_READ_MODEL` | Dérivé des diagnostics/complétude, non persisté comme vérité V0. |
| Histoire principale | Action Modifier | `AVAILABLE_AFTER_READ_MODEL` | Action future vers metadata/storyline, désactivée si source absente. |
| Modules | Quêtes annexes | `EMPTY_STATE_V0` | Carte possible, sans compteur, avec message "Modèle Quest non défini". |
| Modules | Cinématiques | `AVAILABLE_AFTER_READ_MODEL` | Même sémantique que KPI Cinématiques. |
| Modules | Dialogues | `AVAILABLE_AFTER_READ_MODEL` | Même source que KPI Dialogues. |
| Modules | Conditions narratives | `AVAILABLE_AFTER_READ_MODEL` | Conditions Step/Scenario/visibility predicates, pas runtime state. |
| Modules | Règles du monde | `AVAILABLE_AFTER_READ_MODEL` | `worldChanges` + règles de visibilité authorées. |
| Modules | Facts | `NEEDS_NEW_MODEL` | Empty state jusqu'à registre Fact/lore. |
| Panneau droit | Nom de l'univers narratif | `AVAILABLE_NOW` | `ProjectManifest.name`, avec libellé projet. |
| Panneau droit | Statut global En cours | `AVAILABLE_AFTER_READ_MODEL` | Dérivé du statut éditorial ; fallback `Non évalué`. |
| Panneau droit | Compteurs structurels | `AVAILABLE_AFTER_READ_MODEL` | Même sources que KPI, avec sources absentes marquées. |
| Panneau droit | Description | `NEEDS_SEMANTIC_DECISION` | Source projet-level à décider ; ne pas hardcoder. |
| Panneau droit | Tags | `NEEDS_NEW_MODEL` | Pas de tags globaux fiables ; empty state. |
| Panneau droit | Liste des chapitres | `AVAILABLE_AFTER_READ_MODEL` | Même source que chapitres. |
| Panneau droit | Statut éditorial | `AVAILABLE_AFTER_READ_MODEL` | Résumé des diagnostics par sévérité et fraîcheur. |
| Panneau droit | À jour | `AVAILABLE_AFTER_READ_MODEL` | Seulement si validation exécutée sans diagnostic. |
| Panneau droit | À revoir | `AVAILABLE_AFTER_READ_MODEL` | Diagnostics non bloquants ou warnings. |
| Panneau droit | Bloquants | `AVAILABLE_AFTER_READ_MODEL` | Diagnostics erreur/bloquants. |
| Autres | Project Health | `AVAILABLE_AFTER_READ_MODEL` | Santé authoring agrégée, pas statut de sauvegarde runtime. |
| Autres | Activité récente | `OUT_OF_SCOPE_V0` | Aucun journal réel ; ne pas inventer. |
| Autres | Notifications | `OUT_OF_SCOPE_V0` | Aucun système notification dashboard fiable. |
| Autres | Recherche | `OUT_OF_SCOPE_V0` | Reporter tant qu'un index auteur n'existe pas. |
| Footer | Projet | `AVAILABLE_NOW` | `ProjectManifest.name`. |
| Footer | Locale | `NEEDS_SEMANTIC_DECISION` | Source locale projet à définir. |
| Footer | Version | `NEEDS_SEMANTIC_DECISION` | Distinguer version app, schéma projet et version contenu. |

## 5. Fiches détaillées par donnée

### Chapitres

#### Définition utilisateur

Sections de haut niveau de l'histoire principale, lisibles par un créateur
comme des arcs ou chapitres narratifs.

#### Définition technique recommandée

Nombre de `GlobalStoryChapter` dans le `GlobalStoryStudioDocument` du scénario
global principal. Si la metadata Global Story Studio manque et qu'un chapitre
fallback est généré, le read model doit l'indiquer comme fallback et non comme
chapitre authoré explicitement.

#### Source actuelle dans le repo

- `ProjectManifest.scenarios`
- `ScenarioAsset.scope == ScenarioScope.globalStory`
- `GlobalStoryStudioDocument.chapters`
- fallback de `createDefaultGlobalStoryStudioDocument(...)`

#### Formule V0

```text
chapters = globalStoryDocument.chapters
count = chapters.length
sourceQuality = explicitMetadata | generatedFallback | unavailable
```

#### Classification

`AVAILABLE_AFTER_READ_MODEL`

#### Empty state

`Aucun chapitre défini. Créez une structure d'histoire pour organiser vos steps.`

#### Message si indisponible

`Structure de chapitres non disponible pour cette histoire.`

#### Risques de confusion

Compter le fallback comme un chapitre réellement authoré peut faire croire que
le projet est plus structuré qu'il ne l'est.

#### Non-objectifs

Ne pas représenter la progression joueur dans un chapitre. Ne pas compter les
maps comme chapitres.

#### Tests futurs

- Projet sans scénario global : compteur indisponible.
- Projet avec Global Story Studio metadata : compteur exact.
- Projet sans chapitres explicites mais avec fallback : compteur marqué fallback.

### Scènes et scènes liées

#### Définition utilisateur

Moments narratifs authorés, rattachés à des steps, qui déclenchent ou racontent
une situation : interaction, mini-scène, séquence locale ou scène principale.

#### Définition technique recommandée

En V0, une scène est une référence `StepStudioCutsceneLink` résolue vers un
`ScenarioAsset.localEventFlow` compatible Cutscene Studio. Le terme `Scène` ne
désigne pas un modèle runtime, pas un block cutscene, et pas tous les scénarios.

#### Source actuelle dans le repo

- `StepStudioStep.cutscenes`
- `NarrativeStepSummary.linkedCutsceneIds`
- `ProjectManifest.scenarios`
- `ScenarioAsset.scope == ScenarioScope.localEventFlow`
- metadata `authoring.cutsceneSchema` / `authoring.cutsceneFlow`

#### Formule V0

```text
linkedSceneIds = allSteps.linkedCutsceneIds
resolvedScenes = linkedSceneIds where matching localEventFlow has Cutscene Studio metadata
sceneCount = resolvedScenes.unique.length
linkedSceneCountForStory = stepsInSelectedStory.linkedCutsceneIds.resolved.unique.length
```

#### Classification

`AVAILABLE_AFTER_READ_MODEL`

#### Empty state

`Aucune scène liée à vos steps pour l'instant.`

#### Message si indisponible

`Les scènes ne peuvent pas être calculées sans liens Step Studio vers des cutscenes authorées.`

#### Risques de confusion

Le repo n'a pas encore un modèle `Scene` stable distinct. Afficher un compteur
en comptant tous les `localEventFlow` serait trompeur.

#### Non-objectifs

Ne pas compter les nodes, les blocks, les maps, les triggers ou les sauvegardes
runtime comme des scènes.

#### Tests futurs

- Step liée à une cutscene metadata-backed : +1 scène.
- Step liée à un id inconnu : diagnostic, pas +1.
- Local event flow sans metadata Cutscene Studio : pas compté comme scène V0.

### Cinématiques

#### Définition utilisateur

Séquences cinématiques authorées dans le Cutscene Studio, prêtes à être
prévisualisées, validées ou enrichies.

#### Définition technique recommandée

Nombre de `ScenarioAsset.localEventFlow` portant une metadata Cutscene Studio
reconnue. Une cinématique authorée est différente d'un local event flow legacy
et d'une cinématique runtime.

#### Source actuelle dans le repo

- `ProjectManifest.scenarios`
- `ScenarioAsset.scope == ScenarioScope.localEventFlow`
- `kCutsceneStudioSchemaMetadataKey`
- `kCutsceneStudioFlowMetadataKey`

#### Formule V0

```text
cutsceneCount = scenarios
  .where(scope == localEventFlow)
  .where(metadata contains authoring.cutsceneSchema or authoring.cutsceneFlow)
  .length
```

#### Classification

`AVAILABLE_AFTER_READ_MODEL`

#### Empty state

`Aucune cinématique authorée. Créez une scène locale pour commencer.`

#### Message si indisponible

`Les cinématiques legacy sans metadata Studio doivent être migrées avant comptage fiable.`

#### Risques de confusion

Compter tout `localEventFlow` comme cinématique mélange hooks monde, scène,
cutscene et logique locale.

#### Non-objectifs

Ne pas prouver le support runtime complet de toutes les actions cinématiques.

#### Tests futurs

- Local flow avec metadata Cutscene Studio : compté.
- Local flow sans metadata : non compté ou "à migrer".
- Plusieurs flows référencés par une step : dédupliqués.

### Quêtes et quêtes annexes

#### Définition utilisateur

Objectifs authorés, principaux ou secondaires, que le créateur pourra un jour
organiser comme contenu de quête.

#### Définition technique recommandée

Pas de définition technique V0 fiable. Le repo contient des signaux historiques
comme `quest.step` ou `questGated`, mais pas de modèle Quest first-class.

#### Source actuelle dans le repo

- Aucun modèle Quest stable identifié.
- Signaux techniques ponctuels : `quest.step`, `ItemPickupMode.questGated`.

#### Formule V0

```text
no real quest count in V0
```

#### Classification

KPI `Quêtes` : `OUT_OF_SCOPE_V0`

Carte `Quêtes annexes` : `EMPTY_STATE_V0`

#### Empty state

`Les quêtes ne sont pas encore modélisées dans PokeMap.`

#### Message si indisponible

`Compteur de quêtes indisponible : aucun modèle Quest authoring n'existe encore.`

#### Risques de confusion

Déduire une quête depuis un flag, un item quest-gated ou une variable runtime
produirait un compteur faux.

#### Non-objectifs

Ne pas inventer une convention temporaire de quête dans ce lot.

#### Tests futurs

- Tant qu'aucun modèle Quest n'existe, le read model retourne une disponibilité
  `unavailable` ou `emptyState`, pas `0 réel`.

### Dialogues et dialogues liés

#### Définition utilisateur

Dialogues écrits et organisés dans le Dialogue Studio, plus les dialogues
référencés par une histoire, une scène ou une step.

#### Définition technique recommandée

V0 minimal : compter `ProjectDialogueEntry`.

V0 enrichi : lire les fichiers Yarn via les use cases existants et compter les
lignes structurées `DeLineStep` / `DeNarrationStep` après parsing
`DialogueEditorDocument`. Les lignes ne doivent pas être déduites du seul nombre
de fichiers.

#### Source actuelle dans le repo

- `ProjectManifest.dialogues`
- `ProjectDialogueEntry.relativePath`
- `DialogueEditorDocument`
- `DialogueEditorNode`
- `DialogueEditorStep`
- `validateDialogueDocument(...)`

#### Formule V0

```text
dialogueDocumentCount = project.dialogues.length
dialogueLineCount = sum(parsedDialogue.steps where line/narration) after file read
linkedDialogues = openDialogue/action references resolved from scenes/steps
```

#### Classification

`AVAILABLE_AFTER_READ_MODEL`

#### Empty state

`Aucun dialogue dans la bibliothèque narrative.`

#### Message si indisponible

`Le nombre de lignes nécessite la lecture des fichiers de dialogue.`

#### Risques de confusion

Afficher `1 236 lignes` sans parser les fichiers Yarn serait un faux compteur.

#### Non-objectifs

Ne pas compter les lignes de code, les nodes techniques ou les messages runtime.

#### Tests futurs

- Projet avec deux `ProjectDialogueEntry` : compteur documents exact.
- Fichier Yarn avec lignes/paroles : compteur lignes exact.
- Fichier absent : diagnostic ou indisponible, pas valeur inventée.

### Problèmes ouverts

#### Définition utilisateur

Éléments que le créateur doit corriger ou revoir avant de considérer le contenu
narratif comme propre.

#### Définition technique recommandée

Agrégat de diagnostics authoring :

- erreurs/warnings de `NarrativeValidationReport` ;
- vues auteur de `NarrativeValidatorAuthoringAdapter` ;
- erreurs/warnings de `DialogueEditorValidation` si les documents sont lus ;
- erreurs de `ProjectValidator` transformées en état global si le manifest ne
  peut pas être validé.

`BetaPlayabilityValidator` est exclu du compteur V0 par défaut, car il répond à
une readiness gameplay beta, pas à la propreté du dashboard auteur. Il pourra
être exposé plus tard dans Project Health avec une source séparée.

#### Source actuelle dans le repo

- `packages/map_core/lib/src/operations/narrative_validator.dart`
- `packages/map_core/lib/src/authoring/narrative_validator_authoring_adapter.dart`
- `packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_validation.dart`
- `packages/map_core/lib/src/validation/validators.dart`

#### Formule V0

```text
openIssues = narrativeDiagnostics + dialogueDiagnostics + manifestValidationIssue
blockingCount = diagnostics where severity == error
reviewCount = diagnostics where severity == warning
```

#### Classification

`AVAILABLE_AFTER_READ_MODEL`

#### Empty state

`Aucun problème ouvert détecté.`

Seulement si un validateur a réellement tourné.

#### Message si indisponible

`Non évalué : lancez la validation pour connaître les problèmes ouverts.`

#### Risques de confusion

Afficher `0` sans validation exécutée revient à dire faux "tout va bien".

#### Non-objectifs

Ne pas mélanger diagnostics runtime, sauvegarde joueur et authoring.

#### Tests futurs

- Diagnostic error : `blockingCount +1`.
- Diagnostic warning : `reviewCount +1`.
- Aucun run validator : statut `Non évalué`, pas `0`.

### Histoire principale : titre, synopsis et action Modifier

#### Définition utilisateur

Résumé éditorial de l'histoire principale du projet : son nom, son synopsis et
le point d'entrée pour modifier ses métadonnées.

#### Définition technique recommandée

Le titre V0 vient du scénario `globalStory` principal. La description vient de
`ScenarioAsset.description`. Une future metadata dédiée pourra remplacer cette
source si le produit a besoin d'un synopsis riche.

L'action `Modifier` doit ouvrir plus tard l'édition des métadonnées de
l'histoire principale ; en V0 data-contract, elle est seulement définie comme
capability conditionnelle.

#### Source actuelle dans le repo

- `ProjectManifest.scenarios`
- `ScenarioAsset.name`
- `ScenarioAsset.description`
- `ScenarioScope.globalStory`

#### Formule V0

```text
mainStory = preferred globalStory scenario
title = mainStory.name
synopsis = mainStory.description
canEdit = mainStory exists
```

#### Classification

`AVAILABLE_AFTER_READ_MODEL`

#### Empty state

`Aucune histoire principale définie.`

#### Message si indisponible

`Créez une storyline globale pour renseigner l'histoire principale.`

#### Risques de confusion

Si plusieurs scénarios `globalStory` existent, le read model doit refuser une
sélection implicite opaque ou choisir une règle documentée.

#### Non-objectifs

Ne pas utiliser `Selbrume` ou le texte de l'image comme synopsis par défaut.

#### Tests futurs

- Un scénario global : titre/description repris.
- Aucun scénario global : empty state.
- Plusieurs scénarios globaux : règle de sélection documentée ou warning.

### États de chapitre et statut global

#### Définition utilisateur

État éditorial d'un chapitre ou de l'univers narratif : `Défini`, `En cours`,
`Brouillon`, `Non évalué`.

#### Définition technique recommandée

Ces états ne sont pas encore des champs persistés. En V0, ils sont dérivés :

- `Brouillon` : chapitre/step existe mais manque des informations minimales ;
- `En cours` : contenu structuré mais diagnostics ou éléments incomplets ;
- `Défini` : contenu structuré sans diagnostic bloquant dans son scope ;
- `Non évalué` : aucune validation ou source insuffisante.

#### Source actuelle dans le repo

- `GlobalStoryChapter`
- `StepStudioStep`
- diagnostics de validation narrative/dialogue

#### Formule V0

```text
chapterStatus = derive from steps in chapter + scoped diagnostics + validation freshness
globalStatus = aggregate(chapterStatus, projectHealth)
```

#### Classification

`AVAILABLE_AFTER_READ_MODEL`

#### Empty state

`Non évalué`

#### Message si indisponible

`Statut éditorial indisponible tant que la validation n'a pas été calculée.`

#### Risques de confusion

`Défini` n'est pas `joué`, `terminé` ou `complété par le joueur`.

#### Non-objectifs

Ne pas écrire ces états comme modèle persistant dans NS-HOME-01.

#### Tests futurs

- Chapitre sans step : `Brouillon`.
- Chapitre avec warning : `En cours` ou `À revoir` selon la surface.
- Validation absente : `Non évalué`.

### Conditions narratives

#### Définition utilisateur

Règles qui disent quand une situation narrative devient active, quand elle se
termine, ou sous quelle condition elle est visible.

#### Définition technique recommandée

Compter les conditions authorées issues de :

- `StepStudioActivationRule` quand le mode porte une dépendance ;
- `StepStudioCompletionRule` quand le mode porte une dépendance ;
- `ScenarioAsset.activationCondition` ;
- `ScenarioNodePayload.condition` ;
- prédicats de visibilité des entités / dialogues conditionnels quand exposés
  au validateur narratif.

#### Source actuelle dans le repo

- `StepStudioStep.activation`
- `StepStudioStep.completion`
- `ScenarioAsset.activationCondition`
- `ScenarioNodePayload.condition`
- `MapEntityRuntimePredicate`
- `NarrativeValidator`

#### Formule V0

```text
conditions = activationDependencies
  + completionDependencies
  + scenarioActivationConditions
  + nodeConditions
  + visibilityPredicates
```

#### Classification

`AVAILABLE_AFTER_READ_MODEL`

#### Empty state

`Aucune condition narrative définie.`

#### Message si indisponible

`Conditions non calculables sans projection narrative.`

#### Risques de confusion

Ne pas compter les valeurs actuelles des flags dans une sauvegarde comme
conditions authorées.

#### Non-objectifs

Ne pas créer un moteur de règles complet.

#### Tests futurs

- Step `afterOutcome` : +1 condition.
- Step `atGameStart` sans dépendance : 0 condition.
- Predicate vide : condition présente + diagnostic.

### Règles du monde

#### Définition utilisateur

Règles authorées qui décrivent comment le monde change ou devient visible selon
la progression narrative.

#### Définition technique recommandée

En V0, compter les `StepStudioWorldChange` et les règles de visibilité
conditionnelles validées par `NarrativeValidator`. Ne pas compter les règles de
gameplay générales, les paramètres runtime, ou l'état réel d'une partie.

#### Source actuelle dans le repo

- `StepStudioStep.worldChanges`
- `MapEntityRuntimePredicate`
- `NarrativeValidationDiagnosticKind.worldRulePredicateEmptyRefId`
- UI Step Studio qui expose `worldChanges`

#### Formule V0

```text
worldRules = step.worldChanges + conditionalVisibilityRules
conflicts = diagnostics where category predicateAuthoring or world rule related
```

#### Classification

`AVAILABLE_AFTER_READ_MODEL`

#### Empty state

`Aucune règle du monde définie.`

#### Message si indisponible

`Règles du monde non calculables sans Step Studio ou validation narrative.`

#### Risques de confusion

Le terme ne doit pas devenir "état du monde joueur". Il s'agit d'intentions
authoring.

#### Non-objectifs

Ne pas modéliser toutes les règles systémiques du fangame.

#### Tests futurs

- Step avec un `worldChanges` : +1 règle du monde.
- Predicate de visibilité vide : diagnostic bloquant.

### Facts

#### Définition utilisateur

Base de connaissances narrative : lieux, personnages, lore, créatures,
éléments d'univers et liens entre eux.

#### Définition technique recommandée

Aucune définition technique fiable en V0. Un registre futur est nécessaire, par
exemple un modèle `Fact` / `LoreEntry` / `NarrativeKnowledgeEntry`.

#### Source actuelle dans le repo

Aucun registre Fact first-class identifié dans `map_core` ou `map_editor`.

#### Formule V0

```text
no real fact count in V0
```

#### Classification

`NEEDS_NEW_MODEL`

#### Empty state

`Les Facts ne sont pas encore modélisés dans ce projet.`

#### Message si indisponible

`Compteur Facts indisponible sans registre de connaissances narrative.`

#### Risques de confusion

Compter characters, maps ou Pokémon comme Facts ferait mentir l'UI.

#### Non-objectifs

Ne pas détourner `characters`, `maps` ou `globalProperties` pour fabriquer des
Facts.

#### Tests futurs

- Tant qu'aucun modèle Fact n'existe, le read model expose `unavailable`.

### Structure narrative : nom, description, tags et compteurs

#### Définition utilisateur

Panneau de résumé de l'univers narratif actif : nom, description auteur, tags,
chapitres et compteurs structurels.

#### Définition technique recommandée

Le nom vient de `ProjectManifest.name`. Les compteurs réutilisent les métriques
contractualisées dans ce rapport. La description et les tags globaux nécessitent
une décision de persistance future ; ils ne doivent pas être tirés de l'image.

#### Source actuelle dans le repo

- `ProjectManifest.name`
- `ProjectManifest.version`
- `ProjectManifest.globalProperties` existe, mais sans convention narrative
  stable pour description/tags.

#### Formule V0

```text
name = project.name
description = unavailable until convention
tags = unavailable until model/convention
structuralCounters = metrics where availability != unavailable
```

#### Classification

Nom : `AVAILABLE_NOW`

Description : `NEEDS_SEMANTIC_DECISION`

Tags : `NEEDS_NEW_MODEL`

Compteurs : `AVAILABLE_AFTER_READ_MODEL`

#### Empty state

`Ajoutez une description narrative pour présenter votre univers.`

`Aucun tag défini.`

#### Message si indisponible

`Métadonnées narratives globales non définies.`

#### Risques de confusion

Utiliser `ProjectManifest.name` comme nom d'univers est acceptable V0, mais
peut diverger plus tard d'un titre narratif plus éditorial.

#### Non-objectifs

Ne pas créer une convention `globalProperties` dans ce lot.

#### Tests futurs

- Projet nommé : nom affichable.
- Aucune description/tags : empty state.
- Future convention metadata : tests de lecture et fallback.

### Statut éditorial : À jour, À revoir, Bloquants

#### Définition utilisateur

Résumé de la santé éditoriale du contenu auteur.

#### Définition technique recommandée

- `À jour` : validation exécutée et aucun diagnostic warning/error dans le
  périmètre du dashboard ;
- `À revoir` : diagnostics non bloquants ou warnings ;
- `Bloquants` : diagnostics de sévérité error ou échec de validation manifest ;
- `Non évalué` : aucun run validator fiable.

#### Source actuelle dans le repo

- `NarrativeValidationSeverity.error/warning`
- `DialogueValidationSeverity.error/warning/info`
- `ProjectValidator.validate(...)`
- `NarrativeAuthoringDiagnosticView`

#### Formule V0

```text
blocking = narrativeErrors + dialogueErrors + manifestValidationFailure
toReview = narrativeWarnings + dialogueWarnings
upToDate = validationRan && blocking == 0 && toReview == 0
notEvaluated = !validationRan
```

#### Classification

`AVAILABLE_AFTER_READ_MODEL`

#### Empty state

`Non évalué`

#### Message si indisponible

`Lancez une validation pour calculer le statut éditorial.`

#### Risques de confusion

`À jour` ne doit jamais signifier que le jeu est jouable, terminé ou sauvegardé.

#### Non-objectifs

Ne pas intégrer l'intégralité du Beta Playability Validator dans ce résumé V0.

#### Tests futurs

- Sans diagnostics mais validation non exécutée : `Non évalué`.
- Validation exécutée sans diagnostics : `À jour`.
- Warning : `À revoir`.
- Error : `Bloquants`.

### Project Health

#### Définition utilisateur

Indicateur compact de santé authoring du projet actif.

#### Définition technique recommandée

Agrégat de disponibilité des données + statut éditorial + erreurs manifest.
Il ne doit pas représenter `isProjectDirty`, `Synchronisé`, `Sauvegardé`, ni
un état runtime.

#### Source actuelle dans le repo

- `ProjectValidator`
- `NarrativeValidator`
- `DialogueEditorValidation`
- `EditorState.isProjectDirty` existe mais ne doit pas alimenter Project Health
  du dashboard auteur.

#### Formule V0

```text
health = red if blocking > 0
health = yellow if toReview > 0 or unavailable core metrics
health = green if validationRan && no diagnostics
health = notEvaluated if validation not run
```

#### Classification

`AVAILABLE_AFTER_READ_MODEL`

#### Empty state

`Non évalué`

#### Message si indisponible

`Project Health non évalué.`

#### Risques de confusion

Le status bar actuel expose sauvegarde/dirty state. Le dashboard ne doit pas le
rebadger comme santé narrative.

#### Non-objectifs

Ne pas devenir un système de notifications global.

#### Tests futurs

- Blocking diagnostic => health red.
- No validator run => not evaluated.
- Dirty project without diagnostics => ne change pas la santé narrative.

### Activité récente

#### Définition utilisateur

Journal d'actions authoring récentes : dialogue modifié, chapitre édité,
problème résolu, fact créé.

#### Définition technique recommandée

Pas de source fiable V0. Les `statusMessage` de l'éditeur sont des messages
éphémères, pas un journal persistant.

#### Source actuelle dans le repo

- `EditorState.statusMessage`
- `EditorNotifier` met à jour des messages de feedback, mais pas un flux
  d'activité durable.

#### Formule V0

```text
no recent activity feed in V0
```

#### Classification

`OUT_OF_SCOPE_V0`

#### Empty state

Si la zone est conservée visuellement plus tard :
`Aucune activité récente enregistrée.`

#### Message si indisponible

`Le journal d'activité n'existe pas encore.`

#### Risques de confusion

Transformer `statusMessage` en activité récente invente un historique faux.

#### Non-objectifs

Ne pas construire un audit log dans ce lot.

#### Tests futurs

- Sans journal réel : liste vide, pas de fausses entrées.
- Futur journal : tri temporel et types authoring uniquement.

### Notifications

#### Définition utilisateur

Alertes auteur importantes, par exemple diagnostics nouveaux ou actions à
traiter.

#### Définition technique recommandée

Pas de source dashboard fiable V0. Le badge de l'image ne doit pas être copié.

#### Source actuelle dans le repo

Pas de système de notifications authoring global identifié. Les overlays runtime
et feedback banners ne sont pas une source valide.

#### Formule V0

```text
no notification count in V0
```

#### Classification

`OUT_OF_SCOPE_V0`

#### Empty state

Bouton masqué ou désactivé.

#### Message si indisponible

`Notifications indisponibles dans cette version.`

#### Risques de confusion

Un badge fictif donne l'impression qu'un système d'alertes existe.

#### Non-objectifs

Ne pas brancher les notifications runtime.

#### Tests futurs

- V0 : aucun badge rendu sans source.

### Recherche

#### Définition utilisateur

Recherche dans le contenu auteur : storylines, scènes, dialogues, règles,
problèmes.

#### Définition technique recommandée

Reporter la recherche V0 de la page d'accueil tant qu'un index authoring n'est
pas défini. Une recherche locale simple pourra utiliser le futur
`NarrativeOverviewReadModel`, mais pas avant.

#### Source actuelle dans le repo

Listes projet (`maps`, `dialogues`, `scenarios`) et projection narrative, mais
pas d'index unifié.

#### Formule V0

```text
search disabled or out of initial page scope
```

#### Classification

`OUT_OF_SCOPE_V0`

#### Empty state

Bouton masqué ou désactivé.

#### Message si indisponible

`Recherche narrative à venir.`

#### Risques de confusion

Une recherche partielle peut masquer des résultats importants.

#### Non-objectifs

Ne pas créer un moteur de recherche global.

#### Tests futurs

- Quand implémentée : recherche sur sources déclarées et résultats typés.

### Footer projet / locale / version

#### Définition utilisateur

Métadonnées neutres du projet et de l'application.

#### Définition technique recommandée

`Projet` peut venir de `ProjectManifest.name`. `Locale` doit attendre une
convention projet ou app. `Version` doit distinguer version d'application,
version du schéma `ProjectVersion`, et version éditoriale du contenu.

#### Source actuelle dans le repo

- `ProjectManifest.name`
- `ProjectManifest.version`
- aucune source locale projet stable identifiée dans ce lot.

#### Formule V0

```text
projectLabel = project.name
localeLabel = unavailable until convention
versionLabel = unavailable unless explicitly mapped to project schema version
```

#### Classification

Projet : `AVAILABLE_NOW`

Locale : `NEEDS_SEMANTIC_DECISION`

Version : `NEEDS_SEMANTIC_DECISION`

#### Empty state

`Locale non définie`

`Version non définie`

#### Message si indisponible

`Métadonnée non configurée.`

#### Risques de confusion

Afficher `v0.3.0` sans source ferait croire à une version produit réelle.

#### Non-objectifs

Ne pas lire une version depuis un chemin local ou depuis la maquette.

#### Tests futurs

- Projet nommé : footer projet OK.
- Locale absente : empty state.
- Version non décidée : pas de valeur inventée.

## 6. Contrat anti-faux-mock

Règles strictes pour les futurs lots :

1. Les nombres de l'image de référence ne doivent jamais être copiés dans le
   code.
2. Aucun compteur ne doit être affiché comme réel sans source calculable.
3. Une donnée absente doit produire un empty state honnête, être marquée
   indisponible, ou être masquée.
4. Les fixtures de test doivent être nommées comme fixtures et ne jamais être
   présentées comme vérité produit.
5. `Selbrume` ne doit pas être hardcodé dans le read model ou les widgets.
6. `Non évalué` doit être préféré à `Validé` si aucun validator n'a tourné.
7. L'activité récente doit rester vide tant qu'il n'existe pas de journal réel.
8. Les notifications doivent rester hors scope tant qu'il n'existe pas de source
   réelle.
9. Le dashboard ne doit pas lire `GameState`, `SaveData` ou des sauvegardes
   runtime.
10. Les données runtime joueur ne doivent jamais être mélangées aux données
    authoring.
11. Les placeholders visuels sont autorisés seulement s'ils affichent clairement
    leur état : `À venir`, `Non disponible`, `Non évalué`, ou `Aucune donnée`.
12. Les compteurs `0` doivent distinguer `0 réel après calcul` et `donnée non
    calculée`.

## 7. Read models futurs recommandés

### NarrativeOverviewReadModel

- Responsabilité exacte : agrégat racine de la page `Aperçu`.
- Porte : identité projet, metrics, histoire principale, modules, panneau
  structure, health, disponibilités et empty states.
- Ne porte pas : style Flutter, données runtime, mocks maquette.
- Package recommandé : `packages/map_editor`, côté application/read model.
- Dépendances : `ProjectManifest`, `NarrativeWorkspaceProjection`, diagnostics.
- Tests futurs : projet vide, projet avec global story, projet avec diagnostics,
  absence de Quest/Facts.
- Ordre de création : créer après ou avec ses sous-modèles V0.

### NarrativeOverviewMetrics

- Responsabilité exacte : normaliser les KPI du haut et leurs états de
  disponibilité.
- Porte : chapitres, scènes, cinématiques, dialogues, problèmes ouverts,
  indisponibilité des quêtes.
- Ne porte pas : libellés visuels riches ou navigation.
- Package recommandé : `packages/map_editor`.
- Dépendances : projection narrative, dialogue loader, diagnostics.
- Tests futurs : chaque compteur réel, indisponible et empty.
- Ordre de création : premier sous-modèle de NS-HOME-02.

### MainStoryOverviewSummary

- Responsabilité exacte : résumé de l'histoire principale.
- Porte : title, synopsis, chapter summaries, linked scene/dialogue counts,
  scoped issues, canEdit.
- Ne porte pas : édition complète de la storyline.
- Package recommandé : `packages/map_editor`.
- Dépendances : scénario global, Global Story Studio, Step Studio, diagnostics.
- Tests futurs : aucun global story, un global story, fallback chapter.
- Ordre de création : après `NarrativeOverviewMetrics`.

### NarrativeModuleSummary

- Responsabilité exacte : décrire chaque carte module de la grille avec son
  état honnête.
- Porte : id, label, count, secondary counts, availability, emptyState,
  destination route future.
- Ne porte pas : widgets de carte.
- Package recommandé : `packages/map_editor`.
- Dépendances : metrics, module-specific projections.
- Tests futurs : Quêtes empty V0, Facts unavailable, dialogues available.
- Ordre de création : avec la grille module V0.

### NarrativeStructureInspectorSummary

- Responsabilité exacte : alimenter le panneau droit.
- Porte : project/narrative name, description availability, tags availability,
  chapter rows, structural counters, global status.
- Ne porte pas : inspector Flutter.
- Package recommandé : `packages/map_editor`.
- Dépendances : project manifest, main story summary, editorial status.
- Tests futurs : description absente, tags absents, counters mixed availability.
- Ordre de création : après `MainStoryOverviewSummary`.

### EditorialStatusSummary

- Responsabilité exacte : agréger validation freshness, `À jour`, `À revoir`,
  `Bloquants`, `Non évalué`.
- Porte : validationRan, blockingCount, reviewCount, infoCount optional,
  statusKind.
- Ne porte pas : diagnostic details complets.
- Package recommandé : `packages/map_editor`, en adaptant les diagnostics de
  `map_core`.
- Dépendances : `NarrativeValidationReport`, dialogue issues, manifest
  validation result.
- Tests futurs : no validation, warnings, errors, clean validation.
- Ordre de création : avant Project Health.

### RecentNarrativeActivitySummary

- Responsabilité exacte : futur flux d'activité authoring.
- Porte : rien en V0, sauf `availability = unavailable`.
- Ne porte pas : `EditorState.statusMessage`.
- Package recommandé : futur, probablement `packages/map_editor`.
- Dépendances : journal persistant à créer plus tard.
- Tests futurs : V0 empty/unavailable ; futur tri et typage.
- Ordre de création : reporté après la page V0.

### NarrativeProjectHealthSummary

- Responsabilité exacte : indicateur compact de santé authoring.
- Porte : healthKind, validationState, blockingCount, reviewCount,
  unavailableCriticalMetrics.
- Ne porte pas : dirty state, sauvegarde, runtime readiness joueur.
- Package recommandé : `packages/map_editor`.
- Dépendances : `EditorialStatusSummary`, metrics availability.
- Tests futurs : red/yellow/green/notEvaluated.
- Ordre de création : après `EditorialStatusSummary`.

## 8. Ordre recommandé des prochains lots

1. `NS-HOME-02 — NarrativeOverviewReadModel V0`
   - Type : data/code/test ciblé.
   - Objectif : créer les modèles de lecture purs côté `map_editor`, sans UI,
     avec fixtures explicites et tests.
   - Critère clé : chaque métrique expose sa disponibilité et n'invente aucune
     valeur.

2. `NS-HOME-03 — Narrative Overview Empty States / Availability Tests`
   - Type : tests/design contract.
   - Objectif : verrouiller tous les états `Non évalué`, `Indisponible`,
     `À venir`, `0 réel`.

3. `NS-HOME-04 — Narrative Overview Shell Placement V0`
   - Type : UI ciblée.
   - Objectif : brancher une destination `Aperçu` dans le shell existant sans
     refaire toute l'application.

4. `NS-HOME-05 — Narrative KPI Cards / Main Story Summary V0`
   - Type : UI + read model integration.
   - Objectif : afficher les KPI autorisés et la carte Histoire principale.

5. `NS-HOME-06 — Narrative Modules Grid / Honest Empty States V0`
   - Type : UI + tests.
   - Objectif : afficher les modules disponibles et les modules empty V0.

6. `NS-HOME-07 — Narrative Structure Inspector / Editorial Status V0`
   - Type : UI + validation summary.
   - Objectif : afficher le panneau droit avec statut éditorial honnête.

7. `NS-HOME-08 — Overview Visual Polish / Responsive Smoke`
   - Type : polish/test.
   - Objectif : rapprocher l'écran de la direction visuelle sans ajouter de
     données fictives.

Premier lot recommandé :

```text
NS-HOME-02 — NarrativeOverviewReadModel V0
```

Justification : le risque principal n'est pas visuel, il est sémantique. Le
read model doit empêcher les widgets futurs d'accéder directement à des listes
brutes et d'inventer des compteurs.

## 9. Risques et garde-fous

| Risque | Garde-fou |
|---|---|
| Big bang UI | Livrer read model, empty states, puis UI par sections. |
| Faux mocks | Interdire chiffres de maquette et exiger source/availability. |
| Données Selbrume hardcodées | Tous les tests doivent utiliser fixtures nommées, pas chemin Selbrume figé. |
| Couplage runtime inutile | Dashboard interdit d'accès à `GameState` / `SaveData`. |
| Modification métier trop tôt | Les modèles manquants restent `NEEDS_NEW_MODEL`. |
| Widgets beaux mais débranchés | Aucun widget sans `NarrativeOverviewReadModel`. |
| Duplication avec Storylines/Scenes/Dialogues | Overview affiche résumé et liens, pas éditeur complet. |
| Confusion authoring/runtime | Libellés auteur uniquement : chapitres, scènes, problèmes, statut éditorial. |
| Compteurs faux | `0 réel` et `indisponible` doivent être différents. |
| Validation simulée | `Non évalué` sans vrai run validator. |
| Activité récente inventée | Section hors V0 jusqu'à journal réel. |
| Notifications inventées | Badge masqué/désactivé jusqu'à source. |

Hors scope explicite de cette page V0 :

- runtime player ;
- save slots ;
- New Game ;
- battle runtime ;
- progression joueur ;
- map painting ;
- cinematic builder détaillé ;
- dialogue editor détaillé ;
- édition complète des storylines ;
- validation complète si elle n'est pas encore branchable ;
- journal d'activité ;
- notifications globales.

## 10. Evidence Pack

### Commandes Git initiales

`git branch --show-current`

```text
main
```

`git status --short --untracked-files=all` initial

```text
Sortie : <vide>
```

`git diff --stat` initial

```text
Sortie : <vide>
```

`git diff --name-only` initial

```text
Sortie : <vide>
```

`git log --oneline -n 10`

```text
6239b5fd docs: add narrative studio UI home overview roadmap proposal
0e2beef8 docs: add Phase 7 narrative studio information architecture and creator journey design
9a95f1b5 docs: add Phase 7 modern app shell and narrative studio UX inventory audit
1de262a2 docs: add Phase 7 roadmap bootstrap and narrative studio modern UI scope audit
1ca0154d docs: add Phase 7 roadmap and P6 checkpoint 01 Selbrume beta slice readiness review
f7612f05 feat(P6-08): add Selbrume playable runtime smoke tests and report
8258c5cb feat(P6-07): add Selbrume beta validator pass tests and report
76820007 feat(P6-06): add Selbrume save/load golden slice tests and report
9ca30c63 docs: add Phase 6 roadmap consistency fix
90899d37 Ajoute P6-05 : Selbrume First Trainer Battle (test et rapport)
```

### Commandes de lecture utilisées

```text
sed -n '1,260p' reports/narrativeStudio/ui/ns_home_00_overview_roadmap_proposal.md
rg -n "no-code|Narrative Studio|map_editor|map_core|Reports|Git|UI|roadmap|Phase 7|authoring|créateur|mocks|runtime" AGENTS.md agent_rules.md "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md"
find reports/narrativeStudio/ui -maxdepth 1 -type f | sort
sed -n '120,220p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '1,220p' packages/map_core/lib/src/models/scenario_asset.dart
sed -n '1,260p' packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
sed -n '260,560p' packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
sed -n '1,260p' packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart
sed -n '260,620p' packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart
sed -n '1,260p' packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart
sed -n '220,520p' packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart
sed -n '1,260p' packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart
sed -n '1,220p' packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_model.dart
sed -n '1,180p' packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_validation.dart
sed -n '1,180p' packages/map_core/lib/src/authoring/narrative_validator_authoring_adapter.dart
sed -n '1,140p' packages/map_core/lib/src/operations/narrative_validator.dart
sed -n '520,620p' packages/map_core/lib/src/operations/narrative_validator.dart
sed -n '1,120p' packages/map_core/lib/src/validation/validators.dart
rg -n "class ProjectDialogueEntry|ProjectDialogueEntry|dialogues|ProjectDialogueFolder" packages/map_core/lib/src/models/project_manifest.dart packages/map_core/lib/src/validation/dialogue_validation.dart packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_validation.dart packages/map_editor/lib/src/application/use_cases/project_dialogue_use_cases.dart
rg -n "class .*Quest|Project.*Quest|FactDescriptor|Project.*Fact|WorldRule|worldChanges|ProjectHealth|RecentNarrative|Recent Activity|Notification|notification|ProjectValidator|NarrativeValidatorAuthoringAdapter|BetaPlayabilityValidator|DialogueEditorValidation|dialogue validation" packages/map_core/lib/src packages/map_editor/lib/src --glob '!**/*.g.dart' --glob '!**/*.freezed.dart' --max-count 20
```

### Fichiers lus/audités

```text
AGENTS.md
agent_rules.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_1.md
reports/narrativeStudio/ui/ns_home_00_overview_roadmap_proposal.md
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/lib/src/authoring/narrative_validator_authoring_adapter.dart
packages/map_core/lib/src/validation/validators.dart
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart
packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart
packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_model.dart
packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_validation.dart
packages/map_editor/lib/src/features/editor/state/editor_state.dart
packages/map_editor/lib/src/ui/shared/status_bar.dart
```

### Changements préexistants

```text
Aucun changement préexistant détecté au Gate 0.
```

### Changements introduits par NS-HOME-01

```text
reports/narrativeStudio/ui/ns_home_01_overview_data_contract.md
```

### Commandes finales

`git status --short --untracked-files=all` final

```text
?? reports/narrativeStudio/ui/ns_home_01_overview_data_contract.md
```

`git diff --stat` final

```text
Sortie : <vide>
```

`git diff --name-only` final

```text
Sortie : <vide>
```

`git diff --check` final

```text
Sortie : <vide>
```

Note : le rapport est un fichier non tracké ; `git diff` ne liste pas les
fichiers non trackés. Le `git status` final montre donc le changement introduit
par NS-HOME-01.

### Confirmations de périmètre

```text
Aucun code de production n'a été modifié.
Aucun widget Flutter n'a été créé.
Aucun modèle Dart n'a été créé.
Aucun read model Dart n'a été créé.
Aucun fichier de packages/map_core n'a été modifié.
Aucun fichier de packages/map_editor n'a été modifié hors rapport.
Aucun fichier de packages/map_runtime n'a été modifié.
Aucun fichier de packages/map_gameplay n'a été modifié.
Aucun fichier de packages/map_battle n'a été modifié.
Aucun test ni analyze lancé, car NS-HOME-01 est design/data-contract only et ne modifie aucun code.
```

## 11. Auto-review critique

Ai-je évité de coder ?

```text
Oui. Aucun code d'application n'a été créé ou modifié.
```

Ai-je évité de créer un widget Flutter ?

```text
Oui. Aucun widget Flutter n'a été créé.
```

Ai-je évité de créer un modèle ou read model Dart ?

```text
Oui. Le rapport recommande des read models futurs sans les créer.
```

Ai-je modifié `map_core`, `map_editor`, `map_runtime`, `map_gameplay` ou
`map_battle` ?

```text
Non. Aucun package de production n'a été modifié.
```

Ai-je défini précisément chaque donnée visible sur l'image ?

```text
Oui. Les KPI, la carte Histoire principale, les modules, le panneau droit,
Project Health, activité récente, notifications, recherche et footer sont
classés.
```

Ai-je refusé les faux compteurs ?

```text
Oui. Quêtes, Facts, activité récente, notifications, locale/version et tags
globaux sont explicitement protégés contre le hardcode.
```

Ai-je évité de hardcoder Selbrume ?

```text
Oui. Le contrat impose `ProjectManifest.name` ou des sources projet, jamais un
nom codé en dur.
```

Ai-je fixé un prochain lot exact unique ?

```text
Oui : NS-HOME-02 — NarrativeOverviewReadModel V0.
```

## 12. Regard critique sur le prompt

Le prompt est pertinent parce qu'il force le point le plus risqué avant l'UI :
la vérité des données. La référence visuelle est forte, mais elle contient des
chiffres séduisants qui deviendraient dangereux s'ils étaient copiés comme
fixtures ou constantes.

Le seul point à surveiller est le volume de concepts encore non stabilisés :
`Scènes`, `Quêtes`, `Facts`, `Tags`, `Notifications` et `Activité récente` ne
doivent pas être traités avec le même niveau de maturité. Le bon chemin est donc
de construire d'abord un read model avec disponibilité explicite, puis seulement
ensuite les widgets.
