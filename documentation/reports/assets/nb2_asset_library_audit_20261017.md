# NB2 — Inventaire des ressources de cartes et acquisition 2D

Date : 17 octobre 2026. Lot : **NB2-MAP-SOURCE-INVENTORY-20261017**. Contexte produit existant : **POST-WLD-ASSET-PACK-001**, domaine Monde & narration, hors gate bêta. État proposé pour cette sous-tranche : **TO REVIEW**, avec réserves explicites. Aucun DONE demandé ni appliqué.

## Décision de périmètre et résultat

La dernière instruction de Yoahn remplace l’interprétation « toutes les ressources du jeu » : l’objectif concerne **uniquement les ressources graphiques pour créer toutes les cartes NB2, extérieurs ET intérieurs**. Sont inclus sols, paths, bordures, reliefs, bâtiments, mobilier, décors, mécanismes, personnages et Pokémon visibles dans le monde, objets et effets/animations de terrain. Sont exclus les sprites et fonds de combat, interfaces, icônes de menus, polices, audio et illustrations ne constituant pas des éléments de carte. Aucune extension du format de pack vers ces catégories exclues n’est requise par cette tranche.

La collecte et le classement des **sources énumérées** sont livrés. La couverture de chaque état officiel Noir 2/Blanche 2 n’est **pas certifiée** : `officialAllMapStateCoverageProven:false`. Les sept réserves structurées ci-dessous empêchent toute formule « tout NB2 est prêt ». Ce bilan distingue fichiers absents, identités/associations inconnues, séquences à interpréter et modules natifs non fabriqués.

Le classeur courant est [cartes-20261017/NB2 — Inventaire des ressources de cartes.xlsx](</Users/karim/Project/Avelune Projects/nb2_bibliotheque_modulaire/library/inventaire/cartes-20261017/NB2 — Inventaire des ressources de cartes.xlsx>), **23 onglets** filtrables. Le registre complet est [inventaire-cartes.json](</Users/karim/Project/Avelune Projects/nb2_bibliotheque_modulaire/library/inventaire/cartes-20261017/inventaire-cartes.json>). Les anciens classeurs/audits restent des preuves datées ; le présent rapport et `cartes-20261017` constituent la projection du périmètre corrigé.

## Audit initial

L’inventaire existant contenait déjà les 717 archives publiques, des sélecteurs géométriques, recettes, variantes, références ROM et sept planches 2D. Le piège initial était de lire « 79 fiches 2D moins 7 acquises » comme « 72 ressources de cartes manquantes ». Après examen du catalogue et des fiches ambiguës, ces 72 fiches sont **hors périmètre cartes**. Les six fiches strictement cartographiques étaient déjà acquises ; les accessoires du Musical restent dans une catégorie mixte séparée.

Les sources originales sous Downloads ont été ouvertes en lecture seule. Neuf fichiers de travail sensibles ont été protégés par SHA et taille : `project.json`, sept cartes et le pack cumulatif. Ils sont inchangés. L’inventaire produit ici est externe au code et aux données de jeu ; aucune commande d’authoring, import de ressources, map ou pack n’a été appliquée.

## Grandes familles et besoins

| Groupe | Famille | Groupes de besoins nominatifs |
|---|---|---:|
| 01 | Sols naturels et urbains | 9 |
| 02 | Végétation et herbes | 8 |
| 03 | Bordures dessinables | 7 |
| 04 | Falaises, reliefs et accès | 8 |
| 05 | Eau, rivages et effets | 9 |
| 06 | Bâtiments de toutes les villes | 9 |
| 07 | Architecture intérieure | 8 |
| 08 | Mobilier intérieur | 10 |
| 09 | Décors et transports | 10 |
| 10 | Biomes, grottes et donjons | 8 |
| 11 | Lieux et structures spécifiques | 8 |
| 12 | Personnages, sprites et effets 2D | 6 |

Les **100 groupes de besoins** ne constituent pas 100 assets. Chaque ligne de `besoins-cartes.csv` conserve les variantes/pièces à fournir, l’usage natif envisagé et les sources candidates. Les associations historiques par nom sont explicitement marquées comme candidates ; les preuves exactes de propriété géométrique restent dans les registres de sélecteurs.

## Corpus 3D : disponibilité, admission et découpage

Les 717 originaux du [catalogue NB2 Models Resource](https://models.spriters-resource.com/ds_dsi/pokemonblack2white2/) ont été rehashés et vérifiés par CRC ZIP pendant cette tranche. Ils sont répartis ainsi :

| Décision | Publications |
|---|---:|
| Sources de cartes/décors | 691 |
| Modèles de créatures, emploi monde à confirmer | 13 |
| Géométrie de scène du monde à confirmer | 1 |
| Anciennes scènes, références séparées | 6 |
| Combat, titre et contenu inutilisé exclus | 6 |
| **Total du catalogue** | **717** |

L’index source conserve **2 640 définitions géométriques typées** et **3 494 occurrences**. Après resserrement du périmètre : **2 618 candidats de cartes**, **21 définitions uniquement de référence ancienne**, **une définition inutilisée exclue**. Une définition neutre partagée n’autorise pas la fusion des rigs, pivots ou animations : les occurrences gardent ces propriétés et leurs sélecteurs exacts. Ces nombres ne comptent ni des kits Avelune prêts ni toutes les cellules de terrain comme des assets indépendants.

Les ingrédients de terrain conservent leurs index de faces, matériaux, UV et périodes mesurées dans `exhaustive/variants/terrain/`. Les 24 OBJ ont des décisions par fichier dans `resolution/obj/obj-normalization.json`, avec exceptions/remplacements ; aucun facteur `/16` global arbitraire n’est appliqué. La Route 19 est complétée par sa source ROM dérivée existante, absente du catalogue public. Les 306 recettes et leurs 2 484 occurrences restent disponibles ; le présent lot ne les convertit pas en ressources natives.

## Sources 2D publiques : sélection exhaustive du catalogue

Le [catalogue NB2 Spriters Resource](https://www.spriters-resource.com/ds_dsi/pokemonblack2white2/) a été relevé à nouveau via son DOM public : **79 identifiants et 79 URL individuelles** sont consignés. Chaque fiche reçoit exactement une décision :

| Décision | Fiches | Contenu |
|---|---:|---|
| Pertinentes et acquises | 6 | Mélis, Écho, entités du monde, Pokémon du monde, affiches de films, télévision de l’arène de Méanville |
| Mixte, non comptée dans le cœur | 1 | 101 accessoires du Musical, emploi dans une scène à confirmer |
| Exclues | 72 | Combat, interface, portraits, inventaires, présentations et illustrations hors construction des cartes |

Le corpus strict des six fiches représente **965 unités graphiques** et **7 395 poses/emplacements** : **7 096 poses dessinées**, 233 placeholders et 66 emplacements vides. Il ne s’agit pas de 965 personnages ou Pokémon uniques. Les propriétaires multiples d’une pose restent conservés.

Cinq originaux supplémentaires ont été téléchargés depuis le bouton public dans le navigateur intégré, soit **2 024 861 octets**. Les refus HTTP 403 initiaux des appels automatisés sont historiques et résolus par la voie publique du navigateur, sans contournement. Les trois onglets de recherche ont été fermés.

- [BW Overworld Entites 34109](https://www.spriters-resource.com/ds_dsi/pokemonblackwhite/asset/34109/) et [BW Old-Gen Overworld Pokémon 34110](https://www.spriters-resource.com/ds_dsi/pokemonblackwhite/asset/34110/) : compléments de comparaison acquis.
- [Pokémart Screen Rip 158807](https://www.spriters-resource.com/ds_dsi/pokemonblack2white2/asset/158807/) : interface de magasin, exclue après inspection.
- [Pokéwood Cutscenes 48046](https://www.spriters-resource.com/ds_dsi/pokemonblack2white2/asset/48046/) : illustrations, exclues après inspection.
- [Keldeo and Kyurem Transformations 48131](https://www.spriters-resource.com/ds_dsi/pokemonblack2white2/asset/48131/) : portraits/orbes/effets de transformation, exclus du cœur cartographique.

Les sept PNG précédents sont référencés sans duplication. Les douze originaux sont vérifiés par SHA, dimensions, signature PNG, CRC des chunks et décompression IDAT. Les auteurs de publication et notices observées sont conservés dans `originals-provenance.json` ; une notice de crédit n’est pas transformée en licence des droits sous-jacents.

Comparaison des compléments BW : 3 490 rectangles / 3 414 motifs RGBA distincts de 34110 correspondent exactement après suppression du fond uni et recadrage aux poses NB2. Pour 34109, aucun match RGBA exact ; 939 rectangles / 880 motifs n’ont qu’une correspondance de forme après relabellisation des couleurs. Les pixels et palettes ne sont donc pas déclarés identiques. Un rectangle sans match ne devient jamais automatiquement un manque NB2.

## Sources originales du monde récupérées depuis la ROM

ROM privée : `Pokemon - Version Blanche 2 (France) (NDSi Enhanced).nds`, **IRDF**, 536 870 912 octets, SHA `a21dc750a0a0794d70f4298083a8359182f130bf3e20b805f21ff487f97a3498`, recontrôlé intégralement. Accès `rb`/`mmap.ACCESS_READ`. Les copies ciblées conservent FAT ID, offset, taille et SHA ; aucune reconstruction ou écriture de ROM.

| Source | Inventaire vérifié |
|---|---|
| `a/0/4/7` | 1 008 configurations uniques : 968 acteurs, 11 objets, 29 placeholders ; aucune référence hors limites |
| `a/0/4/8` | 975 membres : 968 BTX0 et sept BMD0 ; 7 528 textures et 978 palettes |
| `a/0/7/4` | 159 membres d’effets de carte ; 254 textures ; 59 animations : 11 PAT0, 24 JNT0, cinq MAT0, 19 SRT0 |
| `a/2/0/8` | 620 variantes d’overworld pour 546 espèces ; 620 liaisons exactes aux UID |
| `a/2/0/0` | Six courbes brutes originales conservées ; le premier entier n’est pas présenté comme un FPS |
| `a/1/2/6` | 616 fichiers d’entités ; 3 146 placements PNJ ; 248 codes d’apparence, tous liés exactement au registre |

**7 782 / 7 782 textures** des deux banques graphiques principales ont été extraites en PNG, soit 7 528 acteurs et 254 effets. Chaque PNG a une correspondance RGBA indépendante avec la texture et une ou plusieurs palettes originales exactes. Une égalité de palettes peut conserver plusieurs candidats ; elle ne prouve pas la sélection originale en jeu.

Les PNG sont regroupés dans [map-original-textures.zip](</Users/karim/Project/Avelune Library Work/nb2-20261017/map-inventory-20261017/rom-coverage/map-original-textures.zip>) : **9 673 937 octets**, SHA `7dc8b2f72e468650e845c24ce936a5bda06ee427c178bec1a98643e055530b61`, CRC correct, zéro doublon. Ce sont des **textures/frames sources**, pas 7 782 nouveaux assets Avelune uniques.

Le binaire local [apicula épinglé](https://github.com/scurest/apicula/tree/3d4e91e14045392a49c89e86dab8cb936225588c) a été réutilisé sans installation/build. Les processus de conversion ont tous été attendus, leurs sorties transitoires DAE supprimées par leurs contextes temporaires, et les PNG archivés immédiatement.

La seule texture initialement omise, `mv_kusa.5` du membre 94, a été récupérée avec **la liaison originale PAT0 109**, frame 15, palette `mv_kusa`. Aucune palette inventée. Les onze PAT0 de cette banque conservent **17 pistes et 56 clés de frame**. Les noms internes `kusaeff`, `lgrass_ani1`, `ripple`, `taki_loop_s`, `shibuki`, `freshwater_in/out` constituent des pistes précises pour les réactions d’herbe, remous et éclaboussures ; leur cadence/déclencheur restent à qualifier.

## Complément météo séparé

La [liste primaire de NARC](https://gist.github.com/PlatinumMaster/9a12681f6c001a052444b21a27eb9f11) et les lecteurs CTRMap ont permis de localiser trois sources supplémentaires, **119 200 octets** cumulés : `a/3/0/0` (12 membres), `a/0/5/5` (44) et `a/0/9/6` (deux). Le registre total contient maintenant **neuf archives**. Les 58 membres supplémentaires ont chacun SHA et offset.

Les **17 textures Nitro** complémentaires ont été récupérées et vérifiées indépendamment en RGBA, dans un ZIP séparé de 9 016 octets, SHA `e8c35c12a23925a1b4bd2057bae33878cf3df3aaa02a4b79b0906e1b1e4b291d`. Elles ne sont pas ajoutées aux 7 782 du cœur pour annoncer un faux nombre d’assets utiles.

Les **39 membres NCGR/NCLR/NCER/NANR/NSCR** de `a/0/5/5` sont conservés dans leur format original. Leur composition en cellules, leurs palettes et leur lecture restent à établir. Les noms `intro_gm1_sp/su/au/wi` de `a/3/0/0` sont conservés : emploi exact dans le monde ou dans une présentation saisonnière non prouvé. Le calendrier contient 24 liaisons de zone × 366 entrées, avec IDs météo bruts ; les noms pluie/neige ne sont pas déduits sans preuve.

## Variantes et réserves restantes

Les index originaux préexistants conservent 615 headers de zones, 409 aires, 416 matrices, 1 065 chunks et 74 règles de remplacement. Ce ne sont pas des comptes de lieux jouables uniques. Les 20 matrices explicites ont 64 cellules et 62 définitions source. Les 57 paires géométriques examinées incluent 46 paires de polygones XYZ différents : une variante ne se résume pas toujours à une texture.

| Réserve | Type | Quantité / unité | Ce qui reste réellement inconnu |
|---|---|---|---|
| MAP-GAP-01 | IDENTITÉ | 247 entités publiques sans légende | Nom métier exact et rapprochement de chaque cellule publique avec UID original. |
| MAP-GAP-02 | SÉQUENCES | 1008 configurations originales, dont placeholders et objets | Ordre effectif, mirroring, boucle et cadence par contrôleur ; le champ controllerType est disponible. |
| MAP-GAP-03 | USAGE | 159 membres de la banque effets, pas 159 effets uniques | Association finale modèles/textures/clips à chaque déclencheur de terrain, et cadence. |
| MAP-GAP-04 | VARIANTE | 166 contextes conditionnels du graphe ROM | Sélection effective des branches et banques en jeu ; graphes alternatifs conservés. |
| MAP-GAP-05 | COUVERTURE | Non dénombré écarts exclusifs Noir 2 restant non certifiés | Preuve de couverture de tous les états Noir 2, au-delà des variantes publiques explicites. |
| MAP-GAP-06 | FABRICATION | Non dénombré modules natifs à produire | Pivots, collisions, règles de dessin, aperçus et ressources natives pour les lots suivants. |
| MAP-GAP-07 | COMPOSITION MÉTÉO | Non dénombré systèmes météo et effets pilotés par code | Banques candidates a/3/0/0 et a/0/5/5 récupérées ; composition des cellules 2D, paramètres et déclencheurs à qualifier. Les modèles intro_gm1_* peuvent relever de présentations saisonnières ; emploi sur les cartes non prouvé. |

Aucune absence de fichier dans les **entrées explicitement inventoriées** n’a été relevée après acquisition. Cela ne prouve pas qu’aucune ressource exclusive à un état Noir 2 non encore rapproché ne manque. Les sélections conditionnelles du graphe et l’accessibilité par les scripts restent distinctes d’un inventaire de sources. Les 166 contextes ont des ressources graphiques présentes ; leur sélection effective n’a pas été qualifiée.

Les canaux MAT0 couleur/alpha et VIS0 visibilité, ainsi que les conversions APAD/GFBTP et déclencheurs, devront être considérés pendant la fabrication selon leur usage réel. Aucun nouveau support moteur n’est prétendu ici. Le nombre de frames originales ne suffit pas à établir une durée en secondes.

## Livrables et fichiers modifiés

Un seul fichier du dépôt est modifié par cette tranche : le présent rapport `documentation/reports/assets/nb2_asset_library_audit_20261017.md`, dont le périmètre et les conclusions remplacent l’ancienne interprétation englobant combat/UI/audio.

Hors dépôt et hors iCloud :

| Chemin | Zone et rôle |
|---|---|
| `/Users/karim/Project/Avelune Projects/nb2_bibliotheque_modulaire/library/inventaire/cartes-20261017` | Classeur 23 onglets ; registres JSON ; 23 CSV ; bilan et manifeste SHA de chaque livrable |
| `/Users/karim/Project/Avelune Library Work/nb2-20261017/map-inventory-20261017/build_map_inventory.py` | Consolidation, décisions de périmètre, contrôles d’intégrité, protection du projet et génération XLSX/CSV/JSON |
| `/Users/karim/Project/Avelune Library Work/nb2-20261017/map-inventory-20261017/test_map_inventory.py` | Contrats positifs/négatifs : exclusions, IDs, URLs, sources absentes/altérées, protection des données |
| `/Users/karim/Project/Avelune Library Work/nb2-20261017/map-inventory-20261017/sprites2d-acquisition` | Cinq nouveaux PNG, références des sept précédents, sélection des 79 fiches, comparaison BW et provenance ; scripts et validation |
| `/Users/karim/Project/Avelune Library Work/nb2-20261017/map-inventory-20261017/rom-coverage` | Archives originales ciblées, registres, ZIP PNG, séquences PAT0, météo, lecteurs et tests ; inventaire exhaustif des fichiers dans `proof-files.json` |
| `/Users/karim/Project/Avelune Library Work/nb2-20261017/map-inventory-20261017/command-results.json` | Arguments exacts, répertoires, exits et logs des commandes |
| `/Users/karim/Project/Avelune Library Work/nb2-20261017/map-inventory-20261017/final-critical-review.json` | Revue indépendante, constat initial et levée des points de restitution |
| `/Users/karim/Project/Avelune Library Work/nb2-20261017/map-inventory-20261017/protected-inputs.json` | Empreintes des neuf fichiers projet/maps/pack à préserver |

Les manifests `fichiers-inventaire-cartes.json`, `sprites2d-acquisition/validation.json` et `rom-coverage/proof-files.json` donnent les listes exhaustives avec tailles et SHA. Aucun nouveau module natif, aperçu du catalogue produit, carte, scénario ou pack exporté.

## Validation et passes indépendantes

Les commandes exactes sont dans `command-results.json` ; Python utilisé : `/Users/karim/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3`.

| Passe | Commande / preuve | Résultat |
|---|---|---|
| Audit / architecture | `map_inventory_scope_review`, confrontation des inventaires et du dernier périmètre | Sources ≠ modules livrés ; pas 72 manques cartographiques ; réserves explicites |
| Acquisition / implémentation de l’inventaire | `collect_map_sources.py`, neuf contrôles du collecteur | Exit 0 ; 79 décisions uniques, 12 originaux vérifiés ; erreurs signature/troncature/CRC rejetées |
| Tests sources ROM | `python3 -B rom-coverage/test_rom_map_sources.py` | **20 tests, 0 échec, 0 erreur**, exit 0 |
| Tests consolidation | `python3 -B -m unittest -v test_map_inventory.py` depuis le dossier de travail | **15 tests, 0 échec, 0 erreur**, exit 0 |
| Build / validation alternative | `python3 -B build_map_inventory.py` | Exit 0 ; 717 SHA+CRC, neuf archives ROM recontrôlées, 23 onglets réouverts et comptes vérifiés |
| Critique finale | `final-critical-review.json` | Revue indépendante ; réserve météo ajoutée explicitement à la table structurée après son repérage |

Les suites Flutter/Dart, builds produit, transports MCP, Studio et appareils sont **N/A** : aucun contrat, code produit, donnée native d’authoring ou comportement de rendu n’a changé. Cette tranche ne vaut ni preuve GPU ni qualification de lecture dans Avelune iOS/Android. L’évaluation de parité MCP est N/A pour ce travail d’inventaire et d’acquisition hors projet ; la future fabrication devra passer par l’API canonique.

Contrôles finaux : `POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh` → exit 0, un rapport non suivi préexistant dans son emplacement canonique ; `git diff --check` → exit 0. Le budget reste le seul rapport déjà créé lors de l’audit autorisé précédent, mis à jour dans cette tranche. Le contrôle indépendant final donne `FAVORABLE_FOR_ENUMERATED_MAP_SOURCE_INVENTORY_WITH_SEVEN_EXPLICIT_RESERVES`, sans défaut P1/P2 ouvert. Les 28 fichiers manifestés et les neuf fichiers protégés ont été recontrôlés après la génération finale.

## État Git et préservation

Premier HEAD observé pour cette reprise : `b9570e2fc62b19e738bbf62593c6923167cb7312` sur `main`, 50 chemins déjà modifiés/non suivis, incluant le rapport issu de l’audit précédent. HEAD observé à la rédaction : `f727cacb9be5ffef276065eccec8cdcd1d637ca4`, progression concurrente préservée. Aucune commande Git d’écriture, aucun commit, push, rebase ou stash de cette tranche. Les états complets sont `git-initial.txt` et `git-final.txt` ; les travaux Border/Converter/Narrative étrangers ne sont pas nettoyés ni inclus dans une livraison Git.

Le pack conserve la version **0.5.0**, **131 ressources**, SHA **`4fcb135fa137c090cbb9144d1489941dbf945a87c1044d5eec79e778f4fd7b08`**. `project.json` et les sept maps sont inchangés. Aucun logiciel de test Studio/Player, émulateur ou serveur n’a été lancé. Tous les onglets temporaires de recherche et tous les processus de conversion de cette tranche sont fermés.

## Auto-critique et prochaine décision

L’inventaire est maintenant exploitable pour distinguer une acquisition manquante d’une absence de fabrication et d’une réserve de fidélité. Il ne faut toujours pas annoncer un nombre final de modules prêts, un pourcentage global ou une couverture de chaque état officiel des deux versions. Les noms inconnus gardent des IDs stables et les effets météo non composés restent explicitement signalés.

Aucune poursuite de fabrication de la bibliothèque n’a été engagée. Les prochaines décisions doivent partir des sept réserves nommées et des lots de familles, en conservant le même `.aveluneassets` lors de la reprise autorisée.
