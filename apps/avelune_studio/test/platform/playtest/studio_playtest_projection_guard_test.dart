import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('native 3D brush projection reaches hero validation', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(_Fixture.create))!;
    addTearDown(fixture.dispose);
    final bundle = RuntimeMapBundle(
      manifest: fixture.project,
      map: fixture.document.map,
      projectRootDirectory: fixture.directory.path,
      tilesetAbsolutePathsById: const {},
    );
    expect(fixture.document.map.spatialScene!.instances, isEmpty);
    expect(bundle.map.spatialScene!.instances, hasLength(1));
    expect(
      bundle.map.spatialScene!.instances.single.position,
      Model3dVector3(x: 1, y: .5, z: 1),
    );
    expect(bundle.map, isNot(fixture.document.map));

    await fixture.mount(tester);
    await _waitFor(tester, 'Choisissez un héros animé');
    expect(find.textContaining('Choisissez un héros animé'), findsOneWidget);
    expect(find.textContaining('La carte a changé'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a real change during first spatial load is rejected', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(_Fixture.create))!;
    addTearDown(fixture.dispose);
    await fixture.mount(
      tester,
      port: _ChangingPort(fixture.port, fixture.changeMap),
    );
    await _waitFor(tester, 'La carte a changé pendant la préparation du test');
    expect(
      find.textContaining('La carte a changé pendant la préparation du test'),
      findsOneWidget,
    );
    expect(find.textContaining('Choisissez un héros animé'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a real change during spatial asset preparation is rejected', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(
      () => _Fixture.create(withHero: true),
    ))!;
    addTearDown(fixture.dispose);
    var preparationCalls = 0;
    await fixture.mount(
      tester,
      prepare: (_) async {
        preparationCalls++;
        await fixture.changeMap();
      },
    );
    await _waitFor(tester, 'La carte a changé pendant la préparation du test');
    expect(preparationCalls, 1);
    expect(
      find.textContaining('La carte a changé pendant la préparation du test'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a real change during 2D asset preparation stays rejected', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(
      () => _Fixture.create(spatial: false),
    ))!;
    addTearDown(fixture.dispose);
    var preparationCalls = 0;
    await fixture.mount(
      tester,
      prepare: (_) async {
        preparationCalls++;
        await fixture.changeMap();
      },
    );
    await _waitFor(tester, 'La carte a changé pendant la préparation du test');
    expect(preparationCalls, 1);
    expect(
      find.textContaining('La carte a changé pendant la préparation du test'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });
}

Future<void> _waitFor(WidgetTester tester, String text) async {
  for (var attempt = 0; attempt < 150; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (find.textContaining(text).evaluate().isNotEmpty) return;
  }
}

final class _Fixture {
  _Fixture(
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

  static Future<_Fixture> create({
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
    return _Fixture(directory, session, loaded, port, document);
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

final class _ChangingPort implements MapWorkspacePort {
  _ChangingPort(this.delegate, this.change);

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
