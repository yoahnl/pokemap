import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('a visual plan can resolve animation time independently per cell', () {
    const layer = SmartTileLayer(
      id: 'grass',
      name: 'Tall grass',
      presetId: 'grass',
      usage: SmartTileUsage.path,
      materialPalette: <String>['', 'grass'],
      field: SmartTileField.cell(semanticCells: <int>[1, 1]),
    );
    const map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: GridSize(width: 2, height: 1),
      layers: <MapLayer>[layer],
    );
    const preset = ProjectSmartTilePreset(
      id: 'grass',
      name: 'Tall grass',
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
              id: 'animated',
              parts: <SmartTileVisualPart>[
                SmartTileVisualPart(
                  source: SmartTileVisualSource.animation(
                    animationId: 'rustle',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    final plan = buildSmartTileLayerVisualPlan(
      map: map,
      layer: layer,
      catalog: ProjectSmartTileCatalog(
        atlases: <ProjectSmartTileAtlas>[
          ProjectSmartTileAtlas(
            id: 'atlas',
            name: 'Atlas',
            tilesetId: 'tiles',
            columns: 2,
            rows: 1,
          ),
        ],
        materials: <ProjectSmartTileMaterial>[
          ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Grass',
            connectionGroupId: 'grass',
          ),
        ],
        animations: <ProjectSmartTileAnimation>[
          ProjectSmartTileAnimation(
            id: 'rustle',
            name: 'Rustle',
            frames: <ProjectSmartTileAnimationFrame>[
              ProjectSmartTileAnimationFrame(
                frame: SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
                durationMs: 100,
              ),
              ProjectSmartTileAnimationFrame(
                frame: SmartTileFrameRef(atlasId: 'atlas', column: 1, row: 0),
                durationMs: 100,
              ),
            ],
          ),
        ],
        presets: <ProjectSmartTilePreset>[preset],
      ),
      pass: SmartTileVisualPass.background,
    );

    final visuals = plan
        .resolveBatch(
          elapsedMs: 100,
          animationElapsedMsForCell:
              ({required cellX, required cellY, required elapsedMs}) =>
                  cellX == 0 ? 0 : elapsedMs,
        )
        .visuals;

    expect(visuals, hasLength(2));
    expect(visuals[0].sourceRect.x, 0);
    expect(visuals[1].sourceRect.x, 32);
  });
}
