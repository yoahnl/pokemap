import 'dart:io';

import 'package:avelune_studio/features/game_export/data/studio_game_export_controller.dart';
import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'm3_story_fixture.dart';

class AuthoringExportFixture {
  AuthoringExportFixture._(
    this.tester,
    this.source,
    this.maps,
    this.gameExport,
  );

  final WidgetTester tester;
  final M3StoryFixture source;
  final MapWorkspaceController maps;
  final StudioGameExportController gameExport;

  EditableMapDocument get document => maps.active!;

  static Future<AuthoringExportFixture> open(
    WidgetTester tester, {
    required Future<void> Function(M3StoryFixture) prepareSource,
    Future<void> Function(String)? prepareProjectAssets,
  }) async {
    M3StoryFixture? ownedSource;
    MapWorkspaceController? ownedMaps;
    StudioGameExportController? ownedExport;
    addTearDown(() async {
      ownedExport?.dispose();
      ownedMaps?.dispose();
      final source = ownedSource;
      if (source == null) return;
      await tester.runAsync(() async {
        if (await source.directory.exists()) {
          await source.directory.delete(recursive: true);
        }
      });
    });
    return (await tester.runAsync(() async {
      final parent = Directory(
        '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109',
      );
      await parent.create(recursive: true);
      final source = await M3StoryFixture.create(parent: parent);
      ownedSource = source;
      await prepareSource(source);
      final maps = MapWorkspaceController(source.session, source.maps);
      ownedMaps = maps;
      await maps.initialize();
      final gameExport = StudioGameExportController(
        projectRoot: source.directory,
        projectName: source.session.name,
        prepareProjectAssets: prepareProjectAssets,
      );
      ownedExport = gameExport;
      await gameExport.load();
      return AuthoringExportFixture._(tester, source, maps, gameExport);
    }))!;
  }

  Future<Map<String, List<int>>> disk() async => (await tester.runAsync(
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

  Future<void> export(File destination) async {
    final result = await tester.runAsync(
      () => gameExport.export(
        metadata:
            gameExport.metadata?.copyWith(author: 'Avelune') ??
            StudioGameExportMetadata(
              gameId: 'avelune.t01.fixture',
              title: source.session.name,
              version: '1.0.0',
              author: 'Avelune',
              locale: 'fr',
              locales: 'fr',
            ),
        outputPath: destination.path,
        overwriteConfirmed: false,
        publication: true,
        prepare: () async {
          for (final document in maps.documents.values) {
            if (!await maps.save(document)) return false;
          }
          return true;
        },
        hasPendingChanges: () => maps.dirty,
        isCurrentProject: () => !maps.isDisposed,
      ),
    );
    expect(result, isTrue, reason: gameExport.error);
    expect(gameExport.stage, StudioExportStage.completed);
  }
}
