import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/scenes/application/scene_catalog_memberships.dart';
import 'package:avelune_studio/features/scenes/application/scene_catalog_rows.dart';
import 'package:avelune_studio/features/story_draft/application/story_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

List<StorylineAsset> membershipStories() => [
  StorylineAsset(
    id: 'main',
    type: StorylineType.main,
    title: 'Départ',
    chapters: [
      StorylineChapter(
        id: 'one',
        title: 'Village',
        order: 0,
        directSceneLinkIds: ['intro_link', 'missing_link', 'another_missing'],
        steps: [
          StorylineStep(
            id: 'meet',
            title: 'Rencontre',
            order: 0,
            sceneLinkIds: ['shared', 'intro_link'],
          ),
        ],
      ),
      StorylineChapter(
        id: 'two',
        title: 'Route',
        order: 1,
        steps: [
          StorylineStep(
            id: 'leave',
            title: 'Voyage',
            order: 0,
            sceneLinkIds: ['shared', 'missing_scene'],
          ),
        ],
      ),
    ],
    sceneLinks: [
      StorylineSceneLink(
        id: 'intro_link',
        chapterId: 'one',
        label: 'Introduction',
        state: StorylineSceneLinkState.linkedScenario,
        role: StorylineSceneLinkRole.primary,
        sceneRef: StorylineSceneRef(
          kind: StorylineSceneRefKind.scenario,
          targetId: 'direct',
        ),
        order: 0,
      ),
      StorylineSceneLink(
        id: 'broken',
        chapterId: 'one',
        label: 'Retour à vérifier',
        state: StorylineSceneLinkState.brokenLink,
        role: StorylineSceneLinkRole.optional,
        sceneRef: StorylineSceneRef(
          kind: StorylineSceneRefKind.scenario,
          targetId: 'shared',
        ),
        order: 1,
      ),
    ],
  ),
  StorylineAsset(
    id: 'side',
    type: StorylineType.sideQuest,
    title: 'La lettre',
    chapters: [
      StorylineChapter(
        id: 'one',
        title: 'Livraison',
        order: 0,
        steps: [
          StorylineStep(
            id: 'deliver',
            title: 'Remettre la lettre',
            order: 0,
            sceneLinkIds: ['shared'],
          ),
        ],
      ),
    ],
  ),
];

List<SceneCatalogRow> membershipRows() => sceneCatalogRows(
  const [
    NarrativeTitle(id: 'shared', title: 'Rencontre'),
    NarrativeTitle(id: 'direct', title: 'Introduction'),
    NarrativeTitle(id: 'outside', title: 'Promenade'),
  ],
  StoryDraft(),
  SceneCatalogMemberships([
    for (final story in membershipStories())
      StorylineAsset.fromJson(story.toJson()),
  ]),
);

void main() {
  test('step scene ids and structured chapter links retain their distinct contracts', () {
    final rows = membershipRows();
    final direct = rows.singleWhere((row) => row.id == 'direct');
    expect(direct.memberships, hasLength(1));
    expect(direct.memberships.single.link!.id, 'intro_link');
    final collision = rows.singleWhere((row) => row.id == 'intro_link');
    expect(collision.missing, isTrue);
    expect(collision.memberships.single.step!.id, 'meet');
    expect(rows.where((row) => row.sceneId == 'shared'), hasLength(1));
    expect(
      rows.singleWhere((row) => row.id == 'shared').memberships,
      hasLength(4),
    );
  });

  test(
    'missing scenes and every unresolved direct chapter reference stay visible',
    () {
      final rows = membershipRows();
      expect(
        rows.singleWhere((row) => row.id == 'missing_scene').broken,
        isTrue,
      );
      expect(rows.singleWhere((row) => row.id == 'shared').broken, isTrue);
      expect(rows.where((row) => row.sceneId == null), hasLength(2));
      expect(filterSceneCatalog(rows, story: 'outside').map((row) => row.id), [
        'outside',
      ]);
    },
  );

  test('combined filters scope chapter identities to their story and deduplicate scenes', () {
    final rows = membershipRows();
    expect(
      filterSceneCatalog(
        rows,
        story: 'side',
        chapter: sceneCatalogChapterKey('side', 'one'),
        query: 'RENCONTRE',
      ).map((row) => row.id),
      ['shared'],
    );
    expect(filterSceneCatalog(rows, chapter: 'none').map((row) => row.id), [
      'outside',
    ]);
    expect(filterSceneCatalog(rows, story: 'main', chapter: 'none'), isEmpty);
    expect(
      filterSceneCatalog(
        rows,
        story: 'story:side',
        chapter: sceneCatalogChapterKey('main', 'one'),
      ),
      isEmpty,
    );
    expect(
      filterSceneCatalog(rows, story: 'outside', query: 'introuvable'),
      isEmpty,
    );
  });
}
