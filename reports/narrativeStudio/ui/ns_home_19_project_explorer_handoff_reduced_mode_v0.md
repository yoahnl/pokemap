# NS-HOME-19 — Project Explorer Handoff / Reduced Mode V0

## 1. Résumé exécutif

NS-HOME-19 stabilise le mécanisme existant de réduction du `ProjectExplorerPanel` global pour mieux cohabiter avec la `NarrativeStudioSidebar` interne.

Le choix retenu est l'option B du prompt : le mécanisme existait déjà dans `EditorShellPage`, mais il n'était pas assez testable et son rendu réduit conservait une zone trop large lors de l'inspection visuelle. Le lot ajoute donc des clés stables, clarifie la sémantique de réduction/réouverture, corrige le sizing du panneau réduit, et produit un Visual Gate où le Project Explorer global est réduit pendant que la sidebar interne Narrative Studio reste visible.

Aucun second système de collapse n'a été créé. Aucun état n'est persisté. `ProjectExplorerPanel` reste global. `NarrativeStudioSidebar` reste interne. `Maps` n'est pas réintroduit dans la sidebar interne.

## 2. Rappel du scope NS-HOME-19

Objectif du lot :

- exploiter le mécanisme existant de réduction du Project Explorer global ;
- améliorer la cohabitation avec la sidebar interne Narrative Studio ;
- garder un moyen évident de rouvrir l'explorer global ;
- préserver les workspaces non narratifs ;
- produire des screenshots Visual Gate.

Non-objectifs respectés :

- pas de suppression du `ProjectExplorerPanel` ;
- pas de transformation du `ProjectExplorerPanel` en sidebar Narrative Studio ;
- pas de collapse persisté disque ;
- pas de nouveau provider global ;
- pas de modification du read model ;
- pas de destination fake ;
- pas de réintroduction de `Maps` dans la sidebar interne.

## 3. Audit du mécanisme de réduction existant

Recherche effectuée :

```bash
rg -n "collapse|collapsed|reduce|reduced|Réduire|explorer|ProjectExplorer|sidebar|rail|expanded|isExplorer|showExplorer" packages/map_editor/lib/src packages/map_editor/test
```

Constats :

- Le mécanisme de réduction est local à `EditorShellPage`.
- Il repose sur `_leftSidebarVisible`, un booléen de widget state local.
- Il n'est pas porté par `EditorState`.
- Il n'est pas persisté.
- Il est contrôlé par le bouton visible `Réduire l'explorateur` dans `ProjectExplorerPanel`.
- Le panneau réduit existait sous forme de bouton rond de réouverture.
- Avant ce lot, l'état n'avait pas de keys stables dédiées.
- Avant correction, l'utilisation combinée de `ResizablePane` et de l'ancien controller pouvait laisser une largeur visuelle trop importante même lorsque le contenu était réduit.

Réponses aux questions du prompt :

| Question | Réponse |
| --- | --- |
| Le mécanisme est-il local à `EditorShellPage` ? | Oui. |
| Est-il porté par `EditorState` ? | Non. |
| Est-il juste un état widget local ? | Oui. |
| Est-il contrôlé par le bouton “Réduire l’explorateur” ? | Oui. |
| Peut-on le piloter en test ? | Oui après ajout de keys stables. |
| Peut-on l'utiliser en `narrativeOverview` sans casser les autres modes ? | Oui, testé. |
| Peut-on produire un screenshot avec explorer réduit ? | Oui, trois screenshots produits. |
| Faut-il ajouter une key de test ? | Oui : `project-explorer-region`, `project-explorer-toggle`, `project-explorer-reduced`, `project-explorer-reopen-toggle`. |
| Faut-il seulement améliorer le test/Visual Gate ? | Non : l'inspection a montré un défaut de largeur réduite, corrigé dans `EditorShellPage`. |

## 4. Stratégie retenue

Stratégie V0 : stabiliser l'existant sans introduire de second système.

Ce qui a été fait :

- conservation de `_leftSidebarVisible` comme état local de `EditorShellPage` ;
- suppression du controller d'animation qui rendait le sizing réduit ambigu avec `ResizablePane` ;
- passage à une largeur directe : `268/344` quand ouvert, `52` quand réduit ;
- key différente pour le `ResizablePane` ouvert/réduit afin que la taille interne soit bien recalculée ;
- rendu conditionnel du contenu ouvert ou réduit pour éviter que le `ProjectExplorerPanel` complet reste layouté dans une largeur de 52 px ;
- ajout de keys et de labels sémantiques pour les tests et la compréhension ;
- aucune réduction automatique en entrant dans Narrative Studio.

Pourquoi ne pas forcer la réduction automatique :

- le prompt privilégie le mécanisme existant ;
- Karim a confirmé que l'explorer peut déjà être réduit manuellement ;
- forcer le collapse aurait introduit une préférence comportementale plus forte ;
- aucun état de préférence n'est demandé à ce stade ;
- les workspaces non narratifs doivent rester stables.

## 5. Fichiers créés / modifiés

Fichiers modifiés :

- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`

Fichiers créés :

- `packages/map_editor/test/ui/shell/project_explorer_handoff_test.dart`
- `reports/narrativeStudio/ui/screenshots/ns_home_19_project_explorer_handoff_reduced_desktop.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_19_project_explorer_handoff_reduced_focus.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_19_project_explorer_non_narrative_regression.png`
- `reports/narrativeStudio/ui/ns_home_19_project_explorer_handoff_reduced_mode_v0.md`

Note Git : les fichiers non trackés ne sont pas listés par `git diff --stat` ni `git diff --name-only`. Ils sont compensés par les listes et extraits de ce rapport.

## 6. Comportement narratif vérifié ou implémenté

En mode `EditorWorkspaceMode.narrativeOverview` :

- le Project Explorer global peut être réduit via le bouton existant ;
- le rail réduit reste visible ;
- un bouton de réouverture est disponible ;
- la `NarrativeStudioSidebar` interne reste visible ;
- le contenu Overview gagne de l'espace horizontal ;
- `ProjectExplorerPanel` n'est pas descendant de `NarrativeStudioShell`.

Les modes narratifs restent couverts par les tests existants de navigation shell :

- `narrativeOverview`
- `globalStory`
- `step`
- `cutscene`
- `dialogue`

## 7. Comportement non narratif préservé

En mode non narratif `map` :

- le Project Explorer global reste ouvert par défaut ;
- `World Explorer` et `World Maps` restent visibles ;
- la `NarrativeStudioSidebar` interne n'est pas rendue ;
- le comportement historique d'explorer global est préservé.

Le screenshot de régression non narratif montre explicitement cet état.

## 8. Distinction Project Explorer / NarrativeStudioSidebar

La séparation d'architecture reste intacte :

```text
PokeMap App Shell
├─ ProjectExplorerPanel global
└─ Workspace host
   └─ NarrativeStudioShell
      ├─ NarrativeStudioSidebar interne
      └─ contenu Narrative Studio
```

Garanties vérifiées :

- `ProjectExplorerPanel` reste rendu par `EditorShellPage`.
- `ProjectExplorerPanel` n'est pas descendant de `NarrativeStudioShell`.
- `NarrativeStudioSidebar` reste visible dans le shell interne.
- Le rail réduit appartient au shell global, pas au Narrative Studio.
- Le Project Explorer peut être récupéré par l'utilisateur.

## 9. Ce qui reste volontairement hors scope

- Réduction automatique du Project Explorer quand on entre dans Narrative Studio.
- Préférence persistée utilisateur.
- Stratégie responsive mobile complète.
- Refonte visuelle du Project Explorer.
- Refonte de la sidebar interne Narrative Studio.
- Activation de `Facts`, `Règles du monde`, `Validateur`.
- Réintroduction de `Maps` dans la sidebar interne.
- Validation narrative globale.
- Nouvelle storyline.
- Recherche globale.
- Notifications.

## 10. Tests ajoutés / modifiés

Test ajouté :

- `packages/map_editor/test/ui/shell/project_explorer_handoff_test.dart`

Ce test couvre :

- réduction/réouverture du Project Explorer global en mode `narrativeOverview` ;
- visibilité de `NarrativeStudioSidebar` en état réduit ;
- distinction `ProjectExplorerPanel` / `NarrativeStudioShell` ;
- absence de `Maps` dans la sidebar interne ;
- présence des entrées disabled `Facts`, `Règles du monde`, `Validateur` ;
- régression non narrative en mode `map` ;
- génération des screenshots NS-HOME-19 via `--dart-define`.

Tests existants relancés :

- `test/ui/canvas/narrative_overview_shell_navigation_test.dart`
- `test/ui/canvas/narrative_overview_workspace_test.dart`
- `test/top_toolbar_test.dart`
- `test/editor_selectors_test.dart`
- `test/status_bar_test.dart`
- `test/pokemon_catalogs_project_explorer_entry_test.dart`

## 11. Visual Gate

Screenshots produits :

- `reports/narrativeStudio/ui/screenshots/ns_home_19_project_explorer_handoff_reduced_desktop.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_19_project_explorer_handoff_reduced_focus.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_19_project_explorer_non_narrative_regression.png`

Méthode :

- test widget dédié avec `matchesGoldenFile` ;
- chargement de polices système pour stabiliser le rendu ;
- dimensions :
  - desktop : `1600 x 1000` ;
  - focus : `1600 x 700` ;
  - non narratif : `1600 x 1000` ;
- génération par `flutter test --update-goldens` avec `--dart-define`.

Ce qui s'est amélioré depuis NS-HOME-18 :

- le Project Explorer global n'occupe plus une large colonne lorsqu'il est réduit ;
- la sidebar interne Narrative Studio reste lisible ;
- l'Overview gagne de l'espace horizontal ;
- la distinction "rail global réduit" vs "sidebar interne Narrative Studio" est visible.

Est-ce que le Project Explorer global est moins envahissant ?

- Oui. En état réduit, il devient un rail étroit de 52 px avec affordance de réouverture.

Est-ce que `NarrativeStudioSidebar` reste visible ?

- Oui. Les screenshots réduits montrent la sidebar interne à gauche du dashboard, distincte du rail global.

Est-ce que les deux sidebars restent distinctes ?

- Oui. Le Project Explorer réduit est un rail global ; la sidebar interne garde ses entrées narratives.

Est-ce que l'utilisateur peut récupérer l'explorer global ?

- Oui. Le bouton `Rouvrir l’explorateur global` réouvre l'explorer.

Est-ce que les workspaces non narratifs restent stables ?

- Oui. Le screenshot non narratif montre `World Explorer` ouvert en mode `map`, sans sidebar Narrative Studio.

Ce qui ne correspond pas encore à l'image cible :

- le Project Explorer global existe encore visuellement sous forme de rail ;
- la top bar globale reste celle de PokeMap ;
- la sidebar interne n'est pas encore le design final pixel-perfect ;
- aucun collapse automatique/contextuel n'est appliqué.

Ce qui est volontairement hors scope de NS-HOME-19 :

- masquer complètement le Project Explorer ;
- reconstruire la top bar cible ;
- reconstruire la sidebar interne cible ;
- persister une préférence de collapse ;
- créer de nouvelles destinations ou actions.

Problèmes visuels inspectés et corrigés :

- première inspection : le Project Explorer semblait réduit côté contenu mais gardait une largeur vide trop importante ;
- correction : largeur directe de pane, key différente ouvert/réduit, rendu conditionnel du contenu ouvert/réduit ;
- seconde inspection : le rail réduit, la sidebar interne et le dashboard cohabitent correctement.

## 12. Commandes exécutées

Références et audit :

```bash
git branch --show-current
git status --short --untracked-files=all
rg -n "collapse|collapsed|reduce|reduced|Réduire|explorer|ProjectExplorer|sidebar|rail|expanded|isExplorer|showExplorer" packages/map_editor/lib/src packages/map_editor/test
sed -n '1,220p' <fichiers requis>
file reports/narrativeStudio/ui/screenshots/ns_home_19_project_explorer_handoff_reduced_desktop.png reports/narrativeStudio/ui/screenshots/ns_home_19_project_explorer_handoff_reduced_focus.png reports/narrativeStudio/ui/screenshots/ns_home_19_project_explorer_non_narrative_regression.png
stat -f '%N %Sm %z' reports/narrativeStudio/ui/screenshots/ns_home_19_project_explorer_handoff_reduced_desktop.png reports/narrativeStudio/ui/screenshots/ns_home_19_project_explorer_handoff_reduced_focus.png reports/narrativeStudio/ui/screenshots/ns_home_19_project_explorer_non_narrative_regression.png
```

Tests :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart
cd packages/map_editor && flutter test test/ui/shell/project_explorer_handoff_test.dart
cd packages/map_editor && flutter test test/top_toolbar_test.dart
cd packages/map_editor && flutter test test/editor_selectors_test.dart
cd packages/map_editor && flutter test test/status_bar_test.dart
cd packages/map_editor && flutter test test/pokemon_catalogs_project_explorer_entry_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/top_toolbar_test.dart test/editor_selectors_test.dart test/status_bar_test.dart test/pokemon_catalogs_project_explorer_entry_test.dart test/ui/shell/project_explorer_handoff_test.dart
```

Screenshots :

```bash
cd packages/map_editor && flutter test test/ui/shell/project_explorer_handoff_test.dart --update-goldens --dart-define=NS_HOME_19_CAPTURE_REDUCED_DESKTOP=true
cd packages/map_editor && flutter test test/ui/shell/project_explorer_handoff_test.dart --update-goldens --dart-define=NS_HOME_19_CAPTURE_REDUCED_FOCUS=true
cd packages/map_editor && flutter test test/ui/shell/project_explorer_handoff_test.dart --update-goldens --dart-define=NS_HOME_19_CAPTURE_NON_NARRATIVE=true
```

Analyse :

```bash
cd packages/map_editor && flutter analyze
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/editor_shell_page.dart lib/src/ui/panels/project_explorer_panel.dart test/ui/shell/project_explorer_handoff_test.dart
```

Git lecture :

```bash
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

## 13. Résultats des tests

Tests ciblés :

```text
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart
00:01 +15: All tests passed!
```

```text
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart
00:02 +29: All tests passed!
```

```text
cd packages/map_editor && flutter test test/ui/shell/project_explorer_handoff_test.dart
00:01 +3: All tests passed!
```

Tests shell connexes :

```text
cd packages/map_editor && flutter test test/top_toolbar_test.dart
00:00 +10: All tests passed!
```

```text
cd packages/map_editor && flutter test test/editor_selectors_test.dart
00:00 +9: All tests passed!
```

```text
cd packages/map_editor && flutter test test/status_bar_test.dart
00:00 +6: All tests passed!
```

```text
cd packages/map_editor && flutter test test/pokemon_catalogs_project_explorer_entry_test.dart
00:01 +2: All tests passed!
```

Régression combinée :

```text
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/top_toolbar_test.dart test/editor_selectors_test.dart test/status_bar_test.dart test/pokemon_catalogs_project_explorer_entry_test.dart test/ui/shell/project_explorer_handoff_test.dart
00:03 +74: All tests passed!
```

Génération des screenshots :

```text
cd packages/map_editor && flutter test test/ui/shell/project_explorer_handoff_test.dart --update-goldens --dart-define=NS_HOME_19_CAPTURE_REDUCED_DESKTOP=true
00:01 +3: All tests passed!
```

```text
cd packages/map_editor && flutter test test/ui/shell/project_explorer_handoff_test.dart --update-goldens --dart-define=NS_HOME_19_CAPTURE_REDUCED_FOCUS=true
00:01 +3: All tests passed!
```

```text
cd packages/map_editor && flutter test test/ui/shell/project_explorer_handoff_test.dart --update-goldens --dart-define=NS_HOME_19_CAPTURE_NON_NARRATIVE=true
00:01 +3: All tests passed!
```

## 14. Résultats analyze

Analyse globale :

```text
cd packages/map_editor && flutter analyze
Analyzing map_editor...

error • The named parameter 'dbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7 • undefined_named_parameter
error • The named parameter 'battleEngineAimedTarget' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:64:7 • undefined_named_parameter
error • The named parameter 'battleEngineMethod' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:72:7 • undefined_named_parameter
error • The named parameter 'effectChance' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:73:7 • undefined_named_parameter
error • The named parameter 'studioFlags' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:74:7 • undefined_named_parameter
error • The named parameter 'battleStageMods' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:75:7 • undefined_named_parameter
error • The named parameter 'moveStatuses' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:76:7 • undefined_named_parameter
error • The named parameter 'psdkStudioMoveId' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:80:9 • undefined_named_parameter
error • The named parameter 'psdkDbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:81:9 • undefined_named_parameter
error • The named parameter 'psdkBattleEngineMethod' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:82:9 • undefined_named_parameter
...
error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
347 issues found. (ran in 3.5s)
```

Conclusion : l'analyse globale échoue sur une dette existante hors périmètre NS-HOME-19, notamment `pokemon_sdk_move_catalog_converter.dart` et `sync_pokemon_sdk_moves_catalog_use_case.dart`.

Analyse ciblée :

```text
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/editor_shell_page.dart lib/src/ui/panels/project_explorer_panel.dart test/ui/shell/project_explorer_handoff_test.dart
Analyzing 3 items...
No issues found! (ran in 1.2s)
```

## 15. Limites

- Le Project Explorer n'est pas réduit automatiquement en entrant dans Narrative Studio.
- Le collapse reste un état local non persisté.
- Le rail réduit n'est pas encore une stratégie responsive complète.
- Le Visual Gate valide l'état réduit généré par test, pas une préférence utilisateur persistée.
- Le screenshot non narratif ne prouve pas tous les workspaces non narratifs, mais il couvre le comportement historique principal de `map`.

## 16. Prochain lot recommandé

Prochain lot recommandé :

```text
NS-HOME-20 — Narrative Studio Internal Header / Actions V0
```

Objectif proposé :

- harmoniser les actions et le header internes du `NarrativeStudioShell` maintenant que le Project Explorer global peut être réduit ;
- garder les affordances futures disabled ;
- ne pas créer de validation, recherche, notifications ou storyline ;
- vérifier la cohabitation rail global réduit + sidebar interne + header interne.

## 17. Evidence Pack

### Git branch

```text
git branch --show-current
main
```

### Git status initial

État initial du lot avant modifications :

```text
git status --short --untracked-files=all
<sortie vide>
```

### Git status final

```text
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
?? packages/map_editor/test/ui/shell/project_explorer_handoff_test.dart
?? reports/narrativeStudio/ui/ns_home_19_project_explorer_handoff_reduced_mode_v0.md
?? reports/narrativeStudio/ui/screenshots/ns_home_19_project_explorer_handoff_reduced_desktop.png
?? reports/narrativeStudio/ui/screenshots/ns_home_19_project_explorer_handoff_reduced_focus.png
?? reports/narrativeStudio/ui/screenshots/ns_home_19_project_explorer_non_narrative_regression.png
```

### Git diff --stat final

`git diff --stat` ne liste que les fichiers trackés modifiés :

```text
 .../map_editor/lib/src/ui/editor_shell_page.dart   | 458 +++++++++++++--------
 .../lib/src/ui/panels/project_explorer_panel.dart  |  93 +++--
 2 files changed, 333 insertions(+), 218 deletions(-)
```

### Git diff --name-only final

`git diff --name-only` ne liste que les fichiers trackés modifiés :

```text
packages/map_editor/lib/src/ui/editor_shell_page.dart
packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
```

### Git diff --check final

```text
git diff --check
<sortie vide>
```

### Fichiers créés

- `packages/map_editor/test/ui/shell/project_explorer_handoff_test.dart`
- `reports/narrativeStudio/ui/ns_home_19_project_explorer_handoff_reduced_mode_v0.md`
- `reports/narrativeStudio/ui/screenshots/ns_home_19_project_explorer_handoff_reduced_desktop.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_19_project_explorer_handoff_reduced_focus.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_19_project_explorer_non_narrative_regression.png`

### Fichiers modifiés

- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`

### Extraits complets des sections modifiées

`EditorShellPage` : état local et largeur directe.

```dart
/// When false, the left ResizablePane is collapsed to a narrow toggle strip.
bool _leftSidebarVisible = true;

final double expandedWidth = isNarrativeWorkspace ? 268.0 : 344.0;
final double currentSidebarWidth =
    _leftSidebarVisible ? expandedWidth : 52.0;
```

`EditorShellPage` : région Project Explorer avec keys et rendu ouvert/réduit.

```dart
ResizablePane.noScrollBar(
  key: ValueKey<String>(
    'left_sidebar_pane_${_leftSidebarVisible ? 'expanded' : 'reduced'}',
  ),
  resizableSide: ResizableSide.right,
  minSize: currentSidebarWidth,
  maxSize: currentSidebarWidth,
  startSize: currentSidebarWidth,
  decoration: BoxDecoration(
    color: context.pokeMapColors.backgroundShell,
  ),
  child: KeyedSubtree(
    key: const ValueKey<String>('project-explorer-region'),
    child: OverflowBox(
      minWidth: 52,
      maxWidth: isNarrativeWorkspace ? 460 : 520,
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: currentSidebarWidth,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedOpacity(
                key: const ValueKey<String>(
                  'project-explorer-expanded-state',
                ),
                duration: const Duration(milliseconds: 180),
                opacity: _leftSidebarVisible ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !_leftSidebarVisible,
                  child: _leftSidebarVisible
                      ? KeyedSubtree(
                          key: const ValueKey<String>(
                            'project-explorer-expanded',
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              isNarrativeWorkspace ? 12 : 16,
                              isNarrativeWorkspace ? 16 : 18,
                              isNarrativeWorkspace ? 10 : 12,
                              isNarrativeWorkspace ? 16 : 18,
                            ),
                            child: ProjectExplorerPanel(
                              onCollapse: () {
                                setState(() {
                                  _leftSidebarVisible = false;
                                });
                              },
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 14,
              child: AnimatedOpacity(
                key: const ValueKey<String>(
                  'project-explorer-reduced-state',
                ),
                duration: const Duration(milliseconds: 180),
                opacity: !_leftSidebarVisible ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: _leftSidebarVisible,
                  child: !_leftSidebarVisible
                      ? KeyedSubtree(
                          key: const ValueKey<String>(
                            'project-explorer-reduced',
                          ),
                          child: Column(
                            children: [
                              _CollapsedExpandButton(
                                key: const ValueKey<String>(
                                  'project-explorer-reopen-toggle',
                                ),
                                onTap: () {
                                  setState(() {
                                    _leftSidebarVisible = true;
                                  });
                                },
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
),
```

`EditorShellPage` : bouton de réouverture.

```dart
class _CollapsedExpandButton extends StatefulWidget {
  const _CollapsedExpandButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CollapsedExpandButton> createState() => _CollapsedExpandButtonState();
}

class _CollapsedExpandButtonState extends State<_CollapsedExpandButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Semantics(
      button: true,
      label: 'Rouvrir l’explorateur global',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _hovered
                    ? colors.brandPrimary.withValues(alpha: 0.8)
                    : colors.borderStrong.withValues(alpha: 0.6),
                width: 1.25,
              ),
              color: _hovered ? colors.surfaceHover : colors.surfaceBase,
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: colors.brandPrimary.withValues(alpha: 0.15),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: _hovered ? colors.brandPrimary : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
```

`ProjectExplorerPanel` : bouton de réduction.

```dart
Widget _buildCollapseButton(BuildContext context) {
  final colors = context.pokeMapColors;
  return Padding(
    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
    child: Semantics(
      button: true,
      label: 'Réduire l’explorateur global',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          key: const ValueKey('project-explorer-toggle'),
          onTap: widget.onCollapse,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colors.borderSubtle,
                width: 1.25,
              ),
              color: colors.surfaceBase,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.borderStrong.withValues(alpha: 0.5),
                      width: 1.15,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    CupertinoIcons.chevron_left,
                    size: 13,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Réduire l\'explorateur',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
```

### Contenu complet du fichier créé `project_explorer_handoff_test.dart`

```dart
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/editor_shell_page.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  testWidgets(
    'EditorShellPage reduces and restores the global Project Explorer in Narrative Studio',
    (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/ns_home_19_narrative_project',
          workspaceMode: EditorWorkspaceMode.narrativeOverview,
          project: _project(),
        ),
        surfaceSize: const Size(1600, 1000),
      );

      expect(find.byKey(const ValueKey('project-explorer-region')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('project-explorer-toggle')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('narrative-studio-sidebar')),
          findsOneWidget);
      expect(find.byType(ProjectExplorerPanel), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('narrative-studio-shell')),
          matching: find.byType(ProjectExplorerPanel),
        ),
        findsNothing,
      );
      expect(_opacity(tester, 'project-explorer-expanded-state'), 1);
      expect(_opacity(tester, 'project-explorer-reduced-state'), 0);

      await tester.tap(find.byKey(const ValueKey('project-explorer-toggle')));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('project-explorer-reduced')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('narrative-studio-sidebar')),
          findsOneWidget);
      expect(find.text('Facts'), findsWidgets);
      expect(find.text('Règles du monde'), findsWidgets);
      expect(find.text('Validateur'), findsWidgets);
      expect(find.text('Maps'), findsNothing);
      expect(_opacity(tester, 'project-explorer-expanded-state'), 0);
      expect(_opacity(tester, 'project-explorer-reduced-state'), 1);

      await tester
          .tap(find.byKey(const ValueKey('project-explorer-reopen-toggle')));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(_opacity(tester, 'project-explorer-expanded-state'), 1);
      expect(_opacity(tester, 'project-explorer-reduced-state'), 0);
      expect(find.text('World Maps'), findsOneWidget);
    },
  );

  testWidgets(
    'EditorShellPage keeps non narrative Project Explorer behavior expanded by default',
    (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/ns_home_19_map_project',
          workspaceMode: EditorWorkspaceMode.map,
          project: _project(),
          activeMap: _map(),
        ),
        surfaceSize: const Size(1600, 1000),
      );

      expect(find.byKey(const ValueKey('project-explorer-region')),
          findsOneWidget);
      expect(find.byType(ProjectExplorerPanel), findsOneWidget);
      expect(
          find.byKey(const ValueKey('narrative-studio-sidebar')), findsNothing);
      expect(find.text('World Explorer'), findsOneWidget);
      expect(find.text('World Maps'), findsOneWidget);
      expect(_opacity(tester, 'project-explorer-expanded-state'), 1);
      expect(_opacity(tester, 'project-explorer-reduced-state'), 0);
    },
  );

  testWidgets(
    'EditorShellPage captures NS-HOME-19 Project Explorer handoff screenshots when requested',
    (tester) async {
      const captureReducedDesktop =
          bool.fromEnvironment('NS_HOME_19_CAPTURE_REDUCED_DESKTOP');
      const captureReducedFocus =
          bool.fromEnvironment('NS_HOME_19_CAPTURE_REDUCED_FOCUS');
      const captureNonNarrative =
          bool.fromEnvironment('NS_HOME_19_CAPTURE_NON_NARRATIVE');
      if (!captureReducedDesktop &&
          !captureReducedFocus &&
          !captureNonNarrative) {
        return;
      }

      await _loadShellScreenshotFonts();
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: captureNonNarrative
              ? '/tmp/ns_home_19_map_project'
              : '/tmp/ns_home_19_narrative_project',
          workspaceMode: captureNonNarrative
              ? EditorWorkspaceMode.map
              : EditorWorkspaceMode.narrativeOverview,
          project: _project(),
          activeMap: captureNonNarrative ? _map() : null,
        ),
        surfaceSize: captureReducedFocus
            ? const Size(1600, 700)
            : const Size(1600, 1000),
      );

      if (!captureNonNarrative) {
        await tester.tap(find.byKey(const ValueKey('project-explorer-toggle')));
        await tester.pump(const Duration(milliseconds: 350));
      }

      final screenshotFile = File(
        '../../reports/narrativeStudio/ui/screenshots/'
        '${captureNonNarrative ? 'ns_home_19_project_explorer_non_narrative_regression.png' : captureReducedFocus ? 'ns_home_19_project_explorer_handoff_reduced_focus.png' : 'ns_home_19_project_explorer_handoff_reduced_desktop.png'}',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byType(EditorShellPage),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
      if (!captureNonNarrative) {
        await tester
            .tap(find.byKey(const ValueKey('project-explorer-reopen-toggle')));
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
      }
    },
  );
}

double _opacity(WidgetTester tester, String key) {
  return tester.widget<AnimatedOpacity>(find.byKey(ValueKey(key))).opacity;
}

Future<void> _loadShellScreenshotFonts() async {
  final fontBytes =
      File('/System/Library/Fonts/Supplemental/Arial.ttf').readAsBytesSync();
  for (final family in <String>[
    'Roboto',
    'Arial',
    '.SF Pro Text',
    'SF Pro Text',
  ]) {
    final loader = FontLoader(family)
      ..addFont(Future<ByteData>.value(ByteData.sublistView(fontBytes)));
    await loader.load();
  }
}

ProjectManifest _project() {
  return const ProjectManifest(
    surfaceCatalog: ProjectSurfaceCatalog.empty(),
    name: 'test_project',
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'test_map',
        name: 'Test Map',
        relativePath: 'maps/test_map.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
  );
}

MapData _map() {
  return const MapData(
    id: 'test_map',
    name: 'Test Map',
    size: GridSize(width: 20, height: 15),
    layers: <MapLayer>[],
  );
}
```

### Screenshots produits

```text
reports/narrativeStudio/ui/screenshots/ns_home_19_project_explorer_handoff_reduced_desktop.png:  PNG image data, 1600 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/ui/screenshots/ns_home_19_project_explorer_handoff_reduced_focus.png:    PNG image data, 1600 x 700, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/ui/screenshots/ns_home_19_project_explorer_non_narrative_regression.png: PNG image data, 1600 x 1000, 8-bit/color RGBA, non-interlaced
```

```text
reports/narrativeStudio/ui/screenshots/ns_home_19_project_explorer_handoff_reduced_desktop.png May 27 19:04:50 2026 203620
reports/narrativeStudio/ui/screenshots/ns_home_19_project_explorer_handoff_reduced_focus.png May 27 19:04:54 2026 136330
reports/narrativeStudio/ui/screenshots/ns_home_19_project_explorer_non_narrative_regression.png May 27 19:04:58 2026 145248
```

### Analyse visuelle de chaque screenshot

`ns_home_19_project_explorer_handoff_reduced_desktop.png` :

- le rail global réduit est visible à gauche ;
- la sidebar interne Narrative Studio est visible et distincte ;
- l'Overview garde son header, ses KPI et son panneau Structure narrative ;
- pas d'overflow évident ;
- le dashboard respire mieux qu'en double-sidebar large.

`ns_home_19_project_explorer_handoff_reduced_focus.png` :

- la distinction rail global / sidebar interne est lisible ;
- les KPI restent visibles ;
- le haut de page reste dense sans perte de contexte ;
- pas de double navigation horizontale.

`ns_home_19_project_explorer_non_narrative_regression.png` :

- le workspace `map` garde `World Explorer` ouvert ;
- le bouton `Réduire l'explorateur` reste disponible ;
- aucune sidebar Narrative Studio n'est affichée ;
- le comportement global non narratif est préservé.

### Confirmations de périmètre

- Aucun fichier `map_core` modifié.
- Aucun fichier `map_runtime` modifié.
- Aucun fichier `map_gameplay` modifié.
- Aucun fichier `map_battle` modifié.
- Aucun read model narratif modifié.
- Aucun provider global créé.
- Aucun repository créé.
- Aucun accès disque métier ajouté.
- Aucune validation narrative activée.
- Aucun badge notification fake créé.
- `Maps` n'est pas réintroduit dans la sidebar interne.

## 18. Auto-review critique

Points solides :

- le lot exploite bien le mécanisme existant ;
- la réduction est testable ;
- la récupération de l'explorer global est testée ;
- la séparation des deux sidebars est testée ;
- la régression non narrative est couverte ;
- le Visual Gate a déclenché une correction réelle de largeur.

Points à surveiller :

- le passage à une largeur instantanée simplifie l'ancien effet animé ;
- si une animation de largeur redevient souhaitée plus tard, il faudra la refaire en accord avec `ResizablePane` plutôt que via un controller qui laisse l'état interne diverger ;
- les screenshots sont générés via golden test ciblé, pas via un test d'intégration desktop complet.

## 19. Regard critique sur le prompt

Le prompt est utilement strict : il évite le piège de supprimer le Project Explorer ou de le confondre avec la sidebar Narrative Studio.

Le point le plus important était la phrase de Karim indiquant que le Project Explorer pouvait déjà être réduit. Elle oriente correctement vers un lot de stabilisation plutôt que vers un nouveau système.

La seule tension du prompt est qu'il demande un état réduit visible en Visual Gate sans imposer de réduction automatique. La solution retenue est donc prudente : l'état réduit est produit par interaction testée, mais le produit ne force pas encore le comportement.
