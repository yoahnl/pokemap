import 'package:map_core/map_core_domain.dart';

class DialogueLineDraft {
  const DialogueLineDraft({
    required this.text,
    this.speakerId,
    this.portraitStateId,
  });
  final String text;
  final String? speakerId;
  final String? portraitStateId;
}

class DialogueChoiceDraft {
  const DialogueChoiceDraft({
    required this.text,
    required this.targetId,
    this.outcomeId,
  });
  final String text;
  final String targetId;
  final String? outcomeId;
}

class DialogueBranchDraft {
  const DialogueBranchDraft({
    required this.id,
    required this.name,
    this.lines = const [],
    this.choices = const [],
  });
  final String id;
  final String name;
  final List<DialogueLineDraft> lines;
  final List<DialogueChoiceDraft> choices;

  DialogueBranchDraft copyWith({
    String? name,
    List<DialogueLineDraft>? lines,
    List<DialogueChoiceDraft>? choices,
  }) => DialogueBranchDraft(
    id: id,
    name: name ?? this.name,
    lines: lines ?? this.lines,
    choices: choices ?? this.choices,
  );
}

class DialogueDraft {
  const DialogueDraft({
    required this.entry,
    required this.branches,
    this.sourceRevision,
  });
  factory DialogueDraft.blank(ProjectDialogueEntry entry) => DialogueDraft(
    entry: entry,
    branches: [
      const DialogueBranchDraft(
        id: 'Start',
        name: 'Début',
        lines: [DialogueLineDraft(text: '')],
      ),
    ],
  );
  final ProjectDialogueEntry entry;
  final List<DialogueBranchDraft> branches;
  final String? sourceRevision;

  DialogueDraft copyWith({
    ProjectDialogueEntry? entry,
    List<DialogueBranchDraft>? branches,
  }) => DialogueDraft(
    entry: entry ?? this.entry,
    branches: branches ?? this.branches,
    sourceRevision: sourceRevision,
  );
}
