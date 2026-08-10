import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/features/personalization/presentation/personalization_scene_inspector.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  testWidgets('shows only the targets that belong to the selected scene', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const PersonalizationSceneInspector(
          scene: PersonalizationStudioScene.pause,
          target: PauseLabelsTarget(),
          onTargetSelected: _ignoreTarget,
          title: 'Menu Pause',
          description: 'Personnalisez le menu ouvert pendant le jeu.',
          child: Text('Réglages Pause'),
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey<String>('personalization-inspector-target-pauseLabels'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>(
          'personalization-inspector-target-pauseAppearance',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('personalization-inspector-target-pauseLayout'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('personalization-inspector-target-globalColors'),
      ),
      findsNothing,
    );
    expect(find.text('Réglages Pause'), findsOneWidget);
  });

  testWidgets('changes the contextual section without changing route', (
    tester,
  ) async {
    PersonalizationInspectorTarget? selected;
    await tester.pumpWidget(
      _app(
        PersonalizationSceneInspector(
          scene: PersonalizationStudioScene.dialogue,
          target: const DialogueAppearanceTarget(),
          onTargetSelected: (target) => selected = target,
          title: 'Dialogue',
          description: 'Personnalisez la bulle de dialogue.',
          child: const Text('Apparence actuelle'),
        ),
      ),
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          'personalization-inspector-target-dialogueTypography',
        ),
      ),
    );
    await tester.pump();

    expect(selected, isA<DialogueTypographyTarget>());
    expect(find.byType(Navigator), findsOneWidget);
  });
}

void _ignoreTarget(PersonalizationInspectorTarget target) {}

Widget _app(Widget child) => MaterialApp(
  theme: PokeMapTheme.light(),
  home: Scaffold(
    body: Center(child: SizedBox(width: 360, height: 720, child: child)),
  ),
);
