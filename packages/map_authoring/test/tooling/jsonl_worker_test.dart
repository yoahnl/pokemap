import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('JsonlWorker', () {
    test('routes game_export through the configured export API', () async {
      final exportApi = _RecordingGamePackageExportApi();
      final worker = JsonlWorker(
        api: const _DelayedReadApi(),
        gameExport: exportApi,
      );

      final result = await _request(
        worker,
        id: 'export-1',
        command: 'game_export',
        args: const <String, Object?>{
          'projectRoot': '/allowed/project',
          'outputPath': '/allowed/output/game.avelunegame',
        },
      );

      expect(result.status, AuthoringResultStatus.success);
      expect(exportApi.projectRoot, '/allowed/project');
      expect(exportApi.outputPath, '/allowed/output/game.avelunegame');
      expect(result.data['sha256'], 'a' * 64);
    });

    test('uses the dedicated bounded timeout for game_export', () async {
      final worker = JsonlWorker(
        api: const _DelayedReadApi(),
        gameExport: _RecordingGamePackageExportApi(
          delay: const Duration(milliseconds: 20),
        ),
        commandTimeout: const Duration(milliseconds: 1),
        gameExportTimeout: const Duration(milliseconds: 50),
      );

      final result = await _request(
        worker,
        id: 'export-timeout-1',
        command: 'game_export',
        args: const <String, Object?>{
          'projectRoot': '/allowed/project',
          'outputPath': '/allowed/output/game.avelunegame',
        },
      );

      expect(result.status, AuthoringResultStatus.success);
    });

    test('golden describe and malformed input are byte-for-byte stable',
        () async {
      final setup = await _TestSetup.create();
      final describe = await setup.worker.processLine(
        jsonEncode({
          'id': 'describe-1',
          'command': 'describe',
          'args': <String, Object?>{},
        }),
      );
      final malformed = await setup.worker.processLine('{');
      final transcript = '$describe\n$malformed\n';
      final golden = await File(
        'test/tooling/goldens/describe_and_error.jsonl',
      ).readAsString();

      expect(transcript, golden);
      for (final line in [describe, malformed]) {
        expect(line, isNot(contains('\n')));
        expect(jsonDecode(line), isA<Map<String, dynamic>>());
      }
    });

    test('describe advertises only the five read commands', () async {
      final setup = await _TestSetup.create();

      final result = await _request(
        setup.worker,
        id: 'describe-commands',
        command: 'describe',
      );

      expect(result.status, AuthoringResultStatus.success);
      final commands = (result.data['commands']! as List)
          .cast<Map<String, Object?>>()
          .map((command) => command['id']);
      expect(commands, ['close', 'describe', 'open', 'query', 'validate']);
      final resourceKinds = (result.data['resourceKinds']! as List)
          .cast<Map<String, Object?>>()
          .map((descriptor) => descriptor['id'])
          .toSet();
      expect(resourceKinds, canonicalQueryableResourceKindIds);
      expect(
        jsonEncode(result.data).toLowerCase(),
        isNot(contains('"write"')),
      );
    });

    test('typed read facade owns contracts before wire serialization',
        () async {
      final setup = await _TestSetup.create(clean: true);
      addTearDown(setup.dispose);
      final typedApi = setup.api as dynamic;

      final description = typedApi.describeRead();
      final opened = await typedApi.openProject(setup.fixture.path);
      final queried = await typedApi.queryProject(
        opened.projectHandle,
        AuthoringQueryRequest(
          resourceKind: 'project',
          operation: AuthoringQueryOperation.get,
          view: AuthoringQueryView.summary,
          ids: const ['project'],
        ),
      );
      final validated = await typedApi.validateProject(opened.projectHandle);

      expect(description.runtimeType.toString(), 'AuthoringReadDescription');
      expect(opened, isA<OpenedProject>());
      expect(queried, isA<AuthoringQueryPage>());
      expect(validated.runtimeType.toString(), 'AuthoringValidationResult');
      expect(description.toJson(), setup.api.describe());
      expect(await typedApi.closeWorkspace(opened.workspaceHandle), isTrue);
    });

    test('every described resource kind has an executable query route',
        () async {
      final setup = await _TestSetup.create(clean: true);
      addTearDown(setup.dispose);
      final opened = await _request(
        setup.worker,
        id: 'open-query-catalog',
        command: 'open',
        args: {'projectRoot': setup.fixture.path},
      );
      final projectHandle = opened.data['projectHandle']! as String;

      for (final resourceKind in canonicalQueryableResourceKindIds) {
        final result = await _request(
          setup.worker,
          id: 'query-$resourceKind',
          command: 'query',
          args: {
            'projectHandle': projectHandle,
            'request': AuthoringQueryRequest(
              resourceKind: resourceKind,
              operation: AuthoringQueryOperation.list,
              view: AuthoringQueryView.summary,
            ).toJson(),
          },
        );

        expect(
          result.status,
          AuthoringResultStatus.success,
          reason: resourceKind,
        );
      }
    });

    test('opens, queries, validates, and closes the real project', () async {
      final setup = await _TestSetup.create();
      final opened = await _request(
        setup.worker,
        id: 'open-1',
        command: 'open',
        args: {'projectRoot': setup.fixture.path},
      );
      final projectHandle = opened.data['projectHandle']! as String;
      final workspaceHandle = opened.data['workspaceHandle']! as String;
      final request = AuthoringQueryRequest(
        resourceKind: 'project',
        operation: AuthoringQueryOperation.get,
        view: AuthoringQueryView.summary,
        ids: const ['project'],
      );

      final queried = await _request(
        setup.worker,
        id: 'query-1',
        command: 'query',
        args: {
          'projectHandle': projectHandle,
          'request': request.toJson(),
        },
      );
      final validated = await _request(
        setup.worker,
        id: 'validate-1',
        command: 'validate',
        args: {'projectHandle': projectHandle},
      );
      final directlyValidated = await setup.api.validate(
        ProjectHandle(projectHandle),
      );
      final closed = await _request(
        setup.worker,
        id: 'close-1',
        command: 'close',
        args: {'workspaceHandle': workspaceHandle},
      );

      expect(opened.status, AuthoringResultStatus.success);
      expect(opened.data['readOnly'], isTrue);
      expect(queried.status, AuthoringResultStatus.success);
      expect(
        (queried.data['items']! as List).single,
        containsPair('name', 'P3 Narrative Smoke Slice'),
      );
      expect(validated.status, AuthoringResultStatus.success);
      expect(validated.data['snapshotRevision'], startsWith('sha256:'));
      expect(
        validated.data['valid'],
        isFalse,
        reason: validated.data.toString(),
      );
      expect(validated.data['structure'], {
        'valid': true,
        'diagnostics': <Object?>[],
      });
      expect(
        validated.data['references'],
        containsPair('valid', false),
      );
      expect(
        validated.data['references'],
        containsPair('hasErrors', true),
      );
      expect(validated.data['capabilityCertification'], {
        'requested': false,
        'status': 'not_requested',
        'valid': null,
        'requiredCapabilityCount': 0,
        'providedCapabilityCount': 0,
      });
      expect(validated.data['capabilityTruth'], isA<Map<String, Object?>>());
      expect(directlyValidated, validated.data,
          reason:
              'direct and JSONL validation projections must stay identical');
      expect(closed.data, {'closed': true});

      final afterClose = await _request(
        setup.worker,
        id: 'query-after-close',
        command: 'query',
        args: {
          'projectHandle': projectHandle,
          'request': request.toJson(),
        },
      );
      expect(afterClose.status, AuthoringResultStatus.failure);
      expect(afterClose.error?.code, AuthoringErrorCode.notFound);
      expect(
          jsonEncode(afterClose.toJson()), isNot(contains(setup.fixture.path)));
    });

    test('does not fail a clean project for unrequested capabilities',
        () async {
      final setup = await _TestSetup.create(clean: true);
      addTearDown(setup.dispose);
      final opened = await _request(
        setup.worker,
        id: 'open-clean-validation',
        command: 'open',
        args: {'projectRoot': setup.fixture.path},
      );
      final projectHandle = opened.data['projectHandle']! as String;

      final validated = await _request(
        setup.worker,
        id: 'validate-clean',
        command: 'validate',
        args: {'projectHandle': projectHandle},
      );

      expect(validated.data['valid'], isTrue);
      expect(validated.data['structure'], {
        'valid': true,
        'diagnostics': <Object?>[],
      });
      expect(validated.data['references'], containsPair('valid', true));
      expect(validated.data['capabilityCertification'], {
        'requested': false,
        'status': 'not_requested',
        'valid': null,
        'requiredCapabilityCount': 0,
        'providedCapabilityCount': 0,
      });
      expect(
        await setup.api.validate(ProjectHandle(projectHandle)),
        validated.data,
      );
    });

    test('project validation rejects out-of-bounds RailJourney geometry',
        () async {
      final setup = await _TestSetup.create(clean: true);
      addTearDown(setup.dispose);
      await _writeOutOfBoundsRailJourneyFixture(setup.fixture);
      final opened = await _request(
        setup.worker,
        id: 'open-rail-journey-bounds',
        command: 'open',
        args: {'projectRoot': setup.fixture.path},
      );
      final projectHandle = opened.data['projectHandle']! as String;

      final validated = await _request(
        setup.worker,
        id: 'validate-rail-journey-bounds',
        command: 'validate',
        args: {'projectHandle': projectHandle},
      );
      final directlyValidated = await setup.api.validate(
        ProjectHandle(projectHandle),
      );
      final structure = validated.data['structure']! as Map<String, Object?>;
      final diagnostics =
          (structure['diagnostics']! as List).cast<Map<String, Object?>>();

      expect(validated.status, AuthoringResultStatus.success);
      expect(structure['valid'], isFalse);
      expect(
        diagnostics,
        contains(
          containsPair(
            'code',
            'rail_journey.boarding_area_out_of_bounds',
          ),
        ),
      );
      expect(directlyValidated, validated.data);
    });

    test('project validation exposes unknown RailJourney items over JSONL',
        () async {
      final setup = await _TestSetup.create(clean: true);
      addTearDown(setup.dispose);
      await _writeUnknownRailJourneyItemFixture(setup.fixture);
      final opened = await _request(
        setup.worker,
        id: 'open-rail-journey-item',
        command: 'open',
        args: {'projectRoot': setup.fixture.path},
      );
      final projectHandle = opened.data['projectHandle']! as String;

      final validated = await _request(
        setup.worker,
        id: 'validate-rail-journey-item',
        command: 'validate',
        args: {'projectHandle': projectHandle},
      );
      final directlyValidated = await setup.api.validate(
        ProjectHandle(projectHandle),
      );
      final structure = validated.data['structure']! as Map<String, Object?>;
      final diagnostics =
          (structure['diagnostics']! as List).cast<Map<String, Object?>>();

      expect(validated.status, AuthoringResultStatus.success);
      expect(structure['valid'], isFalse);
      expect(
        diagnostics,
        contains(containsPair('code', 'rail_journey.item_unknown')),
      );
      expect(directlyValidated, validated.data);
    });

    test('malformed and unknown requests do not terminate the worker',
        () async {
      final setup = await _TestSetup.create();

      final malformed = _decode(await setup.worker.processLine('not-json'));
      final unknown = await _request(
        setup.worker,
        id: 'unknown-1',
        command: 'delete',
      );
      final strict = _decode(
        await setup.worker.processLine(
          jsonEncode({
            'id': 'strict-1',
            'command': 'describe',
            'args': <String, Object?>{},
            'unexpected': true,
          }),
        ),
      );
      final recovered = await _request(
        setup.worker,
        id: 'describe-after-errors',
        command: 'describe',
      );

      expect(malformed.status, AuthoringResultStatus.failure);
      expect(malformed.requestId, 'invalid');
      expect(malformed.error?.code, AuthoringErrorCode.invalidRequest);
      expect(unknown.status, AuthoringResultStatus.failure);
      expect(unknown.error?.code, AuthoringErrorCode.unsupported);
      expect(strict.status, AuthoringResultStatus.failure);
      expect(strict.error?.code, AuthoringErrorCode.invalidRequest);
      expect(recovered.status, AuthoringResultStatus.success);
    });

    test('rejects a line above the UTF-8 byte limit', () async {
      final setup = await _TestSetup.create(maxInputBytes: 32);
      final result = _decode(
        await setup.worker.processLine(
          jsonEncode({
            'id': 'large',
            'command': 'describe',
            'args': {'padding': 'é' * 64},
          }),
        ),
      );

      expect(result.status, AuthoringResultStatus.failure);
      expect(result.requestId, 'invalid');
      expect(result.error?.code, AuthoringErrorCode.invalidRequest);
      expect(result.error?.details['domainCode'], 'worker.input_too_large');
    });

    test('times out one command without exposing its exception', () async {
      final worker = JsonlWorker(
        api: const _DelayedReadApi(),
        commandTimeout: const Duration(milliseconds: 1),
      );

      final result = await _request(
        worker,
        id: 'timeout-1',
        command: 'open',
        args: const {'projectRoot': 'ignored'},
      );

      expect(result.status, AuthoringResultStatus.failure);
      expect(result.error?.code, AuthoringErrorCode.internal);
      expect(result.error?.retryable, isTrue);
      expect(result.error?.details['domainCode'], 'worker.timeout');
      expect(jsonEncode(result.toJson()), isNot(contains('TimeoutException')));
    });

    test('redacts unexpected exception text and machine paths', () async {
      final worker = JsonlWorker(api: const _ThrowingReadApi());

      final result = await _request(
        worker,
        id: 'internal-1',
        command: 'open',
        args: const {'projectRoot': 'ignored'},
      );
      final encoded = jsonEncode(result.toJson());

      expect(result.status, AuthoringResultStatus.failure);
      expect(result.error?.code, AuthoringErrorCode.internal);
      expect(result.error?.details['domainCode'], 'worker.internal');
      expect(encoded, isNot(contains('/Users/secret/project')));
      expect(encoded, isNot(contains('StateError')));
      expect(encoded, isNot(contains('stack trace')));
    });

    test('returns the exact direct API query projection', () async {
      final setup = await _TestSetup.create();
      final opened = await setup.api.open(setup.fixture.path);
      final projectHandle = opened['projectHandle']! as String;
      final request = AuthoringQueryRequest(
        resourceKind: 'map',
        operation: AuthoringQueryOperation.list,
        view: AuthoringQueryView.summary,
        pageSize: 10,
      );

      final direct = await setup.api.query(
        ProjectHandle(projectHandle),
        request,
      );
      final transported = await _request(
        setup.worker,
        id: 'parity-1',
        command: 'query',
        args: {
          'projectHandle': projectHandle,
          'request': request.toJson(),
        },
      );

      expect(transported.status, AuthoringResultStatus.success);
      expect(transported.data, direct);
    });

    test('adapts explicit capability records during validation', () async {
      final setup = await _TestSetup.create(clean: true);
      addTearDown(setup.dispose);
      final opened = await _request(
        setup.worker,
        id: 'open-capability',
        command: 'open',
        args: {'projectRoot': setup.fixture.path},
      );

      final validated = await _request(
        setup.worker,
        id: 'validate-capability',
        command: 'validate',
        args: {
          'projectHandle': opened.data['projectHandle'],
          'capabilityTruth': {
            'requiredCapabilityIds': ['narrative.command.dialogue'],
            'records': [
              {
                'capabilityId': 'narrative.command.dialogue',
                'authoringControl': 'Dialogue picker',
                'contractField': 'DialogueCommand.dialogueId',
                'runtimeConsumer': 'DialogueCommandRunner',
                'playerSurface': 'Dialogue overlay',
                'positiveTest': 'dialogue_positive_test.dart',
                'negativeTest': 'dialogue_missing_test.dart',
                'status': 'promoted',
                'reason': null,
              },
            ],
          },
        },
      );

      final capabilityTruth =
          validated.data['capabilityTruth']! as Map<String, Object?>;
      expect(validated.data['valid'], isTrue);
      expect(validated.data['structure'], containsPair('valid', true));
      expect(validated.data['references'], containsPair('valid', true));
      expect(validated.data['capabilityCertification'], {
        'requested': true,
        'status': 'pass',
        'valid': true,
        'requiredCapabilityCount': 1,
        'providedCapabilityCount': 1,
      });
      expect(capabilityTruth['status'], 'pass');
      expect(
        (capabilityTruth['capabilities']! as List).single,
        containsPair('status', 'promoted'),
      );
    });

    test('separates a failed requested capability certification', () async {
      final setup = await _TestSetup.create(clean: true);
      addTearDown(setup.dispose);
      final opened = await _request(
        setup.worker,
        id: 'open-missing-capability',
        command: 'open',
        args: {'projectRoot': setup.fixture.path},
      );

      final validated = await _request(
        setup.worker,
        id: 'validate-missing-capability',
        command: 'validate',
        args: {
          'projectHandle': opened.data['projectHandle'],
          'capabilityTruth': {
            'requiredCapabilityIds': ['narrative.command.dialogue'],
            'records': <Object?>[],
          },
        },
      );

      expect(validated.status, AuthoringResultStatus.success);
      expect(validated.data['valid'], isFalse);
      expect(validated.data['structure'], containsPair('valid', true));
      expect(validated.data['references'], containsPair('valid', true));
      expect(validated.data['capabilityCertification'], {
        'requested': true,
        'status': 'fail',
        'valid': false,
        'requiredCapabilityCount': 1,
        'providedCapabilityCount': 0,
      });
    });

    test('rejects contradictory capability status fields', () async {
      final setup = await _TestSetup.create();
      final opened = await _request(
        setup.worker,
        id: 'open-contradictory-capability',
        command: 'open',
        args: {'projectRoot': setup.fixture.path},
      );

      final result = await _request(
        setup.worker,
        id: 'validate-contradictory-capability',
        command: 'validate',
        args: {
          'projectHandle': opened.data['projectHandle'],
          'capabilityTruth': {
            'requiredCapabilityIds': ['narrative.command.dialogue'],
            'records': [
              {
                'capabilityId': 'narrative.command.dialogue',
                'authoringControl': 'Dialogue picker',
                'contractField': 'DialogueCommand.dialogueId',
                'runtimeConsumer': 'DialogueCommandRunner',
                'playerSurface': 'Dialogue overlay',
                'positiveTest': 'dialogue_positive_test.dart',
                'negativeTest': 'dialogue_missing_test.dart',
                'status': 'promoted',
                'reason': 'Contradicts promoted status.',
              },
            ],
          },
        },
      );

      expect(result.status, AuthoringResultStatus.failure);
      expect(result.error?.code, AuthoringErrorCode.invalidRequest);
    });
  });
}

final class _TestSetup {
  const _TestSetup({
    required this.fixture,
    required this.api,
    required this.worker,
    required this.deleteFixtureOnDispose,
  });

  final Directory fixture;
  final AuthoringReadApi api;
  final JsonlWorker worker;
  final bool deleteFixtureOnDispose;

  static Future<_TestSetup> create({
    int maxInputBytes = 64 * 1024,
    bool clean = false,
  }) async {
    final fixture = clean
        ? await Directory.systemTemp.createTemp('pokemap_read_validation_')
        : Directory(
            [
              Directory.current.parent.parent.path,
              'examples',
              'playable_runtime_host',
              'p3_narrative_smoke_slice',
            ].join(Platform.pathSeparator),
          );
    if (clean) {
      final manifest = ProjectManifest(
        name: 'Clean validation fixture',
        maps: const [],
        tilesets: const [],
        pokemon: const ProjectPokemonConfig(
          enabled: false,
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        ),
      );
      await File('${fixture.path}/project.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
        flush: true,
      );
      for (final directory in [
        'species',
        'learnsets',
        'evolutions',
        'media',
      ]) {
        await Directory('${fixture.path}/data/pokemon/$directory')
            .create(recursive: true);
      }
    }
    var token = 0;
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [fixture.parent.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore(
      clock: () => DateTime.utc(2026, 7, 31, 12),
      tokenFactory: (prefix) => '$prefix${token++}',
    );
    final api = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
    );
    return _TestSetup(
      fixture: fixture,
      api: api,
      deleteFixtureOnDispose: clean,
      worker: JsonlWorker(
        api: api,
        maxInputBytes: maxInputBytes,
        commandTimeout: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> dispose() async {
    if (deleteFixtureOnDispose && await fixture.exists()) {
      await fixture.delete(recursive: true);
    }
  }
}

Future<void> _writeOutOfBoundsRailJourneyFixture(Directory fixture) async {
  const origin = RailJourneyEndpoint(
    stationMapId: 'map_origin_station',
    boardingArea: MapRect(
      pos: GridPos(x: 8, y: 8),
      size: GridSize(width: 3, height: 2),
    ),
    trainEntryPos: GridPos(x: 1, y: 4),
    stationArrivalPos: GridPos(x: 3, y: 6),
    doors: <RailJourneyEndpointDoor>[
      RailJourneyEndpointDoor(
        side: RailJourneyDoorSide.west,
        stationPlacedElementId: 'door_origin_west',
        vehiclePlacedElementId: 'door_vehicle_west',
      ),
    ],
  );
  const destination = RailJourneyEndpoint(
    stationMapId: 'map_destination_station',
    boardingArea: MapRect(
      pos: GridPos(x: 4, y: 2),
      size: GridSize(width: 2, height: 3),
    ),
    trainEntryPos: GridPos(x: 6, y: 4),
    stationArrivalPos: GridPos(x: 7, y: 6),
    doors: <RailJourneyEndpointDoor>[
      RailJourneyEndpointDoor(
        side: RailJourneyDoorSide.east,
        stationPlacedElementId: 'door_destination_east',
        vehiclePlacedElementId: 'door_vehicle_east',
      ),
    ],
  );
  const manifest = ProjectManifest(
    name: 'RailJourney validation fixture',
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map_origin_station',
        name: 'Origin station',
        relativePath: 'maps/origin.json',
      ),
      ProjectMapEntry(
        id: 'map_destination_station',
        name: 'Destination station',
        relativePath: 'maps/destination.json',
      ),
      ProjectMapEntry(
        id: 'map_train_car',
        name: 'Train car',
        relativePath: 'maps/train.json',
        role: MapRole.interior,
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
    pokemon: ProjectPokemonConfig(
      enabled: false,
      ruleset: PokemonRulesetProfile.pokeMapBetaV1,
    ),
    railJourneyCatalog: RailJourneyCatalog(
      journeys: <RailJourneyDefinition>[
        RailJourneyDefinition(
          id: 'T1',
          label: 'Origin to destination',
          origin: origin,
          destination: destination,
          vehicleMapId: 'map_train_car',
          vehicleVariant: RailJourneyVehicleVariant.regular,
          shellState: 'day',
          fare: RailJourneyFare(policy: RailJourneyFarePolicy.storyFree),
        ),
      ],
    ),
  );
  const maps = <String, MapData>{
    'origin.json': MapData(
      id: 'map_origin_station',
      name: 'Origin station',
      size: GridSize(width: 10, height: 10),
    ),
    'destination.json': MapData(
      id: 'map_destination_station',
      name: 'Destination station',
      size: GridSize(width: 10, height: 10),
    ),
    'train.json': MapData(
      id: 'map_train_car',
      name: 'Train car',
      size: GridSize(width: 10, height: 10),
    ),
  };
  await File('${fixture.path}/project.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
    flush: true,
  );
  final mapDirectory = Directory('${fixture.path}/maps');
  await mapDirectory.create(recursive: true);
  for (final entry in maps.entries) {
    await File('${mapDirectory.path}/${entry.key}').writeAsString(
      const JsonEncoder.withIndent('  ').convert(entry.value.toJson()),
      flush: true,
    );
  }
}

Future<void> _writeUnknownRailJourneyItemFixture(Directory fixture) async {
  await _writeOutOfBoundsRailJourneyFixture(fixture);
  final manifestFile = File('${fixture.path}/project.json');
  final manifest = ProjectManifest.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(await manifestFile.readAsString()) as Map,
    ),
  );
  final journey = manifest.railJourneyCatalog!.journeys.single;
  final updatedJourney = journey.copyWith(
    origin: journey.origin.copyWith(
      boardingArea: const MapRect(
        pos: GridPos(x: 2, y: 3),
        size: GridSize(width: 3, height: 2),
      ),
    ),
    requirements: journey.requirements.copyWith(
      requiredItemIds: const <String>{'item_missing'},
    ),
  );
  const doorFrames = <TilesetVisualFrame>[
    TilesetVisualFrame(
      source: TilesetSourceRect(x: 0, y: 0),
      durationMs: 120,
    ),
    TilesetVisualFrame(
      source: TilesetSourceRect(x: 1, y: 0),
      durationMs: 120,
    ),
  ];
  final updatedManifest = manifest.copyWith(
    pokemon: const ProjectPokemonConfig(
      ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      catalogFiles: <String, String>{
        'items': 'data/pokemon/items.json',
      },
    ),
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'doors',
        name: 'Doors',
        relativePath: 'tilesets/doors.png',
      ),
    ],
    elementCategories: const <ProjectElementCategory>[
      ProjectElementCategory(id: 'doors', name: 'Doors'),
    ],
    elements: const <ProjectElementEntry>[
      ProjectElementEntry(
        id: 'element_station_west',
        name: 'Station west door',
        tilesetId: 'doors',
        categoryId: 'doors',
        frames: doorFrames,
      ),
      ProjectElementEntry(
        id: 'element_station_east',
        name: 'Station east door',
        tilesetId: 'doors',
        categoryId: 'doors',
        frames: doorFrames,
      ),
      ProjectElementEntry(
        id: 'element_vehicle_west',
        name: 'Vehicle west door',
        tilesetId: 'doors',
        categoryId: 'doors',
        frames: doorFrames,
      ),
      ProjectElementEntry(
        id: 'element_vehicle_east',
        name: 'Vehicle east door',
        tilesetId: 'doors',
        categoryId: 'doors',
        frames: doorFrames,
      ),
    ],
    railJourneyCatalog: RailJourneyCatalog(
      journeys: <RailJourneyDefinition>[updatedJourney],
    ),
  );
  await manifestFile.writeAsString(
    const JsonEncoder.withIndent(' ').convert(updatedManifest.toJson()),
    flush: true,
  );

  final mapDoorPlacements = <String, List<MapPlacedElement>>{
    'origin.json': const <MapPlacedElement>[
      MapPlacedElement(
        id: 'door_origin_west',
        layerId: 'doors',
        elementId: 'element_station_west',
        pos: GridPos(x: 2, y: 3),
      ),
    ],
    'destination.json': const <MapPlacedElement>[
      MapPlacedElement(
        id: 'door_destination_east',
        layerId: 'doors',
        elementId: 'element_station_east',
        pos: GridPos(x: 4, y: 2),
      ),
    ],
    'train.json': const <MapPlacedElement>[
      MapPlacedElement(
        id: 'door_vehicle_west',
        layerId: 'doors',
        elementId: 'element_vehicle_west',
        pos: GridPos(x: 1, y: 4),
      ),
      MapPlacedElement(
        id: 'door_vehicle_east',
        layerId: 'doors',
        elementId: 'element_vehicle_east',
        pos: GridPos(x: 6, y: 4),
      ),
    ],
  };
  for (final entry in mapDoorPlacements.entries) {
    final mapFile = File('${fixture.path}/maps/${entry.key}');
    final map = MapData.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(await mapFile.readAsString()) as Map,
      ),
    );
    final updatedMap = map.copyWith(
      layers: const <MapLayer>[
        MapLayer.object(id: 'doors', name: 'Doors'),
      ],
      placedElements: entry.value,
    );
    await mapFile.writeAsString(
      const JsonEncoder.withIndent(' ').convert(updatedMap.toJson()),
      flush: true,
    );
  }
  final itemCatalogFile = File('${fixture.path}/data/pokemon/items.json');
  await itemCatalogFile.parent.create(recursive: true);
  await itemCatalogFile.writeAsString(
    const JsonEncoder.withIndent(' ').convert(
      const ProjectItemCatalog(
        schemaVersion: 1,
        entries: <ProjectItemDefinition>[
          ProjectItemDefinition(
            id: 'item_ticket',
            displayName: 'Ticket',
            pocketId: 'key_items',
          ),
        ],
      ).toJson(),
    ),
    flush: true,
  );
}

Future<AuthoringResult> _request(
  JsonlWorker worker, {
  required String id,
  required String command,
  Map<String, Object?> args = const {},
}) async {
  return _decode(
    await worker.processLine(
      jsonEncode({
        'id': id,
        'command': command,
        'args': args,
      }),
    ),
  );
}

AuthoringResult _decode(String line) {
  final decoded = jsonDecode(line);
  return AuthoringResult.fromJson(
    Map<String, dynamic>.from(decoded as Map),
  );
}

final class _DelayedReadApi implements AuthoringReadApiPort {
  const _DelayedReadApi();

  @override
  Map<String, Object?> describe() => const {};

  @override
  Future<Map<String, Object?>> open(String projectRootPath) {
    return Future.delayed(
      const Duration(milliseconds: 50),
      () => const <String, Object?>{},
    );
  }

  @override
  Future<Map<String, Object?>> query(
    ProjectHandle projectHandle,
    AuthoringQueryRequest request,
  ) async =>
      const {};

  @override
  Future<Map<String, Object?>> validate(
    ProjectHandle projectHandle, {
    Iterable<ProjectCapabilityTruthRecord> capabilityRecords = const [],
    Set<String> requiredCapabilityIds = const {},
  }) async =>
      const {};

  @override
  Future<Map<String, Object?>> close(WorkspaceHandle workspaceHandle) async =>
      const {};
}

final class _RecordingGamePackageExportApi implements GamePackageExportApiPort {
  _RecordingGamePackageExportApi({this.delay = Duration.zero});

  final Duration delay;
  String? projectRoot;
  String? outputPath;

  @override
  Future<GamePackageExportReceipt> export({
    required String projectRoot,
    required String outputPath,
  }) async {
    await Future<void>.delayed(delay);
    this.projectRoot = projectRoot;
    this.outputPath = outputPath;
    return GamePackageExportReceipt(
      outputPath: outputPath,
      sizeBytes: 42,
      sha256: 'a' * 64,
      gameId: 'games.example.fixture',
      gameVersion: '1.0.0',
      title: 'Fixture',
      fileCount: 3,
      treeSha256: 'b' * 64,
    );
  }
}

final class _ThrowingReadApi implements AuthoringReadApiPort {
  const _ThrowingReadApi();

  @override
  Map<String, Object?> describe() => throw StateError(
        '/Users/secret/project stack trace should never be serialized',
      );

  @override
  Future<Map<String, Object?>> open(String projectRootPath) {
    throw StateError(
      '/Users/secret/project stack trace should never be serialized',
    );
  }

  @override
  Future<Map<String, Object?>> query(
    ProjectHandle projectHandle,
    AuthoringQueryRequest request,
  ) async =>
      throw StateError(
        '/Users/secret/project stack trace should never be serialized',
      );

  @override
  Future<Map<String, Object?>> validate(
    ProjectHandle projectHandle, {
    Iterable<ProjectCapabilityTruthRecord> capabilityRecords = const [],
    Set<String> requiredCapabilityIds = const {},
  }) async =>
      throw StateError(
        '/Users/secret/project stack trace should never be serialized',
      );

  @override
  Future<Map<String, Object?>> close(WorkspaceHandle workspaceHandle) async =>
      throw StateError(
        '/Users/secret/project stack trace should never be serialized',
      );
}
