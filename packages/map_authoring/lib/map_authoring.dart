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
export 'src/registry/action_registry.dart';
export 'src/registry/resource_kind_registry.dart';
export 'src/tooling/registry_documentation.dart';
