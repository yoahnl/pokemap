import 'package:flutter/foundation.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/decors/application/decor_draft.dart';
import 'package:avelune_studio/features/decors/application/decor_source_support.dart';
import 'package:avelune_studio/features/terrains/application/terrain_draft_controller.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_connections.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_draft_compatibility.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import '../characters/character_studio_controller.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'resource_catalog.dart';
part 'resource_navigation_terrain.dart';

enum ResourcePage { library, decor, terrain, characters }

class ResourceNavigation extends ChangeNotifier with ResourceNavigationTerrain {
  ResourceNavigation({
    required this.workspace,
    required this.port,
    required this.visuals,
    required this.onUse,
  }) {
    characters.addListener(notifyListeners);
  }
  @override
  final MapWorkspaceController workspace;
  final ResourcePort port;
  final MapWorkspaceVisuals visuals;
  final ValueChanged<ResourceItem> onUse;
  final library = ResourceLibraryState();
  final Map<String, DecorDraft> decors = {};
  @override
  final Map<String, TerrainDraftController> terrains = {};
  late final CharacterStudioController characters = CharacterStudioController(
    project: () => workspace.project!,
    mutate: mutate,
  );
  @override
  ResourcePage page = ResourcePage.library;
  DecorDraft? decor;
  @override
  TerrainDraftController? terrain;
  bool busy = false;
  @override
  String? error;
  @override
  var _terrainSequence = 0;
  bool get dirty =>
      decors.isNotEmpty ||
      terrains.values.any((t) => t.dirty) ||
      characters.dirty;

  void setImportError(String message) {
    error = message;
    notifyListeners();
  }

  void setImportBusy(bool value) {
    busy = value;
    notifyListeners();
  }

  void openCharacters([String? characterId]) {
    if (characterId != null) characters.select(characterId);
    page = ResourcePage.characters;
    notifyListeners();
  }

  List<ProjectSmartTileAuthoringDraft> get terrainDrafts {
    final project = workspace.project!;
    final drafts = {
      for (final draft in project.smartTileCatalog.drafts) draft.id: draft,
      for (final model in terrains.values) model.draft.id: model.draft,
    };
    return drafts.values
        .where(
          (draft) => terrainDraftCompatibilityProblem(project, draft) == null,
        )
        .toList();
  }

  List<ProjectSmartTileAuthoringDraft> get pendingTerrainDrafts => terrainDrafts
      .where(
        (draft) =>
            !workspace.project!.smartTileCatalog.presets.any(
              (preset) => preset.id == draft.targetPresetId,
            ) ||
            terrains[draft.id]?.dirty == true,
      )
      .toList();

  bool canEditTerrain(ResourceItem item) =>
      item.terrain != null &&
      editableTerrainDraft(
            workspace.project!,
            item.terrain!,
            localDrafts: terrains.values.map((model) => model.draft),
          ) !=
          null;

  void openPage(ResourcePage next) {
    page = next;
    notifyListeners();
  }

  @override
  void showLibrary([ResourceItem? item]) {
    page = ResourcePage.library;
    if (item != null) {
      library.reveal(item);
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
            category: element.categoryId,
            tags: element.tags,
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
      if (!await characters.saveAll()) {
        error = characters.error;
        return false;
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
    characters.refreshClean();
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

  void completeTerrainPublication(ProjectSmartTilePreset preset) {
    final item = ResourceItem(
      id: preset.id,
      name: preset.name,
      kind: ResourceKind.terrains,
      terrain: preset,
      category: preset.categoryId,
      tags: preset.tags,
    );
    if (workspace.project!.maps.isEmpty) {
      showLibrary(item);
    } else {
      onUse(item);
    }
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

  @override
  void dispose() {
    characters.removeListener(notifyListeners);
    characters.dispose();
    super.dispose();
  }
}
