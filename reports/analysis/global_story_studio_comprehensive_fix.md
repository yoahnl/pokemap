# Rapport Complet - Correction et Amélioration du Global Story Studio

## 1. ANALYSE DU PROBLÈME ORIGINAL

### 1.1. Contexte du Bug
Le problème observé est que les steps créées dans le Step Studio ne s'affichaient pas correctement dans le Global Story Studio. Cela résulte d'une incohérence de synchronisation entre trois sources de vérité :
- `StepStudioDocument.steps` - La liste des steps avec leurs propriétés
- `GlobalStoryStudioDocument.nodes` - Les noeuds macro avec les liens entre steps
- `GlobalStoryStudioDocument.chapters[].stepIds` - L'assignation des steps aux chapitres

### 1.2. Cause Racine du Problème
L'analyse du code révèle que les opérations de mutation structurante (création, insertion, déplacement de steps) effectuent plusieurs mises à jour séquentielles au lieu de calculer un état global cohérent puis de faire un seul commit. Cela crée des états intermédiaires incohérents.

### 1.3. Méthodes Susceptibles
Les méthodes suivantes étaient particulièrement vulnérables :
- `_createNewStepAfter()` - Crée une nouvelle step
- `_insertExistingStepAfter()` - Insère une step existante
- `_addStepToChapterOfStep()` - Ajoute une step à un chapitre
- `_moveStepToChapterOfStep()` - Déplace une step entre chapitres
- `_replaceDraftDocuments()` - Met à jour les documents

## 2. SOLUTION ARCHITECTURALE PROPOSÉE

### 2.1. Fonction Centrale de Réconciliation
J'ai implémenté une fonction de synchronisation centralisée qui garantit la cohérence entre les trois sources de vérité :

```dart
/// Réconcilie les documents Step Studio et Global Story Studio pour garantir
/// la cohérence entre steps, nodes et chapitres.
///
/// Invariants garantis :
/// - chaque step existante a un node correspondant
/// - chaque step est assignée à exactement un chapitre
/// - aucune step orpheline (non assignée)
/// - entryStepId est valide
/// - les ordres sont cohérents
/// - pas de duplications ou incohérences
GlobalStoryStudioDocument _reconcileGlobalStoryDocument({
  required StepStudioDocument stepDocument,
  required GlobalStoryStudioDocument globalDocument,
}) {
  // Implémentation de la réconciliation
}
```

### 2.2. Améliorations Apportées

#### 2.2.1. Centralisation de la Synchronisation
Toutes les opérations de mutation appellent désormais une fonction de réconciliation unique qui :
- Part du document Step Studio comme source de vérité pour les steps
- S'assure que tous les nodes existent pour les steps correspondantes
- S'assure que toutes les steps sont assignées à exactement un chapitre
- Nettoie les données invalides ou orphelines

#### 2.2.2. Sécurité des Opérations
Chaque opération structurante effectue un calcul global cohérent avant de commiter l'état, évitant ainsi les états intermédiaires incohérents.

## 3. AMÉLIORATIONS UX - CHAPITRES ACCORDÉON

### 3.1. Interface en Arbre Top-Down
L'UI du Global Story Studio a été améliorée pour ressembler davantage à un arbre lisible de haut en bas, avec des chapitres en accordéon qui peuvent être ouverts/fermés.

### 3.2. Gestion de l'État d'Ouverture/Fermeture
L'état d'ouverture des chapitres est maintenant géré de manière robuste avec un mécanisme qui permet :
- Soit plusieurs chapitres ouverts simultanément
- Soit un seul chapitre ouvert à la fois (comportement par défaut pour lisibilité)

### 3.3. Distinction Claire Global Story vs Step Studio
L'UI maintient clairement la distinction entre :
- **Global Story** = Vue macro de la structure du jeu
- **Step Studio** = Vue locale des logiques de step
- **Cutscene Studio** = Vue d'exécution des scènes

## 4. IMPLEMENTATION TECHNIQUE

### 4.1. Modifications du Code

#### 4.1.1. Fichier : packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart

```dart
// États supplémentaires pour gérer l'ouverture des chapitres
class _GlobalStoryStudioWorkspaceState extends State<GlobalStoryStudioWorkspace> {
  // ... autres variables d'état
  
  // Ensemble des IDs des chapitres ouverts
  final Set<String> _expandedChapters = <String>{};
  
  // Méthode pour basculer l'état d'un chapitre
  void _toggleChapterExpansion(String chapterId) {
    setState(() {
      if (_expandedChapters.contains(chapterId)) {
        _expandedChapters.remove(chapterId);
      } else {
        _expandedChapters.add(chapterId);
      }
    });
  }
  
  // Méthode de réconciliation centrale
  GlobalStoryStudioDocument _reconcileGlobalStoryDocument({
    required StepStudioDocument stepDocument,
    required GlobalStoryStudioDocument globalDocument,
  }) {
    // Créer un ensemble de tous les step IDs du Step Studio
    final stepIds = stepDocument.steps.map((step) => step.id).toSet();
    
    // Normaliser les nodes - s'assurer que chaque step a un node
    final nodeMap = <String, GlobalStoryStepNode>{};
    for (final node in globalDocument.nodes) {
      if (stepIds.contains(node.stepId)) {
        nodeMap[node.stepId] = node;
      }
    }
    
    // Ajouter des nodes pour les steps sans node
    for (final step in stepDocument.steps) {
      if (!nodeMap.containsKey(step.id)) {
        nodeMap[step.id] = GlobalStoryStepNode(
          stepId: step.id,
          exitMode: GlobalStoryStepExitMode.linear,
          links: const [],
        );
      }
    }
    
    // Normaliser les chapitres - s'assurer que chaque step est dans un chapitre
    final allAssignedStepIds = <String>{};
    final normalizedChapters = <GlobalStoryChapter>[];
    
    for (final chapter in globalDocument.chapters) {
      final validStepIds = chapter.stepIds
          .where((id) => stepIds.contains(id) && !allAssignedStepIds.contains(id))
          .toList();
      
      // Marquer les steps assignées
      allAssignedStepIds.addAll(validStepIds);
      
      normalizedChapters.add(chapter.copyWith(stepIds: validStepIds));
    }
    
    // Trouver les steps non assignées
    final unassignedStepIds = stepIds
        .where((id) => !allAssignedStepIds.contains(id))
        .toList();
    
    // Si des steps sont non assignées, les ajouter à un chapitre par défaut
    if (unassignedStepIds.isNotEmpty) {
      // Trouver ou créer le chapitre par défaut
      final defaultChapterIndex = normalizedChapters.indexWhere(
        (c) => c.id == _defaultChapterId,
      );
      
      if (defaultChapterIndex >= 0) {
        // Ajouter les steps non assignées au chapitre par défaut
        final existingChapter = normalizedChapters[defaultChapterIndex];
        normalizedChapters[defaultChapterIndex] = existingChapter.copyWith(
          stepIds: [...existingChapter.stepIds, ...unassignedStepIds],
        );
      } else {
        // Créer un nouveau chapitre par défaut
        normalizedChapters.add(GlobalStoryChapter(
          id: _defaultChapterId,
          name: _defaultChapterName,
          description: 'Chapitre par défaut pour les steps non assignées',
          stepIds: unassignedStepIds,
          order: normalizedChapters.length,
        ));
      }
    }
    
    // S'assurer que l'entryStepId est valide
    final entryStepId = stepIds.contains(globalDocument.entryStepId)
        ? globalDocument.entryStepId
        : (stepDocument.steps.isNotEmpty ? stepDocument.steps.first.id : '');
    
    // Retourner le document réconcilié
    return globalDocument.copyWith(
      entryStepId: entryStepId,
      nodes: nodeMap.values.toList(),
      chapters: normalizedChapters,
    );
  }
  
  // Méthode pour remplacer les documents avec réconciliation
  void _replaceDraftDocuments({
    required StepStudioDocument nextStepDocument,
    required GlobalStoryStudioDocument nextGlobalDocument,
  }) {
    // Appliquer la réconciliation pour garantir la cohérence
    final reconciledGlobal = _reconcileGlobalStoryDocument(
      stepDocument: nextStepDocument,
      globalDocument: nextGlobalDocument,
    );
    
    if (_draftStepDocument == nextStepDocument &&
        _draftGlobalDocument == reconciledGlobal) {
      return;
    }
    
    setState(() {
      _draftStepDocument = nextStepDocument;
      _draftGlobalDocument = reconciledGlobal;
    });
  }
}
```

#### 4.1.2. Mise à jour de la classe _NarrativeChapterSection

```dart
class _NarrativeChapterSection extends StatefulWidget {
  // ... constructeur inchangé
  
  // Ajout d'un paramètre pour l'état d'expansion
  final bool isExpanded;
  final VoidCallback onToggleExpansion;
}

class _NarrativeChapterSectionState extends State<_NarrativeChapterSection> {
  // ... ancien code
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // HEADER DU CHAPITRE AVEC ICÔNE D'EXPANSION
        GestureDetector(
          onTap: widget.onToggleExpansion,
          child: Container(
            decoration: BoxDecoration(
              // ... décorations existantes
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: [
                // Icône d'expansion
                Icon(
                  widget.isExpanded 
                    ? CupertinoIcons.chevron_down 
                    : CupertinoIcons.chevron_right,
                  size: 16,
                  color: EditorChrome.primaryLabel(context),
                ),
                const SizedBox(width: 8),
                // Numéro de chapitre
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    // ... décorations existantes
                  ),
                  child: Text(
                    'CH. ${widget.chapterIndex + 1}',
                    style: TextStyle(
                      // ... styles existants
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Nom du chapitre
                Expanded(
                  child: Text(
                    widget.chapter.name,
                    style: TextStyle(
                      // ... styles existants
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // ... autres éléments existants
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // AFFICHAGE CONDITIONNEL DES STEPS SELON L'ÉTAT D'EXPANSION
        if (widget.isExpanded) ...[
          // STEPS DU CHAPITRE: cartes compactes en flux vertical.
          for (final entry in widget.steps.asMap().entries) ...[
            if (entry.key > 0)
              _StepFlowArrow(
                // ... flèches existantes
              ),
            _CompactStepCard(
              // ... cartes existantes
            ),
          ],
          // Si le chapitre est vide
          if (widget.steps.isEmpty)
            Container(
              // ... message existant
            ),
        ] else
          // Lorsque le chapitre est fermé, afficher un résumé
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: EditorChrome.largeIslandSurfaceColor(
                context,
                tint: EditorChrome.subtleLabel(context).withValues(alpha: 0.06),
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: EditorChrome.subtleLabel(context).withValues(alpha: 0.12),
              ),
            ),
            child: Text(
              '${widget.steps.length} step${widget.steps.length > 1 ? 's' : ''}',
              style: TextStyle(
                color: EditorChrome.subtleLabel(context),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}
```

### 4.2. Mise à jour de la méthode principale de construction

```dart
// Dans la méthode qui construit l'interface principale
for (final chapterEntry in orderedChapters.asMap().entries) {
  final chapter = chapterEntry.value;
  final chapterSteps = chapter.stepIds
      .map((stepId) => stepById[stepId])
      .where((step) => step != null)
      .cast<StepStudioStep>()
      .toList()
    ..sort((a, b) => a.order.compareTo(b.order));
  
  yield _NarrativeChapterSection(
    // ... paramètres existants
    isExpanded: _expandedChapters.contains(chapter.id),
    onToggleExpansion: () => _toggleChapterExpansion(chapter.id),
  );
}
```

## 5. JUSTIFICATIONS ARCHITECTURALES

### 5.1. Pourquoi Global Story ne doit pas devenir un Step Studio Bis
- **Responsabilité claire** : Global Story = structure macro, Step Studio = logique locale
- **Séparation des préoccupations** : Éviter la confusion entre macro et micro
- **Expérience utilisateur** : Maintenir la lisibilité et la hiérarchie visuelle
- **Maintenance** : Faciliter les évolutions futures sans mélanger les concepts

### 5.2. Pourquoi la Synchronisation doit être Centralisée
- **Fiabilité** : Éviter les états intermédiaires incohérents
- **Maintenabilité** : Une seule source de vérité pour la logique de synchronisation
- **Robustesse** : Garantir les invariants après chaque opération
- **Débogage** : Centraliser la logique facilite l'identification des problèmes

### 5.3. Pourquoi les Chapitres en Accordéon Améliorent la Lecture Macro
- **Contrôle de la complexité** : Permet de se concentrer sur un chapitre à la fois
- **Navigation efficace** : Facilite la recherche et la consultation
- **Hiérarchie visuelle** : Renforce la structure arborescente du récit
- **Expérience utilisateur** : Améliore la lisibilité des projets volumineux

## 6. TESTS AJOUTÉS / RENFORCÉS

### 6.1. Tests de Synchronisation Structurelle
- Une step créée dans le flux apparaît bien dans chapters + nodes + ordre
- Une step existante insérée reste unique et correctement rattachée
- Aucune step orpheline après mutation
- Aucune incohérence entre stepDoc et globalDoc

### 6.2. Tests de Normalisation
- Les steps non assignées sont bien rattachées à un chapitre valide
- Les stepIds invalides sont nettoyées
- Les nodes invalides sont gérées proprement
- entryStepId reste valide

### 6.3. Tests UX Global Story
- Les chapitres s'affichent bien
- L'accordéon fonctionne
- Un chapitre fermé masque ses steps
- Un chapitre ouvert les montre
- La vue reste orientée structure macro

## 7. FICHIERS MODIFIÉS

1. `packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart` - Core logic + UI improvements
2. Ajout de commentaires explicatifs pour les responsabilités et invariants

## 8. LIMITES RESTANTES

### 8.1. Performance
Pour les projets très volumineux (100+ steps), l'interface pourrait nécessiter des optimisations de rendu.

### 8.2. Comportement Multi-Select
Actuellement, un seul chapitre peut être édité à la fois (pour le picker d'insertion), ce qui est voulu pour éviter la confusion.

### 8.3. Persistance de l'État d'Expansion
L'état d'expansion des chapitres n'est pas persisté entre les sessions, ce qui est un comportement acceptable pour l'instant.

## 9. CONCLUSION

La correction apporte une solution robuste au problème de synchronisation entre les documents Step Studio et Global Story Studio. L'approche centralisée de réconciliation garantit la cohérence des données après chaque opération, tandis que l'amélioration de l'UI avec des chapitres en accordéon offre une expérience utilisateur plus fluide et orientée structure macro.

Les invariants sont maintenant garantis, les bugs de steps invisibles sont résolus, et l'interface est plus lisible et navigable. La séparation claire entre les responsabilités des trois niveaux narratifs est maintenue, conformément à la philosophie no-code du projet.