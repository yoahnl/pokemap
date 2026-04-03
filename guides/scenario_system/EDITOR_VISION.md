# Editor Vision (future)

## 1. Objectif
Definir une vision UX claire pour un editeur scenario coherent avec le modele:
- Global Story
- Step
- Cutscene

Cette vision ne decrit aucune implementation UI immediate.
Elle fixe uniquement le cadre produit.

## 2. Les 3 vues futures

## 2.1 Vue 1 - Navigation generale (macro)
Role:
- donner la carte macro du jeu,
- montrer Global Story,
- montrer la relation entre Steps,
- montrer les outcomes globaux.

Montre:
- arcs,
- noeuds Step,
- dependances et transitions,
- progression macro.

Ne montre pas:
- details de dialogue ligne par ligne,
- pathfinding de scene,
- micro actions PNJ.

Schema:

```text
GLOBAL STORY NAV
   [Arc Prologue] -> [Step: Intro Prof]
                    -> [Step: Starter]
                    -> [Step: Rival 1]
                    -> [Step: Badge 1]
```

## 2.2 Vue 2 - Vue Step (metier)
Role:
- definir la logique metier de l etape,
- definir conditions d entree/validation/sortie,
- lister cutscenes liees,
- formaliser outcomes locaux utiles a l etape.

Montre:
- objectif Step,
- prerequis,
- conditions de completion,
- outcomes produits/consommes,
- cutscenes associees.

Ne montre pas:
- micro timeline de scene,
- animation de camera detaillee,
- path moves case par case.

Schema:

```text
STEP VIEW
   Step: "Choisir starter"
   Entrée: chapter_1.intro.ready
   Cutscenes:
      - starter_intro
      - starter_selection
   Completion:
      - flag starter_chosen == true
   Sortie:
      - outcome global chapter_1.starter_chosen
```

## 2.3 Vue 3 - Editeur Cutscene (execution)
Role:
- construire l execution concrete de scene,
- sequence de dialogues/mouvements/waits/choix,
- branches locales et convergence.

Montre:
- steps de scene en sequence,
- labels/goto de convergence,
- choix locaux,
- actions de mise en scene.

Ne montre pas:
- la macro carte complete du chapitre,
- la logique metier globale de toutes les Steps.

Schema:

```text
CUTSCENE EDITOR
   Dialogue -> Move NPC -> Wait -> Choice
      -> Branch A -> Emit local outcome -> Goto End
      -> Branch B -> Emit local outcome -> Goto End
      -> Branch C -> Emit local outcome -> Goto End
   Label End -> Final Dialogue -> Emit global outcome
```

## 3. Separation stricte des vues

```text
Vue 1 (macro): "Ou en est l histoire ?"
Vue 2 (metier): "Que faut il accomplir dans cette etape ?"
Vue 3 (scene): "Comment la scene se joue concretement ?"
```

## 4. Erreurs UX a eviter
1. Melanger macro progression et micro mise en scene dans une seule vue.
2. Exposer le pathfinding en vue Global Story.
3. Exposer les dialogues ligne par ligne en vue Navigation macro.
4. Refaire un "graph geant unique" qui melange tout.
5. Cacher les outcomes globaux dans des details de scene.

## 5. Pourquoi cette separation est necessaire
- Lisibilite: chaque vue repond a une seule question.
- Maintenance: les changements de scene n impactent pas toute la macro carte.
- Productivite: l auteur choisit le bon niveau de travail.
- Robustesse: moins de confusion entre logique metier et mise en scene.

## 6. Schema conceptuel complet des 3 vues

```text
                    +----------------------------+
                    | Vue 1: Global Story Nav   |
                    | arcs / steps / outcomes   |
                    +-------------+--------------+
                                  |
                                  v
                    +----------------------------+
                    | Vue 2: Step Logic          |
                    | entrees / validations      |
                    | cutscenes de l etape       |
                    +-------------+--------------+
                                  |
                                  v
                    +----------------------------+
                    | Vue 3: Cutscene Editor     |
                    | dialogue / move / wait     |
                    | choice / label / goto      |
                    +----------------------------+
```

## 7. Conclusion
La vision cible impose trois surfaces distinctes:
- navigation macro (Global Story),
- logique metier locale (Step),
- execution concrete (Cutscene).

Cette separation est une regle produit, pas un detail cosmetique.
