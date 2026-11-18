import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:avelune_studio/features/game_export/data/studio_game_export_controller.dart';
import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core.dart';

import '../support/game_export_fixture.dart';
import '../support/m3_story_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Studio exports saved translations with a speaker through its production controller',
    () async {
      final fixture = await M3StoryFixture.create();
      final output = await Directory.systemTemp.createTemp(
        'studio-localized-export-',
      );
      addTearDown(() async {
        await fixture.directory.delete(recursive: true);
        await output.delete(recursive: true);
      });
      await prepareGameExportFixture(fixture);
      final projectFile = File('${fixture.directory.path}/project.json');
      final project = ProjectManifest.fromJson(
        jsonDecode(await projectFile.readAsString()),
      );
      final entry = project.dialogues.single;
      final sourceFile = File(
        '${fixture.directory.path}/${entry.relativePath}',
      );
      final source = (await sourceFile.readAsString())
          .replaceFirst('\n---\n', '\n---\nGuide: ');
      await sourceFile.writeAsString(source);
      var catalog = readLocalizedDialogue(
        source: source,
        sourceLocale: 'fr',
      ).localization;
      for (final unit in catalog.units) {
        catalog = catalog.translate(unit.id, 'en', 'Welcome');
      }
      await projectFile.writeAsString(
        jsonEncode(
          project
              .copyWith(dialogues: [entry.copyWith(localization: catalog)])
              .toJson(),
        ),
      );
      final before = await projectFile.readAsBytes();
      final controller = StudioGameExportController(
        projectRoot: fixture.directory,
        projectName: project.name,
      );
      addTearDown(controller.dispose);
      await controller.load();
      var prepared = false;
      final result = await controller.export(
        metadata: const StudioGameExportMetadata(
          gameId: 'games.example.studio-localized',
          title: 'Localized',
          version: '0.1.0',
          author: 'Yoahn',
          locale: 'fr',
          locales: 'fr,en',
        ),
        outputPath: '${output.path}/localized.avelunegame',
        overwriteConfirmed: false,
        publication: false,
        prepare: () async {
          prepared = true;
          return true;
        },
        hasPendingChanges: () => false,
        isCurrentProject: () => true,
      );
      expect(result, isTrue, reason: controller.error);
      expect(prepared, isTrue);
      expect(controller.stage, StudioExportStage.completed);
      final archive = ZipDecoder().decodeBytes(
        await File(controller.outputPath!).readAsBytes(),
      );
      final exported = PortableCatalogPublication.decodeProjectSync(
        jsonDecode(
          utf8.decode(archive.findFile('project/project.json')!.content),
        ),
        readObject: (ref) => archive
            .findFile('project/${PortableCatalogPublication.objectPath(ref)}')!
            .content,
      );
      final translated = exported.dialogues.single;
      final document = const RuntimeDialogueDocumentCodec().decodeUtf8(
        archive.findFile('project/${translated.relativePath}')!.content,
      );
      final resolved = resolveRuntimeDialogueLocalization(
        document,
        translated.localization!,
        preferredLocale: 'en',
        locales: ProjectLocalePolicy(
          supportedLocales: ['fr', 'en'],
          fallbackLocale: 'fr',
        ),
      );
      expect(
        runtimeDialogueTextScopes(resolved).map((scope) => scope.text),
        contains('Guide: Welcome'),
      );
      expect(
        translated.localization!.units.map((unit) => unit.id),
        catalog.units.map((unit) => unit.id),
      );
      expect(await projectFile.readAsBytes(), before);
      expect(await sourceFile.readAsString(), source);
    },
  );
}
