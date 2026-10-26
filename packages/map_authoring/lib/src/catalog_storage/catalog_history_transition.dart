import 'package:map_core/map_core.dart';

import '../support/authoring_fingerprint.dart';
import 'catalog_history_compatibility.dart';
import 'catalog_storage_store.dart';

final class CatalogHistoryTransitionAttestation {
  CatalogHistoryTransitionAttestation._({
    required this.originalBeforeRoot,
    required this.originalAfterRoot,
    required this.effectiveBeforeRoot,
    required this.effectiveAfterRoot,
    required this.conversions,
    required bool verified,
  }) : _verified = verified;

  final CatalogObjectReference originalBeforeRoot;
  final CatalogObjectReference originalAfterRoot;
  final CatalogObjectReference effectiveBeforeRoot;
  final CatalogObjectReference effectiveAfterRoot;
  final List<CatalogHistoryRootConversion> conversions;
  final bool _verified;
  bool get verified => _verified;

  static Future<CatalogHistoryTransitionAttestation> verify({
    required CatalogStorageStore store,
    required CatalogObjectReference originalBeforeRoot,
    required CatalogObjectReference originalAfterRoot,
    required CatalogObjectReference effectiveBeforeRoot,
    required CatalogObjectReference effectiveAfterRoot,
    required Iterable<CatalogHistoryRootConversion> conversions,
  }) async {
    final pending = CatalogHistoryTransitionAttestation._(
      originalBeforeRoot: originalBeforeRoot,
      originalAfterRoot: originalAfterRoot,
      effectiveBeforeRoot: effectiveBeforeRoot,
      effectiveAfterRoot: effectiveAfterRoot,
      conversions: List.unmodifiable(conversions),
      verified: false,
    );
    final values = pending._boundConversions();
    for (final conversion in values) {
      await store.requireHistoryConversion(conversion);
    }
    return CatalogHistoryTransitionAttestation._(
      originalBeforeRoot: originalBeforeRoot,
      originalAfterRoot: originalAfterRoot,
      effectiveBeforeRoot: effectiveBeforeRoot,
      effectiveAfterRoot: effectiveAfterRoot,
      conversions: values,
      verified: true,
    );
  }

  List<CatalogHistoryRootConversion> _boundConversions() {
    final values = conversions.toList()
      ..sort((a, b) => a.source.sha256.compareTo(b.source.sha256));
    final bySource = {for (final value in values) value.source: value};
    if (values.isEmpty ||
        values.length > 2 ||
        bySource.length != values.length) {
      throw const FormatException(
          'catalog.history: invalid conversion inventory');
    }
    final used = <CatalogObjectReference>{};
    for (final pair in [
      (originalBeforeRoot, effectiveBeforeRoot),
      (originalAfterRoot, effectiveAfterRoot),
    ]) {
      if (pair.$1 == pair.$2) continue;
      final conversion = bySource[pair.$1];
      if (conversion == null || conversion.target != pair.$2) {
        throw const FormatException('catalog.history: unbound converted root');
      }
      used.add(pair.$1);
    }
    if (used.length != values.length) {
      throw const FormatException('catalog.history: extraneous conversion');
    }
    return List.unmodifiable(values);
  }

  Future<CatalogHistoryTransitionAttestation> reverify(
      CatalogStorageStore store,
      {bool allowPreparation = false}) async {
    final values = _boundConversions();
    if (allowPreparation) {
      for (final conversion in values) {
        await CatalogHistoryCompatibility.recover(
            store: store, conversion: conversion);
      }
    }
    return verify(
      store: store,
      originalBeforeRoot: originalBeforeRoot,
      originalAfterRoot: originalAfterRoot,
      effectiveBeforeRoot: effectiveBeforeRoot,
      effectiveAfterRoot: effectiveAfterRoot,
      conversions: values,
    );
  }

  String get originalBeforeRevision => _headRevision(originalBeforeRoot);
  String get originalAfterRevision => _headRevision(originalAfterRoot);
  String get effectiveBeforeRevision => _headRevision(effectiveBeforeRoot);
  String get effectiveAfterRevision => _headRevision(effectiveAfterRoot);

  static String _headRevision(CatalogObjectReference root) =>
      computeAuthoringBytesFingerprint(CatalogStorageStore.encodeHead(root),
          logicalName: CatalogStorageStore.headStorageKey);

  Map<String, Object?> toJson() => {
        'version': 1,
        'originalBeforeRoot': originalBeforeRoot.toJson(),
        'originalAfterRoot': originalAfterRoot.toJson(),
        'effectiveBeforeRoot': effectiveBeforeRoot.toJson(),
        'effectiveAfterRoot': effectiveAfterRoot.toJson(),
        'conversions': [for (final value in conversions) value.toJson()],
      };

  factory CatalogHistoryTransitionAttestation.fromJournalJson(
      Map<String, dynamic> json) {
    try {
      if (json.length != 6 ||
          json['version'] != 1 ||
          json['conversions'] is! List ||
          (json['conversions'] as List).isEmpty ||
          (json['conversions'] as List).length > 2) {
        throw const FormatException(
            'catalog.history: invalid transition proof');
      }
      CatalogObjectReference root(String field) =>
          CatalogObjectReference.fromJson(
              Map<String, Object?>.from(json[field] as Map));
      final value = CatalogHistoryTransitionAttestation._(
        originalBeforeRoot: root('originalBeforeRoot'),
        originalAfterRoot: root('originalAfterRoot'),
        effectiveBeforeRoot: root('effectiveBeforeRoot'),
        effectiveAfterRoot: root('effectiveAfterRoot'),
        conversions: List.unmodifiable((json['conversions'] as List).map(
            (item) => CatalogHistoryRootConversion.fromJson(
                Map<String, Object?>.from(item as Map)))),
        verified: false,
      );
      final sorted = value._boundConversions();
      if (canonicalAuthoringJson(
                  sorted.map((item) => item.toJson()).toList()) !=
              canonicalAuthoringJson(json['conversions']) ||
          canonicalAuthoringJson(json) !=
              canonicalAuthoringJson(value.toJson())) {
        throw const FormatException(
            'catalog.history: invalid transition proof');
      }
      return value;
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException('catalog.history: invalid transition proof');
    }
  }
}
