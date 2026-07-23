import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import 'narrative_studio_destination.dart';

@immutable
final class NarrativeStudioReturnExpectation {
  NarrativeStudioReturnExpectation({
    required this.location,
    this.scrollOffset,
    this.zoom,
    this.focusAnchorId,
  }) {
    if (scrollOffset != null &&
        (!scrollOffset!.isFinite || scrollOffset! < 0)) {
      throw ArgumentError.value(
        scrollOffset,
        'scrollOffset',
        'Must be finite and non-negative',
      );
    }
    if (zoom != null && (!zoom!.isFinite || zoom! <= 0)) {
      throw ArgumentError.value(
        zoom,
        'zoom',
        'Must be finite and strictly positive',
      );
    }
    if (focusAnchorId != null && focusAnchorId!.trim().isEmpty) {
      throw ArgumentError.value(
        focusAnchorId,
        'focusAnchorId',
        'Must not be blank',
      );
    }
  }

  final NarrativeStudioRouteLocation location;
  final double? scrollOffset;
  final double? zoom;
  final String? focusAnchorId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeStudioReturnExpectation &&
          other.location == location &&
          other.scrollOffset == scrollOffset &&
          other.zoom == zoom &&
          other.focusAnchorId == focusAnchorId;

  @override
  int get hashCode => Object.hash(location, scrollOffset, zoom, focusAnchorId);
}

@immutable
final class NarrativeStudioRestorationRequest {
  const NarrativeStudioRestorationRequest({
    required this.expectation,
    required this.revision,
  });

  final NarrativeStudioReturnExpectation expectation;
  final int revision;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeStudioRestorationRequest &&
          other.expectation == expectation &&
          other.revision == revision;

  @override
  int get hashCode => Object.hash(expectation, revision);
}

@immutable
final class NarrativeStudioNavigationState {
  const NarrativeStudioNavigationState({
    required this.location,
    this.projectIdentity,
    this.pendingReturn,
    this.restorationRequest,
    this.revision = 0,
  });

  factory NarrativeStudioNavigationState.initial() =>
      NarrativeStudioNavigationState(
        location: NarrativeStudioRouteLocation.overview(),
      );

  final NarrativeStudioRouteLocation location;
  final String? projectIdentity;
  final NarrativeStudioReturnExpectation? pendingReturn;
  final NarrativeStudioRestorationRequest? restorationRequest;
  final int revision;

  NarrativeStudioNavigationState copyWith({
    NarrativeStudioRouteLocation? location,
    String? projectIdentity,
    bool clearProjectIdentity = false,
    NarrativeStudioReturnExpectation? pendingReturn,
    bool clearPendingReturn = false,
    NarrativeStudioRestorationRequest? restorationRequest,
    bool clearRestorationRequest = false,
    int? revision,
  }) =>
      NarrativeStudioNavigationState(
        location: location ?? this.location,
        projectIdentity: clearProjectIdentity
            ? null
            : projectIdentity ?? this.projectIdentity,
        pendingReturn:
            clearPendingReturn ? null : pendingReturn ?? this.pendingReturn,
        restorationRequest: clearRestorationRequest
            ? null
            : restorationRequest ?? this.restorationRequest,
        revision: revision ?? this.revision,
      );
}

class NarrativeStudioNavigationController
    extends StateNotifier<NarrativeStudioNavigationState> {
  NarrativeStudioNavigationController()
      : super(NarrativeStudioNavigationState.initial());

  void replace(NarrativeStudioRouteLocation location) {
    state = state.copyWith(
      location: location,
      clearPendingReturn: true,
      clearRestorationRequest: true,
      revision: state.revision + 1,
    );
  }

  void navigate(
    NarrativeStudioRouteLocation location, {
    NarrativeStudioReturnExpectation? returnExpectation,
  }) {
    state = state.copyWith(
      location: location,
      pendingReturn: returnExpectation,
      clearPendingReturn: returnExpectation == null,
      clearRestorationRequest: true,
      revision: state.revision + 1,
    );
  }

  void rememberExternalReturn(NarrativeStudioReturnExpectation expectation) {
    state = state.copyWith(
      pendingReturn: expectation,
      clearRestorationRequest: true,
      revision: state.revision + 1,
    );
  }

  /// Resolves an NSC-01 dependency intent and applies internal deep links.
  ///
  /// External Map Editor targets are returned to the caller because opening a
  /// physical map requires editor services that deliberately stay outside
  /// this route-only controller.
  NarrativeStudioNavigationResolution navigateToDependency(
    NarrativeDependencyNavigationIntent intent, {
    NarrativeStudioReturnExpectation? returnExpectation,
  }) {
    final resolution = resolveNarrativeDependencyNavigationIntent(intent);
    final location = resolution.location;
    if (resolution.kind == NarrativeStudioNavigationResolutionKind.internal &&
        location != null) {
      navigate(location, returnExpectation: returnExpectation);
    }
    return resolution;
  }

  NarrativeStudioReturnExpectation? restoreReturn() {
    final expectation = state.pendingReturn;
    if (expectation == null) return null;
    final revision = state.revision + 1;
    final requiresViewportRestoration = expectation.scrollOffset != null ||
        expectation.zoom != null ||
        expectation.focusAnchorId != null;
    state = state.copyWith(
      location: expectation.location,
      clearPendingReturn: true,
      restorationRequest: requiresViewportRestoration
          ? NarrativeStudioRestorationRequest(
              expectation: expectation,
              revision: revision,
            )
          : null,
      clearRestorationRequest: !requiresViewportRestoration,
      revision: revision,
    );
    return expectation;
  }

  bool consumeRestoration(int revision) {
    if (state.restorationRequest?.revision != revision) return false;
    state = state.copyWith(clearRestorationRequest: true);
    return true;
  }

  void resetForProject(
    String? projectIdentity, {
    NarrativeStudioRouteLocation? initialLocation,
  }) {
    final normalized = projectIdentity?.trim();
    if (state.projectIdentity == normalized) return;
    state = NarrativeStudioNavigationState(
      location: initialLocation ?? NarrativeStudioRouteLocation.overview(),
      projectIdentity: normalized,
      revision: state.revision + 1,
    );
  }
}

final narrativeStudioNavigationControllerProvider = StateNotifierProvider<
    NarrativeStudioNavigationController, NarrativeStudioNavigationState>(
  (ref) => NarrativeStudioNavigationController(),
);

enum NarrativeStudioNavigationResolutionKind {
  internal,
  externalMap,
  unavailable,
}

@immutable
final class NarrativeStudioExternalMapTarget {
  const NarrativeStudioExternalMapTarget({
    required this.mapId,
    required this.sourceKind,
    required this.sourceId,
  });

  final String mapId;
  final String sourceKind;
  final String sourceId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeStudioExternalMapTarget &&
          other.mapId == mapId &&
          other.sourceKind == sourceKind &&
          other.sourceId == sourceId;

  @override
  int get hashCode => Object.hash(mapId, sourceKind, sourceId);
}

@immutable
final class NarrativeStudioNavigationResolution {
  const NarrativeStudioNavigationResolution.internal(this.location)
      : kind = NarrativeStudioNavigationResolutionKind.internal,
        externalMapTarget = null,
        reason = null;

  const NarrativeStudioNavigationResolution.externalMap(
    this.externalMapTarget,
  )   : kind = NarrativeStudioNavigationResolutionKind.externalMap,
        location = null,
        reason = null;

  const NarrativeStudioNavigationResolution.unavailable(this.reason)
      : kind = NarrativeStudioNavigationResolutionKind.unavailable,
        location = null,
        externalMapTarget = null;

  final NarrativeStudioNavigationResolutionKind kind;
  final NarrativeStudioRouteLocation? location;
  final NarrativeStudioExternalMapTarget? externalMapTarget;
  final String? reason;
}

NarrativeStudioNavigationResolution resolveNarrativeDependencyNavigationIntent(
  NarrativeDependencyNavigationIntent intent,
) {
  final id = _nonBlank(intent.assetId);
  if (id == null) {
    return const NarrativeStudioNavigationResolution.unavailable(
      'La cible narrative ne possède pas d’identifiant exploitable.',
    );
  }
  final parentId = _nonBlank(intent.parentId);
  final rootId = _nonBlank(intent.rootId);
  final context = _nonBlank(intent.context);
  NarrativeStudioAssetSelection selection(NarrativeStudioAssetKind kind) =>
      NarrativeStudioAssetSelection(
        kind: kind,
        assetId: id,
        parentId: parentId,
        rootId: rootId,
        sourceContext: context,
      );

  return switch (intent.kind) {
    NarrativeDependencyTargetKind.fact =>
      NarrativeStudioNavigationResolution.internal(
        NarrativeStudioRouteLocation.facts(
          selection: selection(NarrativeStudioAssetKind.fact),
        ),
      ),
    NarrativeDependencyTargetKind.badge =>
      const NarrativeStudioNavigationResolution.unavailable(
        'La bibliothèque des badges ne possède pas encore de route Narrative '
        'Studio dédiée.',
      ),
    NarrativeDependencyTargetKind.item =>
      const NarrativeStudioNavigationResolution.unavailable(
        'Le catalogue des objets ne possède pas encore de route Narrative '
        'Studio dédiée.',
      ),
    NarrativeDependencyTargetKind.eventV2 =>
      NarrativeStudioNavigationResolution.internal(
        NarrativeStudioRouteLocation.events(
          selection: selection(NarrativeStudioAssetKind.event),
        ),
      ),
    NarrativeDependencyTargetKind.scene =>
      NarrativeStudioNavigationResolution.internal(
        NarrativeStudioRouteLocation.scenes(
          selection: selection(NarrativeStudioAssetKind.scene),
        ),
      ),
    NarrativeDependencyTargetKind.dialogue =>
      NarrativeStudioNavigationResolution.internal(
        NarrativeStudioRouteLocation.dialogues(
          selection: selection(NarrativeStudioAssetKind.dialogue),
        ),
      ),
    NarrativeDependencyTargetKind.cinematic =>
      NarrativeStudioNavigationResolution.internal(
        NarrativeStudioRouteLocation.cinematics(
          childRoute: NarrativeStudioChildRoute.cinematicBuilder,
          selection: selection(NarrativeStudioAssetKind.cinematic),
        ),
      ),
    NarrativeDependencyTargetKind.media =>
      NarrativeStudioNavigationResolution.internal(
        NarrativeStudioRouteLocation.cinematics(),
      ),
    NarrativeDependencyTargetKind.storyline =>
      NarrativeStudioNavigationResolution.internal(
        NarrativeStudioRouteLocation.storylines(
          selection: selection(NarrativeStudioAssetKind.storyline),
        ),
      ),
    NarrativeDependencyTargetKind.chapter =>
      NarrativeStudioNavigationResolution.internal(
        NarrativeStudioRouteLocation.storylines(
          selection: selection(NarrativeStudioAssetKind.chapter),
        ),
      ),
    NarrativeDependencyTargetKind.step =>
      NarrativeStudioNavigationResolution.internal(
        NarrativeStudioRouteLocation.storylines(
          selection: selection(NarrativeStudioAssetKind.step),
        ),
      ),
    NarrativeDependencyTargetKind.worldRule =>
      NarrativeStudioNavigationResolution.internal(
        NarrativeStudioRouteLocation.worldRules(
          selection: selection(NarrativeStudioAssetKind.worldRule),
        ),
      ),
    NarrativeDependencyTargetKind.sourceMap => _resolveExternalMap(intent, id),
  };
}

NarrativeStudioNavigationResolution resolveNarrativeProjectDiagnostic(
  NarrativeProjectDiagnostic diagnostic,
) {
  NarrativeStudioAssetSelection? selected(
    NarrativeStudioAssetKind kind,
    String? assetId, {
    String? parentId,
    String? rootId,
  }) {
    final id = _nonBlank(assetId);
    if (id == null) return null;
    return NarrativeStudioAssetSelection(
      kind: kind,
      assetId: id,
      parentId: _nonBlank(parentId),
      rootId: _nonBlank(rootId),
      sourceContext: _nonBlank(diagnostic.path),
    );
  }

  NarrativeStudioNavigationResolution missing(String label) =>
      NarrativeStudioNavigationResolution.unavailable(
        'Le diagnostic ne précise pas la cible $label.',
      );

  switch (diagnostic.destination) {
    case NarrativeProjectDiagnosticDestination.overview:
      return NarrativeStudioNavigationResolution.internal(
        NarrativeStudioRouteLocation.overview(),
      );
    case NarrativeProjectDiagnosticDestination.map:
      final mapId = _nonBlank(diagnostic.mapId);
      return mapId == null
          ? missing('map')
          : NarrativeStudioNavigationResolution.externalMap(
              NarrativeStudioExternalMapTarget(
                mapId: mapId,
                sourceKind: 'map',
                sourceId: mapId,
              ),
            );
    case NarrativeProjectDiagnosticDestination.event:
      final selection = selected(
        NarrativeStudioAssetKind.event,
        diagnostic.eventId,
        parentId: diagnostic.mapId,
      );
      return selection == null
          ? missing('événement')
          : NarrativeStudioNavigationResolution.internal(
              NarrativeStudioRouteLocation.events(selection: selection),
            );
    case NarrativeProjectDiagnosticDestination.scene:
      final selection = selected(
        NarrativeStudioAssetKind.scene,
        diagnostic.sceneId,
      );
      return selection == null
          ? missing('scène')
          : NarrativeStudioNavigationResolution.internal(
              NarrativeStudioRouteLocation.scenes(selection: selection),
            );
    case NarrativeProjectDiagnosticDestination.storyline:
      final selection = diagnostic.stepId != null
          ? selected(
              NarrativeStudioAssetKind.step,
              diagnostic.stepId,
              parentId: diagnostic.chapterId,
              rootId: diagnostic.storylineId,
            )
          : diagnostic.chapterId != null
              ? selected(
                  NarrativeStudioAssetKind.chapter,
                  diagnostic.chapterId,
                  parentId: diagnostic.storylineId,
                )
              : selected(
                  NarrativeStudioAssetKind.storyline,
                  diagnostic.storylineId,
                );
      return selection == null
          ? missing('storyline')
          : NarrativeStudioNavigationResolution.internal(
              NarrativeStudioRouteLocation.storylines(
                childRoute: NarrativeStudioChildRoute.storylineLibrary,
                selection: selection,
              ),
            );
    case NarrativeProjectDiagnosticDestination.dialogue:
      final selection = selected(
        NarrativeStudioAssetKind.dialogue,
        diagnostic.dialogueId,
        parentId: diagnostic.sceneId,
      );
      return selection == null
          ? missing('dialogue')
          : NarrativeStudioNavigationResolution.internal(
              NarrativeStudioRouteLocation.dialogues(selection: selection),
            );
    case NarrativeProjectDiagnosticDestination.cinematic:
      final selection = selected(
        NarrativeStudioAssetKind.cinematic,
        diagnostic.cinematicId,
      );
      return selection == null
          ? missing('cinématique')
          : NarrativeStudioNavigationResolution.internal(
              NarrativeStudioRouteLocation.cinematics(
                childRoute: NarrativeStudioChildRoute.cinematicBuilder,
                selection: selection,
              ),
            );
    case NarrativeProjectDiagnosticDestination.fact:
      final selection = selected(
        NarrativeStudioAssetKind.fact,
        diagnostic.factId,
      );
      return selection == null
          ? missing('fact')
          : NarrativeStudioNavigationResolution.internal(
              NarrativeStudioRouteLocation.facts(selection: selection),
            );
    case NarrativeProjectDiagnosticDestination.worldRule:
      final selection = selected(
        NarrativeStudioAssetKind.worldRule,
        diagnostic.worldRuleId,
      );
      return selection == null
          ? missing('règle du monde')
          : NarrativeStudioNavigationResolution.internal(
              NarrativeStudioRouteLocation.worldRules(selection: selection),
            );
  }
}

NarrativeStudioNavigationResolution _resolveExternalMap(
  NarrativeDependencyNavigationIntent intent,
  String sourceId,
) {
  if (intent.scope != 'map') {
    return const NarrativeStudioNavigationResolution.unavailable(
      'La référence ne désigne pas une source physique ouvrable dans une map.',
    );
  }
  final mapId = _nonBlank(intent.mapId) ?? _nonBlank(intent.parentId);
  final sourceKind = _nonBlank(intent.sourceKind);
  if (mapId == null || sourceKind == null) {
    return const NarrativeStudioNavigationResolution.unavailable(
      'La référence ne désigne pas une source physique ouvrable dans une map.',
    );
  }
  return NarrativeStudioNavigationResolution.externalMap(
    NarrativeStudioExternalMapTarget(
      mapId: mapId,
      sourceKind: sourceKind,
      sourceId: sourceId,
    ),
  );
}

String? _nonBlank(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
