# LOT 64 — Socle des workspaces narratifs centraux (Global Story / Step / Cutscene)

## 1. Résumé exécutif

Ce lot met en place un **socle produit + technique** pour intégrer la narration comme un outil de premier plan dans `map_editor`, en respectant strictement la contrainte centrale:

- **Global Story**, **Step** et **Cutscene** sont désormais traités comme des **workspaces centraux**.
- La colonne gauche sert à la **navigation narrative**.
- La colonne droite sert à l’**inspection contextuelle narrative**.

Le lot n’implémente pas encore un éditeur narratif final complet (graph editing avancé), mais pose une architecture propre et scalable pour y arriver.

---

## 2. Besoin produit reformulé

Le besoin n’est pas “ajouter un panneau scénario”, mais:

1. Séparer clairement les niveaux:
   - **Global Story** (macro progression)
   - **Step** (logique de progression locale)
   - **Cutscene** (exécution de scène)
2. Imposer que ces niveaux vivent dans l’**îlot central** (workspace principal).
3. Garder la cohérence shell existante:
   - gauche = navigation
   - centre = édition principale
   - droite = inspection
4. Préparer une base maintenable pour les prochains lots narratifs.

---

## 3. Audit initial (avant implémentation)

État observé:

- `EditorWorkspaceMode` n’exposait que `map` + `tileset`.
- `EditorCanvasHost` ne supportait que `MapCanvas` et `TilesetEditorCanvas`.
- `EditorShellPage` avait des switches uniquement map/tileset (titre central, teinte, panneau droit).
- `TopToolbar` n’avait pas d’entrée workspace narrative.
- `ProjectExplorerPanel` n’avait pas de navigateur narratif dédié.
- Le modèle `map_core` possède déjà `ScenarioAsset` + `ScenarioScope`, donc la donnée narrative existe.

Conclusion:

- Le shell était prêt pour des workspaces centraux supplémentaires.
- Il manquait une couche de projection + état narratif dédiée + surfaces UI associées.

---

## 4. Architecture retenue

### 4.1 Découpage

Nouveau découpage introduit dans `map_editor`:

- `features/narrative/application/`
  - projection des données narratives orientée UI
- `features/narrative/state/`
  - état/contrôleur de navigation et sélection narrative
  - provider de projection
- `ui/canvas/`
  - workspace central narratif
- `ui/panels/`
  - panneau gauche de navigation narrative
  - panneau droit d’inspection narrative

### 4.2 Frontières de responsabilité

- `EditorState` conserve le rôle shell global + mode workspace actif.
- L’état de sélection narrative détaillée est **séparé** dans un contrôleur dédié.
- La projection narrative est **read-only** sur `ProjectManifest`.
- Les widgets gauche/centre/droite consomment la **même projection** pour éviter les incohérences.

---

## 5. Modèle de données UI narratif ajouté

Fichier:
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`

Objets introduits:

- `NarrativeScenarioSummary`
- `NarrativeStepSummary`
- `NarrativeOutcomeSummary`
- `NarrativeWorkspaceProjection`
- `NarrativeOutcomeScope`

Point clé:

- La couche `Step` est projetée depuis les données existantes:
  - base = scénarios `scope=globalStory`
  - enrichissement optionnel via metadata `step.*` (`step.id`, `step.name`, `step.description`, `step.cutsceneIds`)

Extrait:

```dart
enum NarrativeOutcomeScope { local, global, mixed, unknown }

NarrativeWorkspaceProjection buildNarrativeWorkspaceProjection(
  ProjectManifest project,
) { ... }
```

---

## 6. État narratif ajouté

Fichiers:

- `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart`

Ajouts:

- `NarrativeWorkspaceView { globalStory, step, cutscene }`
- `NarrativeWorkspaceState` (sélections courantes)
- `NarrativeWorkspaceController` (API explicite de navigation)
- `narrativeWorkspaceProjectionProvider` (projection centralisée)

Extrait:

```dart
final narrativeWorkspaceControllerProvider = StateNotifierProvider<
    NarrativeWorkspaceController, NarrativeWorkspaceState>(
  (ref) => NarrativeWorkspaceController(),
);
```

---

## 7. Intégration shell (gauche / centre / droite)

## 7.1 Workspace modes étendus

Fichier:
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`

Ajout de:

- `EditorWorkspaceMode.globalStory`
- `EditorWorkspaceMode.step`
- `EditorWorkspaceMode.cutscene`

### 7.2 Navigation workspace

Fichier:
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`

Ajout de méthodes explicites:

- `selectGlobalStoryWorkspace()`
- `selectStepWorkspace()`
- `selectCutsceneWorkspace()`

### 7.3 Centre

Fichiers:

- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`

Comportement:

- Si workspace narratif actif, le centre affiche `NarrativeWorkspaceCanvas`.
- Le canvas central expose:
  - un switch mode (`Global Story / Step / Cutscene`)
  - une colonne de sélection
  - une surface principale de détail/édition conceptuelle

### 7.4 Droite

Fichiers:

- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/lib/src/ui/panels/narrative_inspector_panel.dart`

Comportement:

- En mode narratif, la colonne droite affiche `NarrativeInspectorPanel`.
- Le panneau droit reste un inspecteur contextuel, pas l’éditeur principal.

### 7.5 Gauche

Fichiers:

- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart`

Comportement:

- Nouvelle section `Narrative Studio` dans l’explorer.
- Liste:
  - Global Story graphs
  - Steps
  - Cutscenes
  - Outcomes
- Les clics ouvrent le **workspace central correspondant**.

---

## 8. Détails UX importants

1. Le centre est désormais explicitement le lieu d’édition narrative.
2. Le panneau gauche devient navigateur narratif (et non éditeur caché).
3. Le panneau droit conserve son rôle d’inspection.
4. Les trois niveaux (global/step/cutscene) sont visibles et navigables.
5. Les outcomes sont exposés comme objets de navigation et de relation.

---

## 9. Fichiers modifiés

- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`

## 10. Fichiers créés

- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/panels/narrative_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart`
- `packages/map_editor/test/narrative_workspace_projection_test.dart`
- `packages/map_editor/test/narrative_workspace_state_test.dart`

---

## 11. Validations exécutées

### Format

Commande exécutée:

```bash
dart format <fichiers modifiés/créés map_editor>
```

### Analyze ciblé

Commande exécutée:

```bash
cd packages/map_editor && flutter analyze \
  lib/src/features/narrative \
  lib/src/ui/canvas/editor_canvas_host.dart \
  lib/src/ui/canvas/narrative_workspace_canvas.dart \
  lib/src/ui/editor_shell_page.dart \
  lib/src/ui/panels/project_explorer_panel.dart \
  lib/src/ui/panels/narrative_inspector_panel.dart \
  lib/src/ui/panels/narrative_library_panel.dart \
  lib/src/ui/shared/top_toolbar.dart \
  lib/src/features/editor/state/editor_state.dart \
  lib/src/features/editor/state/editor_notifier.dart \
  test/narrative_workspace_projection_test.dart \
  test/narrative_workspace_state_test.dart
```

Résultat: **No issues found**.

### Tests ciblés

Commande exécutée:

```bash
cd packages/map_editor && flutter test \
  test/editor_notifier_npc_waypoint_placement_test.dart \
  test/narrative_workspace_projection_test.dart \
  test/narrative_workspace_state_test.dart
```

Résultat: **All tests passed**.

---

## 12. Limites actuelles (honnêtes)

1. La projection `Step` est une couche de transition UI; le modèle canonique `Step` n’est pas encore persisté comme entité dédiée.
2. Le workspace central narratif est un socle orienté structure/navigation; pas encore un éditeur graphe complet de cutscene.
3. Les interactions d’édition profonde (CRUD step/cutscene dédiés) devront être implémentées dans un lot suivant.

---

## 13. Prochaines étapes recommandées

1. Introduire un modèle de données `StepAsset` explicite (persisté).
2. Ajouter des use cases narratifs dédiés (CRUD global story / step / cutscene).
3. Faire évoluer `NarrativeWorkspaceCanvas` vers un vrai éditeur flow pour `Cutscene`.
4. Ajouter diagnostics narratifs (branches mortes, outcomes non consommés, step inatteignables).
5. Aligner runtime/authoring pour matérialiser l’exécutabilité depuis ces workspaces.

---

## 14. État Git final (ce lot)

Ce lot a été réalisé **sans commit / amend / merge / rebase / push / tag**.

Statut final observé (`git status --short`):

- fichiers modifiés: 6
- fichiers créés: 8

Le détail exact est visible dans l’état du working tree local.
