import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';

import '../support/authoring_fingerprint.dart';
import 'catalog_history_compatibility.dart';
import 'catalog_storage_store.dart';

final class TrustedCatalogAdmissions {
  TrustedCatalogAdmissions({required this.projectRoot, Directory? directory})
      : _directory = directory ?? _defaultDirectory();

  final String projectRoot;
  final Directory _directory;

  Future<void> restore(CatalogSnapshot snapshot) async {
    final record = await _record(snapshot);
    final file = await _file(record);
    if (await FileSystemEntity.type(file.path, followLinks: false) ==
        FileSystemEntityType.notFound) {
      throw const CatalogStorageException('catalog.preparation_required',
          'Prepare this catalog explicitly before local editing on this machine.');
    }
    await _requireFile(file);
    if (await file.length() > 8192) {
      throw const FormatException('catalog.admission: oversized record');
    }
    final source = await file.readAsString();
    final value = jsonDecode(source);
    if (value is! Map<String, dynamic> ||
        value.length != 3 ||
        value['storedBytes'] is! int ||
        value['fingerprint'] !=
            computeAuthoringJsonFingerprint({
              'admission': value['admission'],
              'storedBytes': value['storedBytes'],
            }, logicalName: 'trusted-catalog-admission.json') ||
        canonicalAuthoringJson(value['admission']) !=
            canonicalAuthoringJson(record) ||
        canonicalAuthoringJson(value) != source) {
      throw const FormatException('catalog.admission: invalid trusted record');
    }
    snapshot.restoreTrustedIndexAdmission(
        storedBytes: value['storedBytes'] as int);
  }

  Future<void> publish(CatalogSnapshot snapshot) async {
    final storedBytes = snapshot.admittedStoredBytes;
    if (storedBytes == null) {
      throw StateError(
          'Only an admitted catalog can publish a trusted admission.');
    }
    final record = await _record(snapshot);
    final file = await _file(record);
    final payload = <String, Object?>{
      'admission': record,
      'storedBytes': storedBytes
    };
    final bytes = utf8.encode(canonicalAuthoringJson({
      ...payload,
      'fingerprint': computeAuthoringJsonFingerprint(payload,
          logicalName: 'trusted-catalog-admission.json'),
    }));
    await _publishRecord(file, bytes);
  }

  Future<bool> metadataIndexPrepared(CatalogSnapshot snapshot) async {
    final record = {...await _record(snapshot), 'metadataIndexVersion': 3};
    final file = await _file(record);
    if (await FileSystemEntity.type(file.path, followLinks: false) ==
        FileSystemEntityType.notFound) {
      return false;
    }
    await _requireFile(file);
    if (await file.length() > 8192 ||
        await file.readAsString() != canonicalAuthoringJson(record)) {
      throw const FormatException(
          'catalog.admission: invalid metadata admission');
    }
    return true;
  }

  Future<void> publishMetadataIndex(CatalogSnapshot snapshot) async {
    if (snapshot.admittedStoredBytes == null) {
      throw StateError('The catalog has no structural admission.');
    }
    final record = {...await _record(snapshot), 'metadataIndexVersion': 3};
    await _publishRecord(
        await _file(record), utf8.encode(canonicalAuthoringJson(record)));
  }

  Future<String?> metadataContextRevision(CatalogSnapshot snapshot) async {
    final record = {...await _record(snapshot), 'contextVersion': 1};
    final file = await _file(record);
    if (await FileSystemEntity.type(file.path, followLinks: false) ==
        FileSystemEntityType.notFound) {
      return null;
    }
    await _requireFile(file);
    if (await file.length() > 8192) {
      throw const FormatException(
          'catalog.admission: oversized context record');
    }
    final source = await file.readAsString();
    final value = jsonDecode(source);
    if (value is! Map<String, dynamic> ||
        value.length != 3 ||
        value['metadataRevision'] is! String ||
        !RegExp(r'^sha256:[0-9a-f]{64}$')
            .hasMatch(value['metadataRevision'] as String) ||
        canonicalAuthoringJson(value['admission']) !=
            canonicalAuthoringJson(record) ||
        value['fingerprint'] !=
            computeAuthoringJsonFingerprint({
              'admission': value['admission'],
              'metadataRevision': value['metadataRevision'],
            }, logicalName: 'trusted-catalog-metadata-context.json') ||
        canonicalAuthoringJson(value) != source) {
      throw const FormatException(
          'catalog.admission: invalid metadata context');
    }
    return value['metadataRevision'] as String;
  }

  Future<String> publishMetadataContext(
      CatalogSnapshot snapshot, String metadataRevision) async {
    if (snapshot.admittedStoredBytes == null ||
        !RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(metadataRevision)) {
      throw StateError('The metadata context has no validated evidence.');
    }
    final existing = await metadataContextRevision(snapshot);
    if (existing != null) return existing;
    final record = {...await _record(snapshot), 'contextVersion': 1};
    final payload = <String, Object?>{
      'admission': record,
      'metadataRevision': metadataRevision,
    };
    await _publishRecord(
        await _file(record),
        utf8.encode(canonicalAuthoringJson({
          ...payload,
          'fingerprint': computeAuthoringJsonFingerprint(payload,
              logicalName: 'trusted-catalog-metadata-context.json'),
        })));
    return metadataRevision;
  }

  Future<void> publishHistoryConversion(
      CatalogPreparedHistoryConversion prepared) async {
    if (prepared.sourceSnapshot.admittedStoredBytes == null ||
        prepared.targetSnapshot.admittedStoredBytes == null) {
      throw StateError('The catalog conversion has no validated evidence.');
    }
    final record = await _historyConversionRecord(
        prepared.conversion, prepared.sourceSnapshot.limits);
    await _publishRecord(
        await _file(record), utf8.encode(canonicalAuthoringJson(record)));
  }

  Future<void> requireHistoryConversion(CatalogHistoryRootConversion conversion,
      CatalogStorageLimits limits) async {
    final record = await _historyConversionRecord(conversion, limits);
    final file = await _file(record);
    if (await FileSystemEntity.type(file.path, followLinks: false) ==
        FileSystemEntityType.notFound) {
      throw const CatalogStorageException('catalog.preparation_required',
          'Prepare this historical conversion explicitly in the current local authority.');
    }
    await _requireFile(file);
    if (await file.length() > 8192 ||
        await file.readAsString() != canonicalAuthoringJson(record)) {
      throw const FormatException(
          'catalog.admission: invalid history conversion admission');
    }
  }

  Future<Map<String, Object?>> _historyConversionRecord(
          CatalogHistoryRootConversion conversion,
          CatalogStorageLimits limits) async =>
      {
        'schemaVersion': 1,
        'projectRoot': await Directory(projectRoot).resolveSymbolicLinks(),
        'historyConversion': conversion.toJson(),
        'limits': _limitValues(limits),
      };

  Future<void> _publishRecord(File file, List<int> bytes) async {
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type != FileSystemEntityType.notFound) {
      await _requireFile(file);
      if (await file.length() > 8192 ||
          await file.readAsString() != utf8.decode(bytes)) {
        throw const FormatException(
            'catalog.admission: conflicting trusted record');
      }
      return;
    }
    final suffix = List.generate(
            16,
            (_) =>
                Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
    final staging = File('${file.path}.$suffix.tmp');
    try {
      await staging.create(exclusive: true);
      await staging.writeAsBytes(bytes, flush: true);
      await _requireFile(staging);
      await staging.rename(file.path);
    } finally {
      if (await staging.exists()) await staging.delete();
    }
  }

  Future<Map<String, Object?>> _record(CatalogSnapshot snapshot) async => {
        'schemaVersion': 1,
        'projectRoot': await Directory(projectRoot).resolveSymbolicLinks(),
        'root': snapshot.root.toJson(),
        'limits': _limitValues(snapshot.limits),
      };

  static List<int> _limitValues(CatalogStorageLimits limits) => [
        limits.maxUnitBytes,
        limits.maxIndexBytes,
        limits.indexPageSize,
        limits.maxDefinitions,
        limits.maxJsonDepth,
        limits.maxJsonValues,
        limits.maxReferencesPerUnit,
        limits.maxIndexDepth,
        limits.maxClosureNodes,
        limits.maxClosureDepth,
        limits.maxStoredBytes,
      ];

  Future<File> _file(Map<String, Object?> record) async {
    final requested = _directory.absolute;
    final project = await Directory(projectRoot).resolveSymbolicLinks();
    final requestedPath = requested.path;
    if (_within(project, requestedPath) || _within(requestedPath, project)) {
      throw const CatalogStorageException('catalog.admission_path_unsafe',
          'Trusted catalog admissions must be outside project storage.');
    }
    final pending = <Directory>[];
    var current = requested;
    while (await FileSystemEntity.type(current.path, followLinks: false) ==
        FileSystemEntityType.notFound) {
      pending.add(current);
      current = current.parent;
    }
    if (await FileSystemEntity.type(current.path, followLinks: false) !=
        FileSystemEntityType.directory) {
      throw const FormatException('catalog.admission: unsafe directory');
    }
    final resolved = await current.resolveSymbolicLinks();
    if (resolved != current.path || _within(project, resolved)) {
      throw const FormatException(
          'catalog.admission: aliased trusted directory');
    }
    for (final directory in pending.reversed) {
      try {
        await directory.create();
      } on FileSystemException {
        if (await FileSystemEntity.type(directory.path, followLinks: false) !=
            FileSystemEntityType.directory) {
          rethrow;
        }
      }
    }
    final canonical = await requested.resolveSymbolicLinks();
    if (canonical != requestedPath || _within(project, canonical)) {
      throw const FormatException(
          'catalog.admission: aliased trusted directory');
    }
    final stat = await requested.stat();
    if (!Platform.isWindows && stat.mode & 0x12 != 0) {
      throw const FormatException(
          'catalog.admission: writable trusted directory');
    }
    final digest =
        sha256.convert(utf8.encode(canonicalAuthoringJson(record))).toString();
    return File('$canonical/$digest.json');
  }

  Future<void> _requireFile(File file) async {
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
            FileSystemEntityType.file ||
        (!Platform.isWindows && (await file.stat()).mode & 0x12 != 0)) {
      throw const FormatException('catalog.admission: unsafe trusted record');
    }
  }

  static Directory _defaultDirectory() {
    final home =
        Platform.environment[Platform.isWindows ? 'LOCALAPPDATA' : 'HOME'];
    if (home == null || home.isEmpty) {
      throw StateError(
          'A private local authoring storage directory is required.');
    }
    return Directory('$home/.avelune/authoring/catalog-admissions');
  }

  static bool _within(String parent, String child) =>
      child == parent || child.startsWith('$parent${Platform.pathSeparator}');
}
