import '../models/game_state.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_map_view.dart';
import '../models/periodic_reward_reference.dart';
import '../models/project_manifest.dart';
import '../models/scene_asset.dart';
import '../read_models/periodic_reward_availability.dart';
import 'narrative_condition_expression_evaluator.dart';
import 'narrative_fact_runtime.dart';
import 'periodic_reward_condition_evaluator.dart';

typedef PresentationMapLookup =
    Iterable<NarrativeMapView> Function(String mapId);

final class PresentationConditionContext {
  PresentationConditionContext({
    required this.project,
    required this.map,
    this.maps = const [],
    this.lookupRewardScenes,
    this.lookupMaps,
  });

  final ProjectManifest project;
  final NarrativeMapView map;
  final List<NarrativeMapView> maps;
  final PeriodicRewardSceneLookup? lookupRewardScenes;
  final PresentationMapLookup? lookupMaps;
  late final _facts = NarrativeFactRuntimeResolver.fromFacts(project.facts);
  final _rewardScenes = <String, List<SceneAsset>>{};
  final _rewards =
      <PeriodicRewardReference, PeriodicRewardReferenceResolution>{};
  final _eventCounts = <String, int>{};
  final _mapCandidates = <String, List<NarrativeMapView>>{};
  final _eventOwners =
      <(String, String), ({NarrativeMapView? map, bool valid})>{};

  NarrativeConditionEvaluation evaluate(
    NarrativeEventConditionExpression expression,
    GameState gameState,
  ) => evaluateNarrativeConditionExpression(
    expression,
    evaluateLeaf: (condition) => condition.whenTyped(
      periodicRewardAvailable: (reference, expected) {
        final resolution = _rewards.putIfAbsent(
          reference,
          () => resolvePeriodicRewardReference(
            reference: reference,
            lookupScenes: (id) => _rewardScenes.putIfAbsent(
              id,
              () => List.unmodifiable(
                lookupRewardScenes?.call(id) ?? const <SceneAsset>[],
              ),
            ),
          ),
        );
        if (!resolution.isResolved) return _unavailable;
        final availability = readPeriodicRewardAvailability(
          calendar: gameState.gameplayCalendarState,
          rewardState: gameState.periodicRewardState,
          rewardId: reference.rewardId,
        );
        return NarrativeConditionEvaluation(
          passed: availability.matches(expectedValue: expected),
          unavailable: availability.value == null,
        );
      },
      fact: (id, operator, expected) {
        final resolution = _facts.resolve(
          factId: id,
          runtimeState: gameState.narrativeFactRuntimeState,
          storyFlags: gameState.storyFlags,
        );
        if (resolution is! NarrativeFactRuntimeResolved ||
            resolution.narrativeValue.kind != expected.kind) {
          return _unavailable;
        }
        return NarrativeConditionEvaluation(
          passed: resolution.narrativeValue.matches(operator, expected),
        );
      },
      narrativeEventConsumed: (id, expected) {
        final count = _eventCounts.putIfAbsent(
          id,
          () =>
              project.eventRegistry?.records
                  .where((record) => record.id == id)
                  .length ??
              0,
        );
        if (count != 1) return _unavailable;
        return NarrativeConditionEvaluation(
          passed:
              gameState.narrativeEventProgress.consumedNarrativeEventIds
                  .contains(id) ==
              expected,
        );
      },
      mapEventInstanceBoolean: (mapId, eventId, key, expected) {
        final candidates = mapId == map.id
            ? [map]
            : lookupMaps?.call(mapId) ??
                  _mapCandidates.putIfAbsent(
                    mapId,
                    () => maps
                        .where((candidate) => candidate.id == mapId)
                        .toList(),
                  );
        NarrativeMapView? owner;
        var count = 0;
        for (final candidate in candidates) {
          if (candidate.id != mapId) continue;
          owner = candidate;
          if (++count > 1) break;
        }
        if (count != 1) owner = null;
        var cached = _eventOwners[(mapId, eventId)];
        if (cached == null || !identical(cached.map, owner)) {
          cached = (
            map: owner,
            valid:
                owner != null &&
                owner.entities.where((entity) => entity.id == eventId).length ==
                    1,
          );
          _eventOwners[(mapId, eventId)] = cached;
        }
        final scope = gameState.mapInstanceWorldState.instanceRef(mapId);
        if (!cached.valid || scope == null) return _unavailable;
        return NarrativeConditionEvaluation(
          passed:
              gameState.mapInstanceWorldState.eventBoolean(
                scope,
                eventId,
                key,
              ) ==
              expected,
        );
      },
    ),
  );

  static const _unavailable = NarrativeConditionEvaluation(
    passed: false,
    unavailable: true,
  );
}
