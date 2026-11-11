import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../../avelune_studio/test/support/m2_ui_owner_fixture.dart';
import '../../../../avelune_studio/test/support/m3_story_fixture.dart';
import '../../../../avelune_studio/test/support/real_test_io.dart';
import 'uwu5_specialized_resources_fixture.dart';

class Uwu6ResourceHost {
  Uwu6ResourceHost._(
    this.tester,
    this.fixture,
    this.navigation,
    this.sessions,
    this.temporary,
    this.package,
  );
  final WidgetTester tester;
  final M2UiOwnerFixture fixture;
  final ResourceNavigation navigation;
  final LocalProjectSessionAdapter sessions;
  final Directory temporary;
  final File package;
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
        (await RealTestIo.run(
          tester,
          () => Directory.systemTemp.createTemp('uwu6-resources-player-'),
        ))!;
    final source =
        (await RealTestIo.run(tester, () async {
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
      await host.close();
      await RealTestIo.run(tester, () async {
        if (await source.directory.exists()) {
          await source.directory.delete(recursive: true);
        }
        if (await temporary.exists()) await temporary.delete(recursive: true);
      });
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
        (await RealTestIo.run(tester, () async {
          final session = await sessions.open(directory.path);
          final maps = LocalMapWorkspaceAdapter();
          final controller = MapWorkspaceController(session, maps);
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
          final fixture = M2UiOwnerFixture(
            directory,
            session,
            maps,
            controller,
            LocalResourceAdapter(session: session, mapAdapter: maps),
          );
          fixture.visuals = await StudioMapResources.load(
            session,
            controller.project!,
          );
          return fixture;
        }))!;
    final navigation = ResourceNavigation(
      workspace: fixture.controller,
      port: fixture.resources,
      visuals: fixture.visuals!,
      onUse: (_) {},
    );
    return Uwu6ResourceHost._(
      tester,
      fixture,
      navigation,
      sessions,
      temporary,
      File(p.join(temporary.path, 'uwu6-resources.avelunegame')),
    );
  }

  Future<T> io<T>(Future<T> Function() action) async {
    Object? failure;
    StackTrace? trace;
    final result = await RealTestIo.run<T?>(tester, () async {
      try {
        return await action();
      } on Object catch (error, stack) {
        failure = error;
        trace = stack;
        return null;
      }
    });
    if (failure case final error?) Error.throwWithStackTrace(error, trace!);
    return result as T;
  }

  Future<PickedResourceImage> pickImage() async {
    final bytes = Uint8List.fromList(replacement ? newPixels : oldPixels);
    final file = File(
      p.join(temporary.path, replacement ? 'new.png' : 'old.png'),
    );
    await file.writeAsBytes(bytes);
    return PickedResourceImage(
      file.path,
      'Planche témoin UwU VI',
      bytes,
      32,
      32,
    );
  }

  Future<ProjectManifest> read() async {
    final reader = LocalProjectSessionAdapter();
    final session = await reader.open(fixture.directory.path);
    try {
      return await LocalMapWorkspaceAdapter().loadProject(session);
    } finally {
      await reader.close(session);
    }
  }

  Future<ProjectManifest> reopen() => io(read);

  Future<void> close() async {
    if (closed) return;
    closed = true;
    navigation.dispose();
    fixture.controller.dispose();
    await io(() async {
      await fixture.visuals?.dispose();
      await fixture.resources.dispose();
      await sessions.close(fixture.session);
    });
  }
}
