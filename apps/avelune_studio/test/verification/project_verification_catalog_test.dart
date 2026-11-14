import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_workshop.dart';
import 'package:avelune_studio/features/verification/application/project_verification_controller.dart';
import 'package:avelune_studio/features/verification/data/local_verification_adapter.dart';
import 'package:avelune_studio/features/verification/data/verification_analysis_worker.dart';
import 'package:avelune_studio/features/verification/data/verification_inputs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../game_memory/game_memory_catalog_fixture.dart';

Future<({Duration elapsed, Duration stall, int problems, String isolate})>
_verify(int unrelated) async {
  final session = await openGameMemoryCatalog(unrelated: unrelated);
  final adapter = LocalMapWorkspaceAdapter();
  final maps = MapWorkspaceController(session, adapter);
  addTearDown(maps.dispose);
  await maps.initialize();
  final port = LocalVerificationAdapter(session: session, mapAdapter: adapter);
  final verification = ProjectVerificationController(
    port: port,
    loadProject: () async {
      await maps.ensureWorkshop(MapWorkspaceWorkshop.verification);
      return maps.project;
    },
    changed: () {},
  );
  var stall = Duration.zero;
  final ticks = Stopwatch()..start();
  var last = Duration.zero;
  final timer = Timer.periodic(const Duration(milliseconds: 4), (_) {
    final now = ticks.elapsed;
    if (now - last > stall) stall = now - last;
    last = now;
  });
  await verification.start();
  timer.cancel();
  expect(
    verification.phase,
    ProjectVerificationPhase.done,
    reason: '${verification.failure}',
  );
  final analysis = await port
      .analyse(
        project: maps.project!,
        maps: await port.readMaps(),
        sources: const [],
      )
      .result;
  return (
    elapsed: verification.elapsed!,
    stall: stall,
    problems: verification.problems.length,
    isolate: analysis.isolateName,
  );
}

void main() {
  test(
    'verification runs off the interface isolate and scales with the project',
    () async {
      final small = await _verify(20);
      final large = await _verify(200);

      debugPrint(
        'VERIFICATION_TIMING small(20)=${small.elapsed.inMilliseconds}ms '
        'stall=${small.stall.inMilliseconds}ms problems=${small.problems} '
        'large(200)=${large.elapsed.inMilliseconds}ms '
        'stall=${large.stall.inMilliseconds}ms problems=${large.problems}',
      );
      expect(small.isolate, verificationWorkerName);
      expect(large.isolate, verificationWorkerName);
      expect(large.problems, greaterThanOrEqualTo(small.problems));
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'maps read for the verification equal the ones the Carte opens',
    () async {
      final session = await openGameMemoryCatalog(unrelated: 3);
      final adapter = LocalMapWorkspaceAdapter();
      final maps = MapWorkspaceController(session, adapter);
      addTearDown(maps.dispose);
      await maps.initialize();
      final port = LocalVerificationAdapter(
        session: session,
        mapAdapter: adapter,
      );
      final sources = await port.readMaps();

      expect(sources, hasLength(4));
      for (final source in sources) {
        expect(
          verificationMap(maps.project!, source),
          (await adapter.loadMap(session, source.entry)).map,
        );
      }
    },
  );

  test(
    'a cancelled verification kills its worker and returns nothing',
    () async {
      final session = await openGameMemoryCatalog(unrelated: 20);
      final adapter = LocalMapWorkspaceAdapter();
      final maps = MapWorkspaceController(session, adapter);
      addTearDown(maps.dispose);
      await maps.initialize();
      await maps.ensureWorkshop(MapWorkspaceWorkshop.verification);
      final port = LocalVerificationAdapter(
        session: session,
        mapAdapter: adapter,
      );
      final job = port.analyse(
        project: maps.project!,
        maps: await port.readMaps(),
        sources: const [],
      );

      job.cancel();

      await expectLater(job.result, throwsA(anything));
    },
  );
}
