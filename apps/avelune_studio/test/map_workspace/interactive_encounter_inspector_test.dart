import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_interactive_encounter_draft.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  for (final trigger in InteractiveEncounterTrigger.values) {
    test('${trigger.name} table and reuse remain canonical with undo', () {
      final entity = MapEntity(
        id: 'tree',
        kind: MapEntityKind.custom,
        pos: const GridPos(x: 2, y: 2),
        editorVisual: const MapEntityEditorVisual(elementId: 'tree'),
        fieldObstacle: trigger == InteractiveEncounterTrigger.afterRockSmash
            ? const MapEntityFieldObstacleData(
                kind: FieldObstacleKind.rockSmashRock,
              )
            : null,
      );
      final map = workspaceMap('a').copyWith(entities: [entity]);
      final project = workspaceProject.copyWith(
        encounterTables: [
          ProjectEncounterTable(
            id: 'objects',
            name: 'Rencontres des objets',
            encounterKind: trigger == InteractiveEncounterTrigger.headbutt
                ? EncounterKind.headbutt
                : EncounterKind.special,
            entries: const [
              ProjectEncounterEntry(
                speciesId: 'test',
                minLevel: 2,
                maxLevel: 2,
              ),
            ],
          ),
        ],
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, revision: 'base', mapId: 'a'),
      );
      final commands = MapEntityEditingCommands(document, project);
      MapInteractiveEncounterDraft draft() => MapInteractiveEncounterDraft(
        document.current.entities.single,
        project,
      );
      expect(commands.canConfigureFieldObstacle(entity), isTrue);
      expect(draft().tables.single.id, 'objects');
      commands.setInteractiveEncounter(entity.id, draft().change());
      expect(
        document.current.entities.single.interactiveEncounter!.trigger,
        trigger,
      );
      expect(
        document.current.entities.single.interactiveEncounter!.encounterTableId,
        'objects',
      );
      commands.setInteractiveEncounter(
        entity.id,
        draft().change(
          reuse: InteractiveEncounterReusePolicy.oncePerMapInstance,
        ),
      );
      expect(
        document.current.entities.single.interactiveEncounter!.reusePolicy,
        InteractiveEncounterReusePolicy.oncePerMapInstance,
      );
      expect(
        MapData.fromJson(document.current.toJson())
            .entities
            .single
            .interactiveEncounter,
        document.current.entities.single.interactiveEncounter,
      );
      document.restore(redo: false);
      expect(
        document.current.entities.single.interactiveEncounter!.reusePolicy,
        InteractiveEncounterReusePolicy.repeatable,
      );
      document.restore(redo: false);
      expect(document.current, map);
    });
  }

  test(
    'table changes preserve existing conditions and presentation settings',
    () {
      final condition = ScriptConditionFactory.factEquals(
        'enabled',
        const NarrativeValue.boolean(true),
      );
      final payload = MapEntityInteractiveEncounterData(
        trigger: InteractiveEncounterTrigger.headbutt,
        encounterTableId: 'old',
        conditions: [condition],
      );
      final entity = MapEntity(
        id: 'tree',
        kind: MapEntityKind.custom,
        pos: const GridPos(x: 2, y: 2),
        interactiveEncounter: payload,
      );
      final changed = MapInteractiveEncounterDraft(
        entity,
        workspaceProject,
      ).change(tableId: 'new');
      expect(changed.conditions, payload.conditions);
      expect(changed.reusePolicy, payload.reusePolicy);
      expect(
        changed.presentation,
        payload.presentation.copyWith(encounterTableId: 'new'),
      );
    },
  );
}
