import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:map_core/map_core.dart';

import '../../tool/create_example_project.dart';
import 'map_workspace_fixture.dart';

class AuthoringResourceFixture {
  AuthoringResourceFixture._(
    this.directory,
    this.session,
    this.workspace,
    this.resources,
    this.navigation,
    this.visuals,
  );

  final Directory directory;
  final ProjectSession session;
  final MapWorkspaceController workspace;
  final LocalResourceAdapter resources;
  final ResourceNavigation navigation;
  final WorkspaceTestVisuals visuals;

  static Future<AuthoringResourceFixture> create({
    bool noMaps = false,
    ProjectDimension? dimension,
  }) async {
    final qaRoot = Directory(
      '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109',
    );
    await qaRoot.create(recursive: true);
    final temporary = await qaRoot.createTemp('resource-library-fixture-');
    final directory = Directory(await temporary.resolveSymbolicLinks());
    MapWorkspaceController? workspace;
    LocalResourceAdapter? resources;
    ResourceNavigation? navigation;
    final visuals = WorkspaceTestVisuals();
    try {
      await writeExampleProject(directory);
      if (noMaps || dimension != null) {
        final file = File('${directory.path}/project.json');
        final manifest = ProjectManifest.fromJson(
          jsonDecode(await file.readAsString()),
        );
        await file.writeAsString(
          jsonEncode(
            manifest
                .copyWith(
                  version: dimension == ProjectDimension.threeD
                      ? ProjectVersion.v9
                      : manifest.version,
                  maps: noMaps ? [] : manifest.maps,
                  settings: dimension == null
                      ? manifest.settings
                      : manifest.settings.copyWith(
                          dimension: dimension,
                          spatialCamera: dimension == ProjectDimension.threeD
                              ? SpatialCameraProfile()
                              : null,
                        ),
                )
                .toJson(),
          ),
        );
      }
      final session = ProjectSession(
        sessionId: directory.path,
        name: 'Atelier M2',
        directoryPath: directory.path,
      );
      final adapter = LocalMapWorkspaceAdapter();
      workspace = MapWorkspaceController(session, adapter);
      await workspace.initialize();
      if (workspace.error != null || (!noMaps && workspace.active == null)) {
        throw StateError(workspace.error ?? 'No active map');
      }
      resources = LocalResourceAdapter(session: session, mapAdapter: adapter);
      navigation = ResourceNavigation(
        workspace: workspace,
        port: resources,
        visuals: visuals,
        onUse: (_) {},
      );
      return AuthoringResourceFixture._(
        directory,
        session,
        workspace,
        resources,
        navigation,
        visuals,
      );
    } catch (_) {
      navigation?.dispose();
      workspace?.dispose();
      await resources?.dispose();
      await visuals.dispose();
      await directory.delete(recursive: true);
      rethrow;
    }
  }

  Future<ProjectManifest> reopen() =>
      LocalMapWorkspaceAdapter().loadProject(session);

  Future<Map<String, String>> mapFiles() async => {
    for (final file in Directory(
      '${directory.path}/maps',
    ).listSync().whereType<File>())
      file.uri.pathSegments.last: await file.readAsString(),
  };

  Future<void> dispose() async {
    navigation.dispose();
    workspace.dispose();
    await resources.dispose();
    await visuals.dispose();
    await directory.delete(recursive: true);
  }
}
