import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_atlas_image_loader.dart';
import 'package:map_editor/src/features/smart_tiles_studio/presentation/smart_tile_pattern_editor.dart';
import 'package:map_editor/src/theme/theme.dart';

void main() {
  testWidgets('authors rectangle, anchor, usage, and repetition without ids',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    ProjectSmartTilePattern? saved;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            height: 1200,
            child: SmartTilePatternEditor(
              manifest: _manifest,
              projectRootPath: '/virtual/project',
              patternId: 'motif',
              imageLoader: const _MissingImageLoader(),
              isSaving: false,
              onCancel: () {},
              onSave: (pattern) async => saved = pattern,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('smart-tiles-pattern-name')),
      'Chemin compacté',
    );
    await tester.tap(
      find.byKey(const Key('smart-tiles-pattern-usage-path')),
    );

    final viewport =
        find.byKey(const Key('smart-tiles-pattern-atlas-viewport'));
    await tester.ensureVisible(viewport);
    Offset cellCenter(Rect rect, int column, int row) => Offset(
          rect.left + (column + 0.5) * rect.width / 4,
          rect.top + (row + 0.5) * rect.height / 3,
        );
    final firstRect = tester.getRect(viewport);
    await tester.tapAt(cellCenter(firstRect, 1, 0));
    await tester.pump();
    final secondRect = tester.getRect(viewport);
    await tester.tapAt(cellCenter(secondRect, 2, 1));
    await tester.pump();

    final anchorMode = find.byKey(const Key('smart-tiles-pattern-mode-anchor'));
    await tester.tap(anchorMode);
    await tester.pump();
    await tester.ensureVisible(viewport);
    final anchorRect = tester.getRect(viewport);
    await tester.tapAt(
      Offset(
        anchorRect.left + 2.5 * anchorRect.width / 4,
        anchorRect.top + 1.5 * anchorRect.height / 3,
      ),
    );
    await tester.pump();

    final tiled = find.byKey(const Key('smart-tiles-pattern-repeat-tiled'));
    await tester.ensureVisible(tiled);
    await tester.tap(tiled);
    await tester.pump();
    final save = find.byKey(const Key('smart-tiles-pattern-save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.id, 'motif');
    expect(saved!.name, 'Chemin compacté');
    expect(saved!.usage, SmartTileUsage.path);
    expect(saved!.repeatMode, SmartTilePatternRepeatMode.tiled);
    expect(saved!.width, 2);
    expect(saved!.height, 2);
    expect(saved!.anchorX, 1);
    expect(saved!.anchorY, 1);
    expect(saved!.cells, hasLength(4));
  });

  testWidgets('shows an explicit empty state when no atlas exists',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: SmartTilePatternEditor(
            manifest: const ProjectManifest(
              name: 'Empty',
              maps: <ProjectMapEntry>[],
              tilesets: <ProjectTilesetEntry>[],
            ),
            projectRootPath: '/virtual/project',
            patternId: 'motif',
            imageLoader: const _MissingImageLoader(),
            isSaving: false,
            onCancel: () {},
            onSave: (_) async {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('smart-tiles-pattern-missing-atlas')),
      findsOneWidget,
    );
  });

  testWidgets('authors canopy and collision masks for an organic forest',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    ProjectSmartTilePattern? saved;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            height: 1600,
            child: SmartTilePatternEditor(
              manifest: _manifest,
              projectRootPath: '/virtual/project',
              patternId: 'organic_forest',
              imageLoader: const _MissingImageLoader(),
              isSaving: false,
              onCancel: () {},
              onSave: (pattern) async => saved = pattern,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('smart-tiles-pattern-name')),
      'Bosquet organique',
    );
    await tester.tap(
      find.byKey(const Key('smart-tiles-pattern-usage-forestSurface')),
    );
    await tester.pump();

    final viewport =
        find.byKey(const Key('smart-tiles-pattern-atlas-viewport'));
    await tester.ensureVisible(viewport);
    final firstRect = tester.getRect(viewport);
    await tester.tapAt(Offset(
      firstRect.left + 0.5 * firstRect.width / 4,
      firstRect.top + 0.5 * firstRect.height / 3,
    ));
    await tester.pump();
    final secondRect = tester.getRect(viewport);
    await tester.tapAt(Offset(
      secondRect.left + 1.5 * secondRect.width / 4,
      secondRect.top + 1.5 * secondRect.height / 3,
    ));
    await tester.pump();

    final canopy =
        find.byKey(const Key('smart-tiles-pattern-profile-channel-canopy'));
    await tester.ensureVisible(canopy);
    await tester.tap(canopy);
    await tester.tap(
      find.byKey(const Key('smart-tiles-pattern-profile-collision-blocked')),
    );
    await tester.tap(
      find.byKey(const Key('smart-tiles-pattern-profile-cell-0-0')),
    );
    await tester.pump();

    final save = find.byKey(const Key('smart-tiles-pattern-save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();

    final firstCell = saved!.cells.singleWhere(
      (cell) => cell.x == 0 && cell.y == 0,
    );
    expect(firstCell.parts.single.channel, SmartTileRenderChannel.canopy);
    expect(firstCell.collision, SmartTilePatternCollision.blocked);
    expect(
      saved!.cells
          .where((cell) => cell.x != 0 || cell.y != 0)
          .map((cell) => cell.parts.single.channel),
      everyElement(SmartTileRenderChannel.ground),
    );
  });

  testWidgets('refuses to overwrite an unsupported advanced pattern',
      (tester) async {
    var saved = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: SmartTilePatternEditor(
            manifest: _manifest,
            projectRootPath: '/virtual/project',
            patternId: 'advanced',
            initialPattern: _advancedPattern,
            imageLoader: const _MissingImageLoader(),
            isSaving: false,
            onCancel: () {},
            onSave: (_) async => saved = true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('smart-tiles-pattern-advanced-readonly')),
      findsOneWidget,
    );
    final save = find.byKey(const Key('smart-tiles-pattern-save'));
    await tester.scrollUntilVisible(
      save,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(save, warnIfMissed: false);
    await tester.pump();
    expect(saved, isFalse);
  });
}

const _advancedPattern = ProjectSmartTilePattern(
  id: 'advanced',
  name: 'Motif avancé',
  usage: SmartTileUsage.forestSurface,
  width: 1,
  height: 1,
  cells: <SmartTilePatternCell>[
    SmartTilePatternCell(
      x: 0,
      y: 0,
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
        SmartTileVisualPart(
          source: SmartTileVisualSource.frame(
            frame: SmartTileFrameRef(
              atlasId: 'atlas',
              column: 1,
              row: 0,
            ),
          ),
          channel: SmartTileRenderChannel.canopy,
        ),
      ],
    ),
  ],
);

final _manifest = ProjectManifest(
  name: 'Pattern editor',
  maps: const <ProjectMapEntry>[],
  tilesets: const <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'tileset',
      name: 'Tileset',
      relativePath: 'tileset.png',
    ),
  ],
  smartTileCatalog: ProjectSmartTileCatalog(
    atlases: const <ProjectSmartTileAtlas>[
      ProjectSmartTileAtlas(
        id: 'atlas',
        name: 'Atlas',
        tilesetId: 'tileset',
        columns: 4,
        rows: 3,
      ),
    ],
  ),
);

final class _MissingImageLoader implements SmartTileAtlasImageLoader {
  const _MissingImageLoader();

  @override
  Future<SmartTileAtlasImageLoadResult> load({
    required String? projectRootPath,
    required ProjectTilesetEntry tileset,
  }) async =>
      const SmartTileAtlasImageLoadResult(
        status: SmartTileAtlasImageLoadStatus.missingFile,
        message: 'Image absente dans ce test.',
      );
}
