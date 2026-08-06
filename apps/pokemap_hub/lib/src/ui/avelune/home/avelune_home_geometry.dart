import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../assets/avelune_credenza_metrics.dart';
import '../avelune_cartridge.dart';
import '../avelune_console.dart';
import '../design_system/foundation/avelune_breakpoints.dart';

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
    required this.credenzaRect,
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
    final regions = _resolveRegions(contentRect, metrics);
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
      regions.scene.bottom - metrics.sceneBottomPadding - consoleHeight,
      consoleWidth,
      consoleHeight,
    );
    final heroCartridgeRect = Rect.fromLTWH(
      contentRect.center.dx - (heroCartridgeSize.width / 2),
      consoleRect.top - metrics.heroConsoleGap - heroCartridgeSize.height,
      heroCartridgeSize.width,
      heroCartridgeSize.height,
    );

    if (heroCartridgeRect.top < regions.scene.top) {
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
    // The credenza runs from the console's feet all the way to the bottom of the
    // screen, so no dark strip shows beneath it. Its shelf board then lands
    // wherever that height puts it, and the shelf band is built around the
    // board — the reverse of deriving the furniture from a band fraction, which
    // left the room ending short of the bottom edge.
    final consoleFootlineY = consoleRect.top +
        (consoleRect.height * kAveluneConsoleFootlineFraction);
    final credenzaHeight = AveluneCredenzaMetrics.heightToReach(
      bottomY: viewportSize.height,
      consoleFootlineY: consoleFootlineY,
    );
    final credenzaWidth = math.max(
      credenzaHeight * AveluneCredenzaMetrics.aspectRatio,
      contentRect.width,
    );
    final credenzaRect = Rect.fromLTWH(
      contentRect.center.dx - (credenzaWidth / 2),
      AveluneCredenzaMetrics.topFor(
        height: credenzaHeight,
        consoleFootlineY: consoleFootlineY,
      ),
      credenzaWidth,
      credenzaHeight,
    );
    final shelfBaselineY = credenzaRect.top +
        (credenzaRect.height * AveluneCredenzaMetrics.shelfBoard);
    final shelfRect = Rect.fromLTRB(
      contentRect.left,
      regions.scene.bottom,
      contentRect.right,
      math.min(
        contentRect.bottom,
        shelfBaselineY + metrics.shelfBottomPadding,
      ),
    );
    final navigationRect = Rect.fromLTRB(
      contentRect.left,
      shelfRect.bottom,
      contentRect.right,
      contentRect.bottom,
    );
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
      headerRect: regions.header,
      sceneRect: regions.scene,
      shelfRect: shelfRect,
      navigationRect: navigationRect,
      credenzaRect: credenzaRect,
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

  /// The credenza, sized so its base meets the bottom of the screen.
  final Rect credenzaRect;

  /// Screen y of the console's feet — the line the credenza's top surface meets.
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

  static _AveluneHomeRegions _resolveRegions(
    Rect contentRect,
    _AveluneHomeClassMetrics metrics,
  ) {
    var top = contentRect.top;

    Rect take(double heightFraction) {
      final region = Rect.fromLTWH(
        contentRect.left,
        top,
        contentRect.width,
        contentRect.height * heightFraction,
      );
      top = region.bottom;
      return region;
    }

    // Only the two bands above the furniture come from fractions; everything
    // below is derived from where the credenza puts its shelf board.
    return _AveluneHomeRegions(
      header: take(metrics.headerHeightFraction),
      scene: take(metrics.sceneHeightFraction),
    );
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
    headerHeightFraction: 0.10,
    sceneHeightFraction: 0.43,
    heroCartridgeHeight: 116,
    shelfCartridgeHeight: 104,
    shelfHorizontalPadding: 12,
    shelfBottomPadding: 12,
    shelfGap: 8,
    sceneHorizontalPadding: 20,
    sceneBottomPadding: 4,
    heroConsoleGap: 22,
    consoleSlotHeight: 6,
    insertionClearance: 3,
  );

  static const _regularMetrics = _AveluneHomeClassMetrics(
    headerHeightFraction: 0.09,
    sceneHeightFraction: 0.42,
    heroCartridgeHeight: 148,
    shelfCartridgeHeight: 120,
    shelfHorizontalPadding: 12,
    shelfBottomPadding: 14,
    shelfGap: 8,
    sceneHorizontalPadding: 12,
    sceneBottomPadding: 4,
    heroConsoleGap: 34,
    consoleSlotHeight: 6,
    insertionClearance: 4,
  );

  static const _largeMetrics = _AveluneHomeClassMetrics(
    headerHeightFraction: 0.085,
    sceneHeightFraction: 0.43,
    heroCartridgeHeight: 172,
    shelfCartridgeHeight: 128,
    shelfHorizontalPadding: 12,
    shelfBottomPadding: 16,
    shelfGap: 10,
    sceneHorizontalPadding: 12,
    sceneBottomPadding: 4,
    heroConsoleGap: 38,
    consoleSlotHeight: 6,
    insertionClearance: 4,
  );
}

@immutable
final class _AveluneHomeRegions {
  const _AveluneHomeRegions({required this.header, required this.scene});

  final Rect header;
  final Rect scene;
}

@immutable
final class _AveluneHomeClassMetrics {
  const _AveluneHomeClassMetrics({
    required this.headerHeightFraction,
    required this.sceneHeightFraction,
    required this.heroCartridgeHeight,
    required this.shelfCartridgeHeight,
    required this.shelfHorizontalPadding,
    required this.shelfBottomPadding,
    required this.shelfGap,
    required this.sceneHorizontalPadding,
    required this.sceneBottomPadding,
    required this.heroConsoleGap,
    required this.consoleSlotHeight,
    required this.insertionClearance,
  });

  final double headerHeightFraction;
  final double sceneHeightFraction;
  final double heroCartridgeHeight;
  final double shelfCartridgeHeight;
  final double shelfHorizontalPadding;
  final double shelfBottomPadding;
  final double shelfGap;
  final double sceneHorizontalPadding;
  final double sceneBottomPadding;
  /// Vertical room between the hero cartridge and the console. It also hosts
  /// the insertion hint, so it is wider than a pure visual gap.
  final double heroConsoleGap;
  final double consoleSlotHeight;
  final double insertionClearance;
}
