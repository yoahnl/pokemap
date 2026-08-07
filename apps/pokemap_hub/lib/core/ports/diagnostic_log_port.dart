/// Appends Hub diagnostics to durable storage, outside the widget tree.
///
/// Every implementation must be best-effort: a diagnostic write that throws
/// would mask the failure it is describing.
abstract interface class DiagnosticLogPort {
  Future<void> append(String line);
}
