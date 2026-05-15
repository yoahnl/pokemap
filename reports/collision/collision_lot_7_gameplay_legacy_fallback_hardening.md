# Collision Lot 7 — Gameplay Legacy Fallback Hardening V0

## 1. Résumé exécutif

Collision-7 active les deux contrats gameplay qui étaient encore en `skip` depuis Collision-3.

Le lot reste test-only :

- `GameplayWorldState` n'est pas modifié.
- `map_core` n'est pas modifié.
- `map_editor` n'est pas modifié.
- `map_runtime` n'est pas modifié.
- les tests gameplay construisent explicitement un `ProjectManifest` normalisé via `normalizeElementCollisionProfile(...)`, sans importer `FileProjectRepository`.

Verdict : le gameplay est bien un consommateur simple. Il consomme `collisionMask` quand il existe, utilise `cells` comme fallback quand `collisionMask` est absent, et ne fait pas de migration legacy cachée.

## 2. Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte : aucune ligne imprimée.

## 3. Rapports précédents relus

Commande :

```bash
rg -n "skip|future normalizer|GameplayWorldState|placed element|collisionMask|cells fallback|over-blocks|normalized|Collision-7|Collision-6" reports/collision/collision_lot_3_red_tests_triage.md reports/collision/collision_lot_4_element_collision_profile_normalizer.md reports/collision/collision_lot_5_collision_mask_cells_projection_contract.md reports/collision/collision_lot_6_editor_persistence_uses_normalizer.md
```

Conclusions reprises :

- Collision-3 avait conservé deux tests gameplay en `skip` :
  - `future normalizer contract keeps legacy roof area passable before gameplay reads placed element cells`
  - `future normalizer contract keeps placed element id isolation`
- Collision-3 avait déjà rendu actifs les tests de caractérisation suivants :
  - `uses collisionMask before legacy cells when both exist`
  - `falls back to legacy cells when collisionMask is absent`
  - `currently over-blocks unnormalized legacy full cells`
- Collision-4 a créé `normalizeElementCollisionProfile(...)` dans `map_core`.
- Collision-5 a verrouillé le contrat `collisionMask -> cells`.
- Collision-6 a branché la normalisation dans `FileProjectRepository.loadProject()` côté éditeur, mais `map_gameplay` reste indépendant de `map_editor`.

## 4. Audit ciblé gameplay

Fichiers inspectés :

- `packages/map_gameplay/test/placed_elements_collision_test.dart`
- `packages/map_gameplay/lib/src/gameplay_world_state.dart`
- `packages/map_gameplay/lib/src/collision/pixel_movement_resolver.dart`
- `packages/map_gameplay/lib/src/gameplay_player_state.dart`
- `packages/map_gameplay/lib/src/gameplay_step.dart`
- `packages/map_gameplay/lib/src/movement_block_reason.dart`

Commandes principales :

```bash
nl -ba packages/map_gameplay/test/placed_elements_collision_test.dart | sed -n '1,780p'
nl -ba packages/map_gameplay/lib/src/gameplay_world_state.dart | sed -n '930,1065p'
nl -ba packages/map_gameplay/lib/src/collision/pixel_movement_resolver.dart | sed -n '1,180p'
nl -ba packages/map_gameplay/lib/src/gameplay_player_state.dart | sed -n '1,160p'
nl -ba packages/map_gameplay/lib/src/gameplay_step.dart | sed -n '1,140p'
nl -ba packages/map_gameplay/lib/src/movement_block_reason.dart | sed -n '1,120p'
rg -n "collisionMask|cells|placed element|placedElements|legacy|manualAddedCells|manualRemovedCells|normalizeElementCollisionProfile|isBlocked|GameplayWorldState|worldStaticObstaclesCollidePixelRect" packages/map_gameplay packages/map_core/lib
```

Constats :

- `GameplayWorldState` récupère les profils par `elementId`.
- `GameplayWorldState` stamp le `profile.collisionMask` dans le cache pixel-level.
- `_buildPlacedElementCellCollisionCache(...)` ignore les profils ayant un `collisionMask` et utilise `profile.cells` uniquement quand `collisionMask == null`.
- `PixelMovementResolverV1` reçoit seulement une fonction `worldStaticObstaclesCollidePixelRect`; il ne connaît ni les profils, ni le JSON, ni l'éditeur.
- `GameplayPlayerState` utilise une hitbox de déplacement V1 dérivée des conventions `PlayerCollisionConventionsV1`.
- `gameplay_step.dart` consomme le monde via `worldStaticObstaclesCollidePixelRect` et les caches exposés par `GameplayWorldState`.
- `movement_block_reason.dart` ne porte aucun contrat de migration.

Conclusion d'audit : aucun changement production gameplay n'est nécessaire pour Collision-7.

## 5. Design retenu

Le design retenu est test-only :

- retirer les deux `skip` gameplay issus de Collision-3 ;
- renommer les tests pour parler du comportement actif ;
- normaliser explicitement les profils dans les tests via un helper privé `_normalizeCollisionProfiles(...)` ;
- conserver le test qui prouve qu'un profil legacy non normalisé sur-bloque encore ;
- ne pas appeler `FileProjectRepository` depuis `map_gameplay` ;
- ne pas ajouter de migration dans `GameplayWorldState`.

Helper ajouté au test :

```dart
ProjectManifest _normalizeCollisionProfiles(ProjectManifest project) {
  final tileSize = project.settings.tileWidth;
  return project.copyWith(
    elements: [
      for (final element in project.elements)
        element.collisionProfile == null
            ? element
            : element.copyWith(
                collisionProfile: normalizeElementCollisionProfile(
                  element.collisionProfile!,
                  tileSize: tileSize,
                ),
              ),
    ],
  );
}
```

Ce helper applique uniquement l'API publique `map_core`; il ne recrée pas une logique de normalisation locale.

## 6. Contrat gameplay final

| Cas | Contrat vérifié |
|---|---|
| `collisionMask` présent | Le masque fin est prioritaire sur `cells`. |
| `collisionMask` absent | `cells` reste le fallback legacy. |
| Profil legacy non normalisé | Le gameplay sur-bloque encore, volontairement, car il ne migre pas. |
| Profil legacy normalisé en amont | Le gameplay respecte les `cells` normalisées. |
| Plusieurs `ProjectElementEntry` | Seul le profil de l'`elementId` placé est appliqué. |
| `FileProjectRepository` | Absent des tests gameplay ; la normalisation editor reste hors package gameplay. |

## 7. Fichiers modifiés

Fichiers modifiés par Collision-7 :

- `packages/map_gameplay/test/placed_elements_collision_test.dart`

Fichiers créés par Collision-7 :

- `reports/collision/collision_lot_7_gameplay_legacy_fallback_hardening.md`

Fichiers supprimés :

- Aucun.

Fichiers generated modifiés :

- Aucun.

Fichiers hors lot préexistants :

- Aucun dans le status initial.

## 8. Fichiers explicitement non modifiés

- `packages/map_gameplay/lib/src/gameplay_world_state.dart`
- `packages/map_gameplay/lib/src/collision/pixel_movement_resolver.dart`
- `packages/map_gameplay/lib/src/gameplay_player_state.dart`
- `packages/map_gameplay/lib/src/gameplay_step.dart`
- `packages/map_gameplay/lib/src/movement_block_reason.dart`
- `packages/map_core/lib/**`
- `packages/map_editor/**`
- `packages/map_runtime/**`
- `packages/map_battle/**`
- `examples/**`

## 9. Tests modifiés / ajoutés

Tests activés :

- Ancien nom : `future normalizer contract keeps legacy roof area passable before gameplay reads placed element cells`
  - Nouveau nom : `normalized legacy manual profile keeps roof area passable in gameplay`
  - Changement : retrait du `skip` et normalisation explicite du manifest dans le test.
- Ancien nom : `future normalizer contract keeps placed element id isolation`
  - Nouveau nom : `normalized placed element collision uses the placed element id only`
  - Changement : retrait du `skip`, normalisation explicite du manifest dans le test, réutilisation d'un seul `legacyProject`.

Helper ajouté :

- `_normalizeCollisionProfiles(ProjectManifest project)`

Tests conservés :

- `uses collisionMask before legacy cells when both exist`
- `falls back to legacy cells when collisionMask is absent`
- `currently over-blocks unnormalized legacy full cells`

## 10. Tests skip retirés

Commande de vérification :

```bash
rg -n "skip:|Pending Collision-4/Collision-7|future normalizer contract" packages/map_gameplay/test/placed_elements_collision_test.dart || true
```

Sortie exacte : aucune ligne imprimée.

Skips retirés :

| Ancien test | Ancienne raison |
|---|---|
| `future normalizer contract keeps legacy roof area passable before gameplay reads placed element cells` | `Pending Collision-4/Collision-7: ElementCollisionProfile normalizer is not implemented before GameplayWorldState consumes legacy cells.` |
| `future normalizer contract keeps placed element id isolation` | `Pending Collision-4/Collision-7: normalized placed element profiles are not available to gameplay yet.` |

## 11. Commandes lancées

```bash
git status --short --untracked-files=all
GIT_DIR=$(git rev-parse --git-dir) && GIT_COMMON=$(git rev-parse --git-common-dir) && printf 'git-dir=%s\ngit-common-dir=%s\n' "$GIT_DIR" "$GIT_COMMON" && git rev-parse --show-superproject-working-tree
rg -n "skip|future normalizer|GameplayWorldState|placed element|collisionMask|cells fallback|over-blocks|normalized|Collision-7|Collision-6" reports/collision/collision_lot_3_red_tests_triage.md reports/collision/collision_lot_4_element_collision_profile_normalizer.md reports/collision/collision_lot_5_collision_mask_cells_projection_contract.md reports/collision/collision_lot_6_editor_persistence_uses_normalizer.md
nl -ba packages/map_gameplay/test/placed_elements_collision_test.dart | sed -n '1,780p'
nl -ba packages/map_gameplay/lib/src/gameplay_world_state.dart | sed -n '930,1065p'
nl -ba packages/map_gameplay/lib/src/collision/pixel_movement_resolver.dart | sed -n '1,180p'
nl -ba packages/map_gameplay/lib/src/gameplay_player_state.dart | sed -n '1,160p'
nl -ba packages/map_gameplay/lib/src/gameplay_step.dart | sed -n '1,140p'
nl -ba packages/map_gameplay/lib/src/movement_block_reason.dart | sed -n '1,120p'
find packages/map_gameplay -name AGENTS.md -print
cd packages/map_gameplay && flutter test --no-pub --reporter expanded test/placed_elements_collision_test.dart
git status --short --untracked-files=all
dart format packages/map_gameplay/test/placed_elements_collision_test.dart
cd packages/map_gameplay && flutter test --no-pub --reporter expanded test/placed_elements_collision_test.dart
cd packages/map_gameplay && flutter test --no-pub --reporter compact test/placed_elements_collision_test.dart
cd packages/map_gameplay && dart analyze lib/src/gameplay_world_state.dart lib/src/collision/pixel_movement_resolver.dart test/placed_elements_collision_test.dart
cd packages/map_gameplay && flutter test --no-pub --reporter compact
rg -n "skip:|Pending Collision-4/Collision-7|future normalizer contract" packages/map_gameplay/test/placed_elements_collision_test.dart || true
git diff --name-only
git diff --stat
git status --short --untracked-files=all
```

## 12. Résultats des tests avant modification

Commande :

```bash
cd packages/map_gameplay
flutter test --no-pub --reporter expanded test/placed_elements_collision_test.dart
```

Sortie utile :

```text
00:00 +0: loading /Users/karim/.config/superpowers/worktrees/pokemonProject/collision-source-of-truth-worktree/packages/map_gameplay/test/placed_elements_collision_test.dart
00:00 +0: GameplayWorldState placed element collisions applyCollision=true blocks movement cell
00:00 +1: GameplayWorldState placed element collisions applyCollision=false does not block movement cell
00:00 +2: GameplayWorldState placed element collisions unknown element id does not block
00:00 +3: GameplayWorldState placed element collisions missing collision profile does not block
00:00 +4: GameplayWorldState placed element collisions pixelMask is used as source-of-truth when provided
00:00 +5: GameplayWorldState placed element collisions uses collisionMask before legacy cells when both exist
00:00 +6: GameplayWorldState placed element collisions falls back to legacy cells when collisionMask is absent
00:00 +7: GameplayWorldState placed element collisions one GridPos blocks one full world cell and nothing sub-tile exists
00:00 +8: GameplayWorldState placed element collisions currently over-blocks unnormalized legacy full cells
00:00 +9: GameplayWorldState placed element collisions future normalizer contract keeps legacy roof area passable before gameplay reads placed element cells
  Skip: Pending Collision-4/Collision-7: ElementCollisionProfile normalizer is not implemented before GameplayWorldState consumes legacy cells.
00:00 +9 ~1: GameplayWorldState placed element collisions future normalizer contract keeps placed element id isolation
  Skip: Pending Collision-4/Collision-7: normalized placed element profiles are not available to gameplay yet.
00:00 +9 ~2: GameplayWorldState placed element collisions roof-like coarse cell set blocks the exact whole world cells it names
00:00 +10 ~2: All tests passed!
```

## 13. Résultats des tests après modification

Commande :

```bash
cd packages/map_gameplay
flutter test --no-pub --reporter expanded test/placed_elements_collision_test.dart
```

Sortie utile :

```text
00:00 +0: loading /Users/karim/.config/superpowers/worktrees/pokemonProject/collision-source-of-truth-worktree/packages/map_gameplay/test/placed_elements_collision_test.dart
00:00 +0: GameplayWorldState placed element collisions applyCollision=true blocks movement cell
00:00 +1: GameplayWorldState placed element collisions applyCollision=false does not block movement cell
00:00 +2: GameplayWorldState placed element collisions unknown element id does not block
00:00 +3: GameplayWorldState placed element collisions missing collision profile does not block
00:00 +4: GameplayWorldState placed element collisions pixelMask is used as source-of-truth when provided
00:00 +5: GameplayWorldState placed element collisions uses collisionMask before legacy cells when both exist
00:00 +6: GameplayWorldState placed element collisions falls back to legacy cells when collisionMask is absent
00:00 +7: GameplayWorldState placed element collisions one GridPos blocks one full world cell and nothing sub-tile exists
00:00 +8: GameplayWorldState placed element collisions currently over-blocks unnormalized legacy full cells
00:00 +9: GameplayWorldState placed element collisions normalized legacy manual profile keeps roof area passable in gameplay
00:00 +10: GameplayWorldState placed element collisions normalized placed element collision uses the placed element id only
00:00 +11: GameplayWorldState placed element collisions roof-like coarse cell set blocks the exact whole world cells it names
00:00 +12: All tests passed!
```

Commande :

```bash
cd packages/map_gameplay
flutter test --no-pub --reporter compact test/placed_elements_collision_test.dart
```

Ligne finale utile :

```text
00:00 +12: All tests passed!
```

Commande :

```bash
cd packages/map_gameplay
flutter test --no-pub --reporter compact
```

Ligne finale utile :

```text
00:01 +122: All tests passed!
```

## 14. Analyse statique / format

Commande :

```bash
dart format packages/map_gameplay/test/placed_elements_collision_test.dart
```

Sortie exacte :

```text
Formatted packages/map_gameplay/test/placed_elements_collision_test.dart
Formatted 1 file (1 changed) in 0.01 seconds.
```

Commande :

```bash
cd packages/map_gameplay
dart analyze lib/src/gameplay_world_state.dart lib/src/collision/pixel_movement_resolver.dart test/placed_elements_collision_test.dart
```

Sortie exacte :

```text
Analyzing gameplay_world_state.dart, pixel_movement_resolver.dart, placed_elements_collision_test.dart...
No issues found!
```

## 15. Vérification du périmètre

Commande :

```bash
git diff --name-only
```

Sortie avant création du rapport :

```text
packages/map_gameplay/test/placed_elements_collision_test.dart
```

Commande :

```bash
git diff --stat
```

Sortie avant création du rapport :

```text
 .../test/placed_elements_collision_test.dart       | 47 ++++++++++++++--------
 1 file changed, 31 insertions(+), 16 deletions(-)
```

Fichiers production modifiés :

- Aucun.

Fichiers hors périmètre modifiés :

- Aucun.

## 16. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte après création du rapport :

```text
 M packages/map_gameplay/test/placed_elements_collision_test.dart
?? reports/collision/collision_lot_7_gameplay_legacy_fallback_hardening.md
```

## 17. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../test/placed_elements_collision_test.dart       | 47 ++++++++++++++--------
 1 file changed, 31 insertions(+), 16 deletions(-)
```

Note : le rapport est un fichier non suivi et n'apparaît pas dans `git diff --stat`.

## 18. Risques / réserves

- Collision-7 ne teste pas une nouvelle golden slice runtime/Flame avec un gros bâtiment ; ce périmètre appartient à Collision-10.
- Collision-7 ne modifie pas l'UI et ne clarifie pas les labels auteur ; ce périmètre appartient à Collision-8.
- Les tests gameplay prouvent la consommation d'un manifest normalisé, mais ils ne prouvent pas le branchement repository editor ; ce branchement est couvert par Collision-6.
- Le helper de test utilise `project.settings.tileWidth` comme `tileSize`, comme les lots précédents. Les fixtures utilisées sont en tiles carrées `16x16`.

## 19. Préparation de Collision-8 / Collision-10

Collision-8 peut s'appuyer sur ce contrat gameplay stabilisé pour clarifier les labels UI :

- `collisionMask` comme vérité fine ;
- `cells` comme projection/fallback legacy ;
- profil non normalisé comme état legacy, pas comme responsabilité gameplay.

Collision-10 peut ajouter une golden slice bâtiment :

- profil legacy normalisé ;
- zone de toit passable ;
- base collisionnante ;
- vérification pixel/player hitbox si le runtime expose la bonne surface de test.

## 20. Auto-review finale

- Ai-je modifié uniquement le test gameplay et le rapport ? Oui.
- Ai-je évité `map_editor` ? Oui.
- Ai-je évité `map_runtime` ? Oui.
- Ai-je évité `map_core` production ? Oui.
- Ai-je évité `GameplayWorldState` sauf nécessité prouvée ? Oui, aucun changement production.
- Ai-je retiré les skips gameplay Collision-3 ? Oui, deux skips retirés.
- Ai-je rendu actifs les contrats normalizer côté gameplay ? Oui.
- Ai-je conservé le test du fallback `cells` legacy ? Oui.
- Ai-je conservé la caractérisation du profil legacy non normalisé ? Oui.
- Ai-je prouvé que `collisionMask` gagne contre `cells` ? Oui, test existant conservé.
- Ai-je prouvé que `cells` fallback reste valide sans `collisionMask` ? Oui, test existant conservé.
- Ai-je prouvé qu'un profil normalisé rend le toit passable ? Oui.
- Ai-je prouvé l'isolation par `elementId` ? Oui.
- Ai-je évité de faire une migration dans gameplay ? Oui.
- Ai-je relancé les tests ciblés ? Oui.
- Ai-je relancé la suite `map_gameplay` ? Oui, `+122: All tests passed!`.

## 21. Contenu complet des fichiers créés/modifiés

Le rapport lui-même est le fichier créé par ce lot. Il n'est pas recopié récursivement dans cette section.

### `packages/map_gameplay/test/placed_elements_collision_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

ElementCollisionPixelMask _solidTileMask16x16() {
  final maskPixels = List<bool>.filled(16 * 16, true);
  return ElementCollisionPixelMask(
    widthPx: 16,
    heightPx: 16,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: 16,
      heightPx: 16,
      solidPixels: maskPixels,
    ),
  );
}

void main() {
  group('GameplayWorldState placed element collisions', () {
    test('applyCollision=true blocks movement cell', () {
      final world = GameplayWorldState.initial(
        map: _baseMap(
          applyCollision: true,
          elementId: 'tree',
        ),
        playerPos: const GridPos(x: 1, y: 1),
        project: _project(
          includeElement: true,
          includeCollisionProfile: true,
        ),
      );

      expect(
          world.isCellCenterBlockedLegacyForGridIndexedSystems(1, 1), isTrue);
    });

    test('applyCollision=false does not block movement cell', () {
      final world = GameplayWorldState.initial(
        map: _baseMap(
          applyCollision: false,
          elementId: 'tree',
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: _project(
          includeElement: true,
          includeCollisionProfile: true,
        ),
      );

      expect(
        world.isCellCenterBlockedLegacyForGridIndexedSystems(1, 1),
        isFalse,
      );
    });

    test('unknown element id does not block', () {
      final world = GameplayWorldState.initial(
        map: _baseMap(
          applyCollision: true,
          elementId: 'missing',
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: _project(
          includeElement: true,
          includeCollisionProfile: true,
        ),
      );

      expect(
        world.isCellCenterBlockedLegacyForGridIndexedSystems(1, 1),
        isFalse,
      );
    });

    test('missing collision profile does not block', () {
      final world = GameplayWorldState.initial(
        map: _baseMap(
          applyCollision: true,
          elementId: 'tree',
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: _project(
          includeElement: true,
          includeCollisionProfile: false,
        ),
      );

      expect(
        world.isCellCenterBlockedLegacyForGridIndexedSystems(1, 1),
        isFalse,
      );
    });

    test('pixelMask is used as source-of-truth when provided', () {
      final maskPixels = List<bool>.filled(16 * 16, false);
      // Active uniquement le quadrant bas-gauche du tile 16x16.
      for (var y = 8; y < 16; y++) {
        for (var x = 0; x < 8; x++) {
          maskPixels[y * 16 + x] = true;
        }
      }
      final mask = ElementCollisionPixelMask(
        widthPx: 16,
        heightPx: 16,
        dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: 16,
          heightPx: 16,
          solidPixels: maskPixels,
        ),
      );
      final project = ProjectManifest(
        name: 'project',
        settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
        maps: const [],
        tilesets: const [
          ProjectTilesetEntry(id: 'ts', name: 'ts', relativePath: 'ts.png'),
        ],
        elementCategories: const [
          ProjectElementCategory(id: 'cat', name: 'cat'),
        ],
        elements: [
          ProjectElementEntry(
            id: 'tree',
            name: 'Tree',
            tilesetId: 'ts',
            categoryId: 'cat',
            frames: const [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
              ),
            ],
            collisionProfile: ElementCollisionProfile(
              collisionMask: mask,
              // On met volontairement `cells` vide: le test valide que le
              // gameplay dérive bien la collision depuis le masque.
              cells: const <GridPos>[],
            ),
          ),
        ],
        surfaceCatalog: ProjectSurfaceCatalog(),
      );
      final world = GameplayWorldState.initial(
        map: _baseMap(
          applyCollision: true,
          elementId: 'tree',
        ),
        playerPos: const GridPos(x: 1, y: 1),
        project: project,
      );
      // Le quadrant bas-gauche est plein : un pixel dedans bloque ; le centre de
      // case (8,8) dans le tile est hors de ce quadrant → pas de blocage au centre.
      expect(
        world.worldStaticObstaclesCollidePixelRect(
          PixelRect(
            leftPx: 16 + 4,
            topPx: 16 + 12,
            widthPx: 1,
            heightPx: 1,
          ),
        ),
        isTrue,
      );
      expect(
        world.isCellCenterBlockedLegacyForGridIndexedSystems(1, 1),
        isFalse,
      );
    });

    test('uses collisionMask before legacy cells when both exist', () {
      final maskPixels = List<bool>.filled(16 * 16, false);
      // Pixels opaques uniquement sur la ligne haute.
      for (var x = 0; x < 16; x++) {
        maskPixels[x] = true; // y=0
      }
      final mask = ElementCollisionPixelMask(
        widthPx: 16,
        heightPx: 16,
        dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: 16,
          heightPx: 16,
          solidPixels: maskPixels,
        ),
      );
      final project = ProjectManifest(
        name: 'project',
        settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
        maps: const [],
        tilesets: const [
          ProjectTilesetEntry(id: 'ts', name: 'ts', relativePath: 'ts.png'),
        ],
        elementCategories: const [
          ProjectElementCategory(id: 'cat', name: 'cat'),
        ],
        elements: [
          ProjectElementEntry(
            id: 'tree',
            name: 'Tree',
            tilesetId: 'ts',
            categoryId: 'cat',
            frames: const [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
              ),
            ],
            collisionProfile: const ElementCollisionProfile(
              // `cells` volontairement bloquante: doit être ignorée car un
              // `pixelMask` valide existe.
              cells: [GridPos(x: 0, y: 0)],
            ).copyWith(collisionMask: mask),
          ),
        ],
        surfaceCatalog: ProjectSurfaceCatalog(),
      );
      final world = GameplayWorldState.initial(
        map: _baseMap(
          applyCollision: true,
          elementId: 'tree',
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: project,
      );
      expect(
        world.isCellCenterBlockedLegacyForGridIndexedSystems(1, 1),
        isFalse,
      );
      expect(
        world.movementBlockReasonAtPlayerFeetCellForWaterAndGridSolidTrial(
          cellX: 1,
          cellY: 1,
          movementMode: MovementMode.walk,
        ),
        isNull,
      );
      expect(
        world.worldStaticObstaclesCollidePixelRect(
          PixelRect(
            leftPx: 16 + 3,
            topPx: 16 + 0,
            widthPx: 1,
            heightPx: 1,
          ),
        ),
        isTrue,
      );
      expect(
        world.worldStaticObstaclesCollidePixelRect(
          PixelRect(
            leftPx: 16 + 3,
            topPx: 16 + 14,
            widthPx: 1,
            heightPx: 1,
          ),
        ),
        isFalse,
      );
    });

    test('falls back to legacy cells when collisionMask is absent', () {
      final world = GameplayWorldState.initial(
        map: _baseMap(
          applyCollision: true,
          elementId: 'tree',
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: ProjectManifest(
          name: 'project',
          maps: const [],
          tilesets: const [
            ProjectTilesetEntry(id: 'ts', name: 'ts', relativePath: 'ts.png'),
          ],
          elementCategories: const [
            ProjectElementCategory(id: 'cat', name: 'cat'),
          ],
          elements: const [
            ProjectElementEntry(
              id: 'tree',
              name: 'Tree',
              tilesetId: 'ts',
              categoryId: 'cat',
              frames: [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
                ),
              ],
              collisionProfile: ElementCollisionProfile(
                cells: [GridPos(x: 0, y: 0)],
              ),
            ),
          ],
          surfaceCatalog: ProjectSurfaceCatalog(),
        ),
      );

      expect(world.isBlocked(1, 1), isTrue);
      expect(world.isBlocked(2, 1), isFalse);
    });

    test('one GridPos blocks one full world cell and nothing sub-tile exists',
        () {
      final world = GameplayWorldState.initial(
        map: _baseMap(
          applyCollision: true,
          elementId: 'tree',
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: _project(
          includeElement: true,
          includeCollisionProfile: true,
        ),
      );

      // Gameplay exposes collision strictly at integer cell coordinates.
      // There is no API for partial-cell collision queries because the runtime
      // cache itself is a List<bool> indexed by whole map cells.
      expect(world.isBlocked(1, 1), isTrue);
      expect(world.isBlocked(0, 1), isFalse);
      expect(world.isBlocked(1, 0), isFalse);
      expect(world.isBlocked(2, 1), isFalse);
      expect(world.isBlocked(1, 2), isFalse);
    });

    test('currently over-blocks unnormalized legacy full cells', () {
      final manifest = ProjectManifest.fromJson(
        migrateProjectManifestJson(_legacyBrokenProjectJson()),
      );
      final world = GameplayWorldState.initial(
        map: MapData(
          id: 'map',
          name: 'Map',
          size: const GridSize(width: 12, height: 12),
          layers: [
            MapLayer.tile(
              id: 'tile',
              name: 'Tile',
              tiles: List<int>.filled(144, 0),
            ),
          ],
          placedElements: const [
            MapPlacedElement(
              id: 'house::3::2',
              layerId: 'tile',
              elementId: 'petite_maison_toit_bleu',
              pos: GridPos(x: 3, y: 2),
              applyCollision: true,
            ),
          ],
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: manifest,
      );

      // cells is the legacy fallback when no collisionMask exists.
      expect(world.isBlocked(3, 2), isTrue);
      expect(world.isBlocked(8, 4), isTrue);
      expect(world.isBlocked(3, 5), isTrue);
      expect(world.isBlocked(7, 7), isTrue);
    });

    test(
        'normalized legacy manual profile keeps roof area passable in gameplay',
        () {
      final manifest = _normalizeCollisionProfiles(
        ProjectManifest.fromJson(
          migrateProjectManifestJson(_legacyBrokenProjectJson()),
        ),
      );
      final world = GameplayWorldState.initial(
        map: MapData(
          id: 'map',
          name: 'Map',
          size: const GridSize(width: 12, height: 12),
          layers: [
            MapLayer.tile(
              id: 'tile',
              name: 'Tile',
              tiles: List<int>.filled(144, 0),
            ),
          ],
          placedElements: const [
            MapPlacedElement(
              id: 'house::3::2',
              layerId: 'tile',
              elementId: 'petite_maison_toit_bleu',
              pos: GridPos(x: 3, y: 2),
              applyCollision: true,
            ),
          ],
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: manifest,
      );

      // Roof area remains passable.
      expect(world.isBlocked(3, 2), isFalse);
      expect(world.isBlocked(8, 4), isFalse);

      // Base/body area blocks exactly where the authored silhouette lives.
      expect(world.isBlocked(3, 5), isTrue);
      expect(world.isBlocked(7, 7), isTrue);
    });

    test('normalized placed element collision uses the placed element id only',
        () {
      final legacyProject = ProjectManifest.fromJson(
        migrateProjectManifestJson(_legacyBrokenProjectJson()),
      );
      final project = _normalizeCollisionProfiles(legacyProject.copyWith(
        elements: [
          ...legacyProject.elements,
          ProjectElementEntry(
            id: 'other_house',
            name: 'Other house',
            tilesetId: 'ts',
            categoryId: 'cat',
            frames: const [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
              ),
            ],
            collisionProfile: const ElementCollisionProfile(
              cells: [GridPos(x: 0, y: 0)],
            ),
          ),
        ],
      ));

      final world = GameplayWorldState.initial(
        map: MapData(
          id: 'map',
          name: 'Map',
          size: const GridSize(width: 12, height: 12),
          layers: [
            MapLayer.tile(
              id: 'tile',
              name: 'Tile',
              tiles: List<int>.filled(144, 0),
            ),
          ],
          placedElements: const [
            MapPlacedElement(
              id: 'house::3::2',
              layerId: 'tile',
              elementId: 'petite_maison_toit_bleu',
              pos: GridPos(x: 3, y: 2),
              applyCollision: true,
            ),
          ],
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: project,
      );

      expect(world.isBlocked(3, 2), isFalse);
      expect(world.isBlocked(3, 5), isTrue);
      expect(world.isBlocked(0, 0), isFalse);
    });

    test(
        'roof-like coarse cell set blocks the exact whole world cells it names',
        () {
      const roofCells = <GridPos>[
        GridPos(x: 1, y: 0),
        GridPos(x: 2, y: 0),
        GridPos(x: 3, y: 0),
        GridPos(x: 4, y: 0),
        GridPos(x: 1, y: 1),
        GridPos(x: 2, y: 1),
        GridPos(x: 3, y: 1),
        GridPos(x: 4, y: 1),
        GridPos(x: 1, y: 2),
        GridPos(x: 2, y: 2),
        GridPos(x: 3, y: 2),
        GridPos(x: 4, y: 2),
      ];

      final world = GameplayWorldState.initial(
        map: MapData(
          id: 'map',
          name: 'Map',
          size: const GridSize(width: 12, height: 12),
          layers: [
            MapLayer.tile(
              id: 'tile',
              name: 'Tile',
              tiles: List<int>.filled(144, 0),
            ),
          ],
          placedElements: const [
            MapPlacedElement(
              id: 'roof::3::4',
              layerId: 'tile',
              elementId: 'roof_house',
              pos: GridPos(x: 3, y: 4),
              applyCollision: true,
            ),
          ],
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: ProjectManifest(
          name: 'project',
          maps: const [],
          tilesets: const [
            ProjectTilesetEntry(id: 'ts', name: 'ts', relativePath: 'ts.png'),
          ],
          elementCategories: const [
            ProjectElementCategory(id: 'cat', name: 'cat'),
          ],
          elements: const [
            ProjectElementEntry(
              id: 'roof_house',
              name: 'Roof House',
              tilesetId: 'ts',
              categoryId: 'cat',
              frames: [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 6, height: 7),
                ),
              ],
              collisionProfile: ElementCollisionProfile(cells: roofCells),
            ),
          ],
          surfaceCatalog: ProjectSurfaceCatalog(),
        ),
      );

      // World-space blocking is the direct translation of GridPos to whole
      // world cells. The slope cannot survive beyond this lattice.
      expect(world.isBlocked(4, 4), isTrue);
      expect(world.isBlocked(5, 4), isTrue);
      expect(world.isBlocked(6, 4), isTrue);
      expect(world.isBlocked(7, 4), isTrue);
      expect(world.isBlocked(3, 4), isFalse);
      expect(world.isBlocked(8, 4), isFalse);
      expect(world.isBlocked(4, 3), isFalse);
      expect(world.isBlocked(4, 7), isFalse);
    });
  });
}

Map<String, dynamic> _legacyBrokenProjectJson() {
  return <String, dynamic>{
    'name': 'Legacy',
    'maps': <dynamic>[],
    'tilesets': <dynamic>[
      <String, dynamic>{
        'id': 'ts',
        'name': 'ts',
        'relativePath': 'ts.png',
      },
    ],
    'elementCategories': <dynamic>[
      <String, dynamic>{'id': 'cat', 'name': 'cat'},
    ],
    'settings': <String, dynamic>{
      'tileWidth': 16,
      'tileHeight': 16,
    },
    'elements': <dynamic>[
      <String, dynamic>{
        'id': 'petite_maison_toit_bleu',
        'name': 'petite maison toit bleu',
        'tilesetId': 'ts',
        'categoryId': 'cat',
        'frames': <dynamic>[
          <String, dynamic>{
            'tilesetId': '',
            'source': <String, dynamic>{
              'x': 0,
              'y': 341,
              'width': 6,
              'height': 7,
            },
          },
        ],
        'presetKind': 'building',
        'collisionProfile': <String, dynamic>{
          'source': 'manual',
          'padding': const <String, dynamic>{
            'top': 0,
            'right': 0,
            'bottom': 0,
            'left': 0,
          },
          'shapeCells': <dynamic>[],
          'cells': <dynamic>[
            for (var y = 0; y < 7; y++)
              for (var x = 0; x < 6; x++) <String, dynamic>{'x': x, 'y': y},
          ],
          'manualAddedCells': const <Map<String, dynamic>>[
            {'x': 0, 'y': 3},
            {'x': 1, 'y': 3},
            {'x': 2, 'y': 3},
            {'x': 3, 'y': 3},
            {'x': 4, 'y': 3},
            {'x': 5, 'y': 3},
            {'x': 1, 'y': 4},
            {'x': 2, 'y': 4},
            {'x': 3, 'y': 4},
            {'x': 4, 'y': 4},
            {'x': 1, 'y': 5},
            {'x': 2, 'y': 5},
            {'x': 3, 'y': 5},
            {'x': 4, 'y': 5},
          ],
          'manualRemovedCells': <dynamic>[],
        },
      },
    ],
  };
}

ProjectManifest _normalizeCollisionProfiles(ProjectManifest project) {
  final tileSize = project.settings.tileWidth;
  return project.copyWith(
    elements: [
      for (final element in project.elements)
        element.collisionProfile == null
            ? element
            : element.copyWith(
                collisionProfile: normalizeElementCollisionProfile(
                  element.collisionProfile!,
                  tileSize: tileSize,
                ),
              ),
    ],
  );
}

MapData _baseMap({
  required bool applyCollision,
  required String elementId,
}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 3, height: 3),
    layers: const [
      MapLayer.tile(
        id: 'tile',
        name: 'Tile',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
    ],
    placedElements: [
      MapPlacedElement(
        id: 'tile::1::1',
        layerId: 'tile',
        elementId: elementId,
        pos: const GridPos(x: 1, y: 1),
        applyCollision: applyCollision,
      ),
    ],
  );
}

ProjectManifest _project({
  required bool includeElement,
  required bool includeCollisionProfile,
}) {
  return ProjectManifest(
    name: 'project',
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(id: 'ts', name: 'ts', relativePath: 'ts.png'),
    ],
    elementCategories: const [
      ProjectElementCategory(id: 'cat', name: 'cat'),
    ],
    elements: includeElement
        ? [
            ProjectElementEntry(
              id: 'tree',
              name: 'Tree',
              tilesetId: 'ts',
              categoryId: 'cat',
              frames: const [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
                ),
              ],
              collisionProfile: includeCollisionProfile
                  ? ElementCollisionProfile(
                      collisionMask: _solidTileMask16x16(),
                      cells: const <GridPos>[],
                    )
                  : null,
            ),
          ]
        : const [],
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}
```
