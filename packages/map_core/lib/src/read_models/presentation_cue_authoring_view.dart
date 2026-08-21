import 'package:meta/meta.dart' show immutable;

import '../authoring/scene_authoring_operations.dart';
import '../models/presentation_interaction_outcome.dart';
import '../models/scene_asset.dart';

/// What an authoring surface needs to know about one interaction cue —
/// BETA-CIN-079.
///
/// A cue lives on a Presentation marker, but its link and its branches live
/// on the Scene side (the ownership boundary of BETA-CIN-068). This read
/// model resolves that crossing once, so the Studio panel and the timeline
/// read the same truth instead of each walking the graph their own way: the
/// bound node, its human label, the exact output ports the branches may
/// address, and the routes already authored.
@immutable
final class PresentationCueAuthoringView {
  const PresentationCueAuthoringView({
    required this.markerId,
    required this.sceneId,
    required this.presentationNodeId,
    required this.awaitableNodeId,
    required this.awaitableLabel,
    required this.awaitableKind,
    required this.outputPortIds,
    required this.routes,
  });

  final String markerId;
  final String sceneId;
  final String presentationNodeId;
  final String awaitableNodeId;

  /// The node's authored title when it has one, its id otherwise — never a
  /// synthesized sentence, so renaming a title never changes identity.
  final String awaitableLabel;
  final SceneNodeKind awaitableKind;

  /// The ports the bound node can terminate on: the only legal targets for a
  /// route, in the node's own declared order.
  final List<String> outputPortIds;
  final List<ScenePresentationCueOutcomeRoute> routes;

  /// The outcome authored for [outputPortId], or null when that port is left
  /// to the default continuation.
  ScenePresentationCueOutcomeRoute? routeFor(String outputPortId) => routes
      .where((route) => route.outputPortId == outputPortId)
      .firstOrNull;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationCueAuthoringView &&
          other.markerId == markerId &&
          other.sceneId == sceneId &&
          other.presentationNodeId == presentationNodeId &&
          other.awaitableNodeId == awaitableNodeId &&
          other.awaitableLabel == awaitableLabel &&
          other.awaitableKind == awaitableKind &&
          _sameStrings(other.outputPortIds, outputPortIds) &&
          _sameRoutes(other.routes, routes);

  @override
  int get hashCode => Object.hash(
        markerId,
        sceneId,
        presentationNodeId,
        awaitableNodeId,
        awaitableLabel,
        awaitableKind,
        Object.hashAll(outputPortIds),
        Object.hashAll(routes),
      );
}

/// Resolves every cue of [presentationCinematicId] that a Scene links,
/// keyed by marker id.
///
/// A marker absent from the result is simply not linked yet — the authoring
/// surface shows it as such instead of inventing an empty binding. When two
/// Scenes bind the same marker (which the Scene schema cannot prevent across
/// documents), the lowest scene id wins so the view stays deterministic.
Map<String, PresentationCueAuthoringView> buildPresentationCueAuthoringViews({
  required String presentationCinematicId,
  required Iterable<SceneAsset> scenes,
}) {
  final sorted = scenes.toList(growable: false)
    ..sort((left, right) => left.id.compareTo(right.id));
  final views = <String, PresentationCueAuthoringView>{};
  for (final scene in sorted) {
    for (final node in scene.graph.nodes) {
      final payload = node.payload;
      if (payload is! ScenePresentationCinematicPayload) continue;
      if (payload.presentationCinematicId != presentationCinematicId) continue;
      for (final binding in payload.interactionCueBindings) {
        if (views.containsKey(binding.markerId)) continue;
        final target = scene.graph.nodes
            .where((candidate) => candidate.id == binding.awaitableNodeId)
            .firstOrNull;
        if (target == null) continue;
        views[binding.markerId] = PresentationCueAuthoringView(
          markerId: binding.markerId,
          sceneId: scene.id,
          presentationNodeId: node.id,
          awaitableNodeId: binding.awaitableNodeId,
          awaitableLabel: switch (target.title?.trim()) {
            final String title when title.isNotEmpty => title,
            _ => target.id,
          },
          awaitableKind: target.kind,
          outputPortIds: scenePresentationCueOutputPortIds(
            scene,
            binding.awaitableNodeId,
          ),
          routes: binding.outcomeRoutes,
        );
      }
    }
  }
  return Map<String, PresentationCueAuthoringView>.unmodifiable(views);
}


/// One branch to draw on the marker track: where the cue sits, and where its
/// answer sends the playhead back (or forward) — BETA-CIN-079.
@immutable
final class PresentationCueBranchArc {
  const PresentationCueBranchArc({
    required this.outputPortId,
    required this.fromUs,
    required this.toUs,
  });

  final String outputPortId;
  final int fromUs;
  final int toUs;

  /// True when the answer sends the playhead backwards — the loop an author
  /// most needs to see.
  bool get isBackwards => toUs < fromUs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationCueBranchArc &&
          other.outputPortId == outputPortId &&
          other.fromUs == fromUs &&
          other.toUs == toUs;

  @override
  int get hashCode => Object.hash(outputPortId, fromUs, toUs);
}

/// The arcs of one cue, resolved against the marker positions of its
/// cinematic. Routes without a destination (continue, stop, cancel, fail)
/// draw nothing, and a destination the cinematic no longer holds is skipped
/// rather than drawn at zero.
List<PresentationCueBranchArc> presentationCueBranchArcs({
  required PresentationCueAuthoringView view,
  required Map<String, int> markerStartUsById,
}) {
  final fromUs = markerStartUsById[view.markerId];
  if (fromUs == null) return const <PresentationCueBranchArc>[];
  final arcs = <PresentationCueBranchArc>[];
  for (final route in view.routes) {
    final destination = switch (route.outcome) {
      PresentationSeekMarkerOutcome(:final markerId) => markerId,
      PresentationRepeatFromMarkerOutcome(:final markerId) => markerId,
      _ => null,
    };
    if (destination == null) continue;
    final toUs = markerStartUsById[destination];
    if (toUs == null) continue;
    arcs.add(
      PresentationCueBranchArc(
        outputPortId: route.outputPortId,
        fromUs: fromUs,
        toUs: toUs,
      ),
    );
  }
  return List<PresentationCueBranchArc>.unmodifiable(arcs);
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _sameRoutes(
  List<ScenePresentationCueOutcomeRoute> left,
  List<ScenePresentationCueOutcomeRoute> right,
) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
