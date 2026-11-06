import 'package:avelune_studio/presentation/features/events/event_scene_panel.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_choice.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
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

  Future<void> pump(
    WidgetTester tester, {
    String? selectedId = 'bg-initialisation',
    List<String>? selected,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: SizedBox(
          height: 900,
          child: EventScenePanel(
            scenes: scenes,
            storylines: storylines,
            selectedId: selectedId,
            dirtyIds: const {},
            onSelect: (id) => selected?.add(id),
            onOpen: (_) {},
            onRemove: () {},
          ),
        ),
      ),
    ),
  );

  List<String> visibleLabels(WidgetTester tester) => tester
      .widgetList<StudioChoice>(find.byType(StudioChoice))
      .map((choice) => choice.label)
      .toList();

  testWidgets('linked scene comes first and identifiers stay out of the rows', (
    tester,
  ) async {
    await pump(tester);
    expect(visibleLabels(tester).first, 'Début de partie');
    expect(visibleLabels(tester), hasLength(5));
    for (final choice in tester.widgetList<StudioChoice>(
      find.byType(StudioChoice),
    )) {
      expect(choice.subtitle, isNot(contains('bg-')));
      expect(choice.subtitle, isNot(contains('hgss-')));
    }
    expect(
      find.text('Identifiant de la scène liée : bg-initialisation'),
      findsOneWidget,
    );
    expect(find.text('5 scènes'), findsOneWidget);
  });

  testWidgets('search matches name, description, tags and storyline context', (
    tester,
  ) async {
    final selected = <String>[];
    await pump(tester, selected: selected);
    final search = find.byKey(const ValueKey('event-scene-search'));

    await tester.enterText(search, 'MAMAN');
    await tester.pump();
    expect(visibleLabels(tester), ['Premier accueil de Maman']);

    await tester.enterText(search, 'rez-de-chaussée');
    await tester.pump();
    expect(visibleLabels(tester), ['Premier accueil de Maman']);

    await tester.enterText(search, 'professeur');
    await tester.pump();
    expect(visibleLabels(tester), ['Visite du laboratoire']);

    await tester.enterText(search, 'quête principale');
    await tester.pump();
    expect(visibleLabels(tester), [
      'Début de partie',
      'Sortie vers la route 29',
    ]);

    await tester.enterText(search, 'johto');
    await tester.pump();
    expect(visibleLabels(tester), ['Sortie vers la route 29']);
    expect(find.text('1 scène sur 5'), findsOneWidget);

    await tester.enterText(search, 'route-29');
    await tester.pump();
    expect(visibleLabels(tester), ['Sortie vers la route 29']);
    await tester.tap(find.text('Sortie vers la route 29'));
    expect(selected, ['route-29']);

    await tester.enterText(search, 'introuvable');
    await tester.pump();
    expect(visibleLabels(tester), isEmpty);
    expect(
      find.text('Aucune scène ne correspond à « introuvable ».'),
      findsOneWidget,
    );
  });

  testWidgets('an unresolved linked scene stays visible and preserved', (
    tester,
  ) async {
    await pump(tester, selectedId: 'scene-supprimee');
    expect(
      find.text('Scène absente : scene-supprimee. La référence est conservée.'),
      findsOneWidget,
    );
    expect(visibleLabels(tester).first, 'Le début d’une aventure');
    expect(
      tester.widget<StudioChoice>(find.byType(StudioChoice).first).selected,
      isFalse,
    );
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
