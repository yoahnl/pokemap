import 'dart:typed_data';

import 'package:map_core/map_core_domain.dart';

import 'project_library_editor.dart';
import 'resource_port.dart';

typedef ProjectCharacterWorkshopRead = ({
  ProjectManifest project,
  String revision,
});

typedef EditWorkshopCharacter = Future<bool> Function(
  String action,
  Map<String, Object?> parameters, {
  PickedProjectLibraryFile? image,
});

abstract interface class ProjectCharacterWorkshopPort {
  Future<ProjectCharacterWorkshopRead> readWorkshopCharacter(String id);

  Future<Uint8List?> readCharacterPortrait(String characterId, String stateId);

  Future<ResourceMutationReceipt> editWorkshopCharacter(
    String id,
    String action,
    Map<String, Object?> parameters, {
    required String expectedRevision,
    PickedProjectLibraryFile? image,
  });

  Future<void> reconcileWorkshopCharacter(
    String id,
    ResourceMutationReceipt receipt,
  );
}
