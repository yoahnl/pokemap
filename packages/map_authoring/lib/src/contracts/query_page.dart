import 'json_contract_support.dart';

final class AuthoringQueryPage {
  AuthoringQueryPage({
    required this.snapshotRevision,
    required Iterable<Map<String, Object?>> items,
    required this.totalAvailable,
    this.nextCursor,
  }) : items = List.unmodifiable([
          for (final item in items)
            freezeContractJsonObject(item, field: 'items'),
        ]) {
    if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(snapshotRevision)) {
      throw ArgumentError.value(
        snapshotRevision,
        'snapshotRevision',
        'must be a lowercase SHA-256 fingerprint',
      );
    }
    if (totalAvailable < this.items.length) {
      throw ArgumentError.value(
        totalAvailable,
        'totalAvailable',
        'cannot be smaller than returned items',
      );
    }
  }

  factory AuthoringQueryPage.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _reservedKeys);
    final rawItems = json['items'];
    final rawReturned = json['returned'];
    if (rawItems is! List || rawReturned is! int) {
      throw const FormatException(
        'items must be a list and returned must be an integer',
      );
    }
    try {
      final page = AuthoringQueryPage(
        snapshotRevision: requireContractString(
          json['snapshotRevision'],
          'snapshotRevision',
        ),
        items: rawItems.map((item) {
          if (item is! Map) {
            throw const FormatException('query item must be an object');
          }
          return Map<String, Object?>.from(item);
        }),
        totalAvailable: json['totalAvailable'] is int
            ? json['totalAvailable']! as int
            : throw const FormatException(
                'totalAvailable must be an integer',
              ),
        nextCursor: readOptionalContractString(
          json['nextCursor'],
          'nextCursor',
        ),
      );
      if (rawReturned != page.returned) {
        throw const FormatException(
          'returned must equal the number of query items',
        );
      }
      return page;
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  static const Set<String> _reservedKeys = {
    'snapshotRevision',
    'items',
    'returned',
    'totalAvailable',
    'nextCursor',
  };

  final String snapshotRevision;
  final List<Map<String, Object?>> items;
  final int totalAvailable;
  final String? nextCursor;

  int get returned => items.length;

  Map<String, Object?> toJson() => {
        'snapshotRevision': snapshotRevision,
        'items': items,
        'returned': returned,
        'totalAvailable': totalAvailable,
        if (nextCursor != null) 'nextCursor': nextCursor,
      };
}
