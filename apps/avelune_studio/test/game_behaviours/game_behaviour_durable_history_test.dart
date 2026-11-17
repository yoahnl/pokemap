import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/field_traversal_zone_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:avelune_studio/features/story_workspace/application/story_history_scope.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../presentation/map_builder_story_support.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  test(
    'a durable physical rollback keeps the preceding rule behind its barrier',
    () async {
      final record = storyRecord(1);
      final port = _TraversalPort(
        workspaceProject.copyWith(
          scenes: [storyPlainScene('scene-plain')],
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [record],
            legacyClaims: const [],
          ),
        ),
      );
      port.saved['a'] = workspaceMap('a').copyWith(entities: [storyLuth]);
      final maps = MapWorkspaceController(workspaceSession, port);
      addTearDown(maps.dispose);
      await maps.initialize();
      final story = MapBuilderStoryBinding(
        maps: maps,
        changed: maps.notify,
        view: () => null,
      );
      maps.addListener(story.reconcile);
      await story.prepare();
      expect(story.renameBehaviour(record, 'Règle avant passage'), isTrue);
      final document = maps.active!;
      expect(
        await maps.configureFieldTraversal(
          document,
          document.current.copyWith(gameplayZones: [_zone]),
        ),
        isTrue,
      );
      final gate = Completer<void>();
      port.restoreGate = gate;
      story.undo();
      expect(document.saving, isTrue);
      expect(document.current.gameplayZones, isEmpty);
      gate.completeError(StateError('Refus durable du passage'));
      await Future<void>.delayed(Duration.zero);
      expect(document.saving, isFalse);
      expect(document.current.gameplayZones.single, _zone);
      final scope = StoryHistoryScope({
        (kind: StoryDraftKind.event, id: record.id),
      });
      expect(story.canStepScope(scope, redo: false), isFalse);
      port.restoreGate = null;
      story.undo();
      await Future<void>.delayed(Duration.zero);
      expect(document.current.gameplayZones, isEmpty);
      expect(story.canStepScope(scope, redo: false), isTrue);
      story.undo();
      story.redo();
      final redoGate = Completer<void>();
      port.restoreGate = redoGate;
      story.redo();
      expect(document.saving, isTrue);
      redoGate.completeError(StateError('Refus durable du rétablissement'));
      await Future<void>.delayed(Duration.zero);
      expect(document.current.gameplayZones, isEmpty);
      expect(story.canStepScope(scope, redo: true), isFalse);
      port.restoreGate = null;
      story.redo();
      await Future<void>.delayed(Duration.zero);
      expect(document.current.gameplayZones.single, _zone);
    },
  );
}

const _zone = MapGameplayZone(
  id: 'passage',
  kind: GameplayZoneKind.fieldAction,
  area: MapRect(pos: GridPos(x: 5, y: 5), size: GridSize(width: 3, height: 1)),
  fieldAction: FieldActionZonePayload(
    actionKind: FieldActionZoneKind.waterfall,
    waterfall: WaterfallZonePayload(
      entry: GridPos(x: 0, y: 0),
      path: [GridPos(x: 1, y: 0)],
      exit: GridPos(x: 2, y: 0),
      direction: MapConnectionDirection.east,
    ),
  ),
);

class _TraversalPort extends WorkspaceMemoryPort
    implements FieldTraversalZonePort {
  _TraversalPort(ProjectManifest manifest) : super(manifest: manifest);
  Completer<void>? restoreGate;

  FieldTraversalZoneReceipt _receipt(MapData map, String revision) =>
      FieldTraversalZoneReceipt(
        document: MapWorkspaceDocument(
          map: map,
          revision: revision,
          mapId: map.id,
        ),
        receiptId: revision,
        actionId: 'gameplay_zone.create',
        selectionZone: _zone,
        parameters: const {},
      );

  @override
  Future<FieldTraversalZoneReceipt> publishFieldTraversalZone(
    ProjectSession session,
    MapWorkspaceDocument base,
    String actionId,
    Map<String, Object?> parameters,
  ) async => _receipt(base.map.copyWith(gameplayZones: [_zone]), 'route-1');

  @override
  Future<FieldTraversalZoneReceipt> restoreFieldTraversalZone(
    ProjectSession session,
    MapWorkspaceDocument base,
    FieldTraversalZoneReceipt receipt, {
    required bool redo,
  }) async {
    await restoreGate?.future;
    return _receipt(
      base.map.copyWith(gameplayZones: [if (redo) _zone]),
      'route-2',
    );
  }
}
