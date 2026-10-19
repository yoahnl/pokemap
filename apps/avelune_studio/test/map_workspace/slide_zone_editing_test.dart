import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_zone_inspector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

const _area = MapRect(
  pos: GridPos(x: 2, y: 2),
  size: GridSize(width: 4, height: 3),
);

void main() {
  test(
    'Studio slide create, edit, undo, save and cold reopen preserve the zone',
    () async {
      final temporary = await Directory.systemTemp.createTemp('studio-slide-');
      final root = Directory(await temporary.resolveSymbolicLinks());
      addTearDown(() => root.delete(recursive: true));
      final project = workspaceProject.copyWith(maps: [workspaceEntries.first]);
      final initial = workspaceMap('a');
      await File('${root.path}/project.json')
          .writeAsString(jsonEncode(project.toJson()));
      await File('${root.path}/a.json')
          .writeAsString(jsonEncode(initial.toJson()));
      final session = ProjectSession(
        sessionId: root.path,
        name: 'Glissade',
        directoryPath: root.path,
      );
      final adapter = LocalMapWorkspaceAdapter();
      final loadedProject = await adapter.loadProject(session);
      final base = await adapter.loadMap(session, loadedProject.maps.single);
      final document = EditableMapDocument(base);
      final commands = GameplayZoneEditingCommands(document, loadedProject);
      final zone = commands.place(GameplayZoneKind.movementEffect, _area);
      expect(zone.movementEffect, const MovementEffectZonePayload());
      commands.updateMovementEffect(
        zone.id,
        effectKind: MovementEffectZoneKind.movementCost,
        movementCost: 3,
      );
      commands.updateMovementEffect(
        zone.id,
        effectKind: MovementEffectZoneKind.slide,
      );
      final edited = document.current;
      final effect = edited.gameplayZones.single.movementEffect!;
      expect(effect.effectKind, MovementEffectZoneKind.slide);
      expect(effect.movementCost, 3);
      document.restore(redo: false);
      expect(
        document.current.gameplayZones.single.movementEffect!.effectKind,
        MovementEffectZoneKind.movementCost,
      );
      document.restore(redo: true);
      expect(document.current, edited);
      final revision = await adapter.saveMap(session, base, document.current);
      document.acceptSave(document.current, revision);
      final cold = LocalMapWorkspaceAdapter();
      final coldProject = await cold.loadProject(session);
      final reopened = await cold.loadMap(session, coldProject.maps.single);
      expect(reopened.map, edited);
      expect(reopened.map.layers, initial.layers);
      expect(reopened.map.entities, initial.entities);
      commands.retype(zone.id, GameplayZoneKind.hazard);
      expect(document.current.gameplayZones.single.movementEffect, isNull);
      document.restore(redo: false);
      expect(document.current, edited);
      expect(
        () => commands.updateMovementEffect(zone.id, movementCost: 0),
        throwsA(isA<ValidationException>()),
      );
      expect(document.current, edited);
    },
  );

  testWidgets('Studio slide explains entry direction and hides inactive cost', (
    tester,
  ) async {
    final document = EditableMapDocument(
      MapWorkspaceDocument(
        map: workspaceMap('a'),
        revision: 'base',
        mapId: 'a',
      ),
    );
    final commands = GameplayZoneEditingCommands(document, workspaceProject);
    final zone = commands.place(GameplayZoneKind.movementEffect, _area);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MapZoneInspector(
              document: document,
              project: workspaceProject,
              zone: zone,
              onChanged: () {},
              onDeleted: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('Glissade'), findsOneWidget);
    expect(find.textContaining('direction d’entrée'), findsOneWidget);
    expect(find.text('Coût par pas'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Studio movement cost keeps its existing editable cost', (
    tester,
  ) async {
    final document = EditableMapDocument(
      MapWorkspaceDocument(
        map: workspaceMap('a'),
        revision: 'base',
        mapId: 'a',
      ),
    );
    final commands = GameplayZoneEditingCommands(document, workspaceProject);
    final zone = commands.place(GameplayZoneKind.movementEffect, _area);
    commands.updateMovementEffect(
      zone.id,
      effectKind: MovementEffectZoneKind.movementCost,
      movementCost: 2,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MapZoneInspector(
              document: document,
              project: workspaceProject,
              zone: commands.selected(zone.id)!,
              onChanged: () {},
              onDeleted: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('Coût par pas'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
