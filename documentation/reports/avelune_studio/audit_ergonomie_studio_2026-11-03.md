# Avelune Studio — audit de l’interface et des parcours de création

**Date :** 3 novembre 2026. **Nature :** revue de l’existant et recommandations, sans maquette ni modification du produit. **Public visé :** personnes qui veulent créer un jeu sans devoir connaître les concepts internes du moteur, tout en laissant aux auteurs expérimentés la précision dont ils ont besoin.

## Lecture rapide

Avelune Studio dispose déjà de fondations utiles : un éditeur de carte central, des aides contextuelles, des vues de ressources, des graphes narratifs, des aperçus et des messages qui distinguent parfois les changements enregistrés des brouillons. Le problème principal n’est pas l’absence de fonctions. C’est qu’une même intention — placer un personnage, configurer une scène, choisir une ressource ou tester le jeu — oblige souvent l’auteur à comprendre **dans quel mode il se trouve, quelle portée il modifie et quel document doit être enregistré** avant même d’accomplir sa tâche.

Les risques les plus importants à traiter d’abord sont :

1. Rendre **l’action du prochain clic** explicite dans l’éditeur de carte ; l’outil actif et la palette affichée peuvent aujourd’hui raconter deux choses différentes.
2. Clarifier **les documents, leur portée et l’enregistrement** : carte, ambiance, projet, personnage, scène et événement n’ont pas tous la même frontière de sauvegarde.
3. Transformer les identifiants et champs techniques des parcours courants en **choix compréhensibles et vérifiés**, sans supprimer l’accès avancé ni perdre les références existantes.
4. Relier les tâches en parcours concrets : **créer un lieu → le peupler → ajouter une interaction → tester → corriger → revenir**, plutôt que demander à l’utilisateur d’assembler seul des ateliers.
5. Faire des erreurs et états vides des **points de reprise** : dire ce qui est connu, ce qui manque et l’action réellement possible.
6. Garder les commandes puissantes, mais les révéler au moment où elles sont utiles ; une simplification ne doit pas retirer les capacités existantes ou tricher sur leur disponibilité réelle.

**Statut de la revue : partielle mais exploitable pour lancer la conception.** Elle couvre les captures disponibles et le code pertinent, pas tous les états de Studio. Il n’y a pas eu de test avec des débutants, de contrôle complet au clavier ou lecteur d’écran, de mesure de contraste ni de certification de performance. Les conséquences sur l’utilisateur sont des risques raisonnés, pas des résultats de tests observés. Aucun changement UI ou maquette n’a été réalisé.

## Périmètre, méthode et limites

- Références locales : [guide des captures](</Users/karim/Project/Avelune Studio - Atlas UI/guide.html>), [galerie](</Users/karim/Project/Avelune Studio - Atlas UI/index.html>) et [matrice de repérage](</Users/karim/Project/Avelune Studio - Atlas UI/inventaire.html>). Les 74 fichiers ne signifient pas 74 écrans uniques ou tous les états possibles.
- Les captures HGSS proviennent d’une session Studio Release spéciale avec une **copie** du projet ; son ancien historique d’édition n’a pas été recopié. Elles ne prouvent ni le comportement de l’original ni toutes les configurations. Le code examiné est celui du dépôt local, base `main` à `51f1ece7854d67dbdb1a4fa7937a09fa11331693`, avec travail local non commité : le SHA ne décrit pas à lui seul tous les fichiers observés ou le binaire de capture.
- Contrôle de preuve : les captures [01](</Users/karim/Project/Avelune Studio - Atlas UI/captures/01-carte-chambre.png>) et [04](</Users/karim/Project/Avelune Studio - Atlas UI/captures/04-carte-decors.png>) sont **identiques octet pour octet**. La capture 04 ne prouve donc pas à elle seule un outil Décors actif. Les vues [35](</Users/karim/Project/Avelune Studio - Atlas UI/captures/35-reglages-test.png>), [47](</Users/karim/Project/Avelune Studio - Atlas UI/captures/47-cinematique-proprietes.png>) et [69](</Users/karim/Project/Avelune Studio - Atlas UI/captures/69-cartes-catalogue.png>) montrent du chargement ; elles servent à examiner cet état, pas à représenter un écran terminé.
- Trois passes indépendantes ont étudié respectivement Carte/région, narration et ressources/Pokémon/réglages. Leurs constats ont été recoupés avec les captures et les points du code cités ci-dessous. Les captures Mobbin sont des références de structure d’autres produits, pas des preuves concernant Avelune ni une validation des solutions proposées.
- **Niveau de preuve** : « capture + code » signifie que la situation visible et la construction correspondante ont été examinées ; « code seul » signifie qu’une reproduction manque ; « capture seule » signifie que l’interprétation attend un parcours ou du code complémentaire. La priorité indique l’impact potentiel sur l’intention de l’auteur, pas un nombre d’utilisateurs touchés mesuré.
- **P1 :** à instruire en premier car risque de mauvais geste, de perte de confiance ou de parcours bloqué. **P2 :** friction importante ou récurrente. **P3 :** précision, qualité visuelle ou amélioration sous réserve de validation. Les points de sécurité d’écriture, de compatibilité ou d’accessibilité ne sont pas résolus par un simple changement de libellé.

## 1. L’expérience globale : aider à finir une tâche

### G01 · L’accueil présente des outils plutôt qu’un prochain objectif — P2

**Preuve — capture + code :** [02 — accueil](</Users/karim/Project/Avelune Studio - Atlas UI/captures/02-accueil-projet.png>) présente le projet, les raccourcis Carte, Ressources, Terrains, Placer un personnage, Histoire, Tester et une aide « Premiers pas » repliée. Les raccourcis et leur ordre sont définis dans [studio_home_tools.dart](../../../apps/avelune_studio/lib/presentation/features/home/studio_home_tools.dart#L39), l’aide dans [studio_home_guidance.dart](../../../apps/avelune_studio/lib/presentation/features/home/studio_home_guidance.dart#L14).

![Accueil du projet HGSS montrant navigation et outils](</Users/karim/Project/Avelune Studio - Atlas UI/captures/02-accueil-projet.png>)

**Problème et impact.** Un nouvel auteur voit des espaces et des objets de l’outil mais pas clairement le prochain geste pour obtenir un premier résultat jouable. La bannière occupe aussi une place importante avant les cartes et la progression utile. Ce n’est pas une preuve d’échec à l’onboarding ; il faut l’observer avec de vrais utilisateurs.

**Proposition.** Après ouverture, afficher un parcours court lié à l’état réel : « Ouvrir ou créer une carte », « Définir le départ », « Placer un personnage », « Ajouter une interaction », « Tester ». Chaque étape doit mener à la bonne action, indiquer « à faire / fait / non vérifié » uniquement sur preuve, pouvoir être ignorée et laisser les accès directs aux experts. Réduire le poids de l’illustration quand elle ne contribue plus à la tâche.

### G02 · « Tester » et « Tester le jeu » sont deux intentions distinctes mais trop proches — P1

**Preuve — capture + code :** [02 — accueil](</Users/karim/Project/Avelune Studio - Atlas UI/captures/02-accueil-projet.png>) montre une tuile « Tester » et un bouton « Tester le jeu ». Dans [workspace_home_binding.dart](../../../apps/avelune_studio/lib/presentation/features/map_workspace/workspace_home_binding.dart#L190), `testGame` appelle un test du projet complet, tandis que `test` appelle le test de la carte/contexte actif.

**Problème et impact.** Les libellés ressemblent à deux accès identiques alors que le point de départ et la portée diffèrent. On peut croire tester l’ouverture complète du jeu alors qu’on teste une carte, ou l’inverse.

**Proposition.** Nommer « Tester cette carte » et « Tester le jeu depuis le début » lorsque ces formulations correspondent au comportement réel. Montrer avant lancement la carte de départ ou le contexte utilisé, les modifications prises en compte et le moyen de revenir à l’édition. Conserver les deux parcours, utiles pour des tâches différentes.

### G03 · « Projet ouvert — lecture seule » ne précise pas quelle lecture est concernée — P1

**Preuve — capture + code :** [02 — accueil](</Users/karim/Project/Avelune Studio - Atlas UI/captures/02-accueil-projet.png>) affiche ce message en même temps que des entrées de création ; [project_open_controls.dart](../../../apps/avelune_studio/lib/presentation/features/project_session/project_open_controls.dart#L74) l’affiche dès que `state.project != null`.

**Problème et impact.** Le texte semble qualifier le projet entier alors que l’interface propose des éditeurs et que ce composant décrit au minimum l’état de la session d’ouverture. La capture ne prouve pas à elle seule que toutes les écritures sont possibles ou impossibles.

**Proposition.** Établir d’abord l’autorité effective de chaque session. Afficher « Lecture seule » au niveau du document réellement concerné seulement si l’écriture y est effectivement impossible, avec raison et action disponible ; sinon remplacer cette mention globale par un état exact. Tester une session en écriture et une vraie session en lecture seule.

### G04 · Le vocabulaire change de portée en changeant d’espace — P2

**Preuve — capture + code :** [32 — réglages](</Users/karim/Project/Avelune Studio - Atlas UI/captures/32-reglages-principal.png>) appelle « Scène à tester » une option dont les valeurs proviennent de `project.maps` dans [project_settings_page.dart](../../../apps/avelune_studio/lib/presentation/features/project_settings/project_settings_page.dart#L196) ; dans Histoire, une scène est un graphe narratif ([20](</Users/karim/Project/Avelune Studio - Atlas UI/captures/20-scene-graphe.png>)).

**Proposition.** Utiliser « Carte à tester » tant que le sélecteur contient des cartes et réserver « scène » au document narratif. Définir un lexique commun pour projet, carte, région, scène, événement, présentation, ressource et instance, avec un exemple court au point de décision. Ne pas renommer les données persistées simplement pour changer l’interface.

## 2. Création de projet et de carte

### C01 · Le choix 2D/3D est clair, mais ses conséquences arrivent tard — P2

**Preuve — capture + code :** [59 — 2D](</Users/karim/Project/Avelune Studio - Atlas UI/captures/59-nouveau-projet-modele-2d-jouable.png>), [60 — 3D](</Users/karim/Project/Avelune Studio - Atlas UI/captures/60-nouveau-projet-modele-3d.png>) et [62 — destination](</Users/karim/Project/Avelune Studio - Atlas UI/captures/62-nouveau-projet-destination.png>). Le code précise que le projet 3D démarre avec terrain plat, sans personnage, et que la synthèse des modèles intégrés peut mentionner Pokémon désactivés ([project_creation_steps.dart](../../../apps/avelune_studio/lib/presentation/features/project_creation/project_creation_steps.dart#L98)).

**Impact.** La différence entre « petit projet jouable », « projet vide » et « 3D vide » est décrite, mais la distance jusqu’au premier test, les éléments inclus et les limites ne sont pas comparés au même endroit. Une personne novice peut choisir selon l’apparence plutôt que selon ce qu’elle pourra faire tout de suite.

**Proposition.** Comparer, au moment du choix, les contenus réellement inclus : carte, personnage, départ, Pokémon, ressources et actions nécessaires avant test. Étiqueter « prêt à tester » seulement si un test vérifié le confirme. Préserver l’explication existante sur les conséquences 2D/3D et le récapitulatif avant création.

### C02 · La création commence par une distinction nom / dossier avant l’intention créative — P2

**Preuve — capture + code :** [57 — informations](</Users/karim/Project/Avelune Studio - Atlas UI/captures/57-nouveau-projet-informations.png>) expose deux champs ; le nom de dossier est suggéré et reste modifiable ([project_creation_steps.dart](../../../apps/avelune_studio/lib/presentation/features/project_creation/project_creation_steps.dart#L51)). [58 — validation](</Users/karim/Project/Avelune Studio - Atlas UI/captures/58-nouveau-projet-validation.png>) montre une erreur située pour le nom manquant : c’est un point fort à conserver.

**Proposition.** Donner la priorité au nom du jeu et présenter le nom du dossier comme option ajustable avec aperçu du chemin final. Ne pas masquer le choix de destination ni affaiblir les vérifications de dossier existant. Vérifier si les auteurs souhaitent réellement modifier les deux noms avant de les fusionner visuellement.

### C03 · La planche par défaut mélange des ressources dont l’usage n’est pas explicite — P2

**Preuve — capture + code :** [73 — menu des planches](</Users/karim/Project/Avelune Studio - Atlas UI/captures/73-carte-menu-planches.png>) affiche Joueur et Joueuse près de sols ; le menu utilise les planches du projet dans [map_catalogue_creation_dialog.dart](../../../apps/avelune_studio/lib/presentation/features/map_workspace/map_catalogue_creation_dialog.dart#L124).

**Proposition.** Dire à quoi sert cette planche, montrer un aperçu et organiser par usage. Si le modèle fournit une classification fiable, ne proposer par défaut que les choix compatibles ; sinon garder les ressources accessibles mais clairement identifiées. Le nom d’une planche ne suffit pas à établir qu’elle est techniquement invalide.

## 3. Carte : rendre le geste évident

### M01 · Palette et outil actif peuvent indiquer deux intentions différentes — P1

**Preuve — capture + code :** [01 — carte](</Users/karim/Project/Avelune Studio - Atlas UI/captures/01-carte-chambre.png>), [07 — environnements](</Users/karim/Project/Avelune Studio - Atlas UI/captures/07-carte-environnements.png>) et [09 — passages](</Users/karim/Project/Avelune Studio - Atlas UI/captures/09-carte-passages.png>) montrent une catégorie en bas alors que « Sélection » reste actif en haut. [map_workspace_tool_strip_actions.dart](../../../apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_tool_strip_actions.dart#L8) conserve la sélection si aucun décor n’est choisi ; [map_workspace_palette_dock.dart](../../../apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_palette_dock.dart#L102) peut changer la catégorie de palette indépendamment.

![Carte avec outil Sélection et palette Décors visibles simultanément](</Users/karim/Project/Avelune Studio - Atlas UI/captures/01-carte-chambre.png>)

**Impact.** L’auteur peut penser placer un objet et sélectionner la carte à la place. Ce risque est corroboré par le code ; sa fréquence et sa gravité chez des utilisateurs restent à mesurer.

**Proposition.** Réunir à proximité de la carte : « action active », « ressource choisie » et « prochaine étape ». Exemple : « Placement de décor · choisissez un décor » ; tant qu’aucun placement n’est possible, la carte ne doit pas laisser croire que le geste est armé. La catégorie consultée peut rester distincte si son statut est nommé. Préserver la sélection et l’édition de tous les objets existants.

### M02 · Les actions essentielles sont cachées dans un menu qui répète aussi la barre — P1

**Preuve — code :** [map_workspace_tool_strip.dart](../../../apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_tool_strip.dart#L60) affiche les familles ; son menu supplémentaire contient notamment personnage, départ, panneau et obstacles, mais aussi Passages et Connexions déjà dans la barre. Les actions correspondantes réutilisent les mêmes préparations dans [map_workspace_tool_strip_actions.dart](../../../apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_tool_strip_actions.dart#L59).

**Proposition.** Donner une place découvrable aux intentions « Personnages », « Départ », « Interaction » et « Passages », et regrouper les variantes secondaires à l’intérieur de ces tâches. Les raccourcis réellement utiles peuvent rester à plusieurs endroits, mais ils doivent avoir le même nom, le même résultat et un état cohérent.

### M03 · Le panneau inférieur peut être sans rapport avec l’outil courant — P2

**Preuve — capture + code :** [08 — collisions](</Users/karim/Project/Avelune Studio - Atlas UI/captures/08-carte-collisions.png>) affiche Collisions actif et une palette Environnements vide. Le choix Collisions modifie `view.tool` sans changer `paletteTab` ([actions](../../../apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_tool_strip_actions.dart#L26)).

**Proposition.** Quand une tâche n’utilise pas de palette, montrer une légende et des commandes pertinentes — peindre, effacer, état de la case — ou replier le panneau avec un moyen explicite de le rouvrir. Ne pas effacer silencieusement la palette précédente.

### M04 · Une instruction peut renvoyer vers un panneau absent dans la session de capture — P1

**Preuve — capture + code :** [10 — connexions](</Users/karim/Project/Avelune Studio - Atlas UI/captures/10-carte-connexions.png>) demande de choisir un bord et une carte à droite alors que l’inspecteur visible montre autre chose. Le panneau est conditionné par des callbacks dans [map_selection_inspector.dart](../../../apps/avelune_studio/lib/presentation/features/map_workspace/map_selection_inspector.dart#L91) et [workspace_screen_body.dart](../../../apps/avelune_studio/lib/presentation/features/map_workspace/workspace_screen_body.dart#L118).

**Proposition.** Ouvrir le panneau attendu lorsque les capacités sont disponibles ; sinon afficher à cet endroit pourquoi et comment continuer. Reproduire d’abord dans un Studio normal : l’état observé vient du build de capture, donc il n’établit pas un défaut généralisé.

### M05 · Noms tronqués et recherches différentes rendent le bon choix difficile — P2

**Preuve — capture + code :** [01 — carte](</Users/karim/Project/Avelune Studio - Atlas UI/captures/01-carte-chambre.png>) montre plusieurs cartes « Maison du jou… » et des ressources tronquées. L’arbre est indenté ([map_library_row_tile.dart](../../../apps/avelune_studio/lib/presentation/features/map_workspace/map_library_row_tile.dart#L51)), les vignettes du dock limitent les lignes ([map_workspace_palette_dock.dart](../../../apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_palette_dock.dart#L208)) et le sélecteur supérieur tronque aussi les titres ([map_workspace_toolbar.dart](../../../apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_toolbar.dart#L203)).

**Proposition.** Autoriser une largeur de panneau adaptée, montrer le nom complet et le chemin au focus/sélection, proposer une recherche qui comprend noms et dossiers. Garder l’arbre pour l’organisation et le sélecteur pour un changement rapide : ce ne sont pas nécessairement des doublons à supprimer.

### M06 · La recherche disparaît dans un dock étroit — P2, code seul

Dans [map_workspace_palette_dock_filters.dart](../../../apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_palette_dock_filters.dart#L90), champ et bouton de recherche du dock ne sont pas construits sous 420 px. Une recherche peut exister ailleurs ; le constat concerne cette palette uniquement. **Proposition :** conserver un accès visible et utilisable au clavier dans la variante étroite et tester avec panneau réduit, texte agrandi et fenêtre compacte.

### M07 · L’état vide de Bordures présente des consignes concurrentes — P2

**Preuve — capture + code :** [06 — bordures](</Users/karim/Project/Avelune Studio - Atlas UI/captures/06-carte-bordures.png>) montre une absence de modèle, une invitation à en créer et un message de filtre vide. [map_border_tool_panel.dart](../../../apps/avelune_studio/lib/presentation/features/map_workspace/map_border_tool_panel.dart#L540) et [map_workspace_palette_dock.dart](../../../apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_palette_dock.dart#L195) produisent des états distincts.

**Proposition.** Distinguer « aucun modèle dans le projet », « aucun résultat pour ces filtres », « chargement » et « erreur » ; proposer créer ou importer, puis revenir à la même carte et au même outil. Préserver le système natif de bordures et ses règles de contour.

### M08 · Ambiance et sauvegarde apparaissent à plusieurs endroits avec des périmètres différents — P1

**Preuve — capture + code :** [01 — carte](</Users/karim/Project/Avelune Studio - Atlas UI/captures/01-carte-chambre.png>) montre l’accès Ambiance et des réglages dans l’inspecteur. Le panneau Ambiance inclut jour/nuit et météo ([map_ambiance_panel.dart](../../../apps/avelune_studio/lib/presentation/features/map_workspace/map_ambiance_panel.dart#L152)), tandis que l’inspecteur inclut aussi jour/nuit ([map_workspace_inspector.dart](../../../apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_inspector.dart#L428)). Les actions de sauvegarde ne couvrent pas nécessairement le même périmètre.

**Proposition.** Une destination d’ambiance de carte identifiable, accessible depuis plusieurs raccourcis si utile, avec une seule explication de la portée de chaque enregistrement. Avant de fusionner des boutons, documenter les transactions effectivement différentes ; conserver annulation et persistance sûres.

### M09 · La carte régionale peut lier silencieusement la première carte — P1, code seul

À la création d’un lieu et à l’activation de Vol, la première carte peut devenir la carte de découverte ou la destination initiale ([regional_map_page.dart](../../../apps/avelune_studio/lib/presentation/features/regional_map/regional_map_page.dart#L64), [regional_map_controller.dart](../../../apps/avelune_studio/lib/features/regional_map/application/regional_map_controller.dart#L240), [destination Vol](../../../apps/avelune_studio/lib/presentation/features/regional_map/regional_map_page.dart#L480)). **Impact possible :** une association arbitraire peut être conservée. **Proposition :** demander ou confirmer la carte avec nom, dossier et aperçu, sans changer les liens déjà enregistrés. La [capture 03](</Users/karim/Project/Avelune Studio - Atlas UI/captures/03-carte-regionale-vide.png>) ne montre pas ce parcours : reproduction requise.

### M10 · Les lieux régionaux et les aperçus manquent de guidage à grande échelle — P2

Le sélecteur de cartes liées construit une ligne par carte et un retrait interdit peut ne pas expliquer la règle ([regional_map_page.dart](../../../apps/avelune_studio/lib/presentation/features/regional_map/regional_map_page.dart#L411)). La page peut également afficher « Image indisponible » avant résolution de l’aperçu ([regional_map_page.dart](../../../apps/avelune_studio/lib/presentation/features/regional_map/regional_map_page.dart#L224)). **Proposition :** recherche multi-sélection avec dossier, résumé des choix et explication de l’invariant ; distinguer attente, absence et erreur. La photo [69](</Users/karim/Project/Avelune Studio - Atlas UI/captures/69-cartes-catalogue.png>) montre 102 cartes et des chargements, mais ne prouve pas leur durée générale ni la cause de la lenteur observée en QA.

## 4. Narration : partir de l’intention, pas des objets internes

### N01 · L’entrée Histoire demande d’apprendre le modèle avant de raconter — P1

**Preuve — capture + code :** [19 — Histoire](</Users/karim/Project/Avelune Studio - Atlas UI/captures/19-histoire-accueil.png>) présente simultanément histoire, scène, événement, cinématique sur carte, présentation et vérification ; ces actions sont distinctes dans [narrative_overview_landing.dart](../../../apps/avelune_studio/lib/presentation/features/narrative/narrative_overview_landing.dart#L249).

![Accueil Histoire et ses différents types de documents](</Users/karim/Project/Avelune Studio - Atlas UI/captures/19-histoire-accueil.png>)

**Proposition.** À côté des accès directs, proposer des entrées orientées résultat : « Faire parler un personnage », « Déclencher une scène en entrant », « Créer une quête », « Mettre en scène un déplacement ». Le parcours explique ensuite quels objets sont créés, leur portée et où les modifier ; il ne doit pas dissimuler des documents séparés ou prétendre que tout est déjà pris en charge.

### N02 · Choisir une scène d’événement devient difficile dans un gros projet — P1

[41 — scène de l’événement](</Users/karim/Project/Avelune Studio - Atlas UI/captures/41-evenements-scene.png>) et [19 — 426 scènes](</Users/karim/Project/Avelune Studio - Atlas UI/captures/19-histoire-accueil.png>) illustrent l’échelle ; [event_scene_panel.dart](../../../apps/avelune_studio/lib/presentation/features/events/event_scene_panel.dart#L23) construit la liste, avec l’identifiant sur chaque ligne et sans champ de recherche dans ce panneau. **Proposition :** rechercher par nom et contexte disponible, afficher la scène déjà liée en premier et garder l’identifiant en détails. Ne pas affirmer que toutes les scènes possèdent déjà une carte associée exploitable comme filtre.

### N03 · Le graphe long oblige à choisir entre vue d’ensemble et lecture — P1

[20 — graphe](</Users/karim/Project/Avelune Studio - Atlas UI/captures/20-scene-graphe.png>) montre une scène dense zoomée à 50 %, aux titres tronqués et aux liens croisés. Les libellés de blocs sont limités dans [scene_canvas_node.dart](../../../apps/avelune_studio/lib/presentation/features/scenes/scene_canvas_node.dart#L164). **Proposition :** compléter zoom et mini-carte existants par recherche de bloc, recentrage sur sélection, suivi des entrées/sorties et lecture d’un chemin en étapes, sans perdre le graphe éditable. Les ports conservent une cible de 28 × 28 indépendamment du zoom ; ne pas prétendre qu’elle rétrécit visuellement et fonctionnellement avec les textes.

### N04 · Les branchements au clavier restent à prouver — P1, risque d’accessibilité

Les ports ont une sémantique de bouton mais les interactions examinées passent par des événements de pointeur ([scene_canvas_node.dart](../../../apps/avelune_studio/lib/presentation/features/scenes/scene_canvas_node.dart#L215)). Le gestionnaire de raccourcis examiné ne montre pas de commande de liaison ([scene_graph_canvas.dart](../../../apps/avelune_studio/lib/presentation/features/scenes/scene_graph_canvas.dart#L197)). **Proposition :** tester clavier et lecteur d’écran ; si nécessaire, permettre « choisir la sortie → choisir le bloc cible → confirmer » avec annonce et annulation. C’est un risque étayé par le code, pas un verdict global WCAG.

### N05 · Les options d’événement mélangent gestes courants et mécanismes avancés — P1

[42 — options](</Users/karim/Project/Avelune Studio - Atlas UI/captures/42-evenements-options.png>) expose mode `v2Only`, priorité, ordre de distribution, exécution et réarmement. [event_options_panel.dart](../../../apps/avelune_studio/lib/presentation/features/events/event_options_panel.dart#L44) avertit déjà que les modifications restent locales et peuvent préparer une désactivation : cet avertissement est à conserver. Le dialogue de mode du projet parle de « revendications » et enregistre le changement global immédiatement ([event_registry_dialog.dart](../../../apps/avelune_studio/lib/presentation/features/events/event_registry_dialog.dart#L10)).

**Proposition.** Montrer d’abord l’effet en jeu : « une fois », « à chaque visite », « après telle condition » lorsque ces règles existent. Placer ordre, priorité et registre dans des options avancées avec portée, conséquences et moment d’enregistrement. Conserver les contrôles de compatibilité et ne jamais déclencher de migration implicite.

### N06 · Une valeur `null` apparaît dans le résumé de l’événement — P1

[39 — déclencheur](</Users/karim/Project/Avelune Studio - Atlas UI/captures/39-evenements-declencheur.png>) affiche « Action de scène · null » ; [event_scene_effects.dart](../../../apps/avelune_studio/lib/presentation/features/events/event_scene_effects.dart#L31) interpole le titre du nœud. **Proposition :** un libellé de secours intelligible, par exemple « Action sans nom », et l’accès au bloc si son identité est connue. Ne pas attribuer la valeur manquante à l’original, à la copie ou à une cause non investiguée.

### N07 · Les conditions nécessitent de déduire leur logique à partir d’icônes — P2

[40 — conditions](</Users/karim/Project/Avelune Studio - Atlas UI/captures/40-evenements-conditions.png>) regroupe inversion, modification et regroupement ; les opérations sont définies dans [event_conditions.dart](../../../apps/avelune_studio/lib/presentation/features/events/event_conditions.dart#L79). **Proposition :** présenter « toutes les conditions » / « au moins une condition » et une phrase de résultat lisible, notamment avant l’inversion ou le regroupement. Les libellés accessibles existants ne prouvent pas que la représentation visuelle soit assez explicite.

### N08 · Deux onglets de cinématique peuvent montrer le même contenu — P2

Dans [47 — propriétés](</Users/karim/Project/Avelune Studio - Atlas UI/captures/47-cinematique-proprietes.png>) et [49 — séquence](</Users/karim/Project/Avelune Studio - Atlas UI/captures/49-cinematique-sequence.png>), aucune étape n’est sélectionnée ; [cinematic_inspector.dart](../../../apps/avelune_studio/lib/presentation/features/cinematics/cinematic_inspector.dart#L132) renvoie les propriétés générales dans ce cas. **Proposition :** dans Séquence, expliquer « Sélectionnez une action dans la timeline » et montrer comment l’ajouter ; ne pas faire disparaître l’accès aux propriétés générales. L’aperçu central de ces images est encore en chargement.

### N09 · Les diagnostics de cinématique répètent des messages difficiles à relier à une action — P2

[50 — aperçu](</Users/karim/Project/Avelune Studio - Atlas UI/captures/50-cinematique-apercu.png>) répète des destinations introuvables et des durées indicatives ; [cinematic_preview_status.dart](../../../apps/avelune_studio/lib/presentation/features/cinematics/cinematic_preview_status.dart#L95) affiche les messages successivement. [48 — acteurs](</Users/karim/Project/Avelune Studio - Atlas UI/captures/48-cinematique-acteurs.png>) montre aussi `null · mother` ([cinematic_inspector_actors.dart](../../../apps/avelune_studio/lib/presentation/features/cinematics/cinematic_inspector_actors.dart#L18)). **Proposition :** grouper les messages identiques, préciser si la lecture est bloquée et permettre d’aller à l’acteur ou au bloc concerné ; donner un nom de secours sans effacer l’identifiant de diagnostic. La cause des données manquantes n’est pas établie.

### N10 · Deux commandes créent la même présentation sous des noms différents — P2

[51 — présentations](</Users/karim/Project/Avelune Studio - Atlas UI/captures/51-presentation-liste.png>) montre « Créer une présentation » et « Nouvelle cinématique ». Les deux utilisent la même action `create` ([presentation_page_body.dart](../../../apps/avelune_studio/lib/presentation/features/presentations/presentation_page_body.dart#L34), [presentation_library.dart](../../../apps/avelune_studio/lib/presentation/features/presentations/presentation_library.dart#L144)). **Proposition :** même libellé et même description ; conserver éventuellement les deux points d’entrée si les positions servent des moments différents. [52 — exigence v8](</Users/karim/Project/Avelune Studio - Atlas UI/captures/52-presentation-projet-v8.png>) doit expliquer l’action réellement sûre lorsqu’elle est connue, sans migration supposée.

### N11 · L’absence de vérification et les documents récents se répètent — P3

[53 — vérification](</Users/karim/Project/Avelune Studio - Atlas UI/captures/53-verification-narrative-initiale.png>) répète « Aucun contrôle lancé » et ses boutons dans plusieurs panneaux ([verification_workspace_page.dart](../../../apps/avelune_studio/lib/presentation/features/verification/verification_workspace_page.dart#L131), [verification_list.dart](../../../apps/avelune_studio/lib/presentation/features/verification/verification_list.dart#L9)). [19 — Histoire](</Users/karim/Project/Avelune Studio - Atlas UI/captures/19-histoire-accueil.png>) peut afficher les mêmes premières scènes dans la liste principale et dans Reprendre ([narrative_overview_landing_content.dart](../../../apps/avelune_studio/lib/presentation/features/narrative/narrative_overview_landing_content.dart#L5), [narrative_overview_landing_side.dart](../../../apps/avelune_studio/lib/presentation/features/narrative/narrative_overview_landing_side.dart#L102)).

**Proposition.** Avant le premier contrôle : une explication et une action principale, puis ouvrir les panneaux de résultat une fois une analyse disponible. Quand rien n’est ouvert, réserver Reprendre à une vraie reprise ou montrer une aide utile. À préserver : « aucun contrôle lancé » ne veut pas dire « aucune erreur ».

## 5. Ressources, personnages et données Pokémon

### R01 · Bibliothèque et Identité sont deux onglets pour le même contenu — P1

**Preuve — capture + code :** [16 — bibliothèque](</Users/karim/Project/Avelune Studio - Atlas UI/captures/16-personnages-bibliotheque.png>) et [17 — identité](</Users/karim/Project/Avelune Studio - Atlas UI/captures/17-personnages-identite.png>). [character_studio_page.dart](../../../apps/avelune_studio/lib/presentation/features/characters/character_studio_page.dart#L153) déclare les deux onglets, mais après les cas Animations et Portraits, le contenu retombe sur le panneau Identité ([ligne 207](../../../apps/avelune_studio/lib/presentation/features/characters/character_studio_page.dart#L207), [ligne 230](../../../apps/avelune_studio/lib/presentation/features/characters/character_studio_page.dart#L230)).

![Onglet Bibliothèque de l’atelier personnages](</Users/karim/Project/Avelune Studio - Atlas UI/captures/16-personnages-bibliotheque.png>)

**Proposition.** Faire de la bibliothèque le panneau de sélection permanent et garder un onglet Identité ; si une vue bibliothèque distincte répond à une vraie tâche, lui donner un contenu et un objectif distincts. Éviter un onglet qui change d’état visuel sans changement utile.

### R02 · La fiche d’un personnage mélange défaut global et modification locale — P1

[17 — identité](</Users/karim/Project/Avelune Studio - Atlas UI/captures/17-personnages-identite.png>) réunit une ombre par défaut du projet et celle du personnage. Le premier réglage est enregistré immédiatement alors que le second appartient au brouillon ([character_studio_page.dart](../../../apps/avelune_studio/lib/presentation/features/characters/character_studio_page.dart#L246)). **Proposition :** placer le défaut global dans les réglages de projet ou clairement l’identifier comme tel ; sur la fiche, montrer « suit le projet » et la dérogation. Chaque action doit dire si elle est appliquée immédiatement ou attend Enregistrer. Préserver l’héritage existant.

### R03 · Les portraits oscillent entre « état » et « expression » — P2

[18 — portraits](</Users/karim/Project/Avelune Studio - Atlas UI/captures/18-personnages-portraits.png>) emploie les deux termes. Le catalogue des états de portrait est référencé dans [character_studio_portrait_panel.dart](../../../apps/avelune_studio/lib/presentation/features/characters/character_studio_portrait_panel.dart#L50). **Proposition :** choisir un mot utilisateur cohérent, par exemple « expression », distinguer création d’expression et association d’une image et préciser la portée partagée seulement après vérification du contrat et d’un essai d’écriture.

### R04 · Deux bibliothèques de ressources ont des structures différentes — P2, continuité à vérifier

[11 — bibliothèque](</Users/karim/Project/Avelune Studio - Atlas UI/captures/11-ressources-etat-vide.png>) et [12 — ressources](</Users/karim/Project/Avelune Studio - Atlas UI/captures/12-ressources-atelier.png>) présentent deux surfaces différentes. Leur branchement dépend de l’état du stockage et de session ([studio_workspace_host.dart](../../../apps/avelune_studio/lib/presentation/shell/studio_workspace_host.dart#L40), [resource_workspace_pane.dart](../../../apps/avelune_studio/lib/presentation/features/resources/resource_workspace_pane.dart#L143)). **Proposition :** identifier clairement le contexte et harmoniser recherche, résultats, fiche et action principale lorsque les capacités sont équivalentes ; ne pas supposer que les deux surfaces ont exactement le même rôle ou qu’une suppression est sûre.

### R05 · Les incidents listent des références sans toujours donner une action de réparation — P1

[56 — incidents](</Users/karim/Project/Avelune Studio - Atlas UI/captures/56-ressources-incidents.png>) affiche des identifiants, une cause générique et des icônes ; [workspace_resource_diagnostics.dart](../../../apps/avelune_studio/lib/presentation/features/map_workspace/workspace_resource_diagnostics.dart#L245) fournit diagnostic et réessai. **Proposition :** nom humain, statut « vérifié / non vérifié », usage connu, raison compréhensible, action « ouvrir la ressource » ou « choisir un fichier » seulement si elle existe, et détails techniques repliables. Ne pas considérer les 14 lignes comme 14 causes distinctes ni généraliser depuis cette copie QA.

### R06 · Les catégories d’objets affichent des identifiants en anglais — P2

[29 — objets](</Users/karim/Project/Avelune Studio - Atlas UI/captures/29-pokemon-objets.png>) montre `medicine`, `balls` et `key_items` ; [pokemon_commerce_page.dart](../../../apps/avelune_studio/lib/presentation/features/pokemon/pokemon_commerce_page.dart#L222) utilise directement l’identifiant de poche. **Proposition :** labels localisés et cohérents, identifiants conservés dans les données et les détails. Le champ Poche de la fiche est une saisie libre ([pokemon_item_overview.dart](../../../apps/avelune_studio/lib/presentation/features/pokemon/pokemon_item_overview.dart#L49)) : remplacer par un choix validé des poches réellement disponibles, avec création guidée si le produit la permet. Le détail de la fiche n’a pas été capturé.

### R07 · Lier des formes Pokémon suppose de saisir des identifiants séparés par des virgules — P1

[24 — formes](</Users/karim/Project/Avelune Studio - Atlas UI/captures/24-pokemon-formes.png>) affiche explicitement cette saisie, découpée par [pokemon_species_forms.dart](../../../apps/avelune_studio/lib/presentation/features/pokemon/pokemon_species_forms.dart#L79). **Proposition :** recherche multi-sélection de formes existantes avec nom, aperçu et état d’une référence manquante ; identifiants visibles en option avancée. Conserver les références existantes même si elles ne se résolvent pas.

### R08 · Une condition d’évolution peut être confondue avec une règle exécutable — P1

[26 — évolutions](</Users/karim/Project/Avelune Studio - Atlas UI/captures/26-pokemon-evolutions.png>) affiche une méthode technique et des champs de condition textuelle ; l’interface précise déjà qu’une condition enregistrée ne garantit pas l’exécution ([pokemon_evolution_entry.dart](../../../apps/avelune_studio/lib/presentation/features/pokemon/pokemon_evolution_entry.dart#L35)). **Proposition :** séparer explicitement description affichée et règle effectivement comprise par le jeu ; proposer des choix guidés pour les seules méthodes réellement prises en charge, signaler les autres sans perte de données, et offrir un test lorsque disponible. Vérifier chaque mécanique avant toute promesse.

### R09 · « Importer » ne veut pas forcément dire « remplacer » un média — P1

[27 — médias](</Users/karim/Project/Avelune Studio - Atlas UI/captures/27-pokemon-medias.png>) montre une image associée et une action d’import ; [pokemon_species_media.dart](../../../apps/avelune_studio/lib/presentation/features/pokemon/pokemon_species_media.dart#L239) et sa note vers [ligne 286](../../../apps/avelune_studio/lib/presentation/features/pokemon/pokemon_species_media.dart#L286) distinguent les rôles et la conservation d’une référence existante. **Proposition :** nommer « Ajouter » pour un rôle vide ; n’afficher « Remplacer » que si un parcours sûr existe, sinon expliquer l’indisponibilité et la suite possible. Localiser les rôles techniques comme `icon` et `party`.

### R10 · Une référence associée ne prouve pas que le média est disponible — P2

La [capture 27](</Users/karim/Project/Avelune Studio - Atlas UI/captures/27-pokemon-medias.png>) et [pokemon_species_media.dart](../../../apps/avelune_studio/lib/presentation/features/pokemon/pokemon_species_media.dart#L91) signalent que la référence ne garantit pas l’existence du fichier. **Proposition :** distinguer « non associé », « non vérifié », « disponible », « introuvable » et « aperçu impossible » selon le résultat réel du contrôle, sans transformer une simple référence en promesse de disponibilité.

### R11 · Les aperçus pixel art ne semblent pas tous rendus avec la même netteté — P3

Bulbizarre paraît flou dans [23 — espèce](</Users/karim/Project/Avelune Studio - Atlas UI/captures/23-pokemon-espece.png>) par rapport aux sprites de [15 — animations](</Users/karim/Project/Avelune Studio - Atlas UI/captures/15-personnages-animations.png>). [pokemon_species_thumbnail.dart](../../../apps/avelune_studio/lib/presentation/features/pokemon/pokemon_species_thumbnail.dart#L49) et [pokemon_media_preview.dart](../../../apps/avelune_studio/lib/presentation/features/pokemon/pokemon_media_preview.dart#L63) ne précisent pas le filtrage, contrairement au [sélecteur de sprites](../../../apps/avelune_studio/lib/presentation/features/pokemon/pokemon_capture_sprite_picker.dart#L144). **Proposition :** comparer la même source à la même échelle, puis employer un filtrage adapté au pixel art et conserver un rendu adapté aux illustrations. La cause de la différence observée reste à confirmer.

### R12 · Les listes vides ou sans sélection n’aident pas toujours à démarrer — P3

Les captures [22 — Pokédex](</Users/karim/Project/Avelune Studio - Atlas UI/captures/22-pokemon-pokedex.png>), [28 — attaques](</Users/karim/Project/Avelune Studio - Atlas UI/captures/28-pokemon-attaques.png>) et [30 — boutiques](</Users/karim/Project/Avelune Studio - Atlas UI/captures/30-pokemon-boutiques.png>) montrent une grande zone sans fiche sélectionnée. **Proposition :** tester un état d’accueil ciblé, expliquant la prochaine action et l’origine du catalogue ; restaurer éventuellement la dernière sélection si elle reste valide. Un espace vide n’est pas en lui-même un défaut prouvé.

### R13 · Combat et attaques demandent de retrouver ailleurs la suite du geste — P2

[31 — combats](</Users/karim/Project/Avelune Studio - Atlas UI/captures/31-pokemon-combats.png>) indique que l’affectation se fait dans une zone ou des cases sur la carte ; [pokemon_combat_context_panel.dart](../../../apps/avelune_studio/lib/presentation/features/pokemon/pokemon_combat_context_panel.dart#L30) décrit différents contextes. [28 — attaques](</Users/karim/Project/Avelune Studio - Atlas UI/captures/28-pokemon-attaques.png>) affiche « Synchronisation » qui ouvre un panneau ([pokemon_moves_library.dart](../../../apps/avelune_studio/lib/presentation/features/pokemon/pokemon_moves_library.dart#L56)) sans exécuter immédiatement une synchronisation.

**Proposition.** Lorsque le contexte et l’identité de l’objet sont connus, proposer un aller-retour vers « Assigner sur une carte » ou « Ouvrir la scène liée » ; préciser la source et l’effet d’une synchronisation avant toute action. Ne pas déduire du mot « synchronisation » qu’un transfert a déjà eu lieu, ni inventer des raccourcis que l’architecture ne permet pas encore.

## 6. Réglages, test et export : rendre les conséquences visibles

### T01 · Tester peut enregistrer certains brouillons et en bloquer d’autres — P1, code seul

Dans [workspace_actions.dart](../../../apps/avelune_studio/lib/presentation/features/map_workspace/workspace_actions.dart#L165), un test refuse notamment des modifications non enregistrées de carte régionale, présentations, cinématiques, dialogues et événements ; plus loin, dans le chemin applicable, des scènes, l’ambiance et la carte/narration peuvent être enregistrées avant le test ([ligne 227](../../../apps/avelune_studio/lib/presentation/features/map_workspace/workspace_actions.dart#L227)). Un mode de cinématique publiée applique d’autres contrôles. **Impact possible :** l’auteur ne sait pas nécessairement si « Tester » utilise un brouillon, l’enregistre ou demande de l’enregistrer ailleurs. Ce constat provient du code ; les avertissements éventuels et la succession réelle des écrans doivent être vérifiés en session.

**Proposition.** Avant le test, présenter clairement ce qui sera utilisé, ce qui doit être enregistré et ce qui sera effectivement sauvegardé si nécessaire, avec des actions explicites vers les documents concernés. Préserver intégrité, écritures ciblées et sémantique de brouillon ; ne pas simuler une sauvegarde ou contourner les vérifications pour fluidifier l’interface.

### T02 · L’erreur de test ne donne pas une prochaine action compréhensible — P1

[36 — erreur de test](</Users/karim/Project/Avelune Studio - Atlas UI/captures/36-test-erreur-capacite.png>) affiche `Bad state: The project requires gameplay.periodic-reward-condition@1`. [studio_playtest_view.dart](../../../apps/avelune_studio/lib/platform/playtest/studio_playtest_view.dart#L487) affiche directement l’erreur interpolée.

![Échec du test de jeu dans la copie HGSS](</Users/karim/Project/Avelune Studio - Atlas UI/captures/36-test-erreur-capacite.png>)

**Proposition.** Traduire les erreurs connues en termes de jeu, distinguer cause établie et cause inconnue, proposer seulement des actions réellement disponibles (« ouvrir le diagnostic », « vérifier la version » ou « réessayer » selon le cas) et garder le détail technique copiable. Dans cet exemple, ni la cause ni une réparation spécifique ne sont établies ; ne pas prétendre qu’un réglage résout le problème.

### T03 · Le même verbe « Annuler » décrit deux portées — P1

[32 — réglages](</Users/karim/Project/Avelune Studio - Atlas UI/captures/32-reglages-principal.png>) place « Annuler les modifications » à côté de « Annuler » ; le premier abandonne le brouillon, le second annule une étape ([project_settings_page.dart](../../../apps/avelune_studio/lib/presentation/features/project_settings/project_settings_page.dart#L230)). Le son présente un motif voisin ([project_audio_panel.dart](../../../apps/avelune_studio/lib/presentation/features/project_settings/project_audio_panel.dart#L174)). **Proposition :** « Abandonner les modifications » et « Annuler la dernière action », avec portée, état et raccourci clairement distincts. Toute confirmation doit correspondre au risque réel, sans ajouter de modal inutile à chaque geste.

### T04 · Champ de vision et distance sont visuellement séparés mais liés — P2, code seul

La [capture 32](</Users/karim/Project/Avelune Studio - Atlas UI/captures/32-reglages-principal.png>) présente deux curseurs ; [spatial_visual_controls.dart](../../../apps/avelune_studio/lib/presentation/features/project_settings/spatial_visual_controls.dart#L81) recalcule la distance lors d’un changement de champ de vision. **Proposition :** expliquer « conserver le cadrage » et rendre le lien visible ; tester si une option explicite est pertinente et traiter une modification couplée comme un geste cohérent dans l’historique. Aucun test interactif n’a mesuré la surprise effective.

### T05 · Activer une CS, disposer de sa mécanique et la débloquer sont trois états — P1

[33 — capacités de terrain](</Users/karim/Project/Avelune Studio - Atlas UI/captures/33-reglages-cs.png>) montre des lignes cochées dont certaines sont indiquées non certifiées ou à implémenter ; [project_cs_panel.dart](../../../apps/avelune_studio/lib/presentation/features/project_settings/project_cs_panel.dart#L68) construit ces sous-titres.

**Proposition.** Présenter séparément l’autorisation au niveau du projet, la disponibilité réellement vérifiée pour le profil et les conditions de déblocage du joueur. Si une capacité n’est pas disponible, dire ce qui est connu et ce qui n’est pas vérifié. L’audit ne certifie aucune mécanique.

### T06 · L’affectation d’un son a deux chemins dont l’effet n’est pas évident — P2

[34 — son](</Users/karim/Project/Avelune Studio - Atlas UI/captures/34-reglages-son.png>) présente sélection et bibliothèque ; [project_audio_panel.dart](../../../apps/avelune_studio/lib/presentation/features/project_settings/project_audio_panel.dart#L121) et [ligne 242](../../../apps/avelune_studio/lib/presentation/features/project_settings/project_audio_panel.dart#L242) utilisent l’affectation. **Proposition :** distinguer explicitement « Écouter » et « Utiliser pour … », montrer le son associé et la portée d’enregistrement ; garder plusieurs raccourcis si leur résultat est cohérent et visible.

### T07 · L’export a besoin de conséquences et de critères compréhensibles — P1

[67 — export](</Users/karim/Project/Avelune Studio - Atlas UI/captures/67-export-options.png>) et [68 — informations](</Users/karim/Project/Avelune Studio - Atlas UI/captures/68-export-options-avancees.png>) montrent mode, destination, résumé et options avancées. L’identifiant stable est exposé dans [studio_game_export_summary.dart](../../../apps/avelune_studio/lib/presentation/features/game_export/studio_game_export_summary.dart#L65) ; les langues utilisent des champs dans [studio_game_export_content.dart](../../../apps/avelune_studio/lib/presentation/features/game_export/studio_game_export_content.dart#L43).

**Proposition.** Expliquer à quoi servira le paquet, où il sera enregistré et quelles validations ont réellement abouti ; utiliser des choix de langues compréhensibles. Expliquer l’identité stable et ses conséquences avant de permettre une modification. Préserver le message indiquant que le paquet utilise la version enregistrée et la confirmation de remplacement. **Invariant :** aucune refonte ne doit compromettre la compatibilité des jeux et sauvegardes protégés.

## 7. Doublons et ambiguïtés : quoi réunir, quoi garder

| Situation | Ce que les preuves établissent | Décision proposée |
|---|---|---|
| Personnages : Bibliothèque / Identité | Même panneau dans les états examinés, sélection visuelle différente. | Un onglet Identité ; bibliothèque permanente ou véritable vue distincte si besoin réel. |
| Présentations : « Créer » / « Nouvelle cinématique » | Même callback, deux noms. | Même nom ; conserver deux accès uniquement s’ils répondent à deux contextes. |
| Carte : Passages / Connexions dans la barre et « … » | Mêmes préparations appelées à deux endroits. | Grouper par tâche et conserver seulement les raccourcis utiles, cohérents et découvrables. |
| Accueil : Tester / Tester le jeu | Deux chemins de test avec portées différentes. | **Ne pas supprimer comme doublon** ; nommer et expliquer la différence. |
| Carte : arborescence / sélecteur supérieur | Deux accès au choix de carte, mais tâches d’organisation et de changement rapide potentiellement distinctes. | Garder les deux si les usages le justifient ; harmoniser noms, recherche et chemin. |
| Ambiance dans panneau et inspecteur | Informations communes, périmètres et actions de sauvegarde partiellement différents. | Harmoniser la destination et rendre les portées explicites avant toute fusion. |
| Son : sélecteur / ligne de bibliothèque | Deux chemins d’affectation ; une ligne propose aussi l’écoute. | Clarifier « écouter » et « utiliser » ; conserver les accès utiles après test. |
| Histoire : cartes de scènes / Reprendre | Même contenu possible quand aucun brouillon n’est ouvert. | Réserver la reprise à une vraie reprise ou afficher un état initial utile. |

## 8. Accessibilité et adaptation : risques, pas certification

1. **Clavier.** Vérifier de bout en bout la navigation entre outils, palettes et inspecteurs, l’ouverture des menus, la liaison des blocs et le placement régional. N04 et la position régionale ([regional_map_page.dart](../../../apps/avelune_studio/lib/presentation/features/regional_map/regional_map_page.dart#L247)) indiquent des gestes à vérifier, mais pas que toute alternative est absente.
2. **Noms accessibles.** Vérifier que chaque icône seule a un nom, que les contrôles désactivés expliquent leur condition d’activation et que les noms tronqués restent disponibles au focus. Des `Tooltip` et de la sémantique existent déjà : ne pas affirmer qu’ils sont absents partout.
3. **États sans couleur.** Vérifier que sélection, erreur, disponibilité et progression restent compréhensibles avec texte ou symbole, pas uniquement par couleur. Mesurer les contrastes des états normaux, secondaires, désactivés et focus avant de conclure.
4. **Taille et adaptation.** Tester 1 920 × 1 080 mais aussi une fenêtre plus étroite, des panneaux redimensionnés et un texte agrandi. M06 documente une branche du dock sous 420 px ; il ne décrit pas toutes les variantes d’écran.
5. **Lecteur d’écran et ordre de lecture.** Vérifier les noms des blocs, ports, liens, statuts d’enregistrement, messages d’erreur et annonces de changement. Une propriété `Semantics` isolée ne suffit pas à prouver un parcours utilisable.
6. **Mouvement et chronologie.** Tester les aperçus, leurs contrôles et messages, l’arrêt et la reprise ; ne pas confondre une capture statique avec la preuve qu’une animation est accessible.

## 9. Références Mobbin consultées

Les exemples ci-dessous sont des captures **web** de produits différents. Elles servent à observer une structure précise, pas à recopier une identité ni à supposer que leurs contraintes sont celles d’un éditeur de RPG. Les comportements non visibles dans les aperçus ne sont pas affirmés.

| Référence observée | Ce que montre la capture | Application proposée à Avelune | Limite |
|---|---|---|---|
| [Framer — éditeur et inspecteur](https://mobbin.com/screens/437d5030-772d-46b7-8ba3-bfc75064b0c5) | Navigation à gauche, objet sélectionné au centre, propriétés regroupées à droite. | Renforcer le lien visible entre sélection de carte, action et inspecteur ; conserver les outils de jeu spécifiques. | Outil de design web ; la capture ne prouve pas son accessibilité ni l’efficacité de ses gestes. |
| [Rive — éditeur sur toile](https://mobbin.com/screens/177be26e-239e-4d9e-a7f7-0d70af0b6394) | Hiérarchie à gauche, grande toile, propriétés de l’objet à droite. | Comparer la hiérarchie des panneaux et la place consacrée au contenu, sans imposer une interface d’expert aux débutants. | État presque vide, pas un parcours de jeu. |
| [Runway — recherche de ressources](https://mobbin.com/flows/96917e5f-3ed5-4788-9b79-879745743863) et [filtrage](https://mobbin.com/flows/6767562d-9976-4d10-854e-690618bcaa16) | Recherche et filtre dans une bibliothèque visible à côté de la surface et de la timeline. | Garder recherche, choix courant et retour à la carte dans le même contexte. | Éditeur vidéo ; ses médias et actions ne correspondent pas directement aux ressources de jeu. |
| [Magnific — nœuds et menu contextuel](https://mobbin.com/screens/506b8d38-275b-4c71-a5a6-e540872ae324) | Un objet sélectionné possède des actions contextuelles près du nœud et des connexions visibles. | Explorer une navigation par bloc sélectionné, en conservant la lecture des branches de scène. | Le nombre de nœuds et la nature des médias diffèrent fortement de HGSS. |
| [VEED — timeline](https://mobbin.com/screens/4ff2167d-aacb-4352-96d2-5948119cb520) | Aperçu, pistes nommées, blocs et commandes de lecture répartis par zone. | Clarifier la relation entre acteur, action, temps et aperçu dans les cinématiques. | Édition vidéo ; pas de preuve sur les déplacements d’acteurs ou l’exécution de scènes. |
| [Deel — résumé de champs requis](https://mobbin.com/screens/14397653-8147-46e8-ac32-39a1f18a92a4) | Une notice liste des champs et branches incomplets avant une action. | Dans Avelune, proposer des diagnostics compréhensibles reliés aux documents ou champs concernés. | Exemple de formulaire ; ne prouve ni la pertinence d’une modale ni une action de correction automatique. |
| [Hotjar — étape de création](https://mobbin.com/screens/7f81c9b2-c4f5-4021-bf70-d1f7e16e0190) | Étapes explicites, champs nommés et aide près du champ. | Expliquer les conséquences des choix de projet au moment de les faire, avec récapitulatif. | Recherche utilisateur, pas création de jeu. |

La recherche Mobbin « project validation with errors » a principalement retourné des écrans de code de vérification : ils n’ont pas été utilisés comme exemples de diagnostic de projet. Les références ci-dessus ne valident ni les recommandations ni leur efficacité ; elles fournissent des points de comparaison à tester.

## 10. Ordre proposé pour la suite, sans réaliser de maquettes maintenant

| Ordre | Parcours à concevoir | Résultat attendu | Vérification à prévoir avant livraison |
|---|---|---|---|
| 1 | Carte : sélectionner, placer, déplacer, retrouver un objet masqué, annuler | Le prochain geste et l’objet concerné sont toujours compréhensibles ; modes et palette ne se contredisent pas. | Observer plusieurs débutants et experts ; vérifier sélection, annulation, enregistrement, récupération et latence de la première modification et des suivantes. |
| 2 | Carte : départ, personnage, dialogue, test et retour | Une première interaction jouable se construit sans chercher dans des menus non liés. | Rejouer sur petit projet et HGSS, vérifier les données enregistrées et le retour au même contexte. |
| 3 | Sauvegarde, test et erreurs | Chaque document et chaque portée sont nommés ; le test indique ce qu’il utilise ou enregistre. | Tester brouillons de carte, scène, dialogue, événement, ambiance et région, échecs de sauvegarde et reprise. |
| 4 | Ressources et personnages | Trouver, inspecter, choisir ou remplacer une ressource sans saisir de référence brute dans le parcours normal. | Tester ressource absente, non vérifiée, importée et partagée ; préserver identités, liens et données. |
| 5 | Scènes et événements | Partir d’une intention, choisir une scène, lire une branche et comprendre les conséquences. | Tester projet de plusieurs centaines de scènes, clavier, sorties non résolues et brouillons. |
| 6 | Pokémon, CS et médias | Différencier description, règle exécutable, disponibilité et déblocage. | Vérifier les mécanismes réellement pris en charge et les références avant toute promesse. |
| 7 | Export et diagnostic | Comprendre ce qui sera distribué, où et après quels contrôles. | Contrôler échecs, remplacement, identité stable, protections des exports et sauvegardes. |

Les priorités visuelles précises et les métriques de succès doivent être définies à partir d’une première observation des parcours, pas à partir de chiffres supposés. Pour les changements d’authoring, conserver les systèmes natifs terrains, chemins, bordures et environnements, les opérations locales et incrémentales, la persistance canonique, l’annulation et la parité API/MCP quand elle s’applique.

## 11. Ce qui reste à observer

- États non photographiés : menus imbriqués et inspecteurs de nombreuses sélections, détails d’objets, création/édition de boutiques, import, éditeur de dialogue, parcours complets de région, restauration d’historique et certains écrans de confirmation.
- Le test en jeu de la copie a affiché une erreur de capacité ; la présentation a affiché une exigence de projet v8 ; certains médias ont été signalés en incident. Ces états sont utiles pour l’UI mais leurs causes ne sont pas diagnostiquées ici.
- Aucun utilisateur débutant ou expert n’a été observé pendant cette revue ; il n’y a ni comptage de clics, ni temps mesuré, ni taux de réussite. Les propositions sont des hypothèses de conception à confronter aux tâches.
- Aucune vérification complète des contrastes, du clavier, du lecteur d’écran ou des tailles de cibles ; aucune affirmation de conformité WCAG.
- Les captures et le code ont pu évoluer séparément. Reconfirmer chaque comportement sur le build choisi pour les futures maquettes et relever explicitement les variantes différentes.

## 12. Traçabilité de la revue

**Passes :** architecture et navigation globale ; carte et région ; narration et cinématiques ; ressources, personnages, Pokémon et réglages ; comparaison Mobbin ; critique finale indépendante. Les conclusions des passes Carte, Narration et Données ont été intégrées et vérifiées sur leurs points principaux ; les limites de chaque passe sont reprises ci-dessus. Aucun agent n’a reçu de tâche d’implémentation du produit : la « passe implémentation » des règles du dépôt est sans objet pour cet audit documentaire. Tests et build du produit sont sans objet pour une revue qui ne modifie aucun code ; la validation porte sur les références, le rapport et l’hygiène documentaire.

**Git au départ :** branche `main`, base `51f1ece7854d67dbdb1a4fa7937a09fa11331693`, 43 entrées modifiées ou non suivies observées dans l’arbre, provenant de travaux en cours sur `map_authoring`, `map_runtime` et `tools/avelune_attack_comparator`. Aucune opération Git d’écriture n’a été réalisée.

**Auto-critique :** l’audit est large mais ne remplace pas la manipulation de chaque branche UI. Les problèmes les plus solides sont les doublons de callbacks ou de contenu, l’exposition de valeurs techniques et les différences de portée étayées par le code ; les suppositions sur la confusion effective, la découvrabilité, l’accessibilité et la performance doivent être testées. Des accès multiples peuvent servir des tâches différentes ; il ne faut pas les supprimer uniquement parce qu’ils se ressemblent. Les comparateurs Mobbin ne sont pas des applications de création de RPG et leurs aperçus ne démontrent ni ergonomie mesurée ni accessibilité.

**Verdicts des passes :** Carte/région : modes, accès et sélection à clarifier, avec reproduction manquante pour la région. Narration : objets distincts à relier par intention et graphe à rendre lisible ; clavier à tester. Ressources/Pokémon/réglages : deux onglets identiques, identifiants et portées à clarifier ; plusieurs fiches demandent une capture supplémentaire. Critique indépendante : comportement du test et références Mobbin recoupés ; un chemin de code erroné a été corrigé, cinq captures représentatives sont maintenant intégrées au rapport, les autres restent liées. Aucune passe ne prétend avoir observé tous les utilisateurs ni tous les états.

**Fichiers créés ou modifiés pour ce livrable :** ce rapport, regroupant preuves, recommandations et limites ; [.gitignore](../../../.gitignore), trois règles ciblées qui rendent uniquement ce rapport visible à Git sans ouvrir le reste des rapports ignorés. Aucun fichier de l’application, aucune capture et aucun projet de jeu n’ont été modifiés pendant cette revue. Les modifications préexistantes et concurrentes n’ont pas été nettoyées.

**Vérifications effectuées :** revue manuelle des captures et du code, douze recherches Mobbin ciblées de captures et de parcours, vérification automatisée de 154 liens locaux et des numéros de ligne cités : aucun lien local manquant au contrôle ; `git diff --check -- .gitignore` : sortie vide, code 0. `POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh` : code 1 ; deux autres Markdown ignorés préexistants, `documentation/reports/avelune_player/plans/2026-10-31-avelune-ios-install-library-launch-perf.md` et `documentation/reports/heartgold/audit-cartes-johto-2026-10-31.md`, restent signalés et font dépasser le budget total. Ils n’ont pas été modifiés. Aucun test Flutter ou build n’a été lancé : aucun comportement d’application n’a été implémenté ou corrigé dans cette tâche.

**Git à la vérification finale :** branche et SHA inchangés ; 45 entrées visibles, dont les 43 entrées préexistantes observées et les deux fichiers de ce livrable. L’état de travail concurrent peut continuer à évoluer. Le suivi [AS-UX-001](https://app.notion.com/p/3e0197a7bfa581eea323f660fa85e295) reste en cours ; les recommandations, les maquettes futures et leur validation n’ont pas été réalisées par cet audit.
