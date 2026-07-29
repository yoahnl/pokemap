import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  group('PokeMapDesktopLayout', () {
    test('classifies the supported desktop viewport boundaries', () {
      expect(
        PokeMapDesktopLayout.resolve(const Size(800, 600)).windowClass,
        PokeMapDesktopWindowClass.compact,
      );
      expect(
        PokeMapDesktopLayout.resolve(const Size(1280, 800)).windowClass,
        PokeMapDesktopWindowClass.medium,
      );
      expect(
        PokeMapDesktopLayout.resolve(const Size(1440, 900)).windowClass,
        PokeMapDesktopWindowClass.expanded,
      );
    });

    test('reserves at least the minimum canvas width in every window class',
        () {
      const viewports = <Size>[
        Size(800, 600),
        Size(1024, 600),
        Size(1440, 600),
      ];

      final budgets = viewports.map(PokeMapDesktopLayout.resolve).toList();

      expect(
        budgets.map((budget) => budget.windowClass),
        <PokeMapDesktopWindowClass>[
          PokeMapDesktopWindowClass.compact,
          PokeMapDesktopWindowClass.medium,
          PokeMapDesktopWindowClass.expanded,
        ],
      );
      for (final budget in budgets) {
        expect(
          budget.canvasWidth,
          greaterThanOrEqualTo(PokeMapDesktopLayoutTokens.minCanvasWidth),
        );
      }
      expect(budgets.first.inspectorIsOverlay, isTrue);
      expect(budgets.first.dockedInspectorWidth, 0);
      expect(
        budgets.first.canvasWidth,
        800 - PokeMapDesktopLayoutTokens.explorerRailWidth,
      );
      expect(budgets[1].inspectorIsOverlay, isFalse);
      expect(
        budgets[1].dockedInspectorWidth,
        PokeMapDesktopLayoutTokens.inspectorWidth,
      );
      expect(budgets.last.inspectorIsOverlay, isFalse);
      expect(
        budgets.last.dockedInspectorWidth,
        PokeMapDesktopLayoutTokens.expandedInspectorWidth,
      );
      expect(
        budgets.last.inspectorWidth,
        PokeMapDesktopLayoutTokens.expandedInspectorWidth,
      );
    });

    test('rejects viewports below the supported desktop floor', () {
      expect(
        () => PokeMapDesktopLayout.resolve(const Size(799, 600)),
        throwsArgumentError,
      );
      expect(
        () => PokeMapDesktopLayout.resolve(const Size(800, 599)),
        throwsArgumentError,
      );
    });
  });
}
