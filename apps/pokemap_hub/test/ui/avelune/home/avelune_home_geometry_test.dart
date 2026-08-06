import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/src/ui/avelune/avelune_cartridge.dart';
import 'package:pokemap_hub/src/ui/avelune/home/avelune_home_geometry.dart';

void main() {
  group('AveluneHomeGeometry', () {
    test('classifies the six portrait reference viewports', () {
      for (final scenario in _referenceViewports) {
        final geometry = scenario.resolve();

        expect(
          geometry.sizeClass,
          scenario.expectedClass,
          reason: scenario.label,
        );
        expect(geometry.allowsVerticalScroll, isFalse, reason: scenario.label);
      }
    });

    test('partitions the Safe Area without overflow or overlap', () {
      for (final scenario in _referenceViewports) {
        final geometry = scenario.resolve();
        final regions = <Rect>[
          geometry.headerRect,
          geometry.sceneRect,
          geometry.shelfRect,
          geometry.activityRect,
          geometry.navigationRect,
        ];

        expect(
          geometry.contentRect,
          Rect.fromLTWH(
            scenario.safeArea.left,
            scenario.safeArea.top,
            scenario.size.width - scenario.safeArea.horizontal,
            scenario.size.height - scenario.safeArea.vertical,
          ),
          reason: scenario.label,
        );
        expect(regions.first.top, geometry.contentRect.top);
        expect(
            regions.last.bottom, closeTo(geometry.contentRect.bottom, 0.001));

        for (var index = 0; index < regions.length; index++) {
          final region = regions[index];
          expect(region.width, greaterThan(0), reason: scenario.label);
          expect(region.height, greaterThan(0), reason: scenario.label);
          expect(
            geometry.contentRect.contains(region.topLeft),
            isTrue,
            reason: '${scenario.label}: region $index top-left',
          );
          expect(
            region.right,
            lessThanOrEqualTo(geometry.contentRect.right),
            reason: scenario.label,
          );
          expect(
            region.bottom,
            lessThanOrEqualTo(geometry.contentRect.bottom + 0.001),
            reason: scenario.label,
          );

          if (index > 0) {
            final previous = regions[index - 1];
            expect(
              previous.bottom,
              closeTo(region.top, 0.001),
              reason: '${scenario.label}: regions $index',
            );
            expect(previous.overlaps(region), isFalse, reason: scenario.label);
          }
        }

        final allocatedHeight = regions.fold<double>(
          0,
          (sum, region) => sum + region.height,
        );
        expect(
          allocatedHeight,
          closeTo(geometry.contentRect.height, 0.001),
          reason: scenario.label,
        );
      }
    });

    test('uses one canonical cartridge ratio and one height per class', () {
      final geometriesByClass =
          <AveluneHomeSizeClass, List<AveluneHomeGeometry>>{};

      for (final scenario in _referenceViewports) {
        final geometry = scenario.resolve();
        geometriesByClass
            .putIfAbsent(geometry.sizeClass, () => <AveluneHomeGeometry>[])
            .add(geometry);

        expect(
          geometry.shelfCartridgeSize.aspectRatio,
          closeTo(kAveluneCartridgeAspectRatio, 0.001),
          reason: scenario.label,
        );
        expect(
          geometry.heroCartridgeSize.aspectRatio,
          closeTo(kAveluneCartridgeAspectRatio, 0.001),
          reason: scenario.label,
        );
        expect(
          geometry.heroCartridgeSize.height,
          greaterThan(geometry.shelfCartridgeSize.height),
          reason: '${scenario.label}: the hero is only a larger display size',
        );
        expect(
          geometry.estimatedVisibleShelfSlots,
          greaterThanOrEqualTo(scenario.minimumVisibleSlots),
          reason: scenario.label,
        );
        expect(
          geometry.shelfFirstCartridgeRect.bottom,
          closeTo(geometry.anchors.shelfBaseline.dy, 0.001),
          reason: scenario.label,
        );
        expect(
          geometry.shelfRect.contains(geometry.shelfFirstCartridgeRect.center),
          isTrue,
          reason: scenario.label,
        );
      }

      for (final entry in geometriesByClass.entries) {
        final shelfHeights = entry.value
            .map((geometry) => geometry.shelfCartridgeSize.height)
            .toSet();
        final heroHeights = entry.value
            .map((geometry) => geometry.heroCartridgeSize.height)
            .toSet();

        expect(shelfHeights, hasLength(1), reason: '${entry.key}: shelf');
        expect(heroHeights, hasLength(1), reason: '${entry.key}: hero');
      }
    });

    test('defines stable console, shelf, hero and insertion anchors', () {
      for (final scenario in _referenceViewports) {
        final geometry = scenario.resolve();
        final anchors = geometry.anchors;
        final insertion = anchors.insertion;

        expect(anchors.heroCenter, geometry.heroCartridgeRect.center);
        expect(anchors.consoleSlotCenter, geometry.consoleSlotRect.center);
        expect(geometry.sceneRect.contains(anchors.heroCenter), isTrue);
        expect(geometry.sceneRect.contains(anchors.consoleSlotCenter), isTrue);
        expect(geometry.heroCartridgeRect.left,
            greaterThanOrEqualTo(geometry.sceneRect.left));
        expect(geometry.heroCartridgeRect.right,
            lessThanOrEqualTo(geometry.sceneRect.right));
        expect(geometry.consoleRect.left,
            greaterThanOrEqualTo(geometry.sceneRect.left));
        expect(geometry.consoleRect.right,
            lessThanOrEqualTo(geometry.sceneRect.right));
        expect(geometry.consoleRect.bottom,
            lessThanOrEqualTo(geometry.sceneRect.bottom));
        expect(geometry.consoleSlotRect.left,
            greaterThanOrEqualTo(geometry.consoleRect.left));
        expect(geometry.consoleSlotRect.right,
            lessThanOrEqualTo(geometry.consoleRect.right));
        expect(geometry.consoleSlotRect.top,
            greaterThanOrEqualTo(geometry.consoleRect.top));
        expect(geometry.consoleSlotRect.bottom,
            lessThanOrEqualTo(geometry.consoleRect.bottom));
        expect(geometry.heroCartridgeRect.bottom,
            lessThan(geometry.consoleRect.top));
        expect(
            geometry.heroCartridgeRect.overlaps(geometry.consoleRect), isFalse);
        expect(insertion.startCenter, anchors.heroCenter);
        expect(insertion.alignedCenter.dx, anchors.consoleSlotCenter.dx);
        expect(insertion.latchedCenter.dx, anchors.consoleSlotCenter.dx);
        // Aligning is an anticipation beat: a small lift off the resting place
        // before the descent, not a move toward the slot.
        expect(insertion.alignedCenter.dy,
            lessThanOrEqualTo(insertion.startCenter.dy));
        expect(
            insertion.startCenter.dy - insertion.alignedCenter.dy,
            lessThanOrEqualTo(8));
        expect(insertion.latchedCenter.dy,
            greaterThan(insertion.alignedCenter.dy));
        expect(geometry.contentRect.contains(insertion.latchedCenter), isTrue);
      }
    });

    test('condenses secondary content by size class', () {
      for (final scenario in _referenceViewports) {
        final geometry = scenario.resolve();

        expect(
          geometry.activityRowCapacity,
          scenario.expectedActivityRows,
          reason: scenario.label,
        );
        expect(
          geometry.hidesNonEssentialMetadata,
          scenario.expectedClass == AveluneHomeSizeClass.compact,
          reason: scenario.label,
        );
      }
    });

    test('routes elevated text scale details to a sheet without scrolling', () {
      final standard = _referenceViewports[2].resolve();
      final enlarged = _referenceViewports[2].resolve(textScaleFactor: 1.6);

      expect(standard.routesExtendedContentToSheet, isFalse);
      expect(enlarged.routesExtendedContentToSheet, isTrue);
      expect(enlarged.hidesNonEssentialMetadata, isTrue);
      expect(enlarged.activityRowCapacity, 1);
      expect(enlarged.allowsVerticalScroll, isFalse);
      expect(enlarged.contentRect, standard.contentRect);
      expect(enlarged.navigationRect.bottom, standard.navigationRect.bottom);
    });

    test('rejects geometry that cannot produce non-negative regions', () {
      expect(
        () => AveluneHomeGeometry.resolve(
          viewportSize: Size.zero,
        ),
        throwsArgumentError,
      );
      expect(
        () => AveluneHomeGeometry.resolve(
          viewportSize: const Size(320, 568),
          safeArea: const EdgeInsets.fromLTRB(0, 300, 0, 300),
        ),
        throwsArgumentError,
      );
      expect(
        () => AveluneHomeGeometry.resolve(
          viewportSize: const Size(320, 568),
          safeArea: const EdgeInsets.only(left: -1),
        ),
        throwsArgumentError,
      );
      expect(
        () => AveluneHomeGeometry.resolve(
          viewportSize: const Size(320, 568),
          textScaleFactor: 0,
        ),
        throwsArgumentError,
      );
    });
  });
}

const _referenceViewports = <_ViewportScenario>[
  _ViewportScenario(
    label: 'iPhone compact 320x568',
    size: Size(320, 568),
    safeArea: EdgeInsets.fromLTRB(0, 20, 0, 0),
    expectedClass: AveluneHomeSizeClass.compact,
    minimumVisibleSlots: 3.25,
    expectedActivityRows: 1,
  ),
  _ViewportScenario(
    label: 'iPhone compact tall 375x667',
    size: Size(375, 667),
    safeArea: EdgeInsets.fromLTRB(0, 20, 0, 0),
    expectedClass: AveluneHomeSizeClass.compact,
    minimumVisibleSlots: 3.25,
    expectedActivityRows: 1,
  ),
  _ViewportScenario(
    label: 'iPhone regular 390x844',
    size: Size(390, 844),
    safeArea: EdgeInsets.fromLTRB(0, 47, 0, 34),
    expectedClass: AveluneHomeSizeClass.regular,
    minimumVisibleSlots: 4,
    expectedActivityRows: 2,
  ),
  _ViewportScenario(
    label: 'iPhone large 430x932',
    size: Size(430, 932),
    safeArea: EdgeInsets.fromLTRB(0, 47, 0, 34),
    expectedClass: AveluneHomeSizeClass.large,
    minimumVisibleSlots: 4.1,
    expectedActivityRows: 3,
  ),
  _ViewportScenario(
    label: 'Android regular 360x800',
    size: Size(360, 800),
    safeArea: EdgeInsets.fromLTRB(0, 24, 0, 24),
    expectedClass: AveluneHomeSizeClass.regular,
    minimumVisibleSlots: 3.5,
    expectedActivityRows: 2,
  ),
  _ViewportScenario(
    label: 'Android large 427x952',
    size: Size(427, 952),
    safeArea: EdgeInsets.fromLTRB(0, 32, 0, 24),
    expectedClass: AveluneHomeSizeClass.large,
    minimumVisibleSlots: 4.1,
    expectedActivityRows: 3,
  ),
];

final class _ViewportScenario {
  const _ViewportScenario({
    required this.label,
    required this.size,
    required this.safeArea,
    required this.expectedClass,
    required this.minimumVisibleSlots,
    required this.expectedActivityRows,
  });

  final String label;
  final Size size;
  final EdgeInsets safeArea;
  final AveluneHomeSizeClass expectedClass;
  final double minimumVisibleSlots;
  final int expectedActivityRows;

  AveluneHomeGeometry resolve({double textScaleFactor = 1}) =>
      AveluneHomeGeometry.resolve(
        viewportSize: size,
        safeArea: safeArea,
        textScaleFactor: textScaleFactor,
      );
}
