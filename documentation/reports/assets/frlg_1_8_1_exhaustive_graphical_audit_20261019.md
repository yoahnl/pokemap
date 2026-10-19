# FRLG 1.8.1 — audit des graphismes de cartes et de leur préparation

Date : 19 octobre 2026. Lot : audit exhaustif FRLG 1.8.1, suite de POST-WLD-ASSET-PACK-001. Statut de l’audit : **TO REVIEW**. La correction du pack reste à faire ; le ticket global reste **DOING**.

## Verdict

Le pack contient les graphismes nécessaires aux contextes de tuiles FRLG non prototypes examinés, mais sa présentation comme une bibliothèque définitive, propre et entièrement prête à poser ou à dessiner n’est pas justifiée. La disponibilité des pixels, l’assemblage des objets et leur facilité d’utilisation sont trois critères différents.

Les doublons avec et sans sol signalés par Yoahn sont réels. Pour un décor indépendant, la version détourée doit être la référence. Un assemblage qui inclut le sol, un mur, un trou ou plusieurs objets doit être présenté comme une construction distincte, avec une fonction explicite. Une composition native ne doit pas être comptée comme un nouveau graphisme indépendant simplement parce que son cadrage diffère.

Cet audit conserve le package et la galerie 1.8.1 en l’état pour garder une référence vérifiable. Il identifie les corrections ; il ne les applique pas.

**Changement concurrent en fin de tâche :** une autre activité a corrigé trois URL d’images dans la galerie, aux entrées 649, 682 et 724. L’archive, le catalogue CSV et `apercus.json` sont inchangés. La galerie d’origine est conservée sous `A/initial-gallery.html`, avec son empreinte initiale ; la galerie actuelle correspond aux 930 chemins d’aperçus de l’index. Cette correction de liens ne nettoie aucun décor avec fond. Le garde-fou d’immutabilité détecte ce changement et échoue comme attendu ; il n’est pas désactivé ni présenté comme vert.

## Périmètre et audit initial

- Inclus : cartes, sols, chemins, bordures, végétation, bâtiments, mobilier, décors intérieurs/extérieurs, portes et effets graphiques liés aux cartes.
- Exclus : personnages, Pokémon, combats, interfaces, musique et logique de jeu. La présence d’une animation graphique ne certifie pas son déclenchement par un événement.
- Entrée publiée : `packages/frlg/1.8.1/FRLG-Cartes-Decors-1.8.1.aveluneassets` dans `/Users/karim/Project/Avelune Package`.
- Archive : 108 229 587 octets ; SHA-256 `ff22c7814405701bcf2eb9fed8e502d62f148c8cbc938ffd13f9cf5d49622f03`.
- Sources RPG Maker : `/Users/karim/Downloads/The-PMon-World-Project-main/The Pokémon World Project - Kanto`.
- Référence originale supplémentaire : [pret/pokefirered, commit 037335f4c725d7c9aecdac87066f2002b4bd7e14](https://github.com/pret/pokefirered/tree/037335f4c725d7c9aecdac87066f2002b4bd7e14). Ce commit correspond à la provenance enregistrée dans le pack. Les sources externes ont été décodées sans exécution de leur code C ni construction de ROM.
- Ancien espace `/Users/karim/Project/Avelune Packs` absent au début de l’audit. Aucun ancien reçu non disponible n’est présenté comme preuve fraîche.
- Risques initiaux : confusion entre tuiles et objets entiers ; faux doublons dus aux collisions ou aux états ; corpus RPG Maker incomplet pour le jeu officiel ; confusions de palettes et de banques ; compositions avec fond classées comme objets indépendants.

Le dossier de preuves est `/Users/karim/Project/Avelune Package/local-records/frlg-exhaustive-audit-20261019`, nommé **A** dans la suite. Les CSV donnent les identifiants exacts ; les numéros de modèles ci-dessous sont les numéros stables des 930 aperçus de cet audit.

## Comptes du pack : ne pas additionner des unités différentes

| Ressource | Quantité publiée | Interprétation |
| --- | ---: | --- |
| Modèles standards | 930 | 630 intérieurs, 217 extérieurs, 83 utilisables dans les deux contextes |
| Modèles de composants | 8 088 | Pièces de construction, distinctes des objets entiers |
| Total des modèles | 9 018 | Standards et composants |
| Presets standards de dessin | 261 | 106 terrains, 150 chemins, 5 surfaces forestières |
| Presets de composants | 64 | Ne pas les compter une seconde fois comme objets |
| Motifs SmartTile | 9 791 | Graphismes modulaires, pas 9 791 décors indépendants |
| Animations SmartTile | 944 | Définitions publiées ; distinctes des animations des modèles |
| Recettes d’environnement | 83 | Dispersions, pas 83 salles complètes |
| Bordures dédiées | 7 | D’autres structures sont fournies sous forme de chemins/constructions |
| Familles | 936 | Taxonomie à simplifier, pas 936 besoins graphiques du jeu |
| Entrées de catalogue principales | 9 862 | Métadonnées de plusieurs types de ressources |

Le précédent découpage en 35 familles n’est pas un dénominateur canonique du package actuel. Inventer des totaux « nécessaires » par famille à partir de ces 35 intitulés donnerait une précision trompeuse. `organization/families.csv` recense les 936 familles réelles et leurs membres ; `organization/presets.csv`, `environments.csv` et `borders.csv` détaillent toutes les ressources de dessin et de dispersion.

## Toutes les cartes sources RPG Maker

| Contrôle | Résultat |
| --- | ---: |
| Fichiers Map*.rxdata décodés | 383 / 383 |
| Échecs de décodage | 0 |
| Cartes avec au moins une tuile non nulle | 345 |
| Cartes vides ou servant de dossiers | 38 |
| Cellules examinées, trois couches | 1 456 380 |
| Cellules non nulles | 651 737 |
| Références distinctes par carte, événements inclus | 22 843 |
| Atlas effectivement utilisés | 33 : 17 statiques et 16 autotiles |
| Pages d’événement utilisant une tuile | 85 |
| Planches de décors référencées dans Characters | 31 |

Chaque carte est listée dans `source-maps/maps.csv`, ses références dans `tile-usage.csv` et `event-tiles.csv`. Le décodeur Marshal est inerte : il ne lance pas les scripts Ruby du projet.

### Anomalies exactes du corpus source

1. **Trois atlas déclarés absents du dossier original** : `FRLG_Outside`, `FRLG_Interior general`, `FRLG_Caves`, affectant 230 cartes. Des plans de support existent dans le package. General et Caves ont été relus depuis ces plans ; Outside a été rapproché de `FRLG_Outside_backup`, avec suppression de pixels principalement annotatifs. Cela ne reconstitue pas une preuve d’identité avec le fichier Outside original absent.
2. **Joyful Game Corner, carte 233, événement 2 « PC », page 2 (index 1), tuile 647** : rectangle `[224,1024,32,32]` hors de la planche Game Corner. Il faut choisir un PC valide dans la bibliothèque. Quatre quarts invalides correspondent ici à une seule mauvaise référence, pas à quatre assets manquants.
3. **`fog10` absent** : référencé dans les 14 salles de Lost Cave, cartes 347–360. `FRLG_Fog` est conservé exactement, mais son alias vers `fog10` ne démontre pas que les deux fichiers étaient identiques. Identité non vérifiée, manque graphique non démontré.
4. **`berrytreeAGUAVBERRY` absent**, carte 195, cinq pages : ajout Essentials non assimilable automatiquement à un besoin des jeux FRLG originaux.
5. **Six empreintes de quarts initialement absentes** sont toutes des annotations : carré blanc/croix rouge de Water Rock, et texte « PLAYER GOES UNDER ONLY » d’Outside. Ne pas les importer comme décors de jeu. Elles sont référencées notamment par Green Path 305 et Azuria 21 ; leur présence dans une couche ne prouve pas leur visibilité après composition.

Les pixels réellement graphiques des 33 atlas utilisés n’ont pas révélé d’absence supplémentaire démontrée. Cette preuve porte sur les pixels disponibles, pas sur l’intégrité sémantique de chaque objet.

Le projet RPG Maker ne suffit pas à définir tout le jeu officiel : il inclut Faraway Island hors FRLG, ne contient pas les intérieurs de Trainer Tower ni les salles Multiplayer utilisées comme référence de complétude, et n’identifie pas Birth Island/Navel Rock. Soustraire 383 cartes RPG Maker à 425 définitions natives ne donne pas un nombre de cartes manquantes : leurs découpages ne sont pas équivalents.

## Référence FRLG originale : tuiles, états et animations

L’audit natif couvre 425 définitions de cartes, dont quatre prototypes, 60 couples de banques de graphismes et 329 layouts utilisés, dont 20 alternatifs. Il prend en compte les changements de layout et les instructions de modification de tuiles compatibles avec la banque de chaque carte.

- **11 129 contextes graphiques non prototypes** correspondent aux pixels publiés : 10 416 statiques et 713 à leur phase animée stable déclarée.
- Les 24 contextes supplémentaires de prototypes sont séparés : 23 ont un équivalent graphique, un reste sans représentation identifiée. Ce dernier n’est pas un manque du jeu publié.
- **948 contextes animés, 8 171 intervalles échantillonnés**, sans différence de pixels ni d’ordre constatée aux points comparés.
- Les contextes de scripts issus d’une branche incompatible avec la banque de la carte sont tracés et écartés. Ils ne deviennent pas de faux assets manquants.
- Les 11 283 contextes natifs explicitement étiquetés dans le pack ont également été décodés indépendamment, sans différence de pixels. Ce contrôle du catalogue ne constitue pas un décompte de modèles entiers.
- Aucun conditionnel Rouge Feu/Vert Feuille affectant les layouts, banques de décors, métatiles ou palettes examinés n’a été trouvé ; les différences de prix/espèces du Casino et d’écran titre restent hors périmètre graphique des décors.

Ces contrôles reconstruisent les contextes de tuiles, pas chaque carte entière avec tous les acteurs, effets et interactions. Les comparaisons temporelles se font au milieu des phases : les arrondis entiers en millisecondes peuvent différer des transitions natives à 60 Hz. Ni l’égalité continue des timings, ni la première phase de chargement, ni le déclenchement dans le Player ne sont certifiés.

Sur 1 020 instructions de changement de métatile déployées dans leurs contextes de carte, 979 sont compatibles et 41 appartiennent à des branches de banques incompatibles, tracées et écartées. Aucun jeton de ces instructions ne reste non résolu.

### Portes et effets annexes : ce qui reste réellement non certifié

Les 32 liaisons de portes sources sont inventoriées. Sur 108 contextes directionnels contrôlés, 106 correspondent à leurs quatre images natives, soit **424 images vérifiées** ; deux correspondent à une entrée SSAnne explicitement inutilisée comme porte dans la source. Ces résultats ne certifient pas les commandes d’ouverture/fermeture dans Avelune.

L’inventaire annexe final comporte **56 sources graphiques**, réparties sans chevauchement :

| État de la source annexe | Nombre | Interprétation |
| --- | ---: | --- |
| Images natives retrouvées exactement | 25 | 66 images dans les sources ainsi qualifiées ; pilotage non certifié |
| Applicabilité, palette ou découpage non certifiés | 14 | Reste d’audit identifié, pas 14 assets manquants démontrés |
| Hors décor persistant | 4 | Effets dépendant d’acteurs ou hors périmètre retenu |
| Explicitement inutilisées dans la source | 5 | Ne pas importer comme besoins obligatoires |
| Météos non utilisées par les déclarations FRLG | 8 | Héritage présent dans les sources, sans besoin démontré par les cartes |

Les 14 sources à qualifier précisément sont : `ash`, `deep_sand_footprints`, `jump_long_grass`, `lavaridge_warp`, `long_grass`, `mountain_disguise`, `pop_out_of_ash`, `sand_disguise`, `sand_pile`, `short_grass`, `small_sparkle`, `tree_disguise`, `underwater_bubbles`, `water_surfacing`, sous `graphics/field_effects/pics/`. Leur présence dans la décompilation ne prouve pas leur utilisation dans FRLG ; certaines peuvent être des restes RSE ou des effets liés à des acteurs. Il faut établir leur pertinence puis résoudre palette/découpage avant de décider un import.

Sont notamment couverts graphiquement : passage dans les hautes herbes, particules d’herbe coupée, poussière de saut, éclaboussures, ondulation, empreintes de sable, traces de vélo, moniteurs de soin et du Panthéon, fragments du rocher de Deoxys, brume horizontale et les six images directionnelles du support Surf. Le fichier `native-effect-scope-coverage.csv` donne le verdict pour chaque source. Les déclarations météo des 425 cartes sont NONE 333, SUNNY 66, FOG_HORIZONTAL 19, SHADE 7 ; la texture de brume nécessaire est retrouvée exactement.

## Doublons : résultats sans double comptage

Les 930 modèles standards et leurs 1 267 images ont été comparés. Les RGB cachés derrière une transparence totale sont ignorés ; aucun rapprochement approximatif n’autorise une fusion. Les 930 images de l’index `apercus.json` correspondent exactement à la première image du modèle publié : les fonds appartiennent bien au contenu publié. La galerie HTML initiale avait toutefois trois liens d’image erronés, corrigés par une activité concurrente en fin d’audit.

| Catégorie exclusive | Groupes | Modèles concernés | Redondances visuelles | Décision |
| --- | ---: | ---: | ---: | --- |
| Même séquence et même comportement | 1 | 2 | 1 | Fusion possible après redirection des références |
| Même visuel, marge ou origine différente | 5 | 12 | 7 | Normaliser l’ancrage avant fusion |
| Même visuel, comportement différent | 17 | 37 | 20 | Garder les différences utiles ou les rendre explicites |
| Total | 23 | 51 | 28 | Ce ne sont pas 28 suppressions automatiques |

Le doublon strict est la plante/fleur **792 / 925** : `frlg-c08-f3a0210924c8a71accc70d` et `frlg-c15-f3c9948a6f13f9a380ef-whole`, mêmes 12 images et même comportement.

Autres corrections établies :

- **64 / 67 / 68 / 69** : même rocher visible ; les noms petit/moyen/sombre ne justifient pas quatre graphismes distincts.
- **79 / 80 / 133** : rayonnages de même apparence ; le couple gauche/droite n’est pas un miroir graphique. Marges et collisions restent à traiter avant fusion.
- **95 / 316** : même meuble apparent, nommé borne cycles ou casier selon l’entrée.
- **267 / 272** : même présentoir ; le nom « réfrigérateur » ne correspond pas à une différence graphique démontrée.
- **Neuf groupes de noms identiques, 21 entrées**, dont sept groupes de bâtiments regroupant 17 entrées : renommer les variantes par une différence visible et utile.

À préserver : quatre groupes ayant la même première image mais des animations différentes ; les 15 états de téléporteur de Léo ; les 11 palettes de météorite ; les huit plateformes de Trainer Tower. Les six traces de vélo gagneraient à être présentées comme un kit. Les lits verts 280/493 diffèrent de 3 140 pixels RGBA sur leur canevas : ils ne sont pas des doublons stricts. La simple proximité du contenu avec le bord d’un rectangle ne prouve pas un objet coupé ; les arbres 4/5/6 nécessitent une validation d’assemblage, pas une suppression sur supposition.

## Fonds : la règle à appliquer et les cas démontrés

L’écran de comparaison a parcouru les 930 modèles et isolé 18 paires où le premier plan opaque peut se retrouver dans une composition plus grande. Il est borné par des seuils de taille, de couleur et d’opacité : il ne détecte pas toutes les paires qui diffèrent légèrement de palette ou de façade. Les pixels semi-transparents ne sont pas couverts par ce test d’inclusion opaque.

| Modèle indépendant | Modèle avec enrobage | Résultat | Action |
| --- | --- | --- | --- |
| 867 — deux faisceaux | 922 — deux faisceaux sur sol | Six images et durées identiques pour le premier plan | Garder 867 comme décor ; 922 comme composition explicitement séparée |
| 868 — un faisceau | 923 — un faisceau sur sol | Six images et durées identiques pour le premier plan | Même règle |
| 869 — bornes ouvertes | 924 — passage sur sol | Même premier plan statique | Même règle |
| 8 — buisson vert A | 9 — buisson vert B | Même buisson, sol supplémentaire | Préférer le buisson transparent dans les décors |
| 11 — buisson clair A | 12 — buisson clair B | Même buisson, sol supplémentaire | Même règle |
| 706 — échelle Diglett | 892 — passage mural Diglett | Même échelle avec paroi supplémentaire | Séparer prop et ouverture murale |
| 710 — échelle brune | 711 — composition murale | Même premier plan à offset identique | Corriger le libellé d’orientation et présenter la paroi comme construction |
| 593 — Centre Pokémon | 594 — Centre Pokémon avec sol | 120 pixels ajoutés, uniquement dans la marge de sol | Préférer 593 comme bâtiment indépendant |
| 596 — arène standard | 597 — arène avec sol | 2 800 pixels ajoutés, uniquement dans la marge de sol | Préférer 596 comme bâtiment indépendant |

Les 11 autres paires de l’écran initial comprennent quatre assemblages de rochers empilés utiles, quatre inclusions entre états de barrière, une machine de soin animée distincte et deux compositions à qualifier. Elles ne doivent pas être supprimées comme doublons. Les deux paires de bâtiments ont été trouvées par la revue indépendante complémentaire : elles échappent aux seuils de l’écran initial. Les neuf paires du tableau sont donc des constats précis, pas l’affirmation que toute redondance avec fond possible se limite à neuf.

Règle proposée pour la prochaine version :

1. **Décor indépendant** : fond transparent, ombre propre conservée si elle appartient à l’objet, pas de rectangle de sol ni de chemin collé au bâtiment.
2. **Structure** : paroi, trou, escalier intégré ou entrée, avec support natif nécessaire clairement nommé et classé.
3. **Construction/kit** : composition complète volontaire avec sol et pièces associées, distincte du décor transparent et sans gonfler le compte des graphismes uniques.
4. **Terrain/chemin/bordure** : support graphique à dessiner ; ne pas fabriquer un détourrage en supprimant une couleur globale pouvant aussi appartenir à l’objet.

Cette règle doit s’appliquer aux centres Pokémon, arènes, maisons et arbres, y compris lorsque les deux versions diffèrent de quelques pixels et échappent au test exact. Deux séries de bâtiments examinées contiennent 14 assemblages anciens (472–485) et 51 modèles natifs (593–643), soit 65 entrées à rapprocher ; ce ne sont pas 65 silhouettes uniques démontrées. La dernière passe critique fournit les identifiants supplémentaires à vérifier dans `critique/critique.json`.

### Autres corrections de composition identifiées visuellement

| Modèles | Problème à traiter | Décision attendue |
| --- | --- | --- |
| 13, 89 | Végétation avec support natif | Distinguer végétation réutilisable et bande/composition avec terrain |
| 165–168, 895–897 | Rochers d’arène avec sol ou paroi | Détourer les objets ou classer les assemblages ; garder les silhouettes différentes |
| 204–206, 234, 356 | Mobilier/équipement avec entourage rectangulaire | Vérifier la limite entre objet et support avant détourage |
| 295 / 301 | 301 nommé « Coussin bleu bas » contient la même chaise que 295 plus 80 pixels | Renommer la composition chaise + objet ; ne pas la présenter comme coussin autonome |
| 587 | Effet de mouvement d’herbe avec tuile complète | Classer comme effet de terrain/overlay |
| 889–892, 894 | Entrées de grotte, échelle intégrée, linteau | Constructions de paroi utiles ; ne pas effacer leurs murs aveuglément |
| 893, 900–902, 904–908, 910, 912–917, 930 | Socle, accès de piscine, plateformes, flèches, médaillons, sols | Présenter dans terrains/constructions plutôt que dans une palette indifférenciée de props |
| 909, 918–921 | Panneau mural, porte/escalier du Champion, paroi technique | Kits structurels composés, séparés des objets individuels transparents |
| 926–929 | Haies de serre avec ombre native au sol | Vérifier la compatibilité du support et de l’alpha ; ne pas confondre une ombre utile avec un fond erroné |

Cette liste est issue de la revue des douze planches d’aperçus. Elle identifie des décisions de contenu précises ; une vignette seule ne certifie pas les limites exactes de toutes les silhouettes ou de toutes leurs images animées. Le contrôle complémentaire de containment sur un canevas identique donne 22 candidats supplémentaires ou recoupés, listés dans `critique.json` ; ils ne s’ajoutent pas aux neuf paires confirmées comme un nombre de doublons à supprimer.

## Portes : faut-il les dessiner dans la maison ?

**Pour une bibliothèque modulaire Avelune, la cible recommandée est une façade fixe avec son encadrement et une porte animée séparée.** La porte doit avoir une échelle, un offset, une profondeur et un rectangle de remplacement définis pour ce bâtiment. L’état fermé doit être disponible comme état par défaut ; l’état ouvert doit laisser apparaître l’ouverture correcte.

Une porte fermée intégrée à l’image du bâtiment reste possible uniquement si l’animation remplace ou masque entièrement le rectangle correspondant. Dans le jeu original, [`src/field_door.c`, lignes 290–310 et 323–359](https://github.com/pret/pokefirered/blob/037335f4c725d7c9aecdac87066f2002b4bd7e14/src/field_door.c#L290) remplace les tuiles puis restaure la version fermée. Une superposition transparente ne garantit pas ce comportement : elle peut laisser la porte fermée visible derrière la porte ouverte.

Les 51 modèles de la famille exacte « Bâtiments FRLG » ont `groupId` nul et le contrat de modèle ne fournit pas de liaison explicite bâtiment ↔ porte ↔ offset ↔ mode de remplacement. Cela ne signifie pas que des événements ne peuvent pas animer des portes ; cela signifie que le catalogue seul ne certifie pas un bâtiment avec porte déjà fonctionnelle.

La planche RPG Maker Doors8 ne manque pas de 16 pixels en haut : ses cellules 32×48 sont placées en bas de cellules publiées 32×64 avec marge transparente. Les 13 états explicites examinés conservent tous leurs pixels graphiques après alignement ; les 768 pixels supprimés sont des marqueurs/en-têtes. La couverture des images et le bon pilotage d’une timeline sont deux validations séparées.

## Chemins, terrains, bordures et environnements

| Famille fonctionnelle | État réel | Reste à corriger ou vérifier |
| --- | --- | --- |
| Terrains standards | 106 : 93 à règles, 5 à constructions natives, 8 à sélection manuelle | Rendre le mode de pose lisible et tester les raccords du jeu de règles |
| Chemins standards | 150 : 45 à règles, 80 à constructions natives, 25 à sélection manuelle | Distinguer pinceau raccordable et tampon/construction ; revoir les palettes ouvertes |
| Surfaces forestières | 5 constructions natives | Valider le raccord des cimes, bords et troncs dans une carte témoin |
| Bordures dédiées | 7 | Nommer les autres structures proposées par les chemins et constructions ; ne pas annoncer toutes les clôtures et falaises comme bordures automatiques |
| Environnements | 83 recettes, dont 65 à un seul modèle ; 59 intérieures et 24 extérieures | Regrouper les recettes utiles et séparer mobilier, décor et composition ; un meuble dispersé n’est pas une pièce prête à poser |
| Classement | 936 familles, dont 328 racines ; 421 directement utilisées par les ressources standards | Unifier huit chemins de familles en double ; réduire les racines ; préciser les variantes |

Les 123 presets sans règles ne sont pas 123 presets cassés : 90 ont des constructions natives et 33 sont des collections de motifs manuels. Aucun n’est dépourvu à la fois de règles et de motifs propres. Le code Studio permet les constructions natives ; 38 presets réunissent les conditions de sélection automatique initiale. Ces constats viennent du code et des définitions, pas d’un essai de tous les pinceaux dans l’interface.

Les 33 collections manuelles ne disposent pas de la restriction de palette associée à une construction native dans leur catégorie ; elles peuvent exposer de nombreux motifs compatibles sans rapport immédiat avec leur nom. Il faut cibler la sélection ou clairement guider l’utilisateur.

Les sept bordures dédiées sont : rive rocheuse brune transparente ; rive rocheuse brune sur eau ; rebord de saut sud ; liseré de tapis bleu bord doré ; liseré de tapis violet ; liseré de tapis vert ; mur nord crème à bande bleue. Les autres berges, clôtures, murs et falaises demandent une revue de leur mode de dessin.

Sur 9 862 lignes CSV rapprochées des métadonnées natives, **745 diffèrent seulement par le chemin de famille**. Contextes, rôles et descriptions correspondent. La publication ajoute notamment des racines de classement ; le CSV/la galerie ne reflètent donc pas toujours exactement la hiérarchie visible dans le pack. Cela ne représente pas 745 graphismes erronés.

## Corrections nécessaires avant de qualifier une nouvelle version de définitive

| Priorité | Travail concret | Critère de sortie |
| --- | --- | --- |
| 1 | Séparer décors transparents et constructions avec sol/paroi | Les trois barrières et les autres paires établies ne sont plus deux décors équivalents ; tous les kits sont clairement identifiés |
| 1 | Revoir les bâtiments et leurs portes | Chaque bâtiment a un état fermé propre et une porte compatible avec ancrage et remplacement démontrés |
| 1 | Fusionner le doublon strict et normaliser les alias d’ancrage | Références redirigées, aucun déplacement ni comportement perdu |
| 2 | Corriger les noms ambigus et les hiérarchies | Variantes expliquées, huit chemins de familles doubles résolus, CSV et Studio cohérents |
| 2 | Qualifier les collections de chemins/terrains | Pinceaux à règles, tampons et constructions sont distincts ; cartes témoins des raccords |
| 2 | Terminer la qualification des effets graphiques annexes | Chaque effet pertinent est présent ou explicitement ajouté, avec sa palette et ses images |
| 2 | Corriger les références source invalides et lever l’incertitude fog10 | PC valide ; alias de brume justifié ou remplacé par une référence assumée |
| 3 | Vérifier dans Studio puis Player | Import propre, placement sur sols contrastés, animations, fermeture/réouverture et export/réimport sans perte |

La prochaine étape n’est donc pas d’importer aveuglément un nombre supplémentaire de milliers de tuiles. C’est de produire une version éditorialement cohérente des objets et des modes de construction, puis de vérifier les effets et le parcours réel.

## Fichiers, zones, vérification et traçabilité

### Fichiers produits

Aucun fichier moteur, application, carte source, archive FRLG ou aperçu publié n’est modifié par cet audit. Le seul fichier ajouté au dépôt moteur par cette tâche est le présent rapport. Les scripts, tables et preuves externes sont conservés sous A, sans modification Git :

| Zone | Fichiers/entrées principaux | Rôle |
| --- | --- | --- |
| Racine | `initial-state.json`, `audit_organization.py`, `audit_backgrounds.py`, `classify_background_candidates.py` | Entrées immuables, classement/modes de pose, inclusion opaque et décisions sémantiques |
| `duplicates/` | `decode_archive.py`, `audit_visuals.py`, `classify_duplicates.py`, `audit_near_matches.py`, `manual_review.py`, `test_audit.py`, tables décodées et 12 planches | Modèles, images et comparaisons ; pas de réécriture du package |
| `source-maps/` | Décodeur Dart, recensement Python, comparateurs, `findings.json`, CSV et empreintes | Toutes les cartes RPG Maker et références utilisées |
| `native-reference/` | Référence épinglée, décodeur natif, comparateurs de timelines, portes, effets et inventaires | Confrontation aux graphismes des jeux originaux |
| `organization/` | `organization.json`, `families.csv`, `presets.csv`, `environments.csv`, `borders.csv`, `csv-native-consistency.json` | Comptes réels et classement |
| `backgrounds/` | `background-twins.json/.csv`, `semantic-decisions.json/.csv`, planche comparative | Paires avec fond et décisions ; seuils explicités |
| `tests/` | `test_independent_audit.py`, journaux, `receipt.json` | Tests positifs/négatifs indépendants et invariants |
| `critique/` | `critique.json` | Relecture contradictoire finale |

L’inventaire final des fichiers produits et leurs tailles figure dans `completion-receipt.json` ; les références externes téléchargées sont comptées séparément des scripts et preuves. Le rapport ne contient pas de copies intégrales de code.

### Commandes et résultats

Les commandes exactes, durées et logs des agents restent dans leurs reçus. La vérification consolidée est effectuée depuis A :

```text
python3 tests/test_independent_audit.py
python3 duplicates/test_audit.py
python3 classify_background_candidates.py
```

Avant le changement concurrent de galerie, la relance racine rapporte exactement `Ran 35 tests in 0.873s — OK` et `Ran 8 tests in 0.110s — OK`, codes de sortie 0.

Après détection du changement, la dernière relance rapporte **`Ran 35 tests in 1.170s — FAILED (failures=1)`** : 34 réussissent, seul `test_published_inputs_unchanged` échoue parce que la galerie a changé. Les huit tests de doublons passent : **`Ran 8 tests in 0.137s — OK`**. Le total final est donc **42 réussites et un échec du garde-fou d’immutabilité**, expliqué et conservé. Le finaliseur ne tolère cette dérive documentée que si seul le HTML a changé, uniquement ses liens d’images, que l’original retrouve exactement son empreinte et que les 930 liens actuels correspondent à l’index épinglé ; toute autre dérive reste bloquante.

Les 21 scripts Python du dossier d’audit sont vérifiés par `ast.parse`, sans erreur. Trois entrées publiées sur quatre restent identiques, dont l’archive ; les 636 fichiers sources RPG Maker lus sont inchangés. Un avertissement de dépréciation Pillow `Image.getdata` est émis par le décodeur d’audit, sans modification de dépendance de l’application.

Build de l’application : non applicable à cette tâche, aucun source applicatif n’étant modifié. Validation alternative : syntaxe des évaluateurs, tests ciblés, décodage et comparaison indépendants. Aucun nouveau parcours Studio/Player n’est revendiqué. Parité MCP : non applicable à une lecture d’archive et à un audit externe ; aucune nouvelle sémantique d’authoring n’est ajoutée, et aucun projet actif n’est modifié par écriture JSON.

### Verdicts des cinq passes

| Passe | Travail et verdict |
| --- | --- |
| Audit / Architecture — `audit_source_maps` | 383 cartes décodées ; recensement source exhaustif ; corpus seul insuffisant pour certifier FRLG officiel ; références erronées et incertitudes nommées |
| Implémentation de l’évaluation — `audit_duplicates` | 930 modèles/1 267 images ; doublons exacts et variantes séparés ; aucune fusion réalisée ; pas de certification des silhouettes ambiguës |
| Tests — `audit_tests` | 35 tests indépendants et huit tests existants réussis ; garde-fous contre faux doublons et fausses absences ; limites temporelles reproduites |
| Build / Validation — `audit_native_reference` | Décodage graphique indépendant ; 11 129 contextes non prototypes couverts ; build applicatif non applicable ; 14 sources annexes encore à qualifier |
| Critique finale — `audit_final_critique` | Preuves acceptées avec limites ; neuf paires avec fond confirmées, dont deux bâtiments manqués par l’écran borné ; package non prêt à être qualifié de définitif |

### Git, hygiène et SSD

- État initial du dépôt moteur : HEAD `621af01f1ed109a39da0e01e799887577495fbac`, 319 lignes de statut modifiées/non suivies préexistantes. Dépôt packages initialement propre, HEAD `3dd3d530f37e727e17ae9997fd5235a6851a7d47`.
- À la vérification finale : moteur HEAD `771fdf5024424501170ca9144976f302f51955d6`, 320 lignes de statut ; packages même HEAD, 8 697 lignes de statut. Des changements et un commit concurrents sont intervenus pendant cet audit. Ils ne sont ni inclus, ni restaurés, ni nettoyés par cette tâche. Les états complets et deltas figurent dans `completion-receipt.json`.
- **Aucune opération Git d’écriture par cet audit.** Son unique ajout au dépôt moteur est ce rapport ; tous ses évaluateurs et preuves se trouvent sous A. L’archive et les deux index FRLG restent inchangés ; la seule dérive des quatre entrées épinglées concerne les trois URL corrigées dans la galerie.
- `bash tools/scripts/check_markdown_hygiene.sh` : code 1, résultat exact `Markdown hygiene: 3 new Markdown files exceed the default limit of 0.` L’un est ce rapport d’audit explicitement demandé ; les deux autres, préexistants, sont `avelune_catalog_limits_diagnostic_20261018.md` et `johto_capability_audit_lots_20261018.md`. Aucun contournement du budget et aucune suppression de ces documents étrangers.
- SSD : environ **50,8 Gio disponibles** à la dernière mesure ; preuves d’audit environ **148 Mio**, référence externe comprise. Les sources et preuves utiles sont conservées ; 152 767 octets de caches Python propres à cet audit ont été supprimés. Les activités concurrentes peuvent faire varier l’espace disponible.
- Traçabilité : [ticket post-bêta existant POST-WLD-ASSET-PACK-001](https://app.notion.com/p/3fb197a7bfa581379199ceec8afe5486), audit proposé à la revue, correction du pack encore ouverte. Aucun nouveau ticket ni changement du périmètre bêta.

## Auto-critique et limites conservées

La vérification est exhaustive pour le recensement des fichiers sources et les contextes de tuiles définis par les évaluateurs. Elle n’est pas une certification exhaustive de tous les objets prêts à poser, de tous les déclenchements d’effets, ni du rendu de chaque carte recomposée dans Avelune.

- Des pixels identiques ne garantissent pas les bons assemblages, couches, ancrages, collisions ou commandes.
- L’écran avec/sans fond est borné ; les différences légères de bâtiment exigent une décision sémantique.
- Les instructions C et scripts sont analysés statiquement ; leur exécution exacte n’est pas simulée.
- Une première image correcte ne prouve pas le bon état ouvert d’une porte, sa fermeture ou son passage dans le Player.
- La référence anglaise épinglée ne certifie pas d’éventuelles traductions graphiques de panneaux dans chaque édition localisée.
- Aucun pourcentage global de « FRLG définitivement prêt » n’est calculé en additionnant des tuiles, objets, recettes et effets hétérogènes.

Le résultat justifie des corrections ciblées de contenu et de classement. Il ne justifie ni de jeter les variantes utiles, ni de déclarer le pack définitif sur la seule base de la couverture des tuiles.
