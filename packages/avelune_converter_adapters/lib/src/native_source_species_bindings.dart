import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';

import 'native_psdk_catalog.dart';
import 'native_psdk_trainer_bundle.dart';

final class NativeSourceSpeciesBindings {
  const NativeSourceSpeciesBindings();

  Future<NativeSourceSpeciesBindingBatch> bindAvailable({
    required SourceSnapshot snapshot,
    required SourcePbsProject source,
    required SourceFilePort files,
    required NativePsdkCatalog nativeCatalog,
    required Iterable<String> requestedSourceSymbols,
    ScanCancellation? cancellation,
  }) async {
    cancellation?.check();
    final symbols = <String>{};
    var inputRows = 0;
    for (final symbol in requestedSourceSymbols) {
      cancellation?.check();
      if (++inputRows > 1000000 || symbol.isEmpty || symbol.length > 192) {
        _invalid('requested_symbols', r'$.requestedSourceSymbols',
            'Requested symbols must be nonempty, at most 192 code units, and bounded to the source ceiling of 1000000 event requests.');
      }
      symbols.add(symbol);
    }
    final bindings = <String, NativeSourceSpeciesBindingResult>{};
    final refusals = <String, ContractError>{};
    late final String operationCatalogHash;
    void verifyOperationCatalog() {
      cancellation?.check();
      if (_catalogHash(nativeCatalog) != operationCatalogHash) {
        _invalid('catalog_integrity', r'$.nativeCatalog',
            'The native catalog changed during batched identity resolution.');
      }
    }
    Future<void> resolve(List<String> requested) async {
      cancellation?.check();
      try {
        final result = await bind(snapshot: snapshot, source: source,
            files: files, nativeCatalog: nativeCatalog,
            requestedSourceSymbols: requested, cancellation: cancellation);
        if (result.evidence['nativeCatalogHash'] != operationCatalogHash) {
          _invalid('catalog_integrity', r'$.nativeCatalog',
              'A species binding differs from the batched native catalog.');
        }
        for (final row in result.rows) {
          final symbol = row['sourceSymbol']! as String;
          bindings[symbol] = NativeSourceSpeciesBindingResult._([row], {
            ...result.evidence,
            'requestedSourceSymbols': [symbol],
            'mappingCount': 1,
            'ignoredSourceFieldDiagnostics': row['ignoredSourceFieldDiagnostics'],
          });
        }
      } on ContractError catch (error) {
        cancellation?.check();
        final localIdentityFailure = const {
          'native_species.compiled_identity',
          'native_species.pbs_identity',
          'native_species.source_name',
          'native_species.source_form_name',
          'native_species.native_form_identity',
        }.contains(error.code) ||
            error.code == 'native_species.native_base_identity' &&
                error.path.startsWith('PBS/');
        if (!localIdentityFailure) rethrow;
        if (requested.length == 1) {
          refusals[requested.single] = error;
        } else {
          final middle = requested.length ~/ 2;
          await resolve(requested.sublist(0, middle));
          await resolve(requested.sublist(middle));
        }
      }
      verifyOperationCatalog();
    }
    if (symbols.isNotEmpty) {
      try {
        operationCatalogHash = _catalogHash(nativeCatalog);
        final ordered = symbols.toList()..sort();
        for (var offset = 0; offset < ordered.length; offset += 2048) {
          final end = offset + 2048 < ordered.length
              ? offset + 2048 : ordered.length;
          await resolve(ordered.sublist(offset, end));
        }
        verifyOperationCatalog();
      } on ContractError catch (error) {
        cancellation?.check();
        if (error.code == 'source.cancelled') rethrow;
        bindings.clear();
        refusals
          ..clear()
          ..addEntries(symbols.map((symbol) => MapEntry(symbol, error)));
      }
    }
    return NativeSourceSpeciesBindingBatch._(bindings, refusals);
  }

  Future<NativeSourceSpeciesBindingResult> bindNativeBases({
    required SourceSnapshot snapshot,
    required SourcePbsProject source,
    required SourceFilePort files,
    required NativePsdkCatalog nativeCatalog,
    required Iterable<String> requestedNativeBaseIds,
    ScanCancellation? cancellation,
  }) async {
    cancellation?.check();
    final requested = <String>{};
    final symbols = <String>[];
    for (final id in requestedNativeBaseIds) {
      cancellation?.check();
      final native = nativeCatalog.speciesById[id];
      if (requested.length >= 2048 ||
          !requested.add(id) ||
          native == null ||
          native.forms.formId != '0' ||
          native.names['en'] == null) {
        _invalid('native_base_source_identity', id,
            'Media requires unique bounded canonical native bases with English names.');
      }
      _canonicalNative(id, native);
      final candidates = source.entries.where((entry) {
        if (entry.family != SourcePbsFamily.species ||
            entry.identity?.form != 0) {
          return false;
        }
        final names = entry.fieldsNamed('Name');
        return names.length == 1 &&
            names.single.values.length == 1 &&
            _orthography(names.single.values.single) ==
                _orthography(native.names['en']!);
      }).toList();
      if (candidates.length != 1 ||
          candidates.single.identity?.sourceSymbol == null) {
        _invalid('native_base_source_identity', id,
            'Native media requires exactly one authored source base with its English name.');
      }
      symbols.add(candidates.single.identity!.sourceSymbol!);
    }
    final result = await bind(
        snapshot: snapshot,
        source: source,
        files: files,
        nativeCatalog: nativeCatalog,
        requestedSourceSymbols: symbols,
        cancellation: cancellation);
    final inverse = <String>{};
    if (result.rows.length != requested.length ||
        result.rows.any((row) =>
            row['sourceForm'] != 0 ||
            row['nativeForm'] != 0 ||
            !requested.contains(row['nativeBaseId']) ||
            !inverse.add(row['nativeBaseId'] as String))) {
      _invalid('native_base_source_identity', r'$',
          'Media source identities require a unique exact source base for every native base.');
    }
    return result;
  }

  Future<NativeSourceSpeciesBindingResult> bind({
    required SourceSnapshot snapshot,
    required SourcePbsProject source,
    required SourceFilePort files,
    required NativePsdkCatalog nativeCatalog,
    required Iterable<String> requestedSourceSymbols,
    ScanCancellation? cancellation,
  }) async {
    cancellation?.check();
    if (source.sourceSnapshotHash != snapshot.canonicalHash ||
        source.logicalProjectNamespace != snapshot.logicalProjectNamespace ||
        source.profile != SourcePbsProfile.essentials21_1) {
      _invalid('source_binding', r'$',
          'Species identities require the exact Essentials 21.1 PBS snapshot and namespace.');
    }
    final requested = <String>{};
    for (final symbol in requestedSourceSymbols) {
      cancellation?.check();
      if (requested.length >= 2048 ||
          symbol.isEmpty ||
          symbol.length > 192 ||
          !requested.add(symbol)) {
        _invalid('requested_symbols', r'$.requestedSourceSymbols',
            'Requested symbols must be unique, nonempty and bounded to 2048 symbols of 192 code units.');
      }
    }
    final catalogHash = _catalogHash(nativeCatalog);
    final witnesses = snapshot.entries
        .where((entry) => entry.relativePath == 'Data/species.dat')
        .toList();
    if (witnesses.length != 1 ||
        witnesses.single.kind != SourceNodeKind.file ||
        witnesses.single.sha256 == null ||
        witnesses.single.byteLength < 1 ||
        witnesses.single.byteLength > 8388608) {
      _invalid('compiled_species', 'Data/species.dat',
          'A single bounded compiled GameData::Species witness is required.');
    }
    final witness = witnesses.single;
    final List<int> bytes;
    try {
      bytes = List<int>.unmodifiable(await files.read(witness.fileId));
    } catch (_) {
      cancellation?.check();
      _invalid('compiled_species_read', witness.relativePath,
          'The exact compiled species witness could not be read.');
    }
    cancellation?.check();
    if (_catalogHash(nativeCatalog) != catalogHash) {
      _invalid('catalog_integrity', r'$.nativeCatalog',
          'The native catalog changed while reading source species.');
    }
    if (bytes.length != witness.byteLength ||
        bytes.any((byte) => byte < 0 || byte > 255) ||
        crypto.sha256.convert(bytes).toString() != witness.sha256!.value) {
      _invalid('compiled_species_changed', witness.relativePath,
          'Compiled species bytes differ from the exact source snapshot.');
    }
    final compiled = _readCompiled(bytes, cancellation);
    final nativeBases = <String, List<PokemonSpeciesFile>>{};
    for (final entry in nativeCatalog.speciesById.entries) {
      cancellation?.check();
      final species = entry.value;
      if (species.forms.formId != '0') continue;
      _canonicalNative(entry.key, species);
      final name = species.names['en'];
      if (name == null || name.isEmpty) {
        _invalid('native_base_identity', entry.key,
            'Native canonical base species require an English name.');
      }
      (nativeBases[_orthography(name)] ??= []).add(species);
    }
    final rows = <Map<String, Object?>>[];
    final ignoredDiagnostics = <String, Map<String, Object?>>{};
    final requestedSorted = requested.toList()..sort();
    for (final symbol in requestedSorted) {
      cancellation?.check();
      final record = compiled[symbol];
      if (record == null) {
        _invalid('compiled_identity', 'Data/species.dat:$symbol',
            'Every requested source symbol requires a compiled species identity.');
      }
      final sourceIdentity = _sourceEntry(source, record);
      final pbs = sourceIdentity.entry;
      _matchSourceName(record, pbs);
      final base = compiled[record.base];
      if (base == null || base.base != record.base || base.form != 0) {
        _invalid('compiled_identity', record.locator,
            'Every compiled form requires its canonical compiled form-zero base.');
      }
      final baseIdentity =
          record.form == 0 ? sourceIdentity : _sourceEntry(source, base);
      final basePbs = baseIdentity.entry;
      final rowDiagnostics = <String, Map<String, Object?>>{
        for (final diagnostic in [
          ...sourceIdentity.ignoredDiagnostics,
          ...baseIdentity.ignoredDiagnostics,
        ])
          canonicalJsonOf(diagnostic): diagnostic,
      };
      ignoredDiagnostics.addAll(rowDiagnostics);
      _matchSourceName(base, basePbs);
      final bases = nativeBases[_orthography(base.name)] ?? const [];
      if (bases.length != 1) {
        _invalid('native_base_identity', pbs.headerLocator.file,
            'Source ${record.base} requires a unique native form-zero English name: ${base.name}.');
      }
      final nativeBase = bases.single;
      final nativeBaseName = nativeBase.names['en']!;
      PokemonSpeciesFile native = nativeBase;
      String? nativeFormName;
      if (record.form != 0) {
        final field = pbs.field('FormName');
        final label = record.formName;
        if (label == null ||
            label.isEmpty ||
            field == null ||
            pbs.fieldsNamed('FormName').length != 1 ||
            field.values.length != 1 ||
            field.values.single != label) {
          _invalid('source_form_name', record.locator,
              'Nonzero source forms require the exact compiled and authored PBS FormName.');
        }
        final names = nativeCatalog.evidence['nativeFormNamesBySpeciesId'];
        final matches = <PokemonSpeciesFile>[];
        for (final entry in nativeCatalog.speciesById.entries) {
          final candidate = entry.value;
          if (candidate.forms.baseFormId != nativeBase.id ||
              candidate.forms.formId == '0') {
            continue;
          }
          _canonicalNative(entry.key, candidate);
          final labels = names is Map ? names[entry.key] : null;
          final english = labels is Map ? labels['en'] : null;
          if (english is! String || english.isEmpty) continue;
          if (_orthography(english) == _orthography(label) ||
              _orthography(english) == _orthography('$nativeBaseName $label')) {
            matches.add(candidate);
          }
        }
        if (matches.length != 1) {
          _invalid('native_form_identity', record.locator,
              'Source $symbol requires one native form of ${nativeBase.id} attested by English label $label.');
        }
        native = matches.single;
        nativeFormName = ((names as Map)[native.id] as Map)['en'] as String;
      }
      _canonicalNative(native.id, native);
      final nativeName = native.names['en'];
      if (nativeName == null || nativeName.isEmpty) {
        _invalid('native_form_identity', native.id,
            'The resolved native species requires an English name.');
      }
      rows.add({
        'sourceSymbol': record.id,
        'sourceBaseSymbol': record.base,
        'sourceForm': record.form,
        'nativeBaseId': nativeBase.id,
        'nativeForm': int.parse(native.forms.formId),
        'nativeSpeciesId': native.id,
        'sourceName': record.name,
        'nativeName': nativeName,
        'sourceFormName': record.formName,
        'nativeFormName': nativeFormName,
        'sourceEntryBlocked': pbs.isBlocked,
        'sourceBaseEntryBlocked': basePbs.isBlocked,
        'ignoredSourceFieldDiagnostics': rowDiagnostics.values.toList(),
        'sourceLocator': pbs.headerLocator.toJson(),
        'sourceBaseLocator': basePbs.headerLocator.toJson(),
        if (pbs.field('Name') case final field?)
          'sourceNameLocator': field.locator.toJson(),
        if (pbs.field('FormName') case final field?)
          'sourceFormNameLocator': field.locator.toJson(),
        'compiledWitness': {
          'relativePath': witness.relativePath,
          'sha256': witness.sha256!.value,
          'byteLength': witness.byteLength,
          'fileId': witness.fileId.value,
          'byteOffset': record.offset,
          'graphPath': record.graphPath,
          'className': 'GameData::Species',
          'key': record.id,
          'baseSymbol': record.base,
          'form': record.form,
        },
      });
    }
    cancellation?.check();
    if (_catalogHash(nativeCatalog) != catalogHash) {
      _invalid('catalog_integrity', r'$.nativeCatalog',
          'The native catalog changed during identity resolution.');
    }
    return NativeSourceSpeciesBindingResult._(rows, {
      'kind': 'nativeSourceSpeciesBindings',
      'version': 1,
      'sourceSnapshotHash': snapshot.canonicalHash.value,
      'sourcePbsHash': source.canonicalHash.value,
      'logicalProjectNamespace': snapshot.logicalProjectNamespace.value,
      'nativeCatalogHash': catalogHash,
      'requestedSourceSymbols': requestedSorted,
      'mappingCount': rows.length,
      'identityPolicy': {
        'base': 'uniqueExactEnglishNameAmongCanonicalNativeFormZero',
        'apostrophe': 'U+2019-to-U+0027',
        'otherText': 'case-sex-signs-spaces-punctuation-preserved',
        'formZero': 'nativeFormZeroOnly',
        'nonzeroForm': 'uniqueAttestedEnglishLabelOrBaseNameSingleSpaceLabel',
        'sourceNumericFormEqualsNativeNumericForm': false,
        'sourceSymbolSpellingUsedForNativeIdentity': false,
        'blockedSourceEntry':
            'identityOnlyWhenAllBlockingDiagnosticsAreLocatedUnusedFieldValues',
      },
      'compiledSpeciesWitness': {
        'relativePath': witness.relativePath,
        'sha256': witness.sha256!.value,
        'byteLength': witness.byteLength,
      },
      'ignoredSourceFieldDiagnostics': ignoredDiagnostics.values.toList(),
      'sourceFieldDataUsed': false,
      'sourceScriptsExecuted': 0,
      'runtimeBattleBuilderQualified': false,
      'activationQualified': false,
    });
  }
}

final class NativeSourceSpeciesBindingBatch {
  NativeSourceSpeciesBindingBatch._(
      Map<String, NativeSourceSpeciesBindingResult> bindings,
      Map<String, ContractError> refusals)
      : bindings = Map.unmodifiable(bindings),
        refusals = Map.unmodifiable(refusals);
  final Map<String, NativeSourceSpeciesBindingResult> bindings;
  final Map<String, ContractError> refusals;
}

final class NativeSourceSpeciesBindingResult {
  NativeSourceSpeciesBindingResult._(
      List<Map<String, Object?>> rows, Map<String, Object?> evidence)
      : rows = List.unmodifiable(rows.map(_freezeMap)),
        evidence = _freezeMap(evidence) {
    mappings = Map.unmodifiable({
      for (final row in this.rows) row['sourceSymbol']! as String: row,
    });
  }

  final List<Map<String, Object?>> rows;
  late final Map<String, Map<String, Object?>> mappings;
  final Map<String, Object?> evidence;
}

final class _CompiledSpecies {
  const _CompiledSpecies(this.id, this.base, this.form, this.name,
      this.formName, this.offset, this.graphPath);

  final String id;
  final String base;
  final int form;
  final String name;
  final String? formName;
  final int offset;
  final String graphPath;
  String get locator => 'Data/species.dat:$offset:$graphPath';
}

Map<String, _CompiledSpecies> _readCompiled(
    List<int> bytes, ScanCancellation? cancellation) {
  try {
    final document = const MarshalDecoder().decode(bytes,
        sourcePath: 'Data/species.dat',
        limits: const MarshalDecodeLimits(
            maxInputBytes: 8388608, maxTotalLocationCodeUnits: 33554432));
    final root = document.node(document.rootId);
    if (root.kind != MarshalKind.hash || root.defaultValue != null) {
      _invalid('compiled_species', 'Data/species.dat',
          'Compiled species must be an inert typed GameData::Species hash.');
    }
    final records = <String, _CompiledSpecies>{};
    final identities = <String>{};
    for (final pair in root.pairs) {
      cancellation?.check();
      final key = document.node(pair.key);
      final value = document.node(pair.value);
      final locator = 'Data/species.dat:${value.location.byteOffset}';
      if (key.kind != MarshalKind.symbol ||
          value.kind != MarshalKind.object ||
          value.className != 'GameData::Species') {
        _invalid('compiled_species', locator,
            'Compiled species hash keys must be symbols and values GameData::Species objects.');
      }
      final fields = <String, MarshalNode>{};
      for (final field in value.instanceVariables) {
        final name = _nodeText(document.node(field.key), MarshalKind.symbol);
        if (name == null || fields.containsKey(name)) {
          _invalid('compiled_species', locator,
              'Compiled species fields require unique symbol identities.');
        }
        fields[name] = document.node(field.value);
      }
      final id = _nodeText(fields['@id'], MarshalKind.symbol);
      final base = _nodeText(fields['@species'], MarshalKind.symbol);
      final name = _nodeText(fields['@real_name'], MarshalKind.string);
      final form = fields['@form'];
      final formNameNode = fields['@real_form_name'];
      final formName = _nodeText(formNameNode, MarshalKind.string);
      if (id == null ||
          id.isEmpty ||
          base == null ||
          base.isEmpty ||
          name == null ||
          name.isEmpty ||
          _nodeText(key, MarshalKind.symbol) != id ||
          form?.kind != MarshalKind.integer ||
          form!.integerValue == null ||
          form.integerValue! < BigInt.zero ||
          form.integerValue! > BigInt.from(2048) ||
          (formNameNode != null &&
              formNameNode.kind != MarshalKind.nil &&
              formName == null)) {
        _invalid('compiled_species', locator,
            'Compiled species require matching key/id, nonempty species and name, a bounded nonnegative integer form and optional string form name.');
      }
      final number = form.integerValue!.toInt();
      if ((number == 0 && id != base) ||
          records.containsKey(id) ||
          !identities.add(canonicalJsonOf([base, number]))) {
        _invalid('compiled_species', locator,
            'Compiled species symbols and base/form identities must be unique and canonical.');
      }
      records[id] = _CompiledSpecies(id, base, number, name, formName,
          value.location.byteOffset, value.location.graphPath);
    }
    return records;
  } on BinaryDecodeError catch (error) {
    _invalid(
        'compiled_species',
        '${error.location.sourcePath}:${error.location.byteOffset}',
        'Compiled species decoding failed: ${error.code}.');
  }
}

final class _SourceSpeciesIdentity {
  const _SourceSpeciesIdentity(this.entry, this.ignoredDiagnostics);
  final SourcePbsEntry entry;
  final List<Map<String, Object?>> ignoredDiagnostics;
}

_SourceSpeciesIdentity _sourceEntry(
    SourcePbsProject source, _CompiledSpecies record) {
  final identity = SourcePbsIdentity(
      namespace: source.logicalProjectNamespace,
      family: SourcePbsFamily.species,
      sourceSymbol: record.base,
      form: record.form);
  final matches = source.entries
      .where((entry) =>
          (entry.family == SourcePbsFamily.species ||
              entry.family == SourcePbsFamily.forms) &&
          entry.identity?.key == identity.key)
      .toList();
  if (matches.length != 1) {
    _invalid('pbs_identity', record.locator,
        'Compiled ${record.id} requires a unique PBS species identity ${record.base}/${record.form}.');
  }
  final entry = matches.single;
  final blocking = source.diagnostics
      .where((diagnostic) =>
          diagnostic.blocking &&
          (diagnostic.identityKey == identity.key ||
              (diagnostic.identityKey == null &&
                  diagnostic.locator.file == entry.headerLocator.file)))
      .toList();
  if (entry.isBlocked && blocking.isEmpty) {
    _invalid('pbs_identity', record.locator,
        'A blocked source identity requires every blocking reason to be witnessed.');
  }
  final ignored = <Map<String, Object?>>[];
  for (final diagnostic in blocking) {
    final fields = entry.fields
        .where((field) =>
            field.locator.file == diagnostic.locator.file &&
            field.locator.line == diagnostic.locator.line)
        .toList();
    if (diagnostic.code != 'pbs.field_value' ||
        diagnostic.identityKey != identity.key ||
        fields.length != 1 ||
        const {'Name', 'FormName'}.contains(fields.single.key)) {
      _invalid(
          'pbs_identity',
          '${diagnostic.locator.file}:${diagnostic.locator.line}',
          'Species identity rejects blocking source identity, syntax, document or name diagnostics.');
    }
    ignored.add({...diagnostic.toJson(), 'field': fields.single.key});
  }
  return _SourceSpeciesIdentity(entry, ignored);
}

void _matchSourceName(_CompiledSpecies record, SourcePbsEntry entry) {
  final names = entry.fieldsNamed('Name');
  if (names.length > 1 ||
      (names.isNotEmpty &&
          (names.single.values.length != 1 ||
              names.single.values.single != record.name))) {
    _invalid('source_name', entry.headerLocator.file,
        'Authored PBS Name must exactly equal the compiled real_name.');
  }
}

void _canonicalNative(String key, PokemonSpeciesFile species) {
  final form = int.tryParse(species.forms.formId);
  final base = species.forms.baseFormId;
  if (form == null ||
      form < 0 ||
      form > 2048 ||
      '$form' != species.forms.formId ||
      base.isEmpty ||
      key != species.id ||
      species.id != nativePsdkFormSpeciesId(base, form) ||
      species.forms.isBaseForm != (form == 0)) {
    _invalid('native_base_identity', key,
        'Native identities require a canonical base ID and bounded native form ID.');
  }
}

String _catalogHash(NativePsdkCatalog catalog) {
  try {
    return canonicalHashOf(catalog.toJson(),
            limits: nativePsdkCatalogShardJsonLimits)
        .value;
  } on ContractError catch (error) {
    _invalid('catalog_integrity', error.path,
        'Native catalog integrity failed: ${error.code}.');
  }
}

String? _nodeText(MarshalNode? node, MarshalKind kind) =>
    node?.kind == kind ? node!.text().text : null;

String _orthography(String value) => value.replaceAll('\u2019', "'");

Map<String, Object?> _freezeMap(Map<String, Object?> value) =>
    Map.unmodifiable(value.map((key, entry) => MapEntry(key, _freeze(entry))));

Object? _freeze(Object? value) {
  if (value is Map<String, Object?>) return _freezeMap(value);
  if (value is List) return List<Object?>.unmodifiable(value.map(_freeze));
  return value;
}

Never _invalid(String code, String locator, String message) =>
    throw ContractError('native_species.$code', locator, message);
