import 'package:map_core/map_core_domain.dart';

import 'project_library_editor.dart';
import 'resource_port.dart';

typedef ProjectDecorWorkshopRead = ({ProjectManifest project, String revision});

abstract interface class ProjectDecorWorkshopPort {
  bool get decorEditingAvailable;

  Future<ProjectDecorWorkshopRead> readWorkshopDecor(String kind, String id);

  Future<ProjectLibraryEdit> publishDecor(
    ProjectElementEntry decor, {
    required String expectedRevision,
  });

  Future<ProjectLibraryEdit> reconcileDecor(ResourceMutationReceipt receipt);
}
