# Plan Corrigé — Accordéon Chapitres (Structure Stable)

## Structure Visuelle

```
╔══════════════════════════════════════════╗
║  [▼] CH. 1 — Prologue      [3 steps]   ║  ← HEADER FIXE
║  3 steps • Chapitre narratif             ║  ← RÉSUMÉ STABLE (toujours visible)
╠══════════════════════════════════════════╣
║  ┌────────────────────────────────────┐  ║
║  │ Step 1 : Arrivée au village        │  ║
║  │ Step 2 : Rencontre professeur      │  ║  ← ZONE ANIMÉE
║  │ Step 3 : Choix du starter          │  ║    (s'ouvre/ferme)
║  └────────────────────────────────────┘  ║
╚══════════════════════════════════════════╝
```

## Modifications (2 fichiers, 1 widget)

### Fichier unique
`packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart`

### Structure corrigée de `_NarrativeChapterSection.build()`

```dart
Column(
  children: [
    // 1. HEADER FIXE
    _ChapterHeader(
      chapter: widget.chapter,
      isExpanded: widget.isExpanded,
      onExpansionTap: widget.onToggleExpansion,
      // ... tous les callbacks existants
    ),
    
    // 2. RÉSUMÉ STABLE (toujours visible)
    _ChapterSummary(
      stepCount: widget.steps.length,
      chapter: widget.chapter,
      isExpanded: widget.isExpanded, // pour opacité réduite si ouvert
    ),
    
    // 3. ZONE DES STEPS ANIMÉE
    ClipRect(
      child: AnimatedSize(
        duration: 300ms,
        curve: easeInOut,
        alignment: Alignment.topCenter,
        child: widget.isExpanded
          ? Column(children: [/* steps */])
          : SizedBox.shrink(), // zone repliée
      ),
    ),
  ],
)
```

## Comportement

| État | Header | Résumé | Steps |
|------|--------|--------|-------|
| Fermé | Visible | Visible (pleine opacité) | Repliée (hauteur 0) |
| Ouvert | Visible | Visible (opacité réduite) | Dépliée (animation fluide) |

## Widgets à créer/modifier

### 1. `_ChapterSummary` (nouveau, simple)
- Affiche le nombre de steps + infos clés
- Toujours visible
- Opacité réduite quand chapitre ouvert (subtil)

### 2. `_ChapterHeader` (modification mineure)
- Ajouter `AnimatedRotation` sur le chevron
- Sinon inchangé

### 3. `_NarrativeChapterSection` (modification du build)
- Séparer en 3 zones distinctes (header, résumé, steps)
- Zone steps dans `ClipRect` + `AnimatedSize`
- Callbacks tous inchangés

## Invariants

✅ Header toujours cliquable (toggle + sélection)
✅ Résumé toujours lisible
✅ Steps apparaissent/disparaissent avec animation
✅ Pas de swap brutal de widgets
✅ Tous les callbacks fonctionnent
✅ Synchronisation intacte

## Risques

| Risque | Mitigation |
|--------|-----------|
| AnimatedSize avec SizedBox.shrink | Tester, fallback sur `SizeBox(height: 0)` si besoin |
| Résumé prend trop de place ouvert | Réduire opacité/padding quand isExpanded |
| Performance 50+ chapitres | `RepaintBoundary` si nécessaire |

## Ordre d'implémentation

1. Créer `_ChapterSummary` (widget simple)
2. Modifier `_ChapterHeader` → `AnimatedRotation` sur chevron
3. Modifier `_NarrativeChapterSection.build()` → 3 zones distinctes
4. Tester manuellement
5. Vérifier tous les callbacks

---

**Total: ~100 lignes. 2-3h. Zéro modification métier.**

**Validé pour implémentation.**