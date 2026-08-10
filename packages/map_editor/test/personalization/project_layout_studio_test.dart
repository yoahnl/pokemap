import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  testWidgets('offers semantic presets without exposing layout internals', (
    tester,
  ) async {
    ProjectPresentationLayoutsProfile? value;
    await tester.pumpWidget(
      _app(
        ProjectLayoutStudio(
          profile: null,
          brandingLayoutVariant: 'standard',
          onChanged: (next) => value = next,
        ),
      ),
    );

    expect(find.text('Composition responsive'), findsOneWidget);
    expect(find.text('Écran titre'), findsOneWidget);
    expect(find.text('Menu Pause'), findsOneWidget);
    expect(find.text('Dialogue'), findsOneWidget);
    expect(find.text('maxWidthFactor'), findsNothing);
    expect(find.text('safeAreaPadding'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('layout-preset-cinematic')),
    );

    expect(
      value?.title.expanded.slot,
      ProjectPresentationLayoutSlot.bottomLeft,
    );
  });

  testWidgets('edits one surface and responsive size without hiding actions', (
    tester,
  ) async {
    ProjectPresentationLayoutsProfile? value =
        suggestedProjectPresentationLayouts('standard');
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => ProjectLayoutStudio(
            profile: value,
            brandingLayoutVariant: 'standard',
            onChanged: (next) => setState(() => value = next),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('layout-surface-pauseMenu')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('layout-breakpoint-expanded')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('layout-slot-right')));
    await tester.pump();

    expect(value?.pauseMenu.expanded.slot, ProjectPresentationLayoutSlot.right);
    expect(value?.title.expanded.slot, ProjectPresentationLayoutSlot.center);
    expect(find.text('Ordre des actions'), findsNothing);
  });

  testWidgets('reset and 200 percent text scale remain usable', (tester) async {
    tester.view.physicalSize = const Size(720, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    ProjectPresentationLayoutsProfile? value =
        suggestedProjectPresentationLayouts('cinematic');

    await tester.pumpWidget(
      _app(
        ProjectLayoutStudio(
          profile: value,
          brandingLayoutVariant: 'cinematic',
          onChanged: (next) => value = next,
        ),
        textScaler: const TextScaler.linear(2),
      ),
    );

    final reset = find.byKey(const ValueKey<String>('layout-reset-project'));
    await tester.ensureVisible(reset);
    expect(reset.hitTestable(), findsOneWidget);
    await tester.tap(reset);
    expect(value, isNull);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(Widget child, {TextScaler textScaler = TextScaler.noScaling}) =>
    MaterialApp(
      theme: PokeMapTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
