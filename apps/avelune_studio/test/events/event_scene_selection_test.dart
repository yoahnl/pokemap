import 'package:avelune_studio/features/events/application/event_scene_selection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  final scenes = [
    _scene('hgss-introduction', 'Le début d’une aventure'),
    _scene(
      'bg-mere',
      'Premier accueil de Maman',
      description: 'Maman accueille le joueur au rez-de-chaussée',
    ),
    _scene('bg-labo', 'Visite du laboratoire', tags: ['professeur']),
    _scene('bg-initialisation', 'Début de partie', storylineId: 'main'),
    _scene(
      'route-29',
      'Sortie vers la route 29',
      storylineId: 'main',
      chapterId: 'johto',
    ),
  ];
  final storylines = [
    StorylineAsset(
      id: 'main',
      type: StorylineType.main,
      title: 'Quête principale',
      chapters: [
        StorylineChapter(id: 'johto', title: 'Arrivée à Johto', order: 0),
      ],
    ),
  ];

  test('linked scene comes first while other scenes retain source order and identity', () {
    final beforeScenes = scenes.map((scene) => scene.toJson()).toList();
    final beforeStories = storylines.map((story) => story.toJson()).toList();
    final choices = eventSceneChoices(
      scenes: scenes,
      storylines: storylines,
      selectedId: 'bg-initialisation',
    );
    expect(choices.selectedId, 'bg-initialisation');
    expect(choices.linked, same(scenes[3]));
    expect(choices.visible.map((scene) => scene.id), [
      'bg-initialisation',
      'hgss-introduction',
      'bg-mere',
      'bg-labo',
      'route-29',
    ]);
    expect(choices.visible[1], same(scenes.first));
    expect(choices.contexts['bg-initialisation'], 'Quête principale');
    expect(choices.contexts['route-29'], 'Quête principale · Arrivée à Johto');
    expect(
      choices.contexts.values.any(
        (context) => context.contains('bg-') || context.contains('hgss-'),
      ),
      isFalse,
    );
    expect(scenes.map((scene) => scene.toJson()).toList(), beforeScenes);
    expect(storylines.map((story) => story.toJson()).toList(), beforeStories);
  });

  for (final entry in <String, List<String>>{
    'MAMAN': ['bg-mere'],
    'rez-de-chaussée': ['bg-mere'],
    'professeur': ['bg-labo'],
    'quête principale': ['bg-initialisation', 'route-29'],
    'arrivée à johto': ['route-29'],
    'route-29': ['route-29'],
    '  ROUTE-29  ': ['route-29'],
  }.entries) {
    test('search resolves native scene metadata for ${entry.key}', () {
      final choices = eventSceneChoices(
        scenes: scenes,
        storylines: storylines,
        selectedId: 'bg-initialisation',
        query: entry.key,
      );
      expect(choices.visible.map((scene) => scene.id), entry.value);
      expect(choices.selectedId, 'bg-initialisation');
      expect(choices.linked, same(scenes[3]));
    });
  }

  test(
    'a linked scene remains first only when it matches the current query',
    () {
      final choices = eventSceneChoices(
        scenes: scenes,
        storylines: storylines,
        selectedId: 'route-29',
        query: 'quête principale',
      );
      expect(choices.visible.map((scene) => scene.id), [
        'route-29',
        'bg-initialisation',
      ]);
      final filtered = eventSceneChoices(
        scenes: scenes,
        storylines: storylines,
        selectedId: 'route-29',
        query: 'MAMAN',
      );
      expect(filtered.visible.map((scene) => scene.id), ['bg-mere']);
      expect(filtered.selectedId, 'route-29');
      expect(filtered.linked, same(scenes.last));
    },
  );

  test(
    'an unresolved linked reference stays exact without choosing another scene',
    () {
      final choices = eventSceneChoices(
        scenes: scenes,
        storylines: storylines,
        selectedId: 'scene-supprimee',
      );
      expect(choices.selectedId, 'scene-supprimee');
      expect(choices.linked, isNull);
      expect(choices.visible, scenes);
      expect(choices.visible.first, same(scenes.first));
      final filtered = eventSceneChoices(
        scenes: scenes,
        storylines: storylines,
        selectedId: 'scene-supprimee',
        query: 'professeur',
      );
      expect(filtered.selectedId, 'scene-supprimee');
      expect(filtered.linked, isNull);
      expect(filtered.visible.map((scene) => scene.id), ['bg-labo']);
    },
  );

  test('missing story and chapter references preserve available description and tags', () {
    final detached = [
      _scene(
        'missing-story',
        'Détachée',
        storylineId: 'absent',
        chapterId: 'johto',
        description: '  Description conservée  ',
        tags: ['indice'],
      ),
      _scene(
        'missing-chapter',
        'Chapitre retiré',
        storylineId: 'main',
        chapterId: 'absent',
        description: '   ',
      ),
    ];
    final choices = eventSceneChoices(scenes: detached, storylines: storylines);
    expect(choices.contexts, {
      'missing-story': 'Description conservée · indice',
      'missing-chapter': 'Quête principale',
    });
    expect(
      eventSceneChoices(
        scenes: detached,
        storylines: storylines,
        query: 'indice',
      ).visible,
      [detached.first],
    );
    expect(
      eventSceneChoices(
        scenes: detached,
        storylines: storylines,
        query: 'johto',
      ).visible,
      isEmpty,
    );
    expect(choices.selectedId, isNull);
    expect(choices.linked, isNull);
  });

  test('empty catalogues and unmatched queries never fabricate a replacement reference', () {
    final empty = eventSceneChoices(
      scenes: [],
      storylines: storylines,
      selectedId: 'missing',
    );
    expect(empty.visible, isEmpty);
    expect(empty.contexts, isEmpty);
    expect(empty.selectedId, 'missing');
    expect(empty.linked, isNull);
    final unmatched = eventSceneChoices(
      scenes: scenes,
      storylines: storylines,
      selectedId: 'bg-initialisation',
      query: 'introuvable',
    );
    expect(unmatched.visible, isEmpty);
    expect(unmatched.selectedId, 'bg-initialisation');
    expect(unmatched.linked, same(scenes[3]));
    final blank = eventSceneChoices(
      scenes: scenes,
      storylines: storylines,
      query: '   ',
    );
    expect(blank.visible, scenes);
    expect(blank.selectedId, isNull);
    expect(blank.linked, isNull);
  });
}

SceneAsset _scene(
  String id,
  String name, {
  String? description,
  List<String> tags = const [],
  String? storylineId,
  String? chapterId,
}) => SceneAsset(
  id: id,
  name: name,
  description: description,
  tags: tags,
  storylineId: storylineId,
  chapterId: chapterId,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'first',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);
