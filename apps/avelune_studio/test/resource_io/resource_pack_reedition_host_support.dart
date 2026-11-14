import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/data/local_resource_pack_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../resource_io/resource_pack_export_host_test.dart'
    show FileExportTestSink;
import '../support/map_workspace_fixture.dart' show WorkspaceTestVisuals;
import '../support/ui04_terrain_atlas.dart' show ui04TerrainAtlas;

String digest(List<int> bytes) => sha256.convert(bytes).toString();

class Host {
  Host(this.root, this.archive);
  final Directory root;
  final File archive;
  late ProjectSession session;
  late LocalMapWorkspaceAdapter maps;
  late LocalResourceAdapter resources;
  late LocalResourcePackAdapter pack;
  late MapWorkspaceController workspace;
  late ResourceNavigation navigation;
  bool open = false;

  static Future<Host> create(Directory root, File archive) async {
    await root.create(recursive: true);
    await File('${root.path}/project.json').writeAsString(
      jsonEncode(
        ProjectManifest(
          name: 'Original discriminant',
          maps: [],
          tilesets: [],
          settings: ProjectSettings(tileWidth: 24, tileHeight: 24),
        ).toJson(),
      ),
    );
    return Host(root, archive);
  }

  Future<void> initialize() async {
    session = ProjectSession(
      sessionId: '${root.path}-${DateTime.now().microsecondsSinceEpoch}',
      name: 'Discriminant',
      directoryPath: await root.resolveSymbolicLinks(),
    );
    maps = LocalMapWorkspaceAdapter();
    workspace = MapWorkspaceController(session, maps);
    await workspace.initialize();
    resources = LocalResourceAdapter(session: session, mapAdapter: maps);
    pack = LocalResourcePackAdapter(
      session: session,
      mapAdapter: maps,
      resources: resources,
    );
    navigation = ResourceNavigation(
      workspace: workspace,
      port: resources,
      visuals: WorkspaceTestVisuals(),
      onUse: (_) {},
      packPort: pack,
      packPicker: () async => archive.path,
      packExportSink: FileExportTestSink(archive),
    );
    open = true;
  }

  Future<ProjectManifest> load() => maps.loadProject(session);

  Future<void> close() async {
    if (!open) return;
    await navigation.packTransfer!.requestClose();
    navigation.dispose();
    await pack.dispose();
    workspace.dispose();
    await resources.dispose();
    open = false;
  }
}

Future<String> addAtlas(Host host) async {
  final file = File('${host.root.path}/source-original.png');
  await file.writeAsBytes(ui04TerrainAtlas());
  final receipt = await host.resources.importImage(
    ResourceImageImport(
      sourcePath: file.path,
      name: 'Original atlas',
      tileWidth: 24,
      tileHeight: 24,
    ),
  );
  await host.navigation.accept(receipt);
  return receipt.createdTilesetId!;
}

Future<void> officialExport(Host host, String kind) async {
  final c = host.navigation.packTransfer!;
  await c.beginExport(projectName: 'Original discriminant');
  for (final entry in {
    'author': 'Original test author',
    'universeId': 'original-fixture',
    'provenance': 'Original in-memory workshop fixture',
  }.entries) {
    await c.setExportField(entry.key, entry.value);
  }
  await c.setFilter(kind: kind);
  await c.selectFiltered();
  await c.prepare();
  expect(c.error, isNull);
  if (c.requiresOrganizationAcknowledgement) {
    c.setOrganizationAcknowledgement(true);
  }
  await c.export();
  expect(c.error, isNull);
  expect(c.outputPath, host.archive.path);
  await c.requestClose();
}

Future<Host> importAndReopen(Directory root, File archive) async {
  final first = await Host.create(root, archive);
  await first.initialize();
  final c = first.navigation.packTransfer!;
  await c.beginImport();
  await c.selectFiltered();
  await c.prepare();
  expect(c.error, isNull);
  await c.apply();
  expect(c.error, isNull);
  final installed = await first.load();
  final firstSession = first.session.sessionId;
  await first.close();
  final reopened = Host(root, archive);
  await reopened.initialize();
  expect(reopened.session.sessionId, isNot(firstSession));
  expect(await reopened.load(), installed);
  return reopened;
}
