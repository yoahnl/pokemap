import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
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
  await tester.tap(find.byKey(const Key('smart-tiles-new-preset')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('smart-tiles-usage-path')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('smart-tiles-usage-next-step')));
  await tester.pump();
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
  await tester.tap(find.byKey(const Key('smart-tiles-guide-erwCorner16')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('smart-tiles-guide-next-step')));
  await tester.pump();
}

Future<void> _pumpGridStage(
  WidgetTester tester, {
  required SmartTileAtlasImageLoader loader,
  ValueChanged<ProjectSmartTileAuthoringDraft>? onDraftChanged,
  Future<SmartTileSourceImportResult?> Function()? onImportProjectImage,
  Size surfaceSize = const Size(1440, 900),
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
  await _startPathImage(tester);
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
  final confirm = find.byKey(const Key('smart-tiles-confirm-grid'));
  await tester.ensureVisible(confirm);
  await tester.pumpAndSettle();
  await tester.tap(confirm);
  await tester.pumpAndSettle();
  final materialsNext = find.byKey(
    const Key('smart-tiles-materials-next-step'),
  );
  await tester.ensureVisible(materialsNext);
  await tester.pumpAndSettle();
  await tester.tap(materialsNext);
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
