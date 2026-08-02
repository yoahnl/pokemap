import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_atlas_image_loader.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_authoring_controller.dart';
import 'package:map_editor/src/features/smart_tiles_studio/presentation/smart_tiles_studio_panel.dart';
import 'package:map_editor/src/ui/design_system/pokemap_button.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

void main() {
  group('SmartTilesStudioPanel', () {
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
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('smart-tiles-workbench-column')),
        findsOneWidget,
      );
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

    testWidgets('keeps add-to-active-map disabled until STN-03',
        (tester) async {
      ProjectSmartTilePreset? addedToMap;
      await _pumpPanel(
        tester,
        _manifest(),
        onAddToActiveMap: (preset) => addedToMap = preset,
      );

      final finder = find.byKey(const Key('smart-tiles-add-to-active-map'));
      final button = tester.widget<PokeMapButton>(finder);
      expect(button.onPressed, isNull);
      expect(
        button.disabledReason,
        smartTileNativeCatalogAuthoringRequiresStn03Code,
      );
      expect(
        find.text(smartTileNativeCatalogAuthoringRequiresStn03Code),
        findsWidgets,
      );

      await tester.tap(finder);
      await tester.pump();
      expect(addedToMap, isNull);
    });

    testWidgets('starts the guided flow with human labels and no masks', (
      tester,
    ) async {
      await _pumpPanel(tester, _manifest(presets: const []));

      await tester.tap(find.byKey(const Key('smart-tiles-new-preset')));
      await tester.pump();

      expect(find.text('Nouveau Smart Tile'), findsOneWidget);
      expect(find.text('1. Usage'), findsOneWidget);
      expect(find.text('2. Guide'), findsOneWidget);
      expect(find.text('3. Placement'), findsOneWidget);
      expect(find.text('4. Essai'), findsOneWidget);
      expect(find.text('5. Publier'), findsOneWidget);
      expect(
        find.byKey(const Key('smart-tiles-usage-path')),
        findsOneWidget,
      );
      expect(find.text('0x00'), findsNothing);
    });

    testWidgets('offers the recognizable ERW guide after choosing Path', (
      tester,
    ) async {
      await _pumpPanel(tester, _manifest(presets: const []));
      await _startPathGuide(tester);

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
      await _pumpGuidedAtlas(tester, loader: loader);

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
      expect(find.textContaining('replacez la cellule nº 1'), findsOneWidget);
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

    testWidgets('keeps the guided preset in memory until STN-03', (
      tester,
    ) async {
      ProjectManifest? published;
      ProjectSmartTilePreset? addedToMap;
      await _pumpGuidedAtlas(
        tester,
        loader: _FakeSmartTileAtlasImageLoader(
          width: 1760,
          height: 2304,
        ),
        onManifestChanged: (next) => published = next,
        onAddToActiveMap: (preset) => addedToMap = preset,
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
      expect(find.text('Publication après STN-03'), findsOneWidget);
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
        smartTileNativeCatalogAuthoringRequiresStn03Code,
      );
      await tester.tap(publish);
      await tester.pump();

      expect(published, isNull);
      expect(addedToMap, isNull);
      expect(
        find.text(smartTileNativeCatalogAuthoringRequiresStn03Code),
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

    testWidgets('validation does not persist a preset before STN-03', (
      tester,
    ) async {
      ProjectManifest? published;
      await _pumpPanel(
        tester,
        _completeManifest(),
        onManifestChanged: (next) => published = next,
      );

      await tester.tap(find.byKey(const Key('smart-tiles-tab-validation')));
      await tester.pump();
      final publish = find.byKey(const Key('smart-tiles-publish'));
      final publishButton = tester.widget<PokeMapButton>(publish);
      expect(publishButton.onPressed, isNull);
      expect(
        publishButton.disabledReason,
        smartTileNativeCatalogAuthoringRequiresStn03Code,
      );
      await tester.tap(publish);
      await tester.pump();

      expect(published, isNull);
      expect(
        find.text(smartTileNativeCatalogAuthoringRequiresStn03Code),
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

Future<void> _startPathGuide(WidgetTester tester) async {
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
  ValueChanged<ProjectManifest>? onManifestChanged,
  ValueChanged<ProjectSmartTilePreset>? onAddToActiveMap,
  Size surfaceSize = const Size(1440, 900),
}) async {
  await _pumpPanel(
    tester,
    _manifest(
        presets: const [], tilesets: const <ProjectTilesetEntry>[_target]),
    projectRootPath: '/tmp/erw-project',
    imageLoader: loader,
    onManifestChanged: onManifestChanged,
    onAddToActiveMap: onAddToActiveMap,
    surfaceSize: surfaceSize,
  );
  await _startPathGuide(tester);
  await tester.tap(find.byKey(const Key('smart-tiles-guide-erwCorner16')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('smart-tiles-guide-next-step')));
  await tester.pump();
  await tester.tap(find.text('Image du projet'));
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
  ValueChanged<ProjectManifest>? onManifestChanged,
  ValueChanged<ProjectSmartTilePreset>? onAddToActiveMap,
  String? projectRootPath,
  SmartTileAtlasImageLoader imageLoader = const FileSmartTileAtlasImageLoader(),
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
          onManifestChanged: onManifestChanged,
          onAddToActiveMap: onAddToActiveMap,
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

final Uint8List _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
  '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
