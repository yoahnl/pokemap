import 'dart:convert';

import '../models/narrative_validation_report.dart';
import 'narrative_event_canonical_json.dart';

/// Stable RFC 8785 JSON representation used by local exports and CI.
String encodeNarrativeValidationReport(
  NarrativeMultidimensionalValidationReport report,
) =>
    canonicalizeNarrativeEventJson(report.toJson());

NarrativeMultidimensionalValidationReport decodeNarrativeValidationReport(
  String source,
) {
  final decoded = decodeNarrativeEventJsonStrict(source);
  if (decoded is! Map) {
    throw const FormatException(
        'Narrative validation report must be an object.');
  }
  return NarrativeMultidimensionalValidationReport.fromJson(
    Map<String, dynamic>.from(decoded),
  );
}

String narrativeValidationDiagnosticFingerprint(
  NarrativeMultidimensionalDiagnostic diagnostic,
) =>
    narrativeValidationPayloadFingerprint(diagnostic.toJson());

/// Shared fingerprint boundary for editor diagnostics which predate the
/// multidimensional publication contract.
String narrativeValidationPayloadFingerprint(Map<String, Object?> payload) =>
    narrativeEventBytesFingerprint(
      canonicalizeNarrativeEventJsonUtf8(payload),
    );

int narrativeValidationExitCode(NarrativeValidationStatus status) =>
    switch (status) {
      NarrativeValidationStatus.pass => 0,
      NarrativeValidationStatus.fail => 1,
      NarrativeValidationStatus.indeterminate => 2,
      NarrativeValidationStatus.notRun => 3,
    };

List<int> encodeNarrativeValidationReportUtf8(
  NarrativeMultidimensionalValidationReport report,
) =>
    utf8.encode(encodeNarrativeValidationReport(report));
