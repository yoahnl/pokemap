import 'package:map_core/map_core_domain.dart';

import 'project_library_editor.dart';
import 'resource_port.dart';

abstract interface class ProjectEnvironmentWorkshopPort {
  bool get environmentEditingAvailable;

  Future<ProjectLibraryEdit> publishEnvironment(
    EnvironmentPreset preset, {
    required String expectedRevision,
  });

  Future<ProjectLibraryEdit> reconcileEnvironment(
    EnvironmentPreset preset,
    ResourceMutationReceipt receipt,
  );
}
