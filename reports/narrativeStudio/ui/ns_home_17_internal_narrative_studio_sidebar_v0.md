# NS-HOME-17 — Internal Narrative Studio Sidebar V0

## 1. Résumé exécutif

NS-HOME-17 crée la première vraie sidebar interne du Narrative Studio dans `NarrativeStudioShell`.

La séparation produit est respectée :

```text
ProjectExplorerPanel = sidebar globale PokeMap
NarrativeStudioSidebar = navigation interne Narrative Studio
```

Le `ProjectExplorerPanel` n'a pas été modifié. Le strip horizontal transitoire de NS-HOME-16 n'est plus la navigation visible principale. Il est remplacé par `NarrativeStudioSidebar`, rendue à l'intérieur du shell interne.

La sidebar V0 expose :

```text
Actifs :
- Aperçu
- Storylines
- Scènes
- Cinématiques
- Dialogues

Disabled / non actifs :
- Facts : Nécessite un modèle
- Règles du monde : À venir
- Validateur : Non branché
```

Correction post-review Karim :

```text
Karim a confirmé que l'onglet “Maps” ne sert pas dans la sidebar interne Narrative Studio.
L'entrée a donc été retirée de NarrativeStudioSidebar, des tests et des screenshots NS-HOME-17.
Les maps restent une responsabilité du chrome global PokeMap tant qu'aucune destination narrative dédiée n'est définie.
```

## 2. Rappel du scope NS-HOME-17

Objectif :

```text
Créer la première vraie sidebar interne du Narrative Studio à l'intérieur de NarrativeStudioShell,
sans remplacer le ProjectExplorerPanel global,
sans activer de fausses destinations,
sans créer Facts / World Rules / Validateur comme vrais modules,
sans modifier le read model,
et avec un Visual Gate screenshot.
```

Règle non négociable respectée :

```text
ProjectExplorerPanel = sidebar globale PokeMap / entrée globale vers Narrative Studio
NarrativeStudioSidebar = navigation interne du Narrative Studio
```

## 3. Fichiers créés / modifiés

Fichiers créés :

```text
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
reports/narrativeStudio/ui/ns_home_17_internal_narrative_studio_sidebar_v0.md
reports/narrativeStudio/ui/screenshots/ns_home_17_internal_sidebar_desktop.png
reports/narrativeStudio/ui/screenshots/ns_home_17_internal_sidebar_focus.png
reports/narrativeStudio/ui/screenshots/ns_home_17_internal_sidebar_medium.png
```

Fichiers modifiés :

```text
packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart
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

## 4. Architecture Sidebar interne créée

Architecture obtenue :

```text
PokeMap App Shell
├─ Project Explorer global
└─ Workspace host
   └─ NarrativeStudioShell
      ├─ NarrativeStudioSidebar
      └─ contenu Narrative Studio
```

`NarrativeStudioSidebar` reçoit uniquement :

```text
- workspaceMode
- callbacks de navigation existants
- compact
```

Il ne reçoit pas :

```text
- ProjectManifest brut ;
- read model Overview ;
- SaveData ;
- GameState ;
- repository ;
- provider global nouveau.
```

## 5. Mapping des destinations internes

| Entrée sidebar | État V0 | Mapping |
|---|---:|---|
| Aperçu | actif | `EditorWorkspaceMode.narrativeOverview` |
| Storylines | actif | `EditorWorkspaceMode.globalStory` |
| Scènes | actif | `EditorWorkspaceMode.step` |
| Cinématiques | actif | `EditorWorkspaceMode.cutscene` |
| Dialogues | actif | `EditorWorkspaceMode.dialogue` |
| Facts | disabled | Nécessite un modèle |
| Règles du monde | disabled | À venir |
| Validateur | disabled | Non branché |

Décision `Scènes` :

```text
Le label visible est “Scènes” pour se rapprocher de la cible produit.
Le sous-label “Étapes narratives” documente honnêtement le mapping vers le workspace existant `step`.
```

## 6. Entrées actives vs disabled

Entrées actives :

```text
Aperçu
Storylines
Scènes
Cinématiques
Dialogues
```

Elles sont des boutons et déclenchent les callbacks existants.

Entrées disabled :

```text
Facts
Règles du monde
Validateur
```

Elles sont rendues comme lignes non interactives. Les tests vérifient que cliquer ces entrées ne change pas le workspace.

Décision `Maps` :

```text
L'entrée “Maps” a été retirée après clarification de Karim.
Elle n'est plus affichée comme destination interne, même disabled, car elle ne sert pas dans le shell interne Narrative Studio V0.
```

Aucun compteur n'est affiché dans la sidebar. Aucun badge notification n'est créé.

## 7. Remplacement du strip transitoire

NS-HOME-16 contenait une navigation horizontale transitoire :

```text
narrative-studio-transitional-navigation
```

NS-HOME-17 la retire de l'UI visible principale. `NarrativeStudioShell` rend désormais :

```text
Row
├─ NarrativeStudioSidebar
└─ Expanded(main content)
```

Le test vérifie :

```text
find.byKey(ValueKey('narrative-studio-transitional-navigation')) == findsNothing
```

## 8. Ce qui reste volontairement hors scope

```text
- collapse automatique du Project Explorer global ;
- stratégie responsive mobile complète ;
- vrai modèle Facts ;
- vrai module World Rules ;
- vrai Validateur global ;
- création de storyline ;
- validation narrative active ;
- recherche globale ;
- centre de notifications ;
- badge notification ;
- modification du read model Overview.
```

## 9. Tests ajoutés / modifiés

Le test principal `NarrativeWorkspaceCanvas renders the internal Narrative Studio shell` vérifie maintenant :

```text
- NarrativeStudioSidebar est rendu dans NarrativeStudioShell ;
- ProjectExplorerPanel n'est pas descendant du shell interne ;
- le strip transitoire n'est plus rendu ;
- Aperçu est actif en narrativeOverview ;
- Storylines navigue vers globalStory ;
- Scènes navigue vers step ;
- Cinématiques navigue vers cutscene ;
- Dialogues navigue vers dialogue ;
- Maps n'est plus rendu dans la sidebar interne ;
- Facts / Règles du monde / Validateur sont visibles mais disabled ;
- cliquer une entrée disabled ne change pas de workspace.
```

Un test screenshot NS-HOME-17 a aussi été ajouté :

```text
NarrativeOverviewWorkspace captures NS-HOME-17 internal sidebar screenshots when requested
```

## 10. Visual Gate

Screenshots produits :

```text
reports/narrativeStudio/ui/screenshots/ns_home_17_internal_sidebar_desktop.png
reports/narrativeStudio/ui/screenshots/ns_home_17_internal_sidebar_focus.png
reports/narrativeStudio/ui/screenshots/ns_home_17_internal_sidebar_medium.png
```

Méthode :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_17_CAPTURE_INTERNAL_SIDEBAR_DESKTOP=true
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_17_CAPTURE_INTERNAL_SIDEBAR_FOCUS=true
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_17_CAPTURE_INTERNAL_SIDEBAR_MEDIUM=true
```

Métadonnées :

```text
reports/narrativeStudio/ui/screenshots/ns_home_17_internal_sidebar_desktop.png: PNG image data, 1600 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/ui/screenshots/ns_home_17_internal_sidebar_focus.png:   PNG image data, 1600 x 700, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/ui/screenshots/ns_home_17_internal_sidebar_medium.png:  PNG image data, 1180 x 1000, 8-bit/color RGBA, non-interlaced
May 27 17:45:43 2026 218409 reports/narrativeStudio/ui/screenshots/ns_home_17_internal_sidebar_desktop.png
May 27 17:46:03 2026 173897 reports/narrativeStudio/ui/screenshots/ns_home_17_internal_sidebar_focus.png
May 27 17:46:16 2026 185995 reports/narrativeStudio/ui/screenshots/ns_home_17_internal_sidebar_medium.png
```

Analyse visuelle :

```text
- La sidebar interne est visible entre le Project Explorer global et le contenu Overview.
- Le Project Explorer global reste distinct et inchangé.
- La navigation horizontale transitoire n'apparaît plus.
- Les entrées actives et disabled sont groupées dans une seule navigation interne.
- Les entrées disabled sont visuellement plus discrètes et ne ressemblent pas à des modules actifs.
- L'entrée Maps n'est plus visible : Karim a confirmé qu'elle ne sert pas dans la sidebar interne.
- Le layout “deux sidebars” est dense mais acceptable en V0, car le collapse du Project Explorer est hors scope.
- Le screenshot medium reste stable : pas d'overflow visible, KPI et Histoire principale restent accessibles.
```

Défaut corrigé après inspection :

```text
Le premier screenshot focus révélait un RenderFlex overflow vertical dans la sidebar.
Correction : densité réduite et scroll interne ajouté à la sidebar.
Une seconde inspection a montré un contraste trop clair ; correction : palette locale dark pour la sidebar.
```

Ce qui ne correspond pas encore à l'image cible :

```text
- le Project Explorer global reste visible ;
- la sidebar interne est compacte, car elle cohabite temporairement avec le Project Explorer ;
- Facts / Règles du monde / Validateur ne sont pas encore des destinations actives ;
- Maps n'est pas exposé dans la sidebar interne Narrative Studio ;
- le chrome final de l'image cible n'est pas reconstruit.
```

## 11. Commandes exécutées

```bash
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
cd packages/map_editor && dart format lib/src/ui/canvas/narrative_studio_sidebar.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart
cd packages/map_editor && flutter test test/top_toolbar_test.dart
cd packages/map_editor && flutter test test/editor_selectors_test.dart
cd packages/map_editor && flutter test test/status_bar_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/top_toolbar_test.dart test/editor_selectors_test.dart test/status_bar_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_17_CAPTURE_INTERNAL_SIDEBAR_DESKTOP=true
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_17_CAPTURE_INTERNAL_SIDEBAR_FOCUS=true
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_17_CAPTURE_INTERNAL_SIDEBAR_MEDIUM=true
cd packages/map_editor && flutter analyze
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_studio_shell.dart lib/src/ui/canvas/narrative_studio_sidebar.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/ui/canvas/narrative_overview_workspace_test.dart
git diff --check
```

## 12. Résultats des tests

### TDD red attendu

Avant création de `NarrativeStudioSidebar`, le test échouait comme prévu :

```text
Expected: exactly one matching candidate
Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'narrative-studio-sidebar'>]: []>
Test: NarrativeWorkspaceCanvas renders the internal Narrative Studio shell
```

Correction post-review Maps :

```text
Expected: no matching candidates
Actual: _DescendantWidgetFinder:<Found 1 widget with text "Maps" descending from widget with key [<'narrative-studio-sidebar'>]: [...]>
Test: NarrativeWorkspaceCanvas renders the internal Narrative Studio shell
```

Ce red confirme que le test détectait bien l'ancienne entrée Maps avant sa suppression.

### Test shell navigation

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
00:00 +0: NarrativeWorkspaceCanvas routes overview mode to the overview shell
00:00 +1: NarrativeWorkspaceCanvas renders the internal Narrative Studio shell
00:01 +2: NarrativeLibraryPanel exposes overview without removing existing studios
00:01 +3: EditorShellPage presents coherent Narrative Studio overview chrome
00:01 +4: ProjectExplorerPanel prioritizes narrative navigation in overview mode
00:01 +5: NarrativeOverviewWorkspace captures a full editor shell screenshot when requested
00:01 +6: NarrativeOverviewWorkspace captures NS-HOME-11 sidebar navigation screenshots when requested
00:01 +7: NarrativeOverviewWorkspace captures NS-HOME-12 top bar screenshots when requested
00:01 +8: NarrativeOverviewWorkspace captures NS-HOME-13 breadcrumb header screenshots when requested
00:01 +9: NarrativeOverviewWorkspace captures NS-HOME-14 header density screenshots when requested
00:01 +10: NarrativeOverviewWorkspace captures NS-HOME-16 internal shell screenshots when requested
00:01 +11: NarrativeOverviewWorkspace captures NS-HOME-17 internal sidebar screenshots when requested
00:01 +12: NarrativeOverviewWorkspace captures NS-HOME-10 shell chrome screenshots when requested
00:01 +13: All tests passed!
```

### Test overview workspace

```text
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
00:02 +59: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures KPI cards screenshot when requested
00:02 +60: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures main story card screenshot when requested
00:02 +61: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures module cards grid screenshot when requested
00:02 +62: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures structure inspector screenshot when requested
00:02 +63: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures empty states and footer screenshot when requested
00:02 +64: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures responsive polish desktop screenshot when requested
00:02 +65: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures responsive polish medium screenshot when requested
00:02 +66: All tests passed!
```

### Screenshots via dart-define

```text
NS_HOME_17_CAPTURE_INTERNAL_SIDEBAR_DESKTOP=true
00:01 +13: All tests passed!

NS_HOME_17_CAPTURE_INTERNAL_SIDEBAR_FOCUS=true
00:01 +13: All tests passed!

NS_HOME_17_CAPTURE_INTERNAL_SIDEBAR_MEDIUM=true
00:01 +13: All tests passed!
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
347 issues found. (ran in 3.1s)
```

Analyse ciblée :

```text
Analyzing 5 items...
No issues found! (ran in 1.4s)
```

Conclusion :

```text
flutter analyze global échoue sur dette préexistante Pokémon SDK catalog.
L'analyse ciblée des fichiers NS-HOME-17 est clean.
```

## 14. Limites

```text
- Deux sidebars cohabitent temporairement : Project Explorer global + sidebar interne.
- La sidebar interne est volontairement compacte jusqu'au lot de collapse/handoff.
- Facts / Règles du monde / Validateur sont visibles mais non actifs.
- Maps n'est plus affiché dans la sidebar interne après clarification de Karim.
- Structure narrative peut ne pas apparaître dans la première hauteur du screenshot desktop à cause de la largeur consommée par les deux sidebars ; elle reste présente dans le workspace Overview.
```

## 15. Prochain lot recommandé

```text
NS-HOME-18 — Project Explorer Collapse / Handoff Strategy V0
```

Objectif recommandé :

```text
Définir et implémenter prudemment le comportement de cohabitation entre Project Explorer global
et NarrativeStudioSidebar interne : garder, réduire, ou masquer l'explorer global en mode narratif,
sans supprimer l'accès global PokeMap et sans casser les autres workspaces.
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

### Git status initial de la correction post-review Maps

```text
 M packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
?? packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
?? reports/narrativeStudio/ui/ns_home_17_internal_narrative_studio_sidebar_v0.md
?? reports/narrativeStudio/ui/screenshots/ns_home_17_internal_sidebar_desktop.png
?? reports/narrativeStudio/ui/screenshots/ns_home_17_internal_sidebar_focus.png
?? reports/narrativeStudio/ui/screenshots/ns_home_17_internal_sidebar_medium.png
```

Cette correction a été faite sur le lot NS-HOME-17 déjà non stagé, sans commande Git d'écriture.

### Git status final

```text
 M packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
?? packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
?? reports/narrativeStudio/ui/ns_home_17_internal_narrative_studio_sidebar_v0.md
?? reports/narrativeStudio/ui/screenshots/ns_home_17_internal_sidebar_desktop.png
?? reports/narrativeStudio/ui/screenshots/ns_home_17_internal_sidebar_focus.png
?? reports/narrativeStudio/ui/screenshots/ns_home_17_internal_sidebar_medium.png
```

### Git diff --stat final

```text
 .../lib/src/ui/canvas/narrative_studio_shell.dart  | 145 ++++-----------------
 .../narrative_overview_shell_navigation_test.dart  | 128 +++++++++++++++---
 2 files changed, 134 insertions(+), 139 deletions(-)
```

Rappel :

```text
Les fichiers non trackés ne sont pas listés par git diff --stat.
Le contenu complet du nouveau widget est donc inclus ci-dessous.
```

### Git diff --name-only final

```text
packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart
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

class NarrativeStudioSidebar extends StatelessWidget {
  const NarrativeStudioSidebar({
    super.key,
    required this.workspaceMode,
    required this.onSelectOverview,
    required this.onSelectGlobal,
    required this.onSelectStep,
    required this.onSelectCutscene,
    required this.onSelectDialogue,
    required this.compact,
  });

  final EditorWorkspaceMode workspaceMode;
  final VoidCallback onSelectOverview;
  final VoidCallback onSelectGlobal;
  final VoidCallback onSelectStep;
  final VoidCallback onSelectCutscene;
  final VoidCallback onSelectDialogue;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Navigation interne Narrative Studio',
      child: Container(
        key: const ValueKey('narrative-studio-sidebar'),
        width: compact ? 132 : 154,
        decoration: BoxDecoration(
          color: _NarrativeSidebarColors.panelFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _NarrativeSidebarColors.panelBorder,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Narrative Studio',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _NarrativeSidebarColors.primaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 1),
              const Text(
                'Navigation interne',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _NarrativeSidebarColors.mutedText,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 7),
              _SidebarEntry(
                key: const ValueKey('narrative-studio-sidebar-overview'),
                icon: CupertinoIcons.square_grid_2x2,
                label: 'Aperçu',
                subtitle: 'Dashboard auteur',
                selected:
                    workspaceMode == EditorWorkspaceMode.narrativeOverview,
                onTap: onSelectOverview,
              ),
              _SidebarEntry(
                key: const ValueKey('narrative-studio-sidebar-storylines'),
                icon: CupertinoIcons.doc_text,
                label: 'Storylines',
                subtitle: 'Histoire globale',
                selected: workspaceMode == EditorWorkspaceMode.globalStory,
                onTap: onSelectGlobal,
              ),
              _SidebarEntry(
                key: const ValueKey('narrative-studio-sidebar-scenes'),
                icon: CupertinoIcons.square_grid_2x2,
                label: 'Scènes',
                subtitle: 'Étapes narratives',
                selected: workspaceMode == EditorWorkspaceMode.step,
                onTap: onSelectStep,
              ),
              _SidebarEntry(
                key: const ValueKey('narrative-studio-sidebar-cutscenes'),
                icon: CupertinoIcons.film,
                label: 'Cinématiques',
                subtitle: 'Studio existant',
                selected: workspaceMode == EditorWorkspaceMode.cutscene,
                onTap: onSelectCutscene,
              ),
              _SidebarEntry(
                key: const ValueKey('narrative-studio-sidebar-dialogues'),
                icon: CupertinoIcons.text_bubble,
                label: 'Dialogues',
                subtitle: 'Studio existant',
                selected: workspaceMode == EditorWorkspaceMode.dialogue,
                onTap: onSelectDialogue,
              ),
              const SizedBox(height: 4),
              const _SidebarEntry(
                key: ValueKey('narrative-studio-sidebar-facts'),
                icon: CupertinoIcons.doc_text,
                label: 'Facts',
                subtitle: 'Nécessite un modèle',
                selected: false,
              ),
              const _SidebarEntry(
                key: ValueKey('narrative-studio-sidebar-world-rules'),
                icon: CupertinoIcons.checkmark_seal,
                label: 'Règles du monde',
                subtitle: 'À venir',
                selected: false,
              ),
              const _SidebarEntry(
                key: ValueKey('narrative-studio-sidebar-validator'),
                icon: CupertinoIcons.check_mark_circled,
                label: 'Validateur',
                subtitle: 'Non branché',
                selected: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarEntry extends StatelessWidget {
  const _SidebarEntry({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  bool get _enabled => onTap != null;

  @override
  Widget build(BuildContext context) {
    final accent = selected
        ? EditorChrome.inspectorJoyCyan
        : _enabled
            ? EditorChrome.accentPrimary
            : _NarrativeSidebarColors.disabledText;
    final borderColor = selected
        ? EditorChrome.inspectorJoyCyan.withValues(alpha: 0.72)
        : _NarrativeSidebarColors.itemBorder;
    final fill = selected
        ? EditorChrome.inspectorJoyCyan.withValues(alpha: 0.14)
        : _enabled
            ? _NarrativeSidebarColors.itemFill
            : _NarrativeSidebarColors.disabledFill;

    final content = Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _enabled
                        ? _NarrativeSidebarColors.primaryText
                        : _NarrativeSidebarColors.disabledText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selected ? 'Actif' : subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        selected ? accent : _NarrativeSidebarColors.mutedText,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!_enabled) {
      return content;
    }

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: content,
    );
  }
}

abstract final class _NarrativeSidebarColors {
  static const panelFill = Color(0xFF102033);
  static const panelBorder = Color(0x334A89FF);
  static const itemFill = Color(0xFF14263A);
  static const disabledFill = Color(0xFF111B27);
  static const itemBorder = Color(0x2E6BA8FF);
  static const primaryText = Color(0xFFE6EEF8);
  static const mutedText = Color(0xFF8EA0B5);
  static const disabledText = Color(0xFF718197);
}
```

### Extrait modifié — NarrativeStudioShell

```dart
return Semantics(
  container: true,
  label: 'Narrative Studio Shell',
  child: LayoutBuilder(
    builder: (context, constraints) {
      final compactSidebar = constraints.maxWidth < 1100;
      return Row(
        key: const ValueKey('narrative-studio-shell'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NarrativeStudioSidebar(
            workspaceMode: workspaceMode,
            onSelectOverview: onSelectOverview,
            onSelectGlobal: onSelectGlobal,
            onSelectStep: onSelectStep,
            onSelectCutscene: onSelectCutscene,
            onSelectDialogue: onSelectDialogue,
            compact: compactSidebar,
          ),
          SizedBox(width: compactSidebar ? 8 : 10),
          Expanded(
            key: const ValueKey('narrative-studio-main-content'),
            child: child,
          ),
        ],
      );
    },
  ),
);
```

### Extrait modifié — test sidebar

```dart
final sidebar = find.byKey(const ValueKey('narrative-studio-sidebar'));
final transientNavigation =
    find.byKey(const ValueKey('narrative-studio-transitional-navigation'));
final mainContent = find.byKey(const ValueKey('narrative-studio-main-content'));

expect(shell, findsOneWidget);
expect(sidebar, findsOneWidget);
expect(transientNavigation, findsNothing);
expect(mainContent, findsOneWidget);

expect(
  find.descendant(of: shell, matching: find.byType(ProjectExplorerPanel)),
  findsNothing,
);
```

### Boundary guard

```text
git diff -- packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle | wc -l
0
```

## 17. Auto-review critique

Points solides :

```text
- la distinction des deux sidebars devient visible ;
- ProjectExplorerPanel reste intouché ;
- les destinations disabled sont testées comme non navigantes ;
- le strip transitoire est retiré de la surface principale ;
- le Visual Gate a détecté puis permis de corriger un overflow réel.
```

Limites :

```text
- la cohabitation de deux sidebars réduit l'espace du dashboard ;
- la sidebar interne est compacte et pas encore la version finale ;
- Maps a été retiré à la demande de Karim, ce qui simplifie la V0 et évite une destination inutile.
```

## 18. Regard critique sur le prompt

Le prompt était utile parce qu'il verrouillait l'erreur possible :

```text
ne pas transformer ProjectExplorerPanel en sidebar Narrative Studio.
```

Le point le plus délicat est `Scènes` :

```text
Le mapping vers `step` est acceptable en V0 uniquement grâce au sous-label “Étapes narratives”.
Le prochain lot devra continuer à documenter cette transition de vocabulaire.
```
