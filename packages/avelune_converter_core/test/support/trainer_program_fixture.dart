import 'dart:convert';
import 'dart:typed_data';
import 'interpretation_profile_fixture.dart';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;

final class TrainerRubyObject {
  TrainerRubyObject(this.name, this.fields);
  final String name;
  final Map<String, Object?> fields;
  final extraFields = <MapEntry<String, Object?>>[];
}

final class TrainerRubyString {
  TrainerRubyString(this.text, this.fields);
  final String text;
  final List<MapEntry<String, Object?>> fields;
}

final class TrainerRubyUserDefined {
  TrainerRubyUserDefined(this.name, this.bytes);
  final String name;
  final List<int> bytes;
}

TrainerRubyObject trainerCommand(int code, List<Object?> parameters,
        {int indent = 0}) =>
    TrainerRubyObject('RPG::EventCommand',
        {'@code': code, '@indent': indent, '@parameters': parameters});

TrainerRubyObject trainerMove(int code) => TrainerRubyObject(
    'RPG::MoveCommand', {'@code': code, '@parameters': <Object?>[]});

TrainerRubyObject trainerRoute(List<TrainerRubyObject> commands,
        {bool repeat = false}) =>
    TrainerRubyObject('RPG::MoveRoute', {
      '@repeat': repeat,
      '@skippable': false,
      '@list': commands,
    });

List<TrainerRubyObject> trainerPages({String name = 'Brent'}) {
  TrainerRubyObject page(List<TrainerRubyObject> commands, int index) =>
      TrainerRubyObject('RPG::Event::Page', {
        '@condition': TrainerRubyObject('RPG::Event::Page::Condition', {
          '@switch1_valid': false,
          '@switch2_valid': false,
          '@variable_valid': false,
          '@self_switch_valid': index == 1,
          '@switch1_id': 1,
          '@switch2_id': 1,
          '@variable_id': 1,
          '@variable_value': 0,
          '@self_switch_ch': 'A',
        }),
        '@graphic': TrainerRubyObject('RPG::Event::Page::Graphic', {
          '@tile_id': 0,
          '@character_name': 'trainer_BUGCATCHER',
          '@character_hue': 0,
          '@direction': 2,
          '@pattern': 0,
          '@opacity': 255,
          '@blend_type': 0,
        }),
        '@move_type': 0,
        '@move_speed': 3,
        '@move_frequency': 3,
        '@move_route': trainerRoute([trainerMove(0)], repeat: true),
        '@walk_anime': true,
        '@step_anime': false,
        '@direction_fix': false,
        '@through': false,
        '@always_on_top': false,
        '@trigger': index == 0 ? 2 : 0,
        '@list': commands,
      });
  return [
    page([
      trainerCommand(355, ['pbTrainerIntro(:FRLG_BUGCATCHER)']),
      trainerCommand(355, ['pbNoticePlayer(get_self)']),
      trainerCommand(101, ['Bonjour, prêt pour le combat ?']),
      trainerCommand(108, ['EndSpeech: Bien joué !']),
      trainerCommand(
          111, [12, 'TrainerBattle.start(:FRLG_BUGCATCHER, "$name")']),
      trainerCommand(123, ['A', 0], indent: 1),
      trainerCommand(0, [], indent: 1),
      trainerCommand(412, []),
      trainerCommand(355, ['pbTrainerEnd']),
      trainerCommand(0, []),
    ], 0),
    page([
      trainerCommand(101, ['À bientôt !']),
      trainerCommand(209, [
        0,
        trainerRoute([trainerMove(25), trainerMove(0)])
      ]),
      trainerCommand(509, [trainerMove(25)]),
      trainerCommand(0, []),
    ], 1),
  ];
}

final class _Table {
  _Table(this.x, this.y, this.z);
  final int x, y, z;
}

final class _Dump {
  List<int> packed(int value) {
    if (value == 0) return [0];
    if (value > 0 && value < 123) return [value + 5];
    if (value < 0 && value > -124) return [(value - 5) & 255];
    var width = 1;
    while (value >= (1 << (width * 8)) || value < -(1 << (width * 8))) {
      width++;
    }
    return [
      value >= 0 ? width : (-width) & 255,
      for (var i = 0; i < width; i++) (value >> (i * 8)) & 255
    ];
  }

  List<int> symbol(String value) {
    final bytes = utf8.encode(value);
    return [0x3a, ...packed(bytes.length), ...bytes];
  }

  List<int> value(Object? input) {
    if (input == null) return [0x30];
    if (input is bool) return [input ? 0x54 : 0x46];
    if (input is int) return [0x69, ...packed(input)];
    if (input is TrainerRubyString) {
      return [
        0x49,
        ...value(input.text),
        ...packed(input.fields.length),
        for (final entry in input.fields) ...[
          ...symbol(entry.key),
          ...value(entry.value)
        ]
      ];
    }
    if (input is TrainerRubyUserDefined) {
      return [0x75, ...symbol(input.name), ...packed(input.bytes.length), ...input.bytes];
    }
    if (input is String) {
      final bytes = utf8.encode(input);
      return [0x22, ...packed(bytes.length), ...bytes];
    }
    if (input is List) {
      return [
        0x5b,
        ...packed(input.length),
        for (final item in input) ...value(item)
      ];
    }
    if (input is Map) {
      return [
        0x7b,
        ...packed(input.length),
        for (final entry in input.entries) ...[
          ...value(entry.key),
          ...value(entry.value)
        ]
      ];
    }
    if (input is TrainerRubyObject) {
      return [
        0x6f,
        ...symbol(input.name),
        ...packed(input.fields.length + input.extraFields.length),
        for (final entry in [
          ...input.fields.entries,
          ...input.extraFields
        ]) ...[...symbol(entry.key), ...value(entry.value)]
      ];
    }
    if (input is _Table) {
      final cells = input.x * input.y * input.z;
      final bytes = ByteData(20 + cells * 2)
        ..setUint32(0, input.z == 1 ? 1 : 3, Endian.little)
        ..setUint32(4, input.x, Endian.little)
        ..setUint32(8, input.y, Endian.little)
        ..setUint32(12, input.z, Endian.little)
        ..setUint32(16, cells, Endian.little);
      return [
        0x75,
        ...symbol('Table'),
        ...packed(bytes.lengthInBytes),
        ...bytes.buffer.asUint8List()
      ];
    }
    throw ArgumentError.value(input);
  }

  List<int> dump(Object? input) => [4, 8, ...value(input)];
}

final class _Files implements SourceFilePort {
  _Files(this.bytes);
  final Map<ConverterId, List<int>> bytes;
  @override
  Future<List<int>> read(ConverterId id) async => bytes[id]!;
}

Future<NormalizedSourceProject> trainerSource({
  int mapId = 417,
  int eventId = 23,
  String eventName = 'Dresseur Trainer(6)',
  String trainerName = "Élodie d'Arc",
  List<String?>? variableNames,
  List<String?>? switchNames,
  List<int>? scriptsBytes,
  SourceInterpretationProfile? interpretationProfile,
  void Function(List<TrainerRubyObject>)? mutate,
}) async {
  final pages = trainerPages(name: trainerName);
  mutate?.call(pages);
  final files = <String, Object?>{
    if (scriptsBytes != null) 'Data/Scripts.rxdata': null,
    'Data/MapInfos.rxdata': {
      mapId: TrainerRubyObject('RPG::MapInfo', {
        '@name': 'Route libre',
        '@parent_id': 0,
        '@order': 0,
        '@expanded': true,
        '@scroll_x': 0,
        '@scroll_y': 0,
      })
    },
    'Data/Map${mapId.toString().padLeft(3, '0')}.rxdata':
        TrainerRubyObject('RPG::Map', {
      '@tileset_id': 1,
      '@width': 2,
      '@height': 2,
      '@data': _Table(2, 2, 3),
      '@events': {
        eventId: TrainerRubyObject('RPG::Event', {
          '@id': eventId,
          '@name': eventName,
          '@x': 1,
          '@y': 1,
          '@pages': pages,
        })
      },
    }),
    'Data/Tilesets.rxdata': [
      null,
      TrainerRubyObject('RPG::Tileset', {
        '@id': 1,
        '@name': 'Terrain',
        '@tileset_name': '',
        '@autotile_names': List.filled(7, ''),
        '@passages': _Table(384, 1, 1),
        '@priorities': _Table(384, 1, 1),
        '@terrain_tags': _Table(384, 1, 1),
      })
    ],
    'Data/System.rxdata': TrainerRubyObject('RPG::System', {
      '@switches': switchNames ?? ['', 'Ready'],
      if (variableNames != null) '@variables': variableNames,
    }),
  };
  final bytes = {
    for (final entry in files.entries)
      ConverterId(
              'fixture:${base64Url.encode(utf8.encode(entry.key)).replaceAll('=', '')}'):
          entry.key == 'Data/Scripts.rxdata'
              ? scriptsBytes!
              : _Dump().dump(entry.value)
  };
  final snapshot = SourceSnapshot(
    logicalProjectNamespace: ConverterId('trainer-template-fixture'),
    policyHash: Sha256Hash('1' * 64),
    entries: [
      for (final entry in bytes.entries.indexed)
        SourceFileEntry(
            fileId: entry.$2.key,
            relativePath: files.keys.elementAt(entry.$1),
            kind: SourceNodeKind.file,
            byteLength: entry.$2.value.length,
            sha256:
                Sha256Hash(crypto.sha256.convert(entry.$2.value).toString()),
            format: 'ruby-marshal',
            family: 'rmxp')
    ],
    diagnostics: [],
    excludedPaths: [],
    profileEvidence: [],
    state: SourceScanState.complete,
  );
  return const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: _Files(bytes),
      selectedMapIds: {mapId},
      interpretationProfile: interpretationProfile,
      includeEventSystem: true);
}

SourceEventAnalysis analyzeTrainerSource(NormalizedSourceProject source) =>
    SourceEventAnalyzer.forProject(source,
            profile: SourceEventProfile.forProject(source,
                scriptsArchiveHash:
                    Sha256Hash(fixtureSourceInterpretationProfile.scriptsArchiveHash.value),
interpretationProfile: fixtureSourceInterpretationProfile,
))
        .analyze();
