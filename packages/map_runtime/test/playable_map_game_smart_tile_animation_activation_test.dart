import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('entering a painted cell triggers its Smart Tile animation', () async {
    final game = _TestPlayableMapGame(
      bundle: _bundle,
      projectFilePath: '/tmp/project.json',
      runtimeTilesetImageLoader:
          (_, {transparentColorByTilesetId = const {}}) async => const {},
    );

    game.onGameResize(Vector2(640, 480));
    await game.onLoad();
    await _pumpUntil(
      game,
      () => !game.debugIsMapActivationDispatchInFlight,
    );

    expect(
      game.debugSmartTileAnimationElapsedMsForCell(
        layerId: 'grass',
        cellX: 1,
        cellY: 0,
      ),
      0,
    );

    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.right),
    );
    game.update(0.016);
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.release(RuntimeInputControl.right),
    );
    await _pumpUntil(game, () => !game.debugIsPlayerStepping);
    game.update(0.05);

    expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 0));
    expect(
      game.debugSmartTileAnimationElapsedMsForCell(
        layerId: 'grass',
        cellX: 1,
        cellY: 0,
      ),
      greaterThan(0),
    );
    expect(
      game.debugSmartTileAnimationElapsedMsForCell(
        layerId: 'grass',
        cellX: 0,
        cellY: 0,
      ),
      0,
    );
  });
}

final class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    required super.runtimeTilesetImageLoader,
  });

  @override
  bool get isLoaded => true;
}

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() predicate,
) async {
  for (var index = 0; index < 120 && !predicate(); index += 1) {
    game.update(1 / 60);
    await Future<void>.delayed(Duration.zero);
  }
  expect(predicate(), isTrue);
}

final _bundle = RuntimeMapBundle(
  manifest: _manifest,
  map: _map,
  projectRootDirectory: '/tmp',
  tilesetAbsolutePathsById: const <String, String>{
    'smart': '/tmp/missing.png',
  },
);

final _map = MapData(
  id: 'map',
  name: 'Map',
  version: ProjectVersion.v6,
  size: const GridSize(width: 3, height: 1),
  layers: const <MapLayer>[
    SmartTileLayer(
      id: 'grass',
      name: 'Tall grass',
      presetId: 'grass-preset',
      usage: SmartTileUsage.path,
      materialPalette: <String>['', 'grass-material'],
      field: SmartTileField.cell(semanticCells: <int>[0, 1, 0]),
      animationActivation: SmartTileAnimationActivation.onEnter,
    ),
  ],
);

final _manifest = ProjectManifest(
  name: 'Triggered Smart Tile Runtime',
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
      id: 'smart',
      name: 'Smart',
      relativePath: 'tilesets/smart.png',
    ),
  ],
  smartTileCatalog: ProjectSmartTileCatalog(
    atlases: const <ProjectSmartTileAtlas>[
      ProjectSmartTileAtlas(
        id: 'atlas',
        name: 'Atlas',
        tilesetId: 'smart',
        columns: 2,
        rows: 1,
      ),
    ],
    materials: const <ProjectSmartTileMaterial>[
      ProjectSmartTileMaterial(
        id: 'grass-material',
        name: 'Grass',
        connectionGroupId: 'grass',
      ),
    ],
    animations: const <ProjectSmartTileAnimation>[
      ProjectSmartTileAnimation(
        id: 'rustle',
        name: 'Rustle',
        frames: <ProjectSmartTileAnimationFrame>[
          ProjectSmartTileAnimationFrame(
            frame: SmartTileFrameRef(
              atlasId: 'atlas',
              column: 0,
              row: 0,
            ),
            durationMs: 500,
          ),
          ProjectSmartTileAnimationFrame(
            frame: SmartTileFrameRef(
              atlasId: 'atlas',
              column: 1,
              row: 0,
            ),
            durationMs: 500,
          ),
        ],
      ),
    ],
    presets: const <ProjectSmartTilePreset>[
      ProjectSmartTilePreset(
        id: 'grass-preset',
        name: 'Tall grass',
        usage: SmartTileUsage.path,
        topology: SmartTileTopology.uniform,
        coveragePolicy: SmartTileCoveragePolicy.complete,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        transformPolicy: SmartTileTransformPolicy(),
        defaultMaterialId: 'grass-material',
        allowedMaterialIds: <String>['grass-material'],
        rules: <SmartTileRule>[
          SmartTileRule(
            id: 'fill',
            centerMatch: SmartTileSlotMatch.material('grass-material'),
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
      ),
    ],
  ),
);
