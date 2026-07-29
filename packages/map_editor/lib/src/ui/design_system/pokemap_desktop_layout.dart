import 'package:flutter/widgets.dart';

enum PokeMapDesktopWindowClass { compact, medium, expanded }

abstract final class PokeMapDesktopLayoutTokens {
  static const minSupportedWidth = 800.0;
  static const minSupportedHeight = 600.0;
  static const mediumBreakpoint = 1024.0;
  static const expandedBreakpoint = 1440.0;
  static const explorerRailWidth = 52.0;
  static const inspectorWidth = 360.0;
  static const expandedInspectorWidth = 400.0;
  static const minCanvasWidth = 320.0;
}

@immutable
class PokeMapDesktopLayoutBudget {
  const PokeMapDesktopLayoutBudget({
    required this.viewport,
    required this.windowClass,
    required this.explorerRailWidth,
    required this.inspectorWidth,
    required this.inspectorIsOverlay,
    required this.dockedInspectorWidth,
    required this.canvasWidth,
  });

  final Size viewport;
  final PokeMapDesktopWindowClass windowClass;
  final double explorerRailWidth;
  final double inspectorWidth;
  final bool inspectorIsOverlay;
  final double dockedInspectorWidth;
  final double canvasWidth;
}

/// Owns desktop breakpoint classification and fixed-column budgeting.
abstract final class PokeMapDesktopLayout {
  static PokeMapDesktopWindowClass classify(double width) {
    if (width >= PokeMapDesktopLayoutTokens.expandedBreakpoint) {
      return PokeMapDesktopWindowClass.expanded;
    }
    if (width >= PokeMapDesktopLayoutTokens.mediumBreakpoint) {
      return PokeMapDesktopWindowClass.medium;
    }
    return PokeMapDesktopWindowClass.compact;
  }

  static PokeMapDesktopLayoutBudget resolve(Size viewport) {
    if (viewport.width < PokeMapDesktopLayoutTokens.minSupportedWidth ||
        viewport.height < PokeMapDesktopLayoutTokens.minSupportedHeight) {
      throw ArgumentError.value(
        viewport,
        'viewport',
        'PokeMap desktop layouts require at least '
            '${PokeMapDesktopLayoutTokens.minSupportedWidth} × '
            '${PokeMapDesktopLayoutTokens.minSupportedHeight} logical pixels.',
      );
    }

    final windowClass = classify(viewport.width);
    final inspectorWidth = windowClass == PokeMapDesktopWindowClass.expanded
        ? PokeMapDesktopLayoutTokens.expandedInspectorWidth
        : PokeMapDesktopLayoutTokens.inspectorWidth;
    final inspectorIsOverlay = windowClass == PokeMapDesktopWindowClass.compact;
    final dockedInspectorWidth = inspectorIsOverlay ? 0.0 : inspectorWidth;
    final canvasWidth = viewport.width -
        PokeMapDesktopLayoutTokens.explorerRailWidth -
        dockedInspectorWidth;

    if (canvasWidth < PokeMapDesktopLayoutTokens.minCanvasWidth) {
      throw StateError(
        'The resolved desktop columns leave only $canvasWidth logical pixels '
        'for the canvas.',
      );
    }

    return PokeMapDesktopLayoutBudget(
      viewport: viewport,
      windowClass: windowClass,
      explorerRailWidth: PokeMapDesktopLayoutTokens.explorerRailWidth,
      inspectorWidth: inspectorWidth,
      inspectorIsOverlay: inspectorIsOverlay,
      dockedInspectorWidth: dockedInspectorWidth,
      canvasWidth: canvasWidth,
    );
  }
}
