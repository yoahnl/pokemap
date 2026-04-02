# Scenario Graph — Guide Story-Centric (Global + Local)

## 1. Pourquoi ce guide existe

Le Scenario Graph n’est plus pensé comme une collection d’events locaux isolés.

Le modèle cible est maintenant **story-centric** :

- un **graphe global** pilote la progression principale,
- des **flows locaux** (hooks monde) déclenchent des séquences concrètes,
- des **outcomes explicites** relient local et global.

Ce guide explique comment authorer ce modèle de façon claire et reproductible.

---

## 2. Mental Model (à retenir absolument)

### 2.1 Global Story Graph

Le scénario global représente la progression principale du jeu :

- chapitres,
- milestones,
- branches majeures,
- transitions narratives.

Dans l’éditeur, il est recommandé de créer ce scénario avec le scope :

- `Global Story Graph`

### 2.2 Local Event Flow

Un flow local représente un hook gameplay concret :

- entrée sur map,
- entrée dans un trigger,
- interaction avec une entité/PNJ.

Dans l’éditeur, ce scénario utilise le scope :

- `Local Event Flow`

### 2.3 Outcome

Un outcome est un résultat explicite produit par un flow local.

Exemples :

- `professor_intro.completed`
- `starter.selected.fire`
- `rival_1.defeated`

Un flow local **émet** un outcome.
Le graphe global peut ensuite le **consommer**.

---

## 3. Ce qui est exécuté en runtime (MVP actuel)

### 3.1 Sources runtime supportées

- `sourceMapEnter`
- `sourceTriggerEnter`
- `sourceEntityInteract`
- `sourceOutcome`

### 3.2 Actions runtime supportées

- `openDialogue`
- `runScript`
- `showMessage`
- `setFlag`
- `clearFlag`
- `emitOutcome`

### 3.3 Nœuds non encore exécutés complètement

- `Choice` (bloqué explicitement par l’exécuteur MVP)
- `Reference` hors mode `source*` (authoring/documentation)
- action kinds non supportés explicitement

---

## 4. Structure recommandée d’un projet

## 4.1 Un scénario global principal

Crée un `ScenarioAsset` en scope `Global Story Graph`.

Ce scénario doit contenir :

- des `sourceOutcome`,
- des `Condition`,
- des `Dialogue`/`Action`,
- des `End`.

## 4.2 Plusieurs scénarios locaux

Crée des `ScenarioAsset` en scope `Local Event Flow`.

Chaque scénario local démarre sur un hook monde (`sourceMapEnter`, `sourceTriggerEnter`, `sourceEntityInteract`) puis émet un outcome via `emitOutcome`.

---

## 5. Comment créer un flow local propre

### Objectif

Quand le joueur parle au professeur, on veut produire :

- `professor_intro.completed`

### Étapes

1. Crée un scénario `local_professor_intro` en scope `Local Event Flow`.
2. Ajoute une source:
   - node `Reference`
   - preset `Déclencheur : interaction PNJ/entité` (`sourceEntityInteract`)
   - renseigne `mapId` + `entityId`.
3. Ajoute un node `Dialogue` ou `Action/runScript`.
4. Ajoute un node `Action` preset `Émettre un outcome` (`emitOutcome`).
5. Renseigne `Outcome ID = professor_intro.completed`.
6. Relie les nodes.

Résultat :

- le flow local est déclenché par le monde,
- il émet un outcome persistant.

---

## 6. Comment brancher le global sur un outcome local

### Objectif

Après `professor_intro.completed`, ouvrir un dialogue global.

### Étapes

1. Ouvre le scénario global (scope `Global Story Graph`).
2. Ajoute un node `Reference`.
3. Choisis preset `Source : outcome reçu` (`sourceOutcome`).
4. Renseigne `Outcome ID = professor_intro.completed`.
5. Ajoute un node `Dialogue` avec le dialogue cible.
6. Connecte `sourceOutcome -> Dialogue -> End`.

Résultat :

- quand le local émet l’outcome, le global peut enchaîner.

---

## 7. Exemple complet — Professeur + Starter

## 7.1 Flow local professeur

- `sourceEntityInteract(map=vova_east, entity=npc_professor)`
- `dialogue(professor_intro)`
- `emitOutcome(professor_intro.completed)`

## 7.2 Flow global

- `sourceOutcome(professor_intro.completed)`
- `dialogue(starter_selection_intro)`
- `condition(flag story.got_starter ?)`

Branches :

- vrai -> `end_progress_ready`
- faux -> `dialogue(reminder_pick_starter)` -> `end_waiting_starter`

## 7.3 Flow local sélection starter

- hook local (interaction/table/trigger selon ton map design)
- script qui pose `story.got_starter`
- `emitOutcome(starter.selected.fire|water|grass)` selon choix

## 7.4 Flow global suite

- `sourceOutcome(starter.selected.fire)` -> branche Fire
- `sourceOutcome(starter.selected.water)` -> branche Water
- `sourceOutcome(starter.selected.grass)` -> branche Grass

---

## 8. Conditions et gating de scénario

Chaque scénario peut définir une `activationCondition` (JSON ScriptCondition).

Usage typique :

- empêcher un flow local de se déclencher tant qu’un chapitre global n’est pas ouvert,
- activer/désactiver des hooks monde selon la progression.

Exemple :

```json
{
  "type": "flagIsSet",
  "params": {
    "flagName": "story.chapter_1_started"
  }
}
```

---

## 9. Outcomes déclarés (champ scénario)

Le champ `declaredOutcomes` sert à documenter/normaliser les outcomes utilisés par un scénario.

Bonnes pratiques :

- garde un namespace stable (`quest.professor.*`, `starter.selected.*`),
- évite les noms vagues (`done`, `ok`, `step2`),
- réutilise les mêmes IDs entre local et global.

---

## 10. Nommage recommandé

### Scénarios

- `global_main_story`
- `local_professor_intro`
- `local_route1_trigger_start`

### Outcomes

- `professor_intro.completed`
- `starter.selected.fire`
- `rival_1.defeated`
- `parcel.delivered`

### Flags de progression (si nécessaires)

- `story.chapter_1_started`
- `story.got_starter`

---

## 11. Recettes rapides utiles

Dans l’inspecteur, les recettes peuvent accélérer l’authoring :

- `Entrée map -> dialogue`
- `Entrée trigger -> dialogue`
- `Parler PNJ -> script`
- `Entrée map -> outcome`
- `Outcome -> dialogue global`

Recommandation :

- utilise les recettes pour poser une base,
- nettoie ensuite les labels/edges,
- vérifie le diagnostic du scénario.

---

## 12. Erreurs fréquentes

### 12.1 Tout mettre dans un seul scénario local

Erreur : la progression globale devient illisible.

Fix :

- garde le global séparé,
- fais remonter des outcomes depuis les locaux.

### 12.2 Oublier l’Outcome ID sur `emitOutcome` / `sourceOutcome`

Erreur bloquante : le flow ne peut pas router correctement.

Fix :

- renseigne toujours `outcomeId`,
- ajoute aussi l’outcome dans `declaredOutcomes`.

### 12.3 Mélanger scope et rôle

Erreur :

- scénario global avec `sourceMapEnter`,
- scénario local avec `sourceOutcome`.

Fix :

- hooks monde -> local,
- outcomes -> global.

### 12.4 Utiliser Choice comme si c’était déjà runtime-ready

Actuellement, `Choice` n’est pas entièrement exécuté par l’exécuteur MVP.

Fix :

- garde `Choice` pour authoring/planification,
- utilise conditions/actions supportées pour le runtime réel.

---

## 13. Checklist “flow exécutable maintenant”

Avant test runtime, vérifie :

- le scénario local a un hook source valide (`sourceMapEnter`/`sourceTriggerEnter`/`sourceEntityInteract`),
- les IDs map/trigger/entity existent vraiment,
- le dialogue/script référencé existe,
- `emitOutcome` a un `outcomeId`,
- le scénario global écoute cet outcome via `sourceOutcome`,
- les nœuds critiques sont marqués “Exécution réelle” dans l’inspecteur.

---

## 14. Ce que le système ne fait pas encore complètement

- exécution complète des `Choice` en runtime scénario MVP,
- orchestration globale avancée type quest-system complet,
- pilotage exhaustif et automatique de tous les contenus monde.

Le MVP actuel apporte un pont réel :

- hooks monde locaux -> outcomes -> transitions globales.

---

## 15. Cheatsheet finale

- “Entrer sur map -> dialogue” :
  - local `sourceMapEnter` -> `Dialogue`
- “Entrer dans zone -> dialogue” :
  - local `sourceTriggerEnter` -> `Dialogue`
- “Parler à PNJ -> script” :
  - local `sourceEntityInteract` -> `Action(runScript)`
- “Faire progresser l’histoire globale” :
  - local `emitOutcome(x)` + global `sourceOutcome(x)`
- “Bloquer/débloquer un flow local” :
  - `activationCondition` sur le scénario local
- “Brancher selon progression” :
  - `Condition` avec flags/variables/outcomes persistés

---

Ce guide décrit l’état MVP branché runtime + authoring actuel.
Pour les futures étapes (choice runtime complet, executor plus riche, quest orchestration), garde cette séparation centrale :

- **Local = hooks concrets du monde**
- **Global = progression narrative du jeu**
