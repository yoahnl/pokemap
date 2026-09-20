# AS-UI-004 — Préparer un terrain automatique

État : livraison locale en attente de validation visuelle de l’utilisateur. Aucun passage à un autre écran, aucune écriture Git ou Notion. Les projets utilisés sont des fixtures temporaires ; aucun projet personnel n’a été modifié.

## Audit initial et décisions

Pack lu : `/Users/karim/Downloads/avelune_studio_UI04_terrains_prompt_et_references/`. Les trois PNG de `references/` ont été ouverts avant de coder. Le contrôleur cardinal existait, mais l’écran formait une longue séquence, la reprise acceptait des préparations insuffisamment vérifiées et la publication canonique supprimait le brouillon. Le résolveur, les transactions de ressources, les caches d’images et les sessions ont été conservés.

Trois zones simultanées sur desktop : image source, seize raccords, essai réel 17 × 17. Aucun ordre de l’atlas ne détermine automatiquement les raccords. À petite hauteur, les panneaux défilent localement ; à 1024 × 640 / 150 %, les onglets Préparer / Essayer gardent les commandes principales accessibles. La grille d’essai se place à côté de ses commandes quand cet onglet est large.

La reprise préfère le brouillon local ou canonique. Après publication, une reconstruction n’est permise que si elle reproduit exactement le preset et si l’identité est libre. Les configurations avancées sont refusées à l’édition simplifiée et restent utilisables sur Carte. La publication utilise toujours `smart_tile.preset.draft.upsert` puis `smart_tile.preset.publish` ; une réussite partielle conserve le brouillon et l’ancienne publication.

Passes réalisées : contrôleur/compatibilité, intégration Ressources, navigation Personnages, composition/gestes, revue indépendante, vérification intégrée. La revue indépendante a trouvé une collision possible entre l’ID reconstruit et un brouillon d’une autre cible. Le correctif et sa régression couvrent les brouillons locaux et persistés ; la seconde passe confirme le problème résolu. Aucun autre problème actionnable sur cette revue statique.

## Parcours prouvés

- Atlas réel de test à seize pièces distinctes, volontairement permutées, tuiles 24 px ; sélection par vrais gestes dans le composant d’atlas. Les autres tests conservent la grille 16 × 24 avec marges et espacements.
- Sauvegarde incomplète, réouverture avec les adaptateurs réels, conservation des associations et de l’identité ; deux terrains distincts depuis une même image.
- Association des seize raccords, erreur volontaire, examen d’une case, correction immédiate, annulation/rétablissement local, retrait et recherche des raccords manquants. L’historique est borné à 64 préparations.
- Tracé continu dans l’essai, exemple couvrant les seize situations, gomme et remise à zéro locales. Les cases non associées sont signalées explicitement.
- Publication puis peinture sur une carte déjà modifiée ; zoom et historique conservés ; annuler la peinture conserve les modifications antérieures. Le parcours M2 existant sauvegarde, recharge et lance le vrai runtime.
- Republication sous la même identité, refus sans perte des préparations avancées, panne de publication après upsert : « Brouillon enregistré ; publication non effectuée », ancienne version intacte et réessai possible.
- Sans carte, publication dans Ressources et sélection du terrain, sans prétendre activer un pinceau.
- Entrée principale Personnages retirée ; « Placer un personnage » ouvre Carte et sa palette, y compris repliée à 150 %. Aucun placement avant choix du sprite ; placement ensuite annulable.

## Comparaison visuelle

Source principale : `references/01-terrain-cible.png` du pack, 1536 × 1024. Captures produites par le rendu Flutter réel, ratio 1, sans retouche. Elles utilisent un atlas de test dessiné de façon déterministe, pas les ressources d’un projet personnel. Les captures ne constituent pas une certification du pilote natif macOS ni une validation artistique utilisateur.

Comparaison plein écran et régions source/raccords/essai : la première passe montrait trop de vide au-dessus de l’atlas, des noms tronqués et une source minuscule à 150 %. Corrections : alignement supérieur, libellés sur deux lignes, défilement local à faible hauteur. La grille complète reste maintenant à côté des commandes dans l’onglet Essayer compact. La capture de retour a aussi révélé une palette Décors encore affichée malgré le pinceau terrain actif : le retour ouvre désormais Terrains et efface son ancien filtre. Les options décoratives, diagonales, animations et ancien assistant en quatre étapes de la maquette n’ont pas été reproduits, conformément au périmètre du pack.

| Capture | État |
| --- | --- |
| [01-brouillon-incomplet.png](01-brouillon-incomplet.png) | 1536 × 1024, cinq raccords affectés |
| [02-raccord-corrige.png](02-raccord-corrige.png) | Raccord examiné et corrigé dans l’exemple |
| [03-terrain-complet.png](03-terrain-complet.png) | Page complète, seize raccords et tracé interactif |
| [04-compact-150.png](04-compact-150.png) | 1024 × 640, texte 150 %, Essayer ; Préparer testé aussi |
| [05-retour-carte.png](05-retour-carte.png) | Terrain publié et peint, carte antérieure préservée |

Les formats 1440 × 900 et 1280 × 900 sont aussi traversés par le test. Résultat de comparaison technique : `passed` après ces corrections ; aucun écart P0/P1/P2 actionnable identifié sur le parcours autorisé. Validation visuelle utilisateur encore attendue. L’atlas de test n’est pas une direction artistique nouvelle.

## Fichiers et zones

Tous les chemins ci-dessous sont relatifs à `apps/avelune_studio/`.

| Fichiers | Zones modifiées |
| --- | --- |
| `lib/features/terrains/application/terrain_draft_controller.dart` | Historique local, états, essai, publication et reprise après erreur |
| `lib/features/terrains/domain/terrain_connections.dart` | Construction et projection fidèles du brouillon |
| `lib/features/terrains/domain/terrain_draft_compatibility.dart` (nouveau) | Validation stricte, reconstruction et protection des collisions |
| `lib/presentation/features/terrains/terrain_editor_screen.dart` | Cadre, actions, disposition responsive |
| `lib/presentation/features/terrains/terrain_scratch_view.dart` | Gestes continus et examen |
| `lib/presentation/features/terrains/terrain_source_panel.dart` (nouveau) | Nom, source et sélection de case |
| `lib/presentation/features/terrains/terrain_rules_panel.dart` (nouveau) | Seize situations, filtres et historique |
| `lib/presentation/features/terrains/terrain_trial_panel.dart` (nouveau) | Essai, commandes et disposition compacte |
| `lib/presentation/features/resources/atlas_selection_view.dart` | Sélection optionnelle, alignement supérieur optionnel et dédoublonnage du même geste |
| `lib/presentation/features/resources/resource_navigation.dart` | Création distincte, reprise et publication sans carte |
| `lib/presentation/features/resources/resource_workspace_pane.dart` | Branchement des actions existantes |
| `lib/presentation/features/resources/resource_brush_selection.dart` | Retour avec palette Terrains visible et pinceau actif |
| `lib/presentation/features/resources/resource_library_screen.dart` | Section de brouillons bornée dans Terrains |
| `lib/presentation/features/resources/resource_terrain_draft_list.dart` (nouveau) | Liste de reprise |
| `lib/presentation/features/resources/resource_detail_panel.dart` | Modifier les raccords / message de préparation avancée |
| `lib/presentation/shared/widgets/layout/studio_connection_diagram.dart` (nouveau) | Diagramme cardinal avec les tokens existants |
| `lib/presentation/shared/widgets/layout/studio_palette_card.dart` | Nombre de lignes optionnel, valeur par défaut conservée |
| `lib/presentation/shared/widgets/layout/studio_primary_navigation.dart` | Retrait de l’entrée principale Personnages |
| `lib/presentation/features/home/studio_home_tools.dart` | Intitulé du raccourci |
| `lib/presentation/features/map_workspace/workspace_home_binding.dart` | Destination du raccourci |
| `lib/presentation/features/map_workspace/map_workspace_screen.dart` | Retrait du contexte Personnages autonome |
| `lib/presentation/features/map_workspace/map_creation_tools.dart` | Réutilisation de l’ouverture de palette |
| `lib/presentation/features/map_workspace/map_workspace_view_state.dart` | Demande d’ouverture de palette et neutralisation du pinceau précédent |
| `lib/presentation/features/map_workspace/map_workspace_layout.dart` | Ouverture de la palette compacte |
| `lib/presentation/features/map_workspace/map_workspace_panels.dart` | Aide dans le pied de palette existant |
| `test/terrain_preparation_ui04_test.dart` (nouveau) | Historique, fidélité, avancé, erreur partielle et collision |
| `test/terrain_editor_test.dart` | Gestes avec coordonnées réelles et onglets compacts |
| `test/resource_io/terrain_resource_io_test.dart` | Réouverture, publication et erreur avec adaptateurs réels |
| `test/resource_io/terrain_navigation_ui04_test.dart` (nouveau) | Identités distinctes, reprise et absence de cartes |
| `test/home/home_character_navigation_test.dart` (nouveau) | Navigation et placement desktop/compact |
| `test/presentation/ui04_terrain_journey_test.dart` (nouveau) | Parcours intégré et captures |
| `test/support/ui04_terrain_atlas.dart` (nouveau) | Atlas distinct et permuté, reproductible |

Ce README, cinq captures et le journal final constituent le dossier de preuves. Aucun package moteur, dépendance, configuration native ni projet personnel modifié par UI04.

## Vérifications et limites

Les commandes Flutter suivantes sont lancées depuis `apps/avelune_studio` :

| Commande | Résultat |
| --- | --- |
| `dart format --output=none --set-exit-if-changed` sur les fichiers du lot | Aucun fichier à reformater |
| `flutter analyze --no-pub` | `No issues found! (ran in 6.0s)` |
| `flutter test --no-pub --reporter expanded --concurrency=4` | `01:02 +294 ~2: All tests passed!` — 294 réussis, 2 ignorés |
| `flutter test --no-pub --reporter expanded test/presentation/ui04_terrain_journey_test.dart` avec `AVELUNE_CAPTURE_DIR` vers ce dossier | Parcours et cinq captures du rendu réel |
| `flutter build macos --no-pub` | `✓ Built build/macos/Build/Products/Release/Avelune Studio.app (114.9MB)` |

Les deux tests ignorés nécessitent une copie personnelle explicitement fournie (`AVELUNE_PROJECT_COPY` / capture Train). Ils ne sont pas comptés comme réussis. Le parcours M2 du runtime, les scénarios M3 et les parcours UI01/UI02/UI03 font partie de la suite. Les avertissements natifs de plugins observés lors du premier build n’ont pas été corrigés hors périmètre.

Les sorties finales utiles et les reçus de suivi des processus figurent dans [verification.txt](verification.txt). Le dossier contient seulement cette note, ce journal et les cinq captures annoncées.

Le suivi PID/descendants des exécutions Flutter n’a trouvé aucun reliquat reconnu à arrêter lors du passage final. Un passage global intermédiaire a rencontré un délai d’E/S de 20 secondes dans `desktop_workspace_layout_test.dart` pendant les validations concurrentes ; la réexécution séquentielle puis les suites complètes repassent, sans changement du produit pour contourner ce délai. Les premières vérifications ont aussi permis de corriger le débordement compact et les coordonnées de clic du test après le repositionnement de la source.

Depuis la racine, `git diff --check` et `POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh` passent. L’exception Markdown est limitée à l’unique note explicitement demandée par le pack.

Parité : aucune nouvelle action moteur. `dart test --reporter expanded test/domains/maps/smart_tile_draft_actions_test.dart test/tooling/jsonl_smart_tile_native_flow_test.dart`, depuis `packages/map_authoring`, termine par `00:18 +21: All tests passed!`. Depuis `tools/pokemap_mcp`, `npm run check` réussit et `npm test` reconstruit le serveur puis termine par `tests 82`, `pass 82`, `fail 0`, `skipped 0`. Cette suite comporte les transports réels de sauvegarde/publication de brouillons et de peinture Smart Tile. Le serveur MCP connecté à cette session répond toutefois `worker.exited` code 78 au `pokemap_describe` ; son catalogue connecté n’est donc pas certifié par les tests du serveur empaqueté. Aucun nouveau contrat n’est nécessaire pour l’historique et l’essai locaux de l’interface.

État Git initial : branche `main`, base `81ebef54ed2165f95648649bca7872654289d3c4`. Huit modifications préexistantes conservées : `macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` et les sept `app_icon_*.png` sous `macos/Runner/Assets.xcassets/AppIcon.appiconset/`. État final : 47 chemins modifiés ou nouveaux, dont ces 8 préexistants et 39 liés à UI04 (32 fichiers Dart, 5 captures, cette note et le journal). Changements non commités. Aucune écriture Git/Notion.

Lancement depuis `apps/avelune_studio` : `flutter run -d macos`. Les terrains avancés restent volontairement hors de l’éditeur simplifié. Les petits formats nécessitent un défilement local dans Préparer. L’acceptation artistique et l’usage manuel natif restent à valider ; ne pas commencer la page suivante avant cette validation.
