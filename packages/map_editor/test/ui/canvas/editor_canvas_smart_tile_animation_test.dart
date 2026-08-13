import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/map_canvas/editor_canvas_animation_need_resolver.dart';

void main() {
  group('World Map Smart Tile animation activation', () {
    test(
      'on enter stays on its initial frame while always follows the clock',
      () {
        expect(
          resolveEditorSmartTileAnimationElapsedMs(
            activation: SmartTileAnimationActivation.onEnter,
            elapsedMs: 640,
          ),
          0,
        );
        expect(
          resolveEditorSmartTileAnimationElapsedMs(
            activation: SmartTileAnimationActivation.always,
            elapsedMs: 640,
          ),
          640,
        );
      },
    );

    test(
      'only always-active Smart Tile layers keep the editor clock running',
      () {
        final project = ProjectManifest(
          name: 'Animated Smart Tile project',
          maps: const <ProjectMapEntry>[],
          tilesets: const <ProjectTilesetEntry>[],
          smartTileCatalog: ProjectSmartTileCatalog(
            animations: const <ProjectSmartTileAnimation>[
              ProjectSmartTileAnimation(
                id: 'grass-wave',
                name: 'Grass wave',
                frames: <ProjectSmartTileAnimationFrame>[
                  ProjectSmartTileAnimationFrame(
                    frame: SmartTileFrameRef(
                      atlasId: 'grass-atlas',
                      column: 0,
                      row: 0,
                    ),
                    durationMs: 200,
                  ),
                ],
              ),
            ],
          ),
        );
        const onEnterMap = MapData(
          id: 'on-enter-map',
          name: 'On enter map',
          version: ProjectVersion.v6,
          size: GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            SmartTileLayer(
              id: 'grass',
              name: 'Grass',
              presetId: 'grass',
              usage: SmartTileUsage.path,
              field: SmartTileField.cell(semanticCells: <int>[0]),
              animationActivation: SmartTileAnimationActivation.onEnter,
            ),
          ],
        );

        expect(
          editorCanvasNeedsAnimation(
            map: onEnterMap,
            project: project,
            borderPreview: null,
          ),
          isFalse,
        );
        expect(
          editorCanvasNeedsAnimation(
            map: onEnterMap.copyWith(
              layers: <MapLayer>[
                (onEnterMap.layers.single as SmartTileLayer).copyWith(
                  animationActivation: SmartTileAnimationActivation.always,
                ),
              ],
            ),
            project: project,
            borderPreview: null,
          ),
          isTrue,
        );
      },
    );

    test('an animated atlas tile keeps the editor clock running', () {
      const map = MapData(
        id: 'animated-atlas-map',
        name: 'Animated atlas map',
        size: GridSize(width: 1, height: 1),
        layers: <MapLayer>[
          TileLayer(
            id: 'water',
            name: 'Water',
            palette: <TileLayerPaletteEntry>[
              TileLayerPaletteEntry(tilesetId: 'world', localTileId: 1),
            ],
            cells: <int>[1],
          ),
        ],
      );
      const project = ProjectManifest(
        name: 'Animated atlas project',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'world',
            name: 'World',
            relativePath: 'world.png',
            source: ProjectRegularAtlasTilesetSource(
              assetId: 'world',
              pixelWidth: 64,
              pixelHeight: 64,
              tileWidth: 32,
              tileHeight: 32,
              tileAnimations: <ProjectRegularAtlasTileAnimation>[
                ProjectRegularAtlasTileAnimation(
                  tileId: 1,
                  frames: <ProjectImageCollectionAnimationFrame>[
                    ProjectImageCollectionAnimationFrame(
                      tileId: 1,
                      durationMs: 110,
                    ),
                    ProjectImageCollectionAnimationFrame(
                      tileId: 2,
                      durationMs: 110,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

      expect(
        editorCanvasNeedsAnimation(
          map: map,
          project: project,
          borderPreview: null,
        ),
        isTrue,
      );
    });
  });
}
