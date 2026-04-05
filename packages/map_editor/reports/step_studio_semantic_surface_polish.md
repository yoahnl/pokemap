# Step Studio — polish sémantique surface (créateur, pas DTO)

Objectif : libellés compréhensibles pour un créateur non développeur, sans changer le JSON, le runtime ni la logique. Aucun nouveau lien automatique suggéré.

## Renommages appliqués et raison

| Avant (problème) | Après | Pourquoi ça réduit l’ambiguïté |
|------------------|--------|--------------------------------|
| Portée | **Type de résultat** | Indique qu’on classe le résultat, pas un concept technique de modèle. |
| Local | **Variante de cette étape** | Ancre clairement le résultat au périmètre de l’étape courante. |
| Progression | **Avancement de l’histoire** | Évite « progression » trop large ; aligné macro Global Story vs step. |
| Monde | **État du monde** | Évoque PNJ, carte, persistance — plus concret que « monde » seul. |
| Validation (modes / admin) | **Condition de fin** + options explicites | « Validation » sonne procédure ; ici c’est la règle qui clôt l’étape. |
| Fin de l’étape (carte / inspecteur texte) | **Quand l’étape se termine** | Langage naturel pour le bloc texte + résumé de la condition enregistrée. |
| Après cette étape | **Note de transition** | Assume l’honnêteté : mémo / lecture, pas promesse de suite auto. |
| Rappel… sans effet automatique | **Étape liée en mémo (n’active rien automatiquement)** | Court + explicite sur l’absence d’effet sur `flowUnlocksStepId`. |
| Sans effet automatique (esprit) | Formulation **« n’active rien automatiquement »** | Plus direct qu’un double négatif administratif. |
| Sur la carte / titres carte | **Changements sur la carte** | Insiste sur la modification d’état, pas la métaphore « être sur la carte ». |
| + Règle sur la carte | **Ajouter un changement** | Action concrète, alignée avec le titre de section. |
| Variantes / + variante | **Issues** / **Ajouter une issue** | Cohérent avec « Issues possibles », moins générique que « variante ». |
| Résultat pour l’histoire | **Ajouter un résultat d’histoire** | Verbe d’action + objet clair. |
| Réf. projet | **Référence de la scène** | Lisible ; l’id reste affiché quand utile. |
| Phrase sur le fil | **Texte affiché dans le parcours** | Évite le jargon « fil » interne ; garde le rôle (lecture centrale). |
| Réglage enregistré | **Règle appliquée** | Vivant, sans prétendre autre chose que la donnée persistée. |
| Cutscene (libellés surface Step) | **Scène** où pertinent | Distinction produit : Cutscene Studio pour l’outil ; « scène » pour le créateur dans Step. |
| Modes de fin (liste) | Formulations demandées (scène, interaction, état du monde, manuel) | Alignées sur l’intention jeu, pas sur les noms d’enum. |

## Fichiers touchés

- `lib/src/features/narrative/application/step_studio_authoring.dart` — `stepStudio*Label`, `summarizeStep*`, commentaire enum completion.
- `lib/src/ui/canvas/step_studio_workspace.dart` — inspecteur, activation / completion, carte, liste latérale, `_CutsceneLinkRow`, `_OutcomeRow`.
- `lib/src/ui/canvas/step_studio/step_flow_canvas.dart` — titres carte, note de transition, référence scène.
- `lib/src/ui/canvas/step_studio/step_flow_palette.dart` — repères & ajouts.
- `test/step_flow_canvas_test.dart` — attentes de titres canvas.

## Non-objectifs (respectés)

- Pas de changement de schéma JSON ni de sémantique runtime.
- Pas d’affichage de `flowUnlocksStepId` sur le canvas ; pas de wording de « déblocage auto ».
- Pas d’élargissement Cutscene Studio / Global Story hors libellés Step Studio concernés.
