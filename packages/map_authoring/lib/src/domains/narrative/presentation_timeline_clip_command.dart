final class PresentationTimelineClipCommand {
  PresentationTimelineClipCommand({
    required this.actionId,
    required Map<String, Object?> parameters,
  }) : parameters = Map<String, Object?>.unmodifiable(parameters);

  final String actionId;
  final Map<String, Object?> parameters;

  List<Map<String, Object?>> get operations {
    final operations = parameters['operations'];
    if (operations is! List<Object?>) return const <Map<String, Object?>>[];
    return operations
        .map(
          (operation) => Map<String, Object?>.unmodifiable(
            Map<String, Object?>.from(operation! as Map),
          ),
        )
        .toList(growable: false);
  }
}
