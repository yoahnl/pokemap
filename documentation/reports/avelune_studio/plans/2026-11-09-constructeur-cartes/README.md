# Constructeur de cartes Avelune — dossier de référence

**Nouveau plan exécutoire : [remplacement intégral de l’UI de Studio, chapitre 27](#27-remplacement-ui).** Il contient 88 lots dans 15 thématiques, impose le retrait avant reconstruction et remplace l’ancien découpage D01–D14 comme ordre de travail. [Ouvrir le plan et les comparaisons dans l’artefact](index.html#replacement).

**Version documentaire : 9 novembre 2026. Révision MagicPath figée : 470590493273763840.**

Ce dossier rassemble la proposition de constructeur de cartes, les états de son interface, les décisions produit conservées, les limites constatées et un découpage pour la réalisation native. Il clôt la phase de consolidation de cette maquette. Il ne lance pas une nouvelle refonte.

**Pour commencer : ouvrir [index.html](index.html).** La galerie et la documentation fonctionnent localement, sans compte MagicPath, sans serveur et sans connexion réseau. Le dossier doit rester entier pour conserver les images. [manifest.json](manifest.json) fournit l’inventaire exploitable par un programme ; [captures/](captures/) contient les originaux.

## Sommaire

1. [Périmètre, provenance et niveau de preuve](#1-perimetre)
2. [Décisions produit de référence](#2-decisions)
3. [Architecture générale de l’écran](#3-structure)
4. [Sélection, outils et changements de contexte](#4-selection)
5. [Bibliothèque et recherche de ressources](#5-bibliotheque)
6. [Décors et instances](#6-decors)
7. [Sols, chemins et eau](#7-surfaces)
8. [Reliefs, parois et pentes](#8-reliefs)
9. [Environnements et génération](#9-environnements)
10. [Contenu, calques et actions communes](#10-contenu)
11. [Navigation, extérieur et caméra](#11-vue)
12. [Gestion des cartes et réglages](#12-cartes)
13. [Jeu : connexions et passages](#13-connexions)
14. [Jeu : déplacements](#14-deplacements)
15. [Jeu : rencontres sauvages](#15-rencontres)
16. [Jeu : départs, arrivées et utilitaires](#16-points)
17. [Scénario : éléments, comportements et références](#17-scenario)
18. [Ambiance : temps, météo, effets et musique](#18-ambiance)
19. [Historique, enregistrement et test](#19-session)
20. [États transversaux et accessibilité](#20-transversal)
21. [Limites connues et corrections à réaliser](#21-limites)
22. [Traduction vers l’architecture native](#22-native)
23. [Lots de réalisation et critères de sortie](#23-lots)
24. [Parcours de recette de bout en bout](#24-recette)
25. [Couverture, exclusions et maintenance](#25-couverture)
26. [Index exhaustif des captures livrées](#26-index)
27. [Plan de remplacement intégral de l’UI de Studio](#27-remplacement-ui)

<a id="1-perimetre"></a>
## 1. Périmètre, provenance et niveau de preuve

### 1.1 La référence figée

| Élément | Valeur |
| --- | --- |
| Projet MagicPath | 470322374529675264 |
| Composant | 470322378581372928 |
| Nom | Avelune — Construire une carte |
| Nom généré | finely-dusk-9230 |
| Révision publiée de référence | 470590493273763840 |
| Captures de documentation | 001 à 401 : 401 images |
| Captures de l’audit précédent, même révision | 900 à 914 : 15 images |
| Total du dossier | 416 captures JPEG |
| Source des captures | Prévisualisation locale du code de cette révision, interactions dans le navigateur |
| Données manipulées | Exemples de maquette en mémoire, sans modification des projets natifs |
| Modification distante pendant cette documentation | Aucune |

Les captures montrent le rendu et les états interactifs de la révision MagicPath récupérée. Elles ne sont pas des captures de l’application Flutter native ni une preuve de publication de leurs données dans MagicPath. Les captures d’audit ont été importées en conservant leur contenu ; leur provenance est distincte dans le manifeste.

Le fond illustré du village ou de l’intérieur n’est pas une reconstruction de tous ses objets. Une maison visible dans l’image ne constitue pas automatiquement un décor sélectionnable. Les nouveaux éléments et les repères sont superposés à ce fond. Les cartes sans image peuvent utiliser un plan schématique. Cette distinction explique plusieurs différences entre la composition visible et la liste Contenu.

### 1.2 Comment lire les affirmations

| Mention | Sens |
| --- | --- |
| **Observé** | État obtenu par l’interface ou comportement confirmé dans le code figé ; la capture associée illustre le résultat visible |
| **Cible native** | Règle à respecter dans la réalisation Avelune ; sa présence dans ce dossier ne prouve pas sa livraison |
| **Limite connue** | Incohérence ou interaction incomplète conservée dans la révision figée |
| **Non démontré** | Fonctionnement qui nécessite le moteur, la persistance, un catalogue réel ou un autre profil de projet |

Une capture prouve un affichage. Les changements de données relèvent de l’interaction ou de la lecture du code, et la jouabilité exige une validation native. « Aucune incohérence détectée » dans la maquette ne veut pas dire que le jeu est certifié.

### 1.3 Portée de « tous les états possibles »

L’inventaire couvre les familles d’états et les branches accessibles pertinentes : accueil, ressource choisie, outil armé, résultat, sélection, vide, filtre, refus, verrouillage, confirmation, aperçu et variantes de réglages. Les champs numériques, textes libres, tracés et combinaisons entre panneaux produisent une infinité de configurations : il n’existe pas une capture de chaque combinaison de pixels.

Les alternatives finies importantes sont montrées ou énumérées dans les chapitres. Les valeurs continues sont illustrées par des exemples et des bornes. Les branches impossibles à atteindre avec les données et le profil de la maquette sont recensées au chapitre 25. Aucun état n’a été fabriqué en modifiant le code source pour lui donner l’apparence d’une fonctionnalité disponible.

### 1.4 Rapport avec le plan existant

Ce dossier complète le [plan de refonte Studio du 6 novembre](../2026-11-06-refonte-studio.md), qui contient 41 lots dans son état consulté. Il ne remplace pas ses statuts ni les travaux natifs déjà réalisés. Les lots du chapitre 23 sont des unités de reprise pour ce constructeur, avec une correspondance vers les lots UX existants.

<a id="2-decisions"></a>
## 2. Décisions produit de référence

Les points suivants viennent des demandes et validations de la conversation. Ils constituent la direction retenue.

1. **Une carte reste le sujet central.** Les panneaux servent la tâche en cours et la carte garde une place lisible.
2. **Quatre espaces explicites : Construction, Jeu, Scénario, Ambiance.** Chaque espace expose ses objets et son vocabulaire.
3. **La bibliothèque complète reste accessible.** « Sur cette carte » est un raccourci vers les ressources déjà employées, jamais une restriction du droit de construire. Une éolienne du projet doit pouvoir être posée sur une carte qui ne l’utilisait pas.
4. **Les familles de construction restent visibles.** Décors, Sols, Chemins, Eau, Reliefs et parois, Environnements sont des entrées compréhensibles. Le sélecteur et le choix de famille ne doivent pas se dissimuler l’un l’autre.
5. **Chemins et eau sont différenciés.** Leurs intentions d’usage, aperçus et ressources sont identifiables.
6. **Surface, relief et pente sont différenciés.** Le relief possède une bibliothèque ; une pente est une transition de niveau, pas seulement une texture.
7. **Le sommet et la paroi se prévisualisent ensemble.** On doit voir comment un sol ou un chemin se comporte avec les bords et la géométrie.
8. **Les actions communes ont un propriétaire clair.** Contenu centralise les opérations sur les éléments ; l’inspecteur porte leurs propriétés. Un raccourci éventuel appelle la même commande.
9. **Le Scénario associe des comportements à des éléments.** L’écriture des scènes reste dans l’espace Scènes.
10. **Les liaisons simples entre cartes ne nécessitent pas une scène.** Connexion de bords, passage et arrivée sont des objets de jeu.
11. **L’aperçu reste distinct de la configuration enregistrée.** Prévisualiser la nuit ne fixe pas l’heure de la carte.
12. **Une référence ne devient pas une copie.** Scène, table de rencontres, définition de dresseur et décor porteur gardent leur identité.
13. **Un refus explique sa cause.** Verrouillage, dépendance, limite ou brouillon doivent orienter vers une correction.
14. **La documentation devient la base de reprise.** Les défauts restants sont bornés ; ils n’autorisent pas à relancer indéfiniment une nouvelle série de maquettes.

<a id="3-structure"></a>
## 3. Architecture générale de l’écran

### 3.1 Zones stables

| Zone | Responsabilité | Exemple |
| --- | --- | --- |
| Navigation globale, tout à gauche | Changer de grand module de Studio | Ressources, Scènes, données du projet |
| Barre supérieure | Identité du projet et de la carte, historique, Contenu, réglages, enregistrement, test | Bourg Geon, Annuler, Tester la carte |
| Colonne gauche | Choix des ressources ou des éléments de l’espace | Catalogue en Construction, catégories de règles en Jeu |
| Onglets au-dessus du canevas | Changer d’espace sur la carte | Construction, Jeu, Scénario, Ambiance |
| Barre d’outils du canevas | Geste actif | Sélection, Peindre, Effacer |
| Canevas | Construction, repères ou aperçu selon l’espace | Tracé, zone, passage, météo |
| Colonne droite | Propriétés de l’outil ou de la sélection | Pente, PNJ, passage, météo |
| Barre inférieure | État, zoom, aides et commandes de vue | Échelle, grille, indication du mode |

**Captures repères :** 001, 173, 262, 328 et 394–398.

### 3.2 Les quatre espaces

| Espace | Question de l’utilisateur | Objets principaux | Ce qui reste ailleurs |
| --- | --- | --- | --- |
| Construction | « De quoi est faite la carte ? » | Décors, surfaces, reliefs, pentes, environnements | Règles de jeu et scènes |
| Jeu | « Comment peut-on y jouer et la traverser ? » | Connexions, passages, déplacements, rencontres, points, utilitaires | Dialogue et actions scénarisées |
| Scénario | « Qui ou quoi déclenche quelle scène ? » | PNJ, interactions, zones, entrée de carte, références à des résultats | Édition du contenu de la scène |
| Ambiance | « Quelle atmosphère a ce lieu ? » | Temps, météo, effets, musique | Changements temporaires exécutés par une scène |

La barre globale fournit des accès aux autres modules. Dans la maquette, plusieurs de ces accès ouvrent seulement un dialogue explicatif. Les captures 014–019 ne montrent pas les futurs écrans complets de ces modules.

### 3.3 Une seule carte active

La carte annoncée dans la barre globale, le sélecteur local, le canevas, les compteurs et l’inspecteur doivent toujours correspondre. Un élément trouvé à l’échelle du projet indique sa carte propriétaire. Son ouverture doit rendre le contexte explicite.

**Cible native :** changer de carte annule un geste non validé selon la règle de garde du chapitre 4, retire les sélections locales incompatibles et restaure une vue cohérente. Une sélection périmée ne doit jamais provoquer une modification sur la nouvelle carte.

<a id="4-selection"></a>
## 4. Sélection, outils et changements de contexte

### 4.1 Les notions à garder séparées

- **Famille de bibliothèque :** filtre les ressources proposées.
- **Ressource choisie :** matériau, décor ou preset utilisé par la prochaine création.
- **Outil actif :** décrit le geste sur la carte.
- **Élément sélectionné :** instance déjà présente, avec son identifiant et sa carte.
- **Sélection multiple :** ensemble explicite d’éléments ; elle ne possède pas les propriétés détaillées d’un élément unique.
- **Prévisualisation en attente :** proposition non encore appliquée ; elle n’est pas un élément durable.

Une ressource choisie ne doit pas être présentée comme une instance existante. Un décor sélectionné ne change pas de ressource parce qu’on parcourt un autre filtre. La distinction doit rester visible dans le titre et les champs de l’inspecteur.

### 4.2 Machine d’interaction attendue

| Départ | Action | Arrivée attendue | Historique |
| --- | --- | --- | --- |
| Aucune sélection | Cliquer un élément | Sélection simple ; inspecteur de cet élément | Aucune mutation |
| Sélection simple | Sélectionner plusieurs lignes de Contenu | Sélection multiple ; actions communes | Aucune mutation |
| Navigation de bibliothèque | Choisir une ressource | Outil compatible armé et propriétés de création | Aucune mutation avant geste |
| Outil armé | Cliquer ou glisser dans une zone valide | Élément créé ou trait terminé | Une transaction logique |
| Outil armé | Échap / Annuler | Retour à la sélection | Aucune création |
| Prévisualisation environnement | Appliquer | Zone et proposition appliquées | Une transaction |
| Prévisualisation environnement | Abandonner | Proposition retirée | Aucune création |
| Prévisualisation environnement | Changer de contexte | Garde : rester, abandonner, appliquer | Mutation seulement si appliquer |
| Élément verrouillé | Modifier | Refus explicite ; inspection possible | Aucune mutation |
| Sélection filtrée | Localiser / Propriétés | Élément et espace propriétaire identifiables | Aucune mutation |

Les captures 091–096 montrent la garde d’environnement. Les captures 389–392 montrent les états de sélection multiple et de verrouillage. La capture 401 montre le raccourci de recherche depuis Jeu, qui conduit à Construction et focalise la recherche.

### 4.3 Règles natives à unifier

Chaque entrée d’une action doit appliquer les mêmes contrôles : canevas, champ numérique, flèche de déplacement, duplication, commande clavier et action MCP. Les contrôles portent sur la carte, la géométrie, la zone jouable, l’extérieur, le verrouillage effectif, les dépendances et les capacités du profil.

La maquette présente encore des divergences sur ces points. Les anomalies L01, L03, L07 et L09 du chapitre 21 ne sont pas des exceptions produit acceptées.

<a id="5-bibliotheque"></a>
## 5. Bibliothèque et recherche de ressources

### 5.1 Recherche et portée

**Observé :** la colonne Ressources comprend une recherche, les six familles, les portées « Sur cette carte » et « Tout le projet », des sous-familles, des compteurs et une présentation en vignettes ou en liste.

| État | Résultat attendu | Captures |
| --- | --- | --- |
| Toutes les familles, tout le projet | Ensemble du catalogue d’exemple | 001–007, 900 |
| Famille choisie | Ressources de cette famille | 002–007 |
| Recherche avec résultat | Résultats lisibles dans le contexte des filtres | 008–009 |
| Recherche sans résultat | Message, cause probable et remise à zéro | 010, 399 |
| Filtre visible puis panneau replié | Puce du filtre toujours visible et retirable | 011–013, 400 |
| Carte vide, portée locale | Aucun usage local ; catalogue projet accessible | 147–149 |
| Raccourci de recherche | Construction ouvert et champ focalisé | 401 |

**Limite de la maquette :** certains changements de portée réinitialisent la sous-famille. La capture 013 a été nommée selon ce résultat réel. L’état vide de sous-famille sur la carte est réellement montré par 399 et 400.

### 5.2 Parcours de référence : poser une éolienne

1. Ouvrir Construction.
2. Garder ou choisir Décors.
3. Passer sur « Tout le projet » si la ressource n’est pas utilisée ici.
4. Rechercher « éolienne » ou ouvrir la sous-famille adaptée.
5. Choisir la vignette ; l’aperçu et les réglages de placement apparaissent.
6. Cliquer une case valide de la carte.
7. Revenir à Sélection pour modifier l’instance.
8. Vérifier que la ressource apparaît ensuite dans les usages de la carte.

Les captures 024–025, 048–055 et 386–387 documentent le choix et les instances. Le dernier point est un critère de recette native : le calcul des usages doit provenir des données réelles, pas d’une liste statique.

### 5.3 Fiche et rôle d’une ressource

La vignette donne un aperçu, un nom et sa famille. Le choix d’une ressource alimente le bon outil. Le catalogue de démonstration contient 21 ressources ; les captures 028–047 et 024 montrent leurs aperçus.

**Cible native :** une fiche distingue la définition partagée de l’instance locale. Changer la collision d’une éolienne posée ne doit pas réécrire la ressource pour toutes les cartes. L’édition, l’import, le remplacement ou la suppression d’une ressource globale restent dans leur module propriétaire, avec analyse des usages.

### 5.4 États réels à prévoir à l’intégration

Le catalogue statique ne démontre pas le chargement asynchrone, l’erreur de lecture, la ressource manquante, le fichier incompatible ou la disparition d’une ressource pendant une recherche. La réalisation native doit prévoir un état explicite et conserver la recherche lorsque l’utilisateur réessaie. Ces états sont recensés sans fausse capture au chapitre 25.

<a id="6-decors"></a>
## 6. Décors et instances

### 6.1 Création et inspection

**Observé :** une ressource de décor peut être posée, puis inspectée. La maquette expose la position en cases, quatre rotations, la collision et des paramètres visuels d’instance.

| Paramètre | Sens | Captures |
| --- | --- | --- |
| X, Y | Position de l’instance sur sa carte | 048–055 |
| Rotation | 0°, 90°, 180°, 270° | 048–051 |
| Bloquer le passage | Collision de ce décor | 052 |
| Taille en pourcentage | Échelle de cette instance | 053 |
| Décalage vertical | Ajustement de présentation | 053 |
| Ordre | Superposition visuelle | 054 |
| Animation | Animation de l’instance de démonstration | 054 |
| Position refusée | Respect de la zone d’appartenance | 055, 126 |

Les plages exactes du prototype sont des choix de démonstration ; elles ne constituent pas une nouvelle définition du format natif. Rotation et échelle doivent être confrontées aux capacités du profil et de la ressource.

### 6.2 Image de référence et objets éditables

La capture 026 montre un clic sur le lit visible dans l’image de fond. Elle ne prouve pas l’existence d’une instance « lit » modifiable. La capture 065 montre une sélection de décor superposé, pas la sélection du tracé qui était visé.

**Cible native :** les objets réels doivent être identifiables par leur contour, leur nom et Contenu. Un fond de référence reste un fond, masquable indépendamment.

### 6.3 Déplacement et liaison à une interaction

Le déplacement par champs et les commandes communes existent dans la maquette. **Le déplacement direct d’un décor par glisser ne fonctionne pas dans la révision figée** : voir L08 et 913.

Un objet interactif de Scénario peut référencer un décor porteur. Il suit alors ce décor ; sa position n’est plus modifiable dans Scénario. La suppression du décor doit être protégée tant que le lien existe. Les captures 317 et 383 illustrent ces deux responsabilités.

La duplication d’un décor lié et d’une interaction doit préserver la relation entre les deux copies, sans rattacher la copie au décor original. Les captures 384–386 illustrent un cas de duplication ; la persistance de cette relation reste à vérifier dans l’application native.

<a id="7-surfaces"></a>
## 7. Sols, chemins et eau

### 7.1 Modèle produit

| Famille | Intention | Exemple |
| --- | --- | --- |
| Sols | Recouvrir une surface | Herbe, sable |
| Chemins | Construire un parcours lisible | Terre, pavés |
| Eau | Définir une surface et son rivage | Bassin, rive |

Ces familles partagent des mécanismes de surface, mais gardent des ressources et des aperçus distincts. Une eau visible ne prouve pas une règle de Surf ; le déplacement se configure dans Jeu.

### 7.2 Gestes et formes

**Observé :** les chemins proposent des pièces de démonstration, une largeur et des gestes de tracé ; les surfaces proposent notamment peinture et formes. La sélection d’un tracé permet d’inspecter sa forme et son contour.

| Cas | Ce qu’il faut lire | Captures |
| --- | --- | --- |
| Chemin droit / virage / jonction | Raccord visuel des pièces | 056–059 |
| Largeur minimale / maximale | Effet du réglage sur l’outil | 060–061 |
| Ligne / tracé libre | Départ et résultat d’un geste | 062–063 |
| Effacer sans élément ciblé | Pas de destruction de l’image de fond | 064 |
| Formes de tracé sélectionné | Variante de géométrie et propriétés | 066–069 |
| Points du contour | Coordonnées et contour sélectionné | 070 |
| Sol : pièces et pinceau | Variante de surface et taille | 071–074 |
| Rectangle : survol de l’outil | Présentation du contrôle, sans preuve d’application | 075 |
| Matériaux de sommet | Association avec relief ou surface | 076–080 |

**Attention :** 075 est un état de survol. Les états de rectangle sélectionné et de pente appliquée se lisent dans 068 et 087. Le dossier ne rebaptise pas un survol « terrain construit ».

### 7.3 Cible native

Un geste se convertit dans les surfaces et Paths natifs. Le contour, le matériau, l’ordre, les raccords et les collisions gardent leurs contrats existants. Une édition locale ne doit pas recalculer tout le projet.

Les coordonnées de cellule et les coordonnées de bord de cellule ont des domaines différents : une carte de largeur 32 possède des indices de cellule 0 à 31, mais son bord droit est à 32. La maquette confond ces domaines dans certains champs. L03 doit être corrigée à la traduction native.

L’effacement doit décrire ce qu’il enlève : une couverture, une portion de tracé ou un objet entier. Il doit être cohérent avec le modèle natif et réversible dans l’historique. Un outil d’effacement ne doit pas supprimer un décor superposé par simple ambiguïté de cible.

<a id="8-reliefs"></a>
## 8. Reliefs, parois et pentes

### 8.1 Organisation retenue

Le choix de la ressource et le choix du travail à effectuer sont deux niveaux visibles :

| Niveau | Choix |
| --- | --- |
| Bibliothèque | Sol, chemin, eau, relief/paroi, environnement |
| Géométrie | Surface, Relief, Pente |
| Style de bord | Paroi de terre, roche ou autre Border compatible |
| Surface supérieure | Sol ou matériau de chemin compatible |
| Geste | Contour continu, zone, transition ou autre outil existant |

Le relief conserve sa propre bibliothèque. La pente apparaît comme un travail géométrique avec orientation et transition de niveau. L’utilisateur peut juger ensemble sommet, chemin et paroi au lieu d’assembler mentalement plusieurs catalogues.

### 8.2 États illustrés

- Les ressources Reliefs et parois sont accessibles par la famille dédiée : 006 et les fiches 028–047.
- Les réglages de relief continu, de réancrage et de niveau sont montrés dans 081–083.
- Les orientations de pente sont montrées dans 084–086 et 088 ; le résultat appliqué est illustré dans 087.
- L’inspection d’une géométrie sélectionnée est montrée dans 088 et les captures voisines de cette séquence.
- La discordance Eau → Sculpter → relief de terre est documentée dans 911–912.

### 8.3 Cible native

Le mode natif `SpatialTerrainMode` contient **ground, relief, ramp**. Les libellés de présentation n’imposent pas de nouvelles valeurs « chemin » ou « eau » à cette énumération.

- Les surfaces, les chemins et l’eau utilisent les structures natives prévues pour les surfaces et Paths.
- Les falaises, berges, parois et bordures utilisent Borders.
- Une pente conserve son orientation, ses niveaux d’entrée/sortie et sa relation aux surfaces.
- Un arbre entier utilise le système d’arbres/environnements ; il ne devient pas une paroi ou un fragment de terrain.
- Le preset visuel ne remplace pas la géométrie native.
- Le choix d’un outil doit utiliser une ressource compatible explicitement choisie ou proposer de la choisir. Aucun ancien preset caché ne doit être appliqué silencieusement.

La maquette ne démontre pas le maillage 3D, les normales, le raccord entre reliefs, la navigation réelle sur une pente ni le rendu d’une rive dans le moteur. Ces preuves appartiennent à la recette native.

<a id="9-environnements"></a>
## 9. Environnements et génération

### 9.1 Parcours

1. Choisir un preset d’environnement.
2. Définir densité et paramètres proposés.
3. Dessiner une zone.
4. Examiner la proposition.
5. Changer la variation si nécessaire.
6. Appliquer ou abandonner.
7. Sélectionner la zone appliquée pour modifier ses réglages.

**Captures :** 089–101, notamment densité minimale/maximale 089–090, proposition 091, seconde action refusée 092, variation 093, garde 094 et issues 095–097.

### 9.2 Transaction et changement de contexte

La proposition doit être clairement marquée « non appliquée ». Un deuxième geste ne doit pas faire disparaître la première proposition. Un changement de carte, d’espace ou de ressource avec une proposition en attente appelle la même garde :

| Choix | Effet |
| --- | --- |
| Rester | Conserver proposition et contexte |
| Abandonner | Retirer la proposition et continuer la navigation |
| Appliquer | Valider une fois, puis continuer si l’opération réussit |

**Cible native :** conserver la graine et les paramètres pour une génération reproductible ; définir si l’édition régénère la zone ou modifie des instances existantes ; vérifier les usages et les verrouillages. L’application d’une génération doit constituer une opération annulable cohérente.

Une zone verrouillée reste inspectable et refuse la modification. La capture 101 montre cet état. La démonstration graphique ne constitue pas une preuve de génération native ni de performance avec des milliers d’arbres.

<a id="10-contenu"></a>
## 10. Contenu, calques et actions communes

### 10.1 Contenu comme point d’entrée commun

Le bouton global Contenu ouvre la liste des éléments de la carte et les calques. La liste mélange des familles éditables, pas les pixels du fond. Recherche et filtre permettent de retrouver un objet masqué, petit ou superposé.

| Action | Responsabilité | Cas à protéger |
| --- | --- | --- |
| Sélectionner | Mettre en évidence la même identité dans la carte et l’inspecteur | Référence périmée |
| Propriétés | Ouvrir le bon inspecteur dans son espace | Élément non spatial |
| Localiser | Cadrer un élément spatial | Ne pas inventer une position à un événement global |
| Déplacer d’une case | Modifier les coordonnées via la commande canonique | Limites, extérieur, dépendances, verrouillage |
| Dupliquer | Copier avec de nouveaux identifiants et liens remappés | Copie hors limite, point de départ unique |
| Supprimer | Analyser les références puis confirmer | Point utilisé, décor porteur, départ du jeu |
| Masquer | Modifier la visibilité de travail | Ne pas désactiver le gameplay |
| Verrouiller | Protéger l’édition | Héritage du calque |
| Affecter un calque | Organiser l’édition | Sélection multiple compatible |

**Captures :** 100–119, 381–389. La capture 103 montre la partie basse de la liste ; ce n’est pas une vue de toutes les lignes simultanément.

### 10.2 Multi-sélection

Les cases de sélection sont explicites. « Tout sélectionner » concerne le résultat filtré affiché. La barre d’actions indique le nombre sélectionné. Les actions incompatibles sont désactivées ou expliquées.

**Cible native :** une action sur plusieurs éléments doit être atomique lorsque leur cohérence l’exige. Un refus ne doit pas produire une moitié de duplication, perdre la sélection ou déplacer seulement les objets faciles à traiter. Les dépendances entre éléments copiés sont remappées ensemble.

La capture 389 montre un inspecteur de sélection multiple qui renvoie vers Contenu. Elle ne doit pas être interprétée comme une fiche d’un des passages sélectionnés.

### 10.3 Calques

**Observé :** création d’un calque nommé, affectation, visibilité, verrouillage, ordre et retrait du calque sont illustrés dans 105–115. Le retrait conserve les éléments.

| État | Conséquence |
| --- | --- |
| Calque visible et déverrouillé | Éléments modifiables selon leur état propre |
| Calque masqué | Éléments masqués dans la vue de travail |
| Calque verrouillé | Verrouillage effectif des éléments |
| Élément verrouillé individuellement | Protection propre à l’élément |
| Tentative de déverrouillage sous calque verrouillé | Refus ou explication de la protection héritée |
| Retrait d’un calque | Réaffectation sans suppression des contenus |

Le fond de référence possède une visibilité distincte : 116. Réordonner un calque d’organisation ne doit pas devenir implicitement un changement de collision ou de priorité de comportement.

### 10.4 Suppressions et dépendances

La confirmation annonce l’objet et les conséquences réelles. Un point référencé par un passage est protégé ; un décor porteur d’interaction demande d’abord de traiter cette interaction ; le départ courant de nouvelle partie exige un remplacement.

Les captures 381–383 montrent la confirmation puis les refus correspondants. Un dialogue générique ne suffit pas à prouver que toutes les suppressions sont sûres : la validation doit être répétée au moment de l’application.

<a id="11-vue"></a>
## 11. Navigation, extérieur et caméra

### 11.1 Vue de travail

**Observé :** zoom, grille, déplacement de la vue, vue libre illustrative et repli de l’inspecteur sont accessibles : 117–123. La carte peut s’observer autrement sans modifier ses dimensions.

**Cible native :** zoom et pan appartiennent à la session d’édition. Les réglages de caméra du jeu appartiennent à la carte. L’un ne doit pas écrire dans l’autre.

### 11.2 Zone jouable et décor extérieur

Le décor extérieur permet d’habiller les alentours hors de la zone jouable. Des marges par direction peuvent être affichées et réglées.

| Cas | Attendu | Captures |
| --- | --- | --- |
| Activer la cible extérieur | Marges et indication du mode | 123–124 |
| Cliquer dans la zone jouable avec cible extérieur | Refus de la mauvaise appartenance | 125 |
| Poser dans une marge | Décor extérieur créé | 126 |
| Déplacer numériquement vers la zone opposée | Refus plutôt que conversion silencieuse | 127 |
| Réduire les marges en excluant un décor | Refus explicite | 128 |
| Marges asymétriques / panneau replié | Appartenance toujours lisible | 129–131 |
| Construire une surface hors de la cible autorisée | Refus | 132 |

La convention native d’appartenance et les bornes doivent être réutilisées. Le pourcentage interne de la maquette n’est pas un nouveau format de stockage.

### 11.3 Caméra du jeu

Les réglages exposent projection, cadrage et paramètres de caméra. Les captures 155–159 montrent écran large, 4:3, portrait, perspective, orthographique et valeurs limites.

**Cible native :** montrer un aperçu fidèle au provider actif ; garder les paramètres dans les contrats Avelune ; identifier les réglages indisponibles par profil. La transformation CSS de la maquette ne prouve pas une projection 3D native.

<a id="12-cartes"></a>
## 12. Gestion des cartes et réglages

### 12.1 Gestionnaire des cartes

| Opération | État illustré | Captures |
| --- | --- | --- |
| Parcourir | Extérieur, intérieur, plan schématique | 133–135 |
| Rechercher / filtrer par dossier | Résultat et contexte | 138–141 |
| Renommer / ranger | Identité et dossier | 138–139 |
| Créer | Nom, dossier, type, dimensions | 142–147 |
| Refuser un nom vide ou déjà utilisé | Message local | 143–144 |
| Refuser des dimensions invalides | Message explicite | 145–146 |
| Ouvrir une carte vide | Bibliothèque et Contenu vides | 147–149 |
| Dupliquer | Formulaire, conflit de nom, autre dossier | 150–152 |
| Supprimer une carte libre | Confirmation et résultat | 153–154 |
| Protéger une carte référencée / de départ | Références expliquées | 136–137 |

Le dossier est un rangement du projet, pas un chemin système choisi librement. Les dimensions 4–128 sont celles de cette maquette, pas une limite générale approuvée pour tous les profils natifs.

### 12.2 Duplication d’une carte

**Observé :** le formulaire annonce la copie des éléments locaux, terrains, rencontres et réglages. Les départs deviennent des arrivées simples ; les connexions de bord ne sont pas copiées ; les passages gardent leur destination et ne créent pas automatiquement de retour.

**Cible native :** mapper explicitement tous les identifiants locaux et leurs références internes. Réutiliser les définitions partagées. Valider le nouveau graphe sans modifier la carte source. Le formulaire de démonstration ne remplace pas un test de relecture/export de la copie.

### 12.3 Dimensions et zone jouable

Les dimensions de carte, la zone jouable et les marges extérieures sont des notions différentes. Le changement conserve l’origine de la carte et ne supprime aucun élément pour « faire rentrer » la nouvelle géométrie.

- Une dimension invalide est refusée : 161.
- Une réduction qui exclut du contenu est refusée : 162.
- Un agrandissement est montré : 163.
- Une zone jouable de géométrie invalide est refusée : 164.
- Une zone jouable qui exclut des objets est refusée : 165.
- Une réduction qui invalide une liaison voisine doit aussi être traitée ; la maquette présente encore L02.

### 12.4 Règles locales du lieu

Le type intérieur/extérieur, l’autorisation du vélo, l’association à un donjon et la Corde Sortie sont présentés dans 166–169. Les donjons d’exemple sont Antre Noir et Caves Jumelles.

Le profil de démonstration est 3D ; la Corde Sortie y reste désactivée. L’écran ne démontre pas son activation dans un profil 2D. Les règles d’usage doivent provenir des capacités et contrats réels du projet. Le changement de type de lieu doit recalculer ses effets explicites, notamment météo et déplacement, sans réinitialiser les autres réglages.

<a id="13-connexions"></a>
## 13. Jeu : connexions et passages

### 13.1 Deux objets distincts

| Objet | Intention | Données principales |
| --- | --- | --- |
| Carte voisine | Traverser le bord vers une carte adjacente | Carte cible, bord, décalage, portion commune, relation inverse |
| Passage | Utiliser une porte, un escalier ou une échelle | Position source, destination par point nommé, transition, retour éventuel |

Une liaison simple ne doit pas demander de scène. Un événement scénarisé peut entourer un déplacement, mais il ne remplace pas son objet géographique.

### 13.2 Connexions de bords

Parcours : Jeu → Connexions et passages → Ajouter une liaison → Carte voisine → choisir la carte → choisir Nord/Est/Sud/Ouest → ajuster le décalage → vérifier le bord commun.

**Observé :** la comparaison place les deux cartes à même échelle, affiche les dimensions et le décalage, et présente le retour automatique. Les captures 177–187 montrent incomplet, diagnostic bloquant, correction, orientations, décalage signé, édition inverse, conflit et retrait.

| Cas | Comportement attendu |
| --- | --- |
| Destination absente | Brouillon explicite, pas de liaison exploitable |
| Portion commune non vide | Évaluation des règles natives et affichage du recouvrement |
| Décalage changé depuis l’autre extrémité | Cohérence de la relation inverse et du signe |
| Suppression | Conséquences sur les deux extrémités annoncées |
| Redimensionnement d’une des cartes | Revalidation des portions affectées |
| Deux liaisons sur un bord | Validation selon profil et chevauchement |

**Différence native essentielle :** le prototype signale une deuxième destination sur un bord. Le natif distingue les profils : en 3D, plusieurs voisins sur un même bord ne sont pas supportés ; en 2D, plusieurs destinations peuvent être admises si les segments ne se chevauchent pas. La règle du prototype ne doit pas être généralisée au format natif.

Réutiliser les opérations de recouvrement existantes. Un bord sans case commune ne doit jamais rester annoncé comme valide après réduction : L02, captures 909–910.

### 13.3 Passage et destination

La fiche de passage comprend nom, type, destination, état du retour et transition. Les types montrés sont Porte, Escalier, Échelle ; la transition est instantanée ou en fondu. Le fondu de démonstration va de 100 à 2000 ms : 188–194.

Le sélecteur de destination présente :

1. Recherche de carte ou de dossier.
2. Carte cible avec aperçu.
3. Points d’arrivée nommés.
4. Possibilité de cliquer une case pour proposer une nouvelle arrivée.
5. Résumé du point et de l’orientation.
6. Bouton de confirmation.

**Captures :** 195–201. La sélection reste provisoire jusqu’à confirmation ; changer de carte sans point désactive la validation. Annuler ne doit créer aucun point orphelin.

### 13.4 Retour et suppression

Un passage peut rester à sens unique : c’est un avertissement informatif, pas automatiquement une erreur. « Créer le passage retour » crée le trajet inverse avec les mêmes points, sans inventer une autre arrivée : 202–203.

Un nouveau passage peut être placé sans destination puis complété : 204–205. La suppression indique que les points nommés et l’éventuel passage retour sont conservés : 206–207. Le graphe réel doit respecter ces conséquences, même après annulation/rétablissement.

<a id="14-deplacements"></a>
## 14. Jeu : déplacements

L’espace présente une grille de règles de passage indépendante de l’apparence du terrain.

| Règle de démonstration | Sens |
| --- | --- |
| Accessible à pied | Le joueur peut marcher sur la case |
| Passage bloqué | Mur ou obstacle infranchissable |
| Eau surfable | Déplacement sur l’eau nécessaire |
| Passage à sens unique | Franchissement directionnel ; exemple vers le sud |

**Captures :** 208–215 : aucune case, case sélectionnée, quatre règles, peinture, règle appliquée et effacement. La capture 217 montre le changement de carte avec sélection de case retirée.

En Sélection, cliquer inspecte la règle existante ; en Peindre, cliquer ou glisser applique la règle choisie ; Effacer rétablit la règle d’origine de l’exemple. La légende accompagne la surcouche pour éviter de dépendre uniquement des couleurs.

**Cible native :** conserver la distinction entre collision d’un décor, terrain, grille de passage et capacités du joueur. Le système runtime décide de la traversabilité à partir de leurs contrats existants. L’éditeur ne doit pas embarquer une seconde implémentation des règles de gameplay.

### Mécanismes avancés

La capture 216 présente des emplacements explicatifs pour surfaces glissantes, plateformes mobiles/ascenseurs et actions telles que Cascade, Tourbillon, Flash ou Plongée. Ce ne sont pas des outils opérationnels démontrés. La maquette indique aussi des différences de profil, notamment Flash/Plongée réservés au profil 2D dans cette proposition. La disponibilité native doit être interrogée, pas déduite de ce texte.

<a id="15-rencontres"></a>
## 15. Jeu : rencontres sauvages

### 15.1 Zone et table

La zone de rencontres appartient à la carte. La définition des espèces, niveaux et poids peut appartenir à une table du projet. La carte choisit une référence et ses conditions locales.

| Champ | Rôle |
| --- | --- |
| Nom | Repère d’édition |
| Déplacement | À pied, Surf, Pêche dans l’exemple |
| Horaire | Tout le temps, Jour, Nuit dans l’exemple |
| Fréquence | Probabilité d’activation ; démonstration 1–100 % |
| Table | Répartition locale existante ou table du projet |
| Aperçu de table | Espèces, niveaux et répartition en lecture |
| Emprise | Rectangle sur la carte |
| Active | Activation de la zone |

Les captures 218–230 couvrent les variantes. Les tables d’exemple incluent Route 29 journée, Route 29 nuit et Johto eau douce. La capture 222 explique le propriétaire de leur définition.

Choisir une table de nuit ne doit pas être confondu avec le choix de l’horaire « Nuit » : l’un sélectionne des données, l’autre leur applicabilité. L’interface native doit rendre ce couple explicite.

### 15.2 Création, redessin et suppression

- Dessiner une zone : outil armé puis emprise.
- Redessiner : remplacer l’emprise de la zone sélectionnée, sans créer une deuxième zone.
- Nouvelle zone incomplète : rester inactive tant que sa configuration n’est pas validée.
- Supprimer : confirmation ciblée, sans supprimer la table partagée.

**Captures :** 231–235 et 392 pour le verrouillage.

Le prototype ne démontre pas le tirage d’une rencontre, le démarrage d’un combat ou l’édition complète d’une table. Ces comportements doivent être validés dans leurs modules propriétaires et dans le runtime.

<a id="16-points"></a>
## 16. Jeu : départs, arrivées et utilitaires

### 16.1 Trois rôles de point

| Rôle | Portée | Conséquence |
| --- | --- | --- |
| Point d’arrivée | Repère nommé utilisé par les passages | Déplacement partagé avec ses consommateurs |
| Point de test | Choix de préparation d’une session de test | Ne change pas le départ d’une nouvelle partie |
| Départ nouvelle partie | Départ unique du projet | Remplacement explicite et protégé |

La position se lit en cases, avec orientation Nord/Est/Sud/Ouest. Les captures 236–249 couvrent les quatre directions, le point choisi pour test, le remplacement du départ, une case de test bloquée, la création et la suppression d’un point libre.

Un point utilisé affiche ses consommateurs et ne peut pas disparaître sans traiter les références. Une modification de sa position modifie la destination de tous les passages qui le référencent. **Cible native :** les verrouillages des dépendances doivent être pris en compte, y compris depuis son inspecteur : L01.

Déplacer le départ du projet ne doit pas modifier arbitrairement une sauvegarde de progression existante. Le démarrage d’une nouvelle partie, la préparation d’un test et la reprise d’une partie sont trois opérations distinctes.

### 16.2 Objets utilitaires

| Type montré | Fonction de jeu | Particularité |
| --- | --- | --- |
| Arbre à couper | Obstacle franchissable avec Coupe | Apparence choisie séparément |
| Rocher à pousser | Obstacle déplaçable avec Force | Politique de conservation de l’état |
| Rocher à briser | Obstacle destructible avec Éclate-Roc | Résolution côté gameplay |
| Bloc de glace | Bloc déplaçable | Réinitialisation à chaque visite dans l’exemple |
| Boules de soin | Affichage de l’équipe lors des soins | Capacité d’affichage ; ne déclenche pas seul les soins |

**Captures :** 250–261. Les données comprennent nom d’édition, fonction, apparence du projet, coordonnées, politique après sortie de carte et collision. La capacité minimale d’affichage est montrée dans 259 ; le verrouillage dans 260.

Le changement de fonction ne renomme pas nécessairement l’objet : un élément appelé « Arbre à couper » peut être transformé en rocher dans la capture. Le nom reste un nom d’éditeur ; la fonction doit être lisible indépendamment pour éviter une interprétation erronée.

**Cible native :** réutiliser les définitions et contrats de field actions. L’apparence du socle de soin ne porte ni le dialogue ni la logique de soin, qui restent dans leur comportement ou scène.

<a id="17-scenario"></a>
## 17. Scénario : éléments, comportements et références

### 17.1 Frontière avec Scènes

Le constructeur répond à : **« Quand cet élément doit-il déclencher quelle scène existante ? »**

L’espace Scènes répond à : **« Quelles actions, dialogues, déplacements et conséquences composent cette scène ? »**

Le constructeur ne doit pas dupliquer un éditeur de dialogue, de combat, de conditions de scène ou de récompenses. Le sélecteur associe une référence. Retirer cette association ne supprime pas la scène du projet. L’aide de la capture 263 formule cette séparation.

### 17.2 Navigation et états

La liste distingue Personnages, Objets interactifs, Zones et Carte/résultats. Elle propose portée carte/projet, recherche et filtre « À configurer ».

| État | Captures |
| --- | --- |
| Aucun élément sélectionné | 262 |
| Portée projet et carte propriétaire | 264 |
| Filtres personnages, objets, zones, événements, à configurer, tous | 265–270 |
| Recherche avec résultat / vide | 271–272 |
| Carte sans scénario | 318 |
| Menu Ajouter | 319 |
| Créations et brouillons | 320–327 |

Un événement global n’a pas de position. Son ouverture peut conserver une vue de carte de travail, mais l’inspecteur doit indiquer sa portée et ne pas lui attribuer de coordonnées. Les captures 306–311 et 104 illustrent cette distinction.

### 17.3 Élément et comportements

Un élément possède ses propriétés, son activation et plusieurs comportements. Chaque comportement possède un nom, un déclencheur, une condition, une référence de scène, une politique de répétition et un état d’activation.

| Partie | Question | Exemple |
| --- | --- | --- |
| Quand | Quel événement déclenche l’évaluation ? | Le joueur interagit |
| Si | Quelle condition doit être vraie ? | Starter reçu |
| Alors | Quelle scène existante déclencher ? | Prêt pour l’aventure |
| Après le déclenchement | Quelle répétition autoriser ? | Une seule fois |
| Actif | Ce comportement peut-il participer ? | Actif si complet |

Les déclencheurs dépendent du type d’élément : interaction/contact/automatique pour un personnage, entrée de zone, entrée de carte ou résultat reçu pour les éléments correspondants. Les captures 273–280, 306–313 montrent ces variantes.

Les trois conditions proposées par cette maquette sont **Toujours, Starter non reçu, Starter reçu**. Elles illustrent le principe mais ne couvrent pas les conditions réelles d’un fangame. L04 précise le complément nécessaire.

Les politiques de répétition montrées sont **Une seule fois, À chaque interaction, Une fois par visite**. Leur sémantique runtime, leur clé de persistance et leur interaction avec les conditions doivent être reprises des contrats natifs. Aucune progression n’est exécutée par l’aperçu.

### 17.4 Brouillon, prêt, actif et sélectionné

Ces quatre notions ne doivent jamais être confondues :

- **Brouillon :** une scène ou une autre référence requise manque.
- **Prêt :** références requises valides.
- **Actif :** prêt et activation autorisée.
- **Sélectionné :** comportement actuellement inspecté, même s’il est inactif.

Un comportement incomplet reste désactivé, avec une aide pour compléter sa référence. Un comportement prêt peut rester volontairement inactif. L’activation de l’élément entier domine l’activation de ses comportements.

Les captures 284–289 montrent retrait d’association, nouveau comportement, état prêt/inactif, activation et réorganisation. La suppression du dernier comportement ramène à l’appel « Configurer le comportement » : 322. Un nouvel élément n’exécute aucune action par défaut.

### 17.5 Sélecteur de scène existante

Le dialogue annonce l’élément et le comportement concernés, recherche dans le catalogue, montre la scène associée et permet de retirer uniquement l’association.

**Captures :** 281–286 : état initial, résultat de recherche, vide, association retirée et choix sans association. L’édition/création du contenu de la scène est renvoyée à l’espace Scènes.

**Cible native :** conserver l’identité de référence ; afficher les références cassées ; ne pas associer une scène périmée après un rafraîchissement asynchrone. Une suppression de scène depuis son module doit produire un diagnostic sur ses consommateurs.

### 17.6 Aperçu des conditions

L’aperçu fournit un état fictif du joueur et évalue les conditions. Il ne lance pas de scène. Les captures 290–294 montrent une correspondance, plusieurs correspondances, un élément désactivé, aucune correspondance et un comportement inspecté faux alors qu’un autre convient.

**Cible native :** la règle de priorité, d’exclusivité ou d’enchaînement des comportements vient de l’autorité d’exécution existante. L’ordre visuel n’autorise pas à inventer une autre résolution. Plusieurs correspondances doivent être expliquées selon cette règle et testées dans le moteur.

### 17.7 Propriétés de personnage

**Observé :** nom, position, apparence du projet, orientation initiale, collision, déplacement autonome et définition de dresseur. Les variantes de déplacement sont immobile, aléatoire avec rayon, parcours fixe avec étapes et attentes.

**Captures :** 295–305. Les captures 298–302 distinguent parcours vide, dérive répétée, sortie dès la première étape, parcours valable et attente.

La validation d’un parcours répété doit examiner son effet sur plusieurs cycles. Un seul tour contenu dans la carte ne suffit pas si chaque répétition décale le personnage vers le bord. La maquette affiche ces diagnostics mais ne fait pas marcher le PNJ.

Associer « Gamin · Jules » est une référence à une définition du projet : équipe, récompenses et règles sont éditées dans les données du projet. Cette association ne crée pas automatiquement un combat ; le déclencheur et la scène restent explicites.

### 17.8 Objets, zones, entrée de carte et résultats

- **Objet indépendant :** repère d’interaction positionné sans créer un deuxième décor visible.
- **Objet porté par un décor :** référence à l’instance ; position gérée en Construction.
- **Zone :** origine et dimensions explicites ; les conditions et scènes restent dans Comportement.
- **Entrée de carte :** événement local sans besoin d’un personnage.
- **Résultat global :** écoute d’une référence de résultat du projet ; aucune position à dessiner.

**Captures :** 306–317 et 323–327. Les résultats d’exemple comprennent victoire, défaite et Starter reçu. Une référence de résultat manquante rend le comportement brouillon : 310.

**Limite :** le résultat global fourni en exemple est modifiable, mais le menu Ajouter ne permet pas de créer normalement un nouvel écouteur global. L05 doit être résolue avant de considérer ce parcours complet.

<a id="18-ambiance"></a>
## 18. Ambiance : temps, météo, effets et musique

### 18.1 Configuration permanente et aperçu

La colonne gauche contient Jour et nuit, Météo, Effets visuels et Musique. L’inspecteur expose les réglages enregistrés. Le canevas propose une heure d’aperçu indépendante et un bouton « Voir la capture d’origine ».

| État | Effet |
| --- | --- |
| Modifier un réglage local | Change la configuration de la carte |
| Revenir à l’héritage | Supprime la surcharge locale du paramètre |
| Déplacer l’heure d’aperçu | Change seulement la visualisation |
| Voir la capture d’origine | Désactive les surcouches d’aperçu |
| Changer temporairement l’ambiance dans une scène | Relève de l’exécution de cette scène |

**Captures :** 328–344. La capture 342 montre une heure fixe enregistrée à 14:36 avec un aperçu à 06:00, preuve visuelle de la distinction.

### 18.2 Temps

| Source | Réglages |
| --- | --- |
| Cycle du projet | Paramètres hérités, indication de provenance |
| Cycle propre à cette carte | Durée d’une journée et heure de départ |
| Heure fixe sur cette carte | Heure enregistrée sans progression du cycle |

Le projet de démonstration indique une journée de 24 minutes et un départ à 08:00. Ce sont des valeurs de fixture.

Les périodes de la maquette sont : Aube 06:00–09:00 ; Jour 09:00–17:00 ; Soir 17:00–21:00 ; Nuit 21:00–06:00. Les boutons d’aperçu utilisent 06:00, 12:00, 18:30 et 22:00. Le curseur couvre la journée par pas de quinze minutes ; la capture de borne supérieure montre 23:45.

**Cible native :** l’horloge de simulation et l’horloge d’histoire appartiennent au host. Les horaires des PNJ et les conditions de rencontres restent dans leurs espaces. L’aperçu ne doit jamais avancer la progression de jeu.

### 18.3 Météo

| Source | Comportement |
| --- | --- |
| Suivre la météo du projet | Héritage explicite |
| Personnaliser cette carte | Type et intensité locaux |
| Toujours un ciel dégagé | Choix local explicite, même si le projet change |

Types : Ciel dégagé, Nuages, Pluie, Orage, Neige, Brouillard. Les captures 345–350 les montrent. L’intensité 0–100 % et le drapeau de sons météo sont illustrés dans 351–352.

Un intérieur est protégé par défaut. La capture 353 montre une pluie configurée mais non appliquée dans l’intérieur ; 354 montre l’autorisation explicite de météo intérieure.

L’intensité n’apparaît pas de la même façon pour chaque type. Le drapeau de son est un réglage d’interface : aucun son n’est joué dans la maquette.

### 18.4 Effets visuels et sources

Les six effets montrés sont Halos lumineux, Fenêtres éclairées, Lucioles le soir, Eau animée, Brume en profondeur et Profondeur de champ.

Chaque effet peut présenter source Projet/Carte, activation, intensité et sources associées. Les captures 355–370 couvrent fiches ouvertes, absence de source, héritage, personnalisation, activation, désactivation, intensité et repère sélectionné.

**Différence fondamentale :** la provenance d’un réglage n’est pas l’identité d’une source spatiale. « Suivre le projet » ne veut pas dire qu’un lampadaire global existe sur toutes les cartes.

**Limite connue :** les sources affichées sont des exemples statiques. Une carte vide peut afficher « Lampadaire de la place ». Aucun parcours réel d’ajout/changement/retrait de source n’est démontré : L06 et capture 907.

**Cible native :** les sources proviennent d’objets/ancres réels de la carte ; un clic localise la bonne identité ; une suppression est propagée ; une source verrouillée est protégée ; l’absence de source ne crée pas un repère fictif. L’association et le réglage d’effet doivent garder des responsabilités claires.

### 18.5 Musique

Les choix d’exemple sont Silence, Bourg Geon, Maison du joueur. Le volume de carte est illustré à 0 et 100 % : 371–375.

La musique de carte est distincte des sons météo et de la musique de combat. Les ressources audio restent dans le catalogue du projet. **Non démontré :** lecture audio, boucle, fondu entre cartes, gestion des interruptions, export offline ou présence des fichiers dans le Player. Ces preuves nécessitent le système audio natif.

<a id="19-session"></a>
## 19. Historique, enregistrement et test

### 19.1 Historique commun

Les captures 170–171 illustrent Annuler et Rétablir ; 172 montre un état enregistré de session. Ces commandes sont communes aux espaces.

**Cible native :**

- Une action utilisateur cohérente produit une entrée d’historique.
- Un trait ne produit pas une entrée par point de souris.
- Une liaison modifiée conserve la cohérence de ses deux extrémités à chaque annulation.
- Une copie de graphe remappe ses identifiants à l’application et au rétablissement.
- Une commande refusée n’ajoute pas une entrée vide.
- Un changement de sélection ou d’aperçu ne marque pas les données comme modifiées.
- Une annulation après changement de carte reste attribuable à la bonne carte.

### 19.2 Enregistrement

Le bouton Enregistrer de la maquette conserve les modifications pendant la session de prévisualisation ; il ne prouve pas une écriture durable sur disque ni une publication du projet.

La réalisation native doit distinguer Enregistré, Modification en cours, Enregistrement en cours et Échec. Un échec conserve les données et offre une reprise. La cible de feedback est 100 ms et celle de sauvegarde durable 500 ms pour une modification locale, à mesurer ; aucun chiffre de performance n’est validé par ces captures.

### 19.3 Préparation du test

Le bouton global Tester la carte ouvre le choix d’un point de départ et les diagnostics de la carte concernée. Le choix de test ne remplace pas le départ d’une nouvelle partie.

| État | Effet | Captures |
| --- | --- | --- |
| Connexion incomplète | Blocage et lien Corriger | 178–179 |
| Case de départ bloquée | Refus de prévisualiser | 244 |
| Avertissement de sens unique | Prévisualisation permise | 380, 393 |
| Aucun problème détecté dans les fixtures | Prévisualisation permise | 377 |
| Aperçu du départ | Image et repère ; pas de moteur | 378 |
| Retour à la préparation / à la carte | Contexte lisible | 379 |

Les diagnostics de la maquette sont partiels. Les contrôles du jeu réel doivent venir des validateurs canoniques. Le résultat vert ne couvre pas tous les points de destination : L01.

### 19.4 Niveaux de recette

| Niveau | Ce qu’il prouve |
| --- | --- |
| Capture de maquette | Présentation d’un état |
| Interaction de maquette / lecture du code figé | Branche de démonstration |
| Test de commande native | Mutation et refus sur des données réelles |
| Test de relecture | Écriture et restitution des mêmes données |
| Parcours Studio natif | Usage réel de l’interface |
| Export puis Player | Consommation du contrat par le moteur |
| Validation visuelle et performance | Résultat rendu et coût sur une cible définie |

Aucun niveau n’est remplacé par le précédent. Une compilation verte ne prouve pas un passage utilisable.

<a id="20-transversal"></a>
## 20. États transversaux et accessibilité

### 20.1 États à conserver dans chaque famille

| Situation | Réponse attendue |
| --- | --- |
| Rien de sélectionné | Aide courte et action de départ |
| Recherche vide | Liste complète selon filtres |
| Aucun résultat | Message, filtres visibles, remise à zéro |
| Carte sans contenu | Invitation adaptée ; pas de faux objets |
| Référence manquante | Identité du problème, brouillon ou diagnostic |
| Verrouillage propre | Lecture possible, mutations protégées |
| Verrouillage du calque | Origine de la protection affichée |
| Élément hors limites | Refus avec cause et correction |
| Plusieurs éléments | Actions communes et nombre sélectionné |
| Confirmation | Objet, portée et conséquences |
| Opération en attente | État explicite et possibilité de sortir proprement |
| Échec de sauvegarde/chargement | Conservation, diagnostic et reprise |
| Capacité indisponible | Explication liée au profil, sans faux contrôle actif |

Les deux dernières lignes n’ont pas de simulation complète dans les fixtures statiques. Elles font partie des critères natifs, pas des captures promises comme acquises.

### 20.2 Clavier et focus

L’accès de recherche est illustré par Cmd+K depuis Jeu : 401. Échap permet de quitter plusieurs gestes de création. Les raccourcis natifs devront utiliser les bindings existants et respecter la plateforme.

**Critères natifs :** les flèches ne déplacent pas un élément lorsque le focus est dans un champ ; Supprimer n’agit pas derrière un dialogue ; Annuler/Rétablir respecte l’édition de texte ; la fermeture d’un dialogue rend le focus à son déclencheur ; les libellés accessibles distinguent les champs de même nom ; les erreurs sont annoncées ; la sélection n’est pas uniquement indiquée par couleur.

### 20.3 Fenêtre compacte

Les captures 394–398 utilisent un viewport compact de 1000 × 800 pour examiner les quatre espaces et l’inspecteur de Construction ouvert/replié. Les fichiers de capture peuvent inclure une marge blanche extérieure à la zone de page ; les dimensions de fichier figurent dans le manifeste.

Ces vues montrent une adaptation de présentation, pas une recette exhaustive du responsive. La livraison native doit assurer une largeur minimale documentée, des zones de défilement indépendantes et des actions toujours accessibles. La cible principale reste l’édition desktop ; aucune interface mobile complète n’est déduite de ces cinq captures.

<a id="21-limites"></a>
## 21. Limites connues et corrections à réaliser

Ces neuf groupes viennent de la dernière passe de complétude. **Ils restent ouverts dans la révision figée.** Leur conservation dans ce dossier est volontaire ; ils ne sont pas réparés par la documentation.

### L01 — Validation spatiale et verrouillages incohérents

**Constat :** sur une carte de 8 × 8 dont la zone jouable est en 2,2 avec dimensions 4 × 4, une zone Scénario et un point de Jeu peuvent être créés en 0,0. Une modification de point depuis son inspecteur peut aussi déplacer un point consommé par un passage verrouillé. Les diagnostics de départ ne couvrent pas toutes les arrivées.

**Preuves :** 903, 905, 908 ; le cas de passage verrouillé dépendant a été confirmé par interaction DOM lors de l’audit, sans capture dédiée du delta numérique.

**Réparation attendue :** appliquer le même validateur aux gestes, champs, déplacements, duplications et commandes ; inclure les dépendances de point ; revalider les arrivées concernées.

**Sortie :** tout chemin d’entrée refuse la même mutation sans changement partiel ; un point valide reste déplaçable ; les arrivées hors zone sont signalées.

### L02 — Redimensionnement qui invalide un voisin sans diagnostic

**Constat :** une connexion avec une seule case commune sur carte 8 × 8 et décalage 7 perd son recouvrement lors du passage en 4 × 4 ; son état reste vert.

**Preuves :** 909 avant, 910 après.

**Réparation attendue :** utiliser l’analyse native des dépendances de redimensionnement et les calculs de recouvrement ; refuser ou présenter une résolution explicite ; mettre à jour les deux extrémités et les diagnostics.

**Sortie :** aucun état « valide » avec zéro case commune ; Annuler restaure dimensions et graphe.

### L03 — Échelle des cases et bords de terrain incohérents

**Constat :** grille visuelle fixe de 16 × 16 sur une carte 32 × 24 ; largeur de trait exprimée par pourcentage fixe ; rectangle de largeur 32 tronqué à 31.

**Preuves :** 901–902.

**Réparation attendue :** une transformation unique carte ↔ canevas ; séparer indices de cellule et coordonnées des bords ; calculer les tailles à partir des dimensions réelles.

**Sortie :** une case est une case à tous les zooms, les quatre bords sont atteignables, les formes couvrent leur largeur annoncée sur cartes carrées et non carrées.

### L04 — Conditions limitées au Starter

**Constat :** trois choix figés ne permettent pas d’exprimer les conditions réelles du projet.

**Preuve :** 906 et 277–278.

**Réparation attendue :** consommer les formulaires et références de conditions natives, avec leurs capacités et diagnostics ; conserver un premier niveau simple ; utiliser le même évaluateur pour l’aperçu et l’exécution.

**Sortie :** au moins les conditions requises par les parcours réels du projet sont sélectionnables, sérialisées et exécutées ; aucune liste fictive ni second évaluateur divergent.

### L05 — Création d’écouteur global absente

**Constat :** le résultat global de fixture est éditable, mais Ajouter ne propose que personnage, objet, zone et entrée de carte.

**Preuves :** 904 et 319, comparées à 306–311.

**Réparation attendue :** fournir une entrée dans le module natif propriétaire des événements/résultats et un accès clair depuis le constructeur ; éviter une deuxième définition concurrente.

**Sortie :** un utilisateur partant d’un projet sans fixture peut créer, associer, retrouver et supprimer proprement un écouteur.

### L06 — Sources d’ambiance fictives

**Constat :** une carte vide peut afficher une source de lampadaire ; ajout/changement/retrait d’association absent.

**Preuve :** 907 ; 356 montre le contraste d’un état sans source en intérieur.

**Réparation attendue :** dériver les sources des vrais objets/ancres de carte et fournir leur gestion ; préserver la distinction source du réglage/source spatiale.

**Sortie :** carte vide sans fausse source ; création, localisation, changement, suppression et undo cohérents.

### L07 — Famille Eau avec outil de relief terrestre implicite

**Constat :** depuis Eau sans sélection explicite de ressource, Sculpter active un preset de falaise terreuse et de chemin de terre.

**Preuves :** 911–912.

**Réparation attendue :** valider l’intention active lors du changement de famille/outil ; demander une ressource compatible ou garder une sélection explicite clairement affichée.

**Sortie :** aucune création avec preset invisible hérité d’une autre famille ; retour à Sélection prévisible.

### L08 — Déplacement direct d’un décor absent

**Constat :** glisser un décor ne le déplace pas ; champs numériques et actions de Contenu restent disponibles.

**Preuve :** 913 et interaction de l’audit.

**Réparation attendue :** utiliser le geste natif de transformation existant, avec seuil de départ, aperçu, validation et transaction unique ; arbitrer correctement le pan de vue.

**Sortie :** clic sélectionne, glisser déplace, Échap annule, verrouillage et limites sont identiques aux champs ; undo unique.

### L09 — Duplication refusée silencieusement au bord

**Constat :** dupliquer un point en 31,23 ne crée pas de copie, ne montre pas d’erreur et efface la sélection dans le cas audité.

**Preuve :** interaction DOM de l’audit ; aucune capture dédiée du changement de sélection.

**Réparation attendue :** prévalider le décalage de copie ; proposer un placement valide ou expliquer le refus ; préserver la sélection et les données.

**Sortie :** duplication au centre réussie ; duplication impossible au bord refusée avec message ; aucune copie partielle ni perte de sélection.

### Priorité de reprise

Traiter L01/L02/L03/L07/L09 avec les commandes et la sélection, car ils conditionnent la fiabilité. L08 s’appuie sur ces garanties. L04/L05/L06 complètent les parcours métier. Cette priorité ne modifie pas les statuts du plan natif existant.

<a id="22-native"></a>
## 22. Traduction vers l’architecture native

### 22.1 Frontières à préserver

| Couche | Responsabilité |
| --- | --- |
| map_core | Contrats, modèles, codecs, validation partagée ; Dart pur |
| map_gameplay | Décisions pures d’overworld |
| map_battle | Mécaniques de combat |
| map_authoring | Actions canoniques d’édition, dépendances et mutations |
| map_editor et application Studio | Cas d’usage et présentation, organisation de l’édition |
| map_runtime | Intégration Flutter/Flame et consommation des données |
| Host | Horloges, session de simulation, orchestration |

Les types TypeScript de la maquette ne sont pas un schéma à copier dans les modèles Dart. Ils expriment des besoins d’interface avec des fixtures. Les nouvelles vues doivent adapter les commandes existantes, réutiliser le design system et ses tokens, et maintenir les barrels publics lorsqu’une API exportée change.

### 22.2 Points d’entrée vérifiés à consulter

Les chemins ci-dessous sont relatifs à la racine du dépôt. Ils sont des points de départ, pas une liste de fichiers à réécrire.

| Sujet | Présentation / application Studio | Autorité native / contrats |
| --- | --- | --- |
| Intention et barre d’outils | map_workspace_view_state.dart ; map_palette_intent.dart ; map_workspace_tool_strip.dart ; map_workspace_tool_strip_selection.dart | Commandes d’édition existantes |
| Palette et filtres | map_workspace_palette_dock.dart ; map_workspace_palette_dock_filters.dart ; workspace_scoped_catalog_binding.dart | map_workspace_catalog_commands.dart ; map_element_catalog.dart |
| Sélection | map_selection_context.dart ; map_selection_inspector.dart ; map_multi_selection_inspector.dart | map_entity_editing_commands.dart |
| Clavier et commandes | workspace_keyboard_binding.dart ; workspace_command_binding.dart | Mutation canonique |
| Terrain | map_terrain_tool_panel.dart ; map_terrain_inspector.dart ; spatial_terrain_controls.dart ; spatial_terrain_surface_editor.dart | spatial_terrain_stroke.dart ; spatial_terrain_surface_editing_commands.dart ; spatial_ramp_editing_commands.dart |
| Borders | map_terrain_patterns.dart ; map_terrain_highlight.dart | map_border_editing_commands.dart ; map_border_drawing_draft.dart |
| Environnement | workspace_environment_binding.dart ; map_environment_tool_panel.dart ; spatial_environment_gesture.dart | environment_editing_commands.dart ; environment_actions.dart |
| Connexions | workspace_connection_binding.dart ; map_connection_panel.dart | warp_connection_actions.dart ; world_graph_queries.dart ; map_resize_dependencies.dart |
| Passage | map_warp_inspector.dart ; map_warp_palette.dart ; map_warp_transition_editor.dart | warp_connection_actions.dart ; map_connections.dart |
| Points et zones | map_marker_inspector.dart ; map_zone_inspector.dart ; map_trigger_inspector.dart | entity_actions.dart |
| Déplacements | map_canvas_collision_paint.dart | Règles et opérations de déplacement existantes |
| Rencontres | map_encounter_mode_picker.dart ; map_encounter_cell_stroke.dart ; map_painted_encounter_overlay.dart | Tables et commandes de zones existantes |
| Réglages et ambiance | map_settings_inspector.dart ; map_ambiance_panel.dart ; map_atmosphere_settings_panel.dart | spatial_visual_profile.dart et patches natifs |
| Utilitaires | field_obstacle / healing inspectors existants | Contrats et field actions existants |
| Scénario | Modules narrative, facts et scene existants | narrative_event_definition.dart et opérations associées |

Les fichiers de présentation de la colonne centrale se trouvent principalement dans :

- `apps/avelune_studio/lib/presentation/features/map_workspace/`
- `apps/avelune_studio/lib/features/map_workspace/application/`

Les actions de carte se trouvent dans :

- `packages/map_authoring/lib/src/domains/maps/`
- `packages/map_authoring/lib/src/api/local_map_authoring_mutation_api.dart`

Les contrats partagés cités se trouvent notamment dans :

- `packages/map_core/lib/src/models/spatial_visual_profile.dart`
- `packages/map_core/lib/src/models/narrative_event_definition.dart`
- `packages/map_core/lib/src/operations/map_connections.dart`

### 22.3 Correspondance de concepts

| Présentation de la maquette | Traduction native attendue |
| --- | --- |
| Quatre espaces | Organisation des vues ; pas remplacement automatique des enums de commandes |
| Bibliothèque carte/projet | Catalogue et usages réels, avec préparation et chargement incrémental |
| Surface / Relief / Pente | ground / relief / ramp de SpatialTerrainMode |
| Chemin / Eau | Rôles de ressource, surface ou preset compatibles |
| Falaise / rive / paroi | Borders natifs |
| Environnement d’arbres | Système natif de génération et d’instances |
| Réglage hérité | Patch absent ; retour par SpatialVisualPatch.set(parameter, null) |
| Scène associée | Référence de scène existante |
| Table de rencontres | Référence de table existante |
| Définition de dresseur | Référence de données existante |
| Pourcentages de position de fixture | Conversion de démonstration uniquement ; conserver les coordonnées natives |
| Contenu | Vue commune des identités ; aucune duplication des objets métier |

### 22.4 Compatibilité, performance et parité

Les projets, cartes et jeux exportés depuis Studio 0.3.31+331 restent lisibles et jouables. Un changement de format ou de comportement persisté doit fournir une lecture compatible ou conversion déterministe testée, sans écraser l’original sur échec.

La compatibilité historique des sauvegardes de progression est suspendue pendant la phase de développement décidée le 8 novembre. Cela ne retire pas les garanties sur les projets et exports, ni l’exigence de sauvegarde/reprise fiable du format courant. Une sauvegarde non supportée est signalée sans suppression ni remplacement automatique.

Une modification locale doit coûter un travail borné par ses données et dépendances. Éviter chargement intégral, validation globale et reconstruction du projet à chaque geste. Les objectifs 100 ms/500 ms se mesurent sur un scénario représentatif.

**MCP parity de cette livraison documentaire : N/A.** Lors de la réalisation, toute modification d’action canonique map_authoring, de contrat projet ou de commande éditeur doit être reflétée dans le MCP selon le skill du dépôt.

<a id="23-lots"></a>
## 23. Lots de réalisation et critères de sortie

Ces lots sont un découpage documentaire. Ils ne sont pas déclarés exécutés. Avant chaque lot, confronter son périmètre aux travaux natifs déjà présents et au plan existant. Un lot déjà couvert nécessite seulement la vérification de son écart.

### D01 — Contrat d’intention et de sélection

**Correspondance :** UX-04, UX-07. **Dépendance :** aucune. **Anomalie :** L07.

Conserver les commandes existantes et établir la correspondance entre espace, famille, ressource, outil, sélection et brouillon. Un même état alimente barre d’outils, bibliothèque, canevas et inspecteur.

**Sortie :** changer de famille n’active aucun preset caché ; changer de carte retire les références incompatibles ; Échap annule le geste ; multi-sélection explicite ; test de non-régression d’une sélection existante.

### D02 — Validation spatiale et dépendances communes

**Correspondance :** UX-07, UX-10, UX-25. **Dépendance :** D01. **Anomalies :** L01, L02, L03, L09.

Réutiliser les validateurs natifs pour géométrie, limites, extérieur, verrouillages et consommateurs. Séparer bords et cellules. Prévalider les opérations de groupe et le redimensionnement.

**Sortie :** mêmes refus par geste/champ/clavier/MCP ; carte 32 × 24 correctement couverte ; point lié à passage verrouillé protégé ; redimensionnement sans recouvrement refusé ou résolu ; duplication au bord explicite et atomique.

### D03 — Bibliothèque complète et recherche

**Correspondance :** UX-05, UX-11. **Dépendance :** D01.

Brancher les portées sur catalogue et usages réels. Préserver les filtres visibles, les résultats vides et l’ouverture vers le catalogue complet. Traiter chargement et références manquantes.

**Sortie :** poser une éolienne non encore employée ; la retrouver dans les usages ; ne pas charger tout le projet par frappe ; rafraîchissement sans résultat périmé.

### D04 — Contenu et calques

**Correspondance :** UX-06, UX-07, UX-13. **Dépendances :** D01–D02.

Centraliser les actions, préserver l’identité et les relations lors des copies, rendre les verrouillages effectifs.

**Sortie :** déplacement groupé atomique ; duplication décor+interaction remappée ; retrait de calque conserve les éléments ; suppression de point/décor dépendant refusée ; recherche d’élément masqué possible.

### D05 — Décors et manipulation directe

**Correspondance :** UX-08. **Dépendances :** D02–D04. **Anomalie :** L08.

Réutiliser le geste natif de transformation et les paramètres d’instance. Définir sélection, seuil de drag, pan, preview et annulation.

**Sortie :** cliquer sélectionne sans déplacer ; glisser déplace avec un undo ; limites et verrouillages identiques aux champs ; extérieur conservé ; liaison Scénario suit l’instance.

### D06 — Surfaces, chemins, eau, reliefs et pentes

**Correspondance :** UX-09. **Dépendances :** D02–D03.

Brancher les familles et aperçus aux outils natifs ground/relief/ramp, surfaces et Borders. Conserver la distinction visuelle sommet/paroi.

**Sortie :** sol, chemin, eau, relief et pente créés comme données natives éditables ; bords accessibles ; raccords vérifiés au rendu ; navigation sur pente testée ; une modification ne reconstruit que ses dépendances.

### D07 — Environnements et propositions

**Correspondance :** UX-08. **Dépendances :** D02–D03.

Brancher le preview sur la génération native, avec graine, garde et transaction.

**Sortie :** rester/abandonner/appliquer respectent la proposition ; changer de carte ne fuit pas de données ; undo restaure la zone ; verrouillage effectif ; coût représentatif mesuré.

### D08 — Cartes, géométrie, caméra et règles locales

**Correspondance :** UX-14, UX-16, UX-17. **Dépendances :** D02.

Réutiliser gestionnaire de catalogue, préparation, dépendances de resize et préférences. Maintenir caméra d’édition/caméra de jeu et profil.

**Sortie :** création, renommage, rangement et copie relisibles ; réduction protège contenus et voisins ; suppression référencée sûre ; réglages par capacité ; reprise après échec sans perte.

### D09 — Connexions, passages et points

**Correspondance :** UX-10. **Dépendances :** D02, D08.

Brancher la comparaison à géométrie native, le dialogue aux vrais points et les retours au graphe partagé. Respecter la différence 2D/3D des voisins.

**Sortie :** liaison réciproque cohérente ; destination provisoire annulable ; point créé une fois à confirmation ; passage à sens unique assumé ; retour correct ; export puis traversée Player vérifiés.

### D10 — Déplacements, rencontres et utilitaires

**Correspondance :** UX-10, UX-23.5, UX-23.8. **Dépendances :** D02–D03.

Réutiliser grille, tables et field actions. Distinguer apparence et fonction.

**Sortie :** peinture persistée et consommée ; zone et table gardent leur propriétaire ; horaires appliqués ; obstacle et soins empruntent la vraie exécution ; aucun panneau indicatif vendu comme mécanisme actif.

### D11 — Scénario et références

**Correspondance :** UX-22, UX-23.1, UX-23.2. **Dépendances :** D01–D04. **Anomalies :** L04, L05.

Adapter les formulaires natifs de conditions et références, l’autorité de résolution, les variantes d’élément et le propriétaire des événements globaux. Garder l’écriture des scènes dans Scènes.

**Sortie :** projet sans fixture capable de créer chaque type ; référence manquante visible ; prêt/inactif distinct de brouillon ; aperçu et exécution concordants ; ordre testé ; parcours PNJ répété validé ; événement global sans coordonnées.

### D12 — Ambiance et sources réelles

**Correspondance :** UX-17, UX-18, UX-20. **Dépendances :** D03–D05. **Anomalie :** L06.

Adapter les patches d’héritage, les paramètres du lieu, les ancres réelles et l’audio. Préserver l’indépendance de l’aperçu.

**Sortie :** retour à héritage supprime la surcharge ; carte vide sans lampadaire fictif ; source réelle localisable et supprimable ; aperçu ne change pas l’heure enregistrée ; intérieur protégé ; audio exporté et lu offline.

### D13 — Session et diagnostic de test

**Correspondance :** UX-07, UX-21, UX-24, UX-25. **Dépendances :** lots concernés.

Brancher historique, enregistrement, diagnostics et test au flux natif. Le diagnostic navigue vers le propriétaire du problème.

**Sortie :** sauvegarde/relecture réelle ; erreur conservant le travail ; point de test distinct du départ ; diagnostic des arrivées et dépendances ; lancement moteur réel ; parité MCP et mesures incrémentales.

### D14 — Recette finale native

**Correspondance :** UX-26. **Dépendances :** D01–D13.

Exécuter les parcours du chapitre 24 sur une copie QA possédée, dans les profils supportés ; comparer aux captures de référence et relever les écarts justifiés.

**Sortie :** preuve Studio, relecture, export, Player et visuel pour chaque parcours requis. Le résultat indique ce qui est terminé, ce qui reste indicatif et les capacités non supportées. Aucun nouveau tour de design n’est nécessaire pour corriger une commande défaillante.

### Ordre et parallélisme raisonnables

D01 et D02 forment le socle. Après stabilisation des contrats, D03/D04 et D08 peuvent avancer avec propriétaires de fichiers distincts. D05–D07 portent la construction ; D09–D10 le jeu ; D11 le scénario ; D12 l’ambiance. D13 intègre, D14 vérifie.

Les états de sélection, les modèles et les validateurs partagés gardent un propriétaire unique pendant l’intégration. Paralléliser quatre agents sur le même store ne remplace pas un contrat commun.

<a id="24-recette"></a>
## 24. Parcours de recette de bout en bout

Ces scénarios servent de critères de reprise. Ils n’ont pas été exécutés dans Studio natif pour cette livraison de documentation.

| ID | Préparation et actions | Résultat à prouver | Référence |
| --- | --- | --- | --- |
| R01 | Carte sans éolienne ; ouvrir catalogue projet, chercher, poser, enregistrer, rouvrir | Instance réelle et usage local ; autre carte inchangée | 024–025, 048, 147–149 |
| R02 | Créer sol, chemin, eau, relief et pente puis les rééditer | Données natives distinctes, raccord et déplacement moteur | 056–088 |
| R03 | Rectangle couvrant 32 × 24, puis carte 8 × 8 ; zoom et pan | Même cellule, bords atteints, aucune troncature | 901–902 |
| R04 | Proposition environnement ; naviguer ; essayer les trois réponses | Proposition conservée, abandonnée ou appliquée une seule fois | 091–097 |
| R05 | Décor lié à interaction ; copie groupée ; déplacer la copie | Nouveau lien interne ; original inchangé ; undo cohérent | 317, 383–386 |
| R06 | Calque verrouillé, élément verrouillé, commande champ/drag/flèche | Même refus et explication ; aucun delta caché | 108–115, 387, 390–392 |
| R07 | Carte 8 × 8 ; zone jouable 2,2,4,4 ; poser en 0,0 par chaque entrée | Refus identique ; données conservées | 903–908 |
| R08 | Connexion avec une case commune ; réduire la carte | Refus ou résolution explicite ; pas de vert à zéro recouvrement | 909–910 |
| R09 | Choisir arrivée, annuler, confirmer une nouvelle case, créer retour | Pas de point orphelin ; un point confirmé ; trajet Player aller/retour | 195–207 |
| R10 | Peindre marche/blocage/Surf/sens unique ; tester | Règles persistées et consommées ; apparence indépendante | 208–217 |
| R11 | Zone de rencontre avec table projet, horaire et activation | Référence partagée ; tirage réel selon conditions | 218–235 |
| R12 | Choisir point de test puis remplacer le départ du projet | Deux choix distincts ; protections et reprise cohérentes | 236–249 |
| R13 | Créer PNJ sans comportement ; compléter, désactiver, réordonner | Brouillon/prêt/actif corrects ; scène reste dans Scènes | 273–294, 320–322 |
| R14 | PNJ à parcours dérivant ; corriger puis exécuter | Diagnostic des répétitions ; mouvement natif conforme | 298–302 |
| R15 | Projet sans écouteur global ; créer et associer un résultat | Parcours accessible sans fixture ; événement non spatial | 304–311, 904 |
| R16 | Ambiance héritée → locale → héritée ; changer l’aperçu | Patch retiré ; heure enregistrée inchangée par aperçu | 339–344, 364–366 |
| R17 | Carte vide ; ajouter puis supprimer une vraie source lumineuse | Aucun faux lampadaire ; source et effets cohérents | 356, 369, 907 |
| R18 | Musique de carte et météo ; export, lancement offline | Fichiers présents, sons et volume réellement consommés | 351–352, 371–375 |
| R19 | Duplication point au centre puis en dernier coin | Succès au centre ; refus explicite au bord sans perte de sélection | L09 |
| R20 | Erreur d’écriture simulée sur copie QA, reprise puis relecture | Travail conservé ; message utile ; aucune corruption d’original | Cible native sans capture |
| R21 | Fenêtre compacte ; clavier et dialogues | Actions atteignables, focus cohérent, erreurs annoncées | 394–401 |

### Fichiers de tests existants à privilégier

Ces chemins ont été observés lors de la préparation ; ils servent de points de départ. Leur existence ne signifie pas que leurs tests ont été relancés ou qu’ils prouvent tous les critères ci-dessus.

Dans `apps/avelune_studio/test/map_workspace/` :

- Sélection/commandes : `locked_element_selection_test.dart`, `entity_deletion_guard_test.dart`, `map_selection_scope_regression_test.dart`, `map_content_logical_groups_test.dart`, `inspector_fields_undo_test.dart`, `context_keyboard_test.dart`.
- Construction : `spatial_terrain_surface_tools_test.dart`, `spatial_terrain_painting_test.dart`, `spatial_terrain_surface_stroke_test.dart`, `spatial_relief_tools_test.dart`, `map_relief_guided_flow_test.dart`, `spatial_environment_gesture_test.dart`, `environment_canvas_ownership_test.dart`.
- Vue et décors : `spatial_navigation_tools_test.dart`, `map_canvas_navigation_test.dart`, `decor_transform_host_test.dart`, `decor_disk_journey_test.dart`, `spatial_exterior_decoration_editor_test.dart`.
- Cartes et connexions : `map_connection_host_test.dart`, `map_connection_discovery_test.dart`, `warp_runtime_destination_test.dart`, `warp_disk_journey_test.dart`, `warp_editing_test.dart`, `uwu2_resize_runtime_host_test.dart`, `uwu2_deleted_destination_history_test.dart`, `uwu6_empty_map_host_test.dart`.
- Catalogue : `map_catalog_mutation_test.dart`, `map_catalog_transaction_guard_test.dart`, `map_catalog_lifecycle_races_test.dart`, `map_catalog_stale_document_test.dart`, `map_catalog_async_reads_test.dart`.
- Jeu : `map_collision_stroke_test.dart`, `field_obstacle_inspector_test.dart`, `healing_display_inspector_test.dart`, `gameplay_zone_table_commands_test.dart`, `gameplay_zone_canvas_test.dart`.
- Coût de sauvegarde : `map_save_cost_bench_test.dart`.

Autres points de départ : `test/presentation/map_atmosphere_settings_panel_test.dart`, `test/events/event_conditions_logic_test.dart`, `test/scenes/scene_condition_form_ui06_test.dart`, `test/scenes/scene_condition_source_forms_test.dart`, `test/scenes/scene_condition_catalog_refresh_host_test.dart`, `test/characters/character_time_window_test.dart`, `test/characters/story_zone_overlay_test.dart`, `test/ui13_verification_runtime_test.dart`.

Choisir les tests du contrat touché avant une suite large. Compléter les cas attendus, négatifs et une non-régression avec la vraie commande. Les tests runtime/Player viennent ensuite lorsque le comportement les concerne. Aucun build d’application n’est requis pour ce dossier documentaire.

<a id="25-couverture"></a>
## 25. Couverture, exclusions et maintenance

### 25.1 Organisation physique

| Fichier / dossier | Contenu |
| --- | --- |
| README.md | Référence consolidée et index complet |
| index.html | Galerie filtrable, couverture et lecture de ce document |
| manifest.json | Révision, groupes, limites, exclusions, chaque fichier et SHA-256 |
| captures/001–401 | Captures de cette documentation |
| captures/900–914 | Captures importées de l’audit sur la même révision |

Chaque numéro est stable. Il ne décrit pas un numéro de test. Les sauts de 401 à 900 sont intentionnels pour distinguer la provenance. Les titres des captures décrivent l’état visible, même lorsqu’il diffère de l’intention initiale de l’interaction.

### 25.2 Matrice de couverture

| Famille | Couverture visuelle | Limite |
| --- | --- | --- |
| Navigation globale | Accès et dialogues | Modules externes non implémentés ici |
| Ressources | Six familles, portées, filtres, vide, aperçus | Catalogue statique de 21 exemples |
| Décors | Placement, transformations, verrouillage | Drag direct absent ; fond illustré non éditable |
| Surfaces et reliefs | Choix, gestes, formes, contours, pentes | Géométrie/raccord moteur non démontrés |
| Environnements | Proposition, variation, garde et validation | Génération native/performance non démontrées |
| Contenu et calques | Filtres, sélection, copie, suppression, protections | Cas L01/L09 encore incohérents |
| Cartes/réglages | Gestionnaire, vide, copie, suppression, dimensions | L02 ; catalogue et persistance de fixture |
| Jeu | Cinq catégories, dialogues, diagnostics | Moteur absent ; mécanismes avancés indicatifs |
| Scénario | Types, propriétés, références, brouillons, aperçu | Conditions limitées ; création globale manquante |
| Ambiance | Temps, météo, six effets, musique | Sources fictives, audio absent, rendu illustratif |
| Session/test | Historique, état enregistré, préparation et aperçu | Aucun jeu lancé ni écriture durable prouvée |
| Compact | Quatre espaces et inspecteur replié | Pas de recette mobile ni de toutes les tailles |

### 25.3 États explicitement non capturés

| ID | État | Motif et traitement |
| --- | --- | --- |
| NC01 | Toutes les combinaisons de champs, textes, tracés et réglages | Espace combinatoire ouvert ; branches et valeurs représentatives documentées |
| NC02 | Milieu exact d’un glisser avec pointeur maintenu | Les captures retiennent outil armé et résultat ; geste atomique de l’outil de capture |
| NC03 | Menu natif de chaque select ouvert | Rendu navigateur/OS variable ; valeurs choisies capturées, alternatives énumérées |
| NC04 | Erreur réseau/chargement de catalogue réel | Fixtures synchrones ; cible native explicitée |
| NC05 | Erreur durable de sauvegarde et récupération | Pas de stockage natif dans la maquette |
| NC06 | Catalogue de scènes/tables réellement supprimées pendant l’édition | Données statiques ; références absentes accessibles montrées, autres cas à tester nativement |
| NC07 | Activation 2D de Corde Sortie, Flash ou Plongée | Profil de fixture 3D ; ne pas fabriquer un contrôle actif |
| NC08 | Édition complète d’une scène, dialogue, table ou définition de dresseur | Module externe ; frontière volontaire |
| NC09 | Association réelle et CRUD de sources d’ambiance | Parcours absent ; L06 |
| NC10 | Création normale d’un écouteur global | Parcours absent ; L05 |
| NC11 | Déplacement direct de décor réussi | Interaction absente ; L08, aucun faux résultat fourni |
| NC12 | Jeu moteur, combat, audio, export et reprise de progression | Hors exécution de la maquette |
| NC13 | Chaque carte et chaque ressource d’un vrai projet | Catalogue de démonstration borné |
| NC14 | Thèmes, langues, zoom système et toutes tailles de fenêtre | Non fournis par cette révision ; recette d’accessibilité native requise |
| NC15 | Historique de toutes les anciennes révisions MagicPath | Dossier figé sur une révision, sans mélange avec les pistes abandonnées |

Ces exclusions rendent le dossier vérifiable. Elles ne signifient pas que les états natifs de chargement ou d’erreur sont optionnels.

### 25.4 Vérification de cette livraison

Les 416 fichiers ont été décodés pour vérifier leur intégrité et parcourus visuellement en planches de contact ; les cas ambigus ont été renommés selon leur contenu réel. Le manifeste enregistre taille, dimensions et empreinte de chaque image. La galerie permet d’ouvrir l’original.

Vérifications exécutées pour cette livraison :

- Décodage des 416 JPEG : réussi ; 39 238 573 octets de captures.
- Correspondance fichiers / manifeste / index : 416 images référencées, aucune manquante, aucune empreinte SHA-256 incohérente.
- Liens locaux et ancres du document : aucune cible manquante.
- Vérification des 45 chemins de tests natifs cités : tous existent ; aucun de ces tests n’est revendiqué comme exécuté ici.
- `node --check` sur le script de galerie : code de sortie 0.
- Exécution de la galerie dans un DOM local, sans navigateur et sans réseau : 12 contrôles réussis, dont recherche par ID et sans accent, filtres, état vide, ouverture, navigation entre captures, accès au chapitre et inventaires des limites ; aucune erreur JavaScript.
- `POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh` : code de sortie 0, un nouveau Markdown en emplacement canonique.

**Limite de vérification de la galerie :** le navigateur intégré refuse le protocole `file://`. La galerie finale n’a donc pas été inspectée visuellement dans ce navigateur. Le contrôle DOM valide ses interactions, pas sa composition visuelle ni son rendu dans chaque navigateur. Les 416 captures elles-mêmes ont bien été inspectées visuellement.

Les tests Flutter/Dart et une nouvelle compilation native ne sont pas exécutés pour cette livraison documentaire. Les résultats d’audits précédents sont historiques, sans être transformés en résultats frais de cette documentation.

Le dépôt était déjà largement modifié avant cette tâche et reste partagé avec d’autres travaux. Cette livraison crée seulement le dossier documentaire et son entrée d’autorisation dans .gitignore ; les autres changements ne lui sont pas attribués. Aucun add, commit ou push n’est effectué par cette tâche.

Points d’observation Git : début sur `main`, HEAD `8c49dd6867806151ce0a894f2006f378f8d55154`, 115 entrées de statut ; contrôle de livraison sur `main`, HEAD `06fd484d3fbe762f33380e05a21629cb6dee23fc`, 436 entrées, dont les 419 nouveaux fichiers de ce dossier. Le HEAD et les modifications extérieures ont évolué pendant le travail partagé ; leur attribution ne revient pas à cette tâche. Ces nombres décrivent deux instantanés, pas un diff entièrement produit ici.

### 25.5 Mise à jour future

Une future révision de maquette doit être identifiée par un nouvel identifiant de révision, avec ses captures associées. Ne pas mélanger silencieusement plusieurs sources dans une même série. Conserver les identifiants d’états et signaler les captures remplacées.

Pour l’implémentation, conserver ce dossier comme référence de comportement et de présentation ; suivre les statuts dans le plan natif existant. La prochaine étape utile est la réalisation et la recette d’un lot borné, pas une nouvelle boucle d’audits de la même maquette.

<a id="26-index"></a>
## 26. Index exhaustif des captures livrées

L’ordre est celui des séries de capture ; les filtres de la galerie regroupent les états par thème. Les légendes sont des descriptions d’état, pas des déclarations de recette native réussie.

| ID | Thème | État capturé | Précision |
| --- | --- | --- | --- |
| 001 | Construction | [accueil catalogue projet](captures/001-construction-accueil-catalogue-projet.jpg) | État de maquette. |
| 002 | Bibliothèque | [decors](captures/002-bibliotheque-decors.jpg) | État de maquette. |
| 003 | Bibliothèque | [sols](captures/003-bibliotheque-sols.jpg) | État de maquette. |
| 004 | Bibliothèque | [chemins](captures/004-bibliotheque-chemins.jpg) | État de maquette. |
| 005 | Bibliothèque | [eau](captures/005-bibliotheque-eau.jpg) | État de maquette. |
| 006 | Bibliothèque | [reliefs et parois](captures/006-bibliotheque-reliefs-et-parois.jpg) | État de maquette. |
| 007 | Bibliothèque | [environnements](captures/007-bibliotheque-environnements.jpg) | État de maquette. |
| 008 | Bibliothèque | [ressources de la carte](captures/008-bibliotheque-ressources-de-la-carte.jpg) | État de maquette. |
| 009 | Bibliothèque | [recherche avec resultat](captures/009-bibliotheque-recherche-avec-resultat.jpg) | État de maquette. |
| 010 | Bibliothèque | [recherche vide](captures/010-bibliotheque-recherche-vide.jpg) | État de maquette. |
| 011 | Bibliothèque | [filtres avances](captures/011-bibliotheque-filtres-avances.jpg) | État de maquette. |
| 012 | Bibliothèque | [sous famille couchages](captures/012-bibliotheque-sous-famille-couchages.jpg) | État de maquette. |
| 013 | Bibliothèque | [portee carte reinitialise famille](captures/013-bibliotheque-portee-carte-reinitialise-famille.jpg) | Le passage à la portée carte réinitialise la sous-famille ; voir 399–400 pour le vrai état vide filtré. |
| 014 | Navigation globale | [accueil projet](captures/014-navigation-accueil-projet.jpg) | Point d’entrée illustratif, module externe non implémenté dans ce composant. |
| 015 | Navigation globale | [carte regionale](captures/015-navigation-carte-regionale.jpg) | Point d’entrée illustratif, module externe non implémenté dans ce composant. |
| 016 | Navigation globale | [gestion ressources](captures/016-navigation-gestion-ressources.jpg) | Point d’entrée illustratif, module externe non implémenté dans ce composant. |
| 017 | Navigation globale | [histoire](captures/017-navigation-histoire.jpg) | Point d’entrée illustratif, module externe non implémenté dans ce composant. |
| 018 | Navigation globale | [raccourcis aide](captures/018-navigation-raccourcis-aide.jpg) | Point d’entrée illustratif, module externe non implémenté dans ce composant. |
| 019 | Navigation globale | [reglages projet](captures/019-navigation-reglages-projet.jpg) | Point d’entrée illustratif, module externe non implémenté dans ce composant. |
| 020 | Bibliothèque | [onglet cartes](captures/020-bibliotheque-onglet-cartes.jpg) | État de maquette. |
| 021 | Construction | [interieur maison](captures/021-construction-interieur-maison.jpg) | État de maquette. |
| 022 | Bibliothèque | [ressources maison](captures/022-bibliotheque-ressources-maison.jpg) | État de maquette. |
| 023 | Décors | [placement lit](captures/023-decor-placement-lit.jpg) | État de maquette. |
| 024 | Décors | [placement eolienne projet](captures/024-decor-placement-eolienne-projet.jpg) | État de maquette. |
| 025 | Décors | [instance ajoutee](captures/025-decor-instance-ajoutee.jpg) | État de maquette. |
| 026 | Décors | [clic lit de reference](captures/026-decor-clic-lit-de-reference.jpg) | Clic sur un lit de l’image de référence ; aucune sélection d’instance éditable prouvée. |
| 027 | Décors | [instance selectionnee](captures/027-decor-instance-selectionnee.jpg) | État de maquette. |
| 028 | Décors | [rotation 90](captures/028-decor-rotation-90.jpg) | État de maquette. |
| 029 | Décors | [rotation 180](captures/029-decor-rotation-180.jpg) | État de maquette. |
| 030 | Décors | [rotation 270](captures/030-decor-rotation-270.jpg) | État de maquette. |
| 031 | Décors | [rotation 0](captures/031-decor-rotation-0.jpg) | État de maquette. |
| 032 | Décors | [collision desactivee](captures/032-decor-collision-desactivee.jpg) | État de maquette. |
| 033 | Décors | [instance petite decalee](captures/033-decor-instance-petite-decalee.jpg) | État de maquette. |
| 034 | Décors | [instance grande animation desactivee](captures/034-decor-instance-grande-animation-desactivee.jpg) | État de maquette. |
| 035 | Décors | [erreur position hors limites](captures/035-decor-erreur-position-hors-limites.jpg) | État de maquette. |
| 036 | Fiches de ressources | [lit](captures/036-ressource-lit.jpg) | État de maquette. |
| 037 | Fiches de ressources | [bureau](captures/037-ressource-bureau.jpg) | État de maquette. |
| 038 | Fiches de ressources | [plante](captures/038-ressource-plante.jpg) | État de maquette. |
| 039 | Fiches de ressources | [televiseur](captures/039-ressource-televiseur.jpg) | État de maquette. |
| 040 | Fiches de ressources | [tapis](captures/040-ressource-tapis.jpg) | État de maquette. |
| 041 | Fiches de ressources | [horloge](captures/041-ressource-horloge.jpg) | État de maquette. |
| 042 | Fiches de ressources | [assise](captures/042-ressource-assise.jpg) | État de maquette. |
| 043 | Fiches de ressources | [equipement jeu](captures/043-ressource-equipement-jeu.jpg) | État de maquette. |
| 044 | Fiches de ressources | [banc](captures/044-ressource-banc.jpg) | État de maquette. |
| 045 | Fiches de ressources | [lampadaire](captures/045-ressource-lampadaire.jpg) | État de maquette. |
| 046 | Fiches de ressources | [chemin terre](captures/046-ressource-chemin-terre.jpg) | État de maquette. |
| 047 | Fiches de ressources | [chemin pave](captures/047-ressource-chemin-pave.jpg) | État de maquette. |
| 048 | Fiches de ressources | [herbe](captures/048-ressource-herbe.jpg) | État de maquette. |
| 049 | Fiches de ressources | [sable](captures/049-ressource-sable.jpg) | État de maquette. |
| 050 | Fiches de ressources | [eau](captures/050-ressource-eau.jpg) | État de maquette. |
| 051 | Fiches de ressources | [falaise terreuse](captures/051-ressource-falaise-terreuse.jpg) | État de maquette. |
| 052 | Fiches de ressources | [falaise rocheuse](captures/052-ressource-falaise-rocheuse.jpg) | État de maquette. |
| 053 | Fiches de ressources | [paroi grotte](captures/053-ressource-paroi-grotte.jpg) | État de maquette. |
| 054 | Fiches de ressources | [bosquet](captures/054-ressource-bosquet.jpg) | État de maquette. |
| 055 | Fiches de ressources | [prairie](captures/055-ressource-prairie.jpg) | État de maquette. |
| 056 | Chemins | [raccord droit](captures/056-chemin-raccord-droit.jpg) | État de maquette. |
| 057 | Chemins | [raccord virage](captures/057-chemin-raccord-virage.jpg) | État de maquette. |
| 058 | Chemins | [raccord jonction](captures/058-chemin-raccord-jonction.jpg) | État de maquette. |
| 059 | Chemins | [pieces raccords ouvertes](captures/059-chemin-pieces-raccords-ouvertes.jpg) | État de maquette. |
| 060 | Chemins | [ligne largeur minimale](captures/060-chemin-ligne-largeur-minimale.jpg) | État de maquette. |
| 061 | Chemins | [ligne largeur maximale](captures/061-chemin-ligne-largeur-maximale.jpg) | État de maquette. |
| 062 | Chemins | [ligne dessinee](captures/062-chemin-ligne-dessinee.jpg) | État de maquette. |
| 063 | Chemins | [trace libre dessine](captures/063-chemin-trace-libre-dessine.jpg) | État de maquette. |
| 064 | Chemins | [gomme aucun trace](captures/064-chemin-gomme-aucun-trace.jpg) | État de maquette. |
| 065 | Décors | [selection superposee](captures/065-decor-selection-superposee.jpg) | Décor superposé sélectionné à la place du tracé visé ; vrais inspecteurs dans 066–070. |
| 066 | Surfaces | [ligne selectionnee proprietes](captures/066-terrain-ligne-selectionnee-proprietes.jpg) | État de maquette. |
| 067 | Surfaces | [forme trace](captures/067-terrain-forme-trace.jpg) | État de maquette. |
| 068 | Surfaces | [forme rectangle](captures/068-terrain-forme-rectangle.jpg) | État de maquette. |
| 069 | Surfaces | [forme pinceau](captures/069-terrain-forme-pinceau.jpg) | État de maquette. |
| 070 | Surfaces | [forme ligne](captures/070-terrain-forme-ligne.jpg) | État de maquette. |
| 071 | Surfaces | [contour deux points](captures/071-terrain-contour-deux-points.jpg) | État de maquette. |
| 072 | Surfaces | [pieces sol](captures/072-terrain-pieces-sol.jpg) | État de maquette. |
| 073 | Surfaces | [pinceau minimum](captures/073-terrain-pinceau-minimum.jpg) | État de maquette. |
| 074 | Surfaces | [pinceau maximum](captures/074-terrain-pinceau-maximum.jpg) | État de maquette. |
| 075 | Surfaces | [outil rectangle survol](captures/075-terrain-outil-rectangle-survol.jpg) | Survol du contrôle Rectangle ; aucune nouvelle application démontrée. |
| 076 | Reliefs et parois | [sommet chemin](captures/076-relief-sommet-chemin.jpg) | État de maquette. |
| 077 | Reliefs et parois | [sommet herbe](captures/077-relief-sommet-herbe.jpg) | État de maquette. |
| 078 | Reliefs et parois | [sommet eau](captures/078-relief-sommet-eau.jpg) | État de maquette. |
| 079 | Reliefs et parois | [sommet pave](captures/079-relief-sommet-pave.jpg) | État de maquette. |
| 080 | Reliefs et parois | [sommet sable](captures/080-relief-sommet-sable.jpg) | État de maquette. |
| 081 | Reliefs et parois | [continu denivele reancrage desactive](captures/081-relief-continu-denivele-reancrage-desactive.jpg) | État de maquette. |
| 082 | Pentes | [nord](captures/082-pente-nord.jpg) | État de maquette. |
| 083 | Pentes | [est](captures/083-pente-est.jpg) | État de maquette. |
| 084 | Pentes | [sud](captures/084-pente-sud.jpg) | État de maquette. |
| 085 | Pentes | [ouest](captures/085-pente-ouest.jpg) | État de maquette. |
| 086 | Pentes | [trace applique](captures/086-pente-trace-applique.jpg) | État de maquette. |
| 087 | Pentes | [geometrie selectionnee haut](captures/087-pente-geometrie-selectionnee-haut.jpg) | État de maquette. |
| 088 | Pentes | [geometrie selectionnee bas](captures/088-pente-geometrie-selectionnee-bas.jpg) | État de maquette. |
| 089 | Environnements | [densite minimale](captures/089-environnement-densite-minimale.jpg) | État de maquette. |
| 090 | Environnements | [densite maximale](captures/090-environnement-densite-maximale.jpg) | État de maquette. |
| 091 | Environnements | [apercu non applique](captures/091-environnement-apercu-non-applique.jpg) | État de maquette. |
| 092 | Environnements | [erreur second geste](captures/092-environnement-erreur-second-geste.jpg) | État de maquette. |
| 093 | Environnements | [autre repartition](captures/093-environnement-autre-repartition.jpg) | État de maquette. |
| 094 | Environnements | [garde changement contexte](captures/094-environnement-garde-changement-contexte.jpg) | État de maquette. |
| 095 | Environnements | [rester sur apercu](captures/095-environnement-rester-sur-apercu.jpg) | État de maquette. |
| 096 | Environnements | [abandon vers jeu](captures/096-environnement-abandon-vers-jeu.jpg) | État de maquette. |
| 097 | Environnements | [applique et enregistre](captures/097-environnement-applique-et-enregistre.jpg) | État de maquette. |
| 098 | Environnements | [zone selectionnee](captures/098-environnement-zone-selectionnee.jpg) | État de maquette. |
| 099 | Environnements | [zone prairie contour](captures/099-environnement-zone-prairie-contour.jpg) | État de maquette. |
| 100 | Contenu | [element verrouille](captures/100-contenu-element-verrouille.jpg) | État de maquette. |
| 101 | Environnements | [zone verrouillee](captures/101-environnement-zone-verrouillee.jpg) | État de maquette. |
| 102 | Contenu | [recherche vide](captures/102-contenu-recherche-vide.jpg) | État de maquette. |
| 103 | Contenu | [liste partie basse](captures/103-contenu-liste-partie-basse.jpg) | Partie basse de la liste après défilement. |
| 104 | Contenu | [filtre scenario](captures/104-contenu-filtre-scenario.jpg) | État de maquette. |
| 105 | Contenu | [selection evenement non spatial](captures/105-contenu-selection-evenement-non-spatial.jpg) | État de maquette. |
| 106 | Contenu | [element masque](captures/106-contenu-element-masque.jpg) | État de maquette. |
| 107 | Calques | [aucun calque](captures/107-calques-aucun-calque.jpg) | État de maquette. |
| 108 | Calques | [nom saisi](captures/108-calques-nom-saisi.jpg) | État de maquette. |
| 109 | Calques | [deux calques](captures/109-calques-deux-calques.jpg) | État de maquette. |
| 110 | Contenu | [element affecte calque](captures/110-contenu-element-affecte-calque.jpg) | État de maquette. |
| 111 | Calques | [calque masque](captures/111-calques-calque-masque.jpg) | État de maquette. |
| 112 | Calques | [calque verrouille](captures/112-calques-calque-verrouille.jpg) | État de maquette. |
| 113 | Calques | [erreur element sous calque masque](captures/113-calques-erreur-element-sous-calque-masque.jpg) | État de maquette. |
| 114 | Calques | [erreur element sous calque verrouille](captures/114-calques-erreur-element-sous-calque-verrouille.jpg) | État de maquette. |
| 115 | Calques | [ordre modifie](captures/115-calques-ordre-modifie.jpg) | État de maquette. |
| 116 | Calques | [calque supprime elements conserves](captures/116-calques-calque-supprime-elements-conserves.jpg) | État de maquette. |
| 117 | Contenu | [fond reference masque](captures/117-contenu-fond-reference-masque.jpg) | État de maquette. |
| 118 | Vue et navigation | [inspecteur replie](captures/118-vue-inspecteur-replie.jpg) | État de maquette. |
| 119 | Vue et navigation | [grille visible](captures/119-vue-grille-visible.jpg) | État de maquette. |
| 120 | Vue et navigation | [zoom 60](captures/120-vue-zoom-60.jpg) | État de maquette. |
| 121 | Vue et navigation | [zoom 150](captures/121-vue-zoom-150.jpg) | État de maquette. |
| 122 | Vue et navigation | [main vue deplacee](captures/122-vue-main-vue-deplacee.jpg) | État de maquette. |
| 123 | Vue et navigation | [vue libre illustrative](captures/123-vue-vue-libre-illustrative.jpg) | État de maquette. |
| 124 | Décor extérieur | [enveloppe et marges](captures/124-exterieur-enveloppe-et-marges.jpg) | État de maquette. |
| 125 | Décor extérieur | [refus placement zone jouable](captures/125-exterieur-refus-placement-zone-jouable.jpg) | État de maquette. |
| 126 | Décor extérieur | [decor place dans marge](captures/126-exterieur-decor-place-dans-marge.jpg) | État de maquette. |
| 127 | Décor extérieur | [instance coordonnees hors carte](captures/127-exterieur-instance-coordonnees-hors-carte.jpg) | État de maquette. |
| 128 | Décor extérieur | [refus reintegrer decor dans zone](captures/128-exterieur-refus-reintegrer-decor-dans-zone.jpg) | État de maquette. |
| 129 | Décor extérieur | [refus reduction marge](captures/129-exterieur-refus-reduction-marge.jpg) | État de maquette. |
| 130 | Décor extérieur | [marges asymetriques](captures/130-exterieur-marges-asymetriques.jpg) | État de maquette. |
| 131 | Décor extérieur | [marges repliees](captures/131-exterieur-marges-repliees.jpg) | État de maquette. |
| 132 | Décor extérieur | [refus peinture terrain](captures/132-exterieur-refus-peinture-terrain.jpg) | État de maquette. |
| 133 | Cartes du projet | [gestionnaire liste](captures/133-cartes-gestionnaire-liste.jpg) | État de maquette. |
| 134 | Cartes du projet | [apercu interieur](captures/134-cartes-apercu-interieur.jpg) | État de maquette. |
| 135 | Cartes du projet | [suppression depart protegee](captures/135-cartes-suppression-depart-protegee.jpg) | État de maquette. |
| 136 | Cartes du projet | [apercu schema route](captures/136-cartes-apercu-schema-route.jpg) | État de maquette. |
| 137 | Cartes du projet | [suppression references protegee](captures/137-cartes-suppression-references-protegee.jpg) | État de maquette. |
| 138 | Cartes du projet | [renommer ranger](captures/138-cartes-renommer-ranger.jpg) | État de maquette. |
| 139 | Cartes du projet | [recherche resultat](captures/139-cartes-recherche-resultat.jpg) | État de maquette. |
| 140 | Cartes du projet | [recherche vide](captures/140-cartes-recherche-vide.jpg) | État de maquette. |
| 141 | Cartes du projet | [filtre dossier](captures/141-cartes-filtre-dossier.jpg) | État de maquette. |
| 142 | Cartes du projet | [creation formulaire](captures/142-cartes-creation-formulaire.jpg) | État de maquette. |
| 143 | Cartes du projet | [creation erreur nom](captures/143-cartes-creation-erreur-nom.jpg) | État de maquette. |
| 144 | Cartes du projet | [creation erreur doublon](captures/144-cartes-creation-erreur-doublon.jpg) | État de maquette. |
| 145 | Cartes du projet | [creation erreur dimensions](captures/145-cartes-creation-erreur-dimensions.jpg) | État de maquette. |
| 146 | Cartes du projet | [creation type interieur](captures/146-cartes-creation-type-interieur.jpg) | État de maquette. |
| 147 | Cartes du projet | [carte vide creee](captures/147-cartes-carte-vide-creee.jpg) | État de maquette. |
| 148 | Bibliothèque | [carte vide sans ressource](captures/148-bibliotheque-carte-vide-sans-ressource.jpg) | État de maquette. |
| 149 | Contenu | [carte vide sans element](captures/149-contenu-carte-vide-sans-element.jpg) | État de maquette. |
| 150 | Cartes du projet | [dupliquer formulaire](captures/150-cartes-dupliquer-formulaire.jpg) | État de maquette. |
| 151 | Cartes du projet | [dupliquer nom refuse](captures/151-cartes-dupliquer-nom-refuse.jpg) | État de maquette. |
| 152 | Cartes du projet | [copie dossier cible](captures/152-cartes-copie-dossier-cible.jpg) | État de maquette. |
| 153 | Cartes du projet | [suppression carte libre](captures/153-cartes-suppression-carte-libre.jpg) | État de maquette. |
| 154 | Cartes du projet | [carte supprimee](captures/154-cartes-carte-supprimee.jpg) | État de maquette. |
| 155 | Réglages de carte | [camera perspective large](captures/155-reglages-camera-perspective-large.jpg) | État de maquette. |
| 156 | Réglages de carte | [camera format 4 3](captures/156-reglages-camera-format-4-3.jpg) | État de maquette. |
| 157 | Réglages de carte | [camera format portrait](captures/157-reglages-camera-format-portrait.jpg) | État de maquette. |
| 158 | Réglages de carte | [camera orthographique](captures/158-reglages-camera-orthographique.jpg) | État de maquette. |
| 159 | Réglages de carte | [camera valeurs limites](captures/159-reglages-camera-valeurs-limites.jpg) | État de maquette. |
| 160 | Réglages de carte | [dimensions et limites](captures/160-reglages-dimensions-et-limites.jpg) | État de maquette. |
| 161 | Réglages de carte | [dimensions erreur valeur](captures/161-reglages-dimensions-erreur-valeur.jpg) | État de maquette. |
| 162 | Réglages de carte | [dimensions reduction refusee](captures/162-reglages-dimensions-reduction-refusee.jpg) | État de maquette. |
| 163 | Réglages de carte | [dimensions agrandissement](captures/163-reglages-dimensions-agrandissement.jpg) | État de maquette. |
| 164 | Réglages de carte | [limites erreur geometrie](captures/164-reglages-limites-erreur-geometrie.jpg) | État de maquette. |
| 165 | Réglages de carte | [limites excluent contenu](captures/165-reglages-limites-excluent-contenu.jpg) | État de maquette. |
| 166 | Réglages de carte | [regles locales exterieur](captures/166-reglages-regles-locales-exterieur.jpg) | État de maquette. |
| 167 | Réglages de carte | [regles donjon antre noir](captures/167-reglages-regles-donjon-antre-noir.jpg) | État de maquette. |
| 168 | Réglages de carte | [regles donjon caves jumelles](captures/168-reglages-regles-donjon-caves-jumelles.jpg) | État de maquette. |
| 169 | Réglages de carte | [regles interieur velo indisponible](captures/169-reglages-regles-interieur-velo-indisponible.jpg) | État de maquette. |
| 170 | Historique et session | [annulation commune](captures/170-historique-annulation-commune.jpg) | État de maquette. |
| 171 | Historique et session | [retablissement commun](captures/171-historique-retablissement-commun.jpg) | État de maquette. |
| 172 | Historique et session | [session enregistree](captures/172-historique-session-enregistree.jpg) | État de maquette. |
| 173 | Jeu | [accueil connexions](captures/173-jeu-accueil-connexions.jpg) | État de maquette. |
| 174 | Jeu | [recherche resultat](captures/174-jeu-recherche-resultat.jpg) | État de maquette. |
| 175 | Jeu | [recherche vide](captures/175-jeu-recherche-vide.jpg) | État de maquette. |
| 176 | Cartes voisines | [menu ajouter liaison](captures/176-connexion-menu-ajouter-liaison.jpg) | État de maquette. |
| 177 | Cartes voisines | [voisin incomplet](captures/177-connexion-voisin-incomplet.jpg) | État de maquette. |
| 178 | Préparation du test | [diagnostic connexion bloquante](captures/178-test-diagnostic-connexion-bloquante.jpg) | État de maquette. |
| 179 | Préparation du test | [retour corriger proprietaire](captures/179-test-retour-corriger-proprietaire.jpg) | État de maquette. |
| 180 | Cartes voisines | [comparaison nord](captures/180-connexion-comparaison-nord.jpg) | État de maquette. |
| 181 | Cartes voisines | [comparaison est](captures/181-connexion-comparaison-est.jpg) | État de maquette. |
| 182 | Cartes voisines | [comparaison sud](captures/182-connexion-comparaison-sud.jpg) | État de maquette. |
| 183 | Cartes voisines | [decalage signe](captures/183-connexion-decalage-signe.jpg) | État de maquette. |
| 184 | Cartes voisines | [edition depuis extremite inverse](captures/184-connexion-edition-depuis-extremite-inverse.jpg) | État de maquette. |
| 185 | Cartes voisines | [conflit bord deux destinations](captures/185-connexion-conflit-bord-deux-destinations.jpg) | État de maquette. |
| 186 | Cartes voisines | [confirmation suppression deux sens](captures/186-connexion-confirmation-suppression-deux-sens.jpg) | État de maquette. |
| 187 | Cartes voisines | [liaison retiree](captures/187-connexion-liaison-retiree.jpg) | État de maquette. |
| 188 | Passages | [porte complete retour lie](captures/188-passage-porte-complete-retour-lie.jpg) | État de maquette. |
| 189 | Passages | [type escalier](captures/189-passage-type-escalier.jpg) | État de maquette. |
| 190 | Passages | [type echelle](captures/190-passage-type-echelle.jpg) | État de maquette. |
| 191 | Passages | [type porte](captures/191-passage-type-porte.jpg) | État de maquette. |
| 192 | Passages | [transition instantanee](captures/192-passage-transition-instantanee.jpg) | État de maquette. |
| 193 | Passages | [fondu minimum](captures/193-passage-fondu-minimum.jpg) | État de maquette. |
| 194 | Passages | [fondu maximum](captures/194-passage-fondu-maximum.jpg) | État de maquette. |
| 195 | Choix de destination | [point actuel selectionne](captures/195-destination-point-actuel-selectionne.jpg) | État de maquette. |
| 196 | Choix de destination | [recherche dossier](captures/196-destination-recherche-dossier.jpg) | État de maquette. |
| 197 | Choix de destination | [recherche vide](captures/197-destination-recherche-vide.jpg) | État de maquette. |
| 198 | Choix de destination | [nouvelle carte sans point choisi](captures/198-destination-nouvelle-carte-sans-point-choisi.jpg) | État de maquette. |
| 199 | Choix de destination | [point nomme choisi](captures/199-destination-point-nomme-choisi.jpg) | État de maquette. |
| 200 | Choix de destination | [nouvelle case choisie](captures/200-destination-nouvelle-case-choisie.jpg) | État de maquette. |
| 201 | Choix de destination | [arrivee confirmee](captures/201-destination-arrivee-confirmee.jpg) | État de maquette. |
| 202 | Passages | [sens unique sans retour](captures/202-passage-sens-unique-sans-retour.jpg) | État de maquette. |
| 203 | Passages | [retour cree](captures/203-passage-retour-cree.jpg) | État de maquette. |
| 204 | Passages | [placement arme](captures/204-passage-placement-arme.jpg) | État de maquette. |
| 205 | Passages | [nouveau passage sans destination](captures/205-passage-nouveau-passage-sans-destination.jpg) | État de maquette. |
| 206 | Passages | [confirmation suppression](captures/206-passage-confirmation-suppression.jpg) | État de maquette. |
| 207 | Passages | [supprime points conserves](captures/207-passage-supprime-points-conserves.jpg) | État de maquette. |
| 208 | Déplacements | [selection sans case](captures/208-deplacements-selection-sans-case.jpg) | État de maquette. |
| 209 | Déplacements | [case selectionnee](captures/209-deplacements-case-selectionnee.jpg) | État de maquette. |
| 210 | Déplacements | [regle marche](captures/210-deplacements-regle-marche.jpg) | État de maquette. |
| 211 | Déplacements | [regle bloque](captures/211-deplacements-regle-bloque.jpg) | État de maquette. |
| 212 | Déplacements | [regle surf](captures/212-deplacements-regle-surf.jpg) | État de maquette. |
| 213 | Déplacements | [regle sens unique](captures/213-deplacements-regle-sens-unique.jpg) | État de maquette. |
| 214 | Déplacements | [case regle appliquee](captures/214-deplacements-case-regle-appliquee.jpg) | État de maquette. |
| 215 | Déplacements | [effacement regle origine](captures/215-deplacements-effacement-regle-origine.jpg) | État de maquette. |
| 216 | Déplacements | [mecanismes avances](captures/216-deplacements-mecanismes-avances.jpg) | État de maquette. |
| 217 | Déplacements | [changement carte selection effacee](captures/217-deplacements-changement-carte-selection-effacee.jpg) | État de maquette. |
| 218 | Rencontres sauvages | [zone terre locale](captures/218-rencontres-zone-terre-locale.jpg) | État de maquette. |
| 219 | Rencontres sauvages | [table projet jour](captures/219-rencontres-table-projet-jour.jpg) | État de maquette. |
| 220 | Rencontres sauvages | [table projet nuit](captures/220-rencontres-table-projet-nuit.jpg) | État de maquette. |
| 221 | Rencontres sauvages | [table projet eau](captures/221-rencontres-table-projet-eau.jpg) | État de maquette. |
| 222 | Rencontres sauvages | [proprietaire table projet](captures/222-rencontres-proprietaire-table-projet.jpg) | État de maquette. |
| 223 | Rencontres sauvages | [horaire jour](captures/223-rencontres-horaire-jour.jpg) | État de maquette. |
| 224 | Rencontres sauvages | [horaire nuit](captures/224-rencontres-horaire-nuit.jpg) | État de maquette. |
| 225 | Rencontres sauvages | [frequence minimale](captures/225-rencontres-frequence-minimale.jpg) | État de maquette. |
| 226 | Rencontres sauvages | [frequence maximale](captures/226-rencontres-frequence-maximale.jpg) | État de maquette. |
| 227 | Rencontres sauvages | [methode surf](captures/227-rencontres-methode-surf.jpg) | État de maquette. |
| 228 | Rencontres sauvages | [methode peche](captures/228-rencontres-methode-peche.jpg) | État de maquette. |
| 229 | Rencontres sauvages | [zone desactivee](captures/229-rencontres-zone-desactivee.jpg) | État de maquette. |
| 230 | Rencontres sauvages | [zone activee](captures/230-rencontres-zone-activee.jpg) | État de maquette. |
| 231 | Rencontres sauvages | [redessin arme](captures/231-rencontres-redessin-arme.jpg) | État de maquette. |
| 232 | Rencontres sauvages | [zone redessinee](captures/232-rencontres-zone-redessinee.jpg) | État de maquette. |
| 233 | Rencontres sauvages | [nouvelle zone outil](captures/233-rencontres-nouvelle-zone-outil.jpg) | État de maquette. |
| 234 | Rencontres sauvages | [nouvelle zone inactive](captures/234-rencontres-nouvelle-zone-inactive.jpg) | État de maquette. |
| 235 | Rencontres sauvages | [confirmation suppression zone](captures/235-rencontres-confirmation-suppression-zone.jpg) | État de maquette. |
| 236 | Départs et arrivées | [arrivee referencee suppression protegee](captures/236-points-arrivee-referencee-suppression-protegee.jpg) | État de maquette. |
| 237 | Départs et arrivées | [orientation nord](captures/237-points-orientation-nord.jpg) | État de maquette. |
| 238 | Départs et arrivées | [orientation est](captures/238-points-orientation-est.jpg) | État de maquette. |
| 239 | Départs et arrivées | [orientation sud](captures/239-points-orientation-sud.jpg) | État de maquette. |
| 240 | Départs et arrivées | [orientation ouest](captures/240-points-orientation-ouest.jpg) | État de maquette. |
| 241 | Départs et arrivées | [role point test](captures/241-points-role-point-test.jpg) | État de maquette. |
| 242 | Départs et arrivées | [choisi pour test](captures/242-points-choisi-pour-test.jpg) | État de maquette. |
| 243 | Départs et arrivées | [confirmation remplacer depart](captures/243-points-confirmation-remplacer-depart.jpg) | État de maquette. |
| 244 | Préparation du test | [depart case bloquee](captures/244-test-depart-case-bloquee.jpg) | État de maquette. |
| 245 | Départs et arrivées | [placement arme](captures/245-points-placement-arme.jpg) | État de maquette. |
| 246 | Départs et arrivées | [nouveau point inutilise](captures/246-points-nouveau-point-inutilise.jpg) | État de maquette. |
| 247 | Départs et arrivées | [confirmation suppression](captures/247-points-confirmation-suppression.jpg) | État de maquette. |
| 248 | Départs et arrivées | [depart nouvelle partie actuel](captures/248-points-depart-nouvelle-partie-actuel.jpg) | État de maquette. |
| 249 | Départs et arrivées | [depart actuel changement protege](captures/249-points-depart-actuel-changement-protege.jpg) | État de maquette. |
| 250 | Objets utilitaires | [liste objets](captures/250-utilitaires-liste-objets.jpg) | État de maquette. |
| 251 | Objets utilitaires | [menu types](captures/251-utilitaires-menu-types.jpg) | État de maquette. |
| 252 | Objets utilitaires | [placement arbre](captures/252-utilitaires-placement-arbre.jpg) | État de maquette. |
| 253 | Objets utilitaires | [arbre coupe proprietes](captures/253-utilitaires-arbre-coupe-proprietes.jpg) | État de maquette. |
| 254 | Objets utilitaires | [etat persistant variante personnalisee](captures/254-utilitaires-etat-persistant-variante-personnalisee.jpg) | État de maquette. |
| 255 | Objets utilitaires | [rocher force](captures/255-utilitaires-rocher-force.jpg) | État de maquette. |
| 256 | Objets utilitaires | [rocher eclate roc](captures/256-utilitaires-rocher-eclate-roc.jpg) | État de maquette. |
| 257 | Objets utilitaires | [bloc glace reset impose](captures/257-utilitaires-bloc-glace-reset-impose.jpg) | État de maquette. |
| 258 | Objets utilitaires | [boules de soin](captures/258-utilitaires-boules-de-soin.jpg) | État de maquette. |
| 259 | Objets utilitaires | [capacite minimale](captures/259-utilitaires-capacite-minimale.jpg) | État de maquette. |
| 260 | Objets utilitaires | [objet verrouille](captures/260-utilitaires-objet-verrouille.jpg) | État de maquette. |
| 261 | Objets utilitaires | [confirmation suppression texte actuel](captures/261-utilitaires-confirmation-suppression-texte-actuel.jpg) | État de maquette. |
| 262 | Scénario | [accueil sans selection](captures/262-scenario-accueil-sans-selection.jpg) | État de maquette. |
| 263 | Scénario | [aide et separation scenes](captures/263-scenario-aide-et-separation-scenes.jpg) | État de maquette. |
| 264 | Scénario | [portee projet](captures/264-scenario-portee-projet.jpg) | État de maquette. |
| 265 | Scénario | [filtre personnages](captures/265-scenario-filtre-personnages.jpg) | État de maquette. |
| 266 | Scénario | [filtre objets](captures/266-scenario-filtre-objets.jpg) | État de maquette. |
| 267 | Scénario | [filtre zones](captures/267-scenario-filtre-zones.jpg) | État de maquette. |
| 268 | Scénario | [filtre evenements](captures/268-scenario-filtre-evenements.jpg) | État de maquette. |
| 269 | Scénario | [filtre a configurer](captures/269-scenario-filtre-a-configurer.jpg) | État de maquette. |
| 270 | Scénario | [filtre tous](captures/270-scenario-filtre-tous.jpg) | État de maquette. |
| 271 | Scénario | [recherche resultat](captures/271-scenario-recherche-resultat.jpg) | État de maquette. |
| 272 | Scénario | [recherche vide](captures/272-scenario-recherche-vide.jpg) | État de maquette. |
| 273 | Scénario | [personnage comportement pret](captures/273-scenario-personnage-comportement-pret.jpg) | État de maquette. |
| 274 | Scénario | [comportement quand si alors](captures/274-scenario-comportement-quand-si-alors.jpg) | État de maquette. |
| 275 | Scénario | [declencheur contact personnage](captures/275-scenario-declencheur-contact-personnage.jpg) | État de maquette. |
| 276 | Scénario | [declencheur automatique](captures/276-scenario-declencheur-automatique.jpg) | État de maquette. |
| 277 | Scénario | [condition toujours](captures/277-scenario-condition-toujours.jpg) | État de maquette. |
| 278 | Scénario | [condition starter recu](captures/278-scenario-condition-starter-recu.jpg) | État de maquette. |
| 279 | Scénario | [repetition chaque interaction](captures/279-scenario-repetition-chaque-interaction.jpg) | État de maquette. |
| 280 | Scénario | [repetition par visite](captures/280-scenario-repetition-par-visite.jpg) | État de maquette. |
| 281 | Scénario | [selecteur scene associee](captures/281-scenario-selecteur-scene-associee.jpg) | État de maquette. |
| 282 | Scénario | [selecteur scene recherche](captures/282-scenario-selecteur-scene-recherche.jpg) | État de maquette. |
| 283 | Scénario | [selecteur scene vide](captures/283-scenario-selecteur-scene-vide.jpg) | État de maquette. |
| 284 | Scénario | [association retiree brouillon](captures/284-scenario-association-retiree-brouillon.jpg) | État de maquette. |
| 285 | Scénario | [nouveau comportement independant](captures/285-scenario-nouveau-comportement-independant.jpg) | État de maquette. |
| 286 | Scénario | [selecteur scene sans association](captures/286-scenario-selecteur-scene-sans-association.jpg) | État de maquette. |
| 287 | Scénario | [comportement pret inactif](captures/287-scenario-comportement-pret-inactif.jpg) | État de maquette. |
| 288 | Scénario | [comportement active](captures/288-scenario-comportement-active.jpg) | État de maquette. |
| 289 | Scénario | [ordre comportements modifie](captures/289-scenario-ordre-comportements-modifie.jpg) | État de maquette. |
| 290 | Scénario | [apercu conditions ouvert](captures/290-scenario-apercu-conditions-ouvert.jpg) | État de maquette. |
| 291 | Scénario | [apercu plusieurs correspondances](captures/291-scenario-apercu-plusieurs-correspondances.jpg) | État de maquette. |
| 292 | Scénario | [apercu element desactive](captures/292-scenario-apercu-element-desactive.jpg) | État de maquette. |
| 293 | Scénario | [apercu aucun comportement](captures/293-scenario-apercu-aucun-comportement.jpg) | État de maquette. |
| 294 | Scénario | [selection condition fausse autre comportement actif](captures/294-scenario-selection-condition-fausse-autre-comportement-actif.jpg) | État de maquette. |
| 295 | Scénario | [proprietes personnage haut](captures/295-scenario-proprietes-personnage-haut.jpg) | État de maquette. |
| 296 | Scénario | [personnage apparence orientation collision](captures/296-scenario-personnage-apparence-orientation-collision.jpg) | État de maquette. |
| 297 | Scénario | [personnage deplacement aleatoire](captures/297-scenario-personnage-deplacement-aleatoire.jpg) | État de maquette. |
| 298 | Scénario | [personnage parcours vide](captures/298-scenario-personnage-parcours-vide.jpg) | État de maquette. |
| 299 | Scénario | [personnage parcours derive](captures/299-scenario-personnage-parcours-derive.jpg) | État de maquette. |
| 300 | Scénario | [parcours sortie premiere etape](captures/300-scenario-parcours-sortie-premiere-etape.jpg) | État de maquette. |
| 301 | Scénario | [personnage parcours valide](captures/301-scenario-personnage-parcours-valide.jpg) | État de maquette. |
| 302 | Scénario | [personnage parcours attente](captures/302-scenario-personnage-parcours-attente.jpg) | État de maquette. |
| 303 | Scénario | [dresseur associe](captures/303-scenario-dresseur-associe.jpg) | État de maquette. |
| 304 | Scénario | [definition dresseur consultee](captures/304-scenario-definition-dresseur-consultee.jpg) | État de maquette. |
| 305 | Scénario | [element verrouille](captures/305-scenario-element-verrouille.jpg) | État de maquette. |
| 306 | Scénario | [resultat global reference](captures/306-scenario-resultat-global-reference.jpg) | État de maquette. |
| 307 | Scénario | [resultat defaite](captures/307-scenario-resultat-defaite.jpg) | État de maquette. |
| 308 | Scénario | [evenement starter](captures/308-scenario-evenement-starter.jpg) | État de maquette. |
| 309 | Scénario | [resultat victoire](captures/309-scenario-resultat-victoire.jpg) | État de maquette. |
| 310 | Scénario | [resultat global reference manquante](captures/310-scenario-resultat-global-reference-manquante.jpg) | État de maquette. |
| 311 | Scénario | [evenement global non spatial](captures/311-scenario-evenement-global-non-spatial.jpg) | État de maquette. |
| 312 | Scénario | [evenement carte proprietes](captures/312-scenario-evenement-carte-proprietes.jpg) | État de maquette. |
| 313 | Scénario | [evenement entree carte](captures/313-scenario-evenement-entree-carte.jpg) | État de maquette. |
| 314 | Scénario | [zone emprise modifiee](captures/314-scenario-zone-emprise-modifiee.jpg) | État de maquette. |
| 315 | Scénario | [reperes masques](captures/315-scenario-reperes-masques.jpg) | État de maquette. |
| 316 | Scénario | [objet repere independant](captures/316-scenario-objet-repere-independant.jpg) | État de maquette. |
| 317 | Scénario | [interaction liee decor](captures/317-scenario-interaction-liee-decor.jpg) | État de maquette. |
| 318 | Scénario | [carte sans scenario](captures/318-scenario-carte-sans-scenario.jpg) | État de maquette. |
| 319 | Scénario | [menu ajouter](captures/319-scenario-menu-ajouter.jpg) | État de maquette. |
| 320 | Scénario | [placement personnage](captures/320-scenario-placement-personnage.jpg) | État de maquette. |
| 321 | Scénario | [nouveau personnage sans comportement](captures/321-scenario-nouveau-personnage-sans-comportement.jpg) | État de maquette. |
| 322 | Scénario | [dernier comportement supprime](captures/322-scenario-dernier-comportement-supprime.jpg) | État de maquette. |
| 323 | Scénario | [placement objet](captures/323-scenario-placement-objet.jpg) | État de maquette. |
| 324 | Scénario | [nouvel objet sans comportement](captures/324-scenario-nouvel-objet-sans-comportement.jpg) | État de maquette. |
| 325 | Scénario | [placement zone](captures/325-scenario-placement-zone.jpg) | État de maquette. |
| 326 | Scénario | [nouvelle zone dessinee](captures/326-scenario-nouvelle-zone-dessinee.jpg) | État de maquette. |
| 327 | Scénario | [nouvel evenement carte](captures/327-scenario-nouvel-evenement-carte.jpg) | État de maquette. |
| 328 | Temps et aperçu | [accueil exterieur](captures/328-ambiance-accueil-exterieur.jpg) | État de maquette. |
| 329 | Temps et aperçu | [bourg meteo pluie](captures/329-ambiance-bourg-meteo-pluie.jpg) | État de maquette. |
| 330 | Temps et aperçu | [apercu aube](captures/330-ambiance-apercu-aube.jpg) | État de maquette. |
| 331 | Temps et aperçu | [apercu jour](captures/331-ambiance-apercu-jour.jpg) | État de maquette. |
| 332 | Temps et aperçu | [apercu soir](captures/332-ambiance-apercu-soir.jpg) | État de maquette. |
| 333 | Temps et aperçu | [apercu nuit](captures/333-ambiance-apercu-nuit.jpg) | État de maquette. |
| 334 | Temps et aperçu | [capture origine apercu desactive](captures/334-ambiance-capture-origine-apercu-desactive.jpg) | État de maquette. |
| 335 | Temps et aperçu | [heure apercu debut journee](captures/335-ambiance-heure-apercu-debut-journee.jpg) | État de maquette. |
| 336 | Temps et aperçu | [heure apercu fin journee](captures/336-ambiance-heure-apercu-fin-journee.jpg) | État de maquette. |
| 337 | Temps et aperçu | [zoom minimum](captures/337-ambiance-zoom-minimum.jpg) | État de maquette. |
| 338 | Temps et aperçu | [zoom maximum](captures/338-ambiance-zoom-maximum.jpg) | État de maquette. |
| 339 | Temps et aperçu | [cycle herite projet](captures/339-ambiance-cycle-herite-projet.jpg) | État de maquette. |
| 340 | Temps et aperçu | [cycle local](captures/340-ambiance-cycle-local.jpg) | État de maquette. |
| 341 | Temps et aperçu | [cycle local duree modifiee](captures/341-ambiance-cycle-local-duree-modifiee.jpg) | État de maquette. |
| 342 | Temps et aperçu | [heure fixe independante apercu](captures/342-ambiance-heure-fixe-independante-apercu.jpg) | Heure fixe enregistrée 14:36 ; aperçu 06:00, indépendant. |
| 343 | Temps et aperçu | [meteo heritee](captures/343-ambiance-meteo-heritee.jpg) | État de maquette. |
| 344 | Temps et aperçu | [meteo forcee degagee](captures/344-ambiance-meteo-forcee-degagee.jpg) | État de maquette. |
| 345 | Météo | [ciel degage](captures/345-meteo-ciel-degage.jpg) | État de maquette. |
| 346 | Météo | [nuages](captures/346-meteo-nuages.jpg) | État de maquette. |
| 347 | Météo | [pluie](captures/347-meteo-pluie.jpg) | État de maquette. |
| 348 | Météo | [orage](captures/348-meteo-orage.jpg) | État de maquette. |
| 349 | Météo | [neige](captures/349-meteo-neige.jpg) | État de maquette. |
| 350 | Météo | [brouillard](captures/350-meteo-brouillard.jpg) | État de maquette. |
| 351 | Météo | [intensite zero](captures/351-meteo-intensite-zero.jpg) | État de maquette. |
| 352 | Météo | [intensite maximale sons actives](captures/352-meteo-intensite-maximale-sons-actives.jpg) | État de maquette. |
| 353 | Météo | [interieur protege](captures/353-meteo-interieur-protege.jpg) | État de maquette. |
| 354 | Météo | [interieur meteo autorisee](captures/354-meteo-interieur-meteo-autorisee.jpg) | État de maquette. |
| 355 | Effets et sources | [liste interieur](captures/355-effets-liste-interieur.jpg) | État de maquette. |
| 356 | Effets et sources | [interieur sans source associee](captures/356-effets-interieur-sans-source-associee.jpg) | État de maquette. |
| 357 | Effets et sources | [interieur fenetres associees](captures/357-effets-interieur-fenetres-associees.jpg) | État de maquette. |
| 358 | Effets et sources | [fiche halos](captures/358-effets-fiche-halos.jpg) | État de maquette. |
| 359 | Effets et sources | [fiche fenetres](captures/359-effets-fiche-fenetres.jpg) | État de maquette. |
| 360 | Effets et sources | [fiche lucioles](captures/360-effets-fiche-lucioles.jpg) | État de maquette. |
| 361 | Effets et sources | [fiche eau](captures/361-effets-fiche-eau.jpg) | État de maquette. |
| 362 | Effets et sources | [fiche brume](captures/362-effets-fiche-brume.jpg) | État de maquette. |
| 363 | Effets et sources | [fiche profondeur champ](captures/363-effets-fiche-profondeur-champ.jpg) | État de maquette. |
| 364 | Effets et sources | [profondeur champ personnalisee active](captures/364-effets-profondeur-champ-personnalisee-active.jpg) | État de maquette. |
| 365 | Effets et sources | [personnalise inactif intensite masquee](captures/365-effets-personnalise-inactif-intensite-masquee.jpg) | État de maquette. |
| 366 | Effets et sources | [retour heritage](captures/366-effets-retour-heritage.jpg) | État de maquette. |
| 367 | Effets et sources | [halos intensite minimale](captures/367-effets-halos-intensite-minimale.jpg) | État de maquette. |
| 368 | Effets et sources | [halos intensite maximale](captures/368-effets-halos-intensite-maximale.jpg) | État de maquette. |
| 369 | Effets et sources | [source reperee selectionnee](captures/369-effets-source-reperee-selectionnee.jpg) | État de maquette. |
| 370 | Effets et sources | [brume activee](captures/370-effets-brume-activee.jpg) | État de maquette. |
| 371 | Musique | [aucune musique](captures/371-musique-aucune-musique.jpg) | État de maquette. |
| 372 | Musique | [piste bourg geon](captures/372-musique-piste-bourg-geon.jpg) | État de maquette. |
| 373 | Musique | [volume zero](captures/373-musique-volume-zero.jpg) | État de maquette. |
| 374 | Musique | [volume maximum](captures/374-musique-volume-maximum.jpg) | État de maquette. |
| 375 | Musique | [piste maison](captures/375-musique-piste-maison.jpg) | État de maquette. |
| 376 | Préparation du test | [preparation depuis ambiance](captures/376-test-preparation-depuis-ambiance.jpg) | État de maquette. |
| 377 | Préparation du test | [aucune incoherence](captures/377-test-aucune-incoherence.jpg) | État de maquette. |
| 378 | Préparation du test | [apercu depart sans moteur](captures/378-test-apercu-depart-sans-moteur.jpg) | État de maquette. |
| 379 | Préparation du test | [retour preparation](captures/379-test-retour-preparation.jpg) | État de maquette. |
| 380 | Préparation du test | [avertissements non bloquants](captures/380-test-avertissements-non-bloquants.jpg) | Avertissement du laboratoire après modification de destination ; état initial de la maison dans 393. |
| 381 | Contenu | [confirmation suppression selection](captures/381-contenu-confirmation-suppression-selection.jpg) | État de maquette. |
| 382 | Contenu | [refus suppression point reference](captures/382-contenu-refus-suppression-point-reference.jpg) | État de maquette. |
| 383 | Contenu | [refus suppression decor lie](captures/383-contenu-refus-suppression-decor-lie.jpg) | État de maquette. |
| 384 | Contenu | [selection multiple decor interaction](captures/384-contenu-selection-multiple-decor-interaction.jpg) | État de maquette. |
| 385 | Contenu | [duplication decor interaction](captures/385-contenu-duplication-decor-interaction.jpg) | État de maquette. |
| 386 | Décors | [copie selectionnee](captures/386-decor-copie-selectionnee.jpg) | État de maquette. |
| 387 | Décors | [instance verrouillee](captures/387-decor-instance-verrouillee.jpg) | État de maquette. |
| 388 | Contenu | [tous elements filtres selectionnes](captures/388-contenu-tous-elements-filtres-selectionnes.jpg) | État de maquette. |
| 389 | Construction | [selection multiple inspecteur](captures/389-construction-selection-multiple-inspecteur.jpg) | État de maquette. |
| 390 | Passages | [passage verrouille](captures/390-passage-passage-verrouille.jpg) | État de maquette. |
| 391 | Départs et arrivées | [point verrouille](captures/391-points-point-verrouille.jpg) | État de maquette. |
| 392 | Rencontres sauvages | [zone verrouillee](captures/392-rencontres-zone-verrouillee.jpg) | État de maquette. |
| 393 | Préparation du test | [avertissement sens unique reference](captures/393-test-avertissement-sens-unique-reference.jpg) | Fixture fraîche : Entrée de la maison sans retour ; aperçu autorisé. |
| 394 | Fenêtre compacte | [construction compact inspecteur ouvert](captures/394-responsive-construction-compact-inspecteur-ouvert.jpg) | Viewport de page 1000 × 800 ; marge extérieure de capture possible. |
| 395 | Fenêtre compacte | [construction compact inspecteur replie](captures/395-responsive-construction-compact-inspecteur-replie.jpg) | Viewport de page 1000 × 800 ; marge extérieure de capture possible. |
| 396 | Fenêtre compacte | [jeu compact](captures/396-responsive-jeu-compact.jpg) | Viewport de page 1000 × 800 ; marge extérieure de capture possible. |
| 397 | Fenêtre compacte | [scenario compact](captures/397-responsive-scenario-compact.jpg) | Viewport de page 1000 × 800 ; marge extérieure de capture possible. |
| 398 | Fenêtre compacte | [ambiance compact](captures/398-responsive-ambiance-compact.jpg) | Viewport de page 1000 × 800 ; marge extérieure de capture possible. |
| 399 | Bibliothèque | [filtre carte aucun resultat](captures/399-bibliotheque-filtre-carte-aucun-resultat.jpg) | État de maquette. |
| 400 | Bibliothèque | [puce filtre panneau replie](captures/400-bibliotheque-puce-filtre-panneau-replie.jpg) | État de maquette. |
| 401 | Bibliothèque | [recherche raccourci depuis jeu](captures/401-bibliotheque-recherche-raccourci-depuis-jeu.jpg) | État de maquette. |
| 900 | Écarts et preuves d’audit | [construction catalogue](captures/900-audit-construction-catalogue.jpg) | Preuve importée de l’audit ; même révision. |
| 901 | Écarts et preuves d’audit | [grille et terrain](captures/901-audit-grille-et-terrain.jpg) | L03 : grille fixe 16 × 16 sur carte 32 × 24. |
| 902 | Écarts et preuves d’audit | [largeur bord tronquee](captures/902-audit-largeur-bord-tronquee.jpg) | L03 : rectangle de largeur 32 tronqué à 31. |
| 903 | Écarts et preuves d’audit | [zone jouable centree](captures/903-audit-zone-jouable-centree.jpg) | Préparation L01 : carte 8 × 8, zone jouable 2,2,4,4. |
| 904 | Écarts et preuves d’audit | [ajouter scenario sans resultat](captures/904-audit-ajouter-scenario-sans-resultat.jpg) | L05 : création normale d’écouteur global absente du menu. |
| 905 | Écarts et preuves d’audit | [zone scenario hors limite](captures/905-audit-zone-scenario-hors-limite.jpg) | L01 : zone Scénario créée en 0,0 hors zone jouable. |
| 906 | Écarts et preuves d’audit | [conditions limitees au starter](captures/906-audit-conditions-limitees-au-starter.jpg) | L04 : trois conditions liées au Starter seulement. |
| 907 | Écarts et preuves d’audit | [source ambiance fictive carte vide](captures/907-audit-source-ambiance-fictive-carte-vide.jpg) | L06 : source de lampadaire sur carte vide. |
| 908 | Écarts et preuves d’audit | [point jeu hors limite](captures/908-audit-point-jeu-hors-limite.jpg) | L01 : point d’arrivée créé en 0,0 hors zone jouable. |
| 909 | Écarts et preuves d’audit | [voisin avant reduction](captures/909-audit-voisin-avant-reduction.jpg) | Avant réduction : une case commune, décalage 7. |
| 910 | Écarts et preuves d’audit | [voisin sans bord commun vert](captures/910-audit-voisin-sans-bord-commun-vert.jpg) | L02 : après réduction 4 × 4, zéro recouvrement mais état vert. |
| 911 | Écarts et preuves d’audit | [eau outil sculpter sans choix](captures/911-audit-eau-outil-sculpter-sans-choix.jpg) | Préparation L07 : Eau sans choix explicite de ressource. |
| 912 | Écarts et preuves d’audit | [eau arme relief terre](captures/912-audit-eau-arme-relief-terre.jpg) | L07 : Sculpter active implicitement un relief terrestre. |
| 913 | Écarts et preuves d’audit | [decor deplacement direct absent](captures/913-audit-decor-deplacement-direct-absent.jpg) | L08 : le glisser ne déplace pas le décor, selon l’interaction d’audit ; une image isolée ne prouve pas l’absence de mouvement. |
| 914 | Écarts et preuves d’audit | [test diagnostic et focus](captures/914-audit-test-diagnostic-et-focus.jpg) | Diagnostic et Corriger ; aucune certification de jeu réel. |

<a id="27-remplacement-ui"></a>
## 27. Plan exécutoire : retrait intégral et remplacement de l’UI

> Ce chapitre remplace les anciens lots D01–D14 comme ordre d’exécution. Les chapitres 1–26 restent la référence du constructeur. Les statuts du plan du 6 novembre ne valident aucune nouvelle UI.

**Mandat :** Toute l’UI du Studio, y compris shell, quatre espaces carte, ressources/ateliers, Histoire, Pokémon, réglages, régional, test/export et dialogues. Les moteurs Player et la logique métier restent protégés.

**Architecture :** retirer toutes les anciennes compositions avant reconstruction ; préserver contrats, données, moteurs et commandes. Flutter/Dart restent les technologies du produit.

**Suivi canonique :** [ui-replacement-plan.json](ui-replacement-plan.json). Lecture et comparaison dans l’onglet Plan de remplacement de [l’artefact](index.html#replacement).

**Départ :** 88 lots, 15 thématiques, zéro réalisation native revendiquée par la préparation du dossier.

### 27.1 Retrait et éléments protégés

- Premier changement du produit : retrait des compositions historiques ; préparation et extraction non visuelles permises avant G0.
- Suppression physique des widgets spécifiques Studio ; aucun dossier legacy, copie de secours de code ou flag de retour.
- Pour une UI partagée utilisée par un autre consommateur : aucun usage résiduel depuis Studio ; suppression globale seulement après traitement autorisé des autres consommateurs.
- Nouveaux widgets dans presentation/rebuilt et nouvelles primitives dans le design system ; les chemins proposés sont ajustables sans élargir la portée ni réutiliser l’ancienne composition.
- Le renderer, Flutter, les codecs et les contrats ne sont pas l’UI d’éditeur à supprimer ; leurs wrappers/panneaux historiques le sont.
- Le jalon hôte neutre est un arrêt technique de développement, pas une version utilisateur à publier.

**Protections :**

- apps/avelune_studio/lib/features/**/application et domain, hors extraction ciblée de logique UI
- packages/map_core, map_gameplay, map_battle, map_authoring : contrats et mécaniques
- packages/map_runtime et providers de rendu : consommation et simulation
- Données de projets/maps/assets/exports/saves et lecteurs compatibles
- Horloges host, révisions, writers canoniques, budgets incrémentaux, barrels publics

### 27.2 Références et priorité

La demande du 9 novembre remplace les consignes antérieures de conserver/harmoniser des écrans ou de prendre librement des écarts visuels. Les anciens statuts prouvent éventuellement du fonctionnel, jamais l’acceptation visuelle de cette nouvelle UI.

- Une référence existante doit être liée et approuvée pour l’état/profil ciblé avant reconstruction.
- Une fiche guide et une preuve de défaut ne suffisent jamais comme cible.
- La 2D n’est pas validée par une capture de la 3D ; les contrôles communs peuvent partager une cible de chrome approuvée, avec cible de canevas 2D distincte.
- Aucune ancienne UI ne sert de fallback pour une maquette manquante.

Les 416 captures du 9 novembre et 195 références non historiques du 6 novembre sont réunies ici : 611 références. Les 54 fiches d’aide restent descriptives et les 15 captures d’audit restent des preuves de défaut. RUI-003 complète Pokémon, Histoire détaillée, régional, cinématiques/présentations, erreurs/récupération et les variantes 2D. Une cible manquante bloque la reconstruction concernée ; aucun ancien écran ne sert de secours.

### 27.3 Portes et ordre

| Porte | Lot | Condition |
| --- | --- | --- |
| G0 | RUI-010 | Zéro ancienne UI Studio et fonctionnel protégé |
| G1 | RUI-088 | Nouvelle UI complète, deux profils et preuves à jour |

Ordre initial strict de RUI-001 à RUI-088. Une parallélisation future exige une modification explicite des dépendances, contrats stabilisés, propriétaires de fichiers distincts et aucune violation de G0.

| Thématique | Phase | Lots |
| --- | --- | --- |
| T00 — Périmètre, références et contrat de contrôle | Préparation sans nouvelle UI | RUI-001, RUI-002, RUI-003, RUI-004 |
| T01 — Retrait intégral de l’ancienne UI | Retrait avant toute reconstruction | RUI-005, RUI-006, RUI-007, RUI-008, RUI-009, RUI-010 |
| T02 — Nouveau design system et nouveau shell | Reconstruction après G0 | RUI-011, RUI-012, RUI-013, RUI-014, RUI-015, RUI-016 |
| T03 — Sessions, accueil et gestion des cartes | Reconstruction | RUI-017, RUI-018, RUI-019, RUI-020, RUI-021, RUI-022 |
| T04 — Sélection, contenu et historique d’édition | Reconstruction | RUI-023, RUI-024, RUI-025, RUI-026, RUI-027 |
| T05 — Bibliothèque, import et ateliers de ressources | Reconstruction | RUI-028, RUI-029, RUI-030, RUI-031, RUI-032, RUI-033, RUI-034, RUI-035 |
| T06 — Construction native 2D et 3D | Reconstruction | RUI-036, RUI-037, RUI-038, RUI-039, RUI-040, RUI-041, RUI-042, RUI-043, RUI-044 |
| T07 — Règles de jeu sur la carte | Reconstruction | RUI-045, RUI-046, RUI-047, RUI-048, RUI-049, RUI-050, RUI-051 |
| T08 — Scénario de carte et comportements | Reconstruction | RUI-052, RUI-053, RUI-054, RUI-055, RUI-056, RUI-057 |
| T09 — Ambiance de carte | Reconstruction | RUI-058, RUI-059, RUI-060, RUI-061, RUI-062 |
| T10 — Réglages globaux et carte régionale | Reconstruction | RUI-063, RUI-064, RUI-065, RUI-066, RUI-067 |
| T11 — Histoire scènes et contenu narratif global | Reconstruction | RUI-068, RUI-069, RUI-070, RUI-071, RUI-072, RUI-073, RUI-074 |
| T12 — Pokémon et données de jeu | Reconstruction | RUI-075, RUI-076, RUI-077, RUI-078, RUI-079 |
| T13 — Vérification test et export | Reconstruction | RUI-080, RUI-081, RUI-082, RUI-083 |
| T14 — Recette finale et clôture du remplacement | Acceptation globale | RUI-084, RUI-085, RUI-086, RUI-087, RUI-088 |

### 27.4 Contrat de fidélité et rejet

Chaque état requis doit obtenir **au moins 95/100 dans chacun des deux profils** : structure 40, typographie 15, espacements 15, contrôles 15, états 15. Revue par Yoahn ou réviseur distinct de l’implémenteur. Aucun score moyen ne compense un écran raté.

Seuils : déplacement de structure <=8 px logiques ; erreur de largeur de panneau <=2 % ; différence de taille de texte <=1 px logique ; différence d’espacement <=4 px logiques. Une adaptation intentionnelle modifie d’abord une cible approuvée.

**Refus sans tolérance :**

- Panneau, contrôle, état ou parcours requis manquant
- Action différente ou simulée alors que le contrat attend le moteur réel
- Ancienne UI ou fallback historique utilisé par le nouveau Studio
- Preuve manquante, périmée, modifiée, mauvais état/profil ou référence non approuvée
- Donnée perdue, sauvegarde fausse, dépendance cassée, verrou ignoré
- Version 2D validée par capture 3D ou capacité fictivement activée

**Comparaison :**

1. Reproduire les mêmes données et le même état ; viewport logique et DPR identiques, échelle apparente égale.
2. Conserver référence et capture native plein cadre, non recadrées ; noms et empreintes de fichier.
3. Comparer côte à côte puis en superposition à opacité réglable, avec contour des panneaux et mesures.
4. Contrôler séparément chrome UI et contenu de carte : un moteur différent ne justifie pas l’absence d’objets, chemins, bords ou eau.
5. Masquer uniquement les données réellement variables documentées (horloge système, identifiant de run), jamais un contrôle ou une géométrie gênants.
6. Le score est une revue argumentée ; pixel-diff/SSIM peuvent aider mais ne décident pas seuls.
7. Refuser si un seul état ou profil reste sous seuil ; aucun score moyen entre écrans ne compense une erreur.
8. Tout écart intentionnel modifie d’abord une cible approuvée et sa révision, puis une nouvelle tentative est évaluée.

**Après rejet :** garder preuves, mesures et motif ; corriger le lot ; recapturer/rejouer les cas affectés ; soumettre une nouvelle tentative. Le rejet bloque les dépendants. Un build vert ne vaut pas acceptation visuelle.

### 27.5 Mise à jour durable

1. Avant un lot : relever HEAD/status, relire ses propriétaires, baselines et dépendances ; attribuer l’implémenteur.
2. Au démarrage : execution.status=in_progress dans ui-replacement-plan.json et régénération du plan/artefact.
3. À chaque tentative : copier les vrais screenshots/logs depuis QA vers proofs/<lot>/<attempt>/<profile>/ ; remplir un reçu avec empreintes et mesures.
4. Vérifier le reçu par update_plan.py record --lot <id> --receipt <fichier> --emit-patch ; appliquer son patch avec l’outil natif d’édition.
5. Après mise à jour du JSON canonique : update_plan.py render --emit-patch ; appliquer le patch puis update_plan.py validate.
6. Un import JSON dans l’artefact est une consultation/brouillon en mémoire ; exporter le JSON ne met pas automatiquement le dépôt à jour.
7. Conserver les essais rejetés et le motif ; ne mettre accepted qu’après revue et contrôle de toutes les preuves.
8. Après nettoyage QA, seules les copies durables de proofs font foi ; aucun lien vers un temporaire supprimé.
9. Si un changement de code ou de référence rend une preuve obsolète : update_plan.py invalidate --lot ID --reason MOTIF --emit-patch ; appliquer, puis régénérer. Les lots dépendants déjà exécutés sont rouverts.

~~~bash
python3 documentation/reports/avelune_studio/plans/2026-11-09-constructeur-cartes/update_plan.py validate
python3 documentation/reports/avelune_studio/plans/2026-11-09-constructeur-cartes/update_plan.py record --lot RUI-001 --receipt documentation/reports/avelune_studio/plans/2026-11-09-constructeur-cartes/proofs/RUI-001/attempt-001/receipt.json --emit-patch
python3 documentation/reports/avelune_studio/plans/2026-11-09-constructeur-cartes/update_plan.py render --target readme --emit-patch
python3 documentation/reports/avelune_studio/plans/2026-11-09-constructeur-cartes/update_plan.py render --target html --emit-patch
~~~

record/render émettent un patch à appliquer par l’outil natif d’édition ; relancer validate ensuite. La commande record ci-dessus ne s’exécute qu’après création du vrai reçu futur à ce chemin. invalidate --lot ID --reason MOTIF --emit-patch rouvre un lot et ses dépendants après changement ; les anciennes tentatives restent conservées. L’import dans la page est un brouillon tant que le JSON du dossier n’est pas remplacé et l’artefact régénéré.

Le vérificateur contrôle empreintes, dépendances, scores, mesures et complétude. Il ne prouve pas qu’une mesure déclarée est honnête : la revue visuelle et les vrais scénarios restent obligatoires.

### 27.6 Index des lots — détails complets dans l’artefact et le JSON

**Avancement vérifié :** 2026-11-09T23:43:44.898789+00:00 ; G0 non accepté.

- Caractérisations avant extraction (9 fichiers) : 62 tests, sortie 0.
- Hôte neutre, lifecycle, updates, MCP, fermeture, édition injectée 2D/3D et contrôleur G0 initial : 37 tests, sortie 0.
- Workflows sauvegarde/fermeture/lancement et contrats personnages/Pokémon/présentations/import : 39 tests, sortie 0.
- Sessions carte, connexions source/cible, projections et durée de vie des previews : 60 tests, sortie 0.
- Contrôleur G0 et racines consommateurs, avant extension Unys : 19 tests, sortie 0.
- Export contrôleur réel, installation hors source, déplacement/dialogue/warp Player : 1 tests, sortie 0.
- Accueil : contrôleurs réels ouverture et maintenance, après correction fixture création : 37 tests, sortie 0.
- Création/Session : 44 cas données et 8 parcours surface, ressources, Player et export : 52 tests, sortie 0.
- Monde, récompenses quotidiennes, Vérification et consultation sans analyse implicite : 50 tests, sortie 0.
- Metadata ressources, refus de revision, absence de carte et sources compatibles : 8 tests, sortie 0.
- Armement terrains et matériaux via sessions et viewport technique : 4 tests, sortie 0.
- Régression sessions et viewports neutres avec correction Échap : 84 tests, sortie 0.
- Suppression clavier via session et viewport neutres : 6 tests, sortie 0.
- Contrôleur G0, racines consommateurs et dérive inventaire : 28 tests, sortie 0.
- Événements : édition5, gardes playtest9, templates13 et simulation7 ; parcours métier sans ancien widget : 34 tests, sortie 0.
- Publication guidée par workflow extrait : vrai adapter, carte et événement mis à jour : 1 tests, sortie 0.
- Carte : régression native logicielle complète après correction des fixtures : 26 tests, sortie 0.
- Navigation des sources d’événement sans ancien panneau : 6 tests, sortie 0.
- Conteneurs Ressources : véritables publications, refus et relecture : 4 tests, sortie 0.
- Terrain : 11 cas de viewport/parser/scratch puis publication canonique isolée corrigée : 12 tests, sortie 0.

**Limites :** G0 non accepté : widgets historiques, tests et consommateurs en cours de retrait/migration.; Aucun lot accepté ; prérequis T00 non acceptés.; Build Release isolé et hôte neutre observé avec moteur QA corrigé ; ne prouve pas les derniers viewports ni des parcours natifs complets 2D/3D.; MCP natif non connecté dans le bundle isolé (distribution.manifest_unavailable) ; tests lifecycle MCP distincts réussis.; Aucune écriture Git, publication ni modification de mécanique runtime réalisée par T01.; Capture durable de l’hôte vide et du suivi documentaire uniquement ; captures/mesures par état et par profil de lot encore à produire, aucun score inventé..

- [after-extraction-before-workflow.log](proofs/t01-execution/after-extraction-before-workflow.log)
- [artefact-t01-progress.jpg](proofs/t01-execution/artefact-t01-progress.jpg)
- [before-characterization.log](proofs/t01-execution/before-characterization.log)
- [dependency-resource-HEAD-receipt.json](proofs/t01-execution/dependency-resource-HEAD-receipt.json)
- [dependency-resource-HEAD-tests-ready.log](proofs/t01-execution/dependency-resource-HEAD-tests-ready.log)
- [global-playtest-batch1-tests.log](proofs/t01-execution/global-playtest-batch1-tests.log)
- [global-playtest-newgame-HEADbaseline2.log](proofs/t01-execution/global-playtest-newgame-HEADbaseline2.log)
- [hub-controller-export-player.log](proofs/t01-execution/hub-controller-export-player.log)
- [native-engine-receipt.json](proofs/t01-execution/native-engine-receipt.json)
- [native-neutral-host-observation.json](proofs/t01-execution/native-neutral-host-observation.json)
- [native-neutral-host.jpg](proofs/t01-execution/native-neutral-host.jpg)
- [native-neutral-host.log](proofs/t01-execution/native-neutral-host.log)
- [native-release-build.log](proofs/t01-execution/native-release-build.log)
- [neutral-host-and-extraction.log](proofs/t01-execution/neutral-host-and-extraction.log)
- [sessions-and-projections.log](proofs/t01-execution/sessions-and-projections.log)
- [workflow-and-contracts.log](proofs/t01-execution/workflow-and-contracts.log)
- [creation-session-creator-isolated.log](proofs/t01-execution/creation-session-creator-isolated.log)
- [creation-session-final-analyze.log](proofs/t01-execution/creation-session-final-analyze.log)
- [creation-session-native-batch3.log](proofs/t01-execution/creation-session-native-batch3.log)
- [creation-session-pure-batch1.log](proofs/t01-execution/creation-session-pure-batch1.log)
- [creation-session-retirement-ledger.json](proofs/t01-execution/creation-session-retirement-ledger.json)
- [dependency-g0-drift.log](proofs/t01-execution/dependency-g0-drift.log)
- [dependency-resource-metadata-sources-receipt.json](proofs/t01-execution/dependency-resource-metadata-sources-receipt.json)
- [dependency-resource-metadata-sources.log](proofs/t01-execution/dependency-resource-metadata-sources.log)
- [dependency-terrain-arm-material-receipt.json](proofs/t01-execution/dependency-terrain-arm-material-receipt.json)
- [dependency-terrain-arm-material.log](proofs/t01-execution/dependency-terrain-arm-material.log)
- [home-creator-alone2.log](proofs/t01-execution/home-creator-alone2.log)
- [home-dart-analysis-final.log](proofs/t01-execution/home-dart-analysis-final.log)
- [home-retirement-ledger.json](proofs/t01-execution/home-retirement-ledger.json)
- [home-tests-batch1.log](proofs/t01-execution/home-tests-batch1.log)
- [keyboard-delete-neutral-decoupled.log](proofs/t01-execution/keyboard-delete-neutral-decoupled.log)
- [viewport-session-neutral-regression.log](proofs/t01-execution/viewport-session-neutral-regression.log)
- [world-verification-retirement-ledger.json](proofs/t01-execution/world-verification-retirement-ledger.json)
- [world-verification-retirement.log](proofs/t01-execution/world-verification-retirement.log)
- [dependency-resource-containers-receipt.json](proofs/t01-execution/dependency-resource-containers-receipt.json)
- [dependency-resource-containers.log](proofs/t01-execution/dependency-resource-containers.log)
- [dependency-terrain-publication-canonical.log](proofs/t01-execution/dependency-terrain-publication-canonical.log)
- [dependency-terrain-publication-fixed.log](proofs/t01-execution/dependency-terrain-publication-fixed.log)
- [dependency-terrain-semantic-receipt.json](proofs/t01-execution/dependency-terrain-semantic-receipt.json)
- [dependency-terrain-semantic.log](proofs/t01-execution/dependency-terrain-semantic.log)
- [event-guided-publisher-one.log](proofs/t01-execution/event-guided-publisher-one.log)
- [event-simulation-seven.log](proofs/t01-execution/event-simulation-seven.log)
- [events-editing-template-playtest.log](proofs/t01-execution/events-editing-template-playtest.log)
- [events-retirement-ledger.json](proofs/t01-execution/events-retirement-ledger.json)
- [map-catalogue-lifecycle-native16.log](proofs/t01-execution/map-catalogue-lifecycle-native16.log)
- [map-catalogue-lifecycle-native16.terminated.json](proofs/t01-execution/map-catalogue-lifecycle-native16.terminated.json)
- [map-event-source-navigation6.command.json](proofs/t01-execution/map-event-source-navigation6.command.json)
- [map-event-source-navigation6.log](proofs/t01-execution/map-event-source-navigation6.log)
- [map-native-regression26.command.json](proofs/t01-execution/map-native-regression26.command.json)
- [map-native-regression26.log](proofs/t01-execution/map-native-regression26.log)
- [standard-event-lock-and-templates-green.log](proofs/t01-execution/standard-event-lock-and-templates-green.log)
- [standard-event-lock-red.log](proofs/t01-execution/standard-event-lock-red.log)
- [standard-event-working-publication-isolated.log](proofs/t01-execution/standard-event-working-publication-isolated.log)
- [ui02-native-instrumented.log](proofs/t01-execution/ui02-native-instrumented.log)
- [before-characterization-provenance.json](proofs/t00-preparation/before-characterization-provenance.json)
- [t00-current-witness-preparation-summary.json](proofs/t00-preparation/t00-current-witness-preparation-summary.json)
- [dependency-rui004-fingerprint-fix-receipt.json](proofs/t00-preparation/dependency-rui004-fingerprint-fix-receipt.json)
- [current-witness-authoring-checkpoint.json](proofs/t00-preparation/current-witness-authoring-checkpoint.json)
- [Contrôle ciblé avant commit T01 — statut partiel](proofs/t01-execution/precommit-check-20261110.json)

### T00 — Périmètre, références et contrat de contrôle

**Phase :** Préparation sans nouvelle UI. Geler la cible et les protections avant la première suppression ; distinguer préparation du plan et réalisation native.

<a id="rui-001"></a>
#### RUI-001 — Geler le périmètre et l’inventaire de retrait

**Statut :** in_progress. **Dépendances :** aucune.

**Objectif :** Établir la liste exhaustive des UI Studio à retirer, y compris celles hors presentation et celles importées depuis map_editor.

**2D :** Inclure éditeur de tuiles, canvas et ateliers 2D.

**3D :** Inclure viewport spatial, réglages et ateliers 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-001). 5 étapes ; 2 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

**Avancement :** Rattrapage : les 992 empreintes historiques ont été retrouvées et comparées. Proposition de classement enrichie en revue ; consommateurs externes à conserver explicitement. G0 actuel reste rouge, aucun retrait supplémentaire autorisé pendant le rattrapage.

<a id="rui-002"></a>
#### RUI-002 — Caractériser et protéger le fonctionnel existant

**Statut :** in_progress. **Dépendances :** RUI-001.

**Objectif :** Séparer une ancienne implémentation UI d’un comportement métier à conserver.

**2D :** Projet réellement 2D avec tuiles, collisions, passage et scène.

**3D :** Projet réellement 3D avec surfaces, Border, pente, modèle et passage.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-002). 5 étapes ; 2 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

**Avancement :** Deux témoins actuels 2D/3D préparés : deux tests réussis, lecteur canonique et ressources vérifiés, originaux inchangés. Authoring3D attempt2 arrêté exit1 après trois imports GLB et publication du blueprint ; carte inchangée, aucun Border/pente nouveau. Mauvais choix de lecteur dans le harness à corriger. Native/export/Player/reprise non exécutés ; aucune reconstitution AVANT.

<a id="rui-003"></a>
#### RUI-003 — Compléter et approuver les cibles visuelles 2D et 3D

**Statut :** in_progress. **Dépendances :** RUI-002.

**Objectif :** Ne reconstruire aucun écran sans états cibles utilisables pour la comparaison.

**2D :** Les contrôles 2D ne sont pas une capture 3D renommée ; l’absence de capacité est expliquée.

**3D :** Les surfaces, parois, pentes, caméra et sources restent représentées.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-003). 6 étapes ; 2 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

**Avancement :** 611 sources recensées : 542 références existantes, 54 guides, 15 défauts. Les 782 couples lot/état/profil non documentaires restent sans liaison approuvée. Les variantes 2D et les modules encore réduits à des guides doivent être complétés avant reconstruction.

<a id="rui-004"></a>
#### RUI-004 — Activer le registre des lots et des preuves

**Statut :** in_progress. **Dépendances :** RUI-003.

**Objectif :** Faire de l’artefact le contrôle de passage des lots, avec état canonique et historique des refus.

**2D :** Volet et verdict 2D distincts.

**3D :** Volet et verdict 3D distincts.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-004). 6 étapes ; 2 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

**Avancement :** Correctif du vérificateur : empreintes fournies contrôlées aussi pour les lots documentaires ; codeFiles obligatoire pour evidence_framework. Dix tests de régression réussis avec revue indépendante du correctif ; pas de validation native revendiquée. Le contrôleur de reçus ne remplace pas le contrôle G0 réel.

### T01 — Retrait intégral de l’ancienne UI

**Phase :** Retrait avant toute reconstruction. Premier changement du produit : retirer toutes les compositions Studio, sans fallback historique ; conserver seulement les contrats et moteurs protégés.

<a id="rui-005"></a>
#### RUI-005 — Extraire les responsabilités non visuelles des fichiers mixtes

**Statut :** blocked. **Dépendances :** RUI-004.

**Objectif :** Préserver la logique aujourd’hui hébergée près des widgets avant leur suppression.

**2D :** Conserver décodage atlas et documents de tuiles.

**3D :** Conserver services de rendu, buffers, modèles et indépendance du provider.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-005). 5 étapes ; 2 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

**Avancement :** Contrats, sessions, workflows et viewports extraits. Accueil/Création/Monde/Vérification vérifiés ; Événements guidés/simulation/playtest séparés, Personnages vérifiés et Pokémon en extraction. Autres ateliers encore à migrer.

<a id="rui-006"></a>
#### RUI-006 — Détacher toutes les routes de l’ancien Studio

**Statut :** blocked. **Dépendances :** RUI-005.

**Objectif :** Le binaire de développement ne monte plus aucune ancienne destination.

**2D :** L’hôte sait charger la session 2D pour tests sans ancienne interface.

**3D :** L’hôte sait ouvrir les services 3D pour tests sans panneau spatial historique.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-006). 5 étapes ; 2 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

**Avancement :** Entrée principale neutre compilée et observée en Release QA isolé. Accueil et Création/Session retirés physiquement ; consommateurs Hub/Unys et profils natifs complets encore à fermer.

<a id="rui-007"></a>
#### RUI-007 — Supprimer les anciennes UI de carte et de construction

**Statut :** blocked. **Dépendances :** RUI-006.

**Objectif :** Retirer physiquement les widgets de palette, canevas d’édition, inspecteurs et panneaux de carte.

**2D :** Retirer aussi les palettes, couches et outils de tuiles historiques.

**3D :** Retirer aussi gizmos/panneaux d’édition historiques ; ne pas supprimer le renderer.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-007). 5 étapes ; 2 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

**Avancement :** Sessions et surfaces techniques 2D/3D, régression26 verte et navigation sources6 verte. Catalogue16 interrompu honnêtement pour diagnostic ; compositions Carte et consommateurs mixtes encore à retirer.

<a id="rui-008"></a>
#### RUI-008 — Supprimer les anciennes UI globales et spécialisées

**Statut :** blocked. **Dépendances :** RUI-007.

**Objectif :** Retirer Accueil, Ressources, Histoire, Pokémon, Réglages, Test, Export, ateliers et dialogues historiques.

**2D :** Aucun atelier/image/donnée 2D ancien conservé comme raccourci.

**3D :** Aucun atelier/modèle/preview 3D ancien conservé comme écran de remplacement.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-008). 5 étapes ; 2 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

**Avancement :** Accueil7, Création/Session10, Monde8 et Vérification6 retirés. Trois UI Événements retirées après34 cas de comportement et publisher réel ; Ressources/Personnages en retrait coordonné. Aucun atelier reconstruit.

<a id="rui-009"></a>
#### RUI-009 — Retirer les primitives et ponts UI historiques de Studio

**Statut :** blocked. **Dépendances :** RUI-008.

**Objectif :** Le retrait inclut wrappers, thème d’écran et imports partagés qui réintroduisent une interface ancienne.

**2D :** Aucune ancienne composition editor_shell_page ou panneau 2D dans Studio.

**3D :** Aucun wrapper historique de preview spatiale avec chrome réutilisé.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-009). 5 étapes ; 2 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

**Avancement :** Chrome Player retiré ; douze exceptions techniques exactes et revues, dont nouvelle surface terrain. Primitives/exports historiques encore présents ; bibliothèques externes protégées.

<a id="rui-010"></a>
#### RUI-010 — Passer la porte G0 zéro ancienne UI

**Statut :** blocked. **Dépendances :** RUI-009.

**Objectif :** Interdire toute reconstruction avant preuve du retrait intégral.

**2D :** Ouverture/lecture 2D sans ancienne UI et sans mutation de projet.

**3D :** Ouverture/lecture 3D et disponibilité du service de rendu sans ancienne UI.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-010). 5 étapes ; 3 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

**Avancement :** G0 toujours non accepté. Outillage28cas vérifiés avant correction package:/file: révélée par probes compiler ; inventaire/ledgers/preuves mis à jour, aucun score visuel ou lot accepté.

### T02 — Nouveau design system et nouveau shell

**Phase :** Reconstruction après G0. Recréer les fondations visuelles, puis les brancher aux capacités existantes.

<a id="rui-011"></a>
#### RUI-011 — Créer les nouveaux tokens et règles visuelles

**Statut :** planned. **Dépendances :** RUI-010.

**Objectif :** Traduire les références approuvées en palette, typographie, espacements, rayons, tailles et états sémantiques.

**2D :** Mêmes tokens et hiérarchie sur le chrome 2D.

**3D :** Mêmes tokens, sans thème concurrent du provider 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-011). 4 étapes ; 2 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-012"></a>
#### RUI-012 — Créer les nouveaux composants et champs

**Statut :** planned. **Dépendances :** RUI-011.

**Objectif :** Fournir les primitives réutilisables des maquettes avant les écrans métier.

**2D :** Vignettes sprites/atlas nettes à leur échelle.

**3D :** Vignettes modèles et presets dans les mêmes cadres.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-012). 4 étapes ; 2 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-013"></a>
#### RUI-013 — Reconstruire le shell et les huit destinations

**Statut :** planned. **Dépendances :** RUI-012.

**Objectif :** Recréer une navigation globale stable sans réutiliser l’ancien shell.

**2D :** Le shell porte le profil 2D réel.

**3D :** Le shell porte le profil 3D réel sans modifier un autre projet.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-013). 5 étapes ; 4 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-014"></a>
#### RUI-014 — Reconstruire le cadre de carte et les panneaux

**Statut :** planned. **Dépendances :** RUI-013.

**Objectif :** Réaliser colonnes, onglets, inspecteur et barre de vue des quatre espaces.

**2D :** Canevas 2D occupant la même zone utile ; outils incompatibles absents ou explicités.

**3D :** Canevas 3D même chrome, caméra de travail distincte de caméra du jeu.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-014). 5 étapes ; 3 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-015"></a>
#### RUI-015 — Brancher commandes et raccourcis communs

**Statut :** planned. **Dépendances :** RUI-014.

**Objectif :** Une action a une seule commande et un état de disponibilité commun.

**2D :** Raccourcis des tuiles uniquement en contexte 2D.

**3D :** Raccourcis de vue 3D sans intercepter le texte ni les autres espaces.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-015). 5 étapes ; 3 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-016"></a>
#### RUI-016 — Reconstruire dialogues et feedback global

**Statut :** planned. **Dépendances :** RUI-015.

**Objectif :** Uniformiser confirmations, chargements, erreurs, notices et retours de focus.

**2D :** Erreurs de lecture d’images/atlas.

**3D :** Erreurs de modèle/provider sans perte de scène ni projet.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-016). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

### T03 — Sessions, accueil et gestion des cartes

**Phase :** Reconstruction. Restaurer les parcours projet et carte sur la nouvelle UI.

<a id="rui-017"></a>
#### RUI-017 — Reconstruire l’accueil et la reprise de projet

**Statut :** planned. **Dépendances :** RUI-016.

**Objectif :** Un prochain objectif utile, projets récents et accès directs aux données réelles.

**2D :** Reprise d’un projet et d’une carte 2D.

**3D :** Reprise d’un projet 3D sans démarrer tous les previews à l’accueil.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-017). 4 étapes ; 4 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-018"></a>
#### RUI-018 — Reconstruire création et choix du profil projet

**Statut :** planned. **Dépendances :** RUI-017.

**Objectif :** Le choix 2D/3D intervient à la création sans conversion silencieuse.

**2D :** Créer un vrai projet 2D et une première carte éditable.

**3D :** Créer un vrai projet 3D et une première carte spatiale éditable.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-018). 4 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-019"></a>
#### RUI-019 — Reconstruire ouverture et récupération de session

**Statut :** planned. **Dépendances :** RUI-018.

**Objectif :** Conserver originaux, révisions, brouillons et diagnostics de reprise.

**2D :** Relecture des documents et médias 2D.

**3D :** Relecture des profils visuels/modèles 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-019). 4 étapes ; 4 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-020"></a>
#### RUI-020 — Reconstruire catalogue et navigation des cartes

**Statut :** planned. **Dépendances :** RUI-019.

**Objectif :** Combiner recherche rapide et arborescence utilisable sur un grand projet.

**2D :** Plans et vignettes réels des cartes 2D.

**3D :** Vignettes/aperçus réels des cartes 3D, placeholders de chargement explicites.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-020). 4 étapes ; 3 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-021"></a>
#### RUI-021 — Reconstruire cycle de vie des cartes

**Statut :** planned. **Dépendances :** RUI-020.

**Objectif :** Création, nom/dossier, copie et suppression protégée sur vrais contrats.

**2D :** Copie des couches, tuiles et paramètres de carte 2D.

**3D :** Copie des surfaces, Borders, environnements et paramètres de carte 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-021). 5 étapes ; 4 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-022"></a>
#### RUI-022 — Reconstruire géométrie et règles locales de carte

**Statut :** planned. **Dépendances :** RUI-021.

**Objectif :** Éditer dimensions, zone jouable, extérieur et règles de lieu avec analyse de dépendances.

**2D :** Règles locales et Corde Sortie seulement si capacités natives l’autorisent.

**3D :** Règles 3D réelles, aucune Corde Sortie fictivement active.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-022). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

### T04 — Sélection, contenu et historique d’édition

**Phase :** Reconstruction. Unifier les identités et validations au lieu de reproduire plusieurs chemins divergents.

<a id="rui-023"></a>
#### RUI-023 — Reconstruire le modèle de sélection et d’intention

**Statut :** planned. **Dépendances :** RUI-022.

**Objectif :** Une identité de sélection commune à l’espace, au canevas, à Contenu et à l’inspecteur.

**2D :** Sélection de tuile/objet/zone par coordonnées 2D.

**3D :** Sélection de modèle/surface/Border par identité native.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-023). 4 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-024"></a>
#### RUI-024 — Unifier géométrie verrouillages et dépendances

**Statut :** planned. **Dépendances :** RUI-023.

**Objectif :** Corriger L01/L03/L09 dans tous les chemins de mutation.

**2D :** Même précision sur carte rectangulaire et couches 2D.

**3D :** Même propriété spatiale, y compris surface et décor extérieur 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-024). 5 étapes ; 3 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-025"></a>
#### RUI-025 — Reconstruire Contenu et localisation

**Statut :** planned. **Dépendances :** RUI-024.

**Objectif :** Retrouver tout élément réel, y compris masqué, superposé ou non spatial.

**2D :** Inclure objets, couches et zones réellement présents en 2D.

**3D :** Inclure modèles, traits, Borders, pentes et environnements 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-025). 4 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-026"></a>
#### RUI-026 — Reconstruire opérations simples et groupées

**Statut :** planned. **Dépendances :** RUI-025.

**Objectif :** Déplacer, dupliquer et supprimer depuis une seule frontière transactionnelle.

**2D :** Copie d’objets et interactions/couches 2D.

**3D :** Copie de modèles et interactions/spatial traits 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-026). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-027"></a>
#### RUI-027 — Reconstruire calques visibilité et ordre

**Statut :** planned. **Dépendances :** RUI-026.

**Objectif :** Séparer organisation de travail, verrouillage et comportement dans le jeu.

**2D :** Ne pas confondre calque d’organisation et couche de tuiles rendue.

**3D :** Ne pas confondre ordre de travail et profondeur géométrique.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-027). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

### T05 — Bibliothèque, import et ateliers de ressources

**Phase :** Reconstruction. Recréer les écrans globaux de ressources et leurs ateliers sans perdre les services de catalogue.

<a id="rui-028"></a>
#### RUI-028 — Reconstruire bibliothèque projet et recherche contextuelle

**Statut :** planned. **Dépendances :** RUI-027.

**Objectif :** Le catalogue complet reste accessible depuis toute carte, même si elle n’utilise pas encore la ressource.

**2D :** Afficher les images/tilesets et ressources autorisées en 2D.

**3D :** Afficher modèles, surfaces et presets autorisés en 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-028). 5 étapes ; 7 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-029"></a>
#### RUI-029 — Reconstruire usages remplacement et suppression de ressource

**Statut :** planned. **Dépendances :** RUI-028.

**Objectif :** Les mutations de définition partagée montrent et protègent leurs consommateurs.

**2D :** Compatibilité dimensions/atlas/animations des sprites et tilesets.

**3D :** Compatibilité modèles/materials/presets et usages spatiaux.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-029). 6 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-030"></a>
#### RUI-030 — Reconstruire import et publication de packs

**Statut :** planned. **Dépendances :** RUI-029.

**Objectif :** Montrer préflight, adoption, conflits et publication depuis les services existants.

**2D :** Image, atlas, sprite et pack de ressources 2D.

**3D :** Modèle GLB/GLTF et pack 3D selon formats réellement supportés.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-030). 5 étapes ; 6 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-031"></a>
#### RUI-031 — Reconstruire ateliers décor 2D et modèle 3D

**Statut :** planned. **Dépendances :** RUI-030.

**Objectif :** Modifier une définition de ressource via un atelier neuf, pas une instance de carte.

**2D :** Découpage image, ancrage, animation de sprite et collision 2D.

**3D :** Pivot, échelle de définition, collision, animation et ombres du modèle 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-031). 5 étapes ; 6 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-032"></a>
#### RUI-032 — Reconstruire atelier terrain et raccords

**Statut :** planned. **Dépendances :** RUI-031.

**Objectif :** Préparer matériaux, motifs et pièces utilisés par les gestes natifs.

**2D :** Raccords et motifs de tuiles/Paths en 2D.

**3D :** Matériaux et surfaces de sommet compatibles relief/pente en 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-032). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-033"></a>
#### RUI-033 — Reconstruire atelier Border

**Statut :** planned. **Dépendances :** RUI-032.

**Objectif :** Éditer pièces de contour, angles et franchissements avec leur propriétaire natif.

**2D :** Contours et franchissements 2D uniquement selon capacités existantes.

**3D :** Parois, berges et falaises 3D avec niveaux et raccords.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-033). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-034"></a>
#### RUI-034 — Reconstruire atelier Environnement

**Statut :** planned. **Dépendances :** RUI-033.

**Objectif :** Définir un preset génératif réutilisable sans confondre preset et zone appliquée.

**2D :** Distribution de ressources 2D complètes.

**3D :** Distribution de modèles/arbres 3D complets.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-034). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-035"></a>
#### RUI-035 — Reconstruire atelier Personnage

**Statut :** planned. **Dépendances :** RUI-034.

**Objectif :** Préparer apparence et animations réutilisables, séparées du PNJ et de ses comportements.

**2D :** Sprites, atlas et directions 2D ; pixels préservés.

**3D :** Apparence/modèle animé 3D seulement lorsque le pipeline natif le supporte.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-035). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

### T06 — Construction native 2D et 3D

**Phase :** Reconstruction. Les familles visibles pilotent des gestes et données natifs ; pas de décor figé simulant une carte éditable.

<a id="rui-036"></a>
#### RUI-036 — Reconstruire les viewports et transformations de coordonnées

**Statut :** planned. **Dépendances :** RUI-035.

**Objectif :** Remplacer le wrapper UI tout en branchant les moteurs 2D/3D existants.

**2D :** Rendu réel en 2D, couches et atlas correctement alignés.

**3D :** Rendu provider 3D réel, projection et picking cohérents avec le host.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-036). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-037"></a>
#### RUI-037 — Reconstruire placement et transformation des décors

**Statut :** planned. **Dépendances :** RUI-036.

**Objectif :** Créer et déplacer des instances réelles, y compris par glisser direct.

**2D :** Décor image/sprite, ancrage, ordre et collision 2D.

**3D :** Modèle 3D, rotation/échelle et collision natives.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-037). 5 étapes ; 6 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-038"></a>
#### RUI-038 — Reconstruire peinture des sols et couche de tuiles

**Statut :** planned. **Dépendances :** RUI-037.

**Objectif :** Conserver l’édition 2D native tout en proposant une entrée Sols commune.

**2D :** Tuiles/couches/autotiles réellement écrites et consommées.

**3D :** Surfaces de terrain et matériaux natifs.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-038). 5 étapes ; 6 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-039"></a>
#### RUI-039 — Reconstruire chemins et raccords

**Statut :** planned. **Dépendances :** RUI-038.

**Objectif :** Offrir des chemins identifiables avec segments, virages, jonctions et largeur.

**2D :** Paths/autotiles natifs, pas de patchs image indépendants.

**3D :** Surface de chemin native et raccord avec sommet/relief.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-039). 5 étapes ; 6 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-040"></a>
#### RUI-040 — Reconstruire eau et rivages

**Statut :** planned. **Dépendances :** RUI-039.

**Objectif :** Une famille Eau distincte pilote une surface native, avec déplacement configuré ailleurs.

**2D :** Eau et rives 2D natives ; pas de faux niveau 3D.

**3D :** Eau/surface et Border de rive 3D rééditables.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-040). 5 étapes ; 4 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-041"></a>
#### RUI-041 — Reconstruire reliefs parois et Borders

**Statut :** planned. **Dépendances :** RUI-040.

**Objectif :** Ressource de paroi et surface de sommet restent visibles ensemble.

**2D :** Contours/ledges natifs si supportés ; niveau géométrique indisponible expliqué.

**3D :** Relief et paroi Border natifs, niveaux et normales corrects.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-041). 5 étapes ; 6 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-042"></a>
#### RUI-042 — Reconstruire pentes et transitions de niveaux

**Statut :** planned. **Dépendances :** RUI-041.

**Objectif :** Une pente est une géométrie orientée, distincte de sa texture.

**2D :** Si ramp non supporté, état de capacité explicite ; chemins/ledges 2D restent utilisables.

**3D :** Ramp natif avec entrée/sortie et raccord au relief.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-042). 5 étapes ; 4 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-043"></a>
#### RUI-043 — Reconstruire génération d’environnements

**Statut :** planned. **Dépendances :** RUI-042.

**Objectif :** Proposition reproductible, confirmation et garde de navigation complètes.

**2D :** Ressources 2D complètes et génération compatible.

**3D :** Arbres/modèles complets via système Environnement, sans arbres fragmentés.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-043). 5 étapes ; 6 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-044"></a>
#### RUI-044 — Reconstruire décor extérieur et marges

**Statut :** planned. **Dépendances :** RUI-043.

**Objectif :** Habiller les alentours sans confondre zone jouable et propriété d’un décor.

**2D :** Décors 2D extérieurs selon capacité native documentée.

**3D :** Décors spatiaux extérieurs conservant leur propriétaire.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-044). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

### T07 — Règles de jeu sur la carte

**Phase :** Reconstruction. Recréer les cinq catégories Jeu avec les vrais contrats de navigation et de gameplay.

<a id="rui-045"></a>
#### RUI-045 — Reconstruire navigation Jeu et listes contextuelles

**Statut :** planned. **Dépendances :** RUI-044.

**Objectif :** Règles de carte lisibles, recherche et propriétaire explicites.

**2D :** Rubriques avec capacités réelles du profil 2D.

**3D :** Rubriques avec capacités réelles du profil 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-045). 4 étapes ; 3 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-046"></a>
#### RUI-046 — Reconstruire connexions de bords

**Statut :** planned. **Dépendances :** RUI-045.

**Objectif :** Comparaison à même échelle et retour cohérent des voisins.

**2D :** Plusieurs voisins d’un même bord permis seulement si segments natifs non chevauchants.

**3D :** Un voisin par bord selon support 3D existant ; pas d’élargissement implicite.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-046). 5 étapes ; 6 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-047"></a>
#### RUI-047 — Reconstruire passages et sélecteur d’arrivée

**Statut :** planned. **Dépendances :** RUI-046.

**Objectif :** Destination par point nommé, choix provisoire et retour explicite.

**2D :** Arrivées et orientation sur grille 2D.

**3D :** Arrivées et transition avec coordonnées/profil spatial.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-047). 5 étapes ; 7 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-048"></a>
#### RUI-048 — Reconstruire peinture et inspection des déplacements

**Statut :** planned. **Dépendances :** RUI-047.

**Objectif :** Indépendance entre apparence, collision et capacité du joueur.

**2D :** Collisions, surf et franchissements 2D ; actions propres au profil.

**3D :** Collisions et traversée spatiale, sans prétendre activer Flash/Plongée si non supportés.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-048). 5 étapes ; 6 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-049"></a>
#### RUI-049 — Reconstruire zones de rencontres

**Statut :** planned. **Dépendances :** RUI-048.

**Objectif :** Zone locale et table partagée gardent des propriétaires distincts.

**2D :** Rencontres 2D selon méthode, horaire et cellule.

**3D :** Rencontres 3D selon mêmes contrats et emprise native.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-049). 5 étapes ; 7 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-050"></a>
#### RUI-050 — Reconstruire départs arrivées et préparation de test

**Statut :** planned. **Dépendances :** RUI-049.

**Objectif :** Séparer départ unique, points d’arrivée référencés et point de test.

**2D :** Indices et orientations de grille 2D.

**3D :** Emplacements et orientation d’arrivée sur carte 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-050). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-051"></a>
#### RUI-051 — Reconstruire objets utilitaires

**Statut :** planned. **Dépendances :** RUI-050.

**Objectif :** Fonction, apparence et politique d’état explicites pour chaque objet.

**2D :** Obstacles et mouvements de blocs dans les capacités 2D existantes.

**3D :** Obstacles spatiaux et sources de soin existants.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-051). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

### T08 — Scénario de carte et comportements

**Phase :** Reconstruction. Le constructeur associe éléments et scènes ; le contenu des scènes garde son propre éditeur.

<a id="rui-052"></a>
#### RUI-052 — Reconstruire liste et propriétés des éléments de scénario

**Statut :** planned. **Dépendances :** RUI-051.

**Objectif :** Personnages, objets, zones et événements retrouvent une UI commune sans perdre leurs différences.

**2D :** PNJ/objet/zone sur vraie carte 2D.

**3D :** PNJ/objet/zone avec rendu et coordonnées 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-052). 5 étapes ; 4 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-053"></a>
#### RUI-053 — Reconstruire Quand Si Alors et activation

**Statut :** planned. **Dépendances :** RUI-052.

**Objectif :** Utiliser les conditions et l’autorité natives, au-delà de trois choix de Starter.

**2D :** Même logique de conditions sur événements 2D.

**3D :** Même autorité sur éléments 3D ; aucune branche Flutter de gameplay.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-053). 5 étapes ; 6 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-054"></a>
#### RUI-054 — Reconstruire sélecteur de scène et liens de propriété

**Statut :** planned. **Dépendances :** RUI-053.

**Objectif :** Associer une scène existante sans recopier ni éditer ses actions dans la carte.

**2D :** Scènes de carte 2D et références de cible compatibles.

**3D :** Scènes 3D sans confondre scène narrative et scène de rendu.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-054). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-055"></a>
#### RUI-055 — Reconstruire aperçu des conditions et diagnostics

**Statut :** planned. **Dépendances :** RUI-054.

**Objectif :** Afficher quel comportement est applicable sans lancer ni faire progresser le jeu.

**2D :** Aperçu sur acteur 2D sans exécution.

**3D :** Aperçu sur acteur 3D sans simulation cachée.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-055). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-056"></a>
#### RUI-056 — Reconstruire propriétés PNJ parcours et lien décor

**Statut :** planned. **Dépendances :** RUI-055.

**Objectif :** Rendre apparence, déplacement et position éditables avec leurs bons propriétaires.

**2D :** Sprites/directions et parcours par cases 2D.

**3D :** Apparences et déplacements selon contrat 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-056). 5 étapes ; 6 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-057"></a>
#### RUI-057 — Reconstruire entrées de carte et écouteurs de résultat

**Statut :** planned. **Dépendances :** RUI-056.

**Objectif :** Un projet sans fixtures peut créer les événements locaux et globaux requis.

**2D :** Événement d’entrée et résultat valables dans un jeu 2D.

**3D :** Mêmes événements sans dépendance au provider 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-057). 5 étapes ; 4 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

### T09 — Ambiance de carte

**Phase :** Reconstruction. Configuration permanente, héritage et aperçu restent séparés ; les sources doivent être réelles.

<a id="rui-058"></a>
#### RUI-058 — Reconstruire espace Ambiance et temps

**Statut :** planned. **Dépendances :** RUI-057.

**Objectif :** Brancher aperçu indépendant, cycle projet/local et heure fixe.

**2D :** Teinte/cycle 2D seulement selon capacités du renderer.

**3D :** Cycle/éclairage 3D avec même propriété de temps.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-058). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-059"></a>
#### RUI-059 — Reconstruire météo et protection des intérieurs

**Statut :** planned. **Dépendances :** RUI-058.

**Objectif :** Source et intensité locales explicites, sans effets de gameplay implicites.

**2D :** Effets météo 2D réellement disponibles et repli expliqué.

**3D :** Effets météo 3D réellement consommés.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-059). 5 étapes ; 4 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-060"></a>
#### RUI-060 — Reconstruire effets et sources spatiales réelles

**Statut :** planned. **Dépendances :** RUI-059.

**Objectif :** Supprimer les associations fictives et fournir leur gestion complète.

**2D :** Effets 2D supportés ; profondeur 3D non transposée arbitrairement.

**3D :** Halos, fenêtres, eau et profondeur sur vraies sources 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-060). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-061"></a>
#### RUI-061 — Reconstruire musique de carte et aperçu audio

**Statut :** planned. **Dépendances :** RUI-060.

**Objectif :** Utiliser les fichiers réels avec silence explicite et volume local.

**2D :** Audio de carte dans Player 2D.

**3D :** Même audio dans Player 3D, sans dépendance de fichiers sur machine auteur.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-061). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-062"></a>
#### RUI-062 — Vérifier persistance et exécution des ambiances

**Statut :** planned. **Dépendances :** RUI-061.

**Objectif :** Fermer le parcours avec vraies sources, patches et Player.

**2D :** Cas visuel/audio 2D compatible et météo intérieure.

**3D :** Cas visuel/audio 3D avec source et temps.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-062). 5 étapes ; 3 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

### T10 — Réglages globaux et carte régionale

**Phase :** Reconstruction. Aucun ancien écran de réglages ne reste ; les contrats de portée existants sont conservés.

<a id="rui-063"></a>
#### RUI-063 — Reconstruire session de réglages et identité du jeu

**Statut :** planned. **Dépendances :** RUI-062.

**Objectif :** Formulaires neufs et brouillons par rubrique, identité partagée avec Export.

**2D :** Identité et réglages d’un projet 2D.

**3D :** Identité et réglages d’un projet 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-063). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-064"></a>
#### RUI-064 — Reconstruire image caméra et paramètres de rendu

**Statut :** planned. **Dépendances :** RUI-063.

**Objectif :** Séparer défauts projet, surcharge de carte et vue d’édition.

**2D :** Caméra/cadrage/échelle 2D ; pas d’orbite ou profondeur fictive.

**3D :** Perspective/orthographique, inclinaison, rotation et distance réellement consommées.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-064). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-065"></a>
#### RUI-065 — Reconstruire temps météo sons et capacités projet

**Statut :** planned. **Dépendances :** RUI-064.

**Objectif :** Réutiliser les services globaux avec leurs vraies unités d’enregistrement.

**2D :** Capacités propres au profil 2D, notamment celles réservées à ce profil.

**3D :** Capacités 3D réellement disponibles, sans promettre Plongée/Flash par simple checkbox.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-065). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-066"></a>
#### RUI-066 — Reconstruire carte régionale et arrivées de Vol

**Statut :** planned. **Dépendances :** RUI-065.

**Objectif :** Plan régional, localisation des cartes et destinations viennent des contrats réels.

**2D :** Carte régionale et Vol vers une vraie carte 2D.

**3D :** Carte régionale et arrivée dans une vraie carte 3D selon support.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-066). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-067"></a>
#### RUI-067 — Reconstruire diagnostics ressources et récupération de réglages

**Statut :** planned. **Dépendances :** RUI-066.

**Objectif :** Rendre les erreurs de données et rendu actionnables dans le nouveau shell.

**2D :** Image/atlas/tileset absent, format ou résolution.

**3D :** Modèle/material/provider indisponible et reprise.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-067). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

### T11 — Histoire scènes et contenu narratif global

**Phase :** Reconstruction. Rebâtir tous les éditeurs narratifs ; le graphe de scène reste natif et distinct du Scénario de carte.

<a id="rui-068"></a>
#### RUI-068 — Reconstruire accueil Histoire et recherche transversale

**Statut :** planned. **Dépendances :** RUI-067.

**Objectif :** Entrées par intention et synthèse ouvrent les vrais documents spécialisés.

**2D :** Documents et cibles 2D.

**3D :** Documents et cibles 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-068). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-069"></a>
#### RUI-069 — Reconstruire éditeur de scènes en graphe

**Statut :** planned. **Dépendances :** RUI-068.

**Objectif :** Graphe visuel neuf branché sur les modèles et exécuteurs existants.

**2D :** Nœuds qui ciblent les bons acteurs/cartes 2D.

**3D :** Nœuds qui ciblent les bons acteurs/cartes/caméras 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-069). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-070"></a>
#### RUI-070 — Reconstruire dialogues choix et résultats

**Statut :** planned. **Dépendances :** RUI-069.

**Objectif :** Éditeur guidé de dialogue avec vraies références et branches.

**2D :** Portraits/sprites et présentation de dialogue 2D.

**3D :** Dialogue en jeu 3D, mêmes résultats narratifs.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-070). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-071"></a>
#### RUI-071 — Reconstruire faits règles événements et zones d’histoire

**Statut :** planned. **Dépendances :** RUI-070.

**Objectif :** Unifier les formulaires de conditions et les références globales.

**2D :** Zones, événements et faits sur carte 2D.

**3D :** Zones et faits sur carte 3D sans état dépendant du renderer.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-071). 6 étapes ; 6 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-072"></a>
#### RUI-072 — Reconstruire histoires étapes et progression

**Statut :** planned. **Dépendances :** RUI-071.

**Objectif :** Organiser les documents et conditions sans modifier leurs mécaniques.

**2D :** Histoire jouable en profil 2D.

**3D :** Même histoire en profil 3D sans logique de progression dupliquée.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-072). 5 étapes ; 6 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-073"></a>
#### RUI-073 — Reconstruire cinématiques et présentations animées

**Statut :** planned. **Dépendances :** RUI-072.

**Objectif :** Éditeurs neufs pour timelines et compositions, gardant leurs transports et ressources.

**2D :** Mouvements/caméra/présentations 2D selon support.

**3D :** Caméra/acteurs/compositions 3D par ports natifs.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-073). 5 étapes ; 6 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-074"></a>
#### RUI-074 — Reconstruire publication narrative et vérification des usages

**Statut :** planned. **Dépendances :** RUI-073.

**Objectif :** Finir les parcours d’édition avec leurs transactions et références intactes.

**2D :** Pipeline narratif complet d’un jeu 2D.

**3D :** Pipeline narratif complet d’un jeu 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-074). 5 étapes ; 6 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

### T12 — Pokémon et données de jeu

**Phase :** Reconstruction. Aucune ancienne page conservée ; contrats et mécaniques existants restent la source fonctionnelle.

<a id="rui-075"></a>
#### RUI-075 — Reconstruire catalogue Pokémon et espèces

**Statut :** planned. **Dépendances :** RUI-074.

**Objectif :** Nouvelle liste/fiche pour données d’espèce et provenance.

**2D :** Données communes avec ressources visuelles adaptées au jeu 2D.

**3D :** Mêmes données avec médias 3D quand disponibles.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-075). 6 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-076"></a>
#### RUI-076 — Reconstruire capacités apprentissages et données de combat

**Statut :** planned. **Dépendances :** RUI-075.

**Objectif :** Formulaires nouveaux, mécanique de combat inchangée.

**2D :** Références et présentations de combat 2D.

**3D :** Références et présentations de combat 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-076). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-077"></a>
#### RUI-077 — Reconstruire objets commerces et économie

**Statut :** planned. **Dépendances :** RUI-076.

**Objectif :** Refaire toutes les pages de données et commerce sans second stockage.

**2D :** Parcours commerce/objets du jeu 2D.

**3D :** Même logique du jeu 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-077). 6 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-078"></a>
#### RUI-078 — Reconstruire rencontres dresseurs équipes et références

**Statut :** planned. **Dépendances :** RUI-077.

**Objectif :** Les données réutilisables se préparent ici et se référencent depuis les cartes/scènes.

**2D :** Tables et dresseurs référencés depuis carte 2D.

**3D :** Tables et dresseurs référencés depuis carte 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-078). 6 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-079"></a>
#### RUI-079 — Reconstruire import synchro et références externes de données

**Statut :** planned. **Dépendances :** RUI-078.

**Objectif :** Préserver corrections locales et sources lors des opérations de catalogue.

**2D :** Données et médias 2D admis avec compatibilité explicite.

**3D :** Données et médias 3D admis selon pipeline disponible.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-079). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

### T13 — Vérification test et export

**Phase :** Reconstruction. Distinguer vérifier un projet, préparer un point de test, lancer un moteur et publier un paquet.

<a id="rui-080"></a>
#### RUI-080 — Reconstruire diagnostics et parcours Corriger

**Statut :** planned. **Dépendances :** RUI-079.

**Objectif :** Une liste guidée renvoie à l’UI propriétaire sans faux feu vert.

**2D :** Validation des capacités, cartes et médias 2D.

**3D :** Validation du graphe spatial, sources et médias 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-080). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-081"></a>
#### RUI-081 — Reconstruire test de carte et lancement de jeu

**Statut :** planned. **Dépendances :** RUI-080.

**Objectif :** Un clic Test démarre le vrai chemin natif, pas une image de départ.

**2D :** Lancer le Player 2D avec contrôles utilisables.

**3D :** Lancer le Player 3D avec contrôles utilisables.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-081). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-082"></a>
#### RUI-082 — Reconstruire export et état de publication

**Statut :** planned. **Dépendances :** RUI-081.

**Objectif :** Métadonnées partagées, validation, génération et résultat réel du paquet.

**2D :** Jeu 2D exporté, médias/règles présents.

**3D :** Jeu 3D exporté avec modèles, effets et médias présents.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-082). 5 étapes ; 6 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-083"></a>
#### RUI-083 — Reconstruire reprise et erreurs de Player

**Statut :** planned. **Dépendances :** RUI-082.

**Objectif :** La nouvelle UI explique les reprises sans détruire de sauvegarde.

**2D :** Sauvegarder/reprendre le jeu 2D courant.

**3D :** Sauvegarder/reprendre le jeu 3D courant.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-083). 5 étapes ; 4 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

### T14 — Recette finale et clôture du remplacement

**Phase :** Acceptation globale. Aucun lot vert ne remplace les parcours de bout en bout et la vérification d’absence de l’ancienne UI.

<a id="rui-084"></a>
#### RUI-084 — Vérifier responsive accessibilité et clavier

**Statut :** planned. **Dépendances :** RUI-083.

**Objectif :** Contrôler tous les nouveaux modules, pas seulement les quatre vues carte.

**2D :** Toute la navigation sur projet 2D.

**3D :** Toute la navigation sur projet 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-084). 5 étapes ; 5 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-085"></a>
#### RUI-085 — Mesurer performance et durabilité des éditions

**Statut :** planned. **Dépendances :** RUI-084.

**Objectif :** Vérifier les coûts réels sans confondre rendu fluide et édition incrémentale.

**2D :** Projet 2D représentatif avec cartes/couches/ressources.

**3D :** Projet 3D représentatif avec modèles, surfaces et environnements.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-085). 5 étapes ; 3 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-086"></a>
#### RUI-086 — Vérifier compatibilité frontières et parité MCP

**Statut :** planned. **Dépendances :** RUI-085.

**Objectif :** Le remplacement UI ne change pas silencieusement les contrats consommés.

**2D :** Compatibilité des projets/jeux 2D.

**3D :** Compatibilité des projets/jeux 3D.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-086). 5 étapes ; 3 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-087"></a>
#### RUI-087 — Exécuter les parcours complets et comparer chaque état

**Statut :** planned. **Dépendances :** RUI-086.

**Objectif :** Une réalisation n’est complète qu’après preuve visuelle et fonctionnelle native des deux profils.

**2D :** Recette complète 2D avec parcours applicables et capacités indisponibles testées.

**3D :** Recette complète 3D, géométrie/rendu et parcours moteur.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-087). 5 étapes ; 4 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

<a id="rui-088"></a>
#### RUI-088 — Clore la porte G1 remplacement complet

**Statut :** planned. **Dépendances :** RUI-087.

**Objectif :** Zéro ancienne UI, toutes les nouvelles fonctions reliées et preuves conservées dans l’artefact.

**2D :** Studio et jeu 2D utilisables de bout en bout.

**3D :** Studio et jeu 3D utilisables de bout en bout.

[Ouvrir le lot complet : fichiers, étapes, tests, références, états et critères](index.html#plan-RUI-088). 5 étapes ; 4 états requis par profil. Le JSON canonique conserve tous les détails ; cet index évite de dupliquer le plan intégral dans un Markdown surdimensionné.

### 27.7 Préparation et limites

Départ sur main, HEAD 06fd484d3fbe762f33380e05a21629cb6dee23fc, arbre modifié et travail concurrent préservé. T00 en rattrapage. Les extractions et retraits T01 déjà réalisés sont conservés ; tout nouveau retrait T01 et toute reconstruction sont figés. Aucun lot accepté, G0 non accepté. L’inventaire de 992 fichiers est à classer et compléter par graphe ; ce n’est pas un ordre aveugle de supprimer des dossiers.

**Vérifications de préparation :** Historique de préparation initiale : 88 lots détaillés dans 15 thématiques ; 88 lots planifiés, zéro lot natif accepté.; Historique de préparation initiale : 611 références locales présentes et empreintes vérifiées ; aucune référence de lot inconnue.; Historique de préparation initiale : Inventaire initial de 992 fichiers, à classer avant retrait ; aucun fichier applicatif supprimé.; Historique de préparation initiale : 16 contrôles du vérificateur réussis : refus de preuve manquante, score 94, auto-revue, écart critique, métrique excessive, code périmé, commande en échec.; Historique de préparation initiale : record émet un patch sans modifier le canonique ; invalidation en cascade vérifiée sur fixture sans résultat natif revendiqué.; Historique de préparation initiale : 17 contrôles d’interactions DOM et 3 contrôles de lien direct réussis ; aucune erreur JavaScript.; Historique de préparation initiale : Rendus Markdown/HTML déterministes et synchronisés au JSON canonique ; contrôle de taille du Markdown réussi.; Historique de préparation initiale : Markdown hygiene : un nouveau Markdown canonique, contrôle réussi avec POKEMAP_MARKDOWN_MAX_NEW=1 ; index sous la limite de 262144 octets..

**Revue native indépendante :** Revues indépendantes de source réalisées entre sous-agents : extractions, frontières Player, surfaces techniques et hôte neutre. Recette native par état/profil et G0 global non acceptés.. **Inspection visuelle du nouvel artefact :** Artefact inspecté dans le navigateur local : filtrage T01 affiche six lots, G0 En cours/aucune acceptation et note de réalisation RUI-005 visible ; capture durable artefact-t01-progress.jpg. Vérification documentaire, pas acceptation des nouvelles maquettes..

**Adaptation de writing-plans :** fichiers, séquence, cas et contrats de preuve sont détaillés ; le plan ne préécrit pas des milliers de lignes de patches futurs sur des interfaces à retirer. Le code et ses tests sont ajoutés au lot concerné. Aucun commit/worktree n’est imposé par le skill.

**Prochaine action :** Terminer le classement revu, qualifier les témoins actuels 2D/3D, compléter et approuver les références, puis revoir le registre. Reprendre T01 seulement après résolution des prérequis.
