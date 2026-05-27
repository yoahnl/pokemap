# NS-HOME-15 — Narrative Studio Internal Shell / Sidebar Architecture Design Gate

## 1. Résumé exécutif

NS-HOME-15 corrige la trajectoire d’architecture avant les prochains lots UI.

Décision centrale :

```text
PokeMap Project Explorer
!=
Narrative Studio Sidebar interne
```

Le `ProjectExplorerPanel` doit rester une sidebar globale PokeMap. Il peut contenir une entrée globale vers `Narrative Studio`, et les ajustements NS-HOME-11 restent utiles comme handoff temporaire. En revanche, il ne doit pas devenir la sidebar finale du Narrative Studio.

La bonne trajectoire est de créer un shell interne dans le workspace narratif :

```text
PokeMap App Shell
├─ Top toolbar globale PokeMap
├─ Sidebar globale PokeMap / Project Explorer
├─ Status bar globale
└─ Workspace host
   └─ Narrative Studio Shell
      ├─ header interne Narrative Studio
      ├─ sidebar interne Narrative Studio
      ├─ contenu principal
      └─ inspector / panneau droit éventuel
```

Prochain lot recommandé :

```text
NS-HOME-16 — NarrativeStudioShell V0
```

## 2. Sources lues

Sources repo / règles :

```text
AGENTS.md
agent_rules.md
skills/README.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_1.md
```

Rapports lus :

```text
reports/narrativeStudio/ui/ns_home_00_overview_roadmap_proposal.md
reports/narrativeStudio/ui/ns_home_01_overview_data_contract.md
reports/narrativeStudio/ui/ns_home_02_narrative_overview_read_model.md
reports/narrativeStudio/ui/ns_home_03_narrative_overview_shell_placement.md
reports/narrativeStudio/ui/ns_home_04_narrative_overview_kpi_cards.md
reports/narrativeStudio/ui/ns_home_05_narrative_overview_main_story_card.md
reports/narrativeStudio/ui/ns_home_06_narrative_overview_module_cards_grid.md
reports/narrativeStudio/ui/ns_home_07_narrative_overview_structure_inspector.md
reports/narrativeStudio/ui/ns_home_08_narrative_overview_empty_states_footer.md
reports/narrativeStudio/ui/ns_home_09_narrative_overview_responsive_polish.md
reports/narrativeStudio/ui/ns_home_10_narrative_studio_shell_chrome_alignment.md
reports/narrativeStudio/ui/ns_home_11_narrative_studio_sidebar_navigation_alignment.md
reports/narrativeStudio/ui/ns_home_12_narrative_studio_top_bar_action_affordances.md
reports/narrativeStudio/ui/ns_home_13_narrative_studio_breadcrumb_shell_header.md
reports/narrativeStudio/ui/ns_home_14_narrative_studio_shell_header_density.md
```

Fichiers shell / state lus :

```text
packages/map_editor/lib/src/ui/editor_shell_page.dart
packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/lib/src/ui/shared/top_toolbar.dart
packages/map_editor/lib/src/ui/shared/status_bar.dart
packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
packages/map_editor/lib/src/features/editor/state/editor_state.dart
packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart
packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart
```

Screenshots inspectés :

```text
reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_desktop.png
reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_focus.png
reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_medium.png
/Users/karim/Desktop/assets/pokeMap/définitive/1 - page d'accueil.png
```

Tous les fichiers demandés existent dans le repo.

## 3. Audit de l’architecture actuelle

### Où commence le shell global PokeMap

Le shell global commence dans `EditorShellPage`.

Responsabilités observées :

- compose la top toolbar globale ;
- compose le Project Explorer global ;
- compose le canvas host ;
- compose la status bar globale ;
- porte les comportements globaux comme right panel / project shell / workspace container.

Le shell global ne devrait pas connaître la navigation interne détaillée du Narrative Studio. Il doit seulement savoir quel workspace central est actif.

### Où commence aujourd’hui le workspace Narrative Studio

Le workspace narratif commence aujourd’hui au niveau de `EditorCanvasHost`, qui route ces modes vers `NarrativeWorkspaceCanvas` :

```text
narrativeOverview
globalStory
step
cutscene
dialogue
```

`NarrativeWorkspaceCanvas` est donc déjà le bon point d’entrée technique pour un shell interne narratif.

Aujourd’hui, il contient encore directement :

- le mode strip narratif ;
- la construction du read model overview ;
- le switch vers `NarrativeOverviewWorkspace`, `GlobalStoryStudioWorkspace`, `StepStudioWorkspace`, `CutsceneStudioWorkspace`, `DialogueStudioWorkspace`.

Cela marche pour V0, mais c’est aussi le signe que le futur `NarrativeStudioShell` devrait se placer ici.

### Où la future sidebar interne doit vivre

La future sidebar interne doit vivre à l’intérieur du workspace narratif, pas dans `ProjectExplorerPanel`.

Point recommandé :

```text
NarrativeWorkspaceCanvas
└─ NarrativeStudioShell
   ├─ NarrativeStudioSidebar
   ├─ NarrativeStudioMainArea
   └─ NarrativeStudioInspectorSlot
```

Le `NarrativeStudioShell` reçoit le mode narratif courant et les callbacks existants de navigation. Il rend la sidebar interne et délègue le contenu à la surface déjà existante.

### Changements NS-HOME-11 temporaires

NS-HOME-11 a rendu `Narrative Studio` plus visible dans `ProjectExplorerPanel` quand un workspace narratif est actif :

- header `Narrative Studio` ;
- carte narrative remontée ;
- accès aux espaces narratifs existants ;
- état sélectionné plus clair.

Ces changements sont utiles comme entrée globale et comme handoff, mais ils sont temporaires pour la navigation interne. Ils ne doivent pas être interprétés comme la sidebar finale.

### Changements NS-HOME-11 qui peuvent rester utiles

Peuvent rester :

- l’entrée globale `Narrative Studio` dans le Project Explorer ;
- l’état sélectionné quand un mode narratif est actif ;
- le résumé global : aperçu, histoire globale, étapes, cinématiques, dialogues ;
- le fait que la carte soit plus visible quand l’utilisateur est déjà en mode narratif.

À terme, cette carte devrait être un accès au studio, pas la navigation détaillée du studio.

### Changements à ne pas interpréter comme sidebar finale

Ne pas considérer comme final :

- la sous-navigation narrative dans le Project Explorer ;
- le reorder visuel du Project Explorer en mode narratif ;
- le mode strip comme destination finale de la navigation ;
- les libellés techniques `Global Story`, `Step`, `Cutscene` comme vocabulaire final.

### Responsabilités aujourd’hui mélangées

Mélanges observés :

- `ProjectExplorerPanel` commence à exposer une navigation narrative détaillée alors qu’il devrait rester global ;
- `NarrativeWorkspaceCanvas` contient à la fois routing, strip, shell visuel minimal et contenu ;
- `TopToolbar` expose des affordances narratives V0, mais ce sont des actions globales shell, pas un header interne complet ;
- `EditorWorkspaceMode` mélange modes globaux PokeMap et modes internes narratifs dans le même enum.

Ce mélange reste acceptable en V0, mais il devient dangereux si les prochains lots ajoutent la sidebar cible au mauvais endroit.

### Risques si ProjectExplorerPanel devient la sidebar Narrative Studio

Risques :

- confusion produit : l’explorer global deviendrait dépendant d’un studio particulier ;
- régression des autres workspaces : Map, Tileset, Catalogues, Trainer, Path, Environment ;
- impossibilité de fermer/réduire proprement l’explorer global sans perdre la navigation narrative ;
- difficulté responsive : la sidebar interne doit se comporter avec le contenu narratif, pas avec toute l’app ;
- dette de state : préférences globales et navigation interne seraient mélangées ;
- faux alignement visuel : on croirait approcher l’image cible tout en cassant la séparation shell/workspace.

## 4. Deux sidebars, deux responsabilités

| Élément | Responsabilité | Appartient à | Peut être fermé/réduit ? | Doit contenir quoi ? | Ne doit pas contenir quoi ? |
| --- | --- | --- | --- | --- | --- |
| PokeMap Project Explorer | Explorer le projet global PokeMap et ouvrir les grands espaces de travail. | Shell global PokeMap, `EditorShellPage` / `ProjectExplorerPanel`. | Oui. Il peut être ouvert, réduit ou fermé comme chrome global. | World Explorer, maps, tilesets, assets, catalogues, trainer studio, environment studio, entrée globale vers Narrative Studio. | La navigation finale détaillée du Narrative Studio, les destinations internes fake, le panneau final `Facts / World Rules / Validateur`. |
| Narrative Studio Sidebar | Naviguer à l’intérieur du Narrative Studio. | Workspace narratif interne, futur `NarrativeStudioShell`. | Oui, mais comme comportement interne au studio ou responsive du studio, pas comme préférence globale PokeMap par défaut. | Aperçu, Storylines, Maps, Scènes, Cinématiques, Dialogues, Facts, World Rules, Validateur, avec états branché / disabled honnêtes. | World Explorer global, Tile Library globale, catalogues globaux, actions runtime, fausses données, destinations non branchées actives. |

Règles explicites :

```text
Le Project Explorer ne doit pas être supprimé.
Le Project Explorer ne doit pas devenir la navigation finale du Narrative Studio.
La sidebar Narrative Studio doit être créée à l’intérieur du workspace Narrative Studio.
```

## 5. Architecture cible recommandée

Architecture V0 recommandée :

```text
EditorShellPage
├─ TopToolbar
├─ ProjectExplorerPanel
├─ EditorCanvasHost
│  └─ NarrativeWorkspaceCanvas
│     └─ NarrativeStudioShell
│        ├─ NarrativeStudioHeader
│        ├─ NarrativeStudioSidebar
│        ├─ NarrativeStudioMainArea
│        │  ├─ NarrativeOverviewWorkspace
│        │  ├─ GlobalStoryStudioWorkspace
│        │  ├─ StepStudioWorkspace
│        │  ├─ CutsceneStudioWorkspace
│        │  └─ DialogueStudioWorkspace
│        └─ NarrativeStudioInspectorSlot
└─ StatusBar
```

### Widgets recommandés

`NarrativeStudioShell`

- fichier recommandé : `packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart` ;
- responsabilité : layout interne du studio narratif ;
- reçoit : `workspaceMode`, `project`, `projection`, callbacks de navigation, contenu principal ;
- interdit : lire le disque, parser Yarn, créer des données métier, lancer validation.

`NarrativeStudioSidebar`

- fichier recommandé : `packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart` ;
- responsabilité : liste de navigation interne et états disabled ;
- reçoit : mode courant, disponibilité des destinations, callbacks ;
- interdit : devenir un provider, lire `SaveData`, afficher des compteurs non issus du read model/projection.

`NarrativeStudioMainArea`

- fichier recommandé : peut rester privé dans `narrative_studio_shell.dart` au début ;
- responsabilité : héberger le workspace courant ;
- reçoit : un `Widget child` ou un switch déjà préparé par `NarrativeWorkspaceCanvas`.

`NarrativeStudioInspectorSlot`

- fichier recommandé : privé V0 ;
- responsabilité : réserver le futur emplacement inspector ;
- V0 : peut être absent ou pass-through si `NarrativeOverviewWorkspace` garde son panneau interne.

### Données reçues

Sources autorisées :

- `EditorWorkspaceMode` pour le workspace courant ;
- `EditorNotifier` / `EditorWorkspaceController` pour les transitions existantes ;
- `NarrativeWorkspaceState` pour la sélection narrative ;
- `NarrativeWorkspaceProjection` pour les entités narratives disponibles ;
- `NarrativeOverviewReadModel` uniquement pour la page `Aperçu`.

### Données interdites

Interdit :

- `SaveData` ;
- `GameState` ;
- runtime/player progression ;
- lecture disque ;
- parsing Yarn opportuniste ;
- faux compteurs ;
- tags/facts/world rules actifs sans modèle.

### Points d’intégration avec EditorWorkspaceMode

À court terme, conserver les modes existants :

```text
narrativeOverview
globalStory
step
cutscene
dialogue
```

Le futur `NarrativeStudioSidebar` peut mapper ses entrées vers ces modes sans créer de nouvel enum immédiatement.

À moyen terme, envisager une séparation :

```text
EditorWorkspaceMode.narrativeStudio
NarrativeStudioSection.overview/storylines/scenes/cutscenes/dialogues/...
```

Mais ce changement est plus risqué et doit être un lot dédié, pas une conséquence cachée de la sidebar.

### Points d’intégration avec NarrativeWorkspaceState

`NarrativeWorkspaceState` est déjà la bonne maison pour les sélections internes :

- selected global story ;
- selected step ;
- selected cutscene ;
- selected outcome.

Il peut accueillir plus tard une section interne narrative si cela évite de gonfler `EditorState`, mais seulement si un besoin réel apparaît. Pour NS-HOME-16/17, `EditorWorkspaceMode` suffit probablement.

### Ce qui reste dans ProjectExplorerPanel

À conserver :

- entrée globale `Narrative Studio` ;
- état sélectionné quand un mode narratif est actif ;
- accès global au studio ;
- capacité à rester ouvert/réduit/fermé indépendamment.

À éviter :

- liste finale `Aperçu / Storylines / Maps / Scènes / ...` comme navigation principale ;
- destinations disabled internes ;
- compteur `Facts`, `World Rules`, validation.

### Ce qui migre vers NarrativeStudioSidebar / NarrativeStudioShell

À migrer progressivement :

- mode strip narratif ;
- libellés orientés utilisateur final ;
- états active/disabled des sections internes ;
- navigation `Aperçu`, `Storylines`, `Scènes`, `Cinématiques`, `Dialogues` ;
- mentions `Facts`, `World Rules`, `Validateur` en disabled honnête si décidé.

## 6. Comportement d’entrée dans Narrative Studio

### Recommandation V0

Ne pas masquer automatiquement le Project Explorer au premier lot.

Stratégie recommandée :

1. NS-HOME-16 crée `NarrativeStudioShell` sans changer le comportement global.
2. NS-HOME-17 ajoute la sidebar interne.
3. NS-HOME-18 traite explicitement le handoff/collapse du Project Explorer.

### Project Explorer global

Options évaluées :

- réduction automatique : visuellement proche de la cible, mais risque de surprise et nécessite état persistant clair ;
- rester visible : plus sûr pour V0, mais deux sidebars peuvent sembler lourdes ;
- masquage en Narrative Studio uniquement : trop agressif sans préférence utilisateur.

Choix recommandé :

```text
Desktop large : Project Explorer visible ou réduit selon préférence globale existante, sidebar interne visible.
Medium : Project Explorer réduit par défaut si un mécanisme existant est sûr, sidebar interne compacte.
Small : Project Explorer masqué derrière chrome global, sidebar interne en rail ou menu.
```

### Où stocker l’état

Pour V0 :

- si un état d’explorer réduit existe déjà dans le shell, le réutiliser ;
- sinon, ne pas ajouter de provider global dans NS-HOME-16/17 ;
- traiter la préférence dans NS-HOME-18.

Si un état nouveau devient nécessaire :

- préférence UI/session dans `EditorState` ou slice UI existante ;
- pas dans `NarrativeWorkspaceState`, car c’est un état du shell global ;
- pas dans le read model overview.

### Comment revenir à l’explorer global

Le bouton existant `Réduire l’explorateur` peut être réutilisé si son comportement est déjà réel et global.

À prévoir :

- tooltip clair ;
- état visible quand l’explorer est réduit ;
- pas de masquage irréversible ;
- pas de comportement automatique sans sortie utilisateur.

## 7. Navigation interne Narrative Studio V0

| Entrée cible | Statut V0 recommandé | Mapping possible | Décision prudente |
| --- | --- | --- | --- |
| Aperçu | Branchée maintenant | `EditorWorkspaceMode.narrativeOverview` | Active. C’est la page courante fiable. |
| Storylines | Branchable vers workspace existant | `EditorWorkspaceMode.globalStory` | Afficher comme `Storylines` ou `Histoire globale` avec transition progressive. |
| Maps | À clarifier | workspace global Map ou future vue narrative maps | Ne pas rendre comme destination interne active tant que le sens produit n’est pas décidé. |
| Scènes | À clarifier / branchable partiellement | `EditorWorkspaceMode.step` | Peut remplacer progressivement `Step`, mais attention : `scène` et `step` ne sont pas forcément synonymes métier. |
| Cinématiques | Branchable vers workspace existant | `EditorWorkspaceMode.cutscene` | Active si elle ouvre le Cutscene Studio réel. |
| Dialogues | Branchée vers workspace existant | `EditorWorkspaceMode.dialogue` | Active si elle ouvre le Dialogue Studio réel. |
| Facts | Disabled / needs model | aucun modèle fiable V0 | Visible disabled seulement si wording honnête. |
| World Rules | Disabled / future surface | aucun workspace final | Visible disabled ou hors scope selon densité. |
| Validateur | Disabled / futur diagnostic panel | aucune validation globale branchée | Ne pas activer. Pas de badge fake. |

### Renommage des libellés existants

Recommandation :

- garder les modes techniques existants dans `EditorWorkspaceMode` pour éviter une migration prématurée ;
- dans la sidebar interne, utiliser progressivement les libellés produit :
  - `Global Story` -> `Storylines` ou `Histoire globale` ;
  - `Step` -> `Scènes` seulement après clarification métier ;
  - `Cutscene` -> `Cinématiques` ;
  - `Dialogue` -> `Dialogues`.

Le renommage visible peut arriver avant le renommage interne, mais il doit être testé pour éviter une confusion avec les anciens tests.

## 8. Impact sur les lots NS-HOME déjà réalisés

| Catégorie | Statut | Décision |
| --- | --- | --- |
| Read model | Valide | Reste inchangé. Il alimente `Aperçu`, pas le shell global. |
| Overview content | Valide | Doit rester dans `NarrativeOverviewWorkspace`, hébergé plus tard par `NarrativeStudioMainArea`. |
| KPI cards | Valide | Reste tel quel. Aucun lien avec la sidebar globale. |
| Main story card | Valide | Reste dans le contenu Overview. |
| Module cards | Valide | Reste dans le contenu Overview. Facts reste `needsModel`. |
| Structure inspector | Valide V0 | Peut rester dans `NarrativeOverviewWorkspace`, puis migrer vers `NarrativeStudioInspectorSlot` si un inspector partagé émerge. |
| Empty states | Valide | Reste dans Overview. |
| Footer metadata | Valide | Reste dans Overview ; ne doit pas être confondu avec status bar globale. |
| Responsive polish | Valide | À retester quand shell interne ajoute une sidebar. |
| Top bar | Valide V0 | Reste globale PokeMap ; ne doit pas absorber la sidebar interne. |
| Project Explorer adjustments | Temporaire utile | Garder comme entrée globale, ne pas considérer comme sidebar finale. |
| Breadcrumb | Valide | Peut rester dans Overview ou migrer dans `NarrativeStudioHeader` selon NS-HOME-16. |
| Mode strip narratif | Transitoire | Candidat principal à migration vers `NarrativeStudioSidebar`. |

Point important :

```text
NS-HOME-11 est utile comme amélioration temporaire du Project Explorer,
mais ne doit pas être considéré comme la sidebar finale du Narrative Studio.
```

## 9. Roadmap corrigée des prochains lots

### NS-HOME-16 — NarrativeStudioShell V0

Objectif :

- créer l’enveloppe interne du Narrative Studio dans `NarrativeWorkspaceCanvas` ;
- ne pas encore créer la sidebar finale détaillée ;
- déplacer le rôle de shell interne hors du mode strip brut.

Fichiers probables :

```text
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart
packages/map_editor/test/ui/canvas/narrative_studio_shell_test.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Non-objectifs :

- pas de collapse Project Explorer ;
- pas de Facts actif ;
- pas de validation active ;
- pas de refonte sidebar globale.

Tests attendus :

- les modes narratifs restent routés ;
- Overview reste visible ;
- Global Story / Step / Cutscene / Dialogue restent accessibles ;
- shell interne présent avec header minimal ;
- ProjectExplorerPanel reste global.

Visual Gate :

- screenshot desktop montrant shell global + shell interne V0.

Risques :

- double header ;
- régression du layout overview ;
- confusion entre top toolbar et header interne.

Critères d’acceptation :

- `NarrativeStudioShell` existe ;
- aucun code global non nécessaire modifié ;
- aucun faux module activé ;
- screenshots produits.

### NS-HOME-17 — Internal Narrative Studio Sidebar V0

Objectif :

- créer `NarrativeStudioSidebar` interne ;
- migrer le mode strip vers une sidebar interne V0 ;
- afficher les entrées branchées et disabled honnêtes.

Fichiers probables :

```text
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart
packages/map_editor/test/ui/canvas/narrative_studio_sidebar_test.dart
```

Non-objectifs :

- pas de collapse global ;
- pas de création de Facts / World Rules / Validateur ;
- pas de renommage massif des modes internes.

Tests attendus :

- Aperçu actif ;
- Storylines/Histoire globale ouvre `globalStory` ;
- Cinématiques ouvre `cutscene` ;
- Dialogues ouvre `dialogue` ;
- Facts/World Rules/Validateur disabled si affichés.

Visual Gate :

- screenshot desktop montrant deux zones distinctes : explorer global + sidebar interne.

Risques :

- double navigation trop lourde ;
- libellé `Scènes` prématuré ;
- overflow medium.

Critères d’acceptation :

- sidebar interne visible ;
- Project Explorer non supprimé ;
- destinations fake disabled.

### NS-HOME-18 — Project Explorer Collapse / Handoff Strategy V0

Objectif :

- définir et implémenter le comportement de l’explorer global quand le studio interne existe.

Fichiers probables :

```text
packages/map_editor/lib/src/ui/editor_shell_page.dart
packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
packages/map_editor/lib/src/features/editor/state/editor_state.dart
packages/map_editor/test/ui/shell/project_explorer_collapse_test.dart
```

Non-objectifs :

- pas de nouvelle navigation interne ;
- pas de préférence persistée disque si non existante ;
- pas de masquage irréversible.

Tests attendus :

- explorer global peut se réduire ;
- retour possible ;
- autres workspaces non cassés ;
- medium stable.

Visual Gate :

- desktop large explorer visible ;
- medium explorer réduit ou stratégie choisie.

Risques :

- casser les workflows maps ;
- état UI global trop couplé au mode narratif.

Critères d’acceptation :

- stratégie documentée ;
- contrôle utilisateur clair ;
- pas de suppression du Project Explorer.

### NS-HOME-19 — Internal Navigation Wiring V0

Objectif :

- fiabiliser le wiring de la sidebar interne vers les workspaces existants ;
- clarifier les disabled states.

Fichiers probables :

```text
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
packages/map_editor/test/ui/canvas/narrative_studio_navigation_test.dart
```

Non-objectifs :

- pas de nouveaux modèles métier ;
- pas de validation réelle ;
- pas de Maps/Scènes ambiguës actives sans décision.

Tests attendus :

- chaque entrée branchée change le bon mode ;
- disabled ne déclenche rien ;
- anciens workspaces narratifs restent accessibles.

Visual Gate :

- focus sidebar interne avec états active/disabled lisibles.

Risques :

- conflits de vocabulaire entre `Step` et `Scènes` ;
- callbacks dupliqués.

Critères d’acceptation :

- navigation déterministe ;
- aucune fausse destination fonctionnelle.

### NS-HOME-20 — Internal Header / Actions V0

Objectif :

- déplacer le contexte interne narratif dans un header de studio propre ;
- garder la top toolbar globale comme chrome global.

Fichiers probables :

```text
packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart
packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart
```

Non-objectifs :

- pas d’action active future ;
- pas de recherche globale ;
- pas de notification.

Tests attendus :

- header interne indique `Narrative Studio / Aperçu` ;
- top bar globale reste stable ;
- actions disabled restent disabled.

Visual Gate :

- screenshot top shell + internal header.

Risques :

- redondance avec breadcrumb ;
- surcharge verticale.

Critères d’acceptation :

- contexte clair ;
- densité acceptable ;
- aucune action fake.

### NS-HOME-21 — Visual Harmonization Against Target

Objectif :

- harmoniser le layout avec l’image cible après apparition du shell interne.

Fichiers probables :

```text
packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
```

Non-objectifs :

- pas de nouveaux modèles ;
- pas de nouvelle feature ;
- pas de pixel perfect.

Tests attendus :

- desktop large ;
- medium ;
- absence d’overflow ;
- blocs existants toujours visibles.

Visual Gate :

- comparaison cible vs état codé ;
- screenshots full shell.

Risques :

- trop de polish avant données réelles ;
- casse responsive.

Critères d’acceptation :

- écran complet plus proche cible ;
- séparation des deux sidebars visible ;
- zéro donnée fake.

### NS-HOME-22 — Final Acceptance Checkpoint

Objectif :

- audit final de la page `Aperçu` et du shell Narrative Studio V0.

Fichiers probables :

```text
reports/narrativeStudio/ui/ns_home_22_final_acceptance_checkpoint.md
```

Non-objectifs :

- pas de code ;
- pas de nouvelle UI ;
- pas de correction cachée.

Tests attendus :

- relance ciblée des tests NS-HOME ;
- analyse ciblée ;
- diff/check evidence.

Visual Gate :

- desktop large ;
- medium ;
- focus navigation ;
- éventuellement comparaison image cible.

Risques :

- evidence incomplet ;
- validation trop optimiste.

Critères d’acceptation :

- checklist complète ;
- écarts connus ;
- prochain chantier clairement séparé.

## 10. Garde-fous architecture

Garde-fous non négociables :

- Ne jamais transformer `ProjectExplorerPanel` en sidebar finale Narrative Studio.
- Ne pas supprimer l’explorer global PokeMap.
- Ne pas créer de fausses destinations internes.
- Ne pas rendre `Facts`, `World Rules` ou `Validateur` actifs sans modèle/source.
- Ne pas mélanger navigation globale PokeMap et navigation interne Narrative Studio.
- Ne pas coupler la sidebar Narrative Studio au runtime.
- Ne pas lire `SaveData` / `GameState`.
- Ne pas ajouter de provider global si un state local suffit.
- Ne pas déplacer les read models métier dans l’UI.
- Ne pas parser les fichiers Yarn depuis la sidebar.
- Ne pas hardcoder les données de l’image cible.
- Ne pas transformer le mode strip actuel en architecture finale par inertie.

## 11. Prochain lot recommandé

Prochain lot exact :

```text
NS-HOME-16 — NarrativeStudioShell V0
```

Objectif promptable :

```text
Créer un shell interne Narrative Studio dans NarrativeWorkspaceCanvas,
sans implémenter encore la sidebar finale,
afin de préparer une séparation claire entre Project Explorer global
et navigation interne Narrative Studio.
```

Pourquoi NS-HOME-16 avant la sidebar :

- il faut d’abord créer le conteneur qui appartient au workspace narratif ;
- cela évite d’ajouter la sidebar interne directement dans `ProjectExplorerPanel` ;
- cela permet de migrer le mode strip proprement au lot suivant.

## 12. Risques

Risques principaux :

- continuer à embellir `ProjectExplorerPanel` comme si c’était la sidebar cible ;
- activer trop tôt `Facts`, `World Rules` ou `Validateur` ;
- rendre `Maps` actif sans décider s’il pointe vers maps globales ou une vue narrative ;
- confondre `Step` avec `Scènes` sans décision sémantique ;
- ajouter un provider global pour une préférence qui peut rester locale ;
- créer un double header trop haut après ajout du shell interne ;
- casser les workspaces non narratifs si `EditorWorkspaceMode` est refactoré trop tôt.

Risque acceptable :

- garder encore une courte période de double navigation V0, si elle est explicitement documentée comme transitoire.

## 13. Evidence Pack

### Branche

```text
main
```

### Git status initial

```text
(aucune sortie)
```

### Git status final

```text
?? reports/narrativeStudio/ui/ns_home_15_internal_shell_sidebar_architecture.md
```

### Git diff --stat final

```text
(aucune sortie)
```

### Git diff --name-only final

```text
(aucune sortie)
```

### Git diff --check final

```text
(aucune sortie)
```

### Fichiers lus

```text
AGENTS.md
agent_rules.md
skills/README.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_1.md
reports/narrativeStudio/ui/ns_home_00_overview_roadmap_proposal.md
reports/narrativeStudio/ui/ns_home_01_overview_data_contract.md
reports/narrativeStudio/ui/ns_home_02_narrative_overview_read_model.md
reports/narrativeStudio/ui/ns_home_03_narrative_overview_shell_placement.md
reports/narrativeStudio/ui/ns_home_04_narrative_overview_kpi_cards.md
reports/narrativeStudio/ui/ns_home_05_narrative_overview_main_story_card.md
reports/narrativeStudio/ui/ns_home_06_narrative_overview_module_cards_grid.md
reports/narrativeStudio/ui/ns_home_07_narrative_overview_structure_inspector.md
reports/narrativeStudio/ui/ns_home_08_narrative_overview_empty_states_footer.md
reports/narrativeStudio/ui/ns_home_09_narrative_overview_responsive_polish.md
reports/narrativeStudio/ui/ns_home_10_narrative_studio_shell_chrome_alignment.md
reports/narrativeStudio/ui/ns_home_11_narrative_studio_sidebar_navigation_alignment.md
reports/narrativeStudio/ui/ns_home_12_narrative_studio_top_bar_action_affordances.md
reports/narrativeStudio/ui/ns_home_13_narrative_studio_breadcrumb_shell_header.md
reports/narrativeStudio/ui/ns_home_14_narrative_studio_shell_header_density.md
packages/map_editor/lib/src/ui/editor_shell_page.dart
packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/lib/src/ui/shared/top_toolbar.dart
packages/map_editor/lib/src/ui/shared/status_bar.dart
packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
packages/map_editor/lib/src/features/editor/state/editor_state.dart
packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart
packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart
```

### Screenshots inspectés

```text
reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_desktop.png
reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_focus.png
reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_medium.png
/Users/karim/Desktop/assets/pokeMap/définitive/1 - page d'accueil.png
```

Confirmation fichiers screenshots :

```text
reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_desktop.png: PNG image data, 1600 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_focus.png:   PNG image data, 1600 x 700, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_medium.png:  PNG image data, 1180 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_desktop.png May 27 15:56:13 2026 244834
reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_focus.png May 27 15:56:18 2026 170329
reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_medium.png May 27 15:56:23 2026 187968
```

### Confirmations audit-only

```text
Aucun code production modifié.
Aucun test modifié.
Aucun widget Flutter créé.
Aucun provider créé.
Aucun fichier map_core/runtime/gameplay/battle modifié.
```

### Tests

Non lancés volontairement : NS-HOME-15 est audit/design-only et ne modifie aucun code ni test.

## 14. Auto-review critique

Points solides :

- la distinction entre sidebar globale et sidebar interne est explicite ;
- NS-HOME-11 est reclassé comme amélioration temporaire utile, pas comme cible finale ;
- la roadmap force `NarrativeStudioShell` avant `NarrativeStudioSidebar` ;
- les destinations non fiables restent disabled / needs model.

Points à surveiller :

- `EditorWorkspaceMode` mélange encore modes globaux et modes narratifs internes ; une séparation future sera probablement saine, mais pas urgente ;
- `Maps` et `Scènes` nécessitent une décision produit avant activation ;
- le futur comportement de collapse du Project Explorer doit être un lot dédié, car il touche le shell global.

## 15. Regard critique sur le prompt

Le prompt corrige un vrai risque de dérive : les lots NS-HOME-10 à NS-HOME-14 amélioraient progressivement le chrome global, et NS-HOME-11 pouvait être mal interprété comme début de sidebar finale.

La consigne la plus importante est la bonne :

```text
ProjectExplorerPanel = entrée globale vers Narrative Studio
NarrativeStudioSidebar = navigation interne du Narrative Studio
```

Le prompt est volontairement strict et cela évite de coder trop tôt. Le prochain lot doit rester aussi strict : créer le shell interne, pas encore résoudre toute la navigation finale.
