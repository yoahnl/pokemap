import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_action_builder.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets(
    'logical pose uses a named owner picker and preserves position and facing when edited',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SceneNodePayload? submitted;
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SceneActionBuilder(
                initialCommandId: NarrativeCommandIds.setNpcPose,
                initialPayload: SceneActionPayload.consequence(
                  SceneConsequence.setNpcPose(
                    mapId: 'lab',
                    entityId: 'rival',
                    x: 14,
                    y: 4,
                    facing: EntityFacing.west,
                  ),
                ),
                project: const ProjectManifest(
                  name: 'Pose',
                  maps: [],
                  tilesets: [],
                ),
                pickerOptions: const {
                  NarrativeCommandParameterKind.mapEntityReference: [
                    SceneActionPickerOption(
                      id: 'lab::rival',
                      label: 'Laboratoire · Rival',
                    ),
                  ],
                },
                onSubmit: (value) => submitted = value,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final pickers = tester.widgetList<PokeMapDropdownField<String>>(
        find.byType(PokeMapDropdownField<String>),
      );
      expect(
        pickers.singleWhere((field) => field.label == 'PNJ à variantes').value,
        'lab::rival',
      );
      expect(
        pickers.singleWhere((field) => field.label == 'Direction').value,
        'west',
      );
      final field = find.byKey(const ValueKey('scene-action-parameter-x'));
      await tester.enterText(field, '5');
      await tester.ensureVisible(
        find.byKey(const ValueKey('scene-action-submit')),
      );
      await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
      expect(
        (submitted as SceneActionPayload).consequence,
        SceneConsequence.setNpcPose(
          mapId: 'lab',
          entityId: 'rival',
          x: 5,
          y: 4,
          facing: EntityFacing.west,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
