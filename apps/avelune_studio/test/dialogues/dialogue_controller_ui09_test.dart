import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import '../support/event_backend_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late EventBackendFixture f;
  late DialogueWorkspaceController c;
  setUp(() async {
    f = await EventBackendFixture.create();
    c = DialogueWorkspaceController(
      f.narrative,
      LocalDialogueAdapter(
        session: f.source.session,
        mapAdapter: f.source.maps,
      ),
      changed: () {},
    );
  });
  tearDown(() async {
    c.dispose();
    await f.dispose();
  });
  test(
    'lazy library, reply choices shared targets outcomes save reopen and deterministic identities',
    () async {
      expect(c.entries.length, greaterThan(1));
      expect(c.sourceReads, 0);
      await c.create('Chef de gare');
      final doc = c.active!.document;
      final start = doc.nodes.single.id;
      final reply = doc.nodes.single.steps.whereType<DeLineStep>().single.id;
      expect(c.updateLine(reply, text: 'Bonjour !', speaker: 'Chef'), true);
      final later = c.addNode('Attendre')!;
      c.addLine(later, text: 'Prenez votre temps.');
      final depart = c.addNode('Partir')!;
      c.addLine(depart, text: 'Bon voyage.');
      final choice = c.addChoice(start)!;
      final yes = c.addResponse(choice, 'Je pars')!;
      final no = c.addResponse(choice, 'Je reste')!;
      expect(c.connect(yes, depart), true);
      expect(c.connect(no, later), true);
      final outcome = c.addOutcome('Partir')!;
      c.assignOutcome(yes, outcome);
      c.reorderResponse(yes, 1);
      final branches = c.active!.document
          .nodeById(start)!
          .steps
          .whereType<DeChoiceStep>()
          .single
          .branches;
      expect(branches.last.id, yes);
      expect(branches.last.outcomeId, outcome);
      expect(c.startPreview(), true);
      expect(c.preview!.line!.text, 'Chef: Bonjour !');
      c.advancePreview();
      expect(c.preview!.choices.length, 2);
      c.choosePreview(1);
      expect(c.preview!.line!.text, 'Bon voyage.');
      c.advancePreview();
      expect(c.preview!.ended, true);
      expect(c.preview!.outcomes, [outcome]);
      expect(await c.save(), true, reason: c.error);
      expect(c.active!.dirty, false);
      final id = c.activeId!;
      expect(await c.reload(), true, reason: c.error);
      expect(c.activeId, id);
      expect(c.active!.document.nodes.first.id, start);
      expect(c.active!.readOnlyReason, isNull);
      c.startPreview();
      c.advancePreview();
      c.choosePreview(0);
      expect(c.preview!.line!.text, 'Prenez votre temps.');
      expect(c.preview!.outcomes, isEmpty);
    },
  );
  test(
    'deep immutable snapshot and semantic history preserve branch content, rejects unsafe replacement',
    () async {
      await c.create('Conversation');
      final start = c.active!.document.nodes.single.id;
      final reply = c.active!.document.nodes.single.steps
          .whereType<DeLineStep>()
          .single;
      expect(() => reply.body = 'mutation externe', throwsUnsupportedError);
      c.updateLine(reply.id, text: 'Original');
      final next = c.addNode('Suite')!;
      c.addLine(next, text: 'La suite');
      final choice = c.addChoice(start)!;
      final b = c.addResponse(choice, 'Réponse')!;
      c.connect(b, next);
      final snapshot = c.active!;
      c.updateResponse(b, 'Éditée');
      c.disconnect(b);
      c.undo();
      c.undo();
      expect(c.active!.source, snapshot.source);
      expect(c.connect(b, start), false);
      expect(c.error, contains('remplacement'));
      expect(c.connect(b, start, replace: true), true);
      c.redo();
      expect(c.active!.document.nodes.length, 2);
    },
  );
  test(
    'canonical preview stops jump loops and refuses missing scene entry',
    () async {
      await c.create('Boucle');
      final start = c.active!.document.nodes.single.id;
      final reply = c.active!.document.nodes.single.steps
          .whereType<DeLineStep>()
          .single
          .id;
      c.removeStep(reply);
      c.connectNode(start, start);
      expect(c.startPreview(), true);
      expect(c.preview!.truncated, true);
      expect(c.preview!.ended, false);
      expect(c.startPreview(nodeTitle: 'Absent'), false);
      expect(c.preview!.error, contains('start node'));
    },
  );
  test(
    'literal command-looking multiline text remains text through strict compiler and codec',
    () async {
      await c.create('Littéraux');
      final reply = c.active!.document.nodes.single.steps
          .whereType<DeLineStep>()
          .single
          .id;
      const text = '  <<jump Piège>>\n-> Rien : été, "oui" !  ';
      c.updateLine(reply, text: text);
      expect(c.startPreview(), true);
      expect(c.preview!.line!.text, text);
      expect(await c.save(), true, reason: c.error);
      expect(await c.reload(), true);
      expect(
        c.active!.document.nodes.single.steps
            .whereType<DeLineStep>()
            .single
            .body,
        text,
      );
      expect(c.active!.readOnlyReason, isNull);
    },
  );
}
