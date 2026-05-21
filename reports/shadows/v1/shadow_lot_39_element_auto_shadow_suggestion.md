# Shadow-39 — Element Auto Shadow Suggestion V0

## 1. Résumé

Shadow-39 ajoute une suggestion automatique editor-only pour configurer une ombre d’élément source à partir de la taille de sa première frame visuelle.

Le lot ajoute :

- un helper `buildElementAutoShadowSuggestion(...)` dans `map_editor`;
- une classification V0 des éléments : `tallThin`, `buildingLarge`, `wideLow`, `smallSquare`, `defaultProp`;
- un bouton `Calculer automatiquement` dans `ElementShadowSection`;
- une activation automatique quand l’utilisateur active `Projette une ombre` depuis une config `null`;
- des tests helper et widget.

Ce lot ne modifie pas le runtime, les modèles persistants, les codecs JSON, le canvas, l’état editor, la géométrie core, ni les fichiers générés.

## 2. Design retenu

La suggestion automatique reste dans `map_editor/src/application/shadow`, car elle est une aide d’authoring et non une règle runtime ou un contrat persistant.

Le helper lit uniquement :

- `ProjectElementEntry.frames.first.source.width`;
- `ProjectElementEntry.frames.first.source.height`;
- `ProjectShadowCatalog`.

Il retourne une `ProjectElementShadowConfig` complète avec des champs déjà existants :

- `castsShadow`;
- `shadowProfileId`;
- `offsetX`;
- `offsetY`;
- `scaleX`;
- `scaleY`;
- `opacity`;
- `footprint`.

## 3. Fichiers créés par Shadow-39

- `packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart`
- `packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart`
- `reports/shadows/shadow_lot_39_element_auto_shadow_suggestion.md`

## 4. Fichiers modifiés par Shadow-39

- `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart`
- `packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart`

## 5. Fichiers déjà modifiés ou non suivis avant Shadow-39

Déjà modifiés avant l’implémentation Shadow-39 :

```text
 M AGENTS.md
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
```

Déjà non suivis avant l’implémentation Shadow-39 :

```text
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview.md
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview_plan.md
?? reports/shadows/shadow_lot_39_element_auto_shadow_suggestion_plan.md
```

## 6. Fichiers non modifiés explicitement

Shadow-39 ne modifie pas :

- `packages/map_runtime/**`
- `packages/map_gameplay/**`
- `packages/map_battle/**`
- `packages/map_core/lib/src/models/**`
- `packages/map_core/lib/src/operations/*json_codec.dart`
- `packages/map_editor/lib/src/ui/canvas/**`
- `packages/map_editor/lib/src/features/editor/state/**`

Le scan global canvas montre des lignes préexistantes venant de Shadow-38, pas de Shadow-39.

## 7. Helper API

API ajoutée :

```dart
enum ElementAutoShadowSuggestionKind {
  tallThin,
  buildingLarge,
  wideLow,
  smallSquare,
  defaultProp,
}

final class ElementAutoShadowSuggestion {
  const ElementAutoShadowSuggestion({
    required this.kind,
    required this.config,
    required this.summary,
  });

  final ElementAutoShadowSuggestionKind kind;
  final ProjectElementShadowConfig config;
  final String summary;
}

ElementAutoShadowSuggestion? buildElementAutoShadowSuggestion({
  required ProjectElementEntry element,
  required ProjectShadowCatalog shadowCatalog,
});
```

Le helper retourne `null` si :

- l’élément n’a pas de frame;
- la première frame a une largeur ou une hauteur invalide;
- aucun profil compatible `groundStatic` n’existe.

## 8. Règles de classification

Ordre appliqué :

```text
tallThin:
  aspect >= 2.2 && width <= 2

buildingLarge:
  width >= 4 || area >= 12

wideLow:
  width >= 3 && height <= 3

smallSquare:
  area <= 4

defaultProp:
  tous les autres éléments valides
```

L’ordre est volontaire : les éléments fins et hauts sont classés avant les gros éléments, pour éviter qu’un lampadaire devienne un bâtiment.

## 9. Valeurs suggérées

`tallThin` :

```text
profile: default-ground-contact-blob ou fallback compatible
offsetX: 0
offsetY: 0
scaleX: 1
scaleY: 1
opacity: 0.28
footprint: anchorX 0.5, anchorY 1.0, width 0.18, height 0.07
```

`buildingLarge` :

```text
profile: default-ground-wide-ellipse ou fallback compatible
offsetX: 0
offsetY: 0
scaleX: 1
scaleY: 0.85
opacity: 0.30
footprint: anchorX 0.5, anchorY 0.92, width 0.82, height 0.12
```

`wideLow` :

```text
profile: default-ground-wide-ellipse ou fallback compatible
offsetX: 0
offsetY: 0
scaleX: 0.92
scaleY: 0.75
opacity: 0.27
footprint: anchorX 0.5, anchorY 0.95, width 0.72, height 0.10
```

`smallSquare` :

```text
profile: default-ground-contact-blob ou fallback compatible
offsetX: 0
offsetY: 0
scaleX: 0.78
scaleY: 0.70
opacity: 0.26
footprint: anchorX 0.5, anchorY 0.96, width 0.46, height 0.10
```

`defaultProp` :

```text
profile: default-ground-soft-ellipse ou fallback compatible
offsetX: 0
offsetY: 0
scaleX: 0.90
scaleY: 0.80
opacity: 0.28
footprint: anchorX 0.5, anchorY 0.95, width 0.62, height 0.12
```

## 10. UI action

`ElementShadowSection` affiche `Calculer automatiquement` après le picker `Profil` quand une suggestion existe.

Le bouton :

- remplace explicitement la config courante par la suggestion;
- nettoie les erreurs de champs numériques et footprint;
- affiche un message court du type `Ombre automatique : grand bâtiment.`

## 11. Activation behavior

Quand `shadow == null` et que l’utilisateur active `Projette une ombre`, `ElementShadowSection` tente d’appliquer la suggestion automatique.

Si aucune suggestion n’est disponible, le comportement existant est conservé : création d’une config active avec le premier profil compatible et sans footprint.

## 12. Règles de conservation

Les mutations manuelles existantes restent conservatrices :

- `_setCastsShadow(false)` préserve la config existante;
- `_setProfile(...)` préserve `footprint`;
- `_setNumber(...)` préserve `footprint`;
- `_setFootprintNumber(...)` préserve `shadowProfileId`, `offsetX`, `offsetY`, `scaleX`, `scaleY`, `opacity`.

L’action `Calculer automatiquement` est différente : elle remplace volontairement les valeurs courantes par une nouvelle suggestion complète.

## 13. Tests ajoutés ou modifiés

Ajout :

- `packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart`

Modification :

- `packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart`

Couverture ajoutée :

- absence de suggestion sans profil compatible;
- absence de suggestion sans frame ou avec frame invalide;
- classification des cinq catégories;
- priorité des profils par défaut;
- fallback sur profils custom compatibles;
- validité des footprints, scales et opacités;
- activation depuis `null`;
- fallback depuis `null` quand la suggestion est indisponible;
- présence du bouton;
- application explicite du bouton sur une config active;
- absence du bouton sans profil compatible;
- conservation du footprint après changement de profil.

## 14. Commandes lancées

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
```

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_suggestion_test.dart
cd packages/map_editor && flutter test test/features/tileset_library/element_shadow_section_test.dart
cd packages/map_editor && dart format lib/src/application/shadow/element_auto_shadow_suggestion.dart test/application/shadow/element_auto_shadow_suggestion_test.dart lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart test/features/tileset_library/element_shadow_section_test.dart
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_suggestion_test.dart
cd packages/map_editor && flutter test test/features/tileset_library/element_shadow_section_test.dart
cd packages/map_editor && flutter test test/application/shadow
cd packages/map_editor && flutter test test/features/tileset_library
cd packages/map_editor && flutter analyze lib/src/application/shadow lib/src/ui/panels/tileset_palette/widgets/shadow test/application/shadow test/features/tileset_library
cd packages/map_core && dart test test/shadow/static_shadow_footprint_config_test.dart
cd packages/map_core && dart test test/shadow/static_shadow_geometry_test.dart
cd packages/map_core && dart analyze lib test/shadow
```

```bash
git diff --name-only | rg -n "packages/map_runtime|packages/map_gameplay|packages/map_battle"
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
git diff --name-only | rg -n "packages/map_editor/lib/src/ui/canvas|packages/map_editor/lib/src/features/editor/state"
git diff -U0 -- packages/map_editor packages/map_core | rg -n "Canvas|drawOval|drawPath|drawImageRect|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
git diff -U0 -- packages/map_editor | rg -n "package:map_runtime|map_runtime/src"
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

## 15. Résultats complets des tests ciblés

### Helper RED

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_suggestion_test.dart
```

Résultat attendu avant implémentation : compilation impossible car le fichier de production n’existe pas.

Sortie utile :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
test/application/shadow/element_auto_shadow_suggestion_test.dart:3:8: Error: Error when reading 'lib/src/application/shadow/element_auto_shadow_suggestion.dart': No such file or directory
import 'package:map_editor/src/application/shadow/element_auto_shadow_suggestion.dart';
       ^
test/application/shadow/element_auto_shadow_suggestion_test.dart:196:10: Error: Type 'ElementAutoShadowSuggestion' not found.
Iterable<ElementAutoShadowSuggestion> _allSuggestionKinds() sync* {
         ^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/application/shadow/element_auto_shadow_suggestion_test.dart:8:26: Error: Method not found: 'buildElementAutoShadowSuggestion'.
      final suggestion = buildElementAutoShadowSuggestion(
                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
00:00 +0 -1: Some tests failed.
```

### Helper GREEN

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_suggestion_test.dart
```

Sortie complète utile :

```text
00:00 +0: buildElementAutoShadowSuggestion returns null without compatible ground static profile
00:00 +1: buildElementAutoShadowSuggestion returns null for missing frames
00:00 +2: buildElementAutoShadowSuggestion returns null for invalid first frame source
00:00 +3: buildElementAutoShadowSuggestion classifies tall thin elements as tallThin
00:00 +4: buildElementAutoShadowSuggestion classifies large buildings as buildingLarge
00:00 +5: buildElementAutoShadowSuggestion classifies wide low elements as wideLow
00:00 +6: buildElementAutoShadowSuggestion classifies small square elements as smallSquare
00:00 +7: buildElementAutoShadowSuggestion classifies remaining valid elements as defaultProp
00:00 +8: buildElementAutoShadowSuggestion prefers default compact profile for tallThin
00:00 +9: buildElementAutoShadowSuggestion falls back to custom compatible profile ids
00:00 +10: buildElementAutoShadowSuggestion all suggestions have castsShadow true
00:00 +11: buildElementAutoShadowSuggestion all suggestion footprints are non-null and valid
00:00 +12: buildElementAutoShadowSuggestion all suggestion opacities are within 0..1
00:00 +13: buildElementAutoShadowSuggestion all suggestion scaleX and scaleY are greater than zero
00:00 +14: All tests passed!
```

### Widget RED

Commande :

```bash
cd packages/map_editor && flutter test test/features/tileset_library/element_shadow_section_test.dart
```

Sortie utile avant implémentation widget :

```text
00:00 +6: ElementShadowSection activating from null applies an auto suggestion
Expected: 'default-ground-contact-blob'
  Actual: 'default-ground-soft-ellipse'
00:01 +7 -2: ElementShadowSection auto calculate button is visible with a compatible profile [E]
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Calculer automatiquement": []>
00:01 +7 -3: ElementShadowSection auto calculate button applies suggestion to active config [E]
The finder "Found 0 widgets with key [<'element-shadow-auto-suggestion-button'>]: []" could not find any matching widgets.
00:03 +23 -3: Some tests failed.
```

### Widget GREEN

Commande :

```bash
cd packages/map_editor && flutter test test/features/tileset_library/element_shadow_section_test.dart
```

Sortie complète utile :

```text
00:00 +0: ElementShadowSection is inserted before the collision summary in Edit Element
00:00 +1: ElementShadowSection shows not configured state for a null shadow config
00:00 +2: ElementShadowSection shows seed action when the catalog has no compatible profiles
00:00 +3: ElementShadowSection actorContact-only catalog is treated as no compatible profile
00:00 +4: ElementShadowSection none-only catalog is treated as no compatible profile
00:00 +5: ElementShadowSection after seed the default profiles appear in the dropdown
00:00 +6: ElementShadowSection activating from null applies an auto suggestion
00:00 +7: ElementShadowSection activating from null falls back to first profile when suggestion is unavailable
00:00 +8: ElementShadowSection auto calculate button is visible with a compatible profile
00:00 +9: ElementShadowSection auto calculate button applies suggestion to active config
00:01 +10: ElementShadowSection auto calculate button is absent without compatible profile
00:01 +11: ElementShadowSection changing profile after auto suggestion preserves footprint
00:01 +12: ElementShadowSection disabling preserves the selected profile and overrides
00:01 +13: ElementShadowSection reset clears the shadow config instead of disabling it
00:01 +14: ElementShadowSection changing profile updates shadowProfileId
00:01 +15: ElementShadowSection numeric fields update and clear nullable overrides
00:01 +16: ElementShadowSection invalid scale and opacity values are rejected
00:01 +17: ElementShadowSection footprint block is visible only for active shadows
00:01 +18: ElementShadowSection footprint null and partial values sync text fields
00:02 +19: ElementShadowSection footprint fields update ratios and preserve shadow fields
00:02 +20: ElementShadowSection invalid footprint values show errors and do not emit changes
00:02 +21: ElementShadowSection reset and clearing the last footprint field write null
00:02 +22: ElementShadowSection existing profile toggle and number changes preserve footprint
00:02 +23: ElementShadowSection missing profile is shown as a diagnostic
00:02 +24: ElementShadowSection profile none is informational and not an error
00:02 +25: ElementShadowSection forbidden V0 fields are not rendered
00:02 +26: All tests passed!
```

## 16. Lignes finales exactes des tests globaux ciblés

```text
cd packages/map_editor && flutter test test/application/shadow
00:00 +77: All tests passed!
```

```text
cd packages/map_editor && flutter test test/features/tileset_library
00:03 +45: All tests passed!
```

```text
cd packages/map_editor && flutter analyze lib/src/application/shadow lib/src/ui/panels/tileset_palette/widgets/shadow test/application/shadow test/features/tileset_library
No issues found! (ran in 1.8s)
```

```text
cd packages/map_core && dart test test/shadow/static_shadow_footprint_config_test.dart
00:00 +6: All tests passed!
```

```text
cd packages/map_core && dart test test/shadow/static_shadow_geometry_test.dart
00:00 +19: All tests passed!
```

```text
cd packages/map_core && dart analyze lib test/shadow
No issues found!
```

## 17. Résultats des scans anti-dérive

```bash
git diff --name-only | rg -n "packages/map_runtime|packages/map_gameplay|packages/map_battle"
```

```text
aucune sortie
```

```bash
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
```

```text
aucune sortie
```

```bash
git diff --name-only | rg -n "packages/map_editor/lib/src/ui/canvas|packages/map_editor/lib/src/features/editor/state"
```

```text
3:packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
```

Interprétation : cette sortie vient des changements Shadow-38 préexistants avant Shadow-39.

```bash
git diff -U0 -- packages/map_editor packages/map_core | rg -n "Canvas|drawOval|drawPath|drawImageRect|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
```

```text
315:-    canvas.drawOval(
333:+        canvas.drawOval(
347:+          canvas.drawPath(path, paint);
```

Interprétation : ces lignes appartiennent au painter Shadow-38 préexistant. Le scan limité aux fichiers Shadow-39 ne sort rien.

```bash
git diff -U0 -- packages/map_editor | rg -n "package:map_runtime|map_runtime/src"
```

```text
aucune sortie
```

```bash
git diff -U0 -- packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart | rg -n "Canvas|drawOval|drawPath|drawImageRect|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas|package:map_runtime|map_runtime/src"
```

```text
aucune sortie
```

```bash
git diff --check
```

```text
aucune sortie
```

## 18. git status initial

```text
 M AGENTS.md
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview.md
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview_plan.md
?? reports/shadows/shadow_lot_39_element_auto_shadow_suggestion_plan.md
```

## 19. git status final attendu après création de ce rapport

```text
 M AGENTS.md
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
 M packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart
 M packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
?? packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart
?? packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview.md
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview_plan.md
?? reports/shadows/shadow_lot_39_element_auto_shadow_suggestion.md
?? reports/shadows/shadow_lot_39_element_auto_shadow_suggestion_plan.md
```

## 20. git diff --stat

```text
 AGENTS.md                                          | 1289 ++++++++++++--------
 .../shadow/editor_static_shadow_preview.dart       |  285 ++++-
 .../editor_static_shadow_preview_painter.dart      |   54 +-
 .../widgets/shadow/element_shadow_section.dart     |   39 +
 .../shadow/editor_static_shadow_preview_test.dart  |  390 +++++-
 .../element_shadow_section_test.dart               |  163 ++-
 .../editor_static_shadow_preview_painter_test.dart |   69 +-
 7 files changed, 1630 insertions(+), 659 deletions(-)
```

Les fichiers non suivis Shadow-39 ne sont pas comptés par `git diff --stat`.

## 21. Non-objectifs respectés

- Aucun runtime modifié par Shadow-39.
- Aucun modèle persistant modifié.
- Aucun codec JSON modifié.
- Aucun fichier generated modifié.
- Aucun canvas ou painter modifié par Shadow-39.
- Aucun état editor modifié.
- Aucun `build_runner`.
- Aucune nouvelle lumière globale.
- Aucun import `map_runtime` dans `map_editor`.

## 22. Risques et limites

- Shadow-39 améliore fortement les lampadaires et petits props grâce à un footprint automatique étroit.
- Les bâtiments restent limités par les projections et profils disponibles : ce lot ne crée pas encore de famille de silhouette dédiée façon Pokémon pour les façades et toits.
- La classification V0 repose sur la taille de la première frame, pas sur l’analyse d’image ou de sprite mask.
- Le bouton `Calculer automatiquement` remplace explicitement les valeurs courantes; c’est voulu, mais cela peut écraser un réglage manuel si l’utilisateur clique volontairement.

## 23. Auto-review

- Le helper utilise-t-il uniquement les champs existants ? oui.
- Le helper évite-t-il les imports runtime ? oui.
- Le lot évite-t-il les modèles persistants et codecs ? oui.
- L’activation depuis `null` applique-t-elle une suggestion ? oui.
- Le bouton explicite de recalcul existe-t-il ? oui.
- Les éditions manuelles existantes restent-elles possibles après suggestion ? oui.
- Les cas invalides ou sans profil compatible sont-ils sûrs ? oui.
- Les limites produit sont-elles documentées ? oui.

## 24. Regard critique sur le plan

Le plan est cohérent pour résoudre la douleur immédiate : arrêter de demander à l’utilisateur de deviner un footprint pour chaque type d’élément. La limite importante est qu’il reste heuristique : il ne peut pas encore produire des ombres Pokémon parfaitement silhouettes pour les bâtiments, car cela demandera une famille de projection ou une donnée de silhouette plus spécialisée.

## 25. Code complet des fichiers créés par Shadow-39

### packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart

```dart
import 'package:map_core/map_core.dart';

enum ElementAutoShadowSuggestionKind {
  tallThin,
  buildingLarge,
  wideLow,
  smallSquare,
  defaultProp,
}

final class ElementAutoShadowSuggestion {
  const ElementAutoShadowSuggestion({
    required this.kind,
    required this.config,
    required this.summary,
  });

  final ElementAutoShadowSuggestionKind kind;
  final ProjectElementShadowConfig config;
  final String summary;
}

ElementAutoShadowSuggestion? buildElementAutoShadowSuggestion({
  required ProjectElementEntry element,
  required ProjectShadowCatalog shadowCatalog,
}) {
  if (element.frames.isEmpty) {
    return null;
  }
  final source = element.frames.first.source;
  if (source.width <= 0 || source.height <= 0) {
    return null;
  }
  final kind = _classifyElement(
    width: source.width.toDouble(),
    height: source.height.toDouble(),
  );
  final profile = _profileForKind(shadowCatalog, kind);
  if (profile == null) {
    return null;
  }
  return ElementAutoShadowSuggestion(
    kind: kind,
    config: _configForKind(kind, profile.id),
    summary: _summaryForKind(kind),
  );
}

ElementAutoShadowSuggestionKind _classifyElement({
  required double width,
  required double height,
}) {
  final area = width * height;
  final aspect = height / width;
  if (aspect >= 2.2 && width <= 2) {
    return ElementAutoShadowSuggestionKind.tallThin;
  }
  if (width >= 4 || area >= 12) {
    return ElementAutoShadowSuggestionKind.buildingLarge;
  }
  if (width >= 3 && height <= 3) {
    return ElementAutoShadowSuggestionKind.wideLow;
  }
  if (area <= 4) {
    return ElementAutoShadowSuggestionKind.smallSquare;
  }
  return ElementAutoShadowSuggestionKind.defaultProp;
}

ProjectShadowProfile? _profileForKind(
  ProjectShadowCatalog catalog,
  ElementAutoShadowSuggestionKind kind,
) {
  switch (kind) {
    case ElementAutoShadowSuggestionKind.tallThin:
    case ElementAutoShadowSuggestionKind.smallSquare:
      return _preferredCompactProfile(catalog);
    case ElementAutoShadowSuggestionKind.buildingLarge:
    case ElementAutoShadowSuggestionKind.wideLow:
      return _preferredWideProfile(catalog);
    case ElementAutoShadowSuggestionKind.defaultProp:
      return _preferredSoftProfile(catalog);
  }
}

ProjectShadowProfile? _preferredCompactProfile(ProjectShadowCatalog catalog) {
  return _compatibleProfileById(catalog, 'default-ground-contact-blob') ??
      _firstCompatibleProfileWithMode(catalog, ShadowCasterMode.contactBlob) ??
      _firstCompatibleProfile(catalog);
}

ProjectShadowProfile? _preferredWideProfile(ProjectShadowCatalog catalog) {
  return _compatibleProfileById(catalog, 'default-ground-wide-ellipse') ??
      _firstCompatibleProfileWithMode(catalog, ShadowCasterMode.ellipse) ??
      _firstCompatibleProfile(catalog);
}

ProjectShadowProfile? _preferredSoftProfile(ProjectShadowCatalog catalog) {
  return _compatibleProfileById(catalog, 'default-ground-soft-ellipse') ??
      _firstCompatibleProfileWithMode(catalog, ShadowCasterMode.ellipse) ??
      _firstCompatibleProfile(catalog);
}

ProjectShadowProfile? _compatibleProfileById(
  ProjectShadowCatalog catalog,
  String id,
) {
  final profile = catalog.profileById(id);
  if (profile == null || !isGroundStaticElementShadowProfile(profile)) {
    return null;
  }
  return profile;
}

ProjectShadowProfile? _firstCompatibleProfileWithMode(
  ProjectShadowCatalog catalog,
  ShadowCasterMode mode,
) {
  for (final profile in catalog.profiles) {
    if (profile.mode == mode && isGroundStaticElementShadowProfile(profile)) {
      return profile;
    }
  }
  return null;
}

ProjectShadowProfile? _firstCompatibleProfile(ProjectShadowCatalog catalog) {
  for (final profile in catalog.profiles) {
    if (isGroundStaticElementShadowProfile(profile)) {
      return profile;
    }
  }
  return null;
}

ProjectElementShadowConfig _configForKind(
  ElementAutoShadowSuggestionKind kind,
  String profileId,
) {
  switch (kind) {
    case ElementAutoShadowSuggestionKind.tallThin:
      return ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: profileId,
        offsetX: 0,
        offsetY: 0,
        scaleX: 1,
        scaleY: 1,
        opacity: 0.28,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 1.0,
          footprintWidthRatio: 0.18,
          footprintHeightRatio: 0.07,
        ),
      );
    case ElementAutoShadowSuggestionKind.buildingLarge:
      return ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: profileId,
        offsetX: 0,
        offsetY: 0,
        scaleX: 1,
        scaleY: 0.85,
        opacity: 0.30,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.92,
          footprintWidthRatio: 0.82,
          footprintHeightRatio: 0.12,
        ),
      );
    case ElementAutoShadowSuggestionKind.wideLow:
      return ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: profileId,
        offsetX: 0,
        offsetY: 0,
        scaleX: 0.92,
        scaleY: 0.75,
        opacity: 0.27,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.95,
          footprintWidthRatio: 0.72,
          footprintHeightRatio: 0.10,
        ),
      );
    case ElementAutoShadowSuggestionKind.smallSquare:
      return ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: profileId,
        offsetX: 0,
        offsetY: 0,
        scaleX: 0.78,
        scaleY: 0.70,
        opacity: 0.26,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.96,
          footprintWidthRatio: 0.46,
          footprintHeightRatio: 0.10,
        ),
      );
    case ElementAutoShadowSuggestionKind.defaultProp:
      return ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: profileId,
        offsetX: 0,
        offsetY: 0,
        scaleX: 0.90,
        scaleY: 0.80,
        opacity: 0.28,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.95,
          footprintWidthRatio: 0.62,
          footprintHeightRatio: 0.12,
        ),
      );
  }
}

String _summaryForKind(ElementAutoShadowSuggestionKind kind) {
  switch (kind) {
    case ElementAutoShadowSuggestionKind.tallThin:
      return 'lampadaire fin';
    case ElementAutoShadowSuggestionKind.buildingLarge:
      return 'grand bâtiment';
    case ElementAutoShadowSuggestionKind.wideLow:
      return 'élément large et bas';
    case ElementAutoShadowSuggestionKind.smallSquare:
      return 'petit élément compact';
    case ElementAutoShadowSuggestionKind.defaultProp:
      return 'élément standard';
  }
}
```

### packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/element_auto_shadow_suggestion.dart';

void main() {
  group('buildElementAutoShadowSuggestion', () {
    test('returns null without compatible ground static profile', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 4),
        shadowCatalog: ProjectShadowCatalog(
          profiles: [
            _profile(
              'actor_contact',
              mode: ShadowCasterMode.contactBlob,
              renderPass: ShadowRenderPass.actorContact,
            ),
            _profile('none', mode: ShadowCasterMode.none),
          ],
        ),
      );

      expect(suggestion, isNull);
    });

    test('returns null for missing frames', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _elementWithFrames(const []),
        shadowCatalog: _defaultCatalog(),
      );

      expect(suggestion, isNull);
    });

    test('returns null for invalid first frame source', () {
      final invalidWidth = buildElementAutoShadowSuggestion(
        element: _element(width: 0, height: 4),
        shadowCatalog: _defaultCatalog(),
      );
      final invalidHeight = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 0),
        shadowCatalog: _defaultCatalog(),
      );

      expect(invalidWidth, isNull);
      expect(invalidHeight, isNull);
    });

    test('classifies tall thin elements as tallThin', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 4),
        shadowCatalog: _defaultCatalog(),
      )!;

      expect(suggestion.kind, ElementAutoShadowSuggestionKind.tallThin);
      expect(suggestion.config.shadowProfileId, 'default-ground-contact-blob');
      expect(suggestion.config.footprint!.footprintWidthRatio, 0.18);
      expect(suggestion.config.footprint!.footprintHeightRatio, 0.07);
      expect(suggestion.config.opacity, 0.28);
    });

    test('classifies large buildings as buildingLarge', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 4, height: 3),
        shadowCatalog: _defaultCatalog(),
      )!;

      expect(suggestion.kind, ElementAutoShadowSuggestionKind.buildingLarge);
      expect(suggestion.config.shadowProfileId, 'default-ground-wide-ellipse');
      expect(suggestion.config.footprint!.anchorYRatio, 0.92);
      expect(suggestion.config.footprint!.footprintWidthRatio, 0.82);
      expect(suggestion.config.footprint!.footprintHeightRatio, 0.12);
      expect(suggestion.config.scaleY, 0.85);
      expect(suggestion.config.opacity, 0.30);
    });

    test('classifies wide low elements as wideLow', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 3, height: 2),
        shadowCatalog: _defaultCatalog(),
      )!;

      expect(suggestion.kind, ElementAutoShadowSuggestionKind.wideLow);
      expect(suggestion.config.shadowProfileId, 'default-ground-wide-ellipse');
      expect(suggestion.config.footprint!.anchorYRatio, 0.95);
      expect(suggestion.config.footprint!.footprintWidthRatio, 0.72);
      expect(suggestion.config.footprint!.footprintHeightRatio, 0.10);
      expect(suggestion.config.scaleX, 0.92);
      expect(suggestion.config.scaleY, 0.75);
      expect(suggestion.config.opacity, 0.27);
    });

    test('classifies small square elements as smallSquare', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 2, height: 2),
        shadowCatalog: _defaultCatalog(),
      )!;

      expect(suggestion.kind, ElementAutoShadowSuggestionKind.smallSquare);
      expect(suggestion.config.shadowProfileId, 'default-ground-contact-blob');
      expect(suggestion.config.footprint!.anchorYRatio, 0.96);
      expect(suggestion.config.footprint!.footprintWidthRatio, 0.46);
      expect(suggestion.config.footprint!.footprintHeightRatio, 0.10);
      expect(suggestion.config.scaleX, 0.78);
      expect(suggestion.config.scaleY, 0.70);
      expect(suggestion.config.opacity, 0.26);
    });

    test('classifies remaining valid elements as defaultProp', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 2, height: 3),
        shadowCatalog: _defaultCatalog(),
      )!;

      expect(suggestion.kind, ElementAutoShadowSuggestionKind.defaultProp);
      expect(suggestion.config.shadowProfileId, 'default-ground-soft-ellipse');
      expect(suggestion.config.footprint!.anchorYRatio, 0.95);
      expect(suggestion.config.footprint!.footprintWidthRatio, 0.62);
      expect(suggestion.config.footprint!.footprintHeightRatio, 0.12);
      expect(suggestion.config.scaleX, 0.90);
      expect(suggestion.config.scaleY, 0.80);
      expect(suggestion.config.opacity, 0.28);
    });

    test('prefers default compact profile for tallThin', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 4),
        shadowCatalog: ProjectShadowCatalog(
          profiles: [
            _profile('custom-soft'),
            _profile('default-ground-contact-blob',
                mode: ShadowCasterMode.contactBlob),
          ],
        ),
      )!;

      expect(suggestion.config.shadowProfileId, 'default-ground-contact-blob');
    });

    test('falls back to custom compatible profile ids', () {
      final tallThin = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 4),
        shadowCatalog: ProjectShadowCatalog(
          profiles: [
            _profile('custom-contact', mode: ShadowCasterMode.contactBlob)
          ],
        ),
      )!;
      final building = buildElementAutoShadowSuggestion(
        element: _element(width: 4, height: 3),
        shadowCatalog: ProjectShadowCatalog(
          profiles: [_profile('custom-ellipse')],
        ),
      )!;
      final defaultProp = buildElementAutoShadowSuggestion(
        element: _element(width: 2, height: 3),
        shadowCatalog: ProjectShadowCatalog(
          profiles: [_profile('custom-soft')],
        ),
      )!;

      expect(tallThin.config.shadowProfileId, 'custom-contact');
      expect(building.config.shadowProfileId, 'custom-ellipse');
      expect(defaultProp.config.shadowProfileId, 'custom-soft');
    });

    test('all suggestions have castsShadow true', () {
      for (final suggestion in _allSuggestionKinds()) {
        expect(suggestion.config.castsShadow, isTrue);
      }
    });

    test('all suggestion footprints are non-null and valid', () {
      for (final suggestion in _allSuggestionKinds()) {
        final footprint = suggestion.config.footprint;
        expect(footprint, isNotNull);
        expect(footprint!.anchorXRatio, inInclusiveRange(0, 1));
        expect(footprint.anchorYRatio, inInclusiveRange(0, 1));
        expect(footprint.footprintWidthRatio, greaterThan(0));
        expect(footprint.footprintHeightRatio, greaterThan(0));
      }
    });

    test('all suggestion opacities are within 0..1', () {
      for (final suggestion in _allSuggestionKinds()) {
        expect(suggestion.config.opacity, inInclusiveRange(0, 1));
      }
    });

    test('all suggestion scaleX and scaleY are greater than zero', () {
      for (final suggestion in _allSuggestionKinds()) {
        expect(suggestion.config.scaleX, greaterThan(0));
        expect(suggestion.config.scaleY, greaterThan(0));
      }
    });
  });
}

Iterable<ElementAutoShadowSuggestion> _allSuggestionKinds() sync* {
  for (final dimensions in const [
    (width: 1, height: 4),
    (width: 4, height: 3),
    (width: 3, height: 2),
    (width: 2, height: 2),
    (width: 2, height: 3),
  ]) {
    yield buildElementAutoShadowSuggestion(
      element: _element(width: dimensions.width, height: dimensions.height),
      shadowCatalog: _defaultCatalog(),
    )!;
  }
}

ProjectShadowCatalog _defaultCatalog() {
  return ProjectShadowCatalog(
    profiles: createDefaultGroundStaticShadowProfiles(),
  );
}

ProjectElementEntry _element({
  required int width,
  required int height,
}) {
  return _elementWithFrames([
    TilesetVisualFrame(
      source: TilesetSourceRect(x: 0, y: 0, width: width, height: height),
    ),
  ]);
}

ProjectElementEntry _elementWithFrames(List<TilesetVisualFrame> frames) {
  return ProjectElementEntry(
    id: 'element',
    name: 'Element',
    tilesetId: 'tileset',
    categoryId: 'decor',
    frames: frames,
  );
}

ProjectShadowProfile _profile(
  String id, {
  ShadowCasterMode mode = ShadowCasterMode.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
}) {
  return ProjectShadowProfile(
    id: id,
    name: '$id shadow',
    mode: mode,
    renderPass: renderPass,
  );
}
```

## 26. Diffs complets des fichiers existants modifiés par Shadow-39

```diff
diff --git a/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart b/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart
index 8e900adc..b72627ca 100644
--- a/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart
+++ b/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart
@@ -3,6 +3,7 @@ import 'package:flutter/services.dart';
 import 'package:flutter/material.dart' show Colors;
 import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/application/shadow/element_auto_shadow_suggestion.dart';
 import 'package:map_editor/src/application/shadow/element_shadow_read_model.dart';
 import 'package:map_editor/src/ui/shared/cupertino_editor_widgets.dart';
 
@@ -89,6 +90,7 @@ class _ElementShadowSectionState extends State<ElementShadowSection> {
     final profiles = readModel.profileOptions;
     final selectedProfileId =
         readModel.profileExists ? readModel.shadowProfileId : null;
+    final autoSuggestion = _buildAutoSuggestion();
     final label = EditorChrome.primaryLabel(context);
     final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
     final shadow = widget.shadow;
@@ -203,6 +205,19 @@ class _ElementShadowSectionState extends State<ElementShadowSection> {
             selectedProfileId: selectedProfileId,
             enabled: profiles.isNotEmpty && shadow != null,
           ),
+          if (autoSuggestion != null) ...[
+            const SizedBox(height: 8),
+            Align(
+              alignment: Alignment.centerLeft,
+              child: PushButton(
+                key: const ValueKey('element-shadow-auto-suggestion-button'),
+                controlSize: ControlSize.regular,
+                secondary: true,
+                onPressed: () => _applyAutoSuggestion(autoSuggestion),
+                child: const Text('Calculer automatiquement'),
+              ),
+            ),
+          ],
           if (shadow != null) ...[
             const SizedBox(height: 10),
             if (shadow.castsShadow) ...[
@@ -482,6 +497,14 @@ class _ElementShadowSectionState extends State<ElementShadowSection> {
       return;
     }
 
+    if (current == null) {
+      final suggestion = _buildAutoSuggestion();
+      if (suggestion != null) {
+        _applyAutoSuggestion(suggestion);
+        return;
+      }
+    }
+
     final profiles = buildShadowProfileOptionsForManifest(widget.manifest);
     if (profiles.isEmpty) {
       setState(() {
@@ -512,6 +535,22 @@ class _ElementShadowSectionState extends State<ElementShadowSection> {
     );
   }
 
+  ElementAutoShadowSuggestion? _buildAutoSuggestion() {
+    return buildElementAutoShadowSuggestion(
+      element: widget.element,
+      shadowCatalog: widget.manifest.shadowCatalog,
+    );
+  }
+
+  void _applyAutoSuggestion(ElementAutoShadowSuggestion suggestion) {
+    setState(() {
+      _errors.clear();
+      _footprintErrors.clear();
+      _activationMessage = 'Ombre automatique : ${suggestion.summary}.';
+    });
+    widget.onChanged(suggestion.config);
+  }
+
   void _setProfile(String profileId) {
     final current = widget.shadow;
     widget.onChanged(
diff --git a/packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart b/packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart
index aad31388..b1e8de19 100644
--- a/packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart
+++ b/packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart
@@ -187,8 +187,33 @@ void main() {
       );
     });
 
+    testWidgets('activating from null applies an auto suggestion',
+        (tester) async {
+      final harness = _ShadowSectionHarness();
+
+      await _pumpSection(
+        tester,
+        harness: harness,
+        manifest: _project(_defaultCatalog()),
+        element: _element(width: 1, height: 4),
+      );
+
+      final toggle = tester.widget<CupertinoSwitch>(
+        find.byKey(const ValueKey('element-shadow-casts-switch')),
+      );
+      toggle.onChanged!(true);
+      await tester.pump();
+
+      expect(harness.shadow, isNotNull);
+      expect(harness.shadow!.castsShadow, isTrue);
+      expect(harness.shadow!.shadowProfileId, 'default-ground-contact-blob');
+      expect(harness.shadow!.footprint!.footprintWidthRatio, 0.18);
+      expect(harness.shadow!.footprint!.footprintHeightRatio, 0.07);
+      expect(harness.shadow!.opacity, 0.28);
+    });
+
     testWidgets(
-        'activating from null creates an active config with first profile',
+        'activating from null falls back to first profile when suggestion is unavailable',
         (tester) async {
       final harness = _ShadowSectionHarness();
 
@@ -198,6 +223,7 @@ void main() {
         manifest: _project(
           _catalog([_profile('tree_large'), _profile('rock_small')]),
         ),
+        element: _element(frames: const <TilesetVisualFrame>[]),
       );
 
       final toggle = tester.widget<CupertinoSwitch>(
@@ -209,6 +235,113 @@ void main() {
       expect(harness.shadow, isNotNull);
       expect(harness.shadow!.castsShadow, isTrue);
       expect(harness.shadow!.shadowProfileId, 'tree_large');
+      expect(harness.shadow!.footprint, isNull);
+    });
+
+    testWidgets('auto calculate button is visible with a compatible profile',
+        (tester) async {
+      final harness = _ShadowSectionHarness();
+
+      await _pumpSection(
+        tester,
+        harness: harness,
+        manifest: _project(_defaultCatalog()),
+        element: _element(width: 1, height: 4),
+      );
+
+      expect(find.text('Calculer automatiquement'), findsOneWidget);
+    });
+
+    testWidgets('auto calculate button applies suggestion to active config',
+        (tester) async {
+      final harness = _ShadowSectionHarness(
+        ProjectElementShadowConfig(
+          castsShadow: true,
+          shadowProfileId: 'manual-profile',
+          offsetX: 8,
+          offsetY: 4,
+          scaleX: 2,
+          scaleY: 2,
+          opacity: 0.9,
+          footprint: StaticShadowFootprintConfig(
+            anchorXRatio: 0.1,
+            footprintWidthRatio: 0.2,
+          ),
+        ),
+      );
+
+      await _pumpSection(
+        tester,
+        harness: harness,
+        manifest: _project(_defaultCatalog()),
+        element: _element(width: 4, height: 3),
+      );
+
+      await tester.tap(
+        find.byKey(const ValueKey('element-shadow-auto-suggestion-button')),
+      );
+      await tester.pump();
+
+      expect(harness.shadow!.castsShadow, isTrue);
+      expect(harness.shadow!.shadowProfileId, 'default-ground-wide-ellipse');
+      expect(harness.shadow!.offsetX, 0);
+      expect(harness.shadow!.offsetY, 0);
+      expect(harness.shadow!.scaleX, 1);
+      expect(harness.shadow!.scaleY, 0.85);
+      expect(harness.shadow!.opacity, 0.30);
+      expect(harness.shadow!.footprint!.anchorYRatio, 0.92);
+      expect(harness.shadow!.footprint!.footprintWidthRatio, 0.82);
+      expect(find.text('Ombre automatique : grand bâtiment.'), findsOneWidget);
+    });
+
+    testWidgets('auto calculate button is absent without compatible profile',
+        (tester) async {
+      final harness = _ShadowSectionHarness();
+
+      await _pumpSection(
+        tester,
+        harness: harness,
+        manifest: _project(
+          _catalog([
+            _profile(
+              'actor_contact',
+              mode: ShadowCasterMode.contactBlob,
+              renderPass: ShadowRenderPass.actorContact,
+            ),
+          ]),
+        ),
+        element: _element(width: 1, height: 4),
+      );
+
+      expect(find.text('Calculer automatiquement'), findsNothing);
+    });
+
+    testWidgets('changing profile after auto suggestion preserves footprint',
+        (tester) async {
+      final harness = _ShadowSectionHarness();
+
+      await _pumpSection(
+        tester,
+        harness: harness,
+        manifest: _project(_defaultCatalog()),
+        element: _element(width: 1, height: 4),
+      );
+
+      final toggle = tester.widget<CupertinoSwitch>(
+        find.byKey(const ValueKey('element-shadow-casts-switch')),
+      );
+      toggle.onChanged!(true);
+      await tester.pump();
+      final footprint = harness.shadow!.footprint;
+
+      final popup = tester.widget<MacosPopupButton<String>>(
+        find.byKey(const ValueKey('element-shadow-profile-popup')),
+      );
+      popup.onChanged!('default-ground-soft-ellipse');
+      await tester.pump();
+
+      expect(harness.shadow!.shadowProfileId, 'default-ground-soft-ellipse');
+      expect(harness.shadow!.footprint, footprint);
     });
 
     testWidgets('disabling preserves the selected profile and overrides',
@@ -701,11 +834,12 @@ Future<void> _pumpSection(
   WidgetTester tester, {
   required _ShadowSectionHarness harness,
   required ProjectManifest manifest,
+  ProjectElementEntry? element,
   VoidCallback? onEnsureDefaultShadowProfiles,
 }) async {
   await tester.binding.setSurfaceSize(const Size(520, 900));
   addTearDown(() => tester.binding.setSurfaceSize(null));
-  final element = _element();
+  final sectionElement = element ?? _element();
 
   await tester.pumpWidget(
     MacosTheme(
@@ -719,7 +853,7 @@ Future<void> _pumpSection(
                   width: 460,
                   child: ElementShadowSection(
                     manifest: manifest,
-                    element: element.copyWith(shadow: harness.shadow),
+                    element: sectionElement.copyWith(shadow: harness.shadow),
                     shadow: harness.shadow,
                     onChanged: (next) {
                       harness.changes.add(next);
@@ -760,6 +894,9 @@ ProjectManifest _project(ProjectShadowCatalog catalog) {
 }
 
 ProjectElementEntry _element({
+  int width = 1,
+  int height = 1,
+  List<TilesetVisualFrame>? frames,
   ElementCollisionProfile? collisionProfile,
 }) {
   return ProjectElementEntry(
@@ -767,13 +904,27 @@ ProjectElementEntry _element({
     name: 'Tree element',
     tilesetId: 'tileset_main',
     categoryId: 'decor',
-    frames: const <TilesetVisualFrame>[
-      TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
-    ],
+    frames: frames ??
+        [
+          TilesetVisualFrame(
+            source: TilesetSourceRect(
+              x: 0,
+              y: 0,
+              width: width,
+              height: height,
+            ),
+          ),
+        ],
     collisionProfile: collisionProfile,
   );
 }
 
+ProjectShadowCatalog _defaultCatalog() {
+  return ProjectShadowCatalog(
+    profiles: createDefaultGroundStaticShadowProfiles(),
+  );
+}
+
 ProjectShadowCatalog _catalog(List<ProjectShadowProfile> profiles) {
   return ProjectShadowCatalog(profiles: profiles);
 }
```
