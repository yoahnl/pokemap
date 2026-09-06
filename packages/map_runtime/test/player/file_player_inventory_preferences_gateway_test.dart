import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  late Directory directory;
  late FilePlayerInventoryPreferencesGateway gateway;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('inventory-preferences-');
    gateway = FilePlayerInventoryPreferencesGateway(directory: directory);
  });

  tearDown(() => directory.delete(recursive: true));

  test('round trips favorites per game across gateway instances', () async {
    expect(await gateway.load('game-a'), isEmpty);
    await gateway.save('game-a', {'potion', 'antidote'});
    await gateway.save('game-b', {'escape-rope'});
    final reopened =
        FilePlayerInventoryPreferencesGateway(directory: directory);
    expect(await reopened.load('game-a'), {'potion', 'antidote'});
    expect(await reopened.load('game-b'), {'escape-rope'});
    await reopened.save('game-a', {});
    expect(await gateway.load('game-a'), isEmpty);
    expect(await gateway.load('game-b'), {'escape-rope'});
    expect(await directory.list().length, 2);
  });

  test('game identifiers cannot escape the preferences directory', () async {
    const gameId = '../../un jeu/é';
    await gateway.save(gameId, {'potion'});
    expect(await gateway.load(gameId), {'potion'});
    final file = (await directory.list().toList()).single;
    expect(file.parent.path, directory.path);
  });

  test('invalid or excessive favorites preserve the last committed file',
      () async {
    await gateway.save('game', {'potion'});
    for (final favorites in <Set<String>>[
      {''},
      {'x' * 257},
      {for (var index = 0; index < 4097; index++) 'item-$index'},
    ]) {
      await expectLater(gateway.save('game', favorites), throwsFormatException);
      expect(await gateway.load('game'), {'potion'});
    }
    expect(await directory.list().length, 1);
  });

  test('lazy directory resolution happens at load time', () async {
    var calls = 0;
    final lazy = FilePlayerInventoryPreferencesGateway.lazy(
      directoryProvider: () async {
        calls++;
        return directory;
      },
    );
    expect(calls, 0);
    await lazy.load('game');
    expect(calls, 1);
  });

  test('corrupt or unsupported preferences are rejected without overwriting',
      () async {
    await gateway.save('game', {'potion'});
    final file = (await directory.list().toList()).single as File;
    for (final content in [
      '{',
      jsonEncode({
        'schemaVersion': 2,
        'gameId': 'game',
        'favoriteItemIds': ['potion']
      }),
      jsonEncode({
        'schemaVersion': 1,
        'gameId': 'other',
        'favoriteItemIds': ['potion']
      }),
      jsonEncode({
        'schemaVersion': 1,
        'gameId': 'game',
        'favoriteItemIds': [7]
      }),
    ]) {
      await file.writeAsString(content);
      await expectLater(gateway.load('game'), throwsFormatException);
      expect(await file.readAsString(), content);
    }
  });
}
