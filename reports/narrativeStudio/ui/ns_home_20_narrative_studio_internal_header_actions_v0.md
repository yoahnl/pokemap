# NS-HOME-20 — Narrative Studio Internal Header / Actions V0

## 1. Résumé exécutif

NS-HOME-20 crée le premier `NarrativeStudioHeader` interne dans `NarrativeStudioShell`.

Le header vit dans la zone Narrative Studio, au-dessus du contenu principal, à côté de la `NarrativeStudioSidebar` interne. Il ne remplace pas la top toolbar globale PokeMap et ne touche pas au `ProjectExplorerPanel`.

Actions V0 :

- `Aperçu` est une vraie action et revient vers `EditorWorkspaceMode.narrativeOverview`.
- `Nouvelle storyline`, `Valider`, `Recherche`, `Notifications`, `Paramètres` sont visibles mais disabled / non fonctionnelles.
- Aucun badge notification n'est rendu.
- Aucune création de storyline, validation, recherche, notification ou préférence n'est branchée.

## 2. Rappel du scope NS-HOME-20

Objectif :

- créer / harmoniser le header interne du Narrative Studio ;
- afficher le mode courant ;
- préparer les futures actions narratives sans les activer ;
- préserver le Project Explorer global ;
- préserver la sidebar interne ;
- produire un Visual Gate.

Non-objectifs respectés :

- pas de modification du read model ;
- pas de modèle métier modifié ;
- pas de runtime/gameplay/battle/map_core touché ;
- pas de provider global ;
- pas de repository ;
- pas de vraie storyline ;
- pas de validation narrative globale ;
- pas de recherche globale ;
- pas de notification fake ;
- pas de badge notification ;
- pas de réintroduction de `Maps`.

## 3. Fichiers créés / modifiés

Fichiers créés :

- `packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart`
- `packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart`
- `reports/narrativeStudio/ui/screenshots/ns_home_20_internal_header_desktop.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_20_internal_header_focus.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_20_internal_header_disabled_actions.png`
- `reports/narrativeStudio/ui/ns_home_20_narrative_studio_internal_header_actions_v0.md`

Fichiers modifiés :

- `packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart`

Fichiers volontairement non modifiés :

- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart`
- `packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart`

## 4. Architecture du header interne

Architecture créée :

```text
NarrativeStudioShell
├─ NarrativeStudioSidebar
└─ Main area
   ├─ NarrativeStudioHeader
   └─ content
```

`NarrativeStudioHeader` reçoit :

- `workspaceMode`;
- `onSelectOverview`.

Il ne reçoit pas :

- `ProjectManifest` brut ;
- read model Overview ;
- `SaveData` ;
- `GameState` ;
- repository ;
- provider global.

Le header est volontairement local et stateless. Il calcule uniquement un label de mode depuis `EditorWorkspaceMode`.

## 5. Actions internes V0

Action réelle :

| Action | Statut | Comportement |
| --- | --- | --- |
| Aperçu | active / current | appelle `onSelectOverview` |

Actions préparées mais non actives :

| Action | Statut | Raison |
| --- | --- | --- |
| Nouvelle storyline | disabled | création de storyline à venir |
| Valider | disabled | validation narrative globale non branchée en V0 |
| Recherche | disabled | recherche narrative à venir |
| Notifications | disabled | aucune source fiable en V0 |
| Paramètres | disabled | paramètres narratifs à venir |

Le header ne crée aucune donnée. Il ne déclenche aucun flow métier.

## 6. Actions laissées disabled

Les actions disabled sont rendues comme des pills atténuées avec sémantique disabled.

Tests associés :

- tap sur `Nouvelle storyline` ne modifie pas le workspace ;
- tap sur `Valider` ne modifie pas le workspace ;
- tap sur `Recherche` ne modifie pas le workspace ;
- tap sur `Notifications` ne modifie pas le workspace ;
- tap sur `Paramètres` ne modifie pas le workspace ;
- aucun badge `narrative-studio-header-notifications-badge` n'existe.

## 7. Relation header interne / top toolbar globale

La top toolbar globale reste inchangée.

Rôle de la top toolbar :

- chrome global PokeMap ;
- actions globales déjà posées par NS-HOME-12 ;
- statut projet / workspace global.

Rôle du header interne :

- contexte interne Narrative Studio ;
- mode narratif courant ;
- actions narratives V0 locales au studio.

Le header interne ne remplace pas la top toolbar globale.

## 8. Relation header interne / NarrativeOverviewWorkspace

Décision retenue : option A.

Le header shell reste léger :

```text
Narrative Studio / <mode courant>
Dashboard auteur
actions V0
```

`NarrativeOverviewWorkspace` conserve son breadcrumb et son titre :

```text
PokeMap / Narrative Studio / Aperçu
Aperçu
Vue d’ensemble auteur : métriques et statuts honnêtes.
```

Pourquoi :

- le breadcrumb Overview reste utile quand la page est testée seule ;
- le header interne prépare les actions de shell ;
- aucun contexte n'est supprimé sans lot dédié ;
- le Visual Gate montre que les KPI restent visibles.

## 9. Ce qui reste volontairement hors scope

- Activer `Nouvelle storyline`.
- Activer `Valider`.
- Activer `Recherche`.
- Activer `Notifications`.
- Créer un badge notification.
- Créer un panneau `Paramètres`.
- Déplacer la sidebar interne.
- Modifier le Project Explorer global.
- Réduire automatiquement le Project Explorer.
- Supprimer le breadcrumb Overview.
- Refaire la top bar globale.
- Refaire la sidebar finale.

## 10. Tests ajoutés / modifiés

Test créé :

- `packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart`

Couverture :

- rendu du header ;
- label `Narrative Studio / Aperçu` ;
- label `Dashboard auteur` ;
- labels des modes `Storylines`, `Scènes`, `Cinématiques`, `Dialogues` ;
- action `Aperçu` réelle ;
- actions futures visibles mais inertes ;
- absence de badge notification.

Test modifié :

- `packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart`

Couverture ajoutée :

- `NarrativeStudioHeader` est descendant de `NarrativeStudioShell` ;
- `Aperçu` du header revient à `narrativeOverview` ;
- les actions disabled du header ne changent pas de workspace ;
- les screenshots NS-HOME-20 sont générables ;
- le Project Explorer reste distinct du shell interne.

## 11. Visual Gate

Screenshots produits :

- `reports/narrativeStudio/ui/screenshots/ns_home_20_internal_header_desktop.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_20_internal_header_focus.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_20_internal_header_disabled_actions.png`

Méthode :

- génération via widget test `narrative_overview_shell_navigation_test.dart` ;
- `matchesGoldenFile` ;
- Project Explorer réduit via `project-explorer-toggle` avant capture ;
- tailles :
  - desktop : `1600 x 1000` ;
  - focus : `1600 x 700` ;
  - disabled actions : `1600 x 700`.

Ce qui s'est amélioré depuis NS-HOME-19 :

- le shell interne a maintenant un header dédié ;
- les actions narratives V0 sont regroupées dans le studio ;
- `Aperçu` est la seule action réellement branchée ;
- les actions futures sont visibles mais atténuées ;
- le Project Explorer global réduit reste distinct.

Est-ce que le header interne est clairement dans `NarrativeStudioShell` ?

- Oui. Il est rendu dans la main area de `NarrativeStudioShell`, pas dans la top toolbar globale.

Est-ce que `ProjectExplorerPanel` reste global et distinct ?

- Oui. Il n'est pas modifié et n'est pas descendant de `NarrativeStudioShell`.

Est-ce que `NarrativeStudioSidebar` reste claire ?

- Oui. La sidebar interne reste visible à gauche du contenu Narrative Studio.

Est-ce que les actions V0 sont lisibles ?

- Oui. Les actions sont visibles dans une rangée compacte du header interne.

Est-ce que les actions disabled sont clairement non fonctionnelles ?

- Oui. Elles sont atténuées et testées comme inertes.

Est-ce que l'Overview reste stable ?

- Oui. Le breadcrumb, le titre, les KPI, la Structure narrative et les blocs Overview restent visibles.

Est-ce que les KPI ne sont pas repoussés trop bas ?

- Oui sur desktop : les KPI restent visibles sans scroll initial excessif. En focus `1600 x 700`, le début des KPI reste visible.

Ce qui ne correspond pas encore à l'image cible :

- la top toolbar globale n'est pas reconstruite ;
- les actions sont encore disabled ;
- l'explorer global reste sous forme de rail réduit ;
- le header interne n'est pas pixel-perfect ;
- aucune recherche/notification/validation réelle n'existe.

Hors scope volontaire :

- activation des actions futures ;
- finalisation du header cible ;
- suppression de toute redondance breadcrumb/header.

Correction après inspection visuelle :

- aucune correction layout bloquante n'a été nécessaire après inspection ;
- les screenshots montrent une densité acceptable et les KPI restent visibles.

## 12. Commandes exécutées

Test rouge initial :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_studio_header_test.dart
```

Tests ciblés :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart
cd packages/map_editor && flutter test test/ui/shell/project_explorer_handoff_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_studio_header_test.dart
cd packages/map_editor && flutter test test/top_toolbar_test.dart
cd packages/map_editor && flutter test test/editor_selectors_test.dart
cd packages/map_editor && flutter test test/status_bar_test.dart
```

Régression combinée :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/ui/shell/project_explorer_handoff_test.dart test/ui/canvas/narrative_studio_header_test.dart test/top_toolbar_test.dart test/editor_selectors_test.dart test/status_bar_test.dart
```

Screenshots :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_20_CAPTURE_INTERNAL_HEADER_DESKTOP=true
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_20_CAPTURE_INTERNAL_HEADER_FOCUS=true
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_20_CAPTURE_INTERNAL_HEADER_DISABLED_ACTIONS=true
```

Analyse :

```bash
cd packages/map_editor && flutter analyze
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_studio_header.dart lib/src/ui/canvas/narrative_studio_shell.dart test/ui/canvas/narrative_studio_header_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Git lecture :

```bash
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

## 13. Résultats des tests

Test rouge initial :

```text
Failed to load ".../narrative_studio_header_test.dart":
Error when reading 'lib/src/ui/canvas/narrative_studio_header.dart': No such file or directory
Method not found: 'NarrativeStudioHeader'.
00:00 +0 -1: Some tests failed.
```

Après implémentation :

```text
cd packages/map_editor && flutter test test/ui/canvas/narrative_studio_header_test.dart
00:00 +3: All tests passed!
```

```text
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart
00:02 +16: All tests passed!
```

```text
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart
00:02 +29: All tests passed!
```

```text
cd packages/map_editor && flutter test test/ui/shell/project_explorer_handoff_test.dart
00:01 +3: All tests passed!
```

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

Régression combinée finale :

```text
00:03 +76: All tests passed!
```

Screenshots :

```text
NS_HOME_20_CAPTURE_INTERNAL_HEADER_DESKTOP=true
00:02 +16: All tests passed!

NS_HOME_20_CAPTURE_INTERNAL_HEADER_FOCUS=true
00:02 +16: All tests passed!

NS_HOME_20_CAPTURE_INTERNAL_HEADER_DISABLED_ACTIONS=true
00:02 +16: All tests passed!
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
error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
```

Conclusion : l'analyse globale échoue sur dette préexistante hors NS-HOME-20, déjà observée sur NS-HOME-19.

Analyse ciblée finale :

```text
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_studio_header.dart lib/src/ui/canvas/narrative_studio_shell.dart test/ui/canvas/narrative_studio_header_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
Analyzing 4 items...
No issues found! (ran in 1.9s)
```

## 15. Limites

- Le header ajoute une couche de contexte sans supprimer encore le breadcrumb Overview.
- Les actions futures sont visibles mais non fonctionnelles.
- Le screenshot `disabled_actions` a le même cadrage que le focus : c'est volontaire pour montrer les pills disabled dans le header.
- Le header ne reçoit pas encore de `projectName`, car la top toolbar globale porte déjà le projet.
- Le rail Project Explorer global réduit reste visible.

## 16. Prochain lot recommandé

Prochain lot recommandé :

```text
NS-HOME-21 — Narrative Studio Visual Harmonization Against Target V0
```

Objectif proposé :

- harmoniser visuellement le header interne, la sidebar interne et le dashboard contre l'image cible ;
- réduire les redondances restantes sans supprimer le contexte ;
- garder les actions futures disabled ;
- ne pas activer validation, recherche, notifications ou création de storyline.

## 17. Evidence Pack

### Git branch

```text
main
```

### Git status initial

```text
git status --short --untracked-files=all
<sortie vide>
```

### Git status final

```text
 M packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
?? packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart
?? packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart
?? reports/narrativeStudio/ui/ns_home_20_narrative_studio_internal_header_actions_v0.md
?? reports/narrativeStudio/ui/screenshots/ns_home_20_internal_header_desktop.png
?? reports/narrativeStudio/ui/screenshots/ns_home_20_internal_header_disabled_actions.png
?? reports/narrativeStudio/ui/screenshots/ns_home_20_internal_header_focus.png
```

### Git diff --stat final

`git diff --stat` ne liste que les fichiers trackés :

```text
 .../lib/src/ui/canvas/narrative_studio_shell.dart  |  13 ++-
 .../narrative_overview_shell_navigation_test.dart  | 100 ++++++++++++++++++++-
 2 files changed, 110 insertions(+), 3 deletions(-)
```

### Git diff --name-only final

```text
packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Note : les fichiers non trackés ne sont pas listés par `git diff --name-only`.

### Git diff --check final

```text
git diff --check
<sortie vide>
```

### Liste complète des fichiers créés

- `packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart`
- `packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart`
- `reports/narrativeStudio/ui/ns_home_20_narrative_studio_internal_header_actions_v0.md`
- `reports/narrativeStudio/ui/screenshots/ns_home_20_internal_header_desktop.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_20_internal_header_focus.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_20_internal_header_disabled_actions.png`

### Liste complète des fichiers modifiés

- `packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart`

### Contenu des fichiers créés

Le contenu complet des fichiers créés est disponible dans :

- `packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart` (`280` lignes)
- `packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart` (`108` lignes)

Extraits complets des sections clés :

```dart
class NarrativeStudioHeader extends StatelessWidget {
  const NarrativeStudioHeader({
    super.key,
    required this.workspaceMode,
    required this.onSelectOverview,
  });

  final EditorWorkspaceMode workspaceMode;
  final VoidCallback onSelectOverview;

  @override
  Widget build(BuildContext context) {
    final currentLabel = _workspaceLabel(workspaceMode);
    return Container(
      key: const ValueKey('narrative-studio-header'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF102033).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EditorChrome.activeAccent(context).withValues(alpha: 0.24),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;
          final titleBlock = _HeaderTitle(currentLabel: currentLabel);
          final actions = _HeaderActions(
            workspaceMode: workspaceMode,
            onSelectOverview: onSelectOverview,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                const SizedBox(height: 8),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 12),
              Flexible(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: actions,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

```dart
children: [
  const _HeaderActionPill(
    key: ValueKey('narrative-studio-header-action-new-storyline'),
    icon: CupertinoIcons.add,
    label: 'Nouvelle storyline',
    disabledReason: 'Création de storyline à venir',
  ),
  _HeaderActionPill(
    key: const ValueKey('narrative-studio-header-action-overview'),
    icon: CupertinoIcons.eye,
    label: 'Aperçu',
    selected: workspaceMode == EditorWorkspaceMode.narrativeOverview,
    onTap: onSelectOverview,
  ),
  const _HeaderActionPill(
    key: ValueKey('narrative-studio-header-action-validate'),
    icon: CupertinoIcons.shield,
    label: 'Valider',
    disabledReason: 'Validation narrative globale non branchée en V0',
  ),
  const _HeaderActionPill(
    key: ValueKey('narrative-studio-header-action-search'),
    icon: CupertinoIcons.search,
    label: 'Recherche',
    disabledReason: 'Recherche narrative à venir',
  ),
  const _HeaderActionPill(
    key: ValueKey('narrative-studio-header-action-notifications'),
    icon: CupertinoIcons.bell,
    label: 'Notifications',
    disabledReason: 'Aucune source fiable en V0',
  ),
  const _HeaderActionPill(
    key: ValueKey('narrative-studio-header-action-settings'),
    icon: CupertinoIcons.gear,
    label: 'Paramètres',
    disabledReason: 'Paramètres narratifs à venir',
  ),
]
```

```dart
if (!enabled) {
  return Semantics(
    button: true,
    enabled: false,
    label: '${widget.label} — ${widget.disabledReason}',
    child: content,
  );
}
```

### Extraits des sections modifiées

`NarrativeStudioShell` :

```dart
Expanded(
  key: const ValueKey('narrative-studio-main-content'),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      NarrativeStudioHeader(
        workspaceMode: workspaceMode,
        onSelectOverview: onSelectOverview,
      ),
      const SizedBox(height: 8),
      Expanded(child: child),
    ],
  ),
),
```

`narrative_overview_shell_navigation_test.dart` :

```dart
expect(
  find.descendant(
    of: shell,
    matching: find.byKey(const ValueKey('narrative-studio-header')),
  ),
  findsOneWidget,
);
expect(find.text('Narrative Studio / Aperçu'), findsOneWidget);
expect(find.text('Dashboard auteur'), findsOneWidget);
```

```dart
await tester.tap(
  find.byKey(const ValueKey('narrative-studio-header-action-overview')),
);
await tester.pumpAndSettle();
expect(find.text('workspace:narrativeOverview'), findsOneWidget);
```

```dart
for (final key in <String>[
  'narrative-studio-header-action-new-storyline',
  'narrative-studio-header-action-validate',
  'narrative-studio-header-action-search',
  'narrative-studio-header-action-notifications',
  'narrative-studio-header-action-settings',
]) {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}
expect(find.text('workspace:narrativeOverview'), findsOneWidget);
```

### Screenshots produits

```text
reports/narrativeStudio/ui/screenshots/ns_home_20_internal_header_desktop.png:          PNG image data, 1600 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/ui/screenshots/ns_home_20_internal_header_focus.png:            PNG image data, 1600 x 700, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/ui/screenshots/ns_home_20_internal_header_disabled_actions.png: PNG image data, 1600 x 700, 8-bit/color RGBA, non-interlaced
```

```text
reports/narrativeStudio/ui/screenshots/ns_home_20_internal_header_desktop.png May 27 19:28:50 2026 213573
reports/narrativeStudio/ui/screenshots/ns_home_20_internal_header_focus.png May 27 19:29:05 2026 137378
reports/narrativeStudio/ui/screenshots/ns_home_20_internal_header_disabled_actions.png May 27 19:29:18 2026 137378
```

### Analyse visuelle de chaque screenshot

`ns_home_20_internal_header_desktop.png` :

- Project Explorer global réduit visible ;
- sidebar interne Narrative Studio visible ;
- header interne visible au-dessus de l'Overview ;
- actions V0 regroupées ;
- KPI et Structure narrative visibles.

`ns_home_20_internal_header_focus.png` :

- header interne et actions lisibles ;
- début du dashboard visible ;
- pas d'overflow évident.

`ns_home_20_internal_header_disabled_actions.png` :

- même cadrage focus, dédié à la lecture des pills disabled ;
- actions futures visuellement atténuées ;
- aucun badge notification.

### Confirmations de périmètre

- `ProjectExplorerPanel` non modifié.
- `NarrativeStudioSidebar` non déplacée.
- `Maps` non réintroduit.
- `Facts`, `Règles du monde`, `Validateur` restent disabled dans la sidebar.
- Aucun read model modifié.
- Aucun modèle métier modifié.
- Aucun fichier runtime/gameplay/battle/map_core modifié.

## 18. Auto-review critique

Points solides :

- le header est un widget isolé ;
- il vit dans `NarrativeStudioShell` ;
- les actions disabled sont testées ;
- `Aperçu` est la seule action réelle ;
- les screenshots prouvent l'état Project Explorer réduit + sidebar interne + header.

Points à surveiller :

- il reste une redondance volontaire entre header interne et breadcrumb Overview ;
- le header ne reçoit pas encore de projet actif ;
- le design reste V0, pas final.

## 19. Regard critique sur le prompt

Le prompt est bien cadré : il pousse vers une couche interne propre sans retomber dans la top toolbar globale.

La contrainte importante est l'honnêteté des actions. Elle évite de reproduire l'image cible en activant des boutons mensongers.

La seule tension est la densité : ajouter un header interne augmente la hauteur avant les KPI. Le Visual Gate montre que cela reste acceptable en V0, mais un lot d'harmonisation visuelle pourra réduire les redondances ensuite.
