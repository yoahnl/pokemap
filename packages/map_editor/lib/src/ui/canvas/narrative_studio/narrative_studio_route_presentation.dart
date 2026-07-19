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
  final location = narrativeStudioRouteLocationFor(workspaceMode);
  return location == null
      ? null
      : narrativeStudioRoutePresentationForLocation(location);
}

NarrativeStudioRouteLocation? narrativeStudioRouteLocationFor(
  EditorWorkspaceMode workspaceMode,
) =>
    switch (workspaceMode) {
      EditorWorkspaceMode.narrativeOverview =>
        NarrativeStudioRouteLocation.overview(),
      EditorWorkspaceMode.globalStory =>
        NarrativeStudioRouteLocation.storylines(),
      EditorWorkspaceMode.step => NarrativeStudioRouteLocation.storylines(
          childRoute: NarrativeStudioChildRoute.storylineStep,
        ),
      EditorWorkspaceMode.scenes => NarrativeStudioRouteLocation.scenes(),
      EditorWorkspaceMode.events => NarrativeStudioRouteLocation.events(),
      EditorWorkspaceMode.cutscene => NarrativeStudioRouteLocation.cinematics(),
      EditorWorkspaceMode.dialogue => NarrativeStudioRouteLocation.dialogues(),
      EditorWorkspaceMode.facts => NarrativeStudioRouteLocation.facts(),
      EditorWorkspaceMode.worldRules =>
        NarrativeStudioRouteLocation.worldRules(),
      EditorWorkspaceMode.narrativeValidator =>
        NarrativeStudioRouteLocation.validator(),
      _ => null,
    };

NarrativeStudioRoutePresentation narrativeStudioRoutePresentationForLocation(
  NarrativeStudioRouteLocation location,
) =>
    switch (location.childRoute) {
      NarrativeStudioChildRoute.overview =>
        const NarrativeStudioRoutePresentation(
          destination: NarrativeStudioDestination.overview,
          label: 'Aperçu',
          breadcrumbLabels: ['Aperçu'],
        ),
      NarrativeStudioChildRoute.storylineLibrary =>
        const NarrativeStudioRoutePresentation(
          destination: NarrativeStudioDestination.storylines,
          label: 'Storylines',
          breadcrumbLabels: ['Storylines'],
        ),
      NarrativeStudioChildRoute.storylineStep =>
        const NarrativeStudioRoutePresentation(
          destination: NarrativeStudioDestination.storylines,
          label: 'Étape',
          breadcrumbLabels: ['Storylines', 'Étape'],
        ),
      NarrativeStudioChildRoute.sceneBuilder =>
        const NarrativeStudioRoutePresentation(
          destination: NarrativeStudioDestination.scenes,
          label: 'Scènes',
          breadcrumbLabels: ['Scènes'],
        ),
      NarrativeStudioChildRoute.eventBuilder =>
        const NarrativeStudioRoutePresentation(
          destination: NarrativeStudioDestination.events,
          label: 'Event Builder',
          breadcrumbLabels: ['Événements', 'Event Builder'],
        ),
      NarrativeStudioChildRoute.mapEvents =>
        const NarrativeStudioRoutePresentation(
          destination: NarrativeStudioDestination.events,
          label: 'Events par map',
          breadcrumbLabels: ['Événements', 'Events par map'],
        ),
      NarrativeStudioChildRoute.cinematicLibrary =>
        const NarrativeStudioRoutePresentation(
          destination: NarrativeStudioDestination.cinematics,
          label: 'Cinématiques',
          breadcrumbLabels: ['Cinématiques'],
        ),
      NarrativeStudioChildRoute.cinematicBuilder =>
        const NarrativeStudioRoutePresentation(
          destination: NarrativeStudioDestination.cinematics,
          label: 'Cinematic Builder',
          breadcrumbLabels: ['Cinématiques', 'Cinematic Builder'],
        ),
      NarrativeStudioChildRoute.cinematicLegacy =>
        const NarrativeStudioRoutePresentation(
          destination: NarrativeStudioDestination.cinematics,
          label: 'Studio legacy',
          breadcrumbLabels: ['Cinématiques', 'Studio legacy'],
        ),
      NarrativeStudioChildRoute.dialogueEditor =>
        const NarrativeStudioRoutePresentation(
          destination: NarrativeStudioDestination.dialogues,
          label: 'Dialogues',
          breadcrumbLabels: ['Dialogues'],
        ),
      NarrativeStudioChildRoute.factsManager =>
        const NarrativeStudioRoutePresentation(
          destination: NarrativeStudioDestination.facts,
          label: 'Facts',
          breadcrumbLabels: ['Facts'],
        ),
      NarrativeStudioChildRoute.worldRulesManager =>
        const NarrativeStudioRoutePresentation(
          destination: NarrativeStudioDestination.worldRules,
          label: 'Règles du monde',
          breadcrumbLabels: ['Règles du monde'],
        ),
      NarrativeStudioChildRoute.validatorDiagnostics =>
        const NarrativeStudioRoutePresentation(
          destination: NarrativeStudioDestination.validator,
          label: 'Validateur',
          breadcrumbLabels: ['Validateur'],
        ),
    };
