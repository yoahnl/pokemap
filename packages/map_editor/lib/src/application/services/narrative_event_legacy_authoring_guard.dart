import 'package:map_core/map_core.dart';

enum NarrativeEventLegacyAuthoringKind { mapEvent }

/// Returns a user-facing reason when a legacy authoring entry point must be
/// closed for the project's authoritative Event Builder mode.
String? narrativeEventLegacyAuthoringBlockReason(
  ProjectManifest? project, {
  required NarrativeEventLegacyAuthoringKind kind,
}) {
  if (project?.eventRegistry?.mode != EventSystemMode.v2Only) return null;
  return 'Le projet est en mode Event Builder V2 uniquement. '
      'Les anciens MapEvents doivent être modifiés depuis la migration '
      'ou l’Event Builder V2.';
}
