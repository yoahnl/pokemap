import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test('a zone adopts its table type and excludes scripted encounters', () {
    final document = EditableMapDocument(
      MapWorkspaceDocument(
        map: workspaceMap('a'),
        revision: 'base',
        mapId: 'a',
      ),
    );
    final project = workspaceProject.copyWith(
      encounterTables: const [
        ProjectEncounterTable(
          id: 'surf_table',
          name: 'Eau',
          encounterKind: EncounterKind.surf,
        ),
        ProjectEncounterTable(
          id: 'unique_table',
          name: 'Unique',
          encounterKind: EncounterKind.special,
          tags: ['studio:unique'],
        ),
      ],
    );
    final commands = GameplayZoneEditingCommands(document, project);
    final zone = commands.place(
      GameplayZoneKind.encounter,
      const MapRect(
        pos: GridPos(x: 2, y: 2),
        size: GridSize(width: 2, height: 2),
      ),
    );

    expect(commands.encounterTables().map((table) => table.id), ['surf_table']);
    commands.updateEncounter(zone.id, tableId: 'surf_table');
    expect(
      commands.selected(zone.id)?.encounter?.encounterKind,
      EncounterKind.surf,
    );
    expect(commands.coverageProblem(commands.selected(zone.id)!), isNull);
  });
}
