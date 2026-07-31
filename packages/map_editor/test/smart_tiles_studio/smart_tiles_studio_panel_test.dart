import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_atlas_image_loader.dart';
import 'package:map_editor/src/features/smart_tiles_studio/presentation/smart_tiles_studio_panel.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
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
              defaultMaterialId: 'grass',
              allowedMaterialIds: <String>['grass'],
            ),
            ProjectSmartTilePreset(
              id: 'forest',
              name: 'Forêt Hanazuki',
              usage: SmartTileUsage.forestSurface,
              topology: SmartTileTopology.blob8,
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

    testWidgets('starts the five-step native preset flow at Source', (
      tester,
    ) async {
      await _pumpPanel(tester, _manifest(presets: const []));

      await tester.tap(find.byKey(const Key('smart-tiles-new-preset')));
      await tester.pump();

      expect(find.text('Nouveau Smart Tile'), findsOneWidget);
      expect(find.text('1. Source'), findsOneWidget);
      expect(find.text('2. Grille'), findsOneWidget);
      expect(find.text('3. Usage'), findsOneWidget);
      expect(find.text('4. Mapping'), findsOneWidget);
      expect(find.text('5. Test'), findsOneWidget);
      expect(find.text('Image du projet'), findsOneWidget);
      expect(find.text('Atlas enregistré'), findsOneWidget);
      expect(find.text('Preset vide'), findsOneWidget);
    });

    testWidgets(
      'requires an explicit searched project image and uses its dimensions',
      (tester) async {
        const target = ProjectTilesetEntry(
          id: 'erw-terrain-master',
          name: 'ERW Terrain Master',
          relativePath: 'assets/erw/terrain_master.png',
        );
        final tilesets = <ProjectTilesetEntry>[
          for (var index = 0; index < 4162; index += 1)
            ProjectTilesetEntry(
              id: 'fixture-$index',
              name: 'Fixture $index',
              relativePath: 'assets/fixture_$index.png',
            ),
          target,
        ];
        final loader = _FakeSmartTileAtlasImageLoader(
          width: 1760,
          height: 2304,
        );
        await _pumpPanel(
          tester,
          _manifest(presets: const [], tilesets: tilesets),
          projectRootPath: '/tmp/erw-project',
          imageLoader: loader,
        );

        await tester.tap(find.byKey(const Key('smart-tiles-new-preset')));
        await tester.pump();
        await tester.tap(find.text('Image du projet'));
        await tester.pump();

        expect(
          tester
              .widget<PokeMapButton>(
                find.byKey(const Key('smart-tiles-next-step')),
              )
              .onPressed,
          isNull,
        );
        await tester.tap(
          find.byKey(const Key('smart-tiles-choose-project-image')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('smart-tiles-source-picker')),
          findsOneWidget,
        );
        await tester.enterText(
          find.byKey(const Key('smart-tiles-source-search')),
          'terrain master',
        );
        await tester.pump();

        expect(
          find.byKey(
              const Key('smart-tiles-source-tileset-erw-terrain-master')),
          findsOneWidget,
        );
        expect(find.text('Fixture 0'), findsNothing);
        await tester.tap(
          find.byKey(
              const Key('smart-tiles-source-tileset-erw-terrain-master')),
        );
        await tester.pumpAndSettle();

        expect(loader.lastTilesetId, target.id);
        expect(find.text('1760 × 2304 px'), findsOneWidget);
        expect(find.text('55 × 72 cellules à 32 px'), findsOneWidget);
        expect(
          tester
              .widget<PokeMapButton>(
                find.byKey(const Key('smart-tiles-next-step')),
              )
              .onPressed,
          isNotNull,
        );

        await tester.tap(find.byKey(const Key('smart-tiles-next-step')));
        await tester.pump();
        expect(
          find.textContaining('55 × 72 cellules'),
          findsOneWidget,
        );
      },
    );

    testWidgets('maps a large atlas through one image-backed viewport', (
      tester,
    ) async {
      const target = ProjectTilesetEntry(
        id: 'erw-terrain-master',
        name: 'ERW Terrain Master',
        relativePath: 'assets/erw/terrain_master.png',
      );
      await _pumpPanel(
        tester,
        _manifest(presets: const [], tilesets: const [target]),
        projectRootPath: '/tmp/erw-project',
        imageLoader: _FakeSmartTileAtlasImageLoader(
          width: 1760,
          height: 2304,
        ),
      );
      await tester.tap(find.byKey(const Key('smart-tiles-new-preset')));
      await tester.pump();
      await tester.tap(find.text('Image du projet'));
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('smart-tiles-choose-project-image')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('smart-tiles-source-tileset-erw-terrain-master')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('smart-tiles-next-step')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('smart-tiles-grid-next-step')));
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('smart-tiles-usage-forestSurface')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('smart-tiles-usage-next-step')));
      await tester.pump();

      final viewport = find.byKey(const Key('smart-tiles-atlas-viewport'));
      expect(viewport, findsOneWidget);
      expect(
        find.byKey(const Key('smart-tiles-atlas-cell-0-0')),
        findsNothing,
      );
      expect(find.byType(PokeMapButton).evaluate().length, lessThan(100));

      await tester.tap(find.byKey(const Key('smart-tiles-mapping-mask-0')));
      await tester.pump();
      await tester.tapAt(tester.getCenter(viewport));
      await tester.pump();

      expect(find.text('1 signature mappée'), findsOneWidget);
    });

    testWidgets('keeps detected grid values directly editable', (tester) async {
      await _pumpPanel(tester, _manifest(presets: const []));
      await tester.tap(find.byKey(const Key('smart-tiles-new-preset')));
      await tester.pump();
      await tester.tap(find.text('Preset vide'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('smart-tiles-next-step')));
      await tester.pump();

      expect(find.text('Grille détectée'), findsOneWidget);
      final cellWidth = find.byKey(const Key('smart-tiles-cell-width'));
      expect(cellWidth, findsOneWidget);

      await tester.enterText(cellWidth, '48');
      await tester.pump();

      expect(
        tester
            .widget<EditableText>(find.descendant(
              of: cellWidth,
              matching: find.byType(EditableText),
            ))
            .controller
            .text,
        '48',
      );
    });

    testWidgets('authors Usage and Mapping after Source and Grid',
        (tester) async {
      await _pumpPanel(tester, _manifest(presets: const []));
      await tester.tap(find.byKey(const Key('smart-tiles-new-preset')));
      await tester.pump();
      await tester.tap(find.text('Preset vide'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('smart-tiles-next-step')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('smart-tiles-grid-next-step')));
      await tester.pump();

      expect(find.text('Choisir l’usage'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('smart-tiles-usage-forestSurface')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('smart-tiles-usage-next-step')));
      await tester.pump();

      expect(find.text('Mapping Blob 47'), findsOneWidget);
      expect(find.text('47 signatures attendues'), findsOneWidget);
      expect(
        find.byKey(const Key('smart-tiles-mapping-mask-0')),
        findsOneWidget,
      );
      final viewport = find.byKey(const Key('smart-tiles-atlas-viewport'));
      expect(viewport, findsOneWidget);

      await tester.tap(find.byKey(const Key('smart-tiles-mapping-mask-0')));
      await tester.pump();
      await tester.tapAt(tester.getTopLeft(viewport) + const Offset(4, 4));
      await tester.pump();

      expect(find.text('1 signature mappée'), findsOneWidget);
      expect(
        find.byKey(const Key('smart-tiles-add-canopy-part')),
        findsOneWidget,
      );
    });

    testWidgets('test bench resolves every canonical Edge 16 scenario',
        (tester) async {
      await _pumpPanel(tester, _completeManifest());

      await tester.tap(
        find.byKey(const Key('smart-tiles-tab-testBench')),
      );
      await tester.pump();

      expect(find.text('16 / 16 résolus'), findsOneWidget);
      expect(
        find.byKey(const Key('smart-tiles-test-cell-3-3')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('smart-tiles-test-cell-3-3')),
      );
      await tester.pump();
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const Key('smart-tiles-test-cell-3-3')),
            )
            .isSelected,
        isTrue,
      );
    });

    testWidgets('validation publishes only through the manifest callback',
        (tester) async {
      ProjectManifest? published;
      await _pumpPanel(
        tester,
        _completeManifest(),
        onManifestChanged: (next) => published = next,
      );

      await tester.tap(
        find.byKey(const Key('smart-tiles-tab-validation')),
      );
      await tester.pump();

      expect(find.text('Publication autorisée'), findsOneWidget);
      await tester.tap(find.byKey(const Key('smart-tiles-publish')));
      await tester.pump();

      expect(published, isNotNull);
      expect(
        published!.smartTileCatalog.presets.single.status,
        SmartTilePresetStatus.published,
      );
    });
  });
}

Future<void> _pumpPanel(
  WidgetTester tester,
  ProjectManifest manifest, {
  ValueChanged<ProjectManifest>? onManifestChanged,
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
    defaultMaterialId: 'grass',
    allowedMaterialIds: const <String>['grass'],
    rules: <SmartTileRule>[
      for (var mask = 0; mask < 16; mask++)
        SmartTileRule(
          id: smartTileCanonicalRuleId(mask),
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
    version: ProjectVersion.v4,
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
      defaultMaterialId: 'dirt',
      allowedMaterialIds: <String>['dirt'],
      status: SmartTilePresetStatus.published,
    ),
  ],
  List<ProjectTilesetEntry> tilesets = const <ProjectTilesetEntry>[],
}) {
  return ProjectManifest(
    name: 'Smart Tiles test',
    version: ProjectVersion.v4,
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
