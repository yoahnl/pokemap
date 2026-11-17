import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  test(
      'canonical export ships translated dialogue identities and its capability',
      () async {
    final root = await Directory.systemTemp.createTemp('localized-export-');
    addTearDown(() => root.delete(recursive: true));
    const source =
        'title: Start\n---\nBonjour\n-> Partir\n    <<outcome leave>>\n    Au revoir\n-> Rester\n    <<outcome stay>>\n    À bientôt\n===\n';
    final opened = readLocalizedDialogue(source: source, sourceLocale: 'fr');
    var localization = opened.localization;
    const translations = ['Hello', 'Leave', 'Goodbye', 'Stay', 'See you'];
    for (final (index, unit) in localization.units.indexed) {
      localization = localization.translate(unit.id, 'en', translations[index]);
    }
    final files = spatialPayload();
    final project = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(files['project/project.json']!)));
    files['project/project.json'] = utf8.encode(jsonEncode(project.copyWith(
      dialogues: [
        ProjectDialogueEntry(
          id: 'talk',
          name: 'Accueil',
          relativePath: 'dialogues/talk.yarn',
          localization: localization,
        ),
      ],
    ).toJson()));
    files['project/dialogues/talk.yarn'] = utf8.encode(source);
    for (final entry in files.entries) {
      final file =
          File('${root.path}/${entry.key.substring('project/'.length)}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
    final artifact = await const CanonicalGamePackageExportService().build(
      projectRoot: root,
      profile: GamePackageExportProfile(
        gameId: 'games.example.localization',
        gameVersion: '0.1.0',
        title: 'Langues',
        authorName: 'Yoahn',
        defaultLocale: 'fr',
        supportedLocales: ['fr', 'en'],
      ),
      mode: GamePackageExportMode.localTest,
    );
    expect(artifact.manifest.compatibility.requiredCapabilities,
        contains(dialogueLocalizationCapability));
    expect(artifact.compiledDialogueCount, 1);
    final archived = {
      for (final file in ZipDecoder().decodeBytes(artifact.packageBytes).files)
        file.name: file.content,
    };
    final exported = PortableCatalogPublication.decodeProjectSync(
        jsonDecode(utf8.decode(archived['project/project.json']!)),
        readObject: (ref) =>
            archived['project/${PortableCatalogPublication.objectPath(ref)}']!);
    final dialogue = exported.dialogues.single;
    expect(dialogue.localization!.units.map((unit) => unit.id),
        localization.units.map((unit) => unit.id));
    final compiled = const RuntimeDialogueDocumentCodec()
        .decodeUtf8(archived['project/${dialogue.relativePath}']!);
    final resolved = resolveRuntimeDialogueLocalization(
        compiled, dialogue.localization!,
        preferredLocale: 'en',
        locales: ProjectLocalePolicy(
            supportedLocales: ['fr', 'en'], fallbackLocale: 'fr'));
    expect(runtimeDialogueTextScopes(resolved).map((scope) => scope.text),
        translations);
    expect(
        runtimeDialogueTextShape(resolved), runtimeDialogueTextShape(compiled));
    final choices =
        resolved.nodes.single.steps[1] as RuntimeDialogueChoiceBlock;
    expect(
        choices.choices.map((choice) => choice.outcomeId), ['leave', 'stay']);
    for (final entry in files.entries) {
      expect(
          await File('${root.path}/${entry.key.substring('project/'.length)}')
              .readAsBytes(),
          entry.value);
    }
  });
}
