import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_visual_catalog.dart';

void main() {
  group('BattleMoveVisualCatalog', () {
    test('direct recipe lookup exists for seeded moves', () {
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['tackle'],
        equals(BattleMoveVisualRecipeId.sdkTackle),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['scratch'],
        equals(BattleMoveVisualRecipeId.sdkScratch),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['quickattack'],
        equals(BattleMoveVisualRecipeId.sdkQuickAttack),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['thunderbolt'],
        equals(BattleMoveVisualRecipeId.sdkThunderbolt),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['shadowball'],
        equals(BattleMoveVisualRecipeId.sdkShadowBall),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['protect'],
        equals(BattleMoveVisualRecipeId.sdkProtect),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['burningbulwark'],
        equals(BattleMoveVisualRecipeId.sdkBurningBulwark),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['banefulbunker'],
        equals(BattleMoveVisualRecipeId.sdkBanefulBunker),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['growl'],
        equals(BattleMoveVisualRecipeId.sdkGrowl),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['thunderwave'],
        equals(BattleMoveVisualRecipeId.sdkExactThunderWave),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['raindance'],
        equals(BattleMoveVisualRecipeId.sdkRainDance),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['sandstorm'],
        equals(BattleMoveVisualRecipeId.sdkSandstorm),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['trickroom'],
        equals(BattleMoveVisualRecipeId.sdkTrickRoom),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['reflect'],
        equals(BattleMoveVisualRecipeId.sdkReflect),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['lightscreen'],
        equals(BattleMoveVisualRecipeId.sdkLightScreen),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['mist'],
        equals(BattleMoveVisualRecipeId.sdkMist),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['auroraveil'],
        equals(BattleMoveVisualRecipeId.sdkAuroraVeil),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['aquajet'],
        equals(BattleMoveVisualRecipeId.sdkAquaJet),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['extremespeed'],
        equals(BattleMoveVisualRecipeId.sdkExtremeSpeed),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['machpunch'],
        equals(BattleMoveVisualRecipeId.sdkMachPunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['spark'],
        equals(BattleMoveVisualRecipeId.sdkSpark),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['wildcharge'],
        equals(BattleMoveVisualRecipeId.sdkWildCharge),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['flareblitz'],
        equals(BattleMoveVisualRecipeId.sdkFlareBlitz),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['accelerock'],
        equals(BattleMoveVisualRecipeId.sdkAccelerock),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['wickedblow'],
        equals(BattleMoveVisualRecipeId.sdkWickedBlow),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['doublehit'],
        equals(BattleMoveVisualRecipeId.sdkDoubleHit),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['crunch'],
        equals(BattleMoveVisualRecipeId.sdkCrunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['flamethrower'],
        equals(BattleMoveVisualRecipeId.sdkFlamethrower),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['icebeam'],
        equals(BattleMoveVisualRecipeId.sdkIceBeam),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['psychic'],
        equals(BattleMoveVisualRecipeId.sdkPsychic),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['moonblast'],
        equals(BattleMoveVisualRecipeId.sdkMoonBlast),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['poisonjab'],
        equals(BattleMoveVisualRecipeId.sdkPoisonJab),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['earthquake'],
        equals(BattleMoveVisualRecipeId.sdkEarthquake),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['energyball'],
        equals(BattleMoveVisualRecipeId.sdkEnergyBall),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['rockslide'],
        equals(BattleMoveVisualRecipeId.sdkRockSlide),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['nightslash'],
        equals(BattleMoveVisualRecipeId.sdkNightSlash),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['gigaimpact'],
        equals(BattleMoveVisualRecipeId.sdkGigaImpact),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['powerwhip'],
        equals(BattleMoveVisualRecipeId.sdkPowerWhip),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['crabhammer'],
        equals(BattleMoveVisualRecipeId.sdkCrabHammer),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['discharge'],
        equals(BattleMoveVisualRecipeId.sdkDischarge),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['smartstrike'],
        equals(BattleMoveVisualRecipeId.sdkSmartStrike),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['megahorn'],
        equals(BattleMoveVisualRecipeId.sdkMegaHorn),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['dragonclaw'],
        equals(BattleMoveVisualRecipeId.sdkDragonClaw),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['psychocut'],
        equals(BattleMoveVisualRecipeId.sdkPsychoCut),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['waterpulse'],
        equals(BattleMoveVisualRecipeId.sdkWaterPulse),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['powergem'],
        equals(BattleMoveVisualRecipeId.sdkPowerGem),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['heatwave'],
        equals(BattleMoveVisualRecipeId.sdkHeatWave),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['muddywater'],
        equals(BattleMoveVisualRecipeId.sdkMuddyWater),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['earthpower'],
        equals(BattleMoveVisualRecipeId.sdkEarthPower),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['bugbuzz'],
        equals(BattleMoveVisualRecipeId.sdkBugBuzz),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['playrough'],
        equals(BattleMoveVisualRecipeId.sdkPlayRough),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['surf'],
        equals(BattleMoveVisualRecipeId.sdkSurf),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['hydropump'],
        equals(BattleMoveVisualRecipeId.sdkHydroPump),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['leafblade'],
        equals(BattleMoveVisualRecipeId.sdkLeafBlade),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['xscissor'],
        equals(BattleMoveVisualRecipeId.sdkXScissor),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['firefang'],
        equals(BattleMoveVisualRecipeId.sdkFireFang),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['icefang'],
        equals(BattleMoveVisualRecipeId.sdkIceFang),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['thunderfang'],
        equals(BattleMoveVisualRecipeId.sdkThunderFang),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['airslash'],
        equals(BattleMoveVisualRecipeId.sdkExactAirSlash),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['dracometeor'],
        equals(BattleMoveVisualRecipeId.sdkDracoMeteor),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['hypervoice'],
        equals(BattleMoveVisualRecipeId.sdkHyperVoice),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['flashcannon'],
        equals(BattleMoveVisualRecipeId.sdkFlashCannon),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['dragonpulse'],
        equals(BattleMoveVisualRecipeId.sdkDragonPulse),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['sludgebomb'],
        equals(BattleMoveVisualRecipeId.sdkSludgeBomb),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['magicalleaf'],
        equals(BattleMoveVisualRecipeId.sdkMagicalLeaf),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['electroweb'],
        equals(BattleMoveVisualRecipeId.sdkElectroweb),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['bulletseed'],
        equals(BattleMoveVisualRecipeId.sdkBulletSeed),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['slam'],
        equals(BattleMoveVisualRecipeId.sdkSlam),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['spore'],
        equals(BattleMoveVisualRecipeId.sdkSpore),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['painsplit'],
        equals(BattleMoveVisualRecipeId.sdkPainSplit),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['skillswap'],
        equals(BattleMoveVisualRecipeId.sdkSkillSwap),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['quiverdance'],
        equals(BattleMoveVisualRecipeId.sdkQuiverDance),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['focusblast'],
        equals(BattleMoveVisualRecipeId.sdkFocusBlast),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['voltswitch'],
        equals(BattleMoveVisualRecipeId.sdkVoltSwitch),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['explosion'],
        equals(BattleMoveVisualRecipeId.sdkExplosion),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['hurricane'],
        equals(BattleMoveVisualRecipeId.sdkHurricane),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['bravebird'],
        equals(BattleMoveVisualRecipeId.sdkAerialAce),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['sunnyday'],
        equals(BattleMoveVisualRecipeId.sdkSunnyDay),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['hail'],
        equals(BattleMoveVisualRecipeId.sdkHail),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['electricterrain'],
        equals(BattleMoveVisualRecipeId.sdkElectricTerrain),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['grassyterrain'],
        equals(BattleMoveVisualRecipeId.sdkGrassyTerrain),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['mistyterrain'],
        equals(BattleMoveVisualRecipeId.sdkMistyTerrain),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['followme'],
        equals(BattleMoveVisualRecipeId.sdkFollowMe),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['kinesis'],
        equals(BattleMoveVisualRecipeId.sdkKinesis),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['solarbeam'],
        equals(BattleMoveVisualRecipeId.sdkSolarBeam),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['thunder'],
        equals(BattleMoveVisualRecipeId.sdkThunder),
      );
    });

    test('the 18 exact SDK Ruby ports resolve to exact recipe ids', () {
      const expectedExactRoutes = <String, BattleMoveVisualRecipeId>{
        'acidarmor': BattleMoveVisualRecipeId.sdkExactAcidArmor,
        'acrobatics': BattleMoveVisualRecipeId.sdkExactAcrobatics,
        'aerialace': BattleMoveVisualRecipeId.sdkExactAerialAce,
        'airslash': BattleMoveVisualRecipeId.sdkExactAirSlash,
        'aquaring': BattleMoveVisualRecipeId.sdkExactAquaRing,
        'aquatail': BattleMoveVisualRecipeId.sdkExactAquaTail,
        'assurance': BattleMoveVisualRecipeId.sdkExactAssurance,
        'astonish': BattleMoveVisualRecipeId.sdkExactAstonish,
        'avalanche': BattleMoveVisualRecipeId.sdkExactAvalanche,
        'karatechop': BattleMoveVisualRecipeId.sdkExactKarateChop,
        'leechseed': BattleMoveVisualRecipeId.sdkExactLeechSeed,
        'poisonpowder': BattleMoveVisualRecipeId.sdkExactPoisonPowder,
        'recover': BattleMoveVisualRecipeId.sdkExactRecover,
        'sleeppowder': BattleMoveVisualRecipeId.sdkExactSleepPowder,
        'stunspore': BattleMoveVisualRecipeId.sdkExactStunSpore,
        'tailwhip': BattleMoveVisualRecipeId.sdkExactTailWhip,
        'thunderwave': BattleMoveVisualRecipeId.sdkExactThunderWave,
        'vinewhip': BattleMoveVisualRecipeId.sdkExactVineWhip,
      };

      for (final entry in expectedExactRoutes.entries) {
        expect(
          BattleMoveVisualCatalog.recipeBySDKMoveId[entry.key],
          equals(entry.value),
          reason: entry.key,
        );
      }
    });

    test('exact Ruby source ids are limited to the 18 Ruby scripts', () {
      expect(
        BattleMoveVisualCatalog.exactRubySDKMoveIds,
        equals(<String>{
          'acidarmor',
          'acrobatics',
          'aerialace',
          'airslash',
          'aquaring',
          'aquatail',
          'assurance',
          'astonish',
          'avalanche',
          'karatechop',
          'leechseed',
          'poisonpowder',
          'recover',
          'sleeppowder',
          'stunspore',
          'tailwhip',
          'thunderwave',
          'vinewhip',
        }),
      );
    });

    test('active recipe ids do not use legacy showdown naming', () {
      for (final recipeId in BattleMoveVisualRecipeId.values) {
        expect(recipeId.name.toLowerCase(), isNot(startsWith('showdown')));
      }
    });

    test('direct recipe lookup exists for the new sdk wave bucket', () {
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['doomdesire'],
        equals(BattleMoveVisualRecipeId.sdkDoomDesire),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['seedflare'],
        equals(BattleMoveVisualRecipeId.sdkSeedFlare),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['icywind'],
        equals(BattleMoveVisualRecipeId.sdkIcyWind),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['weatherball'],
        equals(BattleMoveVisualRecipeId.sdkWeatherBall),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['scald'],
        equals(BattleMoveVisualRecipeId.sdkScald),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['triattack'],
        equals(BattleMoveVisualRecipeId.sdkTriAttack),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['clangingscales'],
        equals(BattleMoveVisualRecipeId.sdkClangingScales),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['flameburst'],
        equals(BattleMoveVisualRecipeId.sdkFlameBurst),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['steameruption'],
        equals(BattleMoveVisualRecipeId.sdkSteamEruption),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['watersport'],
        equals(BattleMoveVisualRecipeId.sdkWaterSport),
      );
    });

    test('direct guard and protect routings stay wired to the right families',
        () {
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['detect'],
        equals(BattleMoveVisualRecipeId.sdkProtect),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['kingsshield'],
        equals(BattleMoveVisualRecipeId.sdkProtect),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['spikyshield'],
        equals(BattleMoveVisualRecipeId.sdkProtect),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['endure'],
        equals(BattleMoveVisualRecipeId.sdkProtect),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['magiccoat'],
        equals(BattleMoveVisualRecipeId.sdkProtect),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['craftyshield'],
        equals(BattleMoveVisualRecipeId.sdkQuickGuard),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['matblock'],
        equals(BattleMoveVisualRecipeId.sdkQuickGuard),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['burningbulwark'],
        equals(BattleMoveVisualRecipeId.sdkBurningBulwark),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['banefulbunker'],
        equals(BattleMoveVisualRecipeId.sdkBanefulBunker),
      );
    });

    test('direct recipe lookup exists for psychic ghost and heal support wave',
        () {
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['storedpower'],
        equals(BattleMoveVisualRecipeId.sdkStoredPower),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['psychoboost'],
        equals(BattleMoveVisualRecipeId.sdkPsychoBoost),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['psyshock'],
        equals(BattleMoveVisualRecipeId.sdkPsyshock),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['hex'],
        equals(BattleMoveVisualRecipeId.sdkHex),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['willowisp'],
        equals(BattleMoveVisualRecipeId.sdkWillOWisp),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['lifedew'],
        equals(BattleMoveVisualRecipeId.sdkLifeDew),
      );
    });

    test(
        'direct recipe lookup exists for recovery cleanse and restoration wave',
        () {
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['aromatherapy'],
        equals(BattleMoveVisualRecipeId.sdkAromatherapy),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['rest'],
        equals(BattleMoveVisualRecipeId.sdkRest),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['ingrain'],
        equals(BattleMoveVisualRecipeId.sdkIngrain),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['morningsun'],
        equals(BattleMoveVisualRecipeId.sdkMorningSun),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['shoreup'],
        equals(BattleMoveVisualRecipeId.sdkShoreUp),
      );
    });

    test('direct recipe lookup exists for beam cannon star and meteor wave',
        () {
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['hyperbeam'],
        equals(BattleMoveVisualRecipeId.sdkHyperBeam),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['signalbeam'],
        equals(BattleMoveVisualRecipeId.sdkSignalBeam),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['fleurcannon'],
        equals(BattleMoveVisualRecipeId.sdkFleurCannon),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['armorcannon'],
        equals(BattleMoveVisualRecipeId.sdkArmorCannon),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['steelbeam'],
        equals(BattleMoveVisualRecipeId.sdkSteelBeam),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['beakblast'],
        equals(BattleMoveVisualRecipeId.sdkBeakBlast),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['twinbeam'],
        equals(BattleMoveVisualRecipeId.sdkTwinBeam),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['spikecannon'],
        equals(BattleMoveVisualRecipeId.sdkSpikeCannon),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['terastarstorm'],
        equals(BattleMoveVisualRecipeId.sdkTerastarStorm),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['meteormash'],
        equals(BattleMoveVisualRecipeId.sdkMeteorMash),
      );
    });

    test(
        'direct routings stay wired to psychic ghost and heal support families',
        () {
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['powertrip'],
        equals(BattleMoveVisualRecipeId.sdkStoredPower),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['psychicnoise'],
        equals(BattleMoveVisualRecipeId.sdkPsychoBoost),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['prismaticlaser'],
        equals(BattleMoveVisualRecipeId.sdkPsychoBoost),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['psystrike'],
        equals(BattleMoveVisualRecipeId.sdkPsyshock),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['nightshade'],
        equals(BattleMoveVisualRecipeId.sdkHex),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['ominouswind'],
        equals(BattleMoveVisualRecipeId.sdkHex),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['blackholeeclipse'],
        equals(BattleMoveVisualRecipeId.sdkHex),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['neverendingnightmare'],
        equals(BattleMoveVisualRecipeId.sdkHex),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['moongeistbeam'],
        equals(BattleMoveVisualRecipeId.sdkHex),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['astralbarrage'],
        equals(BattleMoveVisualRecipeId.sdkHex),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['soulstealing7starstrike'],
        equals(BattleMoveVisualRecipeId.sdkHex),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['healpulse'],
        equals(BattleMoveVisualRecipeId.sdkLifeDew),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['aquaring'],
        equals(BattleMoveVisualRecipeId.sdkExactAquaRing),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['softboiled'],
        equals(BattleMoveVisualRecipeId.sdkLifeDew),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['moonlight'],
        equals(BattleMoveVisualRecipeId.sdkLifeDew),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['lunarblessing'],
        equals(BattleMoveVisualRecipeId.sdkLifeDew),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['revivalblessing'],
        equals(BattleMoveVisualRecipeId.sdkLifeDew),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['recover'],
        equals(BattleMoveVisualRecipeId.sdkExactRecover),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['roost'],
        equals(BattleMoveVisualRecipeId.sdkLifeDew),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['healorder'],
        equals(BattleMoveVisualRecipeId.sdkLifeDew),
      );
    });

    test('direct routings stay wired to beam cannon star and meteor families',
        () {
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['blastburn'],
        equals(BattleMoveVisualRecipeId.sdkArmorCannon),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['chloroblast'],
        equals(BattleMoveVisualRecipeId.sdkFleurCannon),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['simplebeam'],
        equals(BattleMoveVisualRecipeId.sdkSignalBeam),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['maxstarfall'],
        equals(BattleMoveVisualRecipeId.sdkTerastarStorm),
      );
    });

    test(
        'direct recovery cleanse and restoration routings stay wired to seeded families',
        () {
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['healbell'],
        equals(BattleMoveVisualRecipeId.sdkAromatherapy),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['refresh'],
        equals(BattleMoveVisualRecipeId.sdkAromatherapy),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['swallow'],
        equals(BattleMoveVisualRecipeId.sdkRest),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['milkdrink'],
        equals(BattleMoveVisualRecipeId.sdkRest),
      );
    });

    test('direct drain siphon and absorb routings stay wired to custom recipes',
        () {
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['gigadrain'],
        equals(BattleMoveVisualRecipeId.sdkDrain),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['leechlife'],
        equals(BattleMoveVisualRecipeId.sdkLeechLife),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['drainingkiss'],
        equals(BattleMoveVisualRecipeId.sdkDrainingKiss),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['absorb'],
        equals(BattleMoveVisualRecipeId.sdkDrain),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['megadrain'],
        equals(BattleMoveVisualRecipeId.sdkDrain),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['hornleech'],
        equals(BattleMoveVisualRecipeId.sdkHornLeech),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['paraboliccharge'],
        equals(BattleMoveVisualRecipeId.sdkParabolicCharge),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['oblivionwing'],
        equals(BattleMoveVisualRecipeId.sdkOblivionWing),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['strengthsap'],
        equals(BattleMoveVisualRecipeId.sdkLeechLife),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['leechseed'],
        equals(BattleMoveVisualRecipeId.sdkExactLeechSeed),
      );
    });

    test(
        'direct impact kick and punch routings stay wired to dedicated recipes',
        () {
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['shadowpunch'],
        equals(BattleMoveVisualRecipeId.sdkShadowPunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['focuspunch'],
        equals(BattleMoveVisualRecipeId.sdkFocusPunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['drainpunch'],
        equals(BattleMoveVisualRecipeId.sdkDrainPunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['dynamicpunch'],
        equals(BattleMoveVisualRecipeId.sdkDynamicPunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['cometpunch'],
        equals(BattleMoveVisualRecipeId.sdkCometPunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['megapunch'],
        equals(BattleMoveVisualRecipeId.sdkMegaPunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['poweruppunch'],
        equals(BattleMoveVisualRecipeId.sdkPowerUpPunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['dizzypunch'],
        equals(BattleMoveVisualRecipeId.sdkDizzyPunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['jetpunch'],
        equals(BattleMoveVisualRecipeId.sdkJetPunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['firepunch'],
        equals(BattleMoveVisualRecipeId.sdkFirePunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['icepunch'],
        equals(BattleMoveVisualRecipeId.sdkIcePunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['thunderpunch'],
        equals(BattleMoveVisualRecipeId.sdkThunderPunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['blazekick'],
        equals(BattleMoveVisualRecipeId.sdkBlazeKick),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['thunderouskick'],
        equals(BattleMoveVisualRecipeId.sdkThunderousKick),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['tropkick'],
        equals(BattleMoveVisualRecipeId.sdkTropKick),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['bodyslam'],
        equals(BattleMoveVisualRecipeId.sdkBodySlam),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['heavyslam'],
        equals(BattleMoveVisualRecipeId.sdkBodySlam),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['bodypress'],
        equals(BattleMoveVisualRecipeId.sdkBodySlam),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['dragonhammer'],
        equals(BattleMoveVisualRecipeId.sdkBodySlam),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['jumpkick'],
        equals(BattleMoveVisualRecipeId.sdkHighJumpKick),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['highjumpkick'],
        equals(BattleMoveVisualRecipeId.sdkHighJumpKick),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['lowkick'],
        equals(BattleMoveVisualRecipeId.sdkHighJumpKick),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['circlethrow'],
        equals(BattleMoveVisualRecipeId.sdkHighJumpKick),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['axekick'],
        equals(BattleMoveVisualRecipeId.sdkHighJumpKick),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['megakick'],
        equals(BattleMoveVisualRecipeId.sdkHighJumpKick),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['karatechop'],
        equals(BattleMoveVisualRecipeId.sdkExactKarateChop),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['forcepalm'],
        equals(BattleMoveVisualRecipeId.sdkKarateChop),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['brickbreak'],
        equals(BattleMoveVisualRecipeId.sdkKarateChop),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['throatchop'],
        equals(BattleMoveVisualRecipeId.sdkKarateChop),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['stormthrow'],
        equals(BattleMoveVisualRecipeId.sdkKarateChop),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['vitalthrow'],
        equals(BattleMoveVisualRecipeId.sdkKarateChop),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['drillrun'],
        equals(BattleMoveVisualRecipeId.sdkDrillRun),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['hyperdrill'],
        equals(BattleMoveVisualRecipeId.sdkDrillRun),
      );
    });

    test('direct recipe lookup exists for projectile bomb wave', () {
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['gunkshot'],
        equals(BattleMoveVisualRecipeId.sdkGunkShot),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['mudshot'],
        equals(BattleMoveVisualRecipeId.sdkMudShot),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['electroball'],
        equals(BattleMoveVisualRecipeId.sdkElectroBall),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['rockblast'],
        equals(BattleMoveVisualRecipeId.sdkRockBlast),
      );
    });

    test('direct projectile bomb routings stay wired to seeded families', () {
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['sludge'],
        equals(BattleMoveVisualRecipeId.sdkGunkShot),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['acid'],
        equals(BattleMoveVisualRecipeId.sdkSmog),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['acidspray'],
        equals(BattleMoveVisualRecipeId.sdkSmog),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['belch'],
        equals(BattleMoveVisualRecipeId.sdkGunkShot),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['mudbomb'],
        equals(BattleMoveVisualRecipeId.sdkMudShot),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['mudslap'],
        equals(BattleMoveVisualRecipeId.sdkMudShot),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['thundershock'],
        equals(BattleMoveVisualRecipeId.sdkRmxpMoveAnimation),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['shockwave'],
        equals(BattleMoveVisualRecipeId.sdkRmxpMoveAnimation),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['smackdown'],
        equals(BattleMoveVisualRecipeId.sdkRockBlast),
      );
    });

    test('direct recipe lookup exists for poison toxic control wave', () {
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['toxic'],
        equals(BattleMoveVisualRecipeId.sdkToxic),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['toxicspikes'],
        equals(BattleMoveVisualRecipeId.sdkToxicSpikes),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['poisongas'],
        equals(BattleMoveVisualRecipeId.sdkPoisonGas),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['smog'],
        equals(BattleMoveVisualRecipeId.sdkSmog),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['clearsmog'],
        equals(BattleMoveVisualRecipeId.sdkClearSmog),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['poisonfang'],
        equals(BattleMoveVisualRecipeId.sdkPoisonFang),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['crosspoison'],
        equals(BattleMoveVisualRecipeId.sdkCrossPoison),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['direclaw'],
        equals(BattleMoveVisualRecipeId.sdkDireClaw),
      );
    });

    test('direct poison toxic control routings stay wired to seeded families',
        () {
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['venomdrench'],
        equals(BattleMoveVisualRecipeId.sdkSmog),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['belch'],
        equals(BattleMoveVisualRecipeId.sdkGunkShot),
      );
    });

    test('direct recipe lookup exists for sweeping wave storm and beam wave',
        () {
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['whirlwind'],
        equals(BattleMoveVisualRecipeId.sdkWhirlwind),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['freezedry'],
        equals(BattleMoveVisualRecipeId.sdkFreezeDry),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['magmastorm'],
        equals(BattleMoveVisualRecipeId.sdkMagmaStorm),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['originpulse'],
        equals(BattleMoveVisualRecipeId.sdkOriginPulse),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['psybeam'],
        equals(BattleMoveVisualRecipeId.sdkPsybeam),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['aeroblast'],
        equals(BattleMoveVisualRecipeId.sdkAeroblast),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['roaroftime'],
        equals(BattleMoveVisualRecipeId.sdkRoarOfTime),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['revelationdance'],
        equals(BattleMoveVisualRecipeId.sdkRevelationDance),
      );
    });

    test(
        'direct sweeping wave storm and beam routings stay wired to seeded families',
        () {
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['gust'],
        equals(BattleMoveVisualRecipeId.sdkWhirlwind),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['silverwind'],
        equals(BattleMoveVisualRecipeId.sdkWhirlwind),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['twister'],
        equals(BattleMoveVisualRecipeId.sdkWhirlwind),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['frostbreath'],
        equals(BattleMoveVisualRecipeId.sdkFreezeDry),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['glaciate'],
        equals(BattleMoveVisualRecipeId.sdkFreezeDry),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['fierydance'],
        equals(BattleMoveVisualRecipeId.sdkMagmaStorm),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['inferno'],
        equals(BattleMoveVisualRecipeId.sdkMagmaStorm),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['hydrovortex'],
        equals(BattleMoveVisualRecipeId.sdkOriginPulse),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['maxgeyser'],
        equals(BattleMoveVisualRecipeId.sdkOriginPulse),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['gmaxcannonade'],
        equals(BattleMoveVisualRecipeId.sdkOriginPulse),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['gmaxhydrosnipe'],
        equals(BattleMoveVisualRecipeId.sdkOriginPulse),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['psywave'],
        equals(BattleMoveVisualRecipeId.sdkPsybeam),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['expandingforce'],
        equals(BattleMoveVisualRecipeId.sdkPsybeam),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['terablastflying'],
        equals(BattleMoveVisualRecipeId.sdkAeroblast),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['eternabeam'],
        equals(BattleMoveVisualRecipeId.sdkRoarOfTime),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['pollenpuff'],
        equals(BattleMoveVisualRecipeId.sdkRevelationDance),
      );
    });

    test('direct self-buff routings stay wired to seeded setup families', () {
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['focusenergy'],
        equals(BattleMoveVisualRecipeId.sdkBulkUp),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['harden'],
        equals(BattleMoveVisualRecipeId.sdkReflect),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['defensecurl'],
        equals(BattleMoveVisualRecipeId.sdkReflect),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['irondefense'],
        equals(BattleMoveVisualRecipeId.sdkReflect),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['cottonguard'],
        equals(BattleMoveVisualRecipeId.sdkReflect),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['defendorder'],
        equals(BattleMoveVisualRecipeId.sdkReflect),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['barrier'],
        equals(BattleMoveVisualRecipeId.sdkReflect),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['howl'],
        equals(BattleMoveVisualRecipeId.sdkBulkUp),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['meditate'],
        equals(BattleMoveVisualRecipeId.sdkBulkUp),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['sharpen'],
        equals(BattleMoveVisualRecipeId.sdkSwordsDance),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['charge'],
        equals(BattleMoveVisualRecipeId.sdkCalmMind),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['luckychant'],
        equals(BattleMoveVisualRecipeId.sdkCalmMind),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['rockpolish'],
        equals(BattleMoveVisualRecipeId.sdkAgility),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['autotomize'],
        equals(BattleMoveVisualRecipeId.sdkAgility),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['shiftgear'],
        equals(BattleMoveVisualRecipeId.sdkAgility),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['magnetrise'],
        equals(BattleMoveVisualRecipeId.sdkAgility),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['minimize'],
        equals(BattleMoveVisualRecipeId.sdkAgility),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['growth'],
        equals(BattleMoveVisualRecipeId.sdkCalmMind),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['tailglow'],
        equals(BattleMoveVisualRecipeId.sdkQuiverDance),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['cosmicpower'],
        equals(BattleMoveVisualRecipeId.sdkCalmMind),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['geomancy'],
        equals(BattleMoveVisualRecipeId.sdkQuiverDance),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['chargeup'],
        equals(BattleMoveVisualRecipeId.sdkCalmMind),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['gearup'],
        equals(BattleMoveVisualRecipeId.sdkAgility),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['flowershield'],
        equals(BattleMoveVisualRecipeId.sdkReflect),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['laserfocus'],
        equals(BattleMoveVisualRecipeId.sdkBulkUp),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['honeclaws'],
        equals(BattleMoveVisualRecipeId.sdkSwordsDance),
      );
    });

    test('high-value sdk aliases stay wired to seeded families', () {
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['waterfall'],
        equals('aquajet'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['bulletpunch'],
        equals('machpunch'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['wringout'],
        equals('forcepalm'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['wideguard'],
        equals('quickguard'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['surgingstrikes'],
        equals('aquajet'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['volttackle'],
        equals('wildcharge'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['heatcrash'],
        equals('flareblitz'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['nuzzle'],
        equals('spark'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['terablastelectric'],
        equals('thunderbolt'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['comeuppance'],
        equals('darkpulse'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['boltbeak'],
        equals('spark'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['mysticalfire'],
        equals('flamethrower'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['terablastpsychic'],
        equals('psychic'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['jawlock'],
        equals('crunch'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['shellsidearmphysical'],
        equals('poisonjab'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['ceaselessedge'],
        equals('nightslash'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['doubleedge'],
        equals('gigaimpact'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['vinewhip'],
        equals('powerwhip'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['liquidation'],
        equals('crabhammer'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['aurawheel'],
        equals('discharge'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['behemothblade'],
        equals('smartstrike'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['hornattack'],
        equals('megahorn'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['breakingswipe'],
        equals('dragonclaw'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['psyblade'],
        equals('psychocut'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['chillingwater'],
        equals('waterpulse'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['mountaingale'],
        equals('powergem'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['burningjealousy'],
        equals('heatwave'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['paleowave'],
        equals('muddywater'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['scorchingsands'],
        equals('earthpower'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['terablastbug'],
        equals('bugbuzz'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['hydrocannon'],
        equals('hydropump'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['terablastwater'],
        equals('hydropump'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['razorwind'],
        equals('airslash'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['terablaststellar'],
        equals('dracometeor'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['chatter'],
        equals('hypervoice'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['echoedvoice'],
        equals('hypervoice'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['mirrorshot'],
        equals('flashcannon'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['terablaststeel'],
        equals('flashcannon'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['dynamaxcannon'],
        equals('dragonpulse'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['terablastdragon'],
        equals('dragonpulse'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['venoshock'],
        equals('sludgebomb'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['poisonpowder'],
        equals('spore'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['poisontail'],
        equals('poisonjab'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['gastroacid'],
        equals('toxic'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['corrosivegas'],
        equals('poisongas'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['terablastpoison'],
        equals('sludgebomb'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['razorleaf'],
        equals('magicalleaf'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['grasspledge'],
        equals('magicalleaf'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['spiderweb'],
        equals('electroweb'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['toxicthread'],
        equals('electroweb'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['pinmissile'],
        equals('bulletseed'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['attackorder'],
        equals('bulletseed'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['beatup'],
        equals('slam'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['rockclimb'],
        equals('slam'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['sleeppowder'],
        equals('spore'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['magicpowder'],
        equals('spore'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['psychoshift'],
        equals('painsplit'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['reflecttype'],
        equals('painsplit'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['gmaxfinale'],
        equals('maxstarfall'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['gmaxsmite'],
        equals('maxstarfall'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['guardsplit'],
        equals('skillswap'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['courtchange'],
        equals('skillswap'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['selfdestruct'],
        equals('explosion'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['mindblown'],
        equals('explosion'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['drillpeck'],
        equals('bravebird'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['bleakwindstorm'],
        equals('hurricane'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['dragonenergy'],
        equals('dragonbreath'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['futuresight'],
        equals('doomdesire'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['powdersnow'],
        equals('icywind'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['purify'],
        equals('weatherball'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['10000000voltthunderbolt'],
        equals('s10000000voltthunderbolt'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['dragondarts'],
        equals('dragonbreath'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['pyroball'],
        equals('flameburst'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['scaleshot'],
        equals('clangingscales'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['terablast'],
        equals('scald'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['terablastgrass'],
        equals('seedflare'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['hydrosteam'],
        equals('steameruption'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['watergun'],
        equals('watersport'),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['snowscape'],
        equals(BattleMoveVisualRecipeId.sdkHail),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['magicroom'],
        equals(BattleMoveVisualRecipeId.sdkTrickRoom),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['wonderroom'],
        equals(BattleMoveVisualRecipeId.sdkTrickRoom),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['babydolleyes'],
        equals(BattleMoveVisualRecipeId.sdkBabyDollEyes),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['junglehealing'],
        equals(BattleMoveVisualRecipeId.sdkGrassyTerrain),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['technoblast'],
        equals(BattleMoveVisualRecipeId.sdkFocusBlast),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['flamecharge'],
        equals(BattleMoveVisualRecipeId.sdkFlareBlitz),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['leafstorm'],
        equals(BattleMoveVisualRecipeId.sdkMagicalLeaf),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['sludgewave'],
        equals(BattleMoveVisualRecipeId.sdkSludgeBomb),
      );
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['zapcannon'],
        equals(BattleMoveVisualRecipeId.sdkThunder),
      );
    });

    test('direct recipe lookup exists for the sdk impact bucket', () {
      const expectedRoutes = <String, BattleMoveVisualRecipeId>{
        'woodhammer': BattleMoveVisualRecipeId.sdkWoodHammer,
        'ivycudgel': BattleMoveVisualRecipeId.sdkIvyCudgel,
        'ivycudgelwater': BattleMoveVisualRecipeId.sdkIvyCudgelWater,
        'ivycudgelfire': BattleMoveVisualRecipeId.sdkIvyCudgelFire,
        'ivycudgelrock': BattleMoveVisualRecipeId.sdkIvyCudgelRock,
        'cut': BattleMoveVisualRecipeId.sdkCut,
        'shadowclaw': BattleMoveVisualRecipeId.sdkShadowClaw,
        'multiattack': BattleMoveVisualRecipeId.sdkMultiAttack,
        'bite': BattleMoveVisualRecipeId.sdkBite,
        'superfang': BattleMoveVisualRecipeId.sdkSuperFang,
        'bugbite': BattleMoveVisualRecipeId.sdkBugBite,
        'psychicfangs': BattleMoveVisualRecipeId.sdkPsychicFangs,
        'ironhead': BattleMoveVisualRecipeId.sdkIronHead,
        'headbutt': BattleMoveVisualRecipeId.sdkHeadbutt,
        'stomp': BattleMoveVisualRecipeId.sdkStomp,
        'hammerarm': BattleMoveVisualRecipeId.sdkHammerArm,
        'icehammer': BattleMoveVisualRecipeId.sdkIceHammer,
        'skyuppercut': BattleMoveVisualRecipeId.sdkSkyUppercut,
        'needlearm': BattleMoveVisualRecipeId.sdkNeedleArm,
        'rocksmash': BattleMoveVisualRecipeId.sdkRockSmash,
      };

      for (final entry in expectedRoutes.entries) {
        expect(
          BattleMoveVisualCatalog.recipeBySDKMoveId[entry.key],
          equals(entry.value),
          reason: entry.key,
        );
      }
    });

    test('safe sdk aliases route into the impact bucket', () {
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['highhorsepower'],
        equals('stomp'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['hyperfang'],
        equals('superfang'),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['firelash'],
        equals('multiattack'),
      );
    });

    test('direct recipe lookup exists for the sdk catch-up roots wave', () {
      const expectedRoutes = <String, BattleMoveVisualRecipeId>{
        'ragepowder': BattleMoveVisualRecipeId.sdkFollowMe,
        'wish': BattleMoveVisualRecipeId.sdkLifeDew,
        'nobleroar': BattleMoveVisualRecipeId.sdkGrowl,
        'swagger': BattleMoveVisualRecipeId.sdkSwagger,
        'shelltrap': BattleMoveVisualRecipeId.sdkMagmaStorm,
        'outrage': BattleMoveVisualRecipeId.sdkDragonClaw,
        'bind': BattleMoveVisualRecipeId.sdkPowerWhip,
        'petaldance': BattleMoveVisualRecipeId.sdkMagicalLeaf,
        'fusionflare': BattleMoveVisualRecipeId.sdkFireBlast,
        'gigavolthavoc': BattleMoveVisualRecipeId.sdkThunderbolt,
        'alloutpummeling': BattleMoveVisualRecipeId.sdkCloseCombat,
        'supersonicskystrike': BattleMoveVisualRecipeId.sdkHurricane,
        'aciddownpour': BattleMoveVisualRecipeId.sdkSludgeBomb,
        'torchsong': BattleMoveVisualRecipeId.sdkFireBlast,
        'iceball': BattleMoveVisualRecipeId.sdkFreezeDry,
        'anchorshot': BattleMoveVisualRecipeId.sdkSpikeCannon,
        'diamondstorm': BattleMoveVisualRecipeId.sdkPowerGem,
        'twinkletackle': BattleMoveVisualRecipeId.sdkPlayRough,
        'headlongrush': BattleMoveVisualRecipeId.sdkEarthquake,
        'crushclaw': BattleMoveVisualRecipeId.sdkShadowClaw,
        'falseswipe': BattleMoveVisualRecipeId.sdkCut,
        'bitterblade': BattleMoveVisualRecipeId.sdkLeafBlade,
        'secretsword': BattleMoveVisualRecipeId.sdkPsychoCut,
      };

      for (final entry in expectedRoutes.entries) {
        expect(
          BattleMoveVisualCatalog.recipeBySDKMoveId[entry.key],
          equals(entry.value),
          reason: entry.key,
        );
      }
    });

    test('exact sdk alias chains route through the catch-up wave', () {
      const expectedAliases = <String, String>{
        'torment': 'swagger',
        'searingshot': 'shelltrap',
        'magikarpsrevenge': 'outrage',
        'wakeupslap': 'smellingsalts',
        'frustration': 'thrash',
        'bonerush': 'boneclub',
        'shadowstrike': 'shadowforce',
        'phantomforce': 'shadowforce',
        'nightmare': 'nightshade',
        'dreameater': 'drainingkiss',
        'maxphantasm': 'neverendingnightmare',
        'maxlightning': 'gigavolthavoc',
        'maxquake': 'tectonicrage',
        'maxstrike': 'breakneckblitz',
        'maxmindstorm': 'shatteredpsyche',
        'maxrockfall': 'continentalcrush',
        'falsesurrender': 'feintattack',
        'steelroller': 'steamroller',
        'tripledive': 'dive',
        'polarflare': 'torchsong',
        'mistball': 'iceball',
        'fusionbolt': 'boltstrike',
        'wildboltstorm': 'boltstrike',
        'holdhands': 'painsplit',
        'seedbomb': 'bulletseed',
        'syrupbomb': 'sludgebomb',
        'shelter': 'withdraw',
      };

      for (final entry in expectedAliases.entries) {
        expect(
          BattleMoveVisualCatalog.aliasBySDKMoveId[entry.key],
          equals(entry.value),
          reason: entry.key,
        );
      }
    });

    test('direct recipe lookup exists for the fidelity catch-up wave', () {
      const expectedRoutes = <String, BattleMoveVisualRecipeId>{
        'taunt': BattleMoveVisualRecipeId.sdkTaunt,
        'doubleteam': BattleMoveVisualRecipeId.sdkAgility,
        'teleport': BattleMoveVisualRecipeId.sdkAgility,
        'nastyplot': BattleMoveVisualRecipeId.sdkCalmMind,
        'haze': BattleMoveVisualRecipeId.sdkMist,
        'sing': BattleMoveVisualRecipeId.sdkHyperVoice,
        'snarl': BattleMoveVisualRecipeId.sdkDarkPulse,
        'holdback': BattleMoveVisualRecipeId.sdkTackle,
        'irontail': BattleMoveVisualRecipeId.sdkIronHead,
        'reversal': BattleMoveVisualRecipeId.sdkCloseCombat,
        'fakeout': BattleMoveVisualRecipeId.sdkQuickAttack,
        'shadowsneak': BattleMoveVisualRecipeId.sdkShadowPunch,
        'geargrind': BattleMoveVisualRecipeId.sdkSpikeCannon,
        'ancientpower': BattleMoveVisualRecipeId.sdkPowerGem,
        'vacuumwave': BattleMoveVisualRecipeId.sdkAuraSphere,
        'firespin': BattleMoveVisualRecipeId.sdkMagmaStorm,
        'wavecrash': BattleMoveVisualRecipeId.sdkOriginPulse,
      };

      for (final entry in expectedRoutes.entries) {
        expect(
          BattleMoveVisualCatalog.recipeBySDKMoveId[entry.key],
          equals(entry.value),
          reason: entry.key,
        );
      }
    });

    test('direct fidelity wave keeps representative buckets aligned', () {
      const expectedRoutes = <String, BattleMoveVisualRecipeId>{
        'supersonic': BattleMoveVisualRecipeId.sdkConfuseRay,
        'metalsound': BattleMoveVisualRecipeId.sdkGrowl,
        'thief': BattleMoveVisualRecipeId.sdkNightSlash,
        'tailslap': BattleMoveVisualRecipeId.sdkDoubleHit,
        'iciclespear': BattleMoveVisualRecipeId.sdkBulletSeed,
        'burnup': BattleMoveVisualRecipeId.sdkFlamethrower,
        'freezingglare': BattleMoveVisualRecipeId.sdkFreezeDry,
        'thundercage': BattleMoveVisualRecipeId.sdkChargeBeam,
      };

      for (final entry in expectedRoutes.entries) {
        expect(
          BattleMoveVisualCatalog.recipeBySDKMoveId[entry.key],
          equals(entry.value),
          reason: entry.key,
        );
      }
    });

    test('second fidelity wave keeps setup and signature buckets aligned', () {
      const expectedRoutes = <String, BattleMoveVisualRecipeId>{
        'allyswitch': BattleMoveVisualRecipeId.sdkAgility,
        'transform': BattleMoveVisualRecipeId.sdkSkillSwap,
        'bellydrum': BattleMoveVisualRecipeId.sdkBulkUp,
        'shellsmash': BattleMoveVisualRecipeId.sdkQuiverDance,
        'stickyweb': BattleMoveVisualRecipeId.sdkElectroweb,
        'makeitrain': BattleMoveVisualRecipeId.sdkFlashCannon,
        'waterspout': BattleMoveVisualRecipeId.sdkOriginPulse,
        'solarblade': BattleMoveVisualRecipeId.sdkLeafBlade,
        'glaciallance': BattleMoveVisualRecipeId.sdkIceHammer,
        'spacialrend': BattleMoveVisualRecipeId.sdkDracoMeteor,
        'dragonascent': BattleMoveVisualRecipeId.sdkAerialAce,
      };

      for (final entry in expectedRoutes.entries) {
        expect(
          BattleMoveVisualCatalog.recipeBySDKMoveId[entry.key],
          equals(entry.value),
          reason: entry.key,
        );
      }
    });

    test('third fidelity wave keeps signature finishers aligned', () {
      const expectedRoutes = <String, BattleMoveVisualRecipeId>{
        'avalanche': BattleMoveVisualRecipeId.sdkExactAvalanche,
        'fierywrath': BattleMoveVisualRecipeId.sdkDarkPulse,
        'terrainpulse': BattleMoveVisualRecipeId.sdkWeatherBall,
        'flowertrick': BattleMoveVisualRecipeId.sdkLeafBlade,
        'tripleaxel': BattleMoveVisualRecipeId.sdkDoubleKick,
        'firstimpression': BattleMoveVisualRecipeId.sdkQuickAttack,
        'plasmafists': BattleMoveVisualRecipeId.sdkThunderPunch,
        'electrodrift': BattleMoveVisualRecipeId.sdkWildCharge,
        'photongeyser': BattleMoveVisualRecipeId.sdkPsychic,
        'clangoroussoulblaze': BattleMoveVisualRecipeId.sdkClangingScales,
        'thunderclap': BattleMoveVisualRecipeId.sdkSpark,
        'magicaltorque': BattleMoveVisualRecipeId.sdkPlayRough,
      };

      for (final entry in expectedRoutes.entries) {
        expect(
          BattleMoveVisualCatalog.recipeBySDKMoveId[entry.key],
          equals(entry.value),
          reason: entry.key,
        );
      }
    });

    test('final catch-up wave keeps the last safe mappings aligned', () {
      const expectedRoutes = <String, BattleMoveVisualRecipeId>{
        'instruct': BattleMoveVisualRecipeId.sdkInstruct,
        'hiddenpower': BattleMoveVisualRecipeId.sdkHiddenPower,
        'watershuriken': BattleMoveVisualRecipeId.sdkWaterShuriken,
        'slash': BattleMoveVisualRecipeId.sdkSlash,
        'judgment': BattleMoveVisualRecipeId.sdkFocusBlast,
        'gmaxsteelsurge': BattleMoveVisualRecipeId.sdkFlashCannon,
        'saltcure': BattleMoveVisualRecipeId.sdkStealthRock,
        'swift': BattleMoveVisualRecipeId.sdkRmxpMoveAnimation,
        'guardianofalola': BattleMoveVisualRecipeId.sdkMoonBlast,
      };

      for (final entry in expectedRoutes.entries) {
        expect(
          BattleMoveVisualCatalog.recipeBySDKMoveId[entry.key],
          equals(entry.value),
          reason: entry.key,
        );
      }
    });

    test('retuned sdk numeric variants route to adapted base visuals', () {
      const expectedAliases = <String, String>{
        'aciddownpour2': 'aciddownpour',
        'alloutpummeling2': 'alloutpummeling',
        'blackholeeclipse2': 'blackholeeclipse',
        'bloomdoom2': 'bloomdoom',
        'breakneckblitz2': 'breakneckblitz',
        'continentalcrush2': 'continentalcrush',
        'corkscrewcrash2': 'corkscrewcrash',
        'devastatingdrake2': 'devastatingdrake',
        'gigavolthavoc2': 'gigavolthavoc',
        'hydrovortex2': 'hydrovortex',
        'infernooverdrive2': 'infernooverdrive',
        'neverendingnightmare2': 'neverendingnightmare',
        'savagespinout2': 'savagespinout',
        'shatteredpsyche2': 'shatteredpsyche',
        'subzeroslammer2': 'subzeroslammer',
        'supersonicskystrike2': 'supersonicskystrike',
        'tectonicrage2': 'tectonicrage',
        'twinkletackle2': 'twinkletackle',
      };

      for (final entry in expectedAliases.entries) {
        expect(
          BattleMoveVisualCatalog.aliasBySDKMoveId[entry.key],
          equals(entry.value),
          reason: entry.key,
        );
      }
      expect(
        BattleMoveVisualCatalog.recipeBySDKMoveId['s10000000voltthunderbolt'],
        equals(BattleMoveVisualRecipeId.sdkThunderbolt),
      );
      expect(
        BattleMoveVisualCatalog.aliasBySDKMoveId['10000000voltthunderbolt'],
        equals('s10000000voltthunderbolt'),
      );
    });

    test('sdk ids without RMXP coverage stay explicitly adapted', () {
      const expectedRoutes = <String, BattleMoveVisualRecipeId>{
        'aciddownpour': BattleMoveVisualRecipeId.sdkSludgeBomb,
        'alloutpummeling': BattleMoveVisualRecipeId.sdkCloseCombat,
        'blackholeeclipse': BattleMoveVisualRecipeId.sdkHex,
        'bloomdoom': BattleMoveVisualRecipeId.sdkMagicalLeaf,
        'breakneckblitz': BattleMoveVisualRecipeId.sdkGigaImpact,
        'catastropika': BattleMoveVisualRecipeId.sdkThunderbolt,
        'clangoroussoulblaze': BattleMoveVisualRecipeId.sdkClangingScales,
        'continentalcrush': BattleMoveVisualRecipeId.sdkRockSlide,
        'corkscrewcrash': BattleMoveVisualRecipeId.sdkSmartStrike,
        'devastatingdrake': BattleMoveVisualRecipeId.sdkDragonPulse,
        'extremeevoboost': BattleMoveVisualRecipeId.sdkQuiverDance,
        'genesissupernova': BattleMoveVisualRecipeId.sdkPsychoBoost,
        'gigavolthavoc': BattleMoveVisualRecipeId.sdkThunderbolt,
        'guardianofalola': BattleMoveVisualRecipeId.sdkMoonBlast,
        'hydrovortex': BattleMoveVisualRecipeId.sdkOriginPulse,
        'infernooverdrive': BattleMoveVisualRecipeId.sdkFireBlast,
        'letssnuggleforever': BattleMoveVisualRecipeId.sdkPlayRough,
        'lightthatburnsthesky': BattleMoveVisualRecipeId.sdkFireBlast,
        'maliciousmoonsault': BattleMoveVisualRecipeId.sdkBodySlam,
        'menacingmoonrazemaelstrom': BattleMoveVisualRecipeId.sdkHex,
        'mindblown': BattleMoveVisualRecipeId.sdkExplosion,
        'neverendingnightmare': BattleMoveVisualRecipeId.sdkHex,
        'oceanicoperetta': BattleMoveVisualRecipeId.sdkOriginPulse,
        'photongeyser': BattleMoveVisualRecipeId.sdkPsychic,
        'plasmafists': BattleMoveVisualRecipeId.sdkThunderPunch,
        'pulverizingpancake': BattleMoveVisualRecipeId.sdkBodySlam,
        'savagespinout': BattleMoveVisualRecipeId.sdkElectroweb,
        'searingsunrazesmash': BattleMoveVisualRecipeId.sdkFlareBlitz,
        'shatteredpsyche': BattleMoveVisualRecipeId.sdkPsychic,
        'sinisterarrowraid': BattleMoveVisualRecipeId.sdkNightSlash,
        'soulstealing7starstrike': BattleMoveVisualRecipeId.sdkHex,
        'splinteredstormshards': BattleMoveVisualRecipeId.sdkRockSlide,
        'stokedsparksurfer': BattleMoveVisualRecipeId.sdkThunderbolt,
        'subzeroslammer': BattleMoveVisualRecipeId.sdkBlizzard,
        'supersonicskystrike': BattleMoveVisualRecipeId.sdkHurricane,
        'tectonicrage': BattleMoveVisualRecipeId.sdkEarthquake,
        'twinkletackle': BattleMoveVisualRecipeId.sdkPlayRough,
      };

      for (final entry in expectedRoutes.entries) {
        expect(
          BattleMoveVisualCatalog.recipeBySDKMoveId[entry.key],
          equals(entry.value),
          reason: entry.key,
        );
        expect(
          BattleMoveVisualCatalog.adaptedSDKMoveIds,
          contains(entry.key),
        );
      }
    });

    test('final bespoke seven now resolve to dedicated direct recipes', () {
      const expectedRoutes = <String, BattleMoveVisualRecipeId>{
        'splash': BattleMoveVisualRecipeId.sdkSplash,
        'celebrate': BattleMoveVisualRecipeId.sdkCelebrate,
        'orderup': BattleMoveVisualRecipeId.sdkOrderUp,
        'heartstamp': BattleMoveVisualRecipeId.sdkHeartStamp,
        'matchagotcha': BattleMoveVisualRecipeId.sdkMatchaGotcha,
        'present': BattleMoveVisualRecipeId.sdkPresent,
        'payday': BattleMoveVisualRecipeId.sdkPayDay,
      };

      for (final entry in expectedRoutes.entries) {
        expect(
          BattleMoveVisualCatalog.recipeBySDKMoveId[entry.key],
          equals(entry.value),
          reason: entry.key,
        );
      }
    });

    test(
        'fidelity support wave promotes taunt-style utility moves to bespoke recipes',
        () {
      const expectedRoutes = <String, BattleMoveVisualRecipeId>{
        'taunt': BattleMoveVisualRecipeId.sdkTaunt,
        'instruct': BattleMoveVisualRecipeId.sdkInstruct,
        'quash': BattleMoveVisualRecipeId.sdkQuash,
        'swagger': BattleMoveVisualRecipeId.sdkSwagger,
        'encore': BattleMoveVisualRecipeId.sdkEncore,
        'babydolleyes': BattleMoveVisualRecipeId.sdkBabyDollEyes,
      };

      for (final entry in expectedRoutes.entries) {
        expect(
          BattleMoveVisualCatalog.recipeBySDKMoveId[entry.key],
          equals(entry.value),
          reason: entry.key,
        );
      }
    });

    test('aliases point to existing ids', () {
      for (final aliasTarget
          in BattleMoveVisualCatalog.aliasBySDKMoveId.values) {
        expect(
          BattleMoveVisualCatalog.recipeBySDKMoveId.containsKey(
                aliasTarget,
              ) ||
              BattleMoveVisualCatalog.aliasBySDKMoveId.containsKey(
                aliasTarget,
              ),
          isTrue,
          reason: aliasTarget,
        );
      }
    });

    test('no alias loop', () {
      for (final start in BattleMoveVisualCatalog.aliasBySDKMoveId.keys) {
        final visited = <String>{};
        var current = start;
        while (true) {
          expect(visited.add(current), isTrue, reason: current);
          final next = BattleMoveVisualCatalog.aliasBySDKMoveId[current];
          if (next == null) {
            break;
          }
          current = next;
        }
      }
    });

    test('explicit no-animation ids are disjoint from direct recipe ids', () {
      expect(
        BattleMoveVisualCatalog.explicitNoAnimationSDKIds.any(
          BattleMoveVisualCatalog.recipeBySDKMoveId.containsKey,
        ),
        isFalse,
      );
    });

    test('explicit no-animation list is empty after the bespoke final wave',
        () {
      expect(BattleMoveVisualCatalog.explicitNoAnimationSDKIds, isEmpty);
    });
  });
}
