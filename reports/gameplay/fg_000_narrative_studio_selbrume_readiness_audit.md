# Audit complet du Narrative Studio pour le démonstrateur Selbrume

Date de l'audit : 18 juillet 2026<br>
Périmètre : état du moteur, du runtime, de l'éditeur no-code et du contenu Selbrume ; aucune implémentation demandée<br>
Référentiels : `MVP Selbrume/narrative_studio.md`, `MVP Selbrume/selbrume.md`, `pokemap_roadmap_mecaniques_fangame.md`<br>
Lot narratif : **N1 — Existing Narrative Studio Audit vs Canonical Model**, appliqué ici au démonstrateur complet Selbrume<br>
Lot mécanique transverse : **FG-000 — baseline audit**, limité à ce périmètre narratif ; aucun statut de roadmap n'a été modifié<br>
Branche et révision observées : `main`, `f93b70ad12a1930e332bef6c4eebcc10026690dc`

## 1. Verdict exécutif

### Réponse courte

| Objet évalué | Avancement estimé | Verdict |
|---|---:|---|
| Narrative Studio face à la vision canonique | **50 %** | `PARTIAL` |
| Capacités moteur/runtime utiles à Selbrume | **62 %** | `PARTIAL` |
| Démonstrateur Selbrume complet, du démarrage à l'épilogue | **50 % ± 5 points** | **non prêt / gate `FAIL`** |

Si un seul nombre doit être retenu, **Selbrume est à environ 50 % de sa réalisation fonctionnelle**. Ce pourcentage ne signifie pas que la moitié des fichiers manque : beaucoup de contenu est déjà déclaré. Il signifie que la moitié environ de la chaîne **auteur no-code → donnée persistée → déclenchement réel → interaction jouée → conséquence sauvegardée → validation de campagne** est démontrée.

Le socle est substantiel : modèles narratifs, Facts, Story Steps, Event V2, Scenes graphées, dialogues Yarn affichables, combats trainer/wild, World Rules simples et sauvegarde générique existent. Le démonstrateur n'est pourtant pas livrable, car cinq capacités critiques restent absentes ou non prouvées :

1. le choix de starter et le chemin « party déjà existante » ne sont pas un flux auteur/runtime complet ;
2. les choix Yarn ne produisent pas d'outcomes persistants utilisables par une Scene ;
3. les Scenes ne savent pas encore attribuer les récompenses nécessaires (Pokémon, objets, argent) par leur contrat canonique ;
4. les cinématiques Selbrume ne sont pas jouées visuellement dans le runtime ;
5. aucune preuve end-to-end ne parcourt réellement les 12 étapes principales, les 3 quêtes annexes, les combats, les choix et les sauvegardes jusqu'à l'épilogue.

La gate fraîche est en outre rouge : le contrat de hash du projet promu est périmé et deux tests d'intégration Event V2 du projet courant expirent.

## 2. Ce que signifie « démonstrateur Selbrume complet »

Cet audit évalue le démonstrateur complet décrit par `selbrume.md`, et non uniquement la Golden Slice Lysa. La cible comprend notamment :

- 9 maps canoniques décrites par la spécification ;
- 4 chapitres principaux et 12 étapes principales détaillées ;
- l'introduction de Maël, avec les variantes starter/party existante ;
- la panique au port, le choix de ton, Lysa, puis la convergence victoire/défaite ;
- Mado, les trois indices, Soline et l'ouverture du passage ;
- le phare, deux gardiens, la confrontation finale et l'épilogue ;
- 3 quêtes annexes : cristaux de sel, Goélise et cabane du gardien ;
- des choix, récompenses, Facts, World Rules, combats et sauvegardes cohérents sur une session annoncée de 2 à 3 heures.

La spécification Narrative Studio cible 11 surfaces produit : Overview, Storylines Board, Storyline Graph, Scenes Library, Scene Builder, Cinematics Library, Cinematic Builder V2, Map Events View, Event Builder, Facts/World Rules et Validator.

## 3. Méthode et prudence sur les pourcentages

Chaque capacité a été notée selon cinq niveaux :

- `0` : absente ;
- `0,25` : structure ou prototype sans boucle fonctionnelle ;
- `0,50` : partielle, utilisable dans certains cas ;
- `0,75` : fonctionnelle mais incomplète ou insuffisamment prouvée ;
- `1` : complète et couverte par une preuve fraîche représentative.

Une moyenne ne peut pas rendre un démonstrateur « prêt » si une gate critique est rouge. Les trois pourcentages répondent à des questions différentes : maturité de l'outil auteur, capacité technique du moteur et fermeture réelle du contenu Selbrume. L'incertitude de ±5 points vient du worktree concurrent, de l'absence de walkthrough manuel complet et de plusieurs ambiguïtés dans les spécifications.

### 3.1 Score Narrative Studio

| Domaine | Poids | Niveau | Points | Lecture |
|---|---:|---:|---:|---|
| Shell et navigation unifiée | 10 | 0,75 | 7,5 | navigation spécialisée présente, mais encore en convergence |
| Overview | 8 | 0,50 | 4 | utile, mais encore lié en partie au modèle legacy Scenario |
| Storylines Board et Graph | 15 | 0,50 | 7,5 | structure auteur présente ; branches/conditions/outcomes incomplets |
| Scenes Library et Builder | 15 | 0,50 | 7,5 | graphes, références et diagnostics solides ; authoring des conséquences incomplet |
| Event Builder V2 et Map Events | 15 | 0,50 | 7,5 | quatre sources runtime ; vue cartographique consolidée et actions avancées absentes |
| Dialogues Yarn | 10 | 0,50 | 5 | CRUD, fichiers et lecture ; pas de liaison choix → outcome |
| Facts et World Rules | 10 | 0,75 | 7,5 | bonne base booléenne ; effets environnementaux trop limités |
| Cinematics | 12 | 0,25 | 3 | authoring avancé visible ; playback production non visuel |
| Validator produit | 5 | 0,25 | 1,25 | diagnostics locaux, pas de route ni de gate globale de campagne |
| **Total brut** | **100** |  | **50,75** | **arrondi prudent : 50 %** |

### 3.2 Score des capacités moteur/runtime

| Domaine | Poids | Points acquis | Motif principal |
|---|---:|---:|---|
| Contrats, JSON et sérialisation | 15 | 13 | modèles structurés et validations nombreuses |
| Event V2 et exécution de Scenes | 20 | 14 | boucle solide en fixture ; deux intégrations projet courant rouges |
| Dialogue/Yarn | 10 | 5 | affichage, options et jumps ; aucun outcome public/persisté |
| Cinématiques | 10 | 2 | résolution/attente seulement, sans playback visuel production |
| Combats et rencontres | 15 | 12 | trainer/wild, write-back et persistance ; parcours Selbrume complet non joué |
| État, sauvegarde et World Rules | 15 | 11 | socle générique fort ; campagne/mid-quest non prouvée |
| Nouvelle partie et récompenses | 10 | 3 | mutations génériques existantes, sans boucle canonique Narrative Studio |
| Validation end-to-end | 5 | 2 | diagnostics ciblés, pas de preuve campagne |
| **Total** | **100** | **62** | **capacité moteur partielle** |

### 3.3 Score du démonstrateur complet

| Résultat attendu | Poids | Points acquis | État |
|---|---:|---:|---|
| Contenu structurel et raccords déclarés | 15 | 12 | inventaire riche, encore `draft` et volatil |
| Ouverture, Maël et starter | 10 | 4 | chemin party existante semé ; starter bloqué |
| Trame principale jusqu'à l'épilogue | 30 | 15 | Scenes présentes, pas de parcours réel complet |
| Combats, boss et récompenses | 15 | 7 | moteurs présents, intégration/récompenses incomplètes |
| Trois quêtes annexes | 10 | 3 | structure déclarée, choix/récompenses non fermés |
| Sauvegarde de la progression | 10 | 6 | round-trips génériques, pas de campagne longue prouvée |
| Authoring no-code du contenu | 4 | 2 | plusieurs surfaces, persistance fragmentée |
| Validator Selbrume dérivé du projet | 4 | 1 | absent comme gate globale |
| Walkthrough end-to-end réel | 2 | 0 | aucune preuve du démarrage à l'épilogue |
| **Total** | **100** | **50** | **non prêt** |

## 4. Audit initial et état du dépôt

Au début de l'audit :

- branche `main`, HEAD `f93b70ad12a1930e332bef6c4eebcc10026690dc` ;
- 204 entrées dans `git status --short --untracked-files=all` ;
- 63 fichiers modifiés, 3 supprimés et 138 non suivis ;
- empreinte SHA-256 du porcelain initial : `c85a6a1960d6090b9982ebc48bf709c75596ae20f9e7a6b49cf7ce1e651fc2ae` ;
- les changements préexistants couvrent notamment `packages/map_editor`, `reports/` et `selbrume/`.

L'audit n'a pas tenté de nettoyer, restaurer, indexer ou committer ce worktree.

### 4.1 Mutation concurrente du contenu Selbrume

`selbrume/project.json` a été modifié à plusieurs reprises par un travail concurrent pendant l'audit. Les lectures ont notamment vu les empreintes `949f08f1…`, puis `f22c2bf0…`, avec augmentation de 28 à 30 Scenes et de 25 à 27 Events V2. Le point de coupe utilisé pour les inventaires finaux de ce rapport est :

- SHA-256 : `f22c2bf0b8b935a781c4e1c70db83d56ed956583118e3ea2d3427bca7f851141` ;
- date fichier : `2026-07-18T12:15:22+0200` ;
- taille : `1 453 954` octets ;
- deux lectures espacées de trois secondes ont donné la même empreinte.

Ce point de coupe est une photographie, pas une baseline promue. Les pourcentages portent d'abord sur les capacités du moteur et restent valables même si le contenu continue d'évoluer.

## 5. Inventaire du snapshot Selbrume observé

| Élément | Quantité observée | Commentaire |
|---|---:|---|
| Maps dans le manifeste | 10 | la spécification canonique en énumère 9 ; l'écart doit être expliqué, pas forcément supprimé |
| Storylines | 4 | toutes au statut `draft` |
| Chapitres | 7 | 4 principaux + chapitres de quêtes annexes |
| Story Steps | 26 | 37 liens Step → Scene |
| Events V2 | 27 | 9 `entityInteract`, 16 `triggerEnter`, 2 `outcomeReceived` ; tous `oneShot` |
| Scenes | 30 | 184 nœuds et 154 arêtes |
| Nœuds d'action | 70 | 42 `setFact`, 28 `completeStoryStep` |
| Facts | 46 | booléens |
| World Rules | 6 | essentiellement visibilité et override de dialogue |
| Cinematics | 16 | 15 timelines Selbrume réduites à un unique `wait` ; 1 prototype non Selbrume plus riche |
| Dialogues déclarés | 12 | tous avec `declaredOutcomes: []` |
| Trainers | 5 | Lysa, deux gardiens et confrontation finale inclus dans les graphes observés |
| Encounter tables | 1 | couverture faible pour une campagne de 2–3 h |
| Scripts | 0 | le flux canonique repose sur Event V2/Scenes |

La structure est nettement plus avancée que le niveau de preuve runtime. Cinq Facts n'ont pas de producteur Scene : `fact_test`, hors périmètre, et les quatre Facts fonctionnels suivants :

- `fact_starter_received`, faux par défaut : blocage du chemin starter A ;
- `fact_player_started_with_existing_pokemon`, **vrai par défaut** : configuration B déjà résolue, pas un blocage autonome ;
- `fact_goelise_object_returned`, faux par défaut : aucun outcome Yarn ne le produit ;
- `fact_goelise_object_kept`, faux par défaut : aucun outcome Yarn ne le produit.

Les blocages non résolus sont donc le chemin starter A et les deux résultats du choix Goélise. Une simulation d'atteignabilité optimiste — sources supposées activables, victoires de combat accordées et sans jouer les overlays — atteint **26 Events sur 27**. Le seul Event restant bloqué est le retour au pêcheur, qui exige `fact_goelise_object_returned = true`. Cette simulation n'est pas un walkthrough.

Le manifeste documente lui-même les limites actuelles :

- `selbrume.activeStarterConfiguration = existingPokemon` ;
- `selbrume.starterChoiceStatus = blocked_missing_give_pokemon_consequence` ;
- `selbrume.dialogueChoicePersistenceStatus = blocked_missing_yarn_outcome_binding` ;
- `selbrume.sideQuestRewardStatus = authored_narratively_runtime_reward_pending` ;
- `selbrume.cinematicStatus = semantic_runtime_v1`.

## 6. Ce qui va bien

### 6.1 Architecture et contrats

- `map_core` possède des modèles explicites pour Storyline, Chapter, Story Step, Scene, Cinematic, Fact, World Rule et Event V2.
- Les frontières de packages sont globalement respectées : contrats dans `map_core`, mutations de progression dans `map_gameplay`, orchestration dans `map_runtime`, authoring dans `map_editor`.
- Les Scenes ont un graphe sérialisable avec nœuds start/end, dialogue Yarn, cinematic, battle, action et branches de combat.
- Les références croisées, graphes, Facts, World Rules et cinematics disposent de diagnostics ciblés bien testés.

### 6.2 Event V2 et Scenes runtime

- Les quatre sources nécessaires au slice existent : `mapEnter`, `triggerEnter`, `entityInteract` et `outcomeReceived`.
- La coordination Event V2 applique l'autorité de dispatch et la consommation automatique d'un Event `oneShot` après succès ; l'absence de nœud explicite `markEventConsumed` dans les Scenes n'est donc pas, à elle seule, une anomalie.
- Le runner de Scene sait suspendre l'exécution pendant dialogue, cinematic et battle, puis appliquer atomiquement les conséquences prises en charge.
- Les branches victoire/défaite de Lysa existent dans le snapshot courant et les deux Scenes post-combat complètent `step_rival_battle`.

### 6.3 Gameplay et persistance génériques

- Le moteur de combat sait préparer des rencontres trainer/wild, renvoyer victoire/défaite, écrire les PV, mettre à jour la party et enregistrer un trainer vaincu.
- Les mutations gameplay savent déjà donner un Pokémon, un objet ou de l'argent dans d'autres contrats legacy/génériques.
- La sauvegarde générique couvre party, PC/boxes, bag, argent, progression, Facts, Story Steps, Event V2 consommés et outbox.
- Des tests frais prouvent des slices Selbrume isolées : première interaction, capture, premier combat trainer et sauvegarde/rechargement.

### 6.4 Éditeur no-code

- Une navigation Narrative Studio spécialisée existe, avec Overview, Storylines, Scenes, Events, Cinematics, Dialogues, Facts et World Rules.
- Dialogues : création, import, renommage, suppression, dossiers et fichier Yarn réel sont couverts.
- Facts/World Rules : la base d'authoring est utilisable et les diagnostics sont solides.
- Cinematic Builder : les surfaces savent représenter acteurs, placements, mouvements, caméra, timeline et points de scène ; le problème est désormais surtout le playback runtime et la vraie densité des timelines Selbrume.
- Event Builder V2 permet de choisir une source, des conditions, une Scene, une politique de réutilisation et une priorité.

## 7. Ce qui ne va pas ou reste incomplet

### 7.1 Blocage P0 — choix Yarn sans conséquence exploitable

Le runtime peut afficher des options et suivre des jumps Yarn, mais son contrat public n'expose pas d'outcome de dialogue. `packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart:343` le dit explicitement. Le test `scene_dialogue_runtime_awaitable_adapter_test.dart` vérifie même que l'adaptateur n'invente pas d'outcome.

Conséquences pour Selbrume :

- le ton `confident` / `hesitant` / `aggressive` face à Lysa ne peut pas alimenter proprement une branche ;
- le choix du port ne peut pas durablement modifier la foule ou les dialogues ;
- accepter/refuser la quête de Mado n'est pas raccordé ;
- rendre/garder l'objet du Goélise ne produit aucun Fact ;
- les branches `branchByOutcome` sont modélisées, mais l'UI les désactive avec `mapping futur requis` dans `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart:1501`.

La convergence post-combat de Lysa n'utilise pas `branchByOutcome` : elle repose sur deux Events V2 `outcomeReceived`, vers `scene_rival_after_win` et `scene_rival_after_loss`. C'est un raccord valide pour les outcomes de combat. En revanche, `branchByOutcome` reste réellement inutilisable : les diagnostics le marquent unsupported dans `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart:284-287` et le plan builder runtime le rejette dans `packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart:42` et `:137`.

### 7.2 Blocage P0 — conséquences Narrative Scene trop étroites

Le contrat canonique `SceneConsequence` ne propose que :

- `setFact` ;
- `markEventConsumed` ;
- `completeStoryStep`.

Il est défini dans `packages/map_core/lib/src/models/scene_consequence.dart:3-27` et exécuté dans `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart:52-61`.

Les mutations `givePokemon`, give item et money existent ailleurs, mais ne sont pas authorables comme conséquences de Scene. Cela bloque : starter, récompenses de Mado, récompenses de quêtes annexes, objets trouvés/rendus, argent et récompense finale. Ajouter seulement le contenu ne contourne pas ce manque de capacité produit.

### 7.3 Blocage P0 — nouvelle partie et starter

Le builder de nouvelle partie peut construire un état valide, mais le starter des tests est injecté directement par une mutation. Il n'existe pas de boucle complète : détection party vide → choix guidé → attribution → confirmation → Fact → activation de l'étape suivante. Le snapshot actuel choisit explicitement la configuration B « Pokémon déjà présent » et marque la configuration starter comme bloquée.

Pour respecter `selbrume.md`, les deux chemins doivent converger vers le même contrat de progression et être sauvegardables.

### 7.4 Blocage P0 — projet courant non vert en intégration

Deux problèmes frais empêchent tout verdict READY :

- le test J5 attend le hash `8689d1d9736b543863e40806c1640a76dc8b395a928313f529c0b0384d455167`, alors que le snapshot courant vaut `f22c2bf0…` ;
- `selbrume_event_v2_three_source_integration_test.dart` finit à `4 PASS / 2 FAIL` : deux cas projet promu expirent après l'entrée dans des Scenes désormais awaitables, alors que les variantes fixture passent.

Les logs prouvent au moins pour l'entrée du port que la source Event est résolue, `scene_port_entry` est lancée, Yarn est parsé et l'overlay de dialogue s'ouvre ; le harness attend ensuite la consommation terminale sans avancer le nouveau dialogue/cinematic awaitable. La gate est bien rouge, mais ce résultat ne prouve pas un défaut de résolution de la source Event. Le hash signale de son côté une baseline de promotion périmée, pas un défaut moteur. Il faut réconcilier baseline et harness, puis terminer les overlays et prouver la consommation `oneShot`.

### 7.5 Blocage P1 — cinématiques sémantiques mais non visuelles

`PlayableMapGame` instancie `SceneCinematicRuntimeNoVisualPlayer` dans `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:7460`. Ce player résout la timeline et attend sa durée, mais ne joue ni mouvement d'acteur, ni caméra, ni fade, ni emote, ni son, ni FX dans le jeu.

Le contenu confirme le problème : les 15 cinematics Selbrume sont des placeholders d'un seul `wait`. Seul `cinematic_uwu`, prototype hors campagne canonique, contient une timeline riche. Les IDs existent, mais l'expérience narrative voulue n'existe pas encore à l'écran.

### 7.6 Blocage P1 — World Rules insuffisantes pour les transformations du monde

Les sources couvrent Fact, Story Step complété et Event consommé. Les cibles/effets couvrent surtout visibilité d'entité, override de dialogue et activation d'Event. Cela convient pour masquer Lysa ou changer une réplique, mais pas pour :

- ouvrir réellement un passage ou une porte ;
- changer collision/pathfinding ;
- activer/désactiver un objet de carte complexe ;
- changer ambiance, météo, brouillard ou tiles ;
- matérialiser la résolution du phare.

Pour Selbrume, l'ouverture du Passage des Dames et la dissipation de la brume ont besoin d'effets environnementaux de production, pas seulement de Facts.

### 7.7 Blocage P1 — Validator non global

Le Validator est intentionnellement absent de la navigation produit, documenté dans `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_destination.dart:4`. Les diagnostics actuels sont utiles mais locaux.

La gate Selbrume doit dériver du projet, sans booléens injectés, au minimum :

- atteignabilité des Story Steps et des 27 Events ;
- références map/entity/trigger/dialogue/cinematic/trainer ;
- production et consommation des Facts ;
- fermeture des outcomes Yarn et battle ;
- présence des conséquences de récompense ;
- convergence des branches ;
- couverture de checkpoints save/load ;
- absence de Scene orpheline ou de contenu `draft` bloquant.

Le test beta actuel reçoit notamment `hasSaveLoadSupport: true` comme information externe : son PASS ne démontre donc pas le save de la campagne.

### 7.8 Fidélité de la confrontation finale

Le flow générique de static encounter existe surtout via le contrat `Scenario` legacy et ses tests. Dans le contenu Selbrume courant, `scene_final_pokemon` lance au contraire un combat `trainer` vers `trainer_boss_phare_pokemon`. Cela permet une victoire/défaite et ferme la branche victoire, mais ne prouve pas une vraie rencontre Pokémon statique avec politique de capture, consommation, réapparition ou apaisement propre au canon.

Ce choix peut être accepté comme simplification MVP, mais il doit être explicite. Sinon, le moteur et l'éditeur doivent fermer le contrat static encounter Event V2/Scene et ses conséquences.

### 7.9 Dette produit de l'éditeur

- Overview lit encore une vision legacy `Scenario/globalStory` tandis que Storylines repose sur `StorylineAsset`.
- Storyline Graph visualise surtout la structure ; les conditions et outcomes ne sont pas un langage auteur complet.
- Il n'existe pas de Map Events View consolidée montrant, sur une carte, tous les événements et leur état de raccordement.
- Event Builder V2 ne porte pas directement les récompenses, changements de monde, activation d'étape, timer ou orchestration multi-actions.
- Les Facts sont booléens ; aucun compteur/quantité n'est prévu pour les collectes sans multiplier les Facts.
- La persistance éditeur reste fragmentée : dialogues et Event V2 ont des chemins disque plus affirmés que plusieurs autres surfaces du manifeste.

## 8. Écarts de contenu et ambiguïtés des spécifications

Même avec les capacités moteur complétées, les documents demandent une passe de normalisation :

- `step_unlock_passage` est cité mais n'a pas de fiche détaillée et chevauche `step_report_to_soline` ;
- plusieurs Steps n'explicitent pas leur condition d'activation ou de complétion ;
- `scene_starter_choice` n'est pas défini complètement dans la spécification ;
- plusieurs références Yarn sont citées sans fiche de dialogue correspondante ;
- l'outcome `aggressive` de Lysa n'a pas de traitement canonique clair ;
- Mado peut produire `refuse_for_now`, mais le flux décrit déverrouille tout de même la quête ;
- le chemin « Pokémon déjà existant » ne décrit pas clairement l'activation de l'aller au port ;
- l'activation de la confrontation finale est incomplète dans le document ;
- la politique après défaite du boss n'est pas tranchée ;
- les équipes, récompenses, starters et timelines cinématiques sont seulement partiellement spécifiés ;
- le contrat de sauvegarde ne définit pas les checkpoints et invariants de round-trip attendus ;
- la cible 2–3 h de Selbrume est plus large que la Golden Slice générique 30–60 minutes de la roadmap.

Le snapshot courant fait des choix raisonnables, par exemple une configuration B « party existante » et une défaite du boss qui ne résout pas la brume, mais ces choix doivent devenir des décisions produit canoniques, pas seulement des métadonnées de seed.

## 9. Matrice de capacité par package

| Package | Verdict | Capacité présente | Manque déterminant pour Selbrume |
|---|---|---|---|
| `map_core` | `PARTIAL` | modèles, JSON, graphes, diagnostics | outcomes Yarn publics, conséquences de récompense, World Rules environnementales, validator global |
| `map_gameplay` | `PARTIAL` | Facts, étapes, party/bag/PC, mutations, save state | orchestration de starter et récompenses depuis le contrat narratif |
| `map_battle` | `PARTIAL` à fort | moteur de combat générique | preuve des combats Lysa/gardiens/boss joués, progression et récompenses de campagne |
| `map_runtime` | `PARTIAL` | Event V2, Scene runner, dialogue, battle handoff, sauvegarde | outcomes Yarn, playback cinematic visuel, deux intégrations projet courant rouges |
| `map_editor` | `PARTIAL` | majorité des surfaces auteur et diagnostics ciblés | fermeture no-code des branches/conséquences, Map Events, Validator, persistance homogène |
| host jouable | `PARTIAL` | fixtures et slices ciblées | vrai walkthrough du projet promu, sans callbacks simulés |

## 10. Passe Tests — verdict strict `FAIL`

Les tests prouvent des briques solides, mais pas Selbrume de bout en bout.

| Exigence | Prouvé | Non prouvé ou rouge |
|---|---|---|
| Projet promu | chargement et assertions riches prévues | hash J5 périmé, test arrêté avant les assertions runtime |
| Event V2 | fixtures Lysa/indice/port vertes | 2 timeouts sur le projet courant |
| Nouvelle partie | état, party/bag et round-trip | starter ajouté directement, aucun choix runtime |
| Scene Lysa | intents dialogue/cinematic/battle et outcomes simulés | choix Yarn, cinematic et combat joué non prouvés |
| Combat trainer | write-back, progression, argent, save | victoire contrôlée, pas une partie Lysa jouée par input |
| Sauvegarde | round-trips mémoire/disque génériques | aucun parcours mid-quête/choix/annexe complet |
| Validator | diagnostics graph/références et prérequis génériques | pas d'atteignabilité globale ni de preuve save dérivée |
| Campagne | test courant de 4 Scenes avec 2 cas verts | appels directs et callbacks simulés ; rival, indices, quêtes et traversal sautés |

Angles morts de preuve :

- aucun test ne réalise les 12 étapes dans l'ordre depuis une vraie nouvelle partie ;
- aucun test ne ferme les trois quêtes annexes et leurs récompenses ;
- aucun outcome Yarn réel n'alimente une branche de Scene ;
- aucun playback cinematic visuel n'est branché ;
- aucun combat Lysa n'est joué via overlay/input jusqu'au résultat ;
- aucun save/reload n'est exécuté au milieu des indices, cristaux, choix Lysa ou boss ;
- aucun validator ne prouve l'atteignabilité de la campagne entière.

## 11. Commandes et résultats frais

### 11.1 Inventaire et contrôle du snapshot

```bash
git status --short --untracked-files=all
git rev-parse --abbrev-ref HEAD
git rev-parse HEAD
shasum -a 256 selbrume/project.json
stat -f '%Sm|%z|%i' -t '%Y-%m-%dT%H:%M:%S%z' selbrume/project.json
jq '{maps:(.maps|length), dialogues:(.dialogues|length), scripts:(.scripts|length), scenarios:(.scenarios|length), cinematics:(.cinematics|length), facts:(.facts|length), worldRules:(.worldRules|length), scenes:(.scenes|length), storylines:(.storylines|length), trainers:(.trainers|length), characters:(.characters|length), encounterTables:(.encounterTables|length)}' selbrume/project.json
jq '{events:(.eventRegistry.records|length), eventSourceKinds:([.eventRegistry.records[].definition.source.kind]|group_by(.)|map({kind:.[0],count:length})), oneShot:([.eventRegistry.records[]|select(.definition.reusePolicy=="oneShot")]|length)}' selbrume/project.json
jq '{storylines:(.storylines|length), chapters:([.storylines[].chapters[]?]|length), steps:([.storylines[].chapters[]?.steps[]?]|length), stepSceneLinks:([.storylines[].chapters[]?.steps[]?.sceneLinkIds[]?]|length), statuses:([.storylines[].status]|group_by(.)|map({status:.[0],count:length}))}' selbrume/project.json
jq '{actionKinds:([.scenes[].graph.nodes[]?.payload.consequence?.kind]|group_by(.)|map({kind:.[0],count:length})), nodeKinds:([.scenes[].graph.nodes[]?.kind]|group_by(.)|map({kind:.[0],count:length})), graphNodeCount:([.scenes[].graph.nodes[]?]|length), graphEdgeCount:([.scenes[].graph.edges[]?]|length), sceneOutcomeCount:([.scenes[].declaredOutcomes[]?]|length)}' selbrume/project.json
jq -r '[.scenes[].graph.nodes[]? | select(.payload.kind=="action") | .payload.consequence | select(.kind=="setFact") | .factId] | unique[]' selbrume/project.json
```

Résultat utile : branche/HEAD ci-dessus ; snapshot `f22c2bf0…` stable sur deux lectures de trois secondes ; inventaire donné en section 5.

### 11.2 Diagnostics core ciblés

Depuis `packages/map_core` :

```bash
dart test test/golden_slice_readiness_test.dart test/scene_diagnostics_test.dart test/world_rule_diagnostics_test.dart test/cinematic_diagnostics_test.dart test/narrative_validator_test.dart
```

Résultat : **exit 0, 110/110 tests passés**.

### 11.3 Éditeur ciblé

Depuis `packages/map_editor` :

```bash
flutter test test/ui/canvas/narrative_studio_destination_test.dart test/features/narrative/application/overview/narrative_overview_read_model_test.dart test/storylines_current_global_story_characterization_test.dart test/scenes_workspace_shell_test.dart test/narrative_event_builder_v2_use_case_test.dart test/dialogue_disk_hierarchy_v13_test.dart test/facts_world_rules_manager_test.dart test/cinematics_library_workspace_test.dart
```

Résultat : **exit 0, `+131: All tests passed!`**. La résolution des dépendances de ce run a actualisé `packages/map_editor/pubspec.lock`, qui était déjà modifié au début de l'audit ; ce side effect est documenté en section 16.

### 11.4 Slices runtime P6

Depuis `packages/map_runtime` :

```bash
flutter test test/p6_selbrume_first_narrative_interaction_test.dart test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart test/p6_selbrume_first_trainer_battle_golden_slice_test.dart test/p6_selbrume_save_load_golden_slice_test.dart
```

Résultat : **exit 0, 4/4 tests passés**.

### 11.5 Projet promu et campagne simulée sur le snapshot final

Depuis `examples/playable_runtime_host` :

```bash
flutter test --reporter=compact test/selbrume_event_v2_promoted_project_test.dart test/selbrume_canonical_narrative_campaign_test.dart
```

Résultat : **exit 1, 2 passés / 1 échec**. L'échec est le hash J5 : attendu `8689d1…`, obtenu `f22c2bf…`. Les deux tests de campagne passent, mais appellent directement quatre Scenes et simulent dialogue/cinematic/battle ; ils ne constituent pas un E2E jouable.

### 11.6 Sources Event V2 par hooks de production

Depuis `packages/map_runtime` :

```bash
flutter test --reporter=compact test/selbrume_event_v2_three_source_integration_test.dart
```

Résultat : **exit 1, 4 passés / 2 échecs**. Les deux cas projet promu expirent après dispatch dans les nouvelles opérations awaitables ; les variantes fixture passent. Les logs du port montrent la Scene résolue et le dialogue ouvert avant le timeout : la gate/harness est obsolète, sans démontrer à elle seule une panne de résolution Event V2.

### 11.7 Vérifications non lancées

- pas de suite complète de chaque package : l'audit privilégie les gates narratives ciblées et le worktree est très actif ;
- pas de `dart analyze` / `flutter analyze` global : aucune modification de code n'a été réalisée, et une analyse verte ne prouverait pas le walkthrough ;
- pas de build release : hors du besoin « état des capacités » et non probant pour la campagne ;
- pas de walkthrough GUI manuel de 2–3 h : c'est précisément la preuve manquante à construire.

## 12. Verdict des sub-agents / passes indépendantes

| Passe | Verdict | Conclusion |
|---|---|---|
| Audit spécification | `PASS` pour l'extraction, `PARTIAL` pour la fermeture | cible canonique inventoriée ; contradictions et fiches manquantes empêchent un contrat totalement fermé |
| Audit éditeur/authoring | `PARTIAL` | Narrative Studio ≈ 50 %, fermeture auteur directe de Selbrume ≈ 40 % |
| Audit moteur/runtime | `PARTIAL` | capacité technique 60–65 %, démonstrateur end-to-end 45–55 % |
| Tests | **`FAIL` strict** | unités/slices nombreuses au vert, mais hash et deux intégrations fraîches au rouge ; aucun E2E complet |
| Build/Validation | `PARTIAL`, gate READY `FAIL` | diagnostics ciblés verts ; validator global, playback et campagne manquent |
| Critique finale | `PASS` sur la conclusion, `PARTIAL` sur le niveau de preuve | scores et verdict global confirmés ; corrections de précision intégrées ; aucune conclusion READY |

## 13. Lots roadmap concernés — proposition de statut, sans modification

L'audit ne propose **aucun lot `DONE`**. Les statuts ci-dessous sont des recommandations à confirmer par une passe de clôture dédiée :

| Lots | Statut proposé | Motif |
|---|---|---|
| `FG-000` | `PARTIAL` | baseline narrative complète, pas audit repo-wide de toute la mécanique |
| `FG-010`, `FG-011`, `FG-014`, `FG-016` | `PARTIAL` | nouvelle partie/party/save présents, flux starter et campagne non fermés |
| `FG-012`, `FG-013`, `FG-103` | `BLOCKED` ou `TODO` | modèle/flow starter et Gift Pokémon non fermés depuis Narrative Studio |
| `FG-020`, `FG-021`, `FG-024`, `FG-025` | `PARTIAL` | party/PC/bag génériques, intégration narrative/reward incomplète |
| `FG-040` à `FG-052` | `PARTIAL` à absent selon le sous-lot | persistance combat présente ; PP/status/XP/level/moves/évolution/reward presentation et certains cas UX ne sont pas tous prouvés pour Selbrume |
| `FG-060`, `FG-064`, `FG-067`, `FG-068` | `PARTIAL` à `TODO` | registry d'items, key-item gates, pickup et hidden item ne sont pas fermés via les conséquences Narrative Scene ni prouvés en campagne |
| `FG-080` à `FG-094` | `PARTIAL` à `TODO` selon le sous-lot | commandes, conditions, executor, Action Builder et templates existent à des degrés différents ; choix, récompenses et world changes manquent |
| `FG-100`, `FG-102`, `FG-107`, `FG-108` | `PARTIAL` à `TODO` | audit/validation d'encounters partiels ; static encounter surtout legacy, consommation et authoring Selbrume non prouvés |
| `FG-140`, `FG-141`, `FG-145`, `FG-146` | `PARTIAL` | trainer defeated, dialogue post-battle et follow-up rival existent partiellement ; le progression validator ne détecte pas encore la campagne impossible |
| `FG-147` | `TODO` à `PARTIAL` | aucun walkthrough complet automatisé et joué |
| `FG-163`, `FG-165` | `PARTIAL` | menus/handoff utiles, pas évalués comme boucle complète ici |
| `FG-180`, `FG-181` | `PARTIAL` | socle projet/maps riche, état concurrent et preuves d'usage incomplètes |
| `FG-182` | `BLOCKED` | contenu narratif canonique non entièrement exécutable |
| `FG-183` | `PARTIAL` | plusieurs matrices de tests existent, sans preuve globale verte |
| `FG-184`, `FG-185` | `TODO` | dashboard generator et release gate non prouvés par cet audit ; la gate fonctionnelle observée est rouge |

Le lot narratif **N1** est proposé comme livrable d'audit par le présent rapport, après intégration de la critique et du statut Git final ; aucun statut de roadmap n'est modifié. Le lot **N13 — Lysa Golden Slice** est avancé, mais ne doit pas être confondu avec la readiness du démonstrateur complet.

## 14. Ordre recommandé pour terminer Selbrume

### P0 — rendre la boucle narrative réellement fermable

1. Figer une baseline Selbrume promue et réconcilier le hash, les maps, les dialogues et le harness Event V2.
2. Corriger les deux timeouts du projet réel et garder les variantes fixture comme tests de caractérisation.
3. Définir un contrat Yarn `choice/outcome` qualifié, le persister et le rendre sélectionnable dans Scene Builder.
4. Étendre les conséquences de Scene : donner/retirer objet, donner Pokémon, argent, récompense idempotente, éventuellement warp/transition.
5. Implémenter les deux chemins Maël : starter si party vide et convergence avec party existante.
6. Fermer les choix Lysa, Mado et Goélise avec Facts, dialogues post-choix et récompenses.

### P1 — rendre l'expérience visible et cohérente dans le monde

7. Brancher un player cinematic visuel de production puis remplacer les 15 placeholders Selbrume par de vraies timelines.
8. Étendre les World Rules aux portes, collisions, passages, objets, brouillard/ambiance et état du phare.
9. Clarifier le boss : nature de la rencontre, défaite, retry, récompense et condition exacte de dissipation.

### P1/P2 — prouver le démonstrateur

10. Construire un Validator Selbrume dérivé uniquement du projet, accessible depuis Narrative Studio.
11. Ajouter un parcours E2E par checkpoints : new game, port/Lysa, trois indices, passage, phare, boss, épilogue, trois quêtes annexes.
12. À chaque checkpoint, sauver/recharger et vérifier idempotence des événements, récompenses et branches.
13. Faire un walkthrough manuel de la build cible, relever la durée, les blocages, les dialogues et les états du monde, puis seulement proposer les lots `DONE`.

## 15. Fichiers et zones inspectés

Principaux contrats/code :

- `packages/map_core/lib/src/models/scene_consequence.dart` ;
- `packages/map_core/lib/src/models/world_rule.dart` ;
- `packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart` ;
- `packages/map_core/lib/src/diagnostics/` ;
- `packages/map_gameplay/lib/src/game_state_mutations.dart` ;
- `packages/map_runtime/lib/src/application/scene_runtime/` ;
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` ;
- `packages/map_editor/lib/src/ui/canvas/narrative_studio/` ;
- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart` ;
- `packages/map_editor/lib/src/ui/canvas/events_v2/`.

Contenu et spécifications :

- `MVP Selbrume/narrative_studio.md` ;
- `MVP Selbrume/selbrume.md` ;
- `selbrume/project.json` ;
- `selbrume/maps/` ;
- `selbrume/dialogues/`.

Preuves historiques consultées sans les substituer aux runs frais :

- `reports/narrativeStudio/ns_studio_product_beta_readiness_audit.md` ;
- `reports/narrativeStudio/ns_studio_product_beta_readiness_evidence_pack.md` ;
- `reports/narrativeStudio/events/ns_event_34_runtime_handoff_smoke_editor_authored_scene_target_gate.md` ;
- `reports/narrativeStudio/events/ns_event_35_trigger_variants_runtime_handoff_lifecycle_semantics_gate.md` ;
- `reports/narrativeStudio/events/ns_event_v2_phase_j_selbrume_golden_slice_evidence_pack.md` ;
- plans/audits Scenes V1-137/V1-138 et rapports de fermeture Facts/World Rules associés.

Les preuves historiques portent parfois sur d'autres révisions, dont `2f683…`, et ne valent pas preuve fraîche pour le HEAD `f93b70…` et le snapshot Selbrume volatil courant.

## 16. Fichiers modifiés par cet audit

### Créé

- `reports/gameplay/fg_000_narrative_studio_selbrume_readiness_audit.md` — le présent rapport ; toutes ses lignes sont nouvelles et son contenu complet constitue l'artefact livré.

### Code et tests

- aucun fichier Dart modifié ;
- aucun test créé ou modifié par l'audit ;
- aucune roadmap modifiée ;
- aucune opération Git d'écriture effectuée.

### Side effect de validation sur un fichier déjà dirty

- `packages/map_editor/pubspec.lock` était déjà `M` dans l'état initial. La résolution déclenchée par le run éditeur a actualisé les zones suivantes dans le diff courant : `matcher 0.12.19 → 0.12.20`, `meta 1.18.0 → 1.19.0`, `test_api 0.7.11 → 0.7.12`, `vector_math 2.2.0 → 2.4.0`, avec leurs SHA. Il n'a pas été restauré, car l'état antérieur non committé appartient au worktree utilisateur et une restauration aurait été destructive.

Les autres changements visibles dans le worktree, y compris `selbrume/project.json`, les maps/dialogues, les fichiers Narrative Studio et les nouveaux tests/outils de seed, sont préexistants ou proviennent d'un travail concurrent. Ils ne sont pas revendiqués par cet audit.

### État Git final — résumé et extrait ciblé

```text
photographie : 2026-07-18T12:37:07+0200
222 entrées : 70 modifiées/autres, 3 supprimées, 149 non suivies
répartition : packages 74, selbrume 85, reports 61, examples 1, design-qa.md 1
empreinte SHA-256 du porcelain : a18980b744943dba7381f6553cdd33c678fa6f4369924a7093c3802bcfd0140e
 M packages/map_editor/pubspec.lock
 M selbrume/project.json
?? reports/gameplay/fg_000_narrative_studio_selbrume_readiness_audit.md
```

Le porcelain complet comporte 222 lignes et n'est pas recopié intégralement ici ; il est reproductible avec `git status --short --untracked-files=all`. Le résumé, l'empreinte et l'extrait ci-dessus constituent la photographie contrôlée. Toute évolution concurrente ultérieure ne doit pas être attribuée à l'audit.

## 17. Auto-critique et risques

1. **Snapshot volatil.** Le contenu Selbrume a changé pendant la lecture. L'inventaire est exact pour `f22c2bf0…`, pas garanti pour une révision ultérieure.
2. **Pas de walkthrough visuel complet.** L'audit inspecte contrats, contenu et tests, mais ne remplace pas une partie humaine de 2–3 h.
3. **Pourcentage de maturité, pas couverture.** Le 50 % est un score de fermeture fonctionnelle pondéré, avec ±5 points d'incertitude ; ce n'est ni un taux de lignes ni un nombre de tâches.
4. **Spécification contradictoire.** Certains écarts peuvent être résolus par une décision produit plutôt que par du code ; ils restent bloquants tant que la décision n'est pas canonique.
5. **Tests simulés.** Plusieurs « Golden Slices » appellent directement des Scenes ou contrôlent les outcomes ; ils surévalueraient la readiness si on les lisait comme des parcours joués.
6. **Vérification ciblée.** Les suites complètes, analyses statiques et builds n'ont pas été relancés ; le verdict ne prétend donc pas à une santé globale du monorepo.
7. **Risque de double système.** Tant que Scenario legacy et Storyline/Scene/Event V2 coexistent dans les surfaces produit, des auteurs peuvent configurer un état que le runtime ne consomme pas de la façon attendue.

## 18. Conclusion

Le Narrative Studio n'est plus un prototype vide : il dispose d'une vraie architecture auteur et d'un runtime narratif crédible. Le problème principal n'est plus « pouvoir stocker une histoire », mais **fermer les interactions qui donnent du sens à cette histoire** : choix, conséquences, récompenses, transformations du monde, cinématiques visibles et validation end-to-end.

Le démonstrateur complet Selbrume doit donc rester **`PARTIAL`, environ 50 %**, et **ne peut pas être proposé `DONE` ou READY** sur les preuves actuelles. Le chemin le plus court n'est pas d'ajouter encore des IDs ou des Scenes ; il est de terminer les contrats transverses P0, de stabiliser le projet promu, puis de prouver une campagne réellement jouée et sauvegardée.
