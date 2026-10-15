import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';

List<int> _marshal(List<int> body) => [4, 8, ...body];
List<int> _text(String value) => [34, value.length + 5, ...utf8.encode(value)];
List<int> _float(String value) =>
    [102, value.length + 5, ...ascii.encode(value)];
List<int> _symbol(String value) =>
    [58, value.length + 5, ...ascii.encode(value)];
List<int> _unknown() => [117, ..._symbol('Unknown'), 8, 0, 255, 42];
SourceFileEntry _entry(List<int> bytes,
        {String id = 'file-1', String path = 'Data/Fixture.rxdata'}) =>
    SourceFileEntry(
        fileId: ConverterId(id),
        relativePath: path,
        kind: SourceNodeKind.file,
        byteLength: bytes.length,
        sha256: Sha256Hash(crypto.sha256.convert(bytes).toString()),
        format: 'marshal',
        family: 'data');

Map<String, dynamic> _mutable(SourceArchive archive) =>
    jsonDecode(jsonEncode(archive.toJson())) as Map<String, dynamic>;

SourceLocator _locator(String path, {int? commandIndex}) {
  final json = jsonDecode(
          File('test/fixtures/asset_candidate.example.json').readAsStringSync())
      as Map;
  final locator = (json['parts'] as List).first['locator'] as Map;
  locator['file'] = path;
  locator['commandIndex'] = commandIndex;
  return AssetCandidate.fromJson(json).parts.first.locator;
}

Matcher _error(String value) =>
    isA<ContractError>().having((error) => error.code, 'code', value);

void main() {
  group('sealed source digests', () {
    test(
        'unsealed archive stays fresh and sealed archive reuses its exact digest',
        () {
      final archive = SourceArchive();
      final empty = archive.canonicalHash;
      final bytes = _marshal(_text('opaque'));
      final entry = _entry(bytes);
      archive.add(entry, bytes);
      final added = archive.canonicalHash;
      expect(added, isNot(empty));
      archive.reference(fileId: entry.fileId, nodeId: 0);
      final referenced = archive.canonicalHash;
      expect(referenced, isNot(added));
      archive.seal();
      final sealed = archive.canonicalHash;
      expect(sealed, referenced);
      expect(archive.canonicalHash, same(sealed));
      archive.seal();
      expect(archive.canonicalHash, same(sealed));
      final oracle = _mutable(archive);
      for (final file in oracle['files'] as List) {
        (file as Map).remove('rawBytes');
      }
      expect(sealed, canonicalHashOf(oracle));
      expect(() => archive.add(entry, bytes),
          throwsA(_error('source_archive.sealed')));
      expect(() => archive.reference(fileId: entry.fileId, nodeId: 0),
          throwsA(_error('source_archive.sealed')));
    });

    test(
        'sealed byte buffers and roundtrip input cannot mutate the cached archive',
        () {
      final bytes = _marshal(_text('opaque'));
      final entry = _entry(bytes);
      final archive = SourceArchive()
        ..add(entry, bytes)
        ..seal();
      final first = archive.canonicalHash;
      final file = archive.files.values.single;
      expect(() => (file.rawBytes as Uint8List).buffer.asUint8List()[0] = 0,
          throwsUnsupportedError);
      final node = file.document.node(file.document.rootId);
      expect(() => (node.bytes as Uint8List).buffer.asUint8List()[0] = 0,
          throwsUnsupportedError);
      final restored = SourceArchive.fromJson(_mutable(archive));
      expect(restored.canonicalHash, first);
      expect(restored.canonicalHash, same(restored.canonicalHash));
      expect(restored.canonicalHash, isNot(same(first)));
      final forged = _mutable(archive);
      (forged['files'] as List).single['rawBytes'] = base64Encode([4, 8, 48]);
      expect(
          () => SourceArchive.fromJson(forged), throwsA(isA<ContractError>()));
      bytes[0] = 0;
      expect(archive.canonicalHash, first);
    });
  });

  test('archive retains exact immutable bytes and decodes each file once', () {
    final bytes = _marshal(_text('opaque'));
    final original = [...bytes];
    final entry = _entry(bytes);
    final archive = SourceArchive();
    final first = archive.add(entry, bytes);
    final second = archive.add(entry, bytes);
    expect(second, same(first));
    expect(second.document, same(first.document));
    bytes[0] = 0;
    expect(first.rawBytes, original);
    expect(first.document.node(first.document.rootId).text().text, 'opaque');
    expect(() => first.rawBytes[0] = 0, throwsUnsupportedError);
    expect(() => archive.files.clear(), throwsUnsupportedError);
    expect(first.contentHash, entry.sha256);
  });

  test(
      'cycles non-finite floats and unknown user payload survive JSON roundtrip',
      () {
    final bytes = _marshal([
      91,
      10,
      64,
      0,
      ..._float('nan'),
      ..._float('inf'),
      ..._float('-inf'),
      ..._unknown(),
    ]);
    final archive = SourceArchive();
    final entry = _entry(bytes);
    final file = archive.add(entry, bytes);
    final unknownId = file.document.node(file.document.rootId).elements.last;
    final ref = archive.reference(fileId: entry.fileId, nodeId: unknownId);
    final json = _mutable(archive);
    final restored = SourceArchive.fromJson(json);
    final document = restored.files[entry.fileId]!.document;
    final root = document.node(document.rootId);
    expect(root.elements.first, document.rootId);
    expect(document.node(root.elements[1]).floatValue!.isNaN, isTrue);
    expect(document.node(root.elements[2]).floatValue, double.infinity);
    expect(document.node(root.elements[3]).floatValue, double.negativeInfinity);
    expect(document.node(root.elements[4]).className, 'Unknown');
    expect(document.node(root.elements[4]).bytes, [0, 255, 42]);
    expect(restored.references[ref.id]!.nodeId, unknownId);
    expect(restored.files[entry.fileId]!.rawBytes, bytes);
    expect(restored.canonicalHash, archive.canonicalHash);
    final encoded = jsonEncode(json);
    expect(RegExp(RegExp.escape(base64Encode(bytes))).allMatches(encoded),
        hasLength(1));
    expect(encoded, isNot(contains('floatValue')));
  });

  test('references bind file content node decoder policy and semantic locator',
      () {
    final bytes = _marshal([91, 7, ..._text('a'), ..._text('b')]);
    final entry = _entry(bytes);
    final archive = SourceArchive()..add(entry, bytes);
    final node = archive.files[entry.fileId]!.document.nodes.last;
    final nodeId = archive.files[entry.fileId]!.document.nodes.length - 1;
    final first = archive.reference(
        fileId: entry.fileId,
        nodeId: nodeId,
        locator: _locator(entry.relativePath, commandIndex: 2));
    final sameReference = archive.reference(
        fileId: entry.fileId,
        nodeId: nodeId,
        locator: _locator(entry.relativePath, commandIndex: 2));
    expect(sameReference, same(first));
    expect(first.status, 'preservedOnly');
    expect(first.decoderPolicyVersion, 'marshal-4.8-v1');
    expect(first.binaryLocation.byteOffset, node.location.byteOffset);
    expect(first.binaryLocation.graphPath, node.location.graphPath);
    expect(first.contentHash, entry.sha256);
    expect(
        archive
            .reference(
                fileId: entry.fileId,
                nodeId: nodeId,
                locator: _locator(entry.relativePath, commandIndex: 3))
            .id,
        isNot(first.id));
    expect(
        archive.reference(fileId: entry.fileId, nodeId: 0).id, isNot(first.id));
    final other = SourceArchive()..add(_entry(bytes, id: 'file-2'), bytes);
    expect(other.reference(fileId: ConverterId('file-2'), nodeId: nodeId).id,
        isNot(first.id));
    final changedBytes = _marshal([91, 7, ..._text('a'), ..._text('c')]);
    final changed = SourceArchive()..add(_entry(changedBytes), changedBytes);
    expect(
        changed
            .reference(
                fileId: entry.fileId,
                nodeId: nodeId,
                locator: _locator(entry.relativePath, commandIndex: 2))
            .id,
        isNot(first.id));
    expect(() => archive.references.clear(), throwsUnsupportedError);
  });

  test('canonical archive identity is independent of registration order', () {
    final a = _marshal(_text('a'));
    final b = _marshal(_text('b'));
    final aEntry = _entry(a, id: 'a', path: 'Data/A.rxdata');
    final bEntry = _entry(b, id: 'b', path: 'Data/B.rxdata');
    final first = SourceArchive()
      ..add(aEntry, a)
      ..add(bEntry, b)
      ..reference(fileId: aEntry.fileId, nodeId: 0)
      ..reference(fileId: bEntry.fileId, nodeId: 0);
    final second = SourceArchive()
      ..add(bEntry, b)
      ..add(aEntry, a)
      ..reference(fileId: bEntry.fileId, nodeId: 0)
      ..reference(fileId: aEntry.fileId, nodeId: 0);
    expect(first.canonicalHash, second.canonicalHash);
    expect(jsonEncode(first.toJson()), jsonEncode(second.toJson()));
  });

  test('sealed archives and loaded archives reject further mutations', () {
    final bytes = _marshal([48]);
    final entry = _entry(bytes);
    final archive = SourceArchive()..add(entry, bytes);
    expect(archive.isSealed, isFalse);
    archive.seal();
    archive.seal();
    expect(archive.isSealed, isTrue);
    expect(() => archive.add(entry, bytes),
        throwsA(_error('source_archive.sealed')));
    expect(() => archive.reference(fileId: entry.fileId, nodeId: 0),
        throwsA(_error('source_archive.sealed')));
    final restored = SourceArchive.fromJson(archive.toJson());
    expect(restored.isSealed, isTrue);
    expect(() => restored.add(entry, bytes),
        throwsA(_error('source_archive.sealed')));
  });

  test('invalid limits are refused by both constructor and JSON reader', () {
    for (final limits in [
      const SourceArchiveLimits(maxFiles: 0),
      const SourceArchiveLimits(maxTotalBytes: -1),
      const SourceArchiveLimits(maxFileBytes: 67108865),
      const SourceArchiveLimits(maxReferences: 0),
      const SourceArchiveLimits(maxEncodedCodeUnits: 1 << 40),
      const SourceArchiveLimits(maxTotalNodes: 0),
      const SourceArchiveLimits(maxTotalEntries: 8000001),
      const SourceArchiveLimits(maxTotalLocationCodeUnits: 134217729),
    ]) {
      expect(() => SourceArchive(limits: limits),
          throwsA(_error('source_archive.invalid_limits')));
      expect(() => SourceArchive.fromJson({}, limits: limits),
          throwsA(_error('source_archive.invalid_limits')));
    }
  });

  test('file quota runs before source byte reads', () {
    final bytes = _marshal([48]);
    final archive =
        SourceArchive(limits: const SourceArchiveLimits(maxFiles: 1))
          ..add(_entry(bytes), bytes);
    final unreadable = _UnreadableBytes(bytes.length);
    expect(() => archive.add(_entry(bytes, id: 'file-2'), unreadable),
        throwsA(_error('source_archive.quota.files')));
    expect(unreadable.reads, 0);
  });

  test('file and total byte quotas run before copying or decoding', () {
    final bytes = _marshal(_text('large'));
    for (final limits in [
      SourceArchiveLimits(maxFileBytes: bytes.length - 1),
      SourceArchiveLimits(maxTotalBytes: bytes.length - 1),
    ]) {
      final unreadable = _UnreadableBytes(bytes.length);
      expect(
          () => SourceArchive(limits: limits).add(_entry(bytes), unreadable),
          throwsA(_error(limits.maxFileBytes < bytes.length
              ? 'source_archive.quota.file_bytes'
              : 'source_archive.quota.total_bytes')));
      expect(unreadable.reads, 0);
    }
  });

  test('aggregate quotas do not mutate an archive when an add fails', () {
    final bytes = _marshal([48]);
    final archive =
        SourceArchive(limits: SourceArchiveLimits(maxTotalBytes: bytes.length))
          ..add(_entry(bytes), bytes);
    expect(() => archive.add(_entry(bytes, id: 'second'), bytes),
        throwsA(_error('source_archive.quota.total_bytes')));
    expect(archive.files, hasLength(1));
  });

  test('encoded budget is checked before source reads and base64 allocations',
      () {
    final bytes = _marshal(_text('a'));
    final unreadable = _UnreadableBytes(bytes.length);
    expect(
        () => SourceArchive(
                limits: const SourceArchiveLimits(maxEncodedCodeUnits: 1))
            .add(_entry(bytes), unreadable),
        throwsA(_error('source_archive.quota.encoded')));
    expect(unreadable.reads, 0);
  });

  test('reference quota accepts the same reference but rejects a new one', () {
    final bytes = _marshal([91, 7, 48, 84]);
    final entry = _entry(bytes);
    final archive =
        SourceArchive(limits: const SourceArchiveLimits(maxReferences: 1))
          ..add(entry, bytes);
    final first = archive.reference(fileId: entry.fileId, nodeId: 0);
    expect(archive.reference(fileId: entry.fileId, nodeId: 0), same(first));
    expect(() => archive.reference(fileId: entry.fileId, nodeId: 1),
        throwsA(_error('source_archive.quota.references')));
    expect(archive.references, hasLength(1));
  });

  test('reference encoded quota fails before registration and identity hashing',
      () {
    final bytes = _marshal(_text('a'));
    final entry = _entry(bytes);
    final source = SourceArchive()..add(entry, bytes);
    final maximum = jsonEncode(source.toJson()).length;
    final archive =
        SourceArchive(limits: SourceArchiveLimits(maxEncodedCodeUnits: maximum))
          ..add(entry, bytes);
    expect(() => archive.reference(fileId: entry.fileId, nodeId: 0),
        throwsA(_error('source_archive.quota.encoded')));
    expect(archive.references, isEmpty);
  });

  test('hash length kind and duplicate file identity are validated', () {
    final bytes = _marshal([48]);
    final archive = SourceArchive()..add(_entry(bytes), bytes);
    expect(() => archive.add(_entry(_marshal([84])), bytes),
        throwsA(_error('source_archive.hash')));
    expect(() => archive.add(_entry(bytes), [...bytes, 0]),
        throwsA(_error('source_archive.length')));
    expect(() => archive.add(_entry(bytes, path: 'Data/Other.rxdata'), bytes),
        throwsA(_error('source_archive.duplicate_file')));
    expect(
        () => archive.add(
            SourceFileEntry(
                fileId: ConverterId('directory'),
                relativePath: 'Data',
                kind: SourceNodeKind.directory,
                byteLength: 0,
                sha256: null,
                format: 'directory',
                family: 'directory'),
            []),
        throwsA(_error('source_archive.file_kind')));
  });

  test('malformed Marshal and non-byte input cannot be registered', () {
    final invalid = [4, 8, 48, 1];
    final archive = SourceArchive();
    expect(() => archive.add(_entry(invalid), invalid),
        throwsA(isA<BinaryDecodeError>()));
    expect(archive.files, isEmpty);
    expect(() => archive.add(_entry([4, 8, 48]), [4, 8, 304]),
        throwsA(_error('source_archive.bytes')));
  });

  test('missing file wrong node and foreign locators cannot form references',
      () {
    final bytes = _marshal([48]);
    final entry = _entry(bytes);
    final archive = SourceArchive()..add(entry, bytes);
    expect(() => archive.reference(fileId: ConverterId('missing'), nodeId: 0),
        throwsA(_error('source_archive.reference_file')));
    for (final nodeId in [-1, 1]) {
      expect(() => archive.reference(fileId: entry.fileId, nodeId: nodeId),
          throwsA(_error('source_archive.reference_node')));
    }
    expect(
        () => archive.reference(
            fileId: entry.fileId,
            nodeId: 0,
            locator: _locator('Data/Foreign.rxdata')),
        throwsA(_error('source_archive.locator')));
  });

  test('JSON reader rejects extra fields and unknown decoder policies', () {
    final bytes = _marshal([48]);
    final archive = SourceArchive()..add(_entry(bytes), bytes);
    for (final json in [
      _mutable(archive)..['extra'] = 1,
      _mutable(archive)..['decoderPolicyVersion'] = 'future',
      _mutable(archive)..['kind'] = 'other',
      _mutable(archive)..['schemaVersion'] = '2.0',
    ]) {
      expect(() => SourceArchive.fromJson(json), throwsA(isA<ContractError>()));
    }
    final file = _mutable(archive);
    (file['files'] as List).first['extra'] = 1;
    expect(() => SourceArchive.fromJson(file),
        throwsA(_error('source_archive.shape')));
    final entry = _mutable(archive);
    (entry['files'] as List).first['entry']['extra'] = 1;
    expect(() => SourceArchive.fromJson(entry),
        throwsA(_error('source_archive.shape')));
  });

  test('JSON reader validates raw base64 hashes and entry lengths', () {
    final bytes = _marshal([48]);
    final archive = SourceArchive()..add(_entry(bytes), bytes);
    final invalidBase64 = _mutable(archive);
    (invalidBase64['files'] as List).first['rawBytes'] = '***=';
    expect(() => SourceArchive.fromJson(invalidBase64),
        throwsA(_error('source_archive.base64')));
    final wrongHash = _mutable(archive);
    (wrongHash['files'] as List).first['contentHash'] = 'a' * 64;
    expect(() => SourceArchive.fromJson(wrongHash),
        throwsA(_error('source_archive.hash')));
    final wrongLength = _mutable(archive);
    (wrongLength['files'] as List).first['entry']['byteLength'] = 2;
    expect(() => SourceArchive.fromJson(wrongLength),
        throwsA(_error('source_archive.length')));
    final alteredRaw = _mutable(archive);
    (alteredRaw['files'] as List).first['rawBytes'] =
        base64Encode(_marshal([84]));
    expect(() => SourceArchive.fromJson(alteredRaw),
        throwsA(_error('source_archive.hash')));
  });

  test('canonical base64 rejects whitespace URL alphabet and unused pad bits',
      () {
    final bytes = _marshal([91, 0]);
    final archive = SourceArchive()..add(_entry(bytes), bytes);
    final canonical = base64Encode(bytes);
    expect(canonical, 'BAhbAA==');
    for (final encoded in ['BAhbAB==', 'BAhbA_==', 'BAhbA ==', 'BAhbA===']) {
      final json = _mutable(archive);
      (json['files'] as List).first['rawBytes'] = encoded;
      expect(() => SourceArchive.fromJson(json),
          throwsA(_error('source_archive.base64')));
    }
  });

  test('same physical path cannot be archived under two file identities', () {
    final bytes = _marshal([48]);
    final archive = SourceArchive()..add(_entry(bytes), bytes);
    expect(() => archive.add(_entry(bytes, id: 'second'), bytes),
        throwsA(_error('source_archive.duplicate_file')));
  });

  test('JSON reader accepts string keys in inert maps of wider static types',
      () {
    final bytes = _marshal([48]);
    final entry = _entry(bytes);
    final archive = SourceArchive()
      ..add(entry, bytes)
      ..reference(
          fileId: entry.fileId,
          nodeId: 0,
          locator: _locator(entry.relativePath));
    Object? widen(Object? value) {
      if (value is Map) {
        return <Object?, Object?>{
          for (final pair in value.entries) pair.key: widen(pair.value)
        };
      }
      if (value is List) return value.map(widen).toList();
      return value;
    }

    expect(SourceArchive.fromJson(widen(archive.toJson())).canonicalHash,
        archive.canonicalHash);
  });

  test('JSON reader rejects duplicate file and reference records', () {
    final bytes = _marshal([48]);
    final entry = _entry(bytes);
    final archive = SourceArchive()
      ..add(entry, bytes)
      ..reference(fileId: entry.fileId, nodeId: 0);
    final file = _mutable(archive);
    (file['files'] as List).add((file['files'] as List).first);
    expect(() => SourceArchive.fromJson(file),
        throwsA(_error('source_archive.duplicate_file')));
    final ref = _mutable(archive);
    (ref['references'] as List).add((ref['references'] as List).first);
    expect(() => SourceArchive.fromJson(ref),
        throwsA(_error('source_archive.duplicate_reference')));
  });

  test('JSON reader rejects forged reference ids locations and locators', () {
    final bytes = _marshal([48]);
    final entry = _entry(bytes);
    final archive = SourceArchive()
      ..add(entry, bytes)
      ..reference(
          fileId: entry.fileId,
          nodeId: 0,
          locator: _locator(entry.relativePath, commandIndex: 2));
    for (final change in <void Function(Map)>[
      (ref) => ref['id'] = 'forged',
      (ref) => ref['contentHash'] = 'a' * 64,
      (ref) => ref['fileId'] = 'missing',
      (ref) => ref['nodeId'] = 1,
      (ref) => ref['binaryLocation']['byteOffset'] = 0,
      (ref) => ref['binaryLocation']['graphPath'] = 'forged',
      (ref) => ref['binaryLocation']['sourcePath'] = 'Data/Foreign.rxdata',
      (ref) => ref['binaryLocation']['tag'] = 84,
      (ref) => ref['binaryLocation']['extra'] = 1,
      (ref) => ref['locator']['commandIndex'] = 3,
      (ref) => ref['locator']['file'] = 'Data/Foreign.rxdata',
      (ref) => ref['decoderPolicyVersion'] = 'future',
      (ref) => ref['status'] = 'executed',
      (ref) => ref['extra'] = 1,
      (ref) => ref['locator']['extra'] = 1,
    ]) {
      final json = _mutable(archive);
      change((json['references'] as List).first as Map);
      expect(() => SourceArchive.fromJson(json), throwsA(isA<ContractError>()));
    }
  });

  test('JSON count byte and encoded quotas reject before reconstruction', () {
    final bytes = _marshal(_text('a'));
    final entry = _entry(bytes);
    final archive = SourceArchive()
      ..add(entry, bytes)
      ..reference(fileId: entry.fileId, nodeId: 0);
    final fileCount = _mutable(archive);
    (fileCount['files'] as List).add((fileCount['files'] as List).first);
    expect(
        () => SourceArchive.fromJson(fileCount,
            limits: const SourceArchiveLimits(maxFiles: 1)),
        throwsA(_error('source_archive.quota.files')));
    final refCount = _mutable(archive);
    (refCount['references'] as List)
        .add((refCount['references'] as List).first);
    expect(
        () => SourceArchive.fromJson(refCount,
            limits: const SourceArchiveLimits(maxReferences: 1)),
        throwsA(_error('source_archive.quota.references')));
    expect(
        () => SourceArchive.fromJson(_mutable(archive),
            limits: SourceArchiveLimits(maxTotalBytes: bytes.length - 1)),
        throwsA(_error('source_archive.quota.total_bytes')));
    expect(
        () => SourceArchive.fromJson(_mutable(archive),
            limits: const SourceArchiveLimits(maxEncodedCodeUnits: 1)),
        throwsA(_error('source_archive.quota.encoded')));
  });

  test('aggregate node quota is passed into decoding before allocation', () {
    final bytes = _marshal([91, 7, 48, 84]);
    final archive =
        SourceArchive(limits: const SourceArchiveLimits(maxTotalNodes: 2));
    expect(() => archive.add(_entry(bytes), bytes),
        throwsA(_error('source_archive.quota.nodes')));
    expect(archive.files, isEmpty);
    final small = _marshal([48]);
    archive.add(_entry(small), small);
    archive.add(_entry(small, id: 'second', path: 'Data/Second.rxdata'), small);
    final unreadable = _UnreadableBytes(small.length);
    expect(
        () => archive.add(
            _entry(small, id: 'third', path: 'Data/Third.rxdata'), unreadable),
        throwsA(_error('source_archive.quota.nodes')));
    expect(unreadable.reads, 0);
    expect(archive.files, hasLength(2));
  });

  test('aggregate edge quota includes arrays pairs ivars and defaults', () {
    final bytes = _marshal([91, 7, 48, 84]);
    final archive =
        SourceArchive(limits: const SourceArchiveLimits(maxTotalEntries: 1));
    expect(() => archive.add(_entry(bytes), bytes),
        throwsA(_error('source_archive.quota.entries')));
    expect(archive.files, isEmpty);
    final one = _marshal([91, 6, 48]);
    archive.add(_entry(one), one);
    expect(
        () => archive.add(
            _entry(one, id: 'second', path: 'Data/Second.rxdata'), one),
        throwsA(_error('source_archive.quota.entries')));
    final hash = _marshal([125, 6, 48, 84, 70]);
    final separate =
        SourceArchive(limits: const SourceArchiveLimits(maxTotalEntries: 2));
    expect(() => separate.add(_entry(hash), hash),
        throwsA(_error('source_archive.quota.entries')));
    final ivar = _marshal([73, ..._text('a'), 6, ..._symbol('E'), 84]);
    final ivarArchive =
        SourceArchive(limits: const SourceArchiveLimits(maxTotalEntries: 1));
    expect(() => ivarArchive.add(_entry(ivar), ivar),
        throwsA(_error('source_archive.quota.entries')));
  });

  test('user-marshal payload cycles are retained as inert graph edges', () {
    final bytes = _marshal([85, ..._symbol('Mystery'), 64, 0]);
    final entry = _entry(bytes);
    final archive = SourceArchive()..add(entry, bytes);
    final restored = SourceArchive.fromJson(archive.toJson());
    final document = restored.files[entry.fileId]!.document;
    final root = document.node(document.rootId);
    expect(root.kind, MarshalKind.userMarshal);
    expect(root.className, 'Mystery');
    expect(root.elements, [document.rootId]);
  });

  test('an exhausted edge budget rejects another scalar without mutation', () {
    final one = _marshal([91, 6, 48]);
    final archive =
        SourceArchive(limits: const SourceArchiveLimits(maxTotalEntries: 1))
          ..add(_entry(one), one);
    final before = archive.canonicalHash;
    final scalar = _marshal([48]);
    final unreadable = _UnreadableBytes(scalar.length);
    expect(
        () => archive.add(
            _entry(scalar, id: 'second', path: 'Data/Second.rxdata'),
            unreadable),
        throwsA(_error('source_archive.quota.entries')));
    expect(unreadable.reads, 0);
    expect(archive.files, hasLength(1));
    expect(archive.canonicalHash, before);
  });

  test('JSON refuses exhausted graph budgets before decoding more base64', () {
    final scalar = _marshal([48]);
    final archive = SourceArchive()
      ..add(_entry(scalar), scalar)
      ..add(_entry(scalar, id: 'second', path: 'Data/Second.rxdata'), scalar);
    final input = _mutable(archive);
    ((input['files'] as List)[1] as Map)['rawBytes'] = '!AAA';
    expect(
        () => SourceArchive.fromJson(input,
            limits: const SourceArchiveLimits(maxTotalNodes: 1)),
        throwsA(_error('source_archive.quota.nodes')));
  });

  test('aggregate locations are counted using original graph paths', () {
    final bytes = _marshal([91, 6, 48]);
    final document = const MarshalDecoder().decode(bytes);
    final used = document.nodes
        .fold<int>(0, (total, node) => total + node.location.graphPath.length);
    final archive = SourceArchive(
        limits: SourceArchiveLimits(maxTotalLocationCodeUnits: used))
      ..add(_entry(bytes), bytes);
    expect(
        () => archive.add(
            _entry(bytes, id: 'second', path: 'Data/Second.rxdata'), bytes),
        throwsA(_error('source_archive.quota.locations')));
    final fresh = SourceArchive(
        limits: SourceArchiveLimits(maxTotalLocationCodeUnits: used - 1));
    expect(() => fresh.add(_entry(bytes), bytes),
        throwsA(_error('source_archive.quota.locations')));
    expect(fresh.files, isEmpty);
  });

  test('JSON redecoding respects independent aggregate graph budgets', () {
    final bytes = _marshal([91, 6, 48]);
    final archive = SourceArchive()
      ..add(_entry(bytes), bytes)
      ..add(_entry(bytes, id: 'second', path: 'Data/Second.rxdata'), bytes);
    for (final limits in [
      const SourceArchiveLimits(maxTotalNodes: 3),
      const SourceArchiveLimits(maxTotalEntries: 1),
      const SourceArchiveLimits(maxTotalLocationCodeUnits: 7),
    ]) {
      expect(
          () => SourceArchive.fromJson(archive.toJson(), limits: limits),
          throwsA(isA<ContractError>().having((error) => error.code, 'code',
              startsWith('source_archive.quota.'))));
    }
  });
}

final class _UnreadableBytes extends ListBase<int> {
  _UnreadableBytes(this._length);
  final int _length;
  int reads = 0;
  @override
  int get length => _length;
  @override
  set length(int value) => throw UnsupportedError('length');
  @override
  int operator [](int index) {
    reads++;
    throw StateError('Quota must run before source byte access.');
  }

  @override
  void operator []=(int index, int value) => throw UnsupportedError('write');
}
