import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:avelune_studio/features/world/data/local_world_adapter.dart';

import '../../tool/create_example_project.dart';

/// A real project on disk for the states and world rules of UI12.
class Ui12WorldHarness {
  Ui12WorldHarness(this.directory, this.session, this.maps, this.world);

  final Directory directory;
  final ProjectSession session;
  final MapWorkspaceController maps;
  final WorldWorkspaceController world;
  int changes = 0;
  void Function()? onChanged;

  static Future<Ui12WorldHarness> create({
    WorldPort Function(WorldPort)? wrap,
    bool initialize = true,
  }) async {
    final temporary = await Directory.systemTemp.createTemp('avelune_ui12w_');
    final directory = Directory(await temporary.resolveSymbolicLinks());
    await writeExampleProject(directory);
    return open(directory, wrap: wrap, initialize: initialize);
  }

  /// Reopens the same folder through fresh adapters, the way a later session
  /// would: what is asserted after this has really been written.
  static Future<Ui12WorldHarness> open(
    Directory directory, {
    WorldPort Function(WorldPort)? wrap,
    bool initialize = true,
  }) async {
    final session = ProjectSession(
      sessionId: directory.path,
      name: 'UI12',
      directoryPath: directory.path,
    );
    final adapter = LocalMapWorkspaceAdapter();
    final maps = MapWorkspaceController(session, adapter);
    await maps.initialize();
    final narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: session, mapAdapter: adapter),
      () {},
      (_, _) async {},
    );
    late Ui12WorldHarness harness;
    final world = WorldWorkspaceController(
      narrative,
      (wrap ?? (port) => port)(
        LocalWorldAdapter(session: session, mapAdapter: adapter),
      ),
      changed: () {
        harness.changes++;
        harness.onChanged?.call();
      },
    );
    harness = Ui12WorldHarness(directory, session, maps, world);
    if (initialize) await world.initialize();
    return harness;
  }

  Future<void> dispose({bool deleteDirectory = true}) async {
    world.dispose();
    maps.dispose();
    if (deleteDirectory && await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
