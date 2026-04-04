# Diagnostic et Plan d'Action — Global Story Studio Corrections

## 1. DIAGNOSTIC TECHNIQUE

### A. Bug "Insérer" — Cause Racine Identifiée

**Fichier**: `global_story_studio_workspace.dart`, ligne 3064-3072

**Code actuel**:
```dart
List<_SimpleOption> _availableStepsFor(String currentStepId) {
  final stepIds = widget.steps.map((s) => s.id).toList();
  return widget.steps
      .where((s) => s.id != currentStepId)
      .map((s) => _SimpleOption(...))
      .toList(growable: false);
}
```

**Problème**: La méthode utilise `widget.steps` qui contient **uniquement les steps du chapitre courant**, pas toutes les steps du projet.

**Conséquence**: 
- Si un chapitre n'a que 1-2 steps → la liste est quasi vide
- L'utilisateur voit "Aucune step disponible" alors qu'il y a des dizaines de steps dans d'autres chapitres
- Le comportement est techniquement correct (filtre par chapitre) mais fonctionalement absurde

**Correction nécessaire**: Utiliser `widget.globalDocument` et/ou `widget.stepDocument` pour accéder à **toutes les steps du projet**, pas seulement celles du chapitre.

---

### B. Accordéon — Gestion Actuelle du Clic

**Fichier**: `global_story_studio_workspace.dart`, ligne 3260-3340

**Architecture actuelle**:
```dart
_ChapterHeader(
  onTap: () => widget.onTapChapter(widget.chapter.id),  // ← Sélection du chapitre
  onExpansionTap: widget.onToggleExpansion,              // ← Toggle expansion (chevron uniquement)
)
```

**Structure interne du `_ChapterHeader`**:
- `GestureDetector` englobant tout le header → `onTap` (sélection chapitre)
- `GestureDetector` sur le chevron uniquement → `onExpansionTap` (toggle expansion)

**Problème**: 
- Le header principal est relié à `onTapChapter` (sélection du chapitre)
- Seule la zone du chevron (40x40px environ) déclenche l'expansion
- L'utilisateur doit viser une petite zone pour ouvrir/fermer
- UX contraire aux standards des accordéons modernes

**Correction nécessaire**: 
- Remplacer `onTap` du header par `_toggleChapterExpansion`
- Conserver `onExpansionTap` sur le chevron (redondant mais cohérent)
- Ajouter un `onTap` séparé pour la sélection si nécessaire (double-clic ou bouton dédié)

---

### C. Renommage des Chapitres — État Actuel

**Callback existant**: `onRenameChapter` est déjà défini et transmis au `_ChapterHeader`.

**Problème**: Aucune UI n'expose ce callback à l'utilisateur. Le renommage est techniquement possible mais inaccessible.

**Correction nécessaire**: Ajouter un moyen intuitif de déclencher le renommage.

---

## 2. DIAGNOSTIC UX

### Ce qui marche déjà
✅ Structure 3 zones (header fixe, résumé stable, steps animées)
✅ Animation fluide de l'accordéon (300ms)
✅ Chevron animé (250ms)
✅ Séparation claire Global Story vs Step Studio
✅ Lecture top-down naturelle
✅ Cohérence visuelle avec macos_ui

### Ce qui reste bancal
❌ **Zone cliquable de l'accordéon trop petite** — seul le chevron est fonctionnel
❌ **Bug "Insérer"** — liste vide car filtrée par chapitre au lieu de projet entier
❌ **Renommage inaccessible** — callback existe mais aucune UI pour le déclencher
❌ **Hiérarchie visuelle** — le header pourrait être plus distinctif

### Ce qui doit être amélioré
- Rendre tout le header cliquable pour l'accordéon
- Corriger la source de données du picker d'insertion
- Ajouter une UI de renommage intuitive
- Renforcer la hiérarchie visuelle header/résumé/steps

---

## 3. PLAN D'ACTION

### ÉTAPE 1: Correction du Bug "Insérer" (Priorité Haute)

**Fichier concerné**: `global_story_studio_workspace.dart`

**Modification**: `_NarrativeChapterSectionState._availableStepsFor()`

**Avant**:
```dart
List<_SimpleOption> _availableStepsFor(String currentStepId) {
  return widget.steps  // ← Steps du chapitre uniquement
      .where((s) => s.id != currentStepId)
      .map(...)
      .toList();
}
```

**Après**:
```dart
List<_SimpleOption> _availableStepsFor(String currentStepId) {
  // Récupérer TOUTES les steps du StepStudioDocument via le parent
  // Exclure uniquement la step courante
  // Retourner la liste complète
}
```

**Problème à résoudre**: `_NarrativeChapterSection` n'a pas accès directement au `StepStudioDocument`. Il faut soit:
- **Option A**: Ajouter un paramètre `allSteps` au widget
- **Option B**: Accéder via `widget.globalDocument` + reconstruction

**Recommandation**: **Option A** — ajouter `List<StepStudioStep> allProjectSteps` comme paramètre du widget. Plus clair, plus maintenable.

**Impact**: 
- Modifier `_NarrativeChapterSection` constructor
- Modifier l'appelant dans `_buildNarrativeTree()` pour passer `stepDocument.steps`
- Tester que la liste affiche bien toutes les steps

**Risque**: Faible — modification purement UI, pas de logique métier

---

### ÉTAPE 2: Rendre le Header Entièrement Cliquable pour l'Accordéon

**Fichier concerné**: `global_story_studio_workspace.dart`

**Modifications**:

#### 2.1. Dans `_ChapterHeader.build()`

**Avant**:
```dart
GestureDetector(
  onTap: onTap,  // ← Sélection du chapitre
  child: Container(...),
)
```

**Après**:
```dart
GestureDetector(
  onTap: onExpansionTap,  // ← Toggle expansion (tout le header)
  child: Container(...),
)
```

#### 2.2. Supprimer le GestureDetector dupliqué sur le chevron

Le chevron n'a plus besoin de son propre `GestureDetector` car tout le header est cliquable.

**Avant**:
```dart
if (showExpansionIcon) ...[
  GestureDetector(
    onTap: onExpansionTap,
    child: AnimatedRotation(...),
  ),
]
```

**Après**:
```dart
if (showExpansionIcon) ...[
  AnimatedRotation(...),  // ← Plus de GestureDetector, juste l'icône
]
```

**Impact**: 
- UX beaucoup plus naturelle (comme un vrai accordéon)
- Pas de conflit d'interaction
- Le chevron reste visible comme indicateur visuel

**Risque**: Très faible — simplification du code

---

### ÉTAPE 3: Ajouter le Renommage des Chapitres

**Option Recommandée**: Double-clic sur le nom du chapitre → édition inline

**Justification**:
- Standard UX moderne (Finder macOS, VS Code, etc.)
- Pas de bouton supplémentaire à ajouter
- Intuitif pour les utilisateurs macOS
- Cohérent avec macos_ui

**Implémentation**:

#### 3.1. Ajouter un état d'édition dans `_ChapterHeader`

Transformer `_ChapterHeader` de `StatelessWidget` à `StatefulWidget`:

```dart
class _ChapterHeader extends StatefulWidget {
  // ... paramètres existants
}

class _ChapterHeaderState extends State<_ChapterHeader> {
  bool _isEditing = false;
  final TextEditingController _controller = TextEditingController();
  
  void _startEditing() {
    setState(() => _isEditing = true);
    _controller.text = widget.chapter.name;
  }
  
  void _commitEdit() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onRename(_controller.text.trim());
    }
    setState(() => _isEditing = false);
  }
  
  void _cancelEdit() {
    setState(() => _isEditing = false);
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return _buildEditingMode();
    }
    return _buildDisplayMode();
  }
}
```

#### 3.2. Mode affichage (actuel)

```dart
Widget _buildDisplayMode() {
  return GestureDetector(
    onTap: widget.onTap,  // ← Sélection
    onDoubleTap: _startEditing,  // ← Renommage
    child: Container(...),
  );
}
```

#### 3.3. Mode édition

```dart
Widget _buildEditingMode() {
  return CupertinoTextField(
    controller: _controller,
    autofocus: true,
    onSubmitted: (_) => _commitEdit(),
    onKeyDown: (event) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _cancelEdit();
      }
    },
  );
}
```

**Impact**:
- UX intuitive (double-clic = éditer)
- Pas de bouton supplémentaire
- Cohérent avec macOS
- Nom persisté via `onRename` callback existant

**Risque**: Faible — état local au widget, pas d'impact sur les données

---

### ÉTAPE 4: Améliorations Visuelles Ciblées

#### 4.1. Renforcer la hiérarchie visuelle

**Header de chapitre**:
- Augmenter légèrement la taille du titre (15 → 16px)
- Ajouter un hover effect subtil pour indiquer la cliquabilité
- Bordure légèrement plus prononcée

**Résumé**:
- Réduire encore l'opacité quand chapitre ouvert (0.6 → 0.5)
- Padding vertical réduit pour plus de compacité

**Cards de steps**:
- Aucun changement (déjà propres)

#### 4.2. Améliorer le wording

**Chevron**: Pas de changement (icône universelle)

**Résumé quand fermé**: 
- Actuel: "3 steps"
- Après: "3 steps • Cliquez pour déplier" (plus guidé)

**Bouton "Insérer"**:
- Actuel: "Insérer"
- Après: "Insérer une step" (plus explicite)

---

## 4. ORDRE D'IMPLÉMENTATION

1. **Bug "Insérer"** — correction de la source de données (30min)
2. **Header cliquable** — modification du GestureDetector (15min)
3. **Renommage** — double-clic + édition inline (1h30)
4. **Finitions UX** — hover effects, wording, opacité (30min)

**Total estimé**: ~2h30

---

## 5. FICHIERS À MODIFIER

| Fichier | Modifications | Lignes |
|---------|---------------|--------|
| `global_story_studio_workspace.dart` | 4 modifications ciblées | ~150-200 |

**Aucun autre fichier touché.**

---

## 6. TESTS À AJOUTER

### Tests unitaires
```dart
test('Insert picker shows all project steps, not just chapter steps', ...)
test('Double-click on chapter name starts editing', ...)
test('Chapter rename persists to document', ...)
test('Escape key cancels editing', ...)
test('Full header click toggles expansion', ...)
```

### Tests manuels
- [ ] Ouvrir chapitre avec 1 step → cliquer "Insérer" → voir toutes les steps du projet
- [ ] Double-cliquer sur nom de chapitre → éditer → valider
- [ ] Cliquer sur header (pas chevron) → chapitre s'ouvre/ferme
- [ ] Hover sur header → effet visuel visible

---

## 7. RISQUES ET MITIGATIONS

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|------------|
| Régression synchronisation | Faible | Élevé | Zéro modification logique métier |
| Conflit double-clic / simple clic | Moyenne | Moyen | Tester les délais, ajuster si besoin |
| Perte de focus pendant édition | Faible | Faible | `autofocus: true` + gestion Escape |
| Performance avec 100+ steps dans picker | Moyenne | Faible | ListView avec lazy loading si besoin |

---

## 8. INVARIANTS À PRÉSERVER

✅ Tous les callbacks existants fonctionnent
✅ Synchronisation steps/nodes/chapters intacte
✅ Global Story reste une vue macro
✅ Pas de Material widget ajouté
✅ Cohérence macos_ui
✅ Animation accordéon fluide
✅ Structure 3 zones conservée

---

**Plan validé pour implémentation.**