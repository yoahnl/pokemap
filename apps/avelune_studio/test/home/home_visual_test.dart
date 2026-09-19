import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/features/home/domain/recent_studio_project.dart';
import 'package:avelune_studio/presentation/features/home/studio_home_screen.dart';
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
      await captureM3Widget(
        tester,
        key,
        size.width == 1024
            ? 'ui01-small-150'
            : 'ui01-demo-${size.width.toInt()}',
      );
      await tester.enterText(find.byType(TextField), 'village');
      await tester.pumpAndSettle();
      expect(find.text('Clairière de test'), findsNothing);
      expect(find.text('Village de test'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Reprendre mon projet'));
      await tester.tap(find.text('Reprendre mon projet'));
      expect(resumed, 1);
      if (size.width == 1536) {
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
}
