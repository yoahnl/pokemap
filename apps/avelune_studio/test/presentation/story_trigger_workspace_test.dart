import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'story_memory_harness.dart';

void main() {
  testWidgets('deleting the last trigger keeps its empty editor usable', (
    tester,
  ) async {
    await openMemoryStudio(tester, memoryIndex(), world: MapOnlyWorld.new);
    await openWholeGame(tester);
    await tester.tap(find.byKey(const ValueKey('behaviour-$guideTalk')));
    await settleMemory(tester);
    final scroll = find
        .descendant(
          of: find.byKey(const ValueKey('story-trigger-editor')),
          matching: find.byType(Scrollable),
        )
        .first;
    final remove = find.byKey(const ValueKey('map-story-behaviour-delete'));
    await tester.scrollUntilVisible(remove, 500, scrollable: scroll);
    await tester.tap(remove);
    await settleMemory(tester);
    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('map-story-behaviour-add')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('behaviour-$guideTalk')), findsNothing);
  });

  testWidgets('an unavailable scene stays visible in a compact trigger row', (
    tester,
  ) async {
    final record = NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: guideTalk,
        name: 'Scène perdue',
        source: NarrativeEventSourceRef.entityInteract('a', 'guide'),
        conditions: const [],
        sceneId: 'missing',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: 0,
        order: 0,
      ),
      enabled: true,
    );
    await openMemoryStudio(
      tester,
      memoryIndex(),
      project: memoryProject.copyWith(
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [record],
          legacyClaims: const [],
        ),
      ),
    );
    await openWholeGame(tester);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('behaviour-$guideTalk')),
        matching: find.textContaining('Référence indisponible'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('behaviours-filter-toRepair')));
    await settleMemory(tester);
    expect(find.byKey(const ValueKey('behaviour-$guideTalk')), findsOneWidget);
  });

  testWidgets('triggers use a compact list and a wide central editor', (
    tester,
  ) async {
    await openMemoryStudio(tester, memoryIndex(), world: MapOnlyWorld.new);
    tester.view.physicalSize = const Size(1280, 720);
    await openWholeGame(tester);
    expect(find.text('Déclencheurs'), findsWidgets);
    expect(find.text('Quand lancer les scènes'), findsWidgets);
    expect(
      tester
          .getSize(
            find.descendant(
              of: find.byKey(const ValueKey('behaviours-view')),
              matching: find.text('Déclencheurs'),
            ),
          )
          .height,
      lessThan(32),
    );
    expect(
      find.byKey(const ValueKey('story-trigger-workspace')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('story-inspector')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('behaviour-$guideTalk')));
    await settleMemory(tester);
    expect(find.byKey(const ValueKey('studio-story')), findsOneWidget);
    final editor = find.byKey(const ValueKey('story-trigger-editor'));
    expect(tester.getSize(editor).width, greaterThan(500));
    for (final section in ['when', 'if', 'then', 'repeat']) {
      expect(
        find.byKey(ValueKey('story-trigger-block-$section')),
        findsOneWidget,
      );
    }
    expect(
      tester
          .widget<StudioChoice>(
            find.byKey(const ValueKey('behaviour-$guideTalk')),
          )
          .selected,
      isTrue,
    );
    expect(find.byKey(const ValueKey('map-story-tabs')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('map filtering preserves selection and never activates a map', (
    tester,
  ) async {
    final index = memoryIndex();
    final maps = await openMemoryStudio(tester, index, world: MapOnlyWorld.new);
    await openWholeGame(tester);
    await tester.tap(find.byKey(const ValueKey('behaviour-$guideTalk')));
    await settleMemory(tester);
    final reads = maps.reads;
    final titleReads = index.titleRequests.length;
    final filter = tester.widget<StudioSelect>(
      find.byKey(const ValueKey('behaviours-map-filter')),
    );
    filter.onChanged!('b');
    await settleMemory(tester);
    expect(find.byKey(const ValueKey('behaviours-no-match')), findsOneWidget);
    expect(find.byKey(const ValueKey('story-trigger-editor')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('story-trigger-selection-filtered')),
      findsOneWidget,
    );
    expect(maps.reads, reads);
    expect(index.titleRequests, hasLength(titleReads));
    expect(maps.writes, 0);
    await tester.tap(find.text('Tout afficher'));
    await settleMemory(tester);
    expect(
      tester
          .widget<StudioChoice>(
            find.byKey(const ValueKey('behaviour-$guideTalk')),
          )
          .selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
