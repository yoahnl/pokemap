import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';

void main() {
  testWidgets('commits one profile after a complete drag', (tester) async {
    final layouts = suggestedProjectPresentationLayouts('standard');
    final previews = <ProjectPresentationLayoutsProfile>[];
    final commits = <ProjectPresentationLayoutsProfile>[];
    await tester.pumpWidget(
      _app(
        PersonalizationLayoutOverlay(
          surface: ProjectPresentationSurfaceRole.pauseMenu,
          breakpoint: ProjectPresentationBreakpoint.regular,
          profile: layouts,
          textScale: 1,
          onPreviewChanged: previews.add,
          onCommitted: commits.add,
          child: const ColoredBox(color: Colors.black),
        ),
      ),
    );

    final gesture = await tester.startGesture(const Offset(80, 200));
    await gesture.moveBy(const Offset(280, 0));
    await gesture.up();
    await tester.pump();

    expect(previews, isNotEmpty);
    expect(commits, hasLength(1));
    expect(
      commits.single.pauseMenu.regular.slot,
      ProjectPresentationLayoutSlot.right,
    );
  });

  testWidgets('escape cancels an in-flight preview without committing', (
    tester,
  ) async {
    final layouts = suggestedProjectPresentationLayouts('standard');
    final previews = <ProjectPresentationLayoutsProfile>[];
    final commits = <ProjectPresentationLayoutsProfile>[];
    await tester.pumpWidget(
      _app(
        PersonalizationLayoutOverlay(
          surface: ProjectPresentationSurfaceRole.pauseMenu,
          breakpoint: ProjectPresentationBreakpoint.regular,
          profile: layouts,
          textScale: 1,
          onPreviewChanged: previews.add,
          onCommitted: commits.add,
          child: const ColoredBox(color: Colors.black),
        ),
      ),
    );

    final gesture = await tester.startGesture(const Offset(80, 200));
    await gesture.moveBy(const Offset(280, 0));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await gesture.cancel();
    await tester.pump();

    expect(previews.last, layouts);
    expect(commits, isEmpty);
  });

  testWidgets('exposes equivalent keyboard layout actions', (tester) async {
    final layouts = suggestedProjectPresentationLayouts('standard');
    final commits = <ProjectPresentationLayoutsProfile>[];
    await tester.pumpWidget(
      _app(
        PersonalizationLayoutOverlay(
          surface: ProjectPresentationSurfaceRole.pauseMenu,
          breakpoint: ProjectPresentationBreakpoint.regular,
          profile: layouts,
          textScale: 1,
          onPreviewChanged: (_) {},
          onCommitted: commits.add,
          child: const ColoredBox(color: Colors.black),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Déplacer à droite'));

    expect(commits, hasLength(1));
    expect(
      commits.single.pauseMenu.regular.slot,
      ProjectPresentationLayoutSlot.right,
    );
    await tester.tap(find.byTooltip('Augmenter la marge'));
    expect(commits, hasLength(2));
    expect(
      commits.last.pauseMenu.regular.screenMargin,
      ProjectPresentationScreenMargin.comfortable,
    );
  });

  testWidgets('ignores drags outside the editable visual target', (
    tester,
  ) async {
    final layouts = suggestedProjectPresentationLayouts('standard');
    final commits = <ProjectPresentationLayoutsProfile>[];
    await tester.pumpWidget(
      _app(
        PersonalizationLayoutOverlay(
          surface: ProjectPresentationSurfaceRole.battleHud,
          breakpoint: ProjectPresentationBreakpoint.regular,
          profile: layouts,
          textScale: 1,
          dragBounds: const Rect.fromLTWH(0, .7, 1, .3),
          onPreviewChanged: (_) {},
          onCommitted: commits.add,
          child: const ColoredBox(color: Colors.black),
        ),
      ),
    );

    final gesture = await tester.startGesture(const Offset(100, 100));
    await gesture.moveBy(const Offset(280, 0));
    await gesture.up();
    await tester.pump();

    expect(commits, isEmpty);
  });
}

Widget _app(Widget child) => MaterialApp(
  theme: ThemeData.dark(),
  home: Scaffold(body: SizedBox(width: 600, height: 400, child: child)),
);
