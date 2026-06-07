# NS-SCENES-V1-94 bis — Evidence Pack

## 1. Contexte

Repository :

```text
/Users/karim/Project/pokemonProject
```

Branche :

```text
main
```

Etat initial rapporté au début du correctif :

```text
git status --short --untracked-files=all
<aucune sortie>
```

## 2. Prompt et arbitrage

Le fichier attaché était :

```text
NS-SCENES-V1-95 — Cinematic Actor Display Preview Sprite Resolver Prep Contract
```

Mais Karim a explicitement demandé :

```text
Le problème est qu'il manque les éléments du "path studio" et donc l'eau.
```

Décision : priorité à la demande directe de Karim. V1-95 n'a pas été exécuté ; ce tour ferme un correctif V1-94 bis.

## 3. RED

Commande :

```text
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'uses Path Studio center pattern when a path layer references its base preset'
```

Echec fonctionnel observé avant correction :

```text
Expected: Set:['water_pattern']
  Actual: Set:['water_base']
   Which: does not contain 'water_pattern'
```

Conclusion : le plan cinematic rendait le preset de base `water_base` au lieu du pattern Path Studio `water_pattern`.

## 4. GREEN ciblé

Commande :

```text
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'uses Path Studio center pattern when a path layer references its base preset'
```

Résultat :

```text
00:02 +1: All tests passed!
```

Commande de non-régression V1-94 :

```text
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'builds extended backdrop bitmap instructions for neutral terrain path surface and placed elements'
```

Résultat :

```text
00:01 +1: All tests passed!
```

## 5. Suite Builder complète

Commande :

```text
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Résultat final :

```text
00:35 +175: All tests passed!
```

## 6. Analyse ciblée

Commande :

```text
cd packages/map_editor
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart test/cinematic_builder_workspace_test.dart
```

Résultat :

```text
Analyzing 2 items...
No issues found! (ran in 1.7s)
```

## 7. Checks anti-scope

Commande :

```text
git diff --check
```

Résultat :

```text
<aucune sortie>
```

Commande :

```text
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples selbrume
```

Résultat :

```text
<aucune sortie>
```

Commande :

```text
rg -n "package:flame|GameWidget|FlameGame|PlayableMapGame|RuntimeMapGame|GameState|map_runtime|MapCanvas\(|MapGridPainter\(|playbackTimeMs|currentTimeMs|isPlaying|Timer\(|Ticker|AnimationController|gpt-image-2|image_generation" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart packages/map_editor/test/cinematic_builder_workspace_test.dart
```

Résultat :

```text
<aucune sortie ; exit 1 attendu pour aucun match>
```

## 8. Diff utile

Fichiers produit/test :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
```

Code utile :

```dart
ProjectPathPatternPreset? linkedPattern;
var hasAmbiguousPattern = false;
for (final pattern in manifest.pathPatternPresets) {
  if (pattern.basePathPresetId.trim() != trimmed) {
    continue;
  }
  if (linkedPattern != null) {
    hasAmbiguousPattern = true;
    break;
  }
  linkedPattern = pattern;
}
if (!hasAmbiguousPattern && linkedPattern != null) {
  return _ResolvedPathPreset(
    sourceId: linkedPattern.id,
    basePreset: base,
    patternPreset: linkedPattern,
  );
}
return _ResolvedPathPreset(sourceId: base.id, basePreset: base);
```

Assertion de test :

```dart
expect(
  pathInstructions.map((instruction) => instruction.sourceId).toSet(),
  {'water_pattern'},
);
```

## 9. Statut proposé

```text
NS-SCENES-V1-94 bis — DONE
NS-SCENES-V1-95 — TODO
```

V1-95 reste le prochain lot recommandé, maintenant que le backdrop Path Studio/eau est aligné avec le Map Editor.

