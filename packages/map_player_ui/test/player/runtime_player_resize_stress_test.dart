import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets(
      'portrait landscape expanded portrait keeps scene focus and scroll',
      (tester) async {
    await _setSurface(tester, const Size(390, 500));
    final sceneMounts = ValueNotifier<int>(0);
    addTearDown(sceneMounts.dispose);
    final snapshot = _pausedSnapshot(
      section: RuntimePlayerPauseSection.root,
      logicalSelectionId: 'pause.bag',
    );

    await tester.pumpWidget(_app(
      RuntimePlayerSurfaceRouter(
        snapshot: snapshot,
        titlePresentation: const RuntimePlayerTitlePresentation(
          author: 'Studio Test',
        ),
        gameSceneBuilder: (_) => _SceneMountProbe(mounts: sceneMounts),
        onAction: (_) async => const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.accepted,
        ),
      ),
    ));
    await tester.pump();

    expect(sceneMounts.value, 1);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'Player action: Sac',
    );
    final portraitList = find.byKey(
      const ValueKey<String>('player-pause-list'),
    );
    await tester.drag(portraitList, const Offset(0, -180));
    await tester.pump();
    final portraitOffset = _scrollOffset(tester, portraitList);
    expect(portraitOffset, greaterThan(0));

    for (final size in <Size>[
      const Size(844, 390),
      const Size(1280, 800),
      const Size(390, 500),
    ]) {
      tester.view.physicalSize = size;
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull, reason: '$size');
      expect(sceneMounts.value, 1, reason: '$size');
    }

    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'Player action: Sac',
    );
    expect(
      _scrollOffset(
        tester,
        find.byKey(const ValueKey<String>('player-pause-list')),
      ),
      closeTo(portraitOffset, .1),
    );
  });

  testWidgets('detail section and portrait scroll survive the same sequence',
      (tester) async {
    await _setSurface(tester, const Size(390, 500));
    final focus = RuntimePlayerFocusController(
      logicalSelectionId: 'pause.party',
    );
    addTearDown(focus.dispose);

    await tester.pumpWidget(_app(
      RuntimePlayerPauseShell(
        gameTitle: 'Aube',
        pauseSection: RuntimePlayerPauseSection.party,
        actions: _actions(),
        onSelected: (_) {},
        onBackToRoot: () {},
        logicalSelectionId: 'pause.party',
        focusController: focus,
        detail: Column(
          children: <Widget>[
            for (var index = 0; index < 30; index++)
              SizedBox(
                height: 48,
                child: Text('Membre $index'),
              ),
          ],
        ),
      ),
    ));

    expect(find.text('Équipe'), findsOneWidget);
    final detailScroll = find.byKey(
      const ValueKey<String>('runtime-pause-detail-scroll'),
    );
    await tester.drag(detailScroll, const Offset(0, -240));
    await tester.pump();
    final portraitOffset = _scrollOffset(tester, detailScroll);
    expect(portraitOffset, greaterThan(0));

    for (final size in <Size>[
      const Size(844, 390),
      const Size(1280, 800),
      const Size(390, 500),
    ]) {
      tester.view.physicalSize = size;
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull, reason: '$size');
      expect(focus.logicalSelectionId, 'pause.party');
      expect(find.text('Membre 29'), findsOneWidget);
    }

    expect(
      _scrollOffset(
        tester,
        find.byKey(
          const ValueKey<String>('runtime-pause-detail-scroll'),
        ),
      ),
      closeTo(portraitOffset, .1),
    );
  });

  for (final scale in <double>[1, 1.5, 2]) {
    testWidgets(
        'text scale $scale remains usable with reduced height and motion',
        (tester) async {
      await _setSurface(tester, const Size(390, 520));

      await tester.pumpWidget(_app(
        RuntimePlayerPauseShell(
          gameTitle: 'Aube',
          pauseSection: RuntimePlayerPauseSection.root,
          actions: _actions(),
          onSelected: (_) {},
          onBackToRoot: () {},
          onTouchMenu: () {},
          activeInputSource: PlayerInputSource.controller,
          detail: const SizedBox.shrink(),
        ),
        textScaler: TextScaler.linear(scale),
        reducedMotion: true,
        keyboardInset: 180,
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(
                const ValueKey<String>(
                  'runtime-pause-touch-menu-opacity',
                ),
              ),
            )
            .duration,
        Duration.zero,
      );
      final targets = find.byKey(
        const ValueKey<String>('player-action-focus-frame'),
      );
      expect(targets, findsWidgets);
      for (final element in targets.evaluate()) {
        expect(
          tester.getSize(find.byElementPredicate((candidate) {
            return identical(candidate, element);
          })).height,
          greaterThanOrEqualTo(48),
        );
      }
    });
  }
}

RuntimePlayerSnapshot _pausedSnapshot({
  required RuntimePlayerPauseSection section,
  required String logicalSelectionId,
}) {
  return RuntimePlayerSnapshot(
    revision: 1,
    phase: RuntimePlayerPhase.paused,
    gameTitle: 'Aube',
    pauseSection: section,
    logicalSelectionId: logicalSelectionId,
    activeInputSource: PlayerInputSource.keyboard,
    actions: <RuntimePlayerActionAvailability>[
      for (final action in RuntimePlayerAction.values)
        RuntimePlayerActionAvailability.enabled(action),
    ],
  );
}

Map<PlayerPauseAction, PlayerActionAvailability> _actions() =>
    <PlayerPauseAction, PlayerActionAvailability>{
      for (final action in PlayerPauseAction.values)
        action: PlayerActionAvailability.enabled,
    };

double _scrollOffset(WidgetTester tester, Finder scrollView) {
  final scrollable = find.descendant(
    of: scrollView,
    matching: find.byType(Scrollable),
  );
  return tester.state<ScrollableState>(scrollable).position.pixels;
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(
  Widget child, {
  TextScaler textScaler = TextScaler.noScaling,
  bool reducedMotion = false,
  double keyboardInset = 0,
}) {
  return MaterialApp(
    locale: const Locale('fr'),
    supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
    localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
    theme: PokeMapPlayerTheme.dark(reducedMotion: reducedMotion),
    builder: (context, child) {
      final media = MediaQuery.of(context).copyWith(
        textScaler: textScaler,
        viewInsets: EdgeInsets.only(bottom: keyboardInset),
      );
      return MediaQuery(
        data: media,
        child: Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: child!,
        ),
      );
    },
    home: child,
  );
}

class _SceneMountProbe extends StatefulWidget {
  const _SceneMountProbe({required this.mounts});

  final ValueNotifier<int> mounts;

  @override
  State<_SceneMountProbe> createState() => _SceneMountProbeState();
}

class _SceneMountProbeState extends State<_SceneMountProbe> {
  @override
  void initState() {
    super.initState();
    widget.mounts.value++;
  }

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Colors.green);
  }
}
