import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/narrative/application/cutscene_studio_authoring.dart';

void main() {
  group('cutsceneStudioResolveMapContextPredecessors', () {
    test('linear flow: predecessors exclude target block', () {
      const a = CutsceneStudioBlock(
        id: 'a',
        kind: CutsceneStudioBlockKind.moveCharacter,
        actorId: kCutsceneStudioActorPlayerId,
        destinationTargetKind: kCutsceneStudioMoveTargetWarp,
        destinationTargetId: 'w1',
      );
      const b = CutsceneStudioBlock(
        id: 'b',
        kind: CutsceneStudioBlockKind.dialogue,
        actorId: 'npc1',
      );
      final flow = <CutsceneFlowEntry>[
        const CutsceneFlowBlockEntry(a),
        const CutsceneFlowBlockEntry(b),
      ];
      final r = cutsceneStudioResolveMapContextPredecessors(flow, 'b');
      expect(r, isA<CutsceneStudioMapContextLinear>());
      expect(
        (r as CutsceneStudioMapContextLinear).predecessorBlocks,
        orderedEquals(<CutsceneStudioBlock>[a]),
      );
    });

    test('choice with branches then tail block is ambiguous', () {
      const q = CutsceneStudioBlock(
        id: 'q',
        kind: CutsceneStudioBlockKind.playerQuestion,
        messageText: '?',
        choiceOptions: ['Oui', 'Non'],
      );
      const inner = CutsceneStudioBlock(
        id: 'inner',
        kind: CutsceneStudioBlockKind.wait,
        durationMs: 1,
      );
      const after = CutsceneStudioBlock(
        id: 'after',
        kind: CutsceneStudioBlockKind.wait,
        durationMs: 2,
      );
      final flow = <CutsceneFlowEntry>[
        const CutsceneFlowChoiceEntry(
          question: q,
          onYes: [CutsceneFlowBlockEntry(inner)],
          onNo: [],
        ),
        const CutsceneFlowBlockEntry(after),
      ];
      final r = cutsceneStudioResolveMapContextPredecessors(flow, 'after');
      expect(r, isA<CutsceneStudioMapContextAmbiguous>());
    });
  });

  group('cutsceneStudioSimulatedPlayerMapId', () {
    test('player warp updates map from resolver', () {
      const move = CutsceneStudioBlock(
        id: 'm',
        kind: CutsceneStudioBlockKind.moveCharacter,
        actorId: kCutsceneStudioActorPlayerId,
        destinationTargetKind: kCutsceneStudioMoveTargetWarp,
        destinationTargetId: 'w',
      );
      final map = cutsceneStudioSimulatedPlayerMapId(
        startMapId: 'upper',
        predecessorBlocks: [move],
        warpTargetMapId: (mid, wid) {
          if (mid == 'upper' && wid == 'w') return 'lower';
          return null;
        },
      );
      expect(map, 'lower');
    });

    test('transitionMap block sets player map', () {
      const t = CutsceneStudioBlock(
        id: 't',
        kind: CutsceneStudioBlockKind.transitionMap,
        transitionMapId: 'indoor',
        transitionWarpId: 'door',
      );
      final map = cutsceneStudioSimulatedPlayerMapId(
        startMapId: 'outdoor',
        predecessorBlocks: [t],
        warpTargetMapId: (_, __) => null,
      );
      expect(map, 'indoor');
    });

    test('NPC warp does not change simulated player map', () {
      const move = CutsceneStudioBlock(
        id: 'm',
        kind: CutsceneStudioBlockKind.moveCharacter,
        actorId: 'npc_x',
        destinationTargetKind: kCutsceneStudioMoveTargetWarp,
        destinationTargetId: 'w',
      );
      final map = cutsceneStudioSimulatedPlayerMapId(
        startMapId: 'a',
        predecessorBlocks: [move],
        warpTargetMapId: (_, __) => 'should_not_use',
      );
      expect(map, 'a');
    });
  });

  group('cutsceneStudioCollectMapIdsAlongPlayerSimulation', () {
    test('collects intermediate maps along warp chain', () {
      const m1 = CutsceneStudioBlock(
        id: 'm1',
        kind: CutsceneStudioBlockKind.moveCharacter,
        actorId: kCutsceneStudioActorPlayerId,
        destinationTargetKind: kCutsceneStudioMoveTargetWarp,
        destinationTargetId: 'w1',
      );
      const m2 = CutsceneStudioBlock(
        id: 'm2',
        kind: CutsceneStudioBlockKind.moveCharacter,
        actorId: kCutsceneStudioActorPlayerId,
        destinationTargetKind: kCutsceneStudioMoveTargetWarp,
        destinationTargetId: 'w2',
      );
      final ids = cutsceneStudioCollectMapIdsAlongPlayerSimulation(
        startMapId: 'a',
        predecessorBlocks: [m1, m2],
        warpTargetMapId: (mid, wid) {
          if (mid == 'a' && wid == 'w1') return 'b';
          if (mid == 'b' && wid == 'w2') return 'c';
          return null;
        },
      );
      expect(ids, {'a', 'b', 'c'});
    });
  });
}
