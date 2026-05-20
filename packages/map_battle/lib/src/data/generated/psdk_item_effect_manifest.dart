/// Generated PSDK item effect manifest.
///
/// Source: `pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects`
/// plus local held-item checks currently modeled outside PSDK item effects
/// (weather rocks, Terrain Extender and Loaded Dice).
final psdkItemEffectManifest = _buildPsdkItemEffectManifest();

enum PsdkItemPortStatus {
  ported,
  partial,
  missing,
  outOfScope,
}

enum PsdkItemEffectBatch {
  damageTypeStatModifiers,
  berries,
  focusEjectChoiceOrb,
  weatherTerrainField,
  heldItemLifecycleConsumption,
}

extension PsdkItemEffectBatchLabel on PsdkItemEffectBatch {
  String get label {
    return switch (this) {
      PsdkItemEffectBatch.damageTypeStatModifiers =>
        'damage/type/stat modifiers',
      PsdkItemEffectBatch.berries => 'berries',
      PsdkItemEffectBatch.focusEjectChoiceOrb => 'focus/eject/choice/orb',
      PsdkItemEffectBatch.weatherTerrainField => 'weather/terrain/field',
      PsdkItemEffectBatch.heldItemLifecycleConsumption =>
        'held-item lifecycle and consumption',
    };
  }
}

final class PsdkItemEffectManifestEntry {
  const PsdkItemEffectManifestEntry({
    required this.itemId,
    required this.rubyPath,
    required this.status,
    required this.batch,
    this.dartEffect,
  });

  final String itemId;
  final String rubyPath;
  final PsdkItemPortStatus status;
  final PsdkItemEffectBatch batch;
  final String? dartEffect;
}

List<PsdkItemEffectManifestEntry> _buildPsdkItemEffectManifest() {
  final entries = <PsdkItemEffectManifestEntry>[];
  for (final line in _psdkItemEffectRows.trim().split('\n')) {
    final separator = line.indexOf('|');
    final itemId = line.substring(0, separator);
    final rubyPath = line.substring(separator + 1);
    final dartEffect = _dartItemEffects[itemId];
    entries.add(
      PsdkItemEffectManifestEntry(
        itemId: itemId,
        rubyPath: rubyPath,
        status: _itemStatus(itemId, dartEffect),
        batch: psdkItemEffectBatchFor(itemId: itemId, rubyPath: rubyPath),
        dartEffect: dartEffect,
      ),
    );
  }
  return List<PsdkItemEffectManifestEntry>.unmodifiable(entries);
}

PsdkItemEffectBatch psdkItemEffectBatchFor({
  required String itemId,
  required String rubyPath,
}) {
  final normalizedId = itemId.trim().toLowerCase();
  if (normalizedId.endsWith('_berry')) {
    return PsdkItemEffectBatch.berries;
  }
  return psdkItemEffectBatchForPath(rubyPath);
}

PsdkItemEffectBatch psdkItemEffectBatchForPath(String rubyPath) {
  final normalizedPath = rubyPath.toLowerCase();
  if (normalizedPath.contains('berry')) {
    return PsdkItemEffectBatch.berries;
  }
  if (normalizedPath.contains('itembasepowermultiplier') ||
      normalizedPath.contains('halfspeeditems') ||
      normalizedPath.contains('gems') ||
      normalizedPath.contains('drives') ||
      normalizedPath.contains('expert belt') ||
      normalizedPath.contains('eviolite') ||
      normalizedPath.contains('deep sea') ||
      normalizedPath.contains('lightball') ||
      normalizedPath.contains('metal powder') ||
      normalizedPath.contains('quick powder') ||
      normalizedPath.contains('thick club') ||
      normalizedPath.contains('lax incense') ||
      normalizedPath.contains('wide lens') ||
      normalizedPath.contains('zoom lens') ||
      normalizedPath.contains('poisonbarb')) {
    return PsdkItemEffectBatch.damageTypeStatModifiers;
  }
  if (normalizedPath.contains('choiceitemmultiplier') ||
      normalizedPath.contains('focus ') ||
      normalizedPath.contains('focus_') ||
      normalizedPath.contains('eject') ||
      normalizedPath.contains(' orb') ||
      normalizedPath.contains('primalorbs') ||
      normalizedPath.contains('life orb') ||
      normalizedPath.contains('red card')) {
    return PsdkItemEffectBatch.focusEjectChoiceOrb;
  }
  if (normalizedPath.contains('weathermove') ||
      normalizedPath.contains('terrainmove') ||
      normalizedPath.contains('terrainseeds') ||
      normalizedPath.contains('safetygoggles')) {
    return PsdkItemEffectBatch.weatherTerrainField;
  }
  return PsdkItemEffectBatch.heldItemLifecycleConsumption;
}

PsdkItemPortStatus _itemStatus(String itemId, String? dartEffect) {
  if (_portedItemEffects.contains(itemId)) {
    return PsdkItemPortStatus.ported;
  }
  return dartEffect == null
      ? PsdkItemPortStatus.missing
      : PsdkItemPortStatus.partial;
}

const _portedItemEffects = <String>{
  'absorb_bulb',
  'adamant_orb',
  'air_balloon',
  'apicot_berry',
  'aspear_berry',
  'assault_vest',
  'babiri_berry',
  'berry_juice',
  'big_root',
  'black_belt',
  'black_glasses',
  'black_sludge',
  'bright_powder',
  'bug_gem',
  'burn_drive',
  'cell_battery',
  'charcoal',
  'charti_berry',
  'cheri_berry',
  'chesto_berry',
  'chilan_berry',
  'chill_drive',
  'chople_berry',
  'choice_band',
  'choice_scarf',
  'choice_specs',
  'coba_berry',
  'colbur_berry',
  'damp_rock',
  'dark_gem',
  'deep_sea_scale',
  'deep_sea_tooth',
  'douse_drive',
  'draco_plate',
  'dragon_fang',
  'dragon_gem',
  'dread_plate',
  'earth_plate',
  'electric_gem',
  'electric_seed',
  'enigma_berry',
  'eviolite',
  'expert_belt',
  'fairy_gem',
  'fighting_gem',
  'fire_gem',
  'fist_plate',
  'flame_orb',
  'flame_plate',
  'flying_gem',
  'focus_band',
  'focus_sash',
  'ganlon_berry',
  'ghost_gem',
  'grass_gem',
  'griseous_orb',
  'grassy_seed',
  'ground_gem',
  'haban_berry',
  'hard_stone',
  'heat_rock',
  'ice_gem',
  'icicle_plate',
  'icy_rock',
  'insect_plate',
  'iron_ball',
  'iron_plate',
  'jaboca_berry',
  'kasib_berry',
  'kebia_berry',
  'kee_berry',
  'lax_incense',
  'leftovers',
  'liechi_berry',
  'light_ball',
  'luminous_moss',
  'lustrous_orb',
  'macho_brace',
  'magnet',
  'maranga_berry',
  'meadow_plate',
  'metal_coat',
  'metal_powder',
  'mind_plate',
  'miracle_seed',
  'misty_seed',
  'muscle_band',
  'mystic_water',
  'never_melt_ice',
  'normal_gem',
  'occa_berry',
  'odd_incense',
  'oran_berry',
  'passho_berry',
  'payapa_berry',
  'pecha_berry',
  'petaya_berry',
  'pixie_plate',
  'poison_barb',
  'poison_gem',
  'power_band',
  'power_belt',
  'power_bracer',
  'power_lens',
  'power_weight',
  'psychic_gem',
  'psychic_seed',
  'punching_glove',
  'quick_powder',
  'rawst_berry',
  'rindo_berry',
  'rock_gem',
  'rock_incense',
  'rocky_helmet',
  'rose_incense',
  'roseli_berry',
  'rowap_berry',
  'safety_goggles',
  'salac_berry',
  'sea_incense',
  'sharp_beak',
  'shed_shell',
  'shock_drive',
  'shuca_berry',
  'silk_scarf',
  'silver_powder',
  'sitrus_berry',
  'sky_plate',
  'smooth_rock',
  'snowball',
  'soul_dew',
  'soft_sand',
  'spell_tag',
  'splash_plate',
  'spooky_plate',
  'starf_berry',
  'steel_gem',
  'sticky_barb',
  'stone_plate',
  'tanga_berry',
  'terrain_extender',
  'thick_club',
  'toxic_orb',
  'toxic_plate',
  'twisted_spoon',
  'wacan_berry',
  'water_gem',
  'wave_incense',
  'weakness_policy',
  'wide_lens',
  'wise_glasses',
  'yache_berry',
  'zap_plate',
};

const _dartItemEffects = <String, String>{
  'absorb_bulb': 'TypeReactiveStatItemEffect',
  'adamant_orb': 'HeldItemModifierEffect.legendaryOrb',
  'air_balloon': 'AirBalloonEffect',
  'aguav_berry': 'BerryItemEffect.hpHeal.partialNoNatureConfusion',
  'apicot_berry': 'BerryItemEffect.statPinch',
  'aspear_berry': 'BerryItemEffect.statusCure',
  'assault_vest': 'AssaultVestEffect',
  'babiri_berry': 'TypeResistingBerryEffect',
  'berry_juice': 'BerryItemEffect.hpHeal',
  'big_root': 'BigRootEffect',
  'binding_band': 'BindingBandEffect',
  'black_belt': 'HeldItemModifierEffect.typeBoost',
  'black_glasses': 'HeldItemModifierEffect.typeBoost',
  'black_sludge': 'BlackSludgeEffect',
  'bright_powder': 'AccuracyModifierItemEffect.target',
  'bug_gem': 'GemItemEffect',
  'burn_drive': 'DriveItemEffect.technoBlastType',
  'cell_battery': 'TypeReactiveStatItemEffect',
  'charcoal': 'HeldItemModifierEffect.typeBoost',
  'charti_berry': 'TypeResistingBerryEffect',
  'cheri_berry': 'BerryItemEffect.statusCure',
  'chesto_berry': 'BerryItemEffect.statusCure',
  'chill_drive': 'DriveItemEffect.technoBlastType',
  'chilan_berry': 'TypeResistingBerryEffect',
  'chople_berry': 'TypeResistingBerryEffect',
  'choice_band': 'ChoiceItemEffect.choiceBand',
  'choice_scarf': 'ChoiceItemEffect.choiceScarf',
  'choice_specs': 'ChoiceItemEffect.choiceSpecs',
  'coba_berry': 'TypeResistingBerryEffect',
  'colbur_berry': 'TypeResistingBerryEffect',
  'damp_rock': 'WeatherRockEffect.dampRock',
  'dark_gem': 'GemItemEffect',
  'deep_sea_scale': 'HeldItemModifierEffect.speciesStat',
  'deep_sea_tooth': 'HeldItemModifierEffect.speciesStat',
  'douse_drive': 'DriveItemEffect.technoBlastType',
  'draco_plate': 'HeldItemModifierEffect.typeBoost',
  'electric_seed': 'TerrainSeedItemEffect.defense',
  'dragon_fang': 'HeldItemModifierEffect.typeBoost',
  'dragon_gem': 'GemItemEffect',
  'dread_plate': 'HeldItemModifierEffect.typeBoost',
  'earth_plate': 'HeldItemModifierEffect.typeBoost',
  'electric_gem': 'GemItemEffect',
  'enigma_berry': 'EnigmaBerryEffect',
  'eviolite': 'HeldItemModifierEffect.eviolite',
  'expert_belt': 'HeldItemModifierEffect.finalDamage',
  'fairy_gem': 'GemItemEffect',
  'fighting_gem': 'GemItemEffect',
  'figy_berry': 'BerryItemEffect.hpHeal.partialNoNatureConfusion',
  'fire_gem': 'GemItemEffect',
  'flame_orb': 'StatusOrbItemEffect.burn',
  'fist_plate': 'HeldItemModifierEffect.typeBoost',
  'flame_plate': 'HeldItemModifierEffect.typeBoost',
  'flying_gem': 'GemItemEffect',
  'focus_band': 'FocusBandEffect',
  'focus_sash': 'FocusSashEffect',
  'ganlon_berry': 'BerryItemEffect.statPinch',
  'ghost_gem': 'GemItemEffect',
  'grass_gem': 'GemItemEffect',
  'ground_gem': 'GemItemEffect',
  'griseous_orb': 'HeldItemModifierEffect.legendaryOrb',
  'grassy_seed': 'TerrainSeedItemEffect.defense',
  'grip_claw': 'GripClawEffect',
  'haban_berry': 'TypeResistingBerryEffect',
  'hard_stone': 'HeldItemModifierEffect.typeBoost',
  'heat_rock': 'WeatherRockEffect.heatRock',
  'ice_gem': 'GemItemEffect',
  'iapapa_berry': 'BerryItemEffect.hpHeal.partialNoNatureConfusion',
  'icy_rock': 'WeatherRockEffect.icyRock',
  'icicle_plate': 'HeldItemModifierEffect.typeBoost',
  'insect_plate': 'HeldItemModifierEffect.typeBoost',
  'iron_ball': 'IronBallEffect',
  'iron_plate': 'HeldItemModifierEffect.typeBoost',
  'jaboca_berry': 'RetaliateBerryEffect.physical',
  'kasib_berry': 'TypeResistingBerryEffect',
  'kebia_berry': 'TypeResistingBerryEffect',
  'kee_berry': 'HitStatBerryEffect.physicalDefense',
  'lax_incense': 'AccuracyModifierItemEffect.target',
  'liechi_berry': 'BerryItemEffect.statPinch',
  'leftovers': 'LeftoversEffect',
  'life_orb': 'LifeOrbEffect.partialNoPostActionBatching',
  'light_ball': 'HeldItemModifierEffect.speciesStat',
  'loaded_dice': 'LoadedDiceEffect',
  'luminous_moss': 'TypeReactiveStatItemEffect',
  'lum_berry': 'BerryItemEffect.statusCure.partialNoVolatileConfusion',
  'lustrous_orb': 'HeldItemModifierEffect.legendaryOrb',
  'macho_brace': 'HeldItemModifierEffect.speed',
  'magnet': 'HeldItemModifierEffect.typeBoost',
  'mago_berry': 'BerryItemEffect.hpHeal.partialNoNatureConfusion',
  'maranga_berry': 'HitStatBerryEffect.specialDefense',
  'meadow_plate': 'HeldItemModifierEffect.typeBoost',
  'metal_coat': 'HeldItemModifierEffect.typeBoost',
  'metal_powder': 'HeldItemModifierEffect.speciesStat',
  'misty_seed': 'TerrainSeedItemEffect.specialDefense',
  'mind_plate': 'HeldItemModifierEffect.typeBoost',
  'miracle_seed': 'HeldItemModifierEffect.typeBoost',
  'muscle_band': 'HeldItemModifierEffect.categoryBoost',
  'mystic_water': 'HeldItemModifierEffect.typeBoost',
  'never_melt_ice': 'HeldItemModifierEffect.typeBoost',
  'normal_gem': 'GemItemEffect',
  'odd_incense': 'HeldItemModifierEffect.typeBoost',
  'occa_berry': 'TypeResistingBerryEffect',
  'oran_berry': 'BerryItemEffect.hpHeal',
  'passho_berry': 'TypeResistingBerryEffect',
  'payapa_berry': 'TypeResistingBerryEffect',
  'pecha_berry': 'BerryItemEffect.statusCure',
  'petaya_berry': 'BerryItemEffect.statPinch',
  'pixie_plate': 'HeldItemModifierEffect.typeBoost',
  'poison_barb': 'HeldItemModifierEffect.typeBoost',
  'poison_gem': 'GemItemEffect',
  'power_band': 'HeldItemModifierEffect.speed',
  'power_belt': 'HeldItemModifierEffect.speed',
  'power_bracer': 'HeldItemModifierEffect.speed',
  'power_lens': 'HeldItemModifierEffect.speed',
  'power_weight': 'HeldItemModifierEffect.speed',
  'psychic_seed': 'TerrainSeedItemEffect.specialDefense',
  'psychic_gem': 'GemItemEffect',
  'punching_glove': 'HeldItemModifierEffect.categoryBoost',
  'quick_powder': 'HeldItemModifierEffect.speciesSpeed',
  'rawst_berry': 'BerryItemEffect.statusCure',
  'rindo_berry': 'TypeResistingBerryEffect',
  'rock_gem': 'GemItemEffect',
  'rock_incense': 'HeldItemModifierEffect.typeBoost',
  'rocky_helmet': 'RockyHelmetEffect',
  'roseli_berry': 'TypeResistingBerryEffect',
  'rose_incense': 'HeldItemModifierEffect.typeBoost',
  'rowap_berry': 'RetaliateBerryEffect.special',
  'safety_goggles': 'SafetyGogglesEffect',
  'salac_berry': 'BerryItemEffect.statPinch',
  'sea_incense': 'HeldItemModifierEffect.typeBoost',
  'shell_bell': 'ShellBellEffect.partialNoSheerForceActivation',
  'sharp_beak': 'HeldItemModifierEffect.typeBoost',
  'shed_shell': 'ShedShellEffect',
  'shock_drive': 'DriveItemEffect.technoBlastType',
  'shuca_berry': 'TypeResistingBerryEffect',
  'silk_scarf': 'HeldItemModifierEffect.typeBoost',
  'silver_powder': 'HeldItemModifierEffect.typeBoost',
  'sitrus_berry': 'BerryItemEffect.hpHeal',
  'sky_plate': 'HeldItemModifierEffect.typeBoost',
  'smooth_rock': 'WeatherRockEffect.smoothRock',
  'snowball': 'TypeReactiveStatItemEffect',
  'soft_sand': 'HeldItemModifierEffect.typeBoost',
  'soul_dew': 'HeldItemModifierEffect.legendaryOrb',
  'splash_plate': 'HeldItemModifierEffect.typeBoost',
  'spell_tag': 'HeldItemModifierEffect.typeBoost',
  'spooky_plate': 'HeldItemModifierEffect.typeBoost',
  'starf_berry': 'BerryItemEffect.statPinch',
  'steel_gem': 'GemItemEffect',
  'sticky_barb': 'StickyBarbEffect',
  'stone_plate': 'HeldItemModifierEffect.typeBoost',
  'tanga_berry': 'TypeResistingBerryEffect',
  'terrain_extender': 'TerrainExtenderEffect',
  'thick_club': 'HeldItemModifierEffect.speciesStat',
  'toxic_orb': 'StatusOrbItemEffect.toxic',
  'toxic_plate': 'HeldItemModifierEffect.typeBoost',
  'twisted_spoon': 'HeldItemModifierEffect.typeBoost',
  'wacan_berry': 'TypeResistingBerryEffect',
  'water_gem': 'GemItemEffect',
  'wave_incense': 'HeldItemModifierEffect.typeBoost',
  'weakness_policy': 'WeaknessPolicyEffect',
  'wide_lens': 'AccuracyModifierItemEffect.user',
  'wiki_berry': 'BerryItemEffect.hpHeal.partialNoNatureConfusion',
  'wise_glasses': 'HeldItemModifierEffect.categoryBoost',
  'yache_berry': 'TypeResistingBerryEffect',
  'zap_plate': 'HeldItemModifierEffect.typeBoost',
};

const _psdkItemEffectRows = '''
absorb_bulb|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Luminous Moss - Snowball.rb
adamant_orb|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
aguav_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 HpTriggered Healing Berries.rb
air_balloon|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Air Balloon.rb
apicot_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 HpTriggered Stat Berries.rb
aspear_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 StatusBerry.rb
assault_vest|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 ChoiceItemMultiplier.rb
babiri_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 TypeResistingBerry.rb
berry_juice|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 HpTriggered Healing Berries.rb
berserk_gene|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Berserk Gene.rb
big_root|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Big Root.rb
binding_band|pokemonsdk-development/scripts/5 Battle/06 Effects/02 Move Effects/001 Bind.rb
black_belt|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
black_glasses|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
black_sludge|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Black Sludge.rb
blue_orb|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 PrimalOrbs.rb
bright_powder|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Lax Incense.rb
bug_gem|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 Gems.rb
burn_drive|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 Drives.rb
cell_battery|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Luminous Moss - Snowball.rb
charcoal|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
charti_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 TypeResistingBerry.rb
cheri_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 StatusBerry.rb
chesto_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 StatusBerry.rb
chilan_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 TypeResistingBerry.rb
chill_drive|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 Drives.rb
choice_band|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 ChoiceItemMultiplier.rb
choice_scarf|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 ChoiceItemMultiplier.rb
choice_specs|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 ChoiceItemMultiplier.rb
chople_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 TypeResistingBerry.rb
coba_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 TypeResistingBerry.rb
colbur_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 TypeResistingBerry.rb
damp_rock|pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 WeatherMove.rb
dark_gem|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 Gems.rb
deep_sea_scale|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Deep Sea Scale.rb
deep_sea_tooth|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Deep Sea Tooth.rb
douse_drive|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 Drives.rb
draco_plate|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
dragon_fang|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
dragon_gem|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 Gems.rb
dread_plate|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
earth_plate|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
eject_button|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Eject Button.rb
electric_gem|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 Gems.rb
electric_seed|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 TerrainSeeds.rb
enigma_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Enigma Berry.rb
eviolite|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Eviolite.rb
expert_belt|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Expert Belt.rb
fairy_gem|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 Gems.rb
fighting_gem|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 Gems.rb
figy_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 HpTriggered Healing Berries.rb
fire_gem|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 Gems.rb
fist_plate|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
flame_orb|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Flame Orb.rb
flame_plate|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
flying_gem|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 Gems.rb
focus_band|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Focus Band.rb
focus_sash|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Focus Sash.rb
ganlon_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 HpTriggered Stat Berries.rb
ghost_gem|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 Gems.rb
grass_gem|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 Gems.rb
grip_claw|pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 Bind.rb
grassy_seed|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 TerrainSeeds.rb
griseous_orb|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
ground_gem|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 Gems.rb
haban_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 TypeResistingBerry.rb
hard_stone|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
heat_rock|pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 WeatherMove.rb
iapapa_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 HpTriggered Healing Berries.rb
ice_gem|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 Gems.rb
icicle_plate|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
icy_rock|pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 WeatherMove.rb
insect_plate|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
iron_ball|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 HalfSpeedItems.rb
iron_plate|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
jaboca_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Jaboca Berry.rb
kasib_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 TypeResistingBerry.rb
kebia_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 TypeResistingBerry.rb
kee_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Kee Berry - Maranga Berry.rb
king_s_rock|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Kings Rock - Razor Fang.rb
lansat_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Lansat Berry.rb
lax_incense|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Lax Incense.rb
leftovers|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Leftovers.rb
leppa_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Leppa Berry.rb
liechi_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 HpTriggered Stat Berries.rb
life_orb|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Life Orb.rb
light_ball|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 LightBall.rb
loaded_dice|pokemonsdk-development/scripts/5 Battle/30 AI/1 MoveHeuristic/002 MultiHitMoves.rb
lum_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Lum Berry.rb
luminous_moss|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Luminous Moss - Snowball.rb
lustrous_orb|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
macho_brace|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 HalfSpeedItems.rb
magnet|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
mago_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 HpTriggered Healing Berries.rb
maranga_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Kee Berry - Maranga Berry.rb
meadow_plate|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
mental_herb|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 MentalHerb.rb
metal_coat|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
metal_powder|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Metal Powder.rb
metronome|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Metronome.rb
micle_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Micle Berry.rb
mind_plate|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
miracle_seed|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
mirror_herb|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 MirrorHerb.rb
misty_seed|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 TerrainSeeds.rb
muscle_band|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
mystic_water|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
never_melt_ice|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
normal_gem|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 Gems.rb
occa_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 TypeResistingBerry.rb
odd_incense|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
oran_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 HpTriggered Healing Berries.rb
passho_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 TypeResistingBerry.rb
payapa_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 TypeResistingBerry.rb
pecha_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 StatusBerry.rb
persim_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Persim Berry.rb
petaya_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 HpTriggered Stat Berries.rb
pixie_plate|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
poison_barb|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 PoisonBarb.rb
poison_gem|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 Gems.rb
power_band|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 HalfSpeedItems.rb
power_belt|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 HalfSpeedItems.rb
power_bracer|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 HalfSpeedItems.rb
power_herb|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 PowerHerb.rb
power_lens|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 HalfSpeedItems.rb
power_weight|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 HalfSpeedItems.rb
psychic_gem|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 Gems.rb
psychic_seed|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 TerrainSeeds.rb
punching_glove|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
quick_powder|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Quick Powder.rb
rawst_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 StatusBerry.rb
razor_fang|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Kings Rock - Razor Fang.rb
red_card|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Red Card.rb
red_orb|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 PrimalOrbs.rb
rindo_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 TypeResistingBerry.rb
rock_gem|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 Gems.rb
rock_incense|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
rocky_helmet|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Rocky Helmet.rb
rose_incense|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
roseli_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 TypeResistingBerry.rb
rowap_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Jaboca Berry.rb
safety_goggles|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 SafetyGoggles.rb
salac_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 HpTriggered Stat Berries.rb
sea_incense|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
sharp_beak|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
shed_shell|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Shed Shell.rb
shell_bell|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Shell Bell.rb
shock_drive|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 Drives.rb
shuca_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 TypeResistingBerry.rb
silk_scarf|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
silver_powder|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
sitrus_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 HpTriggered Healing Berries.rb
sky_plate|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
smoke_ball|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 SmokeBall.rb
smooth_rock|pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 WeatherMove.rb
snowball|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Luminous Moss - Snowball.rb
soft_sand|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
soul_dew|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
spell_tag|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
splash_plate|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
spooky_plate|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
starf_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 HpTriggered Stat Berries.rb
steel_gem|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 Gems.rb
sticky_barb|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Sticky Barb.rb
stone_plate|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
tanga_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 TypeResistingBerry.rb
terrain_extender|pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 TerrainMove.rb
thick_club|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Thick Club.rb
throat_spray|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Throat Spray.rb
toxic_orb|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Toxic Orb.rb
toxic_plate|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
twisted_spoon|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
wacan_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 TypeResistingBerry.rb
water_gem|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 Gems.rb
wave_incense|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
weakness_policy|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Weakness Policy.rb
white_herb|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 White Herb.rb
wide_lens|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Wide Lens.rb
wiki_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 HpTriggered Healing Berries.rb
wise_glasses|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
yache_berry|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 TypeResistingBerry.rb
zap_plate|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb
zoom_lens|pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/100 Zoom Lens.rb
''';
