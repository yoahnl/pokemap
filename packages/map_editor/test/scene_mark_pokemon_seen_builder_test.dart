import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_action_builder.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets(
    'seen-only action guides species choice and reopens without gift fields',
    (tester) async {
      tester.view.physicalSize = const Size(900, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SceneNodePayload? submitted;
      Future<void> pump(SceneActionPayload payload) => tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SceneActionBuilder(
                key: ValueKey(payload.consequence!.toJson()['speciesId']),
                initialCommandId: NarrativeCommandIds.markPokemonSeen,
                initialPayload: payload,
                project: const ProjectManifest(
                  name: 'Seen',
                  maps: [],
                  tilesets: [],
                ),
                pickerOptions: const {
                  NarrativeCommandParameterKind.species: [
                    SceneActionPickerOption(
                      id: 'bulbasaur',
                      label: 'Bulbizarre',
                    ),
                    SceneActionPickerOption(id: 'squirtle', label: 'Carapuce'),
                  ],
                },
                onSubmit: (value) => submitted = value,
              ),
            ),
          ),
        ),
      );
      await pump(
        SceneActionPayload.consequence(
          SceneConsequence.markPokemonSeen(speciesId: 'bulbasaur'),
        ),
      );
      await tester.pump();
      var picker = tester
          .widgetList<PokeMapDropdownField<String>>(
            find.byType(PokeMapDropdownField<String>),
          )
          .singleWhere((field) => field.label == 'Espèce');
      expect(picker.value, 'bulbasaur');
      expect(
        find.byKey(const ValueKey('scene-action-parameter-level')),
        findsNothing,
      );
      picker.onChanged('squirtle');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('scene-action-submit')),
      );
      await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
      expect(
        (submitted as SceneActionPayload).consequence,
        SceneConsequence.markPokemonSeen(speciesId: 'squirtle'),
      );
      await pump(submitted as SceneActionPayload);
      await tester.pump();
      picker = tester
          .widgetList<PokeMapDropdownField<String>>(
            find.byType(PokeMapDropdownField<String>),
          )
          .singleWhere((field) => field.label == 'Espèce');
      expect(picker.value, 'squirtle');
      expect(tester.takeException(), isNull);
    },
  );
}
