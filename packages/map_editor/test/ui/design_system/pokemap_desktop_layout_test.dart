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
        PokeMapDesktopLayout.resolve(const Size(1279, 800)).windowClass,
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

    test('preserves the existing budget constructor signature', () {
      const budget = PokeMapDesktopLayoutBudget(
        viewport: Size(1280, 800),
        windowClass: PokeMapDesktopWindowClass.medium,
        explorerRailWidth: 52,
        inspectorWidth: 360,
        inspectorIsOverlay: false,
        dockedInspectorWidth: 360,
        canvasWidth: 868,
      );

      expect(budget.explorerIsExpanded, isFalse);
      expect(budget.explorerWidth, 52);
      expect(budget.resizeHandleWidth, 0);
    });

    test('resolves the exact compact budget at 800 logical pixels', () {
      final budget = PokeMapDesktopLayout.resolve(const Size(800, 600));

      expect(PokeMapDesktopLayoutTokens.explorerExpandedWidth, 344);
      expect(PokeMapDesktopLayoutTokens.inspectorResizeHandleWidth, 12);
      expect(budget.windowClass, PokeMapDesktopWindowClass.compact);
      expect(budget.explorerRailWidth, 52);
      expect(budget.explorerIsExpanded, isFalse);
      expect(budget.explorerWidth, 52);
      expect(budget.inspectorWidth, 360);
      expect(budget.inspectorIsOverlay, isTrue);
      expect(budget.dockedInspectorWidth, 0);
      expect(budget.resizeHandleWidth, 0);
      expect(budget.canvasWidth, 748);
    });

    test('keeps the compact overlay budget immediately below 1280', () {
      final budget = PokeMapDesktopLayout.resolve(const Size(1279, 800));

      expect(budget.windowClass, PokeMapDesktopWindowClass.compact);
      expect(budget.explorerIsExpanded, isFalse);
      expect(budget.explorerWidth, 52);
      expect(budget.inspectorWidth, 360);
      expect(budget.inspectorIsOverlay, isTrue);
      expect(budget.dockedInspectorWidth, 0);
      expect(budget.resizeHandleWidth, 0);
      expect(budget.canvasWidth, 1227);
    });

    test('resolves the exact medium budget at 1280 logical pixels', () {
      final budget = PokeMapDesktopLayout.resolve(const Size(1280, 800));

      expect(budget.windowClass, PokeMapDesktopWindowClass.medium);
      expect(budget.explorerIsExpanded, isTrue);
      expect(budget.explorerWidth, 344);
      expect(budget.inspectorWidth, 360);
      expect(budget.inspectorIsOverlay, isFalse);
      expect(budget.dockedInspectorWidth, 360);
      expect(budget.resizeHandleWidth, 12);
      expect(budget.canvasWidth, 564);
    });

    test('resolves the exact expanded budget at 1440 logical pixels', () {
      final budget = PokeMapDesktopLayout.resolve(const Size(1440, 900));

      expect(budget.windowClass, PokeMapDesktopWindowClass.expanded);
      expect(budget.explorerIsExpanded, isTrue);
      expect(budget.explorerWidth, 344);
      expect(budget.inspectorWidth, 400);
      expect(budget.inspectorIsOverlay, isFalse);
      expect(budget.dockedInspectorWidth, 400);
      expect(budget.resizeHandleWidth, 12);
      expect(budget.canvasWidth, 684);
    });

    test('honors explicit panel state while preserving the canvas floor', () {
      final collapsedExplorer = PokeMapDesktopLayout.resolve(
        const Size(1280, 800),
        explorerExpanded: false,
      );
      final hiddenInspector = PokeMapDesktopLayout.resolve(
        const Size(1280, 800),
        inspectorVisible: false,
      );

      expect(collapsedExplorer.explorerIsExpanded, isFalse);
      expect(collapsedExplorer.explorerWidth, 52);
      expect(collapsedExplorer.canvasWidth, 856);
      expect(hiddenInspector.explorerIsExpanded, isTrue);
      expect(hiddenInspector.explorerWidth, 344);
      expect(hiddenInspector.inspectorWidth, 0);
      expect(hiddenInspector.dockedInspectorWidth, 0);
      expect(hiddenInspector.resizeHandleWidth, 0);
      expect(hiddenInspector.canvasWidth, 936);
    });

    test('always reserves at least the minimum canvas width', () {
      const viewports = <Size>[
        Size(800, 600),
        Size(1279, 800),
        Size(1280, 800),
        Size(1439, 900),
        Size(1440, 900),
      ];

      for (final viewport in viewports) {
        final budget = PokeMapDesktopLayout.resolve(viewport);
        expect(
          budget.canvasWidth,
          greaterThanOrEqualTo(PokeMapDesktopLayoutTokens.minCanvasWidth),
          reason: 'viewport: $viewport',
        );
      }
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
