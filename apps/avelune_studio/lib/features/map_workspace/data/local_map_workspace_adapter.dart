import '../domain/spatial_model_visibility_port.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:isolate';

import 'package:map_authoring/map_authoring.dart'
    show AssetRecord, assetBlobStorageKey, probeProjectAudioSourceBytes;
import 'package:map_authoring/map_authoring_documents.dart';
import 'package:map_authoring/map_authoring_local.dart';

import '../domain/map_atmosphere_port.dart';
import '../domain/map_exterior_decoration_port.dart';
import '../../project_visuals/domain/project_visuals_port.dart';
import '../domain/map_editor_port.dart';
import '../domain/spatial_field_obstacle_port.dart';
import '../domain/field_traversal_zone_port.dart';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_catalog_port.dart';
import 'package:avelune_studio/features/map_workspace/data/map_document_retention.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';

import '../../project_session/data/studio_project_document_revision.dart';
import '../../project_session/data/local_workshop_reader.dart';
import '../../project_surf/domain/project_surf_port.dart';
import '../../project_cs/domain/project_cs_port.dart';
import '../../project_audio/domain/project_audio_port.dart';

part 'local_map_atmosphere_adapter.dart';
part 'local_map_saved_map_reader.dart';
part 'local_map_exterior_decoration_adapter.dart';
part 'local_project_visuals_adapter.dart';
part 'local_project_surf_adapter.dart';
part 'local_project_cs_adapter.dart';
part 'local_project_audio_adapter.dart';
part 'local_project_audio_import.dart';
part 'local_project_settings_mutation.dart';
part 'local_map_editor_adapter.dart';
part 'local_spatial_field_obstacle_adapter.dart';
part 'local_spatial_model_visibility_adapter.dart';
part 'local_field_traversal_zone_adapter.dart';
part 'local_map_workspace_catalog.dart';
part 'local_map_workspace_working_catalog.dart';
part 'local_map_workspace_scoped_catalog.dart';
part 'local_map_workspace_scoped_selection.dart';
part 'local_map_workspace_scoped_reads.dart';
part 'local_map_workspace_resource_families.dart';
part 'local_map_workspace_palette_listing.dart';
part 'local_map_workspace_catalog_ports.dart';
part 'local_map_workspace_map_ports.dart';
part 'local_map_workspace_settings_ports.dart';
part 'local_map_workspace_baseline.dart';
part 'local_map_workspace_documents.dart';

final class LocalMapWorkspaceAdapter
    with
        _MapWorkspaceCatalogPorts,
        _MapWorkspaceMapFeaturePorts,
        _MapWorkspaceSettingsPorts
    implements
        MapWorkspacePort,
        MapWorkspacePreviewSelectionPort,
        MapWorkspaceExternalMutationPort,
        MapWorkspaceWorkshopPort,
        MapWorkspaceResourceKindPort,
        MapWorkspaceResourcePrefetchPort,
        MapWorkspaceBorderProfilePort,
        MapWorkspaceResourceClosurePort,
        MapWorkspaceModelLightPort,
        MapAtmospherePort,
        MapExteriorDecorationPort,
        ProjectVisualsPort,
        ProjectSurfPort,
        ProjectCsPort,
        ProjectAudioPort,
        MapEditorPort,
        MapElementOrderPort,
        SpatialFieldObstaclePort,
        SpatialModelVisibilityPort,
        FieldTraversalZonePort {
  LocalMapWorkspaceAdapter({
    ProjectFileReader? reader,
    AtomicMapDocumentPersistence? persistence,
    this.performanceObserver,
    this.onMapMetadataEntryRead,
    this.onMapMetadataNodeCopied,
  }) : _reader = reader ?? const LocalProjectFileReader(),
       _persistence = persistence ?? const AtomicMapDocumentPersistence();

  @override
  LocalMapWorkspaceAdapter get _adapter => this;

  final AuthoringPerformanceObserver? performanceObserver;
  var _settingsOperations = 0;
  var _surfOperations = 0;
  final _visualServices = <String, Future<LocalVisualSettingsAuthoring>>{};
  var _visualOperations = 0;
  final void Function()? onMapMetadataEntryRead;
  final void Function()? onMapMetadataNodeCopied;
  final ProjectFileReader _reader;
  final AtomicMapDocumentPersistence _persistence;
  final _projects = <String, _ProjectDocument>{};
  final _resourceSelections = <String, ProjectManifest>{};
  final _resourceKindReads = <String, Map<String, _FamilyRead>>{};
  final _onDemandSelections = <String, ProjectManifest>{};
  final _activeMapDefinitions = <String, ProjectManifest>{};
  final _workshopCharacterDefinitions = <String, ProjectManifest>{};
  final _loadedPaths = <(String, String), String>{};
  Future<void> _writes = Future.value();
  final _exteriorServices = <String, Future<LocalMapExteriorDecorationAuthoring>>{};
  var _exteriorOperations = 0;
  final _atmosphereServices = <String, Future<LocalMapAtmosphereAuthoring>>{};
  final _editorServices = <String, Future<LocalMapEditorAuthoring>>{};
  final _elementOrderServices = <String, Future<LocalMapElementOrderAuthoring>>{};
  var _editorOperations = 0;
  var _atmosphereOperations = 0;

  Future<T> withResourceMutation<T>(Future<T> Function() operation) {
    final result = _writes.then((_) => operation());
    _writes = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<({ProjectManifest manifest, String revision})> resourceBaseline(
    ProjectSession session, {
    bool refreshCatalog = false,
  }) async {
    var project = _project(session);
    await _requireRoot(session);
    if (refreshCatalog) {
      project = await _refreshCatalog(session, project);
    }
    await _requireProjectRevision(session, project);
    return (manifest: project.manifest, revision: project.revision);
  }

  Future<String> resourceRevision(ProjectSession session) async {
    final descriptor = await _reader.readBytes(
      projectRoot: session.directoryPath,
      relativePath: 'project.json',
    );
    final head = session.storage == ProjectSessionStorage.workingCatalog
        ? await _reader.readBytes(
            projectRoot: session.directoryPath,
            relativePath: CatalogStorageStore.headStorageKey,
          )
        : null;
    return studioProjectDocumentRevision(
      descriptorBytes: descriptor,
      headBytes: head,
    );
  }
}
