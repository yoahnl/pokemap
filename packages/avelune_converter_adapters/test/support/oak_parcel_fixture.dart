import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';

import '../../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'literal_tile_fixture.dart';

Object? _literal(Object? value) => switch (value) {
      Map() when value['__class__'] == 'Tone' => LiteralFixtureUserDefined(
          'Tone', base64Decode(value['marshalPayload'] as String)),
      Map() => LiteralFixtureObject(value['__class__'] as String, {
          for (final e in value.entries)
            if (e.key != '__class__') '@${e.key}': _literal(e.value)
        }),
      List() => value.map(_literal).toList(),
      _ => value,
    };

Map<String, dynamic> parcelFixtureEvents() => (jsonDecode(
            File('test/fixtures/closed_parcel_program.json').readAsStringSync())
        as Map)
    .cast<String, dynamic>();

Future<({NormalizedSourceProject source, LiteralFixtureFiles files})>
    parcelFixture({
  int mapId = 9,
  Map<String, dynamic>? events,
}) async {
  final input = events ?? parcelFixtureEvents();
  final base = await LiteralTileFixture.create(
      scriptsBytes: syntheticInterpretationArchive,
      interpretationProfile: fixtureSourceInterpretationProfile,
      includeEventSystem: true,
      extraFiles: {
        'Data/CommonEvents.rxdata': literalFixtureMarshal([null]),
      },
      switchNames: [
        null,
        for (var i = 1; i <= 255; i++) 'Switch $i'
      ],
      variableNames: [
        null,
        for (var i = 1; i <= 255; i++) 'Variable $i'
      ],
      maps: [
        LiteralFixtureMap(id: mapId, width: 20, height: 20, layers: [
          List.filled(400, 384),
          List.filled(400, 0),
          List.filled(400, 0),
        ]),
      ]);
  final table = ByteData(20 + 2400)
    ..setUint32(0, 3, Endian.little)
    ..setUint32(4, 20, Endian.little)
    ..setUint32(8, 20, Endian.little)
    ..setUint32(12, 3, Endian.little)
    ..setUint32(16, 1200, Endian.little);
  for (var i = 0; i < 400; i++) {
    table.setUint16(20 + i * 2, 384, Endian.little);
  }
  final path = 'Data/Map${mapId.toString().padLeft(3, '0')}.rxdata';
  final bytes = {
    ...base.sourceBytes,
    path: literalFixtureMarshal(LiteralFixtureObject('RPG::Map', {
      '@tileset_id': 1,
      '@width': 20,
      '@height': 20,
      '@data': LiteralFixtureUserDefined('Table', table.buffer.asUint8List()),
      '@events': {
        for (final event in input.values) event['id'] as int: _literal(event),
      },
      '@autoplay_bgm': false,
      '@autoplay_bgs': false,
      '@encounter_list': <Object?>[],
      '@encounter_step': 30,
    })),
  };
  final snapshot = SourceSnapshot(
      logicalProjectNamespace: base.snapshot.logicalProjectNamespace,
      policyHash: base.snapshot.policyHash,
      entries: [
        for (final entry in base.snapshot.entries)
          if (entry.relativePath == path)
            SourceFileEntry(
                fileId: entry.fileId,
                relativePath: path,
                kind: entry.kind,
                byteLength: bytes[path]!.length,
                sha256: literalFixtureHash(bytes[path]!),
                format: entry.format,
                family: entry.family)
          else
            entry,
      ],
      diagnostics: [],
      excludedPaths: [],
      profileEvidence: base.snapshot.profileEvidence,
      state: SourceScanState.complete);
  final files = LiteralFixtureFiles(snapshot, bytes);
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: files,
      selectedMapIds: {mapId},
      includeEventSystem: true,
      interpretationProfile: fixtureSourceInterpretationProfile);
  return (source: source, files: files);
}

void renameParcelFixture(Map<String, dynamic> events,
    {bool renameGraphics = true}) {
  const actors = {1: 41, 12: 61, 15: 62, 25: 63};
  const switches = {75: 175, 60: 160, 51: 151, 29: 129, 61: 161};
  const variables = {29: 119, 7: 117, 1: 101};
  for (final event in events.values) {
    event['id'] = actors[event['id']] ?? event['id'];
    event['name'] = 'Renamed actor ${event['id']}';
    for (final page in event['pages']) {
      final graphic = page['graphic'] as Map;
      if (renameGraphics && (graphic['character_name'] as String).isNotEmpty) {
        graphic['character_name'] = 'Generic_${event['id']}';
      }
      final condition = page['condition'] as Map;
      for (final key in ['switch1_id', 'switch2_id']) {
        condition[key] = switches[condition[key]] ?? condition[key];
      }
      condition['variable_id'] =
          variables[condition['variable_id']] ?? condition['variable_id'];
      for (final command in page['list']) {
        final parameters = command['parameters'] as List;
        switch (command['code']) {
          case 101:
          case 401:
            parameters[0] = 'Texte libre de la nouvelle histoire.';
          case 111 when parameters[0] == 6:
            parameters[1] = actors[parameters[1]] ?? parameters[1];
          case 121:
            parameters[0] = switches[parameters[0]] ?? parameters[0];
            parameters[1] = switches[parameters[1]] ?? parameters[1];
          case 209:
            parameters[0] = actors[parameters[0]] ?? parameters[0];
        }
        for (var i = 0; i < parameters.length; i++) {
          if (parameters[i] is! String ||
              const {101, 401, 108, 408}.contains(command['code'])) {
            continue;
          }
          var text = parameters[i] as String;
          for (final actor in actors.entries) {
            text = text.replaceAll('pbSetSelfSwitch(${actor.key},',
                'pbSetSelfSwitch(${actor.value},');
            text = text.replaceAll(
                'get_character(${actor.key})', 'get_character(${actor.value})');
          }
          parameters[i] = text
              .replaceAll(':OAKPARCEL', ':SEALEDLETTER')
              .replaceAll(':POKEBALL', ':CAPSULE')
              .replaceAll(
                  'pbReceiveItem(:CAPSULE,5)', 'pbReceiveItem(:CAPSULE,7)')
              .replaceAll('pokedex.unlock(1)', 'pokedex.unlock(3)');
        }
      }
    }
  }
}

Future<({NormalizedSourceProject source, SourceFilePort files})>
    renameBoundParcelSource(
        NormalizedSourceProject source, SourceFilePort files,
        {bool missingDex = false}) async {
  Object? value(MarshalDocument doc, int id) {
    final node = doc.node(id);
    return switch (node.kind) {
      MarshalKind.nil => null,
      MarshalKind.boolean => node.booleanValue,
      MarshalKind.integer => node.integerValue!.toInt(),
      MarshalKind.string => node.text().text!,
      MarshalKind.symbol => LiteralFixtureSymbol(node.name!),
      MarshalKind.array => [
          for (final child in node.elements) value(doc, child)
        ],
      MarshalKind.hash => {
          for (final pair in node.pairs)
            value(doc, pair.key): value(doc, pair.value),
        },
      MarshalKind.object => LiteralFixtureObject(node.className!, {
          for (final field in node.instanceVariables)
            doc.node(field.key).name!: value(doc, field.value),
        }),
      MarshalKind.userDefined =>
        LiteralFixtureUserDefined(node.className!, node.bytes!),
      _ => throw StateError('Unsupported literal fixture node ${node.kind}'),
    };
  }

  Object? plain(Object? input) => switch (input) {
        LiteralFixtureObject() => {
            '__class__': input.name,
            for (final entry in input.fields.entries)
              entry.key.substring(1): plain(entry.value),
          },
        LiteralFixtureUserDefined() => {
            '__class__': input.name,
            'marshalPayload': base64Encode(input.bytes),
          },
        List() => input.map(plain).toList(),
        Map() => {for (final e in input.entries) e.key: plain(e.value)},
        _ => input,
      };
  final replacements = <ConverterId, List<int>>{};
  for (final path in [
    'Data/Map009.rxdata',
    'Data/items.dat',
    'Data/regional_dexes.dat'
  ]) {
    final entry =
        source.snapshot.entries.singleWhere((e) => e.relativePath == path);
    final doc = const MarshalDecoder().decode(await files.read(entry.fileId));
    final raw = value(doc, doc.rootId);
    if (path.endsWith('Map009.rxdata')) {
      final map = raw as LiteralFixtureObject;
      final events = map.fields['@events'] as Map;
      final next = <String, dynamic>{
        for (final e in events.entries) '${e.key}': plain(e.value)
      };
      renameParcelFixture(next, renameGraphics: false);
      map.fields['@events'] = {
        for (final e in next.values) e['id'] as int: _literal(e)
      };
    } else if (path.endsWith('items.dat')) {
      final rows = raw as Map;
      for (final pair in [
        ('OAKPARCEL', 'SEALEDLETTER'),
        ('POKEBALL', 'CAPSULE')
      ]) {
        final key = rows.keys
            .whereType<LiteralFixtureSymbol>()
            .singleWhere((key) => key.value == pair.$1);
        final item = rows.remove(key) as LiteralFixtureObject;
        item.fields['@id'] = LiteralFixtureSymbol(pair.$2);
        rows[LiteralFixtureSymbol(pair.$2)] = item;
      }
    } else {
      final regions = raw as List;
      while (regions.length <= 3) {
        regions.add(null);
      }
      regions[3] = missingDex ? <Object?>[] : regions[1];
    }
    replacements[entry.fileId] = literalFixtureMarshal(raw);
  }
  final snapshot = SourceSnapshot(
      logicalProjectNamespace: source.snapshot.logicalProjectNamespace,
      policyHash: source.snapshot.policyHash,
      entries: [
        for (final entry in source.snapshot.entries)
          if (replacements[entry.fileId] case final bytes?)
            SourceFileEntry(
                fileId: entry.fileId,
                relativePath: entry.relativePath,
                kind: entry.kind,
                byteLength: bytes.length,
                sha256: literalFixtureHash(bytes),
                format: entry.format,
                family: entry.family)
          else
            entry
      ],
      diagnostics: source.snapshot.diagnostics,
      excludedPaths: source.snapshot.excludedPaths,
      profileEvidence: source.snapshot.profileEvidence,
      state: source.snapshot.state);
  final changed = _ParcelOverlayFiles(files, replacements);
  final normalized = await const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: changed,
      selectedMapIds: {9},
      includeEventSystem: true,
      interpretationProfile: source.interpretationProfile);
  return (source: normalized, files: changed);
}

final class _ParcelOverlayFiles implements SourceFilePort {
  const _ParcelOverlayFiles(this.original, this.replacements);
  final SourceFilePort original;
  final Map<ConverterId, List<int>> replacements;
  @override
  Future<List<int>> read(ConverterId id) => replacements.containsKey(id)
      ? Future.value(replacements[id]!)
      : original.read(id);
}
