import '../../../features/editor/state/models/editor_workspace_mode.dart';
import 'narrative_studio_destination.dart';

/// UI-only description of an editor route inside Narrative Studio.
///
/// This value contains no provider or project data. Workspaces can enrich the
/// breadcrumb with a real chapter, step, scene or entity name at composition
/// time without changing destination selection.
class NarrativeStudioRoutePresentation {
  const NarrativeStudioRoutePresentation({
    required this.destination,
    required this.label,
    required this.breadcrumbLabels,
  });

  final NarrativeStudioDestination destination;
  final String label;
  final List<String> breadcrumbLabels;
}

/// Pure mapping between the existing editor routes and product navigation.
///
/// Non-narrative routes return `null`. In particular, Map Editor never selects
/// an item in the Narrative Studio rail.
NarrativeStudioRoutePresentation? narrativeStudioRoutePresentationFor(
  EditorWorkspaceMode workspaceMode,
) {
  return switch (workspaceMode) {
    EditorWorkspaceMode.narrativeOverview =>
      const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.overview,
        label: 'Aperçu',
        breadcrumbLabels: ['Aperçu'],
      ),
    EditorWorkspaceMode.globalStory => const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.storylines,
        label: 'Storylines',
        breadcrumbLabels: ['Storylines'],
      ),
    EditorWorkspaceMode.step => const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.storylines,
        label: 'Étape',
        breadcrumbLabels: ['Storylines', 'Étape'],
      ),
    EditorWorkspaceMode.scenes => const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.scenes,
        label: 'Scènes',
        breadcrumbLabels: ['Scènes'],
      ),
    EditorWorkspaceMode.events => const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.events,
        label: 'Event Builder',
        breadcrumbLabels: ['Event Builder'],
      ),
    EditorWorkspaceMode.cutscene => const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.cinematics,
        label: 'Cinématiques',
        breadcrumbLabels: ['Cinématiques'],
      ),
    EditorWorkspaceMode.dialogue => const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.dialogues,
        label: 'Dialogues',
        breadcrumbLabels: ['Dialogues'],
      ),
    EditorWorkspaceMode.facts => const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.facts,
        label: 'Facts',
        breadcrumbLabels: ['Facts'],
      ),
    EditorWorkspaceMode.worldRules => const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.worldRules,
        label: 'Règles du monde',
        breadcrumbLabels: ['Règles du monde'],
      ),
    EditorWorkspaceMode.narrativeValidator =>
      const NarrativeStudioRoutePresentation(
        destination: NarrativeStudioDestination.validator,
        label: 'Validateur',
        breadcrumbLabels: ['Validateur'],
      ),
    _ => null,
  };
}
