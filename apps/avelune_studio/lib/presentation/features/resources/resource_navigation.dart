import 'package:flutter/foundation.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/decors/application/decor_draft.dart';
import 'package:avelune_studio/features/decors/application/decor_source_support.dart';
import 'package:avelune_studio/features/terrains/application/terrain_draft_controller.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_connections.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'resource_catalog.dart';

enum ResourcePage { library, decor, terrain }

class ResourceNavigation extends ChangeNotifier {
  ResourceNavigation({
    required this.workspace,
    required this.port,
    required this.visuals,
    required this.onUse,
  });
  final MapWorkspaceController workspace;
  final ResourcePort port;
  final MapWorkspaceVisuals visuals;
  final ValueChanged<ResourceItem> onUse;
  final library = ResourceLibraryState();
  final Map<String, DecorDraft> decors = {};
  final Map<String, TerrainDraftController> terrains = {};
  ResourcePage page = ResourcePage.library;
  DecorDraft? decor;
  TerrainDraftController? terrain;
  bool busy = false;
  String? error;
  bool get dirty => decors.isNotEmpty || terrains.values.any((t) => t.dirty);

  void openPage(ResourcePage next) {
    page = next;
    notifyListeners();
  }

  void showLibrary([ResourceItem? item]) {
    page = ResourcePage.library;
    if (item != null) {
      library.kind = item.kind;
      library.selectedId = item.id;
    }
    notifyListeners();
  }

  void openElement(ProjectElementEntry? element, {bool edit = false}) {
    final item = element == null
        ? null
        : ResourceItem(
            id: element.id,
            name: element.name,
            kind: ResourceKind.decors,
            element: element,
          );
    if (edit && item != null) {
      this.edit(item);
    } else {
      showLibrary(item);
    }
  }

  Future<bool> saveDrafts() async {
    if (busy) return false;
    busy = true;
    notifyListeners();
    try {
      for (final draft in decors.values.toList()) {
        final snapshot = draft.build();
        await accept(await port.saveElement(snapshot));
        if (draft.build() == snapshot) {
          decors.removeWhere((key, value) => identical(value, draft));
          if (identical(decor, draft)) decor = null;
        }
      }
      for (final draft in terrains.values.where((t) => t.dirty)) {
        if (!await draft.save(mutate, publish: false)) return false;
      }
      return !dirty;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<ProjectManifest> accept(ResourceMutationReceipt receipt) async {
    workspace.acceptResources(receipt.before, receipt.manifest);
    for (final model in terrains.values) {
      model.manifest = receipt.manifest;
    }
    if (visuals case final ResourceWorkspaceVisuals resources) {
      await resources.updateCatalog(
        receipt.manifest,
        changedRelativePaths: receipt.changedPaths.toSet(),
      );
    }
    notifyListeners();
    return receipt.manifest;
  }

  Future<ProjectManifest> mutate(
    String action,
    Map<String, Object?> parameters,
  ) async {
    final wasBusy = busy;
    busy = true;
    notifyListeners();
    try {
      return await accept(await port.mutate(action, parameters));
    } finally {
      busy = wasBusy;
      notifyListeners();
    }
  }

  Future<void> import(ResourceImageImport request) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final receipt = await port.importImage(request);
      final manifest = await accept(receipt);
      final tileset = manifest.tilesets.firstWhere(
        (t) => t.id == receipt.createdTilesetId,
      );
      edit(
        ResourceItem(
          id: tileset.id,
          name: tileset.name,
          kind: ResourceKind.images,
          tileset: tileset,
        ),
      );
    } catch (e) {
      error = e.toString();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void edit(ResourceItem item) {
    final project = workspace.project!;
    final tileset =
        item.tileset ??
        project.tilesets.firstWhere((t) => t.id == item.element!.tilesetId);
    if (item.element == null && !canCreateDecor(tileset, project)) {
      error = decorConversionProblem(tileset, project);
      showLibrary(item);
      return;
    }
    decor = decors.putIfAbsent(
      item.id,
      () => DecorDraft(tileset: tileset, original: item.element),
    );
    page = ResourcePage.decor;
    notifyListeners();
  }

  void prepareTerrain(ResourceItem item) {
    final tileset = item.tileset!;
    final id = 'terrain-${DateTime.now().microsecondsSinceEpoch}';
    terrain = terrains.putIfAbsent(
      item.id,
      () => TerrainDraftController(
        manifest: workspace.project!,
        atlas: terrainAtlas(tileset, 'atlas-$id'),
        id: id,
        name: tileset.name,
      ),
    );
    page = ResourcePage.terrain;
    notifyListeners();
  }

  void resumeTerrain(ProjectSmartTileAuthoringDraft draft) {
    terrain = terrains.putIfAbsent(
      draft.id,
      () => TerrainDraftController.resume(
        manifest: workspace.project!,
        draft: draft,
      ),
    );
    page = ResourcePage.terrain;
    notifyListeners();
  }

  Future<void> saveDecor(ProjectElementEntry element) async {
    busy = true;
    notifyListeners();
    try {
      final receipt = await port.saveElement(element);
      await accept(receipt);
      decors.removeWhere((k, v) => identical(v, decor));
      decor = null;
      final saved = receipt.manifest.elements.firstWhere(
        (e) => e.id == element.id,
      );
      onUse(
        ResourceItem(
          id: saved.id,
          name: saved.name,
          kind: ResourceKind.decors,
          element: saved,
        ),
      );
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
