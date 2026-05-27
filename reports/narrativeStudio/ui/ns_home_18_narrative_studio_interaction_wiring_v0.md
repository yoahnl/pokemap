# NS-HOME-18 — Narrative Studio Interaction Wiring V0

## 1. Résumé exécutif

NS-HOME-18 rend interactives les zones du dashboard qui peuvent pointer vers un workspace narratif existant sans inventer de donnée ni de destination.

Interactions branchées :

- sidebar interne : `Aperçu`, `Storylines`, `Scènes`, `Cinématiques`, `Dialogues` ;
- KPI cards : `Chapitres`, `Scènes`, `Cinématiques`, `Dialogues` ;
- module cards : `Cinématiques`, `Dialogues` ;
- carte `Histoire principale` : bouton `Ouvrir Storylines` uniquement quand la source principale est explicite et éditable.

Interactions volontairement non branchées :

- `Quêtes`, `Problèmes ouverts`, `Quêtes annexes`, `Conditions narratives`, `Facts`, `Règles du monde`, `Validateur` ;
- `Maps` n'est pas réintroduit dans la sidebar interne, conformément à la clarification de Karim après NS-HOME-17.

Le `ProjectExplorerPanel` n'a pas été modifié et reste la sidebar globale PokeMap. Aucune donnée métier, aucun read model, aucun modèle `map_core`, aucun runtime/gameplay/battle n'a été touché.

## 2. Rappel du scope NS-HOME-18

Objectif du lot :

```text
Destination réelle → interaction réelle.
Destination future → disabled clair.
Destination ambiguë → pas d’action active.
```

Le lot devait rendre vivantes les parties déjà branchables du Narrative Studio, sans créer de nouvelle feature métier.

Périmètre respecté :

- callbacks locaux depuis `NarrativeWorkspaceCanvas` ;
- callbacks optionnels dans `NarrativeOverviewWorkspace` ;
- navigation interne déjà existante conservée dans `NarrativeStudioSidebar` / `NarrativeStudioShell` ;
- tests de clic pour les destinations actives et disabled ;
- screenshots Visual Gate.

Périmètre évité :

- pas de modification de `ProjectExplorerPanel` ;
- pas de provider global ;
- pas de repository ;
- pas de création de storyline ;
- pas de validation narrative globale ;
- pas de recherche/notification ;
- pas de réintroduction de `Maps`.

## 3. Fichiers créés / modifiés

Fichiers modifiés :

- `packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart`

Fichiers créés :

- `reports/narrativeStudio/ui/ns_home_18_narrative_studio_interaction_wiring_v0.md`
- `reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_wiring_desktop.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_wiring_focus.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_disabled_states.png`

Fichiers explicitement non modifiés :

- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart`
- tous les fichiers `map_core`, `map_runtime`, `map_gameplay`, `map_battle`.

## 4. Interactions rendues actives

### Sidebar interne

Les entrées déjà branchées restent actives :

| Entrée | Destination réelle |
| --- | --- |
| `Aperçu` | `EditorWorkspaceMode.narrativeOverview` |
| `Storylines` | `EditorWorkspaceMode.globalStory` |
| `Scènes` | `EditorWorkspaceMode.step` |
| `Cinématiques` | `EditorWorkspaceMode.cutscene` |
| `Dialogues` | `EditorWorkspaceMode.dialogue` |

Le mapping `Scènes -> step` reste prudent : il correspond au workspace existant d'étapes narratives, sans créer un module scène distinct.

### KPI cards

KPI branchées :

| KPI | Destination |
| --- | --- |
| `Chapitres` | `globalStory` |
| `Scènes` | `step` |
| `Cinématiques` | `cutscene` |
| `Dialogues` | `dialogue` |

Les cartes actives affichent une petite affordance `arrow_right_circle`. Le calcul des valeurs vient toujours du read model existant.

### Module cards

Modules branchés :

| Module | Destination |
| --- | --- |
| `Cinématiques` | `cutscene` |
| `Dialogues` | `dialogue` |

L'affordance `Studio relié` est maintenant réservée aux modules réellement cliquables. Les autres modules restent en `Accès à venir`.

### Histoire principale

Le bouton de la carte principale devient `Ouvrir Storylines` uniquement si :

```dart
story.canEdit &&
story.availability == NarrativeOverviewAvailability.available &&
story.sourceStatus == NarrativeOverviewSourceStatus.explicit
```

Dans les états empty/ambiguous/unavailable, l'action reste `Modifier à venir` et ne navigue pas.

## 5. Interactions laissées disabled

Éléments non branchés :

| Élément | Décision |
| --- | --- |
| `Quêtes` KPI | non actif, pas de modèle Quest |
| `Problèmes ouverts` KPI | non actif, validation globale non branchée |
| `Quêtes annexes` module | non actif, hors scope V0 |
| `Conditions narratives` module | non actif, mapping encore ambigu entre step/global story |
| `Facts` | non actif, nécessite un modèle |
| `Règles du monde` | non actif, pas de workspace dédié fiable |
| `Validateur` | non actif, validation globale non branchée |
| `Maps` | absent de la sidebar interne |

Le choix sur `Conditions narratives` est volontairement conservateur : le read model historique contient une destination technique, mais le sens produit reste trop ambigu pour activer une navigation sans clarification.

## 6. Architecture des callbacks

L'architecture évite que les cartes Overview connaissent `EditorNotifier`.

Flux retenu :

```text
NarrativeWorkspaceCanvas
→ construit les callbacks de navigation
→ passe les callbacks à NarrativeStudioShell
→ NarrativeStudioShell les passe à NarrativeStudioSidebar
→ NarrativeWorkspaceCanvas passe les callbacks Overview à NarrativeOverviewWorkspace
→ les KPI / modules / carte principale appellent seulement des VoidCallback? optionnels
```

Callbacks ajoutés côté Overview :

```dart
VoidCallback? onOpenStorylines
VoidCallback? onOpenScenes
VoidCallback? onOpenCutscenes
VoidCallback? onOpenDialogues
```

Les widgets de cartes restent passifs : ils ne lisent ni provider, ni notifier, ni repository.

## 7. Mapping UI → workspace destinations

| UI | Destination | Actif ? |
| --- | --- | --- |
| Sidebar `Aperçu` | `narrativeOverview` | oui |
| Sidebar `Storylines` | `globalStory` | oui |
| Sidebar `Scènes` | `step` | oui |
| Sidebar `Cinématiques` | `cutscene` | oui |
| Sidebar `Dialogues` | `dialogue` | oui |
| Sidebar `Facts` | aucune | disabled |
| Sidebar `Règles du monde` | aucune | disabled |
| Sidebar `Validateur` | aucune | disabled |
| Sidebar `Maps` | aucune | absent |
| KPI `Chapitres` | `globalStory` | oui |
| KPI `Scènes` | `step` | oui |
| KPI `Cinématiques` | `cutscene` | oui |
| KPI `Dialogues` | `dialogue` | oui |
| KPI `Quêtes` | aucune | disabled |
| KPI `Problèmes ouverts` | aucune | disabled |
| Module `Cinématiques` | `cutscene` | oui |
| Module `Dialogues` | `dialogue` | oui |
| Module `Quêtes annexes` | aucune | disabled |
| Module `Conditions narratives` | aucune | disabled |
| Module `Règles du monde` | aucune | disabled |
| Module `Facts` | aucune | disabled |
| Histoire principale explicite | `globalStory` | oui |
| Histoire principale vide | aucune | disabled |

## 8. Ce qui reste volontairement hors scope

- Collapse ou handoff du `ProjectExplorerPanel` global.
- Destination `Maps` dans le Narrative Studio.
- Création d'une storyline.
- Validation globale narrative.
- Recherche narrative.
- Notifications.
- Vrai modèle `Facts`.
- Vrai module `World Rules`.
- Vrai module `Quest`.
- Refonte visuelle majeure de la sidebar interne.
- Changement du read model.

## 9. Tests ajoutés / modifiés

Tests modifiés :

- `narrative_overview_shell_navigation_test.dart`
  - ajoute un test de wiring des cartes Overview vers les seuls workspaces réels ;
  - vérifie que `Quêtes`, `Problèmes ouverts`, `Quêtes annexes`, `Conditions narratives`, `Règles du monde`, `Facts` ne changent pas de workspace ;
  - vérifie que `Maps` n'est pas rendu ;
  - ajoute la capture des screenshots NS-HOME-18.

- `narrative_overview_workspace_test.dart`
  - ajoute les callbacks optionnels au helper de rendu ;
  - vérifie que `Modifier à venir` ne déclenche rien sur une histoire principale vide ;
  - vérifie que `Ouvrir Storylines` est actif uniquement avec une histoire principale explicite.

Les tests existants de top bar, status bar et selectors restent inchangés et passent.

## 10. Visual Gate

Screenshots produits :

- `reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_wiring_desktop.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_wiring_focus.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_disabled_states.png`

Méthode :

```bash
cd packages/map_editor
flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_18_CAPTURE_INTERACTION_DESKTOP=true
flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_18_CAPTURE_INTERACTION_FOCUS=true
flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_18_CAPTURE_INTERACTION_DISABLED_STATES=true
```

Résultat visuel depuis NS-HOME-17 :

- la sidebar interne reste visible et distincte du Project Explorer global ;
- le strip horizontal transitoire ne revient pas ;
- `Maps` n'est pas présent ;
- les KPI branchables affichent une affordance sobre ;
- `Quêtes` et `Problèmes ouverts` restent non cliquables ;
- `Cinématiques` et `Dialogues` sont clairement reliés côté modules ;
- `Quêtes annexes`, `Conditions narratives`, `Règles du monde`, `Facts` restent à venir ;
- la carte `Histoire principale` reste disabled sur l'état empty du screenshot ;
- le dashboard reste lisible avec les deux sidebars V0.

Ce qui ne correspond pas encore à l'image cible :

- le Project Explorer global reste visible à gauche ;
- la sidebar interne n'est pas encore la sidebar finale pixel-polished ;
- les actions top bar futures restent disabled ;
- `Facts`, `World Rules`, `Validateur` ne sont pas des destinations actives.

Hors scope NS-HOME-18 :

- collapse du Project Explorer ;
- reconstruction finale de la top bar/sidebar ;
- activation de Maps ou Validateur ;
- création de données narratives.

Correction après inspection :

- l'analyse globale a révélé deux variables de test inutilisées introduites pendant le wiring ; elles ont été supprimées avant l'analyse ciblée finale.

## 11. Commandes exécutées

```bash
cd /Users/karim/Project/pokemonProject
pwd && git branch --show-current && git status --short --untracked-files=all
```

```bash
cd packages/map_editor
dart format lib/src/ui/canvas/narrative_overview_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/ui/canvas/narrative_overview_workspace_test.dart
flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart
flutter test test/ui/canvas/narrative_overview_workspace_test.dart
flutter test test/top_toolbar_test.dart
flutter test test/editor_selectors_test.dart
flutter test test/status_bar_test.dart
flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/top_toolbar_test.dart test/editor_selectors_test.dart test/status_bar_test.dart
flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_18_CAPTURE_INTERACTION_DESKTOP=true
flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_18_CAPTURE_INTERACTION_FOCUS=true
flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_18_CAPTURE_INTERACTION_DISABLED_STATES=true
flutter analyze
flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_studio_shell.dart lib/src/ui/canvas/narrative_studio_sidebar.dart lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/narrative_overview_workspace.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/ui/canvas/narrative_overview_workspace_test.dart
```

```bash
cd /Users/karim/Project/pokemonProject
git diff --check
git diff --stat
git diff --name-only
file reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_wiring_desktop.png reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_wiring_focus.png reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_disabled_states.png
stat -f '%N %Sm %z' reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_wiring_desktop.png reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_wiring_focus.png reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_disabled_states.png
```

## 12. Résultats des tests

`flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart`

```text
00:02 +15: All tests passed!
```

`flutter test test/ui/canvas/narrative_overview_workspace_test.dart`

```text
00:02 +29: All tests passed!
```

`flutter test test/top_toolbar_test.dart`

```text
00:00 +10: All tests passed!
```

`flutter test test/editor_selectors_test.dart`

```text
00:00 +9: All tests passed!
```

`flutter test test/status_bar_test.dart`

```text
00:00 +6: All tests passed!
```

Régression combinée :

```text
00:03 +69: All tests passed!
```

Screenshots NS-HOME-18 :

```text
00:02 +15: All tests passed!
```

pour chaque commande de capture desktop, focus et disabled states.

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
error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
347 issues found. (ran in 2.1s)
```

Conclusion : l'analyse globale échoue sur une dette préexistante hors scope, notamment le convertisseur Pokémon SDK et des infos historiques. Aucune occurrence ne concerne les fichiers modifiés NS-HOME-18.

Analyse ciblée :

```text
Analyzing 6 items...
No issues found! (ran in 1.2s)
```

Une première tentative d'analyse ciblée lancée en parallèle d'un test Flutter a échoué sur le verrou Flutter :

```text
Unable to delete file or directory at ".../macos/Flutter/ephemeral/Packages/.packages".
```

Elle a été relancée seule et a réussi.

## 14. Limites

- Le Project Explorer global reste visible à côté de la sidebar interne : le collapse/handoff est prévu pour un lot ultérieur.
- `Conditions narratives` reste disabled malgré une destination technique historique, car le mapping produit n'est pas encore assez clair.
- `Quêtes`, `Facts`, `Règles du monde`, `Validateur` restent des surfaces futures.
- Les screenshots montrent l'état V0 avec deux sidebars ; c'est acceptable pour ce lot mais pas l'état final.

## 15. Prochain lot recommandé

Prochain lot recommandé :

```text
NS-HOME-19 — Project Explorer Collapse / Narrative Studio Handoff Strategy V0
```

Objectif proposé :

- définir puis implémenter le comportement du Project Explorer global quand l'utilisateur entre dans le Narrative Studio ;
- garder le Project Explorer disponible comme navigation globale PokeMap ;
- éviter que les deux sidebars consomment trop d'espace sur desktop/medium ;
- ne pas masquer définitivement l'explorer global ;
- produire un Visual Gate comparant l'état avec deux sidebars à l'état handoff V0.

## 16. Evidence Pack

### Branche

```text
main
```

### Git status initial

Statut relevé dans la passe finale avant création du rapport :

```text
 M packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
?? reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_disabled_states.png
?? reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_wiring_desktop.png
?? reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_wiring_focus.png
```

### Git status final attendu

Après création de ce rapport :

```text
 M packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
?? reports/narrativeStudio/ui/ns_home_18_narrative_studio_interaction_wiring_v0.md
?? reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_disabled_states.png
?? reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_wiring_desktop.png
?? reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_wiring_focus.png
```

### Git diff --stat final

`git diff` ne liste pas les fichiers non trackés.

```text
.../ui/canvas/narrative_overview_workspace.dart    | 247 +++++++++++++++++----
.../src/ui/canvas/narrative_workspace_canvas.dart  |  60 +++--
.../narrative_overview_shell_navigation_test.dart  | 167 ++++++++++++++
.../canvas/narrative_overview_workspace_test.dart  |  60 ++++-
4 files changed, 460 insertions(+), 74 deletions(-)
```

### Git diff --name-only final

```text
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
```

### Git diff --check final

```text
```

Sortie vide : aucun whitespace error.

### Fichiers créés

```text
reports/narrativeStudio/ui/ns_home_18_narrative_studio_interaction_wiring_v0.md
reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_disabled_states.png
reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_wiring_desktop.png
reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_wiring_focus.png
```

Les screenshots sont des fichiers binaires non listés par `git diff`.

### Fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
```

### Extraits des sections modifiées

Callbacks Overview :

```dart
const NarrativeOverviewWorkspace({
  super.key,
  required this.readModel,
  this.onOpenStorylines,
  this.onOpenScenes,
  this.onOpenCutscenes,
  this.onOpenDialogues,
});

final VoidCallback? onOpenStorylines;
final VoidCallback? onOpenScenes;
final VoidCallback? onOpenCutscenes;
final VoidCallback? onOpenDialogues;
```

Callbacks dans `NarrativeWorkspaceCanvas` :

```dart
void openGlobalStory() {
  editorNotifier.selectGlobalStoryWorkspace();
  narrativeController.openGlobalStory(
    scenarioId: selectedGlobal?.id,
  );
}

void openStep() {
  editorNotifier.selectStepWorkspace();
  narrativeController.openStep(
    stepId: selectedStep?.id,
    globalScenarioId: selectedStep?.globalScenarioId,
  );
}
```

Mapping KPI :

```dart
VoidCallback? _metricCallback(String metricId) {
  return switch (metricId) {
    'chapters' => onOpenStorylines,
    'scenes' => onOpenScenes,
    'cutscenes' => onOpenCutscenes,
    'dialogues' => onOpenDialogues,
    _ => null,
  };
}
```

Mapping modules :

```dart
VoidCallback? _moduleCallback(String moduleId) {
  return switch (moduleId) {
    NarrativeOverviewModuleIds.cutscenes => onOpenCutscenes,
    NarrativeOverviewModuleIds.dialogues => onOpenDialogues,
    _ => null,
  };
}
```

Action Histoire principale :

```dart
final canOpenStorylines = story.canEdit &&
    story.availability == NarrativeOverviewAvailability.available &&
    story.sourceStatus == NarrativeOverviewSourceStatus.explicit;
```

Test de non-réintroduction de Maps :

```dart
expect(find.text('Maps'), findsNothing);
```

### Screenshots produits

```text
reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_wiring_desktop.png:  PNG image data, 1600 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_wiring_focus.png:    PNG image data, 1600 x 700, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_disabled_states.png: PNG image data, 1600 x 1000, 8-bit/color RGBA, non-interlaced
```

```text
reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_wiring_desktop.png May 27 18:22:01 2026 208332
reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_wiring_focus.png May 27 18:22:11 2026 164854
reports/narrativeStudio/ui/screenshots/ns_home_18_interaction_disabled_states.png May 27 18:22:22 2026 237135
```

### Analyse visuelle de chaque screenshot

`ns_home_18_interaction_wiring_desktop.png`

- montre le shell global PokeMap, le Project Explorer global et la sidebar interne Narrative Studio ;
- les KPI actives sont identifiables ;
- les KPI `Quêtes` et `Problèmes ouverts` restent non actives ;
- le layout avec deux sidebars reste acceptable en V0.

`ns_home_18_interaction_wiring_focus.png`

- montre clairement la sidebar interne, le header et les KPI ;
- les affordances d'interaction sont visibles sans écraser la hiérarchie ;
- pas d'overflow évident dans le haut de page.

`ns_home_18_interaction_disabled_states.png`

- montre les modules et les états disabled ;
- `Cinématiques` et `Dialogues` apparaissent comme reliés ;
- `Quêtes annexes`, `Conditions narratives`, `Règles du monde`, `Facts` restent `Accès à venir` ou équivalent honnête ;
- aucun faux compteur ou badge notification n'apparaît.

### Confirmations de non-régression de périmètre

- `ProjectExplorerPanel` non modifié.
- `NarrativeOverviewReadModel` non modifié.
- Aucun fichier `map_core` modifié.
- Aucun fichier `map_runtime` modifié.
- Aucun fichier `map_gameplay` modifié.
- Aucun fichier `map_battle` modifié.
- Aucun provider global créé.
- Aucun repository créé.
- Aucune donnée Selbrume, tag de l'image, `FR`, `v0.3.0` ou chiffre cible hardcodé.

## 17. Auto-review critique

Points satisfaisants :

- les interactions ajoutées sont limitées aux destinations réelles ;
- les tests couvrent à la fois clics actifs et clics disabled ;
- `Maps` reste absent ;
- la structure de callbacks garde l'Overview découplé de `EditorNotifier` ;
- l'analyse ciblée est clean.

Points à surveiller :

- la présence simultanée du Project Explorer global et de la sidebar interne consomme beaucoup d'espace ;
- `Conditions narratives` devra être reclarifié avant de devenir actif ;
- l'affordance des cartes actives est volontairement sobre, mais pourra être enrichie quand les interactions seront plus nombreuses.

## 18. Regard critique sur le prompt

Le prompt est utilement strict sur le principe "destination réelle seulement". Le point à clarifier pour les prochains lots est la place de `Conditions narratives` : le read model historique laisse croire à une destination technique, mais la surface produit ne dit pas encore si elle relève de `step`, `globalStory` ou d'un futur module dédié.

La clarification de Karim sur `Maps` est intégrée : `Maps` ne doit plus apparaître dans la sidebar interne Narrative Studio tant qu'un besoin produit réel n'est pas redéfini.
