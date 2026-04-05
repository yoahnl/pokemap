# Step Studio — refonte produit & architecture (PokeMap Narrative Studio)

**Date :** 2026-04-05  
**Périmètre :** vue **Step Studio** uniquement (`StepStudioWorkspace` et modules `step_studio/*`), données `step_studio_authoring.dart`, câblage minimal depuis `NarrativeWorkspaceCanvas`.

---

## 1. Pourquoi les tentatives « mini Cutscene » ou « mini Global Story » échouent

### 1.1 Copier Cutscene Studio pour une Step

**Cutscene Studio** répond à la question : *comment la scène s’exécute-t-elle ?*  
Blocs naturels : dialogue, déplacement, caméra, attente, choix UI, enchaînement de nœuds, flags techniques d’exécution.

**Step Studio** doit répondre à : *que doit accomplir le joueur pour faire avancer l’histoire à l’échelle de cette étape ?*  
Blocs naturels : entrée métier, objectif, validation, outcomes attendus, rattachement de scènes par **rôle**, branches **métier** (pas branches de bloc `if camera`), sortie vers la suite.

Si l’UI Step affiche une timeline ou des primitives d’exécution, trois problèmes apparaissent :

1. **Double édition** : le créateur configure la même vérité à deux endroits (cutscene + step), avec risque de divergence.
2. **Charge cognitive** : une personne non développeuse voit des détails moteur avant la structure du jeu.
3. **Responsabilité floue** : on ne sait plus si la « vérité » de la progression est dans le graphe de cutscene ou dans la step — ce qui casse la hiérarchie Global Story → Step → Cutscene.

### 1.2 Refaire une version réduite de Global Story dans la Step

**Global Story** décide du **macro** : quelle grande ligne, quelle step est débloquée dans le graphe global, quels arcs suivent.

**Step** décide du **local** : pour *cette* unité de progression, qu’est-ce qui est requis, quels résultats **locaux** peuvent apparaître, quel résultat **global / de progression** clôt l’étape, quelles cutscenes **servent** l’étape.

Une Step ne doit pas redevenir un graphe d’arcs du jeu entier : sinon on duplique la carte mentale de la Global Story et on perd la lisibilité « une étape = une fiche de mission ».

---

## 2. Différence exacte : Step vs Cutscene

| Dimension | Step | Cutscene |
|-----------|------|----------|
| Question centrale | *Qu’est-ce qui doit être vrai / fait pour valider l’étape ?* | *Comment montrer ça à l’écran ?* |
| Unité d’édition | Objectif métier, conditions de validation, outcomes, liens vers scènes | Nœuds d’exécution, dialogues, mouvements, caméra |
| Branches | Branches **métier** (ex. feu / eau / plante comme résultats attendus) | Branches **scéniques** (choix UI, chemins de nœuds) |
| Outputs | Outcome IDs porteurs de sens pour la progression | Émission d’outcomes **comme effet** d’une scène bien construite |
| Ce que l’éditeur montre | Références `(cutsceneId, rôle)` + texte lisible | Contenu des nœuds et graphe local |

**Règle d’or :** la Step **ne contient pas** la mise en scène ; elle **référence** des cutscenes et décrit **pourquoi** elles sont là (intro, choix principal, clôture, optionnel).

---

## 3. Différence exacte : Step vs Global Story

| Dimension | Global Story | Step |
|-----------|--------------|------|
| Échelle | Jeu / chapitre / arc | Une progression « mission » |
| Débit | Quelle step est active, déblocages entre steps | Comment *cette* step se termine et quels outcomes elle produit |
| Graphe | Structure globale des steps | Sous-structure **locale** (branches locales, liste de scènes liées) |
| Lisibilité | Vue d’ensemble narrative | Vue « fiche d’étape » pour un créateur |

La Global Story **orchestre** les steps ; la Step **définit** le contrat local (objectif + validation + outcomes + scènes servant l’étape).

---

## 4. Logique produit retenue pour Step Studio

1. **No-code lisible** : phrases et libellés pour entrée / objectif / validation / sortie, complétés par des règles techniques (activation, completion) dans l’inspecteur quand nécessaire.
2. **Construction visuelle « type Scratch », mais métier** : flux **vertical** de blocs sémantiques (pas de nœuds d’exécution).
3. **Trois zones fixes** pour réduire la surprise cognitive :
   - **Gauche** : palette de **types** de blocs (raccourcis + sémantique).
   - **Centre** : **canvas de flux** — lecture du parcours logique de l’étape.
   - **Droite** : **inspecteur** du bloc sélectionné (champs de données Step).
4. **Cutscenes** : uniquement liste de **liens** `(id, rôle)` + action **« Ouvrir dans Cutscene Studio »** (câblée au niveau `NarrativeWorkspaceCanvas`).
5. **Exemple canon** : gabarit **« Choix du starter »** (bouton dédié) qui préremplit objectifs, outcomes locaux, outcome de progression et textes de flux — les IDs de cutscenes réels restent à lier depuis le projet.

---

## 5. Structure de l’écran implémentée

### 5.1 Zone gauche — `StepFlowPalette`

**Responsabilité :** proposer des **actions de composition** alignées sur la progression métier :

- focus / ajout vers entrée, objectif, validation, outcomes (local / progression), cutscene liée, branche locale, monde, sortie.

**Ce qu’elle n’est pas :** une palette de primitives Cutscene (dialogue, move, etc.).

Fichier : `lib/src/ui/canvas/step_studio/step_flow_palette.dart`.

### 5.2 Zone centrale — `StepFlowCanvas`

**Responsabilité :** matérialiser le **fil narratif-logique** de l’étape :

- cartes empilées reliées par connecteurs (lecture haut → bas),
- blocs pour entrée, moteur d’activation, objectif, cutscenes liées, branches locales, validation (completion), outcomes de progression, sortie (déblocage step suivante), carte « monde ».

**Ce qu’elle n’est pas :** un graphe de scène ni une timeline.

Fichier : `lib/src/ui/canvas/step_studio/step_flow_canvas.dart`.

### 5.3 Zone droite — inspecteur contextuel dans `StepStudioWorkspace`

**Responsabilité :** éditer les **données** du slot sélectionné :

- champs texte « langage humain » pour le flux,
- sections existantes réutilisées pour activation, completion, identité, outcomes, liens cutscene, monde.

**Message vide** : rappel explicite que ce panneau n’édite pas dialogues / caméra / pathfinding.

Types de focus : `StepFlowSlot` + index de liste quand pertinent (`StepFlowFocus`).

Fichiers : `step_flow_focus.dart`, `_buildFlowInspectorColumn` / `_buildFlowInspectorContent` dans `step_studio_workspace.dart`.

---

## 6. Nature des blocs logiques

Les blocs sont des **vues** sur des champs du modèle `StepStudioStep` / document, pas un second format de vérité :

- **Entrée** : `flowEntryLabel` + rappel/sous-édition de l’activation (quand le moteur active la step).
- **Objectif** : nom/description de step + `flowObjectiveLabel`.
- **Cutscene liée** : entrée dans `cutscenes[]` avec `StepStudioCutsceneRole`.
- **Branches locales** : sous-ensemble des `outcomes` avec scope **local** (ex. `starter.selected.*`).
- **Validation** : `completion` + `flowValidationLabel` (phrase joueur / créateur).
- **Outcome global de step** : outcomes scope **progression** + règle `whenOutcomeEmitted`, etc.
- **Sortie** : `flowExitLabel` + `flowUnlocksStepId` (step suivante débloquée — lien **documentaire / auteur** dans le JSON actuel).
- **Monde** : `worldChanges` (persistance d’entités — reste distinct de la mise en scène).

---

## 7. Cutscenes liées à une step (sans les éditer)

1. **Ajout** : depuis la palette ou l’inspecteur — crée une entrée dans `cutscenes` avec un rôle.
2. **Référence** : dropdown des scénarios `localEventFlows` du projet (projection narrative).
3. **Rôle** : kickoff / main / completion / optional — vocabulaire métier pour expliquer *pourquoi* la scène existe dans l’étape.
4. **Édition du contenu** : bouton **« Ouvrir dans Cutscene Studio »** si `onOpenCutsceneStudio` est fourni ; le parent bascule workspace + sélectionne la cutscene (`NarrativeWorkspaceCanvas`).

Aucun affichage des nœuds internes dans Step Studio.

---

## 8. Pourquoi la vue reste no-code et lisible

- Le **canvas** parle en **titres** (Entrée, Objectif, Cutscenes, Branches, Validation, Sortie).
- Les **IDs techniques** sont confinés à l’inspecteur ou aux sous-titres, avec génération d’IDs depuis les libellés là où c’était déjà le pattern du produit.
- La **footnote** du workspace rappelle la triade Global Story / Step / Cutscene.

---

## 9. Parties encore évolutives (hypothèses assumées)

1. **`flowUnlocksStepId`** : aujourd’hui c’est un champ **auteur** pour documenter / outiller la sortie ; la synchronisation fine avec le graphe Global Story pourra être renforcée côté moteur ou côté Global Story uniquement — à trancher produit.
2. **Ordre exact des cutscenes** : le canvas affiche l’ordre du tableau ; une contrainte moteur « kickoff avant main » pourrait être ajoutée plus tard (validation ou tri).
3. **Branches locales** : modélisées comme outcomes **locaux** ; un modèle plus riche (ex. arbre conditionnel métier) pourrait compléter sans remplacer la couche Cutscene.
4. **Gabarit starter** : ne crée pas automatiquement les assets `starter_intro` / `starter_selection` — il prépare la **logique** ; les liens cutscene restent une action créateur.

---

## 10. Compromis

| Compromis | Raison |
|-----------|--------|
| Inspecteur réutilise des sections « formulaire » existantes | Cohérence avec le reste de l’éditeur, moins de régression ; le **canvas** apporte la couche « Scratch métier ». |
| Deux chemins pour certaines données (ex. outcomes) : palette + inspecteur | La palette accélère la composition ; l’inspecteur permet l’édition fine. |
| Champ `flowUnlocksStepId` optionnel | Utile pour la lisibilité « sortie » sans imposer un moteur de déblocage déjà finalisé. |
| Layout **empilé** si la largeur utile est faible (sidebar + marges) | Évite les débordements horizontaux sur fenêtres étroites ; les zones reçoivent des `Expanded` avec flex pour partager la hauteur. |
| Tests widget : `setSurfaceSize(1600×1200)` pour `StepStudioWorkspace` | Le viewport par défaut des tests (800×600) est plus petit qu’un bureau d’éditeur ; même comportement que `global_story_studio_workspace_test`. |

---

## 11. Fichiers touchés (référence)

| Fichier | Rôle |
|---------|------|
| `lib/src/features/narrative/application/step_studio_authoring.dart` | Champs JSON `flow*` + `flowUnlocksStepId` sur `StepStudioStep`. |
| `lib/src/ui/canvas/step_studio/step_flow_focus.dart` | Focus / slots pour canvas + inspecteur. |
| `lib/src/ui/canvas/step_studio/step_flow_palette.dart` | Palette métier gauche. |
| `lib/src/ui/canvas/step_studio/step_flow_canvas.dart` | Canvas central. |
| `lib/src/ui/canvas/step_studio_workspace.dart` | Assemblage 3 colonnes, inspecteur, gabarit starter, suppression d’anciennes sections orphelines. |
| `lib/src/ui/canvas/narrative_workspace_canvas.dart` | `onOpenCutsceneStudio` vers Cutscene workspace. |
| `test/step_studio_authoring_test.dart` | Roundtrip JSON des champs de flux. |

---

## 12. Critères de réussite (checklist)

- [x] Cohérent avec la hiérarchie Global Story → Step → Cutscene.
- [x] Pas d’édition de mise en scène dans Step Studio.
- [x] Cutscenes = références + rôle + ouverture externe.
- [x] UI structurée palette / canvas / inspecteur.
- [x] Gabarit « Choix du starter » intégré comme exemple produit.
- [x] Rapport produit/architecture (ce document).

---

*Fin du rapport.*
