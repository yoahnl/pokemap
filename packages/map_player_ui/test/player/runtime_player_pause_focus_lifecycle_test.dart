import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
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

  testWidgets('root navigation scroll and selection survive a pause remount',
      (tester) async {
    _setSurface(tester, const Size(844, 390));
    final focus = RuntimePlayerFocusController(
      logicalSelectionId: 'pause.bag',
      activeInputSource: PlayerInputSource.touch,
    );
    addTearDown(focus.dispose);
    Widget root() => _app(_shell(focus: focus));
    await tester.pumpWidget(root());
    await tester.pumpAndSettle();
    final before = tester
        .widget<Scrollbar>(
          find.byKey(const ValueKey('runtime-pause-navigation-scrollbar')),
        )
        .controller!;
    expect(before.position.maxScrollExtent, greaterThan(96));
    before.jumpTo(96);
    await tester.pumpAndSettle();

    await tester.pumpWidget(_app(const SizedBox.shrink()));
    await tester.pumpAndSettle();
    await tester.pumpWidget(root());
    await tester.pumpAndSettle();
    final after = tester
        .widget<Scrollbar>(
          find.byKey(const ValueKey('runtime-pause-navigation-scrollbar')),
        )
        .controller!;

    expect(after.offset, closeTo(96, .01));
    expect(focus.logicalSelectionId, 'pause.bag');
    expect(tester.takeException(), isNull);
  });
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

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(reducedMotion: true),
      home: child,
    );
