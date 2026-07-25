/// Stable error categories for persisted save contracts.
enum SaveContractErrorCode {
  invalidField,
  unknownField,
  invalidIdentity,
  invalidTimeline,
  invalidCompletion,
  invalidChecksum,
  checksumMismatch,
  addressMismatch,
  unsupportedSchema,
  unsupportedSaveFormat,
  sizeLimitExceeded,
}

/// A malformed or unsupported save contract.
final class SaveContractException extends FormatException {
  const SaveContractException(this.code, super.message, {this.path});

  final SaveContractErrorCode code;
  final String? path;

  @override
  String toString() {
    final location = path == null ? '' : ' at $path';
    return 'SaveContractException(${code.name})$location: $message';
  }
}
