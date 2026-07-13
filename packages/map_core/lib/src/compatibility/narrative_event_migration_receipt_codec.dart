import 'dart:convert';

import 'package:meta/meta.dart' show immutable;

import '../models/narrative_event_wire.dart';
import '../operations/narrative_event_canonical_json.dart';
import 'narrative_event_migration_receipt.dart';

@immutable
sealed class NarrativeEventMigrationReceiptDecodeResult {
  NarrativeEventMigrationReceiptDecodeResult._(
    List<int> originalJsonBytes,
  ) : originalJsonBytes = List.unmodifiable(originalJsonBytes);

  factory NarrativeEventMigrationReceiptDecodeResult.decoded(
    NarrativeEventMigrationReceipt receipt,
    List<int> originalJsonBytes,
  ) = _DecodedNarrativeEventMigrationReceipt;

  factory NarrativeEventMigrationReceiptDecodeResult.unsupported(
    Object? rawReceiptJson,
    List<int> originalJsonBytes,
    List<String> diagnostics,
  ) = _UnsupportedNarrativeEventMigrationReceipt;

  factory NarrativeEventMigrationReceiptDecodeResult.invalid(
    Object? rawReceiptJson,
    List<int> originalJsonBytes,
    List<String> diagnostics,
  ) = _InvalidNarrativeEventMigrationReceipt;

  final List<int> originalJsonBytes;

  NarrativeEventMigrationReceipt? get receiptOrNull;
  Object? get rawReceiptJson;
  List<String> get diagnostics;

  T when<T>({
    required T Function(NarrativeEventMigrationReceipt receipt) decoded,
    required T Function(
      Object? raw,
      List<int> originalJsonBytes,
      List<String> diagnostics,
    ) unsupported,
    required T Function(
      Object? raw,
      List<int> originalJsonBytes,
      List<String> diagnostics,
    ) invalid,
  });

  Map<String, Object?> toJson() {
    final receipt = receiptOrNull;
    if (receipt == null) {
      throw StateError('Only a decoded migration receipt can be encoded.');
    }
    return receipt.toJson();
  }
}

final class _DecodedNarrativeEventMigrationReceipt
    extends NarrativeEventMigrationReceiptDecodeResult {
  _DecodedNarrativeEventMigrationReceipt(
    this.receipt,
    super.originalJsonBytes,
  ) : super._();

  final NarrativeEventMigrationReceipt receipt;

  @override
  NarrativeEventMigrationReceipt get receiptOrNull => receipt;

  @override
  Object? get rawReceiptJson => null;

  @override
  List<String> get diagnostics => const [];

  @override
  T when<T>({
    required T Function(NarrativeEventMigrationReceipt receipt) decoded,
    required T Function(
      Object? raw,
      List<int> originalJsonBytes,
      List<String> diagnostics,
    ) unsupported,
    required T Function(
      Object? raw,
      List<int> originalJsonBytes,
      List<String> diagnostics,
    ) invalid,
  }) =>
      decoded(receipt);
}

abstract base class _FailedNarrativeEventMigrationReceipt
    extends NarrativeEventMigrationReceiptDecodeResult {
  _FailedNarrativeEventMigrationReceipt(
    Object? rawReceiptJson,
    super.originalJsonBytes,
    List<String> diagnostics,
  )   : rawReceiptJson = _freezeJson(rawReceiptJson),
        diagnostics = List.unmodifiable(diagnostics),
        super._();

  @override
  NarrativeEventMigrationReceipt? get receiptOrNull => null;

  @override
  final Object? rawReceiptJson;

  @override
  final List<String> diagnostics;
}

final class _UnsupportedNarrativeEventMigrationReceipt
    extends _FailedNarrativeEventMigrationReceipt {
  _UnsupportedNarrativeEventMigrationReceipt(
    super.rawReceiptJson,
    super.originalJsonBytes,
    super.diagnostics,
  );

  @override
  T when<T>({
    required T Function(NarrativeEventMigrationReceipt receipt) decoded,
    required T Function(
      Object? raw,
      List<int> originalJsonBytes,
      List<String> diagnostics,
    ) unsupported,
    required T Function(
      Object? raw,
      List<int> originalJsonBytes,
      List<String> diagnostics,
    ) invalid,
  }) =>
      unsupported(rawReceiptJson, originalJsonBytes, diagnostics);
}

final class _InvalidNarrativeEventMigrationReceipt
    extends _FailedNarrativeEventMigrationReceipt {
  _InvalidNarrativeEventMigrationReceipt(
    super.rawReceiptJson,
    super.originalJsonBytes,
    super.diagnostics,
  );

  @override
  T when<T>({
    required T Function(NarrativeEventMigrationReceipt receipt) decoded,
    required T Function(
      Object? raw,
      List<int> originalJsonBytes,
      List<String> diagnostics,
    ) unsupported,
    required T Function(
      Object? raw,
      List<int> originalJsonBytes,
      List<String> diagnostics,
    ) invalid,
  }) =>
      invalid(rawReceiptJson, originalJsonBytes, diagnostics);
}

NarrativeEventMigrationReceiptDecodeResult
    decodeNarrativeEventMigrationReceiptStrict(List<int> jsonBytes) {
  String source;
  Object? raw;
  try {
    source = utf8.decode(jsonBytes);
  } on Object catch (error) {
    return NarrativeEventMigrationReceiptDecodeResult.invalid(
      null,
      jsonBytes,
      ['Migration receipt UTF-8 decode failed: $error'],
    );
  }

  late List<String> duplicateKeys;
  try {
    duplicateKeys = findDuplicateNarrativeEventJsonKeys(source);
  } on Object catch (error) {
    return NarrativeEventMigrationReceiptDecodeResult.invalid(
      null,
      jsonBytes,
      ['Migration receipt JSON scan failed: $error'],
    );
  }
  try {
    raw = jsonDecode(source);
  } on Object catch (error) {
    return NarrativeEventMigrationReceiptDecodeResult.invalid(
      null,
      jsonBytes,
      ['Migration receipt JSON decode failed: $error'],
    );
  }

  if (duplicateKeys.isNotEmpty) {
    return NarrativeEventMigrationReceiptDecodeResult.invalid(
      raw,
      jsonBytes,
      [
        for (final path in duplicateKeys)
          'Duplicate JSON key at $path is not valid I-JSON.',
      ],
    );
  }

  try {
    return NarrativeEventMigrationReceiptDecodeResult.decoded(
      NarrativeEventMigrationReceipt.fromJson(raw),
      jsonBytes,
    );
  } on NarrativeEventUnsupportedWireException catch (error) {
    return NarrativeEventMigrationReceiptDecodeResult.unsupported(
      raw,
      jsonBytes,
      [error.message.toString()],
    );
  } on NarrativeEventInvalidWireException catch (error) {
    return NarrativeEventMigrationReceiptDecodeResult.invalid(
      raw,
      jsonBytes,
      [error.message.toString()],
    );
  } on FormatException catch (error) {
    return NarrativeEventMigrationReceiptDecodeResult.invalid(
      raw,
      jsonBytes,
      [error.message.toString()],
    );
  } on ArgumentError catch (error) {
    return NarrativeEventMigrationReceiptDecodeResult.invalid(
      raw,
      jsonBytes,
      [error.message?.toString() ?? 'Invalid migration receipt invariant.'],
    );
  } on Object catch (error) {
    return NarrativeEventMigrationReceiptDecodeResult.invalid(
      raw,
      jsonBytes,
      ['Migration receipt invariant validation failed: $error'],
    );
  }
}

Object? _freezeJson(Object? value) {
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_freezeJson));
  }
  if (value is Map) {
    return Map<Object?, Object?>.unmodifiable({
      for (final entry in value.entries)
        _freezeJson(entry.key): _freezeJson(entry.value),
    });
  }
  return value;
}
