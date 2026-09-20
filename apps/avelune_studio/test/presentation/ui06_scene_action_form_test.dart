import 'package:avelune_studio/presentation/features/scenes/scene_action_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  final project = ProjectManifest(
    name: 'Action fixture',
    maps: const [],
    tilesets: const [],
    facts: [NarrativeFactDefinition(id: 'departure', label: 'Départ autorisé')],
  );

  Future<void> pump(
    WidgetTester tester, {
    SceneNodePayload? current,
    required ValueChanged<SceneNodePayload> onApply,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: SceneActionForm(
            project: project,
            current: current,
            onApply: onApply,
          ),
        ),
      ),
    ),
  );

  testWidgets('action edits preserve opaque metadata until explicit apply', (
    tester,
  ) async {
    final original = SceneActionPayload.consequence(
      SceneConsequence.setFact(factId: 'departure', value: true),
      actionKind: 'author-label',
      parameters: const {'annotation': 'keep'},
    );
    final applied = <SceneNodePayload>[];
    await pump(tester, current: original, onApply: applied.add);
    expect(find.text('Départ autorisé'), findsOneWidget);
    expect(applied, isEmpty);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    expect(applied, isEmpty);
    expect(
      original.consequence,
      SceneConsequence.setFact(factId: 'departure', value: true),
    );
    await tester.tap(find.text('Appliquer l’action'));
    final result = applied.single as SceneActionPayload;
    expect(result.parameters, original.parameters);
    expect(result.actionKind, original.actionKind);
    expect(
      result.consequence,
      SceneConsequence.setFact(factId: 'departure', value: false),
    );
  });

  testWidgets('missing references remain explicit and cannot apply', (
    tester,
  ) async {
    final original = SceneActionPayload.consequence(
      SceneConsequence.setFact(factId: 'removed', value: true),
    );
    var applied = false;
    await pump(tester, current: original, onApply: (_) => applied = true);
    expect(
      find.textContaining('Référence introuvable : removed'),
      findsOneWidget,
    );
    expect(
      tester.widget<StudioButton>(find.byType(StudioButton)).onPressed,
      isNull,
    );
    expect(applied, isFalse);
  });

  testWidgets('unsupported payload is retained until explicit replacement', (
    tester,
  ) async {
    final original = SceneActionPayload(
      actionKind: 'custom-untouched',
      parameters: const {'private': 'value'},
    );
    final applied = <SceneNodePayload>[];
    await pump(tester, current: original, onApply: applied.add);
    expect(find.textContaining('paramètres avancés'), findsOneWidget);
    expect(
      tester.widget<StudioButton>(find.byType(StudioButton)).onPressed,
      isNull,
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Donner de l’argent').last);
    await tester.pumpAndSettle();
    expect(applied, isEmpty);
    await tester.enterText(find.byType(TextField), 'invalide');
    await tester.pump();
    expect(
      tester.widget<StudioButton>(find.byType(StudioButton)).onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextField), '42');
    await tester.pump();
    await tester.tap(find.text('Appliquer l’action'));
    expect(
      (applied.single as SceneActionPayload).consequence,
      SceneConsequence.giveMoney(amount: 42),
    );
    expect(original.parameters, const {'private': 'value'});
  });
}
