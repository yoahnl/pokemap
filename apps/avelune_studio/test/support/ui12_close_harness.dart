import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/stories/data/local_story_adapter.dart';
import 'package:avelune_studio/features/stories/domain/story_port.dart';
import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/world/world_workspace_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'm2_ui_fixture.dart';
import 'ui05_narrative_fixture.dart';
import 'ui12_widget_world_port.dart';
import 'ui12_world_harness.dart';

Future<void> activate(WidgetTester tester, Finder finder) async {
  await tester.pump(const Duration(milliseconds: 350));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await pumpIo(tester, frames: 12);
}

Finder inDialog(String label) => find.descendant(
  of: find.byType(AlertDialog),
  matching: find.text(label),
);

String state(WorldWorkspaceController world, String label) {
  final id = world.createFact();
  world.editFact(
    NarrativeFactDefinition(
      id: id,
      label: label,
      initialValue: const NarrativeValue.boolean(false),
    ),
  );
  return id;
}

String composeRule(
  WorldWorkspaceController world,
  String factId, {
  bool complete = true,
}) {
  final map = world.maps.firstWhere((map) => map.entities.isNotEmpty);
  final entity = map.entities.first;
  final id = world.createRule(factId: factId);
  world.editRule(id, (draft) {
    draft.label = 'Masquer le conducteur';
    if (!complete) return;
    draft.target = WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEntity,
      mapId: map.id,
      entityId: entity.id,
      label: entity.id,
    );
    draft.effect = const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden);
  });
  return id;
}

Future<(Ui12WorldHarness, Future<bool> Function())> host(
  WidgetTester tester, {
  WorldPort Function(WorldPort)? wrap,
}) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final h = (await tester.runAsync(
    () => Ui12WorldHarness.create(
      initialize: false,
      wrap: (port) =>
          Ui12WidgetWorldPort((wrap ?? (value) => value)(port), tester),
    ),
  ))!;
  final visuals = (await tester.runAsync(
    () => StudioMapResources.load(h.session, h.maps.project!),
  ))!;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(h.dispose);
  });
  Future<bool> Function()? guard;
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: MapWorkspaceScreen(
        controller: h.maps,
        loadVisuals: (_, _) async => visuals,
        narrativePort: Ui05NarrativePort(
          LocalNarrativeAdapter(session: h.session, mapAdapter: h.adapter),
          tester,
        ),
        storyPort: _WidgetStoryPort(
          LocalStoryAdapter(session: h.session, mapAdapter: h.adapter),
          tester,
        ),
        worldPort: h.port,
        onClose: () async {},
        registerExitGuard: (value) {
          if (value != null) guard = value;
        },
        runtimeBuilder: (_, _, _) => const SizedBox(),
      ),
    ),
  );
  await pumpIo(tester);
  await activate(
    tester,
    find.descendant(
      of: find.byType(StudioPrimaryNavigation),
      matching: find.byTooltip('Histoire'),
    ),
  );
  await activate(tester, find.text('États et règles du monde').first);
  expect(find.byType(WorldWorkspacePage), findsOneWidget);
  expect(opened(tester).narrative.saveStoryDrafts, isNotNull);
  return (h, () => guard!());
}

WorldWorkspaceController opened(WidgetTester tester) =>
    tester.widget<WorldWorkspacePage>(find.byType(WorldWorkspacePage)).controller;

class _WidgetStoryPort implements StoryPort {
  _WidgetStoryPort(this.delegate, this.tester);
  final StoryPort delegate;
  final WidgetTester tester;

  Future<T> _run<T>(Future<T> Function() action) async {
    final operation = tester.runAsync(() async {
      try {
        return (await action(), null);
      } catch (error) {
        return (null, error);
      }
    });
    WidgetResourcePort.pending = operation;
    try {
      final result = (await operation)!;
      if (result.$2 case final error?) throw error;
      return result.$1 as T;
    } finally {
      if (identical(WidgetResourcePort.pending, operation)) {
        WidgetResourcePort.pending = null;
      }
    }
  }

  @override
  Future<ResourceMutationReceipt> publishFact({
    required NarrativeFactDefinition? base,
    required NarrativeFactDefinition current,
  }) => _run(() => delegate.publishFact(base: base, current: current));

  @override
  Future<ResourceMutationReceipt> publishStory({
    required String id,
    required StorylineAsset? base,
    required StorylineAsset? current,
    Set<String> requiredStoryIds = const {},
    Set<String> requiredFactIds = const {},
    Set<String> requiredSceneIds = const {},
  }) => _run(
    () => delegate.publishStory(
      id: id,
      base: base,
      current: current,
      requiredStoryIds: requiredStoryIds,
      requiredFactIds: requiredFactIds,
      requiredSceneIds: requiredSceneIds,
    ),
  );
}
