# Fluidité d’Avelune Player sur HeartGold — dossier de revue pour Opus

**21 novembre 2026 · Revue technique demandée par Yoahn · Investigation menée par Tom (Codex)**

Avelune Player exécute des jeux créés avec Avelune Studio. HeartGold, abrégé HGSS dans ce dossier, est le jeu utilisé comme cas réel. La demande initiale concernait une porte qui bloquait systématiquement. Une fois ce blocage corrigé, il restait une question plus large. Pourquoi une carte sur laquelle le joueur marche à 30 FPS peut-elle figer plus d’une seconde dès qu’il y revient par un bâtiment ?

**Le résultat central est reproductible sur l’iPhone 15 Pro.** Sur la Route 32, 396 intervalles consécutifs pendant la marche sont restés sous 50 ms. En ressortant du passage des Ruines vers cette même route, le Player a laissé passer **1 305 ms entre deux images**. Un second passage avec échantillonnage CPU a retrouvé **1 313 ms**. La préparation de la géométrie du sol occupait alors le thread qui devait rendre la suite de l’animation.

### Demande à Opus

> Donne-moi une contre-revue technique de cette investigation. Quels diagnostics sont suffisamment établis pour agir ? Quel résultat te paraît le plus fragile ou susceptible de changer sur Android ? Quel correctif livrerais-tu en premier, et lequel repousserais-tu malgré son bon chiffre sur Mac ?
>
> Examine en particulier le choix entre découpage du travail par image et isolates, la validité et la consommation mémoire des caches, et la possibilité d’accélérer le démarrage tout en détectant une installation modifiée. Pour chaque désaccord important, cite la mesure ou le chemin de code sur lequel tu t’appuies et propose l’expérience la plus courte qui permettrait de trancher.
>
> Termine par un ordre de livraison, un risque de régression concret pour chaque priorité, et les critères qui te feraient accepter ou refuser sa mise en production. Si tu as accès au dépôt, utilise la révision indiquée ci-dessous. Si ton analyse repose uniquement sur ce document, précise les points qui demandent une lecture du code.

## 1. Version de référence et valeur des preuves

| Élément | Référence et conditions |
|---|---|
| Signalement initial | Player build **857**. Yoahn a également constaté le problème sur Android sur une nouvelle partie et une installation fraîche. Sur iPhone, le changement d’application puis le retour faisaient apparaître le message d’erreur. |
| Player audité | Révision Git **`8889445899c498f1dc934535fd6783a57ffb6d44`**, après les deux correctifs décrits en section 2. Les mesures sont rattachées à ce code, indépendamment du numéro du Player personnel installé. |
| Cartouche publique | **`0.1.17-dev.alpha`**, identifiant `private.hgss.bourg-geon`. L’archive contient **62 328 entrées** avec le manifeste, dont 62 327 fichiers de contenu. Son empreinte figure en annexe. |
| iPhone | iPhone 15 Pro physique, binaire QA en mode Profile, conteneur isolé et copie de sauvegarde. Limite de **30 FPS**, échelle de rendu **50 %**, FSR1 et HUD de diagnostic. Les commandes du parcours sont pilotées par le harnais. Le test de lancement emprunte la navigation native du Player. |
| Mac | Tests Flutter du vrai chargeur, du renderer et du parcours de jeu. Les essais de décodage et de lecture isolés sont également passés en Dart compilé en natif. Certains chronos Flutter utilisent le JIT et subissent la charge de la machine. |
| Données des Ruines | Le passage entre la Route 32 et son poste de garde se teste sur la cartouche publique. Pour entrer sur la carte extérieure des Ruines, les essais de parcours et de chargement utilisent une copie avec les quatre bordures réparées. Le projet auteur et l’export possèdent des représentations différentes de certaines données visuelles. Seules les données réparées ont été reportées dans la copie d’export. |

Le compteur mesure les **intervalles entre débuts de trames Flutter**, issus de `FrameTiming.vsyncStart`. À 30 FPS, le budget nominal est de 33,33 ms. Un p95 de 33,5 ms signifie que 95 % des intervalles de la fenêtre sont plus courts que cette valeur. Un unique gel très visible peut disparaître dans une moyenne de FPS. Les intervalles, les marqueurs de prise de contrôle et les piles CPU répondent donc à trois questions différentes. La présentation matérielle à l’écran et le temps d’exécution du GPU restent à instrumenter séparément. [Révision auditée][revision] · [Définition du compteur][hud]

Une contrainte produit s’applique à toute proposition de nouveau format ou d’index. Les projets, les cartes et les jeux valides exportés depuis **Avelune Studio `0.3.31+331`** doivent rester lisibles et jouables dans les Players ultérieurs. L’expérimentation peut ajouter une représentation plus rapide avec un chemin de lecture compatible. La conservation des sauvegardes de progression relève d’un contrat distinct. [Politique de compatibilité][compatibilite]

Dans les tableaux, **à froid** signifie première visite dans la session ou relance du processus, selon le parcours indiqué. **À chaud** signifie revisite dans la même session. Le système d’exploitation peut encore avoir des fichiers en cache. Le téléphone Android de l’utilisateur n’a pas fait l’objet d’une campagne physique chronométrée.

## 2. Ce qui a déjà été corrigé

### Plantage des portes et saccades en marchant

La vidéo initiale contient **9,01 s d’écran noir** avant « Session suspendue ». Une reproduction a laissé le Player noir au premier plan pendant 40 s. La position du personnage était déjà celle de l’école, tandis que le transfert attendait la confirmation du renderer. En revenant dans l’application, le joueur voyait « Source d’animation du héros indisponible ». La fonction concernée dessine également les PNJ.

L’entrée de l’école de Mauville passait lorsque seules la ville et l’école étaient chargées. Avec la Route 32 encore présente comme voisine, la fin de préparation du Pokémon suiveur dans la nouvelle session déclenchait un nettoyage du cache partagé. L’image `asset-hgss-parent-ami` était libérée alors que le PNJ `ch7-36-1` de la Route 32 en avait encore besoin pour une image de l’extérieur. Cela explique le lien avec le changement d’application observé par Yoahn et la reproduction sur des données récentes.

Le commit **`4608ec1c6`** a corrigé la conservation des images par leurs utilisateurs encore actifs et amélioré plusieurs calculs de marche. Le calcul de hauteur examine maintenant les polygones proches du personnage. Plus de **176 000 positions** à Mauville et sur la Route 32 ont été comparées pour vérifier que la hauteur obtenue restait identique. Deux entrées et deux sorties de l’école ont abouti sur l’iPhone, application au premier plan, puis le personnage a pu remarcher. [Commit des portes et de la cadence][fix-portes] · [Test de traversée][test-portes]

| Marche durant la validation de ce correctif | FPS moyens | p95 entre trames |
|---|---:|---:|
| Mauville avant correction | 23,42 | 70,34 ms |
| Mauville après correction | 30,02 | 33,50 ms |
| École de Mauville | 30,00 | 33,45 ms |
| Route 32 | 29,99 | 33,52 ms |
| Ruines d’Alpha, extérieur réparé | 30,00 | 33,52 ms |
| Ruines d’Alpha, hall souterrain | 29,99 | 33,44 ms |

Sur ces parcours corrigés de 16 à 18 s, aucun intervalle de marche n’a dépassé 50 ms. À Mauville, 49 intervalles dépassaient ce seuil avant correction. Ce premier avant/après porte sur la marche. La campagne suivante a isolé les gels aux portes qui persistaient sur la révision corrigée.

### Double chargement et données des Ruines

Le commit **`888944589`** rassemble les dépendances de la carte et de son décor extérieur dans une seule projection du catalogue. Au même seuil des Ruines sur l’iPhone, la première entrée après relance est passée de **8,31 s à 5,32–5,52 s**. Une revisite dans la même session a pris **1,75 s**. Ce correctif a déjà été poussé sur `main`. Les variantes de cache et de rendu décrites plus loin sont des essais distincts. [Commit du chargeur][fix-chargeur] · [Test des dépendances du décor][test-decor]

Le refus d’entrer aux Ruines avait aussi une cause propre au jeu. Dix éléments du décor avaient changé de modèle après l’enregistrement de quatre bordures. Leurs empreintes de génération étaient devenues incohérentes. Les quatre bordures ont été régénérées dans le projet source, avec l’accord de Yoahn. Une comparaison entre l’export public et la source réparée retrouve **quatre reçus modifiés sur 42 bordures**, **689 instances dans les deux cartes** et **une seule position différente**. Sur cette instance sans collision, Y passe de 3,08962 à 2,83987, soit environ −0,25 unité. La cartouche publique identifiée en annexe contient encore les anciens reçus. Sept autres cartes ont présenté des incohérences d’empreinte pendant l’examen initial, dont Doublonville. Leur traversée reste à vérifier.

## 3. Temps réellement vécus sur l’iPhone

| Action et borne de fin | Mesure |
|---|---|
| Jouer depuis la bibliothèque, cartouche déjà installée → première image du titre | **24,244 s**. Le splash s’affiche à +86 ms. La vérification intégrale se déroule de +0,053 à +19,080 s. Le harnais passe l’intro dès qu’elle l’autorise. |
| Continuer → contrôle effectif à Mauville | **14,422 s** dans la passe légère. Le parcours automatisé complet de Jouer au contrôle prend **38,693 s**. |
| Ouvrir le menu pause → première trame observée | **515 ms** pour la première ouverture. Reprendre depuis ce menu prend **38 ms**. Il s’agit de la pause en jeu. |
| École → Mauville | **3,00 s** au premier retour et **3,00 s** au suivant. Pires intervalles respectifs de **414 et 439 ms**. |
| Mauville → Route 32 juste après Continuer | **3,015 s** dans la passe légère, avec un intervalle de **456 ms**. |
| Route 32 → passage des Ruines | **1,331 s**, pire intervalle **61,5 ms**. |
| Passage des Ruines → Route 32 | **2,908 s** sans profilage CPU. Sur 34 intervalles, trois dépassent 50 ms, le p95 est de **475 ms** et le maximum de **1 305 ms**. |
| Marche continue sur la Route 32 | **39,44 unités en 13,23 s**, **30,00 FPS**, p95 **33,53 ms**, maximum **41,47 ms**. Aucun des 396 intervalles ne dépasse 50 ms. |

Le lancement du shell avant l’action Jouer a pris environ 3,10 s dans ce parcours. Deux vérifications structurelles de la bibliothèque ont duré 1,99 et 2,24 s sur des périodes qui se chevauchent. De même, les 19,03 s de vérification intégrale sont **incluses** dans les 24,24 s de Jouer au titre. Lancer ce contrôle plus tôt peut avancer le titre ou simplement déplacer l’attente. Le critère utilisateur est le temps jusqu’au contrôle, accompagné de la réactivité des écrans traversés.

La répétition à chaud de l’entrée dans le poste des Ruines n’a pas déclenché la porte depuis le second point de départ du harnais. Cette tentative est exclue. Les deux sorties de l’école et les deux mesures du gel en revenant sur la Route 32 ont bien abouti.

## 4. Où se perd une seconde pendant une transition

Sur le retour du passage vers la Route 32, la trace CPU mesure un gel de **1 313 ms** alors que la porte, déjà noire, attend le renderer. Sur **942 échantillons de l’isolate UI**, 936 passent par la matérialisation de la scène et **851 par `_SceneGround._resolveSteps`**. Les piles montrent la tessellation du terrain, la création des sommets et le découpage des polygones. La plus longue pause GC observée sur ce créneau dure **2,84 ms**. Une passe de contrôle, HUD actif et collecte CPU désactivée, retrouve le gel à **1 305 ms**. [Construction des maillages][maillages]

Pendant la même transition, **un autre intervalle de 532 ms** apparaît plus tôt. Sur 251 échantillons, 244 passent par `SmartTileLayerVisualPlan.invariantImageIds`. Le moteur détermine quelles pages de textures la carte peut utiliser. À la sortie de l’école, cette même fonction apparaît dans 176 des 194 échantillons du pic de 414 ms. À l’entrée de l’école, un pic différent de 130 ms contient environ 125 ms en phase de peinture, avec des appels à `drawIndexed`. Cela justifie de mesurer également la soumission du rendu et le premier affichage. [Sélection des cellules][smart-tiles]

**Décomposition sur Mac.** Les valeurs suivantes sont des médianes de trois passages sur les cartes de la cartouche, avec caches de modèles et textures initialement vides. Le banc Flutter effectue la préparation CPU sans présenter d’image. Ces durées servent à comparer les opérations sur une même machine. Elles ne s’additionnent pas aux durées de l’iPhone.

| Travail de préparation | Mauville | Route 32 | Ruines, extérieur |
|---|---:|---:|---:|
| Préparer les modèles GLB | 620 ms | 153 ms | 521 ms |
| Construire les plans de sol et d’occlusion | 40 ms | 6 ms | 5 ms |
| Identifier les pages de textures actuelles et suivantes | 249 ms | 539 ms | 39 ms |
| Lire et décoder ces pages | 16 ms | 8 ms | 25 ms |
| Construire les maillages du sol de la carte active | 109 ms | 305 ms | 182 ms |
| Sommets et indices préparés pour l’envoi | 2,38 Mo | 9,01 Mo | 4,72 Mo |

**Variante testée.** Les cartes voisines disposent déjà d’un itérateur qui rend la main entre des tranches de travail. Pour la destination active, le chemin courant construit encore le sol en synchrone. Avec une cible de 6 ms par tranche, la médiane du plus long morceau mesuré est descendue à **6,9 / 9,5 / 10,7 ms** sur Mauville, la Route 32 et les Ruines. Pour la Route 32, le total passe de **305 à 414 ms**. L’intérêt joueur dépend donc du moment où le travail commence. Après l’écran noir, le découpage risque d’allonger l’attente. À l’approche de la porte, il permet à la carte source de continuer à s’animer pendant la préparation. [Choix du budget et construction coopérative][tranches]

**Proposition à challenger.** Préparer d’abord le secteur visible depuis le point d’arrivée, conserver la scène source jusqu’à ce que la destination soit cohérente, puis compléter les secteurs hors champ. L’entrée, les collisions, le Pokémon suiveur et la caméra doivent être prêts ensemble. Si le joueur s’éloigne, un changement de destination doit annuler le travail devenu inutile et libérer ses ressources. L’essai le plus discriminant comparerait le même seuil en filmant l’animation, avec mesure du noir, du pire intervalle et du temps jusqu’au premier pas.

Deux pistes viennent ensuite. Les modèles de Mauville et ceux du Centre Pokémon ont **zéro identifiant de modèle source commun** dans cette cartouche. Même constat entre l’extérieur des Ruines et son poste de garde. Conserver une partie des modèles de la porte précédente pourrait éviter un second décodage. Mauville et les Ruines représentent chacun environ **42 Mio** dans la comptabilité du banc, pour un budget résident 3D de **256 Mio** dans le Hub. Une mesure de la mémoire réelle et des évictions est indispensable. En régime de marche établi, les calculs combinés de fenêtre d’images, de sol et d’occlusion de la Route 32 coûtent **2,18 ms au p95** sur le banc Mac. Ce coût récurrent mérite un suivi après les gels de plusieurs centaines de millisecondes. [Éviction des modèles][eviction]

## 5. Revisiter une carte sans reconstruire son catalogue

La cartouche contient **31 619 objets JSON** sous `catalog/objects`. La première préparation des Ruines étudiée demande **526 définitions de départ** puis **1 231 définitions**, dépendances comprises. Le Player conserve déjà la carte du retour immédiat par une porte. Pour éprouver un autre cas, le banc a gardé le même catalogue ouvert et appelé le vrai chargeur dans l’ordre **Ruines → entrée du hall → hall souterrain → Ruines**. Ce test mesure la fourniture des données de carte. L’affichage, le transfert du personnage et l’animation de porte sont mesurés séparément sur téléphone.

Deux seuils du code expliquent le coût des revisites. Le cache des octets bruts est limité à **4 Mio**. Le cache des projections préparées possède un budget de **8 Mio de données sources** et écarte notamment les demandes avec plus de 256 racines. La projection finale des grosses sélections utilise déjà un isolate. Il reste en amont la lecture des objets, le parcours des dépendances et la construction de leurs représentations. [Cache et parcours des dépendances][catalogue] · [Lecture des objets][lecture-objets]

| Variante sur le retour aux Ruines | Résultat de la copie QA |
|---|---|
| Code de référence | **1 228 lectures de fichiers pour 1 231 demandes**. Deux témoins du test avec comparaison des résultats prennent **3,839 s et 2,344 s**. |
| Cache brut porté de 4 à 12 Mio | Zéro relecture au retour dans cet essai. Le chargeur redécode encore les 1 231 objets. Une passe prend **1,325 s** avec un intervalle de boucle principale de **846 ms**. |
| Garder la projection validée si son poids source entre dans les 8 Mio | **Zéro relecture et zéro redécodage d’objet** sur le retour. Deux passages prennent **312 et 335 ms**. Les empreintes du contenu de carte et du manifeste concordent sur les **dix chargements** comparés au témoin. |
| Travail résiduel dans cette dernière variante | **249 et 267 ms** sont encore consacrées à la préparation et à la vérification des bordures des Ruines. |

Les compteurs « lectures de fichiers » mesurent les accès demandés au système de fichiers. Ils incluent les données que macOS peut servir depuis son cache. Le poids du JSON d’origine sous-estime potentiellement le poids des objets Dart conservés. Le passage de plusieurs secondes à quelques centaines de millisecondes établit un gain sur **ce chemin du chargeur Mac**. Le prochain essai doit suivre la mémoire réelle et l’impact sur la porte entière lors de circuits entre plusieurs grandes cartes.

La vérification résiduelle des bordures mérite sa propre décision. Elle a précisément permis de repérer les quatre reçus périmés du jeu. Réutiliser son résultat exige une identité qui couvre la carte effective, le catalogue de bordures, les instances, les ressources référencées et le contexte utilisé pour la validation. Une carte transformée en cours de session doit pouvoir invalider le résultat. [Contrat de vérification des bordures][bordures]

## 6. Où le multithreading aide et où il coûte

Le premier essai prend les **1 231 définitions réelles des Ruines**, soit **7 240 424 octets** déjà en mémoire. Chaque variante exécute les contrôles et le décodage sur les mêmes données, puis restitue tous les objets décodés. Trois passages par variante ont été réalisés en ordre alterné sur Mac, en Dart compilé. Les quatre résultats décodés ont la même empreinte. Le blocage est mesuré par l’intervalle maximal observé sur la boucle principale de chaque passage. Le tableau donne les médianes.

| Exécution | Durée du travail | Plus long intervalle de boucle principale |
|---|---:|---:|
| Décodage sur le thread principal | 490 ms | 490 ms |
| 1 isolate | 495 ms | 21,9 ms |
| 2 isolates | 441 ms | 6,9 ms |
| 4 isolates | 255 ms | 15,6 ms |

Un worker rend déjà la boucle principale beaucoup plus disponible, même lorsque le travail total prend autant de temps. Quatre workers accélèrent ce lot sur Mac. Pour retenir un degré de parallélisme mobile, il faut mesurer le transfert des résultats, la mémoire maximale, la chauffe et la concurrence avec le renderer. Un candidat raisonnable est une file de lots bornés en octets desservie par un ou deux workers réutilisés. Le banc mesurait des lots lancés avec `Isolate.run`. L’intérêt de workers persistants sur téléphone reste à tester.

**Contre-exemple.** Construire les deux plans de rendu entiers dans un isolate, puis les rapatrier vers le thread principal, a fait passer l’opération de **575 à 1 617 ms** sur la Route 32. Les pages et les propriétés des visuels contrôlés concordaient. Une préparation par secteur avec un résultat compact, ou les tranches déjà présentes, mérite un essai avant de transférer de grands graphes d’objets. La création des ressources graphiques reste sous la responsabilité du backend et la mutation de la scène vivante sous celle du renderer.

**Lecture des petits fichiers.** Un second essai indépendant lit les mêmes objets depuis le système de fichiers chaud du Mac et vérifie leurs empreintes. Hachage compris, les durées médianes atteignent **271 ms en série**, **159 ms avec quatre lectures concurrentes**, **135 ms avec seize** et **54 ms dans un bloc contigu expérimental**. Le bloc est un prototype de disposition des fichiers. Un format livré demanderait un index d’offsets et de longueurs, le contrôle des contenus et la lecture des anciennes cartouches. Ces durées caractérisent 7,24 Mo de définitions. Le temps d’installation de la cartouche complète fait l’objet d’une mesure séparée en section 7.

La lecture portable vérifie l’empreinte, l’UTF-8 et des limites de structure, puis le décodeur de stockage repasse sur plusieurs de ces contrôles. Une API qui transmet un résultat validé pourrait mutualiser le hachage et certains parcours. Pour l’évaluer, il faut des cas négatifs de longueur, d’empreinte, de profondeur et de quotas, y compris les limites cumulées du catalogue. [Contrôles à la lecture][lecture-objets] · [Décodage au stockage][decodeur]

## 7. Démarrage, menu, combat et installation

### Jouer et Continuer

L’ouverture complète du catalogue, avant la première carte, lit **1 885 objets**. Elle charge notamment **620 dialogues, 443 scènes et 354 cinématiques**. La lecture sélective du format existe déjà. Une variante a demandé seulement le nom, la version, les réglages, la présentation, ses cinématiques, les références de médias cinématiques et les données de nouvelle partie. Elle a lu **60 objets**. Deux passages ont pris **73 et 87 ms**, contre **2,289 et 4,352 s** pour l’ouverture complète. Les sept champs retenus ont la même empreinte. L’essai prouve leur équivalence sur HGSS. Le branchement de toutes les variantes de titres, de langues et d’intros d’autres jeux reste à tester. [Lecture sélective][metadonnees] · [Démarrage du Hub][demarrage]

La vérification de la bibliothèque et celle d’un lancement ont des responsabilités distinctes. Pour une même version installée, partager une **vérification structurelle déjà en cours** est une première piste. Le Player doit également continuer à refuser un lancement si un fichier installé est modifié, ce qu’un test du dépôt exerce explicitement. Un reçu d’installation seul ne prouve pas que le contenu est encore intact. Pour la vérification intégrale de 19,03 s, nous envisagerions d’abord le regroupement des lectures et une organisation qui chevauche la préparation du titre avec des contrôles sûrs. Toute variante doit conserver le refus avant la prise de contrôle. [Vérification au lancement][verif-lancement] · [Test de fichier modifié][alteration]

Les **14,42 s après Continuer** ont plusieurs contributeurs. Dans une passe profilée séparée de 15,37 s, sur 3 515 échantillons du thread principal, 649 contiennent la lecture du catalogue et 617 l’initialisation native de pipelines de rendu, notamment matériau, météo et mise à l’échelle. Ces nombres décrivent les piles CPU échantillonnées. Ils ne donnent ni une fraction du temps mural ni la durée des commandes sur le GPU. Un essai pertinent consisterait à compter les créations de pipelines par combinaison de shaders, de format et de disposition des sommets, puis à mesurer l’effet d’une réutilisation compatible avec le contexte graphique. [Création des pipelines][pipelines]

Le jeu dispose aussi d’un index narratif préparé à l’installation. Sur Mac, relire l’index valide de **104 cartes** a pris **1,09–1,43 s**, avec un plus grand intervalle de boucle principale de **20–23 ms**. Une copie QA au cache narratif vide a passé environ **12,3 s** dans la phase du catalogue narratif. Les chiffres correspondent à deux états de cache différents. Un prochain profil de Continuer doit donc consigner lequel a été utilisé. Sur cette même cartouche installée, la détection des options météo et heure a trouvé sa réponse sans ouvrir de cartes supplémentaires. [Index narratif préparé][index-narratif]

### Menu pause

À chaque ouverture, le constructeur de carte régionale relit environ **4,3 Mio de JSON** et reconstruit un catalogue de **11 527 assets**. HGSS ne déclare aucune carte régionale illustrée. Le menu présente 104 lieux sous forme de liste et cette branche n’utilise pas les assets chargés.

| Même sauvegarde immobile, même processus Flutter sur Mac | Code livré | Lecture réservée à la branche qui utilise les images |
|---|---:|---:|
| Construction des six sections à chaud | 200–234 ms | **36–40 ms** |
| Plus long intervalle observé par un timer de 4 ms | 163–197 ms | **6–8 ms** |
| Lieux proposés | 104 | 104 |

C’est le changement le plus facile à isoler. Il évite une opération entière sans ajouter de cache pour HGSS. Le test de non-régression indispensable est un second jeu qui dispose réellement d’une carte régionale illustrée, avec image, vignettes et règles de visibilité des lieux. Le gain sur le premier menu de l’iPhone reste à mesurer. [Constructeur de carte régionale][menu]

### Premier combat et sauvegardes

Pour cinq Pokémon dans l’équipe et aucun en boîte, l’hydratation initiale a lu **502 fichiers JSON d’espèces**. Dans un parcours complet sur Mac, cette lecture a pris **301 ms**, contre **15 ms** pour les attaques. Le chargeur conserve ensuite son index dans la session. Une piste serait de publier un index par identifiant d’espèce avec lecture à la demande. Il faut préserver les identifiants locaux, les espèces désactivées et le comportement des cartouches sans nouvel index. [Chargeur d’espèces][especes]

Deux parcours Flutter ont utilisé la copie de la sauvegarde iPhone, le préchargeur du Hub et son budget spatial de 256 Mio. Le vrai menu tactile du Player a accepté *Attaquer*, affiché les capacités après **72 ms**, puis accepté *Vive-Attaque*. Après le tour et *Fuir*, le contrôle est revenu sur la Route 32 **3,39 s après la fuite**, animations comprises. Il s’agit de touchers synthétiques sur Mac, avec rendu logiciel et pilote audio de test. Le premier effet sonore, le toucher physique et la présentation GPU d’un combat sur mobile restent à mesurer.

Les checkpoints manuels et de cycle de vie ont été écrits puis relus sur la copie. À chaud, l’écriture atomique vérifiée prenait généralement **13–18 ms**. Les résultats disponibles donnent la priorité au menu et au premier combat. Ils ne suffisent pas à classer toutes les sauvegardes sur téléphone, notamment en présence de stockage lent.

### Première installation

Sur le banc Flutter Mac, l’installateur réel a pris **136 s** pour la cartouche. Les principales étapes sont l’inspection initiale du manifeste (**3,65 s**), la copie avec calcul de l’empreinte (**13,66 s**), l’inspection détaillée du contenu (**58,78 s**), l’extraction (**36,22 s**), la vérification de l’inventaire extrait (**3,23 s**) et le chargement de contrôle avec préparation de l’index narratif (**19,80 s**).

L’inspection et l’extraction emploient déjà des isolates. L’extracteur émet **62 328 événements de progression** avant le filtrage qui limite les mises à jour de l’interface native. Regrouper les événements dans le worker est un changement local dont le gain reste à mesurer. Une fusion de passages sur les octets est une décision plus large. Elle doit conserver l’annulation, la détection d’archive altérée et la promotion atomique d’une version entièrement admise. Le contrôle final de l’arborescence vérifie notamment l’inventaire et les types de fichiers. [Installateur][installation] · [Émission de la progression][progression]

## 8. Ordre de livraison proposé et critères de décision

| Priorité proposée | Expérience ou changement | Condition d’acceptation à vérifier |
|---|---|---|
| 1. Menu | Charger les assets régionaux dans la branche qui les consomme. | Six sections et 104 lieux identiques sur HGSS. Images correctes sur un jeu illustré. Viser **moins de 100 ms** jusqu’au menu interactif à chaud sur appareil. |
| 2. Gel aux portes | Préparer la destination avant le noir et découper le calcul des Smart Tiles et du maillage actif. | Mesurer séparément le pire intervalle, le noir et le temps au premier pas. Préserver le résultat des collisions, l’apparition des PNJ et du suiveur, ainsi que l’annulation quand le joueur change de direction. |
| 3. Revisites | Garder les projections validées selon un budget, mesurer la mémoire résidente et invalider à la bonne révision. | Rejouer Ruines → hall → sous-sol → Ruines. Comparer les contenus, les relectures, la mémoire et le temps de porte complet. Une bordure ou une ressource altérée doit toujours être détectée. |
| 4. Démarrage | Partager les demandes identiques, ouvrir les données de présentation en premier et mesurer le travail de Continuer. | Réduire **Jouer → contrôle** sur un jeu installé, vérifier titre interactif et reprise correcte. Inclure nouvelle partie, sauvegarde existante, cache narratif valide ou absent, et fichier altéré. |
| 5. Combat et distribution | Expérimenter l’index d’espèces, puis les lectures groupées et le format compact si le coût restant le justifie. | Chronométrer premier et deuxième combat jusqu’à la première commande. Vérifier les anciennes cartouches, les espèces locales et la reprise après interruption de l’installation. |

**Recette mobile proposée.** Garder la cartouche, le point de départ et les réglages constants. Enregistrer le modèle, le mode d’alimentation, l’état thermique et la mémoire avant et après chaque circuit. Alterner exécutions témoin et candidate. Tester une minute de marche à Mauville et sur la Route 32, puis au moins dix allers-retours par porte sur l’école, le passage et les Ruines corrigées. Présenter les échantillons, le p95, le maximum et les comptes au-dessus de 50 et 100 ms, en séparant première visite et revisite. Garder un parcours avec un passage en arrière-plan puis un retour, comme dans le signalement initial. Répéter sur un **Android physique** et sur l’iPhone.

**Objectifs pour la version candidate.** À la cible de 30 FPS, viser une minute de marche sans intervalle supérieur à 50 ms sur le parcours retenu, puis dix allers-retours sans gel de 100 ms pendant l’animation. Pour une porte, conserver séparément la durée de l’animation voulue par le jeu et l’attente de ressources qui la prolonge. Une baisse de la résolution ou un fondu plus long changerait l’expérience mesurée. Les résultats à 60 FPS, en résolution native ou après une longue session chaude restent ouverts.

**Le point sur lequel un désaccord serait particulièrement intéressant.** Une approche garde les données préparées pour réduire le temps total. Une autre réduit la durée maximale de travail par image, quitte à préparer la carte un peu plus longtemps. Sur la Route 32, les deux ont des preuves en leur faveur et des coûts différents. Le jugement attendu porte sur l’ordre dans lequel les livrer et sur le test qui démontrera que le joueur y gagne des deux côtés.

## 9. Contre-revue d’Opus

**21 novembre 2026 · Opus 5.5 (Claude Code) · lecture du code à `b51707fba`, sans nouvelle mesure sur appareil**

Les fichiers cités ci-dessous sont identiques entre la révision auditée `8889445` et `b51707fba`, ce qui permet de garder les liens sur la révision auditée. Aucun chiffre de cette section ne provient d’une nouvelle mesure. Les chiffres viennent du dossier ci-dessus, de la lecture du code ou de mesures Thor antérieures signalées comme telles.

### 9.1 Verdict

**L’investigation est solide sur le diagnostic, mais son ordre de livraison est trop prudent.** Les piles CPU, les deux reproductions à 1 305 et 1 313 ms et le chemin de code concordent : le sol de la carte active est construit en synchrone sur l’isolate UI. Le rapport est honnête sur ses limites, ce qui est rare et précieux. Trois points changent toutefois les priorités.

1. **Le cache le plus rentable manque.** Ce n’est ni le catalogue ni les modèles communs. C’est la scène déjà matérialisée de la carte qu’on vient de quitter. Le cas mesuré, Route 32 → poste → Route 32, reconstruit une géométrie qui existait deux secondes plus tôt (§9.3, D1).
2. **Le démarrage est le plus gros temps perdu.** Jouer → contrôle prend **38,7 s**, dont **19 s** à re-hacher tout le contenu installé à chaque lancement. Le rapport cherche à accélérer cette lecture, alors que le vrai sujet est le contrat de vérification (D3).
3. **La mémoire n’est mesurée nulle part.** Toutes les pistes de cache en dépendent, et le bug d’origine relevait précisément de la durée de vie des ressources (D6).

| Diagnostic du dossier | Statut | Raison |
|---|---|---|
| Gel au retour sur la Route 32 dû à `_SceneGround._resolveSteps` | **Établi, on peut agir** | 851/942 échantillons, deux passes concordantes, chemin synchrone confirmé : `workBudget` vaut `null` pour la placement active ([materialization L45][o-budget]). |
| Pic de 414–532 ms dans `invariantImageIds` | **Établi** | 244/251 et 176/194 échantillons. Le résultat est mémorisé par instance de plan ([resolver L1287][o-invariant]), mais le plan est recréé avec le chunk. |
| Menu pause : relecture de 4,3 Mio par ouverture | **Établi sur Mac** | Correctif local, gain iPhone non mesuré. |
| Cache de projections validées : 2,3–3,8 s → 312–335 ms | **Établi sur le chemin Mac du chargeur seulement** | Poids mémoire réel inconnu, et le gain sur la porte entière n’est pas mesuré. |
| 4 isolates = 255 ms | **Fragile** | Mac à cœurs homogènes. L’iPhone 15 Pro a 2 cœurs performance, et un Android milieu de gamme partage ses gros cœurs avec les threads UI, raster et pilote GPU. |
| Contre-exemple de l’isolate de rendu (575 → 1 617 ms) | **Mal attribué** | Le surcoût peut venir de la copie des entrées et des caches froids de l’isolate, pas du rapatriement du résultat (D5). |
| « Aucun intervalle > 50 ms en marche » | **Le plus susceptible de changer sur Android** | Mesure à 30 FPS, échelle 50 %, sur un téléphone haut de gamme. Le Thor montrait le 28/10 1 à 4 intervalles UI > 33 ms par tranche de 4,7 s, avec ~200 Mo/s d’allocation Dart. Cette piste reste non attribuée. |

### 9.2 Ce que la lecture du code confirme ou ajoute

| Point | Chemin | Constat |
|---|---|---|
| La scène de la carte quittée est jetée | [`spatial_scene_view.dart` L2611–L2688][o-chunks] | Un chunk n’est réutilisé que s’il fait encore partie des placements suivants (`previousChunk?.signature == signature`). Au commit, `sceneChunks = nextChunks` abandonne les autres, puis `cache.removeWhere` libère les modèles inutilisés par la carte active. |
| Projection Smart Tile gardée, plans recréés | [`spatial_scene_view.dart` L1916–L1955][o-projection] | La projection garde 8 entrées, indexées par `MapData`. Les plans de sol et d’occlusion, les maillages et `invariantImageIds` sont recalculés au retour. |
| Jouer re-hache tout le contenu | [`avelune_library_bridge.dart` L114][o-bridge] · [`installed_game_launch_resolver.dart` L20][o-resolver] | Le résolveur de lancement de l’embedding utilise la profondeur `content` par défaut. Celui de l’activité utilise `structure`. |
| Hachage en Dart pur | [`installed_game_verifier.dart` L462–L491][o-verifier] | SHA-256 de `package:crypto`, 4 workers par défaut et 8 au maximum, eux-mêmes lancés depuis un isolate. |
| Manifeste décodé plusieurs fois | [`installed_game_verifier.dart` L282][o-manifest] | Chaque vérification relit et décode `game-manifest.json` (62 328 entrées). Les deux vérifications structurelles de 1,99 et 2,24 s du §3 correspondent probablement à ce décodage en double. |
| Un pipeline par matériau | [`material.dart` L18][o-material] | `createResource` appelle `createPipeline` pour chaque instance de `Material`. Or `GlbRendererLayout` crée un `SpatialPixelMaterial` par primitive, alors que les paires de shaders distinctes se comptent sur les doigts. |

### 9.3 Désaccords et expérience la plus courte pour trancher

**D1. Le dossier cherche le mauvais recouvrement.** Il mesure **zéro modèle commun** entre Mauville et le Centre Pokémon, et en déduit que garder les modèles de la porte précédente aurait peu d’intérêt. Le bon motif n’est pas « ce qui est commun à A et B ». C’est **A → B → A**, le parcours le plus fréquent d’un jeu Pokémon : on entre dans un bâtiment puis on ressort. Garder le chunk complet de la carte extérieure pendant qu’on est dans un intérieur coûte au plus sa mémoire, soit 9 Mo de sommets pour la Route 32 sur le banc, plus ses modèles et textures. Cela supprime ensuite tout le travail du retour : sol, plans, Smart Tiles et décodage des modèles.

- *Expérience :* garder un emplacement « carte précédente » dans `sceneChunks` (chunk, réservations et textures de sol), puis rejouer **Route 32 → poste → Route 32** dix fois sur l’iPhone. Critère : pire intervalle du retour < 100 ms au lieu de 1 305 ms, et empreinte mémoire résidente (`phys_footprint`) mesurée avant et après.
- *Condition :* la rétention doit passer par les réservations existantes (`RuntimeResourceReservation`, `retainOptionally`) et céder sous pression du budget de 256 Mio. Sinon on recrée la classe de bug corrigée par `4608ec1c6`, avec une image libérée encore utilisée ou une image jamais libérée.

**D2. Le menu ne mérite pas la priorité 1 en impact, seulement en facilité.** Le dossier le classe premier parce qu’il est le plus simple à isoler. C’est vrai, et je le livrerais quand même tôt, car il ne coûte presque rien. En revanche, le joueur ressent d’abord les **38,7 s** avant le contrôle, puis le gel de 1,3 s aux portes, et seulement ensuite les 515 ms du menu. Un ordre par impact ressenti place le démarrage et les portes devant.

**D3. La vérification intégrale au lancement est un choix de contrat, pas un problème de lecture.** Re-hacher ~1,3 Go et 62 327 fichiers à *chaque* Jouer pour détecter une altération est disproportionné. Le dossier propose de regrouper les lectures ou de chevaucher le titre, ce qui ne fait que déplacer l’attente. Je propose plutôt :

1. au lancement, vérifier le pointeur, le reçu et le manifeste, puis l’inventaire (présence, taille, `mtime`) à partir d’un `stat` de chaque fichier. Le test [`a tampered file … cannot be played`][alteration] réécrit `project.json` avec une taille différente : il resterait vert ;
2. vérifier l’empreinte **à la lecture** de chaque fichier effectivement utilisé. Le catalogue le fait déjà pour ses objets (§6), il faut l’étendre aux GLB, textures et médias ;
3. lancer éventuellement un balayage complet en arrière-plan, à basse priorité, après la prise de contrôle, avec un message clair en cas d’écart.

C’est une décision qui revient à Yoahn : une altération de même taille et de même `mtime` sur une carte jamais visitée ne serait détectée qu’au moment où elle est lue. Pour un jeu amateur installé dans un bac à sable iOS ou Android, la menace réaliste est la corruption plutôt que la triche. La détection à la lecture couvre exactement le contenu qu’on exécute.

- *Expérience courte pour séparer E/S et calcul :* sur l’iPhone, chronométrer (a) un `stat` des 62 327 fichiers, (b) leur lecture sans hachage, (c) le chemin actuel. Si (b) ≪ (c), le coût est dans le SHA-256 en Dart pur. Le §7 va dans ce sens : copie avec hachage de 1,31 Go en 13,66 s, soit ~96 Mo/s.

**D4. Le rapport Mac/iPhone ×4 sur la même fonction n’est pas expliqué.** Le banc Mac construit les maillages de la Route 32 en **305 ms**, alors que l’iPhone y passe environ **1,18 s** (851 échantillons sur 1 313 ms). En monocœur, un A17 Pro est proche d’un M2. Un tel écart signale soit un travail différent (voisins, résolution, données réparées ou non), soit un banc en JIT, soit un téléphone bridé thermiquement. Tant que cet écart n’est pas compris, aucune durée Mac ne doit servir à dimensionner un budget mobile.

- *Expérience :* exécuter le même banc en `dart compile exe` sur Mac et comparer le nombre de visuels, de sommets et d’étapes avec un compteur ajouté dans la build Profile iPhone sur la même transition.
- *Mise à jour du 2026-11-21 :* un banc Mac qui rejoue le `refresh()` complet du renderer sur la même cartouche a mesuré un bloc synchrone de **1 078 à 1 170 ms** au retour du passage vers la Route 32. Ce banc tournait en JIT, sans GPU et sans voisines. L’écart ×4 vient donc probablement du périmètre mesuré par les 305 ms, et pas du téléphone. D4 perd l’essentiel de sa portée, mais la comparaison des compteurs reste utile.

**D5. Le contre-exemple de l’isolate ne condamne pas les isolates pour le sol.** `Isolate.run` transfère son résultat par `Isolate.exit`, ce qui évite une copie. Les **entrées**, en revanche, sont copiées, et l’isolate démarre sans aucun cache chaud. Un graphe de plans complet est le pire cas possible. Un maillage de sol produit sous forme de `Float32List` et `Uint32List` est au contraire le meilleur : 9 Mo de mémoire contiguë.

- *Expérience :* horodater dans l’essai existant l’entrée dans l’isolate, la fin du calcul et la réception, afin de séparer copie d’entrée, calcul et retour.

**D6. Aucune piste de cache ne devrait passer en production sans mesure de mémoire.** Le dossier le dit, mais le classe comme expérience suivante. Je le placerais comme **prérequis instrumental** commun aux priorités 2 et 3 : `phys_footprint` sur iOS, `PSS` et `dumpsys meminfo` sur Android, et compteur d’évictions du budget de 256 Mio. Le signalement initial portait sur un retour d’arrière-plan. Sur Android, un processus trop gros est tué par le Low Memory Killer pendant qu’il est en arrière-plan, et ce symptôme ressemble exactement à « la session ne revient pas ».

### 9.4 Pistes que le dossier ne couvre pas

| # | Piste | Gain attendu | Coût et risque |
|---|---|---|---|
| N1 | **Rétention de la carte précédente** (D1) | Retour par une porte : gel de 1,3 s → quasi nul | Faible en code, mémoire à borner, risque de durée de vie des ressources |
| N2 | **Préparation déclenchée à l’approche d’un passage.** Les sorties de chaque carte sont connues. Lancer `prepareDestination` lorsque le joueur se trouve à ≤ N cases d’un passage et lui fait face, avec les tranches coopératives existantes, puis l’annuler s’il s’éloigne. | Le travail se fait pendant que la carte source s’anime. Le noir n’attend plus que le reliquat. | Concurrence avec la marche : borner chaque tranche à quelques ms (cible 6 ms, comme dans l’essai du §4). |
| N3 | **Préchargement spéculatif de Continuer pendant l’écran titre.** La carte de la sauvegarde la plus récente est connue avant le choix. On peut ouvrir son catalogue, préchauffer les pipelines et préparer ses dépendances, puis tout annuler si le joueur choisit Nouvelle partie. | Une partie des 14,4 s de Continuer se recouvre avec le temps passé sur le titre | Mémoire et annulation propres. L’intro et le titre ne doivent pas saccader. |
| N4 | **Décoder le manifeste une seule fois par lancement.** Clé : chemin, taille, `mtime` et empreinte de l’arbre du pointeur. | ~2 s de CPU par vérification structurelle (§3) | Invalidation lors d’une mise à jour ou d’une réparation |
| N5 | **SHA-256 natif** pour l’installation et la vérification : CommonCrypto sur iOS et macOS, BoringSSL ou `MessageDigest` sur Android, appelés par FFI ou par le canal existant. | Probablement un ordre de grandeur sur le hachage (copie 13,7 s et inspection 58,8 s à l’installation). C’est à mesurer. | Une dépendance par plateforme et des vecteurs de test croisés obligatoires |
| N6 | **Un pipeline par paire de shaders**, mis en cache dans le backend plutôt que par matériau, et **préchauffé** pendant le titre avec les variantes réellement utilisées (blend, culling, instanciation). | Une partie des 617 échantillons de création de pipelines au premier Continuer. Le gain sera plus fort sur les pilotes Vulkan Android. | Le cache côté Impeller existe peut-être déjà : à vérifier en comptant les créations natives |
| N7 | **Cache disque des dérivés déterministes du sol** : `invariantImageIds`, plans et éventuellement maillages. Clé : empreinte de la carte, version du code de génération et réglages de rendu. Le cache serait écrit au premier passage ou à l’installation, comme l’index narratif. | La première visite d’une session devient aussi rapide qu’une revisite | Invalidation stricte. Le fichier reste optionnel avec repli sur le calcul, donc compatible avec les cartouches `0.3.31+331`. |
| N8 | **Plafonner les workers selon l’appareil** pendant la vérification et l’inspection (2 sur mobile au lieu de 4–8) | Splash et titre plus fluides pendant les vérifications | Durée totale un peu plus longue, à arbitrer sur le Thor |

**Premier essai de N1 (2026-11-21, Mac, non commité).** Le renderer garde le chunk de la dernière carte quittée, avec ses modèles et ses images de sol, et le réutilise si sa signature est identique. Sur un banc qui fait la boucle Route 32 → passage des Ruines → Route 32 sur la cartouche 0.1.17, le retour passe de **1 078–1 170 ms** de blocage à **8–12 ms**, et la préparation de **~0,8 s** à **0 ms**, pendant quatre cycles. Ce banc ne couvre ni le GPU, ni une scène Flame montée, ni le chargement des voisines, ni la mémoire réelle. Les réservations conservées sont optionnelles : quand le budget manque de place, la carte gardée est libérée en entier.

**Mesure iPhone 15 Pro (2026-11-21, build Profile QA isolée, même harnais pour les deux variantes, trois cycles).** Sur le retour du passage vers la Route 32, le plus grand écart entre deux images passe de **1 220–1 232 ms** sans rétention à **459–477 ms** avec rétention. L'entrée dans le passage reste entre 121 et 210 ms dans les deux cas. Les ~470 ms restants ne viennent ni du build (≤ 33 ms) ni du raster (≤ 74 ms) d'une image : un travail synchrone occupe le thread entre deux images. Un profil CPU pris sur le téléphone pendant ce gel l'a attribué à 97 % à `prepareDestination`. La préparation recalculait `invariantImageIds` pour la Route 32 alors que la carte gardée la couvrait déjà, parce que le court-circuit comparait la carte par identité et que la session repasse une copie égale. Une fois la comparaison faite par égalité, le retour tombe à **199–249 ms**. Ce temps tient désormais dans une seule image dont le build dure 200 à 250 ms, et sa cause reste à profiler.

### 9.5 Réponses aux trois questions demandées

**Découpage par image ou isolates ?** Les deux, mais pas pour le même travail.

- **Découpage par image** pour tout ce qui touche la scène vivante ou produit de gros graphes d’objets : plans, Smart Tiles, insertion des composants. Ce travail doit **commencer avant le noir** (N2). Après le noir, le découpage ne fait qu’allonger l’attente, ce que le dossier a bien vu.
- **Isolates (1, au plus 2, persistants)** pour le travail pur aux entrées et sorties compactes : décodage du catalogue, hachage et tessellation du sol si elle produit des tampons typés.
- Un parallélisme de 4 ne devrait pas être retenu à partir d’un banc Mac.

**Validité et mémoire des caches ?** Tout cache doit avoir une clé de contenu, pas d’identité. `MapData` est un modèle freezed, donc comparé en profondeur : c’est correct, mais son `hashCode` n’est pas mémorisé et se recalcule à chaque recherche. Il doit aussi passer par le système de réservations existant et céder sous le budget. Ordre recommandé :

1. rétention de la carte précédente (N1) ;
2. projections validées sous budget ;
3. cache disque des dérivés (N7).

Le poids JSON est un mauvais proxy du poids des objets Dart, souvent 3 à 10 fois plus gros. Il faut donc mesurer la mémoire réelle (D6).

**Accélérer le démarrage tout en détectant une installation modifiée ?** Oui, en déplaçant la garantie de « tout, à chaque lancement » vers « ce qu’on lit, quand on le lit » (D3). On ajoute un inventaire par `stat` au lancement et, si Yoahn veut garder une garantie complète, un balayage en arrière-plan. Le refus de jouer avec un fichier altéré reste vrai pour tout fichier effectivement utilisé.

### 9.6 Ordre de livraison révisé

| Ordre | Changement | Risque de régression concret | J’accepte si… | Je refuse si… |
|---|---|---|---|---|
| 0 | **Instrumentation** : mémoire résidente, évictions du budget, durée du noir et premier pas, sur l’iPhone et le Thor | Instrumentation coûteuse, comme le `getprop` sondé toutes les 60 frames qui créait de faux pics | Coût < 0,1 ms par frame, désactivé hors Profile | Il crée lui-même des pics mesurables |
| 1 | **Menu** : assets régionaux chargés seulement par la branche illustrée | Jeu illustré sans images ni vignettes | 104 lieux identiques sur HGSS, images correctes sur un jeu illustré, < 100 ms à chaud sur l’appareil | Une règle de visibilité des lieux change |
| 2 | **Rétention de la carte précédente** (N1) | Ressource libérée puis encore utilisée, ou fuite qui pousse vers le Low Memory Killer | 10 allers-retours école et poste sans gel > 100 ms, mémoire stable après 10 circuits, retour d’arrière-plan correct | Mémoire croissante d’un circuit à l’autre, ou toute réapparition de « Source d’animation indisponible » |
| 3 | **Démarrage** : manifeste décodé une fois (N4), contrat de vérification (D3) après décision de Yoahn, préchauffage des pipelines (N6) | Fichier altéré accepté, ou vérification contournée par une mise à jour partielle | Jouer → contrôle réduit d’au moins 15 s sur l’iPhone, test d’altération vert, nouveaux tests d’altération de même taille détectés à la lecture | Un fichier corrompu peut être chargé sans erreur |
| 4 | **Préparation à l’approche des passages** (N2) avec tranches de 6 ms sur le sol actif et les Smart Tiles | Saccades de marche près des passages, travail orphelin si le joueur change d’avis | Marche près d’un passage sans intervalle > 50 ms, annulation testée, noir < 300 ms à froid | La marche près d’un passage se dégrade |
| 5 | **Projections validées sous budget**, puis cache disque des dérivés (N7) | Données périmées après modification de carte ou de bordure | Circuit Ruines → hall → sous-sol → Ruines identique au témoin, bordure altérée toujours détectée | Une seule divergence d’empreinte |
| 6 | Index d’espèces, SHA-256 natif (N5), format compact | Anciennes cartouches illisibles, écarts de hachage entre plateformes | Lecture des cartouches `0.3.31+331`, vecteurs de test SHA-256 identiques | Lecteur de compatibilité absent |

**À repousser malgré leur bon chiffre sur Mac :** les **4 isolates** (255 ms) et le **bloc contigu** (54 ms). Le premier dépend d’une topologie de cœurs propre au Mac. Le second impose un nouveau format, avec son index, son contrôle et un lecteur de compatibilité, pour un gain que la rétention et le cache des projections captent en grande partie sans toucher au format.

### 9.7 Campagne Android

L’absence de campagne Android est la plus grosse limite, alors que Yoahn constate le problème sur Android. Le Thor a déjà servi aux mesures d’octobre et la méthode d’allocation y est rodée : il faut le réutiliser. Il faut aussi ajouter un Android milieu de gamme, car le Thor est haut de gamme. Points spécifiques à mesurer :

- **Pipelines Vulkan :** création et compilation plus lentes que sur Metal selon les pilotes Adreno et Mali. Vérifier aussi qu’Impeller n’est pas retombé sur OpenGL ES.
- **E/S :** coût d’ouverture de 62 k petits fichiers sur le stockage interne.
- **Cœurs :** répartition big.LITTLE et effet des 4–8 isolates de vérification sur le splash.
- **Mémoire :** tuerie en arrière-plan par le Low Memory Killer, puis reprise de session (scénario du signalement initial).
- **Thermique :** dérive sur 10 minutes de circuits répétés.
- **Mesure :** ne jamais sonder `getprop` pendant les mesures de saccades. Ce sondage crée à lui seul un pic de 13–14 ms.

### 9.8 Points qui demandent encore une lecture du code ou une mesure

- Ce que fait exactement l’initialisation native recensée par les 617 échantillons : création du `RenderPipeline` Flutter GPU ou compilation du PSO à son premier usage.
- La cause du rapport ×4 entre Mac et iPhone (D4).
- La couverture de la vérification à la lecture hors catalogue : GLB, textures et audio.
- Le comportement du Player lorsque la carte de retour immédiat est conservée côté catalogue, mais que l’instance `MapData` change. Le chunk n’est réutilisé que si la signature est égale.

[o-budget]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/packages/map_render_3d/lib/src/spatial_scene_materialization.dart#L45
[o-invariant]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/packages/map_core/lib/src/operations/smart_tile_layer_visual_resolver.dart#L1287
[o-chunks]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/packages/map_render_3d/lib/src/spatial_scene_view.dart#L2611-L2688
[o-projection]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/packages/map_render_3d/lib/src/spatial_scene_view.dart#L1916-L1955
[o-bridge]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/apps/pokemap_hub/lib/embedding/avelune_library_bridge.dart#L114
[o-resolver]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/apps/pokemap_hub/lib/features/session/data/repositories/installed_game_launch_resolver.dart#L20
[o-verifier]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/apps/pokemap_hub/lib/features/installation/data/repositories/installed_game_verifier.dart#L462-L491
[o-manifest]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/apps/pokemap_hub/lib/features/installation/data/repositories/installed_game_verifier.dart#L282
[o-material]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/third_party/flame_3d/lib/src/resources/material/material.dart#L18

## Annexe — vérifications, limites et reproductibilité

**État de livraison.** Les deux commits du Player sont dans l’historique de `origin/main` vérifié à la rédaction. La correction des quatre bordures se trouve dans le projet auteur HeartGold pour son prochain export. Les variantes de découpage, de cache pondéré, de lecture sélective et de menu présentées comme essais ont été évaluées dans des copies QA. Aucun lot de mécanique de jeu numéroté n’a été ouvert pour cet audit transversal. La contre-revue d’Opus figure en section 9.

**Tests du code livré.** La dernière exécution ciblée sur `packages/map_runtime` a rendu **`+72: All tests passed!`** avec la commande suivante.

```sh
flutter test --no-pub -r failures-only \
  test/runtime_project_catalog_exterior_dependencies_test.dart \
  test/application/runtime_map_bundle_exterior_decoration_test.dart \
  test/spatial_native_door_traversal_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart
```

L’analyse ciblée `dart analyze lib/src/application/load_runtime_map_bundle.dart test/runtime_project_catalog_exterior_dependencies_test.dart` a signalé deux informations de style `curly_braces_in_flow_control_structures`. L’APK Android arm64 a été compilé et sa signature vérifiée. Les 58 tests Android natifs ont réussi lors de la validation des correctifs. Les deux parcours combat réalisés pour l’audit ont également terminé avec succès sur Mac. Les chiffres de cadence sont issus des mesures physiques décrites ci-dessus.

**CI du commit audité.** Le contrôle GitHub Actions `repository-contracts` s’est terminé en échec dans l’étape `Editor smoke and static checks`, avec **18 tests réussis et 2 en échec**. Les deux tests de `github_distribution_workflow_test.dart` inspectent le workflow de distribution du Studio desktop, l’un pour les trois plateformes, l’autre pour le tag et le build avant signature. Les attentes en échec portent sur `working-directory: packages/map_editor` et `--pubspec ../../apps/avelune_studio/pubspec.yaml`. Le statut global de cette révision reste rouge. [Exécution CI et journal des tests][ci]

**Empreintes pour retrouver la même cartouche.**

| Objet | Valeur |
|---|---|
| Nom de l’archive testée | `Pokemon HeartGold - 0.1.17-dev.alpha - Cris.avelunegame` |
| Taille de l’archive | 1 311 965 365 octets |
| SHA-256 de l’archive | `e54445ac0daf001c33b3c8ee293ad59493d4f2b1de8b04faabe98b43e099e0f1` |
| Empreinte de l’arborescence déclarée dans le manifeste | `06e3975657f40ac9eeb507c35271ecd7ce35c5e47fdee40d2b9f5ae678e5da7f` |
| Carte des Ruines dans l’export public, SHA-256 | `798c67a997311b167613bf3fc57d4f5d7d69e7c0775732cbdb66823f6b989e3d` |
| Résultat des quatre variantes de décodage des définitions des Ruines, SHA-256 | `b055914fdd02fddf639005e83421d00f3c4895a0000bb24489b9fdaf93f41782` |

Les traces brutes volumineuses, le binaire de test et les copies de sauvegarde ont été supprimés à la fin de la campagne. Ce dossier restitue les mesures consignées, les conditions et les chemins de code publics à la révision auditée. Une vérification indépendante des piles ou une nouvelle statistique demande de rejouer le parcours. Les empreintes de l’archive et de sa carte des Ruines ont été recalculées à la rédaction, et celle de l’arborescence relue dans le manifeste. La dernière empreinte est celle consignée par le banc de décodage avec le même ordre d’entrée pour les quatre variantes. Le temps GPU matériel, la performance Android physique et la cadence sur des sessions prolongées constituent les trois principales limites de cette revue.

MCP parity: N/A

[revision]: https://github.com/yoahnl/pokemap/tree/8889445899c498f1dc934535fd6783a57ffb6d44
[fix-portes]: https://github.com/yoahnl/pokemap/commit/4608ec1c6838321a049e8c82b3e3b79b51b10419
[fix-chargeur]: https://github.com/yoahnl/pokemap/commit/8889445899c498f1dc934535fd6783a57ffb6d44
[test-portes]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/packages/map_runtime/test/spatial_native_door_traversal_test.dart
[test-decor]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/packages/map_runtime/test/runtime_project_catalog_exterior_dependencies_test.dart
[hud]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/apps/pokemap_hub/lib/embedding/avelune_runtime_diagnostics.dart#L128
[compatibilite]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/documentation/architecture/product_and_architecture_policies.md#L63
[maillages]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/packages/map_render_3d/lib/src/spatial_scene_view.dart#L4055
[smart-tiles]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/packages/map_core/lib/src/operations/smart_tile_layer_visual_resolver.dart#L1290
[tranches]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/packages/map_render_3d/lib/src/spatial_scene_materialization.dart#L45
[eviction]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/packages/map_render_3d/lib/src/spatial_scene_view.dart#L2688
[catalogue]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/packages/map_runtime/lib/src/application/runtime_project_catalog.dart#L487
[lecture-objets]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/packages/map_runtime/lib/src/application/runtime_project_catalog.dart#L853
[bordures]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/packages/map_runtime/lib/src/border/border_runtime_readiness.dart#L58
[decodeur]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/packages/map_core/lib/src/catalog_storage/catalog_storage.dart#L2150
[metadonnees]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/packages/map_core/lib/src/catalog_storage/portable_catalog_publication.dart#L98
[demarrage]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/apps/pokemap_hub/lib/features/session/application/services/hub_runtime_startup_bootstrap.dart#L150
[verif-lancement]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/apps/pokemap_hub/lib/features/session/data/repositories/installed_game_launch_resolver.dart#L20
[alteration]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/apps/pokemap_hub/test/embedding/avelune_library_bridge_test.dart#L458
[pipelines]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/third_party/flame_3d/lib/src/graphics/backend/flutter_gpu/gpu_backend.dart#L89
[index-narratif]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/apps/pokemap_hub/lib/features/session/data/repositories/hub_prepared_narrative_index.dart#L98
[menu]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/packages/map_runtime/lib/src/player/runtime_regional_map_builder.dart#L111
[especes]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart#L242
[installation]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/apps/pokemap_hub/lib/features/installation/data/repositories/game_package_installer.dart#L249
[progression]: https://github.com/yoahnl/pokemap/blob/8889445899c498f1dc934535fd6783a57ffb6d44/apps/pokemap_hub/lib/features/installation/data/repositories/install_staging.dart#L314
[ci]: https://github.com/yoahnl/pokemap/actions/runs/44860365270
