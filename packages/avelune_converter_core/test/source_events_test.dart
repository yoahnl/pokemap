import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';

final class _RubyObject {
  _RubyObject(this.className, this.fields);
  final String className;
  final Map<String, Object?> fields;
}

final class _RubyBytes {
  const _RubyBytes(this.bytes);
  final List<int> bytes;
}

final class _RubyTable {
  _RubyTable(this.x, this.y, this.z, this.cells, {this.dimensions = 3});
  final int dimensions;
  final int x;
  final int y;
  final int z;
  final List<int> cells;
}

final class _MarshalFixture {
  final _objects = HashMap<Object, int>.identity();

  List<int> dump(Object? value) => [4, 8, ..._value(value)];

  List<int> _packed(int value) {
    if (value == 0) return [0];
    if (value > 0 && value < 123) return [value + 5];
    if (value < 0 && value > -124) return [(value - 5) & 255];
    var width = 1;
    while (value >= (1 << (width * 8)) || value < -(1 << (width * 8))) {
      width++;
    }
    return [
      value >= 0 ? width : (-width) & 255,
      for (var i = 0; i < width; i++) (value >> (i * 8)) & 255,
    ];
  }

  List<int> _symbol(String value) {
    final bytes = utf8.encode(value);
    return [0x3a, ..._packed(bytes.length), ...bytes];
  }

  List<int> _value(Object? value) {
    if (value == null) return [0x30];
    if (value is bool) return [value ? 0x54 : 0x46];
    if (value is int) return [0x69, ..._packed(value)];
    final prior = _objects[value];
    if (prior != null) return [0x40, ..._packed(prior)];
    _objects[value] = _objects.length;
    if (value is String || value is _RubyBytes) {
      final bytes =
          value is String ? utf8.encode(value) : (value as _RubyBytes).bytes;
      return [0x22, ..._packed(bytes.length), ...bytes];
    }
    if (value is List) {
      return [
        0x5b,
        ..._packed(value.length),
        for (final item in value) ..._value(item)
      ];
    }
    if (value is Map) {
      return [
        0x7b,
        ..._packed(value.length),
        for (final entry in value.entries) ...[
          ..._value(entry.key),
          ..._value(entry.value)
        ],
      ];
    }
    if (value is _RubyObject) {
      return [
        0x6f,
        ..._symbol(value.className),
        ..._packed(value.fields.length),
        for (final entry in value.fields.entries) ...[
          ..._symbol(entry.key),
          ..._value(entry.value)
        ],
      ];
    }
    if (value is _RubyTable) {
      final data = ByteData(20 + value.cells.length * 2)
        ..setUint32(0, value.dimensions, Endian.little)
        ..setUint32(4, value.x, Endian.little)
        ..setUint32(8, value.y, Endian.little)
        ..setUint32(12, value.z, Endian.little)
        ..setUint32(16, value.cells.length, Endian.little);
      for (var i = 0; i < value.cells.length; i++) {
        data.setInt16(20 + 2 * i, value.cells[i], Endian.little);
      }
      final bytes = data.buffer.asUint8List();
      return [0x75, ..._symbol('Table'), ..._packed(bytes.length), ...bytes];
    }
    throw ArgumentError('Unsupported synthetic fixture value');
  }
}

_RubyObject _mapInfo(String name, {int parent = 0, int order = 0}) =>
    _RubyObject('RPG::MapInfo', {
      '@name': name,
      '@parent_id': parent,
      '@order': order,
      '@expanded': true,
      '@scroll_x': 4,
      '@scroll_y': 7,
    });

_RubyObject _map({
  int width = 3,
  int height = 2,
  int tileset = 1,
  _RubyTable? data,
  Map<int, Object?>? events,
}) =>
    _RubyObject('RPG::Map', {
      '@tileset_id': tileset,
      '@width': width,
      '@height': height,
      '@data': data ??
          _RubyTable(width, height, 3,
              List.generate(width * height * 3, (i) => 384 + i)),
      '@events': events ?? <int, Object?>{},
      '@autoplay_bgm': false,
      '@bgm': _RubyObject(
          'RPG::AudioFile', {'@name': '', '@volume': 80, '@pitch': 100}),
      '@autoplay_bgs': false,
      '@bgs': _RubyObject(
          'RPG::AudioFile', {'@name': '', '@volume': 80, '@pitch': 100}),
      '@encounter_list': <Object?>[],
      '@encounter_step': 30,
    });

_RubyObject _tileset({String image = 'Terrain', List<String>? autotiles}) =>
    _RubyObject('RPG::Tileset', {
      '@id': 1,
      '@name': 'Source terrain',
      '@tileset_name': image,
      '@autotile_names': autotiles ?? List.filled(7, ''),
      '@panorama_name': '',
      '@panorama_hue': 0,
      '@fog_name': '',
      '@fog_hue': 0,
      '@fog_opacity': 64,
      '@fog_blend_type': 0,
      '@fog_zoom': 200,
      '@fog_sx': 0,
      '@fog_sy': 0,
      '@battleback_name': '',
      '@passages': _RubyTable(512, 1, 1, List.generate(512, (i) => i % 16),
          dimensions: 1),
      '@priorities': _RubyTable(512, 1, 1, List.generate(512, (i) => i % 6),
          dimensions: 1),
      '@terrain_tags': _RubyTable(512, 1, 1, List.generate(512, (i) => i % 8),
          dimensions: 1),
    });

_RubyObject _command(int code, List<Object?> parameters, {int indent = 0}) =>
    _RubyObject('RPG::EventCommand',
        {'@code': code, '@indent': indent, '@parameters': parameters});

_RubyObject _page(List<_RubyObject> commands,
        {int trigger = 0, String character = ''}) =>
    _RubyObject('RPG::Event::Page', {
      '@condition': _RubyObject('RPG::Event::Page::Condition', {
        '@switch1_valid': false,
        '@switch2_valid': false,
        '@variable_valid': false,
        '@self_switch_valid': false,
        '@switch1_id': 1,
        '@switch2_id': 1,
        '@variable_id': 1,
        '@variable_value': 0,
        '@self_switch_ch': 'A',
      }),
      '@graphic': _RubyObject('RPG::Event::Page::Graphic', {
        '@tile_id': 0,
        '@character_name': character,
        '@character_hue': 0,
        '@direction': 2,
        '@pattern': 0,
        '@opacity': 255,
        '@blend_type': 0,
      }),
      '@move_type': 0,
      '@move_speed': 3,
      '@move_frequency': 3,
      '@move_route': _RubyObject('RPG::MoveRoute', {
        '@repeat': true,
        '@skippable': false,
        '@list': [
          _RubyObject(
              'RPG::MoveCommand', {'@code': 0, '@parameters': <Object?>[]})
        ],
      }),
      '@walk_anime': true,
      '@step_anime': false,
      '@direction_fix': false,
      '@through': false,
      '@always_on_top': false,
      '@trigger': trigger,
      '@list': commands,
    });

_RubyObject _event(int id, List<_RubyObject> pages, {int x = 1, int y = 1}) =>
    _RubyObject('RPG::Event',
        {'@id': id, '@name': 'Event $id', '@x': x, '@y': y, '@pages': pages});

List<int> _png() {
  final header = ByteData(13)
    ..setUint32(0, 256, Endian.big)
    ..setUint32(4, 96, Endian.big)
    ..setUint8(8, 8)
    ..setUint8(9, 6);
  return [
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
    ..._pngChunk('IHDR', header.buffer.asUint8List()),
    ..._pngChunk(
        'IDAT', ZLibEncoder().convert(List.filled(96 * (1 + 256 * 4), 0))),
    ..._pngChunk('IEND', []),
  ];
}

List<int> _pngChunk(String type, List<int> payload) {
  final body = [...ascii.encode(type), ...payload];
  var crc = 0xffffffff;
  for (final byte in body) {
    crc ^= byte;
    for (var i = 0; i < 8; i++) {
      crc = crc & 1 == 0 ? crc >> 1 : (crc >> 1) ^ 0xedb88320;
    }
  }
  final length = ByteData(4)..setUint32(0, payload.length, Endian.big);
  final checksum = ByteData(4)..setUint32(0, crc ^ 0xffffffff, Endian.big);
  return [
    ...length.buffer.asUint8List(),
    ...body,
    ...checksum.buffer.asUint8List()
  ];
}

Map<String, List<int>> _project({
  Map<int, _RubyObject>? maps,
  Map<int, _RubyObject>? infos,
  _RubyObject? tileset,
  bool image = true,
}) {
  final sourceMaps = maps ?? {1: _map()};
  final sourceInfos =
      infos ?? {for (final id in sourceMaps.keys) id: _mapInfo('Map $id')};
  return {
    'README.md': utf8.encode('Pokemon Essentials v21.1\n'),
    'Data/MapInfos.rxdata': _MarshalFixture().dump(sourceInfos),
    'Data/Tilesets.rxdata':
        _MarshalFixture().dump([null, tileset ?? _tileset()]),
    for (final entry in sourceMaps.entries)
      'Data/Map${entry.key.toString().padLeft(3, '0')}.rxdata':
          _MarshalFixture().dump(entry.value),
    if (image) 'Graphics/Tilesets/Terrain.png': _png(),
  };
}

Sha256Hash _hash(List<int> bytes) =>
    Sha256Hash(crypto.sha256.convert(bytes).toString());

final class _Files implements SourceFilePort {
  _Files(this.bytes, this.snapshot) {
    for (final entry in snapshot.entries) {
      byId[entry.fileId] = entry.relativePath;
    }
  }
  final Map<String, List<int>> bytes;
  final SourceSnapshot snapshot;
  final byId = <ConverterId, String>{};
  final reads = <String>[];
  final replacements = <String, List<int>>{};
  void Function(String)? onRead;

  @override
  Future<List<int>> read(ConverterId fileId) async {
    final path = byId[fileId]!;
    reads.add(path);
    onRead?.call(path);
    return List<int>.from(replacements[path] ?? bytes[path]!);
  }
}

_Files _source(Map<String, List<int>> bytes,
    {bool reverse = false,
    SourceScanState state = SourceScanState.complete,
    String namespace = 'synthetic-project'}) {
  final entries = [
    for (final entry in bytes.entries)
      SourceFileEntry(
        fileId: ConverterId(
            'fixture:${base64Url.encode(utf8.encode(entry.key)).replaceAll('=', '')}'),
        relativePath: entry.key,
        kind: SourceNodeKind.file,
        byteLength: entry.value.length,
        sha256: _hash(entry.value),
        format: entry.key.endsWith('.rxdata')
            ? 'ruby-marshal'
            : entry.key.endsWith('.png')
                ? 'png'
                : 'text',
        family: entry.key.endsWith('.rxdata')
            ? 'rmxp'
            : entry.key.endsWith('.png')
                ? 'raster'
                : 'documentation',
      ),
  ];
  final snapshot = SourceSnapshot(
    logicalProjectNamespace: ConverterId(namespace),
    policyHash: _hash([1, 2, 3]),
    entries: reverse ? entries.reversed.toList() : entries,
    diagnostics: [],
    excludedPaths: [],
    profileEvidence: [
      if (bytes.containsKey('README.md'))
        SourceProfileEvidence(
            relativePath: 'README.md',
            fileHash: _hash(bytes['README.md']!),
            version: '21.1',
            line: 1,
            excerpt: 'Pokemon Essentials v21.1'),
    ],
    state: state,
  );
  return _Files(bytes, snapshot);
}

Future<NormalizedSourceProject> _normalize(_Files files,
        {SourceNormalizationLimits limits = const SourceNormalizationLimits(),
        Set<int>? selectedMapIds,
        bool includeEventSystem = false,
        ScanCancellation? cancellation}) =>
    const RmxpSourceNormalizer().normalize(
        snapshot: files.snapshot,
        files: files,
        limits: limits,
        selectedMapIds: selectedMapIds,
        includeEventSystem: includeEventSystem,
        cancellation: cancellation);

Future<NormalizedSourceProject> _events(List<_RubyObject> pages,
    {bool system = true,
    bool includeSystem = true,
    List<Object?> switches = const ['', 'Ready', 's:dangerous()'],
    Map<int, _RubyObject>? extraEvents}) async {
  final data = _project(maps: {
    1: _map(events: {1: _event(1, pages), ...?extraEvents}),
    8: _map(),
  });
  if (system) {
    data['Data/System.rxdata'] = _MarshalFixture()
        .dump(_RubyObject('RPG::System', {'@switches': switches}));
  }
  return _normalize(_source(data), includeEventSystem: includeSystem);
}

SourceEventAnalyzer _analyzer(NormalizedSourceProject project,
        {String? scriptsHash}) =>
    SourceEventAnalyzer.forProject(project,
        profile: SourceEventProfile.kantoForProject(project,
            scriptsArchiveHash: Sha256Hash(
                scriptsHash ?? SourceEventProfile.kantoScriptsArchiveSha256)));

_RubyObject _withCondition(_RubyObject page, Map<String, Object?> values) {
  (page.fields['@condition'] as _RubyObject).fields.addAll(values);
  return page;
}

extension on SourceEventAnalysis {
  SourceEventDefinition requireEvent(int mapId, int eventId) {
    final event = eventAt(mapId, eventId);
    expect(event, isNotNull,
        reason: 'The preserved source event must be analyzed');
    return event!;
  }
}

void main() {
  test(
      'closed literal pickup condition preserves the source symbol and both return branches',
      () async {
    for (final expression in [
      'pbItemBall(:POTION)',
      ' pbItemBall( :POTION, 2 ) '
    ]) {
      final result = _analyzer(await _events([
        _page([
          _command(111, [12, expression]),
          _command(123, ['A', 0], indent: 1),
          _command(411, []),
          _command(101, ['Bag full'], indent: 1),
          _command(412, []),
          _command(0, []),
        ])
      ]))
          .analyze();
      final event = result.requireEvent(1, 1);
      final condition =
          event.pages.single.body.nodes.single as SourceConditionalNode;
      expect(condition.condition.kind, SourceEventConditionKind.pickup);
      expect(condition.condition.pickup!.sourceSymbol, 'POTION');
      expect(condition.condition.pickup!.quantity,
          expression.contains(',') ? 2 : 1);
      expect(condition.condition.pickup!.failureMayPartiallyAdd,
          expression.contains(','));
      expect(condition.condition.toJson()['pickup'],
          containsPair('targetQualification', 'required'));
      expect(condition.condition.evaluate(), isNull);
      expect(condition.whenTrue.nodes.single, isA<SourceSelfSwitchNode>());
      expect(condition.whenFalse.nodes.single, isA<SourceTextNode>());
      expect(event.isQuarantined, isFalse);
    }
  });

  test(
      'pickup-looking dynamic Ruby and statement suffixes are entirely quarantined',
      () async {
    for (final expression in [
      'pbItemBall(item)',
      'pbItemBall(:POTION, amount)',
      'pbItemBall(:POTION, 0)',
      'pbItemBall(:POTION, -1)',
      'pbItemBall(:POTION, 01)',
      'pbItemBall(:POTION, 2147483648)',
      'pbItemBall(:POTION, *items)',
      'obj.pbItemBall(:POTION)',
      'pbItemBall(:POTION); reward()',
      'pbItemBall(:POTION) || reward()',
      'pbItemBall(:"#{dynamic}")',
      'pbItemBall(:POTION, 1, extra)',
      'pbItemBall(: POTION)',
      'pbItemBall\n(:POTION)',
    ]) {
      final event = _analyzer(await _events([
        _page([
          _command(111, [12, expression]),
          _command(123, ['A', 0], indent: 1),
          _command(412, []),
        ])
      ]))
          .analyze()
          .requireEvent(1, 1);
      expect(event.isQuarantined, isTrue, reason: expression);
    }
  });

  test(
      'Essentials dummy126 and pickup scripts are never promoted to native grants',
      () async {
    for (final command in [
      _command(126, [1, 0, 0, 1]),
      _command(355, ['pbItemBall(:POTION)'])
    ]) {
      final event = _analyzer(await _events([
        _page([command])
      ]))
          .analyze()
          .requireEvent(1, 1);
      expect(event.isQuarantined, isTrue);
      expect(
          event.pages.single.body.nodes.single, isNot(isA<SourcePickupNode>()));
    }
  });

  test('exact oracle and source bindings qualify a profile', () async {
    final project = await _events([_page([])]);
    final profile = _analyzer(project).profile;
    expect(profile.isQualified, isTrue);
    expect(profile.sourceSnapshotHash, project.snapshot.canonicalHash);
    expect(profile.normalizationHash, project.canonicalHash);
    expect(
        _analyzer(project, scriptsHash: 'a' * 64).profile.isQualified, isFalse);
    expect(SourceEventProfile.kantoForProject(project).isQualified, isFalse);
  });

  test('System is optional and retained only for requested event studies',
      () async {
    final omitted = await _events([_page([])], includeSystem: false);
    final included = await _events([_page([])]);
    expect(omitted.archive.files.values.map((file) => file.entry.relativePath),
        isNot(contains('Data/System.rxdata')));
    expect(included.archive.files.values.map((file) => file.entry.relativePath),
        contains('Data/System.rxdata'));
    expect(omitted.canPlan, isTrue);
    expect(included.canPlan, isTrue);
  });

  test(
      'last true empty page masks earlier commands and remains in source order',
      () async {
    final project = await _events([
      _page([
        _command(101, ['Earlier']),
        _command(0, [])
      ]),
      _page([_command(0, [])]),
    ]);
    final event = _analyzer(project).analyze().requireEvent(1, 1);
    expect(event.pages.map((page) => page.originalPageIndex), [0, 1]);
    expect(event.selectPage()!.originalPageIndex, 1);
    expect(event.pages.last.isEmpty, isTrue);
    expect(event.isQuarantined, isFalse);
    expect(event.name, 'Event 1');
    expect([event.x, event.y], [1, 1]);
  });

  test(
      'self-switch identities are map and event scoped and snapshot independent',
      () async {
    final condition = {'@self_switch_valid': true, '@self_switch_ch': 'A'};
    final project = await _events([
      _page([
        _command(123, ['A', 0]),
        _command(0, [])
      ]),
      _withCondition(_page([]), condition),
    ], extraEvents: {
      2: _event(2, [_withCondition(_page([]), condition)])
    });
    final analyzer = _analyzer(project);
    final analysis = analyzer.analyze();
    final first = analysis.requireEvent(1, 1);
    final second = analysis.requireEvent(1, 2);
    final fact = analyzer.selfFactId(1, 1, 'A');
    expect(first.selectPage()!.originalPageIndex, 0);
    expect(first.selectPage(facts: {fact: true})!.originalPageIndex, 1);
    expect(second.selectPage(facts: {fact: true}), isNull);
    expect(fact, isNot(analyzer.selfFactId(8, 1, 'A')));
    expect(fact, isNot(analyzer.selfFactId(1, 2, 'A')));
    final changed = _analyzer(await _events([
      _page([
        _command(101, ['changed'])
      ])
    ]));
    expect(fact, changed.selfFactId(1, 1, 'A'));
    expect((first.pages.first.body.nodes.first as SourceSelfSwitchNode).factId,
        fact);
  });

  test('script-named and absent switches never become boolean conditions',
      () async {
    for (final switchId in [1, 2, 3]) {
      final project = await _events([
        _withCondition(_page([]), {
          '@switch1_valid': true,
          '@switch1_id': switchId,
        })
      ]);
      final page = _analyzer(project).analyze().requireEvent(1, 1).pages.single;
      expect(page.condition.isQualified, switchId == 1);
      if (switchId != 1) {
        expect(page.condition.evaluate(), isNull);
        expect(page.isQuarantined, isTrue);
      }
    }
    final absent = await _events([
      _withCondition(_page([]), {
        '@switch1_valid': true,
        '@switch1_id': 1,
      })
    ], system: false);
    expect(
        _analyzer(absent).analyze().requireEvent(1, 1).isQuarantined, isTrue);
  });

  test('unknown higher condition prevents selecting a lower page', () async {
    final project = await _events([
      _page([
        _command(101, ['Unsafe fallback'])
      ]),
      _withCondition(_page([]), {'@switch1_valid': true, '@switch1_id': 2}),
    ]);
    expect(
        _analyzer(project).analyze().requireEvent(1, 1).selectPage(), isNull);
  });

  test('page variables use the source greater-than-or-equal threshold',
      () async {
    final project = await _events([
      _withCondition(_page([]), {
        '@variable_valid': true,
        '@variable_id': 7,
        '@variable_value': 3,
      })
    ]);
    final condition =
        _analyzer(project).analyze().requireEvent(1, 1).pages.single.condition;
    expect(condition.evaluate(variables: {7: 2}), isFalse);
    expect(condition.evaluate(variables: {7: 3}), isTrue);
    expect(condition.evaluate(variables: {7: 4}), isTrue);
  });

  test('page graphics and movement are read without mutating sealed references',
      () async {
    final page = _page([])..fields['@through'] = true;
    final graphic = page.fields['@graphic'] as _RubyObject;
    graphic.fields['@direction'] = 8;
    graphic.fields['@pattern'] = 2;
    final project = await _events([page]);
    final before = project.archive.canonicalHash;
    final result = _analyzer(project).analyze().requireEvent(1, 1).pages.single;
    expect(result.graphic!.through, isTrue);
    expect(result.graphic!.direction, 8);
    expect(result.graphic!.pattern, 2);
    expect(result.graphic!.moveSpeed, 3);
    expect(result.rawDataRef!.contentHash,
        project.archive.files[result.rawDataRef!.fileId]!.contentHash);
    expect(project.archive.canonicalHash, before);
  });

  test('text continuation preserves oracle spaces and source span', () async {
    final project = await _events([
      _page([
        _command(101, ['Hello']),
        _command(401, ['world']),
        _command(401, ['']),
        _command(401, [' again']),
        _command(0, []),
      ])
    ]);
    final node = _analyzer(project)
        .analyze()
        .requireEvent(1, 1)
        .pages
        .single
        .body
        .nodes
        .single as SourceTextNode;
    expect(node.text, 'Hello world  again');
    expect([node.span.firstCommandIndex, node.span.lastCommandIndex], [0, 3]);
    expect(node.span.locator.pageIndex, 0);
  });

  test('conditional AST keeps both dependent branches and switch range',
      () async {
    final project = await _events([
      _page([
        _command(111, [0, 1, 0]),
        _command(121, [1, 1, 1], indent: 1),
        _command(411, []),
        _command(123, ['B', 0], indent: 1),
        _command(412, []),
        _command(0, []),
      ])
    ]);
    final analyzer = _analyzer(project);
    final page = analyzer.analyze().requireEvent(1, 1).pages.single;
    final node = page.body.nodes.single as SourceConditionalNode;
    expect(page.isQuarantined, isFalse);
    expect(node.condition.evaluate(facts: {analyzer.globalFactId(1): true}),
        isTrue);
    expect((node.whenTrue.nodes.single as SourceSwitchNode).value, isFalse);
    expect((node.whenFalse.nodes.single as SourceSelfSwitchNode).letter, 'B');
    expect(node.span.lastCommandIndex, 4);
  });

  test(
      'all alternatives and cancellation are structured under a preceding text',
      () async {
    final project = await _events([
      _page([
        _command(101, ['Choose']),
        _command(102, [
          ['Yes', 'No'],
          5
        ]),
        _command(402, [0, 'Yes']),
        _command(123, ['A', 0], indent: 1),
        _command(402, [1, 'No']),
        _command(101, ['No'], indent: 1),
        _command(403, []),
        _command(101, ['Cancel'], indent: 1),
        _command(404, []),
        _command(0, []),
      ])
    ]);
    final page = _analyzer(project).analyze().requireEvent(1, 1).pages.single;
    final text = page.body.nodes.single as SourceTextNode;
    final choice = text.followingChoice!;
    expect(page.isQuarantined, isFalse);
    expect(choice.branches.map((branch) => branch.label), ['Yes', 'No']);
    expect(choice.cancelType, 5);
    expect(
        (choice.cancelBranch!.nodes.single as SourceTextNode).text, 'Cancel');
    expect(text.span.lastCommandIndex, 8);
  });

  test('literal warp resolves selected map coordinates direction and fade',
      () async {
    final project = await _events([
      _page([
        _command(201, [0, 8, 2, 1, 6, 0])
      ])
    ]);
    final page = _analyzer(project).analyze().requireEvent(1, 1).pages.single;
    final warp = page.body.nodes.single as SourceWarpNode;
    expect(
        [warp.targetSourceMapId, warp.x, warp.y, warp.direction], [8, 2, 1, 6]);
    expect(warp.fade, isTrue);
    expect(page.isQuarantined, isFalse);
  });

  test('dynamic invalid and excluded warps quarantine the entire page',
      () async {
    for (final params in [
      [1, 8, 1, 1, 2, 0],
      [0, 8, 3, 1, 2, 0],
      [0, 9, 1, 1, 2, 0],
      [0, 8, 1, 1, 3, 0]
    ]) {
      final project = await _events([
        _page([
          _command(201, params),
          _command(123, ['A', 0])
        ])
      ]);
      expect(_analyzer(project).analyze().requireEvent(1, 1).isQuarantined,
          isTrue);
    }
  });

  test(
      'script groups remain inert and dependent effects are quarantined together',
      () async {
    final project = await _events([
      _page([
        _command(355, ['remove_money()']),
        _command(655, ['dynamic()']),
        _command(355, ['reward()']),
        _command(123, ['A', 0]),
        _command(0, []),
      ])
    ]);
    final event = _analyzer(project).analyze().requireEvent(1, 1);
    final block = event.pages.single.body;
    expect(event.isQuarantined, isTrue);
    expect(block.isQuarantined, isTrue);
    expect(block.nodes, hasLength(2));
    final script = block.nodes.first as SourceScriptNode;
    expect(script.script, 'remove_money()\ndynamic()\nreward()\n');
    expect(script.span.lastCommandIndex, 2);
    expect(block.span.lastCommandIndex, 4);
  });

  test('unknown nested branch quarantines its page without flattening siblings',
      () async {
    final project = await _events([
      _page([
        _command(111, [0, 1, 0]),
        _command(999, [], indent: 1),
        _command(411, []),
        _command(123, ['A', 0], indent: 1),
        _command(412, []),
      ])
    ]);
    final event = _analyzer(project).analyze().requireEvent(1, 1);
    final conditional =
        event.pages.single.body.nodes.single as SourceConditionalNode;
    expect(event.isQuarantined, isTrue);
    expect(conditional.whenTrue.nodes.single, isA<SourceUnknownNode>());
    expect(conditional.whenFalse.nodes.single, isA<SourceSelfSwitchNode>());
  });

  test(
      'malformed block structure and terminal command cannot expose suffix effects',
      () async {
    for (final commands in [
      [
        _command(111, [0, 1, 0]),
        _command(123, ['A', 0])
      ],
      [
        _command(401, ['orphan']),
        _command(123, ['A', 0])
      ],
      [
        _command(0, []),
        _command(123, ['A', 0])
      ],
      [
        _command(111, [0, 1, 0]),
        _command(999, [], indent: 1)
      ],
    ]) {
      final project = await _events([_page(commands)]);
      expect(_analyzer(project).analyze().requireEvent(1, 1).isQuarantined,
          isTrue);
    }
  });

  test(
      'unqualified oracle and mismatched project bindings cannot enable events',
      () async {
    final project = await _events([_page([])]);
    expect(
        _analyzer(project, scriptsHash: 'a' * 64)
            .analyze()
            .requireEvent(1, 1)
            .isQuarantined,
        isTrue);
    final wrong = SourceEventProfile.kanto(
        scriptsArchiveHash:
            Sha256Hash(SourceEventProfile.kantoScriptsArchiveSha256),
        sourceSnapshotHash: _hash([9]),
        normalizationHash: project.canonicalHash);
    expect(
        SourceEventAnalyzer.forProject(project, profile: wrong)
            .analyze()
            .requireEvent(1, 1)
            .isQuarantined,
        isTrue);
  });

  test('published analysis nodes branches and conditions are immutable',
      () async {
    final analysis = _analyzer(await _events([
      _page([
        _command(101, ['Hi'])
      ])
    ]))
        .analyze();
    final event = analysis.requireEvent(1, 1);
    final page = event.pages.single;
    expect(() => analysis.events.clear(), throwsUnsupportedError);
    expect(() => event.pages.clear(), throwsUnsupportedError);
    expect(() => page.body.nodes.clear(), throwsUnsupportedError);
    expect(() => page.condition.children.clear(), throwsUnsupportedError);
  });

  test('deep command nesting is rejected before recursive AST allocation',
      () async {
    final commands = [
      for (var depth = 0; depth < 130; depth++)
        _command(111, [0, 1, 0], indent: depth),
      _command(123, ['A', 0], indent: 130),
      for (var depth = 129; depth >= 0; depth--)
        _command(412, [], indent: depth),
      _command(0, []),
    ];
    final result = _analyzer(await _events([_page(commands)])).analyze();
    expect(result.requireEvent(1, 1).isQuarantined, isTrue);
    expect(result.diagnostics.map((diagnostic) => diagnostic.code),
        contains('events.command_depth_exceeded'));
  });

  test('adjacent Essentials choices remain wholly non-executable', () async {
    final choice = [
      _command(102, [
        ['One'],
        0
      ]),
      _command(402, [0, 'One']),
      _command(123, ['A', 0], indent: 1),
      _command(404, []),
    ];
    final result = _analyzer(await _events([
      _page([...choice, ...choice])
    ]))
        .analyze();
    expect(result.requireEvent(1, 1).isQuarantined, isTrue);
    expect(result.diagnostics.map((diagnostic) => diagnostic.code),
        contains('events.adjacent_choice_merge_unqualified'));
  });

  test(
      'preservation markers and malformed graphics cannot masquerade as typed values',
      () async {
    final page = _page([
      _command(121, [1, _RubyObject('Unknown', {}), 0])
    ]);
    (page.fields['@graphic'] as _RubyObject).fields['@direction'] = 7;
    final result = _analyzer(await _events([page])).analyze();
    expect(result.requireEvent(1, 1).isQuarantined, isTrue);
    expect(result.requireEvent(1, 1).pages.single.graphic, isNull);
    expect(result.diagnostics.map((diagnostic) => diagnostic.code),
        contains('events.invalid_command_parameters'));
  });
}
