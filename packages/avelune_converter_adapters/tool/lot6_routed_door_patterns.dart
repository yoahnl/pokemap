import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as image;

Future<({SourceInterpretationProfile profile, Map<String, Object?> evidence})>
    deriveLot6RoutedDoorPatterns(
        {required SourceSnapshot snapshot,
        required SourceFilePort files,
        required SourceInterpretationProfile profile,
        ScanCancellation? cancellation}) async {
  final token = cancellation ?? ScanCancellation();
  final scripts = snapshot.entries
      .where((entry) => entry.relativePath == 'Data/Scripts.rxdata')
      .singleOrNull;
  if (snapshot.state != SourceScanState.complete ||
      !profile.supports('events') ||
      scripts?.sha256 == null ||
      !profile.matchesArchive(scripts!.sha256)) {
    throw ContractError('door_patterns.profile', r'$',
        'Door pattern declarations require a complete pinned source profile.');
  }
  Future<List<int>> read(SourceFileEntry entry, int maximum) async {
    token.check();
    if (entry.kind != SourceNodeKind.file ||
        entry.sha256 == null ||
        entry.byteLength > maximum) {
      throw ContractError('door_patterns.source', entry.relativePath,
          'Source witnesses must be bounded attested regular files.');
    }
    final bytes = await files.read(entry.fileId);
    token.check();
    if (bytes.length != entry.byteLength ||
        bytes.any((b) => b < 0 || b > 255) ||
        crypto.sha256.convert(bytes).toString() != entry.sha256!.value) {
      throw ContractError('door_patterns.changed', entry.relativePath,
          'Source bytes changed after inventory.');
    }
    return bytes;
  }

  final maps = snapshot.entries
      .where((entry) =>
          RegExp(r'^Data/Map[0-9]+\.rxdata$').hasMatch(entry.relativePath))
      .toList()
    ..sort((a, b) => a.relativePath.compareTo(b.relativePath));
  if (maps.length > 4096 ||
      maps.fold<int>(0, (sum, e) => sum + e.byteLength) > 268435456) {
    throw ContractError('door_patterns.quota', r'$',
        'Map inventory exceeds the bounded declaration scan.');
  }
  final candidates = <(String, int, int), List<Map<String, Object?>>>{};
  for (final entry in maps) {
    final bytes = await read(entry, 33554432);
    final document = const MarshalDecoder().decode(bytes,
        limits: const MarshalDecodeLimits(
            maxInputBytes: 33554432, maxNodes: 1000000),
        sourcePath: entry.relativePath);
    final reader = _DoorPatternReader(document);
    final root = reader.fields(document.rootId, 'RPG::Map');
    if (root == null || root['@events'] == null) {
      continue;
    }
    final events = reader.plain(root['@events']!, MarshalKind.hash);
    if (events == null || events.pairs.length > 10000) {
      continue;
    }
    for (final pair in events.pairs) {
      token.check();
      final event = reader.fields(pair.value, 'RPG::Event');
      if (event == null || event['@pages'] == null) {
        continue;
      }
      final id = reader.integer(pair.key);
      if (id == null || id <= 0 || reader.integer(event['@id']) != id) {
        continue;
      }
      final pages = reader.plain(event['@pages']!, MarshalKind.array);
      if (pages == null || pages.elements.length != 2) {
        continue;
      }
      final first = reader.fields(pages.elements[0], 'RPG::Event::Page');
      final last = reader.fields(pages.elements[1], 'RPG::Event::Page');
      if (first == null ||
          last == null ||
          reader.integer(first['@trigger']) != 1 ||
          reader.integer(last['@trigger']) != 3 ||
          !reader.skeleton(first['@list'], true) ||
          !reader.skeleton(last['@list'], false)) {
        continue;
      }
      final a = reader.graphic(first), b = reader.graphic(last);
      if (a == null || b == null || a.$1 != b.$1 || a.$2 == b.$2) {
        continue;
      }
      (candidates.putIfAbsent((a.$1, a.$2, b.$2), () => [])).add({
        'sourceMapFile': entry.relativePath,
        'sourceMapHash': entry.sha256!.value,
        'sourceEventId': id,
        'departurePageIndex': 0,
        'arrivalPageIndex': 1,
      });
      if (candidates.length > 128) {
        throw ContractError('door_patterns.quota', r'$',
            'Too many distinct door pattern declarations.');
      }
    }
  }
  final declared = [...?profile.presentationBindings?.routedDoorPatterns];
  final witnesses = <Map<String, Object?>>[];
  final keys = candidates.keys.toList()
    ..sort((a, b) =>
        '${a.$1}:${a.$2}:${a.$3}'.compareTo('${b.$1}:${b.$2}:${b.$3}'));
  for (final key in keys) {
    token.check();
    final path = 'Graphics/Characters/${key.$1}.png';
    final images = snapshot.entries
        .where((entry) =>
            sourcePathCollisionKey(entry.relativePath) ==
            sourcePathCollisionKey(path))
        .toList();
    if (images.length != 1 || images.single.relativePath != path) {
      continue;
    }
    final entry = images.single;
    final bytes = await read(entry, 16777216);
    final info = image.PngDecoder().startDecode(Uint8List.fromList(bytes));
    if (info == null ||
        info.width <= 0 ||
        info.height <= 0 ||
        info.width > 4096 ||
        info.height > 4096 ||
        info.width % 4 != 0 ||
        info.height % 4 != 0) {
      continue;
    }
    final previous = declared
        .where((value) =>
            value.charset == key.$1 &&
            value.departurePattern == key.$2 &&
            value.arrivalPattern == key.$3)
        .toList();
    if (previous.length > 1 ||
        (previous.isNotEmpty && previous.single.sha256 != entry.sha256)) {
      throw ContractError('door_patterns.conflict', path,
          'An existing declaration conflicts with the exact source atlas.');
    }
    final binding = SourceRoutedDoorPattern.fromJson({
      'charset': key.$1,
      'sha256': entry.sha256!.value,
      'departurePattern': key.$2,
      'arrivalPattern': key.$3
    });
    if (previous.isEmpty) declared.add(binding);
    witnesses.add({
      'declaration': binding.toJson(),
      'sourceImageFileId': entry.fileId.value,
      'sourceImagePath': path,
      'sourceImageBytes': entry.byteLength,
      'sourceEventCandidates': candidates[key]
    });
  }
  declared.sort((a, b) =>
      canonicalJsonOf(a.toJson()).compareTo(canonicalJsonOf(b.toJson())));
  final result = witnesses.isEmpty
      ? profile
      : SourceInterpretationProfile.fromJson({
          ...profile.toJson(),
          'presentationBindings': {
            ...?profile.toJson()['presentationBindings']
                as Map<String, Object?>?,
            'routedDoorPatterns':
                declared.map((value) => value.toJson()).toList(),
          },
        });
  return (
    profile: result,
    evidence: {
      'kind': 'sourceRoutedDoorPatternDeclarations',
      'version': 1,
      'sourceSnapshotHash': snapshot.canonicalHash.value,
      'inputProfileHash': profile.canonicalHash.value,
      'outputProfileHash': result.canonicalHash.value,
      'nativePresentationAdaptation': 'nativeStableDepartureDoorSkin',
      'sourceVisualParityQualified': false,
      'sourceProgramsQualified': false,
      'eventAdmission':
          'completeSourceRoutedDoorProgramMatcherAndRawRebindingRequired',
      'sourceScriptsExecuted': 0,
      'aiSourceInferenceCalls': 0,
      'declarations': witnesses,
    }
  );
}

final class _DoorPatternReader {
  _DoorPatternReader(this.document);
  final MarshalDocument document;
  MarshalNode? plain(int? id, MarshalKind kind) {
    if (id == null) {
      return null;
    }
    final node = document.node(id);
    return node.kind == kind &&
            node.extensions.isEmpty &&
            node.userClass == null &&
            node.instanceVariables.isEmpty
        ? node
        : null;
  }

  int? integer(int? id) {
    final value = plain(id, MarshalKind.integer)?.integerValue;
    return value == null ||
            value < BigInt.zero ||
            value > BigInt.from(2147483647)
        ? null
        : value.toInt();
  }

  String? literalText(int? id) {
    if (id == null) return null;
    final node = document.node(id);
    if (node.kind != MarshalKind.string ||
        node.extensions.isNotEmpty ||
        node.userClass != null ||
        node.instanceVariables.length > 2) {
      return null;
    }
    final keys = <String>{};
    for (final pair in node.instanceVariables) {
      final key = plain(pair.key, MarshalKind.symbol)?.name;
      if (key == null ||
          !const {'E', 'encoding'}.contains(key) ||
          !keys.add(key) ||
          plain(pair.value,
                  key == 'E' ? MarshalKind.boolean : MarshalKind.string) ==
              null) {
        return null;
      }
    }
    return node.text().text;
  }

  Map<String, int>? fields(int id, String name) {
    final node = document.node(id);
    if (node.kind != MarshalKind.object ||
        node.className != name ||
        node.extensions.isNotEmpty ||
        node.userClass != null ||
        node.instanceVariables.length > 32) {
      return null;
    }
    final fields = <String, int>{};
    for (final pair in node.instanceVariables) {
      final key = plain(pair.key, MarshalKind.symbol)?.name;
      if (key == null || fields.containsKey(key)) {
        return null;
      }
      fields[key] = pair.value;
    }
    return fields;
  }

  (String, int)? graphic(Map<String, int> page) {
    if (integer(page['@move_type']) != 0 || page['@graphic'] == null) {
      return null;
    }
    final values = fields(page['@graphic']!, 'RPG::Event::Page::Graphic');
    if (values == null ||
        integer(values['@tile_id']) != 0 ||
        integer(values['@character_hue']) != 0 ||
        integer(values['@opacity']) != 255 ||
        integer(values['@blend_type']) != 0 ||
        integer(values['@direction']) != 2) {
      return null;
    }
    final name = literalText(values['@character_name']);
    final pattern = integer(values['@pattern']);
    if (name == null ||
        name.isEmpty ||
        name.length > 128 ||
        RegExp(r'[\\/<>:\x00-\x1f]').hasMatch(name) ||
        name.trim() != name ||
        pattern == null ||
        pattern > 3) {
      return null;
    }
    return (name, pattern);
  }

  bool skeleton(int? id, bool departure) {
    final list = plain(id, MarshalKind.array);
    if (list == null || list.elements.length > 128) return false;
    final found = <(int, int)>[];
    for (final id in list.elements) {
      final command = fields(id, 'RPG::EventCommand');
      if (command == null) return false;
      final code = integer(command['@code']),
          indent = integer(command['@indent']);
      if (code == null || indent == null) return false;
      if (code != 509) found.add((code, indent));
    }
    return canonicalJsonOf([
          for (final v in found) [v.$1, v.$2]
        ]) ==
        canonicalJsonOf(departure
            ? [
                [209, 0],
                [210, 0],
                [209, 0],
                [210, 0],
                [208, 0],
                [209, 0],
                [210, 0],
                [223, 0],
                [106, 0],
                [208, 0],
                [201, 0],
                [223, 0],
                [0, 0]
              ]
            : [
                [111, 0],
                [208, 1],
                [209, 1],
                [210, 1],
                [208, 1],
                [209, 1],
                [210, 1],
                [209, 1],
                [210, 1],
                [0, 1],
                [412, 0],
                [355, 0],
                [0, 0]
              ]);
  }
}
