# NS-STORYLINES-02 — Current Global Story Characterization / Anti-Fake Tests V0

## 1. Executive summary

NS-STORYLINES-02 ajoute un test de caractérisation ciblé sur l'ancien `Global Story Studio`.

Résultat :

- l'écran `EditorWorkspaceMode.globalStory` reste accessible via `NarrativeWorkspaceCanvas > NarrativeStudioShell > GlobalStoryStudioWorkspace` ;
- les valeurs visibles testées viennent d'une fixture neutre `ScenarioAsset` / metadata authoring, pas des images cible Storylines ;
- les données cible interdites (`La brume du phare`, quêtes annexes cible, tags cible, `412`, `18`, etc.) ne sont pas rendues quand la fixture ne les contient pas ;
- `localEventFlow` reste séparé du `globalStory` et n'est pas présenté comme quête annexe ;
- `Maps` reste absent de la sidebar interne Narrative Studio ;
- aucun code production, modèle, widget ou design system n'a été modifié.

Statut recommandé : `DONE`.

Prochain lot recommandé : `NS-STORYLINES-03 — Storylines Workspace Shell Layout V0`.

## 2. Inputs read

Fichiers gouvernance / rapports lus :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/storylines/road_map_storylines.md`
- `reports/narrativeStudio/storylines/ns_storylines_00_current_state_target_gap_audit.md`
- `reports/narrativeStudio/storylines/ns_storylines_01_read_model_data_contract_v0.md`
- `reports/narrativeStudio/ui/ns_home_checkpoint_narrative_overview_acceptance_v0.md`
- `reports/narrativeStudio/ui/ns_home_15_internal_shell_sidebar_architecture.md`

Fichiers code inspectés en lecture seule :

- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart`
- `packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_studio_shell.dart`
- `packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_studio_panels.dart`
- `packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_flow_layout.dart`
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart`
- `packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart`
- `packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart`
- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/models/script_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`

Tests existants lus :

- `packages/map_editor/test/global_story_studio_workspace_test.dart`
- `packages/map_editor/test/global_story_studio_ux_test.dart`
- `packages/map_editor/test/global_story_studio_authoring_test.dart`
- `packages/map_editor/test/global_story_studio_behavior_test.dart`
- `packages/map_editor/test/narrative_workspace_projection_test.dart`

Fichiers attendus absents : aucun parmi la liste obligatoire NS-STORYLINES-02.

## 3. Tests added or modified

Fichier de test créé :

- `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`

Aucun test existant n'a été modifié.

Le test créé contient deux cas :

1. widget test : rend l'ancien Global Story Studio avec une fixture neutre et vérifie les données visibles / absentes ;
2. unit test : vérifie que la projection sépare `globalStory`, `localEventFlow` et steps.

## 4. Characterized current behavior

Comportement verrouillé :

```text
EditorWorkspaceMode.globalStory
→ NarrativeWorkspaceCanvas
→ NarrativeStudioShell
→ GlobalStoryStudioWorkspace
```

L'écran courant affiche encore :

- `Storylines` dans le shell Narrative Studio ;
- la story globale issue du `ScenarioAsset.name` ;
- le chapitre issu de `GlobalStoryStudioDocument.chapters` ;
- la step issue de `StepStudioDocument.steps` ;
- les surfaces legacy `STRUCTURE`, `Votre récit`, `FIL NARRATIF`, `Progression globale`, `DÉTAIL DE L'ÉTAPE`.

Caractérisation importante : `ScenarioAsset.description` est disponible dans `NarrativeWorkspaceProjection`, mais l'ancien écran Global Story Studio ne la rend pas encore. Le test verrouille ce comportement au lieu de le corriger dans ce lot.

## 5. Anti-fake guarantees

La fixture positive utilise uniquement des noms neutres :

- `Audit Story From Scenario`
- `Audit description from scenario`
- `Audit Chapter From Metadata`
- `Audit Step From Metadata`
- `Audit Step Detail From Metadata`
- `Audit Local Event Flow`

Les chaînes cible suivantes sont assertées absentes :

- `La brume du phare`
- `Les cristaux de sel`
- `Le Goélise du port`
- `La cabane du phare`
- `Mystère`
- `Exploration`
- `Phare`
- `Côtiers`
- `412`
- `18`
- `RÈGLES DU MONDE AFFECTÉES`
- `DERNIÈRE ACTIVITÉ`

Le test évite donc de transformer les images cible Storylines en données produit.

## 6. GlobalStory / ScenarioAsset source guarantees

La fixture crée un `ScenarioAsset(scope: ScenarioScope.globalStory)` :

- `id: audit_global_story`
- `name: Audit Story From Scenario`
- `description: Audit description from scenario`

La metadata authoring appliquée au scénario contient :

- `GlobalStoryStudioDocument.globalStoryScenarioId: audit_global_story`
- `GlobalStoryChapter.name: Audit Chapter From Metadata`
- `StepStudioStep.name: Audit Step From Metadata`
- `StepStudioStep.description: Audit Step Detail From Metadata`

Le widget test prouve que les valeurs rendues proviennent de ce projet de test.

Le unit test prouve aussi que `buildNarrativeWorkspaceProjection(project)` expose :

- une seule `globalStories.single.id == audit_global_story` ;
- la description du scénario dans la projection ;
- la step issue des metadata ;
- un `localEventFlow` séparé.

## 7. localEventFlow / side quest guardrail

Le test ajoute volontairement un scénario :

```text
ScenarioAsset(scope: ScenarioScope.localEventFlow, name: Audit Local Event Flow)
```

Garantie :

- la projection contient bien ce `localEventFlow` ;
- l'ancien écran Global Story Studio ne l'affiche pas comme quête annexe Storylines ;
- le raccourci `localEventFlow = quête annexe` reste bloqué par test.

## 8. Sidebar / Maps guardrail

Le widget test vérifie :

- `narrative-studio-sidebar` visible ;
- `Storylines` visible ;
- `Facts`, `Règles du monde`, `Validateur` visibles comme entrées internes existantes ;
- `Maps` absent de la sidebar interne.

Cette preuve protège la décision NS-HOME :

```text
ProjectExplorerPanel global ≠ NarrativeStudioSidebar interne
```

## 9. Actions characterized

Actions legacy caractérisées, sans suppression ni activation nouvelle :

- `Réinitialiser`
- `Tester`
- `Valider`
- `+ Nouvelle étape`

Action future Storylines observée dans le header interne :

- `Nouvelle storyline`

Le test ne clique aucune action mutatrice. Il caractérise leur présence actuelle et évite de confondre les actions legacy Global Story Studio avec les futures actions Storylines V0.

## 10. Design System Gate

Design System Gate respecté :

- aucun widget UI de production créé ;
- aucun fichier de production modifié ;
- aucune couleur ajoutée ;
- aucun `Color(0x...)` ajouté ;
- aucun `Colors.*` ajouté ;
- aucun composant feature local créé ;
- aucune primitive design system modifiée.

## 11. Roadmap update

Roadmap mise à jour dans :

- `reports/narrativeStudio/storylines/road_map_storylines.md`

Changements :

- `NS-STORYLINES-02` marqué `DONE` ;
- résumé du test de caractérisation ajouté ;
- fichiers créés/modifiés listés ;
- tests et analyse ciblée listés ;
- Design System Gate confirmé ;
- absence de fake data confirmée ;
- prochain lot recommandé : `NS-STORYLINES-03 — Storylines Workspace Shell Layout V0`.

## 12. Commands run

### Commandes Git initiales

```bash
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Sorties exactes initiales :

```text
main

---STATUS---

---DIFF STAT---

---DIFF NAME ONLY---

---DIFF CHECK---
```

### Vérification des fichiers attendus

```bash
for f in AGENTS.md agent_rules.md skills/README.md reports/narrativeStudio/storylines/road_map_storylines.md reports/narrativeStudio/storylines/ns_storylines_00_current_state_target_gap_audit.md reports/narrativeStudio/storylines/ns_storylines_01_read_model_data_contract_v0.md reports/narrativeStudio/ui/ns_home_checkpoint_narrative_overview_acceptance_v0.md reports/narrativeStudio/ui/ns_home_15_internal_shell_sidebar_architecture.md packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_studio_shell.dart packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_studio_panels.dart packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_flow_layout.dart packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart packages/map_core/lib/src/models/scenario_asset.dart packages/map_core/lib/src/models/script_asset.dart packages/map_core/lib/src/models/project_manifest.dart packages/map_editor/test/global_story_studio_workspace_test.dart packages/map_editor/test/global_story_studio_ux_test.dart packages/map_editor/test/global_story_studio_authoring_test.dart packages/map_editor/test/global_story_studio_behavior_test.dart packages/map_editor/test/narrative_workspace_projection_test.dart; do if [ -f "$f" ]; then printf 'FOUND %s\n' "$f"; else printf 'MISSING %s\n' "$f"; fi; done
```

Sortie exacte :

```text
FOUND AGENTS.md
FOUND agent_rules.md
FOUND skills/README.md
FOUND reports/narrativeStudio/storylines/road_map_storylines.md
FOUND reports/narrativeStudio/storylines/ns_storylines_00_current_state_target_gap_audit.md
FOUND reports/narrativeStudio/storylines/ns_storylines_01_read_model_data_contract_v0.md
FOUND reports/narrativeStudio/ui/ns_home_checkpoint_narrative_overview_acceptance_v0.md
FOUND reports/narrativeStudio/ui/ns_home_15_internal_shell_sidebar_architecture.md
FOUND packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
FOUND packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart
FOUND packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
FOUND packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart
FOUND packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart
FOUND packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_studio_shell.dart
FOUND packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_studio_panels.dart
FOUND packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_flow_layout.dart
FOUND packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
FOUND packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart
FOUND packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart
FOUND packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart
FOUND packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart
FOUND packages/map_core/lib/src/models/scenario_asset.dart
FOUND packages/map_core/lib/src/models/script_asset.dart
FOUND packages/map_core/lib/src/models/project_manifest.dart
FOUND packages/map_editor/test/global_story_studio_workspace_test.dart
FOUND packages/map_editor/test/global_story_studio_ux_test.dart
FOUND packages/map_editor/test/global_story_studio_authoring_test.dart
FOUND packages/map_editor/test/global_story_studio_behavior_test.dart
FOUND packages/map_editor/test/narrative_workspace_projection_test.dart
```

### Test ciblé créé

```bash
cd packages/map_editor && flutter test test/storylines_current_global_story_characterization_test.dart
```

Sortie exacte :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart
00:00 +0: NS-STORYLINES-02 current Global Story characterization renders the legacy Global Story Studio from manifest and authoring metadata
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-02 current Global Story characterization keeps globalStory and localEventFlow separated in the current projection
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +2: All tests passed!
```

### Analyse ciblée

```bash
cd packages/map_editor && flutter analyze test/storylines_current_global_story_characterization_test.dart
```

Sortie exacte :

```text
Analyzing storylines_current_global_story_characterization_test.dart...     

No issues found! (ran in 2.8s)
```

### Régression groupée Global Story / Projection

```bash
cd packages/map_editor && flutter test test/storylines_current_global_story_characterization_test.dart test/global_story_studio_workspace_test.dart test/global_story_studio_ux_test.dart test/global_story_studio_behavior_test.dart test/global_story_studio_authoring_test.dart test/narrative_workspace_projection_test.dart
```

Sortie exacte :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart: NS-STORYLINES-02 current Global Story characterization renders the legacy Global Story Studio from manifest and authoring metadata
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/global_story_studio_workspace_test.dart: GlobalStoryStudioWorkspace defers global/step selection callbacks after frame (provider-safe)
[step_studio_trace] action=apply_document scenario=global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=global_story contains_emma=false contains_empty_entity=false
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart: NS-STORYLINES-02 current Global Story characterization renders the legacy Global Story Studio from manifest and authoring metadata
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart: NS-STORYLINES-02 current Global Story characterization renders the legacy Global Story Studio from manifest and authoring metadata
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart: NS-STORYLINES-02 current Global Story characterization renders the legacy Global Story Studio from manifest and authoring metadata
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart: NS-STORYLINES-02 current Global Story characterization renders the legacy Global Story Studio from manifest and authoring metadata
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart: NS-STORYLINES-02 current Global Story characterization renders the legacy Global Story Studio from manifest and authoring metadata
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart: NS-STORYLINES-02 current Global Story characterization renders the legacy Global Story Studio from manifest and authoring metadata
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart: NS-STORYLINES-02 current Global Story characterization renders the legacy Global Story Studio from manifest and authoring metadata
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart: NS-STORYLINES-02 current Global Story characterization renders the legacy Global Story Studio from manifest and authoring metadata
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart: NS-STORYLINES-02 current Global Story characterization renders the legacy Global Story Studio from manifest and authoring metadata
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart: NS-STORYLINES-02 current Global Story characterization renders the legacy Global Story Studio from manifest and authoring metadata
00:00 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart: NS-STORYLINES-02 current Global Story characterization renders the legacy Global Story Studio from manifest and authoring metadata
00:00 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart: NS-STORYLINES-02 current Global Story characterization renders the legacy Global Story Studio from manifest and authoring metadata
00:00 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart: NS-STORYLINES-02 current Global Story characterization renders the legacy Global Story Studio from manifest and authoring metadata
00:00 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/global_story_studio_workspace_test.dart: GlobalStoryStudioWorkspace can create a step from the shell without exceptions
[step_studio_trace] action=apply_document scenario=global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=global_story contains_emma=false contains_empty_entity=false
00:00 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/global_story_studio_ux_test.dart: Global Story Studio UX renders chapter-based narrative tree (not form-like step editor)
00:01 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart: NS-STORYLINES-02 current Global Story characterization keeps globalStory and localEventFlow separated in the current projection
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:01 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/global_story_studio_ux_test.dart: Global Story Studio UX renders chapter-based narrative tree (not form-like step editor)
00:01 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/global_story_studio_behavior_test.dart: Global Story Studio widget — header & rename steps visibles sans accordéon; ajouter un chapitre conserve la liste
00:01 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/global_story_studio_behavior_test.dart: Global Story Studio widget — header & rename steps visibles sans accordéon; ajouter un chapitre conserve la liste
00:01 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/global_story_studio_behavior_test.dart: Global Story Studio widget — header & rename steps visibles sans accordéon; ajouter un chapitre conserve la liste
00:01 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/global_story_studio_behavior_test.dart: Global Story Studio widget — header & rename steps visibles sans accordéon; ajouter un chapitre conserve la liste
00:01 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/global_story_studio_behavior_test.dart: Global Story Studio widget — header & rename steps visibles sans accordéon; ajouter un chapitre conserve la liste
00:01 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/global_story_studio_behavior_test.dart: Global Story Studio widget — header & rename steps visibles sans accordéon; ajouter un chapitre conserve la liste
00:01 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/global_story_studio_ux_test.dart: Global Story Studio UX structure with multiple steps in chapters displays correctly
00:01 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/global_story_studio_behavior_test.dart: Global Story Studio widget — header & rename champ titre chapitre : saisie + validation renomme
00:01 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/global_story_studio_behavior_test.dart: Global Story Studio widget — header & rename champ titre chapitre : saisie + validation renomme
00:01 +24: /Users/karim/Project/pokemonProject/packages/map_editor/test/global_story_studio_behavior_test.dart: Global Story Studio widget — header & rename champ titre chapitre : saisie + validation renomme
00:01 +25: /Users/karim/Project/pokemonProject/packages/map_editor/test/global_story_studio_behavior_test.dart: Global Story Studio widget — header & rename champ titre chapitre : saisie + validation renomme
00:01 +26: /Users/karim/Project/pokemonProject/packages/map_editor/test/global_story_studio_behavior_test.dart: Global Story Studio widget — header & rename champ titre chapitre : saisie + validation renomme
00:01 +27: /Users/karim/Project/pokemonProject/packages/map_editor/test/global_story_studio_behavior_test.dart: Global Story Studio widget — header & rename champ titre chapitre : saisie + validation renomme
00:01 +28: /Users/karim/Project/pokemonProject/packages/map_editor/test/global_story_studio_behavior_test.dart: Insert picker widget Ajouter une step au chapitre ouvre le sélecteur macOS (steps absentes du chapitre)
00:01 +29: All tests passed!
```

## 13. Evidence Pack

### Git initial

Branche initiale :

```text
main
```

`git status --short --untracked-files=all` initial :

```text
Sortie : <vide>
```

`git diff --stat` initial :

```text
Sortie : <vide>
```

`git diff --name-only` initial :

```text
Sortie : <vide>
```

`git diff --check` initial :

```text
Sortie : <vide>
```

### Git final

`git status --short --untracked-files=all` final :

```text
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? packages/map_editor/test/storylines_current_global_story_characterization_test.dart
?? reports/narrativeStudio/storylines/ns_storylines_02_current_global_story_characterization_anti_fake_tests_v0.md
```

`git diff --stat` final :

```text
 .../storylines/road_map_storylines.md              | 30 ++++++++++++++++++----
 1 file changed, 25 insertions(+), 5 deletions(-)
```

`git diff --name-only` final :

```text
reports/narrativeStudio/storylines/road_map_storylines.md
```

`git diff --check` final :

```text
Sortie : <vide>
```

Note : les fichiers non trackés ne sont pas listés par `git diff --stat` ni `git diff --name-only`. Leur contenu complet est donc inclus ci-dessous.

### Fichiers créés par NS-STORYLINES-02

- `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`
- `reports/narrativeStudio/storylines/ns_storylines_02_current_global_story_characterization_anti_fake_tests_v0.md`

### Fichiers modifiés par NS-STORYLINES-02

- `reports/narrativeStudio/storylines/road_map_storylines.md`

### Fichiers de code production modifiés

Aucun.

### Fichiers de test existants modifiés

Aucun.

### Contenu complet du test créé

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/application/global_story_studio_authoring.dart';
import 'package:map_editor/src/features/narrative/application/narrative_workspace_projection.dart';
import 'package:map_editor/src/features/narrative/application/step_studio_authoring.dart';
import 'package:map_editor/src/features/narrative/state/narrative_workspace_state.dart';
import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';

void main() {
  group('NS-STORYLINES-02 current Global Story characterization', () {
    testWidgets(
      'renders the legacy Global Story Studio from manifest and authoring metadata',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1600, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final project = _auditProject();

        await _pumpGlobalStoryCanvas(tester, project);

        expect(find.byType(NarrativeWorkspaceCanvas), findsOneWidget);
        expect(find.byKey(const ValueKey('narrative-studio-sidebar')),
            findsOneWidget);
        expect(find.byKey(const ValueKey('narrative-studio-header')),
            findsOneWidget);

        expect(find.text('Storylines'), findsWidgets);
        expect(find.text('Audit Story From Scenario'), findsOneWidget);
        expect(_chapterFieldWithText('Audit Chapter From Metadata'),
            findsOneWidget);
        expect(find.text('Audit Step From Metadata'), findsWidgets);
        expect(find.text('Audit Step Detail From Metadata'), findsWidgets);

        // Current characterization: ScenarioAsset.description is present in
        // the projection, but the legacy screen does not render it yet.
        expect(find.text('Audit description from scenario'), findsNothing);

        expect(find.text('STRUCTURE'), findsOneWidget);
        expect(find.text('Votre récit'), findsOneWidget);
        expect(find.text('FIL NARRATIF'), findsOneWidget);
        expect(find.text('Progression globale'), findsOneWidget);
        expect(find.text('DÉTAIL DE L’ÉTAPE'), findsOneWidget);

        // Legacy Global Story Studio actions are characterized, not removed.
        expect(find.text('Réinitialiser'), findsOneWidget);
        expect(find.text('Tester'), findsOneWidget);
        expect(find.text('Valider'), findsWidgets);
        expect(find.text('+ Nouvelle étape'), findsOneWidget);

        // Future Storylines action exists only in the internal header shell.
        expect(find.text('Nouvelle storyline'), findsOneWidget);

        // NS-HOME guardrail: Maps is not an internal Narrative Studio entry.
        expect(find.text('Maps'), findsNothing);
        expect(find.text('Facts'), findsOneWidget);
        expect(find.text('Règles du monde'), findsOneWidget);
        expect(find.text('Validateur'), findsOneWidget);

        // localEventFlow is available to the projection, but is not displayed
        // as a side quest/storyline in the legacy Global Story workspace.
        expect(find.text('Audit Local Event Flow'), findsNothing);

        for (final forbidden in _targetOnlyStrings) {
          expect(
            find.text(forbidden),
            findsNothing,
            reason: '$forbidden must not be injected from target imagery.',
          );
        }
      },
    );

    test(
      'keeps globalStory and localEventFlow separated in the current projection',
      () {
        final project = _auditProject();

        final projection = buildNarrativeWorkspaceProjection(project);

        expect(projection.globalStories, hasLength(1));
        expect(projection.globalStories.single.id, 'audit_global_story');
        expect(
          projection.globalStories.single.name,
          'Audit Story From Scenario',
        );
        expect(
          projection.globalStories.single.description,
          'Audit description from scenario',
        );

        expect(projection.localEventFlows, hasLength(1));
        expect(projection.localEventFlows.single.id, 'audit_local_event_flow');
        expect(
          projection.localEventFlows.single.name,
          'Audit Local Event Flow',
        );

        expect(projection.steps, hasLength(1));
        expect(projection.steps.single.id, 'audit_step');
        expect(projection.steps.single.name, 'Audit Step From Metadata');
        expect(
          projection.steps.single.description,
          'Audit Step Detail From Metadata',
        );
      },
    );
  });
}

const _targetOnlyStrings = <String>[
  'La brume du phare',
  'Les cristaux de sel',
  'Le Goélise du port',
  'La cabane du phare',
  'Mystère',
  'Exploration',
  'Phare',
  'Côtiers',
  '412',
  '18',
  'RÈGLES DU MONDE AFFECTÉES',
  'DERNIÈRE ACTIVITÉ',
];

Finder _chapterFieldWithText(String value) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is CupertinoTextField && widget.controller?.text == value,
    description: 'CupertinoTextField with text "$value"',
  );
}

Future<void> _pumpGlobalStoryCanvas(
  WidgetTester tester,
  ProjectManifest project,
) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final editorSubscription = container.listen(
    editorNotifierProvider,
    (_, __) {},
  );
  addTearDown(editorSubscription.close);

  container.read(editorNotifierProvider.notifier).state = EditorState(
    project: project,
    workspaceMode: EditorWorkspaceMode.globalStory,
  );
  container
      .read(narrativeWorkspaceControllerProvider.notifier)
      .openGlobalStory(scenarioId: 'audit_global_story');
  container
      .read(narrativeWorkspaceControllerProvider.notifier)
      .selectStep('audit_step');

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1600,
            height: 1000,
            child: NarrativeWorkspaceCanvas(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

ProjectManifest _auditProject() {
  const stepDocument = StepStudioDocument(
    globalStoryScenarioId: 'audit_global_story',
    steps: <StepStudioStep>[
      StepStudioStep(
        id: 'audit_step',
        name: 'Audit Step From Metadata',
        description: 'Audit Step Detail From Metadata',
        order: 0,
        activation: StepStudioActivationRule(
          mode: StepStudioActivationMode.atGameStart,
        ),
        completion: StepStudioCompletionRule(
          mode: StepStudioCompletionMode.manual,
        ),
      ),
    ],
  );
  const globalDocument = GlobalStoryStudioDocument(
    globalStoryScenarioId: 'audit_global_story',
    entryStepId: 'audit_step',
    nodes: <GlobalStoryStepNode>[
      GlobalStoryStepNode(stepId: 'audit_step'),
    ],
    chapters: <GlobalStoryChapter>[
      GlobalStoryChapter(
        id: 'audit_chapter',
        name: 'Audit Chapter From Metadata',
        description: 'Audit chapter description from metadata',
        stepIds: <String>['audit_step'],
        order: 0,
      ),
    ],
  );

  final globalScenario = applyGlobalStoryStudioDocumentToGlobalScenario(
    applyStepStudioDocumentToGlobalScenario(
      const ScenarioAsset(
        id: 'audit_global_story',
        name: 'Audit Story From Scenario',
        description: 'Audit description from scenario',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
      ),
      stepDocument,
    ),
    globalDocument,
    stepDocument: stepDocument,
  );

  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: 'Audit Project',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    scenarios: <ScenarioAsset>[
      globalScenario,
      const ScenarioAsset(
        id: 'audit_local_event_flow',
        name: 'Audit Local Event Flow',
        description: 'Audit local flow must not become a side quest',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'local_start',
      ),
    ],
  );
}
```

### Diff complet des tests modifiés

Aucun test existant n'a été modifié.

Le test créé est non tracké ; `git diff` ne le liste donc pas. Son contenu complet est inclus dans la section précédente.

### Diff complet de `road_map_storylines.md`

```diff
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index d0ff9a23..a4e2a8f3 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -290,7 +290,7 @@ Interprétation V0 :
 | Lot | Title | Type | Status | Next |
 |---|---|---|---|---|
 | NS-STORYLINES-01 | Storylines Read Model / Data Contract V0 | core/design | DONE | NS-STORYLINES-02 |
-| NS-STORYLINES-02 | Current Global Story Characterization / Anti-Fake Tests V0 | test/audit | TODO | NS-STORYLINES-03 |
+| NS-STORYLINES-02 | Current Global Story Characterization / Anti-Fake Tests V0 | test/audit | DONE | NS-STORYLINES-03 |
 | NS-STORYLINES-03 | Storylines Workspace Shell Layout V0 | editor UI | TODO | NS-STORYLINES-04 |
 | NS-STORYLINES-04 | Storylines Secondary List Panel Read-only V0 | editor UI | TODO | NS-STORYLINES-05 |
 | NS-STORYLINES-05 | Storyline Header / Tabs / KPI Read-only V0 | editor UI | TODO | NS-STORYLINES-06 |
@@ -340,7 +340,15 @@ Interprétation V0 :
 - Visual Gate : optionnel.
 - Risques : figer une UI destinée à être remplacée.
 - Design system impact : aucun nouveau composant local.
-- Statut : TODO.
+- Statut : DONE.
+- Résultat NS-STORYLINES-02 : ajout d'un test de caractérisation anti-fake qui verrouille l'ancien Global Story Studio sans toucher au code production.
+- Fichiers créés : `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`, `reports/narrativeStudio/storylines/ns_storylines_02_current_global_story_characterization_anti_fake_tests_v0.md`.
+- Fichiers modifiés : `reports/narrativeStudio/storylines/road_map_storylines.md`.
+- Code production : aucun fichier `packages/map_editor/lib`, `map_core`, `map_runtime`, `map_gameplay` ou `map_battle` modifié.
+- Tests exécutés : `flutter test test/storylines_current_global_story_characterization_test.dart`, régression groupée Global Story / Projection.
+- Analyse exécutée : `flutter analyze test/storylines_current_global_story_characterization_test.dart`.
+- Design System Gate : confirmé ; aucun widget production, aucune couleur, aucune primitive design system modifiée.
+- Fake data : aucune donnée cible ajoutée ; les chaînes cible sont assertées absentes quand la fixture neutre ne les contient pas.
 - Prochain lot attendu : NS-STORYLINES-03.
 
 ### NS-STORYLINES-03 — Storylines Workspace Shell Layout V0
@@ -620,9 +628,9 @@ Décision temporaire :
 
 ```text
 Roadmap status: ACTIVE
-Current lot: NS-STORYLINES-01
+Current lot: NS-STORYLINES-02
 Current lot status: DONE
-Next recommended lot: NS-STORYLINES-02 — Current Global Story Characterization / Anti-Fake Tests V0
+Next recommended lot: NS-STORYLINES-03 — Storylines Workspace Shell Layout V0
 ```
 
 | Lot | Status | Last update | Notes |
@@ -630,7 +638,7 @@ Next recommended lot: NS-STORYLINES-02 — Current Global Story Characterization
 | NS-STORYLINES-00 | DONE | 2026-05-27 | Audit actuel/cible produit. |
 | NS-STORYLINES-ROADMAP-00 | DONE | 2026-05-27 | Roadmap vivante créée. |
 | NS-STORYLINES-01 | DONE | 2026-05-27 | Contrat de données Storylines V0 documenté ; aucun code/test modifié. |
-| NS-STORYLINES-02 | TODO | 2026-05-27 | Prochain lot recommandé : caractérisation et anti-fake tests. |
+| NS-STORYLINES-02 | DONE | 2026-05-27 | Tests de caractérisation anti-fake ajoutés ; ancien Global Story Studio verrouillé sans code production. |
 | NS-STORYLINES-03 | TODO | 2026-05-27 | UI shell après contrat/tests. |
 | NS-STORYLINES-04 | TODO | 2026-05-27 | Secondary list read-only. |
 | NS-STORYLINES-05 | TODO | 2026-05-27 | Header/tabs/KPI read-only. |
@@ -644,6 +652,18 @@ Next recommended lot: NS-STORYLINES-02 — Current Global Story Characterization
 
 ## 14. Changelog
 
+### 2026-05-27 — NS-STORYLINES-02
+
+- Ajout du test `storylines_current_global_story_characterization_test.dart`.
+- Vérification que `EditorWorkspaceMode.globalStory` rend encore `NarrativeWorkspaceCanvas > NarrativeStudioShell > GlobalStoryStudioWorkspace`.
+- Vérification que les données visibles viennent du `ScenarioAsset globalStory` et des metadata `GlobalStoryStudioDocument` / `StepStudioDocument`.
+- Vérification anti-fake : données cible Storylines (`La brume du phare`, quêtes annexes cible, tags cible, `412`, `18`, etc.) absentes avec une fixture neutre.
+- Vérification que `localEventFlow` n'est pas affiché comme quête annexe Storylines.
+- Vérification que `Maps` reste absent de la sidebar interne Narrative Studio.
+- Régressions Global Story / Projection passées et analyse ciblée clean.
+- Aucun code production, modèle, widget ou design system modifié.
+- Prochain lot recommandé : `NS-STORYLINES-03 — Storylines Workspace Shell Layout V0`.
+
 ### 2026-05-27 — NS-STORYLINES-01
 
 - Création du contrat de données Storylines V0.
```

### Contenu complet du rapport créé

Le présent fichier est le rapport créé. Une auto-inclusion littérale complète du rapport dans lui-même créerait une récursion infinie ; toutes les sections obligatoires du rapport sont présentes dans ce document.

### Justification de l'analyse

Analyse ciblée lancée car le lot crée un test Flutter :

```text
flutter analyze test/storylines_current_global_story_characterization_test.dart
```

Résultat : clean.

### Confirmation des interdictions

- Aucun code production modifié.
- Aucun modèle modifié.
- Aucun widget production créé.
- Aucun fichier `map_core/lib`, `map_runtime`, `map_gameplay`, `map_battle` modifié.
- Aucune fixture Selbrume finale créée.
- Aucune donnée cible utilisée comme donnée positive.
- Aucune action future activée.
- `Maps` non réintroduit dans la sidebar interne.

## 14. Self-review

Points positifs :

- le test verrouille la source réelle des données visibles ;
- la séparation `globalStory` / `localEventFlow` est prouvée ;
- les données cible interdites sont protégées par assertions négatives ;
- la roadmap est mise à jour sans démarrer NS-STORYLINES-03 ;
- aucun code production n'a été touché.

Limites :

- le test caractérise l'UI legacy actuelle, qui sera remplacée progressivement ;
- `ScenarioAsset.description` est seulement prouvée dans la projection, pas dans le rendu legacy ;
- les actions legacy sont caractérisées en présence, mais aucun clic mutateur n'est exercé dans ce lot pour éviter de transformer la caractérisation en refactor comportemental.

Auto-review critique :

- le scope reste bien `anti-fake` et non `nouvelle UI` ;
- le test utilise des noms neutres, pas les données cible ;
- le Design System Gate est respecté parce qu'aucune UI production n'est ajoutée ;
- le prochain lot doit rester `NS-STORYLINES-03` et commencer le shell Storylines sans réinventer les données.
