import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_editing.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  late MapWorkspaceController maps;
  late NarrativeWorkspaceController narrative;
  late _Port port;
  final advanced = NarrativeEventRecord.draft(
    NarrativeEventDraft(
      id: 'evt_00000000-0000-7000-8000-000000000002',
      name: 'Interaction avancée',
      source: NarrativeEventSourceRef.entityInteract('a', 'chief'),
      conditions: [],
      priority: 0,
      order: 0,
    ),
  );

  setUp(() async {
    maps = MapWorkspaceController(workspaceSession, WorkspaceMemoryPort());
    await maps.initialize();
    port = _Port(maps);
    narrative = NarrativeWorkspaceController(
      maps,
      port,
      () {},
      (_, _) async {},
    );
  });
  tearDown(() => maps.dispose());

  test(
    'advanced interaction warning remains local after map and resource navigation',
    () async {
      final original = maps.active!;
      original.commit(original.current.copyWith(name: 'Carte modifiée'));
      await narrative.openSource(
        original,
        NarrativeEventSourceRef.entityInteract('a', 'other'),
        'Brouillon conservé',
      );
      final draft = narrative.active!;
      draft.change(
        interaction: draft.current.interaction.revise(name: 'En cours'),
      );
      final snapshot = draft.current;
      expect(await narrative.openRecord(advanced), false);
      expect(narrative.error, contains('avancée'));
      expect(
        workspaceNarrativeError(narrative, narrativePage: true),
        contains('avancée'),
      );
      expect(workspaceNarrativeError(narrative, narrativePage: false), isNull);
      await maps.activate(workspaceEntries.last);
      expect(workspaceNarrativeError(narrative, narrativePage: false), isNull);
      expect(narrative.sessions.values, contains(draft));
      expect(draft.current, same(snapshot));
      expect(draft.dirty, true);
      expect(original.dirty, true);
      expect(original.canUndo, true);
      expect(port.publications, 0);
    },
  );

  test(
    'failed publication stays visible through consultation until successful retry',
    () async {
      final original = maps.active!;
      narrative.addFact('Aide acceptée');
      port.fail = true;
      expect(await narrative.save(), false);
      expect(
        workspaceNarrativeError(narrative, narrativePage: false),
        contains('Conflit'),
      );
      expect(await narrative.openRecord(advanced), false);
      expect(narrative.error, contains('avancée'));
      expect(
        workspaceNarrativeError(narrative, narrativePage: false),
        contains('Conflit'),
      );
      await maps.activate(workspaceEntries.last);
      expect(
        workspaceNarrativeError(narrative, narrativePage: false),
        contains('Conflit'),
      );
      expect(narrative.pendingFacts, hasLength(1));
      port.fail = false;
      expect(await narrative.save(document: original), true);
      expect(narrative.pendingFacts, isEmpty);
      expect(workspaceNarrativeError(narrative, narrativePage: false), isNull);
    },
  );
}

class _Port implements NarrativePort {
  _Port(this.maps);
  final MapWorkspaceController maps;
  bool fail = false;
  int publications = 0;

  @override
  Future<NarrativeDialogueSource> readDialogue(ProjectDialogueEntry entry) =>
      throw UnimplementedError();

  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication publication,
  ) async {
    publications++;
    if (fail) throw const NarrativeFailure('Conflit de publication');
    return NarrativePublicationReceipt(
      beforeManifest: maps.project!,
      manifest: maps.project!,
      savedMap: publication.current,
      revision: 'published-$publications',
      sourceRevisions: {},
      changedPaths: [],
    );
  }
}
