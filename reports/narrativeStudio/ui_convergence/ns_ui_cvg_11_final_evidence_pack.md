# Evidence Pack final — Narrative Studio UI Convergence

Date de clôture : 18 juillet 2026
Lot exact : `NS-UI-CVG-11 — Ancien shell retiré, QA complète et Evidence Pack`
Programme couvert : `NS-UI-CVG-00` à `NS-UI-CVG-11`
HEAD audité : `f93b70ad`
Branche : `main`
Verdict : **ACCEPTÉ pour le périmètre de convergence UI Narrative Studio**

## 1. Résumé exécutif

Le Narrative Studio utilise désormais la grammaire produit de l’Event Builder
sur toutes ses routes réelles, sans reproduire artificiellement la grille
métier Event dans les autres outils. Une seule coque
`NarrativeStudioProductShell`, une seule navigation et une seule page de
workspace structurent Aperçu, Storylines, Étape, Scènes, Événements,
Cinématiques, Dialogues, Facts et Règles du monde.

La convergence est **terminée à 100 % des critères pondérés du plan** : les
douze lots ont une preuve de code, de test ou de QA. La compatibilité Event
legacy/dual-read/V2 et les trois modes Cinématiques est conservée. Les actions
visibles restent honnêtes : aucun bouton, compteur ou statut n’est simulé quand
la capacité métier n’existe pas.

L’inventaire Git-visible du lot comprend 65 chemins suivis et 53 nouveaux
chemins, soit 118 chemins. La roadmap locale ignorée par Git a également été
actualisée de 0 % à 100 %.

La suite ciblée finale passe avec **191 tests réussis**. L’analyse Flutter ne
signale aucun problème et le build macOS debug aboutit. La suite package
complète a été exécutée une fois et a terminé avec **3338 réussites et 9
échecs** ; les cinq goldens affectés ont ensuite été inspectés et régénérés et
les quatre tests de performance/génération ont tous été rejoués isolément avec
succès. Comme la suite complète n’a pas été relancée une seconde fois pendant
plus de sept minutes, ce rapport ne prétend pas qu’elle est verte en une seule
passe finale.

## 2. Scope confirmé

### Inclus et livré

- coque produit commune du Narrative Studio ;
- navigation unique, sélection de destination et passerelle Maps ;
- contexte projet, état dirty, breadcrumb et actions contextuelles réelles ;
- Aperçu, Storylines, Étape, Scènes, Événements legacy/V2, Cinématiques
  bibliothèque/builder/legacy, Dialogues, Facts et Règles du monde ;
- états sans projet honnêtes ;
- design system, responsive desktop, DPR 2, focus, clavier et sémantiques ;
- police et icônes déterministes pour les preuves raster ;
- goldens normatifs 1672 × 941 et comparaisons avec la cible utilisateur.

### Limites volontairement conservées

- aucune refonte du Map Editor ;
- aucun authoring de map, PNJ, objet ou zone dans l’Event Builder ;
- aucune modification de `map_core`, `map_gameplay`, `map_runtime`, des schémas
  projet ou des formats de persistance ;
- aucune modification des politiques Event `legacyOnly`, `dualRead`, `v2Only` ;
- aucune refonte fonctionnelle de Yarn, des graphes, des cinématiques ou des
  règles du monde ;
- aucun faux Validateur, compteur de santé, notification ou bouton décoratif ;
- aucune suppression des chemins legacy encore couverts ;
- aucune instrumentation Marionette ajoutée sans autorisation explicite ;
- aucune opération Git d’écriture effectuée.

## 3. Audit initial

### Constat de départ

L’audit visuel et architectural a identifié une cassure nette entre l’Event
Builder et le reste du Narrative Studio : double chrome, sidebar Narrative
imbriquée, Project Explorer réintroduit selon les routes, vocabulaire variable,
actions globales non contextualisées et cadres métier sans rythme commun.

### Contrats existants préservés

- `EditorWorkspaceMode` reste la source de vérité de la destination ;
- `EventSystemMode` continue de décider legacy/dual-read/V2 ;
- chaque workspace conserve ses contrôleurs, providers et mutations ;
- `EditorShellPage` reste l’hôte produit ;
- les primitives et couleurs restent celles du design system PokeMap ;
- les workspaces spécialisés conservent leur composition métier : dashboard,
  graphe, bibliothèque, registre ou timeline.

### Fichiers et tests repérés avant modification

- anciens hôtes : `narrative_studio_shell.dart`,
  `narrative_studio_sidebar.dart`,
  `events_v2/event_builder_v2_product_shell.dart` ;
- hôte global : `editor_shell_page.dart` et
  `narrative_workspace_canvas.dart` ;
- workspaces de chaque destination Narrative ;
- harness Event V2 et shell chrome existants ;
- tests Storylines, Scènes, Event, Cinématiques, Dialogues, Facts/Règles du
  monde et Aperçu ;
- audit source :
  `reports/narrativeStudio/ui_consistency_audit/narrative_studio_event_builder_visual_system_audit_2026-07-17.md` ;
- cible utilisateur :
  `reports/narrativeStudio/ui_consistency_audit/evidence/00-user-target-event-builder-1672x941.png`.

### Risques initiaux

| Risque | Traitement |
|---|---|
| Copier la grille Event partout | coque partagée, body métier conservé |
| Deux sources de navigation | enum + présentation + policy pures |
| Régression legacy | routes legacy maintenues et testées |
| Contrôles mensongers | callbacks requis ou action absente/désactivée |
| Couleurs locales | primitives et tokens du design system seulement |
| Goldens non portables | fonte versionnée + assets précachés |
| Overflow/focus | matrices viewport/scale, Tab/Shift+Tab, DPR 2 |
| État projet perdu | navigation testée avec projet, map et dirty préservés |

## 4. Décisions d’architecture

```text
EditorShellPage
└── NarrativeStudioProductShell
    ├── ProductHeader
    ├── ProjectContext + ProductNavigation
    └── NarrativeStudioWorkspacePage
        ├── Breadcrumb + actions réelles
        ├── diagnostics éventuels
        └── body métier du workspace
```

- `NarrativeStudioDestination` formalise les destinations produit.
- `NarrativeStudioRoutePresentation` centralise vocabulaire et breadcrumbs ;
  les icônes restent définies par la navigation produit.
- `NarrativeStudioShellPolicy` mappe exhaustivement les modes éditeur.
- `NarrativeStudioProductNavigation` porte le rail partagé et la passerelle
  Maps, sans provider métier.
- `NarrativeStudioProductShell` porte projet, dirty state, navigation et slot.
- `NarrativeStudioWorkspacePage` porte contexte, actions et body métier.
- `NarrativeWorkspaceCanvas` ne recrée plus un second shell.
- Les anciens shells ont été supprimés après recherche de zéro référence.

## 5. Avancement des douze lots

| Lot | Poids | Preuve principale | Statut |
|---|---:|---|---|
| `NS-UI-CVG-00` | 5 % | harness réel + contrat visuel | DONE |
| `NS-UI-CVG-01` | 7 % | destinations, présentation, policy et tests exhaustifs | DONE |
| `NS-UI-CVG-02` | 13 % | coque/page partagées, responsive et accessibilité | DONE |
| `NS-UI-CVG-03` | 10 % | Event legacy/dual/V2 sur la coque commune | DONE |
| `NS-UI-CVG-04` | 10 % | Scènes migré, canvas et inspecteur conservés | DONE |
| `NS-UI-CVG-05` | 8 % | Storylines + Étape migrés | DONE |
| `NS-UI-CVG-06` | 7 % | Dialogues migré, actions disque honnêtes | DONE |
| `NS-UI-CVG-07` | 5 % | bibliothèque Cinématiques migrée | DONE |
| `NS-UI-CVG-08` | 10 % | Cinematic Builder et legacy migrés | DONE |
| `NS-UI-CVG-09` | 7 % | Facts + Règles du monde migrés | DONE |
| `NS-UI-CVG-10` | 5 % | Aperçu migré, santé non évaluée masquée | DONE |
| `NS-UI-CVG-11` | 13 % | anciens shells supprimés, QA, build, Evidence Pack | DONE |
| **Total** | **100 %** | **tous critères du périmètre** | **100 %** |

## 6. Verdicts des sub-agents et passes indépendantes

| Passe | Verdict initial | Correction / preuve | Verdict final |
|---|---|---|---|
| Audit / Architecture | divergence confirmée | coque séparée du body métier, contrats purs | PASS |
| Implémentation | exécution par lots | toutes destinations et variantes migrées | PASS |
| Tests | matrices incomplètes au premier contrôle | 60 cas spécialisés + gates route/accessibilité | PASS |
| Build / Validation | à obtenir | analyze vert, build macOS debug vert | PASS |
| Revue intégration spécialisée | NEEDS_CHANGES : santé projet et matrice | santé masquée si non évaluée, 107 tests verts | PASS |
| Revue qualité Event/shell | CHANGES REQUIRED : fonte, Dialogues, V1-35, imports | fonte portable, actions masquées, V1-35 inspecté, analyze vert | PASS — 258 tests ciblés |
| Critique Lot 11 | CHANGES REQUIRED : QA, failures, Evidence Pack | QA global, failures absents, Evidence Pack présent | PASS conditionnel levé après contrôle du rapport |

## 7. Inventaire complet des fichiers modifiés — production

| Fichier | Zones modifiées | Raison et impact |
|---|---|---|
| `design-qa.md` | document complet | remplace l’ancien QA Event-only par la QA globale de convergence |
| `packages/map_editor/pubspec.yaml` | section `assets` | embarque la fonte de capture portable et sa licence |
| `packages/map_editor/lib/src/ui/editor_shell_page.dart` | `_EditorShellPageState.build`, `selectNarrativeDestination`, `_NarrativeStudioProjectCard`, `_NarrativeStudioSaveStatus` | monte une seule coque commune et préserve projet/map/dirty |
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | dispatch des modes et états sans projet | retire le shell imbriqué et rend les états honnêtes |
| `packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart` | composition, header, santé projet | adopte `WorkspacePage`, masque une santé non calculée |
| `packages/map_editor/lib/src/ui/canvas/narrative_overview_structure_inspector.dart` | bloc Project Health | n’affiche que les diagnostics réels |
| `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart` | page, actions, focus modal | branche la coque et restaure le focus après création |
| `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart` | layout/contraintes | rend le graphe compatible avec le nouveau cadre |
| `packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart` | sous-route, breadcrumb, page | présente Étape comme contexte enfant de Storylines |
| `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart` | page, side sheet, focus/retour | migre le workspace sans perdre canvas/inspecteur |
| `packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart` | page, actions, état vide | masque les opérations disque sans racine projet |
| `packages/map_editor/lib/src/ui/canvas/facts_world_rules/facts_world_rules_workspace.dart` | page, titres, état vide | harmonise Facts et Règles du monde avec la coque |
| `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart` | page bibliothèque | conserve recherche/liste dans le cadre partagé |
| `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart` | page builder, panneaux, responsive | conserve la timeline/authoring dans la coque commune |
| `packages/map_editor/lib/src/ui/canvas/cutscene_studio/cutscene_studio_workbench.dart` | cadre legacy, contraintes | conserve le workbench legacy dans la nouvelle page |
| `packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart` | retrait ancien wrapper | évite le double shell sur le chemin legacy |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart` | hôte route, actions, diagnostics | remplace la coque privée par la coque commune |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_inspector.dart` | `EventBuilderV2Inspector.build` | remplace l’état vide redondant par une tuile neutre sémantique |
| `packages/map_editor/lib/src/ui/design_system/pokemap_icon_button.dart` | sémantique du bouton | expose un label accessible aux actions icône |
| `packages/map_editor/lib/src/ui/design_system/pokemap_sidebar_item.dart` | `growForTextScale`, hauteur minimale | laisse les libellés accessibles grandir sans réduire la hauteur nominale |
| `packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart` | trois `DefaultTextStyle.merge` | préserve la famille de fonte héritée dans les lignes sidebar |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_shell.dart` | fichier supprimé | élimine la coque Event privée devenue doublon |
| `packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart` | fichier supprimé | élimine l’ancien shell imbriqué |
| `packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart` | fichier supprimé | élimine la seconde navigation Narrative |

Documentation locale ignorée par Git mais mise à jour :

| Fichier | Zones modifiées | Raison et impact |
|---|---|---|
| `docs/superpowers/plans/2026-07-17-narrative-studio-event-builder-ui-convergence.md` | statut, progression et tableaux des phases/lots | passe la roadmap de `NON DÉMARRÉ / 0 %` à `TERMINÉ / 100 %` et relie l’Evidence Pack ; le fichier reste ignoré par la règle `/docs/*` du dépôt |

## 8. Inventaire complet des fichiers modifiés — tests

| Fichier | Zones modifiées | Raison et impact |
|---|---|---|
| `packages/map_editor/test/cinematic_builder_workspace_test.dart` | harness et assertions shell | couvre le builder dans la coque commune |
| `packages/map_editor/test/cinematics_library_workspace_test.dart` | route, sans projet, actions | couvre la bibliothèque migrée |
| `packages/map_editor/test/dialogue_studio_explorer_dialogue_widgets_test.dart` | route, actions avec/sans racine | prouve l’absence de faux contrôles |
| `packages/map_editor/test/event_builder_workspace_test.dart` | attentes chrome | caractérise le nouveau montage Event |
| `packages/map_editor/test/facts_world_rules_manager_test.dart` | route, golden V1-35, imports | couvre les deux registres et leur rendu portable |
| `packages/map_editor/test/scenes_workspace_shell_test.dart` | shell, side sheet, focus | couvre navigation/fermeture/restauration |
| `packages/map_editor/test/shell_chrome_test_harness.dart` | montage commun | adapte les fixtures au shell produit unique |
| `packages/map_editor/test/step_studio_workspace_regression_test.dart` | sous-route et non-régression | couvre breadcrumb et état Étape |
| `packages/map_editor/test/storylines_current_global_story_characterization_test.dart` | caractérisation shell | préserve le modèle Storylines courant |
| `packages/map_editor/test/storylines_workspace_shell_test.dart` | navigation, modal, focus | couvre le workspace migré |
| `packages/map_editor/test/support/event_builder_v2_product_route_fixture.dart` | fixture de route | utilise le montage partagé |
| `packages/map_editor/test/support/event_builder_v2_visual_harness.dart` | fonte/assets/hôte | rend les goldens Event déterministes |
| `packages/map_editor/test/ui/canvas/event_builder_v2_product_route_test.dart` | contrats route, goldens, responsive | couvre les variantes Event et la coque partagée |
| `packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart` | navigation réelle | prouve sélection et conservation projet/map/dirty |
| `packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart` | santé projet et états | couvre non évalué puis warning réel |
| `packages/map_editor/test/ui/shell/project_explorer_handoff_test.dart` | handoff Maps/Narrative | prouve l’absence du Project Explorer imbriqué |

## 9. Fichiers binaires suivis modifiés

Les fichiers suivants sont des oracles raster inspectés puis régénérés. Leur
diff est binaire ; la zone modifiée est l’image complète et l’impact attendu
est l’alignement avec la coque/fonte portable.

### Goldens Event

- `packages/map_editor/test/goldens/event_builder_v2/phase_1/event_builder_v2_full_product_route_1672x941.png`
- `packages/map_editor/test/goldens/event_builder_v2/phase_1/event_builder_v2_product_route_1672x941.png`
- `packages/map_editor/test/goldens/event_builder_v2/phase_k/event_builder_v2_1672x941.png`

### Captures historiques Scènes

- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_bis_edge_selection_deletion_ux_v0.png`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_visual_port_connection_ux_v0.png`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_wire_anchor_color_code.png`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_17_condition_authoring_v0.png`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_18_fact_registry_v0.png`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.png`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_29_storyline_step_scene_link_v0.png`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_30_bis_scene_node_deletion_ux_v0.png`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_30_scene_node_payload_editing_v0.png`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_31_scene_consequence_authoring_ui_v0.png`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_35_facts_world_rules_manager_ui_v0.png`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_39_cinematic_scene_builder_picker_v0.png`

### Captures historiques Storylines

- `reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_bis_graph_full_layout.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_authoring_actions.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_collapsed_chapter.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_expanded_chapter_steps.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_full_width_accordion.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_graph_regression.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_empty_polished.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_main_polished.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_sidequest_attached_polished.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_sidequest_standalone_polished.png`

## 10. Fichiers créés

### Production et support texte

- `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_destination.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_route_presentation.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_shell_policy.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_product_navigation.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart`
- `packages/map_editor/test/support/narrative_studio_capture_fonts.dart`
- `packages/map_editor/test/support/narrative_studio_visual_harness.dart`
- `packages/map_editor/assets/fonts/pokemap_capture_sans_LICENSE.txt`

### Tests texte

- `packages/map_editor/test/ui/canvas/narrative_studio_destination_test.dart`
- `packages/map_editor/test/ui/canvas/narrative_studio_shell_policy_test.dart`
- `packages/map_editor/test/ui/canvas/narrative_studio_shell_contract_test.dart`
- `packages/map_editor/test/ui/canvas/narrative_studio_responsive_accessibility_test.dart`
- `packages/map_editor/test/ui/canvas/narrative_studio_visual_contract_test.dart`
- `packages/map_editor/test/ui/canvas/narrative_studio_specialized_routes_test.dart`
- `packages/map_editor/test/ui/canvas/narrative_studio_workspace_visual_test.dart`
- `packages/map_editor/test/ui/canvas/narrative_studio_cinematics_route_test.dart`

Le contenu complet de ces dix-sept fichiers texte figure en annexe A. Le
rapport lui-même n’est pas répliqué récursivement.

- `reports/narrativeStudio/ui_convergence/ns_ui_cvg_11_final_evidence_pack.md`
  est le dix-huitième fichier texte créé ; son contenu est précisément le
  présent document et n’est donc pas dupliqué récursivement.

### Binaires créés

- fonte : `packages/map_editor/assets/fonts/pokemap_capture_sans_regular.ttf` ;
- onze nouveaux goldens Narrative Studio sous
  `packages/map_editor/test/goldens/narrative_studio/` ;
- une planche de synthèse et vingt-deux comparaisons QA sous
  `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/`.

Le manifeste SHA-256/dimensions complet figure en annexe B. Les binaires ne
peuvent pas être représentés fidèlement comme texte Markdown ; leur hash et
leurs dimensions constituent leur contenu vérifiable.

## 11. Tests créés ou étendus

- mapping exhaustif mode → destination et passerelle Maps ;
- policy commune sur tous les modes Event ;
- unicité de la coque/page/navigation ;
- états avec et sans projet pour toutes les destinations ;
- préservation projet/map/dirty pendant la navigation ;
- Event legacy, dual-read et V2 ;
- Cinématiques bibliothèque, builder et legacy ;
- 4 routes spécialisées × 5 viewports × 3 échelles texte = 60 cas ;
- DPR 2, Tab, Shift+Tab, sémantiques selected/disabled/status/diagnostic ;
- Escape, retour Navigator et focus de la side sheet Scènes ;
- restauration du focus après le modal Storylines ;
- Project Health masqué si non évalué et visible après warning réel ;
- Dialogues sans racine projet : actions disque absentes ;
- goldens normatifs 1672 × 941 et non-régressions historiques.

## 12. Commandes et résultats exacts

### Gate final Narrative Studio

```bash
cd packages/map_editor
flutter test --no-pub \
  test/ui/canvas/narrative_studio_destination_test.dart \
  test/ui/canvas/narrative_studio_shell_policy_test.dart \
  test/ui/canvas/narrative_studio_shell_contract_test.dart \
  test/ui/canvas/narrative_studio_responsive_accessibility_test.dart \
  test/ui/canvas/narrative_studio_visual_contract_test.dart \
  test/ui/canvas/narrative_studio_specialized_routes_test.dart \
  test/ui/canvas/narrative_studio_workspace_visual_test.dart \
  test/ui/canvas/narrative_studio_cinematics_route_test.dart \
  test/ui/canvas/event_builder_v2_product_route_test.dart
```

Résultat : `191 tests passed`, `All tests passed!`, exit 0.

Après suppression des trois attentes murales `Future.delayed` restantes dans
les nouveaux tests visuels, les deux fichiers concernés ont été rejoués :

```bash
flutter test --no-pub \
  test/ui/canvas/narrative_studio_workspace_visual_test.dart \
  test/ui/canvas/narrative_studio_cinematics_route_test.dart
```

Résultat : `61 tests passed`, `All tests passed!`, exit 0.

La critique indépendante a ensuite recroisé Cinématiques avec les routes
spécialisées :

```bash
flutter test --no-pub -r compact \
  test/ui/canvas/narrative_studio_cinematics_route_test.dart \
  test/ui/canvas/narrative_studio_specialized_routes_test.dart
```

Résultat : `79 tests passed`, `All tests passed!`, exit 0.

### Revue spécialisée

```bash
flutter test --no-pub \
  test/ui/canvas/narrative_studio_specialized_routes_test.dart \
  test/ui/canvas/narrative_overview_workspace_test.dart
```

Résultat : `107 tests passed`, exit 0.

### Goldens historiques impactés

```bash
flutter test --no-pub --update-goldens \
  test/scene_cinematic_picker_test.dart \
  test/ui/canvas/event_builder_v2_phase_k_visual_test.dart \
  test/storylines_workspace_scene_links_test.dart \
  test/storylines_structure_layout_test.dart \
  test/storylines_seed_graph_usability_test.dart
```

Résultat : `28 tests passed`, `All tests passed!`, exit 0. Chaque baseline a
été examinée avant acceptation. Le golden V1-35 a ensuite été rejoué
séparément : `5 tests passed`, `All tests passed!`, exit 0.

### Analyse

```bash
cd packages/map_editor
flutter analyze --no-pub
```

Résultat exact : `No issues found! (ran in 6.1s)`, exit 0.

### Format

```bash
{ git diff --name-only -- '*.dart'; git ls-files --others --exclude-standard -- '*.dart'; } \
  | sort -u | xargs dart format --output=none --set-exit-if-changed
```

Résultat : `Formatted 51 files (0 changed)`, exit 0.

```bash
dart format --output=none --set-exit-if-changed lib test
```

Résultat : 110 fichiers historiques hors scope signalés comme non formatés,
sans écriture grâce à `--output=none`. Cette garde globale n’est donc pas
verte ; le scope modifié l’est.

### Build

```bash
cd packages/map_editor
flutter build macos --debug --no-pub
```

Résultat exact :
`✓ Built build/macos/Build/Products/Debug/map_editor.app`, exit 0.

### Suite package complète et reprises isolées

```bash
cd packages/map_editor
flutter test --no-pub
```

Résultat de la passe complète : **3338 réussites, 9 échecs**.

- cinq échecs golden causés par la nouvelle coque/fonte : V1-39, Event Phase
  K, V1-29, Storylines Structure et Storylines Seed Fix ; tous inspectés,
  régénérés et couverts par la reprise à 28 tests réussis ;
- `test/selbrume_port_reference_assets_builder_test.dart` : rejoué isolément,
  `+1`, `All tests passed!`, environ 16 s ;
- `test/narrative_event_authoring_snapshot_performance_test.dart` : rejoué
  isolément, `+1`, `All tests passed!` ;
- `test/event_registry_persistence_performance_test.dart` : rejoué isolément,
  `+1`, `All tests passed!` ;
- `test/narrative_event_validation_incremental_performance_test.dart` : rejoué
  isolément, `+1`, `All tests passed!`, `p95_us: 12846`, budget `36000`.

Ces quatre derniers échecs étaient sensibles à la concurrence de la suite
complète. Le rapport conserve toutefois le résultat global exact et ne le
transforme pas en succès fictif.

### Gardes finales

```bash
rg -n --glob '*.dart' \
  'NarrativeStudioSidebar|EventBuilderV2ProductShell|narrative-studio-shell|narrative-studio-sidebar|event-builder-v2-product-shell|NarrativeStudioShell\\b' \
  packages/map_editor/lib packages/map_editor/test
```

Résultat : aucune sortie, exit 1 attendu pour absence de correspondance.

```bash
find packages/map_editor/test -type f -path '*/failures/*' -print
git diff --check
```

Résultats : aucun artefact d’échec ; aucune erreur de whitespace.

## 13. Preuves visuelles

- cible utilisateur SHA-256 :
  `2072679b3b861a63c068628450705d39e70ad59dc5067e0a0bf91c0bcbe8c885` ;
- planche finale cible + onze états représentatifs SHA-256 :
  `d0b9e73ec03fa91d30c9ccce18ad294929e3ef2db10be6eddb82cc3074c2858f` ;
- treize comparaisons individuelles couvrent les variantes Event et
  Cinématiques ;
- chaque comparaison associe la référence et l’implémentation au même viewport
  avant jugement ;
- `design-qa.md` se termine par `final result: passed`.

Principaux oracles :

| Route | SHA-256 |
|---|---|
| Aperçu | `f5e8b1b76ee3338bb2707cced012cd73c8379fbf5dbd7ca311220fe592f28ef5` |
| Storylines | `e5d594801a35537859af59231aad45906b5139844f8dcf562c6f6358ba463f29` |
| Scènes | `b5502bd011aa318a532d09791e2bf4b494caaeac08d6bd534601f3277628c0f7` |
| Event V2 | `f9bf76815dcc511210d9fd9a9af1a0993fc0ee165aa0503b3fd977e6c357eb76` |
| Cinématiques — bibliothèque | `0f50f0789432bed10c7d1623daa4268d77f76922b55f7887277d111d6176d7f7` |
| Dialogues | `f2c9d4fd44e663211a8d921539517929b25761b16fe7159f162276fb7c682dd2` |
| Facts | `2a7fcf943567847ef3c64dee680de875d123062012f8c4d8574edb512671f40b` |
| Règles du monde | `3c180fa7a46e850010bd14582b99d2dcea16becf87bbdfb4ab467d736fdd96c9` |
| Étape | `73e664ac65a3410fa508e4ae564df221209c8083a0766ac83b4278bd47c21aa1` |

## 14. État Git

### Initial

- branche : `main` ;
- HEAD : `f93b70ad` ;
- zéro fichier tracked modifié ;
- 83 entrées untracked préexistantes : audit UI, preuves de l’audit, assets
  Selbrume V2 et lock Selbrume ;
- aucun worktree dédié.

### Final

- branche : `main` ;
- HEAD : `f93b70ad` inchangé ;
- modifications du lot présentes mais non indexées ;
- roadmap locale `docs/superpowers/plans/...` mise à 100 %, mais ignorée par
  `.gitignore` et donc absente du statut Git ;
- aucun `git add`, commit, push, stash, reset, checkout ou autre écriture Git ;
- les assets et le lock Selbrume préexistants ont été préservés ;
- l’inventaire exact final est reproduit en annexe C.

## 15. Critique finale et risques restants

### Auto-critique

- Le gain principal est la cohérence de coque ; les workspaces ne sont pas des
  clones internes de l’Event Builder, conformément au plan.
- La surface de diff est large parce que toutes les routes et de nombreux
  oracles historiques partagent désormais la même coque/fonte. Les contrats
  métier n’ont cependant pas bougé.
- Le nombre de goldens apporte une preuve visuelle forte mais augmente le coût
  de maintenance ; la fonte versionnée et les harness communs limitent ce coût.
- Deux anciens crops Storylines (`collapsed_chapter` et
  `expanded_chapter_steps`) sont byte-identiques : leur finder remonte à la
  même frontière de rendu. Les assertions fonctionnelles distinctes prouvent
  bien les deux états, mais ces deux crops historiques ne constituent pas à eux
  seuls une preuve différentielle utile.
- Le build macOS prouve la compilabilité produit, mais pas un parcours automatisé
  du binaire : `map_editor` ne contient pas Marionette et aucune instrumentation
  n’a été ajoutée sans autorisation.
- La suite package complète n’est pas présentée comme verte : un second run
  intégral reste la meilleure preuve supplémentaire, malgré les reprises
  isolées réussies.
- Le format global du dépôt contient 110 écarts historiques hors scope ; aucun
  nettoyage opportuniste n’a été entrepris.

### Risques restants

| Risque | Niveau | Mitigation / prochaine action proposée |
|---|---|---|
| suite complète non rejouée après corrections | faible | relancer `flutter test --no-pub` en série avant release |
| QA binaire desktop sans Marionette | faible | ajouter l’instrumentation dans un lot séparé si souhaité |
| maintenance de nombreux goldens | faible | conserver fonte/harness centralisés et inspection obligatoire |
| deux crops Storylines historiques identiques | faible | remplacer leur frontière de capture dans un lot test-only séparé |
| acceptation visuelle subjective | faible | faire valider la planche finale par Karim |
| fichiers Selbrume non suivis présents | hors scope | les traiter dans leur chantier propriétaire |

### Verdicts indépendants post-correction

- Revue intégration/architecture : **PASS**, 107 tests réussis.
- Revue qualité shell : **PASS**, 258 tests ciblés, analyse verte, inspections
  V1-35 et routes spécialisées sans anomalie.
- Critique de clôture Lot 11 : **PASS** après présence du rapport, QA globale,
  zéro artefact d’échec et gardes historiques propres.

### Prochaines étapes proposées, non implémentées

1. validation visuelle finale par Karim sur la planche de comparaison ;
2. seconde passe complète `flutter test --no-pub` si un gate release exige un
   résultat monolithique vert ;
3. commit/push uniquement sur demande explicite ;
4. lot séparé facultatif pour l’automatisation desktop Marionette.

---

## Annexe A — contenu complet des fichiers texte créés

### `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_destination.dart`

```dart
/// Selectable, project-level destinations exposed by Narrative Studio.
///
/// Maps is intentionally absent: it is a gateway to Map Editor, not a
/// Narrative Studio selection. Validator is also intentionally absent until a
/// real product route and real validation state exist.
enum NarrativeStudioDestination {
  overview,
  storylines,
  scenes,
  events,
  cinematics,
  dialogues,
  facts,
  worldRules,
}
```

### `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_route_presentation.dart`

```dart
import '../../../features/editor/state/models/editor_workspace_mode.dart';
import 'narrative_studio_destination.dart';

/// UI-only description of an editor route inside Narrative Studio.
///
/// This value contains no provider or project data. Workspaces can enrich the
/// breadcrumb with a real chapter, step, scene or entity name at composition
/// time without changing destination selection.
class NarrativeStudioRoutePresentation {
  const NarrativeStudioRoutePresentation({
    required this.destination,
    required this.label,
    required this.breadcrumbLabels,
  });

  final NarrativeStudioDestination destination;
  final String label;
  final List<String> breadcrumbLabels;
}

/// Pure mapping between the existing editor routes and product navigation.
///
/// Non-narrative routes return `null`. In particular, Map Editor never selects
/// an item in the Narrative Studio rail.
NarrativeStudioRoutePresentation? narrativeStudioRoutePresentationFor(
  EditorWorkspaceMode workspaceMode,
) {
  return switch (workspaceMode) {
    EditorWorkspaceMode.narrativeOverview =>
      const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.overview,
        label: 'Aperçu',
        breadcrumbLabels: ['Aperçu'],
      ),
    EditorWorkspaceMode.globalStory => const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.storylines,
        label: 'Storylines',
        breadcrumbLabels: ['Storylines'],
      ),
    EditorWorkspaceMode.step => const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.storylines,
        label: 'Étape',
        breadcrumbLabels: ['Storylines', 'Étape'],
      ),
    EditorWorkspaceMode.scenes => const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.scenes,
        label: 'Scènes',
        breadcrumbLabels: ['Scènes'],
      ),
    EditorWorkspaceMode.events => const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.events,
        label: 'Event Builder',
        breadcrumbLabels: ['Event Builder'],
      ),
    EditorWorkspaceMode.cutscene => const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.cinematics,
        label: 'Cinématiques',
        breadcrumbLabels: ['Cinématiques'],
      ),
    EditorWorkspaceMode.dialogue => const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.dialogues,
        label: 'Dialogues',
        breadcrumbLabels: ['Dialogues'],
      ),
    EditorWorkspaceMode.facts => const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.facts,
        label: 'Facts',
        breadcrumbLabels: ['Facts'],
      ),
    EditorWorkspaceMode.worldRules => const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.worldRules,
        label: 'Règles du monde',
        breadcrumbLabels: ['Règles du monde'],
      ),
    _ => null,
  };
}
```

### `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_shell_policy.dart`

```dart
import 'package:map_core/map_core.dart';

import '../../../features/editor/state/models/editor_workspace_mode.dart';

/// Incremental adoption gate for the shared Narrative Studio product shell.
///
/// The policy is deliberately detached from widgets and providers so routing
/// can be tested as a complete truth table before any workspace is migrated.
abstract final class NarrativeStudioShellPolicy {
  static bool shouldUseProductShell({
    required EditorWorkspaceMode workspaceMode,
    required EventSystemMode eventSystemMode,
  }) {
    if (workspaceMode == EditorWorkspaceMode.scenes ||
        workspaceMode == EditorWorkspaceMode.globalStory ||
        workspaceMode == EditorWorkspaceMode.step ||
        workspaceMode == EditorWorkspaceMode.cutscene ||
        workspaceMode == EditorWorkspaceMode.dialogue ||
        workspaceMode == EditorWorkspaceMode.facts ||
        workspaceMode == EditorWorkspaceMode.worldRules ||
        workspaceMode == EditorWorkspaceMode.narrativeOverview) {
      return true;
    }
    if (workspaceMode != EditorWorkspaceMode.events) return false;

    return switch (eventSystemMode) {
      EventSystemMode.legacyOnly => true,
      EventSystemMode.dualRead || EventSystemMode.v2Only => true,
    };
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_product_navigation.dart`

```dart
import 'package:flutter/cupertino.dart';

import '../../design_system/design_system.dart';
import 'narrative_studio_destination.dart';

const narrativeStudioProductNavigationMapsKey =
    ValueKey<String>('narrative-studio-product-nav-maps');
const narrativeStudioProductNavigationStatusKey =
    ValueKey<String>('narrative-studio-product-navigation-status');

/// Provider-free project navigation shared by Narrative Studio workspaces.
class NarrativeStudioProductNavigation extends StatelessWidget {
  const NarrativeStudioProductNavigation({
    super.key,
    required this.selectedDestination,
    required this.onSelectDestination,
    required this.onOpenMaps,
    this.status,
  });

  final NarrativeStudioDestination selectedDestination;
  final ValueChanged<NarrativeStudioDestination> onSelectDestination;
  final VoidCallback onOpenMaps;

  /// Real project status supplied by the host. No placeholder is rendered when
  /// it is absent.
  final Widget? status;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(8),
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Column(
          children: [
            for (final item in _items.take(2)) ...[
              _NarrativeStudioNavigationItem(
                key: ValueKey<String>(
                  'narrative-studio-product-nav-${item.destination.name}',
                ),
                icon: item.icon,
                label: item.label,
                selected: item.destination == selectedDestination,
                onTap: () => onSelectDestination(item.destination),
              ),
              const SizedBox(height: 4),
            ],
            _NarrativeStudioNavigationItem(
              key: narrativeStudioProductNavigationMapsKey,
              icon: CupertinoIcons.map,
              label: 'Maps',
              selected: false,
              onTap: onOpenMaps,
            ),
            const SizedBox(height: 4),
            for (final item in _items.skip(2)) ...[
              _NarrativeStudioNavigationItem(
                key: ValueKey<String>(
                  'narrative-studio-product-nav-${item.destination.name}',
                ),
                icon: item.icon,
                label: item.label,
                selected: item.destination == selectedDestination,
                onTap: () => onSelectDestination(item.destination),
              ),
              const SizedBox(height: 4),
            ],
            if (status != null) ...[
              const Spacer(),
              SizedBox(
                key: narrativeStudioProductNavigationStatusKey,
                width: double.infinity,
                child: status,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NarrativeStudioNavigationItem extends StatelessWidget {
  const _NarrativeStudioNavigationItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PokeMapSidebarItem(
      icon: Icon(icon),
      label: label,
      compact: true,
      selected: selected,
      onTap: onTap,
    );
  }
}

class _DestinationNavigationItem {
  const _DestinationNavigationItem({
    required this.destination,
    required this.icon,
    required this.label,
  });

  final NarrativeStudioDestination destination;
  final IconData icon;
  final String label;
}

const _items = <_DestinationNavigationItem>[
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.overview,
    icon: CupertinoIcons.house,
    label: 'Aperçu',
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.storylines,
    icon: CupertinoIcons.rectangle_grid_1x2,
    label: 'Storylines',
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.scenes,
    icon: CupertinoIcons.photo,
    label: 'Scènes',
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.events,
    icon: CupertinoIcons.bolt_horizontal_circle,
    label: 'Événements',
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.cinematics,
    icon: CupertinoIcons.film,
    label: 'Cinématiques',
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.dialogues,
    icon: CupertinoIcons.text_bubble,
    label: 'Dialogues',
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.facts,
    icon: CupertinoIcons.doc_text,
    label: 'Facts',
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.worldRules,
    icon: CupertinoIcons.checkmark_shield,
    label: 'Règles du monde',
  ),
];
```

### `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart`

```dart
import 'package:flutter/cupertino.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import 'narrative_studio_destination.dart';
import 'narrative_studio_product_navigation.dart';

const narrativeStudioProductShellKey =
    ValueKey<String>('narrative-studio-product-shell');
const narrativeStudioProductShellHeaderKey =
    ValueKey<String>('narrative-studio-product-shell-header');
const narrativeStudioProductShellProjectKey =
    ValueKey<String>('narrative-studio-product-shell-project');
const narrativeStudioProductShellNavigationKey =
    ValueKey<String>('narrative-studio-product-shell-navigation');
const narrativeStudioProductShellWorkspaceKey =
    ValueKey<String>('narrative-studio-product-shell-workspace');

/// Shared outer product chrome for Narrative Studio.
///
/// The shell owns geometry only: product header, optional project/status slots,
/// navigation and the workspace slot. It deliberately contains no business
/// provider, service or workspace-specific grid.
class NarrativeStudioProductShell extends StatelessWidget {
  const NarrativeStudioProductShell({
    super.key,
    required this.selectedDestination,
    required this.onSelectDestination,
    required this.onOpenMaps,
    required this.workspace,
    this.project,
    this.status,
    this.appMark,
  });

  final NarrativeStudioDestination selectedDestination;
  final ValueChanged<NarrativeStudioDestination> onSelectDestination;
  final VoidCallback onOpenMaps;
  final Widget workspace;
  final Widget? project;
  final Widget? status;
  final Widget? appMark;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final navigationWidth = _navigationWidth(constraints.maxWidth);
        return Semantics(
          key: narrativeStudioProductShellKey,
          container: true,
          label: 'PokeMap, Narrative Studio',
          child: ColoredBox(
            color: colors.chromeBackground,
            child: Column(
              children: [
                _NarrativeStudioProductHeader(appMark: appMark),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: navigationWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (project != null)
                              SizedBox(
                                key: narrativeStudioProductShellProjectKey,
                                height: 52,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 8, 0, 8),
                                  child: project,
                                ),
                              ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
                                child: NarrativeStudioProductNavigation(
                                  key: narrativeStudioProductShellNavigationKey,
                                  selectedDestination: selectedDestination,
                                  onSelectDestination: onSelectDestination,
                                  onOpenMaps: onOpenMaps,
                                  status: status,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8, bottom: 8),
                          child: SizedBox.expand(
                            key: narrativeStudioProductShellWorkspaceKey,
                            child: workspace,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NarrativeStudioProductHeader extends StatelessWidget {
  const _NarrativeStudioProductHeader({required this.appMark});

  final Widget? appMark;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return SizedBox(
      key: narrativeStudioProductShellHeaderKey,
      height: 50,
      child: PokeMapToolbarSurface(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: appMark ??
                  Image.asset(
                    'assets/branding/pokemap_event_builder_mark.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                  ),
            ),
            const SizedBox(width: 10),
            Text(
              'PokeMap',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 10),
            const PokeMapBadge(
              label: 'beta',
              variant: PokeMapBadgeVariant.info,
            ),
          ],
        ),
      ),
    );
  }
}

double _navigationWidth(double viewportWidth) {
  if (viewportWidth >= 1672) return 191;
  if (viewportWidth >= 1480) return 176;
  if (viewportWidth >= 1100) return 168;
  return 148;
}
```

### `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart`

```dart
import 'package:flutter/cupertino.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import 'narrative_studio_route_presentation.dart';

const narrativeStudioWorkspaceContextKey =
    ValueKey<String>('narrative-studio-workspace-context');

/// Shared inner page frame for one Narrative Studio workspace.
///
/// Workspaces own the real breadcrumb detail, real actions and business body.
/// This widget only aligns those elements with the shared product shell.
class NarrativeStudioWorkspacePage extends StatelessWidget {
  const NarrativeStudioWorkspacePage({
    super.key,
    required this.presentation,
    required this.body,
    this.actions = const [],
    this.leading,
  });

  final NarrativeStudioRoutePresentation presentation;
  final Widget body;
  final List<Widget> actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final breadcrumb = <String>[
      'Narrative Studio',
      ...presentation.breadcrumbLabels,
    ].join('  /  ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          key: narrativeStudioWorkspaceContextKey,
          height: 52,
          child: PokeMapToolbarSurface(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                leading ??
                    Icon(
                      CupertinoIcons.house,
                      size: 14,
                      color: colors.textMuted,
                    ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    breadcrumb,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.brandPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (var index = 0; index < actions.length; index++) ...[
                  if (index > 0) const SizedBox(width: 8),
                  actions[index],
                ],
              ],
            ),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}
```

### `packages/map_editor/test/support/narrative_studio_capture_fonts.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

const narrativeStudioCaptureFontAsset =
    'assets/fonts/pokemap_capture_sans_regular.ttf';

final Set<String> _loadedTextFamilies = <String>{};
bool _cupertinoIconsLoaded = false;
bool _materialIconsLoaded = false;

/// Loads the repository-versioned capture font and bundled framework icons.
///
/// Golden tests may register the same text bytes under the family names used
/// by their existing themes. This keeps the pixels deterministic without
/// depending on host fonts or Flutter's internal cache layout.
Future<void> loadNarrativeStudioCaptureFonts({
  required Iterable<String> textFamilies,
}) async {
  final pendingTextFamilies = textFamilies
      .where((family) => family.trim().isNotEmpty)
      .where((family) => !_loadedTextFamilies.contains(family))
      .toSet();
  if (pendingTextFamilies.isNotEmpty) {
    final textFontBytes = await rootBundle.load(
      narrativeStudioCaptureFontAsset,
    );
    for (final family in pendingTextFamilies) {
      final loader = FontLoader(family)
        ..addFont(Future<ByteData>.value(textFontBytes));
      await loader.load();
      _loadedTextFamilies.add(family);
    }
  }

  if (!_cupertinoIconsLoaded) {
    final iconFontBytes = await rootBundle.load(
      'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    );
    final effectiveIconFamily = const TextStyle(
      fontFamily: CupertinoIcons.iconFont,
      package: CupertinoIcons.iconFontPackage,
    ).fontFamily!;
    final loader = FontLoader(effectiveIconFamily)
      ..addFont(Future<ByteData>.value(iconFontBytes));
    await loader.load();
    _cupertinoIconsLoaded = true;
  }

  if (!_materialIconsLoaded) {
    final iconFontBytes = await rootBundle.load(
      'fonts/MaterialIcons-Regular.otf',
    );
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future<ByteData>.value(iconFontBytes));
    await loader.load();
    _materialIconsLoaded = true;
  }
}
```

### `packages/map_editor/test/support/narrative_studio_visual_harness.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import '../shell_chrome_test_harness.dart';

const narrativeStudioRealRouteModes = <EditorWorkspaceMode>[
  EditorWorkspaceMode.narrativeOverview,
  EditorWorkspaceMode.globalStory,
  EditorWorkspaceMode.step,
  EditorWorkspaceMode.scenes,
  EditorWorkspaceMode.events,
  EditorWorkspaceMode.cutscene,
  EditorWorkspaceMode.dialogue,
  EditorWorkspaceMode.facts,
  EditorWorkspaceMode.worldRules,
];

ProjectManifest buildNarrativeStudioVisualProject({
  EventSystemMode eventSystemMode = EventSystemMode.legacyOnly,
}) {
  return ProjectManifest(
    name: 'Narrative visual contract',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map_contract',
        name: 'Contract Map',
        relativePath: 'maps/contract.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: eventSystemMode,
      records: const <NarrativeEventRecord>[],
      legacyClaims: const <LegacySourceClaim>[],
    ),
  );
}

const narrativeStudioVisualMap = MapData(
  id: 'map_contract',
  name: 'Contract Map',
  size: GridSize(width: 12, height: 10),
);

Future<ProviderContainer> pumpNarrativeStudioRealRoute(
  WidgetTester tester, {
  required EditorWorkspaceMode mode,
  required ProjectManifest? project,
  String? projectRootPath,
  MapData? activeMap,
  Size surfaceSize = const Size(1672, 941),
  bool isProjectDirty = false,
}) {
  return pumpEditorShellPage(
    tester,
    initialState: EditorState(
      projectRootPath: projectRootPath,
      project: project,
      activeMap: activeMap,
      workspaceMode: mode,
      isProjectDirty: isProjectDirty,
    ),
    surfaceSize: surfaceSize,
  );
}
```

### `packages/map_editor/assets/fonts/pokemap_capture_sans_LICENSE.txt`

```text

                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS

   APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

   Copyright [yyyy] [name of copyright owner]

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
```

### `packages/map_editor/test/ui/canvas/narrative_studio_destination_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/models/editor_workspace_mode.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_destination.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_route_presentation.dart';

void main() {
  group('Narrative Studio route presentation', () {
    test('maps every narrative workspace to the canonical destination', () {
      const expected = <EditorWorkspaceMode, NarrativeStudioDestination>{
        EditorWorkspaceMode.narrativeOverview:
            NarrativeStudioDestination.overview,
        EditorWorkspaceMode.globalStory: NarrativeStudioDestination.storylines,
        EditorWorkspaceMode.step: NarrativeStudioDestination.storylines,
        EditorWorkspaceMode.scenes: NarrativeStudioDestination.scenes,
        EditorWorkspaceMode.events: NarrativeStudioDestination.events,
        EditorWorkspaceMode.cutscene: NarrativeStudioDestination.cinematics,
        EditorWorkspaceMode.dialogue: NarrativeStudioDestination.dialogues,
        EditorWorkspaceMode.facts: NarrativeStudioDestination.facts,
        EditorWorkspaceMode.worldRules: NarrativeStudioDestination.worldRules,
      };

      for (final entry in expected.entries) {
        expect(
          narrativeStudioRoutePresentationFor(entry.key)?.destination,
          entry.value,
          reason: '${entry.key} must select ${entry.value}',
        );
      }
    });

    test('step remains a child breadcrumb of Storylines', () {
      final storyline = narrativeStudioRoutePresentationFor(
        EditorWorkspaceMode.globalStory,
      );
      final step = narrativeStudioRoutePresentationFor(
        EditorWorkspaceMode.step,
      );

      expect(storyline?.breadcrumbLabels, const ['Storylines']);
      expect(step?.breadcrumbLabels, const ['Storylines', 'Étape']);
      expect(step?.destination, NarrativeStudioDestination.storylines);
    });

    test('uses the canonical French labels for localized destinations', () {
      expect(
        narrativeStudioRoutePresentationFor(EditorWorkspaceMode.scenes)?.label,
        'Scènes',
      );
      expect(
        narrativeStudioRoutePresentationFor(EditorWorkspaceMode.worldRules)
            ?.label,
        'Règles du monde',
      );
    });

    test('maps and validator cannot become selected destinations', () {
      expect(
        NarrativeStudioDestination.values,
        const [
          NarrativeStudioDestination.overview,
          NarrativeStudioDestination.storylines,
          NarrativeStudioDestination.scenes,
          NarrativeStudioDestination.events,
          NarrativeStudioDestination.cinematics,
          NarrativeStudioDestination.dialogues,
          NarrativeStudioDestination.facts,
          NarrativeStudioDestination.worldRules,
        ],
      );
      expect(
        narrativeStudioRoutePresentationFor(EditorWorkspaceMode.map),
        isNull,
      );
      expect(
        narrativeStudioRoutePresentationFor(EditorWorkspaceMode.tileset),
        isNull,
      );
    });
  });
}
```

### `packages/map_editor/test/ui/canvas/narrative_studio_shell_policy_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/models/editor_workspace_mode.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_shell_policy.dart';

void main() {
  group('NarrativeStudioShellPolicy', () {
    test('enables the product shell for every Event system mode', () {
      expect(
        NarrativeStudioShellPolicy.shouldUseProductShell(
          workspaceMode: EditorWorkspaceMode.events,
          eventSystemMode: EventSystemMode.legacyOnly,
        ),
        isTrue,
      );
      expect(
        NarrativeStudioShellPolicy.shouldUseProductShell(
          workspaceMode: EditorWorkspaceMode.events,
          eventSystemMode: EventSystemMode.dualRead,
        ),
        isTrue,
      );
      expect(
        NarrativeStudioShellPolicy.shouldUseProductShell(
          workspaceMode: EditorWorkspaceMode.events,
          eventSystemMode: EventSystemMode.v2Only,
        ),
        isTrue,
      );
    });

    test('enables the product shell for the migrated Scenes route', () {
      for (final eventSystemMode in EventSystemMode.values) {
        expect(
          NarrativeStudioShellPolicy.shouldUseProductShell(
            workspaceMode: EditorWorkspaceMode.scenes,
            eventSystemMode: eventSystemMode,
          ),
          isTrue,
          reason: 'Scenes does not depend on $eventSystemMode',
        );
      }
    });

    test(
      'enables Storylines and its nested Step route atomically',
      () {
        for (final workspaceMode in <EditorWorkspaceMode>[
          EditorWorkspaceMode.globalStory,
          EditorWorkspaceMode.step,
        ]) {
          for (final eventSystemMode in EventSystemMode.values) {
            expect(
              NarrativeStudioShellPolicy.shouldUseProductShell(
                workspaceMode: workspaceMode,
                eventSystemMode: eventSystemMode,
              ),
              isTrue,
              reason: '$workspaceMode does not depend on $eventSystemMode',
            );
          }
        }
      },
    );

    test('enables the product shell for the complete Cinematics route', () {
      for (final eventSystemMode in EventSystemMode.values) {
        expect(
          NarrativeStudioShellPolicy.shouldUseProductShell(
            workspaceMode: EditorWorkspaceMode.cutscene,
            eventSystemMode: eventSystemMode,
          ),
          isTrue,
          reason: 'Cinematics does not depend on $eventSystemMode',
        );
      }
    });

    test(
      'enables Overview, Dialogues, Facts and World Rules atomically',
      () {
        for (final workspaceMode in <EditorWorkspaceMode>[
          EditorWorkspaceMode.narrativeOverview,
          EditorWorkspaceMode.dialogue,
          EditorWorkspaceMode.facts,
          EditorWorkspaceMode.worldRules,
        ]) {
          for (final eventSystemMode in EventSystemMode.values) {
            expect(
              NarrativeStudioShellPolicy.shouldUseProductShell(
                workspaceMode: workspaceMode,
                eventSystemMode: eventSystemMode,
              ),
              isTrue,
              reason: '$workspaceMode does not depend on $eventSystemMode',
            );
          }
        }
      },
    );

    test('keeps every other editor route outside the product shell', () {
      for (final workspaceMode in EditorWorkspaceMode.values) {
        if (workspaceMode == EditorWorkspaceMode.events ||
            workspaceMode == EditorWorkspaceMode.scenes ||
            workspaceMode == EditorWorkspaceMode.globalStory ||
            workspaceMode == EditorWorkspaceMode.step ||
            workspaceMode == EditorWorkspaceMode.cutscene ||
            workspaceMode == EditorWorkspaceMode.dialogue ||
            workspaceMode == EditorWorkspaceMode.facts ||
            workspaceMode == EditorWorkspaceMode.worldRules ||
            workspaceMode == EditorWorkspaceMode.narrativeOverview) {
          continue;
        }

        expect(
          NarrativeStudioShellPolicy.shouldUseProductShell(
            workspaceMode: workspaceMode,
            eventSystemMode: EventSystemMode.v2Only,
          ),
          isFalse,
          reason: '$workspaceMode is not a Narrative Studio destination',
        );
      }
    });
  });
}
```

### `packages/map_editor/test/ui/canvas/narrative_studio_shell_contract_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_destination.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_navigation.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_route_presentation.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets(
      'composes real slots and forwards navigation and action callbacks',
      (tester) async {
    final opened = <NarrativeStudioDestination>[];
    var mapsOpenCount = 0;
    var actionCount = 0;

    await _pumpShell(
      tester,
      selectedDestination: NarrativeStudioDestination.events,
      onSelectDestination: opened.add,
      onOpenMaps: () => mapsOpenCount += 1,
      project: const PokeMapCard(child: Text('Selbrume Demo')),
      status: const Text('Tous les changements enregistrés'),
      workspace: NarrativeStudioWorkspacePage(
        presentation: const NarrativeStudioRoutePresentation(
          destination: NarrativeStudioDestination.events,
          label: 'Event Builder',
          breadcrumbLabels: ['Événements'],
        ),
        actions: [
          PokeMapButton(
            key: const ValueKey('narrative-studio-contract-action'),
            onPressed: () => actionCount += 1,
            size: PokeMapButtonSize.compact,
            child: const Text('Nouvel événement'),
          ),
        ],
        body: const Text('Event workspace'),
      ),
    );

    for (final key in <ValueKey<String>>[
      narrativeStudioProductShellKey,
      narrativeStudioProductShellHeaderKey,
      narrativeStudioProductShellProjectKey,
      narrativeStudioProductShellNavigationKey,
      narrativeStudioProductShellWorkspaceKey,
      narrativeStudioWorkspaceContextKey,
    ]) {
      expect(find.byKey(key), findsOneWidget);
    }
    expect(find.text('Narrative Studio  /  Événements'), findsOneWidget);
    expect(find.text('Event workspace'), findsOneWidget);
    expect(find.text('Validateur'), findsNothing);
    final defaultMark = tester.widget<Image>(
      find.descendant(
        of: find.byKey(narrativeStudioProductShellHeaderKey),
        matching: find.byType(Image),
      ),
    );
    expect(
      (defaultMark.image as AssetImage).assetName,
      'assets/branding/pokemap_event_builder_mark.png',
    );
    final storylinesTop = tester.getTopLeft(
      find.byKey(
        const ValueKey('narrative-studio-product-nav-storylines'),
      ),
    );
    final mapsTop = tester.getTopLeft(
      find.byKey(narrativeStudioProductNavigationMapsKey),
    );
    final scenesTop = tester.getTopLeft(
      find.byKey(const ValueKey('narrative-studio-product-nav-scenes')),
    );
    expect(storylinesTop.dy, lessThan(mapsTop.dy));
    expect(mapsTop.dy, lessThan(scenesTop.dy));

    await tester.tap(
      find.byKey(const ValueKey('narrative-studio-product-nav-overview')),
    );
    await tester.tap(
      find.byKey(narrativeStudioProductNavigationMapsKey),
    );
    await tester.tap(
      find.byKey(const ValueKey('narrative-studio-contract-action')),
    );
    await tester.pump();

    expect(opened, const [NarrativeStudioDestination.overview]);
    expect(mapsOpenCount, 1);
    expect(actionCount, 1);
  });

  testWidgets('omits optional project and status slots without reserved space',
      (tester) async {
    await _pumpShell(
      tester,
      selectedDestination: NarrativeStudioDestination.overview,
    );

    final navigationWithoutProject = tester.getTopLeft(
      find.byKey(narrativeStudioProductShellNavigationKey),
    );
    expect(find.byKey(narrativeStudioProductShellProjectKey), findsNothing);
    expect(find.byKey(narrativeStudioProductNavigationStatusKey), findsNothing);

    await _pumpShell(
      tester,
      selectedDestination: NarrativeStudioDestination.overview,
      project: const PokeMapCard(child: Text('Projet')),
    );

    final navigationWithProject = tester.getTopLeft(
      find.byKey(narrativeStudioProductShellNavigationKey),
    );
    expect(find.byKey(narrativeStudioProductShellProjectKey), findsOneWidget);
    expect(
      navigationWithProject.dy - navigationWithoutProject.dy,
      moreOrLessEquals(52),
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required NarrativeStudioDestination selectedDestination,
  ValueChanged<NarrativeStudioDestination>? onSelectDestination,
  VoidCallback? onOpenMaps,
  Widget? project,
  Widget? status,
  Widget? workspace,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 941);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: NarrativeStudioProductShell(
          selectedDestination: selectedDestination,
          onSelectDestination: onSelectDestination ?? (_) {},
          onOpenMaps: onOpenMaps ?? () {},
          project: project,
          status: status,
          workspace: workspace ??
              const NarrativeStudioWorkspacePage(
                presentation: NarrativeStudioRoutePresentation(
                  destination: NarrativeStudioDestination.overview,
                  label: 'Aperçu',
                  breadcrumbLabels: ['Aperçu'],
                ),
                body: Text('Overview workspace'),
              ),
        ),
      ),
    ),
  );
  await tester.pump();
}
```

### `packages/map_editor/test/ui/canvas/narrative_studio_responsive_accessibility_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_destination.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_navigation.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_route_presentation.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('desktop tiers and text scales render without overflow',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const widths = <double>[
      1920,
      1672,
      1480,
      1440,
      1366,
      1280,
      1100,
      1099,
    ];
    const textScales = <double>[1, 1.25, 1.5];

    for (final width in widths) {
      for (final textScale in textScales) {
        await _pumpResponsiveShell(
          tester,
          width: width,
          textScale: textScale,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'overflow at ${width}px / ${textScale * 100}%',
        );
      }
    }

    await _pumpResponsiveShell(
      tester,
      width: 1672,
      textScale: 1,
      devicePixelRatio: 2,
    );
    expect(
      tester.takeException(),
      isNull,
      reason: 'overflow at 1672px / DPR 2',
    );
  });

  testWidgets('announces selection, keeps Maps unselected and supports focus',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final opened = <NarrativeStudioDestination>[];
    var mapsOpenCount = 0;
    final semantics = tester.ensureSemantics();

    await _pumpResponsiveShell(
      tester,
      width: 1099,
      textScale: 1.5,
      onSelectDestination: opened.add,
      onOpenMaps: () => mapsOpenCount += 1,
    );

    final selectedSemantics = find.descendant(
      of: find.byKey(
        const ValueKey('narrative-studio-product-nav-events'),
      ),
      matching: find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.selected == true,
      ),
    );
    final mapsSelectedSemantics = find.descendant(
      of: find.byKey(narrativeStudioProductNavigationMapsKey),
      matching: find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.selected == true,
      ),
    );
    expect(selectedSemantics, findsOneWidget);
    expect(mapsSelectedSemantics, findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('narrative-studio-disabled-action')),
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.enabled == false,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey('narrative-studio-icon-action'),
        ),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Plus d’options',
        ),
      ),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.text('Tous les changements enregistrés')).label,
      contains('Tous les changements enregistrés'),
    );

    FocusManager.instance.primaryFocus?.unfocus();
    final navigation = find.byKey(narrativeStudioProductShellNavigationKey);
    var focusIsInsideNavigation = false;
    for (var attempt = 0; attempt < 12; attempt++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      focusIsInsideNavigation = _primaryFocusIsInside(navigation);
      if (focusIsInsideNavigation) break;
    }
    expect(focusIsInsideNavigation, isTrue);
    final firstNavigationFocus = FocusManager.instance.primaryFocus;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, isNot(firstNavigationFocus));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, same(firstNavigationFocus));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(opened, isNotEmpty);

    await tester.tap(find.byKey(narrativeStudioProductNavigationMapsKey));
    await tester.pump();
    expect(mapsOpenCount, 1);
    semantics.dispose();
  });
}

Future<void> _pumpResponsiveShell(
  WidgetTester tester, {
  required double width,
  required double textScale,
  double devicePixelRatio = 1,
  ValueChanged<NarrativeStudioDestination>? onSelectDestination,
  VoidCallback? onOpenMaps,
}) async {
  tester.view.devicePixelRatio = devicePixelRatio;
  tester.view.physicalSize = Size(
    width * devicePixelRatio,
    941 * devicePixelRatio,
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: NarrativeStudioProductShell(
          selectedDestination: NarrativeStudioDestination.events,
          onSelectDestination: onSelectDestination ?? (_) {},
          onOpenMaps: onOpenMaps ?? () {},
          project: const PokeMapCard(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(CupertinoIcons.folder, size: 14),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selbrume Demo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          status: const Text(
            'Tous les changements enregistrés',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          workspace: NarrativeStudioWorkspacePage(
            presentation: const NarrativeStudioRoutePresentation(
              destination: NarrativeStudioDestination.events,
              label: 'Event Builder',
              breadcrumbLabels: ['Événements'],
            ),
            actions: [
              PokeMapIconButton(
                key: const ValueKey('narrative-studio-icon-action'),
                onPressed: () {},
                tooltip: 'Plus d’options',
                icon: const Icon(CupertinoIcons.ellipsis),
              ),
              const PokeMapButton(
                key: ValueKey('narrative-studio-disabled-action'),
                onPressed: null,
                size: PokeMapButtonSize.compact,
                variant: PokeMapButtonVariant.secondary,
                child: Text('Action indisponible'),
              ),
            ],
            body: const Center(child: Text('Event workspace')),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

bool _primaryFocusIsInside(Finder finder) {
  final target = finder.evaluate().single;
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext == null) return false;

  var current = focusContext as Element?;
  while (current != null) {
    if (identical(current, target)) return true;
    Element? parent;
    current.visitAncestorElements((ancestor) {
      parent = ancestor;
      return false;
    });
    current = parent;
  }
  return false;
}
```

### `packages/map_editor/test/ui/canvas/narrative_studio_visual_contract_test.dart`

```dart
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_navigation.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';

import '../../support/narrative_studio_visual_harness.dart';

void main() {
  late Directory projectRoot;

  setUp(() async {
    projectRoot = await Directory.systemTemp.createTemp(
      'map_editor_narrative_visual_contract_',
    );
  });

  tearDown(() async {
    if (await projectRoot.exists()) {
      await projectRoot.delete(recursive: true);
    }
  });

  for (final mode in narrativeStudioRealRouteModes) {
    testWidgets(
      '${mode.name} real route owns one product shell, rail and context bar',
      (tester) async {
        final project = buildNarrativeStudioVisualProject();
        final before = project.toJson();
        final container = await pumpNarrativeStudioRealRoute(
          tester,
          mode: mode,
          project: project,
          projectRootPath: projectRoot.path,
          activeMap: narrativeStudioVisualMap,
          isProjectDirty: true,
        );

        expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
        expect(find.byType(NarrativeStudioProductNavigation), findsOneWidget);
        expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
        expect(find.byType(ProjectExplorerPanel), findsNothing);
        expect(find.text('PokeMap'), findsOneWidget);
        expect(find.text('Validateur'), findsNothing);
        expect(
          container.read(editorNotifierProvider).project?.toJson(),
          before,
        );
        expect(
          container.read(editorNotifierProvider).activeMap,
          narrativeStudioVisualMap,
        );
        expect(container.read(editorNotifierProvider).isProjectDirty, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final mode in narrativeStudioRealRouteModes) {
    testWidgets(
      '${mode.name} no-project route keeps one honest workspace context',
      (tester) async {
        await pumpNarrativeStudioRealRoute(
          tester,
          mode: mode,
          project: null,
          surfaceSize: const Size(1280, 768),
        );

        expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
        expect(find.byType(NarrativeStudioProductNavigation), findsOneWidget);
        expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
        expect(find.text('Aucun projet chargé'), findsOneWidget);
        expect(find.byType(ProjectExplorerPanel), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
```

### `packages/map_editor/test/ui/canvas/narrative_studio_specialized_routes_test.dart`

```dart
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/dialogue_studio_workspace.dart';
import 'package:map_editor/src/ui/canvas/facts_world_rules/facts_world_rules_workspace.dart';
import 'package:map_editor/src/ui/canvas/narrative_overview_workspace.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart';
import 'package:map_editor/src/ui/editor_shell_page.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';

import '../../shell_chrome_test_harness.dart';
import '../../support/narrative_studio_capture_fonts.dart';

const _specializedRoutesCaptureFontFamily =
    'NarrativeStudioSpecializedRoutesArial';

void main() {
  late Directory projectRoot;

  setUp(() async {
    projectRoot = await Directory.systemTemp.createTemp(
      'map_editor_specialized_routes_',
    );
  });

  tearDown(() async {
    if (await projectRoot.exists()) {
      await projectRoot.delete(recursive: true);
    }
  });

  final routeCases = <({
    EditorWorkspaceMode mode,
    Type workspaceType,
    String breadcrumb,
  })>[
    (
      mode: EditorWorkspaceMode.narrativeOverview,
      workspaceType: NarrativeOverviewWorkspace,
      breadcrumb: 'Narrative Studio  /  Aperçu',
    ),
    (
      mode: EditorWorkspaceMode.dialogue,
      workspaceType: DialogueStudioWorkspace,
      breadcrumb: 'Narrative Studio  /  Dialogues',
    ),
    (
      mode: EditorWorkspaceMode.facts,
      workspaceType: FactsWorldRulesWorkspace,
      breadcrumb: 'Narrative Studio  /  Facts',
    ),
    (
      mode: EditorWorkspaceMode.worldRules,
      workspaceType: FactsWorldRulesWorkspace,
      breadcrumb: 'Narrative Studio  /  Règles du monde',
    ),
  ];

  for (final routeCase in routeCases) {
    testWidgets(
      '${routeCase.mode.name} full route owns exactly one shared product shell and context',
      (tester) async {
        final project = _project();
        final activeMap = _map();
        final container = await pumpEditorShellPage(
          tester,
          initialState: EditorState(
            projectRootPath: projectRoot.path,
            project: project,
            activeMap: activeMap,
            workspaceMode: routeCase.mode,
            isProjectDirty: true,
          ),
          surfaceSize: const Size(1672, 941),
        );

        expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
        expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
        expect(find.byType(routeCase.workspaceType), findsOneWidget);
        expect(find.byType(ProjectExplorerPanel), findsNothing);
        expect(find.text(routeCase.breadcrumb), findsOneWidget);
        expect(find.text('Modifications non enregistrées'), findsOneWidget);
        expect(container.read(editorNotifierProvider).project, project);
        expect(container.read(editorNotifierProvider).activeMap, activeMap);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'product navigation switches Overview, Dialogues, Facts and World Rules without mutating project or map',
    (tester) async {
      final project = _project();
      final activeMap = _map();
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: projectRoot.path,
          project: project,
          activeMap: activeMap,
          workspaceMode: EditorWorkspaceMode.narrativeOverview,
          isProjectDirty: true,
        ),
        surfaceSize: const Size(1672, 941),
      );

      for (final destination in <({String key, EditorWorkspaceMode mode})>[
        (
          key: 'narrative-studio-product-nav-dialogues',
          mode: EditorWorkspaceMode.dialogue,
        ),
        (
          key: 'narrative-studio-product-nav-facts',
          mode: EditorWorkspaceMode.facts,
        ),
        (
          key: 'narrative-studio-product-nav-worldRules',
          mode: EditorWorkspaceMode.worldRules,
        ),
        (
          key: 'narrative-studio-product-nav-overview',
          mode: EditorWorkspaceMode.narrativeOverview,
        ),
      ]) {
        await tester.tap(find.byKey(ValueKey<String>(destination.key)));
        await tester.pumpAndSettle();

        final state = container.read(editorNotifierProvider);
        expect(state.workspaceMode, destination.mode);
        expect(state.project, project);
        expect(state.activeMap, activeMap);
        expect(state.isProjectDirty, isTrue);
        expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
        expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
        expect(find.byType(ProjectExplorerPanel), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );

  for (final mode in <EditorWorkspaceMode>[
    EditorWorkspaceMode.narrativeOverview,
    EditorWorkspaceMode.dialogue,
    EditorWorkspaceMode.facts,
    EditorWorkspaceMode.worldRules,
  ]) {
    testWidgets(
      '${mode.name} keeps its shared context when no project is loaded',
      (tester) async {
        await pumpEditorShellPage(
          tester,
          initialState: EditorState(workspaceMode: mode),
          surfaceSize: const Size(1280, 768),
        );

        expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
        expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
        expect(find.byType(ProjectExplorerPanel), findsNothing);
        expect(find.text('Aucun projet chargé'), findsOneWidget);
        if (mode == EditorWorkspaceMode.narrativeOverview) {
          expect(
            find.byKey(
              const ValueKey('narrative-overview-project-unavailable'),
            ),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  const responsiveSizes = <Size>[
    Size(1280, 768),
    Size(1366, 768),
    Size(1440, 900),
    Size(1672, 941),
    Size(1920, 941),
  ];
  const responsiveTextScales = <double>[1, 1.25, 1.5];

  for (final routeCase in routeCases) {
    for (final size in responsiveSizes) {
      for (final textScale in responsiveTextScales) {
        testWidgets(
          '${routeCase.mode.name} is overflow-free at '
          '${size.width}x${size.height} and ${textScale * 100}% text',
          (tester) async {
            tester.platformDispatcher.textScaleFactorTestValue = textScale;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );

            await pumpEditorShellPage(
              tester,
              initialState: EditorState(
                projectRootPath: projectRoot.path,
                project: _project(),
                activeMap: _map(),
                workspaceMode: routeCase.mode,
              ),
              surfaceSize: size,
            );

            expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
            expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  for (final goldenCase in <({
    EditorWorkspaceMode mode,
    String routeName,
  })>[
    (
      mode: EditorWorkspaceMode.narrativeOverview,
      routeName: 'overview',
    ),
    (
      mode: EditorWorkspaceMode.dialogue,
      routeName: 'dialogues',
    ),
    (
      mode: EditorWorkspaceMode.facts,
      routeName: 'facts',
    ),
    (
      mode: EditorWorkspaceMode.worldRules,
      routeName: 'world_rules',
    ),
  ]) {
    testWidgets(
      'matches the full ${goldenCase.routeName} product route at 1672x941',
      (tester) async {
        await _loadSpecializedRoutesCaptureFonts();
        await pumpEditorShellPage(
          tester,
          initialState: EditorState(
            projectRootPath: projectRoot.path,
            project: _project(),
            activeMap: _map(),
            workspaceMode: goldenCase.mode,
          ),
          surfaceSize: const Size(1672, 941),
          fontFamily: _specializedRoutesCaptureFontFamily,
          cupertinoFontFamily: _specializedRoutesCaptureFontFamily,
        );
        await tester.pumpAndSettle();

        final output = File(
          'test/goldens/narrative_studio/${goldenCase.routeName}/'
          '${goldenCase.routeName}_full_product_route_1672x941.png',
        );
        output.parent.createSync(recursive: true);
        await expectLater(
          find.byType(EditorShellPage),
          matchesGoldenFile(output.absolute.path),
        );
      },
    );
  }
}

Future<void> _loadSpecializedRoutesCaptureFonts() async {
  await loadNarrativeStudioCaptureFonts(
    textFamilies: const <String>[_specializedRoutesCaptureFontFamily],
  );
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Specialized routes',
    maps: const [
      ProjectMapEntry(
        id: 'map_route',
        name: 'Route',
        relativePath: 'maps/route.json',
      ),
    ],
    tilesets: const [],
    facts: [
      NarrativeFactDefinition(id: 'fact_started', label: 'A commencé'),
    ],
  );
}

MapData _map() {
  return const MapData(
    id: 'map_route',
    name: 'Route',
    size: GridSize(width: 12, height: 10),
  );
}
```

### `packages/map_editor/test/ui/canvas/narrative_studio_workspace_visual_test.dart`

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/application/step_studio_authoring.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart';
import 'package:map_editor/src/ui/canvas/scenes_workspace.dart';
import 'package:map_editor/src/ui/canvas/step_studio_workspace.dart';
import 'package:map_editor/src/ui/canvas/storylines_workspace.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/editor_shell_page.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';

import '../../shell_chrome_test_harness.dart';
import '../../support/event_builder_v2_visual_harness.dart';
import '../../support/narrative_studio_capture_fonts.dart';

const _narrativeStudioArialCaptureFontFamily =
    'NarrativeStudioArialCaptureFont';

Future<void> _loadNarrativeStudioArialCaptureFonts() async {
  await loadNarrativeStudioCaptureFonts(
    textFamilies: const <String>[
      eventBuilderV2PhaseKCaptureFontFamily,
      _narrativeStudioArialCaptureFontFamily,
    ],
  );
}

void main() {
  testWidgets(
    'Storylines full route owns one product shell and one real create action',
    (tester) async {
      final project = _projectWithStorylinesAndStep();
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: project,
          workspaceMode: EditorWorkspaceMode.globalStory,
        ),
        surfaceSize: const Size(1672, 941),
      );

      expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
      expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
      expect(find.byType(StorylinesWorkspace), findsOneWidget);
      expect(find.byType(ProjectExplorerPanel), findsNothing);
      expect(find.text('Narrative Studio  /  Storylines'), findsOneWidget);

      final createAction =
          find.byKey(const ValueKey('storylines-create-main-cta'));
      expect(
        find.descendant(
          of: find.byKey(narrativeStudioWorkspaceContextKey),
          matching: createAction,
        ),
        findsOneWidget,
      );
      expect(container.read(editorNotifierProvider).project, equals(project));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Step full route stays nested under the selected Storylines destination',
    (tester) async {
      final project = _projectWithStorylinesAndStep();
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: project,
          workspaceMode: EditorWorkspaceMode.step,
        ),
        surfaceSize: const Size(1672, 941),
      );

      expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
      expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
      expect(find.byType(StepStudioWorkspace), findsOneWidget);
      expect(find.byType(ProjectExplorerPanel), findsNothing);
      expect(
        find.text(
          'Narrative Studio  /  Storylines  /  Étape  /  Aller au port',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('narrative-studio-product-nav-storylines'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('narrative-studio-product-nav-step')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('step-studio-save-action')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('step-studio-reset-action')),
        findsOneWidget,
      );
      expect(container.read(editorNotifierProvider).project, equals(project));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Scenes full route owns one shared product shell and one workspace page',
    (tester) async {
      final project = _projectWithScene();
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: project,
          workspaceMode: EditorWorkspaceMode.scenes,
        ),
        surfaceSize: const Size(1672, 941),
      );

      expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
      expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
      expect(find.byType(ScenesWorkspace), findsOneWidget);
      expect(find.byType(ProjectExplorerPanel), findsNothing);
      expect(
        find.byKey(const ValueKey('scenes-create-scene-action')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('event-builder-v2-validate-project')),
        findsNothing,
      );
      expect(
        container.read(editorNotifierProvider).project,
        equals(project),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Scenes route action opens the existing draft flow without eager mutation',
    (tester) async {
      final project = _projectWithScene();
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: project,
          workspaceMode: EditorWorkspaceMode.scenes,
        ),
        surfaceSize: const Size(1440, 900),
      );

      final contextHeader = find.byKey(narrativeStudioWorkspaceContextKey);
      final createAction = find.byKey(
        const ValueKey('scenes-create-scene-action'),
      );
      expect(
        find.descendant(of: contextHeader, matching: createAction),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('scenes-tree-panel')),
          matching: createAction,
        ),
        findsNothing,
      );

      await tester.tap(createAction);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('scenes-create-scene-dialog')),
        findsOneWidget,
      );
      expect(container.read(editorNotifierProvider).project, equals(project));
    },
  );

  testWidgets(
    'compact Scenes opens its inspector side sheet and Escape restores focus',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(
        tester.platformDispatcher.clearTextScaleFactorTestValue,
      );
      final project = _projectWithScene();
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: project,
          workspaceMode: EditorWorkspaceMode.scenes,
        ),
        surfaceSize: const Size(1280, 768),
      );

      final launcher = find.byKey(
        const ValueKey('scenes-open-inspector-action'),
      );
      expect(
          find.byKey(const ValueKey('scenes-inspector-column')), findsNothing);
      expect(launcher, findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('scene-graph-node-node_end')));
      await tester.pump();
      await tester.tap(launcher);
      await tester.pumpAndSettle();

      final sheet = find.byType(PokeMapDesktopSideSheet);
      expect(sheet, findsOneWidget);
      expect(
        find.byKey(const ValueKey('scenes-inspector-sheet-content')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: sheet,
          matching: find.byKey(
            const ValueKey('scene-node-read-only-inspector'),
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('node_end'), findsWidgets);
      expect(_primaryFocusIsInside(sheet), isTrue);
      expect(container.read(editorNotifierProvider).project, equals(project));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(sheet, findsNothing);
      expect(_primaryFocusIsInside(launcher), isTrue);
      expect(container.read(editorNotifierProvider).project, equals(project));
    },
  );

  testWidgets(
    'compact Scenes inspector side sheet closes through navigator back',
    (tester) async {
      final project = _projectWithScene();
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: project,
          workspaceMode: EditorWorkspaceMode.scenes,
        ),
        surfaceSize: const Size(1366, 768),
      );

      final launcher = find.byKey(
        const ValueKey('scenes-open-inspector-action'),
      );
      await tester.tap(launcher);
      await tester.pumpAndSettle();
      expect(find.byType(PokeMapDesktopSideSheet), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(PokeMapDesktopSideSheet), findsNothing);
      expect(_primaryFocusIsInside(launcher), isTrue);
      expect(container.read(editorNotifierProvider).project, equals(project));
    },
  );

  testWidgets(
    'compact Scenes inspector sheet reacts to a real edge deletion',
    (tester) async {
      final project = _projectWithScene();
      final originalNodes = project.scenes.single.graph.nodes;
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: project,
          workspaceMode: EditorWorkspaceMode.scenes,
        ),
        surfaceSize: const Size(1280, 768),
      );

      await tester.tap(
        find.byKey(
          const ValueKey('scene-graph-edge-hit-target-edge_start_end'),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('scenes-open-inspector-action')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PokeMapDesktopSideSheet), findsOneWidget);
      expect(
        find.byKey(const ValueKey('scene-edge-read-only-inspector')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-edge-delete-action')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('scene-edge-delete-action')),
      );
      await tester.pumpAndSettle();

      final updatedScene =
          container.read(editorNotifierProvider).project!.scenes.single;
      expect(updatedScene.graph.edges, isEmpty);
      expect(updatedScene.graph.nodes, originalNodes);
      expect(find.byType(PokeMapDesktopSideSheet), findsOneWidget);
      expect(
        find.byKey(const ValueKey('scene-edge-delete-action')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('scene-edge-read-only-inspector')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('scene-node-read-only-inspector')),
        findsOneWidget,
      );
    },
  );

  for (final size in <Size>[
    const Size(1280, 768),
    const Size(1366, 768),
    const Size(1440, 900),
    const Size(1672, 941),
    const Size(1920, 941),
  ]) {
    for (final textScale in <double>[1, 1.25, 1.5]) {
      testWidgets(
        'Scenes full route has no overflow at ${size.width}x${size.height} '
        'and ${textScale * 100}% text',
        (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = textScale;
          addTearDown(
            tester.platformDispatcher.clearTextScaleFactorTestValue,
          );
          await pumpEditorShellPage(
            tester,
            initialState: EditorState(
              project: _projectWithScene(),
              workspaceMode: EditorWorkspaceMode.scenes,
            ),
            surfaceSize: size,
          );

          expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
          expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
          final compact = size.width <= 1366;
          final inspectorColumn = find.byKey(
            const ValueKey('scenes-inspector-column'),
          );
          final inspectorLauncher = find.byKey(
            const ValueKey('scenes-open-inspector-action'),
          );
          final graphSize = tester.getSize(
            find.byKey(const ValueKey('scenes-graph-column')),
          );
          if (compact) {
            expect(inspectorColumn, findsNothing);
            expect(inspectorLauncher, findsOneWidget);
            expect(graphSize.width, greaterThan(800));
          } else {
            expect(inspectorColumn, findsOneWidget);
            expect(inspectorLauncher, findsNothing);
            final inspectorSize = tester.getSize(inspectorColumn);
            expect(inspectorSize.width, closeTo(320, 0.1));
            expect(graphSize.width, greaterThan(inspectorSize.width));
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final workspaceMode in <EditorWorkspaceMode>[
    EditorWorkspaceMode.globalStory,
    EditorWorkspaceMode.step,
  ]) {
    for (final size in <Size>[
      const Size(1280, 768),
      const Size(1366, 768),
      const Size(1440, 900),
      const Size(1672, 941),
      const Size(1920, 941),
    ]) {
      for (final textScale in <double>[1, 1.25, 1.5]) {
        testWidgets(
          '$workspaceMode has one shell and no overflow at '
          '${size.width}x${size.height}, ${textScale * 100}% text',
          (tester) async {
            tester.platformDispatcher.textScaleFactorTestValue = textScale;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            await pumpEditorShellPage(
              tester,
              initialState: EditorState(
                project: _projectWithStorylinesAndStep(),
                workspaceMode: workspaceMode,
              ),
              surfaceSize: size,
            );

            expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
            expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
            expect(find.byType(ProjectExplorerPanel), findsNothing);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('matches the full Scenes product route at 1672x941',
      (tester) async {
    await loadEventBuilderV2PhaseKCaptureFonts();
    await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        project: _projectWithScene(),
        workspaceMode: EditorWorkspaceMode.scenes,
      ),
      surfaceSize: const Size(1672, 941),
      fontFamily: eventBuilderV2PhaseKCaptureFontFamily,
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();

    final output = File(
      'test/goldens/narrative_studio/scenes/'
      'scenes_full_product_route_1672x941.png',
    );
    output.parent.createSync(recursive: true);
    await expectLater(
      find.byType(EditorShellPage),
      matchesGoldenFile(output.absolute.path),
    );
  });

  for (final workspaceMode in <EditorWorkspaceMode>[
    EditorWorkspaceMode.globalStory,
    EditorWorkspaceMode.step,
  ]) {
    final routeName = workspaceMode == EditorWorkspaceMode.globalStory
        ? 'storylines'
        : 'step';
    testWidgets('matches the full $routeName product route at 1672x941',
        (tester) async {
      final isStep = workspaceMode == EditorWorkspaceMode.step;
      if (isStep) {
        await _loadNarrativeStudioArialCaptureFonts();
      } else {
        await loadEventBuilderV2PhaseKCaptureFonts();
      }
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: _projectWithStorylinesAndStep(),
          workspaceMode: workspaceMode,
        ),
        surfaceSize: const Size(1672, 941),
        fontFamily: isStep
            ? _narrativeStudioArialCaptureFontFamily
            : eventBuilderV2PhaseKCaptureFontFamily,
        cupertinoFontFamily:
            isStep ? _narrativeStudioArialCaptureFontFamily : null,
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      final output = File(
        'test/goldens/narrative_studio/$routeName/'
        '${routeName}_full_product_route_1672x941.png',
      );
      output.parent.createSync(recursive: true);
      await expectLater(
        find.byType(EditorShellPage),
        matchesGoldenFile(output.absolute.path),
      );
    });
  }
}

bool _primaryFocusIsInside(Finder finder) {
  final target = finder.evaluate().single;
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext == null) return false;

  var current = focusContext as Element?;
  while (current != null) {
    if (identical(current, target)) return true;
    Element? parent;
    current.visitAncestorElements((ancestor) {
      parent = ancestor;
      return false;
    });
    current = parent;
  }
  return false;
}

ProjectManifest _projectWithScene() {
  return ProjectManifest(
    name: 'Scenes convergence fixture',
    maps: [],
    tilesets: [],
    scenes: [
      SceneAsset(
        id: 'scene_intro',
        name: 'Introduction',
        graph: SceneGraph(
          startNodeId: 'node_start',
          nodes: [
            SceneNode(id: 'node_start', kind: SceneNodeKind.start),
            SceneNode(id: 'node_end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'edge_start_end',
              fromNodeId: 'node_start',
              fromPortId: 'completed',
              toNodeId: 'node_end',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
        layout: SceneGraphLayout(
          nodeLayouts: [
            SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
            SceneNodeLayout(nodeId: 'node_end', x: 320, y: 80),
          ],
        ),
      ),
    ],
  );
}

ProjectManifest _projectWithStorylinesAndStep() {
  const document = StepStudioDocument(
    globalStoryScenarioId: 'global_story',
    steps: <StepStudioStep>[
      StepStudioStep(
        id: 'step_port',
        name: 'Aller au port',
        description: 'Retrouver le rival sur le quai.',
        order: 0,
        activation: StepStudioActivationRule(
          mode: StepStudioActivationMode.atGameStart,
        ),
        completion: StepStudioCompletionRule(
          mode: StepStudioCompletionMode.manual,
        ),
      ),
      StepStudioStep(
        id: 'step_rival',
        name: 'Affronter le rival',
        description: 'Remporter le premier combat.',
        order: 1,
        activation: StepStudioActivationRule(
          mode: StepStudioActivationMode.afterPreviousStep,
        ),
        completion: StepStudioCompletionRule(
          mode: StepStudioCompletionMode.manual,
        ),
      ),
    ],
  );
  return ProjectManifest(
    name: 'Selbrume Narrative',
    maps: const [],
    tilesets: const [],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    storylines: [
      StorylineAsset(
        id: 'storyline_main',
        type: StorylineType.main,
        title: 'La brume de Selbrume',
        description: 'Le mystère du port et de son ancien phare.',
        chapters: [
          StorylineChapter(
            id: 'chapter_port',
            title: 'Le port',
            description: 'Premiers indices sur les quais.',
            order: 0,
            steps: [
              StorylineStep(
                id: 'story_step_arrival',
                title: 'Arrivée à Selbrume',
                order: 0,
              ),
              StorylineStep(
                id: 'story_step_rival',
                title: 'Rencontre au port',
                order: 1,
              ),
            ],
          ),
          StorylineChapter(
            id: 'chapter_marsh',
            title: 'Les marais',
            order: 1,
          ),
        ],
      ),
      StorylineAsset(
        id: 'storyline_sidequest',
        type: StorylineType.sideQuest,
        title: 'Le pêcheur inquiet',
        description: 'Une quête annexe du port.',
      ),
    ],
    scenarios: [
      ScenarioAsset(
        id: 'global_story',
        name: 'La brume de Selbrume',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
        metadata: {
          kStepStudioDocumentMetadataKey: document.toMetadataJson(),
        },
      ),
    ],
  );
}
```

### `packages/map_editor/test/ui/canvas/narrative_studio_cinematics_route_test.dart`

```dart
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_builder_workspace.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematics_library_workspace.dart';
import 'package:map_editor/src/ui/canvas/cutscene_studio_workspace.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_navigation.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart';
import 'package:map_editor/src/ui/editor_shell_page.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';

import '../../shell_chrome_test_harness.dart';
import '../../support/event_builder_v2_visual_harness.dart';

void main() {
  testWidgets(
    'Cinematics keeps one product shell and page through Library, Builder and legacy',
    (tester) async {
      final project = _cinematicsProject();
      final before = project.toJson();

      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: project,
          workspaceMode: EditorWorkspaceMode.cutscene,
        ),
        surfaceSize: const Size(1672, 941),
      );

      void expectSharedRoute() {
        expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
        expect(find.byType(NarrativeStudioProductNavigation), findsOneWidget);
        expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
        expect(find.byType(ProjectExplorerPanel), findsNothing);
        expect(
          find.byKey(
            const ValueKey<String>(
              'narrative-studio-product-nav-cinematics',
            ),
          ),
          findsOneWidget,
        );
      }

      expectSharedRoute();
      expect(find.byType(CinematicsLibraryWorkspace), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cinematics-library-workspace')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-entry-cinematic_intro')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('cinematics-library-open-builder-button')),
      );
      await tester.pumpAndSettle();

      expectSharedRoute();
      expect(find.byType(CinematicBuilderWorkspace), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Narrative Studio  /  Cinématiques  /  Intro cinématique',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-back-button')),
      );
      await tester.pumpAndSettle();

      expectSharedRoute();
      expect(find.byType(CinematicsLibraryWorkspace), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey('cinematics-library-open-legacy-button'),
        ),
      );
      await tester.pumpAndSettle();

      expectSharedRoute();
      expect(find.byType(CutsceneStudioWorkspace), findsOneWidget);
      expect(find.text('Narrative Studio  ›  Step  ›  Cutscene'), findsNothing);
      for (final action in <String>[
        'Sauvegarder',
        'Réinitialiser',
        'Nouvelle cutscene',
      ]) {
        expect(find.text(action), findsOneWidget);
      }
      expect(find.text('Tester'), findsNothing);
      expect(find.text('Simuler'), findsNothing);
      expect(
        find.text('Narrative Studio  /  Cinématiques  /  Ancien studio'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('cinematics-library-back-button')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematics-library-back-button')),
      );
      await tester.pumpAndSettle();

      expectSharedRoute();
      expect(find.byType(CinematicsLibraryWorkspace), findsOneWidget);
      expect(project.toJson(), before);
    },
  );

  testWidgets('Cinematics project-absent state still owns one shared page', (
    tester,
  ) async {
    await pumpEditorShellPage(
      tester,
      initialState: const EditorState(
        workspaceMode: EditorWorkspaceMode.cutscene,
      ),
      surfaceSize: const Size(1280, 768),
    );

    expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
    expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
    expect(find.byType(ProjectExplorerPanel), findsNothing);
    expect(find.text('Aucun projet chargé'), findsOneWidget);
    expect(
      find.text(
        'Chargez un projet pour ouvrir la bibliothèque et les outils cinématiques.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Cinematics shared route is responsive at supported widths', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.25;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final size in <Size>[
      const Size(1280, 768),
      const Size(1366, 768),
      const Size(1440, 900),
      const Size(1672, 941),
      const Size(1920, 941),
    ]) {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: _cinematicsProject(),
          workspaceMode: EditorWorkspaceMode.cutscene,
        ),
        surfaceSize: size,
      );

      expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
      expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Library viewport: $size');

      await tester.tap(
        find.byKey(const ValueKey('cinematic-entry-cinematic_intro')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('cinematics-library-open-builder-button')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CinematicBuilderWorkspace), findsOneWidget);
      expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Builder viewport: $size');

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-back-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('cinematics-library-open-legacy-button'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CutsceneStudioWorkspace), findsOneWidget);
      expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Legacy viewport: $size');

      await tester.tap(
        find.byKey(const ValueKey('cinematics-library-back-button')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CinematicsLibraryWorkspace), findsOneWidget);
    }
  });

  for (final goldenState in <String>['library', 'builder', 'legacy']) {
    testWidgets(
      'matches the full Cinematics $goldenState route at 1672x941',
      (tester) async {
        await loadEventBuilderV2PhaseKCaptureFonts();
        await pumpEditorShellPage(
          tester,
          initialState: EditorState(
            project: _cinematicsProject(),
            workspaceMode: EditorWorkspaceMode.cutscene,
          ),
          surfaceSize: const Size(1672, 941),
          fontFamily: eventBuilderV2PhaseKCaptureFontFamily,
          cupertinoFontFamily: eventBuilderV2PhaseKCaptureFontFamily,
        );

        if (goldenState == 'builder') {
          await tester.tap(
            find.byKey(const ValueKey('cinematic-entry-cinematic_intro')),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(
              const ValueKey('cinematics-library-open-builder-button'),
            ),
          );
        } else if (goldenState == 'legacy') {
          await tester.tap(
            find.byKey(
              const ValueKey('cinematics-library-open-legacy-button'),
            ),
          );
        }
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump();

        final golden = File(
          'test/goldens/narrative_studio/cinematics/'
          'cinematics_${goldenState}_full_product_route_1672x941.png',
        );
        golden.parent.createSync(recursive: true);
        await expectLater(
          find.byType(EditorShellPage),
          matchesGoldenFile(golden.absolute.path),
        );
      },
    );
  }
}

ProjectManifest _cinematicsProject() {
  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: 'Cinématiques route fixture',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    scenarios: const <ScenarioAsset>[
      ScenarioAsset(
        id: 'scenario_legacy',
        name: 'Ancienne cinématique',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'start',
        metadata: <String, String>{
          'authoring.cutsceneSchema': 'cutscene-studio-v0',
        },
      ),
    ],
    cinematics: <CinematicAsset>[
      CinematicAsset(
        id: 'cinematic_intro',
        title: 'Intro cinématique',
        timeline: CinematicTimeline(),
      ),
    ],
  );
}
```


## Annexe B — manifeste des binaires créés

| Fichier | Type | Dimensions | Octets | SHA-256 |
|---|---|---:|---:|---|
| `packages/map_editor/assets/fonts/pokemap_capture_sans_regular.ttf` | TTF | — | 171676 | `79e851404657dac2106b3d22ad256d47824a9a5765458edb72c9102a45816d95` |
| `packages/map_editor/test/goldens/narrative_studio/cinematics/cinematics_builder_full_product_route_1672x941.png` | PNG | 1672×941 | 198693 | `97c445d0d67635bb92082a8d742b8db0b66b20fbfe000543ad2a12586c502532` |
| `packages/map_editor/test/goldens/narrative_studio/cinematics/cinematics_legacy_full_product_route_1672x941.png` | PNG | 1672×941 | 188204 | `d9886956a7ed3a93b6b511d85976251eaaaa5f913e2316406ab071920055defe` |
| `packages/map_editor/test/goldens/narrative_studio/cinematics/cinematics_library_full_product_route_1672x941.png` | PNG | 1672×941 | 183446 | `0f50f0789432bed10c7d1623daa4268d77f76922b55f7887277d111d6176d7f7` |
| `packages/map_editor/test/goldens/narrative_studio/dialogues/dialogues_full_product_route_1672x941.png` | PNG | 1672×941 | 90671 | `f2c9d4fd44e663211a8d921539517929b25761b16fe7159f162276fb7c682dd2` |
| `packages/map_editor/test/goldens/narrative_studio/events/event_builder_legacy_full_product_route_1672x941.png` | PNG | 1672×941 | 235401 | `a51c775321ca687afd1055971669f58f292368d8037d2c7060cd0600878aff6e` |
| `packages/map_editor/test/goldens/narrative_studio/facts/facts_full_product_route_1672x941.png` | PNG | 1672×941 | 113253 | `2a7fcf943567847ef3c64dee680de875d123062012f8c4d8574edb512671f40b` |
| `packages/map_editor/test/goldens/narrative_studio/overview/overview_full_product_route_1672x941.png` | PNG | 1672×941 | 254828 | `f5e8b1b76ee3338bb2707cced012cd73c8379fbf5dbd7ca311220fe592f28ef5` |
| `packages/map_editor/test/goldens/narrative_studio/scenes/scenes_full_product_route_1672x941.png` | PNG | 1672×941 | 155216 | `b5502bd011aa318a532d09791e2bf4b494caaeac08d6bd534601f3277628c0f7` |
| `packages/map_editor/test/goldens/narrative_studio/step/step_full_product_route_1672x941.png` | PNG | 1672×941 | 222906 | `73e664ac65a3410fa508e4ae564df221209c8083a0766ac83b4278bd47c21aa1` |
| `packages/map_editor/test/goldens/narrative_studio/storylines/storylines_full_product_route_1672x941.png` | PNG | 1672×941 | 158570 | `e5d594801a35537859af59231aad45906b5139844f8dcf562c6f6358ba463f29` |
| `packages/map_editor/test/goldens/narrative_studio/world_rules/world_rules_full_product_route_1672x941.png` | PNG | 1672×941 | 93055 | `3c180fa7a46e850010bd14582b99d2dcea16becf87bbdfb4ab467d736fdd96c9` |
| `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/00-target-and-final-routes-contact-sheet.png` | PNG | 1671×1256 | 681945 | `d0b9e73ec03fa91d30c9ccce18ad294929e3ef2db10be6eddb82cc3074c2858f` |
| `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/baseline-vs-event-builder-v2-phase-k.png` | PNG | 3344×941 | 567901 | `316acafb50a7b7d4580305203b2a540e975b556594cf3e239bfb17a85389c938` |
| `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/baseline-vs-ns_scenes_v1_29_storyline_step_scene_link_v0.png` | PNG | 2800×900 | 77284 | `67a828a34f3adb5421e938dca380e242d0e9db8fdda006ff2c871b3f3550d326` |
| `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/baseline-vs-ns_scenes_v1_39_cinematic_scene_builder_picker_v0.png` | PNG | 3840×1080 | 104269 | `d0da3746450e4f958c53d6cd0198f9dda469d0b650d54e5b7897bb5fdcc5238c` |
| `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/baseline-vs-ns_storylines_seed_fix_01_bis_graph_full_layout.png` | PNG | 3200×1000 | 120392 | `70dc84ab228d8ad0c980a42821fc9635cafe4f69edebf950c8fbd3468df66033` |
| `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/baseline-vs-ns_storylines_structure_bis_authoring_actions.png` | PNG | 2016×803 | 70052 | `ca3c68881a8d63fa9b4e516bc233392a40d1c1d8e3a14da114068530e3099d24` |
| `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/baseline-vs-ns_storylines_structure_bis_collapsed_chapter.png` | PNG | 2016×803 | 70594 | `cbc2bacbdc72413bf01b6ec8d2e68fc8448787df23adf42a1ed1582b8d39fa14` |
| `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/baseline-vs-ns_storylines_structure_bis_expanded_chapter_steps.png` | PNG | 2016×803 | 70594 | `cbc2bacbdc72413bf01b6ec8d2e68fc8448787df23adf42a1ed1582b8d39fa14` |
| `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/baseline-vs-ns_storylines_structure_bis_full_width_accordion.png` | PNG | 3200×1000 | 126946 | `bb95f8aa6e87a6217659c7e516629eca90416779880c644411202c386fd527aa` |
| `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/baseline-vs-ns_storylines_structure_bis_graph_regression.png` | PNG | 3200×1000 | 120398 | `5491340844cc2ab68080e3cf2a9fc79b2320e5db4f95e8fa87e91cd2d6c6f145` |
| `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-cinematics-builder.png` | PNG | 3344×941 | 1698782 | `6624db8472ef9464c1fe90bbab9b9409e04e74cc2d4b330c5876ee43252d3f1f` |
| `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-cinematics-legacy.png` | PNG | 3344×941 | 1691291 | `5d2120332b985ccba50b66bc9bcbc0af6aa722943dba040e65c973b9be8881a3` |
| `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-cinematics-library.png` | PNG | 3344×941 | 1685409 | `77fdb5bc8b6543d0999bdf20b9308b3a5887e4fd8e6f339b04e82699c94c84ba` |
| `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-dialogues.png` | PNG | 3344×941 | 1601711 | `ba34fc929b62fa4d64741a55f2965328513ee34e0b2837ba1a72f6e343b3faae` |
| `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-event-legacy.png` | PNG | 3344×941 | 1735114 | `e413c7a7b7596c2cbf8e6a49c0a41657e52b89f2b43a554063bd43d5d52a2dd4` |
| `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-event-v2-product.png` | PNG | 3344×941 | 1764483 | `bca95e112c0b360ac022cbf0f022706e3bab89b642e60a0a8d11d71197bfee11` |
| `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-event-v2.png` | PNG | 3344×941 | 1785044 | `485bca251992196e7208de8c41b201b49cfb4dfb588f27acba40de8533267bf4` |
| `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-facts.png` | PNG | 3344×941 | 1619740 | `d16d1f50726ccc6c086211a47ef14214916d5eb9bedb2ee3c117e63e477a65d1` |
| `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-overview.png` | PNG | 3344×941 | 1755987 | `1df34c56ca2c7450409175b25af61efcb0f4dddec258d4ec36d65294045fd381` |
| `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-scenes.png` | PNG | 3344×941 | 1659031 | `0afc8e64fa9828ae8bb704cc24f994a6787c4cb71ae795ce959f2a31ce61827a` |
| `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-step.png` | PNG | 3344×941 | 1724801 | `9ab0549e11d3ef71b3c7a1f4bdde5be3cc5f7eb4d7b153a018a1f60b42a841cd` |
| `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-storylines.png` | PNG | 3344×941 | 1662936 | `9a08b50d22e22d95f6557a25c011c6d6236b5a57aebb3f27cf7771c27e1b317b` |
| `reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-world-rules.png` | PNG | 3344×941 | 1602521 | `93b339150439818a12f1c214d270505fe70ad062768382dc503cacb2618d3519` |


## Annexe C — état Git final exact

```text
 M design-qa.md
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cutscene_studio/cutscene_studio_workbench.dart
 M packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_inspector.dart
 M packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart
 D packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_shell.dart
 M packages/map_editor/lib/src/ui/canvas/facts_world_rules/facts_world_rules_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_overview_structure_inspector.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
 D packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart
 D packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart
 M packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
 M packages/map_editor/lib/src/ui/design_system/pokemap_icon_button.dart
 M packages/map_editor/lib/src/ui/design_system/pokemap_sidebar_item.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart
 M packages/map_editor/pubspec.yaml
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M packages/map_editor/test/dialogue_studio_explorer_dialogue_widgets_test.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
 M packages/map_editor/test/facts_world_rules_manager_test.dart
 M packages/map_editor/test/goldens/event_builder_v2/phase_1/event_builder_v2_full_product_route_1672x941.png
 M packages/map_editor/test/goldens/event_builder_v2/phase_1/event_builder_v2_product_route_1672x941.png
 M packages/map_editor/test/goldens/event_builder_v2/phase_k/event_builder_v2_1672x941.png
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M packages/map_editor/test/shell_chrome_test_harness.dart
 M packages/map_editor/test/step_studio_workspace_regression_test.dart
 M packages/map_editor/test/storylines_current_global_story_characterization_test.dart
 M packages/map_editor/test/storylines_workspace_shell_test.dart
 M packages/map_editor/test/support/event_builder_v2_product_route_fixture.dart
 M packages/map_editor/test/support/event_builder_v2_visual_harness.dart
 M packages/map_editor/test/ui/canvas/event_builder_v2_product_route_test.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
 M packages/map_editor/test/ui/shell/project_explorer_handoff_test.dart
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_bis_edge_selection_deletion_ux_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_visual_port_connection_ux_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_wire_anchor_color_code.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_17_condition_authoring_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_18_fact_registry_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_29_storyline_step_scene_link_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_30_bis_scene_node_deletion_ux_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_30_scene_node_payload_editing_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_31_scene_consequence_authoring_ui_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_35_facts_world_rules_manager_ui_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_39_cinematic_scene_builder_picker_v0.png
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_bis_graph_full_layout.png
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_authoring_actions.png
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_collapsed_chapter.png
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_expanded_chapter_steps.png
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_full_width_accordion.png
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_graph_regression.png
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_empty_polished.png
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_main_polished.png
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_sidequest_attached_polished.png
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_sidequest_standalone_polished.png
?? packages/map_editor/assets/fonts/pokemap_capture_sans_LICENSE.txt
?? packages/map_editor/assets/fonts/pokemap_capture_sans_regular.ttf
?? packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_destination.dart
?? packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_product_navigation.dart
?? packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart
?? packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_route_presentation.dart
?? packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_shell_policy.dart
?? packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart
?? packages/map_editor/test/goldens/narrative_studio/cinematics/cinematics_builder_full_product_route_1672x941.png
?? packages/map_editor/test/goldens/narrative_studio/cinematics/cinematics_legacy_full_product_route_1672x941.png
?? packages/map_editor/test/goldens/narrative_studio/cinematics/cinematics_library_full_product_route_1672x941.png
?? packages/map_editor/test/goldens/narrative_studio/dialogues/dialogues_full_product_route_1672x941.png
?? packages/map_editor/test/goldens/narrative_studio/events/event_builder_legacy_full_product_route_1672x941.png
?? packages/map_editor/test/goldens/narrative_studio/facts/facts_full_product_route_1672x941.png
?? packages/map_editor/test/goldens/narrative_studio/overview/overview_full_product_route_1672x941.png
?? packages/map_editor/test/goldens/narrative_studio/scenes/scenes_full_product_route_1672x941.png
?? packages/map_editor/test/goldens/narrative_studio/step/step_full_product_route_1672x941.png
?? packages/map_editor/test/goldens/narrative_studio/storylines/storylines_full_product_route_1672x941.png
?? packages/map_editor/test/goldens/narrative_studio/world_rules/world_rules_full_product_route_1672x941.png
?? packages/map_editor/test/support/narrative_studio_capture_fonts.dart
?? packages/map_editor/test/support/narrative_studio_visual_harness.dart
?? packages/map_editor/test/ui/canvas/narrative_studio_cinematics_route_test.dart
?? packages/map_editor/test/ui/canvas/narrative_studio_destination_test.dart
?? packages/map_editor/test/ui/canvas/narrative_studio_responsive_accessibility_test.dart
?? packages/map_editor/test/ui/canvas/narrative_studio_shell_contract_test.dart
?? packages/map_editor/test/ui/canvas/narrative_studio_shell_policy_test.dart
?? packages/map_editor/test/ui/canvas/narrative_studio_specialized_routes_test.dart
?? packages/map_editor/test/ui/canvas/narrative_studio_visual_contract_test.dart
?? packages/map_editor/test/ui/canvas/narrative_studio_workspace_visual_test.dart
?? reports/narrativeStudio/ui_consistency_audit/evidence/00-narrative-studio-current-contact-sheet.png
?? reports/narrativeStudio/ui_consistency_audit/evidence/00-user-target-event-builder-1672x941.png
?? reports/narrativeStudio/ui_consistency_audit/evidence/01-scene-builder-current.png
?? reports/narrativeStudio/ui_consistency_audit/evidence/02-event-builder-current.png
?? reports/narrativeStudio/ui_consistency_audit/evidence/03-overview-current.png
?? reports/narrativeStudio/ui_consistency_audit/evidence/04-storylines-current.png
?? reports/narrativeStudio/ui_consistency_audit/evidence/05-scenes-current.png
?? reports/narrativeStudio/ui_consistency_audit/evidence/06-events-current.png
?? reports/narrativeStudio/ui_consistency_audit/evidence/07-cinematics-current.png
?? reports/narrativeStudio/ui_consistency_audit/evidence/08-dialogues-current.png
?? reports/narrativeStudio/ui_consistency_audit/evidence/09-facts-current.png
?? reports/narrativeStudio/ui_consistency_audit/evidence/10-world-rules-current.png
?? reports/narrativeStudio/ui_consistency_audit/evidence/11-validator-navigation-blocked.png
?? reports/narrativeStudio/ui_consistency_audit/narrative_studio_event_builder_visual_system_audit_2026-07-17.md
?? reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/00-target-and-final-routes-contact-sheet.png
?? reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/baseline-vs-event-builder-v2-phase-k.png
?? reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/baseline-vs-ns_scenes_v1_29_storyline_step_scene_link_v0.png
?? reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/baseline-vs-ns_scenes_v1_39_cinematic_scene_builder_picker_v0.png
?? reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/baseline-vs-ns_storylines_seed_fix_01_bis_graph_full_layout.png
?? reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/baseline-vs-ns_storylines_structure_bis_authoring_actions.png
?? reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/baseline-vs-ns_storylines_structure_bis_collapsed_chapter.png
?? reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/baseline-vs-ns_storylines_structure_bis_expanded_chapter_steps.png
?? reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/baseline-vs-ns_storylines_structure_bis_full_width_accordion.png
?? reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/baseline-vs-ns_storylines_structure_bis_graph_regression.png
?? reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-cinematics-builder.png
?? reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-cinematics-legacy.png
?? reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-cinematics-library.png
?? reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-dialogues.png
?? reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-event-legacy.png
?? reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-event-v2-product.png
?? reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-event-v2.png
?? reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-facts.png
?? reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-overview.png
?? reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-scenes.png
?? reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-step.png
?? reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-storylines.png
?? reports/narrativeStudio/ui_convergence/evidence/ns_ui_cvg_11/qa/target-vs-world-rules.png
?? reports/narrativeStudio/ui_convergence/ns_ui_cvg_11_final_evidence_pack.md
?? selbrume/.pokemap-project-1f1a60297a27b0b0.lock
?? selbrume/assets/sources/v2/houses/house_01_white_orange_roof.png
?? selbrume/assets/sources/v2/houses/house_02_large_blue_roof.png
?? selbrume/assets/sources/v2/houses/house_03_wooden_shed.png
?? selbrume/assets/sources/v2/houses/house_04_blue_roof_clinic.png
?? selbrume/assets/sources/v2/houses/house_05_blue_roof_shop.png
?? selbrume/assets/sources/v2/houses/house_06_wide_orange_roof.png
?? selbrume/assets/sources/v2/marsh/01_bassin_haut_gauche.png
?? selbrume/assets/sources/v2/marsh/02_bassin_haut_centre.png
?? selbrume/assets/sources/v2/marsh/03_bassin_haut_large.png
?? selbrume/assets/sources/v2/marsh/04_bassin_haut_droit.png
?? selbrume/assets/sources/v2/marsh/05_bassin_bas_large.png
?? selbrume/assets/sources/v2/marsh/06_roseaux_marais.png
?? selbrume/assets/sources/v2/marsh/07_passerelle_bois.png
?? selbrume/assets/sources/v2/marsh/08_tas_sel_marais.png
?? selbrume/assets/sources/v2/port/01_quai_bois_grand.png
?? selbrume/assets/sources/v2/port/02_pont_bois_sur_eau.png
?? selbrume/assets/sources/v2/port/03_caisses_port.png
?? selbrume/assets/sources/v2/port/04_poteau_1.png
?? selbrume/assets/sources/v2/port/05_poteau_2.png
?? selbrume/assets/sources/v2/port/06_caisse_simple.png
?? selbrume/assets/sources/v2/props/01_puits.png
?? selbrume/assets/sources/v2/props/02_velo.png
?? selbrume/assets/sources/v2/props/03_panneau_carte.png
?? selbrume/assets/sources/v2/props/04_panneau_gois_marees.png
?? selbrume/assets/sources/v2/props/05_lampadaire_1.png
?? selbrume/assets/sources/v2/props/06_lampadaire_2.png
?? selbrume/assets/sources/v2/props/07_panneau_affichage.png
?? selbrume/assets/sources/v2/props/08_caisse.png
?? selbrume/assets/sources/v2/props/09_jardiniere_basse.png
?? selbrume/assets/sources/v2/props/10_banc.png
?? selbrume/assets/sources/v2/props/11_jardiniere_haute.png
?? selbrume/assets/sources/v2/props/12_borne_bois.png
?? selbrume/assets/sources/v2/props/13_baril_haut.png
?? selbrume/assets/sources/v2/props/14_baril_bas_1.png
?? selbrume/assets/sources/v2/props/15_tas_sel.png
?? selbrume/assets/sources/v2/props/16_barque.png
?? selbrume/assets/sources/v2/props/17_coffre.png
?? selbrume/assets/sources/v2/props/18_poteau_goeland.png
?? selbrume/assets/sources/v2/props/19_bouee.png
?? selbrume/assets/sources/v2/props/20_cabine_plage_verte.png
?? selbrume/assets/sources/v2/props/21_cabine_plage_bleue_1.png
?? selbrume/assets/sources/v2/props/22_cabine_plage_bleue_2.png
?? selbrume/assets/sources/v2/props/23_cabine_plage_blanche.png
?? selbrume/assets/sources/v2/rocks/rocher_decor_01.png
?? selbrume/assets/sources/v2/rocks/rocher_decor_02.png
?? selbrume/assets/sources/v2/rocks/rocher_decor_03.png
?? selbrume/assets/sources/v2/rocks/rocher_decor_04.png
?? selbrume/assets/sources/v2/rocks/rocher_decor_05.png
?? selbrume/assets/sources/v2/rocks/rocher_decor_06.png
?? selbrume/assets/sources/v2/rocks/rocher_decor_07.png
?? selbrume/assets/sources/v2/rocks/rocher_decor_08.png
?? selbrume/assets/sources/v2/rocks/rocher_decor_09.png
?? selbrume/assets/sources/v2/rocks/rocher_decor_10.png
?? selbrume/assets/sources/v2/rocks/rocher_decor_11.png
?? selbrume/assets/sources/v2/vegetation/01_arbre_1.png
?? selbrume/assets/sources/v2/vegetation/02_arbre_2.png
?? selbrume/assets/sources/v2/vegetation/03_arbre_jaune.png
?? selbrume/assets/sources/v2/vegetation/04_arbre_sec.png
?? selbrume/assets/sources/v2/vegetation/05_buisson.png
?? selbrume/assets/sources/v2/vegetation/06_herbes_hautes_1.png
?? selbrume/assets/sources/v2/vegetation/07_herbes_hautes_2.png
?? selbrume/assets/sources/v2/vegetation/08_fleurs_violettes.png
?? selbrume/assets/sources/v2/vegetation/09_roseaux.png
?? selbrume/assets/sources/v2/vegetation/10_fleurs_1.png
?? selbrume/assets/sources/v2/vegetation/11_fleurs_2.png
?? selbrume/assets/sources/v2/vegetation/12_fleurs_blanches_1.png
?? selbrume/assets/sources/v2/vegetation/13_fleurs_rouges.png
?? selbrume/assets/sources/v2/vegetation/14_fleurs_blanches_2.png
```
