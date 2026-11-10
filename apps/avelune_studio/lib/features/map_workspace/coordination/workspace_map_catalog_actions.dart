import 'package:map_core/map_core_domain.dart';

import '../application/map_workspace_controller.dart';
import '../application/editable_map_document.dart';
import '../domain/map_catalog_port.dart';

final _lifecycleOperations = Expando<bool>();

Future<bool> saveMapLifecycleTarget({
  required MapWorkspaceController controller,
  required ProjectMapEntry entry,
  required bool Function() isActive,
  required Future<bool> Function() confirmSave,
}) async {
  final document = controller.documents[entry.id];
  if (document?.dirty != true) return document?.saving != true;
  if (!await confirmSave() || !isActive() || controller.isDisposed) {
    return false;
  }
  return controller.save(document!);
}

Future<void> runMapLifecycleOperation({
  required MapWorkspaceController controller,
  required ProjectMapEntry entry,
  required bool Function() isActive,
  required Future<bool> Function() confirmSave,
  required Future<void> Function() operation,
}) async {
  if (_lifecycleOperations[controller] == true ||
      controller.catalogBusy ||
      controller.isDisposed) {
    return;
  }
  _lifecycleOperations[controller] = true;
  final project = controller.project;
  try {
    if (!await saveMapLifecycleTarget(
          controller: controller,
          entry: entry,
          isActive: isActive,
          confirmSave: confirmSave,
        ) ||
        !isActive() ||
        controller.isDisposed ||
        controller.project != project) {
      return;
    }
    await operation();
  } finally {
    _lifecycleOperations[controller] = false;
  }
}

class WorkspaceMapCreation {
  WorkspaceMapCreation(this.controller, {this.groupId, String? id})
    : id = id ?? 'studio_map_${DateTime.now().microsecondsSinceEpoch}',
      width = '${controller.project?.settings.defaultMapWidth ?? 20}',
      height = '${controller.project?.settings.defaultMapHeight ?? 15}';

  final MapWorkspaceController controller;
  final String id;
  String name = '', width, height;
  MapRole role = MapRole.exterior;
  String? groupId, tilesetId;
  bool published = false;
  bool get valid =>
      name.trim().isNotEmpty &&
      (int.tryParse(width) ?? 0) > 0 &&
      (int.tryParse(height) ?? 0) > 0;

  Future<String?> submit() async {
    if (controller.isDisposed) return 'Le projet a été fermé.';
    if (!published) {
      if (!valid) {
        return 'Un nom et des dimensions entières positives sont requis.';
      }
      final selectedTileset =
          controller.project?.settings.dimension == ProjectDimension.threeD
          ? null
          : tilesetId;
      final result = await controller.mutateCatalog('map.create', {
        'mapId': id,
        'name': name.trim(),
        'width': int.parse(width),
        'height': int.parse(height),
        'role': role.name,
        'groupId': ?groupId,
        'tilesetId': ?selectedTileset,
      });
      published = result.published || result.integrated;
      if (!result.integrated) {
        return published
            ? 'La carte est créée sur disque. ${result.error ?? ''} Réouvrez-la pour reprendre la relecture.'
            : result.error ?? 'La création a été refusée.';
      }
    } else if (controller.pendingCatalogReceipt != null) {
      final result = await controller.retryCatalogRefresh();
      if (!result.integrated) {
        return 'La carte est créée. ${result.error ?? 'Relecture impossible.'}';
      }
    }
    if (controller.isDisposed) {
      return 'La carte est créée, mais le projet a été fermé.';
    }
    final entry = controller.project?.maps
        .where((entry) => entry.id == id)
        .firstOrNull;
    if (entry == null) {
      return 'La carte est créée ; relisez le catalogue avant de la rouvrir.';
    }
    await controller.activate(entry);
    return controller.active?.base.mapId == id
        ? null
        : 'La carte est créée. ${controller.error ?? 'Ouverture impossible.'} Utilisez Réouvrir.';
  }
}

class WorkspaceMapRename {
  WorkspaceMapRename(this.controller, this.entry) : name = entry.name;
  final MapWorkspaceController controller;
  final ProjectMapEntry entry;
  String name;
  bool published = false;

  Future<String?> submit() async {
    final result = published
        ? await controller.retryCatalogRefresh()
        : await controller.mutateCatalog('map.update_metadata', {
            'mapId': entry.id,
            'name': name.trim(),
          });
    published = result.published;
    return result.integrated
        ? null
        : result.published
        ? 'Le titre est enregistré sur disque. ${result.error ?? ''} Relisez le catalogue.'
        : result.error ?? 'Le renommage a été refusé.';
  }
}

class WorkspaceMapPreparedMutation {
  WorkspaceMapPreparedMutation(this.controller, this.preparation);
  final MapWorkspaceController controller;
  final MapCatalogPreparation preparation;
  bool published = false;

  Future<MapCatalogResult> apply({bool confirmDestructive = false}) async {
    final result = published
        ? await controller.retryCatalogRefresh()
        : await controller.applyPreparedCatalog(
            preparation,
            confirmDestructive: confirmDestructive,
          );
    published = result.published;
    return result;
  }
}

class WorkspaceMapDuplicate {
  WorkspaceMapDuplicate(this.controller, this.preparation);
  final MapWorkspaceController controller;
  final MapCatalogPreparation preparation;
  bool published = false;
  String? createdId;

  Future<String?> submit({required String name, String? groupId}) async {
    if (!published) {
      final result = await controller.applyPreparedCatalog(
        preparation.withDuplicateDestination(
          name: name.trim(),
          groupId: groupId,
        ),
      );
      published = result.published;
      createdId = result.receipt?.createdMapId;
      if (!result.integrated) {
        return published
            ? 'La copie est créée sur disque. ${result.error ?? ''} Réouvrez cette copie.'
            : result.error ?? 'La duplication a été refusée.';
      }
    } else if (controller.pendingCatalogReceipt != null) {
      final result = await controller.retryCatalogRefresh();
      if (!result.integrated) return 'La copie existe. ${result.error ?? ''}';
    }
    if (controller.isDisposed) {
      return 'La copie existe ; le projet a été fermé.';
    }
    final copy = controller.project?.maps
        .where((entry) => entry.id == createdId)
        .firstOrNull;
    if (copy == null) {
      return 'La copie existe ; relisez le catalogue pour la retrouver.';
    }
    await controller.activate(copy);
    return controller.active?.base.mapId == copy.id
        ? null
        : 'La copie existe. ${controller.error ?? 'Ouverture impossible.'} Réouvrez-la.';
  }
}

Future<String?> saveWorkspaceMapMetadata({
  required MapWorkspaceController controller,
  required EditableMapDocument document,
  required Map<String, Object?> values,
}) async {
  if (document.dirty && !await controller.save(document)) {
    return 'La carte doit être enregistrée avant de modifier ses paramètres.';
  }
  final result = await controller.mutateCatalog('map.update_metadata', values);
  return result.integrated
      ? null
      : result.error ?? 'Les paramètres n’ont pas pu être enregistrés.';
}
