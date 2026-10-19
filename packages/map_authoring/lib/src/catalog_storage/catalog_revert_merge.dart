import 'dart:async';

import 'package:map_core/map_core.dart';

import '../support/authoring_fingerprint.dart';
import 'catalog_storage_store.dart';

final class CatalogRevertDelta {
  CatalogRevertDelta._(this.upserts, this.removals);
  final List<CatalogDefinitionUnit> upserts;
  final List<CatalogDefinitionKey> removals;

  static Future<CatalogRevertDelta> between({
    required CatalogSnapshot before,
    required CatalogSnapshot after,
    required CatalogSnapshot current,
  }) async {
    final upserts = <CatalogDefinitionUnit>[];
    final removals = <CatalogDefinitionKey>[];
    final oldIndex = StreamIterator(_entries(before));
    final newIndex = StreamIterator(_entries(after));
    try {
      var hasOld = await oldIndex.moveNext();
      var hasNew = await newIndex.moveNext();
      while (hasOld || hasNew) {
        final old = hasOld ? oldIndex.current : null;
        final next = hasNew ? newIndex.current : null;
        final order = old == null
            ? 1
            : next == null
                ? -1
                : old.key.compareTo(next.key);
        final key = order <= 0 ? old!.key : next!.key;
        final desired = order < 0 ? null : next;
        final changed = order != 0 || old!.reference != next!.reference;
        if (changed && key.kind != CatalogDefinitionKind.workspaceState) {
          final actual = await current.indexEntry(key);
          if (actual?.reference != desired?.reference) {
            if (desired == null) {
              removals.add(key);
            } else {
              upserts.add((await after.lookup(key))!);
            }
          }
        }
        if (order <= 0) hasOld = await oldIndex.moveNext();
        if (order >= 0) hasNew = await newIndex.moveNext();
      }
    } finally {
      await oldIndex.cancel();
      await newIndex.cancel();
    }
    return CatalogRevertDelta._(
        List.unmodifiable(upserts), List.unmodifiable(removals));
  }

  static Stream<CatalogIndexEntry> _entries(CatalogSnapshot snapshot) async* {
    String? cursor;
    do {
      final page = await snapshot.page(
          limit: snapshot.limits.indexPageSize, cursor: cursor);
      yield* Stream.fromIterable(page.items);
      cursor = page.nextCursor;
    } while (cursor != null);
  }
}

final class CatalogRevertMergeAttestation {
  CatalogRevertMergeAttestation._(
      {required this.currentRoot,
      required this.targetBeforeRoot,
      required this.targetAfterRoot,
      required this.resultRoot,
      required bool verified})
      : _verified = verified;

  final CatalogObjectReference currentRoot;
  final CatalogObjectReference targetBeforeRoot;
  final CatalogObjectReference targetAfterRoot;
  final CatalogObjectReference resultRoot;
  final bool _verified;
  bool get verified => _verified;

  static Future<CatalogRevertMergeAttestation> verify({
    required CatalogSnapshot current,
    required CatalogSnapshot targetBefore,
    required CatalogSnapshot targetAfter,
    required CatalogSnapshot result,
  }) async {
    await current.admitIndex();
    final delta = await CatalogRevertDelta.between(
        before: targetBefore, after: targetAfter, current: current);
    final state = await result.lookup(CatalogDefinitionKey(
        CatalogDefinitionKind.workspaceState, 'workspace'));
    if (state == null ||
        state.references.isNotEmpty ||
        state.payload.length != 2 ||
        state.payload['id'] != 'workspace' ||
        state.payload['fingerprint'] is! String ||
        !RegExp(r'^sha256:[0-9a-f]{64}$')
            .hasMatch(state.payload['fingerprint']! as String)) {
      throw const FormatException('catalog.revert: invalid workspace state');
    }
    final expected = await current
        .patch(upserts: [...delta.upserts, state], removals: delta.removals);
    if (expected.root != result.root || current.root == result.root) {
      throw const FormatException(
          'catalog.revert: result differs from canonical unit merge');
    }
    return CatalogRevertMergeAttestation._(
        currentRoot: current.root,
        targetBeforeRoot: targetBefore.root,
        targetAfterRoot: targetAfter.root,
        resultRoot: result.root,
        verified: true);
  }

  Future<CatalogRevertMergeAttestation> reverify(
          CatalogStorageStore store) async =>
      verify(
          current: (await store.openRoot(currentRoot)).snapshot,
          targetBefore: (await store.openRoot(targetBeforeRoot)).snapshot,
          targetAfter: (await store.openRoot(targetAfterRoot)).snapshot,
          result: (await store.openRoot(resultRoot)).snapshot);

  String get currentHeadRevision => _headRevision(currentRoot);
  String get targetBeforeHeadRevision => _headRevision(targetBeforeRoot);
  String get targetAfterHeadRevision => _headRevision(targetAfterRoot);
  String get resultHeadRevision => _headRevision(resultRoot);

  static String _headRevision(CatalogObjectReference root) =>
      computeAuthoringBytesFingerprint(CatalogStorageStore.encodeHead(root),
          logicalName: CatalogStorageStore.headStorageKey);

  Map<String, Object?> toJson() => {
        'version': 1,
        'currentRoot': currentRoot.toJson(),
        'targetBeforeRoot': targetBeforeRoot.toJson(),
        'targetAfterRoot': targetAfterRoot.toJson(),
        'resultRoot': resultRoot.toJson()
      };

  factory CatalogRevertMergeAttestation.fromJournalJson(
      Map<String, dynamic> json) {
    final value = CatalogRevertMergeAttestation._(
        currentRoot: CatalogObjectReference.fromJson(
            Map<String, Object?>.from(json['currentRoot'] as Map)),
        targetBeforeRoot: CatalogObjectReference.fromJson(
            Map<String, Object?>.from(json['targetBeforeRoot'] as Map)),
        targetAfterRoot: CatalogObjectReference.fromJson(
            Map<String, Object?>.from(json['targetAfterRoot'] as Map)),
        resultRoot: CatalogObjectReference.fromJson(
            Map<String, Object?>.from(json['resultRoot'] as Map)),
        verified: false);
    if (canonicalAuthoringJson(json) !=
        canonicalAuthoringJson(value.toJson())) {
      throw const FormatException('catalog.revert: invalid merge attestation');
    }
    return value;
  }
}
