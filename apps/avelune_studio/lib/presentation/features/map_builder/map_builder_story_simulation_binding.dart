part of 'map_builder_story_binding.dart';

extension MapStorySimulation on MapBuilderStoryBinding {
  NarrativeEventSimulationReport? simulate(
    NarrativeEventSimulationInput input,
  ) {
    final project = this.project;
    final map = this.map;
    if (project == null || map == null || !ready) return null;
    return (editing ??
            GameBehaviourEditing(
              project: project,
              map: map,
              behaviours: behaviours,
            ))
        .simulate(input);
  }

  void toggleSimulation(String eventId) {
    simulating = simulating == eventId ? null : eventId;
    changed();
  }
}
