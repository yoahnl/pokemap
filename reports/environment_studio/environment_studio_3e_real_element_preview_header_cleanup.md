# EnvironmentStudio-3E — Real Element Preview & Header Cleanup V0

## 1. Résumé

EnvironmentStudio-3E ajoute une miniature réelle des éléments Environment quand le tileset image est résoluble, avec fallback propre quand la ressource ne peut pas être chargée. La preview est utilisée dans les cards `Éléments compatibles`, dans la palette brouillon du wizard, dans l’éditeur de palette et dans la palette read-only du preset.

Le lot nettoie aussi le wording visible `shell read-only` dans les labels Environment Studio / Project Explorer, sans toucher à `map_core`, au modèle `ProjectManifest`, au workflow TileLayer Environment, au canvas, à la génération ou à la peinture.

## 2. Objectif du lot

Objectif exécuté :
- afficher la vraie image statique issue de la première frame de `ProjectElementEntry` ;
- cropper la zone tileset via `TilesetSourceRect` en coordonnées de tiles ;
- conserver un fallback si l’élément, le tileset, le chemin image ou le crop est invalide ;
- supprimer le vieux wording Environment Studio visible de type `shell read-only` ;
- préserver le wizard tileset-first, la création mémoire et les guards anti-mélange.

## 3. Audit des références d’éléments

Fichiers audités :
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/visual_frame_json.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_creation_wizard.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_view.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/palette/tileset_palette_preview.dart`

Constats :
- `ProjectElementEntry` expose `tilesetId` et `frames`.
- `TilesetVisualFrame.tilesetId` peut surcharger `ProjectElementEntry.tilesetId`.
- `TilesetSourceRect` utilise `x`, `y`, `width`, `height` en unités de tiles.
- `ProjectManifest.settings.tileWidth/tileHeight` donnent la conversion vers pixels.
- `ProjectTilesetEntry.relativePath` est relatif au projet dans le cas courant.
- `EditorNotifier.getTilesetAbsolutePathById` résout déjà un id tileset vers un chemin absolu via le workspace projet.

## 4. Audit du chargement / résolution d’assets

Le code existant charge déjà des images tileset dans le canvas et le Tileset Palette Panel, mais ces helpers sont privés à leurs widgets. Le plus petit chemin sûr pour 3E a été :
- ajouter un resolver optionnel `EnvironmentTilesetPathResolver` ;
- le brancher depuis `EnvironmentStudioWorkspace` avec `EditorNotifier.getTilesetAbsolutePathById` ;
- garder `EnvironmentStudioPanel` utilisable en tests/harness sans accès disque ;
- centraliser preview et fallback dans `EnvironmentElementThumbnail`.

Le widget accepte aussi un chemin absolu dans `ProjectTilesetEntry.relativePath`, utile en tests ciblés.

## 5. Stratégie de preview retenue

Stratégie retenue :
- frame utilisée : `element.frames.primaryFrame` ;
- tileset source : `frame.tilesetId` si non vide, sinon `element.tilesetId` ;
- chemin image : resolver optionnel, puis `relativePath` uniquement s’il est absolu ;
- crop : `source.x/y/width/height * tileWidth/tileHeight` ;
- rendu : crop décodé avec `package:image`, peint en pixels via `CustomPainter`.

Décision de debugging : une première version avec `ui.instantiateImageCodec`, puis une autre avec `Image.memory`, bloquaient `pumpAndSettle` dans les tests widgets avec une image réelle. La version finale évite l’image stream Flutter et garde une preview réelle en peignant le raster décodé.

## 6. Implémentation des miniatures réelles

Nouveau fichier :
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_element_thumbnail.dart`

Le widget :
- résout la frame/tileset/path ;
- vérifie bounds et tailles ;
- croppe l’image tileset ;
- peint le crop ;
- affiche le fallback quand la preview n’est pas fiable.

## 7. Fallbacks

Fallback déclenché si :
- l’élément est absent ;
- la frame est absente ;
- le tileset source est vide ;
- `tileWidth` ou `tileHeight` est invalide ;
- le chemin image n’est pas résolu ;
- le fichier image n’existe pas ;
- l’image ne se décode pas ;
- le `TilesetSourceRect` sort des bounds.

Le fallback reste visuel, compact et stable. Il affiche une initiale ou `?`, pas une erreur bruyante.

## 8. Intégration dans les éléments compatibles

`EnvironmentPresetCreationWizard` remplace le placeholder `CupertinoIcons.square_grid_2x2_fill` par `EnvironmentElementThumbnail`.

Clés de test ajoutées :
- `environment-element-preview-<elementId>`
- `environment-element-preview-fallback-<elementId>`

La clé historique `environment-creation-element-preview-<elementId>` reste conservée via `KeyedSubtree`.

## 9. Intégration dans la palette sélectionnée

`EnvironmentPaletteItemDraftEditor` reçoit maintenant le manifest et le resolver optionnel. Il résout l’élément courant par `elementId` et affiche une miniature dans la première colonne.

`EnvironmentPaletteItemView` reçoit aussi manifest/élément/resolver pour la palette read-only du preset sélectionné.

Clés de test ajoutées :
- `environment-selected-palette-preview-<elementId>`
- `environment-selected-palette-preview-fallback-<elementId>`

## 10. Nettoyage du wording legacy

Modifications :
- `editorShellSnapshotProvider` pour Environment Studio utilise maintenant `Presets d’environnements réutilisables`.
- Project Explorer affiche `Presets d’environnements réutilisables`.
- L’entrée enfant Environment Studio affiche `Créez et organisez vos presets d’environnements.`
- Le commentaire `shell read-only` dans `EditorNotifier` a été remplacé.
- Le libellé Path Studio visible `shell read-only` a aussi été retiré pour que le Project Explorer ne montre plus cette expression.

## 11. Comportements préservés

Préservé :
- wizard tileset-first ;
- filtre éléments compatibles ;
- ajout/retrait de palette ;
- création mémoire ;
- save palette existant ;
- guard anti-mélange tilesets ;
- diagnostics ;
- absence de peinture/génération dans Environment Studio ;
- absence de modification `map_core` ;
- absence de modification modèle `ProjectManifest`.

## 12. Tests

Tests RED/TDD ajoutés :
- card compatible avec preview réelle : `environment-element-preview-grass_a` ;
- fallback card quand le tileset image n’est pas résolu ;
- preview dans la palette sélectionnée après ajout ;
- label shell Environment Studio propre ;
- Project Explorer sans `shell read-only` / `lecture seule` dans l’entrée Environment.

Commandes finales lancées :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/environment_studio/environment_studio_preset_creation_form_test.dart
```

Résultat exact :

```text
00:00 +0: environmentPresetDraftIssueKindLabel libellés FR attendus (extrait)
00:00 +1: EnvironmentStudioPanel — création tileset-first (3C) Nouveau preset ouvre un wizard et bloque Continuer sans tileset
00:00 +2: EnvironmentStudioPanel — création tileset-first (3C) sélectionner un tileset active l’étape éléments compatibles
00:00 +3: EnvironmentStudioPanel — création tileset-first (3C) prévisualise le fallback si le tileset image est introuvable
00:00 +4: EnvironmentStudioPanel — création tileset-first (3C) ajout, retrait et création mémoire restent guidés par le tileset
00:01 +5: EnvironmentStudioPanel — création tileset-first (3C) changer de tileset vide la palette du brouillon
00:01 +6: EnvironmentStudioPanel — création tileset-first (3C) un élément forcé hors tileset source bloque la création
00:01 +7: EnvironmentStudioPanel — création tileset-first (3C) catégorie optionnelle : champ compact vide
00:01 +8: All tests passed!
```

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/environment_studio/environment_preset_palette_draft_editor_test.dart
```

Résultat exact :

```text
00:03 +21: All tests passed!
```

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/environment_studio/environment_preset_save_to_manifest_test.dart
```

Résultat exact :

```text
00:03 +13: All tests passed!
```

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/environment_studio/environment_preset_palette_use_case_test.dart
```

Résultat exact :

```text
00:00 +11: All tests passed!
```

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/environment_studio/environment_preset_tileset_compatibility_test.dart
```

Résultat exact :

```text
00:00 +7: All tests passed!
```

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/environment_studio/environment_studio_preset_browser_test.dart
```

Résultat exact :

```text
00:00 +9: All tests passed!
```

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/environment_studio/environment_studio_workspace_entry_test.dart
```

Résultat exact :

```text
00:00 +3: All tests passed!
```

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/editor_selectors_test.dart
```

Résultat exact :

```text
00:00 +9: All tests passed!
```

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat exact :

```text
00:02 +59: All tests passed!
```

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/environment_studio/environment_golden_slice_workflow_test.dart
```

Résultat exact :

```text
00:00 +6: All tests passed!
```

Échecs intermédiaires documentés :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/environment_studio/environment_studio_preset_creation_form_test.dart
```

Résultat RED exact utile :

```text
Error: No named parameter with the name 'resolveTilesetPathById'.
00:00 +0 -1: Some tests failed.
```

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
timeout 35s flutter test --reporter expanded --plain-name "sélectionner un tileset active" test/environment_studio/environment_studio_preset_creation_form_test.dart; echo EXIT:$?
```

Résultat de debugging exact utile avant changement de stratégie de rendu :

```text
00:32 +0: EnvironmentStudioPanel — création tileset-first (3C) sélectionner un tileset active l’étape éléments compatibles - did not complete [E]
00:32 +0: Some tests failed.
EXIT:124
```

## 13. Analyse ciblée

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter analyze lib/src/features/editor/state/editor_notifier.dart lib/src/features/editor/state/editor_selectors.dart lib/src/features/environment_studio/environment_studio_panel.dart lib/src/features/environment_studio/environment_studio_workspace.dart lib/src/features/environment_studio/widgets/environment_element_thumbnail.dart lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart lib/src/features/environment_studio/widgets/environment_palette_item_view.dart lib/src/features/environment_studio/widgets/environment_preset_creation_wizard.dart lib/src/features/environment_studio/widgets/environment_preset_detail.dart lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart lib/src/ui/panels/project_explorer_panel.dart test/editor_selectors_test.dart test/environment_studio/environment_studio_preset_creation_form_test.dart test/environment_studio/environment_studio_workspace_entry_test.dart
```

Résultat exact :

```text
Analyzing 14 items...

No issues found! (ran in 2.0s)
```

Formatage :

```bash
cd /Users/karim/Project/pokemonProject
dart format packages/map_editor/lib/src/features/editor/state/editor_notifier.dart packages/map_editor/lib/src/features/editor/state/editor_selectors.dart packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart packages/map_editor/lib/src/features/environment_studio/widgets/environment_element_thumbnail.dart packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_view.dart packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_creation_wizard.dart packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart packages/map_editor/test/editor_selectors_test.dart packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart
```

Résultat exact :

```text
Formatted packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
Formatted packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart
Formatted packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart
Formatted packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_creation_wizard.dart
Formatted 14 files (4 changed) in 0.09 seconds.
```

## 14. Fichiers créés/modifiés

Fichiers créés par EnvironmentStudio-3E :
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_element_thumbnail.dart`
- `reports/environment_studio/environment_studio_3e_real_element_preview_header_cleanup.md`

Fichiers modifiés par EnvironmentStudio-3E :
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- `packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart`
- `packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_view.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_creation_wizard.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/test/editor_selectors_test.dart`
- `packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart`
- `packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart`

Fichiers non touchés hors lot au status final :
- `reports/shadows/shadow_system_architecture_audit.md`

## 15. Non-objectifs respectés

Confirmé :
- aucun commit ;
- aucun `git add` ;
- aucun push ;
- aucun reset/restore/checkout/stash ;
- aucun `build_runner` ;
- aucun generated file modifié ;
- aucun `map_core` modifié ;
- aucun modèle `ProjectManifest` modifié ;
- aucun runtime/gameplay/battle modifié ;
- aucun TileLayer inspector modifié ;
- aucun canvas modifié ;
- aucune sauvegarde disque ajoutée ;
- aucune peinture/génération remise dans Environment Studio ;
- aucune nouvelle feature métier.

## 16. Evidence Pack

Git status initial :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Résultat exact :

```text
```

HEAD initial :

```bash
cd /Users/karim/Project/pokemonProject
git rev-parse --short HEAD
```

Résultat exact :

```text
04c16597
```

Git status final :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Résultat exact :

```text
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
 M packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
 M packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_view.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_creation_wizard.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
 M packages/map_editor/test/editor_selectors_test.dart
 M packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart
 M packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart
?? packages/map_editor/lib/src/features/environment_studio/widgets/environment_element_thumbnail.dart
?? reports/environment_studio/environment_studio_3e_real_element_preview_header_cleanup.md
?? reports/shadows/shadow_system_architecture_audit.md
```

Diff stat :

```bash
cd /Users/karim/Project/pokemonProject
git diff --stat
```

Résultat exact :

```text
 .../src/features/editor/state/editor_notifier.dart |   2 +-
 .../features/editor/state/editor_selectors.dart    |   2 +-
 .../environment_studio_panel.dart                  |  10 ++
 .../environment_studio_workspace.dart              |  10 +-
 .../environment_palette_item_draft_editor.dart     | 146 ++++++++++++++-------
 .../widgets/environment_palette_item_view.dart     |  59 ++++++---
 .../environment_preset_creation_wizard.dart        |  28 ++--
 .../widgets/environment_preset_detail.dart         |  17 +++
 .../widgets/environment_preset_draft_form.dart     |   5 +
 .../lib/src/ui/panels/project_explorer_panel.dart  |   8 +-
 .../map_editor/test/editor_selectors_test.dart     |  24 ++++
 ...vironment_studio_preset_creation_form_test.dart |  62 ++++++++-
 .../environment_studio_workspace_entry_test.dart   |   2 +
 13 files changed, 284 insertions(+), 91 deletions(-)
```

Diff name-only :

```bash
cd /Users/karim/Project/pokemonProject
git diff --name-only
```

Résultat exact :

```text
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart
packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart
packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_view.dart
packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_creation_wizard.dart
packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart
packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
packages/map_editor/test/editor_selectors_test.dart
packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart
packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart
```

Git diff check :

```bash
cd /Users/karim/Project/pokemonProject
git diff --check
```

Résultat exact :

```text
```

Recherche wording legacy :

```bash
cd /Users/karim/Project/pokemonProject
rg -n "shell read-only|lecture seule|diagnostics — shell read-only|génération sur carte arrive bientôt|renommage d.id arrive bientôt" packages/map_editor/lib packages/map_editor/test
```

Résultat exact :

```text
packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart:13:/// Mode de la surface d’édition : **aperçu** (lecture seule) ou peinture sur
packages/map_editor/lib/src/ui/canvas/cutscene_studio/cutscene_studio_workbench.dart:247:  /// Bannière lecture seule si graphe incompatible.
packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart:31:/// graphe avec branches **sans** JSON : lecture seule (avertissements), car on
packages/map_editor/test/editor_selectors_test.dart:200:      expect(shell.workspaceSubtitle, isNot(contains('shell read-only')));
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart:1070:            'Export Yarn (lecture seule depuis les blocs)',
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_empty_state.dart:136:/// Elle reste volontairement en lecture seule, mais la phase 5 ajoute une
packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart:73:      expect(find.textContaining('shell read-only'), findsNothing);
packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart:74:      expect(find.textContaining('lecture seule'), findsNothing);
packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart:75:      expect(find.textContaining('génération sur carte arrive bientôt'),
packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart:121:      expect(find.textContaining('shell read-only'), findsNothing);
packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart:122:      expect(find.textContaining('lecture seule'), findsNothing);
packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart:5:/// Première façade applicative Pokédex orientée liste, en lecture seule.
packages/map_editor/lib/src/application/models/pokemon_database_index.dart:95:  ///   lecture seule ;
packages/map_editor/lib/src/application/models/pokedex_species_detail.dart:3:/// Agrégat de détail Pokédex en lecture seule.
packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart:56:      expect(find.textContaining('shell read-only'), findsNothing);
packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart:57:      expect(find.textContaining('lecture seule'), findsNothing);
packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart:78:      expect(find.textContaining('shell read-only'), findsNothing);
packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart:79:      expect(find.textContaining('génération sur carte arrive bientôt'),
```

Lecture du résultat `rg` :
- aucune occurrence `shell read-only` dans `packages/map_editor/lib` ;
- les occurrences `lecture seule` restantes dans `packages/map_editor/lib` sont hors Environment Studio visible ;
- les occurrences `shell read-only` restantes dans `packages/map_editor/test` sont des assertions de non-présence.

## 17. Diff pertinent

Nouveau fichier complet — `packages/map_editor/lib/src/features/environment_studio/widgets/environment_element_thumbnail.dart` :

```dart
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../ui/shared/cupertino_editor_widgets.dart';

typedef EnvironmentTilesetPathResolver = String? Function(String tilesetId);

class EnvironmentElementThumbnail extends StatelessWidget {
  const EnvironmentElementThumbnail({
    super.key,
    required this.manifest,
    required this.element,
    required this.elementId,
    this.resolveTilesetPathById,
    this.size = 34,
    this.previewKey,
    this.fallbackKey,
    this.fallbackAccent,
  });

  final ProjectManifest manifest;
  final ProjectElementEntry? element;
  final String elementId;
  final EnvironmentTilesetPathResolver? resolveTilesetPathById;
  final double size;
  final Key? previewKey;
  final Key? fallbackKey;
  final Color? fallbackAccent;

  @override
  Widget build(BuildContext context) {
    final resolved = _ResolvedEnvironmentElementThumbnail.resolve(
      manifest: manifest,
      element: element,
      resolveTilesetPathById: resolveTilesetPathById,
    );
    if (resolved == null) {
      return _fallback(context);
    }

    final croppedImage = _EnvironmentElementThumbnailImageCache.crop(resolved);
    if (croppedImage == null) {
      return _fallback(context);
    }
    return Container(
      key: previewKey,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: EditorChrome.badgeFill(context),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _EnvironmentElementThumbnailRasterPainter(croppedImage),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    final accent = fallbackAccent ?? EditorChrome.accentJade;
    final id = elementId.trim();
    return Container(
      key: fallbackKey,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: accent.withValues(alpha: 0.38)),
      ),
      child: Text(
        id.isEmpty ? '?' : id.characters.first.toUpperCase(),
        style: TextStyle(
          color: accent,
          fontSize: size <= 30 ? 13 : 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ResolvedEnvironmentElementThumbnail {
  const _ResolvedEnvironmentElementThumbnail({
    required this.path,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
  });

  final String path;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;

  static _ResolvedEnvironmentElementThumbnail? resolve({
    required ProjectManifest manifest,
    required ProjectElementEntry? element,
    required EnvironmentTilesetPathResolver? resolveTilesetPathById,
  }) {
    if (element == null || element.frames.isEmpty) {
      return null;
    }
    final frame = element.frames.primaryFrame;
    final tilesetId = frame.tilesetId.trim().isNotEmpty
        ? frame.tilesetId.trim()
        : element.tilesetId.trim();
    if (tilesetId.isEmpty) {
      return null;
    }
    final tileWidth = manifest.settings.tileWidth;
    final tileHeight = manifest.settings.tileHeight;
    if (tileWidth <= 0 || tileHeight <= 0) {
      return null;
    }
    final source = frame.source;
    if (source.width <= 0 || source.height <= 0) {
      return null;
    }
    final path = _resolvePath(
      manifest: manifest,
      tilesetId: tilesetId,
      resolveTilesetPathById: resolveTilesetPathById,
    );
    if (path == null) {
      return null;
    }
    return _ResolvedEnvironmentElementThumbnail(
      path: path,
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
    );
  }

  static String? _resolvePath({
    required ProjectManifest manifest,
    required String tilesetId,
    required EnvironmentTilesetPathResolver? resolveTilesetPathById,
  }) {
    final resolved = resolveTilesetPathById?.call(tilesetId)?.trim();
    if (resolved != null && resolved.isNotEmpty) {
      return resolved;
    }
    for (final tileset in manifest.tilesets) {
      if (tileset.id != tilesetId) {
        continue;
      }
      final relativePath = tileset.relativePath.trim();
      if (relativePath.isNotEmpty && p.isAbsolute(relativePath)) {
        return relativePath;
      }
      return null;
    }
    return null;
  }

  String get cacheKey {
    return [
      path,
      source.x,
      source.y,
      source.width,
      source.height,
      tileWidth,
      tileHeight,
    ].join('|');
  }

  img.Image? crop() {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        return null;
      }
      final bytes = file.readAsBytesSync();
      if (bytes.isEmpty) {
        return null;
      }
      final image = img.decodeImage(bytes);
      if (image == null || !fits(image.width, image.height)) {
        return null;
      }
      final cropped = img.copyCrop(
        image,
        x: source.x * tileWidth,
        y: source.y * tileHeight,
        width: source.width * tileWidth,
        height: source.height * tileHeight,
      );
      return cropped;
    } catch (_) {
      return null;
    }
  }

  bool fits(int imageWidth, int imageHeight) {
    final left = source.x * tileWidth;
    final top = source.y * tileHeight;
    final width = source.width * tileWidth;
    final height = source.height * tileHeight;
    return left >= 0 &&
        top >= 0 &&
        width > 0 &&
        height > 0 &&
        left + width <= imageWidth &&
        top + height <= imageHeight;
  }
}

class _EnvironmentElementThumbnailRasterPainter extends CustomPainter {
  _EnvironmentElementThumbnailRasterPainter(this.image);

  final img.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = _scaleToFit(size);
    final drawWidth = image.width * scale;
    final drawHeight = image.height * scale;
    final left = (size.width - drawWidth) / 2;
    final top = (size.height - drawHeight) / 2;
    final paint = Paint();
    for (var y = 0; y < image.height; y += 1) {
      for (var x = 0; x < image.width; x += 1) {
        final pixel = image.getPixel(x, y);
        paint.color = Color.fromARGB(
          pixel.a.toInt(),
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
        );
        canvas.drawRect(
          Rect.fromLTWH(
            left + x * scale,
            top + y * scale,
            scale.ceilToDouble(),
            scale.ceilToDouble(),
          ),
          paint,
        );
      }
    }
  }

  double _scaleToFit(Size size) {
    final widthScale = size.width / image.width;
    final heightScale = size.height / image.height;
    return widthScale < heightScale ? widthScale : heightScale;
  }

  @override
  bool shouldRepaint(covariant _EnvironmentElementThumbnailRasterPainter old) {
    return old.image != image;
  }
}

class _EnvironmentElementThumbnailImageCache {
  static final Map<String, img.Image?> _cache = {};

  static img.Image? crop(_ResolvedEnvironmentElementThumbnail resolved) {
    return _cache.putIfAbsent(resolved.cacheKey, resolved.crop);
  }
}
```

Hunks principaux des fichiers existants :

```diff
diff --git a/packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart b/packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart
@@
+    final notifier = ref.read(editorNotifierProvider.notifier);
     return EnvironmentStudioPanel(
       manifest: manifest,
+      resolveTilesetPathById: notifier.getTilesetAbsolutePathById,
@@
-        ref.read(editorNotifierProvider.notifier).applyInMemoryProjectManifest(
-              nextManifest,
-              statusMessage: msg,
-            );
+        notifier.applyInMemoryProjectManifest(
+          nextManifest,
+          statusMessage: msg,
+        );
```

```diff
diff --git a/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_creation_wizard.dart b/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_creation_wizard.dart
@@
+import 'environment_element_thumbnail.dart';
@@
+    this.resolveTilesetPathById,
@@
+  final EnvironmentTilesetPathResolver? resolveTilesetPathById;
@@
-    return Container(
+    return KeyedSubtree(
       key: Key('environment-creation-element-preview-${element.id}'),
-      width: 42,
-      height: 42,
-      alignment: Alignment.center,
-      decoration: BoxDecoration(
-        color: accent.withValues(alpha: 0.18),
-        borderRadius: BorderRadius.circular(10),
-        border: Border.all(color: accent.withValues(alpha: 0.45)),
-      ),
-      child: Icon(
-        CupertinoIcons.square_grid_2x2_fill,
-        color: accent,
-        size: 20,
+      child: EnvironmentElementThumbnail(
+        manifest: widget.manifest,
+        element: element,
+        elementId: element.id,
+        resolveTilesetPathById: widget.resolveTilesetPathById,
+        size: 42,
+        previewKey: Key('environment-element-preview-${element.id}'),
+        fallbackKey: Key('environment-element-preview-fallback-${element.id}'),
+        fallbackAccent: accent,
```

```diff
diff --git a/packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart b/packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart
@@
+import 'environment_element_thumbnail.dart';
@@
+    this.manifest,
+    this.resolveTilesetPathById,
@@
+  final ProjectManifest? manifest;
+  final EnvironmentTilesetPathResolver? resolveTilesetPathById;
@@
+        EnvironmentElementThumbnail(
+          manifest: widget.manifest!,
+          element: selectedElement,
+          elementId: widget.item.elementId,
+          resolveTilesetPathById: widget.resolveTilesetPathById,
+          size: 34,
+          previewKey: Key(
+            'environment-selected-palette-preview-$previewId',
+          ),
+          fallbackKey: Key(
+            'environment-selected-palette-preview-fallback-$previewId',
+          ),
+        ),
```

```diff
diff --git a/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart b/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
@@
     EditorWorkspaceMode.environmentStudio =>
-      'Presets d’environnements organiques et diagnostics — shell read-only.',
+      'Presets d’environnements réutilisables',
```

```diff
diff --git a/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart b/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
@@
-          subtitle: 'Presets d’environnements organiques (shell read-only)',
+          subtitle: 'Presets d’environnements réutilisables',
@@
-            'Résumé presets et diagnostics — lecture seule',
+            'Créez et organisez vos presets d’environnements.',
```

```diff
diff --git a/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart b/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart
@@
+      expect(
+        find.byKey(const Key('environment-element-preview-grass_a')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const Key('environment-element-preview-fallback-grass_a')),
+        findsNothing,
+      );
@@
+      expect(
+        find.byKey(const Key('environment-element-preview-fallback-grass_a')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const Key('environment-element-preview-grass_a')),
+        findsNothing,
+      );
@@
+      expect(
+        find.byKey(const Key('environment-selected-palette-preview-grass_a')),
+        findsOneWidget,
+      );
```

## 18. Auto-review

- Les éléments compatibles affichent-ils une vraie miniature ? Oui, quand le tileset image est résolu.
- La palette sélectionnée affiche-t-elle aussi cette miniature ? Oui, dans `EnvironmentPaletteItemDraftEditor` et `EnvironmentPaletteItemView`.
- Le fallback est-il utilisé seulement quand la ressource réelle est indisponible ? Oui, via résolution/crop/bounds checks.
- Le rendu permet-il de distinguer `rock cliff 1 / 2 / 3` visuellement ? Oui si leurs frames pointent vers des rectangles différents dans une image résolue.
- Le flow tileset-first est-il intact ? Oui, tests 3C verts.
- Le guard anti-mélange tileset est-il intact ? Oui, tests compatibility/use case/TileLayer verts.
- La création mémoire est-elle intacte ? Oui, tests save manifest et wizard verts.
- Le texte `shell read-only` a-t-il disparu de l’UI principale ? Oui, plus aucune occurrence dans `packages/map_editor/lib`.
- La recherche `rg` ne trouve-t-elle plus que des assertions de non-présence si elles existent ? Pour `shell read-only`, oui côté tests ; `lecture seule` reste dans des commentaires et UI hors Environment Studio.
- Aucun `map_core` modifié ? Oui.
- Aucun ProjectManifest model modifié ? Oui.
- Aucun generated file ? Oui.
- Aucun build_runner ? Oui.
- Aucun TileLayer inspector modifié ? Oui.
- Aucun canvas modifié ? Oui.
- Aucune peinture/génération Environment Studio ? Oui.

## 19. Critique du prompt et du lot

Clair :
- le besoin produit est net : montrer ce que l’utilisateur ajoute ;
- le périmètre UI est correctement borné ;
- l’absence de `map_core` et de persistance disque est explicite.

Ambigu ou risqué :
- le prompt demande beaucoup de commentaires utiles dans le code, mais le contrat du lot et les consignes repo interdisent les commentaires inutiles et demandent aucun commentaire dans ce type de lot. J’ai choisi de ne pas ajouter de commentaire de code.
- la commande `rg` demandée cherche `lecture seule` dans tout `packages/map_editor/lib`; il existe des occurrences hors Environment Studio qui ne sont pas des régressions 3E.
- une preview réelle nécessite un accès fichier. Le workspace réel le permet via `EditorNotifier.getTilesetAbsolutePathById`; les harness sans racine projet utilisent le fallback.

À trancher plus tard :
- factoriser un helper image partagé avec Path Studio / Tileset Palette Panel ;
- ajouter une vraie mesure de perf si de très gros sprites multi-tiles apparaissent dans les palettes Environment ;
- décider si le fallback doit être enrichi avec une icône par famille d’éléments.

## 20. Verdict de fermeture

```text
EnvironmentStudio-3E livré
Code produit modifié : oui
Code UI modifié : oui
Tests ciblés : pass
Analyze ciblé : pass
git diff --check : pass
Prochain lot recommandé : aucun lot Environment Studio UI principal, sauf bug réel ou polish visuel validé sur screenshot.
```
