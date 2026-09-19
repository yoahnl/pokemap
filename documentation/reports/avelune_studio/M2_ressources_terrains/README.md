# M2 — Des ressources à la carte, sans détour

Le parcours livré utilise les vrais fichiers et moteurs : bibliothèque → import PNG
→ décor ou terrain cardinal à seize raccords → carte → sauvegarde → runtime.
M1 reste disponible : déplacements, empilement, tuiles, historique, vues et test.
Aucune gestion manuelle de calques, écriture Git, modification Notion ou écriture
dans un projet original. Les fichiers sont laissés à relire, sans commit.

## Audit initial et décisions

Base propre : `main`, HEAD `3e9352b1f259fffcd834dd94dfba67021b338b7b`, index vide
([état initial](evidence/initial-state.txt)). Le fichier M2 fourni est la référence
écrite ; `PROMPT_CODEX.md`, `REFERENCES_VISUELLES.md` et les maquettes `references/`
n’étaient pas présents dans les emplacements examinés. Aucune conformité visuelle
à ces fichiers absents n’est revendiquée.

L’audit a retrouvé les transactions/journaux authoring, le projecteur d’import,
les modèles de décors, les drafts Smart Tiles, leur résolveur, la composition de
carte et le runtime M1. Les risques centraux étaient la révision du manifeste
pendant une édition locale, la durée de vie des images, le gros atlas refusé et
la perte des brouillons lors de la navigation. L’architecture Riverpod actuelle,
ses ports purs et les adaptateurs `platform` sont conservés.

- `tileset.import_image` compose staging, projection d’atlas et manifeste dans
  une transaction canonique récupérable. Le premier décor peut créer sa catégorie
  dans cette même chaîne. Les transactions multi-fichiers ont un journal de reprise,
  pas une garantie de visibilité simultanée de tous les fichiers.
- Le port ressources et le port cartes partagent une file d’écriture. Un reçu
  valide avance la révision propre au Studio ; les conflits externes demeurent
  bloquants, y compris pour une sauvegarde sans changement apparent.
- Les documents et contrôleurs de brouillons survivent au changement d’espace.
  La fermeture sauvegarde un snapshot, protège les modifications concurrentes
  et fige les interactions pendant l’opération.
- Le terrain réutilise `PreparedSmartTileResolver` et les gestes natifs. Un test
  de pixels runtime a révélé un support masqué par le sol : son insertion utilise
  maintenant le plan de composition existant. Aucun nouveau résolveur parallèle.
- Le cache conserve 256 Mio résidents et admet un décodage à la fois dans une
  enveloppe estimée de 512 Mio : `4 × RGBA + 2 × encodé + images retenues`.
  Ce n’est pas une mesure du RSS. Pas de prétendu décodage partiel : les chunks
  runtime viennent après le décodage. Les générations utilisées restent vivantes.

## Fichiers et zones

L’[inventaire exhaustif](evidence/file-inventory.tsv) donne pour chaque source ou
test créé/modifié son chemin, ses classes ou hunks Git et son rôle. Le diff local
reste la preuve canonique ; aucune copie intégrale des sources n’est ajoutée.

| Zone | Changement et effet |
| --- | --- |
| Studio `app/di`, `studio_bootstrap`, `studio_workspace_host` | Injection du port ressources avec le même adaptateur cartes ; durée de vie du workspace conservée. |
| `features/resources`, `features/decors`, `features/terrains` | Reçus, publication, brouillons, sélection exacte, variantes, collision indépendante de l’occlusion, règles et pinceau natifs. |
| `presentation/features/resources`, `terrains` | Bibliothèque virtualisée, import, préparation, essai, correction et reprise ; détails et actions contextuelles. |
| `presentation/features/map_workspace` | Navigation, pinceaux, traits interpolés, empilement, fermeture et maintien des vues M1 ; reprise du pinceau terrain après déplacement de la vue. |
| `platform/files`, `platform/rendering` | Sélecteur PNG, aperçu source, invalidation ciblée, budget et diagnostic déterministe. |
| `map_authoring` | Action sémantique d’import, création de première catégorie, API/JSONL et récupération testées. |
| `map_core` | Extraction ciblée de création de support Smart Tile depuis la carte active autoritative ; garde de l’ancienne API préservée. |
| `map_runtime` | Export du collecteur de dépendances terrain et maintien des images détachées encore utilisées. |
| `tools/pokemap_mcp/test` | Import complet par serveur stdio empaqueté et worker réel. |

Les packages moteur ne sont modifiés que pour ces trois contrats ciblés autorisés
par M2. Pas de modification de l’ancien éditeur, de dépendance ou de configuration native.

## Vérifications exécutées

Chaque lien mène à la sortie complète ; son fichier `.json` voisin contient la
commande exacte, le répertoire, les heures, le code de sortie et le suivi des
processus du runner. SDK Flutter/Dart de `/opt/homebrew/share/flutter/bin`.

| Commande / périmètre | Résultat et preuve |
| --- | --- |
| Studio `flutter test --no-pub` | [186 passés, 2 ignorés](evidence/studio-release-check.txt), code 0, dont PNG illisible avec annulation propre. |
| Studio `flutter analyze --no-pub` | [No issues found!](evidence/studio-analyze-final-check.txt), code 0. |
| Studio `flutter build macos --debug --no-pub` | [Avelune Studio.app construit](evidence/macos-final-check.txt), code 0. |
| Interface réelle, import → décor → terrain → sauvegarde/réouverture → runtime ; 720 px et texte 150 % | [2 tests et six captures](evidence/ui-captures-verified.txt), code 0 ; vrais adaptateurs et transactions. |
| Collision du décor importé dans le runtime | [2 tests ciblés](evidence/ui-runtime-collision.txt), code 0 : déplacement de (8,9) vers (8,7), puis blocage effectif avant (8,6). |
| Ressources locales, conflits, variantes, champs préservés et publication terrain | [11 tests](evidence/resource-controller-verified.txt), code 0. |
| Fermeture avec brouillons et écritures concurrentes | [3 tests](evidence/resource-draft-close-regression.txt), code 0. |
| `map_authoring`: import, contrats bibliothèque et transport JSONL | [21 tests](evidence/resource-canonical-regression.txt) ; [5 tests import/reprise](evidence/resource-jsonl-recovery.txt), codes 0. |
| `map_core`: création de supports natifs | [19 tests](evidence/terrain-core-creation.txt), code 0. |
| Terrains Studio et vrai runtime | [10 tests](evidence/terrain-all-verified.txt) ; [pixels exacts et déplacement](evidence/terrain-runtime-order.txt), codes 0. |
| Cache runtime : rétention, codec, single-flight, chunks | [23 tests](evidence/cache-runtime-tests.txt), code 0. |
| Catalogue, invalidation au même chemin et atlas HGSS réel | [5 tests](evidence/cache-updates-v2.txt), code 0 ; voir mesure ci-dessous. |
| Source ajustée, zoom et masque entièrement visible | [6 tests](evidence/atlas-fit-mask-final.txt), code 0. |
| Analyses ciblées partagées | [Authoring](evidence/resource-canonical-analysis.txt), [cache/runtime](evidence/cache-analysis-final.txt), [terrains](evidence/terrain-analysis-clean.txt) : sans problème. |
| MCP `npm run check`, `npm run build`, test stdio empaqueté | [check](evidence/resource-mcp-check.txt), [build](evidence/resource-mcp-build.txt), [1 test réel](evidence/resource-mcp-live-targeted.txt), codes 0. |

Les deux tests conditionnels demandent une copie externe : le test gros atlas a
été exécuté séparément avec cette copie ; l’ancienne recette de capture Train M1
reste ignorée dans la suite ordinaire. Le catalogue HGSS contient **329 atlas** ;
le décor `hgss-building-001` est réellement rendu depuis `hgss-buildings-assembled`
(4096 × 5280) avec **1 lecture, 1 décodage, 86 507 520 octets résidents** et
**347 528 926 octets estimés au pic**, sous le budget de 536 870 912 octets.

Les passes rouges ont conduit à corriger la composition terrain, les longues
étiquettes et le retour à la ligne du bandeau avec texte agrandi. Deux preuves
intermédiaires significatives sont conservées : [pixels terrain](evidence/terrain-runtime-correct-zone.txt)
et [débordements](evidence/studio-suite-verified.txt). Les sorties finales font foi.
Les harnais de tests suivis par PID/parent/identité ont été réapés ; aucun harnais
possédé restant dans les reçus finaux. Les services Xcode `ibtoold` ne sont pas
assimilés à des harnais de test.

## Captures et limite native

Six captures **du logiciel Flutter exécuté hors écran**, avec polices desktop,
vrais PNG et vrai stockage temporaire. Elles ont été relues ; elles ne sont ni
des maquettes générées ni des captures de fenêtre native. Les dessins de test
sont synthétiques ; les seize associations illustrent les règles, pas une
validation artistique d’un tileset de production.

1. [Bibliothèque](captures/01-bibliotheque.png).
2. [Décor, rectangle exact et collision](captures/02-preparation-decor.png).
3. [Retour sur la carte et placements](captures/03-carte-nouveau-decor.png).
4. [Empilement et rang d’instance](captures/04-empilement.png).
5. [Terrain automatique et essai](captures/05-terrain-et-essai.png).
6. [132 ressources, largeur 720 et texte agrandi](captures/06-catalogue-volumineux.png).

Le [nouveau binaire démarre](evidence/native-run.txt), mais le pilote CUA renvoie
l’ancienne fenêtre M1 avec un projet non enregistré, même après une réattache.
Aucune interaction n’y a été faite. L’instance lancée pour M2 a été identifiée
puis arrêtée seule ([trace native](evidence/native-observation.txt)). Le dialogue
système de choix PNG n’est pas certifié ; son résultat est injecté dans le vrai
parcours d’import testé. Marionette n’était pas instrumenté dans cette app.
Le MCP configuré échoue avec `worker.exited`, code 78 ([trace](evidence/configured-mcp.txt)) ;
la preuve stdio empaquetée est distincte et ne prétend pas réparer cette connexion.

## Critique finale et limites

Verdicts : agent ressources/transactions **validé**, y compris seconde critique
de fermeture ; agent terrains **validé** après correction du support ; agent
cache/source **validé** après contrôle des images retenues et des captures.
Passes racine audit/architecture, intégration, tests et build : effectuées,
avec les réserves natives ci-dessus. Aucun blocage fonctionnel identifié dans
le périmètre de création cardinal à seize raccords.

La préparation des autres modèles de terrain, l’édition des catégories et le
comptage d’usages sur les cartes non ouvertes restent incomplets. Les conversions
de décor incompatibles avec la grille projet sont désactivées avec une raison,
sans rééchantillonnage silencieux ; les sources anciennes sans métadonnées ne
permettent pas de parcourir toutes leurs tuiles. L’import préparé est PNG et
limité à 64 Mio décodés, distinct du gros atlas déjà présent et maintenant lisible.
L’aperçu des animations reste à la première frame ; les limites M1 de bordures et
d’ordre entre contextes de composition restent explicites. Aucun lot suivant engagé.

## Lancement

Depuis `apps/avelune_studio` : `dart run tool/create_example_project.dart`, puis
`flutter run -d macos --no-pub`. Ouvrir le dossier temporaire imprimé ; sa planche
`assets/atelier.png` peut servir à essayer l’import. Le [README Studio](../../../../apps/avelune_studio/README.md)
décrit les parcours et les contraintes. État final détaillé : [Git et vérifications](evidence/final-state.txt).
