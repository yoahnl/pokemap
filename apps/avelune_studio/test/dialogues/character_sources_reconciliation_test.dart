import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import '../support/event_backend_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'changed Yarn invalidates only clean affected sessions and preview',
    () async {
      final fixture = await EventBackendFixture.create();
      addTearDown(fixture.dispose);
      final controller = DialogueWorkspaceController(
        fixture.narrative,
        LocalDialogueAdapter(
          session: fixture.source.session,
          mapAdapter: fixture.source.maps,
        ),
        changed: () {},
      );
      addTearDown(controller.dispose);
      final entries = controller.entries;
      final affected = entries.first;
      final other = entries.last;
      expect(affected.id, isNot(other.id));
      await controller.open(other.id);
      final otherSession = controller.active!;
      await controller.open(affected.id);
      expect(controller.startPreview(), true);
      final reads = controller.sourceReads;
      final file = File(
        '${fixture.source.directory.path}/${affected.relativePath}',
      );
      final before = await file.readAsString();
      final changed = before.replaceFirst('Bienvenue', 'Version remplacée');
      expect(changed, isNot(before));
      await file.writeAsString(changed);
      controller.invalidateCharacterSources({affected.id});
      expect(controller.session(affected.id), isNull);
      expect(controller.preview, isNull);
      expect(controller.session(other.id), same(otherSession));
      await controller.open(affected.id);
      expect(controller.sourceReads, reads + 1);
      expect(controller.active!.source, contains('Version remplacée'));
      final node = controller.active!.document.nodes.first;
      controller.addLine(node.id, text: 'Brouillon conservé');
      final draft = controller.active!.source;
      expect(controller.characterSourceProblem({affected.id}), isNotNull);
      expect(
        () => controller.invalidateCharacterSources({affected.id}),
        throwsStateError,
      );
      expect(controller.active!.source, draft);
      expect(controller.active!.dirty, true);
    },
  );
}
