# Scenario Graph Editor — Guide Pratique Complet

Ce guide explique, pas à pas, comment utiliser le Scenario Graph Editor de façon concrète, même si tu débutes.

## 1. C’est quoi le Scenario Graph ?

Le **Scenario Graph** est l’espace central pour orchestrer la progression narrative de ton jeu.

Il sert à définir :
- le point de départ d’une séquence,
- les dialogues,
- les actions gameplay,
- les tests de conditions,
- les embranchements,
- les références vers le monde (maps/events/entities/warps/triggers/trainers).

Le graphe n’est pas juste “technique” : c’est ta **vue de direction narrative**.

## 2. Différences entre les bibliothèques

## Dialogue Library
- Contient les dialogues Yarn.
- Sert pour le texte et les échanges.

## Scenario Scripts
- Contient des scripts runtime réutilisables.
- Sert pour la logique procédurale.

## Scenario Graphs
- Sert à orchestrer l’enchaînement global.
- Relie dialogues, scripts et monde.

## World Maps
- Contient les maps et leur contenu : events, entités, warps, triggers.
- Sert de cible concrète pour les nodes de type Action/Reference.

Raccourci mental :
- Dialogue = contenu parlé
- Script = logique
- Map = contexte monde
- Graph = orchestration

## 3. Types de nodes ultra clairs

## Start
- Rôle : point d’entrée du scénario.
- Utilisation : toujours un seul Start par scénario.
- À remplir : titre/description seulement.

## Dialogue
- Rôle : jouer un dialogue.
- Utilisation : scène parlée, narration, exposition.
- À remplir en priorité : Dialogue Yarn.
- Optionnel : script, message inline.

## Action
- Rôle : déclencher une action.
- Utilisation : combat dresseur, script, flag, ciblage map/event/warp/trigger.
- À remplir en priorité : Action Kind + champs qui apparaissent.

## Condition
- Rôle : tester une condition et bifurquer.
- Utilisation : progression avec flags, variables, events consommés, map active.
- À remplir en priorité : mode de condition + paramètres liés.

## Choice
- Rôle : choix multi-branches.
- Utilisation : “Oui/Non/Plus tard”, choix narratif.
- À remplir en priorité : labels d’edges sortants.

## Reference
- Rôle : lier explicitement un node à une ressource existante.
- Utilisation : pointer vers map/event/entity/warp/trigger/trainer/dialogue/script.
- À remplir en priorité : Type de référence + cible.

## End
- Rôle : fin de branche.
- Utilisation : clôturer proprement une séquence.
- À remplir : titre/description seulement.

## 4. Action Kind — ce que ça veut dire concrètement

`Action Kind` sert à choisir l’effet d’un node Action.

Le principe :
1. Tu choisis une action lisible.
2. L’UI affiche uniquement les champs nécessaires.

## Actions disponibles

- **Afficher un message**
  - Champs : Message
  - Usage : feedback simple au joueur.

- **Ouvrir un dialogue**
  - Champs : Dialogue
  - Usage : séquence parlée.

- **Exécuter un script**
  - Champs : Script
  - Usage : logique runtime réutilisable.

- **Démarrer un combat dresseur**
  - Champs : Trainer
  - Usage : combat scénarisé.

- **Cibler un event de map**
  - Champs : Map + Event
  - Usage : lier le flux à un event existant.

- **Utiliser un warp**
  - Champs : Map + Warp
  - Usage : transition liée à un warp.

- **Activer un trigger**
  - Champs : Map + Trigger
  - Usage : lier une activation de trigger.

- **Cibler une entité**
  - Champs : Map + Entity
  - Usage : cibler un PNJ/objet entité existant.

- **Activer un flag / Désactiver un flag**
  - Champs : Flag Name
  - Usage : progression scénario.

- **Custom / avancé**
  - Usage : cas expert non couvert.
  - Conseil : éviter tant qu’un preset standard suffit.

## 5. Lier une map à ses ressources

Quand une action/référence dépend du monde :

1. Choisis d’abord **Map**.
2. Ensuite choisis la ressource liée :
   - Event
   - Entity
   - Warp
   - Trigger

Les dropdowns sont filtrés automatiquement par map.

Exemples de labels affichés :
- `event_intro_lab — actor — (8,8)`
- `npc_professor — npc — (10,4)`
- `lab_entry — (3,12) -> vova_center`
- `trigger_intro_start — box — area (x,y,w,h)`

Si tu n’as pas choisi de map :
- les champs dépendants sont désactivés,
- l’éditeur te demande explicitement de choisir une map.

## 6. Cas concret : “Entrer dans une zone -> lancer un dialogue”

Flux recommandé :
1. `Start`
2. `Condition` (optionnel, si tu veux filtrer par flag/map)
3. `Action` avec `Ouvrir un dialogue`
4. `End`

Si la zone est un trigger map :
1. Ajoute un node `Reference` (preset “Référence trigger”) pour documenter la source monde.
2. Ajoute un node `Action` (`Ouvrir un dialogue`) pour l’effet narratif.

Astuce :
- garde `Reference` pour le lien monde,
- garde `Action` pour l’effet concret.

## 7. Cas concret : “Parler à un PNJ -> lancer une séquence”

Structure simple :
1. `Start`
2. `Reference` (map + entity PNJ)
3. `Dialogue` ou `Action` (`Exécuter un script`)
4. `End`

Quand choisir quoi :
- conversation simple -> node `Dialogue`
- logique plus riche -> node `Action` + `Run script`

## 8. Cas concret : combat de dresseur

Structure :
1. `Start`
2. `Action` : `Démarrer un combat dresseur`
3. `Trainer` : choisir le dresseur
4. `End` ou branche conditionnelle post-combat

Conseil :
- ajoute un `Condition` derrière si tu veux brancher selon progression (flag).

## 9. Cas concret : condition sur flag

Structure :
1. `Start`
2. `Condition` : `Flag actif` ou `Flag inactif`
3. Branche A (progression)
4. Branche B (blocage)

Flag exemple :
- `story.got_starter`

## 10. Cas concret : choix multi-branches

Structure :
1. `Start`
2. `Choice`
3. Au moins 2 edges sortants
4. Label de chaque edge (Oui / Non / Plus tard)

Ensuite :
- chaque branche mène vers dialogue/action/end.

## 11. Séquence complète type (petit scénario)

Exemple :
1. `Start`
2. `Dialogue` (intro)
3. `Choice` (Accepter mission ?)
4. Branche Oui -> `Action(setFlag)` -> `Dialogue` confirmation -> `End`
5. Branche Non -> `Dialogue` refus -> `End`

Ce pattern est solide pour démarrer.

## 12. Erreurs fréquentes

- Mettre trop de logique dans un seul node.
- Remplir des champs non pertinents “au cas où”.
- Utiliser `Action` quand un simple `Dialogue` suffit.
- Oublier de choisir la map avant Event/Entity/Warp/Trigger.
- Oublier d’avoir au moins 2 sorties pour Condition/Choice.
- Utiliser `Custom` trop tôt.

## 13. Workflow recommandé

Ordre conseillé :
1. Préparer les maps et le contenu monde.
2. Préparer dialogues Yarn.
3. Préparer scripts réutilisables.
4. Construire le graphe scénario.
5. Ajouter branches/conditions progressivement.
6. Tester des petits flux, puis complexifier.

## 14. Cheatsheet finale “Si tu veux X, fais Y”

- Faire parler un personnage :
  - `Dialogue` + sélection Dialogue.

- Lancer une logique personnalisée :
  - `Action` + `Exécuter un script`.

- Déclencher un combat :
  - `Action` + `Démarrer un combat dresseur` + Trainer.

- Faire un embranchement logique :
  - `Condition`.

- Proposer un choix joueur :
  - `Choice` + labels d’edges.

- Lier le scénario à un élément existant de map :
  - `Reference` + Map + cible.

- Terminer une branche :
  - `End`.

---

Si tu débutes vraiment :
- commence par `Start -> Dialogue -> End`,
- puis ajoute un `Condition`,
- puis ajoute des `Action` avec ressources map.

C’est la façon la plus simple d’éviter un graphe confus.
