/// Generated PSDK ability effect manifest.
///
/// Source: `pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects`
/// plus core PSDK ability checks already modeled by the Dart lane.
/// This file is intentionally explicit so ability parity is measurable even
/// before every ability has a dedicated Dart effect implementation.
const psdkAbilityEffectManifest = <PsdkAbilityEffectManifestEntry>[
  PsdkAbilityEffectManifestEntry(
    abilityId: 'aerilate',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/051 ChangingMoveType.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'MoveTypeChangeAbilityEffect.aerilate',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'aftermath',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Aftermath.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AftermathEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'air_lock',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Air Lock - Cloud Nine.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AirLockEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'analytic',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Analytic.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AbilityBasePowerModifierEffect.analytic',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'anger_point',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Anger Point.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AngerPointEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'anger_shell',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Anger Shell.rb',
    status: PsdkAbilityPortStatus.partial,
    dartEffect: 'HalfHpThresholdStatChangeAbilityEffect.angerShell',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'anticipation',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Anticipation.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AnticipationEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'arena_trap',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 PreventingSwitchAbilities.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'ShadowTagEffect.arenaTrap',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'armor_tail',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Armor Tail.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'PriorityMovePreventionAbilityEffect.armorTail',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'aroma_veil',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Mental Immunity.rb',
    status: PsdkAbilityPortStatus.partial,
    dartEffect: 'MentalImmunityAbilityEffect.aromaVeil.partialNoPostActionHook',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'as_one',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/101 AsOne.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'aura_break',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Auras.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AuraPowerAbilityEffect.auraBreak',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'bad_dreams',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Bad Dreams.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'BadDreamsEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'ball_fetch',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 BallFetch.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'battery',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Battery.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AllyDamageModifierAbilityEffect.batterySpecialAttack',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'battle_bond',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Battle Bond.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'beads_of_ruin',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 TabletsOfRuin.rb',
    status: PsdkAbilityPortStatus.partial,
    dartEffect: 'RuinStatAbilityEffect.beadsOfRuin.partialNoWonderRoomSwap',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'beast_boost',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Beast Boost.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'PostDamageKoStatBoostAbilityEffect.highestStat',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'berserk',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Berserk.rb',
    status: PsdkAbilityPortStatus.partial,
    dartEffect: 'HalfHpThresholdStatChangeAbilityEffect.berserk',
  ),
  PsdkAbilityEffectManifestEntry(
      abilityId: 'big_pecks',
      rubyPath:
          'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Big Pecks.rb',
      status: PsdkAbilityPortStatus.ported,
      dartEffect: 'StatDropPreventionAbilityEffect.defense'),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'blaze',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 BoostingMoveType.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'TypeBoostingAbilityEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'bulletproof',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Bulletproof.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'BulletproofEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'cheek_pouch',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/05 Item Effects/002 Berry.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'CheekPouchEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'chilling_neigh',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Moxie.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'PostDamageKoStatBoostAbilityEffect.attack',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'chlorophyll',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Chlorophyll.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatModifierAbilityEffect.chlorophyll',
  ),
  PsdkAbilityEffectManifestEntry(
      abilityId: 'clear_body',
      rubyPath:
          'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Clear Body.rb',
      status: PsdkAbilityPortStatus.ported,
      dartEffect: 'StatDropPreventionAbilityEffect.all'),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'cloud_nine',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Air Lock - Cloud Nine.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'CloudNineEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'color_change',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Color Change.rb',
    status: PsdkAbilityPortStatus.partial,
    dartEffect: 'ColorChangeEffect.partialNoSheerForceMultiHitState',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'comatose',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Comatose.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatusImmunityEffect.comatose',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'commander',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Commander.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'competitive',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Defiant.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatDropPunishAbilityEffect.competitive',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'compound_eyes',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Compound Eyes.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AccuracyModifierAbilityEffect.compoundEyes',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'contrary',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Contrary.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatChangeTransformAbilityEffect.contrary',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'costar',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Costar.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'CostarEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'cotton_down',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Cotton Down.rb',
    status: PsdkAbilityPortStatus.partial,
    dartEffect: 'CottonDownEffect.partialNoMirrorArmor',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'cud_chew',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Cud Chew.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'curious_medicine',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Curious Medicine.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'CuriousMedicineEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'cursed_body',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Cursed Body.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'ContactDisableAbilityEffect.cursedBody',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'cute_charm',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Cute Charm.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'damp',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 SelfDestruct.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'DampEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'dancer',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Dancer.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'dark_aura',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Auras.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AuraPowerAbilityEffect.darkAura',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'dauntless_shield',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Dauntless Shield.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'SwitchStatBoostAbilityEffect.dauntlessShield',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'dazzling',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Queenly Majesty - Dazzling.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'PriorityMovePreventionAbilityEffect.dazzling',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'defeatist',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Defeatist.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AbilityBasePowerModifierEffect.defeatist',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'defiant',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Defiant.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatDropPunishAbilityEffect.defiant',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'delta_stream',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Primal Weathers.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'PrimalWeatherAbilityEffect.deltaStream',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'desolate_land',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Primal Weathers.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'PrimalWeatherAbilityEffect.desolateLand',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'disguise',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Disguise.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'download',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Download.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'DownloadEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'dragon_s_maw',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 BoostingMoveType.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'TypeBoostingAbilityEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'drizzle',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 Weather Setting Abilitites.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'SwitchWeatherAbilityEffect.drizzle',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'drought',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 Weather Setting Abilitites.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'SwitchWeatherAbilityEffect.drought',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'dry_skin',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Dry Skin.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'DrySkinEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'earth_eater',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 TypeAbsorb.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'TypeImmunityAbilityEffect.earthEater',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'effect_spore',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Effect Spore.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'ContactStatusAbilityEffect.effectSpore',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'electric_surge',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 FieldTerrain Setting Abilities.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'SwitchTerrainAbilityEffect.electricSurge',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'electromorphosis',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Electromorphosis.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'embody_aspect',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Embody Aspect.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'emergency_exit',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Emergency Exit - Wimp Out.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'fairy_aura',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Auras.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AuraPowerAbilityEffect.fairyAura',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'filter',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 SuperEffectivePowerReduction.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AbilityFinalDamageModifierEffect.superEffectiveIncoming',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'flame_body',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Flame Body.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'ContactStatusAbilityEffect.flameBody',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'flare_boost',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Flare Boost.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatModifierAbilityEffect.flareBoost',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'flash_fire',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Flash Fire.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'TypeImmunityAbilityEffect.flashFire',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'flower_gift',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Flower Gift.rb',
    status: PsdkAbilityPortStatus.partial,
    dartEffect: 'FlowerGiftStatAbilityEffect.partialNoCherrimForm',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'flower_veil',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Flower Veil.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'FlowerVeilEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'fluffy',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Fluffy.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AbilityBasePowerModifierEffect.fluffy',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'forecast',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Forecast.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'forewarn',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Forewarn.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'ForewarnEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'friend_guard',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Friend Guard.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AllyDamageModifierAbilityEffect.friendGuard',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'frisk',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Frisk.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'FriskEffect',
  ),
  PsdkAbilityEffectManifestEntry(
      abilityId: 'full_metal_body',
      rubyPath:
          'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Full Metal Body.rb',
      status: PsdkAbilityPortStatus.ported,
      dartEffect: 'StatDropPreventionAbilityEffect.all'),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'fur_coat',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Fur Coat.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatModifierAbilityEffect.furCoat',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'gale_wings',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Gale Wings.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'GaleWingsAbilityEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'galvanize',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/051 ChangingMoveType.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'MoveTypeChangeAbilityEffect.galvanize',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'good_as_gold',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 GoodAsGold.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'GoodAsGoldEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'gooey',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Gooey.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'PostDamageStatChangeAbilityEffect.gooey',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'gorilla_tactics',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Gorilla Tactics.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'grass_pelt',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Grass Pelt.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatModifierAbilityEffect.grassPelt',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'grassy_surge',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 FieldTerrain Setting Abilities.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'SwitchTerrainAbilityEffect.grassySurge',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'grim_neigh',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Moxie.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'PostDamageKoStatBoostAbilityEffect.specialAttack',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'guard_dog',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 GuardDog.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatChangeTransformAbilityEffect.guardDog',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'gulp_missile',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 GulpMissile.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'guts',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Guts.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatModifierAbilityEffect.guts',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'hadron_engine',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 HadronEngine.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'HadronEngineEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'harvest',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Harvest.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'HarvestEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'healer',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Healer.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'HealerEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'heatproof',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Heatproof.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AbilityBasePowerModifierEffect.heatproof',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'hospitality',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Hospitality.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'HospitalityEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'huge_power',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Pure Power - Huge Power.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatModifierAbilityEffect.hugePower',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'hunger_switch',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Hunger Switch.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'hustle',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Hustle.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'HustleAbilityEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'hydration',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Hydration.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'HydrationEffect',
  ),
  PsdkAbilityEffectManifestEntry(
      abilityId: 'hyper_cutter',
      rubyPath:
          'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Hyper Cutter.rb',
      status: PsdkAbilityPortStatus.ported,
      dartEffect: 'StatDropPreventionAbilityEffect.attack'),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'ice_body',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Ice Body.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'IceBodyEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'ice_face',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Ice Face.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'ice_scales',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Ice Scales.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AbilityBasePowerModifierEffect.iceScales',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'immunity',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 NonVolatileStatusImmunity.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatusImmunityEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'imposter',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Imposter.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'ImposterEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'innards_out',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Innards Out.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'InnardsOutEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'inner_focus',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Inner Focus.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'MentalImmunityAbilityEffect.innerFocus',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'insomnia',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 NonVolatileStatusImmunity.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatusImmunityEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'intimidate',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Intimidate.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'IntimidateEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'intrepid_sword',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Intrepid Sword.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'SwitchStatBoostAbilityEffect.intrepidSword',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'iron_barbs',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Rough Skin - Iron Barbs.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'ContactPunishAbilityEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'iron_fist',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Iron Fist.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'MoveShapePowerAbilityEffect.ironFist',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'justified',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Justified.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'PostDamageStatChangeAbilityEffect.justified',
  ),
  PsdkAbilityEffectManifestEntry(
      abilityId: 'keen_eye',
      rubyPath:
          'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Keen Eye.rb',
      status: PsdkAbilityPortStatus.ported,
      dartEffect: 'StatDropPreventionAbilityEffect.accuracy'),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'leaf_guard',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Leaf Guard.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatusPreventionAbilityEffect.leafGuard',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'levitate',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/03 PokemonBattler/004 Grounded.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'LevitateEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'libero',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Libero - Protean.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'lightning_rod',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Lightning Rod - Storm Drain.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'TypeImmunityAbilityEffect.lightningRod',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'limber',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 NonVolatileStatusImmunity.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatusImmunityEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'lingering_aroma',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Mummy.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'ContactAbilityChangeEffect.lingeringAroma',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'liquid_ooze',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Liquid Ooze.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'liquid_voice',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Liquid Voice.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'MoveTypeChangeAbilityEffect.liquidVoice',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'magician',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Pickpocket - Magician.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'magma_armor',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 NonVolatileStatusImmunity.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatusImmunityEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'magnet_pull',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 PreventingSwitchAbilities.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'ShadowTagEffect.magnetPull',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'marvel_scale',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Marvel Scale.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatModifierAbilityEffect.marvelScale',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'mega_launcher',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Mega Launcher.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'MoveShapePowerAbilityEffect.megaLauncher',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'mimicry',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Mimicry.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'MimicryEffect',
  ),
  PsdkAbilityEffectManifestEntry(
      abilityId: 'mind_s_eye',
      rubyPath:
          'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Keen Eye.rb',
      status: PsdkAbilityPortStatus.ported,
      dartEffect: 'StatDropPreventionAbilityEffect.accuracy'),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'minus',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Plus - Minus.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'PlusMinusAbilityEffect.minus',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'mirror_armor',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Mirror Armor.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'misty_surge',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 FieldTerrain Setting Abilities.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'SwitchTerrainAbilityEffect.mistySurge',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'mold_breaker',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Mold Breaker.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'MoldBreakerFamilyEffect.moldBreaker',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'moody',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Moody.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'MoodyEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'motor_drive',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Motor Drive.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'TypeImmunityAbilityEffect.motorDrive',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'moxie',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Moxie.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'PostDamageKoStatBoostAbilityEffect.attack',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'multiscale',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Multiscale - Shadow Shield.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'FullHpIncomingPowerReductionEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'mummy',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Mummy.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'ContactAbilityChangeEffect.mummy',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'natural_cure',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Natural Cure.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'NaturalCureEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'neuroforce',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Neuroforce.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AbilityFinalDamageModifierEffect.neuroforce',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'neutralizing_gas',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 NeutralizingGas.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'no_guard',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/10 Move/120 Procedure.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'NoGuardEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'normalize',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Normalize.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'MoveTypeChangeAbilityEffect.normalize',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'oblivious',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Mental Immunity.rb',
    status: PsdkAbilityPortStatus.partial,
    dartEffect: 'MentalImmunityAbilityEffect.oblivious.partialNoPostActionCure',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'opportunist',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Opportunist.rb',
    status: PsdkAbilityPortStatus.partial,
    dartEffect: 'OpportunistEffect.statBoostCopy',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'orichalcum_pulse',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 OrichalcumPulse.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'OrichalcumPulseEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'overcoat',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Overcoat.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'PowderMoveImmunityAbilityEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'overgrow',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 BoostingMoveType.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'TypeBoostingAbilityEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'own_tempo',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Own Tempo.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'MentalImmunityAbilityEffect.ownTempo',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'parental_bond',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Parental Bond.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'pastel_veil',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Pastel Veil.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatusPreventionAbilityEffect.pastelVeil',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'perish_body',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Perish Body.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'PerishBodyEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'pickpocket',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Pickpocket - Magician.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'pixilate',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/051 ChangingMoveType.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'MoveTypeChangeAbilityEffect.pixilate',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'plus',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Plus - Minus.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'PlusMinusAbilityEffect.plus',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'poison_point',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Poison Point.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'ContactStatusAbilityEffect.poisonPoint',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'poison_puppeteer',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Poison Puppeteer.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'poison_touch',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 ApplyStatusToMoveTarget.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'ApplyStatusToMoveTargetAbilityEffect.poisonTouch',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'power_construct',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Power Construct.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'power_of_alchemy',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Power of Alchemy - Receiver.rb',
    status: PsdkAbilityPortStatus.partial,
    dartEffect:
        'ReceiverPowerOfAlchemyEffect.powerOfAlchemy.partialNoAbilityChangePreventionHooks',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'power_spot',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 PowerSpot.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AllyDamageModifierAbilityEffect.powerSpot',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'prankster',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Prankster.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'PranksterAbilityEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'pressure',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Pressure.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'PressureEffect+BattleTurnRunner.ppCost',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'primordial_sea',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Primal Weathers.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'PrimalWeatherAbilityEffect.primordialSea',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'prism_armor',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 SuperEffectivePowerReduction.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AbilityFinalDamageModifierEffect.superEffectiveIncoming',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'propeller_tail',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Stalwart.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'BattleTargetResolver.redirectionBypass',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'protean',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Libero - Protean.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'protosynthesis',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Protosynthesis.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'psychic_surge',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 FieldTerrain Setting Abilities.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'SwitchTerrainAbilityEffect.psychicSurge',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'punk_rock',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Punk Rock.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'MoveShapePowerAbilityEffect.punkRock',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'pure_power',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Pure Power - Huge Power.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatModifierAbilityEffect.purePower',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'purifying_salt',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 PurifyingSalt.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'PurifyingSaltEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'quark_drive',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 QuarkDrive.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'queenly_majesty',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Queenly Majesty - Dazzling.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'PriorityMovePreventionAbilityEffect.queenlyMajesty',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'quick_feet',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Quick Feet.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatModifierAbilityEffect.quickFeet',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'rain_dish',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Rain Dish.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'RainDishEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'rattled',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Rattled.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'RattledEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'receiver',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Power of Alchemy - Receiver.rb',
    status: PsdkAbilityPortStatus.partial,
    dartEffect:
        'ReceiverPowerOfAlchemyEffect.receiver.partialNoAbilityChangePreventionHooks',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'reckless',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Reckless.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'RecklessEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'refrigerate',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/051 ChangingMoveType.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'MoveTypeChangeAbilityEffect.refrigerate',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'regenerator',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Regenerator.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'RegeneratorEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'ripen',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Ripen.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'RipenEffect + BerryItemEffect ripen multipliers',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'rivalry',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Rivalry.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'rock_head',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/10 Move/120 Procedure.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'RockHeadEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'rocky_payload',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 BoostingMoveType.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'TypeBoostingAbilityEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'rough_skin',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Rough Skin - Iron Barbs.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'ContactPunishAbilityEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'run_away',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 RunAway.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'sand_force',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Sand Force.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AbilityBasePowerModifierEffect.sandForce',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'sand_rush',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Sand Rush.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatModifierAbilityEffect.sandRush',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'sand_spit',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Sand Spit.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'SandSpitEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'sand_stream',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 Weather Setting Abilitites.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'SwitchWeatherAbilityEffect.sandStream',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'sand_veil',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 SandVeil.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AccuracyModifierAbilityEffect.sandVeil',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'sap_sipper',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Sap Sipper.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'TypeImmunityAbilityEffect.sapSipper',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'schooling',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Zen Mode.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'screen_cleaner',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 ScreenCleaner.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'ScreenCleanerEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'seed_sower',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 SeedSower.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'SeedSowerEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'serene_grace',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 SereneGrace.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'shadow_shield',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Multiscale - Shadow Shield.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'FullHpIncomingPowerReductionEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'shadow_tag',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 PreventingSwitchAbilities.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'ShadowTagEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'sharpness',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Sharpness.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'MoveShapePowerAbilityEffect.sharpness',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'shed_skin',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Shed Skin.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'ShedSkinEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'sheer_force',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 SheerForce.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'shield_dust',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 ShieldDust.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'skill_link',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/10 Move/1 Mechanics/103 TwoHit MultiHit.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'SkillLinkEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'shields_down',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Zen Mode.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'simple',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Simple.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatChangeTransformAbilityEffect.simple',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'slow_start',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Slow Start.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'SlowStartAbilityEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'slush_rush',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Slush Rush.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatModifierAbilityEffect.slushRush',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'snow_cloak',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Snow Cloak.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AccuracyModifierAbilityEffect.snowCloak',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'snow_warning',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 Weather Setting Abilitites.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'SwitchWeatherAbilityEffect.snowWarning',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'solar_power',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Solar Power.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'SolarPowerEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'solid_rock',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 SuperEffectivePowerReduction.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AbilityFinalDamageModifierEffect.superEffectiveIncoming',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'soul_heart',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Soul-Heart.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'SoulHeartEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'soundproof',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Soundproof.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'SoundproofEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'speed_boost',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Speed Boost.rb',
    status: PsdkAbilityPortStatus.partial,
    dartEffect: 'SpeedBoostEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'stakeout',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Stakeout.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AbilityBasePowerModifierEffect.stakeout',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'stalwart',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Stalwart.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'BattleTargetResolver.redirectionBypass',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'stamina',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Stamina.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'PostDamageStatChangeAbilityEffect.stamina',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'stance_change',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Stance Change.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'static',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Static.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'ContactStatusAbilityEffect.static',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'steadfast',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Steadfast.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'steam_engine',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Steam Engine.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'PostDamageStatChangeAbilityEffect.steamEngine',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'steelworker',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 BoostingMoveType.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'TypeBoostingAbilityEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'steely_spirit',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Steely Spirit.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AllyDamageModifierAbilityEffect.steelySpirit',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'stench',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Stench.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StenchEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'storm_drain',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Lightning Rod - Storm Drain.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'TypeImmunityAbilityEffect.stormDrain',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'strong_jaw',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Strong Jaw.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'MoveShapePowerAbilityEffect.strongJaw',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'sturdy',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Sturdy.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'SturdyEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'suction_cups',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 PreventingSwitchAbilities.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'SuctionCupsEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'supersweet_syrup',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Supersweet Syrup.rb',
    status: PsdkAbilityPortStatus.partial,
    dartEffect: 'SupersweetSyrupEffect.partialNoPersistentAbilityUsed',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'supreme_overlord',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 SupremeOverlord.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'surge_surfer',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Surge Surfer.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatModifierAbilityEffect.surgeSurfer',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'swarm',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 BoostingMoveType.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'TypeBoostingAbilityEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'sweet_veil',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Sweet Veil.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatusPreventionAbilityEffect.sweetVeil',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'swift_swim',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Swift Swim.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatModifierAbilityEffect.swiftSwim',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'sword_of_ruin',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 TabletsOfRuin.rb',
    status: PsdkAbilityPortStatus.partial,
    dartEffect: 'RuinStatAbilityEffect.swordOfRuin.partialNoWonderRoomSwap',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'symbiosis',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Symbiosis.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'synchronize',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Synchronize.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'SynchronizeEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'tablets_of_ruin',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 TabletsOfRuin.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'RuinStatAbilityEffect.tabletsOfRuin',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'tangled_feet',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Tangled Feet.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AccuracyModifierAbilityEffect.tangledFeet',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'tangling_hair',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Gooey.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'PostDamageStatChangeAbilityEffect.tanglingHair',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'technician',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Technician.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'MoveShapePowerAbilityEffect.technician',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'telepathy',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Telepathy.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'TelepathyEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'tera_shell',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 TeraShell.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'tera_shift',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Tera Shift.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'teraform_zero',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Teraform Zero.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'teravolt',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Mold Breaker.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'MoldBreakerFamilyEffect.teravolt',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'thermal_exchange',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 ThermalExchange.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'ThermalExchangeEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'thick_fat',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Thick Fat.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AbilityBasePowerModifierEffect.thickFat',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'tinted_lens',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Tinted Lens.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AbilityFinalDamageModifierEffect.notVeryEffectiveOutgoing',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'torrent',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 BoostingMoveType.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'TypeBoostingAbilityEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'tough_claws',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Tough Claws.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'MoveShapePowerAbilityEffect.toughClaws',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'toxic_boost',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Toxic Boost.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatModifierAbilityEffect.toxicBoost',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'toxic_chain',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 ApplyStatusToMoveTarget.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'ApplyStatusToMoveTargetAbilityEffect.toxicChain',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'toxic_debris',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 ToxicDebris.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'ToxicDebrisEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'trace',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Trace.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'TraceEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'transistor',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 BoostingMoveType.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'TypeBoostingAbilityEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'triage',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Triage.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'TriageAbilityEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'truant',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Truant.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'turboblaze',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Mold Breaker.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'MoldBreakerFamilyEffect.turboblaze',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'unaware',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Unaware.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'unburden',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Unburden.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'UnburdenEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'unnerve',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Unnerve.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'vessel_of_ruin',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 TabletsOfRuin.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'RuinStatAbilityEffect.vesselOfRuin',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'victory_star',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Victory Star.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AccuracyModifierAbilityEffect.victoryStar',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'vital_spirit',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 NonVolatileStatusImmunity.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatusImmunityEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'volt_absorb',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 TypeAbsorb.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'TypeImmunityAbilityEffect.voltAbsorb',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'wandering_spirit',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Wandering Spirit.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'WanderingSpiritEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'water_absorb',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 TypeAbsorb.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'TypeImmunityAbilityEffect.waterAbsorb',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'water_bubble',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Water Bubble.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'WaterBubbleEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'water_compaction',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Water Compaction.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'PostDamageStatChangeAbilityEffect.waterCompaction',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'water_veil',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/050 NonVolatileStatusImmunity.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'StatusImmunityEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'weak_armor',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Weak Armor.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'PostDamageStatChangeAbilityEffect.weakArmor',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'well_baked_body',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 WellBaked Body.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'TypeImmunityAbilityEffect.wellBakedBody',
  ),
  PsdkAbilityEffectManifestEntry(
      abilityId: 'white_smoke',
      rubyPath:
          'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 White Smoke.rb',
      status: PsdkAbilityPortStatus.ported,
      dartEffect: 'StatDropPreventionAbilityEffect.all'),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'wimp_out',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Emergency Exit - Wimp Out.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'wind_power',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 WindPower.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'wind_rider',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 WindRider.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'wonder_guard',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Wonder Guard.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'WonderGuardEffect',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'wonder_skin',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Wonder Skin.rb',
    status: PsdkAbilityPortStatus.ported,
    dartEffect: 'AccuracyModifierAbilityEffect.wonderSkin',
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'zen_mode',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 Zen Mode.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
  PsdkAbilityEffectManifestEntry(
    abilityId: 'zero_to_hero',
    rubyPath:
        'pokemonsdk-development/scripts/5 Battle/06 Effects/04 Ability Effects/100 ZeroToHero.rb',
    status: PsdkAbilityPortStatus.missing,
  ),
];

final class PsdkAbilityEffectManifestEntry {
  const PsdkAbilityEffectManifestEntry({
    required this.abilityId,
    required this.rubyPath,
    required this.status,
    this.dartEffect,
  });

  final String abilityId;
  final String rubyPath;
  final PsdkAbilityPortStatus status;
  final String? dartEffect;
}

enum PsdkAbilityPortStatus {
  ported,
  partial,
  missing,
  outOfScope,
}
