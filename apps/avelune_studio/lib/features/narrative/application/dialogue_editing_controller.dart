import '../domain/dialogue_draft.dart';
import 'interaction_edit_session.dart';
import 'narrative_editing.dart';

class DialogueEditingController {
  DialogueEditingController(this.session, this.changed);
  final InteractionEditSession session;
  final void Function() changed;
  DialogueDraft get draft => session.current.dialogue;
  DialogueBranchDraft get branch => draft.branches[session.branchIndex];
  void updateBranch(DialogueBranchDraft next) {
    final branches = [...draft.branches];
    branches[session.branchIndex] = next;
    _change(draft.copyWith(branches: branches));
    changed();
  }

  void line(int index, DialogueLineDraft value) {
    final lines = [...branch.lines];
    lines[index] = value;
    updateBranch(branch.copyWith(lines: lines));
  }

  void addLine() => updateBranch(
    branch.copyWith(
      lines: [
        ...branch.lines,
        const DialogueLineDraft(text: ''),
      ],
    ),
  );
  void removeLine(int index) =>
      updateBranch(branch.copyWith(lines: [...branch.lines]..removeAt(index)));
  void moveLine(int index, int delta) {
    final to = index + delta;
    if (to < 0 || to >= branch.lines.length) return;
    final lines = [...branch.lines];
    lines.insert(to, lines.removeAt(index));
    updateBranch(branch.copyWith(lines: lines));
  }

  void addBranch(String name) {
    final id = 'suite_${DateTime.now().microsecondsSinceEpoch}';
    session.change(
      dialogue: draft.copyWith(
        branches: [
          ...draft.branches,
          DialogueBranchDraft(
            id: id,
            name: name,
            lines: [const DialogueLineDraft(text: '')],
          ),
        ],
      ),
    );
    session.branchIndex = draft.branches.length - 1;
    changed();
  }

  bool removeBranch() {
    if (session.branchIndex == 0 ||
        draft.branches.any(
          (b) => b.choices.any((c) => c.targetId == branch.id),
        )) {
      return false;
    }
    final branches = [...draft.branches]..removeAt(session.branchIndex);
    session.branchIndex = 0;
    _change(draft.copyWith(branches: branches));
    changed();
    return true;
  }

  void choice(int index, DialogueChoiceDraft value) {
    final choices = [...branch.choices];
    choices[index] = value;
    updateBranch(branch.copyWith(choices: choices));
  }

  void addChoice() => updateBranch(
    branch.copyWith(
      choices: [
        ...branch.choices,
        DialogueChoiceDraft(
          text: 'Nouveau choix',
          targetId: draft.branches.last.id,
          outcomeId: 'choix_${DateTime.now().microsecondsSinceEpoch}',
        ),
      ],
    ),
  );
  void removeChoice(int index) => updateBranch(
    branch.copyWith(choices: [...branch.choices]..removeAt(index)),
  );

  void _change(DialogueDraft next) {
    final outcomes = next.branches
        .expand((branch) => branch.choices)
        .map((choice) => choice.outcomeId)
        .toSet();
    final effects = session.current.interaction.branches;
    session.change(
      dialogue: next,
      interaction: session.current.interaction.revise(
        branches: {
          for (final outcome in outcomes.whereType<String>())
            outcome: effects[outcome] ?? [],
        },
      ),
    );
  }
}
