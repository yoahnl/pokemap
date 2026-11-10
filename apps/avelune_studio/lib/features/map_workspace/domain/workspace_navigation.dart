enum WorkspaceSpace {
  projectSettings,
  map,
  regionalMap,
  resources,
  story,
  pokemon,
  interaction,
  scene,
  progression,
  events,
  dialogue,
  cinematic,
  presentation,
  world,
  verification,
  gameExport,
}

class WorkspaceReturn {
  const WorkspaceReturn(this.space, {this.documentId, this.elementId});
  static const story = WorkspaceReturn(WorkspaceSpace.story);
  final WorkspaceSpace space;
  final String? documentId;
  final String? elementId;
}
