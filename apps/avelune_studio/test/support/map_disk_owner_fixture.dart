import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_tool_command_runner.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_resource_placement.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'border_catalog_fixture.dart';
import 'm3_story_fixture.dart';
import 'neutral_map_host_fixture.dart';

class MapDiskOwnerFixture {
  MapDiskOwnerFixture._(this.tester, this.source, this.maps, this.host);

  final WidgetTester tester;
  final M3StoryFixture source;
  final MapWorkspaceController maps;
  final NeutralMapHostFixture host;

  EditableMapDocument get document => maps.active!;
  MapEditingViewportSession get view => host.nativeView;

  static Future<MapDiskOwnerFixture> open(
    WidgetTester tester, {
    Future<void> Function(M3StoryFixture source)? prepareSource,
  }) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final (source, maps) = (await tester.runAsync(() async {
      final source = await M3StoryFixture.create();
      if (prepareSource != null) await prepareSource(source);
      final maps = MapWorkspaceController(source.session, source.maps);
      await maps.initialize();
      return (source, maps);
    }))!;
    addTearDown(() async {
      maps.dispose();
      await tester.runAsync(() async {
        if (await source.directory.exists()) {
          await source.directory.delete(recursive: true);
        }
      });
    });
    final host = await NeutralMapHostFixture.fromController(
      tester,
      maps,
      mapAdapter: source.maps,
    );
    return MapDiskOwnerFixture._(tester, source, maps, host);
  }

  static Future<MapDiskOwnerFixture> withBorder(
    WidgetTester tester, {
    BorderBlueprintTemplate template = BorderBlueprintTemplate.connectedLine,
    bool nativeOrientations = false,
  }) => open(
    tester,
    prepareSource: (source) async {
      final projectFile = File('${source.directory.path}/project.json');
      final project = ProjectManifest.fromJson(
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
      );
      await projectFile.writeAsString(
        jsonEncode(
          project
              .copyWith(
                borderCatalog: testBorderCatalog(
                  template: template,
                  nativeOrientations: nativeOrientations,
                ),
              )
              .toJson(),
        ),
      );
    },
  );

  MapToolCommandRunner tools({bool spatial = false}) => MapToolCommandRunner(
    view: view,
    paletteTab: () => '',
    selectPalette: (_) {},
    spatial: spatial,
    paletteVisible: true,
    onChanged: maps.notify,
    onMoreTools: () {},
    onResources: () {},
  );

  Future<void> runFamily(String label) async {
    tools().runFamily(label);
    await pump();
  }

  Future<void> chooseBorder(String borderId) async {
    await tester.runAsync(maps.ensureBorderProfiles);
    final item = resourceCatalog(maps.project!)
        .singleWhere((item) => item.border?.id == borderId);
    final used = await tester.runAsync(
      () => useMapResource(
        workspace: maps,
        item: item,
        view: () => view,
        isActive: () => true,
        chooseMap: (_) async => throw StateError('The map is already active'),
        chooseTile: (_) async =>
            throw StateError('A border needs no tile selection'),
      ),
    );
    expect(used, isTrue);
    maps.notify();
    await pump();
  }

  Future<void> pump({int frames = 4}) => host.pump(frames: frames);

  Offset cellAt(int x, int y) => host.cellAt(x, y);

  Future<void> tapCell(int x, int y) => host.tapCell(x, y);

  Future<void> rightClick(int x, int y) => host.rightClick(x, y);

  Future<void> key(LogicalKeyboardKey key) => host.key(key);

  Future<void> save() async {
    final saved = await tester.runAsync(() => maps.save(document));
    await pump();
    expect(saved, isTrue, reason: document.error ?? maps.error);
    expect(document.dirty, isFalse, reason: document.error);
  }

  Future<void> activate(String mapId) async {
    final entry = maps.project!.maps.singleWhere((entry) => entry.id == mapId);
    await tester.runAsync(() => maps.activate(entry));
    await pump();
  }

  Future<MapData> reopen(String mapId) async =>
      (await tester.runAsync(() async {
        final adapter = LocalMapWorkspaceAdapter();
        final project = await adapter.loadProject(source.session);
        return (await adapter.loadMap(
          source.session,
          project.maps.firstWhere((entry) => entry.id == mapId),
        )).map;
      }))!;
}
