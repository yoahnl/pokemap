# Cutscene Studio — refonte produit (PokeMap)

Ce document est le rapport demandé pour la refonte **Cutscene Studio** : il explique les problèmes de l’ancienne approche, le nouveau paradigme UI/UX, l’architecture technique introduite, le drag-and-drop, la persistance des branches, et les suites possibles.

---

## 1. Pourquoi l’ancienne UI était insuffisante (honnêteté produit)

### 1.1 Symptômes visibles

L’écran historique combinait :

- un **header** avec actions,
- une **section source** (hook monde),
- une **liste verticale de cartes**, chacune contenant **tout le formulaire** du bloc.

Pour l’utilisateur non technique, cela ressemblait à :

- une **fiche à remplir** empilée,
- un **panneau de configuration** plutôt qu’une scène à composer,
- une **colonne de paramètres** sans hiérarchie entre « structure de la scène » et « détail d’un bloc ».

### 1.2 Cause structurelle (pas seulement du « polish »)

Le **centre de l’écran** était occupé par des **formulaires répétés**. Or, dans un outil no-code narratif :

- le **centre** doit répondre à : *« Que se passe-t-il, dans quel ordre, avec quelles branches ? »* ;
- le **détail** doit répondre à : *« Comment est paramétrée l’action sélectionnée ? »*.

Mélanger les deux dans la même colonne **casse la lisibilité** : on ne voit plus la scène, on voit des champs.

### 1.3 Limite du modèle linéaire

Le studio v1 assumait un **graphe linéaire** côté compilation. Dès qu’un scénario avait des **branches réelles** (choix, conditions), le parseur marquait la cutscene comme **non éditable**. C’était cohérent techniquement, mais **bloquant produit** : impossible d’aligner l’UI sur un wireframe avec **Oui / Non** sans étendre le modèle d’authoring et le compilateur.

---

## 2. Nouveau paradigme : composition visuelle + inspection contextuelle

### 2.1 Règle d’or

> **Le centre montre la structure ; la droite montre le détail.**

Autrement dit :

- **Gauche** : *« Qu’est-ce que je peux ajouter ? »* (bibliothèque)
- **Centre** : *« Comment ma scène se lit ? »* (flow)
- **Droite** : *« Comment je règle l’élément sélectionné ? »* (inspecteur)

### 2.2 Vocabulaire volontairement « métier »

On évite dans l’UI :

- node, graphe libre, runtime block, IDs techniques en exergue.

On favorise :

- **action**, **bloc**, **scène**, **choix**, **branche**, **suite**, **personnage**, **dialogue**, **caméra**.

### 2.3 Inspiration Scratch sans aspect « jouet »

L’inspiration est **la manipulation directe** (glisser-déposer, fentes visibles), pas les couleurs criardes ni les puzzles enfantins. La DA vise un **desktop calme** : surfaces séparées, peu de contours agressifs, hiérarchie typographique claire.

---

## 3. Hiérarchie des zones (wireframe → implémentation)

### 3.1 Top bar

Contenu cible :

- fil d’Ariane : `Narrative Studio > Step > Cutscene` ;
- **nom** de la cutscene (champ éditable) ;
- actions explicites : **Tester**, **Simuler**, **Sauvegarder**, plus **Réinitialiser** et **Nouvelle cutscene**.

Les boutons **Tester / Simuler** sont pour l’instant des **ancrages produit** (messages explicatifs) : le runtime MVP ne supporte pas encore l’exécution complète des nœuds `choice`, et il est préférable d’être **transparent** plutôt que de simuler une fonctionnalité absente.

### 3.2 Colonne gauche — bibliothèque

- recherche : *« Rechercher une action… »* ;
- catégories repliables : Dialogue, Personnages, Déplacements, Caméra, Attentes, Conditions ;
- items **draggables** avec feedback léger.

### 3.3 Colonne centrale — flow vertical guidé

- ancres **Start** / **End** ;
- **zones de dépôt** explicites entre les blocs ;
- cartes de blocs **compactes** (titre + résumé) ;
- embranchement **Oui / Non** avec sous-zones de dépôt.

Le centre n’est **pas** un node editor libre : la topologie reste **lisible** et **pédagogique**.

### 3.4 Colonne droite — inspecteur

- si **aucun bloc sélectionné** : méta cutscene + **configuration complète de la source** (hook monde) ;
- si **bloc sélectionné** : éditeurs existants (adaptés) pour paramétrer ce bloc.

---

## 4. Modèle de données : arbre d’authoring + graphe runtime

### 4.1 `CutsceneFlowEntry`

Deux formes :

1. **`CutsceneFlowBlockEntry`** : une action simple.
2. **`CutsceneFlowChoiceEntry`** : une **question** (bloc) + listes `onYes` / `onNo` d’entrées imbriquées.

Ce modèle est volontairement **plus riche** que la liste plate `blocks`, mais reste **guidé** (pas un graphe arbitraire).

### 4.2 `CutsceneStudioDocument`

- `blocks` : tronc principal aplati (**compatibilité** avec l’existant et les écrans qui lisent surtout cette liste).
- `cutsceneFlow` : arbre complet lorsque des branches existent.

### 4.3 Persistance JSON (`ScenarioAsset.metadata`)

Clé : `authoring.cutsceneFlow`

- permet de **recharger** la même structure dans l’UI après rouverture du projet ;
- complète le graphe runtime : le runtime continue de consommer `nodes/edges`, tandis que l’éditeur conserve une **vue authoring fidèle**.

### 4.4 Compilation avec branches

Le compilateur produit :

- des nœuds `choice` avec **deux arêtes** `ScenarioEdgeKind.choice` ;
- des nœuds **fusion** (`wait` 0 ms) pour **reconverger** les branches vers la suite du tronc.

Cette technique est classique : elle garantit un graphe **valide** tout en gardant une lecture authoring simple.

**Note runtime** : l’exécuteur MVP peut encore **bloquer explicitement** sur `choice` ; l’éditeur, lui, prépare un graphe **valide côté données** et une UX **honnête** (boutons test/simulation non trompeurs).

---

## 5. Drag-and-drop : comportement attendu vs compromis

### 5.1 Ce qui est implémenté

- Glisser depuis la **palette** vers :
  - une fente du **tronc principal** ;
  - une fente **Oui / Non** ;
- **Réordonnancement** du tronc principal par drag interne (payload dédié).

### 5.2 Compromis assumés (itération suivante)

- pas encore de **drag** pour réordonner **à l’intérieur** d’une branche avec la même richesse que le tronc ;
- embranchements **imbriqués** dans une branche : message d’information plutôt qu’éditeur complet (le cas est rare dans le wireframe initial, mais le modèle de données le permet).

---

## 6. Choix visuels

- **Teintes discrètes** par famille (dialogue, déplacement, caméra, attente, condition) — jamais arc-en-ciel agressif.
- **Cartes** avec bordure renforcée à la sélection (lisibilité > fioritures).
- **Zones de drop** avec animation légère quand un drag est au-dessus.

---

## 7. Évolution prévue (backlog honnête)

1. **Exécution** : brancher Tester/Simuler sur un mode pas-à-pas réel, puis support runtime des `choice`.
2. **Manipulation** : réordonnancement dans les branches + suppression de bloc depuis le canvas.
3. **Palette** : actions « Si / sinon » distinctes de « question joueur » si le runtime distingue condition scriptée vs choix UI.
4. **Round-trip** : parser un graphe runtime **sans** metadata JSON (reconstruction heuristique) — difficile, à éviter tant que la metadata est fiable.
5. **Internationalisation** : aujourd’hui FR produit sur les libellés demandés.

---

## 8. Fichiers touchés (cartographie)

- `packages/map_editor/lib/src/features/narrative/application/cutscene_studio_authoring.dart`  
  schéma v2, flow JSON, compilation branches, helpers de mutation.
- `packages/map_editor/lib/src/ui/canvas/cutscene_studio/cutscene_studio_workbench.dart`  
  nouvelle coque 3 colonnes + DnD.
- `packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart`  
  logique projet / hydration / inspecteur / source.
- `packages/map_editor/test/cutscene_studio_authoring_test.dart`  
  assertion sur la présence de la metadata de flow après build.

---

## 9. Critères de réussite (checklist)

- [x] Top bar alignée sur le wireframe (breadcrumb, nom, actions).
- [x] Palette catégorisée + recherche + drag.
- [x] Flow vertical Start → blocs → question → Oui/Non → End.
- [x] Inspecteur contextuel + source quand rien n’est sélectionné.
- [x] Modèle d’authoring avec branches + sauvegarde metadata + compile graphe valide.
- [x] Démo template `visualFlowDemo` disponible côté authoring.
- [x] Rapport markdown détaillé (ce fichier).

---

## 10. Conclusion

La refonte ne « réarrange » pas l’ancienne colonne de formulaires : elle **sépare** lisiblement **composition** et **configuration**, et **étend** le contrat d’authoring pour refléter des **branches réelles**. L’outil ressemble davantage à un **studio narratif** qu’à un panneau technique — tout en restant honnête sur les **limites runtime** encore en cours de maturation.
