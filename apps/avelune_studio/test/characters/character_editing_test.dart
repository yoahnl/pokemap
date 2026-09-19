import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import '../support/map_workspace_fixture.dart';

const guide = ProjectCharacterEntry(
  id: 'guide',
  name: 'Chef de gare',
  tilesetId: 'atlas',
);

void main() {
  late EditableMapDocument document;
  late ProjectManifest project;
  late CharacterEditingCommands commands;
  setUp(() {
    document = EditableMapDocument(
      MapWorkspaceDocument(
        map: workspaceMap('a'),
        revision: 'base',
        mapId: 'a',
      ),
    );
    project = workspaceProject.copyWith(characters: [guide]);
    commands = CharacterEditingCommands(document, project);
  });
  test(
    'place, move, duplicate, properties, deletion and undo use map history',
    () {
      final first = commands.place(guide, const GridPos(x: 2, y: 3));
      expect(first.npc!.characterId, guide.id);
      expect(document.current.layers, workspaceMap('a').layers);
      commands.move(first.id, const GridPos(x: 4, y: 5));
      commands.update(
        first.id,
        name: 'Chef',
        facing: EntityFacing.east,
        blocks: false,
      );
      final clone = commands.duplicate(first.id);
      expect(clone.id, isNot(first.id));
      commands.update(clone.id, name: 'Voyageuse');
      expect(commands.selected(first.id)!.npc!.displayName, 'Chef');
      expect(clone.npc!.facing, EntityFacing.east);
      commands.delete(clone.id);
      expect(document.current.entities, hasLength(1));
      final saved = document.current;
      document.restore(redo: false);
      expect(document.current.entities, hasLength(2));
      document.restore(redo: true);
      expect(document.current, saved);
      expect(document.dirty, isTrue);
    },
  );
  test('changing one instance property preserves all advanced payloads', () {
    final first = commands.place(guide, const GridPos(x: 2, y: 3));
    final advanced = first.copyWith(
      properties: {'patrol-script': 'keep'},
      npc: first.npc!.copyWith(
        trainerId: 'trainer',
        lineOfSightRange: 5,
        dialogue: const DialogueRef(
          dialogueId: 'intro',
          scriptPathRelative: 'dialogues/intro.yarn',
        ),
        movement: const MapEntityNpcMovementConfig(
          mode: MapEntityNpcMovementMode.patrol,
          waypoints: [GridPos(x: 4, y: 3)],
          stepDurationMs: 480,
        ),
        conditionalDialogues: [
          MapEntityConditionalDialogue(
            when: const MapEntityRuntimePredicate(
              kind: MapEntityRuntimePredicateKind.storyFlagSet,
              refId: 'mission',
            ),
            dialogue: const DialogueRef(
              dialogueId: 'final',
              scriptPathRelative: 'dialogues/final.yarn',
            ),
          ),
        ],
      ),
    );
    document.commit(
      updateEntityOnMap(
        document.current,
        entityId: first.id,
        npc: advanced.npc,
        properties: advanced.properties,
      ),
    );
    commands.update(first.id, name: 'Renommé', blocks: false);
    final actual = commands.selected(first.id)!;
    expect(actual.npc, advanced.npc!.copyWith(displayName: 'Renommé'));
    expect(actual.properties, advanced.properties);
  });
  test('out of bounds does not add a history entry', () {
    expect(
      () => commands.place(guide, const GridPos(x: -1, y: 0)),
      throwsA(isA<ValidationException>()),
    );
    expect(document.undoCount, 0);
    expect(document.dirty, isFalse);
  });
  test('story source references block deletion with the canonical index', () {
    final first = commands.place(guide, const GridPos(x: 2, y: 3));
    project = project.copyWith(
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.dualRead,
        legacyClaims: [],
        records: [
          NarrativeEventRecord.draft(
            NarrativeEventDraft(
              id: 'evt_00000000-0000-7000-8000-000000000001',
              name: 'Conversation',
              source: NarrativeEventSourceRef.entityInteract('a', first.id),
              conditions: [],
              priority: 0,
              order: 0,
            ),
          ),
        ],
      ),
    );
    commands = CharacterEditingCommands(document, project);
    expect(commands.deletionProblem(first.id), contains('histoire'));
    expect(() => commands.delete(first.id), throwsStateError);
    expect(document.current.entities, hasLength(1));
  });
}
