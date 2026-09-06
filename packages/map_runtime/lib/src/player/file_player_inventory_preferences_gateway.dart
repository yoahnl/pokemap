import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'player_inventory_preferences_gateway.dart';

final class FilePlayerInventoryPreferencesGateway
    implements PlayerInventoryPreferencesGateway {
  FilePlayerInventoryPreferencesGateway({required Directory directory})
      : _directoryProvider = (() async => directory);

  FilePlayerInventoryPreferencesGateway.lazy({
    required Future<Directory> Function() directoryProvider,
  }) : _directoryProvider = directoryProvider;

  final Future<Directory> Function() _directoryProvider;

  @override
  Future<Set<String>> load(String gameId) async {
    final file = await _file(gameId);
    if (!await file.exists()) return const <String>{};
    if (await file.length() > 2097152) {
      throw const FormatException('Inventory preferences are too large.');
    }
    final data = jsonDecode(await file.readAsString());
    if (data is! Map<String, dynamic> ||
        data['schemaVersion'] != 1 ||
        data['gameId'] != gameId ||
        data['favoriteItemIds'] is! List) {
      throw const FormatException('Invalid inventory preferences.');
    }
    final items = data['favoriteItemIds'] as List;
    if (items.length > 4096 ||
        items.any((item) => item is! String || !_validItemId(item))) {
      throw const FormatException('Invalid favorite item identifiers.');
    }
    return Set<String>.unmodifiable(items.cast<String>());
  }

  @override
  Future<void> save(String gameId, Set<String> favoriteItemIds) async {
    if (favoriteItemIds.length > 4096 ||
        favoriteItemIds.any((item) => !_validItemId(item))) {
      throw const FormatException('Invalid favorite item identifiers.');
    }
    final items = favoriteItemIds.toList()..sort();
    final file = await _file(gameId);
    await file.parent.create(recursive: true);
    final temporaryDirectory = await file.parent.createTemp('.inventory-');
    try {
      final temporaryFile =
          File(p.join(temporaryDirectory.path, 'preferences'));
      await temporaryFile.writeAsString(
        jsonEncode({
          'schemaVersion': 1,
          'gameId': gameId,
          'favoriteItemIds': items,
        }),
        flush: true,
      );
      await temporaryFile.rename(file.path);
    } finally {
      await temporaryDirectory.delete(recursive: true);
    }
  }

  Future<File> _file(String gameId) async {
    final encoded = base64Url.encode(utf8.encode(gameId)).replaceAll('=', '');
    if (gameId.trim().isEmpty || encoded.length > 200) {
      throw const FormatException('Invalid game identifier.');
    }
    final directory = await _directoryProvider();
    return File(p.join(directory.path, '$encoded.json'));
  }

  static bool _validItemId(String itemId) =>
      itemId.trim().isNotEmpty && itemId.length <= 256;
}
