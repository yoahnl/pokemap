# LOT 66 - Refonte Cutscene Studio no-code (blocs concrets)

## 1. Resume executif

Ce lot refond le **Cutscene Workspace** pour le rapprocher d'un vrai studio no-code "bloc par bloc".

Ce qui change concretement:
- l'edition principale est maintenant orientee **actions de scene** (dialogue, deplacement, transition, choix starter, resultat de scene);
- la saisie d'identifiants techniques n'est plus le chemin principal;
- les selections passent par des **dropdowns guides** relies aux donnees projet (maps, PNJ, dialogues, warps, scripts);
- les blocs sont categories visuellement et indiquent explicitement si le runtime est deja branche.

Ce qui n'est pas pretendu:
- ce lot ne livre pas encore un "Scratch ultime" avec drag-and-drop complet;
- ce lot ne pretend pas que tous les nouveaux blocs UI sont deja executes en runtime.

---

## 2. Diagnostic de l'etat precedent (pourquoi c'etait encore trop technique)

Problemes observes avant refonte:
- le Cutscene Studio exposait encore des parcours techniques (`scriptId`, `outcomeId`, saisie manuelle);
- des blocs "legacy runtime" prenaient trop de place dans l'UX principale;
- l'utilisateur editait trop des references techniques, pas assez des intentions de scene;
- le modele mental ressemblait a un inspecteur de donnees plus qu'a un constructeur de scene.

Conséquence produit:
- charge cognitive trop elevee pour un public non technique;
- faible sentiment "je mets en scene";
- faible proximite avec un authoring type Scratch / RPG Maker.

---

## 3. Decisions produit appliquees

### 3.1 Modele mental retenu

Le centre de gravite est maintenant:
- **"Construire une scene avec des blocs d'actions"**

et non:
- "Configurer des objets runtime".

### 3.2 Palette no-code prioritaire

Le bouton "Ajouter un bloc" expose en priorite:
- Faire parler un personnage
- Afficher une ligne de narration
- Deplacer un personnage
- Le joueur suit un personnage
- Tourner un personnage
- Entrer dans un batiment / map
- Choix du starter
- Attendre
- Ajouter un resultat de scene
- Lancer une sequence scriptée (avance)

Les blocs legacy techniques restent compatibles mais ne sont plus la palette principale.

### 3.3 Suppression de la saisie d'IDs techniques dans le flux principal

Remplacements:
- `dialogueId` tape a la main -> dropdown dialogues
- `scriptId` tape a la main -> dropdown scripts
- `outcomeId` tape a la main -> bloc "Resultat de scene" avec nom lisible + portee (id interne genere automatiquement)
- `entityId` tape a la main -> dropdown personnages (joueur/narrateur/PNJ map)
- destination de mouvement -> dropdown type + dropdown cible (warp/spawn/personnage)

---

## 4. Decisions UX detaillees

## 4.1 Structure des blocs

Chaque bloc affiche maintenant:
- titre action lisible;
- categorie (Dialogue, Deplacement, Transition, Gameplay, Logique, Technique);
- controles de sequence (monter/descendre/supprimer);
- editeur contextuel guide.

## 4.2 Deplacement/pathfinding (niveau authoring)

Nouveau bloc **"Deplacer un personnage"**:
- personnage (dropdown),
- type de destination (warp/spawn/personnage),
- cible (dropdown dependant du type),
- option "attendre la fin du deplacement" (toggle).

## 4.3 Transition map

Bloc **"Entrer dans un batiment / map"**:
- map de destination (dropdown),
- warp de destination (dropdown base sur la map).

## 4.4 Choix starter

Bloc **"Choix du starter"**:
- options visibles dans la carte de bloc,
- edition simple option par option,
- ajout/suppression d'option.

## 4.5 Resultat de scene (sans outcomeId tape)

Bloc **"Ajouter un resultat de scene"**:
- nom lisible,
- portee (`local`, `progression`, `global`) via dropdown,
- affichage de l'identifiant interne genere.

---

## 5. Decisions architecture

Le lot reste dans le scope `map_editor` et garde la frontiere:
- UI/authoring dans `cutscene_studio_workspace.dart`;
- mapping authoring -> `ScenarioAsset` dans `cutscene_studio_authoring.dart`.

Nouveaux points importants:
- constantes authoring pour les blocs no-code (actions, scopes, cibles de move);
- helper public `resolveCutsceneStudioOutcomeId(...)` pour generer l'id interne sans exposition technique;
- cache lookup map enrichi (PNJ + spawns + triggers + warps) pour alimenter les dropdowns sans imposer l'ouverture active de chaque map.

---

## 6. Fichiers modifies

### 6.1 `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/narrative/application/cutscene_studio_authoring.dart`

Modifications principales:
- ajout de nouvelles constantes actions no-code:
  - `showMessage`, `moveCharacter`, `followCharacter`, `faceCharacter`, `transitionMap`, `starterChoice`, `waitMs`;
- ajout constantes metier:
  - scopes de resultat de scene (`local/progression/global`);
  - cibles de deplacement (`warp/spawn/entity`);
- extension `CutsceneStudioBlockKind` avec blocs concrets;
- categorisation des blocs + helper de support runtime;
- extension `CutsceneStudioBlock` (actor, destination, transition, wait, options de choix, resultat lisible);
- compile/parse pour les nouveaux blocs;
- helper public `resolveCutsceneStudioOutcomeId(...)`.

Extrait cle:

```dart
String? resolveCutsceneStudioOutcomeId(CutsceneStudioBlock block) {
  return _resolveOutcomeIdForResultBlock(block);
}
```

Raison:
- garder une UX no-code basee sur un nom lisible, tout en generant un id stable pour le runtime.

---

### 6.2 `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart`

Modifications principales:
- refonte de la section "Construction de la scene" en vrai mode blocs guides;
- bloc card visuel avec categorie + badge runtime support/non support;
- suppression des flux principaux bases sur saisie manuelle d'identifiants;
- ajout d'editeurs de blocs concrets:
  - dialogue,
  - narration,
  - move character,
  - follow character,
  - face character,
  - transition map,
  - starter choice,
  - wait,
  - scene result,
  - runScript (avance);
- palette "Ajouter un bloc" recentree no-code;
- enrichissement des lookup map (PNJ/spawns/triggers/warps) pour dropdowns contextuels.

Extrait cle:

```dart
const List<CutsceneStudioBlockKind> _cutscenePaletteBlockKinds =
    <CutsceneStudioBlockKind>[
  CutsceneStudioBlockKind.dialogue,
  CutsceneStudioBlockKind.narration,
  CutsceneStudioBlockKind.moveCharacter,
  CutsceneStudioBlockKind.followCharacter,
  CutsceneStudioBlockKind.faceCharacter,
  CutsceneStudioBlockKind.transitionMap,
  CutsceneStudioBlockKind.starterChoice,
  CutsceneStudioBlockKind.wait,
  CutsceneStudioBlockKind.sceneResult,
  CutsceneStudioBlockKind.runScript,
];
```

Raison:
- prioriser les blocs "scene authoring" plutot que les primitives techniques.

---

### 6.3 `/Users/karim/Project/pokemonProject/packages/map_editor/test/cutscene_studio_authoring_test.dart`

Modifications principales:
- adaptation parse test (`emitOutcome` parse maintenant vers `sceneResult`);
- ajout test generation outcome interne pour bloc resultat de scene;
- ajout test mapping bloc moveCharacter vers payload runtime.

---

## 7. Flux d'execution principal (nouvelle UX)

1. L'auteur ouvre une cutscene.
2. Il clique "Ajouter un bloc".
3. Il choisit un bloc metier (dialogue/deplacement/transition/choix/resultat...).
4. Il configure le bloc via dropdowns contextuels:
   - map / PNJ / warp / dialogue / scope resultat.
5. Le studio compile ensuite vers `ScenarioAsset` avec metadata schema et bindings runtime.

---

## 8. Cas "Emma -> laboratoire" (v1 atteignable)

Exprimable avec les blocs disponibles:
- Faire parler un personnage (Emma)
- Faire parler un personnage (Emma)
- Tourner un personnage (Emma -> est/ouest)
- Deplacer un personnage (Emma -> destination warp/sortie)
- Le joueur suit un personnage (Emma)
- Entrer dans un batiment / map (map labo + warp)
- Faire parler un personnage (Emma)
- Ajouter un resultat de scene ("Emma rencontree", scope progression)

---

## 9. Validations executees

## 9.1 Format

Commande:

```bash
dart format \
  packages/map_editor/lib/src/features/narrative/application/cutscene_studio_authoring.dart \
  packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart \
  packages/map_editor/test/cutscene_studio_authoring_test.dart
```

Resultat: OK.

## 9.2 Analyze cible

Commande:

```bash
flutter analyze \
  packages/map_editor/lib/src/features/narrative/application/cutscene_studio_authoring.dart \
  packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart \
  packages/map_editor/test/cutscene_studio_authoring_test.dart
```

Resultat: **No issues found**.

## 9.3 Tests cibles

Commandes executees:

```bash
cd packages/map_editor
flutter test test/cutscene_studio_authoring_test.dart
flutter test test/editor_notifier_map_snapshot_test.dart
```

Resultats:
- `cutscene_studio_authoring_test.dart`: OK (tous les tests passent)
- `editor_notifier_map_snapshot_test.dart`: OK (tous les tests passent)

Note honnête:
- un premier essai de test lance depuis la racine du monorepo a echoue (`No pubspec.yaml file found`), puis relance correcte depuis `packages/map_editor`.

---

## 10. Ce qui est volontairement hors scope de ce lot

- drag-and-drop complet des blocs;
- branchement visuel profond type graphe complexe;
- moteur "Scratch complet" (boucles riches, sous-flux visuels imbriques);
- execution runtime complete des nouveaux blocs mouvement/transition/starter choice (les blocs non connectes runtime sont identifies dans l'UI).

---

## 11. Limites restantes (honnêtes)

1. Certains nouveaux blocs sont prepares UI/authoring mais pas encore branches runtime.
2. Le choix starter est un bloc v1 simple (options + serialisation), pas encore un branch editor complet.
3. L'edition texte (narration/resultat/options) passe encore par prompt sheet ponctuel, pas encore full inline editable.

---

## 12. Prochaines etapes recommandees

1. **Runtime bridge Lot suivant**
   - brancher `moveCharacter`, `followCharacter`, `faceCharacter`, `transitionMap`, `starterChoice`, `waitMs` dans l'execution cutscene.
2. **Branches visuelles V2**
   - representation claire des branches de choix + convergence.
3. **Cutscene Studio drag-and-drop V2**
   - reorder plus fluide avec drag handle.
4. **Preview in-engine**
   - lecture test de scene depuis le studio avec feedback bloc courant.
5. **Diagnostics narratifs**
   - warnings guidés ("bloc incomplet", "destination manquante", etc.).

---

## 13. Etat git final (sans commit)

Commande:

```bash
git status --short
```

Etat:
- `M packages/map_editor/lib/src/features/narrative/application/cutscene_studio_authoring.dart`
- `M packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart`
- `M packages/map_editor/test/cutscene_studio_authoring_test.dart`

Aucun commit, aucun amend, aucun merge, aucun rebase, aucun push.

