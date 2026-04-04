# LOT 65 — Narrative No-Code Studio v1 (Cutscene Studio guidé)

## 1) Résumé exécutif honnête

Ce lot ne prétend pas livrer le studio narratif final complet.  
Il livre un **premier lot à forte valeur produit**: un **Cutscene Studio central, guidé, no-code, orienté blocs** qui remplace une logique trop “graph tech” par une logique “je construis ma scène”.

Le lot respecte explicitement:

- la contrainte UI “**édition principale dans l’îlot central**”;
- la séparation conceptuelle `Global Story / Step / Cutscene`;
- la direction no-code (pickers, templates, labels humains, fallback manuel au lieu d’IDs imposés);
- l’honnêteté produit (mode lecture seule si le scénario sort du périmètre guidé v1).

Le lot **n’implémente pas encore**:

- un éditeur macro visuel complet pour Global Story (board/flowchart riche);
- un Step Studio guidé complet (conditions/validations configurables visuellement);
- un cutscene branching visuel complet type Scratch multi-branches.

Ce lot pose un socle robuste et exploitable immédiatement pour l’authoring cutscene linéaire guidé.

---

## 2) Objectif exact de ce lot

Transformer la couche “cutscene” d’un mode “fiche/graph technique” vers un mode:

- **visuel**
- **guidé**
- **orienté action narrative**
- **accessible non technique**

en gardant une traduction fiable vers le format canonique `ScenarioAsset` existant.

---

## 3) Périmètre traité

### Inclus

- Audit critique du socle narratif existant.
- Proposition produit détaillée (vision cible no-code).
- Implémentation du lot le plus pertinent: **Cutscene Studio Scratch-like v1**.
- Nouvelles mutations scénario dédiées (`create/update/delete`) côté use-cases.
- Intégration workspace central dans `NarrativeWorkspaceCanvas`.
- Tests unitaires authoring + use-cases scénario.

### Hors périmètre (assumé)

- Refonte complète Global Story en canvas macro riche.
- Refonte complète Step Studio en éditeur métier guidé.
- Branching avancé cutscene visuel (choix/branches graphiques complexes).
- Runtime cutscene (ce lot est editor/authoring côté `map_editor`).

---

## 4) Audit critique de l’état initial (avant ce lot)

## 4.1 Points positifs déjà présents

- Le shell central narratif existait déjà (modes `Global Story / Step / Cutscene`).
- Projection narrative déjà en place (`NarrativeWorkspaceProjection`).
- Données canoniques déjà existantes dans `map_core` (`ScenarioAsset`, `ScenarioNode`, `ScenarioEdge`).
- Runtime MVP scénario déjà branché sur un sous-ensemble d’actions.

## 4.2 Limites majeures produit/UX

- `Global Story` et `Step` restaient proches d’une lecture “liste + détails” (peu visuel, peu constructif).
- L’édition cutscene restait trop proche de la structure technique interne.
- L’utilisateur non technique n’avait pas de “flow de création” clair.
- Création/édition scénario pas suffisamment outillée par des use-cases explicites dédiés.
- Trop de risque de confusion entre:
  - “je décris une structure”
  - “je construis réellement une scène jouable”.

## 4.3 Diagnostic produit

La base était techniquement saine, mais l’expérience ne passait pas encore le test:

> “ma mère doit pouvoir l’utiliser”.

La plus forte valeur immédiate était de traiter la couche **Cutscene** d’abord, car c’est là que l’utilisateur manipule concrètement la narration.

---

## 5) Vision produit cible (rappel direction)

## 5.1 Répartition des responsabilités (non négociable)

- `Global Story` = structure macro.
- `Step` = logique de progression locale.
- `Cutscene` = exécution concrète de scène.

## 5.2 Répartition UI (non négociable)

- Gauche = navigation.
- Centre = édition principale.
- Droite = inspection/contextualisation.

## 5.3 Cible no-code

- Créer par templates, blocs, pickers.
- Éviter IDs bruts dans le parcours principal.
- Langage orienté actions lisibles.
- Mode guidé par défaut, fallback manuel explicite.

---

## 6) Choix d’architecture pour ce lot

## 6.1 Stratégie

Livrer une v1 **petite, stable, honnête** plutôt qu’un faux “éditeur total”:

- Flow linéaire guidé uniquement.
- Si scénario hors périmètre v1: lecture seule + explication claire.

## 6.2 Pourquoi ce choix

- Réduit le risque de corruption de graphes avancés.
- Donne une UX no-code immédiatement utilisable.
- Prépare des migrations itératives vers une v2 branching visuel.

## 6.3 Frontières de responsabilité

- `cutscene_studio_authoring.dart`:
  - modèle d’authoring UX
  - parse/compile vers `ScenarioAsset`
- `cutscene_studio_workspace.dart`:
  - UI centrale guidée (templates, pickers, blocs)
- `project_scenario_use_cases.dart`:
  - mutations persistées/validées (create/update/delete)
- `editor_notifier.dart`:
  - orchestration de ces mutations + feedback UX

---

## 7) Implémentation réalisée

## 7.1 Fichier créé

`/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart`

Ajout de use-cases dédiés:

- `CreateProjectScenarioUseCase`
- `UpdateProjectScenarioUseCase`
- `DeleteProjectScenarioUseCase`
- helper `generateUniqueScenarioId(...)`

Rôle:

- mutation métier validée (`ProjectValidator`),
- persistance via `ProjectRepository.saveProject(...)`,
- erreurs explicites (`EditorValidationException`, `EditorConflictException`, `EditorNotFoundException`).

Extrait:

```dart
Future<ProjectManifest> execute(
  ProjectWorkspace workspace,
  ProjectManifest project, {
  required ScenarioAsset scenario,
}) async {
  final id = scenario.id.trim();
  final name = scenario.name.trim();
  if (id.isEmpty) {
    throw const EditorValidationException('Scenario id cannot be empty');
  }
  ...
  ProjectValidator.validate(updated);
  await _repo.saveProject(updated, workspace.projectManifestPath);
  return updated;
}
```

---

## 7.2 Fichier modifié

`/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/use_cases.dart`

Changement:

- export du nouveau module `project_scenario_use_cases.dart`.

---

## 7.3 Fichier créé

`/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/narrative/application/cutscene_studio_authoring.dart`

Ajouts majeurs:

- Contrat de schéma authoring:
  - `kCutsceneStudioSchemaVersion`
  - `kCutsceneStudioSchemaMetadataKey`
- Modèle UX:
  - `CutsceneStudioSourceConfig`
  - `CutsceneStudioBlock`
  - `CutsceneStudioDocument`
- Templates:
  - `npcDialogue`
  - `mapEnterDialogue`
  - `npcScript`
- Parseur:
  - `parseScenarioToCutsceneStudioDocument(...)`
  - accepte uniquement `start -> source -> blocks -> end`
  - marque non éditable si branches/structures avancées
- Compilateur:
  - `buildScenarioFromCutsceneStudioDocument(...)`
  - reconstruit un `ScenarioAsset` canonique linéaire
  - met à jour `declaredOutcomes` depuis blocs `emitOutcome`
  - injecte metadata de version.

Extrait (honnêteté v1):

```dart
if (outgoing.length > 1) {
  warnings.add(
    '$contextLabel a plusieurs sorties: le mode guidé v1 ne gère pas les branches.',
  );
  return null;
}
```

Extrait (compile déterministe):

```dart
nodes.add(const ScenarioNode(id: 'start', type: ScenarioNodeType.start));
nodes.add(ScenarioNode(id: 'source', type: ScenarioNodeType.reference, ...));
...
edges.insert(
  0,
  const ScenarioEdge(
    id: 'edge_start_source',
    fromNodeId: 'start',
    toNodeId: 'source',
    kind: ScenarioEdgeKind.next,
    order: 0,
  ),
);
```

---

## 7.4 Fichier modifié

`/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`

Ajout de méthodes:

- `createProjectScenario(...)`
- `updateProjectScenario(...)`
- `deleteProjectScenario(...)`

Rôle:

- orchestration UI -> use-case,
- mutation `state.project`,
- messages `statusMessage` / `errorMessage`.

---

## 7.5 Fichier créé

`/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart`

Nouveau workspace central guidé:

- État vide + bouton création template.
- Header actions:
  - nouvelle cutscene
  - sauvegarder
  - réinitialiser
  - supprimer
- Section source:
  - type de déclencheur (map enter / trigger enter / entity interact)
  - pickers map/trigger/PNJ
- Section blocs:
  - ajout bloc
  - ordre
  - suppression
  - configuration par type de bloc
- Fallback manuel explicite quand la ressource n’est pas listée.
- Mode lecture seule + warning si scénario hors format v1.

Extrait (sélecteur guidé + fallback manuel):

```dart
if (values.isNotEmpty) {
  final options = <_PickerOption>[
    for (final value in values)
      _PickerOption(value: value, label: valueToLabel(value)),
    const _PickerOption(value: _customPickerSentinel, label: 'Saisir manuellement…'),
  ];
  ...
}
// fallback manuel explicite
final controller = TextEditingController(text: currentValue ?? '');
```

---

## 7.6 Fichier modifié

`/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`

Changement:

- remplacement du panneau cutscene “liste + fiche” par `CutsceneStudioWorkspace` en zone centrale.

Impact:

- la cutscene devient enfin un véritable espace d’édition principal.

---

## 7.7 Tests créés

1. `/Users/karim/Project/pokemonProject/packages/map_editor/test/cutscene_studio_authoring_test.dart`
2. `/Users/karim/Project/pokemonProject/packages/map_editor/test/project_scenario_use_cases_test.dart`

Couverture:

- parse flow linéaire => editable
- parse flow branché => non editable
- compile document => scénario canonique
- create/update/delete scénario persistés correctement

---

## 8) UX livrée maintenant (concrètement)

Un utilisateur peut maintenant:

1. ouvrir le workspace **Cutscene** au centre;
2. créer une cutscene via template guidé;
3. choisir map/PNJ/dialogue/script via pickers;
4. ajouter des blocs de scène (dialogue/script/flag/outcome);
5. réordonner/supprimer/sauvegarder;
6. rester protégé contre l’édition destructive des graphes non compatibles v1.

---

## 9) Validation exécutée

## 9.1 Format

Commande:

```bash
dart format \
  packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart \
  packages/map_editor/lib/src/application/use_cases/use_cases.dart \
  packages/map_editor/lib/src/features/editor/state/editor_notifier.dart \
  packages/map_editor/lib/src/features/narrative/application/cutscene_studio_authoring.dart \
  packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart \
  packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart \
  packages/map_editor/test/cutscene_studio_authoring_test.dart \
  packages/map_editor/test/project_scenario_use_cases_test.dart
```

Résultat:

- `Formatted 8 files (0 changed)`

## 9.2 Analyze ciblé

Commande (dans `packages/map_editor`):

```bash
flutter analyze \
  lib/src/application/use_cases/project_scenario_use_cases.dart \
  lib/src/application/use_cases/use_cases.dart \
  lib/src/features/editor/state/editor_notifier.dart \
  lib/src/features/narrative/application/cutscene_studio_authoring.dart \
  lib/src/ui/canvas/cutscene_studio_workspace.dart \
  lib/src/ui/canvas/narrative_workspace_canvas.dart \
  test/cutscene_studio_authoring_test.dart \
  test/project_scenario_use_cases_test.dart
```

Résultat:

- `No issues found!`

## 9.3 Tests ciblés

Commande (dans `packages/map_editor`):

```bash
flutter test \
  test/cutscene_studio_authoring_test.dart \
  test/project_scenario_use_cases_test.dart \
  test/narrative_workspace_projection_test.dart \
  test/narrative_workspace_state_test.dart \
  test/editor_notifier_npc_waypoint_placement_test.dart
```

Résultat:

- `All tests passed!`

## 9.4 Analyze global package

Commande:

```bash
flutter analyze
```

Résultat:

- échec global (issues préexistantes, principalement deprecations/providers + warnings divers hors périmètre de ce lot).
- Aucun nouvel échec bloquant détecté sur les fichiers de ce lot.

---

## 10) Limites connues et honnêteté produit

1. Cutscene Studio v1 est **linéaire** (pas de branches visuelles riches).
2. Les scénarios complexes sont volontairement en lecture seule dans ce studio.
3. `Global Story` et `Step` restent encore des surfaces majoritairement informatives (pas encore “studio visuel” complet).
4. Certaines entrées conservent un fallback manuel (utile, mais moins no-code que le chemin idéal).

---

## 11) Plan d’implémentation recommandé par lots (suite)

## Lot 66 — Cutscene Studio v2 (branches locales visuelles)

- blocs `Choice` + branches visuelles `Oui/Non` ou multi-réponses
- convergence explicite
- diagnostics de cohérence de branche

## Lot 67 — Step Studio guidé

- sections métier éditables (entrée, validation, outcomes, transitions)
- assistants “ajouter condition” en langage naturel
- liaison guidée vers cutscenes

## Lot 68 — Global Story board macro

- cartes de steps dans un board central
- liens visuels de progression
- branches/convergences lisibles
- outcomes globaux visibles sur les transitions

## Lot 69 — Templates + assistants narratifs

- “Créer Step” wizard
- “Créer Cutscene” wizard enrichi (squelettes selon type de scène)
- templates no-code prêts à l’emploi

## Lot 70 — Connexion map-aware visuelle

- sélection de destination de mouvement par clic map (pas X/Y manuel)
- sélection PNJ/dialogue contextuelle par map
- feedback visuel de ciblage

---

## 12) Risques et vigilance

1. **Risque de régression vers du tech-first**:
   - contrer via labels orientés action et pickers systématiques.
2. **Risque d’édition destructive de graphes avancés**:
   - maintenir l’honnêteté lecture seule tant que v2 n’est pas prête.
3. **Risque de divergence modèle UX / runtime**:
   - garder la compilation centralisée dans `cutscene_studio_authoring.dart`.

---

## 13) État git final (aucune écriture git)

Fichiers modifiés:

- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/use_cases.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`

Fichiers créés:

- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/narrative/application/cutscene_studio_authoring.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/cutscene_studio_authoring_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/project_scenario_use_cases_test.dart`
- `/Users/karim/Project/pokemonProject/reports/lots/lot_65_narrative_no_code_cutscene_studio_v1/LOT_65_NARRATIVE_NO_CODE_CUTSCENE_STUDIO_V1_REPORT.md`

Aucun commit, amend, merge, rebase, push, tag, reset ou écriture Git n’a été effectué.

---

## 14) Conclusion

Ce lot fait passer la couche cutscene d’un mode “structure technique” à un mode “construction de scène guidée no-code” dans l’îlot central, avec une base propre pour itérer vers:

- un Step Studio réellement guidé,
- un Global Story board macro visuel,
- et un Cutscene Studio branching complet.

Le résultat est volontairement progressif, mais déjà utilisable, honnête et aligné avec la vision produit no-code.
