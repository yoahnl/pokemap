part of 'map_builder_story_binding.dart';

class MapBuilderInputSession extends MapEditingInputSession {
  MapBuilderInputSession({
    required super.controller,
    required super.view,
    required this.story,
  });

  final MapBuilderStoryBinding story;

  @override
  MapContextActionContext? contextAt(GridPos position) {
    final context = super.contextAt(position);
    return context == null
        ? null
        : MapGuardedContextActionContext(
            document: context.document,
            project: story.behaviours.project(context.project),
            position: position,
            deletionGuard: story.contextDeletionProblem,
          );
  }

  @override
  void run(MapContextCommand command) {
    final selected = target;
    final document = controller.active;
    final problem = command != MapContextCommand.delete || selected == null
        ? null
        : story.contextDeletionProblem(selected);
    if (problem == null || document == null) return super.run(command);
    dismiss();
    document.error = problem;
    notifyListeners();
  }
}
