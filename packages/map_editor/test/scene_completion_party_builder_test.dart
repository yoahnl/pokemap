import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_action_builder.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('finishGame recording stays opt-in and keeps the stored ending', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final original = SceneConsequence.finishGame(
      endingId: 'custom.champion',
      outcome: SceneGameCompletionOutcome.victory,
      result: SceneFinishGameResult(
        title: SceneLocalizedText(
          fallback: 'Victoire',
          translations: {'de': 'Sieg'},
        ),
        summary: SceneLocalizedText(fallback: 'Parcours accompli'),
        details: [SceneLocalizedText(fallback: 'Équipe gagnante')],
      ),
      postGamePolicy: ScenePostGamePolicy.continueGame,
      label: 'Conservé',
      notes: 'Notes',
    );
    SceneNodePayload? submitted;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SceneActionBuilder(
              project: const ProjectManifest(
                name: 'Fin',
                maps: [],
                tilesets: [],
              ),
              initialCommandId: NarrativeCommandIds.finishGame,
              initialPayload: SceneActionPayload.consequence(original),
              onSubmit: (value) => submitted = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final toggle = tester
        .widgetList<PokeMapDropdownField<String>>(
          find.byType(PokeMapDropdownField<String>),
        )
        .singleWhere(
          (widget) =>
              widget.label ==
              'Enregistrer l’équipe dans le journal des victoires',
        );
    expect(toggle.value, 'false');
    toggle.onChanged('true');
    await tester.pumpAndSettle();
    final submit = find.byKey(const ValueKey('scene-action-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    expect((submitted as SceneActionPayload).consequence!.toJson(), {
      ...original.toJson(),
      'recordParty': true,
    });
    expect(tester.takeException(), isNull);
  });
}
