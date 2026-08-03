import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_atlas_image_loader.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_authoring_controller.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_source_asset_import_service.dart';
import 'package:map_editor/src/features/smart_tiles_studio/presentation/smart_tiles_studio_panel.dart';
import 'package:map_editor/src/ui/design_system/pokemap_asset_card.dart';
import 'package:map_editor/src/ui/design_system/pokemap_button.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

void main() {
  group('SmartTilesStudioPanel', () {
    testWidgets('enables the three approved no-code usages', (
      tester,
    ) async {
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
      expect(find.text('Natif v5'), findsOneWidget);
    });

    testWidgets('adapts the studio shell without overflowing when narrow', (
      tester,
    ) async {
      await _pumpPanel(
        tester,
        _manifest(),
        surfaceSize: const Size(560, 760),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('smart-tiles-library-column')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('smart-tiles-workbench-column')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('smart-tiles-inspector-column')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('smart-tiles-open-library')),
        findsOneWidget,
      );
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
      await _pumpPanel(
        tester,
        _manifest(),
        surfaceSize: const Size(900, 760),
      );

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
      expect(
        find.byKey(const Key('smart-tiles-open-library')),
        findsNothing,
      );

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

    testWidgets('keeps add-to-active-map disabled until STN-04 wiring',
        (tester) async {
      await _pumpPanel(tester, _manifest());

      final finder = find.byKey(const Key('smart-tiles-add-to-active-map'));
      final button = tester.widget<PokeMapButton>(finder);
      expect(button.onPressed, isNull);
      expect(
        button.disabledReason,
        smartTileStudioAuthoringRequiresStn04Code,
      );
      expect(
        find.text(smartTileStudioAuthoringRequiresStn04Code),
        findsWidgets,
      );

      await tester.tap(finder);
      await tester.pump();
    });

    testWidgets('starts the guided flow with human labels and no masks', (
      tester,
    ) async {
      await _pumpPanel(tester, _manifest(presets: const []));

      await tester.tap(find.byKey(const Key('smart-tiles-new-preset')));
      await tester.pump();

      expect(find.text('Nouveau Smart Tile'), findsOneWidget);
      for (final stage in const <String>[
        '1. Usage',
        '2. Image',
        '3. Grille',
        '4. Matériaux',
        '5. Raccords',
        '6. Variantes',
        '7. Formes',
        '8. Essai',
        '9. Publier',
      ]) {
        expect(find.text(stage), findsOneWidget);
      }
      expect(
        find.byKey(const Key('smart-tiles-usage-path')),
        findsOneWidget,
      );
      expect(find.text('0x00'), findsNothing);
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
      final loader = _FakeSmartTileAtlasImageLoader(
        width: 1760,
        height: 2304,
      );
      await _pumpGridStage(tester, loader: loader);

      expect(loader.lastTilesetId, _target.id);
      expect(find.textContaining('55 × 72 cellules'), findsWidgets);
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
      expect(find.textContaining('36 × 72 cellules proposées'), findsOneWidget);
    });

    testWidgets('keeps detected geometry pending until explicit confirmation', (
      tester,
    ) async {
      ProjectSmartTileAuthoringDraft? latestDraft;
      await _pumpGridStage(
        tester,
        loader: _FakeSmartTileAtlasImageLoader(width: 1760, height: 2304),
        onDraftChanged: (draft) => latestDraft = draft,
      );

      expect(
          find.byKey(const Key('smart-tiles-atlas-viewport')), findsOneWidget);
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
      expect(tester.widget<PokeMapButton>(next).onPressed, isNull);

      final dirt = find.byKey(const Key('smart-tiles-material-dirt'));
      await tester.ensureVisible(dirt);
      await tester.tap(dirt);
      await tester.pump();

      expect(latestDraft!.allowedMaterialIds, <String>['dirt']);
      expect(latestDraft!.defaultMaterialId, 'dirt');
      expect(latestDraft!.materials.single.id, 'dirt');
      expect(find.text('Par défaut'), findsOneWidget);
      expect(tester.widget<PokeMapButton>(next).onPressed, isNotNull);

      final grass = find.byKey(const Key('smart-tiles-material-grass'));
      await tester.ensureVisible(grass);
      await tester.tap(grass);
      await tester.pump();

      expect(latestDraft!.allowedMaterialIds, <String>['dirt', 'grass']);
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

      expect(latestDraft!.materials.single.name, 'Sable doux');
      expect(
          latestDraft!.materials.single.id, 'smart-tile-material-sable-doux');
      expect(latestDraft!.defaultMaterialId, latestDraft!.materials.single.id);
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
      await tester.ensureVisible(custom);
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
        loader: _FakeSmartTileAtlasImageLoader(
          width: 1760,
          height: 2304,
        ),
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
        loader: _FakeSmartTileAtlasImageLoader(
          width: 1760,
          height: 2304,
        ),
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
      await tester.tapAt(
        tester.getTopLeft(viewport) + const Offset(140, 110),
      );
      await tester.pump();

      expect(find.text('Case 7 corrigée.'), findsOneWidget);
      expect(find.text('16 cellules • 12 raccords'), findsOneWidget);
      expect(
        find.byKey(const Key('smart-tiles-guide-overlay')),
        findsOneWidget,
      );
    });

    testWidgets('rejects the whole guide when its anchor is too close to edge',
        (
      tester,
    ) async {
      await _pumpGuidedAtlas(
        tester,
        loader: _FakeSmartTileAtlasImageLoader(
          width: 1760,
          height: 2304,
        ),
      );

      final viewport = find.byKey(const Key('smart-tiles-atlas-viewport'));
      await tester.ensureVisible(viewport);
      await tester.tapAt(tester.getTopLeft(viewport) + const Offset(3, 3));
      await tester.pump();

      expect(find.textContaining('Le guide dépasse l’atlas'), findsOneWidget);
      expect(find.text('0 cellules • 0 raccords'), findsOneWidget);
      expect(
        find.byKey(const Key('smart-tiles-guide-overlay')),
        findsNothing,
      );
    });

    testWidgets('emits a canonical draft while publication remains gated', (
      tester,
    ) async {
      ProjectSmartTileAuthoringDraft? durableDraft;
      await _pumpGuidedAtlas(
        tester,
        loader: _FakeSmartTileAtlasImageLoader(
          width: 1760,
          height: 2304,
        ),
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
      expect(find.text('Publication dans STN-04'), findsOneWidget);
      expect(
        find.text('16 cellules • 12 raccords • 4 variantes'),
        findsOneWidget,
      );

      final publish = find.byKey(const Key('smart-tiles-publish-guided'));
      await tester.ensureVisible(publish);
      await tester.pumpAndSettle();
      final publishButton = tester.widget<PokeMapButton>(publish);
      expect(publishButton.onPressed, isNull);
      expect(
        publishButton.disabledReason,
        smartTileStudioAuthoringRequiresStn04Code,
      );
      await tester.tap(publish);
      await tester.pump();

      expect(durableDraft, isNotNull);
      expect(durableDraft!.lastStage, SmartTileAuthoringStage.publish);
      expect(durableDraft!.rules, hasLength(12));
      expect(
        find.text(smartTileStudioAuthoringRequiresStn04Code),
        findsWidgets,
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

      await tester.tap(
        find.descendant(
          of: find.byKey(
            const Key('smart-tiles-transform-quarter-turns'),
          ),
          matching: find.byType(CupertinoSwitch),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byKey(
            const Key('smart-tiles-transform-horizontal-flip'),
          ),
          matching: find.byType(CupertinoSwitch),
        ),
      );
      await tester.pump();

      expect(latestDraft!.transformPolicy.allowQuarterTurns, isTrue);
      expect(latestDraft!.transformPolicy.allowHFlip, isTrue);
      expect(find.text('8 orientation(s) réellement autorisée(s)'),
          findsOneWidget);

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
          animation.frames.every((frame) => frame.durationMs == 120), isTrue);
      expect(find.text('Herbe au vent'), findsOneWidget);
      expect(find.text(animation.id), findsNothing);
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
      await tester.ensureVisible(form);
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
      expect(latestDraft!.rules.single.candidates.map((item) => item.id),
          <String>[secondId, firstId]);

      final remove = find.byKey(Key('smart-tiles-variant-remove-$firstId'));
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pump();
      expect(latestDraft!.rules.single.candidates.single.id, secondId);
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
      await tester.ensureVisible(form);
      await tester.tap(form);
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
          ]));
    });

    testWidgets('test bench resolves every canonical Edge 16 scenario', (
      tester,
    ) async {
      await _pumpPanel(tester, _completeManifest());

      await tester.tap(find.byKey(const Key('smart-tiles-tab-testBench')));
      await tester.pump();

      expect(find.text('16 / 16 résolus'), findsOneWidget);
      expect(
        find.byKey(const Key('smart-tiles-test-cell-3-3')),
        findsOneWidget,
      );
    });

    testWidgets('manual bench fails closed for dedicated Wang lattices', (
      tester,
    ) async {
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

      expect(
        find.byKey(const Key('smart-tiles-wang-manual-bench-deferred')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('smart-tiles-test-cell-3-3')),
        findsNothing,
      );
    });

    testWidgets('validation does not persist a preset before STN-04 wiring', (
      tester,
    ) async {
      await _pumpPanel(tester, _completeManifest());

      await tester.tap(find.byKey(const Key('smart-tiles-tab-validation')));
      await tester.pump();
      final publish = find.byKey(const Key('smart-tiles-publish'));
      final publishButton = tester.widget<PokeMapButton>(publish);
      expect(publishButton.onPressed, isNull);
      expect(
        publishButton.disabledReason,
        smartTileStudioAuthoringRequiresStn04Code,
      );
      await tester.tap(publish);
      await tester.pump();

      expect(
        find.text(smartTileStudioAuthoringRequiresStn04Code),
        findsWidgets,
      );
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

Future<void> _startUsageImage(
  WidgetTester tester,
  SmartTileUsage usage,
) async {
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
  final noConnections = find.byKey(const Key('smart-tiles-connection-none'));
  await tester.ensureVisible(noConnections);
  await tester.tap(noConnections);
  await tester.pumpAndSettle();
  final next = find.byKey(const Key('smart-tiles-connections-next-step'));
  await tester.ensureVisible(next);
  await tester.pumpAndSettle();
  await tester.tap(next);
  await tester.pumpAndSettle();
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
  final variantsNext = find.byKey(
    const Key('smart-tiles-variants-next-step'),
  );
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
        presets: const [], tilesets: const <ProjectTilesetEntry>[_target]),
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
  await tester.tap(find.byKey(const Key('smart-tiles-next-step')));
  await tester.pump();
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
  final topLeft = tester.getTopLeft(viewport);
  final size = tester.getSize(viewport);
  await tester.tapAt(topLeft + Offset(size.width / 2, 80));
}

Future<void> _tapAtlasDisplay(
  WidgetTester tester,
  Finder viewport,
  Offset localOffset,
) async {
  await tester.tapAt(tester.getTopLeft(viewport) + localOffset);
  await tester.pump();
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
          onDraftChanged: onDraftChanged,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProjectManifest _completeManifest() {
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
          candidates: const <SmartTileCandidate>[
            SmartTileCandidate(
              id: 'visual',
              parts: <SmartTileVisualPart>[
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
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
    version: ProjectVersion.v5,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'tileset',
        name: 'Tileset',
        relativePath: 'assets/tileset.png',
      ),
    ],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
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
}) {
  return ProjectManifest(
    name: 'Smart Tiles test',
    version: ProjectVersion.v5,
    maps: const <ProjectMapEntry>[],
    tilesets: tilesets,
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
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
    ),
  );
}

final class _FakeSmartTileAtlasImageLoader
    implements SmartTileAtlasImageLoader {
  _FakeSmartTileAtlasImageLoader({
    required this.width,
    required this.height,
  });

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
