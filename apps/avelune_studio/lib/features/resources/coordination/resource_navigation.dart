import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:avelune_studio/features/resources/coordination/resource_pack_transfer_controller.dart';
import 'package:avelune_studio/features/resources/domain/resource_pack_port.dart';

import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/decors/application/decor_draft.dart';
import 'package:avelune_studio/features/decors/application/decor_source_support.dart';
import 'package:avelune_studio/features/terrains/application/terrain_draft_controller.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_connections.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_draft_compatibility.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';

import 'package:avelune_studio/features/characters/coordination/character_studio_controller.dart';

import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';

import '../application/resource_containers.dart';

import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';
import 'package:avelune_studio/features/resources/coordination/resource_terrain_management.dart';
import 'package:avelune_studio/features/resources/coordination/resource_border_management.dart';
import 'package:avelune_studio/features/resources/coordination/resource_character_management.dart';
import 'package:avelune_studio/features/resources/domain/resource_mutation_preparation.dart';
import 'package:avelune_studio/features/resources/domain/resource_lifecycle_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_usage_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/resources/application/environment_draft.dart';
part 'resource_navigation_terrain.dart';
part 'resource_navigation_management.dart';
part 'resource_navigation_lifecycle.dart';
part 'resource_navigation_opening.dart';
part 'resource_navigation_receipts.dart';
part 'resource_navigation_environment.dart';
part 'resource_navigation_saving.dart';
part 'resource_navigation_management_publication.dart';
part 'resource_navigation_library_publication.dart';

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

  void _notifyListeners() => notifyListeners();

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
  ResourceItem? importedSource;
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

  Future<bool> loadFamily(ResourceLibraryFamily family) => _loadFamily(family);

  Future<void> openCharacters([String? characterId]) =>
      _openCharacters(characterId);

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
    if (!workspace.isDisposed &&
        !workspace.hasResourceKind(library.family.canonicalKind)) {
      unawaited(loadFamily(library.family));
    }
  }

  void openElement(ProjectElementEntry? element, {bool edit = false}) =>
      _openElement(element, edit: edit);

  Future<ProjectManifest> accept(ResourceMutationReceipt receipt) =>
      _acceptResourceReceipt(this, receipt);

  Future<ProjectManifest> mutate(
    String action,
    Map<String, Object?> parameters,
  ) => _mutateResources(this, action, parameters);

  Future<void> import(
    ResourceImageImport request, {
    ResourceImportIntent intent = ResourceImportIntent.decor,
  }) => _import(request, intent: intent);

  void edit(ResourceItem item) => _edit(item);

  void completeTerrainPublication(ProjectSmartTilePreset preset) =>
      _completeTerrainPublication(preset);

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
