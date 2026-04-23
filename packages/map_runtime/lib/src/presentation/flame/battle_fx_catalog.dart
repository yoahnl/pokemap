class BattleFxAssetSpec {
  const BattleFxAssetSpec({
    required this.effectId,
    required this.assetKey,
    required this.sourceFileName,
  });

  final String effectId;
  final String assetKey;
  final String sourceFileName;
}

final class BattleFxCatalog {
  static const Map<String, BattleFxAssetSpec> byEffectId =
      <String, BattleFxAssetSpec>{
    'angry': BattleFxAssetSpec(
      effectId: 'angry',
      assetKey: 'packages/map_runtime/assets/fx/angry.png',
      sourceFileName: 'angry.png',
    ),
    'blackwisp': BattleFxAssetSpec(
      effectId: 'blackwisp',
      assetKey: 'packages/map_runtime/assets/fx/blackwisp.png',
      sourceFileName: 'blackwisp.png',
    ),
    'bluefireball': BattleFxAssetSpec(
      effectId: 'bluefireball',
      assetKey: 'packages/map_runtime/assets/fx/bluefireball.png',
      sourceFileName: 'bluefireball.png',
    ),
    'bone': BattleFxAssetSpec(
      effectId: 'bone',
      assetKey: 'packages/map_runtime/assets/fx/bone.png',
      sourceFileName: 'bone.png',
    ),
    'bottombite': BattleFxAssetSpec(
      effectId: 'bottombite',
      assetKey: 'packages/map_runtime/assets/fx/bottombite.png',
      sourceFileName: 'bottombite.png',
    ),
    'caltrop': BattleFxAssetSpec(
      effectId: 'caltrop',
      assetKey: 'packages/map_runtime/assets/fx/caltrop.png',
      sourceFileName: 'caltrop.png',
    ),
    'electroball': BattleFxAssetSpec(
      effectId: 'electroball',
      assetKey: 'packages/map_runtime/assets/fx/electroball.png',
      sourceFileName: 'electroball.png',
    ),
    'energyball': BattleFxAssetSpec(
      effectId: 'energyball',
      assetKey: 'packages/map_runtime/assets/fx/energyball.png',
      sourceFileName: 'energyball.png',
    ),
    'feather': BattleFxAssetSpec(
      effectId: 'feather',
      assetKey: 'packages/map_runtime/assets/fx/feather.png',
      sourceFileName: 'feather.png',
    ),
    'fireball': BattleFxAssetSpec(
      effectId: 'fireball',
      assetKey: 'packages/map_runtime/assets/fx/fireball.png',
      sourceFileName: 'fireball.png',
    ),
    'fist': BattleFxAssetSpec(
      effectId: 'fist',
      assetKey: 'packages/map_runtime/assets/fx/fist.png',
      sourceFileName: 'fist.png',
    ),
    'fist1': BattleFxAssetSpec(
      effectId: 'fist1',
      assetKey: 'packages/map_runtime/assets/fx/fist1.png',
      sourceFileName: 'fist1.png',
    ),
    'foot': BattleFxAssetSpec(
      effectId: 'foot',
      assetKey: 'packages/map_runtime/assets/fx/foot.png',
      sourceFileName: 'foot.png',
    ),
    'flareball': BattleFxAssetSpec(
      effectId: 'flareball',
      assetKey: 'packages/map_runtime/assets/fx/flareball.png',
      sourceFileName: 'flareball.png',
    ),
    'gear': BattleFxAssetSpec(
      effectId: 'gear',
      assetKey: 'packages/map_runtime/assets/fx/gear.png',
      sourceFileName: 'gear.png',
    ),
    'greenmetal1': BattleFxAssetSpec(
      effectId: 'greenmetal1',
      assetKey: 'packages/map_runtime/assets/fx/greenmetal1.png',
      sourceFileName: 'greenmetal1.png',
    ),
    'greenmetal2': BattleFxAssetSpec(
      effectId: 'greenmetal2',
      assetKey: 'packages/map_runtime/assets/fx/greenmetal2.png',
      sourceFileName: 'greenmetal2.png',
    ),
    'heart': BattleFxAssetSpec(
      effectId: 'heart',
      assetKey: 'packages/map_runtime/assets/fx/heart.png',
      sourceFileName: 'heart.png',
    ),
    'icicle': BattleFxAssetSpec(
      effectId: 'icicle',
      assetKey: 'packages/map_runtime/assets/fx/icicle.png',
      sourceFileName: 'icicle.png',
    ),
    'icicle-pink': BattleFxAssetSpec(
      effectId: 'icicle-pink',
      assetKey: 'packages/map_runtime/assets/fx/icicle-pink.png',
      sourceFileName: 'icicle-pink.png',
    ),
    'iceball': BattleFxAssetSpec(
      effectId: 'iceball',
      assetKey: 'packages/map_runtime/assets/fx/iceball.png',
      sourceFileName: 'iceball.png',
    ),
    'impact': BattleFxAssetSpec(
      effectId: 'impact',
      assetKey: 'packages/map_runtime/assets/fx/impact.png',
      sourceFileName: 'impact.png',
    ),
    'leaf1': BattleFxAssetSpec(
      effectId: 'leaf1',
      assetKey: 'packages/map_runtime/assets/fx/leaf1.png',
      sourceFileName: 'leaf1.png',
    ),
    'leaf2': BattleFxAssetSpec(
      effectId: 'leaf2',
      assetKey: 'packages/map_runtime/assets/fx/leaf2.png',
      sourceFileName: 'leaf2.png',
    ),
    'leftchop': BattleFxAssetSpec(
      effectId: 'leftchop',
      assetKey: 'packages/map_runtime/assets/fx/leftchop.png',
      sourceFileName: 'leftchop.png',
    ),
    'leftclaw': BattleFxAssetSpec(
      effectId: 'leftclaw',
      assetKey: 'packages/map_runtime/assets/fx/leftclaw.png',
      sourceFileName: 'leftclaw.png',
    ),
    'leftslash': BattleFxAssetSpec(
      effectId: 'leftslash',
      assetKey: 'packages/map_runtime/assets/fx/leftslash.png',
      sourceFileName: 'leftslash.png',
    ),
    'lightning': BattleFxAssetSpec(
      effectId: 'lightning',
      assetKey: 'packages/map_runtime/assets/fx/lightning.png',
      sourceFileName: 'lightning.png',
    ),
    'mistball': BattleFxAssetSpec(
      effectId: 'mistball',
      assetKey: 'packages/map_runtime/assets/fx/mistball.png',
      sourceFileName: 'mistball.png',
    ),
    'moon': BattleFxAssetSpec(
      effectId: 'moon',
      assetKey: 'packages/map_runtime/assets/fx/moon.png',
      sourceFileName: 'moon.png',
    ),
    'mudwisp': BattleFxAssetSpec(
      effectId: 'mudwisp',
      assetKey: 'packages/map_runtime/assets/fx/mudwisp.png',
      sourceFileName: 'mudwisp.png',
    ),
    'petal': BattleFxAssetSpec(
      effectId: 'petal',
      assetKey: 'packages/map_runtime/assets/fx/petal.png',
      sourceFileName: 'petal.png',
    ),
    'pointer': BattleFxAssetSpec(
      effectId: 'pointer',
      assetKey: 'packages/map_runtime/assets/fx/pointer.png',
      sourceFileName: 'pointer.png',
    ),
    'poisoncaltrop': BattleFxAssetSpec(
      effectId: 'poisoncaltrop',
      assetKey: 'packages/map_runtime/assets/fx/poisoncaltrop.png',
      sourceFileName: 'poisoncaltrop.png',
    ),
    'poisonwisp': BattleFxAssetSpec(
      effectId: 'poisonwisp',
      assetKey: 'packages/map_runtime/assets/fx/poisonwisp.png',
      sourceFileName: 'poisonwisp.png',
    ),
    'pokeball': BattleFxAssetSpec(
      effectId: 'pokeball',
      assetKey: 'packages/map_runtime/assets/fx/pokeball.png',
      sourceFileName: 'pokeball.png',
    ),
    'rainbow': BattleFxAssetSpec(
      effectId: 'rainbow',
      assetKey: 'packages/map_runtime/assets/fx/rainbow.png',
      sourceFileName: 'rainbow.png',
    ),
    'rightchop': BattleFxAssetSpec(
      effectId: 'rightchop',
      assetKey: 'packages/map_runtime/assets/fx/rightchop.png',
      sourceFileName: 'rightchop.png',
    ),
    'rightclaw': BattleFxAssetSpec(
      effectId: 'rightclaw',
      assetKey: 'packages/map_runtime/assets/fx/rightclaw.png',
      sourceFileName: 'rightclaw.png',
    ),
    'rightslash': BattleFxAssetSpec(
      effectId: 'rightslash',
      assetKey: 'packages/map_runtime/assets/fx/rightslash.png',
      sourceFileName: 'rightslash.png',
    ),
    'rock1': BattleFxAssetSpec(
      effectId: 'rock1',
      assetKey: 'packages/map_runtime/assets/fx/rock1.png',
      sourceFileName: 'rock1.png',
    ),
    'rock2': BattleFxAssetSpec(
      effectId: 'rock2',
      assetKey: 'packages/map_runtime/assets/fx/rock2.png',
      sourceFileName: 'rock2.png',
    ),
    'rock3': BattleFxAssetSpec(
      effectId: 'rock3',
      assetKey: 'packages/map_runtime/assets/fx/rock3.png',
      sourceFileName: 'rock3.png',
    ),
    'rocks': BattleFxAssetSpec(
      effectId: 'rocks',
      assetKey: 'packages/map_runtime/assets/fx/rocks.png',
      sourceFileName: 'rocks.png',
    ),
    'shadowball': BattleFxAssetSpec(
      effectId: 'shadowball',
      assetKey: 'packages/map_runtime/assets/fx/shadowball.png',
      sourceFileName: 'shadowball.png',
    ),
    'shell': BattleFxAssetSpec(
      effectId: 'shell',
      assetKey: 'packages/map_runtime/assets/fx/shell.png',
      sourceFileName: 'shell.png',
    ),
    'shine': BattleFxAssetSpec(
      effectId: 'shine',
      assetKey: 'packages/map_runtime/assets/fx/shine.png',
      sourceFileName: 'shine.png',
    ),
    'stare': BattleFxAssetSpec(
      effectId: 'stare',
      assetKey: 'packages/map_runtime/assets/fx/stare.png',
      sourceFileName: 'stare.png',
    ),
    'sword': BattleFxAssetSpec(
      effectId: 'sword',
      assetKey: 'packages/map_runtime/assets/fx/sword.png',
      sourceFileName: 'sword.png',
    ),
    'tatsugiri': BattleFxAssetSpec(
      effectId: 'tatsugiri',
      assetKey: 'packages/map_runtime/assets/fx/tatsugiri.png',
      sourceFileName: 'tatsugiri.png',
    ),
    'topbite': BattleFxAssetSpec(
      effectId: 'topbite',
      assetKey: 'packages/map_runtime/assets/fx/topbite.png',
      sourceFileName: 'topbite.png',
    ),
    'waterwisp': BattleFxAssetSpec(
      effectId: 'waterwisp',
      assetKey: 'packages/map_runtime/assets/fx/waterwisp.png',
      sourceFileName: 'waterwisp.png',
    ),
    'web': BattleFxAssetSpec(
      effectId: 'web',
      assetKey: 'packages/map_runtime/assets/fx/web.png',
      sourceFileName: 'web.png',
    ),
    'wisp': BattleFxAssetSpec(
      effectId: 'wisp',
      assetKey: 'packages/map_runtime/assets/fx/wisp.png',
      sourceFileName: 'wisp.png',
    ),
    'z-symbol': BattleFxAssetSpec(
      effectId: 'z-symbol',
      assetKey: 'packages/map_runtime/assets/fx/z-symbol.png',
      sourceFileName: 'z-symbol.png',
    ),
  };

  static bool contains(String effectId) => byEffectId.containsKey(effectId);

  static BattleFxAssetSpec require(String effectId) {
    final spec = byEffectId[effectId];
    if (spec == null) {
      throw StateError('Unknown battle FX effectId: $effectId');
    }
    return spec;
  }

  static Iterable<String> get allEffectIds => byEffectId.keys;
}
