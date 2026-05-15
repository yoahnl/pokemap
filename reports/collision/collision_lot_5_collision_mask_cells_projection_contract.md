# Collision Lot 5 — collisionMask -> cells Projection Contract V0

## 1. Résumé exécutif

Collision-5 verrouille le contrat de projection entre `ElementCollisionProfile.collisionMask`, `ElementCollisionMaskCodec.cellsFromPixelMask(...)` et `ElementCollisionProfile.cells`.

Verdict court : le code de production `map_core` était déjà cohérent avec le contrat attendu. Le lot ajoute donc des tests contractuels, sans modifier `element_collision_mask_codec.dart`, `element_collision_profile_normalizer.dart`, les modèles, les codecs JSON, l'éditeur, le gameplay ou le runtime.

Contrat stabilisé :

- `collisionMask` reste la vérité fine.
- `pixelMask` reste le nom JSON historique de `collisionMask`.
- `cells` reste une projection legacy/fallback/debug.
- un pixel solide peut activer une cellule avec le seuil par défaut `0.01`.
- `minimumSolidRatioPerCell` filtre ou accepte une cellule selon le ratio solide échantillonné.
- la projection respecte `sourceWidthInTiles` / `sourceHeightInTiles`.
- l'ordre de sortie est stable : `y` croissant puis `x` croissant.
- le normalizer utilise la même projection que le codec avec `ceil(mask.widthPx / tileSize)` et `ceil(mask.heightPx / tileSize)`.

Inventaire complet du lot :

| Catégorie | Fichiers |
|---|---|
| Créés | `reports/collision/collision_lot_5_collision_mask_cells_projection_contract.md` |
| Modifiés | `packages/map_core/test/element_collision_mask_codec_test.dart` |
| Modifiés | `packages/map_core/test/element_collision_profile_normalizer_test.dart` |
| Supprimés | Aucun |
| Générés | Aucun |
| Untracked touchés | `reports/collision/collision_lot_5_collision_mask_cells_projection_contract.md` |
| Fichiers hors lot préexistants | Aucun au status initial |

## 2. Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
```

Conclusion : worktree propre au début de Collision-5.

## 3. Rapports précédents relus

Rapports relus :

```text
/Users/karim/Project/pokemonProject/reports/collision/collision_system_audit_v0.md
/Users/karim/Project/pokemonProject/reports/collision/collision_lot_2_source_of_truth_implementation_plan.md
reports/collision/collision_lot_3_red_tests_triage.md
reports/collision/collision_lot_4_element_collision_profile_normalizer.md
```

Note de provenance :

- `collision_system_audit_v0.md` et `collision_lot_2_source_of_truth_implementation_plan.md` sont présents dans le workspace principal.
- `collision_lot_3_red_tests_triage.md` et `collision_lot_4_element_collision_profile_normalizer.md` sont présents dans ce worktree.

Conclusions reprises :

- l'audit V0 a établi que `collisionMask` existe déjà et qu'il est sérialisé sous `pixelMask`.
- Collision-2 a recommandé de garder `cells` comme projection/fallback/debug coarse.
- Collision-3 a clarifié les contrats legacy sans toucher à la production.
- Collision-4 a créé `normalizeElementCollisionProfile(...)` côté `map_core` et a déjà validé que `collisionMask` gagne contre `cells`.

## 4. Audit ciblé du codec de projection

Fichiers inspectés :

```text
packages/map_core/lib/src/operations/element_collision_mask_codec.dart
packages/map_core/lib/src/operations/element_collision_profile_normalizer.dart
packages/map_core/lib/src/models/element_collision_profile.dart
packages/map_core/test/element_collision_mask_codec_test.dart
packages/map_core/test/element_collision_profile_normalizer_test.dart
packages/map_core/test/element_collision_profile_pixel_mask_json_test.dart
```

Commande de recherche :

```bash
rg -n "cellsFromPixelMask|minimumSolidRatioPerCell|decodePackedBits|encodePackedBits|collisionMask|pixelMask|normalizeElementCollisionProfile" packages/map_core/lib packages/map_core/test
```

Signature réelle observée :

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

Règles actuelles observées dans `cellsFromPixelMask(...)` :

- dimensions invalides (`total <= 0`, `tileWidth <= 0`, `tileHeight <= 0`, `sourceWidthInTiles <= 0`, `sourceHeightInTiles <= 0`) : retourne `const <GridPos>[]`.
- `decodePackedBits(...)` transforme le payload `packed_bits_v1` en booléens row-major.
- chaque cellule demandée par `sourceWidthInTiles` / `sourceHeightInTiles` est échantillonnée avec `tileWidth` / `tileHeight`.
- les pixels hors dimensions du masque sont ignorés.
- `sampled` compte seulement les pixels effectivement présents dans le masque.
- `ratio = solid / sampled`.
- une cellule est ajoutée si `ratio >= minimumSolidRatioPerCell.clamp(0.0, 1.0)` et `solid > 0`.
- la sortie est triée par `y` croissant puis `x` croissant.

Règles actuelles observées dans `normalizeElementCollisionProfile(...)` :

- si `collisionMask != null`, le profil est copié avec `cells` recalculé par `ElementCollisionMaskCodec.cellsFromPixelMask(...)`.
- `tileWidth` et `tileHeight` valent `tileSize`.
- `sourceWidthInTiles = ceil(collisionMask.widthPx / tileSize)`.
- `sourceHeightInTiles = ceil(collisionMask.heightPx / tileSize)`.
- le résultat est retrié par `y` puis `x`.

Tests déjà existants avant Collision-5 :

- `element_collision_mask_codec_test.dart` testait le roundtrip packed bits et une projection simple.
- `element_collision_profile_normalizer_test.dart` testait la priorité `collisionMask`, la conservation `visualMask` / `occlusionMask`, le legacy coarse, l'ordre stable legacy, `tileSize <= 0`, et l'absence de mutation.
- `element_collision_profile_pixel_mask_json_test.dart` testait `pixelMask`, `visualMask`, `occlusionMask` et les payloads legacy non-map.

Lacunes couvertes par Collision-5 :

- pixel solide unique avec le seuil par défaut.
- masque vide.
- ordre stable multi-cellules côté codec.
- effet explicite de `minimumSolidRatioPerCell`.
- respect de `sourceWidthInTiles` / `sourceHeightInTiles`.
- dimensions non multiples de `tileSize` côté normalizer.
- cohérence normalizer <-> codec.

## 5. Contrat de projection retenu

Contrat retenu :

1. `collisionMask` est projeté en cellules legacy par `ElementCollisionMaskCodec.cellsFromPixelMask(...)`.
2. Le codec ne connaît pas le tileset complet : il projette uniquement la fenêtre demandée par `sourceWidthInTiles` / `sourceHeightInTiles`.
3. Une cellule est active si au moins un pixel solide existe et si le ratio solide de la cellule atteint `minimumSolidRatioPerCell`.
4. Le seuil par défaut `0.01` signifie qu'un pixel solide dans une tile `4x4` active la cellule (`1 / 16 = 0.0625`).
5. Un masque vide donne `cells == []`.
6. Les dimensions partielles sont supportées : les zones hors masque ne sont pas échantillonnées.
7. Le normalizer projette les dimensions partielles avec `ceil(widthPx / tileSize)` et `ceil(heightPx / tileSize)`.
8. La sortie est déterministe : `y` croissant puis `x` croissant.
9. `visualMask` et `occlusionMask` restent hors collision.
10. Les erreurs `tileSize <= 0` restent gérées par le normalizer, déjà testé en Collision-4.

Décision sur le code :

```text
Cas A — Les tests passent sans modification de production.
```

Conséquence : aucune modification de `packages/map_core/lib/**`.

## 6. Tests ajoutés ou renforcés

Tests ajoutés dans `packages/map_core/test/element_collision_mask_codec_test.dart` :

- `cellsFromPixelMask activates a cell with one solid pixel by default`
- `cellsFromPixelMask returns empty cells for an empty mask`
- `cellsFromPixelMask returns cells in stable y then x order`
- `cellsFromPixelMask filters sparse cells with minimum ratio`
- `cellsFromPixelMask accepts cells dense enough for minimum ratio`
- `cellsFromPixelMask respects requested source tile dimensions`

Tests ajoutés dans `packages/map_core/test/element_collision_profile_normalizer_test.dart` :

- `collisionMask projection handles partial edge tiles`
- `collisionMask projection matches ElementCollisionMaskCodec contract`

## 7. Fichiers créés

```text
reports/collision/collision_lot_5_collision_mask_cells_projection_contract.md
```

## 8. Fichiers modifiés

```text
packages/map_core/test/element_collision_mask_codec_test.dart
packages/map_core/test/element_collision_profile_normalizer_test.dart
```

## 9. Fichiers explicitement non modifiés

```text
packages/map_core/lib/src/operations/element_collision_mask_codec.dart
packages/map_core/lib/src/operations/element_collision_profile_normalizer.dart
packages/map_core/lib/src/models/element_collision_profile.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/tileset.dart
packages/map_editor/**
packages/map_gameplay/**
packages/map_runtime/**
packages/map_battle/**
examples/**
```

## 10. Comportements couverts

| Question | Réponse verrouillée par tests |
|---|---|
| Quand un pixel est solide, quelle cellule devient active ? | La cellule qui contient ce pixel devient active si le ratio atteint le seuil. |
| Que se passe-t-il si le mask n'est pas aligné sur `tileSize` ? | Le normalizer utilise `ceil`, et les cellules partielles sont projetées sans crash. |
| Que se passe-t-il si une cellule a seulement 1 pixel solide ? | Avec le seuil par défaut `0.01`, elle peut être active. |
| Quel est le rôle de `minimumSolidRatioPerCell` ? | Il filtre la cellule si le ratio solide est inférieur au seuil. |
| L'ordre des cells projetées est-il stable ? | Oui, `y` puis `x`. |
| Un mask vide donne-t-il cells vide ? | Oui. |
| Un mask plus petit qu'une tile peut-il activer une cellule ? | Oui, si un pixel solide est échantillonné et atteint le seuil. |
| Un mask partiellement hors dimensions de projection est-il géré proprement ? | Oui, les pixels hors masque sont ignorés. |
| Le normalizer respecte-t-il exactement cette projection ? | Oui, test explicite avec résultat du codec comme référence. |
| Les erreurs de dimensions / `tileSize` sont-elles claires ? | `tileSize <= 0` est rejeté par `ValidationException` côté normalizer ; le codec retourne vide pour dimensions invalides. |

## 11. Commandes lancées

Audit et recherche :

```bash
git status --short --untracked-files=all
ls -1 reports/collision
ls -1 /Users/karim/Project/pokemonProject/reports/collision
sed -n '1,220p' reports/collision/collision_lot_3_red_tests_triage.md
sed -n '1,220p' reports/collision/collision_lot_4_element_collision_profile_normalizer.md
sed -n '1,220p' /Users/karim/Project/pokemonProject/reports/collision/collision_system_audit_v0.md
sed -n '1,220p' /Users/karim/Project/pokemonProject/reports/collision/collision_lot_2_source_of_truth_implementation_plan.md
sed -n '1,260p' packages/map_core/lib/src/operations/element_collision_mask_codec.dart
sed -n '1,260p' packages/map_core/lib/src/operations/element_collision_profile_normalizer.dart
sed -n '1,260p' packages/map_core/lib/src/models/element_collision_profile.dart
sed -n '1,280p' packages/map_core/test/element_collision_mask_codec_test.dart
sed -n '1,320p' packages/map_core/test/element_collision_profile_normalizer_test.dart
sed -n '1,260p' packages/map_core/test/element_collision_profile_pixel_mask_json_test.dart
rg -n "cellsFromPixelMask|minimumSolidRatioPerCell|decodePackedBits|encodePackedBits|collisionMask|pixelMask|normalizeElementCollisionProfile" packages/map_core/lib packages/map_core/test
```

Format :

```bash
dart format packages/map_core/test/element_collision_mask_codec_test.dart packages/map_core/test/element_collision_profile_normalizer_test.dart
```

Tests et analyse :

```bash
cd packages/map_core
dart test test/element_collision_mask_codec_test.dart test/element_collision_profile_normalizer_test.dart
dart test test/element_collision_mask_codec_test.dart test/element_collision_profile_model_test.dart test/element_collision_profile_pixel_mask_json_test.dart test/element_collision_profile_normalizer_test.dart
dart analyze lib/src/operations/element_collision_mask_codec.dart lib/src/operations/element_collision_profile_normalizer.dart test/element_collision_mask_codec_test.dart test/element_collision_profile_normalizer_test.dart
dart test --reporter compact test/element_collision_mask_codec_test.dart test/element_collision_profile_normalizer_test.dart
dart test --reporter compact test/element_collision_mask_codec_test.dart test/element_collision_profile_model_test.dart test/element_collision_profile_pixel_mask_json_test.dart test/element_collision_profile_normalizer_test.dart
dart test --reporter compact
```

Périmètre :

```bash
git diff --name-only
git diff --stat
git status --short --untracked-files=all
```

## 12. Résultats des tests ciblés

Commande :

```bash
cd packages/map_core
dart test --reporter compact test/element_collision_mask_codec_test.dart test/element_collision_profile_normalizer_test.dart
```

Sortie finale utile :

```text
00:00 +20: All tests passed!
```

Commande :

```bash
cd packages/map_core
dart test test/element_collision_mask_codec_test.dart test/element_collision_profile_normalizer_test.dart
```

Résultat : même périmètre ciblé vert. La relance compacte fournit la ligne finale ci-dessus.

## 13. Résultats des tests groupés / globaux

Commande :

```bash
cd packages/map_core
dart test --reporter compact test/element_collision_mask_codec_test.dart test/element_collision_profile_model_test.dart test/element_collision_profile_pixel_mask_json_test.dart test/element_collision_profile_normalizer_test.dart
```

Sortie finale utile :

```text
00:00 +28: All tests passed!
```

Commande :

```bash
cd packages/map_core
dart test --reporter compact
```

Sortie finale utile :

```text
00:02 +1526: All tests passed!
```

## 14. Analyse statique / format

Commande :

```bash
dart format packages/map_core/test/element_collision_mask_codec_test.dart packages/map_core/test/element_collision_profile_normalizer_test.dart
```

Sortie :

```text
Formatted packages/map_core/test/element_collision_mask_codec_test.dart
Formatted 2 files (1 changed) in 0.01 seconds.
```

Commande :

```bash
cd packages/map_core
dart analyze lib/src/operations/element_collision_mask_codec.dart lib/src/operations/element_collision_profile_normalizer.dart test/element_collision_mask_codec_test.dart test/element_collision_profile_normalizer_test.dart
```

Sortie :

```text
Analyzing element_collision_mask_codec.dart, element_collision_profile_normalizer.dart, element_collision_mask_codec_test.dart, element_collision_profile_normalizer_test.dart...
No issues found!
```

## 15. Vérification du périmètre

Commande :

```bash
git diff --name-only
```

Sortie avant création du rapport :

```text
packages/map_core/test/element_collision_mask_codec_test.dart
packages/map_core/test/element_collision_profile_normalizer_test.dart
```

Sortie exacte après création du rapport :

```text
packages/map_core/test/element_collision_mask_codec_test.dart
packages/map_core/test/element_collision_profile_normalizer_test.dart
```

Note : `git diff --name-only` ne liste pas les fichiers untracked. Le rapport apparaît dans `git status --short --untracked-files=all`.

Confirmation :

- aucun fichier de production `map_core/lib/**` n'a été modifié.
- aucun fichier `map_editor/**`, `map_gameplay/**`, `map_runtime/**`, `map_battle/**` ou `examples/**` n'a été modifié.
- aucun fichier generated n'a été modifié.
- `build_runner` n'a pas été lancé.

## 16. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale exacte après création du rapport :

```text
 M packages/map_core/test/element_collision_mask_codec_test.dart
 M packages/map_core/test/element_collision_profile_normalizer_test.dart
?? reports/collision/collision_lot_5_collision_mask_cells_projection_contract.md
```

## 17. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie avant création du rapport :

```text
 .../test/element_collision_mask_codec_test.dart    | 168 ++++++++++++++++++++-
 .../element_collision_profile_normalizer_test.dart |  65 ++++++++
 2 files changed, 230 insertions(+), 3 deletions(-)
```

Sortie exacte après création du rapport : identique pour les fichiers trackés, car le rapport est encore untracked.

## 18. Risques / réserves

- Le seuil par défaut `minimumSolidRatioPerCell = 0.01` est volontairement permissif : un seul pixel solide peut activer une cellule coarse. C'est acceptable pour une projection legacy/debug, mais Collision-6/7 doivent garder en tête que `collisionMask` est la vérité fine.
- Le codec retourne `[]` pour des dimensions invalides, alors que le normalizer rejette `tileSize <= 0` avec `ValidationException`. Ce partage de responsabilité est conservé pour éviter un changement de comportement production hors lot.
- Les tests `map_editor` et `map_gameplay` skip de Collision-3 ne sont pas modifiés ici. Ils restent réservés à Collision-6 et Collision-7.
- Les packages hors `map_core` n'ont pas été relancés, car Collision-5 interdit les branchements editor/gameplay/runtime.

Non vérifié.

**Sujet :**
Suites complètes `map_editor`, `map_gameplay`, `map_runtime`, `map_battle`, `examples/playable_runtime_host`.

**Raison :**
Le lot est limité à `map_core` et n'a modifié que deux tests `map_core`.

**Impact :**
Aucun impact attendu côté production, editor, gameplay ou runtime.

**Comment vérifier dans Collision-6 :**
Relancer les tests ciblés `map_editor` autour de `FileProjectRepository` au moment du branchement du normalizer.

## 19. Préparation de Collision-6 / Collision-7

Collision-6 peut brancher `normalizeElementCollisionProfile(...)` dans la persistance editor sans réinventer la projection :

```text
collisionMask présent
-> ElementCollisionMaskCodec.cellsFromPixelMask(...)
-> cells projection legacy/debug stable
```

Collision-7 peut durcir gameplay en s'appuyant sur deux garanties :

- `collisionMask` reste la vérité fine.
- `cells` issue d'un profil normalisé est une projection cohérente et déterministe.

## 20. Auto-review finale

- Ai-je limité le lot à `map_core` ? Oui.
- Ai-je évité `map_editor` production ? Oui.
- Ai-je évité `map_gameplay` production ? Oui.
- Ai-je évité `map_runtime` production ? Oui.
- Ai-je évité `ProjectManifest` ? Oui.
- Ai-je évité `build_runner/generated` ? Oui.
- Ai-je conservé `collisionMask` comme vérité fine ? Oui.
- Ai-je conservé `pixelMask` comme nom JSON historique ? Oui.
- Ai-je clarifié le rôle de `cells` comme projection legacy ? Oui.
- Ai-je testé les dimensions non multiples de `tileSize` ? Oui.
- Ai-je testé `minimumSolidRatioPerCell` ? Oui.
- Ai-je testé l'ordre stable ? Oui.
- Ai-je vérifié la cohérence avec `normalizeElementCollisionProfile` ? Oui.
- Ai-je évité de corriger trop large ? Oui, aucune production modifiée.
- Ai-je relancé les tests ciblés ? Oui, `+20`, `+28`, et `map_core` global `+1526`.

Auto-critique : ce lot ajoute de la couverture sans changer la production, ce qui est exactement le bon périmètre. Le seul point de vigilance est que les tests documentent un seuil par défaut très permissif ; ce choix doit rester explicitement compris comme une projection legacy/debug et non comme une règle d'authoring UI.

## 21. Contenu complet des fichiers créés/modifiés

Le rapport lui-même n'est pas recopié ici pour éviter une inclusion récursive. Les deux fichiers de tests modifiés sont recopiés intégralement ci-dessous.

### `packages/map_core/test/element_collision_mask_codec_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ElementCollisionMaskCodec', () {
    test('packed bits roundtrip preserves mask', () {
      const width = 5;
      const height = 3;
      final pixels = <bool>[
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        true,
        false,
        false,
        false,
      ];
      final encoded = ElementCollisionMaskCodec.encodePackedBits(
        widthPx: width,
        heightPx: height,
        solidPixels: pixels,
      );
      final decoded = ElementCollisionMaskCodec.decodePackedBits(
        widthPx: width,
        heightPx: height,
        dataBase64: encoded,
      );
      expect(decoded, pixels);
    });

    test('cellsFromPixelMask projects blocking cells from mask', () {
      // 2x2 tiles, 2x2 px per tile => 4x4 px mask
      const widthPx = 4;
      const heightPx = 4;
      final pixels = List<bool>.filled(widthPx * heightPx, false);
      // Active entire bottom-left tile (cell 0,1)
      for (var y = 2; y < 4; y++) {
        for (var x = 0; x < 2; x++) {
          pixels[y * widthPx + x] = true;
        }
      }
      final mask = ElementCollisionPixelMask(
        widthPx: widthPx,
        heightPx: heightPx,
        dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: widthPx,
          heightPx: heightPx,
          solidPixels: pixels,
        ),
      );
      final cells = ElementCollisionMaskCodec.cellsFromPixelMask(
        mask: mask,
        tileWidth: 2,
        tileHeight: 2,
        sourceWidthInTiles: 2,
        sourceHeightInTiles: 2,
      );
      expect(cells, const [GridPos(x: 0, y: 1)]);
    });

    test('cellsFromPixelMask activates a cell with one solid pixel by default',
        () {
      final mask = _mask(
        widthPx: 4,
        heightPx: 4,
        solidPoints: const [GridPos(x: 3, y: 2)],
      );

      final cells = ElementCollisionMaskCodec.cellsFromPixelMask(
        mask: mask,
        tileWidth: 4,
        tileHeight: 4,
        sourceWidthInTiles: 1,
        sourceHeightInTiles: 1,
      );

      expect(cells, const [GridPos(x: 0, y: 0)]);
    });

    test('cellsFromPixelMask returns empty cells for an empty mask', () {
      final mask = _mask(widthPx: 8, heightPx: 8);

      final cells = ElementCollisionMaskCodec.cellsFromPixelMask(
        mask: mask,
        tileWidth: 4,
        tileHeight: 4,
        sourceWidthInTiles: 2,
        sourceHeightInTiles: 2,
      );

      expect(cells, isEmpty);
    });

    test('cellsFromPixelMask returns cells in stable y then x order', () {
      final mask = _mask(
        widthPx: 8,
        heightPx: 8,
        solidPoints: const [
          GridPos(x: 4, y: 4),
          GridPos(x: 0, y: 0),
          GridPos(x: 4, y: 0),
        ],
      );

      final cells = ElementCollisionMaskCodec.cellsFromPixelMask(
        mask: mask,
        tileWidth: 4,
        tileHeight: 4,
        sourceWidthInTiles: 2,
        sourceHeightInTiles: 2,
      );

      expect(
        cells,
        const [
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 1, y: 1),
        ],
      );
    });

    test('cellsFromPixelMask filters sparse cells with minimum ratio', () {
      final mask = _mask(
        widthPx: 4,
        heightPx: 4,
        solidPoints: const [GridPos(x: 0, y: 0)],
      );

      final cells = ElementCollisionMaskCodec.cellsFromPixelMask(
        mask: mask,
        tileWidth: 4,
        tileHeight: 4,
        sourceWidthInTiles: 1,
        sourceHeightInTiles: 1,
        minimumSolidRatioPerCell: 0.5,
      );

      expect(cells, isEmpty);
    });

    test('cellsFromPixelMask accepts cells dense enough for minimum ratio', () {
      final mask = _mask(
        widthPx: 4,
        heightPx: 4,
        solidPoints: const [
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 2, y: 0),
          GridPos(x: 3, y: 0),
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
          GridPos(x: 3, y: 1),
        ],
      );

      final cells = ElementCollisionMaskCodec.cellsFromPixelMask(
        mask: mask,
        tileWidth: 4,
        tileHeight: 4,
        sourceWidthInTiles: 1,
        sourceHeightInTiles: 1,
        minimumSolidRatioPerCell: 0.5,
      );

      expect(cells, const [GridPos(x: 0, y: 0)]);
    });

    test('cellsFromPixelMask respects requested source tile dimensions', () {
      final mask = _mask(
        widthPx: 8,
        heightPx: 8,
        solidPoints: const [
          GridPos(x: 4, y: 0),
          GridPos(x: 7, y: 3),
        ],
      );

      final cells = ElementCollisionMaskCodec.cellsFromPixelMask(
        mask: mask,
        tileWidth: 4,
        tileHeight: 4,
        sourceWidthInTiles: 1,
        sourceHeightInTiles: 1,
      );

      expect(cells, isEmpty);
    });
  });
}

ElementCollisionPixelMask _mask({
  required int widthPx,
  required int heightPx,
  List<GridPos> solidPoints = const [],
}) {
  final pixels = List<bool>.filled(widthPx * heightPx, false);
  for (final point in solidPoints) {
    pixels[point.y * widthPx + point.x] = true;
  }
  return ElementCollisionPixelMask(
    widthPx: widthPx,
    heightPx: heightPx,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: widthPx,
      heightPx: heightPx,
      solidPixels: pixels,
    ),
  );
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

    test('collisionMask projection handles partial edge tiles', () {
      final mask = _mask(
        widthPx: 5,
        heightPx: 5,
        solidPixels: _pixels(
          widthPx: 5,
          heightPx: 5,
          solidPoints: const [GridPos(x: 4, y: 4)],
        ),
      );
      const profile = ElementCollisionProfile(
        cells: [GridPos(x: 0, y: 0)],
      );

      final normalized = normalizeElementCollisionProfile(
        profile.copyWith(collisionMask: mask),
        tileSize: 4,
      );

      expect(normalized.cells, const [GridPos(x: 1, y: 1)]);
    });

    test('collisionMask projection matches ElementCollisionMaskCodec contract',
        () {
      final mask = _mask(
        widthPx: 5,
        heightPx: 5,
        solidPixels: _pixels(
          widthPx: 5,
          heightPx: 5,
          solidPoints: const [
            GridPos(x: 4, y: 4),
            GridPos(x: 0, y: 0),
            GridPos(x: 4, y: 0),
          ],
        ),
      );
      final profile = ElementCollisionProfile(
        collisionMask: mask,
        cells: const [GridPos(x: 9, y: 9)],
      );
      final expectedCells = ElementCollisionMaskCodec.cellsFromPixelMask(
        mask: mask,
        tileWidth: 4,
        tileHeight: 4,
        sourceWidthInTiles: 2,
        sourceHeightInTiles: 2,
      );

      final normalized = normalizeElementCollisionProfile(
        profile,
        tileSize: 4,
      );

      expect(
        expectedCells,
        const [
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 1, y: 1),
        ],
      );
      expect(normalized.cells, expectedCells);
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

## 22. Diff complet des fichiers modifiés

```diff
diff --git a/packages/map_core/test/element_collision_mask_codec_test.dart b/packages/map_core/test/element_collision_mask_codec_test.dart
index 832b4864..366a07f3 100644
--- a/packages/map_core/test/element_collision_mask_codec_test.dart
+++ b/packages/map_core/test/element_collision_mask_codec_test.dart
@@ -7,9 +7,21 @@ void main() {
       const width = 5;
       const height = 3;
       final pixels = <bool>[
-        true, false, true, false, true,
-        false, true, false, true, false,
-        true, true, false, false, false,
+        true,
+        false,
+        true,
+        false,
+        true,
+        false,
+        true,
+        false,
+        true,
+        false,
+        true,
+        true,
+        false,
+        false,
+        false,
       ];
       final encoded = ElementCollisionMaskCodec.encodePackedBits(
         widthPx: width,
@@ -53,5 +65,155 @@ void main() {
       );
       expect(cells, const [GridPos(x: 0, y: 1)]);
     });
+
+    test('cellsFromPixelMask activates a cell with one solid pixel by default',
+        () {
+      final mask = _mask(
+        widthPx: 4,
+        heightPx: 4,
+        solidPoints: const [GridPos(x: 3, y: 2)],
+      );
+
+      final cells = ElementCollisionMaskCodec.cellsFromPixelMask(
+        mask: mask,
+        tileWidth: 4,
+        tileHeight: 4,
+        sourceWidthInTiles: 1,
+        sourceHeightInTiles: 1,
+      );
+
+      expect(cells, const [GridPos(x: 0, y: 0)]);
+    });
+
+    test('cellsFromPixelMask returns empty cells for an empty mask', () {
+      final mask = _mask(widthPx: 8, heightPx: 8);
+
+      final cells = ElementCollisionMaskCodec.cellsFromPixelMask(
+        mask: mask,
+        tileWidth: 4,
+        tileHeight: 4,
+        sourceWidthInTiles: 2,
+        sourceHeightInTiles: 2,
+      );
+
+      expect(cells, isEmpty);
+    });
+
+    test('cellsFromPixelMask returns cells in stable y then x order', () {
+      final mask = _mask(
+        widthPx: 8,
+        heightPx: 8,
+        solidPoints: const [
+          GridPos(x: 4, y: 4),
+          GridPos(x: 0, y: 0),
+          GridPos(x: 4, y: 0),
+        ],
+      );
+
+      final cells = ElementCollisionMaskCodec.cellsFromPixelMask(
+        mask: mask,
+        tileWidth: 4,
+        tileHeight: 4,
+        sourceWidthInTiles: 2,
+        sourceHeightInTiles: 2,
+      );
+
+      expect(
+        cells,
+        const [
+          GridPos(x: 0, y: 0),
+          GridPos(x: 1, y: 0),
+          GridPos(x: 1, y: 1),
+        ],
+      );
+    });
+
+    test('cellsFromPixelMask filters sparse cells with minimum ratio', () {
+      final mask = _mask(
+        widthPx: 4,
+        heightPx: 4,
+        solidPoints: const [GridPos(x: 0, y: 0)],
+      );
+
+      final cells = ElementCollisionMaskCodec.cellsFromPixelMask(
+        mask: mask,
+        tileWidth: 4,
+        tileHeight: 4,
+        sourceWidthInTiles: 1,
+        sourceHeightInTiles: 1,
+        minimumSolidRatioPerCell: 0.5,
+      );
+
+      expect(cells, isEmpty);
+    });
+
+    test('cellsFromPixelMask accepts cells dense enough for minimum ratio', () {
+      final mask = _mask(
+        widthPx: 4,
+        heightPx: 4,
+        solidPoints: const [
+          GridPos(x: 0, y: 0),
+          GridPos(x: 1, y: 0),
+          GridPos(x: 2, y: 0),
+          GridPos(x: 3, y: 0),
+          GridPos(x: 0, y: 1),
+          GridPos(x: 1, y: 1),
+          GridPos(x: 2, y: 1),
+          GridPos(x: 3, y: 1),
+        ],
+      );
+
+      final cells = ElementCollisionMaskCodec.cellsFromPixelMask(
+        mask: mask,
+        tileWidth: 4,
+        tileHeight: 4,
+        sourceWidthInTiles: 1,
+        sourceHeightInTiles: 1,
+        minimumSolidRatioPerCell: 0.5,
+      );
+
+      expect(cells, const [GridPos(x: 0, y: 0)]);
+    });
+
+    test('cellsFromPixelMask respects requested source tile dimensions', () {
+      final mask = _mask(
+        widthPx: 8,
+        heightPx: 8,
+        solidPoints: const [
+          GridPos(x: 4, y: 0),
+          GridPos(x: 7, y: 3),
+        ],
+      );
+
+      final cells = ElementCollisionMaskCodec.cellsFromPixelMask(
+        mask: mask,
+        tileWidth: 4,
+        tileHeight: 4,
+        sourceWidthInTiles: 1,
+        sourceHeightInTiles: 1,
+      );
+
+      expect(cells, isEmpty);
+    });
   });
 }
+
+ElementCollisionPixelMask _mask({
+  required int widthPx,
+  required int heightPx,
+  List<GridPos> solidPoints = const [],
+}) {
+  final pixels = List<bool>.filled(widthPx * heightPx, false);
+  for (final point in solidPoints) {
+    pixels[point.y * widthPx + point.x] = true;
+  }
+  return ElementCollisionPixelMask(
+    widthPx: widthPx,
+    heightPx: heightPx,
+    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
+      widthPx: widthPx,
+      heightPx: heightPx,
+      solidPixels: pixels,
+    ),
+  );
+}
diff --git a/packages/map_core/test/element_collision_profile_normalizer_test.dart b/packages/map_core/test/element_collision_profile_normalizer_test.dart
index 252b2b02..e3e4bea8 100644
--- a/packages/map_core/test/element_collision_profile_normalizer_test.dart
+++ b/packages/map_core/test/element_collision_profile_normalizer_test.dart
@@ -32,6 +32,71 @@ void main() {
       expect(normalized.cells, const [GridPos(x: 0, y: 1)]);
     });
 
+    test('collisionMask projection handles partial edge tiles', () {
+      final mask = _mask(
+        widthPx: 5,
+        heightPx: 5,
+        solidPixels: _pixels(
+          widthPx: 5,
+          heightPx: 5,
+          solidPoints: const [GridPos(x: 4, y: 4)],
+        ),
+      );
+      const profile = ElementCollisionProfile(
+        cells: [GridPos(x: 0, y: 0)],
+      );
+
+      final normalized = normalizeElementCollisionProfile(
+        profile.copyWith(collisionMask: mask),
+        tileSize: 4,
+      );
+
+      expect(normalized.cells, const [GridPos(x: 1, y: 1)]);
+    });
+
+    test('collisionMask projection matches ElementCollisionMaskCodec contract',
+        () {
+      final mask = _mask(
+        widthPx: 5,
+        heightPx: 5,
+        solidPixels: _pixels(
+          widthPx: 5,
+          heightPx: 5,
+          solidPoints: const [
+            GridPos(x: 4, y: 4),
+            GridPos(x: 0, y: 0),
+            GridPos(x: 4, y: 0),
+          ],
+        ),
+      );
+      final profile = ElementCollisionProfile(
+        collisionMask: mask,
+        cells: const [GridPos(x: 9, y: 9)],
+      );
+      final expectedCells = ElementCollisionMaskCodec.cellsFromPixelMask(
+        mask: mask,
+        tileWidth: 4,
+        tileHeight: 4,
+        sourceWidthInTiles: 2,
+        sourceHeightInTiles: 2,
+      );
+
+      final normalized = normalizeElementCollisionProfile(
+        profile,
+        tileSize: 4,
+      );
+
+      expect(
+        expectedCells,
+        const [
+          GridPos(x: 0, y: 0),
+          GridPos(x: 1, y: 0),
+          GridPos(x: 1, y: 1),
+        ],
+      );
+      expect(normalized.cells, expectedCells);
+    });
+
     test('collisionMask preserves visualMask and occlusionMask', () {
       final collision = _solidMask(widthPx: 2, heightPx: 2);
       final visual = _solidMask(widthPx: 4, heightPx: 4);
```
