import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as image;

Sha256Hash literalFixtureHash(List<int> bytes) =>
    Sha256Hash(crypto.sha256.convert(bytes).toString());

List<int> literalFixtureAtlas({bool alternate = false}) {
  final raster = image.Image(width: 256, height: 64, numChannels: 4);
  for (var y = 0; y < 64; y++) {
    for (var x = 0; x < 256; x++) {
      raster.setPixelRgba(x, y, alternate ? 96 : 34, 67, 91, 255);
    }
  }
  for (var y = 0; y < 32; y++) {
    for (var x = 0; x < 32; x++) {
      raster.setPixelRgba(x, y, alternate ? 101 : 201, 17, 39, 255);
    }
    for (var x = 224; x < 256; x++) {
      raster.setPixelRgba(x, y, 19, alternate ? 107 : 207, 55, 255);
    }
  }
  for (var y = 32; y < 64; y++) {
    for (var x = 0; x < 32; x++) {
      raster.setPixelRgba(x, y, 23, 61, alternate ? 123 : 223, 255);
    }
  }
  raster.setPixelRgba(0, 0, 9, 11, 13, 0);
  raster.setPixelRgba(1, 0, 17, 29, 43, 127);
  raster.setPixelRgba(2, 0, 53, 71, 89, 255);
  raster.setPixelRgba(3, 0, 255, 0, 255, 255);
  return List.unmodifiable(image.encodePng(raster));
}

final class LiteralFixtureMap {
  LiteralFixtureMap({
    required this.id,
    String? name,
    this.tilesetId = 1,
    this.width = 3,
    this.height = 1,
    List<List<int>>? layers,
    List<List<Object?>> warpParameters = const [],
    this.events = const [],
    this.autoplayBgm = false,
    this.bgmName = '',
    this.bgmVolume = 100,
    this.bgmPitch = 100,
  })  : name = name ?? 'Original map $id',
        layers = List.unmodifiable((layers ??
                const [
                  [384, 391, 392],
                  [0, 384, 0],
                  [0, 0, 0],
                ])
            .map((layer) => List<int>.unmodifiable(layer))),
        warpParameters = List.unmodifiable(warpParameters
            .map((parameters) => List<Object?>.unmodifiable(parameters)));

  final int id;
  final String name;
  final int tilesetId;
  final int width;
  final int height;
  final List<List<int>> layers;
  final List<List<Object?>> warpParameters;
  final List<LiteralFixtureEvent> events;
  final bool autoplayBgm;
  final String bgmName;
  final int bgmVolume;
  final int bgmPitch;
}

final class LiteralFixtureEvent {
  const LiteralFixtureEvent({required this.id, required this.x,
    required this.y, required this.pages, this.name = 'Original event'});
  final int id;
  final int x;
  final int y;
  final String name;
  final List<LiteralFixtureEventPage> pages;
}

final class LiteralFixtureEventPage {
  const LiteralFixtureEventPage({required this.commands, this.selfSwitch,
    this.globalSwitch, this.characterName = '', this.pattern = 0, this.tileId = 0,
    this.direction = 2, this.trigger = 0, this.through = false,
    this.moveType = 0, this.directionFix = false, this.moveSpeed = 3});
  final List<LiteralFixtureEventCommand> commands;
  final String? selfSwitch;
  final int? globalSwitch;
  final String characterName;
  final int pattern;
  final int tileId;
  final int direction;
  final int trigger;
  final bool through;
  final int moveType;
  final bool directionFix;
  final int moveSpeed;
}

final class LiteralFixtureEventCommand {
  const LiteralFixtureEventCommand(this.code, this.parameters, {this.indent = 0});
  final int code;
  final List<Object?> parameters;
  final int indent;
}

final class LiteralFixtureObject {
  const LiteralFixtureObject(this.name, this.fields);
  final String name;
  final Map<String, Object?> fields;
}

final class LiteralFixtureSymbol {
  const LiteralFixtureSymbol(this.value);
  final String value;
}

final class LiteralFixtureUserDefined {
  const LiteralFixtureUserDefined(this.name, this.bytes);
  final String name;
  final List<int> bytes;
}

List<int> literalFixtureMarshal(Object? value) => _Marshal().dump(value);

final class LiteralFixtureTileset {
  LiteralFixtureTileset({
    required this.id,
    this.name = 'Original atlas',
    this.metadataTileCount = 512,
    String? imageName,
    List<int>? png,
    this.imagePresent = true,
    List<String> autotileNames = const [],
    Map<int, int> priorities = const {},
    Map<int, int> passages = const {},
    Map<int, int> terrainTags = const {},
  })  : imageName = imageName ?? 'OriginalAtlas$id',
        png = List.unmodifiable(png ?? literalFixtureAtlas()),
        autotileNames = List.unmodifiable(autotileNames),
        priorities = Map.unmodifiable(priorities),
        passages = Map.unmodifiable(passages),
        terrainTags = Map.unmodifiable(terrainTags) {
    if (metadataTileCount < 1 || metadataTileCount > 65536) {
      throw RangeError.range(metadataTileCount, 1, 65536, 'metadataTileCount');
    }
  }

  final int id;
  final String name;
  final int metadataTileCount;
  final String imageName;
  final List<int> png;
  final bool imagePresent;
  final List<String> autotileNames;
  final Map<int, int> priorities;
  final Map<int, int> passages;
  final Map<int, int> terrainTags;
}

final class LiteralFixtureFiles implements SourceFilePort {
  LiteralFixtureFiles(this.snapshot, this.bytes);

  final SourceSnapshot snapshot;
  final Map<String, List<int>> bytes;
  final Map<String, List<int>> overrides = {};
  final List<ConverterId> reads = [];
  Object? readFailure;
  void Function(String path)? onRead;

  @override
  Future<List<int>> read(ConverterId fileId) async {
    reads.add(fileId);
    final path = snapshot.entries
        .singleWhere((entry) => entry.fileId == fileId)
        .relativePath;
    onRead?.call(path);
    if (readFailure case final Object failure) {
      throw failure;
    }
    return List.unmodifiable(overrides[path] ?? bytes[path]!);
  }
}

final class LiteralTileFixture {
  LiteralTileFixture._(this.snapshot, this.sourceBytes, this.files, this.source,
      this.sourceRootPath);

  final SourceSnapshot snapshot;
  final Map<String, List<int>> sourceBytes;
  final LiteralFixtureFiles files;
  final NormalizedSourceProject source;
  final String? sourceRootPath;

  static Future<LiteralTileFixture> create({
    String namespace = 'original-literal-tile-fixture',
    List<LiteralFixtureMap>? maps,
    List<LiteralFixtureTileset>? tilesets,
    Set<int>? selectedMapIds,
    String? sourceRootPath,
    bool contradictoryProfile = false,
    bool reverseManifest = false,
    Map<String, List<int>> autotilePngs = const {},
    List<int>? scriptsBytes,
    SourceInterpretationProfile? interpretationProfile,
    Map<String, List<int>> extraFiles = const {},
    bool includeEventSystem = false,
    List<String?> switchNames = const [null, 'Original door opened', 'Original reward consumed'],
    List<String?> variableNames = const [null, 'Original count'],
    Map<int, List<LiteralFixtureEventCommand>> commonEvents = const {},
    Map<int, int> commonEventTriggers = const {},
  }) async {
    final sourceMaps = maps ?? [LiteralFixtureMap(id: 1)];
    final sourceTilesets = tilesets ?? [LiteralFixtureTileset(id: 1)];
    final bytes = <String, List<int>>{
      ...extraFiles,
      if (commonEvents.isNotEmpty)
        'Data/CommonEvents.rxdata': _Marshal().dump([
          for (var id = 0; id <= commonEvents.keys.reduce((a, b) => a > b ? a : b); id++)
            if (commonEvents[id] case final commands?)
              _Object('RPG::CommonEvent', {'@id': id, '@name': 'Common $id',
                '@trigger': commonEventTriggers[id] ?? 0, '@switch_id': 1,
                '@list': [for (final command in [...commands, const LiteralFixtureEventCommand(0, [])])
                  _Object('RPG::EventCommand', {'@code': command.code,
                    '@indent': command.indent, '@parameters': command.parameters})]})
            else null,
        ]),
      if (scriptsBytes != null)
        'Data/Scripts.rxdata': List<int>.unmodifiable(scriptsBytes),
      if (includeEventSystem)
        'Data/System.rxdata': _Marshal().dump(_Object('RPG::System', {
          '@switches': switchNames,
          '@variables': variableNames,
        })),
      'README.md':
          utf8.encode('Original controlled Pokemon Essentials v21.1 fixture\n'),
      'Data/MapInfos.rxdata': _Marshal().dump({
        for (final map in sourceMaps)
          map.id: _Object('RPG::MapInfo', {
            '@name': map.name,
            '@parent_id': 0,
            '@order': map.id,
            '@expanded': true,
            '@scroll_x': 0,
            '@scroll_y': 0,
          }),
      }),
      for (final map in sourceMaps)
        'Data/Map${map.id.toString().padLeft(3, '0')}.rxdata':
            _Marshal().dump(_Object('RPG::Map', {
          '@tileset_id': map.tilesetId,
          '@width': map.width,
          '@height': map.height,
          '@data': _Table(3, map.width, map.height, 3,
              map.layers.expand((layer) => layer).toList()),
          '@events': {
            if (map.warpParameters.isNotEmpty) 6: _event(map.warpParameters),
            for (final event in map.events) event.id: _fixtureEvent(event),
          },
          '@autoplay_bgm': map.autoplayBgm,
          if (map.autoplayBgm || map.bgmName.isNotEmpty)
            '@bgm': _Object('RPG::AudioFile', {
              '@name': map.bgmName,
              '@volume': map.bgmVolume,
              '@pitch': map.bgmPitch,
            }),
          '@autoplay_bgs': false,
          '@encounter_list': <Object?>[],
          '@encounter_step': 30,
        })),
      'Data/Tilesets.rxdata': _Marshal().dump([
        for (var id = 0;
            id <=
                sourceTilesets
                    .map((tileset) => tileset.id)
                    .reduce((a, b) => a > b ? a : b);
            id++)
          sourceTilesets.any((tileset) => tileset.id == id)
              ? _tileset(
                  sourceTilesets.singleWhere((tileset) => tileset.id == id))
              : null,
      ]),
      for (final tileset in sourceTilesets)
        if (tileset.imagePresent)
          'Graphics/Tilesets/${tileset.imageName}.png': tileset.png,
      for (final tileset in sourceTilesets)
        for (final name in tileset.autotileNames)
          if (name.isNotEmpty)
            'Graphics/Autotiles/$name.png': autotilePngs[name] ?? tileset.png,
      if (contradictoryProfile)
        'Scripts/Version.rb': utf8.encode('ESSENTIALS_VERSION = "22"\n'),
    };
    final frozenBytes = Map<String, List<int>>.unmodifiable(bytes
        .map((path, value) => MapEntry(path, List<int>.unmodifiable(value))));
    final entries = [
      for (final entry in frozenBytes.entries)
        SourceFileEntry(
          fileId: ConverterId(
              'literal-file:${base64Url.encode(utf8.encode(entry.key)).replaceAll('=', '')}'),
          relativePath: entry.key,
          kind: SourceNodeKind.file,
          byteLength: entry.value.length,
          sha256: literalFixtureHash(entry.value),
          format: entry.key.endsWith('.rxdata')
              ? 'ruby-marshal'
              : entry.key.endsWith('.png')
                  ? 'raster'
                  : entry.key.endsWith('.rb')
                      ? 'ruby-text'
                      : 'text',
          family: entry.key.endsWith('.rxdata')
              ? 'data'
              : entry.key.endsWith('.png')
                  ? 'graphics'
                  : entry.key.startsWith('Scripts/')
                      ? 'scripts'
                      : 'project',
        ),
    ];
    final snapshot = SourceSnapshot(
      logicalProjectNamespace: ConverterId(namespace),
      policyHash: SourceScanPolicy().canonicalHash,
      entries: reverseManifest ? entries.reversed.toList() : entries,
      diagnostics: [],
      excludedPaths: [],
      profileEvidence: [
        SourceProfileEvidence(
          relativePath: 'README.md',
          fileHash: literalFixtureHash(frozenBytes['README.md']!),
          version: '21.1',
          line: 1,
          excerpt: 'Original controlled Pokemon Essentials v21.1 fixture',
        ),
        if (contradictoryProfile)
          SourceProfileEvidence(
            relativePath: 'Scripts/Version.rb',
            fileHash: literalFixtureHash(frozenBytes['Scripts/Version.rb']!),
            version: '22',
            line: 1,
            excerpt: 'ESSENTIALS_VERSION = "22"',
          ),
      ],
      state: SourceScanState.complete,
    );
    if (sourceRootPath != null) {
      for (final entry in frozenBytes.entries) {
        final file = File('$sourceRootPath/${entry.key}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value, flush: true);
      }
    }
    final files = LiteralFixtureFiles(snapshot, frozenBytes);
    final source = await const RmxpSourceNormalizer().normalize(
        snapshot: snapshot, files: files, interpretationProfile: interpretationProfile, selectedMapIds: selectedMapIds,
        includeEventSystem: includeEventSystem);
    files.reads.clear();
    return LiteralTileFixture._(
        snapshot, frozenBytes, files, source, sourceRootPath);
  }
}

_Object _fixtureEvent(LiteralFixtureEvent event) => _Object('RPG::Event', {
  '@id': event.id, '@name': event.name, '@x': event.x, '@y': event.y,
  '@pages': [for (final page in event.pages) _Object('RPG::Event::Page', {
    '@condition': _Object('RPG::Event::Page::Condition', {
      '@switch1_valid': page.globalSwitch != null, '@switch2_valid': false,
      '@variable_valid': false, '@self_switch_valid': page.selfSwitch != null,
      '@switch1_id': page.globalSwitch ?? 1, '@switch2_id': 1,
      '@variable_id': 1, '@variable_value': 0,
      '@self_switch_ch': page.selfSwitch ?? 'A',
    }),
    '@graphic': _Object('RPG::Event::Page::Graphic', {
      '@tile_id': page.tileId, '@character_name': page.characterName,
      '@character_hue': 0, '@direction': page.direction,
      '@pattern': page.pattern, '@opacity': 255, '@blend_type': 0,
    }),
    '@move_type': page.moveType, '@move_speed': page.moveSpeed, '@move_frequency': 3,
    '@move_route': _Object('RPG::MoveRoute', {
      '@repeat': true, '@skippable': false,
      '@list': [_Object('RPG::MoveCommand', {'@code': 0, '@parameters': <Object?>[]})],
    }),
    '@walk_anime': true, '@step_anime': false, '@direction_fix': page.directionFix,
    '@through': page.through, '@always_on_top': false, '@trigger': page.trigger,
    '@list': [for (final command in page.commands) _Object('RPG::EventCommand', {
      '@code': command.code, '@indent': command.indent,
      '@parameters': command.parameters,
    })],
  })],
});

_Object _tileset(LiteralFixtureTileset tileset) => _Object('RPG::Tileset', {
      '@id': tileset.id,
      '@name': tileset.name,
      '@tileset_name': tileset.imageName,
      '@autotile_names': List<String>.generate(
          7,
          (slot) => slot < tileset.autotileNames.length
              ? tileset.autotileNames[slot]
              : ''),
      '@panorama_name': '',
      '@fog_name': '',
      '@battleback_name': '',
      '@passages': _Table(
          1,
          tileset.metadataTileCount,
          1,
          1,
          List.generate(
              tileset.metadataTileCount, (id) => tileset.passages[id] ?? 0)),
      '@priorities': _Table(
          1,
          tileset.metadataTileCount,
          1,
          1,
          List.generate(
              tileset.metadataTileCount, (id) => tileset.priorities[id] ?? 0)),
      '@terrain_tags': _Table(
          1,
          tileset.metadataTileCount,
          1,
          1,
          List.generate(
              tileset.metadataTileCount, (id) => tileset.terrainTags[id] ?? 0)),
    });

_Object _event(List<List<Object?>> parameters) => _Object('RPG::Event', {
      '@id': 6,
      '@name': 'Original transfer event',
      '@x': 1,
      '@y': 0,
      '@pages': [
        _Object('RPG::Event::Page', {
          '@condition': _Object('RPG::Event::Page::Condition', {
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
          '@graphic': _Object('RPG::Event::Page::Graphic', {
            '@tile_id': 0,
            '@character_name': '',
            '@character_hue': 0,
            '@direction': 2,
            '@pattern': 0,
            '@opacity': 255,
            '@blend_type': 0,
          }),
          '@trigger': 0,
          '@list': [
            for (final value in parameters)
              _Object('RPG::EventCommand', {
                '@code': 201,
                '@indent': 0,
                '@parameters': value,
              }),
          ],
        }),
      ],
    });

final class _Object {
  const _Object(this.name, this.fields);
  final String name;
  final Map<String, Object?> fields;
}

final class _Table {
  const _Table(this.dimensions, this.x, this.y, this.z, this.cells);
  final int dimensions;
  final int x;
  final int y;
  final int z;
  final List<int> cells;
}

final class _Marshal {
  List<int> dump(Object? value) => [4, 8, ..._value(value)];

  List<int> _integer(int value) {
    if (value == 0) return [0];
    if (value > 0 && value < 123) return [value + 5];
    if (value < 0 && value > -124) return [(value - 5) & 255];
    final data = ByteData(4)..setInt32(0, value, Endian.little);
    final bytes = data.buffer.asUint8List().toList();
    while (bytes.length > 1 && bytes.last == (value < 0 ? 255 : 0)) {
      bytes.removeLast();
    }
    return [value < 0 ? (256 - bytes.length) : bytes.length, ...bytes];
  }

  List<int> _symbol(String value) {
    final bytes = utf8.encode(value);
    return [0x3a, ..._integer(bytes.length), ...bytes];
  }

  List<int> _value(Object? value) {
    if (value is LiteralFixtureUserDefined) {
      return [0x75, ..._symbol(value.name), ..._integer(value.bytes.length), ...value.bytes];
    }
    if (value is LiteralFixtureSymbol) return _symbol(value.value);
    if (value is LiteralFixtureObject) {
      return _value(_Object(value.name, value.fields));
    }
    if (value == null) return [0x30];
    if (value is bool) return [value ? 0x54 : 0x46];
    if (value is int) return [0x69, ..._integer(value)];
    if (value is String) {
      final bytes = utf8.encode(value);
      return [0x22, ..._integer(bytes.length), ...bytes];
    }
    if (value is List) {
      return [
        0x5b,
        ..._integer(value.length),
        for (final item in value) ..._value(item)
      ];
    }
    if (value is Map) {
      return [
        0x7b,
        ..._integer(value.length),
        for (final entry in value.entries)
          ...[_value(entry.key), _value(entry.value)].expand((bytes) => bytes),
      ];
    }
    if (value is _Object) {
      return [
        0x6f,
        ..._symbol(value.name),
        ..._integer(value.fields.length),
        for (final entry in value.fields.entries)
          ...[_symbol(entry.key), _value(entry.value)].expand((bytes) => bytes),
      ];
    }
    if (value is _Table) {
      final data = ByteData(20 + value.cells.length * 2)
        ..setUint32(0, value.dimensions, Endian.little)
        ..setUint32(4, value.x, Endian.little)
        ..setUint32(8, value.y, Endian.little)
        ..setUint32(12, value.z, Endian.little)
        ..setUint32(16, value.cells.length, Endian.little);
      for (var index = 0; index < value.cells.length; index++) {
        data.setInt16(20 + index * 2, value.cells[index], Endian.little);
      }
      final bytes = data.buffer.asUint8List();
      return [0x75, ..._symbol('Table'), ..._integer(bytes.length), ...bytes];
    }
    throw ArgumentError('Unsupported original Marshal fixture value');
  }
}
