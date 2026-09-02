import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_atlas_image_loader.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_source_asset_import_service.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_reconstruction_service.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_tiled_wang_import_service.dart';
import 'package:map_editor/src/features/smart_tiles_studio/presentation/smart_tile_sprite_preview.dart';
import 'package:map_editor/src/features/smart_tiles_studio/presentation/smart_tile_preset_library_actions.dart';
import 'package:map_editor/src/features/smart_tiles_studio/presentation/smart_tiles_studio_panel.dart';
import 'package:map_editor/src/ui/design_system/pokemap_asset_card.dart';
import 'package:map_editor/src/ui/design_system/pokemap_button.dart';
import 'package:map_editor/src/ui/design_system/pokemap_selectable_tile.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

void main() {
  group('SmartTilesStudioPanel', () {
    testWidgets('enables the three approved no-code usages', (tester) async {
      await _pumpPanel(tester, _manifest());

      await tester.tap(find.byKey(const Key('smart-tiles-new-preset')));
      await tester.pump();

      final terrain = tester.widget<PokeMapAssetCard>(
        find.byKey(const Key('smart-tiles-usage-terrain')),
      );
      final forest = tester.widget<PokeMapAssetCard>(
        find.byKey(const Key('smart-tiles-usage-forestSurface')),
      );
      final path = tester.widget<PokeMapAssetCard>(
        find.byKey(const Key('smart-tiles-usage-path')),
      );

      expect(terrain.onPressed, isNotNull);
      expect(forest.onPressed, isNotNull);
      expect(path.onPressed, isNotNull);
      expect(find.text('Surface organique'), findsOneWidget);
      expect(find.textContaining('Recommandé :'), findsNWidgets(3));
    });

    testWidgets('renders the approved three-column studio shell', (
      tester,
    ) async {
      await _pumpPanel(tester, _manifest());

      expect(find.text('Smart Tiles Studio'), findsOneWidget);
      expect(
        find.byKey(const Key('smart-tiles-library-column')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('smart-tiles-workbench-column')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('smart-tiles-inspector-column')),
        findsOneWidget,
      );
      for (final tab in <String>[
        'Atlas',
        'Règles',
        'Animations',
        'Banc d’essai',
        'Validation',
      ]) {
        expect(find.text(tab), findsWidgets);
      }
      expect(find.text('Chemin Hanazuki'), findsWidgets);
      expect(find.text('Publié'), findsWidgets);
      expect(find.text('Natif v6'), findsOneWidget);
    });

    testWidgets('shows an animated preset first frame in the library', (
      tester,
    ) async {
      await _pumpPanel(
        tester,
        _completeManifest(animated: true),
        projectRootPath: '/virtual/project',
      );

      final thumbnail = find.byKey(
        const Key('smart-tiles-library-thumbnail-native:edge'),
      );
      expect(thumbnail, findsOneWidget);
      expect(
        tester.widget<SmartTileSpritePreview>(thumbnail).frame,
        const SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
      );
    });

    testWidgets('opens and submits the guided TSX/Wang import flow', (
      tester,
    ) async {
      List<TiledWangSetSelection>? submitted;
      await _pumpPanel(
        tester,
        _manifest(),
        onPickTiledWangSource: () async => _tiledWangSource,
        onImportTiledWang: (source, selections) async {
          submitted = selections;
          return SmartTileTiledWangImportResult(
            manifest: _manifest(),
            presetIds: const <String>['road-import-w0-preset'],
            receiptId: 'receipt-tiled-import',
          );
        },
      );

      await tester.tap(find.byKey(const Key('smart-tiles-import-tiled-wang')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('smart-tiles-tiled-wang-import-editor')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('smart-tiles-wang-set-0-usage')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chemin').last);
      await tester.pumpAndSettle();
      final submit = find.byKey(const Key('smart-tiles-tiled-wang-submit'));
      await tester.scrollUntilVisible(
        submit,
        300,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('smart-tiles-workbench-column')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(submitted, hasLength(1));
      expect(submitted!.single.usage, SmartTileUsage.path);
    });

    testWidgets('offers publication for an imported Wang draft', (
      tester,
    ) async {
      ProjectSmartTilePreset? published;
      await _pumpPanel(
        tester,
        _manifest(presets: const <ProjectSmartTilePreset>[_importedWangPreset]),
        onPublishExistingPreset: (preset) async => published = preset,
      );

      final publish = find.byKey(
        const Key('smart-tiles-publish-imported-preset'),
      );
      expect(publish, findsOneWidget);
      expect(tester.widget<PokeMapButton>(publish).onPressed, isNotNull);

      await tester.tap(publish);
      await tester.pumpAndSettle();

      expect(published, _importedWangPreset);
    });

    testWidgets('renames a preset through a guided prompt', (tester) async {
      ProjectSmartTilePreset? updated;
      await _pumpPanel(
        tester,
        _manifest(),
        onUpdatePreset: (preset) async => updated = preset,
      );

      await tester.tap(find.byKey(const Key('smart-tiles-rename-preset')));
      await tester.pumpAndSettle();

      expect(find.text('Renommer le Smart Tile'), findsOneWidget);
      final field = find.byType(EditableText).last;
      expect(field, findsOneWidget);
      await tester.enterText(field, 'Chemin principal');
      await tester.tap(find.text('Renommer').last);
      await tester.pumpAndSettle();

      expect(updated, isNotNull);
      expect(updated!.id, 'hanazuki-path');
      expect(updated!.name, 'Chemin principal');
      expect(updated!.usage, SmartTileUsage.path);
    });

    testWidgets('duplicates the complete selected preset', (tester) async {
      ProjectSmartTilePreset? duplicated;
      await _pumpPanel(
        tester,
        _manifest(),
        onDuplicatePreset: (preset) async => duplicated = preset,
      );

      final duplicate = find.byKey(const Key('smart-tiles-duplicate-preset'));
      expect(duplicate, findsOneWidget);
      expect(tester.widget<PokeMapButton>(duplicate).onPressed, isNotNull);

      await tester.tap(duplicate);
      await tester.pumpAndSettle();

      expect(duplicated, isNotNull);
      expect(duplicated!.id, 'hanazuki-path');
      expect(duplicated!.name, 'Chemin Hanazuki');
      expect(duplicated!.usage, SmartTileUsage.path);
    });

    testWidgets('confirms before deleting the selected preset', (tester) async {
      ProjectSmartTilePreset? deleted;
      await _pumpPanel(
        tester,
        _manifest(),
        onDeletePreset: (preset) async => deleted = preset,
      );

      await tester.tap(find.byKey(const Key('smart-tiles-delete-preset')));
      await tester.pumpAndSettle();

      expect(find.text('Supprimer ce Smart Tile ?'), findsOneWidget);
      expect(deleted, isNull);
      await tester.tap(find.text('Supprimer').last);
      await tester.pumpAndSettle();

      expect(deleted, isNotNull);
      expect(deleted!.id, 'hanazuki-path');
    });

    testWidgets('opens the reconstruction assistant from a captured map', (
      tester,
    ) async {
      await _pumpPanel(
        tester,
        _manifest(),
        projectRootPath: '/project',
        capturedMap: _literalCapturedMap,
        isCapturedMapAvailable: true,
        reconstructionService: SmartTileReconstructionService(
          gateway: _UnusedReconstructionGateway(),
        ),
        onReconstructionApplied: (_) async {},
      );

      final trigger = find.byKey(
        const Key('smart-tiles-reconstruct-literal-layer'),
      );
      expect(trigger, findsOneWidget);
      await tester.tap(trigger);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('smart-tile-reconstruction-editor')),
        findsOneWidget,
      );
      expect(find.text('Reconstruire une couche littérale'), findsOneWidget);
      expect(find.text('Analyser la reconstruction'), findsOneWidget);
    });

    testWidgets('adapts the studio shell without overflowing when narrow', (
      tester,
    ) async {
      await _pumpPanel(tester, _manifest(), surfaceSize: const Size(560, 760));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('smart-tiles-library-column')), findsNothing);
      expect(
        find.byKey(const Key('smart-tiles-workbench-column')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('smart-tiles-inspector-column')),
        findsNothing,
      );
      expect(find.byKey(const Key('smart-tiles-open-library')), findsOneWidget);
      expect(
        find.byKey(const Key('smart-tiles-open-inspector')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('smart-tiles-open-library')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('smart-tiles-library-modal')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('moves only the inspector to a side sheet at medium width', (
      tester,
    ) async {
      await _pumpPanel(tester, _manifest(), surfaceSize: const Size(900, 760));

      expect(
        find.byKey(const Key('smart-tiles-library-column')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('smart-tiles-workbench-column')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('smart-tiles-inspector-column')),
        findsNothing,
      );
      expect(find.byKey(const Key('smart-tiles-open-library')), findsNothing);

      await tester.tap(find.byKey(const Key('smart-tiles-open-inspector')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('smart-tiles-inspector-drawer')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('filters the permanent library by usage', (tester) async {
      await _pumpPanel(
        tester,
        _manifest(
          presets: const <ProjectSmartTilePreset>[
            ProjectSmartTilePreset(
              id: 'terrain',
              name: 'Terrain Hanazuki',
              usage: SmartTileUsage.terrain,
              topology: SmartTileTopology.cardinal4,
              coveragePolicy: SmartTileCoveragePolicy.complete,
              coverageProfile: SmartTileCoverageProfile(
                mode: SmartTileCoverageMode.template,
              ),
              transformPolicy: SmartTileTransformPolicy(),
              defaultMaterialId: 'grass',
              allowedMaterialIds: <String>['grass'],
            ),
            ProjectSmartTilePreset(
              id: 'forest',
              name: 'Forêt Hanazuki',
              usage: SmartTileUsage.forestSurface,
              topology: SmartTileTopology.blob8,
              coveragePolicy: SmartTileCoveragePolicy.complete,
              coverageProfile: SmartTileCoverageProfile(
                mode: SmartTileCoverageMode.template,
              ),
              transformPolicy: SmartTileTransformPolicy(),
              defaultMaterialId: 'forest',
              allowedMaterialIds: <String>['forest'],
            ),
          ],
        ),
      );

      await tester.tap(
        find.byKey(const Key('smart-tiles-filter-forestSurface')),
      );
      await tester.pump();

      expect(find.text('Forêt Hanazuki'), findsWidgets);
      expect(find.text('Terrain Hanazuki'), findsNothing);
    });

    testWidgets('adds a published preset to the captured map canonically', (
      tester,
    ) async {
      ProjectSmartTilePreset? addedPreset;
      await _pumpPanel(
        tester,
        _manifest(),
        isCapturedMapAvailable: true,
        onAddPresetToCapturedMap: (preset) async {
          addedPreset = preset;
          return true;
        },
      );

      final finder = find.byKey(const Key('smart-tiles-add-to-active-map'));
      final button = tester.widget<PokeMapButton>(finder);
      expect(button.onPressed, isNotNull);
      expect(button.disabledReason, isNull);

      await tester.tap(finder);
      await tester.pumpAndSettle();

      expect(addedPreset?.id, 'hanazuki-path');
    });

    testWidgets('starts the guided flow with human labels and no masks', (
      tester,
    ) async {
      await _pumpPanel(tester, _manifest(presets: const []));

      await tester.tap(find.byKey(const Key('smart-tiles-new-preset')));
      await tester.pump();

      expect(find.text('Nouveau Smart Tile'), findsOneWidget);
      for (final stage in const <String>[
        '1. Objectif',
        '2. Image',
        '3. Découpage',
        '4. Peinture',
        '5. Tracé',
        '6. Options',
        '7. Associer',
        '8. Tester',
        '9. Enregistrer',
      ]) {
        expect(find.text(stage), findsOneWidget);
      }
      expect(find.byKey(const Key('smart-tiles-usage-path')), findsOneWidget);
      expect(find.text('0x00'), findsNothing);
    });

    testWidgets('previews a project image before confirming the source', (
      tester,
    ) async {
      final loader = _FakeSmartTileAtlasImageLoader(width: 320, height: 192);
      await _pumpPanel(
        tester,
        _manifest(
          presets: const <ProjectSmartTilePreset>[],
          tilesets: const <ProjectTilesetEntry>[_target],
        ),
        projectRootPath: '/tmp/erw-project',
        imageLoader: loader,
      );

      await _startPathImage(tester);
      await tester.tap(
        find.byKey(const Key('smart-tiles-source-project-image')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('smart-tiles-choose-project-image')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('smart-tiles-source-tileset-erw-terrain-master')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Choisir une image du projet'), findsOneWidget);
      expect(
        find.byKey(const Key('smart-tiles-picker-image-preview')),
        findsOneWidget,
      );
      expect(find.text('320 × 192 px'), findsOneWidget);
      expect(loader.lastTilesetId, 'erw-terrain-master');

      await tester.tap(
        find.byKey(const Key('smart-tiles-picker-confirm-image')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Choisir une image du projet'), findsNothing);
      expect(
        find.byKey(const Key('smart-tiles-source-image-preview')),
        findsOneWidget,
      );
    });

    testWidgets('presents the path workflow in plain language', (tester) async {
      await _pumpPanel(
        tester,
        _manifest(
          presets: const <ProjectSmartTilePreset>[],
          tilesets: const <ProjectTilesetEntry>[_target],
        ),
        projectRootPath: '/tmp/erw-project',
        imageLoader: _FakeSmartTileAtlasImageLoader(width: 320, height: 192),
      );

      await tester.tap(find.byKey(const Key('smart-tiles-new-preset')));
      await tester.pump();

      for (final stage in const <String>[
        '1. Objectif',
        '2. Image',
        '3. Découpage',
        '4. Peinture',
        '5. Tracé',
        '6. Options',
        '7. Associer',
        '8. Tester',
        '9. Enregistrer',
      ]) {
        expect(find.text(stage), findsOneWidget);
      }

      await tester.tap(find.byKey(const Key('smart-tiles-usage-path')));
      await tester.pump();
      expect(find.text('Chemin guidé'), findsOneWidget);
      for (final stage in const <String>[
        'Image',
        'Patron',
        'Remplir le patron',
        'Essai',
      ]) {
        expect(find.text(stage), findsOneWidget);
      }
      await tester.tap(find.byKey(const Key('smart-tiles-usage-next-step')));
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('smart-tiles-source-project-image')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('smart-tiles-choose-project-image')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('smart-tiles-source-tileset-erw-terrain-master')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('smart-tiles-picker-confirm-image')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('smart-tiles-next-step')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('smart-tiles-path-pattern-classic')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('smart-tiles-path-pattern-closedContour')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('smart-tiles-grid-advanced-fields')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('smart-tiles-toggle-grid-advanced')),
        findsNothing,
      );
    });

    testWidgets('opens the approved 3 by 3 plus 2 by 2 contour workbench', (
      tester,
    ) async {
      ProjectSmartTileAuthoringDraft? latestDraft;
      await _pumpQuickPathPatternStage(
        tester,
        onDraftChanged: (draft) => latestDraft = draft,
      );

      await tester.tap(
        find.byKey(const Key('smart-tiles-path-pattern-closedContour')),
      );
      await tester.pumpAndSettle();
      final next = find.byKey(const Key('smart-tiles-path-pattern-continue'));
      await _ensureWorkbenchTapTargetVisible(tester, next);
      await tester.tap(next);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('smart-tiles-path-primary-grid')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('smart-tiles-path-corner-grid')),
        findsOneWidget,
      );
      expect(find.text('0 / 13 morceaux associés'), findsOneWidget);
      expect(find.text('Aperçu automatique'), findsOneWidget);
      expect(find.byKey(const Key('smart-tiles-library-column')), findsNothing);
      expect(
        find.byKey(const Key('smart-tiles-inspector-column')),
        findsNothing,
      );
      expect(find.byKey(const Key('smart-tiles-open-library')), findsOneWidget);
      expect(
        find.byKey(const Key('smart-tiles-open-inspector')),
        findsOneWidget,
      );
      expect(latestDraft?.topology, SmartTileTopology.wangCorner4);
      expect(latestDraft?.templateHint, SmartTileTemplateHint.corner12);
      expect(latestDraft?.lastStage, SmartTileAuthoringStage.forms);
    });

    testWidgets(
      'maps the selected contour piece and advances to the next one',
      (tester) async {
        ProjectSmartTileAuthoringDraft? latestDraft;
        await _pumpQuickPathPatternStage(
          tester,
          onDraftChanged: (draft) => latestDraft = draft,
        );
        await tester.tap(
          find.byKey(const Key('smart-tiles-path-pattern-closedContour')),
        );
        await tester.pumpAndSettle();
        final next = find.byKey(const Key('smart-tiles-path-pattern-continue'));
        await _ensureWorkbenchTapTargetVisible(tester, next);
        await tester.tap(next);
        await tester.pumpAndSettle();

        const firstMask = smartTileSouthEastBit;
        const secondMask = smartTileSouthWestBit | smartTileSouthEastBit;
        final firstSlot = find.byKey(
          const Key('smart-tiles-path-slot-$firstMask'),
        );
        await _ensureWorkbenchTapTargetVisible(tester, firstSlot);
        await tester.tap(firstSlot);
        await tester.pump();

        final atlas = find.byKey(const Key('smart-tiles-atlas-viewport'));
        await _tapAtlasDisplay(tester, atlas, const Offset(8, 8));
        await tester.pumpAndSettle();

        expect(find.text('1 / 13 morceaux associés'), findsOneWidget);
        expect(
          tester
              .widget<PokeMapSelectableTile>(
                find.byKey(const Key('smart-tiles-path-slot-$secondMask')),
              )
              .selected,
          isTrue,
        );
        expect(
          latestDraft!.rules.map(
            (rule) => smartTileMaskForSignature(
              rule.signature,
              topology: latestDraft!.topology,
            ),
          ),
          contains(firstMask),
        );
        expect(find.byType(SmartTileSpritePreview), findsWidgets);
        final previews = tester.widgetList<SmartTileSpritePreview>(
          find.byType(SmartTileSpritePreview),
        );
        expect(
          previews.any(
            (preview) => preview.atlases.any(
              (atlas) => atlas.id == preview.frame.atlasId,
            ),
          ),
          isTrue,
        );
      },
    );

    testWidgets('prepares one paint material for a simple path', (
      tester,
    ) async {
      await _pumpGridStage(
        tester,
        loader: _FakeSmartTileAtlasImageLoader(width: 320, height: 192),
      );
      await _confirmGridAndOpenMaterials(tester);

      expect(find.text('Votre chemin est prêt à être peint'), findsOneWidget);
      final next = tester.widget<PokeMapButton>(
        find.byKey(const Key('smart-tiles-materials-next-step')),
      );
      expect(next.onPressed, isNotNull);
    });

    testWidgets('keeps technical path choices behind optional controls', (
      tester,
    ) async {
      await _pumpGridStage(
        tester,
        loader: _FakeSmartTileAtlasImageLoader(width: 320, height: 192),
      );
      await _confirmGridAndOpenMaterials(tester);

      final materialsNext = find.byKey(
        const Key('smart-tiles-materials-next-step'),
      );
      await tester.ensureVisible(materialsNext);
      await tester.tap(materialsNext);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('smart-tiles-connection-organic')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('smart-tiles-connection-none')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('smart-tiles-toggle-connections-advanced')),
        findsOneWidget,
      );

      final connectionsNext = find.byKey(
        const Key('smart-tiles-connections-next-step'),
      );
      await _ensureWorkbenchTapTargetVisible(tester, connectionsNext);
      await tester.tap(connectionsNext);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('smart-tiles-transform-quarter-turns')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('smart-tiles-toggle-variants-advanced')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('smart-tiles-variants-next-step')),
        findsOneWidget,
      );
    });

    testWidgets('authors a reusable pattern through the no-code workbench', (
      tester,
    ) async {
      ProjectSmartTilePattern? savedPattern;
      await _pumpPanel(
        tester,
        _manifest(
          presets: const <ProjectSmartTilePreset>[],
          tilesets: const <ProjectTilesetEntry>[
            ProjectTilesetEntry(
              id: 'tileset',
              name: 'Tileset',
              relativePath: 'assets/tileset.png',
            ),
          ],
          atlases: const <ProjectSmartTileAtlas>[
            ProjectSmartTileAtlas(
              id: 'atlas',
              name: 'Atlas',
              tilesetId: 'tileset',
              columns: 2,
              rows: 2,
            ),
          ],
        ),
        projectRootPath: '/virtual/project',
        imageLoader: _FakeSmartTileAtlasImageLoader(width: 64, height: 64),
        onUpsertPattern: (pattern) async => savedPattern = pattern,
      );

      await tester.tap(find.byKey(const Key('smart-tiles-new-pattern')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('smart-tiles-pattern-editor')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('smart-tiles-pattern-name')),
        'Détail de sol',
      );
      final tiled = find.byKey(const Key('smart-tiles-pattern-repeat-tiled'));
      final workbenchScrollable = find
          .descendant(
            of: find.byKey(const Key('smart-tiles-workbench-column')),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        tiled,
        300,
        scrollable: workbenchScrollable,
      );
      await tester.drag(workbenchScrollable, const Offset(0, -120));
      await tester.pump();
      await tester.tap(tiled);
      await tester.pump();
      final save = find.byKey(const Key('smart-tiles-pattern-save'));
      await tester.scrollUntilVisible(
        save,
        300,
        scrollable: workbenchScrollable,
      );
      await tester.drag(workbenchScrollable, const Offset(0, -80));
      await tester.pump();
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(savedPattern, isNotNull);
      expect(savedPattern!.id, 'motif');
      expect(savedPattern!.name, 'Détail de sol');
      expect(savedPattern!.repeatMode, SmartTilePatternRepeatMode.tiled);
      expect(savedPattern!.cells, hasLength(1));
    });

    testWidgets('offers the recognizable ERW guide after source setup', (
      tester,
    ) async {
      await _pumpGridStage(
        tester,
        loader: _FakeSmartTileAtlasImageLoader(width: 1760, height: 2304),
      );
      await _confirmGridAndOpenConnections(tester);

      expect(
        find.byKey(const Key('smart-tiles-guide-erwCorner16')),
        findsOneWidget,
      );
      expect(find.text('Guide ERW 16'), findsWidgets);
      expect(find.text('0x00'), findsNothing);
    });

    testWidgets('loads a real-sized atlas and keeps its grid editable', (
      tester,
    ) async {
      final loader = _FakeSmartTileAtlasImageLoader(width: 1760, height: 2304);
      await _pumpGridStage(tester, loader: loader);

      expect(loader.lastTilesetId, _target.id);
      expect(find.textContaining('55 colonnes × 72 lignes'), findsOneWidget);
      expect(
        find.byKey(const Key('smart-tiles-grid-advanced-fields')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const Key('smart-tiles-toggle-grid-advanced')),
      );
      await tester.pumpAndSettle();
      final cellWidth = find.byKey(const Key('smart-tiles-cell-width'));
      expect(cellWidth, findsOneWidget);

      await tester.ensureVisible(cellWidth);
      await tester.enterText(cellWidth, '48');
      await tester.pump();

      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: cellWidth,
                matching: find.byType(EditableText),
              ),
            )
            .controller
            .text,
        '48',
      );
      expect(find.textContaining('36 colonnes × 72 lignes'), findsOneWidget);
    });

    testWidgets('keeps detected geometry pending until explicit confirmation', (
      tester,
    ) async {
      ProjectSmartTileAuthoringDraft? latestDraft;
      await _pumpGridStage(
        tester,
        loader: _FakeSmartTileAtlasImageLoader(width: 1760, height: 2304),
        onDraftChanged: (draft) => latestDraft = draft,
        usage: SmartTileUsage.terrain,
      );

      expect(
        find.byKey(const Key('smart-tiles-atlas-viewport')),
        findsOneWidget,
      );
      expect(latestDraft, isNotNull);
      expect(latestDraft!.lastStage, SmartTileAuthoringStage.grid);
      expect(latestDraft!.sourceTilesetIds, <String>[_target.id]);
      expect(latestDraft!.atlases, isEmpty);
      expect(latestDraft!.primaryAtlasId, isNull);

      final confirm = find.byKey(const Key('smart-tiles-confirm-grid'));
      await tester.ensureVisible(confirm);
      await tester.pumpAndSettle();
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(latestDraft!.lastStage, SmartTileAuthoringStage.materials);
      expect(latestDraft!.atlases, hasLength(1));
      expect(latestDraft!.primaryAtlasId, latestDraft!.atlases.single.id);
      expect(latestDraft!.atlases.single.tilesetId, _target.id);
    });

    testWidgets('authors allowed, default, and active materials separately', (
      tester,
    ) async {
      ProjectSmartTileAuthoringDraft? latestDraft;
      await _pumpGridStage(
        tester,
        loader: _FakeSmartTileAtlasImageLoader(width: 1760, height: 2304),
        onDraftChanged: (draft) => latestDraft = draft,
      );
      await _confirmGridAndOpenMaterials(tester);

      final next = find.byKey(const Key('smart-tiles-materials-next-step'));
      expect(tester.widget<PokeMapButton>(next).onPressed, isNotNull);
      expect(latestDraft!.materials.single.name, 'Chemin');

      final dirt = find.byKey(const Key('smart-tiles-material-dirt'));
      await tester.ensureVisible(dirt);
      await tester.tap(dirt);
      await tester.pump();

      expect(latestDraft!.allowedMaterialIds, <String>[
        'smart-tile-material-chemin',
        'dirt',
      ]);
      expect(latestDraft!.defaultMaterialId, 'smart-tile-material-chemin');
      await tester.tap(
        find.byKey(const Key('smart-tiles-material-default-dirt')),
      );
      await tester.pump();
      expect(latestDraft!.defaultMaterialId, 'dirt');
      expect(find.text('Par défaut'), findsOneWidget);
      expect(tester.widget<PokeMapButton>(next).onPressed, isNotNull);

      final grass = find.byKey(const Key('smart-tiles-material-grass'));
      await tester.ensureVisible(grass);
      await tester.tap(grass);
      await tester.pump();

      expect(latestDraft!.allowedMaterialIds, <String>[
        'smart-tile-material-chemin',
        'dirt',
        'grass',
      ]);
      expect(latestDraft!.defaultMaterialId, 'dirt');
      expect(
        tester
            .widget<PokeMapAssetCard>(
              find.byKey(const Key('smart-tiles-material-grass')),
            )
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const Key('smart-tiles-material-toggle-dirt')),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('creates a named material without exposing its canonical id', (
      tester,
    ) async {
      ProjectSmartTileAuthoringDraft? latestDraft;
      await _pumpGridStage(
        tester,
        loader: _FakeSmartTileAtlasImageLoader(width: 1760, height: 2304),
        onDraftChanged: (draft) => latestDraft = draft,
      );
      await _confirmGridAndOpenMaterials(tester);

      final name = find.byKey(const Key('smart-tiles-new-material-name'));
      await tester.ensureVisible(name);
      await tester.enterText(name, 'Sable doux');
      await tester.pump();
      final create = find.byKey(const Key('smart-tiles-create-material'));
      await tester.tap(create);
      await tester.pump();

      final material = latestDraft!.materials.singleWhere(
        (candidate) => candidate.name == 'Sable doux',
      );
      expect(material.id, 'smart-tile-material-sable-doux');
      expect(latestDraft!.defaultMaterialId, 'smart-tile-material-chemin');
      expect(find.text('Sable doux'), findsOneWidget);
      expect(find.text('smart-tile-material-sable-doux'), findsNothing);
    });

    testWidgets('offers six profiles and configures a custom topology', (
      tester,
    ) async {
      ProjectSmartTileAuthoringDraft? latestDraft;
      await _pumpGridStage(
        tester,
        loader: _FakeSmartTileAtlasImageLoader(width: 1760, height: 2304),
        onDraftChanged: (draft) => latestDraft = draft,
      );
      await _confirmGridAndOpenConnections(tester);
      await tester.tap(
        find.byKey(const Key('smart-tiles-toggle-connections-advanced')),
      );
      await tester.pumpAndSettle();

      for (final profile in <String>[
        'none',
        'borders',
        'corners',
        'organic',
        'bordersAndCorners',
        'custom',
      ]) {
        expect(
          find.byKey(Key('smart-tiles-connection-$profile')),
          findsOneWidget,
        );
      }
      expect(find.text('Recommandé'), findsOneWidget);
      expect(latestDraft!.topology, SmartTileTopology.blob8);
      expect(
        tester
            .widget<PokeMapAssetCard>(
              find.byKey(const Key('smart-tiles-connection-organic')),
            )
            .selected,
        isTrue,
      );

      final custom = find.byKey(const Key('smart-tiles-connection-custom'));
      await _ensureWorkbenchTapTargetVisible(tester, custom);
      await tester.tap(custom);
      await tester.pump();
      final next = find.byKey(const Key('smart-tiles-connections-next-step'));
      await tester.ensureVisible(next);
      expect(tester.widget<PokeMapButton>(next).onPressed, isNull);

      final cardinal = find.byKey(
        const Key('smart-tiles-custom-topology-cardinal4'),
      );
      await tester.ensureVisible(cardinal);
      await tester.tap(cardinal);
      await tester.pumpAndSettle();

      expect(latestDraft!.topology, SmartTileTopology.cardinal4);
      expect(latestDraft!.templateHint, SmartTileTemplateHint.free);
      expect(tester.widget<PokeMapButton>(next).onPressed, isNotNull);
    });

    testWidgets('makes filled versus paintable coverage an explicit choice', (
      tester,
    ) async {
      ProjectSmartTileAuthoringDraft? latestDraft;
      await _pumpGridStage(
        tester,
        loader: _FakeSmartTileAtlasImageLoader(width: 1760, height: 2304),
        onDraftChanged: (draft) => latestDraft = draft,
      );
      await _confirmGridAndOpenConnections(tester);

      final complete = find.byKey(const Key('smart-tiles-coverage-complete'));
      final sparse = find.byKey(const Key('smart-tiles-coverage-sparse'));
      expect(complete, findsOneWidget);
      expect(sparse, findsOneWidget);
      expect(tester.widget<PokeMapAssetCard>(sparse).selected, isTrue);

      await tester.ensureVisible(complete);
      await tester.tap(complete);
      await tester.pumpAndSettle();

      expect(latestDraft!.coveragePolicy, SmartTileCoveragePolicy.complete);
      expect(tester.widget<PokeMapAssetCard>(complete).selected, isTrue);
    });

    testWidgets('adopts a canonically imported project image', (tester) async {
      var imports = 0;
      final importedImage = _fakeImage(width: 96, height: 64);
      final manifest = _manifest(
        presets: const [],
        tilesets: const <ProjectTilesetEntry>[_target],
      );
      await _pumpPanel(
        tester,
        manifest,
        projectRootPath: '/tmp/erw-project',
        onImportProjectImage: () async {
          imports += 1;
          return SmartTileSourceImportResult(
            manifest: manifest,
            tileset: _target,
            image: importedImage,
            assetId: 'asset-erw',
          );
        },
      );
      await _startPathImage(tester);
      await tester.tap(
        find.byKey(const Key('smart-tiles-source-project-image')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('smart-tiles-import-project-image')),
      );
      await tester.pumpAndSettle();

      expect(imports, 1);
      expect(
        find.byKey(const Key('smart-tiles-source-image-preview')),
        findsOneWidget,
      );
      expect(find.text('96 × 64 px'), findsOneWidget);
      final next = tester.widget<PokeMapButton>(
        find.byKey(const Key('smart-tiles-next-step')),
      );
      expect(next.onPressed, isNotNull);
    });

    testWidgets('shows canonical import failures without advancing', (
      tester,
    ) async {
      await _pumpPanel(
        tester,
        _manifest(presets: const []),
        projectRootPath: '/tmp/erw-project',
        onImportProjectImage: () async =>
            throw const SmartTileSourceImportException(
              'smart_tile.source_not_image',
              'Le fichier sélectionné n’est pas une image reconnue.',
            ),
      );
      await _startPathImage(tester);
      await tester.tap(
        find.byKey(const Key('smart-tiles-source-project-image')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('smart-tiles-import-project-image')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('smart-tiles-source-error')), findsOneWidget);
      expect(
        find.text('Le fichier sélectionné n’est pas une image reconnue.'),
        findsOneWidget,
      );
      final next = tester.widget<PokeMapButton>(
        find.byKey(const Key('smart-tiles-next-step')),
      );
      expect(next.onPressed, isNull);
    });

    testWidgets('one valid anchor associates and overlays all sixteen cells', (
      tester,
    ) async {
      await _pumpGuidedAtlas(
        tester,
        loader: _FakeSmartTileAtlasImageLoader(width: 1760, height: 2304),
      );

      final viewport = find.byKey(const Key('smart-tiles-atlas-viewport'));
      await tester.ensureVisible(viewport);
      await _tapVisibleValidAnchor(tester, viewport);
      await tester.pump();

      expect(
        find.byKey(const Key('smart-tiles-guide-overlay')),
        findsOneWidget,
      );
      expect(find.textContaining('16 cellules associées'), findsWidgets);
      expect(find.textContaining('prêt pour le banc d’essai'), findsOneWidget);
      expect(find.text('0x00'), findsNothing);
    });

    testWidgets('lets one suggested cell be corrected from the atlas', (
      tester,
    ) async {
      await _pumpGuidedAtlas(
        tester,
        loader: _FakeSmartTileAtlasImageLoader(width: 1760, height: 2304),
        surfaceSize: const Size(1440, 1800),
      );

      final viewport = find.byKey(const Key('smart-tiles-atlas-viewport'));
      await tester.ensureVisible(viewport);
      await _tapVisibleValidAnchor(tester, viewport);
      await tester.pump();

      final correction = find.byKey(const Key('smart-tiles-correction-7'));
      await tester.ensureVisible(correction);
      await tester.tap(correction);
      await tester.pump();
      await tester.ensureVisible(viewport);
      await tester.tapAt(tester.getTopLeft(viewport) + const Offset(140, 110));
      await tester.pump();

      expect(find.text('Case 7 corrigée.'), findsOneWidget);
      expect(find.text('16 cellules • 12 raccords'), findsOneWidget);
      expect(
        find.byKey(const Key('smart-tiles-guide-overlay')),
        findsOneWidget,
      );
    });

    testWidgets(
      'rejects the whole guide when its anchor is too close to edge',
      (tester) async {
        await _pumpGuidedAtlas(
          tester,
          loader: _FakeSmartTileAtlasImageLoader(width: 1760, height: 2304),
        );

        final viewport = find.byKey(const Key('smart-tiles-atlas-viewport'));
        await _ensureWorkbenchTapTargetVisible(
          tester,
          viewport,
          localOffset: const Offset(3, 3),
        );
        await tester.tapAt(tester.getTopLeft(viewport) + const Offset(3, 3));
        await tester.pump();

        expect(find.textContaining('Le guide dépasse l’atlas'), findsOneWidget);
        expect(find.text('0 cellules • 0 raccords'), findsOneWidget);
        expect(
          find.byKey(const Key('smart-tiles-guide-overlay')),
          findsNothing,
        );
      },
    );

    testWidgets('emits a canonical draft and exposes the real publication', (
      tester,
    ) async {
      ProjectSmartTileAuthoringDraft? durableDraft;
      await _pumpGuidedAtlas(
        tester,
        loader: _FakeSmartTileAtlasImageLoader(width: 1760, height: 2304),
        onDraftChanged: (next) => durableDraft = next,
      );
      final viewport = find.byKey(const Key('smart-tiles-atlas-viewport'));
      await tester.ensureVisible(viewport);
      await _tapVisibleValidAnchor(tester, viewport);
      await tester.pump();

      final toTest = find.byKey(const Key('smart-tiles-mapping-next-step'));
      await tester.ensureVisible(toTest);
      await tester.pumpAndSettle();
      await tester.tap(toTest);
      await tester.pump();
      expect(find.text('12 / 12 résolus'), findsOneWidget);
      expect(find.text('Aucune forme manquante'), findsOneWidget);
      expect(find.text('4 variantes supplémentaires'), findsOneWidget);

      final toPublish = find.byKey(const Key('smart-tiles-go-to-publish'));
      await tester.ensureVisible(toPublish);
      await tester.pumpAndSettle();
      await tester.tap(toPublish);
      await tester.pump();
      expect(find.text('Prêt à planifier'), findsOneWidget);
      expect(
        find.text('16 cellules • 12 raccords • 4 variantes'),
        findsOneWidget,
      );

      final publish = find.byKey(const Key('smart-tiles-publish-plan'));
      await tester.ensureVisible(publish);
      await tester.pumpAndSettle();
      final publishButton = tester.widget<PokeMapButton>(publish);
      expect(publishButton.onPressed, isNotNull);
      await tester.tap(publish);
      await tester.pump();

      expect(durableDraft, isNotNull);
      expect(durableDraft!.lastStage, SmartTileAuthoringStage.publish);
      expect(durableDraft!.rules, hasLength(12));
      expect(
        find.text('smart_tile.publish.session_unavailable'),
        findsOneWidget,
      );
    });

    testWidgets('authors D4 transforms and animations without exposing ids', (
      tester,
    ) async {
      ProjectSmartTileAuthoringDraft? latestDraft;
      await _openVariantsWithoutGuide(
        tester,
        loader: _FakeSmartTileAtlasImageLoader(width: 1760, height: 2304),
        onDraftChanged: (draft) => latestDraft = draft,
      );
      await _jumpWorkbenchToTop(tester);

      final quarterTurnsSwitch = find.descendant(
        of: find.byKey(const Key('smart-tiles-transform-quarter-turns')),
        matching: find.byType(CupertinoSwitch),
      );
      await tester.ensureVisible(quarterTurnsSwitch);
      await tester.pumpAndSettle();
      await tester.tap(quarterTurnsSwitch);
      await tester.pump();
      expect(latestDraft!.transformPolicy.allowQuarterTurns, isFalse);
      expect(
        find.byKey(const Key('smart-tiles-transform-proposal')),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('smart-tiles-transform-horizontal-flip')),
          matching: find.byType(CupertinoSwitch),
        ),
      );
      await tester.pump();

      expect(latestDraft!.transformPolicy.allowQuarterTurns, isFalse);
      expect(latestDraft!.transformPolicy.allowHFlip, isFalse);
      expect(
        find.text('8 orientation(s) réellement autorisée(s)'),
        findsOneWidget,
      );
      expect(find.text('Formes gagnées (0)'), findsOneWidget);
      expect(find.text('Formes perdues (0)'), findsOneWidget);

      final discard = find.byKey(const Key('smart-tiles-transform-discard'));
      await tester.ensureVisible(discard);
      await tester.pumpAndSettle();
      await tester.tap(discard);
      await tester.pump();
      expect(
        find.byKey(const Key('smart-tiles-transform-proposal')),
        findsNothing,
      );
      expect(
        find.text('1 orientation(s) réellement autorisée(s)'),
        findsOneWidget,
      );

      await tester.ensureVisible(quarterTurnsSwitch);
      await tester.pumpAndSettle();
      await tester.tap(quarterTurnsSwitch);
      await tester.pump();
      expect(latestDraft!.transformPolicy.allowQuarterTurns, isFalse);
      expect(
        find.text('4 orientation(s) réellement autorisée(s)'),
        findsOneWidget,
      );
      var accept = find.byKey(const Key('smart-tiles-transform-accept'));
      await tester.ensureVisible(accept);
      await tester.pumpAndSettle();
      await tester.tap(accept);
      await tester.pump();
      expect(latestDraft!.transformPolicy.allowQuarterTurns, isTrue);

      await tester.ensureVisible(quarterTurnsSwitch);
      await tester.pumpAndSettle();
      await tester.tap(quarterTurnsSwitch);
      await tester.pump();
      expect(latestDraft!.transformPolicy.allowQuarterTurns, isTrue);
      expect(
        find.text('1 orientation(s) réellement autorisée(s)'),
        findsOneWidget,
      );
      accept = find.byKey(const Key('smart-tiles-transform-accept'));
      await tester.ensureVisible(accept);
      await tester.pumpAndSettle();
      await tester.tap(accept);
      await tester.pump();
      expect(latestDraft!.transformPolicy.allowQuarterTurns, isFalse);

      final viewport = find.byKey(const Key('smart-tiles-atlas-viewport'));
      await tester.ensureVisible(viewport);
      await tester.pumpAndSettle();
      await _tapAtlasDisplay(tester, viewport, const Offset(2, 2));
      await _tapAtlasDisplay(tester, viewport, const Offset(9, 2));
      expect(find.text('Image 1'), findsOneWidget);
      expect(find.text('Image 2'), findsOneWidget);

      final name = find.byKey(const Key('smart-tiles-animation-name'));
      final duration = find.byKey(const Key('smart-tiles-animation-duration'));
      await tester.ensureVisible(name);
      await tester.enterText(name, 'Herbe au vent');
      await tester.enterText(duration, '120');
      await tester.pump();
      final create = find.byKey(const Key('smart-tiles-create-animation'));
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pump();

      expect(latestDraft!.animations, hasLength(1));
      final animation = latestDraft!.animations.single;
      expect(animation.name, 'Herbe au vent');
      expect(animation.frames, hasLength(2));
      expect(
        animation.frames.every((frame) => frame.durationMs == 120),
        isTrue,
      );
      expect(find.text('Herbe au vent'), findsOneWidget);
      expect(find.text(animation.id), findsNothing);
    });

    testWidgets('resumes a persisted grid draft and reloads its source image', (
      tester,
    ) async {
      const tileset = ProjectTilesetEntry(
        id: 'resumable-source',
        name: 'Source reprise',
        relativePath: 'assets/resumable.png',
      );
      const draft = ProjectSmartTileAuthoringDraft(
        id: 'resumable-draft',
        targetPresetId: 'resumable-preset',
        name: 'Terrain à reprendre',
        usage: SmartTileUsage.terrain,
        lastStage: SmartTileAuthoringStage.grid,
        sourceTilesetIds: <String>['resumable-source'],
        atlases: <ProjectSmartTileAtlas>[
          ProjectSmartTileAtlas(
            id: 'resumable-atlas',
            name: 'Atlas repris',
            tilesetId: 'resumable-source',
            cellWidth: 32,
            cellHeight: 32,
            columns: 10,
            rows: 6,
          ),
        ],
        primaryAtlasId: 'resumable-atlas',
        topology: SmartTileTopology.cardinal4,
        templateHint: SmartTileTemplateHint.edge16,
      );
      final loader = _FakeSmartTileAtlasImageLoader(width: 320, height: 192);

      await _pumpPanel(
        tester,
        _manifest(
          tilesets: const <ProjectTilesetEntry>[tileset],
          drafts: <ProjectSmartTileAuthoringDraft>[draft],
        ),
        projectRootPath: '/tmp/resumable-project',
        imageLoader: loader,
      );

      expect(find.text('Terrain à reprendre'), findsWidgets);
      expect(find.textContaining('Brouillon à reprendre'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('smart-tiles-library-item-draft:resumable-draft')),
      );
      await tester.pumpAndSettle();

      expect(loader.lastTilesetId, 'resumable-source');
      expect(find.text('Vérifier le découpage en tuiles'), findsOneWidget);
      expect(find.text('Le découpage est correct'), findsOneWidget);
      expect(find.text('Brouillon repris'), findsOneWidget);
    });

    testWidgets('previews gained and lost forms before accepting transforms', (
      tester,
    ) async {
      const tileset = ProjectTilesetEntry(
        id: 'transform-source',
        name: 'Source transformations',
        relativePath: 'assets/transforms.png',
      );
      final draft = ProjectSmartTileAuthoringDraft(
        id: 'transform-draft',
        targetPresetId: 'transform-preset',
        name: 'Chemin orienté',
        usage: SmartTileUsage.path,
        lastStage: SmartTileAuthoringStage.variants,
        sourceTilesetIds: <String>['transform-source'],
        atlases: <ProjectSmartTileAtlas>[
          const ProjectSmartTileAtlas(
            id: 'transform-atlas',
            name: 'Atlas transformations',
            tilesetId: 'transform-source',
            columns: 4,
            rows: 4,
          ),
        ],
        primaryAtlasId: 'transform-atlas',
        defaultMaterialId: 'dirt',
        allowedMaterialIds: <String>['dirt'],
        topology: SmartTileTopology.cardinal4,
        templateHint: SmartTileTemplateHint.free,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        coverageProfile: const SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.explicit,
        ),
        rules: <SmartTileRule>[
          SmartTileRule(
            id: 'north',
            centerMatch: const SmartTileSlotMatch.any(),
            signature: smartTileSignatureForMask(
              smartTileNorthBit,
              topology: SmartTileTopology.cardinal4,
            ),
            candidates: const <SmartTileCandidate>[
              SmartTileCandidate(
                id: 'north-visual',
                parts: <SmartTileVisualPart>[
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.frame(
                      frame: SmartTileFrameRef(
                        atlasId: 'transform-atlas',
                        column: 0,
                        row: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      ProjectSmartTileAuthoringDraft? latestDraft;
      await _pumpPanel(
        tester,
        _manifest(
          tilesets: const <ProjectTilesetEntry>[tileset],
          drafts: <ProjectSmartTileAuthoringDraft>[draft],
        ),
        projectRootPath: '/tmp/transform-project',
        imageLoader: _FakeSmartTileAtlasImageLoader(width: 128, height: 128),
        onDraftChanged: (value) => latestDraft = value,
      );
      await tester.tap(
        find.byKey(const Key('smart-tiles-library-item-draft:transform-draft')),
      );
      await tester.pumpAndSettle();
      await _jumpWorkbenchToTop(tester);
      await tester.tap(
        find.byKey(const Key('smart-tiles-toggle-variants-advanced')),
      );
      await tester.pumpAndSettle();

      final quarterTurns = find.descendant(
        of: find.byKey(const Key('smart-tiles-transform-quarter-turns')),
        matching: find.byType(CupertinoSwitch),
      );
      await tester.ensureVisible(quarterTurns);
      await tester.pumpAndSettle();
      await tester.tap(quarterTurns);
      await tester.pump();

      expect(latestDraft!.transformPolicy.allowQuarterTurns, isFalse);
      expect(find.text('Formes gagnées (3)'), findsOneWidget);
      expect(find.text('Formes perdues (0)'), findsOneWidget);
      expect(find.text('Extrémité est'), findsOneWidget);
      expect(find.text('Extrémité sud'), findsOneWidget);
      expect(find.text('Extrémité ouest'), findsOneWidget);
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const Key('smart-tiles-variants-next-step')),
            )
            .onPressed,
        isNull,
      );

      var accept = find.byKey(const Key('smart-tiles-transform-accept'));
      await tester.ensureVisible(accept);
      await tester.pumpAndSettle();
      await tester.tap(accept);
      await tester.pump();
      expect(latestDraft!.transformPolicy.allowQuarterTurns, isTrue);

      await tester.ensureVisible(quarterTurns);
      await tester.pumpAndSettle();
      await tester.tap(quarterTurns);
      await tester.pump();
      expect(find.text('Formes gagnées (0)'), findsOneWidget);
      expect(find.text('Formes perdues (3)'), findsOneWidget);
      final discard = find.byKey(const Key('smart-tiles-transform-discard'));
      await tester.ensureVisible(discard);
      await tester.pumpAndSettle();
      await tester.tap(discard);
      await tester.pump();
      expect(latestDraft!.transformPolicy.allowQuarterTurns, isTrue);
      expect(
        find.byKey(const Key('smart-tiles-transform-proposal')),
        findsNothing,
      );
    });

    testWidgets('maps a form then manages exact weighted variants', (
      tester,
    ) async {
      ProjectSmartTileAuthoringDraft? latestDraft;
      await _openFormsWithoutGuide(
        tester,
        loader: _FakeSmartTileAtlasImageLoader(width: 1760, height: 2304),
        onDraftChanged: (draft) => latestDraft = draft,
      );

      final form = find.byKey(const Key('smart-tiles-form-0'));
      await _ensureWorkbenchTapTargetVisible(tester, form);
      await tester.tap(form);
      await tester.pump();
      final viewport = find.byKey(const Key('smart-tiles-atlas-viewport'));
      await tester.ensureVisible(viewport);
      await tester.pumpAndSettle();
      await _tapAtlasDisplay(tester, viewport, const Offset(2, 2));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await _tapAtlasDisplay(tester, viewport, const Offset(9, 2));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      var candidates = latestDraft!.rules.single.candidates;
      expect(candidates, hasLength(2));
      expect(find.text('50 %'), findsNWidgets(2));
      final firstId = candidates.first.id;
      final secondId = candidates.last.id;
      final weight = find.byKey(Key('smart-tiles-weight-$firstId'));
      await tester.ensureVisible(weight);
      await tester.enterText(weight, '3');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      candidates = latestDraft!.rules.single.candidates;
      expect(candidates.first.weight, 3);
      expect(find.text('75 %'), findsOneWidget);
      expect(find.text('25 %'), findsOneWidget);

      final moveDown = find.byKey(Key('smart-tiles-variant-down-$firstId'));
      await tester.ensureVisible(moveDown);
      await tester.tap(moveDown);
      await tester.pump();
      expect(
        latestDraft!.rules.single.candidates.map((item) => item.id),
        <String>[secondId, firstId],
      );

      final remove = find.byKey(Key('smart-tiles-variant-remove-$firstId'));
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pump();
      expect(latestDraft!.rules.single.candidates.single.id, secondId);
      _expectNoTechnicalMaskText(tester);
    });

    testWidgets('selects and edits a rectangular multi-cell atlas frame', (
      tester,
    ) async {
      ProjectSmartTileAuthoringDraft? latestDraft;
      await _openFormsWithoutGuide(
        tester,
        loader: _FakeSmartTileAtlasImageLoader(width: 1760, height: 2304),
        onDraftChanged: (draft) => latestDraft = draft,
      );

      final form = find.byKey(const Key('smart-tiles-form-0'));
      await _ensureWorkbenchTapTargetVisible(tester, form);
      await tester.tap(form);
      await tester.pump();
      final rectangle = find.byKey(
        const Key('smart-tiles-atlas-selection-rectangle'),
      );
      await _ensureWorkbenchTapTargetVisible(tester, rectangle);
      await tester.tap(rectangle);
      await tester.pump();

      final viewport = find.byKey(const Key('smart-tiles-atlas-viewport'));
      await tester.ensureVisible(viewport);
      await tester.pumpAndSettle();
      await _tapAtlasDisplay(tester, viewport, const Offset(2, 2));
      expect(
        find.byKey(const Key('smart-tiles-atlas-selection-size')),
        findsOneWidget,
      );
      await _tapAtlasDisplay(tester, viewport, const Offset(40, 40));

      var part = latestDraft!.rules.single.candidates.single.parts.single;
      final frame = (part.source as SmartTileFrameSource).frame;
      expect(frame.columnSpan, greaterThan(1));
      expect(frame.rowSpan, greaterThan(1));
      expect(part.footprintWidth, frame.columnSpan);
      expect(part.footprintHeight, frame.rowSpan);

      final candidateId = latestDraft!.rules.single.candidates.single.id;
      final anchorY = find.byKey(
        Key('smart-tiles-geometry-$candidateId-0-anchorY'),
      );
      await tester.ensureVisible(anchorY);
      await tester.enterText(anchorY, '24');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      part = latestDraft!.rules.single.candidates.single.parts.single;
      expect(part.anchorY, 24);
    });

    testWidgets('authors an exact multi-material transition without Wang ids', (
      tester,
    ) async {
      const tileset = ProjectTilesetEntry(
        id: 'multi-source',
        name: 'Source multi-matières',
        relativePath: 'assets/multi.png',
      );
      const draft = ProjectSmartTileAuthoringDraft(
        id: 'multi-draft',
        targetPresetId: 'multi-preset',
        name: 'Raccord multi-matières',
        usage: SmartTileUsage.path,
        lastStage: SmartTileAuthoringStage.forms,
        sourceTilesetIds: <String>['multi-source'],
        atlases: <ProjectSmartTileAtlas>[
          ProjectSmartTileAtlas(
            id: 'multi-atlas',
            name: 'Atlas multi-matières',
            tilesetId: 'multi-source',
            columns: 4,
            rows: 4,
          ),
        ],
        primaryAtlasId: 'multi-atlas',
        materials: <ProjectSmartTileMaterial>[
          ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Herbe',
            connectionGroupId: 'grass',
          ),
          ProjectSmartTileMaterial(
            id: 'water',
            name: 'Eau',
            connectionGroupId: 'water',
          ),
          ProjectSmartTileMaterial(
            id: 'stone',
            name: 'Pierre',
            connectionGroupId: 'stone',
          ),
        ],
        defaultMaterialId: 'grass',
        allowedMaterialIds: <String>['grass', 'water', 'stone'],
        topology: SmartTileTopology.wangEdge4,
        templateHint: SmartTileTemplateHint.edge16,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.explicit,
        ),
      );
      ProjectSmartTileAuthoringDraft? latestDraft;
      await _pumpPanel(
        tester,
        _manifest(
          tilesets: const <ProjectTilesetEntry>[tileset],
          drafts: const <ProjectSmartTileAuthoringDraft>[draft],
        ),
        projectRootPath: '/tmp/multi-project',
        imageLoader: _FakeSmartTileAtlasImageLoader(width: 128, height: 128),
        onDraftChanged: (value) => latestDraft = value,
      );
      await tester.tap(
        find.byKey(const Key('smart-tiles-library-item-draft:multi-draft')),
      );
      await tester.pumpAndSettle();
      await _jumpWorkbenchToTop(tester);

      final add = find.byKey(const Key('smart-tiles-transition-add'));
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();

      final north = find.byKey(
        const Key('smart-tiles-transition-transition_case_1-northEdge'),
      );
      await tester.ensureVisible(north);
      await tester.tap(north);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eau').last);
      await tester.pumpAndSettle();

      final east = find.byKey(
        const Key('smart-tiles-transition-transition_case_1-eastEdge'),
      );
      await tester.ensureVisible(east);
      await tester.tap(east);
      await tester.pumpAndSettle();
      final stoneOption = find.text('Pierre').last;
      await tester.ensureVisible(stoneOption);
      await tester.pumpAndSettle();
      await tester.tap(stoneOption);
      await tester.pumpAndSettle();

      final viewport = find.byKey(const Key('smart-tiles-atlas-viewport'));
      await tester.ensureVisible(viewport);
      await tester.pumpAndSettle();
      await _tapAtlasDisplay(tester, viewport, const Offset(2, 2));

      final rule = latestDraft!.rules.single;
      expect(rule.centerMatch.materialId, 'grass');
      expect(rule.signature.northEdge.materialId, 'water');
      expect(rule.signature.eastEdge.materialId, 'stone');
      expect(rule.candidates, hasLength(1));
      expect(find.text('Herbe'), findsWidgets);
      expect(find.text('Eau'), findsWidgets);
      expect(find.text('Pierre'), findsWidgets);
      expect(find.text('transition_case_1'), findsNothing);
      _expectNoTechnicalMaskText(tester);
    });

    testWidgets('maps an atlas cell back to the next human form', (
      tester,
    ) async {
      ProjectSmartTileAuthoringDraft? latestDraft;
      await _openFormsWithoutGuide(
        tester,
        loader: _FakeSmartTileAtlasImageLoader(width: 1760, height: 2304),
        onDraftChanged: (draft) => latestDraft = draft,
      );

      final viewport = find.byKey(const Key('smart-tiles-atlas-viewport'));
      await tester.ensureVisible(viewport);
      await tester.pumpAndSettle();
      await _tapAtlasDisplay(tester, viewport, const Offset(2, 2));
      expect(
        find.byKey(const Key('smart-tiles-clear-pending-frame')),
        findsOneWidget,
      );

      final form = find.byKey(const Key('smart-tiles-form-0'));
      final formSize = tester.getSize(form);
      final formTapOffset = Offset(formSize.width / 2, formSize.height - 12);
      await _ensureWorkbenchTapTargetVisible(
        tester,
        form,
        localOffset: formTapOffset,
      );
      await tester.tapAt(tester.getTopLeft(form) + formTapOffset);
      await tester.pump();

      expect(latestDraft!.rules, hasLength(1));
      expect(latestDraft!.rules.single.candidates, hasLength(1));
      expect(
        find.byKey(const Key('smart-tiles-clear-pending-frame')),
        findsNothing,
      );
      _expectNoTechnicalMaskText(tester);
    });

    testWidgets('disables a guide without deleting its prefilled mappings', (
      tester,
    ) async {
      ProjectSmartTileAuthoringDraft? latestDraft;
      await _pumpGuidedAtlas(
        tester,
        loader: _FakeSmartTileAtlasImageLoader(width: 1760, height: 2304),
        onDraftChanged: (draft) => latestDraft = draft,
      );
      final viewport = find.byKey(const Key('smart-tiles-atlas-viewport'));
      await tester.ensureVisible(viewport);
      await _tapVisibleValidAnchor(tester, viewport);
      await tester.pump();

      expect(latestDraft!.guideId, isNotNull);
      expect(latestDraft!.rules, hasLength(12));
      await _jumpWorkbenchToTop(tester);
      final disable = find.byKey(const Key('smart-tiles-disable-guide'));
      await tester.ensureVisible(disable);
      await tester.tap(disable);
      await tester.pump();

      expect(latestDraft!.guideId, isNull);
      expect(latestDraft!.rules, hasLength(12));
      expect(find.byKey(const Key('smart-tiles-guide-overlay')), findsNothing);
    });

    testWidgets('composes forest ground and canopy as visual channels', (
      tester,
    ) async {
      ProjectSmartTileAuthoringDraft? latestDraft;
      await _openFormsWithoutGuide(
        tester,
        loader: _FakeSmartTileAtlasImageLoader(width: 1760, height: 2304),
        onDraftChanged: (draft) => latestDraft = draft,
        usage: SmartTileUsage.forestSurface,
      );

      final form = find.byKey(const Key('smart-tiles-form-0'));
      await tester.ensureVisible(form);
      await tester.tap(form);
      await tester.pump();
      final viewport = find.byKey(const Key('smart-tiles-atlas-viewport'));
      await tester.ensureVisible(viewport);
      await _tapAtlasDisplay(tester, viewport, const Offset(2, 2));
      final canopy = find.byKey(const Key('smart-tiles-channel-canopy'));
      await tester.ensureVisible(canopy);
      await tester.tap(canopy);
      await tester.pump();
      await tester.ensureVisible(viewport);
      await _tapAtlasDisplay(tester, viewport, const Offset(9, 2));

      final parts = latestDraft!.rules.single.candidates.single.parts;
      expect(
        parts.map((part) => part.channel),
        containsAll(<Object?>[
          SmartTileRenderChannel.ground,
          SmartTileRenderChannel.canopy,
        ]),
      );
    });

    testWidgets('test bench resolves every canonical Edge 16 scenario', (
      tester,
    ) async {
      await _pumpPanel(tester, _completeManifest());

      await tester.tap(find.byKey(const Key('smart-tiles-tab-testBench')));
      await tester.pump();

      expect(find.text('16 / 16 résolus'), findsOneWidget);
      expect(find.byKey(const Key('smart-tiles-compact-lab')), findsOneWidget);
      final lab = find.byKey(const Key('smart-tiles-compact-lab'));
      await tester.ensureVisible(lab);
      await tester.tapAt(tester.getTopLeft(lab) + const Offset(168, 168));
      await tester.pump();
      expect(
        find.byKey(const Key('smart-tiles-lab-inspection')),
        findsOneWidget,
      );
      expect(find.text('Résolue'), findsOneWidget);
      _expectNoTechnicalMaskText(tester);
    });

    testWidgets('manual bench exposes dedicated Wang lattices', (tester) async {
      await _pumpPanel(
        tester,
        _manifest(
          presets: const <ProjectSmartTilePreset>[
            ProjectSmartTilePreset(
              id: 'wang-path',
              name: 'Wang path',
              usage: SmartTileUsage.path,
              topology: SmartTileTopology.wangEdge4,
              templateHint: SmartTileTemplateHint.edge16,
              coveragePolicy: SmartTileCoveragePolicy.sparse,
              coverageProfile: SmartTileCoverageProfile(
                mode: SmartTileCoverageMode.template,
              ),
              transformPolicy: SmartTileTransformPolicy(),
              defaultMaterialId: 'dirt',
              allowedMaterialIds: <String>['dirt'],
            ),
          ],
        ),
      );

      await tester.tap(find.byKey(const Key('smart-tiles-tab-testBench')));
      await tester.pump();

      expect(find.byKey(const Key('smart-tiles-compact-lab')), findsOneWidget);
      expect(
        find.byKey(const Key('smart-tiles-wang-manual-bench-deferred')),
        findsNothing,
      );
      expect(find.textContaining('arêtes horizontales'), findsOneWidget);
    });

    testWidgets('validation reports an existing draft without a fake gate', (
      tester,
    ) async {
      await _pumpPanel(tester, _completeManifest());

      await tester.tap(find.byKey(const Key('smart-tiles-tab-validation')));
      await tester.pump();
      expect(find.byKey(const Key('smart-tiles-publish')), findsNothing);
      expect(find.text('Brouillon valide'), findsOneWidget);
      expect(find.textContaining('STN-04'), findsNothing);
    });
  });
}

const _target = ProjectTilesetEntry(
  id: 'erw-terrain-master',
  name: 'ERW Terrain Master',
  relativePath: 'assets/erw/terrain_master.png',
);

Future<void> _startPathImage(WidgetTester tester) async {
  await _startUsageImage(tester, SmartTileUsage.path);
}

Future<void> _pumpQuickPathPatternStage(
  WidgetTester tester, {
  ValueChanged<ProjectSmartTileAuthoringDraft>? onDraftChanged,
}) async {
  await _pumpPanel(
    tester,
    _manifest(
      presets: const <ProjectSmartTilePreset>[],
      tilesets: const <ProjectTilesetEntry>[_target],
    ),
    projectRootPath: '/tmp/erw-project',
    imageLoader: _FakeSmartTileAtlasImageLoader(width: 320, height: 192),
    onDraftChanged: onDraftChanged,
  );
  await _startPathImage(tester);
  await tester.tap(find.byKey(const Key('smart-tiles-source-project-image')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('smart-tiles-choose-project-image')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const Key('smart-tiles-source-tileset-erw-terrain-master')),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('smart-tiles-picker-confirm-image')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('smart-tiles-next-step')));
  await tester.pumpAndSettle();
}

Future<void> _startUsageImage(WidgetTester tester, SmartTileUsage usage) async {
  await tester.tap(find.byKey(const Key('smart-tiles-new-preset')));
  await tester.pump();
  await tester.tap(find.byKey(Key('smart-tiles-usage-${usage.name}')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('smart-tiles-usage-next-step')));
  await tester.pump();
}

Future<void> _openVariantsWithoutGuide(
  WidgetTester tester, {
  required SmartTileAtlasImageLoader loader,
  ValueChanged<ProjectSmartTileAuthoringDraft>? onDraftChanged,
  SmartTileUsage usage = SmartTileUsage.path,
}) async {
  await _pumpGridStage(
    tester,
    loader: loader,
    onDraftChanged: onDraftChanged,
    usage: usage,
  );
  await _confirmGridAndOpenConnections(tester);
  if (usage == SmartTileUsage.path) {
    await tester.tap(
      find.byKey(const Key('smart-tiles-toggle-connections-advanced')),
    );
    await tester.pumpAndSettle();
  }
  final noConnections = find.byKey(const Key('smart-tiles-connection-none'));
  await tester.ensureVisible(noConnections);
  await tester.tap(noConnections);
  await tester.pumpAndSettle();
  final next = find.byKey(const Key('smart-tiles-connections-next-step'));
  await tester.ensureVisible(next);
  await tester.pumpAndSettle();
  await tester.tap(next);
  await tester.pumpAndSettle();
  if (usage == SmartTileUsage.path) {
    await tester.tap(
      find.byKey(const Key('smart-tiles-toggle-variants-advanced')),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _openFormsWithoutGuide(
  WidgetTester tester, {
  required SmartTileAtlasImageLoader loader,
  ValueChanged<ProjectSmartTileAuthoringDraft>? onDraftChanged,
  SmartTileUsage usage = SmartTileUsage.path,
}) async {
  await _openVariantsWithoutGuide(
    tester,
    loader: loader,
    onDraftChanged: onDraftChanged,
    usage: usage,
  );
  final next = find.byKey(const Key('smart-tiles-variants-next-step'));
  await tester.ensureVisible(next);
  await tester.pumpAndSettle();
  await tester.tap(next);
  await tester.pumpAndSettle();
}

Future<void> _pumpGuidedAtlas(
  WidgetTester tester, {
  required SmartTileAtlasImageLoader loader,
  ValueChanged<ProjectSmartTileAuthoringDraft>? onDraftChanged,
  Size surfaceSize = const Size(1440, 900),
}) async {
  await _pumpGridStage(
    tester,
    loader: loader,
    onDraftChanged: onDraftChanged,
    surfaceSize: surfaceSize,
  );
  await _confirmGridAndOpenConnections(tester);
  final guide = find.byKey(const Key('smart-tiles-guide-erwCorner16'));
  await tester.ensureVisible(guide);
  await tester.pumpAndSettle();
  await tester.tap(guide);
  await tester.pumpAndSettle();
  final connectionsNext = find.byKey(
    const Key('smart-tiles-connections-next-step'),
  );
  await tester.ensureVisible(connectionsNext);
  await tester.pumpAndSettle();
  await tester.tap(connectionsNext);
  await tester.pumpAndSettle();
  final variantsNext = find.byKey(const Key('smart-tiles-variants-next-step'));
  await tester.ensureVisible(variantsNext);
  await tester.pumpAndSettle();
  await tester.tap(variantsNext);
  await tester.pumpAndSettle();
}

Future<void> _pumpGridStage(
  WidgetTester tester, {
  required SmartTileAtlasImageLoader loader,
  ValueChanged<ProjectSmartTileAuthoringDraft>? onDraftChanged,
  Future<SmartTileSourceImportResult?> Function()? onImportProjectImage,
  Size surfaceSize = const Size(1440, 900),
  SmartTileUsage usage = SmartTileUsage.path,
}) async {
  await _pumpPanel(
    tester,
    _manifest(
      presets: const [],
      tilesets: const <ProjectTilesetEntry>[_target],
    ),
    projectRootPath: '/tmp/erw-project',
    imageLoader: loader,
    onDraftChanged: onDraftChanged,
    onImportProjectImage: onImportProjectImage,
    surfaceSize: surfaceSize,
  );
  await _startUsageImage(tester, usage);
  await tester.tap(find.byKey(const Key('smart-tiles-source-project-image')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('smart-tiles-choose-project-image')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const Key('smart-tiles-source-tileset-erw-terrain-master')),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('smart-tiles-picker-confirm-image')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('smart-tiles-next-step')));
  await tester.pump();
  final customPath = find.byKey(const Key('smart-tiles-path-pattern-custom'));
  if (usage == SmartTileUsage.path && customPath.evaluate().isNotEmpty) {
    await tester.tap(customPath);
    await tester.pumpAndSettle();
  }
}

Future<void> _confirmGridAndOpenConnections(WidgetTester tester) async {
  await _confirmGridAndOpenMaterials(tester);
  final material = find.byKey(const Key('smart-tiles-material-dirt'));
  await tester.ensureVisible(material);
  await tester.tap(material);
  await tester.pumpAndSettle();
  final materialsNext = find.byKey(
    const Key('smart-tiles-materials-next-step'),
  );
  await tester.ensureVisible(materialsNext);
  await tester.pumpAndSettle();
  await tester.tap(materialsNext);
  await tester.pumpAndSettle();
}

Future<void> _confirmGridAndOpenMaterials(WidgetTester tester) async {
  final confirm = find.byKey(const Key('smart-tiles-confirm-grid'));
  await tester.ensureVisible(confirm);
  await tester.pumpAndSettle();
  await tester.tap(confirm);
  await tester.pumpAndSettle();
}

Future<void> _tapVisibleValidAnchor(
  WidgetTester tester,
  Finder viewport,
) async {
  final size = tester.getSize(viewport);
  final localOffset = Offset(size.width / 2, 80);
  await _ensureWorkbenchTapTargetVisible(
    tester,
    viewport,
    localOffset: localOffset,
  );
  await tester.tapAt(tester.getTopLeft(viewport) + localOffset);
}

Future<void> _tapAtlasDisplay(
  WidgetTester tester,
  Finder viewport,
  Offset localOffset,
) async {
  await _ensureWorkbenchTapTargetVisible(
    tester,
    viewport,
    localOffset: localOffset,
  );
  await tester.tapAt(tester.getTopLeft(viewport) + localOffset);
  await tester.pump();
}

Future<void> _ensureWorkbenchTapTargetVisible(
  WidgetTester tester,
  Finder target, {
  Offset? localOffset,
}) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  final list = find
      .descendant(
        of: find.byKey(const Key('smart-tiles-workbench-column')),
        matching: find.byType(ListView),
      )
      .first;
  final targetRect = tester.getRect(target);
  final listRect = tester.getRect(list);
  final point =
      targetRect.topLeft +
      (localOffset ?? Offset(targetRect.width / 2, targetRect.height / 2));
  final safeTop = listRect.top + 8;
  final safeBottom = listRect.bottom - 8;
  final dragY = point.dy < safeTop
      ? safeTop - point.dy
      : point.dy > safeBottom
      ? safeBottom - point.dy
      : 0.0;
  if (dragY != 0) {
    await tester.drag(list, Offset(0, dragY));
    await tester.pumpAndSettle();
  }
  final size = tester.getSize(target);
  final offset = localOffset ?? Offset(size.width / 2, size.height / 2);
  final alignment = Alignment(
    offset.dx / size.width * 2 - 1,
    offset.dy / size.height * 2 - 1,
  );
  expect(target.hitTestable(at: alignment), findsOneWidget);
}

Future<void> _jumpWorkbenchToTop(WidgetTester tester) async {
  final listView = find
      .descendant(
        of: find.byKey(const Key('smart-tiles-workbench-column')),
        matching: find.byType(ListView),
      )
      .first;
  await tester.fling(listView, const Offset(0, 1000), 3000);
  await tester.pumpAndSettle();
}

void _expectNoTechnicalMaskText(WidgetTester tester) {
  final visibleTexts = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data ?? '')
      .join('\n');
  expect(visibleTexts, isNot(contains(RegExp(r'0x[0-9a-fA-F]+'))));
  expect(
    visibleTexts,
    isNot(contains(RegExp(r'mask[_ -]?\d', caseSensitive: false))),
  );
}

Future<void> _pumpPanel(
  WidgetTester tester,
  ProjectManifest manifest, {
  ValueChanged<ProjectSmartTileAuthoringDraft>? onDraftChanged,
  String? projectRootPath,
  SmartTileAtlasImageLoader imageLoader = const FileSmartTileAtlasImageLoader(),
  Future<SmartTileSourceImportResult?> Function()? onImportProjectImage,
  Future<SmartTileTiledWangSource?> Function()? onPickTiledWangSource,
  Future<SmartTileTiledWangImportResult> Function(
    SmartTileTiledWangSource source,
    List<TiledWangSetSelection> selections,
  )?
  onImportTiledWang,
  bool isCapturedMapAvailable = false,
  MapData? capturedMap,
  SmartTileReconstructionService? reconstructionService,
  Future<void> Function(SmartTileReconstructionResult result)?
  onReconstructionApplied,
  Future<void> Function(ProjectSmartTilePreset preset)? onPublishExistingPreset,
  Future<void> Function(ProjectSmartTilePreset preset)? onUpdatePreset,
  Future<void> Function(ProjectSmartTilePreset preset)? onDuplicatePreset,
  Future<void> Function(ProjectSmartTilePreset preset)? onDeletePreset,
  Future<bool> Function(ProjectSmartTilePreset preset)?
  onAddPresetToCapturedMap,
  Future<void> Function(ProjectSmartTilePattern pattern)? onUpsertPattern,
  Size surfaceSize = const Size(1440, 900),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MacosApp(
      home: CupertinoPageScaffold(
        child: SmartTilesStudioPanel(
          manifest: manifest,
          projectRootPath: projectRootPath,
          imageLoader: imageLoader,
          onImportProjectImage: onImportProjectImage,
          onPickTiledWangSource: onPickTiledWangSource,
          onImportTiledWang: onImportTiledWang,
          onDraftChanged: onDraftChanged,
          isCapturedMapAvailable: isCapturedMapAvailable,
          capturedMap: capturedMap,
          reconstructionService: reconstructionService,
          onReconstructionApplied: onReconstructionApplied,
          presetActions: SmartTilePresetLibraryActions(
            publish: onPublishExistingPreset,
            update: onUpdatePreset,
            duplicate: onDuplicatePreset,
            delete: onDeletePreset,
            addToMap: onAddPresetToCapturedMap,
          ),
          onUpsertPattern: onUpsertPattern,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _UnusedReconstructionGateway
    implements SmartTileReconstructionGateway {
  @override
  Future<SmartTileReconstructionCanonicalSnapshot> load({
    required String projectRootPath,
  }) => throw UnimplementedError();

  @override
  Future<SmartTileReconstructionCanonicalPlan> plan({
    required String projectRootPath,
    required Map<String, Object?> parameters,
    required String expectedRevision,
    required String idempotencyKey,
  }) => throw UnimplementedError();

  @override
  Future<String> confirmAndApply({
    required SmartTileReconstructionCanonicalPlan plan,
    required String operationId,
  }) => throw UnimplementedError();
}

const _literalCapturedMap = MapData(
  id: 'captured',
  name: 'Captured',
  version: ProjectVersion.v6,
  size: GridSize(width: 1, height: 1),
  layers: <MapLayer>[
    MapLayer.tile(
      id: 'literal',
      name: 'Literal',
      palette: <TileLayerPaletteEntry>[
        TileLayerPaletteEntry(tilesetId: 'tileset', localTileId: 0),
      ],
      cells: <int>[1],
    ),
  ],
);

final _tiledWangSource = SmartTileTiledWangSource(
  tsxPath: '/outside/road.tsx',
  imagePath: '/outside/road.png',
  imagePaths: const <String, String>{'road.png': '/outside/road.png'},
  displayName: 'road.tsx',
  tsx: _tiledWangTsx,
  importId: 'road-import',
  tilesetDocument: parseTiledTileset(_tiledWangTsx),
  document: parseTiledWangTileset(_tiledWangTsx),
);

const _tiledWangTsx = '''
<tileset name="Road" tilewidth="16" tileheight="16" tilecount="1" columns="1">
  <image source="road.png" width="16" height="16"/>
  <wangsets>
    <wangset name="Road" type="edge" tile="-1">
      <wangcolor name="Road" color="#c8a162" tile="0" probability="1"/>
      <wangtile tileid="0" wangid="1,0,1,0,1,0,1,0"/>
    </wangset>
  </wangsets>
</tileset>
''';

ProjectManifest _completeManifest({bool animated = false}) {
  final preset = ProjectSmartTilePreset(
    id: 'edge',
    name: 'Edge 16',
    usage: SmartTileUsage.terrain,
    topology: SmartTileTopology.cardinal4,
    templateHint: SmartTileTemplateHint.edge16,
    status: SmartTilePresetStatus.draft,
    coveragePolicy: SmartTileCoveragePolicy.complete,
    coverageProfile: const SmartTileCoverageProfile(
      mode: SmartTileCoverageMode.template,
    ),
    transformPolicy: const SmartTileTransformPolicy(),
    defaultMaterialId: 'grass',
    allowedMaterialIds: const <String>['grass'],
    rules: <SmartTileRule>[
      for (var mask = 0; mask < 16; mask++)
        SmartTileRule(
          id: smartTileCanonicalRuleId(mask),
          centerMatch: const SmartTileSlotMatch.any(),
          signature: smartTileSignatureForMask(
            mask,
            topology: SmartTileTopology.cardinal4,
          ),
          candidates: <SmartTileCandidate>[
            SmartTileCandidate(
              id: 'visual',
              parts: <SmartTileVisualPart>[
                SmartTileVisualPart(
                  source: animated
                      ? const SmartTileVisualSource.animation(
                          animationId: 'edge-wind',
                        )
                      : const SmartTileVisualSource.frame(
                          frame: SmartTileFrameRef(
                            atlasId: 'atlas',
                            column: 0,
                            row: 0,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
    ],
  );
  return ProjectManifest(
    name: 'Complete Smart Tiles test',
    version: ProjectVersion.v6,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'tileset',
        name: 'Tileset',
        relativePath: 'assets/tileset.png',
      ),
    ],
    smartTileCatalog: ProjectSmartTileCatalog(
      atlases: const <ProjectSmartTileAtlas>[
        ProjectSmartTileAtlas(
          id: 'atlas',
          name: 'Atlas',
          tilesetId: 'tileset',
          columns: 4,
          rows: 4,
        ),
      ],
      materials: const <ProjectSmartTileMaterial>[
        ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Grass',
          connectionGroupId: 'grass',
        ),
      ],
      animations: <ProjectSmartTileAnimation>[
        if (animated)
          const ProjectSmartTileAnimation(
            id: 'edge-wind',
            name: 'Edge wind',
            frames: <ProjectSmartTileAnimationFrame>[
              ProjectSmartTileAnimationFrame(
                frame: SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
                durationMs: 167,
              ),
            ],
          ),
      ],
      presets: <ProjectSmartTilePreset>[preset],
    ),
  );
}

ProjectManifest _manifest({
  List<ProjectSmartTilePreset> presets = const <ProjectSmartTilePreset>[
    ProjectSmartTilePreset(
      id: 'hanazuki-path',
      name: 'Chemin Hanazuki',
      usage: SmartTileUsage.path,
      topology: SmartTileTopology.blob8,
      coveragePolicy: SmartTileCoveragePolicy.complete,
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.template,
      ),
      transformPolicy: SmartTileTransformPolicy(),
      defaultMaterialId: 'dirt',
      allowedMaterialIds: <String>['dirt'],
      status: SmartTilePresetStatus.published,
    ),
  ],
  List<ProjectTilesetEntry> tilesets = const <ProjectTilesetEntry>[],
  List<ProjectSmartTileAuthoringDraft> drafts =
      const <ProjectSmartTileAuthoringDraft>[],
  List<ProjectSmartTileAtlas> atlases = const <ProjectSmartTileAtlas>[],
  List<ProjectSmartTilePattern> patterns = const <ProjectSmartTilePattern>[],
}) {
  return ProjectManifest(
    name: 'Smart Tiles test',
    version: ProjectVersion.v6,
    maps: const <ProjectMapEntry>[],
    tilesets: tilesets,
    smartTileCatalog: ProjectSmartTileCatalog(
      materials: const <ProjectSmartTileMaterial>[
        ProjectSmartTileMaterial(
          id: 'dirt',
          name: 'Dirt',
          connectionGroupId: 'ground',
        ),
        ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Grass',
          connectionGroupId: 'ground',
        ),
        ProjectSmartTileMaterial(
          id: 'forest',
          name: 'Forest',
          connectionGroupId: 'forest',
        ),
      ],
      presets: presets,
      drafts: drafts,
      atlases: atlases,
      patterns: patterns,
    ),
  );
}

const _importedWangPreset = ProjectSmartTilePreset(
  id: 'road-import-w0-preset',
  name: 'Road',
  usage: SmartTileUsage.path,
  topology: SmartTileTopology.cardinal4,
  templateHint: SmartTileTemplateHint.edge16,
  status: SmartTilePresetStatus.draft,
  coveragePolicy: SmartTileCoveragePolicy.sparse,
  coverageProfile: SmartTileCoverageProfile(
    mode: SmartTileCoverageMode.explicit,
  ),
  transformPolicy: SmartTileTransformPolicy(),
  defaultMaterialId: 'dirt',
  allowedMaterialIds: <String>['dirt'],
  tags: <String>['imported', 'tiled-wang'],
);

final class _FakeSmartTileAtlasImageLoader
    implements SmartTileAtlasImageLoader {
  _FakeSmartTileAtlasImageLoader({required this.width, required this.height});

  final int width;
  final int height;
  String? lastTilesetId;

  @override
  Future<SmartTileAtlasImageLoadResult> load({
    required String? projectRootPath,
    required ProjectTilesetEntry tileset,
  }) async {
    lastTilesetId = tileset.id;
    return SmartTileAtlasImageLoadResult(
      status: SmartTileAtlasImageLoadStatus.loaded,
      message: 'loaded',
      image: SmartTileAtlasImage(
        absolutePath: '$projectRootPath/${tileset.relativePath}',
        bytes: _onePixelPng,
        width: width,
        height: height,
        columnAlphaCoverage: List<double>.filled(width, 1),
        rowAlphaCoverage: List<double>.filled(height, 1),
      ),
    );
  }
}

SmartTileAtlasImage _fakeImage({required int width, required int height}) =>
    SmartTileAtlasImage(
      absolutePath: '/tmp/erw-project/${_target.relativePath}',
      bytes: _onePixelPng,
      width: width,
      height: height,
      columnAlphaCoverage: List<double>.filled(width, 1),
      rowAlphaCoverage: List<double>.filled(height, 1),
    );

final Uint8List _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
  '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
