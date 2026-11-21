import 'package:map_core/map_core_domain.dart';

import 'resource_port.dart';

typedef ProjectModelWorkshopRead = ({
  ProjectModel3dEntry? model,
  String? revision,
});

typedef ProjectModelWorkshopSettings = ({
  bool? castsShadows,
  bool collisionChanged,
  Model3dBounds? collisionBounds,
  double? scale,
  Model3dVector3? pivot,
});

abstract interface class ProjectModelWorkshopPort {
  Future<ProjectModelWorkshopRead> readWorkshopModel(String modelId);

  Future<ResourceMutationReceipt> saveModelShadow(
    String modelId, {
    required bool castsShadows,
    required String expectedRevision,
  });

  Future<ResourceMutationReceipt> saveModelSettings(
    String modelId, {
    required ProjectModelWorkshopSettings settings,
    required String expectedRevision,
  });

  Future<void> reconcileModelShadow(ResourceMutationReceipt receipt);
}
