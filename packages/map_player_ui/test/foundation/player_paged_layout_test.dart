import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  for (final (height, scale, sideNavigation) in [
    for (final height in [48.0, 84.0])
      for (final scale in [1.0, 2.0])
        for (final sideNavigation in [false, true])
          (height, scale, sideNavigation),
  ]) {
    testWidgets(
      'compact pagination preserves 48 pixel targets at $height scale=$scale side=$sideNavigation',
      (tester) async {
        final selected = <int>[];
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 320,
                  height: height,
                  child: PlayerPagedList(
                    sideNavigation: sideNavigation,
                    children: [
                      for (var index = 0; index < 4; index++)
                        SizedBox(
                          height: 48,
                          child: TextButton(
                            onPressed: () => selected.add(index),
                            child: Text('Action $index'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (var index = 0; index < 4; index++) {
          final action = find.widgetWithText(TextButton, 'Action $index');
          expect(action.hitTestable(), findsOneWidget);
          final actionBounds = tester.getRect(action);
          expect(actionBounds.height, 48);
          expect(actionBounds.bottom, lessThanOrEqualTo(height));
          await tester.tap(action);
          for (final key in ['player-page-previous', 'player-page-next']) {
            final bounds = tester.getRect(find.byKey(ValueKey(key)));
            expect(bounds.size, const Size(48, 48));
            expect(bounds.top, greaterThanOrEqualTo(0));
            expect(bounds.bottom, lessThanOrEqualTo(height));
            expect(bounds.overlaps(actionBounds), isFalse);
          }
          if (index < 3) {
            await tester.tap(find.byKey(const ValueKey('player-page-next')));
            await tester.pumpAndSettle();
          }
        }
        expect(selected, [0, 1, 2, 3]);
        expect(find.byType(Scrollable), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'reports measured content including gaps without repeated frames',
    (tester) async {
      final heights = <double>[];
      var spacing = 8.0;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Center(
                child: SizedBox(
                  width: 320,
                  height: 140,
                  child: PlayerPagedList(
                    spacing: spacing,
                    onContentHeightChanged: heights.add,
                    children: const [
                      SizedBox(height: 40, child: Text('Premier contenu')),
                      SizedBox(height: 50, child: Text('Second contenu')),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      expect(heights, isEmpty);
      await tester.pumpAndSettle();
      expect(heights, [98]);
      await tester.pump();
      await tester.pump();
      expect(heights, [98]);
      update(() => spacing = 16);
      await tester.pumpAndSettle();
      expect(heights, [98, 106]);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(768, 432),
    const Size(496, 432),
    const Size(1440, 900),
  ]) {
    testWidgets('anchored actions retain clear margins at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var returns = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapPlayerTheme.dark(),
          home: PlayerMenuThemeScope(
            child: PlayerMenuFrame(
              scrollable: false,
              header: PlayerMenuHeader(
                icon: Icons.menu,
                title: 'Menu',
                onBack: () => returns++,
              ),
              footer: PlayerMenuFooter(
                hints: const [],
                returnAction: PlayerMenuSelectableRow(
                  key: const ValueKey('margin-return'),
                  id: 'margin-return',
                  label: 'Retour',
                  onPressed: () {},
                ),
              ),
              child: const SizedBox.expand(key: ValueKey('margin-body')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final body = tester.getRect(find.byKey(const ValueKey('margin-body')));
      final action = tester.getRect(
        find.byKey(const ValueKey('margin-return-surface')),
      );
      expect(action.top - body.bottom, greaterThanOrEqualTo(16));
      expect(size.height - action.bottom, greaterThanOrEqualTo(16));
      expect(action.height, greaterThanOrEqualTo(48));
      expect(action.width, lessThanOrEqualTo(168));
      expect(action.left, lessThan(size.width / 2));
      if (size.shortestSide < 600) {
        expect(
          find.byKey(const ValueKey('player-menu-frame-panel')),
          findsNothing,
        );
        expect(
          tester.getRect(
            find.byKey(const ValueKey('player-menu-edge-to-edge')),
          ),
          Offset.zero & size,
        );
        final back = find.byType(PlayerMenuBackButton);
        expect(tester.getSize(back), const Size(48, 48));
        await tester.tap(back);
        expect(returns, 1);
      } else {
        expect(
          find.byKey(const ValueKey('player-menu-frame-panel')),
          findsOneWidget,
        );
      }
      expect(find.byType(Scrollable), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('pages measured rows without scroll or unreachable controls', (
    tester,
  ) async {
    var activations = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 320,
              height: 220,
              child: PlayerPagedList(
                children: [
                  for (var i = 0; i < 4; i++)
                    SizedBox(
                      height: 90,
                      child: TextButton(
                        onPressed: () => activations++,
                        child: Text('Action $i'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Scrollable), findsNothing);
    expect(find.text('Action 0'), findsOneWidget);
    expect(find.text('Action 1'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('player-page-next')));
    await tester.pumpAndSettle();
    expect(find.text('Action 1'), findsOneWidget);
    await tester.tap(find.text('Action 1'));
    expect(activations, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resizing keeps row state and returns content without a pager', (
    tester,
  ) async {
    final size = ValueNotifier(const Size(320, 200));
    addTearDown(size.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: size,
            builder: (context, extent, _) => Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: extent.width,
                height: extent.height,
                child: const PlayerPagedList(
                  children: [
                    SizedBox(height: 90, child: Text('Premier')),
                    SizedBox(height: 90, child: Text('Second')),
                    SizedBox(height: 90, child: Text('Troisième')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('player-page-next')));
    await tester.pumpAndSettle();
    size.value = const Size(400, 500);
    await tester.pumpAndSettle();
    expect(find.text('Premier'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    expect(find.text('Troisième'), findsOneWidget);
    expect(find.byKey(const ValueKey('player-page-next')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'rebuilding the same keyed rows keeps content visible and focused in one frame',
    (tester) async {
      final revision = ValueNotifier(0);
      final focus = FocusNode(debugLabel: 'Stable option');
      addTearDown(revision.dispose);
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 220,
              child: ValueListenableBuilder(
                valueListenable: revision,
                builder: (context, value, _) => PlayerPagedList(
                  children: [
                    SizedBox(
                      key: const ValueKey('stable-option'),
                      height: 80,
                      child: TextButton(
                        focusNode: focus,
                        onPressed: () => revision.value++,
                        child: Text('Option $value'),
                      ),
                    ),
                    const SizedBox(
                      key: ValueKey('other-option'),
                      height: 80,
                      child: Text('Autre option'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      focus.requestFocus();
      await tester.pump();
      expect(focus.hasFocus, isTrue);
      revision.value++;
      await tester.pump();
      expect(focus.hasFocus, isTrue);
      expect(
        find.widgetWithText(TextButton, 'Option 1').hitTestable(),
        findsOneWidget,
      );
      expect(find.text('Autre option').hitTestable(), findsOneWidget);
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isTrue);
      expect(find.text('Option 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'reordering keyed rows preserves visible content and measured heights',
    (tester) async {
      final arrangement = ValueNotifier((false, 48.0));
      final heights = <double>[];
      addTearDown(arrangement.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 320,
                height: 220,
                child: ValueListenableBuilder(
                  valueListenable: arrangement,
                  builder: (context, value, _) {
                    final rows = [
                      SizedBox(
                        key: const ValueKey('large-keyed-row'),
                        height: 150,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Grand contenu'),
                        ),
                      ),
                      SizedBox(
                        key: const ValueKey('small-keyed-row'),
                        height: value.$2,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Petit contenu'),
                        ),
                      ),
                    ];
                    return PlayerPagedList(
                      onContentHeightChanged: heights.add,
                      children: value.$1 ? rows.reversed.toList() : rows,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(heights, [206]);
      arrangement.value = (true, 48);
      await tester.pump();
      expect(find.text('Grand contenu').hitTestable(), findsOneWidget);
      expect(find.text('Petit contenu').hitTestable(), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Petit contenu')).dy,
        lessThan(tester.getTopLeft(find.text('Grand contenu')).dy),
      );
      await tester.pumpAndSettle();
      expect(heights, [206]);
      arrangement.value = (true, 100);
      await tester.pumpAndSettle();
      expect(heights.last, 258);
      expect(find.text('Petit contenu').hitTestable(), findsOneWidget);
      expect(find.text('Grand contenu'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('player-page-next')));
      await tester.pumpAndSettle();
      expect(find.text('Grand contenu').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'keyed text remeasures after width theme and text scale changes',
    (tester) async {
      const label = 'Une option au texte adaptable';
      var width = 320.0;
      var fontSize = 14.0;
      var textScale = 1.0;
      final heights = <double>[];
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return Theme(
                  data: ThemeData(
                    textTheme: TextTheme(
                      bodyMedium: TextStyle(fontSize: fontSize, height: 1),
                    ),
                  ),
                  child: MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(textScale)),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: width,
                        height: 500,
                        child: PlayerPagedList(
                          onContentHeightChanged: heights.add,
                          children: [
                            Builder(
                              key: const ValueKey('responsive-keyed-text'),
                              builder: (context) => Text(
                                label,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(
                              key: ValueKey('responsive-keyed-end'),
                              height: 48,
                              child: Text('Fin'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      var previous = heights.last;
      for (final change in <VoidCallback>[
        () => width = 160,
        () => fontSize = 20,
        () => textScale = 2,
      ]) {
        update(change);
        await tester.pumpAndSettle();
        expect(heights.last, greaterThan(previous));
        expect(
          heights.last,
          closeTo(tester.getSize(find.text(label)).height + 56, .5),
        );
        previous = heights.last;
      }
      update(() => width = 320);
      await tester.pumpAndSettle();
      expect(heights.last, lessThan(previous));
      expect(find.text('Fin').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'growing keyed content remeasures before painting and preserves focus',
    (tester) async {
      final expanded = ValueNotifier(false);
      final focus = FocusNode();
      addTearDown(expanded.dispose);
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 320,
                height: 220,
                child: ValueListenableBuilder(
                  valueListenable: expanded,
                  builder: (context, value, _) => PlayerPagedList(
                    children: [
                      SizedBox(
                        key: const ValueKey('growing-row'),
                        height: value ? 150 : 80,
                        child: TextButton(
                          focusNode: focus,
                          onPressed: () {},
                          child: const Text('Premier'),
                        ),
                      ),
                      const SizedBox(
                        key: ValueKey('second-row'),
                        height: 80,
                        child: Text('Second'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      focus.requestFocus();
      await tester.pump();
      expanded.value = true;
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(focus.hasFocus, isTrue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(focus.hasFocus, isTrue);
      expect(find.text('Premier'), findsOneWidget);
      expect(find.text('Second'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('player-page-next')));
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsOneWidget);
      expect(find.byType(Scrollable), findsNothing);
    },
  );

  testWidgets(
    'remeasurement preserves the second page while estimates fit one page',
    (tester) async {
      final revision = ValueNotifier(0);
      addTearDown(revision.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 320,
                height: 220,
                child: ValueListenableBuilder(
                  valueListenable: revision,
                  builder: (context, value, _) => PlayerPagedList(
                    children: [
                      const SizedBox(
                        key: ValueKey('first-row'),
                        height: 150,
                        child: Text('Premier'),
                      ),
                      SizedBox(
                        key: const ValueKey('second-row'),
                        height: 80,
                        child: Text('Second $value'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('player-page-next')));
      await tester.pumpAndSettle();
      expect(find.text('Second 0'), findsOneWidget);
      revision.value++;
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(find.text('Second 1'), findsOneWidget);
      expect(find.text('Premier'), findsNothing);
      expect(find.text('Page 2 / 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'resizing reveals the selected keyed row after page boundaries change',
    (tester) async {
      final height = ValueNotifier(500.0);
      addTearDown(height.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: ValueListenableBuilder(
                valueListenable: height,
                builder: (context, value, _) => SizedBox(
                  width: 320,
                  height: value,
                  child: const PlayerPagedList(
                    revealChildKey: ValueKey('selected-row'),
                    children: [
                      SizedBox(
                        key: ValueKey('first-row'),
                        height: 90,
                        child: Text('Premier'),
                      ),
                      SizedBox(
                        key: ValueKey('second-row'),
                        height: 90,
                        child: Text('Second'),
                      ),
                      SizedBox(
                        key: ValueKey('selected-row'),
                        height: 90,
                        child: Text('Sélection'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Premier'), findsOneWidget);
      height.value = 220;
      await tester.pumpAndSettle();
      expect(find.text('Sélection'), findsOneWidget);
      expect(find.text('Premier'), findsNothing);
      expect(find.text('Page 3 / 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'keeps an unanchored page when status content reduces its height',
    (tester) async {
      final availableHeight = ValueNotifier(250.0);
      addTearDown(availableHeight.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: ValueListenableBuilder<double>(
                valueListenable: availableHeight,
                builder: (context, height, _) => SizedBox(
                  width: 320,
                  height: height,
                  child: const PlayerPagedList(
                    children: [
                      SizedBox(height: 140, child: Text('Première page')),
                      SizedBox(height: 140, child: Text('Réglage actif')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('player-page-next')));
      await tester.pumpAndSettle();
      availableHeight.value = 220;
      await tester.pumpAndSettle();
      expect(find.text('Réglage actif').hitTestable(), findsOneWidget);
      expect(find.text('Première page'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keeps the selected atom visible after earlier content grows', (
    tester,
  ) async {
    final leadingHeight = ValueNotifier(40.0);
    addTearDown(leadingHeight.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 320,
              height: 220,
              child: PlayerPagedList(
                revealChildKey: const ValueKey('selected-action'),
                children: [
                  ValueListenableBuilder<double>(
                    key: const ValueKey('late-image'),
                    valueListenable: leadingHeight,
                    builder: (context, height, _) => SizedBox(
                      height: height,
                      child: const Text('Illustration'),
                    ),
                  ),
                  const SizedBox(
                    key: ValueKey('selected-action'),
                    height: 60,
                    child: Text('Nouvelle partie'),
                  ),
                  const SizedBox(height: 90, child: Text('Options')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nouvelle partie').hitTestable(), findsOneWidget);
    leadingHeight.value = 140;
    await tester.pumpAndSettle();
    expect(find.text('Nouvelle partie').hitTestable(), findsOneWidget);
    expect(find.text('Illustration'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('player-page-previous')));
    await tester.pumpAndSettle();
    leadingHeight.value = 150;
    await tester.pumpAndSettle();
    expect(find.text('Illustration').hitTestable(), findsOneWidget);
    expect(find.text('Nouvelle partie'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final (width, height, atomHeight) in [
    (640.0, 110.0, 82.0),
    (640.0, 156.0, 128.0),
    (206.0, 124.0, 71.0),
  ]) {
    testWidgets(
      'side navigation keeps tall atoms and forty-eight pixel controls at $width x $height',
      (tester) async {
        final widths = <double>{};
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: PlayerPagedList(
                    sideNavigation: true,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          widths.add(constraints.maxWidth);
                          return SizedBox(
                            height: atomHeight,
                            child: Text('Retourner au titre ?'),
                          );
                        },
                      ),
                      SizedBox(height: 80, child: Text('Décision suivante')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(widths, {width - 56});
        expect(find.text('Retourner au titre ?'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final body = tester.getRect(
          find.byKey(const ValueKey('player-paged-body')),
        );
        for (final key in ['player-page-previous', 'player-page-next']) {
          final rect = tester.getRect(find.byKey(ValueKey(key)));
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
          expect(rect.left - body.right, greaterThanOrEqualTo(8));
          expect(rect.bottom, lessThanOrEqualTo(height));
        }
        await tester.tap(find.byKey(const ValueKey('player-page-next')));
        await tester.pumpAndSettle();
        expect(find.text('Décision suivante'), findsOneWidget);
        expect(find.byType(Scrollable), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
