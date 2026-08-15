/// Local desktop composition surface for PokeMap authoring clients.
library;

export 'map_authoring_api.dart';
export 'src/api/local_map_authoring_mutation_api.dart';
export 'src/domains/assets/asset_store.dart' show assetBlobResourceIdentity;
export 'src/domains/assets/tiled_image_collection_packer.dart'
    show TiledImageCollectionRasterCodec;
export 'src/domains/gameplay/pokemon_catalog_coherence_loader.dart'
    show PokemonCatalogCoherenceLoader;
export 'src/ports/artifact_store.dart'
    show LocalArtifactStore, maximumAuthoringArtifactBytesV1;
export 'src/ports/project_file_reader.dart'
    show
        LocalProjectFileReader,
        ProjectDirectoryReader,
        ProjectFileReader,
        ProjectResourceIdentity,
        ProjectResourceIdentityReader,
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
    show ProjectSnapshotLoadPolicy, ProjectSnapshotLoader;
export 'src/workspace/workspace_handle_store.dart' show WorkspaceHandleStore;
export 'src/workspace/workspace_policy.dart' show WorkspacePolicy;
