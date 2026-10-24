import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/presentation/features/characters/character_inspector.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/combat_project_fixture.dart';
import '../support/m3_story_fixture.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets(
    'Studio authors battle readiness and refusal with faithful disk reopen',
    (tester) async {
      tester.view.physicalSize = const Size(900, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = (await tester.runAsync(() async {
        final source = await M3StoryFixture.create();
        await seedCombatProject(source);
        final file = File('${source.directory.path}/project.json');
        final project =
            ProjectManifest.fromJson(
              jsonDecode(await file.readAsString()) as Map<String, dynamic>,
            ).copyWith(
              trainers: [
                const ProjectTrainerEntry(
                  id: 'clock_guard',
                  name: 'Gardien',
                  trainerClass: 'Gardien',
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
        await file.writeAsString(jsonEncode(project.toJson()));
        final entry = project.maps.first;
        final mapFile = File('${source.directory.path}/${entry.relativePath}');
        final map = MapData.fromJson(
          jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>,
        );
        final original = map.entities.singleWhere(
          (entity) => entity.id == 'combat-guide',
        );
        final npc = original.npc!.copyWith(
          trainerId: 'clock_guard',
          facing: EntityFacing.east,
          visibilityRule: const MapEntityNpcVisibilityRule(
            mode: MapEntityNpcVisibilityMode.visibleWhen,
            predicate: MapEntityRuntimePredicate(
              kind: MapEntityRuntimePredicateKind.storyFlagSet,
              refId: 'started',
            ),
          ),
          conditionalDialogues: [
            MapEntityConditionalDialogue(
              when: const MapEntityRuntimePredicate(
                kind: MapEntityRuntimePredicateKind.storyFlagSet,
                refId: 'started',
              ),
              dialogue: DialogueRef(dialogueId: project.dialogues.first.id),
            ),
          ],
        );
        final updated = original.copyWith(
          npc: npc,
          properties: {'audit': 'keep'},
        );
        await mapFile.writeAsString(
          jsonEncode(
            map
                .copyWith(
                  entities: [
                    for (final entity in map.entities)
                      if (entity.id == updated.id) updated else entity,
                  ],
                )
                .toJson(),
          ),
        );
        await source.maps.loadProject(source.session);
        final document = EditableMapDocument(
          await source.maps.loadMap(source.session, entry),
        );
        return (source, project, document, updated);
      }))!;
      final (source, project, document, original) = fixture;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() => source.directory.delete(recursive: true));
      });
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
                    project: project,
                    entity: document.current.entities.singleWhere(
                      (entity) => entity.id == original.id,
                    ),
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
      await _select(tester, 'npc-combat-guide-readiness-mode', 'party');
      await _select(tester, 'npc-combat-guide-readiness-minimum', '2');
      await _select(
        tester,
        'npc-combat-guide-readiness-refusal',
        project.dialogues.first.id,
      );
      final saved = document.current;
      final changed = saved.entities.singleWhere((e) => e.id == original.id);
      expect(changed.npc!.trainerBattleReadyWhen!.minimumCount, 2);
      expect(
        changed.npc!.trainerBattleNotReadyDialogue?.dialogueId,
        project.dialogues.first.id,
      );
      expect(changed.npc!.visibilityRule, original.npc!.visibilityRule);
      expect(
        changed.npc!.conditionalDialogues,
        original.npc!.conditionalDialogues,
      );
      expect(changed.pos, original.pos);
      expect(changed.properties, original.properties);
      document.restore(redo: false);
      expect(document.current, isNot(saved));
      document.restore(redo: true);
      expect(document.current, saved);
      await tester.runAsync(
        () => source.maps.saveMap(source.session, document.base, saved),
      );
      final reopened = (await tester.runAsync(() async {
        final fresh = LocalMapWorkspaceAdapter();
        final manifest = await fresh.loadProject(source.session);
        return (await fresh.loadMap(source.session, manifest.maps.first)).map;
      }))!;
      expect(
        reopened.entities.singleWhere((e) => e.id == original.id),
        changed,
      );
      final trainerPicker = tester.widget<DropdownButtonFormField<String>>(
        find.byKey(const ValueKey('trainer-combat-guide-clock_guard')),
      );
      trainerPicker.onChanged!('');
      await tester.pumpAndSettle();
      final cleared = document.current.entities
          .singleWhere((e) => e.id == original.id)
          .npc!;
      expect(cleared.trainerId, isNull);
      expect(cleared.trainerBattleReadyWhen, isNull);
      expect(cleared.trainerBattleNotReadyDialogue, isNull);
      expect(cleared.visibilityRule, original.npc!.visibilityRule);
      expect(tester.takeException(), isNull);
    },
  );
}

StudioSelect _selectWidget(WidgetTester tester, String key) =>
    tester.widget<StudioSelect>(find.byKey(ValueKey(key)));
Future<void> _select(WidgetTester tester, String key, String value) async {
  final finder = find.byKey(ValueKey(key));
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
  await tester.pumpAndSettle();
  final widget = _selectWidget(tester, key);
  expect(widget.options, contains(value));
  widget.onChanged!(value);
  await tester.pumpAndSettle();
}
