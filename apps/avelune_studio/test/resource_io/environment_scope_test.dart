import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/environment_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_open_map_usage.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_documents.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import 'resource_fixture.dart';

void main() {
  for (final withZones in [true, false]) {
    test(
      withZones
          ? 'shared environment publication preserves three generated zones on two maps'
          : 'unused environment publication leaves both maps without zones',
      () async {
        final host = await EnvironmentScopeFixture.create(withZones: withZones);
        addTearDown(host.dispose);
        final beforeMaps = {
          for (final doc in host.workspace.documents.values)
            doc.current.id: doc.current,
        };
        final beforeFiles = await host.files();
        final item = host.item;
        expect(
          resourceOpenMapUsage(item, beforeMaps.values),
          withZones ? 3 : 0,
        );
        if (withZones) {
          expect(
            beforeMaps.values.every((map) => map.placedElements.isNotEmpty),
            isTrue,
          );
        }
        host.navigation.openEnvironment(host.preset);
        final draft = host.navigation.environment!..name = 'Forêt étoilée';
        draft.setWeightInput('tree', '3');
        await host.navigation.saveEnvironment();
        expect(host.navigation.error, isNull);
        expect(host.navigation.dirty, isFalse);
        final reader = LocalMapWorkspaceAdapter();
        final reopened = await reader.loadProject(host.fixture.session);
        expect(reopened.environmentPresets.single.name, 'Forêt étoilée');
        expect(reopened.environmentPresets.single.palette.single.weight, 3);
        expect(reopened.environmentPresets.single.id, host.preset.id);
        final diskMaps = <MapData>[];
        for (final entry in reopened.maps) {
          final disk = await reader.loadMap(host.fixture.session, entry);
          diskMaps.add(disk.map);
          expect(disk.map, beforeMaps[entry.id]);
          final file = File('${host.fixture.root.path}/${entry.relativePath}');
          expect(await file.readAsBytes(), beforeFiles[file.path]);
        }
        expect(resourceOpenMapUsage(item, diskMaps), withZones ? 3 : 0);
        for (final entry in reopened.tilesets) {
          final file = File('${host.fixture.root.path}/${entry.relativePath}');
          expect(await file.readAsBytes(), beforeFiles[file.path]);
        }
      },
    );
  }
}

final class EnvironmentScopeFixture {
  EnvironmentScopeFixture(
    this.owned,
    this.fixture,
    this.workspace,
    this.visuals,
    this.navigation,
    this.preset,
  );

  final Directory owned;
  final ResourceFixture fixture;
  final MapWorkspaceController workspace;
  final WorkspaceTestVisuals visuals;
  final ResourceNavigation navigation;
  final EnvironmentPreset preset;
  ResourceItem get item =>
      resourceCatalog(workspace.project!)
          .singleWhere((item) => item.environment?.id == preset.id);

  static Future<EnvironmentScopeFixture> create({
    bool withZones = true,
    void Function(ResourceItem)? onUse,
  }) async {
    final cache = Directory('/Users/karim/Library/Caches/AveluneQA');
    await cache.create(recursive: true);
    final owned = await cache.createTemp('environment-retirement-');
    final fixture = await ResourceFixture.create(parent: owned);
    final base = await fixture.maps.loadProject(fixture.session);
    final map = (await fixture.loadMap()).map;
    const grove = ProjectMapEntry(
      id: 'grove',
      name: 'Bosquet',
      relativePath: 'grove.json',
    );
    await File('${fixture.root.path}/${grove.relativePath}').writeAsBytes(
      encodeMapDocumentBytes(map.copyWith(id: grove.id, name: grove.name)),
    );
    await fixture.manifestFile.writeAsString(
      jsonEncode(base.copyWith(maps: [...base.maps, grove]).toJson()),
    );
    await fixture.maps.loadProject(fixture.session);
    final imported = await fixture.import();
    await fixture.resources.saveElement(
      fixture
          .element(imported.createdTilesetId!)
          .copyWith(
            frames: const [
              TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
            ],
          ),
    );
    final workspace = MapWorkspaceController(fixture.session, fixture.maps);
    await workspace.initialize();
    await workspace.materializeProject();
    final visuals = WorkspaceTestVisuals();
    final navigation = ResourceNavigation(
      workspace: workspace,
      port: fixture.resources,
      visuals: visuals,
      onUse: onUse ?? (_) {},
    );
    navigation.openEnvironment();
    navigation.environment!
      ..name = 'Forêt claire'
      ..add('tree')
      ..params = EnvironmentGenerationParams(
        density: 1,
        variation: 0,
        edgeDensity: 1,
        minSpacingCells: 0,
      );
    await navigation.saveEnvironment();
    final preset = workspace.project!.environmentPresets.single;
    for (final entry in workspace.project!.maps.toList()) {
      await workspace.activate(entry);
      if (withZones) {
        final doc = workspace.active!;
        final commands = EnvironmentEditingCommands(doc, workspace.project!);
        final count = entry.id == ResourceFixture.entry.id ? 2 : 1;
        for (var index = 0; index < count; index++) {
          final session = commands.create(preset);
          commands.paint(session, [
            GridPos(x: index * 2, y: index * 2),
          ], erase: false);
          commands.preview(session);
          commands.apply(session);
        }
        expect(await workspace.save(doc), isTrue, reason: doc.error);
      }
    }
    await workspace.activate(workspace.project!.maps.first);
    navigation.library.atelierVisible = false;
    navigation.showLibrary();
    return EnvironmentScopeFixture(
      owned,
      fixture,
      workspace,
      visuals,
      navigation,
      preset,
    );
  }

  Future<Map<String, List<int>>> files() async => {
    for (final entity in owned.listSync(recursive: true))
      if (entity is File) entity.path: await entity.readAsBytes(),
  };

  Future<void> dispose() async {
    navigation.dispose();
    workspace.dispose();
    visuals.dispose();
    await fixture.dispose();
    await owned.delete(recursive: true);
  }
}
