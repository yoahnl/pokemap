import 'dart:async';

import 'package:avelune_studio/features/narrative/application/narrative_navigation_requests.dart';
import 'package:avelune_studio/features/narrative/application/narrative_overview.dart';
import 'package:avelune_studio/features/narrative/application/narrative_overview_selection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  test('a failed navigation is reported when it is the latest request', () async {
    final requests = NarrativeNavigationRequests();
    expect(await requests.run((_) async => 'Refusé', 'a'), 'Refusé');
    expect(await requests.run((_) async => null, 'a'), isNull);
  });

  test('the error of an older request is dropped once a newer one started', () async {
    final requests = NarrativeNavigationRequests();
    final slow = Completer<String?>();
    final first = requests.run((_) => slow.future, 'a');
    final second = requests.run((_) async => 'Deuxième', 'b');
    slow.complete('Première');
    expect(await first, isNull);
    expect(await second, 'Deuxième');
  });

  test('a newer request without error still hides the older error', () async {
    final requests = NarrativeNavigationRequests();
    final slow = Completer<String?>();
    final first = requests.run((_) => slow.future, 'a');
    final second = requests.run((_) async => null, 'b');
    slow.complete('Première');
    expect(await first, isNull);
    expect(await second, isNull);
  });

  test('the error is dropped when the selection moved away from the requested id', () async {
    final requests = NarrativeNavigationRequests();
    var selected = 'a';
    final pending = Completer<String?>();
    final result = requests.run(
      (_) => pending.future,
      'a',
      relevant: () => selected == 'a',
    );
    selected = 'b';
    pending.complete('Refusé');
    expect(await result, isNull);
    selected = 'a';
    expect(
      await requests.run((_) async => 'Refusé', 'a', relevant: () => selected == 'a'),
      'Refusé',
    );
  });

  test('the initial view opens the first story and only once', () {
    final stories = [
      StorylineAsset(id: 'one', type: StorylineType.main, title: 'Un'),
      StorylineAsset(id: 'two', type: StorylineType.main, title: 'Deux'),
    ];
    final state = NarrativeOverviewSelection();
    state.initialize(_overview(stories));
    expect(state.initialized, isTrue);
    expect(state.storyId, 'one');
    expect(state.tab, NarrativeOverviewTab.stories);
    state.storyId = 'two';
    state.initialize(_overview(stories));
    expect(state.storyId, 'two');
  });

  test('a project without story starts on the interactions tab', () {
    final state = NarrativeOverviewSelection()..initialize(_overview(const []));
    expect(state.storyId, isNull);
    expect(state.tab, NarrativeOverviewTab.interactions);
  });
}

NarrativeOverview _overview(List<StorylineAsset> stories) => NarrativeOverview(
  stories: stories,
  facts: const [],
  interactions: const [],
  stepsById: const {},
  stepLinks: const {},
  factLinks: const {},
  dirtyCount: 0,
);
