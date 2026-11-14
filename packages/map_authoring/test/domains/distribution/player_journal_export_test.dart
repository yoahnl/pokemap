import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  test('export declares the player journal only when the project has one',
      () async {
    final plain = await _export(withJournal: false);
    final journal = await _export(withJournal: true);

    expect(plain, isNot(contains(PlayerJournalCapabilities.capabilityId)));
    expect(journal, contains(PlayerJournalCapabilities.capabilityId));
    expect(
      journal.difference(plain),
      {PlayerJournalCapabilities.capabilityId},
    );
    expect(plain.difference(journal), isEmpty);
  });
}

Future<Set<String>> _export({required bool withJournal}) async {
  final qa = await Directory('/Users/karim/Library/Caches/AveluneQA/c6')
      .create(recursive: true);
  final root = await qa.createTemp('journal-export-');
  addTearDown(() => root.delete(recursive: true));
  final files = spatialPayload();
  final project = ProjectManifest.fromJson(
      jsonDecode(utf8.decode(files['project/project.json']!)));
  files['project/project.json'] = utf8.encode(jsonEncode(project.copyWith(
    facts: [
      ...project.facts,
      NarrativeFactDefinition(id: 'saw_tracks', label: 'Traces'),
    ],
    storylines: [
      StorylineAsset(
        id: 'main',
        type: StorylineType.main,
        title: 'Trame',
        chapters: [
          StorylineChapter(id: 'c1', title: 'Un', order: 0, steps: [
            StorylineStep(
              id: 'm1',
              title: 'Rival',
              order: 0,
              journal: withJournal
                  ? StorylineMilestoneJournal(
                      title: SceneLocalizedText(fallback: 'Le rival'),
                      text: SceneLocalizedText(fallback: 'Il attend.'),
                    )
                  : null,
            ),
          ]),
        ],
        journalClues: [
          if (withJournal)
            StorylineJournalClue(
              id: 'tracks',
              factId: 'saw_tracks',
              text: SceneLocalizedText(fallback: 'Des traces au nord.'),
            ),
        ],
      ),
    ],
  ).toJson()));
  for (final entry in files.entries) {
    final file = File('${root.path}/${entry.key.substring('project/'.length)}');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(entry.value);
  }
  final artifact = await const CanonicalGamePackageExportService().build(
    projectRoot: root,
    profile: GamePackageExportProfile(
        gameId: 'games.example.journal',
        gameVersion: '0.1.0',
        title: 'Journal',
        authorName: 'Yoahn',
        defaultLocale: 'fr',
        supportedLocales: ['fr']),
    mode: GamePackageExportMode.localTest,
  );
  for (final entry in files.entries) {
    expect(
        await File('${root.path}/${entry.key.substring('project/'.length)}')
            .readAsBytes(),
        entry.value);
  }
  return artifact.manifest.compatibility.requiredCapabilities.toSet();
}
