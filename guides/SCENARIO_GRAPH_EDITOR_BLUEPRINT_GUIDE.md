# Scenario Graph Editor — Guide Blueprint-like (Authoring Humain)

## 1) Pourquoi ce guide existe

Le `Scenario Graph Editor` n’est pas un simple éditeur de champs techniques.  
Son but est de te laisser **penser en gameplay et narration**:

- qu’est-ce qui déclenche la séquence ?
- quelle condition décide de la branche ?
- quelle action est exécutée ?
- quel dialogue est montré ?
- comment la branche se termine ?

Ce guide t’explique comment travailler avec cette logique, sans te noyer dans les IDs bruts.

---

## 2) Le mental model à retenir

Pense toujours ton flow dans cet ordre:

1. **Source / Trigger**
2. **Condition** (optionnelle)
3. **Effet / Action** ou **Dialogue**
4. **Choice** (si choix joueur)
5. **End**

Le graphe te permet d’orchestrer visuellement ces étapes.

---

## 3) Différence entre bibliothèques

### Dialogue Library
Contenu Yarn (texte/dialogues).

### Scenario Scripts
Procédures runtime réutilisables (logique script).

### Scenario Graphs
Orchestration visuelle de haut niveau (sources, branches, effets, fins).

### World Maps
Contenu monde concret:
- events
- entités
- warps
- triggers

---

## 4) Honnêteté runtime: ce qui est réellement exécuté aujourd’hui

Le graphe scénario est maintenant **partiellement branché au runtime** (MVP).

### Exécuté en runtime (MVP)
- source `sourceMapEnter` (entrée map) ;
- source `sourceTriggerEnter` (entrée trigger) ;
- source `sourceEntityInteract` (interaction entité/PNJ) ;
- node `Dialogue` (dialogueId ou message inline) ;
- node `Action` avec:
  - `runScript`
  - `openDialogue`
  - `showMessage`
  - `setFlag`
  - `clearFlag`
- node `Condition` (évaluation via `ScriptConditionEvaluator`) ;
- node `End`.

### Non exécuté automatiquement (pour l’instant)
- `Choice` (authoring-only dans le bridge MVP) ;
- `Reference` hors presets source ;
- actions non supportées (ex: `startTrainerBattle`, `triggerWarp`, etc.).

Lis toujours le statut affiché dans l’inspecteur et les diagnostics:
- exécutable runtime,
- authoring-only,
- prévu plus tard.

---

## 5) Types de nodes (version simple)

## Start
Point d’entrée du flow.

Utilise-le pour:
- démarrer la séquence.

Évite:
- d’en créer plusieurs.

## Dialogue
Étape de narration/dialogue.

Utilise-le pour:
- ouvrir un dialogue Yarn,
- ou lier un script/message de narration.

## Action
Effet gameplay/narratif.

Utilise-le pour:
- ouvrir un dialogue,
- exécuter un script,
- démarrer un combat dresseur,
- activer/désactiver un flag,
- cibler un event/trigger/warp/entité.

## Condition
Test booléen qui bifurque.

Utilise-le pour:
- flag actif/inactif,
- event consommé,
- joueur sur map,
- variable égale,
- JSON brut (avancé).

## Choice
Choix joueur à plusieurs branches.

Utilise-le pour:
- Oui / Non / Plus tard, etc.

## Reference
Lien explicite vers ressource monde/projet.  
Peut aussi jouer un rôle de **Source** via presets de déclencheur.

## End
Fin de branche.

---

## 6) Action Kind (important)

Dans un node Action (ou Reference), commence par choisir un preset.

Exemples utiles:

- **Afficher un message**
- **Ouvrir un dialogue**
- **Exécuter un script**
- **Démarrer un combat dresseur**
- **Cibler un event de map**
- **Utiliser un warp**
- **Activer un trigger**
- **Cibler une entité**
- **Activer un flag**
- **Désactiver un flag**

Le preset affiche uniquement les champs pertinents.

---

## 7) Map context intelligent

Quand tu choisis une map:

- les pickers `Event / Entity / Warp / Trigger` sont filtrés,
- tu vois le contenu de map (compteurs + aperçu IDs),
- si la map n’a pas d’éléments du type demandé, l’UI te le dit clairement.

Workflow conseillé:

1. Choisis la map.
2. Choisis la ressource filtrée.
3. Vérifie le résumé du node.

---

## 8) Recettes Blueprint (assistants de composition)

Les recettes créent des mini-flows prêts à l’emploi:

- Entrée map → dialogue
- Entrée trigger → dialogue
- Interaction entité/PNJ → script
- Combat dresseur
- Condition flag A/B

Avant insertion, choisis le mode:

- **Insérer en parallèle**: garde les sorties existantes.
- **Remplacer les sorties existantes**: nettoie le flow à partir du node courant.
- **Chaîner avant la sortie existante**: insère le mini-flow puis reconnecte la fin à l’ancienne cible (si possible).

Astuce: pour un graphe propre, “Remplacer” est souvent le meilleur choix.

---

## 9) Cas d’usage pas à pas

## Cas A — Entrée map → dialogue

1. Sélectionne un node source (souvent `Start`).
2. Lance la recette **Entrée map → dialogue**.
3. Choisis la map.
4. Choisis le dialogue.
5. Choisis le mode d’insertion (recommandé: **Remplacer** si flow initial vide).
6. Vérifie le flow généré:
   - Source `sourceMapEnter`
   - Dialogue
   - End
7. Teste en runtime: l’entrée sur la map ciblée doit ouvrir le dialogue.

## Cas B — Entrée zone/trigger → dialogue

1. Recette **Entrée trigger → dialogue**.
2. Choisis map puis trigger.
3. Choisis dialogue.
4. Vérifie la source `sourceTriggerEnter`.
5. Teste en runtime: en entrant dans la zone trigger, le dialogue s’ouvre.

## Cas C — Parler à un PNJ → script

1. Recette **Interaction entité → script**.
2. Choisis map puis entité.
3. Choisis script.
4. Vérifie:
   - source `sourceEntityInteract`
   - action `runScript`
   - end.
5. Teste en runtime: interaction avec l’entité ciblée -> script lancé.

## Cas D — Combat dresseur (authoring aujourd’hui)

1. Recette **Combat dresseur**.
2. Choisis trainer.
3. Vérifie le node Action `startTrainerBattle`.
4. Note: ce preset reste un pont d’authoring tant qu’il n’est pas ajouté au bridge runtime scénario.

## Cas E — Condition flag

1. Recette **Condition flag A/B**.
2. Choisis un flag existant ou saisis-en un.
3. Vérifie les branches `Vrai` / `Faux`.

---

## 10) Mode advanced (assisté + brut)

Le mode advanced n’est plus “raw only”.

Tu as:

- des pickers assistés (script/dialogue/map/event/entity/warp/trigger/trainer),
- des suggestions pour flags/variables,
- et les champs raw en fallback expert.

Règle simple:
- utilise d’abord l’assisté,
- garde le raw pour les cas spéciaux.

---

## 11) Lire le diagnostic du scénario

Le panneau diagnostic te donne:

- nodes atteignables / non atteignables,
- nodes incomplets,
- cul-de-sac,
- nodes isolés,
- répartition runtime/authoring/planned.
- alertes d’exécutabilité (node atteignable mais non exécutable dans le MVP).

Et pour le node sélectionné:
- erreurs,
- avertissements,
- connectivité (entrées/sorties),
- statut d’exécution.

---

## 12) Erreurs fréquentes

- laisser un node Action sans preset;
- oublier de choisir map avant event/entity/warp/trigger;
- créer une Condition avec une seule sortie;
- oublier un End final;
- laisser des branches orphelines après plusieurs essais de recettes;
- supposer qu’un `Choice` est déjà géré par le runtime scénario (ce n’est pas encore le cas).

---

## 13) Cheatsheet runtime MVP

- Entrée map -> dialogue: `sourceMapEnter -> Dialogue -> End`
- Entrée trigger -> dialogue: `sourceTriggerEnter -> Dialogue -> End`
- Interaction PNJ/entité -> script: `sourceEntityInteract -> Action(runScript) -> End`
- Brancher sur flag: `Condition(flagSet/flagUnset)` + edges vrai/faux
- Si un node est marqué authoring-only: le flow visuel est valide, mais pas encore auto-exécuté en runtime.
- penser qu’un flow authoring est forcément auto-exécuté en runtime.

---

## 13) Workflow recommandé

1. Définis l’intention gameplay (source → effet).
2. Utilise une recette proche du cas.
3. Choisis la stratégie d’insertion (append/replace/chain).
4. Renseigne les ressources via pickers.
5. Vérifie le diagnostic.
6. Corrige les nodes incomplets.
7. Ajoute conditions/choices si besoin.
8. Termine toutes les branches avec End.

---

## 14) Cheatsheet rapide (“si tu veux X, fais Y”)

- Faire parler un PNJ: `sourceEntityInteract` → `Dialogue` (ou `Action/openDialogue`) → `End`.
- Déclencher un script à l’interaction: `sourceEntityInteract` → `Action/runScript` → `End`.
- Déclencher au passage dans une zone: `sourceTriggerEnter` → `Dialogue/Action` → `End`.
- Déclencher à l’entrée d’une map: `sourceMapEnter` → `Dialogue/Action` → `End`.
- Brancher sur un flag: `Condition(flag)` + 2 sorties minimum.
- Proposer un choix joueur: `Choice` + labels de branches.
- Terminer proprement: ajoute `End` sur chaque branche terminale.

---

## 15) Limites actuelles (transparentes)

- Le graphe scénario n’est pas encore une source d’exécution automatique complète côté runtime.
- Certains presets servent surtout de pont d’authoring/orchestration.
- Les diagnostics aident à éviter les flows incohérents, mais ne remplacent pas encore un compilateur de scénario complet.

---

## 16) Conclusion

Utilise le graphe comme un **Blueprint narratif/gameplay**:

- explicite la source,
- garde les branches lisibles,
- choisis les ressources via pickers,
- surveille le diagnostic,
- et reste conscient du statut runtime affiché.

Tu obtiens un authoring plus humain, plus clair, et plus maintenable.
