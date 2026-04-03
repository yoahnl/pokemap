# LOT 62 - Scenario System Spec (documentation only)

## 1. Objectif exact du lot
Ce lot fige une reference de conception centrale pour le futur systeme de scenario.
Le lot est strictement documentaire.
Il ne contient aucune implementation technique.

Objectif:
- arreter la derive de directions multiples,
- formaliser un cadre unique durable:
  - Global Story
  - Step
  - Cutscene

## 2. Livrables crees

### Dossier principal
- `guides/scenario_system/README.md`
- `guides/scenario_system/GLOBAL_STORY_STEP_CUTSCENE_ARCHITECTURE.md`
- `guides/scenario_system/CUTSCENE_RUNTIME_SPEC.md`
- `guides/scenario_system/EDITOR_VISION.md`

### Rapport de lot
- `reports/lots/lot_62_scenario_system_spec/LOT_62_SCENARIO_SYSTEM_SPEC_REPORT.md`

## 3. Resume precis de chaque fichier

## 3.1 README.md
Contient:
- le role du dossier,
- le resume du modele a 3 niveaux,
- les liens de navigation vers les specs detaillees.

## 3.2 GLOBAL_STORY_STEP_CUTSCENE_ARCHITECTURE.md
Contient:
- la vision d ensemble du modele,
- la separation des responsabilites par niveau,
- la hierarchie cible Global Story -> Step -> Cutscene,
- la distinction outcomes locaux/globaux,
- les 4 types de branches,
- l exemple detaille du choix du starter,
- les regles anti-confusion,
- des schemas ASCII de reference.

## 3.3 CUTSCENE_RUNTIME_SPEC.md
Contient:
- le role exact du niveau Cutscene,
- ce que Cutscene peut faire et ne doit pas faire,
- la regle explicite "pathfinding appartient a Cutscene",
- la difference branchement local vs progression globale,
- des regles structurantes pour scene runtime.

## 3.4 EDITOR_VISION.md
Contient:
- la vision future en 3 vues distinctes:
  - navigation generale,
  - vue Step,
  - editeur Cutscene,
- ce que chaque vue montre/ne montre pas,
- les erreurs UX a eviter,
- des schemas ASCII conceptuels.

## 4. Justification de l emplacement
- `guides/scenario_system/` centralise la reference produit durable.
- `reports/lots/lot_62_scenario_system_spec/` garde la tracabilite du lot.

Ce choix separe clairement:
- la reference vivante (guides),
- le suivi d execution du lot (report).

## 5. Confirmation de scope
Ce lot est volontairement hors:
- runtime implementation,
- editor implementation,
- UI implementation,
- model implementation,
- tests.

Aucun code n a ete ajoute ou modifie.
Aucun test n a ete ajoute ou modifie.

## 6. Validations finales executees
Validations realisees:
1. verification existence des 4 fichiers de guides.
2. verification existence du rapport.
3. verification non-vide des fichiers (presence de contenu redacte).
4. verification qu aucun fichier de code/test n a ete modifie.

## 7. Validation technique (etat git)
Etat attendu en fin de lot:
- uniquement des nouveaux fichiers markdown de documentation.
- aucun changement sur fichiers `.dart` ou tests.

## 8. Conclusion
Le lot 62 livre une base de verite documentaire centrale, durable, et reutilisable.
Le cadre Global Story / Step / Cutscene est formalise sans ambiguite.
La documentation est le livrable principal de ce lot.
