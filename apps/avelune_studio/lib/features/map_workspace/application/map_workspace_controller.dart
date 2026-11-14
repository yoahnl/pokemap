import '../domain/spatial_model_visibility_port.dart';
import '../../project_visuals/application/project_visuals_controller.dart';

import '../../project_visuals/domain/project_visuals_port.dart';
import 'map_atmosphere_controller.dart';
import 'map_exterior_decoration_controller.dart';
import 'map_editor_controller.dart';

import 'dart:async';

import '../domain/map_editor_port.dart';
import '../domain/spatial_field_obstacle_port.dart';
import '../domain/field_traversal_zone_port.dart';
import 'package:map_authoring/map_authoring_editing.dart' show SpatialMapActions, EnvironmentEditing;
import 'package:map_authoring/map_authoring.dart' show TriggerZoneActions;
import '../domain/map_atmosphere_port.dart';
import '../domain/map_exterior_decoration_port.dart';

import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_catalog_port.dart';

part 'map_workspace_catalog_commands.dart';
part 'map_workspace_catalog_preparation.dart';
part 'map_workspace_history_destinations.dart';
part 'map_workspace_resource_references.dart';
part 'map_workspace_element_order.dart';
part 'map_workspace_field_obstacles.dart';
part 'map_workspace_model_visibility.dart';
part 'map_workspace_field_traversals.dart';
part 'map_workspace_model_projection.dart';
part 'map_workspace_accepted_resources.dart';
part 'map_workspace_visual_settings.dart';
part 'map_workspace_workshops.dart';
part 'map_workspace_resource_kinds.dart';
part 'map_workspace_map_loading.dart';
part 'map_workspace_external_states.dart';
part 'map_workspace_external_mutations.dart';
part 'map_workspace_saving.dart';

class MapWorkspaceController {
  MapWorkspaceController(this.session, this.port, {this.catalogPort})
    : projectScope =
          session.storage == ProjectSessionStorage.workingCatalog &&
              port is MapWorkspaceScopedPort
          ? MapWorkspaceProjectScope.catalogMetadata
          : MapWorkspaceProjectScope.completeProject;

  final ProjectSession session;
  final MapWorkspacePort port;
  final MapCatalogPort? catalogPort;
  final Map<String, EditableMapDocument> documents = {};
  final Map<String, Future<EditableMapDocument>> _loading = {};
  final Map<String, Future<MapData?>> _previews = {};
  final Map<String, ProjectManifest> _previewDefinitions = {};
  ProjectManifest? previewDefinitionsFor(String mapId) => _previewDefinitions[mapId];
  final Map<String, EditableMapDocument> retiredDocuments = {};
  final _elementOrderReceipts =
      <String, Map<Object, MapElementOrderWorkspaceReceipt>>{};
  final _modelVisibilityReceipts =
      <String, Map<Object, SpatialModelVisibilityReceipt>>{};
  final _fieldObstacleReceipts = <String, Map<Object, SpatialFieldObstacleReceipt>>{};
  final _fieldTraversalReceipts = <String, Map<Object, FieldTraversalZoneReceipt>>{};
  bool catalogBusy = false;
  MapCatalogReceipt? pendingCatalogReceipt;
  String? _catalogTargetId;
  var _catalogEpoch = 0;
  final Map<String, int> _mapEpochs = {};
  final Set<void Function()> _listeners = {};
  ProjectManifest? project;
  MapWorkspaceProjectScope projectScope;
  final Map<String, MapWorkspaceSelection> _selections = {};
  final _visualScopeMapIds = <String, String>{};

  final _selectionMapsByModel = <String, Set<String>>{};
  final _previewMapsByModel = <String, Set<String>>{};
  final _acceptedModelDefinitions = <String, ({int epoch, ProjectModel3dEntry definition})>{};
  int _modelSourceEpoch = 0;
  int modelSourceSelectionsVisited = 0;
  int modelSourcePreviewsVisited = 0;
  int modelSourceProjectionLookups = 0;
  int visualProjectionBuilds = 0;

  bool get hasCompleteProject =>
      projectScope == MapWorkspaceProjectScope.completeProject;
  ProjectNewGameConfig? _catalogNewGame;
  ProjectNewGameConfig? get homeNewGame =>
      hasCompleteProject ? project?.newGame : _catalogNewGame;
  ProjectManifest? _visualMapSource;
  ProjectManifest? _visualFamilySource;
  ProjectManifest? _combinedVisuals;
  ProjectManifest? _resourceVisualDefinitions;
  ProjectManifest? get visualProject {
    if (hasCompleteProject) return project == null ? null : _withSurfConfiguration(project!);
    final map = _selections[active?.base.mapId]?.definitions ?? project;
    final family = _resourceVisualDefinitions;
    if (map == null || family == null) return map == null ? null : _withSurfConfiguration(map);
    if (!identical(map, _visualMapSource) ||
        !identical(family, _visualFamilySource)) {
      _cacheVisualComposition(map, family);
    }
    return _combinedVisuals == null ? null : _withSurfConfiguration(_combinedVisuals!);
  }

  ProjectSurfSettings? _acceptedSurfConfiguration;
  ProjectFieldAbilitiesSettings? _acceptedFieldAbilities;
  ProjectAudioSettings? _acceptedAudio;
  bool _surfConfigurationAccepted = false,
      _fieldAbilitiesAccepted = false,
      _audioAccepted = false;
  Expando<ProjectManifest> _surfProjections = Expando<ProjectManifest>();

  EditableMapDocument? active;
  ProjectVisualsController? settingsVisualsOwner;
  SpatialVisualPatch? _projectVisualProfile;
  SpatialVisualPatch get inheritedVisualProfile => _projectVisualProfile ?? SpatialVisualPatch();
  final _mapVisualProfiles = <String, SpatialVisualPatch>{};

  bool loading = false;
  String? error;
  String? Function(MapData before, MapData after)? historyGuard;
  String? Function(String mapId, String modelId)? modelDeletionGuard;
  String? Function(String actionId, String targetMapId)?
  catalogDependencyFailure;
  var _generation = 0;
  var _disposed = false;
  bool get isDisposed => _disposed;

  bool get dirty => documents.values.any(
    (document) =>
        document.dirty ||
        document.atmosphere?.dirty == true ||
        document.exteriorDecoration?.dirty == true ||
        document.weatherVisuals?.dirty == true ||
        document.editor?.dirty == true,
  );
  bool get saving => documents.values.any(
    (document) =>
        document.saving ||
        document.atmosphere?.saving == true ||
        document.exteriorDecoration?.saving == true ||
        document.weatherVisuals?.saving == true ||
        document.editor?.saving == true,
  );
  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);

  Future<void> initialize() => _initialize();

  Future<void> activate(ProjectMapEntry entry, {bool Function()? isCurrent}) =>
      _activate(entry, isCurrent: isCurrent);

  Future<MapData?> previewMap(String id) => _previewMap(id);

  final _workshops = <MapWorkspaceWorkshop>{};
  final _workshopLoads = <MapWorkspaceWorkshop, Future<void>>{};
  ProjectManifest? _workshopDefinitions;

  String? _resourceKind;
  int _resourceKindRequest = 0;
  int _resourceKindPending = 0;
  Future<void> _resourceKindQueue = Future.value();

  Future<void> ensureResourceKind(String kind, {bool placeableOnly = false}) =>
      _ensureResourceKind(kind, placeableOnly: placeableOnly);

  ProjectManifest? _familyDefinitions;
  ProjectManifest? _onDemandDefinitions;
  bool _borderProfilesLoaded = false;
  final _borderBlueprints = <String>{};

  final _resourceClosures = <String>{};

  Future<void> ensureBorderProfiles() => _ensureOnDemandSelection(
    () => hasBorderProfiles,
    (source) => _borderPort(source).loadBorderProfiles(session),
    () => _borderProfilesLoaded = true,
  );

  Future<void> _externalMutations = Future.value();
  final _externalConflicts = <String>{};

  final _startedSaves = <Future<void>>{};

  Future<bool> save(EditableMapDocument document) {
    final operation = _save(document);
    final started = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _startedSaves.add(started);
    unawaited(started.whenComplete(() => _startedSaves.remove(started)));
    return operation;
  }

  Future<bool> saveAll() async {
    for (final document in documents.values.toList()) {
      if (!await save(document)) return false;
    }
    return !_disposed && !dirty && !saving;
  }

  void restore({required bool redo}) => _restore(redo: redo);

  void acceptResources(ProjectManifest before, ProjectManifest updated, {
    Map<String, ProjectModel3dEntry> changedModels = const {},
  }) => _acceptResources(before, updated, changedModels: changedModels);

  void notify() {
    if (_disposed) return;
    for (final listener in List.of(_listeners)) {
      if (_listeners.contains(listener)) listener();
    }
  }

  bool _entryDocumentCurrent(ProjectMapEntry entry) {
    final current = project?.maps
        .where((map) => map.id == entry.id)
        .firstOrNull;
    return current != null &&
        current.relativePath == entry.relativePath &&
        current.name == entry.name;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    settingsVisualsOwner = null;
    _generation++;
    _previews.clear();
    _visualScopeMapIds.clear();
    _previewDefinitions.clear();
    _previewMapsByModel.clear();
    _clearSelections();
    _acceptedModelDefinitions.clear();
    for (final document in {...documents.values, ...retiredDocuments.values}) {
      document.weatherVisuals?.dispose();
      document.atmosphere?.dispose();
      document.exteriorDecoration?.dispose();
      document.editor?.dispose();
    }
    _listeners.clear();
  }
}
