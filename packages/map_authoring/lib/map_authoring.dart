/// Canonical pure-Dart authoring contracts for PokeMap.
///
/// Platform adapters and MCP protocol translation deliberately live outside
/// this package. Keeping this barrel free of those dependencies is an
/// architectural invariant tested by `package_boundary_test.dart`.
library;

export 'src/architecture/package_boundaries.dart';
export 'src/contracts/action_descriptor.dart';
export 'src/contracts/capability_descriptor.dart';
export 'src/contracts/authoring_diff.dart';
export 'src/contracts/authoring_error.dart';
export 'src/contracts/authoring_receipt.dart';
export 'src/contracts/authoring_request.dart';
export 'src/contracts/authoring_result.dart';
export 'src/contracts/resource_ref.dart';
export 'src/contracts/schema_descriptor.dart';
export 'src/contracts/query_page.dart';
export 'src/contracts/query_request.dart';
export 'src/domains/maps/map_region_query.dart';
export 'src/domains/project/capability_truth_adapter.dart';
export 'src/ports/project_file_reader.dart';
export 'src/registry/action_registry.dart';
export 'src/registry/resource_kind_registry.dart';
export 'src/references/project_reference_index.dart';
export 'src/references/reference_impact.dart';
export 'src/references/reference_queries.dart';
export 'src/tooling/registry_documentation.dart';
export 'src/workspace/project_open_service.dart';
export 'src/workspace/project_query_service.dart';
export 'src/workspace/project_snapshot.dart';
export 'src/workspace/project_snapshot_loader.dart';
export 'src/workspace/workspace_handle_store.dart';
export 'src/workspace/workspace_policy.dart';
