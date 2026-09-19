import 'dart:convert';

import 'package:map_authoring/map_authoring_narrative.dart';
import 'package:map_core/map_core_domain.dart';

import '../domain/dialogue_draft.dart';
import '../domain/narrative_port.dart';

class DialogueDraftCodec {
  const DialogueDraftCodec();
  static const marker = 'avelune_visual_dialogue_v1';

  NarrativeDialogueSource encode(DialogueDraft draft) {
    if (draft.branches.isEmpty) {
      throw const NarrativeFailure('Ajoutez une réplique.');
    }
    final ids = draft.branches.map((branch) => branch.id).toSet();
    if (ids.length != draft.branches.length ||
        ids.any((id) => !RegExp(r'^[A-Za-z0-9_]+$').hasMatch(id))) {
      throw const NarrativeFailure(
        'Les destinations du dialogue sont invalides.',
      );
    }
    final source = StringBuffer();
    final outcomes = <String, String>{};
    for (final branch in draft.branches) {
      source.writeln('title: ${branch.id}');
      source.writeln('avelune: ${jsonEncode(branch.name)}');
      source.writeln('---');
      for (final line in branch.lines) {
        if (line.speakerId != null && line.portraitStateId != null) {
          _token(line.speakerId!);
          _token(line.portraitStateId!);
          source.writeln(
            '<<portrait ${line.speakerId} ${line.portraitStateId}>>',
          );
        } else if (line.speakerId != null) {
          _token(line.speakerId!);
          source.writeln('<<speaker ${line.speakerId}>>');
        }
        source.writeln('\\${jsonEncode(line.text)}');
      }
      for (final choice in branch.choices) {
        if (!ids.contains(choice.targetId)) {
          throw const NarrativeFailure('Un choix a perdu sa destination.');
        }
        source.writeln('-> \\${jsonEncode(choice.text)}');
        if (choice.outcomeId case final String outcome) {
          _token(outcome);
          outcomes[outcome] = choice.text;
          source.writeln('    <<outcome $outcome>>');
        }
        source.writeln('    <<jump ${choice.targetId}>>');
      }
      source.writeln('===');
    }
    final entry = draft.entry.copyWith(
      defaultStartNode: draft.branches.first.id,
      tags: {...draft.entry.tags, marker}.toList(),
      declaredOutcomes: [
        for (final outcome in outcomes.entries)
          DialogueDeclaredOutcome(id: outcome.key, label: outcome.value),
      ],
    );
    final compiled = const DialogueAuthoringCompiler().compile(
      entry: entry,
      source: source.toString(),
    );
    if (!compiled.canPublish) {
      throw const NarrativeFailure(
        'Le dialogue contient une branche vide ou invalide.',
      );
    }
    return NarrativeDialogueSource(
      entry: entry,
      source: source.toString(),
      revision: draft.sourceRevision,
    );
  }

  DialogueDraft? decode(NarrativeDialogueSource source) {
    if (!source.entry.tags.contains(marker)) return null;
    try {
      final document = const YarnDialogueCompiler().compile(source.source);
      final names = <String, String>{};
      String? title;
      for (final line in source.source.split('\n')) {
        if (line.startsWith('title: ')) title = line.substring(7);
        if (line.startsWith('avelune: ') && title != null) {
          names[title] = jsonDecode(line.substring(9)) as String;
        }
      }
      final branches = <DialogueBranchDraft>[];
      for (final node in document.nodes) {
        final lines = <DialogueLineDraft>[];
        final choices = <DialogueChoiceDraft>[];
        for (final step in node.steps) {
          if (step is RuntimeDialogueLine && choices.isEmpty) {
            lines.add(
              DialogueLineDraft(
                text: step.text,
                speakerId: step.characterId,
                portraitStateId: step.portraitStateId,
              ),
            );
          } else if (step is RuntimeDialogueChoiceBlock && choices.isEmpty) {
            for (final choice in step.choices) {
              if (choice.steps.length != 1 ||
                  choice.steps.single is! RuntimeDialogueJump) {
                return null;
              }
              choices.add(
                DialogueChoiceDraft(
                  text: choice.text,
                  targetId:
                      (choice.steps.single as RuntimeDialogueJump).targetNode,
                  outcomeId: choice.outcomeId,
                ),
              );
            }
          } else {
            return null;
          }
        }
        branches.add(
          DialogueBranchDraft(
            id: node.title,
            name: names[node.title] ?? node.title,
            lines: lines,
            choices: choices,
          ),
        );
      }
      final draft = DialogueDraft(
        entry: source.entry,
        branches: branches,
        sourceRevision: source.revision,
      );
      final rebuilt = encode(draft);
      if (rebuilt.source != source.source ||
          rebuilt.entry.defaultStartNode != source.entry.defaultStartNode ||
          jsonEncode(rebuilt.entry.declaredOutcomes) !=
              jsonEncode(source.entry.declaredOutcomes)) {
        return null;
      }
      return draft;
    } on Object {
      return null;
    }
  }

  void _token(String value) {
    if (!RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(value)) {
      throw const NarrativeFailure('Une référence du dialogue est invalide.');
    }
  }
}
