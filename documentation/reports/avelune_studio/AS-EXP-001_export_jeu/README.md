# AS-EXP-001 — Exporter un jeu depuis Avelune Studio et le jouer dans Avelune

Ticket de référence : https://app.notion.com/p/3e2197a7bfa5819888efe20c15b10e47. Aucune écriture Notion ni Git n'a été effectuée.

## Résultat et périmètre

Dans un projet ouvert, l'entrée « Exporter le jeu » crée un `.avelunegame` par le service canonique de `map_authoring`. Le créateur renseigne les métadonnées de distribution, choisit `Publication` ou `Test local` et la destination native. Un fichier existant demande confirmation ; une destination apparue pendant la construction est refusée. Les brouillons déclenchent un choix explicite d'enregistrement par leurs propriétaires. L'activité suit préparation, construction/validation, puis écriture, sans pourcentage fictif. La page affiche le chemin, le SHA-256 et une empreinte stable des fichiers auteur pris en compte.

La recette utilise une copie temporaire à deux cartes. Elle exporte par le véritable écran Studio, rend la source inaccessible, installe le paquet avec `GamePackageInstaller`, résout le jeu installé, lance `PlayableMapGame` depuis cette installation, déclenche un dialogue et atteint la seconde carte par passage. Le paquet témoin est [as-exp-001-demo.avelunegame](as-exp-001-demo.avelunegame), SHA-256 `b4f21353fe231650330cbce1e320175f7a24d966a697bcf8c443d0d43cdd823c`.

Lancement local : `cd apps/avelune_studio && flutter run -d macos`, puis ouvrir un projet et choisir « Exporter le jeu » dans la navigation. Pour le Player : `cd apps/pokemap_hub && flutter run -d macos`, puis importer le `.avelunegame` produit dans sa bibliothèque et lancer le jeu installé.

## Audit initial

La relecture MAP-002 a confirmé l'ordre fautif de `_openStoryInteraction()` : un record enregistré dans Événements devançait la session simplifiée modifiée. Un test rouge dans le véritable `MapWorkspaceScreen` a reproduit première sauvegarde, seconde modification, retour Carte et réouverture. La correction donne la priorité à la session simplifiée **sale**, sans faire passer une session propre devant le propriétaire enregistré ; les identités, sélections et protections de coexistence sont conservées.

L'exporteur de l'ancien éditeur délègue déjà à `CanonicalGamePackageExportService` ; ses contrats `GamePackageExportProfile`, les modes et l'extension `.avelunegame` sont publics dans `map_authoring`/`map_distribution`. Le Player possède déjà l'inspection, l'installation et la résolution de lancement. L'intervention ne crée donc ni format, ni moteur, ni adaptateur vers les composants privés de l'ancien éditeur. Risques repérés : brouillons détenus par plusieurs éditeurs, modifications de fichiers pendant la construction, écrasement tardif, repli d'écriture macOS sur un fichier existant et réponse tardive après fermeture.

État Git initial : la branche avait déjà dix chemins modifiés du chantier MAP-002 (`map_context_menu_actions.dart`, `map_context_menu_model.dart`, `workspace_context_menu_binding.dart`, `workspace_world_binding.dart`, les quatre tests d'hôte `context_identity`, `decor_move`, `keyboard_delete`, `story_zone_reopen`, `map_host_fixture.dart`, et le rapport AS-MAP-002). Ils ont été préservés ; ce lot n'a pas réinitialisé l'arbre.

```
 M apps/avelune_studio/lib/features/map_workspace/application/map_context_menu_actions.dart
 M apps/avelune_studio/lib/features/map_workspace/application/map_context_menu_model.dart
 M apps/avelune_studio/lib/presentation/features/map_workspace/workspace_context_menu_binding.dart
 M apps/avelune_studio/lib/presentation/features/map_workspace/workspace_world_binding.dart
 M apps/avelune_studio/test/map_workspace/context_identity_host_test.dart
 M apps/avelune_studio/test/map_workspace/decor_move_host_test.dart
 M apps/avelune_studio/test/map_workspace/keyboard_delete_host_test.dart
 M apps/avelune_studio/test/map_workspace/story_zone_reopen_host_test.dart
 M apps/avelune_studio/test/support/map_host_fixture.dart
 M documentation/reports/avelune_studio/AS-MAP-002_clic_droit_carte/README.md
```

## Fichiers et zones

| Chemin | Zone / effet |
| --- | --- |
| `apps/avelune_studio/lib/presentation/features/map_workspace/workspace_story_binding.dart` | `_openStoryInteraction` reprend la session simplifiée sale avant le record ; session propre traitée par son propriétaire. |
| `apps/avelune_studio/test/map_workspace/story_zone_reopen_host_test.dart` | nouveau parcours sauvegarde, modification, réouverture, identité et absence de publication. |
| `documentation/reports/avelune_studio/AS-MAP-002_clic_droit_carte/README.md` | note courte du correctif et cinquième test d'hôte. |
| `apps/avelune_studio/lib/features/game_export/domain/studio_game_export_port.dart` | contrat pur des métadonnées, destination, état, changements et opérations. |
| `apps/avelune_studio/lib/features/game_export/data/studio_game_export_controller.dart` | profil canonique, orchestration asynchrone, annulation, erreurs, garde de projet/révision/destination et écriture. |
| `apps/avelune_studio/lib/features/game_export/data/studio_export_revision.dart` | empreintes de fichiers auteur avant/après construction et révision affichée. |
| `apps/avelune_studio/lib/platform/files/native_game_export_picker.dart` | sélection native et constat d'existence du fichier. |
| `apps/avelune_studio/lib/presentation/features/game_export/studio_game_export_name.dart` | nom de fichier suggéré. |
| `apps/avelune_studio/lib/presentation/features/game_export/studio_game_export_page.dart` | écran Avelune, profil, mode, confirmation, progression et reçu. |
| `apps/avelune_studio/lib/app/di/game_export_providers.dart`, `providers.dart`, `apps/avelune_studio/lib/app/studio_bootstrap.dart` | injection du port et du sélecteur natif ; aucune I/O dans la présentation. |
| `apps/avelune_studio/lib/presentation/shell/studio_workspace_host.dart` | fournit port et sélecteur au workspace réel. |
| `apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_screen.dart`, `map_workspace_layout.dart`, `workspace_screen_body.dart`, `workspace_secondary_content.dart`, `workspace_export_binding.dart` | entrée de navigation, page, préparation et garde de fermeture. |
| `apps/avelune_studio/lib/presentation/shared/widgets/layout/studio_primary_navigation.dart` | entrée « Exporter le jeu » accessible hors vérification narrative. |
| `apps/avelune_studio/lib/presentation/features/map_workspace/workspace_actions.dart`, `workspace_close_actions.dart` | réutilisation de la sauvegarde ordonnée des propriétaires et remontée de sa cause d'échec. |
| `packages/map_authoring/lib/src/domains/distribution/game_package_export_service.dart` | exposition de l'écriture de l'artifact certifié ; repli direct interdit si une destination existe, validation d'extension avant construction. |
| `apps/avelune_studio/test/support/map_host_fixture.dart`, `test/support/game_export_fixture.dart` | hôte réel, projet temporaire exportable à deux cartes, destination injectable et capture. |
| `apps/avelune_studio/test/game_export/studio_game_export_control_test.dart`, `studio_game_export_service_test.dart` | préparation refusée, ressource absente, annulation, mutation concurrente, échec/reprise, écrasement, écran et fichiers auteur inchangés. |
| `apps/pokemap_hub/pubspec.yaml`, `pubspec.lock` | Studio uniquement en dépendance de développement pour la recette croisée. |
| `apps/pokemap_hub/test/features/installation/avelune_studio_export_player_e2e_test.dart` | export UI → paquet → installateur → résolution → runtime installé → dialogue → passage. |
| `documentation/reports/avelune_studio/AS-EXP-001_export_jeu/captures/export-ready.png`, `as-exp-001-demo.avelunegame` | capture réelle du widget avec polices chargées et paquet produit par la recette. |

Les autres modifications MAP-002 déjà présentes à l'ouverture (`map_context_menu_actions.dart`, `map_context_menu_model.dart`, `workspace_context_menu_binding.dart`, `workspace_world_binding.dart`, `context_identity_host_test.dart`, `decor_move_host_test.dart`, `keyboard_delete_host_test.dart`) restent hors de cette intervention. Le diff Git les conserve sans les attribuer à AS-EXP-001.

## Vérifications et preuves

Capture : [export-ready.png](captures/export-ready.png). Elle provient du véritable `MapWorkspaceScreen` monté en test widget, avec les polices desktop chargées ; elle ne prouve pas une manipulation native du sélecteur. Les fichiers auteur de la fixture sont comparés octet par octet avant/après l'export sans demande de sauvegarde.

Journaux conservés : [suite Studio](logs/studio-suite.log), [stress isolé](logs/studio-stress.log), [export et correction](logs/studio-export-correction.log), [frontières](logs/studio-architecture.log), [installation et jeu Player](logs/player-import-journey.log).

| Commande / preuve | Résultat |
| --- | --- |
| `cd apps/avelune_studio && flutter test --no-pub test/game_export test/map_workspace/story_zone_reopen_host_test.dart` | 19 tests passés sur les sources finales. |
| `cd apps/avelune_studio && flutter test --no-pub test/architecture/architecture_boundaries_test.dart test/architecture/dart_dependency_graph_test.dart` | 12 tests passés après séparation port/I/O. |
| `cd packages/map_authoring && dart test test/domains/distribution/game_package_export_api_test.dart` | 4 tests passés. |
| `cd packages/map_editor && flutter test --no-pub test/game_export/game_package_export_service_test.dart test/game_export/game_package_export_controller_test.dart` | 35 tests passés. |
| `cd apps/pokemap_hub && flutter test --no-pub test/features/installation/avelune_studio_export_player_e2e_test.dart test/features/installation/game_package_installer_test.dart test/features/session/installed_game_launch_resolver_test.dart` | 15 tests passés, dialogue puis arrivée `clairiere` aux coordonnées `(8, 9)`. |
| `cd apps/avelune_studio && flutter test --no-pub` | Deux passages parallèles : respectivement 877 et 878 réussites, 2 ignorés, 1 échec de délai sur `desktop_workspace_layout_test` (`E/S réelles ... en 20 secondes`). Le test passe isolé. |
| `cd apps/avelune_studio && flutter test --no-pub $(rg --files test \| rg '_test\\.dart$' \| rg -v '^test/presentation/desktop_workspace_layout_test\\.dart$')` | 880 réussites, 2 ignorés, aucun échec sur les sources finales. |
| `cd apps/avelune_studio && flutter test --no-pub test/presentation/desktop_workspace_layout_test.dart` | 1 test passé isolément en 24 s sur les sources finales. Tous les fichiers de test ont donc été exécutés. |
| `cd apps/avelune_studio && flutter analyze --no-pub` | Aucune remarque sur les sources finales. |
| `cd packages/map_authoring && dart analyze` | Aucune remarque. |
| `cd apps/pokemap_hub && flutter analyze --no-pub` | 1 information préexistante hors lot : import inutile dans `avelune_game_shelf.dart` ; aucun diagnostic du test ajouté. |
| `cd packages/map_editor && flutter analyze --no-pub` | 2 informations préexistantes hors lot : imports inutiles dans `cinematic_media_preview_controller_test.dart` et `selbrume_npc_state_commands_test.dart`. |
| `cd apps/avelune_studio && flutter build macos --debug --no-pub` | `build/macos/Build/Products/Debug/Avelune Studio.app` produit sur les sources finales. |
| `cd tools/pokemap_mcp && npm run check && npm test` | TypeScript sans erreur ; 83 tests du serveur MCP passés, dont `pokemap_game_export`. |
| `cd packages/map_authoring && dart run tool/pmcp085_conformance.dart` | Sortie 1 : 86 ressources, 360 actions, 0 contrat manquant/bloqué ; certification de transports globale incomplète (`transportCertificationComplete=false`). Ce constat global précède ce lot et n'a pas été masqué. |
| `cd packages/map_authoring && dart test test/parity/full_authoring_parity_test.dart` | 18 tests passés, dont parité direct API et JSONL/CLI. |
| `pokemap_describe` sur la connexion courante | Worker `code 78` à trois tentatives, y compris après la fin des suites. La lecture du catalogue **live** reste non prouvée malgré les tests du serveur empaqueté ; parité live `PARTIAL`. |

La tentative séquentielle intermédiaire a été interrompue après une modification de code ; aucun de ses résultats partiels n'est compté. La suite a ensuite été rejouée intégralement en deux partitions sur les sources finales.

État Git final : [git-status-final.txt](logs/git-status-final.txt) contient la sortie exacte de `git status --short --untracked-files=all`. L'arbre reste volontairement modifié et non indexé ; aucun commit, push, PR ou changement de branche n'a été effectué. `git diff --check` ne signale aucun espace fautif. `POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh` passe avec un nouveau rapport Markdown dans l'emplacement canonique.

## Passes et critique finale

- **Audit / architecture — conforme** : réemploi du service et des contrats canoniques ; aucun import des composants privés de l'ancien éditeur. La première passe de frontières a trouvé une fuite I/O vers l'application et la présentation ; elle a été corrigée par un port pur, un adaptateur local et l'injection du sélecteur.
- **Implémentation — conforme** : l'export part d'un état enregistré, appelle les propriétaires existants après choix explicite et refuse un mélange de révisions. L'écriture reste celle du service canonique.
- **Tests — conforme sur le parcours, réserve de charge sur la suite concurrente** : les cas positifs, refus, annulation, écriture échouée puis reprise, modification concurrente et paquet installé joué sont couverts ; aucun projet personnel n'est utilisé.
- **Build / validation — conforme avec réserves documentées** : voir les commandes exactes ci-dessus et les résultats finaux ci-dessous.
- **Critique finale — réserve non bloquante** : le chemin de sortie apparu pendant la construction a été ajouté au garde d'écrasement ; le choix de mode brut a été remplacé par `StudioSelect`. Risques restants : la suite concurrente peut saturer son test de stress, le sélecteur NSSavePanel n'a pas été piloté nativement, et une annulation pendant une sauvegarde propriétaire ne peut arrêter cette sauvegarde déjà lancée (le message l'annonce).

Les demandes UI05, catalogue d'objets, store, App Store, 3D et iOS/SPM restent hors périmètre. La parité MCP d'export utilise l'API existante ; aucun contrat d'authoring nouveau n'a été créé. Le ticket Notion reste sans modification conformément au mandat, donc sa projection de suivi n'est pas synchronisée.
