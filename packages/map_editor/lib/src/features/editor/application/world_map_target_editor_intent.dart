import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import 'map_canvas_object_hit_test.dart';

@immutable
sealed class WorldMapTargetEditorIntent {
  const WorldMapTargetEditorIntent();
}

@immutable
final class OpenLegacyMapEventEditorIntent extends WorldMapTargetEditorIntent {
  const OpenLegacyMapEventEditorIntent(this.eventId);

  final String eventId;
}

@immutable
final class OpenNarrativeCompatibilityEventIntent
    extends WorldMapTargetEditorIntent {
  const OpenNarrativeCompatibilityEventIntent(this.stableKey);

  final String stableKey;
}

@immutable
final class FocusWorldMapObjectInspectorIntent
    extends WorldMapTargetEditorIntent {
  const FocusWorldMapObjectInspectorIntent(this.target);

  final MapCanvasObjectTarget target;
}

enum WorldMapTargetEditorBlockCode {
  eventBuilderReadModelUnavailable,
  missingCompatibilityEntry,
  ambiguousCompatibilityEntry,
  invalidCompatibilityEntry,
}

@immutable
sealed class WorldMapTargetEditorResolution {
  const WorldMapTargetEditorResolution();
}

@immutable
final class WorldMapTargetEditorReady extends WorldMapTargetEditorResolution {
  const WorldMapTargetEditorReady(this.intent);

  final WorldMapTargetEditorIntent intent;
}

@immutable
final class WorldMapTargetEditorBlocked extends WorldMapTargetEditorResolution {
  const WorldMapTargetEditorBlocked({
    required this.code,
    required this.reason,
  });

  final WorldMapTargetEditorBlockCode code;
  final String reason;
}

typedef WorldMapTargetEditorRequested = Future<void> Function(
  WorldMapTargetEditorIntent intent,
);

final class WorldMapTargetEditorIntentResolver {
  const WorldMapTargetEditorIntentResolver();

  WorldMapTargetEditorResolution resolve({
    required MapCanvasObjectTarget target,
    required MapData map,
    required ProjectManifest? project,
    required NarrativeEventBuilderProjectReadModel? eventBuilderReadModel,
  }) {
    if (target.kind != MapCanvasObjectKind.mapEvent) {
      return WorldMapTargetEditorReady(
        FocusWorldMapObjectInspectorIntent(target),
      );
    }

    final mode = project?.eventRegistry?.mode ?? EventSystemMode.legacyOnly;
    if (mode == EventSystemMode.legacyOnly) {
      return WorldMapTargetEditorReady(
        OpenLegacyMapEventEditorIntent(target.id),
      );
    }

    if (eventBuilderReadModel == null) {
      return const WorldMapTargetEditorBlocked(
        code: WorldMapTargetEditorBlockCode.eventBuilderReadModelUnavailable,
        reason: 'L’Event Builder n’est pas encore disponible. '
            'Réessayez après son chargement.',
      );
    }

    final provenance = LegacySourceRef.mapEvent(map.id, target.id);
    final matches = <_CompatibilityMatch>[
      for (final summary in eventBuilderReadModel.events)
        for (final origin in summary.compatibilityOrigins)
          if (origin.provenance == provenance)
            (summary: summary, origin: origin),
    ];
    if (matches.isEmpty) {
      return const WorldMapTargetEditorBlocked(
        code: WorldMapTargetEditorBlockCode.missingCompatibilityEntry,
        reason: 'Aucune entrée de compatibilité ne correspond à ce MapEvent. '
            'Vérifiez la migration dans l’Event Builder.',
      );
    }
    if (matches.length != 1) {
      return const WorldMapTargetEditorBlocked(
        code: WorldMapTargetEditorBlockCode.ambiguousCompatibilityEntry,
        reason: 'Plusieurs entrées de compatibilité correspondent à ce '
            'MapEvent. Vérifiez la migration avant de continuer.',
      );
    }

    final match = matches.single;
    final expectedStableKey = 'legacy:${match.origin.stableKey}';
    final summary = match.summary;
    if (!summary.readOnly ||
        summary.origin != NarrativeEventProjectOrigin.legacyMapEvent ||
        summary.group != NarrativeEventProjectGroupKind.legacyCompatibility ||
        summary.stableKey != expectedStableKey) {
      return const WorldMapTargetEditorBlocked(
        code: WorldMapTargetEditorBlockCode.invalidCompatibilityEntry,
        reason: 'L’entrée de compatibilité de ce MapEvent est invalide. '
            'Vérifiez la migration dans l’Event Builder.',
      );
    }

    return WorldMapTargetEditorReady(
      OpenNarrativeCompatibilityEventIntent(summary.stableKey),
    );
  }
}

typedef _CompatibilityMatch = ({
  NarrativeEventProjectSummary summary,
  NarrativeEventCompatibilityOrigin origin,
});
