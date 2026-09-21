import 'dart:io';

import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/interaction_edit_session.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction.dart';
import 'package:avelune_studio/features/narrative/domain/dialogue_draft.dart';
import 'package:avelune_studio/features/verification/application/verification_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/ui13_verification_harness.dart';

const _welcome = 'station_welcome';
const _refusal = 'station_refusal';

/// A source the authoring compiler really refuses: a public outcome outside a
/// choice branch. The fixture writes it; no UI09 protection is disabled.
const _faulty = '''
title: Start
---
Le chef de gare hésite.
<<outcome refus>>
===
''';

File sourceFile(Ui13VerificationHarness h, String id) =>
    File('${h.directory.path}/dialogues/$id.yarn');

Future<Map<String, int>> footprint(Directory directory) async {
  final sizes = <String, int>{};
  await for (final entity in directory.list(recursive: true)) {
    if (entity is File) {
      sizes[entity.path] = (await entity.readAsBytes()).fold(
        0,
        (sum, byte) => sum * 31 + byte & 0x7fffffff,
      );
    }
  }
  return sizes;
}

List<NarrativeProjectDiagnostic> dialogueFaults(
  VerificationReport report,
  String id,
) => [
  for (final item in report.diagnostics)
    if (item.domain == NarrativeProjectDiagnosticDomain.dialogue &&
        item.dialogueId == id)
      item,
];

Future<VerificationReport> analysed(Ui13VerificationHarness h) async {
  expect(await h.verification.run(), isTrue, reason: h.verification.error);
  return h.verification.report!;
}

void main() {
  test('an unopened dialogue is checked from its saved source', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    expect(await analysed(h), isNotNull);
    expect(
      dialogueFaults(h.verification.report!, _welcome),
      isEmpty,
      reason: 'the published fixture compiles cleanly',
    );

    await sourceFile(h, _welcome).writeAsString(_faulty);
    final report = await analysed(h);
    final faults = dialogueFaults(report, _welcome);
    expect(
      faults,
      isNotEmpty,
      reason: 'a dialogue nobody opened is still read and compiled',
    );
    expect(faults.single.code, 'dialogue.outcome_outside_choice');
    expect(faults.single.severity, NarrativeProjectDiagnosticSeverity.error);
    expect(
      faults.single.destination,
      NarrativeProjectDiagnosticDestination.dialogue,
    );
    expect(report.labelFor(faults.single), isNotEmpty);
    expect(
      report.dimensions.structurallyValid.status,
      NarrativeValidationStatus.fail,
      reason: 'a dialogue error weighs in the report like any other',
    );
  });

  test('a text changed in the editor is the one that gets compiled', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    final before = await footprint(h.directory);
    final first = await analysed(h);
    expect(dialogueFaults(first, _welcome), isEmpty);

    expect(await h.dialogues.open(_welcome), isTrue, reason: h.dialogues.error);
    final line = h.dialogues.active!.document.nodes.first.steps
        .whereType<DeLineStep>()
        .first;
    expect(
      h.dialogues.updateLine(line.id, text: 'Texte revu sans enregistrement'),
      isTrue,
      reason: h.dialogues.error,
    );

    expect(
      h.verification.stale,
      isTrue,
      reason: 'a text alone moves the working version',
    );
    final second = await analysed(h);
    expect(
      second.inputFingerprint,
      isNot(first.inputFingerprint),
      reason: 'the fingerprint follows the text handed to the compiler',
    );
    expect(
      second.scope.any((line) => line.contains('source(s) de dialogue')),
      isTrue,
    );
    expect(
      await footprint(h.directory),
      before,
      reason: 'checking a draft never publishes it',
    );
  });

  test('an unsaved source is compiled, not published', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    final before = await footprint(h.directory);
    expect(dialogueFaults(await analysed(h), _welcome), isEmpty);

    final entry = h.narrative.project.dialogues.firstWhere(
      (item) => item.id == _welcome,
    );
    await h.maps.activate(h.maps.project!.maps.first);
    h.narrative.sessions['interaction'] = InteractionEditSession(
      document: h.maps.active!,
      dialogue: DialogueDraft.blank(entry),
      interaction: NarrativeInteractionDraft(
        id: 'interaction',
        name: 'Chef de gare',
        mapId: h.maps.project!.maps.first.id,
        source: NarrativeEventSourceRef.entityInteract(
          h.maps.project!.maps.first.id,
          'npc',
        ),
        dialogueId: entry.id,
      ),
      readOnlySource: _faulty,
    );

    final report = await analysed(h);
    expect(
      dialogueFaults(report, _welcome),
      isNotEmpty,
      reason: 'the version held by an editor is what the compiler saw',
    );
    expect(
      await footprint(h.directory),
      before,
      reason: 'nothing was published in the author’s place',
    );
  });

  test('an unreadable source is named, never counted as clean', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    await sourceFile(h, _refusal).delete();

    final report = await analysed(h);
    expect(
      report.exclusions.any(
        (item) => item.owner == 'Dialogues' && item.label == _refusal,
      ),
      isTrue,
      reason: 'a source that could not be read is declared out of coverage',
    );
    expect(report.limitations.any((item) => item.contains(_refusal)), isTrue);
    expect(
      dialogueFaults(report, _refusal),
      isEmpty,
      reason: 'nothing is compiled from a source that was never read',
    );
    expect(
      report.scope.any((line) => line.contains('2 source(s) de dialogue')),
      isTrue,
      reason: 'the scope counts what was really compiled',
    );
  });
}
