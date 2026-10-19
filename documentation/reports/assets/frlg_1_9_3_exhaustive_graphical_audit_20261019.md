# FRLG 1.9.3 — audit exhaustif des graphismes de cartes

19 octobre 2026 · POST-WLD-ASSET-PACK-001 · Audit proposé **TO REVIEW** ; corrections du pack à faire.

## Verdict concret

**Aucun graphisme supplémentaire de cellule de carte officielle n’est démontré manquant. Les 421 définitions hors prototypes, leurs 11 129 contextes graphiques distincts et leurs 239 426 positions de cellules examinées ont une représentation dans le pack.** Les 21 illustrations natives d’entrée de lieu sont également présentes et exactes.

**La préparation du pack reste à corriger sur des points précis : une porte abîmée, un fauteuil propre mal nommé à préférer à sa composition avec mur/parquet, une paroi d’ascenseur mal assemblée dont l’animation reste à préparer, six alias de portes redondants, huit chemins de familles doubles et deux descriptions contradictoires.** Les modes de dessin doivent aussi rester explicites : 138 outils standards à règles, 90 choix de constructions natives et 33 collections de motifs manuels.

Ces nombres sont de différentes unités. Trois états de porte abîmés ne deviennent pas sept assets manquants parce qu’ils sont référencés sept fois. La présence des pixels dans des motifs composants ne certifie pas un objet entier correctement préparé.

## Ce qui reste réellement à corriger

| Priorité | Élément | Quantité exacte | Correction nécessaire |
| --- | --- | ---: | --- |
| P0 | Porte du laboratoire de Chen, Bourg Palette | **1 style ; 3 définitions ; 3 états graphiques uniques** | Restaurer le panneau vert rendu transparent dans l’état fermé, l’ouverture et la fermeture ; conserver le véritable état ouvert. |
| P1 | Fauteuil du capitaine | **1 paire de modèles à rationaliser** | Le fauteuil propre existe déjà sous « Commode cabine » : le renommer et le classer dans les assises. Reléguer la composition avec mur/parquet aux composants ; vérifier les différences d’ancrage et de collision avant tout remappage. |
| P1 | « Distributeurs généraux terrasse » | **1 paroi ; 3 états cohérents ; 2 sens d’animation à préparer** | Le modèle juxtapose trois phases de reflet au même instant. Recomposer chaque état entier, animer montée/descente et corriger le nom, le contexte intérieur et la famille. Les neuf pièces graphiques de fenêtre existent déjà. |
| P2 | États de portes ouverts équivalents | **6 alias redondants dans 2 groupes** | Conserver deux dessins distincts et remapper les références des huit définitions concernées ; conserver noms, provenance et animations utiles. |
| P2 | Taxonomie | **8 chemins de familles dupliqués** | Regrouper les identifiants de famille équivalents et remapper leurs membres. |
| P2 | Descriptions de bâtiments | **2 descriptions** | Corriger les textes du Centre Pokémon standard rouge et de l’arène standard : ils affirment à la fois conserver le sol et fournir une version indépendante transparente. |

Il n’y a **aucun doublon exact démontré entre les 793 modèles standards**, après comparaison des séquences, durées, dimensions et comportements. Les six alias ci-dessus sont des composants d’états ouverts ; ce ne sont pas six styles de portes à supprimer.

### Porte de Chen : défaut démontré, pas hypothèse de vignette

Le vert supprimé constitue le panneau de la porte autour de la fenêtre et de la poignée. Ce n’est pas le sol. La carte native concernée est `PalletTown`, métatile `METATILE_PalletTown_OaksLabDoor`, identifiant 684.

| Définition concernée | Identifiant |
| --- | --- |
| Ouverture, standard | `rp_012ad95b32c9bd0b6894f9282dd20f931561b35e36c8357a` |
| Fermeture, composant | `rp_3302d7658572840dc413b4ad4b70fbc0424e91698a321cfa` |
| État fermé, composant | `rp_747fcb2fc1d5ba253f249196e307f98b5d4de5fcef2ad9f3` |

Trois états atlas ont perdu respectivement **328, 272 et 156 pixels opaques**, soit **756 pixels uniques**. Ils produisent sept références de frames abîmées : trois à l’ouverture, trois à la fermeture et l’état fermé. Les pixels conservés sont exacts. L’état ouvert est intact. Le dessin fermé complet subsiste aussi comme motif composant ; aucune des 151 séquences de quatre frames recherchées dans le pack ne fournit l’animation native complète intacte.

La cause est localisée dans la préparation : les deux couleurs `(32,172,98)` et `(82,205,148)` ont été traitées comme de l’herbe sur les quatre frames de cette porte. La correction doit restaurer leurs masques spatiaux à partir des sources, et non changer la palette ou recolorer tout l’atlas.

La façade associée est `rp_1acf1549bd831b1db753132b4b9ab5e86d7ba6bf4bca574d`. Son aperçu assemblé doit être régénéré après correction. La cadence de 333 ms correspond à l’arrondi des vingt ticks natifs à 60 Hz nominal : la fonction source consomme cinq appels par image malgré le champ `duration=4`. Le défaut identifié est graphique.

[Comparatif des quatre états natifs puis des quatre états du pack](</Users/karim/Project/Avelune Package/local-records/frlg-1.9.3-exhaustive-audit/native/chen-native-versus-transparent.png>) · [preuve chiffrée et sources](</Users/karim/Project/Avelune Package/local-records/frlg-1.9.3-exhaustive-audit/native/chen-door-difference.json>).

### Fauteuil et ascenseur : identifications recoupées avec les cartes

- `frlg-boat-meuble-cabine-gris`, modèle `rp_832ecb4c3237a8e3a77183c239ca6b8571f5b8bd25044a5d` : le rectangle RPG Maker `FRLG_Boat`, `[224,448,32,64]`, contient le fauteuil gris du bureau du capitaine et son entourage. La carte native `SSAnne_CaptainsOffice` le situe aux métatiles 772/780, position `[2,1]`. Les vrais escaliers sont ailleurs dans la pièce. Le fauteuil détouré existe déjà sous `frlg-boat-commode-cabine`, modèle `rp_b81cf4a8586da50fcb998c67944efae3dc591386590f1cae` : ses **1 224 pixels opaques correspondent tous exactement**, avec un décalage vertical de seize pixels, au fauteuil de la composition. Il faut renommer le propre, corriger sa famille et distinguer la composition source. Une fusion aveugle casserait les ancrages ou collisions : une cellule pour le propre, deux pour la composition.
- `frlg-interior-general-distributeurs-generaux-terrasse`, modèle `rp_2eee3d603431821d01d8e239e4c53b705361847232b4aa4d` : le rectangle RPG Maker `[0,7872,160,96]` est une paroi d’ascenseur, avec panneau de commande, maincourante et fenêtre à reflets. La banque native `gTileset_SilphCo` et les constantes `ElevatorWindow_Top/Mid/Bottom` établissent cette fonction. Quatre layouts l’utilisent : ascenseurs du Grand Magasin, du Repaire Rocket, de la Sylphe et de la Tour des Dresseurs. Le montage courant juxtapose les phases 0, 1 et 2 dans trois colonnes ; le jeu natif applique une même phase aux trois colonnes à chaque instant. Il faut assembler **trois états de paroi cohérents**, puis les animer en montée **0 → 1 → 2** et en descente **0 → 2 → 1**, à **100 ms par état**, cycle de **300 ms** à 60 Hz nominal. La première mutation native intervient après sept appels, les suivantes après six ; la phase initiale reste distincte du cycle régulier. Les neuf pièces de fenêtre sont présentes. La recherche ne trouve aucune séquence correspondante parmi les **944 animations SmartTile** ni les **324 définitions de modèle animées, 2 137 frames**. Sources : `src/field_specials.c:776–811,1127–1164`, `include/constants/metatile_labels.h:215–223`. Le nom, la famille et le contexte extérieur doivent aussi être corrigés.

La comparaison structurelle avec ces deux motifs conserve les formes et les relations de couleurs, mais les palettes RPG Maker et natives diffèrent : elle n’est pas présentée comme une égalité RGBA entre ces deux corpus.

Le socle et les cordons de la navette du musée ont aussi été réexaminés : ils appartiennent à l’exposition source. Ils ne doivent pas être supprimés comme un fond parasite.

[Identifications et références exactes](</Users/karim/Project/Avelune Package/local-records/frlg-1.9.3-exhaustive-audit/native/annexes/reponse-identification.json>) · [fauteuil propre et différences de comportement](</Users/karim/Project/Avelune Package/local-records/frlg-1.9.3-exhaustive-audit/critique/chair-identity.json>) · [recherche d’animation d’ascenseur](</Users/karim/Project/Avelune Package/local-records/frlg-1.9.3-exhaustive-audit/critique/elevator-element-animation-scan.json>).

## Couverture des jeux originaux : dénominateurs vérifiables

| Ensemble réellement comparé | Résultat | Reste graphique démontré |
| --- | ---: | --- |
| Définitions de cartes hors prototypes | **421 / 421** | Aucune définition sans représentation de ses cellules dans le pack. |
| Contextes distincts de tuiles, banques et états de scripts | **11 129 / 11 129** | Aucun contexte requis sans pixels correspondants. |
| Positions de cellules, variantes et bordures incluses | **239 426 / 239 426** | Aucun trou graphique dans cette comparaison. |
| Contextes applicables de portes natives | **52 / 53 exacts** | Le contexte Chen est présent mais mal détouré. |
| Directions ouverture/fermeture de ces portes | **104 / 106 exactes** | Les deux différences sont l’ouverture et la fermeture de Chen. |
| Illustrations natives d’entrée de lieu | **21 / 21** | Aucune manquante ; images 480 × 320 exactement reconstruites. |
| Sorties graphiques des modifications Cut qualifiées | **26 / 26** | Aucun manque parmi ces sorties sur 44 cartes. |
| Anciennes annexes à l’applicabilité incertaine | **14 / 14 résolues** | Aucune n’établit un graphisme requis manquant. |

La source contient **425 définitions**, dont **quatre prototypes explicitement séparés**. Les vingt variantes de layouts, les bordures et les plans initiaux produisent **890 matrices de comparaison**. Une cellule sans représentation est trouvée dans `Prototype_SeviiIsle_9` ; elle n’est pas comptée comme un manque du jeu publié.

Les huit sous-tuiles de chaque métatile, les palettes, les retournements et les deux plans graphiques sont décodés à partir des sources. Les comparaisons de composition conservent les positions et des empreintes RGBA, sans générer des centaines d’images géantes. Il s’agit d’une comparaison source → ressources du pack, **pas du rendu en direct des 421 cartes dans Studio**.

Les timelines examinées couvrent **948 contextes animés et 8 171 intervalles**, avec correspondance des images aux points comparés. Les arrondis de temps en millisecondes, les transitions exactes et la phase au premier chargement ne sont pas une certification temporelle continue.

Les quatorze anciennes incertitudes sont maintenant classées par déclenchement réel : six prédicats désactivés dans FRLG, cinq effets sans déclencheur dans les cartes, deux sans appel de démarrage et un explicitement inutilisé. Les fichiers concernés sont `ash`, `deep_sand_footprints`, `jump_long_grass`, `lavaridge_warp`, `long_grass`, `mountain_disguise`, `pop_out_of_ash`, `sand_disguise`, `sand_pile`, `short_grass`, `small_sparkle`, `tree_disguise`, `underwater_bubbles` et `water_surfacing`. Leur simple présence dans la décompilation n’impose pas quatorze imports supplémentaires.

[Toutes les définitions natives, une ligne par carte](</Users/karim/Project/Avelune Package/local-records/frlg-1.9.3-exhaustive-audit/native/per-map-coverage.csv>) · [890 matrices et empreintes](</Users/karim/Project/Avelune Package/local-records/frlg-1.9.3-exhaustive-audit/native/all-map-composition.csv>) · [illustrations](</Users/karim/Project/Avelune Package/local-records/frlg-1.9.3-exhaustive-audit/native/location-previews.csv>) · [annexes résolues](</Users/karim/Project/Avelune Package/local-records/frlg-1.9.3-exhaustive-audit/native/fourteen-annexes-resolved.csv>).

### Effets : images, séquences et mouvements procéduraux

Les **25 sources d’images d’effets applicables** couvertes par la passe native ont aussi été rattachées aux tables d’animation C actives, puis recherchées parmi les **9 106 définitions de modèle** et **944 animations SmartTile**. Les **42 séquences ou états distincts** se répartissent ainsi :

| Contrôle borné | Nombre | Résultat |
| --- | ---: | --- |
| Séquences avec images, ordre et cadence nominale correspondants | **10** | Présentes. |
| Séquences avec maintien terminal explicite et nettoyage transparent | **8** | Images, ordre et cadence avec fin de vie correspondants ; le tick terminal est justifié par le cycle natif. Ce ne sont pas huit défauts à corriger. |
| États statiques directionnels ou fragments intentionnels | **24** | Présents ; ces états ne constituent pas une animation unique à concaténer. |
| Séquence flipbook manquante dans cette passe | **0** | Aucun assemblage d’images absent démontré sur ces 42 cas. |

Les huit séquences à maintien terminal sont les ondes sur l’eau, la poussière d’atterrissage, le saut dans les hautes herbes, la grande éclaboussure, le pas dans une flaque, la petite éclaboussure, l’écran de soin et l’écran du Panthéon. Le consommateur `src/sprite.c:915–989` décrémente la durée à l’entrée : `FRAME(N)` représente N ticks nominaux, contrairement au moteur de portes. Les cinq callbacks concernés nettoient sur `animEnded` ; le callback précède `AnimateSprite`, donc END est observé au callback suivant et justifie le tick de maintien final. Les arrondis de durée sont inférieurs ou égaux à une milliseconde. La correspondance est établie dans les données ; déclenchement, arrêt et répétition en situation restent à qualifier dans le Player.

Surf comporte **quatre animations directionnelles distinctes de deux frames**, à 48 ticks par frame, toutes présentes. Il ne faut pas assembler les six dessins sources en une seule animation.

Quatre effets réclament par nature un comportement au-delà du fichier graphique : les huit feuilles de Coupe se déplacent en spirale, la brume défile, les quatre fragments du rocher de Deoxys se déplacent, et les Poké Balls de la machine de soin clignotent par changement de palette. Leurs images existent ; **leur chorégraphie complète n’est pas démontrée par la présence de ces assets**. Cette réserve n’ajoute pas quatre imports graphiques manquants.

[42 séquences et correspondances exactes](</Users/karim/Project/Avelune Package/local-records/frlg-1.9.3-exhaustive-audit/effect-sequences/sequence-coverage.csv>) · [effets procéduraux et références C](</Users/karim/Project/Avelune Package/local-records/frlg-1.9.3-exhaustive-audit/effect-sequences/procedural-effects.json>).

## Contenu actuel, famille fonctionnelle par famille fonctionnelle

| Famille | Présent dans le pack | Préparation ou qualification réelle |
| --- | ---: | --- |
| Modèles graphiques standards | **793** | Effets compris ; une porte, une paire de fauteuils et une paroi d’ascenseur demandent les corrections ci-dessus. Les 21 illustrations natives sont toutes des composants, en dehors de ces 793 standards. |
| Composants de modèles | **8 313** | Pièces et états de construction ; six alias de portes redondants identifiés. |
| Terrains standards | **106** | **93 à règles**, **5 choix de construction**, **8 collections manuelles**. |
| Chemins standards, dont les hautes herbes | **150** | **45 à règles**, **80 choix de construction**, **25 collections manuelles**. Ce ne sont pas 150 revêtements automatiques équivalents. |
| Surfaces de forêt | **5** | Cinq choix de constructions natives pour cimes/bords/assemblages. |
| Pinceaux composants | **64** | Supports techniques, distincts des 261 outils standards. |
| Motifs SmartTile | **9 791** | Motifs présents et catalogue canonique valide ; ne pas les additionner aux décors comme des objets indépendants. |
| Animations SmartTile | **944** | Définitions présentes ; elles sont distinctes des animations des modèles de portes. |
| Bordures dédiées | **7** | Deux rives rocheuses, un rebord de saut sud, trois liserés de tapis et un mur nord crème/bleu. Les autres structures utilisent aussi des chemins et constructions. |
| Environnements | **74 standards + 9 composants = 83** | Recettes et compositions, pas 83 pièces entièrement construites. 65 recettes ont une palette d’un seul modèle. |
| Groupes de portes illustrés | **43** | Références présentes ; Chen exige une restauration de masque. Les événements ne sont pas créés automatiquement. |
| Façades standards avec aperçu fermé associé | **44** | Contrat de superposition explicite ; ce chiffre n’est pas une nouvelle certification RGBA de chaque bâtiment contre le jeu original. |
| Atlas supports | **492** | Les médias liés comprennent 514 fichiers, dont l’intégrité est vérifiée. |
| Ressources principales, tous types | **10 013** | Le total du pack ; les 9 791 motifs sont comptés séparément. |

### Ce qui se dessine automatiquement et ce qui se pose autrement

Les **325 presets**, leurs **9 791 motifs**, **373 atlas SmartTile**, **944 animations**, **266 matériaux** et **337 catégories** ont été rapprochés exactement de l’archive puis passés au validateur canonique de `map_core` : **zéro erreur et zéro avertissement**.

Pour les presets disposant de règles, l’évaluateur canonique rapporte **138 / 138 outils standards exacts sur leurs 1 609 scénarios déclarés**. Quatre presets composants à règles ajoutent dix-neuf scénarios : **142 / 142 au total, 1 628 scénarios**. Les tests négatifs confirment que retirer toutes les règles ou les liaisons d’atlas invalide l’évaluation.

Les **90 constructions natives** et **33 collections manuelles** sont présentes : aucune n’est dépourvue à la fois de règles et de motifs. Elles ne sont donc pas 123 assets manquants. En revanche, elles ne doivent pas être présentées comme 123 brosses à raccords automatiques pour toute géométrie. Des motifs tels qu’une flèche ou un téléporteur ont naturellement un usage de tampon. Il faut rendre le mode de pose lisible et créer des règles supplémentaires seulement lorsque l’usage visé le demande.

La couverture des scénarios déclarés ne remplace pas un parcours visuel des lignes, angles, extrémités et jonctions de tous les outils et bordures. Cette qualification d’usage reste distincte de la disponibilité graphique.

[33 outils manuels, avec noms et identifiants](</Users/karim/Project/Avelune Package/local-records/frlg-1.9.3-exhaustive-audit/readiness/manual-tools.csv>) · [90 constructions natives](</Users/karim/Project/Avelune Package/local-records/frlg-1.9.3-exhaustive-audit/readiness/native-construction-tools.csv>) · [évaluation canonique détaillée](</Users/karim/Project/Avelune Package/local-records/frlg-1.9.3-exhaustive-audit/canonical/result.json>).

### Classement complet

Le catalogue contient 936 identifiants de familles. Huit chemins complets sont dupliqués : `Bâtiments`, `Clôtures`, `Sols`, `Objets`, `Eau`, `Arbres`, `Végétation`, et `Sols / Constructions natives — Rouge Feu et Vert Feuille / Îles Écume`.

Le tableau consolidé fournit **791 lignes de regroupement utilisées**, dont une ligne sans famille pour 55 atlas supports techniques. Ses colonnes totalisent exactement 793 modèles standards, 261 outils standards, 74 environnements standards, sept bordures et 8 878 composants de tous types, soit **10 013 ressources**. Aucun standard n’est dépourvu de famille, description ou contexte ; les erreurs sémantiques de classement du fauteuil et de l’ascenseur restent à corriger.

[Inventaire complet par famille et type de ressource](</Users/karim/Project/Avelune Package/local-records/frlg-1.9.3-exhaustive-audit/families.csv>). Le dénominateur des besoins graphiques est celui des cartes et états sources ; les intitulés historiques de « 35 familles » ne définissent pas un nombre canonique de modèles Avelune nécessaires.

## Confrontation de toutes les cartes RPG Maker

| Contrôle | Résultat frais |
| --- | ---: |
| Fichiers de cartes décodés | **383 / 383**, zéro erreur |
| Cartes non vides / cartes vides ou dossiers | **345 / 38** |
| Cellules des trois couches examinées | **1 456 380**, dont **651 737 non nulles** |
| Références distinctes carte/tuile, événements inclus | **22 843** |
| Références avec pixels présents | **22 840** |
| Références à des annotations d’éditeur exclues | **2** |
| Référence réellement invalide | **1** |
| Atlas utilisés | **33 : 17 statiques et 16 autotiles** |
| Pages d’événement à tuile | **85**, dont une référence invalide |
| Cellules des trente planches de décors présentes | **480 : 228 non vides et 252 vides** |
| États non vides retrouvés comme frames entières | **228 / 228**, soit **161 dessins distincts** |

Parmi les 228 états, 136 ont une correspondance standard et 92 uniquement des composants. Les 92 ne sont pas des objets manquants : plusieurs sont des états internes d’animation. Les 36 frames statiques ou animées de Doors8 préservent tous les pixels utiles après retrait du seul magenta opaque documenté.

### Défauts du projet source, séparés des manques du pack

| Source | Défaut ou réserve précis | Conséquence |
| --- | --- | --- |
| Trois atlas originaux | `FRLG_Outside`, `FRLG_Interior general`, `FRLG_Caves` absents ; **230 cartes RPG Maker** les déclarent | Leur identité originale ne peut pas être certifiée. Les supports récupérés et la comparaison native indépendante établissent séparément la disponibilité des graphismes officiels. |
| Joyful Game Corner | Carte **233**, événement **2 « PC »**, **page 2**, tuile **647**, rectangle `[224,1024,32,32]` hors atlas | Corriger cette référence ou utiliser un PC valide déjà présent ; ce n’est pas quatre assets absents. |
| Lost Cave | `fog10` absent sur les cartes **347–360**, soit **14 cartes** | L’identité avec un autre fichier de brume reste non prouvée. La brume native FRLG existe ; ne pas annoncer un nouvel asset officiel manquant. |
| Carte 195 | `berrytreeAGUAVBERRY` absent sur cinq événements | Ajout Essentials hors besoins officiels FRLG ; à récupérer uniquement pour reproduire cette personnalisation. |
| Azuria / Green Path | Six empreintes distinctes d’annotations, correspondant à 34 coordonnées de quarts et deux références de carte | Les croix et instructions de l’éditeur ne doivent pas être importées comme décors du jeu. |
| Illustrations d’entrée RPG Maker | Dix-neuf fichiers encadrés 512 × 384 différents des illustrations natives | Les 21 illustrations natives 480 × 320 sont toutes exactes ; ne pas compter dix-neuf images de jeu manquantes. |

Le corpus RPG Maker comprend des ajouts et ne découpe pas les lieux comme le jeu natif. Il ne faut ni soustraire 383 de 425, ni additionner ces deux corpus comme autant de cartes distinctes à refaire.

[383 cartes et leur verdict individuel](</Users/karim/Project/Avelune Package/local-records/frlg-1.9.3-exhaustive-audit/rpg/final-map-status.csv>) · [22 843 références détaillées](</Users/karim/Project/Avelune Package/local-records/frlg-1.9.3-exhaustive-audit/rpg/current-tile-references.csv>) · [228 états visibles et leurs correspondances](</Users/karim/Project/Avelune Package/local-records/frlg-1.9.3-exhaustive-audit/rpg/current-object-state-coverage.csv>).

## Méthode, preuves et limites

### Entrées et audit initial

- Pack publié : version **1.9.3**, 109 607 908 octets, SHA-256 `0ee82db83846d4b256e812639961f9af0f8031e793c80868f62468e90f912b38`.
- Référence native : `pret/pokefirered`, commit `037335f4c725d7c9aecdac87066f2002b4bd7e14`. **9 857 fichiers**, 31 792 059 octets, vérifiés à nouveau contre le tar épinglé : aucune différence. Le code C externe n’est pas exécuté et aucune ROM n’est construite.
- Source RPG Maker : dossier Kanto fourni ; **636 fichiers sources hachés à nouveau**, inchangés par rapport au manifeste précédent. Le décodeur Marshal est inerte et n’exécute pas les scripts Ruby.
- L’audit 1.8.1 et les correctifs 1.9.0–1.9.3 servent de pistes. Les tableaux d’archive, pixels, références et compteurs ci-dessus sont réévalués sur la 1.9.3.
- Risques initiaux : mélanger disponibilité des pixels et intégrité d’objet ; confondre composants et standards ; convertir toute différence de palette ou d’ancrage en doublon ; prendre le corpus personnalisé RPG Maker pour l’inventaire officiel ; annoncer chaque outil de construction comme une brosse automatique.

Les 793 aperçus standards actuels ont été inspectés visuellement sur douze planches datées, puis les anomalies concrètes recoupées avec les sources. Les 1 057 frames standards et 458 frames des 224 compagnons illustrés ont été comparées aux ressources de l’archive. Cette dernière comparaison prouve la fidélité de l’aperçu au pack ; elle ne prouve pas, à elle seule, la fidélité du pack au jeu. La porte de Chen illustre précisément cette différence.

### Fichiers produits et zones

Le seul ajout demandé au dépôt moteur est ce rapport. Aucun code moteur, projet Studio, carte source, package publié, aperçu publié ou site n’est modifié. Les évaluateurs et preuves restent dans **A = `/Users/karim/Project/Avelune Package/local-records/frlg-1.9.3-exhaustive-audit`**.

| Zone | Contenu et rôle |
| --- | --- |
| `native/` | Décodage source indépendant, comparaison de toutes les cartes, états Cut, portes, illustrations et annexes ; scripts relançables, CSV par carte et preuves Chen. |
| `native/annexes/` | Identification source du fauteuil et de la paroi d’ascenseur ; ces annexes ne réécrivent pas les preuves natives déjà figées. |
| `rpg/` | Décodage inerte des 383 cartes, empreintes source, atlas, événements, frames entières et tests de faux manques. |
| `readiness/` | Rôles, familles, outils, environnements, bordures et doublons sémantiques, avec identifiants exacts. |
| `canonical/prepare_input.py` | Rapprochement hashé des six tables SmartTile du catalogue de préparation avec les unités de l’archive actuelle. |
| `canonical/validate_tools.dart` | Appels publics `validateProjectSmartTileCatalog` et `analyzeSmartTileCoverage`, compteurs standards/composants séparés et deux contrôles négatifs. |
| `critique/` | Relecture indépendante, tests de consolidation, douze planches des aperçus et probes de contexte source. |
| `effect-sequences/` | Tables d’animation C actives, ordre et cadence des séquences, distinction des fragments et mouvements procéduraux, garde-fous. |
| Racine de A | `verify_native_snapshot.py`, `consolidate.py`, `summary.json`, `families.csv`, `remaining-work.csv`, états Git et reçu final avec inventaire complet des fichiers. |

### Commandes et résultats frais

| Vérification | Commande depuis le sous-dossier indiqué | Résultat |
| --- | --- | --- |
| Pipeline natif | `python3 -B run_all.py` dans `native/` | Comparaisons complètes terminées ; diagnostic de porte incorrecte conservé. |
| Garde-fous natifs | `python3 -B -m unittest discover -s . -p test_audit_guards.py -v` | **9 tests réussis**, dernière relance racine **0,038 s**. |
| Garde-fous RPG | `python3 -B -m unittest discover -s . -p 'test_*.py' -v` dans `rpg/` | **16 tests réussis**, **0,540 s**. |
| Garde-fous de préparation | `python3 -B -m unittest test_readiness.py -v` dans `readiness/` | **6 tests réussis**, **0,002 s**. |
| Critique croisée | `python3 -B -m unittest test_cross_audit.py -v` dans `critique/` | **13 tests réussis**, dont séparation des unités, effets, fauteuil existant et animation d’ascenseur ; chronométrage final dans le reçu. |
| Séquences d’effets | `python3 -B -m unittest discover -s . -p 'test_*.py' -v` dans `effect-sequences/` | **12 tests réussis**, dont ordre de frames, durée et refus d’une frame transparente intermédiaire ; chronométrage final dans le reçu. |
| Validateur canonique | `dart --packages=/Users/karim/Project/pokemonProject/packages/map_core/.dart_tool/package_config.json canonical/validate_tools.dart canonical/input.json canonical/result.json` avec chemins absolus depuis A | Exécution compilée réussie, **325 presets**, **zéro erreur/zéro avertissement**, **1 609 scénarios standards exacts**, deux négatifs satisfaits. |
| Intégrité source native | `python3 -B verify_native_snapshot.py` depuis A | **9 857 fichiers identiques**, zéro écart. |
| Consolidation | `python3 -B consolidate.py` depuis A | Compteurs et unités réconciliés ; 791 lignes de familles totalisant 10 013 ressources. |

Une dépréciation Pillow `Image.getdata` est émise par l’évaluateur d’illustrations ; les comparaisons et tests passent, sans changement de dépendance applicative.

Build Studio/Player : **non applicable à cet audit sans modification applicative**. La meilleure vérification supplémentaire est l’exécution compilée du validateur canonique actuel. Aucun nouveau rendu Studio de chaque carte, parcours Player ou test d’appareil n’est revendiqué. Parité MCP : aucune sémantique d’authoring n’est ajoutée et aucun projet mutable n’est modifié ; reconstruction et transport restent hors périmètre de cette lecture.

### Passes indépendantes

| Passe | Verdict |
| --- | --- |
| Audit des sources RPG Maker — `audit194_rpg_maps` | Recensement complet des 383 cartes ; pixels et frames recensés, référence PC invalide et réserves source nommées ; 16 tests. |
| Implémentation des évaluateurs et synthèse — racine | Entrées épinglées, rapprochement des tables d’archive, évaluateur canonique et consolidation ; aucune correction de production appliquée. |
| Tests et préparation — `audit194_readiness` | Séquences, variantes, doublons, modes de pose et métadonnées examinés ; six tests et six alias identifiés. |
| Build/validation native — `audit194_native_maps` | 421 définitions hors prototypes et leurs contextes couverts ; 21 illustrations exactes ; masque de Chen incorrect démontré ; neuf garde-fous. |
| Critique finale — `audit194_readiness`, passe croisée distincte | Treize tests de consolidation, revue des 793 aperçus, recoupement des trois probes et des séquences d’effets ; verdict final consigné dans `critique/critique.json`. |

### Git, stockage et traçabilité

État initial : moteur `37bbdf845e130d6688bc78cb17da6e9bedac634b`, 351 chemins modifiés/non suivis préexistants ; dépôt packages `4c7de0c6ca1b179e336db2a21753781cc47ea22f`, travaux concurrents présents. L’état complet initial et l’état final sont conservés dans les reçus. **Aucune écriture Git, publication ni modification du site par cet audit.**

Au contrôle final, le moteur est passé à `021a0a822527c1c9137a1b0fae630c91af13d6b9` par le travail concurrent ; le dépôt packages conserve son SHA initial. Le nombre de chemins modifiés/non suivis continue d’évoluer avec les autres conversations : les listes et compteurs exacts au dernier contrôle figurent dans le reçu. Ils ne constituent pas le diff de cette tâche : elle ajoute seulement ce rapport au moteur et son dossier privé de preuves au dépôt packages.

Le contrôle Markdown est exécuté sans contournement : trois rapports non suivis préexistants excèdent déjà le budget zéro ; le présent rapport d’audit est l’unique ajout Markdown de cette tâche, explicitement demandé. Les documents étrangers ne sont ni supprimés ni modifiés. L’état exact après ajout et les tailles finales figurent dans le reçu final.

Les sources, archives et preuves utiles sont conservées. Aucun téléchargement du pack en double, aucune reconstruction de ROM, aucun export vidéo ni rendu massif des cartes. Les petits comparatifs et CSV sont locaux. Le JSON intermédiaire `canonical/input.json`, **18 408 347 octets**, est supprimé après validation : `canonical/prepare_input.py` le régénère exactement ; son empreinte et le nettoyage sont consignés dans le reçu. Le résultat de validation et ses preuves restent disponibles.

Les **56 tests de garde-fous** sont réussis au dernier passage racine. Le dossier de preuves représente environ **45,2 Mio** et le SSD dispose de **15,5 Gio libres** au contrôle final ; ces mesures sont ponctuelles. Le contrôle Markdown sort avec le code 1, **quatre nouveaux Markdown contre un budget zéro**, dont les trois préexistants et le présent rapport expressément demandé. Aucun contournement de limite n’est utilisé.

Traçabilité : ticket existant [POST-WLD-ASSET-PACK-001](https://app.notion.com/p/3fb197a7bfa581379199ceec8afe5486). L’audit est proposé **TO REVIEW**, le chantier de correction reste **DOING** ; aucun élargissement du backlog bêta et aucun passage automatique à DONE.

## Auto-critique et décision de suite

L’audit des références et des graphismes comparés est terminé. La correction des défauts identifiés n’est pas appliquée par cette tâche. Les preuves ne justifient pas encore l’expression « package définitif permettant de refaire le jeu de A à Z sans préparation ».

La prochaine correction utile est ciblée : restaurer la porte de Chen, renommer et classer le fauteuil propre déjà présent, assembler et animer correctement la paroi d’ascenseur, remapper les six alias de portes et nettoyer la taxonomie/les deux descriptions. Ensuite, une carte témoin de dessin doit vérifier les usages promis des outils et bordures, sans présenter les tampons comme des autotiles.

Les acteurs, leur occultation entre les plans, les collisions, les événements de porte, les transitions d’animation et une ROM française localisée ne sont pas certifiés par cette comparaison graphique. La référence native épinglée est anglaise ; cela ne prouve pas les éventuels textes graphiques localisés. Les illustrations d’entrée contrôlées ne contiennent pas de texte français gravé. Aucun pourcentage global ne mélange ces besoins différents.

[Liste actionnable des travaux restants](</Users/karim/Project/Avelune Package/local-records/frlg-1.9.3-exhaustive-audit/remaining-work.csv>) · [synthèse structurée](</Users/karim/Project/Avelune Package/local-records/frlg-1.9.3-exhaustive-audit/summary.json>) · [reçu technique et inventaire final](</Users/karim/Project/Avelune Package/local-records/frlg-1.9.3-exhaustive-audit/final-receipt.json>).
