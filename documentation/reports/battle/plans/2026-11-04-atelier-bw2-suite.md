# Suite des animations de combat BW2 — Implementation Plan

> **Exécution :** reprendre ce plan lot par lot avec `skills/executing-plans/SKILL.md`. Ce document prépare la suite ; sa rédaction ne modifie pas le statut de l’objectif Codex, actuellement actif.

**Goal:** améliorer un maximum d’animations BW1/BW2 dans l’atelier, faciliter leur vérification par Yoahn, puis livrer un premier ensemble jouable dans Avelune hors ligne.

**Architecture:** conserver les règles de combat et réutiliser le convertisseur de scripts, le lecteur, la caméra et les ressources existants. Corriger les comportements communs à partir de références et de la source, puis brancher les programmes retenus au chemin API → import → export → Player sans imposer de réseau en jeu.

**Tech Stack:** Dart/Flutter, Flame, programmes JSON et ressources BW2 déjà convertis, API Avelune en TypeScript, `.avelunegame`, atelier macOS et Player iOS.

---

## État de départ vérifié le 4 novembre 2026

| Point | Constat | Ce que cela ne prouve pas |
|---|---|---|
| Dépôt PokeMap | La première préparation était à `21900a78f14ca95789759d8c66491506b812d52f`. Depuis, la correction locale de l’atelier a été committée en `c8eb9e87f`, puis les vecteurs de contrat en `2a5a92cd2` ; le plan et son exception `.gitignore` restent non committés. | Que ces commits ont été poussés ou que le chantier entier est terminé. |
| Catalogue batch | `tools/avelune_attack_comparator/assets/bw2/batch/index.json` contient **581 entrées**, **544 identifiants distincts**, 544 URL de référence distinctes et 574 fichiers de programme distincts. Tous les chemins de programme référencés existent. L’atelier contient aussi 18 aperçus déclarés dans `PreviewMove.values`, dont certains recoupent ces entrées. | 581 attaques différentes, 581 animations fidèles, ou un total obtenu en additionnant simplement les deux listes. |
| Moteur | Le lecteur de programmes source `BattleGen5SourceProgramPlayback` est raccordé à l’overlay expérimental de l’atelier. Il existe déjà des tests pour Surf, les attentes, la caméra, les acteurs et les palettes. | Une animation testée en logiciel est identique à la référence ou fonctionne déjà dans le Player distribué. |
| Contrôles déjà rapportés | Le ticket Notion rapporte une lecture technique de 581 entrées et 338 scénarios d’atelier réussis en rendu logiciel avant les changements locaux actuels. | Que 581 animations sont visuellement fidèles, vérifiées sur GPU ou disponibles sur iPhone ; ces tests n’ont pas été relancés pour cette relecture. |
| Priorités candidates | Dans l’index batch, 172 entrées portent `scene-palette-fade:layer-approximation` (163 identifiants) et 130 portent `particle-spin:trigonometry-experimental` (120 identifiants). Les groupes se recoupent ; `fadeStagePalette` apparaît dans les programmes de 215 entrées. | Un défaut visible est établi pour chacune de ces entrées, ou une correction améliorera automatiquement toutes ces attaques. Les aperçus déclarés en code ne sont pas inclus dans ces comptes. |
| Références | L’atelier sait chercher une attaque, rejouer, choisir portrait/paysage et charger les Pokémon associés à la référence. L’index embarqué dans l’application du Bureau a la même empreinte que celui du dépôt. | Que l’ensemble du binaire du Bureau correspond exactement au commit actuel, ni que son affichage natif a été observé après le déverrouillage. |
| Synchronisation référence | `c8eb9e87f` attend le chargement de la référence avant de lancer le tour ; une référence absente ne bloque pas l’aperçu et les anciens chargements sont ignorés. Un exemplaire macOS signé a été testé et placé sur le Bureau. | Une synchronisation image par image : un décalage reste visible sur Surf. |
| Chemin jeu/API | Le lecteur de recettes de production indique encore `supportsCompleteMoveVisuals == false`. Le validateur **local** de l’API accepte désormais les définitions de particules 1 à 4 et les commandes de mouvement Gen 5 du contrat existant ; l’atelier expérimental lit aussi des versions 5 à 19. | L’état précis du service API déployé, ni l’admission des programmes complets de l’atelier dans le Player. |
| Autres travaux | Le dépôt séparé `/Users/karim/Project/avelune-pokemon-api` contient des fichiers de travail non suivis liés aux sauvegardes. | Une autorisation de les modifier ou de les supprimer pour ce chantier. |

L’audit historique [du 2 novembre](2026-11-02-bw2-combat-integration-plan.md) conserve les détails de source et les dix lots proposés à cette date. Ses constats et sa mention de lots non exécutés sont historiques : les comparer au code et aux preuves actuelles avant de les reprendre.

Le suivi reste rattaché au domaine Notion **Combat solo**, ticket existant « Intégrer les animations d’attaques BW2 dans Avelune » (`40b197a7-bfa5-8170-87d6-e4ebf532bb8b`). Les lots `FG-052` et `FG-053` de la roadmap concernent respectivement le remplacement après K.O. et la cible globale de parité combat ; ce plan ne les ferme pas et ne modifie pas les règles de combat.

## Résultat attendu et limites

- Un atelier stable pour comparer les animations à BW1/BW2, avec portrait et paysage, acteur/cible comparables et affichage des replis.
- Le plus grand ensemble raisonnablement possible de programmes source jouables, avec une liste explicite des variantes, ressources et effets manquants. Une approximation identifiée reste acceptable pour le POC.
- Des contrôles automatiques en lot pour les erreurs techniques ; des comparaisons visuelles sur des exemples représentatifs, puis une revue humaine facilitée attaque par attaque. Un test technique vert ne vaut pas validation visuelle.
- Une première chaîne complète API → import Studio → export `.avelunegame` → Player hors ligne → iPhone, avec les résultats et replis réellement observés. Le Player ne télécharge pas les médias en combat.
- Préserver la priorité déjà demandée pour les Pokémon : squelette si disponible et pris en charge, sinon GIF, sinon image fixe ; absence totale signalée. Les vrais modèles 3D et les combats triples restent hors de ce lot.
- Ne pas changer les règles de dégâts, sauvegardes ou progression pour réussir une comparaison visuelle. Préserver les jeux et sauvegardes protégés par la politique de compatibilité du dépôt.

## Organisation : sept lots, trois jalons

| Jalon | Lots | Résultat concret |
|---|---|---|
| **1 — Référence et jeu réel minimal** | 1, puis début de 7 | Observer les références et faire passer un premier petit ensemble par la chaîne API → export → Player hors ligne. Identifier immédiatement les incompatibilités de contrat. |
| **2 — Moteur, couverture et revue** | 2 à 6, par itérations | Corriger les causes communes, traiter le catalogue en lot et rendre les exceptions faciles à revoir dans l’atelier. |
| **3 — Livraison sur appareil** | fin de 7 | Étendre le lot utilisable, tester le jeu sur iPhone et donner un bilan des animations réellement livrées et des manques. |

Le lot 7 est volontairement commencé après le constat initial du lot 1 : le pilote de bout en bout ne doit pas attendre la fin de toutes les améliorations visuelles. Les lots 2 à 5 avancent ensuite par petites itérations ; leur ordre dépend des écarts et des incompatibilités constatés. Le traitement en masse commence dès qu’une correction commune a une preuve suffisante : il n’attend pas une perfection graphique générale. L’audio approximatif ou une variante manquante ne bloque pas seul l’examen des autres attaques.

## Lot 1 — Établir une référence visuelle et la stabilité native

**But :** savoir ce qui s’affiche réellement avant de modifier le moteur. Le Mac a été indiqué déverrouillé par Yoahn ; son état au moment de l’essai reste à vérifier.

- [ ] Ouvrir l’atelier du Bureau, noter son chemin et sa version effective, puis confirmer que la référence BW se charge et que l’animation Avelune démarre et termine. Si le binaire ne correspond pas au code à évaluer, reconstruire et identifier explicitement le nouveau binaire.
- [ ] Comparer **Charge, Pistolet à O, Surf, Tonnerre, Séisme, Vampigraine et Vol** : départ/fin, effet au contact, taille, caméra, acteur/cible et décor. Ces exemples couvrent plusieurs familles ; ne pas les présenter comme toute la bibliothèque.
- [ ] Pour chaque exemple, regarder portrait **393 × 852** et paysage **852 × 393**, sans étirer la référence DS. Choisir les mêmes Pokémon et la même variante lorsque l’atelier les possède ; signaler les substitutions. Comparer la composition et le mouvement à échelle apparente comparable, pas seulement un arrêt sur image.
- [ ] Vérifier au moins un enchaînement et une interruption : rejouer, changer d’attaque pendant une préparation puis après un effet. À la fin, position, caméra, visibilité et teintes doivent revenir à l’état attendu.
- [ ] Si un crash ou un blocage se reproduit, relever l’attaque, la séquence, le binaire et le rapport natif, puis localiser la première erreur avant de corriger. Les anciens `EXC_BAD_ACCESS` justifient cette vigilance mais ne prouvent pas une cause actuelle.
- [ ] Examiner les changements locaux de synchronisation de référence et leurs tests avant de les poursuivre : vérifier chargement réussi, échec et changement rapide d’attaque, puis observer l’application native. Ne pas les présenter comme livrés sur la seule base du diff.

**Fichiers à inspecter selon le symptôme :** `tools/avelune_attack_comparator/lib/main.dart`, `lib/preview_game.dart`, `lib/workshop_reference_pokemon.dart`, `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart` et les tests ciblés ci-dessous.

**Avancement :** Charge en portrait et Surf en portrait/paysage ont été lancés dans un build macOS natif ; la vague Surf est visible et le couple de Pokémon est celui de la référence. La synchronisation reste approximative et un décalage visible subsiste sur Surf. Les cinq autres exemples et une comparaison de fidélité complète restent à faire.

**Fin du lot :** une courte liste priorisée de différences réellement observées, leurs attaques représentatives et les limites de référence. Une capture ou un enregistrement ne prouve que le cas représenté ; pas de déclaration de parité globale. Enchaîner ensuite sur le pilote initial du lot 7 avant de généraliser.

## Lot 2 — Corriger d’abord les effets visuels communs

**But :** résoudre les causes qui dégradent plusieurs attaques, sans régler 581 fichiers à la main.

- [ ] Classer les écarts observés par famille : teinte/fondu de scène ou de décor, taille/durée, rotation/projection, ordre des couches, émetteurs et particules. Utiliser les comptes d’étiquettes comme indice de portée, puis vérifier que les attaques emploient réellement le comportement en cause.
- [ ] Commencer par une famille dont un défaut est visible sur au moins un exemple du lot 1 ; comparer l’instruction et les valeurs converties aux handlers BW2 de la révision `41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c`. Les transitions de palette et la rotation de particules sont les premières candidates, pas des corrections présumées.
- [ ] Corriger dans le lecteur ou le convertisseur propriétaire de la cause. Ne changer les JSON générés que si la conversion est responsable ; régénérer le groupe concerné avec le mécanisme existant et relever les différences réellement produites.
- [ ] Ajouter un test ciblé sur le comportement fautif, un cas sans cet effet et un cas d’annulation ; comparer au moins deux attaques utilisant la même famille, dans les deux formats quand la géométrie est en jeu.

**Fichiers candidats :** `packages/map_runtime/lib/src/presentation/flame/battle_gen5_source_background.dart`, `battle_gen5_source_program_playback.dart`, `battle_overlay_component.dart`, `battle_spl_point_preview_painter.dart`, `battle_spl_particle_motion.dart`, `battle_spl_color_texture_animation.dart` ; convertisseurs sous `packages/map_authoring/lib/src/domains/gameplay/pokemon_external/`.

**Fin du lot :** pour chaque correction retenue, expliquer la cause, les exemples avant/après, le nombre d’entrées concernées mesuré après régénération et les cas toujours approximatifs. Ne pas retirer une étiquette uniquement parce qu’un test passe.

## Lot 3 — Acteurs, squelette, caméra et transitions

**But :** rendre cohérents les effets qui déplacent ou masquent un Pokémon et ceux qui déplacent la caméra.

- [ ] Vérifier la chaîne script → acteur et ses points d’ancrage sur **Vol**, **Vive-Attaque**, **Surf** et un changement de Pokémon, avec les deux formats. Distinguer une erreur de source, de projection, de point d’attache ou de remplacement.
- [ ] Vérifier le résultat avec un squelette disponible, puis avec un GIF et une image fixe de repli. Une animation d’attaque doit respecter l’état, l’orientation et le remplacement de l’acteur sans écraser les règles du combat.
- [ ] Conserver une seule caméra et son horloge ; tester le retour à la position initiale après fin, interruption, K.O. et enchaînement. Ne pas déformer les ressources pour remplir un écran plus large.
- [ ] Caractériser le repli temporaire en rendu logiciel utilisé pour certaines rotations. Le maintenir comme limite explicite tant qu’un chemin GPU équivalent n’a pas été prouvé ; le modifier seulement après reproduction et test sur le moteur natif.

**Fichiers candidats :** `battle_gen5_actor_motion.dart`, `battle_gen5_camera_motion.dart`, `battle_perspective_camera.dart`, `battle_scene_combatant_component.dart`, `battle_pokemon_sprite_resolver.dart`, `battle_overlay_component.dart` et `tools/avelune_attack_comparator/lib/preview_game.dart`.

**Avancement :** le lecteur expérimental accepte le côté de l’attaquant pour ses acteurs et ses cadrages. Son repère de caméra reste attaché aux places physiques joueur/adversaire. Trois tests vérifient le déplacement adverse et sa restitution, l’équivalence des cadrages et celle de la projection d’un même acteur lorsque les rôles sont inversés. La suite de scène et le smoke runtime passent : 79 tests ; le smoke de l’hôte passe : 14 tests. Les émetteurs, la revue visuelle des deux sens et le raccord au Player ne sont pas démontrés par ces tests ; les appels existants continuent à utiliser le côté joueur par défaut.

**Fin du lot :** acteurs et caméra restent cohérents sur les exemples ciblés et après interruption ; les différences restantes entre squelette, GIF et rendu GPU sont indiquées.

## Lot 4 — Sons et synchronisation

**But :** conserver un résultat audible utilisable tout en distinguant les sons réellement synchronisés des approximations.

- [ ] Faire l’inventaire des sons et des commandes `PlaySE`, `PanSE` et `MoveSE` pour Charge, Pistolet à O, Surf, Tonnerre et une attaque dont le son manque. Dans l’atelier actuel, un MP3 d’attaque complète est préparé via `WorkshopMoveAudio` : cela ne prouve pas la synchronisation de chaque commande source.
- [ ] Réutiliser les ressources et le lecteur existants ; ne convertir des événements individuels que lorsque leur correspondance avec la source est connue. Conserver le clip complet comme repli annoncé si nécessaire.
- [ ] Vérifier déclenchement, fin, interruption et absence de son, sans bloquer le combat ; tester au moins deux attaques enchaînées et distinguer les attentes visuelles des attentes audio.
- [ ] Comparer l’audio sur un enregistrement de référence adapté lorsqu’il existe. L’APNG de comparaison étant muet, ne pas en déduire une synchronisation sonore.

**Fichiers candidats :** `tools/avelune_attack_comparator/lib/workshop_move_audio.dart`, `lib/preview_game.dart`, `packages/map_runtime/lib/src/presentation/flame/battle_gen5_source_program_playback.dart`, `battle_overlay_component.dart` et `battle_sfx_player.dart`. Le test existant `packages/map_runtime/test/battle_gen5_source_sound_dispatch_test.dart` couvre la distribution des sons.

**Fin du lot :** exemples avec son exact ou approximatif identifiés ; l’absence de certaines ressources ne bloque pas la revue des visuels.

## Lot 5 — Exécuter et compléter le catalogue par lots

**But :** maximiser la couverture avec un inventaire et des corrections généralisables.

- [ ] Recalculer l’inventaire sur l’index de départ et les aperçus intégrés, sans additionner les doublons. Compter séparément attaque, variante, référence, programme et ressource ; conserver l’identifiant source et le numéro de variante dans les résultats.
- [ ] Exécuter le test groupé `workshop batch programs complete in the source scene` sur l’index complet après les corrections communes. Pour chaque échec, conserver attaque, variante, instruction ou ressource et raison. Les erreurs isolées n’arrêtent pas la passe suivante.
- [ ] Regrouper les échecs par même cause ; corriger en priorité celles qui débloquent plusieurs entrées. Réutiliser `Gen5SourceProgramConverter` et les ressources source déjà disponibles ; ne pas réinventer les animations à la main si le script et les paramètres existent.
- [ ] Tester les variantes ou contextes réellement concernés : côté joueur/adversaire, plusieurs phases, plusieurs cibles si déjà prises en charge, fond ou son manquant. Une variante inconnue ou un effet non couvert reste visible comme limitation, avec un repli précis.
- [ ] Pour chaque lot de génération, fournir les totaux **programmes présents / lecture technique réussie / échecs avec raison / vus dans l’atelier / validés visuellement**. Ces catégories mesurent des choses différentes et ne doivent pas être additionnées.

**Fichiers candidats :** `packages/map_authoring/lib/src/domains/gameplay/pokemon_external/gen5_source_program_converter.dart`, `gen5_battle_script_*`, `gen5_spl_particle_converter.dart`, `tools/avelune_attack_comparator/assets/bw2/batch/` et `packages/map_runtime/test/battle_gen5_source_overlay_test.dart`.

**Fin du lot :** tout le catalogue de départ a été parcouru techniquement, les exceptions sont nommées et les corrections à fort impact ont été appliquées ; les animations encore approximatives ne sont pas annoncées comme fidèles.

## Lot 6 — Rendre la revue de Yoahn simple

**But :** permettre de vérifier chaque attaque sans lire de JSON ni chercher des fichiers.

- [ ] Conserver le lecteur Avelune réel et la référence côte à côte, la recherche, le choix de format et le bouton rejouer. Vérifier qu’un changement rapide de sélection n’affiche pas les ressources d’une attaque précédente.
- [ ] Ajouter seulement ce qui manque pour parcourir la liste facilement : attaque précédente/suivante, variante affichée et état lisible « à revoir », « écart à corriger » ou « validée par Yoahn ». Un résultat automatique reste un statut technique distinct.
- [ ] Conserver les décisions de revue dans un petit fichier local, hors des jeux et de leurs sauvegardes ; sauvegarder sans effacer les décisions déjà présentes et permettre de reprendre après fermeture. Aucun nouveau serveur ni base de données de revue.
- [ ] Afficher les manques connus en langage simple, notamment variante, Pokémon de remplacement, son approximatif et effet non reproduit. En l’absence de référence, montrer la limite plutôt qu’une comparaison vide présentée comme réussie.

**Fichiers candidats :** `tools/avelune_attack_comparator/lib/main.dart`, les tests `tools/avelune_attack_comparator/test/`, et un petit module local de persistance seulement si le code existant ne suffit pas.

**QA partielle :** les commandes précédent/suivant et l’état de revue sont implémentés ; quatre tests couvrent les décisions, les variantes, le fichier mal formé, les écritures simultanées et les contrôles. L’analyse ciblée est sans diagnostic. Une copie macOS signée a affiché ces commandes et la comparaison, mais l’outil de contrôle n’a pas pu cliquer dans sa fenêtre (`noWindowsAvailable`) : la modification d’un avis et sa conservation après fermeture n’ont pas été observées en natif. La copie de test et son conteneur ont été supprimés après arrêt de leur processus ; l’atelier précédent reste ouvert et le raccourci du Bureau n’a pas été mis à jour.

**Fin du lot :** Yoahn peut retrouver une attaque, la rejouer, changer de format et reprendre ses décisions après fermeture. Les captures automatiques ne valident pas les attaques à sa place.

## Lot 7 — Relier l’API, l’export et le Player

**But :** rendre les animations réellement utilisables dans un jeu, en commençant par un petit ensemble représentatif. Commencer les trois premières étapes immédiatement après le lot 1 ; terminer la livraison après les itérations du jalon 2.

- [ ] Contrôler l’état du service API réellement déployé et comparer son contrat au validateur local `avelune-pokemon-api/src/animations/inspect-recipe.ts`, aux modèles Dart et aux programmes de l’atelier. Tester les incompatibilités sur des copies : ne pas conclure qu’un JSON est compatible parce qu’il est stocké quelque part.
- [ ] Faire passer **Charge, Pistolet à O et Surf** par l’import canonique existant ; ajouter Tonnerre ou Vol lorsqu’une capacité supplémentaire est prouvée. Si une adaptation du contrat est nécessaire, la limiter aux capacités utilisées, avec le même corpus de cas positifs/négatifs côté API et Dart, sans écarter les limites de taille ou d’intégrité.
- [ ] Préserver les garanties des projets et sauvegardes existants. Exporter une copie de test `.avelunegame`, inspecter les programmes, les médias et leurs empreintes, puis couper l’accès à l’API et vérifier que les animations se chargent depuis le paquet local.
- [ ] À ce premier passage, noter pour chaque étape le premier point qui bloque et le repli réellement utilisé. Corriger le minimum nécessaire pour prouver la chaîne sur une attaque avant de l’élargir aux trois ; un affichage de repli seul ne valide pas le nouveau moteur.
- [ ] Exercer le même contrat par l’API d’authoring, Studio et MCP lorsque le lot modifie l’import/export : action `pokemon.move_recipe.import`, test JSONL, test MCP et catalogue `pokemap_describe`. La persistance brute d’un JSON ne constitue pas cette preuve.
- [ ] Tester d’abord le parcours réel sur l’iPhone 15 Pro de Yoahn : installation, chargement d’une sauvegarde existante protégée, combat, plusieurs attaques, changement de Pokémon, fin de combat et poursuite. Ajouter l’iPad si le format de présentation a changé. Noter ce qui est visible, audible et réellement chargé ; ne pas confondre compilation, TestFlight et validation sur appareil.
- [ ] Étendre ensuite l’import en lot aux programmes admissibles ; les non admissibles conservent le repli existant et une raison lisible. Pas de publication massive avant un essai réussi de la chaîne complète.

**Fichiers candidats :** `/Users/karim/Project/avelune-pokemon-api/src/animations/inspect-recipe.ts` et ses tests ; `packages/map_authoring/lib/src/domains/gameplay/pokemon_external/`, `packages/map_authoring/test/workspace/battle_recipe_import_test.dart`, `packages/map_runtime/lib/src/presentation/flame/battle_offline_move_recipe_loader.dart`, `battle_move_recipe_compiler.dart`, `tools/pokemap_mcp/test/battle_recipe_import_stdio.test.ts` et `examples/playable_runtime_host/`.

**Premier contrôle :** le programme brut de Charge est rejeté par le contrat actuel, y compris enveloppé dans une recette, car `gen5SourceProgram` n’est pas une capacité reconnue. Le commit API local `ef552fe` aligne les particules 3/4 et deux commandes de mouvement sur le contrat Dart existant ; un paquet synthétique utilisant les cinq vraies textures et la définition de Charge passe l’inspection locale. Ce paquet n’est pas l’attaque complète, et l’API déployée n’a pas été modifiée. Le service public répond sur `/health` ; dans `public-2026-11`, les listes de médias de Charge, Pistolet à O et Surf contiennent chacune un clip audio, sans recette d’animation dans ces listes. Les éventuels brouillons privés n’ont pas été examinés.

**Périmètre des programmes pilotes :** Charge contient 18 instructions et deux déclenchements d’émetteur ; Pistolet à O en contient 53, dont 15 projectiles mobiles et deux impacts ; Surf en contient 43, dont cinq déclenchements, un tremblement de caméra et des changements de palette. Les définitions SPL correspondantes sont les ressources 199 (v3), 220 (v5) et 222 (v5). Le contrat doit conserver l’ordre, les répétitions et la correspondance des numéros d’émetteurs ; admettre seulement leurs définitions ne suffit pas.

Sur les 581 séquences du catalogue batch actuel, en parcourant chaque variante depuis son point d’entrée jusqu’à son premier `end`, 557 utilisent `moveCameraPreset`, 493 `startEmitter` et 105 `startMovingEmitter`. Ces totaux comptent des séquences, pas des attaques validées ni des animations garanties fidèles ; les 18 aperçus spéciaux hors index ne sont pas inclus.

**Avancement du pilote, 4 novembre :**

- Le script complet de Charge et sa définition SPL réelle ont été exercés dans un tour expérimental suivi : les deux émetteurs et trois événements sonores sont dispatchés, puis la jauge de dégâts n’avance qu’après la fin de la présentation. Les particules sont simulées sans textures, les sons sont des événements observés sans lecture audio ; l’API, le chargement depuis un paquet et le Player distribué ne sont pas impliqués.

- Les recettes partielles de Charge, Poing-Karaté et Direct Toxik sont déjà publiées dans `public-2026-11-02-bw2`. Le transport HTTP utilisé par Studio a récupéré et vérifié leurs 7, 6 et 5 ressources ; leurs empreintes correspondent aux bundles convertis utilisés dans les tests hors ligne. Le validateur réellement déployé les accepte aussi. Le dépôt authentifié de Charge, ses sept liens et sa lecture après publication passent dans une base API de test en mémoire. Écras’Face et Souplesse restent refusées par le convertisseur actuel.
- Charge et ses sept ressources passent l’import canonique, JSONL, annulation/rétablissement, réouverture et export dans un projet de test. L’API distante est simulée pour ce test ; aucune publication réelle n’en découle. Six scénarios d’import/export réussissent, analyse ciblée sans diagnostic.
- Dans un jeu de test exporté et avec HTTP interdit, Charge passe trois scénarios du moteur 2D : lecture, annulation et fin d’un son bloqué. Les particules, le mouvement et la caméra sont exercés. Poing-Karaté et Direct Toxik passent également en 2D. Charge passe le test de combat spatial en rendu logiciel. L’audio est simulé et les avertissements `path_provider` concernent un son de repli : aucune écoute native n’est démontrée.
- L’action `pokemon.move_recipe.import` est présente dans le catalogue MCP connecté. Le programme groupé de l’atelier a parcouru sans échec ses 581 entrées, dans une scène expérimentale et en rendu logiciel ; ce n’est ni une revue visuelle ni un test du Player distribué.
- Les 11 scénarios ciblés de l’import Studio passent avec une recette synthétique, notamment le passage par le panneau des attaques et l’export. Le projet choisit son catalogue enregistré ; les nouveaux projets prennent `public-2026-11-02-bw2`. L’import de Charge depuis l’interface Studio réelle reste à observer.
- Les définitions de particules de Pistolet à O et Surf sont en version 5. Le contrat local Dart/API, l’export et le Player de développement acceptent désormais cette version avec une capacité dédiée ; l’API déployée et les applications distribuées n’ont pas été mises à jour. Les vraies définitions 220 et 222 passent les deux validateurs. L’import et l’export d’une recette v5 synthétique, ainsi que le refus d’un paquet dont le marqueur v5 a été retiré, sont testés.
- Le convertisseur tient compte de la correspondance entre numéros source et définitions compactées ; le script de traitement en lot essaie désormais les émetteurs utilisés lorsqu’une conversion complète échoue. La sélection réelle de Pistolet à O est testée depuis la source 220. Les scripts vérifiés de Pistolet à O et Surf ont produit localement des recettes partielles de respectivement 2 et 5 émetteurs, avec leurs ressources et leurs clips audio. Les deux bundles passent le validateur API local et sont préparés en rendu logiciel par le chargeur Player avec accès réseau interdit pendant la préparation. Ces tests ne prouvent pas leur apparence, le son natif ou un combat réel. Pistolet à O omet encore des mouvements et des émetteurs répétés ; Surf omet notamment des mouvements de caméra, une vibration et des variations de palette. Aucun programme complet n’a été livré par ces recettes.
- Import pilote pour HeartGold : le MCP connecté ne peut lire les fichiers à préparer que dans ses racines d’artefacts configurées. Les copies de transfert de ces recettes et les bundles temporaires du pilote ont été supprimés après vérification des consommateurs ; le cache `tsx-501` préexistant a été préservé.
- Les trois recettes ont ensuite été importées dans le projet source `/Users/karim/Project/Pokemon HeartGold/jeu` par `pokemon.move_recipe.import`, après prévisualisation et sans changer le catalogue général. Les liaisons `tackle`, `karate_chop` et `poison_jab`, les recettes et leurs 18 ressources ont été relues avec leurs empreintes. L’action prévoit l’annulation ; celle-ci n’a été exercée que sur un projet de test. La sauvegarde du joueur n’a pas été modifiée. Le projet utilisait auparavant le catalogue par défaut `public-2026-11`, sans ces recettes.
- L’export [HeartGold - pilote animations BW2.avelunegame](</Users/karim/Desktop/HeartGold - pilote animations BW2.avelunegame>) a été créé après expiration du délai de la réponse MCP. L’inspecteur complet valide 53 901 fichiers et l’empreinte SHA-256 du paquet `f95ae689f8488eecd22fa966d5b3f84f6a969567d6231ff041504d96b4372b98`. L’archive contient les trois recettes et leurs 18 ressources. Il s’agit d’un export `localTest` sans signature ; l’inspection ne vérifiait pas les capacités d’une version de Player précise.
- Cet export garde l’identité `private.hgss.bourg-geon` et la version `0.1.11`. Le code d’installation rejette une même version de contenu différent ; l’état du jeu installé sur l’iPhone n’est pas connu. Ne pas conseiller l’installation tant que ce point et la compatibilité de la build TestFlight ne sont pas vérifiés ; ne jamais supprimer ou réinitialiser la sauvegarde pour contourner le conflit.
- Contrôles complémentaires locaux : 17 tests Core, 47 tests de convertisseurs et 5 ignorés faute de sources optionnelles, 22 tests API, 16 tests du compilateur runtime et le test MCP d’import/annulation v5 réussis. Les analyses ciblées et les builds API/MCP réussissent ; aucun DTD actif ne permet un hot reload. Le contrôle Markdown échoue sur deux documents ignorés préexistants d’autres chantiers.
- Aucun résultat ci-dessus ne prouve la fidélité à BW2, un parcours complet effectué en une seule fois depuis l’API déployée, l’exécution du programme complet de l’atelier ou un essai sur iPhone. `FG-052` et `FG-053` restent ouverts.

**Fin du lot :** preuve d’au moins trois attaques visibles, avec le son observé ou son absence explicitement indiquée, dans un export chargé hors ligne et essayé sur iPhone ; inventaire des entrées importées, des replis et des manques. L’approbation visuelle de Yoahn reste distincte.

## Vérifications prévues, à adapter uniquement aux fichiers effectivement touchés

Ces commandes sont des **commandes futures**, pas des tests exécutés pendant la rédaction du plan.

```bash
cd /Users/karim/Project/pokemonProject/tools/avelune_attack_comparator
AVELUNE_ATTACK_WORKSHOP_QA=/Users/karim/Library/Caches/AveluneQA/attack-volume-shapes-01a18d64 flutter test --no-pub --concurrency=1 test/workshop_reference_pokemon_test.dart test/workshop_reference_preview_test.dart
flutter analyze --no-pub --no-fatal-infos lib/main.dart lib/preview_game.dart lib/workshop_reference_pokemon.dart
```

Attendu : les tests ciblés réussissent et l’analyse ne contient pas de nouvelle erreur ou de nouvel avertissement. Les scénarios utilisant la racine QA ne doivent pas être considérés comme exécutés s’ils sont ignorés faute de variable d’environnement.

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter test --no-pub --concurrency=1 test/battle_gen5_source_overlay_test.dart --plain-name 'workshop batch programs complete in the source scene'
flutter test --no-pub --concurrency=1 test/battle_gen5_actor_motion_test.dart test/battle_spl_color_texture_animation_test.dart test/battle_gen5_source_sound_dispatch_test.dart
```

Attendu : le parcours technique couvre toutes les entrées de l’index courant et indique les échecs par entrée ; les suites de mécanismes touchés réussissent. Ces tests n’évaluent pas seuls la fidélité visuelle ou l’audio natif.

```bash
cd /Users/karim/Project/pokemonProject/packages/map_authoring
dart test test/domains/gameplay/gen5_source_program_converter_test.dart test/domains/gameplay/gen5_batch_recipe_converter_test.dart test/workspace/battle_recipe_import_test.dart
cd /Users/karim/Project/pokemonProject/tools/pokemap_mcp
npm run build
node --import tsx --test --test-concurrency=1 test/battle_recipe_import_stdio.test.ts
```

Attendu si l’import est modifié : convertisseur et import conformes pour les cas concernés, serveur MCP reconstruit, tests ciblés réussis et catalogue actif vérifié. Côté API, lancer les tests de `test/animations/inspect-recipe.test.ts` et `inspect-recipe-bundle.test.ts` ainsi que `npm run typecheck` si son contrat change.

À chaque `flutter test`, relever le PID du lanceur et ses descendants, puis ne terminer que les processus résiduels dont l’appartenance est démontrée. Les copies QA et captures jetables vont dans le dossier de travail existant sous `/Users/karim/Library/Caches/AveluneQA/attack-volume-shapes-01a18d64/` ; conserver les preuves utiles, préserver les sauvegardes et ne pas toucher aux autres sessions. Les commits doivent rester ciblés et respecter l’autorisation Git de Yoahn.

## Critères de fin du POC

1. Les sept exemples de départ ont un constat portrait/paysage, une référence identifiée et une liste d’écarts visibles ; aucune affirmation de fidélité n’est déduite uniquement d’un test.
2. Le catalogue courant a un résultat technique par entrée, les variantes et manques sont identifiés et les corrections partagées ont été propagées en lot lorsque justifié.
3. L’atelier permet de revoir les attaques et de garder les décisions de Yoahn sans confondre « se lance » et « validée ».
4. Au moins Charge, Pistolet à O et Surf sont vérifiés dans un jeu exporté, en lecture hors ligne et sur iPhone ; les sons et replis sont qualifiés honnêtement.
5. Aucun jeu ou sauvegarde protégés ne sont écrasés ou rendus incompatibles ; les tests pertinents, le suivi Notion et l’état Git sont fournis. Le ticket reste `TO REVIEW` après implémentation vérifiée ; `DONE` appartient à Yoahn.

## Vérification de la préparation

- Audit en lecture seule du code de l’atelier, du lecteur runtime, du convertisseur, du validateur local de l’API, du plan historique et des tests existants ; aucune commande n’a été exécutée contre les projets et sauvegardes de jeu.
- Inventaire JSON par script Python : 581 entrées, 544 identifiants, 544 URL de référence, 574 chemins de programme distincts et aucun chemin de programme absent sur disque. Le comptage exclut les 18 aperçus déclarés dans `PreviewMove.values`.
- `git ls-remote --heads origin main` a confirmé le même SHA `21900a78f14ca95789759d8c66491506b812d52f` que le `HEAD` local. L’index batch du dépôt et celui de l’application du Bureau ont la même empreinte SHA-256 `36000584fa092f905d941fa2840643f9381e2f2ab6dbc5bd3be23c128ee79edc`.
- Lors de la première préparation, l’état Git était propre ; le plan et une exception précise dans `.gitignore` ont ensuite été ajoutés. Les changements de synchronisation trouvés à la reprise ont été testés puis commités dans `c8eb9e87f` ; les vecteurs de contrat sont dans `2a5a92cd2`, et l’alignement du validateur API dans `ef552fe`. Le plan et `.gitignore` restent locaux.
- `git diff --check` ne signale pas d’erreur sur les fichiers suivis. Le contrôle Markdown avec `POKEMAP_MARKDOWN_MAX_NEW=1` échoue sur deux Markdown ignorés préexistants sous `documentation/reports/avelune_player/plans/` et `documentation/reports/heartgold/` ; les deux fichiers et le plan sont comptés comme trois nouveaux documents. Ils n’ont pas été modifiés ou supprimés.
- Relecture du plan : l’inventaire et l’existence des 574 programmes ont été revérifiés, ainsi que la présence des principaux fichiers de tests cités. Aucun test produit ni build n’a été exécuté pour cette relecture. Le contrôle Markdown et `git diff --check` ont été relancés avec les résultats ci-dessus.

## Relecture critique du plan

| Passe | Verdict |
|---|---|
| Audit et architecture | Le lecteur expérimental et le chemin de production sont distincts ; les comptes batch excluent les aperçus déclarés en code et ne mesurent pas la fidélité. |
| Faisabilité | Les premiers exemples, sources, chemins et tests existent. Les corrections exactes attendent les écarts visibles ; inventer leurs paramètres avant observation serait hasardeux. |
| Tests et build | Le plan sépare exécution technique, rendu logiciel, rendu natif, comparaison visuelle, export et appareil. Aucun test ni build produit n’a été lancé pour rédiger ce document. |
| Périmètre | Les règles de combat, les modèles 3D, les triples et une refonte de Studio restent hors scope. Les variantes difficiles et sons manquants peuvent rester signalés pour le POC. |
| Critique finale | Les groupes de priorité se recoupent et leurs volumes n’annoncent aucun nombre d’attaques « réparées ». L’intégration au Player peut nécessiter une évolution de contrat non encore chiffrable ; la limiter aux besoins prouvés. |

**Mandat de ce document :** suivre l’exécution sans confondre aperçu expérimental et livraison dans le jeu. Après les constats initiaux du lot 1, engager le pilote initial du lot 7 ; la fidélité globale et le test iPhone restent ouverts.
