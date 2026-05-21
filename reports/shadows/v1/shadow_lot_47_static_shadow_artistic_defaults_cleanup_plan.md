# Shadow-47 — Static Shadow Artistic Defaults / Auto Cleanup V0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** rendre les ombres statiques beaucoup moins catastrophiques en supprimant automatiquement les mauvaises ombres générées et en resserrant les familles de projection qui restent.

**Architecture:** Shadow-47 ne crée pas de nouveau renderer. Il corrige la politique d’authoring et les specs pures `map_core` déjà consommées par runtime/editor. Le principe produit est volontairement sévère : mieux vaut aucune ombre sur un petit décor qu’une projection moche.

**Tech Stack:** Dart, Flutter tests, `map_core` pure operations, `map_editor` application shadow helpers, existing runtime/editor consumers.

---

## 1. Diagnostic de départ

Les captures montrent encore :

- des petits losanges répétés sur l’herbe ;
- des projections de bâtiments trop lourdes ;
- des ombres qui se lisent comme des artefacts de debug plutôt que comme des ombres Pokémon ;
- une incohérence entre l’intention artistique et la politique automatique actuelle.

La cause principale n’est plus un manque de pipeline. Les lots précédents ont posé :

- `StaticShadowFamily` ;
- footprint ;
- projection polygonale ;
- runtime/editor integration.

Le problème est maintenant la politique :

1. trop d’éléments reçoivent une ombre automatique ;
2. les ombres déjà persistées restent dans le projet ;
3. les familles de projection sont encore trop agressives ;
4. le backfill protège trop de configs auto anciennes comme si elles étaient manuelles.

## 2. Décision produit

Shadow-47 adopte cette règle :

```text
PNJ / joueur : contact shadows OK.
Éléments statiques : ombres automatiques uniquement pour les cas très sûrs.
Petits décors : pas d’ombre automatique.
Bâtiments : ombre plus courte / moins large / moins opaque en V0.
Configs auto anciennes devenues mauvaises : cleanup automatique.
Configs vraiment manuelles : conservées.
```

## 3. Périmètre

### Autorisé

- `packages/map_core/lib/src/operations/static_shadow_family_projection.dart`
- `packages/map_core/test/shadow/static_shadow_family_projection_test.dart`
- `packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart`
- `packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart`
- `packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart`
- `packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart`
- `packages/map_editor/test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart`
- `reports/shadows/shadow_lot_47_static_shadow_artistic_defaults_cleanup.md`

### Interdit

- Pas de nouveau modèle persistant.
- Pas de codec JSON.
- Pas de generated file.
- Pas de build_runner.
- Pas de nouveau renderer.
- Pas de nouveau Flame Component.
- Pas de `saveLayer`, `ImageFilter`, blur, atlas.
- Pas de nouvelle lumière globale.
- Pas de Shadow Studio.
- Pas de modification `map_runtime` attendue : le runtime consomme déjà `map_core`.
- Pas de modification de la preview canvas attendue : l’éditeur consomme déjà `map_core`.

## 4. Design précis

### 4.1 Réduire la surface des auto-suggestions

Dans `element_auto_shadow_suggestion.dart`, la classification actuelle applique encore des suggestions à trop de cas :

```dart
smallSquare -> compactProp
defaultProp -> genericProjection
wideLow -> compactProp
```

Shadow-47 doit changer la politique :

```text
micro décor 1x1 / 1x2 -> null
smallSquare -> null
defaultProp -> null
wideLow -> seulement si width >= 4 OU area >= 10
tallThin -> conserver, mais très compact
buildingLarge -> conserver, mais plus sobre
```

Le point important : les petits éléments qui ne sont ni bâtiment ni lampadaire ne doivent plus recevoir d’ombre automatique.

### 4.2 Resserrer les familles de projection dans `map_core`

Dans `static_shadow_family_projection.dart`, les multiplicateurs sont trop longs pour le rendu actuel.

Valeurs V0 recommandées :

```dart
compactProp:
  lengthRatioScale: 0.38
  nearWidthMultiplierScale: 0.58
  farWidthMultiplierScale: 0.44

tallProp:
  lengthRatioScale: 0.48
  nearWidthMultiplierScale: 0.32
  farWidthMultiplierScale: 0.28

building:
  lengthRatioScale: 0.62
  nearWidthMultiplierScale: 0.78
  farWidthMultiplierScale: 0.62

foliage:
  lengthRatioScale: 0.45
  nearWidthMultiplierScale: 0.72
  farWidthMultiplierScale: 0.70
```

Pourquoi : on cherche une ombre lisible mais calme. Les longues ombres “géométriques” actuelles dominent trop la carte.

### 4.3 Nettoyer les anciennes configs auto

`element_auto_shadow_backfill.dart` doit distinguer :

```text
manuel réel
auto ancien reconnaissable
auto actuel reconnaissable
disabled explicite
sans suggestion
```

Nouveau status recommandé :

```dart
clearedAutoNoSuggestion
```

Règle :

```text
Si currentShadow est reconnaissable comme auto-générée
ET la nouvelle policy ne donne plus de suggestion
ALORS shadow devient null.
```

Cela vise directement les losanges déjà persistés sur les petits décors.

### 4.4 Détection d’une config auto

Ajouter une fonction privée dans `element_auto_shadow_backfill.dart` :

```dart
bool _isRecognizedAutoShadow(
  ProjectElementShadowConfig shadow,
  ProjectShadowCatalog catalog,
)
```

Elle doit retourner `true` pour :

- anciennes configs génériques pré-footprint déjà remplaçables par `_canReplaceExistingShadow` ;
- configs exactement égales aux suggestions connues pour le même genre d’élément ;
- configs utilisant un profil par défaut + famille/footprint/opacité/scale exactement issus de l’auto-suggestion.

Elle doit retourner `false` pour :

- `castsShadow: false` ;
- profil custom présent dans le catalogue ;
- offset/scale/opacity modifiés hors valeurs auto ;
- footprint partiel non reconnu ;
- family custom non reconnue ;
- override d’instance, car ce lot ne nettoie que `ProjectElementShadowConfig`.

### 4.5 Sauvegarde via use case existant

`ApplyElementAutoShadowSuggestionsUseCase` doit rester le point d’entrée.

Son comportement attendu après Shadow-47 :

```text
Si le cleanup retire des shadows auto anciennes -> hasChanges true -> saveProject.
Si aucun changement -> pas de sauvegarde.
```

Pas besoin de nouvelle UI dans ce lot si le bouton/action existant applique déjà le use case.

### 4.6 Selbrume

Le projet local `/Users/karim/Desktop/selbrume/project.json` ne doit pas être modifié pendant le lot sans instruction explicite.

Après implémentation, il faudra proposer une commande ou une action claire pour appliquer le cleanup au projet Selbrume. Deux options :

1. ouvrir Selbrume dans l’éditeur et lancer l’action existante “ombres automatiques” ;
2. créer plus tard un petit outil CLI dry-run/write si l’action éditeur ne suffit pas.

Shadow-47 doit d’abord rendre l’opération correcte et testée.

## 5. Tâches

### Task 1 — Tests RED pour la nouvelle politique d’auto-suggestion

**Files:**

- Modify: `packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart`

- [ ] Ajouter un test : `smallSquare returns null under artistic V0 policy`.

Cas :

```dart
final suggestion = buildElementAutoShadowSuggestion(
  element: _element(width: 2, height: 2),
  shadowCatalog: _defaultCatalog(),
);
expect(suggestion, isNull);
```

- [ ] Ajouter un test : `default prop returns null under artistic V0 policy`.

Cas :

```dart
final suggestion = buildElementAutoShadowSuggestion(
  element: _element(width: 2, height: 3),
  shadowCatalog: _defaultCatalog(),
);
expect(suggestion, isNull);
```

- [ ] Ajouter un test : `wide low needs enough surface to receive an automatic shadow`.

Cas :

```dart
final smallWide = buildElementAutoShadowSuggestion(
  element: _element(width: 3, height: 2),
  shadowCatalog: _defaultCatalog(),
);
final safeWide = buildElementAutoShadowSuggestion(
  element: _element(width: 4, height: 2),
  shadowCatalog: _defaultCatalog(),
);

expect(smallWide, isNull);
expect(safeWide, isNotNull);
expect(safeWide!.kind, ElementAutoShadowSuggestionKind.wideLow);
```

- [ ] Lancer :

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_suggestion_test.dart
```

Attendu RED : au moins les tests `smallSquare` / `defaultProp` échouent parce que le code actuel retourne encore une suggestion.

### Task 2 — Implémenter la policy stricte dans `element_auto_shadow_suggestion.dart`

**Files:**

- Modify: `packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart`

- [ ] Ajouter un guard après classification :

```dart
if (!_autoShadowKindIsArtisticallySafe(kind, width: width, height: height)) {
  return null;
}
```

- [ ] Pour éviter de recalculer les doubles, stocker :

```dart
final width = source.width.toDouble();
final height = source.height.toDouble();
```

- [ ] Ajouter :

```dart
bool _autoShadowKindIsArtisticallySafe(
  ElementAutoShadowSuggestionKind kind, {
  required double width,
  required double height,
}) {
  switch (kind) {
    case ElementAutoShadowSuggestionKind.tallThin:
    case ElementAutoShadowSuggestionKind.buildingLarge:
      return true;
    case ElementAutoShadowSuggestionKind.wideLow:
      return width >= 4 || width * height >= 10;
    case ElementAutoShadowSuggestionKind.smallSquare:
    case ElementAutoShadowSuggestionKind.defaultProp:
      return false;
  }
}
```

- [ ] Ajuster les tests existants qui attendaient des suggestions pour `smallSquare` et `defaultProp`.

Nouveau comportement attendu :

```text
smallSquare -> null
defaultProp -> null
```

- [ ] Lancer le test ciblé.

### Task 3 — Tests RED pour les specs de projection plus sobres

**Files:**

- Modify: `packages/map_core/test/shadow/static_shadow_family_projection_test.dart`

- [ ] Ajouter / ajuster un test qui vérifie que `building` est plus court qu’avant et reste plus large que `tallProp`.

Exemple d’attente structurelle, sans figer trop de nombres :

```dart
final base = defaultStaticShadowProjectionSpec;
final building = resolveStaticShadowFamilyProjectionSpec(
  family: StaticShadowFamily.building,
);
final tall = resolveStaticShadowFamilyProjectionSpec(
  family: StaticShadowFamily.tallProp,
);

expect(building.lengthRatio, lessThan(base.lengthRatio));
expect(tall.lengthRatio, lessThan(base.lengthRatio));
expect(tall.nearWidthMultiplier, lessThan(building.nearWidthMultiplier));
```

- [ ] Ajouter un test que `genericProjection` reste inchangé :

```dart
expect(
  resolveStaticShadowFamilyProjectionSpec(
    family: StaticShadowFamily.genericProjection,
  ),
  defaultStaticShadowProjectionSpec,
);
```

- [ ] Lancer :

```bash
cd packages/map_core && dart test test/shadow/static_shadow_family_projection_test.dart
```

Attendu RED : les familles actuelles sont encore trop longues.

### Task 4 — Ajuster `static_shadow_family_projection.dart`

**Files:**

- Modify: `packages/map_core/lib/src/operations/static_shadow_family_projection.dart`

- [ ] Remplacer les multiplicateurs par la V0 sobre :

```dart
case StaticShadowFamily.compactProp:
  return _scaledProjectionSpec(
    baseProjectionSpec,
    lengthRatioScale: 0.38,
    nearWidthMultiplierScale: 0.58,
    farWidthMultiplierScale: 0.44,
  );
case StaticShadowFamily.tallProp:
  return _scaledProjectionSpec(
    baseProjectionSpec,
    lengthRatioScale: 0.48,
    nearWidthMultiplierScale: 0.32,
    farWidthMultiplierScale: 0.28,
  );
case StaticShadowFamily.building:
  return _scaledProjectionSpec(
    baseProjectionSpec,
    lengthRatioScale: 0.62,
    nearWidthMultiplierScale: 0.78,
    farWidthMultiplierScale: 0.62,
  );
case StaticShadowFamily.foliage:
  return _scaledProjectionSpec(
    baseProjectionSpec,
    lengthRatioScale: 0.45,
    nearWidthMultiplierScale: 0.72,
    farWidthMultiplierScale: 0.70,
  );
```

- [ ] Lancer :

```bash
cd packages/map_core && dart test test/shadow/static_shadow_family_projection_test.dart
```

Attendu GREEN.

### Task 5 — Tests RED pour le cleanup des anciennes ombres auto

**Files:**

- Modify: `packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart`

- [ ] Ajouter un test : `clears recognized auto small square shadow when artistic policy now has no suggestion`.

Scénario :

```dart
final oldAutoSmallSquare = ProjectElementShadowConfig(
  castsShadow: true,
  shadowProfileId: 'default-ground-contact-blob',
  offsetX: 0,
  offsetY: 0,
  scaleX: 0.78,
  scaleY: 0.70,
  opacity: 0.26,
  family: StaticShadowFamily.compactProp,
  footprint: StaticShadowFootprintConfig(
    anchorXRatio: 0.5,
    anchorYRatio: 0.96,
    footprintWidthRatio: 0.46,
    footprintHeightRatio: 0.10,
  ),
);
```

Attendu :

```dart
expect(result.project.elements.single.shadow, isNull);
expect(
  result.entries.single.status,
  ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
);
expect(result.hasChanges, isTrue);
```

- [ ] Ajouter un test : `clears genericProjection auto shadow when new policy has no suggestion`.

Utiliser l’ancienne config `defaultProp` :

```dart
ProjectElementShadowConfig(
  castsShadow: true,
  shadowProfileId: 'default-ground-soft-ellipse',
  offsetX: 0,
  offsetY: 0,
  scaleX: 0.90,
  scaleY: 0.80,
  opacity: 0.28,
  family: StaticShadowFamily.genericProjection,
  footprint: StaticShadowFootprintConfig(
    anchorXRatio: 0.5,
    anchorYRatio: 0.95,
    footprintWidthRatio: 0.62,
    footprintHeightRatio: 0.12,
  ),
)
```

- [ ] Ajouter un test : `preserves manual footprint even if no suggestion exists`.

Utiliser un footprint non égal aux valeurs auto :

```dart
footprint: StaticShadowFootprintConfig(footprintWidthRatio: 0.33)
```

Attendu : status `skippedManual`, shadow conservée.

- [ ] Lancer :

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_backfill_test.dart
```

Attendu RED : status inexistant ou shadow non nettoyée.

### Task 6 — Implémenter cleanup dans `element_auto_shadow_backfill.dart`

**Files:**

- Modify: `packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart`

- [ ] Ajouter le status :

```dart
clearedAutoNoSuggestion,
```

- [ ] Ajuster `appliedCount` ou ajouter `changedCount`.

Décision V0 :

```dart
int get changedCount => entries.where((entry) =>
  entry.status == ElementAutoShadowBackfillStatus.appliedMissing ||
  entry.status == ElementAutoShadowBackfillStatus.appliedGeneric ||
  entry.status == ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion
).length;
```

Puis :

```dart
bool get hasChanges => addedDefaultProfiles || changedCount > 0;
```

Garder `appliedCount` pour compatibilité sémantique : il ne compte que les applications, pas les suppressions.

- [ ] Dans la boucle, calculer la suggestion avant de décider `skippedManual` lorsque l’ombre actuelle est active.

Pseudo-flux :

```dart
final suggestion = buildElementAutoShadowSuggestion(...);

if (suggestion == null) {
  if (currentShadow != null && _isRecognizedAutoShadow(currentShadow, projectWithDefaults.shadowCatalog)) {
    entries.add(_entry(element, ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion));
    elements.add(element.copyWith(shadow: null));
    continue;
  }
  entries.add(_entry(element, ElementAutoShadowBackfillStatus.skippedNoSuggestion));
  elements.add(element);
  continue;
}
```

- [ ] Garder `skippedDisabled` prioritaire.

- [ ] Garder les vraies configs manuelles protégées.

- [ ] Ajouter helpers privés :

```dart
bool _isRecognizedAutoShadow(
  ProjectElementShadowConfig shadow,
  ProjectShadowCatalog catalog,
) {
  return _canReplaceExistingShadow(shadow, catalog) ||
      _matchesKnownAutoShadowConfig(shadow);
}
```

- [ ] Implémenter `_matchesKnownAutoShadowConfig` avec comparaison exacte des configs auto connues pour `smallSquare` et `defaultProp`.

Ne pas exposer cette API publiquement en V0.

### Task 7 — Tests use case save/no save

**Files:**

- Modify: `packages/map_editor/test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart`

- [ ] Ajouter un test : `saves when cleanup removes recognized auto shadow`.

Attendu :

```dart
expect(result.hasChanges, isTrue);
expect(repo.savedPath, '/tmp/project.json');
expect(repo.lastSavedProject!.elements.single.shadow, isNull);
```

- [ ] Ajouter un test : `does not save when only manual shadows are skipped`.

Conserver / adapter test existant si nécessaire.

- [ ] Lancer :

```bash
cd packages/map_editor && flutter test test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart
```

Attendu GREEN après Task 6.

### Task 8 — Régressions ciblées

- [ ] Lancer :

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_suggestion_test.dart
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_backfill_test.dart
cd packages/map_editor && flutter test test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart
cd packages/map_core && dart test test/shadow/static_shadow_family_projection_test.dart
```

- [ ] Lancer suites plus larges :

```bash
cd packages/map_editor && flutter test test/application/shadow
cd packages/map_editor && flutter test test/features/tileset_library
cd packages/map_core && dart test test/shadow
```

- [ ] Lancer analyses :

```bash
cd packages/map_editor && flutter analyze lib/src/application/shadow test/application/shadow test/features/tileset_library
cd packages/map_core && dart analyze lib test/shadow
```

### Task 9 — Scans anti-dérive

- [ ] Lancer :

```bash
git diff --check
git diff --name-only | rg -n "packages/map_runtime|packages/map_gameplay|packages/map_battle|examples/playable_runtime_host"
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|\\.g\\.dart|\\.freezed\\.dart"
git diff -U0 -- packages/map_editor packages/map_core | rg -n "saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
git status --short --untracked-files=all
```

Attendu :

```text
aucune sortie pour runtime/gameplay/battle/host
aucune sortie pour models/codecs/generated
aucune sortie pour renderer avancé
```

Le status peut contenir les fichiers Shadow-46 non commités si le lot précédent n’a pas été commit.

### Task 10 — Rapport Shadow-47

**Files:**

- Create: `reports/shadows/shadow_lot_47_static_shadow_artistic_defaults_cleanup.md`

Le rapport doit inclure :

- résumé ;
- politique artistique retenue ;
- fichiers créés/modifiés ;
- fichiers hors lot préexistants ;
- tests RED/GREEN ;
- résultats de tests complets utiles ;
- analyze ;
- scans anti-dérive ;
- status final ;
- risques ;
- auto-review ;
- note honnête : ce lot améliore beaucoup le bruit, mais ne remplace pas encore des shadow masks dessinés à la main.

## 6. Critères de réussite

Shadow-47 est réussi si :

- les petits décors ne reçoivent plus d’ombres automatiques ;
- les anciennes ombres auto reconnues sur petits décors sont supprimées ;
- les ombres manuelles sont conservées ;
- les familles de projection sont plus sobres ;
- runtime/editor bénéficient du changement sans modification directe ;
- tests ciblés verts ;
- `map_editor/test/application/shadow` vert ;
- `map_core/test/shadow` vert ;
- analyze vert ;
- aucun modèle / codec / generated file ;
- aucun runtime ;
- aucun nouveau renderer.

## 7. Suite après Shadow-47

Si Shadow-47 améliore le bruit mais ne suffit pas encore pour les bâtiments, la suite réaliste est :

```text
Shadow-48 — Building Shadow Mask / Base Band Authoring Decision V0
Shadow-49 — Building Base Shadow Family V0
Shadow-50 — Runtime/Editor Building Base Shadow Visual Integration V0
```

Pourquoi : pour atteindre vraiment l’exemple Pokémon, les bâtiments auront probablement besoin d’une ombre dessinée ou d’un masque spécifique, pas seulement d’une projection mathématique.

## 8. Auto-review du plan

- Le plan nettoie les ombres automatiques existantes : oui.
- Le plan durcit les futures suggestions : oui.
- Le plan protège les ombres manuelles : oui.
- Le plan ne touche pas aux modèles persistants : oui.
- Le plan ne touche pas aux codecs JSON : oui.
- Le plan évite un nouveau renderer : oui.
- Le plan évite une lumière globale : oui.
- Le plan reconnaît que les vraies ombres Pokémon demanderont probablement un lot de mask/base shadow : oui.
