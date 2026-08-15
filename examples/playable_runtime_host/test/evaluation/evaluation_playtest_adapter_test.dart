import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_state_snapshot.dart';
import 'package:pokemap_loader/src/evaluation/driver/evaluation_driver.dart';
import 'package:pokemap_loader/src/evaluation/driver/evaluation_playtest_adapter.dart';
import 'package:pokemap_loader/src/evaluation/driver/selbrume_evaluation_driver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('adapter isolates files, dispatches real driver commands, and cleans up',
      () async {
    final projectRoot =
        await Directory.systemTemp.createTemp('pmcp070_project_');
    addTearDown(() async {
      if (await projectRoot.exists()) await projectRoot.delete(recursive: true);
    });
    final projectFile = File('${projectRoot.path}/project.json');
    await projectFile.writeAsString('{"id":"selbrume"}');
    final beforeBytes = await projectFile.readAsBytes();
    final revision = await computeEvaluationProjectRevision(projectRoot);
    final sandboxes = <Directory>[];
    final driver = _FakeEvaluationDriver();

    final port = RuntimePlaytestPort(
      pokemonCatalogPreflight: _readyPokemonCatalog,
      driverFactory: (request) => EvaluationPlaytestDriver.start(
        request: request,
        projectRoot: projectRoot,
        driverFactory: ({required runId, required seed}) async {
          expect(runId, request.sessionId);
          expect(seed, 42);
          return driver;
        },
        captureSurface: () async => <int>[137, 80, 78, 71],
        onSandboxCreated: sandboxes.add,
      ),
    );
    final session = await port.start(
      PlaytestStartRequest(
        sessionId: 'session-070',
        projectId: 'selbrume',
        projectRevision: revision,
        scenarioId: 'golden.slice',
        seed: 42,
      ),
    );

    await session.execute(
      PlaytestCommand(
        commandId: 'money',
        operation: 'probe.setMoney',
        arguments: const <String, Object?>{'value': 750},
      ),
    );
    await session.captureScreenshot('after-money');
    final receipt = await session.stop();

    expect(driver.money, 750);
    expect(driver.disposeCount, 1);
    expect(receipt.projectRevision, revision);
    expect(receipt.seed, 42);
    expect(receipt.scenarioId, 'golden.slice');
    expect(receipt.artifacts.single.mediaType, 'image/png');
    expect(await projectFile.readAsBytes(), beforeBytes);
    expect(sandboxes, hasLength(1));
    expect(await sandboxes.single.exists(), isFalse);
  });

  test('canonical port drives the real Selbrume evaluation runtime', () async {
    final projectRoot =
        Directory(p.join(_findRepositoryRoot().path, 'selbrume'));
    final revision = await computeEvaluationProjectRevision(projectRoot);
    final beforeRevision = await computeEvaluationProjectRevision(projectRoot);
    final port = RuntimePlaytestPort(
      pokemonCatalogPreflight: _readyPokemonCatalog,
      driverFactory: (request) => EvaluationPlaytestDriver.start(
        request: request,
        projectRoot: projectRoot,
        driverFactory: ({required runId, required seed}) {
          expect(seed, 0);
          return SelbrumeEvaluationDriver.start(
            projectRoot: projectRoot,
            runId: runId,
          );
        },
      ),
    );
    final session = await port.start(
      PlaytestStartRequest(
        sessionId: 'session-070-selbrume',
        projectId: 'selbrume',
        projectRevision: revision,
        scenarioId: 'smoke.start',
        seed: 0,
      ),
    );

    final execution = await session.execute(
      PlaytestCommand(
        commandId: 'money',
        operation: 'probe.setMoney',
        arguments: const <String, Object?>{'value': 1123},
      ),
    );
    final receipt = await session.stop();

    expect(
      (execution.snapshot.state['trainer'] as Map)['money'],
      1123,
    );
    expect(receipt.terminalState, PlaytestSessionState.stopped);
    expect(await computeEvaluationProjectRevision(projectRoot), beforeRevision);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('bounded player-state service drives Bag commands without durable writes',
      () async {
    final projectRoot =
        await Directory.systemTemp.createTemp('itm055_runtime_project_');
    addTearDown(() async {
      if (await projectRoot.exists()) await projectRoot.delete(recursive: true);
    });
    final projectFile = File('${projectRoot.path}/project.json');
    await projectFile.writeAsString('{"id":"item-boundary"}');
    final beforeBytes = await projectFile.readAsBytes();
    final revision = await computeEvaluationProjectRevision(projectRoot);
    final driver = _FakeEvaluationDriver();
    final handles = WorkspaceHandleStore();
    final project = handles.registerProject(
      projectName: 'item-boundary',
      initialFingerprint: revision,
      readBytes: (relativePath) =>
          File(p.join(projectRoot.path, relativePath)).readAsBytes(),
    );
    final service = PlaytestPlayerStateService(
      handles: handles,
      playtest: RuntimePlaytestPort(
        pokemonCatalogPreflight: _readyPokemonCatalog,
        driverFactory: (request) => EvaluationPlaytestDriver.start(
          request: request,
          projectRoot: projectRoot,
          driverFactory: ({required runId, required seed}) async => driver,
        ),
      ),
      actor: AuthoringActor(
        actorId: 'runtime-test',
        permissions: const [
          AuthoringPermissionScope.playtestRun,
          AuthoringPermissionScope.playtestControl,
        ],
      ),
    );
    await service.start(
      workspaceHandle: project.workspaceHandle,
      projectHandle: project.projectHandle,
      request: PlaytestStartRequest(
        sessionId: 'item-session-runtime',
        projectId: 'item-boundary',
        projectRevision: revision,
        scenarioId: 'item-boundary',
        seed: 42,
      ),
    );

    final given = await service.executeBagCommand(
      workspaceHandle: project.workspaceHandle,
      projectHandle: project.projectHandle,
      sessionId: 'item-session-runtime',
      command: PlaytestPlayerStateCommand.giveItem(
        commandId: 'give-potion',
        itemId: 'potion',
        quantity: 3,
      ),
    );
    final consumed = await service.executeBagCommand(
      workspaceHandle: project.workspaceHandle,
      projectHandle: project.projectHandle,
      sessionId: 'item-session-runtime',
      command: PlaytestPlayerStateCommand.consumeItem(
        commandId: 'consume-potion',
        itemId: 'potion',
        quantity: 1,
      ),
    );
    await service.stop(
      workspaceHandle: project.workspaceHandle,
      projectHandle: project.projectHandle,
      sessionId: 'item-session-runtime',
    );

    expect((given.snapshot.state['bag'] as Map)['potion'], 3);
    expect((consumed.snapshot.state['bag'] as Map)['potion'], 2);
    expect(driver.disposeCount, 1);
    expect(await projectFile.readAsBytes(), beforeBytes);
  });
}

final class _FakeEvaluationDriver
    implements EvaluationDriver, EvaluationBagMutationAutomation {
  var money = 1000;
  var disposeCount = 0;
  final Map<String, int> bag = <String, int>{};

  @override
  EvaluationStateSnapshot snapshot() => EvaluationStateSnapshot(
        projectId: 'selbrume',
        runId: 'session-070',
        mapId: 'map_bourg_selbrume',
        x: 4,
        y: 7,
        movementMode: 'walk',
        money: money,
        bag: bag,
      );

  @override
  Future<void> giveBagItem(String itemId, int quantity) async {
    bag.update(
      itemId,
      (current) => current + quantity,
      ifAbsent: () => quantity,
    );
  }

  @override
  Future<void> consumeBagItem(String itemId, int quantity) async {
    final current = bag[itemId] ?? 0;
    if (current < quantity) throw StateError('insufficient quantity');
    if (current == quantity) {
      bag.remove(itemId);
    } else {
      bag[itemId] = current - quantity;
    }
  }

  @override
  Future<void> probeSetMoney(int value) async {
    money = value;
  }

  @override
  Future<void> dispose() async {
    disposeCount += 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<PokemonCatalogCoherenceReport> _readyPokemonCatalog(
  PlaytestStartRequest _,
) async => PokemonCatalogCoherenceReport(const []);

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      throw StateError('pokemonProject repository root not found.');
    }
    current = current.parent;
  }
}
