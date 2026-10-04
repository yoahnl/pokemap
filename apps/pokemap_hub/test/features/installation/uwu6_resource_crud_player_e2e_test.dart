import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'uwu4_resource_replacement_player_support.dart';
import 'uwu5_specialized_resources_player_support.dart';
import 'uwu6_resource_host.dart';
import 'uwu6_resource_image_steps.dart';
import 'uwu6_resource_specialized_steps.dart';
import 'uwu6_resource_border_steps.dart';
import 'uwu6_resource_player_movement.dart';
import 'uwu6_resource_player_visuals.dart';
import 'uwu6_resource_export_steps.dart';

void main() {
  testWidgets(
    'resource CRUD through actual Studio UI survives independent installation',
    (tester) async {
      var host = await Uwu6ResourceHost.create(tester);
      final temporary = host.temporary;
      final source = host.fixture.directory;
      final ownedSource = (await tester.runAsync(source.resolveSymbolicLinks))!;
      final systemTemp =
          (await tester.runAsync(Directory.systemTemp.resolveSymbolicLinks))!;
      expect(p.isWithin(systemTemp, ownedSource), true);
      final mapId = host.fixture.controller.active!.current.id;
      print(
        'UWU6_RESOURCE_SEED maps=${host.fixture.controller.project!.maps.length} borderLayers=0 terrain=published portraits=preloaded',
      );
      final image = await editUwu6Images(host);
      await editUwu6Terrain(host);
      await resolveUwu6Characters(host);
      await drawUwu6Border(host);
      await deprecateUwu6Border(host);
      final expected = host.fixture.controller.active!.current;
      await tester.pumpWidget(const SizedBox());
      await host.close();

      host = await Uwu6ResourceHost.openExisting(tester, source, temporary);
      addTearDown(host.close);
      final after = await host.reopen();
      expect(
        after.tilesets.singleWhere((entry) => entry.id == image.sheetId).name,
        'Planche émeraude — témoin',
      );
      expect(after.smartTileCatalog.presets, hasLength(2));
      expect(after.borderCatalog.records.single.isDeprecated, true);
      expect(after.settings.defaultPlayerCharacterId, 'uwu5-replacement');
      expect(host.fixture.controller.active!.current, expected);
      final second = after.maps.singleWhere((entry) => entry.id != mapId);
      await tester.pumpWidget(const SizedBox());
      await host.close();
      host = await Uwu6ResourceHost.openExisting(
        tester,
        source,
        temporary,
        initialMapId: second.id,
      );
      addTearDown(host.close);
      await inspectUwu6ClosedUsages(host, image.sheetId, image.placedId, mapId);

      final authored = await host.reopen();
      await exportUwu6Resources(host);
      final read = LocalProjectSessionAdapter();
      final authoredMap =
          (await tester.runAsync(() async {
            final session = await read.open(source.path);
            try {
              final maps = LocalMapWorkspaceAdapter();
              await maps.loadProject(session);
              return (await maps.loadMap(
                session,
                authored.maps.singleWhere((entry) => entry.id == mapId),
              )).map;
            } finally {
              await read.close(session);
            }
          }))!;
      expect(authoredMap, expected);
      await tester.pumpWidget(const SizedBox());
      await host.close();
      final hidden = Directory('${source.path}.uwu6-offline');
      expect(await tester.runAsync(source.resolveSymbolicLinks), ownedSource);
      expect(p.isWithin(systemTemp, ownedSource), true);
      await tester.runAsync(() => source.rename(hidden.path));
      final ownedHidden = (await tester.runAsync(hidden.resolveSymbolicLinks))!;
      addTearDown(() async {
        if (await hidden.exists()) {
          expect(await hidden.resolveSymbolicLinks(), ownedHidden);
          expect(p.isWithin(systemTemp, ownedHidden), true);
          await hidden.delete(recursive: true);
        }
      });
      expect(await tester.runAsync(source.exists), false);
      print('UWU6_RESOURCE_AUTHOR_CLOSED=${host.closed} sourceAbsent=true');
      await playReplacedPackage(
        tester,
        host.package,
        Directory(p.join(temporary.path, 'pixels-installation')),
        authored: authored,
        tilesetId: image.sheetId,
        elementId: image.decorId,
        placedId: image.placedId,
        expectedPixels: host.newPixels,
      );
      await playUwu5InstalledPackage(
        tester,
        host.package,
        Directory(p.join(temporary.path, 'specialized-installation')),
        authored: authored,
        authoredMap: authoredMap,
        verifyAdditionalMovement: verifyUwu6BorderVisualSemantics,
        verifyBundle: verifyUwu6InstalledConnections,
        verifyFrame: verifyUwu6InstalledConnectionPixels,
      );
      expect(await tester.runAsync(source.exists), false);
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
