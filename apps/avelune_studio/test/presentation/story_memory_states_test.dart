import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../game_memory/game_memory_fakes.dart';
import 'story_memory_harness.dart';

void main() {
  testWidgets('a missing index preparation is stated and can be retried', (
    tester,
  ) async {
    final index = memoryIndex()
      ..titleFailure = const NarrativeIndexPreparationRequired(
        'narrativeTitles',
      );
    await openMemoryStudio(tester, index);
    await openHistoire(tester);

    expect(
      find.byKey(const ValueKey('memory-preparation-required')),
      findsOneWidget,
    );
    expect(find.text('L’index de l’histoire n’est pas prêt'), findsOneWidget);

    index.titleFailure = null;
    await tester.tap(find.text('Réessayer'));
    await settleMemory(tester);
    expect(find.text('Rencontre'), findsOneWidget);
  });

  testWidgets('a read failure states its cause', (tester) async {
    final index = memoryIndex()..titleFailure = StateError('disque absent');
    await openMemoryStudio(tester, index);
    await openHistoire(tester);

    expect(find.byKey(const ValueKey('memory-failed')), findsOneWidget);
    expect(find.textContaining('disque absent'), findsOneWidget);
  });

  testWidgets('a project that is not a working copy is read only', (
    tester,
  ) async {
    await openMemoryStudio(
      tester,
      memoryIndex(),
      session: ProjectSession(
        sessionId: memorySession.sessionId,
        name: memorySession.name,
        directoryPath: memorySession.directoryPath,
        storage: ProjectSessionStorage.portableCatalog,
      ),
    );
    await openHistoire(tester);

    expect(find.text('Rencontre'), findsOneWidget);
    expect(
      tester
          .widget<StudioButton>(find.byKey(const ValueKey('memory-new-fact')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('an empty memory proposes to create a state', (tester) async {
    final index = FakeNarrativeIndex()
      ..titlesByKind[NarrativeTitleKind.facts] = const [];
    await openMemoryStudio(tester, index);
    await openHistoire(tester);

    expect(find.byKey(const ValueKey('memory-facts-empty')), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('memory-facts-empty')),
        matching: find.text('Nouvel état'),
      ),
    );
    await settleMemory(tester);
    expect(find.byKey(const ValueKey('memory-new-fact-name')), findsOneWidget);
  });

  testWidgets('filters read the usage index and state a failure', (
    tester,
  ) async {
    final index = memoryIndex();
    await openMemoryStudio(tester, index);
    await openHistoire(tester);

    await tester.tap(find.byKey(const ValueKey('memory-filter-neverWritten')));
    await settleMemory(tester);
    expect(find.text('Rencontre'), findsNothing);
    expect(find.text('Pièces'), findsOneWidget);
    expect(index.userRequests.single.toSet(), {'met', 'coins'});

    await tester.tap(find.byKey(const ValueKey('memory-filter-neverRead')));
    await settleMemory(tester);
    expect(find.text('Pièces'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('memory-fact-search')),
        matching: find.byType(TextField),
      ),
      'zzz',
    );
    await settleMemory(tester);
    expect(find.byKey(const ValueKey('memory-facts-empty')), findsOneWidget);
    expect(find.text('Aucun état ne correspond'), findsOneWidget);
  });

  testWidgets('world rules read as sentences and edit into the draft', (
    tester,
  ) async {
    final index = memoryIndex();
    await openMemoryStudio(tester, index);
    await openHistoire(tester);

    await tester.tap(find.text('Règles du monde'));
    await settleMemory(tester);
    final row = tester.widget<StudioChoice>(
      find.byKey(const ValueKey('memory-rule-world_rule_door')),
    );
    expect(
      row.subtitle,
      'Tant que « Rencontre » est vrai, alors « Guide » (Clairière) '
      'disparaît.',
    );

    await tester.tap(find.text('Porte du bourg'));
    await settleMemory(tester);
    await tester.tap(find.byKey(const ValueKey('memory-rule-effect')));
    await settleMemory(tester);
    await tester.tap(find.text('apparaît').last);
    await settleMemory(tester);

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('memory-rule-sentence')))
          .data,
      endsWith('« Guide » (Clairière) apparaît.'),
    );
    expect(
      tester
          .widget<StudioChoice>(
            find.byKey(const ValueKey('memory-rule-world_rule_door')),
          )
          .trailing,
      isA<StudioBadge>(),
    );
  });

  testWidgets('a character shows the rules and scenes that cite it', (
    tester,
  ) async {
    final index = memoryIndex();
    index.owners['a/guide'] = NarrativeUsages(
      owners: const [
        NarrativeOwner(
          kind: NarrativeOwnerKind.worldRule,
          id: 'world_rule_door',
        ),
        NarrativeOwner(kind: NarrativeOwnerKind.scene, id: 'gate'),
        NarrativeOwner(kind: NarrativeOwnerKind.event, id: guideTalk),
      ],
      notCovered: const ['maps'],
    );
    await openMemoryStudio(tester, index);
    await tester.tap(find.byKey(const ValueKey('map-space-story')));
    await settleMemory(tester);
    await tester.tap(find.text('Guide').first);
    await settleMemory(tester);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('map-story-tabs')),
        matching: find.text('Propriétés'),
      ),
    );
    await settleMemory(tester);

    final presence = find.byKey(const ValueKey('map-story-presence'));
    await tester.ensureVisible(presence);
    expect(find.text('Présence'), findsOneWidget);
    expect(
      find.descendant(of: presence, matching: find.text('Porte du bourg')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: presence,
        matching: find.text('Ouverture de la porte'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: presence, matching: find.text('Parler au guide')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: presence,
        matching: find.textContaining('Non couvert par l’index'),
      ),
      findsOneWidget,
    );
    expect(
      index.titleRequests.toSet(),
      containsAll({NarrativeTitleKind.worldRules, NarrativeTitleKind.scenes}),
    );
    expect(index.titleRequests, isNot(contains(NarrativeTitleKind.facts)));
    expect(index.ruleRequests, 0);
  });

  testWidgets('a new rule picks a character on a map loaded on demand', (
    tester,
  ) async {
    final index = memoryIndex();
    late MapOnlyWorld world;
    await openMemoryStudio(
      tester,
      index,
      world: (maps) => world = MapOnlyWorld(maps),
    );
    await openHistoire(tester);
    await tester.tap(find.text('Règles du monde'));
    await settleMemory(tester);
    expect(world.loaded, isEmpty);

    await tester.tap(find.byKey(const ValueKey('memory-new-rule')));
    await settleMemory(tester);
    await tester.enterText(
      find.byKey(const ValueKey('memory-new-rule-name')),
      'Le guide part',
    );
    Future<void> choose(String key, String label) async {
      await tester.tap(find.byKey(ValueKey(key)));
      await settleMemory(tester);
      await tester.tap(find.text(label).last);
      await settleMemory(tester);
    }

    await choose('memory-rule-fact', 'Pièces');
    await choose('memory-rule-operator', 'vaut au moins');
    await choose('memory-new-rule-map', 'Clairière');
    expect(world.loaded, ['a']);
    await choose('memory-new-rule-character', 'Guide');
    await tester.tap(find.byKey(const ValueKey('memory-new-rule-create')));
    await settleMemory(tester);

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('memory-rule-sentence')))
          .data,
      'Tant que « Pièces » vaut au moins 0, alors « Guide » (Clairière) '
      'apparaît.',
    );
    expect(
      tester
          .widget<StudioChoice>(
            find.byKey(const ValueKey('memory-rule-world_rule_le_guide_part')),
          )
          .trailing,
      isA<StudioBadge>(),
    );
  });
}
