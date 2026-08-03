import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_map_backdrop_render_pass.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart';

void main() {
  test('cinematic backdrop renders Smart Tile background and foreground parts',
      () async {
    final image = await _tilesetImage();
    addTearDown(image.dispose);
    final manifest = _manifest();
    const map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: GridSize(width: 2, height: 1),
      layers: <MapLayer>[
        MapLayer.smartTile(
          id: 'smart-ground',
          name: 'Smart ground',
          presetId: 'grass',
          usage: SmartTileUsage.terrain,
          materialPalette: <String>['', 'grass'],
          field: SmartTileField.cell(semanticCells: <int>[1, 0]),
        ),
      ],
    );
    final assets = <String, CinematicResolvedTilesetAsset>{
      'smart-tiles': CinematicResolvedTilesetAsset.available(
        tilesetId: 'smart-tiles',
        image: image,
        tileWidth: 16,
        tileHeight: 16,
      ),
    };

    expect(
      collectCinematicMapBackdropLayerTilesetIds(
        mapData: map,
        manifest: manifest,
      ),
      <String>{'smart-tiles'},
    );

    final plan = buildCinematicMapBackdropLayerRenderPlan(
      mapData: map,
      manifest: manifest,
      tilesets: assets,
    );

    expect(plan.diagnostics, isEmpty);
    expect(plan.instructions, hasLength(2));
    expect(
      plan.instructions.map((instruction) => instruction.layerKind),
      everyElement(CinematicMapBackdropLayerKind.smartTile),
    );
    expect(
      plan.instructions.map((instruction) => instruction.renderPass),
      <CinematicMapBackdropRenderPass>[
        CinematicMapBackdropRenderPass.smartTileBackground,
        CinematicMapBackdropRenderPass.tileForeground,
      ],
    );
    expect(
      plan.instructions.map((instruction) => instruction.sourceFamily),
      everyElement('smartTile'),
    );
    final foreground = plan.instructions.last;
    expect(foreground.sourceRect.left, 16);
    expect(foreground.quarterTurns, 1);
    expect(foreground.flipX, isTrue);
    expect(foreground.destinationWidthPx, 32);
    expect(foreground.destinationHeightPx, 16);
  });
}

ProjectManifest _manifest() => ProjectManifest(
      name: 'Cinematic Smart Tile',
      version: ProjectVersion.v6,
      maps: const <ProjectMapEntry>[],
      settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
      tilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'smart-tiles',
          name: 'Smart Tiles',
          relativePath: 'assets/smart-tiles.png',
        ),
      ],
      smartTileCatalog: ProjectSmartTileCatalog(
        atlases: const <ProjectSmartTileAtlas>[
          ProjectSmartTileAtlas(
            id: 'atlas',
            name: 'Atlas',
            tilesetId: 'smart-tiles',
            cellWidth: 16,
            cellHeight: 16,
            columns: 2,
            rows: 1,
          ),
        ],
        materials: const <ProjectSmartTileMaterial>[
          ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Grass',
            connectionGroupId: 'grass',
          ),
        ],
        presets: const <ProjectSmartTilePreset>[
          ProjectSmartTilePreset(
            id: 'grass',
            name: 'Grass',
            usage: SmartTileUsage.terrain,
            topology: SmartTileTopology.uniform,
            templateHint: SmartTileTemplateHint.simple,
            status: SmartTilePresetStatus.published,
            coveragePolicy: SmartTileCoveragePolicy.complete,
            coverageProfile: SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.template,
            ),
            transformPolicy: SmartTileTransformPolicy(),
            defaultMaterialId: 'grass',
            allowedMaterialIds: <String>['grass'],
            rules: <SmartTileRule>[
              SmartTileRule(
                id: 'uniform',
                centerMatch: SmartTileSlotMatch.material('grass'),
                candidates: <SmartTileCandidate>[
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
                      SmartTileVisualPart(
                        source: SmartTileVisualSource.frame(
                          frame: SmartTileFrameRef(
                            atlasId: 'atlas',
                            column: 1,
                            row: 0,
                          ),
                        ),
                        transform: SmartTileSpriteTransform(
                          quarterTurns: 1,
                          flipX: true,
                        ),
                        channel: SmartTileRenderChannel.foreground,
                        footprintWidth: 2,
                        drawOrder: 1,
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

Future<ui.Image> _tilesetImage() async {
  final source = img.Image(width: 32, height: 16, numChannels: 4);
  img.fill(source, color: img.ColorRgba8(40, 120, 60, 255));
  final codec = await ui.instantiateImageCodec(
    Uint8List.fromList(img.encodePng(source)),
  );
  addTearDown(codec.dispose);
  return (await codec.getNextFrame()).image;
}
