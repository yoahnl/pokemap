import 'package:meta/meta.dart' show immutable;

import '../models/geometry.dart';
import '../models/narrative_event_registry.dart';
import '../models/narrative_event_source_ref.dart';

enum NarrativeSpatialEventSourceOwnerKind {
  map,
  entity,
  trigger,
  placedElement,
  legacyMapEvent,
}

enum NarrativeSpatialEventSourceAvailability {
  selectable,
  visibleButUnavailable,
  missing,
  incompatible,
  legacyCompatibility,
}

enum NarrativeSpatialEventSourceOrigin { canonical, legacyCompatibility }

enum NarrativeSpatialSourceGeometryKind { bounds, mapWide, unavailable }

enum NarrativeSpatialEventSourceResolutionStatus {
  found,
  unavailable,
  missing,
  ambiguous,
}

@immutable
final class NarrativeSpatialSourceGeometrySummary {
  const NarrativeSpatialSourceGeometrySummary._({
    required this.kind,
    this.bounds,
  });

  const NarrativeSpatialSourceGeometrySummary.bounds(MapRect bounds)
      : this._(
          kind: NarrativeSpatialSourceGeometryKind.bounds,
          bounds: bounds,
        );

  const NarrativeSpatialSourceGeometrySummary.mapWide()
      : this._(kind: NarrativeSpatialSourceGeometryKind.mapWide);

  const NarrativeSpatialSourceGeometrySummary.unavailable()
      : this._(kind: NarrativeSpatialSourceGeometryKind.unavailable);

  final NarrativeSpatialSourceGeometryKind kind;
  final MapRect? bounds;

  Map<String, Object?> toDebugJson() => {
        'kind': kind.name,
        if (bounds != null)
          'bounds': {
            'pos': {'x': bounds!.pos.x, 'y': bounds!.pos.y},
            'size': {
              'width': bounds!.size.width,
              'height': bounds!.size.height,
            },
          },
      };
}

@immutable
final class NarrativeSpatialEventSourceDiagnostic {
  NarrativeSpatialEventSourceDiagnostic({
    required String code,
    required String message,
    required this.mapId,
    this.ownerId,
  })  : code = _identity(code, 'code'),
        message = _identity(message, 'message');

  final String code;
  final String message;
  final String mapId;
  final String? ownerId;

  Map<String, Object?> toDebugJson() => {
        'code': code,
        'message': message,
        'mapId': mapId,
        if (ownerId != null) 'ownerId': ownerId,
      };
}

@immutable
final class NarrativeSpatialEventSourceOption {
  NarrativeSpatialEventSourceOption({
    required this.source,
    this.sourceHint,
    required String humanLabel,
    required String humanDescription,
    required this.mapId,
    required String mapLabel,
    required String sourceTypeLabel,
    required this.availability,
    String? unavailableReason,
    required this.origin,
    required String debugTechnicalLabel,
    required this.geometry,
    required this.ownerKind,
    this.ownerId,
    List<LegacySourceRef> legacyProvenances = const [],
  })  : humanLabel = _identity(humanLabel, 'humanLabel'),
        humanDescription = _identity(humanDescription, 'humanDescription'),
        mapLabel = _identity(mapLabel, 'mapLabel'),
        sourceTypeLabel = _identity(sourceTypeLabel, 'sourceTypeLabel'),
        unavailableReason = _optionalIdentity(
          unavailableReason,
          'unavailableReason',
        ),
        debugTechnicalLabel = _nonEmptyRaw(
          debugTechnicalLabel,
          'debugTechnicalLabel',
        ),
        legacyProvenances = _sortedProvenances(legacyProvenances) {
    if (availability == NarrativeSpatialEventSourceAvailability.selectable) {
      if (source == null || this.unavailableReason != null) {
        throw ArgumentError(
          'A selectable spatial source requires a source and no unavailable '
          'reason.',
        );
      }
    } else if (this.unavailableReason == null) {
      throw ArgumentError(
        'A non-selectable spatial source requires an unavailable reason.',
      );
    }
    if (source != null && sourceHint != null) {
      throw ArgumentError(
        'A spatial source cannot be both canonical and a repair hint.',
      );
    }
    final ownerRequiresId =
        ownerKind != NarrativeSpatialEventSourceOwnerKind.map;
    if ((ownerRequiresId && ownerId == null) ||
        (!ownerRequiresId && ownerId != null)) {
      throw ArgumentError(
        'A map owner must omit ownerId; every other owner requires one.',
      );
    }
    if (source != null && !_sourceMatchesOwner(source!)) {
      throw ArgumentError(
        'The canonical source kind and identity must match its owner.',
      );
    }
    if (sourceHint != null && !_hintMatchesLegacyOwner(sourceHint!)) {
      throw ArgumentError(
        'A source hint must be spatial, map-consistent, and legacy-owned.',
      );
    }
    if ((ownerKind == NarrativeSpatialEventSourceOwnerKind.placedElement ||
            ownerKind == NarrativeSpatialEventSourceOwnerKind.legacyMapEvent) &&
        source != null) {
      throw ArgumentError(
        'Placed and legacy owners cannot claim a canonical spatial source.',
      );
    }
  }

  final NarrativeEventSourceRef? source;
  final NarrativeEventSourceRef? sourceHint;
  final String humanLabel;
  final String humanDescription;
  final String mapId;
  final String mapLabel;
  final String sourceTypeLabel;
  final NarrativeSpatialEventSourceAvailability availability;
  final String? unavailableReason;
  final NarrativeSpatialEventSourceOrigin origin;
  final String debugTechnicalLabel;
  final NarrativeSpatialSourceGeometrySummary geometry;
  final NarrativeSpatialEventSourceOwnerKind ownerKind;
  final String? ownerId;
  final List<LegacySourceRef> legacyProvenances;

  bool get selectable =>
      availability == NarrativeSpatialEventSourceAvailability.selectable;

  NarrativeSpatialEventSourceOption withLegacyProvenance(
    LegacySourceRef provenance,
  ) {
    return NarrativeSpatialEventSourceOption(
      source: source,
      sourceHint: sourceHint,
      humanLabel: humanLabel,
      humanDescription: humanDescription,
      mapId: mapId,
      mapLabel: mapLabel,
      sourceTypeLabel: sourceTypeLabel,
      availability: availability,
      unavailableReason: unavailableReason,
      origin: origin,
      debugTechnicalLabel: debugTechnicalLabel,
      geometry: geometry,
      ownerKind: ownerKind,
      ownerId: ownerId,
      legacyProvenances: [...legacyProvenances, provenance],
    );
  }

  Map<String, Object?> toDebugJson() => {
        if (source != null) 'source': source!.toJson(),
        if (sourceHint != null) 'sourceHint': sourceHint!.toJson(),
        'humanLabel': humanLabel,
        'humanDescription': humanDescription,
        'mapId': mapId,
        'mapLabel': mapLabel,
        'sourceTypeLabel': sourceTypeLabel,
        'availability': availability.name,
        if (unavailableReason != null) 'unavailableReason': unavailableReason,
        'origin': origin.name,
        'debugTechnicalLabel': debugTechnicalLabel,
        'geometry': geometry.toDebugJson(),
        'ownerKind': ownerKind.name,
        if (ownerId != null) 'ownerId': ownerId,
        'legacyProvenances': [
          for (final provenance in legacyProvenances) provenance.toJson(),
        ],
      };

  bool _sourceMatchesOwner(NarrativeEventSourceRef value) {
    return value.when(
      entityInteract: (sourceMapId, entityId) =>
          ownerKind == NarrativeSpatialEventSourceOwnerKind.entity &&
          mapId == sourceMapId &&
          ownerId == entityId,
      triggerEnter: (sourceMapId, triggerId) =>
          ownerKind == NarrativeSpatialEventSourceOwnerKind.trigger &&
          mapId == sourceMapId &&
          ownerId == triggerId,
      mapEnter: (sourceMapId) =>
          ownerKind == NarrativeSpatialEventSourceOwnerKind.map &&
          mapId == sourceMapId &&
          ownerId == null,
      outcomeReceived: (_) => false,
    );
  }

  bool _hintMatchesLegacyOwner(NarrativeEventSourceRef value) {
    if (ownerKind != NarrativeSpatialEventSourceOwnerKind.legacyMapEvent) {
      return false;
    }
    return value.when(
      entityInteract: (sourceMapId, _) => mapId == sourceMapId,
      triggerEnter: (sourceMapId, _) => mapId == sourceMapId,
      mapEnter: (sourceMapId) => mapId == sourceMapId,
      outcomeReceived: (_) => false,
    );
  }
}

@immutable
final class NarrativeSpatialEventSourceResolution {
  const NarrativeSpatialEventSourceResolution._({
    required this.status,
    this.option,
  });

  const NarrativeSpatialEventSourceResolution.found(
    NarrativeSpatialEventSourceOption option,
  ) : this._(
          status: NarrativeSpatialEventSourceResolutionStatus.found,
          option: option,
        );

  const NarrativeSpatialEventSourceResolution.unavailable(
    NarrativeSpatialEventSourceOption option,
  ) : this._(
          status: NarrativeSpatialEventSourceResolutionStatus.unavailable,
          option: option,
        );

  const NarrativeSpatialEventSourceResolution.missing()
      : this._(status: NarrativeSpatialEventSourceResolutionStatus.missing);

  const NarrativeSpatialEventSourceResolution.ambiguous()
      : this._(status: NarrativeSpatialEventSourceResolutionStatus.ambiguous);

  final NarrativeSpatialEventSourceResolutionStatus status;
  final NarrativeSpatialEventSourceOption? option;
}

@immutable
final class NarrativeSpatialEventSourceCatalog {
  NarrativeSpatialEventSourceCatalog({
    required List<NarrativeSpatialEventSourceOption> options,
    required List<NarrativeSpatialEventSourceDiagnostic> diagnostics,
  })  : options = List.unmodifiable(options),
        diagnostics = List.unmodifiable(diagnostics),
        _optionsBySource = _indexSpatialOptions(options);

  final List<NarrativeSpatialEventSourceOption> options;
  final List<NarrativeSpatialEventSourceDiagnostic> diagnostics;
  final Map<NarrativeEventSourceRef, List<NarrativeSpatialEventSourceOption>>
      _optionsBySource;

  List<NarrativeSpatialEventSourceOption> get selectableOptions =>
      List.unmodifiable(options.where((option) => option.selectable));

  NarrativeSpatialEventSourceResolution resolve(
    NarrativeEventSourceRef source,
  ) {
    final matches = optionsForSource(source);
    if (matches.isEmpty) {
      return const NarrativeSpatialEventSourceResolution.missing();
    }
    if (matches.length > 1) {
      return const NarrativeSpatialEventSourceResolution.ambiguous();
    }
    final option = matches.single;
    return option.selectable
        ? NarrativeSpatialEventSourceResolution.found(option)
        : NarrativeSpatialEventSourceResolution.unavailable(option);
  }

  List<NarrativeSpatialEventSourceOption> optionsForSource(
    NarrativeEventSourceRef source,
  ) =>
      _optionsBySource[source] ?? const [];

  Map<String, Object?> toDebugJson() => {
        'options': [for (final option in options) option.toDebugJson()],
        'diagnostics': [
          for (final diagnostic in diagnostics) diagnostic.toDebugJson(),
        ],
      };
}

Map<NarrativeEventSourceRef, List<NarrativeSpatialEventSourceOption>>
    _indexSpatialOptions(List<NarrativeSpatialEventSourceOption> options) {
  final result =
      <NarrativeEventSourceRef, List<NarrativeSpatialEventSourceOption>>{};
  for (final option in options) {
    final source = option.source;
    if (source == null) continue;
    result.putIfAbsent(source, () => []).add(option);
  }
  return Map.unmodifiable({
    for (final entry in result.entries)
      entry.key:
          List<NarrativeSpatialEventSourceOption>.unmodifiable(entry.value),
  });
}

String _identity(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, name, 'must be non-empty and trimmed');
  }
  return value;
}

String? _optionalIdentity(String? value, String name) {
  if (value == null) return null;
  return _identity(value, name);
}

String _nonEmptyRaw(String value, String name) {
  if (value.isEmpty) {
    throw ArgumentError.value(value, name, 'must be non-empty');
  }
  return value;
}

List<LegacySourceRef> _sortedProvenances(List<LegacySourceRef> values) {
  final sorted = List<LegacySourceRef>.of(values)
    ..sort(compareLegacySourceRefs);
  for (var index = 1; index < sorted.length; index++) {
    if (sorted[index - 1] == sorted[index]) {
      throw ArgumentError.value(
        values,
        'legacyProvenances',
        'must not contain duplicates',
      );
    }
  }
  return List.unmodifiable(sorted);
}
