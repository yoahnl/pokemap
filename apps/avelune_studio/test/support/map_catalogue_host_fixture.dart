import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'm2_ui_fixture.dart' show pumpIo;
import 'project_creation_workspace_fixture.dart';

class MapCatalogueHostFixture {
  MapCatalogueHostFixture(this.tester, this.parent, this.host);
  final WidgetTester tester;
  final Directory parent;
  final ProjectCreationWorkspaceFixture host;

  static Future<MapCatalogueHostFixture> open(
    WidgetTester tester, {
    bool empty = false,
    Size size = const Size(1536, 1024),
    double textScale = 1,
    GlobalKey? captureKey,
  }) async {
    final parent = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('uwu-map-catalogue-'),
    ))!;
    final host = ProjectCreationWorkspaceFixture(
      tester,
      parent,
      File('${parent.path}/fixture.avelunegame'),
    );
    addTearDown(() async {
      await host.dispose();
      await tester.runAsync(() => parent.delete(recursive: true));
    });
    await host.mount(size: size, textScale: textScale, captureKey: captureKey);
    if (empty) {
      await tester.tap(find.text('Nouveau projet'));
      await pumpIo(tester, frames: 3);
      await tester.enterText(
        find.widgetWithText(TextField, 'Nom du projet'),
        'Projet vide UwU',
      );
      await host.next();
      await tester.tap(find.text('Projet vide'));
      await host.next();
      await tester.tap(find.byKey(const ValueKey('creation-grid-16')));
      await host.next();
      await tester.tap(find.byKey(const ValueKey('creation-choose-parent')));
      await pumpIo(tester, frames: 4);
      await tester.tap(find.byKey(const ValueKey('create-project-confirm')));
      for (var i = 0; i < 100 && host.session.state.project == null; i++) {
        await pumpIo(tester, frames: 3);
      }
      expect(host.session.state.project, isNotNull);
      await pumpIo(tester, frames: 20);
      if (find.text('Reprendre mon projet').evaluate().isNotEmpty) {
        await tester.tap(find.text('Reprendre mon projet'));
      }
      await pumpIo(tester, frames: 4);
    } else {
      await host.create(32, name: 'Clairbois UwU');
    }
    return MapCatalogueHostFixture(tester, parent, host);
  }

  Future<void> field(String key, String value) async {
    final finder = find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(finder);
    await tester.enterText(finder, value);
    await pumpIo(tester, frames: 2);
  }

  Future<void> tapKey(String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await pumpIo(tester, frames: 12);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<ProjectMapEntry> createMap(String name) async {
    await tapKey('new-map');
    await field('new-map-name', name);
    await tester.tap(find.text('Créer la carte'));
    await pumpIo(tester, frames: 20);
    final entry = host.maps.project!.maps.singleWhere((e) => e.name == name);
    expect(host.maps.active!.base.mapId, entry.id);
    return entry;
  }

  Future<void> mapAction(String id, String action) async {
    await tapKey('map-library-actions-$id');
    await tester.tap(find.text(action).last);
    await pumpIo(tester, frames: 12);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> renameMap(String id, String name) async {
    await mapAction(id, 'Renommer…');
    await field('rename-map-name', name);
    await tester.tap(find.text('Enregistrer').last);
    await pumpIo(tester, frames: 20);
  }

  Future<void> choose(String label, String option) async {
    final select = find.ancestor(
      of: find.text(label),
      matching: find.byType(DropdownButtonFormField<String>),
    );
    await tester.ensureVisible(select);
    await tester.tap(select);
    await pumpIo(tester, frames: 12);
    await tester.tap(find.text(option).last);
    await pumpIo(tester, frames: 3);
  }

  Future<ProjectMapGroup> createFolder(String name, {String? parent}) async {
    await tapKey('Nouveau dossier');
    await tester.enterText(
      find.widgetWithText(TextField, 'Nom du dossier'),
      name,
    );
    await tester.pump();
    if (parent != null) await choose('Dossier parent', parent);
    await tester.tap(find.text('Créer').last);
    await pumpIo(tester, frames: 20);
    expect(
      host.maps.project!.groups.any((g) => g.name == name),
      isTrue,
      reason:
          '${host.maps.error}\n${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().join(" | ")}',
    );
    return host.maps.project!.groups.lastWhere((g) => g.name == name);
  }

  Future<void> groupAction(String id, String action) async {
    await tapKey('map-library-group-actions-$id');
    await tester.tap(find.text(action).last);
    await pumpIo(tester, frames: 12);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<({ProjectManifest project, Map<String, MapData> maps})>
  reopen() async => (await tester.runAsync(() async {
    final sessions = LocalProjectSessionAdapter();
    final session = await sessions.open(
      host.session.state.project!.directoryPath,
    );
    try {
      final adapter = LocalMapWorkspaceAdapter();
      final project = await adapter.loadProject(session);
      final maps = <String, MapData>{};
      for (final entry in project.maps) {
        maps[entry.id] = (await adapter.loadMap(session, entry)).map;
      }
      return (project: project, maps: maps);
    } finally {
      await sessions.close(session);
    }
  }))!;

  Future<void> paintCollision() async {
    await tester.ensureVisible(find.text('Collisions'));
    await tester.tap(find.text('Collisions'));
    await pumpIo(tester, frames: 3);
    final canvas = tester.widget<MapWorkspaceCanvas>(
      find.byType(MapWorkspaceCanvas),
    );
    final surface = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey('map-canvas')),
    );
    final width =
        canvas.project.settings.tileWidth *
        canvas.project.settings.displayScale;
    final height =
        canvas.project.settings.tileHeight *
        canvas.project.settings.displayScale;
    final x = canvas.document.current.size.width ~/ 2;
    final y = canvas.document.current.size.height ~/ 2;
    await tester.tapAt(
      surface.localToGlobal(Offset((x + .5) * width, (y + .5) * height)),
    );
    await pumpIo(tester, frames: 12);
  }

  Future<void> preserveNativeFixture() async {
    final parent = Platform.environment['AVELUNE_UWU_NATIVE_PARENT'];
    if (parent == null) return;
    final path = (await tester.runAsync(() async {
      final root = Directory(host.session.state.project!.directoryPath);
      final target = await Directory(parent).createTemp('uwu-native-');
      await for (final source in root.list(
        recursive: true,
        followLinks: false,
      )) {
        final destination =
            '${target.path}${source.path.substring(root.path.length)}';
        if (source is Directory) {
          await Directory(destination).create(recursive: true);
        } else if (source is File) {
          await File(destination).parent.create(recursive: true);
          await source.copy(destination);
        }
      }
      return target.path;
    }))!;
    debugPrint('UWU_NATIVE_FIXTURE=$path');
  }
}
