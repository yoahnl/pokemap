import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  final scenarios = <_LayoutScenario>[
    const _LayoutScenario(
      name: 'phone portrait',
      size: Size(390, 844),
      textScales: <double>[1, 2],
      safeArea: EdgeInsets.only(top: 44, bottom: 34),
      breakpoint: ProjectPresentationBreakpoint.compact,
    ),
    const _LayoutScenario(
      name: 'phone landscape',
      size: Size(844, 390),
      textScales: <double>[1, 2],
      safeArea: EdgeInsets.fromLTRB(21, 0, 21, 21),
      breakpoint: ProjectPresentationBreakpoint.compact,
    ),
    const _LayoutScenario(
      name: 'tablet portrait',
      size: Size(768, 1024),
      textScales: <double>[1, 2],
      safeArea: EdgeInsets.all(16),
      breakpoint: ProjectPresentationBreakpoint.regular,
    ),
    const _LayoutScenario(
      name: 'tablet landscape',
      size: Size(1024, 768),
      textScales: <double>[1, 2],
      safeArea: EdgeInsets.all(16),
      breakpoint: ProjectPresentationBreakpoint.regular,
    ),
    const _LayoutScenario(
      name: 'desktop HD',
      size: Size(1280, 720),
      textScales: <double>[1, 2],
      breakpoint: ProjectPresentationBreakpoint.expanded,
    ),
    const _LayoutScenario(
      name: 'desktop FHD',
      size: Size(1920, 1080),
      textScales: <double>[1],
      breakpoint: ProjectPresentationBreakpoint.expanded,
    ),
    const _LayoutScenario(
      name: 'ultra-wide',
      size: Size(2560, 1080),
      textScales: <double>[1],
      breakpoint: ProjectPresentationBreakpoint.expanded,
    ),
  ];

  for (final scenario in scenarios) {
    for (final textScale in scenario.textScales) {
      testWidgets(
        '${scenario.name} at ${textScale}x keeps title, pause and dialogue safe',
        (tester) async {
          tester.view.physicalSize = scenario.size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final layouts = suggestedProjectPresentationLayouts('cinematic');
          final breakpoint = scenario.breakpoint.name;

          await tester.pumpWidget(
            _app(
              scenario: scenario,
              textScale: textScale,
              layouts: layouts,
              child: PlayerTitleScreen(
                data: _titleData(),
                onSelected: (_) {},
              ),
            ),
          );
          expect(
            find.byKey(ValueKey<String>('player-title-responsive-$breakpoint')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);

          await tester.pumpWidget(
            _app(
              scenario: scenario,
              textScale: textScale,
              layouts: layouts,
              child: RuntimePlayerPauseShell(
                gameTitle: 'Le Train de 17h42',
                pauseSection: RuntimePlayerPauseSection.root,
                actions: _pauseActions(),
                onSelected: (_) {},
                onBackToRoot: () {},
                detail: const SizedBox.shrink(),
              ),
            ),
          );
          expect(
            find.byKey(
                ValueKey<String>('runtime-pause-responsive-$breakpoint')),
            findsOneWidget,
          );
          for (final element in find
              .byKey(const ValueKey<String>('player-action-focus-frame'))
              .evaluate()) {
            expect(
              tester
                  .getSize(find.byElementPredicate((value) => value == element))
                  .height,
              greaterThanOrEqualTo(48),
            );
          }
          expect(tester.takeException(), isNull);

          await tester.pumpWidget(
            _app(
              scenario: scenario,
              textScale: textScale,
              layouts: layouts,
              child: PlayerDialogueOverlay(
                snapshot: _dialogueSnapshot(),
                onCommand: (_) {},
                portraitBuilder: (_) => const SizedBox.square(dimension: 64),
              ),
            ),
          );
          expect(
            find.byKey(
                ValueKey<String>('player-dialogue-responsive-$breakpoint')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('pause focus remains stable when the breakpoint changes', (
    tester,
  ) async {
    final focusController = RuntimePlayerFocusController(
      logicalSelectionId: 'pause.pokedex',
    );
    addTearDown(focusController.dispose);
    final layouts = suggestedProjectPresentationLayouts('cinematic');
    const regular = _LayoutScenario(
      name: 'regular',
      size: Size(1024, 768),
      textScales: <double>[1],
      breakpoint: ProjectPresentationBreakpoint.regular,
    );
    const expanded = _LayoutScenario(
      name: 'expanded',
      size: Size(1280, 720),
      textScales: <double>[1],
      breakpoint: ProjectPresentationBreakpoint.expanded,
    );

    tester.view.physicalSize = regular.size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        scenario: regular,
        textScale: 1,
        layouts: layouts,
        child: _pauseShell(focusController),
      ),
    );
    focusController.select('pause.pokedex');
    await tester.pump();

    tester.view.physicalSize = expanded.size;
    await tester.pumpWidget(
      _app(
        scenario: expanded,
        textScale: 1,
        layouts: layouts,
        child: _pauseShell(focusController),
      ),
    );
    await tester.pump();

    expect(focusController.logicalSelectionId, 'pause.pokedex');
    expect(
      find.byKey(
        const ValueKey<String>('runtime-pause-responsive-expanded'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _pauseShell(RuntimePlayerFocusController focusController) =>
    RuntimePlayerPauseShell(
      gameTitle: 'Le Train de 17h42',
      pauseSection: RuntimePlayerPauseSection.root,
      actions: _pauseActions(),
      onSelected: (_) {},
      onBackToRoot: () {},
      focusController: focusController,
      logicalSelectionId: 'pause.pokedex',
      detail: const SizedBox.shrink(),
    );

Widget _app({
  required _LayoutScenario scenario,
  required double textScale,
  required ProjectPresentationLayoutsProfile layouts,
  required Widget child,
}) {
  final theme = PokeMapPlayerTheme.withLayoutProfile(
    PokeMapPlayerTheme.dark(),
    layouts,
  );
  return MaterialApp(
    locale: const Locale('fr'),
    supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
    localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
    theme: theme,
    builder: (context, appChild) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: scenario.safeArea,
        viewPadding: scenario.safeArea,
        textScaler: TextScaler.linear(textScale),
      ),
      child: appChild!,
    ),
    home: child,
  );
}

PlayerTitleViewData _titleData() => PlayerTitleViewData(
      gameTitle: 'Le Train de 17h42',
      author: 'Avelune Studio',
      description: 'Une aventure ferroviaire entre mémoire et mystère.',
      actions: <PlayerTitleMenuAction, PlayerActionAvailability>{
        for (final action in PlayerTitleMenuAction.values)
          action: PlayerActionAvailability.enabled,
      },
    );

Map<PlayerPauseAction, PlayerActionAvailability> _pauseActions() =>
    <PlayerPauseAction, PlayerActionAvailability>{
      for (final action in PlayerPauseAction.values)
        action: PlayerActionAvailability.enabled,
    };

DialoguePresentationSnapshot _dialogueSnapshot() =>
    const DialoguePresentationSnapshot(
      revision: 1,
      mode: DialoguePresentationMode.line,
      nodeTitle: 'layout-matrix',
      speaker: 'Élise',
      text: 'Le prochain train traversera Hanazuki dans quelques minutes.',
      fullText: 'Le prochain train traversera Hanazuki dans quelques minutes.',
      isCurrentLineFullyRevealed: true,
      isLastContent: false,
      choices: <DialoguePresentationChoice>[],
    );

final class _LayoutScenario {
  const _LayoutScenario({
    required this.name,
    required this.size,
    required this.textScales,
    required this.breakpoint,
    this.safeArea = EdgeInsets.zero,
  });

  final String name;
  final Size size;
  final List<double> textScales;
  final EdgeInsets safeArea;
  final ProjectPresentationBreakpoint breakpoint;
}
