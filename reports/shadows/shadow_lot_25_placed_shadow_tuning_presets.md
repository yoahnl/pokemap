# Shadow-25 — Placed Shadow Tuning Presets / Footprint UX V0

## 1. Résumé du lot

Shadow-25 ajoute des réglages rapides d'ombre d'instance dans l'éditeur. Le lot introduit un helper editor-only de presets et un bloc UI compact dans `PlacedElementShadowOverrideSection`, visible uniquement en mode `Personnaliser`.

Les presets écrivent uniquement un `MapPlacedElementShadowOverride` en mode `custom` avec `offsetX`, `offsetY`, `scaleX`, `scaleY` et `opacity`. Ils ne modifient pas `ProjectElementEntry.shadow`.

## 2. Design retenu

Design validé avant implémentation :

- helper pur dans `packages/map_editor/lib/src/application/shadow/placed_element_shadow_tuning_presets.dart` ;
- cinq presets stables ;
- bloc `Réglages rapides` placé après `Profil Shadow` et avant les champs numériques ;
- application par le callback existant `onChanged` de Shadow-23 ;
- conservation du `shadowProfileId` uniquement quand l'override courant est déjà `custom`.

Le lot ne crée pas de direction globale de lumière : les presets sont seulement des raccourcis UX qui appliquent des valeurs d'override sur une instance.

## 3. Fichiers créés

- `packages/map_editor/lib/src/application/shadow/placed_element_shadow_tuning_presets.dart`
- `packages/map_editor/test/application/shadow/placed_element_shadow_tuning_presets_test.dart`
- `reports/shadows/shadow_lot_25_placed_shadow_tuning_presets.md`

## 4. Fichiers modifiés

- `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart`
- `packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart`

## 5. Fichiers non modifiés explicitement

- `packages/map_runtime/**`
- `packages/map_gameplay/**`
- `packages/map_battle/**`
- `packages/map_core/lib/src/models/**`
- `packages/map_editor/lib/src/application/shadow/placed_element_shadow_override_read_model.dart`
- `packages/map_editor/lib/src/application/shadow/element_shadow_read_model.dart`
- `packages/map_editor/lib/src/ui/canvas/**`
- `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart`

## 6. API helper ajoutée

```dart
final class PlacedElementShadowTuningPreset {
  const PlacedElementShadowTuningPreset({
    required this.id,
    required this.label,
    required this.description,
    required this.offsetX,
    required this.offsetY,
    required this.scaleX,
    required this.scaleY,
    required this.opacity,
  });

  final String id;
  final String label;
  final String description;
  final double offsetX;
  final double offsetY;
  final double scaleX;
  final double scaleY;
  final double opacity;
}

List<PlacedElementShadowTuningPreset> createPlacedElementShadowTuningPresets();

MapPlacedElementShadowOverride applyPlacedElementShadowTuningPreset({
  required PlacedElementShadowTuningPreset preset,
  MapPlacedElementShadowOverride? currentOverride,
});
```

## 7. Liste des presets V0

| id | label | offsetX | offsetY | scaleX | scaleY | opacity |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| `compact-footprint` | Petite ombre | 0 | 2 | 0.65 | 0.45 | 0.24 |
| `soft-wide-footprint` | Ombre large douce | 0 | 3 | 1.15 | 0.60 | 0.22 |
| `subtle-footprint` | Ombre discrète | 0 | 2 | 0.75 | 0.35 | 0.14 |
| `cast-bottom-right` | Portée bas-droite | 6 | 5 | 0.85 | 0.45 | 0.26 |
| `cast-bottom-left` | Portée bas-gauche | -6 | 5 | 0.85 | 0.45 | 0.26 |

Tous les presets ont `scaleX > 0`, `scaleY > 0` et `opacity` dans `0..1`.

## 8. Règles de conservation du shadowProfileId

`applyPlacedElementShadowTuningPreset(...)` conserve `shadowProfileId` uniquement si `currentOverride?.mode == ShadowOverrideMode.custom`.

Conséquences :

- override `null` -> override `custom` avec `shadowProfileId == null` ;
- override `inherit` explicite -> override `custom` avec `shadowProfileId == null` ;
- override `disabled` -> override `custom` avec `shadowProfileId == null` ;
- override `custom` avec `shadowProfileId` -> override `custom` avec le même `shadowProfileId`.

## 9. UI “Réglages rapides”

`PlacedElementShadowOverrideSection` affiche le bloc uniquement en mode `Personnaliser`.

Ordre UI retenu :

```text
Profil Shadow
Réglages rapides
Offset / Scale / Opacité
```

Le bloc utilise les `PushButton` existants et déclenche `onChanged` avec un override `custom` produit par le helper. Les contrôleurs numériques existants se synchronisent ensuite via `didUpdateWidget`, ce qui met à jour les champs visibles après clic.

## 10. Pourquoi ce lot ne crée pas de direction globale de lumière

Les labels `Portée bas-droite` et `Portée bas-gauche` simulent seulement des valeurs d'offset/scale/opacité appliquées à une instance placée. Aucune notion persistante ou globale de soleil, `timeOfDay`, `LightDirection`, `WorldLightState` ou `ShadowLightProfile` n'est créée.

## 11. Pourquoi ce lot ne touche pas au runtime

Shadow-25 est un lot UX éditeur. Le runtime sait déjà consommer `MapPlacedElement.shadowOverride` via les lots précédents. Ce lot ne modifie ni renderer, ni host runtime, ni modèle persistant.

## 12. Tests ajoutés

Nouveau test helper :

- `packages/map_editor/test/application/shadow/placed_element_shadow_tuning_presets_test.dart`

Couverture :

- ids stables ;
- ids uniques ;
- ranges numériques valides ;
- application sur override `null` ;
- application sur override `disabled` ;
- conservation du profil depuis override `custom` ;
- valeurs exactes de `compact-footprint`, `cast-bottom-right`, `cast-bottom-left`.

Tests widget complétés :

- bloc `Réglages rapides` visible seulement en mode custom ;
- clic `Petite ombre` applique les valeurs attendues ;
- clic `Portée bas-droite` donne `offsetX > 0` et `offsetY > 0` ;
- clic `Portée bas-gauche` donne `offsetX < 0` et `offsetY > 0` ;
- preset conserve un `shadowProfileId` custom existant ;
- champs numériques synchronisés après preset.

## 13. Commandes lancées

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print

cd packages/map_editor && flutter test test/application/shadow/placed_element_shadow_tuning_presets_test.dart test/features/tileset_library/placed_element_shadow_override_section_test.dart
dart format packages/map_editor/lib/src/application/shadow/placed_element_shadow_tuning_presets.dart packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart packages/map_editor/test/application/shadow/placed_element_shadow_tuning_presets_test.dart packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart
cd packages/map_editor && flutter test test/application/shadow/placed_element_shadow_tuning_presets_test.dart
cd packages/map_editor && flutter test test/features/tileset_library/placed_element_shadow_override_section_test.dart
cd packages/map_editor && flutter test test/application/shadow
cd packages/map_editor && flutter test test/features/tileset_library
cd packages/map_editor && flutter analyze lib/src/application/shadow lib/src/ui/panels/tileset_palette/widgets/placed_instances test/application/shadow test/features/tileset_library

git diff --name-only | rg -n "packages/map_runtime|packages/map_gameplay|packages/map_battle"
git diff --name-only | rg -n "packages/map_core/lib/src/models"
git diff -U0 -- packages/map_editor packages/map_core | rg -n "drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|ShadowLayerComponent|zOrder|zIndex|WorldLightState|ShadowLightProfile|timeOfDay|LightDirection|SunDirection"
git diff -U0 -- packages/map_editor | rg -n "package:map_runtime|map_runtime/src"
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

## 14. Résultats complets des tests ciblés

### RED initial

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow/placed_element_shadow_tuning_presets_test.dart test/features/tileset_library/placed_element_shadow_override_section_test.dart
```

Sortie utile complète :

```text
test/application/shadow/placed_element_shadow_tuning_presets_test.dart:3:8: Error: Error when reading 'lib/src/application/shadow/placed_element_shadow_tuning_presets.dart': No such file or directory
import 'package:map_editor/src/application/shadow/placed_element_shadow_tuning_presets.dart';
       ^
test/application/shadow/placed_element_shadow_tuning_presets_test.dart:117:1: Error: Type 'PlacedElementShadowTuningPreset' not found.
PlacedElementShadowTuningPreset _preset(String id) {
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/application/shadow/placed_element_shadow_tuning_presets_test.dart:8:23: Error: Method not found: 'createPlacedElementShadowTuningPresets'.
      final presets = createPlacedElementShadowTuningPresets();
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/application/shadow/placed_element_shadow_tuning_presets_test.dart:24:23: Error: Method not found: 'createPlacedElementShadowTuningPresets'.
      final presets = createPlacedElementShadowTuningPresets();
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/application/shadow/placed_element_shadow_tuning_presets_test.dart:38:24: Error: Method not found: 'applyPlacedElementShadowTuningPreset'.
      final override = applyPlacedElementShadowTuningPreset(
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/application/shadow/placed_element_shadow_tuning_presets_test.dart:55:24: Error: Method not found: 'applyPlacedElementShadowTuningPreset'.
      final override = applyPlacedElementShadowTuningPreset(
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/application/shadow/placed_element_shadow_tuning_presets_test.dart:70:24: Error: Method not found: 'applyPlacedElementShadowTuningPreset'.
      final override = applyPlacedElementShadowTuningPreset(
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/application/shadow/placed_element_shadow_tuning_presets_test.dart:93:27: Error: Method not found: 'applyPlacedElementShadowTuningPreset'.
      final bottomRight = applyPlacedElementShadowTuningPreset(
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/application/shadow/placed_element_shadow_tuning_presets_test.dart:97:26: Error: Method not found: 'applyPlacedElementShadowTuningPreset'.
      final bottomLeft = applyPlacedElementShadowTuningPreset(
                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/application/shadow/placed_element_shadow_tuning_presets_test.dart:118:10: Error: Method not found: 'createPlacedElementShadowTuningPresets'.
  return createPlacedElementShadowTuningPresets().singleWhere(
         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
00:00 +0 -1: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/placed_element_shadow_tuning_presets_test.dart [E]
00:01 +7 -2: /Users/karim/Project/pokemonProject/packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart: PlacedElementShadowOverrideSection quick tuning presets appear only in custom mode [E]
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Réglages rapides": []>
00:01 +7 -3: /Users/karim/Project/pokemonProject/packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart: PlacedElementShadowOverrideSection compact preset emits expected custom override values [E]
The finder "Found 0 widgets with text "Petite ombre": []" (used in a call to "tap()") could not find any matching widgets.
00:01 +7 -4: /Users/karim/Project/pokemonProject/packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart: PlacedElementShadowOverrideSection cast presets apply the expected offset directions [E]
The finder "Found 0 widgets with text "Portée bas-droite": []" (used in a call to "tap()") could not find any matching widgets.
00:01 +7 -5: /Users/karim/Project/pokemonProject/packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart: PlacedElementShadowOverrideSection preset preserves a selected custom profile id [E]
The finder "Found 0 widgets with text "Petite ombre": []" (used in a call to "tap()") could not find any matching widgets.
00:01 +7 -5: Some tests failed.
```

### Fixture invalid test corrigé

Après implémentation, un test a échoué car la fixture construisait un `MapPlacedElementShadowOverride.disabled` avec `shadowProfileId`, ce que le modèle interdit déjà.

Sortie utile :

```text
00:00 +3 -1: /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/placed_element_shadow_tuning_presets_test.dart: applyPlacedElementShadowTuningPreset does not inherit a profile id from disabled overrides [E]
  MapPlacedElementShadowOverride.disabled cannot carry custom shadow fields
  package:map_core/src/models/shadow.dart 212:7                                 new MapPlacedElementShadowOverride
  test/application/shadow/placed_element_shadow_tuning_presets_test.dart 57:26  main.<fn>.<fn>
00:01 +16 -1: Some tests failed.
```

Correction : la fixture `disabled` a été rendue valide, sans `shadowProfileId`. Ce problème n'est pas une régression Shadow-25 ; c'était une erreur de test.

### GREEN combiné helper + widget

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow/placed_element_shadow_tuning_presets_test.dart test/features/tileset_library/placed_element_shadow_override_section_test.dart
```

Sortie complète utile :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/placed_element_shadow_tuning_presets_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/placed_element_shadow_tuning_presets_test.dart: createPlacedElementShadowTuningPresets returns stable unique preset ids
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/placed_element_shadow_tuning_presets_test.dart: createPlacedElementShadowTuningPresets keeps every preset within valid numeric ranges
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/placed_element_shadow_tuning_presets_test.dart: applyPlacedElementShadowTuningPreset applies compact footprint values to a null override
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/placed_element_shadow_tuning_presets_test.dart: applyPlacedElementShadowTuningPreset does not inherit a profile id from disabled overrides
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/placed_element_shadow_tuning_presets_test.dart: applyPlacedElementShadowTuningPreset preserves a profile id from custom overrides
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/placed_element_shadow_tuning_presets_test.dart: applyPlacedElementShadowTuningPreset applies exact cast direction values
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart: PlacedElementShadowOverrideSection shows the section title and inherit mode for null override
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart: PlacedElementShadowOverrideSection disabled mode emits a disabled override
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart: PlacedElementShadowOverrideSection custom mode emits custom override and reset emits null
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart: PlacedElementShadowOverrideSection number fields update custom offset scale and opacity
00:01 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart: PlacedElementShadowOverrideSection invalid scale and opacity values do not emit changes
00:01 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart: PlacedElementShadowOverrideSection profile dropdown filters actorContact and none profiles
00:01 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart: PlacedElementShadowOverrideSection empty catalog shows seed action
00:01 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart: PlacedElementShadowOverrideSection quick tuning presets appear only in custom mode
00:01 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart: PlacedElementShadowOverrideSection compact preset emits expected custom override values
00:01 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart: PlacedElementShadowOverrideSection cast presets apply the expected offset directions
00:01 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart: PlacedElementShadowOverrideSection preset preserves a selected custom profile id
00:01 +17: All tests passed!
```

### Test helper dédié

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow/placed_element_shadow_tuning_presets_test.dart
```

Sortie complète utile :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/placed_element_shadow_tuning_presets_test.dart
00:00 +0: createPlacedElementShadowTuningPresets returns stable unique preset ids
00:00 +1: createPlacedElementShadowTuningPresets keeps every preset within valid numeric ranges
00:00 +2: applyPlacedElementShadowTuningPreset applies compact footprint values to a null override
00:00 +3: applyPlacedElementShadowTuningPreset does not inherit a profile id from disabled overrides
00:00 +4: applyPlacedElementShadowTuningPreset preserves a profile id from custom overrides
00:00 +5: applyPlacedElementShadowTuningPreset applies exact cast direction values
00:00 +6: All tests passed!
```

### Test widget dédié

Commande :

```bash
cd packages/map_editor && flutter test test/features/tileset_library/placed_element_shadow_override_section_test.dart
```

Sortie complète utile :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart
00:00 +0: PlacedElementShadowOverrideSection shows the section title and inherit mode for null override
00:00 +1: PlacedElementShadowOverrideSection disabled mode emits a disabled override
00:00 +2: PlacedElementShadowOverrideSection custom mode emits custom override and reset emits null
00:00 +3: PlacedElementShadowOverrideSection number fields update custom offset scale and opacity
00:01 +4: PlacedElementShadowOverrideSection invalid scale and opacity values do not emit changes
00:01 +5: PlacedElementShadowOverrideSection profile dropdown filters actorContact and none profiles
00:01 +6: PlacedElementShadowOverrideSection empty catalog shows seed action
00:01 +7: PlacedElementShadowOverrideSection quick tuning presets appear only in custom mode
00:01 +8: PlacedElementShadowOverrideSection compact preset emits expected custom override values
00:01 +9: PlacedElementShadowOverrideSection cast presets apply the expected offset directions
00:01 +10: PlacedElementShadowOverrideSection preset preserves a selected custom profile id
00:01 +11: All tests passed!
```

## 15. Ligne finale exacte des tests globaux ciblés

### `test/application/shadow`

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow
```

Résultat final exact :

```text
00:00 +48: All tests passed!
```

### `test/features/tileset_library`

Commande :

```bash
cd packages/map_editor && flutter test test/features/tileset_library
```

Résultat final exact :

```text
00:02 +29: All tests passed!
```

### Analyse ciblée

Commande :

```bash
cd packages/map_editor && flutter analyze lib/src/application/shadow lib/src/ui/panels/tileset_palette/widgets/placed_instances test/application/shadow test/features/tileset_library
```

Résultat exact :

```text
No issues found! (ran in 3.7s)
```

## 16. Résultats des scans anti-dérive

### `find .. -name AGENTS.md -print`

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Seul `../pokemonProject/AGENTS.md` s'applique au repo courant.

### Runtime interdit

Commande :

```bash
git diff --name-only | rg -n "packages/map_runtime|packages/map_gameplay|packages/map_battle"
```

Résultat :

```text
aucune sortie
```

### Modèles persistants core interdits

Commande :

```bash
git diff --name-only | rg -n "packages/map_core/lib/src/models"
```

Résultat :

```text
aucune sortie
```

### Renderer / lumière globale interdits

Commande :

```bash
git diff -U0 -- packages/map_editor packages/map_core | rg -n "drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|ShadowLayerComponent|zOrder|zIndex|WorldLightState|ShadowLightProfile|timeOfDay|LightDirection|SunDirection"
```

Résultat :

```text
aucune sortie
```

### Import runtime interdit

Commande :

```bash
git diff -U0 -- packages/map_editor | rg -n "package:map_runtime|map_runtime/src"
```

Résultat :

```text
aucune sortie
```

### `git diff --check`

```text
aucune sortie
```

## 17. git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Résultat initial :

```text
aucune sortie
```

## 18. git status final

Résultat final à jour après création de ce rapport :

```text
 M packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart
 M packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart
?? packages/map_editor/lib/src/application/shadow/placed_element_shadow_tuning_presets.dart
?? packages/map_editor/test/application/shadow/placed_element_shadow_tuning_presets_test.dart
?? reports/shadows/shadow_lot_25_placed_shadow_tuning_presets.md
```

## 19. git diff --stat

Résultat avant création du rapport :

```text
 .../placed_element_shadow_override_section.dart    | 47 +++++++++++
 ...laced_element_shadow_override_section_test.dart | 98 ++++++++++++++++++++++
 2 files changed, 145 insertions(+)
```

Les fichiers créés non suivis sont listés dans `git status final`, car `git diff --stat` ne les inclut pas tant qu'ils ne sont pas indexés.

### `git diff --name-status`

```text
M	packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart
M	packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart
```

## 20. Non-objectifs respectés

- Aucun runtime modifié.
- Aucun modèle persistant modifié.
- Aucun `ProjectElementEntry.shadow` modifié par l'application d'un preset.
- Aucun Shadow Studio créé.
- Aucune direction globale de lumière créée.
- Aucun blur, atlas, renderer avancé, `zOrder` ou `zIndex`.
- Aucun commit pendant l'execution du lot avant la demande explicite post-livraison.

## 21. Risques / réserves

- Les presets V0 sont des raccourcis de valeurs fixes. Ils ne remplacent pas un futur système global de lumière ou une authoring UI avancée.
- Les libellés `Portée bas-droite` / `Portée bas-gauche` restent volontairement présentés comme des presets d'offset, pas comme une simulation physique.
- Le test complet `flutter test` de tout `map_editor` n'a pas été lancé, car le contrat demandait les suites ciblées Shadow/editor concernées.

## 22. Auto-review finale

- Ai-je ajouté des presets de tuning d'ombre d'instance ? oui.
- Ai-je utilisé uniquement `MapPlacedElementShadowOverride` existant ? oui.
- Ai-je évité de modifier les modèles persistants ? oui.
- Ai-je évité de toucher au runtime ? oui.
- Ai-je préservé `shadowProfileId` existant lors d'un preset ? oui, uniquement depuis un override custom.
- Ai-je gardé `scaleX` / `scaleY > 0` ? oui, testé.
- Ai-je gardé `opacity` entre 0 et 1 ? oui, testé.
- Ai-je évité de promettre une vraie direction globale de lumière ? oui.
- Ai-je évité Shadow Studio / preview canvas supplémentaire ? oui.
- Ai-je gardé `ProjectElementEntry.shadow` inchangé ? oui.

## 23. Regard critique sur le prompt

Le prompt est cohérent avec Shadow-23 et Shadow-24 : il cible une amélioration UX rapide sans élargir le modèle ni le runtime. Le point le plus sensible était la règle de conservation du `shadowProfileId`; la décision “conserver seulement depuis custom” évite de propager des données invalides depuis `inherit` ou `disabled`.

Le test initial a révélé que le modèle refuse déjà un `disabled` avec champs custom. Cette contrainte est saine et a conduit à corriger la fixture plutôt qu'à contourner le modèle.

## 24. Contenu complet des fichiers créés/modifiés

### `packages/map_editor/lib/src/application/shadow/placed_element_shadow_tuning_presets.dart`

```dart
import 'package:map_core/map_core.dart';

final class PlacedElementShadowTuningPreset {
  const PlacedElementShadowTuningPreset({
    required this.id,
    required this.label,
    required this.description,
    required this.offsetX,
    required this.offsetY,
    required this.scaleX,
    required this.scaleY,
    required this.opacity,
  });

  final String id;
  final String label;
  final String description;
  final double offsetX;
  final double offsetY;
  final double scaleX;
  final double scaleY;
  final double opacity;
}

List<PlacedElementShadowTuningPreset> createPlacedElementShadowTuningPresets() {
  return const [
    PlacedElementShadowTuningPreset(
      id: 'compact-footprint',
      label: 'Petite ombre',
      description: 'Réduit fortement l’emprise au sol.',
      offsetX: 0,
      offsetY: 2,
      scaleX: 0.65,
      scaleY: 0.45,
      opacity: 0.24,
    ),
    PlacedElementShadowTuningPreset(
      id: 'soft-wide-footprint',
      label: 'Ombre large douce',
      description: 'Plus large, plus discrète, utile pour les objets bas.',
      offsetX: 0,
      offsetY: 3,
      scaleX: 1.15,
      scaleY: 0.60,
      opacity: 0.22,
    ),
    PlacedElementShadowTuningPreset(
      id: 'subtle-footprint',
      label: 'Ombre discrète',
      description: 'Ombre légère pour les petits props.',
      offsetX: 0,
      offsetY: 2,
      scaleX: 0.75,
      scaleY: 0.35,
      opacity: 0.14,
    ),
    PlacedElementShadowTuningPreset(
      id: 'cast-bottom-right',
      label: 'Portée bas-droite',
      description: 'Simule une lumière venant du haut-gauche.',
      offsetX: 6,
      offsetY: 5,
      scaleX: 0.85,
      scaleY: 0.45,
      opacity: 0.26,
    ),
    PlacedElementShadowTuningPreset(
      id: 'cast-bottom-left',
      label: 'Portée bas-gauche',
      description: 'Simule une lumière venant du haut-droite.',
      offsetX: -6,
      offsetY: 5,
      scaleX: 0.85,
      scaleY: 0.45,
      opacity: 0.26,
    ),
  ];
}

MapPlacedElementShadowOverride applyPlacedElementShadowTuningPreset({
  required PlacedElementShadowTuningPreset preset,
  MapPlacedElementShadowOverride? currentOverride,
}) {
  final shadowProfileId = currentOverride?.mode == ShadowOverrideMode.custom
      ? currentOverride?.shadowProfileId
      : null;
  return MapPlacedElementShadowOverride(
    mode: ShadowOverrideMode.custom,
    shadowProfileId: shadowProfileId,
    offsetX: preset.offsetX,
    offsetY: preset.offsetY,
    scaleX: preset.scaleX,
    scaleY: preset.scaleY,
    opacity: preset.opacity,
  );
}
```

### `packages/map_editor/test/application/shadow/placed_element_shadow_tuning_presets_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/placed_element_shadow_tuning_presets.dart';

void main() {
  group('createPlacedElementShadowTuningPresets', () {
    test('returns stable unique preset ids', () {
      final presets = createPlacedElementShadowTuningPresets();

      expect(presets.map((preset) => preset.id), [
        'compact-footprint',
        'soft-wide-footprint',
        'subtle-footprint',
        'cast-bottom-right',
        'cast-bottom-left',
      ]);
      expect(
        presets.map((preset) => preset.id).toSet(),
        hasLength(presets.length),
      );
    });

    test('keeps every preset within valid numeric ranges', () {
      final presets = createPlacedElementShadowTuningPresets();

      for (final preset in presets) {
        expect(preset.scaleX, greaterThan(0), reason: preset.id);
        expect(preset.scaleY, greaterThan(0), reason: preset.id);
        expect(preset.opacity, inInclusiveRange(0, 1), reason: preset.id);
      }
    });
  });

  group('applyPlacedElementShadowTuningPreset', () {
    test('applies compact footprint values to a null override', () {
      final preset = _preset('compact-footprint');

      final override = applyPlacedElementShadowTuningPreset(
        preset: preset,
        currentOverride: null,
      );

      expect(override.mode, ShadowOverrideMode.custom);
      expect(override.shadowProfileId, isNull);
      expect(override.offsetX, 0);
      expect(override.offsetY, 2);
      expect(override.scaleX, 0.65);
      expect(override.scaleY, 0.45);
      expect(override.opacity, 0.24);
    });

    test('does not inherit a profile id from disabled overrides', () {
      final preset = _preset('compact-footprint');

      final override = applyPlacedElementShadowTuningPreset(
        preset: preset,
        currentOverride: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.disabled,
        ),
      );

      expect(override.mode, ShadowOverrideMode.custom);
      expect(override.shadowProfileId, isNull);
    });

    test('preserves a profile id from custom overrides', () {
      final preset = _preset('compact-footprint');

      final override = applyPlacedElementShadowTuningPreset(
        preset: preset,
        currentOverride: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
          shadowProfileId: 'wide_shadow',
          offsetX: 99,
          offsetY: 99,
          scaleX: 2,
          scaleY: 2,
          opacity: 1,
        ),
      );

      expect(override.mode, ShadowOverrideMode.custom);
      expect(override.shadowProfileId, 'wide_shadow');
      expect(override.offsetX, preset.offsetX);
      expect(override.offsetY, preset.offsetY);
      expect(override.scaleX, preset.scaleX);
      expect(override.scaleY, preset.scaleY);
      expect(override.opacity, preset.opacity);
    });

    test('applies exact cast direction values', () {
      final bottomRight = applyPlacedElementShadowTuningPreset(
        preset: _preset('cast-bottom-right'),
        currentOverride: null,
      );
      final bottomLeft = applyPlacedElementShadowTuningPreset(
        preset: _preset('cast-bottom-left'),
        currentOverride: null,
      );

      expect(bottomRight.offsetX, 6);
      expect(bottomRight.offsetY, 5);
      expect(bottomRight.scaleX, 0.85);
      expect(bottomRight.scaleY, 0.45);
      expect(bottomRight.opacity, 0.26);

      expect(bottomLeft.offsetX, -6);
      expect(bottomLeft.offsetY, 5);
      expect(bottomLeft.scaleX, 0.85);
      expect(bottomLeft.scaleY, 0.45);
      expect(bottomLeft.opacity, 0.26);
    });
  });
}

PlacedElementShadowTuningPreset _preset(String id) {
  return createPlacedElementShadowTuningPresets().singleWhere(
    (preset) => preset.id == id,
  );
}
```

### Sections modifiées de `PlacedElementShadowOverrideSection`

```diff
diff --git a/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart b/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart
index 0858d43c..1d8e307a 100644
--- a/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart
+++ b/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart
@@ -5,6 +5,7 @@ import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
 import 'package:map_editor/src/application/shadow/element_shadow_read_model.dart';
 import 'package:map_editor/src/application/shadow/placed_element_shadow_override_read_model.dart';
+import 'package:map_editor/src/application/shadow/placed_element_shadow_tuning_presets.dart';
 import 'package:map_editor/src/ui/shared/cupertino_editor_widgets.dart';
 
 class PlacedElementShadowOverrideSection extends StatefulWidget {
@@ -178,6 +179,8 @@ class _PlacedElementShadowOverrideSectionState
               selectedProfileId: readModel.selectedProfileId,
             ),
             const SizedBox(height: 10),
+            _quickTuningPresets(context),
+            const SizedBox(height: 10),
             _numberGrid(context),
           ],
           if (widget.shadowOverride != null) ...[
@@ -268,6 +271,40 @@ class _PlacedElementShadowOverrideSectionState
     );
   }
 
+  Widget _quickTuningPresets(BuildContext context) {
+    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
+    final presets = createPlacedElementShadowTuningPresets();
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.start,
+      children: [
+        Text(
+          'Réglages rapides',
+          style: TextStyle(color: secondary, fontSize: 10),
+        ),
+        const SizedBox(height: 4),
+        Text(
+          'Applique des réglages rapides à cette instance. Vous pouvez ensuite affiner les valeurs manuellement.',
+          style: TextStyle(color: secondary, fontSize: 10),
+        ),
+        const SizedBox(height: 6),
+        Wrap(
+          spacing: 6,
+          runSpacing: 6,
+          children: [
+            for (final preset in presets)
+              PushButton(
+                key: ValueKey('placed-shadow-preset-${preset.id}-button'),
+                controlSize: ControlSize.small,
+                secondary: true,
+                onPressed: () => _applyTuningPreset(preset),
+                child: Text(preset.label),
+              ),
+          ],
+        ),
+      ],
+    );
+  }
+
   Widget _numberGrid(BuildContext context) {
     return Column(
       children: [
@@ -386,6 +423,16 @@ class _PlacedElementShadowOverrideSectionState
     );
   }
 
+  void _applyTuningPreset(PlacedElementShadowTuningPreset preset) {
+    setState(_errors.clear);
+    widget.onChanged(
+      applyPlacedElementShadowTuningPreset(
+        preset: preset,
+        currentOverride: widget.shadowOverride,
+      ),
+    );
+  }
+
   double? _parseNumber(_PlacedShadowNumberField field, String rawValue) {
     final trimmed = rawValue.trim();
     if (trimmed.isEmpty) {
```

### Sections modifiées de `placed_element_shadow_override_section_test.dart`

```diff
diff --git a/packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart b/packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart
index 41518405..d5618c9e 100644
--- a/packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart
+++ b/packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart
@@ -151,6 +151,104 @@ void main() {
 
       expect(harness.seedCount, 1);
     });
+
+    testWidgets('quick tuning presets appear only in custom mode',
+        (tester) async {
+      final inheritHarness = _Harness();
+      await _pumpSection(tester, harness: inheritHarness);
+
+      expect(find.text('Réglages rapides'), findsNothing);
+
+      final customHarness = _Harness(
+        value: MapPlacedElementShadowOverride(
+          mode: ShadowOverrideMode.custom,
+        ),
+      );
+      await _pumpSection(tester, harness: customHarness);
+
+      expect(find.text('Réglages rapides'), findsOneWidget);
+      expect(find.text('Petite ombre'), findsOneWidget);
+      expect(find.text('Portée bas-droite'), findsOneWidget);
+      expect(find.text('Portée bas-gauche'), findsOneWidget);
+    });
+
+    testWidgets('compact preset emits expected custom override values',
+        (tester) async {
+      final harness = _Harness(
+        value: MapPlacedElementShadowOverride(
+          mode: ShadowOverrideMode.custom,
+        ),
+      );
+      await _pumpSection(tester, harness: harness);
+
+      await tester.tap(find.text('Petite ombre'));
+      await tester.pump();
+
+      expect(harness.value!.mode, ShadowOverrideMode.custom);
+      expect(harness.value!.shadowProfileId, isNull);
+      expect(harness.value!.offsetX, 0);
+      expect(harness.value!.offsetY, 2);
+      expect(harness.value!.scaleX, 0.65);
+      expect(harness.value!.scaleY, 0.45);
+      expect(harness.value!.opacity, 0.24);
+      expect(
+        tester
+            .widget<MacosTextField>(
+              find.byKey(const ValueKey('placed-shadow-offsetY-field')),
+            )
+            .controller!
+            .text,
+        '2.0',
+      );
+      expect(
+        tester
+            .widget<MacosTextField>(
+              find.byKey(const ValueKey('placed-shadow-scaleX-field')),
+            )
+            .controller!
+            .text,
+        '0.65',
+      );
+    });
+
+    testWidgets('cast presets apply the expected offset directions',
+        (tester) async {
+      final harness = _Harness(
+        value: MapPlacedElementShadowOverride(
+          mode: ShadowOverrideMode.custom,
+        ),
+      );
+      await _pumpSection(tester, harness: harness);
+
+      await tester.tap(find.text('Portée bas-droite'));
+      await tester.pump();
+
+      expect(harness.value!.offsetX, greaterThan(0));
+      expect(harness.value!.offsetY, greaterThan(0));
+
+      await tester.tap(find.text('Portée bas-gauche'));
+      await tester.pump();
+
+      expect(harness.value!.offsetX, lessThan(0));
+      expect(harness.value!.offsetY, greaterThan(0));
+    });
+
+    testWidgets('preset preserves a selected custom profile id',
+        (tester) async {
+      final harness = _Harness(
+        value: MapPlacedElementShadowOverride(
+          mode: ShadowOverrideMode.custom,
+          shadowProfileId: 'wide_shadow',
+        ),
+      );
+      await _pumpSection(tester, harness: harness);
+
+      await tester.tap(find.text('Petite ombre'));
+      await tester.pump();
+
+      expect(harness.value!.mode, ShadowOverrideMode.custom);
+      expect(harness.value!.shadowProfileId, 'wide_shadow');
+    });
   });
 }
```

## 25. Diffs complets ou équivalents /dev/null pour fichiers créés

### Nouveau helper

```diff
diff --git a/packages/map_editor/lib/src/application/shadow/placed_element_shadow_tuning_presets.dart b/packages/map_editor/lib/src/application/shadow/placed_element_shadow_tuning_presets.dart
new file mode 100644
index 00000000..24f38ad1
--- /dev/null
+++ b/packages/map_editor/lib/src/application/shadow/placed_element_shadow_tuning_presets.dart
@@ -0,0 +1,96 @@
+import 'package:map_core/map_core.dart';
+
+final class PlacedElementShadowTuningPreset {
+  const PlacedElementShadowTuningPreset({
+    required this.id,
+    required this.label,
+    required this.description,
+    required this.offsetX,
+    required this.offsetY,
+    required this.scaleX,
+    required this.scaleY,
+    required this.opacity,
+  });
+
+  final String id;
+  final String label;
+  final String description;
+  final double offsetX;
+  final double offsetY;
+  final double scaleX;
+  final double scaleY;
+  final double opacity;
+}
+
+List<PlacedElementShadowTuningPreset> createPlacedElementShadowTuningPresets() {
+  return const [
+    PlacedElementShadowTuningPreset(
+      id: 'compact-footprint',
+      label: 'Petite ombre',
+      description: 'Réduit fortement l’emprise au sol.',
+      offsetX: 0,
+      offsetY: 2,
+      scaleX: 0.65,
+      scaleY: 0.45,
+      opacity: 0.24,
+    ),
+    PlacedElementShadowTuningPreset(
+      id: 'soft-wide-footprint',
+      label: 'Ombre large douce',
+      description: 'Plus large, plus discrète, utile pour les objets bas.',
+      offsetX: 0,
+      offsetY: 3,
+      scaleX: 1.15,
+      scaleY: 0.60,
+      opacity: 0.22,
+    ),
+    PlacedElementShadowTuningPreset(
+      id: 'subtle-footprint',
+      label: 'Ombre discrète',
+      description: 'Ombre légère pour les petits props.',
+      offsetX: 0,
+      offsetY: 2,
+      scaleX: 0.75,
+      scaleY: 0.35,
+      opacity: 0.14,
+    ),
+    PlacedElementShadowTuningPreset(
+      id: 'cast-bottom-right',
+      label: 'Portée bas-droite',
+      description: 'Simule une lumière venant du haut-gauche.',
+      offsetX: 6,
+      offsetY: 5,
+      scaleX: 0.85,
+      scaleY: 0.45,
+      opacity: 0.26,
+    ),
+    PlacedElementShadowTuningPreset(
+      id: 'cast-bottom-left',
+      label: 'Portée bas-gauche',
+      description: 'Simule une lumière venant du haut-droite.',
+      offsetX: -6,
+      offsetY: 5,
+      scaleX: 0.85,
+      scaleY: 0.45,
+      opacity: 0.26,
+    ),
+  ];
+}
+
+MapPlacedElementShadowOverride applyPlacedElementShadowTuningPreset({
+  required PlacedElementShadowTuningPreset preset,
+  MapPlacedElementShadowOverride? currentOverride,
+}) {
+  final shadowProfileId = currentOverride?.mode == ShadowOverrideMode.custom
+      ? currentOverride?.shadowProfileId
+      : null;
+  return MapPlacedElementShadowOverride(
+    mode: ShadowOverrideMode.custom,
+    shadowProfileId: shadowProfileId,
+    offsetX: preset.offsetX,
+    offsetY: preset.offsetY,
+    scaleX: preset.scaleX,
+    scaleY: preset.scaleY,
+    opacity: preset.opacity,
+  );
+}
```

### Nouveau test helper

```diff
diff --git a/packages/map_editor/test/application/shadow/placed_element_shadow_tuning_presets_test.dart b/packages/map_editor/test/application/shadow/placed_element_shadow_tuning_presets_test.dart
new file mode 100644
index 00000000..95a8e931
--- /dev/null
+++ b/packages/map_editor/test/application/shadow/placed_element_shadow_tuning_presets_test.dart
@@ -0,0 +1,120 @@
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/application/shadow/placed_element_shadow_tuning_presets.dart';
+
+void main() {
+  group('createPlacedElementShadowTuningPresets', () {
+    test('returns stable unique preset ids', () {
+      final presets = createPlacedElementShadowTuningPresets();
+
+      expect(presets.map((preset) => preset.id), [
+        'compact-footprint',
+        'soft-wide-footprint',
+        'subtle-footprint',
+        'cast-bottom-right',
+        'cast-bottom-left',
+      ]);
+      expect(
+        presets.map((preset) => preset.id).toSet(),
+        hasLength(presets.length),
+      );
+    });
+
+    test('keeps every preset within valid numeric ranges', () {
+      final presets = createPlacedElementShadowTuningPresets();
+
+      for (final preset in presets) {
+        expect(preset.scaleX, greaterThan(0), reason: preset.id);
+        expect(preset.scaleY, greaterThan(0), reason: preset.id);
+        expect(preset.opacity, inInclusiveRange(0, 1), reason: preset.id);
+      }
+    });
+  });
+
+  group('applyPlacedElementShadowTuningPreset', () {
+    test('applies compact footprint values to a null override', () {
+      final preset = _preset('compact-footprint');
+
+      final override = applyPlacedElementShadowTuningPreset(
+        preset: preset,
+        currentOverride: null,
+      );
+
+      expect(override.mode, ShadowOverrideMode.custom);
+      expect(override.shadowProfileId, isNull);
+      expect(override.offsetX, 0);
+      expect(override.offsetY, 2);
+      expect(override.scaleX, 0.65);
+      expect(override.scaleY, 0.45);
+      expect(override.opacity, 0.24);
+    });
+
+    test('does not inherit a profile id from disabled overrides', () {
+      final preset = _preset('compact-footprint');
+
+      final override = applyPlacedElementShadowTuningPreset(
+        preset: preset,
+        currentOverride: MapPlacedElementShadowOverride(
+          mode: ShadowOverrideMode.disabled,
+        ),
+      );
+
+      expect(override.mode, ShadowOverrideMode.custom);
+      expect(override.shadowProfileId, isNull);
+    });
+
+    test('preserves a profile id from custom overrides', () {
+      final preset = _preset('compact-footprint');
+
+      final override = applyPlacedElementShadowTuningPreset(
+        preset: preset,
+        currentOverride: MapPlacedElementShadowOverride(
+          mode: ShadowOverrideMode.custom,
+          shadowProfileId: 'wide_shadow',
+          offsetX: 99,
+          offsetY: 99,
+          scaleX: 2,
+          scaleY: 2,
+          opacity: 1,
+        ),
+      );
+
+      expect(override.mode, ShadowOverrideMode.custom);
+      expect(override.shadowProfileId, 'wide_shadow');
+      expect(override.offsetX, preset.offsetX);
+      expect(override.offsetY, preset.offsetY);
+      expect(override.scaleX, preset.scaleX);
+      expect(override.scaleY, preset.scaleY);
+      expect(override.opacity, preset.opacity);
+    });
+
+    test('applies exact cast direction values', () {
+      final bottomRight = applyPlacedElementShadowTuningPreset(
+        preset: _preset('cast-bottom-right'),
+        currentOverride: null,
+      );
+      final bottomLeft = applyPlacedElementShadowTuningPreset(
+        preset: _preset('cast-bottom-left'),
+        currentOverride: null,
+      );
+
+      expect(bottomRight.offsetX, 6);
+      expect(bottomRight.offsetY, 5);
+      expect(bottomRight.scaleX, 0.85);
+      expect(bottomRight.scaleY, 0.45);
+      expect(bottomRight.opacity, 0.26);
+
+      expect(bottomLeft.offsetX, -6);
+      expect(bottomLeft.offsetY, 5);
+      expect(bottomLeft.scaleX, 0.85);
+      expect(bottomLeft.scaleY, 0.45);
+      expect(bottomLeft.opacity, 0.26);
+    });
+  });
+}
+
+PlacedElementShadowTuningPreset _preset(String id) {
+  return createPlacedElementShadowTuningPresets().singleWhere(
+    (preset) => preset.id == id,
+  );
+}
```
