import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _stepWithoutJournal =
    '{"id":"meet_rival","title":"Rencontrer le rival","description":"Au labo",'
    '"order":0,"completionCondition":{"type":"factEquals","params":'
    '{"factId":"met_rival","valueType":"bool","value":"true"},"children":[]},'
    '"sceneLinkIds":[],"expectedOutcomeIds":[],"status":"active",'
    '"authorNotes":"note","metadata":{"k":"v"}}';

const _storylineWithoutJournal =
    '{"id":"main","schemaVersion":1,"type":"main","status":"active",'
    '"title":"Trame","chapters":[{"id":"c1","title":"Chapitre","order":0,'
    '"steps":[$_stepWithoutJournal],"directSceneLinkIds":[],"metadata":{}}],'
    '"sceneLinks":[],"relationships":[],"metadata":{}}';

void main() {
  group('characterization without journal data', () {
    test('a milestone without journal round-trips byte for byte', () {
      final decoded = StorylineStep.fromJson(
        jsonDecode(_stepWithoutJournal) as Map<String, dynamic>,
      );

      expect(jsonEncode(decoded.toJson()), _stepWithoutJournal);
    });

    test('a storyline without clue notes round-trips byte for byte', () {
      final decoded = StorylineAsset.fromJson(
        jsonDecode(_storylineWithoutJournal) as Map<String, dynamic>,
      );

      expect(jsonEncode(decoded.toJson()), _storylineWithoutJournal);
    });
  });

  group('journal data', () {
    final journal = StorylineMilestoneJournal(
      title: SceneLocalizedText(
        fallback: 'Le rival',
        translations: {'en': 'The rival'},
      ),
      text: SceneLocalizedText(fallback: 'Il attend au labo.'),
    );
    final clue = StorylineJournalClue(
      id: 'footprints',
      factId: 'saw_footprints',
      text: SceneLocalizedText(fallback: 'Des traces mènent au nord.'),
    );

    test('a milestone journal round-trips and is appended last', () {
      final step = StorylineStep.fromJson(
        jsonDecode(_stepWithoutJournal) as Map<String, dynamic>,
      ).copyWith(journal: journal);

      final json = step.toJson();
      final decoded = StorylineStep.fromJson(
        jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
      );

      expect(decoded, step);
      expect(json.keys.last, 'journal');
      expect(json['journal'], {
        'title': {
          'fallback': 'Le rival',
          'translations': {'en': 'The rival'},
        },
        'text': {'fallback': 'Il attend au labo.'},
      });
      expect(
        jsonEncode(step.copyWith(journal: null).toJson()),
        _stepWithoutJournal,
      );
    });

    test('clue notes round-trip on the storyline', () {
      final storyline = StorylineAsset.fromJson(
        jsonDecode(_storylineWithoutJournal) as Map<String, dynamic>,
      ).copyWith(journalClues: [clue]);

      final json = storyline.toJson();
      final decoded = StorylineAsset.fromJson(
        jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
      );

      expect(decoded, storyline);
      expect(json.keys.last, 'journalClues');
      expect(json['journalClues'], [
        {
          'id': 'footprints',
          'factId': 'saw_footprints',
          'text': {'fallback': 'Des traces mènent au nord.'},
        },
      ]);
    });

    test('rejects blank, oversized and duplicated journal data', () {
      expect(
        () => StorylineMilestoneJournal(
          title: SceneLocalizedText(fallback: '  '),
          text: SceneLocalizedText(fallback: 'x'),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => StorylineMilestoneJournal(
          title: SceneLocalizedText(
            fallback: 'ok',
            translations: {'en': 'x' * (storylineJournalTitleMaxLength + 1)},
          ),
          text: SceneLocalizedText(fallback: 'x'),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => StorylineMilestoneJournal(
          title: SceneLocalizedText(fallback: 'ok'),
          text: SceneLocalizedText(
            fallback: 'x' * (storylineJournalTextMaxLength + 1),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => StorylineJournalClue(
          id: ' padded',
          factId: 'f',
          text: SceneLocalizedText(fallback: 'x'),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => StorylineAsset(
          id: 'main',
          type: StorylineType.main,
          title: 'Trame',
          journalClues: [clue, clue],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects a journal that is not a localized text object', () {
      final json = jsonDecode(_stepWithoutJournal) as Map<String, dynamic>
        ..['journal'] = {'title': 'Le rival', 'text': 3};

      expect(
        () => StorylineStep.fromJson(json),
        throwsA(isA<ValidationException>()),
      );
    });

    test('step and storyline copies used by authoring keep journal data', () {
      final project = ProjectManifest(
        name: 'Journal',
        maps: const [],
        tilesets: const [],
        storylines: [
          StorylineAsset.fromJson(
            jsonDecode(_storylineWithoutJournal) as Map<String, dynamic>,
          ).copyWith(journalClues: [clue]),
        ],
      );
      final withJournal = setStorylineMilestoneJournal(
        project,
        storylineId: 'main',
        chapterId: 'c1',
        stepId: 'meet_rival',
        journal: journal,
      ).after;

      final duplicated = duplicateStoryline(
        withJournal,
        storylineId: 'main',
        duplicateId: 'copy',
        title: 'Copie',
      ).after.storylines.last;

      expect(duplicated.journalClues, [clue]);
      expect(duplicated.chapters.single.steps.single.journal, journal);
    });
  });
}
