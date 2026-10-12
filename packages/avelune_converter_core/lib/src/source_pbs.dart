part of '../avelune_converter_core.dart';

enum SourcePbsFamily {
  species,
  forms,
  items,
  moves,
  trainerTypes,
  trainers,
  encounters,
  types,
  abilities
}

enum SourcePbsProfile { essentials21_1 }

final class SourcePbsLimits {
  const SourcePbsLimits({
    this.maxDocuments = 128,
    this.maxFileBytes = 8388608,
    this.maxTotalBytes = 33554432,
    this.maxLines = 400000,
    this.maxLineCodeUnits = 65536,
    this.maxEntries = 100000,
    this.maxFields = 2000000,
    this.maxTokens = 4000000,
    this.maxDiagnostics = 100000,
  });

  final int maxDocuments;
  final int maxFileBytes;
  final int maxTotalBytes;
  final int maxLines;
  final int maxLineCodeUnits;
  final int maxEntries;
  final int maxFields;
  final int maxTokens;
  final int maxDiagnostics;
}

final class SourcePbsIdentity {
  SourcePbsIdentity({
    required this.namespace,
    required SourcePbsFamily family,
    this.sourceSymbol,
    this.form = 0,
    this.trainerType,
    this.trainerName,
    this.version = 0,
    this.sourceMapId,
  }) : family =
            family == SourcePbsFamily.forms ? SourcePbsFamily.species : family;

  final ConverterId namespace;
  final SourcePbsFamily family;
  final String? sourceSymbol;
  final int form;
  final String? trainerType;
  final String? trainerName;
  final int version;
  final int? sourceMapId;
  late final String key = canonicalJsonOf(toJson());
  late final ConverterId sourceId = ConverterId(
      'source-pbs-${canonicalHashOf(toJson()).value.substring(0, 24)}');
  Map<String, Object?> toJson() => Map.unmodifiable({
        'namespace': namespace.value,
        'family': family.name,
        'sourceSymbol': sourceSymbol,
        'form': form,
        'trainerType': trainerType,
        'trainerName': trainerName,
        'version': version,
        'sourceMapId': sourceMapId,
      });
}

ConverterId sourcePbsItemBindingId(
        ConverterId namespace, String sourceSymbol) =>
    ConverterId('source-item-${canonicalHashOf({
          'namespace': namespace.value,
          'sourceSymbol': sourceSymbol,
        }).value.substring(0, 24)}');

final class SourcePbsDiagnostic {
  const SourcePbsDiagnostic({
    required this.code,
    required this.message,
    required this.locator,
    required this.blocking,
    this.identityKey,
  });
  final String code;
  final String message;
  final SourceLocator locator;
  final bool blocking;
  final String? identityKey;
  Map<String, Object?> toJson() => Map.unmodifiable({
        'code': code,
        'message': message,
        'locator': locator.toJson(),
        'blocking': blocking,
        'identityKey': identityKey,
      });
}

final class SourcePbsField {
  SourcePbsField._({
    required this.key,
    required this.rawValue,
    required this.rawLine,
    required this.locator,
    required this.schemaFormat,
    required List<String> values,
  }) : values = List.unmodifiable(values);
  final String key;
  final String rawValue;
  final String rawLine;
  final SourceLocator locator;
  final String? schemaFormat;
  final List<String> values;
  bool get isKnown => schemaFormat != null;
  Map<String, Object?> toJson() => Map.unmodifiable({
        'key': key,
        'rawValue': rawValue,
        'rawLine': rawLine,
        'locator': locator.toJson(),
        'schemaFormat': schemaFormat,
        'values': values,
      });
}

final class SourcePbsTrainerPokemon {
  SourcePbsTrainerPokemon._(this.headerField, List<SourcePbsField> fields)
      : fields = List.unmodifiable(fields);
  final SourcePbsField headerField;
  final List<SourcePbsField> fields;
  SourcePbsField? field(String key) => _pbsLastField(fields, key);
  Map<String, Object?> toJson() => Map.unmodifiable({
        'headerField': headerField.toJson(),
        'fields': fields.map((field) => field.toJson()).toList(),
      });
}

final class SourcePbsEncounterSlot {
  const SourcePbsEncounterSlot._({
    required this.weight,
    required this.species,
    required this.minimumLevel,
    required this.maximumLevel,
    required this.locator,
    required this.rawLine,
  });
  final int weight;
  final String species;
  final int minimumLevel;
  final int maximumLevel;
  final SourceLocator locator;
  final String rawLine;
  Map<String, Object?> toJson() => Map.unmodifiable({
        'weight': weight,
        'species': species,
        'minimumLevel': minimumLevel,
        'maximumLevel': maximumLevel,
        'locator': locator.toJson(),
        'rawLine': rawLine,
      });
}

final class SourcePbsEncounterMethod {
  SourcePbsEncounterMethod._({
    required this.name,
    required this.stepChance,
    required this.locator,
    required this.rawLine,
    required List<SourcePbsEncounterSlot> slots,
  }) : slots = List.unmodifiable(slots);
  final String name;
  final int? stepChance;
  final SourceLocator locator;
  final String rawLine;
  final List<SourcePbsEncounterSlot> slots;
  Map<String, Object?> toJson() => Map.unmodifiable({
        'name': name,
        'stepChance': stepChance,
        'locator': locator.toJson(),
        'rawLine': rawLine,
        'slots': slots.map((slot) => slot.toJson()).toList(),
      });
}

final class SourcePbsEntry {
  SourcePbsEntry._({
    required this.identity,
    required this.family,
    required this.header,
    required this.rawHeader,
    required this.headerLocator,
    required List<SourcePbsField> fields,
    required List<SourcePbsTrainerPokemon> party,
    required List<SourcePbsEncounterMethod> methods,
    required this.isBlocked,
  })  : fields = List.unmodifiable(fields),
        party = List.unmodifiable(party),
        methods = List.unmodifiable(methods);
  final SourcePbsIdentity? identity;
  final SourcePbsFamily family;
  final String header;
  final String rawHeader;
  final SourceLocator headerLocator;
  final List<SourcePbsField> fields;
  final List<SourcePbsTrainerPokemon> party;
  final List<SourcePbsEncounterMethod> methods;
  final bool isBlocked;
  SourcePbsField? field(String key) => _pbsLastField(fields, key);
  List<SourcePbsField> fieldsNamed(String key) =>
      List.unmodifiable(fields.where((field) => field.key == key));
  Map<String, Object?> toJson() => Map.unmodifiable({
        'identity': identity?.toJson(),
        'family': family.name,
        'header': header,
        'rawHeader': rawHeader,
        'headerLocator': headerLocator.toJson(),
        'fields': fields.map((field) => field.toJson()).toList(),
        'party': party.map((member) => member.toJson()).toList(),
        'methods': methods.map((method) => method.toJson()).toList(),
        'isBlocked': isBlocked,
      });
}

final class SourcePbsDocument {
  SourcePbsDocument._({
    required this.file,
    required this.family,
    required this.suffix,
    required List<int> rawBytes,
    required List<String> rawLines,
    required List<SourcePbsEntry> entries,
  })  : rawBytes = List.unmodifiable(rawBytes),
        rawLines = List.unmodifiable(rawLines),
        entries = List.unmodifiable(entries);
  final SourceFileEntry file;
  final SourcePbsFamily family;
  final String suffix;
  final List<int> rawBytes;
  final List<String> rawLines;
  final List<SourcePbsEntry> entries;
  Map<String, Object?> toJson() => Map.unmodifiable({
        'file': file.toJson(),
        'family': family.name,
        'suffix': suffix,
        'rawBytes': base64.encode(rawBytes),
        'entries': entries.map((entry) => entry.toJson()).toList(),
      });
}

final class SourcePbsProject {
  SourcePbsProject._({
    required this.sourceSnapshotHash,
    required this.logicalProjectNamespace,
    required this.profile,
    required List<SourcePbsDocument> documents,
    required List<SourcePbsDiagnostic> diagnostics,
  })  : documents = List.unmodifiable(documents),
        entries =
            List.unmodifiable(documents.expand((document) => document.entries)),
        diagnostics = List.unmodifiable(diagnostics) {
    for (final entry in entries) {
      final identity = entry.identity;
      if (identity != null) {
        (_byIdentity[identity.key] ??= []).add(entry);
      }
    }
  }
  final Sha256Hash sourceSnapshotHash;
  final ConverterId logicalProjectNamespace;
  final SourcePbsProfile profile;
  final List<SourcePbsDocument> documents;
  final List<SourcePbsEntry> entries;
  final List<SourcePbsDiagnostic> diagnostics;
  final _byIdentity = <String, List<SourcePbsEntry>>{};
  SourcePbsEntry? lookup(SourcePbsIdentity identity) {
    final matches = _byIdentity[identity.key];
    return matches != null && matches.length == 1 && !matches.single.isBlocked
        ? matches.single
        : null;
  }

  late final Sha256Hash canonicalHash = _pbsHash(toJson());
  Map<String, Object?> toJson() => Map.unmodifiable({
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'logicalProjectNamespace': logicalProjectNamespace.value,
        'profile': profile.name,
        'documents': documents.map((document) => document.toJson()).toList(),
        'diagnostics':
            diagnostics.map((diagnostic) => diagnostic.toJson()).toList(),
      });
}

SourcePbsField? _pbsLastField(List<SourcePbsField> fields, String key) {
  for (final field in fields.reversed) {
    if (field.key == key) return field;
  }
  return null;
}

final class SourcePbsParser {
  const SourcePbsParser();
  Future<SourcePbsProject> read({
    required SourceSnapshot snapshot,
    required SourceFilePort files,
    Set<SourcePbsFamily> families = const {
      SourcePbsFamily.species,
      SourcePbsFamily.forms,
      SourcePbsFamily.items,
      SourcePbsFamily.moves,
      SourcePbsFamily.trainerTypes,
      SourcePbsFamily.trainers,
      SourcePbsFamily.encounters,
      SourcePbsFamily.types,
      SourcePbsFamily.abilities,
    },
    SourcePbsProfile profile = SourcePbsProfile.essentials21_1,
    SourcePbsLimits limits = const SourcePbsLimits(),
    ScanCancellation? cancellation,
  }) async {
    cancellation?.check();
    _require(snapshot.state == SourceScanState.complete, 'pbs.snapshot', r'$',
        'PBS parsing requires a complete hashed source inventory.');
    final budget = _PbsBudget(limits);
    final selected = <(SourceFileEntry, SourcePbsFamily, String)>[];
    for (final file in snapshot.entries) {
      cancellation?.check();
      final match = _pbsFileMatch(file.relativePath);
      if (file.kind == SourceNodeKind.file &&
          match != null &&
          families.contains(match.$1)) {
        budget.add('documents', 1, file.relativePath);
        budget.check('fileBytes', file.byteLength, file.relativePath);
        budget.add('bytes', file.byteLength, file.relativePath);
        selected.add((file, match.$1, match.$2));
      }
    }
    final pending = <_PbsDocumentBuilder>[];
    final diagnostics = <SourcePbsDiagnostic>[];
    for (final selection in selected) {
      cancellation?.check();
      final file = selection.$1;
      final bytes = await files.read(file.fileId);
      cancellation?.check();
      _require(
          bytes.length == file.byteLength &&
              bytes.every((value) => value >= 0 && value <= 255) &&
              Sha256Hash(sha256.convert(bytes).toString()) == file.sha256,
          'pbs.source_changed',
          file.relativePath,
          'PBS bytes differ from the sealed source inventory.');
      final document = _PbsDocumentBuilder(
          file,
          selection.$2,
          selection.$3,
          List<int>.unmodifiable(bytes),
          snapshot.logicalProjectNamespace,
          budget,
          diagnostics,
          cancellation);
      document.parse();
      pending.add(document);
    }
    final identities = <String, List<_PbsEntryBuilder>>{};
    for (final document in pending) {
      for (final entry in document.entries) {
        final identity = entry.identity;
        if (identity != null) (identities[identity.key] ??= []).add(entry);
      }
    }
    for (final matches in identities.values) {
      if (matches.length < 2) continue;
      for (final entry in matches) {
        entry.blocked = true;
        budget.add('diagnostics', 1, entry.headerLocator.file);
        diagnostics.add(SourcePbsDiagnostic(
            code: 'pbs.duplicate_identity',
            message: 'The same source identity is defined more than once.',
            locator: entry.headerLocator,
            blocking: true,
            identityKey: entry.identity!.key));
      }
    }
    cancellation?.check();
    return SourcePbsProject._(
        sourceSnapshotHash: snapshot.canonicalHash,
        logicalProjectNamespace: snapshot.logicalProjectNamespace,
        profile: profile,
        documents: pending.map((document) => document.freeze()).toList(),
        diagnostics: diagnostics);
  }
}

Sha256Hash _pbsHash(Object? input) {
  final output = _SourceDigestSink();
  final sink = sha256.startChunkedConversion(output);
  void write(String value) => sink.add(utf8.encode(value));
  void visit(Object? value) {
    if (value is Map<String, Object?>) {
      write('{');
      final keys = value.keys.toList()..sort();
      for (var index = 0; index < keys.length; index++) {
        if (index > 0) write(',');
        write(jsonEncode(keys[index]));
        write(':');
        visit(value[keys[index]]);
      }
      write('}');
    } else if (value is List) {
      write('[');
      for (var index = 0; index < value.length; index++) {
        if (index > 0) write(',');
        visit(value[index]);
      }
      write(']');
    } else {
      write(jsonEncode(value));
    }
  }

  visit(input);
  sink.close();
  return output.hash;
}

final class _PbsBudget {
  _PbsBudget(this.limits) {
    for (final value in maxima.values) {
      _require(value > 0 && value <= 9007199254740991, 'pbs.limits', r'$',
          'PBS limits must be positive safe integers.');
    }
  }
  final SourcePbsLimits limits;
  final counts = <String, int>{};
  Map<String, int> get maxima => {
        'documents': limits.maxDocuments,
        'fileBytes': limits.maxFileBytes,
        'bytes': limits.maxTotalBytes,
        'lines': limits.maxLines,
        'lineUnits': limits.maxLineCodeUnits,
        'entries': limits.maxEntries,
        'fields': limits.maxFields,
        'tokens': limits.maxTokens,
        'diagnostics': limits.maxDiagnostics,
      };
  void check(String name, int count, String path) => _require(
      count <= maxima[name]!, 'pbs.quota', path, 'PBS $name quota exceeded.');
  void add(String name, int count, String path) {
    counts[name] = (counts[name] ?? 0) + count;
    check(name, counts[name]!, path);
  }
}

const _pbsBaseFiles = <String, SourcePbsFamily?>{
  'pokemon_forms': SourcePbsFamily.forms,
  'pokemon_metrics': null,
  'trainer_types': SourcePbsFamily.trainerTypes,
  'encounters': SourcePbsFamily.encounters,
  'abilities': SourcePbsFamily.abilities,
  'trainers': SourcePbsFamily.trainers,
  'pokemon': SourcePbsFamily.species,
  'items': SourcePbsFamily.items,
  'moves': SourcePbsFamily.moves,
  'types': SourcePbsFamily.types,
};

(SourcePbsFamily, String)? _pbsFileMatch(String path) {
  if (!path.startsWith('PBS/') ||
      !path.endsWith('.txt') ||
      path.substring(4).contains('/')) {
    return null;
  }
  final filename = path.substring(4, path.length - 4);
  final bases = _pbsBaseFiles.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final base in bases) {
    if (filename == base) {
      final family = _pbsBaseFiles[base];
      return family == null ? null : (family, '');
    }
    if (filename.startsWith('${base}_')) {
      final family = _pbsBaseFiles[base];
      return family == null
          ? null
          : (family, filename.substring(base.length + 1));
    }
  }
  return null;
}

SourceLocator _pbsLocator(String file, int line) =>
    SourceLocator._(Map<String, Object?>.unmodifiable({
      'file': file,
      'mapId': null,
      'eventId': null,
      'pageIndex': null,
      'commandIndex': null,
      'tileId': null,
      'line': line,
    }));

final class _PbsEntryBuilder {
  _PbsEntryBuilder(this.identity, this.family, this.header, this.rawHeader,
      this.headerLocator);
  final SourcePbsIdentity? identity;
  final SourcePbsFamily family;
  final String header;
  final String rawHeader;
  final SourceLocator headerLocator;
  final fields = <SourcePbsField>[];
  final party = <(SourcePbsField, List<SourcePbsField>)>[];
  final methods =
      <(String, int?, SourceLocator, String, List<SourcePbsEncounterSlot>)>[];
  bool blocked = false;
  SourcePbsEntry freeze(bool documentBlocked) => SourcePbsEntry._(
      identity: identity,
      family: family,
      header: header,
      rawHeader: rawHeader,
      headerLocator: headerLocator,
      fields: fields,
      party: party
          .map((member) => SourcePbsTrainerPokemon._(member.$1, member.$2))
          .toList(),
      methods: methods
          .map((method) => SourcePbsEncounterMethod._(
              name: method.$1,
              stepChance: method.$2,
              locator: method.$3,
              rawLine: method.$4,
              slots: method.$5))
          .toList(),
      isBlocked: blocked || documentBlocked);
}

final class _PbsDocumentBuilder {
  _PbsDocumentBuilder(this.file, this.family, this.suffix, this.bytes,
      this.namespace, this.budget, this.diagnostics, this.cancellation);
  final SourceFileEntry file;
  final SourcePbsFamily family;
  final String suffix;
  final List<int> bytes;
  final ConverterId namespace;
  final _PbsBudget budget;
  final List<SourcePbsDiagnostic> diagnostics;
  final ScanCancellation? cancellation;
  final lines = <String>[];
  final entries = <_PbsEntryBuilder>[];
  bool blocked = false;
  _PbsEntryBuilder? current;
  void report(String code, String message, int line, {bool blocking = true}) {
    budget.add('diagnostics', 1, file.relativePath);
    diagnostics.add(SourcePbsDiagnostic(
        code: code,
        message: message,
        locator: _pbsLocator(file.relativePath, line),
        blocking: blocking,
        identityKey: current?.identity?.key));
    if (blocking) {
      if (current == null) {
        blocked = true;
      } else {
        current!.blocked = true;
      }
    }
  }

  void parse() {
    String text;
    try {
      text = utf8.decode(bytes, allowMalformed: false);
      if (bytes.length >= 3 &&
          bytes[0] == 239 &&
          bytes[1] == 187 &&
          bytes[2] == 191 &&
          !text.startsWith('\uFEFF')) {
        text = '\uFEFF$text';
      }
    } on FormatException {
      report('pbs.encoding', 'The PBS document is not valid UTF-8.', 1);
      return;
    }
    lines.addAll(text.split('\n'));
    budget.add('lines', lines.length, file.relativePath);
    for (var index = 0; index < lines.length; index++) {
      cancellation?.check();
      final rawLine = lines[index];
      final lineNumber = index + 1;
      budget.check('lineUnits', rawLine.length, file.relativePath);
      var line = rawLine;
      if (index == 0 && line.startsWith('\uFEFF')) line = line.substring(1);
      final hash = line.indexOf('#');
      if (hash >= 0) line = line.substring(0, hash);
      line = line.trim();
      if (line.isEmpty) continue;
      final section = RegExp(r'^\[\s*(.+)\s*\]$').firstMatch(line);
      if (section != null) {
        finishEntry();
        budget.add('entries', 1, file.relativePath);
        final header = section.group(1)!.trim();
        final identity = identityFor(header, lineNumber);
        current = _PbsEntryBuilder(identity, family, header, rawLine,
            _pbsLocator(file.relativePath, lineNumber));
        entries.add(current!);
        if (identity == null) {
          report('pbs.header', 'The source section identity is malformed.',
              lineNumber);
        }
        continue;
      }
      if (current == null) {
        report('pbs.before_section',
            'Data appears before the first source section.', lineNumber);
        continue;
      }
      if (family == SourcePbsFamily.encounters) {
        encounter(line, rawLine, lineNumber);
        continue;
      }
      final assignment = RegExp(r'^(\w+)\s*=\s*(.*)$').firstMatch(line);
      if (assignment == null) {
        report('pbs.syntax', 'Expected a source field assignment.', lineNumber);
        continue;
      }
      field(assignment.group(1)!, assignment.group(2)!, rawLine, lineNumber);
    }
    finishEntry();
  }

  void finishEntry() {
    if (current != null &&
        family == SourcePbsFamily.trainers &&
        current!.party.isEmpty) {
      report(
          'pbs.trainer_party',
          'A source trainer must define at least one Pokemon.',
          current!.headerLocator.line!);
    }
  }

  SourcePbsIdentity? identityFor(String header, int line) {
    final values = tokens(header);
    switch (family) {
      case SourcePbsFamily.forms:
        if (values.length != 2 ||
            !_pbsSymbol(values[0]) ||
            _pbsInt(values[1], positive: true) == null) {
          return null;
        }
        return SourcePbsIdentity(
            namespace: namespace,
            family: family,
            sourceSymbol: values[0],
            form: int.parse(values[1]));
      case SourcePbsFamily.trainers:
        if (values.length < 2 ||
            values.length > 3 ||
            !_pbsSymbol(values[0]) ||
            values[1].isEmpty ||
            (values.length == 3 &&
                values[2].isNotEmpty &&
                _pbsInt(values[2]) == null)) {
          return null;
        }
        return SourcePbsIdentity(
            namespace: namespace,
            family: family,
            trainerType: values[0],
            trainerName: values[1],
            version: values.length == 3 && values[2].isNotEmpty
                ? int.parse(values[2])
                : 0);
      case SourcePbsFamily.encounters:
        if (values.isEmpty ||
            values.length > 2 ||
            _pbsInt(values[0], positive: true) == null ||
            (values.length == 2 &&
                values[1].isNotEmpty &&
                _pbsInt(values[1]) == null)) {
          return null;
        }
        return SourcePbsIdentity(
            namespace: namespace,
            family: family,
            sourceMapId: int.parse(values[0]),
            version: values.length == 2 && values[1].isNotEmpty
                ? int.parse(values[1])
                : 0);
      default:
        if (values.length != 1 || !_pbsSymbol(values[0])) return null;
        return SourcePbsIdentity(
            namespace: namespace, family: family, sourceSymbol: values[0]);
    }
  }

  List<String> tokens(String value) {
    final fragments = value.split(',').cast<String?>().toList();
    while (fragments.isNotEmpty && fragments.last == '') {
      fragments.removeLast();
    }
    budget.add('tokens', fragments.length, file.relativePath);
    for (var index = 0; index < fragments.length; index++) {
      final original = fragments[index];
      if (original == null || original.isEmpty) continue;
      var count = '"'.allMatches(original).length;
      if (count > 0) {
        for (var next = index; next < fragments.length - 1; next++) {
          final joined = fragments[index]!;
          count = '"'.allMatches(joined).length;
          if (count == 2 &&
              original.startsWith(r'\"') &&
              joined.endsWith(r'\"')) {
            fragments[index] = joined.substring(2, joined.length - 2);
            break;
          }
          if (count.isEven) break;
          fragments[index] = '$joined,${fragments[next + 1]}';
          fragments[next + 1] = null;
        }
        if (count != 2 &&
            '"'.allMatches(original).length == 2 &&
            original.startsWith(r'\"') &&
            original.endsWith(r'\"')) {
          fragments[index] =
              fragments[index]!.substring(2, fragments[index]!.length - 2);
        }
      }
      fragments[index] = fragments[index]!.trim();
    }
    return fragments.whereType<String>().toList();
  }

  void field(String key, String value, String rawLine, int line) {
    budget.add('fields', 1, file.relativePath);
    final format = _pbsSchema(family)[key];
    final values =
        format == null || format == 'q' ? <String>[value] : tokens(value);
    if (format == null || format == 'q') {
      budget.add('tokens', 1, file.relativePath);
    }
    final sourceField = SourcePbsField._(
        key: key,
        rawValue: value,
        rawLine: rawLine,
        locator: _pbsLocator(file.relativePath, line),
        schemaFormat: format,
        values: values);
    current!.fields.add(sourceField);
    if (format == null) {
      report('pbs.unknown_field',
          'The source field has no Essentials 21.1 schema.', line,
          blocking: false);
    } else if (!_pbsValidValues(values, format)) {
      report('pbs.field_value',
          'The field does not match its source schema $format.', line);
    }
    if (family == SourcePbsFamily.trainers) {
      if (key == 'Pokemon') {
        current!.party.add((sourceField, <SourcePbsField>[]));
      } else if (_pbsTrainerSubSchema.containsKey(key)) {
        if (current!.party.isEmpty) {
          report('pbs.trainer_scope',
              'A Pokemon property appears before its Pokemon heading.', line);
        } else {
          current!.party.last.$2.add(sourceField);
        }
      } else if (format == null && current!.party.isNotEmpty) {
        current!.party.last.$2.add(sourceField);
      }
    }
  }

  void encounter(String line, String rawLine, int lineNumber) {
    budget.add('fields', 1, file.relativePath);
    final values = tokens(line);
    if (RegExp(r'^\d+,').hasMatch(line)) {
      if (current!.methods.isEmpty) {
        report('pbs.encounter_scope',
            'A slot appears before an encounter method.', lineNumber);
        return;
      }
      if (values.length < 3 ||
          values.length > 4 ||
          !_pbsValidValues(values, 'vevV') ||
          !_pbsSymbol(values[1])) {
        report(
            'pbs.field_value', 'The encounter slot is malformed.', lineNumber);
        return;
      }
      final minimum = int.parse(values[2]);
      final maximum = values.length == 4 && values[3].isNotEmpty
          ? int.parse(values[3])
          : minimum;
      if (maximum < minimum) {
        report('pbs.encounter_level',
            'The minimum encounter level exceeds the maximum.', lineNumber);
        return;
      }
      current!.methods.last.$5.add(SourcePbsEncounterSlot._(
          weight: int.parse(values[0]),
          species: values[1],
          minimumLevel: minimum,
          maximumLevel: maximum,
          locator: _pbsLocator(file.relativePath, lineNumber),
          rawLine: rawLine));
      return;
    }
    if (values.isEmpty ||
        values.length > 2 ||
        !_pbsEncounterMethods.contains(values[0]) ||
        (values.length == 2 &&
            values[1].isNotEmpty &&
            _pbsInt(values[1]) == null)) {
      report('pbs.encounter_method',
          'The encounter method is unsupported or malformed.', lineNumber);
      return;
    }
    current!.methods.add((
      values[0],
      values.length == 2 && values[1].isNotEmpty ? int.parse(values[1]) : null,
      _pbsLocator(file.relativePath, lineNumber),
      rawLine,
      <SourcePbsEncounterSlot>[]
    ));
  }

  SourcePbsDocument freeze() => SourcePbsDocument._(
      file: file,
      family: family,
      suffix: suffix,
      rawBytes: bytes,
      rawLines: lines,
      entries: entries.map((entry) => entry.freeze(blocked)).toList());
}

bool _pbsSymbol(String value) =>
    RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(value);
int? _pbsInt(String value, {bool positive = false, bool signed = false}) {
  if (!(signed ? RegExp(r'^-?\d+$') : RegExp(r'^\d+$')).hasMatch(value)) {
    return null;
  }
  final number = int.tryParse(value);
  return number != null &&
          number.abs() <= 9007199254740991 &&
          (!positive || number > 0)
      ? number
      : null;
}

bool _pbsValidValues(List<String> values, String format) {
  final repeating = format.startsWith('*');
  final schema = repeating ? format.substring(1) : format;
  final count = repeating
      ? math.max(
          schema.length,
          ((values.length + schema.length - 1) ~/ schema.length) *
              schema.length)
      : schema.length;
  for (var index = 0; index < count; index++) {
    final type = schema[index % schema.length];
    final value = index < values.length ? values[index] : null;
    if (type == type.toUpperCase() && (value == null || value.isEmpty)) {
      continue;
    }
    if (type == 's' || type == 'q') continue;
    if (value == null) return false;
    switch (type.toLowerCase()) {
      case 'i':
        if (_pbsInt(value, signed: true) == null) return false;
      case 'u':
        if (_pbsInt(value) == null) return false;
      case 'v':
        if (_pbsInt(value, positive: true) == null) return false;
      case 'm':
      case 'n':
        if (!_pbsSymbol(value)) return false;
      case 'e':
        if (value.isEmpty) return false;
      case 'f':
        if (!RegExp(r'^\d*\.?\d*$').hasMatch(value)) return false;
      case 'b':
        if (!RegExp(r'^(1|TRUE|YES|Y|0|FALSE|NO|N)$', caseSensitive: false)
            .hasMatch(value)) {
          return false;
        }
    }
  }
  return true;
}

const _pbsTrainerSubSchema = <String, String>{
  'Form': 'u',
  'Name': 's',
  'Moves': '*e',
  'Ability': 'e',
  'AbilityIndex': 'u',
  'Item': 'e',
  'Gender': 'e',
  'Nature': 'e',
  'IV': 'uUUUUU',
  'EV': 'uUUUUU',
  'Happiness': 'u',
  'Shiny': 'b',
  'SuperShiny': 'b',
  'Shadow': 'b',
  'Ball': 'e',
};

Map<String, String> _pbsSchema(SourcePbsFamily family) => switch (family) {
      SourcePbsFamily.species || SourcePbsFamily.forms => {
          if (family == SourcePbsFamily.species) 'Name': 's',
          'FormName': 'q',
          if (family == SourcePbsFamily.forms) ...{
            'PokedexForm': 'u',
            'MegaStone': 'e',
            'MegaMove': 'e',
            'UnmegaForm': 'u',
            'MegaMessage': 'u',
          },
          'Types': '*e',
          'BaseStats': 'vvvvvv',
          if (family == SourcePbsFamily.species) ...{
            'GenderRatio': 'e',
            'GrowthRate': 'e'
          },
          'BaseExp': 'v',
          'EVs': '*ev',
          'CatchRate': 'u',
          'Happiness': 'u',
          'Abilities': '*e',
          'HiddenAbilities': '*e',
          'Moves': '*ue',
          'TutorMoves': '*e',
          'EggMoves': '*e',
          'EggGroups': '*e',
          'HatchSteps': 'v',
          if (family == SourcePbsFamily.species) 'Incense': 'e',
          'Offspring': family == SourcePbsFamily.forms ? '*e' : '*s',
          'Height': 'f',
          'Weight': 'f',
          'Color': 'e',
          'Shape': 'e',
          'Habitat': 'e',
          'Category': 's',
          'Pokedex': 'q',
          'Generation': 'i',
          'Flags': '*s',
          'WildItemCommon': '*e',
          'WildItemUncommon': '*e',
          'WildItemRare': '*e',
          'Evolutions': family == SourcePbsFamily.forms ? '*ees' : '*ses',
        },
      SourcePbsFamily.items => {
          'Name': 's',
          'NamePlural': 's',
          'PortionName': 's',
          'PortionNamePlural': 's',
          'Pocket': 'v',
          'Price': 'u',
          'SellPrice': 'u',
          'BPPrice': 'u',
          'FieldUse': 'e',
          'BattleUse': 'e',
          'Flags': '*s',
          'Consumable': 'b',
          'ShowQuantity': 'b',
          'Move': 'e',
          'Description': 'q',
        },
      SourcePbsFamily.moves => {
          'Name': 's',
          'Type': 'e',
          'Category': 'e',
          'Power': 'u',
          'Accuracy': 'u',
          'TotalPP': 'u',
          'Target': 'e',
          'Priority': 'i',
          'FunctionCode': 's',
          'Flags': '*s',
          'EffectChance': 'u',
          'Description': 'q',
        },
      SourcePbsFamily.trainerTypes => {
          'Name': 's',
          'Gender': 'e',
          'BaseMoney': 'u',
          'SkillLevel': 'u',
          'Flags': '*s',
          'IntroBGM': 's',
          'BattleBGM': 's',
          'VictoryBGM': 's',
        },
      SourcePbsFamily.trainers => {
          'Items': '*e',
          'LoseText': 'q',
          'Pokemon': 'ev',
          ..._pbsTrainerSubSchema,
        },
      SourcePbsFamily.types => {
          'Name': 's',
          'IconPosition': 'u',
          'IsSpecialType': 'b',
          'IsPseudoType': 'b',
          'Weaknesses': '*m',
          'Resistances': '*m',
          'Immunities': '*m',
          'Flags': '*s',
        },
      SourcePbsFamily.abilities => {
          'Name': 's',
          'Description': 'q',
          'Flags': '*s'
        },
      SourcePbsFamily.encounters => const {},
    };

const _pbsEncounterMethods = {
  'Land',
  'LandDay',
  'LandNight',
  'LandMorning',
  'LandAfternoon',
  'LandEvening',
  'PokeRadar',
  'Cave',
  'CaveDay',
  'CaveNight',
  'CaveMorning',
  'CaveAfternoon',
  'CaveEvening',
  'Water',
  'WaterDay',
  'WaterNight',
  'WaterMorning',
  'WaterAfternoon',
  'WaterEvening',
  'OldRod',
  'GoodRod',
  'SuperRod',
  'RockSmash',
  'HeadbuttLow',
  'HeadbuttHigh',
  'BugContest',
};
