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

  testWidgets('canonical heal command is authorable without raw parameters',
      (tester) async {
    SceneNodePayload? submitted;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.healParty,
      onSubmit: (payload) => submitted = payload,
    );

    expect(find.text('Persistant'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();

    expect(
      (submitted! as SceneActionPayload).consequence,
      SceneConsequence.healParty(),
    );
  });

  testWidgets('badge and field ability use project-owned guided pickers',
      (tester) async {
    SceneNodePayload? badgePayload;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.awardBadge,
      options: const {
        NarrativeCommandParameterKind.badge: [
          SceneActionPickerOption(id: 'badge_tide', label: 'Badge Marée'),
        ],
      },
      onSubmit: (payload) => badgePayload = payload,
    );

    expect(find.text('Badge Marée'), findsOneWidget);
    expect(find.byType(PokeMapTextField), findsNothing);
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();
    expect(
      (badgePayload! as SceneActionPayload).consequence,
      SceneConsequence.awardBadge(badgeId: 'badge_tide'),
    );

    SceneNodePayload? fieldPayload;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.unlockFieldAbility,
      options: const {
        NarrativeCommandParameterKind.fieldAbility: [
          SceneActionPickerOption(id: 'surf', label: 'Surf'),
        ],
      },
      onSubmit: (payload) => fieldPayload = payload,
    );
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();
    expect(
      (fieldPayload! as SceneActionPayload).consequence,
      SceneConsequence.unlockFieldAbility(ability: FieldAbility.surf),
    );
  });

  testWidgets('deleted picker target is kept visible and blocks editing',
      (tester) async {
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.awardBadge,
      initialParameters: const {'badgeId': 'badge_deleted'},
      options: const {
        NarrativeCommandParameterKind.badge: [
          SceneActionPickerOption(id: 'badge_tide', label: 'Badge Marée'),
        ],
      },
    );

    expect(find.textContaining('badge_deleted'), findsOneWidget);
    expect(find.textContaining('n’existe plus'), findsOneWidget);
    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(const ValueKey('scene-action-submit')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('editing preserves an existing non-default picker target',
      (tester) async {
    SceneActionBuildResult? result;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.awardBadge,
      initialParameters: const {'badgeId': 'badge_tide'},
      options: const {
        NarrativeCommandParameterKind.badge: [
          SceneActionPickerOption(id: 'badge_leaf', label: 'Badge Feuille'),
          SceneActionPickerOption(id: 'badge_tide', label: 'Badge Marée'),
        ],
      },
      onSubmitResult: (value) => result = value,
    );

    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();

    expect(result!.parameters['badgeId'], 'badge_tide');
    expect(
      (result!.payload as SceneActionPayload).consequence,
      SceneConsequence.awardBadge(badgeId: 'badge_tide'),
    );
  });

  testWidgets('commands absent from the current runtime stay hidden',
      (tester) async {
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.healParty,
      runtimeCommandIds: const {NarrativeCommandIds.healParty},
    );

    expect(find.text('Soigner l’équipe'), findsOneWidget);
    expect(find.text('Donner un badge'), findsNothing);
    expect(find.text('Modifier la présence d’un PNJ'), findsNothing);
  });

  testWidgets('Finish Game uses friendly fields and guided policy pickers',
      (tester) async {
    SceneNodePayload? submitted;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.finishGame,
      runtimeCommandIds: const {NarrativeCommandIds.finishGame},
      initialParameters: const {
        'endingName': 'Selbrume sauvée',
        'resultTitle': 'Selbrume est sauvée',
        'resultSummary': 'La brume se retire.',
        'includeCredits': 'false',
      },
      onSubmit: (payload) => submitted = payload,
    );

    expect(find.text('Issue de la partie'), findsOneWidget);
    expect(find.text('Après la fin'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('scene-action-parameter-endingId')),
      findsNothing,
    );

    final finishSubmit = find.byKey(const ValueKey('scene-action-submit'));
    await tester.ensureVisible(finishSubmit);
    final finishButton = tester.widget<PokeMapButton>(finishSubmit);
    expect(finishButton.onPressed, isNotNull);
    finishButton.onPressed!();
    await tester.pump();

    final consequence = (submitted! as SceneActionPayload).consequence!
        as SceneFinishGameConsequence;
    expect(consequence.endingId, 'ending.selbrume-sauvee');
    expect(consequence.credits, isNull);
    expect(
      consequence.postGamePolicy,
      ScenePostGamePolicy.continueGame,
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
  Map<String, String> initialParameters = const {},
  Set<String>? runtimeCommandIds,
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
            key: ValueKey('builder-$initialCommandId'),
            initialCommandId: initialCommandId,
            pickerOptions: options,
            initialParameters: initialParameters,
            runtimeCommandIds: runtimeCommandIds,
            onSubmit: onSubmit ?? (_) {},
            onSubmitResult: onSubmitResult,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
