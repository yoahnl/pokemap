import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/src/native_psdk_catalog.dart';
import 'package:avelune_converter_adapters/src/native_psdk_trainer_bundle.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';

final class NativePsdkReferenceAdmission {
  NativePsdkReferenceAdmission._(
      this._reader, this._definitionPaths, this.definitions, this.families);

  final _ReferenceReader _reader;
  final List<String> _definitionPaths;
  final List<Map<String, Object?>> definitions;
  final List<Map<String, Object?>> families;

  List<NativePsdkCatalogRequest> get requests => [
        for (final row in definitions)
          if (row['status'] == 'admitted')
            NativePsdkCatalogRequest(
                baseId: row['baseId'] as String, form: 0, level: 1),
      ];

  Future<void> verifyUnchanged() async {
    if (canonicalJsonOf(await _definitionFiles(_reader.root)) !=
        canonicalJsonOf(_definitionPaths)) {
      throw StateError(
          'Native reference definitions changed during admission.');
    }
    for (final missing in _reader.missing) {
      if (await File('${_reader.root}/$missing').exists()) {
        throw StateError(
            'Native reference source appeared during admission: $missing.');
      }
    }
    for (final source in _reader.sources.values) {
      final resolved = await File('${_reader.root}/${source.relativePath}')
          .resolveSymbolicLinks();
      if (!resolved.startsWith('${_reader.root}/')) {
        throw StateError('Native reference escaped during admission.');
      }
      final bytes =
          await File('${_reader.root}/${source.relativePath}').readAsBytes();
      if (bytes.length != source.bytes.length ||
          crypto.sha256.convert(bytes).toString() != source.sha256.value) {
        throw StateError(
            'Native reference changed during admission: ${source.relativePath}.');
      }
    }
  }

  Map<String, Object?> toJson({String? catalogManifestHash}) {
    final sources = [
      for (final path in _reader.sources.keys.toList()..sort())
        _reader.sources[path]!.evidence,
    ];
    return {
      'kind': 'nativePsdkReferenceAdmission',
      'version': 1,
      'catalogManifestHash': catalogManifestHash,
      'referenceSnapshotHash': canonicalHashOf({
        'definitionPaths': _definitionPaths,
        'sources': sources,
      }).value,
      'definitions': definitions,
      'families': families,
      'sources': sources,
      'counts': {
        'inspectedBases': definitions.length,
        'inspectedForms': definitions.fold<int>(
            0, (count, row) => count + (row['forms'] as List).length),
        'admittedBases': requests.length,
        'refusedBases': definitions.length - requests.length,
      },
      'sourceScriptsExecuted': 0,
      'aiSourceInferenceCalls': 0,
    };
  }
}

Future<NativePsdkReferenceAdmission> inspectNativePsdkReference({
  required String root,
  required Future<NativePsdkTrainerBundle> Function(
          List<NativePsdkCatalogRequest>)
      qualifyFamily,
  void Function(int done, int total)? onProgress,
}) async {
  final reader = _ReferenceReader(await Directory(root).resolveSymbolicLinks());
  final paths = await _definitionFiles(reader.root);
  if (paths.isEmpty ||
      paths.length > const NativePsdkCatalogLimits().maxRequests) {
    throw StateError('Native reference definition count exceeds its bounds.');
  }
  final globalReasons = <Map<String, Object?>>[];
  Map<int, String> englishNames = const {};
  const namePath = 'Data/Text/Dialogs/100000.csv';
  final names = await reader.read(namePath);
  if (names == null) {
    globalReasons.add({'code': 'source_missing', 'relativePath': namePath});
  } else {
    try {
      englishNames = nativePsdkEnglishSpeciesNames(names);
    } on ContractError catch (error) {
      globalReasons.add({
        'code': error.code,
        'relativePath': namePath,
        'detail': error.message
      });
    }
  }
  final definitions = <String, _Definition>{};
  for (final path in paths) {
    final base = path.substring('Data/Studio/pokemon/'.length, path.length - 5);
    final source = await reader.read(path);
    final definition = _Definition(base, source!);
    definitions[base] = definition;
    definition.inspect();
    definition.englishName = englishNames[definition.nativeId];
    if (definition.englishName?.trim().isNotEmpty != true) {
      definition.refuse('species_name_missing', namePath,
          detail: '${definition.nativeId}');
    }
  }
  final links = {
    for (final base in definitions.keys) base: <String>{},
  };
  for (final definition in definitions.values) {
    for (final target in definition.targets) {
      final other = definitions[target.$1];
      if (other == null) {
        definition.refuse('species_dependency_missing',
            'Data/Studio/pokemon/${target.$1}.json');
      } else {
        links[definition.base]!.add(other.base);
        links[other.base]!.add(definition.base);
      }
    }
  }
  final pending = definitions.keys.toSet();
  final groups = <List<String>>[];
  while (pending.isNotEmpty) {
    final group = <String>{};
    final queue = [pending.first];
    for (var i = 0; i < queue.length; i++) {
      final base = queue[i];
      if (!group.add(base)) continue;
      queue.addAll(links[base]!);
    }
    pending.removeAll(group);
    groups.add(group.toList()..sort());
  }
  groups.sort((a, b) => a.first.compareTo(b.first));
  final rows = <Map<String, Object?>>[];
  final families = <Map<String, Object?>>[];
  for (var offset = 0; offset < groups.length; offset++) {
    final group = groups[offset];
    final reasons = <String, Map<String, Object?>>{};
    void addReason(Map<String, Object?> reason) =>
        reasons[canonicalJsonOf(reason)] = reason;
    for (final reason in globalReasons) {
      addReason(reason);
    }
    final references = <String>{
      'Data/Text/Dialogs/100000.csv',
      'Data/Text/Dialogs/100067.csv',
      for (final id in nativeQualifiedFieldMoveSourceHashes.keys)
        'Data/Studio/moves/$id.json',
      for (final id in nativeTrainerTypeIds) 'Data/Studio/types/$id.json',
      for (final id in canonicalPokemonNatureIds)
        'Data/Studio/natures/$id.json',
    };
    for (final base in group) {
      final definition = definitions[base]!;
      for (final reason in definition.reasons) {
        addReason(reason);
      }
      references.addAll(definition.references);
    }
    for (final path in references.toList()..sort()) {
      final source = await reader.read(path);
      if (source == null) {
        addReason({'code': 'source_missing', 'relativePath': path});
      } else if (path.endsWith('.json')) {
        try {
          final raw = jsonDecode(utf8.decode(source.bytes));
          if (raw is! Map) {
            addReason({'code': 'source_json', 'relativePath': path});
          } else if (raw.containsKey('version') ||
              raw.containsKey('schemaVersion')) {
            addReason({'code': 'source_version', 'relativePath': path});
          }
        } on FormatException {
          addReason({'code': 'source_json', 'relativePath': path});
        }
      }
    }
    if (reasons.isEmpty) {
      try {
        final bundle = await qualifyFamily([
          for (final base in group)
            NativePsdkCatalogRequest(baseId: base, form: 0, level: 1),
        ]);
        for (final raw in bundle.evidence['sources'] as List) {
          final witness = raw as Map;
          final path = witness['relativePath'] as String;
          final actual = await reader.read(path);
          if (actual == null ||
              actual.sha256.value != witness['sha256'] ||
              actual.bytes.length != witness['byteLength']) {
            throw StateError('Native qualification source changed: $path.');
          }
        }
      } on ContractError catch (error) {
        addReason({
          'code': error.code,
          'relativePath': error.path,
          'detail': error.message,
        });
      }
    }
    final orderedReasons = [
      for (final key in reasons.keys.toList()..sort()) reasons[key]!,
    ];
    final status = reasons.isEmpty ? 'admitted' : 'refused';
    final familyId = canonicalHashOf(group).value;
    families.add({
      'familyId': familyId,
      'baseIds': group,
      'status': status,
      'reasons': orderedReasons,
    });
    for (final base in group) {
      final definition = definitions[base]!;
      rows.add({
        'baseId': base,
        'englishName': definition.englishName,
        'source': definition.source.evidence,
        'forms': definition.forms,
        'nativeSpeciesIds': [
          for (final form in definition.forms)
            nativePsdkFormSpeciesId(base, form),
        ],
        'familyId': familyId,
        'status': status,
        'reasons': orderedReasons,
      });
    }
    onProgress?.call(offset + 1, groups.length);
  }
  rows.sort((a, b) => (a['baseId'] as String).compareTo(b['baseId'] as String));
  return NativePsdkReferenceAdmission._(reader, paths, rows, families);
}

Future<List<String>> _definitionFiles(String root) async {
  final directory = Directory('$root/Data/Studio/pokemon');
  return [
    await for (final entry in directory.list(followLinks: false))
      if (entry.path.endsWith('.json'))
        'Data/Studio/pokemon/${entry.path.split(Platform.pathSeparator).last}',
  ]..sort();
}

final class _ReferenceReader {
  _ReferenceReader(this.root);
  final String root;
  final sources = <String, NativePsdkTrainerSourceFile>{};
  int _totalBytes = 0;
  final missing = <String>{};

  Future<NativePsdkTrainerSourceFile?> read(String path) async {
    if (sources[path] case final previous?) return previous;
    if (!RegExp(
            r'^(Data/Studio/[a-z_]+/[a-z0-9_]+\.json|Data/Text/Dialogs/(100000|100067)\.csv|graphics/pokedex/poke(front|back)/[a-z0-9_]+\.png)$')
        .hasMatch(path)) {
      throw StateError('Native reference path is invalid: $path.');
    }
    final file = File('$root/$path');
    if (!await file.exists()) {
      missing.add(path);
      return null;
    }
    final resolved = await file.resolveSymbolicLinks();
    if (!resolved.startsWith('$root/')) {
      throw StateError('Native reference escaped its root: $path.');
    }
    if (await file.length() > 1048576 ||
        sources.length >= const NativePsdkCatalogLimits().maxSourceFiles) {
      throw StateError('Native reference source exceeds its bounds: $path.');
    }
    final bytes = await file.readAsBytes();
    if (_totalBytes + bytes.length >
        const NativePsdkCatalogLimits().maxSourceBytes) {
      throw StateError('Native reference total bytes exceed their bound.');
    }
    _totalBytes += bytes.length;
    final source = NativePsdkTrainerSourceFile(
        relativePath: path,
        sha256: Sha256Hash(crypto.sha256.convert(bytes).toString()),
        bytes: bytes);
    sources[path] = source;
    return source;
  }
}

final class _Definition {
  _Definition(this.base, this.source);
  final String base;
  final NativePsdkTrainerSourceFile source;
  final forms = <int>[];
  final targets = <(String, int)>[];
  final references = <String>{};
  final reasons = <Map<String, Object?>>[];
  int? nativeId;
  String? englishName;

  void refuse(String code, String path, {String? detail}) => reasons.add({
        'code': code,
        'relativePath': path,
        if (detail != null) 'detail': detail,
      });

  void inspect() {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(source.bytes));
    } on FormatException {
      refuse('species_json', source.relativePath);
      return;
    }
    if (decoded is! Map<String, dynamic> ||
        decoded.keys.any((key) =>
            !const {'klass', 'id', 'dbSymbol', 'forms'}.contains(key)) ||
        !RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(base) ||
        decoded['klass'] != 'Specie' ||
        decoded['id'] is! int ||
        (decoded['id'] as int) < 0 ||
        decoded['dbSymbol'] != base ||
        decoded['forms'] is! List ||
        (decoded['forms'] as List).isEmpty) {
      refuse('species_schema', source.relativePath);
    }
    if (decoded is Map && decoded['id'] is int) nativeId = decoded['id'] as int;
    if (decoded is! Map || decoded['forms'] is! List) return;
    for (final raw in decoded['forms'] as List) {
      if (raw is! Map ||
          raw['form'] is! int ||
          (raw['form'] as int) < 0 ||
          forms.contains(raw['form'])) {
        refuse('species_form', source.relativePath);
        continue;
      }
      forms.add(raw['form'] as int);
      final moves = raw['moveSet'];
      final abilities = raw['abilities'];
      final evolutions = raw['evolutions'];
      if (moves is! List || abilities is! List || evolutions is! List) {
        refuse('species_form_schema', source.relativePath);
        continue;
      }
      for (final move in moves) {
        if (move is! Map ||
            move['move'] is! String ||
            !RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(move['move'] as String)) {
          refuse('move_identity', source.relativePath);
        } else {
          references.add('Data/Studio/moves/${move['move']}.json');
        }
      }
      for (final ability in abilities) {
        if (ability is! String ||
            !RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(ability)) {
          refuse('ability_identity', source.relativePath);
        } else {
          references.add('Data/Studio/abilities/$ability.json');
        }
      }
      for (final rule in evolutions) {
        if (rule is! Map) {
          refuse('evolution_schema', source.relativePath);
          continue;
        }
        final target = rule['dbSymbol'] ?? base;
        final form = rule['form'];
        if (target is! String || form is! int || form < 0) {
          refuse('evolution_schema', source.relativePath);
        } else {
          targets.add((target, form));
        }
        if (rule['conditions'] case final List conditions) {
          for (final condition in conditions) {
            if (condition is Map &&
                condition['type'] == 'skill1' &&
                condition['value'] is String) {
              references.add('Data/Studio/moves/${condition['value']}.json');
            }
            if (condition is Map && condition['type'] == 'tradeWith') {
              final partner = condition['value'];
              if (partner is! String ||
                  !RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(partner)) {
                refuse('trade_partner_identity', source.relativePath);
              } else {
                targets.add((partner, 0));
              }
            }
          }
        }
      }
      final baby = raw['babyDbSymbol'];
      if (baby is String && baby != 'none' && baby != '__undef__') {
        final form = raw['babyForm'];
        if (form is int && form >= 0) {
          targets.add((baby, form));
        } else {
          refuse('baby_form_schema', source.relativePath);
        }
      }
      if (raw['form'] != 0) {
        final resources = raw['resources'];
        for (final side in ['front', 'back']) {
          final value = resources is Map ? resources[side] : null;
          if (value is! String || !RegExp(r'^[a-z0-9_]+$').hasMatch(value)) {
            refuse('media_identity', source.relativePath);
          } else {
            references.add('graphics/pokedex/poke$side/$value.png');
          }
        }
      }
    }
    forms.sort();
    if (!forms.contains(0)) refuse('base_form_missing', source.relativePath);
  }
}
