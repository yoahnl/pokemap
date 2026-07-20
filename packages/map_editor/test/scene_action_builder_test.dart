import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_action_builder.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('builds a persistent action from guided picker values',
      (tester) async {
    SceneNodePayload? submitted;
    SceneActionBuildResult? submittedResult;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.giveItem,
      options: {
        NarrativeCommandParameterKind.item: const [
          SceneActionPickerOption(id: 'potion', label: 'Potion'),
        ],
      },
      onSubmit: (payload) => submitted = payload,
      onSubmitResult: (result) => submittedResult = result,
    );

    expect(find.text('Persistant'), findsOneWidget);
    expect(find.text('FG-083'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('scene-action-parameter-quantity')),
      '2',
    );
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();

    final action = submitted! as SceneActionPayload;
    expect(
      action.consequence,
      SceneConsequence.giveItem(itemId: 'potion', quantity: 2),
    );
    expect(submittedResult!.command.id, NarrativeCommandIds.giveItem);
    expect(submittedResult!.parameters, {'itemId': 'potion', 'quantity': '2'});
  });

  testWidgets('empty guided picker blocks publication without asking for an ID',
      (tester) async {
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.giveItem,
    );

    expect(find.textContaining('Aucun Objet disponible'), findsOneWidget);
    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(const ValueKey('scene-action-submit')),
          )
          .onPressed,
      isNull,
    );
    expect(find.byType(PokeMapTextField), findsOneWidget);
  });

  testWidgets('unsupported FG mechanic stays visible and cannot be submitted',
      (tester) async {
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.healParty,
    );

    expect(find.text('Non disponible'), findsOneWidget);
    expect(find.text('FG-092'), findsOneWidget);
    expect(find.textContaining('healParty'), findsOneWidget);
    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(const ValueKey('scene-action-submit')),
          )
          .onPressed,
      isNull,
    );
  });
}

Future<void> _pumpBuilder(
  WidgetTester tester, {
  required String initialCommandId,
  Map<NarrativeCommandParameterKind, List<SceneActionPickerOption>> options =
      const {},
  ValueChanged<SceneNodePayload>? onSubmit,
  ValueChanged<SceneActionBuildResult>? onSubmitResult,
}) async {
  tester.view.physicalSize = const Size(900, 760);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.light(),
      darkTheme: PokeMapTheme.dark(),
      themeMode: ThemeMode.dark,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SceneActionBuilder(
            initialCommandId: initialCommandId,
            pickerOptions: options,
            onSubmit: onSubmit ?? (_) {},
            onSubmitResult: onSubmitResult,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
