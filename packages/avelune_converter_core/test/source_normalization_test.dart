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
        ScanCancellation? cancellation}) =>
    const RmxpSourceNormalizer().normalize(
        snapshot: files.snapshot,
        files: files,
        limits: limits,
        selectedMapIds: selectedMapIds,
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

void main() {
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

  test('event character image absence blocks with the original page locator',
      () async {
    final result = await _normalize(_source(_project(maps: {
      1: _map(events: {
        2: _event(2, [_page([], character: 'AbsentCharacter')])
      })
    })));
    _blocked(result, file: 'Data/Map001.rxdata');
    final image = result.eventImages.single;
    expect(image.sourceName, 'AbsentCharacter');
    expect(
        [image.locator.mapId, image.locator.eventId, image.locator.pageIndex],
        [1, 2, 0]);
    expect(image.sourceFile, isNull);
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
