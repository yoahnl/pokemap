part of '../avelune_converter_core.dart';

SourceDeclaredProgramBinding? _automaticCenterServiceBinding(
    List<Object?> rawPages) {
  if (rawPages.length == 7 && rawPages.every((page) => page is Map)) {
    try {
      final pages = rawPages.cast<Map>();
      if (pages.indexed.any((entry) =>
          entry.$2['trigger'] != 0 ||
          ((entry.$2['list'] as List).single as Map)['code'] != 0 ||
          (entry.$2['condition'] as Map)['variable_valid'] != (entry.$1 > 0) ||
          (entry.$1 > 0 &&
              (entry.$2['condition'] as Map)['variable_value'] != entry.$1))) {
        return null;
      }
      return SourceDeclaredProgramBinding.fromJson({
        'id': 'automatic-healingDisplay-${canonicalHashOf(rawPages).value}',
        'family': 'healingDisplay',
        'pages': {
          for (final entry in pages.indexed) 'count${entry.$1}': entry.$2
        },
        'parameters': {},
      });
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } on StateError {
      return null;
    }
  }
  if (rawPages.length != 2 || rawPages.any((page) => page is! Map)) return null;
  final pages =
      rawPages.map((page) => Map<String, Object?>.from(page as Map)).toList();
  final first = pages[0], second = pages[1];
  List<(int, Map)> commands(Map page) => [
        for (final entry in (page['list'] as List).indexed)
          if (!const {108, 408, 401}.contains((entry.$2 as Map)['code']))
            (entry.$1, entry.$2 as Map),
      ];
  final a = commands(first), b = commands(second);
  bool shape(List<(int, Map)> list, String expected) =>
      list
          .map((entry) => '${entry.$2['code']}:${entry.$2['indent']}')
          .join(',') ==
      expected;
  Object? args(List<(int, Map)> list, int index) =>
      list[index].$2['parameters'];
  bool equal(Object? a, Object? b) => canonicalJsonOf(a) == canonicalJsonOf(b);
  Map<String, Object?> binding(String family, Map<String, Object?> roles,
          Map<String, Object?> parameters) =>
      {
        'id': 'automatic-$family-${canonicalHashOf(rawPages).value}',
        'family': family,
        'pages': roles,
        'parameters': parameters,
      };
  try {
    if ((shape(a, '123:0,0:0') ||
            shape(a, '111:0,123:1,0:1,411:0,101:1,0:1,412:0,0:0')) &&
        shape(b, '355:0,123:0,0:0') &&
        equal(args(b, 0), ['pbPokeCenterPC'])) {
      return SourceDeclaredProgramBinding.fromJson(
          binding('centerPc', {'activation': first, 'open': second}, {}));
    }
    if (!shape(a,
            '355:0,101:0,101:0,101:0,102:0,402:0,101:1,355:1,314:1,209:1,509:1,509:1,210:1,122:1,122:1,118:1,122:1,250:1,106:1,111:1,119:2,0:2,412:1,209:1,509:1,249:1,106:1,122:1,355:1,209:1,509:1,209:1,509:1,509:1,210:1,111:1,101:2,101:2,101:2,121:2,0:2,411:1,101:2,101:2,209:2,509:2,509:2,509:2,210:2,101:2,0:2,412:1,0:1,402:0,101:1,0:1,404:0,0:0') ||
        !shape(b,
            '101:0,355:0,314:0,209:0,509:0,509:0,210:0,122:0,122:0,118:0,122:0,250:0,106:0,111:0,119:1,0:1,412:0,209:0,509:0,249:0,106:0,122:0,355:0,209:0,509:0,209:0,509:0,509:0,210:0,101:0,209:0,509:0,509:0,509:0,210:0,101:0,121:0,0:0')) {
      return null;
    }
    final labels = (args(a, 4) as List)[0] as List;
    if (!equal(args(a, 0), ['pbSetPokemonCenter']) ||
        !equal(args(a, 7), [r'$stats.poke_center_count += 1']) ||
        !equal(args(b, 1), [r'$stats.poke_center_count += 1']) ||
        !equal(args(a, 5), [0, labels[0]]) ||
        !equal(args(a, 53), [1, labels[1]]) ||
        !equal(args(a, 35), [12, 'pbPokerus?'])) {
      return null;
    }
    final visualA = {...first}
      ..remove('condition')
      ..remove('trigger')
      ..remove('list');
    final visualB = {...second}
      ..remove('condition')
      ..remove('trigger')
      ..remove('list');
    if (!equal(visualA, visualB)) return null;
    final count = (args(a, 13) as List)[0];
    final balls = (args(a, 14) as List)[0];
    final loop = (args(a, 15) as List).single;
    final display = (args(a, 23) as List)[0];
    if (count is! int ||
        balls is! int ||
        count == balls ||
        display is! int ||
        display <= 0) {
      return null;
    }
    bool presentation(List<(int, Map)> list, int offset) {
      final base = offset;
      final positions = base == 0
          ? [13, 14, 15, 16, 19, 20, 27, 28, 23, 29]
          : [7, 8, 9, 10, 13, 14, 21, 22, 17, 23];
      if (!equal(args(list, positions[0]), [count, count, 0, 7, 1]) ||
          !equal(args(list, positions[1]), [balls, balls, 0, 0, 0]) ||
          !equal(args(list, positions[2]), [loop]) ||
          !equal(args(list, positions[3]), [balls, balls, 1, 0, 1]) ||
          !equal(args(list, positions[4]), [1, balls, 1, count, 4]) ||
          !equal(args(list, positions[5]), [loop]) ||
          !equal(args(list, positions[6]), [balls, balls, 0, 0, 0]) ||
          !equal(args(list, positions[7]),
              ['get_character($display).pattern = 0'])) {
        return false;
      }
      bool route(int index, int actor, List<Object?> steps) {
        final value = args(list, index) as List;
        return value[0] == actor &&
            equal((value[1] as Map)['list'], [
              for (final step in steps)
                {
                  '__class__': 'RPG::MoveCommand',
                  'code': (step as List)[0],
                  'parameters': step[1]
                },
              {'__class__': 'RPG::MoveCommand', 'code': 0, 'parameters': []},
            ]);
      }

      final charset = (first['graphic'] as Map)['character_name'];
      return route(base == 0 ? 9 : 3, 0, [
            [17, []],
            [
              15,
              [2]
            ]
          ]) &&
          route(positions[8], display, [
            [33, []]
          ]) &&
          route(positions[9], display, [
            [34, []]
          ]) &&
          route(base == 0 ? 31 : 25, 0, [
            [
              15,
              [15]
            ],
            [16, []]
          ]) &&
          route(base == 0 ? 44 : 30, 0, [
            [
              41,
              [charset, 0, 2, 1]
            ],
            [
              15,
              [10]
            ],
            [
              41,
              [charset, 0, 2, 0]
            ]
          ]);
    }

    if (!presentation(a, 0) || !presentation(b, 1)) return null;
    List<int> indices(List<(int, Map)> list, List<int> positions) =>
        positions.map((position) => list[position].$1).toList();
    return SourceDeclaredProgramBinding.fromJson(binding('centerNurse', {
      'choice': first,
      'recovery': second
    }, {
      'choiceCommandIndex': a[4].$1,
      'textGroups': {
        'choice': {
          'greeting': indices(a, [1, 2, 3]),
          'acceptance': indices(a, [6]),
          'completion': indices(a, [42, 43, 49]),
          'refusal': indices(a, [54])
        },
        'recovery': {
          'greeting': indices(b, [0]),
          'acceptance': [],
          'completion': indices(b, [29, 35]),
          'refusal': []
        },
      },
      'recoveryMusicCommandIndices': {'choice': a[25].$1, 'recovery': b[19].$1},
      'recoveryWaitCommandIndices': {'choice': a[26].$1, 'recovery': b[20].$1},
    }));
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  } on RangeError {
    return null;
  }
}
