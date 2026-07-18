# Matrice précise — Narrative Studio et démonstrateur Selbrume

Date : 18 juillet 2026<br>
Source : `reports/gameplay/fg_000_narrative_studio_selbrume_readiness_audit.md`<br>
Baseline de contenu : `selbrume/project.json`, SHA-256 `f22c2bf0b8b935a781c4e1c70db83d56ed956583118e3ea2d3427bca7f851141`<br>
Verdict hérité de l'audit : Narrative Studio **50 %**, capacité moteur/runtime **62 %**, démonstrateur complet **environ 50 % et non prêt**

## Légende

| État | Signification |
|---|---|
| `PRÊT` | La capacité ciblée existe et dispose d'une preuve fraîche suffisante pour être utilisée dans Selbrume. |
| `PARTIEL` | Le socle existe, mais un cas important, une intégration ou une preuve manque. |
| `MANQUANT` | Le contrat produit/runtime requis n'existe pas encore. |
| `BLOQUÉ` | Le contenu existe, mais ne peut pas être terminé avec les capacités actuelles. |
| `GATE ROUGE` | Une vérification fraîche échoue ; aucune readiness ne peut être déclarée. |

`PRÊT` désigne une capacité isolée, pas un lot roadmap `DONE`. Aucun lot mécanique n'est proposé `DONE` dans l'audit parent.

## 1. Matrice des capacités du Narrative Studio et du moteur

| Domaine | Élément | État | Ce qui est prêt | Ce qui manque exactement | Impact sur Selbrume | Priorité |
|---|---|---|---|---|---|---|
| Données | Modèles et JSON narratifs | `PRÊT` | Storyline, Chapter, Step, Scene, Event V2, Fact, World Rule et Cinematic sont structurés et sérialisables. | Pas de manque bloquant pour stocker la structure actuelle. | Le projet peut représenter une campagne riche sans JSON manuel côté utilisateur. | — |
| Données | Références du snapshot | `PARTIEL` | 30 Scenes, 27 Events, 46 Facts, 16 cinematics et 12 dialogues sont déclarés ; les références structurales principales sont valides. | L'atteignabilité n'est qu'optimiste : 26 Events sur 27 ; aucune preuve de parcours réel complet. | Le volume de contenu ne garantit pas sa jouabilité. | P0 |
| Navigation | Shell Narrative Studio | `PARTIEL` | Navigation spécialisée vers Overview, Storylines, Scenes, Events, Cinematics, Dialogues, Facts et World Rules. | Validator absent ; convergence UI et persistance encore inégales. | L'auteur peut accéder aux principaux outils, mais pas fermer le projet depuis un seul endroit. | P1 |
| Overview | Vue d'ensemble | `PARTIEL` | Résumé et accès aux espaces narratifs. | Une partie repose encore sur `Scenario/globalStory` legacy au lieu de la source canonique Storyline/Scene/Event V2. | Risque d'afficher un état différent de celui réellement exécuté. | P1 |
| Storylines | Board, chapitres et Steps | `PARTIEL` | 4 Storylines, 7 chapitres et 26 Steps sont authorés ; 37 liens Step → Scene. | Statut `draft` partout ; conditions d'activation, outcomes et progression globale incomplets. | La structure Selbrume est visible, mais sa progression n'est pas démontrée. | P0 |
| Storylines | Graph de progression | `PARTIEL` | Visualisation structurelle des Storylines et Steps. | Pas de langage complet pour conditions, branches, convergence et outcomes. | Impossible d'auditer visuellement toute la campagne et ses chemins. | P1 |
| Scenes | Library et graphes de base | `PRÊT` | Start/end, dialogue, cinematic, battle, action, arêtes et diagnostics sont utilisables. | Aucun manque pour les séquences linéaires et branches de combat simples. | Les scènes principales peuvent être décrites et exécutées. | — |
| Scenes | Conséquences d'état simples | `PRÊT` | `setFact`, `completeStoryStep` et `markEventConsumed` sont modélisés, validés et exécutés. | La palette est trop courte pour les récompenses de RPG. | Les milestones narratifs et Facts peuvent avancer. | — |
| Scenes | `branchByOutcome` | `MANQUANT` | Le type existe dans le modèle. | UI désactivée (`mapping futur requis`), diagnostic unsupported et rejet par le plan builder runtime. | Les choix de dialogue ne peuvent pas piloter directement un graphe de Scene. | P0 |
| Scenes | Récompenses canoniques | `MANQUANT` | Des mutations give Pokémon/item/money existent ailleurs dans le moteur. | Aucune conséquence Scene authorable pour donner/retirer Pokémon, objet, argent ou récompense idempotente. | Bloque starter, récompenses de Mado, Goélise, cabane et récompense finale. | P0 |
| Events V2 | Sources de déclenchement | `PRÊT` | `mapEnter`, `triggerEnter`, `entityInteract` et `outcomeReceived` existent dans le moteur. | Pas de manque structurel pour les déclencheurs Selbrume actuels. | Maël, port, indices, NPC et follow-ups battle peuvent être raccordés. | — |
| Events V2 | Conditions sur Facts | `PRÊT` | Conditions booléennes testées et utilisées dans le projet. | Pas de variables/counters ni de composition avancée authorable. | Suffisant pour les trois indices séparés ; moins adapté aux collectes génériques. | P2 |
| Events V2 | Politique `oneShot` | `PRÊT` | Consommation automatique après succès, autorité de dispatch et persistance save/load. | La preuve doit encore être étendue à toute la campagne réelle. | Évite les doubles scènes et doubles récompenses lorsque le flux termine. | P1 |
| Events V2 | Intégration du projet promu | `GATE ROUGE` | Les variantes fixture des trois sources passent ; les logs du port montrent source résolue, Scene lancée et dialogue ouvert. | Deux tests du projet réel expirent ensuite dans les opérations awaitables ; le harness ne ferme pas les nouveaux overlays. | La baseline courante ne peut pas être déclarée verte. | P0 |
| Events | Map Events View consolidée | `MANQUANT` | Event Builder V2 sait éditer un Event individuel. | Aucune vue globale par map montrant sources, zones, NPC, conditions, Scenes et erreurs de raccordement. | L'auteur ne peut pas contrôler rapidement les 27 Events de Selbrume. | P1 |
| Dialogues | Fichiers et authoring Yarn | `PRÊT` | Création, import, renommage, suppression, dossiers, lecture disque et sélection de nœud. | Pas de manque pour un dialogue linéaire. | Les conversations peuvent être écrites et jouées. | — |
| Dialogues | Options et jumps à l'écran | `PARTIEL` | Le runtime sait afficher des choix et suivre les jumps Yarn. | Le choix sélectionné ne devient pas un outcome public/persisté. | Le joueur peut choisir visuellement, mais le monde ne mémorise pas le choix. | P0 |
| Dialogues | Outcome Yarn → Scene/Fact | `MANQUANT` | Aucun contrat public ne l'expose aujourd'hui. | Qualifier l'outcome, le persister, le mapper dans Scene Builder et le transmettre au runtime. | Bloque ton de Lysa, panique du port, acceptation Mado et décision Goélise. | P0 |
| Facts | Facts booléens | `PRÊT` | 46 Facts, valeurs par défaut, écriture runtime, diagnostics et save/load. | Aucun manque pour des états oui/non. | Le cœur de la progression Selbrume est représentable. | — |
| Facts | Variables et compteurs | `MANQUANT` | Les collectes peuvent être simulées avec un Fact par objet. | Pas de compteur/valeur numérique réutilisable. | Non bloquant pour les 3 cristaux actuels, mais coûteux pour étendre le jeu. | P2 |
| World Rules | Visibilité et dialogue NPC | `PRÊT` | Masquer/afficher une entité, override de dialogue et activation d'Event. | Pas de manque pour changer un NPC simple après progression. | Lysa et les dialogues post-quête peuvent évoluer. | — |
| World Rules | Portes, collisions et environnement | `MANQUANT` | Les Facts déclencheurs existent. | Aucun effet complet pour collision, porte, passage, tiles, brouillard, météo, ambiance ou mécanisme du phare. | L'ouverture du Passage des Dames et la dissipation de la brume ne sont pas matérialisées proprement. | P1 |
| Cinematics | Modèle et Builder | `PARTIEL` | Timeline, acteurs, placements, déplacements, caméra, emotes et diagnostics sont authorables. | La persistance/UX complète n'est pas prouvée sur toute une campagne. | L'outil peut concevoir une cinématique, mais Selbrume n'en fournit presque pas de réelles. | P1 |
| Cinematics | Contenu Selbrume | `BLOQUÉ` | 15 IDs de cinematics canoniques existent. | Les 15 timelines Selbrume sont chacune réduites à un unique `wait`; seul un prototype hors campagne est riche. | Les moments narratifs clés n'ont pas de mise en scène réelle. | P1 |
| Cinematics | Playback runtime visuel | `MANQUANT` | Résolution de l'asset et attente de la durée. | `PlayableMapGame` utilise `SceneCinematicRuntimeNoVisualPlayer` : aucun mouvement, caméra, fade, emote, son ou FX visible. | Même une timeline complète ne serait pas jouée visuellement. | P1 |
| Validation | Diagnostics locaux | `PRÊT` | Graphes, références, Facts, World Rules, cinematics et readiness ciblée ; 110 tests core frais au vert. | Ces diagnostics ne calculent pas la campagne complète. | Les erreurs locales sont bien détectées. | — |
| Validation | Validator produit global | `MANQUANT` | Un validator beta et plusieurs diagnostics existent. | Route produit absente ; pas d'atteignabilité des Steps/Events, de fermeture des outcomes, de récompenses ou de checkpoints save dérivés du projet. | Impossible d'obtenir un verdict « Selbrume jouable » fiable depuis l'éditeur. | P0 |
| Persistance éditeur | Sauvegarde des assets auteur | `PARTIEL` | Dialogues et Event V2 ont des chemins disque affirmés. | Persistance moins homogène pour plusieurs autres surfaces du manifeste. | Risque qu'une configuration visible ne soit pas la donnée réellement promue. | P1 |

## 2. Matrice des capacités gameplay nécessaires à Selbrume

| Domaine | Élément | État | Ce qui est prêt | Ce qui manque exactement | Impact sur le démonstrateur | Priorité |
|---|---|---|---|---|---|---|
| Nouvelle partie | Construction du GameState | `PRÊT` | État initial, spawn, party/bag et validation générique sont testés. | Le flux produit complet doit encore sélectionner la configuration narrative. | Le moteur sait démarrer une partie techniquement. | — |
| Nouvelle partie | Configuration B, party existante | `PRÊT` | `fact_player_started_with_existing_pokemon` est vrai par défaut et le projet fournit une équipe initiale. | La convergence produit avec le chemin starter doit être explicitée. | La route B active permet d'avancer sans choisir un starter. | P1 |
| Nouvelle partie | Configuration A, choix du starter | `MANQUANT` | Le moteur sait ajouter un Pokémon par mutation générique. | Picker auteur, écran/runtime de choix, conséquence `givePokemon`, anti-duplication, Fact et convergence. | Le chemin prévu dans `selbrume.md` n'est pas jouable. | P0 |
| Party/Bag/PC | État et opérations génériques | `PRÊT` | Party, stockage, bag, argent, capture vers party/box et sérialisation existent. | Pas de raccord universel depuis Narrative Scene. | Les systèmes RPG de base peuvent conserver les résultats. | P0 pour le raccord |
| Sauvegarde | Round-trip générique | `PRÊT` | Party, PC, bag, argent, progression, Facts, Steps, Events consommés et outbox sont sauvegardables. | Pas de preuve longue à travers toute la campagne. | Le format sait conserver l'état narratif. | — |
| Sauvegarde | Checkpoints Selbrume | `PARTIEL` | Des slices ciblées save/load passent. | Aucun save/reload après choix Lysa, au milieu des indices/cristaux, autour du boss ou après les quêtes annexes. | Risque de duplication ou de progression perdue sur une partie de 2–3 h. | P0 |
| Combat | Trainer battle | `PRÊT` | Setup, victoire/défaite, write-back PV, trainer defeated, argent et persistance sont présents. | Les combats Selbrume ne sont pas tous joués par input réel dans un E2E. | Les combats peuvent fonctionner isolément. | P1 |
| Combat | Lysa victoire/défaite | `PARTIEL` | Deux outcomes battle et deux Events `outcomeReceived`; les deux Scenes post-combat complètent le Step. | Choix de ton absent, cinematic non visuel, combat non parcouru jusqu'au résultat par un test joueur complet. | La structure converge, l'expérience complète n'est pas prouvée. | P0 |
| Combat | Gardiens du phare | `PARTIEL` | Deux Scenes battle et Facts de victoire existent. | Pas de traversal et de combats joués end-to-end, ni de récompenses/progression démontrées. | Le mini-donjon est déclaré, pas validé comme séquence jouable. | P1 |
| Combat | Pokémon final / boss | `PARTIEL` | Victoire/défaite et branche de résolution sont authorées. | Le boss est un `trainer battle`, pas une static encounter canonique ; politique capture/retry/apaisement non fermée. | Simplification MVP possible, mais fidélité au scénario non décidée. | P1 |
| Combat | XP, level-up, moves et récompenses | `PARTIEL` | Certaines briques et tests ciblés existent. | Aucune preuve de progression cohérente sur les quatre combats et 2–3 h de jeu. | La courbe de progression de Selbrume n'est pas validée. | P1 |
| Rencontres | Wild encounter et capture | `PRÊT` pour une slice | Une Golden Slice capture/party existe et passe. | Densité, tables et équilibre de toute la campagne non définis ; une seule encounter table observée. | Suffisant pour une preuve isolée, trop faible pour une démo de 2–3 h. | P1 |
| Récompenses | Objets, argent et Pokémon depuis l'histoire | `MANQUANT` | Mutations gameplay disponibles hors contrat narratif. | Conséquences Scene authorables et idempotentes, présentation et save/reload. | Les quêtes peuvent se terminer narrativement sans donner leur récompense réelle. | P0 |
| Monde | Ouverture du Passage des Dames | `PARTIEL` | Fact et Scene de déverrouillage existent. | Effet physique sur collision/porte/passage et preuve de traversal. | Le récit peut déclarer le passage ouvert sans garantir que le joueur passe. | P0 |
| Monde | Dissipation de la brume | `PARTIEL` | Facts de résolution, Scene et cinematic ID existent. | World Rule environnementale et playback cinematic visuel. | La fin est enregistrée mais peu ou pas visible dans le monde. | P1 |

## 3. Matrice de fermeture du contenu Selbrume

| Arc ou contenu | État | Prêt dans le snapshot | Manque exact avant validation | Priorité |
|---|---|---|---|---|
| Maël — introduction | `PARTIEL` | Dialogue, Event, Scene, Facts et complétion des Steps. | Vrai choix starter A et convergence des deux configurations. | P0 |
| Port — alerte/panique | `PARTIEL` | Trigger, dialogues, Facts, Scenes et cinematics IDs. | Outcome du choix joueur et effet durable sur foule/dialogues. | P0 |
| Lysa — rencontre et combat | `PARTIEL` | NPC Event, Scene battle, victoire/défaite, deux follow-ups et convergence du Step. | Ton Yarn mémorisé, cinematic visuel et combat joué end-to-end. | P0 |
| Marais — arrivée et Mado | `PARTIEL` | Events, dialogues, Scenes et démarrage narratif. | Refus/acceptation réellement branché ; récompense de quête. | P0 |
| Trois indices | `PARTIEL` | Trois Events/Scenes/Facts et Fact agrégé. | Deux timeouts du harness à réconcilier ; traversal réel et save mid-enquête. | P0 |
| Soline — passage | `PARTIEL` | Conditions, dialogue, Fact et Step. | Transformation physique du passage et traversée prouvée. | P0 |
| Cristaux de sel | `PARTIEL` | Trois collectes, Facts, retour Mado et Steps. | Récompense réelle, idempotence et save/reload de la quête. | P0 |
| Goélise | `BLOQUÉ` | Départ de quête, nid, dialogue de choix et Scene de retour. | Les Facts `returned/kept` ne sont jamais produits ; l'Event de retour exige `returned=true` et reste le seul Event non atteignable dans la simulation 26/27. | P0 |
| Cabane du gardien | `PARTIEL` | Yvon, clé, carnet, Facts et Steps. | Attribution/consommation d'objet, world change, récompense et parcours réel. | P1 |
| Arrivée au phare | `PARTIEL` | Trigger, Scene, Fact et cinematic ID. | Timeline réelle, playback visuel et traversal depuis le passage. | P1 |
| Deux gardiens | `PARTIEL` | Deux battles et Facts de victoire. | Combats joués, progression, dialogue/récompense et save intermédiaire. | P1 |
| Confrontation finale | `PARTIEL` | Battle, outcomes, Facts de résolution et Step. | Décision trainer-vs-static, retry/capture/apaisement et preuve jouée. | P1 |
| Épilogue | `PARTIEL` | Trigger, Scene, dialogue, Facts de fin et Steps. | World change visible, cinematic finale réelle et arrivée par le parcours complet. | P1 |
| Campagne principale complète | `MANQUANT` comme preuve | Les 12 Steps principaux ont une structure substantielle. | Un walkthrough réel, ordonné, depuis New Game jusqu'à l'épilogue. | P0 |
| Trois quêtes annexes complètes | `MANQUANT` comme preuve | Les trois Storylines et la plupart des assets existent. | Choix, récompenses, idempotence et save/load end-to-end pour chacune. | P0 |
| Baseline promue | `GATE ROUGE` | Le projet courant charge dans plusieurs tests et le snapshot est inventorié. | Hash J5 attendu `8689d1…` contre snapshot `f22c2bf0…`; promotion et harness à remettre en cohérence. | P0 |
| Démonstrateur 2–3 h | `MANQUANT` comme preuve | Fondations moteur et contenu déclaré. | Build cible, parcours humain complet, durée mesurée, checkpoints save et absence de soft-lock. | P0 |

## 4. Ordre de traitement recommandé

| Ordre | Travail | Critère de sortie vérifiable |
|---:|---|---|
| 1 | Stabiliser le projet promu et le harness Event V2 | Hash volontairement promu ; les 6 cas du test trois-sources passent, overlays compris. |
| 2 | Ajouter le contrat Yarn outcome | Un choix réel produit un outcome qualifié, sauvegardé et utilisable par une Scene. |
| 3 | Étendre les conséquences Narrative Scene | Donner/retirer item, Pokémon et argent avec idempotence et round-trip. |
| 4 | Fermer les deux chemins Maël | Party vide → choix starter ; party existante → continuation ; même Step final. |
| 5 | Fermer Lysa, Mado et Goélise | Chaque choix pose les bons Facts, change les dialogues et ne se rejoue pas après reload. |
| 6 | Brancher le playback cinematic visuel | Mouvement, caméra, fade/emote/FX visibles dans `PlayableMapGame`; plus aucun placeholder Selbrume. |
| 7 | Étendre les World Rules environnementales | Passage, collisions/portes et brume changent réellement selon les Facts. |
| 8 | Construire le Validator global | Il détecte Event/Step inaccessible, Fact jamais produit, reward absent et outcome non fermé. |
| 9 | Prouver la campagne | E2E par checkpoints + walkthrough manuel du démarrage à l'épilogue et des 3 quêtes. |

## 5. Lecture finale

### Déjà prêt et réutilisable

- contrats narratifs et sérialisation ;
- graphes de Scenes linéaires et branches de combat ;
- Facts booléens et complétion de Steps ;
- sources Event V2 et `oneShot` ;
- dialogues Yarn linéaires ;
- combat trainer/wild et persistance générique ;
- party, bag, PC et sauvegarde générique ;
- diagnostics locaux.

### Manques qui bloquent directement Selbrume

- choix Yarn transformé en outcome persistant ;
- conséquences Scene de récompense ;
- flow starter complet ;
- fermeture de la quête Goélise ;
- baseline/harness Event V2 vert ;
- Validator global et E2E campagne.

### Manques nécessaires à la qualité du démonstrateur

- cinématiques visuelles et vraies timelines ;
- World Rules environnementales ;
- progression/rewards cohérents sur tous les combats ;
- sauvegardes à des checkpoints de quête ;
- walkthrough réel de 2–3 h.

## 6. Provenance et état des modifications

| Passe de l'audit parent | Verdict repris |
|---|---|
| Spécification | extraction `PASS`, fermeture `PARTIAL` |
| Éditeur/authoring | `PARTIAL`, environ 50 % |
| Moteur/runtime | `PARTIAL`, 60–65 % |
| Tests | `FAIL` strict pour la readiness |
| Critique finale | conclusion confirmée, niveau de preuve `PARTIAL` |

Fichier créé par cette demande :

- `reports/gameplay/fg_000_narrative_studio_selbrume_capability_matrix.md` — toutes les lignes sont nouvelles ; aucun fichier de code ou test n'a été modifié.

La roadmap n'est pas modifiée. Cette matrice explicite l'audit parent ; elle ne transforme aucun lot en `DONE`.
