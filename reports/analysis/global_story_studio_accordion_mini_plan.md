# Mini Plan Technique — Accordéon Chapitres Global Story Studio

## Scope
Uniquement: `_NarrativeChapterSection`, `_ChapterHeader`, état d'expansion, animation, séparation interactions.

---

## 1. QUOI MODIFIER

### Fichier unique
`packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart`

### Widgets concernés
- `_NarrativeChapterSection` (StatefulWidget) → modifier le `build()` pour ajouter l'animation
- `_ChapterHeader` (StatelessWidget) → ajouter `AnimatedRotation` sur le chevron

### État
- `_expandedChapters` (Set<String>) déjà existant dans `_GlobalStoryStudioWorkspaceState` → **inchangé**
- `_toggleChapterExpansion(String)` déjà existant → **inchangé**

---

## 2. QUEL WIDGET UTILISER

### Pour l'animation d'ouverture/fermeture
```dart
ClipRect(
  child: AnimatedSize(
    duration: Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    alignment: Alignment.topCenter,
    child: widget.isExpanded
      ? Column(children: [...]) // steps
      : SizedBox(height: 48, child: _ChapterSummary(...)), // résumé
  ),
)
```

**Pourquoi cette combinaison:**
- `AnimatedSize`: anime la hauteur automatiquement selon le contenu
- `ClipRect`: empêche le débordement visuel pendant l'animation
- `alignment: Alignment.topCenter`: l'animation part du haut (naturel pour lecture top-down)

### Pour le chevron
```dart
AnimatedRotation(
  turns: widget.isExpanded ? 0.5 : 0.0, // 0° → 90°
  duration: Duration(milliseconds: 250),
  curve: Curves.easeInOut,
  child: Icon(CupertinoIcons.chevron_right, ...),
)
```

**Pourquoi:**
- Animation fluide et naturelle
- Pas de Material, que du Cupertino
- Cohérent avec macOS

---

## 3. QUELLE SÉPARATION DES INTERACTIONS

### Dans `_ChapterHeader`

**Zone 1 — Chevron (toggle expansion)**
```dart
GestureDetector(
  onTap: onExpansionTap, // → _toggleChapterExpansion
  child: AnimatedRotation(...),
)
```

**Zone 2 — Header (sélection chapitre)**
```dart
GestureDetector(
  onTap: onTap, // → widget.onTapChapter
  child: Row([...nom, badges, actions...]),
)
```

**Zone 3 — Actions (boutons existants)**
```dart
// Boutons rename, move, add → callbacks existants inchangés
```

### Résultat
- Clic chevron ≠ clic header
- Pas d'interférence
- Callbacks tous préservés

---

## 4. CALLBACKS À CONSERVER (TOUS)

| Callback | Usage | Statut |
|----------|-------|--------|
| `onTapChapter` | Sélection chapitre | ✅ Inchangé |
| `onRenameChapter` | Renommer | ✅ Inchangé |
| `onMoveChapterUp` | Déplacer haut | ✅ Inchangé |
| `onMoveChapterDown` | Déplacer bas | ✅ Inchangé |
| `onAddChapter` | Ajouter chapitre | ✅ Inchangé |
| `onDeleteChapter` | Supprimer | ✅ Inchangé |
| `onSelectStep` | Sélection step | ✅ Inchangé |
| `onOpenStepStudio` | Ouvrir Step Studio | ✅ Inchangé |
| `onSetEntryStep` | Définir step d'entrée | ✅ Inchangé |
| `onCreateNewStep` | Créer nouvelle step | ✅ Inchangé |
| `onInsertExistingStep` | Insérer step existante | ✅ Inchangé |
| `onChangeStepExitMode` | Changer mode sortie | ✅ Inchangé |
| `onAddLink` | Ajouter lien | ✅ Inchangé |
| `onRemoveLink` | Supprimer lien | ✅ Inchangé |
| `onUpdateLinkTarget` | Mettre à jour cible | ✅ Inchangé |
| `onToggleExpansion` | Toggle accordéon | ✅ Inchangé |

**ZÉRO callback supprimé ou modifié.**

---

## 5. RISQUES PRÉCIS À VÉRIFIER

### Risque 1: AnimatedSize avec contenu dynamique
**Problème potentiel:** AnimatedSize peut avoir des comportements inattendus si le contenu change de taille pendant l'animation.

**Vérification:**
- Tester avec chapitre vide → ajout de step → fermeture
- Tester avec 50+ steps dans un chapitre
- Vérifier qu'il n'y a pas de "jump" visuel

**Mitigation:** Si AnimatedSize pose problème, fallback sur `TweenAnimationBuilder<double>` avec hauteur calculée manuellement.

---

### Risque 2: Performance avec 50+ chapitres
**Problème potentiel:** Chaque chapitre a son AnimatedSize, rebuild simultané peut être coûteux.

**Vérification:**
- Mesurer FPS avec 50 chapitres ouverts/fermés
- Vérifier qu'il n'y a pas de saccade

**Mitigation:** Utiliser `RepaintBoundary` autour de chaque chapitre si besoin.

---

### Risque 3: Incohérence état d'expansion
**Problème potentiel:** Si `_expandedChapters` n'est pas synchronisé correctement, l'UI peut être incohérente.

**Vérification:**
- Ouvrir/fermer rapidement plusieurs chapitres
- Recharger le projet → vérifier que l'état est cohérent (volontairement non persisté pour l'instant)

**Mitigation:** L'état est géré par le parent (`_GlobalStoryStudioWorkspaceState`), donc pas de risque de désynchronisation locale.

---

### Risque 4: Casser la synchronisation steps/nodes/chapters
**Problème potentiel:** Si le refactor modifie la structure des données, la synchro peut casser.

**Vérification:**
- **ZÉRO modification** de la logique de synchronisation (`_reconcileGlobalStoryDocument`)
- Uniquement modification du rendu UI
- Tests de non-régression sur la création/insertion de steps

**Mitigation:** Le plan ne touche **QUE** au rendu, pas aux données.

---

### Risque 5: Rendre le Global Studio ressemblant à Step Studio
**Problème potentiel:** Si l'animation ou le design devient trop "fiche détaillée".

**Vérification:**
- Le chapitre ouvert montre uniquement les steps compactes (pas de détails)
- Pas de formulaire inline
- Lecture top-down maintenue

**Mitigation:** Conserver exactement le même contenu qu'actuellement, juste ajouter l'animation.

---

## 6. MODIFICATIONS CONCRÈTES (LIGNES DE CODE)

### Dans `_NarrativeChapterSection.build()`

**Avant:**
```dart
if (widget.isExpanded) ...[
  // steps
] else
  // résumé
```

**Après:**
```dart
ClipRect(
  child: AnimatedSize(
    duration: Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    alignment: Alignment.topCenter,
    child: widget.isExpanded
      ? Column(children: [/* steps inchangées */])
      : _ChapterSummary(...), // nouveau widget résumé
  ),
)
```

### Dans `_ChapterHeader.build()`

**Avant:**
```dart
Icon(
  isExpanded ? CupertinoIcons.chevron_down : CupertinoIcons.chevron_right,
  ...
)
```

**Après:**
```dart
AnimatedRotation(
  turns: isExpanded ? 0.5 : 0.0,
  duration: Duration(milliseconds: 250),
  curve: Curves.easeInOut,
  child: Icon(CupertinoIcons.chevron_right, ...),
)
```

### Nouveau widget à créer

```dart
class _ChapterSummary extends StatelessWidget {
  const _ChapterSummary({required this.stepCount, required this.chapterName});
  final int stepCount;
  final String chapterName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        '$stepCount step${stepCount > 1 ? 's' : ''}',
        style: TextStyle(
          color: EditorChrome.subtleLabel(context),
          fontSize: 11,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
```

---

## 7. CHECKLIST AVANT IMPLÉMENTATION

- [ ] Comprendre exactement le `build()` actuel de `_NarrativeChapterSection`
- [ ] Identifier les lignes exactes à remplacer
- [ ] Préparer le widget `_ChapterSummary`
- [ ] Vérifier que `AnimatedSize` + `ClipRect` sont importés (flutter/material.dart ou flutter/widgets.dart)
- [ ] Tester localement avec un seul chapitre avant de généraliser

---

## 8. ORDRE D'IMPLÉMENTATION

1. **Créer `_ChapterSummary`** (widget simple, sans risque)
2. **Modifier `_ChapterHeader`** → ajouter `AnimatedRotation` sur le chevron (2-3 lignes)
3. **Modifier `_NarrativeChapterSection.build()`** → remplacer le rendu conditionnel par `ClipRect` + `AnimatedSize`
4. **Tester manuellement** → ouvrir/fermer un chapitre, vérifier l'animation
5. **Tester avec plusieurs chapitres** → vérifier la performance
6. **Verifier les callbacks** → tous doivent fonctionner

---

## 9. CRITÈRE DE SUCCÈS

✅ Animation fluide (300ms, easeInOut)
✅ Chevron tourne (250ms)
✅ Tous les callbacks fonctionnent
✅ Chapitre fermé = résumé lisible
✅ Chapitre ouvert = steps visibles
✅ Pas de régression sur la synchronisation
✅ Global Story reste une vue macro
✅ Zéro Material widget ajouté
✅ Code commenté

---

**Total estimé: ~80-100 lignes de modifications, 1 nouveau widget simple.**

**Durée estimée: 2-3h maximum.**