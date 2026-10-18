import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';

final class _RubyObject {
  _RubyObject(this.className, this.fields);
  final String className;
  final Map<String, Object?> fields;
}

final class _RubyFloat {
  const _RubyFloat(this.text);
  final String text;
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
    if (value is _RubyFloat) {
      final bytes = ascii.encode(value.text);
      return [0x66, ..._packed(bytes.length), ...bytes];
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
                ? 'raster'
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
        bool includeConnections = false,
        ScanCancellation? cancellation}) =>
    const RmxpSourceNormalizer().normalize(
        snapshot: files.snapshot,
        files: files,
        limits: limits,
        selectedMapIds: selectedMapIds,
        includeConnections: includeConnections,
        cancellation: cancellation);

void _blocked(NormalizedSourceProject result, {String? file}) {
  expect(result.canPlan, isFalse);
  expect(result.diagnostics.where((item) => item.blocksPlanning), isNotEmpty);
  if (file != null) {
    expect(
        result.diagnostics
            .where((item) => item.blocksPlanning)
            .map((item) => item.locator.file),
        contains(file));
  }
}

SourceSnapshot _connectionSourceSnapshot(Map<String, dynamic> json) =>
    SourceSnapshot(
      logicalProjectNamespace:
          ConverterId(json['logicalProjectNamespace'] as String),
      policyHash: Sha256Hash(json['policyHash'] as String),
      entries: [
        for (final row in json['entries'] as List)
          SourceFileEntry(
              fileId: ConverterId(row['fileId'] as String),
              relativePath: row['relativePath'] as String,
              kind: SourceNodeKind.values.byName(row['kind'] as String),
              byteLength: row['byteLength'] as int,
              sha256: row['sha256'] == null
                  ? null
                  : Sha256Hash(row['sha256'] as String),
              format: row['format'] as String,
              family: row['family'] as String)
      ],
      diagnostics: [
        for (final row in json['diagnostics'] as List)
          SourceScanDiagnostic(
              code: row['code'] as String,
              relativePath: row['relativePath'] as String,
              message: row['message'] as String,
              blocksExtraction: row['blocksExtraction'] as bool,
              relatedPaths: (row['relatedPaths'] as List).cast<String>())
      ],
      excludedPaths: (json['excludedPaths'] as List).cast<String>(),
      profileEvidence: [
        for (final row in json['profileEvidence'] as List)
          SourceProfileEvidence(
              relativePath: row['relativePath'] as String,
              fileHash: Sha256Hash(row['fileHash'] as String),
              version: row['version'] as String,
              line: row['line'] as int,
              excerpt: row['excerpt'] as String)
      ],
      state: SourceScanState.values.byName(json['state'] as String),
    );

final class _ExternalConnectionFiles implements SourceFilePort {
  _ExternalConnectionFiles(this.root, SourceSnapshot snapshot)
      : entries = {for (final entry in snapshot.entries) entry.fileId: entry};
  final String root;
  final Map<ConverterId, SourceFileEntry> entries;
  final reads = <String>[];
  @override
  Future<List<int>> read(ConverterId id) async {
    final entry = entries[id]!;
    if (entry.byteLength > 16777216) {
      throw StateError('External fixture file quota');
    }
    final file = File('$root/${entry.relativePath}');
    if (FileSystemEntity.typeSync(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw StateError('External fixture requires a regular source file');
    }
    final bytes = await file.readAsBytes();
    expect(bytes.length, entry.byteLength);
    expect(_hash(bytes), entry.sha256);
    reads.add(entry.relativePath);
    return bytes;
  }
}

Map<String, List<int>> _connectionProject(List<Object?> rows) {
  _RubyObject map(int width, int height) => _map(
      width: width,
      height: height,
      data: _RubyTable(
          width,
          height,
          3,
          List.generate(
              width * height * 3, (i) => i < width * height ? 384 : 0)));
  return _project(maps: {
    21: map(48, 40),
    83: map(48, 40),
    98: map(72, 61),
    100: map(30, 85),
  })
    ..['Data/map_connections.dat'] = _MarshalFixture().dump(rows);
}

List<Object?> _routeConnections() => [
      [21, 'E', 5, 98, 'W', 0],
      [83, 'E', 0, 98, 'W', 35],
      [98, 'E', 0, 100, 'W', 0],
    ];

void main() {
  group('common event archive census', () {
    Future<NormalizedSourceProject> normalize(_Files files, {bool include = true,
        SourceNormalizationLimits limits = const SourceNormalizationLimits()}) =>
        const RmxpSourceNormalizer().normalize(snapshot: files.snapshot, files: files,
            includeEventSystem: include, limits: limits);
    Map<String, List<int>> input() => _project()..['Data/CommonEvents.rxdata'] =
        _MarshalFixture().dump([null, _RubyObject('RPG::CommonEvent', {
          '@id': 1, '@name': 'Inert', '@trigger': 0, '@switch_id': 1,
          '@list': [_command(355, [r'$game_variables[1] = "ON"']), _command(0, [])],
        })]);
    test('requested inventoried bytes are archived once and bind normalization hash', () async {
      final files = _source(input());
      final omitted = await normalize(files, include: false);
      expect(files.reads, isNot(contains('Data/CommonEvents.rxdata')));
      final included = await normalize(files);
      expect(included.canPlan, isTrue);
      final archived = included.archive.files.values.singleWhere(
          (file) => file.entry.relativePath == 'Data/CommonEvents.rxdata');
      expect(archived.rawBytes, files.bytes['Data/CommonEvents.rxdata']);
      expect(archived.contentHash, _hash(archived.rawBytes));
      expect(files.reads.where((path) => path == 'Data/CommonEvents.rxdata'), hasLength(1));
      expect(included.archive.canonicalHash, isNot(omitted.archive.canonicalHash));
      expect(included.canonicalHash, isNot(omitted.canonicalHash));
      expect(SourceArchive.fromJson(included.archive.toJson()).canonicalHash,
          included.archive.canonicalHash);
    });
    test('absence is legitimate when event system is requested', () async {
      final result = await normalize(_source(_project()));
      expect(result.canPlan, isTrue);
      expect(result.diagnostics.where((d) => d.locator.file == 'Data/CommonEvents.rxdata'), isEmpty);
    });
    test('changed inventoried bytes block before archive admission', () async {
      final files = _source(input());
      files.replacements['Data/CommonEvents.rxdata'] = [4, 8, 48];
      final result = await normalize(files);
      _blocked(result, file: 'Data/CommonEvents.rxdata');
      expect(result.diagnostics.map((d) => d.code), contains('normalization.source_changed'));
    });
    test('malformed Marshal blocks requested common event extraction', () async {
      final files = _source(input()..['Data/CommonEvents.rxdata'] = [4, 8, 255]);
      _blocked(await normalize(files), file: 'Data/CommonEvents.rxdata');
    });
    test('planned common event bytes count before reading', () async {
      final files = _source(input());
      final baseline = await normalize(files, include: false);
      files.reads.clear();
      final result = await normalize(files, limits: SourceNormalizationLimits(
          maxTotalBytes: baseline.archive.files.values.fold(0, (n, file) => n + file.rawBytes.length)));
      _blocked(result);
      expect(files.reads, isEmpty);
    });
    test('common event commands share the normalization command budget', () async {
      final result = await normalize(_source(input()),
          limits: const SourceNormalizationLimits(maxCommands: 1));
      _blocked(result, file: 'Data/CommonEvents.rxdata');
      expect(result.diagnostics.map((d) => d.code), contains('normalization.quota.commands'));
    });
    test('common event parameters share the normalization parameter budget', () async {
      final data = input()..['Data/CommonEvents.rxdata'] = _MarshalFixture().dump([
        null, _RubyObject('RPG::CommonEvent', {'@id': 1, '@name': 'Bounded',
          '@trigger': 0, '@switch_id': 1, '@list': [
            _command(355, ['first()']), _command(355, ['second()']), _command(0, []),
          ]}),
      ]);
      final result = await normalize(_source(data),
          limits: const SourceNormalizationLimits(maxParameterNodes: 1));
      _blocked(result, file: 'Data/CommonEvents.rxdata');
      expect(result.diagnostics.map((d) => d.code), contains('normalization.quota.parameters'));
    });
  });
  group('sealed source digests', () {
    test('normalized digest is reused and equals the uncached JSON oracle',
        () async {
      final source = await _normalize(_source(_project()));
      expect(source.archive.isSealed, isTrue);
      final oracleJson = Map<String, Object?>.from(source.toJson())
        ..remove('archive');
      final oracle = canonicalHashOf(oracleJson,
          limits: const ContractLimits(
              maxNodes: 40000000,
              maxStringCodeUnits: 1048576,
              maxTextCodeUnits: 134217728));
      final first = source.canonicalHash;
      expect(first, oracle);
      expect(source.canonicalHash, same(first));
      expect(source.canonicalHash, same(first));
    });

    test('immutable normalized graph refuses every reachable mutation',
        () async {
      final input = _project(image: false, maps: {
        1: _map(events: {
          1: _event(1, [
            _page([
              _command(101, ['Hello'])
            ])
          ])
        })
      });
      final source = await _normalize(_source(input));
      final first = source.canonicalHash;
      for (final list in <List>[
        source.maps,
        source.connections,
        source.mapHierarchy,
        source.tilesets,
        source.eventImages,
        source.diagnostics,
        source.preservedParameterRefs,
        source.selectedSourceMapIds,
        source.unprocessedSourceMapIds,
        source.tilesets.single.images,
        source.snapshot.entries,
        source.snapshot.excludedPaths,
        source.snapshot.profileEvidence,
        for (final diagnostic in source.diagnostics) diagnostic.relatedPaths,
      ]) {
        expect(() => list.clear(), throwsUnsupportedError);
      }
      void frozenJson(Object? value) {
        if (value is Map) {
          expect(() => value['forged'] = true, throwsUnsupportedError);
          for (final nested in value.values) {
            frozenJson(nested);
          }
        } else if (value is List) {
          expect(() => value.add(null), throwsUnsupportedError);
          for (final nested in value) {
            frozenJson(nested);
          }
        }
      }

      frozenJson(source.maps.single.toJson());
      expect(() => source.archive.files.clear(), throwsUnsupportedError);
      expect(() => source.archive.references.clear(), throwsUnsupportedError);
      for (final file in source.archive.files.values) {
        expect(() => file.rawBytes[0] = 0, throwsUnsupportedError);
        final bytes = file.rawBytes as Uint8List;
        expect(() => bytes.buffer.asUint8List()[0] = 0, throwsUnsupportedError);
        expect(() => file.document.nodes.clear(), throwsUnsupportedError);
        for (final node in file.document.nodes) {
          for (final list in <List>[
            node.elements,
            node.pairs,
            node.instanceVariables,
            node.extensions,
          ]) {
            expect(() => list.clear(), throwsUnsupportedError);
          }
          if (node.bytes case final Uint8List bytes when bytes.isNotEmpty) {
            expect(() => bytes[0] = 0, throwsUnsupportedError);
            expect(() => bytes.buffer.asUint8List()[0] = 0,
                throwsUnsupportedError);
          }
        }
      }
      for (final bytes in input.values) {
        if (bytes.isNotEmpty) bytes[0] = 0;
      }
      final exported = source.toJson();
      exported['sourceProfileId'] = 'changed-only-in-export';
      expect(source.canonicalHash, first);
      expect(
          source.toJson()['sourceProfileId'], isNot('changed-only-in-export'));
    });

    test(
        'a new normalization has an independent digest for changed source bytes',
        () async {
      final first = await _normalize(_source(_project()));
      final second =
          await _normalize(_source(_project(maps: {1: _map(width: 4)})));
      expect(first.maps.single.map.sourceMapId,
          second.maps.single.map.sourceMapId);
      expect(first.canonicalHash, isNot(second.canonicalHash));
      expect(first.archive.canonicalHash, isNot(second.archive.canonicalHash));
      final equivalent = await _normalize(_source(_project()));
      expect(equivalent.canonicalHash, first.canonicalHash);
      expect(equivalent.canonicalHash, isNot(same(first.canonicalHash)));
    });
  });

  test(
      'explicit atlas image binding resolves a missing reference with provenance',
      () async {
    final bytes = _project(image: false)
      ..['Graphics/Tilesets/Terrain_backup.png'] = _png();
    final files = _source(bytes);
    final binding = SourceImageBinding(
      expectedReferencePath: 'Graphics/Tilesets/Terrain',
      sourceRelativePath: 'Graphics/Tilesets/Terrain_backup.png',
      sourceSha256: _hash(_png()),
    );
    final missing = await _normalize(files);
    _blocked(missing);
    final resolved = await const RmxpSourceNormalizer().normalize(
      snapshot: files.snapshot,
      files: files,
      imageBindings: [binding],
    );
    expect(resolved.canPlan, isTrue);
    final image = resolved.tilesets.single.images
        .singleWhere((image) => image.sourceName == 'Terrain');
    expect(image.state, 'resolved');
    expect(image.sourceName, 'Terrain');
    expect(image.locator.file, 'Data/Tilesets.rxdata');
    expect(image.sourceFile!.relativePath, binding.sourceRelativePath);
    expect(image.sourceFile!.sha256, binding.sourceSha256);
    expect(image.appliedImageBinding!.toJson(), binding.toJson());
    expect(resolved.snapshot.canonicalHash, files.snapshot.canonicalHash);
    expect(resolved.canonicalHash, isNot(missing.canonicalHash));
    expect(resolved.diagnostics.map((d) => d.code),
        contains('normalization.image_binding_applied'));
    expect(bytes.containsKey('Graphics/Tilesets/Terrain.png'), isFalse);
    expect(SourceImageBinding.fromJson(binding.toJson()).toJson(),
        binding.toJson());
  });

  test('atlas image bindings reject unattested files and duplicate decisions',
      () async {
    final bytes = _project(image: false)
      ..['Graphics/Tilesets/Terrain_backup.png'] = _png();
    final files = _source(bytes);
    SourceImageBinding binding(String path, Sha256Hash hash) =>
        SourceImageBinding(
          expectedReferencePath: 'Graphics/Tilesets/Terrain',
          sourceRelativePath: path,
          sourceSha256: hash,
        );
    for (final bindings in [
      [binding('Graphics/Tilesets/absent.png', _hash(_png()))],
      [
        binding('Graphics/Tilesets/Terrain_backup.png', _hash([1]))
      ],
      [
        binding('Graphics/Tilesets/Terrain_backup.png', _hash(_png())),
        binding('Graphics/Tilesets/Terrain_backup.png', _hash(_png())),
      ],
    ]) {
      final resolved = await const RmxpSourceNormalizer().normalize(
        snapshot: files.snapshot,
        files: files,
        imageBindings: bindings,
      );
      _blocked(resolved);
      expect(resolved.diagnostics.map((d) => d.code),
          contains('normalization.image_binding.invalid'));
    }
    for (final reference in ['../Terrain', 'Graphics/Characters/Trainer']) {
      expect(
        () => SourceImageBinding(
          expectedReferencePath: reference,
          sourceRelativePath: 'Graphics/Tilesets/Terrain_backup.png',
          sourceSha256: _hash(_png()),
        ),
        throwsA(isA<ContractError>()),
      );
    }
  });

  test('atlas image bindings never replace resolved images or disappear unused',
      () async {
    final files =
        _source(_project()..['Graphics/Tilesets/Terrain_backup.png'] = _png());
    for (final reference in [
      'Graphics/Tilesets/Terrain',
      'Graphics/Tilesets/Unused',
    ]) {
      final resolved = await const RmxpSourceNormalizer().normalize(
        snapshot: files.snapshot,
        files: files,
        imageBindings: [
          SourceImageBinding(
            expectedReferencePath: reference,
            sourceRelativePath: 'Graphics/Tilesets/Terrain_backup.png',
            sourceSha256: _hash(_png()),
          ),
        ],
      );
      _blocked(resolved);
      expect(
          resolved.diagnostics.map((d) => d.code),
          contains(anyOf('normalization.image_binding.unneeded',
              'normalization.image_binding.unused')));
      expect(
          resolved.tilesets.single.images
              .singleWhere((image) => image.sourceName == 'Terrain')
              .sourceFile!
              .relativePath,
          'Graphics/Tilesets/Terrain.png');
    }
  });

  test(
      'atlas image bindings freeze choices and select an ambiguous source explicitly',
      () async {
    final files =
        _source(_project()..['Graphics/Tilesets/Terrain.bmp'] = [1, 2, 3]);
    final binding = SourceImageBinding(
      expectedReferencePath: 'Graphics/Tilesets/Terrain',
      sourceRelativePath: 'Graphics/Tilesets/Terrain.png',
      sourceSha256: _hash(_png()),
    );
    final choices = [binding];
    files.onRead = (_) => choices.clear();
    final resolved = await const RmxpSourceNormalizer().normalize(
      snapshot: files.snapshot,
      files: files,
      imageBindings: choices,
    );
    expect(choices, isEmpty);
    expect(resolved.canPlan, isTrue);
    final image = resolved.tilesets.single.images
        .singleWhere((image) => image.sourceName == 'Terrain');
    expect(image.appliedImageBinding, binding);
    expect(image.sourceFile!.relativePath, binding.sourceRelativePath);
  });

  test('atlas image bindings reject malformed transports and preserve quotas',
      () async {
    final hash = _hash(_png());
    for (final source in [
      'Terrain.png',
      '/tmp/Terrain.png',
      'Graphics/Autotiles/Terrain.png',
      'Graphics/Tilesets/Terrain.txt'
    ]) {
      expect(
          () => SourceImageBinding(
                expectedReferencePath: 'Graphics/Tilesets/Terrain',
                sourceRelativePath: source,
                sourceSha256: hash,
              ),
          throwsA(isA<ContractError>()));
    }
    final binding = SourceImageBinding(
      expectedReferencePath: 'Graphics/Tilesets/Terrain',
      sourceRelativePath: 'Graphics/Tilesets/Terrain_backup.png',
      sourceSha256: hash,
    );
    for (final json in [
      {...binding.toJson(), 'unexpected': true},
      {...binding.toJson(), 'version': 0},
      {...binding.toJson(), 'sourceSha256': 'wrong'},
    ]) {
      expect(() => SourceImageBinding.fromJson(json),
          throwsA(isA<ContractError>()));
    }
    final files = _source(_project(image: false)
      ..['Graphics/Tilesets/Terrain_backup.png'] = _png());
    await expectLater(
        const RmxpSourceNormalizer().normalize(
          snapshot: files.snapshot,
          files: files,
          imageBindings: List.filled(257, binding),
        ),
        throwsA(isA<ContractError>()));
    expect(files.reads, isEmpty);
  });

  test('map hierarchy inspection reads names without decoding map content',
      () async {
    final bytes = _project(maps: {1: _map(), 8: _map()})
      ..['Data/Map008.rxdata'] = [4, 8, 0xff]
      ..['Data/Tilesets.rxdata'] = [4, 8, 0xff];
    final files = _source(bytes);
    final result = await const RmxpSourceNormalizer().inspectMapHierarchy(
      snapshot: files.snapshot,
      files: files,
    );
    expect(files.reads, ['Data/MapInfos.rxdata']);
    expect(result.maps, isEmpty);
    expect(result.tilesets, isEmpty);
    expect(result.selectedSourceMapIds, isEmpty);
    expect(result.mapHierarchy.map((info) => info.sourceMapId), [1, 8]);
    expect(result.mapHierarchy.every((info) => info.name.isNotEmpty), isTrue);
    expect(result.diagnostics, isEmpty);
  });

  test('map hierarchy inspection keeps source integrity and admission guards',
      () async {
    final changed = _source(_project());
    changed.replacements['Data/MapInfos.rxdata'] = [4, 8, 0xff];
    final changedResult =
        await const RmxpSourceNormalizer().inspectMapHierarchy(
      snapshot: changed.snapshot,
      files: changed,
    );
    _blocked(changedResult, file: 'Data/MapInfos.rxdata');
    expect(changedResult.diagnostics.map((d) => d.code),
        contains('normalization.source_changed'));
    final partial = _source(_project(), state: SourceScanState.partial);
    await expectLater(
      const RmxpSourceNormalizer().inspectMapHierarchy(
        snapshot: partial.snapshot,
        files: partial,
      ),
      throwsA(isA<ContractError>()
          .having((e) => e.code, 'code', 'normalization.incomplete_snapshot')),
    );
    expect(partial.reads, isEmpty);
    final bounded = _source(_project());
    final boundedResult =
        await const RmxpSourceNormalizer().inspectMapHierarchy(
      snapshot: bounded.snapshot,
      files: bounded,
      limits: const SourceNormalizationLimits(maxTotalBytes: 1),
    );
    _blocked(boundedResult);
    expect(bounded.reads, isEmpty);
    final cancelled = _source(_project());
    final token = ScanCancellation()..cancel();
    await expectLater(
      const RmxpSourceNormalizer().inspectMapHierarchy(
        snapshot: cancelled.snapshot,
        files: cancelled,
        cancellation: token,
      ),
      throwsA(isA<ContractError>()
          .having((e) => e.code, 'code', 'source.cancelled')),
    );
    expect(cancelled.reads, isEmpty);
  });

  test('CONN-01 distinguishes unrequested, missing and extracted empty graph',
      () async {
    final unrequested = _source(_connectionProject(_routeConnections()));
    final first = await _normalize(unrequested, selectedMapIds: {98, 100});
    expect(first.connectionsState, SourceConnectionsState.notRequested);
    expect(first.connectionsExtracted, isFalse);
    expect(first.connections, isEmpty);
    expect(unrequested.reads, isNot(contains('Data/map_connections.dat')));
    final missing =
        await _normalize(_source(_project()), includeConnections: true);
    expect(missing.connectionsState, SourceConnectionsState.missing);
    expect(missing.connectionsExtracted, isFalse);
    _blocked(missing, file: 'Data/map_connections.dat');
    final empty = await _normalize(_source(_connectionProject([])),
        selectedMapIds: {98, 100}, includeConnections: true);
    expect(empty.canPlan, isTrue);
    expect(empty.connectionsState, SourceConnectionsState.extracted);
    expect(empty.connectionsExtracted, isTrue);
    expect(empty.connections, isEmpty);
  });

  test('CONN-02 preserves whole ordered graph and split west outside selection',
      () async {
    final files = _source(_connectionProject(_routeConnections()));
    final result = await _normalize(files,
        selectedMapIds: {98, 100}, includeConnections: true);
    expect(result.canPlan, isTrue);
    expect(result.connectionsExtracted, isTrue);
    expect(result.connections.map((row) => row.sourceRowIndex), [0, 1, 2]);
    expect(result.connections.map((row) => row.sourceMapId), [21, 83, 98]);
    expect(result.connections.map((row) => row.nativeOffset), [5, -35, 0]);
    expect(result.connections.last.sourceDirection,
        SourceConnectionDirection.east);
    expect(result.connections.last.targetDirection,
        SourceConnectionDirection.west);
    expect(result.connections.last.sourceDirection.opposite,
        SourceConnectionDirection.west);
    expect(result.maps.map((map) => map.map.sourceMapId), [98, 100]);
    expect(files.reads.where((path) => path == 'Data/map_connections.dat'),
        hasLength(1));
    expect(files.reads, isNot(contains('Data/Map021.rxdata')));
    expect(files.reads, isNot(contains('Data/Map083.rxdata')));
    final file = result.archive.files[result.connectionsFileId]!;
    expect(file.rawBytes, files.bytes['Data/map_connections.dat']);
    final row = result.connections.last;
    expect(row.locator.file, 'Data/map_connections.dat');
    expect(row.rawDataRef.binaryLocation.byteOffset, greaterThan(0));
    expect(row.rawDataRef.binaryLocation.graphPath, contains('[2]'));
    expect(row.toJson()['nativeOffset'], 0);
    expect(row.toJson()['sourceDirection'], 'E');
    expect(result.toJson()['extractorVersion'], 'rmxp-normalization-v6');
  });

  test(
      'CONN-03 identity is independent from manifest selection and signed coordinates',
      () async {
    final bytes = _connectionProject([
      [98, 'N', -12, 100, 'S', 3]
    ]);
    final a = await _normalize(_source(bytes),
        selectedMapIds: {98, 100}, includeConnections: true);
    final b = await _normalize(_source(bytes, reverse: true),
        selectedMapIds: {98}, includeConnections: true);
    expect(a.canPlan, isTrue);
    expect(b.canPlan, isTrue);
    expect(a.connections.single.identity, b.connections.single.identity);
    expect(a.connections.single.nativeOffset, -15);
    expect(a.connections.single.sourceDirection.sourceCode, 'N');
    expect(a.connections.single.targetDirection.sourceCode, 'S');
    expect(a.connections.single.sourceDirection.opposite,
        SourceConnectionDirection.south);
  });

  test('CONN-04 malformed row cannot become a partially admitted graph',
      () async {
    final rows = [
      ..._routeConnections(),
      [98, 'E', 0, 100, 'W']
    ];
    final files = _source(_connectionProject(rows));
    final result = await _normalize(files,
        selectedMapIds: {98, 100}, includeConnections: true);
    _blocked(result, file: 'Data/map_connections.dat');
    expect(result.connectionsState, SourceConnectionsState.invalid);
    expect(result.connectionsExtracted, isFalse);
    expect(result.connections, isEmpty);
    expect(result.archive.files[result.connectionsFileId]!.rawBytes,
        files.bytes['Data/map_connections.dat']);
  });

  for (final rows in [
    [
      [98, 'East', 0, 100, 'W', 0]
    ],
    [
      [98, 'E', 0, 100, 'N', 0]
    ],
    [
      [98, 'E', 0, 98, 'W', 0]
    ],
    [
      [98, 'E', 2147483648, 100, 'W', 0]
    ],
    [
      [98, 'E', _RubyFloat('0.5'), 100, 'W', 0]
    ],
    [
      [98, 'E', 0, 999, 'W', 0]
    ],
  ]) {
    test('CONN-05 rejects invalid endpoints, edges or bounded offsets $rows',
        () async {
      final result = await _normalize(_source(_connectionProject(rows)),
          selectedMapIds: {98, 100}, includeConnections: true);
      _blocked(result, file: 'Data/map_connections.dat');
      expect(result.connectionsState, SourceConnectionsState.invalid);
      expect(result.connectionsExtracted, isFalse);
    });
  }

  test(
      'CONN-06 duplicate literal rows remain visible and block without overwrite',
      () async {
    final row = [98, 'E', 0, 100, 'W', 0];
    final result = await _normalize(_source(_connectionProject([row, row])),
        selectedMapIds: {98, 100}, includeConnections: true);
    _blocked(result, file: 'Data/map_connections.dat');
    expect(result.diagnostics.map((d) => d.code),
        contains('normalization.connection.duplicate'));
    expect(result.connectionsExtracted, isFalse);
    expect(result.archive.files[result.connectionsFileId], isNotNull);
  });

  test('CONN-07 record quota is cumulative and never silently truncates',
      () async {
    final result = await _normalize(
        _source(_connectionProject(_routeConnections())),
        selectedMapIds: {98, 100},
        includeConnections: true,
        limits: const SourceNormalizationLimits(maxConnections: 2));
    _blocked(result, file: 'Data/map_connections.dat');
    expect(result.connectionsExtracted, isFalse);
    expect(result.connections, isEmpty);
  });

  test('CONN-08 source drift is refused before archiving connections',
      () async {
    final files = _source(_connectionProject(_routeConnections()));
    files.replacements['Data/map_connections.dat'] = _MarshalFixture().dump([]);
    final result = await _normalize(files,
        selectedMapIds: {98, 100}, includeConnections: true);
    _blocked(result, file: 'Data/map_connections.dat');
    expect(result.connectionsExtracted, isFalse);
    expect(
        result.archive.files.values.any(
            (file) => file.entry.relativePath == 'Data/map_connections.dat'),
        isFalse);
  });

  test('CONN-09 cancellation at graph read escapes without a partial result',
      () async {
    final files = _source(_connectionProject(_routeConnections()));
    final cancellation = ScanCancellation();
    files.onRead = (path) {
      if (path == 'Data/map_connections.dat') cancellation.cancel();
    };
    await expectLater(
        _normalize(files,
            selectedMapIds: {98, 100},
            includeConnections: true,
            cancellation: cancellation),
        throwsA(isA<ContractError>()
            .having((e) => e.code, 'code', 'source.cancelled')));
  });

  test(
      'CONN-10 graph values are immutable and graph changes alter normalization hash',
      () async {
    final a = await _normalize(_source(_connectionProject(_routeConnections())),
        selectedMapIds: {98, 100}, includeConnections: true);
    final b = await _normalize(
        _source(_connectionProject(_routeConnections().reversed.toList())),
        selectedMapIds: {98, 100},
        includeConnections: true);
    expect(() => a.connections.clear(), throwsUnsupportedError);
    expect(a.canonicalHash, isNot(b.canonicalHash));
    expect(a.connections.map((row) => row.identity).toSet(),
        b.connections.map((row) => row.identity).toSet());
  });

  test('CONN-11 endpoints require unselected MapInfos and inventoried files',
      () async {
    for (final missingInfo in [true, false]) {
      final bytes = _connectionProject(_routeConnections());
      if (missingInfo) {
        bytes['Data/MapInfos.rxdata'] = _MarshalFixture().dump({
          83: _mapInfo('Map83'),
          98: _mapInfo('Map98'),
          100: _mapInfo('Map100'),
        });
      } else {
        bytes.remove('Data/Map021.rxdata');
      }
      final files = _source(bytes);
      final result = await _normalize(files,
          selectedMapIds: {98, 100}, includeConnections: true);
      _blocked(result, file: 'Data/map_connections.dat');
      expect(result.connectionsState, SourceConnectionsState.invalid);
      expect(result.diagnostics.map((item) => item.code),
          contains('normalization.connection.map_reference'));
      expect(files.reads, isNot(contains('Data/Map021.rxdata')));
    }
  });

  test('CONN-12 graph root and cyclic non-scalar fields stay inert and blocked',
      () async {
    final cyclic = <Object?>[98, 'E', 0, 100, 'W', null];
    cyclic[5] = cyclic;
    for (final graph in [
      <int, Object?>{
        1: [98, 'E', 0, 100, 'W', 0]
      },
      [cyclic]
    ]) {
      final bytes = _connectionProject([])
        ..['Data/map_connections.dat'] = _MarshalFixture().dump(graph);
      final result = await _normalize(_source(bytes),
          selectedMapIds: {98, 100}, includeConnections: true);
      _blocked(result, file: 'Data/map_connections.dat');
      expect(result.connections, isEmpty);
      expect(result.connectionsState, SourceConnectionsState.invalid);
      expect(result.archive.files[result.connectionsFileId]!.rawBytes,
          bytes['Data/map_connections.dat']);
    }
  });

  test('CONN-13 declared graph bytes join aggregate pre-read admission',
      () async {
    final bytes = _connectionProject(_routeConnections());
    final paths = [
      'Data/MapInfos.rxdata',
      'Data/Tilesets.rxdata',
      'Data/Map098.rxdata',
      'Data/Map100.rxdata',
      'Data/map_connections.dat'
    ];
    final budget =
        paths.fold<int>(0, (sum, path) => sum + bytes[path]!.length) - 1;
    final files = _source(bytes);
    final result = await _normalize(files,
        selectedMapIds: {98, 100},
        includeConnections: true,
        limits: SourceNormalizationLimits(maxTotalBytes: budget));
    _blocked(result);
    expect(files.reads, isEmpty);
    expect(result.connectionsExtracted, isFalse);
  });

  test('CONN-14 graph record projections reserve cumulative IR budget',
      () async {
    final result = await _normalize(
        _source(_connectionProject(_routeConnections())),
        selectedMapIds: {98, 100},
        includeConnections: true,
        limits: const SourceNormalizationLimits(maxTotalIrNodes: 110));
    _blocked(result, file: 'Data/map_connections.dat');
    expect(result.diagnostics.map((item) => item.code),
        contains('normalization.quota.ir_nodes'));
    expect(result.connectionsExtracted, isFalse);
    expect(result.connections, isEmpty);
  });

  final externalRoot = Platform.environment['AVELUNE_CONNECTION_SOURCE_ROOT'];
  final externalSnapshot =
      Platform.environment['AVELUNE_CONNECTION_SOURCE_SNAPSHOT'];
  test('CONN-15 attested real Kanto 98 and 100 retain whole compiled graph',
      () async {
    final file = File(externalSnapshot!);
    expect(file.lengthSync(), lessThanOrEqualTo(16777216));
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final snapshot = _connectionSourceSnapshot(json);
    expect(snapshot.canonicalHash.value, json['canonicalHash']);
    final files = _ExternalConnectionFiles(externalRoot!, snapshot);
    final result = await const RmxpSourceNormalizer().normalize(
        snapshot: snapshot,
        files: files,
        selectedMapIds: {98, 100},
        includeConnections: true);
    expect(result.diagnostics.where((item) => item.blocksPlanning), isEmpty);
    expect(result.canPlan, isTrue);
    expect(result.connectionsExtracted, isTrue);
    expect(result.maps.map((map) => map.map.sourceMapId), [98, 100]);
    final east = result.connections.singleWhere(
        (row) => row.sourceMapId == 98 && row.targetSourceMapId == 100);
    expect(east.sourceDirection, SourceConnectionDirection.east);
    expect(east.targetDirection, SourceConnectionDirection.west);
    expect(east.nativeOffset, 0);
    expect(
        result.connections
            .where((row) => row.targetSourceMapId == 98)
            .map((row) => row.sourceMapId),
        containsAll([21, 83]));
    expect(result.archive.files[result.connectionsFileId]!.contentHash.value,
        '7afe966d8f6710be30b463d7993029176e4f3fa6ac46e9f0ffc74749211648ef');
    expect(files.reads, isNot(contains('Data/Map021.rxdata')));
    expect(files.reads, isNot(contains('Data/Map083.rxdata')));
    for (final path in files.reads) {
      final entry =
          snapshot.entries.singleWhere((entry) => entry.relativePath == path);
      expect(
          _hash(await File('$externalRoot/$path').readAsBytes()), entry.sha256);
    }
    print(jsonEncode({
      'kind': 'realConnectionNormalization',
      'sourceSnapshotHash': snapshot.canonicalHash.value,
      'normalizedSourceHash': result.canonicalHash.value,
      'connectionCount': result.connections.length,
      'selectedMapIds': result.selectedSourceMapIds,
      'routeConnection': east.toJson(),
      'readPaths': files.reads
    }));
  }, skip: externalRoot == null || externalSnapshot == null);

  test('synthetic Marshal oracle has exact axes, cycles and nonfinite nodes',
      () {
    final map = _map();
    map.fields['@plugin_cycle'] = map;
    map.fields['@plugin_infinity'] = const _RubyFloat('inf');
    final bytes = _MarshalFixture().dump(map);
    final document =
        const MarshalDecoder().decode(bytes, sourcePath: 'Data/Map001.rxdata');
    expect(document.node(document.rootId).className, 'RPG::Map');
    final root = document.node(document.rootId);
    final values = {
      for (final pair in root.instanceVariables)
        document.node(pair.key).name: pair.value
    };
    expect(values['@plugin_cycle'], document.rootId);
    expect(
        document.node(values['@plugin_infinity']!).floatValue, double.infinity);
    final table = const TableDecoder().decode(document.node(values['@data']!));
    expect([table.xSize, table.ySize, table.zSize], [3, 2, 3]);
    expect(table.valueAt(2, 1, 2), 401);
  });

  test('MAP-01 keeps sparse IDs, duplicate titles and nonspatial parent order',
      () async {
    final files = _source(_project(
      maps: {120: _map(), 1: _map(), 8: _map()},
      infos: {
        120: _mapInfo('Duplicate', parent: 8, order: 4),
        8: _mapInfo('Folder', parent: 1, order: 19),
        1: _mapInfo('Duplicate', order: 2)
      },
    ));
    final result = await _normalize(files);
    expect(result.canPlan, isTrue);
    expect(result.maps.map((map) => map.map.sourceMapId), [1, 8, 120]);
    final infos = {
      for (final info in result.mapHierarchy) info.sourceMapId: info
    };
    expect(infos[120]!.parentSourceMapId, 8);
    expect(infos[8]!.parentSourceMapId, 1);
    expect(infos[8]!.order, 19);
    expect(infos[1]!.name, infos[120]!.name);
    expect(infos[120]!.identity, result.mapIdentity(120));
    expect(infos[120]!.locator.file, 'Data/MapInfos.rxdata');
    expect(infos[120]!.locator.mapId, 120);
  });

  test('MAP-01 map identities survive rename and isolate namespace', () async {
    final first =
        await _normalize(_source(_project(infos: {1: _mapInfo('Before')})));
    final renamed =
        await _normalize(_source(_project(infos: {1: _mapInfo('After')})));
    final other =
        await _normalize(_source(_project(), namespace: 'another-project'));
    expect(first.mapIdentity(1), renamed.mapIdentity(1));
    expect(first.mapIdentity(1), isNot(other.mapIdentity(1)));
    expect(first.canonicalHash, isNot(renamed.canonicalHash));
  });

  test('event identity includes map ID and survives event rename', () async {
    final event = _event(4, [_page([])]);
    final first = await _normalize(_source(_project(maps: {
      1: _map(events: {4: event}),
      8: _map()
    })));
    event.fields['@name'] = 'Renamed event';
    final renamed = await _normalize(_source(_project(maps: {
      1: _map(events: {4: event}),
      8: _map()
    })));
    expect(first.eventIdentity(1, 4), renamed.eventIdentity(1, 4));
    expect(first.eventIdentity(1, 4), isNot(first.eventIdentity(8, 4)));
    expect(first.eventIdentity(1, 4), isNot(first.mapIdentity(4)));
  });

  test('MAP-02 preserves all cells of three non-square layers in source order',
      () async {
    final result = await _normalize(_source(_project()));
    final map = result.maps.single.map;
    expect(
        [map.width, map.height, map.tileWidth, map.tileHeight], [3, 2, 32, 32]);
    expect(map.layers.map((layer) => layer.sourceZ), [0, 1, 2]);
    for (var z = 0; z < 3; z++) {
      expect(map.layers[z].cells, List.generate(6, (i) => 384 + z * 6 + i));
    }
    expect(
        map.sourceFileId,
        result.snapshot.entries
            .singleWhere((entry) => entry.relativePath == 'Data/Map001.rxdata')
            .fileId);
  });

  test(
      'tileset raw tables and image provenance remain separate from map layers',
      () async {
    final result = await _normalize(_source(_project()));
    final tileset = result.tilesets.single;
    expect(tileset.sourceTilesetId, 1);
    expect(tileset.passages.valueAt(399, 0, 0), 15);
    expect(tileset.priorities.valueAt(399, 0, 0), 3);
    expect(tileset.terrainTags.valueAt(399, 0, 0), 7);
    final image =
        tileset.images.singleWhere((image) => image.sourceName == 'Terrain');
    expect(image.sourceFile!.relativePath, 'Graphics/Tilesets/Terrain.png');
    expect(image.sourceFile!.sha256, _hash(_png()));
    expect(image.locator.file, 'Data/Tilesets.rxdata');
    expect(tileset.rawDataRef.status, 'preservedOnly');
  });

  test('MAP-03 missing tileset image is a precise planning blocker', () async {
    final result = await _normalize(_source(_project(image: false)));
    _blocked(result, file: 'Data/Tilesets.rxdata');
    expect(
        result.tilesets.single.images
            .where((image) => image.sourceName == 'Terrain')
            .single
            .sourceFile,
        isNull);
    expect(
        result.diagnostics.any((item) =>
            item.blocksPlanning &&
            (item.message.contains('Terrain') ||
                item.relatedPaths.any((path) => path.contains('Terrain')))),
        isTrue);
    expect(result.maps.single.map.layers.first.cells,
        [384, 385, 386, 387, 388, 389]);
  });

  test('used empty autotile slot cannot silently become empty tiles', () async {
    final result = await _normalize(_source(_project(maps: {
      1: _map(data: _RubyTable(3, 2, 3, [48, ...List.filled(17, 0)]))
    })));
    _blocked(result);
    expect(result.maps.single.map.layers.first.cells.first, 48);
  });

  test(
      'MAP-04 preserves unknown cyclic and nonfinite data by exact source archive',
      () async {
    final sourceMap = _map();
    sourceMap.fields['@plugin_cycle'] = sourceMap;
    sourceMap.fields['@plugin_infinity'] = const _RubyFloat('inf');
    final files = _source(_project(maps: {1: sourceMap}));
    final result = await _normalize(files);
    expect(result.maps.single.map.unknownDataRefs,
        hasLength(greaterThanOrEqualTo(2)));
    final restored = SourceArchive.fromJson(result.archive.toJson());
    expect(restored.canonicalHash, result.archive.canonicalHash);
    final fileId = result.maps.single.map.sourceFileId;
    final original = files.bytes['Data/Map001.rxdata']!;
    expect(result.archive.files[fileId]!.rawBytes, original);
    expect(restored.files[fileId]!.rawBytes, original);
    expect(restored.files[fileId]!.contentHash, _hash(original));
    final referenced = result.maps.single.map.unknownDataRefs
        .map((id) => restored.references[id]!);
    expect(
        referenced.every(
            (ref) => ref.status == 'preservedOnly' && ref.fileId == fileId),
        isTrue);
    expect(
        referenced.map(
            (ref) => restored.files[fileId]!.document.node(ref.nodeId).kind),
        containsAll([MarshalKind.object, MarshalKind.floating]));
    expect(
        result.diagnostics.any((item) =>
            !item.blocksPlanning && item.locator.file == 'Data/Map001.rxdata'),
        isTrue);
  });

  test('IR-04 extraction and shuffled manifest produce identical canonical IR',
      () async {
    final bytes = _project(
        maps: {8: _map(), 1: _map()},
        infos: {8: _mapInfo('Eight', parent: 1), 1: _mapInfo('One')});
    final first = await _normalize(_source(bytes));
    final second = await _normalize(_source(bytes, reverse: true));
    final third = await _normalize(_source(bytes));
    expect(first.canonicalHash, second.canonicalHash);
    expect(first.canonicalHash, third.canonicalHash);
    expect(jsonEncode(first.toJson()), jsonEncode(second.toJson()));
    expect(first.maps.map((map) => map.canonicalHash),
        second.maps.map((map) => map.canonicalHash));
  });

  test('empty pages and end commands retain original indexes and locators',
      () async {
    final pages = [
      _page([
        _command(101, ['Bonjour']),
        _command(0, [])
      ], trigger: 2),
      _page([])
    ];
    final result = await _normalize(_source(_project(maps: {
      1: _map(events: {
        99: _event(99, pages),
        3: _event(3, [_page([])])
      })
    })));
    final events = result.maps.single.map.events;
    expect(events.map((event) => event.sourceEventId), [3, 99]);
    final event = events.last;
    expect(event.pages.map((page) => page.originalPageIndex), [0, 1]);
    expect(event.pages.last.commands, isEmpty);
    expect(event.pages.first.triggerCode, 2);
    expect(event.pages.first.conditionsDataRef, isNotNull);
    expect(event.pages.first.rawDataRef, isNotNull);
    expect(event.pages.first.commands.map((command) => command.originalIndex),
        [0, 1]);
    final locator = event.pages.first.commands.first.sourceLocator;
    expect([
      locator.file,
      locator.mapId,
      locator.eventId,
      locator.pageIndex,
      locator.commandIndex
    ], [
      'Data/Map001.rxdata',
      1,
      99,
      0,
      0
    ]);
  });

  test(
      'primitive parameters project to JSON while unsupported values keep positions',
      () async {
    final cycle = <Object?>[];
    cycle.add(cycle);
    final parameters = <Object?>[
      null,
      true,
      7,
      'texte',
      [1, 'nested'],
      _RubyObject('Plugin::Payload', {'@answer': 8}),
      const _RubyFloat('nan'),
      <Object?, Object?>{'preservedDataRef': 'literal-source-value'},
      const _RubyBytes([255]),
      cycle,
    ];
    final result = await _normalize(_source(_project(maps: {
      1: _map(events: {
        4: _event(4, [
          _page([_command(355, parameters)])
        ])
      })
    })));
    final command =
        result.maps.single.map.events.single.pages.single.commands.single;
    expect(command.parameters.take(5), [
      null,
      true,
      7,
      'texte',
      [1, 'nested']
    ]);
    expect(command.parameters, hasLength(parameters.length));
    final refs = result.toJson()['preservedParameterRefs'] as List;
    expect(refs, hasLength(5));
    expect(refs.map((ref) => (ref as Map)['parameterIndex']), [5, 6, 7, 8, 9]);
    for (var i = 5; i < command.parameters.length; i++) {
      final marker = command.parameters[i] as Map;
      expect(marker.keys, ['preservedDataRef']);
      final ref = result.archive
          .references[ConverterId(marker['preservedDataRef'] as String)]!;
      expect(ref.status, 'preservedOnly');
      expect(ref.locator!.commandIndex, 0);
      expect(ref.locator!.eventId, 4);
    }
  });

  test('missing event character stays unresolved without blocking the map',
      () async {
    final result = await _normalize(_source(_project(maps: {
      1: _map(events: {
        2: _event(2, [_page([], character: 'AbsentCharacter')])
      })
    })));
    expect(result.canPlan, isTrue);
    final image = result.eventImages.single;
    expect(image.sourceName, 'AbsentCharacter');
    expect(
        [image.locator.mapId, image.locator.eventId, image.locator.pageIndex],
        [1, 2, 0]);
    expect(image.sourceFile, isNull);
    expect(image.state, 'missing');
    final diagnostic = result.diagnostics
        .singleWhere((item) => item.code == 'normalization.missing_image');
    expect(diagnostic.blocksPlanning, isFalse);
    expect(diagnostic.locator.toJson(), image.locator.toJson());
    expect(diagnostic.relatedPaths, ['Graphics/Characters/AbsentCharacter']);
    expect(result.maps.single.map.events.single.pages.single.rawDataRef,
        isNotNull);
  });

  test('invalid event tile stays unresolved without blocking valid terrain',
      () async {
    final page = _page([]);
    (page.fields['@graphic']! as _RubyObject).fields['@tile_id'] = 647;
    final files = _source(_project(maps: {
      1: _map(events: {2: _event(2, [_page([]), page])})
    }));
    final result = await _normalize(files);
    expect(result.canPlan, isTrue);
    final reference = result.eventImages
        .singleWhere((image) => image.role == 'eventTile');
    expect(reference.state, 'invalid');
    expect(reference.sourceTileId, 647);
    expect(reference.sourceFile!.relativePath, 'Graphics/Tilesets/Terrain.png');
    expect(reference.sourceFile!.sha256, _hash(_png()));
    expect([
      reference.locator.mapId,
      reference.locator.eventId,
      reference.locator.pageIndex
    ], [1, 2, 1]);
    final diagnostic = result.diagnostics.singleWhere(
        (entry) => entry.code == 'normalization.event_tile_metadata_missing');
    expect(diagnostic.blocksPlanning, isFalse);
    expect(diagnostic.locator.toJson(), reference.locator.toJson());
    final graphic = result.maps.single.map.events.single.pages.last;
    expect(graphic.rawDataRef, isNotNull);
    expect(result.archive.references[graphic.rawDataRef]!.status, 'preservedOnly');
    expect(result.maps.single.map.layers.first.cells,
        [384, 385, 386, 387, 388, 389]);
    final analysis = SourceEventAnalyzer.forProject(result,
            profile: SourceEventProfile.forProject(result,
                scriptsArchiveHash: Sha256Hash(
                    fixtureSourceInterpretationProfile.scriptsArchiveHash.value),
interpretationProfile: fixtureSourceInterpretationProfile,
))
        .analyze();
    expect(analysis.events.single.isQuarantined, isTrue);
    final invalidGraphic = analysis.diagnostics.singleWhere(
        (entry) => entry.code == 'events.invalid_event_graphic_reference');
    expect(invalidGraphic.locator.toJson(), reference.locator.toJson());
  });

  test('out of range terrain metadata still blocks the entire map', () async {
    final result = await _normalize(_source(_project(maps: {
      1: _map(data: _RubyTable(3, 2, 3, [512, ...List.filled(17, 0)]))
    })));
    _blocked(result, file: 'Data/Map001.rxdata');
    expect(
        result.diagnostics.any((entry) =>
            entry.code == 'normalization.tile_metadata_missing' &&
            entry.blocksPlanning),
        isTrue);
    expect(result.eventImages, isEmpty);
  });

  test('ambiguous event character images still block planning', () async {
    final project = _project(maps: {
      1: _map(events: {
        2: _event(2, [_page([], character: 'AmbiguousCharacter')])
      })
    });
    project['Graphics/Characters/AmbiguousCharacter.png'] = _png();
    project['Graphics/Characters/AmbiguousCharacter.bmp'] = _png();
    final result = await _normalize(_source(project));
    _blocked(result, file: 'Data/Map001.rxdata');
    expect(result.eventImages.single.state, 'ambiguous');
    expect(
        result.diagnostics
            .singleWhere((item) => item.code == 'normalization.ambiguous_image')
            .blocksPlanning,
        isTrue);
  });

  test('invalid event character paths still block planning', () async {
    final result = await _normalize(_source(_project(maps: {
      1: _map(events: {
        2: _event(2, [_page([], character: '../UnsafeCharacter')])
      })
    })));
    _blocked(result, file: 'Data/Map001.rxdata');
    expect(result.eventImages.single.state, 'invalid');
    expect(
        result.diagnostics
            .singleWhere(
                (item) => item.code == 'normalization.invalid_media_path')
            .blocksPlanning,
        isTrue);
  });

  test('content hash drift is refused without admitting changed bytes',
      () async {
    final files = _source(_project());
    files.replacements['Data/Map001.rxdata'] =
        _MarshalFixture().dump(_map(width: 2));
    final result = await _normalize(files);
    _blocked(result, file: 'Data/Map001.rxdata');
    final fileId = files.snapshot.entries
        .singleWhere((entry) => entry.relativePath == 'Data/Map001.rxdata')
        .fileId;
    expect(result.archive.files.containsKey(fileId), isFalse);
  });

  test('incomplete snapshot is refused before any source read', () async {
    final files = _source(_project(), state: SourceScanState.partial);
    await expectLater(_normalize(files), throwsA(isA<ContractError>()));
    expect(files.reads, isEmpty);
  });

  test('pre-cancelled extraction is refused before any source read', () async {
    final files = _source(_project());
    final cancellation = ScanCancellation()..cancel();
    await expectLater(
        _normalize(files, cancellation: cancellation),
        throwsA(isA<ContractError>()
            .having((error) => error.code, 'code', 'source.cancelled')));
    expect(files.reads, isEmpty);
  });

  test('invalid normalization limits fail before any source read', () async {
    final files = _source(_project());
    await expectLater(
        _normalize(files,
            limits: const SourceNormalizationLimits(maxTotalCells: 0)),
        throwsArgumentError);
    expect(files.reads, isEmpty);
  });

  test('declared aggregate byte quota blocks before reading source payloads',
      () async {
    final files = _source(_project(maps: {1: _map(), 8: _map()}));
    final result = await _normalize(files,
        limits: const SourceNormalizationLimits(maxTotalBytes: 1));
    _blocked(result);
    expect(files.reads, isEmpty);
    expect(result.selectedSourceMapIds, [1, 8]);
    expect(result.unprocessedSourceMapIds, [1, 8]);
  });

  test('map quota produces a blocked result with no over-budget maps',
      () async {
    final result = await _normalize(
        _source(_project(maps: {1: _map(), 8: _map()})),
        limits: const SourceNormalizationLimits(maxMaps: 1));
    _blocked(result);
    expect(result.maps.length, lessThanOrEqualTo(1));
    expect(result.selectedSourceMapIds, [1, 8]);
    expect(result.unprocessedSourceMapIds, [1, 8]);
  });

  test('cell quota blocks before populating map layer lists', () async {
    final result = await _normalize(_source(_project()),
        limits: const SourceNormalizationLimits(maxTotalCells: 17));
    _blocked(result, file: 'Data/Map001.rxdata');
    expect(result.maps, isEmpty);
  });

  test('event quota produces a blocked result', () async {
    final result = await _normalize(
        _source(_project(maps: {
          1: _map(events: {
            1: _event(1, [_page([])]),
            2: _event(2, [_page([])])
          })
        })),
        limits: const SourceNormalizationLimits(maxEvents: 1));
    _blocked(result, file: 'Data/Map001.rxdata');
  });

  test('command quota produces a blocked result', () async {
    final result = await _normalize(
        _source(_project(maps: {
          1: _map(events: {
            1: _event(1, [
              _page([
                _command(101, ['one']),
                _command(0, [])
              ])
            ])
          })
        })),
        limits: const SourceNormalizationLimits(maxCommands: 1));
    _blocked(result, file: 'Data/Map001.rxdata');
  });

  test('parameter node quota does not truncate command parameters', () async {
    final result = await _normalize(
        _source(_project(maps: {
          1: _map(events: {
            1: _event(1, [
              _page([
                _command(101, [
                  [1, 2, 3, 4]
                ])
              ])
            ])
          })
        })),
        limits: const SourceNormalizationLimits(maxParameterNodes: 2));
    _blocked(result, file: 'Data/Map001.rxdata');
  });

  test(
      'negative Table tile cell is blocked instead of clamped or reinterpreted',
      () async {
    final result = await _normalize(_source(_project(maps: {
      1: _map(data: _RubyTable(3, 2, 3, [-1, ...List.filled(17, 0)]))
    })));
    _blocked(result, file: 'Data/Map001.rxdata');
    expect(result.maps, isEmpty);
    expect(
        result.archive.files.values
            .any((file) => file.entry.relativePath == 'Data/Map001.rxdata'),
        isTrue);
  });

  test('known map field of the wrong type is preserved and blocked', () async {
    final map = _map()..fields['@width'] = '3';
    final result = await _normalize(_source(_project(maps: {1: map})));
    _blocked(result, file: 'Data/Map001.rxdata');
    expect(result.maps, isEmpty);
    expect(
        result.archive.files.values
            .any((file) => file.entry.relativePath == 'Data/Map001.rxdata'),
        isTrue);
  });

  test('Table shape must equal declared map dimensions and three layers',
      () async {
    for (final table in [
      _RubyTable(2, 3, 3, List.filled(18, 0)),
      _RubyTable(3, 2, 2, List.filled(12, 0))
    ]) {
      final result =
          await _normalize(_source(_project(maps: {1: _map(data: table)})));
      _blocked(result, file: 'Data/Map001.rxdata');
      expect(result.maps, isEmpty);
    }
  });

  test('map metadata pointing at an absent map stays visible and blocks',
      () async {
    final result = await _normalize(_source(_project(
        infos: {1: _mapInfo('One'), 8: _mapInfo('Missing map', parent: 1)})));
    _blocked(result);
    expect(result.mapHierarchy.map((info) => info.sourceMapId), contains(8));
    expect(result.maps.map((map) => map.map.sourceMapId), isNot(contains(8)));
  });

  test('absent tileset ID is a blocker without a synthesized replacement',
      () async {
    final result =
        await _normalize(_source(_project(maps: {1: _map(tileset: 8)})));
    _blocked(result, file: 'Data/Map001.rxdata');
    expect(result.maps.single.map.sourceTilesetId, 8);
    expect(result.tilesets.map((tileset) => tileset.sourceTilesetId),
        isNot(contains(8)));
  });

  test('hierarchy cycles and absent parent IDs are not repaired into routes',
      () async {
    for (final infos in [
      {1: _mapInfo('One', parent: 8), 8: _mapInfo('Eight', parent: 1)},
      {1: _mapInfo('One', parent: 120), 8: _mapInfo('Eight')},
    ]) {
      final result = await _normalize(
          _source(_project(maps: {1: _map(), 8: _map()}, infos: infos)));
      _blocked(result, file: 'Data/MapInfos.rxdata');
      expect(result.mapHierarchy.first.parentSourceMapId,
          infos[1]!.fields['@parent_id']);
    }
  });

  test('event hash key and embedded ID mismatch cannot change event identity',
      () async {
    final result = await _normalize(_source(_project(maps: {
      1: _map(events: {
        3: _event(99, [_page([])])
      })
    })));
    _blocked(result, file: 'Data/Map001.rxdata');
  });

  test('unknown selected map ID blocks rather than choosing another map',
      () async {
    final result = await _normalize(_source(_project()), selectedMapIds: {120});
    _blocked(result);
    expect(result.maps, isEmpty);
  });

  test('published collections and preserved bytes are immutable', () async {
    final result = await _normalize(_source(_project()));
    expect(() => result.maps.clear(), throwsUnsupportedError);
    expect(() => result.mapHierarchy.clear(), throwsUnsupportedError);
    expect(() => result.tilesets.clear(), throwsUnsupportedError);
    expect(() => result.diagnostics.clear(), throwsUnsupportedError);
    expect(() => result.tilesets.single.images.clear(), throwsUnsupportedError);
    expect(() => result.maps.single.map.layers.first.cells[0] = 0,
        throwsUnsupportedError);
    expect(() => result.archive.files.clear(), throwsUnsupportedError);
    expect(() => result.archive.references.clear(), throwsUnsupportedError);
    expect(() => result.archive.files.values.first.rawBytes[0] = 0,
        throwsUnsupportedError);
  });

  test('adversarial AC-04 freezes caller selection across awaited reads',
      () async {
    final files = _source(_project(maps: {1: _map(), 8: _map()}));
    final selected = {1};
    files.onRead = (path) {
      if (path == 'Data/MapInfos.rxdata') {
        selected
          ..clear()
          ..add(8);
      }
    };
    final result = await _normalize(files, selectedMapIds: selected);
    expect(result.canPlan, isTrue);
    expect(result.maps.map((map) => map.map.sourceMapId), [1]);
    expect(files.reads, contains('Data/Map001.rxdata'));
    expect(files.reads, isNot(contains('Data/Map008.rxdata')));
  });

  test(
      'adversarial AC-04 tile event requires its tileset image on an empty map',
      () async {
    final page = _page([]);
    (page.fields['@graphic']! as _RubyObject).fields['@tile_id'] = 384;
    final result = await _normalize(_source(_project(
      maps: {
        1: _map(
          data: _RubyTable(3, 2, 3, List.filled(18, 0)),
          events: {
            6: _event(6, [page])
          },
        ),
      },
      tileset: _tileset(image: ''),
      image: false,
    )));
    _blocked(result, file: 'Data/Map001.rxdata');
    expect(
      result.diagnostics.any((item) =>
          item.blocksPlanning &&
          item.locator.mapId == 1 &&
          item.locator.eventId == 6 &&
          item.locator.pageIndex == 0),
      isTrue,
    );
  });

  test('adversarial budgets AC-04 metadata cells are counted across all tables',
      () async {
    final result = await _normalize(_source(_project()),
        limits: const SourceNormalizationLimits(maxMetadataCells: 1024));
    _blocked(result, file: 'Data/Tilesets.rxdata');
    expect(result.tilesets, isEmpty);
    expect(
        result.archive.files.values
            .any((file) => file.entry.relativePath == 'Data/Tilesets.rxdata'),
        isTrue);
  });

  test('adversarial budgets AC-04 IR nodes block before admitting a map',
      () async {
    final files = _source(_project());
    final result = await _normalize(files,
        limits: const SourceNormalizationLimits(maxTotalIrNodes: 1));
    _blocked(result, file: 'Data/MapInfos.rxdata');
    expect(result.maps, isEmpty);
    expect(files.reads, isNot(contains('Data/Map001.rxdata')));
  });

  test('adversarial budgets AC-04 IR text blocks before admitting a map',
      () async {
    final files = _source(_project());
    final result = await _normalize(files,
        limits: const SourceNormalizationLimits(maxTotalTextCodeUnits: 4));
    _blocked(result, file: 'Data/MapInfos.rxdata');
    expect(result.maps, isEmpty);
    expect(files.reads, isNot(contains('Data/Map001.rxdata')));
  });

  test('adversarial budgets AC-04 directories cannot impersonate Marshal files',
      () async {
    for (final path in ['Data/MapInfos.rxdata', 'Data/Tilesets.rxdata']) {
      final original = _source(_project());
      final entries = [
        for (final entry in original.snapshot.entries)
          if (entry.relativePath == path)
            SourceFileEntry(
              fileId: entry.fileId,
              relativePath: entry.relativePath,
              kind: SourceNodeKind.directory,
              byteLength: 0,
              sha256: null,
              format: 'directory',
              family: 'none',
            )
          else
            entry,
      ];
      final snapshot = SourceSnapshot(
        logicalProjectNamespace: original.snapshot.logicalProjectNamespace,
        policyHash: original.snapshot.policyHash,
        entries: entries,
        diagnostics: [],
        excludedPaths: [],
        profileEvidence: original.snapshot.profileEvidence,
        state: SourceScanState.complete,
      );
      final files = _Files(original.bytes, snapshot)
        ..onRead = (readPath) {
          if (readPath == path) {
            throw StateError('A directory reached the file reader');
          }
        };
      final result = await _normalize(files);
      _blocked(result, file: path);
      expect(files.reads, isNot(contains(path)));
      expect(result.selectedSourceMapIds, [1]);
      expect(result.unprocessedSourceMapIds, [1]);
    }
  });
}
