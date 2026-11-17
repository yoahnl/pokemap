import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  for (final withLocalization in [false, true]) {
    test(
        'export preserves authoring content and declares localized runtime needs, localized=$withLocalization',
        () async {
      final root = await Directory.systemTemp.createTemp('dialogue_export_');
      addTearDown(() => root.delete(recursive: true));
      const source = 'title: Start\n---\nBonjour\n===\n';
      final draft = readLocalizedDialogue(source: source, sourceLocale: 'fr');
      final files = spatialPayload();
      final project = ProjectManifest.fromJson(
          jsonDecode(utf8.decode(files['project/project.json']!)));
      final localized = project.copyWith(dialogues: [
        ProjectDialogueEntry(
          id: 'talk',
          name: 'Accueil',
          relativePath: 'dialogues/talk.yarn',
          localization: withLocalization
              ? draft.localization
                  .translate(draft.localization.units.single.id, 'en', 'Hello')
              : null,
        )
      ]);
      files['project/project.json'] =
          utf8.encode(jsonEncode(localized.toJson()));
      files['project/dialogues/talk.yarn'] = utf8.encode(source);
      for (final entry in files.entries) {
        final file =
            File('${root.path}/${entry.key.substring('project/'.length)}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value);
      }
      final exporting = const CanonicalGamePackageExportService().build(
          projectRoot: root,
          profile: GamePackageExportProfile(
              gameId: 'games.example.localization',
              gameVersion: '0.1.0',
              title: 'Langues',
              authorName: 'Yoahn',
              defaultLocale: 'fr',
              supportedLocales: ['fr', 'en']),
          mode: GamePackageExportMode.localTest);
      final artifact = await exporting;
      expect(
          artifact.manifest.compatibility.requiredCapabilities
              .contains(dialogueLocalizationCapability),
          withLocalization);
      for (final entry in files.entries) {
        expect(
            await File('${root.path}/${entry.key.substring('project/'.length)}')
                .readAsBytes(),
            entry.value);
      }
    });
  }
}
