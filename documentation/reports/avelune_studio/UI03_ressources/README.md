# AS-UI-003 — Bibliothèque Ressources

Livraison locale du 20 septembre 2026, en attente de validation visuelle. Aucun commit, push, changement Notion ou accès en écriture à un projet personnel. Base conservée : `main`, `2b4db9053ab0dafaa6701e5724f9ac17672c4376`, avec les 46 chemins UI-02 déjà modifiés/non suivis au début du lot.

## Résultat et comparaison

Les deux textes du pack et ses trois PNG ont été lus/ouverts avant le code. La cible dirige la composition : catégories réelles à gauche, galerie dominante, détail à droite et action d’utilisation fixe. Le cadre Accueil/Carte et les logos Avelune sont conservés. Comparaison visuelle effectivement réalisée avec `01-bibliotheque-cible.png` : import réaligné à droite, suppression d’une ligne secondaire en faible hauteur, cartes réduites en petite fenêtre pour montrer aussi leur nom, largeur des libellés du détail adaptée à 150 %. Les compteurs, catégories et actions viennent des données disponibles ; aucun favori, export ou historique fictif.

Captures **réelles Flutter hors écran**, sans retouche, produites par les widgets de production sur une fixture temporaire. Elles prouvent le rendu et les interactions testées, pas une validation manuelle native. Les graphismes simples proviennent de `tool/example_project_assets.dart`, déjà présent ; les 123 décors de la fixture réutilisent ces trois ressources, sans prétendre représenter la richesse artistique d’un projet personnel.

| Capture | Preuve |
| --- | --- |
| [Décors et détail](01-decors-detail.png) | 1536 × 1024, quatre colonnes, aperçu entier et sélection initiale en lecture seule |
| [Atlas](02-image-atlas.png) | Image complète, dimensions réelles, préparation existante |
| [Terrain](03-terrain-raccord.png) | Exemple 3 × 3 calculé par le résolveur, aucune image générique |
| [Recherche et catégorie](04-recherche-categorie.png) | Recherche par tag, catégorie Objets, 40 résultats réels |
| [Compact à 150 %](05-compact-150.png) | 1024 × 640, noms visibles, catégories repliées |
| [Détail compact](05b-detail-compact-150.png) | Panneau défilant, utilisation toujours accessible |
| [Retour Carte](06-retour-carte.png) | Même document, pinceau terrain actif, geste annulé |

## Audit initial et périmètre

`ResourceNavigation`, `LocalResourceAdapter`, les transactions M2, `StudioMapResources`, les miniatures et le choix explicite de tuile existaient déjà. Le défaut principal était de présentation : détail vide initialement, petits aperçus, catégorie absente pour les terrains, sélection masquée par les filtres et détail comprimé en bas de fenêtre. La recherche et l’ordre de sélection ont été centralisés dans l’état déjà détenu par la navigation. Aucun nouveau chargeur, moteur, budget mémoire, schéma ou éditeur spécialisé.

L’audit a confirmé que `_narrative.error` était affiché globalement. La correction limite les diagnostics de consultation à leur contexte et conserve séparément un échec de publication tant qu’il n’est pas résolu. Les brouillons, documents et gardes de sauvegarde restent en place. La parité sémantique réutilise les actions existantes ; aucune nouvelle certification globale MCP, conformément au mandat UI-03.

## Fichiers et zones UI-03

Chemins ci-dessous relatifs à `apps/avelune_studio/`. Les autres différences UI-02 du dépôt sont conservées, sans les attribuer à ce lot.

| Fichier | Zone et effet |
| --- | --- |
| `lib/presentation/features/resources/resource_library_screen.dart` | Orchestration galerie/catégories/détail, réconciliation, repli compact et révélation contextuelle |
| `lib/presentation/features/resources/resource_catalog_toolbar.dart` | Nouveau composant recherche, nombre réel, tri, grille/liste et filtres |
| `lib/presentation/features/resources/resource_catalog_view.dart` | Nouvelle galerie/liste paresseuse, identités stables, hauteur adaptée, aperçus dominants |
| `lib/presentation/features/resources/resource_category_filter.dart` | Nouveau filtre réel, compteurs calculés en une passe |
| `lib/presentation/features/resources/resource_catalog.dart` | `ResourceItem.identity`, `visibleItems`, `reconcileSelection`, `reveal`, catégories/tri |
| `lib/presentation/features/resources/resource_navigation.dart` | Ouverture contextuelle avec catégorie/tags et conservation du reste de l’état |
| `lib/presentation/features/resources/resource_detail_panel.dart` | Grand aperçu, métadonnées, actions existantes, CTA fixe et garde sans carte |
| `lib/presentation/features/resources/resource_preview.dart` | Atlas complet ; activation explicite du motif terrain réservée à Ressources |
| `lib/presentation/features/resources/resource_terrain_preview.dart` | Nouveau motif via `PreparedSmartTileResolver` et miniatures existantes |
| `lib/presentation/features/resources/resource_workspace_pane.dart` | Carte cible transmise et erreur locale bornée |
| `lib/presentation/features/resources/resource_brush_selection.dart` | Retour sûr sans projet/carte ; choix explicite de tuile conservé |
| `lib/presentation/shared/widgets/inputs/studio_resource_card.dart` | Nom sur deux lignes configurable, tooltip ; valeur par défaut conservée |
| `lib/presentation/shared/widgets/layout/studio_resource_grid.dart` | Hauteur de carte optionnelle, virtualisation inchangée |
| `lib/presentation/shared/widgets/layout/studio_page_header.dart` | Alignement des actions optionnel, activé uniquement ici |
| `lib/presentation/features/map_workspace/workspace_compact_panel.dart` | Libellé de fermeture configurable ; défaut Carte conservé |
| `lib/presentation/features/map_workspace/map_workspace_screen.dart` | Portée du diagnostic narratif et nettoyage de notification au changement de contexte |
| `lib/presentation/features/map_workspace/workspace_home_binding.dart` | Ouverture d’interaction et notification locale, sans changer l’accueil |
| `lib/presentation/features/narrative/narrative_navigation.dart` | `workspaceNarrativeError` distingue consultation et publication |
| `lib/features/narrative/application/narrative_workspace_controller.dart` | Erreur de publication persistante jusqu’à un nouvel essai réussi |
| `test/presentation/resource_catalog_ui03_test.dart` | Identités homonymes, familles, filtres, catégories, tri et révélation |
| `test/presentation/resource_detail_ui03_test.dart` | CTA à 150 %, atlas ancien, neuf tuiles résolues, catégorie terrain/sans carte |
| `test/presentation/ui03_resource_journey_test.dart` | Parcours, captures, import annulé, trois usages avec geste/annulation, compact/contextuel |
| `test/support/ui03_resource_fixture.dart` | Catalogue temporaire reproductible utilisant les assets de test existants |
| `test/resource_io/resource_navigation_save_test.dart` | Préservation des brouillons et révélation malgré filtre |
| `test/narrative/narrative_error_scope_test.dart` | Erreur locale et erreur de publication persistante |
| `test/presentation/m2_end_to_end_test.dart` | Défilement jusqu’à la préparation, recherche de l’atlas 132 hors première page |
| `test/support/m2_ui_fixture.dart` | Bannière debug désactivée pour capturer aussi les overlays |

Ce dossier ajoute sept PNG, cette note et `verification.log`. Sept PNG d’icônes macOS sont également apparus modifiés pendant le travail, hors des modifications UI-03 : ils ont été laissés intacts. L’état Git final détaillé est dans le journal ; aucune écriture Git effectuée.

## Vérifications fraîches

Depuis `apps/avelune_studio` :

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub --reporter expanded test/presentation/ui03_resource_journey_test.dart test/presentation/resource_detail_ui03_test.dart test/presentation/resource_catalog_ui03_test.dart test/resource_io/resource_navigation_save_test.dart test/narrative/narrative_error_scope_test.dart
flutter test --no-pub --reporter expanded
flutter build macos --debug --no-pub
```

Résultats : **239 fichiers / 0 reformatté ; analyse sans problème ; 18 tests ciblés réussis ; 281 tests Studio réussis, 2 ignorés ; build macOS réussi**. Les deux tests ignorés réclament une copie externe via variable d’environnement (`studio_large_atlas_test`, `train_workspace_capture_test`). Les contrôles globaux incluent M1/M2/M3/UI01/UI02, l’architecture, les petits budgets de cache et le catalogue multi-atlas volumineux. Le parcours M2 rejoue import → décor → terrain → sauvegarde → réouverture → vrai runtime. Le test UI-03 vérifie séparément l’absence d’écriture après consultation/import annulé et les trois gestes annulables.

Pour reproduire les sept captures, ajouter `AVELUNE_CAPTURE_DIR="$PWD/../../documentation/reports/avelune_studio/UI03_ressources"` devant la commande ciblée. Les tests ont été surveillés avec enregistrement des PID descendants et vérification de leur identité : aucun harnais restant à terminer après les deux runs finaux. Les journaux initiaux ont permis de corriger des interactions de tests devenues défilantes, une attente I/O de fixture et une catégorie manquante dans la fixture ; aucun échec final masqué.

À la racine : `git diff --check` et `POKEMAP_MARKDOWN_MAX_NEW=2 bash tools/scripts/check_markdown_hygiene.sh`. Le budget de deux couvre uniquement les deux notes explicitement demandées : UI-02 préexistante et UI-03.

## Passes et limites

- Audit/architecture : réemploi confirmé ; isolation du diagnostic narratif nécessaire et bornée.
- Implémentation catalogue/navigation : revue indépendante, fermeture compacte et révélation contextuelle corrigées.
- Implémentation détail/aperçus : cache existant conservé ; aucune image fictive de remplacement.
- Tests/build : résultats ci-dessus sur le code final ; captures hors écran, pas de session native conduite.
- Critique finale indépendante : aucun nouveau défaut bloquant confirmé, validation visuelle utilisateur toujours ouverte.

Le motif terrain couvre les raccords mono-partie 1 × 1 alignés sur un atlas régulier. Pour les compositions complexes, offsets et atlas décalés, le message « Aperçu du raccord non préparé » reste explicite ; l’utilisation du moteur existant est conservée. Les usages concernent seulement les cartes ouvertes. Les ressources anciennes restent consultables avec leurs limites. Les captures emploient des assets de fixture simples : elles ne certifient pas le rendu artistique de tous les projets utilisateur. Aucun nouvel écran commencé.

Lancement : `cd apps/avelune_studio && flutter run -d macos`. Arrêt de la mission à la validation visuelle de Yoahn.
