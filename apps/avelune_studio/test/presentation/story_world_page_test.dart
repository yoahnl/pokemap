import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../game_behaviours/game_behaviour_fakes.dart';
import '../game_memory/game_memory_fakes.dart';
import '../support/map_workspace_fixture.dart';
import 'story_memory_harness.dart';

StudioChoice _row(WidgetTester tester, String id) =>
    tester.widget<StudioChoice>(find.byKey(ValueKey('behaviour-$id')));

void main() {
  testWidgets('Tout le jeu opens first and lists behaviours by map', (
    tester,
  ) async {
    final index = memoryIndex();
    await openMemoryStudio(tester, index);
    await openWholeGame(tester);

    expect(find.byKey(const ValueKey('behaviours-view')), findsOneWidget);
    expect(find.text('Clairière · 1'), findsOneWidget);
    final row = _row(tester, guideTalk);
    expect(row.label, 'Parler au guide');
    expect(
      row.subtitle,
      'Clairière · Guide\n'
      'Quand : Le joueur interagit · Si : Toujours · '
      'Alors : Aucune scène choisie · Après : À définir',
    );
    expect(index.factRequests, isEmpty);
    expect(index.userRequests, isEmpty);

    await tester.tap(find.text('Parler au guide'));
    await settleMemory(tester);
    expect(find.byKey(const ValueKey('studio-story')), findsNothing);
    expect(
      find.byKey(const ValueKey('map-story-inspector-entity:guide')),
      findsOneWidget,
    );
  });

  testWidgets('a behaviour deleted elsewhere is refused cleanly', (
    tester,
  ) async {
    final index = memoryIndex()
      ..titlesByKind[NarrativeTitleKind.events] = const [];
    await openMemoryStudio(tester, index);
    await openWholeGame(tester);

    expect(
      (_row(tester, guideTalk).trailing! as StudioBadge).label,
      'Supprimé ailleurs',
    );
    await tester.tap(find.text('Parler au guide'));
    await settleMemory(tester);

    expect(find.byKey(const ValueKey('studio-story')), findsOneWidget);
    expect(find.byKey(const ValueKey('behaviours-refused')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('map-story-inspector-entity:guide')),
      findsNothing,
    );
  });

  testWidgets('an empty project proposes to go to the map', (tester) async {
    final index = FakeNarrativeIndex();
    await openMemoryStudio(tester, index, project: workspaceProject);
    await openWholeGame(tester);

    expect(find.byKey(const ValueKey('behaviours-empty')), findsOneWidget);
    await tester.tap(find.text('Aller à la carte'));
    await settleMemory(tester);
    expect(find.byKey(const ValueKey('studio-story')), findsNothing);
    expect(find.byKey(const ValueKey('map-story-search')), findsOneWidget);
  });

  testWidgets('many behaviours build visible rows only, filter and group', (
    tester,
  ) async {
    final records = [
      for (var i = 1; i <= 300; i++)
        behaviour(
          i,
          'Sans carte $i',
          conditions: [NarrativeEventCondition.fact('met', true)],
        ),
    ];
    final index = memoryIndex()
      ..titlesByKind[NarrativeTitleKind.events] = [
        for (final record in records)
          NarrativeTitle(
            id: record.id,
            title: record.definitionOrNull?.name ?? '',
          ),
      ];
    index.users['met'] = NarrativeUsages(
      owners: [
        for (final record in records.take(3))
          NarrativeOwner(
            kind: NarrativeOwnerKind.event,
            id: record.id,
            role: NarrativeFactRole.read,
          ),
      ],
      notCovered: const [],
    );
    await openMemoryStudio(
      tester,
      index,
      project: workspaceProject.copyWith(
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: records,
          legacyClaims: const [],
        ),
      ),
    );
    await openWholeGame(tester);

    final built = tester
        .widgetList(
          find.byWidgetPredicate(
            (widget) =>
                widget is StudioChoice &&
                '${widget.key}'.startsWith("[<'behaviour-"),
            skipOffstage: false,
          ),
        )
        .length;
    expect(built, inInclusiveRange(3, 40));
    expect(find.text('Sans carte · 300'), findsOneWidget);
    expect(
      _row(tester, behaviourId(1)).subtitle,
      contains('Si : « Rencontre » est vrai'),
    );

    await tester.tap(find.byKey(const ValueKey('behaviours-filter-disabled')));
    await settleMemory(tester);
    expect(find.byKey(const ValueKey('behaviours-no-match')), findsOneWidget);
    await tester.tap(find.text('Tout afficher'));
    await settleMemory(tester);

    await tester.tap(find.text('Par état'));
    await settleMemory(tester);
    expect(index.userRequests, hasLength(1));
    expect(find.text('Rencontre · 3'), findsOneWidget);
    expect(find.text('Sans état · 297'), findsOneWidget);
  });
}
