import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'story_interactions_support.dart';
import 'story_memory_harness.dart';

void main() {
  testWidgets('resizing keeps the current filter and unfinished rule name', (
    tester,
  ) async {
    await openInteractions(tester);
    await openInteractionRule(tester);
    await filterInteractions(tester, 'b');
    await tester.tap(interactionKey('behaviour-$motherTalk'));
    await settleMemory(tester);
    final name = interactionKey('map-story-behaviour-name-$motherTalk');
    final field = find.descendant(of: name, matching: find.byType(TextField));
    await tester.enterText(field, 'Maman encore saisie');
    final state = tester.state(name);
    for (final size in [
      const Size(1280, 680),
      const Size(1100, 900),
      const Size(1920, 1080),
    ]) {
      tester.view.physicalSize = size;
      await settleMemory(tester);
      expect(interactionFilter(tester).value, 'b');
      expect(tester.state(name), same(state));
      expect(
        tester.widget<TextField>(field).controller!.text,
        'Maman encore saisie',
      );
      expect(interactionMaps(tester).active!.current.id, 'a');
    }
  });

  testWidgets('nested map visits restore each origin list and selection', (
    tester,
  ) async {
    await openInteractions(tester);
    final binding = interactionBinding(tester);
    binding.search('Guide');
    await openInteractionRule(tester);
    await filterInteractions(tester, 'b');
    await tester.tap(interactionKey('behaviour-$motherTalk'));
    await settleMemory(tester);
    final context = interactionKey('story-behaviour-context-$motherTalk');
    await tester.scrollUntilVisible(
      interactionKey('story-behaviour-view-map'),
      500,
      scrollable: find
          .descendant(of: context, matching: find.byType(Scrollable))
          .first,
    );
    await tester.tap(interactionKey('story-behaviour-view-map'));
    await settleMemory(tester);
    expect(interactionMaps(tester).active!.current.id, 'b');
    binding.search('Maman');
    await tester.tap(interactionKey('story-return'));
    await settleMemory(tester);
    expect(interactionFilter(tester).value, 'b');
    await tester.tap(interactionKey('story-return'));
    await settleMemory(tester);
    expect(interactionMaps(tester).active!.current.id, 'a');
    expect(binding.selected!.id, 'guide');
    expect(binding.query, 'Guide');
    expect(binding.tab, MapStoryTab.behaviour);
  });
  testWidgets(
    'a local rule transports its map filter and returns without losing typing or viewport',
    (tester) async {
      await openInteractions(tester);
      final binding = interactionBinding(tester);
      final maps = interactionMaps(tester);
      final document = maps.active!;
      binding.search('Guide');
      final view = binding.view()!;
      view.tool = StudioMapTool.pan;
      view.transform.value = Matrix4.identity()
        ..translateByDouble(70, 45, 0, 1)
        ..scaleByDouble(1.25, 1.25, 1, 1);
      final transform = view.transform.value.clone();
      await openInteractionRule(tester);
      expect(interactionFilter(tester).value, 'a');
      final name = interactionKey('map-story-behaviour-name-$guideTalk');
      await tester.enterText(
        find.descendant(of: name, matching: find.byType(TextField)),
        'Nom encore saisi',
      );
      await tester.tap(interactionKey('story-return'));
      await settleMemory(tester);
      expect(maps.active, same(document));
      expect(binding.selected!.id, 'guide');
      expect(binding.query, 'Guide');
      expect(view.transform.value, transform);
      expect(view.tool, StudioMapTool.pan);
      expect(binding.selectedBehaviour!.name, 'Nom encore saisi');
      expect(binding.behaviours.draft.recorded, 1);
    },
  );

  testWidgets(
    'editing B from Histoire keeps the map A document and source selected',
    (tester) async {
      await openInteractions(tester);
      await openInteractionRule(tester);
      final binding = interactionBinding(tester);
      final document = interactionMaps(tester).active;
      await filterInteractions(tester, 'b');
      await tester.tap(interactionKey('behaviour-$motherTalk'));
      await settleMemory(tester);
      await tester.enterText(
        find.descendant(
          of: interactionKey('map-story-behaviour-name-$motherTalk'),
          matching: find.byType(TextField),
        ),
        'Maman modifiée',
      );
      await tester.tap(interactionKey('story-return'));
      await settleMemory(tester);
      expect(interactionMaps(tester).active, same(document));
      expect(binding.selected!.id, 'guide');
      expect(
        binding.behaviours
            .registry(binding.project!)!
            .records
            .singleWhere((record) => record.id == motherTalk)
            .name,
        'Maman modifiée',
      );
    },
  );
}
