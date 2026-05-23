import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  group('PokeMapCard, Panel, Toolbar, SectionHeader, and EmptyState Tests', () {
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

    testWidgets('PokeMapCard & PokeMapPanel pump correctly under light & dark theme', (tester) async {
      // PokeMapCard
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: const PokeMapCard(
            child: Text('Card Content'),
          ),
        ),
      );
      expect(find.text('Card Content'), findsOneWidget);

      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.dark(),
          child: const PokeMapCard(
            child: Text('Card Content'),
          ),
        ),
      );
      expect(find.text('Card Content'), findsOneWidget);

      // PokeMapPanel
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: const PokeMapPanel(
            header: Text('Header'),
            footer: Text('Footer'),
            child: Text('Panel Content'),
          ),
        ),
      );
      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Panel Content'), findsOneWidget);
      expect(find.text('Footer'), findsOneWidget);
    });

    testWidgets('PokeMapCard border changes when selected', (tester) async {
      late BuildContext capturedContext;
      
      // Unselected card
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                capturedContext = context;
                return const PokeMapCard(
                  selected: false,
                  child: Text('Card Content'),
                );
              },
            ),
          ),
        ),
      );

      final cardFinder = find.byType(PokeMapCard);
      expect(cardFinder, findsOneWidget);

      final containerWidgetUnselected = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final decorationUnselected = containerWidgetUnselected.decoration as BoxDecoration;
      final borderUnselected = decorationUnselected.border as Border;
      
      // Selected card
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return const PokeMapCard(
                  selected: true,
                  child: Text('Card Content'),
                );
              },
            ),
          ),
        ),
      );

      final containerWidgetSelected = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final decorationSelected = containerWidgetSelected.decoration as BoxDecoration;
      final borderSelected = decorationSelected.border as Border;

      expect(borderUnselected.top.color, isNot(equals(borderSelected.top.color)));
      expect(borderSelected.top.color, equals(capturedContext.pokeMapColors.brandPrimaryBorder));
    });

    testWidgets('PokeMapToolbarSurface & PokeMapSectionHeader pump correctly', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: const PokeMapToolbarSurface(
            child: Text('Toolbar Content'),
          ),
        ),
      );
      expect(find.text('Toolbar Content'), findsOneWidget);

      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: const PokeMapSectionHeader(
            title: 'Section Title',
            description: 'Section Description',
            trailing: Icon(Icons.info),
          ),
        ),
      );
      expect(find.text('Section Title'), findsOneWidget);
      expect(find.text('Section Description'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('PokeMapEmptyState displays title, description and action if provided', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: PokeMapEmptyState(
            title: 'No Items Found',
            description: 'Please add some items to get started.',
            icon: const Icon(Icons.hourglass_empty),
            action: PokeMapButton(
              onPressed: () => actionTriggered = true,
              child: const Text('Add Now'),
            ),
          ),
        ),
      );

      expect(find.text('No Items Found'), findsOneWidget);
      expect(find.text('Please add some items to get started.'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
      expect(find.text('Add Now'), findsOneWidget);

      await tester.tap(find.text('Add Now'));
      expect(actionTriggered, isTrue);
    });
  });
}
