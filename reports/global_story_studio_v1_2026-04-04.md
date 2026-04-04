# Global Story Studio v1 - Lot Produit + Technique
Date: 2026-04-04  
Scope: `packages/map_editor`  
Contrainte respectee: aucune operation Git destructive/ecriture historique (`commit`, `amend`, `merge`, `rebase`, `push`, `tag`, `stash`, etc.) n'a ete executee.

## 1) Resume executif
Ce lot implemente un **Global Story Studio v1** dans l'ilot central, avec une separation stricte:

- Global Story = structure macro (ordre, branches, convergences, point de depart).
- Step = logique metier locale (activation, completion, outcomes, changements monde).
- Cutscene = execution de scene (dialogs, mouvements, transitions, etc.).

Le resultat livre:

- un nouveau document d'authoring **Global Story** dedie (metadata scenario global unique),
- un nouveau workspace central **GlobalStoryStudioWorkspace** no-code/low-code (cartes, dropdowns, edition inline),
- une integration propre dans `NarrativeWorkspaceCanvas`,
- des tests logiques + widget,
- `flutter analyze` cible sans issue.

## 2) Besoin reformule
Le besoin produit etait de rendre enfin la couche Global Story:

- unique (un seul scenario global canonique),
- lisible macro (plan narratif),
- editable sans ids techniques saisis a la main,
- non-confondue avec Step Studio et Cutscene Studio,
- utilisable par un profil non-developpeur.

## 3) Analyse du probleme initial
Avant ce lot:

- Le mode Global Story dans le centre etait surtout un placeholder detail-card.
- Il manquait une structure macro editable des transitions entre steps.
- La navigation etait presente, mais l'edition globale de la progression etait trop pauvre.
- La distinction produit "Global Story vs Step vs Cutscene" existait dans le discours, mais pas suffisamment dans l'outillage central.

## 4) Decisions d'architecture
### 4.1 Nouveau document canonique Global Story (metadata)
Creation d'un document dedie:

- `GlobalStoryStudioDocument`
- `GlobalStoryStepNode`
- `GlobalStoryStepLink`
- `GlobalStoryStepExitMode`

Stockage metadata sur le scenario global unique:

- `authoring.globalStoryStudioSchema`
- `authoring.globalStoryStudioDocument`

### 4.2 Separation stricte des responsabilites
- **StepStudioDocument** reste la source de verite des fiches step (identite + logique locale).
- **GlobalStoryStudioDocument** porte uniquement la structure macro (liens entre steps + entry step + type de sortie).
- Aucune logique d'execution cutscene n'a ete deplacee dans Global Story.

### 4.3 Compatibilite et fallback doux
Si le document Global Story n'existe pas:

- reconstruction automatique d'un flux lineaire depuis l'ordre des steps.

Si le document est invalide/partiel:

- normalisation defensive (liens invalides supprimes, entry corrigee, dedup).

### 4.4 Guardrails techniques
Les invariants sont imposes via normalisation:

- une seule entree valide,
- un noeud max par step,
- cibles de liens existantes seulement,
- pas de self-link,
- mode lineaire/convergence borne a une destination.

## 5) UX implementee (ilot central)
Nouveau workspace central Global Story:

- panneau gauche: navigation des steps globales,
- surface centrale: cartes de progression macro + connecteurs textuels,
- edition inline (pas d'alerte systeme pour les operations principales),
- actions metier:
  - inserer step,
  - supprimer step,
  - renommer/decrire step,
  - marquer step de depart,
  - definir mode de sortie (lineaire / branche exclusive / branche conditionnelle / convergence),
  - ajouter/retirer destinations,
  - ouvrir la step dans Step Studio.

## 6) Fichiers crees / modifies
### Crees
- `packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart`
- `packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart`
- `packages/map_editor/test/global_story_studio_authoring_test.dart`
- `packages/map_editor/test/global_story_studio_workspace_test.dart`

### Modifies
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart` (const hygiene lint)

## 7) Extraits de code importants + explication
## 7.1 Modele Global Story dedie
Fichier: `packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart`

```dart
enum GlobalStoryStepExitMode {
  linear,
  branchExclusive,
  branchConditional,
  converge,
}
```

Ce mode encode le type de sortie macro d'une step, sans toucher a la logique locale Step/Cutscene.

```dart
class GlobalStoryStudioDocument {
  const GlobalStoryStudioDocument({
    required this.globalStoryScenarioId,
    required this.entryStepId,
    required this.nodes,
    this.schemaVersion = kGlobalStoryStudioSchemaVersion,
  });
  ...
}
```

Le document est explicitement lie au scenario global unique.

## 7.2 Parse + fallback + normalisation
```dart
GlobalStoryStudioParseResult parseGlobalStoryStudioDocumentFromGlobalScenario(
  ScenarioAsset scenario, {
  required StepStudioDocument stepDocument,
}) { ... }
```

Pipeline:
1. parse metadata si presente,  
2. fallback lineaire sinon,  
3. normalisation stricte,  
4. diagnostics exploitables UI.

## 7.3 Application non destructive au scenario
```dart
ScenarioAsset applyGlobalStoryStudioDocumentToGlobalScenario(
  ScenarioAsset scenario,
  GlobalStoryStudioDocument document, {
  required StepStudioDocument stepDocument,
}) { ... }
```

La mutation reste metadata-centric (authoring), sans casser le graphe runtime existant.

## 7.4 Nouveau workspace central
Fichier: `packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart`

```dart
class GlobalStoryStudioWorkspace extends StatefulWidget { ... }
```

Points cle:

- hydration depuis scenario global unique,
- edition draft locale,
- save/reset explicites,
- edition inline des liens macro,
- callbacks de selection deferres apres frame (provider-safe).

## 7.5 Branchement du workspace dans la toile narrative
Fichier: `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`

```dart
EditorWorkspaceMode.globalStory => GlobalStoryStudioWorkspace(...)
```

L'ancien body detail-only a ete retire pour laisser place a un vrai studio central.

## 8) Invariants metier assures
- Un seul Global Story "canonique" est edite (premier scenario global detecte).
- Global Story ne porte pas l'execution de scene.
- Step garde sa logique locale.
- Cutscene garde la mise en scene.
- Les liens macro ne peuvent plus pointer vers des steps inconnues apres normalisation.
- Le point de depart global est toujours valide (ou recale automatiquement).

## 9) Ce qui a ete volontairement non change
- Aucune refonte de Cutscene Studio.
- Aucune migration destructive du graphe runtime scenario nodes/edges.
- Aucune operation Git.
- Aucun changement d'architecture shell gauche/centre/droite.
- Pas de transformation de Step Studio en graph abstrait.

## 10) Validations executees
### Format
```bash
/opt/homebrew/Caskroom/flutter/3.38.4/flutter/bin/dart format \
  packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart \
  packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart \
  packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart \
  packages/map_editor/test/global_story_studio_authoring_test.dart \
  packages/map_editor/test/global_story_studio_workspace_test.dart
```

### Tests cibles
```bash
cd packages/map_editor
/opt/homebrew/Caskroom/flutter/3.38.4/flutter/bin/flutter test \
  test/global_story_studio_authoring_test.dart \
  test/global_story_studio_workspace_test.dart \
  test/narrative_workspace_projection_test.dart \
  test/narrative_workspace_state_test.dart \
  test/step_studio_workspace_regression_test.dart
```

Resultat: **All tests passed**.

### Analyze cible
```bash
cd packages/map_editor
/opt/homebrew/Caskroom/flutter/3.38.4/flutter/bin/flutter analyze \
  lib/src/ui/canvas/narrative_workspace_canvas.dart \
  lib/src/ui/canvas/global_story_studio_workspace.dart \
  lib/src/features/narrative/application/global_story_studio_authoring.dart \
  lib/src/features/narrative/application/narrative_workspace_projection.dart \
  lib/src/features/narrative/state/narrative_workspace_state.dart \
  lib/src/features/narrative/state/narrative_workspace_providers.dart \
  lib/src/ui/panels/narrative_library_panel.dart \
  lib/src/ui/panels/narrative_inspector_panel.dart \
  test/global_story_studio_authoring_test.dart \
  test/global_story_studio_workspace_test.dart
```

Resultat: **No issues found**.

## 11) Limites restantes (honnetes)
- La representation visuelle est un flow vertical "cards + connecteurs textuels", pas encore un canvas graph libre.
- Les diagnostics sont utiles mais encore v1 (pas de detection avancee de cycles complexes multibranches).
- Le mode "convergence" est modele cote sortie de step (simple pour v1), pas encore avec un outillage dedie des convergences entrantes.
- Les metadata historiques multi-global-story ne sont pas migrees automatiquement; le studio reste volontairement focalise sur la source canonique unique.

## 12) Prochaines etapes recommandees
1. Ajouter une vue "mini-map du plan global" (overview).  
2. Ajouter diagnostics UX plus riches (cycles involontaires, branchements incomplets).  
3. Ajouter un panneau de "regles de passage" plus explicite (outcome-based routing guide).  
4. Introduire, en v2, une edition visuelle plus graphique si necessaire (tout en gardant la lisibilite no-code).

## 13) Hypotheses explicites
- L'ordre des steps reste porte par `StepStudioDocument.order` (source canonique de sequence).
- La structure macro entre steps est portee par `GlobalStoryStudioDocument`.
- Le premier scenario `scope=globalStory` est la source canonique en cas de donnees historiques multiples.
