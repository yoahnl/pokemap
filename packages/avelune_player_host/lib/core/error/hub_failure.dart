/// Raised when the host file picker cannot deliver a package.
///
/// Lives in `core/error/` rather than beside the platform port: it is an error
/// contract the whole app reports on, not part of the port's interface. Its
/// `code`, `message` and `recommendation` are asserted by
/// `test/platform/hub_platform_adapter_test.dart`.
final class HubPackagePickerFailure implements Exception {
  const HubPackagePickerFailure({
    required this.code,
    required this.message,
    required this.recommendation,
    this.cause,
  });

  final String code;
  final String message;
  final String recommendation;
  final Object? cause;

  @override
  String toString() => cause == null ? message : '$message Cause: $cause';
}
