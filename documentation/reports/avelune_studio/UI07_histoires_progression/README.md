# AS-UI-007 — Histoires et progression

État : implémentation locale, validation visuelle utilisateur attendue.
Base : `a4ae464fe3baf6a01ecf0db946d93c66ac67d3f8`, branche `main`, arbre initial propre.
Aucune écriture Git ou Notion. Les fixtures de publication utilisent des répertoires temporaires ; aucun projet original n’est utilisé comme destination.

## Audit initial et décisions

Le pack UI07, ses références, ses annexes et la maquette 02 ont été lus. La maquette a réellement été ouverte. Les frontières existantes sont conservées : modèles et opérations Storyline dans map_core, transactions map_authoring, sessions Studio et présentation dans features/stories. UI06 reste un éditeur de scène distinct.

Constats vérifiés dans le code :
- UI05 possédait déjà pendingStories et pendingFacts : UI07 partage ces mêmes brouillons, au lieu d’en créer une seconde copie.
- Le propriétaire d’une relation peut être une histoire secondaire : les deltas et la publication ciblent les agrégats réellement modifiés.
- step.sceneLinkIds associe des SceneAsset modernes. Les StorylineSceneLink structurés utilisent des ScenarioAsset historiques. Aucun rapprochement par nom, aucune migration implicite.
- La connexion canonique exigeait un outcomeLink existant, alors que le modèle interdit un outcomeLink sans effet. Le premier effet est désormais créé atomiquement par l’opération existante, via outcomeId optionnel, après validation du vrai résultat déclaré, de la destination, des doublons et des cycles. Aucun nouveau format de document.
- Les coordonnées du graphe Storyline ne sont pas persistées dans le manifeste. La disposition, le cadrage et la sélection restent attachés au projet et à l’histoire durant la session.

## Parcours livré

Bibliothèque recherchable et filtrable pour tous les types, histoires homonymes distinguées par leur identité, indication hors filtre. Création d’une histoire vide, chapitres et étapes, modification/effacement des propriétés optionnelles, duplication, statut d’auteur, suppression protégée par les consommateurs.

Graphe par défaut : chapitres groupés, étapes ciblables, faits booléens, résultats explicites de scénarios et histoires liées. Connexions manipulables pour activer/accomplir une étape, conditionner son entrée/achèvement et créer une relation simple entre histoires. Courbes sélectionnables, provenance inspectable, déconnexion canonique, annulation/rétablissement sémantique. Pan, zoom, trackpad, déplacement de groupes et mini-carte modifient seulement la vue ; leur historique est distinct.

Structure : mêmes documents, classement explicite des chapitres/étapes, sélection commune. Inspecteur : noms, descriptions, notes, type/statut, conditions, références et actions. Les liens enrichis restent consultables avec leurs ancres et conditions ; ils ne sont pas aplatis pour devenir des relations simples.

Navigation : entrée locale depuis Histoire UI05, ouverture exacte d’une scène associée dans UI06, puis retour contextualisé à UI07. L’accès UI06 depuis UI05 conserve son retour vers UI05.

Publication : faits puis histoires concernées, chaque document dans une transaction canonique avec base optimiste, vérification du reçu et récupération. L’ensemble de plusieurs documents n’est pas une transaction atomique globale : un succès partiel est annoncé et les autres brouillons restent modifiés. Aucun enregistrement de carte ou de scène caché derrière le bouton UI07.

## Corrections UI06

- C1 : réconciliation des scènes propres après publication par un autre parcours ; conservation des scènes sales/en sauvegarde, purge de l’historique périmé, réconciliation des sélections disparues sans perdre le cadrage.
- C2 : priorité de readOnlySource et isolation du cache par workspace ; conservation des sources avancées sans conversion en interaction simplifiée.
- C3 : suppression des deux imports redondants visés par la revue, sans ignore.

Les reproductions C1/C2 précèdent leurs corrections. Journaux locaux : `/tmp/ui07-corrections-verified.txt`, `/tmp/ui07-cache-red.txt`. Le premier effet Storyline a également été reproduit en échec contre une copie extérieure du code HEAD : `/tmp/ui07-first-outcome-baseline-red2.txt`.

## Comparaison visuelle

La première capture réelle a montré un cadrage trop réduit, des libellés CustomPainter rendus avec la police de test et un débordement compact. Corrections : typographie issue du thème, colonnes adaptées à une histoire courte, taille des groupes tenant compte du texte agrandi, bibliothèque défilable, contrôles Avelune réutilisés.

Les images sont des captures non retouchées des vrais widgets Flutter, rendus hors écran à partir d’une fixture temporaire utilisant les adaptateurs réels. Elles ne constituent pas une preuve d’exécution interactive native sur macOS.

La passe de parcours a aussi reproduit trois défauts avant correction : perte du focus clavier après sélection d’un fil, sauvegarde du texte encore focalisé, retour UI05 reprenant une ancienne histoire. Les quatre tests de sélection associés passent après correction. Le petit écran dispose maintenant d’un en-tête adapté et d’une barre d’actions défilable, sans diminuer le facteur de texte demandé. Une réserve de cadrage évite que la mini-carte recouvre la quête secondaire au cadrage initial.

Écarts délibérés au PNG : pas d’illustrations arbitraires lorsque les documents n’ont pas de média associé ; pas de score de progression du joueur ni de faux nœud de début/fin ; pas de flèche de suite inventée à partir d’un classement. L’ordre d’auteur, les conditions et les dépendances sont nommés séparément.

## Vérifications exécutées

| Périmètre | Commande / résultat |
| --- | --- |
| Corrections Studio C1/C2 et régressions UI06 | 22 tests verts, `/tmp/ui07-corrections-verified.txt` |
| Ancien éditeur, workflow et extraction C3 | 49 tests verts, `/tmp/ui07-editor-c3-tests.txt` |
| Analyse ancien éditeur | Un import inutile préexistant hors lot subsiste dans cinematics_library_workspace.dart:6 ; `/tmp/ui07-editor-c3-analyze.txt`. Les deux imports demandés sont corrigés. Aucune affirmation sur la CI distante. |
| Modèles/opérations/projections Storyline | 98 tests verts, `/tmp/ui07-core-all.txt` ; analyse des deux fichiers core concernés : No issues found! |
| Publication canonique map_authoring | `dart test test/domains/narrative/storyline_scenario_authoring_test.dart --reporter expanded` : 3 tests verts |
| Serveur MCP construit | `cd tools/pokemap_mcp && npm run build` : exit 0 |
| Transport MCP empaqueté | Test de publication narrative existant et nouveau test UI07 storyline.upsert : 2 tests verts sur le fichier final ; npm run check : exit 0 |
| Suite finale Studio | `flutter test --no-pub --reporter expanded` : `01:19 +415 ~2: All tests passed!`, `/tmp/ui07-studio-final.txt` ; 2 tests optionnels ignorés car AVELUNE_PROJECT_COPY / copie Train absents |
| Analyse Studio | `dart analyze lib test` : `No issues found!` |
| Build macOS | `flutter build macos --debug --no-pub` : `✓ Built build/macos/Build/Products/Debug/Avelune Studio.app`, `/tmp/ui07-macos-build.txt` |
| Captures finales | Rejeu de `test/presentation/ui07_story_journey_test.dart` avec AVELUNE_CAPTURE_DIR : 1 test vert, sept PNG produits, `/tmp/ui07-captures-final.txt` |

Commande core exacte, depuis packages/map_core :

```sh
dart test test/storyline_asset_test.dart test/storyline_asset_json_test.dart test/storyline_authoring_operations_test.dart test/storyline_progression_operations_test.dart test/storyline_first_outcome_connection_test.dart test/storyline_progression_projection_test.dart test/storyline_scene_link_test.dart test/storyline_scene_link_diagnostics_test.dart test/storyline_scene_links_read_model_test.dart test/project_manifest_storylines_test.dart --reporter expanded
```

Commandes MCP ciblées, depuis tools/pokemap_mcp :

```sh
npm run build
node --import tsx --test --test-concurrency=1 test/studio_narrative_publication.test.ts
```

Commandes des corrections UI06, depuis `apps/avelune_studio` puis `packages/map_editor` respectivement :

```sh
flutter test --no-pub --reporter expanded test/scenes/scene_reconciliation_ui07_test.dart test/presentation/ui07_scene_linked_source_test.dart test/scenes/scene_session_ui06_test.dart test/scenes/scene_history_ui06_test.dart test/presentation/ui06_scene_inspector_test.dart
flutter test --no-pub --reporter expanded --timeout 2m test/release/github_distribution_workflow_test.dart test/tileset_grid_metrics_test.dart test/map_editing_controller_test.dart test/scene_action_builder_test.dart test/narrative_template_catalog_test.dart
flutter analyze --no-pub lib test/release
```

L’appel du connecteur MCP configuré `pokemap_describe` a échoué : `worker.exited`, code 78. Le test empaqueté ouvre son propre transport et inspecte son catalogue ; son succès ne prouve pas le fonctionnement du connecteur configuré.

Parité sémantique MCP : PARTIAL pour le geste de connexion Storyline, aucune action dédiée progression.connect n’existant dans le catalogue. La persistance ciblée storyline.upsert est testée ; elle ne remplace pas une preuve d’exposition sémantique des trois gestes.

Les runners Flutter ont été suivis avec leurs descendants, puis seuls leurs processus résiduels prouvés ont été nettoyés. Aucun arrêt global par nom de processus.

Mesure de volume dans la suite finale : 10 histoires, 20 chapitres, 200 étapes, 100 liens sémantiques, huit gestes ; `viewportUpdates=12`, `projectionRebuilt=false`, `documentMutations=0`, aucun adaptateur d’E/S instancié. Mesures de ce run de test : `firstFrameUs=954427`, `gesturesUs=1130800`. Ce sont des temps de test Flutter, pas une mesure de FPS natifs.

## Passes de revue

- Passe backend : sessions partagées, propriétaires réels, versions de base, publication partielle, rechargement ciblé, courses de sauvegarde et gardes de test du jeu.
- Passe canvas : géométrie, sélection de courbe, connexion précise, annulation des gestes, trackpad, volume, premier résultat et collisions d’identifiants dérivés.
- Passe parcours : fixture réelle, construction depuis zéro, modification effective dans UI06, retour, sélection/focus, filtres, tailles et captures.
- Passe principale : intégration, propriétés/structure, raccords, comparaison des captures, vérifications transversales et limites.

La première suite complète a révélé une fixture UI06 invalide (layout référençant un nœud retiré) et un débordement pendant la transition vers le petit écran. La fixture a été corrigée sans toucher au contrat ; la composition compacte a été ajustée. La reprise ciblée des deux cas et des quatre tests de sélection est verte : 6 tests, `/tmp/ui07-compact-fixed.txt`.

## Captures finales accessibles

- [Histoire complète](captures/01-histoire-complete.png) : bibliothèque, chapitres, étapes, sources et quête secondaire.
- [Connexion en cours](captures/02-connexion-progression.png) : source booléenne et étape précise.
- [Inspecteur de relation](captures/03-inspecteur-relation.png) : sens, propriétaire et inverse.
- [Structure](captures/04-structure.png) : même document et classement explicite.
- [Scène réellement modifiée](captures/05-scene-modifiee.png) : édition UI06 depuis l’étape, puis sauvegarde/relecture contrôlée par le test.
- [Retour contextualisé](captures/05-retour-scene.png) : même étape et brouillon Storyline préservé.
- [Compact à 150 %](captures/06-compact-texte150.png) : 1024 × 640, panneaux conservés et actions accessibles.

Génération reproductible depuis `apps/avelune_studio` :

```sh
AVELUNE_CAPTURE_DIR="$PWD/../../documentation/reports/avelune_studio/UI07_histoires_progression/captures" flutter test --no-pub --reporter expanded test/presentation/ui07_story_journey_test.dart
```

## Limites et auto-critique

Validation visuelle utilisateur encore attendue. Pas de nouvelle page commencée.
Les résultats structurés des scènes modernes restent une limite du contrat existant : seules leurs associations et leur édition UI06 sont raccordées ; les résultats structurés proviennent de scénarios historiques réels.
Les liens enrichis avancés restent localement en lecture seule ; leurs champs sont conservés et expliqués.
La disposition visuelle ne survit pas au redémarrage. Les sauvegardes du joueur et les évaluateurs runtime ne sont pas réécrits ; les tests de projection ne prouvent pas une progression jouée.
La certification native interactive, la CI distante et le connecteur MCP configuré ne sont pas déclarés verts.

## Lancement

Depuis la racine du dépôt :

```sh
cd apps/avelune_studio
flutter run -d macos
```

Ouvrir un projet de travail puis Histoire → Histoires et progression. Les boutons publient dans le projet ouvert ; les recettes livrées utilisent exclusivement des copies temporaires.

## Inventaire des fichiers

Les zones modifiées sont les contrôleurs et transactions narratives, les raccords DI/navigation, les trois correctifs UI06, le nouveau répertoire de présentation stories, deux primitives DS, l’opération canonique du premier effet, puis les fixtures/tests ci-dessous. Aucun moteur runtime ou autre écran spécialisé n’est reconstruit.

- `apps/avelune_studio/lib/app/di/providers.dart`
- `apps/avelune_studio/lib/app/studio_bootstrap.dart`
- `apps/avelune_studio/lib/features/narrative/application/narrative_overview_cache.dart`
- `apps/avelune_studio/lib/features/narrative/application/narrative_overview_projection.dart`
- `apps/avelune_studio/lib/features/narrative/application/narrative_workspace_controller.dart`
- `apps/avelune_studio/lib/features/scenes/application/scene_edit_session.dart`
- `apps/avelune_studio/lib/features/scenes/application/scene_workspace_controller.dart`
- `apps/avelune_studio/lib/features/scenes/data/local_scene_adapter.dart`
- `apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_screen.dart`
- `apps/avelune_studio/lib/presentation/features/map_workspace/workspace_actions.dart`
- `apps/avelune_studio/lib/presentation/features/map_workspace/workspace_secondary_content.dart`
- `apps/avelune_studio/lib/presentation/features/map_workspace/workspace_story_binding.dart`
- `apps/avelune_studio/lib/presentation/features/narrative/narrative_overview_header.dart`
- `apps/avelune_studio/lib/presentation/features/narrative/narrative_story_pane.dart`
- `apps/avelune_studio/lib/presentation/features/scenes/scene_builder_header.dart`
- `apps/avelune_studio/lib/presentation/features/scenes/scene_builder_page.dart`
- `apps/avelune_studio/lib/presentation/features/scenes/scene_builder_view_state.dart`
- `apps/avelune_studio/lib/presentation/features/scenes/scene_linked_document.dart`
- `apps/avelune_studio/lib/presentation/shared/widgets/inputs/studio_commit_field.dart`
- `apps/avelune_studio/lib/presentation/shared/widgets/layout/studio_primary_navigation.dart`
- `apps/avelune_studio/lib/presentation/shell/studio_workspace_host.dart`
- `apps/avelune_studio/test/presentation/ui06_scene_playtest_guard_test.dart`
- `apps/avelune_studio/test/support/ui06_scene_fixture.dart`
- `packages/map_core/lib/src/authoring/storyline_progression_operations.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/narrative_command_authoring_capability_evidence.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_action_builder.dart`
- `tools/pokemap_mcp/test/studio_narrative_publication.test.ts`
- `apps/avelune_studio/lib/app/di/story_providers.dart`
- `apps/avelune_studio/lib/features/narrative/data/local_narrative_catalog_transaction.dart`
- `apps/avelune_studio/lib/features/stories/application/story_edit_history.dart`
- `apps/avelune_studio/lib/features/stories/application/story_workspace_controller.dart`
- `apps/avelune_studio/lib/features/stories/application/story_workspace_publication.dart`
- `apps/avelune_studio/lib/features/stories/application/story_workspace_reload.dart`
- `apps/avelune_studio/lib/features/stories/data/local_story_adapter.dart`
- `apps/avelune_studio/lib/features/stories/domain/story_port.dart`
- `apps/avelune_studio/lib/presentation/features/map_workspace/workspace_progression_binding.dart`
- `apps/avelune_studio/lib/presentation/features/map_workspace/workspace_screen_body.dart`
- `apps/avelune_studio/lib/presentation/features/stories/story_coherence_dialog.dart`
- `apps/avelune_studio/lib/presentation/features/stories/story_create_dialog.dart`
- `apps/avelune_studio/lib/presentation/features/stories/story_document_commands.dart`
- `apps/avelune_studio/lib/presentation/features/stories/story_graph_canvas.dart`
- `apps/avelune_studio/lib/presentation/features/stories/story_graph_connection.dart`
- `apps/avelune_studio/lib/presentation/features/stories/story_graph_controls.dart`
- `apps/avelune_studio/lib/presentation/features/stories/story_graph_geometry.dart`
- `apps/avelune_studio/lib/presentation/features/stories/story_graph_layer.dart`
- `apps/avelune_studio/lib/presentation/features/stories/story_graph_painter.dart`
- `apps/avelune_studio/lib/presentation/features/stories/story_graph_source_picker.dart`
- `apps/avelune_studio/lib/presentation/features/stories/story_graph_sources.dart`
- `apps/avelune_studio/lib/presentation/features/stories/story_graph_surface.dart`
- `apps/avelune_studio/lib/presentation/features/stories/story_inspector.dart`
- `apps/avelune_studio/lib/presentation/features/stories/story_labels.dart`
- `apps/avelune_studio/lib/presentation/features/stories/story_library_panel.dart`
- `apps/avelune_studio/lib/presentation/features/stories/story_metadata_fields.dart`
- `apps/avelune_studio/lib/presentation/features/stories/story_progression_content.dart`
- `apps/avelune_studio/lib/presentation/features/stories/story_progression_page.dart`
- `apps/avelune_studio/lib/presentation/features/stories/story_progression_view_store.dart`
- `apps/avelune_studio/lib/presentation/features/stories/story_relation_details.dart`
- `apps/avelune_studio/lib/presentation/features/stories/story_reload_dialog.dart`
- `apps/avelune_studio/lib/presentation/features/stories/story_scenario_links.dart`
- `apps/avelune_studio/lib/presentation/features/stories/story_scene_links.dart`
- `apps/avelune_studio/lib/presentation/features/stories/story_structure_view.dart`
- `apps/avelune_studio/lib/presentation/features/stories/story_view_state.dart`
- `apps/avelune_studio/lib/presentation/shared/widgets/layout/studio_graph_card.dart`
- `apps/avelune_studio/test/presentation/ui07_scene_linked_source_test.dart`
- `apps/avelune_studio/test/presentation/ui07_story_construction_test.dart`
- `apps/avelune_studio/test/presentation/ui07_story_journey_test.dart`
- `apps/avelune_studio/test/presentation/ui07_story_playtest_guard_test.dart`
- `apps/avelune_studio/test/presentation/ui07_story_selection_test.dart`
- `apps/avelune_studio/test/scenes/scene_reconciliation_ui07_test.dart`
- `apps/avelune_studio/test/scenes/scene_view_reconciliation_ui07_test.dart`
- `apps/avelune_studio/test/stories/story_document_commands_test.dart`
- `apps/avelune_studio/test/stories/story_publication_races_ui07_test.dart`
- `apps/avelune_studio/test/stories/story_publication_ui07_test.dart`
- `apps/avelune_studio/test/stories/story_reconciliation_ui07_test.dart`
- `apps/avelune_studio/test/stories/story_sessions_ui07_test.dart`
- `apps/avelune_studio/test/stories/ui07_story_fixture_test.dart`
- `apps/avelune_studio/test/story_graph_canvas_test.dart`
- `apps/avelune_studio/test/story_scenario_links_test.dart`
- `apps/avelune_studio/test/support/delayed_map_save_port.dart`
- `apps/avelune_studio/test/support/delayed_story_port.dart`
- `apps/avelune_studio/test/support/story_backend_fixture.dart`
- `apps/avelune_studio/test/support/story_canvas_test_harness.dart`
- `apps/avelune_studio/test/support/ui07_journey_driver.dart`
- `apps/avelune_studio/test/support/ui07_story_fixture.dart`
- `apps/avelune_studio/test/support/ui07_workspace_harness.dart`
- `apps/avelune_studio/test/ui07_story_graph_volume_test.dart`
- `packages/map_core/test/storyline_first_outcome_connection_test.dart`

Le présent rapport et les sept captures finales complètent cet inventaire. État final : 95 fichiers modifiés ou nouveaux, tous laissés dans l’arbre local, HEAD inchangé à `a4ae464fe3baf6a01ecf0db946d93c66ac67d3f8`. `git diff --check` passe. Aucun ajout à l’index, commit ou push.

Hygiène Markdown : `POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh` passe : un seul nouveau document, celui explicitement demandé par le pack, à l’emplacement canonique. Aucun fichier Dart manuel Studio ajouté ou modifié ne dépasse 300 lignes.
