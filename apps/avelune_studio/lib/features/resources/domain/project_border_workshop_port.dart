import 'package:map_core/map_core_domain.dart';

import 'resource_port.dart';

typedef ProjectBorderWorkshopRead = ({
  ProjectManifest project,
  String revision,
});

final class BorderWorkshopReopenRequired implements Exception {
  const BorderWorkshopReopenRequired();

  static const message =
      'Le catalogue a changé depuis l’enregistrement. Rouvrez le projet pour reprendre.';
}

abstract interface class ProjectBorderWorkshopPort {
  bool get canEditBorderWorkshop;

  Future<ProjectBorderWorkshopRead> readWorkshopBorder(String borderId);

  Future<ResourceMutationReceipt> saveBorderDraft(
    String borderId, {
    required BorderBlueprintDraft draft,
    required String expectedRevision,
  });

  Future<ResourceMutationReceipt> publishBorderDraft(
    String borderId, {
    required String expectedRevision,
  });

  Future<void> reconcileBorderWorkshop(
    String borderId,
    ResourceMutationReceipt receipt,
  );
}
