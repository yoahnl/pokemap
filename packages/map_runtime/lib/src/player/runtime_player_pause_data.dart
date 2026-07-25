import 'dart:collection';

enum RuntimePlayerPauseSection {
  root,
  party,
  bag,
  pokedex,
  map,
  options,
}

/// Generic data-only row rendered by a runtime-owned pause detail surface.
final class RuntimePlayerDetailEntrySnapshot {
  RuntimePlayerDetailEntrySnapshot({
    required this.id,
    required this.title,
    this.subtitle,
    this.trailingLabel,
    this.progress,
  }) {
    if (id.trim().isEmpty || title.trim().isEmpty) {
      throw ArgumentError('Detail entry id and title must not be empty.');
    }
    if (progress case final value? when value < 0 || value > 1) {
      throw ArgumentError.value(
        value,
        'progress',
        'must be between zero and one',
      );
    }
  }

  final String id;
  final String title;
  final String? subtitle;
  final String? trailingLabel;
  final double? progress;
}

/// Data-only presentation for one non-root pause section.
final class RuntimePlayerPauseDetailSnapshot {
  RuntimePlayerPauseDetailSnapshot({
    required this.section,
    required this.title,
    List<RuntimePlayerDetailEntrySnapshot> entries =
        const <RuntimePlayerDetailEntrySnapshot>[],
    this.emptyMessage,
  }) : entries = List<RuntimePlayerDetailEntrySnapshot>.unmodifiable(entries) {
    if (section == RuntimePlayerPauseSection.root) {
      throw ArgumentError.value(
        section,
        'section',
        'the pause root is navigation, not a detail surface',
      );
    }
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'must not be empty');
    }
  }

  final RuntimePlayerPauseSection section;
  final String title;
  final List<RuntimePlayerDetailEntrySnapshot> entries;
  final String? emptyMessage;
}

/// Optional runtime-owned projection queried only while gameplay is paused.
///
/// The Hub and a future standalone host both consume the same data-only
/// snapshots. Neither host reads or interprets the live [GameState].
abstract interface class RuntimePlayerPauseDataPort {
  Future<Map<RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>>
      loadPauseDetails();
}

Map<RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>
    immutableRuntimePlayerPauseDetails(
  Map<RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot> details,
) {
  return UnmodifiableMapView<RuntimePlayerPauseSection,
      RuntimePlayerPauseDetailSnapshot>(
    Map<RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>.from(
      details,
    ),
  );
}
