import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/workspace_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets(
    'failed narrative publication blocks runtime and saving close without losing either map',
    (tester) async {
      final maps = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      await maps.initialize();
      final first = maps.active!;
      first.commit(first.current.copyWith(name: 'Première carte modifiée'));
      await maps.activate(workspaceEntries.last);
      final second = maps.active!;
      second.commit(second.current.copyWith(name: 'Deuxième carte modifiée'));
      final failing = _FailingNarrativePort();
      final narrative = NarrativeWorkspaceController(
        maps,
        failing,
        () {},
        (_, _) async {},
      );
      narrative.addFact('À conserver');
      late WorkspaceActions actions;
      var launches = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              actions = WorkspaceActions(
                controller: maps,
                context: () => context,
                mounted: () => true,
                changed: () {},
                resources: () => null,
                narrative: () => narrative,
                runtimeBuilder: (_, _, _) {
                  launches++;
                  return const SizedBox();
                },
              );
              return const Scaffold(body: Text('Éditeur'));
            },
          ),
        ),
      );
      await actions.test();
      expect(launches, 0);
      expect(actions.testing, isFalse);
      expect(failing.attempts, 1);
      expect(first.dirty, isTrue);
      expect(second.dirty, isTrue);
      expect(narrative.pendingFacts, hasLength(1));
      final close = actions.allowClose();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(await close, isFalse);
      expect(actions.closing, isFalse);
      expect(failing.attempts, 2);
      expect(first.current.name, 'Première carte modifiée');
      expect(second.current.name, 'Deuxième carte modifiée');
      expect(first.dirty, isTrue);
      expect(second.dirty, isTrue);
      expect(narrative.pendingFacts, hasLength(1));
      expect(narrative.error, contains('Conflit externe'));
      await tester.pumpWidget(const SizedBox());
      maps.dispose();
    },
  );
}

class _FailingNarrativePort implements NarrativePort {
  var attempts = 0;
  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication publication,
  ) async {
    attempts++;
    throw const NarrativeFailure('Conflit externe simulé');
  }

  @override
  Future<NarrativeDialogueSource> readDialogue(ProjectDialogueEntry entry) =>
      throw UnimplementedError();
}
