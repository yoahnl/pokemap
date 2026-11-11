import 'package:avelune_studio/features/narrative/application/narrative_story_outline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  final story = StorylineAsset(
    id: 'main',
    type: StorylineType.main,
    title: 'Aventure',
    chapters: [
      StorylineChapter(
        id: 'late',
        title: 'Épilogue',
        order: 2,
        steps: [StorylineStep(id: 'bye', title: 'Adieux', order: 0)],
      ),
      StorylineChapter(
        id: 'early',
        title: 'Départ',
        order: 1,
        steps: [
          StorylineStep(id: 'b', title: 'Billet', order: 5),
          StorylineStep(id: 'a', title: 'Quai', order: 1),
          StorylineStep(id: 'c', title: 'Train', order: 5),
        ],
      ),
      StorylineChapter(id: 'empty', title: 'Vide', order: 3),
    ],
  );

  List<String> ids(List<NarrativeChapterOutline> outline) => [
    for (final entry in outline)
      '${entry.chapter.id}:${entry.steps.map((s) => s.id).join(',')}',
  ];

  test('without a query chapters and steps follow their order and ties keep the authored order', () {
    expect(ids(narrativeStoryOutline(story, '')), [
      'early:a,b,c',
      'late:bye',
      'empty:',
    ]);
    expect(ids(narrativeStoryOutline(story, '   ')), ids(narrativeStoryOutline(story, '')));
  });

  test('a step query keeps only the chapters that hold a matching step', () {
    expect(ids(narrativeStoryOutline(story, 'BILL')), ['early:b']);
    expect(ids(narrativeStoryOutline(story, 'train')), ['early:c']);
    expect(narrativeStoryOutline(story, 'introuvable'), isEmpty);
  });

  test('a chapter title match keeps every step of that chapter', () {
    expect(ids(narrativeStoryOutline(story, 'dép')), ['early:a,b,c']);
    expect(ids(narrativeStoryOutline(story, 'vide')), ['empty:']);
  });

  test('a story title match keeps every chapter with every step', () {
    expect(ids(narrativeStoryOutline(story, 'aventure')), [
      'early:a,b,c',
      'late:bye',
      'empty:',
    ]);
  });

  test('the summary counts chapters and steps and the link label tells none from some', () {
    expect(narrativeStorySummary(story), '3 chapitre(s) · 4 étape(s)');
    expect(narrativeStepLinkLabel(0), 'Aucun lien trouvé dans les données consultées');
    expect(narrativeStepLinkLabel(2), '2 interaction(s) liée(s)');
  });
}
