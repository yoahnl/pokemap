import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:pokemap_hub/presentation/features/home/widgets/avelune_cartridge.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_console.dart';
import 'package:pokemap_hub/presentation/design_system/foundation/avelune_breakpoints.dart';

enum AveluneHomeSizeClass { compact, regular, large }

@immutable
final class AveluneInsertionTrajectory {
  const AveluneInsertionTrajectory({
    required this.startCenter,
    required this.alignedCenter,
    required this.latchedCenter,
  });

  final Offset startCenter;
  final Offset alignedCenter;
  final Offset latchedCenter;
}

@immutable
final class AveluneHomeAnchors {
  const AveluneHomeAnchors({
    required this.heroCenter,
    required this.consoleSlotCenter,
    required this.shelfBaseline,
    required this.insertion,
  });

  final Offset heroCenter;
  final Offset consoleSlotCenter;
  final Offset shelfBaseline;
  final AveluneInsertionTrajectory insertion;
}

@immutable
final class AveluneHomeGeometry {
  const AveluneHomeGeometry._({
    required this.sizeClass,
    required this.viewportSize,
    required this.safeArea,
    required this.contentRect,
    required this.headerRect,
    required this.sceneRect,
    required this.shelfRect,
    required this.navigationRect,
    required this.cabinWindowRect,
    required this.consoleLedgeRect,
    required this.librarySheetRect,
    required this.consoleFootlineY,
    required this.heroCartridgeSize,
    required this.shelfCartridgeSize,
    required this.heroCartridgeRect,
    required this.consoleRect,
    required this.consoleSlotRect,
    required this.consoleSlotMouthY,
    required this.shelfFirstCartridgeRect,
    required this.anchors,
    required this.shelfGap,
    required this.shelfHorizontalPadding,
    required this.hidesNonEssentialMetadata,
    required this.routesExtendedContentToSheet,
  });

  factory AveluneHomeGeometry.resolve({
    required Size viewportSize,
    EdgeInsets safeArea = EdgeInsets.zero,
    double textScaleFactor = 1,
  }) {
    _validateInputs(
      viewportSize: viewportSize,
      safeArea: safeArea,
      textScaleFactor: textScaleFactor,
    );

    final contentWidth = viewportSize.width - safeArea.horizontal;
    final contentHeight = viewportSize.height - safeArea.vertical;
    if (contentWidth < AveluneBreakpoints.minimumContentWidth ||
        contentHeight < AveluneBreakpoints.minimumContentHeight) {
      throw ArgumentError.value(
        viewportSize,
        'viewportSize',
        'The Safe Area must leave at least '
            '${AveluneBreakpoints.minimumContentWidth}x'
            '${AveluneBreakpoints.minimumContentHeight} logical pixels.',
      );
    }

    final contentRect = Rect.fromLTWH(
      safeArea.left,
      safeArea.top,
      contentWidth,
      contentHeight,
    );
    final sizeClass = _resolveSizeClass(contentRect.size);
    final metrics = _metricsFor(sizeClass);
    final librarySheetTop = contentRect.top +
        (contentRect.height * metrics.librarySheetTopFraction);
    final sceneRect = Rect.fromLTRB(
      contentRect.left,
      contentRect.top,
      contentRect.right,
      librarySheetTop,
    );
    final navigationRect = Rect.fromLTRB(
      contentRect.left,
      contentRect.bottom - metrics.navigationHeight,
      contentRect.right,
      contentRect.bottom,
    );
    final shelfRect = Rect.fromLTRB(
      contentRect.left,
      librarySheetTop + metrics.libraryHeaderHeight,
      contentRect.right,
      navigationRect.top,
    );
    final librarySheetRect = Rect.fromLTRB(
      0,
      librarySheetTop,
      viewportSize.width,
      viewportSize.height,
    );
    final consoleLedgeRect = Rect.fromLTRB(
      0,
      librarySheetTop - metrics.consoleLedgeDepth,
      viewportSize.width,
      librarySheetTop,
    );
    final cabinWindowRect = Rect.fromLTRB(
      contentRect.left + metrics.windowHorizontalInset,
      contentRect.top + metrics.windowTopInset,
      contentRect.right - metrics.windowHorizontalInset,
      consoleLedgeRect.top + metrics.windowLedgeOverlap,
    );
    final headerRect = Rect.fromLTWH(
      cabinWindowRect.left + metrics.windowContentInset,
      cabinWindowRect.top + metrics.windowContentInset,
      cabinWindowRect.width - (metrics.windowContentInset * 2),
      metrics.headerHeight,
    );
    final heroCartridgeSize = Size(
      metrics.heroCartridgeHeight * kAveluneCartridgeAspectRatio,
      metrics.heroCartridgeHeight,
    );
    final shelfCartridgeSize = Size(
      metrics.shelfCartridgeHeight * kAveluneCartridgeAspectRatio,
      metrics.shelfCartridgeHeight,
    );

    final consoleWidth = math.min(
      contentRect.width - (metrics.sceneHorizontalPadding * 2),
      _maximumConsoleWidth,
    );
    final consoleHeight = consoleWidth / kAveluneConsoleAspectRatio;
    final consoleRect = Rect.fromLTWH(
      contentRect.center.dx - (consoleWidth / 2),
      librarySheetTop -
          metrics.consoleFootlineInset -
          (consoleHeight * kAveluneConsoleFootlineFraction),
      consoleWidth,
      consoleHeight,
    );
    final heroCartridgeRect = Rect.fromLTWH(
      contentRect.center.dx - (heroCartridgeSize.width / 2),
      consoleRect.top - metrics.heroConsoleGap - heroCartridgeSize.height,
      heroCartridgeSize.width,
      heroCartridgeSize.height,
    );

    if (heroCartridgeRect.top < headerRect.bottom) {
      throw ArgumentError.value(
        viewportSize,
        'viewportSize',
        'The scene cannot fit the canonical hero and console geometry.',
      );
    }

    final consoleSlotMouthY = consoleRect.top +
        (consoleRect.height * kAveluneConsoleSlotMouthFraction);
    final consoleSlotRect = Rect.fromCenter(
      center: Offset(
        consoleRect.center.dx,
        consoleRect.top +
            (consoleRect.height * kAveluneConsoleSlotCenterFraction),
      ),
      width: consoleRect.width * _consoleSlotWidthFactor,
      height: metrics.consoleSlotHeight,
    );
    final consoleFootlineY = consoleRect.top +
        (consoleRect.height * kAveluneConsoleFootlineFraction);
    final shelfBaselineY = shelfRect.bottom - metrics.shelfBottomPadding;
    final shelfFirstCartridgeRect = Rect.fromLTWH(
      shelfRect.left + metrics.shelfHorizontalPadding,
      shelfBaselineY - shelfCartridgeSize.height,
      shelfCartridgeSize.width,
      shelfCartridgeSize.height,
    );

    if (!shelfRect.contains(shelfFirstCartridgeRect.center)) {
      throw ArgumentError.value(
        viewportSize,
        'viewportSize',
        'The shelf cannot fit the canonical shelf cartridge geometry.',
      );
    }

    // Aligning lifts the cartridge off its resting place and squares it over
    // the slot; the descent then covers the whole distance to the hardware.
    final insertionAlignedCenter = Offset(
      consoleSlotRect.center.dx,
      heroCartridgeRect.center.dy - metrics.insertionClearance,
    );
    // Latched means the connectors are swallowed and the shell stands proud of
    // the console, as the approved latched reference shows. Driving the centre
    // below the slot instead pushed the cartridge out under the hardware.
    // Latched buries exactly the contact strip below the slot's near lip, which
    // is where the cartridge is clipped, so the shell reads as seated in the
    // cavity with its connectors inside.
    final insertionLatchedCenter = Offset(
      consoleSlotRect.center.dx,
      consoleSlotMouthY +
          (heroCartridgeSize.height *
              kAveluneCartridgeConnectorHeightFraction) -
          (heroCartridgeSize.height / 2),
    );
    final highTextScale = textScaleFactor >= _sheetTextScaleThreshold;
    final compactContent = sizeClass == AveluneHomeSizeClass.compact;
    final anchors = AveluneHomeAnchors(
      heroCenter: heroCartridgeRect.center,
      consoleSlotCenter: consoleSlotRect.center,
      shelfBaseline: Offset(
        shelfFirstCartridgeRect.center.dx,
        shelfBaselineY,
      ),
      insertion: AveluneInsertionTrajectory(
        startCenter: heroCartridgeRect.center,
        alignedCenter: insertionAlignedCenter,
        latchedCenter: insertionLatchedCenter,
      ),
    );

    return AveluneHomeGeometry._(
      sizeClass: sizeClass,
      viewportSize: viewportSize,
      safeArea: safeArea,
      contentRect: contentRect,
      headerRect: headerRect,
      sceneRect: sceneRect,
      shelfRect: shelfRect,
      navigationRect: navigationRect,
      cabinWindowRect: cabinWindowRect,
      consoleLedgeRect: consoleLedgeRect,
      librarySheetRect: librarySheetRect,
      consoleFootlineY: consoleFootlineY,
      heroCartridgeSize: heroCartridgeSize,
      shelfCartridgeSize: shelfCartridgeSize,
      heroCartridgeRect: heroCartridgeRect,
      consoleRect: consoleRect,
      consoleSlotRect: consoleSlotRect,
      consoleSlotMouthY: consoleSlotMouthY,
      shelfFirstCartridgeRect: shelfFirstCartridgeRect,
      anchors: anchors,
      shelfGap: metrics.shelfGap,
      shelfHorizontalPadding: metrics.shelfHorizontalPadding,
      hidesNonEssentialMetadata: compactContent || highTextScale,
      routesExtendedContentToSheet: highTextScale,
    );
  }

  static const double _maximumConsoleWidth = 408;
  static const double _consoleSlotWidthFactor = 0.34;
  static const double _sheetTextScaleThreshold = 1.4;

  final AveluneHomeSizeClass sizeClass;
  final Size viewportSize;
  final EdgeInsets safeArea;
  final Rect contentRect;
  final Rect headerRect;
  final Rect sceneRect;
  final Rect shelfRect;
  final Rect navigationRect;

  /// Scenic view clipped by the fixed train/aircraft cabin surround.
  final Rect cabinWindowRect;

  /// Dark technical shelf supporting the console. It is never marble.
  final Rect consoleLedgeRect;

  /// Warm lower panel containing the library and navigation.
  final Rect librarySheetRect;

  /// Screen y of the console's feet where the technical ledge supports it.
  final double consoleFootlineY;
  final Size heroCartridgeSize;
  final Size shelfCartridgeSize;
  final Rect heroCartridgeRect;
  final Rect consoleRect;
  final Rect consoleSlotRect;

  /// Screen y at which a descending cartridge enters the slot and is clipped.
  final double consoleSlotMouthY;
  final Rect shelfFirstCartridgeRect;
  final AveluneHomeAnchors anchors;
  final double shelfGap;
  final double shelfHorizontalPadding;
  final bool hidesNonEssentialMetadata;
  final bool routesExtendedContentToSheet;

  bool get allowsVerticalScroll => false;

  double get estimatedVisibleShelfSlots {
    final availableWidth = shelfRect.width - (shelfHorizontalPadding * 2);
    return (availableWidth + shelfGap) / (shelfCartridgeSize.width + shelfGap);
  }

  static void _validateInputs({
    required Size viewportSize,
    required EdgeInsets safeArea,
    required double textScaleFactor,
  }) {
    if (!viewportSize.width.isFinite ||
        !viewportSize.height.isFinite ||
        viewportSize.width <= 0 ||
        viewportSize.height <= 0) {
      throw ArgumentError.value(
        viewportSize,
        'viewportSize',
        'Viewport dimensions must be finite and positive.',
      );
    }
    final safeAreaValues = <double>[
      safeArea.left,
      safeArea.top,
      safeArea.right,
      safeArea.bottom,
    ];
    if (safeAreaValues.any((value) => !value.isFinite || value < 0)) {
      throw ArgumentError.value(
        safeArea,
        'safeArea',
        'Safe Area insets must be finite and non-negative.',
      );
    }
    if (!textScaleFactor.isFinite || textScaleFactor <= 0) {
      throw ArgumentError.value(
        textScaleFactor,
        'textScaleFactor',
        'Text scale factor must be finite and positive.',
      );
    }
  }

  static AveluneHomeSizeClass _resolveSizeClass(Size contentSize) {
    return switch (AveluneBreakpoints.resolve(contentSize)) {
      AveluneBreakpointClass.compact => AveluneHomeSizeClass.compact,
      AveluneBreakpointClass.regular => AveluneHomeSizeClass.regular,
      AveluneBreakpointClass.large => AveluneHomeSizeClass.large,
    };
  }

  static _AveluneHomeClassMetrics _metricsFor(
    AveluneHomeSizeClass sizeClass,
  ) =>
      switch (sizeClass) {
        AveluneHomeSizeClass.compact => _compactMetrics,
        AveluneHomeSizeClass.regular => _regularMetrics,
        AveluneHomeSizeClass.large => _largeMetrics,
      };

  static const _compactMetrics = _AveluneHomeClassMetrics(
    librarySheetTopFraction: 0.60,
    headerHeight: 42,
    libraryHeaderHeight: 54,
    navigationHeight: 56,
    heroCartridgeHeight: 100,
    shelfCartridgeHeight: 98,
    shelfHorizontalPadding: 12,
    shelfBottomPadding: 10,
    shelfGap: 8,
    sceneHorizontalPadding: 14,
    heroConsoleGap: 14,
    windowHorizontalInset: 8,
    windowTopInset: 2,
    windowContentInset: 12,
    windowLedgeOverlap: 14,
    consoleLedgeDepth: 38,
    consoleFootlineInset: 14,
    consoleSlotHeight: 6,
    insertionClearance: 3,
  );

  static const _regularMetrics = _AveluneHomeClassMetrics(
    librarySheetTopFraction: 0.64,
    headerHeight: 48,
    libraryHeaderHeight: 70,
    navigationHeight: 60,
    heroCartridgeHeight: 148,
    shelfCartridgeHeight: 133,
    shelfHorizontalPadding: 18,
    shelfBottomPadding: 10,
    shelfGap: 10,
    sceneHorizontalPadding: 20,
    heroConsoleGap: 20,
    windowHorizontalInset: 9,
    windowTopInset: 3,
    windowContentInset: 16,
    windowLedgeOverlap: 18,
    consoleLedgeDepth: 48,
    consoleFootlineInset: 17,
    consoleSlotHeight: 6,
    insertionClearance: 4,
  );

  static const _largeMetrics = _AveluneHomeClassMetrics(
    librarySheetTopFraction: 0.635,
    headerHeight: 52,
    libraryHeaderHeight: 72,
    navigationHeight: 60,
    heroCartridgeHeight: 172,
    shelfCartridgeHeight: 140,
    shelfHorizontalPadding: 18,
    shelfBottomPadding: 12,
    shelfGap: 12,
    sceneHorizontalPadding: 20,
    heroConsoleGap: 22,
    windowHorizontalInset: 10,
    windowTopInset: 3,
    windowContentInset: 18,
    windowLedgeOverlap: 20,
    consoleLedgeDepth: 54,
    consoleFootlineInset: 18,
    consoleSlotHeight: 6,
    insertionClearance: 4,
  );
}

@immutable
final class _AveluneHomeClassMetrics {
  const _AveluneHomeClassMetrics({
    required this.librarySheetTopFraction,
    required this.headerHeight,
    required this.libraryHeaderHeight,
    required this.navigationHeight,
    required this.heroCartridgeHeight,
    required this.shelfCartridgeHeight,
    required this.shelfHorizontalPadding,
    required this.shelfBottomPadding,
    required this.shelfGap,
    required this.sceneHorizontalPadding,
    required this.heroConsoleGap,
    required this.windowHorizontalInset,
    required this.windowTopInset,
    required this.windowContentInset,
    required this.windowLedgeOverlap,
    required this.consoleLedgeDepth,
    required this.consoleFootlineInset,
    required this.consoleSlotHeight,
    required this.insertionClearance,
  });

  final double librarySheetTopFraction;
  final double headerHeight;
  final double libraryHeaderHeight;
  final double navigationHeight;
  final double heroCartridgeHeight;
  final double shelfCartridgeHeight;
  final double shelfHorizontalPadding;
  final double shelfBottomPadding;
  final double shelfGap;
  final double sceneHorizontalPadding;
  final double windowHorizontalInset;
  final double windowTopInset;
  final double windowContentInset;
  final double windowLedgeOverlap;
  final double consoleLedgeDepth;
  final double consoleFootlineInset;

  /// Vertical breathing room between the hero cartridge and the console.
  final double heroConsoleGap;
  final double consoleSlotHeight;
  final double insertionClearance;
}
