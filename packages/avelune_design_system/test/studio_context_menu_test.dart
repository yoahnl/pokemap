import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens at a global position and runs the selected entry', (
    tester,
  ) async {
    final calls = <String>[];
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => GestureDetector(
            key: const ValueKey('surface'),
            behavior: HitTestBehavior.opaque,
            onSecondaryTapUp: (details) => StudioContextMenu.showAt(
              context,
              position: details.globalPosition,
              items: [
                StudioContextMenuEntry(
                  label: 'Renommer',
                  icon: Icons.edit_outlined,
                  shortcut: 'F2',
                  onSelected: () => calls.add('rename'),
                ),
                const StudioContextMenuSeparator(),
                StudioContextMenuEntry(
                  label: 'Supprimer',
                  destructive: true,
                  onSelected: () => calls.add('delete'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tapAt(const Offset(200, 150), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(find.text('Renommer'), findsOneWidget);
    expect(find.text('F2'), findsOneWidget);
    expect(find.byType(StudioContextMenuSeparatorLine), findsOneWidget);
    final menuTopLeft = tester.getTopLeft(find.byType(StudioContextMenuPanel));
    expect(menuTopLeft.dx, closeTo(200, 1));
    expect(menuTopLeft.dy, closeTo(150, 1));

    await tester.tap(find.text('Renommer'));
    await tester.pumpAndSettle();
    expect(calls, ['rename']);
    expect(find.byType(StudioContextMenuPanel), findsNothing);
  });

  testWidgets('destructive entries use the error color token', (tester) async {
    await _openAt(tester, [
      StudioContextMenuEntry(
        label: 'Supprimer',
        destructive: true,
        onSelected: () {},
      ),
    ]);
    final context = tester.element(find.text('Supprimer'));
    final text = tester.widget<Text>(find.text('Supprimer'));
    expect(text.style?.color, Theme.of(context).colorScheme.error);
  });

  testWidgets('disabled entries explain why and never run', (tester) async {
    var calls = 0;
    await _openAt(tester, [
      StudioContextMenuEntry(
        label: 'Supprimer',
        disabledReason: 'Carte utilisée par Route 29',
        onSelected: () => calls++,
      ),
    ]);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Tooltip &&
            widget.message == 'Carte utilisée par Route 29',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.byType(StudioContextMenuPanel), findsOneWidget);
  });

  testWidgets('arrows skip disabled entries, Enter runs, Escape closes', (
    tester,
  ) async {
    final calls = <String>[];
    final items = [
      StudioContextMenuEntry(label: 'Un', onSelected: () => calls.add('un')),
      const StudioContextMenuSeparator(),
      StudioContextMenuEntry(
        label: 'Deux',
        disabledReason: 'Indisponible',
        onSelected: () => calls.add('deux'),
      ),
      StudioContextMenuEntry(
        label: 'Trois',
        onSelected: () => calls.add('trois'),
      ),
    ];
    await _openAt(tester, items);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(calls, ['trois']);

    await _openAt(tester, items);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(calls, ['trois', 'un']);

    await _openAt(tester, items);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(StudioContextMenuPanel), findsNothing);
    expect(calls, ['trois', 'un']);
  });

  testWidgets('a tap outside closes the menu without running anything', (
    tester,
  ) async {
    var calls = 0;
    await _openAt(tester, [
      StudioContextMenuEntry(label: 'Un', onSelected: () => calls++),
    ]);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byType(StudioContextMenuPanel), findsNothing);
    expect(calls, 0);
  });

  testWidgets('the more button anchors the menu below itself', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _app(
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: StudioContextMenuButton(
              tooltip: 'Actions de la carte',
              items: () => [
                StudioContextMenuEntry(
                  label: 'Dupliquer',
                  onSelected: () => calls++,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final button = find.byTooltip('Actions de la carte');
    await tester.tap(button);
    await tester.pumpAndSettle();
    final buttonRect = tester.getRect(button);
    final menuTopLeft = tester.getTopLeft(find.byType(StudioContextMenuPanel));
    expect(menuTopLeft.dx, closeTo(buttonRect.left, 1));
    expect(menuTopLeft.dy, closeTo(buttonRect.bottom, 1));
    await tester.tap(find.text('Dupliquer'));
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('the menu stays inside the screen near the bottom right edge', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _openAt(tester, [
      StudioContextMenuEntry(label: 'Un', onSelected: () {}),
      StudioContextMenuEntry(label: 'Deux', onSelected: () {}),
    ], position: const Offset(395, 295));
    final rect = tester.getRect(find.byType(StudioContextMenuPanel));
    expect(rect.right, lessThanOrEqualTo(400));
    expect(rect.bottom, lessThanOrEqualTo(300));
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.top, greaterThanOrEqualTo(0));
  });
}

Future<void> _openAt(
  WidgetTester tester,
  List<StudioContextMenuItem> items, {
  Offset position = const Offset(120, 80),
}) async {
  await tester.pumpWidget(
    _app(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => StudioContextMenu.showAt(
            context,
            position: position,
            items: items,
          ),
          child: const Text('ouvrir'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
}

Widget _app(Widget child) => MaterialApp(
  theme: studioTheme(),
  home: Scaffold(body: child),
);
