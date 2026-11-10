import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/characters/application/character_presence_references.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_element_catalog.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test('unresolved presence reference is described and retained across an effect change', () {
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
    final references = CharacterPresenceReferences(_project);
    final original = _entity(document, 'guard').npc!;
    expect(isCharacterStoryPresence(original.visibilityRule), isTrue);
    final description = references.describe(
      original.visibilityRule!.predicate!,
    );
    expect(description.missing, isTrue);
    expect(description.phrase, contains('ghost_flag'));
    expect(
      references.describe(original.conditionalDialogues.single.when).phrase,
      contains('Recevoir le Pokédex'),
    );
    CharacterEditingCommands(document, _project).setVisibilityRule(
      'guard',
      original.visibilityRule!.copyWith(
        mode: MapEntityNpcVisibilityMode.hiddenWhen,
      ),
    );
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
  });

  test(
    'presence references preserve identity and independent NPC bindings',
    () {
      final document = _document([_npc('traveller'), _npc('chief')]);
      final untouched = document.current;
      final references = CharacterPresenceReferences(_project);
      final step = references
          .of(CharacterPresenceSubject.step)
          .singleWhere((entry) => entry.refId == 'got_dex');
      expect(step.label, 'Recevoir le Pokédex');
      expect(step.detail, 'Aventure · Départ');
      expect(document.current, same(untouched));
      final commands = CharacterEditingCommands(document, _project);
      commands.setVisibilityRule(
        'traveller',
        MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.visibleWhen,
          predicate: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.stepCompleted,
            refId: step.refId,
          ),
        ),
      );
      final rule = _entity(document, 'traveller').npc!.visibilityRule!;
      expect(rule.mode, MapEntityNpcVisibilityMode.visibleWhen);
      expect(rule.predicate!.kind, MapEntityRuntimePredicateKind.stepCompleted);
      expect(rule.predicate!.refId, 'got_dex');
      final description = references.describe(rule.predicate!);
      expect(description.phrase, contains('Recevoir le Pokédex'));
      expect(
        characterPresenceSentence(rule.mode, description.phrase),
        contains('présent seulement quand'),
      );
      commands.setVisibilityRule(
        'traveller',
        const MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.visibleWhen,
          predicate: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.badgeOwned,
            refId: 'zephyr',
          ),
        ),
      );
      expect(
        _entity(document, 'traveller').npc!.visibilityRule!.predicate,
        const MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.badgeOwned,
          refId: 'zephyr',
        ),
      );
      commands.setVisibilityRule(
        'traveller',
        const MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.visibleWhen,
          predicate: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.badgeNotOwned,
            refId: 'zephyr',
          ),
        ),
      );
      expect(
        _entity(document, 'traveller').npc!.visibilityRule!.predicate,
        const MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.badgeNotOwned,
          refId: 'zephyr',
        ),
      );
      final state = references.states.singleWhere(
        (entry) => entry.key == 'rival_seen',
      );
      commands.setVisibilityRule(
        'traveller',
        MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.visibleWhen,
          predicate: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.storyFlagSet,
            refId: state.refId,
          ),
        ),
      );
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
    },
  );

  test('chapter and cutscene rules retain their advanced description', () {
    final references = CharacterPresenceReferences(_project);
    for (final kind in [
      MapEntityRuntimePredicateKind.chapterCompleted,
      MapEntityRuntimePredicateKind.cutsceneCompleted,
    ]) {
      final document = _document([
        _npc(
          'warden',
          rule: MapEntityNpcVisibilityRule(
            mode: MapEntityNpcVisibilityMode.hiddenWhen,
            predicate: MapEntityRuntimePredicate(
              kind: kind,
              refId: 'chapter_two',
            ),
          ),
        ),
      ]);
      final rule = _entity(document, 'warden').npc!.visibilityRule!;
      expect(isCharacterStoryPresence(rule), isFalse);
      expect(
        references.describe(rule.predicate!).phrase,
        contains('chapter_two'),
      );
      expect(MapData.fromJson(document.current.toJson()), document.current);
    }
  });

  test('unloaded references are requested once and never flagged missing prematurely', () async {
    var ready = false;
    var loads = 0;
    final loader = CharacterPresenceReferenceLoader(
      ready: () => ready,
      load: () async {
        loads++;
      },
    );
    addTearDown(loader.dispose);
    await loader.request('guard', needed: true);
    await loader.request('guard', needed: true);
    expect(loads, 1);
    final reference = const MapEntityRuntimePredicate(
      kind: MapEntityRuntimePredicateKind.stepCompleted,
      refId: 'got_dex',
    );
    expect(
      CharacterPresenceReferences(
        workspaceProject,
        ready: ready,
      ).describe(reference).missing,
      isFalse,
    );
    ready = true;
    await loader.request('guard', needed: true);
    expect(loads, 1);
    expect(
      CharacterPresenceReferences(
        _project,
        ready: ready,
      ).resolve(reference)!.refId,
      'got_dex',
    );
  });

  test(
    'failed reference load keeps the persisted rule and reports failed state',
    () async {
      final document = _document([
        _npc(
          'guard',
          rule: const MapEntityNpcVisibilityRule(
            mode: MapEntityNpcVisibilityMode.visibleWhen,
            predicate: MapEntityRuntimePredicate(
              kind: MapEntityRuntimePredicateKind.badgeOwned,
              refId: 'zephyr',
            ),
          ),
        ),
      ]);
      final before = document.current;
      final loader = CharacterPresenceReferenceLoader(
        ready: () => false,
        load: () async => throw StateError('lecteur absent'),
      );
      addTearDown(loader.dispose);
      await loader.request('guard', needed: true);
      expect(loader.failed, isTrue);
      expect(
        CharacterPresenceReferences(
          _project,
          ready: false,
          failed: loader.failed,
        ).failed,
        isTrue,
      );
      expect(document.current, same(before));
    },
  );

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
