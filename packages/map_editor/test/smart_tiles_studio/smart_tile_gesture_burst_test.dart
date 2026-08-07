import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

/// Clicking faster than a commit used to be refused: one canonical write takes
/// hundreds of milliseconds, so ordinary erasing always hit the window.
/// A burst is now coalesced into a single write.
void main() {
  test('a burst of clicks paints every cell and is refused none', () async {
    final h = await _Harness.create();
    addTearDown(h.dispose);

    for (var x = 0; x < 3; x++) {
      h.paint(GridPos(x: x, y: 0));
      expect(h.notifier.state.errorMessage, isNull,
          reason: 'click $x must never be refused');
    }
    await h.settle();

    expect(h.painted(), containsAll(<GridPos>[
      const GridPos(x: 0, y: 0),
      const GridPos(x: 1, y: 0),
      const GridPos(x: 2, y: 0),
    ]), reason: 'no click may be dropped');
    expect(h.notifier.state.errorMessage, isNull);
  });

  test('a lone click still commits on its own', () async {
    final h = await _Harness.create();
    addTearDown(h.dispose);

    h.paint(const GridPos(x: 1, y: 1));
    await h.settle();

    expect(h.painted(), <GridPos>[const GridPos(x: 1, y: 1)]);
    expect(h.notifier.state.errorMessage, isNull);
  });
}

final class _Harness {
  _Harness._(this.root, this.container, this.notifier);

  static Future<_Harness> create() async {
    final root = await Directory.systemTemp.createTemp('pokemap_gesture_burst_');
    final container = ProviderContainer();
    final manifest = _manifest();
    const map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: GridSize(width: 3, height: 2),
      visualStack: MapVisualStackConfig.canonicalV1,
    );
    final mapPath = p.join(root.path, 'maps', 'map.json');
    await Directory(p.dirname(mapPath)).create(recursive: true);
    await FileProjectRepository()
        .saveProject(manifest, p.join(root.path, 'project.json'));
    await FileMapRepository()
        .saveMap(map, mapPath, projectDialogueContext: manifest);

    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(projectRootPath: root.path, project: manifest);
    await notifier.loadMap('maps/map.json');
    final created = await notifier.createCanonicalSmartTileLayer(
      preset: manifest.smartTileCatalog.presets.single,
    );
    expect(created, isTrue, reason: notifier.state.errorMessage);
    notifier.state =
        notifier.state.copyWith(activeTool: EditorToolType.terrainPaint);
    return _Harness._(root, container, notifier);
  }

  final Directory root;
  final ProviderContainer container;
  final EditorNotifier notifier;

  void paint(GridPos cell) => notifier.applyActiveSmartTileSelection(
        SmartTileGestureSelection.line(start: cell, end: cell),
      );

  Future<void> settle() async {
    for (var attempt = 0; attempt < 400; attempt++) {
      final error = notifier.state.errorMessage;
      if (error != null) fail('Gesture burst failed: $error');
      if (!notifier.state.isDirty) {
        await Future<void>.delayed(const Duration(milliseconds: 60));
        if (!notifier.state.isDirty) return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('Timed out waiting for the coalesced burst to commit.');
  }

  List<GridPos> painted() {
    final map = notifier.state.activeMap!;
    final layer = map.layers.whereType<SmartTileLayer>().single;
    return <GridPos>[
      for (var y = 0; y < map.size.height; y++)
        for (var x = 0; x < map.size.width; x++)
          if (smartTileMaterialIdAt(layer, mapSize: map.size, x: x, y: y) !=
              null)
            GridPos(x: x, y: y),
    ];
  }

  Future<void> dispose() async {
    container.dispose();
    if (await root.exists()) await root.delete(recursive: true);
  }
}

ProjectManifest _manifest() => ProjectManifest(
      name: 'Gesture burst',
      version: ProjectVersion.v6,
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'map',
          name: 'Map',
          relativePath: 'maps/map.json',
        ),
      ],
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
            columns: 1,
            rows: 1,
          ),
        ],
        materials: const <ProjectSmartTileMaterial>[
          ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Herbe',
            connectionGroupId: 'ground',
          ),
        ],
        patterns: const <ProjectSmartTilePattern>[
          ProjectSmartTilePattern(
            id: 'grass_patch',
            name: "Touffe d'herbe",
            usage: SmartTileUsage.terrain,
            width: 1,
            height: 1,
            repeatMode: SmartTilePatternRepeatMode.stamp,
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
                ],
              ),
            ],
          ),
        ],
        presets: const <ProjectSmartTilePreset>[
          ProjectSmartTilePreset(
            id: 'grass_preset',
            name: 'Prairie',
            usage: SmartTileUsage.terrain,
            topology: SmartTileTopology.uniform,
            templateHint: SmartTileTemplateHint.simple,
            status: SmartTilePresetStatus.published,
            coveragePolicy: SmartTileCoveragePolicy.sparse,
            coverageProfile: SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.template,
            ),
            transformPolicy: SmartTileTransformPolicy(),
            defaultMaterialId: 'grass',
            allowedMaterialIds: <String>['grass'],
            rules: <SmartTileRule>[
              SmartTileRule(
                id: 'base',
                centerMatch: SmartTileSlotMatch.material('grass'),
                signature: SmartTileSignature(),
                candidates: <SmartTileCandidate>[
                  SmartTileCandidate(
                    id: 'base',
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
          ),
        ],
      ),
    );
