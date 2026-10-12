import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:path/path.dart' as path;

import 'vision_support.dart';
import 'vision_runtime.dart';

final class LocalVisionStore {
  LocalVisionStore(
      {required this.rootPath,
      required this.excludedRoots,
      this.limits = const VisionStoreLimits(),
      DateTime Function()? now})
      : now = now ?? DateTime.now;
  final String rootPath;
  final Future<List<String>> Function() excludedRoots;
  final VisionStoreLimits limits;
  final DateTime Function() now;
  static final _queues = <String, Future<void>>{};

  Future<VisionUsageSnapshot> usage() => _access(false,
      (root) async => _snapshot(root == null ? [] : await _ledger(root)));

  Future<VisionAttemptReservation> reserve(
          {required VisionRequest request,
          required VisionAssistancePolicy policy,
          required int attempt}) =>
      _access(true, (root) async {
        validateVisionPolicy(policy);
        requireVision(
            attempt >= 0 && attempt <= policy.maxRetries, 'vision.retryQuota');
        final pricing =
            effectiveVisionPricing(policy, request.material.model, now());
        final estimate = pricing == null
            ? null
            : visionTokenCost(pricing, policy.maxInputTokensPerAttempt,
                request.material.options['maxOutputTokens'] as int);
        final records = await _ledger(root!);
        requireVision(
            records.length < limits.maxAttempts &&
                records.length < policy.maxRequests,
            'vision.requestQuota');
        if (policy.maxCostMicros != null) {
          var charged = 0;
          for (final record in records) {
            final cost = record['costMicros'] ?? record['estimatedCostMicros'];
            requireVision(cost is int, 'vision.costUnknown');
            charged += cost as int;
          }
          requireVision(
              estimate != null && estimate <= policy.maxCostMicros! - charged,
              'vision.costQuota');
        }
        final id = ConverterId('attempt-${_nonce()}');
        records.add({
          'id': id.value,
          'materialHash': request.material.canonicalHash.value,
          'accountRevision': request.consent.accountRevision.value,
          'attempt': attempt,
          'model': request.material.model,
          'state': 'unknown',
          'estimatedCostMicros': estimate,
          'inputTokens': null,
          'outputTokens': null,
          'costMicros': null
        });
        await _writeLedger(root, records);
        return VisionAttemptReservation(id: id, estimatedCostMicros: estimate);
      });

  Future<void> complete(
          {required VisionAttemptReservation reservation,
          required VisionAssistancePolicy policy,
          VisionTokenUsage? usage}) =>
      _access(true, (root) async {
        final records = await _ledger(root!);
        final index =
            records.indexWhere((r) => r['id'] == reservation.id.value);
        requireVision(
            index >= 0 &&
                records[index]['state'] == 'unknown' &&
                records[index]['estimatedCostMicros'] ==
                    reservation.estimatedCostMicros,
            'vision.reservation');
        if (usage == null) return;
        final record = records[index];
        final pricing =
            effectiveVisionPricing(policy, record['model'] as String, now());
        final cost = pricing == null
            ? null
            : visionTokenCost(pricing, usage.inputTokens, usage.outputTokens);
        requireVision(
            usage.inputTokens >= 0 &&
                usage.inputTokens <= 2097152 &&
                usage.outputTokens >= 0 &&
                usage.outputTokens <= 2097152,
            'vision.usage');
        records[index] = {
          ...record,
          'state': 'reported',
          'inputTokens': usage.inputTokens,
          'outputTokens': usage.outputTokens,
          'costMicros': cost
        };
        await _writeLedger(root, records);
      });

  Future<void> releaseReservation(VisionAttemptReservation reservation) =>
      _access(true, (root) async {
        final records = await _ledger(root!);
        final index =
            records.indexWhere((r) => r['id'] == reservation.id.value);
        requireVision(
            index >= 0 &&
                records[index]['state'] == 'unknown' &&
                records[index]['estimatedCostMicros'] ==
                    reservation.estimatedCostMicros,
            'vision.reservation');
        records.removeAt(index);
        await _writeLedger(root, records);
      });

  Future<VisionResponse?> readCache(VisionRequest request) =>
      _access(false, (root) async {
        if (root == null) return null;
        final key = _cacheKey(request);
        final file = File(path.join(root, 'c-$key.json'));
        final input = await _read(file, limits.maxEntryBytes);
        if (input == null) return null;
        final json = _checkedEnvelope(input);
        visionKeys(json, const {'version', 'key', 'createdAt', 'response'});
        requireVision(
            json['version'] == 1 && json['key'] == key, 'vision.cacheIdentity');
        final created = DateTime.parse(json['createdAt'] as String);
        requireVision(!created.isAfter(now()), 'vision.cacheClock');
        if (now().difference(created) > limits.cacheTtl) {
          return null;
        }
        final responseJson = visionObject(json['response']);
        final previous = VisionResponse.fromJson(responseJson);
        requireVision(
            previous.sourceSnapshotHash == request.context.sourceSnapshotHash &&
                previous.inputRevision == request.context.inputRevision,
            'vision.cacheIdentity');
        final rebound = VisionResponse.fromJson(
            {...responseJson, 'requestId': request.context.requestId.value});
        validateVisionResponse(rebound, request.context);
        return rebound;
      });

  Future<void> writeCache(VisionRequest request, VisionResponse response) =>
      _access(true, (root) async {
        validateVisionResponse(response, request.context);
        final key = _cacheKey(request);
        final target = File(path.join(root!, 'c-$key.json'));
        final bytes = _envelope({
          'version': 1,
          'key': key,
          'createdAt': now().toUtc().toIso8601String(),
          'response': response.toJson()
        });
        requireVision(
            bytes.length <= limits.maxEntryBytes, 'vision.cacheQuota');
        var entries = 0;
        var totalBytes = 0;
        var directoryEntries = 0;
        await for (final entry in Directory(root).list(followLinks: false)) {
          requireVision(++directoryEntries <= limits.maxCacheEntries + 32,
              'vision.storeQuota');
          if (!RegExp(r'^c-[a-f0-9]{64}\.json$')
              .hasMatch(path.basename(entry.path))) {
            continue;
          }
          final stat = await _ordinaryFile(entry.path);
          if (entry.path != target.path) {
            entries++;
            totalBytes += stat.size;
          }
        }
        requireVision(
            entries < limits.maxCacheEntries &&
                bytes.length <= limits.maxCacheBytes - totalBytes,
            'vision.cacheQuota');
        await _publish(root, target, bytes);
      });

  String _cacheKey(VisionRequest request) {
    final metadata = Map<String, Object?>.from(request.material.toJson());
    final context = visionObject(metadata['context'])..remove('requestId');
    metadata['context'] = context;
    return canonicalHashOf({
      'version': 1,
      'material': metadata,
      'accountRevision': request.consent.accountRevision.value
    }).value;
  }

  VisionUsageSnapshot _snapshot(List<Map<String, Object?>> records) {
    final known = records.where((r) => r['costMicros'] != null).toList();
    final pending = records
        .where(
            (r) => r['state'] == 'unknown' && r['estimatedCostMicros'] != null)
        .toList();
    return VisionUsageSnapshot(
        requestCount: records.length,
        retryCount: records.where((r) => (r['attempt'] as int) > 0).length,
        unknownAttempts: records.where((r) => r['state'] == 'unknown').length,
        knownCostMicros: known.isEmpty
            ? null
            : known.fold<int>(0, (sum, r) => sum + (r['costMicros'] as int)),
        reservedCostMicros: pending.isEmpty
            ? null
            : pending.fold<int>(
                0, (sum, r) => sum + (r['estimatedCostMicros'] as int)));
  }

  Future<List<Map<String, Object?>>> _ledger(String root) async {
    final input = await _read(
        File(path.join(root, 'ledger.json')), limits.maxLedgerBytes);
    if (input == null) return [];
    final json = _checkedEnvelope(input);
    visionKeys(json, const {'version', 'revision', 'attempts'});
    requireVision(
        json['version'] == 1 &&
            json['revision'] is int &&
            (json['revision'] as int) > 0,
        'vision.ledger');
    final items = json['attempts'];
    requireVision(items is List && items.length <= limits.maxAttempts,
        'vision.ledgerQuota');
    final ids = <String>{};
    final result = <Map<String, Object?>>[];
    for (final item in items as List) {
      final r = visionObject(item);
      visionKeys(r, const {
        'id',
        'materialHash',
        'accountRevision',
        'attempt',
        'model',
        'state',
        'estimatedCostMicros',
        'inputTokens',
        'outputTokens',
        'costMicros'
      });
      final id = ConverterId(r['id'] as String);
      Sha256Hash(r['materialHash'] as String);
      ConverterId(r['accountRevision'] as String);
      ConverterId(r['model'] as String);
      requireVision(
          ids.add(id.value) &&
              r['attempt'] is int &&
              (r['attempt'] as int) >= 0 &&
              (r['attempt'] as int) <= 3 &&
              const {'unknown', 'reported'}.contains(r['state']),
          'vision.ledger');
      for (final key in ['estimatedCostMicros', 'costMicros']) {
        requireVision(
            r[key] == null ||
                (r[key] is int &&
                    (r[key] as int) >= 0 &&
                    (r[key] as int) <= 1000000000000000000),
            'vision.ledger');
      }
      final reported = r['state'] == 'reported';
      for (final key in ['inputTokens', 'outputTokens']) {
        requireVision(
            reported
                ? (r[key] is int &&
                    (r[key] as int) >= 0 &&
                    (r[key] as int) <= 2097152)
                : r[key] == null,
            'vision.ledger');
      }
      requireVision(reported || r['costMicros'] == null, 'vision.ledger');
      result.add(r);
    }
    return result;
  }

  Future<void> _writeLedger(
      String root, List<Map<String, Object?>> records) async {
    final file = File(path.join(root, 'ledger.json'));
    final old = await _read(file, limits.maxLedgerBytes);
    final revision =
        old == null ? 1 : (_checkedEnvelope(old)['revision'] as int) + 1;
    final bytes =
        _envelope({'version': 1, 'revision': revision, 'attempts': records});
    requireVision(bytes.length <= limits.maxLedgerBytes, 'vision.ledgerQuota');
    await _publish(root, file, bytes);
  }

  List<int> _envelope(Map<String, Object?> data) => utf8.encode(
      canonicalJsonOf({...data, 'canonicalHash': canonicalHashOf(data).value}));

  Map<String, Object?> _checkedEnvelope(Object? input) {
    final json = visionObject(input);
    final hash = json.remove('canonicalHash');
    requireVision(hash is String && canonicalHashOf(json).value == hash,
        'vision.storeHash');
    return json;
  }

  Future<Object?> _read(File file, int maxBytes) async {
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) return null;
    final stat = await _ordinaryFile(file.path);
    requireVision(stat.size <= maxBytes, 'vision.storeQuota');
    final bytes = await file.readAsBytes();
    requireVision(bytes.length == stat.size && bytes.length <= maxBytes,
        'vision.storeQuota');
    await _ordinaryFile(file.path);
    return decodeVisionJson(bytes, maxBytes);
  }

  Future<FileStat> _ordinaryFile(String target) async {
    requireVision(
        await FileSystemEntity.type(target, followLinks: false) ==
            FileSystemEntityType.file,
        'vision.storePath');
    final stat = await File(target).stat();
    requireVision(
        stat.type == FileSystemEntityType.file &&
            await File(target).resolveSymbolicLinks() == target,
        'vision.storePath');
    return stat;
  }

  Future<void> _publish(String root, File target, List<int> bytes) async {
    await _guardRoot(root);
    final type = await FileSystemEntity.type(target.path, followLinks: false);
    requireVision(
        type == FileSystemEntityType.file ||
            type == FileSystemEntityType.notFound,
        'vision.storePath');
    final temp = await Directory(root).createTemp('tmp-');
    try {
      await _private(temp.path, '700');
      final pending = File(path.join(temp.path, 'data.json'));
      await pending.writeAsBytes(bytes, flush: true);
      await _private(pending.path, '600');
      await _guardRoot(root);
      final current =
          await FileSystemEntity.type(target.path, followLinks: false);
      requireVision(
          current == FileSystemEntityType.file ||
              current == FileSystemEntityType.notFound,
          'vision.storePath');
      await pending.rename(target.path);
      await _ordinaryFile(target.path);
    } finally {
      if (await FileSystemEntity.type(temp.path, followLinks: false) ==
              FileSystemEntityType.directory &&
          await temp.resolveSymbolicLinks() == temp.path) {
        await temp.delete(recursive: true);
      }
    }
  }

  Future<T> _access<T>(
      bool create, Future<T> Function(String?) operation) async {
    try {
      _validateLimits();
      requireVision(path.isAbsolute(rootPath), 'vision.storePath');
      requireVision(
          await FileSystemEntity.type(rootPath, followLinks: false) !=
              FileSystemEntityType.link,
          'vision.storePath');
      final root = await _canonical(path.normalize(rootPath));
      for (final otherPath in await excludedRoots()) {
        requireVision(path.isAbsolute(otherPath), 'vision.storePath');
        final other = await _canonical(path.normalize(otherPath));
        requireVision(
            !path.equals(root, other) &&
                !path.isWithin(root, other) &&
                !path.isWithin(other, root),
            'vision.storeOverlap');
      }
      final previous = _queues[root] ?? Future<void>.value();
      final done = Completer<void>();
      _queues[root] = done.future;
      await previous;
      try {
        final type = await FileSystemEntity.type(root, followLinks: false);
        requireVision(
            type == FileSystemEntityType.directory ||
                type == FileSystemEntityType.notFound,
            'vision.storePath');
        if (type == FileSystemEntityType.notFound) {
          if (!create) return await operation(null);
          await Directory(root).create(recursive: true);
        }
        await _guardRoot(root);
        await _private(root, '700');
        final lock = File(path.join(root, '.vision.lock'));
        final lockType =
            await FileSystemEntity.type(lock.path, followLinks: false);
        requireVision(
            lockType == FileSystemEntityType.file ||
                lockType == FileSystemEntityType.notFound,
            'vision.storePath');
        final handle = await lock.open(mode: FileMode.append);
        var locked = false;
        try {
          await _private(lock.path, '600');
          final deadline = DateTime.now().add(const Duration(seconds: 10));
          while (!locked) {
            try {
              await handle.lock(FileLock.exclusive);
              locked = true;
            } on FileSystemException {
              requireVision(
                  DateTime.now().isBefore(deadline), 'vision.storeBusy');
              await Future<void>.delayed(const Duration(milliseconds: 10));
            }
          }
          await _guardRoot(root);
          await _ordinaryFile(lock.path);
          return await operation(root);
        } finally {
          if (locked) await handle.unlock();
          await handle.close();
        }
      } finally {
        done.complete();
        if (identical(_queues[root], done.future)) _queues.remove(root);
      }
    } on VisionAssistanceException {
      rethrow;
    } catch (_) {
      throw const VisionAssistanceException('vision.storageFailed');
    }
  }

  Future<void> _guardRoot(String root) async => requireVision(
      await FileSystemEntity.type(rootPath, followLinks: false) ==
              FileSystemEntityType.directory &&
          await Directory(rootPath).resolveSymbolicLinks() == root,
      'vision.storePath');

  Future<String> _canonical(String target) async {
    final missing = <String>[];
    var current = target;
    while (await FileSystemEntity.type(current, followLinks: false) ==
        FileSystemEntityType.notFound) {
      requireVision(missing.length < 64 && path.dirname(current) != current,
          'vision.storePath');
      missing.add(path.basename(current));
      current = path.dirname(current);
    }
    final resolved = await FileSystemEntity.isDirectory(current)
        ? await Directory(current).resolveSymbolicLinks()
        : await File(current).resolveSymbolicLinks();
    return path.joinAll([resolved, ...missing.reversed]);
  }

  void _validateLimits() => requireVision(
      limits.maxLedgerBytes > 0 &&
          limits.maxLedgerBytes <= 1048576 &&
          limits.maxAttempts > 0 &&
          limits.maxAttempts <= 2048 &&
          limits.maxCacheEntries > 0 &&
          limits.maxCacheEntries <= 64 &&
          limits.maxCacheBytes > 0 &&
          limits.maxCacheBytes <= 16777216 &&
          limits.maxEntryBytes > 0 &&
          limits.maxEntryBytes <= 1048576 &&
          limits.cacheTtl > Duration.zero &&
          limits.cacheTtl <= const Duration(days: 30),
      'vision.storeLimits');

  Future<void> _private(String target, String mode) async {
    if (Platform.isWindows) return;
    final result = await Process.run('/bin/chmod', [mode, target]);
    requireVision(result.exitCode == 0, 'vision.storePermissions');
  }

  String _nonce() => List.generate(16,
          (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'))
      .join();
}
