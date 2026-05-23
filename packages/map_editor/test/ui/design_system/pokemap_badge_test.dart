import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  group('PokeMapBadge Tests', () {
    Widget buildTestWidget({
      required ThemeData theme,
      required Widget child,
    }) {
      return MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(child: child),
        ),
      );
    }

    testWidgets('PokeMapBadge pumps correctly under light & dark theme for all variants', (tester) async {
      for (final variant in PokeMapBadgeVariant.values) {
        // Light Mode
        await tester.pumpWidget(
          buildTestWidget(
            theme: PokeMapTheme.light(),
            child: PokeMapBadge(
              label: 'Tag $variant',
              variant: variant,
              icon: const Icon(Icons.label),
            ),
          ),
        );
        expect(find.text('Tag $variant'), findsOneWidget);
        expect(find.byType(Icon), findsOneWidget);

        // Dark Mode
        await tester.pumpWidget(
          buildTestWidget(
            theme: PokeMapTheme.dark(),
            child: PokeMapBadge(
              label: 'Tag $variant',
              variant: variant,
            ),
          ),
        );
        expect(find.text('Tag $variant'), findsOneWidget);
      }
    });

    testWidgets('PokeMapBadge.mapAccent uses colors.mapAccent correctly', (tester) async {
      late BuildContext capturedContext;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                capturedContext = context;
                return const PokeMapBadge(
                  label: 'Map Item',
                  variant: PokeMapBadgeVariant.mapAccent,
                );
              },
            ),
          ),
        ),
      );

      final badgeContainerFinder = find.byType(Container);
      expect(badgeContainerFinder, findsOneWidget);

      final expectedMapColor = capturedContext.pokeMapColors.mapAccent;
      
      // The text inside should have the mapAccent color
      final textFinder = find.text('Map Item');
      expect(textFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.color, equals(expectedMapColor));
    });
  });
}
