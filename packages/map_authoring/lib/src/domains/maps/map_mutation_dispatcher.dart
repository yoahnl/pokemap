import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'autotile_actions.dart';
import 'border_actions.dart';
import 'collision_actions.dart';
import 'entity_actions.dart';
import 'environment_actions.dart';
import 'map_lifecycle_actions.dart';
import 'map_lifecycle_adapter.dart';
import 'map_operations_batch.dart';
import 'path_actions.dart';
import 'placed_element_actions.dart';
import 'surface_actions.dart';
import 'terrain_actions.dart';
import 'trigger_zone_actions.dart';
import 'warp_connection_actions.dart';

typedef MapMutationDraftBuilder = AuthoringMutationDraft Function(
  AuthoringPlanningContext context,
);

final class MapMutationActionRegistration {
  const MapMutationActionRegistration({
    required this.descriptor,
    required this.build,
  });

  final AuthoringActionDescriptor descriptor;
  final MapMutationDraftBuilder build;
}

/// Deterministic action-to-domain-handler registry used by direct and JSONL APIs.
final class MapMutationDispatcher {
  MapMutationDispatcher(Iterable<MapMutationActionRegistration> registrations)
      : _registrations = _validatedRegistrations(registrations);

  factory MapMutationDispatcher.canonical() {
    const lifecycle = MapLifecycleActions();
    const operations = MapOperationsActions();
    const terrain = TerrainActions();
    const path = PathActions();
    const surface = SurfaceActions();
    const autotile = AutotileActions();
    const border = BorderActions();
    const collision = CollisionActions();
    const entity = EntityActions();
    const environment = EnvironmentActions();
    const placedElement = PlacedElementActions();
    const triggerZone = TriggerZoneActions();
    const warpConnection = WarpConnectionActions();
    return MapMutationDispatcher([
      for (final descriptor in MapLifecycleActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: lifecycle.build,
        ),
      for (final descriptor in MapOperationsActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: operations.build,
        ),
      for (final descriptor in TerrainActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: terrain.build,
        ),
      for (final descriptor in PathActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: path.build,
        ),
      for (final descriptor in SurfaceActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: surface.build,
        ),
      for (final descriptor in AutotileActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: autotile.build,
        ),
      for (final descriptor in BorderActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: border.build,
        ),
      for (final descriptor in CollisionActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: collision.build,
        ),
      for (final descriptor in EntityActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: entity.build,
        ),
      for (final descriptor in EnvironmentActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: environment.build,
        ),
      for (final descriptor in PlacedElementActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: placedElement.build,
        ),
      for (final descriptor in TriggerZoneActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: triggerZone.build,
        ),
      for (final descriptor in WarpConnectionActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: warpConnection.build,
        ),
    ]);
  }

  final Map<String, MapMutationActionRegistration> _registrations;

  List<AuthoringActionDescriptor> get descriptors => List.unmodifiable(
        _registrations.values.map((registration) => registration.descriptor),
      );

  AuthoringActionDescriptor descriptor(String actionId) =>
      _registration(actionId).descriptor;

  AuthoringMutationDraft build(AuthoringPlanningContext context) =>
      _registration(context.request.actionId).build(context);

  MapMutationActionRegistration _registration(String actionId) {
    final registration = _registrations[actionId];
    if (registration == null) {
      throw MapAuthoringException(
        code: 'map.action_unsupported',
        message: 'The requested map authoring action is unsupported.',
        details: {'actionId': actionId},
      );
    }
    return registration;
  }
}

Map<String, MapMutationActionRegistration> _validatedRegistrations(
  Iterable<MapMutationActionRegistration> values,
) {
  final registrations = <String, MapMutationActionRegistration>{};
  for (final registration in values) {
    final previous = registrations[registration.descriptor.id];
    if (previous != null) {
      throw ArgumentError.value(
        registration.descriptor.id,
        'registrations',
        'map mutation action IDs must be unique',
      );
    }
    registrations[registration.descriptor.id] = registration;
  }
  final ordered = registrations.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return Map.unmodifiable(Map.fromEntries(ordered));
}
