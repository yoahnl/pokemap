# Avelune Studio — M1 UX et ressources

Mission exécutée le 19 septembre 2026 sur `/Users/karim/Project/pokemonProject`.

**Verdict : les trois chantiers sont livrés et vérifiés fonctionnellement et visuellement en Flutter. Le parcours macOS complet reste non certifié : le pilote a échoué après l'accueil, puis lors de l'unique rattachement autorisé.** Ce défaut d'outil n'a pas interrompu l'implémentation ni la recette déterministe. Aucun crash applicatif n'est établi par cet essai.

## Résultat et réemploi

- Présentation desktop sombre inspirée des maquettes fournies : thème bleu anthracite, commandes rectangulaires compactes, deux rangées d'outils stables, palette 250 px, inspecteur 270 px, repli des panneaux et listes indépendantes. Accueil avec sélecteur principal et saisie exacte protégée. Aucun bouton fictif.
- Diagnostics structurés, dédupliqués, une ligne en bas et détails virtualisés bornés à 70 % de la fenêtre. Filtres carte active / ressources demandées, cause et détail technique, pression mémoire regroupée, réessai ciblé. Les ressources froides ne sont pas déclarées manquantes. Les conflits de sauvegarde restent visibles séparément.
- Métadonnées ouvertes sans décodage. Ordre de demande : carte, pinceau, vignettes visibles. Cache de 256 Mio décodés avec éviction des images non retenues ; un décodage à la fois, plafonné à 64 Mio encodés et 64 Mio décodés par image. Les consommateurs gardent une retenue jusqu'à leur retrait. Retour A → B → A, réessai, invalidation et fermeture pendant décodage testés.
- Réemploi de `resolveTilesetAbsolutePaths`, du résolveur de projections, de `RuntimeAuthoringMapRenderer`, du décodeur et de `RuntimeTilesetImageSingleFlightCache`. Seules extensions de `map_runtime` : exports publics ciblés et éviction d'une image du cache. Aucun deuxième renderer.
- Palette virtualisée avec recadrages de tuiles et décors vérifiés par pixels. Recherche, pinceau et onglet conservés. Inspecteur avec sélection masquée, rang local et disponibilité calculée par la même opération partagée que le changement d'ordre.
- Riverpod et les frontières architecture restent en place. Aucun changement de format, de collisions, de persistance ni nouvelle opération d'auteur ; pas de surface MCP supplémentaire nécessaire.

## Preuves visuelles inspectées

L'accueil ci-dessous est une **capture de l'application macOS exécutée**, prise pendant le premier build d'intégration. Les autres captures sont les **vrais widgets Flutter exécutés hors écran sur le code final**, avec adaptateurs disque, décodeurs, renderer, données et polices réels. Elles ne prouvent pas des clics natifs ni la fluidité GPU.

| État | Preuve |
|---|---|
| Accueil natif | [Capture macOS](evidence/native-home.jpg) |
| Train, palette et sélection masquée, position 2 / 2 | [Carte réelle sur copie](evidence/train-hanazuki-carte-palette-empilement.png) |
| Incident mémoire réel du Train | [Détail borné](evidence/train-hanazuki-diagnostics.png) |
| 200 incidents, canvas conservé | [Résumé compact](evidence/workspace-200-diagnostics-compact.png) |
| Liste des 200 incidents et réessai ciblé | [Détails](evidence/workspace-200-diagnostics-details.png) |
| Aperçus des tuiles | [Palette de tuiles](evidence/workspace-tile-thumbnails.png) |
| 1024 × 640, texte 175 % | [Petite fenêtre](evidence/workspace-1024x640-text175.png) |
| 1280 × 800 | [Disposition desktop](evidence/workspace-1280x800-text100.png) |
| 1600 × 1000 | [Grande fenêtre](evidence/workspace-1600x1000-text100.png) |

Six combinaisons taille/texte testées : 1024×640, 1280×800, 1600×1000 avec texte 100 % et 175 %. Aucun overflow masqué. À 1280×800 avec panneaux normaux, la zone du canvas mesure 760 px de large et dépasse 480 px de haut. Les problèmes observés durant l'intégration — petit en-tête, typographie de boutons dans les captures, onglets en texte agrandi — ont été corrigés puis recapturés.

## Projet réel, volumes et limites

Copie autonome créée sous `/Users/karim/Documents/Codex/2026-09-19/nous-terminons-la-validation-native-d/work/train-copy` : 12 289 fichiers, 667 309 112 octets, aucun lien symbolique, inodes distincts. Le cache historique de 15,44 Go et les verrous ont été exclus. Les 622 chemins de ressources inventoriés étaient relatifs et internes.

Le Train contient **329 atlas, 1 669 décors et 39 cartes**. Mesure de la recette finale : **0 lecture d'image à l'ouverture des métadonnées**, puis **52 lectures / 51 décodages**, dont les dépendances des cartes traversées et les vignettes visibles. Résidence graphique : **131 465 216 octets**, inférieure aux 256 Mio. L'estimation d'allocation transitoire maximale est 166 121 182 octets ; ce compteur n'est pas une mesure de RAM système. [Mesures originales](evidence/train-resource-stats.json).

L'atlas `hgss-buildings-assembled` dépasse la limite locale de décodage par image : incident **pression mémoire**, et non fichier absent. Il reste référencé et réessayable. Les bordures gardent la limite M1 de prévisualisation ; le runtime existant les prend en charge. Pas de mesure FPS ni de trace profile native.

La fixture reproductible contient 132 atlas valides, un atlas tardif 131, 200 incidents, trois cartes et des décors superposés. Le test de petit budget prouve l'éviction/rechargement et la protection d'une image encore retenue. Les variantes de transparence, le partage concurrent, les résultats tardifs et le réessai pendant disparition d'une vignette sont couverts.

Aucune écriture de cette mission n'a ciblé le projet original. **Une modification concomitante de l'original a néanmoins été constatée sur `maps/hanazuki-gare.json` ; son auteur n'est pas attribué.** La copie de recette est restée strictement identique à son empreinte initiale ; aucune restauration de l'original n'a été tentée. [Empreintes et constat](evidence/original-drift.txt).

## Contrôles exécutés

| Contrôle | Résultat |
|---|---|
| Suite Studio complète, incluant vraie copie Train et captures | **146 tests passent**, exit 0 — [sortie](evidence/studio-acceptance.txt), [reçu](evidence/studio-acceptance.json) |
| Cache, codecs, ordre/rendu du package runtime modifié | **29 tests passent**, exit 0 — [sortie](evidence/runtime-regressions.txt), [reçu](evidence/runtime-regressions.json) |
| Analyse Studio | **Aucune anomalie**, exit 0 — [sortie](evidence/analyze-acceptance.txt) |
| Format de 84 fichiers | **Aucun changement requis**, exit 0 — [sortie](evidence/format-check.txt) |
| Build macOS debug final | **Réussi**, exit 0 — [sortie](evidence/build-acceptance.txt), [reçu](evidence/build-acceptance.json) |
| Diff et hygiène Markdown | **Réussis**, un seul nouveau Markdown canonique — [constat final](evidence/final-checks.txt) |
| Parcours natif | Accueil observé ; sélection de dossier : timeout, unique rattachement : noWindowsAvailable — [constat](evidence/native-observation.txt) |

Les parcours conservés couvrent placement, déplacement, ordre, annuler/rétablir, sauvegarde/lecture, conflits, fermeture avec travail modifié, vrai runtime exécuté sur l'exemple et retour. Les tests d'architecture vérifient aussi les dépendances transitives et les fichiers manuels ≤300 lignes.

Aucune commande Flutter concurrente. Le harness bloqué d'un essai intermédiaire a été arrêté par son PID propre ; aucun arrêt global. Les erreurs intermédiaires et sorties historiques restent conservées dans le dossier de preuves du dépôt, distinctes des reçus finaux ci-dessus.

## Reproduire

Depuis `/Users/karim/Project/pokemonProject/apps/avelune_studio` :

```sh
dart run tool/create_example_project.dart
flutter run -d macos --no-pub
```

Ouvrir le dossier temporaire imprimé avec **Ouvrir un projet**. Le sandbox macOS peut imposer cette sélection avant une ouverture par saisie manuelle. Pour le stress, choisir une destination encore inexistante :

```sh
dart run tool/create_example_project.dart --stress /tmp/avelune-stress-nouveau
flutter test --no-pub
flutter analyze --no-pub
flutter build macos --debug --no-pub
```

La recette avec captures utilise `AVELUNE_CAPTURE_DIR` et `AVELUNE_PROJECT_COPY` ; les arguments exacts et chemins isolés sont dans `studio-acceptance.json`. Sans ces variables, le test optionnel Train est ignoré. Les polices de capture nécessitent macOS et le SDK Flutter présents lors de cette recette.

## État du dépôt

Branche **main**, HEAD initial/final **3482dddf6d2a2143cbb985a3b1cca82d9216dbf6**, index vide de modifications. Aucun add, commit, push, branche ou autre écriture Git ; aucune modification Notion.

**45 fichiers source/documentation Studio et runtime modifiés ou ajoutés**, détaillés avec leurs SHA-256 dans [l'état final](evidence/final-source-state.json), plus ce rapport et ses preuves. Le périmètre principal est `apps/avelune_studio/lib/presentation`, `platform/rendering`, les tests et fixtures ; deux fichiers publics/infrastructure de `packages/map_runtime`. Le README Studio décrit maintenant le chargement réel, le parcours et ses limites.
