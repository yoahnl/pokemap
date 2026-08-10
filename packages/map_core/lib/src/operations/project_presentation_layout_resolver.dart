import '../models/project_presentation_layout_profile.dart';

const double projectPresentationCompactWidth = 600;
const double projectPresentationCompactHeight = 480;
const double projectPresentationExpandedWidth = 1200;
const double projectPresentationExpandedHeight = 700;

final class ProjectResolvedSurfaceLayout {
  const ProjectResolvedSurfaceLayout({
    required this.breakpoint,
    required this.variant,
    required this.maxWidthFactor,
    required this.spacingScale,
    required this.additionalSafeAreaPadding,
  });

  final ProjectPresentationBreakpoint breakpoint;
  final ProjectSurfaceLayoutVariant variant;
  final double maxWidthFactor;
  final double spacingScale;
  final double additionalSafeAreaPadding;
}

final class ProjectPresentationLayoutResolver {
  const ProjectPresentationLayoutResolver();

  ProjectPresentationBreakpoint classify({
    required double width,
    required double height,
  }) {
    if (width < projectPresentationCompactWidth ||
        height < projectPresentationCompactHeight) {
      return ProjectPresentationBreakpoint.compact;
    }
    if (width >= projectPresentationExpandedWidth &&
        height >= projectPresentationExpandedHeight) {
      return ProjectPresentationBreakpoint.expanded;
    }
    return ProjectPresentationBreakpoint.regular;
  }

  ProjectResolvedSurfaceLayout resolve({
    required ProjectPresentationLayoutsProfile layouts,
    required ProjectPresentationSurfaceRole role,
    required double width,
    required double height,
  }) {
    final breakpoint = classify(width: width, height: height);
    final variant = layouts.resolve(role).resolve(breakpoint);
    return ProjectResolvedSurfaceLayout(
      breakpoint: breakpoint,
      variant: variant,
      maxWidthFactor: _maxWidthFactor(variant.width, breakpoint),
      spacingScale: switch (variant.spacing) {
        ProjectPresentationSpacing.compact => .8,
        ProjectPresentationSpacing.normal => 1,
        ProjectPresentationSpacing.airy => 1.25,
      },
      additionalSafeAreaPadding: switch (variant.screenMargin) {
        ProjectPresentationScreenMargin.none => 0,
        ProjectPresentationScreenMargin.compact => 12,
        ProjectPresentationScreenMargin.comfortable => 24,
      },
    );
  }

  double _maxWidthFactor(
    ProjectPresentationContentWidth width,
    ProjectPresentationBreakpoint breakpoint,
  ) {
    if (breakpoint == ProjectPresentationBreakpoint.compact) {
      return switch (width) {
        ProjectPresentationContentWidth.narrow => .78,
        ProjectPresentationContentWidth.comfortable => .9,
        ProjectPresentationContentWidth.wide => 1,
      };
    }
    return switch (width) {
      ProjectPresentationContentWidth.narrow => .42,
      ProjectPresentationContentWidth.comfortable => .66,
      ProjectPresentationContentWidth.wide => .9,
    };
  }
}
