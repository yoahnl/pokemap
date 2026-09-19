# UI-02 — Carte

État du 20 septembre 2026 : implémentation et vérifications Studio terminées, validation visuelle de Yoahn attendue. Aucun autre écran commencé, aucune écriture Git ou Notion, aucun projet personnel modifié.

## Résultat et comparaison

Le header de 64 px, le logo et la navigation sont partagés avec l’accueil accepté. Carte utilise une seule barre contextuelle, une palette visuelle à gauche, le canvas existant et l’inspecteur à droite. À 1536 px : navigation 184, palette 240, inspecteur 300 ; à 1280 px : palette 220, inspecteur 280. À 1024 px ou avec texte agrandi, les panneaux compacts gardent l’accès aux outils et rendent la main après sélection.

Comparaison faite pendant le travail puis sur les cinq rendus finaux : suppression des barres redondantes, grille de vignettes, commandes devant/derrière libellées, pile réellement sélectionnable, avertissement de bordures sorti des coordonnées de carte. Corrections après capture : onglets bornés à deux colonnes, raccourcis lisibles, atlas compact aligné en haut avec dimensions visibles. L’accueil conserve son illustration et sa composition.

Les références [Carte cible](reference-carte.png), [Accueil accepté](reference-accueil.png), [Carte avant](reference-avant.png) ont toutes été ouvertes avant les modifications. La composition est rapprochée de la cible, pas déclarée identique : pas de minicarte factice, pas de gestion manuelle des calques, pas de contenu de jeu recréé pour imiter la scène illustrée.

## Captures réelles

Rendus Flutter hors écran, avec polices desktop, vrais widgets et assets d’une fixture temporaire autonome. Les originaux utilisateur ne sont jamais ouverts. Ces captures prouvent la composition et les tests associés, pas une recette des clics macOS natifs.

| Capture | État |
| --- | --- |
| [01-carte-generale.png](01-carte-generale.png) | 1536 × 1024, carte et palette Décors |
| [02-decor-empilement.png](02-decor-empilement.png) | Trois instances compatibles, sélection, position 1 devant |
| [03-palette-tuiles.png](03-palette-tuiles.png) | Atlas réellement importé, sélection inline réutilisée |
| [04-compact-150.png](04-compact-150.png) | 1024 × 640, texte 150 %, panneaux repliés |
| [05-accueil-conserve.png](05-accueil-conserve.png) | Retour à l’accueil avec le même workspace monté |

## Audit initial, réemploi et passes

Base propre : branche `main`, HEAD `2b4db9053ab0dafaa6701e5724f9ac17672c4376`. Audit ciblé de l’accueil UI01, layout/palette/inspecteur, transformation du canvas, sessions et tests M1/M2/M3. Risques identifiés : duplication de workspace, perte du pinceau/cache, saisie capturée par les raccourcis, coordonnées après repli, débordements à texte agrandi. Le mandat est cohérent avec le dépôt ; aucune extension de périmètre nécessaire.

`MapWorkspaceController`, `EditableMapDocument`, `MapEditingCommands`, `StudioMapResources`, les actions de sauvegarde/test et le runtime existants restent les fondations. Aucun moteur, contrat sérialisé, dépendance ou configuration native changé. L’extension facultative d’`AtlasSelectionView` conserve son comportement Ressources par défaut. Le `part` préexistant de liaison Accueil est conservé ; aucun nouveau découpage artificiel en `part`.

Passes : Audit/Architecture (racine) — frontières préservées ; Implémentation palette (agent) — catalogue paresseux, scroll/zoom conservés, primitives dans le design system ; Implémentation inspecteur (agent) — contrat `1 = devant`, limites du moteur respectées ; Tests/Build (racine) — résultats ci-dessous ; Critique (agent puis racine) — aucun blocage sessions/zoom identifié, incohérence de destination Carte après Personnages corrigée sans vider la palette. La recette artistique reste à Yoahn.

## Vérifications sur le code final

Depuis `apps/avelune_studio` :

- `dart format --output=none --set-exit-if-changed` sur les 35 fichiers Dart présents modifiés/ajoutés : zéro changement.
- `flutter analyze --no-pub` : `No issues found! (ran in 7.8s)`.
- `flutter test --no-pub --reporter expanded` : `00:52 +266 ~2: All tests passed!`.
- Capture ciblée : `flutter test --no-pub --reporter expanded test/presentation/ui02_map_journey_test.dart` : `00:13 +1: All tests passed!`.
- `flutter build macos --debug --no-pub` : `✓ Built build/macos/Build/Products/Debug/Avelune Studio.app`.

Les deux tests ignorés nécessitent `AVELUNE_PROJECT_COPY` : grosse bibliothèque externe et capture Train. Cette variable n’a pas été fournie pour ne pas utiliser de projet personnel. Les tests de stress autonomes sont exécutés. Les descendants des runners Flutter sont suivis et revérifiés après exécution : aucun harness résiduel à arrêter. Résultats et PID des deux runs finaux dans [verification.log](verification.log).

Preuves comportementales : import/décor/terrain/sauvegarde/relecture/vrai runtime M2 ; interactions/histoire M3 ; fermeture annulée/conflit ; recherche et focus ; brush/cache avec palette masquée ; catalogue virtualisé ; diagnostics nombreux ; pile compatible, sélection masquée, limites, undo et conservation des collisions ; même session/document sale/transformation après Accueil ; placement à la bonne case après redimensionnement, zoom, pan et fermeture de la palette compacte. Les anciens tests ont été adaptés aux vrais boutons et coordonnées transformées, en conservant leurs assertions métier.

Parité MCP : aucune opération d’auteur ou API nouvelle. Les commandes canoniques existantes sont réutilisées ; aucun nouveau contrat transport à enregistrer. Depuis `tools/pokemap_mcp`, `npm test` reconstruit le serveur : **82 tests réussis, 0 échec, 0 ignoré**, y compris imports Studio, publication et transports canoniques. La vérification du serveur connecté `pokemap_describe({})` échoue néanmoins avec `worker.exited`, code 78, `retryable=false`. La certification de ce serveur connecté reste bloquée ; elle n’est pas confondue avec les tests locaux réussis. Résultats dans le journal final.

## Inventaire du code

Chemins ci-dessous relatifs à `apps/avelune_studio/`. Les diff Git et les sources restent les preuves détaillées ; aucune copie des sources dans ce rapport.

| Fichier | Zone et effet |
| --- | --- |
| `lib/platform/rendering/studio_map_visual_widgets.dart` | `StudioMapVisual.build` : avertissement retiré du canvas zoomé, renderer conservé |
| `lib/presentation/features/characters/character_inspector.dart` | Aperçu 96 px, explication de l’ordre naturel runtime |
| `lib/presentation/features/characters/character_palette.dart` | Grille paresseuse de personnages, mêmes actions |
| `lib/presentation/features/home/studio_home_navigation.dart` | Ancien widget déplacé vers la navigation partagée |
| `lib/presentation/features/home/studio_home_screen.dart` | Extraction du cadre, recherche/focus partagés, corps conservé |
| `lib/presentation/features/map_workspace/map_creation_tools.dart` | Outils existants regroupés à gauche |
| `lib/presentation/features/map_workspace/map_palette_grid.dart` | Grille et conservation du scroll |
| `lib/presentation/features/map_workspace/map_tile_palette.dart` | Choix d’atlas et réemploi de sa sélection inline |
| `lib/presentation/features/map_workspace/map_selection_inspector.dart` | Largeur et outil transmis à l’inspecteur |
| `lib/presentation/features/map_workspace/map_workspace_inspector.dart` | Contexte vide, preview, instance/définition, pile réelle |
| `lib/presentation/features/map_workspace/map_workspace_layout.dart` | Cadre, largeurs, panneaux compacts, messages bornés |
| `lib/presentation/features/map_workspace/map_workspace_panels.dart` | Quatre catalogues, recherche, catégories et compteurs réels |
| `lib/presentation/features/map_workspace/map_workspace_screen.dart` | Raccord du cadre au workspace existant |
| `lib/presentation/features/map_workspace/map_workspace_toolbar.dart` | Une barre carte/actions/vue, zoom réel observable |
| `lib/presentation/features/map_workspace/map_workspace_view_state.dart` | Scroll, atlas et transformations retenus puis disposés |
| `lib/presentation/features/map_workspace/workspace_home_binding.dart` | Contexte navigation Carte/Personnages distinct de la palette retenue |
| `lib/presentation/features/project_session/project_session_screen.dart` | Transmission recherche/focus à l’accueil existant |
| `lib/presentation/features/resources/atlas_selection_view.dart` | Contrôleur externe facultatif et présentation compacte facultative |
| `lib/presentation/shared/widgets/feedback/studio_notice.dart` | Nombre de lignes facultatif, texte intégral accessible par infobulle |
| `lib/presentation/shared/widgets/inputs/studio_search_field.dart` | Focus externe facultatif |
| `lib/presentation/shared/widgets/inputs/studio_palette_tabs.dart` | Onglets visuels bornés à deux colonnes |
| `lib/presentation/shared/widgets/layout/studio_application_frame.dart` | Header/logo/navigation communs |
| `lib/presentation/shared/widgets/layout/studio_palette_card.dart` | Vignette visuelle partagée sélectionnable |
| `lib/presentation/shared/widgets/layout/studio_primary_navigation.dart` | Destinations et fermeture explicite, modes large/compact |
| `lib/presentation/shared/widgets/layout/studio_depth_control.dart` | Boutons devant/derrière et raccourcis réels |
| `lib/presentation/shell/studio_home_navigation.dart` | État de recherche et transfert de focus, sans nouvelle session |
| `test/presentation/brush_retention_transition_test.dart` | Parcours des outils/panneaux, assertions cache conservées |
| `test/presentation/desktop_workspace_layout_test.dart` | Budgets UI02 avec deux panneaux, stress/diagnostics conservés |
| `test/presentation/m2_end_to_end_test.dart` | Nouveaux sélecteurs des mêmes actions |
| `test/presentation/m3_authoring_journey_test.dart` | Sélecteur palette et clic transformé, parcours narratif conservé |
| `test/presentation/map_workspace_journey_test.dart` | Nom de la vignette de tuile |
| `test/presentation/studio_app_test.dart` | Identité vérifiée par le libellé sémantique du logo |
| `test/presentation/studio_gallery_test.dart` | Défilement réel vers la carte avant clic à texte agrandi |
| `test/presentation/map_inspector_ui02_test.dart` | Nouveaux tests contexte/pile/masquage/limites/undo |
| `test/presentation/ui02_palette_test.dart` | Nouveaux tests 500 décors, scroll, sélection atlas, zoom retenu |
| `test/presentation/ui02_map_journey_test.dart` | Nouveau parcours réel, captures, session/focus/responsive/coordonnées |

Les autres fichiers livrés sont uniquement les cinq captures, trois références et journaux de ce dossier. État Git final : changements non indexés limités à ces chemins, aucun commit/push ; HEAD inchangé. `git diff --check` propre.

## Limites et lancement

L’illustration de carte de la maquette n’est pas reproduite : la fixture montre des assets originaux simples, donc une scène moins dense. Pas de minicarte ajoutée, pas de rendu de bordures/animations nouveau, pas de FPS revendiqués. Les captures ne remplacent pas la validation visuelle native ; aucun ancien Studio contenant un projet personnel n’a été piloté.

Depuis `apps/avelune_studio` : `flutter run -d macos -t lib/main.dart`. Un exemple autonome neuf peut être créé avec `dart run tool/create_example_project.dart`, puis ouvert depuis l’accueil. Ne pas passer un dossier existant comme sortie.

Prochaine étape : validation visuelle de Carte par Yoahn. Aucun autre écran entamé.
