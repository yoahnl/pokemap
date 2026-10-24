import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/panels/entity_properties_panel.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

void main() {
  testWidgets('renaming preserves NPC time rules and other payload fields', (
    tester,
  ) async {
    final root = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('npc_time_panel_'),
    ))!;
    addTearDown(() => root.delete(recursive: true));
    const project = ProjectManifest(
      name: 'Time rules',
      maps: [],
      tilesets: [],
      dialogues: [
        ProjectDialogueEntry(
          id: 'guard_dialogue',
          name: 'Garde',
          relativePath: 'dialogues/guard.yarn',
        ),
      ],
      trainers: [
        ProjectTrainerEntry(
          id: 'guard',
          name: 'Garde',
          trainerClass: 'Garde',
          team: [
            ProjectTrainerPokemonEntry(
              speciesId: 'bulbasaur',
              level: 5,
              moves: ['tackle'],
            ),
          ],
        ),
      ],
    );
    await tester.runAsync(() async {
      await File(
        '${root.path}/project.json',
      ).writeAsString(jsonEncode(project.toJson()));
      await Directory('${root.path}/dialogues').create();
      await File(
        '${root.path}/dialogues/guard.yarn',
      ).writeAsString('title: After\n---\nBonsoir.\n===\n');
    });
    const npc = MapEntityNpcData(
      displayName: 'Guide',
      trainerId: 'guard',
      trainerBattleReadyWhen: MapEntityRuntimePredicate(kind: MapEntityRuntimePredicateKind.partyUsableCountAtLeast, minimumCount: 2),
      trainerBattleNotReadyDialogue: DialogueRef(dialogueId: 'guard_dialogue', scriptPathRelative: 'dialogues/guard.yarn', startNode: 'After'),
      facing: EntityFacing.west,
      lineOfSightRange: 5,
      movement: MapEntityNpcMovementConfig(
        pauseDurationMs: 700,
        stepDurationMs: 300,
      ),
      visibilityRule: MapEntityNpcVisibilityRule(
        mode: MapEntityNpcVisibilityMode.hiddenWhen,
        predicate: MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.localTimeWindow,
          timeWindow: LocalTimeWindow(startMinute: 240, endMinute: 1200),
        ),
      ),
      trainerBattleWhen: MapEntityRuntimePredicate(
        kind: MapEntityRuntimePredicateKind.localTimeWindow,
        timeWindow: LocalTimeWindow(startMinute: 1200, endMinute: 240),
      ),
      conditionalDialogues: [
        MapEntityConditionalDialogue(
          when: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.localTimeWindow,
            timeWindow: LocalTimeWindow(startMinute: 1200, endMinute: 1440),
          ),
          dialogue: DialogueRef(
            dialogueId: 'guard_dialogue',
            scriptPathRelative: 'dialogues/guard.yarn',
            startNode: 'After',
          ),
        ),
      ],
    );
    const entity = MapEntity(
      id: 'npc',
      name: 'Guide',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 1, y: 1),
      properties: {'audit': 'keep'},
      npc: npc,
    );
    const map = MapData(
      id: 'route',
      name: 'Route',
      size: GridSize(width: 4, height: 4),
      layers: [
        TileLayer(
          id: 'ground',
          name: 'Ground',
          cells: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        ),
      ],
      entities: [entity],
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = EditorState(
      projectRootPath: root.path,
      project: project,
      activeMap: map,
      activeLayerId: 'ground',
      selectedEntityId: 'npc',
    );
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const MaterialApp(
            home: CupertinoPageScaffold(
              child: Center(
                child: SizedBox(
                  width: 560,
                  height: 980,
                  child: EntityPropertiesPanel(embedded: true),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final name = find.byWidgetPredicate(
      (widget) => widget is EditableText && widget.controller.text == 'Guide',
    );
    expect(name, findsOneWidget);
    await tester.enterText(name, 'Guide renommé');
    final save = find.text('Enregistrer');
    await tester.scrollUntilVisible(
      save.hitTestable(),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(save.hitTestable(), findsOneWidget);
    await tester.tap(save);
    await tester.pumpAndSettle();
    final saved = container.read(editorNotifierProvider).activeMap!;
    final reloaded = MapData.fromJson(saved.toJson()).entities.single;
    expect(reloaded.npc!.displayName, 'Guide renommé');
    expect(reloaded.npc, npc.copyWith(displayName: 'Guide renommé'));
    expect(reloaded.pos, entity.pos);
    expect(reloaded.properties, entity.properties);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
