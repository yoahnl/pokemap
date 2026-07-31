import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'map_lifecycle_actions.dart';
import 'map_lifecycle_adapter.dart';

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
    return MapMutationDispatcher([
      for (final descriptor in MapLifecycleActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: lifecycle.build,
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
