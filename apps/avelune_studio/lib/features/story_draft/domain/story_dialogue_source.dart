import 'package:map_core/map_core_domain.dart';

final class StoryDialogueSource {
  const StoryDialogueSource({
    required this.entry,
    required this.source,
    this.revision,
  });

  final ProjectDialogueEntry entry;
  final String source;
  final String? revision;

  String get id => entry.id;
  String get relativePath => entry.relativePath;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryDialogueSource &&
          other.entry == entry &&
          other.source == source;

  @override
  int get hashCode => Object.hash(entry, source);
}
