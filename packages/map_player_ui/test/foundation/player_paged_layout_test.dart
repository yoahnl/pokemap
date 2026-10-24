import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
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
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapPlayerTheme.dark(),
          home: PlayerMenuThemeScope(
            child: PlayerMenuFrame(
              scrollable: false,
              header: const PlayerMenuHeader(icon: Icons.menu, title: 'Menu'),
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
    'rebuilding the same keyed rows keeps the active control focused',
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
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isTrue);
      expect(find.text('Option 1'), findsOneWidget);
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
  for (final (height, atomHeight) in [(110.0, 82.0), (156.0, 128.0)]) {
    testWidgets(
      'side navigation keeps tall atoms and forty-eight pixel controls at height $height',
      (tester) async {
        final widths = <double>{};
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 640,
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
        expect(widths, {584.0});
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
