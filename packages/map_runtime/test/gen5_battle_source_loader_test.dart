import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/infrastructure/gen5_battle_source_loader.dart';

void main() {
  late Map<String, Uint8List> inventory;
  late List<String> opened;
  late Gen5BattleSourceBundle bundle;
  late Gen5BattleSourceBinding binding;

  setUp(() {
    inventory = {};
    opened = [];
    bundle = Gen5BattleSourceBundle(
      species: 'syntheticmon',
      nationalDex: 25,
      release: 'synthetic-release',
      sourceRepository: 'fuddlesworth/pokebw2',
      sourceRevision: 'a' * 40,
      sourceDirectory: 'res/pokemon/syntheticmon',
      reconstruction: 'unverified',
      redistributionStatus: 'unverified',
      assets: {
        for (var i = 0; i < gen5BattleBundleAssetNames.length; i++)
          gen5BattleBundleAssetNames[i]: Uint8List.fromList([i + 1]),
      },
    );
    binding = Gen5BattleSourceBinding.fromBundle(
      projectSpeciesId: 'local-e\u0301',
      projectNationalDex: 25,
      bundle: bundle,
    );
  });

  Future<Stream<List<int>>?> openAsset(String path) async {
    opened.add(path);
    final bytes = inventory[path];
    return bytes == null ? null : Stream.value(bytes);
  }

  Future<Gen5BattleSourceBundle?> load({
    String? hash,
    String speciesId = 'local-e\u0301',
    int dex = 25,
    bool Function()? isCurrent,
    Future<Stream<List<int>>?> Function(String)? open,
  }) => loadRuntimeGen5BattleSource(
    openAsset: open ?? openAsset,
    projectSpeciesId: speciesId,
    projectNationalDex: dex,
    expectedBindingSha256: hash,
    isCurrent: isCurrent,
  );

  void addSource() {
    inventory[binding.bindingPath] = binding.encode();
    inventory[binding.bundlePath] = bundle.encode();
  }

  test('loads bound assets from the host inventory', () async {
    addSource();
    final loaded = await load(
      hash: sha256.convert(binding.encode()).toString(),
    );
    expect(loaded!.species, 'syntheticmon');
    expect(loaded.assets.keys.toSet(), gen5BattleBundleAssetNames.toSet());
    for (final name in gen5BattleBundleAssetNames) {
      expect(loaded.assets[name], bundle.assets[name]);
    }
    expect(opened, [binding.bindingPath, binding.bundlePath]);
  });

  test('does not open optional data without an inventory digest', () async {
    addSource();
    expect(await load(), isNull);
    expect(opened, isEmpty);
  });

  test('rejects missing, modified, or wrongly identified bound data', () async {
    final hash = sha256.convert(binding.encode()).toString();
    await expectLater(load(hash: hash), throwsFormatException);
    inventory[binding.bindingPath] = binding.encode();
    await expectLater(load(hash: hash), throwsFormatException);
    inventory[binding.bundlePath] = bundle.encode();
    await expectLater(load(hash: '0' * 64), throwsFormatException);
    await expectLater(load(hash: hash, dex: 26), throwsFormatException);
    final damaged = Uint8List.fromList(bundle.encode());
    damaged[damaged.length - 2] ^= 1;
    inventory[binding.bundlePath] = damaged;
    await expectLater(load(hash: hash), throwsFormatException);
  });

  test('stops reading an oversized binding before later chunks', () async {
    var chunksRead = 0;
    Stream<List<int>> oversized() async* {
      chunksRead++;
      yield Uint8List(gen5BattleSourceBindingMaxBytes);
      chunksRead++;
      yield [0];
      chunksRead++;
      yield [0];
    }

    await expectLater(
      load(hash: '0' * 64, open: (_) async => oversized()),
      throwsFormatException,
    );
    expect(chunksRead, 2);
  });

  test(
    'stops before opening data when the load is no longer current',
    () async {
      await expectLater(
        load(hash: '0' * 64, isCurrent: () => false),
        throwsStateError,
      );
      expect(opened, isEmpty);
    },
  );

  test('stops consuming the stream when the load becomes stale', () async {
    var current = true;
    var chunksRead = 0;
    Stream<List<int>> stale() async* {
      chunksRead++;
      yield [0];
      current = false;
      chunksRead++;
      yield [0];
      chunksRead++;
      yield [0];
    }

    await expectLater(
      load(
        hash: '0' * 64,
        isCurrent: () => current,
        open: (_) async => stale(),
      ),
      throwsStateError,
    );
    expect(chunksRead, 2);
  });
}
