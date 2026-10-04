import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/game_export/data/studio_game_export_controller.dart';
import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/resources/resource_image_import.dart';
import 'package:avelune_studio/presentation/shell/studio_home_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../../avelune_studio/test/support/m2_ui_fixture.dart';
import '../../../../avelune_studio/test/support/m3_story_fixture.dart';
import '../../../../avelune_studio/test/support/uwu_resource_host.dart';
import '../../../../avelune_studio/test/support/widget_resource_journey_map_port.dart';
import '../../../../avelune_studio/test/support/widget_resource_management_port.dart';
import 'uwu5_specialized_resources_fixture.dart';
import 'uwu5_specialized_resources_player_e2e_test.dart' show Uwu5StudioAssets;

class Uwu6ResourceHost extends UwUResourceHost {
  Uwu6ResourceHost(super.tester, super.fixture, this.temporary, this.package);
  final Directory temporary;
  final File package;
  final navigationHome = StudioHomeNavigation();
  late final StudioGameExportController exporter;
  late final LocalProjectSessionAdapter sessions;
  final oldPixels = image.encodePng(
    image.Image(width: 32, height: 32)
      ..clear(image.ColorRgba8(230, 44, 31, 255)),
  );
  final newPixels = image.encodePng(
    image.Image(width: 32, height: 32)
      ..clear(image.ColorRgba8(249, 9, 222, 255)),
  );
  bool replacement = false;
  bool closed = false;

  static Future<Uwu6ResourceHost> create(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final temporary =
        (await tester.runAsync(
          () => Directory.systemTemp.createTemp('uwu6-resources-player-'),
        ))!;
    final source =
        (await tester.runAsync(() async {
          final source = await M3StoryFixture.create();
          await prepareUwu5ExportFixture(source, discriminatingTerrain: true);
          final resources = LocalResourceAdapter(
            session: source.session,
            mapAdapter: source.maps,
          );
          await resources.mutate('characterStudio.character.create', {
            'name': 'Personnage libre',
            'tilesetId':
                (await source.maps.loadProject(
                  source.session,
                )).characters.first.tilesetId,
            'frameWidth': 1,
            'frameHeight': 1,
          });
          await resources.dispose();
          final manifest = await source.maps.loadProject(source.session);
          final base = await source.maps.loadMap(
            source.session,
            manifest.maps.first,
          );
          await source.maps.saveMap(
            source.session,
            base,
            base.map.copyWith(
              layers:
                  base.map.layers
                      .where((layer) => layer is! BorderLayer)
                      .toList(),
            ),
          );
          return source;
        }))!;
    final host = await openExisting(tester, source.directory, temporary);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await host.close();
      if (await source.directory.exists()) {
        await source.directory.delete(recursive: true);
      }
      if (await temporary.exists()) await temporary.delete(recursive: true);
    });
    return host;
  }

  static Future<Uwu6ResourceHost> openExisting(
    WidgetTester tester,
    Directory directory,
    Directory temporary, {
    String? initialMapId,
  }) async {
    final sessions = LocalProjectSessionAdapter();
    final fixture =
        (await tester.runAsync(() async {
          final session = await sessions.open(directory.path);
          final maps = LocalMapWorkspaceAdapter();
          final port = WidgetResourceJourneyMapPort(maps, tester);
          final controller = WidgetMapController(session, port, tester);
          if (initialMapId == null) {
            await controller.initialize();
          } else {
            controller.project = await maps.loadProject(session);
            await controller.activate(
              controller.project!.maps.singleWhere(
                (entry) => entry.id == initialMapId,
              ),
            );
          }
          port.active = true;
          return M2UiFixture(
            directory,
            session,
            maps,
            controller,
            LocalResourceAdapter(session: session, mapAdapter: maps),
          );
        }))!;
    final host = Uwu6ResourceHost(
      tester,
      fixture,
      temporary,
      File(p.join(temporary.path, 'uwu6-resources.avelunegame')),
    );
    host.sessions = sessions;
    host.exporter = StudioGameExportController(
      projectRoot: directory,
      projectName: 'Recette ressources UwU VI',
    );
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: Uwu5StudioAssets(),
        child: MaterialApp(
          theme: studioTheme(),
          home: RepaintBoundary(
            key: fixture.captureKey,
            child: MapWorkspaceScreen(
              controller: fixture.controller,
              resourcePort: WidgetResourceManagementPort(
                fixture.resources,
                tester,
              ),
              home: host.navigationHome,
              gameExport: host.exporter,
              gameExportPicker:
                  (_) async => StudioGameExportDestination(
                    host.package.path,
                    exists: await host.package.exists(),
                  ),
              imagePicker: host.pickImage,
              loadVisuals:
                  (session, project) async =>
                      fixture.visuals = await StudioMapResources.load(
                        session,
                        project,
                      ),
              runtimeBuilder: (_, _, _) => const SizedBox(),
              onClose: () async {},
              registerExitGuard: (_) {},
            ),
          ),
        ),
      ),
    );
    await pumpIo(tester);
    return host;
  }

  Future<PickedResourceImage> pickImage() async {
    final bytes = Uint8List.fromList(replacement ? newPixels : oldPixels);
    final file = File(
      p.join(temporary.path, replacement ? 'new.png' : 'old.png'),
    );
    await WidgetResourcePort.serial(tester, () => file.writeAsBytes(bytes));
    return PickedResourceImage(
      file.path,
      'Planche témoin UwU VI',
      bytes,
      32,
      32,
    );
  }

  Future<void> text(String label) async {
    await tester.pump(const Duration(milliseconds: 350));
    final target = find.text(label).last;
    await tester.ensureVisible(target);
    await tester.pump();
    await tester.tap(target);
    await pumpIo(tester, frames: 12);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
  }

  Future<void> go(String label) async {
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byTooltip(label).first);
    await pumpIo(tester, frames: 12);
  }

  @override
  Future<void> tap(String key) async {
    final target = find.byKey(ValueKey(key));
    if (key == 'resource-manage-containers' && target.evaluate().isEmpty) {
      await text('Actions');
    }
    await tester.ensureVisible(target);
    await tester.pump();
    await tester.tap(target);
    await pumpIo(tester, frames: 12);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  Future<void> cell(int x, int y) async {
    final canvas = find.byKey(const ValueKey('map-canvas'));
    final rect = tester.getRect(canvas);
    final size = fixture.controller.active!.current.size;
    await tester.tapAt(
      rect.topLeft +
          Offset(
            (x + .5) * rect.width / size.width,
            (y + .5) * rect.height / size.height,
          ),
    );
    await pumpIo(tester, frames: 4);
  }

  Future<void> saveMap() async {
    await tap('Enregistrer');
    expect(
      fixture.controller.active!.dirty,
      false,
      reason: fixture.controller.active!.error,
    );
  }

  Future<void> close() async {
    if (closed) return;
    closed = true;
    fixture.controller.dispose();
    exporter.dispose();
    navigationHome.dispose();
    await WidgetResourcePort.serial(tester, fixture.resources.dispose);
    await WidgetResourcePort.serial(
      tester,
      () => sessions.close(fixture.session),
    );
  }
}
