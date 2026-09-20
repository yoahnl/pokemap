# AS-UI-006 — Éditeur de scène graphique

Livraison locale du 20 septembre 2026. Validation visuelle de Yoahn encore attendue. Aucun commit, push, changement Notion ou changement d’un projet personnel.

## Audit initial et périmètre

État initial propre, branche `main`, HEAD `af133be2ae96d82c914d535e3502305ef078c45a`. Lecture de `PROMPT_CODEX.md`, `REFERENCES_VISUELLES.md`, annexes 01–03, guides 01–04, README du kit et fiche de l’écran 03. La vraie `03_editeur_de_scene/MAQUETTE.png` a été ouverte avant développement et reprise pendant la comparaison.

Le dépôt possède déjà les modèles `SceneAsset`, les ports calculés depuis les payloads, les opérations de graphe, le compilateur/aperçu de chemin, l’exécuteur runtime et la mutation canonique `scene.upsert`. Le port narratif de Studio publiait avec une carte : il ne suffisait pas à enregistrer une scène indépendante. Une projection d’interaction simplifiée pouvait également conserver une ancienne base de scène. Ce sont les deux raccordements structurants du lot.

L’interface reste dans `presentation/features/scenes`, les sessions dans `features/scenes/application`, le port dans `domain`, la transaction dans `data`. Aucun nouveau moteur, format ou stockage parallèle de brouillon. Accueil, Carte, Ressources et Terrains ne sont pas refaits.

## Ce qui est livré

- Histoire → Scènes ; accès direct depuis une interaction avancée vers sa scène exacte. Bibliothèque réelle, recherche, scènes homonymes conservées par identité, création et brouillons multiples.
- Palette cliquable et glissable ; ajout au centre ou au point déposé ; menu contextuel de création depuis une sortie ; paramètres canoniques dans l’inspecteur.
- Graphe manipulable : déplacement, sélection de bloc et de courbe, connexion avec cible compatible, déconnexion, duplication, suppression, annulation/rétablissement, annulation d’un geste. Un déplacement fait une seule entrée d’historique.
- Vue indépendante du document : pan, zoom ancré, cadrage, mini-carte, panneaux repliables. L’historique conserve 64 commandes, selon la convention des terrains.
- Noms et résultats publics éditables, références guidées, conditions booléennes/entières/texte, actions existantes. Un payload avancé ou une référence manquante n’est jamais remplacé silencieusement.
- Consultation du dialogue exact, y compris le brouillon déjà ouvert, choix du départ Yarn et retour au même bloc/cadrage ; consultation de la vraie cinématique sans nouvelle timeline.
- Prévisualisation avec décisions explicites, attente d’entrée, trace de blocs et fils, invalidation après mutation. Le bouton de jeu n’apparaît que si une interaction de la carte active référence la scène ; son infobulle annonce la sauvegarde des scènes, de la carte et de ses interactions.
- Publication ciblée via `scene.upsert` et transaction existante, réouverture indépendante depuis les fichiers, conflits et interruptions d’écriture gérés sans faux état propre.
- Protection réciproque entre graphe complet et interaction simplifiée : blocage des bases incompatibles, invalidation des sessions propres périmées, conservation des brouillons sans rapport. La fermeture du projet connaît les scènes modifiées.

## Réutilisation et écarts explicites à la maquette

| Élément | Réutilisation / adaptation |
| --- | --- |
| Début, Fin, Dialogue, Condition, Action, Combat, Cinématique, Présentation, Branchement, Convergence | Types et opérations canoniques ; pas de catégories fictives persistées |
| Objet, état, événement et autres commandes | Formulaire du bloc Action utilisant les descripteurs et constructeurs existants ; les cibles absentes du catalogue ne sont pas inventées |
| Constructeur de payload de commande | Extraction pure depuis `map_editor` vers `map_core`, réexportée par l’ancien service ; comportements existants vérifiés |
| Texte/choix de dialogue dans la maquette | Aperçu du document canonique ; aucune copie éditable concurrente |
| Variables et journal permanents | Sélecteur de faits dans l’inspecteur ; aperçu de chemin ouvert à la demande, repliable |
| Commentaire, sous-scène, faux compte/thème/versions | Non inventés lorsque le contrat ne les propose pas |
| Tester depuis un bloc arbitraire | Non proposé ; le vrai lancement réutilise le contexte carte/événement disponible |

La composition conserve le cadre Avelune, Histoire sélectionné, une bibliothèque gauche, un canvas dominant et l’inspecteur droit. Les premiers rendus révélaient une scène trop étalée et des débordements à 150 %. Le placement de la fixture, les ports et leurs étiquettes, le format compact et la typographie des blocs ont été corrigés. La page n’est pas une reproduction pixel pour pixel : les personnages décoratifs et contrôles sans contrat de la maquette ne sont pas simulés.

## Captures exécutées

Ce sont des **rendus hors écran des vrais widgets Flutter**, sans retouche. Ils ne certifient pas une session native interactive. Les données proviennent d’un projet temporaire publié par les adaptateurs réels.

1. [Scène complète](01-scene-complete.png), 1536 × 1024.
2. [Fil et cible compatible](02-fil-cible-compatible.png), geste réel avant annulation.
3. [Inspecteur et dialogue réel](03-propriete-document.png).
4. [Chemin et entrées explicites](04-chemin-entrees-explicites.png).
5. [Format compact à 150 %](05-compact-texte150.png), 1024 × 640 ; les deux panneaux sont aussi ouverts et refermés dans le test.
6. [Retour du document lié](06-retour-document.png), scène et sélection intactes.

Les formats 1440 × 900 et 1280 × 800 sont également parcourus sans exception de layout.

## Recette et vérifications

La recette de construction commence par une nouvelle scène et utilise la palette, les champs, les sorties et les entrées à la souris : **8 blocs et 7 fils**. Elle publie par le vrai adaptateur, ferme la session puis relit le document avec un lecteur indépendant. Le test ne se limite pas à afficher la fixture des captures.

Les tests de sessions couvrent historique, commande composée refusée sans mutation partielle, snapshot stable de sauvegarde, réponse tardive, blocages réciproques et session simplifiée périmée. Les tests de publication couvrent scène sans carte, import concurrent conservé, carte inchangée, révision externe, graphe incomplet refusé, échec d’écriture et récupération transactionnelle. Les tests d’inspecteur vérifient notamment que changer de dialogue conserve les liens incompatibles avec un diagnostic, au lieu de les supprimer.

L’exécuteur existant parcourt Non puis Oui : dialogue de refus et résultat attente sans autorisation ; dialogue d’accord, conséquence canonique et résultat embarquement. Une variante cinématique utilise également le runtime existant. La prévisualisation seule n’est pas présentée comme cette preuve.

Commandes depuis `apps/avelune_studio` :

```sh
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build macos --debug --no-pub
```

Les tests Flutter ont été lancés par un wrapper local qui relève le PID du runner et ses descendants, vérifie leur identité puis ne termine que ses éventuels enfants restants. Les sorties finales et les reçus synthétiques figurent dans `verification.txt`. Ce wrapper n’est pas une dépendance du projet : les commandes ci-dessus sont celles à rejouer.

Résultat final : **363 tests réussis, 2 ignorés**, analyse Studio sans diagnostic, build macOS debug réussi. Les deux tests ignorés préexistants attendent une copie externe (`studio_large_atlas_test.dart` et `train_workspace_capture_test.dart`) ; aucune copie de projet original n’a été fournie à cette exécution. Aucun test UI06 n’est ignoré. Les tests d’architecture vérifient également les frontières transitives et la limite de 300 lignes par fichier Dart manuel.

Autres vérifications exécutées :

```sh
cd packages/map_authoring
dart test test/domains/narrative/modern_narrative_authoring_test.dart test/tooling/jsonl_scene_pre_session_flow_test.dart
cd ../map_editor
flutter test --no-pub --reporter expanded test/narrative_template_catalog_test.dart
dart analyze lib/src/application/services/narrative_template_catalog.dart
cd ../map_core
dart analyze lib/src/authoring/scene_command_payload_builder.dart lib/src/authoring/scene_command_payload_helpers.dart lib/map_core_domain.dart
cd ../../tools/pokemap_mcp
npm run build
node --import tsx --test --test-concurrency=1 test/studio_narrative_publication.test.ts
node --import tsx --test --test-concurrency=1 --test-name-pattern='scene.upsert' test/mutation_server.test.ts
```

API directe/JSONL : **12 réussites**. Constructeurs historiques du Map Editor : **15 réussites** et analyse ciblée propre. MCP compilé : **1 réussite de publication + 1 réussite de `scene.upsert`**, aucune suite globale relancée. L’analyse ciblée `map_core` signale seulement `unnecessary_library_name` ligne 1 du barrel, déjà présent dans HEAD ; les nouveaux fichiers n’ont pas de diagnostic. Le catalogue MCP connecté a échoué avec `worker.exited`, code 78 : la parité transport empaquetée est vérifiée, la disponibilité du serveur de cette session ne l’est pas.

Le test de volume utilise **200 nœuds, 265 liens, 8 mises à jour de vue, zéro mutation de document**, sans adaptateur d’E/S instancié. Il mesure le rendu logiciel de test, pas les FPS natifs. Les valeurs du passage final sont consignées dans `verification.txt`.

## Passes de revue et corrections

Relectures indépendantes : agent `ui03_catalog` pour les gestes et le canvas, `ui03_detail` pour les sessions/publications, `ui03_context_audit` pour les contrats, propriétés et runtime. Leurs noms proviennent des tâches de collaboration réutilisées ; leur périmètre effectif ici est uniquement UI06. Les points concrets retenus ci-dessous ont été corrigés et revérifiés par le runner central. Aucun blocage supplémentaire confirmé après ces corrections ; acceptation visuelle toujours ouverte.

- Audit du contrat : modèles, commandes et exécuteur existants retenus ; aucun moteur parallèle. Revue des actions et documents liés : sélecteurs exacts, payloads avancés conservés.
- Passe canvas : vrai défaut trackpad corrigé ; un pan ne déplace plus aussi le bloc et ne s’applique plus deux fois. Vérification de la sélection de courbes aux différents zooms et des gestes annulés.
- Passe sessions/publication : 64 entrées d’historique, conflits entre représentations, instantané de sauvegarde et bases périmées couverts.
- Passe finale : le soupçon de lancement périmé pendant `saveAll` a été retiré après lecture de son retour `!dirty`. Un garde final couvre néanmoins une modification pendant l’attente suivante de sauvegarde de carte : le jeu ne part pas avec une ancienne scène présentée comme courante.
- Corrections de tests distinctes du produit : la fixture d’import doit contenir un atlas canonique réel ; les publications asynchrones doivent démarrer dans la zone `runAsync` et leurs attentes être bornées. Deux essais bloqués ont été interrompus proprement ; leur code de sortie de wrapper ne constitue pas une réussite. Aucune assertion supprimée ni aucun nouveau skip pour obtenir du vert.

## Limites et autocritique

- Validation visuelle et manipulation native par Yoahn encore ouvertes. Le build macOS et les captures de widgets ne remplacent pas cette acceptation.
- Un graphe incomplet reste en mémoire ; le contrat actuel peut refuser sa publication. Le fichier valide précédent est conservé. Aucun stockage caché de brouillon ajouté.
- Les documents liés sont consultables, pas édités dans cette page. Le retour intact est testé ; un aller-retour d’édition de leur contenu n’est pas annoncé comme réalisé.
- Les références de certaines actions nécessitent un catalogue non chargé dans le manifeste ; elles restent explicitement indisponibles. Les données avancées existantes sont conservées.
- Un conflit externe exige de réconcilier/réouvrir le projet. L’action Abandonner est explicite et reprend la version du catalogue de session ; elle ne prétend pas recharger le disque.
- L’aperçu est borné et exige les sorties de test ; ce n’est ni un interpréteur supplémentaire ni une preuve de partie joueur sauvegardée.
- Le cadrage complet d’un grand graphe réduit naturellement les blocs. Zoom et inspecteur restent nécessaires pour lire les détails ; aucune promesse de performance native chiffrée.

## Lancement

```sh
cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter run -d macos --no-pub
```

Ouvrir une copie de projet, puis **Histoire → Scènes → Nouvelle scène** ou une scène existante. La configuration WebStorm **Avelune Studio** existante reste utilisable.

## Inventaire et état final

L’inventaire ci-dessous est celui du lot local, fichiers non suivis inclus. Les modifications restent à relire et à indexer uniquement sur autorisation ultérieure. Aucun autre écran commencé.

Les chemins partent de la racine du dépôt. Pour les fichiers modifiés, les zones sont les positions `+ligne,nombre` du diff final ; pour les nouveaux fichiers, le fichier entier est concerné.

| Fichier | État | Zones |
| --- | --- | --- |
| `apps/avelune_studio/lib/app/di/providers.dart` | Modifié | 5 |
| `apps/avelune_studio/lib/app/studio_bootstrap.dart` | Modifié | 4, 57,8 |
| `apps/avelune_studio/lib/features/narrative/application/interaction_edit_session.dart` | Modifié | 4, 18,2, 25,2 |
| `apps/avelune_studio/lib/features/narrative/application/narrative_interaction_opener.dart` | Modifié | 85, 100,2, 104, 167,3, 190,4, 216,22 |
| `apps/avelune_studio/lib/features/narrative/application/narrative_workspace_controller.dart` | Modifié | 32, 110,11, 164,16, 217,3 |
| `apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_screen.dart` | Modifié | 2,3, 42, 49, 69,2, 101, 121, 188,2, 215, 274,4 |
| `apps/avelune_studio/lib/presentation/features/map_workspace/workspace_actions.dart` | Modifié | 2, 24, 33, 40, 48,2, 58,3, 83,4, 98,7 |
| `apps/avelune_studio/lib/presentation/features/map_workspace/workspace_secondary_content.dart` | Modifié | 2,2, 13, 18,4, 34,9, 61,2 |
| `apps/avelune_studio/lib/presentation/features/map_workspace/workspace_story_binding.dart` | Modifié | 4,37 |
| `apps/avelune_studio/lib/presentation/features/narrative/narrative_overview_detail.dart` | Modifié | 20, 28, 110,14 |
| `apps/avelune_studio/lib/presentation/features/narrative/narrative_overview_header.dart` | Modifié | 14, 20, 38,2, 48,3, 79,7 |
| `apps/avelune_studio/lib/presentation/features/narrative/narrative_story_pane.dart` | Modifié | 22,2, 29,2, 89,3, 104 |
| `apps/avelune_studio/lib/presentation/shared/widgets/dialogs/confirm_studio_close.dart` | Modifié | 7,3 |
| `apps/avelune_studio/lib/presentation/shared/widgets/layout/studio_primary_navigation.dart` | Modifié | 24, 54, 80,2 |
| `apps/avelune_studio/lib/presentation/shell/studio_workspace_host.dart` | Modifié | 29 |
| `packages/map_core/lib/map_core_domain.dart` | Modifié | 390,2 |
| `packages/map_editor/lib/src/application/services/narrative_template_catalog.dart` | Modifié | 3,3, 713,0 |
| `apps/avelune_studio/lib/app/di/scene_providers.dart` | Nouveau | 1–6 |
| `apps/avelune_studio/lib/features/scenes/application/scene_edit_session.dart` | Nouveau | 1–102 |
| `apps/avelune_studio/lib/features/scenes/application/scene_workspace_controller.dart` | Nouveau | 1–161 |
| `apps/avelune_studio/lib/features/scenes/data/local_scene_adapter.dart` | Nouveau | 1–157 |
| `apps/avelune_studio/lib/features/scenes/domain/scene_port.dart` | Nouveau | 1–22 |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_action_form.dart` | Nouveau | 1–272 |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_builder_commands.dart` | Nouveau | 1–145 |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_builder_header.dart` | Nouveau | 1–216 |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_builder_page.dart` | Nouveau | 1–280 |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_builder_view_state.dart` | Nouveau | 1–47 |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_canvas_layer.dart` | Nouveau | 1–151 |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_canvas_menu.dart` | Nouveau | 1–65 |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_canvas_minimap.dart` | Nouveau | 1–112 |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_canvas_node.dart` | Nouveau | 1–255 |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_canvas_painter.dart` | Nouveau | 1–129 |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_canvas_surface.dart` | Nouveau | 1–244 |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_canvas_types.dart` | Nouveau | 1–174 |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_condition_form.dart` | Nouveau | 1–271 |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_graph_canvas.dart` | Nouveau | 1–290 |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_inspector.dart` | Nouveau | 1–254 |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_inspector_fields.dart` | Nouveau | 1–271 |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_library_panel.dart` | Nouveau | 1–155 |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_linked_cinematic.dart` | Nouveau | 1–123 |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_linked_document.dart` | Nouveau | 1–198 |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_payload_picker.dart` | Nouveau | 1–80 |
| `apps/avelune_studio/lib/presentation/features/scenes/scene_preview_panel.dart` | Nouveau | 1–126 |
| `apps/avelune_studio/lib/presentation/shared/widgets/inputs/studio_commit_field.dart` | Nouveau | 1–50 |
| `apps/avelune_studio/lib/presentation/shared/widgets/inputs/studio_select.dart` | Nouveau | 1–39 |
| `apps/avelune_studio/test/presentation/ui06_scene_action_form_test.dart` | Nouveau | 1–118 |
| `apps/avelune_studio/test/presentation/ui06_scene_inspector_test.dart` | Nouveau | 1–294 |
| `apps/avelune_studio/test/presentation/ui06_scene_journey_test.dart` | Nouveau | 1–180 |
| `apps/avelune_studio/test/presentation/ui06_scene_navigation_test.dart` | Nouveau | 1–235 |
| `apps/avelune_studio/test/presentation/ui06_scene_playtest_guard_test.dart` | Nouveau | 1–137 |
| `apps/avelune_studio/test/scene_canvas_addition_test.dart` | Nouveau | 1–117 |
| `apps/avelune_studio/test/scene_graph_canvas_test.dart` | Nouveau | 1–167 |
| `apps/avelune_studio/test/scenes/scene_condition_form_ui06_test.dart` | Nouveau | 1–145 |
| `apps/avelune_studio/test/scenes/scene_history_ui06_test.dart` | Nouveau | 1–52 |
| `apps/avelune_studio/test/scenes/scene_publication_ui06_test.dart` | Nouveau | 1–244 |
| `apps/avelune_studio/test/scenes/scene_session_ui06_test.dart` | Nouveau | 1–290 |
| `apps/avelune_studio/test/support/scene_canvas_test_harness.dart` | Nouveau | 1–119 |
| `apps/avelune_studio/test/support/ui06_scene_construction_driver.dart` | Nouveau | 1–102 |
| `apps/avelune_studio/test/support/ui06_scene_fixture.dart` | Nouveau | 1–262 |
| `apps/avelune_studio/test/ui06_scene_construction_test.dart` | Nouveau | 1–222 |
| `apps/avelune_studio/test/ui06_scene_runtime_test.dart` | Nouveau | 1–161 |
| `apps/avelune_studio/test/ui06_scene_volume_test.dart` | Nouveau | 1–135 |
| `packages/map_core/lib/src/authoring/scene_command_payload_builder.dart` | Nouveau | 1–213 |
| `packages/map_core/lib/src/authoring/scene_command_payload_helpers.dart` | Nouveau | 1–144 |

Preuves ajoutées : ce `README.md`, `verification.txt` et les six PNG listés plus haut. Aucun asset du pack ni projet personnel n’est embarqué.

État Git final : **17 fichiers suivis modifiés, 55 nouveaux non suivis, index vide**. Branche `main` et HEAD initial inchangés. `git diff --check` et garde Markdown réussis ; formatage final des 64 fichiers Dart concernés sans changement restant.
