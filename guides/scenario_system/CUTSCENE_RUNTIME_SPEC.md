# Cutscene Runtime Spec

## 1. Role exact de Cutscene
Cutscene est le niveau d execution concrete d une scene.
Cutscene sert a orchestrer:
- dialogue,
- mouvement PNJ,
- pathfinding,
- wait,
- choix joueur,
- transitions locales,
- emission de signaux (outcomes/flags) necessaires a la scene.

Cutscene n est pas:
- le pilote de la progression globale du jeu,
- un remplacement de Step,
- un remplacement de Global Story.

## 2. Frontiere fonctionnelle

```text
Global Story / Step:
   "Pourquoi et quand on avance dans l histoire"

Cutscene:
   "Comment la scene se passe concretement"
```

## 3. Place du pathfinding
Regle explicite:

```text
Le pathfinding appartient a Cutscene.
```

Justification:
- Deplacer un PNJ est un besoin de mise en scene.
- Ce n est pas une decision metier de progression.
- Ce n est pas une regle macro de Global Story.

## 4. Capacites attendues du runtime cutscene
Capacites de base attendues:
- ouvrir un dialogue,
- attendre la fermeture dialogue si la scene le demande,
- deplacer un PNJ et attendre la fin de mouvement,
- attendre une duree,
- orienter un PNJ,
- emettre un outcome,
- set/clear flag technique de scene,
- appeler une sous-cutscene,
- faire un branchement local (choix + goto/label + conditions simples).

## 5. Ce que Cutscene peut faire

Exemples concrets:
- "Le professeur marche jusqu a la table, puis parle."
- "Le rival arrive apres 2 secondes, puis combat."
- "Le joueur choisit fire/water/grass, puis branche locale."
- "La scene emet starter.selected.fire puis continue."

## 6. Ce que Cutscene ne doit pas faire
- Definir seule la structure complete du jeu.
- Decider seule de la progression macro du chapitre.
- Remplacer les validations metier de Step.
- Cacher des regles de progression globale non explicites.

## 7. Branchement local vs progression globale

```text
Branchement local Cutscene:
   - sequence de scene
   - variantes de dialogue/animation
   - convergence vers un bloc final

Progression globale:
   - deblocage Step suivante
   - activation arc suivant
   - signal macro pour Global Story
```

Regle:
- Une cutscene peut produire des signaux.
- La consommation metier de ces signaux reste au niveau Step/Global Story.

## 8. Outcomes en Cutscene
Une cutscene peut emettre:
- outcomes locaux (souvent pour branches de scene),
- outcomes globaux (si la Step le formalise explicitement).

Important:
- emit outcome != fin automatique de la cutscene.
- emit outcome != validation automatique de Step.
- emit outcome != avancee globale automatique.

## 9. Choix joueur en Cutscene
Le choix joueur est une brique runtime de scene:
- la cutscene demande un choix,
- la scene attend la resolution,
- la scene branche localement selon la reponse,
- la scene converge ensuite vers un bloc commun si necessaire.

Schema local:

```text
Dialogue intro
   -> Choice
      -> branche A
      -> branche B
      -> branche C
   -> convergence
   -> fin scene
```

## 10. Label/Goto en Cutscene
Label/Goto est un outil de structure locale:
- Label marque un point de convergence ou de reprise.
- Goto saute vers un label connu.

Usage recommande:
- convergence de branches,
- reduction de duplication.

Usage a eviter:
- graph spaghetti illisible,
- sauts non structures partout.

## 11. Regles structurantes
1. Cutscene doit rester lisible et orientee scene.
2. Les branches locales doivent converger des que possible.
3. Les outcomes doivent etre nommes explicitement.
4. Les conditions metier majeures restent dans Step/Global Story.
5. Les micro-conditions de scene restent dans Cutscene.

## 12. Exemple guide: starter_selection

```text
Cutscene starter_selection
   1) dialogue intro professeur
   2) choice starter_choice [fire, water, grass]
   3) branche fire -> outcome local starter.selected.fire
   4) branche water -> outcome local starter.selected.water
   5) branche grass -> outcome local starter.selected.grass
   6) bloc final commun:
        - donner starter
        - set flag starter_chosen
        - emit outcome global chapter_1.starter_chosen
```

## 13. Limites conceptuelles connues
Ce document ne definit pas:
- une implementation UI de cutscene editor,
- un modele complet de camera/timeline avancee,
- une serialisation definitive de tous les types de scene.

Ce document fixe la frontiere conceptuelle de Cutscene runtime.
