import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_overview_projection.dart';
import 'package:avelune_studio/features/narrative/application/narrative_overview_selection.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/ui05_story_backend_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('filter leaves a neutral detail until a visible story is selected', () async {
    final fixture = await createUi05StoryBackend();
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
    final overview = buildNarrativeOverview(narrative);
    final state = NarrativeOverviewSelection();
    final other = overview.stories.firstWhere(
      (story) => story.id != 'garden-traces',
    );
    state
      ..storyId = other.id
      ..select(step: other.chapters.first.steps.first.id);

    state.query = 'Les traces du jardin';
    state.reconcileSelection(overview);
    expect(state.storyId, isNull);
    expect(state.stepId, isNull);
    expect(state.detailVisible, isFalse);
    expect(
      state.visibleStories(overview).map((story) => story.id),
      ['garden-traces'],
    );

    state
      ..storyId = 'garden-traces'
      ..select(step: 'garden-listen');
    state.reconcileSelection(overview);
    expect(state.storyId, 'garden-traces');
    expect(state.stepId, 'garden-listen');
    expect(state.detailVisible, isTrue);
    final garden = state.visibleStories(overview).single;
    expect(garden.chapters.single.title, 'Une piste discrète');

    state.select(step: 'absent-step');
    state.reconcileSelection(overview);
    expect(state.storyId, 'garden-traces');
    expect(state.stepId, isNull);
    expect(state.detailVisible, isFalse);

    state.query = 'traverser la CLAIRIÈRE';
    expect(
      state.visibleStories(overview).map((story) => story.id),
      ['garden-traces'],
    );
    state.query = 'aucune histoire ne porte ce nom';
    expect(state.visibleStories(overview), isEmpty);
  }, timeout: _slow);
}

const _slow = Timeout(Duration(minutes: 3));
