import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

enum PersonalizationLayoutKeyboardCommand {
  moveLeft,
  moveRight,
  moveUp,
  moveDown,
  grow,
  shrink,
  increaseMargin,
  decreaseMargin,
}

final class PersonalizationLayoutGestureRequest {
  const PersonalizationLayoutGestureRequest({
    required this.surface,
    required this.breakpoint,
    required this.profile,
    required this.moveDelta,
    this.resizeDelta = 0,
    this.textScale = 1,
  });

  final ProjectPresentationSurfaceRole surface;
  final ProjectPresentationBreakpoint breakpoint;
  final ProjectPresentationLayoutsProfile profile;
  final Offset moveDelta;
  final double resizeDelta;
  final double textScale;
}

final class PersonalizationLayoutKeyboardRequest {
  const PersonalizationLayoutKeyboardRequest({
    required this.surface,
    required this.breakpoint,
    required this.profile,
    required this.command,
    this.textScale = 1,
  });

  final ProjectPresentationSurfaceRole surface;
  final ProjectPresentationBreakpoint breakpoint;
  final ProjectPresentationLayoutsProfile profile;
  final PersonalizationLayoutKeyboardCommand command;
  final double textScale;
}

enum PersonalizationLayoutGestureStatus { accepted, noOp, rejected }

final class PersonalizationLayoutGesturePlan {
  const PersonalizationLayoutGesturePlan({
    required this.status,
    required this.profile,
    this.code,
  });

  final PersonalizationLayoutGestureStatus status;
  final ProjectPresentationLayoutsProfile profile;
  final String? code;

  bool get isAccepted => status == PersonalizationLayoutGestureStatus.accepted;
  bool get isNoOp => status == PersonalizationLayoutGestureStatus.noOp;
  bool get isRejected => status == PersonalizationLayoutGestureStatus.rejected;
}

final class PersonalizationLayoutGesturePlanner {
  const PersonalizationLayoutGesturePlanner();

  PersonalizationLayoutGesturePlan plan(
    PersonalizationLayoutGestureRequest request,
  ) {
    if (request.moveDelta.distance < .08 && request.resizeDelta.abs() < .08) {
      return _noOp(request.profile);
    }
    var variant = request.profile
        .resolve(request.surface)
        .resolve(request.breakpoint);
    if (request.moveDelta.distance >= .08) {
      variant = variant.copyWith(
        slot: _slotForDirection(
          request.surface,
          request.breakpoint,
          request.moveDelta,
          variant.slot,
        ),
      );
    }
    if (request.resizeDelta.abs() >= .08) {
      final width = _stepEnum(
        ProjectPresentationContentWidth.values,
        variant.width,
        request.resizeDelta > 0 ? 1 : -1,
      );
      if (_wouldOverflow(request.breakpoint, width, request.textScale)) {
        return _rejected(request.profile, 'layoutGestureOverflow');
      }
      variant = variant.copyWith(width: width);
    }
    final profile = _replaceVariant(
      request.profile,
      request.surface,
      request.breakpoint,
      variant,
    );
    return profile == request.profile ? _noOp(profile) : _accepted(profile);
  }

  PersonalizationLayoutGesturePlan planKeyboard(
    PersonalizationLayoutKeyboardRequest request,
  ) {
    final responsive = request.profile.resolve(request.surface);
    var variant = responsive.resolve(request.breakpoint);
    switch (request.command) {
      case PersonalizationLayoutKeyboardCommand.moveLeft:
      case PersonalizationLayoutKeyboardCommand.moveRight:
      case PersonalizationLayoutKeyboardCommand.moveUp:
      case PersonalizationLayoutKeyboardCommand.moveDown:
        variant = variant.copyWith(
          slot: _slotForDirection(
            request.surface,
            request.breakpoint,
            switch (request.command) {
              PersonalizationLayoutKeyboardCommand.moveLeft => const Offset(
                -1,
                0,
              ),
              PersonalizationLayoutKeyboardCommand.moveRight => const Offset(
                1,
                0,
              ),
              PersonalizationLayoutKeyboardCommand.moveUp => const Offset(
                0,
                -1,
              ),
              PersonalizationLayoutKeyboardCommand.moveDown => const Offset(
                0,
                1,
              ),
              _ => Offset.zero,
            },
            variant.slot,
          ),
        );
      case PersonalizationLayoutKeyboardCommand.grow:
      case PersonalizationLayoutKeyboardCommand.shrink:
        final width = _stepEnum(
          ProjectPresentationContentWidth.values,
          variant.width,
          request.command == PersonalizationLayoutKeyboardCommand.grow ? 1 : -1,
        );
        if (_wouldOverflow(request.breakpoint, width, request.textScale)) {
          return _rejected(request.profile, 'layoutGestureOverflow');
        }
        variant = variant.copyWith(width: width);
      case PersonalizationLayoutKeyboardCommand.increaseMargin:
      case PersonalizationLayoutKeyboardCommand.decreaseMargin:
        variant = variant.copyWith(
          screenMargin: _stepEnum(
            ProjectPresentationScreenMargin.values,
            variant.screenMargin,
            request.command ==
                    PersonalizationLayoutKeyboardCommand.increaseMargin
                ? 1
                : -1,
          ),
        );
    }
    final profile = _replaceVariant(
      request.profile,
      request.surface,
      request.breakpoint,
      variant,
    );
    return profile == request.profile ? _noOp(profile) : _accepted(profile);
  }

  bool _wouldOverflow(
    ProjectPresentationBreakpoint breakpoint,
    ProjectPresentationContentWidth width,
    double textScale,
  ) =>
      breakpoint == ProjectPresentationBreakpoint.compact &&
      width == ProjectPresentationContentWidth.wide &&
      textScale >= 2;

  ProjectPresentationLayoutSlot _slotForDirection(
    ProjectPresentationSurfaceRole surface,
    ProjectPresentationBreakpoint breakpoint,
    Offset delta,
    ProjectPresentationLayoutSlot current,
  ) {
    final supported = projectPresentationLayoutSlotsFor(surface, breakpoint);
    final preferred = delta.dx.abs() >= delta.dy.abs()
        ? delta.dx.isNegative
              ? <ProjectPresentationLayoutSlot>[
                  ProjectPresentationLayoutSlot.left,
                  ProjectPresentationLayoutSlot.leftPane,
                  ProjectPresentationLayoutSlot.bottomLeft,
                ]
              : <ProjectPresentationLayoutSlot>[
                  ProjectPresentationLayoutSlot.right,
                ]
        : delta.dy.isNegative
        ? <ProjectPresentationLayoutSlot>[
            ProjectPresentationLayoutSlot.topCenter,
          ]
        : <ProjectPresentationLayoutSlot>[
            ProjectPresentationLayoutSlot.bottomCenter,
          ];
    return preferred.where(supported.contains).firstOrNull ?? current;
  }

  T _stepEnum<T>(List<T> values, T current, int delta) {
    final index = (values.indexOf(current) + delta).clamp(0, values.length - 1);
    return values[index];
  }

  PersonalizationLayoutGesturePlan _accepted(
    ProjectPresentationLayoutsProfile profile,
  ) => PersonalizationLayoutGesturePlan(
    status: PersonalizationLayoutGestureStatus.accepted,
    profile: profile,
  );

  PersonalizationLayoutGesturePlan _noOp(
    ProjectPresentationLayoutsProfile profile,
  ) => PersonalizationLayoutGesturePlan(
    status: PersonalizationLayoutGestureStatus.noOp,
    profile: profile,
  );

  PersonalizationLayoutGesturePlan _rejected(
    ProjectPresentationLayoutsProfile profile,
    String code,
  ) => PersonalizationLayoutGesturePlan(
    status: PersonalizationLayoutGestureStatus.rejected,
    profile: profile,
    code: code,
  );
}

final class PersonalizationLayoutGestureSession {
  PersonalizationLayoutGestureSession({
    required this.planner,
    required this.surface,
    required this.breakpoint,
    required ProjectPresentationLayoutsProfile profile,
    this.textScale = 1,
  }) : _baseline = profile,
       previewProfile = profile;

  final PersonalizationLayoutGesturePlanner planner;
  final ProjectPresentationSurfaceRole surface;
  final ProjectPresentationBreakpoint breakpoint;
  final double textScale;
  final ProjectPresentationLayoutsProfile _baseline;
  ProjectPresentationLayoutsProfile previewProfile;

  bool get hasPendingChange => previewProfile != _baseline;

  PersonalizationLayoutGesturePlan previewMove(Offset normalizedDelta) {
    final plan = planner.plan(
      PersonalizationLayoutGestureRequest(
        surface: surface,
        breakpoint: breakpoint,
        profile: _baseline,
        moveDelta: normalizedDelta,
        textScale: textScale,
      ),
    );
    previewProfile = plan.profile;
    return plan;
  }

  ProjectPresentationLayoutsProfile commit() => previewProfile;

  ProjectPresentationLayoutsProfile cancel() {
    previewProfile = _baseline;
    return _baseline;
  }
}

ProjectPresentationLayoutsProfile _replaceVariant(
  ProjectPresentationLayoutsProfile profile,
  ProjectPresentationSurfaceRole surface,
  ProjectPresentationBreakpoint breakpoint,
  ProjectSurfaceLayoutVariant variant,
) {
  final responsive = profile.resolve(surface);
  final replacement = switch (breakpoint) {
    ProjectPresentationBreakpoint.compact => responsive.copyWith(
      compact: variant,
    ),
    ProjectPresentationBreakpoint.regular => responsive.copyWith(
      regular: variant,
    ),
    ProjectPresentationBreakpoint.expanded => responsive.copyWith(
      expanded: variant,
    ),
  };
  return switch (surface) {
    ProjectPresentationSurfaceRole.title ||
    ProjectPresentationSurfaceRole.titlePrompt => profile.copyWith(
      title: replacement,
    ),
    ProjectPresentationSurfaceRole.pauseMenu => profile.copyWith(
      pauseMenu: replacement,
    ),
    ProjectPresentationSurfaceRole.dialogue => profile.copyWith(
      dialogue: replacement,
    ),
    ProjectPresentationSurfaceRole.battleHud => profile.copyWith(
      battle: replacement,
    ),
    _ => throw ArgumentError.value(surface, 'surface'),
  };
}
