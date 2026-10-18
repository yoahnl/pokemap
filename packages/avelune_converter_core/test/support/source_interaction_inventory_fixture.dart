import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;

final class _RubyObject {
  _RubyObject(this.className, this.fields);
  final String className;
  final Map<String, Object?> fields;
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
    if (value is double) {
      final bytes = ascii.encode(value.toString());
      return [0x66, ..._packed(bytes.length), ...bytes];
    }
    if (value is String) {
      final bytes = utf8.encode(value);
      return [0x22, ..._packed(bytes.length), ...bytes];
    }
    if (value is List) {
      return [
        0x5b,
        ..._packed(value.length),
        for (final item in value) ..._value(item),
      ];
    }
    if (value is Map) {
      return [
        0x7b,
        ..._packed(value.length),
        for (final entry in value.entries) ...[
          ..._value(entry.key),
          ..._value(entry.value),
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
          ..._value(entry.value),
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
          _RubyTable(
            width,
            height,
            3,
            List.generate(width * height * 3, (i) => 384 + i),
          ),
      '@events': events ?? <int, Object?>{},
      '@autoplay_bgm': false,
      '@bgm': _RubyObject('RPG::AudioFile', {
        '@name': '',
        '@volume': 80,
        '@pitch': 100,
      }),
      '@autoplay_bgs': false,
      '@bgs': _RubyObject('RPG::AudioFile', {
        '@name': '',
        '@volume': 80,
        '@pitch': 100,
      }),
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
      '@passages': _RubyTable(
        512,
        1,
        1,
        List.generate(512, (i) => i % 16),
        dimensions: 1,
      ),
      '@priorities': _RubyTable(
        512,
        1,
        1,
        List.generate(512, (i) => i % 6),
        dimensions: 1,
      ),
      '@terrain_tags': _RubyTable(
        512,
        1,
        1,
        List.generate(512, (i) => i % 8),
        dimensions: 1,
      ),
    });

_RubyObject _command(int code, List<Object?> parameters, {int indent = 0}) =>
    _RubyObject('RPG::EventCommand', {
      '@code': code,
      '@indent': indent,
      '@parameters': parameters,
    });

_RubyObject _page(
  List<_RubyObject> commands, {
  int trigger = 0,
  String character = '',
}) =>
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
              'RPG::MoveCommand', {'@code': 0, '@parameters': <Object?>[]}),
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
    _RubyObject('RPG::Event', {
      '@id': id,
      '@name': 'Event $id',
      '@x': x,
      '@y': y,
      '@pages': pages,
    });

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
      'IDAT',
      ZLibEncoder().convert(List.filled(96 * (1 + 256 * 4), 0)),
    ),
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
    ...checksum.buffer.asUint8List(),
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
    'Data/Tilesets.rxdata': _MarshalFixture().dump([
      null,
      tileset ?? _tileset(),
    ]),
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

_Files _source(
  Map<String, List<int>> bytes, {
  bool reverse = false,
  SourceScanState state = SourceScanState.complete,
  String namespace = 'synthetic-project',
}) {
  final entries = [
    for (final entry in bytes.entries)
      SourceFileEntry(
        fileId: ConverterId(
          'fixture:${base64Url.encode(utf8.encode(entry.key)).replaceAll('=', '')}',
        ),
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
          excerpt: 'Pokemon Essentials v21.1',
        ),
    ],
    state: state,
  );
  return _Files(bytes, snapshot);
}

Future<NormalizedSourceProject> _normalize(
  _Files files, {
  SourceNormalizationLimits limits = const SourceNormalizationLimits(),
  Set<int>? selectedMapIds,
  bool includeEventSystem = false,
  ScanCancellation? cancellation,
}) =>
    const RmxpSourceNormalizer().normalize(
      snapshot: files.snapshot,
      files: files,
      limits: limits,
      selectedMapIds: selectedMapIds,
      includeEventSystem: includeEventSystem,
      cancellation: cancellation,
    );

Future<NormalizedSourceProject> fixture({Set<int>? selectedMapIds}) async {
  final first = _page([
    _command(101, ['=Hello,"world"\nsecond line']),
    _command(201, [0, 8, 1, 1, 2, 0]),
    _command(355, ['dangerous()']),
    _command(999, ['opaque']),
    _command(0, []),
  ], character: 'ObjectOrPerson');
  final empty = _page([_command(0, [])], character: 'Door');
  (empty.fields['@condition'] as _RubyObject).fields['@switch1_valid'] = true;
  final controller = _page([
    _command(121, [1, 1, 0]),
    _command(0, []),
  ], trigger: 4);
  final data = _project(
    maps: {
      1: _map(
        events: {
          1: _event(1, [first, empty]),
          2: _event(2, [controller]),
        },
      ),
      8: _map(),
    },
  );
  return _normalize(_source(data),
      includeEventSystem: true, selectedMapIds: selectedMapIds);
}

SourceEventAnalysis analyze(NormalizedSourceProject source) =>
    SourceEventAnalyzer.forProject(
      source,
      profile: SourceEventProfile.forProject(source),
    ).analyze();

Map<String, List<int>> commonEventCallSourceFiles() => _project(maps: {
      1: _map(events: {
        1: _event(1, [
          _page([
            _command(117, [4]),
            _command(0, [])
          ])
        ])
      }),
    });
