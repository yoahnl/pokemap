import 'dart:io';

import 'package:avelune_studio/features/game_export/data/studio_game_export_controller.dart';
import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'm3_story_fixture.dart';
import 'real_test_io.dart';

class MapHostOwnerFixture {
  MapHostOwnerFixture._(this.tester, this.source, this.maps, this.gameExport);

  final WidgetTester tester;
  final M3StoryFixture source;
  final MapWorkspaceController maps;
  final StudioGameExportController gameExport;

  EditableMapDocument get document => maps.active!;

  static Future<MapHostOwnerFixture> open(
    WidgetTester tester, {
    Future<void> Function(M3StoryFixture source)? prepareSource,
  }) async {
    final (source, maps) = (await RealTestIo.run(tester, () async {
      final source = await M3StoryFixture.create();
      if (prepareSource != null) await prepareSource(source);
      final maps = MapWorkspaceController(source.session, source.maps);
      await maps.initialize();
      return (source, maps);
    }))!;
    final gameExport = StudioGameExportController(
      projectRoot: source.directory,
      projectName: source.session.name,
    );
    addTearDown(() async {
      gameExport.dispose();
      maps.dispose();
      await RealTestIo.run(tester, () async {
        if (await source.directory.exists()) {
          await source.directory.delete(recursive: true);
        }
      });
    });
    return MapHostOwnerFixture._(tester, source, maps, gameExport);
  }

  Future<bool> save() async =>
      await RealTestIo.run(tester, () => maps.save(document)) ?? false;

  Future<bool> exportGame(File package, {required String author}) async =>
      await RealTestIo.run(tester, () async {
        await gameExport.load();
        return gameExport.export(
          metadata: StudioGameExportMetadata(
            gameId: 'games.avelune.map-host-owner',
            title: source.session.name,
            version: '0.1.0',
            author: author,
            locale: 'fr',
            locales: 'fr',
          ),
          outputPath: package.path,
          overwriteConfirmed: false,
          publication: false,
          prepare: () async => !document.dirty || await maps.save(document),
          hasPendingChanges: () => maps.dirty,
          isCurrentProject: () => !maps.isDisposed,
        );
      }) ??
      false;

  Future<Map<String, List<int>>> disk() async =>
      (await RealTestIo.run(
        tester,
        () async => {
          for (final file
              in await source.directory
                  .list(recursive: true)
                  .where(
                    (file) => file is File && !file.path.contains('/.pokemap/'),
                  )
                  .cast<File>()
                  .toList())
            file.path.substring(source.directory.path.length): await file
                .readAsBytes(),
        },
      ))!;
}
