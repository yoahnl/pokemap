import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_element_catalog.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/characters/character_inspector.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets(
    'an unresolved presence reference is kept, flagged and survives an effect change',
    (tester) async {
      final document = _document([
        _npc(
          'guard',
          rule: const MapEntityNpcVisibilityRule(
            mode: MapEntityNpcVisibilityMode.visibleWhen,
            predicate: MapEntityRuntimePredicate(
              kind: MapEntityRuntimePredicateKind.storyFlagSet,
              refId: 'ghost_flag',
            ),
          ),
          variants: [
            MapEntityConditionalDialogue(
              when: const MapEntityRuntimePredicate(
                kind: MapEntityRuntimePredicateKind.stepCompleted,
                refId: 'got_dex',
              ),
              dialogue: DialogueRef(dialogueId: 'lost_dialogue'),
            ),
          ],
        ),
      ]);
      await _pump(tester, document, 'guard');

      expect(_select(tester, 'npc-guard-presence-mode').value, 'story');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('npc-guard-presence-missing')),
          matching: find.textContaining('ghost_flag'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('npc-guard-dialogue-variant-0')),
          matching: find.textContaining('Recevoir le Pokédex'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('npc-guard-dialogue-variant-0')),
          matching: find.textContaining('lost_dialogue'),
        ),
        findsOneWidget,
      );

      await _choose(tester, 'npc-guard-presence-effect', 'hiddenWhen');
      final rule = _entity(document, 'guard').npc!.visibilityRule!;
      expect(rule.mode, MapEntityNpcVisibilityMode.hiddenWhen);
      expect(rule.predicate!.kind, MapEntityRuntimePredicateKind.storyFlagSet);
      expect(rule.predicate!.refId, 'ghost_flag');
      expect(
        _entity(
          document,
          'guard',
        ).npc!.conditionalDialogues.single.dialogue.dialogueId,
        'lost_dialogue',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a story presence is composed with pickers, explained and tested on both branches',
    (tester) async {
      final document = _document([_npc('traveller'), _npc('chief')]);
      await _pump(tester, document, 'traveller');
      final untouched = document.current;

      await _choose(tester, 'npc-traveller-presence-mode', 'story');
      expect(document.current, same(untouched));
      expect(
        find.byKey(const ValueKey('npc-traveller-presence-pending')),
        findsOneWidget,
      );

      await _choose(
        tester,
        'npc-traveller-presence-condition',
        'stepCompleted',
      );
      expect(document.current, same(untouched));
      await tester.enterText(
        find.byKey(const ValueKey('npc-traveller-presence-search')),
        'pokédex',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('npc-traveller-presence-ref-gym_one')),
        findsNothing,
      );
      await _tap(tester, 'npc-traveller-presence-ref-got_dex');

      final rule = _entity(document, 'traveller').npc!.visibilityRule!;
      expect(rule.mode, MapEntityNpcVisibilityMode.visibleWhen);
      expect(rule.predicate!.kind, MapEntityRuntimePredicateKind.stepCompleted);
      expect(rule.predicate!.refId, 'got_dex');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('npc-traveller-presence-result')),
          matchRoot: true,
          matching: find.textContaining('Recevoir le Pokédex'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('npc-traveller-presence-origin')),
          matchRoot: true,
          matching: find.textContaining('Guide'),
        ),
        findsOneWidget,
      );

      await _tap(tester, 'npc-traveller-presence-test-unmet');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('npc-traveller-presence-test-outcome')),
          matchRoot: true,
          matching: find.textContaining('absent'),
        ),
        findsOneWidget,
      );
      await _tap(tester, 'npc-traveller-presence-test-met');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('npc-traveller-presence-test-outcome')),
          matchRoot: true,
          matching: find.textContaining('présent'),
        ),
        findsOneWidget,
      );

      await _choose(tester, 'npc-traveller-presence-condition', 'badgeOwned');
      expect(
        _entity(document, 'traveller').npc!.visibilityRule!.predicate!.refId,
        'got_dex',
      );
      await _tap(tester, 'npc-traveller-presence-ref-zephyr');
      expect(
        _entity(document, 'traveller').npc!.visibilityRule!.predicate,
        const MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.badgeOwned,
          refId: 'zephyr',
        ),
      );

      await _choose(
        tester,
        'npc-traveller-presence-condition',
        'badgeNotOwned',
      );
      expect(
        _entity(document, 'traveller').npc!.visibilityRule!.predicate,
        const MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.badgeNotOwned,
          refId: 'zephyr',
        ),
      );

      await _choose(tester, 'npc-traveller-presence-condition', 'storyFlagSet');
      await _tap(tester, 'npc-traveller-presence-ref-rival_seen');
      expect(
        _entity(document, 'traveller').npc!.visibilityRule!.predicate,
        const MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.storyFlagSet,
          refId: 'rival_flag',
        ),
      );

      expect(
        _entity(document, 'chief'),
        _entity(_document([_npc('chief')]), 'chief'),
      );
      expect(_entity(document, 'traveller').npc!.characterId, 'guide');
      expect(_entity(document, 'traveller').npc!.conditionalDialogues, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('chapter and cutscene rules stay preserved and described', (
    tester,
  ) async {
    final document = _document([
      _npc(
        'warden',
        rule: const MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.hiddenWhen,
          predicate: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.chapterCompleted,
            refId: 'chapter_two',
          ),
        ),
      ),
    ]);
    await _pump(tester, document, 'warden');
    expect(_select(tester, 'npc-warden-presence-mode').value, 'advanced');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('npc-warden-presence-advanced')),
        matchRoot: true,
        matching: find.textContaining('chapter_two'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test('a conditional presence stays findable in map content', () {
    final map = _document([
      _npc(
        'guard',
        rule: const MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.visibleWhen,
          predicate: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.badgeOwned,
            refId: 'zephyr',
          ),
        ),
        variants: [
          MapEntityConditionalDialogue(
            when: const MapEntityRuntimePredicate(
              kind: MapEntityRuntimePredicateKind.badgeOwned,
              refId: 'zephyr',
            ),
            dialogue: DialogueRef(dialogueId: 'hello'),
          ),
        ],
      ),
      _npc('chief'),
    ]).current;
    final catalog = MapElementCatalog(map, _project);
    final guard = catalog.entries.singleWhere((entry) => entry.id == 'guard');
    final chief = catalog.entries.singleWhere((entry) => entry.id == 'chief');
    expect(guard.detail, contains('Présence conditionnelle'));
    expect(guard.detail, contains('1 variante de dialogue'));
    expect(chief.detail, isNot(contains('Présence conditionnelle')));
  });
}

final _project = workspaceProject.copyWith(
  characters: const [
    ProjectCharacterEntry(id: 'guide', name: 'Guide', tilesetId: 'atlas'),
  ],
  dialogues: const [
    ProjectDialogueEntry(
      id: 'hello',
      name: 'Bonjour',
      relativePath: 'dialogues/hello.yarn',
    ),
  ],
  storylines: [
    StorylineAsset(
      id: 'main',
      type: StorylineType.main,
      title: 'Aventure',
      chapters: [
        StorylineChapter(
          id: 'chapter_one',
          title: 'Départ',
          order: 0,
          steps: [
            StorylineStep(
              id: 'got_dex',
              title: 'Recevoir le Pokédex',
              order: 0,
            ),
            StorylineStep(id: 'gym_one', title: 'Premier badge', order: 1),
          ],
        ),
      ],
    ),
  ],
  facts: [
    NarrativeFactDefinition(
      id: 'rival_seen',
      label: 'Rival rencontré',
      legacyFlagName: 'rival_flag',
    ),
  ],
  badges: const [BadgeDefinition(id: 'zephyr', label: 'Badge Zéphyr')],
);

MapEntity _npc(
  String id, {
  MapEntityNpcVisibilityRule? rule,
  List<MapEntityConditionalDialogue> variants = const [],
}) => MapEntity(
  id: id,
  name: id,
  kind: MapEntityKind.npc,
  pos: const GridPos(x: 3, y: 4),
  npc: MapEntityNpcData(
    characterId: 'guide',
    visibilityRule: rule,
    conditionalDialogues: variants,
  ),
);

EditableMapDocument _document(List<MapEntity> entities) => EditableMapDocument(
  MapWorkspaceDocument(
    map: workspaceMap('a').copyWith(name: 'Bourg', entities: entities),
    revision: 'r0',
    mapId: 'a',
  ),
);

MapEntity _entity(EditableMapDocument document, String id) =>
    document.current.entities.singleWhere((entity) => entity.id == id);

Future<void> _pump(
  WidgetTester tester,
  EditableMapDocument document,
  String id,
) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: SizedBox(
          width: 600,
          child: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: CharacterInspector(
                document: document,
                project: _project,
                entity: _entity(document, id),
                visuals: WorkspaceTestVisuals(),
                onChanged: () => setState(() {}),
                onSelect: (_) {},
                onEditInteraction: (_) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

StudioSelect _select(WidgetTester tester, String key) =>
    tester.widget<StudioSelect>(find.byKey(ValueKey(key)));

Future<void> _choose(WidgetTester tester, String key, String value) async {
  final finder = find.byKey(ValueKey(key));
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
  await tester.pumpAndSettle();
  final widget = _select(tester, key);
  expect(widget.options, contains(value));
  widget.onChanged!(value);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
