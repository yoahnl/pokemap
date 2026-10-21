import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_action_builder.dart';

void main() {
  testWidgets(
    'Studio reopens a named Fact workflow with source prompts and guided text targets',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final command = SceneInteractiveCommand.fromJson({
        'kind': 'inputTextToFact',
        'factId': 'rival',
        'prompt': {
          'localizationKey': 'source.rival.name',
          'fallbackText': 'Son nom ?',
          'arguments': {'kept': 'source'},
        },
        'confirmationPrompt': {
          'localizationKey': 'source.rival.confirm',
          'fallbackText': 'Confirmer {value} ?',
        },
        'constraints': {'minGraphemes': 1, 'maxGraphemes': 7},
        'presetValues': ['Blue', 'Gary', 'Michael'],
        'customChoiceLabel': 'Custom',
        'presetChoicePrompt': {
          'localizationKey': 'source.rival.choice',
          'fallbackText': 'Quel nom ?',
        },
      });
      SceneNodePayload? submitted;
      final project = ProjectManifest(
        name: 'Names',
        maps: [],
        tilesets: [],
        facts: [
          NarrativeFactDefinition(
            id: 'rival',
            label: 'Nom du rival',
            initialValue: NarrativeValue.string(''),
          ),
          NarrativeFactDefinition(id: 'flag', label: 'Booléen'),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SceneActionBuilder(
                project: project,
                initialCommandId: 'inputTextToFact',
                initialPayload: SceneActionPayload.interactive(command),
                onSubmit: (value) => submitted = value,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final picker = tester
          .widgetList<PokeMapDropdownField<String>>(
            find.byType(PokeMapDropdownField<String>),
          )
          .singleWhere((field) => field.label == 'Fact texte');
      expect(picker.items.map((item) => item.value), ['rival']);
      for (final entry in {
        'prompt': 'Son nom ?',
        'confirmationPrompt': 'Confirmer {value} ?',
        'minGraphemes': '1',
        'maxGraphemes': '7',
        'presetValues': 'Blue\nGary\nMichael',
        'customChoiceLabel': 'Custom',
        'presetChoicePrompt': 'Quel nom ?',
      }.entries) {
        expect(
          tester
              .widget<TextField>(
                find.byKey(ValueKey('scene-action-parameter-${entry.key}')),
              )
              .controller!
              .text,
          entry.value,
        );
      }
      await tester.ensureVisible(
        find.byKey(const ValueKey('scene-action-submit')),
      );
      await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
      expect((submitted as SceneActionPayload).interactiveCommand, command);
      await tester.enterText(
        find.byKey(const ValueKey('scene-action-parameter-maxGraphemes')),
        '0',
      );
      await tester.pump();
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('scene-action-submit')),
            )
            .onPressed,
        isNull,
      );
    },
  );
}
