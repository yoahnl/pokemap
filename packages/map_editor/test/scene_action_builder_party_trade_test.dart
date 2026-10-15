import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_action_builder.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('party trade guide submits the typed native party command', (
    tester,
  ) async {
    SceneNodePayload? submitted;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.openPartyTrade,
      project: const ProjectManifest(name: '2D', maps: [], tilesets: []),
      onSubmit: (payload) => submitted = payload,
    );
    expect(find.text('Échanger deux Pokémon de l’équipe'), findsOneWidget);
    expect(_submitButton(tester).onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    expect((submitted as SceneActionPayload).interactiveCommand!.toJson(), {
      'kind': 'openPartyTrade',
    });
  });

  testWidgets('party trade guide refuses 3D and missing project context', (
    tester,
  ) async {
    for (final project in <ProjectManifest?>[
      null,
      const ProjectManifest(
        name: '3D',
        maps: [],
        tilesets: [],
        settings: ProjectSettings(dimension: ProjectDimension.threeD),
      ),
    ]) {
      await _pumpBuilder(
        tester,
        initialCommandId: NarrativeCommandIds.openPartyTrade,
        initialPayload: SceneActionPayload.interactive(
          SceneInteractiveCommand.openPartyTrade(),
        ),
        project: project,
        onSubmit: (_) => fail('A party trade requires a known 2D project'),
      );
      final picker = tester.widget<PokeMapDropdownField<String>>(
        find.byWidgetPredicate(
          (widget) =>
              widget is PokeMapDropdownField<String> &&
              widget.label == 'Type de commande',
        ),
      );
      expect(
        picker.items.any(
          (item) => item.value == NarrativeCommandIds.openPartyTrade,
        ),
        isFalse,
      );
      expect(_submitButton(tester).onPressed, isNull);
    }
  });
}

Future<void> _pumpBuilder(
  WidgetTester tester, {
  required String initialCommandId,
  ProjectManifest? project,
  SceneActionPayload? initialPayload,
  required ValueChanged<SceneNodePayload> onSubmit,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: SceneActionBuilder(
            key: UniqueKey(),
            initialCommandId: initialCommandId,
            project: project,
            initialPayload: initialPayload,
            onSubmit: onSubmit,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

PokeMapButton _submitButton(WidgetTester tester) => tester
    .widget<PokeMapButton>(find.byKey(const ValueKey('scene-action-submit')));
