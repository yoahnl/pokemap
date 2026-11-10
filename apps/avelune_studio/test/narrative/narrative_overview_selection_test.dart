import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/narrative/application/narrative_overview_projection.dart';
import 'package:avelune_studio/features/narrative/application/narrative_overview_selection.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/m3_story_fixture.dart';

void main() {
  test('filtering clears hidden consultation selection while retaining the exact interaction draft and disk data', () async {
    final fixture = await M3StoryFixture.create();
    addTearDown(() => fixture.directory.delete(recursive: true));
    final maps = MapWorkspaceController(fixture.session, fixture.maps);
    addTearDown(maps.dispose);
    await maps.initialize();
    final narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: fixture.session, mapAdapter: fixture.maps),
      () {},
      (_, _) async {},
    );
    addTearDown(narrative.dispose);
    final document = maps.active!;
    final entity = document.current.entities.singleWhere(
      (entity) => entity.id == 'chief',
    );
    await narrative.openNpc(document, entity);
    final session = narrative.active!;
    session.change(dialogue: session.current.dialogue.copyWith());
    final before = await LocalMapWorkspaceAdapter().loadProject(
      fixture.session,
    );
    final overview = buildNarrativeOverview(narrative);
    final state = NarrativeOverviewSelection()
      ..tab = NarrativeOverviewTab.interactions;
    final id = session.current.interaction.id;
    state.select(interaction: id);
    state.mapId = 'hidden-map';
    state.reconcileSelection(overview);
    expect(state.interactionId, isNull);
    expect(state.detailVisible, isFalse);
    state.mapId = null;
    state.reconcileSelection(overview);
    expect(state.interactionId, isNull);
    state.select(interaction: id);
    state.query = 'aucun résultat pour cette recherche';
    state.reconcileSelection(overview);
    expect(state.interactionId, isNull);
    state.query = '';
    final clean = overview.interactions.firstWhere(
      (interaction) => !interaction.dirty,
    );
    state.select(interaction: clean.id);
    state.onlyDirty = true;
    state.reconcileSelection(overview);
    expect(state.interactionId, isNull);
    state.select(interaction: id);
    state.reconcileSelection(overview);
    expect(state.interactionId, id);
    state.onlyDirty = false;
    state.reconcileSelection(overview);
    expect(state.interactionId, id);
    expect(narrative.sessions[id], same(session));
    expect(session.dirty, isTrue);
    expect(
      await LocalMapWorkspaceAdapter().loadProject(fixture.session),
      before,
    );
  });
}
