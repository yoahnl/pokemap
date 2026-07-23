import 'package:flutter/foundation.dart';

/// Selectable, project-level destinations exposed by Narrative Studio.
///
/// Maps is intentionally absent: it is a gateway to Map Editor, not a
/// Narrative Studio selection.
enum NarrativeStudioDestination {
  overview,
  storylines,
  scenes,
  events,
  cinematics,
  dialogues,
  facts,
  shops,
  worldRules,
  validator,
}

/// Typed routes nested below the stable product destinations.
///
/// `mapEvents` deliberately belongs to [NarrativeStudioDestination.events].
/// The physical Map Editor remains an external workspace and is not modeled
/// as a Narrative Studio destination.
enum NarrativeStudioChildRoute {
  overview,
  storylineLibrary,
  storylineStep,
  sceneBuilder,
  eventBuilder,
  mapEvents,
  cinematicLibrary,
  cinematicBuilder,
  cinematicLegacy,
  dialogueEditor,
  factsManager,
  shopBuilder,
  worldRulesManager,
  validatorDiagnostics,
}

enum NarrativeStudioAssetKind {
  storyline,
  chapter,
  step,
  scene,
  event,
  cinematic,
  dialogue,
  fact,
  shop,
  worldRule,
  map,
  diagnostic,
}

@immutable
final class NarrativeStudioAssetSelection {
  NarrativeStudioAssetSelection({
    required this.kind,
    required String assetId,
    String? parentId,
    String? rootId,
    String? focusId,
    String? sourceContext,
  })  : assetId = _requiredRouteToken(assetId, 'assetId'),
        parentId = _optionalRouteToken(parentId, 'parentId'),
        rootId = _optionalRouteToken(rootId, 'rootId'),
        focusId = _optionalRouteToken(focusId, 'focusId'),
        sourceContext = _optionalRouteToken(sourceContext, 'sourceContext');

  final NarrativeStudioAssetKind kind;
  final String assetId;
  final String? parentId;
  final String? rootId;
  final String? focusId;
  final String? sourceContext;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeStudioAssetSelection &&
          other.kind == kind &&
          other.assetId == assetId &&
          other.parentId == parentId &&
          other.rootId == rootId &&
          other.focusId == focusId &&
          other.sourceContext == sourceContext;

  @override
  int get hashCode => Object.hash(
        kind,
        assetId,
        parentId,
        rootId,
        focusId,
        sourceContext,
      );
}

/// Complete internal location for the Narrative Studio.
///
/// Construction is guarded so an incompatible child route or selected asset
/// fails closed instead of silently falling back to another workspace item.
@immutable
final class NarrativeStudioRouteLocation {
  NarrativeStudioRouteLocation._({
    required this.destination,
    required this.childRoute,
    this.selection,
  }) {
    if (!_childrenForDestination(destination).contains(childRoute)) {
      throw ArgumentError.value(
        childRoute,
        'childRoute',
        'Route incompatible with ${destination.name}',
      );
    }
    if (selection != null &&
        !_assetsForDestination(destination).contains(selection!.kind)) {
      throw ArgumentError.value(
        selection!.kind,
        'selection.kind',
        'Asset incompatible with ${destination.name}',
      );
    }
  }

  factory NarrativeStudioRouteLocation.overview({
    NarrativeStudioAssetSelection? selection,
  }) =>
      NarrativeStudioRouteLocation._(
        destination: NarrativeStudioDestination.overview,
        childRoute: NarrativeStudioChildRoute.overview,
        selection: selection,
      );

  factory NarrativeStudioRouteLocation.storylines({
    NarrativeStudioChildRoute childRoute =
        NarrativeStudioChildRoute.storylineLibrary,
    NarrativeStudioAssetSelection? selection,
  }) =>
      NarrativeStudioRouteLocation._(
        destination: NarrativeStudioDestination.storylines,
        childRoute: childRoute,
        selection: selection,
      );

  factory NarrativeStudioRouteLocation.scenes({
    NarrativeStudioAssetSelection? selection,
  }) =>
      NarrativeStudioRouteLocation._(
        destination: NarrativeStudioDestination.scenes,
        childRoute: NarrativeStudioChildRoute.sceneBuilder,
        selection: selection,
      );

  factory NarrativeStudioRouteLocation.events({
    NarrativeStudioChildRoute childRoute =
        NarrativeStudioChildRoute.eventBuilder,
    NarrativeStudioAssetSelection? selection,
  }) =>
      NarrativeStudioRouteLocation._(
        destination: NarrativeStudioDestination.events,
        childRoute: childRoute,
        selection: selection,
      );

  factory NarrativeStudioRouteLocation.cinematics({
    NarrativeStudioChildRoute childRoute =
        NarrativeStudioChildRoute.cinematicLibrary,
    NarrativeStudioAssetSelection? selection,
  }) =>
      NarrativeStudioRouteLocation._(
        destination: NarrativeStudioDestination.cinematics,
        childRoute: childRoute,
        selection: selection,
      );

  factory NarrativeStudioRouteLocation.dialogues({
    NarrativeStudioAssetSelection? selection,
  }) =>
      NarrativeStudioRouteLocation._(
        destination: NarrativeStudioDestination.dialogues,
        childRoute: NarrativeStudioChildRoute.dialogueEditor,
        selection: selection,
      );

  factory NarrativeStudioRouteLocation.facts({
    NarrativeStudioAssetSelection? selection,
  }) =>
      NarrativeStudioRouteLocation._(
        destination: NarrativeStudioDestination.facts,
        childRoute: NarrativeStudioChildRoute.factsManager,
        selection: selection,
      );

  factory NarrativeStudioRouteLocation.shops({
    NarrativeStudioAssetSelection? selection,
  }) =>
      NarrativeStudioRouteLocation._(
        destination: NarrativeStudioDestination.shops,
        childRoute: NarrativeStudioChildRoute.shopBuilder,
        selection: selection,
      );

  factory NarrativeStudioRouteLocation.worldRules({
    NarrativeStudioAssetSelection? selection,
  }) =>
      NarrativeStudioRouteLocation._(
        destination: NarrativeStudioDestination.worldRules,
        childRoute: NarrativeStudioChildRoute.worldRulesManager,
        selection: selection,
      );

  factory NarrativeStudioRouteLocation.validator({
    NarrativeStudioAssetSelection? selection,
  }) =>
      NarrativeStudioRouteLocation._(
        destination: NarrativeStudioDestination.validator,
        childRoute: NarrativeStudioChildRoute.validatorDiagnostics,
        selection: selection,
      );

  final NarrativeStudioDestination destination;
  final NarrativeStudioChildRoute childRoute;
  final NarrativeStudioAssetSelection? selection;

  NarrativeStudioRouteLocation withSelection(
    NarrativeStudioAssetSelection? selection,
  ) =>
      NarrativeStudioRouteLocation._(
        destination: destination,
        childRoute: childRoute,
        selection: selection,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeStudioRouteLocation &&
          other.destination == destination &&
          other.childRoute == childRoute &&
          other.selection == selection;

  @override
  int get hashCode => Object.hash(destination, childRoute, selection);
}

Set<NarrativeStudioChildRoute> _childrenForDestination(
  NarrativeStudioDestination destination,
) =>
    switch (destination) {
      NarrativeStudioDestination.overview => const {
          NarrativeStudioChildRoute.overview,
        },
      NarrativeStudioDestination.storylines => const {
          NarrativeStudioChildRoute.storylineLibrary,
          NarrativeStudioChildRoute.storylineStep,
        },
      NarrativeStudioDestination.scenes => const {
          NarrativeStudioChildRoute.sceneBuilder,
        },
      NarrativeStudioDestination.events => const {
          NarrativeStudioChildRoute.eventBuilder,
          NarrativeStudioChildRoute.mapEvents,
        },
      NarrativeStudioDestination.cinematics => const {
          NarrativeStudioChildRoute.cinematicLibrary,
          NarrativeStudioChildRoute.cinematicBuilder,
          NarrativeStudioChildRoute.cinematicLegacy,
        },
      NarrativeStudioDestination.dialogues => const {
          NarrativeStudioChildRoute.dialogueEditor,
        },
      NarrativeStudioDestination.facts => const {
          NarrativeStudioChildRoute.factsManager,
        },
      NarrativeStudioDestination.shops => const {
          NarrativeStudioChildRoute.shopBuilder,
        },
      NarrativeStudioDestination.worldRules => const {
          NarrativeStudioChildRoute.worldRulesManager,
        },
      NarrativeStudioDestination.validator => const {
          NarrativeStudioChildRoute.validatorDiagnostics,
        },
    };

Set<NarrativeStudioAssetKind> _assetsForDestination(
  NarrativeStudioDestination destination,
) =>
    switch (destination) {
      NarrativeStudioDestination.overview => const {},
      NarrativeStudioDestination.storylines => const {
          NarrativeStudioAssetKind.storyline,
          NarrativeStudioAssetKind.chapter,
          NarrativeStudioAssetKind.step,
        },
      NarrativeStudioDestination.scenes => const {
          NarrativeStudioAssetKind.scene,
        },
      NarrativeStudioDestination.events => const {
          NarrativeStudioAssetKind.event,
          NarrativeStudioAssetKind.map,
        },
      NarrativeStudioDestination.cinematics => const {
          NarrativeStudioAssetKind.cinematic,
        },
      NarrativeStudioDestination.dialogues => const {
          NarrativeStudioAssetKind.dialogue,
        },
      NarrativeStudioDestination.facts => const {
          NarrativeStudioAssetKind.fact,
        },
      NarrativeStudioDestination.shops => const {
          NarrativeStudioAssetKind.shop,
        },
      NarrativeStudioDestination.worldRules => const {
          NarrativeStudioAssetKind.worldRule,
        },
      NarrativeStudioDestination.validator => const {
          NarrativeStudioAssetKind.diagnostic,
        },
    };

String _requiredRouteToken(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, name, 'Must not be blank');
  }
  return normalized;
}

String? _optionalRouteToken(String? value, String name) {
  if (value == null) return null;
  return _requiredRouteToken(value, name);
}
