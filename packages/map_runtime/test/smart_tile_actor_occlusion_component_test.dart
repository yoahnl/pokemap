import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/smart_tile_animation_activation_controller.dart';
import 'package:map_runtime/src/presentation/flame/smart_tile_actor_occlusion_component.dart';

import 'surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds one depth row per map row only when actor visuals exist', () {
    final collection = SmartTileActorOcclusionLayerCollection(
      bundle: _bundle(_manifest(), _map()),
      tileImagesByTilesetId: const <String, RuntimeTilesetImage>{},
    );
    final groundOnly = SmartTileActorOcclusionLayerCollection(
      bundle: _bundle(_manifest(actorOcclusion: false), _map()),
      tileImagesByTilesetId: const <String, RuntimeTilesetImage>{},
    );

    expect(collection.rows, hasLength(3));
    expect(groundOnly.rows, isEmpty);
  });

  test('renders only actor occlusion visuals in their owner depth row',
      () async {
    final image = await _runtimeImage();
    addTearDown(image.dispose);
    final collection = SmartTileActorOcclusionLayerCollection(
      bundle: _bundle(_manifest(), _map()),
      tileImagesByTilesetId: <String, RuntimeTilesetImage>{'smart': image},
    )..setVisibleLocalRect(const Rect.fromLTWH(0, 0, 96, 96));

    final firstRow = await _render(collection.rows[0]);
    final secondRow = await _render(collection.rows[1]);

    expect(await pixelAt(firstRow, 16, 16), rgba(0, 0, 0, 0));
    expect(await pixelAt(secondRow, 16, 48), rgba(255, 0, 0, 255));
    expect(collection.debugLastOwnerCellVisits, 9);
    firstRow.dispose();
    secondRow.dispose();
  });

  test('depth rows track map origin and interleave around actor feet', () {
    final collection = SmartTileActorOcclusionLayerCollection(
      bundle: _bundle(_manifest(), _map()),
      tileImagesByTilesetId: const <String, RuntimeTilesetImage>{},
    );

    collection.setMapOrigin(Vector2(32, 64));
    final row = collection.rows[1];

    expect(row.position, Vector2(32, 64));
    expect(row.priority, 1129);
    expect(1000 + 100, lessThan(row.priority));
    expect(1000 + 128, lessThan(row.priority));
    expect(1000 + 140, greaterThan(row.priority));

    collection.setMapOrigin(Vector2(-64, -96));

    expect(row.position, Vector2(-64, -96));
    expect(row.priority, 969);
  });

  test('large maps allocate per row and resolve only the visible envelope',
      () async {
    final image = await _runtimeImage();
    addTearDown(image.dispose);
    final collection = SmartTileActorOcclusionLayerCollection(
      bundle: _bundle(_manifest(), _largeMap()),
      tileImagesByTilesetId: <String, RuntimeTilesetImage>{'smart': image},
    )..setVisibleLocalRect(const Rect.fromLTWH(1568, 1568, 96, 96));

    final rendered = await _render(collection.rows[50]);

    expect(collection.rows, hasLength(100));
    expect(collection.debugLastOwnerCellVisits, lessThan(100));
    rendered.dispose();
  });

  test('actor occlusion animation advances from one shared clock', () async {
    final image = await _runtimeImage();
    addTearDown(image.dispose);
    final collection = SmartTileActorOcclusionLayerCollection(
      bundle: _bundle(_manifest(animated: true), _map()),
      tileImagesByTilesetId: <String, RuntimeTilesetImage>{'smart': image},
    )..setVisibleLocalRect(const Rect.fromLTWH(0, 0, 96, 96));

    final before = await _render(collection.rows[1]);
    collection.update(0.11);
    final after = await _render(collection.rows[1]);

    expect(await pixelAt(before, 16, 48), rgba(255, 0, 0, 255));
    expect(await pixelAt(after, 16, 48), rgba(0, 0, 255, 255));
    before.dispose();
    after.dispose();
  });

  test('cell-entry actor animation is hidden outside its active cycle',
      () async {
    final image = await _runtimeImage();
    addTearDown(image.dispose);
    final map = _map(
      animationActivation: SmartTileAnimationActivation.onEnter,
    );
    final manifest = _manifest(animated: true);
    final controller = SmartTileAnimationActivationController(
      map: map,
      catalog: manifest.smartTileCatalog,
    );
    final collection = SmartTileActorOcclusionLayerCollection(
      bundle: _bundle(manifest, map),
      tileImagesByTilesetId: <String, RuntimeTilesetImage>{'smart': image},
      smartTileAnimationController: controller,
    )..setVisibleLocalRect(const Rect.fromLTWH(0, 0, 96, 96));

    final idle = await _render(collection.rows[1]);
    controller.onPlayerEnteredCell(const GridPos(x: 0, y: 1));
    controller.update(0.11);
    collection.update(0.11);
    final active = await _render(collection.rows[1]);
    controller.update(0.1);
    collection.update(0.1);
    final completed = await _render(collection.rows[1]);

    expect(await pixelAt(idle, 16, 48), rgba(0, 0, 0, 0));
    expect(await pixelAt(active, 16, 48), rgba(0, 0, 255, 255));
    expect(await pixelAt(completed, 16, 48), rgba(0, 0, 0, 0));
    idle.dispose();
    active.dispose();
    completed.dispose();
  });

  test('static actor occlusion remains visible while on-enter is idle',
      () async {
    final image = await _runtimeImage();
    addTearDown(image.dispose);
    final map = _map(
      animationActivation: SmartTileAnimationActivation.onEnter,
    );
    final manifest = _manifest(animated: false);
    final collection = SmartTileActorOcclusionLayerCollection(
      bundle: _bundle(manifest, map),
      tileImagesByTilesetId: <String, RuntimeTilesetImage>{'smart': image},
      smartTileAnimationController: SmartTileAnimationActivationController(
        map: map,
        catalog: manifest.smartTileCatalog,
      ),
    )..setVisibleLocalRect(const Rect.fromLTWH(0, 0, 96, 96));

    final idle = await _render(collection.rows[1]);

    expect(await pixelAt(idle, 16, 48), rgba(255, 0, 0, 255));
    idle.dispose();
  });

  test('static occlusion stays visible around a cell-entry animation',
      () async {
    final image = await _runtimeImage();
    addTearDown(image.dispose);
    final map = _map(
      animationActivation: SmartTileAnimationActivation.onEnter,
    );
    final manifest = _manifest(
      animated: true,
      includeStaticActorOcclusion: true,
    );
    final controller = SmartTileAnimationActivationController(
      map: map,
      catalog: manifest.smartTileCatalog,
    );
    final collection = SmartTileActorOcclusionLayerCollection(
      bundle: _bundle(manifest, map),
      tileImagesByTilesetId: <String, RuntimeTilesetImage>{'smart': image},
      smartTileAnimationController: controller,
    )..setVisibleLocalRect(const Rect.fromLTWH(0, 0, 96, 96));

    final idle = await _render(collection.rows[1]);
    controller.onPlayerEnteredCell(const GridPos(x: 0, y: 1));
    controller.update(0.11);
    collection.update(0.11);
    final active = await _render(collection.rows[1]);
    controller.update(0.1);
    collection.update(0.1);
    final completed = await _render(collection.rows[1]);

    expect(await pixelAt(idle, 16, 48), rgba(255, 0, 0, 255));
    expect(await pixelAt(active, 16, 48), rgba(0, 0, 255, 255));
    expect(await pixelAt(completed, 16, 48), rgba(255, 0, 0, 255));
    idle.dispose();
    active.dispose();
    completed.dispose();
  });
}

Future<ui.Image> _render(SmartTileActorOcclusionRowComponent component) {
  final recorder = ui.PictureRecorder();
  component.render(Canvas(recorder));
  return recorder.endRecording().toImage(96, 96);
}

RuntimeMapBundle _bundle(ProjectManifest manifest, MapData map) =>
    RuntimeMapBundle(
      manifest: manifest,
      map: map,
      projectRootDirectory: '/tmp/tall-grass-runtime-test',
      tilesetAbsolutePathsById: const <String, String>{},
    );

MapData _map({
  SmartTileAnimationActivation animationActivation =
      SmartTileAnimationActivation.always,
}) =>
    MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        SmartTileLayer(
          id: 'grass',
          name: 'Grass',
          presetId: 'grass',
          usage: SmartTileUsage.path,
          materialPalette: <String>['', 'grass'],
          field: SmartTileField.cell(
            semanticCells: <int>[0, 0, 0, 1, 0, 0, 0, 0, 0],
          ),
          animationActivation: animationActivation,
        ),
      ],
    );

MapData _largeMap() {
  final cells = List<int>.filled(100 * 100, 0);
  cells[50 * 100 + 50] = 1;
  return MapData(
    id: 'large-map',
    name: 'Large map',
    version: ProjectVersion.v6,
    size: const GridSize(width: 100, height: 100),
    layers: <MapLayer>[
      SmartTileLayer(
        id: 'grass',
        name: 'Grass',
        presetId: 'grass',
        usage: SmartTileUsage.path,
        materialPalette: const <String>['', 'grass'],
        field: SmartTileField.cell(semanticCells: cells),
      ),
    ],
  );
}

ProjectManifest _manifest({
  bool actorOcclusion = true,
  bool animated = false,
  bool includeStaticActorOcclusion = false,
}) {
  final source = animated
      ? const SmartTileVisualSource.animation(animationId: 'rustle')
      : const SmartTileVisualSource.frame(
          frame: SmartTileFrameRef(
            atlasId: 'atlas',
            column: 1,
            row: 0,
          ),
        );
  return ProjectManifest(
    name: 'Tall grass runtime',
    version: ProjectVersion.v6,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'smart',
        name: 'Smart',
        relativePath: 'smart.png',
      ),
    ],
    settings: const ProjectSettings(
      tileWidth: 32,
      tileHeight: 32,
      displayScale: 1,
    ),
    smartTileCatalog: ProjectSmartTileCatalog(
      atlases: const <ProjectSmartTileAtlas>[
        ProjectSmartTileAtlas(
          id: 'atlas',
          name: 'Atlas',
          tilesetId: 'smart',
          columns: 3,
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
      animations: animated
          ? const <ProjectSmartTileAnimation>[
              ProjectSmartTileAnimation(
                id: 'rustle',
                name: 'Rustle',
                frames: <ProjectSmartTileAnimationFrame>[
                  ProjectSmartTileAnimationFrame(
                    frame: SmartTileFrameRef(
                      atlasId: 'atlas',
                      column: 1,
                      row: 0,
                    ),
                    durationMs: 100,
                  ),
                  ProjectSmartTileAnimationFrame(
                    frame: SmartTileFrameRef(
                      atlasId: 'atlas',
                      column: 2,
                      row: 0,
                    ),
                    durationMs: 100,
                  ),
                ],
              ),
            ]
          : const <ProjectSmartTileAnimation>[],
      presets: <ProjectSmartTilePreset>[
        ProjectSmartTilePreset(
          id: 'grass',
          name: 'Grass',
          usage: SmartTileUsage.path,
          topology: SmartTileTopology.uniform,
          coveragePolicy: SmartTileCoveragePolicy.sparse,
          coverageProfile: const SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.explicit,
          ),
          transformPolicy: const SmartTileTransformPolicy(),
          defaultMaterialId: 'grass',
          allowedMaterialIds: const <String>['grass'],
          rules: <SmartTileRule>[
            SmartTileRule(
              id: 'grass',
              centerMatch: const SmartTileSlotMatch.material('grass'),
              candidates: <SmartTileCandidate>[
                SmartTileCandidate(
                  id: 'grass',
                  parts: <SmartTileVisualPart>[
                    const SmartTileVisualPart(
                      source: SmartTileVisualSource.frame(
                        frame: SmartTileFrameRef(
                          atlasId: 'atlas',
                          column: 0,
                          row: 0,
                        ),
                      ),
                    ),
                    if (includeStaticActorOcclusion)
                      const SmartTileVisualPart(
                        source: SmartTileVisualSource.frame(
                          frame: SmartTileFrameRef(
                            atlasId: 'atlas',
                            column: 1,
                            row: 0,
                          ),
                        ),
                        channel: SmartTileRenderChannel.actorOcclusion,
                      ),
                    SmartTileVisualPart(
                      source: source,
                      channel: actorOcclusion
                          ? SmartTileRenderChannel.actorOcclusion
                          : SmartTileRenderChannel.ground,
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
}

Future<RuntimeTilesetImage> _runtimeImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 32, 32),
    Paint()..color = const Color(0xFF00FF00),
  );
  canvas.drawRect(
    const Rect.fromLTWH(32, 0, 32, 32),
    Paint()..color = const Color(0xFFFF0000),
  );
  canvas.drawRect(
    const Rect.fromLTWH(64, 0, 32, 32),
    Paint()..color = const Color(0xFF0000FF),
  );
  final image = await recorder.endRecording().toImage(96, 32);
  return RuntimeTilesetImage(
    images: <ui.Image>[image],
    chunks: const <RuntimeTilesetChunk>[
      RuntimeTilesetChunk(top: 0, height: 32, width: 96),
    ],
    width: 96,
    height: 32,
  );
}
