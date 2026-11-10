import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:avelune_studio/features/cinematics/domain/cinematic_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workflow.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  test(
    'published cinematic test preserves dirty dependencies and focused invalid edit blocks close',
    () async {
      final maps = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      await maps.initialize();
      final document = maps.active!;
      final narrativePort = _Narrative();
      final narrative = NarrativeWorkspaceController(
        maps,
        narrativePort,
        () {},
        (_, _) async {},
      );
      final c = CinematicWorkspaceController(
        narrative,
        _Cinematic(document.current.id),
        changed: () {},
      );
      await c.open('film');
      document.commit(document.current.copyWith(name: 'Carte à préserver'));
      var launches = 0;
      var closePrompts = 0;
      final actions = WorkspaceWorkflow(
        controller: maps,
        isActive: () => true,
        changed: () {},
        resources: () => null,
        narrative: () => narrative,
        cinematics: () => c,
        publishedCinematicContext: () => true,
        confirmClose: () async {
          closePrompts++;
          return WorkspaceCloseChoice.cancel;
        },
        flushFocus: () {},
        launchMap: (_, _) async {
          launches++;
        },
      );
      await actions.test();
      expect(launches, 0);
      expect(narrativePort.writes, 0);
      expect(document.dirty, true);
      expect(document.current.name, 'Carte à préserver');
      expect(c.error, contains('aucun brouillon n’a été publié'));
      c.flushEdits = () => false;
      expect(await actions.allowClose(), false);
      expect(closePrompts, 0);
      expect(await c.saveAll(), false);
      c.dispose();
      narrative.dispose();
      maps.dispose();
    },
  );
}

class _Narrative implements NarrativePort {
  int writes = 0;
  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication publication,
  ) async {
    writes++;
    throw StateError('Aucune publication attendue');
  }

  @override
  Future<NarrativeDialogueSource> readDialogue(ProjectDialogueEntry entry) =>
      throw UnimplementedError();
}

class _Cinematic implements CinematicPort {
  _Cinematic(this.mapId);
  final String mapId;
  @override
  Future<CinematicSourceSnapshot> load(String id) async =>
      CinematicSourceSnapshot(
        asset: CinematicAsset(
          id: id,
          title: 'Film',
          mapId: mapId,
          timeline: CinematicTimeline(),
        ),
        revision: 'fixture',
      );
  @override
  Future<CinematicPublicationReceipt> publish({
    required String id,
    required CinematicSourceSnapshot? base,
    required CinematicAsset asset,
    String? folderId,
  }) => throw UnimplementedError();
  @override
  Future<CinematicPublicationReceipt> delete({
    required CinematicSourceSnapshot base,
  }) => throw UnimplementedError();
  @override
  Future<CinematicPublicationReceipt> setArchived({
    required CinematicSourceSnapshot base,
    required bool archived,
  }) => throw UnimplementedError();
}
