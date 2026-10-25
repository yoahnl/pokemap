import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';

Future<void> _mount(
  WidgetTester tester, {
  required ValueChanged<int> onPageChanged,
  VoidCallback? onActivate,
  VoidCallback? onOuterDrag,
  ValueChanged<double>? onContentHeightChanged,
  bool reducedMotion = false,
  int initialPage = 0,
  Widget? first,
  FocusNode? secondFocus,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapPlayerTheme.light(reducedMotion: reducedMotion),
      home: Scaffold(
        body: GestureDetector(
          onPanEnd: (_) => onOuterDrag?.call(),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 320,
              height: 220,
              child: Focus(
                autofocus: true,
                child: PlayerMenuThemeScope(
                  child: PlayerPagedList(
                    initialPage: initialPage,
                    onPageChanged: onPageChanged,
                    onContentHeightChanged: onContentHeightChanged,
                    children: [
                      SizedBox(
                        key: const ValueKey('first-row'),
                        height: 90,
                        child:
                            first ??
                            TextButton(
                              onPressed: onActivate,
                              child: const Text('First'),
                            ),
                      ),
                      SizedBox(
                        key: const ValueKey('second-row'),
                        height: 90,
                        child: TextButton(
                          focusNode: secondFocus,
                          onPressed: onActivate,
                          child: const Text('Second'),
                        ),
                      ),
                      const SizedBox(
                        key: ValueKey('third-row'),
                        height: 90,
                        child: Text('Third'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'horizontal drag changes one page without activating or bubbling',
    (tester) async {
      final pages = <int>[];
      var activations = 0;
      var outerDrags = 0;
      await _mount(
        tester,
        onPageChanged: pages.add,
        onActivate: () => activations++,
        onOuterDrag: () => outerDrags++,
      );
      await tester.drag(find.text('First'), const Offset(-250, 3));
      await tester.pumpAndSettle();
      expect(pages, [1]);
      expect(find.text('Second'), findsOneWidget);
      expect(activations, 0);
      expect(outerDrags, 0);
      expect(find.byType(Scrollable), findsNothing);
      await tester.drag(find.text('Second'), const Offset(200, 0));
      await tester.pumpAndSettle();
      expect(pages, [1, 0]);
      expect(find.text('First'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final displacement in [
    const Offset(-90, 95),
    const Offset(0, -90),
    const Offset(-30, 0),
  ]) {
    testWidgets('rejects vertical diagonal and short gestures $displacement', (
      tester,
    ) async {
      final pages = <int>[];
      await _mount(tester, onPageChanged: pages.add, onActivate: () {});
      await tester.drag(find.text('First'), displacement);
      await tester.pumpAndSettle();
      expect(pages, isEmpty);
      expect(find.text('First'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('tap still activates once and does not turn the page', (
    tester,
  ) async {
    final pages = <int>[];
    var activations = 0;
    await _mount(
      tester,
      onPageChanged: pages.add,
      onActivate: () => activations++,
    );
    await tester.tap(find.text('First'));
    await tester.pumpAndSettle();
    expect(activations, 1);
    expect(pages, isEmpty);
  });

  testWidgets(
    'cancel reversal and initially vertical gesture never turn pages',
    (tester) async {
      final pages = <int>[];
      await _mount(tester, onPageChanged: pages.add, onActivate: () {});
      final origin = tester.getCenter(find.text('First'));
      final cancelled = await tester.startGesture(origin);
      await cancelled.moveBy(const Offset(-90, 0));
      await cancelled.cancel();
      await tester.pumpAndSettle();
      expect(pages, isEmpty, reason: 'PointerCancel must not commit.');
      final reversed = await tester.startGesture(origin);
      await reversed.moveBy(const Offset(-100, 0));
      await reversed.moveBy(const Offset(40, 0));
      await reversed.up();
      await tester.pumpAndSettle();
      expect(pages, isEmpty, reason: 'A reversed drag must not commit.');
      final vertical = await tester.startGesture(origin);
      await vertical.moveBy(const Offset(0, 25));
      await vertical.moveBy(const Offset(-130, 0));
      await vertical.up();
      await tester.pumpAndSettle();
      expect(pages, isEmpty);
      expect(find.text('First'), findsOneWidget);
    },
  );

  testWidgets('page boundaries do not emit commands or wrap', (tester) async {
    final pages = <int>[];
    await _mount(tester, onPageChanged: pages.add, onActivate: () {});
    await tester.drag(find.text('First'), const Offset(160, 0));
    await tester.pumpAndSettle();
    expect(pages, isEmpty);
    await tester.drag(find.text('First'), const Offset(-160, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.text('Second'), const Offset(-160, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.text('Third'), const Offset(-160, 0));
    await tester.pumpAndSettle();
    expect(pages, [1, 2]);
    expect(find.text('Page 3 / 3'), findsOneWidget);
  });

  for (final rowCount in [1, 3]) {
    testWidgets(
      'nested pager owns its pages before the tab swipe rowCount=$rowCount',
      (tester) async {
        final pages = <int>[];
        var tabs = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: PlayerHorizontalSwipeRegion(
                  onNext: () => tabs++,
                  child: SizedBox(
                    width: 320,
                    height: 220,
                    child: PlayerMenuThemeScope(
                      child: PlayerPagedList(
                        onPageChanged: pages.add,
                        children: [
                          for (var index = 0; index < rowCount; index++)
                            SizedBox(height: 90, child: Text('Row $index')),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.drag(find.text('Row 0'), const Offset(-130, 0));
        await tester.pumpAndSettle();
        expect(pages, rowCount > 1 ? [1] : isEmpty);
        expect(tabs, rowCount > 1 ? 0 : 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('external tab selection invalidates the shared swipe region', (
    tester,
  ) async {
    final revision = ValueNotifier(0);
    addTearDown(revision.dispose);
    var commands = 0;
    final feedback = <double>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: ValueListenableBuilder(
              valueListenable: revision,
              builder: (context, value, _) => PlayerHorizontalSwipeRegion(
                resetToken: value,
                onNext: () => commands++,
                onDragChanged: feedback.add,
                child: const SizedBox(
                  width: 320,
                  height: 220,
                  child: Text('Tab body'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Tab body')),
    );
    await gesture.moveBy(const Offset(-90, 0));
    revision.value++;
    await tester.pump();
    await gesture.moveBy(const Offset(-40, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(commands, 0);
    expect(feedback.last, 0);
  });

  testWidgets('text editing owns drag and page keys', (tester) async {
    final pages = <int>[];
    final controller = TextEditingController(text: 'Editable response');
    addTearDown(controller.dispose);
    await _mount(
      tester,
      onPageChanged: pages.add,
      first: TextField(controller: controller),
    );
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    final editable = find.byType(EditableText);
    expect(tester.widget<EditableText>(editable).focusNode.hasFocus, isTrue);
    final gesture = await tester.startGesture(
      tester.getTopLeft(editable) + const Offset(20, 8),
    );
    await gesture.moveBy(const Offset(-90, 0));
    await gesture.up();
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();
    expect(pages, isEmpty);
    expect(controller.text, 'Editable response');
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('navigation buttons and page keys share the swipe command', (
    tester,
  ) async {
    final pages = <int>[];
    await _mount(tester, onPageChanged: pages.add, onActivate: () {});
    await tester.tap(find.byKey(const ValueKey('player-page-next')));
    await tester.pumpAndSettle();
    final nextFocus = Focus.of(
      tester.element(find.byIcon(Icons.chevron_right)),
    );
    nextFocus.requestFocus();
    await tester.pump();
    expect(nextFocus.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();
    final previousFocus = Focus.of(
      tester.element(find.byIcon(Icons.chevron_left)),
    );
    previousFocus.requestFocus();
    await tester.pump();
    expect(previousFocus.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
    await tester.pumpAndSettle();
    expect(pages, [1, 2, 1]);
    expect(find.text('Second'), findsOneWidget);
  });

  testWidgets('a resize during a drag invalidates its pending page command', (
    tester,
  ) async {
    final pages = <int>[];
    addTearDown(tester.view.reset);
    await _mount(tester, onPageChanged: pages.add, onActivate: () {});
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('First')),
    );
    await gesture.moveBy(const Offset(-60, 0));
    tester.view.physicalSize = const Size(250, 600);
    tester.view.devicePixelRatio = 1;
    await tester.pumpAndSettle();
    await gesture.moveBy(const Offset(-60, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(pages, isEmpty);
    expect(find.text('First'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final reduced in [false, true]) {
    testWidgets(
      'drag feedback is bounded and cancellation restores position reduced=$reduced',
      (tester) async {
        final pages = <int>[];
        await _mount(
          tester,
          onPageChanged: pages.add,
          onActivate: () {},
          reducedMotion: reduced,
        );
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('First')),
        );
        await gesture.moveBy(const Offset(-120, 0));
        await tester.pump();
        final transform = find.byKey(const ValueKey('player-page-transition'));
        final offset = tester
            .widget<Transform>(transform)
            .transform
            .getTranslation()
            .x;
        expect(offset, reduced ? 0 : -14);
        expect(pages, isEmpty);
        await gesture.cancel();
        await tester.pumpAndSettle();
        expect(
          tester.widget<Transform>(transform).transform.getTranslation().x,
          0,
        );
        expect(pages, isEmpty);
        expect(find.text('First'), findsOneWidget);
      },
    );
  }

  for (final reduced in [false, true]) {
    testWidgets(
      'page motion respects reduced=$reduced and keeps measurement focus and ids',
      (tester) async {
        final pages = <int>[];
        final heights = <double>[];
        final focus = FocusNode();
        addTearDown(focus.dispose);
        await _mount(
          tester,
          onPageChanged: pages.add,
          onContentHeightChanged: heights.add,
          reducedMotion: reduced,
          onActivate: () {},
          secondFocus: focus,
        );
        expect(heights, [286]);
        final first = tester.element(find.byKey(const ValueKey('first-row')));
        await tester.drag(find.text('First'), const Offset(-160, 0));
        await tester.pump();
        final transform = find.byKey(const ValueKey('player-page-transition'));
        final translation = tester
            .widget<Transform>(transform)
            .transform
            .getTranslation()
            .x;
        expect(translation, reduced ? 0 : greaterThan(0));
        focus.requestFocus();
        await tester.pump(const Duration(milliseconds: 90));
        expect(focus.hasFocus, isTrue);
        await tester.pumpAndSettle();
        expect(pages, [1]);
        expect(heights, [286]);
        expect(
          tester.element(
            find.byKey(const ValueKey('first-row'), skipOffstage: false),
          ),
          same(first),
        );
        expect(find.text('Second'), findsOneWidget);
        expect(
          tester.widget<Transform>(transform).transform.getTranslation().x,
          0,
        );
        expect(focus.hasFocus, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
