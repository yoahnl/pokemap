# Plan d'Action Détaillé - Système d'Accordéon des Chapitres (Global Story Studio)

## 0. RÉSUMÉ EXÉCUTIF

Ce document propose un plan d'action structuré pour implémenter un système d'accordéon élégant et performant pour les chapitres du Global Story Studio, en respectant l'esthétique macOS/macOS_ui du projet. Après analyse comparative de trois approches, **la recommandation finale est une implémentation custom légère utilisant des briques natives Flutter** (AnimatedSize, ClipRect, AnimatedRotation), qui offre le meilleur compromis entre contrôle UX, cohérence visuelle avec macos_ui, maintenabilité et performance.

**Plan en 5 étapes**:
1. Préparation et tests de non-régression
2. Refactoring du widget `_NarrativeChapterSection` avec solution custom
3. Implémentation de la logique d'expansion avec animations fluides
4. Intégration et validation de la synchronisation steps/nodes/chapters
5. Tests finaux et documentation

---

## 1. CONTEXTE PRODUIT ET TECHNIQUE

### 1.1. Vision Produit
Le Global Story Studio doit être une vue MACRO du jeu, orientée structure narrative, avec:
- Lecture top-down claire
- Chapitres bien mis en avant
- Interface chaleureuse et lisible
- Esthétique macOS/custom (macos_ui)
- Pas d'apparence Material décalée

### 1.2. Architecture Narrative (Rappel)
**Séparation stricte à 3 niveaux**:
- **Global Story** = structure macro (chapitres, ordre des steps, branches, convergences)
- **Step** = logique locale (activation, validation, outcomes, cutscenes liées)
- **Cutscene** = exécution (dialogues, pathfinding, mouvements, animations)

**Règle absolue**: Un seul scénario global dans le jeu.

### 1.3. État Actuel
- Chapitres introduits avec une lecture verticale
- Synchronisation améliorée entre StepStudioDocument et GlobalStoryStudioDocument
- Accordéon actuellement implémenté de manière basique (rendu conditionnel sans animation)
- Utilisation de `_expandedChapters` (Set<String>) pour gérer l'état

---

## 2. ANALYSE DES BESOINS

### 2.1. Besoins UX
- Animation fluide d'ouverture/fermeture des chapitres
- Séparation claire entre:
  - Clic pour ouvrir/fermer le chapitre
  - Clic pour sélectionner le chapitre
  - Actions du header (renommer, déplacer, etc.)
- Chapitre fermé reste informatif (résumé visible)
- Chapitre ouvert affiche les steps en flux vertical
- Cohérence visuelle avec macos_ui

### 2.2. Besoins Techniques
- Utiliser des briques natives Flutter d'animation
- Préserver l'esthétique custom/macOS
- Ne pas casser la synchronisation existante
- Maintenir la performance avec 50+ chapitres
- Garantir la maintenabilité du code

### 2.3. Contraintes
- Pas de Material widgets visuellement décalés
- Pas de ExpansionTile/ExpansionPanelList si incompatibles avec macos_ui
- Garder la structure top-down lisible
- Préserver tous les callbacks existants

---

## 3. COMPARAISON DES APPROCHES

### 3.1. Option A: ExpansionTile (Material)

#### Description
Widget Material Flutter natif avec animation intégrée.

#### Avantages
- Animation native optimisée
- Gestion automatique de l'état
- Peu de code à écrire

#### Inconvénients
- ❌ **Apparence Material incompatible avec macos_ui**
- ❌ **Style difficilement personnalisable**
- ❌ **Confusion possible entre toggle et sélection**
- ❌ **Header structuralement rigide**
- ❌ **Casserait l'esthétique macOS de l'éditeur**

#### Compatibilité macos_ui
**Très faible**: Le style Material jurerait visuellement avec le reste de l'interface.

#### Verdict
🔴 **Rejeté**: Incompatible avec notre esthétique et notre philosophie produit.

---

### 3.2. Option B: ExpansionPanelList (Material)

#### Description
Widget Material pour listes de panneaux expansibles.

#### Avantages
- Gestion de multiples panneaux
- Animations natives

#### Inconvénients
- ❌❌ **Totalement inadapté à notre cas d'usage**
- ❌❌ **Apparence encore plus Material**
- ❌❌ **Structure imposée incompatible**
- ❌❌ **Créerait un décalage visuel majeur**

#### Compatibilité macos_ui
**Nulle**: Complètement étranger à notre contexte narratif et esthétique.

#### Verdict
🔴🔴 **Rejeté catégoriquement**: Widget inadapté.

---

### 3.3. Option C: Solution Custom avec Briques Natives Flutter

#### Description
Implémentation personnalisée utilisant:
- `AnimatedSize` pour l'animation de hauteur
- `ClipRect` pour le clipping pendant l'animation
- `AnimatedRotation` pour le chevron d'expansion
- `AnimatedOpacity` pour les transitions de contenu
- Widgets custom pour le header

#### Avantages
- ✅ **Contrôle total sur l'apparence et le comportement**
- ✅ **Intégration parfaite avec macos_ui**
- ✅ **Séparation claire des interactions**
- ✅ **Animations fluides et personnalisables**
- ✅ **Maintien de l'esthétique macOS**
- ✅ **Flexibilité maximale pour l'UX**
- ✅ **Pas de compromis visuel**

#### Inconvénients
- ⚠️ **Plus de code à écrire** (mais reste modeste: ~150-200 lignes)
- ⚠️ **Responsabilité de l'implémentation des animations**

#### Compatibilité macos_ui
**Parfaite**: Utilisation directe des styles et composants macos_ui sans conflit.

#### Verdict
✅✅ **Recommandé**: Meilleure solution technique et UX.

---

## 4. RECOMMANDATION FINALE

### 4.1. Option Choisie: Solution Custom (Option C)

**Justification détaillée**:

1. **Esthétique**: Préservation parfaite de l'apparence macOS/custom
2. **Contrôle UX**: Séparation claire entre toggle, sélection et actions
3. **Animation**: Fluidité native via les briques Flutter
4. **Maintenabilité**: Code simple, élégant, sans contorsion
5. **Performance**: Animations optimisées par le moteur Flutter
6. **Cohérence**: Alignement avec la philosophie produit no-code

### 4.2. Widgets à Utiliser

| Widget | Rôle | Pourquoi |
|--------|------|----------|
| `AnimatedSize` | Animation de la hauteur du contenu | Transition fluide entre ouvert/fermé |
| `ClipRect` | Clipping pendant l'animation | Évite le débordement visuel |
| `AnimatedRotation` | Rotation du chevron | Animation élégante de l'icône |
| `AnimatedOpacity` | Fondu du contenu | Transition douce |
| `GestureDetector` | Gestion des interactions | Séparation toggle/sélection |
| `Container` + `Decoration` | Style custom | Cohérence avec macos_ui |

### 4.3. Widgets à NE PAS Utiliser

| Widget | Pourquoi l'éviter |
|--------|------------------|
| `ExpansionTile` | Apparence Material incompatible |
| `ExpansionPanelList` | Structure inadaptée, trop Material |
| `AnimatedContainer` seul | Moins fluide que AnimatedSize pour la hauteur |

---

## 5. PLAN D'ACTION DÉTAILLÉ

### ÉTAPE 1: Préparation et Analyse (1-2h)

#### Objectif
Comprendre l'existant et préparer le terrain sans casser.

#### Actions
1. **Lire et documenter** le code actuel de `_NarrativeChapterSection`
2. **Identifier** tous les callbacks et leur usage
3. **Cartographier** les dépendances avec le reste du workspace
4. **Créer** un fichier de tests de non-régression
5. **Vérifier** que la synchronisation steps/nodes/chapters est stable

#### Livrables
- Documentation de l'existant
- Tests de non-régression prêts
- Liste des callbacks à préserver

#### Critères de succès
- Tous les tests passent avant modification
- Compréhension complète du flux de données

---

### ÉTAPE 2: Conception du Nouveau Widget (2-3h)

#### Objectif
Concevoir l'architecture du nouvel accordéon custom.

#### Actions
1. **Définir la structure du widget**:
   ```
   _NarrativeChapterSection (StatefulWidget)
   ├── Header custom (GestureDetector séparé)
   │   ├── GestureDetector (toggle expansion)
   │   │   └── Chevron animé (AnimatedRotation)
   │   ├── GestureDetector (sélection chapitre)
   │   │   └── Nom du chapitre
   │   └── Actions (boutons existants)
   └── Contenu animé
       └── AnimatedSize + ClipRect
           └── Steps du chapitre
   ```

2. **Définir la logique d'animation**:
   - Duration: 250-300ms (fluide mais pas trop rapide)
   - Curve: Curves.easeInOut (naturel)
   - Gestion de l'état via `_expandedChapters` existant

3. **Définir la gestion des interactions**:
   - Clic sur chevron → toggle expansion
   - Clic sur nom du chapitre → sélection
   - Clic sur actions → callbacks existants

4. **Préparer le design**:
   - Conserver les couleurs et styles actuels
   - Maintenir la hiérarchie visuelle
   - Préserver les badges et indicateurs

#### Livrables
- Architecture widget documentée
- Plan d'animation détaillé
- Matrice des interactions

#### Critères de succès
- Architecture claire et maintenable
- Séparation nette des responsabilités

---

### ÉTAPE 3: Implémentation du Header Custom (2-3h)

#### Objectif
Créer le header avec séparation claire des interactions.

#### Actions
1. **Créer un widget `_ChapterHeaderCustom`**:
   - Row avec chevron à gauche
   - Nom du chapitre au centre (cliquable pour sélection)
   - Actions à droite
   - Chaque zone avec son propre GestureDetector

2. **Implémenter l'animation du chevron**:
   ```dart
   AnimatedRotation(
     turns: isExpanded ? 0.5 : 0.0, // 0° → 90°
     duration: Duration(milliseconds: 250),
     curve: Curves.easeInOut,
     child: Icon(CupertinoIcons.chevron_right, ...),
   )
   ```

3. **Gérer les interactions séparément**:
   - Zone chevron: `onTap` → `_toggleChapterExpansion(chapterId)`
   - Zone nom: `onTap` → `onSelectChapter(chapterId)`
   - Zone actions: callbacks existants

4. **Appliquer le style macos_ui**:
   - Couleurs cohérentes avec le thème
   - Espacements propres
   - Badges et indicateurs conservés

#### Livrables
- Widget `_ChapterHeaderCustom` fonctionnel
- Interactions séparées et testables
- Style cohérent avec l'existant

#### Critères de succès
- Clics distincts fonctionnent correctement
- Apparence conforme au design actuel
- Pas de confusion entre les interactions

---

### ÉTAPE 4: Implémentation du Contenu Animé (3-4h)

#### Objectif
Créer l'animation d'ouverture/fermeture fluide.

#### Actions
1. **Implémenter la structure animée**:
   ```dart
   ClipRect(
     child: AnimatedSize(
       duration: Duration(milliseconds: 300),
       curve: Curves.easeInOut,
       alignment: Alignment.topCenter,
       child: isExpanded
         ? Column(children: [/* steps */])
         : SizedBox.shrink(),
     ),
   )
   ```

2. **Gérer le contenu replié**:
   - Quand fermé: afficher un résumé compact
   - Quand ouvert: afficher les steps complètes
   - Transition fluide entre les deux états

3. **Optimiser la performance**:
   - Utiliser `const` widgets quand possible
   - Éviter les rebuilds inutiles
   - Tester avec 50+ chapitres

4. **Ajouter des effets subtils**:
   - `AnimatedOpacity` pour le contenu
   - Transition douce pour les badges
   - Pas d'animation excessive

#### Livrables
- Contenu animé fonctionnel
- Performance validée
- Transitions fluides

#### Critères de succès
- Animation fluide et naturelle
- Pas de saccade avec beaucoup de chapitres
- Contenu replié reste informatif

---

### ÉTAPE 5: Intégration et Synchronisation (2-3h)

#### Objectif
Intégrer le nouvel accordéon sans casser la synchronisation.

#### Actions
1. **Remplacer l'ancien `_NarrativeChapterSection`** par le nouveau
2. **Vérifier que tous les callbacks fonctionnent**:
   - `onTapChapter`
   - `onRenameChapter`
   - `onMoveChapterUp/Down`
   - `onAddChapter`
   - `onDeleteChapter`
   - `onSelectStep`
   - `onOpenStepStudio`
   - etc.

3. **Tester la synchronisation**:
   - Création de step → apparition correcte
   - Insertion de step → rattachement cohérent
   - Suppression → mise à jour propre
   - Rechargement → état préservé

4. **Valider les invariants**:
   - Chaque step dans exactement un chapitre
   - Pas de step orpheline
   - entryStepId valide
   - Nodes cohérents

#### Livrables
- Intégration complète
- Tous les tests de synchronisation passent
- Invariants garantis

#### Critères de succès
- Zéro régression fonctionnelle
- Synchronisation intacte
- UX améliorée

---

### ÉTAPE 6: Tests et Documentation (2-3h)

#### Objectif
Valider la qualité et documenter.

#### Actions
1. **Tests unitaires**:
   - Toggle expansion
   - Sélection de chapitre
   - Synchronisation steps/chapters
   - Performance avec 50+ chapitres

2. **Tests d'intégration**:
   - Flux complet de création à affichage
   - Rechargement après sauvegarde
   - Interactions multiples

3. **Tests UX**:
   - Fluidité des animations
   - Lisibilité macro
   - Cohérence visuelle
   - Séparation des interactions

4. **Documentation**:
   - Commentaires dans le code
   - Rapport d'implémentation
   - Guide d'utilisation

#### Livrables
- Suite de tests complète
- Documentation à jour
- Code commenté

#### Critères de succès
- Tous les tests passent
- Documentation claire
- Code maintenable

---

## 6. ARCHITECTURE UI PROPOSÉE

### 6.1. Structure du Widget

```
_NarrativeChapterSection (StatefulWidget)
│
├─ _ChapterHeaderCustom (Widget)
│  ├─ GestureDetector (zone toggle)
│  │  └─ AnimatedRotation(chevron)
│  ├─ GestureDetector (zone sélection)
│  │  └─ Nom du chapitre + badges
│  └─ Row (actions)
│     ├─ Bouton renommer
│     ├─ Boutons déplacer
│     └─ Bouton ajouter/supprimer
│
└─ AnimatedContainer (contenu)
   └─ ClipRect
      └─ AnimatedSize
         └─ isExpanded ? stepsContent : summaryContent
```

### 6.2. Gestion des Interactions

| Zone | Action | Résultat |
|------|--------|----------|
| Chevron | Clic | Toggle expansion du chapitre |
| Nom du chapitre | Clic | Sélection du chapitre |
| Bouton renommer | Clic | Ouvrir édition du nom |
| Boutons déplacer | Clic | Déplacer chapitre haut/bas |
| Bouton ajouter | Clic | Créer nouveau chapitre |
| Bouton supprimer | Clic | Supprimer chapitre (si vide) |

### 6.3. Animation Details

| Élément | Type d'animation | Duration | Curve |
|---------|------------------|----------|-------|
| Chevron | Rotation | 250ms | easeInOut |
| Contenu | Size (hauteur) | 300ms | easeInOut |
| Opacité contenu | Fade | 200ms | easeOut |
| Badges | Opacité | 150ms | easeOut |

---

## 7. INVARIANTS À GARANTIR

### 7.1. Invariants de Données
- ✅ Chaque step appartient à exactement un chapitre
- ✅ Pas de step orpheline (toutes assignées)
- ✅ entryStepId pointe vers une step valide
- ✅ Nodes synchronisés avec steps
- ✅ Ordre des steps cohérent
- ✅ Pas de duplication de stepIds

### 7.2. Invariants UX
- ✅ Séparation claire toggle vs sélection
- ✅ Chapitre fermé affiche un résumé utile
- ✅ Chapitre ouvert affiche les steps en flux
- ✅ Animation fluide sans saccade
- ✅ Pas de confusion visuelle avec Step Studio
- ✅ Lecture top-down maintenue

### 7.3. Invariants Techniques
- ✅ Performance stable avec 50+ chapitres
- ✅ Pas de memory leak
- ✅ Rebuilds optimisés
- ✅ État persisté correctement
- ✅ Callbacks tous fonctionnels

---

## 8. FICHIERS À MODIFIER

### 8.1. Fichiers Principaux

| Fichier | Modifications | Impact |
|---------|---------------|--------|
| `packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart` | Refactorisation de `_NarrativeChapterSection`, création de `_ChapterHeaderCustom`, implémentation animations | **Élevé**: Widget principal |

### 8.2. Fichiers de Tests

| Fichier | Modifications |
|---------|---------------|
| `packages/map_editor/test/global_story_studio_accordion_test.dart` | **Nouveau**: Tests de l'accordéon |
| `packages/map_editor/test/global_story_studio_ux_test.dart` | **Mise à jour**: Ajouter tests d'animation |
| `packages/map_editor/test/global_story_studio_authoring_test.dart` | **Vérification**: Synchronisation intacte |

### 8.3. Fichiers Non Modifiés

Les fichiers suivants ne doivent **PAS** être modifiés:
- `packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart` (logique métier intacte)
- `packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart` (inchangé)
- Tous les fichiers de modèles (GlobalStoryChapter, etc.)

---

## 9. STRATÉGIE DE TESTS

### 9.1. Tests Unitaires

#### Tests d'Expansion
```dart
test('Toggle expansion opens closed chapter', ...)
test('Toggle expansion closes opened chapter', ...)
test('Multiple chapters can be expanded simultaneously', ...)
test('Chapter state is preserved after toggle', ...)
```

#### Tests d'Interaction
```dart
test('Click on chevron toggles expansion only', ...)
test('Click on chapter name selects without toggling', ...)
test('Action buttons trigger correct callbacks', ...)
test('No interference between interactions', ...)
```

#### Tests de Synchronisation
```dart
test('New step appears in correct chapter', ...)
test('Inserted step is not duplicated', ...)
test('Deleted step is removed from chapter', ...)
test('Chapter reassignment works correctly', ...)
```

### 9.2. Tests d'Intégration

```dart
test('Full workflow: create chapter → add step → expand → verify', ...)
test('Save and reload preserves chapter states', ...)
test('Animation completes without errors', ...)
test('Performance with 50 chapters remains smooth', ...)
```

### 9.3. Tests de Non-Régression

```dart
test('All existing callbacks still fire', ...)
test('Step selection still works', ...)
test('Chapter rename still works', ...)
test('Chapter reordering still works', ...)
test('Global Story synchronization intact', ...)
```

### 9.4. Tests UX (Manuels)

- [ ] Animation fluide visuellement
- [ ] Pas de saccade avec 50+ chapitres
- [ ] Cohérence avec macos_ui
- [ ] Séparation claire des interactions
- [ ] Résumé de chapitre fermé informatif
- [ ] Lecture top-down naturelle

---

## 10. RISQUES ET POINTS DE VIGILANCE

### 10.1. Risques Techniques

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|------------|
| Performance avec 50+ chapitres | Moyenne | Élevé | Tester explicitement, optimiser si besoin |
| Animation saccadée | Faible | Moyen | Utiliser les bons curves, tester sur device réel |
| Régression callbacks | Faible | Élevé | Tests de non-régression avant implémentation |
| Memory leak | Faible | Élevé | Vérifier disposal des controllers |
| Incohérence synchronisation | Faible | Critique | Tests de sync avant et après |

### 10.2. Risques UX

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|------------|
| Confusion toggle/sélection | Moyenne | Moyen | Zones de clic bien séparées visuellement |
| Animation trop rapide | Moyenne | Faible | Duration 250-300ms, test utilisateur |
| Perte de lisibilité macro | Faible | Élevé | Conserver la structure top-down |
| Décalage visuel avec macos_ui | Faible | Élevé | Utiliser les mêmes styles/couleurs |

### 10.3. Points de Vigilance Critiques

1. **NE PAS casser la synchronisation** steps/nodes/chapters
2. **NE PAS transformer** Global Story en Step Studio bis
3. **NE PAS introduire** d'apparence Material
4. **NE PAS perdre** les callbacks existants
5. **NE PAS réduire** la performance
6. **NE PAS casser** la lecture top-down

---

## 11. CRITÈRES DE SUCCÈS

### 11.1. Critères Techniques
- [ ] Tous les tests passent
- [ ] Performance ≥ performance actuelle
- [ ] Zéro régression fonctionnelle
- [ ] Code commenté et documenté
- [ ] Pas de warnings/analyzer issues

### 11.2. Critères UX
- [ ] Animation fluide et naturelle
- [ ] Séparation claire des interactions
- [ ] Cohérence visuelle avec macos_ui
- [ ] Chapitre fermé reste informatif
- [ ] Lecture top-down améliorée

### 11.3. Critères Produit
- [ ] Global Story reste une vue macro
- [ ] Pas de confusion avec Step Studio
- [ ] Interface no-code préservée
- [ ] Lisibilité narrative améliorée

---

## 12. ESTIMATION TEMPS

| Étape | Temps estimé |
|-------|--------------|
| Étape 1: Préparation | 1-2h |
| Étape 2: Conception | 2-3h |
| Étape 3: Header custom | 2-3h |
| Étape 4: Contenu animé | 3-4h |
| Étape 5: Intégration | 2-3h |
| Étape 6: Tests | 2-3h |
| **Total** | **12-18h** |

---

## 13. CHECKLIST PRÉ-IMPLÉMENTATION

Avant de commencer l'implémentation, vérifier:
- [ ] Plan validé par le responsable produit
- [ ] Tests de non-régression écrits et passants
- [ ] Architecture widget documentée
- [ ] Matrice des interactions validée
- [ ] Design des animations approuvé
- [ ] Performance de référence mesurée
- [ ] Stratégie de rollback prête

---

## 14. CONCLUSION

Ce plan d'action propose une approche structurée en 6 étapes pour implémenter un système d'accordéon élégant et performant pour les chapitres du Global Story Studio. La solution custom basée sur des briques natives Flutter (AnimatedSize, ClipRect, AnimatedRotation) offre le meilleur compromis entre:

- **Contrôle UX total** (séparation des interactions)
- **Cohérence visuelle** (macOS/macOS_ui)
- **Performance** (animations optimisées)
- **Maintenabilité** (code simple et élégant)

Les risques sont identifiés et mitigés, les tests sont planifiés, et les critères de succès sont clairs. Le plan préserve l'architecture narrative stricte (Global Story ≠ Step ≠ Cutscene) tout en améliorant significativement l'expérience utilisateur.

**Prochaine étape**: Validation de ce plan, puis implémentation étape par étape avec validation intermédiaire.

---

## 15. ANNEXE: COMPARAISON RAPIDE

| Critère | ExpansionTile | ExpansionPanelList | **Solution Custom** |
|---------|---------------|--------------------|---------------------|
| Compatibilité macOS | ❌ | ❌ | ✅ |
| Contrôle header | ⚠️ | ❌ | ✅ |
| Animation fluide | ✅ | ✅ | ✅ |
| Séparation interactions | ❌ | ❌ | ✅ |
| Performance | ✅ | ⚠️ | ✅ |
| Maintenabilité | ⚠️ | ❌ | ✅ |
| **Recommandé** | ❌ | ❌ | **✅** |

---

**Document créé**: 2026-04-04
**Statut**: En attente de validation
**Prochaine action**: Implémentation après validation du plan