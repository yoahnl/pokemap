import 'package:meta/meta.dart' show immutable;

import 'narrative_event_registry.dart';
import 'narrative_event_source_ref.dart';

final RegExp _correlationIdPattern = RegExp(
  r'^corr_[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

@immutable
final class NarrativeEventOccurrence {
  NarrativeEventOccurrence({
    required this.source,
    this.provenance,
    String? rootCorrelationId,
    int? depth,
  })  : rootCorrelationId = _validateCorrelationId(rootCorrelationId),
        depth = _validateDepth(depth);

  final NarrativeEventSourceRef source;
  final LegacySourceRef? provenance;
  final String? rootCorrelationId;
  final int? depth;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeEventOccurrence &&
          other.source == source &&
          other.provenance == provenance &&
          other.rootCorrelationId == rootCorrelationId &&
          other.depth == depth;

  @override
  int get hashCode => Object.hash(source, provenance, rootCorrelationId, depth);
}

String? _validateCorrelationId(String? value) {
  if (value == null) return null;
  if (!_correlationIdPattern.hasMatch(value)) {
    throw ArgumentError.value(
      value,
      'rootCorrelationId',
      'must match corr_<uuid-v7>',
    );
  }
  return value;
}

int? _validateDepth(int? value) {
  if (value != null && value < 0) {
    throw ArgumentError.value(value, 'depth', 'must be non-negative');
  }
  return value;
}
