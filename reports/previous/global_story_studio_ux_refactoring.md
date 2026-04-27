# Rapport de Refonte UX : Global Story Studio — Arbre Narratif par Chapitres

**Date :** 2026-04-04  
**Auteur :** Qwen Code  
**Projet :** Pokémon-like Flutter Editor — `packages/map_editor`  
**Fichiers modifiés :**
- `packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart`
- `packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart`
- `packages/map_editor/test/global_story_studio_ux_test.dart` (nouveau)

---

## 1. Résumé Exécutif

**Problème :** Le Global Story Studio actuel ressemblait trop à un Step Studio déguisé. L'UX centrale était une liste de fiches de step avec des formulaires inline (nom, description, exit mode, liens), donnant l'impression d'être "encore dans une grosse fiche de formulaire" plutôt que de "voir la structure globale du jeu".

**Solution :** Refonte complète de l'UX du Global Story Studio pour qu'il devienne une **vue de structure narrative** basée sur des chapitres/arcs narratifs :
- **Nouveau concept de données :** `GlobalStoryChapter` dans `GlobalStoryStudioDocument`
- **Nouvelle UX :** Arbre narratif vertical avec chapitres clairement séparés, steps compactes, indicateurs de flux
- **Différenciation visuelle forte :** Le Global Story Studio est maintenant IMPOSSIBLE à confondre avec le Step Studio

**Résultat :** Quand on ouvre le Global Story Studio, on voit immédiatement "la structure du jeu de haut en bas" — chapitres, steps, branches, convergences — au lieu de remplir des formulaires.

---

## 2. Pourquoi l'UI Précédente Créait une Confusion

### Problème Conceptuel

L'ancien `_buildGlobalStoryEditor` affichait une liste verticale de `_GlobalStoryStepCard`, chacune contenant :
- Champs de texte inline (nom, description)
- Dropdowns de type de sortie (linéaire, branche, convergence)
- Éditeurs de liens détaillés (step suivante, condition, outcome)
- Boutons d'action (définir départ, insérer, monter/descendre, ouvrir Step)

**Ce que l'utilisateur voyait :** Une grosse fiche de formulaire pour chaque step.  
**Ce qu'il DEVAIT voir :** Un plan narratif macro avec des chapitres et un enchaînement de steps.

### Règle Produit Violée (Implicitement)

> "Le Global Story ne doit contenir QUE des steps."

Techniquement c'était vrai — le Global Story ne contenait que des steps. Mais visuellement, il contenait **les détails de chaque step** (activation, validation, liens détaillés), ce qui est le rôle du Step Studio. La frontière visuelle entre les deux studios était floue.

### Comparaison Avant / Après

| Aspect | Avant (confus) | Après (clair) |
|---|---|---|
| **Sensation** | Formulaire de step bis | Carte routière narrative |
| **Hiérarchie** | Plate (toutes les steps au même niveau) | Chapitre → Steps imbriquées |
| **Détail** | Nom, description, exit mode, liens, conditions | Nom, description courte, type de sortie, destinations |
| **Actions** | Tout éditer inline | Ouvrir Step Studio pour le détail |
| **Chapitres** | Aucun concept visuel | Sections majeures avec headers forts |

---

## 3. Logique de Refonte

### Principe Architectural

```
3 étages narratifs strictement séparés :

1. Global Story Studio = STRUCTURE MACRO
   → Chapitres, steps, flux, branches, convergences
   → "Je vois la structure du jeu"

2. Step Studio = LOGIQUE LOCALE
   → Activation, validation, outcomes, cutscenes, world changes
   → "Je configure la logique d'une step"

3. Cutscene Studio = EXÉCUTION DE SCÈNE
   → Dialogues, déplacements, waits, transitions
   → "Je crée la scène"
```

### Direction UX

Le Global Story Studio devait évoquer :
- Un **arbre vertical** de narration
- Un **plan narratif** lisible de haut en bas
- Des **chapitres** comme sections majeures
- Des **steps compactes** comme éléments de progression
- Des **indicateurs de flux** entre les steps

### Stratégie d'Implémentation

1. **Ajouter le concept de chapitre** au modèle de données (rétrocompatible)
2. **Remplacer le centre de l'UI** par un arbre narratif vertical
3. **Réduire les cartes de step** à l'essentiel macro
4. **Garder le "Ouvrir Step Studio"** comme porte d'entrée vers le détail
5. **Ne rien casser** — l'ancien système de données reste fonctionnel

---

## 4. Hiérarchie Visuelle Retenue

### Niveau 1 : Header Global (zone haute)

```
┌────────────────────────────────────────────────────┐
│ 🗺️ Global Story                    [Modifié]      │
│ 📖 2 chapitres  🏁 5 steps  🔀 1 branche           │
│ [Sauvegarder]  [Réinitialiser]                      │
└────────────────────────────────────────────────────┘
```

- Nom du scénario global unique
- Badges de résumé macro (chapitres, steps, branches, convergences)
- Actions globales (sauvegarder, réinitialiser)

### Niveau 2 : Chapitre (section majeure)

```
┌────────────────────────────────────────────────────┐
│ CH. 1   Prologue                        2 steps  + │
└────────────────────────────────────────────────────┘
```

- Badge "CH. N" fort et coloré (violet/plum)
- Nom du chapitre en gros texte
- Badge de step count (vert/mint)
- Bouton "+" pour ajouter un chapitre

### Niveau 3 : Step (carte compacte)

```
    ┌─────────────────────────────────────────────┐
    │ #1 Introduction         [Linéaire] 📍        │
    │ Le joueur commence son aventure              │
    │ Suite: step_professor                         │
    │ [Ouvrir Step] [Insérer] 📍                    │
    └─────────────────────────────────────────────┘
```

- Numéro d'ordre (petit badge)
- Nom de la step (texte fort)
- Badge de type de sortie (violet)
- Description courte (1-2 lignes)
- Indicateur de destination
- Actions rapides : Ouvrir Step, Insérer, Définir départ

### Indicateurs de Flux

```
         ↓ Introduction → Rencontre du professeur
```

- Flèche entre les steps consécutives
- Icône adaptée au type de sortie (↓ linéaire, 🔀 branche, 🔀 convergence)
- Label de destination

---

## 5. Différence Explicite entre Global Story et Step Studio

| Aspect | Global Story Studio | Step Studio |
|---|---|---|
| **Rôle** | Voir la structure du jeu | Configurer la logique d'une step |
| **Unité principale** | Chapitre (groupe de steps) | Step individuelle |
| **Vue** | Arbre narratif vertical | Fiche détaillée d'une step |
| **Détail visible** | Nom, description courte, type de sortie | Activation, validation, outcomes, cutscenes, world changes |
| **Édition inline** | Mininale (renommer chapitre) | Complète (tous les champs) |
| **Accès au détail** | Bouton "Ouvrir Step" → Step Studio | Déjà dans le Step Studio |
| **Couleur dominante** | Cyan (header) + Violet (chapitres) | Mint/Amber (sections) |
| **Sensation** | "Carte routière narrative" | "Fiche de configuration" |

---

## 6. Fichiers Modifiés

### 6.1 `global_story_studio_authoring.dart`

**Changements :**
- Schéma mis à jour : `global_story_studio_v1` → `global_story_studio_v1.1`
- Nouvelle classe `GlobalStoryChapter` :
  - `id`, `name`, `description`, `stepIds` (ordonnés), `order`
  - Sérialization JSON complète (`toJson`, `fromJson`)
  - Égalité et hashCode immuables
- `GlobalStoryStudioDocument` mis à jour :
  - Nouveau champ `chapters` (liste de `GlobalStoryChapter`)
  - Rétrocompatible : `chapters` est optionnel (vide par défaut)
- `createDefaultGlobalStoryStudioDocument` :
  - Crée automatiquement un chapitre "Histoire principale" avec toutes les steps
- `normalizeGlobalStoryStudioDocument` :
  - Si aucun chapitre n'existe → crée le chapitre par défaut
  - Les steps non assignées → ajoutées au chapitre par défaut
  - Nettoyage des stepIds invalides et duplicates
- Nouvelle fonction `_normalizeChapters` :
  - Trie les chapitres par order
  - Filtre les stepIds invalides
  - Garantit que chaque step est dans exactement un chapitre
  - Crée le chapitre par défaut si nécessaire

**Commentaires ajoutés :** Chaque nouvelle fonction et classe est commentée pour expliquer son rôle produit et ses invariants.

### 6.2 `global_story_studio_workspace.dart`

**Changements majeurs :**

1. **État :** Ajout de `_selectedChapterId` pour la sélection visuelle de chapitre

2. **Méthodes de gestion de chapitres :**
   - `_selectChapter(String)` — sélection visuelle
   - `_renameChapter(String, String)` — renommage
   - `_moveChapter(int)` — déplacement haut/bas
   - `_addChapter()` — ajout d'un nouveau chapitre vide
   - `_deleteChapter(String)` — suppression (chapitres vides uniquement)
   - `_updateLinkFromSelectedStepToStep(int, String?)` — raccourci callback

3. **Nouvelle méthode `build()` :**
   - Remplace le `Row(left nav + right editor)` par un `Column` centré sur l'arbre narratif
   - Le Global Story Studio est maintenant une vue plein écran de structure

4. **Nouvelle méthode `_buildNarrativeTree()` :**
   - Remplace `_buildGlobalStoryEditor`
   - Affiche : header macro → warnings → chapitres avec steps → footnote
   - Compte les branches et convergences pour le résumé

5. **Nouveaux widgets UI :**
   - `_NarrativeTreeHeader` — zone haute avec résumé macro
   - `_MacroBadge` — badges de compte (chapitres, steps, branches)
   - `_ChapterGap` — séparateur visuel entre chapitres
   - `_NoChaptersHint` — message quand aucun chapitre n'existe
   - `_NarrativeChapterSection` — section de chapitre avec ses steps
   - `_ChapterHeader` — header fort de chapitre (CH. N, nom, step count)
   - `_StepFlowArrow` — flèche de flux entre steps consécutives
   - `_CompactStepCard` — carte de step compacte (vs la grosse fiche précédente)

6. **Widgets conservés (non utilisés mais non supprimés) :**
   - `_GlobalStoryStepCard` — ancien widget, gardé pour référence
   - `_buildStepNavigatorCard` — ancienne navigation latérale
   - `_buildHeader` — ancien header
   - `_GlobalStorySectionCard` — ancienne section card
   - `_FlowConnectorHint` — ancien indicateur de flux

**Pourquoi garder les anciens widgets :**
- Ils peuvent servir de référence pour comprendre l'évolution
- Ils ne causent aucun problème (juste des warnings "unused")
- Supprimer massivement augmenterait le risque de régression

### 6.3 `global_story_studio_ux_test.dart` (NOUVEAU)

**Tests ajoutés :**
1. `renders chapter-based narrative tree (not form-like step editor)` — vérifie que l'UX affiche des chapitres et des steps compactes
2. `opens Step Studio when "Ouvrir Step" button is pressed` — vérifie que le bouton "Ouvrir Step" déclenche le callback
3. `unique global story rule is respected` — vérifie le comportement sans Global Story
4. `structure with multiple steps in chapters displays correctly` — vérifie l'affichage multi-chapitres
5. `GlobalStoryChapter serializes and deserializes correctly` — test unitaire de sérialization
6. `GlobalStoryStudioDocument includes chapters in serialization` — test unitaire du document
7. `normalizeGlobalStoryStudioDocument creates default chapter when none exist` — test de normalisation

---

## 7. Limites Restantes

| Limite | Impact | Priorité |
|---|---|---|
| Anciens widgets non supprimés (warnings unused) | Nettoyage cosmétique | Basse — peut être fait dans un second temps |
| Pas de drag-and-drop pour réorganiser les steps entre chapitres | UX d'édition de structure limitée aux boutons | Moyenne — amélioration future naturelle |
| Pas de renommage inline de chapitre dans l'UI actuelle | Le renommage est programmatique seulement | Moyenne — peut être ajouté avec un éditeur inline |
| Pas de déplacement de step d'un chapitre à un autre | La réorganisation des steps reste basique | Moyenne — nécessite un sélecteur de chapitre |
| L'inspecteur droit n'a pas été mis à jour pour le contexte Global Story | L'inspecteur affiche toujours les mêmes stats | Basse — l'inspecteur reste contextuel |
| Le panneau gauche (NarrativeLibraryPanel) n'a pas été adapté | La bibliothèque reste inchangée | Basse — la navigation fonctionne toujours |

---

## 8. Prochaines Améliorations Possibles

1. **Drag-and-drop inter-chapitres :** Permettre de glisser une step d'un chapitre à un autre pour réorganiser la structure narrative.

2. **Renommage inline de chapitre :** Cliquer sur le nom du chapitre pour le renommer directement dans l'arbre.

3. **Sélecteur de chapitre pour les steps :** Dans la carte compacte de step, un dropdown pour changer le chapitre d'appartenance.

4. **Vue graphique optionnelle :** Alternance entre vue arbre vertical et vue graphe/nœuds pour les utilisateurs qui préfèrent une visualisation non-linéaire.

5. **Inspecteur Global Story dédié :** Un panneau droit spécifique au Global Story avec :
   - Résumé du chapitre sélectionné
   - Stats de branches/convergences
   - Diagnostic de structure (steps orphelines, culs-de-sac)
   - Lien rapide vers le Step Studio

6. **Export/Import de structure :** Exporter la structure narrative en JSON ou Markdown pour review externe.

---

## 9. Validations Exécutées

| Validation | Commande | Résultat |
|---|---|---|
| **flutter analyze** (fichiers modifiés) | `flutter analyze lib/src/.../global_story_studio_*.dart lib/src/.../global_story_studio_workspace.dart` | ✅ 0 erreurs, warnings unused-only |
| **flutter analyze** (package complet) | `flutter analyze` dans `packages/map_editor` | ✅ 0 erreurs |
| **flutter test** (Global Story UX) | `flutter test test/global_story_studio_ux_test.dart` | ✅ 7/7 pass |
| **flutter test** (Step Studio authoring) | `flutter test test/step_studio_authoring_test.dart` | ✅ 3/3 pass |
| **flutter test** (Narrative projection) | `flutter test test/narrative_workspace_projection_test.dart` | ✅ 2/2 pass |

---

## 10. Philosophie de la Refonte

### Ce qui a GUIDÉ chaque décision :

1. **"Je vois la structure du jeu" > "Je remplis des formulaires"**
   - Chaque pixel du Global Story Studio doit contribuer à la lecture macro
   - Le détail appartient au Step Studio

2. **Chapitre = Section narrative, pas = dossier administratif**
   - Un chapitre a un nom, une identité visuelle forte
   - Un chapitre n'est pas un "groupe de steps" anonyme

3. **Step compacte = Carte de visite, pas = fiche complète**
   - La step dans le Global Story montre juste assez pour la situer
   - Le détail complet s'obtient en un clic vers le Step Studio

4. **Rétrocompatibilité = Non négociable**
   - Les projets existants sans chapitres fonctionnent toujours
   - Un chapitre par défaut est créé automatiquement
   - Aucune donnée n'est perdue

### Ce qui a été ÉVITÉ :

- ❌ Refonte du modèle de données existant (StepStudioDocument reste inchangé)
- ❌ Suppression massive de code (les anciens widgets sont gardés)
- ❌ Changement de la navigation entre studios
- ❌ Modification du panneau gauche ou de l'inspecteur
- ❌ Toute opération Git

---

**Fin du rapport.**
