/// Stable, protocol-neutral authoring boundary for direct Dart consumers.
///
/// Filesystem composition, domain handlers, transaction engines, and protocol
/// workers are deliberately absent. Desktop clients that need local adapters
/// should import `map_authoring_local.dart` instead.
library;

export 'package:map_core/map_core.dart' show ProjectCapabilityTruthRecord;

export 'src/api/authoring_mutation_api.dart';
export 'src/api/authoring_mutation_contracts.dart';
export 'src/api/authoring_read_api.dart';
export 'src/api/authoring_read_contracts.dart';
export 'src/contracts/action_descriptor.dart';
export 'src/contracts/artifact_contracts.dart';
export 'src/contracts/artifact_ref.dart';
export 'src/contracts/authoring_diff.dart';
export 'src/contracts/authoring_error.dart';
export 'src/contracts/authoring_receipt.dart';
export 'src/contracts/authoring_request.dart';
export 'src/contracts/authoring_result.dart';
export 'src/contracts/capability_descriptor.dart';
export 'src/contracts/job_contracts.dart';
export 'src/contracts/playtest_contracts.dart';
export 'src/contracts/query_page.dart';
export 'src/contracts/query_request.dart';
export 'src/contracts/resource_ref.dart';
export 'src/contracts/schema_descriptor.dart';
export 'src/parity/full_authoring_parity.dart';
export 'src/ports/artifact_store.dart'
    show
        ArtifactFileStager,
        ArtifactStore,
        ArtifactStoreException,
        StoredArtifact;
export 'src/ports/map_render_port.dart';
export 'src/ports/media_processing_port.dart';
export 'src/ports/playtest_port.dart';
export 'src/references/project_reference_index.dart'
    show
        ProjectReferenceDiagnostic,
        ProjectReferenceSeverity,
        ProjectReferenceIndex;
export 'src/transactions/authoring_plan.dart' show AuthoringPlan;
export 'src/transactions/change_set.dart'
    show AuthoringChangeSet, AuthoringResourceChange;
export 'src/workspace/project_open_service.dart'
    show OpenedProject, ProjectOpenException;
export 'src/workspace/workspace_handle_store.dart'
    show ProjectHandle, WorkspaceHandle, WorkspaceHandleException;
