import '../../resources/domain/studio_search_text.dart';

final class StudioCommandEntry {
  const StudioCommandEntry({
    required this.id,
    required this.label,
    required this.group,
    required this.help,
    this.keywords = const [],
    this.shortcut,
    this.example,
    this.unavailable,
    this.executable = true,
  });

  final String id, label, group, help;
  final List<String> keywords;
  final String? shortcut, example, unavailable;
  final bool executable;

  bool get runnable => executable && unavailable == null;
}

List<StudioCommandEntry> studioCommandSearch(
  List<StudioCommandEntry> entries,
  String query,
) {
  final folded = studioSearchText(query).trim();
  if (folded.isEmpty) return entries;
  int score(StudioCommandEntry entry) {
    final label = studioSearchText(entry.label);
    if (label.startsWith(folded)) return 0;
    if (label.contains(folded)) return 1;
    if (entry.keywords.any(
      (keyword) => studioSearchText(keyword).contains(folded),
    )) {
      return 2;
    }
    return 3;
  }

  final matches = [
    for (final entry in entries)
      if (studioSearchMatches(
        '${entry.label} ${entry.keywords.join(' ')} ${entry.group} ${entry.help}',
        query,
      ))
        entry,
  ];
  final order = {for (var i = 0; i < entries.length; i++) entries[i]: i};
  matches.sort((left, right) {
    final byScore = score(left).compareTo(score(right));
    return byScore != 0 ? byScore : order[left]!.compareTo(order[right]!);
  });
  return matches;
}
