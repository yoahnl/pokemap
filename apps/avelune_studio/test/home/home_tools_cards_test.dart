import 'package:avelune_studio/presentation/features/home/studio_home_tools.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (width, textScale) in [(1100.0, 1.0), (720.0, 1.5)]) {
    testWidgets(
      'creation tool cards share one height at $width and $textScale',
      (tester) async {
        tester.view.physicalSize = Size(width, 750);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final destinations = <String>[];
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
              child: Scaffold(
                body: StudioHomeTools(
                  onDestination: destinations.add,
                  hasProject: true,
                  canTest: true,
                  busy: false,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final cards = [
          for (final id in [
            'map',
            'resources',
            'terrains',
            'characters',
            'story',
            'test',
          ])
            find.byKey(ValueKey('home-tool-$id')),
        ];
        final heights = [for (final card in cards) tester.getSize(card).height];
        expect(heights.toSet(), hasLength(1));
        await tester.tap(cards.first);
        expect(destinations, ['map']);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
