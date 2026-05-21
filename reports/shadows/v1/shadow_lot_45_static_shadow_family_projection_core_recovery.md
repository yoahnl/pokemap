# Shadow-45 Static Shadow Family Projection Core Recovery V0

## 1. Resume du lot

Shadow-45 ajoute la brique pure `map_core` manquante qui transforme une `StaticShadowFamily` en `StaticShadowProjectionSpec`.

Ce lot recupere le chainon attendu par les lots Shadow-43/44 :

- `resolveStaticShadowFamily(...)`
- `resolveStaticShadowFamilyProjectionSpec(...)`
- export public via `packages/map_core/lib/map_core.dart`

Le lot ne branche pas encore runtime/editor. Il rend seulement les familles d'ombres calculables et testables cote coeur.

## 2. Design retenu

Le design reste volontairement minimal :

- la famille effective est resolue par priorite `overrideFamily`, puis `elementFamily`, puis `genericProjection`;
- `genericProjection` retourne la projection de base sans modification;
- les autres familles conservent la direction de base et ne modifient que `lengthRatio`, `nearWidthMultiplier` et `farWidthMultiplier`;
- les constantes V0 sont des multiplicateurs conservateurs, afin d'avoir une differenciation mesurable sans figer l'art direction finale.

## 3. Pourquoi Shadow-45 recupere la brique Shadow-42 manquante

Les plans Shadow-43 et Shadow-44 s'appuient sur une API de projection par famille, mais le fichier `packages/map_core/lib/src/operations/static_shadow_family_projection.dart` n'existait pas. Sans cette brique, le runtime/editor ne peuvent pas consommer honnetement les familles `genericProjection`, `compactProp`, `tallProp`, `building` et `foliage`.

Shadow-45 implemente uniquement cette API pure. L'integration visuelle reste a faire dans les lots suivants.

## 4. Fichiers crees

- `packages/map_core/lib/src/operations/static_shadow_family_projection.dart`
- `packages/map_core/test/shadow/static_shadow_family_projection_test.dart`
- `reports/shadows/shadow_lot_45_static_shadow_family_projection_core_recovery.md`

## 5. Fichiers modifies

- `packages/map_core/lib/map_core.dart`

## 6. Fichiers non modifies explicitement

- `packages/map_core/lib/src/models/**`
- `packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart`
- `packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart`
- `packages/map_core/lib/src/operations/static_shadow_family_json_codec.dart`
- `packages/map_editor/**`
- `packages/map_runtime/**`
- `packages/map_gameplay/**`
- `packages/map_battle/**`
- `examples/playable_runtime_host/**`
- fichiers generes `.g.dart` / `.freezed.dart`

Des fichiers `map_editor` et `map_battle` apparaissent dans le worktree, mais ils etaient hors scope Shadow-45 et n'ont pas ete modifies par ce lot.

## 7. API ajoutee

```dart
StaticShadowFamily resolveStaticShadowFamily({
  StaticShadowFamily? elementFamily,
  StaticShadowFamily? overrideFamily,
});

StaticShadowProjectionSpec resolveStaticShadowFamilyProjectionSpec({
  required StaticShadowFamily family,
  StaticShadowProjectionSpec baseProjectionSpec =
      defaultStaticShadowProjectionSpec,
});
```

## 8. Regle de merge family

La regle est :

```text
overrideFamily ?? elementFamily ?? StaticShadowFamily.genericProjection
```

Pourquoi :

- l'element source fournit la strategie par defaut;
- l'instance placee pourra plus tard la remplacer localement;
- l'absence de famille garde la projection generique existante;
- la regle est simple, explicite et testee.

## 9. Specs V0 par famille

Base actuelle :

```text
defaultStaticShadowProjectionSpec.lengthRatio = 0.32
defaultStaticShadowProjectionSpec.nearWidthMultiplier = 0.92
defaultStaticShadowProjectionSpec.farWidthMultiplier = 1.18
```

Multiplicateurs Shadow-45 :

```text
genericProjection:
  spec de base inchangee

compactProp:
  lengthRatio * 0.72
  nearWidthMultiplier * 0.82
  farWidthMultiplier * 0.78

tallProp:
  lengthRatio * 1.18
  nearWidthMultiplier * 0.52
  farWidthMultiplier * 0.58

building:
  lengthRatio * 1.25
  nearWidthMultiplier * 1.05
  farWidthMultiplier * 0.98

foliage:
  lengthRatio * 1.05
  nearWidthMultiplier * 1.15
  farWidthMultiplier * 1.28
```

Constantes resultantes testees :

```text
compactProp:
  lengthRatio = 0.2304
  nearWidthMultiplier = 0.7544
  farWidthMultiplier = 0.9204

tallProp:
  lengthRatio = 0.3776
  nearWidthMultiplier = 0.4784
  farWidthMultiplier = 0.6844

building:
  lengthRatio = 0.4
  nearWidthMultiplier = 0.966
  farWidthMultiplier = 1.1564

foliage:
  lengthRatio = 0.336
  nearWidthMultiplier = 1.058
  farWidthMultiplier = 1.5104
```

## 10. Preservation de la direction de base

`resolveStaticShadowFamilyProjectionSpec(...)` conserve toujours :

```text
baseProjectionSpec.directionX
baseProjectionSpec.directionY
```

Cette decision evite de creer une lumiere globale. Les familles reglent uniquement la silhouette relative de l'ombre.

## 11. Pourquoi ce lot ne touche pas runtime/editor

Shadow-45 corrige une brique core absente. Le runtime et l'editor doivent l'utiliser ensuite, mais ce branchement est un risque different :

- il touche le rendu;
- il doit verifier l'ordre de rendu;
- il doit eviter d'appliquer deux fois la projection;
- il doit conserver les comportements visuels existants.

Ce lot reste donc en `map_core` uniquement.

## 12. Pourquoi ce lot ne cree pas de lumiere globale

Le lot ne cree aucun `WorldLightState`, `LightDirection`, `timeOfDay`, modele persistant de lumiere, renderer, `Canvas`, `Flame`, `saveLayer`, blur ou atlas. La direction est un champ deja present dans `StaticShadowProjectionSpec` et reste transmise depuis la spec de base fournie a la fonction.

## 13. Tests ajoutes

Fichier cree :

- `packages/map_core/test/shadow/static_shadow_family_projection_test.dart`

Couverture :

- fallback famille generique;
- famille element;
- famille override prioritaire;
- `genericProjection` conserve la spec de base;
- les familles non generiques conservent la direction;
- constantes V0 stables;
- specs valides avec base positive custom;
- tall prop nettement plus etroit que building;
- compact prop projette moins de surface que generic pour les memes metriques.

## 14. Commandes lancees

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/dc902811/skills/verification-before-completion/SKILL.md
sed -n '1,220p' packages/map_core/lib/src/operations/static_shadow_family_projection.dart
sed -n '1,420p' packages/map_core/test/shadow/static_shadow_family_projection_test.dart
sed -n '1,180p' packages/map_core/lib/map_core.dart
git diff -- packages/map_core/lib/map_core.dart
git diff --no-index /dev/null packages/map_core/lib/src/operations/static_shadow_family_projection.dart
git diff --no-index /dev/null packages/map_core/test/shadow/static_shadow_family_projection_test.dart
cd packages/map_core && dart test test/shadow/static_shadow_family_projection_test.dart
cd packages/map_core && dart format lib/src/operations/static_shadow_family_projection.dart test/shadow/static_shadow_family_projection_test.dart lib/map_core.dart
cd packages/map_core && dart test test/shadow/static_shadow_family_projection_test.dart
cd packages/map_core && dart test test/shadow
cd packages/map_core && dart analyze lib test/shadow
cd packages/map_core && dart test
git diff --name-only | rg -n "packages/map_editor|packages/map_runtime|packages/map_gameplay|packages/map_battle|examples/playable_runtime_host"
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_family_json_codec|\.g\.dart|\.freezed\.dart"
git diff -U0 -- packages/map_core | rg -n "Canvas|Flame|drawOval|drawPath|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

## 15. Resultats complets des tests cibles

### RED utile

Commande :

```bash
cd packages/map_core && dart test test/shadow/static_shadow_family_projection_test.dart
```

Resultat utile apres correction du test lui-meme :

```text
Failed to load "test/shadow/static_shadow_family_projection_test.dart":
test/shadow/static_shadow_family_projection_test.dart:10:9: Error: Method not found: 'resolveStaticShadowFamily'.
        resolveStaticShadowFamily(),
        ^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow/static_shadow_family_projection_test.dart:17:9: Error: Method not found: 'resolveStaticShadowFamily'.
        resolveStaticShadowFamily(
        ^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow/static_shadow_family_projection_test.dart:27:9: Error: Method not found: 'resolveStaticShadowFamily'.
        resolveStaticShadowFamily(
        ^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow/static_shadow_family_projection_test.dart:45:9: Error: Method not found: 'resolveStaticShadowFamilyProjectionSpec'.
        resolveStaticShadowFamilyProjectionSpec(
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow/static_shadow_family_projection_test.dart:66:22: Error: Method not found: 'resolveStaticShadowFamilyProjectionSpec'.
        final spec = resolveStaticShadowFamilyProjectionSpec(
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow/static_shadow_family_projection_test.dart:78:20: Error: Method not found: 'resolveStaticShadowFamilyProjectionSpec'.
      final spec = resolveStaticShadowFamilyProjectionSpec(
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow/static_shadow_family_projection_test.dart:97:20: Error: Method not found: 'resolveStaticShadowFamilyProjectionSpec'.
      final spec = resolveStaticShadowFamilyProjectionSpec(
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow/static_shadow_family_projection_test.dart:116:20: Error: Method not found: 'resolveStaticShadowFamilyProjectionSpec'.
      final spec = resolveStaticShadowFamilyProjectionSpec(
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow/static_shadow_family_projection_test.dart:135:23: Error: Method not found: 'resolveStaticShadowFamilyProjectionSpec'.
      final foliage = resolveStaticShadowFamilyProjectionSpec(
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow/static_shadow_family_projection_test.dart:138:24: Error: Method not found: 'resolveStaticShadowFamilyProjectionSpec'.
      final tallProp = resolveStaticShadowFamilyProjectionSpec(
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow/static_shadow_family_projection_test.dart:153:20: Error: Method not found: 'resolveStaticShadowFamilyProjectionSpec'.
      final spec = resolveStaticShadowFamilyProjectionSpec(
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow/static_shadow_family_projection_test.dart:163:20: Error: Method not found: 'resolveStaticShadowFamilyProjectionSpec'.
      final spec = resolveStaticShadowFamilyProjectionSpec(
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow/static_shadow_family_projection_test.dart:173:20: Error: Method not found: 'resolveStaticShadowFamilyProjectionSpec'.
      final spec = resolveStaticShadowFamilyProjectionSpec(
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow/static_shadow_family_projection_test.dart:183:20: Error: Method not found: 'resolveStaticShadowFamilyProjectionSpec'.
      final spec = resolveStaticShadowFamilyProjectionSpec(
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow/static_shadow_family_projection_test.dart:200:22: Error: Method not found: 'resolveStaticShadowFamilyProjectionSpec'.
        final spec = resolveStaticShadowFamilyProjectionSpec(
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow/static_shadow_family_projection_test.dart:276:21: Error: Method not found: 'resolveStaticShadowFamilyProjectionSpec'.
    projectionSpec: resolveStaticShadowFamilyProjectionSpec(family: family),
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

Interpretation : le test echoue bien sur l'API manquante visee par Shadow-45.

### GREEN cible final

Commande :

```bash
cd packages/map_core && dart test test/shadow/static_shadow_family_projection_test.dart
```

Sortie complete utile :

```text
00:00 +0: loading test/shadow/static_shadow_family_projection_test.dart
00:00 +0: resolveStaticShadowFamily uses generic projection when no family is provided
00:00 +1: resolveStaticShadowFamily uses element family when no override family is provided
00:00 +2: resolveStaticShadowFamily uses override family over element family
00:00 +3: resolveStaticShadowFamilyProjectionSpec genericProjection returns the base projection unchanged
00:00 +4: resolveStaticShadowFamilyProjectionSpec preserves base direction for every non-generic family
00:00 +5: resolveStaticShadowFamilyProjectionSpec compact props are shorter and tighter than generic projection
00:00 +6: resolveStaticShadowFamilyProjectionSpec tall props are narrow and still project farther than generic
00:00 +7: resolveStaticShadowFamilyProjectionSpec buildings keep a broad block-like projection
00:00 +8: resolveStaticShadowFamilyProjectionSpec foliage is broader than tall prop
00:00 +9: resolveStaticShadowFamilyProjectionSpec compactProp V0 constants are stable
00:00 +10: resolveStaticShadowFamilyProjectionSpec tallProp V0 constants are stable
00:00 +11: resolveStaticShadowFamilyProjectionSpec building V0 constants are stable
00:00 +12: resolveStaticShadowFamilyProjectionSpec foliage V0 constants are stable
00:00 +13: resolveStaticShadowFamilyProjectionSpec scaled family specs remain valid for a custom positive base
00:00 +14: family projection geometry composition tall prop polygon stays much narrower than building polygon
00:00 +15: family projection geometry composition compact prop projects less area than generic for same metrics
00:00 +16: All tests passed!
```

## 16. Lignes finales exactes des tests globaux cibles

Commande :

```bash
cd packages/map_core && dart test test/shadow
```

Ligne finale exacte :

```text
00:01 +255: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart analyze lib test/shadow
```

Sortie exacte :

```text
Analyzing lib, shadow...
No issues found!
```

Commande :

```bash
cd packages/map_core && dart test
```

Ligne finale exacte :

```text
00:03 +1611: All tests passed!
```

## 17. Resultats des scans anti-derive

Commande :

```bash
find .. -name AGENTS.md -print
```

Sortie :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Commande :

```bash
git diff --name-only | rg -n "packages/map_editor|packages/map_runtime|packages/map_gameplay|packages/map_battle|examples/playable_runtime_host"
```

Sortie :

```text
2:packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
3:packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
4:packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
5:packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
```

Interpretation : ces fichiers `map_editor` etaient des modifications hors lot deja presentes. Shadow-45 n'a edite aucun fichier `map_editor`, `map_runtime`, `map_gameplay`, `map_battle` ou `examples`.

Commande :

```bash
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_family_json_codec|\.g\.dart|\.freezed\.dart"
```

Sortie :

```text
aucune sortie
```

Commande :

```bash
git diff -U0 -- packages/map_core | rg -n "Canvas|Flame|drawOval|drawPath|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
```

Sortie :

```text
aucune sortie
```

Commande :

```bash
git diff --check
```

Sortie :

```text
aucune sortie
```

## 18. git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie initiale observee au debut de Shadow-45 :

```text
 M AGENTS.md
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
?? packages/map_battle/lib/src/domain/move/psdk_battle_move_executor.dart
?? packages/map_battle/lib/src/domain/move/psdk_battle_move_request.dart
?? packages/map_battle/test/psdk_battle_move_executor_test.dart
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview.md
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview_plan.md
?? reports/shadows/shadow_lot_45_static_shadow_family_projection_core_recovery_plan.md
```

Note honnete : le worktree a evolue pendant la session hors Shadow-45. `AGENTS.md` et certains fichiers `map_battle` non suivis ne sont plus dans le status final. Shadow-45 n'a pas touche ces chemins.

## 19. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Status final :

```text
 M packages/map_core/lib/map_core.dart
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
?? packages/map_core/lib/src/operations/static_shadow_family_projection.dart
?? packages/map_core/test/shadow/static_shadow_family_projection_test.dart
?? reports/shadows/shadow_lot_45_static_shadow_family_projection_core_recovery.md
?? reports/shadows/shadow_lot_45_static_shadow_family_projection_core_recovery_plan.md
```

## 20. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 packages/map_core/lib/map_core.dart                |   1 +
 .../shadow/editor_static_shadow_preview.dart       | 285 +++++++++++++--
 .../editor_static_shadow_preview_painter.dart      |  54 ++-
 .../shadow/editor_static_shadow_preview_test.dart  | 390 +++++++++++++++++----
 .../editor_static_shadow_preview_painter_test.dart |  69 +++-
 5 files changed, 681 insertions(+), 118 deletions(-)
```

Note : les fichiers Shadow-45 nouvellement crees sont non suivis, donc absents de `git diff --stat`.

Stat cible Shadow-45 suivi :

```bash
git diff --stat -- packages/map_core/lib/map_core.dart packages/map_core/lib/src/operations/static_shadow_family_projection.dart packages/map_core/test/shadow/static_shadow_family_projection_test.dart
```

Sortie :

```text
 packages/map_core/lib/map_core.dart | 1 +
 1 file changed, 1 insertion(+)
```

## 21. Non-objectifs respectes

- Aucun runtime modifie par Shadow-45.
- Aucun editor/canvas/UI modifie par Shadow-45.
- Aucun modele persistant modifie.
- Aucun codec JSON modifie.
- Aucun fichier genere modifie.
- Aucun `build_runner`.
- Aucune lumiere globale.
- Aucun `Canvas`, `Flame`, renderer, blur, `saveLayer`, atlas ou sprite d'ombre.
- Aucun commit effectue.

## 22. Risques / reserves

- Les constantes V0 sont volontairement conservatrices. Elles differencient les familles, mais ne garantissent pas encore un rendu final type Pokemon tant que runtime/editor ne consomment pas cette API.
- Le worktree contient des modifications hors lot. Elles devront rester separees lors du commit.
- Shadow-45 ne corrige pas directement les screenshots runtime : c'est une brique prealable.

## 23. Auto-review finale

- Ai-je ajoute `resolveStaticShadowFamily(...)` ? oui.
- Ai-je ajoute `resolveStaticShadowFamilyProjectionSpec(...)` ? oui.
- Ai-je garde `genericProjection` comme comportement inchangé ? oui.
- Ai-je preserve la direction de base ? oui.
- Ai-je differencie compact/tall/building/foliage ? oui.
- Ai-je evite de modifier les modeles persistants ? oui.
- Ai-je evite de modifier les codecs JSON ? oui.
- Ai-je evite de toucher runtime/editor ? oui.
- Ai-je evite build_runner ? oui.
- Ai-je evite toute lumiere globale ? oui.
- Ai-je ajoute des tests cibles ? oui.
- Ai-je documente le worktree sale hors lot ? oui.

## 24. Regard critique sur le plan/prompt

Le plan est coherent comme lot de recuperation : il evite de melanger API core et integration renderer. Le point discutable est la calibration des constantes V0 : elles sont testees comme contrat temporaire, mais elles restent artistiques et devront probablement etre ajustees apres captures visuelles. Le plan ne peut pas, a lui seul, rendre les ombres belles dans le runtime tant que les lots d'integration ne consomment pas l'API.

## 25. Code complet des fichiers crees/modifies par Shadow-45

### `packages/map_core/lib/src/operations/static_shadow_family_projection.dart`

```dart
import '../models/shadow.dart';
import 'static_shadow_projection_geometry.dart';

StaticShadowFamily resolveStaticShadowFamily({
  StaticShadowFamily? elementFamily,
  StaticShadowFamily? overrideFamily,
}) {
  return overrideFamily ??
      elementFamily ??
      StaticShadowFamily.genericProjection;
}

StaticShadowProjectionSpec resolveStaticShadowFamilyProjectionSpec({
  required StaticShadowFamily family,
  StaticShadowProjectionSpec baseProjectionSpec =
      defaultStaticShadowProjectionSpec,
}) {
  switch (family) {
    case StaticShadowFamily.genericProjection:
      return baseProjectionSpec;
    case StaticShadowFamily.compactProp:
      return _scaledProjectionSpec(
        baseProjectionSpec,
        lengthRatioScale: 0.72,
        nearWidthMultiplierScale: 0.82,
        farWidthMultiplierScale: 0.78,
      );
    case StaticShadowFamily.tallProp:
      return _scaledProjectionSpec(
        baseProjectionSpec,
        lengthRatioScale: 1.18,
        nearWidthMultiplierScale: 0.52,
        farWidthMultiplierScale: 0.58,
      );
    case StaticShadowFamily.building:
      return _scaledProjectionSpec(
        baseProjectionSpec,
        lengthRatioScale: 1.25,
        nearWidthMultiplierScale: 1.05,
        farWidthMultiplierScale: 0.98,
      );
    case StaticShadowFamily.foliage:
      return _scaledProjectionSpec(
        baseProjectionSpec,
        lengthRatioScale: 1.05,
        nearWidthMultiplierScale: 1.15,
        farWidthMultiplierScale: 1.28,
      );
  }
}

StaticShadowProjectionSpec _scaledProjectionSpec(
  StaticShadowProjectionSpec baseProjectionSpec, {
  required double lengthRatioScale,
  required double nearWidthMultiplierScale,
  required double farWidthMultiplierScale,
}) {
  return StaticShadowProjectionSpec(
    directionX: baseProjectionSpec.directionX,
    directionY: baseProjectionSpec.directionY,
    lengthRatio: baseProjectionSpec.lengthRatio * lengthRatioScale,
    nearWidthMultiplier:
        baseProjectionSpec.nearWidthMultiplier * nearWidthMultiplierScale,
    farWidthMultiplier:
        baseProjectionSpec.farWidthMultiplier * farWidthMultiplierScale,
  );
}
```

### `packages/map_core/test/shadow/static_shadow_family_projection_test.dart`

```dart
import 'dart:math' as math;

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('resolveStaticShadowFamily', () {
    test('uses generic projection when no family is provided', () {
      expect(
        resolveStaticShadowFamily(),
        StaticShadowFamily.genericProjection,
      );
    });

    test('uses element family when no override family is provided', () {
      expect(
        resolveStaticShadowFamily(
          elementFamily: StaticShadowFamily.building,
        ),
        StaticShadowFamily.building,
      );
    });

    test('uses override family over element family', () {
      expect(
        resolveStaticShadowFamily(
          elementFamily: StaticShadowFamily.building,
          overrideFamily: StaticShadowFamily.tallProp,
        ),
        StaticShadowFamily.tallProp,
      );
    });
  });

  group('resolveStaticShadowFamilyProjectionSpec', () {
    test('genericProjection returns the base projection unchanged', () {
      final base = StaticShadowProjectionSpec(
        directionX: -1,
        directionY: 0.5,
        lengthRatio: 0.4,
        nearWidthMultiplier: 0.9,
        farWidthMultiplier: 1.1,
      );

      expect(
        resolveStaticShadowFamilyProjectionSpec(
          family: StaticShadowFamily.genericProjection,
          baseProjectionSpec: base,
        ),
        base,
      );
    });

    test('preserves base direction for every non-generic family', () {
      final base = StaticShadowProjectionSpec(
        directionX: -0.75,
        directionY: 0.35,
        lengthRatio: 0.32,
        nearWidthMultiplier: 0.92,
        farWidthMultiplier: 1.18,
      );

      for (final family in <StaticShadowFamily>[
        StaticShadowFamily.compactProp,
        StaticShadowFamily.tallProp,
        StaticShadowFamily.building,
        StaticShadowFamily.foliage,
      ]) {
        final spec = resolveStaticShadowFamilyProjectionSpec(
          family: family,
          baseProjectionSpec: base,
        );

        expect(spec.directionX, base.directionX);
        expect(spec.directionY, base.directionY);
      }
    });

    test('compact props are shorter and tighter than generic projection', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.compactProp,
      );

      expect(
        spec.lengthRatio,
        lessThan(defaultStaticShadowProjectionSpec.lengthRatio),
      );
      expect(
        spec.nearWidthMultiplier,
        lessThan(defaultStaticShadowProjectionSpec.nearWidthMultiplier),
      );
      expect(
        spec.farWidthMultiplier,
        lessThan(defaultStaticShadowProjectionSpec.farWidthMultiplier),
      );
    });

    test('tall props are narrow and still project farther than generic', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.tallProp,
      );

      expect(
        spec.lengthRatio,
        greaterThan(defaultStaticShadowProjectionSpec.lengthRatio),
      );
      expect(
        spec.nearWidthMultiplier,
        lessThan(defaultStaticShadowProjectionSpec.nearWidthMultiplier),
      );
      expect(
        spec.farWidthMultiplier,
        lessThan(defaultStaticShadowProjectionSpec.farWidthMultiplier),
      );
    });

    test('buildings keep a broad block-like projection', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.building,
      );

      expect(
        spec.lengthRatio,
        greaterThan(defaultStaticShadowProjectionSpec.lengthRatio),
      );
      expect(
        spec.nearWidthMultiplier,
        greaterThan(defaultStaticShadowProjectionSpec.nearWidthMultiplier),
      );
      expect(
        spec.farWidthMultiplier,
        lessThan(defaultStaticShadowProjectionSpec.farWidthMultiplier),
      );
    });

    test('foliage is broader than tall prop', () {
      final foliage = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.foliage,
      );
      final tallProp = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.tallProp,
      );

      expect(
        foliage.nearWidthMultiplier,
        greaterThan(tallProp.nearWidthMultiplier),
      );
      expect(
        foliage.farWidthMultiplier,
        greaterThan(tallProp.farWidthMultiplier),
      );
    });

    test('compactProp V0 constants are stable', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.compactProp,
      );

      expect(spec.lengthRatio, closeTo(0.2304, 0.0000001));
      expect(spec.nearWidthMultiplier, closeTo(0.7544, 0.0000001));
      expect(spec.farWidthMultiplier, closeTo(0.9204, 0.0000001));
    });

    test('tallProp V0 constants are stable', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.tallProp,
      );

      expect(spec.lengthRatio, closeTo(0.3776, 0.0000001));
      expect(spec.nearWidthMultiplier, closeTo(0.4784, 0.0000001));
      expect(spec.farWidthMultiplier, closeTo(0.6844, 0.0000001));
    });

    test('building V0 constants are stable', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.building,
      );

      expect(spec.lengthRatio, closeTo(0.4, 0.0000001));
      expect(spec.nearWidthMultiplier, closeTo(0.966, 0.0000001));
      expect(spec.farWidthMultiplier, closeTo(1.1564, 0.0000001));
    });

    test('foliage V0 constants are stable', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.foliage,
      );

      expect(spec.lengthRatio, closeTo(0.336, 0.0000001));
      expect(spec.nearWidthMultiplier, closeTo(1.058, 0.0000001));
      expect(spec.farWidthMultiplier, closeTo(1.5104, 0.0000001));
    });

    test('scaled family specs remain valid for a custom positive base', () {
      final base = StaticShadowProjectionSpec(
        directionX: 1,
        directionY: 0.45,
        lengthRatio: 0.1,
        nearWidthMultiplier: 0.2,
        farWidthMultiplier: 0.3,
      );

      for (final family in StaticShadowFamily.values) {
        final spec = resolveStaticShadowFamilyProjectionSpec(
          family: family,
          baseProjectionSpec: base,
        );

        expect(spec.directionX.isFinite, isTrue);
        expect(spec.directionY.isFinite, isTrue);
        expect(spec.lengthRatio, greaterThan(0));
        expect(spec.nearWidthMultiplier, greaterThan(0));
        expect(spec.farWidthMultiplier, greaterThan(0));
      }
    });
  });

  group('family projection geometry composition', () {
    test('tall prop polygon stays much narrower than building polygon', () {
      final tall = _projectedCase(
        family: StaticShadowFamily.tallProp,
        visualWidth: 16,
        visualHeight: 64,
        footprintWidthRatio: 0.18,
        footprintHeightRatio: 0.07,
      );
      final building = _projectedCase(
        family: StaticShadowFamily.building,
        visualWidth: 96,
        visualHeight: 80,
        footprintWidthRatio: 0.82,
        footprintHeightRatio: 0.12,
      );

      expect(_maxWidth(tall), lessThan(_maxWidth(building) * 0.45));
      expect(_polygonArea(tall), lessThan(_polygonArea(building) * 0.45));
    });

    test('compact prop projects less area than generic for same metrics', () {
      final compact = _projectedCase(
        family: StaticShadowFamily.compactProp,
        visualWidth: 72,
        visualHeight: 48,
        footprintWidthRatio: 0.72,
        footprintHeightRatio: 0.10,
      );
      final generic = _projectedCase(
        family: StaticShadowFamily.genericProjection,
        visualWidth: 72,
        visualHeight: 48,
        footprintWidthRatio: 0.72,
        footprintHeightRatio: 0.10,
      );

      expect(_polygonArea(compact), lessThan(_polygonArea(generic)));
    });
  });
}

ProjectedStaticShadowGeometry _projectedCase({
  required StaticShadowFamily family,
  required double visualWidth,
  required double visualHeight,
  required double footprintWidthRatio,
  required double footprintHeightRatio,
}) {
  final metrics = StaticShadowVisualMetrics(
    left: 0,
    top: 0,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
  );
  final baseGeometry = resolveStaticShadowGeometry(
    metrics: metrics,
    shadowConfig: ResolvedShadowConfig(
      shadowProfileId: 'default-ground-soft-ellipse',
      mode: ShadowCasterMode.ellipse,
      renderPass: ShadowRenderPass.groundStatic,
      offsetX: 0,
      offsetY: 0,
      scaleX: 1,
      scaleY: 1,
      opacity: 0.3,
      colorHexRgb: '000000',
      softnessMode: ShadowSoftnessMode.hardEdge,
    ),
    elementFootprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 1,
      footprintWidthRatio: footprintWidthRatio,
      footprintHeightRatio: footprintHeightRatio,
    ),
  );

  return resolveProjectedStaticShadowGeometry(
    baseGeometry: baseGeometry,
    metrics: metrics,
    projectionSpec: resolveStaticShadowFamilyProjectionSpec(family: family),
  );
}

double _maxWidth(ProjectedStaticShadowGeometry geometry) {
  return [
    _distance(geometry.nearLeft, geometry.nearRight),
    _distance(geometry.farLeft, geometry.farRight),
  ].reduce((first, second) => first > second ? first : second);
}

double _distance(
  ProjectedStaticShadowPoint first,
  ProjectedStaticShadowPoint second,
) {
  final dx = first.x - second.x;
  final dy = first.y - second.y;
  return math.sqrt(dx * dx + dy * dy);
}

double _polygonArea(ProjectedStaticShadowGeometry geometry) {
  final points = geometry.points;
  var area = 0.0;
  for (var i = 0; i < points.length; i += 1) {
    final current = points[i];
    final next = points[(i + 1) % points.length];
    area += current.x * next.y - next.x * current.y;
  }
  return area.abs() / 2;
}
```

### `packages/map_core/lib/map_core.dart`

```dart
library map_core;

export 'src/models/enums.dart';
export 'src/models/geometry.dart';
export 'src/models/tileset.dart';
export 'src/models/tileset_transparent_color.dart';
export 'src/models/map_data.dart';
export 'src/models/element_collision_profile.dart';
export 'src/models/environment.dart';
export 'src/models/map_entity_payloads.dart';
export 'src/models/map_entity_editor_visual.dart';
export 'src/models/map_gameplay_zone_payloads.dart';
export 'src/models/map_layer.dart';
export 'src/models/map_metadata.dart';
export 'src/models/path_center_pattern.dart';
export 'src/models/project_path_pattern_preset.dart';
export 'src/models/project_manifest.dart';
export 'src/models/save_data.dart';
export 'src/models/game_state.dart';
export 'src/models/pokemon_move.dart';
export 'src/models/pokemon_move_accuracy.dart';
export 'src/models/pokemon_move_effect.dart';
export 'src/models/script_asset.dart';
export 'src/models/script_conditions.dart';
export 'src/models/map_event_definition.dart';
export 'src/models/project_trainer.dart';
export 'src/models/scenario_asset.dart';
export 'src/models/visual_frame_json.dart';
export 'src/models/shadow.dart';
export 'src/models/shadow_catalog.dart';
export 'src/models/surface.dart';
export 'src/models/surface_catalog.dart';
export 'src/operations/map_resize.dart';
export 'src/operations/map_paint.dart';
export 'src/operations/map_collision.dart';
export 'src/operations/map_path.dart';
export 'src/operations/map_terrain.dart';
export 'src/operations/map_terrain_autotile.dart';
export 'src/operations/terrain_preset_subtile_for_map_cell.dart';
export 'src/operations/terrain_preset_variant_pick.dart';
export 'src/operations/path_center_pattern_resolver.dart';
export 'src/operations/path_pattern_visual_resolution.dart';
export 'src/operations/project_path_preset_center_pattern_adapter.dart';
export 'src/operations/project_element_shadow_config_json_codec.dart';
export 'src/operations/project_manifest_shadow_catalog_operations.dart';
export 'src/operations/project_path_pattern_preset_json_codec.dart';
export 'src/operations/project_shadow_catalog_json_codec.dart';
export 'src/operations/project_shadow_profile_json_codec.dart';
export 'src/operations/static_shadow_family_json_codec.dart';
export 'src/operations/static_shadow_footprint_config_json_codec.dart';
export 'src/operations/project_json_migrations.dart';
export 'src/operations/default_shadow_profiles.dart';
export 'src/operations/tile_visual_frame_timeline.dart';
export 'src/operations/tile_visual_frame_vertical_atlas.dart';
export 'src/operations/path_variant_vertical_atlas_mapping.dart';
export 'src/operations/path_preset_vertical_atlas_builder.dart';
export 'src/operations/terrain_path_variant_vertical_atlas_layout.dart';
export 'src/operations/standard_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_water_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_lava_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_ice_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_tall_grass_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_surface_preset_builder.dart';
export 'src/operations/surface_catalog_diagnostics.dart';
export 'src/operations/surface_catalog_authoring_diagnostics.dart';
export 'src/operations/surface_catalog_diagnostics_summary.dart';
export 'src/operations/surface_catalog_diagnostics_presentation.dart';
export 'src/operations/static_shadow_geometry.dart';
export 'src/operations/static_shadow_family_projection.dart';
export 'src/operations/static_shadow_projection_geometry.dart';
export 'src/operations/surface_atlas_json_codec.dart';
export 'src/operations/surface_animation_frame_json_codec.dart';
export 'src/operations/surface_animation_timeline_json_codec.dart';
export 'src/operations/project_surface_animation_json_codec.dart';
export 'src/operations/surface_variant_animation_ref_json_codec.dart';
export 'src/operations/surface_variant_animation_ref_set_json_codec.dart';
export 'src/operations/project_surface_preset_json_codec.dart';
export 'src/operations/project_surface_catalog_json_codec.dart';
export 'src/operations/project_manifest_surface_catalog_operations.dart';
export 'src/operations/project_manifest_path_pattern_preset_operations.dart';
export 'src/operations/surface_studio_read_model.dart';
export 'src/operations/tall_grass_authoring_view.dart';
export 'src/operations/path_animation_rules.dart';
export 'src/operations/element_collision_mask_codec.dart';
export 'src/collision/pixel_rect.dart';
export 'src/collision/player_collision_conventions_v1.dart';
export 'src/operations/map_layers.dart';
export 'src/operations/environment_layer_content_json_codec.dart';
export 'src/operations/environment_preset_json_codec.dart';
export 'src/operations/project_manifest_environment_preset_operations.dart';
export 'src/operations/environment_preset_diagnostics.dart';
export 'src/operations/environment_layer_usage_diagnostics.dart';
export 'src/operations/environment_authoring_diagnostics.dart';
export 'src/operations/shadow_authoring_diagnostics.dart';
export 'src/operations/shadow_config_resolver.dart';
export 'src/operations/surface_layer_placements.dart';
export 'src/operations/surface_to_gameplay_zone_generation_assessment.dart';
export 'src/operations/surface_to_gameplay_zone_generation_plan.dart';
export 'src/operations/surface_variant_role_resolver.dart';
export 'src/operations/map_connections.dart';
export 'src/operations/map_entities.dart';
export 'src/operations/map_events.dart';
export 'src/operations/map_placed_elements.dart';
export 'src/operations/map_placed_element_animation.dart';
export 'src/operations/map_placed_element_shadow_override_json_codec.dart';
export 'src/operations/map_entity_collision_footprint.dart';
export 'src/operations/map_triggers.dart';
export 'src/operations/map_warps.dart';
export 'src/operations/map_gameplay_zones.dart';
export 'src/operations/map_map_metadata.dart';
export 'src/operations/game_state_persistence.dart';
export 'src/operations/tileset_library_tree.dart';
export 'src/operations/dialogue_library_tree.dart';
export 'src/operations/project_dialogue_refs.dart';
export 'src/validation/validators.dart';
export 'src/validation/dialogue_validation.dart';
export 'src/validation/entity_editor_visual_validation.dart';
export 'src/exceptions/map_exceptions.dart';
```

## 26. Diffs complets ou equivalents /dev/null pour fichiers crees

### `packages/map_core/lib/map_core.dart`

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index d468dcca..a3d2c92d 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -66,6 +66,7 @@ export 'src/operations/surface_catalog_authoring_diagnostics.dart';
 export 'src/operations/surface_catalog_diagnostics_summary.dart';
 export 'src/operations/surface_catalog_diagnostics_presentation.dart';
 export 'src/operations/static_shadow_geometry.dart';
+export 'src/operations/static_shadow_family_projection.dart';
 export 'src/operations/static_shadow_projection_geometry.dart';
 export 'src/operations/surface_atlas_json_codec.dart';
 export 'src/operations/surface_animation_frame_json_codec.dart';
```

### `packages/map_core/lib/src/operations/static_shadow_family_projection.dart`

Equivalent `/dev/null` : fichier nouveau, contenu complet fourni en section 25.

### `packages/map_core/test/shadow/static_shadow_family_projection_test.dart`

Equivalent `/dev/null` : fichier nouveau, contenu complet fourni en section 25.
