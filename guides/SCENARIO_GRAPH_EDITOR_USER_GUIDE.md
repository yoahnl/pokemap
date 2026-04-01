# Guide Utilisateur — Scenario Graph Editor

## 1. Introduction

Le **Scenario Graph Editor** sert à orchestrer la progression narrative globale de ton jeu.

Il ne remplace pas les autres bibliothèques, il les relie :

- **Scenario Graphs** : orchestration visuelle (ordre, branches, conditions, liens monde).
- **Dialogue Library** : contenu de dialogues Yarn.
- **Scenario Scripts** : procédures runtime réutilisables.
- **World Maps** : events, entités, warps, triggers, trainers.

En pratique :
- les dialogues contiennent le texte,
- les scripts exécutent des actions runtime,
- les maps contiennent les objets du monde,
- le graphe scénario décide **quand** et **comment** tout s’enchaîne.

## 2. Philosophie de l’outil

Pense le graphe comme un storyboard interactif :

- un node = une intention narrative claire,
- une connexion = une transition,
- une condition/choice = un embranchement,
- une référence monde = un lien explicite avec le contenu map.

Recommandation :
- évite les nodes “fourre-tout”,
- garde des nodes courts, lisibles, spécialisés.

## 3. Types de nodes (simple et concret)

## Start

À quoi ça sert :
- point d’entrée du scénario.

Quand l’utiliser :
- toujours, une seule fois par scénario.

Quand ne pas l’utiliser :
- pour faire une action ou un dialogue.

À remplir en priorité :
- titre/description uniquement.

## Dialogue

À quoi ça sert :
- afficher un dialogue Yarn ou une séquence dialoguée.

Quand l’utiliser :
- scène parlée, exposition, retour d’info au joueur.

Quand ne pas l’utiliser :
- action gameplay pure (flag, warp, trigger).

À remplir en priorité :
- `Dialogue Yarn`,
- optionnel : `Script scénario`,
- optionnel : message inline court.

## Action

À quoi ça sert :
- déclencher une action gameplay/narrative.

Quand l’utiliser :
- déclencher un combat, lancer un script, setter un flag, cibler un event/warp/trigger.

Quand ne pas l’utiliser :
- pour structurer un choix simple (utilise `Choice`).

À remplir en priorité :
- `Action` (preset),
- puis uniquement les champs affichés pour cette action.

## Condition

À quoi ça sert :
- tester un état, puis brancher le flux.

Quand l’utiliser :
- progression flag/variable/event consommé.

Quand ne pas l’utiliser :
- quand il n’y a aucune logique de branche.

À remplir en priorité :
- mode de condition,
- champs du mode choisi,
- deux sorties minimum.

## Choice

À quoi ça sert :
- représenter un choix joueur avec plusieurs branches.

Quand l’utiliser :
- “Oui / Non”, choix d’approche, choix de récompense.

Quand ne pas l’utiliser :
- pour un test automatique de flag (utilise `Condition`).

À remplir en priorité :
- labels lisibles sur les edges sortants.

## Reference

À quoi ça sert :
- documenter/lier explicitement le scénario à une ressource du projet.

Quand l’utiliser :
- map/event/entity/warp/trigger/trainer/dialogue/script comme point d’ancrage.

Quand ne pas l’utiliser :
- pour exécuter une action immédiate (utilise `Action`).

À remplir en priorité :
- type de référence,
- ressource cible via dropdown.

## End

À quoi ça sert :
- fin de branche / fin de séquence.

Quand l’utiliser :
- sortie claire d’un flux.

Quand ne pas l’utiliser :
- comme node intermédiaire.

À remplir en priorité :
- titre/description.

## 4. Champs importants

## Script
- Ressource runtime réutilisable.
- À utiliser quand il y a une logique procédurale.

## Dialogue
- Ressource Yarn.
- À utiliser pour la narration parlée.

## Map
- Contexte monde.
- Conditionne les dropdowns dépendants.

## Event ID / Entity ID / Warp ID / Trigger ID
- Cibles existantes de la map sélectionnée.
- L’éditeur filtre automatiquement ces listes selon `Map`.

## Trainer ID
- Cible dresseur pour combat/action liée.

## Flag Name
- Exemple : `story.got_starter`.

## Variable Name
- Exemple : `quest.professor.progress`.

## Action Kind
- Choix de l’action du node `Action`.
- Utilise un preset humainement lisible.

## Message
- Texte court direct.
- Exemple : `Le professeur n'est pas encore prêt.`

## Condition
- Test logique de branche.
- Modes guidés : flag actif, flag inactif, event consommé, variable égale, JSON brut.

## 5. Action Kind — tableau de référence

| Action | Signification | Champs requis |
|---|---|---|
| Afficher un message | Affiche un texte court | Message |
| Ouvrir un dialogue | Lance un dialogue Yarn | Dialogue |
| Exécuter un script | Lance une procédure runtime | Script |
| Démarrer un combat dresseur | Prépare un combat trainer | Trainer |
| Cibler un event de map | Lie/active un event existant | Map + Event ID |
| Déclencher un warp | Lie/active un warp existant | Map + Warp ID |
| Activer un trigger | Lie/active un trigger existant | Map + Trigger ID |
| Cibler une entité | Lie une entité existante | Map + Entity ID |
| Activer un flag | Met un flag à vrai | Flag Name |
| Désactiver un flag | Met un flag à faux | Flag Name |
| Custom / avancé | Cas non couvert par presets | Raw/avancé |

Conseil :
- commence par un preset standard,
- n’utilise `Custom / avancé` qu’en dernier recours.

## 6. Exemples pas à pas

## Exemple 1 — séquence minimale

Objectif :
- `Start -> Dialogue -> End`

Étapes :
1. Crée un node `Start`.
2. Crée un node `Dialogue` avec un `Dialogue Yarn`.
3. Crée un node `End`.
4. Relie `Start -> Dialogue -> End`.

## Exemple 2 — combat dresseur

Objectif :
- `Start -> Action(startTrainerBattle) -> End`

Étapes :
1. Node `Action`.
2. Action = `Démarrer un combat dresseur`.
3. Choisis `Trainer`.
4. Relie vers `End`.

## Exemple 3 — condition binaire

Objectif :
- `Start -> Condition(flag set?) -> branche A / branche B`

Étapes :
1. Node `Condition`.
2. Mode = `Flag actif`.
3. Flag = `story.got_starter`.
4. Ajoute deux sorties :
   - vers branche progression,
   - vers branche blocage.

## Exemple 4 — interaction liée à la map

Objectif :
- lier un point scénario à un event map.

Étapes :
1. Node `Reference`.
2. Type de référence = `Référence event`.
3. Choisis `Map`.
4. Choisis `Event ID` filtré automatiquement.

## Exemple 5 — mini scénario complet

Objectif :
- intro + choix + condition + fin.

Structure :
1. `Start`
2. `Dialogue` (intro)
3. `Choice` (Oui / Non)
4. Branche Oui -> `Action(setFlag)` -> `End`
5. Branche Non -> `Dialogue` (blocage) -> `End`

## 7. Comment choisir les bonnes ressources

Ordre recommandé :
1. Choisis d’abord la **Map** si ton node cible le monde.
2. Puis choisis la ressource dépendante :
   - Event / Entity / Warp / Trigger.
3. Pour narration :
   - prends d’abord `Dialogue`,
   - ajoute `Script` seulement si logique supplémentaire.

Bon réflexe :
- si tu hésites entre Script et Dialogue, commence par Dialogue.

## 8. Erreurs fréquentes

- Remplir tous les champs “au cas où”.
- Utiliser `Action` pour des cas purement narratifs simples.
- Choisir une map puis oublier de rafraîchir la cible dépendante.
- Empiler trop de logique dans un seul node.
- Oublier d’ajouter deux sorties à un `Condition`.

## 9. Workflow recommandé

1. Prépare d’abord les ressources monde (maps/events/entities/warps/triggers).
2. Prépare les dialogues Yarn.
3. Prépare les scripts réutilisables.
4. Construis le graphe scénario.
5. Relie progressivement les branches.
6. Teste des flux simples.
7. Complexifie ensuite.

Règle pratique :
- “petit graphe propre” > “gros graphe confus”.

## 10. Cheatsheet rapide

- Faire parler un personnage : `Dialogue`.
- Déclencher un combat : `Action` + `Démarrer un combat dresseur`.
- Poser une règle de progression : `Condition`.
- Donner un choix joueur : `Choice`.
- Lier un event/warp/trigger : `Reference` + `Map` + cible.
- Terminer une branche : `End`.

---

Si tu débutes :
- commence par `Start -> Dialogue -> End`,
- puis ajoute un seul `Condition`,
- puis seulement ensuite des `Action` avancées.
