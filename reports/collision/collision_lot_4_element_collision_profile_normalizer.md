# Collision Lot 4 — Element Collision Profile Normalizer V0

## 1. Résumé exécutif

Collision-4 ajoute la première brique pure de normalisation collision dans `map_core`.

Verdict court :

- `normalizeElementCollisionProfile(...)` est créé dans `packages/map_core/lib/src/operations/element_collision_profile_normalizer.dart`.
- L'API est exportée par `packages/map_core/lib/map_core.dart`, comme les autres opérations publiques.
- Les tests `map_core` couvrent `collisionMask`, `cells`, `shapeCells`, `manualAddedCells`, `manualRemovedCells`, `visualMask`, `occlusionMask`, ordre stable, validation `tileSize` et absence de mutation.
- Aucun branchement editor, gameplay, runtime ou manifest n'est réalisé dans ce lot.

## 2. Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte au début du lot dans le worktree :

```text
```

Interprétation :

- Worktree Collision-4 propre au départ.
- Branche active : `collision-source-of-truth-worktree`.

## 3. Rapports précédents relus

Rapports relus :

```text
/Users/karim/Project/pokemonProject/reports/collision/collision_system_audit_v0.md
/Users/karim/Project/pokemonProject/reports/collision/collision_lot_2_source_of_truth_implementation_plan.md
reports/collision/collision_lot_3_red_tests_triage.md
```

Note de provenance :

- `collision_system_audit_v0.md` et `collision_lot_2_source_of_truth_implementation_plan.md` existent dans le workspace principal et étaient absents de ce worktree frais.
- `collision_lot_3_red_tests_triage.md` existe dans ce worktree grâce au commit Collision-3.

Contrats repris :

- `collisionMask` gagne contre `cells`.
- `pixelMask` reste le nom JSON historique de `collisionMask`.
- `cells` reste projection legacy, fallback et debug coarse.
- `shapeCells`, `manualAddedCells`, `manualRemovedCells` portent l'intention auteur coarse.
- `visualMask` et `occlusionMask` ne créent jamais de collision.
- La normalisation pure appartient à `map_core`; les branchements editor/gameplay restent pour Collision-6 et Collision-7.

## 4. Audit ciblé map_core

Fichiers inspectés :

```text
packages/map_core/lib/src/models/element_collision_profile.dart
packages/map_core/lib/src/operations/element_collision_mask_codec.dart
packages/map_core/lib/src/exceptions/map_exceptions.dart
packages/map_core/lib/map_core.dart
packages/map_core/test/element_collision_mask_codec_test.dart
packages/map_core/test/element_collision_profile_model_test.dart
packages/map_core/test/element_collision_profile_pixel_mask_json_test.dart
```

Signature réelle de projection mask -> cells :

```dart
static List<GridPos> cellsFromPixelMask({
  required ElementCollisionPixelMask mask,
  required int tileWidth,
  required int tileHeight,
  required int sourceWidthInTiles,
  required int sourceHeightInTiles,
  double minimumSolidRatioPerCell = 0.01,
})
```

Exception de validation disponible :

```dart
class ValidationException extends MapException {
  const ValidationException(super.message);
}
```

Convention d'export :

- `packages/map_core/lib/map_core.dart` exporte déjà les opérations publiques sous `src/operations`.
- `element_collision_mask_codec.dart` est déjà exporté.
- Le normalizer est donc exporté juste après `element_collision_mask_codec.dart`.

Tests existants à compléter sans les modifier :

- `element_collision_mask_codec_test.dart` teste déjà `cellsFromPixelMask`.
- `element_collision_profile_model_test.dart` teste la sérialisation profil et defaults legacy.
- `element_collision_profile_pixel_mask_json_test.dart` teste `pixelMask`, `visualMask`, `occlusionMask` et les vieux payloads non-map.

## 5. Design retenu

Design retenu :

- API libre de tout contexte projet : elle prend un `ElementCollisionProfile` et un `tileSize`.
- Aucune dépendance Flutter, Flame, editor, gameplay ou runtime.
- Aucune lecture d'image.
- Aucune mutation du profil d'entrée.
- Aucun accès fichier.
- Aucun changement de JSON.
- Aucun nouveau modèle V2.

Calcul des dimensions de projection :

- `ElementCollisionMaskCodec.cellsFromPixelMask(...)` demande `sourceWidthInTiles` et `sourceHeightInTiles`.
- Le normalizer les dérive depuis les dimensions pixel du mask :

```text
sourceWidthInTiles = ceil(collisionMask.widthPx / tileSize)
sourceHeightInTiles = ceil(collisionMask.heightPx / tileSize)
```

Raison :

- L'API Collision-4 ne reçoit pas `TilesetSourceRect`.
- Le mask local porte déjà ses dimensions pixel.
- Le `tileSize` fournit la granularité de projection legacy.

## 6. API ajoutée

Fichier :

```text
packages/map_core/lib/src/operations/element_collision_profile_normalizer.dart
```

API :

```dart
ElementCollisionProfile normalizeElementCollisionProfile(
  ElementCollisionProfile profile, {
  required int tileSize,
})
```

Export public ajouté :

```dart
export 'src/operations/element_collision_profile_normalizer.dart';
```

## 7. Règles de normalisation

### `tileSize`

Règle :

- `tileSize` doit être strictement positif.
- Si `tileSize <= 0`, la fonction lance `ValidationException`.

### Si `collisionMask` existe

Règle :

- `collisionMask` gagne toujours.
- `cells` devient la projection de `collisionMask`.
- `visualMask` est conservé.
- `occlusionMask` est conservé.
- `shapeCells`, `manualAddedCells`, `manualRemovedCells` sont conservés comme intention auteur.

Projection :

```text
cells = ElementCollisionMaskCodec.cellsFromPixelMask(
  mask: collisionMask,
  tileWidth: tileSize,
  tileHeight: tileSize,
  sourceWidthInTiles: ceil(mask.widthPx / tileSize),
  sourceHeightInTiles: ceil(mask.heightPx / tileSize),
)
```

### Si `collisionMask` est absent

Règle legacy V0 :

```text
base =
  shapeCells si shapeCells non vide
  sinon manualAddedCells si manualAddedCells non vide
  sinon cells existants

résultat = base + manualAddedCells - manualRemovedCells
```

La combinaison utilise un `Set<GridPos>` logique pour éviter les doublons.

Si aucune intention auteur legacy n'existe :

```text
shapeCells = []
manualAddedCells = []
manualRemovedCells = []
```

alors le profil est retourné inchangé.

### Ordre stable

Les cellules reconstruites sont triées :

```text
y croissant, puis x croissant
```

### `visualMask` et `occlusionMask`

Règle :

- `visualMask` ne crée pas de `cells`.
- `occlusionMask` ne crée pas de `cells`.
- Ces masks sont conservés si présents.

## 8. Fichiers créés

```text
packages/map_core/lib/src/operations/element_collision_profile_normalizer.dart
packages/map_core/test/element_collision_profile_normalizer_test.dart
reports/collision/collision_lot_4_element_collision_profile_normalizer.md
```

## 9. Fichiers modifiés

```text
packages/map_core/lib/map_core.dart
```

Modification :

- ajout de l'export public du normalizer.

## 10. Fichiers explicitement non modifiés

```text
packages/map_core/lib/src/models/element_collision_profile.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_editor/**
packages/map_gameplay/**
packages/map_runtime/**
packages/map_battle/**
examples/**
```

Production non `map_core` :

```text
Aucun fichier modifié
```

Generated/build_runner :

```text
Aucun fichier modifié
```

## 11. Tests ajoutés

Fichier :

```text
packages/map_core/test/element_collision_profile_normalizer_test.dart
```

Tests ajoutés :

1. `collisionMask wins over contradictory legacy cells`
2. `collisionMask preserves visualMask and occlusionMask`
3. `visualMask does not create collision cells`
4. `occlusionMask does not create collision cells`
5. `legacy manualAddedCells rebuild cells when shapeCells is empty`
6. `legacy shapeCells plus manualAddedCells minus manualRemovedCells`
7. `keeps cells unchanged when no legacy authoring intent exists`
8. `sorts rebuilt legacy cells by y then x`
9. `rejects non-positive tileSize`
10. `does not mutate original profile`

RED observé avant production :

```text
Failed to load "test/element_collision_profile_normalizer_test.dart":
test/element_collision_profile_normalizer_test.dart:26:26: Error: Method not found: 'normalizeElementCollisionProfile'.
...
00:00 +0 -1: Some tests failed.
```

## 12. Commandes lancées

Audit :

```bash
git status --short --untracked-files=all
rg -n "ElementCollisionProfile|ElementCollisionPixelMask|cellsFromPixelMask|manualAddedCells|manualRemovedCells|shapeCells|pixelMask|collisionMask|occlusionMask|visualMask|ValidationException" packages/map_core/lib packages/map_core/test
rg -n "export 'src/operations" packages/map_core/lib/map_core.dart
```

TDD RED :

```bash
cd packages/map_core
dart test test/element_collision_profile_normalizer_test.dart
```

Format :

```bash
dart format packages/map_core/lib/src/operations/element_collision_profile_normalizer.dart packages/map_core/test/element_collision_profile_normalizer_test.dart packages/map_core/lib/map_core.dart
```

Tests et analyse :

```bash
cd packages/map_core
dart test test/element_collision_profile_normalizer_test.dart
```

```bash
cd packages/map_core
dart test test/element_collision_profile_normalizer_test.dart test/element_collision_mask_codec_test.dart test/element_collision_profile_model_test.dart test/element_collision_profile_pixel_mask_json_test.dart
```

```bash
cd packages/map_core
dart test --reporter json > /tmp/collision4_map_core_test.json
```

```bash
cd packages/map_core
dart test --reporter compact > /tmp/collision4_map_core_compact.txt 2>&1
```

```bash
cd packages/map_core
dart analyze lib/map_core.dart lib/src/operations/element_collision_profile_normalizer.dart test/element_collision_profile_normalizer_test.dart
```

Périmètre :

```bash
git status --short --untracked-files=all
git diff --name-only
git diff --stat
```

## 13. Résultats des tests ciblés

Commande :

```bash
cd packages/map_core
dart test test/element_collision_profile_normalizer_test.dart
```

Sortie utile après implémentation :

```text
00:00 +0: normalizeElementCollisionProfile collisionMask wins over contradictory legacy cells
00:00 +1: normalizeElementCollisionProfile collisionMask preserves visualMask and occlusionMask
00:00 +2: normalizeElementCollisionProfile visualMask does not create collision cells
00:00 +3: normalizeElementCollisionProfile occlusionMask does not create collision cells
00:00 +4: normalizeElementCollisionProfile legacy manualAddedCells rebuild cells when shapeCells is empty
00:00 +5: normalizeElementCollisionProfile legacy shapeCells plus manualAddedCells minus manualRemovedCells
00:00 +6: normalizeElementCollisionProfile keeps cells unchanged when no legacy authoring intent exists
00:00 +7: normalizeElementCollisionProfile sorts rebuilt legacy cells by y then x
00:00 +8: normalizeElementCollisionProfile rejects non-positive tileSize
00:00 +9: normalizeElementCollisionProfile does not mutate original profile
00:00 +10: All tests passed!
```

## 14. Résultats des tests groupés / globaux

Commande groupée :

```bash
cd packages/map_core
dart test test/element_collision_profile_normalizer_test.dart test/element_collision_mask_codec_test.dart test/element_collision_profile_model_test.dart test/element_collision_profile_pixel_mask_json_test.dart
```

Sortie utile :

```text
00:00 +20: All tests passed!
```

Commande globale JSON :

```bash
cd packages/map_core
dart test --reporter json > /tmp/collision4_map_core_test.json
```

Résumé extrait :

```text
DONE success=true tests=1626 skipped=0 hidden=108
```

Commande globale compact :

```bash
cd packages/map_core
dart test --reporter compact > /tmp/collision4_map_core_compact.txt 2>&1
```

Ligne finale exacte nettoyée des codes ANSI :

```text
00:02 +1518: All tests passed!
```

## 15. Analyse statique / format

Format :

```bash
dart format packages/map_core/lib/src/operations/element_collision_profile_normalizer.dart packages/map_core/test/element_collision_profile_normalizer_test.dart packages/map_core/lib/map_core.dart
```

Sortie exacte :

```text
Formatted packages/map_core/test/element_collision_profile_normalizer_test.dart
Formatted 3 files (1 changed) in 0.01 seconds.
```

Analyse :

```bash
cd packages/map_core
dart analyze lib/map_core.dart lib/src/operations/element_collision_profile_normalizer.dart test/element_collision_profile_normalizer_test.dart
```

Sortie exacte :

```text
Analyzing map_core.dart, element_collision_profile_normalizer.dart, element_collision_profile_normalizer_test.dart...
No issues found!
```

## 16. Vérification du périmètre

Commande :

```bash
git diff --name-only
```

Sortie exacte avant création du rapport :

```text
packages/map_core/lib/map_core.dart
```

Explication :

- Les deux nouveaux fichiers `map_core` sont non suivis et apparaissent dans `git status`.
- `git diff --name-only` ne liste que le fichier tracked modifié.

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte avant création du rapport :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/element_collision_profile_normalizer.dart
?? packages/map_core/test/element_collision_profile_normalizer_test.dart
```

Périmètre respecté :

- Aucun fichier `packages/map_editor/**`.
- Aucun fichier `packages/map_gameplay/**`.
- Aucun fichier `packages/map_runtime/**`.
- Aucun fichier `packages/map_battle/**`.
- Aucun fichier `examples/**`.
- Aucun fichier generated.

## 17. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/element_collision_profile_normalizer.dart
?? packages/map_core/test/element_collision_profile_normalizer_test.dart
?? reports/collision/collision_lot_4_element_collision_profile_normalizer.md
```

Inventaire final :

| Catégorie | Fichiers |
|---|---|
| Créés par Collision-4 | `packages/map_core/lib/src/operations/element_collision_profile_normalizer.dart`, `packages/map_core/test/element_collision_profile_normalizer_test.dart`, `reports/collision/collision_lot_4_element_collision_profile_normalizer.md` |
| Modifiés par Collision-4 | `packages/map_core/lib/map_core.dart` |
| Supprimés | Aucun |
| Generated modifiés | Aucun |
| Hors périmètre modifié | Aucun |

## 18. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie exacte avant création du rapport :

```text
 packages/map_core/lib/map_core.dart | 1 +
 1 file changed, 1 insertion(+)
```

Note :

- Les fichiers non suivis sont listés dans `git status`, pas dans `git diff --stat`.

## 19. Risques / réserves

| Risque | État Collision-4 | Suite |
|---|---|---|
| Le normalizer n'est pas encore branché dans la persistance editor | Volontaire | Collision-6 |
| Les skips Collision-3 restent skips | Volontaire | Collision-6 / Collision-7 |
| La projection depuis `collisionMask` dérive les dimensions en tiles depuis `mask.widthPx/heightPx` | Documenté | Collision-5 peut ajouter des tests de projection avancés |
| `cells` inchangé sans intention auteur | Volontaire pour éviter une migration trop magique | Collision-5 peut élargir si besoin |
| `manualRemovedCells` sans shape/manualAdded retire depuis `cells` existants | Conforme à la règle base fallback cells | À conserver par tests si utilisé |

## 20. Préparation de Collision-5 / Collision-6 / Collision-7

Collision-5 :

- peut renforcer les tests de projection `collisionMask -> cells`;
- peut documenter la politique de `sourceWidthInTiles/sourceHeightInTiles` pour masks non alignés tile.

Collision-6 :

- pourra appeler `normalizeElementCollisionProfile(...)` depuis `FileProjectRepository.loadProject()`;
- pourra retirer le skip repository Collision-3.

Collision-7 :

- pourra durcir les tests gameplay en injectant des profils normalisés;
- pourra retirer les skips gameplay Collision-3 sans ajouter de migration complexe dans `GameplayWorldState`.

## 21. Auto-review finale

| Question | Réponse |
|---|---|
| Ai-je créé le normalizer dans map_core uniquement ? | Oui. |
| Ai-je évité toute modification map_editor production ? | Oui. |
| Ai-je évité toute modification map_gameplay production ? | Oui. |
| Ai-je évité toute modification map_runtime production ? | Oui. |
| Ai-je évité ProjectManifest ? | Oui. |
| Ai-je évité build_runner/generated ? | Oui. |
| Ai-je conservé pixelMask comme nom JSON historique ? | Oui, aucun changement JSON. |
| Ai-je fait gagner collisionMask contre cells ? | Oui, test dédié. |
| Ai-je empêché visualMask de créer de la collision ? | Oui, test dédié. |
| Ai-je empêché occlusionMask de créer de la collision ? | Oui, test dédié. |
| Ai-je testé manualAddedCells/manualRemovedCells ? | Oui. |
| Ai-je produit un ordre stable ? | Oui, y puis x. |
| Ai-je relancé les tests ciblés ? | Oui. |
| Ai-je documenté les risques ? | Oui. |

## 22. Contenu complet des fichiers créés/modifiés

### `packages/map_core/lib/src/operations/element_collision_profile_normalizer.dart`

```dart
import '../exceptions/map_exceptions.dart';
import '../models/element_collision_profile.dart';
import '../models/geometry.dart';
import 'element_collision_mask_codec.dart';

ElementCollisionProfile normalizeElementCollisionProfile(
  ElementCollisionProfile profile, {
  required int tileSize,
}) {
  _validateTileSize(tileSize);

  final collisionMask = profile.collisionMask;
  if (collisionMask != null) {
    return profile.copyWith(
      cells: _sortedCells(
        ElementCollisionMaskCodec.cellsFromPixelMask(
          mask: collisionMask,
          tileWidth: tileSize,
          tileHeight: tileSize,
          sourceWidthInTiles: _ceilDiv(collisionMask.widthPx, tileSize),
          sourceHeightInTiles: _ceilDiv(collisionMask.heightPx, tileSize),
        ),
      ),
    );
  }

  final legacyCells = _normalizeLegacyCells(profile);
  if (legacyCells == null) {
    return profile;
  }

  return profile.copyWith(cells: legacyCells);
}

void _validateTileSize(int tileSize) {
  if (tileSize <= 0) {
    throw ValidationException(
      'Element collision profile tileSize must be strictly positive, got $tileSize',
    );
  }
}

List<GridPos>? _normalizeLegacyCells(ElementCollisionProfile profile) {
  final hasAuthoringIntent = profile.shapeCells.isNotEmpty ||
      profile.manualAddedCells.isNotEmpty ||
      profile.manualRemovedCells.isNotEmpty;
  if (!hasAuthoringIntent) {
    return null;
  }

  final cells = <GridPos>{};
  if (profile.shapeCells.isNotEmpty) {
    cells.addAll(profile.shapeCells);
  } else if (profile.manualAddedCells.isNotEmpty) {
    cells.addAll(profile.manualAddedCells);
  } else {
    cells.addAll(profile.cells);
  }

  cells.addAll(profile.manualAddedCells);
  cells.removeAll(profile.manualRemovedCells);
  return _sortedCells(cells);
}

List<GridPos> _sortedCells(Iterable<GridPos> cells) {
  final sorted = cells.toList(growable: false);
  sorted.sort((a, b) {
    final y = a.y.compareTo(b.y);
    if (y != 0) {
      return y;
    }
    return a.x.compareTo(b.x);
  });
  return sorted;
}

int _ceilDiv(int value, int divisor) {
  if (value <= 0) {
    return 0;
  }
  return (value + divisor - 1) ~/ divisor;
}
```

### `packages/map_core/test/element_collision_profile_normalizer_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeElementCollisionProfile', () {
    test('collisionMask wins over contradictory legacy cells', () {
      final mask = _mask(
        widthPx: 4,
        heightPx: 4,
        solidPixels: _pixels(
          widthPx: 4,
          heightPx: 4,
          solidPoints: const [GridPos(x: 0, y: 2)],
        ),
      );
      final profile = ElementCollisionProfile(
        collisionMask: mask,
        cells: const [
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
        ],
      );

      final normalized = normalizeElementCollisionProfile(
        profile,
        tileSize: 2,
      );

      expect(normalized.collisionMask, same(mask));
      expect(normalized.cells, const [GridPos(x: 0, y: 1)]);
    });

    test('collisionMask preserves visualMask and occlusionMask', () {
      final collision = _solidMask(widthPx: 2, heightPx: 2);
      final visual = _solidMask(widthPx: 4, heightPx: 4);
      final occlusion = _solidMask(widthPx: 6, heightPx: 6);
      final profile = ElementCollisionProfile(
        collisionMask: collision,
        visualMask: visual,
        occlusionMask: occlusion,
        cells: const [GridPos(x: 3, y: 3)],
      );

      final normalized = normalizeElementCollisionProfile(
        profile,
        tileSize: 2,
      );

      expect(normalized.visualMask, same(visual));
      expect(normalized.occlusionMask, same(occlusion));
      expect(normalized.collisionMask, same(collision));
      expect(normalized.cells, const [GridPos(x: 0, y: 0)]);
    });

    test('visualMask does not create collision cells', () {
      final profile = ElementCollisionProfile(
        visualMask: _solidMask(widthPx: 4, heightPx: 4),
      );

      final normalized = normalizeElementCollisionProfile(
        profile,
        tileSize: 2,
      );

      expect(normalized.cells, isEmpty);
    });

    test('occlusionMask does not create collision cells', () {
      final profile = ElementCollisionProfile(
        occlusionMask: _solidMask(widthPx: 4, heightPx: 4),
      );

      final normalized = normalizeElementCollisionProfile(
        profile,
        tileSize: 2,
      );

      expect(normalized.cells, isEmpty);
    });

    test('legacy manualAddedCells rebuild cells when shapeCells is empty', () {
      const manualAdded = [
        GridPos(x: 4, y: 5),
        GridPos(x: 0, y: 3),
        GridPos(x: 2, y: 4),
      ];
      final profile = ElementCollisionProfile(
        cells: _legacyFullCells(width: 6, height: 7),
        manualAddedCells: manualAdded,
      );

      final normalized = normalizeElementCollisionProfile(
        profile,
        tileSize: 16,
      );

      expect(
        normalized.cells,
        const [
          GridPos(x: 0, y: 3),
          GridPos(x: 2, y: 4),
          GridPos(x: 4, y: 5),
        ],
      );
      expect(normalized.manualAddedCells, manualAdded);
    });

    test('legacy shapeCells plus manualAddedCells minus manualRemovedCells',
        () {
      const profile = ElementCollisionProfile(
        shapeCells: [
          GridPos(x: 1, y: 0),
          GridPos(x: 0, y: 0),
        ],
        cells: [
          GridPos(x: 9, y: 9),
        ],
        manualAddedCells: [
          GridPos(x: 1, y: 1),
          GridPos(x: 0, y: 0),
        ],
        manualRemovedCells: [
          GridPos(x: 1, y: 0),
        ],
      );

      final normalized = normalizeElementCollisionProfile(
        profile,
        tileSize: 16,
      );

      expect(
        normalized.cells,
        const [
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 1),
        ],
      );
    });

    test('keeps cells unchanged when no legacy authoring intent exists', () {
      const profile = ElementCollisionProfile(
        cells: [
          GridPos(x: 2, y: 0),
          GridPos(x: 0, y: 0),
        ],
      );

      final normalized = normalizeElementCollisionProfile(
        profile,
        tileSize: 16,
      );

      expect(normalized.cells, profile.cells);
    });

    test('sorts rebuilt legacy cells by y then x', () {
      const profile = ElementCollisionProfile(
        manualAddedCells: [
          GridPos(x: 2, y: 2),
          GridPos(x: 1, y: 1),
          GridPos(x: 0, y: 1),
        ],
      );

      final normalized = normalizeElementCollisionProfile(
        profile,
        tileSize: 16,
      );

      expect(
        normalized.cells,
        const [
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 2),
        ],
      );
    });

    test('rejects non-positive tileSize', () {
      expect(
        () => normalizeElementCollisionProfile(
          const ElementCollisionProfile(),
          tileSize: 0,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('does not mutate original profile', () {
      final mask = _solidMask(widthPx: 2, heightPx: 2);
      final profile = ElementCollisionProfile(
        collisionMask: mask,
        cells: const [GridPos(x: 3, y: 3)],
      );
      final originalCells = profile.cells;

      final normalized = normalizeElementCollisionProfile(
        profile,
        tileSize: 2,
      );

      expect(identical(normalized, profile), isFalse);
      expect(profile.cells, originalCells);
      expect(normalized.cells, const [GridPos(x: 0, y: 0)]);
    });
  });
}

ElementCollisionPixelMask _solidMask({
  required int widthPx,
  required int heightPx,
}) {
  return _mask(
    widthPx: widthPx,
    heightPx: heightPx,
    solidPixels: List<bool>.filled(widthPx * heightPx, true),
  );
}

ElementCollisionPixelMask _mask({
  required int widthPx,
  required int heightPx,
  required List<bool> solidPixels,
}) {
  return ElementCollisionPixelMask(
    widthPx: widthPx,
    heightPx: heightPx,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: widthPx,
      heightPx: heightPx,
      solidPixels: solidPixels,
    ),
  );
}

List<bool> _pixels({
  required int widthPx,
  required int heightPx,
  required List<GridPos> solidPoints,
}) {
  final pixels = List<bool>.filled(widthPx * heightPx, false);
  for (final point in solidPoints) {
    pixels[point.y * widthPx + point.x] = true;
  }
  return pixels;
}

List<GridPos> _legacyFullCells({
  required int width,
  required int height,
}) {
  return [
    for (var y = 0; y < height; y++)
      for (var x = 0; x < width; x++) GridPos(x: x, y: y),
  ];
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
export 'src/operations/project_json_migrations.dart';
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
export 'src/operations/element_collision_profile_normalizer.dart';
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

Diff complet de `map_core.dart` :

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 80f3af11..1b84cb7c 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -76,6 +76,7 @@ export 'src/operations/surface_studio_read_model.dart';
 export 'src/operations/tall_grass_authoring_view.dart';
 export 'src/operations/path_animation_rules.dart';
 export 'src/operations/element_collision_mask_codec.dart';
+export 'src/operations/element_collision_profile_normalizer.dart';
 export 'src/collision/pixel_rect.dart';
 export 'src/collision/player_collision_conventions_v1.dart';
 export 'src/operations/map_layers.dart';
```
