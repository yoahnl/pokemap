import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/map_workspace/application/map_relief_tool.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class MapBuilderReliefInspector extends StatelessWidget {
  const MapBuilderReliefInspector({
    super.key,
    required this.state,
    required this.profiles,
    required this.onProfile,
  });

  final MapReliefToolState state;
  final List<MapReliefProfile> profiles;
  final ValueChanged<MapReliefProfile> onProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final failure = state.loadFailure;
    return Column(
      key: const ValueKey('map-relief-inspector'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSection(
          title: l10n.reliefStyleTitle,
          children: [
            if (state.loading)
              StudioLoadingState(label: l10n.reliefStyleLoading)
            else if (failure != null)
              StudioNotice(
                l10n.reliefStyleLoadFailed('$failure'),
                isError: true,
              )
            else if (profiles.isEmpty)
              StudioNotice(l10n.reliefStyleEmpty)
            else
              for (final profile in profiles)
                StudioChoice(
                  key: ValueKey('map-relief-profile-${profile.id}'),
                  label: profile.name,
                  subtitle: profile.twoLevelId == null
                      ? l10n.reliefStyleOneLevel
                      : l10n.reliefStyleTwoLevels,
                  selected: profile.id == state.profileId,
                  onTap: () => onProfile(profile),
                ),
          ],
        ),
        const SizedBox(height: StudioSpacing.l),
        Text(
          l10n.reliefShortcuts,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

({String message, bool isError})? mapBuilderReliefNotice(
  AppLocalizations l10n,
  MapReliefOutcome? outcome,
) {
  final problem = outcome?.problem;
  if (problem != null) {
    return (message: _problem(l10n, problem, outcome!), isError: true);
  }
  final warnings = outcome?.warnings ?? const {};
  if (warnings.isEmpty) return null;
  return (
    message: [
      if (warnings.contains(MapReliefWarning.unreachable))
        l10n.reliefWarningUnreachable,
      if (warnings.contains(MapReliefWarning.exteriorDecoration))
        l10n.reliefWarningExterior,
    ].join(' · '),
    isError: false,
  );
}

String _problem(
  AppLocalizations l10n,
  MapReliefProblem problem,
  MapReliefOutcome outcome,
) => switch (problem) {
  MapReliefProblem.profileIncompatible
      when outcome.diagnostics.isNotEmpty && outcome.profileName != null =>
    l10n.reliefProblemProfileRefused(
      outcome.profileName!,
      _reason(l10n, outcome.diagnostics),
    ),
  MapReliefProblem.noProfile => l10n.reliefProblemNoProfile,
  MapReliefProblem.profileUnavailable => l10n.reliefProblemProfileUnavailable,
  MapReliefProblem.profileLeftHanded => l10n.reliefProblemLeftHanded,
  MapReliefProblem.profileLevels => l10n.reliefProblemProfileLevels,
  MapReliefProblem.levelInvalid => l10n.reliefProblemLevelInvalid,
  MapReliefProblem.stepNotLevel => l10n.reliefProblemStepNotLevel,
  MapReliefProblem.twoLevelMissing => l10n.reliefProblemTwoLevelMissing,
  MapReliefProblem.stepTooHigh => l10n.reliefProblemStepTooHigh,
  MapReliefProblem.ambiguous => l10n.reliefProblemAmbiguous,
  MapReliefProblem.narrowCorner => l10n.reliefProblemNarrowCorner,
  MapReliefProblem.profileIncompatible => l10n.reliefProblemProfileIncompatible,
  MapReliefProblem.surfaceLimit => l10n.reliefProblemSurfaceLimit,
  MapReliefProblem.footprintLimit => l10n.reliefProblemFootprintLimit,
  MapReliefProblem.rampConflict => l10n.reliefProblemRampConflict,
  MapReliefProblem.busy => l10n.reliefProblemBusy,
  MapReliefProblem.unknown => l10n.reliefProblemUnknown,
};

String _reason(AppLocalizations l10n, List<String> codes) {
  bool any(Iterable<String> wanted) => codes.any(wanted.contains);
  if (any(const ['border.spatial.face_base_mismatch'])) {
    return l10n.reliefReasonFaceBase;
  }
  if (any(const ['border.spatial.face_crown_mismatch'])) {
    return l10n.reliefReasonFaceCrown;
  }
  if (any(const [
    'border.spatial.face_on_land_side',
    'border.spatial.face_mass_on_land_side',
  ])) {
    return l10n.reliefReasonFaceSide;
  }
  if (any(const ['border.spatial.source_model_missing'])) {
    return l10n.reliefReasonModelMissing;
  }
  if (codes.any((code) => code.startsWith('border.spatial.ground_surface_'))) {
    return l10n.reliefReasonGroundSurface;
  }
  if (any(const [
    'border.spatial.required_roles_missing',
    'border.spatial.corner_turn_missing',
    'border.spatial.orientation_missing',
    'border.spatial.sequence_phase_missing',
    'border.spatial.sequence_orientation_missing',
    'border.spatial.sequence_corner_missing',
  ])) {
    return l10n.reliefReasonPieces;
  }
  return l10n.reliefReasonOther(codes.first);
}
