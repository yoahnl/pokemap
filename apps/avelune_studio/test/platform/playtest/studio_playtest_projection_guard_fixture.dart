import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

Future<void> waitForProjection(WidgetTester tester, String text) async {
  for (var attempt = 0; attempt < 150; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (find.textContaining(text).evaluate().isNotEmpty) return;
  }
}

final class ProjectionGuardFixture {
  ProjectionGuardFixture(
    this.directory,
    this.session,
    this.project,
    this.port,
    this.document,
  );

  final Directory directory;
  final ProjectSession session;
  final ProjectManifest project;
  final LocalMapWorkspaceAdapter port;
  final MapWorkspaceDocument document;

  static Future<ProjectionGuardFixture> create({
    bool spatial = true,
    bool withHero = false,
  }) async {
    final temporary = await Directory.systemTemp.createTemp(
      'studio-playtest-projection-',
    );
    final directory = Directory(await temporary.resolveSymbolicLinks());
    final project = ProjectManifest(
      name: 'Projection test',
      version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
      maps: const [
        ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'map.json'),
      ],
      tilesets: [
        if (withHero)
          const ProjectTilesetEntry(
            id: 'actor',
            name: 'Actor',
            relativePath: 'actor.png',
          ),
      ],
      settings: ProjectSettings(
        dimension: spatial ? ProjectDimension.threeD : ProjectDimension.twoD,
        spatialCamera: spatial ? SpatialCameraProfile() : null,
        tileWidth: 16,
        tileHeight: 24,
        defaultPlayerCharacterId: withHero ? 'hero' : '',
      ),
      characters: [
        if (withHero)
          const ProjectCharacterEntry(
            id: 'hero',
            name: 'Hero',
            tilesetId: 'actor',
            frameWidth: 1,
            frameHeight: 1,
            animations: [
              CharacterAnimation(
                state: CharacterAnimationState.idle,
                direction: EntityFacing.south,
                frames: [
                  CharacterAnimationFrame(
                    source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
                  ),
                ],
              ),
            ],
          ),
      ],
      models3d: [
        if (spatial)
          ProjectModel3dEntry(
            id: 'grass',
            name: 'Grass',
            sourceAssetId: 'model3d_grass',
            relativePath: 'assets/models3d/grass.glb',
            inspection: Model3dInspection(
              bounds: Model3dBounds(
                min: Model3dVector3.zero,
                max: Model3dVector3(x: 1, y: .5, z: 1),
              ),
              meshCount: 1,
              triangleCount: 6,
            ),
          ),
      ],
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: spatial
            ? const [
                ProjectSmartTileMaterial(
                  id: 'grass',
                  name: 'Grass',
                  connectionGroupId: 'grass',
                ),
              ]
            : const [],
        presets: spatial
            ? const [
                ProjectSmartTilePreset(
                  id: 'grass-path',
                  name: 'Grass',
                  usage: SmartTileUsage.path,
                  topology: SmartTileTopology.uniform,
                  templateHint: SmartTileTemplateHint.simple,
                  coveragePolicy: SmartTileCoveragePolicy.complete,
                  coverageProfile: SmartTileCoverageProfile(
                    mode: SmartTileCoverageMode.template,
                  ),
                  transformPolicy: SmartTileTransformPolicy(),
                  defaultMaterialId: 'grass',
                  allowedMaterialIds: ['grass'],
                  rules: [
                    SmartTileRule(
                      id: 'grass',
                      centerMatch: SmartTileSlotMatch.material('grass'),
                      candidates: [
                        SmartTileCandidate(
                          id: 'grass',
                          parts: [
                            SmartTileVisualPart(
                              source: SmartTileVisualSource.model3d(
                                modelId: 'grass',
                              ),
                              offsetX: 8,
                              offsetY: 12,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ]
            : const [],
      ),
    );
    final map = MapData(
      id: 'map',
      name: 'Map',
      version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
      size: const GridSize(width: 2, height: 2),
      layers: spatial
          ? const [
              SmartTileLayer(
                id: 'grass',
                name: 'Grass',
                presetId: 'grass-path',
                usage: SmartTileUsage.path,
                materialPalette: ['', 'grass'],
                field: SmartTileField.cell(semanticCells: [1, 0, 0, 0]),
              ),
            ]
          : const [],
      spatialScene: spatial
          ? MapSpatialScene(
              width: 2,
              depth: 2,
              heightLevels: const [2, 2, 2, 2],
              levelHeight: .25,
            )
          : null,
    );
    ProjectValidator.validate(project);
    MapValidator.validate(map, projectDialogueContext: project);
    await File('${directory.path}/project.json')
        .writeAsString(jsonEncode(project.toJson()));
    await File('${directory.path}/map.json')
        .writeAsString(jsonEncode(map.toJson()));
    final session = ProjectSession(
      sessionId: 'projection',
      name: project.name,
      directoryPath: directory.path,
    );
    final port = LocalMapWorkspaceAdapter();
    final loaded = await port.loadProject(session);
    final document = await port.loadMap(session, loaded.maps.single);
    return ProjectionGuardFixture(directory, session, loaded, port, document);
  }

  Future<void> mount(
    WidgetTester tester, {
    MapWorkspacePort? port,
    Future<void> Function(String)? prepare,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StudioPlaytestView(
          session: session,
          entry: project.maps.single,
          expectedRevision: document.revision,
          port: port ?? this.port,
          onClose: () {},
          prepareProjectAssets: prepare,
        ),
      ),
    ),
  );

  Future<void> changeMap() => File('${directory.path}/map.json').writeAsString(
    jsonEncode(document.map.copyWith(name: 'Changed during load').toJson()),
  );

  Future<void> dispose() async => directory.delete(recursive: true);
}

final class ChangingPort implements MapWorkspacePort {
  ChangingPort(this.delegate, this.change);

  final MapWorkspacePort delegate;
  final Future<void> Function() change;

  @override
  Future<ProjectManifest> loadProject(ProjectSession session) =>
      delegate.loadProject(session);

  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    final document = await delegate.loadMap(session, entry);
    await change();
    return document;
  }

  @override
  Future<String> saveMap(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapData current,
  ) => delegate.saveMap(session, base, current);
}
