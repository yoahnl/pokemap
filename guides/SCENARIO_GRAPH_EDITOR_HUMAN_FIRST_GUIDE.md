# Scenario Graph Editor — Guide Humain (Mode Visual Scripting)

Ce guide est écrit pour une personne qui veut créer un RPG Pokémon-like sans devoir penser en JSON ni en IDs internes.

## 1. C’est quoi le Scenario Graph ?

Le Scenario Graph est la surface où tu organises la logique de scène :

- ce qui déclenche une étape,
- ce qui est vérifié,
- ce qui se passe ensuite,
- où le flow se termine.

Le graphe te sert à répondre à des questions simples :
- “quand le joueur entre ici, que se passe-t-il ?”
- “si ce flag est actif, je vais où ?”
- “quand on parle à ce PNJ, je lance quoi ?”

## 2. Différence entre les bibliothèques (très important)

## Dialogue Library
Contient le texte/dialogue Yarn.

## Scenario Scripts
Contient des scripts runtime réutilisables.

## Scenario Graphs
Contient l’orchestration visuelle (le flow).

## World Maps
Contient les assets monde : events, entités, warps, triggers.

Résumé :
- dialogue = contenu parlé,
- script = logique,
- map = contexte monde,
- graph = orchestration.

## 3. Comment raisonner “Blueprint-like”

Pense chaque node comme une responsabilité unique :

- **Source / Trigger** : d’où vient l’activation,
- **Condition** : quel test est appliqué,
- **Action / Dialogue** : quel effet est exécuté,
- **Choice** : quel choix joueur bifurque le flow,
- **End** : où la branche se termine.

Bon réflexe :
- éviter les nodes “fourre-tout”.

## 4. Les types de nodes (version simple)

## Start
Point de départ global.

## Dialogue
Joue un dialogue ou une étape de narration.

## Action
Exécute un effet concret (script, trainer battle, set flag, etc.).

## Condition
Teste une règle (flag, map, event consommé, variable).

## Choice
Propose un choix avec plusieurs branches.

## Reference
Lie explicitement le flow à une ressource monde.

Astuce :
- certains presets de `Reference` servent de **source/déclencheur** (entrée map, entrée trigger, interaction entité).

## End
Termine une branche.

## 5. Action Kind sans jargon

Dans un node Action, `Action Kind` répond à :
**“Qu’est-ce que je veux faire exactement ?”**

Exemples :
- Ouvrir un dialogue
- Exécuter un script
- Démarrer un combat dresseur
- Activer un flag
- Désactiver un flag

Le panneau affiche ensuite uniquement les champs nécessaires.

## 6. Source vs Exécution (ne plus confondre)

Cas fréquent :
- `Reference` preset “Déclencheur : entrée trigger” = **source**.
- `Action` preset “Ouvrir un dialogue” = **effet**.

Tu relies les deux dans le graphe :
- Source -> Effet.

## 7. Les dropdowns intelligents

Tu n’as pas besoin de taper des IDs partout.

Flow recommandé :
1. Choisis la map.
2. Choisis ensuite Event/Entity/Warp/Trigger filtré automatiquement.

Si tu n’as pas choisi de map :
- ces champs sont désactivés avec un message clair.

## 8. Cas d’usage prêts à l’emploi

Le panneau propose des recettes “Blueprint” :

- Entrée map -> dialogue
- Entrée trigger -> dialogue
- Parler PNJ -> script
- Combat dresseur
- Condition flag A/B

Ces recettes créent automatiquement un mini-flow node + edges.

## 9. Cas concret 1 — Entrée map -> dialogue

Objectif :
- quand le joueur arrive sur `vova_east`, lancer `dialogue_intro`.

Méthode :
1. Sélectionne un node de départ.
2. Clique la recette `Entrée map -> dialogue`.
3. Choisis la map.
4. Choisis le dialogue.
5. Le flow est généré (source + dialogue + edges).

## 10. Cas concret 2 — Entrée dans une zone -> dialogue

Objectif :
- trigger `trigger_intro_start` lance un dialogue.

Méthode :
1. Recette `Entrée trigger -> dialogue`.
2. Choisis map.
3. Choisis trigger.
4. Choisis dialogue.

## 11. Cas concret 3 — Parler à un PNJ -> script

Objectif :
- interaction sur `npc_professor` lance `script_professor_intro`.

Méthode :
1. Recette `Parler PNJ -> script`.
2. Choisis map.
3. Choisis entité.
4. Choisis script.

## 12. Cas concret 4 — Combat dresseur

Objectif :
- arriver à un node déclenche un combat trainer.

Méthode :
1. Recette `Combat dresseur`.
2. Choisis trainer.
3. Relie ensuite vers dialogue ou end.

## 13. Cas concret 5 — Condition flag

Objectif :
- si `story.got_starter` alors branche A sinon branche B.

Méthode :
1. Recette `Condition flag A/B`.
2. Choisis un flag connu ou saisis-le.
3. Le node condition + 2 branches sont créés.
4. Remplace les End temporaires par tes vraies suites.

## 14. “Contexte map” : lire ce qui existe

Quand une map est choisie, le panneau affiche :
- nombre d’events,
- nombre d’entités,
- nombre de warps,
- nombre de triggers.

But :
- comprendre immédiatement ce que tu peux cibler.

## 15. Flags et variables : différence

## Flag
Booléen (actif/inactif) de progression.

## Variable
Valeur évolutive (ex: `quest.professor.progress = 2`).

Le panneau propose des suggestions quand des noms existent déjà.

## 16. Authoring vs runtime (honnêteté)

Le panneau affiche le niveau de support des presets :
- exécution runtime réelle,
- authoring/orchestration,
- préparation future.

Cela évite de confondre :
- ce qui est déjà exécuté par le runtime,
- ce qui sert surtout à structurer la logique auteur.

## 17. Erreurs fréquentes

- Mélanger “source” et “action”.
- Remplir des champs techniques en mode avancé sans nécessité.
- Oublier de choisir map avant les cibles map-scoped.
- Utiliser `custom` trop tôt.
- Créer des nodes énormes au lieu de chaînes simples.

## 18. Workflow recommandé

1. Prépare les ressources monde (map/events/entities/warps/triggers).
2. Prépare dialogues et scripts.
3. Construis le flow avec les recettes.
4. Affine les conditions.
5. Nettoie les labels d’edges.
6. Teste des petits scénarios avant de complexifier.

## 19. Cheatsheet “Si tu veux X, fais Y”

- Entrée map -> dialogue : recette correspondante.
- Entrée zone -> dialogue : recette trigger -> dialogue.
- PNJ -> script : recette PNJ -> script.
- Combat trainer : Action + trainer (ou recette).
- Test progression : node Condition.
- Choix joueur : node Choice + labels d’edges.
- Fin de branche : node End.

## 20. Mini checklist qualité avant validation

- Est-ce que je comprends chaque node sans lire le raw ?
- Est-ce que les nodes map-scoped ont une map sélectionnée ?
- Est-ce que les conditions ont des branches claires ?
- Est-ce que les edges ont des labels lisibles (Oui/Non, Vrai/Faux, etc.) ?
- Est-ce que j’ai distingué Source et Effet ?

---

Si tu débutes :
- commence par les recettes,
- puis ajuste manuellement.

C’est la manière la plus rapide d’obtenir un flow propre, compréhensible, et maintenable.
