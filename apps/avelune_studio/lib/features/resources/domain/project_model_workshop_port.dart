import 'package:map_core/map_core_domain.dart';

import 'resource_port.dart';

typedef ProjectModelWorkshopRead = ({
  ProjectModel3dEntry? model,
  String? revision,
});

abstract interface class ProjectModelWorkshopPort {
  Future<ProjectModelWorkshopRead> readWorkshopModel(String modelId);

  Future<ResourceMutationReceipt> saveModelShadow(
    String modelId, {
    required bool castsShadows,
    required String expectedRevision,
  });

  Future<void> reconcileModelShadow(ResourceMutationReceipt receipt);
}
