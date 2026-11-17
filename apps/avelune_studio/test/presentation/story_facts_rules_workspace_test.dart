import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'story_interactions_support.dart';
import 'story_memory_harness.dart';

void main() {
  testWidgets(
    'changing the interface language preserves the fact and its identified usages',
    (tester) async {
      final index = memoryIndex();
      final locale = ValueNotifier(const Locale('fr'));
      addTearDown(locale.dispose);
      await openMemoryStudio(tester, index, locale: locale);
      await openHistoire(tester);
      await tester.tap(find.text('Rencontre'));
      await settleMemory(tester);
      final requests = index.userRequests.length;
      expect(find.text('4 usages identifiés'), findsNWidgets(2));
      locale.value = const Locale('en');
      await settleMemory(tester);
      expect(find.text('4 identified usages'), findsNWidgets(2));
      expect(
        find.byKey(const ValueKey('memory-fact-detail-met')),
        findsOneWidget,
      );
      expect(find.text('Where is this used?'), findsOneWidget);
      locale.value = const Locale('fr');
      await settleMemory(tester);
      expect(find.text('4 usages identifiés'), findsNWidgets(2));
      expect(index.userRequests, hasLength(requests));
    },
  );

  testWidgets('a fact usage opens its exact second trigger in Histoire', (
    tester,
  ) async {
    final index = memoryIndex();
    index.users['met'] = NarrativeUsages(
      owners: const [
        NarrativeOwner(
          kind: NarrativeOwnerKind.event,
          id: motherTalk,
          role: NarrativeFactRole.read,
        ),
      ],
      notCovered: const ['dialogueDefinitions'],
    );
    index.titlesByKind[NarrativeTitleKind.events] = const [
      NarrativeTitle(id: guideTalk, title: 'Premier cas'),
      NarrativeTitle(id: motherTalk, title: 'Deuxième cas'),
    ];
    await openMemoryStudio(
      tester,
      index,
      world: MapOnlyWorld.new,
      project: memoryProject.copyWith(
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            interactionRecord(guideTalk, 'a', 'guide', 'Premier cas'),
            interactionRecord(motherTalk, 'a', 'guide', 'Deuxième cas'),
          ],
          legacyClaims: const [],
        ),
      ),
    );
    await openHistoire(tester);
    await tester.tap(find.text('Rencontre'));
    await settleMemory(tester);
    expect(find.text('Déclencheur'), findsOneWidget);
    final usage = find.byKey(const ValueKey('memory-open-event-$motherTalk'));
    await tester.ensureVisible(usage);
    await settleMemory(tester);
    await tester.tap(usage);
    await settleMemory(tester);
    expect(find.byKey(const ValueKey('studio-story')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('map-story-behaviour-name-$motherTalk')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('map-story-behaviour-name-$guideTalk')),
      findsNothing,
    );
    expect(interactionMaps(tester).active!.current.id, 'a');
  });

  testWidgets(
    'a saved fact explains initial and simulation values and keeps deletion disabled',
    (tester) async {
      await openMemoryStudio(tester, memoryIndex());
      await openHistoire(tester);
      await tester.tap(find.text('Rencontre'));
      await settleMemory(tester);
      expect(find.textContaining('simulation'), findsOneWidget);
      expect(find.textContaining('sauvegardes Player'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('memory-fact-delete')),
        300,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('memory-fact-detail-met')),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          ),
        ),
      );
      await settleMemory(tester);
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('memory-fact-delete')),
            )
            .onPressed,
        isNull,
      );
      expect(
        find.byKey(const ValueKey('memory-fact-delete-refused')),
        findsOneWidget,
      );
    },
  );
}
