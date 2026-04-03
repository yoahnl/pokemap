# Global Story / Step / Cutscene Architecture

## 1. Vision d ensemble
Le systeme cible repose sur trois niveaux separes:

```text
GLOBAL STORY  -> pilote la progression macro
STEP          -> porte la logique metier locale
CUTSCENE      -> execute la mise en scene concrete
```

Ce decoupage est obligatoire pour eviter:
- un graph unique impossible a maintenir,
- la confusion entre regles metier et actions de scene,
- la derive "event graph geant" sans lisibilite produit.

## 2. Hierarchie cible

```text
GLOBAL STORY
   |
   +-- Step A
   |     +-- Cutscene A1
   |     +-- Cutscene A2
   |     +-- validations / conditions / outcomes
   |
   +-- Step B
   |     +-- Cutscene B1
   |     +-- validations / conditions / outcomes
   |
   +-- Step C
         +-- Cutscene C1
         +-- ...
```

## 3. Responsibilities par niveau

## 3.1 Global Story
Role:
- progression globale du jeu,
- arcs narratifs,
- branches majeures,
- ordre macro des etapes,
- deblocage des grandes sequences.

Questions traitees:
- Ou en est l histoire ?
- Quelle branche globale est active ?
- Quelle etape est debloquee ?
- Quel arc vient ensuite ?

Global Story ne fait pas:
- pas de pathfinding,
- pas de deplacement PNJ case par case,
- pas de dialogue ligne par ligne,
- pas de script de mise en scene.

Schema Global Story:

```text
[Arc Prologue] --> [Arc Starter] --> [Arc Rival 1] --> [Arc Badge 1]
        \               \
         \               +--> [Arc Team Ennemie - branche]
          \
           +--> [Arc Tutoriel Optionnel]
```

## 3.2 Step
Role:
- unite metier de progression,
- objectif local clair,
- validation d avancement,
- reception/emission d outcomes metier.

Questions traitees:
- Que doit accomplir le joueur maintenant ?
- Quelles conditions valident cette etape ?
- Quel resultat fait avancer la progression ?

Exemples:
- rencontrer le professeur,
- choisir un starter,
- battre le rival,
- obtenir un badge.

Step ne fait pas:
- pas de mise en scene detaillee,
- pas de tempo de dialogue,
- pas de micro animation de scene.

Schema Step:

```text
Step: "Choisir son starter"
   Entrée:
      - chapitre_1.intro.ready
   Actions metier:
      - lancer cutscene starter_selection
   Validation:
      - flag starter_chosen == true
   Sortie:
      - outcome global chapter_1.starter_chosen
```

## 3.3 Cutscene
Role:
- execution concrete d une scene,
- dialogues,
- deplacements PNJ,
- pathfinding,
- camera,
- waits,
- choix joueur,
- transitions,
- petits flags techniques si necessaire,
- emission d outcomes locaux (et eventuellement globaux selon regle Step).

Cutscene ne fait pas:
- pas de pilotage macro complet du jeu,
- pas de remplacement de Global Story,
- pas de remplacement de la logique metier Step.

Schema Cutscene:

```text
Cutscene "starter_selection"
   -> dialogue intro
   -> move npc professor
   -> wait
   -> choix joueur
   -> branche locale
   -> convergence
   -> emit outcome(s)
```

## 4. Outcomes: local vs global

## 4.1 Outcome local
Usage:
- dans une Step,
- entre cutscenes proches,
- pour exprimer un resultat local de branchement/progression.

Exemples:
- starter.selected.fire
- starter.selected.water
- starter.selected.grass
- professor_intro.accepted
- rival.arrived
- player.said_yes

## 4.2 Outcome global
Usage:
- signal de progression macro pour Global Story.

Exemples:
- chapter_1.starter_chosen
- chapter_1.professor_arc.completed
- badge_1.obtained

Regle fondamentale:
- Une cutscene peut emettre un outcome pendant son execution.
- Un outcome n implique pas automatiquement:
  - fin de cutscene,
  - fin de Step,
  - avancee globale immediate.

## 5. Types de branches

## 5.1 Branches exclusives
Un seul chemin est choisi.

Exemples:
- faction A ou faction B,
- starter fire/water/grass.

## 5.2 Branches paralleles
Plusieurs arcs avancent en parallele.

Exemples:
- arc principal,
- arc rival,
- arc team ennemie,
- progression badges.

## 5.3 Branches conditionnelles
Ouverture selon etat (flag/outcome/condition metier).

Exemple:
- route ouverte seulement si un outcome existe.

## 5.4 Branches convergentes
Des chemins differents reviennent vers un bloc commun.

Pourquoi c est critique:
- evite l explosion combinatoire,
- garde un scenario maintenable,
- permet variantes locales sans dupliquer toute la suite.

Schema branches:

```text
           +--> [Path A] --+
[Node X] --+               +--> [Convergence C] --> suite commune
           +--> [Path B] --+
           +--> [Path C] --+
```

## 6. Exemple obligatoire: choix du starter

## 6.1 Vue globale

```text
GLOBAL STORY
   |
   v
STEP : choisir son starter
   |
   v
CUTSCENE : starter_selection
   |
   +--> intro professeur
   |
   +--> choix :
   |      - fire
   |      - water
   |      - grass
   |
   +--> branche fire
   |      - emit local outcome: starter.selected.fire
   |      - dialogue specifique
   |      - animation specifique
   |
   +--> branche water
   |      - emit local outcome: starter.selected.water
   |      - dialogue specifique
   |      - animation specifique
   |
   +--> branche grass
   |      - emit local outcome: starter.selected.grass
   |      - dialogue specifique
   |      - animation specifique
   |
   +--> bloc final commun
          - donner le starter
          - set flag starter_chosen
          - emit global outcome: chapter_1.starter_chosen
          - step complete
```

## 6.2 Lecture architecturale
- Les branches fire/water/grass sont locales a la cutscene.
- La validation metier de progression reste au niveau Step.
- Le signal macro (chapter_1.starter_chosen) sert a Global Story.
- La convergence est obligatoire pour eviter trois suites dupliquees.

## 7. Regle explicite sur le pathfinding
Regle de conception:

```text
Pathfinding appartient au niveau Cutscene.
```

Raison:
- "faire bouger un PNJ vers une case" est une action de mise en scene.
- Ce n est pas une regle de progression globale.
- Ce n est pas une validation metier de Step.

## 8. Separation des responsabilites (anti-confusion)

```text
PROGRESSION (Global Story / Step)
   - arcs
   - etapes
   - conditions metier
   - outcomes importants

MISE EN SCENE (Cutscene)
   - dialogues
   - mouvements PNJ
   - camera
   - waits
   - choix locaux
   - micro branches
   - pathfinding
```

Erreur majeure a eviter:
- ne pas melanger logique de progression et mise en scene dans un meme graphe sans frontiere.

## 9. Conclusion
Le modele recommande et fige est:
- Global Story pilote la macro progression.
- Step porte la logique metier locale de progression.
- Cutscene execute la scene concrete.

Ce decoupage est la base officielle pour les prochains lots.
