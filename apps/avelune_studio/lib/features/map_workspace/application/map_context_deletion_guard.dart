import 'package:avelune_studio/features/map_workspace/application/map_context_menu_actions.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';

typedef MapContextDeletionGuard = String? Function(MapContextTarget target);

class MapGuardedContextActionContext extends MapContextActionContext {
  const MapGuardedContextActionContext({
    required super.document,
    required super.project,
    required super.position,
    required this.deletionGuard,
  });

  final MapContextDeletionGuard deletionGuard;
}

String? mapContextDeletionProblem(
  MapContextActionContext context,
  MapContextTarget target,
) => switch (context) {
  MapGuardedContextActionContext(:final deletionGuard) => deletionGuard(target),
  _ => null,
};
