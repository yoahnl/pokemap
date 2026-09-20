import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:avelune_studio/features/cinematics/data/local_cinematic_adapter.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_editing.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import '../support/m3_story_fixture.dart';

void main() {
  late M3StoryFixture f;
  late MapWorkspaceController maps;
  late NarrativeWorkspaceController n;
  late CinematicWorkspaceController c;
  late LocalCinematicAdapter port;
  setUp(() async {
    f = await M3StoryFixture.create();
    maps = MapWorkspaceController(f.session, f.maps);
    await maps.initialize();
    n = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: f.session, mapAdapter: f.maps),
      () {},
      (_, _) async {},
    );
    port = LocalCinematicAdapter(session: f.session, mapAdapter: f.maps);
    c = CinematicWorkspaceController(n, port, changed: () {});
  });
  tearDown(() async {
    c.dispose();
    n.dispose();
    maps.dispose();
    await f.directory.delete(recursive: true);
  });
  test(
    'full and simplified dirty ownership is reciprocal; publication invalidates only clean owners',
    () async {
      final record = n.project.eventRegistry!.records.firstWhere(
        (r) => n.project.scenes
            .firstWhere((s) => s.id == r.definitionOrNull!.sceneId)
            .graph
            .nodes
            .any((node) => node.payload.toJson()['cinematicId'] != null),
      );
      expect(await n.openRecord(record), true);
      final simple = n.active!;
      final id = n.interactionCinematicIds(simple).first;
      expect(await c.open(id), true, reason: c.error);
      c.rename('Version complète');
      simple.change(
        interaction: simple.current.interaction.revise(name: 'Refusé'),
      );
      expect(simple.dirty, false);
      expect(simple.error, contains('brouillon complet'));
      c.undo();
      simple.change(
        interaction: simple.current.interaction.revise(
          name: 'Version simplifiée',
        ),
      );
      expect(simple.dirty, true);
      expect(await c.open(id), false);
      expect(c.error, contains('simplifiée'));
      expect(simple.current.interaction.name, 'Version simplifiée');
      simple.restore(redo: false);
      expect(await c.open(id), true);
      c.rename('Version complète');
      expect(await c.save(), true, reason: c.error);
      expect(n.sessions.containsValue(simple), false);
      expect(await n.openRecord(record), false);
      expect(n.error, contains('avancée'));
      expect((await port.load(id)).asset.title, 'Version complète');
    },
  );
  test(
    'changed cinematic base refuses stale simplified publication even when scene is unchanged',
    () async {
      final record = n.project.eventRegistry!.records.firstWhere(
        (r) => n.project.scenes
            .firstWhere((s) => s.id == r.definitionOrNull!.sceneId)
            .graph
            .nodes
            .any((node) => node.payload.toJson()['cinematicId'] != null),
      );
      expect(await n.openRecord(record), true);
      final simple = n.active!, id = n.interactionCinematicIds(n.active!).first;
      simple.change(
        interaction: simple.current.interaction.revise(
          name: 'Brouillon conservé',
        ),
      );
      final base = await port.load(id);
      final receipt = await port.publish(
        id: id,
        base: base,
        asset: base.asset.copyWith(title: 'Titre externe'),
      );
      maps.acceptResources(
        receipt.resources.before,
        receipt.resources.manifest,
      );
      expect(await n.save(document: simple.document), false);
      expect(simple.dirty, true);
      expect(n.error, contains('cinématique liée a changé'));
      expect((await port.load(id)).asset.title, 'Titre externe');
    },
  );
}
