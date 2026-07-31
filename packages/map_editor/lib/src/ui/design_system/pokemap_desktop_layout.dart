import 'package:flutter/widgets.dart';

enum PokeMapDesktopWindowClass { compact, medium, expanded }

abstract final class PokeMapDesktopLayoutTokens {
  static const minSupportedWidth = 800.0;
  static const minSupportedHeight = 600.0;
  static const mediumBreakpoint = 1280.0;
  static const expandedBreakpoint = 1440.0;
  static const explorerRailWidth = 52.0;
  static const explorerExpandedWidth = 344.0;
  static const inspectorWidth = 360.0;
  static const expandedInspectorWidth = 400.0;
  static const inspectorResizeHandleWidth = 12.0;
  static const minCanvasWidth = 320.0;
}

@immutable
class PokeMapDesktopLayoutBudget {
  const PokeMapDesktopLayoutBudget({
    required this.viewport,
    required this.windowClass,
    required this.explorerRailWidth,
    this.explorerIsExpanded = false,
    double? explorerWidth,
    required this.inspectorWidth,
    required this.inspectorIsOverlay,
    required this.dockedInspectorWidth,
    this.resizeHandleWidth = 0,
    required this.canvasWidth,
  }) : explorerWidth = explorerWidth ?? explorerRailWidth;

  final Size viewport;
  final PokeMapDesktopWindowClass windowClass;
  final double explorerRailWidth;
  final bool explorerIsExpanded;
  final double explorerWidth;
  final double inspectorWidth;
  final bool inspectorIsOverlay;
  final double dockedInspectorWidth;
  final double resizeHandleWidth;
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

  static PokeMapDesktopLayoutBudget resolve(
    Size viewport, {
    bool explorerExpanded = true,
    bool inspectorVisible = true,
  }) {
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
    final inspectorIsOverlay = windowClass == PokeMapDesktopWindowClass.compact;
    final inspectorWidth = inspectorVisible
        ? windowClass == PokeMapDesktopWindowClass.expanded
            ? PokeMapDesktopLayoutTokens.expandedInspectorWidth
            : PokeMapDesktopLayoutTokens.inspectorWidth
        : 0.0;
    final dockedInspectorWidth = inspectorIsOverlay ? 0.0 : inspectorWidth;
    final resizeHandleWidth = dockedInspectorWidth == 0
        ? 0.0
        : PokeMapDesktopLayoutTokens.inspectorResizeHandleWidth;
    var explorerIsExpanded =
        explorerExpanded && windowClass != PokeMapDesktopWindowClass.compact;
    var explorerWidth = explorerIsExpanded
        ? PokeMapDesktopLayoutTokens.explorerExpandedWidth
        : PokeMapDesktopLayoutTokens.explorerRailWidth;
    var canvasWidth = viewport.width -
        explorerWidth -
        dockedInspectorWidth -
        resizeHandleWidth;

    if (explorerIsExpanded &&
        canvasWidth < PokeMapDesktopLayoutTokens.minCanvasWidth) {
      explorerIsExpanded = false;
      explorerWidth = PokeMapDesktopLayoutTokens.explorerRailWidth;
      canvasWidth = viewport.width -
          explorerWidth -
          dockedInspectorWidth -
          resizeHandleWidth;
    }

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
      explorerIsExpanded: explorerIsExpanded,
      explorerWidth: explorerWidth,
      inspectorWidth: inspectorWidth,
      inspectorIsOverlay: inspectorIsOverlay,
      dockedInspectorWidth: dockedInspectorWidth,
      resizeHandleWidth: resizeHandleWidth,
      canvasWidth: canvasWidth,
    );
  }
}
