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
      'a catalog animation outside the layer preset does not run the clock',
      () {
        final project = ProjectManifest(
          name: 'Static Smart Tile project',
          maps: const <ProjectMapEntry>[],
          tilesets: const <ProjectTilesetEntry>[],
          smartTileCatalog: ProjectSmartTileCatalog(
            materials: const <ProjectSmartTileMaterial>[
              ProjectSmartTileMaterial(
                id: 'grass',
                name: 'Grass',
                connectionGroupId: 'grass',
              ),
            ],
            animations: const <ProjectSmartTileAnimation>[
              ProjectSmartTileAnimation(
                id: 'unrelated-water-loop',
                name: 'Unrelated water loop',
                frames: <ProjectSmartTileAnimationFrame>[
                  ProjectSmartTileAnimationFrame(
                    frame: SmartTileFrameRef(
                      atlasId: 'water-atlas',
                      column: 0,
                      row: 0,
                    ),
                    durationMs: 200,
                  ),
                ],
              ),
            ],
            presets: const <ProjectSmartTilePreset>[
              ProjectSmartTilePreset(
                id: 'grass',
                name: 'Grass',
                usage: SmartTileUsage.path,
                topology: SmartTileTopology.uniform,
                coveragePolicy: SmartTileCoveragePolicy.complete,
                coverageProfile: SmartTileCoverageProfile(
                  mode: SmartTileCoverageMode.template,
                ),
                transformPolicy: SmartTileTransformPolicy(),
                defaultMaterialId: 'grass',
                allowedMaterialIds: <String>['grass'],
                rules: <SmartTileRule>[
                  SmartTileRule(
                    id: 'fill',
                    centerMatch: SmartTileSlotMatch.material('grass'),
                    candidates: <SmartTileCandidate>[
                      SmartTileCandidate(
                        id: 'static-grass',
                        parts: <SmartTileVisualPart>[
                          SmartTileVisualPart(
                            source: SmartTileVisualSource.frame(
                              frame: SmartTileFrameRef(
                                atlasId: 'grass-atlas',
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
          isFalse,
        );
      },
    );

    test('an animation referenced by the layer preset runs the clock', () {
      final project = ProjectManifest(
        name: 'Animated Smart Tile project',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        smartTileCatalog: ProjectSmartTileCatalog(
          materials: const <ProjectSmartTileMaterial>[
            ProjectSmartTileMaterial(
              id: 'water',
              name: 'Water',
              connectionGroupId: 'water',
            ),
          ],
          animations: const <ProjectSmartTileAnimation>[
            ProjectSmartTileAnimation(
              id: 'water-loop',
              name: 'Water loop',
              frames: <ProjectSmartTileAnimationFrame>[
                ProjectSmartTileAnimationFrame(
                  frame: SmartTileFrameRef(
                    atlasId: 'water-atlas',
                    column: 0,
                    row: 0,
                  ),
                  durationMs: 110,
                ),
                ProjectSmartTileAnimationFrame(
                  frame: SmartTileFrameRef(
                    atlasId: 'water-atlas',
                    column: 1,
                    row: 0,
                  ),
                  durationMs: 110,
                ),
              ],
            ),
          ],
          presets: const <ProjectSmartTilePreset>[
            ProjectSmartTilePreset(
              id: 'water',
              name: 'Water',
              usage: SmartTileUsage.terrain,
              topology: SmartTileTopology.uniform,
              coveragePolicy: SmartTileCoveragePolicy.complete,
              coverageProfile: SmartTileCoverageProfile(
                mode: SmartTileCoverageMode.template,
              ),
              transformPolicy: SmartTileTransformPolicy(),
              defaultMaterialId: 'water',
              allowedMaterialIds: <String>['water'],
              rules: <SmartTileRule>[
                SmartTileRule(
                  id: 'fill',
                  centerMatch: SmartTileSlotMatch.material('water'),
                  candidates: <SmartTileCandidate>[
                    SmartTileCandidate(
                      id: 'animated-water',
                      parts: <SmartTileVisualPart>[
                        SmartTileVisualPart(
                          source: SmartTileVisualSource.animation(
                            animationId: 'water-loop',
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
      const map = MapData(
        id: 'water-map',
        name: 'Water map',
        version: ProjectVersion.v6,
        size: GridSize(width: 1, height: 1),
        layers: <MapLayer>[
          SmartTileLayer(
            id: 'water',
            name: 'Water',
            presetId: 'water',
            usage: SmartTileUsage.terrain,
            field: SmartTileField.cell(semanticCells: <int>[0]),
            animationActivation: SmartTileAnimationActivation.always,
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

    test('an animation referenced by a painted pattern runs the clock', () {
      final project = ProjectManifest(
        name: 'Animated Smart Tile pattern project',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        smartTileCatalog: ProjectSmartTileCatalog(
          animations: const <ProjectSmartTileAnimation>[
            ProjectSmartTileAnimation(
              id: 'flower-loop',
              name: 'Flower loop',
              frames: <ProjectSmartTileAnimationFrame>[
                ProjectSmartTileAnimationFrame(
                  frame: SmartTileFrameRef(
                    atlasId: 'flower-atlas',
                    column: 0,
                    row: 0,
                  ),
                  durationMs: 110,
                ),
              ],
            ),
          ],
          presets: const <ProjectSmartTilePreset>[
            ProjectSmartTilePreset(
              id: 'grass',
              name: 'Grass',
              usage: SmartTileUsage.path,
              topology: SmartTileTopology.uniform,
              coveragePolicy: SmartTileCoveragePolicy.complete,
              coverageProfile: SmartTileCoverageProfile(
                mode: SmartTileCoverageMode.template,
              ),
              transformPolicy: SmartTileTransformPolicy(),
              defaultMaterialId: 'grass',
              allowedMaterialIds: <String>['grass'],
            ),
          ],
          patterns: const <ProjectSmartTilePattern>[
            ProjectSmartTilePattern(
              id: 'flowers',
              name: 'Flowers',
              usage: SmartTileUsage.path,
              width: 1,
              height: 1,
              cells: <SmartTilePatternCell>[
                SmartTilePatternCell(
                  x: 0,
                  y: 0,
                  parts: <SmartTileVisualPart>[
                    SmartTileVisualPart(
                      source: SmartTileVisualSource.animation(
                        animationId: 'flower-loop',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
      const map = MapData(
        id: 'flower-map',
        name: 'Flower map',
        version: ProjectVersion.v6,
        size: GridSize(width: 1, height: 1),
        layers: <MapLayer>[
          SmartTileLayer(
            id: 'grass',
            name: 'Grass',
            presetId: 'grass',
            usage: SmartTileUsage.path,
            field: SmartTileField.cell(semanticCells: <int>[0]),
            patternStrokes: <SmartTilePatternStroke>[
              SmartTilePatternStroke(
                id: 'flowers-1',
                patternId: 'flowers',
                cells: <GridPos>[GridPos(x: 0, y: 0)],
              ),
            ],
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
