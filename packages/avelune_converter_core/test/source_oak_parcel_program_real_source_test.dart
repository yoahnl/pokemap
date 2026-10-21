import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';

import 'support/interpretation_profile_fixture.dart';
import 'support/source_external_original_fixture.dart';

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final enabled = root != null &&
      snapshot != null &&
      Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'] != null;
  const sourcePath = 'Data/Map009.rxdata';
  Future<NormalizedSourceProject> read({List<int>? changed}) async {
    final fixture = await readExternalOriginalSource(root!, snapshot!,
        selectedMapIds: const {
          9
        },
        overrideBytes: {
          if (changed != null) sourcePath: changed,
        });
    return const RmxpSourceNormalizer().normalize(
        snapshot: fixture.source.snapshot,
        files: _SupplementalFiles(fixture.files),
        selectedMapIds: const {9},
        includeEventSystem: true,
        interpretationProfile: externalOracleInterpretationProfile());
  }

  SourceEvent oak(NormalizedSourceProject source) =>
      source.maps.single.map.events.singleWhere((e) => e.sourceEventId == 1);
  SourceOakParcelProgram? program(NormalizedSourceProject source) =>
      SourceOakParcelProgram.read(
          source: source,
          profile: SourceEventProfile.forProject(source),
          sourceMapId: 9,
          event: oak(source));
  group('attested Oak parcel program', () {
    late NormalizedSourceProject source;
    late List<int> bytes;
    setUpAll(() async {
      bytes = await File('$root/$sourcePath').readAsBytes();
      source = await read();
    });
    test('recognizes four approaches and retains all six page conditions', () {
      final found = program(source);
      expect(found, isNotNull);
      final value = found!;
      expect(
          value.isBoundTo(
              source: source,
              profile: SourceEventProfile.forProject(source),
              event: oak(source)),
          isTrue);
      expect(value.pages, hasLength(6));
      expect(value.pageConditions, hasLength(6));
      expect(value.pageConditions[4]['switch1_id'], 51);
      expect(value.pageConditions[5]['switch1_id'], 29);
      expect(
          SourceOakParcelProgram.approaches.map((a) => a.sourcePlayerDirection),
          [2, 8, 4, 6]);
      expect(SourceOakParcelProgram.approaches.map((a) => a.firstCommandIndex),
          [9, 136, 275, 420]);
      final commands = (value.pages[2]['list'] as List).cast<Map>();
      expect(commands, hasLength(572));
      expect(commands[4]['parameters'], [12, r'$bag.has?(:OAKPARCEL)']);
      expect(commands[6]['parameters'], [r'$player.has_pokedex = true']);
      expect(commands[7]['parameters'], [r'$player.pokedex.unlock(1)']);
      expect(commands[8]['parameters'], [60, 60, 0]);
      for (final index in [16, 143, 282, 427]) {
        expect(commands[index]['parameters'], [r'$bag.remove(:OAKPARCEL)']);
      }
      for (final index in [91, 230, 375, 511]) {
        expect(commands[index]['parameters'], ['pbReceiveItem(:POKEBALL,5)']);
      }
      for (final indices in [(79, 80), (218, 219), (363, 364), (499, 500)]) {
        expect(commands[indices.$1]['parameters'],
            ['pbSetSelfSwitch(12,"A",true)']);
        expect(commands[indices.$2]['parameters'],
            ['pbSetSelfSwitch(15,"A",true)']);
      }
      final json = value.toJson();
      expect(json['adaptedPageIndices'], [0, 1, 2, 3]);
      expect(json['unsupportedPageIndices'], [4, 5]);
      expect(json['nativeExecutionQualified'], isFalse);
      expect(json['staticSemanticsQualified'], isFalse);
      expect(json['sourceScriptsExecuted'], 0);
      expect(json['aiCalls'], 0);
      expect(value.rawDataRef.locator!.file, sourcePath);
      expect(() => value.raw['x'] = 99, throwsUnsupportedError);
      expect(
          () => (value.raw['pages'] as List).clear(), throwsUnsupportedError);
    });
    for (final row in [
      (r'$bag.remove(:OAKPARCEL)', r'$bag.remove(:OAKPARCEL,2)'),
      ('pbReceiveItem(:POKEBALL,5)', 'pbReceiveItem(:POKEBALL,6)'),
      (r'$player.pokedex.unlock(1)', r'$player.pokedex.unlock(2)'),
      (r'$player.has_pokedex = true', r'$player.has_pokedex = false'),
      ('pbSetSelfSwitch(25,"A",true)', 'pbSetSelfSwitch(26,"A",true)'),
      ('pbSetSelfSwitch(12,"A",true)', 'pbSetSelfSwitch(12,"B",true)'),
      ('FollowingPkmn.toggle_off', 'arbitrary_source_call()'),
      ('pbExclaim(get_character(1))', 'pbExclaim(get_character(2))'),
    ]) {
      test('refuses altered business effect or actor ${row.$1}', () async {
        expect(
            program(
                await read(changed: _replaceLiteral(bytes, row.$1, row.$2))),
            isNull);
      });
    }
    for (final row in [
      (0, '@switch1_id', 76),
      (2, '@variable_value', 2),
      (3, '@switch2_id', 61),
      (4, '@switch1_id', 52),
      (5, '@switch1_id', 30)
    ]) {
      test('refuses altered priority condition on page ${row.$1}', () async {
        final changed = _changeNodeInteger(
            bytes,
            (doc) => _field(
                doc, _field(doc, _oakPages(doc)[row.$1], '@condition'), row.$2),
            row.$3);
        expect(program(await read(changed: changed)), isNull);
      });
    }
    test(
        'refuses altered movement instead of reducing the cutscene to a reward',
        () async {
      final changed = _changeNodeInteger(bytes, (doc) {
        final list = doc.node(_field(doc, _oakPages(doc)[2], '@list')).elements;
        final parameters =
            doc.node(_field(doc, list[26], '@parameters')).elements;
        final route = doc.node(_field(doc, parameters[1], '@list')).elements;
        return _field(doc, route.first, '@code');
      }, 2);
      expect(program(await read(changed: changed)), isNull);
    });
    test('refuses unknown source commands within a recognized page', () async {
      final changed = _changeNodeInteger(bytes, (doc) {
        final list = doc.node(_field(doc, _oakPages(doc)[2], '@list')).elements;
        return _field(doc, list[5], '@code');
      }, 354);
      expect(program(await read(changed: changed)), isNull);
    });
    test('refuses an event command array above the explicit 1024 ceiling',
        () async {
      final changed = _extendParcelCommandArray(bytes, 1025);
      final next = await read(changed: changed);
      expect(oak(next).pages[2].commands, hasLength(1025));
      expect(program(next), isNull);
    });
    test(
        'keeps later unsupported bodies quarantined rather than inferring support',
        () async {
      final changed = _changeNodeInteger(bytes, (doc) {
        final list = doc.node(_field(doc, _oakPages(doc)[4], '@list')).elements;
        return _field(doc, list[3], '@code');
      }, 354);
      final next = program(await read(changed: changed));
      expect(next, isNotNull);
      expect(next!.toJson()['unsupportedPageIndices'], contains(4));
      expect(next.toJson()['staticSemanticsQualified'], isFalse);
      expect(next.programHash, isNot(program(source)!.programHash));
    });
    test('allows changed dialogue only with a freshly bound proof', () async {
      final changed = await read(
          changed: _replaceLiteral(
              bytes, r'\bOak: Now, \PN.', r'\bOak: Hello, \PN.'));
      final original = program(source)!;
      final next = program(changed);
      expect(next, isNotNull);
      expect(next!.programHash, isNot(original.programHash));
      expect(
          original.isBoundTo(
              source: changed,
              profile: SourceEventProfile.forProject(changed),
              event: oak(changed)),
          isFalse);
    });
    test('refuses mismatched source maps and unattested profiles', () {
      final profile = SourceEventProfile.forProject(source);
      expect(
          SourceOakParcelProgram.read(
              source: source,
              profile: profile,
              sourceMapId: 10,
              event: oak(source)),
          isNull);
      expect(
          SourceOakParcelProgram.read(
              source: source,
              profile: SourceEventProfile(
                  scriptsArchiveHash: profile.scriptsArchiveHash,
                  sourceSnapshotHash: profile.sourceSnapshotHash,
                  normalizationHash: profile.normalizationHash),
              sourceMapId: 9,
              event: oak(source)),
          isNull);
      expect(
          SourceOakParcelProgram.read(
              source: source,
              profile: SourceEventProfile(
                  scriptsArchiveHash: profile.scriptsArchiveHash,
                  sourceSnapshotHash: Sha256Hash('0' * 64),
                  normalizationHash: profile.normalizationHash,
                  interpretationProfile: profile.interpretationProfile),
              sourceMapId: 9,
              event: oak(source)),
          isNull);
    });
  },
      skip: enabled
          ? false
          : 'Requires immutable original source and attested profile.');
}

int _field(MarshalDocument doc, int nodeId, String name) => doc
    .node(nodeId)
    .instanceVariables
    .singleWhere((pair) => doc.node(pair.key).name == name)
    .value;
List<int> _oakPages(MarshalDocument doc) {
  final events = doc.node(_field(doc, doc.rootId, '@events')).pairs;
  final oak = events
      .singleWhere((pair) => doc.node(pair.key).integerValue == BigInt.one)
      .value;
  return doc.node(_field(doc, oak, '@pages')).elements;
}

List<int> _changeNodeInteger(
    List<int> bytes, int Function(MarshalDocument) target, int value) {
  final doc = const MarshalDecoder().decode(bytes);
  final node = doc.node(target(doc));
  expect(node.kind, MarshalKind.integer);
  final offset = node.location.byteOffset;
  expect(bytes[offset], 105);
  final width = bytes[offset + 1] < 5 ? bytes[offset + 1] + 1 : 1;
  return [
    ...bytes.take(offset + 1),
    ..._positiveMarshalInteger(value),
    ...bytes.skip(offset + 1 + width)
  ];
}

List<int> _positiveMarshalInteger(int value) {
  if (value == 0) return [0];
  if (value < 123) return [value + 5];
  final bytes = <int>[];
  var remaining = value;
  while (remaining > 0) {
    bytes.add(remaining & 255);
    remaining >>= 8;
  }
  return [bytes.length, ...bytes];
}

List<int> _extendParcelCommandArray(List<int> bytes, int length) {
  final doc = const MarshalDecoder().decode(bytes);
  final pages = _oakPages(doc);
  final list = doc.node(_field(doc, pages[2], '@list'));
  final end = doc.node(pages[3]).location.byteOffset;
  final target = list.elements.last;
  final objects = doc.nodes
      .take(target)
      .where((node) => !const {
            MarshalKind.nil,
            MarshalKind.boolean,
            MarshalKind.integer,
            MarshalKind.symbol,
          }.contains(node.kind))
      .length;
  final reference = [64, ..._positiveMarshalInteger(objects)];
  final offset = list.location.byteOffset;
  expect(bytes[offset], 91);
  final oldCountWidth = bytes[offset + 1] + 1;
  return [
    ...bytes.take(offset + 1),
    ..._positiveMarshalInteger(length),
    ...bytes.sublist(offset + 1 + oldCountWidth, end),
    for (var i = list.elements.length; i < length; i++) ...reference,
    ...bytes.skip(end)
  ];
}

List<int> _replaceLiteral(List<int> bytes, String before, String after) {
  final old = utf8.encode(before), next = utf8.encode(after);
  if (old.length >= 123 || next.length >= 123) {
    throw StateError('Fixture quota');
  }
  final pattern = [34, old.length + 5, ...old];
  for (var i = 0; i <= bytes.length - pattern.length; i++) {
    if (List.generate(pattern.length, (j) => bytes[i + j] == pattern[j])
        .every((v) => v)) {
      return [
        ...bytes.take(i),
        34,
        next.length + 5,
        ...next,
        ...bytes.skip(i + pattern.length)
      ];
    }
  }
  throw StateError('Missing source literal: $before');
}

final class _SupplementalFiles implements SourceFilePort {
  const _SupplementalFiles(this.primary);
  final ExternalOriginalFiles primary;

  @override
  Future<List<int>> read(ConverterId id) async {
    final entry = primary.snapshot.entries.singleWhere((e) => e.fileId == id);
    if (primary.overrideBytes.containsKey(entry.relativePath)) {
      return primary.read(id);
    }
    for (final root in [
      primary.root,
      ...(Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ?? '')
          .split('|')
          .where((value) => value.isNotEmpty),
    ]) {
      final file = File('$root/${entry.relativePath}');
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      if (bytes.length == entry.byteLength &&
          crypto.sha256.convert(bytes).toString() == entry.sha256?.value) {
        return bytes;
      }
    }
    return primary.read(id);
  }
}
