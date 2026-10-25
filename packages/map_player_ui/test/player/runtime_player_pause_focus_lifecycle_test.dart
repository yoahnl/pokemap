import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('pending restoration cannot replace newer physical focus',
      (tester) async {
    final focus = RuntimePlayerFocusController(logicalSelectionId: 'first');
    addTearDown(focus.dispose);
    final first = focus.nodeFor('first', debugLabel: 'First');
    final second = focus.nodeFor('second', debugLabel: 'Second');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Row(children: [
          TextButton(focusNode: first, onPressed: () {}, child: const Text('First')),
          TextButton(focusNode: second, onPressed: () {}, child: const Text('Second')),
        ]),
      ),
    ));
    first.requestFocus();
    await tester.pumpAndSettle();
    focus.restoreSelection('first');
    second.requestFocus();
    await tester.idle();
    expect(focus.logicalSelectionId, 'second');
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, second);
    expect(focus.logicalSelectionId, 'second');
    expect(tester.takeException(), isNull);
  });

  testWidgets('illustrated detail accepts Escape immediately after opening',
      (tester) async {
    _setSurface(tester, const Size(1440, 900));
    final focus = RuntimePlayerFocusController(
      logicalSelectionId: 'pause.profile',
    );
    addTearDown(focus.dispose);
    var section = RuntimePlayerPauseSection.root;
    var returns = 0;
    await tester.pumpWidget(_app(StatefulBuilder(
      builder: (context, update) => _shell(
        focus: focus,
        section: section,
        logicalSelectionId: 'pause.profile',
        onSelected: (action) {
          if (action == PlayerPauseAction.profile) {
            update(() => section = RuntimePlayerPauseSection.profile);
          }
        },
        onBack: () => update(() {
          returns++;
          section = RuntimePlayerPauseSection.root;
        }),
      ),
    )));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(section, RuntimePlayerPauseSection.profile);
    expect(find.byKey(const ValueKey('pause.profile')), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(returns, 1);
    expect(section, RuntimePlayerPauseSection.root);
    expect(focus.logicalSelectionId, 'pause.profile');
    expect(FocusManager.instance.primaryFocus,
        focus.nodeFor('pause.profile', debugLabel: 'Profile'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared root selection survives remount with a stale snapshot',
      (tester) async {
    _setSurface(tester, const Size(1440, 900));
    final focus = RuntimePlayerFocusController(
      logicalSelectionId: 'pause.profile',
    );
    addTearDown(focus.dispose);
    Widget root() => _app(_shell(
          focus: focus,
          logicalSelectionId: 'pause.profile',
        ));
    await tester.pumpWidget(root());
    await tester.pumpAndSettle();
    focus.select('pause.bag', requestFocus: true);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus,
        focus.nodeFor('pause.bag', debugLabel: 'Bag'));

    await tester.pumpWidget(_app(const SizedBox.shrink()));
    await tester.pumpAndSettle();
    await tester.pumpWidget(root());
    await tester.pumpAndSettle();

    expect(focus.logicalSelectionId, 'pause.bag');
    expect(FocusManager.instance.primaryFocus,
        focus.nodeFor('pause.bag', debugLabel: 'Bag'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('hiding the current root entry focuses the first enabled entry',
      (tester) async {
    _setSurface(tester, const Size(1440, 900));
    final focus = RuntimePlayerFocusController(
      logicalSelectionId: 'pause.profile',
    );
    addTearDown(focus.dispose);
    final selected = <PlayerPauseAction>[];
    await tester.pumpWidget(_app(_shell(
      focus: focus,
      logicalSelectionId: 'pause.profile',
      onSelected: selected.add,
    )));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(_shell(
      focus: focus,
      logicalSelectionId: 'pause.profile',
      presentation: const PlayerPausePresentation(
        style: ProjectPauseMenuStyle.nightIllustrated,
        actionOrder: [
          PlayerPauseAction.party,
          PlayerPauseAction.bag,
          PlayerPauseAction.profile,
        ],
        hiddenActions: {PlayerPauseAction.profile},
      ),
      actions: {
        ..._actions(),
        PlayerPauseAction.party:
            const PlayerActionAvailability.disabled('Équipe indisponible'),
      },
      onSelected: selected.add,
    )));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('pause.profile')), findsNothing);
    expect(focus.logicalSelectionId, 'pause.bag');
    expect(FocusManager.instance.primaryFocus,
        focus.nodeFor('pause.bag', debugLabel: 'Bag'));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(selected, [PlayerPauseAction.bag]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail Menu uses its back callback without selecting Resume',
      (tester) async {
    _setSurface(tester, const Size(1440, 900));
    final focus = RuntimePlayerFocusController(
      logicalSelectionId: 'pause.profile',
    );
    addTearDown(focus.dispose);
    final selected = <PlayerPauseAction>[];
    var returns = 0;
    await tester.pumpWidget(_app(_shell(
      focus: focus,
      section: RuntimePlayerPauseSection.profile,
      logicalSelectionId: 'pause.profile',
      onSelected: selected.add,
      onBack: () => returns++,
      onMenu: () => returns++,
    )));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.pumpAndSettle();
    expect(returns, 1);
    expect(selected, isEmpty);
    expect(focus.logicalSelectionId, 'pause.profile');
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'root navigation restores its selected page and keyboard focus after remount at scale=$scale',
      (tester) async {
        _setSurface(tester, const Size(844, 240));
        final focus = RuntimePlayerFocusController(
          logicalSelectionId: 'pause.bag',
          activeInputSource: PlayerInputSource.touch,
        );
        addTearDown(focus.dispose);
        Widget root() => _app(_shell(focus: focus), scale: scale);
        await tester.pumpWidget(root());
        await tester.pumpAndSettle();
        final options = find.byKey(const ValueKey('pause.options'));
        for (
          var page = 0;
          page < 20 && options.hitTestable().evaluate().isEmpty;
          page++
        ) {
          final next = find.descendant(
            of: find.byType(PlayerPauseNavigation),
            matching: find.byKey(const ValueKey('player-page-next')),
          ).hitTestable();
          expect(next, findsOneWidget);
          expect(tester.widget<IconButton>(next).onPressed, isNotNull);
          await tester.tap(next);
          await tester.pumpAndSettle();
        }
        expect(options.hitTestable(), findsOneWidget);
        await tester.tap(options);
        await tester.pumpAndSettle();
        final before = tester.getRect(options);
        expect(focus.logicalSelectionId, 'pause.options');
        expect(find.byType(Scrollable), findsNothing);

        focus.noteInputSource(PlayerInputSource.keyboard);
        focus.select('pause.options', requestFocus: true);
        await tester.pumpAndSettle();
        expect(
          FocusManager.instance.primaryFocus,
          focus.nodeFor('pause.options', debugLabel: 'Options'),
        );
        await tester.pumpWidget(_app(const SizedBox.shrink()));
        await tester.pumpAndSettle();
        await tester.pumpWidget(root());
        await tester.pumpAndSettle();
        expect(options.hitTestable(), findsOneWidget);
        expect(tester.getRect(options), before);
        expect(focus.logicalSelectionId, 'pause.options');
        expect(
          FocusManager.instance.primaryFocus,
          focus.nodeFor('pause.options', debugLabel: 'Options'),
        );
        final body = tester.getRect(
          find.byKey(const ValueKey('player-paged-body')),
        );
        expect(body.height, greaterThanOrEqualTo(48));
        expect(before.height, greaterThanOrEqualTo(48));
        expect(before.top, greaterThanOrEqualTo(body.top));
        expect(before.bottom, lessThanOrEqualTo(body.bottom));
        expect(find.byType(Scrollable), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

RuntimePlayerPauseShell _shell({
  required RuntimePlayerFocusController focus,
  RuntimePlayerPauseSection section = RuntimePlayerPauseSection.root,
  String? logicalSelectionId,
  Map<PlayerPauseAction, PlayerActionAvailability>? actions,
  PlayerPausePresentation presentation = const PlayerPausePresentation(
    style: ProjectPauseMenuStyle.nightIllustrated,
  ),
  ValueChanged<PlayerPauseAction>? onSelected,
  VoidCallback? onBack,
  VoidCallback? onMenu,
}) =>
    RuntimePlayerPauseShell(
      gameTitle: 'Le Train de 17h42',
      pauseSection: section,
      actions: actions ?? _actions(),
      onSelected: onSelected ?? (_) {},
      onBackToRoot: onBack ?? () {},
      onTouchMenu: onMenu,
      detail: const Text('Détails du joueur'),
      presentation: presentation,
      focusController: focus,
      logicalSelectionId: logicalSelectionId,
    );

Map<PlayerPauseAction, PlayerActionAvailability> _actions() => {
      for (final action in PlayerPauseAction.values)
        action: PlayerActionAvailability.enabled,
    };

void _setSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(Widget child, {double scale = 1}) => MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(reducedMotion: true),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: child,
    );
