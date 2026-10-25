import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  for (final reduced in [false, true]) {
    testWidgets(
      'detail transition follows direction without retaining old height reduced=$reduced',
      (tester) async {
        Widget host(int page) => MaterialApp(
          theme: PokeMapPlayerTheme.light(reducedMotion: reduced),
          home: PlayerMenuThemeScope(
            child: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: PlayerMenuDetailTransition(
                  contentKey: ValueKey(page),
                  direction: -1,
                  child: SizedBox(
                    key: ValueKey('content-$page'),
                    width: 300,
                    height: page == 0 ? 200 : 60,
                    child: Text('Page $page'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpWidget(host(0));
        await tester.pumpAndSettle();
        await tester.pumpWidget(host(1));
        expect(
          tester.getSize(find.byType(PlayerMenuDetailTransition)),
          const Size(300, 60),
        );
        final incoming = find
            .ancestor(
              of: find.byKey(const ValueKey('content-1')),
              matching: find.byKey(
                const ValueKey('player-menu-detail-transform'),
              ),
            )
            .first;
        expect(
          tester.widget<Transform>(incoming).transform.getTranslation().x,
          reduced ? 0 : -8,
        );
        expect(find.text('Page 0'), findsOneWidget);
        await tester.pumpAndSettle();
        expect(find.text('Page 0'), findsNothing);
        expect(
          tester.getSize(find.byType(PlayerMenuDetailTransition)),
          const Size(300, 60),
        );
        expect(
          tester.widget<Transform>(incoming).transform.getTranslation().x,
          0,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
