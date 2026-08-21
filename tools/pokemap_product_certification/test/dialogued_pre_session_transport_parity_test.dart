import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

/// BETA-CIN-083 — the same project on the four transports.
///
/// Parity on its own proves very little: four scripts that all apply the same
/// wrong payload agree perfectly. So the sequence is declared once in
/// `DialoguedPreSessionFixture`, replayed here by each transport, and the
/// resulting projects are compared semantically — and then what landed is
/// asserted, so agreement on nonsense would still fail.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory workRoot;
  final mcpPackageRoot = Directory(
    p.normalize(p.join(Directory.current.path, '..', 'pokemap_mcp')),
  );

  setUp(() async {
    workRoot = await Directory.systemTemp.createTemp('cin083-parity-');
  });
  tearDown(() async {
    if (await workRoot.exists()) await workRoot.delete(recursive: true);
  });

  test('every transport produces the same project', () async {
    final runs = <DialoguedPreSessionTransport, DialoguedPreSessionTransportRun>{
      for (final transport in DialoguedPreSessionTransport.values)
        transport: await const DialoguedPreSessionTransportParity().run(
          transport,
          workRoot: workRoot,
          mcpPackageRoot: mcpPackageRoot,
        ),
    };

    expect(
      runs.keys,
      unorderedEquals(DialoguedPreSessionTransport.values),
      reason: 'no transport may be quietly skipped',
    );

    final expectedActionIds = const DialoguedPreSessionFixture()
        .steps
        .map((step) => step.actionId)
        .toList(growable: false);
    for (final run in runs.values) {
      expect(
        run.appliedActionIds,
        expectedActionIds,
        reason: '${run.transport.wireName} applied a different sequence',
      );
    }

    // The comparison is on the decoded projects, so key order or whitespace
    // cannot fail it for the wrong reason — and cannot hide a real difference
    // either, since a manifest compares by value.
    final reference = runs[DialoguedPreSessionTransport.directApi]!.project;
    for (final run in runs.values) {
      if (run.transport == DialoguedPreSessionTransport.directApi) continue;
      expect(
        run.project.scenes,
        reference.scenes,
        reason: '${run.transport.wireName} authored different Scenes',
      );
      expect(
        run.project.presentationCinematics,
        reference.presentationCinematics,
        reason: '${run.transport.wireName} authored a different Presentation',
      );
      expect(
        run.project.newGame,
        reference.newGame,
        reason: '${run.transport.wireName} left a different New Game entry',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 6)));

  test('the MCP runner must be built rather than skipped', () {
    expect(
      DialoguedPreSessionTransportParity.mcpRunnerIsBuilt(mcpPackageRoot),
      isTrue,
      reason: 'run `npm run build` in tools/pokemap_mcp — an unbuilt runner '
          'would otherwise turn the MCP leg of the parity matrix into a '
          'silent pass',
    );
  });

  test('what landed is the journey, not merely something identical', () async {
    final run = await const DialoguedPreSessionTransportParity().run(
      DialoguedPreSessionTransport.editor,
      workRoot: workRoot,
    );
    final scene = run.project.scenes.singleWhere(
      (candidate) => candidate.id == DialoguedPreSessionFixture.sceneId,
    );
    final opening = scene.graph.nodes.singleWhere(
      (node) => node.id == DialoguedPreSessionFixture.openingNodeId,
    );
    final payload = opening.payload! as ScenePresentationCinematicPayload;
    expect(
      payload.interactionCueBindings.map((binding) => binding.markerId),
      containsAll(<String>[
        DialoguedPreSessionFixture.pagesMarkerId,
        DialoguedPreSessionFixture.avatarMarkerId,
        DialoguedPreSessionFixture.nameMarkerId,
        DialoguedPreSessionFixture.confirmMarkerId,
        DialoguedPreSessionFixture.closingMarkerId,
      ]),
      reason: 'the Editor transport bound every cue of the reference journey',
    );
    expect(
      <String>{
        for (final binding in payload.interactionCueBindings)
          for (final route in binding.outcomeRoutes)
            route.outcome.kind.wireName,
      },
      DialoguedPreSessionFixture.coveredOutcomeWireNames,
    );
  }, timeout: const Timeout(Duration(minutes: 3)));
}
