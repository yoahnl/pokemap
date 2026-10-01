import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_catalog_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_catalog_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:path/path.dart' as p;

import '../../tool/create_example_project.dart' show writeExampleProject;

final class MapCatalogFixture {
  MapCatalogFixture._(this.root, this.session, this.adapter, this.catalog);

  final Directory root;
  final ProjectSession session;
  final LocalMapWorkspaceAdapter adapter;
  final ControlledMapCatalogPort catalog;
  late final controller = MapWorkspaceController(
    session,
    adapter,
    catalogPort: catalog,
  );

  static Future<MapCatalogFixture> create({
    bool empty = false,
    List<ProjectSnapshotLoadProfile>? profiles,
  }) async {
    final temporary = await Directory.systemTemp.createTemp('uwu_catalog_');
    final root = Directory(await temporary.resolveSymbolicLinks());
    if (empty) {
      await File(p.join(root.path, 'project.json')).writeAsString(
        jsonEncode(
          const ProjectManifest(
            name: 'Projet vide',
            maps: [],
            tilesets: [],
            settings: ProjectSettings(tileWidth: 48, tileHeight: 48),
          ).toJson(),
        ),
      );
    } else {
      await writeExampleProject(root);
    }
    final session = ProjectSession(
      sessionId: root.path,
      name: 'Catalogue',
      directoryPath: root.path,
    );
    final adapter = LocalMapWorkspaceAdapter();
    final fixture = MapCatalogFixture._(
      root,
      session,
      adapter,
      ControlledMapCatalogPort(
        LocalMapCatalogAdapter(adapter, profileSink: profiles?.add),
      ),
    );
    await fixture.controller.initialize();
    return fixture;
  }

  Future<MapCatalogResult> createMap(String id) => controller.mutateCatalog(
    'map.create',
    {'mapId': id, 'name': 'Carte $id', 'width': 7, 'height': 5},
  );

  Future<void> dispose() async {
    controller.dispose();
    if (root.existsSync()) await root.delete(recursive: true);
  }
}

final class ControlledMapCatalogPort implements MapCatalogPort {
  ControlledMapCatalogPort(this.delegate);

  final MapCatalogPort delegate;
  bool failRefresh = false;
  Completer<void>? publicationReady;
  Completer<void>? publicationGate;
  int mutations = 0;
  int refreshes = 0;

  @override
  Future<MapCatalogReceipt> mutate(
    ProjectSession session,
    String actionId,
    Map<String, Object?> parameters, {
    Map<String, String> expectedMapRevisions = const {},
    bool confirmDestructive = false,
    ProjectManifest? expectedManifest,
  }) async {
    mutations++;
    final receipt = await delegate.mutate(
      session,
      actionId,
      parameters,
      expectedMapRevisions: expectedMapRevisions,
      confirmDestructive: confirmDestructive,
      expectedManifest: expectedManifest,
    );
    publicationReady?.complete();
    await publicationGate?.future;
    return receipt;
  }

  @override
  Future<void> reconcile(
    ProjectSession session,
    MapCatalogReceipt receipt,
  ) async {
    refreshes++;
    if (failRefresh) throw StateError('Lecture indisponible');
    await delegate.reconcile(session, receipt);
  }
}
