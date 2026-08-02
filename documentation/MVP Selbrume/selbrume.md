Oui. On va figer **Selbrume** comme **scénario de référence canonique** pour construire le Narrative Studio.
L’idée n’est pas juste d’avoir une jolie histoire : c’est d’avoir un **jeu miniature complet**, assez simple pour être faisable, mais assez riche pour tester tous les systèmes narratifs de PokeMap.

# Selbrume — Mini scénario complet pour PokeMap

## 0. Résumé ultra court

**Titre provisoire :**
**Les Brumes de Selbrume**

**Pitch :**
Sur l’île de Selbrume, une brume étrange se lève chaque soir autour du vieux phare. Les pêcheurs n’osent plus sortir, les Pokémon sauvages deviennent nerveux, et une lumière anormale clignote parfois au sommet du phare abandonné. Le joueur doit aider les habitants à comprendre ce qui perturbe l’île, traverser les marais, débloquer le passage vers le phare, puis apaiser le Pokémon responsable du phénomène.

**Durée cible :** 2 à 3 heures.
**Structure :** une île, une histoire principale, trois quêtes annexes, quelques combats, une mini-enquête, un donjon final court.
**Objectif produit :** servir de golden slice narratif pour tester le futur Narrative Studio.

---

# 1. Intention du scénario

Selbrume doit servir à tester :

| Besoin Narrative Studio     | Présent dans Selbrume |
| --------------------------- | --------------------- |
| Histoire principale         | Oui                   |
| Chapitres                   | Oui                   |
| Story Steps                 | Oui                   |
| Quêtes annexes              | Oui                   |
| Events de map               | Oui                   |
| Dialogues Yarn avec choix   | Oui                   |
| Outcomes Yarn               | Oui                   |
| Scènes en graph             | Oui                   |
| Cinématiques linéaires      | Oui                   |
| Branches qui se rejoignent  | Oui                   |
| Conditions de disponibilité | Oui                   |
| Facts / flags cachés        | Oui                   |
| World Rules                 | Oui                   |
| Combats trainer             | Oui                   |
| Combat final                | Oui                   |
| Objets ramassables          | Oui                   |
| Récompenses                 | Oui                   |
| Validator                   | Oui                   |

Selbrume est volontairement petit, mais il doit couvrir **toute la grammaire narrative** de PokeMap.

Le scénario doit permettre de tester cette chaîne :

```text
Map Element
→ Event
→ Scene
→ Dialogue Yarn
→ Outcome
→ Cinematic
→ Battle
→ Fact
→ Story Step
→ World Rule
→ Validator
```

---

# 2. Ambiance générale

Selbrume est une île fictive inspirée de Noirmoutier, avec :

```text
village côtier
port de pêche
marais salants
bois de pins
passage submersible
vieux phare abandonné
brume marine
petites cabanes
digues
bateaux à quai
sentiers humides
lanternes dans la nuit
```

Le ton doit être :

```text
mystérieux
doux
local
humain
un peu mélancolique
pas apocalyptique
pas “sauver le monde”
```

Ce n’est pas une aventure avec une Team criminelle internationale qui veut invoquer le dieu du sel cosmique. On reste à taille humaine. Une île, ses habitants, un vieux phare, un Pokémon effrayé, et une brume qui perturbe tout.

---

# 3. Carte globale de l’île

## Zones principales

| ID                      | Nom                             | Rôle                                 |
| ----------------------- | ------------------------------- | ------------------------------------ |
| `map_bourg_selbrume`    | Bourg de Selbrume               | Village de départ                    |
| `map_port_brisants`     | Port des Brisants               | Premier conflit, pêcheurs, rival     |
| `map_bois_chaise_brume` | Bois de la Chaise-Brume         | Route naturelle, premiers dresseurs  |
| `map_marais_salants`    | Marais Salants                  | Enquête, indices, quête des cristaux |
| `map_passage_dames`     | Passage des Dames               | Route submersible vers le phare      |
| `map_phare_exterieur`   | Vieux Phare d’Écume — extérieur | Accès final                          |
| `map_phare_interieur`   | Vieux Phare d’Écume — intérieur | Donjon court                         |
| `map_sommet_phare`      | Sommet du phare                 | Combat / apaisement final            |
| `map_cabane_gardien`    | Cabane du gardien               | Quête annexe / lore / raccourci      |

---

# 4. Personnages principaux

## 4.1 Joueur

Le joueur est un jeune habitant ou une jeune habitante de Selbrume.

Important : le jeu doit permettre deux configurations.

### Configuration A — départ classique

```text
Le joueur commence sans Pokémon.
Il reçoit un starter au début.
```

### Configuration B — départ flexible

```text
Le joueur commence déjà avec un Pokémon.
Le choix du starter est alors sauté ou transformé en vérification.
```

C’est important pour PokeMap : le Narrative Studio ne doit pas forcer tous les jeux à commencer par un choix de starter.

---

## 4.2 Maël

**ID :** `npc_mael`
**Nom :** Maël
**Rôle :** garde-nature local / mentor
**Localisation :** Bourg de Selbrume

Maël est la personne qui comprend le mieux l’équilibre naturel de l’île. Il n’est pas professeur Pokémon au sens classique. Il est plutôt garde-nature, observateur, un peu scientifique de terrain.

Fonction narrative :

```text
donne la mission principale
peut donner le starter si nécessaire
explique les premiers signes de la brume
oriente le joueur vers le port
sert de point de retour si le joueur est perdu
```

---

## 4.3 Lysa

**ID :** `npc_lysa`
**Nom :** Lysa
**Rôle :** rival local / fille de pêcheur / protectrice du port
**Localisation :** Port des Brisants

Lysa n’est pas une ennemie. Elle est protectrice, impulsive, méfiante. Elle connaît l’île et n’aime pas que le joueur “joue au héros”.

Fonction narrative :

```text
premier combat important
test des branches victoire / défaite
dialogues alternatifs selon le ton du joueur
peut aider ou rester distante selon les outcomes
```

Elle est parfaite pour tester :

```text
combat trainer
dialogue Yarn avec choix
branches narratives
facts persistants
relations légères
story step completed
```

---

## 4.4 Mado

**ID :** `npc_mado`
**Nom :** Mado
**Rôle :** paludière des marais salants
**Localisation :** Marais Salants

Mado connaît les marais, les digues, les cristaux de sel, les vieux chemins.

Fonction narrative :

```text
donne la quête annexe “Les cristaux de sel”
aide à comprendre l’origine naturelle de la brume
fournit un indice sur l’ancien mécanisme du phare
```

---

## 4.5 Yvon

**ID :** `npc_yvon`
**Nom :** Yvon
**Rôle :** ancien gardien du phare
**Localisation :** près du Passage des Dames / Cabane du gardien

Yvon est bourru, nostalgique, pas très bavard. Il connaît l’histoire du phare mais ne veut pas trop en parler.

Fonction narrative :

```text
quête annexe de la cabane
donne du lore sur la lentille du phare
peut débloquer un raccourci
donne un indice optionnel pour comprendre le final
```

---

## 4.6 Capitaine Soline

**ID :** `npc_soline`
**Nom :** Soline
**Rôle :** responsable du port
**Localisation :** Port des Brisants

Elle gère les pêcheurs et décide quand le passage vers le phare peut être emprunté.

Fonction narrative :

```text
bloque l’accès au Passage des Dames au début
débloque l’accès quand le joueur a assez d’indices
explique le danger de la brume et de la marée
```

---

## 4.7 Le Pokémon du phare

**ID provisoire :** `boss_phare_pokemon`
**Espèce possible :** Lanturn, Motisma, Magnéti, ou fakemon local
**Rôle :** source involontaire de la brume

Pour un fangame Pokémon, Lanturn ou Motisma fonctionnent bien. Pour PokeMap en mode Pokémon-like générique, on peut le garder comme :

```text
Pokémon électrique / eau-électrique réfugié dans le phare
```

Il n’est pas méchant. Il est effrayé, coincé dans le mécanisme de la lentille, et son énergie amplifie la brume marine.

---

# 5. Histoire principale

## Storyline principale

```text
ID : story_main_brume_phare
Nom : La brume du phare
Type : Main Story
Durée cible : 2 à 3 heures
```

Résumé :

```text
Le joueur enquête sur une brume étrange qui perturbe Selbrume, découvre que le vieux phare amplifie involontairement l’énergie d’un Pokémon effrayé, puis l’apaise pour rétablir l’équilibre de l’île.
```

---

# 6. Découpage en chapitres

## Chapitre 1 — Le port

```text
ID : chapter_1_port
Nom : Le port
Rôle : introduction, mission, rival, premier branchement
```

Objectifs :

```text
présenter Selbrume
donner la mission
éventuellement donner le starter
envoyer le joueur au port
introduire Lysa
déclencher le premier combat
créer une première branche victoire/défaite
```

Steps :

```text
step_intro_selbrume
step_receive_mission
step_go_to_port
step_rival_battle
```

---

## Chapitre 2 — Les marais

```text
ID : chapter_2_marais
Nom : Les marais
Rôle : enquête, exploration, indices, quêtes annexes
```

Objectifs :

```text
débloquer la zone marais
trouver plusieurs indices
introduire Mado
rendre certaines quêtes annexes disponibles
préparer l’accès au phare
```

Steps :

```text
step_enter_marais
step_find_three_clues
step_report_to_soline
```

---

## Chapitre 3 — Le phare

```text
ID : chapter_3_phare
Nom : Le phare
Rôle : accès final, mini-donjon, résolution
```

Objectifs :

```text
débloquer le Passage des Dames
atteindre le phare
explorer l’intérieur
arriver au sommet
affronter ou apaiser le Pokémon du phare
```

Steps :

```text
step_unlock_passage
step_reach_lighthouse
step_climb_lighthouse
step_final_confrontation
```

---

## Chapitre 4 — Épilogue

```text
ID : chapter_4_epilogue
Nom : Épilogue
Rôle : retour au calme, conclusion, dialogues post-game
```

Objectifs :

```text
montrer que la brume s’est dissipée
changer les dialogues des PNJ
afficher une mini-cérémonie au port
débloquer éventuellement des quêtes post-game
```

Steps :

```text
step_return_to_port
step_main_story_completed
```

---

# 7. Story Steps détaillées

## Step 1 — Introduction à Selbrume

```text
ID : step_intro_selbrume
Nom : Introduction à Selbrume
Storyline : story_main_brume_phare
Chapter : chapter_1_port
```

État initial :

```text
Active dès le début du jeu
```

But :

```text
Le joueur découvre que quelque chose ne va pas sur l’île.
```

Events liés :

```text
event_mael_intro
event_player_house_exit
```

Complétion :

```text
Completed quand le joueur parle à Maël et accepte d’aider.
```

Facts produits :

```text
fact_mael_intro_done
fact_main_story_started
```

---

## Step 2 — Recevoir la mission

```text
ID : step_receive_mission
Nom : Recevoir la mission de Maël
```

Activation :

```text
Active quand step_intro_selbrume completed
```

Deux cas :

### Cas A — pas de starter

```text
Maël propose un choix de starter.
```

### Cas B — joueur a déjà un Pokémon

```text
Maël vérifie que le joueur est prêt et saute le choix starter.
```

Events liés :

```text
event_starter_choice
event_mael_mission_given
```

Facts possibles :

```text
fact_starter_received
fact_player_started_with_existing_pokemon
fact_mael_mission_given
```

Complétion :

```text
Completed quand le joueur peut partir vers le port.
```

---

## Step 3 — Aller au port

```text
ID : step_go_to_port
Nom : Aller au Port des Brisants
```

Activation :

```text
Active quand fact_mael_mission_given est vrai
```

Event clé :

```text
event_enter_port_alert
```

But :

```text
Le joueur arrive au port et constate que les pêcheurs sont inquiets.
```

Complétion :

```text
Completed quand la scène d’alerte du port est terminée.
```

Facts produits :

```text
fact_port_alert_seen
fact_port_crowd_panicked ou fact_port_crowd_reassured
```

---

## Step 4 — Combat rival

```text
ID : step_rival_battle
Nom : Affronter Lysa
```

Activation :

```text
Active après step_go_to_port completed
```

Event clé :

```text
event_rival_port_meet
```

Branches :

```text
Victoire contre Lysa
Défaite contre Lysa
```

Important : les deux branches peuvent rejoindre l’histoire principale. On ne bloque pas le joueur.

### Si victoire

Facts :

```text
fact_rival_port_defeated
fact_lysa_respects_player
```

Conséquences :

```text
Lysa accepte que le joueur enquête.
La quête annexe “Signal étrange” / “Goélise du port” peut devenir disponible.
```

### Si défaite

Facts :

```text
fact_rival_port_lost_once
fact_lysa_goes_ahead
```

Conséquences :

```text
Lysa se moque gentiment du joueur.
L’histoire continue quand même.
Certains dialogues futurs changent.
```

Complétion :

```text
Completed quand le combat a produit un outcome victory ou defeat.
```

---

## Step 5 — Entrer dans les marais

```text
ID : step_enter_marais
Nom : Entrer dans les Marais Salants
```

Activation :

```text
Active après step_rival_battle completed
```

Events liés :

```text
event_marais_entry
event_mado_first_talk
```

Facts :

```text
fact_marais_unlocked
fact_mado_met
```

---

## Step 6 — Trouver trois indices

```text
ID : step_find_three_clues
Nom : Trouver les indices de la brume
```

Activation :

```text
Active quand step_enter_marais completed
```

Indices :

```text
Indice 1 : morceau de verre poli
Indice 2 : traces électriques dans la vase
Indice 3 : vieux repère de lentille du phare
```

Events :

```text
event_clue_glass_found
event_clue_electric_tracks_found
event_clue_lighthouse_mark_found
```

Facts :

```text
fact_clue_glass_found
fact_clue_electric_tracks_found
fact_clue_lighthouse_mark_found
```

Complétion :

```text
Completed quand les trois facts d’indices sont vrais.
```

---

## Step 7 — Convaincre Soline

```text
ID : step_report_to_soline
Nom : Convaincre Soline d’ouvrir le passage
```

Activation :

```text
Active quand step_find_three_clues completed
```

Event :

```text
event_soline_unlock_passage
```

Conséquence :

```text
Le Passage des Dames devient accessible.
```

Facts :

```text
fact_passage_dames_unlocked
```

World Rule :

```text
Le PNJ bloqueur du passage disparaît ou laisse passer.
```

---

## Step 8 — Rejoindre le phare

```text
ID : step_reach_lighthouse
Nom : Rejoindre le Vieux Phare d’Écume
```

Activation :

```text
Active quand fact_passage_dames_unlocked est vrai
```

Events :

```text
event_enter_passage_dames
event_lighthouse_exterior_arrival
```

Facts :

```text
fact_lighthouse_reached
```

---

## Step 9 — Explorer le phare

```text
ID : step_climb_lighthouse
Nom : Explorer le phare
```

Activation :

```text
Active quand fact_lighthouse_reached est vrai
```

Contenu :

```text
mini-donjon court
quelques dresseurs ou habitants paniqués
objets
notes de l’ancien gardien
petits obstacles
```

Events :

```text
event_lighthouse_floor_1
event_lighthouse_old_note
event_lighthouse_top_access
```

Facts :

```text
fact_lighthouse_old_note_read
fact_lighthouse_top_unlocked
```

---

## Step 10 — Apaiser le Pokémon du phare

```text
ID : step_final_confrontation
Nom : Apaiser le Pokémon du phare
```

Activation :

```text
Active quand fact_lighthouse_top_unlocked est vrai
```

Events :

```text
event_final_pokemon_scene
event_final_battle_or_appease
```

Outcomes possibles :

```text
battle_victory
pokemon_appeased
pokemon_captured éventuellement plus tard
```

Facts :

```text
fact_lighthouse_pokemon_appeased
fact_mist_source_resolved
```

World Rules :

```text
La brume disparaît.
Les PNJ changent de dialogue.
Le port redevient actif.
```

---

## Step 11 — Retour au port

```text
ID : step_return_to_port
Nom : Retourner au port
```

Activation :

```text
Active après fact_mist_source_resolved
```

Scene :

```text
scene_ending_port
```

Facts :

```text
fact_ending_seen
```

---

## Step 12 — Fin de l’histoire principale

```text
ID : step_main_story_completed
Nom : La lumière revient sur Selbrume
```

Activation :

```text
Active après scene_ending_port terminée
```

Complétion :

```text
Completed immédiatement après l’épilogue
```

Facts :

```text
fact_main_story_completed
```

---

# 8. Quêtes annexes

# 8.1 Quête annexe — Les cristaux de sel

```text
ID : story_side_salt_crystals
Nom : Les cristaux de sel
Type : Side Quest
```

## Pitch

Mado a perdu trois cristaux de sel particuliers dans les marais. Ils réagissent à la brume et brillent légèrement la nuit. Elle demande au joueur de les retrouver.

## Disponibilité

```text
Disponible si :
- fact_marais_unlocked = true
- fact_mado_met = true
```

## Steps

```text
step_crystals_talk_to_mado
step_crystals_collect_three
step_crystals_return_to_mado
step_crystals_completed
```

## Events

```text
event_mado_crystals_start
event_pick_crystal_1
event_pick_crystal_2
event_pick_crystal_3
event_mado_crystals_return
```

## Facts

```text
fact_crystals_quest_started
fact_crystal_1_collected
fact_crystal_2_collected
fact_crystal_3_collected
fact_crystals_all_collected
fact_crystals_quest_completed
```

## World Rules

```text
Cristal 1 visible si fact_crystal_1_collected = false
Cristal 2 visible si fact_crystal_2_collected = false
Cristal 3 visible si fact_crystal_3_collected = false
Mado propose la récompense si les 3 cristaux sont collectés
```

## Récompense

```text
Super Potion
ou Sel Soin
ou argent
ou item de soin local
```

## Intérêt pour PokeMap

Cette quête teste :

```text
collecte multiple
compteur implicite
objets visibles / invisibles
quête annexe disponible sous condition
retour PNJ
récompense
validator de quête terminable
```

---

# 8.2 Quête annexe — Le Goélise du port

```text
ID : story_side_goelise_port
Nom : Le Goélise du port
Type : Side Quest
```

## Pitch

Un Goélise vole les repas des pêcheurs. Les pêcheurs pensent qu’il est juste pénible, mais en réalité son nid a été dérangé par la brume.

## Disponibilité

```text
Disponible si :
- step_rival_battle completed
```

Option :

```text
Si fact_port_crowd_reassured = true, les pêcheurs sont plus calmes.
Si fact_port_crowd_panicked = true, les dialogues sont plus agités.
```

## Steps

```text
step_goelise_talk_to_fisher
step_goelise_find_nest
step_goelise_choice
step_goelise_return
step_goelise_completed
```

## Events

```text
event_fisher_goelise_start
event_goelise_nest_found
event_goelise_choice
event_fisher_goelise_return
```

## Choix joueur

Le joueur trouve un objet brillant dans le nid.

Choix :

```text
Rendre l’objet aux pêcheurs
Garder l’objet
```

## Outcomes

### Rendre l’objet

Facts :

```text
fact_goelise_item_returned
fact_fisher_trust_player
```

Récompense :

```text
Baies
argent
réduction éventuelle dans une boutique
```

### Garder l’objet

Facts :

```text
fact_goelise_item_kept
fact_fisher_suspicious
```

Récompense :

```text
objet rare mineur
dialogue moins chaleureux
```

## World Rules

```text
Goélise cesse d’apparaître au port si quête terminée.
Pêcheurs changent de dialogue selon le choix.
```

## Intérêt pour PokeMap

Cette quête teste :

```text
choix moral léger
outcome Yarn ou Scene
facts différents selon choix
récompenses alternatives
dialogues persistants différents
```

---

# 8.3 Quête annexe — La cabane du phare

```text
ID : story_side_lighthouse_cabin
Nom : La cabane du phare
Type : Side Quest
```

## Pitch

Yvon, l’ancien gardien du phare, a fermé sa vieille cabane et ne retrouve plus la clé. La cabane contient un carnet qui explique l’histoire de la lentille du phare.

## Disponibilité

```text
Disponible si :
- fact_passage_dames_unlocked = true
```

ou plus tôt :

```text
Disponible si :
- fact_mado_met = true
```

selon le rythme voulu.

## Steps

```text
step_cabin_talk_to_yvon
step_cabin_find_key
step_cabin_open_door
step_cabin_read_journal
step_cabin_completed
```

## Events

```text
event_yvon_cabin_start
event_cabin_key_found
event_cabin_door_interact
event_cabin_journal_read
```

## Facts

```text
fact_cabin_quest_started
fact_cabin_key_obtained
fact_cabin_opened
fact_guardian_journal_read
fact_cabin_quest_completed
```

## World Rules

```text
Porte cabane utilisable si fact_cabin_key_obtained = true
Cabane fermée sinon
Carnet visible si fact_cabin_opened = true
Raccourci vers passage débloqué si fact_guardian_journal_read = true
```

## Récompense

```text
Lore sur le phare
objet rare
raccourci
meilleure compréhension du final
```

## Intérêt pour PokeMap

Cette quête teste :

```text
porte verrouillée
clé
condition d’interaction
lore optionnel
raccourci
world rule persistante
```

---

# 9. Facts principaux

## Facts de progression principale

```text
fact_main_story_started
fact_mael_intro_done
fact_starter_received
fact_player_started_with_existing_pokemon
fact_mael_mission_given
fact_port_alert_seen
fact_port_crowd_panicked
fact_port_crowd_reassured
fact_rival_port_defeated
fact_rival_port_lost_once
fact_lysa_respects_player
fact_lysa_goes_ahead
fact_marais_unlocked
fact_mado_met
fact_clue_glass_found
fact_clue_electric_tracks_found
fact_clue_lighthouse_mark_found
fact_all_clues_found
fact_passage_dames_unlocked
fact_lighthouse_reached
fact_lighthouse_old_note_read
fact_lighthouse_top_unlocked
fact_lighthouse_pokemon_appeased
fact_mist_source_resolved
fact_ending_seen
fact_main_story_completed
```

## Facts de quêtes annexes

```text
fact_crystals_quest_started
fact_crystal_1_collected
fact_crystal_2_collected
fact_crystal_3_collected
fact_crystals_all_collected
fact_crystals_quest_completed

fact_goelise_quest_started
fact_goelise_nest_found
fact_goelise_item_returned
fact_goelise_item_kept
fact_goelise_quest_completed

fact_cabin_quest_started
fact_cabin_key_obtained
fact_cabin_opened
fact_guardian_journal_read
fact_cabin_quest_completed
```

---

# 10. World Rules principales

## Rival

```text
PNJ Lysa visible au port si fact_rival_port_defeated = false
PNJ Lysa dialogue “respect” si fact_rival_port_defeated = true
PNJ Lysa dialogue “moquerie douce” si fact_rival_port_lost_once = true
```

## Passage des Dames

```text
PNJ bloqueur visible si fact_passage_dames_unlocked = false
Passage utilisable si fact_passage_dames_unlocked = true
Message “La brume est trop dense” si false
```

## Marais

```text
Accès aux marais actif si step_rival_battle completed
Mado propose quête cristaux si fact_mado_met = true et fact_crystals_quest_completed = false
Cristaux visibles selon leurs facts respectifs
```

## Cabane du phare

```text
Porte verrouillée si fact_cabin_key_obtained = false
Porte ouverte si fact_cabin_key_obtained = true
Carnet visible si fact_cabin_opened = true
```

## Phare

```text
Sommet accessible si fact_lighthouse_top_unlocked = true
Brume visuelle active si fact_mist_source_resolved = false
Brume dissipée si fact_mist_source_resolved = true
```

## Port après fin

```text
Pêcheurs reprennent activité si fact_main_story_completed = true
Soline dialogue final si fact_main_story_completed = true
Maël félicite joueur si fact_main_story_completed = true
```

---

# 11. Events principaux

## Event — Introduction Maël

```text
ID : event_mael_intro
Map : map_bourg_selbrume
Element : npc_mael
Trigger : interact
```

Conditions :

```text
fact_mael_intro_done = false
```

Actions :

```text
Play Scene : scene_mael_intro
SetFact fact_mael_intro_done = true
SetFact fact_main_story_started = true
Activate Step step_receive_mission
```

---

## Event — Choix starter

```text
ID : event_starter_choice
Map : map_bourg_selbrume
Element : npc_mael
Trigger : interact
```

Conditions :

```text
fact_mael_intro_done = true
fact_starter_received = false
party_empty = true
```

Actions :

```text
Play Scene : scene_starter_choice
GivePokemon selected_starter
SetFact fact_starter_received = true
SetFact fact_mael_mission_given = true
Complete Step step_receive_mission
Activate Step step_go_to_port
```

Alternative si le joueur a déjà un Pokémon :

```text
SetFact fact_player_started_with_existing_pokemon = true
SetFact fact_mael_mission_given = true
Complete Step step_receive_mission
```

---

## Event — Entrée au port

```text
ID : event_enter_port_alert
Map : map_port_brisants
Element : zone_port_entry
Trigger : enter_zone
```

Conditions :

```text
step_go_to_port active
fact_port_alert_seen = false
```

Actions :

```text
Play Scene : scene_port_alert
SetFact fact_port_alert_seen = true
Complete Step step_go_to_port
Activate Step step_rival_battle
```

Scene Outcome possible :

```text
port_crowd_panicked
port_crowd_reassured
```

Selon outcome :

```text
SetFact fact_port_crowd_panicked = true
ou
SetFact fact_port_crowd_reassured = true
```

---

## Event — Rencontre rival

```text
ID : event_rival_port_meet
Map : map_port_brisants
Element : npc_lysa
Trigger : interact
```

Conditions :

```text
step_rival_battle active
fact_rival_port_defeated = false
```

Actions :

```text
Play Scene : scene_rival_meet
Launch Battle : battle_rival_port
```

Post-combat :

### Victory

```text
SetFact fact_rival_port_defeated = true
SetFact fact_lysa_respects_player = true
Complete Step step_rival_battle
Activate Step step_enter_marais
Play Scene : scene_rival_after_win
```

### Defeat

```text
SetFact fact_rival_port_lost_once = true
SetFact fact_lysa_goes_ahead = true
Complete Step step_rival_battle
Activate Step step_enter_marais
Play Scene : scene_rival_after_loss
```

---

## Event — Rencontre Mado

```text
ID : event_mado_first_talk
Map : map_marais_salants
Element : npc_mado
Trigger : interact
```

Conditions :

```text
step_enter_marais active
fact_mado_met = false
```

Actions :

```text
Play Scene : scene_mado_intro
SetFact fact_mado_met = true
Complete Step step_enter_marais
Activate Step step_find_three_clues
Unlock Side Storyline story_side_salt_crystals
```

---

## Event — Indices

```text
ID : event_clue_glass_found
Trigger : interact object
SetFact fact_clue_glass_found = true

ID : event_clue_electric_tracks_found
Trigger : inspect ground
SetFact fact_clue_electric_tracks_found = true

ID : event_clue_lighthouse_mark_found
Trigger : interact object
SetFact fact_clue_lighthouse_mark_found = true
```

Quand les trois sont vrais :

```text
SetFact fact_all_clues_found = true
Complete Step step_find_three_clues
Activate Step step_report_to_soline
```

---

## Event — Soline débloque le passage

```text
ID : event_soline_unlock_passage
Map : map_port_brisants
Element : npc_soline
Trigger : interact
```

Conditions :

```text
fact_all_clues_found = true
fact_passage_dames_unlocked = false
```

Actions :

```text
Play Scene : scene_soline_unlock_passage
SetFact fact_passage_dames_unlocked = true
Complete Step step_report_to_soline
Activate Step step_reach_lighthouse
```

---

## Event — Arrivée au phare

```text
ID : event_lighthouse_exterior_arrival
Map : map_phare_exterieur
Element : zone_lighthouse_entry
Trigger : enter_zone
```

Conditions :

```text
fact_passage_dames_unlocked = true
fact_lighthouse_reached = false
```

Actions :

```text
Play Scene : scene_lighthouse_arrival
SetFact fact_lighthouse_reached = true
Complete Step step_reach_lighthouse
Activate Step step_climb_lighthouse
```

---

## Event — Sommet du phare

```text
ID : event_final_pokemon_scene
Map : map_sommet_phare
Element : zone_lighthouse_top
Trigger : enter_zone
```

Conditions :

```text
step_final_confrontation active
fact_mist_source_resolved = false
```

Actions :

```text
Play Scene : scene_final_pokemon
Launch Battle : battle_lighthouse_pokemon
```

Post-combat :

```text
SetFact fact_lighthouse_pokemon_appeased = true
SetFact fact_mist_source_resolved = true
Complete Step step_final_confrontation
Activate Step step_return_to_port
Play Scene : scene_mist_disperses
```

---

## Event — Épilogue au port

```text
ID : event_ending_port
Map : map_port_brisants
Element : zone_port_center
Trigger : enter_zone
```

Conditions :

```text
fact_mist_source_resolved = true
fact_ending_seen = false
```

Actions :

```text
Play Scene : scene_ending_port
SetFact fact_ending_seen = true
Complete Step step_return_to_port
Complete Step step_main_story_completed
SetFact fact_main_story_completed = true
```

---

# 12. Scenes principales

## Scene — Maël introduction

```text
ID : scene_mael_intro
Type : graph
```

Nodes :

```text
Start
→ Dialogue Yarn : yarn_mael_intro
→ Condition : party_empty
    true → Play Scene node : starter explanation
    false → Dialogue Yarn : yarn_mael_existing_pokemon
→ Emit Outcome : mission_started
→ End
```

---

## Scene — Alerte au port

```text
ID : scene_port_alert
Type : graph
```

Nodes :

```text
Start
→ Dialogue Yarn : yarn_port_alert
→ Branch by outcome
    panic → Play Cinematic : cinematic_port_panic
    reassure → Play Cinematic : cinematic_port_reassure
→ Merge
→ Emit Scene Outcome : port_crowd_panicked ou port_crowd_reassured
→ End
```

Outcomes Yarn :

```text
panic
reassure
```

---

## Scene — Rencontre rival

```text
ID : scene_rival_meet
Type : graph
```

Nodes :

```text
Start
→ Dialogue Yarn : yarn_rival_intro
→ Branch by outcome
    confident → Play Cinematic : cinematic_rival_smiles
    hesitant → Play Cinematic : cinematic_rival_teases
→ Merge
→ Emit Scene Outcome : rival_battle_started
→ End
```

Combat lancé par Event après la Scene.

---

## Scene — Après victoire rival

```text
ID : scene_rival_after_win
```

Nodes :

```text
Start
→ Play Cinematic : cinematic_rival_depart_win
→ Dialogue Yarn : yarn_rival_after_win
→ Emit Outcome : rival_respects_player
→ End
```

---

## Scene — Après défaite rival

```text
ID : scene_rival_after_loss
```

Nodes :

```text
Start
→ Play Cinematic : cinematic_rival_depart_loss
→ Dialogue Yarn : yarn_rival_after_loss
→ Emit Outcome : rival_goes_ahead
→ End
```

---

## Scene — Mado intro

```text
ID : scene_mado_intro
```

Nodes :

```text
Start
→ Dialogue Yarn : yarn_mado_intro
→ Branch by outcome
    accept_help → Activate side quest crystals
    refuse_for_now → no activation, but can retry
→ End
```

Si le joueur refuse :

```text
fact_mado_met peut être vrai
fact_crystals_quest_started reste faux
```

---

## Scene — Soline débloque le passage

```text
ID : scene_soline_unlock_passage
```

Nodes :

```text
Start
→ Dialogue Yarn : yarn_soline_clues
→ Play Cinematic : cinematic_passage_revealed
→ Emit Outcome : passage_unlocked
→ End
```

---

## Scene — Pokémon du phare

```text
ID : scene_final_pokemon
```

Nodes :

```text
Start
→ Play Cinematic : cinematic_lighthouse_light_unstable
→ Dialogue Yarn : yarn_final_pokemon_discovery
→ Action : launch battle handled by Event
→ End
```

---

## Scene — Brume dissipée

```text
ID : scene_mist_disperses
```

Nodes :

```text
Start
→ Play Cinematic : cinematic_mist_disperses
→ Dialogue Yarn : yarn_mael_distance_reaction
→ Emit Outcome : mist_resolved
→ End
```

---

## Scene — Épilogue au port

```text
ID : scene_ending_port
```

Nodes :

```text
Start
→ Play Cinematic : cinematic_port_celebration
→ Dialogue Yarn : yarn_ending_port
→ Emit Outcome : main_story_completed
→ End
```

---

# 13. Cinématiques principales

## Cinématiques du Chapitre 1

```text
cinematic_port_panic
cinematic_port_reassure
cinematic_rival_smiles
cinematic_rival_teases
cinematic_rival_depart_win
cinematic_rival_depart_loss
```

## Cinématiques du Chapitre 2

```text
cinematic_marais_first_fog
cinematic_crystal_glow
cinematic_passage_revealed
```

## Cinématiques du Chapitre 3

```text
cinematic_lighthouse_arrival
cinematic_lighthouse_light_unstable
cinematic_mist_disperses
```

## Cinématiques du Chapitre 4

```text
cinematic_port_celebration
cinematic_lighthouse_final_beam
```

Toutes les cinématiques sont linéaires.

Pas de branches dans la cinématique.

Les branches sont gérées par la Scene.

---

# 14. Dialogues Yarn

## `yarn_mael_intro`

Objectif :

```text
présenter Maël
présenter la brume
introduire la mission
```

Outcomes possibles :

```text
accept_mission
ask_more
```

---

## `yarn_port_alert`

Situation :

```text
La foule du port panique à cause de la brume.
```

Choix joueur :

```text
“Oh mon Dieu, on va tous mourir !”
“Calmez-vous, on va comprendre ce qui se passe.”
```

Outcomes :

```text
panic
reassure
```

---

## `yarn_rival_intro`

Situation :

```text
Lysa provoque le joueur.
```

Choix joueur :

```text
“Je peux aider.”
“Je ne suis pas sûr.”
“Pousse-toi, je vais régler ça.”
```

Outcomes :

```text
confident
hesitant
aggressive
```

Utilisation :

```text
Changer la cinématique ou le ton avant combat.
Éventuellement influencer un fact relationnel léger.
```

---

## `yarn_mado_intro`

Outcomes :

```text
accept_help
refuse_for_now
```

---

## `yarn_goelise_choice`

Outcomes :

```text
return_item
keep_item
```

---

## `yarn_yvon_cabin`

Outcomes :

```text
accept_search_key
ignore_for_now
```

---

## `yarn_final_pokemon_discovery`

Pas forcément de choix. Sert à expliquer :

```text
Le Pokémon n’est pas méchant.
Il est coincé.
La lentille amplifie son énergie.
```

---

# 15. Combats

## Combat rival au port

```text
ID : battle_rival_port
Type : trainer
Trainer : trainer_lysa_port
```

Outcomes :

```text
victory
defeat
```

Important :

```text
La défaite ne bloque pas l’histoire.
Elle produit une branche différente, puis rejoint le flux principal.
```

---

## Combats mineurs du phare

```text
battle_lighthouse_curious_1
battle_lighthouse_curious_2
```

Rôle :

```text
habitants paniqués ou curieux
pas une Team criminelle
```

---

## Combat final

```text
ID : battle_lighthouse_pokemon
Type : static / boss
```

Outcomes :

```text
victory
capture éventuellement plus tard
appeased éventuellement si système dédié
```

En V0 :

```text
victory = Pokémon apaisé
```

---

# 16. Objets nécessaires

## Key items

```text
item_cabin_key
item_polished_glass_piece
item_lighthouse_lens_mark
item_salt_crystal
```

## Consommables

```text
item_potion
item_super_potion
item_salt_heal
```

## Récompenses possibles

```text
item_berry_pack
item_lighthouse_charm
item_marine_charm
```

---

# 17. Ce que le projet doit posséder pour faire fonctionner Selbrume

Pour que ce scénario soit implémentable, PokeMap doit avoir au minimum :

## Données narratives

```text
Storyline
Chapter
StoryStep
Event
SceneGraph
SceneNode
CinematicAsset
DialogueAsset / Yarn reference
Fact
WorldRule
```

## Données map

```text
Map element IDs
NPC IDs
Zone trigger IDs
Interactable object IDs
Door IDs
Battle trigger IDs
```

## Gameplay minimal

```text
party
starter / give Pokémon
trainer battle
battle outcome
static encounter / boss battle
item reward
money reward
quest activation
fact persistence
world rule application
save/load
```

## UI auteur

```text
Storyline Graph
Scene Builder
Event Builder
Cinematic Builder
Map Events View
Facts & World Rules
Validator
```

---

# 18. Golden slice recommandé

Le premier vrai golden slice doit être :

```text
Parler à Lysa au port
→ Event vérifie Step active + Rival pas battu
→ Scene “Rencontre rival”
→ Dialogue Yarn “rival_intro”
→ Outcome confident / hesitant / aggressive
→ Cinematic différente selon outcome
→ Combat Rival
→ Outcome victory / defeat
→ Fact persistant
→ Step completed
→ World Rule change Lysa
→ Quête annexe devient disponible
→ Validator confirme que tout est atteignable
```

Pourquoi ce golden slice est parfait :

```text
il teste la map
il teste un event
il teste une scène graph
il teste Yarn
il teste une cinématique
il teste un combat
il teste un outcome
il teste les facts
il teste les steps
il teste les world rules
il teste la disponibilité d’une quête annexe
il teste le validator
```

C’est le cœur du Narrative Studio.

---

# 19. Structure finale de Selbrume en une vue

```text
Storyline principale : La brume du phare

Chapitre 1 — Le port
  Step : Introduction à Selbrume
  Step : Recevoir la mission
  Step : Aller au port
  Step : Combat rival
    Branche victoire
    Branche défaite
    Convergence vers les marais

Chapitre 2 — Les marais
  Step : Entrer dans les marais
  Step : Trouver trois indices
  Step : Convaincre Soline

Chapitre 3 — Le phare
  Step : Débloquer le passage
  Step : Rejoindre le phare
  Step : Explorer le phare
  Step : Apaiser le Pokémon du phare

Chapitre 4 — Épilogue
  Step : Retour au port
  Step : Histoire terminée

Quête annexe : Les cristaux de sel
  Collecte 3 cristaux
  Retour Mado
  Récompense

Quête annexe : Le Goélise du port
  Trouver le nid
  Choix rendre/garder
  Dialogues persistants

Quête annexe : La cabane du phare
  Trouver clé
  Ouvrir cabane
  Lire carnet
  Débloquer lore/raccourci
```

---

# 20. Conclusion

Selbrume doit être notre **mini-jeu de référence**.

Il n’est pas énorme, mais il est assez complet pour forcer PokeMap à gérer correctement :

```text
histoire principale
quêtes annexes
chapitres
steps
events
scènes graphées
cinématiques linéaires
dialogues Yarn
outcomes
combats
facts
world rules
conditions d’accès
validation
```

Le but n’est pas d’écrire un roman. Le but est de créer une aventure courte, propre, testable, qui permet de vérifier si le futur Narrative Studio est vraiment capable de fabriquer un fangame Pokémon-like sans code.

Si Selbrume fonctionne, le modèle fonctionne.

Et si Selbrume coince, c’est que notre Narrative Studio coince aussi.
