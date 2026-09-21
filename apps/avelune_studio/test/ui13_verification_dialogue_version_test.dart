import 'dart:io';

import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/interaction_edit_session.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction.dart';
import 'package:avelune_studio/features/narrative/domain/dialogue_draft.dart';
import 'package:avelune_studio/features/verification/application/verification_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/ui06_scene_fixture.dart';
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
  test('an advanced read-only source is not simplified', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    const raw =
        'title: Start\n---\nSource avancée conservée telle quelle.\n===\n';
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
      readOnlySource: raw,
    );

    final captured = h.verification.openSource(_welcome);
    expect(captured.problem, isNull);
    expect(
      captured.source!.source,
      raw,
      reason: 'the original source is kept, not its simplified re-encoding',
    );
    final report = await analysed(h);
    expect(report.exclusions, isEmpty);
    expect(
      report.scope.any((line) => line.contains('3 source(s) de dialogue')),
      isTrue,
    );
  });

  test(
    'two incompatible versions of one dialogue are a named conflict',
    () async {
      final h = await Ui13VerificationHarness.create();
      addTearDown(h.dispose);
      final entry = h.narrative.project.dialogues.firstWhere(
        (item) => item.id == _welcome,
      );
      expect(
        await h.dialogues.open(_welcome),
        isTrue,
        reason: h.dialogues.error,
      );
      final line = h.dialogues.active!.document.nodes.first.steps
          .whereType<DeLineStep>()
          .first;
      expect(h.dialogues.updateLine(line.id, text: 'Version A'), isTrue);

      await h.maps.activate(h.maps.project!.maps.first);
      final session = InteractionEditSession(
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
      );
      session.change(
        dialogue: DialogueDraft(
          entry: entry,
          branches: const [
            DialogueBranchDraft(
              id: 'Start',
              name: 'Début',
              lines: [DialogueLineDraft(text: 'Version B')],
            ),
          ],
        ),
      );
      expect(session.dirty, isTrue);
      h.narrative.sessions['interaction'] = session;

      final conflict = h.verification.openSource(_welcome);
      expect(
        conflict.problem,
        isNotNull,
        reason: 'neither version is chosen over the other',
      );
      expect(conflict.source, isNull);

      final report = await analysed(h);
      expect(
        report.exclusions.any(
          (item) => item.owner == 'Dialogues' && item.label == _welcome,
        ),
        isTrue,
      );
      expect(dialogueFaults(report, _welcome), isEmpty);
    },
  );

  test('the fixture really exercises the authoring compiler', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    await sourceFile(
      h,
      Ui06SceneFixture.sceneId,
    ).parent.create(recursive: true);
    await sourceFile(h, _welcome).writeAsString(_faulty);
    await sourceFile(h, _refusal).writeAsString(_faulty);
    final report = await analysed(h);
    expect(dialogueFaults(report, _welcome), hasLength(1));
    expect(dialogueFaults(report, _refusal), hasLength(1));
    expect(
      report.diagnostics
          .where(
            (item) => item.domain == NarrativeProjectDiagnosticDomain.dialogue,
          )
          .map((item) => item.stableKey)
          .toSet(),
      hasLength(2),
      reason: 'each dialogue keeps its own identity, no duplicate',
    );
  });
}
