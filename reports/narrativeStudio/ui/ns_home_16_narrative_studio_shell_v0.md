# NS-HOME-16 — NarrativeStudioShell V0

## 1. Résumé exécutif

NS-HOME-16 crée le premier shell interne réel du Narrative Studio avec `NarrativeStudioShell`.

Le changement matérialise la séparation décidée en NS-HOME-15 :

```text
PokeMap Project Explorer global
≠
Navigation interne Narrative Studio
```

Le `ProjectExplorerPanel` n'a pas été modifié. Il reste la navigation globale PokeMap. La navigation narrative existante est conservée comme strip transitoire dans le nouveau shell interne, en attendant la future sidebar interne NS-HOME-17.

Résultat :

```text
NarrativeWorkspaceCanvas
└─ NarrativeStudioShell
   ├─ navigation transitoire V0
   └─ contenu principal
      └─ Overview / Global Story / Step / Cutscene / Dialogue
```

## 2. Rappel du scope NS-HOME-16

Scope demandé :

```text
- créer NarrativeStudioShell ;
- utiliser ce shell depuis NarrativeWorkspaceCanvas ;
- conserver les modes narratifs existants ;
- ne pas remplacer le Project Explorer global ;
- ne pas créer la sidebar interne finale ;
- ne pas modifier le read model ;
- ne pas inventer Facts / World Rules / Validateur comme destinations actives ;
- produire des screenshots Visual Gate ;
- produire un rapport complet.
```

Hors scope respecté :

```text
- aucune refonte de ProjectExplorerPanel ;
- aucune création de sidebar interne finale ;
- aucune action future activée ;
- aucun read model modifié ;
- aucun map_core/runtime/gameplay/battle touché.
```

## 3. Fichiers créés / modifiés

Fichiers créés :

```text
packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart
reports/narrativeStudio/ui/ns_home_16_narrative_studio_shell_v0.md
reports/narrativeStudio/ui/screenshots/ns_home_16_narrative_studio_shell_desktop.png
reports/narrativeStudio/ui/screenshots/ns_home_16_narrative_studio_shell_focus.png
reports/narrativeStudio/ui/screenshots/ns_home_16_narrative_studio_shell_medium.png
```

Fichiers modifiés :

```text
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Fichiers explicitement non modifiés :

```text
packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart
packages/map_core/
packages/map_runtime/
packages/map_gameplay/
packages/map_battle/
```

## 4. Architecture créée

Le nouveau widget `NarrativeStudioShell` est un conteneur interne au workspace narratif. Il reçoit :

```text
- workspaceMode courant ;
- callbacks existants de navigation narrative ;
- child principal à afficher.
```

Il ne reçoit pas :

```text
- read model ;
- ProjectManifest brut ;
- SaveData ;
- GameState ;
- provider global nouveau ;
- repository.
```

Le shell V0 contient :

```text
- une navigation transitoire horizontale ;
- un slot de contenu principal ;
- des keys de test explicites :
  - narrative-studio-shell
  - narrative-studio-transitional-navigation
  - narrative-studio-main-content
```

## 5. Mapping NarrativeWorkspaceCanvas → NarrativeStudioShell

Avant NS-HOME-16, `NarrativeWorkspaceCanvas` composait directement :

```text
Column
├─ _NarrativeModeStrip
└─ Expanded(content)
```

Après NS-HOME-16 :

```text
NarrativeWorkspaceCanvas
├─ calcule la projection narrative existante
├─ résout le contenu principal selon EditorWorkspaceMode
└─ retourne NarrativeStudioShell(child: mainContent)
```

Le parent reste responsable de choisir le contenu :

```text
narrativeOverview -> NarrativeOverviewWorkspace
globalStory       -> GlobalStoryStudioWorkspace
step              -> _StepWorkspaceBody
cutscene          -> _CutsceneWorkspaceBody
dialogue          -> DialogueStudioWorkspace
```

Le shell reste responsable du cadre interne commun.

## 6. Navigation transitoire conservée

La navigation actuelle reste volontairement un strip horizontal, déplacé dans `NarrativeStudioShell`.

Entrées conservées :

```text
Aperçu
Histoire globale
Étape
Cinématique
Dialogue
```

Entrées volontairement non créées :

```text
Facts
World Rules
Validateur
```

Décision :

```text
Le mode strip reste transitoire jusqu'à NS-HOME-17.
Il sert à conserver l'accès aux studios existants sans prétendre être la sidebar finale.
```

## 7. Préparation de la future sidebar interne

NS-HOME-16 prépare le point d'insertion de la future sidebar interne sans l'afficher encore.

Le futur lot pourra faire évoluer :

```text
NarrativeStudioShell
├─ NarrativeStudioSidebar
└─ NarrativeStudioMainArea
```

Le choix V0 évite un placeholder visible qui ferait croire à une sidebar déjà conçue. La séparation d'architecture existe dans le code via le nouveau widget, mais la surface finale reste réservée à NS-HOME-17.

## 8. Ce qui reste volontairement hors scope

```text
- sidebar interne finale ;
- destinations Facts / World Rules / Validateur ;
- création de storyline ;
- validation narrative active ;
- recherche globale ;
- centre de notifications ;
- badge notification ;
- inspector interne dédié au shell ;
- collapse automatique du Project Explorer global ;
- modification du read model Overview.
```

## 9. Tests ajoutés / modifiés

Ajout dans `narrative_overview_shell_navigation_test.dart` :

```text
NarrativeWorkspaceCanvas renders the internal Narrative Studio shell
```

Ce test vérifie :

```text
- le shell interne est rendu ;
- le contenu Overview est dans le shell ;
- le ProjectExplorerPanel n'est pas dans le shell interne ;
- Aperçu / Histoire globale / Étape / Cinématique / Dialogue restent accessibles ;
- Facts / World Rules / Validateur ne sont pas rendus dans cette navigation ;
- les clics changent bien le workspaceMode attendu.
```

Ajout dans le même fichier :

```text
NarrativeOverviewWorkspace captures NS-HOME-16 internal shell screenshots when requested
```

Ce test génère les screenshots Visual Gate via dart-define.

## 10. Visual Gate

Screenshots produits :

```text
reports/narrativeStudio/ui/screenshots/ns_home_16_narrative_studio_shell_desktop.png
reports/narrativeStudio/ui/screenshots/ns_home_16_narrative_studio_shell_focus.png
reports/narrativeStudio/ui/screenshots/ns_home_16_narrative_studio_shell_medium.png
```

Méthode :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_16_CAPTURE_STUDIO_SHELL_DESKTOP=true
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_16_CAPTURE_STUDIO_SHELL_FOCUS=true
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_16_CAPTURE_STUDIO_SHELL_MEDIUM=true
```

Métadonnées :

```text
reports/narrativeStudio/ui/screenshots/ns_home_16_narrative_studio_shell_desktop.png: PNG image data, 1600 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/ui/screenshots/ns_home_16_narrative_studio_shell_focus.png:   PNG image data, 1600 x 700, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/ui/screenshots/ns_home_16_narrative_studio_shell_medium.png:  PNG image data, 1180 x 1000, 8-bit/color RGBA, non-interlaced
May 27 16:50:07 2026 244852 reports/narrativeStudio/ui/screenshots/ns_home_16_narrative_studio_shell_desktop.png
May 27 16:50:18 2026 170343 reports/narrativeStudio/ui/screenshots/ns_home_16_narrative_studio_shell_focus.png
May 27 16:50:30 2026 187972 reports/narrativeStudio/ui/screenshots/ns_home_16_narrative_studio_shell_medium.png
```

Analyse visuelle :

```text
- Le shell global PokeMap reste visible : toolbar, Project Explorer global, status bar.
- Le Project Explorer reste à gauche et n'est pas transformé en sidebar interne.
- La zone Narrative Studio contient maintenant son propre conteneur interne.
- La navigation transitoire est visible au-dessus du contenu Overview.
- L'Overview reste stable : breadcrumb, titre, projet, KPI, histoire principale et Structure narrative restent visibles selon la hauteur.
- Le screenshot medium reste lisible, sans overflow évident.
- Le screenshot focus confirme que le strip appartient au workspace narratif, pas au Project Explorer global.
```

Ce qui ne correspond pas encore à l'image cible :

```text
- la sidebar interne Narrative Studio finale n'existe pas encore ;
- Facts / World Rules / Validateur ne sont pas des destinations internes actives ;
- le Project Explorer global reste visible ;
- le mode strip est encore transitoire.
```

Correction après inspection visuelle :

```text
Aucune correction visuelle supplémentaire n'a été nécessaire après inspection.
Le défaut attendu est architecturalement assumé : le strip est transitoire jusqu'à NS-HOME-17.
```

## 11. Commandes exécutées

```bash
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart
cd packages/map_editor && flutter test test/top_toolbar_test.dart
cd packages/map_editor && flutter test test/editor_selectors_test.dart
cd packages/map_editor && flutter test test/status_bar_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/top_toolbar_test.dart test/editor_selectors_test.dart test/status_bar_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_16_CAPTURE_STUDIO_SHELL_DESKTOP=true
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_16_CAPTURE_STUDIO_SHELL_FOCUS=true
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_16_CAPTURE_STUDIO_SHELL_MEDIUM=true
cd packages/map_editor && flutter analyze
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/narrative_studio_shell.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/ui/canvas/narrative_overview_workspace_test.dart
git diff --check
```

## 12. Résultats des tests

### TDD red attendu

Avant création de `NarrativeStudioShell`, le test ajouté échouait comme prévu :

```text
Expected: exactly one matching candidate
Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'narrative-studio-shell'>]: []>
```

### Test shell navigation

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
00:00 +0: NarrativeWorkspaceCanvas routes overview mode to the overview shell
00:00 +1: NarrativeWorkspaceCanvas renders the internal Narrative Studio shell
00:00 +2: NarrativeLibraryPanel exposes overview without removing existing studios
00:00 +3: EditorShellPage presents coherent Narrative Studio overview chrome
00:01 +4: ProjectExplorerPanel prioritizes narrative navigation in overview mode
00:01 +5: NarrativeOverviewWorkspace captures a full editor shell screenshot when requested
00:01 +6: NarrativeOverviewWorkspace captures NS-HOME-11 sidebar navigation screenshots when requested
00:01 +7: NarrativeOverviewWorkspace captures NS-HOME-12 top bar screenshots when requested
00:01 +8: NarrativeOverviewWorkspace captures NS-HOME-13 breadcrumb header screenshots when requested
00:01 +9: NarrativeOverviewWorkspace captures NS-HOME-14 header density screenshots when requested
00:01 +10: NarrativeOverviewWorkspace captures NS-HOME-16 internal shell screenshots when requested
00:01 +11: NarrativeOverviewWorkspace captures NS-HOME-10 shell chrome screenshots when requested
00:01 +12: All tests passed!
```

### Test overview workspace

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
00:00 +0: NarrativeOverviewWorkspace renders a minimal authoring overview from the read model
00:00 +1: NarrativeOverviewWorkspace does not present unavailable modules as real data
00:00 +2: NarrativeOverviewWorkspace renders honest upcoming data states and footer metadata
00:00 +3: NarrativeOverviewWorkspace KPI cards consume read model values
00:00 +4: NarrativeOverviewWorkspace KPI layout renders on a narrower desktop width
00:00 +5: NarrativeOverviewWorkspace keeps KPI cards visible after header density polish
00:01 +6: NarrativeOverviewWorkspace renders an honest empty main story card
00:01 +7: NarrativeOverviewWorkspace renders explicit main story data from the read model
00:01 +8: NarrativeOverviewWorkspace explains missing description and fallback chapters
00:01 +9: NarrativeOverviewWorkspace renders ambiguous main story state explicitly
00:01 +10: NarrativeOverviewWorkspace renders honest narrative module cards
00:01 +11: NarrativeOverviewWorkspace module cards consume read model values
00:01 +12: NarrativeOverviewWorkspace module grid keeps previous overview blocks visible
00:01 +13: NarrativeOverviewWorkspace renders an honest structure inspector panel
00:01 +14: NarrativeOverviewWorkspace structure inspector consumes read model counters and chapters
00:01 +15: NarrativeOverviewWorkspace structure inspector shows clean validation as up to date
00:01 +16: NarrativeOverviewWorkspace structure inspector maps warnings to review state
00:01 +17: NarrativeOverviewWorkspace structure inspector maps errors to blocking state
00:02 +18: NarrativeOverviewWorkspace keeps the structure inspector beside the main column on large desktop
00:02 +19: NarrativeOverviewWorkspace stacks the structure inspector after the main column on medium desktop
00:02 +20: NarrativeOverviewWorkspace keeps V0 unavailable data honest after responsive polish
00:02 +21: NarrativeOverviewWorkspace captures KPI cards screenshot when requested
00:02 +22: NarrativeOverviewWorkspace captures main story card screenshot when requested
00:02 +23: NarrativeOverviewWorkspace captures module cards grid screenshot when requested
00:02 +24: NarrativeOverviewWorkspace captures structure inspector screenshot when requested
00:02 +25: NarrativeOverviewWorkspace captures empty states and footer screenshot when requested
00:02 +26: NarrativeOverviewWorkspace captures responsive polish desktop screenshot when requested
00:02 +27: NarrativeOverviewWorkspace captures responsive polish medium screenshot when requested
00:02 +28: All tests passed!
```

### Tests shell connexes

```text
test/top_toolbar_test.dart
00:00 +10: All tests passed!

test/editor_selectors_test.dart
00:00 +9: All tests passed!

test/status_bar_test.dart
00:00 +6: All tests passed!
```

### Régression combinée

```text
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/top_toolbar_test.dart test/editor_selectors_test.dart test/status_bar_test.dart
00:02 +65: All tests passed!
```

### Screenshots via dart-define

```text
NS_HOME_16_CAPTURE_STUDIO_SHELL_DESKTOP=true
00:01 +12: All tests passed!

NS_HOME_16_CAPTURE_STUDIO_SHELL_FOCUS=true
00:01 +12: All tests passed!

NS_HOME_16_CAPTURE_STUDIO_SHELL_MEDIUM=true
00:01 +12: All tests passed!
```

## 13. Résultats analyze

Analyse globale :

```text
Analyzing map_editor...
error • The named parameter 'dbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7 • undefined_named_parameter
error • The named parameter 'battleEngineAimedTarget' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:64:7 • undefined_named_parameter
error • The named parameter 'battleEngineMethod' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:72:7 • undefined_named_parameter
error • The named parameter 'effectChance' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:73:7 • undefined_named_parameter
error • The named parameter 'studioFlags' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:74:7 • undefined_named_parameter
error • The named parameter 'battleStageMods' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:75:7 • undefined_named_parameter
error • The named parameter 'moveStatuses' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:76:7 • undefined_named_parameter
error • The named parameter 'psdkStudioMoveId' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:80:9 • undefined_named_parameter
error • Undefined class 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:239:3 • undefined_class
347 issues found. (ran in 3.3s)
```

Analyse ciblée :

```text
Analyzing 4 items...
No issues found! (ran in 1.3s)
```

Conclusion :

```text
flutter analyze global échoue sur une dette préexistante du catalogue Pokémon SDK.
L'analyse ciblée des fichiers NS-HOME-16 est clean.
```

## 14. Limites

```text
- Le shell interne existe mais ne rend pas encore la sidebar interne finale.
- La navigation est encore un strip horizontal transitoire.
- Le Project Explorer global reste visible et priorisé comme entrée globale.
- Aucune stratégie de collapse automatique n'est implémentée.
- Le screenshot utilise des fixtures génériques de test, pas des données Selbrume.
```

## 15. Prochain lot recommandé

```text
NS-HOME-17 — Internal Narrative Studio Sidebar V0
```

Objectif recommandé :

```text
Créer la première sidebar interne Narrative Studio à l'intérieur de NarrativeStudioShell,
sans remplacer ProjectExplorerPanel,
avec Aperçu / Histoire globale / Étape / Cinématique / Dialogue branchés,
et Facts / World Rules / Validateur explicitement disabled ou hors scope.
```

## 16. Evidence Pack

### Branche

```text
main
```

### Git status initial

```text
(aucune sortie)
```

Le working tree était clean au démarrage du lot.

### Git status final

```text
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
?? packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart
?? reports/narrativeStudio/ui/ns_home_16_narrative_studio_shell_v0.md
?? reports/narrativeStudio/ui/screenshots/ns_home_16_narrative_studio_shell_desktop.png
?? reports/narrativeStudio/ui/screenshots/ns_home_16_narrative_studio_shell_focus.png
?? reports/narrativeStudio/ui/screenshots/ns_home_16_narrative_studio_shell_medium.png
```

### Git diff --stat final

```text
 .../src/ui/canvas/narrative_workspace_canvas.dart  | 315 +++++++--------------
 .../narrative_overview_shell_navigation_test.dart  | 160 ++++++++++-
 2 files changed, 263 insertions(+), 212 deletions(-)
```

Rappel :

```text
Les fichiers non trackés ne sont pas listés par git diff --stat.
Le contenu complet du nouveau widget est donc inclus ci-dessous.
```

### Git diff --name-only final

```text
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

### Git diff --check final

```text
(aucune sortie)
```

### Contenu complet du fichier créé

```dart
import 'package:flutter/cupertino.dart';

import '../../features/editor/state/models/editor_workspace_mode.dart';
import '../shared/cupertino_editor_widgets.dart';

class NarrativeStudioShell extends StatelessWidget {
  const NarrativeStudioShell({
    super.key,
    required this.workspaceMode,
    required this.onSelectOverview,
    required this.onSelectGlobal,
    required this.onSelectStep,
    required this.onSelectCutscene,
    required this.onSelectDialogue,
    required this.child,
  });

  final EditorWorkspaceMode workspaceMode;
  final VoidCallback onSelectOverview;
  final VoidCallback onSelectGlobal;
  final VoidCallback onSelectStep;
  final VoidCallback onSelectCutscene;
  final VoidCallback onSelectDialogue;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Narrative Studio Shell',
      child: Column(
        key: const ValueKey('narrative-studio-shell'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NarrativeStudioTransientNavigation(
            workspaceMode: workspaceMode,
            onSelectOverview: onSelectOverview,
            onSelectGlobal: onSelectGlobal,
            onSelectStep: onSelectStep,
            onSelectCutscene: onSelectCutscene,
            onSelectDialogue: onSelectDialogue,
          ),
          const SizedBox(height: 8),
          Expanded(
            key: const ValueKey('narrative-studio-main-content'),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _NarrativeStudioTransientNavigation extends StatelessWidget {
  const _NarrativeStudioTransientNavigation({
    required this.workspaceMode,
    required this.onSelectOverview,
    required this.onSelectGlobal,
    required this.onSelectStep,
    required this.onSelectCutscene,
    required this.onSelectDialogue,
  });

  final EditorWorkspaceMode workspaceMode;
  final VoidCallback onSelectOverview;
  final VoidCallback onSelectGlobal;
  final VoidCallback onSelectStep;
  final VoidCallback onSelectCutscene;
  final VoidCallback onSelectDialogue;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('narrative-studio-transitional-navigation'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ModeChip(
            label: 'Aperçu',
            selected: workspaceMode == EditorWorkspaceMode.narrativeOverview,
            onTap: onSelectOverview,
          ),
          const SizedBox(width: 6),
          _ModeChip(
            label: 'Histoire globale',
            selected: workspaceMode == EditorWorkspaceMode.globalStory,
            onTap: onSelectGlobal,
          ),
          const SizedBox(width: 6),
          _ModeChip(
            label: 'Étape',
            selected: workspaceMode == EditorWorkspaceMode.step,
            onTap: onSelectStep,
          ),
          const SizedBox(width: 6),
          _ModeChip(
            label: 'Cinématique',
            selected: workspaceMode == EditorWorkspaceMode.cutscene,
            onTap: onSelectCutscene,
          ),
          const SizedBox(width: 6),
          _ModeChip(
            label: 'Dialogue',
            selected: workspaceMode == EditorWorkspaceMode.dialogue,
            onTap: onSelectDialogue,
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected
        ? EditorChrome.inspectorJoyCyan
        : EditorChrome.subtleLabel(context);
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? EditorChrome.islandFillElevated(context)
              : EditorChrome.sidebarHoverFill(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.7)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: accent,
          ),
        ),
      ),
    );
  }
}
```

### Extrait modifié — NarrativeWorkspaceCanvas

```dart
final mainContent = switch (editor.workspaceMode) {
  EditorWorkspaceMode.narrativeOverview => NarrativeOverviewWorkspace(
      readModel: buildNarrativeOverviewReadModel(
        project: editor.project!,
      ),
    ),
  EditorWorkspaceMode.globalStory => GlobalStoryStudioWorkspace(
      editorNotifier: editorNotifier,
      project: editor.project,
      projection: projection,
      selectedGlobalStoryId: narrative.selectedGlobalStoryId,
      selectedStepId: narrative.selectedStepId,
      onSelectGlobalStory: (scenarioId) {
        if (scenarioId == null || scenarioId.trim().isEmpty) {
          return;
        }
        narrativeController.selectGlobalStory(scenarioId);
        narrativeController.openGlobalStory(scenarioId: scenarioId);
      },
      onSelectStep: (stepId) {
        if (stepId == null || stepId.trim().isEmpty) {
          return;
        }
        final step = projection.steps
            .where((item) => item.id == stepId)
            .cast<NarrativeStepSummary?>()
            .firstWhere((item) => item != null, orElse: () => null);
        narrativeController.selectStep(stepId);
        if (step != null) {
          narrativeController.selectGlobalStory(step.globalScenarioId);
        }
      },
      onOpenStepStudio: (stepId) {
        final step = projection.steps
            .where((item) => item.id == stepId)
            .cast<NarrativeStepSummary?>()
            .firstWhere((item) => item != null, orElse: () => null);
        narrativeController.selectStep(stepId);
        narrativeController.openStep(
          stepId: stepId,
          globalScenarioId: step?.globalScenarioId,
        );
        editorNotifier.selectStepWorkspace();
      },
    ),
  EditorWorkspaceMode.step => _StepWorkspaceBody(
      projection: projection,
      selectedStep: selectedStep,
      onSelectStep: (stepId) {
        final step = projection.steps
            .where((s) => s.id == stepId)
            .cast<NarrativeStepSummary?>()
            .firstWhere((s) => s != null, orElse: () => null);
        narrativeController.selectStep(stepId);
        narrativeController.openStep(
          stepId: stepId,
          globalScenarioId: step?.globalScenarioId,
        );
      },
      onSelectOutcome: narrativeController.selectOutcome,
      onOpenCutsceneStudio: (cutsceneScenarioId) {
        // Même séquence que la bibliothèque narrative : sélection +
        // état de vue, puis bascule du workspace éditeur.
        narrativeController.selectCutscene(cutsceneScenarioId);
        narrativeController.openCutscene(
          cutsceneScenarioId: cutsceneScenarioId,
        );
        editorNotifier.selectCutsceneWorkspace();
      },
      editorNotifier: editorNotifier,
      project: editor.project,
      activeMap: editor.activeMap,
    ),
  EditorWorkspaceMode.cutscene => _CutsceneWorkspaceBody(
      editorNotifier: editorNotifier,
      project: editor.project,
      activeMap: editor.activeMap,
      projection: projection,
      selectedCutscene: selectedCutscene,
      onSelectCutscene: (scenarioId) {
        narrativeController.selectCutscene(scenarioId);
        narrativeController.openCutscene(
          cutsceneScenarioId: scenarioId,
        );
      },
      onSelectOutcome: narrativeController.selectOutcome,
    ),
  EditorWorkspaceMode.dialogue => const DialogueStudioWorkspace(),
  // Workspaces non narratifs: ce widget ne doit pas être utilisé.
  _ => const SizedBox.shrink(),
};

return NarrativeStudioShell(
  workspaceMode: editor.workspaceMode,
  onSelectOverview: editorNotifier.selectNarrativeOverviewWorkspace,
  onSelectGlobal: () {
    editorNotifier.selectGlobalStoryWorkspace();
    narrativeController.openGlobalStory(
      scenarioId: selectedGlobal?.id,
    );
  },
  onSelectStep: () {
    editorNotifier.selectStepWorkspace();
    narrativeController.openStep(
      stepId: selectedStep?.id,
      globalScenarioId: selectedStep?.globalScenarioId,
    );
  },
  onSelectCutscene: () {
    editorNotifier.selectCutsceneWorkspace();
    narrativeController.openCutscene(
      cutsceneScenarioId: selectedCutscene?.id,
    );
  },
  onSelectDialogue: editorNotifier.selectDialogueWorkspace,
  child: mainContent,
);
```

### Extrait modifié — test shell interne

```dart
testWidgets(
  'NarrativeWorkspaceCanvas renders the internal Narrative Studio shell',
  (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          editorNotifierProvider.overrideWith(
            () => _SeededEditorNotifier(
              EditorState(
                workspaceMode: EditorWorkspaceMode.narrativeOverview,
                project: _minimalProject('test_project'),
              ),
            ),
          ),
        ],
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 1200,
                height: 760,
                child: Column(
                  children: [
                    Expanded(child: NarrativeWorkspaceCanvas()),
                    _WorkspaceModeProbe(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final shell = find.byKey(const ValueKey('narrative-studio-shell'));
    final navigation =
        find.byKey(const ValueKey('narrative-studio-transitional-navigation'));
    final mainContent =
        find.byKey(const ValueKey('narrative-studio-main-content'));

    expect(shell, findsOneWidget);
    expect(navigation, findsOneWidget);
    expect(mainContent, findsOneWidget);
    expect(
      find.descendant(
        of: shell,
        matching: find.byKey(const ValueKey('narrative-overview-scroll')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: shell, matching: find.byType(ProjectExplorerPanel)),
      findsNothing,
    );

    for (final label in <String>[
      'Aperçu',
      'Histoire globale',
      'Étape',
      'Cinématique',
      'Dialogue',
    ]) {
      expect(
        find.descendant(of: navigation, matching: find.text(label)),
        findsOneWidget,
      );
    }
    for (final unavailable in <String>['Facts', 'World Rules', 'Validateur']) {
      expect(
        find.descendant(of: navigation, matching: find.text(unavailable)),
        findsNothing,
      );
    }
  },
);
```

### Confirmation des boundaries

```text
Aucun code production hors map_editor/ui/canvas n'a été modifié.
Aucun test hors narrative_overview_shell_navigation_test.dart n'a été modifié.
Aucun widget Flutter autre que NarrativeStudioShell n'a été créé.
Aucun provider n'a été créé.
Aucun fichier map_core/runtime/gameplay/battle n'a été modifié.
ProjectExplorerPanel n'a pas été modifié.
```

## 17. Auto-review critique

Points positifs :

```text
- l'architecture NS-HOME-15 est matérialisée ;
- le shell interne est testable via des keys dédiées ;
- le Project Explorer reste hors du shell interne ;
- la navigation existante reste fonctionnelle ;
- aucune destination future fake n'est rendue.
```

Risques / limites :

```text
- le strip horizontal peut encore ressembler à une navigation finale si on s'arrête ici ;
- la sidebar interne n'existe pas encore, donc l'amélioration est surtout architecturale ;
- la duplication de certains labels entre shell global et shell interne reste possible jusqu'à NS-HOME-17/18.
```

Mitigation :

```text
Le rapport documente explicitement que le strip est transitoire.
Le prochain lot doit créer la sidebar interne dans NarrativeStudioShell, pas dans ProjectExplorerPanel.
```

## 18. Regard critique sur le prompt

Le prompt était précis et utile parce qu'il séparait clairement :

```text
- création du shell interne maintenant ;
- sidebar interne plus tard ;
- Project Explorer global intouchable ;
- aucune donnée fake.
```

Point de vigilance pour le prochain prompt :

```text
NS-HOME-17 devra être encore plus strict sur les destinations disabled :
Facts / World Rules / Validateur doivent être visiblement non actifs ou absents,
pas simplement stylés comme des entrées normales.
```
