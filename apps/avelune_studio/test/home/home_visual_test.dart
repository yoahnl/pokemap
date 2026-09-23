import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/features/home/domain/recent_studio_project.dart';
import 'package:avelune_studio/presentation/features/home/studio_home_screen.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';

void main() {
  for (final size in [
    const Size(1536, 1024),
    const Size(1440, 900),
    const Size(1280, 800),
    const Size(1024, 640),
    const Size(480, 360),
  ]) {
    testWidgets('home fits $size with real layout and local search', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(loadDesktopCaptureFonts);
      final key = GlobalKey();
      final routes = <String>[];
      var picked = 0;
      var resumed = 0;
      var active = true;
      Widget app() => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: studioTheme(),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(size.width == 1024 ? 1.5 : 1),
          ),
          child: RepaintBoundary(
            key: key,
            child: StudioHomeScreen(
              projectName: active ? 'Démonstration UI01' : null,
              projectPath: active ? '/tmp/avelune-ui01-demo' : null,
              onOpen: () => picked++,
              onResume: active ? () => resumed++ : null,
              onExport: active ? () => routes.add('gameExport') : null,
              canTest: active,
              onDestination: routes.add,
              recentProjects: active
                  ? [
                      for (final name in [
                        'Démonstration UI01',
                        'Village de test',
                        'Île de test',
                      ])
                        RecentStudioProject(
                          name: name,
                          directoryPath: '/tmp/$name',
                          lastOpenedAt: DateTime(2026, 9, 19, 18),
                        ),
                    ]
                  : [],
              onRecent: (_) {},
              onRemoveRecent: (_) {},
              maps: active
                  ? const [
                      (id: 'a', name: 'Clairière de test'),
                      (id: 'b', name: 'Village de test'),
                      (id: 'c', name: 'Port de test'),
                      (id: 'd', name: 'Forêt de test'),
                    ]
                  : [],
              onMap: routes.add,
            ),
          ),
        ),
      );
      await tester.pumpWidget(app());
      await tester.runAsync(() async {
        await precacheImage(
          const AssetImage('assets/home/hero_landscape.png'),
          key.currentContext!,
        );
        await precacheImage(
          const AssetImage('assets/home/avelune_symbol.png'),
          key.currentContext!,
        );
        await precacheImage(
          const AssetImage('assets/home/avelune_logo.png'),
          key.currentContext!,
        );
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byType(StudioPrimaryNavigation),
          matching: find.byTooltip('Exporter le jeu'),
        ),
        findsNothing,
      );
      if (size.width >= 1280) {
        expect(
          find.byKey(const ValueKey('home-local-content-scroll')),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byType(StudioPrimaryNavigation),
            matching: find.byType(Scrollable),
          ),
          findsNothing,
        );
      }
      await captureM3Widget(
        tester,
        key,
        size.width == 1024
            ? 'ui01-small-150'
            : 'ui01-demo-${size.width.toInt()}',
      );
      await tester.enterText(find.byType(TextField), 'village');
      await tester.pumpAndSettle();
      if (size.width <= 1024) {
        final contentScroll = find.descendant(
          of: find.byKey(const ValueKey('home-local-content-scroll')),
          matching: find.byType(Scrollable),
        );
        await tester.scrollUntilVisible(
          find.text('Village de test'),
          200,
          scrollable: contentScroll,
        );
      }
      expect(find.text('Clairière de test'), findsNothing);
      expect(find.text('Village de test'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      if (size.width <= 1024) {
        final contentScroll = find.descendant(
          of: find.byKey(const ValueKey('home-local-content-scroll')),
          matching: find.byType(Scrollable),
        );
        tester.state<ScrollableState>(contentScroll.first).position.jumpTo(0);
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Reprendre mon projet'));
      await tester.tap(find.text('Reprendre mon projet'));
      expect(resumed, 1);
      if (size.width == 1536) {
        await tester.tap(find.byKey(const ValueKey('home-export-game')));
        expect(routes.last, 'gameExport');
        for (final destination in [
          'map',
          'resources',
          'terrains',
          'characters',
          'story',
          'test',
        ]) {
          final tool = find.byKey(ValueKey('home-tool-$destination'));
          await tester.ensureVisible(tool);
          await tester.tap(tool);
          expect(routes.last, destination);
        }
      }
      active = false;
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('home-export-game')),
            )
            .onPressed,
        isNull,
      );
      expect(find.byTooltip('Exporter le jeu'), findsNothing);
      if (size.width == 1536) await captureM3Widget(tester, key, 'ui01-empty');
      await tester.ensureVisible(
        find.byKey(const ValueKey('open-project-picker')),
      );
      await tester.tap(find.byKey(const ValueKey('open-project-picker')));
      expect(picked, 1);
      if (size.width == 1536) {
        final tool = find.byKey(const ValueKey('home-tool-resources'));
        await tester.ensureVisible(tool);
        await tester.tap(tool);
        expect(routes.last, 'resources');
        expect(
          tester
              .widget<InkWell>(find.byKey(const ValueKey('home-tool-test')))
              .onTap,
          isNull,
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('long home collections scroll locally without moving the frame', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final routes = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: StudioHomeScreen(
          projectName: 'Projet de test',
          onOpen: () {},
          onResume: () {},
          onExport: () {},
          onDestination: routes.add,
          onRecent: (_) {},
          onRemoveRecent: (_) {},
          onMap: routes.add,
          recentProjects: [
            for (var i = 0; i < 100; i++)
              RecentStudioProject(
                name: 'Projet $i',
                directoryPath: '/tmp/project-$i',
                lastOpenedAt: DateTime(2026, 9, 23),
              ),
          ],
          maps: [for (var i = 0; i < 10; i++) (id: 'map-$i', name: 'Carte $i')],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Projet 99'), findsNothing);
    expect(find.text('Voir toutes les cartes (10)'), findsOneWidget);
    final navigation = tester.getRect(find.byType(StudioPrimaryNavigation));
    final hero = tester.getRect(find.text('BIENVENUE DANS AVELUNE STUDIO'));
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(navigation.center));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 300)));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(StudioPrimaryNavigation)), navigation);
    expect(tester.getRect(find.text('BIENVENUE DANS AVELUNE STUDIO')), hero);
    final recentScroll = find.descendant(
      of: find.byKey(const ValueKey('home-recent-projects-list')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Projet 99'),
      300,
      scrollable: recentScroll,
    );
    expect(find.text('Projet 99'), findsOneWidget);
    await tester.tap(find.text('Voir toutes les cartes (10)'));
    expect(routes.last, 'map');
    expect(tester.takeException(), isNull);
  });
}
