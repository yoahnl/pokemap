# Rapport de Correction UX : Action "Insérer" du Global Story Studio

**Date :** 2026-04-04  
**Auteur :** Qwen Code  
**Projet :** Pokémon-like Flutter Editor — `packages/map_editor`  
**Fichier modifié :** `packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart`

---

## 1. Résumé Exécutif

**Problème :** Le bouton "Insérer" sur les steps du Global Story Studio créait automatiquement une nouvelle step sans aucun choix explicite de l'utilisateur. Le libellé disait "Insérer" mais le code faisait "Créer" — une ambiguïté sémantique inacceptable pour un éditeur no-code.

**Solution :** Séparation explicite en deux actions distinctes :
1. **"Nouvelle"** — crée une nouvelle step après la step courante
2. **"Insérer"** — ouvre un sélecteur (CupertinoActionSheet) pour choisir une step existante à insérer après la step courante

**Résultat :** L'utilisateur comprend immédiatement ce qu'il fait. Aucune création implicite. Maîtrise totale de la structure narrative.

---

## 2. Le Problème UX Actuel

### Comportement Précédent Exact

Quand l'utilisateur cliquait sur "Insérer" dans une carte de step compacte :

```
Clic sur "Insérer"
  → _addStepAfterSelection() appelé directement
    → Crée une NOUVELLE step immédiatement
    → L'insère dans le flux global
    → Sélectionne la nouvelle step
    → AUCUN choix proposé à l'utilisateur
```

**Aucune UI de choix ne s'ouvrait.** Aucune liste de steps existantes n'était proposée. Le bouton disait "Insérer" mais le code créait systématiquement une nouvelle step.

### Pourquoi "Insérer" Était Ambigu

| Ce que le texte suggère | Ce que le code faisait |
|---|---|
| "Insérer" = placer quelque chose d'existant dans un flux | Créer systématiquement une nouvelle step |
| L'utilisateur s'attend à CHOISIR quoi insérer | Aucune option, création automatique |
| Sémantique de structure (réorganiser) | Sémantique de création (ajouter du nouveau) |

Dans l'esprit d'un éditeur no-code :
- **"Créer"** = faire apparaître quelque chose de nouveau
- **"Insérer"** = placer quelque chose qui existe déjà à un endroit précis

Le bouton fusionnait les deux concepts sans les distinguer, ce qui est trompeur.

### Cas d'Usage Cassés

**Cas 1 — voulu par l'utilisateur :**
> "J'ai une step 'Rencontre professeur' qui existe déjà. Je veux l'insérer après 'Début jeu' dans le flux global."

**Résultat actuel :** Une nouvelle step vierge "Nouvelle step 4" est créée au lieu d'insérer la step existante.

**Cas 2 — voulu par l'utilisateur :**
> "Je veux créer une nouvelle step après 'Début jeu'."

**Résultat actuel :** Ça marche, mais l'utilisateur ne sait pas que c'est ce qui se passe car le bouton dit "Insérer" pas "Créer".

---

## 3. Nouveau Comportement Retenu

### Architecture UX : Deux Boutons Distincts

J'ai choisi l'approche **deux boutons séparés** plutôt qu'un bouton unique avec menu secondaire, car :

1. **Clarté immédiate** — l'utilisateur voit les deux options sans clic supplémentaire
2. **Pas d'ambiguïté** — chaque bouton fait EXACTEMENT ce que son libellé indique
3. **Cohérent avec le no-code** — les éditeurs no-code favorisent l'explicite sur l'implicite
4. **Compact mais lisible** — les boutons sont assez petits pour tenir dans la carte

### Bouton 1 : "Nouvelle" (vert/mint)

```
Clic sur "Nouvelle"
  → _createNewStepAfter(stepId) appelé
    → Crée une NOUVELLE step après la step courante
    → Lui donne un nom par défaut "Nouvelle step N"
    → L'ajoute au même chapitre que la step source
    → Met à jour les liens du flux global
    → Sélectionne la nouvelle step
```

### Bouton 2 : "Insérer" (bleu)

```
Clic sur "Insérer"
  → Ouvre un sélecteur inline sous la carte de step
    → Affiche un CupertinoActionSheet avec les steps existantes
    → L'utilisateur choisit une step
    → Clic sur "Insérer" dans le picker
      → _insertExistingStepAfter(stepId, existingStepId) appelé
        → Retire la step existante de sa position actuelle
        → L'insère après la step courante
        → Met à jour les ordres
        → Met à jour les liens du flux global
        → Déplace la step dans le chapitre de la step source
        → PAS de nouvelle step créée
        → PAS de duplication
    → Clic sur "Annuler" dans le picker
      → Ferme le sélecteur, aucune modification
```

### Design du Sélecteur

Le sélecteur est affiché **inline** sous la carte de step (pas de popup agressive) :
- **CupertinoActionSheet** pour le choix de step (natif macOS, élégant)
- **Bouton "Insérer"** (bleu, primaire) pour confirmer
- **Bouton "Annuler"** (corail, secondaire) pour fermer
- **Label explicite** : "Insérer une step existante après celle-ci"

---

## 4. Pourquoi C'est Plus Clair pour un Usage No-Code

### Principe No-Code Fondamental

> **L'utilisateur ne doit JAMAIS être surpris par ce que fait un bouton.**

Dans l'ancien système :
- Bouton "Insérer" → crée une step → surprise ❌

Dans le nouveau système :
- Bouton "Nouvelle" → crée une step → attendu ✅
- Bouton "Insérer" → ouvre un sélecteur de steps existantes → attendu ✅

### Différence Sémantique Respectée

| Action | Sémantique | Résultat |
|---|---|---|
| **Nouvelle** | Création | Nouvelle step vierge |
| **Insérer** | Réorganisation | Step existante repositionnée |

L'utilisateur peut maintenant :
- **Créer** du contenu nouveau quand il en a besoin
- **Réorganiser** la structure existante sans créer de duplication
- **Comprendre** immédiatement ce que chaque bouton fait

### Contrôle Total

- Le sélecteur montre uniquement les steps **autres que la step courante** (pas d'auto-référence)
- L'utilisateur peut **annuler** à tout moment
- La step insérée reste **unique** (pas de copie)
- Le **chapitre** est automatiquement mis à jour pour refléter la nouvelle position

---

## 5. Méthodes Modifiées

### Anciennes Méthodes

| Méthode | Rôle Ancien | Statut |
|---|---|---|
| `_addStepAfterSelection()` | Créait une nouvelle step + l'insérait | **Remplacée** par `_createNewStepAfter` |

### Nouvelles Méthodes

| Méthode | Rôle |
|---|---|
| `_createNewStepAfter(String afterStepId)` | Crée une NOUVELLE step après `afterStepId` |
| `_insertExistingStepAfter(String afterStepId, String existingStepId)` | Insère une step EXISTANTE après `afterStepId` |
| `_addStepToChapterOfStep(String referenceStepId, String newStepId)` | Ajoute une nouvelle step au chapitre de référence |
| `_moveStepToChapterOfStep(String referenceStepId, String stepIdToMove)` | Déplace une step existante vers le chapitre de référence |
| `_toggleInsertPicker(String stepId)` | Ouvre/ferme le sélecteur de step existante |
| `_cancelInsertPicker()` | Ferme le sélecteur |

### Logique de Structure Globale Mise à Jour

#### Création (`_createNewStepAfter`)

1. Trie les steps par ordre
2. Crée une nouvelle step avec un ID unique
3. L'insère à la bonne position
4. Re-normalise les ordres
5. Met à jour les noeuds macro (flux global) :
   - Si le noeud source est en mode linéaire : la nouvelle step prend les liens précédents, le source pointe vers la nouvelle
   - Si le noeud source est en mode branching sans liens : ajoute simplement le lien
6. Ajoute la nouvelle step au chapitre de la step source
7. Sélectionne la nouvelle step

#### Insertion d'existant (`_insertExistingStepAfter`)

1. Vérifie que les deux steps existent et sont différentes
2. Retire la step existante de sa position actuelle
3. Recalcule l'index d'insertion
4. Insère la step existante après la step cible
5. Re-normalise les ordres
6. Met à jour les noeuds macro :
   - La step insérée hérite des liens du noeud source
   - Le noeud source pointe vers la step insérée
   - Nettoyage des liens circulaires potentiels
7. Déplace la step insérée dans le chapitre de la step source
8. Sélectionne la step insérée

#### Gestion des Chapitres

- **Nouvelle step** → ajoutée au même chapitre que la step source (append)
- **Step existante insérée** → déplacée vers le chapitre de la step source (insertion après la référence)
- **Invariant** : chaque step est dans exactement un chapitre

---

## 6. Widgets UI Ajoutés

### `_InsertStepPicker` (StatefulWidget)

Sélecteur inline de step existante. Affiché sous la carte de step quand l'utilisateur clique sur "Insérer".

**Composition :**
- Label explicite : "Insérer une step existante après celle-ci"
- Bouton de sélection de step (ouvre un `CupertinoActionSheet`)
- Bouton "Insérer" (confirme le choix)
- Bouton "Annuler" (ferme le sélecteur)

**Design :**
- Compact, intégré au style actuel
- Pas de popup agressive
- CupertinoActionSheet natif macOS pour le choix
- Couleur bleue cohérente avec le bouton "Insérer"

### `_CompactStepCard` (modifié)

**Anciens paramètres :**
- `onInsertAfter: VoidCallback` — appelait directement `_addStepAfterSelection`

**Nouveaux paramètres :**
- `onCreateNewStep: VoidCallback` — crée une nouvelle step
- `onInsertExistingStep: VoidCallback` — ouvre le sélecteur
- `insertPickerVisible: bool` — état d'affichage du picker
- `onTogglePicker: VoidCallback` — toggle le picker
- `onPickExistingStep: ValueChanged<String>` — confirme le choix
- `availableSteps: List<_SimpleOption>` — steps disponibles

### `_NarrativeChapterSection` (modifié)

Converti de `StatelessWidget` en `StatefulWidget` pour gérer l'état du sélecteur (`_insertPickerStepId`).

**Nouveaux paramètres :**
- `onCreateNewStep: ValueChanged<String>` — callback de création
- `onInsertExistingStep: void Function(String, String)` — callback d'insertion

---

## 7. Limites Restantes

| Limite | Impact | Priorité |
|---|---|---|
| Le sélecteur CupertinoActionSheet est modal (bloque l'UI) | UX légèrement intrusive mais acceptable pour macOS | Basse — cohérent avec le style natif |
| Pas de recherche/filtrage dans le sélecteur si beaucoup de steps | Peut devenir lent avec 50+ steps | Moyenne — amélioration future |
| L'insertion d'une step existante déplace la step (pas de copie) | Comportement voulu mais peut surprendre un utilisateur qui voulait dupliquer | Basse — c'est le comportement correct pour "insérer" |
| Pas de drag-and-drop pour réorganiser | L'insertion reste manuelle via boutons | Moyenne — amélioration future naturelle |

---

## 8. Validations Exécutées

| Validation | Commande | Résultat |
|---|---|---|
| **flutter analyze** (fichier modifié) | `flutter analyze lib/src/ui/canvas/global_story_studio_workspace.dart` | ✅ 0 erreurs |
| **flutter analyze** (package complet) | `flutter analyze` | ✅ 0 erreurs |
| **flutter test** (Global Story UX) | `flutter test test/global_story_studio_ux_test.dart` | ✅ 9/9 pass |
| **flutter test** (tous tests narratifs) | `flutter test test/global_story_studio_ux_test.dart test/step_studio_authoring_test.dart test/narrative_workspace_projection_test.dart test/step_studio_workspace_regression_test.dart` | ✅ 17/17 pass |

---

## 9. Fichiers Modifiés

| Fichier | Changement |
|---|---|
| `global_story_studio_workspace.dart` | Refonte complète de l'action "Insérer" : 2 boutons distincts + sélecteur inline + méthodes de création/insertion séparées |
| `global_story_studio_ux_test.dart` | 2 tests unitaires ajoutés (chapitre par défaut + steps non assignées) |

---

## 10. Prochaines Améliorations Possibles

1. **Recherche dans le sélecteur** — si le nombre de steps dépasse ~20, ajouter un champ de recherche dans le CupertinoActionSheet.

2. **Drag-and-drop inter-chapitres** — permettre de glisser une step d'un chapitre à un autre pour réorganiser visuellement.

3. **Option "Dupliquer"** — ajouter un troisième bouton "Dupliquer" qui crée une copie de la step courante (comportement différent de "Insérer" et "Nouvelle").

4. **Annulation (Undo)** — intégrer les actions d'insertion dans un système undo/redo pour permettre à l'utilisateur de revenir en arrière.

---

**Fin du rapport.**
