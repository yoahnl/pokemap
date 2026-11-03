import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_gen5_source_program_playback.dart';

Map<String, dynamic> _instruction(
  String op, [
  Map<String, dynamic> args = const {},
]) => {
  'op': op,
  'source': {'index': 0, 'line': 1, 'name': op, 'operands': <String>[]},
  'args': args,
};

Map<String, dynamic> _program(List<Map<String, dynamic>> instructions) => {
  'kind': 'gen5SourceProgram',
  'timebaseHz': 60,
  'source': {'path': 'tackle.s'},
  'variants': ['Tackle'],
  'labels': [
    {'name': 'Tackle', 'instructionIndex': 0, 'line': 1},
  ],
  'variant': 'Tackle',
  'entryIndex': 0,
  'conversion': 'supported',
  'instructions': instructions,
};

BattleGen5SourceProgramPlayback _playback(
  List<Map<String, dynamic>> instructions, {
  String? Function(BattleGen5SourceInstruction)? admit,
  BattleGen5SourceDispatchResult Function(BattleGen5SourceInstruction)?
  dispatch,
  bool Function(BattleGen5SourceTaskCategory)? isBusy,
  bool Function()? isParticleLoading,
  void Function(BattleGen5SourcePlaybackStatus)? onTerminated,
}) => BattleGen5SourceProgramPlayback(
  program: _program(instructions),
  variant: 'Tackle',
  admit: admit ?? (_) => null,
  dispatch: dispatch ?? (_) => BattleGen5SourceDispatchResult.completed,
  isBusy: isBusy ?? (_) => false,
  isParticleLoading: isParticleLoading ?? () => false,
  onTerminated: onTerminated,
);

void main() {
  test('cry wait conservatively follows current audio activity', () {
    var audioBusy = true;
    final trace = <String>[];
    final playback = _playback(
      [
        _instruction('playCry'),
        _instruction('waitTasks', {'what': 'CRY'}),
        _instruction('startEmitter'),
        _instruction('end'),
      ],
      isBusy: (category) =>
          category == BattleGen5SourceTaskCategory.audio && audioBusy,
      dispatch: (instruction) {
        trace.add(instruction.op);
        return BattleGen5SourceDispatchResult.completed;
      },
    );
    playback.tick();
    playback.tick();
    playback.tick();
    expect(trace, ['playCry']);
    audioBusy = false;
    playback.tick();
    playback.tick();
    expect(trace, ['playCry', 'startEmitter']);
  });

  test('player one audio wait conservatively follows current audio activity', () {
    var audioBusy = true;
    final trace = <String>[];
    final playback = _playback(
      [
        _instruction('waitTasks', {'what': 'SE_PLAYER_1'}),
        _instruction('startEmitter'),
        _instruction('end'),
      ],
      isBusy: (category) =>
          category == BattleGen5SourceTaskCategory.audio && audioBusy,
      dispatch: (instruction) {
        trace.add(instruction.op);
        return BattleGen5SourceDispatchResult.completed;
      },
    );
    playback.tick();
    playback.tick();
    expect(trace, isEmpty);
    audioBusy = false;
    playback.tick();
    playback.tick();
    expect(trace, ['startEmitter']);
  });

  test('stage and field fade wait resumes after the combined fade', () {
    final matching = BattleGen5SourceTaskCategory.values.where(
      (category) => category.name == 'stageFieldPalette',
    );
    expect(matching, hasLength(1));
    final stageFade = matching.single;
    var busy = true;
    final trace = <String>[];
    final playback = _playback(
      [
        _instruction('waitTasks', {'what': 'STAGE_FIELD_FADE'}),
        _instruction('startEmitter'),
        _instruction('end'),
      ],
      isBusy: (category) => category == stageFade && busy,
      dispatch: (instruction) {
        trace.add(instruction.op);
        return BattleGen5SourceDispatchResult.completed;
      },
    );
    playback.tick();
    playback.tick();
    expect(trace, isEmpty);
    busy = false;
    playback.tick();
    playback.tick();
    expect(trace, ['startEmitter']);
  });

  test('ALL waits for a background wave while BG only waits for movement', () {
    final waves = BattleGen5SourceTaskCategory.values.where(
      (category) => category.name == 'backgroundWave',
    );
    expect(waves, hasLength(1));
    final wave = waves.single;
    var waveBusy = true;
    final trace = <String>[];
    final playback = _playback(
      [
        _instruction('waveBackground'),
        _instruction('waitTasks', {'what': 'BG'}),
        _instruction('startEmitter'),
        _instruction('waitTasks', {'what': 'ALL'}),
        _instruction('startEmitter'),
        _instruction('end'),
      ],
      isBusy: (category) => category == wave && waveBusy,
      dispatch: (instruction) {
        trace.add(instruction.op);
        return BattleGen5SourceDispatchResult.completed;
      },
    );
    for (var i = 0; i < 6; i++) {
      playback.tick();
    }
    expect(trace, ['waveBackground', 'startEmitter']);
    waveBusy = false;
    playback.tick();
    playback.tick();
    expect(trace, ['waveBackground', 'startEmitter', 'startEmitter']);
  });

  test('BG waits for background motion independently of the camera', () {
    var backgroundBusy = true;
    final trace = <String>[];
    final playback = _playback(
      [
        _instruction('waitTasks', {'what': 'BG'}),
        _instruction('startEmitter'),
        _instruction('end'),
      ],
      isBusy: (category) =>
          category == BattleGen5SourceTaskCategory.background && backgroundBusy,
      dispatch: (instruction) {
        trace.add(instruction.op);
        return BattleGen5SourceDispatchResult.completed;
      },
    );
    playback.tick();
    playback.tick();
    expect(trace, isEmpty);
    backgroundBusy = false;
    playback.tick();
    playback.tick();
    expect(trace, ['startEmitter']);
  });

  test('yield begins enabled and FALSE batches until TRUE', () {
    var call = 0;
    final trace = <String>[];
    final playback = _playback(
      [
        _instruction('moveCameraPreset'),
        _instruction('setYield', {'value': false}),
        _instruction('startEmitter'),
        _instruction('startEmitter'),
        _instruction('setYield', {'value': true}),
        _instruction('startEmitter'),
        _instruction('end'),
      ],
      dispatch: (instruction) {
        trace.add('$call:${instruction.op}');
        return BattleGen5SourceDispatchResult.completed;
      },
    );
    for (call = 0; call < 4; call++) {
      playback.tick();
    }
    expect(trace, [
      '0:moveCameraPreset',
      '1:startEmitter',
      '1:startEmitter',
      '2:startEmitter',
    ]);
    expect(playback.status, BattleGen5SourcePlaybackStatus.finished);
  });

  for (final entry in [(frames: 0, nextCall: 2), (frames: 2, nextCall: 3)]) {
    test('waitFrames ${entry.frames} resumes on call ${entry.nextCall}', () {
      var call = 0;
      final trace = <int>[];
      final playback = _playback(
        [
          _instruction('waitFrames', {'frames': entry.frames}),
          _instruction('startEmitter'),
          _instruction('end'),
        ],
        dispatch: (_) {
          trace.add(call);
          return BattleGen5SourceDispatchResult.completed;
        },
      );
      for (call = 0; call <= entry.nextCall; call++) {
        playback.tick();
      }
      expect(trace, [entry.nextCall]);
    });
  }

  test(
    'PARTICLES ignores camera and audio while ALL waits for camera only',
    () {
      var particleBusy = true;
      var cameraBusy = true;
      final queried = <BattleGen5SourceTaskCategory>[];
      final trace = <String>[];
      final playback = _playback(
        [
          _instruction('waitTasks', {'what': 'PARTICLES'}),
          _instruction('startEmitter'),
          _instruction('waitTasks', {'what': 'ALL'}),
          _instruction('startEmitter'),
          _instruction('end'),
        ],
        isBusy: (category) {
          queried.add(category);
          return switch (category) {
            BattleGen5SourceTaskCategory.particles => particleBusy,
            BattleGen5SourceTaskCategory.camera => cameraBusy,
            BattleGen5SourceTaskCategory.audio => true,
            _ => false,
          };
        },
        dispatch: (instruction) {
          trace.add(instruction.op);
          return BattleGen5SourceDispatchResult.completed;
        },
      );
      playback.tick();
      playback.tick();
      expect(trace, isEmpty);
      expect(queried, [BattleGen5SourceTaskCategory.particles]);
      particleBusy = false;
      playback.tick();
      expect(trace, isEmpty);
      playback.tick();
      expect(trace, ['startEmitter']);
      playback.tick();
      playback.tick();
      expect(trace, ['startEmitter']);
      cameraBusy = false;
      playback.tick();
      expect(trace, ['startEmitter']);
      playback.tick();
      expect(trace, ['startEmitter', 'startEmitter']);
      expect(queried, isNot(contains(BattleGen5SourceTaskCategory.audio)));
    },
  );

  for (final pending in [false, true]) {
    test('loadParticle preserves yield with pending callback $pending', () {
      var loading = pending;
      var call = 0;
      final trace = <String>[];
      final playback = _playback(
        [
          _instruction('setYield', {'value': false}),
          _instruction('loadParticle', {'particle': 199}),
          _instruction('startEmitter'),
          _instruction('startEmitter'),
          _instruction('setYield', {'value': true}),
          _instruction('end'),
        ],
        isParticleLoading: () => loading,
        dispatch: (instruction) {
          trace.add('$call:${instruction.op}');
          return instruction.op == 'loadParticle' && pending
              ? BattleGen5SourceDispatchResult.particleLoadPending
              : BattleGen5SourceDispatchResult.completed;
        },
      );
      playback.tick();
      expect(trace, ['0:loadParticle']);
      call++;
      playback.tick();
      if (pending) {
        expect(trace, ['0:loadParticle']);
        loading = false;
        call++;
        playback.tick();
        expect(trace, ['0:loadParticle']);
        call++;
        playback.tick();
      }
      expect(trace, [
        '0:loadParticle',
        '$call:startEmitter',
        '$call:startEmitter',
      ]);
    });
  }

  test(
    'preflight rejects a later unsupported operation before any dispatch',
    () {
      final dispatched = <String>[];
      expect(
        () => _playback(
          [
            _instruction('startEmitter'),
            _instruction('moveCombatant', {'type': 99}),
            _instruction('end'),
          ],
          admit: (instruction) =>
              instruction.op == 'moveCombatant' ? 'mode unavailable' : null,
          dispatch: (instruction) {
            dispatched.add(instruction.op);
            return BattleGen5SourceDispatchResult.completed;
          },
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('mode unavailable'),
          ),
        ),
      );
      expect(dispatched, isEmpty);
    },
  );

  test(
    'preflight rejects unsupported conversion, wrong variant and no end',
    () {
      BattleGen5SourceProgramPlayback build(
        Map<String, dynamic> program,
        String variant,
      ) => BattleGen5SourceProgramPlayback(
        program: program,
        variant: variant,
        admit: (_) => null,
        dispatch: (_) => BattleGen5SourceDispatchResult.completed,
        isBusy: (_) => false,
        isParticleLoading: () => false,
      );
      final unsupported = _program([_instruction('end')])
        ..['conversion'] = 'unsupported';
      expect(() => build(unsupported, 'Tackle'), throwsFormatException);
      expect(
        () => build(_program([_instruction('end')]), 'Surf'),
        throwsFormatException,
      );
      expect(
        () => build(_program([_instruction('startEmitter')]), 'Tackle'),
        throwsFormatException,
      );
      expect(
        () => build(
          _program([_instruction('unsupported'), _instruction('end')]),
          'Tackle',
        ),
        throwsFormatException,
      );
    },
  );

  for (final wait in [
    _instruction('waitFrames', {'frames': 0}),
    _instruction('waitTasks', {'what': 'PARTICLES'}),
  ]) {
    test('${wait['op']} restores one instruction per call', () {
      var call = 0;
      final trace = <int>[];
      final playback = _playback(
        [
          _instruction('setYield', {'value': false}),
          wait,
          _instruction('startEmitter'),
          _instruction('startEmitter'),
          _instruction('end'),
        ],
        dispatch: (_) {
          trace.add(call);
          return BattleGen5SourceDispatchResult.completed;
        },
      );
      for (call = 0; call < 4; call++) {
        playback.tick();
      }
      expect(trace, [2, 3]);
    });
  }

  test('preflight admits particle loads and rejects unavailable resources', () {
    final admitted = <String>[];
    final dispatched = <String>[];
    expect(
      () => _playback(
        [
          _instruction('startEmitter'),
          _instruction('loadParticle', {'particle': 199}),
          _instruction('end'),
        ],
        admit: (instruction) {
          admitted.add(instruction.op);
          return instruction.op == 'loadParticle'
              ? 'missing particle 199'
              : null;
        },
        dispatch: (instruction) {
          dispatched.add(instruction.op);
          return BattleGen5SourceDispatchResult.completed;
        },
      ),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('missing particle 199'),
        ),
      ),
    );
    expect(admitted, ['startEmitter', 'loadParticle']);
    expect(dispatched, isEmpty);
  });

  test('animation pause admits only integer modes zero and one', () {
    for (final mode in [0, 1]) {
      final trace = <int>[];
      final playback = _playback(
        [
          _instruction('setAnimationState', {'mode': mode}),
          _instruction('end'),
        ],
        dispatch: (instruction) {
          trace.add(instruction.args['mode'] as int);
          return BattleGen5SourceDispatchResult.completed;
        },
      );
      playback.tick();
      expect(trace, [mode]);
    }
    for (final mode in [2, 3, -1, 1.0, '1']) {
      expect(
        () => _playback([
          _instruction('setAnimationState', {'mode': mode}),
          _instruction('end'),
        ]),
        throwsFormatException,
      );
    }
  });

  test('SE barrier observes audio instead of camera or particles', () {
    var audioBusy = true;
    final queries = <BattleGen5SourceTaskCategory>[];
    var dispatched = 0;
    final playback = _playback(
      [
        _instruction('waitTasks', {'what': 'SE'}),
        _instruction('startEmitter'),
        _instruction('end'),
      ],
      isBusy: (category) {
        queries.add(category);
        return category == BattleGen5SourceTaskCategory.audio && audioBusy;
      },
      dispatch: (_) {
        dispatched++;
        return BattleGen5SourceDispatchResult.completed;
      },
    );
    playback.tick();
    playback.tick();
    audioBusy = false;
    playback.tick();
    expect(dispatched, 0);
    playback.tick();
    expect(dispatched, 1);
    expect(queries, everyElement(BattleGen5SourceTaskCategory.audio));
  });

  test('a dispatch failure terminates once and reports the error', () {
    final outcomes = <BattleGen5SourcePlaybackStatus>[];
    final playback = _playback(
      [_instruction('startEmitter'), _instruction('end')],
      dispatch: (_) => throw StateError('texture unavailable'),
      onTerminated: outcomes.add,
    );
    playback.tick();
    playback.tick();
    playback.cancel();
    expect(playback.status, BattleGen5SourcePlaybackStatus.failed);
    expect(playback.diagnostic, contains('texture unavailable'));
    expect(outcomes, [BattleGen5SourcePlaybackStatus.failed]);
  });

  test('preflight rejects an oversized synchronous call before dispatch', () {
    var dispatched = 0;
    expect(
      () => _playback(
        [
          _instruction('setYield', {'value': false}),
          for (var i = 0; i < 255; i++) _instruction('startEmitter'),
          _instruction('setYield', {'value': true}),
          _instruction('end'),
        ],
        dispatch: (_) {
          dispatched++;
          return BattleGen5SourceDispatchResult.completed;
        },
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('256'),
        ),
      ),
    );
    expect(dispatched, 0);
  });

  test('preflight admits a 256-instruction synchronous call', () {
    var dispatched = 0;
    final playback = _playback(
      [
        _instruction('setYield', {'value': false}),
        for (var i = 0; i < 254; i++) _instruction('startEmitter'),
        _instruction('setYield', {'value': true}),
        _instruction('end'),
      ],
      dispatch: (_) {
        dispatched++;
        return BattleGen5SourceDispatchResult.completed;
      },
    );
    playback.tick();
    expect(dispatched, 254);
    playback.tick();
    expect(playback.status, BattleGen5SourcePlaybackStatus.finished);
  });

  test('particle loading ends the call without resetting the yield flag', () {
    var dispatched = 0;
    final playback = _playback(
      [
        _instruction('setYield', {'value': false}),
        for (var i = 0; i < 254; i++) _instruction('startEmitter'),
        _instruction('loadParticle', {'particle': 199}),
        for (var i = 0; i < 254; i++) _instruction('startEmitter'),
        _instruction('setYield', {'value': true}),
        _instruction('end'),
      ],
      dispatch: (_) {
        dispatched++;
        return BattleGen5SourceDispatchResult.completed;
      },
    );
    playback.tick();
    expect(dispatched, 255);
    playback.tick();
    expect(dispatched, 509);
    playback.tick();
    expect(playback.status, BattleGen5SourcePlaybackStatus.finished);
  });

  test('a variant cannot reach an end in the following variant', () {
    final program =
        _program([
            _instruction('startEmitter'),
            _instruction('startEmitter'),
            _instruction('end'),
          ])
          ..['variants'] = ['A', 'B']
          ..['labels'] = [
            {'name': 'A', 'instructionIndex': 0, 'line': 1},
            {'name': 'B', 'instructionIndex': 1, 'line': 3},
          ]
          ..['variant'] = 'A'
          ..['entryIndex'] = 0;
    var dispatched = 0;
    expect(
      () => BattleGen5SourceProgramPlayback(
        program: program,
        variant: 'A',
        admit: (_) => null,
        dispatch: (_) {
          dispatched++;
          return BattleGen5SourceDispatchResult.completed;
        },
        isBusy: (_) => false,
        isParticleLoading: () => false,
      ),
      throwsFormatException,
    );
    expect(dispatched, 0);
  });

  test('internal labels do not end a variant or dictate declaration order', () {
    final program =
        _program([
            _instruction('moveCameraPreset'),
            _instruction('end'),
            _instruction('startEmitter'),
            _instruction('end'),
          ])
          ..['variants'] = ['B', 'A']
          ..['labels'] = [
            {'name': 'A', 'instructionIndex': 0, 'line': 1},
            {'name': 'alias', 'instructionIndex': 0, 'line': 2},
            {'name': 'inner', 'instructionIndex': 1, 'line': 3},
            {'name': 'B', 'instructionIndex': 2, 'line': 5},
          ]
          ..['variant'] = 'A'
          ..['entryIndex'] = 0;
    final admitted = <String>[];
    final dispatched = <String>[];
    BattleGen5SourceProgramPlayback build(String variant) =>
        BattleGen5SourceProgramPlayback(
          program: program,
          variant: variant,
          admit: (instruction) {
            admitted.add(instruction.op);
            return null;
          },
          dispatch: (instruction) {
            dispatched.add(instruction.op);
            return BattleGen5SourceDispatchResult.completed;
          },
          isBusy: (_) => false,
          isParticleLoading: () => false,
        );
    final first = build('A');
    first.tick();
    first.tick();
    expect(first.status, BattleGen5SourcePlaybackStatus.finished);
    expect(admitted, ['moveCameraPreset']);
    expect(dispatched, ['moveCameraPreset']);
    admitted.clear();
    dispatched.clear();
    program['variant'] = 'B';
    program['entryIndex'] = 2;
    final second = build('B');
    second.tick();
    second.tick();
    expect(second.status, BattleGen5SourcePlaybackStatus.finished);
    expect(admitted, ['startEmitter']);
    expect(dispatched, ['startEmitter']);
  });

  test(
    'selected instructions are immutable and scoped to the admitted variant',
    () {
      final leftArgs = <String, dynamic>{
        'particle': 199,
        'meta': {
          'values': [1, 2],
        },
      };
      final instructions = [
        _instruction('startEmitter', leftArgs),
        _instruction('end'),
        _instruction('startEmitter', {'particle': 999}),
        _instruction('startEmitter', {'particle': 222}),
        _instruction('end'),
      ];
      final program = _program(instructions)
        ..['variants'] = ['A', 'B']
        ..['labels'] = [
          {'name': 'A', 'instructionIndex': 0, 'line': 1},
          {'name': 'internal', 'instructionIndex': 1, 'line': 2},
          {'name': 'B', 'instructionIndex': 3, 'line': 4},
        ]
        ..['variant'] = 'A'
        ..['entryIndex'] = 0;
      final admitted = <BattleGen5SourceInstruction>[];
      final dispatched = <BattleGen5SourceInstruction>[];
      BattleGen5SourceProgramPlayback build(String variant) =>
          BattleGen5SourceProgramPlayback(
            program: program,
            variant: variant,
            admit: (instruction) {
              admitted.add(instruction);
              return null;
            },
            dispatch: (instruction) {
              dispatched.add(instruction);
              return BattleGen5SourceDispatchResult.completed;
            },
            isBusy: (_) => false,
            isParticleLoading: () => false,
          );
      final first = build('A');
      expect(first.selectedInstructions.map((item) => item.op), [
        'startEmitter',
        'end',
      ]);
      expect(first.selectedInstructions.first, same(admitted.single));
      program['variant'] = 'B';
      program['entryIndex'] = 3;
      admitted.clear();
      final second = build('B');
      expect(second.selectedInstructions.map((item) => item.op), [
        'startEmitter',
        'end',
      ]);
      expect(second.selectedInstructions.first.args['particle'], 222);
      expect(second.selectedInstructions.first, same(admitted.single));
      leftArgs['particle'] = 123;
      (leftArgs['meta'] as Map)['values'] = [9];
      instructions[0]['op'] = 'playSound';
      expect(first.selectedInstructions.first.args['particle'], 199);
      expect(
        ((first.selectedInstructions.first.args['meta'] as Map)['values']
            as List),
        [1, 2],
      );
      expect(first.selectedInstructions.first.op, 'startEmitter');
      expect(
        () => first.selectedInstructions.add(first.selectedInstructions.first),
        throwsUnsupportedError,
      );
      expect(
        () => first.selectedInstructions.first.args['particle'] = 2,
        throwsUnsupportedError,
      );
      expect(
        () =>
            ((first.selectedInstructions.first.args['meta'] as Map)['values']
                    as List)
                .add(3),
        throwsUnsupportedError,
      );
      expect(
        () => (first.selectedInstructions.first.source['operands'] as List).add(
          'extra',
        ),
        throwsUnsupportedError,
      );
      first.tick();
      second.tick();
      expect(dispatched[0], same(first.selectedInstructions.first));
      expect(dispatched[1], same(second.selectedInstructions.first));
    },
  );

  test(
    'preflight rejects duplicate, unordered or inconsistent variant labels',
    () {
      Map<String, dynamic> validProgram() =>
          _program([
              _instruction('startEmitter'),
              _instruction('end'),
              _instruction('startEmitter'),
              _instruction('end'),
            ])
            ..['variants'] = ['A', 'B']
            ..['labels'] = [
              {'name': 'A', 'instructionIndex': 0, 'line': 1},
              {'name': 'inner', 'instructionIndex': 1, 'line': 2},
              {'name': 'B', 'instructionIndex': 2, 'line': 3},
            ]
            ..['variant'] = 'A'
            ..['entryIndex'] = 0;
      final invalid = <Map<String, dynamic>>[
        validProgram()..['variants'] = ['A', 'A'],
        validProgram()
          ..['labels'] = [
            {'name': 'A', 'instructionIndex': 0},
            {'name': 'A', 'instructionIndex': 1},
            {'name': 'B', 'instructionIndex': 2},
          ],
        validProgram()
          ..['labels'] = [
            {'name': 'A', 'instructionIndex': 0},
            {'name': 'inner', 'instructionIndex': 3},
            {'name': 'B', 'instructionIndex': 2},
          ],
        validProgram()
          ..['labels'] = [
            {'name': 'A', 'instructionIndex': 0},
            {'name': 'B', 'instructionIndex': 0},
          ],
        validProgram()
          ..['labels'] = [
            {'name': 'A', 'instructionIndex': 0},
            {'name': 'inner', 'instructionIndex': 1},
          ],
        validProgram()..['entryIndex'] = 1,
        validProgram()
          ..['labels'] = [
            {'name': 'A', 'instructionIndex': 0},
            {'name': 'B', 'instructionIndex': 4},
          ],
      ];
      var dispatched = 0;
      for (final program in invalid) {
        expect(
          () => BattleGen5SourceProgramPlayback(
            program: program,
            variant: 'A',
            admit: (_) => null,
            dispatch: (_) {
              dispatched++;
              return BattleGen5SourceDispatchResult.completed;
            },
            isBusy: (_) => false,
            isParticleLoading: () => false,
          ),
          throwsFormatException,
        );
      }
      expect(dispatched, 0);
    },
  );

  test('cyclic maps and lists are rejected before admission or dispatch', () {
    void expectRejected(Map<String, dynamic> program) {
      var admitted = 0;
      var dispatched = 0;
      expect(
        () => BattleGen5SourceProgramPlayback(
          program: program,
          variant: 'Tackle',
          admit: (_) {
            admitted++;
            return null;
          },
          dispatch: (_) {
            dispatched++;
            return BattleGen5SourceDispatchResult.completed;
          },
          isBusy: (_) => false,
          isParticleLoading: () => false,
        ),
        throwsFormatException,
      );
      expect(admitted, 0);
      expect(dispatched, 0);
    }

    final cyclicMap = <String, dynamic>{};
    cyclicMap['self'] = cyclicMap;
    expectRejected(
      _program([_instruction('startEmitter', cyclicMap), _instruction('end')]),
    );
    final cyclicList = <Object?>[];
    cyclicList.add(cyclicList);
    expectRejected(
      _program([
        _instruction('startEmitter', {'cycle': cyclicList}),
        _instruction('end'),
      ]),
    );
    final cyclicProgram = _program([_instruction('end')]);
    cyclicProgram['self'] = cyclicProgram;
    expectRejected(cyclicProgram);
  });

  test('shared acyclic references remain accepted and deeply immutable', () {
    final shared = <String, dynamic>{
      'numbers': [1, 2],
    };
    final seen = <String>[];
    final playback = _playback(
      [
        _instruction('startEmitter', {'left': shared, 'right': shared}),
        _instruction('end'),
      ],
      dispatch: (instruction) {
        final left = instruction.args['left'] as Map;
        final numbers = left['numbers'] as List;
        expect(() => left['new'] = 3, throwsUnsupportedError);
        expect(() => numbers.add(3), throwsUnsupportedError);
        seen.add(instruction.op);
        return BattleGen5SourceDispatchResult.completed;
      },
    );
    shared['numbers'] = [9];
    playback.tick();
    expect(seen, ['startEmitter']);
  });

  test('preflight bounds program depth, breadth and string sizes globally', () {
    var admitted = 0;
    var dispatched = 0;
    void expectRejected(Map<String, dynamic> program) {
      expect(
        () => BattleGen5SourceProgramPlayback(
          program: program,
          variant: 'Tackle',
          admit: (_) {
            admitted++;
            return null;
          },
          dispatch: (_) {
            dispatched++;
            return BattleGen5SourceDispatchResult.completed;
          },
          isBusy: (_) => false,
          isParticleLoading: () => false,
        ),
        throwsFormatException,
      );
    }

    Object nested = 0;
    for (var i = 0; i < 20; i++) {
      nested = [nested];
    }
    expectRejected(
      _program([
        _instruction('startEmitter', {'nested': nested}),
        _instruction('end'),
      ]),
    );
    expectRejected(
      _program([
        _instruction('startEmitter', {'many': List<int>.filled(4097, 0)}),
        _instruction('end'),
      ]),
    );
    expectRejected(
      _program([
        _instruction('startEmitter', {'long': 'x' * 4097}),
        _instruction('end'),
      ]),
    );
    expectRejected(
      _program([
        _instruction('startEmitter', {
          'strings': List<String>.filled(300, 'x' * 1024),
        }),
        _instruction('end'),
      ]),
    );
    expectRejected(
      _program([
        for (var i = 0; i < 340; i++)
          _instruction('startEmitter', {'values': List<int>.filled(200, 0)}),
        _instruction('end'),
      ]),
    );
    expect(admitted, 0);
    expect(dispatched, 0);
  });

  test('cancellation during an unresolved barrier settles once', () {
    final outcomes = <BattleGen5SourcePlaybackStatus>[];
    var calls = 0;
    final playback = _playback(
      [
        _instruction('waitTasks', {'what': 'PARTICLES'}),
        _instruction('startEmitter'),
        _instruction('end'),
      ],
      isBusy: (_) => true,
      dispatch: (_) {
        calls++;
        return BattleGen5SourceDispatchResult.completed;
      },
      onTerminated: outcomes.add,
    );
    playback.tick();
    playback.tick();
    playback.cancel();
    playback.cancel();
    playback.tick();
    expect(calls, 0);
    expect(outcomes, [BattleGen5SourcePlaybackStatus.cancelled]);
    expect(playback.status, BattleGen5SourcePlaybackStatus.cancelled);
  });
}
