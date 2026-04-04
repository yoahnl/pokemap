# Global Story Studio — correctifs (round 2 + compléments UX / tests)

## Résumé exécutif

Ce document couvre :

1. **Round 2 initial** : réordonnancement **`chapter.stepIds`** lors d’une insertion existante **dans le même chapitre** ; renommage inline robuste (clavier / import) ; premières hit zones header.
2. **Compléments (post-validation produit)** :
   - **Header / accordéon** : une **seule grande zone** visuelle (chevron + CH + titre + badge steps) partage le **même** comportement « ligne cliquable » pour le toggle, tout en gardant **double-clic sur le titre** pour le renommage et **actions hors zone**.
   - **Insertion** : logique pure extraite dans **`global_story_studio_authoring.dart`** (testable) ; vérifications documentées pour ordre global vs `stepIds` (même chapitre / autre chapitre).
   - **Tests** : fichier **`test/global_story_studio_behavior_test.dart`** (unitaires + widget ciblés).

---

## Ce qui est maintenant garanti (code + tests)

| Garantie | Détail |
|----------|--------|
| **Même chapitre** | `reorderChapterStepIdsAfterMovingWithinSameChapter` aligne `chapter.stepIds` sur l’intention « après la step de référence », cohérent avec l’ordre global simulé après `_insertExistingStepAfter`. |
| **Autre chapitre** | `chapterStepIdsRemovingOnce` + `chapterStepIdsInsertingAfterReference` modélisent retrait / insertion sans doublon dans le chapitre cible (`null` si insert déjà présent). |
| **Picker** | `eligibleStepIdsForGlobalStoryInsertPicker` + `_availableStepsFor` : toutes les steps du **`StepStudioDocument` courant** sauf la step courante ; tests unitaires + widget (libellé `#n.` de la première option). |
| **Header** | `Expanded` → `GestureDetector` → `Row` (chevron, CH, titre, badge) : **simple tap** = toggle (sauf zone actions) ; **double tap** sur le titre = édition ; **`CupertinoButton`** d’actions **hors** du `GestureDetector` de ligne. |
| **Renommage** | Enter / Escape (key down) / perte de focus / nom vide inchangés par rapport au round 2. |
| **Tests automatisés** | Voir section « Tests ajoutés » ; `flutter test test/global_story_studio_behavior_test.dart test/global_story_studio_ux_test.dart` : **OK**. |

---

## Compromis UX restants

| Compromis | Pourquoi |
|-----------|----------|
| **Délai sur simple clic titre** | `_ChapterNameDisplay` combine `onTap` (toggle) et `onDoubleTap` (renommage). Flutter **retarde** le `onTap` pour distinguer un futur double-clic : le toggle depuis le **texte du titre** peut être légèrement plus lent qu’un clic sur chevron / badge. |
| **Deux recognizers sur la même ligne** | Le parent enveloppe toute la ligne ; l’enfant titre a son propre `GestureDetector` : les taps sur le titre sont traités par l’enfant (toggle + double-clic) ; chevron / badge passent par le parent. Comportement voulu, légère redondance des callbacks (`onAccordionToggle` ≈ `onExpansionTap`). |
| **Feuille d’action Cupertino** | Le picker secondaire (`showCupertinoModalPopup`) n’est pas couvert en test widget sur VM (rendu plateforme) ; la présence des options est validée via le **bandeau** et `eligibleStepIdsForGlobalStoryInsertPicker`. |

---

## Bugs confirmés (historique round 2)

| Bug | Cause racine |
|-----|----------------|
| Ordre chapitre après insert même chapitre | `stepIds` non réordonnés alors que `StepStudioDocument.steps` l’était. |
| Double-clic vs toggle (première itération) | Toggle et titre dans le même `GestureDetector` sans `onDoubleTap` sur le titre. |
| Import `KeyEventResult` | Mauvais `show` depuis `services.dart`. |

---

## Fichiers concernés

| Fichier | Rôle |
|---------|------|
| `packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart` | Fonctions pures : `reorderChapterStepIdsAfterMovingWithinSameChapter`, `chapterStepIdsRemovingOnce`, `chapterStepIdsInsertingAfterReference`, `eligibleStepIdsForGlobalStoryInsertPicker`. |
| `packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart` | Appelle les pures fonctions ; header unifié ; `_ChapterNameDisplay(onAccordionToggle)` ; `_availableStepsFor` branché sur `eligibleStepIds…`. |
| `packages/map_editor/test/global_story_studio_behavior_test.dart` | Nouveaux tests (voir ci-dessous). |
| `packages/map_editor/test/global_story_studio_ux_test.dart` | Helper `_expandAllGlobalStoryChapters` (chapitres repliés par défaut). |

---

## Vérification insertion (2 cas) — comportement réel

### Cas A — Même chapitre

1. **`_insertExistingStepAfter`** : liste `ordered` = `stepDoc.steps` triés par `order` ; `removeAt(existingIndex)` puis `insert(insertionIndex, existingStep)` après `afterStepId` ; re-numérotation `order` 0..n-1.
2. **`_moveStepToChapterOfStep`** : `reorderChapterStepIdsAfterMovingWithinSameChapter(chapter.stepIds, …)` → même permutation d’ids que l’ordre global **si** le chapitre contenait exactement ces steps dans l’ordre visé (test : `globalIds == visual`).

**Duplication** : un seul `remove` + un seul `insert` par liste ; pas de `copyWith` de step.

### Cas B — Autre chapitre

1. Ordre global : **même** algorithme liste `ordered` (étape 1 ci-dessus).
2. Chapitres : `chapterStepIdsRemovingOnce` sur le chapitre qui contenait la step ; `chapterStepIdsInsertingAfterReference` sur le chapitre de la step de référence (la step insérée **n’était pas** dans ce chapitre → pas de doublon).

**Cohérence picker** : options = `eligibleStepIdsForGlobalStoryInsertPicker(allProjectSteps, currentStepId)` ; `allProjectSteps` = `stepDocument.steps` triés passés depuis `_buildNarrativeTree`.

---

## Hit zones header (version actuelle)

```
Row
├── Expanded
│   └── GestureDetector (onTap: toggle)     ← grande zone « ligne »
│       └── Row
│           ├── chevron + badge CH
│           ├── Expanded
│           │   └── _ChapterNameDisplay
│           │         (onTap: toggle, onDoubleTap: rename)   ← titre
│           └── badge « X steps »
├── [actions] CupertinoButton…               ← hors GestureDetector ligne
```

- **Toggle** : tout tap sur chevron, CH, badge steps, ou **titre** (simple clic, avec délai si double-clic possible).
- **Renommage** : double-clic sur le titre uniquement.
- **Actions** : jamais dans le `GestureDetector` de la ligne.

---

## Renommage inline (inchangé fonctionnellement depuis round 2)

| Action | Comportement |
|--------|----------------|
| Double-clic zone titre | Édition inline. |
| Enter | Validation. |
| Escape (key down) | Annulation. |
| Perte de focus | Annulation. |
| Nom vide | Annulation silencieuse. |

---

## Tests ajoutés (`global_story_studio_behavior_test.dart`)

| Test | Objectif |
|------|----------|
| `reorderChapterStepIdsAfterMovingWithinSameChapter moves after ref` | Réordonnancement intra-chapitre. |
| `returns null if id missing` | Garde-fou. |
| `cross-chapter: remove then insert after` | Pas de doublon dans le chapitre cible. |
| `chapterStepIdsInsertingAfterReference rejects duplicate insert` | Anti-doublon. |
| `same-chapter: global step id order and chapter.stepIds stay aligned` | Alignement liste globale vs `stepIds`. |
| `cross-chapter: global order vs chapter membership` | Modèle retrait chapitre B + insertion chapitre A. |
| `eligibleStepIdsForGlobalStoryInsertPicker lists all except current` | Picker = tout le projet sauf courant. |
| `tap chevron toggles expansion; add chapter does not only collapse` | Toggle vs bouton « ajouter chapitre ». |
| `double-tap chapter title opens field; enter commits rename` | Renommage inline widget. |
| `Insérer opens sheet listing other project steps` | Picker inline : libellé `#2. …` + step courante visible. |

**Commande** : `flutter test test/global_story_studio_behavior_test.dart test/global_story_studio_ux_test.dart`

---

## Risques restants

- **Délai toggle** sur le titre (voir compromis).
- **Autres opérations** (hors « insert existing ») pourraient théoriquement désynchroniser `stepIds` et ordre global — non couvertes ici.
- **Picker** : borné au `StepStudioDocument` du scénario édité (pas « toutes les steps de tous les scénarios »).

---

## Limites connues

- Pas d’assertion widget sur le contenu exact de `CupertinoActionSheet` sous test VM.
- Warnings analyse préexistants dans `global_story_studio_workspace.dart` (code mort, `minSize` déprécié) non traités dans ce lot.

---

## Extraits / symboles utiles

- `reorderChapterStepIdsAfterMovingWithinSameChapter` — `global_story_studio_authoring.dart`
- `_ChapterHeader.build` — `global_story_studio_workspace.dart`
- `_ChapterNameDisplay` — `onAccordionToggle` + `onDoubleTap`

---

*Mise à jour après compléments UX header, extraction logique pure, et tests ciblés — pas d’opération Git associée.*
