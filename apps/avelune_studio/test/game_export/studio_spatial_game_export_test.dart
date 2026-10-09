import 'dart:io';

import 'package:avelune_studio/features/game_export/data/studio_game_export_controller.dart';
import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/presentation/features/game_export/studio_game_export_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_action_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../support/game_export_fixture.dart';
import '../support/map_host_fixture.dart';
import '../support/m3_story_fixture.dart';

void main() {
  StudioActionCard card(WidgetTester tester, String title) => tester
      .widgetList<StudioActionCard>(find.byType(StudioActionCard))
      .singleWhere((card) => card.title == title);

  testWidgets(
    '3D workspace defaults to testing and explains the release gate',
    (tester) async {
      final fixture = await MapHostFixture.open(
        tester,
        prepareSource: prepareGameExportFixture,
        gameExportPicker: (_) async => null,
      );
      final project = fixture.maps.project!;
      fixture.maps.project = project.copyWith(
        settings: project.settings.copyWith(dimension: ProjectDimension.threeD),
      );
      await fixture.openExport();
      final page = tester.widget<StudioGameExportPage>(
        find.byType(StudioGameExportPage),
      );
      expect(page.publicationAvailable, isFalse);
      expect(card(tester, 'Test local').selected, isTrue);
      expect(card(tester, 'Publication').selected, isFalse);
      expect(card(tester, 'Publication').onPressed, isNull);
      expect(
        find.textContaining('validation complète sur iOS et Android'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('2D workspace keeps publication available by default', (
    tester,
  ) async {
    final fixture = await MapHostFixture.open(
      tester,
      prepareSource: prepareGameExportFixture,
      gameExportPicker: (_) async => null,
    );
    await fixture.openExport();
    expect(card(tester, 'Publication').selected, isTrue);
    expect(card(tester, 'Publication').onPressed, isNotNull);
    expect(card(tester, 'Test local').selected, isFalse);
    expect(
      find.textContaining('validation complète sur iOS et Android'),
      findsNothing,
    );
  });

  test('canonical 3D publication refusal is explained in French', () async {
    final source = await M3StoryFixture.create();
    final output = await Directory.systemTemp.createTemp('as-spatial-export-');
    addTearDown(() async {
      await source.directory.delete(recursive: true);
      await output.delete(recursive: true);
    });
    final controller = StudioGameExportController(
      projectRoot: source.directory,
      projectName: source.session.name,
      buildPackage: (_, _, _) async => throw const GamePackageExportException(
        code: 'runtime3d.publication_unsupported',
        path: 'project.json',
        message:
            '3D exploration packages can only be exported for local testing.',
      ),
    );
    addTearDown(controller.dispose);
    final file = File('${output.path}/test.avelunegame');
    expect(
      await controller.export(
        metadata: const StudioGameExportMetadata(
          gameId: 'games.avelune.test',
          title: 'Test',
          version: '0.1.0',
          author: 'Avelune',
          locale: 'fr',
          locales: 'fr',
        ),
        outputPath: file.path,
        overwriteConfirmed: false,
        publication: true,
        prepare: () async => true,
        hasPendingChanges: () => false,
        isCurrentProject: () => true,
      ),
      isFalse,
    );
    expect(
      controller.error,
      contains('export 3D est disponible en mode Test local'),
    );
    expect(await file.exists(), isFalse);
  });
}
