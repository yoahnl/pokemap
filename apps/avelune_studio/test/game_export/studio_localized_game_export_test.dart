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

  test('Studio exports saved translations with a speaker through its production controller', () async {
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
    final sourceFile = File('${fixture.directory.path}/${entry.relativePath}');
    const frenchGreeting = 'Guide: Bonjour !';
    const englishGreeting = 'Guide: Hello!';
    const untranslated = 'Le phare est ouvert.';
    final source = (await sourceFile.readAsString()).replaceFirst(
        '\\${jsonEncode('Bienvenue sur le quai.')}',
        '$frenchGreeting\n$untranslated',
    );
    await sourceFile.writeAsString(source);
    var catalog = readLocalizedDialogue(
      source: source,
      sourceLocale: 'fr',
    ).localization;
      expect(catalog.units.map((unit) => unit.source), ['Bonjour !', untranslated]);
    final [greeting, fallback] = catalog.units;
    catalog = catalog.translate(greeting.id, 'en', 'Hello!');
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
    final localization = translated.localization!;
    expect(localization.units.map((unit) => unit.id), [
      greeting.id,
      fallback.id,
    ]);
    final idsByBinding = {
      for (final unit in localization.units) unit.binding: unit.id,
    };
    final locales = ProjectLocalePolicy(
      supportedLocales: ['fr', 'en'],
      fallbackLocale: 'fr',
    );
    Map<String, String> texts(String locale) => {
      for (final scope in runtimeDialogueTextScopes(
        resolveRuntimeDialogueLocalization(
          document,
          localization,
          preferredLocale: locale,
          locales: locales,
        ),
      ))
        idsByBinding[scope.binding]!: scope.text,
    };
    expect(texts('fr'), {
      greeting.id: frenchGreeting,
      fallback.id: untranslated,
    });
    expect(texts('en'), {
      greeting.id: englishGreeting,
      fallback.id: untranslated,
    });
    final fallbackResolution = localization.resolve(
      fallback.id,
      preferredLocale: 'en',
      supportedLocales: locales.supportedLocales,
      fallbackLocale: locales.fallbackLocale,
    );
    expect(fallbackResolution.usedFallback, isTrue);
    expect(fallbackResolution.textLocale, 'fr');
    expect(await projectFile.readAsBytes(), before);
    expect(await sourceFile.readAsString(), source);
  });
}
