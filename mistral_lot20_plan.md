# Mistral Plan - Lot PathPattern-20 : Legacy PathPattern Save Flow V0
*Date: 2025-05-01 | Type: Plan d'implémentation | Statut: À valider avant exécution*

---

## 🎯 Résumé Exécutif

Ce document décrit **ma stratégie d'implémentation** pour le Lot 20, **sans l'exécuter**. 
Il explique **ce que je ferais**, **pourquoi**, et **comment**, en répondant au prompt ChatGPT tout en adaptant l'approche à ma compréhension du codebase après analyse complète des Lots 0-18.

**Objectif du Lot 20:**
> Brancher la sauvegarde du flux **"Depuis un path existant"** dans `ProjectManifest.pathPatternPresets` en mémoire, en utilisant les opérations existantes, sans écrire sur disque.

**Périmètre strict:**
- ✅ **À implémenter:** Sauvegarde legacy PathPattern → manifest en mémoire
- ❌ **Exclu:** Sauvegarde "Nouveau chemin" (attend bords/coins/jonctions)
- ❌ **Exclu:** Toute modification de `map_core`, `ProjectManifest`, codecs, persistence disque

---

---

## 📋 Compréhension du Contexte

### État Actuel (après Lot 19)
D'après l'analyse des rapports Lots 0-18:

1. **Path Studio** a deux flux:
   - **Nouveau chemin**: `PathStudioNewPathDraft` (indépendant, pas de base legacy) → **Non sauvegardable** (bords/coins/jonctions manquants)
   - **Depuis un path existant**: `PathPatternDraft` (basé sur `ProjectPathPreset` legacy) → **Produit un `ProjectPathPatternPreset` valide**

2. **Lot 19 a préparé:**
   - Save plan local côté `map_editor`
   - `PathStudioPanel` expose `ValueChanged<ProjectPathPatternPreset>? onPathPatternPresetSaveRequested`
   - Callback reçoit le preset **sans muter le manifest**
   - "Nouveau chemin" reste **volontairement bloqué** (bouton Enregistrer disabled)

3. **Opérations manifest existantes (Lot 11):**
   ```dart
   // packages/map_core/lib/src/operations/project_manifest_path_pattern_preset_operations.dart
   ProjectManifest upsertProjectPathPatternPreset(ProjectManifest, ProjectPathPatternPreset)
   ```
   → **Accessible publiquement** via `map_core.dart` (export)

4. **Mécanisme de mise à jour manifest éditeur:**
   → **À auditer** (voir Section 3)

---

## 🔍 Audit Préliminaire (Basé sur Lots 0-18)

### Fichiers Clés à Inspecter

| Fichier | Rôle | Statut (d'après rapports) | Action Prévue |
|---------|------|--------------------------|---------------|
| `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart` | UI principale Path Studio | Existe, 3668+ lignes | **Modifier** (brancher callback) |
| `packages/map_editor/lib/src/features/path_studio/path_studio_save_plan.dart` | Plan de sauvegarde local | **Créé Lot 19?** | **À auditer** |
| `packages/map_editor/lib/src/features/path_studio/path_pattern_draft.dart` | Modèle draft legacy | Existe | **Lire** (comprendre structure) |
| `packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart` | Modèle draft indépendant | Existe | **Lire** (comprendre différences) |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` | State management éditeur | Existe | **Modifier** (ajouter méthode update) |
| `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart` | Sélecteurs Riverpod | Existe | **Lire** (comprendre accès manifest) |
| `packages/map_editor/lib/src/features/path_studio/path_studio_workspace.dart` | Workspace Path Studio | **Existe?** | **Modifier** (brancher callback) |

---

## 🎯 Stratégie d'Implémentation

### Étape 1: Audit Complet (Obligatoire)

**Commandes à exécuter avant toute modification:**
```bash
# 1. Vérifier structure Path Studio
ls -la packages/map_editor/lib/src/features/path_studio/

# 2. Vérifier state management
ls -la packages/map_editor/lib/src/features/editor/state/

# 3. Vérifier exports map_core
cat packages/map_core/lib/map_core.dart | grep -E "path_pattern|manifest"

# 4. Vérifier opérations manifest disponibles
cat packages/map_core/lib/src/operations/project_manifest_path_pattern_preset_operations.dart | head -50
```

**Questions à répondre par l'audit:**
1. Où est stocké le `ProjectManifest` courant dans l'éditeur?
2. Quelle méthode permet de le mettre à jour en mémoire?
3. `upsertProjectPathPatternPreset` est-il accessible depuis `map_editor`?
4. Existe-t-il un mécanisme `dirty state` existant?
5. Comment les autres features (tilesets, maps) mettent-elles à jour le manifest?

---

### Étape 2: Branchement du Callback

**Problème:** Le Lot 19 a préparé le callback, mais il n'est pas branché.

**Solution prévue:**

#### Fichier: `path_studio_workspace.dart` (ou équivalent)

**Action:** Brancher `onPathPatternPresetSaveRequested` depuis `PathStudioPanel`

```dart
// AVANT (hypothèse):
PathStudioPanel(
  // ...
  onPathPatternPresetSaveRequested: null, // ou non branché
)

// APRÈS:
PathStudioPanel(
  // ...
  onPathPatternPresetSaveRequested: (preset) {
    _handleSavePathPatternPreset(preset);
  },
)
```

**Justification:**
- Le callback est déjà exposé par `PathStudioPanel` (Lot 19)
- Le workspace est le niveau approprié pour gérer la logique de sauvegarde
- Respecte le principe de **séparation des responsabilités** (UI vs logique)

---

### Étape 3: Gestion de la Sauvegarde

**Problème:** Comment mettre à jour le manifest en mémoire?

**Solution prévue:**

#### Option A (Préférée): Utiliser notifier existant

Si l'éditeur a déjà un mécanisme pour mettre à jour le manifest:

```dart
// Dans path_studio_workspace.dart
void _handleSavePathPatternPreset(ProjectPathPatternPreset preset) {
  // 1. Lire manifest courant
  final currentManifest = ref.read(editorManifestProvider);
  
  // 2. Appliquer upsert via opération existante
  final updatedManifest = upsertProjectPathPatternPreset(
    currentManifest,
    preset,
  );
  
  // 3. Mettre à jour via notifier existant
  ref.read(editorManifestNotifierProvider.notifier).updateManifest(updatedManifest);
  
  // 4. Feedback UX
  _showSaveSuccessFeedback();
  
  // 5. Nettoyer draft
  _clearLegacyDraft();
}
```

#### Option B: Ajouter méthode au notifier

Si aucune méthode `updateManifest` n'existe:

```dart
// Dans editor_notifier.dart
void updateManifest(ProjectManifest newManifest) {
  state = state.copyWith(manifest: newManifest);
  // Mettre à jour dirty flag si mécanisme existe
  _markAsDirty();
}
```

**Préférence:** Option A si possible, sinon Option B (minimale)

---

### Étape 4: Mise à Jour de la Liste Path Studio

**Problème:** Après sauvegarde, la liste doit refléter le nouveau preset.

**Solution prévue:**
- Le `PathPatternEditorReadModel` est recalculé automatiquement via Riverpod quand le manifest change
- **Pas de code supplémentaire nécessaire** si le read model dépend déjà de `editorManifestProvider`
- Sinon, ajouter un `ref.read(editorManifestProvider)` dans le builder du read model

---

### Étape 5: Feedback UX

**Problème:** L'utilisateur doit voir que la sauvegarde a réussi.

**Solution prévue:**

1. **Message de succès:**
   - Snackbar ou toast: "Motif enregistré dans le projet"
   - Utiliser le système de feedback existant dans `map_editor`

2. **Nettoyage du draft:**
   - Vider le `PathPatternDraft` legacy après sauvegarde
   - Sélectionner automatiquement le nouveau preset dans la liste **si simple**
   - Sinon: juste vider le draft et rafraîchir la liste

3. **Nouveau chemin reste bloqué:**
   - **Aucune modification** du comportement existant
   - Bouton Enregistrer **resté disabled**
   - Message explicite: "Bords/coins/jonctions à définir pour sauvegarder"

---

### Étape 6: Gestion des Erreurs

**Problème:** Que faire si l'upsert échoue?

**Solution prévue:**

```dart
void _handleSavePathPatternPreset(ProjectPathPatternPreset preset) {
  try {
    final currentManifest = ref.read(editorManifestProvider);
    final updatedManifest = upsertProjectPathPatternPreset(currentManifest, preset);
    ref.read(editorManifestNotifierProvider.notifier).updateManifest(updatedManifest);
    _showSuccessFeedback();
    _clearLegacyDraft();
  } on ValidationException catch (e) {
    // Ex: duplicate id, champ invalide
    _showErrorFeedback('Erreur de validation: ${e.message}');
    // NE PAS vider le draft
  } catch (e) {
    _showErrorFeedback('Échec de la sauvegarde: ${e.toString()}');
    // NE PAS vider le draft
  }
}
```

**Cas couverts:**
- `ValidationException` (opérations manifest)
- Erreurs de concurrence (id duplicate non détecté)

**Cas NON couverts (hors scope):**
- Erreurs réseau (pas applicable, pas de persistence)
- Erreurs disque (pas applicable)

---

---

## 📁 Fichiers à Modifier/Créer

### Fichiers Modifiés

| Fichier | Type de Modification | Justification |
|---------|----------------------|---------------|
| `packages/map_editor/lib/src/features/path_studio/path_studio_workspace.dart` | Ajout callback handler | Brancher `onPathPatternPresetSaveRequested` |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` | Ajout méthode `updateManifest` | Mettre à jour manifest en mémoire **si nécessaire** |
| `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart` | Modification bouton Enregistrer | Activer/désactiver selon draft valide |

### Fichiers Créés

| Fichier | Contenu | Justification |
|---------|---------|---------------|
| `packages/map_editor/test/path_pattern/path_studio_workspace_save_flow_test.dart` | Tests d'intégration | Valider le flux complet de sauvegarde |
| `reports/pathPattern/pathpattern_20_legacy_pathpattern_save_flow_v0.md` | Rapport final | Obligatoire (Evidence Pack complet) |

### Fichiers Non Modifiés (Garanti)

| Fichier/Package | Raison |
|----------------|--------|
| `packages/map_core/...` | Contrainte du Lot: pas de modification map_core |
| `packages/map_core/lib/src/models/project_manifest.dart` | Déjà stable, pas de changement |
| `packages/map_core/lib/src/operations/project_manifest_path_pattern_preset_operations.dart` | Utilisé tel quel, pas de modification |
| `packages/map_gameplay/...` | Hors scope |
| `packages/map_battle/...` | Hors scope |
| `packages/map_runtime/...` | Hors scope (pas de rendu runtime dans ce lot) |

---

---

## 🧪 Stratégie de Tests

### Tests Unitaires

**Si nouvelle méthode ajoutée dans `editor_notifier.dart`:**

```dart
// packages/map_editor/test/editor_notifier_test.dart (ou nouveau fichier)
test('updateManifest avec PathPatternPreset', () {
  final notifier = EditorNotifier(initialManifest: testManifest);
  final newPreset = testPathPatternPreset;
  
  notifier.updateManifest(
    upsertProjectPathPatternPreset(testManifest, newPreset)
  );
  
  expect(notifier.state.manifest.pathPatternPresets, contains(newPreset));
  expect(notifier.state.manifest.otherFields, equals(testManifest.otherFields));
});
```

### Tests Widget (PathStudioPanel)

```dart
// packages/map_editor/test/path_pattern/path_studio_panel_test.dart
group('Lot 20 - Sauvegarde Legacy', () {
  testWidgets('bouton Enregistrer appelle callback avec preset valide', (tester) async {
    final receivedPreset = <ProjectPathPatternPreset>[];
    
    await tester.pumpWidget(
      ProviderScope(
        child: PathStudioPanel(
          onPathPatternPresetSaveRequested: (p) => receivedPreset.add(p),
          // ... autres params
        ),
      ),
    );
    
    // Simuler draft legacy valide
    // Cliquer sur Enregistrer
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    
    expect(receivedPreset, hasLength(1));
    expect(receivedPreset[0].id, isNotEmpty);
  });
  
  testWidgets('bouton Enregistrer disabled pour Nouveau chemin', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: PathStudioPanel(
          onPathPatternPresetSaveRequested: (_) => fail('ne doit pas être appelé'),
          // draft = Nouveau chemin
        ),
      ),
    );
    
    final button = find.text('Enregistrer');
    expect(tester.widget<Button>(button).enabled, isFalse);
  });
});
```

### Tests d'Intégration (Workspace)

```dart
// packages/map_editor/test/path_pattern/path_studio_workspace_save_flow_test.dart
group('Lot 20 - Flux complet', () {
  testWidgets('sauvegarde legacy met à jour manifest en mémoire', (tester) async {
    final initialManifest = ProjectManifest(pathPatternPresets: []);
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          editorManifestProvider.overrideWithValue(initialManifest),
        ],
        child: PathStudioWorkspace(),
      ),
    );
    
    // 1. Sélectionner "Depuis un path existant"
    // 2. Configurer le draft
    // 3. Cliquer sur Enregistrer
    
    // Vérifier que manifest a été mis à jour
    final updatedManifest = tester.state<EditorNotifierState>(find.byType(EditorNotifier)).manifest;
    expect(updatedManifest.pathPatternPresets, hasLength(1));
    
    // Vérifier que le preset a les bonnes propriétés
    final savedPreset = updatedManifest.pathPatternPresets.first;
    expect(savedPreset.id, 'expected-id');
    expect(savedPreset.name, 'expected-name');
    expect(savedPreset.basePathPresetId, 'legacy-path-id');
  });
  
  testWidgets('Nouveau chemin ne déclenche pas de mutation manifest', (tester) async {
    final initialManifest = ProjectManifest(pathPatternPresets: []);
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          editorManifestProvider.overrideWithValue(initialManifest),
        ],
        child: PathStudioWorkspace(),
      ),
    );
    
    // 1. Sélectionner "Nouveau chemin"
    // 2. Configurer le draft
    // 3. Tentative de clic sur Enregistrer (disabled)
    
    // Vérifier que manifest n'a PAS changé
    final finalManifest = tester.state<EditorNotifierState>(find.byType(EditorNotifier)).manifest;
    expect(finalManifest.pathPatternPresets, isEmpty);
  });
});
```

### Régressions

```bash
# map_editor
flutter test test/path_pattern/path_studio_panel_test.dart
flutter test test/path_pattern/path_studio_workspace_save_flow_test.dart
flutter test test/path_pattern/
flutter test test/editor_shell_page_smoke_test.dart
flutter test test/top_toolbar_test.dart
flutter test test/editor_selectors_test.dart

# map_core
dart test test/project_manifest_path_pattern_preset_operations_test.dart
dart test test/project_manifest_path_pattern_presets_test.dart
dart test test/project_path_pattern_preset_json_codec_test.dart
dart test test/project_path_pattern_preset_json_golden_test.dart
dart test test/project_path_pattern_preset_test.dart
```

### Analyse Statique

```bash
flutter analyze lib/src/features/path_studio test/path_pattern
```

---

---

## 📊 Checklist de Validation

- [ ] Audit initial complet réalisé
- [ ] `upsertProjectPathPatternPreset` accessible depuis `map_editor`
- [ ] Mécanisme de mise à jour manifest existant identifié
- [ ] Callback `onPathPatternPresetSaveRequested` branché dans workspace
- [ ] Mise à jour manifest en mémoire implémentée
- [ ] Feedback UX après sauvegarde implémenté
- [ ] Draft legacy nettoyé après sauvegarde
- [ ] Nouveau chemin reste NON sauvegardable (bouton disabled + message)
- [ ] Gestion d'erreurs basique implémentée
- [ ] Tests unitaires ajoutés si nécessaire
- [ ] Tests widget mis à jour
- [ ] Tests d'intégration créés
- [ ] Toutes régressions passent
- [ ] `flutter analyze` passe
- [ ] Aucun fichier `map_core` modifié
- [ ] Aucun fichier de persistence disque créé/modifié
- [ ] Rapport final complet avec Evidence Pack

---

---

## 🎨 Décisions de Conception

### Décision 1: Où mettre la logique de sauvegarde?

**Choix:** Dans `PathStudioWorkspace`

**Alternatives considérées:**
- Dans `PathStudioPanel`: ❌ Mélange UI et logique métier
- Dans un service dédié: ❌ Trop lourd pour ce lot (pas de repository/service)
- Dans le notifier: ✅ **Alternative valable** si le workspace n'a pas accès au state

**Justification:**
- Le workspace est le conteneur logique pour la coordination entre panels
- Respecte le pattern existant dans `map_editor`
- Minimal et ciblé

---

### Décision 2: Comment mettre à jour le manifest?

**Choix:** Utiliser `upsertProjectPathPatternPreset` existant + notifier

**Alternatives considérées:**
- Copier la logique dans `map_editor`: ❌ Duplication de code
- Modifier `map_core` pour exposer plus: ❌ Contrainte du lot

**Justification:**
- Les opérations manifest existent déjà (Lot 11)
- Accessibles depuis `map_editor` via import `map_core.dart`
- **0 modification de `map_core`** nécessaire

---

### Décision 3: Que faire du draft après sauvegarde?

**Choix:** Vider le draft + afficher feedback

**Alternatives considérées:**
- Sélectionner automatiquement le preset: ✅ **Option idéale** si simple
- Garder le draft: ❌ Risque de confusion (état incohérent)

**Justification:**
- Éviter la duplication (draft + preset sauvegardé)
- Feedback clair pour l'utilisateur
- Sélection auto reportable si trop complexe pour ce lot

---

### Décision 4: Gestion du dirty state

**Choix:** Utiliser mécanisme existant si présent, sinon documenter limite

**Justification:**
- Pas de création de système complexe dans ce lot
- Compatible avec l'approche incrémentale

---

---

## ⚠️ Limites Connues (À Documenter dans le Rapport Final)

1. **Pas de sauvegarde disque:**
   - Le manifest est mis à jour en mémoire seulement
   - La persistence disque est gérée par le flux existant `Save` de l'éditeur
   - **Justification:** Contrainte du Lot ("sans écrire sur disque")

2. **Pas de validation avancée:**
   - Validation basique via `upsertProjectPathPatternPreset`
   - Pas de vérification que `basePathPresetId` existe dans le manifest
   - **À améliorer:** Lot futur dédié aux diagnostics

3. **Pas de sélection automatique du preset:**
   - Si trop complexe, reporté à un lot futur
   - **Justification:** Minimiser la portée du Lot 20

4. **Nouveau chemin reste non fonctionnel:**
   - **Volontaire:** Attend l'implémentation des bords/coins/jonctions
   - **Risque:** None (comportement existant préservé)

5. **Pas de test complet `map_editor`:**
   - Seuls les tests PathPattern sont exécutés
   - **Justification:** Portée du lot limitée

---

---

## 📝 Critique du Prompt ChatGPT

### Points Forts ✅

1. **Très structuré:** 12 sections claires, checklist exhaustive
2. **Contexte complet:** Rappel du Lot 19 et de l'état actuel
3. **Contraintes explicites:** Liste claire des non-objectifs
4. **Evidence Pack obligatoire:** Définition précise des preuves requises
5. **Approche incrémentale:** Respecte la philosophie des lots précédents

### Points à Améliorer ⚠️

1. **Hypothèse sur `path_studio_save_plan.dart`:**
   - Le prompt mentionne ce fichier comme existant (Lot 19)
   - **À vérifier:** Ce fichier existe-t-il vraiment?
   - **Ma stratégie:** Auditer d'abord, adapter si absent

2. **Ambiguïté sur `PathStudioWorkspace`:**
   - Le prompt suppose l'existence de ce widget
   - **À vérifier:** Structure réelle de Path Studio
   - **Ma stratégie:** Trouver le conteneur parent approprié

3. **Complexité des tests Riverpod:**
   - Le prompt demande des tests d'intégration complets
   - **Risque:** Environnement de test lourd
   - **Ma stratégie:** Commencer par tests unitaires + widget, escalader si nécessaire

4. **Gestion des erreurs sous-estimée:**
   - Le prompt minimise la gestion d'erreurs
   - **Réalité:** `ValidationException` doit être catchée
   - **Ma stratégie:** Implémenter gestion basique mais robuste

---

---

## 🎯 Prochaine Étape Recommandée

**Après validation de ce plan:**

1. **Exécuter l'audit initial** (Section 3)
2. **Valider les hypothèses** (existence des fichiers, accès aux opérations)
3. **Ajuster le plan** si nécessaire (ex: `path_studio_workspace.dart` n'existe pas)
4. **Implémenter** selon la stratégie ci-dessus
5. **Créer le rapport final** avec Evidence Pack complet

**Lot suivant logique:** Lot 21 (Tall Grass Gameplay Bridge) **OU** Lot de refactoring Path Studio (extraire sous-widgets)

---

---

## 📌 Résumé des Actions Prévues

| Étape | Action | Fichiers Impactés | Preuve Attendue |
|-------|--------|-------------------|-----------------|
| 1 | Audit initial | - | Rapport d'audit dans mistral_lot20_plan.md |
| 2 | Brancher callback | `path_studio_workspace.dart` | Diff du fichier |
| 3 | Mettre à jour manifest | `editor_notifier.dart` (si nécessaire) | Diff du fichier |
| 4 | Activer bouton Enregistrer | `path_studio_panel.dart` | Diff du fichier |
| 5 | Créer tests d'intégration | `path_studio_workspace_save_flow_test.dart` | Fichier complet |
| 6 | Exécuter tests | - | Sorties complètes des tests |
| 7 | Exécuter analyse | - | Sortie `flutter analyze` |
| 8 | Créer rapport final | `reports/pathPattern/pathpattern_20_...md` | Rapport complet + Evidence Pack |

---

*Document généré par Mistral Vibe - Plan d'implémentation pour Lot PathPattern-20*
*À valider avant exécution. Ce document décrit l'intention, pas l'implémentation.*
