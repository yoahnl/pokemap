# AS-UI-009 — Éditeur de dialogue

Livraison du 20 septembre 2026. Validation visuelle utilisateur encore attendue ; aucune autre page commencée.

## Résultat et accès

Depuis **Histoire → Dialogues**, ouvrir ou créer un dialogue. Depuis UI06, sélectionner un bloc de dialogue puis **Ouvrir le dialogue** : UI09 retrouve son document partagé et son point de départ. **Retour à la scène** conserve le brouillon, la sélection et le contexte supérieur, notamment Histoire UI07 ou Événements UI08.

La page permet de créer, dupliquer, renommer et supprimer un dialogue avec les gardes de référence ; écrire des répliques et narrations ; ajouter, réordonner et relier des réponses ; choisir les portraits disponibles ; déclarer et affecter des résultats publics ; essayer chaque branche ; annuler/rétablir ; publier et rouvrir. Les conséquences de jeu restent dans les scènes. Le renommage seul d'un événement conserve maintenant son activation.

Lancement depuis le dépôt :

```sh
cd apps/avelune_studio
flutter run -d macos
```

Utiliser un projet de travail ou une copie. Les recettes de cette livraison créent exclusivement des fixtures temporaires et ne modifient aucun projet personnel original.

## Audit initial, périmètre et décisions

État initial : branche `main`, HEAD `8ce12d4535dd8f9f9100ff63d0973ff622bf937c`, arbre de travail propre. Le pack UI09, ses références et annexes ont été lus ; la maquette `kit/Avelune_Studio_Narrative_Kit_v1/ecrans/05_editeur_de_dialogue/MAQUETTE.png` a été ouverte avant l'implémentation et à la comparaison finale.

L'audit a identifié le document structuré, le codec Yarn et la validation de l'ancien éditeur, le compilateur authoring existant, les transactions de publication, les sessions narratives simples, les brouillons de scènes et leurs contextes imbriqués. Les risques principaux étaient la double propriété des brouillons, la perte de source avancée, les publications source/métadonnées désynchronisées, l'invalidation des résultats de scène et la perte du champ encore focalisé.

Le modèle, le codec et la validation purs ont été déplacés vers `map_authoring`, avec réexport depuis leurs anciens chemins. Il n'existe pas une deuxième implémentation du dialogue. Aucune dépendance, configuration native, police, moteur runtime ou identité visuelle n'a été remplacé. Les trois fichiers historiques extraits restent exceptionnellement au-delà de 300 lignes : extraction à comportement testé, sans copie concurrente ni refonte hors périmètre. Les nouveaux fichiers Studio respectent la limite d'architecture.

Le mandat direct impose zéro commentaire ajouté au code écrit manuellement, contrairement à la règle générale de `codex_rule.md` : le mandat a priorité. Il impose également zéro écriture Git et Notion ; ces interdictions ont été respectées.

## Composition et comparaison visuelle

[Composition finale](captures/01-composition-complete.png) — [première capture](captures/ui09-dialogue-early-1536.png).

La composition reprend la navigation Avelune, la bibliothèque verticale à gauche, le graphe quadrillé dominant, l'inspecteur à droite et le test de conversation sous le graphe. Entrée et sélection bleu vif, suites violettes, connexions cyan et résultats verts différencient les éléments. Le logo approuvé et les composants du cadre existant sont conservés.

À la demande de l'utilisateur pendant la vérification finale, la palette initiale trop désaturée a été renforcée : bleu `#1262FF`, violet `#7952FF`, cyan `#00C8FF`, vert `#00DDB0`, panneaux bleu nuit `#031C30` et canvas `#001626`. Ces valeurs sont des tokens dans `StudioDialogueTheme`, limité à UI09 ; aucun recoloriage des pages UI05–08. Les cartes utilisent un accent optionnel du composant partagé et des en-têtes plus contrastés. Il s'agit d'une reprise des familles de couleurs de la référence, sans prétendre à une égalité pixel par pixel.

Les premiers essais ont révélé des ports mal ciblés après zoom, un débordement de ligne de résultat et une perte du champ lors du changement d'onglet. Le calcul géométrique, la hauteur des réponses et la validation des champs avant fermeture ont été corrigés puis testés. La revue a aussi conduit à confirmer explicitement le remplacement d'un lien, annuler un fil devenu périmé et gérer Cmd/Ctrl+S depuis un champ.

Adaptations assumées : les blocs illustratifs d'action/condition ne deviennent pas un second moteur ; les résultats publics remplacent ces conséquences dans le dialogue. La sélection d'une version fictive, les variables de test non prises en charge, les effets de texte et les notes décoratives ne sont pas présentés comme des fonctions disponibles. L'aperçu montre les répliques et choix compilés, sans inventer un décor de carte. La bibliothèque ne charge pas tous les documents pour fabriquer des compteurs ou portraits.

Les captures montrent de vrais widgets Flutter hors écran, sans retouche. Le personnage géométrique est un véritable PNG de fixture temporaire, lu par le port de portraits et affiché dans le graphe, l'inspecteur et l'aperçu ; ce n'est ni un portrait artistique livré au produit ni une extraction de la maquette.

| Preuve | Capture |
| --- | --- |
| Composition complète | [01](captures/01-composition-complete.png) |
| Fil pendant un geste réel | [02](captures/02-connexion-en-cours.png) |
| Texte, locuteur et portrait disponible | [03](captures/03-inspecteur-portrait.png) |
| Réponse Partir et résultat | [04 départ](captures/04-apercu-depart.png) |
| Réponse Attendre et résultat | [04 attente](captures/04-apercu-attente.png) |
| Retour au brouillon de scène | [05](captures/05-retour-scene-brouillon.png) |
| Point de départ inexistant, diagnostic | [06](captures/06-depart-absent-diagnostic.png) |
| 1024 × 640, texte 150 %, panneaux repliés | [07](captures/07-compact-150.png) |
| Édition et sauvegarde à 1440 × 900 | [responsive 1440](captures/responsive-1440x900-100.png) |
| Édition et sauvegarde à 1280 × 800 | [responsive 1280](captures/responsive-1280x800-100.png) |
| Inspecteur compact, texte 150 %, sauvegarde accessible | [responsive 1024](captures/responsive-1024x640-150.png) |

Le cadrage intégral du graphe compact réduit les cartes ; la page et le facteur de texte ne sont pas réduits. Le zoom et l'inspecteur donnent accès au texte. Cette capture ne prétend pas rendre chaque réplique lisible au zoom de cadrage 37 %.

## Garanties fonctionnelles

- Le document canonique reste la vérité. Graphe, coordonnées, zoom et sélection sont des projections de session ; aucune syntaxe parallèle ni sidecar n'est publié.
- Ouvrir, sélectionner, déplacer, zoomer et consulter Yarn n'écrit pas le projet. La bibliothèque charge la source à la demande.
- Une source que le modèle graphique ne peut représenter fidèlement reste en consultation avec diagnostic. La consultation et les opérations refusées ne normalisent pas sa source.
- Un résultat est émis par une réponse. Le compilateur existant ne transporte pas un `outcome` placé à la racine d'une suite : UI09 refuse précisément cette forme au lieu d'afficher un faux succès. Le moteur n'a pas été étendu.
- La publication vérifie les révisions fraîches, les références de départ et les consommateurs ; les écritures source/manifeste restent transactionnelles. Les imports indépendants et les documents sans modification sont préservés.
- Les sessions complètes et interactions simplifiées partagent les notifications de publication et les gardes de brouillon. Une session simple ne peut écraser un dialogue complet ou sale. Une révision tardive du dialogue A ne remplace pas le dialogue B actif.
- Les nouveaux résultats actualisent les ports des scènes ouvertes sans sauvegarder leur brouillon. Les suppressions incompatibles avec des consommateurs enregistrés ou ouverts sont refusées.
- La validation d'un champ encore focalisé précède sauvegarde, annulation et changement de panneau. Une valeur refusée revient à la valeur réelle avec diagnostic ; la sauvegarde déclenchée par ce refus n'écrit rien.
- L'aperçu utilise la compilation canonique, attend un choix explicite et borne les boucles à 512 opérations. Un départ manquant produit un diagnostic.

## Correctif UI08

Dans `EventWorkspaceCommands.rename`, la mutation de métadonnées appelle désormais `_edit(..., disable: false)`. Les autres éditions conservent leur protection de désactivation. Le défaut a été reproduit avant correction : [rouge](logs/rename-ui08-red.txt), puis [vert](logs/rename-ui08-green.txt), et de nouveau couvert par [la recette finale](logs/runtime-rename-final.txt).

Les tests couvrent événement actif, désactivé, nom inchangé, annulation/rétablissement, sauvegarde/réouverture et conservation du mode et des autres champs. Le correctif ne change pas la publication différée UI08.

## Vérifications et journaux

Les commandes Flutter ont été exécutées via `/tmp/avelune_design_run.py`, qui enregistre le PID du runner, les descendants avec leur identité et le nettoyage des seuls processus attribuables au run. Les fichiers JSON voisins des journaux contiennent commande exacte, code de sortie, propriété et nettoyage. Aucun arrêt global de processus de test n'a été utilisé.

Les lignes ci-dessous sont des résultats réellement observés, pas un total à additionner : plusieurs sélections se recouvrent.

| Périmètre | Résultat exact final ciblé | Journal |
| --- | --- | --- |
| Controller UI09 et régressions narrative | `00:08 +67: All tests passed!` | [controller-final.txt](logs/controller-final.txt) |
| Adaptateur, portraits, publication et garde UI08 | `00:02 +16: All tests passed!` | [dialogue-adapter-final.txt](logs/dialogue-adapter-final.txt) |
| Publication canonique directe/JSONL | `00:01 +13: All tests passed!` | [dialogue-canonical.txt](logs/dialogue-canonical.txt) |
| Modèle partagé | `00:00 +3: All tests passed!` | [shared-dialogue-model.txt](logs/shared-dialogue-model.txt) |
| Consommateur ancien éditeur | `00:00 +20: All tests passed!` | [shared-editor-regressions.txt](logs/shared-editor-regressions.txt) |
| Runtime, renommage et fixture | `00:12 +11: All tests passed!` | [runtime-rename-final.txt](logs/runtime-rename-final.txt) |
| Gestes, focus, connexions et navigation | `00:47 +13: All tests passed!` | [widget-final-captures.txt](logs/widget-final-captures.txt) |
| Recapture de l'aperçu des deux résultats | `All tests passed!`, 1 test | [widget-preview-final.txt](logs/widget-preview-final.txt) |
| Architecture Studio après correction | `All tests passed!`, 7 tests | [architecture-final.txt](logs/architecture-final.txt) |
| Volume du graphe | `00:03 +1: All tests passed!` | [volume-widget.txt](logs/volume-widget.txt) |
| MCP compilé et contrôle TypeScript | codes 0 | [build](logs/mcp-build.txt), [check](logs/mcp-check.txt) |
| Publication Yarn par transport MCP empaqueté | 1 test réussi, code 0 | [mcp-dialogue-publication.txt](logs/mcp-dialogue-publication.txt) |

Commandes ciblées principales, dans `apps/avelune_studio` :

```sh
flutter test --no-pub --reporter expanded test/dialogues/dialogue_controller_ui09_test.dart test/dialogues/dialogue_concurrency_ui09_test.dart test/dialogues/dialogue_coexistence_ui09_test.dart test/dialogues/dialogue_preview_ui09_test.dart test/narrative
flutter test --no-pub --reporter expanded test/dialogues/dialogue_adapter_ui09_test.dart test/dialogues/dialogue_publication_guards_ui09_test.dart test/dialogues/dialogue_portrait_ui09_test.dart test/narrative/interaction_event_roundtrip_ui08_test.dart
flutter test --no-pub --concurrency=1 --reporter expanded test/events/event_rename_ui09_test.dart test/events/event_workspace_ui08_test.dart test/events_runtime_ui09_dialogue_test.dart test/events_ui09_dialogue_fixture_test.dart
flutter test --no-pub --concurrency=1 --reporter expanded test/dialogues_ui09_visual_test.dart test/dialogues_ui09_interaction_test.dart test/dialogues_ui09_navigation_test.dart test/dialogues_ui09_nested_navigation_test.dart test/dialogues_ui09_safety_test.dart
flutter test --no-pub --reporter expanded test/dialogues_ui09_volume_test.dart
```

Dans `packages/map_authoring` :

```sh
dart test --reporter expanded test/domains/narrative/dialogue_atomic_update_test.dart test/domains/narrative/dialogue_script_authoring_test.dart test/domains/narrative/narrative_document_publication_test.dart
dart test --reporter expanded test/dialogue/dialogue_document_ui09_test.dart
```

Dans `packages/map_editor` :

```sh
flutter test --no-pub --reporter expanded test/dialogue_yarn_codec_test.dart test/dialogue_editor_validation_test.dart test/dialogue_document_session_integration_test.dart
```

Dans `tools/pokemap_mcp` :

```sh
npm run build
npm run check
node --import tsx --test --test-concurrency=1 --test-name-pattern 'packaged MCP publishes source' test/studio_narrative_publication.test.ts
```

Analyses ciblées : `No issues found` pour controller/tests, modèle partagé, adaptateur/port, actions canoniques et les 12 fichiers runtime/widget/rename. Les commandes et sélections exactes figurent dans [les reçus JSON](logs/).

### État final global

Suite complète Studio : `flutter test --no-pub --concurrency=1 --reporter expanded`, code 0, ligne finale **`07:12 +526 ~2: All tests passed!`** dans [studio-full-final.txt](logs/studio-full-final.txt). Les deux tests ignorés sont `infrastructure/studio_large_atlas_test.dart` et `presentation/train_workspace_capture_test.dart`, faute de variable `AVELUNE_PROJECT_COPY`. Aucune copie de projet personnel n'a été utilisée pour lever ces skips.

Cette suite a commencé avant la retouche finale des couleurs. Les derniers fichiers sont compilés au fur et à mesure par Flutter : elle n'est donc pas revendiquée comme un snapshot immuable de la palette finale. Les ciblages widgets, responsive, architecture, analyse et build sont rejoués ensuite sur l'état final ; leurs résultats sont consignés ci-dessous. La logique du document, des transactions et du runtime n'a pas changé après la suite complète.

Après la retouche de palette :

- `flutter analyze --no-pub` : code 0, **`No issues found! (ran in 6.1s)`**, [journal](logs/final-state-analyze.txt).
- `flutter build macos --debug --no-pub` : code 0, **`✓ Built build/macos/Build/Products/Debug/Avelune Studio.app`**, [journal](logs/macos-build-final.txt).
- Architecture et composants partagés : code 0, **`00:03 +18: All tests passed!`**, [journal](logs/palette-architecture-widgets.txt).
- Les 13 tests widgets/navigation/sécurité ont repassé sur la palette finale. Le nouveau test de redimensionnement 1280 × 800 a d'abord sélectionné une réponse derrière l'aperçu après conservation du viewport. La recette a été corrigée pour utiliser le véritable bouton « Cadrer le dialogue » avant sélection, sans changement produit ; [premier run responsive](logs/widget-final-palette-responsive.txt).
- `flutter test --no-pub --concurrency=1 --reporter expanded test/dialogues_ui09_responsive_test.dart` : code 0, **`00:14 +3: All tests passed!`**, [journal final](logs/widget-responsive-final.txt). Chaque taille vérifie deux publications réelles, la relecture du texte et de la réponse sur disque, ainsi que la conservation du saut et du résultat. Analyse de ce test : `No issues found!`.
- Contrôle de format final sur les 93 fichiers Dart modifiés/créés : **`Formatted 93 files (0 changed) in 0.24 seconds.`**, code 0. Cinq fichiers ont seulement été reformattés après le build et la suite : publication narrative, en-tête Histoire, compilateur authoring, codec extrait et test d'interaction. Aucun changement sémantique après les vérifications finales.

La première suite `studio-full.txt` n'est **pas une preuve de succès** : trois échecs d'architecture puis interruption sur un problème du harness de portraits. Le contrôle d'architecture et le harness ont été corrigés ; les journaux intermédiaires et celui de l'arrêt sont conservés. Un code 0 du wrapper après interruption ne signifie pas que cette suite a réussi.

### Runtime et performance

La recette publie le Yarn canonique dans une fixture temporaire, déclenche un véritable événement `mapEnter`, exécute le dialogue dans le runtime existant puis choisit réellement chacune des deux réponses. Les résultats conduisent à deux suites de scène et faits du monde distincts, observables et exclusifs. Les empreintes des sources ne changent pas pendant l'exécution. Il s'agit d'une recette automatisée du runtime, pas d'une vidéo d'une fenêtre native.

Le test de volume utilise 40 suites, 200 répliques et 50 liens. Huit gestes de vue/sélection donnent une lecture de source au total, zéro compilation supplémentaire et neuf constructions de page (initiale + huit sélections). Le snapshot sémantique reste identique et non modifié. Ce contrôle ne prétend pas mesurer une fréquence d'affichage ou une consommation mémoire native.

### Limites de certification

- Préflight natif exécuté : outil Flutter/macOS disponible, instrumentation et dépendances Marionette absentes. Aucun ajout de pile native. Les captures sont donc des widgets réels hors écran ; le build macOS n'est pas présenté comme une recette native manipulée.
- Le MCP empaqueté est testé, mais le connecteur MCP vivant renvoie toujours `worker.exited`, code 78, dans [le reçu](logs/mcp-live-describe.json). La parité du connecteur vivant reste **PARTIAL**. Elle n'est pas déduite des tests directs ou JSONL.
- Aucune exécution des suites complètes de tous les autres packages : seuls les consommateurs des contrats modifiés sont ciblés, conformément au budget du lot.

## Inventaire des fichiers et zones

Les chemins ci-dessous sont relatifs au dépôt. Les fichiers listés dans une même ligne ont la responsabilité indiquée ; les sources et `git diff` restent la preuve, sans copie intégrale du code.

### Application et données Studio

Préfixe `apps/avelune_studio/lib/` :

| Fichiers | Zone, raison et impact |
| --- | --- |
| `app/di/dialogue_providers.dart`, `app/di/providers.dart`, `app/studio_bootstrap.dart`, `presentation/shell/studio_workspace_host.dart` | Port dialogue optionnel puis injection de l'adaptateur local dans le workspace réel. |
| `features/dialogues/domain/dialogue_port.dart` | Lecture, publication révisionnée et portraits en octets ; frontière pure sans accès fichier en présentation. |
| `features/dialogues/data/local_dialogue_adapter.dart` | Chargement à la demande, lecture des portraits autorisés et publication par session existante. |
| `features/dialogues/data/local_dialogue_transaction.dart` | Garde de révision et transaction source/manifeste, reprise et chemins limités. |
| `features/dialogues/application/dialogue_edit_session.dart` | Snapshot immuable, révisions et historique par dialogue. |
| `features/dialogues/application/dialogue_workspace_controller.dart` | Bibliothèque, propriété des sessions, notifications et document actif. |
| `features/dialogues/application/dialogue_workspace_commands.dart` | Répliques, locuteurs, réponses et résultats sur le modèle partagé. |
| `features/dialogues/application/dialogue_workspace_structure.dart` | Création/duplication/suppression/réorganisation des suites et éléments. |
| `features/dialogues/application/dialogue_workspace_links.dart` | Connexion, remplacement et suppression de liens canoniques. |
| `features/dialogues/application/dialogue_workspace_validation.dart` | Fidélité graphique, références, sources avancées et refus explicites. |
| `features/dialogues/application/dialogue_workspace_publication.dart` | Sauvegarde, renommage, duplication, suppression et publication du snapshot propriétaire. |
| `features/dialogues/application/dialogue_preview_state.dart` | Exécution de l'aperçu à partir de la compilation, choix explicite, boucle bornée. |
| `features/map_workspace/data/local_map_workspace_adapter.dart`, `features/map_workspace/data/local_map_workspace_catalog.dart` | Rafraîchissement frais du catalogue sous mutex, sans remplacer les brouillons de carte. |
| `features/narrative/application/narrative_interaction_loading.dart` | Garde avant ouverture d'une interaction simplifiée sur dialogue possédé. |
| `features/narrative/application/narrative_session_coexistence.dart` | Invalidation réciproque des sessions propres et protection des sessions modifiées. |
| `features/narrative/application/narrative_workspace_controller.dart` | Registre de propriété des dialogues complets et notifications de publication. |
| `features/narrative/application/narrative_workspace_publication.dart` | Notification après publication simple, actualisation des consommateurs. |
| `features/scenes/application/scene_dialogue_results.dart` | Mise à jour des résultats attendus dans les seuls brouillons de scène concernés. |
| `features/events/application/event_workspace_commands.dart` | `rename` : `disable: false`, seule exception ajoutée à la garde d'activation. |

### Présentation Studio

Préfixe `apps/avelune_studio/lib/presentation/` :

| Fichiers | Zone, raison et impact |
| --- | --- |
| `features/dialogues/dialogue_workspace_page.dart` | Composition responsive, panneaux et raccourcis sauvegarde. |
| `features/dialogues/dialogue_page_commands.dart` | Gestes sémantiques, flush du focus, confirmations protégées par propriétaire/révision. |
| `features/dialogues/dialogue_view_state.dart` | Sélection, positions, viewport et filtres en mémoire par dialogue. |
| `features/dialogues/dialogue_library.dart` | Recherche, dossiers, liste paresseuse et création. |
| `features/dialogues/dialogue_document_toolbar.dart`, `features/dialogues/dialogue_add_toolbar.dart` | Actions de document et ajout de contenu. |
| `features/dialogues/dialogue_graph_geometry.dart` | Projection des suites, réponses, ports et lignes. |
| `features/dialogues/dialogue_graph_canvas.dart` | Pan/zoom, déplacement, geste de connexion et annulation des gestes périmés. |
| `features/dialogues/dialogue_graph_node.dart` | Répliques, réponses, résultat lisible et portrait réel. |
| `features/dialogues/dialogue_graph_painter.dart` | Grille, connexions, flèches et sélection des fils. |
| `features/dialogues/dialogue_graph_controls.dart` | Zoom, cadrage et minicarte navigable. |
| `features/dialogues/dialogue_inspector.dart` | Édition contextuelle et onglets Propriétés/Aperçu/Yarn. |
| `features/dialogues/dialogue_results_panel.dart` | Déclaration et renommage des résultats publics, sans actions de jeu. |
| `features/dialogues/dialogue_suite_actions.dart` | Départ, duplication et test depuis la suite sélectionnée. |
| `features/dialogues/dialogue_portrait_fields.dart`, `features/dialogues/dialogue_portrait_image.dart` | Sélection dans le catalogue réel et chargement d'octets via le port. |
| `features/dialogues/dialogue_preview_panel.dart` | Ligne courante, choix explicites et résultats émis. |
| `features/map_workspace/map_workspace_screen.dart` | Cycle de vie du controller/dialogue et conservation du contexte. |
| `features/map_workspace/workspace_dialogue_binding.dart` | Entrée depuis Histoire/UI06, retour imbriqué et résultats publiés. |
| `features/map_workspace/workspace_actions.dart` | Fermeture, sauvegarde globale et playtest protègent le dialogue modifié. |
| `features/map_workspace/workspace_home_binding.dart` | Validation du texte avant retour Accueil. |
| `features/map_workspace/workspace_screen_body.dart`, `features/map_workspace/workspace_secondary_content.dart` | Passage des dépendances et routage de l'espace Dialogue. |
| `features/map_workspace/workspace_story_binding.dart` | Raccourci de sauvegarde du dialogue actif. |
| `features/narrative/narrative_overview_header.dart`, `features/narrative/narrative_story_pane.dart` | Accès Dialogues dans Histoire, y compris compact. |
| `features/scenes/scene_builder_page.dart` | Ouverture de UI09 pour un véritable payload dialogue, sans convertir la scène. |
| `features/scenes/scene_linked_document.dart` | Résolution du document source depuis le snapshot partagé à jour. |
| `shared/widgets/inputs/studio_commit_field.dart` | Variante `tryCommit` : valeur rejetée rétablie, anciens appels conservés. |
| `shared/widgets/layout/studio_graph_card.dart` | Accent optionnel de carte pour les bordures et fonds colorés UI09 ; comportement antérieur conservé sans argument. |
| `shared/widgets/layout/studio_primary_navigation.dart` | Dialogue reste sous l'entrée Histoire. |
| `theme/studio_dialogue_theme.dart` | Tokens et thème bleu/violet/cyan limités à UI09 ; autres pages et thème clair inchangés. |

### Contrats et modèle partagés

Préfixe `packages/map_authoring/` :

| Fichiers | Zone, raison et impact |
| --- | --- |
| `lib/map_authoring_dialogue.dart` | API publique du modèle/codec pur. |
| `lib/src/dialogue/dialogue_editor_model.dart`, `lib/src/dialogue/dialogue_editor_validation.dart`, `lib/src/dialogue/dialogue_yarn_codec.dart` | Extraction de l'implémentation existante ; chaînes littérales et roundtrip fidélisés dans le codec. |
| `lib/src/dialogue/dialogue_document_identity.dart` | Réconciliation des identités d'édition après décodage. |
| `lib/src/dialogue/dialogue_document_snapshot.dart` | Copie immuable profonde pour historique et publication. |
| `lib/src/domains/narrative/dialogue_actions.dart` | Source optionnelle dans la mise à jour canonique, transaction atomique et validation des consommateurs. |
| `lib/src/domains/narrative/dialogue_authoring_service.dart` | Diagnostic d'un résultat hors choix que le runtime ne transporte pas. |
| `lib/src/domains/narrative/dialogue_source_guards.dart` | Vérification des points de départ référencés par les scènes. |
| `lib/src/domains/narrative/narrative_document_actions.dart` | Validation des références lors de la publication d'un document de scène. |
| `test/dialogue/dialogue_document_ui09_test.dart` | Immutabilité, codec et identité du modèle extrait. |
| `test/domains/narrative/dialogue_atomic_update_test.dart` | Source/manifeste atomiques, références et transport JSONL. |

Les trois fichiers `packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_model.dart`, `dialogue_editor_validation.dart` et `dialogue_yarn_codec.dart` deviennent des réexports du code extrait. Leurs consommateurs existants restent couverts par 20 tests de régression.

### Tests et fixtures Studio

Préfixe `apps/avelune_studio/test/` :

| Fichiers | Garanties |
| --- | --- |
| `dialogues/dialogue_adapter_ui09_test.dart`, `dialogues/dialogue_publication_guards_ui09_test.dart`, `support/dialogue_adapter_fixture.dart` | Publication, conflits, rollback, indépendance des ressources et absence d'écritures de consultation. |
| `dialogues/dialogue_portrait_ui09_test.dart` | Portraits réellement disponibles et limites de lecture. |
| `dialogues/dialogue_controller_ui09_test.dart` | Opérations, historique, sauvegarde et réouverture. |
| `dialogues/dialogue_concurrency_ui09_test.dart` | Réponse tardive, changement de document et propriétaire du snapshot. |
| `dialogues/dialogue_coexistence_ui09_test.dart` | Partage des brouillons, consommateurs multiples, sources opaques, gardes et invalidation. |
| `dialogues/dialogue_preview_ui09_test.dart` | Aperçu canonique, départ invalide, choix et boucle bornée. |
| `dialogues_ui09_visual_test.dart` | Captures des vrais widgets et format compact. |
| `dialogues_ui09_responsive_test.dart` | Édition réelle de réplique et réponse avec sauvegarde aux tailles 1440 × 900, 1280 × 800 et 1024 × 640 à texte 150 %. |
| `dialogues_ui09_interaction_test.dart` | Focus, sauvegarde, undo, aperçu et fils par gestes à plusieurs zooms. |
| `dialogues_ui09_navigation_test.dart`, `dialogues_ui09_nested_navigation_test.dart` | Retours UI06, UI07 et UI08, brouillons conservés. |
| `dialogues_ui09_safety_test.dart` | Champ rejeté sans écriture, annulation du texte, remplacement confirmé, fil périmé, Cmd/Ctrl+S et onglet Yarn. |
| `dialogues_ui09_volume_test.dart` | Volume et absence de relecture/recompilation pendant les gestes de vue. |
| `events/event_rename_ui09_test.dart`, `events/event_workspace_ui08_test.dart` | Régression de renommage et gardes d'activation préservées. |
| `events_runtime_ui09_dialogue_test.dart`, `events_ui09_dialogue_fixture_test.dart` | Deux chemins réels runtime, publication et réouverture indépendante. |
| `support/ui09_dialogue_fixture.dart`, `support/ui09_dialogue_harness.dart`, `support/ui09_runtime_fixture.dart` | Projets temporaires, portraits PNG et montage des vrais widgets/runtime. |
| `support/ui08_workspace_harness.dart` | Injection optionnelle du port dialogue pour tester les retours imbriqués. |

Le dossier de livraison contient ce seul rapport Markdown, les captures PNG et les journaux/reçus JSON. Les essais rouges et interrompus sont gardés pour tracer les corrections, sans les mélanger aux résultats finaux.

## Revue indépendante et auto-critique

| Passe / propriétaire | Verdict |
| --- | --- |
| Audit / architecture — root et `ui08_coexistence` | Réemploi du document/codec/compilateur justifié ; pas de moteur dialogue parallèle. Sources avancées et frontières explicites. |
| Implémentation / transactions — `ui08_events_backend` | Publication atomique, conflits et gardes testés ; aucun moteur partagé refait. |
| Modèle / coexistence — `ui08_coexistence` | 67 tests controller/narrative, 3 modèle et 20 ancien éditeur réussis ; aucun blocage identifié à la dernière revue ciblée. |
| Tests / runtime — `ui08_runtime_proof` | Défaut UI08 reproduit, deux résultats runtime et retours imbriqués prouvés ; captures honnêtement hors écran. |
| Build / validation — `ui08_events_backend` | Suite 526 réussis / 2 ignorés ; palette finale : 18 tests architecture/composants, analyse sans problème et build macOS réussi. |
| Critique finale — `ui08_coexistence`, `ui08_runtime_proof`, root | Les défauts de focus, port après zoom, remplacement, résultat débordant et geste périmé ont été corrigés avec tests. Validation esthétique utilisateur encore ouverte. |

Limites conservées : l'onglet Yarn est en consultation ; les commandes avancées non fidèlement représentables ne sont pas éditées graphiquement ; disposition/zoom ne persistent pas après redémarrage de l'application ; la création depuis la bibliothèque ne rattache pas automatiquement le nouveau document à un bloc de scène ; les réserves antérieures de progression UI07 ne sont ni corrigées ni closes par UI09.

L'écart artistique le plus visible avec le kit reste le média de fixture géométrique et un aperçu sobre sans décor de jeu. La bibliothèque privilégie les métadonnées réellement disponibles. La vue compacte demande du zoom ou l'inspecteur pour lire un graphe cadré en entier. Les tests automatisés ne remplacent pas la validation visuelle et native de l'utilisateur.

État Git final : branche `main`, HEAD initial inchangé `8ce12d4535dd8f9f9100ff63d0973ff622bf937c`. Les 93 fichiers Dart modifiés/créés sont inventoriés ci-dessus ; les autres ajouts sont les preuves UI09 et ce rapport. Les modifications restent locales et non indexées. `git diff --check` : code 0, aucune sortie. `POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh` : code 0, `Markdown hygiene: 1 new Markdown file(s), all in canonical locations.` L'exception d'un fichier correspond au rapport explicitement demandé par le pack.

Aucun commit, push, changement de branche ou ticket Notion effectué. Prochaine étape : validation visuelle de cette page seulement.
