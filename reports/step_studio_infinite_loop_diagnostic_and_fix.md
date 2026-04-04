# Rapport de Diagnostic & Correctif : Step Studio Infinite Loop / RAM Explosion

**Date :** 2026-04-04  
**Auteur :** Qwen Code (diagnostic autonome)  
**Projet :** Pokémon-like Flutter Editor — `packages/map_editor`  
**Fichier corrigé :** `packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart`  
**Test ajouté :** `packages/map_editor/test/step_studio_workspace_regression_test.dart`

---

## 1. Résumé Exécutif

**Cause racine :** Trois boucles `for` dans la méthode `build()` de `_StepStudioWorkspaceState` étaient écrites **sans expression d'incrémentation** (`index++`). Cela provoquait une **boucle infinie synchrone** lors du rendu Flutter, générant un nombre infini de widgets dans des spreads `...[]`.

**Impact :** Au clic sur "Ajouter une cutscene liée", "Ajouter un résultat" ou "Ajouter un changement monde", le widget reconstruisait sa UI. La boucle `for` sans incrément tournait indéfiniment sur le premier élément de la liste, créant une infinité d'instances widget. Le thread UI était bloqué (freeze macOS, roue colorée) et la RAM montait jusqu'à des niveaux absurdes (183 Go+) car Flutter tentait d'allouer infiniment des objets `Widget`.

**Correctif :** Remplacement des trois boucles `for (var index = 0; index < X.length; index)` par `for (final entry in X.asMap().entries)`, un pattern intrinsèquement borné qui ne peut pas boucler infiniment.

**Complexité du fix :** Minimal — 3 lignes de boucle remplacées, avec commentaires explicatifs. Aucune refonte architecturale, aucun changement de comportement produit.

---

## 2. Symptôme Utilisateur Observé

| Symptôme | Observation |
|---|---|
| **Déclencheur** | Clic sur "Ajouter une cutscene liée", "Ajouter un résultat", "Ajouter un changement monde" dans Step Studio |
| **Comportement** | Application macOS freeze immédiatement |
| **Curseur** | Roue colorée macOS spinning |
| **RAM** | Monte exponentiellement jusqu'à 183 Go+ |
| **Alerte macOS** | "L'application utilise une quantité de mémoire extrêmement élevée" |
| **Reproductibilité** | 100% reproductible dès qu'une step contient au moins 1 cutscene/outcome/worldChange et que le widget rebuild |

---

## 3. Cause Racine Exacte

### Le Bug

Trois boucles `for` dans la méthode `build()` de `_StepStudioWorkspaceState` (classe privée dans `step_studio_workspace.dart`) omettaient l'incrémentation de l'index :

```dart
// ❌ BUG — index n'est JAMAIS incrémenté
for (var index = 0; index < links.length; index) ...[
  _CutsceneLinkRow(link: links[index], ...),
  const SizedBox(height: 8),
],
```

Quand `links.length > 0` :
- `index` commence à 0
- La condition `0 < links.length` est toujours vraie
- `index` ne change jamais (pas de `index++`)
- La boucle génère **infiniment** `_CutsceneLinkRow(link: links[0], ...)` et `SizedBox`
- Le spread `...[]` essaie d'insérer une infinité d'éléments dans la collection de widgets
- Flutter tente de materialiser ces widgets → RAM explosion + CPU à 100%

### Les 3 Emplacements Affectés

| # | Ligne (avant fix) | Méthode | Liste itérée |
|---|---|---|---|
| 1 | 1582 | `_buildCutsceneLinksSection` | `links` (cutscenes liées) |
| 2 | 1651 | `_buildOutcomesSection` | `outcomes` (résultats de progression) |
| 3 | 1758 | `_buildWorldPersistenceSection` | `worldChanges` (changements monde) |

### Pourquoi le Bug se Manifestait au Clic sur "Ajouter …"

1. La step initiale (bootstrap) a des listes **vides** de cutscenes, outcomes et worldChanges
2. Au premier build, les trois boucles ne s'exécutent jamais (`0 < 0` est faux)
3. L'utilisateur clique sur "Ajouter une cutscene liée"
4. `_replaceSelectedStep()` ajoute un élément à la liste `cutscenes`
5. `setState()` déclenche un rebuild
6. Au rebuild, `links.length == 1`, donc `0 < 1` est vrai → **boucle infinie**
7. Le même mécanisme s'applique aux outcomes et worldChanges

**C'est pourquoi le bug n'apparaissait qu'APRÈS avoir ajouté un élément**, et non au chargement initial du Step Studio.

---

## 4. Chaîne Complète de Déclenchement

```
Clic utilisateur sur "Ajouter une cutscene liée"
  │
  ├─ onPressed callback dans _buildCutsceneLinksSection
  │   │
  │   ├─ Crée un nouveau StepStudioCutsceneLink
  │   ├─ Appelle _replaceSelectedStep(selectedStep.copyWith(cutscenes: nextLinks))
  │   │   │
  │   │   ├─ _replaceSelectedStep crée une copie du document avec la step modifiée
  │   │   └─ Appelle _replaceDraft(doc.copyWith(steps: nextSteps))
  │   │       │
  │   │       ├─ Garde anti-boucle: if (_draftDocument == next) return;  ✅ ne trigger pas
  │   │       └─ setState(() { _draftDocument = next; })
  │   │           │
  │   │           └─ ⚡ Schedule un rebuild du StatefulWidget
  │   │
  │   └─ Rebuild commence → build() appelé
  │       │
  │       ├─ _buildStepEditor() appelé
  │       │   │
  │       │   └─ _buildCutsceneLinksSection() appelé
  │       │       │
  │       │       └─ for (var index = 0; index < links.length; index) ...[
  │       │              │
  │       │              ├─ index = 0, links.length = 1 → 0 < 1 = true
  │       │              ├─ Génère _CutsceneLinkRow(link: links[0]) + SizedBox
  │       │              ├─ index reste 0 (PAS de index++)
  │       │              ├─ 0 < 1 = true → RECOMMENCE
  │       │              ├─ index = 0 → génère à nouveau ...
  │       │              ├─ ∞ itérations
  │       │              │
  │       │              └─ 💥 Allocation infinie de widgets
  │       │                 → RAM explose (Go+)
  │       │                 → Thread UI bloqué (roue macOS)
  │       │                 → Application freeze
  │
  └─ (Même chaîne pour "Ajouter un résultat" et "Ajouter un changement monde")
```

**Nature de la boucle :** SYNCHRONE — pas de Riverpod, pas de Future, pas de addPostFrameCallback. C'est une boucle `for` pure dans le code Dart exécuté sur le thread UI.

---

## 5. Pourquoi la RAM Explose

Flutter utilise un système de "collection literal spread" (`...[]`) dans les méthodes `build`. Quand Dart évalue :

```dart
for (var index = 0; index < 1; index) ...[
  _CutsceneLinkRow(...),
  const SizedBox(height: 8),
],
```

Il essaie d'insérer chaque itération dans la liste parente. Comme la boucle ne termine jamais :

1. Dart alloue un `_CutsceneLinkRow` à chaque itération (objet avec son propre `BuildContext` potentiel)
2. Chaque `SizedBox` est un `const` mais le `_CutsceneLinkRow` ne l'est pas
3. La liste de widgets résultante grandit indéfiniment en mémoire
4. Le garbage collector ne peut rien collecter car la liste est toujours référencée pendant la construction
5. Résultat : courbe de RAM exponentielle jusqu'à saturation système

---

## 6. Pourquoi l'Intuition Initiale (Riverpod/Provider Loop) Était Faussée

Le diagnostic initial soupçonnait une boucle entre :
- état local du Step Studio
- provider Riverpod de sélection narrative
- callbacks post-frame / hydratation

**Cette intuition était compréhensible mais incorrecte.** Le système de sync provider/local était en réalité **bien conçu** :

✅ `_dispatchSelectionAfterFrame` utilise correctement `addPostFrameCallback`  
✅ La déduplication `_lastDispatchedSelection` évite les re-notifications  
✅ `_replaceDraft` a une garde `if (_draftDocument == next) return;`  
✅ `didUpdateWidget` ne re-hydrate que si `project` ou `projection` change  
✅ `_selectStep` a une garde `if (_selectedStepId == stepId) return;`  

**Le vrai coupable** était beaucoup plus trivial : un oubli de `++` dans une boucle `for`. C'est exactement le genre de bug qui passe inaperçu en code review car la syntaxe `for (...; ...; )` ressemble visuellement à une boucle correcte.

---

## 7. Fichiers Inspectés

| Fichier | Rôle | Statut |
|---|---|---|
| `packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart` | Widget principal du Step Studio | ✅ **Modifié** (fix des 3 boucles) |
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | Parent qui héberge le Step Studio | ✅ Lu — aucun problème trouvé |
| `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart` | État Riverpod de navigation narrative | ✅ Lu — correct |
| `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart` | Providers de projection narrative | ✅ Lu — correct |
| `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart` | Construction de la projection | ✅ Lu — correct |
| `packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart` | Panneau bibliothèque gauche | ✅ Lu — aucun problème |
| `packages/map_editor/lib/src/ui/panels/narrative_inspector_panel.dart` | Inspecteur droite | ✅ Lu — aucun problème |
| `packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart` | Logique métier Step Studio | ✅ Lu — aucun problème |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` | Notifier Riverpod global | ✅ Lu — aucun problème |
| `packages/map_editor/lib/src/features/editor/state/editor_state.dart` | État global de l'éditeur | ✅ Lu — aucun problème |
| `packages/map_editor/test/step_studio_workspace_regression_test.dart` | Tests de non-régression | ✅ **Modifié** (test ajouté) |
| `packages/map_editor/test/step_studio_authoring_test.dart` | Tests d'authoring | ✅ Lu — inchangé |

---

## 8. Modifications Faites

### 8.1 `step_studio_workspace.dart` — 3 boucles corrigées

**Avant (bug) :**
```dart
for (var index = 0; index < links.length; index) ...[
  _CutsceneLinkRow(link: links[index], ...),
],

for (var index = 0; index < outcomes.length; index) ...[
  _OutcomeRow(outcome: outcomes[index], ...),
],

for (var index = 0; index < worldChanges.length; index) ...[
  _WorldChangeRow(change: worldChanges[index], ...),
],
```

**Après (fix) :**
```dart
// GARDE anti-boucle: `.asMap().entries` est intrinsèquement protégé
// contre l'oubli de `++` qui causait la boucle infinie build().
for (final entry in links.asMap().entries)
  ...[
    _CutsceneLinkRow(link: entry.value, ...),
  ],

for (final entry in outcomes.asMap().entries)
  ...[
    _OutcomeRow(outcome: entry.value, ...),
  ],

for (final entry in worldChanges.asMap().entries)
  ...[
    _WorldChangeRow(change: entry.value, ...),
  ],
```

**Pourquoi `.asMap().entries` :**
- Retourne un `Iterable<MapEntry<int, T>>` où chaque clé est l'index et chaque valeur est l'élément
- L'itération via `for-in` est intrinsèquement bornée — impossible d'oublier un incrément
- Donne accès à `entry.key` (index) et `entry.value` (élément) sans compteur manuel
- Pattern idiomatique Dart pour les cas où on a besoin de l'index ET de la valeur

**Access aux index dans les callbacks :** Les callbacks utilisaient `index` pour référencer l'élément dans les listes. Avec `.asMap().entries`, on utilise `entry.key` à la place — sémantiquement identique.

### 8.2 `step_studio_workspace_regression_test.dart` — Test anti-régression ajouté

Un nouveau test `testWidgets` vérifie que :
1. Le build complète en temps borné (< 30s) même avec des listes non vides
2. Aucune exception n'est levée
3. Un rebuild subséquent ne déclenche pas de boucle infinie

Le test contient un `Timeout(Duration(seconds: 30))` — si la boucle infinie existait encore, le test ne terminerait jamais et serait tué par le test runner.

---

## 9. Justification Architecture / State Management

Le code existant de synchronisation entre état local et providers Riverpod était **bien architecturé** :

### Points Positifs Conservés

| Mécanisme | Pourquoi c'est bien |
|---|---|
| `_dispatchSelectionAfterFrame` via `addPostFrameCallback` | Évite la mutation provider pendant build |
| `_selectionDispatchScheduled` flag | Évite la planification multiple de callbacks |
| `_lastDispatchedSelection` déduplication | Évite les re-notifications inutiles au parent |
| `_replaceDraft` garde `if (_draftDocument == next) return` | Évite les setState redondants en cascade |
| `_selectStep` garde `if (_selectedStepId == stepId) return` | Évite les callbacks parent redondants |
| `didUpdateWidget` ne re-hydrate que si project/projection change | Évite la re-hydratation à chaque rebuild |
| `_ensureEntitiesLoadedForMap` avec `_entityMapsLoading` Set | Évite les requêtes concurrentes duplicates |

### Le Vrai Problème Était Ailleurs

Le bug n'était **PAS** dans la couche state management. Il était dans la **couche présentation pure** — une boucle `for` malformée dans le `build()`. C'est un rappel que les bugs les plus dévastateurs ne sont pas toujours dans l'architecture complexe : parfois c'est juste un `++` manquant.

---

## 10. Garde-Fous Ajoutés

### 10.1 Pattern `.asMap().entries` (intrinsèquement sûr)

Le remplacement de `for (var i = 0; i < n; i)` par `for (final entry in list.asMap().entries)` est une **protection structurelle** — pas besoin de se souvenir d'incrémenter quoi que ce soit. C'est l'itérateur Dart qui gère le comptage.

### 10.2 Commentaires Explicatifs dans le Code

Chaque boucle corrigée contient un commentaire expliquant :
- **La cause historique** du bug (oubli de `++`)
- **La conséquence** (boucle infinie, RAM explosion)
- **La stratégie de protection** (pourquoi `.asMap().entries` est sûr)

Ces commentaires servent de "panneaux de danger" pour tout développeur futur qui toucherait à ce code.

### 10.3 Test de Non-Régression avec Timeout

Le test `build completes in bounded time with non-empty cutscenes, outcomes, and worldChanges (anti-infinite-loop guard)` :
- Construit un Step Studio avec des listes non vides
- Vérifie que le build termine en < 30 secondes
- Un échec = timeout du test = régression détectée immédiatement en CI

---

## 11. Tests Ajoutés ou Renforcés

| Test | Fichier | Type | Statut |
|---|---|---|---|
| `defers initial step selection callback after frame (provider-safe)` | `step_studio_workspace_regression_test.dart` | Widget | ✅ Existant — passe |
| `EditorSidebarListRow with subtitle does not overflow` | `step_studio_workspace_regression_test.dart` | Widget | ✅ Existant — passe |
| **`build completes in bounded time with non-empty cutscenes, outcomes, and worldChanges (anti-infinite-loop guard)`** | `step_studio_workspace_regression_test.dart` | **Widget (nouveau)** | ✅ **Passe** |
| `parses legacy step metadata as fallback document` | `step_studio_authoring_test.dart` | Unit | ✅ Existant — passe |
| `apply + parse roundtrip keeps explicit Step Studio document` | `step_studio_authoring_test.dart` | Unit | ✅ Existant — passe |
| `generates stable user-friendly ids` | `step_studio_authoring_test.dart` | Unit | ✅ Existant — passe |

**Résultat global :** `6/6 tests pass` ✅

---

## 12. Validations Exécutées

| Validation | Commande | Résultat |
|---|---|---|
| **flutter analyze** (fichier corrigé) | `flutter analyze lib/src/ui/canvas/step_studio_workspace.dart` | ✅ 4 infos (const pre-existing, 0 errors) |
| **flutter analyze** (package complet) | `flutter analyze` dans `packages/map_editor` | ✅ 211 infos (pre-existing, 0 errors) |
| **flutter test** (régression Step Studio) | `flutter test test/step_studio_workspace_regression_test.dart` | ✅ 3/3 pass |
| **flutter test** (authoring Step Studio) | `flutter test test/step_studio_authoring_test.dart` | ✅ 3/3 pass |

**Zéro erreur de compilation. Zéro nouveau warning. Zéro test échoué.**

---

## 13. Limites Restantes

| Limite | Impact | Priorité |
|---|---|---|
| Pas de test widget pour les boutons "Ajouter …" directement (simulation de tap) | On teste le build avec listes non vides, mais pas le flux complet du clic | Moyenne — le test actuel couvre déjà la boucle infinie |
| Pas de test pour vérifier que `_replaceDraft` ne mute PAS le draft original | La garde `if (_draftDocument == next)` est testée implicitement mais pas explicitement | Basse — le comportement est correct |
| `_ensureEntitiesLoadedForMap` appelle `setState` 3 fois par invocation | Pourrait être optimisé mais ne cause pas de boucle (garde `_entityMapsLoading`) | Basse — pas un bug |

---

## 14. Pistes Futures (Non Requis pour ce Fix)

1. **Lint personnalisé :** Ajouter une règle `custom_lint` ou `dart analyze` qui détecte les boucles `for` sans expression d'incrémentation dans les fichiers contenant des méthodes `build()`.

2. **Migration vers `ListView.builder` :** Pour les listes potentiellement longues de cutscenes/outcomes/worldChanges, remplacer les boucles `for` par `ListView.builder` améliorerait les performances (lazy rendering au lieu de construction eager).

3. **Tests d'intégration complets :** Ajouter des tests `flutter drive` ou `integration_test` qui simulent le flux complet : clic sur "Ajouter" → vérification que l'élément apparaît → sélection → édition → sauvegarde.

4. **Riverpod 2.x `ref.listen` :** Remplacer le mécanisme manuel `_dispatchSelectionAfterFrame` par `ref.listen` de Riverpod pour une sync encore plus propre entre état local et providers.

---

## Annexe : Diff Complet

```diff
--- a/packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart

@@ -1579,8 +1579,21 @@ class _StepStudioWorkspaceState extends State<StepStudioWorkspace> {
               text:
                   'Aucune cutscene liée. Vous pouvez ajouter une cutscene de démarrage, principale ou de validation.',
             ),
-          for (var index = 0; index < links.length; index) ...[
-            _CutsceneLinkRow(
-              link: links[index],
+          // NOTE BUG FIX (2026-04-04):
+          // Les trois boucles `for` ci-dessous utilisaient previously
+          // `for (var index = 0; index < X.length; index)` sans `index++`,
+          // ce qui provoquait une boucle infinie SYNCHRONE dans build().
+          // Quand la liste n'était pas vide, `index` restait à 0 indéfiniment,
+          // générant une infinité de widgets dans le spread `...[]`.
+          // Conséquence: freeze macOS, roue colorée, RAM qui explose (Go+).
+          //
+          // Garde: on utilise maintenant `.asMap().entries` qui est
+          // intrinsèquement protégé contre ce type d'erreur — chaque entrée
+          // est itérée exactement une fois, sans compteur manuel.
+          for (final entry in links.asMap().entries)
+            ...[
+              _CutsceneLinkRow(
+                link: entry.value,
               cutsceneOptions: cutsceneOptions,
               enabled: _canEdit,
               onRoleChanged: (role) {
@@ -1588,22 +1601,23 @@ class _StepStudioWorkspaceState extends State<StepStudioWorkspace> {
-                nextLinks[index] = nextLinks[index].copyWith(role: role);
+                nextLinks[entry.key] = nextLinks[entry.key].copyWith(role: role);
                 ...
-              onCutsceneChanged: (cutsceneId) {
-                if (cutsceneId == null) return;
-                final nextLinks = links.toList(growable: true);
-                nextLinks[index] =
-                    nextLinks[index].copyWith(cutsceneId: cutsceneId);
+              onCutsceneChanged: (cutsceneId) {
+                if (cutsceneId == null) return;
+                final nextLinks = links.toList(growable: true);
+                nextLinks[entry.key] =
+                    nextLinks[entry.key].copyWith(cutsceneId: cutsceneId);
                 ...
-              onRemove: () {
-                if (!_canEdit) return;
-                final nextLinks = links.toList(growable: true)..removeAt(index);
+              onRemove: () {
+                if (!_canEdit) return;
+                final nextLinks = links.toList(growable: true)
+                  ..removeAt(entry.key);
                 ...
-            ),
-            const SizedBox(height: 8),
-          ],
+              ),
+              const SizedBox(height: 8),
+            ],

@@ -1648,44 +1662,48 @@ class _StepStudioWorkspaceState extends State<StepStudioWorkspace> {
-          for (var index = 0; index < outcomes.length; index) ...[
-            _OutcomeRow(
-              outcome: outcomes[index],
+          // GARDE anti-boucle: même motif que cutscenes — `.asMap().entries`
+          // au lieu d'un compteur manuel sujet aux oublis de `++`.
+          for (final entry in outcomes.asMap().entries)
+            ...[
+              _OutcomeRow(
+                outcome: entry.value,
                 ...
-                final current = outcomes[index];
+                final current = outcomes[entry.key];
                 ...
-                nextOutcomes[index] = current.copyWith(...);
+                nextOutcomes[entry.key] = current.copyWith(...);
                 ...
-                widget.onSelectOutcome(outcomes[index].outcomeId);
+                widget.onSelectOutcome(outcomes[entry.key].outcomeId);
                 ...
-                ..removeAt(index);
+                ..removeAt(entry.key);
                 ...
-            ),
-            const SizedBox(height: 8),
-          ],
+              ),
+              const SizedBox(height: 8),
+            ],

@@ -1755,43 +1773,47 @@ class _StepStudioWorkspaceState extends State<StepStudioWorkspace> {
-          for (var index = 0; index < worldChanges.length; index) ...[
-            _WorldChangeRow(
-              change: worldChanges[index],
+          // GARDE anti-boucle: même motif — `.asMap().entries` protège
+          // contre l'oubli de `++` qui causait la boucle infinie build().
+          for (final entry in worldChanges.asMap().entries)
+            ...[
+              _WorldChangeRow(
+                change: entry.value,
                 ...
-                entityOptions: _entitiesForMap(worldChanges[index].mapId)
+                entityOptions: _entitiesForMap(worldChanges[entry.key].mapId)
                 ...
-                next[index] = next[index].copyWith(...);
+                next[entry.key] = next[entry.key].copyWith(...);
                 ...
-                ..removeAt(index);
+                ..removeAt(entry.key);
                 ...
-            ),
-            const SizedBox(height: 8),
-          ],
+              ),
+              const SizedBox(height: 8),
+            ],
```

---

## Fichiers Modifiés (Résumé)

| Fichier | Changement |
|---|---|
| `packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart` | 3 boucles `for` corrigées + commentaires explicatifs |
| `packages/map_editor/test/step_studio_workspace_regression_test.dart` | 1 test anti-régression ajouté + import `step_studio_authoring.dart` |

---

**Fin du rapport.**
