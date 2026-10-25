import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../features/resources/application/resource_pack_transfer_controller.dart';
import '../../../features/resources/domain/resource_pack_port.dart';

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
import 'resource_terrain_management.dart';
import 'resource_border_management.dart';
import 'resource_character_management.dart';
import '../../../features/resources/domain/resource_mutation_preparation.dart';
import '../../../features/resources/domain/resource_lifecycle_port.dart';
import '../../../features/resources/domain/resource_usage_port.dart';
import '../../../features/map_workspace/domain/map_workspace_port.dart';
import '../../../features/resources/application/environment_draft.dart';
part 'resource_navigation_terrain.dart';
part 'resource_navigation_management.dart';
part 'resource_navigation_lifecycle.dart';
part 'resource_navigation_environment.dart';
part 'resource_navigation_saving.dart';

enum ResourcePage { library, decor, terrain, characters, environment }

class ResourceNavigation extends ChangeNotifier with ResourceNavigationTerrain {
  ResourceNavigation({
    required this.workspace,
    required this.port,
    required this.visuals,
    required this.onUse,
    this.additionalDraftOwners,
    this.openUsage,
    this.canOpenUsage,
    ResourcePackPort? packPort,
    PickResourcePack? packPicker,
    PickResourcePackLicenses? packLicensePicker,
    ResourcePackExportSink? packExportSink,
  }) {
    characters.addListener(notifyListeners);
    workspace.addListener(changed);
    if (packPort != null && packPicker != null) {
      packTransfer = ResourcePackTransferController(
        port: packPort,
        picker: packPicker,
        pickLicenses: packLicensePicker,
        exportSink: packExportSink,
        localDrafts: _packLocalDrafts,
        accept: (receipt) async {
          await accept(receipt);
        },
      );
      packTransfer!.addListener(_packChanged);
    } else {
      packTransfer = null;
    }
  }
  @override
  final MapWorkspaceController workspace;
  final ResourcePort port;
  final MapWorkspaceVisuals visuals;
  final ValueChanged<ResourceItem> onUse;
  final List<String> Function()? additionalDraftOwners;
  final Future<bool> Function(ResourceUsageEntry)? openUsage;
  final bool Function(ResourceUsageEntry)? canOpenUsage;
  ResourceMutationReceipt? pendingReceipt;
  late final ResourcePackTransferController? packTransfer;
  void _packChanged() {
    final transfer = packTransfer!;
    if (transfer.pendingReceipt != null) {
      pendingReceipt = transfer.pendingReceipt;
    }
    changed();
  }

  bool _disposed = false;
  int _libraryLoadRequest = 0;
  bool get isDisposed => _disposed;
  int _managementDialogs = 0;
  void changed() {
    if (!_disposed) notifyListeners();
  }

  String? Function(String blueprintId)? borderDrawingOwner;
  List<String> Function(String characterId)? additionalCharacterOwners;
  void Function(Set<String> dialogueIds)? characterSourcesChanged;
  String? Function(Set<String> dialogueIds)? characterSourceProblem;
  final Map<String, bool Function()> borderEditorOwners = {};
  final Map<String, ResourcePackBorderDraft Function()> packBorderDraftOwners =
      {};
  List<ResourcePackLocalDraft> _packLocalDrafts() => [
    for (final terrain in terrains.values)
      if (terrain.dirty || terrain.busy)
        ResourcePackLocalDraft(
          kind: 'smartTilePreset',
          id: terrain.draft.targetPresetId,
          label: terrain.draft.name,
          signature: jsonEncode(terrain.draft.toJson()),
          saving: terrain.busy,
        ),
    for (final owner in packBorderDraftOwners.entries)
      if (owner.value() case final state when state.dirty || state.saving)
        ResourcePackLocalDraft(
          kind: 'borderBlueprint',
          id: owner.key,
          label: state.request.name,
          signature: state.signature,
          saving: state.saving,
        ),
  ];
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
  EnvironmentDraft? environment;
  final environments = <String, EnvironmentDraft>{};
  Future<void> Function(EnvironmentPreset)? drawEnvironment;
  bool _ordinaryBusy = false;
  bool get busy =>
      _ordinaryBusy ||
      packTransfer?.operationActive == true ||
      packTransfer?.requiresReconciliation == true ||
      packTransfer?.requiresRecovery == true;
  set busy(bool value) => _ordinaryBusy = value;
  String? modelRemovalProblem(String modelId) {
    final owners = workspace.documents.values.where(
      (document) =>
          document.current.spatialScene?.instances.any(
            (instance) => instance.modelId == modelId,
          ) ??
          false,
    );
    return owners.isEmpty
        ? null
        : 'Ce modèle est encore utilisé dans une carte ouverte : ${owners.map((document) => document.current.name).join(', ')}.';
  }

  @override
  String? error;
  @override
  var _terrainSequence = 0;
  bool get dirty =>
      pendingReceipt != null ||
      decors.isNotEmpty ||
      terrains.values.any((t) => t.dirty) ||
      environments.values.any((draft) => draft.dirty) ||
      characters.dirty;

  void setImportError(String message) {
    error = message;
    notifyListeners();
  }

  void setImportBusy(bool value) {
    busy = value;
    notifyListeners();
  }

  Future<bool> loadFamily(ResourceLibraryFamily family) async {
    if (_disposed || workspace.isDisposed) return false;
    final request = ++_libraryLoadRequest;
    try {
      await workspace.ensureResourceKind(family.canonicalKind);
      if (_disposed || workspace.isDisposed || request != _libraryLoadRequest) {
        return false;
      }
      error = null;
      changed();
      return true;
    } catch (failure) {
      if (!_disposed && request == _libraryLoadRequest) {
        error = 'Cette famille ne peut pas être chargée : $failure';
        changed();
      }
      return false;
    }
  }

  Future<void> openCharacters([String? characterId]) async {
    if (_disposed || workspace.isDisposed) return;
    final request = ++_libraryLoadRequest;
    try {
      await workspace.ensureResourceKind('character');
      if (_disposed || workspace.isDisposed || request != _libraryLoadRequest) {
        return;
      }
      if (characterId != null) characters.select(characterId);
      page = ResourcePage.characters;
      error = null;
      changed();
    } catch (failure) {
      if (!_disposed && request == _libraryLoadRequest) {
        error = 'Les personnages ne peuvent pas être chargés : $failure';
        changed();
      }
    }
  }

  void openBorders() {
    library.selectFamily(ResourceLibraryFamily.borders);
    showLibrary();
  }

  List<ProjectSmartTileAuthoringDraft> get terrainDrafts {
    final project = workspace.project!;
    final drafts = {
      for (final draft in project.smartTileCatalog.drafts) draft.id: draft,
      for (final model in terrains.values) model.draft.id: model.draft,
    };
    return drafts.values.toList();
  }

  List<ProjectSmartTileAuthoringDraft> get pendingTerrainDrafts =>
      terrainDrafts;

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

  Future<ProjectManifest> accept(ResourceMutationReceipt receipt) =>
      _acceptResourceReceipt(this, receipt);

  Future<ProjectManifest> mutate(
    String action,
    Map<String, Object?> parameters,
  ) => _mutateResources(this, action, parameters);

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
      if (e is ResourceFailure && e.partialReceipt != null) {
        pendingReceipt = e.partialReceipt;
      }
      error = e.toString();
    } finally {
      busy = false;
      changed();
    }
  }

  void edit(ResourceItem item) {
    if (item.model3d != null) {
      library.selectFamily(ResourceLibraryFamily.models3d);
      showLibrary(item);
      return;
    }
    if (item.environment case final preset?) {
      openEnvironment(preset);
      return;
    }
    if (item.character != null) {
      openCharacters(item.id);
      return;
    }
    if (item.border != null) {
      openBorders();
      return;
    }
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
      item.identity,
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

  @override
  void dispose() {
    _disposed = true;
    workspace.removeListener(changed);
    characters.removeListener(notifyListeners);
    characters.dispose();
    packTransfer?.removeListener(_packChanged);
    packTransfer?.dispose();
    super.dispose();
  }
}
