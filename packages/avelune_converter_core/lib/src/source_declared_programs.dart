part of '../avelune_converter_core.dart';

enum SourceDeclaredProgramFamily {
  centerNurse,
  centerPc,
  partyTrade,
  pokedexReward,
  healingDisplay,
  externalWarp,
  elevator,
  hole,
  warpTile,
}

final class SourceDeclaredProgramBinding {
  SourceDeclaredProgramBinding._(
      this.id, this.family, this.pages, this.parameters);
  factory SourceDeclaredProgramBinding.fromJson(Object? input) {
    final json = _interpretationObject(input);
    _interpretationKeys(json, const {'id', 'family', 'pages', 'parameters'});
    final family = SourceDeclaredProgramFamily.values
        .where((f) => f.name == json['family'])
        .singleOrNull;
    _require(family != null, 'declared_program.family', r'$',
        'Unknown declared program family.');
    final pages = _interpretationObject(json['pages']);
    _require(pages.isNotEmpty && pages.length <= 16, 'declared_program.pages',
        r'$', 'Declared programs require bounded complete pages.');
    final allowedRoles = switch (family!) {
      SourceDeclaredProgramFamily.centerNurse => const {'choice', 'recovery'},
      SourceDeclaredProgramFamily.centerPc => const {'activation', 'open'},
      SourceDeclaredProgramFamily.partyTrade => const {'program'},
      SourceDeclaredProgramFamily.pokedexReward => const {
          'offer',
          'afterReward'
        },
      SourceDeclaredProgramFamily.healingDisplay => const {
          'count0',
          'count1',
          'count2',
          'count3',
          'count4',
          'count5',
          'count6'
        },
      SourceDeclaredProgramFamily.externalWarp => const {'program', 'arrival'},
      SourceDeclaredProgramFamily.hole => const {'program'},
      _ => pages.keys.toSet(),
    };
    _require(
        pages.keys.every((role) =>
                RegExp(r'^[A-Za-z][A-Za-z0-9_]{0,63}$').hasMatch(role) &&
                allowedRoles.contains(role)) &&
            (family == SourceDeclaredProgramFamily.externalWarp
                ? pages.containsKey('program')
                : pages.length == allowedRoles.length),
        'declared_program.pages',
        r'$',
        'The declared family requires its complete semantic page roles.');
    final parameters = _interpretationObject(json['parameters']);
    final keys = switch (family) {
      SourceDeclaredProgramFamily.centerNurse => const {
          'textGroups',
          'choiceCommandIndex',
          'recoveryMusicCommandIndices',
          'recoveryWaitCommandIndices'
        },
      SourceDeclaredProgramFamily.centerPc ||
      SourceDeclaredProgramFamily.healingDisplay ||
      SourceDeclaredProgramFamily.hole =>
        const <String>{},
      SourceDeclaredProgramFamily.partyTrade => const {
          'greetingCommandIndices',
          'refusalCommandIndex',
          'facingCommandIndex',
          'choiceCommandIndex'
        },
      SourceDeclaredProgramFamily.pokedexReward => const {
          'textGroups',
          'choiceCommandIndex',
          'seenCommandIndex',
          'ownedCommandIndex',
          'thresholdCommandIndex',
          'rewardCommandIndex'
        },
      SourceDeclaredProgramFamily.externalWarp => const {'presentation'},
      SourceDeclaredProgramFamily.elevator => const {
          'role',
          'familyId',
          'maximumFloor',
          'floor'
        },
      SourceDeclaredProgramFamily.warpTile => const {
          'role',
          'targetRole',
          'repairOriginalTarget'
        },
    };
    _interpretationKeys(parameters, keys);
    final frozenPages = <String, Map<String, Object?>>{};
    final shapes = <String>{};
    for (final entry in pages.entries) {
      final page = _interpretationObject(entry.value);
      _validateDeclaredPage(page, family, entry.key);
      _require(shapes.add(canonicalJsonOf(page)), 'declared_program.ambiguous',
          r'$', 'Semantic page roles must have distinct complete structures.');
      frozenPages[entry.key] = _freezeDeclared(page) as Map<String, Object?>;
    }
    final binding = SourceDeclaredProgramBinding._(
        ConverterId(_interpretationString(json['id'])),
        family,
        Map.unmodifiable(frozenPages),
        _freezeDeclared(parameters) as Map<String, Object?>);
    binding._validateParameters();
    return binding;
  }
  final ConverterId id;
  final SourceDeclaredProgramFamily family;
  final Map<String, Map<String, Object?>> pages;
  late final Map<String, String> _canonicalPages = {
    for (final entry in pages.entries) entry.key: canonicalJsonOf(entry.value)
  };
  final Map<String, Object?> parameters;
  Map<String, Object?> toJson() => {
        'id': id.value,
        'family': family.name,
        'pages': pages,
        'parameters': parameters
      };
  late final Sha256Hash canonicalHash =
      canonicalHashOf(toJson(), limits: SourceInterpretationProfile.jsonLimits);

  void _validateParameters() {
    Map<String, Object?> command(String role, Object? index, Set<int> codes) {
      final list = pages[role]!['list'] as List;
      _require(
          index is int &&
              index >= 0 &&
              index < list.length &&
              codes.contains((list[index] as Map)['code']),
          'declared_program.parameters',
          r'$',
          'A semantic binding must reference a compatible typed command.');
      return Map<String, Object?>.from(list[index as int] as Map);
    }

    void texts(Object? input, String role, {bool allowEmpty = false}) {
      _require(
          input is List &&
              input.length <= 32 &&
              (allowEmpty || input.isNotEmpty),
          'declared_program.parameters',
          r'$',
          'Text bindings require bounded command indices.');
      for (final index in input as List) {
        command(role, index, const {101});
      }
    }

    void groups() {
      final roles = _interpretationObject(parameters['textGroups']);
      _require(
          roles.length == pages.length && roles.keys.every(pages.containsKey),
          'declared_program.parameters',
          r'$',
          'Text groups require the exact declared page roles.');
      for (final role in roles.entries) {
        final groups = _interpretationObject(role.value);
        final allowed = family == SourceDeclaredProgramFamily.centerNurse
            ? const {'greeting', 'acceptance', 'completion', 'refusal'}
            : const {
                'greeting',
                'eligible',
                'explanation',
                'insufficient',
                'refused'
              };
        _interpretationKeys(groups, allowed);
        final expected = family == SourceDeclaredProgramFamily.centerNurse
            ? const {'greeting', 'acceptance', 'completion', 'refusal'}
            : role.key == 'offer'
                ? const {
                    'greeting',
                    'eligible',
                    'explanation',
                    'insufficient',
                    'refused'
                  }
                : const {'explanation'};
        _require(
            groups.keys.toSet().containsAll(expected) &&
                groups.length == expected.length,
            'declared_program.parameters',
            r'$',
            'Every interpreted role requires all of its semantic text groups.');
        for (final entry in groups.entries) {
          texts(entry.value, role.key,
              allowEmpty: family == SourceDeclaredProgramFamily.centerNurse &&
                  role.key == 'recovery' &&
                  const {'acceptance', 'refusal'}.contains(entry.key));
        }
      }
    }

    void pageGuard(String role, int trigger, Set<String> flags) {
      final page = pages[role]!, condition = page['condition'] as Map;
      _require(
          page['trigger'] == trigger &&
              const [
                'switch1_valid',
                'switch2_valid',
                'variable_valid',
                'self_switch_valid'
              ].every((f) => condition[f] == flags.contains(f)),
          'declared_program.guard',
          r'$',
          'A declared semantic role requires its complete supported activation guard.');
    }

    if (family == SourceDeclaredProgramFamily.centerNurse) {
      pageGuard('choice', 0, const {});
      pageGuard('recovery', 3, const {'switch1_valid'});
      final id = (pages['recovery']!['condition'] as Map)['switch1_id'];
      final resets = (pages['recovery']!['list'] as List).cast<Map>().where(
          (c) =>
              c['code'] == 121 &&
              canonicalJsonOf(c['parameters']) == canonicalJsonOf([id, id, 1]));
      _require(resets.length == 1, 'declared_program.guard', r'$',
          'Recovery must clear its own exact activation switch.');
    }
    if (family == SourceDeclaredProgramFamily.centerPc) {
      pageGuard('activation', 0, const {});
      pageGuard('open', 3, const {'self_switch_valid'});
      final letter = (pages['open']!['condition'] as Map)['self_switch_ch'];
      final activation = (pages['activation']!['list'] as List)
          .cast<Map>()
          .where((command) => !const {108, 408, 401}.contains(command['code']))
          .toList();
      if (activation.first['code'] == 111) {
        final condition = activation.first['parameters'] as List;
        _require(
            activation
                        .map((command) =>
                            '${command['code']}:${command['indent']}')
                        .join(',') ==
                    '111:0,123:1,0:1,411:0,101:1,0:1,412:0,0:0' &&
                condition.length == 3 &&
                condition[0] == 0 &&
                condition[1] is int &&
                (condition[1] as int) > 0 &&
                condition[2] == 0,
            'declared_program.pc_availability',
            r'$',
            'A conditional PC must preserve its switch, activation and complete denial branch.');
      }
      for (final role in const ['activation', 'open']) {
        final writes = (pages[role]!['list'] as List)
            .cast<Map>()
            .where((c) => c['code'] == 123)
            .toList();
        _require(
            writes.length == 1 &&
                canonicalJsonOf(writes.single['parameters']) ==
                    canonicalJsonOf([letter, role == 'activation' ? 0 : 1]),
            'declared_program.guard',
            r'$',
            'The PC cycle must arm and clear its own guarded self switch.');
      }
    }
    if (family == SourceDeclaredProgramFamily.partyTrade) {
      pageGuard('program', 0, const {});
    }
    if (family == SourceDeclaredProgramFamily.pokedexReward) {
      pageGuard('offer', 0, const {});
      pageGuard('afterReward', 0, const {'self_switch_valid'});
    }
    switch (family) {
      case SourceDeclaredProgramFamily.centerNurse:
        groups();
        command('choice', parameters['choiceCommandIndex'], const {102});
        for (final key in [
          'recoveryMusicCommandIndices',
          'recoveryWaitCommandIndices'
        ]) {
          final indices = _interpretationObject(parameters[key]);
          _require(
              indices.length == 2 && indices.keys.every(pages.containsKey),
              'declared_program.parameters',
              r'$',
              'Recovery bindings require both nurse programs.');
          for (final entry in indices.entries) {
            command(
                entry.key,
                entry.value,
                key == 'recoveryMusicCommandIndices'
                    ? const {249}
                    : const {106});
          }
        }
      case SourceDeclaredProgramFamily.partyTrade:
        texts(parameters['greetingCommandIndices'], 'program');
        command('program', parameters['refusalCommandIndex'], const {101});
        command('program', parameters['facingCommandIndex'], const {111});
        command('program', parameters['choiceCommandIndex'], const {102});
      case SourceDeclaredProgramFamily.pokedexReward:
        groups();
        command('offer', parameters['choiceCommandIndex'], const {102});
        command('offer', parameters['seenCommandIndex'], const {355});
        command('offer', parameters['ownedCommandIndex'], const {655});
        command('offer', parameters['thresholdCommandIndex'], const {111});
        command('offer', parameters['rewardCommandIndex'], const {111, 355});
      case SourceDeclaredProgramFamily.externalWarp:
        _require(
            const {'fade', 'illustrated', 'caveEntrance', 'caveExit'}
                .contains(parameters['presentation']),
            'declared_program.parameters',
            r'$',
            'Unknown external warp presentation.');
      case SourceDeclaredProgramFamily.elevator:
        _require(
            const {'door', 'exit', 'controller', 'actor'}
                    .contains(parameters['role']) &&
                parameters['familyId'] is String,
            'declared_program.parameters',
            r'$',
            'Elevator bindings require an explicit role and family.');
        ConverterId(parameters['familyId'] as String);
        for (final key in ['maximumFloor', 'floor']) {
          final n = parameters[key];
          _require(
              n == null || n is int && n > 0 && n <= 256,
              'declared_program.parameters',
              r'$',
              'Invalid bounded elevator floor.');
        }
      case SourceDeclaredProgramFamily.warpTile:
        _require(const {'tile', 'activation'}.contains(parameters['role']),
            'declared_program.parameters', r'$', 'Unknown warp tile role.');
        _require(
            parameters['targetRole'] == null ||
                parameters['targetRole'] is String,
            'declared_program.parameters',
            r'$',
            'Invalid declared target role.');
        _require(
            parameters['repairOriginalTarget'] == null ||
                parameters['repairOriginalTarget'] is int &&
                    (parameters['repairOriginalTarget'] as int) > 0,
            'declared_program.parameters',
            r'$',
            'Invalid explicit original target witness.');
      case SourceDeclaredProgramFamily.centerPc:
      case SourceDeclaredProgramFamily.healingDisplay:
      case SourceDeclaredProgramFamily.hole:
        break;
    }
  }
}

Object? _freezeDeclared(Object? value) => switch (value) {
      Map() => Map<String, Object?>.unmodifiable(
          value.map((k, v) => MapEntry(k as String, _freezeDeclared(v)))),
      List() => List<Object?>.unmodifiable(value.map(_freezeDeclared)),
      _ => value,
    };

const _declaredProgramOpcodeGrammars = <String, List<int>>{
  'centerNurse.choice': [
    355,
    102,
    402,
    355,
    314,
    209,
    509,
    509,
    210,
    122,
    122,
    118,
    122,
    250,
    106,
    111,
    119,
    412,
    209,
    509,
    249,
    106,
    122,
    355,
    209,
    509,
    209,
    509,
    509,
    210,
    111,
    121,
    411,
    209,
    509,
    509,
    509,
    210,
    412,
    402,
    404
  ],
  'centerNurse.recovery': [
    355,
    314,
    209,
    509,
    509,
    210,
    122,
    122,
    118,
    122,
    250,
    106,
    111,
    119,
    412,
    209,
    509,
    249,
    106,
    122,
    355,
    209,
    509,
    209,
    509,
    509,
    210,
    209,
    509,
    509,
    509,
    210,
    121
  ],
  'centerPc.activation': [123],
  'centerPc.open': [355, 123],
  'partyTrade.program': [
    111,
    102,
    402,
    355,
    102,
    402,
    355,
    355,
    655,
    655,
    402,
    355,
    655,
    404,
    402,
    404,
    412
  ],
  'pokedexReward.offer': [
    355,
    655,
    102,
    402,
    111,
    111,
    411,
    115,
    412,
    209,
    509,
    123,
    411,
    412,
    402,
    404,
    209,
    509
  ],
  'pokedexReward.afterReward': [209, 509]
};

void _validateDeclaredPage(Map<String, Object?> page,
    SourceDeclaredProgramFamily family, String role) {
  const fields = {
    '__class__',
    'condition',
    'graphic',
    'move_type',
    'move_speed',
    'move_frequency',
    'move_route',
    'walk_anime',
    'step_anime',
    'direction_fix',
    'through',
    'always_on_top',
    'trigger',
    'list'
  };
  _require(
      page.length == fields.length &&
          page.keys.every(fields.contains) &&
          page['__class__'] == 'RPG::Event::Page' &&
          page['trigger'] is int &&
          (page['trigger'] as int) >= 0 &&
          (page['trigger'] as int) <= 4 &&
          page['list'] is List,
      'declared_program.page_shape',
      r'$',
      'Declared pages require complete typed RMXP page fields.');
  void shape(Object? input) {
    if (input is Map) {
      final object = Map<String, Object?>.from(input);
      final type = object['__class__'];
      final keys = switch (type) {
        'RPG::Event::Page' => const {
            '__class__',
            'condition',
            'graphic',
            'move_type',
            'move_speed',
            'move_frequency',
            'move_route',
            'walk_anime',
            'step_anime',
            'direction_fix',
            'through',
            'always_on_top',
            'trigger',
            'list'
          },
        'RPG::Event::Page::Condition' => const {
            '__class__',
            'switch1_valid',
            'switch2_valid',
            'variable_valid',
            'self_switch_valid',
            'switch1_id',
            'switch2_id',
            'variable_id',
            'variable_value',
            'self_switch_ch'
          },
        'RPG::Event::Page::Graphic' => const {
            '__class__',
            'tile_id',
            'character_name',
            'character_hue',
            'direction',
            'pattern',
            'opacity',
            'blend_type'
          },
        'RPG::MoveRoute' => const {'__class__', 'list', 'repeat', 'skippable'},
        'RPG::MoveCommand' => const {'__class__', 'code', 'parameters'},
        'RPG::EventCommand' => const {
            '__class__',
            'code',
            'indent',
            'parameters'
          },
        'RPG::AudioFile' => const {'__class__', 'name', 'volume', 'pitch'},
        'Tone' => const {'__class__', 'marshalPayload'},
        _ => const <String>{},
      };
      _require(
          keys.isNotEmpty &&
              object.length == keys.length &&
              object.keys.every(keys.contains),
          'declared_program.raw_shape',
          r'$',
          'Declared program objects require complete recognized format fields.');
      bool integer(Object? value, int minimum, int maximum) =>
          value is int && value >= minimum && value <= maximum;
      void valid(bool value) => _require(value, 'declared_program.raw_shape',
          r'$', 'Declared format fields require bounded typed values.');
      if (type == 'RPG::Event::Page') {
        valid(integer(object['move_type'], 0, 3) &&
            integer(object['move_speed'], 1, 6) &&
            integer(object['move_frequency'], 1, 6));
        for (final flag in const [
          'walk_anime',
          'step_anime',
          'direction_fix',
          'through',
          'always_on_top'
        ]) {
          valid(object[flag] is bool);
        }
        valid(object['condition'] is Map &&
            (object['condition'] as Map)['__class__'] ==
                'RPG::Event::Page::Condition');
        valid(object['graphic'] is Map &&
            (object['graphic'] as Map)['__class__'] ==
                'RPG::Event::Page::Graphic');
        valid(object['move_route'] is Map &&
            (object['move_route'] as Map)['__class__'] == 'RPG::MoveRoute');
      }
      if (type == 'RPG::Event::Page::Condition') {
        for (final flag in const [
          'switch1_valid',
          'switch2_valid',
          'variable_valid',
          'self_switch_valid'
        ]) {
          valid(object[flag] is bool);
        }
        for (final id in const ['switch1_id', 'switch2_id', 'variable_id']) {
          valid(integer(object[id], 1, 2147483647));
        }
        valid(integer(object['variable_value'], -2147483648, 2147483647));
        valid(const {'A', 'B', 'C', 'D'}.contains(object['self_switch_ch']));
      }
      if (type == 'RPG::Event::Page::Graphic') {
        valid(integer(object['tile_id'], 0, 1000000));
        valid(object['character_name'] is String &&
            (object['character_name'] as String).length <= 512);
        valid(integer(object['character_hue'], 0, 360));
        valid(const {2, 4, 6, 8}.contains(object['direction']));
        valid(integer(object['pattern'], 0, 3));
        valid(integer(object['opacity'], 0, 255));
        valid(integer(object['blend_type'], 0, 2));
      }
      if (type == 'RPG::MoveRoute') {
        valid(object['repeat'] is bool &&
            object['skippable'] is bool &&
            object['list'] is List);
        final moves = object['list'] as List;
        valid(moves.isNotEmpty &&
            moves.length <= 256 &&
            moves.last is Map &&
            (moves.last as Map)['code'] == 0);
      }
      if (type == 'RPG::AudioFile') {
        valid(object['name'] is String &&
            (object['name'] as String).length <= 512);
        valid(integer(object['volume'], 0, 100) &&
            integer(object['pitch'], 50, 150));
      }
      if (type == 'RPG::EventCommand') {
        valid(integer(object['code'], 0, 999) &&
            integer(object['indent'], 0, 32) &&
            object['parameters'] is List &&
            (object['parameters'] as List).length <= 256);
      }
      if (type == 'RPG::MoveCommand') {
        _require(
            object['code'] is int &&
                (object['code'] as int) >= 0 &&
                (object['code'] as int) <= 44 &&
                object['parameters'] is List,
            'declared_program.route',
            r'$',
            'Unknown or scripted move-route commands cannot be declared as native operations.');
      }
      if (type == 'RPG::MoveCommand') {
        final code = object['code'] as int, args = object['parameters'] as List;
        final correct = switch (code) {
          14 => args.length == 2 && args.every((a) => integer(a, -1024, 1024)),
          15 => args.length == 1 && integer(args.single, 1, 1200),
          27 || 28 => args.length == 1 && integer(args.single, 1, 2147483647),
          29 || 30 => args.length == 1 && integer(args.single, 1, 6),
          41 => args.length == 4 &&
              args[0] is String &&
              integer(args[1], 0, 360) &&
              const {2, 4, 6, 8}.contains(args[2]) &&
              integer(args[3], 0, 3),
          42 => args.length == 1 && integer(args.single, 0, 255),
          43 => args.length == 1 && integer(args.single, 0, 2),
          44 => args.length == 1 &&
              args.single is Map &&
              (args.single as Map)['__class__'] == 'RPG::AudioFile',
          _ => args.isEmpty,
        };
        valid(correct);
      }
      if (type == 'Tone') {
        final payload = object['marshalPayload'];
        _require(
            payload is String && payload.length == 44,
            'declared_program.tone',
            r'$',
            'Tone witnesses require their exact bounded inert payload.');
        try {
          _require(
              base64Decode(payload as String).length == 32,
              'declared_program.tone',
              r'$',
              'Tone payload must contain four channels.');
        } on FormatException {
          throw ContractError(
              'declared_program.tone', r'$', 'Malformed inert Tone payload.');
        }
      }
      for (final value in object.values) {
        if (value is Map || value is List) shape(value);
      }
    } else if (input is List) {
      for (final item in input) {
        if (item is Map || item is List) shape(item);
      }
    }
  }

  shape(page);
  final list = page['list'] as List;
  _require(list.isNotEmpty && list.length <= 256, 'declared_program.commands',
      r'$', 'Declared command lists must be bounded and complete.');
  final allowed = switch (family) {
    SourceDeclaredProgramFamily.centerNurse => const {
        0,
        101,
        102,
        106,
        108,
        111,
        118,
        119,
        121,
        122,
        209,
        210,
        249,
        250,
        314,
        355,
        401,
        402,
        404,
        408,
        411,
        412,
        509
      },
    SourceDeclaredProgramFamily.centerPc => const {
        0,
        101,
        111,
        123,
        355,
        401,
        411,
        412
      },
    SourceDeclaredProgramFamily.partyTrade => const {
        0,
        101,
        102,
        111,
        355,
        401,
        402,
        404,
        412,
        655
      },
    SourceDeclaredProgramFamily.pokedexReward => const {
        0,
        101,
        102,
        111,
        115,
        123,
        209,
        355,
        401,
        402,
        404,
        411,
        412,
        509,
        655
      },
    SourceDeclaredProgramFamily.healingDisplay => const {0},
    SourceDeclaredProgramFamily.externalWarp => const {
        0,
        106,
        111,
        201,
        209,
        210,
        223,
        231,
        232,
        235,
        250,
        355,
        412,
        509
      },
    _ => null,
  };
  final grammar = family == SourceDeclaredProgramFamily.centerPc &&
          role == 'activation' &&
          list.any((command) => command is Map && command['code'] == 111)
      ? const [111, 123, 411, 412]
      : _declaredProgramOpcodeGrammars['${family.name}.$role'];
  if (grammar != null) {
    final opcodes = [
      for (final raw in list)
        if (raw is Map && !const {0, 101, 401, 108, 408}.contains(raw['code']))
          raw['code']
    ];
    _require(
        (canonicalJsonOf(opcodes) == canonicalJsonOf(grammar) ||
            family == SourceDeclaredProgramFamily.pokedexReward &&
                role == 'offer' &&
                canonicalJsonOf(opcodes) ==
                    canonicalJsonOf([
                      355,
                      655,
                      102,
                      402,
                      111,
                      111,
                      355,
                      412,
                      355,
                      209,
                      509,
                      123,
                      411,
                      412,
                      402,
                      404,
                      209,
                      509
                    ])),
        'declared_program.grammar',
        r'$',
        'Declared bindings require the complete supported typed control-flow grammar.');
  }
  final stack = <(int, int)>[];
  final locals = <String>{};
  for (var i = 0; i < list.length; i++) {
    final c = _interpretationObject(list[i]);
    _require(
        c.length == 4 &&
            c.keys.every(
                const {'__class__', 'code', 'indent', 'parameters'}.contains) &&
            c['__class__'] == 'RPG::EventCommand' &&
            c['code'] is int &&
            c['indent'] is int &&
            (c['indent'] as int) >= 0 &&
            (c['indent'] as int) <= 32 &&
            c['parameters'] is List &&
            (c['parameters'] as List).length <= 64 &&
            (allowed == null || allowed.contains(c['code'])),
        'declared_program.commands',
        r'$',
        'A declared program contains an unsupported or malformed command.');
    final code = c['code'] as int, indent = c['indent'] as int;
    final p = c['parameters'] as List;
    if (allowed != null) {
      bool scalar(bool ok) {
        _require(ok, 'declared_program.operand', r'$',
            'Declared operations require their complete typed operands.');
        return ok;
      }

      if (const {0, 210, 411, 412, 404, 115}.contains(code)) scalar(p.isEmpty);
      if (const {101, 401, 108, 408, 118, 119}.contains(code)) {
        scalar(p.length == 1 && p.single is String);
      }
      if (code == 106) {
        scalar(p.length == 1 &&
            p.single is int &&
            (p.single as int) >= 0 &&
            (p.single as int) <= 1200);
      }
      if (code == 121) {
        scalar(p.length == 3 &&
            p.every((v) => v is int) &&
            (p[0] as int) > 0 &&
            p[0] == p[1] &&
            const {0, 1}.contains(p[2]));
      }
      if (code == 122) {
        scalar(p.length == 5 &&
            p.every((v) => v is int) &&
            (p[0] as int) > 0 &&
            p[0] == p[1] &&
            const {0, 1}.contains(p[2]) &&
            const {0, 7}.contains(p[3]));
      }
      if (code == 123) {
        scalar(p.length == 2 &&
            const {'A', 'B', 'C', 'D'}.contains(p[0]) &&
            const {0, 1}.contains(p[1]));
      }
      if (code == 249 || code == 250) {
        scalar(p.length == 1 &&
            p.single is Map &&
            (p.single as Map)['__class__'] == 'RPG::AudioFile');
      }
      if (code == 402) {
        scalar(p.length == 2 &&
            p[0] is int &&
            (p[0] as int) >= 0 &&
            (p[0] as int) <= 1 &&
            p[1] is String);
      }
      if (code == 209) {
        scalar(p.length == 2 &&
            p[0] is int &&
            (p[0] as int) >= -1 &&
            p[1] is Map &&
            (p[1] as Map)['__class__'] == 'RPG::MoveRoute');
        final route = p[1] as Map, moves = route['list'] as List;
        scalar(route['repeat'] == false &&
            (family == SourceDeclaredProgramFamily.externalWarp ||
                route['skippable'] == false));
        final mirrors = <Object?>[];
        for (var j = i + 1;
            j < list.length && (list[j] as Map)['code'] == 509;
            j++) {
          final echo = list[j] as Map, args = echo['parameters'] as List;
          scalar(echo['indent'] == indent && args.length == 1);
          mirrors.add(args.single);
        }
        scalar(canonicalJsonOf(mirrors) ==
            canonicalJsonOf(moves.take(moves.length - 1).toList()));
      }
      if (code == 509) {
        scalar(
            i > 0 && const {209, 509}.contains((list[i - 1] as Map)['code']));
      }
    }
    if (code == 111 || code == 102) {
      stack.add((code, indent));
    }
    if (const {411, 412, 402, 404}.contains(code)) {
      final expected = code == 411 || code == 412 ? 111 : 102;
      _require(
          stack.isNotEmpty && stack.last == (expected, indent),
          'declared_program.control_flow',
          r'$',
          'Declared branches must be complete and unambiguous.');
      if (code == 412 || code == 404) stack.removeLast();
    }
    if (code == 355 || code == 655) {
      _require(
          p.length == 1 &&
              p.single is String &&
              (code != 655 ||
                  i > 0 &&
                      const {355, 655}
                          .contains((list[i - 1] as Map)['code'])) &&
              (allowed == null ||
                  _declaredScriptAllowed(family, p.single as String, locals)),
          'declared_program.script',
          r'$',
          'Unknown Ruby cannot be promoted by a declared program binding.');
    }
    if (code == 111) {
      _require(p.isNotEmpty && p.first is int, 'declared_program.condition',
          r'$', 'Declared conditions require a typed operand.');
      if (allowed != null) {
        final kinds = switch (family) {
          SourceDeclaredProgramFamily.centerPc => const {0},
          SourceDeclaredProgramFamily.centerNurse ||
          SourceDeclaredProgramFamily.pokedexReward =>
            const {1, 12},
          SourceDeclaredProgramFamily.partyTrade => const {6},
          SourceDeclaredProgramFamily.externalWarp => const {12},
          _ => const <int>{},
        };
        _require(kinds.contains(p.first), 'declared_program.condition', r'$',
            'Unsupported condition operand in the declared native family.');
        if (p.first == 1) {
          _require(
              p.length == 5 &&
                  p.every((v) => v is int) &&
                  (p[1] as int) > 0 &&
                  const {0, 1}.contains(p[2]) &&
                  (p[4] as int) >= 0 &&
                  (p[4] as int) <= 5,
              'declared_program.condition',
              r'$',
              'Variable conditions require bounded typed comparisons.');
        }
        if (p.first == 6) {
          _require(
              p.length == 3 && p[1] == -1 && const {2, 4, 6, 8}.contains(p[2]),
              'declared_program.condition',
              r'$',
              'Facing guards require the player and a cardinal direction.');
        }
      }
      if (p.first == 12 && allowed != null) {
        _require(
            p.length == 2 &&
                p[1] is String &&
                switch (family) {
                  SourceDeclaredProgramFamily.centerNurse =>
                    p[1] == 'pbPokerus?',
                  SourceDeclaredProgramFamily.pokedexReward => RegExp(
                          r'^(?:pbReceiveItem\(:[A-Z][A-Z0-9_]*(?:,[ ]*[1-9][0-9]*)?\)|!\$bag\.has\?\(:[A-Z][A-Z0-9_]*\))$')
                      .hasMatch(p[1] as String),
                  SourceDeclaredProgramFamily.externalWarp =>
                    p[1] == 'get_self.onEvent?',
                  _ => false,
                },
            'declared_program.script',
            r'$',
            'Unknown script predicates cannot be declared as interpreted conditions.');
      }
    }
    if (code == 314) {
      _require(canonicalJsonOf(p) == '[0]', 'declared_program.heal', r'$',
          'Native healing requires the entire-party opcode.');
    }
    if (code == 102) {
      _require(
          p.length == 2 &&
              p[0] is List &&
              (p[0] as List).length == 2 &&
              (p[0] as List).every((v) => v is String) &&
              p[1] == 2,
          'declared_program.choice',
          r'$',
          'Native service decisions require two explicit choices with cancellation.');
    }
  }
  _require(
      stack.isEmpty && (list.last as Map)['code'] == 0,
      'declared_program.control_flow',
      r'$',
      'Declared programs require a complete terminated command graph.');
  if (family == SourceDeclaredProgramFamily.centerNurse) {
    _require(
        list.where((c) => (c as Map)['code'] == 314).length == 1 &&
            list.where((c) => (c as Map)['code'] == 102).length ==
                (role == 'choice' ? 1 : 0),
        'declared_program.heal',
        r'$',
        'Nurse roles require their typed heal and decision operations.');
  }
}

bool _declaredScriptAllowed(
    SourceDeclaredProgramFamily family, String script, Set<String> locals) {
  switch (family) {
    case SourceDeclaredProgramFamily.centerNurse:
      return script == 'pbSetPokemonCenter' ||
          script == r'$stats.poke_center_count += 1' ||
          RegExp(r'^get_character\([1-9][0-9]*\)\.pattern = 0$')
              .hasMatch(script);
    case SourceDeclaredProgramFamily.centerPc:
      return script == 'pbPokeCenterPC';
    case SourceDeclaredProgramFamily.partyTrade:
      if (RegExp(r'^pbChoosePokemon\([1-9][0-9]*,[1-9][0-9]*\)$')
          .hasMatch(script)) {
        return true;
      }
      final assignment =
          RegExp(r'^([a-z][A-Za-z0-9_]*) = pbGetPokemon\([1-9][0-9]*\)$')
              .firstMatch(script);
      if (assignment != null) {
        locals.add(assignment[1]!);
        return true;
      }
      final trade = RegExp(
              r'^pbStartTradeYourself\(([a-z][A-Za-z0-9_]*),([a-z][A-Za-z0-9_]*)\)$')
          .firstMatch(script);
      return trade != null &&
          locals.contains(trade[1]) &&
          locals.contains(trade[2]);
    case SourceDeclaredProgramFamily.pokedexReward:
      return RegExp(
                  r'^pbSet\([1-9][0-9]*,\$player\.pokedex\.(seen|owned)_count\([0-9]+\)\)$')
              .hasMatch(script) ||
          RegExp(r'^pbReceiveItem\(:[A-Z][A-Z0-9_]*\)$').hasMatch(script) ||
          RegExp(r'^\$game_self_switches\[\[[1-9][0-9]*,[1-9][0-9]*,"[A-D]"\]\]=true$')
              .hasMatch(script);
    case SourceDeclaredProgramFamily.externalWarp:
      return const {'pbCaveEntrance', 'pbCaveExit'}.contains(script) ||
          RegExp(r'^setTempSwitchOn\("[A-D]"\)$').hasMatch(script);
    default:
      return false;
  }
}

final class SourceDeclaredProgramMatch {
  SourceDeclaredProgramMatch._(
      this.binding, this.pageRoles, this.pageValues, this.references,
      {this.automaticallyDiscovered = false});
  final bool automaticallyDiscovered;
  final SourceDeclaredProgramBinding binding;
  final Map<int, String> pageRoles;
  final Map<int, Map<String, Object?>> pageValues;
  final Map<int, SourcePreservedData> references;
  int indexForRole(String role) =>
      pageRoles.entries.singleWhere((e) => e.value == role).key;
  Map<String, Object?> toJson() => {
        'mode': automaticallyDiscovered
            ? 'automaticSourceStructure'
            : 'declaredProgramBinding',
        'bindingId': binding.id.value,
        'bindingHash': binding.canonicalHash.value,
        'family': binding.family.name,
        'pageRoles': {for (final e in pageRoles.entries) '${e.key}': e.value},
        'rubySemanticsAutomaticallyCertified': false
      };
}

SourceDeclaredProgramMatch? matchSourceDeclaredProgram(
    {required NormalizedSourceProject source,
    required SourceEventProfile profile,
    required int sourceMapId,
    required SourceEvent event,
    required Set<SourceDeclaredProgramFamily> families,
    String? familyId,
    Set<ConverterId>? bindingIds}) =>
    _matchSourceDeclaredProgram(
      analyzer: SourceEventAnalyzer.forProject(source, profile: profile),
      sourceMapId: sourceMapId,
      event: event,
      families: families,
      familyId: familyId,
      bindingIds: bindingIds,
    );

SourceDeclaredProgramMatch? _matchSourceDeclaredProgram({
  required SourceEventAnalyzer analyzer,
  required int sourceMapId,
  required SourceEvent event,
  required Set<SourceDeclaredProgramFamily> families,
  String? familyId,
  Set<ConverterId>? bindingIds,
}) {
  final profile = analyzer.profile;
  if (!analyzer._isQualified) return null;
  try {
    final declared = profile.interpretationProfile?.declaredPrograms ??
        const <SourceDeclaredProgramBinding>[];
    final supportsAutomatic = families.any((family) => const {
          SourceDeclaredProgramFamily.centerNurse,
          SourceDeclaredProgramFamily.pokedexReward,
          SourceDeclaredProgramFamily.centerPc,
          SourceDeclaredProgramFamily.healingDisplay,
          SourceDeclaredProgramFamily.warpTile,
          SourceDeclaredProgramFamily.hole,
          SourceDeclaredProgramFamily.externalWarp,
        }.contains(family));
    if (!supportsAutomatic &&
        !declared.any((binding) => families.contains(binding.family))) {
      return null;
    }
    final raw = analyzer._declaredRawEvents.putIfAbsent(
        (sourceMapId, event._json), () {
      final raw = _externalWarpRawEvent(analyzer, sourceMapId, event);
      return raw == null
          ? null
          : (value: _freezeDeclared(raw.value), reference: raw.reference);
    });
    if (raw?.value is! Map) return null;
    final pages = (raw!.value as Map)['pages'];
    if (pages is! List || pages.length != event.pages.length) return null;
    final encodedPages = [for (final page in pages) canonicalJsonOf(page)];
    final matches = <SourceDeclaredProgramMatch>[];
    final automatic = supportsAutomatic &&
            !declared.any((binding) =>
                families.contains(binding.family) &&
                binding.pages.length == pages.length &&
                encodedPages.every(binding._canonicalPages.values.contains))
        ? (families.contains(SourceDeclaredProgramFamily.pokedexReward)
                ? _automaticPokedexRewardBinding(pages.cast<Object?>())
                : null) ??
            (families.contains(SourceDeclaredProgramFamily.hole)
                ? _automaticHoleBinding(pages.cast<Object?>())
                : null) ??
            (families.contains(SourceDeclaredProgramFamily.warpTile)
                ? _automaticWarpTileBinding(pages.cast<Object?>())
                : null) ??
            (families.contains(SourceDeclaredProgramFamily.externalWarp)
                ? _automaticExternalWarpBinding(pages.cast<Object?>())
                : null) ??
            _automaticCenterServiceBinding(pages.cast<Object?>())
        : null;
    for (final binding in [...declared, if (automatic != null) automatic]) {
      if (bindingIds != null && !bindingIds.contains(binding.id) ||
          !families.contains(binding.family) ||
          binding.pages.length != pages.length ||
          familyId != null && binding.parameters['familyId'] != familyId) {
        continue;
      }
      final roles = <int, String>{};
      final values = <int, Map<String, Object?>>{};
      final refs = <int, SourcePreservedData>{};
      for (final page in event.pages) {
        final value =
            Map<String, Object?>.from(pages[page.originalPageIndex] as Map);
        final matching = binding.pages.entries
            .where((e) =>
                binding._canonicalPages[e.key] ==
                encodedPages[page.originalPageIndex])
            .toList();
        if (matching.length != 1 ||
            roles.values.contains(matching.single.key)) {
          break;
        }
        roles[page.originalPageIndex] = matching.single.key;
        values[page.originalPageIndex] =
            _freezeDeclared(value) as Map<String, Object?>;
        refs[page.originalPageIndex] = analyzer._reference(page.rawDataRef)!;
      }
      if (roles.length == pages.length) {
        matches.add(SourceDeclaredProgramMatch._(
            binding,
            Map.unmodifiable(roles),
            Map.unmodifiable(values),
            Map.unmodifiable(refs),
            automaticallyDiscovered: identical(binding, automatic)));
      }
    }
    return matches.length == 1 ? matches.single : null;
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  }
}

SourceDeclaredProgramBinding? _automaticHoleBinding(List<Object?> pages) {
  if (pages.length != 1 || pages.single is! Map) return null;
  final page = Map<String, Object?>.from(pages.single as Map);
  final graphic = page['graphic'], condition = page['condition'];
  final commands = page['list'];
  if (page['trigger'] != 1 || page['move_type'] != 0 ||
      page['through'] is! bool || graphic is! Map || condition is! Map ||
      graphic['tile_id'] != 0 || graphic['character_name'] != '' ||
      graphic['character_hue'] != 0 || graphic['direction'] != 2 ||
      graphic['pattern'] != 0 || graphic['opacity'] != 255 ||
      graphic['blend_type'] != 0 || const [
        'switch1_valid', 'switch2_valid', 'variable_valid', 'self_switch_valid',
      ].any((flag) => condition[flag] != false) ||
      commands is! List || (commands.length != 14 && commands.length != 13)) {
    return null;
  }
  final terrainBump = commands.length == 13;
  if (page['through'] != !terrainBump) return null;
  final codes = terrainBump
      ? const [250, 209, 509, 106, 223, 106, 201, 210, 209, 509, 223, 250, 0]
      : const [209, 509, 210, 250, 106, 223, 106, 201, 209, 509, 210, 223, 250, 0];
  for (var index = 0; index < codes.length; index++) {
    final command = commands[index];
    if (command is! Map || command['code'] != codes[index] ||
        command['indent'] != 0) {
      return null;
    }
  }
  for (final (index, opacity) in [(terrainBump ? 1 : 0, 0), (8, 255)]) {
    final parameters = (commands[index] as Map)['parameters'];
    final continued = (commands[index + 1] as Map)['parameters'];
    if (parameters is! List || parameters.length != 2 ||
        parameters.first != -1 || continued is! List || continued.length != 1) {
      return null;
    }
    final route = parameters.last;
    if (route is! Map || route['__class__'] != 'RPG::MoveRoute' ||
        route['repeat'] != false || route['skippable'] is! bool ||
        route['list'] is! List) {
      return null;
    }
    final steps = route['list'] as List;
    final expected = {'__class__': 'RPG::MoveCommand', 'code': 42, 'parameters': [opacity]};
    final end = {'__class__': 'RPG::MoveCommand', 'code': 0, 'parameters': <Object?>[]};
    if (steps.length != 2 || canonicalJsonOf(steps.first) != canonicalJsonOf(expected) ||
        canonicalJsonOf(steps.last) != canonicalJsonOf(end) ||
        canonicalJsonOf(continued.single) != canonicalJsonOf(expected)) {
      return null;
    }
  }
  return SourceDeclaredProgramBinding.fromJson({
    'id': 'automatic-hole-${canonicalHashOf(pages).value}',
    'family': 'hole',
    'pages': {'program': page},
    'parameters': <String, Object?>{},
  });
}

SourceDeclaredProgramBinding? _automaticWarpTileBinding(List<Object?> pages) {
  if (pages.any((page) => page is! Map)) return null;
  final values =
      pages.map((page) => Map<String, Object?>.from(page as Map)).toList();
  if (values.any((page) {
    final graphic = page['graphic'] as Map;
    return page['move_type'] != 0 ||
        graphic['tile_id'] != 0 ||
        graphic['character_name'] != '' ||
        graphic['blend_type'] != 0;
  })) {
    return null;
  }
  Map<String, Object?>? roles;
  String? role;
  if (values.length == 2 &&
      values[0]['trigger'] == 1 &&
      values[1]['trigger'] == 3 &&
      (values[0]['condition'] as Map)['self_switch_valid'] == true &&
      (values[1]['condition'] as Map)['switch1_valid'] == true) {
    roles = {'departure': values[0], 'arrival': values[1]};
    role = 'tile';
  } else if (values.length == 1 && values.single['trigger'] == 1) {
    final page = values.single;
    final condition = page['condition'] as Map;
    final commands = page['list'] as List;
    if (const [
          'switch1_valid',
          'switch2_valid',
          'variable_valid',
          'self_switch_valid'
        ].any((flag) => condition[flag] != false) ||
        commands.length != 2) {
      return null;
    }
    final first = commands.first as Map, last = commands.last as Map;
    final parameters = first['parameters'] as List;
    if (first['code'] != 355 ||
        first['indent'] != 0 ||
        last['code'] != 0 ||
        last['indent'] != 0 ||
        (last['parameters'] as List).isNotEmpty ||
        parameters.length != 1 ||
        parameters.single is! String ||
        !RegExp(r'^pbSetSelfSwitch\([1-9][0-9]*,"[A-D]",true\)$')
            .hasMatch(parameters.single as String)) {
      return null;
    }
    roles = {'program': page};
    role = 'activation';
  }
  if (roles == null) return null;
  return SourceDeclaredProgramBinding.fromJson({
    'id': 'automatic-warpTile-${canonicalHashOf(pages).value}',
    'family': 'warpTile',
    'pages': roles,
    'parameters': {'role': role},
  });
}
