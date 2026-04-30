# Lot TSX-8 — Reference UI Implementation / Functional TSX Surface Builder V1

## 1. Verdict

TSX-8 implémenté.

Le workspace TSX a été réorganisé en interface guidée proche de la référence : action bar, stepper 3 étapes, colonne groupes détectés, colonne rôles de surface, colonne prévisualisation / état / enregistrement. Le mapping reste explicite, aucun rôle n'est deviné automatiquement, et le bouton `Enregistrer la surface` crée un `ProjectSurfacePreset` uniquement après mapping valide de `Plein(center)`.

## 2. Audit Initial

### Commandes exécutées

```bash
pwd
git status --short --untracked-files=all
git diff --stat
rg -n "TiledTsxWorkspace|TiledTsxAnimationBrowser|TiledTsxSurfacePresetDraft|roleAnimationIds|Suggestions Mistral|Proposer un mapping|Créer le preset|ProjectSurfacePreset|SurfaceVariantRole|surface_studio.primary_tabs|Catalogue Surface|Créer une surface|Diagnostics" packages/map_editor/lib packages/map_editor/test packages/map_core/lib
```

### Réponses d'audit

1. Le workspace TSX est rendu par `TiledTsxWorkspace`, branché dans `SurfaceStudioPanel` quand le workspace primaire TSX est actif.
2. Le browser TSX est rendu par `TiledTsxAnimationBrowser`; avant TSX-8, il portait encore beaucoup du parcours principal.
3. Le builder `role -> animation` venait de TSX-7 via `TiledTsxRoleMappingBuilder`, mais il était encore inséré dans un panneau de browser plutôt que dans une vraie structure produit.
4. L'UI restait difficile à comprendre parce que le parcours principal mélangeait import, liste brute d'animations, actions Mistral, builder et preview dans un empilement technique.
5. Les composants réutilisables conservés : parser/import TSX, append catalog, `TiledTsxRoleMappingBuilder`, `TiledTsxAnimationTilePreview`, draft TSX-4, parser Mistral, browser TSX secondaire.
6. Les composants remplacés dans le chemin principal : l'ancien empilement `Workspace TSX -> Import -> Browser` est maintenant précédé par un builder guidé de référence.
7. Les suggestions Mistral continuent d'être appliquées au draft local par le browser existant ; TSX-8 ne change pas le contrat Mistral.
8. Le preset est créé via `TiledTsxSurfacePresetDraft`, `validateTiledTsxSurfacePresetDraft`, `buildTiledTsxSurfacePresetFromDraft` et `surfaceStudioAppendPresetToWorkCatalog`.
9. La preview existante d'animation est réutilisée pour les groupes, les rôles et la preview globale V1.
10. Parties fonctionnelles préservées : import TSX, transparence TSX en mémoire, browser d'animations, Mistral UI, preset builder TSX-4, tests TSX existants.

## 3. Correspondance Avec L'image De Référence

La référence demandait :

- tabs primaires `Catalogue`, `Créer une surface`, `Diagnostics` ;
- action bar `Importer un TSX`, `Détection auto`, `Appliquer les suggestions`, état assistant IA ;
- stepper 3 étapes ;
- colonne gauche `Groupes détectés` ;
- colonne centrale `Rôles de surface` ;
- colonne droite `Prévisualisation`, `État de la surface`, `Enregistrer la surface`.

TSX-8 implémente cette structure dans le workspace TSX. L'onglet primaire `TSX` a été renommé `Créer une surface`, et `Catalogue Surface` a été raccourci en `Catalogue` au niveau de navigation primaire. L'onglet `Hautes herbes` reste disponible pour préserver le workflow existant.

## 4. Nouvelle Structure UI

Le composant `TiledTsxWorkspace` affiche maintenant :

1. Header produit `Créer une surface`.
2. Action bar.
3. Section import TSX existante.
4. Builder de référence si des animations existent.
5. Browser TSX existant comme accès secondaire sous le builder.

## 5. Groupes Détectés

Ajout d'un modèle de présentation local :

- `TiledTsxDetectedAnimationGroup` ;
- `TiledTsxDetectedAnimationGroupKind` ;
- `buildTiledTsxDetectedAnimationGroups`.

V1 utilise un regroupement heuristique stable par `baseTileId`, en groupes de 40 animations maximum. Le but est de remplacer la liste brute de 242 animations par des groupes visibles et utilisables. Les labels restent prudents : `Groupe détecté 1`, etc., pour ne pas inventer une sémantique eau/lave/herbe sans preuve.

## 6. Role Mapping Builder

Le builder visuel TSX-7 est maintenant placé au centre du parcours TSX-8, dans le panneau `Rôles de surface`. Le groupe actif filtre les animations proposées au picker.

## 7. Animation Picker

Le picker reste celui de `TiledTsxRoleMappingBuilder` : recherche, preview/fallback, frame count, base tile, sélection par clic. Aucun champ texte brut n'est requis pour mapper un rôle.

## 8. Review Mistral

La review Mistral visuelle de TSX-7 est conservée dans le browser TSX secondaire. L'action bar TSX-8 expose `Appliquer les suggestions` sans appliquer silencieusement quoi que ce soit ; si aucune suggestion acceptée n'est prête, elle affiche une note non destructive.

## 9. Preview Globale

La colonne droite contient une preview globale V1 :

- si `Plein(center)` manque : message explicite ;
- si `Plein(center)` est assigné : mosaïque de preview avec la tile assignée ;
- contrôles visuels `Play`, track image, `Boucle` ;
- checklist `Centre`, `Bords`, `Coins`, `Cohérence`.

## 10. Enregistrement Surface

Le bouton `Enregistrer la surface` :

- est disabled tant que `Plein(center)` manque ;
- construit un `TiledTsxSurfacePresetDraft` ;
- valide le draft ;
- crée un `ProjectSurfacePreset` visuel ;
- ajoute le preset au catalogue de travail ;
- ne sauvegarde rien sur disque ;
- ne mute pas directement le `ProjectManifest`.

## 11. Tests

### Tests ciblés TSX-8

#### tsx8_reference_ui.log

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_surface_builder_reference_ui_test.dart
00:00 +0: TSX workspace matches the reference builder structure
00:00 +1: All tests passed!
```

#### tsx8_role_mapping_builder.log

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_role_mapping_builder_test.dart
00:00 +0: shows visual role slots and maps roles through a picker
00:00 +1: All tests passed!
```

#### tsx8_mistral_review_ui.log

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_mistral_review_ui_test.dart
00:00 +0: Mistral review shows visual suggestions and grouped duplicates
00:00 +1: All tests passed!
```

#### tsx8_surface_preview_ui.log

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_surface_preview_ui_test.dart
00:00 +0: reference builder saves a preset only after visual role mapping
00:01 +1: All tests passed!
```


### Régressions TSX

#### tsx8_import_ui.log

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart
00:00 +0: TiledTsxWorkspace import UI loads a TSX, shows summary, imports atlas and animations
00:01 +1: TiledTsxWorkspace import UI blocks import when no matching tileset is available
00:01 +2: TiledTsxWorkspace import UI shows parser errors for invalid TSX
00:01 +3: TiledTsxWorkspace import UI blocks TSX without animations
00:01 +4: TiledTsxWorkspace import UI reports duplicate atlas id without mutating the catalog
00:01 +5: All tests passed!
```

#### tsx8_animation_browser.log

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_animation_browser_test.dart
00:00 +0: TiledTsxAnimationBrowser models builds browser items from the 242 imported Pokemon SDK animations
00:00 +1: TiledTsxAnimationBrowser models filters by animation id, display name, and base tile id
00:00 +2: TiledTsxAnimationBrowser widget selects and clears animations without mutating the catalog
00:00 +3: TiledTsxAnimationBrowser widget searches by tile id in the browser UI
00:01 +4: TiledTsxAnimationBrowser widget shows imported TSX frame details for tile 99
00:01 +5: TiledTsxSurfaceAnimationPreview steps through explicit ProjectSurfaceAnimation frames
00:01 +6: TiledTsxSurfaceAnimationPreview lists frames when atlas image bytes are unavailable
00:01 +7: All tests passed!
```

#### tsx8_mistral_grouping_ui.log

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart
00:00 +0: Mistral grouping button requires selection and configured key
00:00 +1: Mistral grouping shows missing key message
00:00 +2: Mistral grouping requires confirmation, shows progress, then fills draft only after accept
00:01 +3: All tests passed!
```

#### tsx8_surface_preset_builder.log

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_surface_preset_builder_test.dart
00:00 +0: TiledTsxSurfacePresetDraft validates and builds a preset from an explicit isolated mapping
00:00 +1: TiledTsxSurfacePresetDraft rejects duplicate preset ids
00:00 +2: TiledTsxSurfacePresetDraft requires isolated and known animation ids
00:00 +3: TiledTsxSurfacePresetDraft reports draft identity errors
00:00 +4: TiledTsxSurfacePresetDraft builds a preset from the real Pokemon SDK TSX import output
00:00 +5: All tests passed!
```

#### tsx8_workspace_tab.log

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_workspace_tab_test.dart
00:00 +0: Surface Studio exposes a first-level TSX workspace
00:00 +1: Diagnostics remain available as their own top-level workspace
00:01 +2: All tests passed!
```

#### tsx8_surface_studio_panel.log

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
00:00 +0: SurfaceStudioPanel V2.1 renders one wizard and no legacy workflow underneath
00:00 +1: SurfaceStudioPanel V2.1 keeps catalog and diagnostics in the advanced drawer
00:01 +2: SurfaceStudioPanel V2.1 opens a tall grass subtab from Surface Studio
00:01 +3: SurfaceStudioPanel V2.1 shows tall grass authoring signals from the project manifest
00:01 +4: SurfaceStudioPanel V2.1 imports TECH-Nature static tall grass assets
00:01 +5: SurfaceStudioPanel V2.1 SurfaceStudioPanelFromManifest saves the work catalog by action
00:02 +6: SurfaceStudioPanel V2.1 SurfaceStudioPanel still builds without ProviderScope
00:02 +7: All tests passed!
```


### Tous les tests Surface Studio

Commande exacte :

```bash
cd packages/map_editor && flutter test test/surface_studio --no-pub --reporter expanded
```

Ligne finale exacte :

```text
00:20 +425: All tests passed!
```

## 12. Analyze

Commande exacte :

```bash
cd packages/map_editor && flutter analyze lib/src/features/surface_studio lib/src/features/editor/application/editor_ai_settings.dart
```

Sortie complète :

```text
Analyzing 2 items...                                            
No issues found! (ran in 2.0s)
```

## 13. QA Runtime

Commande lancée :

```bash
cd packages/map_editor && flutter run -d macos
```

Sortie observée :

```text
Launching lib/main.dart on macOS in debug mode...
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
2026-04-30 02:59:43.794 map_editor[82738:18067503] Running with merged UI and platform thread. Experimental.
Syncing files to device macOS...                                   228ms

Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

A Dart VM Service on macOS is available at: http://127.0.0.1:60309/2Xdfq8OzJmE=/
The Flutter DevTools debugger and profiler on macOS is available at:
http://127.0.0.1:60309/2Xdfq8OzJmE=/devtools/?uri=ws://127.0.0.1:60309/2Xdfq8OzJmE=/ws
flutter: FileProjectRepository: Loading project from /Users/karim/Desktop/my_new_project/project.json
Application finished.
```

Limite honnête : l'application macOS a été compilée et lancée, puis quittée proprement via `q`. Je n'ai pas fait de QA interactive complète dans l'écran réel avec clics d'import/assignation/sauvegarde. Donc la QA runtime visuelle complète reste à faire côté session utilisateur.

## 14. Non-objectifs Confirmés

- Pas de modification `map_core`.
- Pas de modification `map_runtime`.
- Pas de modification `map_gameplay`.
- Pas de modification `map_battle`.
- Pas de gameplay.
- Pas de `MapGameplayZone`.
- Pas de `SurfaceLayer` gameplay.
- Pas de sauvegarde disque automatique.
- Pas de mutation directe `ProjectManifest`.
- Pas de création automatique de `ProjectTilesetEntry`.
- Pas de PixelLab.
- Pas de MCP.
- Pas de génération d'image.
- Pas de nouveau secret API.
- Pas de suppression du workflow atlas vertical.
- Pas de suppression des flows TSX existants.

## 15. Limites Restantes

- Les groupes V1 sont heuristiques et prudents ; ils ne prétendent pas identifier sémantiquement `Eau calme`, `Cascade`, etc.
- La preview globale V1 utilise principalement le centre assigné ; l'utilisation fine des coins/bords dans une vraie composition surface reste améliorable.
- L'action bar `Appliquer les suggestions` est non destructive et ne fait pas encore une orchestration complète de suggestions acceptées hors du browser Mistral existant.
- Le browser TSX reste affiché sous le builder comme accès secondaire ; une prochaine passe peut décider de le déplacer dans une vue avancée.

## 16. Roadmap Suivante

TSX-9 — TSX Region / Grouping UX V0 :

- améliorer la détection / regroupement d'animations ;
- masquer les animations déjà utilisées ;
- proposer des packs candidats plus intelligents ;
- préparer des contact sheets paginées pour Mistral.

TSX-10 — Paginated Mistral animation contact sheets si les grands ensembles restent difficiles à analyser.

## 17. Fichiers Créés / Modifiés

### Créés TSX-8

- `packages/map_editor/test/surface_studio/tiled_tsx_surface_builder_reference_ui_test.dart`
- `packages/map_editor/test/surface_studio/tiled_tsx_surface_preview_ui_test.dart`

### Modifiés TSX-8

- `packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`
- `packages/map_editor/test/surface_studio/tiled_tsx_workspace_tab_test.dart`

### Changements préexistants toujours présents

Le worktree contenait déjà des changements TSX-6/TSX-7/tall grass/transparent color avant TSX-8. Ils restent présents et ne sont pas revendiqués comme nouveaux TSX-8 :

- `packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animation_browser.dart`
- `packages/map_editor/macos/Runner/MainFlutterWindow.swift`
- `packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart`
- `packages/map_editor/test/surface_studio/tiled_tsx_surface_preset_builder_ui_test.dart`
- `packages/map_editor/lib/src/features/surface_studio/importers/tall_grass_tsx_asset_importer.dart`
- `packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_role_mapping_builder.dart`
- `packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_transparent_color.dart`
- `packages/map_editor/test/surface_studio/tall_grass_tsx_asset_importer_test.dart`
- `packages/map_editor/test/surface_studio/tiled_tsx_mistral_review_ui_test.dart`
- `packages/map_editor/test/surface_studio/tiled_tsx_role_mapping_builder_test.dart`
- `packages/map_editor/test/surface_studio/tiled_tsx_transparent_color_test.dart`
- `reports/surface/surface_studio_tiled_tsx_role_mapping_ux_v0.md`

## 18. Contenu Complet Des Fichiers Créés / Modifiés TSX-8

### packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart

```dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show
        DropdownButton,
        DropdownMenuItem,
        ElevatedButton,
        Material,
        MaterialType;
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../ui/shared/cupertino_editor_widgets.dart';
import '../surface_studio_vertical_atlas_preset_generator.dart';
import 'tiled_tsx_animated_tileset_parser.dart';
import 'tiled_tsx_animation_browser.dart';
import 'tiled_tsx_animation_browser_models.dart';
import 'tiled_tsx_catalog_append.dart';
import 'tiled_tsx_mistral_grouping_suggester.dart';
import 'tiled_tsx_role_mapping_builder.dart';
import 'tiled_tsx_surface_animation_importer.dart';
import 'tiled_tsx_surface_preset_draft.dart';
import 'tiled_tsx_transparent_color.dart';

final class TiledTsxLoadedFile {
  const TiledTsxLoadedFile({
    required this.path,
    required this.fileName,
    required this.xml,
  });

  final String path;
  final String fileName;
  final String xml;
}

const MethodChannel _macOsTiledTsxFileAccessChannel =
    MethodChannel('map_editor/file_access');

abstract interface class TiledTsxFileLoader {
  Future<TiledTsxLoadedFile?> pickAndLoadTsx();
}

final class TiledTsxPlatformFileLoader implements TiledTsxFileLoader {
  const TiledTsxPlatformFileLoader();

  @override
  Future<TiledTsxLoadedFile?> pickAndLoadTsx() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['tsx'],
      withData: false,
    );
    final path = picked?.files.single.path;
    if (path == null) {
      return null;
    }
    await _beginTiledTsxImportBundleAccessIfNeeded(path);
    final xml = await File(path).readAsString();
    return TiledTsxLoadedFile(
      path: path,
      fileName: p.basename(path),
      xml: xml,
    );
  }
}

Future<void> _beginTiledTsxImportBundleAccessIfNeeded(
    String selectedPath) async {
  if (defaultTargetPlatform != TargetPlatform.macOS) {
    return;
  }
  try {
    await _macOsTiledTsxFileAccessChannel.invokeMethod<void>(
      'beginImportBundleAccess',
      <String, String>{'selectedPath': selectedPath},
    );
  } catch (_) {
    // Best effort only: non-macOS tests and unsandboxed builds do not need it.
  }
}

class TiledTsxWorkspace extends StatefulWidget {
  const TiledTsxWorkspace({
    super.key,
    required this.catalog,
    this.projectTilesets = const <ProjectTilesetEntry>[],
    this.onSurfaceCatalogChanged,
    this.fileLoader = const TiledTsxPlatformFileLoader(),
    this.atlasImageBytes,
    this.projectSettings,
    this.groupingSuggester,
  });

  final ProjectSurfaceCatalog catalog;
  final List<ProjectTilesetEntry> projectTilesets;
  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogChanged;
  final TiledTsxFileLoader fileLoader;
  final Uint8List? atlasImageBytes;
  final ProjectSettings? projectSettings;
  final TiledTsxAnimationGroupingSuggester? groupingSuggester;

  @override
  State<TiledTsxWorkspace> createState() => _TiledTsxWorkspaceState();
}

class _TiledTsxWorkspaceState extends State<TiledTsxWorkspace> {
  TiledTsxLoadedFile? _loadedFile;
  TiledTsxTilesetAudit? _audit;
  ProjectTilesetEntry? _selectedTileset;
  ProjectSurfaceCatalog? _localCatalog;
  bool _loading = false;
  String? _statusMessage;
  List<String> _errors = const <String>[];
  Uint8List? _transparentPreviewSourceBytes;
  Uint8List? _transparentPreviewBytes;
  String? _transparentPreviewColor;
  String? _activeGroupId;
  Map<SurfaceVariantRole, String> _roleAnimationIds =
      const <SurfaceVariantRole, String>{};
  Map<SurfaceVariantRole, TiledTsxRoleAssignmentMeta> _roleSources =
      const <SurfaceVariantRole, TiledTsxRoleAssignmentMeta>{};
  List<String> _surfaceSaveErrors = const <String>[];
  List<String> _surfaceSaveWarnings = const <String>[];
  String? _surfaceSaveNote;
  String? _detectionMessage;

  @override
  void didUpdateWidget(covariant TiledTsxWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.catalog != oldWidget.catalog) {
      _localCatalog = null;
    }
    if (widget.projectTilesets != oldWidget.projectTilesets) {
      _selectedTileset = _pickMatchingTileset(_audit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final effectiveCatalog = _localCatalog ?? widget.catalog;
    final atlas = _atlasForBrowser(effectiveCatalog);
    final animations = effectiveCatalog.animations;
    final previewAtlasImageBytes = _previewAtlasImageBytes();
    return SingleChildScrollView(
      key: const ValueKey('surface_studio.tsx_workspace'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TsxWorkspaceHeader(label: label, subtle: subtle),
          const SizedBox(height: 12),
          _TsxReferenceActionBar(
            loading: _loading,
            hasAnimations: animations.isNotEmpty,
            hasMistralKey: widget.projectSettings?.mistralApiKey
                    ?.trim()
                    .isNotEmpty ==
                true,
            onImport: _pickTsx,
            onDetect: _runLocalDetection,
            onApplySuggestions: _applyPreparedSuggestions,
          ),
          const SizedBox(height: 12),
          _ImportSection(
            loadedFile: _loadedFile,
            audit: _audit,
            projectTilesets: widget.projectTilesets,
            selectedTileset: _selectedTileset,
            loading: _loading,
            statusMessage: _statusMessage,
            errors: _errors,
            atlasImageBytesAvailable: widget.atlasImageBytes != null,
            onPickTsx: _pickTsx,
            onTilesetChanged: (tileset) {
              setState(() => _selectedTileset = tileset);
            },
            onConfirmImport: _canConfirmImport ? _confirmImport : null,
          ),
          const SizedBox(height: 14),
          if (animations.isEmpty)
            _TsxEmptyState(onImportPressed: _pickTsx)
          else
            _ReferenceTsxSurfaceBuilder(
              atlas: atlas,
              animations: animations,
              atlasImageBytes: previewAtlasImageBytes,
              catalog: effectiveCatalog,
              activeGroupId: _activeGroupId,
              roleAnimationIds: _roleAnimationIds,
              roleSources: _roleSources,
              detectionMessage: _detectionMessage,
              saveErrors: _surfaceSaveErrors,
              saveWarnings: _surfaceSaveWarnings,
              saveNote: _surfaceSaveNote,
              onGroupSelected: (id) {
                setState(() {
                  _activeGroupId = id;
                  _detectionMessage = null;
                });
              },
              onRoleAssignmentsChanged: _replaceRoleAssignments,
              onSaveSurface: widget.onSurfaceCatalogChanged == null
                  ? null
                  : _saveReferenceSurface,
            ),
          if (animations.isNotEmpty) ...[
            const SizedBox(height: 14),
            TiledTsxAnimationBrowser(
              atlas: atlas,
              animations: animations,
              atlasImageBytes: previewAtlasImageBytes,
              sourceLabel: _loadedFile?.fileName ?? 'Catalogue de travail',
              catalog: effectiveCatalog,
              onSurfaceCatalogChanged: widget.onSurfaceCatalogChanged,
              projectSettings: widget.projectSettings,
              groupingSuggester: widget.groupingSuggester,
            ),
          ],
        ],
      ),
    );
  }

  Uint8List? _previewAtlasImageBytes() {
    final source = widget.atlasImageBytes;
    if (source == null) {
      _transparentPreviewSourceBytes = null;
      _transparentPreviewBytes = null;
      _transparentPreviewColor = null;
      return null;
    }
    final transparentColor = _audit?.summary.transparentColor;
    if (parseTiledTsxTransparentColor(transparentColor) == null) {
      return source;
    }
    if (identical(source, _transparentPreviewSourceBytes) &&
        transparentColor == _transparentPreviewColor &&
        _transparentPreviewBytes != null) {
      return _transparentPreviewBytes;
    }
    final transformed = applyTiledTsxTransparentColorToPngBytes(
      imageBytes: source,
      transparentColor: transparentColor,
    );
    _transparentPreviewSourceBytes = source;
    _transparentPreviewColor = transparentColor;
    _transparentPreviewBytes = transformed;
    return transformed;
  }

  bool get _canConfirmImport =>
      !_loading &&
      _audit != null &&
      _audit!.hasErrors == false &&
      _audit!.summary.animationCount > 0 &&
      _selectedTileset != null;

  Future<void> _pickTsx() async {
    setState(() {
      _loading = true;
      _statusMessage = null;
      _errors = const <String>[];
    });
    try {
      final loaded = await widget.fileLoader.pickAndLoadTsx();
      if (!mounted) {
        return;
      }
      if (loaded == null) {
        setState(() {
          _loading = false;
          _statusMessage = 'Import TSX annulé.';
        });
        return;
      }
      final audit = parseTiledTsxAnimatedTileset(loaded.xml);
      final errors = <String>[
        if (audit.hasErrors) 'Le fichier XML TSX est invalide ou incomplet.',
        if (!audit.hasErrors && audit.summary.animationCount == 0)
          'Le TSX ne contient aucune animation.',
        ...audit.diagnostics
            .where(
              (diagnostic) =>
                  diagnostic.severity == TiledTsxDiagnosticSeverity.error,
            )
            .map((diagnostic) => diagnostic.message),
      ];
      setState(() {
        _loadedFile = loaded;
        _audit = audit;
        _selectedTileset = _pickMatchingTileset(audit);
        _loading = false;
        _statusMessage = null;
        _errors = List<String>.unmodifiable(errors);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errors = ['Le fichier XML TSX est invalide ou incomplet.', '$error'];
      });
    }
  }

  void _confirmImport() {
    final audit = _audit;
    final tileset = _selectedTileset;
    if (audit == null || tileset == null) {
      return;
    }
    final prefix = _slugify(audit.summary.name);
    final imported = importTiledTsxSurfaceAnimations(
      audit: audit,
      options: TiledTsxSurfaceAnimationImportOptions(
        atlasId: prefix,
        tilesetId: tileset.id,
        animationIdPrefix: prefix,
        sortOrderBase: widget.catalog.animationCount,
      ),
    );
    if (imported.hasErrors || imported.atlas == null) {
      setState(() {
        _errors = imported.diagnostics
            .where(
              (diagnostic) =>
                  diagnostic.severity ==
                  TiledTsxSurfaceAnimationImportDiagnosticSeverity.error,
            )
            .map((diagnostic) => diagnostic.message)
            .toList(growable: false);
        _statusMessage = null;
      });
      return;
    }
    final appended = appendTiledTsxSurfaceImportToCatalog(
      catalog: _localCatalog ?? widget.catalog,
      atlas: imported.atlas!,
      animations: imported.animations,
    );
    if (appended.hasErrors || appended.catalog == null) {
      setState(() {
        _errors = appended.errors;
        _statusMessage = null;
      });
      return;
    }
    widget.onSurfaceCatalogChanged?.call(appended.catalog!);
    setState(() {
      _localCatalog = appended.catalog;
      _errors = const <String>[];
      _roleAnimationIds = const <SurfaceVariantRole, String>{};
      _roleSources = const <SurfaceVariantRole, TiledTsxRoleAssignmentMeta>{};
      _surfaceSaveErrors = const <String>[];
      _surfaceSaveWarnings = const <String>[];
      _surfaceSaveNote = null;
      _detectionMessage = null;
      _activeGroupId = null;
      _statusMessage =
          'Import TSX prêt : ${imported.animations.length} animations ajoutées.';
    });
  }

  void _runLocalDetection() {
    final groups = buildTiledTsxDetectedAnimationGroups(
      animations: (_localCatalog ?? widget.catalog).animations,
    );
    setState(() {
      _activeGroupId = groups.isEmpty ? null : groups.first.id;
      _detectionMessage = groups.isEmpty
          ? 'Aucune animation disponible pour la détection locale.'
          : 'Détection locale basique appliquée.';
    });
  }

  void _applyPreparedSuggestions() {
    setState(() {
      _surfaceSaveNote =
          'Aucune suggestion acceptée en attente : validez les suggestions Mistral avant application.';
    });
  }

  void _replaceRoleAssignments(Map<SurfaceVariantRole, String> next) {
    final previous = _roleAnimationIds;
    final nextSources = Map<SurfaceVariantRole, TiledTsxRoleAssignmentMeta>.of(
      _roleSources,
    );
    for (final role in standardSurfaceVariantRoleOrder) {
      final value = next[role];
      if (value == null || value.trim().isEmpty) {
        nextSources.remove(role);
      } else if (previous[role] != value) {
        nextSources[role] = const TiledTsxRoleAssignmentMeta(
          source: TiledTsxRoleAssignmentSource.manual,
        );
      }
    }
    setState(() {
      _roleAnimationIds =
          Map<SurfaceVariantRole, String>.unmodifiable(next);
      _roleSources =
          Map<SurfaceVariantRole, TiledTsxRoleAssignmentMeta>.unmodifiable(
        nextSources,
      );
      _surfaceSaveErrors = const <String>[];
      _surfaceSaveWarnings = const <String>[];
      _surfaceSaveNote = null;
    });
  }

  void _saveReferenceSurface() {
    final catalog = _localCatalog ?? widget.catalog;
    final draft = TiledTsxSurfacePresetDraft(
      id: _nextSurfacePresetId(catalog),
      name: 'Surface TSX',
      categoryId: null,
      sortOrder: catalog.presetCount,
      roleAnimationIds: _roleAnimationIds,
    );
    final validation = validateTiledTsxSurfacePresetDraft(
      draft: draft,
      catalog: catalog,
    );
    if (!validation.canCreate) {
      setState(() {
        _surfaceSaveErrors = validation.errors;
        _surfaceSaveWarnings = validation.warnings;
        _surfaceSaveNote = null;
      });
      return;
    }
    final preset = buildTiledTsxSurfacePresetFromDraft(
      draft: draft,
      catalog: catalog,
    );
    final next = surfaceStudioAppendPresetToWorkCatalog(
      catalog: catalog,
      preset: preset,
    );
    widget.onSurfaceCatalogChanged?.call(next);
    setState(() {
      _localCatalog = next;
      _surfaceSaveErrors = const <String>[];
      _surfaceSaveWarnings = validation.warnings;
      _surfaceSaveNote = 'Surface ${preset.id} ajoutée au catalogue.';
    });
  }

  ProjectTilesetEntry? _pickMatchingTileset(TiledTsxTilesetAudit? audit) {
    if (widget.projectTilesets.isEmpty) {
      return null;
    }
    final imageSource = audit?.summary.imageSource;
    if (imageSource != null && imageSource.isNotEmpty) {
      final expectedBasename = p.basename(imageSource).toLowerCase();
      for (final tileset in widget.projectTilesets) {
        if (p.basename(tileset.relativePath).toLowerCase() ==
            expectedBasename) {
          return tileset;
        }
      }
    }
    return widget.projectTilesets.first;
  }
}

class _ImportSection extends StatelessWidget {
  const _ImportSection({
    required this.loadedFile,
    required this.audit,
    required this.projectTilesets,
    required this.selectedTileset,
    required this.loading,
    required this.statusMessage,
    required this.errors,
    required this.atlasImageBytesAvailable,
    required this.onPickTsx,
    required this.onTilesetChanged,
    required this.onConfirmImport,
  });

  final TiledTsxLoadedFile? loadedFile;
  final TiledTsxTilesetAudit? audit;
  final List<ProjectTilesetEntry> projectTilesets;
  final ProjectTilesetEntry? selectedTileset;
  final bool loading;
  final String? statusMessage;
  final List<String> errors;
  final bool atlasImageBytesAvailable;
  final VoidCallback onPickTsx;
  final ValueChanged<ProjectTilesetEntry?> onTilesetChanged;
  final VoidCallback? onConfirmImport;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final border = EditorChrome.editorIslandRim(context);
    return Container(
      key: const ValueKey('tiled_tsx_workspace.import_section'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Importer un fichier TSX',
                      style: TextStyle(
                        color: label,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Les frames et durées viennent du fichier Tiled. Aucun preset Surface n’est créé à l’import.',
                      style: TextStyle(color: subtle, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                key: const ValueKey('tiled_tsx_workspace.import'),
                onPressed: loading ? null : onPickTsx,
                child:
                    Text(loading ? 'Chargement…' : 'Importer un fichier TSX'),
              ),
            ],
          ),
          if (audit != null) ...[
            const SizedBox(height: 12),
            _TsxSummary(
              audit: audit!,
              loadedFile: loadedFile,
              atlasImageBytesAvailable: atlasImageBytesAvailable,
            ),
            const SizedBox(height: 12),
            _TilesetPicker(
              tilesets: projectTilesets,
              selectedTileset: selectedTileset,
              onChanged: onTilesetChanged,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                key: const ValueKey('tiled_tsx_workspace.confirm_import'),
                onPressed: onConfirmImport,
                child: const Text('Confirmer l’import TSX'),
              ),
            ),
          ],
          if (projectTilesets.isEmpty && audit != null) ...[
            const SizedBox(height: 10),
            const Text(
              'Ajoutez d’abord l’image comme tileset du projet, puis relancez l’import TSX.',
              style: TextStyle(
                color: CupertinoColors.systemOrange,
                fontSize: 12,
              ),
            ),
          ],
          if (statusMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              statusMessage!,
              style: const TextStyle(
                color: CupertinoColors.systemGreen,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (errors.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Erreur import TSX',
              style: TextStyle(
                color: CupertinoColors.systemRed,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            for (final error in errors)
              Text(
                error,
                style: const TextStyle(
                  color: CupertinoColors.systemRed,
                  fontSize: 12,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TsxSummary extends StatelessWidget {
  const _TsxSummary({
    required this.audit,
    required this.loadedFile,
    required this.atlasImageBytesAvailable,
  });

  final TiledTsxTilesetAudit audit;
  final TiledTsxLoadedFile? loadedFile;
  final bool atlasImageBytesAvailable;

  @override
  Widget build(BuildContext context) {
    final s = audit.summary;
    final transparentColor = s.transparentColor;
    final hasTransparentColor =
        transparentColor != null && transparentColor.trim().isNotEmpty;
    final validTransparentColor =
        parseTiledTsxTransparentColor(transparentColor) != null;
    final transparentColorLabel = !hasTransparentColor
        ? 'aucune'
        : validTransparentColor
            ? formatTiledTsxTransparentColor(transparentColor)
            : transparentColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoBlock(
          title: 'Résumé TSX',
          rows: [
            ('Fichier', loadedFile?.fileName ?? 'TSX'),
            ('name', s.name),
            ('tileWidth', '${s.tileWidth}'),
            ('tileHeight', '${s.tileHeight}'),
            ('columns', '${s.columns}'),
            ('tileCount', '${s.tileCount}'),
            ('imageSource', s.imageSource),
            ('imageWidth', '${s.imageWidth}'),
            ('imageHeight', '${s.imageHeight}'),
            ('animations', '${s.animationCount} animations'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Couleur transparente : $transparentColorLabel',
          style: TextStyle(
            color: EditorChrome.primaryLabel(context),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (hasTransparentColor && validTransparentColor) ...[
          const SizedBox(height: 4),
          Text(
            atlasImageBytesAvailable
                ? 'Transparence appliquée aux previews.'
                : 'Transparence prête dès que l’image atlas est disponible.',
            style: const TextStyle(
              color: CupertinoColors.systemGreen,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ] else if (hasTransparentColor) ...[
          const SizedBox(height: 4),
          Text(
            'Couleur transparente TSX invalide : $transparentColor. Les previews utilisent l’image brute.',
            style: const TextStyle(
              color: CupertinoColors.systemOrange,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _TilesetPicker extends StatelessWidget {
  const _TilesetPicker({
    required this.tilesets,
    required this.selectedTileset,
    required this.onChanged,
  });

  final List<ProjectTilesetEntry> tilesets;
  final ProjectTilesetEntry? selectedTileset;
  final ValueChanged<ProjectTilesetEntry?> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    if (tilesets.isEmpty) {
      return Text(
        'Aucun tileset image PokeMap disponible.',
        style: TextStyle(color: subtle, fontSize: 12),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisir le tileset image correspondant',
          style: TextStyle(
            color: label,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          type: MaterialType.transparency,
          child: DropdownButton<ProjectTilesetEntry>(
            key: const ValueKey('tiled_tsx_workspace.tileset_picker'),
            value: selectedTileset,
            isExpanded: true,
            items: [
              for (final tileset in tilesets)
                DropdownMenuItem<ProjectTilesetEntry>(
                  value: tileset,
                  child: Text(
                    '${tileset.name} · ${tileset.id} · ${tileset.relativePath}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _TsxEmptyState extends StatelessWidget {
  const _TsxEmptyState({
    required this.onImportPressed,
  });

  final VoidCallback onImportPressed;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aucune animation TSX importée.',
            style: TextStyle(
              color: label,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Importez un fichier .tsx pour générer des animations Surface depuis un tileset Tiled.',
            style: TextStyle(color: subtle, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            key: const ValueKey('tiled_tsx_workspace.empty_import'),
            onPressed: onImportPressed,
            child: const Text('Importer un fichier TSX'),
          ),
        ],
      ),
    );
  }
}

class _TsxWorkspaceHeader extends StatelessWidget {
  const _TsxWorkspaceHeader({
    required this.label,
    required this.subtle,
  });

  final Color label;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF2DD4BF).withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              CupertinoIcons.square_stack_3d_down_right_fill,
              color: Color(0xFF2DD4BF),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Créer une surface',
                  style: TextStyle(
                    color: label,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Créez des surfaces animées à partir d’atlas TSX en quelques étapes simples.',
                  style: TextStyle(color: subtle, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TsxReferenceActionBar extends StatelessWidget {
  const _TsxReferenceActionBar({
    required this.loading,
    required this.hasAnimations,
    required this.hasMistralKey,
    required this.onImport,
    required this.onDetect,
    required this.onApplySuggestions,
  });

  final bool loading;
  final bool hasAnimations;
  final bool hasMistralKey;
  final VoidCallback onImport;
  final VoidCallback onDetect;
  final VoidCallback onApplySuggestions;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      key: const ValueKey('tiled_tsx_reference.action_bar'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ElevatedButton(
            key: const ValueKey('tiled_tsx_reference.import'),
            onPressed: loading ? null : onImport,
            child: Text(loading ? 'Import en cours…' : 'Importer un TSX'),
          ),
          _ReferenceActionButton(
            key: const ValueKey('tiled_tsx_reference.detect'),
            label: 'Détection auto',
            enabled: hasAnimations,
            onPressed: onDetect,
          ),
          _ReferenceActionButton(
            key: const ValueKey('tiled_tsx_reference.apply_suggestions'),
            label: 'Appliquer les suggestions',
            enabled: hasAnimations,
            onPressed: onApplySuggestions,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF2DD4BF).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF2DD4BF).withValues(alpha: 0.24),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading) ...[
                  const CupertinoActivityIndicator(radius: 6),
                  const SizedBox(width: 7),
                  const Text(
                    'Analyse Mistral en cours…',
                    style: TextStyle(
                      color: Color(0xFF2DD4BF),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ] else
                  Text(
                    hasMistralKey ? 'Assistant IA prêt' : 'Assistant IA optionnel',
                    style: TextStyle(
                      color: hasMistralKey
                          ? const Color(0xFF2DD4BF)
                          : subtle,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceActionButton extends StatelessWidget {
  const _ReferenceActionButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: enabled
          ? const Color(0xFF2563EB).withValues(alpha: 0.20)
          : EditorChrome.islandFillElevated(context),
      borderRadius: BorderRadius.circular(10),
      onPressed: enabled ? onPressed : null,
      child: Text(
        label,
        style: TextStyle(
          color: enabled ? const Color(0xFFA5B4FC) : subtle,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ReferenceTsxSurfaceBuilder extends StatelessWidget {
  const _ReferenceTsxSurfaceBuilder({
    required this.atlas,
    required this.animations,
    required this.atlasImageBytes,
    required this.catalog,
    required this.activeGroupId,
    required this.roleAnimationIds,
    required this.roleSources,
    required this.detectionMessage,
    required this.saveErrors,
    required this.saveWarnings,
    required this.saveNote,
    required this.onGroupSelected,
    required this.onRoleAssignmentsChanged,
    required this.onSaveSurface,
  });

  final ProjectSurfaceAtlas? atlas;
  final List<ProjectSurfaceAnimation> animations;
  final Uint8List? atlasImageBytes;
  final ProjectSurfaceCatalog catalog;
  final String? activeGroupId;
  final Map<SurfaceVariantRole, String> roleAnimationIds;
  final Map<SurfaceVariantRole, TiledTsxRoleAssignmentMeta> roleSources;
  final String? detectionMessage;
  final List<String> saveErrors;
  final List<String> saveWarnings;
  final String? saveNote;
  final ValueChanged<String> onGroupSelected;
  final ValueChanged<Map<SurfaceVariantRole, String>> onRoleAssignmentsChanged;
  final VoidCallback? onSaveSurface;

  @override
  Widget build(BuildContext context) {
    final groups = buildTiledTsxDetectedAnimationGroups(animations: animations);
    final activeGroup = _activeGroup(groups);
    final selectedIds =
        activeGroup?.animationIds.toSet() ?? animations.map((a) => a.id).toSet();
    final canSave =
        onSaveSurface != null && roleAnimationIds.containsKey(SurfaceVariantRole.isolated);

    return Container(
      key: const ValueKey('tiled_tsx_reference_builder.root'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReferenceStepper(
            hasGroups: groups.isNotEmpty,
            hasCenter: roleAnimationIds.containsKey(SurfaceVariantRole.isolated),
            canSave: canSave,
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 1120) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DetectedGroupsColumn(
                      groups: groups,
                      activeGroup: activeGroup,
                      atlas: atlas,
                      animations: animations,
                      atlasImageBytes: atlasImageBytes,
                      detectionMessage: detectionMessage,
                      onGroupSelected: onGroupSelected,
                    ),
                    const SizedBox(height: 10),
                    _RolesColumn(
                      atlas: atlas,
                      animations: animations,
                      atlasImageBytes: atlasImageBytes,
                      selectedIds: selectedIds,
                      roleAnimationIds: roleAnimationIds,
                      roleSources: roleSources,
                      onChanged: onRoleAssignmentsChanged,
                    ),
                    const SizedBox(height: 10),
                    _PreviewAndSaveColumn(
                      atlas: atlas,
                      animations: animations,
                      atlasImageBytes: atlasImageBytes,
                      roleAnimationIds: roleAnimationIds,
                      canSave: canSave,
                      errors: saveErrors,
                      warnings: saveWarnings,
                      note: saveNote,
                      onSaveSurface: onSaveSurface,
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 310,
                    child: _DetectedGroupsColumn(
                      groups: groups,
                      activeGroup: activeGroup,
                      atlas: atlas,
                      animations: animations,
                      atlasImageBytes: atlasImageBytes,
                      detectionMessage: detectionMessage,
                      onGroupSelected: onGroupSelected,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RolesColumn(
                      atlas: atlas,
                      animations: animations,
                      atlasImageBytes: atlasImageBytes,
                      selectedIds: selectedIds,
                      roleAnimationIds: roleAnimationIds,
                      roleSources: roleSources,
                      onChanged: onRoleAssignmentsChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 360,
                    child: _PreviewAndSaveColumn(
                      atlas: atlas,
                      animations: animations,
                      atlasImageBytes: atlasImageBytes,
                      roleAnimationIds: roleAnimationIds,
                      canSave: canSave,
                      errors: saveErrors,
                      warnings: saveWarnings,
                      note: saveNote,
                      onSaveSurface: onSaveSurface,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  TiledTsxDetectedAnimationGroup? _activeGroup(
    List<TiledTsxDetectedAnimationGroup> groups,
  ) {
    for (final group in groups) {
      if (group.id == activeGroupId) {
        return group;
      }
    }
    return groups.isEmpty ? null : groups.first;
  }
}

class _ReferenceStepper extends StatelessWidget {
  const _ReferenceStepper({
    required this.hasGroups,
    required this.hasCenter,
    required this.canSave,
  });

  final bool hasGroups;
  final bool hasCenter;
  final bool canSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('tiled_tsx_reference.stepper'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StepItem(
              number: '1',
              title: '1. Choisir un groupe d’animations',
              subtitle: 'Sélectionnez un groupe détecté',
              complete: hasGroups,
            ),
          ),
          Expanded(
            child: _StepItem(
              number: '2',
              title: '2. Assigner les rôles',
              subtitle: 'Glissez ou choisissez chaque rôle',
              complete: hasCenter,
            ),
          ),
          Expanded(
            child: _StepItem(
              number: '3',
              title: '3. Prévisualiser et enregistrer',
              subtitle: 'Vérifiez et enregistrez votre surface',
              complete: canSave,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.complete,
  });

  final String number;
  final String title;
  final String subtitle;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: complete
                ? const Color(0xFF2DD4BF)
                : const Color(0xFFE2E8F0).withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(
              color: complete ? const Color(0xFF062826) : label,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: label,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: subtle, fontSize: 10.8),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetectedGroupsColumn extends StatelessWidget {
  const _DetectedGroupsColumn({
    required this.groups,
    required this.activeGroup,
    required this.atlas,
    required this.animations,
    required this.atlasImageBytes,
    required this.detectionMessage,
    required this.onGroupSelected,
  });

  final List<TiledTsxDetectedAnimationGroup> groups;
  final TiledTsxDetectedAnimationGroup? activeGroup;
  final ProjectSurfaceAtlas? atlas;
  final List<ProjectSurfaceAnimation> animations;
  final Uint8List? atlasImageBytes;
  final String? detectionMessage;
  final ValueChanged<String> onGroupSelected;

  @override
  Widget build(BuildContext context) {
    return _ReferencePanel(
      title: 'Groupes détectés',
      badge: '${groups.length}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (groups.isEmpty)
            Text(
              'Aucune animation disponible.',
              style: TextStyle(
                color: EditorChrome.subtleLabel(context),
                fontSize: 12,
              ),
            )
          else
            for (final group in groups) ...[
              _DetectedGroupCard(
                group: group,
                active: activeGroup?.id == group.id,
                atlas: atlas,
                animation: _firstAnimationForGroup(group),
                atlasImageBytes: atlasImageBytes,
                onUse: () => onGroupSelected(group.id),
              ),
              if (group != groups.last) const SizedBox(height: 8),
            ],
          if (detectionMessage != null) ...[
            const SizedBox(height: 10),
            _HintBox(text: detectionMessage!),
          ] else ...[
            const SizedBox(height: 10),
            const _HintBox(
              text:
                  'Astuce : sélectionnez un groupe pour limiter le picker aux animations pertinentes.',
            ),
          ],
        ],
      ),
    );
  }

  ProjectSurfaceAnimation? _firstAnimationForGroup(
    TiledTsxDetectedAnimationGroup group,
  ) {
    for (final id in group.animationIds) {
      for (final animation in animations) {
        if (animation.id == id) {
          return animation;
        }
      }
    }
    return null;
  }
}

class _DetectedGroupCard extends StatelessWidget {
  const _DetectedGroupCard({
    required this.group,
    required this.active,
    required this.atlas,
    required this.animation,
    required this.atlasImageBytes,
    required this.onUse,
  });

  final TiledTsxDetectedAnimationGroup group;
  final bool active;
  final ProjectSurfaceAtlas? atlas;
  final ProjectSurfaceAnimation? animation;
  final Uint8List? atlasImageBytes;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      key: ValueKey('tiled_tsx_reference.group.${group.id}'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF2DD4BF).withValues(alpha: 0.12)
            : EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: active
              ? const Color(0xFF2DD4BF).withValues(alpha: 0.55)
              : EditorChrome.editorIslandRim(context),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 54,
            child: animation == null
                ? const _ReferencePreviewFallback()
                : TiledTsxAnimationTilePreview(
                    atlas: atlas,
                    animation: animation!,
                    atlasImageBytes: atlasImageBytes,
                    compact: true,
                  ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: label,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${group.animationIds.length} animations',
                  style: TextStyle(color: subtle, fontSize: 11.2),
                ),
              ],
            ),
          ),
          CupertinoButton(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            onPressed: onUse,
            child: const Text(
              'Utiliser',
              style: TextStyle(
                color: Color(0xFF2DD4BF),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RolesColumn extends StatelessWidget {
  const _RolesColumn({
    required this.atlas,
    required this.animations,
    required this.atlasImageBytes,
    required this.selectedIds,
    required this.roleAnimationIds,
    required this.roleSources,
    required this.onChanged,
  });

  final ProjectSurfaceAtlas? atlas;
  final List<ProjectSurfaceAnimation> animations;
  final Uint8List? atlasImageBytes;
  final Set<String> selectedIds;
  final Map<SurfaceVariantRole, String> roleAnimationIds;
  final Map<SurfaceVariantRole, TiledTsxRoleAssignmentMeta> roleSources;
  final ValueChanged<Map<SurfaceVariantRole, String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return _ReferencePanel(
      title: 'Rôles de surface',
      child: TiledTsxRoleMappingBuilder(
        atlas: atlas,
        animations: animations,
        selectedAnimationIds: selectedIds,
        roleAnimationIds: roleAnimationIds,
        roleSources: roleSources,
        atlasImageBytes: atlasImageBytes,
        onChanged: onChanged,
      ),
    );
  }
}

class _PreviewAndSaveColumn extends StatelessWidget {
  const _PreviewAndSaveColumn({
    required this.atlas,
    required this.animations,
    required this.atlasImageBytes,
    required this.roleAnimationIds,
    required this.canSave,
    required this.errors,
    required this.warnings,
    required this.note,
    required this.onSaveSurface,
  });

  final ProjectSurfaceAtlas? atlas;
  final List<ProjectSurfaceAnimation> animations;
  final Uint8List? atlasImageBytes;
  final Map<SurfaceVariantRole, String> roleAnimationIds;
  final bool canSave;
  final List<String> errors;
  final List<String> warnings;
  final String? note;
  final VoidCallback? onSaveSurface;

  @override
  Widget build(BuildContext context) {
    final center = _animationForRole(SurfaceVariantRole.isolated);
    final edgeCount = [
      SurfaceVariantRole.endNorth,
      SurfaceVariantRole.endEast,
      SurfaceVariantRole.endSouth,
      SurfaceVariantRole.endWest,
    ].where(roleAnimationIds.containsKey).length;
    final cornerCount = [
      SurfaceVariantRole.cornerNW,
      SurfaceVariantRole.cornerNE,
      SurfaceVariantRole.cornerSW,
      SurfaceVariantRole.cornerSE,
    ].where(roleAnimationIds.containsKey).length;
    return _ReferencePanel(
      title: 'Prévisualisation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 190,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF101820),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EditorChrome.editorIslandRim(context)),
            ),
            child: center == null
                ? const Center(
                    child: Text(
                      'Assignez Plein(center) pour voir la preview.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : _PreviewTileMosaic(
                    atlas: atlas,
                    animation: center,
                    atlasImageBytes: atlasImageBytes,
                  ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const _MiniControl(label: 'Play'),
              const SizedBox(width: 8),
              const Expanded(child: _FrameTrack()),
              const SizedBox(width: 8),
              Text(
                'Boucle',
                style: TextStyle(
                  color: EditorChrome.primaryLabel(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'État de la surface',
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          _StatusChecklistRow(
            label: 'Centre',
            value: center == null ? 'Manquant' : 'OK',
            good: center != null,
          ),
          _StatusChecklistRow(
            label: 'Bords',
            value: '$edgeCount / 4 assignés',
            good: edgeCount == 4,
          ),
          _StatusChecklistRow(
            label: 'Coins',
            value: '$cornerCount / 4 assignés',
            good: cornerCount == 4,
          ),
          _StatusChecklistRow(
            label: 'Cohérence',
            value: center == null ? 'À vérifier' : 'Bonne correspondance',
            good: center != null,
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            key: const ValueKey('tiled_tsx_reference_builder.save_surface'),
            onPressed: canSave ? onSaveSurface : null,
            child: const Text('Enregistrer la surface'),
          ),
          const SizedBox(height: 6),
          Text(
            'Enregistrer comme brouillon',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          for (final error in errors) ...[
            const SizedBox(height: 6),
            Text(
              error,
              style: const TextStyle(
                color: CupertinoColors.systemRed,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          for (final warning in warnings) ...[
            const SizedBox(height: 6),
            Text(
              warning,
              style: const TextStyle(
                color: CupertinoColors.systemOrange,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (note != null) ...[
            const SizedBox(height: 6),
            Text(
              note!,
              style: const TextStyle(
                color: Color(0xFF2DD4BF),
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  ProjectSurfaceAnimation? _animationForRole(SurfaceVariantRole role) {
    final id = roleAnimationIds[role];
    if (id == null) {
      return null;
    }
    for (final animation in animations) {
      if (animation.id == id) {
        return animation;
      }
    }
    return null;
  }
}

class _PreviewTileMosaic extends StatelessWidget {
  const _PreviewTileMosaic({
    required this.atlas,
    required this.animation,
    required this.atlasImageBytes,
  });

  final ProjectSurfaceAtlas? atlas;
  final ProjectSurfaceAnimation animation;
  final Uint8List? atlasImageBytes;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      mainAxisSpacing: 3,
      crossAxisSpacing: 3,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < 16; i++)
          TiledTsxAnimationTilePreview(
            atlas: atlas,
            animation: animation,
            atlasImageBytes: atlasImageBytes,
            compact: true,
          ),
      ],
    );
  }
}

class _ReferencePanel extends StatelessWidget {
  const _ReferencePanel({
    required this.title,
    required this.child,
    this.badge,
  });

  final String title;
  final String? badge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: EditorChrome.primaryLabel(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2DD4BF).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Color(0xFF2DD4BF),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _HintBox extends StatelessWidget {
  const _HintBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF2DD4BF).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: EditorChrome.subtleLabel(context),
          fontSize: 11.5,
          height: 1.3,
        ),
      ),
    );
  }
}

class _ReferencePreviewFallback extends StatelessWidget {
  const _ReferencePreviewFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101820),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
      ),
      child: const Center(
        child: Text(
          'Preview',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MiniControl extends StatelessWidget {
  const _MiniControl({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF2DD4BF),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF062826),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FrameTrack extends StatelessWidget {
  const _FrameTrack();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: EditorChrome.editorIslandRim(context),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 0.35,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2DD4BF),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _StatusChecklistRow extends StatelessWidget {
  const _StatusChecklistRow({
    required this.label,
    required this.value,
    required this.good,
  });

  final String label;
  final String value;
  final bool good;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(
            good ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.info,
            color:
                good ? CupertinoColors.systemGreen : CupertinoColors.systemOrange,
            size: 15,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: EditorChrome.primaryLabel(context),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: good
                  ? CupertinoColors.systemGreen.resolveFrom(context)
                  : EditorChrome.subtleLabel(context),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

enum TiledTsxDetectedAnimationGroupKind {
  heuristic,
  selection,
}

final class TiledTsxDetectedAnimationGroup {
  const TiledTsxDetectedAnimationGroup({
    required this.id,
    required this.label,
    required this.animationIds,
    required this.kind,
    required this.confidence,
  });

  final String id;
  final String label;
  final List<String> animationIds;
  final TiledTsxDetectedAnimationGroupKind kind;
  final double confidence;
}

List<TiledTsxDetectedAnimationGroup> buildTiledTsxDetectedAnimationGroups({
  required List<ProjectSurfaceAnimation> animations,
}) {
  if (animations.isEmpty) {
    return const <TiledTsxDetectedAnimationGroup>[];
  }
  final items = buildTiledTsxAnimationBrowserItems(animations: animations);
  final sorted = [...items]..sort((a, b) => a.baseTileId.compareTo(b.baseTileId));
  final groupSize = sorted.length <= 40 ? sorted.length : 40;
  final groups = <TiledTsxDetectedAnimationGroup>[];
  for (var start = 0; start < sorted.length; start += groupSize) {
    final slice = sorted.skip(start).take(groupSize).toList(growable: false);
    final number = groups.length + 1;
    groups.add(
      TiledTsxDetectedAnimationGroup(
        id: 'group-$number',
        label: 'Groupe détecté $number',
        animationIds:
            List<String>.unmodifiable(slice.map((item) => item.animationId)),
        kind: TiledTsxDetectedAnimationGroupKind.heuristic,
        confidence: 0.5,
      ),
    );
  }
  return List<TiledTsxDetectedAnimationGroup>.unmodifiable(groups);
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: label,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      row.$1,
                      style: TextStyle(color: subtle, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: TextStyle(color: label, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

ProjectSurfaceAtlas? _atlasForBrowser(ProjectSurfaceCatalog catalog) {
  for (final animation in catalog.animations) {
    final frames = animation.timeline.frames;
    if (frames.isEmpty) {
      continue;
    }
    final atlas = catalog.atlasById(frames.first.tileRef.atlasId);
    if (atlas != null) {
      return atlas;
    }
  }
  return catalog.atlases.isEmpty ? null : catalog.atlases.first;
}

String _slugify(String value) {
  final lower = value.trim().toLowerCase();
  final slug = lower
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'tsx-import' : slug;
}

String _nextSurfacePresetId(ProjectSurfaceCatalog catalog) {
  var index = catalog.presetCount;
  while (true) {
    final id = 'tsx-surface-$index';
    if (!catalog.containsPreset(id)) {
      return id;
    }
    index++;
  }
}
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart

```dart
// Surface Studio — assistant premium de mapping d'atlas.
//
// Le viewport principal porte un seul workflow guide moderne. Les anciennes
// briques utiles restent accessibles dans le drawer avance, sans second
// Surface Studio rendu sous l'assistant.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'importers/tall_grass_tsx_asset_importer.dart';
import 'importers/tiled_tsx_animation_browser.dart';
import 'importers/tiled_tsx_workspace.dart';
import 'surface_studio_atlas_editing.dart';
import 'surface_studio_atlas_image_preview.dart';
import 'surface_studio_catalog_browser.dart';
import 'surface_studio_diagnostics_view.dart';
import 'surface_studio_paintable_surfaces_panel.dart';
import 'surface_studio_preset_editor_controller.dart';
import 'surface_studio_ai_mapping_suggester.dart';
import 'surface_studio_role_mapping_editor.dart';
import 'surface_studio_selection.dart';
import 'surface_studio_selection_inspector.dart';
import 'surface_studio_selection_summary.dart';
import 'surface_studio_screen.dart';

SurfaceStudioSelection _selectionValidInReadModel(
  SurfaceStudioReadModel rm,
  SurfaceStudioSelection sel,
) {
  if (sel.isNone) return sel;
  if (sel.isAtlas) {
    for (final row in rm.atlases) {
      if (row.id == sel.id) return sel;
    }
  } else if (sel.isAnimation) {
    for (final row in rm.animations) {
      if (row.id == sel.id) return sel;
    }
  } else if (sel.isPreset) {
    for (final row in rm.presets) {
      if (row.id == sel.id) return sel;
    }
  }
  return const SurfaceStudioSelection.none();
}

/// Accent produit Surface Studio (même base que la tuile World Explorer).
const Color _surfaceStudioAccent = Color(0xFF2DD4BF);

enum _SurfaceStudioPrimaryWorkspace {
  catalogue,
  tallGrass,
  tsx,
  diagnostics,
}

typedef TallGrassTsxImportRequested = Future<TallGrassTsxAssetImportResult>
    Function({
  required TiledTsxLoadedFile loadedFile,
  required ProjectSurfaceCatalog workCatalog,
});

/// Panneau présentationnel **lecture seule** pour Surface Studio.
class SurfaceStudioPanel extends StatefulWidget {
  const SurfaceStudioPanel({
    super.key,
    required this.readModel,
    this.onSurfaceCatalogSaveRequested,
    this.onRequestProjectSave,
    this.projectTilesets,
    this.projectRootPath,
    this.projectSettings,
    this.surfaceMappingImageLoader,
    this.aiMappingSuggester,
    this.tallGrassAuthoringView,
    this.onTallGrassTsxImportRequested,
    this.tsxFileLoader = const TiledTsxPlatformFileLoader(),
  });

  final SurfaceStudioReadModel readModel;
  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogSaveRequested;
  final Future<bool> Function()? onRequestProjectSave;
  final List<ProjectTilesetEntry>? projectTilesets;
  final ProjectSettings? projectSettings;
  final SurfaceStudioAtlasUiImageLoader? surfaceMappingImageLoader;
  final SurfaceStudioAiMappingSuggester? aiMappingSuggester;
  final TallGrassAuthoringView? tallGrassAuthoringView;
  final TallGrassTsxImportRequested? onTallGrassTsxImportRequested;
  final TiledTsxFileLoader tsxFileLoader;

  /// Racine projet sur disque pour résoudre les chemins d’images tileset (aperçu Lot 72).
  final String? projectRootPath;

  static const String titleText = 'Surface Studio';
  static const String readOnlyBadgeText = 'Lecture seule';
  static const String partialAuthoringBadgeText = 'Édition partielle';
  static const String workflowStepsHintText =
      'Étapes : atlas → grille → animations → surfaces prêtes à peindre';
  static const String productDescriptionText =
      'Créer des surfaces peintes à partir d’un atlas, étape par étape.';
  static const String placeholderActionsTitle = 'Actions auteur';
  static const String placeholderSoonText = 'Bientôt';
  static const String actionImportVerticalAtlasLabel =
      'Importer un atlas vertical';
  static const String workCatalogDirtyStateText =
      'Catalogue de travail modifié — sauvegarde projet non effectuée.';
  static const String savePrepActionLabel =
      'Préparer la sauvegarde du catalogue Surface';
  static const String savePrepTransmittedNote =
      'Catalogue de travail transmis au parent.';
  static const String savePrepNotConnectedNote =
      'Sauvegarde non connectée dans ce contexte.';
  static const String savePrepNoDiskNote =
      'Aucune écriture disque ne sera effectuée par Surface Studio.';
  static const String manifestMemoryUpdatedNote =
      'Manifest projet mis à jour en mémoire — écriture disque non effectuée.';
  static const String projectSaveViaExistingFlowButtonLabel =
      'Sauvegarder le projet via le flux existant';
  static const String projectDiskSaveResultSuccessNote =
      'Projet sauvegardé via le flux projet existant.';
  static const String projectDiskSaveRequestedNote =
      'Sauvegarde projet demandée.';
  static const String projectDiskSaveFailureNote =
      'Échec de sauvegarde projet — voir la barre d’état.';

  @override
  State<SurfaceStudioPanel> createState() => _SurfaceStudioPanelState();
}

class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
  /// Sélection d’inspection : locale au widget, jamais écrite dans le manifest.
  SurfaceStudioSelection _selection = const SurfaceStudioSelection.none();
  _SurfaceStudioPrimaryWorkspace _primaryWorkspace =
      _SurfaceStudioPrimaryWorkspace.catalogue;
  late SurfaceStudioReadModel _workReadModel;
  String? _saveFlowPrepNote;
  String? _projectSaveDiskNote;
  int _atlasEditSignal = 0;
  String? _tsxBrowserImagePath;
  Uint8List? _tsxBrowserImageBytes;

  @override
  void initState() {
    super.initState();
    _workReadModel = widget.readModel;
  }

  @override
  void didUpdateWidget(covariant SurfaceStudioPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.readModel != oldWidget.readModel) {
      final hadDirty = _workReadModel != oldWidget.readModel;
      final absNow = widget.readModel ==
          buildSurfaceStudioReadModelFromCatalog(_workReadModel.catalog);
      final wasAbsorbed = hadDirty && absNow;
      setState(() {
        _workReadModel = widget.readModel;
        _selection = _selectionValidInReadModel(_workReadModel, _selection);
        _saveFlowPrepNote =
            wasAbsorbed ? SurfaceStudioPanel.manifestMemoryUpdatedNote : null;
      });
    }
  }

  bool get _hasWorkCatalogChanges => _workReadModel != widget.readModel;

  void _bumpAtlasEditSignal() {
    setState(() => _atlasEditSignal += 1);
  }

  void _onConfirmDeleteSelectedAtlas() {
    final id = _selection.id;
    if (id == null || !_selection.isAtlas) {
      return;
    }
    try {
      final next = removeAtlasIdFromWorkCatalog(_workReadModel.catalog, id);
      setState(() {
        _saveFlowPrepNote = null;
        _workReadModel = buildSurfaceStudioReadModelFromCatalog(next);
        _selection = const SurfaceStudioSelection.none();
      });
    } on StateError {
      return;
    }
  }

  SurfaceStudioSelection _selectionAfterCatalogChanged(
    ProjectSurfaceCatalog cat,
  ) {
    if (_selection.isAtlas) {
      final sid = _selection.id;
      if (sid != null) {
        for (final a in cat.atlases) {
          if (a.id == sid) {
            return SurfaceStudioSelection.atlas(sid);
          }
        }
        return const SurfaceStudioSelection.none();
      }
    }
    if (_selection.isAnimation) {
      final sid = _selection.id;
      if (sid != null) {
        for (final a in cat.animations) {
          if (a.id == sid) {
            return SurfaceStudioSelection.animation(sid);
          }
        }
        return const SurfaceStudioSelection.none();
      }
    }
    if (_selection.isPreset) {
      final sid = _selection.id;
      if (sid != null) {
        for (final p in cat.presets) {
          if (p.id == sid) {
            return SurfaceStudioSelection.preset(sid);
          }
        }
        return const SurfaceStudioSelection.none();
      }
    }
    if (cat.atlases.isNotEmpty) {
      return SurfaceStudioSelection.atlas(cat.atlases.last.id);
    }
    return const SurfaceStudioSelection.none();
  }

  void _onSurfaceCatalogSavePrep() {
    final cb = widget.onSurfaceCatalogSaveRequested;
    if (cb == null) {
      return;
    }
    cb(_workReadModel.catalog);
    setState(() {
      _saveFlowPrepNote = SurfaceStudioPanel.savePrepTransmittedNote;
    });
  }

  Future<void> _onRequestProjectSave() async {
    final fn = widget.onRequestProjectSave;
    if (fn == null) {
      return;
    }
    setState(() {
      _projectSaveDiskNote = SurfaceStudioPanel.projectDiskSaveRequestedNote;
    });
    final ok = await fn();
    if (!mounted) {
      return;
    }
    setState(() {
      _projectSaveDiskNote = ok
          ? SurfaceStudioPanel.projectDiskSaveResultSuccessNote
          : SurfaceStudioPanel.projectDiskSaveFailureNote;
    });
  }

  ProjectSurfacePreset? _selectedWorkPreset() {
    final id = _selection.id;
    if (id == null || !_selection.isPreset) {
      return null;
    }
    return _workReadModel.catalog.presetById(id);
  }

  void _selectPreset(String presetId) {
    setState(() {
      _selection = SurfaceStudioSelection.preset(presetId);
    });
  }

  void _onPresetRoleAnimationChanged(
    SurfaceVariantRole role,
    String animationId,
  ) {
    final presetId = _selection.id;
    if (presetId == null || !_selection.isPreset) {
      return;
    }
    final next = surfaceStudioReplacePresetRoleAnimation(
      catalog: _workReadModel.catalog,
      presetId: presetId,
      role: role,
      animationId: animationId,
    );
    setState(() {
      _saveFlowPrepNote = null;
      _workReadModel = buildSurfaceStudioReadModelFromCatalog(next);
      _selection = SurfaceStudioSelection.preset(presetId);
    });
  }

  Future<void> _openPresetMappingEditor(String presetId) async {
    final preset = _workReadModel.catalog.presetById(presetId);
    if (preset == null) {
      return;
    }
    setState(() {
      _selection = SurfaceStudioSelection.preset(presetId);
    });
    await showMacosSheet<void>(
      context: context,
      builder: (ctx) => Center(
        child: MacosSheet(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              key: const ValueKey('surface_mapping_editor_sheet'),
              width: 1120,
              height: 760,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Surface Mapping Editor',
                          style: editorMacosSheetTitleStyle(ctx),
                        ),
                      ),
                      PushButton(
                        key: const ValueKey('surface_mapping_editor_close'),
                        controlSize: ControlSize.large,
                        secondary: true,
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Fermer'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Étape 1 : choisissez un slot visuel. Étape 2 : cliquez directement une colonne dans l’atlas réel.',
                    style: TextStyle(
                      color: _surfaceStudioAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SurfaceStudioRoleMappingEditor(
                        catalog: _workReadModel.catalog,
                        preset: preset,
                        projectRootPath: widget.projectRootPath,
                        projectTilesets: widget.projectTilesets ??
                            const <ProjectTilesetEntry>[],
                        imageLoader: widget.surfaceMappingImageLoader,
                        onRoleAnimationChanged: _onPresetRoleAnimationChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSurfaceCatalogChanged(ProjectSurfaceCatalog cat) {
    setState(() {
      _saveFlowPrepNote = null;
      _workReadModel = buildSurfaceStudioReadModelFromCatalog(cat);
      _selection = _selectionAfterCatalogChanged(cat);
    });
  }

  Future<TallGrassTsxAssetImportResult> _onTallGrassTsxImportRequested(
    TiledTsxLoadedFile loadedFile,
  ) async {
    final requested = widget.onTallGrassTsxImportRequested;
    if (requested == null) {
      return TallGrassTsxAssetImportResult(
        manifest: null,
        errors: const ['Import manifest non connecté dans ce contexte.'],
        messages: const <String>[],
        createdTileset: false,
        tileset: null,
        importedAnimationCount: 0,
        candidateAnimationIds: const <String>[],
        visualCandidateTileIds: const <int>[],
        sdkParticleTags: const <int>[],
        loadedFileName: loadedFile.fileName,
      );
    }
    final result = await requested(
      loadedFile: loadedFile,
      workCatalog: _workReadModel.catalog,
    );
    final next = result.manifest;
    if (!result.hasErrors && next != null && mounted) {
      setState(() {
        _saveFlowPrepNote = SurfaceStudioPanel.manifestMemoryUpdatedNote;
        _workReadModel = buildSurfaceStudioReadModelFromCatalog(
          next.surfaceCatalog,
        );
        _selection = _selectionAfterCatalogChanged(next.surfaceCatalog);
      });
    }
    return result;
  }

  ProjectSurfaceAtlas? _atlasForAnimationBrowser() {
    for (final animation in _workReadModel.catalog.animations) {
      final frames = animation.timeline.frames;
      if (frames.isEmpty) {
        continue;
      }
      final atlas = _workReadModel.catalog.atlasById(
        frames.first.tileRef.atlasId,
      );
      if (atlas != null) {
        return atlas;
      }
    }
    return _workReadModel.catalog.atlases.isEmpty
        ? null
        : _workReadModel.catalog.atlases.first;
  }

  Uint8List? _atlasImageBytesForBrowser(ProjectSurfaceAtlas? atlas) {
    if (atlas == null) {
      _tsxBrowserImagePath = null;
      _tsxBrowserImageBytes = null;
      return null;
    }
    final resolution = resolveSurfaceStudioAtlasImagePreview(
      projectRootPath: widget.projectRootPath,
      projectTilesets: widget.projectTilesets ?? const <ProjectTilesetEntry>[],
      technicalTilesetId: atlas.tilesetId,
    );
    final path = resolution.resolvedAbsolutePath;
    if (path == null || path.isEmpty) {
      _tsxBrowserImagePath = null;
      _tsxBrowserImageBytes = null;
      return null;
    }
    if (_tsxBrowserImagePath == path && _tsxBrowserImageBytes != null) {
      return _tsxBrowserImageBytes;
    }
    try {
      final bytes = File(path).readAsBytesSync();
      _tsxBrowserImagePath = path;
      _tsxBrowserImageBytes = bytes;
      return bytes;
    } catch (_) {
      _tsxBrowserImagePath = path;
      _tsxBrowserImageBytes = null;
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canMutateCatalog = widget.onSurfaceCatalogSaveRequested != null;
    final inspection = Column(
      key: const ValueKey('surface_studio_inspection_column'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SurfaceStudioSelectionSummary(selection: _selection),
        const SizedBox(height: 10),
        SurfaceStudioSelectionInspector(
          readModel: _workReadModel,
          selection: _selection,
          onRequestEditSelectedAtlas:
              canMutateCatalog ? _bumpAtlasEditSignal : null,
          onConfirmDeleteSelectedAtlas:
              canMutateCatalog ? _onConfirmDeleteSelectedAtlas : null,
        ),
      ],
    );
    final selectedPreset = _selectedWorkPreset();
    final paintableSurfaces = SurfaceStudioPaintableSurfacesPanel(
      readModel: _workReadModel,
      selectedPresetId: selectedPreset?.id,
      onPresetSelected: _selectPreset,
      onEditMappingPressed: canMutateCatalog ? _openPresetMappingEditor : null,
      onSaveCatalogPressed: widget.onSurfaceCatalogSaveRequested != null
          ? _onSurfaceCatalogSavePrep
          : null,
    );
    final tsxBrowserAtlas = _atlasForAnimationBrowser();
    Widget buildAdvancedDetails() {
      return _AdvancedDetailsSection(
        inspection: inspection,
        browser: SurfaceStudioCatalogBrowser(
          readModel: _workReadModel,
          selection: _selection,
          onSelectionChanged: (v) {
            setState(() => _selection = v);
          },
        ),
        tsxAnimations: TiledTsxAnimationBrowser(
          atlas: tsxBrowserAtlas,
          animations: _workReadModel.catalog.animations,
          atlasImageBytes: _atlasImageBytesForBrowser(tsxBrowserAtlas),
          sourceLabel: 'Catalogue de travail',
          catalog: _workReadModel.catalog,
          projectSettings: widget.projectSettings,
          onSurfaceCatalogChanged: _onSurfaceCatalogChanged,
        ),
        diagnostics: SurfaceStudioDiagnosticsView(readModel: _workReadModel),
        futureActions: paintableSurfaces,
        placeholder: const _SectionPlaceholder(
          title: SurfaceStudioPanel.placeholderActionsTitle,
        ),
      );
    }

    final advancedDrawer = SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: buildAdvancedDetails(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final shellWidth =
            constraints.hasBoundedWidth ? constraints.maxWidth : 1600.0;
        final shellHeight =
            constraints.hasBoundedHeight ? constraints.maxHeight : 900.0;
        final tsxWorkspaceAtlas = _atlasForAnimationBrowser();
        final content = switch (_primaryWorkspace) {
          _SurfaceStudioPrimaryWorkspace.catalogue => SurfaceStudioScreen(
              readModel: _workReadModel,
              projectSettings: widget.projectSettings,
              projectTilesets: widget.projectTilesets ?? const [],
              projectRootPath: widget.projectRootPath,
              surfaceMappingImageLoader: widget.surfaceMappingImageLoader,
              hasWorkCatalogChanges: _hasWorkCatalogChanges,
              saveFlowPrepNote: _saveFlowPrepNote,
              projectSaveDiskNote: _projectSaveDiskNote,
              onSurfaceCatalogChanged: _onSurfaceCatalogChanged,
              onWorkCatalogAnimationsCreated: (createdIds) {
                if (createdIds.isEmpty) {
                  return;
                }
                setState(() {
                  _selection =
                      SurfaceStudioSelection.animation(createdIds.first);
                });
              },
              onWorkCatalogPresetCreated: (presetId) {
                if (presetId.isEmpty) {
                  return;
                }
                setState(() {
                  _selection = SurfaceStudioSelection.preset(presetId);
                });
              },
              onResetWorkCatalog: () {
                setState(() {
                  _workReadModel = widget.readModel;
                  _selection =
                      _selectionValidInReadModel(_workReadModel, _selection);
                  _saveFlowPrepNote = null;
                });
              },
              onSurfaceCatalogSavePrep:
                  widget.onSurfaceCatalogSaveRequested == null
                      ? null
                      : _onSurfaceCatalogSavePrep,
              onRequestProjectSave: widget.onRequestProjectSave == null
                  ? null
                  : _onRequestProjectSave,
              advancedDrawer: advancedDrawer,
              aiMappingSuggester: widget.aiMappingSuggester,
            ),
          _SurfaceStudioPrimaryWorkspace.tallGrass => _TallGrassStudioPanel(
              view: widget.tallGrassAuthoringView,
              tsxFileLoader: widget.tsxFileLoader,
              onTsxImportRequested: widget.onTallGrassTsxImportRequested == null
                  ? null
                  : _onTallGrassTsxImportRequested,
            ),
          _SurfaceStudioPrimaryWorkspace.tsx => TiledTsxWorkspace(
              catalog: _workReadModel.catalog,
              projectTilesets: widget.projectTilesets ?? const [],
              onSurfaceCatalogChanged: _onSurfaceCatalogChanged,
              fileLoader: widget.tsxFileLoader,
              atlasImageBytes: _atlasImageBytesForBrowser(tsxWorkspaceAtlas),
              projectSettings: widget.projectSettings,
            ),
          _SurfaceStudioPrimaryWorkspace.diagnostics => SingleChildScrollView(
              key: const ValueKey('surface_studio.diagnostics_workspace'),
              padding: const EdgeInsets.all(14),
              child: buildAdvancedDetails(),
            ),
        };
        return SizedBox(
          width: shellWidth,
          height: shellHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SurfaceStudioPrimaryTabs(
                selected: _primaryWorkspace,
                onSelected: (workspace) {
                  setState(() => _primaryWorkspace = workspace);
                },
              ),
              Expanded(child: content),
            ],
          ),
        );
      },
    );
  }
}

class _SurfaceStudioPrimaryTabs extends StatelessWidget {
  const _SurfaceStudioPrimaryTabs({
    required this.selected,
    required this.onSelected,
  });

  final _SurfaceStudioPrimaryWorkspace selected;
  final ValueChanged<_SurfaceStudioPrimaryWorkspace> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('surface_studio.primary_tabs'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: EditorChrome.appBackground(context),
      child: Row(
        children: [
          _SurfaceStudioPrimaryTabButton(
            key: const ValueKey('surface_studio.tab.catalogue'),
            label: 'Catalogue',
            selected: selected == _SurfaceStudioPrimaryWorkspace.catalogue,
            onPressed: () =>
                onSelected(_SurfaceStudioPrimaryWorkspace.catalogue),
          ),
          const SizedBox(width: 8),
          _SurfaceStudioPrimaryTabButton(
            key: const ValueKey('surface_studio.tab.tall_grass'),
            label: 'Hautes herbes',
            selected: selected == _SurfaceStudioPrimaryWorkspace.tallGrass,
            onPressed: () =>
                onSelected(_SurfaceStudioPrimaryWorkspace.tallGrass),
          ),
          const SizedBox(width: 8),
          _SurfaceStudioPrimaryTabButton(
            key: const ValueKey('surface_studio.tab.tsx'),
            label: 'Créer une surface',
            selected: selected == _SurfaceStudioPrimaryWorkspace.tsx,
            onPressed: () => onSelected(_SurfaceStudioPrimaryWorkspace.tsx),
          ),
          const SizedBox(width: 8),
          _SurfaceStudioPrimaryTabButton(
            key: const ValueKey('surface_studio.tab.diagnostics'),
            label: 'Diagnostics',
            selected: selected == _SurfaceStudioPrimaryWorkspace.diagnostics,
            onPressed: () =>
                onSelected(_SurfaceStudioPrimaryWorkspace.diagnostics),
          ),
        ],
      ),
    );
  }
}

class _SurfaceStudioPrimaryTabButton extends StatelessWidget {
  const _SurfaceStudioPrimaryTabButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? _surfaceStudioAccent.withValues(alpha: 0.2)
        : EditorChrome.elevatedPanelBackground(context);
    final textColor =
        selected ? _surfaceStudioAccent : EditorChrome.primaryLabel(context);
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: color,
      borderRadius: BorderRadius.circular(9),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _TallGrassStudioPanel extends StatelessWidget {
  const _TallGrassStudioPanel({
    this.view,
    required this.tsxFileLoader,
    required this.onTsxImportRequested,
  });

  final TallGrassAuthoringView? view;
  final TiledTsxFileLoader tsxFileLoader;
  final Future<TallGrassTsxAssetImportResult> Function(
    TiledTsxLoadedFile loadedFile,
  )? onTsxImportRequested;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      key: const ValueKey('surfaceStudio.tallGrass.panel'),
      decoration:
          BoxDecoration(color: EditorChrome.scaffoldBackground(context)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StudioCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        EditorChrome.elevatedPanelBackground(context),
                        _surfaceStudioAccent,
                        0.24,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const MacosIcon(
                      CupertinoIcons.leaf_arrow_circlepath,
                      color: _surfaceStudioAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hautes herbes',
                          style: TextStyle(
                            color: label,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Terrain spécial traversable avec rencontres, overlay joueur et bruissement local.',
                          style: TextStyle(
                            color: subtle,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  const _TallGrassCapabilityCard(
                    title: 'Visuel',
                    value: 'Preset terrain + overlay',
                    icon: CupertinoIcons.square_stack_3d_down_right,
                  ),
                  const _TallGrassCapabilityCard(
                    title: 'Comportement',
                    value: 'Rencontres en marchant',
                    icon: CupertinoIcons.arrow_right_circle,
                  ),
                  const _TallGrassCapabilityCard(
                    title: 'Animation locale',
                    value: 'Bruissement au pas',
                    icon: CupertinoIcons.waveform_path_ecg,
                  ),
                  const _TallGrassCapabilityCard(
                    title: 'Overlay joueur',
                    value: 'Masque bas du sprite',
                    icon: CupertinoIcons.person_crop_square,
                  ),
                ];
                if (constraints.maxWidth >= 980) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final card in cards) ...[
                        Expanded(child: card),
                        if (card != cards.last) const SizedBox(width: 12),
                      ],
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final card in cards) ...[
                      card,
                      if (card != cards.last) const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            _TallGrassProjectSignalsCard(view: view),
            const SizedBox(height: 12),
            _TallGrassTsxImportCard(
              tsxFileLoader: tsxFileLoader,
              onTsxImportRequested: onTsxImportRequested,
            ),
          ],
        ),
      ),
    );
  }
}

class _TallGrassCapabilityCard extends StatelessWidget {
  const _TallGrassCapabilityCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return _StudioCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MacosIcon(icon, size: 18, color: _surfaceStudioAccent),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: subtle,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: label,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TallGrassTsxImportCard extends StatefulWidget {
  const _TallGrassTsxImportCard({
    required this.tsxFileLoader,
    required this.onTsxImportRequested,
  });

  final TiledTsxFileLoader tsxFileLoader;
  final Future<TallGrassTsxAssetImportResult> Function(
    TiledTsxLoadedFile loadedFile,
  )? onTsxImportRequested;

  @override
  State<_TallGrassTsxImportCard> createState() =>
      _TallGrassTsxImportCardState();
}

class _TallGrassTsxImportCardState extends State<_TallGrassTsxImportCard> {
  bool _loading = false;
  String? _loadedFileName;
  List<String> _messages = const <String>[];
  List<String> _errors = const <String>[];

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final canImport = widget.onTsxImportRequested != null && !_loading;

    return _StudioCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Import assets',
            style: TextStyle(
              color: label,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Importer un TSX hautes herbes pour lier son image tileset au projet, extraire les tuiles candidates et préparer les particules locales.',
            style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: CupertinoButton(
              key: const ValueKey('surfaceStudio.tallGrass.importTsx'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              color: canImport
                  ? _surfaceStudioAccent.withValues(alpha: 0.22)
                  : EditorChrome.elevatedPanelBackground(context),
              borderRadius: BorderRadius.circular(9),
              onPressed: canImport ? _pickAndImportTsx : null,
              child: Text(
                _loading
                    ? 'Import en cours...'
                    : 'Importer un TSX hautes herbes',
                style: TextStyle(
                  color: canImport
                      ? _surfaceStudioAccent
                      : subtle.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          if (widget.onTsxImportRequested == null) ...[
            const SizedBox(height: 10),
            Text(
              'Import manifest non connecté dans ce contexte.',
              style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
            ),
          ],
          if (_loadedFileName != null) ...[
            const SizedBox(height: 10),
            Text(
              'Fichier : $_loadedFileName',
              style: TextStyle(
                color: subtle,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (_messages.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final message in _messages) ...[
              Text(
                message,
                style: TextStyle(
                  color: label,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              if (message != _messages.last) const SizedBox(height: 6),
            ],
          ],
          if (_errors.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Import hautes herbes bloqué',
              style: TextStyle(
                color: CupertinoColors.systemRed.resolveFrom(context),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            for (final error in _errors) ...[
              Text(
                error,
                style: TextStyle(
                  color: CupertinoColors.systemRed.resolveFrom(context),
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
              if (error != _errors.last) const SizedBox(height: 5),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _pickAndImportTsx() async {
    final importRequested = widget.onTsxImportRequested;
    if (importRequested == null) {
      return;
    }
    setState(() {
      _loading = true;
      _messages = const <String>[];
      _errors = const <String>[];
    });
    try {
      final loaded = await widget.tsxFileLoader.pickAndLoadTsx();
      if (!mounted) {
        return;
      }
      if (loaded == null) {
        setState(() {
          _loading = false;
          _loadedFileName = null;
          _messages = const ['Import TSX annulé.'];
          _errors = const <String>[];
        });
        return;
      }
      final result = await importRequested(loaded);
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadedFileName = result.loadedFileName;
        _messages = result.hasErrors ? const <String>[] : result.messages;
        _errors = result.errors;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _messages = const <String>[];
        _errors = ['Échec import TSX hautes herbes.', '$error'];
      });
    }
  }
}

class _TallGrassProjectSignalsCard extends StatelessWidget {
  const _TallGrassProjectSignalsCard({required this.view});

  final TallGrassAuthoringView? view;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final grassTerrainCount = view?.grassTerrainPresets.length ?? 0;
    final tallGrassPathCount = view?.tallGrassPathPresets.length ?? 0;
    final walkTableCount = view?.walkEncounterTables.length ?? 0;
    final walkZoneCount = view?.walkEncounterZones.length ?? 0;
    final readinessItems =
        view?.readinessItems ?? _emptyTallGrassReadinessItems;

    return _StudioCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Signaux projet',
            style: TextStyle(
              color: label,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lecture des presets et rencontres existants, sans nouveau modèle Surface.',
            style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          _TallGrassSignalRow(
            label: 'Terrain herbe',
            value:
                _tallGrassCountLabel(grassTerrainCount, 'terrain', 'terrains'),
          ),
          const SizedBox(height: 8),
          _TallGrassSignalRow(
            label: 'Chemins hautes herbes',
            value:
                _tallGrassCountLabel(tallGrassPathCount, 'chemin', 'chemins'),
          ),
          const SizedBox(height: 8),
          _TallGrassSignalRow(
            label: 'Tables rencontres walk',
            value: _tallGrassCountLabel(walkTableCount, 'table', 'tables'),
          ),
          const SizedBox(height: 8),
          _TallGrassSignalRow(
            label: 'Zones rencontres walk',
            value: _tallGrassCountLabel(walkZoneCount, 'zone', 'zones'),
          ),
          const SizedBox(height: 14),
          Text(
            'Préparation',
            style: TextStyle(
              color: label,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in readinessItems) ...[
            _TallGrassSignalRow(
              label: _tallGrassReadinessLabel(item.id),
              value: _tallGrassReadinessStatus(item),
            ),
            if (item != readinessItems.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _TallGrassSignalRow extends StatelessWidget {
  const _TallGrassSignalRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final primary = EditorChrome.primaryLabel(context);
    final secondary = EditorChrome.subtleLabel(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: secondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: primary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

String _tallGrassCountLabel(int count, String singular, String plural) {
  return '$count ${count <= 1 ? singular : plural}';
}

const _emptyTallGrassReadinessItems = [
  TallGrassAuthoringReadinessItem(
    id: TallGrassAuthoringReadinessItem.visualCandidateId,
    isSatisfied: false,
  ),
  TallGrassAuthoringReadinessItem(
    id: TallGrassAuthoringReadinessItem.walkEncounterTableId,
    isSatisfied: false,
  ),
  TallGrassAuthoringReadinessItem(
    id: TallGrassAuthoringReadinessItem.mappedWalkEncounterZoneId,
    isSatisfied: false,
  ),
];

String _tallGrassReadinessLabel(String id) {
  return switch (id) {
    TallGrassAuthoringReadinessItem.visualCandidateId => 'Visuel hautes herbes',
    TallGrassAuthoringReadinessItem.walkEncounterTableId =>
      'Table rencontres walk',
    TallGrassAuthoringReadinessItem.mappedWalkEncounterZoneId =>
      'Zones walk posées',
    _ => id,
  };
}

String _tallGrassReadinessStatus(TallGrassAuthoringReadinessItem item) {
  if (!item.isSatisfied) {
    return item.id == TallGrassAuthoringReadinessItem.mappedWalkEncounterZoneId
        ? 'À poser'
        : 'À créer';
  }
  return item.id == TallGrassAuthoringReadinessItem.walkEncounterTableId
      ? 'Prête'
      : 'Prêt';
}

class _AdvancedDetailsSection extends StatelessWidget {
  const _AdvancedDetailsSection({
    required this.inspection,
    required this.browser,
    required this.tsxAnimations,
    required this.diagnostics,
    required this.futureActions,
    required this.placeholder,
  });

  final Widget inspection;
  final Widget browser;
  final Widget tsxAnimations;
  final Widget diagnostics;
  final Widget futureActions;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return _StudioCard(
      key: const ValueKey('surface_studio_advanced_details'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Détails avancés',
            style: TextStyle(
              color: label,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Catalogue, inspection et diagnostics restent disponibles sans remplacer le workflow principal.',
            style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth >= 960) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: inspection),
                    const SizedBox(width: 12),
                    Expanded(child: browser),
                    const SizedBox(width: 12),
                    Expanded(child: diagnostics),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  inspection,
                  const SizedBox(height: 12),
                  browser,
                  const SizedBox(height: 12),
                  diagnostics,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          tsxAnimations,
          const SizedBox(height: 12),
          futureActions,
          const SizedBox(height: 10),
          placeholder,
        ],
      ),
    );
  }
}

/// Carte interne : même relief que les tuiles inspecteur / sections.
class _StudioCard extends StatelessWidget {
  const _StudioCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context),
          width: 1,
        ),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: child,
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  const _SectionPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return _StudioCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: label,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  SurfaceStudioPanel.placeholderSoonText,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          MacosIcon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: subtle,
          ),
        ],
      ),
    );
  }
}

/// Adaptateur : construit le read model **sans** I/O à partir d’un [ProjectManifest].
class SurfaceStudioPanelFromManifest extends StatefulWidget {
  const SurfaceStudioPanelFromManifest({
    super.key,
    required this.manifest,
    this.onProjectManifestChanged,
    this.onRequestProjectSave,
    this.projectRootPath,
    this.tsxFileLoader = const TiledTsxPlatformFileLoader(),
  });

  final ProjectManifest manifest;
  final ValueChanged<ProjectManifest>? onProjectManifestChanged;
  final Future<bool> Function()? onRequestProjectSave;

  /// Dossier projet ouvert (même source que l’éditeur) pour résoudre les fichiers image.
  final String? projectRootPath;

  final TiledTsxFileLoader tsxFileLoader;

  @override
  State<SurfaceStudioPanelFromManifest> createState() =>
      _SurfaceStudioPanelFromManifestState();
}

class _SurfaceStudioPanelFromManifestState
    extends State<SurfaceStudioPanelFromManifest> {
  late ProjectManifest _manifest;

  @override
  void initState() {
    super.initState();
    _manifest = widget.manifest;
  }

  @override
  void didUpdateWidget(covariant SurfaceStudioPanelFromManifest oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.manifest != oldWidget.manifest) {
      setState(() {
        _manifest = widget.manifest;
      });
    }
  }

  Future<TallGrassTsxAssetImportResult> _onTallGrassTsxImportRequested({
    required TiledTsxLoadedFile loadedFile,
    required ProjectSurfaceCatalog workCatalog,
  }) async {
    final result = importTallGrassTsxAssets(
      manifest: _manifest.copyWith(surfaceCatalog: workCatalog),
      projectRootPath: widget.projectRootPath,
      loadedFile: loadedFile,
    );
    final next = result.manifest;
    if (!result.hasErrors && next != null) {
      setState(() {
        _manifest = next;
      });
      widget.onProjectManifestChanged?.call(next);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceStudioPanel(
      readModel: buildSurfaceStudioReadModel(_manifest),
      projectSettings: _manifest.settings,
      projectTilesets: _manifest.tilesets,
      projectRootPath: widget.projectRootPath,
      tallGrassAuthoringView: createTallGrassAuthoringView(manifest: _manifest),
      onTallGrassTsxImportRequested: _onTallGrassTsxImportRequested,
      tsxFileLoader: widget.tsxFileLoader,
      onSurfaceCatalogSaveRequested: (c) {
        final n = replaceProjectManifestSurfaceCatalog(_manifest, c);
        setState(() {
          _manifest = n;
        });
        widget.onProjectManifestChanged?.call(n);
      },
      onRequestProjectSave: widget.onRequestProjectSave,
    );
  }
}
```

### packages/map_editor/test/surface_studio/surface_studio_panel_test.dart

```dart
// Surface Studio V2.1 panel tests.
//
// These assertions intentionally replace the old Lot 52-69 panel expectations:
// the catalog browser, diagnostics and paintable-surface panels still exist, but
// they must no longer render as a second Surface Studio under the wizard.

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_workspace.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_workflow_layout.dart';
import 'package:path/path.dart' as p;

import 'surface_studio_rebuild_test_harness.dart';

void main() {
  group('SurfaceStudioPanel V2.1', () {
    testWidgets('renders one wizard and no legacy workflow underneath',
        (tester) async {
      await pumpSurfaceStudioForTest(tester);
      await tester.pump();

      expect(find.byKey(const Key('surfaceStudio.shell')), findsOneWidget);
      expect(
        find.text('Surface Studio — Assistant de mapping d’atlas'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('surface_studio_legacy_authoring_bridge')),
        findsNothing,
      );
      expect(find.byType(SurfaceStudioWorkflowLayout), findsNothing);
      expect(find.text('Assistant de création'), findsNothing);
      expect(find.byKey(const Key('surface_studio.primary_tabs')), findsOne);
      expect(find.text('Catalogue'), findsOneWidget);
      expect(find.text('Créer une surface'), findsOneWidget);
      expect(find.text('Diagnostics Surface'), findsNothing);
    });

    testWidgets('keeps catalog and diagnostics in the advanced drawer',
        (tester) async {
      await pumpSurfaceStudioForTest(tester);
      await tester.pump();

      await tester.tap(find.byIcon(CupertinoIcons.gear_alt));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('surfaceStudio.advanced.drawer')),
        findsOneWidget,
      );
      expect(find.text('Catalogue & diagnostics'), findsOneWidget);
      expect(find.text('Détails avancés'), findsOneWidget);
      expect(find.text('Catalogue Surface'), findsWidgets);
      expect(find.text('Animations TSX importées'), findsOneWidget);
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      expect(find.text('Surfaces prêtes à peindre'), findsOneWidget);
    });

    testWidgets('opens a tall grass subtab from Surface Studio',
        (tester) async {
      await pumpSurfaceStudioForTest(tester);
      await tester.pump();

      expect(
        find.byKey(const Key('surfaceStudio.tallGrass.panel')),
        findsNothing,
      );

      await tester.tap(find.text('Hautes herbes'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('surfaceStudio.tallGrass.panel')),
        findsOneWidget,
      );
      expect(find.text('Comportement'), findsOneWidget);
      expect(find.text('Rencontres en marchant'), findsOneWidget);
      expect(find.text('Animation locale'), findsOneWidget);
      expect(find.text('Bruissement au pas'), findsOneWidget);
    });

    testWidgets('shows tall grass authoring signals from the project manifest',
        (tester) async {
      await pumpSurfaceStudioPanelFromManifest(
        tester,
        manifest: _manifest(
          ProjectSurfaceCatalog(),
          terrainPresets: const [
            ProjectTerrainPreset(
              id: 'grass_visual',
              name: 'Grass Visual',
              terrainType: TerrainType.grass,
            ),
          ],
          pathPresets: const [
            ProjectPathPreset(
              id: 'tall_grass_path',
              name: 'Tall Grass Path',
              surfaceKind: PathSurfaceKind.tallGrass,
            ),
          ],
          encounterTables: const [
            ProjectEncounterTable(
              id: 'route_1_grass',
              name: 'Route 1 Grass',
              encounterKind: EncounterKind.walk,
            ),
          ],
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Hautes herbes'));
      await tester.pumpAndSettle();

      expect(find.text('Signaux projet'), findsOneWidget);
      expect(find.text('Terrain herbe'), findsOneWidget);
      expect(find.text('1 terrain'), findsOneWidget);
      expect(find.text('Chemins hautes herbes'), findsOneWidget);
      expect(find.text('1 chemin'), findsOneWidget);
      expect(find.text('Tables rencontres walk'), findsOneWidget);
      expect(find.text('1 table'), findsOneWidget);
      expect(find.text('Zones rencontres walk'), findsOneWidget);
      expect(find.text('0 zone'), findsOneWidget);
      expect(find.text('Préparation'), findsOneWidget);
      expect(find.text('Visuel hautes herbes'), findsOneWidget);
      expect(find.text('Prêt'), findsOneWidget);
      expect(find.text('Table rencontres walk'), findsOneWidget);
      expect(find.text('Prête'), findsOneWidget);
      expect(find.text('Zones walk posées'), findsOneWidget);
      expect(find.text('À poser'), findsOneWidget);
    });

    testWidgets('imports TECH-Nature static tall grass assets', (tester) async {
      ProjectManifest? changedManifest;
      final projectRoot = Directory.systemTemp.createTempSync(
        'pokemap_tall_grass_panel_import_',
      );
      addTearDown(() {
        if (projectRoot.existsSync()) {
          projectRoot.deleteSync(recursive: true);
        }
      });

      await pumpSurfaceStudioPanelFromManifest(
        tester,
        manifest: _manifest(ProjectSurfaceCatalog()),
        projectRootPath: projectRoot.path,
        tsxFileLoader: _FakeTsxFileLoader(_loadSdkTsx('TECH-Nature.tsx')),
        onProjectManifestChanged: (manifest) => changedManifest = manifest,
      );
      await tester.pump();

      await tester.tap(find.text('Hautes herbes'));
      await tester.pumpAndSettle();

      final importButton =
          find.byKey(const Key('surfaceStudio.tallGrass.importTsx'));
      await tester.ensureVisible(importButton);
      await tester.tap(importButton);
      await tester.pumpAndSettle();

      expect(changedManifest, isNotNull);
      expect(
        changedManifest!.tilesets.map((tileset) => tileset.id),
        contains('tech-nature'),
      );
      expect(
        changedManifest!.tilesets.map((tileset) => tileset.relativePath),
        contains('assets/tilesets/tech-nature.png'),
      );
      expect(
        File(p.join(projectRoot.path, 'assets/tilesets/tech-nature.png'))
            .existsSync(),
        isTrue,
      );
      expect(changedManifest!.surfaceCatalog.atlasCount, 1);
      expect(changedManifest!.surfaceCatalog.animationCount, 0);
      expect(
        find.text(
          'Import hautes herbes prêt : atlas statique lié, 34 tuiles candidates extraites.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Particules SDK : TGrass -> 1, TTallGrass -> 2.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Image TSX copiée dans le projet : assets/tilesets/tech-nature.png.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Tileset lié : tech nature · assets/tilesets/tech-nature.png',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'SurfaceStudioPanelFromManifest saves the work catalog by action',
        (tester) async {
      ProjectManifest? changedManifest;
      await pumpSurfaceStudioPanelFromManifest(
        tester,
        manifest: _manifest(ProjectSurfaceCatalog()),
        onProjectManifestChanged: (manifest) => changedManifest = manifest,
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('surfaceStudio.import.atlasId')),
        'v21-atlas',
      );
      await tester.enterText(
        find.byKey(const Key('surfaceStudio.import.atlasName')),
        'V2.1 Atlas',
      );
      await tester.enterText(
        find.byKey(const Key('surfaceStudio.import.tilesetId')),
        'tiles',
      );
      await tester
          .tap(find.byKey(const Key('surfaceStudio.import.createAtlas')));
      await tester.pump();

      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
      expect(changedManifest, isNull);

      await tester
          .tap(find.byKey(const Key('surfaceStudio.action.saveCatalog')));
      await tester.pump();

      expect(changedManifest, isNotNull);
      expect(
        changedManifest!.surfaceCatalog.atlases.map((atlas) => atlas.id),
        contains('v21-atlas'),
      );
    });

    testWidgets('SurfaceStudioPanel still builds without ProviderScope',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 1800,
            height: 1000,
            child: SurfaceStudioPanel(
              readModel: buildSurfaceStudioReadModelFromCatalog(_catalog()),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('surfaceStudio.shell')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> pumpSurfaceStudioPanelFromManifest(
  WidgetTester tester, {
  required ProjectManifest manifest,
  ValueChanged<ProjectManifest>? onProjectManifestChanged,
  String? projectRootPath,
  TiledTsxFileLoader tsxFileLoader = const TiledTsxPlatformFileLoader(),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(2048, 1120);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 2048,
        height: 1120,
        child: SurfaceStudioPanelFromManifest(
          manifest: manifest,
          projectRootPath: projectRootPath ?? '/missing/project',
          tsxFileLoader: tsxFileLoader,
          onProjectManifestChanged: onProjectManifestChanged,
        ),
      ),
    ),
  );
}

TiledTsxLoadedFile _loadSdkTsx(String fileName) {
  final file = File(
    p.join(_sdkProject().path, 'Data', 'Tiled', 'Tilesets', fileName),
  );
  return TiledTsxLoadedFile(
    path: file.path,
    fileName: fileName,
    xml: file.readAsStringSync(),
  );
}

Directory _sdkProject() {
  final repoRoot = Directory.current.parent.parent;
  return repoRoot
      .listSync()
      .whereType<Directory>()
      .firstWhere((dir) => p.basename(dir.path).contains('sdk_test_project'));
}

final class _FakeTsxFileLoader implements TiledTsxFileLoader {
  const _FakeTsxFileLoader(this.loadedFile);

  final TiledTsxLoadedFile loadedFile;

  @override
  Future<TiledTsxLoadedFile?> pickAndLoadTsx() async => loadedFile;
}

ProjectManifest _manifest(
  ProjectSurfaceCatalog catalog, {
  List<ProjectTerrainPreset> terrainPresets = const [],
  List<ProjectPathPreset> pathPresets = const [],
  List<ProjectEncounterTable> encounterTables = const [],
}) {
  return ProjectManifest(
    name: 'Test',
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'tiles',
        name: 'Tiles',
        relativePath: 'missing/tiles.png',
      ),
    ],
    terrainPresets: terrainPresets,
    pathPresets: pathPresets,
    encounterTables: encounterTables,
    surfaceCatalog: catalog,
  );
}

ProjectSurfaceCatalog _catalog() {
  const atlasId = 'water-atlas';
  final animation = ProjectSurfaceAnimation(
    id: 'water-col-0',
    name: 'Water Column 0',
    timeline: SurfaceAnimationTimeline(
      frames: [
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(
            atlasId: atlasId,
            column: 0,
            row: 0,
          ),
          durationMs: 120,
        ),
      ],
    ),
    syncGroupId: atlasId,
  );
  return ProjectSurfaceCatalog(
    atlases: [
      ProjectSurfaceAtlas(
        id: atlasId,
        name: 'Water Atlas',
        tilesetId: 'tiles',
        geometry: SurfaceAtlasGeometry(
          tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
          gridSize: SurfaceAtlasGridSize(columns: 12, rows: 32),
          layout: SurfaceAtlasLayout.grid,
        ),
      ),
    ],
    animations: [animation],
    presets: [
      ProjectSurfacePreset(
        id: 'water',
        name: 'Water Surface',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.isolated,
              animationId: 'water-col-0',
            ),
          ],
        ),
      ),
    ],
  );
}
```

### packages/map_editor/test/surface_studio/tiled_tsx_workspace_tab_test.dart

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_workspace.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';

void main() {
  testWidgets('Surface Studio exposes a first-level TSX workspace',
      (tester) async {
    await tester.pumpWidget(
      _wrapPanel(
        SurfaceStudioPanel(
          readModel: buildSurfaceStudioReadModelFromCatalog(
            ProjectSurfaceCatalog(),
          ),
          projectTilesets: const [],
          tsxFileLoader: const _NoopTsxFileLoader(),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('surface_studio.primary_tabs')), findsOne);
    expect(find.text('Catalogue'), findsOneWidget);
    expect(find.text('Créer une surface'), findsOneWidget);
    expect(find.text('Diagnostics'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('surface_studio.tab.tsx')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('surface_studio.tsx_workspace')), findsOne);
    expect(find.text('Aucune animation TSX importée.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tiled_tsx_workspace.empty_import')),
      findsOneWidget,
    );
    expect(find.text('Détails avancés'), findsNothing);
  });

  testWidgets('Diagnostics remain available as their own top-level workspace',
      (tester) async {
    await tester.pumpWidget(
      _wrapPanel(
        SurfaceStudioPanel(
          readModel: buildSurfaceStudioReadModelFromCatalog(
            ProjectSurfaceCatalog(),
          ),
          projectTilesets: const [],
          tsxFileLoader: const _NoopTsxFileLoader(),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('surface_studio.tab.diagnostics')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('surface_studio.diagnostics_workspace')),
      findsOne,
    );
    expect(find.text('Détails avancés'), findsOneWidget);
  });
}

Widget _wrapPanel(Widget child) {
  return MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(size: Size(2048, 1120)),
      child: CupertinoPageScaffold(
        child: SizedBox(
          width: 2048,
          height: 1120,
          child: child,
        ),
      ),
    ),
  );
}

final class _NoopTsxFileLoader implements TiledTsxFileLoader {
  const _NoopTsxFileLoader();

  @override
  Future<TiledTsxLoadedFile?> pickAndLoadTsx() async => null;
}
```

### packages/map_editor/test/surface_studio/tiled_tsx_surface_builder_reference_ui_test.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_workspace.dart';

void main() {
  testWidgets('TSX workspace matches the reference builder structure',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        TiledTsxWorkspace(
          catalog: _catalog(),
          projectTilesets: const [
            ProjectTilesetEntry(
              id: 'tech-nature-animations',
              name: 'TECH Nature Animations',
              relativePath: 'Data/Tiled/Assets/TECH-Nature-animations.png',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Créer une surface'), findsWidgets);
    expect(find.text('Importer un TSX'), findsOneWidget);
    expect(find.text('Détection auto'), findsOneWidget);
    expect(find.text('Appliquer les suggestions'), findsOneWidget);
    expect(find.textContaining('Assistant IA'), findsOneWidget);

    expect(find.text('1. Choisir un groupe d’animations'), findsOneWidget);
    expect(find.text('2. Assigner les rôles'), findsOneWidget);
    expect(find.text('3. Prévisualiser et enregistrer'), findsOneWidget);

    expect(find.text('Groupes détectés'), findsOneWidget);
    expect(find.text('Rôles de surface'), findsOneWidget);
    expect(find.text('Prévisualisation'), findsOneWidget);
    expect(find.text('État de la surface'), findsOneWidget);
    expect(find.text('Enregistrer la surface'), findsOneWidget);

    expect(find.text('Groupe détecté 1'), findsOneWidget);
    expect(find.text('2 animations'), findsWidgets);
    expect(find.text('Utiliser'), findsWidgets);
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: 1500, height: 980, child: child),
    ),
  );
}

ProjectSurfaceCatalog _catalog() {
  return ProjectSurfaceCatalog(
    atlases: [_atlas()],
    animations: [
      _animation('tech-animations-tile-99', 1, 1),
      _animation('tech-animations-tile-105', 7, 1),
    ],
  );
}

ProjectSurfaceAtlas _atlas() {
  return ProjectSurfaceAtlas(
    id: 'tech-animations',
    name: 'TECH-Animations',
    tilesetId: 'tech-nature-animations',
    geometry: SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
      gridSize: SurfaceAtlasGridSize(columns: 98, rows: 109),
      layout: SurfaceAtlasLayout.grid,
    ),
  );
}

ProjectSurfaceAnimation _animation(String id, int column, int row) {
  return ProjectSurfaceAnimation(
    id: id,
    name: id,
    timeline: SurfaceAnimationTimeline(
      frames: [
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(
            atlasId: 'tech-animations',
            column: column,
            row: row,
          ),
          durationMs: 100,
        ),
      ],
    ),
  );
}
```

### packages/map_editor/test/surface_studio/tiled_tsx_surface_preview_ui_test.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_workspace.dart';

void main() {
  testWidgets('reference builder saves a preset only after visual role mapping',
      (tester) async {
    ProjectSurfaceCatalog? changedCatalog;

    await tester.pumpWidget(
      _wrap(
        TiledTsxWorkspace(
          catalog: _catalog(),
          onSurfaceCatalogChanged: (catalog) => changedCatalog = catalog,
        ),
      ),
    );

    final save = find.byKey(
      const ValueKey('tiled_tsx_reference_builder.save_surface'),
    );
    expect(tester.widget<ElevatedButton>(save).onPressed, isNull);
    expect(changedCatalog, isNull);

    final pickIsolated = find.byKey(
      const ValueKey('tiled_tsx_role_mapping_builder.pick.isolated'),
    );
    await tester.ensureVisible(pickIsolated);
    await tester.tap(pickIsolated);
    await tester.pumpAndSettle();

    final tile99Option = find.byKey(
      const ValueKey(
        'tiled_tsx_role_mapping_builder.option.isolated.tech-animations-tile-99',
      ),
    );
    await tester.ensureVisible(tile99Option);
    await tester.tap(tile99Option);
    await tester.pumpAndSettle();

    expect(find.text('Centre'), findsOneWidget);
    expect(find.text('OK'), findsWidgets);
    expect(tester.widget<ElevatedButton>(save).onPressed, isNotNull);

    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(changedCatalog, isNotNull);
    expect(changedCatalog!.presetCount, 1);
    expect(
      changedCatalog!
          .presets.single
          .animationIdForRole(SurfaceVariantRole.isolated),
      'tech-animations-tile-99',
    );
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: 1500, height: 980, child: child),
    ),
  );
}

ProjectSurfaceCatalog _catalog() {
  return ProjectSurfaceCatalog(
    atlases: [_atlas()],
    animations: [
      _animation('tech-animations-tile-99', 1, 1),
      _animation('tech-animations-tile-105', 7, 1),
      _animation('tech-animations-tile-111', 13, 1),
    ],
  );
}

ProjectSurfaceAtlas _atlas() {
  return ProjectSurfaceAtlas(
    id: 'tech-animations',
    name: 'TECH-Animations',
    tilesetId: 'tech-nature-animations',
    geometry: SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
      gridSize: SurfaceAtlasGridSize(columns: 98, rows: 109),
      layout: SurfaceAtlasLayout.grid,
    ),
  );
}

ProjectSurfaceAnimation _animation(String id, int column, int row) {
  return ProjectSurfaceAnimation(
    id: id,
    name: id,
    timeline: SurfaceAnimationTimeline(
      frames: [
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(
            atlasId: 'tech-animations',
            column: column,
            row: row,
          ),
          durationMs: 100,
        ),
      ],
    ),
  );
}
```


## 19. Diffs Complets

### Fichiers suivis modifiés

#### git diff -- packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart b/packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart
index eb1298d6..5c83d7d6 100644
--- a/packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart
@@ -1,8 +1,8 @@
 import 'dart:io';
-import 'dart:typed_data';
 
 import 'package:file_picker/file_picker.dart';
 import 'package:flutter/cupertino.dart';
+import 'package:flutter/foundation.dart';
 import 'package:flutter/material.dart'
     show
         DropdownButton,
@@ -10,15 +10,21 @@ import 'package:flutter/material.dart'
         ElevatedButton,
         Material,
         MaterialType;
+import 'package:flutter/services.dart';
 import 'package:map_core/map_core.dart';
 import 'package:path/path.dart' as p;
 
 import '../../../ui/shared/cupertino_editor_widgets.dart';
+import '../surface_studio_vertical_atlas_preset_generator.dart';
 import 'tiled_tsx_animated_tileset_parser.dart';
 import 'tiled_tsx_animation_browser.dart';
+import 'tiled_tsx_animation_browser_models.dart';
 import 'tiled_tsx_catalog_append.dart';
 import 'tiled_tsx_mistral_grouping_suggester.dart';
+import 'tiled_tsx_role_mapping_builder.dart';
 import 'tiled_tsx_surface_animation_importer.dart';
+import 'tiled_tsx_surface_preset_draft.dart';
+import 'tiled_tsx_transparent_color.dart';
 
 final class TiledTsxLoadedFile {
   const TiledTsxLoadedFile({
@@ -32,6 +38,9 @@ final class TiledTsxLoadedFile {
   final String xml;
 }
 
+const MethodChannel _macOsTiledTsxFileAccessChannel =
+    MethodChannel('map_editor/file_access');
+
 abstract interface class TiledTsxFileLoader {
   Future<TiledTsxLoadedFile?> pickAndLoadTsx();
 }
@@ -50,6 +59,7 @@ final class TiledTsxPlatformFileLoader implements TiledTsxFileLoader {
     if (path == null) {
       return null;
     }
+    await _beginTiledTsxImportBundleAccessIfNeeded(path);
     final xml = await File(path).readAsString();
     return TiledTsxLoadedFile(
       path: path,
@@ -59,6 +69,21 @@ final class TiledTsxPlatformFileLoader implements TiledTsxFileLoader {
   }
 }
 
+Future<void> _beginTiledTsxImportBundleAccessIfNeeded(
+    String selectedPath) async {
+  if (defaultTargetPlatform != TargetPlatform.macOS) {
+    return;
+  }
+  try {
+    await _macOsTiledTsxFileAccessChannel.invokeMethod<void>(
+      'beginImportBundleAccess',
+      <String, String>{'selectedPath': selectedPath},
+    );
+  } catch (_) {
+    // Best effort only: non-macOS tests and unsandboxed builds do not need it.
+  }
+}
+
 class TiledTsxWorkspace extends StatefulWidget {
   const TiledTsxWorkspace({
     super.key,
@@ -91,6 +116,18 @@ class _TiledTsxWorkspaceState extends State<TiledTsxWorkspace> {
   bool _loading = false;
   String? _statusMessage;
   List<String> _errors = const <String>[];
+  Uint8List? _transparentPreviewSourceBytes;
+  Uint8List? _transparentPreviewBytes;
+  String? _transparentPreviewColor;
+  String? _activeGroupId;
+  Map<SurfaceVariantRole, String> _roleAnimationIds =
+      const <SurfaceVariantRole, String>{};
+  Map<SurfaceVariantRole, TiledTsxRoleAssignmentMeta> _roleSources =
+      const <SurfaceVariantRole, TiledTsxRoleAssignmentMeta>{};
+  List<String> _surfaceSaveErrors = const <String>[];
+  List<String> _surfaceSaveWarnings = const <String>[];
+  String? _surfaceSaveNote;
+  String? _detectionMessage;
 
   @override
   void didUpdateWidget(covariant TiledTsxWorkspace oldWidget) {
@@ -110,26 +147,27 @@ class _TiledTsxWorkspaceState extends State<TiledTsxWorkspace> {
     final effectiveCatalog = _localCatalog ?? widget.catalog;
     final atlas = _atlasForBrowser(effectiveCatalog);
     final animations = effectiveCatalog.animations;
+    final previewAtlasImageBytes = _previewAtlasImageBytes();
     return SingleChildScrollView(
       key: const ValueKey('surface_studio.tsx_workspace'),
       padding: const EdgeInsets.all(18),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.stretch,
         children: [
-          Text(
-            'Workspace TSX',
-            style: TextStyle(
-              color: label,
-              fontSize: 20,
-              fontWeight: FontWeight.w700,
-            ),
-          ),
-          const SizedBox(height: 6),
-          Text(
-            'Importez un fichier .tsx Tiled, choisissez l’image tileset PokeMap correspondante, puis parcourez les animations Surface produites.',
-            style: TextStyle(color: subtle, fontSize: 13),
+          _TsxWorkspaceHeader(label: label, subtle: subtle),
+          const SizedBox(height: 12),
+          _TsxReferenceActionBar(
+            loading: _loading,
+            hasAnimations: animations.isNotEmpty,
+            hasMistralKey: widget.projectSettings?.mistralApiKey
+                    ?.trim()
+                    .isNotEmpty ==
+                true,
+            onImport: _pickTsx,
+            onDetect: _runLocalDetection,
+            onApplySuggestions: _applyPreparedSuggestions,
           ),
-          const SizedBox(height: 14),
+          const SizedBox(height: 12),
           _ImportSection(
             loadedFile: _loadedFile,
             audit: _audit,
@@ -138,6 +176,7 @@ class _TiledTsxWorkspaceState extends State<TiledTsxWorkspace> {
             loading: _loading,
             statusMessage: _statusMessage,
             errors: _errors,
+            atlasImageBytesAvailable: widget.atlasImageBytes != null,
             onPickTsx: _pickTsx,
             onTilesetChanged: (tileset) {
               setState(() => _selectedTileset = tileset);
@@ -148,21 +187,74 @@ class _TiledTsxWorkspaceState extends State<TiledTsxWorkspace> {
           if (animations.isEmpty)
             _TsxEmptyState(onImportPressed: _pickTsx)
           else
+            _ReferenceTsxSurfaceBuilder(
+              atlas: atlas,
+              animations: animations,
+              atlasImageBytes: previewAtlasImageBytes,
+              catalog: effectiveCatalog,
+              activeGroupId: _activeGroupId,
+              roleAnimationIds: _roleAnimationIds,
+              roleSources: _roleSources,
+              detectionMessage: _detectionMessage,
+              saveErrors: _surfaceSaveErrors,
+              saveWarnings: _surfaceSaveWarnings,
+              saveNote: _surfaceSaveNote,
+              onGroupSelected: (id) {
+                setState(() {
+                  _activeGroupId = id;
+                  _detectionMessage = null;
+                });
+              },
+              onRoleAssignmentsChanged: _replaceRoleAssignments,
+              onSaveSurface: widget.onSurfaceCatalogChanged == null
+                  ? null
+                  : _saveReferenceSurface,
+            ),
+          if (animations.isNotEmpty) ...[
+            const SizedBox(height: 14),
             TiledTsxAnimationBrowser(
               atlas: atlas,
               animations: animations,
-              atlasImageBytes: widget.atlasImageBytes,
+              atlasImageBytes: previewAtlasImageBytes,
               sourceLabel: _loadedFile?.fileName ?? 'Catalogue de travail',
               catalog: effectiveCatalog,
               onSurfaceCatalogChanged: widget.onSurfaceCatalogChanged,
               projectSettings: widget.projectSettings,
               groupingSuggester: widget.groupingSuggester,
             ),
+          ],
         ],
       ),
     );
   }
 
+  Uint8List? _previewAtlasImageBytes() {
+    final source = widget.atlasImageBytes;
+    if (source == null) {
+      _transparentPreviewSourceBytes = null;
+      _transparentPreviewBytes = null;
+      _transparentPreviewColor = null;
+      return null;
+    }
+    final transparentColor = _audit?.summary.transparentColor;
+    if (parseTiledTsxTransparentColor(transparentColor) == null) {
+      return source;
+    }
+    if (identical(source, _transparentPreviewSourceBytes) &&
+        transparentColor == _transparentPreviewColor &&
+        _transparentPreviewBytes != null) {
+      return _transparentPreviewBytes;
+    }
+    final transformed = applyTiledTsxTransparentColorToPngBytes(
+      imageBytes: source,
+      transparentColor: transparentColor,
+    );
+    _transparentPreviewSourceBytes = source;
+    _transparentPreviewColor = transparentColor;
+    _transparentPreviewBytes = transformed;
+    return transformed;
+  }
+
   bool get _canConfirmImport =>
       !_loading &&
       _audit != null &&
@@ -265,11 +357,103 @@ class _TiledTsxWorkspaceState extends State<TiledTsxWorkspace> {
     setState(() {
       _localCatalog = appended.catalog;
       _errors = const <String>[];
+      _roleAnimationIds = const <SurfaceVariantRole, String>{};
+      _roleSources = const <SurfaceVariantRole, TiledTsxRoleAssignmentMeta>{};
+      _surfaceSaveErrors = const <String>[];
+      _surfaceSaveWarnings = const <String>[];
+      _surfaceSaveNote = null;
+      _detectionMessage = null;
+      _activeGroupId = null;
       _statusMessage =
           'Import TSX prêt : ${imported.animations.length} animations ajoutées.';
     });
   }
 
+  void _runLocalDetection() {
+    final groups = buildTiledTsxDetectedAnimationGroups(
+      animations: (_localCatalog ?? widget.catalog).animations,
+    );
+    setState(() {
+      _activeGroupId = groups.isEmpty ? null : groups.first.id;
+      _detectionMessage = groups.isEmpty
+          ? 'Aucune animation disponible pour la détection locale.'
+          : 'Détection locale basique appliquée.';
+    });
+  }
+
+  void _applyPreparedSuggestions() {
+    setState(() {
+      _surfaceSaveNote =
+          'Aucune suggestion acceptée en attente : validez les suggestions Mistral avant application.';
+    });
+  }
+
+  void _replaceRoleAssignments(Map<SurfaceVariantRole, String> next) {
+    final previous = _roleAnimationIds;
+    final nextSources = Map<SurfaceVariantRole, TiledTsxRoleAssignmentMeta>.of(
+      _roleSources,
+    );
+    for (final role in standardSurfaceVariantRoleOrder) {
+      final value = next[role];
+      if (value == null || value.trim().isEmpty) {
+        nextSources.remove(role);
+      } else if (previous[role] != value) {
+        nextSources[role] = const TiledTsxRoleAssignmentMeta(
+          source: TiledTsxRoleAssignmentSource.manual,
+        );
+      }
+    }
+    setState(() {
+      _roleAnimationIds =
+          Map<SurfaceVariantRole, String>.unmodifiable(next);
+      _roleSources =
+          Map<SurfaceVariantRole, TiledTsxRoleAssignmentMeta>.unmodifiable(
+        nextSources,
+      );
+      _surfaceSaveErrors = const <String>[];
+      _surfaceSaveWarnings = const <String>[];
+      _surfaceSaveNote = null;
+    });
+  }
+
+  void _saveReferenceSurface() {
+    final catalog = _localCatalog ?? widget.catalog;
+    final draft = TiledTsxSurfacePresetDraft(
+      id: _nextSurfacePresetId(catalog),
+      name: 'Surface TSX',
+      categoryId: null,
+      sortOrder: catalog.presetCount,
+      roleAnimationIds: _roleAnimationIds,
+    );
+    final validation = validateTiledTsxSurfacePresetDraft(
+      draft: draft,
+      catalog: catalog,
+    );
+    if (!validation.canCreate) {
+      setState(() {
+        _surfaceSaveErrors = validation.errors;
+        _surfaceSaveWarnings = validation.warnings;
+        _surfaceSaveNote = null;
+      });
+      return;
+    }
+    final preset = buildTiledTsxSurfacePresetFromDraft(
+      draft: draft,
+      catalog: catalog,
+    );
+    final next = surfaceStudioAppendPresetToWorkCatalog(
+      catalog: catalog,
+      preset: preset,
+    );
+    widget.onSurfaceCatalogChanged?.call(next);
+    setState(() {
+      _localCatalog = next;
+      _surfaceSaveErrors = const <String>[];
+      _surfaceSaveWarnings = validation.warnings;
+      _surfaceSaveNote = 'Surface ${preset.id} ajoutée au catalogue.';
+    });
+  }
+
   ProjectTilesetEntry? _pickMatchingTileset(TiledTsxTilesetAudit? audit) {
     if (widget.projectTilesets.isEmpty) {
       return null;
@@ -278,7 +462,8 @@ class _TiledTsxWorkspaceState extends State<TiledTsxWorkspace> {
     if (imageSource != null && imageSource.isNotEmpty) {
       final expectedBasename = p.basename(imageSource).toLowerCase();
       for (final tileset in widget.projectTilesets) {
-        if (p.basename(tileset.relativePath).toLowerCase() == expectedBasename) {
+        if (p.basename(tileset.relativePath).toLowerCase() ==
+            expectedBasename) {
           return tileset;
         }
       }
@@ -296,6 +481,7 @@ class _ImportSection extends StatelessWidget {
     required this.loading,
     required this.statusMessage,
     required this.errors,
+    required this.atlasImageBytesAvailable,
     required this.onPickTsx,
     required this.onTilesetChanged,
     required this.onConfirmImport,
@@ -308,6 +494,7 @@ class _ImportSection extends StatelessWidget {
   final bool loading;
   final String? statusMessage;
   final List<String> errors;
+  final bool atlasImageBytesAvailable;
   final VoidCallback onPickTsx;
   final ValueChanged<ProjectTilesetEntry?> onTilesetChanged;
   final VoidCallback? onConfirmImport;
@@ -354,13 +541,18 @@ class _ImportSection extends StatelessWidget {
               ElevatedButton(
                 key: const ValueKey('tiled_tsx_workspace.import'),
                 onPressed: loading ? null : onPickTsx,
-                child: Text(loading ? 'Chargement…' : 'Importer un fichier TSX'),
+                child:
+                    Text(loading ? 'Chargement…' : 'Importer un fichier TSX'),
               ),
             ],
           ),
           if (audit != null) ...[
             const SizedBox(height: 12),
-            _TsxSummary(audit: audit!, loadedFile: loadedFile),
+            _TsxSummary(
+              audit: audit!,
+              loadedFile: loadedFile,
+              atlasImageBytesAvailable: atlasImageBytesAvailable,
+            ),
             const SizedBox(height: 12),
             _TilesetPicker(
               tilesets: projectTilesets,
@@ -428,28 +620,76 @@ class _TsxSummary extends StatelessWidget {
   const _TsxSummary({
     required this.audit,
     required this.loadedFile,
+    required this.atlasImageBytesAvailable,
   });
 
   final TiledTsxTilesetAudit audit;
   final TiledTsxLoadedFile? loadedFile;
+  final bool atlasImageBytesAvailable;
 
   @override
   Widget build(BuildContext context) {
     final s = audit.summary;
-    return _InfoBlock(
-      title: 'Résumé TSX',
-      rows: [
-        ('Fichier', loadedFile?.fileName ?? 'TSX'),
-        ('name', s.name),
-        ('tileWidth', '${s.tileWidth}'),
-        ('tileHeight', '${s.tileHeight}'),
-        ('columns', '${s.columns}'),
-        ('tileCount', '${s.tileCount}'),
-        ('imageSource', s.imageSource),
-        ('imageWidth', '${s.imageWidth}'),
-        ('imageHeight', '${s.imageHeight}'),
-        ('animations', '${s.animationCount} animations'),
-        ('transparentColor', s.transparentColor ?? 'aucune'),
+    final transparentColor = s.transparentColor;
+    final hasTransparentColor =
+        transparentColor != null && transparentColor.trim().isNotEmpty;
+    final validTransparentColor =
+        parseTiledTsxTransparentColor(transparentColor) != null;
+    final transparentColorLabel = !hasTransparentColor
+        ? 'aucune'
+        : validTransparentColor
+            ? formatTiledTsxTransparentColor(transparentColor)
+            : transparentColor;
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        _InfoBlock(
+          title: 'Résumé TSX',
+          rows: [
+            ('Fichier', loadedFile?.fileName ?? 'TSX'),
+            ('name', s.name),
+            ('tileWidth', '${s.tileWidth}'),
+            ('tileHeight', '${s.tileHeight}'),
+            ('columns', '${s.columns}'),
+            ('tileCount', '${s.tileCount}'),
+            ('imageSource', s.imageSource),
+            ('imageWidth', '${s.imageWidth}'),
+            ('imageHeight', '${s.imageHeight}'),
+            ('animations', '${s.animationCount} animations'),
+          ],
+        ),
+        const SizedBox(height: 8),
+        Text(
+          'Couleur transparente : $transparentColorLabel',
+          style: TextStyle(
+            color: EditorChrome.primaryLabel(context),
+            fontSize: 12,
+            fontWeight: FontWeight.w700,
+          ),
+        ),
+        if (hasTransparentColor && validTransparentColor) ...[
+          const SizedBox(height: 4),
+          Text(
+            atlasImageBytesAvailable
+                ? 'Transparence appliquée aux previews.'
+                : 'Transparence prête dès que l’image atlas est disponible.',
+            style: const TextStyle(
+              color: CupertinoColors.systemGreen,
+              fontSize: 12,
+              fontWeight: FontWeight.w600,
+            ),
+          ),
+        ] else if (hasTransparentColor) ...[
+          const SizedBox(height: 4),
+          Text(
+            'Couleur transparente TSX invalide : $transparentColor. Les previews utilisent l’image brute.',
+            style: const TextStyle(
+              color: CupertinoColors.systemOrange,
+              fontSize: 12,
+              fontWeight: FontWeight.w600,
+            ),
+          ),
+        ],
       ],
     );
   }
@@ -558,84 +798,1238 @@ class _TsxEmptyState extends StatelessWidget {
   }
 }
 
-class _InfoBlock extends StatelessWidget {
-  const _InfoBlock({
-    required this.title,
-    required this.rows,
+class _TsxWorkspaceHeader extends StatelessWidget {
+  const _TsxWorkspaceHeader({
+    required this.label,
+    required this.subtle,
   });
 
-  final String title;
-  final List<(String, String)> rows;
+  final Color label;
+  final Color subtle;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      padding: const EdgeInsets.all(16),
+      decoration: BoxDecoration(
+        color: EditorChrome.elevatedPanelBackground(context),
+        borderRadius: BorderRadius.circular(14),
+        border: Border.all(color: EditorChrome.editorIslandRim(context)),
+        boxShadow: EditorChrome.sectionCardShadows(context),
+      ),
+      child: Row(
+        children: [
+          Container(
+            width: 38,
+            height: 38,
+            decoration: BoxDecoration(
+              color: const Color(0xFF2DD4BF).withValues(alpha: 0.22),
+              borderRadius: BorderRadius.circular(11),
+            ),
+            child: const Icon(
+              CupertinoIcons.square_stack_3d_down_right_fill,
+              color: Color(0xFF2DD4BF),
+              size: 22,
+            ),
+          ),
+          const SizedBox(width: 12),
+          Expanded(
+            child: Column(
+              crossAxisAlignment: CrossAxisAlignment.start,
+              children: [
+                Text(
+                  'Créer une surface',
+                  style: TextStyle(
+                    color: label,
+                    fontSize: 21,
+                    fontWeight: FontWeight.w900,
+                  ),
+                ),
+                const SizedBox(height: 3),
+                Text(
+                  'Créez des surfaces animées à partir d’atlas TSX en quelques étapes simples.',
+                  style: TextStyle(color: subtle, fontSize: 12.5),
+                ),
+              ],
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _TsxReferenceActionBar extends StatelessWidget {
+  const _TsxReferenceActionBar({
+    required this.loading,
+    required this.hasAnimations,
+    required this.hasMistralKey,
+    required this.onImport,
+    required this.onDetect,
+    required this.onApplySuggestions,
+  });
+
+  final bool loading;
+  final bool hasAnimations;
+  final bool hasMistralKey;
+  final VoidCallback onImport;
+  final VoidCallback onDetect;
+  final VoidCallback onApplySuggestions;
 
   @override
   Widget build(BuildContext context) {
-    final label = EditorChrome.primaryLabel(context);
     final subtle = EditorChrome.subtleLabel(context);
     return Container(
-      padding: const EdgeInsets.all(10),
+      key: const ValueKey('tiled_tsx_reference.action_bar'),
+      padding: const EdgeInsets.all(12),
       decoration: BoxDecoration(
-        color: EditorChrome.islandFillElevated(context),
-        borderRadius: BorderRadius.circular(8),
+        color: EditorChrome.elevatedPanelBackground(context),
+        borderRadius: BorderRadius.circular(14),
         border: Border.all(color: EditorChrome.editorIslandRim(context)),
       ),
-      child: Column(
-        crossAxisAlignment: CrossAxisAlignment.start,
+      child: Wrap(
+        spacing: 10,
+        runSpacing: 8,
+        crossAxisAlignment: WrapCrossAlignment.center,
         children: [
-          Text(
-            title,
-            style: TextStyle(
-              color: label,
-              fontSize: 13,
-              fontWeight: FontWeight.w700,
+          ElevatedButton(
+            key: const ValueKey('tiled_tsx_reference.import'),
+            onPressed: loading ? null : onImport,
+            child: Text(loading ? 'Import en cours…' : 'Importer un TSX'),
+          ),
+          _ReferenceActionButton(
+            key: const ValueKey('tiled_tsx_reference.detect'),
+            label: 'Détection auto',
+            enabled: hasAnimations,
+            onPressed: onDetect,
+          ),
+          _ReferenceActionButton(
+            key: const ValueKey('tiled_tsx_reference.apply_suggestions'),
+            label: 'Appliquer les suggestions',
+            enabled: hasAnimations,
+            onPressed: onApplySuggestions,
+          ),
+          Container(
+            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
+            decoration: BoxDecoration(
+              color: const Color(0xFF2DD4BF).withValues(alpha: 0.10),
+              borderRadius: BorderRadius.circular(10),
+              border: Border.all(
+                color: const Color(0xFF2DD4BF).withValues(alpha: 0.24),
+              ),
+            ),
+            child: Row(
+              mainAxisSize: MainAxisSize.min,
+              children: [
+                if (loading) ...[
+                  const CupertinoActivityIndicator(radius: 6),
+                  const SizedBox(width: 7),
+                  const Text(
+                    'Analyse Mistral en cours…',
+                    style: TextStyle(
+                      color: Color(0xFF2DD4BF),
+                      fontSize: 11.5,
+                      fontWeight: FontWeight.w800,
+                    ),
+                  ),
+                ] else
+                  Text(
+                    hasMistralKey ? 'Assistant IA prêt' : 'Assistant IA optionnel',
+                    style: TextStyle(
+                      color: hasMistralKey
+                          ? const Color(0xFF2DD4BF)
+                          : subtle,
+                      fontSize: 11.5,
+                      fontWeight: FontWeight.w800,
+                    ),
+                  ),
+              ],
             ),
           ),
-          const SizedBox(height: 8),
-          for (final row in rows)
-            Padding(
-              padding: const EdgeInsets.only(bottom: 3),
-              child: Row(
+        ],
+      ),
+    );
+  }
+}
+
+class _ReferenceActionButton extends StatelessWidget {
+  const _ReferenceActionButton({
+    super.key,
+    required this.label,
+    required this.enabled,
+    required this.onPressed,
+  });
+
+  final String label;
+  final bool enabled;
+  final VoidCallback onPressed;
+
+  @override
+  Widget build(BuildContext context) {
+    final subtle = EditorChrome.subtleLabel(context);
+    return CupertinoButton(
+      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
+      color: enabled
+          ? const Color(0xFF2563EB).withValues(alpha: 0.20)
+          : EditorChrome.islandFillElevated(context),
+      borderRadius: BorderRadius.circular(10),
+      onPressed: enabled ? onPressed : null,
+      child: Text(
+        label,
+        style: TextStyle(
+          color: enabled ? const Color(0xFFA5B4FC) : subtle,
+          fontSize: 12,
+          fontWeight: FontWeight.w800,
+        ),
+      ),
+    );
+  }
+}
+
+class _ReferenceTsxSurfaceBuilder extends StatelessWidget {
+  const _ReferenceTsxSurfaceBuilder({
+    required this.atlas,
+    required this.animations,
+    required this.atlasImageBytes,
+    required this.catalog,
+    required this.activeGroupId,
+    required this.roleAnimationIds,
+    required this.roleSources,
+    required this.detectionMessage,
+    required this.saveErrors,
+    required this.saveWarnings,
+    required this.saveNote,
+    required this.onGroupSelected,
+    required this.onRoleAssignmentsChanged,
+    required this.onSaveSurface,
+  });
+
+  final ProjectSurfaceAtlas? atlas;
+  final List<ProjectSurfaceAnimation> animations;
+  final Uint8List? atlasImageBytes;
+  final ProjectSurfaceCatalog catalog;
+  final String? activeGroupId;
+  final Map<SurfaceVariantRole, String> roleAnimationIds;
+  final Map<SurfaceVariantRole, TiledTsxRoleAssignmentMeta> roleSources;
+  final String? detectionMessage;
+  final List<String> saveErrors;
+  final List<String> saveWarnings;
+  final String? saveNote;
+  final ValueChanged<String> onGroupSelected;
+  final ValueChanged<Map<SurfaceVariantRole, String>> onRoleAssignmentsChanged;
+  final VoidCallback? onSaveSurface;
+
+  @override
+  Widget build(BuildContext context) {
+    final groups = buildTiledTsxDetectedAnimationGroups(animations: animations);
+    final activeGroup = _activeGroup(groups);
+    final selectedIds =
+        activeGroup?.animationIds.toSet() ?? animations.map((a) => a.id).toSet();
+    final canSave =
+        onSaveSurface != null && roleAnimationIds.containsKey(SurfaceVariantRole.isolated);
+
+    return Container(
+      key: const ValueKey('tiled_tsx_reference_builder.root'),
+      padding: const EdgeInsets.all(12),
+      decoration: BoxDecoration(
+        color: EditorChrome.elevatedPanelBackground(context),
+        borderRadius: BorderRadius.circular(16),
+        border: Border.all(color: EditorChrome.editorIslandRim(context)),
+        boxShadow: EditorChrome.sectionCardShadows(context),
+      ),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          _ReferenceStepper(
+            hasGroups: groups.isNotEmpty,
+            hasCenter: roleAnimationIds.containsKey(SurfaceVariantRole.isolated),
+            canSave: canSave,
+          ),
+          const SizedBox(height: 10),
+          LayoutBuilder(
+            builder: (context, constraints) {
+              if (constraints.maxWidth < 1120) {
+                return Column(
+                  crossAxisAlignment: CrossAxisAlignment.stretch,
+                  children: [
+                    _DetectedGroupsColumn(
+                      groups: groups,
+                      activeGroup: activeGroup,
+                      atlas: atlas,
+                      animations: animations,
+                      atlasImageBytes: atlasImageBytes,
+                      detectionMessage: detectionMessage,
+                      onGroupSelected: onGroupSelected,
+                    ),
+                    const SizedBox(height: 10),
+                    _RolesColumn(
+                      atlas: atlas,
+                      animations: animations,
+                      atlasImageBytes: atlasImageBytes,
+                      selectedIds: selectedIds,
+                      roleAnimationIds: roleAnimationIds,
+                      roleSources: roleSources,
+                      onChanged: onRoleAssignmentsChanged,
+                    ),
+                    const SizedBox(height: 10),
+                    _PreviewAndSaveColumn(
+                      atlas: atlas,
+                      animations: animations,
+                      atlasImageBytes: atlasImageBytes,
+                      roleAnimationIds: roleAnimationIds,
+                      canSave: canSave,
+                      errors: saveErrors,
+                      warnings: saveWarnings,
+                      note: saveNote,
+                      onSaveSurface: onSaveSurface,
+                    ),
+                  ],
+                );
+              }
+              return Row(
+                crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   SizedBox(
-                    width: 130,
-                    child: Text(
-                      row.$1,
-                      style: TextStyle(color: subtle, fontSize: 12),
+                    width: 310,
+                    child: _DetectedGroupsColumn(
+                      groups: groups,
+                      activeGroup: activeGroup,
+                      atlas: atlas,
+                      animations: animations,
+                      atlasImageBytes: atlasImageBytes,
+                      detectionMessage: detectionMessage,
+                      onGroupSelected: onGroupSelected,
                     ),
                   ),
+                  const SizedBox(width: 12),
                   Expanded(
-                    child: Text(
-                      row.$2,
-                      style: TextStyle(color: label, fontSize: 12),
-                      overflow: TextOverflow.ellipsis,
+                    child: _RolesColumn(
+                      atlas: atlas,
+                      animations: animations,
+                      atlasImageBytes: atlasImageBytes,
+                      selectedIds: selectedIds,
+                      roleAnimationIds: roleAnimationIds,
+                      roleSources: roleSources,
+                      onChanged: onRoleAssignmentsChanged,
+                    ),
+                  ),
+                  const SizedBox(width: 12),
+                  SizedBox(
+                    width: 360,
+                    child: _PreviewAndSaveColumn(
+                      atlas: atlas,
+                      animations: animations,
+                      atlasImageBytes: atlasImageBytes,
+                      roleAnimationIds: roleAnimationIds,
+                      canSave: canSave,
+                      errors: saveErrors,
+                      warnings: saveWarnings,
+                      note: saveNote,
+                      onSaveSurface: onSaveSurface,
                     ),
                   ),
                 ],
-              ),
-            ),
+              );
+            },
+          ),
         ],
       ),
     );
   }
-}
 
-ProjectSurfaceAtlas? _atlasForBrowser(ProjectSurfaceCatalog catalog) {
-  for (final animation in catalog.animations) {
-    final frames = animation.timeline.frames;
-    if (frames.isEmpty) {
-      continue;
-    }
-    final atlas = catalog.atlasById(frames.first.tileRef.atlasId);
-    if (atlas != null) {
-      return atlas;
+  TiledTsxDetectedAnimationGroup? _activeGroup(
+    List<TiledTsxDetectedAnimationGroup> groups,
+  ) {
+    for (final group in groups) {
+      if (group.id == activeGroupId) {
+        return group;
+      }
     }
+    return groups.isEmpty ? null : groups.first;
   }
-  return catalog.atlases.isEmpty ? null : catalog.atlases.first;
 }
 
-String _slugify(String value) {
-  final lower = value.trim().toLowerCase();
-  final slug = lower
-      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
-      .replaceAll(RegExp(r'^-+|-+$'), '');
-  return slug.isEmpty ? 'tsx-import' : slug;
+class _ReferenceStepper extends StatelessWidget {
+  const _ReferenceStepper({
+    required this.hasGroups,
+    required this.hasCenter,
+    required this.canSave,
+  });
+
+  final bool hasGroups;
+  final bool hasCenter;
+  final bool canSave;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      key: const ValueKey('tiled_tsx_reference.stepper'),
+      padding: const EdgeInsets.all(10),
+      decoration: BoxDecoration(
+        color: EditorChrome.islandFillElevated(context),
+        borderRadius: BorderRadius.circular(12),
+        border: Border.all(color: EditorChrome.editorIslandRim(context)),
+      ),
+      child: Row(
+        children: [
+          Expanded(
+            child: _StepItem(
+              number: '1',
+              title: '1. Choisir un groupe d’animations',
+              subtitle: 'Sélectionnez un groupe détecté',
+              complete: hasGroups,
+            ),
+          ),
+          Expanded(
+            child: _StepItem(
+              number: '2',
+              title: '2. Assigner les rôles',
+              subtitle: 'Glissez ou choisissez chaque rôle',
+              complete: hasCenter,
+            ),
+          ),
+          Expanded(
+            child: _StepItem(
+              number: '3',
+              title: '3. Prévisualiser et enregistrer',
+              subtitle: 'Vérifiez et enregistrez votre surface',
+              complete: canSave,
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _StepItem extends StatelessWidget {
+  const _StepItem({
+    required this.number,
+    required this.title,
+    required this.subtitle,
+    required this.complete,
+  });
+
+  final String number;
+  final String title;
+  final String subtitle;
+  final bool complete;
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+    return Row(
+      children: [
+        Container(
+          width: 30,
+          height: 30,
+          alignment: Alignment.center,
+          decoration: BoxDecoration(
+            color: complete
+                ? const Color(0xFF2DD4BF)
+                : const Color(0xFFE2E8F0).withValues(alpha: 0.16),
+            shape: BoxShape.circle,
+          ),
+          child: Text(
+            number,
+            style: TextStyle(
+              color: complete ? const Color(0xFF062826) : label,
+              fontWeight: FontWeight.w900,
+            ),
+          ),
+        ),
+        const SizedBox(width: 9),
+        Expanded(
+          child: Column(
+            crossAxisAlignment: CrossAxisAlignment.start,
+            children: [
+              Text(
+                title,
+                style: TextStyle(
+                  color: label,
+                  fontSize: 12,
+                  fontWeight: FontWeight.w900,
+                ),
+              ),
+              Text(
+                subtitle,
+                overflow: TextOverflow.ellipsis,
+                style: TextStyle(color: subtle, fontSize: 10.8),
+              ),
+            ],
+          ),
+        ),
+      ],
+    );
+  }
+}
+
+class _DetectedGroupsColumn extends StatelessWidget {
+  const _DetectedGroupsColumn({
+    required this.groups,
+    required this.activeGroup,
+    required this.atlas,
+    required this.animations,
+    required this.atlasImageBytes,
+    required this.detectionMessage,
+    required this.onGroupSelected,
+  });
+
+  final List<TiledTsxDetectedAnimationGroup> groups;
+  final TiledTsxDetectedAnimationGroup? activeGroup;
+  final ProjectSurfaceAtlas? atlas;
+  final List<ProjectSurfaceAnimation> animations;
+  final Uint8List? atlasImageBytes;
+  final String? detectionMessage;
+  final ValueChanged<String> onGroupSelected;
+
+  @override
+  Widget build(BuildContext context) {
+    return _ReferencePanel(
+      title: 'Groupes détectés',
+      badge: '${groups.length}',
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          if (groups.isEmpty)
+            Text(
+              'Aucune animation disponible.',
+              style: TextStyle(
+                color: EditorChrome.subtleLabel(context),
+                fontSize: 12,
+              ),
+            )
+          else
+            for (final group in groups) ...[
+              _DetectedGroupCard(
+                group: group,
+                active: activeGroup?.id == group.id,
+                atlas: atlas,
+                animation: _firstAnimationForGroup(group),
+                atlasImageBytes: atlasImageBytes,
+                onUse: () => onGroupSelected(group.id),
+              ),
+              if (group != groups.last) const SizedBox(height: 8),
+            ],
+          if (detectionMessage != null) ...[
+            const SizedBox(height: 10),
+            _HintBox(text: detectionMessage!),
+          ] else ...[
+            const SizedBox(height: 10),
+            const _HintBox(
+              text:
+                  'Astuce : sélectionnez un groupe pour limiter le picker aux animations pertinentes.',
+            ),
+          ],
+        ],
+      ),
+    );
+  }
+
+  ProjectSurfaceAnimation? _firstAnimationForGroup(
+    TiledTsxDetectedAnimationGroup group,
+  ) {
+    for (final id in group.animationIds) {
+      for (final animation in animations) {
+        if (animation.id == id) {
+          return animation;
+        }
+      }
+    }
+    return null;
+  }
+}
+
+class _DetectedGroupCard extends StatelessWidget {
+  const _DetectedGroupCard({
+    required this.group,
+    required this.active,
+    required this.atlas,
+    required this.animation,
+    required this.atlasImageBytes,
+    required this.onUse,
+  });
+
+  final TiledTsxDetectedAnimationGroup group;
+  final bool active;
+  final ProjectSurfaceAtlas? atlas;
+  final ProjectSurfaceAnimation? animation;
+  final Uint8List? atlasImageBytes;
+  final VoidCallback onUse;
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+    return Container(
+      key: ValueKey('tiled_tsx_reference.group.${group.id}'),
+      padding: const EdgeInsets.all(8),
+      decoration: BoxDecoration(
+        color: active
+            ? const Color(0xFF2DD4BF).withValues(alpha: 0.12)
+            : EditorChrome.islandFillElevated(context),
+        borderRadius: BorderRadius.circular(11),
+        border: Border.all(
+          color: active
+              ? const Color(0xFF2DD4BF).withValues(alpha: 0.55)
+              : EditorChrome.editorIslandRim(context),
+        ),
+      ),
+      child: Row(
+        children: [
+          SizedBox(
+            width: 84,
+            height: 54,
+            child: animation == null
+                ? const _ReferencePreviewFallback()
+                : TiledTsxAnimationTilePreview(
+                    atlas: atlas,
+                    animation: animation!,
+                    atlasImageBytes: atlasImageBytes,
+                    compact: true,
+                  ),
+          ),
+          const SizedBox(width: 9),
+          Expanded(
+            child: Column(
+              crossAxisAlignment: CrossAxisAlignment.start,
+              children: [
+                Text(
+                  group.label,
+                  overflow: TextOverflow.ellipsis,
+                  style: TextStyle(
+                    color: label,
+                    fontSize: 12,
+                    fontWeight: FontWeight.w900,
+                  ),
+                ),
+                Text(
+                  '${group.animationIds.length} animations',
+                  style: TextStyle(color: subtle, fontSize: 11.2),
+                ),
+              ],
+            ),
+          ),
+          CupertinoButton(
+            minimumSize: Size.zero,
+            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
+            onPressed: onUse,
+            child: const Text(
+              'Utiliser',
+              style: TextStyle(
+                color: Color(0xFF2DD4BF),
+                fontSize: 11,
+                fontWeight: FontWeight.w900,
+              ),
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _RolesColumn extends StatelessWidget {
+  const _RolesColumn({
+    required this.atlas,
+    required this.animations,
+    required this.atlasImageBytes,
+    required this.selectedIds,
+    required this.roleAnimationIds,
+    required this.roleSources,
+    required this.onChanged,
+  });
+
+  final ProjectSurfaceAtlas? atlas;
+  final List<ProjectSurfaceAnimation> animations;
+  final Uint8List? atlasImageBytes;
+  final Set<String> selectedIds;
+  final Map<SurfaceVariantRole, String> roleAnimationIds;
+  final Map<SurfaceVariantRole, TiledTsxRoleAssignmentMeta> roleSources;
+  final ValueChanged<Map<SurfaceVariantRole, String>> onChanged;
+
+  @override
+  Widget build(BuildContext context) {
+    return _ReferencePanel(
+      title: 'Rôles de surface',
+      child: TiledTsxRoleMappingBuilder(
+        atlas: atlas,
+        animations: animations,
+        selectedAnimationIds: selectedIds,
+        roleAnimationIds: roleAnimationIds,
+        roleSources: roleSources,
+        atlasImageBytes: atlasImageBytes,
+        onChanged: onChanged,
+      ),
+    );
+  }
+}
+
+class _PreviewAndSaveColumn extends StatelessWidget {
+  const _PreviewAndSaveColumn({
+    required this.atlas,
+    required this.animations,
+    required this.atlasImageBytes,
+    required this.roleAnimationIds,
+    required this.canSave,
+    required this.errors,
+    required this.warnings,
+    required this.note,
+    required this.onSaveSurface,
+  });
+
+  final ProjectSurfaceAtlas? atlas;
+  final List<ProjectSurfaceAnimation> animations;
+  final Uint8List? atlasImageBytes;
+  final Map<SurfaceVariantRole, String> roleAnimationIds;
+  final bool canSave;
+  final List<String> errors;
+  final List<String> warnings;
+  final String? note;
+  final VoidCallback? onSaveSurface;
+
+  @override
+  Widget build(BuildContext context) {
+    final center = _animationForRole(SurfaceVariantRole.isolated);
+    final edgeCount = [
+      SurfaceVariantRole.endNorth,
+      SurfaceVariantRole.endEast,
+      SurfaceVariantRole.endSouth,
+      SurfaceVariantRole.endWest,
+    ].where(roleAnimationIds.containsKey).length;
+    final cornerCount = [
+      SurfaceVariantRole.cornerNW,
+      SurfaceVariantRole.cornerNE,
+      SurfaceVariantRole.cornerSW,
+      SurfaceVariantRole.cornerSE,
+    ].where(roleAnimationIds.containsKey).length;
+    return _ReferencePanel(
+      title: 'Prévisualisation',
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Container(
+            height: 190,
+            padding: const EdgeInsets.all(10),
+            decoration: BoxDecoration(
+              color: const Color(0xFF101820),
+              borderRadius: BorderRadius.circular(12),
+              border: Border.all(color: EditorChrome.editorIslandRim(context)),
+            ),
+            child: center == null
+                ? const Center(
+                    child: Text(
+                      'Assignez Plein(center) pour voir la preview.',
+                      textAlign: TextAlign.center,
+                      style: TextStyle(
+                        color: Color(0xFF94A3B8),
+                        fontSize: 12,
+                        fontWeight: FontWeight.w700,
+                      ),
+                    ),
+                  )
+                : _PreviewTileMosaic(
+                    atlas: atlas,
+                    animation: center,
+                    atlasImageBytes: atlasImageBytes,
+                  ),
+          ),
+          const SizedBox(height: 10),
+          Row(
+            children: [
+              const _MiniControl(label: 'Play'),
+              const SizedBox(width: 8),
+              const Expanded(child: _FrameTrack()),
+              const SizedBox(width: 8),
+              Text(
+                'Boucle',
+                style: TextStyle(
+                  color: EditorChrome.primaryLabel(context),
+                  fontSize: 11,
+                  fontWeight: FontWeight.w800,
+                ),
+              ),
+            ],
+          ),
+          const SizedBox(height: 14),
+          Text(
+            'État de la surface',
+            style: TextStyle(
+              color: EditorChrome.primaryLabel(context),
+              fontSize: 13,
+              fontWeight: FontWeight.w900,
+            ),
+          ),
+          const SizedBox(height: 8),
+          _StatusChecklistRow(
+            label: 'Centre',
+            value: center == null ? 'Manquant' : 'OK',
+            good: center != null,
+          ),
+          _StatusChecklistRow(
+            label: 'Bords',
+            value: '$edgeCount / 4 assignés',
+            good: edgeCount == 4,
+          ),
+          _StatusChecklistRow(
+            label: 'Coins',
+            value: '$cornerCount / 4 assignés',
+            good: cornerCount == 4,
+          ),
+          _StatusChecklistRow(
+            label: 'Cohérence',
+            value: center == null ? 'À vérifier' : 'Bonne correspondance',
+            good: center != null,
+          ),
+          const SizedBox(height: 14),
+          ElevatedButton(
+            key: const ValueKey('tiled_tsx_reference_builder.save_surface'),
+            onPressed: canSave ? onSaveSurface : null,
+            child: const Text('Enregistrer la surface'),
+          ),
+          const SizedBox(height: 6),
+          Text(
+            'Enregistrer comme brouillon',
+            textAlign: TextAlign.center,
+            style: TextStyle(
+              color: EditorChrome.subtleLabel(context),
+              fontSize: 11,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          for (final error in errors) ...[
+            const SizedBox(height: 6),
+            Text(
+              error,
+              style: const TextStyle(
+                color: CupertinoColors.systemRed,
+                fontSize: 11.5,
+                fontWeight: FontWeight.w700,
+              ),
+            ),
+          ],
+          for (final warning in warnings) ...[
+            const SizedBox(height: 6),
+            Text(
+              warning,
+              style: const TextStyle(
+                color: CupertinoColors.systemOrange,
+                fontSize: 11.5,
+                fontWeight: FontWeight.w700,
+              ),
+            ),
+          ],
+          if (note != null) ...[
+            const SizedBox(height: 6),
+            Text(
+              note!,
+              style: const TextStyle(
+                color: Color(0xFF2DD4BF),
+                fontSize: 11.5,
+                fontWeight: FontWeight.w800,
+              ),
+            ),
+          ],
+        ],
+      ),
+    );
+  }
+
+  ProjectSurfaceAnimation? _animationForRole(SurfaceVariantRole role) {
+    final id = roleAnimationIds[role];
+    if (id == null) {
+      return null;
+    }
+    for (final animation in animations) {
+      if (animation.id == id) {
+        return animation;
+      }
+    }
+    return null;
+  }
+}
+
+class _PreviewTileMosaic extends StatelessWidget {
+  const _PreviewTileMosaic({
+    required this.atlas,
+    required this.animation,
+    required this.atlasImageBytes,
+  });
+
+  final ProjectSurfaceAtlas? atlas;
+  final ProjectSurfaceAnimation animation;
+  final Uint8List? atlasImageBytes;
+
+  @override
+  Widget build(BuildContext context) {
+    return GridView.count(
+      crossAxisCount: 4,
+      mainAxisSpacing: 3,
+      crossAxisSpacing: 3,
+      physics: const NeverScrollableScrollPhysics(),
+      children: [
+        for (var i = 0; i < 16; i++)
+          TiledTsxAnimationTilePreview(
+            atlas: atlas,
+            animation: animation,
+            atlasImageBytes: atlasImageBytes,
+            compact: true,
+          ),
+      ],
+    );
+  }
+}
+
+class _ReferencePanel extends StatelessWidget {
+  const _ReferencePanel({
+    required this.title,
+    required this.child,
+    this.badge,
+  });
+
+  final String title;
+  final String? badge;
+  final Widget child;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      padding: const EdgeInsets.all(12),
+      decoration: BoxDecoration(
+        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.62),
+        borderRadius: BorderRadius.circular(14),
+        border: Border.all(color: EditorChrome.editorIslandRim(context)),
+      ),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Row(
+            children: [
+              Expanded(
+                child: Text(
+                  title,
+                  style: TextStyle(
+                    color: EditorChrome.primaryLabel(context),
+                    fontSize: 14,
+                    fontWeight: FontWeight.w900,
+                  ),
+                ),
+              ),
+              if (badge != null)
+                Container(
+                  padding:
+                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
+                  decoration: BoxDecoration(
+                    color: const Color(0xFF2DD4BF).withValues(alpha: 0.16),
+                    borderRadius: BorderRadius.circular(999),
+                  ),
+                  child: Text(
+                    badge!,
+                    style: const TextStyle(
+                      color: Color(0xFF2DD4BF),
+                      fontSize: 10.5,
+                      fontWeight: FontWeight.w900,
+                    ),
+                  ),
+                ),
+            ],
+          ),
+          const SizedBox(height: 10),
+          child,
+        ],
+      ),
+    );
+  }
+}
+
+class _HintBox extends StatelessWidget {
+  const _HintBox({required this.text});
+
+  final String text;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      padding: const EdgeInsets.all(10),
+      decoration: BoxDecoration(
+        color: const Color(0xFF2DD4BF).withValues(alpha: 0.08),
+        borderRadius: BorderRadius.circular(10),
+      ),
+      child: Text(
+        text,
+        style: TextStyle(
+          color: EditorChrome.subtleLabel(context),
+          fontSize: 11.5,
+          height: 1.3,
+        ),
+      ),
+    );
+  }
+}
+
+class _ReferencePreviewFallback extends StatelessWidget {
+  const _ReferencePreviewFallback();
+
+  @override
+  Widget build(BuildContext context) {
+    return DecoratedBox(
+      decoration: BoxDecoration(
+        color: const Color(0xFF101820),
+        borderRadius: BorderRadius.circular(8),
+        border: Border.all(color: EditorChrome.editorIslandRim(context)),
+      ),
+      child: const Center(
+        child: Text(
+          'Preview',
+          style: TextStyle(
+            color: Color(0xFF94A3B8),
+            fontSize: 10,
+            fontWeight: FontWeight.w800,
+          ),
+        ),
+      ),
+    );
+  }
+}
+
+class _MiniControl extends StatelessWidget {
+  const _MiniControl({required this.label});
+
+  final String label;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
+      decoration: BoxDecoration(
+        color: const Color(0xFF2DD4BF),
+        borderRadius: BorderRadius.circular(9),
+      ),
+      child: Text(
+        label,
+        style: const TextStyle(
+          color: Color(0xFF062826),
+          fontSize: 11,
+          fontWeight: FontWeight.w900,
+        ),
+      ),
+    );
+  }
+}
+
+class _FrameTrack extends StatelessWidget {
+  const _FrameTrack();
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      height: 4,
+      decoration: BoxDecoration(
+        color: EditorChrome.editorIslandRim(context),
+        borderRadius: BorderRadius.circular(999),
+      ),
+      alignment: Alignment.centerLeft,
+      child: FractionallySizedBox(
+        widthFactor: 0.35,
+        child: Container(
+          decoration: BoxDecoration(
+            color: const Color(0xFF2DD4BF),
+            borderRadius: BorderRadius.circular(999),
+          ),
+        ),
+      ),
+    );
+  }
+}
+
+class _StatusChecklistRow extends StatelessWidget {
+  const _StatusChecklistRow({
+    required this.label,
+    required this.value,
+    required this.good,
+  });
+
+  final String label;
+  final String value;
+  final bool good;
+
+  @override
+  Widget build(BuildContext context) {
+    return Padding(
+      padding: const EdgeInsets.only(bottom: 7),
+      child: Row(
+        children: [
+          Icon(
+            good ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.info,
+            color:
+                good ? CupertinoColors.systemGreen : CupertinoColors.systemOrange,
+            size: 15,
+          ),
+          const SizedBox(width: 8),
+          Expanded(
+            child: Text(
+              label,
+              style: TextStyle(
+                color: EditorChrome.primaryLabel(context),
+                fontSize: 12,
+                fontWeight: FontWeight.w800,
+              ),
+            ),
+          ),
+          Text(
+            value,
+            style: TextStyle(
+              color: good
+                  ? CupertinoColors.systemGreen.resolveFrom(context)
+                  : EditorChrome.subtleLabel(context),
+              fontSize: 11.5,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+enum TiledTsxDetectedAnimationGroupKind {
+  heuristic,
+  selection,
+}
+
+final class TiledTsxDetectedAnimationGroup {
+  const TiledTsxDetectedAnimationGroup({
+    required this.id,
+    required this.label,
+    required this.animationIds,
+    required this.kind,
+    required this.confidence,
+  });
+
+  final String id;
+  final String label;
+  final List<String> animationIds;
+  final TiledTsxDetectedAnimationGroupKind kind;
+  final double confidence;
+}
+
+List<TiledTsxDetectedAnimationGroup> buildTiledTsxDetectedAnimationGroups({
+  required List<ProjectSurfaceAnimation> animations,
+}) {
+  if (animations.isEmpty) {
+    return const <TiledTsxDetectedAnimationGroup>[];
+  }
+  final items = buildTiledTsxAnimationBrowserItems(animations: animations);
+  final sorted = [...items]..sort((a, b) => a.baseTileId.compareTo(b.baseTileId));
+  final groupSize = sorted.length <= 40 ? sorted.length : 40;
+  final groups = <TiledTsxDetectedAnimationGroup>[];
+  for (var start = 0; start < sorted.length; start += groupSize) {
+    final slice = sorted.skip(start).take(groupSize).toList(growable: false);
+    final number = groups.length + 1;
+    groups.add(
+      TiledTsxDetectedAnimationGroup(
+        id: 'group-$number',
+        label: 'Groupe détecté $number',
+        animationIds:
+            List<String>.unmodifiable(slice.map((item) => item.animationId)),
+        kind: TiledTsxDetectedAnimationGroupKind.heuristic,
+        confidence: 0.5,
+      ),
+    );
+  }
+  return List<TiledTsxDetectedAnimationGroup>.unmodifiable(groups);
+}
+
+class _InfoBlock extends StatelessWidget {
+  const _InfoBlock({
+    required this.title,
+    required this.rows,
+  });
+
+  final String title;
+  final List<(String, String)> rows;
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+    return Container(
+      padding: const EdgeInsets.all(10),
+      decoration: BoxDecoration(
+        color: EditorChrome.islandFillElevated(context),
+        borderRadius: BorderRadius.circular(8),
+        border: Border.all(color: EditorChrome.editorIslandRim(context)),
+      ),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          Text(
+            title,
+            style: TextStyle(
+              color: label,
+              fontSize: 13,
+              fontWeight: FontWeight.w700,
+            ),
+          ),
+          const SizedBox(height: 8),
+          for (final row in rows)
+            Padding(
+              padding: const EdgeInsets.only(bottom: 3),
+              child: Row(
+                children: [
+                  SizedBox(
+                    width: 130,
+                    child: Text(
+                      row.$1,
+                      style: TextStyle(color: subtle, fontSize: 12),
+                    ),
+                  ),
+                  Expanded(
+                    child: Text(
+                      row.$2,
+                      style: TextStyle(color: label, fontSize: 12),
+                      overflow: TextOverflow.ellipsis,
+                    ),
+                  ),
+                ],
+              ),
+            ),
+        ],
+      ),
+    );
+  }
+}
+
+ProjectSurfaceAtlas? _atlasForBrowser(ProjectSurfaceCatalog catalog) {
+  for (final animation in catalog.animations) {
+    final frames = animation.timeline.frames;
+    if (frames.isEmpty) {
+      continue;
+    }
+    final atlas = catalog.atlasById(frames.first.tileRef.atlasId);
+    if (atlas != null) {
+      return atlas;
+    }
+  }
+  return catalog.atlases.isEmpty ? null : catalog.atlases.first;
+}
+
+String _slugify(String value) {
+  final lower = value.trim().toLowerCase();
+  final slug = lower
+      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
+      .replaceAll(RegExp(r'^-+|-+$'), '');
+  return slug.isEmpty ? 'tsx-import' : slug;
+}
+
+String _nextSurfacePresetId(ProjectSurfaceCatalog catalog) {
+  var index = catalog.presetCount;
+  while (true) {
+    final id = 'tsx-surface-$index';
+    if (!catalog.containsPreset(id)) {
+      return id;
+    }
+    index++;
+  }
 }
```

#### git diff -- packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
index 946f71d9..5565d55f 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
@@ -12,6 +12,7 @@ import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
 
 import '../../ui/shared/cupertino_editor_widgets.dart';
+import 'importers/tall_grass_tsx_asset_importer.dart';
 import 'importers/tiled_tsx_animation_browser.dart';
 import 'importers/tiled_tsx_workspace.dart';
 import 'surface_studio_atlas_editing.dart';
@@ -58,6 +59,12 @@ enum _SurfaceStudioPrimaryWorkspace {
   diagnostics,
 }
 
+typedef TallGrassTsxImportRequested = Future<TallGrassTsxAssetImportResult>
+    Function({
+  required TiledTsxLoadedFile loadedFile,
+  required ProjectSurfaceCatalog workCatalog,
+});
+
 /// Panneau présentationnel **lecture seule** pour Surface Studio.
 class SurfaceStudioPanel extends StatefulWidget {
   const SurfaceStudioPanel({
@@ -71,6 +78,7 @@ class SurfaceStudioPanel extends StatefulWidget {
     this.surfaceMappingImageLoader,
     this.aiMappingSuggester,
     this.tallGrassAuthoringView,
+    this.onTallGrassTsxImportRequested,
     this.tsxFileLoader = const TiledTsxPlatformFileLoader(),
   });
 
@@ -82,6 +90,7 @@ class SurfaceStudioPanel extends StatefulWidget {
   final SurfaceStudioAtlasUiImageLoader? surfaceMappingImageLoader;
   final SurfaceStudioAiMappingSuggester? aiMappingSuggester;
   final TallGrassAuthoringView? tallGrassAuthoringView;
+  final TallGrassTsxImportRequested? onTallGrassTsxImportRequested;
   final TiledTsxFileLoader tsxFileLoader;
 
   /// Racine projet sur disque pour résoudre les chemins d’images tileset (aperçu Lot 72).
@@ -368,6 +377,41 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
     });
   }
 
+  Future<TallGrassTsxAssetImportResult> _onTallGrassTsxImportRequested(
+    TiledTsxLoadedFile loadedFile,
+  ) async {
+    final requested = widget.onTallGrassTsxImportRequested;
+    if (requested == null) {
+      return TallGrassTsxAssetImportResult(
+        manifest: null,
+        errors: const ['Import manifest non connecté dans ce contexte.'],
+        messages: const <String>[],
+        createdTileset: false,
+        tileset: null,
+        importedAnimationCount: 0,
+        candidateAnimationIds: const <String>[],
+        visualCandidateTileIds: const <int>[],
+        sdkParticleTags: const <int>[],
+        loadedFileName: loadedFile.fileName,
+      );
+    }
+    final result = await requested(
+      loadedFile: loadedFile,
+      workCatalog: _workReadModel.catalog,
+    );
+    final next = result.manifest;
+    if (!result.hasErrors && next != null && mounted) {
+      setState(() {
+        _saveFlowPrepNote = SurfaceStudioPanel.manifestMemoryUpdatedNote;
+        _workReadModel = buildSurfaceStudioReadModelFromCatalog(
+          next.surfaceCatalog,
+        );
+        _selection = _selectionAfterCatalogChanged(next.surfaceCatalog);
+      });
+    }
+    return result;
+  }
+
   ProjectSurfaceAtlas? _atlasForAnimationBrowser() {
     for (final animation in _workReadModel.catalog.animations) {
       final frames = animation.timeline.frames;
@@ -535,6 +579,10 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
             ),
           _SurfaceStudioPrimaryWorkspace.tallGrass => _TallGrassStudioPanel(
               view: widget.tallGrassAuthoringView,
+              tsxFileLoader: widget.tsxFileLoader,
+              onTsxImportRequested: widget.onTallGrassTsxImportRequested == null
+                  ? null
+                  : _onTallGrassTsxImportRequested,
             ),
           _SurfaceStudioPrimaryWorkspace.tsx => TiledTsxWorkspace(
               catalog: _workReadModel.catalog,
@@ -590,7 +638,7 @@ class _SurfaceStudioPrimaryTabs extends StatelessWidget {
         children: [
           _SurfaceStudioPrimaryTabButton(
             key: const ValueKey('surface_studio.tab.catalogue'),
-            label: 'Catalogue Surface',
+            label: 'Catalogue',
             selected: selected == _SurfaceStudioPrimaryWorkspace.catalogue,
             onPressed: () =>
                 onSelected(_SurfaceStudioPrimaryWorkspace.catalogue),
@@ -606,7 +654,7 @@ class _SurfaceStudioPrimaryTabs extends StatelessWidget {
           const SizedBox(width: 8),
           _SurfaceStudioPrimaryTabButton(
             key: const ValueKey('surface_studio.tab.tsx'),
-            label: 'TSX',
+            label: 'Créer une surface',
             selected: selected == _SurfaceStudioPrimaryWorkspace.tsx,
             onPressed: () => onSelected(_SurfaceStudioPrimaryWorkspace.tsx),
           ),
@@ -661,9 +709,17 @@ class _SurfaceStudioPrimaryTabButton extends StatelessWidget {
 }
 
 class _TallGrassStudioPanel extends StatelessWidget {
-  const _TallGrassStudioPanel({this.view});
+  const _TallGrassStudioPanel({
+    this.view,
+    required this.tsxFileLoader,
+    required this.onTsxImportRequested,
+  });
 
   final TallGrassAuthoringView? view;
+  final TiledTsxFileLoader tsxFileLoader;
+  final Future<TallGrassTsxAssetImportResult> Function(
+    TiledTsxLoadedFile loadedFile,
+  )? onTsxImportRequested;
 
   @override
   Widget build(BuildContext context) {
@@ -777,6 +833,11 @@ class _TallGrassStudioPanel extends StatelessWidget {
             ),
             const SizedBox(height: 12),
             _TallGrassProjectSignalsCard(view: view),
+            const SizedBox(height: 12),
+            _TallGrassTsxImportCard(
+              tsxFileLoader: tsxFileLoader,
+              onTsxImportRequested: onTsxImportRequested,
+            ),
           ],
         ),
       ),
@@ -830,6 +891,185 @@ class _TallGrassCapabilityCard extends StatelessWidget {
   }
 }
 
+class _TallGrassTsxImportCard extends StatefulWidget {
+  const _TallGrassTsxImportCard({
+    required this.tsxFileLoader,
+    required this.onTsxImportRequested,
+  });
+
+  final TiledTsxFileLoader tsxFileLoader;
+  final Future<TallGrassTsxAssetImportResult> Function(
+    TiledTsxLoadedFile loadedFile,
+  )? onTsxImportRequested;
+
+  @override
+  State<_TallGrassTsxImportCard> createState() =>
+      _TallGrassTsxImportCardState();
+}
+
+class _TallGrassTsxImportCardState extends State<_TallGrassTsxImportCard> {
+  bool _loading = false;
+  String? _loadedFileName;
+  List<String> _messages = const <String>[];
+  List<String> _errors = const <String>[];
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+    final canImport = widget.onTsxImportRequested != null && !_loading;
+
+    return _StudioCard(
+      padding: const EdgeInsets.all(14),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Text(
+            'Import assets',
+            style: TextStyle(
+              color: label,
+              fontSize: 15,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          const SizedBox(height: 4),
+          Text(
+            'Importer un TSX hautes herbes pour lier son image tileset au projet, extraire les tuiles candidates et préparer les particules locales.',
+            style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
+          ),
+          const SizedBox(height: 12),
+          Align(
+            alignment: Alignment.centerLeft,
+            child: CupertinoButton(
+              key: const ValueKey('surfaceStudio.tallGrass.importTsx'),
+              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
+              color: canImport
+                  ? _surfaceStudioAccent.withValues(alpha: 0.22)
+                  : EditorChrome.elevatedPanelBackground(context),
+              borderRadius: BorderRadius.circular(9),
+              onPressed: canImport ? _pickAndImportTsx : null,
+              child: Text(
+                _loading
+                    ? 'Import en cours...'
+                    : 'Importer un TSX hautes herbes',
+                style: TextStyle(
+                  color: canImport
+                      ? _surfaceStudioAccent
+                      : subtle.withValues(alpha: 0.8),
+                  fontSize: 13,
+                  fontWeight: FontWeight.w800,
+                ),
+              ),
+            ),
+          ),
+          if (widget.onTsxImportRequested == null) ...[
+            const SizedBox(height: 10),
+            Text(
+              'Import manifest non connecté dans ce contexte.',
+              style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
+            ),
+          ],
+          if (_loadedFileName != null) ...[
+            const SizedBox(height: 10),
+            Text(
+              'Fichier : $_loadedFileName',
+              style: TextStyle(
+                color: subtle,
+                fontSize: 11.5,
+                fontWeight: FontWeight.w700,
+              ),
+            ),
+          ],
+          if (_messages.isNotEmpty) ...[
+            const SizedBox(height: 10),
+            for (final message in _messages) ...[
+              Text(
+                message,
+                style: TextStyle(
+                  color: label,
+                  fontSize: 12,
+                  fontWeight: FontWeight.w700,
+                  height: 1.35,
+                ),
+              ),
+              if (message != _messages.last) const SizedBox(height: 6),
+            ],
+          ],
+          if (_errors.isNotEmpty) ...[
+            const SizedBox(height: 10),
+            Text(
+              'Import hautes herbes bloqué',
+              style: TextStyle(
+                color: CupertinoColors.systemRed.resolveFrom(context),
+                fontSize: 12,
+                fontWeight: FontWeight.w800,
+              ),
+            ),
+            const SizedBox(height: 6),
+            for (final error in _errors) ...[
+              Text(
+                error,
+                style: TextStyle(
+                  color: CupertinoColors.systemRed.resolveFrom(context),
+                  fontSize: 11.5,
+                  height: 1.35,
+                ),
+              ),
+              if (error != _errors.last) const SizedBox(height: 5),
+            ],
+          ],
+        ],
+      ),
+    );
+  }
+
+  Future<void> _pickAndImportTsx() async {
+    final importRequested = widget.onTsxImportRequested;
+    if (importRequested == null) {
+      return;
+    }
+    setState(() {
+      _loading = true;
+      _messages = const <String>[];
+      _errors = const <String>[];
+    });
+    try {
+      final loaded = await widget.tsxFileLoader.pickAndLoadTsx();
+      if (!mounted) {
+        return;
+      }
+      if (loaded == null) {
+        setState(() {
+          _loading = false;
+          _loadedFileName = null;
+          _messages = const ['Import TSX annulé.'];
+          _errors = const <String>[];
+        });
+        return;
+      }
+      final result = await importRequested(loaded);
+      if (!mounted) {
+        return;
+      }
+      setState(() {
+        _loading = false;
+        _loadedFileName = result.loadedFileName;
+        _messages = result.hasErrors ? const <String>[] : result.messages;
+        _errors = result.errors;
+      });
+    } catch (error) {
+      if (!mounted) {
+        return;
+      }
+      setState(() {
+        _loading = false;
+        _messages = const <String>[];
+        _errors = ['Échec import TSX hautes herbes.', '$error'];
+      });
+    }
+  }
+}
+
 class _TallGrassProjectSignalsCard extends StatelessWidget {
   const _TallGrassProjectSignalsCard({required this.view});
 
@@ -1155,6 +1395,7 @@ class SurfaceStudioPanelFromManifest extends StatefulWidget {
     this.onProjectManifestChanged,
     this.onRequestProjectSave,
     this.projectRootPath,
+    this.tsxFileLoader = const TiledTsxPlatformFileLoader(),
   });
 
   final ProjectManifest manifest;
@@ -1164,6 +1405,8 @@ class SurfaceStudioPanelFromManifest extends StatefulWidget {
   /// Dossier projet ouvert (même source que l’éditeur) pour résoudre les fichiers image.
   final String? projectRootPath;
 
+  final TiledTsxFileLoader tsxFileLoader;
+
   @override
   State<SurfaceStudioPanelFromManifest> createState() =>
       _SurfaceStudioPanelFromManifestState();
@@ -1189,6 +1432,25 @@ class _SurfaceStudioPanelFromManifestState
     }
   }
 
+  Future<TallGrassTsxAssetImportResult> _onTallGrassTsxImportRequested({
+    required TiledTsxLoadedFile loadedFile,
+    required ProjectSurfaceCatalog workCatalog,
+  }) async {
+    final result = importTallGrassTsxAssets(
+      manifest: _manifest.copyWith(surfaceCatalog: workCatalog),
+      projectRootPath: widget.projectRootPath,
+      loadedFile: loadedFile,
+    );
+    final next = result.manifest;
+    if (!result.hasErrors && next != null) {
+      setState(() {
+        _manifest = next;
+      });
+      widget.onProjectManifestChanged?.call(next);
+    }
+    return result;
+  }
+
   @override
   Widget build(BuildContext context) {
     return SurfaceStudioPanel(
@@ -1197,6 +1459,8 @@ class _SurfaceStudioPanelFromManifestState
       projectTilesets: _manifest.tilesets,
       projectRootPath: widget.projectRootPath,
       tallGrassAuthoringView: createTallGrassAuthoringView(manifest: _manifest),
+      onTallGrassTsxImportRequested: _onTallGrassTsxImportRequested,
+      tsxFileLoader: widget.tsxFileLoader,
       onSurfaceCatalogSaveRequested: (c) {
         final n = replaceProjectManifestSurfaceCatalog(_manifest, c);
         setState(() {
```

#### git diff -- packages/map_editor/test/surface_studio/surface_studio_panel_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
index 41490dbb..24c90ae0 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
@@ -4,12 +4,16 @@
 // the catalog browser, diagnostics and paintable-surface panels still exist, but
 // they must no longer render as a second Surface Studio under the wizard.
 
+import 'dart:io';
+
 import 'package:flutter/cupertino.dart';
 import 'package:flutter/material.dart' show MaterialApp;
 import 'package:flutter_test/flutter_test.dart';
 import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_workspace.dart';
 import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
 import 'package:map_editor/src/features/surface_studio/surface_studio_workflow_layout.dart';
+import 'package:path/path.dart' as p;
 
 import 'surface_studio_rebuild_test_harness.dart';
 
@@ -32,8 +36,8 @@ void main() {
       expect(find.byType(SurfaceStudioWorkflowLayout), findsNothing);
       expect(find.text('Assistant de création'), findsNothing);
       expect(find.byKey(const Key('surface_studio.primary_tabs')), findsOne);
-      expect(find.text('Catalogue Surface'), findsOneWidget);
-      expect(find.text('TSX'), findsOneWidget);
+      expect(find.text('Catalogue'), findsOneWidget);
+      expect(find.text('Créer une surface'), findsOneWidget);
       expect(find.text('Diagnostics Surface'), findsNothing);
     });
 
@@ -132,6 +136,77 @@ void main() {
       expect(find.text('À poser'), findsOneWidget);
     });
 
+    testWidgets('imports TECH-Nature static tall grass assets', (tester) async {
+      ProjectManifest? changedManifest;
+      final projectRoot = Directory.systemTemp.createTempSync(
+        'pokemap_tall_grass_panel_import_',
+      );
+      addTearDown(() {
+        if (projectRoot.existsSync()) {
+          projectRoot.deleteSync(recursive: true);
+        }
+      });
+
+      await pumpSurfaceStudioPanelFromManifest(
+        tester,
+        manifest: _manifest(ProjectSurfaceCatalog()),
+        projectRootPath: projectRoot.path,
+        tsxFileLoader: _FakeTsxFileLoader(_loadSdkTsx('TECH-Nature.tsx')),
+        onProjectManifestChanged: (manifest) => changedManifest = manifest,
+      );
+      await tester.pump();
+
+      await tester.tap(find.text('Hautes herbes'));
+      await tester.pumpAndSettle();
+
+      final importButton =
+          find.byKey(const Key('surfaceStudio.tallGrass.importTsx'));
+      await tester.ensureVisible(importButton);
+      await tester.tap(importButton);
+      await tester.pumpAndSettle();
+
+      expect(changedManifest, isNotNull);
+      expect(
+        changedManifest!.tilesets.map((tileset) => tileset.id),
+        contains('tech-nature'),
+      );
+      expect(
+        changedManifest!.tilesets.map((tileset) => tileset.relativePath),
+        contains('assets/tilesets/tech-nature.png'),
+      );
+      expect(
+        File(p.join(projectRoot.path, 'assets/tilesets/tech-nature.png'))
+            .existsSync(),
+        isTrue,
+      );
+      expect(changedManifest!.surfaceCatalog.atlasCount, 1);
+      expect(changedManifest!.surfaceCatalog.animationCount, 0);
+      expect(
+        find.text(
+          'Import hautes herbes prêt : atlas statique lié, 34 tuiles candidates extraites.',
+        ),
+        findsOneWidget,
+      );
+      expect(
+        find.text(
+          'Particules SDK : TGrass -> 1, TTallGrass -> 2.',
+        ),
+        findsOneWidget,
+      );
+      expect(
+        find.text(
+          'Image TSX copiée dans le projet : assets/tilesets/tech-nature.png.',
+        ),
+        findsOneWidget,
+      );
+      expect(
+        find.text(
+          'Tileset lié : tech nature · assets/tilesets/tech-nature.png',
+        ),
+        findsOneWidget,
+      );
+    });
+
     testWidgets(
         'SurfaceStudioPanelFromManifest saves the work catalog by action',
         (tester) async {
@@ -200,6 +275,8 @@ Future<void> pumpSurfaceStudioPanelFromManifest(
   WidgetTester tester, {
   required ProjectManifest manifest,
   ValueChanged<ProjectManifest>? onProjectManifestChanged,
+  String? projectRootPath,
+  TiledTsxFileLoader tsxFileLoader = const TiledTsxPlatformFileLoader(),
 }) async {
   tester.view.devicePixelRatio = 1;
   tester.view.physicalSize = const Size(2048, 1120);
@@ -212,7 +289,8 @@ Future<void> pumpSurfaceStudioPanelFromManifest(
         height: 1120,
         child: SurfaceStudioPanelFromManifest(
           manifest: manifest,
-          projectRootPath: '/missing/project',
+          projectRootPath: projectRootPath ?? '/missing/project',
+          tsxFileLoader: tsxFileLoader,
           onProjectManifestChanged: onProjectManifestChanged,
         ),
       ),
@@ -220,6 +298,34 @@ Future<void> pumpSurfaceStudioPanelFromManifest(
   );
 }
 
+TiledTsxLoadedFile _loadSdkTsx(String fileName) {
+  final file = File(
+    p.join(_sdkProject().path, 'Data', 'Tiled', 'Tilesets', fileName),
+  );
+  return TiledTsxLoadedFile(
+    path: file.path,
+    fileName: fileName,
+    xml: file.readAsStringSync(),
+  );
+}
+
+Directory _sdkProject() {
+  final repoRoot = Directory.current.parent.parent;
+  return repoRoot
+      .listSync()
+      .whereType<Directory>()
+      .firstWhere((dir) => p.basename(dir.path).contains('sdk_test_project'));
+}
+
+final class _FakeTsxFileLoader implements TiledTsxFileLoader {
+  const _FakeTsxFileLoader(this.loadedFile);
+
+  final TiledTsxLoadedFile loadedFile;
+
+  @override
+  Future<TiledTsxLoadedFile?> pickAndLoadTsx() async => loadedFile;
+}
+
 ProjectManifest _manifest(
   ProjectSurfaceCatalog catalog, {
   List<ProjectTerrainPreset> terrainPresets = const [],
```

#### git diff -- packages/map_editor/test/surface_studio/tiled_tsx_workspace_tab_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/tiled_tsx_workspace_tab_test.dart b/packages/map_editor/test/surface_studio/tiled_tsx_workspace_tab_test.dart
index aa9c713e..33269ffc 100644
--- a/packages/map_editor/test/surface_studio/tiled_tsx_workspace_tab_test.dart
+++ b/packages/map_editor/test/surface_studio/tiled_tsx_workspace_tab_test.dart
@@ -21,8 +21,8 @@ void main() {
     );
 
     expect(find.byKey(const ValueKey('surface_studio.primary_tabs')), findsOne);
-    expect(find.text('Catalogue Surface'), findsOneWidget);
-    expect(find.text('TSX'), findsOneWidget);
+    expect(find.text('Catalogue'), findsOneWidget);
+    expect(find.text('Créer une surface'), findsOneWidget);
     expect(find.text('Diagnostics'), findsOneWidget);
 
     await tester.tap(find.byKey(const ValueKey('surface_studio.tab.tsx')));
```


### Fichiers ajoutés TSX-8

#### packages/map_editor/test/surface_studio/tiled_tsx_surface_builder_reference_ui_test.dart

```diff
+++ packages/map_editor/test/surface_studio/tiled_tsx_surface_builder_reference_ui_test.dart
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_workspace.dart';
+
+void main() {
+  testWidgets('TSX workspace matches the reference builder structure',
+      (tester) async {
+    await tester.pumpWidget(
+      _wrap(
+        TiledTsxWorkspace(
+          catalog: _catalog(),
+          projectTilesets: const [
+            ProjectTilesetEntry(
+              id: 'tech-nature-animations',
+              name: 'TECH Nature Animations',
+              relativePath: 'Data/Tiled/Assets/TECH-Nature-animations.png',
+            ),
+          ],
+        ),
+      ),
+    );
+
+    expect(find.text('Créer une surface'), findsWidgets);
+    expect(find.text('Importer un TSX'), findsOneWidget);
+    expect(find.text('Détection auto'), findsOneWidget);
+    expect(find.text('Appliquer les suggestions'), findsOneWidget);
+    expect(find.textContaining('Assistant IA'), findsOneWidget);
+
+    expect(find.text('1. Choisir un groupe d’animations'), findsOneWidget);
+    expect(find.text('2. Assigner les rôles'), findsOneWidget);
+    expect(find.text('3. Prévisualiser et enregistrer'), findsOneWidget);
+
+    expect(find.text('Groupes détectés'), findsOneWidget);
+    expect(find.text('Rôles de surface'), findsOneWidget);
+    expect(find.text('Prévisualisation'), findsOneWidget);
+    expect(find.text('État de la surface'), findsOneWidget);
+    expect(find.text('Enregistrer la surface'), findsOneWidget);
+
+    expect(find.text('Groupe détecté 1'), findsOneWidget);
+    expect(find.text('2 animations'), findsWidgets);
+    expect(find.text('Utiliser'), findsWidgets);
+  });
+}
+
+Widget _wrap(Widget child) {
+  return MaterialApp(
+    home: Scaffold(
+      body: SizedBox(width: 1500, height: 980, child: child),
+    ),
+  );
+}
+
+ProjectSurfaceCatalog _catalog() {
+  return ProjectSurfaceCatalog(
+    atlases: [_atlas()],
+    animations: [
+      _animation('tech-animations-tile-99', 1, 1),
+      _animation('tech-animations-tile-105', 7, 1),
+    ],
+  );
+}
+
+ProjectSurfaceAtlas _atlas() {
+  return ProjectSurfaceAtlas(
+    id: 'tech-animations',
+    name: 'TECH-Animations',
+    tilesetId: 'tech-nature-animations',
+    geometry: SurfaceAtlasGeometry(
+      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+      gridSize: SurfaceAtlasGridSize(columns: 98, rows: 109),
+      layout: SurfaceAtlasLayout.grid,
+    ),
+  );
+}
+
+ProjectSurfaceAnimation _animation(String id, int column, int row) {
+  return ProjectSurfaceAnimation(
+    id: id,
+    name: id,
+    timeline: SurfaceAnimationTimeline(
+      frames: [
+        SurfaceAnimationFrame(
+          tileRef: SurfaceAtlasTileRef(
+            atlasId: 'tech-animations',
+            column: column,
+            row: row,
+          ),
+          durationMs: 100,
+        ),
+      ],
+    ),
+  );
+}
```

#### packages/map_editor/test/surface_studio/tiled_tsx_surface_preview_ui_test.dart

```diff
+++ packages/map_editor/test/surface_studio/tiled_tsx_surface_preview_ui_test.dart
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_workspace.dart';
+
+void main() {
+  testWidgets('reference builder saves a preset only after visual role mapping',
+      (tester) async {
+    ProjectSurfaceCatalog? changedCatalog;
+
+    await tester.pumpWidget(
+      _wrap(
+        TiledTsxWorkspace(
+          catalog: _catalog(),
+          onSurfaceCatalogChanged: (catalog) => changedCatalog = catalog,
+        ),
+      ),
+    );
+
+    final save = find.byKey(
+      const ValueKey('tiled_tsx_reference_builder.save_surface'),
+    );
+    expect(tester.widget<ElevatedButton>(save).onPressed, isNull);
+    expect(changedCatalog, isNull);
+
+    final pickIsolated = find.byKey(
+      const ValueKey('tiled_tsx_role_mapping_builder.pick.isolated'),
+    );
+    await tester.ensureVisible(pickIsolated);
+    await tester.tap(pickIsolated);
+    await tester.pumpAndSettle();
+
+    final tile99Option = find.byKey(
+      const ValueKey(
+        'tiled_tsx_role_mapping_builder.option.isolated.tech-animations-tile-99',
+      ),
+    );
+    await tester.ensureVisible(tile99Option);
+    await tester.tap(tile99Option);
+    await tester.pumpAndSettle();
+
+    expect(find.text('Centre'), findsOneWidget);
+    expect(find.text('OK'), findsWidgets);
+    expect(tester.widget<ElevatedButton>(save).onPressed, isNotNull);
+
+    await tester.ensureVisible(save);
+    await tester.tap(save);
+    await tester.pumpAndSettle();
+
+    expect(changedCatalog, isNotNull);
+    expect(changedCatalog!.presetCount, 1);
+    expect(
+      changedCatalog!
+          .presets.single
+          .animationIdForRole(SurfaceVariantRole.isolated),
+      'tech-animations-tile-99',
+    );
+  });
+}
+
+Widget _wrap(Widget child) {
+  return MaterialApp(
+    home: Scaffold(
+      body: SizedBox(width: 1500, height: 980, child: child),
+    ),
+  );
+}
+
+ProjectSurfaceCatalog _catalog() {
+  return ProjectSurfaceCatalog(
+    atlases: [_atlas()],
+    animations: [
+      _animation('tech-animations-tile-99', 1, 1),
+      _animation('tech-animations-tile-105', 7, 1),
+      _animation('tech-animations-tile-111', 13, 1),
+    ],
+  );
+}
+
+ProjectSurfaceAtlas _atlas() {
+  return ProjectSurfaceAtlas(
+    id: 'tech-animations',
+    name: 'TECH-Animations',
+    tilesetId: 'tech-nature-animations',
+    geometry: SurfaceAtlasGeometry(
+      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+      gridSize: SurfaceAtlasGridSize(columns: 98, rows: 109),
+      layout: SurfaceAtlasLayout.grid,
+    ),
+  );
+}
+
+ProjectSurfaceAnimation _animation(String id, int column, int row) {
+  return ProjectSurfaceAnimation(
+    id: id,
+    name: id,
+    timeline: SurfaceAnimationTimeline(
+      frames: [
+        SurfaceAnimationFrame(
+          tileRef: SurfaceAtlasTileRef(
+            atlasId: 'tech-animations',
+            column: column,
+            row: row,
+          ),
+          durationMs: 100,
+        ),
+      ],
+    ),
+  );
+}
```


## 20. Auto-review

- Fonctionnalité réelle : le flux peut assigner `Plein(center)` via picker et créer un `ProjectSurfacePreset` seulement au clic explicite `Enregistrer la surface`.
- Fidélité référence : la structure principale correspond à la référence fournie : action bar, stepper, groupes, rôles, preview, état, sauvegarde.
- Simplicité : les groupes sont heuristiques V1, sans sémantique inventée.
- Sécurité produit : aucun gameplay ni mutation disque automatique.
- Risque : le fichier `tiled_tsx_workspace.dart` est devenu gros ; TSX-9 devrait extraire les composants de présentation si la direction UX est validée.

## 21. Git Status Final

Commande exacte :

```bash
git status --short --untracked-files=all
```

Sortie complète :

```text
 M packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animation_browser.dart
 M packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/macos/Runner/MainFlutterWindow.swift
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart
 M packages/map_editor/test/surface_studio/tiled_tsx_surface_preset_builder_ui_test.dart
 M packages/map_editor/test/surface_studio/tiled_tsx_workspace_tab_test.dart
?? packages/map_editor/lib/src/features/surface_studio/importers/tall_grass_tsx_asset_importer.dart
?? packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_role_mapping_builder.dart
?? packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_transparent_color.dart
?? packages/map_editor/test/surface_studio/tall_grass_tsx_asset_importer_test.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_mistral_review_ui_test.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_role_mapping_builder_test.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_surface_builder_reference_ui_test.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_surface_preview_ui_test.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_transparent_color_test.dart
?? reports/surface/surface_studio_tiled_tsx_reference_ui_v1.md
?? reports/surface/surface_studio_tiled_tsx_role_mapping_ux_v0.md
```
