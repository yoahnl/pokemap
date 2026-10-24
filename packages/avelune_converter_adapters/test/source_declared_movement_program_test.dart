import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_converter_adapters/src/source_hole_native_program.dart';
import 'package:avelune_converter_adapters/src/source_transfer_program_authority.dart';
import 'package:avelune_converter_adapters/src/source_elevator_program.dart';
import 'package:avelune_converter_adapters/src/source_warp_tile_native_program.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/source_external_original_fixture.dart';

LiteralFixtureObject _move(int opacity) =>
    LiteralFixtureObject('RPG::MoveCommand', {
      '@code': 42,
      '@parameters': [opacity]
    });
LiteralFixtureObject _route(int opacity) =>
    LiteralFixtureObject('RPG::MoveRoute', {
      '@repeat': false,
      '@skippable': true,
      '@list': [
        _move(opacity),
        const LiteralFixtureObject(
            'RPG::MoveCommand', {'@code': 0, '@parameters': <Object?>[]})
      ],
    });
LiteralFixtureUserDefined _tone(double value) {
  final bytes = ByteData(32);
  for (var index = 0; index < 3; index++) {
    bytes.setFloat64(index * 8, value, Endian.little);
  }
  return LiteralFixtureUserDefined('Tone', bytes.buffer.asUint8List());
}

LiteralFixtureObject _sound(String name) => LiteralFixtureObject(
    'RPG::AudioFile', {'@name': name, '@volume': 80, '@pitch': 100});

LiteralFixtureEventPage _holePage(int destination, String sound) =>
    LiteralFixtureEventPage(trigger: 1, through: true, commands: [
      LiteralFixtureEventCommand(209, [-1, _route(0)]),
      LiteralFixtureEventCommand(509, [_move(0)]),
      const LiteralFixtureEventCommand(210, []),
      LiteralFixtureEventCommand(250, [_sound('$sound down')]),
      const LiteralFixtureEventCommand(106, [4]),
      LiteralFixtureEventCommand(223, [_tone(-255), 6]),
      const LiteralFixtureEventCommand(106, [8]),
      LiteralFixtureEventCommand(201, [0, destination, 1, 0, 0, 1]),
      LiteralFixtureEventCommand(209, [-1, _route(255)]),
      LiteralFixtureEventCommand(509, [_move(255)]),
      const LiteralFixtureEventCommand(210, []),
      LiteralFixtureEventCommand(223, [_tone(0), 6]),
      LiteralFixtureEventCommand(250, [_sound('$sound up')]),
      const LiteralFixtureEventCommand(0, []),
    ]);

Object? _value(Object? value) => switch (value) {
      LiteralFixtureObject() => {
          '__class__': value.name,
          for (final field in value.fields.entries)
            field.key.substring(1): _value(field.value)
        },
      LiteralFixtureUserDefined() => {
          '__class__': value.name,
          'marshalPayload': base64Encode(value.bytes)
        },
      List() => value.map(_value).toList(),
      _ => value,
    };

Map<String, Object?> _pageValue(LiteralFixtureEventPage page) => {
      '__class__': 'RPG::Event::Page',
      'condition': {
        '__class__': 'RPG::Event::Page::Condition',
        'switch1_valid': page.globalSwitch != null,
        'switch2_valid': false,
        'variable_valid': false,
        'self_switch_valid': page.selfSwitch != null,
        'switch1_id': page.globalSwitch ?? 1,
        'switch2_id': 1,
        'variable_id': 1,
        'variable_value': 0,
        'self_switch_ch': page.selfSwitch ?? 'A'
      },
      'graphic': {
        '__class__': 'RPG::Event::Page::Graphic',
        'tile_id': 0,
        'character_name': page.characterName,
        'character_hue': 0,
        'direction': page.direction,
        'pattern': page.pattern,
        'opacity': 255,
        'blend_type': 0
      },
      'move_type': 0,
      'move_speed': 3,
      'move_frequency': 3,
      'move_route': {
        '__class__': 'RPG::MoveRoute',
        'repeat': true,
        'skippable': false,
        'list': [
          {
            '__class__': 'RPG::MoveCommand',
            'code': 0,
            'parameters': <Object?>[]
          }
        ]
      },
      'walk_anime': true,
      'step_anime': false,
      'direction_fix': false,
      'through': page.through,
      'always_on_top': false,
      'trigger': page.trigger,
      'list': [
        for (final command in page.commands)
          {
            '__class__': 'RPG::EventCommand',
            'code': command.code,
            'indent': command.indent,
            'parameters': _value(command.parameters)
          }
      ],
    };

SourceEventAnalysis _withEvents(
        SourceEventAnalysis analysis, List<SourceEventDefinition> events) =>
    SourceEventAnalysis(
        profile: analysis.profile,
        events: events,
        diagnostics: analysis.diagnostics);

SourceEventDefinition _renamed(SourceEventDefinition event) =>
    SourceEventDefinition(
        identity: event.identity,
        sourceMapId: event.sourceMapId,
        sourceEventId: event.sourceEventId,
        sourceFileId: event.sourceFileId,
        name: 'Changed outside sealed evidence',
        x: event.x,
        y: event.y,
        locator: event.locator,
        pages: event.pages);

Future<NormalizedSourceProject> _reprofile(
        LiteralTileFixture fixture, SourceInterpretationProfile profile) =>
    const RmxpSourceNormalizer().normalize(
        snapshot: fixture.snapshot,
        files: fixture.files,
        selectedMapIds: fixture.source.selectedSourceMapIds.toSet(),
        includeEventSystem: true,
        interpretationProfile: profile);

SourceEventAnalysis _analyze(NormalizedSourceProject source) =>
    SourceEventAnalyzer.forProject(source,
            profile: SourceEventProfile.forProject(source))
        .analyze();

void main() {
  test('indexed elevator candidacy preserves exact declared pages and neighbors',
      () async {
    const declaredPage = LiteralFixtureEventPage(
        characterName: 'OriginalLiftActor',
        commands: [LiteralFixtureEventCommand(0, [])]);
    final profile = SourceInterpretationProfile.fromJson({
      ...syntheticSourceInterpretationProfile.toJson(),
      'declaredPrograms': [
        {
          'id': 'indexed-original-elevator-actor',
          'family': 'elevator',
          'pages': {'program': _pageValue(declaredPage)},
          'parameters': {'role': 'actor', 'familyId': 'indexed-original-lift'}
        }
      ]
    });
    final fixture = await LiteralTileFixture.create(
        scriptsBytes: syntheticInterpretationArchive,
        interpretationProfile: profile,
        includeEventSystem: true,
        maps: [
          LiteralFixtureMap(id: 17, events: const [
            LiteralFixtureEvent(id: 1, x: 0, y: 0, pages: [declaredPage]),
            LiteralFixtureEvent(id: 2, x: 1, y: 0, pages: [
              LiteralFixtureEventPage(commands: [LiteralFixtureEventCommand(0, [])])
            ])
          ]),
          LiteralFixtureMap(id: 83, events: const [
            LiteralFixtureEvent(id: 1, x: 0, y: 0, pages: [
              LiteralFixtureEventPage(commands: [LiteralFixtureEventCommand(0, [])])
            ])
          ])
        ]);
    final source = fixture.source;
    final analysis = _analyze(source);
    final expected = <ConverterId, bool>{};
    for (final event in analysis.events) {
      final original = source.maps
          .singleWhere((map) => map.map.sourceMapId == event.sourceMapId)
          .map.events.singleWhere((raw) => raw.sourceEventId == event.sourceEventId);
      expected[event.identity] = matchSourceDeclaredProgram(
          source: source, profile: analysis.profile,
          sourceMapId: event.sourceMapId, event: original,
          families: const {SourceDeclaredProgramFamily.elevator}) != null;
      expect(source.uniqueEventAt(event.sourceMapId, event.sourceEventId)!.toJson(),
          original.toJson());
      expect(isSourceElevatorFamilyEvent(event,
          source: source, profile: analysis.profile), expected[event.identity]);
    }
    expect(expected[analysis.eventAt(17, 1)!.identity], isTrue);
    expect(expected[analysis.eventAt(17, 2)!.identity], isFalse);
    expect(expected[analysis.eventAt(83, 1)!.identity], isFalse);
    expect(source.uniqueEventAt(17, 1),
        same(source.uniqueEventAt(17, 1)));
  });

  final oraclePath = Platform.environment['AVELUNE_DECLARED_MOVEMENT_ORACLE'];
  test('explicit oracle dataset preserves complete declared movement programs',
      () async {
    final file = File(oraclePath!);
    expect(await file.length(), lessThanOrEqualTo(2097152));
    final oracle =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    expect(
        oracle.keys,
        unorderedEquals([
          'schemaVersion',
          'sourceRoot',
          'snapshotPath',
          'supplementalRoots',
          'selectedMapIds',
          'expected'
        ]));
    expect(oracle['schemaVersion'], 1);
    final selection = (oracle['selectedMapIds'] as List).cast<int>();
    expect(selection, isNotEmpty);
    expect(selection.length, lessThanOrEqualTo(256));
    expect(selection.toSet().length, selection.length);
    expect(selection.every((id) => id > 0), isTrue);
    final expected = Map<String, int>.from(oracle['expected'] as Map);
    expect(
        expected.keys,
        unorderedEquals([
          'holes',
          'elevators',
          'warpTiles',
          'warpActivations',
          'warpRepairs'
        ]));
    expect(expected.values.every((count) => count >= 0 && count <= 100000),
        isTrue);
    final fixture = await readExternalOriginalSource(
        oracle['sourceRoot'] as String, oracle['snapshotPath'] as String,
        supplementalRoots: (oracle['supplementalRoots'] as List).cast<String>(),
        selectedMapIds: selection.toSet());
    final source = fixture.source;
    expect(source.canPlan, isTrue,
        reason: source.diagnostics.map((d) => d.toJson()).toString());
    final analysis = _analyze(source);
    expect(sourceHoleNativePrograms(source: source, analysis: analysis),
        hasLength(expected['holes']!));
    expect(sourceElevatorPrograms(source: source, analysis: analysis),
        hasLength(expected['elevators']!));
    final warp =
        sourceWarpTileNativePrograms(source: source, analysis: analysis);
    expect(warp.refusals, isEmpty);
    expect(warp.programs.values.where((program) => !program.isActivation),
        hasLength(expected['warpTiles']!));
    expect(warp.programs.values.where((program) => program.isActivation),
        hasLength(expected['warpActivations']!));
    expect(warp.programs.values.where((program) => program.repairsTarget),
        hasLength(expected['warpRepairs']!));
  }, skip: oraclePath == null, timeout: const Timeout(Duration(minutes: 2)));
  test(
      'declared warp tile graphs derive relocated state variables and arrival offsets',
      () async {
    for (final offset in [0, 40]) {
      for (final unexpectedState in [false, true]) {
        final origin = 7 + offset, destination = 8 + offset;
        final tileId = 3 + offset,
            otherId = 4 + offset,
            activationId = 5 + offset;
        final variables = [17 + offset, 18 + offset, 19 + offset];
        List<LiteralFixtureEventCommand> positions() => [
              LiteralFixtureEventCommand(
                  122, [variables[0], variables[0], 0, 7, 0]),
              LiteralFixtureEventCommand(
                  122, [variables[1], variables[1], 0, 6, 0, 0]),
              LiteralFixtureEventCommand(
                  122, [variables[2], variables[2], 0, 6, 0, 1]),
            ];
        LiteralFixtureEventPage departure(int target) =>
            LiteralFixtureEventPage(selfSwitch: 'B', trigger: 1, commands: [
              ...positions(),
              LiteralFixtureEventCommand(
                  250, [_sound('Independent warp $offset')]),
              LiteralFixtureEventCommand(223, [_tone(-255), 6]),
              const LiteralFixtureEventCommand(106, [8]),
              LiteralFixtureEventCommand(201, [0, target, 1, 0, 2, 1]),
              if (unexpectedState)
                const LiteralFixtureEventCommand(123, ['D', 0]),
              const LiteralFixtureEventCommand(0, []),
            ]);
        final arrival =
            LiteralFixtureEventPage(globalSwitch: 1, trigger: 3, commands: [
          const LiteralFixtureEventCommand(111, [12, 'get_self.onEvent?']),
          ...positions().map((command) => LiteralFixtureEventCommand(
              command.code, command.parameters,
              indent: 1)),
          LiteralFixtureEventCommand(
              122, [variables[2], variables[2], 2, 0, 2 + offset],
              indent: 1),
          LiteralFixtureEventCommand(
              250, [_sound('Independent arrival $offset')],
              indent: 1),
          LiteralFixtureEventCommand(223, [_tone(0), 6], indent: 1),
          const LiteralFixtureEventCommand(412, []),
          const LiteralFixtureEventCommand(123, ['B', 1]),
          const LiteralFixtureEventCommand(355, ['setTempSwitchOn("C")']),
          const LiteralFixtureEventCommand(0, []),
        ]);
        final activation = LiteralFixtureEventPage(commands: [
          LiteralFixtureEventCommand(
              355, ['pbSetSelfSwitch($tileId,"B",true)']),
          const LiteralFixtureEventCommand(0, [])
        ]);
        final profile = SourceInterpretationProfile.fromJson({
          ...syntheticSourceInterpretationProfile.toJson(),
          'declaredPrograms': [
            for (final (id, target) in [
              ('origin-tile', destination),
              ('destination-tile', origin)
            ])
              {
                'id': id,
                'family': 'warpTile',
                'pages': {
                  'departure': _pageValue(departure(target)),
                  'arrival': _pageValue(arrival)
                },
                'parameters': {'role': 'tile'},
              },
            {
              'id': 'activation',
              'family': 'warpTile',
              'pages': {'program': _pageValue(activation)},
              'parameters': {'role': 'activation', 'targetRole': 'origin-tile'}
            },
            {
              'id': 'other-graph-activation',
              'family': 'warpTile',
              'pages': {'program': _pageValue(activation)},
              'parameters': {
                'role': 'activation',
                'targetRole': 'destination-tile'
              }
            },
          ]
        });
        final fixture = await LiteralTileFixture.create(
            namespace: 'tile-graph-$offset',
            scriptsBytes: syntheticInterpretationArchive,
            interpretationProfile: profile,
            includeEventSystem: true,
            switchNames: const [
              null,
              's:tsOff?("C")'
            ],
            variableNames: [
              null,
              ...List.generate(
                  variables.last, (index) => 'Position ${index + 1}')
            ],
            maps: [
              LiteralFixtureMap(id: origin, events: [
                LiteralFixtureEvent(
                    id: tileId,
                    x: 1,
                    y: 0,
                    name: 'Independent departure',
                    pages: [departure(destination), arrival]),
                LiteralFixtureEvent(
                    id: activationId, x: 0, y: 0, pages: [activation])
              ]),
              LiteralFixtureMap(id: destination, events: [
                LiteralFixtureEvent(
                    id: otherId,
                    x: 1,
                    y: 0,
                    name: 'Independent return',
                    pages: [departure(origin), arrival])
              ]),
            ]);
        final authority =
            SourceTransferProgramAuthority.forSource(fixture.source);
        final analysis = authority.analysis;
        final result = sourceWarpTileNativePrograms(
            source: fixture.source, analysis: analysis, authority: authority);
        final absent =
            await _reprofile(fixture, syntheticSourceInterpretationProfile);
        final automatic = sourceWarpTileNativePrograms(
            source: absent, analysis: _analyze(absent));
        if (unexpectedState) {
          expect(result.programs, isEmpty,
              reason:
                  'A whole declared page cannot silently discard another persistent self switch write');
          expect(automatic.programs, isEmpty,
              reason:
                  'Automatic discovery must reject the same extra persistent write');
          continue;
        }
        expect(result.programs, hasLength(3));
        expect(
            result.programs.map((key, value) => MapEntry(key, value.toJson())),
            sourceWarpTileNativePrograms(
                    source: fixture.source, analysis: analysis)
                .programs
                .map((key, value) => MapEntry(key, value.toJson())));
        expect(authority.analysis, same(analysis));
        expect(
            result.programs.values.every((program) =>
                !program.declaredProgramBinding.automaticallyDiscovered),
            isTrue);
        final native = result.programs.values
            .firstWhere((program) => !program.isActivation);
        expect(native.toJson()['sourcePositionVariableIds'], variables);
        expect(native.toJson()['arrivalYOffset'], -(2 + offset));
        expect(native.toJson()['selfSwitchLetter'], 'B');
        expect(native.toJson()['tempSwitchLetter'], 'C');
        final declared = profile.toJson()['declaredPrograms'] as List;
        final ambiguous = await _reprofile(
            fixture,
            SourceInterpretationProfile.fromJson({
              ...profile.toJson(),
              'declaredPrograms': [
                ...declared,
                {...(declared[2] as Map), 'id': 'ambiguous-activation'}
              ]
            }));
        expect(
            sourceWarpTileNativePrograms(
                    source: ambiguous, analysis: _analyze(ambiguous))
                .programs
                .values
                .any((program) => program.isActivation),
            isFalse);
        expect(
            sourceWarpTileNativePrograms(
                    source: fixture.source,
                    authority: authority,
                    analysis: _withEvents(
                        analysis, [...analysis.events, analysis.events.first]))
                .programs,
            isEmpty);
        expect(
            sourceWarpTileNativePrograms(
                source: fixture.source,
                authority: authority,
                analysis: _withEvents(analysis, [
                  for (final event in analysis.events)
                    event.identity == native.event.identity
                        ? _renamed(event)
                        : event
                ])).programs,
            isEmpty);
        expect(
            sourceWarpTileNativePrograms(
                    source: fixture.source,
                    authority: authority,
                    analysis: _withEvents(
                        analysis,
                        analysis.events
                            .where((event) => event.sourceMapId != destination)
                            .toList()))
                .programs,
            isEmpty);
        expect(automatic.programs, hasLength(2));
        expect(
            automatic.programs.values.every((program) =>
                !program.isActivation &&
                program.declaredProgramBinding.automaticallyDiscovered),
            isTrue);
        expect(
            automatic.programs
                .containsKey(absent.eventIdentity(origin, activationId)),
            isFalse,
            reason:
                'The action-button activation still requires its explicit binding');
        for (final program in automatic.programs.values) {
          final declaredProgram = result.programs[program.event.identity]!;
          expect(program.sourcePositionVariableIds, variables);
          expect(program.arrivalYOffset, -(2 + offset));
          expect(program.sourcePositionVariableIds,
              declaredProgram.sourcePositionVariableIds);
          expect(program.arrivalYOffset, declaredProgram.arrivalYOffset);
          expect(program.selfSwitchLetter, declaredProgram.selfSwitchLetter);
          expect(program.tempSwitchLetter, declaredProgram.tempSwitchLetter);
          expect(program.warp!.targetSourceMapId,
              declaredProgram.warp!.targetSourceMapId);
          expect(program.warp!.x, declaredProgram.warp!.x);
          expect(program.warp!.y, declaredProgram.warp!.y);
        }
      }
    }
  });

  test(
      'declared elevator closure derives relocated cabin roles and variable IDs',
      () async {
    for (final offset in [0, 40]) {
      for (final malformed in [false, true]) {
        final low = 20 + offset, high = 21 + offset, cabin = 22 + offset;
        final current = 7 + offset, selected = 9 + offset, actor = 33 + offset;
        LiteralFixtureEventPage door(int floor) =>
            LiteralFixtureEventPage(trigger: 1, commands: [
              LiteralFixtureEventCommand(122, [current, current, 0, 0, floor]),
              LiteralFixtureEventCommand(201, [0, cabin, 1, 0, 0, 1]),
              const LiteralFixtureEventCommand(0, []),
            ]);
        final exit = LiteralFixtureEventPage(trigger: 1, commands: [
          LiteralFixtureEventCommand(223, [_tone(-255), 6]),
          LiteralFixtureEventCommand(111, [1, current, 0, 2, 0]),
          LiteralFixtureEventCommand(201, [0, high, 1, 0, 0, 1], indent: 1),
          const LiteralFixtureEventCommand(411, []),
          LiteralFixtureEventCommand(201, [0, low, 1, 0, 0, 1], indent: 1),
          const LiteralFixtureEventCommand(412, []),
          LiteralFixtureEventCommand(223, [_tone(0), 6]),
          const LiteralFixtureEventCommand(0, []),
        ]);
        final actorPage = LiteralFixtureEventPage(
            characterName: 'IndependentActor$offset',
            commands: const [LiteralFixtureEventCommand(0, [])]);
        final controller = LiteralFixtureEventPage(commands: [
          LiteralFixtureEventCommand(355, [
            'cur=2-pbGet($current)\n\$game_variables[$selected]=pbMessage(_I("Pick a level"),[_I("High"),_I("Low"),_I("Stop")],3,nil,cur)'
          ]),
          LiteralFixtureEventCommand(
              355, ['t=pbGet($selected)\npbSet($selected,2-t)']),
          LiteralFixtureEventCommand(111, [1, selected, 0, 0, 0]),
          const LiteralFixtureEventCommand(411, []),
          LiteralFixtureEventCommand(118, ['Cycle $offset'], indent: 1),
          LiteralFixtureEventCommand(
              111, [1, selected, 1, current, malformed ? 0 : 3],
              indent: 1),
          LiteralFixtureEventCommand(
              209,
              [
                actor,
                const LiteralFixtureObject('RPG::MoveRoute', {
                  '@repeat': false,
                  '@skippable': false,
                  '@list': [
                    LiteralFixtureObject('RPG::MoveCommand',
                        {'@code': 16, '@parameters': <Object?>[]}),
                    LiteralFixtureObject('RPG::MoveCommand',
                        {'@code': 0, '@parameters': <Object?>[]})
                  ]
                })
              ],
              indent: 2),
          const LiteralFixtureEventCommand(
              509,
              [
                LiteralFixtureObject('RPG::MoveCommand',
                    {'@code': 16, '@parameters': <Object?>[]})
              ],
              indent: 2),
          const LiteralFixtureEventCommand(210, [], indent: 2),
          LiteralFixtureEventCommand(122, [current, current, 1, 0, 1],
              indent: 2),
          LiteralFixtureEventCommand(119, ['Cycle $offset'], indent: 2),
          const LiteralFixtureEventCommand(412, [], indent: 1),
          LiteralFixtureEventCommand(111, [1, selected, 1, current, 4],
              indent: 1),
          LiteralFixtureEventCommand(122, [current, current, 2, 0, 1],
              indent: 2),
          LiteralFixtureEventCommand(119, ['Cycle $offset'], indent: 2),
          const LiteralFixtureEventCommand(412, [], indent: 1),
          const LiteralFixtureEventCommand(412, []),
          const LiteralFixtureEventCommand(0, []),
        ]);
        final bindings = [
          for (final (id, role, page, extra) in [
            ('low', 'door', door(1), {'floor': 1}),
            ('high', 'door', door(2), {'floor': 2}),
            ('exit', 'exit', exit, <String, Object?>{}),
            ('controller', 'controller', controller, {'maximumFloor': 2}),
            ('actor', 'actor', actorPage, <String, Object?>{}),
          ])
            {
              'id': 'independent-lift-$id',
              'family': 'elevator',
              'pages': {'program': _pageValue(page)},
              'parameters': {
                'role': role,
                'familyId': 'independent-lift',
                ...extra
              }
            },
        ];
        final profile = SourceInterpretationProfile.fromJson({
          ...syntheticSourceInterpretationProfile.toJson(),
          'declaredPrograms': bindings
        });
        final fixture = await LiteralTileFixture.create(
            namespace: 'lift-$offset',
            scriptsBytes: syntheticInterpretationArchive,
            interpretationProfile: profile,
            includeEventSystem: true,
            variableNames: [
              null,
              ...List.generate(selected, (index) => 'Variable ${index + 1}')
            ],
            maps: [
              LiteralFixtureMap(id: low, events: [
                LiteralFixtureEvent(
                    id: 5 + offset, x: 0, y: 0, pages: [door(1)])
              ]),
              LiteralFixtureMap(id: high, events: [
                LiteralFixtureEvent(
                    id: 6 + offset, x: 0, y: 0, pages: [door(2)])
              ]),
              LiteralFixtureMap(id: cabin, events: [
                LiteralFixtureEvent(id: 1 + offset, x: 0, y: 0, pages: [exit]),
                LiteralFixtureEvent(
                    id: 2 + offset, x: 1, y: 0, pages: [controller]),
                LiteralFixtureEvent(id: actor, x: 2, y: 0, pages: [actorPage])
              ]),
            ]);
        final authority =
            SourceTransferProgramAuthority.forSource(fixture.source);
        final analysis = authority.analysis;
        final programs = sourceElevatorPrograms(
            source: fixture.source, analysis: analysis, authority: authority);
        if (malformed) {
          expect(programs, isEmpty,
              reason:
                  'A matching declared page does not certify a different elevator loop condition');
          continue;
        }
        expect(programs, hasLength(5));
        expect(
            programs.map((key, value) => MapEntry(key, value.toJson())),
            sourceElevatorPrograms(source: fixture.source, analysis: analysis)
                .map((key, value) => MapEntry(key, value.toJson())));
        expect(authority.analysis, same(analysis));
        final nativeController = programs.values.singleWhere(
            (program) => program.role == SourceElevatorRole.controller);
        expect(nativeController.toJson()['currentFloorVariableId'], current);
        expect(nativeController.toJson()['selectionVariableId'], selected);
        expect(nativeController.toJson()['sourceActorIds'], [actor]);
        expect(
            sourceElevatorPrograms(
                source: fixture.source,
                authority: authority,
                analysis: _withEvents(
                    analysis, [...analysis.events, analysis.events.first])),
            isEmpty);
        expect(
            sourceElevatorPrograms(
                source: fixture.source,
                authority: authority,
                analysis: _withEvents(
                    analysis,
                    analysis.events
                        .where((event) => event.sourceEventId != actor)
                        .toList())),
            isEmpty);
        expect(
            sourceElevatorPrograms(
                source: fixture.source,
                authority: authority,
                analysis: _withEvents(analysis, [
                  for (final event in analysis.events)
                    event.identity == nativeController.event.identity
                        ? _renamed(event)
                        : event
                ])),
            isEmpty);
        final absent =
            await _reprofile(fixture, syntheticSourceInterpretationProfile);
        expect(
            sourceElevatorPrograms(source: absent, analysis: _analyze(absent)),
            isEmpty);
      }
    }
  });

  test('native holes require exact typed player hide and show routes',
      () async {
    for (final variant in [
      'valid',
      'terrainBump',
      'target',
      'repeat',
      'skippable',
      'reversedOpacity',
      'extraStep'
    ]) {
      final original = _holePage(12, 'Original shaft');
      final hidden = _move(variant == 'reversedOpacity' ? 255 : 0);
      final commands = [
        LiteralFixtureEventCommand(209, [
          variant == 'target' ? 0 : -1,
          LiteralFixtureObject('RPG::MoveRoute', {
            '@repeat': variant == 'repeat',
            '@skippable': variant != 'skippable',
            '@list': [
              hidden,
              if (variant == 'extraStep') _move(0),
              const LiteralFixtureObject(
                  'RPG::MoveCommand', {'@code': 0, '@parameters': <Object?>[]})
            ]
          })
        ]),
        LiteralFixtureEventCommand(509, [hidden]),
        if (variant == 'extraStep') LiteralFixtureEventCommand(509, [_move(0)]),
        ...original.commands.skip(2)
      ];
      final terrainOrder = [3, 0, 1, 4, 5, 6, 7, 2, 8, 9, 11, 12, 13];
      final page = LiteralFixtureEventPage(
          trigger: 1,
          through: variant != 'terrainBump',
          commands: variant == 'terrainBump'
              ? [for (final index in terrainOrder) commands[index]]
              : commands);
      final fixture = await LiteralTileFixture.create(
          namespace: 'typed-hole-$variant',
          scriptsBytes: syntheticInterpretationArchive,
          interpretationProfile: syntheticSourceInterpretationProfile,
          includeEventSystem: true,
          maps: [
            LiteralFixtureMap(id: 11, events: [
              LiteralFixtureEvent(
                  id: 23,
                  x: 0,
                  y: 0,
                  name: 'Original shaft size(2,1)',
                  pages: [page])
            ]),
            LiteralFixtureMap(id: 12)
          ]);
      final analysis = _analyze(fixture.source);
      final event = analysis.eventAt(11, 23)!;
      final accepted = variant == 'valid' || variant == 'terrainBump';
      expect(isSourceHoleNativeIdentity(event), accepted, reason: variant);
      final programs =
          sourceHoleNativePrograms(source: fixture.source, analysis: analysis);
      expect(programs.length, accepted ? 1 : 0, reason: variant);
      if (!accepted) continue;
      final routes = event.pages.single.body.nodes
          .whereType<SourceForcedMoveRouteNode>()
          .toList();
      expect(routes.map((route) => route.steps.single.kind),
          [SourceMoveRouteStepKind.hide, SourceMoveRouteStepKind.show]);
      expect(programs.values.single.terrainBump, variant == 'terrainBump');
      final sourcePage = event.pages.single;
      final forged = SourceEventDefinition(
          identity: event.identity,
          sourceMapId: event.sourceMapId,
          sourceEventId: event.sourceEventId,
          sourceFileId: event.sourceFileId,
          name: event.name,
          x: event.x,
          y: event.y,
          locator: event.locator,
          pages: [
            SourceEventPageAnalysis(
                sourcePage: sourcePage.sourcePage,
                locator: sourcePage.locator,
                condition: sourcePage.condition,
                graphic: sourcePage.graphic,
                rawDataRef: sourcePage.rawDataRef,
                diagnostics: sourcePage.diagnostics,
                body: SourceEventBlock(
                    span: sourcePage.body.span,
                    diagnostics: sourcePage.body.diagnostics,
                    nodes: [
                      for (final node in sourcePage.body.nodes)
                        if (node is SourceForcedMoveRouteNode)
                          SourceForcedMoveRouteNode(node.span,
                              targetSourceCharacterId:
                                  node.targetSourceCharacterId,
                              repeat: node.repeat,
                              skippable: node.skippable,
                              steps: node.steps,
                              rawDataRefs: node.rawDataRefs,
                              terminatorNodeId: node.terminatorNodeId,
                              profileHash: literalFixtureHash([1, 2, 3]))
                        else
                          node
                    ]))
          ]);
      expect(isSourceHoleNativeIdentity(forged), isTrue);
      expect(
          sourceHoleNativePrograms(
              source: fixture.source,
              analysis: _withEvents(analysis, [forged])),
          isEmpty,
          reason: 'Typed route evidence must match authoritative analysis');
    }
  });

  test(
      'declared and automatic holes work in renamed projects with relocated identities',
      () async {
    for (final (mapId, eventId, name) in [
      (7, 9, 'Shaft alpha'),
      (71, 31, 'Trap beta')
    ]) {
      final page = _holePage(mapId + 1, name);
      final profile = SourceInterpretationProfile.fromJson({
        ...syntheticSourceInterpretationProfile.toJson(),
        'declaredPrograms': [
          {
            'id': 'original-hole',
            'family': 'hole',
            'pages': {'program': _pageValue(page)},
            'parameters': <String, Object?>{},
          }
        ]
      });
      final fixture = await LiteralTileFixture.create(
          namespace: 'movement-project-$mapId',
          scriptsBytes: syntheticInterpretationArchive,
          interpretationProfile: profile,
          includeEventSystem: true,
          maps: [
            LiteralFixtureMap(id: mapId, events: [
              LiteralFixtureEvent(
                  id: eventId, x: 0, y: 0, name: name, pages: [page])
            ]),
            LiteralFixtureMap(id: mapId + 1)
          ]);
      final authority =
          SourceTransferProgramAuthority.forSource(fixture.source);
      final analysis = authority.analysis;
      final programs = sourceHoleNativePrograms(
          source: fixture.source, analysis: analysis, authority: authority);
      expect(programs, hasLength(1));
      expect(
          programs.map((key, value) => MapEntry(key, value.toJson())),
          sourceHoleNativePrograms(source: fixture.source, analysis: analysis)
              .map((key, value) => MapEntry(key, value.toJson())));
      expect(authority.analysis, same(analysis));
      final program = programs.values.single;
      expect(program.sourceMapId, mapId);
      expect(program.sourceEventId, eventId);
      expect(program.fallingSound.name, '$name down');
      expect(program.toJson()['declaredProgramBinding'], isNotNull);
      expect(program.declaredProgramBinding.automaticallyDiscovered, isFalse);
      expect(
          sourceHoleNativePrograms(
              source: fixture.source,
              authority: authority,
              analysis: _withEvents(
                  analysis, [...analysis.events, analysis.events.first])),
          isEmpty);
      expect(
          sourceHoleNativePrograms(
              source: fixture.source,
              authority: authority,
              analysis:
                  _withEvents(analysis, [_renamed(analysis.events.single)])),
          isEmpty);
      final absent =
          await _reprofile(fixture, syntheticSourceInterpretationProfile);
      final automatic =
          sourceHoleNativePrograms(source: absent, analysis: _analyze(absent));
      expect(automatic, hasLength(1));
      expect(
          automatic
              .values.single.declaredProgramBinding.automaticallyDiscovered,
          isTrue);
      expect(automatic.values.single.sourceMapId, mapId);
      expect(automatic.values.single.sourceEventId, eventId);
      final declaration =
          (profile.toJson()['declaredPrograms'] as List).single as Map;
      final ambiguous = await _reprofile(
          fixture,
          SourceInterpretationProfile.fromJson({
            ...profile.toJson(),
            'declaredPrograms': [
              declaration,
              {...declaration, 'id': 'ambiguous-hole'}
            ]
          }));
      expect(
          sourceHoleNativePrograms(
              source: ambiguous, analysis: _analyze(ambiguous)),
          isEmpty);
    }
  });
  test(
      'whole declared pages never certify unknown route scripts or divergent continuations',
      () async {
    for (final variant in ['script', 'continuation']) {
      final original = _holePage(12, 'Independent shaft');
      final unsafe = const LiteralFixtureObject('RPG::MoveCommand', {
        '@code': 45,
        '@parameters': ['arbitrary_side_effect()']
      });
      final page =
          LiteralFixtureEventPage(trigger: 1, through: true, commands: [
        if (variant == 'script')
          LiteralFixtureEventCommand(209, [
            -1,
            LiteralFixtureObject('RPG::MoveRoute', {
              '@repeat': false,
              '@skippable': true,
              '@list': [
                unsafe,
                const LiteralFixtureObject('RPG::MoveCommand',
                    {'@code': 0, '@parameters': <Object?>[]})
              ]
            })
          ])
        else
          original.commands.first,
        LiteralFixtureEventCommand(
            509, [variant == 'script' ? unsafe : _move(1)]),
        ...original.commands.skip(2)
      ]);
      final input = {
        ...syntheticSourceInterpretationProfile.toJson(),
        'declaredPrograms': [
          {
            'id': 'unsafe-shaft',
            'family': 'hole',
            'pages': {'program': _pageValue(page)},
            'parameters': <String, Object?>{}
          }
        ]
      };
      if (variant == 'script') {
        expect(
            () => SourceInterpretationProfile.fromJson(input),
            throwsA(isA<ContractError>().having(
                (error) => error.code, 'code', 'declared_program.route')));
        continue;
      }
      final profile = SourceInterpretationProfile.fromJson(input);
      final fixture = await LiteralTileFixture.create(
          namespace: 'unsafe-$variant',
          scriptsBytes: syntheticInterpretationArchive,
          interpretationProfile: profile,
          includeEventSystem: true,
          maps: [
            LiteralFixtureMap(id: 11, events: [
              LiteralFixtureEvent(id: 23, x: 0, y: 0, pages: [page])
            ]),
            LiteralFixtureMap(id: 12)
          ]);
      expect(
          sourceHoleNativePrograms(
              source: fixture.source, analysis: _analyze(fixture.source)),
          isEmpty);
    }
  });
}
