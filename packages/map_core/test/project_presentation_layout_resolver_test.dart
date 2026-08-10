import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectPresentationLayoutResolver', () {
    const resolver = ProjectPresentationLayoutResolver();

    test('classifies the acceptance viewport matrix deterministically', () {
      const cases = <(double, double, ProjectPresentationBreakpoint)>[
        (390, 844, ProjectPresentationBreakpoint.compact),
        (844, 390, ProjectPresentationBreakpoint.compact),
        (768, 1024, ProjectPresentationBreakpoint.regular),
        (1024, 768, ProjectPresentationBreakpoint.regular),
        (1280, 720, ProjectPresentationBreakpoint.expanded),
        (1920, 1080, ProjectPresentationBreakpoint.expanded),
        (2560, 1080, ProjectPresentationBreakpoint.expanded),
      ];

      for (final (width, height, expected) in cases) {
        expect(
          resolver.classify(width: width, height: height),
          expected,
          reason: '$width x $height',
        );
      }
    });

    test('locks both breakpoint boundaries at B-1, B and B+1', () {
      expect(
        resolver.classify(width: 599, height: 900),
        ProjectPresentationBreakpoint.compact,
      );
      expect(
        resolver.classify(width: 600, height: 480),
        ProjectPresentationBreakpoint.regular,
      );
      expect(
        resolver.classify(width: 601, height: 481),
        ProjectPresentationBreakpoint.regular,
      );
      expect(
        resolver.classify(width: 1199, height: 700),
        ProjectPresentationBreakpoint.regular,
      );
      expect(
        resolver.classify(width: 1200, height: 700),
        ProjectPresentationBreakpoint.expanded,
      );
      expect(
        resolver.classify(width: 1201, height: 701),
        ProjectPresentationBreakpoint.expanded,
      );
    });

    test('resolves the authored semantic variant and internal geometry', () {
      final layouts = suggestedProjectPresentationLayouts('cinematic');

      final resolved = resolver.resolve(
        layouts: layouts,
        role: ProjectPresentationSurfaceRole.title,
        width: 1920,
        height: 1080,
      );

      expect(resolved.breakpoint, ProjectPresentationBreakpoint.expanded);
      expect(resolved.variant.slot, ProjectPresentationLayoutSlot.bottomLeft);
      expect(resolved.maxWidthFactor, inInclusiveRange(.35, 1));
      expect(resolved.spacingScale, greaterThan(0));
      expect(resolved.additionalSafeAreaPadding, greaterThanOrEqualTo(0));
    });
  });
}
