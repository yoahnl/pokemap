import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/presentation/features/home/studio_home_frame.dart';
import 'package:avelune_studio/presentation/shell/studio_rail.dart';
import 'package:avelune_studio/presentation/shell/studio_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsProperties;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shared navigation and brand at desktop and small window sizes', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 838);
    addTearDown(tester.view.reset);
    final search = TextEditingController();
    addTearDown(search.dispose);
    Future<void> show(Widget body) => tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(body: body),
      ),
    );
    Finder asset(String path) => find.byWidgetPredicate(
      (widget) => widget is Image && widget.image == AssetImage(path),
    );
    final symbol = asset('assets/home/avelune_symbol.png');
    final wordmark = asset('assets/home/avelune_logo.png');
    const rail = ValueKey('studio-rail');
    const home = ValueKey('studio-rail-home');
    const map = ValueKey('studio-rail-map');
    const resources = ValueKey('studio-rail-resources');
    final close = find.byKey(const ValueKey('studio-project-home-close'));
    Rect bounds(ValueKey<String> key) => tester.getRect(find.byKey(key));
    SemanticsProperties railEntry(ValueKey<String> key) => tester
        .widget<Semantics>(
          find.descendant(
            of: find.byKey(key),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics && widget.properties.selected != null,
            ),
          ),
        )
        .properties;
    await show(
      const Column(
        children: [
          StudioTopBar(
            projectName: 'Projet de contrôle',
            maps: [],
            activeMapId: null,
            onSelectMap: null,
            onUndo: null,
            onRedo: null,
            saveState: StudioSaveState.saved,
            onSave: null,
            onTestMap: null,
          ),
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: StudioRail()),
          ),
        ],
      ),
    );
    final editorRail = bounds(rail);
    final editorHome = bounds(home);
    final editorMap = bounds(map);
    final editorSymbol = tester.getRect(symbol);
    final editorWordmark = tester.getRect(wordmark);
    expect(editorWordmark.size, const Size(184, 54));
    expect(railEntry(map).selected, isTrue);
    var maps = 0;
    var closes = 0;
    Widget dashboard(bool busy) => StudioHomeFrame(
      projectName: 'Projet de contrôle',
      busy: busy,
      search: search,
      onSearch: (_) {},
      destinations: {'map': () => maps++},
      onClose: () => closes++,
      child: const SizedBox.expand(),
    );
    await show(dashboard(false));
    expect(bounds(rail), editorRail);
    expect(bounds(home), editorHome);
    expect(bounds(map), editorMap);
    expect(railEntry(home).selected, isTrue);
    expect(railEntry(map).selected, isFalse);
    expect(tester.getSize(symbol), editorSymbol.size);
    expect(tester.getSize(wordmark), editorWordmark.size);
    expect(railEntry(resources).enabled, isFalse);
    await tester.tap(find.byKey(map));
    await tester.tap(close);
    expect((maps, closes), (1, 1));
    await show(dashboard(true));
    expect(railEntry(map).enabled, isFalse);
    expect(tester.widget<StudioTool>(close).onPressed, isNull);
    tester.view.physicalSize = const Size(480, 360);
    await show(dashboard(false));
    expect(symbol, findsOneWidget);
    expect(wordmark, findsNothing);
    expect(close.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
