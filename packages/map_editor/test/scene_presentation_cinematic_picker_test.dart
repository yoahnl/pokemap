import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_presentation_cinematic_picker.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('Create and link is an enabled explicit picker choice', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: const Scaffold(
          body: ScenePresentationCinematicPicker(cinematics: []),
        ),
      ),
    );

    final finder = find.byKey(
      const ValueKey('scene-presentation-picker-create-and-link'),
    );
    expect(finder, findsOneWidget);
    expect(tester.widget<PokeMapButton>(finder).onPressed, isNotNull);
    expect(find.text('Créer et lier'), findsOneWidget);
  });
}
