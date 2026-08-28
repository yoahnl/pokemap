import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../assets/tileset_actions.dart';

final class EnvironmentPresetActions {
  const EnvironmentPresetActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    visualLibraryDescriptor(
      'environment.preset.upsert',
      'Create or replace one validated Environment preset',
      resourceKinds: const ['project', 'preset', 'element'],
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = VisualLibraryParameters(context.request.parameters);
    switch (context.request.actionId) {
      case 'environment.preset.upsert':
        parameters.allow(const {'preset'});
        final preset = decodeEnvironmentPreset(parameters.object('preset'));
        final next = upsertProjectEnvironmentPreset(
          context.snapshot.manifest,
          preset,
        );
        return buildVisualManifestDraft(
          context.snapshot,
          next,
          operation: 'environment.preset.upsert',
          path: '/environmentPresets/${preset.id}',
          after: encodeEnvironmentPreset(preset),
        );
      default:
        throw VisualLibraryException(
          'visual.action_unsupported',
          'The requested Environment preset action is unsupported.',
        );
    }
  }
}
