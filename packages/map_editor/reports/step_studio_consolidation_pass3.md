# Step Studio — consolidation passe 3 (UX sobre, signaux honnêtes)

**Date :** 2026-04-05  
**Périmètre :** Step Studio uniquement (authoring + workspace + `step_studio/*` + test ciblé). Aucune modification de Global Story Studio, Cutscene Studio, `map_runtime`, `map_gameplay`, shell global.

---

## 1. Résumé exécutif

**Ce qui restait flou après la passe 2**

- Le canvas répétait de longs textes « pédagogiques » (pieds de carte Validation / Sortie) qui encombraient la lecture et donnaient l’impression d’un manuel intégré.
- `flowUnlocksStepId` était encore visible sur le canvas à côté de `flowExitLabel`, ce qui renforçait la confusion « lien actif vers la step suivante » alors que le champ est un **mémo JSON sans consommateur runtime** dans ce dépôt.
- La palette et l’inspecteur utilisaient encore beaucoup de sous-titres longs, de backticks et de formulations théoriques — utiles en revue interne, moins pour une UI de création quotidienne.
- La hiérarchie « note auteur vs donnée structurée » était correcte conceptuellement mais **trop bavarde** à l’écran.

**Décisions**

1. **Canvas** : retirer tout affichage de `flowUnlocksStepId` ; ne garder sur la carte « sortie » que `flowExitLabel` (titre renommé **Notes sortie**). Supprimer les **pieds de carte** verbeux sur Validation et Sortie. Raccourcir les hints vides et le bandeau d’en-tête.
2. **Palette** : titres et sous-titres plus courts ; vocabulaire aligné sur des actions (`+ Outcome…`, `Lier une cutscene`) et sur la nature des données (`outcomes`, `worldChanges`) sans discours.
3. **Inspecteur** : libellés et sous-titres raccourcis ; section sortie renommée **Notes sortie** ; dropdown explicitement « mémo / sans effet runtime ».
4. **Modèle (doc uniquement)** : préciser dans `step_studio_authoring.dart` que le canvas ne montre pas `flowUnlocksStepId` (choix UX passe 3), sans changer le schéma JSON.
5. **Test** : verrouiller l’absence de l’id mémo sur le canvas tout en vérifiant que `flowExitLabel` s’affiche.

**Pourquoi**

- Respect de la règle d’or : **ne pas faire croire** à un comportement (déblocage, lien exécutable) qui **n’existe pas**.
- Réduction de la charge cognitive : **guider** sans transformer l’UI en tutoriel vivant.

---

## 2. Analyse des ambiguïtés restantes (avant correctifs)

### 2.1 `flow*Label`

| Aspect | Constat |
|--------|---------|
| Rôle réel | Texte persisté, affiché Step Studio, **non** exposé dans `NarrativeStepSummary`. |
| Où lus | `StepFlowCanvas`, inspecteur `StepStudioWorkspace`, sérialisation JSON. |
| Confusion résiduelle | Mélange visuel avec résumés `summarizeStep*` sur les mêmes cartes. |
| Action passe 3 | Moins de prose autour ; libellés d’inspecteur qui disent « note » / « pas la règle seule » sans paragraphes. |

### 2.2 `flowUnlocksStepId`

| Aspect | Constat |
|--------|---------|
| Fait réellement | Stocké, éditable, sérialisé. **Aucune** lecture dans gameplay/runtime dans ce repo. |
| Ne fait pas | Déclencher l’activation d’une autre step, modifier le graphe, notifier le moteur. |
| Danger UX | Proximité avec « step suivante » sur le canvas = **poison sémantique**. |
| Action passe 3 | **Retrait canvas** ; maintien inspecteur + JSON inchangé ; doc Dart mise à jour. |

### 2.3 Palette

| Aspect | Constat |
|--------|---------|
| Verbosité | Sous-titres type « même inspecteur », backticks, phrases longues. |
| Action passe 3 | Sections plus courtes (`Début`, `Fin`), sous-titres une ligne, icône distincte pour « Notes sortie » (`doc_plaintext` vs flèche entrée). |

### 2.4 Canvas

| Aspect | Constat |
|--------|---------|
| Bavardage | Pieds de carte multi-lignes ; hints longs. |
| Hiérarchie | Section « Outcomes de progression » redondante avec le titre carte. |
| Action passe 3 | Titres plus courts (`Progression`, `Cutscenes`) ; hints une ligne ; pas de pied sur Validation / Notes sortie. |

### 2.5 Inspecteur

| Aspect | Constat |
|--------|---------|
| Ambiguïté | Sous-titres très longs avec markdown mental (`**`) implicite via formulation. |
| Action passe 3 | Phrases courtes ; vérité sur le mémo id conservée **une fois** au bon endroit (dropdown + subtitle section). |

---

## 3. Décisions prises

### Modifié

- `step_flow_canvas.dart` : en-tête, sections, hints, carte sortie (sans `flowUnlocksStepId`, sans pieds pédagogiques), icône notes sortie.
- `step_flow_palette.dart` : titres, sous-titres, sections, libellés d’actions.
- `step_flow_focus.dart` : doc enum `exitNext`.
- `step_studio_workspace.dart` : doc classe widget, footnote, vide inspecteur, cartes inspecteur (entrée, objectif, cutscene, locales, validation, notes sortie).
- `step_studio_authoring.dart` : documentation classe + champ `flowUnlocksStepId` (UX canvas / inspecteur).
- `test/step_flow_canvas_test.dart` : **nouveau** — garde-fous affichage.

### Laissé tel quel

- Schéma JSON, clés metadata, `copyWith`, tests authoring existants (roundtrip `flow*` inchangé).
- Logique d’hydratation / sauvegarde / layout responsive passe 2.
- Pas de toucher à `narrative_workspace_canvas.dart` (câblage Cutscene déjà correct).

### Refusé explicitement

- Renommer la clé JSON `flowUnlocksStepId` (coût migration sans bénéfice produit immédiat).
- Supprimer le champ (casserie de gabarits / projets existants ; le risque est **UX**, pas existence).
- Ajouter un « vrai » lien d’activation dérivé du mémo (faux moteur).
- Nouvelle abstraction « StepLink » ou couche intermédiaire non consommée.

---

## 4. Vérification de branchement réel

| Élément | Qui lit | Où | Abstraction morte ? |
|---------|---------|-----|---------------------|
| `flow*Label` | Step Studio UI + JSON | `map_editor` | Non — affichage réel ; pas runtime. |
| `flowUnlocksStepId` | Step Studio inspecteur + JSON | `map_editor` | Non — édition réelle ; pas runtime. |
| `activation` / `completion` | Inspecteur, résumés canvas, projection narrative (résumés texte) | `map_editor` (+ projection) | Non. |
| `outcomes` / `cutscenes` / `worldChanges` | Idem + listes canvas | `map_editor` | Non. |
| Changements UI texte seuls | — | — | **Aucune** nouvelle donnée ; pas de branchement ajouté. |

---

## 5. Risques restants

- **Lecture utilisateur** : même avec « mémo sans effet runtime », une partie des créateurs peut supposer que le JSON « suffit » au moteur — seul un **contrat runtime documenté** levera le doute globalement.
- **`flowExitLabel` seul sur le canvas** : si le mémo id est rempli mais le texte vide, le canvas dit « Mémo : inspecteur » — l’utilisateur doit ouvrir l’inspecteur ; c’est **volontaire** (réduit le faux lien visuel).
- **Redondance** `description` / `flowObjectiveLabel` : toujours possible ; pas de fusion automatique (hors scope ; risque de perte d’intention auteur).

**Questions produit ouvertes**

- Faut-il **déprécier** `flowUnlocksStepId` à terme au profit d’un seul champ texte ou d’un lien **réel** côté Global Story (hors Step Studio) ?
- Faut-il **générer** les `flow*Label` à partir des règles (one-way) pour éviter la double saisie ?

---

## 6. Fichiers modifiés

| Fichier | Rôle des changements |
|---------|----------------------|
| `lib/src/features/narrative/application/step_studio_authoring.dart` | Doc : famille B, `flowUnlocksStepId` et politique canvas/inspecteur. |
| `lib/src/ui/canvas/step_studio/step_flow_canvas.dart` | Canvas allégé ; notes sortie sans id mémo ; pas de pieds pédagogiques longs. |
| `lib/src/ui/canvas/step_studio/step_flow_palette.dart` | Palette courte et actionnable. |
| `lib/src/ui/canvas/step_studio/step_flow_focus.dart` | Doc `exitNext`. |
| `lib/src/ui/canvas/step_studio_workspace.dart` | Inspecteur + footnote + doc widget. |
| `test/step_flow_canvas_test.dart` | **Nouveau** — contrat UX canvas / mémo id. |

---

## 7. Validation

**Tests lancés**

```text
flutter test test/step_flow_canvas_test.dart test/step_studio_authoring_test.dart
```

**Résultat** : succès (6 tests, dont 2 nouveaux sur le canvas).

**Non vérifié ici**

- `flutter test` sur l’intégralité du package `map_editor` (hors demande ; pas d’explosion de scope).
- Test visuel manuel sur build macOS / Windows.

---

## 8. Ce qui est mieux / imparfait / à ne pas interpréter comme runtime

**Mieux**

- Moins de texte « manuel » dans le canvas ; `flowUnlocksStepId` n’y apparaît plus.
- Palette et inspecteur plus **secs** et **honnêtes**.

**Imparfait**

- Le mémo id existe toujours (choix conservateur) ; seul le **signal visuel** le plus dangereux a été retiré du canvas.
- Les `flow*Label` restent des champs séparés de `description` / règles — la discipline de saisie reste humaine.

**Ne pas interpréter comme runtime**

- Tout champ `flow*` et `flowUnlocksStepId`.
- Tout libellé « note », « mémo », « annotation » dans l’inspecteur.
- L’ordre visuel des cartes sur le canvas (linéaire, pas graphe d’exécution).

---

## 9. Note sur le brief

Aucun point du brief n’a été jugé **impossible** ; le seul arbitrage dur a été : **ne pas supprimer** `flowUnlocksStepId` du schéma (rupture données) tout en **traitant le problème UX** par le retrait d’affichage canvas + tests + libellés — compromis explicitement choisi comme **sain** et **réversible** si le produit décide plus tard de retirer le champ côté données.

---

*Fin du rapport — passe 3.*
