/// Local desktop composition surface for PokeMap authoring clients.
library;

export 'src/catalog_storage/catalog_storage_store.dart';
export 'src/catalog_storage/catalog_editing_session.dart';
export 'src/catalog_storage/catalog_generation_retention.dart';

export 'src/domains/distribution/game_package_export_profile_api.dart';
export 'src/domains/distribution/game_package_export_profile_store.dart';

export 'src/references/resource_usage_projection.dart';

export 'map_authoring_api.dart';
export 'src/api/local_map_authoring_mutation_api.dart';
export 'src/domains/maps/map_lifecycle_actions.dart' show MapLifecycleActions;
export 'src/domains/maps/map_lifecycle_analysis.dart' show MapLifecycleAnalysis;
export 'src/transactions/action_planner.dart' show AuthoringPlanningContext;
export 'src/transactions/authoring_plan.dart' show AuthoringMutationDraft;
export 'src/domains/assets/resource_management_actions.dart'
    show ResourceManagementActions;
export 'src/domains/assets/resource_source_actions.dart'
    show ResourceSourceActions;
export 'src/domains/assets/asset_store.dart' show assetBlobResourceIdentity;
export 'src/domains/assets/tiled_image_collection_packer.dart'
    show TiledImageCollectionRasterCodec;
export 'src/domains/gameplay/pokemon_catalog_coherence_loader.dart'
    show PokemonCatalogCoherenceLoader;
export 'src/domains/gameplay/project_item_icon_provisioning_service.dart';
export 'src/domains/gameplay/project_capture_sprite_provisioning_service.dart';
export 'src/domains/narrative/presentation_cinematic_draft.dart'
    show PresentationCinematicDraft, PresentationCinematicDraftException;
export 'src/ports/artifact_store.dart'
    show LocalArtifactStore, maximumAuthoringArtifactBytesV1;
export 'src/ports/project_file_reader.dart'
    show
        LocalProjectFileReader,
        ProjectDirectoryReader,
        ProjectFileReader,
        ProjectResourceIdentity,
        ProjectResourceIdentityReader,
        ProjectResourceStreamReader,
        ProjectResourceProbe,
        ProjectResourceProbeReader,
        ProjectResourceProbeStatus,
        ProjectSnapshotCacheIdentityReader;
export 'src/ports/project_manifest_bootstrap_writer.dart'
    show LocalProjectManifestBootstrapWriter;
export 'src/references/project_reference_index.dart' show ProjectReferenceIndex;
export 'src/security/authorization_policy.dart' show AuthoringSecurityLimits;
export 'src/support/authoring_performance_observer.dart';
export 'src/workspace/project_open_service.dart' show ProjectOpenService;
export 'src/workspace/local_project_creation_service.dart';
export 'src/workspace/project_template_catalog.dart';
export 'src/workspace/project_creation_bootstrap_api.dart';
export 'src/workspace/project_query_service.dart' show ProjectQueryService;
export 'src/workspace/project_snapshot.dart'
    show ProjectSnapshot, ProjectSnapshotLoadDiagnostic;
export 'src/workspace/project_snapshot_cache.dart'
    show
        ProjectSnapshotCache,
        ProjectSnapshotCacheAdmission,
        ProjectSnapshotCacheBudget,
        ProjectSnapshotCacheValidation;
export 'src/workspace/project_snapshot_fingerprint_cache.dart'
    show ProjectSnapshotFingerprintCache;
export 'src/workspace/project_snapshot_loader.dart'
    show
        ProjectSnapshotLoadPolicy,
        ProjectSnapshotLoadProfile,
        ProjectSnapshotLoadProfileSink,
        ProjectSnapshotLoader;
export 'src/workspace/workspace_handle_store.dart' show WorkspaceHandleStore;
export 'src/workspace/workspace_policy.dart' show WorkspacePolicy;

export 'src/infrastructure/local_resource_pack_store.dart';

export 'src/transactions/local_authoring_payload.dart';

export 'src/api/local_resource_pack_transfer_api.dart';

export 'src/workspace/catalog_project_materialization.dart';
export 'src/workspace/catalog/catalog_targeted_map_edit.dart'
    show CatalogTargetedMapSelection;

export 'src/documents/character_contact_shadow_authoring.dart';

export 'src/documents/map_atmosphere_authoring.dart';
export 'src/documents/map_exterior_decoration_authoring.dart';
export 'src/documents/map_editor_authoring.dart';
export 'src/documents/map_element_order_authoring.dart';

export 'src/support/map_authoring_worker_trace.dart'
    show MapAuthoringWorkerDiagnostics;

export 'src/documents/visual_settings_authoring.dart';

export 'src/references/exterior_decoration_references.dart' show projectExteriorReferenceUsages;
export 'src/api/authoring_capability_discovery.dart';
export 'src/api/map_health_query.dart';
export 'src/api/map_edit_execution.dart';
export 'src/contracts/map_edit_operation.dart';
export 'src/support/companion_process_access.dart';
