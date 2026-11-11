import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:avelune_studio/features/cinematics/data/local_cinematic_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:map_core/map_core.dart';

import 'ui07_story_fixture.dart';
import 'ui10_cinematic_fixture.dart';

class CinematicWorkspaceOwnerFixture {
  CinematicWorkspaceOwnerFixture._(
    this.fixture,
    this.maps,
    this.narrative,
    this.controller,
  );

  final Ui07StoryFixture fixture;
  final MapWorkspaceController maps;
  final NarrativeWorkspaceController narrative;
  final CinematicWorkspaceController controller;
  int rebuilds = 0;

  static Future<CinematicWorkspaceOwnerFixture> create({
    int tileSize = 32,
  }) async {
    final fixture = await createUi10Fixture(tileSize: tileSize);
    final maps = MapWorkspaceController(fixture.session, fixture.maps);
    await maps.initialize();
    final narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: fixture.session, mapAdapter: fixture.maps),
      () {},
      (_, _) async {},
    );
    late final CinematicWorkspaceOwnerFixture owner;
    final controller = CinematicWorkspaceController(
      narrative,
      LocalCinematicAdapter(session: fixture.session, mapAdapter: fixture.maps),
      changed: () => owner.rebuilds++,
    );
    owner = CinematicWorkspaceOwnerFixture._(
      fixture,
      maps,
      narrative,
      controller,
    );
    return owner;
  }

  Future<CinematicAsset> open([String id = ui10CinematicId]) async {
    if (!await controller.open(id)) throw StateError('${controller.error}');
    return controller.active!.asset;
  }

  File get projectFile => File('${fixture.directory.path}/project.json');

  Future<List<int>> projectBytes() => projectFile.readAsBytes();

  Future<CinematicAsset> reread([String id = ui10CinematicId]) async {
    final manifest = ProjectManifest.fromJson(
      jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
    );
    return manifest.cinematics.singleWhere((asset) => asset.id == id);
  }

  Future<Map<String, List<int>>> mapBytes() async => {
    for (final entry in maps.project!.maps)
      entry.relativePath: await File(
        '${fixture.directory.path}/${entry.relativePath}',
      ).readAsBytes(),
  };

  Future<MapData> loadMap(String mapId) async {
    final manifest = await fixture.readFresh();
    final entry = manifest.maps.singleWhere((map) => map.id == mapId);
    return (await fixture.maps.loadMap(fixture.session, entry)).map;
  }

  Future<void> dispose() async {
    controller.dispose();
    narrative.dispose();
    maps.dispose();
    await fixture.dispose();
  }
}
