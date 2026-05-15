# Collision Lot 10-bis — Fine Collision Mask Authoring UI V0

## 1. Résumé exécutif

Collision-10-bis corrige la lacune produit révélée par les tests manuels après Collision-10 : la sheet principale expliquait la vérité gameplay, mais l’utilisateur ne disposait pas d’un chemin réellement utilisable pour créer ou sculpter `ElementCollisionProfile.collisionMask`.

Résultat final :

- la sheet principale expose `Collision par grille` et `Masque fin` ;
- le mode grille conserve les outils coarse existants ;
- le mode `Masque fin` affiche `ElementCollisionTripleMaskEditor` ;
- un profil avec `collisionMask` ouvre directement en mode fin ;
- le triple mask editor démarre sur `Peindre collision`, plus sur un aperçu inactif ;
- les profils legacy remplis sans `collisionMask` démarrent en `Effacer`, pour creuser le masque fin depuis la grille existante ;
- un clic peint ou efface une empreinte visible de pinceau, pas un seul pixel quasi invisible ;
- la taille de pinceau pixel est réglable ;
- la sauvegarde préserve `collisionMask`, `visualMask` et `occlusionMask` ;
- aucun fichier `map_core`, `map_gameplay`, `map_runtime`, repository, generated ou build_runner n’a été touché.

## 2. Pourquoi Collision-10-bis est nécessaire

Le test manuel a identifié deux écarts produit successifs :

1. après Collision-10, l’UI ne donnait pas accès au vrai masque fin depuis la sheet principale ;
2. après le premier branchement du mode fin, l’utilisateur pouvait arriver sur une surface où cliquer ne produisait pas d’effet perceptible : un pixel modifié était trop discret, et un profil grille déjà rouge démarrait en peinture au lieu de démarrer en sculpture.

Le correctif final traite ces deux points. Le moteur savait déjà lire `collisionMask`; ce lot rend l’authoring utilisateur accessible et visible.

## 3. Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte au lancement du lot Collision-10-bis :

```text
```

Interprétation : aucune ligne imprimée, le worktree était propre au début du lot.

## 4. Rapports précédents relus

Rapports relus :

```text
reports/collision/collision_lot_7_gameplay_legacy_fallback_hardening.md
reports/collision/collision_lot_8_ui_truth_labels.md
reports/collision/collision_lot_9_player_foot_hitbox_preview.md
reports/collision/collision_lot_10_building_golden_slice.md
```

Décisions reprises :

- Collision-7 : `GameplayWorldState` consomme `collisionMask` en priorité et `cells` seulement comme fallback, sans migration cachée.
- Collision-8 : l’UI doit expliquer `Collision fine active`, `Collision par grille`, `Aucune collision active`, et ne pas exposer `pixelMask` comme jargon principal.
- Collision-9 : la sheet affiche la hitbox joueur `12 × 8 px`, zone aux pieds.
- Collision-10 : la golden slice bâtiment prouve le cœur data/persistence/gameplay/UI read-model, mais pas l’accès utilisateur au masque fin dans la sheet principale.

## 5. Audit ciblé de la sheet et du triple mask editor

Fichiers inspectés :

```text
packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart
packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart
packages/map_editor/lib/src/application/models/element_collision_truth_summary.dart
packages/map_editor/lib/src/application/models/player_collision_hitbox_preview.dart
packages/map_editor/lib/src/application/services/element_collision_authoring_service.dart
packages/map_editor/test/element_collision_editor_sheet_overflow_test.dart
packages/map_editor/test/element_collision_truth_summary_test.dart
packages/map_editor/test/player_collision_hitbox_preview_test.dart
```

Recherche lancée :

```bash
rg -n "showElementCollisionEditorSheet|ElementCollisionTripleMaskEditor|collisionMask|occlusionMask|visualMask|_buildSavedProfile|_draftProfile|_draftPadding|Collision fine|Masque fin|Collision par grille|Aperçu|Pinceau|Polygone|overflow" packages/map_editor/lib packages/map_editor/test
```

Constats :

- `showElementCollisionEditorSheet(...)` affichait uniquement le flux coarse.
- `ElementCollisionTripleMaskEditor` existait déjà et savait éditer `collisionMask`, `occlusionMask` et conserver `visualMask`.
- Signature réelle de `ElementCollisionTripleMaskEditor` :

```dart
ElementCollisionTripleMaskEditor({
  required ui.Image image,
  required TilesetSourceRect source,
  required int tileWidth,
  required int tileHeight,
  required ElementCollisionProfile? profile,
  required WarpTriggerPadding draftPadding,
  required ValueChanged<ElementCollisionProfile?> onProfileChanged,
})
```

- Le widget émet un nouveau profil via `onProfileChanged` après `_emitProfile()`.
- Il reprojette `cells` depuis `collisionMask` avec `ElementCollisionMaskCodec.cellsFromPixelMask(...)`.
- `_buildSavedProfile()` reconstruisait toujours un profil via `ElementCollisionAuthoringService.rebuild(...)`, ce qui supprimait `visualMask`, `collisionMask` et `occlusionMask`.
- La surface de peinture fine devait utiliser `HitTestBehavior.opaque` pour recevoir les taps sur toute la zone.
- Un clic initial ne peignait qu’un pixel ; à l’échelle de la preview, c’était trop discret.
- Quand un profil legacy avait des `cells` remplies, démarrer en `Peindre` ne changeait rien visuellement sur les zones déjà rouges.

## 6. Design UX retenu

Design retenu : un sélecteur compact dans la sheet principale, puis un triple mask editor directement éditable.

Modes sheet :

```text
Collision par grille
Masque fin
```

Modes masque fin :

```text
Aperçu
Peindre collision
Peindre occlusion
```

Opérations visibles en mode peinture :

```text
Peindre
Effacer
```

Taille de pinceau visible :

```text
1px / 4px / 8px / 16px selon la taille de tile
```

Comportement :

- si `initialProfile.collisionMask != null`, la sheet ouvre directement en mode `Masque fin` ;
- sinon, elle ouvre en mode `Collision par grille` ;
- le sélecteur reste visible dans les deux cas ;
- le mode grille garde l’éditeur existant ;
- le mode masque fin affiche `ElementCollisionTripleMaskEditor` dans une zone scrollable ;
- le triple mask editor démarre en `Peindre collision` ;
- si le profil vient de `cells` legacy sans `collisionMask`, l’opération initiale est `Effacer` pour sculpter la collision existante ;
- le pinceau applique une empreinte carrée visible ;
- le clic secondaire reste une gomme rapide pendant un drag.

## 7. Mode grille / mode masque fin

Mode grille :

- conserve les outils `Aperçu`, `Pinceau +`, `Pinceau -`, `Polygone forme`, `Polygone -` ;
- conserve le padding, les retouches et la sidebar ;
- reste utile pour la compatibilité, le fallback et les silhouettes coarse.

Mode masque fin :

- affiche `ElementCollisionTripleMaskEditor` ;
- expose les labels du triple mask editor : `Masque collision`, `Masque occlusion`, `ne bloque pas` ;
- permet de peindre le masque collision et de générer un `collisionMask` ;
- permet d’effacer explicitement des pixels via `Effacer` ;
- permet de choisir la taille de pinceau ;
- ne branche pas l’occlusion runtime.

## 8. Stratégie de sauvegarde des masks

Avant Collision-10-bis, `_buildSavedProfile()` renvoyait uniquement le résultat coarse :

```dart
_authoringService.rebuild(...)
```

Cette stratégie perdait les trois masks nullable du profil.

Stratégie retenue :

- reconstruire le profil coarse comme avant pour conserver `cells`, `shapeCells`, `manualAddedCells`, `manualRemovedCells` et `padding` ;
- recopier ensuite depuis `_draftProfile` les masks existants :
  - `visualMask` ;
  - `collisionMask` ;
  - `occlusionMask`.

Cette préservation est appliquée aussi aux opérations coarse non destructives comme reset overrides, restore padding base, padding change, brush et polygon. L’action explicite `Vider toute collision` conserve le comportement de clear coarse existant.

## 9. Fichiers créés

```text
packages/map_editor/test/element_collision_editor_sheet_fine_mask_test.dart
reports/collision/collision_lot_10bis_fine_collision_mask_authoring_ui.md
```

## 10. Fichiers modifiés

```text
packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart
packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart
```

## 11. Fichiers explicitement non modifiés

```text
packages/map_core/**
packages/map_gameplay/**
packages/map_runtime/**
packages/map_battle/**
examples/**
packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
packages/map_editor/lib/src/application/collision_generation/**
FileProjectRepository
GameplayWorldState
PixelMovementResolver
normalizeElementCollisionProfile(...)
ElementCollisionMaskCodec
ProjectManifest
ElementCollisionProfile
fichiers generated
```

`build_runner` n’a pas été lancé.

## 12. Tests ajoutés / modifiés

Fichier créé :

```text
packages/map_editor/test/element_collision_editor_sheet_fine_mask_test.dart
```

Tests ajoutés :

- `collision editor sheet exposes grid and fine mask authoring modes`
- `fine mask mode shows collision and occlusion mask labels`
- `nested element edit sheet can open the collision editor`
- `profile with collisionMask opens with fine collision visible`
- `saving preserves existing collision visual and occlusion masks`
- `triple mask editor starts in paint collision mode`
- `triple mask editor paints a visible brush footprint`
- `triple mask editor sculpts legacy grid collision by default`
- `triple mask editor exposes explicit erase mode`

Aucun test existant n’a été modifié.

## 13. Commandes lancées

Statut / audit :

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
sed -n '1,260p' packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart
sed -n '260,560p' packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart
sed -n '1,260p' packages/map_editor/test/element_collision_editor_sheet_overflow_test.dart
rg -n "showElementCollisionEditorSheet|ElementCollisionTripleMaskEditor|collisionMask|occlusionMask|visualMask|_buildSavedProfile|_draftProfile|_draftPadding|Collision fine|Masque fin|Collision par grille|Aperçu|Pinceau|Polygone|overflow" packages/map_editor/lib packages/map_editor/test
```

TDD / debug :

```bash
cd packages/map_editor
flutter test --no-pub --reporter expanded test/element_collision_editor_sheet_fine_mask_test.dart
```

Format / validation finale :

```bash
cd packages/map_editor
dart format lib/src/ui/widgets/element_collision_triple_mask_editor.dart test/element_collision_editor_sheet_fine_mask_test.dart
```

```bash
cd packages/map_editor
flutter test --no-pub --reporter compact test/element_collision_editor_sheet_fine_mask_test.dart test/element_collision_editor_sheet_overflow_test.dart test/element_collision_truth_summary_test.dart test/player_collision_hitbox_preview_test.dart
```

```bash
cd packages/map_editor
flutter test --no-pub --reporter compact test/element_collision_authoring_service_test.dart test/element_collision_shape_rasterizer_service_test.dart test/project_element_collision_persistence_test.dart test/project_element_collision_file_repository_roundtrip_test.dart test/collision_building_golden_slice_test.dart
```

```bash
cd packages/map_editor
flutter analyze lib/src/ui/panels/element_collision_editor_sheet.dart lib/src/ui/widgets/element_collision_triple_mask_editor.dart test/element_collision_editor_sheet_fine_mask_test.dart test/element_collision_editor_sheet_overflow_test.dart
```

Périmètre :

```bash
git diff --name-only
git diff --stat
git status --short --untracked-files=all
```

## 14. Résultats des tests ciblés

Test rouge initial après création du test :

```text
Expected: exactly one matching candidate
  Actual: Found 0 widgets with text "Masque fin"

Expected: collisionMask dataBase64
  Actual: <null>
```

Tests rouges ajoutés après retour manuel sur l’UX :

```text
Expected: exactly one matching candidate
  Actual: Found 0 widgets with text "Peindre collision"

The finder "Found 0 widgets with text "Effacer"" could not find any matching widgets.
```

Tests rouges du correctif "clic qui ne fait rien" :

```text
Expected: a value greater than <1>
  Actual: <1>

Expected: exactly one matching candidate
  Actual: _TextContainingWidgetFinder:<Found 0 widgets with text containing Effacer est sélectionné:
[]>
```

Après modification, test dédié :

```text
00:00 +0: collision editor sheet exposes grid and fine mask authoring modes
00:00 +1: fine mask mode shows collision and occlusion mask labels
00:00 +2: nested element edit sheet can open the collision editor
00:01 +3: profile with collisionMask opens with fine collision visible
00:01 +4: saving preserves existing collision visual and occlusion masks
00:01 +5: triple mask editor starts in paint collision mode
00:01 +6: triple mask editor paints a visible brush footprint
00:01 +7: triple mask editor sculpts legacy grid collision by default
00:01 +8: triple mask editor exposes explicit erase mode
00:01 +9: All tests passed!
```

Après modification, tests sheet/truth/hitbox/overflow :

```text
00:03 +18: All tests passed!
```

Après modification, tests collision editor existants :

```text
00:02 +41: All tests passed!
```

## 15. Analyse statique / format

Format final :

```text
Formatted 2 files (0 changed) in 0.02 seconds.
```

Analyse ciblée :

```text
Analyzing 4 items...
No issues found! (ran in 2.5s)
```

Note : `flutter analyze` a imprimé les lignes habituelles de résolution de dépendances et versions disponibles, sans modifier de fichier suivi.

## 16. Vérification du périmètre

`git diff --name-only` :

```text
packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart
packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart
```

`git diff --stat` :

```text
 .../ui/panels/element_collision_editor_sheet.dart  | 607 +++++++++++++--------
 .../element_collision_triple_mask_editor.dart      | 149 ++++-
 2 files changed, 511 insertions(+), 245 deletions(-)
```

Inventaire complet :

| Catégorie | Fichiers |
|---|---|
| Créés | `packages/map_editor/test/element_collision_editor_sheet_fine_mask_test.dart` |
| Créés | `reports/collision/collision_lot_10bis_fine_collision_mask_authoring_ui.md` |
| Modifiés | `packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart` |
| Modifiés | `packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart` |
| Supprimés | Aucun |
| Générés | Aucun |
| Fichiers hors lot touchés | Aucun |
| Untracked touchés | les deux fichiers créés ci-dessus |

Aucun fichier `packages/map_core/**`, `packages/map_gameplay/**`, `packages/map_runtime/**`, generated ou repository n’apparaît dans le périmètre.

## 17. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart
 M packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart
?? packages/map_editor/test/element_collision_editor_sheet_fine_mask_test.dart
?? reports/collision/collision_lot_10bis_fine_collision_mask_authoring_ui.md
```

## 18. git diff --stat

```text
 .../ui/panels/element_collision_editor_sheet.dart  | 607 +++++++++++++--------
 .../element_collision_triple_mask_editor.dart      | 149 ++++-
 2 files changed, 511 insertions(+), 245 deletions(-)
```

## 19. Risques / réserves

- Le test widget prouve que la sheet expose le mode fin, que le triple editor démarre en peinture collision, que `Effacer` existe et que l’émission de `collisionMask` fonctionne.
- Le test widget prouve aussi qu’un clic applique une empreinte visible, et qu’un profil legacy rempli démarre en gomme pour sculpter la grille existante.
- Le test ne couvre pas un long drag multi-segments dans la sheet modale elle-même.
- L’action `Vider toute collision` reste le clear coarse existant ; elle n’a pas été transformée en dialogue de confirmation multi-mode.
- Le mode masque fin est une surface pixel simple, pas une simulation de déplacement joueur.
- La suite complète `packages/map_editor` n’a pas été lancée dans ce lot.

Non vérifié.

**Sujet :**
Suite complète `packages/map_editor`.

**Raison :**
Le lot est limité à la sheet collision et aux tests associés. Les commandes ciblées couvrent la régression UI, la préservation des masks, le triple editor, les tests collision editor existants, la persistence collision et la golden slice bâtiment.

**Impact :**
Une régression très éloignée de l’éditeur collision ne serait pas détectée par ce lot.

**Comment vérifier dans Collision-11 :**
Lancer `cd packages/map_editor && flutter test --no-pub --reporter compact` et documenter les éventuels échecs par domaine.

## 20. Ce que ce lot prouve

- La sheet principale expose un mode `Masque fin`.
- La sheet conserve un mode `Collision par grille`.
- Le mode `Masque fin` affiche `ElementCollisionTripleMaskEditor`.
- Un profil avec `collisionMask` ouvre avec `Collision fine active` visible.
- Le triple editor démarre directement en `Peindre collision`.
- Le bouton `Effacer` permet d’effacer explicitement des pixels collision.
- Un profil legacy grille rempli démarre en `Effacer`, pour rendre le premier clic utile.
- Un clic applique une empreinte de pinceau visible, pas un unique pixel discret.
- La taille de pinceau est visible et réglable.
- La sauvegarde ne perd pas `collisionMask`, `visualMask` ou `occlusionMask`.
- Le triple editor peut créer un `collisionMask` après interaction de peinture.
- Les labels `Masque collision`, `Masque occlusion` et `ne bloque pas` restent visibles.
- Le test overflow de la sheet reste vert.
- Le périmètre reste limité à `map_editor` UI/tests.

## 21. Ce que ce lot ne prouve pas encore

- Il ne prouve pas une UX de peinture fine avancée avec zoom dédié ou aperçu hitbox superposé sur la zone peinte.
- Il ne prouve pas la génération automatique depuis alpha/image.
- Il ne branche pas l’occlusion runtime.
- Il ne teste pas un screenshot golden Flutter.
- Il ne modifie pas les heuristiques de `PlacedElementAutoCollisionGenerator`.

## 22. Recommandation après Collision-10-bis

Recommandation : refaire le test manuel sur une maison réelle avec le mode `Masque fin` :

1. ouvrir la collision de l’élément ;
2. basculer sur `Masque fin` ;
3. vérifier que `Peindre collision` est actif ;
4. si le bâtiment vient de la grille, utiliser l’état initial `Effacer` pour retirer le toit ;
5. ajuster la taille du pinceau si nécessaire ;
6. sauvegarder ;
7. rouvrir l’élément et vérifier `Collision fine active` ;
8. tester le placement en gameplay.

Si ce flux manuel est satisfaisant, Collision-11 peut se concentrer sur l’alignement de la génération automatique / heuristiques alpha. Si le dessin pixel reste trop pénible, le prochain lot produit devrait améliorer le zoom, l’aperçu de pinceau et les actions `Remplir depuis visuel` / `Effacer tout` avant de toucher aux heuristiques.

## 23. Auto-review finale

| Question | Réponse |
|---|---|
| Ai-je limité le lot à map_editor UI/tests ? | Oui. |
| Ai-je évité map_core ? | Oui. |
| Ai-je évité map_gameplay ? | Oui. |
| Ai-je évité map_runtime ? | Oui. |
| Ai-je évité FileProjectRepository ? | Oui. |
| Ai-je évité le normalizer ? | Oui. |
| Ai-je évité build_runner/generated ? | Oui. |
| Ai-je utilisé ElementCollisionTripleMaskEditor au lieu de créer un nouveau système ? | Oui. |
| Ai-je conservé le mode grille ? | Oui. |
| Ai-je ajouté un mode masque fin clair ? | Oui. |
| Ai-je rendu l’édition fine immédiatement active ? | Oui, `Peindre collision` est le mode initial quand il n’y a pas de grille legacy remplie. |
| Ai-je rendu l’effacement visible ? | Oui, bouton `Effacer`. |
| Ai-je rendu le premier clic utile sur une grille legacy remplie ? | Oui, `Effacer` est sélectionné par défaut dans ce cas. |
| Ai-je rendu un clic visible ? | Oui, via taille de pinceau pixel par défaut et réglable. |
| Ai-je préservé collisionMask à la sauvegarde ? | Oui, testé avec collision, visual et occlusion masks. |
| Ai-je évité d’exposer pixelMask comme jargon principal ? | Oui. |
| Ai-je clarifié que occlusion ne bloque pas ? | Oui, via le triple mask editor affiché dans la sheet. |
| Ai-je relancé le test overflow ? | Oui, inclus dans `+18`. |
| Ai-je documenté ce qui reste non prouvé ? | Oui. |

## 24. Contenu complet des fichiers créés/modifiés

Le rapport lui-même n’est pas reproduit récursivement dans cette section. Les fichiers code/test créés ou modifiés par le lot sont reproduits ci-dessous.

### packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart

```dart
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../application/models/element_collision_truth_summary.dart';
import '../../application/models/player_collision_hitbox_preview.dart';
import '../../application/services/element_collision_authoring_service.dart';
import '../../ui/shared/cupertino_editor_widgets.dart';
import '../../ui/widgets/element_collision_triple_mask_editor.dart';

const ElementCollisionAuthoringService _authoringService =
    ElementCollisionAuthoringService();

enum _ElementCollisionAuthoringMode {
  grid,
  fineMask,
}

Future<ElementCollisionProfile?> showElementCollisionEditorSheet({
  required BuildContext context,
  required String elementName,
  required ui.Image image,
  required TilesetSourceRect source,
  required int tileWidth,
  required int tileHeight,
  ElementCollisionProfile? initialProfile,
  WarpTriggerPadding fallbackPadding = const WarpTriggerPadding(),
}) {
  return showMacosEditorTallSheet<ElementCollisionProfile>(
    context: context,
    heightFraction: 0.92,
    maxWidth: 1180,
    builder: (ctx) => _ElementCollisionEditorSheet(
      elementName: elementName,
      image: image,
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      initialProfile: initialProfile,
      fallbackPadding: fallbackPadding,
    ),
  );
}

class _ElementCollisionEditorSheet extends StatefulWidget {
  const _ElementCollisionEditorSheet({
    required this.elementName,
    required this.image,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
    required this.initialProfile,
    required this.fallbackPadding,
  });

  final String elementName;
  final ui.Image image;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;
  final ElementCollisionProfile? initialProfile;
  final WarpTriggerPadding fallbackPadding;

  @override
  State<_ElementCollisionEditorSheet> createState() =>
      _ElementCollisionEditorSheetState();
}

class _ElementCollisionEditorSheetState
    extends State<_ElementCollisionEditorSheet> {
  _ElementCollisionEditorTool _tool = _ElementCollisionEditorTool.preview;
  ElementCollisionProfile? _draftProfile;
  late WarpTriggerPadding _draftPadding;
  bool _showGrid = true;
  bool _showBase = true;
  bool _showFinal = true;
  bool _showOverrides = true;
  late _ElementCollisionAuthoringMode _authoringMode;
  final List<Offset> _pendingPolygon = <Offset>[];
  Offset? _lastBrushPoint;
  Offset? _hoverGridPoint;

  @override
  void initState() {
    super.initState();
    _draftProfile = widget.initialProfile;
    _draftPadding = widget.initialProfile?.padding ?? widget.fallbackPadding;
    _authoringMode = widget.initialProfile?.collisionMask != null
        ? _ElementCollisionAuthoringMode.fineMask
        : _ElementCollisionAuthoringMode.grid;
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _describe();
    final truthSummary = summarizeElementCollisionTruth(_draftProfile);
    final playerHitboxPreview = buildPlayerCollisionHitboxPreview();
    final pendingPolygonPreviewCells = _buildPendingPolygonPreviewCells();
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    return LayoutBuilder(
      builder: (context, constraints) => Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) {
            return KeyEventResult.ignored;
          }
          if (_isPolygonTool(_tool) &&
              event.logicalKey == LogicalKeyboardKey.enter &&
              _pendingPolygon.length >= 3) {
            _closeAndApplyPendingPolygon();
            return KeyEventResult.handled;
          }
          if (_isPolygonTool(_tool) &&
              event.logicalKey == LogicalKeyboardKey.escape &&
              _pendingPolygon.isNotEmpty) {
            setState(() {
              _pendingPolygon.clear();
              _hoverGridPoint = null;
            });
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EditorHeader(
                  elementName: widget.elementName,
                  source: widget.source,
                  finalCellCount: snapshot.finalCells.length,
                  onCancel: () => Navigator.of(context).pop(),
                  onSave: () => Navigator.of(context).pop(_buildSavedProfile()),
                ),
                const SizedBox(height: 14),
                if (_authoringMode == _ElementCollisionAuthoringMode.grid) ...[
                  _EditorToolbar(
                    tool: _tool,
                    pendingPolygonCount: _pendingPolygon.length,
                    onToolChanged: (tool) {
                      setState(() {
                        _tool = tool;
                        _lastBrushPoint = null;
                        _hoverGridPoint = null;
                        if (!_isPolygonTool(tool)) {
                          _pendingPolygon.clear();
                        }
                      });
                    },
                    onClosePolygon: _pendingPolygon.length >= 3
                        ? _closeAndApplyPendingPolygon
                        : null,
                    onClearPolygon: _pendingPolygon.isNotEmpty
                        ? () => setState(() {
                              _pendingPolygon.clear();
                              _hoverGridPoint = null;
                            })
                        : null,
                    onResetOverrides: () {
                      setState(() {
                        final next = _authoringService.resetOverrides(
                          source: widget.source,
                          tileWidth: widget.tileWidth,
                          tileHeight: widget.tileHeight,
                          current: _draftProfile,
                          fallbackPadding: _draftPadding,
                        );
                        _draftProfile = _preserveDraftMasks(next);
                        _draftPadding = _draftProfile?.padding ?? _draftPadding;
                      });
                    },
                    onRestoreBase: () {
                      setState(() {
                        final next = _authoringService.usePaddingAsPrimaryBase(
                          source: widget.source,
                          tileWidth: widget.tileWidth,
                          tileHeight: widget.tileHeight,
                          padding: _draftPadding,
                        );
                        _draftProfile = _preserveDraftMasks(next);
                      });
                    },
                    onClearAll: () {
                      setState(() {
                        _draftProfile = _authoringService.clearAllCollision(
                          source: widget.source,
                          tileWidth: widget.tileWidth,
                          tileHeight: widget.tileHeight,
                          current: _draftProfile,
                          fallbackPadding: _draftPadding,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                ],
                _CollisionTruthBanner(summary: truthSummary),
                const SizedBox(height: 10),
                _PlayerFootHitboxPreviewCard(preview: playerHitboxPreview),
                const SizedBox(height: 8),
                _CollisionAuthoringModeSelector(
                  mode: _authoringMode,
                  onChanged: (mode) {
                    setState(() {
                      _authoringMode = mode;
                      _lastBrushPoint = null;
                      _hoverGridPoint = null;
                      _pendingPolygon.clear();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _authoringMode ==
                          _ElementCollisionAuthoringMode.fineMask
                      ? CupertinoScrollbar(
                          child: SingleChildScrollView(
                            child: ElementCollisionTripleMaskEditor(
                              image: widget.image,
                              source: widget.source,
                              tileWidth: widget.tileWidth,
                              tileHeight: widget.tileHeight,
                              profile: _draftProfile,
                              draftPadding: _draftPadding,
                              onProfileChanged: (next) {
                                setState(() {
                                  _draftProfile = next;
                                  _draftPadding =
                                      next?.padding ?? _draftPadding;
                                });
                              },
                            ),
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: EditorChrome.largeIslandSurfaceColor(
                                    context,
                                    tint: Colors.white.withValues(alpha: 0.02),
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: CupertinoColors.separator
                                        .resolveFrom(context),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Forme de collision',
                                          style: TextStyle(
                                            color: label,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Flexible(
                                          child: Text(
                                            _tool.helpLabel,
                                            textAlign: TextAlign.right,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: secondary,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Expanded(
                                      child: LayoutBuilder(
                                        builder: (context, canvasConstraints) {
                                          final canvasSize = Size(
                                            canvasConstraints.maxWidth,
                                            canvasConstraints.maxHeight,
                                          );
                                          return MouseRegion(
                                            cursor: _tool ==
                                                    _ElementCollisionEditorTool
                                                        .preview
                                                ? SystemMouseCursors.basic
                                                : SystemMouseCursors.precise,
                                            onHover: (event) {
                                              final next = _localToGridPoint(
                                                event.localPosition,
                                                canvasSize,
                                              );
                                              if (next == _hoverGridPoint) {
                                                return;
                                              }
                                              setState(
                                                  () => _hoverGridPoint = next);
                                            },
                                            onExit: (_) {
                                              if (_hoverGridPoint != null) {
                                                setState(() =>
                                                    _hoverGridPoint = null);
                                              }
                                            },
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTapUp: (details) =>
                                                  _handleCanvasTap(
                                                      details.localPosition,
                                                      canvasSize),
                                              onDoubleTapDown: (details) =>
                                                  _handleCanvasDoubleTap(
                                                details.localPosition,
                                                canvasSize,
                                              ),
                                              onPanStart: (details) =>
                                                  _handleCanvasPanStart(
                                                details.localPosition,
                                                canvasSize,
                                              ),
                                              onPanUpdate: (details) =>
                                                  _handleCanvasPanUpdate(
                                                details.localPosition,
                                                canvasSize,
                                              ),
                                              onPanEnd: (_) =>
                                                  _lastBrushPoint = null,
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  color: Colors.black
                                                      .withValues(alpha: 0.14),
                                                  border: Border.all(
                                                    color: CupertinoColors
                                                        .separator
                                                        .resolveFrom(context),
                                                  ),
                                                ),
                                                child: CustomPaint(
                                                  painter:
                                                      _ElementCollisionCanvasPainter(
                                                    image: widget.image,
                                                    source: widget.source,
                                                    tileWidth: widget.tileWidth,
                                                    tileHeight:
                                                        widget.tileHeight,
                                                    snapshot: snapshot,
                                                    showGrid: _showGrid,
                                                    showBase: _showBase,
                                                    showFinal: _showFinal,
                                                    showOverrides:
                                                        _showOverrides,
                                                    pendingPolygon:
                                                        _pendingPolygon,
                                                    pendingPolygonPreviewCells:
                                                        pendingPolygonPreviewCells,
                                                    hoverGridPoint:
                                                        _hoverGridPoint,
                                                    highlightPolygonClosure:
                                                        _shouldHighlightPolygonClosure,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            SizedBox(
                              width: 320,
                              child: CupertinoScrollbar(
                                child: SingleChildScrollView(
                                  child: _EditorSidebar(
                                    source: widget.source,
                                    snapshot: snapshot,
                                    truthSummary: truthSummary,
                                    showGrid: _showGrid,
                                    showBase: _showBase,
                                    showFinal: _showFinal,
                                    showOverrides: _showOverrides,
                                    pendingPolygonPreviewCount:
                                        pendingPolygonPreviewCells.length,
                                    onShowGridChanged: (value) =>
                                        setState(() => _showGrid = value),
                                    onShowBaseChanged: (value) =>
                                        setState(() => _showBase = value),
                                    onShowFinalChanged: (value) =>
                                        setState(() => _showFinal = value),
                                    onShowOverridesChanged: (value) =>
                                        setState(() => _showOverrides = value),
                                    paddingEditor:
                                        ElementCollisionPaddingEditor(
                                      padding: _draftPadding,
                                      usesManualPrimaryShape:
                                          snapshot.usesManualPrimaryShape,
                                      maxHorizontal: math.max(
                                          0,
                                          widget.source.width *
                                                  widget.tileWidth -
                                              1),
                                      maxVertical: math.max(
                                          0,
                                          widget.source.height *
                                                  widget.tileHeight -
                                              1),
                                      onChanged: (next) {
                                        setState(() {
                                          _draftPadding = next;
                                          final recalculated = _authoringService
                                              .recalculateFromPadding(
                                            source: widget.source,
                                            tileWidth: widget.tileWidth,
                                            tileHeight: widget.tileHeight,
                                            padding: next,
                                            current: _draftProfile,
                                          );
                                          _draftProfile =
                                              _preserveDraftMasks(recalculated);
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ElementCollisionAuthoringSnapshot _describe() {
    return _authoringService.describe(
      source: widget.source,
      tileWidth: widget.tileWidth,
      tileHeight: widget.tileHeight,
      profile: _draftProfile,
      fallbackPadding: _draftPadding,
    );
  }

  List<GridPos> _buildPendingPolygonPreviewCells() {
    if (!_isPolygonTool(_tool) || _pendingPolygon.length < 3) {
      return const <GridPos>[];
    }
    // The polygon itself is the authoring truth while editing. These preview
    // cells are the backend projection that will actually reach runtime after
    // closing/saving, so the author can judge the conversion before commit.
    return _authoringService.shapeRasterizerService.rasterizePolygon(
      vertices: _pendingPolygon,
      gridWidth: widget.source.width,
      gridHeight: widget.source.height,
    );
  }

  ElementCollisionProfile _buildSavedProfile() {
    final snapshot = _describe();
    final rebuilt = _authoringService.rebuild(
      source: widget.source,
      tileWidth: widget.tileWidth,
      tileHeight: widget.tileHeight,
      sourceMode: snapshot.source,
      padding: snapshot.padding,
      shapeCells: snapshot.shapeCells,
      manualAddedCells: snapshot.manualAddedCells,
      manualRemovedCells: snapshot.manualRemovedCells,
    );
    return _preserveDraftMasks(rebuilt);
  }

  ElementCollisionProfile _preserveDraftMasks(ElementCollisionProfile next) {
    final current = _draftProfile;
    if (current == null) {
      return next;
    }
    if (current.visualMask == null &&
        current.collisionMask == null &&
        current.occlusionMask == null) {
      return next;
    }
    return next.copyWith(
      visualMask: current.visualMask,
      collisionMask: current.collisionMask,
      occlusionMask: current.occlusionMask,
    );
  }

  void _closeAndApplyPendingPolygon() {
    if (_pendingPolygon.length < 3) {
      return;
    }
    final operation = _tool.operation;
    if (operation == null) {
      return;
    }
    setState(() {
      final next = _authoringService.applyPolygon(
        source: widget.source,
        tileWidth: widget.tileWidth,
        tileHeight: widget.tileHeight,
        vertices: List<Offset>.from(_pendingPolygon),
        operation: operation,
        current: _draftProfile,
        fallbackPadding: _draftPadding,
      );
      _draftProfile = _preserveDraftMasks(next);
      _pendingPolygon.clear();
      _hoverGridPoint = null;
    });
  }

  void _handleCanvasTap(Offset localPosition, Size canvasSize) {
    if (_tool == _ElementCollisionEditorTool.preview) {
      return;
    }
    final gridPoint = _localToGridPoint(localPosition, canvasSize);
    if (gridPoint == null) {
      return;
    }
    if (_isPolygonTool(_tool)) {
      if (_pendingPolygon.length >= 3 &&
          _isNearPolygonStart(gridPoint, _pendingPolygon.first)) {
        _closeAndApplyPendingPolygon();
        return;
      }
      setState(() {
        _pendingPolygon.add(gridPoint);
      });
      return;
    }

    final operation = _tool.operation;
    if (operation == null) {
      return;
    }
    setState(() {
      final next = _authoringService.applyBrushStroke(
        source: widget.source,
        tileWidth: widget.tileWidth,
        tileHeight: widget.tileHeight,
        points: <Offset>[gridPoint],
        operation: operation,
        current: _draftProfile,
        fallbackPadding: _draftPadding,
      );
      _draftProfile = _preserveDraftMasks(next);
    });
  }

  void _handleCanvasDoubleTap(Offset localPosition, Size canvasSize) {
    if (!_isPolygonTool(_tool) || _pendingPolygon.length < 3) {
      return;
    }
    final gridPoint = _localToGridPoint(localPosition, canvasSize);
    if (gridPoint == null) {
      return;
    }
    setState(() => _hoverGridPoint = gridPoint);
    _closeAndApplyPendingPolygon();
  }

  void _handleCanvasPanStart(Offset localPosition, Size canvasSize) {
    if (!_isBrushTool(_tool)) {
      return;
    }
    final gridPoint = _localToGridPoint(localPosition, canvasSize);
    if (gridPoint == null) {
      return;
    }
    _lastBrushPoint = gridPoint;
    final operation = _tool.operation;
    if (operation == null) {
      return;
    }
    setState(() {
      final next = _authoringService.applyBrushStroke(
        source: widget.source,
        tileWidth: widget.tileWidth,
        tileHeight: widget.tileHeight,
        points: <Offset>[gridPoint],
        operation: operation,
        current: _draftProfile,
        fallbackPadding: _draftPadding,
      );
      _draftProfile = _preserveDraftMasks(next);
    });
  }

  void _handleCanvasPanUpdate(Offset localPosition, Size canvasSize) {
    if (!_isBrushTool(_tool)) {
      return;
    }
    final gridPoint = _localToGridPoint(localPosition, canvasSize);
    if (gridPoint == null) {
      return;
    }
    final previous = _lastBrushPoint;
    final operation = _tool.operation;
    if (previous == null || operation == null) {
      _lastBrushPoint = gridPoint;
      return;
    }
    if ((previous - gridPoint).distance < 0.001) {
      return;
    }
    setState(() {
      final next = _authoringService.applyBrushStroke(
        source: widget.source,
        tileWidth: widget.tileWidth,
        tileHeight: widget.tileHeight,
        points: <Offset>[previous, gridPoint],
        operation: operation,
        current: _draftProfile,
        fallbackPadding: _draftPadding,
      );
      _draftProfile = _preserveDraftMasks(next);
      _lastBrushPoint = gridPoint;
    });
  }

  Offset? _localToGridPoint(Offset localPosition, Size canvasSize) {
    final targetRect = _fitCollisionPreviewRect(
      size: canvasSize,
      source: widget.source,
      tileWidth: widget.tileWidth,
      tileHeight: widget.tileHeight,
      padding: 24,
    );
    if (!targetRect.contains(localPosition)) {
      return null;
    }
    final localX = localPosition.dx - targetRect.left;
    final localY = localPosition.dy - targetRect.top;
    final gridX = (localX / targetRect.width) * widget.source.width;
    final gridY = (localY / targetRect.height) * widget.source.height;
    return Offset(gridX, gridY);
  }

  bool _isBrushTool(_ElementCollisionEditorTool tool) {
    return tool == _ElementCollisionEditorTool.brushAdd ||
        tool == _ElementCollisionEditorTool.brushRemove;
  }

  bool _isPolygonTool(_ElementCollisionEditorTool tool) {
    return tool == _ElementCollisionEditorTool.polygonAdd ||
        tool == _ElementCollisionEditorTool.polygonRemove;
  }

  bool get _shouldHighlightPolygonClosure {
    if (!_isPolygonTool(_tool) ||
        _pendingPolygon.length < 3 ||
        _hoverGridPoint == null) {
      return false;
    }
    return _isNearPolygonStart(_hoverGridPoint!, _pendingPolygon.first);
  }

  bool _isNearPolygonStart(Offset point, Offset start) {
    return (point - start).distance <= 0.45;
  }
}

class _EditorHeader extends StatelessWidget {
  const _EditorHeader({
    required this.elementName,
    required this.source,
    required this.finalCellCount,
    required this.onCancel,
    required this.onSave,
  });

  final String elementName;
  final TilesetSourceRect source;
  final int finalCellCount;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Collision Editor',
                style: editorMacosSheetTitleStyle(context),
              ),
              const SizedBox(height: 4),
              Text(
                '$elementName • source ${source.width}x${source.height} • $finalCellCount cellule${finalCellCount > 1 ? 's' : ''} finales',
                style: TextStyle(
                  color: secondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        PushButton(
          controlSize: ControlSize.large,
          secondary: true,
          onPressed: onCancel,
          child: const Text('Annuler'),
        ),
        const SizedBox(width: 10),
        PushButton(
          controlSize: ControlSize.large,
          onPressed: onSave,
          child: const Text('Sauvegarder'),
        ),
      ],
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar({
    required this.tool,
    required this.pendingPolygonCount,
    required this.onToolChanged,
    required this.onClosePolygon,
    required this.onClearPolygon,
    required this.onResetOverrides,
    required this.onRestoreBase,
    required this.onClearAll,
  });

  final _ElementCollisionEditorTool tool;
  final int pendingPolygonCount;
  final ValueChanged<_ElementCollisionEditorTool> onToolChanged;
  final VoidCallback? onClosePolygon;
  final VoidCallback? onClearPolygon;
  final VoidCallback onResetOverrides;
  final VoidCallback onRestoreBase;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final value in _ElementCollisionEditorTool.values)
          _ToolButton(
            label: value.label,
            selected: tool == value,
            onPressed: () => onToolChanged(value),
          ),
        if (tool == _ElementCollisionEditorTool.polygonAdd ||
            tool == _ElementCollisionEditorTool.polygonRemove)
          _ToolbarAction(
            label: 'Fermer le polygone ($pendingPolygonCount)',
            onPressed: onClosePolygon,
          ),
        if (tool == _ElementCollisionEditorTool.polygonAdd ||
            tool == _ElementCollisionEditorTool.polygonRemove)
          _ToolbarAction(
            label: 'Effacer le polygone',
            onPressed: onClearPolygon,
          ),
        _ToolbarAction(
          label: 'Réinitialiser retouches',
          onPressed: onResetOverrides,
        ),
        _ToolbarAction(
          label: 'Utiliser le padding comme base',
          onPressed: onRestoreBase,
        ),
        _ToolbarAction(
          label: 'Vider toute collision',
          onPressed: onClearAll,
        ),
      ],
    );
  }
}

class _EditorSidebar extends StatelessWidget {
  const _EditorSidebar({
    required this.source,
    required this.snapshot,
    required this.truthSummary,
    required this.showGrid,
    required this.showBase,
    required this.showFinal,
    required this.showOverrides,
    required this.onShowGridChanged,
    required this.onShowBaseChanged,
    required this.onShowFinalChanged,
    required this.onShowOverridesChanged,
    this.pendingPolygonPreviewCount = 0,
    required this.paddingEditor,
  });

  final TilesetSourceRect source;
  final ElementCollisionAuthoringSnapshot snapshot;
  final ElementCollisionTruthSummary truthSummary;
  final bool showGrid;
  final bool showBase;
  final bool showFinal;
  final bool showOverrides;
  final ValueChanged<bool> onShowGridChanged;
  final ValueChanged<bool> onShowBaseChanged;
  final ValueChanged<bool> onShowFinalChanged;
  final ValueChanged<bool> onShowOverridesChanged;
  final int pendingPolygonPreviewCount;
  final Widget paddingEditor;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SidebarSection(
          title: 'Résumé',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _LegendChip(
                    label: snapshot.usesManualPrimaryShape
                        ? 'Forme principale ${snapshot.baseCells.length}'
                        : 'Base padding ${snapshot.baseCells.length}',
                    color: Colors.cyanAccent,
                  ),
                  _LegendChip(
                    label: '+ ${snapshot.manualAddedCells.length}',
                    color: Colors.greenAccent,
                  ),
                  _LegendChip(
                    label: '- ${snapshot.manualRemovedCells.length}',
                    color: Colors.redAccent,
                  ),
                  _LegendChip(
                    label: 'Final ${snapshot.finalCells.length}',
                    color: EditorChrome.inspectorJoyCoral,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                truthSummary.mode == ElementCollisionTruthMode.fineMask
                    ? 'Le gameplay utilise le masque fin. Les ${snapshot.finalCells.length} cellule${snapshot.finalCells.length > 1 ? 's' : ''} affichées ici servent de projection de compatibilité.'
                    : 'Le gameplay utilise ${snapshot.finalCells.length} cellule${snapshot.finalCells.length > 1 ? 's' : ''} de grille quand aucun masque fin n’est défini.',
                style: TextStyle(
                  color: secondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Source sprite: ${source.width} colonnes × ${source.height} lignes',
                style: TextStyle(
                  color: secondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                snapshot.source == ElementCollisionProfileSource.manual
                    ? 'Base métier actuelle: forme principale auteur. Le padding reste disponible comme aide secondaire, mais il ne reprend pas la main au rebuild.'
                    : 'Base métier actuelle: padding automatique. Utilisez un polygone forme si vous voulez remplacer cette base par une vraie silhouette de bâtiment.',
                style: TextStyle(
                  color: secondary,
                  fontSize: 11,
                ),
              ),
              if (pendingPolygonPreviewCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Preview backend polygone: $pendingPolygonPreviewCount cellule${pendingPolygonPreviewCount > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SidebarSection(
          title: 'Padding auto',
          child: paddingEditor,
        ),
        const SizedBox(height: 12),
        _SidebarSection(
          title: 'Affichage',
          child: Column(
            children: [
              _DisplayToggle(
                label: 'Grille',
                value: showGrid,
                onChanged: onShowGridChanged,
              ),
              _DisplayToggle(
                label: snapshot.usesManualPrimaryShape
                    ? 'Forme principale'
                    : 'Base padding',
                value: showBase,
                onChanged: onShowBaseChanged,
              ),
              _DisplayToggle(
                label: 'Retouches manuelles',
                value: showOverrides,
                onChanged: onShowOverridesChanged,
              ),
              _DisplayToggle(
                label: 'Forme finale',
                value: showFinal,
                onChanged: onShowFinalChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SidebarSection(
          title: 'Aide',
          child: Text(
            'Polygone forme: définit une base coarse de bâtiment. Pinceau + / -: applique des retouches locales. Le padding auto reste un outil secondaire pour les cas simples. Le gameplay suit la source active affichée en haut.',
            style: TextStyle(
              color: secondary,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _CollisionAuthoringModeSelector extends StatelessWidget {
  const _CollisionAuthoringModeSelector({
    required this.mode,
    required this.onChanged,
  });

  final _ElementCollisionAuthoringMode mode;
  final ValueChanged<_ElementCollisionAuthoringMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Row(
      children: [
        CupertinoSlidingSegmentedControl<_ElementCollisionAuthoringMode>(
          groupValue: mode,
          children: const {
            _ElementCollisionAuthoringMode.grid: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                'Collision par grille',
                style: TextStyle(fontSize: 11),
              ),
            ),
            _ElementCollisionAuthoringMode.fineMask: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                'Masque fin',
                style: TextStyle(fontSize: 11),
              ),
            ),
          },
          onValueChanged: (next) {
            if (next != null) {
              onChanged(next);
            }
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            mode == _ElementCollisionAuthoringMode.fineMask
                ? 'Masque pixel fin : priorité gameplay.'
                : 'Grille : fallback et retouches coarse.',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: secondary, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _CollisionTruthBanner extends StatelessWidget {
  const _CollisionTruthBanner({required this.summary});

  final ElementCollisionTruthSummary summary;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    final accent = switch (summary.mode) {
      ElementCollisionTruthMode.fineMask => Colors.redAccent,
      ElementCollisionTruthMode.legacyCells => Colors.orangeAccent,
      ElementCollisionTruthMode.empty => Colors.greenAccent,
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Source utilisée par le gameplay',
            style: TextStyle(
              color: secondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary.title,
            style: TextStyle(
              color: label,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            summary.description,
            style: TextStyle(color: secondary, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            summary.detail,
            style: TextStyle(color: secondary, fontSize: 11),
          ),
          for (final note in summary.notes) ...[
            const SizedBox(height: 2),
            Text(
              note,
              style: TextStyle(color: secondary, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayerFootHitboxPreviewCard extends StatelessWidget {
  const _PlayerFootHitboxPreviewCard({required this.preview});

  final PlayerCollisionHitboxPreview preview;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blueAccent.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: CustomPaint(
              painter: _PlayerFootHitboxPreviewPainter(preview),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  preview.title,
                  style: TextStyle(
                    color: label,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  preview.description,
                  style: TextStyle(color: secondary, fontSize: 11),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _LegendChip(
                      label: preview.dimensionsLabel,
                      color: Colors.blueAccent,
                    ),
                    _LegendChip(
                      label: preview.positionLabel,
                      color: Colors.lightBlueAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerFootHitboxPreviewPainter extends CustomPainter {
  const _PlayerFootHitboxPreviewPainter(this.preview);

  final PlayerCollisionHitboxPreview preview;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / preview.spriteWidthPx,
      size.height / preview.spriteHeightPx,
    );
    final spriteWidth = preview.spriteWidthPx * scale;
    final spriteHeight = preview.spriteHeightPx * scale;
    final spriteRect = Rect.fromLTWH(
      (size.width - spriteWidth) / 2,
      (size.height - spriteHeight) / 2,
      spriteWidth,
      spriteHeight,
    );
    final hitboxRect = Rect.fromLTWH(
      spriteRect.left + preview.hitboxLeftPx * scale,
      spriteRect.top + preview.hitboxTopPx * scale,
      preview.hitboxWidthPx * scale,
      preview.hitboxHeightPx * scale,
    );

    final spritePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    final spriteStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final hitboxPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.38)
      ..style = PaintingStyle.fill;
    final hitboxStroke = Paint()
      ..color = Colors.lightBlueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(spriteRect, const Radius.circular(8)),
      spritePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(spriteRect, const Radius.circular(8)),
      spriteStroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(hitboxRect, const Radius.circular(3)),
      hitboxPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(hitboxRect, const Radius.circular(3)),
      hitboxStroke,
    );
  }

  @override
  bool shouldRepaint(covariant _PlayerFootHitboxPreviewPainter oldDelegate) {
    return oldDelegate.preview != preview;
  }
}

class ElementCollisionPaddingEditor extends StatelessWidget {
  const ElementCollisionPaddingEditor({
    super.key,
    required this.padding,
    required this.usesManualPrimaryShape,
    required this.maxHorizontal,
    required this.maxVertical,
    required this.onChanged,
  });

  final WarpTriggerPadding padding;
  final bool usesManualPrimaryShape;
  final int maxHorizontal;
  final int maxVertical;
  final ValueChanged<WarpTriggerPadding> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          usesManualPrimaryShape
              ? 'Le padding reste stocké comme réglage secondaire. Tant qu’une forme principale auteur existe, il ne redéfinit pas la base métier.'
              : 'Le padding génère la base automatique actuelle. Vous pouvez ensuite ajouter ou retirer quelques cellules localement.',
          style: TextStyle(
            color: secondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PaddingStepper(
              label: 'Top',
              value: padding.top,
              maxValue: maxVertical,
              onChanged: (v) => onChanged(padding.copyWith(top: v)),
            ),
            _PaddingStepper(
              label: 'Right',
              value: padding.right,
              maxValue: maxHorizontal,
              onChanged: (v) => onChanged(padding.copyWith(right: v)),
            ),
            _PaddingStepper(
              label: 'Bottom',
              value: padding.bottom,
              maxValue: maxVertical,
              onChanged: (v) => onChanged(padding.copyWith(bottom: v)),
            ),
            _PaddingStepper(
              label: 'Left',
              value: padding.left,
              maxValue: maxHorizontal,
              onChanged: (v) => onChanged(padding.copyWith(left: v)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Valeurs actuelles: T${padding.top} R${padding.right} B${padding.bottom} L${padding.left}',
          style: TextStyle(
            color: label,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PaddingStepper extends StatelessWidget {
  const _PaddingStepper({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int maxValue;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final canDecrease = value > 0;
    final canIncrease = value < maxValue;
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              color: secondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              GestureDetector(
                onTap: canDecrease ? () => onChanged(value - 1) : null,
                child: Icon(
                  CupertinoIcons.minus_circle_fill,
                  size: 18,
                  color: canDecrease
                      ? labelColor
                      : labelColor.withValues(alpha: 0.25),
                ),
              ),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: canIncrease ? () => onChanged(value + 1) : null,
                child: Icon(
                  CupertinoIcons.plus_circle_fill,
                  size: 18,
                  color: canIncrease
                      ? labelColor
                      : labelColor.withValues(alpha: 0.25),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  const _SidebarSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final label = CupertinoColors.label.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: Colors.white.withValues(alpha: 0.018),
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: label,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DisplayToggle extends StatelessWidget {
  const _DisplayToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          MacosSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: CupertinoColors.label.resolveFrom(context),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const accent = EditorChrome.inspectorJoyCoral;
    final labelColor = CupertinoColors.label.resolveFrom(context);
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      minimumSize: Size.zero,
      borderRadius: BorderRadius.circular(10),
      color: selected ? accent.withValues(alpha: 0.16) : Colors.black26,
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: selected ? accent : labelColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  const _ToolbarAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return PushButton(
      controlSize: ControlSize.small,
      secondary: true,
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _ElementCollisionCanvasPainter extends CustomPainter {
  _ElementCollisionCanvasPainter({
    required this.image,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
    required this.snapshot,
    required this.showGrid,
    required this.showBase,
    required this.showFinal,
    required this.showOverrides,
    required this.pendingPolygon,
    required this.pendingPolygonPreviewCells,
    required this.hoverGridPoint,
    required this.highlightPolygonClosure,
  });

  final ui.Image image;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;
  final ElementCollisionAuthoringSnapshot snapshot;
  final bool showGrid;
  final bool showBase;
  final bool showFinal;
  final bool showOverrides;
  final List<Offset> pendingPolygon;
  final List<GridPos> pendingPolygonPreviewCells;
  final Offset? hoverGridPoint;
  final bool highlightPolygonClosure;

  @override
  void paint(Canvas canvas, Size size) {
    final targetRect = _fitCollisionPreviewRect(
      size: size,
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      padding: 24,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          targetRect.inflate(10), const Radius.circular(18)),
      Paint()..color = Colors.black.withValues(alpha: 0.1),
    );

    final sourceRect = Rect.fromLTWH(
      source.x * tileWidth.toDouble(),
      source.y * tileHeight.toDouble(),
      source.width * tileWidth.toDouble(),
      source.height * tileHeight.toDouble(),
    );
    if (sourceRect.right <= image.width && sourceRect.bottom <= image.height) {
      canvas.drawImageRect(
        image,
        sourceRect,
        targetRect,
        Paint()
          ..isAntiAlias = false
          ..filterQuality = FilterQuality.none,
      );
    }

    final cellWidth = targetRect.width / source.width;
    final cellHeight = targetRect.height / source.height;

    if (showBase) {
      for (final cell in snapshot.baseCells) {
        _fillCell(
          canvas,
          cell: cell,
          targetRect: targetRect,
          cellWidth: cellWidth,
          cellHeight: cellHeight,
          color: Colors.cyanAccent.withValues(alpha: 0.16),
        );
      }
    }

    if (showFinal) {
      for (final cell in snapshot.finalCells) {
        _fillCell(
          canvas,
          cell: cell,
          targetRect: targetRect,
          cellWidth: cellWidth,
          cellHeight: cellHeight,
          color: EditorChrome.inspectorJoyCoral.withValues(alpha: 0.18),
          strokeColor: EditorChrome.inspectorJoyCoral,
        );
      }
    }

    if (pendingPolygonPreviewCells.isNotEmpty) {
      for (final cell in pendingPolygonPreviewCells) {
        _fillCell(
          canvas,
          cell: cell,
          targetRect: targetRect,
          cellWidth: cellWidth,
          cellHeight: cellHeight,
          color: Colors.yellowAccent.withValues(alpha: 0.14),
          strokeColor: Colors.yellowAccent.withValues(alpha: 0.85),
        );
      }
    }

    if (showOverrides) {
      for (final cell in snapshot.manualAddedCells) {
        final cellRect = _cellRect(
          cell,
          targetRect: targetRect,
          cellWidth: cellWidth,
          cellHeight: cellHeight,
        );
        canvas.drawRect(
          cellRect.deflate(2),
          Paint()
            ..color = Colors.greenAccent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
      }

      for (final cell in snapshot.manualRemovedCells) {
        final cellRect = _cellRect(
          cell,
          targetRect: targetRect,
          cellWidth: cellWidth,
          cellHeight: cellHeight,
        );
        canvas.drawRect(
          cellRect,
          Paint()
            ..color = Colors.redAccent.withValues(alpha: 0.16)
            ..style = PaintingStyle.fill,
        );
        final strikePaint = Paint()
          ..color = Colors.redAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4;
        canvas.drawLine(cellRect.topLeft, cellRect.bottomRight, strikePaint);
        canvas.drawLine(cellRect.topRight, cellRect.bottomLeft, strikePaint);
      }
    }

    if (showGrid) {
      final gridPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..strokeWidth = 1;
      for (var x = 0; x <= source.width; x++) {
        final dx = targetRect.left + x * cellWidth;
        canvas.drawLine(
          Offset(dx, targetRect.top),
          Offset(dx, targetRect.bottom),
          gridPaint,
        );
      }
      for (var y = 0; y <= source.height; y++) {
        final dy = targetRect.top + y * cellHeight;
        canvas.drawLine(
          Offset(targetRect.left, dy),
          Offset(targetRect.right, dy),
          gridPaint,
        );
      }
    }

    if (pendingPolygon.isNotEmpty) {
      final path = Path();
      final points = pendingPolygon
          .map((point) => Offset(
                targetRect.left + (point.dx / source.width) * targetRect.width,
                targetRect.top + (point.dy / source.height) * targetRect.height,
              ))
          .toList(growable: false);
      path.moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.yellowAccent.withValues(alpha: 0.95)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      for (final point in points) {
        canvas.drawCircle(
          point,
          4,
          Paint()..color = Colors.yellowAccent,
        );
      }
      canvas.drawCircle(
        points.first,
        highlightPolygonClosure ? 9 : 6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = highlightPolygonClosure ? 3 : 1.5
          ..color = highlightPolygonClosure
              ? Colors.greenAccent
              : Colors.yellowAccent.withValues(alpha: 0.8),
      );
      if (hoverGridPoint != null && highlightPolygonClosure) {
        final hoverPoint = Offset(
          targetRect.left +
              (hoverGridPoint!.dx / source.width) * targetRect.width,
          targetRect.top +
              (hoverGridPoint!.dy / source.height) * targetRect.height,
        );
        canvas.drawLine(
          hoverPoint,
          points.first,
          Paint()
            ..color = Colors.greenAccent.withValues(alpha: 0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
      if (points.length >= 3) {
        final preview = Path.from(path)..close();
        canvas.drawPath(
          preview,
          Paint()
            ..color = Colors.yellowAccent.withValues(alpha: 0.12)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  void _fillCell(
    Canvas canvas, {
    required GridPos cell,
    required Rect targetRect,
    required double cellWidth,
    required double cellHeight,
    required Color color,
    Color? strokeColor,
  }) {
    final rect = _cellRect(
      cell,
      targetRect: targetRect,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    if (strokeColor != null) {
      canvas.drawRect(
        rect,
        Paint()
          ..color = strokeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  Rect _cellRect(
    GridPos cell, {
    required Rect targetRect,
    required double cellWidth,
    required double cellHeight,
  }) {
    return Rect.fromLTWH(
      targetRect.left + cell.x * cellWidth,
      targetRect.top + cell.y * cellHeight,
      cellWidth,
      cellHeight,
    );
  }

  @override
  bool shouldRepaint(covariant _ElementCollisionCanvasPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.source != source ||
        oldDelegate.tileWidth != tileWidth ||
        oldDelegate.tileHeight != tileHeight ||
        oldDelegate.snapshot != snapshot ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.showBase != showBase ||
        oldDelegate.showFinal != showFinal ||
        oldDelegate.showOverrides != showOverrides ||
        !_sameCells(oldDelegate.pendingPolygonPreviewCells,
            pendingPolygonPreviewCells) ||
        oldDelegate.hoverGridPoint != hoverGridPoint ||
        oldDelegate.highlightPolygonClosure != highlightPolygonClosure ||
        !_sameOffsets(oldDelegate.pendingPolygon, pendingPolygon);
  }

  bool _sameOffsets(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  bool _sameCells(List<GridPos> a, List<GridPos> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

Rect _fitCollisionPreviewRect({
  required Size size,
  required TilesetSourceRect source,
  required int tileWidth,
  required int tileHeight,
  double padding = 0,
}) {
  final sourcePixelWidth = source.width * tileWidth.toDouble();
  final sourcePixelHeight = source.height * tileHeight.toDouble();
  final safeRect = Rect.fromLTWH(
    padding,
    padding,
    math.max(0, size.width - padding * 2),
    math.max(0, size.height - padding * 2),
  );
  if (sourcePixelWidth <= 0 ||
      sourcePixelHeight <= 0 ||
      safeRect.width <= 0 ||
      safeRect.height <= 0) {
    return safeRect;
  }
  final sourceAspect = sourcePixelWidth / sourcePixelHeight;
  final targetAspect = safeRect.width / safeRect.height;
  if (sourceAspect > targetAspect) {
    final height = safeRect.width / sourceAspect;
    final top = safeRect.top + (safeRect.height - height) / 2;
    return Rect.fromLTWH(safeRect.left, top, safeRect.width, height);
  }
  final width = safeRect.height * sourceAspect;
  final left = safeRect.left + (safeRect.width - width) / 2;
  return Rect.fromLTWH(left, safeRect.top, width, safeRect.height);
}

enum _ElementCollisionEditorTool {
  preview(
    label: 'Aperçu',
    helpLabel: 'Visualiser la forme finale exacte qui sera sauvegardée.',
  ),
  brushAdd(
    label: 'Pinceau +',
    helpLabel: 'Cliquez-glissez pour ajouter des retouches locales.',
    operation: ElementCollisionAuthoringOperation.add,
  ),
  brushRemove(
    label: 'Pinceau -',
    helpLabel: 'Cliquez-glissez pour retirer des retouches locales.',
    operation: ElementCollisionAuthoringOperation.remove,
  ),
  polygonAdd(
    label: 'Polygone forme',
    helpLabel:
        'Placez des points, puis fermez le polygone pour remplacer la forme principale.',
    operation: ElementCollisionAuthoringOperation.add,
  ),
  polygonRemove(
    label: 'Polygone -',
    helpLabel: 'Placez des points, puis retirez cette zone.',
    operation: ElementCollisionAuthoringOperation.remove,
  );

  const _ElementCollisionEditorTool({
    required this.label,
    required this.helpLabel,
    this.operation,
  });

  final String label;
  final String helpLabel;
  final ElementCollisionAuthoringOperation? operation;
}

```

### packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart

```dart
// Éditeur de masques triple couche pour les éléments projet (PokeMap).
// Voir le rapport : reports/POKEMAP_MASKS_OCCLUSION_PLAYER_V2_REPORT.md

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:map_core/map_core.dart';

import '../../application/models/element_collision_truth_summary.dart';
import '../shared/cupertino_editor_widgets.dart';

/// Mode de la surface d’édition : **aperçu** (lecture seule) ou peinture sur
/// un des deux masques métiers (collision vs occlusion).
///
/// Rappel produit :
/// - **Collision** = bloque le déplacement (gameplay).
/// - **Occlusion** = peut recouvrir le joueur au rendu quand il passe « derrière » ;
///   ne bloque pas par lui-même.
enum MaskSurfaceMode {
  /// Sprite + overlays + légende ; pas d’édition.
  preview,

  /// Pinceau / gomme sur [ElementCollisionProfile.collisionMask] (JSON `pixelMask`).
  collisionPaint,

  /// Pinceau / gomme sur [ElementCollisionProfile.occlusionMask].
  occlusionPaint,
}

enum _MaskStrokeOperation {
  paint,
  erase,
}

/// Éditeur **pixel-level** pour les masques d’un [ProjectElementEntry] :
/// visual (alpha), collision, occlusion — avec fond damier, zoom centré, légende.
///
/// ## Compatibilité
/// - Si seul l’ancien champ [ElementCollisionProfile.cells] est rempli, on
///   **dérive** un bitmap collision en remplissant chaque tuile « bloquante ».
/// - À chaque modification, on **ré-écrit** aussi `cells` via
///   [ElementCollisionMaskCodec.cellsFromPixelMask] pour les outils legacy.
///
/// ## Non-objectifs
/// - La grille affichée est un **repère** ; la vérité reste le masque pixel.
class ElementCollisionTripleMaskEditor extends StatefulWidget {
  const ElementCollisionTripleMaskEditor({
    super.key,
    required this.image,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
    required this.profile,
    required this.draftPadding,
    required this.onProfileChanged,
  });

  final ui.Image image;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;
  final ElementCollisionProfile? profile;
  final WarpTriggerPadding draftPadding;
  final ValueChanged<ElementCollisionProfile?> onProfileChanged;

  @override
  State<ElementCollisionTripleMaskEditor> createState() =>
      _ElementCollisionTripleMaskEditorState();
}

class _ElementCollisionTripleMaskEditorState
    extends State<ElementCollisionTripleMaskEditor> {
  MaskSurfaceMode _mode = MaskSurfaceMode.collisionPaint;
  late _MaskStrokeOperation _strokeOperation;
  late int _brushSizePx;
  bool _showPixelGrid = false;

  late List<bool> _collisionBits;
  late List<bool> _occlusionBits;
  List<bool>? _visualBits;
  bool _loadingVisual = false;

  int get _wPx => math.max(1, widget.source.width * widget.tileWidth);
  int get _hPx => math.max(1, widget.source.height * widget.tileHeight);

  @override
  void initState() {
    super.initState();
    _collisionBits = _initialCollisionBits();
    _occlusionBits = _initialOcclusionBits();
    _strokeOperation = _initialStrokeOperation();
    _brushSizePx = _defaultBrushSizePx();
    _scheduleVisualLoad();
  }

  @override
  void didUpdateWidget(covariant ElementCollisionTripleMaskEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile ||
        oldWidget.source != widget.source ||
        oldWidget.tileWidth != widget.tileWidth ||
        oldWidget.tileHeight != widget.tileHeight) {
      setState(() {
        _collisionBits = _initialCollisionBits();
        _occlusionBits = _initialOcclusionBits();
        _visualBits = null;
        _loadingVisual = false;
      });
      _scheduleVisualLoad();
    }
  }

  void _scheduleVisualLoad() {
    final decoded = _decodeMask(widget.profile?.visualMask, _wPx, _hPx);
    if (decoded != null) {
      setState(() {
        _visualBits = decoded;
      });
      return;
    }
    _loadVisualFromImageAlpha();
  }

  /// Construit le masque « visible » depuis l’alpha du PNG si aucun [visualMask]
  /// n’est persisté — cohérent avec l’auto-génération (seuil alpha).
  Future<void> _loadVisualFromImageAlpha() async {
    setState(() {
      _loadingVisual = true;
    });
    final bd =
        await widget.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (!mounted) {
      return;
    }
    if (bd == null) {
      setState(() {
        _loadingVisual = false;
        _visualBits = List<bool>.filled(_wPx * _hPx, false);
      });
      return;
    }
    final bytes = bd.buffer.asUint8List();
    final srcLeft = widget.source.x * widget.tileWidth;
    final srcTop = widget.source.y * widget.tileHeight;
    final w = _wPx;
    final h = _hPx;
    final imgW = widget.image.width;
    final out = List<bool>.filled(w * h, false);
    const alphaThreshold = 12;
    for (var py = 0; py < h; py++) {
      for (var px = 0; px < w; px++) {
        final ix = srcLeft + px;
        final iy = srcTop + py;
        if (ix < 0 || iy < 0 || ix >= imgW || iy >= widget.image.height) {
          continue;
        }
        final o = (iy * imgW + ix) * 4;
        final a = bytes[o + 3];
        out[py * w + px] = a > alphaThreshold;
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _visualBits = out;
      _loadingVisual = false;
    });
  }

  List<bool>? _decodeMask(ElementCollisionPixelMask? m, int w, int h) {
    if (m == null || m.widthPx != w || m.heightPx != h) {
      return null;
    }
    try {
      return ElementCollisionMaskCodec.decodePackedBits(
        widthPx: w,
        heightPx: h,
        dataBase64: m.dataBase64,
      );
    } catch (_) {
      return null;
    }
  }

  List<bool> _initialCollisionBits() {
    final decoded = _decodeMask(widget.profile?.collisionMask, _wPx, _hPx);
    if (decoded != null) {
      return decoded;
    }
    // Legacy : cellules → remplissage tuile par tuile.
    final out = List<bool>.filled(_wPx * _hPx, false);
    final cells = widget.profile?.cells ?? const <GridPos>[];
    for (final c in cells) {
      if (c.x < 0 ||
          c.y < 0 ||
          c.x >= widget.source.width ||
          c.y >= widget.source.height) {
        continue;
      }
      for (var ly = 0; ly < widget.tileHeight; ly++) {
        for (var lx = 0; lx < widget.tileWidth; lx++) {
          final px = c.x * widget.tileWidth + lx;
          final py = c.y * widget.tileHeight + ly;
          if (px < _wPx && py < _hPx) {
            out[py * _wPx + px] = true;
          }
        }
      }
    }
    return out;
  }

  List<bool> _initialOcclusionBits() {
    final decoded = _decodeMask(widget.profile?.occlusionMask, _wPx, _hPx);
    if (decoded != null) {
      return decoded;
    }
    return List<bool>.filled(_wPx * _hPx, false);
  }

  _MaskStrokeOperation _initialStrokeOperation() {
    final hasFineCollision = widget.profile?.collisionMask != null;
    final hasLegacyGridCollision =
        widget.profile?.cells.isNotEmpty == true && !hasFineCollision;
    return hasLegacyGridCollision
        ? _MaskStrokeOperation.erase
        : _MaskStrokeOperation.paint;
  }

  int _defaultBrushSizePx() {
    final tileEdge = math.min(widget.tileWidth, widget.tileHeight);
    return math.max(1, tileEdge ~/ 2);
  }

  List<int> _brushSizeOptions() {
    final tileEdge = math.max(1, math.min(widget.tileWidth, widget.tileHeight));
    final values = <int>{
      1,
      math.max(1, tileEdge ~/ 4),
      math.max(1, tileEdge ~/ 2),
      tileEdge,
    }.where((value) => value >= 1 && value <= tileEdge).toList()
      ..sort();
    return values;
  }

  ElementCollisionPixelMask _maskFromBits(List<bool> bits) {
    return ElementCollisionPixelMask(
      widthPx: _wPx,
      heightPx: _hPx,
      encoding: ElementCollisionMaskEncoding.packedBitsV1,
      dataBase64: ElementCollisionMaskCodec.encodePackedBits(
        widthPx: _wPx,
        heightPx: _hPx,
        solidPixels: bits,
      ),
    );
  }

  void _emitProfile() {
    final collisionMask = _maskFromBits(_collisionBits);
    final occlusionMask = _maskFromBits(_occlusionBits);
    ElementCollisionPixelMask? visualMask;
    if (_visualBits != null && _visualBits!.length == _wPx * _hPx) {
      visualMask = _maskFromBits(_visualBits!);
    }
    final derivedCells = ElementCollisionMaskCodec.cellsFromPixelMask(
      mask: collisionMask,
      tileWidth: widget.tileWidth,
      tileHeight: widget.tileHeight,
      sourceWidthInTiles: widget.source.width,
      sourceHeightInTiles: widget.source.height,
    );
    widget.onProfileChanged(
      ElementCollisionProfile(
        source: ElementCollisionProfileSource.manual,
        padding: widget.profile?.padding ?? widget.draftPadding,
        visualMask: visualMask ?? widget.profile?.visualMask,
        collisionMask: collisionMask,
        occlusionMask: occlusionMask,
        cells: derivedCells,
      ),
    );
  }

  void _applyStroke(Offset local, Size boxSize, double boxHeight,
      {required bool erase}) {
    if (_mode == MaskSurfaceMode.preview) {
      return;
    }
    final targetRect = fitCollisionPreviewRect(
      size: Size(boxSize.width, boxHeight),
      source: widget.source,
      tileWidth: widget.tileWidth,
      tileHeight: widget.tileHeight,
    );
    if (!targetRect.contains(local)) {
      return;
    }
    final lx = local.dx - targetRect.left;
    final ly = local.dy - targetRect.top;
    final px = (lx / targetRect.width * _wPx).floor().clamp(0, _wPx - 1);
    final py = (ly / targetRect.height * _hPx).floor().clamp(0, _hPx - 1);
    final next = _mode == MaskSurfaceMode.collisionPaint
        ? _collisionBits
        : _occlusionBits;
    _paintBrushFootprint(next, centerX: px, centerY: py, erase: erase);
    setState(() {});
    _emitProfile();
  }

  void _paintBrushFootprint(
    List<bool> bits, {
    required int centerX,
    required int centerY,
    required bool erase,
  }) {
    final size = _brushSizePx.clamp(1, math.max(_wPx, _hPx));
    final left = centerX - size ~/ 2;
    final top = centerY - size ~/ 2;
    for (var y = top; y < top + size; y++) {
      if (y < 0 || y >= _hPx) {
        continue;
      }
      for (var x = left; x < left + size; x++) {
        if (x < 0 || x >= _wPx) {
          continue;
        }
        bits[y * _wPx + x] = !erase;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    final padding = widget.profile?.padding ?? widget.draftPadding;
    final truthSummary = summarizeElementCollisionTruth(widget.profile);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: Colors.white.withValues(alpha: 0.015),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Masques pixel (visuel / collision / occlusion)',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${truthSummary.title}. ${truthSummary.description} ${truthSummary.detail}',
            style: TextStyle(color: secondary, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            'Masque collision : bloque le déplacement du joueur. '
            'Masque occlusion : rendu devant/derrière, ne bloque pas. '
            'Masque visuel : aide d’analyse / aperçu, ne bloque pas.',
            style: TextStyle(color: secondary, fontSize: 10),
          ),
          const SizedBox(height: 8),
          CupertinoSlidingSegmentedControl<int>(
            groupValue: _mode.index,
            children: const {
              0: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: Text('Aperçu', style: TextStyle(fontSize: 11)),
              ),
              1: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child:
                    Text('Peindre collision', style: TextStyle(fontSize: 11)),
              ),
              2: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child:
                    Text('Peindre occlusion', style: TextStyle(fontSize: 11)),
              ),
            },
            onValueChanged: (int? v) {
              if (v != null) {
                setState(() => _mode = MaskSurfaceMode.values[v]);
              }
            },
          ),
          if (_mode != MaskSurfaceMode.preview) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CupertinoSlidingSegmentedControl<_MaskStrokeOperation>(
                  groupValue: _strokeOperation,
                  children: const {
                    _MaskStrokeOperation.paint: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Text('Peindre', style: TextStyle(fontSize: 11)),
                    ),
                    _MaskStrokeOperation.erase: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Text('Effacer', style: TextStyle(fontSize: 11)),
                    ),
                  },
                  onValueChanged: (next) {
                    if (next != null) {
                      setState(() => _strokeOperation = next);
                    }
                  },
                ),
                Text(
                  'Taille pinceau',
                  style: TextStyle(color: secondary, fontSize: 10),
                ),
                CupertinoSlidingSegmentedControl<int>(
                  groupValue: _brushSizePx,
                  children: {
                    for (final option in _brushSizeOptions())
                      option: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        child: Text(
                          '${option}px',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                  },
                  onValueChanged: (next) {
                    if (next != null) {
                      setState(() => _brushSizePx = next);
                    }
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              CupertinoSwitch(
                value: _showPixelGrid,
                onChanged: (v) => setState(() => _showPixelGrid = v),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Grille pixel (aide visuelle seulement)',
                  style: TextStyle(color: secondary, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Padding px: T${padding.top} R${padding.right} B${padding.bottom} L${padding.left} · '
            'cadre cyan = zone analysée par l’auto-génération',
            style: TextStyle(color: secondary, fontSize: 10),
          ),
          if (_loadingVisual)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Lecture du masque visuel depuis l’image…',
                style: TextStyle(color: secondary, fontSize: 10),
              ),
            ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              final boxHeight = math
                  .min(240, constraints.maxWidth * 0.72)
                  .toDouble()
                  .clamp(140.0, 260.0);
              return Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) {
                  _applyStroke(
                    e.localPosition,
                    constraints.biggest,
                    boxHeight,
                    erase: _strokeOperation == _MaskStrokeOperation.erase,
                  );
                },
                onPointerMove: (e) {
                  if (_mode == MaskSurfaceMode.preview) {
                    return;
                  }
                  // Le bouton secondaire reste une gomme rapide, même si
                  // l'outil visible est sur "Peindre".
                  final erase =
                      _strokeOperation == _MaskStrokeOperation.erase ||
                          e.buttons == 2;
                  _applyStroke(
                    e.localPosition,
                    constraints.biggest,
                    boxHeight,
                    erase: erase,
                  );
                },
                child: SizedBox(
                  height: boxHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: CupertinoColors.separator.resolveFrom(context),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: CustomPaint(
                        painter: _TripleMaskPixelPainter(
                          image: widget.image,
                          source: widget.source,
                          tileWidth: widget.tileWidth,
                          tileHeight: widget.tileHeight,
                          padding: padding,
                          visualBits: _visualBits,
                          collisionBits: _collisionBits,
                          occlusionBits: _occlusionBits,
                          mode: _mode,
                          showPixelGrid: _showPixelGrid,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _legendRow(
            color: const Color(0xFFB71C1C).withValues(alpha: 0.55),
            border: const Color(0xFFB71C1C),
            text: 'Rouge : collision (bloque)',
            secondary: secondary,
          ),
          const SizedBox(height: 4),
          _legendRow(
            color: const Color(0xFF5E35B1).withValues(alpha: 0.45),
            border: const Color(0xFF4527A0),
            text: 'Violet : occlusion (couverture rendu, ne bloque pas)',
            secondary: secondary,
          ),
          const SizedBox(height: 4),
          _legendRow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
            border: const Color(0xFF1B5E20),
            text: 'Vert : passable (hors collision)',
            secondary: secondary,
          ),
          const SizedBox(height: 4),
          _legendRow(
            color: const Color(0xFF0277BD).withValues(alpha: 0.18),
            border: const Color(0xFF01579B),
            text: 'Bleu léger : matière visuelle (alpha) — repère seulement',
            secondary: secondary,
          ),
          const SizedBox(height: 6),
          Text(
            _mode == MaskSurfaceMode.preview
                ? 'Mode aperçu : édition désactivée.'
                : widget.profile?.collisionMask == null &&
                        widget.profile?.cells.isNotEmpty == true &&
                        _strokeOperation == _MaskStrokeOperation.erase
                    ? 'Profil grille détecté : Effacer est sélectionné pour creuser un masque fin depuis la grille existante.'
                    : _strokeOperation == _MaskStrokeOperation.erase
                        ? 'Mode ${_mode == MaskSurfaceMode.collisionPaint ? 'collision' : 'occlusion'} : '
                            'cliquez / tracez pour effacer.'
                        : 'Mode ${_mode == MaskSurfaceMode.collisionPaint ? 'collision' : 'occlusion'} : '
                            'cliquez / tracez pour peindre. Le bouton Effacer gomme la zone.',
            style: TextStyle(color: secondary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _legendRow({
    required Color color,
    required Color border,
    required String text,
    required Color secondary,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: border, width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: secondary, fontSize: 10),
          ),
        ),
      ],
    );
  }
}

/// Même géométrie que l’ancien `_fitCollisionPreviewRect` : garde le sprite **centré**
/// et le plus grand possible dans la boîte, **sans** déformer les pixels.
Rect fitCollisionPreviewRect({
  required Size size,
  required TilesetSourceRect source,
  required int tileWidth,
  required int tileHeight,
}) {
  final sourcePixelWidth = source.width * tileWidth.toDouble();
  final sourcePixelHeight = source.height * tileHeight.toDouble();
  if (sourcePixelWidth <= 0 || sourcePixelHeight <= 0) {
    return Rect.fromLTWH(0, 0, size.width, size.height);
  }
  final sourceAspect = sourcePixelWidth / sourcePixelHeight;
  final targetAspect = size.width <= 0 || size.height <= 0
      ? sourceAspect
      : size.width / size.height;
  if (sourceAspect > targetAspect) {
    final height = size.width / sourceAspect;
    final top = (size.height - height) / 2;
    return Rect.fromLTWH(0, top, size.width, height);
  }
  final width = size.height * sourceAspect;
  final left = (size.width - width) / 2;
  return Rect.fromLTWH(left, 0, width, size.height);
}

class _TripleMaskPixelPainter extends CustomPainter {
  _TripleMaskPixelPainter({
    required this.image,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
    required this.padding,
    required this.visualBits,
    required this.collisionBits,
    required this.occlusionBits,
    required this.mode,
    required this.showPixelGrid,
  });

  final ui.Image image;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;
  final WarpTriggerPadding padding;
  final List<bool>? visualBits;
  final List<bool> collisionBits;
  final List<bool> occlusionBits;
  final MaskSurfaceMode mode;
  final bool showPixelGrid;

  @override
  void paint(Canvas canvas, Size size) {
    final wPx = math.max(1, source.width * tileWidth);
    final hPx = math.max(1, source.height * tileHeight);

    final targetRect = fitCollisionPreviewRect(
      size: size,
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
    );

    // --- Fond damier (transparence lisible) ---
    _paintCheckerboard(canvas, targetRect);

    final sourceRect = Rect.fromLTWH(
      source.x * tileWidth.toDouble(),
      source.y * tileHeight.toDouble(),
      source.width * tileWidth.toDouble(),
      source.height * tileHeight.toDouble(),
    );
    if (sourceRect.right <= image.width && sourceRect.bottom <= image.height) {
      final imagePaint = Paint()
        ..isAntiAlias = false
        ..filterQuality = FilterQuality.none;
      canvas.drawImageRect(image, sourceRect, targetRect, imagePaint);
    }

    final scaleX = targetRect.width / wPx;
    final scaleY = targetRect.height / hPx;

    // --- Padding : zone exclue de l’analyse auto (assombrissement) ---
    final leftPad = padding.left * scaleX;
    final rightPad = padding.right * scaleX;
    final topPad = padding.top * scaleY;
    final bottomPad = padding.bottom * scaleY;
    final activeLeft = targetRect.left + leftPad;
    final activeTop = targetRect.top + topPad;
    final activeRight = targetRect.right - rightPad;
    final activeBottom = targetRect.bottom - bottomPad;
    final activeRect = Rect.fromLTRB(
      math.min(activeLeft, activeRight),
      math.min(activeTop, activeBottom),
      math.max(activeLeft, activeRight),
      math.max(activeTop, activeBottom),
    );
    _paintPaddingBands(
        canvas, targetRect, leftPad, rightPad, topPad, bottomPad);

    if (activeRect.width > 0 && activeRect.height > 0) {
      canvas.drawRect(
        activeRect,
        Paint()
          ..color = const Color(0xFF00BCD4).withValues(alpha: 0.72)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    // --- Calque « matière visuelle » (optionnel) ---
    if (visualBits != null && visualBits!.length == wPx * hPx) {
      final vp = Paint()..style = PaintingStyle.fill;
      for (var py = 0; py < hPx; py++) {
        for (var px = 0; px < wPx; px++) {
          if (!visualBits![py * wPx + px]) {
            continue;
          }
          final cell = Rect.fromLTWH(
            targetRect.left + px * scaleX,
            targetRect.top + py * scaleY,
            scaleX,
            scaleY,
          );
          vp.color = const Color(0xFF0277BD).withValues(alpha: 0.12);
          canvas.drawRect(cell, vp);
        }
      }
    }

    // --- Collision : rouge ---
    for (var py = 0; py < hPx; py++) {
      for (var px = 0; px < wPx; px++) {
        final idx = py * wPx + px;
        if (idx >= collisionBits.length || !collisionBits[idx]) {
          continue;
        }
        final cell = Rect.fromLTWH(
          targetRect.left + px * scaleX,
          targetRect.top + py * scaleY,
          scaleX,
          scaleY,
        );
        canvas.drawRect(
          cell,
          Paint()..color = const Color(0xFFC62828).withValues(alpha: 0.38),
        );
        canvas.drawRect(
          cell,
          Paint()
            ..color = const Color(0xFFB71C1C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = mode == MaskSurfaceMode.collisionPaint ? 1.0 : 0.6,
        );
      }
    }

    // --- Occlusion : violet (au-dessus du rouge en alpha combiné) ---
    for (var py = 0; py < hPx; py++) {
      for (var px = 0; px < wPx; px++) {
        final idx = py * wPx + px;
        if (idx >= occlusionBits.length || !occlusionBits[idx]) {
          continue;
        }
        final cell = Rect.fromLTWH(
          targetRect.left + px * scaleX,
          targetRect.top + py * scaleY,
          scaleX,
          scaleY,
        );
        canvas.drawRect(
          cell,
          Paint()..color = const Color(0xFF5E35B1).withValues(alpha: 0.42),
        );
        canvas.drawRect(
          cell,
          Paint()
            ..color = const Color(0xFF4527A0)
            ..style = PaintingStyle.stroke
            ..strokeWidth = mode == MaskSurfaceMode.occlusionPaint ? 1.0 : 0.55,
        );
      }
    }

    // --- Grille optionnelle (1 px logique) ---
    if (showPixelGrid) {
      final grid = Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..strokeWidth = 0.5;
      for (var x = 0; x <= wPx; x += 4) {
        final dx = targetRect.left + x * scaleX;
        canvas.drawLine(
            Offset(dx, targetRect.top), Offset(dx, targetRect.bottom), grid);
      }
      for (var y = 0; y <= hPx; y += 4) {
        final dy = targetRect.top + y * scaleY;
        canvas.drawLine(
            Offset(targetRect.left, dy), Offset(targetRect.right, dy), grid);
      }
    }
  }

  void _paintCheckerboard(Canvas canvas, Rect r) {
    const sq = 10.0;
    const light = Color(0xFFECEFF1);
    const dark = Color(0xFFD0D5D8);
    var row = 0;
    for (var y = r.top; y < r.bottom; y += sq) {
      var col = 0;
      for (var x = r.left; x < r.right; x += sq) {
        final cell = Rect.fromLTWH(
          x,
          y,
          math.min(sq, r.right - x),
          math.min(sq, r.bottom - y),
        );
        final paint = Paint()
          ..color = ((row + col) % 2 == 0) ? light : dark
          ..style = PaintingStyle.fill;
        canvas.drawRect(cell, paint);
        col++;
      }
      row++;
    }
  }

  void _paintPaddingBands(
    Canvas canvas,
    Rect targetRect,
    double leftPad,
    double rightPad,
    double topPad,
    double bottomPad,
  ) {
    final p = Paint()..color = Colors.black.withValues(alpha: 0.22);
    if (leftPad > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          targetRect.left,
          targetRect.top,
          leftPad,
          targetRect.height,
        ),
        p,
      );
    }
    if (rightPad > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          targetRect.right - rightPad,
          targetRect.top,
          rightPad,
          targetRect.height,
        ),
        p,
      );
    }
    if (topPad > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          targetRect.left,
          targetRect.top,
          targetRect.width,
          topPad,
        ),
        p,
      );
    }
    if (bottomPad > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          targetRect.left,
          targetRect.bottom - bottomPad,
          targetRect.width,
          bottomPad,
        ),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TripleMaskPixelPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.source != source ||
        !_boolListEq(oldDelegate.collisionBits, collisionBits) ||
        !_boolListEq(oldDelegate.occlusionBits, occlusionBits) ||
        !_nullableBoolListEq(oldDelegate.visualBits, visualBits) ||
        oldDelegate.mode != mode ||
        oldDelegate.showPixelGrid != showPixelGrid ||
        oldDelegate.padding != padding;
  }

  static bool _boolListEq(List<bool> a, List<bool> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  static bool _nullableBoolListEq(List<bool>? a, List<bool>? b) {
    if (identical(a, b)) {
      return true;
    }
    if (a == null || b == null) {
      return false;
    }
    return _boolListEq(a, b);
  }
}

```

### packages/map_editor/test/element_collision_editor_sheet_fine_mask_test.dart

```dart
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/panels/element_collision_editor_sheet.dart';
import 'package:map_editor/src/ui/shared/cupertino_editor_widgets.dart';
import 'package:map_editor/src/ui/widgets/element_collision_triple_mask_editor.dart';

void main() {
  testWidgets(
      'collision editor sheet exposes grid and fine mask authoring modes',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final image = await _testImage(width: 64, height: 64);
    await _pumpEditorLauncher(
      tester,
      image: image,
      initialProfile: const ElementCollisionProfile(
        cells: [GridPos(x: 1, y: 1)],
      ),
    );

    await tester.tap(find.text('Open collision editor'));
    await tester.pumpAndSettle();

    expect(find.text('Source utilisée par le gameplay'), findsOneWidget);
    expect(find.text('Collision par grille'), findsWidgets);
    expect(find.text('Masque fin'), findsOneWidget);
    expect(find.text('Pinceau +'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fine mask mode shows collision and occlusion mask labels',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final image = await _testImage(width: 64, height: 64);
    await _pumpEditorLauncher(
      tester,
      image: image,
      initialProfile: const ElementCollisionProfile(
        cells: [GridPos(x: 1, y: 1)],
      ),
    );

    await tester.tap(find.text('Open collision editor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masque fin'));
    await tester.pumpAndSettle();

    expect(find.text('Peindre collision'), findsOneWidget);
    expect(find.text('Effacer'), findsOneWidget);
    expect(find.textContaining('Masque collision'), findsWidgets);
    expect(find.textContaining('Masque occlusion'), findsWidgets);
    expect(find.textContaining('ne bloque pas'), findsWidgets);
    expect(
        find.textContaining('Mode aperçu : édition désactivée'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nested element edit sheet can open the collision editor',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final image = await _testImage(width: 64, height: 64);

    await tester.pumpWidget(
      MacosApp(
        home: MacosTheme(
          data: MacosThemeData.dark(),
          child: CupertinoPageScaffold(
            child: Builder(
              builder: (context) => Center(
                child: CupertinoButton(
                  child: const Text('Open element edit sheet'),
                  onPressed: () {
                    showMacosEditorTallSheet<void>(
                      context: context,
                      builder: (sheetContext) => Center(
                        child: CupertinoButton(
                          child: const Text('Ouvrir l’éditeur de collision'),
                          onPressed: () {
                            showElementCollisionEditorSheet(
                              context: sheetContext,
                              elementName: 'selbrume nested',
                              image: image,
                              source: _source,
                              tileWidth: 16,
                              tileHeight: 16,
                              initialProfile: const ElementCollisionProfile(
                                cells: [GridPos(x: 1, y: 1)],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open element edit sheet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ouvrir l’éditeur de collision'));
    await tester.pumpAndSettle();

    expect(find.text('Collision Editor'), findsOneWidget);
    expect(find.text('Masque fin'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile with collisionMask opens with fine collision visible',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final image = await _testImage(width: 64, height: 64);
    await _pumpEditorLauncher(
      tester,
      image: image,
      initialProfile: ElementCollisionProfile(
        collisionMask: _mask(widthPx: 64, heightPx: 64, solidIndex: 0),
        cells: const [GridPos(x: 3, y: 3)],
      ),
    );

    await tester.tap(find.text('Open collision editor'));
    await tester.pumpAndSettle();

    expect(find.text('Collision fine active'), findsOneWidget);
    expect(find.text('Masque fin'), findsOneWidget);
    expect(find.textContaining('Masque collision'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saving preserves existing collision visual and occlusion masks',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final image = await _testImage(width: 64, height: 64);
    late Future<ElementCollisionProfile?> result;
    final collisionMask = _mask(widthPx: 64, heightPx: 64, solidIndex: 1);
    final visualMask = _mask(widthPx: 64, heightPx: 64, solidIndex: 2);
    final occlusionMask = _mask(widthPx: 64, heightPx: 64, solidIndex: 3);

    await _pumpEditorLauncher(
      tester,
      image: image,
      onOpen: (context) {
        result = showElementCollisionEditorSheet(
          context: context,
          elementName: 'selbrume maison fine',
          image: image,
          source: _source,
          tileWidth: 16,
          tileHeight: 16,
          initialProfile: ElementCollisionProfile(
            visualMask: visualMask,
            collisionMask: collisionMask,
            occlusionMask: occlusionMask,
            cells: const [GridPos(x: 3, y: 3)],
          ),
        );
      },
    );

    await tester.tap(find.text('Open collision editor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sauvegarder'));
    await tester.pumpAndSettle();

    final saved = await result;
    expect(saved, isNotNull);
    expect(saved!.collisionMask?.dataBase64, collisionMask.dataBase64);
    expect(saved.visualMask?.dataBase64, visualMask.dataBase64);
    expect(saved.occlusionMask?.dataBase64, occlusionMask.dataBase64);
  });

  testWidgets('triple mask editor starts in paint collision mode',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final image = await _testImage(width: 64, height: 64);
    ElementCollisionProfile? emitted;

    await tester.pumpWidget(
      MacosApp(
        home: MacosTheme(
          data: MacosThemeData.dark(),
          child: CupertinoPageScaffold(
            child: Center(
              child: SizedBox(
                width: 720,
                child: ElementCollisionTripleMaskEditor(
                  image: image,
                  source: _source,
                  tileWidth: 16,
                  tileHeight: 16,
                  profile: const ElementCollisionProfile(),
                  draftPadding: const WarpTriggerPadding(),
                  onProfileChanged: (next) => emitted = next,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Peindre collision'), findsOneWidget);
    expect(find.text('Peindre'), findsOneWidget);
    expect(find.text('Effacer'), findsOneWidget);
    expect(
        find.textContaining('Mode aperçu : édition désactivée'), findsNothing);

    await tester.tap(
      find
          .descendant(
            of: find.byType(ElementCollisionTripleMaskEditor),
            matching: find.byType(Listener),
          )
          .last,
    );
    await tester.pumpAndSettle();

    expect(emitted, isNotNull);
    expect(emitted!.collisionMask, isNotNull);
    final bits = ElementCollisionMaskCodec.decodePackedBits(
      widthPx: emitted!.collisionMask!.widthPx,
      heightPx: emitted!.collisionMask!.heightPx,
      dataBase64: emitted!.collisionMask!.dataBase64,
    );
    expect(bits, contains(true));
  });

  testWidgets('triple mask editor paints a visible brush footprint',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final image = await _testImage(width: 64, height: 64);
    ElementCollisionProfile? emitted;

    await tester.pumpWidget(
      MacosApp(
        home: MacosTheme(
          data: MacosThemeData.dark(),
          child: CupertinoPageScaffold(
            child: Center(
              child: SizedBox(
                width: 720,
                child: ElementCollisionTripleMaskEditor(
                  image: image,
                  source: _source,
                  tileWidth: 16,
                  tileHeight: 16,
                  profile: const ElementCollisionProfile(),
                  draftPadding: const WarpTriggerPadding(),
                  onProfileChanged: (next) => emitted = next,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find
          .descendant(
            of: find.byType(ElementCollisionTripleMaskEditor),
            matching: find.byType(Listener),
          )
          .last,
    );
    await tester.pumpAndSettle();

    final bits = ElementCollisionMaskCodec.decodePackedBits(
      widthPx: emitted!.collisionMask!.widthPx,
      heightPx: emitted!.collisionMask!.heightPx,
      dataBase64: emitted!.collisionMask!.dataBase64,
    );
    expect(bits.where((bit) => bit).length, greaterThan(1));
  });

  testWidgets('triple mask editor sculpts legacy grid collision by default',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final image = await _testImage(width: 64, height: 64);
    ElementCollisionProfile? emitted;
    final fullGridCells = [
      for (var y = 0; y < _source.height; y++)
        for (var x = 0; x < _source.width; x++) GridPos(x: x, y: y),
    ];

    await tester.pumpWidget(
      MacosApp(
        home: MacosTheme(
          data: MacosThemeData.dark(),
          child: CupertinoPageScaffold(
            child: Center(
              child: SizedBox(
                width: 720,
                child: ElementCollisionTripleMaskEditor(
                  image: image,
                  source: _source,
                  tileWidth: 16,
                  tileHeight: 16,
                  profile: ElementCollisionProfile(cells: fullGridCells),
                  draftPadding: const WarpTriggerPadding(),
                  onProfileChanged: (next) => emitted = next,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Effacer est sélectionné'), findsOneWidget);
    await tester.tap(
      find
          .descendant(
            of: find.byType(ElementCollisionTripleMaskEditor),
            matching: find.byType(Listener),
          )
          .last,
    );
    await tester.pumpAndSettle();

    final bits = ElementCollisionMaskCodec.decodePackedBits(
      widthPx: emitted!.collisionMask!.widthPx,
      heightPx: emitted!.collisionMask!.heightPx,
      dataBase64: emitted!.collisionMask!.dataBase64,
    );
    expect(bits.where((bit) => bit).length, lessThan(64 * 64));
  });

  testWidgets('triple mask editor exposes explicit erase mode', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final image = await _testImage(width: 64, height: 64);
    ElementCollisionProfile? emitted;

    await tester.pumpWidget(
      MacosApp(
        home: MacosTheme(
          data: MacosThemeData.dark(),
          child: CupertinoPageScaffold(
            child: Center(
              child: SizedBox(
                width: 720,
                child: ElementCollisionTripleMaskEditor(
                  image: image,
                  source: _source,
                  tileWidth: 16,
                  tileHeight: 16,
                  profile: ElementCollisionProfile(
                    collisionMask: _fullMask(widthPx: 64, heightPx: 64),
                  ),
                  draftPadding: const WarpTriggerPadding(),
                  onProfileChanged: (next) => emitted = next,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Effacer'));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byType(ElementCollisionTripleMaskEditor),
            matching: find.byType(Listener),
          )
          .last,
    );
    await tester.pumpAndSettle();

    expect(emitted, isNotNull);
    final bits = ElementCollisionMaskCodec.decodePackedBits(
      widthPx: emitted!.collisionMask!.widthPx,
      heightPx: emitted!.collisionMask!.heightPx,
      dataBase64: emitted!.collisionMask!.dataBase64,
    );
    expect(bits.where((bit) => !bit).length, greaterThan(0));
  });
}

Future<void> _pumpEditorLauncher(
  WidgetTester tester, {
  required ui.Image image,
  ElementCollisionProfile? initialProfile,
  void Function(BuildContext context)? onOpen,
}) async {
  await tester.pumpWidget(
    MacosApp(
      home: MacosTheme(
        data: MacosThemeData.dark(),
        child: CupertinoPageScaffold(
          child: Builder(
            builder: (context) => Center(
              child: CupertinoButton(
                child: const Text('Open collision editor'),
                onPressed: () {
                  if (onOpen != null) {
                    onOpen(context);
                    return;
                  }
                  showElementCollisionEditorSheet(
                    context: context,
                    elementName: 'selbrume maison fine',
                    image: image,
                    source: _source,
                    tileWidth: 16,
                    tileHeight: 16,
                    initialProfile: initialProfile,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<ui.Image> _testImage({
  required int width,
  required int height,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final paint = ui.Paint()..color = const Color(0xFF496D94);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    paint,
  );
  final picture = recorder.endRecording();
  return picture.toImage(width, height);
}

ElementCollisionPixelMask _mask({
  required int widthPx,
  required int heightPx,
  required int solidIndex,
}) {
  final solidPixels = List<bool>.filled(widthPx * heightPx, false);
  solidPixels[solidIndex] = true;
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

ElementCollisionPixelMask _fullMask({
  required int widthPx,
  required int heightPx,
}) {
  return ElementCollisionPixelMask(
    widthPx: widthPx,
    heightPx: heightPx,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: widthPx,
      heightPx: heightPx,
      solidPixels: List<bool>.filled(widthPx * heightPx, true),
    ),
  );
}

const _source = TilesetSourceRect(
  x: 0,
  y: 0,
  width: 4,
  height: 4,
);

```

