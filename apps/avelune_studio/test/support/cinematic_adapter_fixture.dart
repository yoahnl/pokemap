import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/cinematics/data/local_cinematic_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

class CinematicAdapterFixture {
  CinematicAdapterFixture(this.directory, this.session, this.maps);

  final Directory directory;
  final ProjectSession session;
  final LocalMapWorkspaceAdapter maps;

  static CinematicAsset asset(String id) => CinematicAsset(
    id: id,
    title: 'Départ',
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: '$id.wait',
          kind: CinematicTimelineStepKind.wait,
          durationMs: 1400,
        ),
      ],
    ),
    metadata: const {'fixture': 'UI10'},
  );

  static Future<CinematicAdapterFixture> create({
    ProjectVersion version = ProjectVersion.v7,
    List<CinematicAsset> cinematics = const [],
    List<SceneAsset> scenes = const [],
  }) async {
    final temporary = await Directory.systemTemp.createTemp('avelune_ui10_');
    final directory = Directory(await temporary.resolveSymbolicLinks());
    final session = ProjectSession(
      sessionId: directory.path,
      name: 'UI10',
      directoryPath: directory.path,
    );
    final maps = LocalMapWorkspaceAdapter();
    final fixture = CinematicAdapterFixture(directory, session, maps);
    await fixture.writeManifest(
      ProjectManifest(
        name: 'UI10',
        version: version,
        maps: const [],
        tilesets: const [],
        cinematics: cinematics,
        scenes: scenes,
      ),
    );
    await maps.loadProject(session);
    return fixture;
  }

  File file(String path) => File('${directory.path}/$path');
  LocalCinematicAdapter adapter({
    AuthoringTransactionFaultInjector? faultInjector,
  }) => LocalCinematicAdapter(
    session: session,
    mapAdapter: maps,
    faultInjector: faultInjector,
  );

  Future<ProjectManifest> readManifest() async => ProjectManifest.fromJson(
    jsonDecode(await file('project.json').readAsString())
        as Map<String, dynamic>,
  );

  Future<void> writeManifest(ProjectManifest value) =>
      file('project.json').writeAsString(jsonEncode(value.toJson()));

  Future<void> dispose() => directory.delete(recursive: true);
}
