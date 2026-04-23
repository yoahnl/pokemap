import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_visual_catalog.dart';

void main() {
  group('BattleMoveVisualCatalog', () {
    test('direct recipe lookup exists for seeded moves', () {
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['tackle'],
        equals(BattleMoveVisualRecipeId.showdownTackle),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['scratch'],
        equals(BattleMoveVisualRecipeId.showdownScratch),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['quickattack'],
        equals(BattleMoveVisualRecipeId.showdownQuickAttack),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['thunderbolt'],
        equals(BattleMoveVisualRecipeId.showdownThunderbolt),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['shadowball'],
        equals(BattleMoveVisualRecipeId.showdownShadowBall),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['protect'],
        equals(BattleMoveVisualRecipeId.showdownProtect),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['burningbulwark'],
        equals(BattleMoveVisualRecipeId.showdownBurningBulwark),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['banefulbunker'],
        equals(BattleMoveVisualRecipeId.showdownBanefulBunker),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['growl'],
        equals(BattleMoveVisualRecipeId.showdownGrowl),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['thunderwave'],
        equals(BattleMoveVisualRecipeId.showdownThunderWave),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['raindance'],
        equals(BattleMoveVisualRecipeId.showdownRainDance),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['sandstorm'],
        equals(BattleMoveVisualRecipeId.showdownSandstorm),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['trickroom'],
        equals(BattleMoveVisualRecipeId.showdownTrickRoom),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['reflect'],
        equals(BattleMoveVisualRecipeId.showdownReflect),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['lightscreen'],
        equals(BattleMoveVisualRecipeId.showdownLightScreen),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['mist'],
        equals(BattleMoveVisualRecipeId.showdownMist),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['auroraveil'],
        equals(BattleMoveVisualRecipeId.showdownAuroraVeil),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['aquajet'],
        equals(BattleMoveVisualRecipeId.showdownAquaJet),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['extremespeed'],
        equals(BattleMoveVisualRecipeId.showdownExtremeSpeed),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['machpunch'],
        equals(BattleMoveVisualRecipeId.showdownMachPunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['spark'],
        equals(BattleMoveVisualRecipeId.showdownSpark),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['wildcharge'],
        equals(BattleMoveVisualRecipeId.showdownWildCharge),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['flareblitz'],
        equals(BattleMoveVisualRecipeId.showdownFlareBlitz),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['accelerock'],
        equals(BattleMoveVisualRecipeId.showdownAccelerock),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['wickedblow'],
        equals(BattleMoveVisualRecipeId.showdownWickedBlow),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['doublehit'],
        equals(BattleMoveVisualRecipeId.showdownDoubleHit),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['crunch'],
        equals(BattleMoveVisualRecipeId.showdownCrunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['flamethrower'],
        equals(BattleMoveVisualRecipeId.showdownFlamethrower),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['icebeam'],
        equals(BattleMoveVisualRecipeId.showdownIceBeam),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['psychic'],
        equals(BattleMoveVisualRecipeId.showdownPsychic),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['moonblast'],
        equals(BattleMoveVisualRecipeId.showdownMoonBlast),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['poisonjab'],
        equals(BattleMoveVisualRecipeId.showdownPoisonJab),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['earthquake'],
        equals(BattleMoveVisualRecipeId.showdownEarthquake),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['energyball'],
        equals(BattleMoveVisualRecipeId.showdownEnergyBall),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['rockslide'],
        equals(BattleMoveVisualRecipeId.showdownRockSlide),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['nightslash'],
        equals(BattleMoveVisualRecipeId.showdownNightSlash),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['gigaimpact'],
        equals(BattleMoveVisualRecipeId.showdownGigaImpact),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['powerwhip'],
        equals(BattleMoveVisualRecipeId.showdownPowerWhip),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['crabhammer'],
        equals(BattleMoveVisualRecipeId.showdownCrabHammer),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['discharge'],
        equals(BattleMoveVisualRecipeId.showdownDischarge),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['smartstrike'],
        equals(BattleMoveVisualRecipeId.showdownSmartStrike),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['megahorn'],
        equals(BattleMoveVisualRecipeId.showdownMegaHorn),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['dragonclaw'],
        equals(BattleMoveVisualRecipeId.showdownDragonClaw),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['psychocut'],
        equals(BattleMoveVisualRecipeId.showdownPsychoCut),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['waterpulse'],
        equals(BattleMoveVisualRecipeId.showdownWaterPulse),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['powergem'],
        equals(BattleMoveVisualRecipeId.showdownPowerGem),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['heatwave'],
        equals(BattleMoveVisualRecipeId.showdownHeatWave),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['muddywater'],
        equals(BattleMoveVisualRecipeId.showdownMuddyWater),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['earthpower'],
        equals(BattleMoveVisualRecipeId.showdownEarthPower),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['bugbuzz'],
        equals(BattleMoveVisualRecipeId.showdownBugBuzz),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['playrough'],
        equals(BattleMoveVisualRecipeId.showdownPlayRough),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['surf'],
        equals(BattleMoveVisualRecipeId.showdownSurf),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['hydropump'],
        equals(BattleMoveVisualRecipeId.showdownHydroPump),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['leafblade'],
        equals(BattleMoveVisualRecipeId.showdownLeafBlade),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['xscissor'],
        equals(BattleMoveVisualRecipeId.showdownXScissor),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['firefang'],
        equals(BattleMoveVisualRecipeId.showdownFireFang),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['icefang'],
        equals(BattleMoveVisualRecipeId.showdownIceFang),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['thunderfang'],
        equals(BattleMoveVisualRecipeId.showdownThunderFang),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['airslash'],
        equals(BattleMoveVisualRecipeId.showdownAirSlash),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['dracometeor'],
        equals(BattleMoveVisualRecipeId.showdownDracoMeteor),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['hypervoice'],
        equals(BattleMoveVisualRecipeId.showdownHyperVoice),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['flashcannon'],
        equals(BattleMoveVisualRecipeId.showdownFlashCannon),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['dragonpulse'],
        equals(BattleMoveVisualRecipeId.showdownDragonPulse),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['sludgebomb'],
        equals(BattleMoveVisualRecipeId.showdownSludgeBomb),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['magicalleaf'],
        equals(BattleMoveVisualRecipeId.showdownMagicalLeaf),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['electroweb'],
        equals(BattleMoveVisualRecipeId.showdownElectroweb),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['bulletseed'],
        equals(BattleMoveVisualRecipeId.showdownBulletSeed),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['slam'],
        equals(BattleMoveVisualRecipeId.showdownSlam),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['spore'],
        equals(BattleMoveVisualRecipeId.showdownSpore),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['painsplit'],
        equals(BattleMoveVisualRecipeId.showdownPainSplit),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['skillswap'],
        equals(BattleMoveVisualRecipeId.showdownSkillSwap),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['quiverdance'],
        equals(BattleMoveVisualRecipeId.showdownQuiverDance),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['focusblast'],
        equals(BattleMoveVisualRecipeId.showdownFocusBlast),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['voltswitch'],
        equals(BattleMoveVisualRecipeId.showdownVoltSwitch),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['explosion'],
        equals(BattleMoveVisualRecipeId.showdownExplosion),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['hurricane'],
        equals(BattleMoveVisualRecipeId.showdownHurricane),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['bravebird'],
        equals(BattleMoveVisualRecipeId.showdownAerialAce),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['sunnyday'],
        equals(BattleMoveVisualRecipeId.showdownSunnyDay),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['hail'],
        equals(BattleMoveVisualRecipeId.showdownHail),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['electricterrain'],
        equals(BattleMoveVisualRecipeId.showdownElectricTerrain),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['grassyterrain'],
        equals(BattleMoveVisualRecipeId.showdownGrassyTerrain),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['mistyterrain'],
        equals(BattleMoveVisualRecipeId.showdownMistyTerrain),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['followme'],
        equals(BattleMoveVisualRecipeId.showdownFollowMe),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['kinesis'],
        equals(BattleMoveVisualRecipeId.showdownKinesis),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['solarbeam'],
        equals(BattleMoveVisualRecipeId.showdownSolarBeam),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['thunder'],
        equals(BattleMoveVisualRecipeId.showdownThunder),
      );
    });

    test('direct recipe lookup exists for the new showdown wave bucket', () {
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['doomdesire'],
        equals(BattleMoveVisualRecipeId.showdownDoomDesire),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['seedflare'],
        equals(BattleMoveVisualRecipeId.showdownSeedFlare),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['icywind'],
        equals(BattleMoveVisualRecipeId.showdownIcyWind),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['weatherball'],
        equals(BattleMoveVisualRecipeId.showdownWeatherBall),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['scald'],
        equals(BattleMoveVisualRecipeId.showdownScald),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['triattack'],
        equals(BattleMoveVisualRecipeId.showdownTriAttack),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['clangingscales'],
        equals(BattleMoveVisualRecipeId.showdownClangingScales),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['flameburst'],
        equals(BattleMoveVisualRecipeId.showdownFlameBurst),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['steameruption'],
        equals(BattleMoveVisualRecipeId.showdownSteamEruption),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['watersport'],
        equals(BattleMoveVisualRecipeId.showdownWaterSport),
      );
    });

    test('direct guard and protect routings stay wired to the right families',
        () {
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['detect'],
        equals(BattleMoveVisualRecipeId.showdownProtect),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['kingsshield'],
        equals(BattleMoveVisualRecipeId.showdownProtect),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['spikyshield'],
        equals(BattleMoveVisualRecipeId.showdownProtect),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['endure'],
        equals(BattleMoveVisualRecipeId.showdownProtect),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['magiccoat'],
        equals(BattleMoveVisualRecipeId.showdownProtect),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['craftyshield'],
        equals(BattleMoveVisualRecipeId.showdownQuickGuard),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['matblock'],
        equals(BattleMoveVisualRecipeId.showdownQuickGuard),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['burningbulwark'],
        equals(BattleMoveVisualRecipeId.showdownBurningBulwark),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['banefulbunker'],
        equals(BattleMoveVisualRecipeId.showdownBanefulBunker),
      );
    });

    test('direct recipe lookup exists for psychic ghost and heal support wave',
        () {
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['storedpower'],
        equals(BattleMoveVisualRecipeId.showdownStoredPower),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['psychoboost'],
        equals(BattleMoveVisualRecipeId.showdownPsychoBoost),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['psyshock'],
        equals(BattleMoveVisualRecipeId.showdownPsyshock),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['hex'],
        equals(BattleMoveVisualRecipeId.showdownHex),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['willowisp'],
        equals(BattleMoveVisualRecipeId.showdownWillOWisp),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['lifedew'],
        equals(BattleMoveVisualRecipeId.showdownLifeDew),
      );
    });

    test(
        'direct recipe lookup exists for recovery cleanse and restoration wave',
        () {
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['aromatherapy'],
        equals(BattleMoveVisualRecipeId.showdownAromatherapy),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['rest'],
        equals(BattleMoveVisualRecipeId.showdownRest),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['ingrain'],
        equals(BattleMoveVisualRecipeId.showdownIngrain),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['morningsun'],
        equals(BattleMoveVisualRecipeId.showdownMorningSun),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['shoreup'],
        equals(BattleMoveVisualRecipeId.showdownShoreUp),
      );
    });

    test('direct recipe lookup exists for beam cannon star and meteor wave',
        () {
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['hyperbeam'],
        equals(BattleMoveVisualRecipeId.showdownHyperBeam),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['signalbeam'],
        equals(BattleMoveVisualRecipeId.showdownSignalBeam),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['fleurcannon'],
        equals(BattleMoveVisualRecipeId.showdownFleurCannon),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['armorcannon'],
        equals(BattleMoveVisualRecipeId.showdownArmorCannon),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['steelbeam'],
        equals(BattleMoveVisualRecipeId.showdownSteelBeam),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['beakblast'],
        equals(BattleMoveVisualRecipeId.showdownBeakBlast),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['twinbeam'],
        equals(BattleMoveVisualRecipeId.showdownTwinBeam),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['spikecannon'],
        equals(BattleMoveVisualRecipeId.showdownSpikeCannon),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['terastarstorm'],
        equals(BattleMoveVisualRecipeId.showdownTerastarStorm),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['meteormash'],
        equals(BattleMoveVisualRecipeId.showdownMeteorMash),
      );
    });

    test(
        'direct routings stay wired to psychic ghost and heal support families',
        () {
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['powertrip'],
        equals(BattleMoveVisualRecipeId.showdownStoredPower),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['psychicnoise'],
        equals(BattleMoveVisualRecipeId.showdownPsychoBoost),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['prismaticlaser'],
        equals(BattleMoveVisualRecipeId.showdownPsychoBoost),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['psystrike'],
        equals(BattleMoveVisualRecipeId.showdownPsyshock),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['nightshade'],
        equals(BattleMoveVisualRecipeId.showdownHex),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['ominouswind'],
        equals(BattleMoveVisualRecipeId.showdownHex),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['blackholeeclipse'],
        equals(BattleMoveVisualRecipeId.showdownHex),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['neverendingnightmare'],
        equals(BattleMoveVisualRecipeId.showdownHex),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['moongeistbeam'],
        equals(BattleMoveVisualRecipeId.showdownHex),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['astralbarrage'],
        equals(BattleMoveVisualRecipeId.showdownHex),
      );
      expect(
        BattleMoveVisualCatalog
            .recipeByShowdownMoveId['soulstealing7starstrike'],
        equals(BattleMoveVisualRecipeId.showdownHex),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['healpulse'],
        equals(BattleMoveVisualRecipeId.showdownLifeDew),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['aquaring'],
        equals(BattleMoveVisualRecipeId.showdownLifeDew),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['softboiled'],
        equals(BattleMoveVisualRecipeId.showdownLifeDew),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['moonlight'],
        equals(BattleMoveVisualRecipeId.showdownLifeDew),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['lunarblessing'],
        equals(BattleMoveVisualRecipeId.showdownLifeDew),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['revivalblessing'],
        equals(BattleMoveVisualRecipeId.showdownLifeDew),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['recover'],
        equals(BattleMoveVisualRecipeId.showdownLifeDew),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['roost'],
        equals(BattleMoveVisualRecipeId.showdownLifeDew),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['healorder'],
        equals(BattleMoveVisualRecipeId.showdownLifeDew),
      );
    });

    test('direct routings stay wired to beam cannon star and meteor families',
        () {
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['blastburn'],
        equals(BattleMoveVisualRecipeId.showdownArmorCannon),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['chloroblast'],
        equals(BattleMoveVisualRecipeId.showdownFleurCannon),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['simplebeam'],
        equals(BattleMoveVisualRecipeId.showdownSignalBeam),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['maxstarfall'],
        equals(BattleMoveVisualRecipeId.showdownTerastarStorm),
      );
    });

    test(
        'direct recovery cleanse and restoration routings stay wired to seeded families',
        () {
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['healbell'],
        equals(BattleMoveVisualRecipeId.showdownAromatherapy),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['refresh'],
        equals(BattleMoveVisualRecipeId.showdownAromatherapy),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['swallow'],
        equals(BattleMoveVisualRecipeId.showdownRest),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['milkdrink'],
        equals(BattleMoveVisualRecipeId.showdownRest),
      );
    });

    test('direct drain siphon and absorb routings stay wired to custom recipes',
        () {
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['gigadrain'],
        equals(BattleMoveVisualRecipeId.showdownDrain),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['leechlife'],
        equals(BattleMoveVisualRecipeId.showdownLeechLife),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['drainingkiss'],
        equals(BattleMoveVisualRecipeId.showdownDrainingKiss),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['absorb'],
        equals(BattleMoveVisualRecipeId.showdownDrain),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['megadrain'],
        equals(BattleMoveVisualRecipeId.showdownDrain),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['hornleech'],
        equals(BattleMoveVisualRecipeId.showdownHornLeech),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['paraboliccharge'],
        equals(BattleMoveVisualRecipeId.showdownParabolicCharge),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['oblivionwing'],
        equals(BattleMoveVisualRecipeId.showdownOblivionWing),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['strengthsap'],
        equals(BattleMoveVisualRecipeId.showdownLeechLife),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['leechseed'],
        equals(BattleMoveVisualRecipeId.showdownLeechSeed),
      );
    });

    test(
        'direct impact kick and punch routings stay wired to dedicated recipes',
        () {
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['shadowpunch'],
        equals(BattleMoveVisualRecipeId.showdownShadowPunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['focuspunch'],
        equals(BattleMoveVisualRecipeId.showdownFocusPunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['drainpunch'],
        equals(BattleMoveVisualRecipeId.showdownDrainPunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['dynamicpunch'],
        equals(BattleMoveVisualRecipeId.showdownDynamicPunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['cometpunch'],
        equals(BattleMoveVisualRecipeId.showdownCometPunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['megapunch'],
        equals(BattleMoveVisualRecipeId.showdownMegaPunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['poweruppunch'],
        equals(BattleMoveVisualRecipeId.showdownPowerUpPunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['dizzypunch'],
        equals(BattleMoveVisualRecipeId.showdownDizzyPunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['jetpunch'],
        equals(BattleMoveVisualRecipeId.showdownJetPunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['firepunch'],
        equals(BattleMoveVisualRecipeId.showdownFirePunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['icepunch'],
        equals(BattleMoveVisualRecipeId.showdownIcePunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['thunderpunch'],
        equals(BattleMoveVisualRecipeId.showdownThunderPunch),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['blazekick'],
        equals(BattleMoveVisualRecipeId.showdownBlazeKick),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['thunderouskick'],
        equals(BattleMoveVisualRecipeId.showdownThunderousKick),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['tropkick'],
        equals(BattleMoveVisualRecipeId.showdownTropKick),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['bodyslam'],
        equals(BattleMoveVisualRecipeId.showdownBodySlam),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['heavyslam'],
        equals(BattleMoveVisualRecipeId.showdownBodySlam),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['bodypress'],
        equals(BattleMoveVisualRecipeId.showdownBodySlam),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['dragonhammer'],
        equals(BattleMoveVisualRecipeId.showdownBodySlam),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['jumpkick'],
        equals(BattleMoveVisualRecipeId.showdownHighJumpKick),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['highjumpkick'],
        equals(BattleMoveVisualRecipeId.showdownHighJumpKick),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['lowkick'],
        equals(BattleMoveVisualRecipeId.showdownHighJumpKick),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['circlethrow'],
        equals(BattleMoveVisualRecipeId.showdownHighJumpKick),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['axekick'],
        equals(BattleMoveVisualRecipeId.showdownHighJumpKick),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['megakick'],
        equals(BattleMoveVisualRecipeId.showdownHighJumpKick),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['karatechop'],
        equals(BattleMoveVisualRecipeId.showdownKarateChop),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['forcepalm'],
        equals(BattleMoveVisualRecipeId.showdownKarateChop),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['brickbreak'],
        equals(BattleMoveVisualRecipeId.showdownKarateChop),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['throatchop'],
        equals(BattleMoveVisualRecipeId.showdownKarateChop),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['stormthrow'],
        equals(BattleMoveVisualRecipeId.showdownKarateChop),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['vitalthrow'],
        equals(BattleMoveVisualRecipeId.showdownKarateChop),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['drillrun'],
        equals(BattleMoveVisualRecipeId.showdownDrillRun),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['hyperdrill'],
        equals(BattleMoveVisualRecipeId.showdownDrillRun),
      );
    });

    test('direct recipe lookup exists for projectile bomb wave', () {
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['gunkshot'],
        equals(BattleMoveVisualRecipeId.showdownGunkShot),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['mudshot'],
        equals(BattleMoveVisualRecipeId.showdownMudShot),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['electroball'],
        equals(BattleMoveVisualRecipeId.showdownElectroBall),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['rockblast'],
        equals(BattleMoveVisualRecipeId.showdownRockBlast),
      );
    });

    test('direct projectile bomb routings stay wired to seeded families', () {
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['sludge'],
        equals(BattleMoveVisualRecipeId.showdownGunkShot),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['acid'],
        equals(BattleMoveVisualRecipeId.showdownSmog),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['acidspray'],
        equals(BattleMoveVisualRecipeId.showdownSmog),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['belch'],
        equals(BattleMoveVisualRecipeId.showdownGunkShot),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['mudbomb'],
        equals(BattleMoveVisualRecipeId.showdownMudShot),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['mudslap'],
        equals(BattleMoveVisualRecipeId.showdownMudShot),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['thundershock'],
        equals(BattleMoveVisualRecipeId.showdownElectroBall),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['smackdown'],
        equals(BattleMoveVisualRecipeId.showdownRockBlast),
      );
    });

    test('direct recipe lookup exists for poison toxic control wave', () {
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['toxic'],
        equals(BattleMoveVisualRecipeId.showdownToxic),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['toxicspikes'],
        equals(BattleMoveVisualRecipeId.showdownToxicSpikes),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['poisongas'],
        equals(BattleMoveVisualRecipeId.showdownPoisonGas),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['smog'],
        equals(BattleMoveVisualRecipeId.showdownSmog),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['clearsmog'],
        equals(BattleMoveVisualRecipeId.showdownClearSmog),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['poisonfang'],
        equals(BattleMoveVisualRecipeId.showdownPoisonFang),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['crosspoison'],
        equals(BattleMoveVisualRecipeId.showdownCrossPoison),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['direclaw'],
        equals(BattleMoveVisualRecipeId.showdownDireClaw),
      );
    });

    test('direct poison toxic control routings stay wired to seeded families',
        () {
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['venomdrench'],
        equals(BattleMoveVisualRecipeId.showdownSmog),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['belch'],
        equals(BattleMoveVisualRecipeId.showdownGunkShot),
      );
    });

    test('direct recipe lookup exists for sweeping wave storm and beam wave',
        () {
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['whirlwind'],
        equals(BattleMoveVisualRecipeId.showdownWhirlwind),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['freezedry'],
        equals(BattleMoveVisualRecipeId.showdownFreezeDry),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['magmastorm'],
        equals(BattleMoveVisualRecipeId.showdownMagmaStorm),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['originpulse'],
        equals(BattleMoveVisualRecipeId.showdownOriginPulse),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['psybeam'],
        equals(BattleMoveVisualRecipeId.showdownPsybeam),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['aeroblast'],
        equals(BattleMoveVisualRecipeId.showdownAeroblast),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['roaroftime'],
        equals(BattleMoveVisualRecipeId.showdownRoarOfTime),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['revelationdance'],
        equals(BattleMoveVisualRecipeId.showdownRevelationDance),
      );
    });

    test(
        'direct sweeping wave storm and beam routings stay wired to seeded families',
        () {
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['gust'],
        equals(BattleMoveVisualRecipeId.showdownWhirlwind),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['silverwind'],
        equals(BattleMoveVisualRecipeId.showdownWhirlwind),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['twister'],
        equals(BattleMoveVisualRecipeId.showdownWhirlwind),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['frostbreath'],
        equals(BattleMoveVisualRecipeId.showdownFreezeDry),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['glaciate'],
        equals(BattleMoveVisualRecipeId.showdownFreezeDry),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['fierydance'],
        equals(BattleMoveVisualRecipeId.showdownMagmaStorm),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['inferno'],
        equals(BattleMoveVisualRecipeId.showdownMagmaStorm),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['hydrovortex'],
        equals(BattleMoveVisualRecipeId.showdownOriginPulse),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['maxgeyser'],
        equals(BattleMoveVisualRecipeId.showdownOriginPulse),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['gmaxcannonade'],
        equals(BattleMoveVisualRecipeId.showdownOriginPulse),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['gmaxhydrosnipe'],
        equals(BattleMoveVisualRecipeId.showdownOriginPulse),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['psywave'],
        equals(BattleMoveVisualRecipeId.showdownPsybeam),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['expandingforce'],
        equals(BattleMoveVisualRecipeId.showdownPsybeam),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['terablastflying'],
        equals(BattleMoveVisualRecipeId.showdownAeroblast),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['eternabeam'],
        equals(BattleMoveVisualRecipeId.showdownRoarOfTime),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['pollenpuff'],
        equals(BattleMoveVisualRecipeId.showdownRevelationDance),
      );
    });

    test('direct self-buff routings stay wired to seeded setup families', () {
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['focusenergy'],
        equals(BattleMoveVisualRecipeId.showdownBulkUp),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['harden'],
        equals(BattleMoveVisualRecipeId.showdownReflect),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['defensecurl'],
        equals(BattleMoveVisualRecipeId.showdownReflect),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['irondefense'],
        equals(BattleMoveVisualRecipeId.showdownReflect),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['cottonguard'],
        equals(BattleMoveVisualRecipeId.showdownReflect),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['defendorder'],
        equals(BattleMoveVisualRecipeId.showdownReflect),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['barrier'],
        equals(BattleMoveVisualRecipeId.showdownReflect),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['howl'],
        equals(BattleMoveVisualRecipeId.showdownBulkUp),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['meditate'],
        equals(BattleMoveVisualRecipeId.showdownBulkUp),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['sharpen'],
        equals(BattleMoveVisualRecipeId.showdownSwordsDance),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['charge'],
        equals(BattleMoveVisualRecipeId.showdownCalmMind),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['luckychant'],
        equals(BattleMoveVisualRecipeId.showdownCalmMind),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['rockpolish'],
        equals(BattleMoveVisualRecipeId.showdownAgility),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['autotomize'],
        equals(BattleMoveVisualRecipeId.showdownAgility),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['shiftgear'],
        equals(BattleMoveVisualRecipeId.showdownAgility),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['magnetrise'],
        equals(BattleMoveVisualRecipeId.showdownAgility),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['minimize'],
        equals(BattleMoveVisualRecipeId.showdownAgility),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['growth'],
        equals(BattleMoveVisualRecipeId.showdownCalmMind),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['tailglow'],
        equals(BattleMoveVisualRecipeId.showdownQuiverDance),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['cosmicpower'],
        equals(BattleMoveVisualRecipeId.showdownCalmMind),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['geomancy'],
        equals(BattleMoveVisualRecipeId.showdownQuiverDance),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['chargeup'],
        equals(BattleMoveVisualRecipeId.showdownCalmMind),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['gearup'],
        equals(BattleMoveVisualRecipeId.showdownAgility),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['flowershield'],
        equals(BattleMoveVisualRecipeId.showdownReflect),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['laserfocus'],
        equals(BattleMoveVisualRecipeId.showdownBulkUp),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['honeclaws'],
        equals(BattleMoveVisualRecipeId.showdownSwordsDance),
      );
    });

    test('high-value showdown aliases stay wired to seeded families', () {
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['waterfall'],
        equals('aquajet'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['bulletpunch'],
        equals('machpunch'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['wringout'],
        equals('forcepalm'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['wideguard'],
        equals('quickguard'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['surgingstrikes'],
        equals('aquajet'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['volttackle'],
        equals('wildcharge'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['heatcrash'],
        equals('flareblitz'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['nuzzle'],
        equals('spark'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['terablastelectric'],
        equals('thunderbolt'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['comeuppance'],
        equals('darkpulse'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['boltbeak'],
        equals('spark'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['mysticalfire'],
        equals('flamethrower'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['terablastpsychic'],
        equals('psychic'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['jawlock'],
        equals('crunch'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['shellsidearmphysical'],
        equals('poisonjab'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['ceaselessedge'],
        equals('nightslash'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['doubleedge'],
        equals('gigaimpact'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['vinewhip'],
        equals('powerwhip'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['liquidation'],
        equals('crabhammer'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['aurawheel'],
        equals('discharge'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['behemothblade'],
        equals('smartstrike'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['hornattack'],
        equals('megahorn'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['breakingswipe'],
        equals('dragonclaw'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['psyblade'],
        equals('psychocut'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['chillingwater'],
        equals('waterpulse'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['mountaingale'],
        equals('powergem'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['burningjealousy'],
        equals('heatwave'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['paleowave'],
        equals('muddywater'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['scorchingsands'],
        equals('earthpower'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['terablastbug'],
        equals('bugbuzz'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['hydrocannon'],
        equals('hydropump'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['terablastwater'],
        equals('hydropump'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['razorwind'],
        equals('airslash'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['terablaststellar'],
        equals('dracometeor'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['chatter'],
        equals('hypervoice'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['echoedvoice'],
        equals('hypervoice'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['mirrorshot'],
        equals('flashcannon'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['terablaststeel'],
        equals('flashcannon'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['dynamaxcannon'],
        equals('dragonpulse'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['terablastdragon'],
        equals('dragonpulse'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['venoshock'],
        equals('sludgebomb'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['poisonpowder'],
        equals('spore'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['poisontail'],
        equals('poisonjab'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['gastroacid'],
        equals('toxic'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['corrosivegas'],
        equals('poisongas'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['terablastpoison'],
        equals('sludgebomb'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['razorleaf'],
        equals('magicalleaf'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['grasspledge'],
        equals('magicalleaf'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['spiderweb'],
        equals('electroweb'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['toxicthread'],
        equals('electroweb'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['pinmissile'],
        equals('bulletseed'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['attackorder'],
        equals('bulletseed'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['beatup'],
        equals('slam'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['rockclimb'],
        equals('slam'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['sleeppowder'],
        equals('spore'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['magicpowder'],
        equals('spore'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['psychoshift'],
        equals('painsplit'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['reflecttype'],
        equals('painsplit'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['gmaxfinale'],
        equals('maxstarfall'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['gmaxsmite'],
        equals('maxstarfall'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['guardsplit'],
        equals('skillswap'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['courtchange'],
        equals('skillswap'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['selfdestruct'],
        equals('explosion'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['mindblown'],
        equals('explosion'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['drillpeck'],
        equals('bravebird'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['bleakwindstorm'],
        equals('hurricane'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['dragonenergy'],
        equals('dragonbreath'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['futuresight'],
        equals('doomdesire'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['powdersnow'],
        equals('icywind'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['purify'],
        equals('weatherball'),
      );
      expect(
        BattleMoveVisualCatalog
            .aliasByShowdownMoveId['10000000voltthunderbolt'],
        equals('triattack'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['dragondarts'],
        equals('dragonbreath'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['pyroball'],
        equals('flameburst'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['scaleshot'],
        equals('clangingscales'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['terablast'],
        equals('scald'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['terablastgrass'],
        equals('seedflare'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['hydrosteam'],
        equals('steameruption'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['watergun'],
        equals('watersport'),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['snowscape'],
        equals(BattleMoveVisualRecipeId.showdownHail),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['magicroom'],
        equals(BattleMoveVisualRecipeId.showdownTrickRoom),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['wonderroom'],
        equals(BattleMoveVisualRecipeId.showdownTrickRoom),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['babydolleyes'],
        equals(BattleMoveVisualRecipeId.showdownBabyDollEyes),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['junglehealing'],
        equals(BattleMoveVisualRecipeId.showdownGrassyTerrain),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['technoblast'],
        equals(BattleMoveVisualRecipeId.showdownFocusBlast),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['flamecharge'],
        equals(BattleMoveVisualRecipeId.showdownFlareBlitz),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['leafstorm'],
        equals(BattleMoveVisualRecipeId.showdownMagicalLeaf),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['sludgewave'],
        equals(BattleMoveVisualRecipeId.showdownSludgeBomb),
      );
      expect(
        BattleMoveVisualCatalog.recipeByShowdownMoveId['zapcannon'],
        equals(BattleMoveVisualRecipeId.showdownThunder),
      );
    });

    test('direct recipe lookup exists for the showdown impact bucket', () {
      const expectedRoutes = <String, BattleMoveVisualRecipeId>{
        'woodhammer': BattleMoveVisualRecipeId.showdownWoodHammer,
        'ivycudgel': BattleMoveVisualRecipeId.showdownIvyCudgel,
        'ivycudgelwater': BattleMoveVisualRecipeId.showdownIvyCudgelWater,
        'ivycudgelfire': BattleMoveVisualRecipeId.showdownIvyCudgelFire,
        'ivycudgelrock': BattleMoveVisualRecipeId.showdownIvyCudgelRock,
        'cut': BattleMoveVisualRecipeId.showdownCut,
        'shadowclaw': BattleMoveVisualRecipeId.showdownShadowClaw,
        'multiattack': BattleMoveVisualRecipeId.showdownMultiAttack,
        'bite': BattleMoveVisualRecipeId.showdownBite,
        'superfang': BattleMoveVisualRecipeId.showdownSuperFang,
        'bugbite': BattleMoveVisualRecipeId.showdownBugBite,
        'psychicfangs': BattleMoveVisualRecipeId.showdownPsychicFangs,
        'ironhead': BattleMoveVisualRecipeId.showdownIronHead,
        'headbutt': BattleMoveVisualRecipeId.showdownHeadbutt,
        'stomp': BattleMoveVisualRecipeId.showdownStomp,
        'hammerarm': BattleMoveVisualRecipeId.showdownHammerArm,
        'icehammer': BattleMoveVisualRecipeId.showdownIceHammer,
        'skyuppercut': BattleMoveVisualRecipeId.showdownSkyUppercut,
        'needlearm': BattleMoveVisualRecipeId.showdownNeedleArm,
        'rocksmash': BattleMoveVisualRecipeId.showdownRockSmash,
      };

      for (final entry in expectedRoutes.entries) {
        expect(
          BattleMoveVisualCatalog.recipeByShowdownMoveId[entry.key],
          equals(entry.value),
          reason: entry.key,
        );
      }
    });

    test('safe showdown aliases route into the impact bucket', () {
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['highhorsepower'],
        equals('stomp'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['hyperfang'],
        equals('superfang'),
      );
      expect(
        BattleMoveVisualCatalog.aliasByShowdownMoveId['firelash'],
        equals('multiattack'),
      );
    });

    test('direct recipe lookup exists for the showdown catch-up roots wave',
        () {
      const expectedRoutes = <String, BattleMoveVisualRecipeId>{
        'ragepowder': BattleMoveVisualRecipeId.showdownFollowMe,
        'wish': BattleMoveVisualRecipeId.showdownLifeDew,
        'nobleroar': BattleMoveVisualRecipeId.showdownGrowl,
        'swagger': BattleMoveVisualRecipeId.showdownSwagger,
        'shelltrap': BattleMoveVisualRecipeId.showdownMagmaStorm,
        'outrage': BattleMoveVisualRecipeId.showdownDragonClaw,
        'bind': BattleMoveVisualRecipeId.showdownPowerWhip,
        'petaldance': BattleMoveVisualRecipeId.showdownMagicalLeaf,
        'fusionflare': BattleMoveVisualRecipeId.showdownFireBlast,
        'gigavolthavoc': BattleMoveVisualRecipeId.showdownThunderbolt,
        'alloutpummeling': BattleMoveVisualRecipeId.showdownCloseCombat,
        'supersonicskystrike': BattleMoveVisualRecipeId.showdownHurricane,
        'aciddownpour': BattleMoveVisualRecipeId.showdownSludgeBomb,
        'torchsong': BattleMoveVisualRecipeId.showdownFireBlast,
        'iceball': BattleMoveVisualRecipeId.showdownFreezeDry,
        'anchorshot': BattleMoveVisualRecipeId.showdownSpikeCannon,
        'diamondstorm': BattleMoveVisualRecipeId.showdownPowerGem,
        'twinkletackle': BattleMoveVisualRecipeId.showdownPlayRough,
        'headlongrush': BattleMoveVisualRecipeId.showdownEarthquake,
        'crushclaw': BattleMoveVisualRecipeId.showdownShadowClaw,
        'falseswipe': BattleMoveVisualRecipeId.showdownCut,
        'bitterblade': BattleMoveVisualRecipeId.showdownLeafBlade,
        'secretsword': BattleMoveVisualRecipeId.showdownPsychoCut,
      };

      for (final entry in expectedRoutes.entries) {
        expect(
          BattleMoveVisualCatalog.recipeByShowdownMoveId[entry.key],
          equals(entry.value),
          reason: entry.key,
        );
      }
    });

    test('exact showdown alias chains route through the catch-up wave', () {
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
        'bloomdoom': 'petaldance',
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
          BattleMoveVisualCatalog.aliasByShowdownMoveId[entry.key],
          equals(entry.value),
          reason: entry.key,
        );
      }
    });

    test('direct recipe lookup exists for the fidelity catch-up wave', () {
      const expectedRoutes = <String, BattleMoveVisualRecipeId>{
        'taunt': BattleMoveVisualRecipeId.showdownTaunt,
        'doubleteam': BattleMoveVisualRecipeId.showdownAgility,
        'teleport': BattleMoveVisualRecipeId.showdownAgility,
        'nastyplot': BattleMoveVisualRecipeId.showdownCalmMind,
        'haze': BattleMoveVisualRecipeId.showdownMist,
        'sing': BattleMoveVisualRecipeId.showdownHyperVoice,
        'snarl': BattleMoveVisualRecipeId.showdownDarkPulse,
        'holdback': BattleMoveVisualRecipeId.showdownTackle,
        'irontail': BattleMoveVisualRecipeId.showdownIronHead,
        'reversal': BattleMoveVisualRecipeId.showdownCloseCombat,
        'fakeout': BattleMoveVisualRecipeId.showdownQuickAttack,
        'shadowsneak': BattleMoveVisualRecipeId.showdownShadowPunch,
        'geargrind': BattleMoveVisualRecipeId.showdownSpikeCannon,
        'ancientpower': BattleMoveVisualRecipeId.showdownPowerGem,
        'vacuumwave': BattleMoveVisualRecipeId.showdownAuraSphere,
        'firespin': BattleMoveVisualRecipeId.showdownMagmaStorm,
        'wavecrash': BattleMoveVisualRecipeId.showdownOriginPulse,
      };

      for (final entry in expectedRoutes.entries) {
        expect(
          BattleMoveVisualCatalog.recipeByShowdownMoveId[entry.key],
          equals(entry.value),
          reason: entry.key,
        );
      }
    });

    test('direct fidelity wave keeps representative buckets aligned', () {
      const expectedRoutes = <String, BattleMoveVisualRecipeId>{
        'supersonic': BattleMoveVisualRecipeId.showdownConfuseRay,
        'metalsound': BattleMoveVisualRecipeId.showdownGrowl,
        'thief': BattleMoveVisualRecipeId.showdownNightSlash,
        'tailslap': BattleMoveVisualRecipeId.showdownDoubleHit,
        'iciclespear': BattleMoveVisualRecipeId.showdownBulletSeed,
        'burnup': BattleMoveVisualRecipeId.showdownFlamethrower,
        'freezingglare': BattleMoveVisualRecipeId.showdownFreezeDry,
        'thundercage': BattleMoveVisualRecipeId.showdownChargeBeam,
      };

      for (final entry in expectedRoutes.entries) {
        expect(
          BattleMoveVisualCatalog.recipeByShowdownMoveId[entry.key],
          equals(entry.value),
          reason: entry.key,
        );
      }
    });

    test('second fidelity wave keeps setup and signature buckets aligned', () {
      const expectedRoutes = <String, BattleMoveVisualRecipeId>{
        'allyswitch': BattleMoveVisualRecipeId.showdownAgility,
        'transform': BattleMoveVisualRecipeId.showdownSkillSwap,
        'bellydrum': BattleMoveVisualRecipeId.showdownBulkUp,
        'shellsmash': BattleMoveVisualRecipeId.showdownQuiverDance,
        'stickyweb': BattleMoveVisualRecipeId.showdownElectroweb,
        'makeitrain': BattleMoveVisualRecipeId.showdownFlashCannon,
        'waterspout': BattleMoveVisualRecipeId.showdownOriginPulse,
        'solarblade': BattleMoveVisualRecipeId.showdownLeafBlade,
        'glaciallance': BattleMoveVisualRecipeId.showdownIceHammer,
        'spacialrend': BattleMoveVisualRecipeId.showdownDracoMeteor,
        'dragonascent': BattleMoveVisualRecipeId.showdownAerialAce,
      };

      for (final entry in expectedRoutes.entries) {
        expect(
          BattleMoveVisualCatalog.recipeByShowdownMoveId[entry.key],
          equals(entry.value),
          reason: entry.key,
        );
      }
    });

    test('third fidelity wave keeps signature finishers aligned', () {
      const expectedRoutes = <String, BattleMoveVisualRecipeId>{
        'avalanche': BattleMoveVisualRecipeId.showdownIceHammer,
        'fierywrath': BattleMoveVisualRecipeId.showdownDarkPulse,
        'terrainpulse': BattleMoveVisualRecipeId.showdownWeatherBall,
        'flowertrick': BattleMoveVisualRecipeId.showdownLeafBlade,
        'tripleaxel': BattleMoveVisualRecipeId.showdownDoubleKick,
        'firstimpression': BattleMoveVisualRecipeId.showdownQuickAttack,
        'plasmafists': BattleMoveVisualRecipeId.showdownThunderPunch,
        'electrodrift': BattleMoveVisualRecipeId.showdownWildCharge,
        'photongeyser': BattleMoveVisualRecipeId.showdownPsychic,
        'clangoroussoulblaze': BattleMoveVisualRecipeId.showdownClangingScales,
        'thunderclap': BattleMoveVisualRecipeId.showdownSpark,
        'magicaltorque': BattleMoveVisualRecipeId.showdownPlayRough,
      };

      for (final entry in expectedRoutes.entries) {
        expect(
          BattleMoveVisualCatalog.recipeByShowdownMoveId[entry.key],
          equals(entry.value),
          reason: entry.key,
        );
      }
    });

    test('final catch-up wave keeps the last safe mappings aligned', () {
      const expectedRoutes = <String, BattleMoveVisualRecipeId>{
        'instruct': BattleMoveVisualRecipeId.showdownInstruct,
        'hiddenpower': BattleMoveVisualRecipeId.showdownHiddenPower,
        'watershuriken': BattleMoveVisualRecipeId.showdownWaterShuriken,
        'slash': BattleMoveVisualRecipeId.showdownSlash,
        'judgment': BattleMoveVisualRecipeId.showdownFocusBlast,
        'gmaxsteelsurge': BattleMoveVisualRecipeId.showdownFlashCannon,
        'saltcure': BattleMoveVisualRecipeId.showdownStealthRock,
        'swift': BattleMoveVisualRecipeId.showdownMagicalLeaf,
        'guardianofalola': BattleMoveVisualRecipeId.showdownMoonBlast,
      };

      for (final entry in expectedRoutes.entries) {
        expect(
          BattleMoveVisualCatalog.recipeByShowdownMoveId[entry.key],
          equals(entry.value),
          reason: entry.key,
        );
      }
    });

    test('final bespoke seven now resolve to dedicated direct recipes', () {
      const expectedRoutes = <String, BattleMoveVisualRecipeId>{
        'splash': BattleMoveVisualRecipeId.showdownSplash,
        'celebrate': BattleMoveVisualRecipeId.showdownCelebrate,
        'orderup': BattleMoveVisualRecipeId.showdownOrderUp,
        'heartstamp': BattleMoveVisualRecipeId.showdownHeartStamp,
        'matchagotcha': BattleMoveVisualRecipeId.showdownMatchaGotcha,
        'present': BattleMoveVisualRecipeId.showdownPresent,
        'payday': BattleMoveVisualRecipeId.showdownPayDay,
      };

      for (final entry in expectedRoutes.entries) {
        expect(
          BattleMoveVisualCatalog.recipeByShowdownMoveId[entry.key],
          equals(entry.value),
          reason: entry.key,
        );
      }
    });

    test(
        'fidelity support wave promotes taunt-style utility moves to bespoke recipes',
        () {
      const expectedRoutes = <String, BattleMoveVisualRecipeId>{
        'taunt': BattleMoveVisualRecipeId.showdownTaunt,
        'instruct': BattleMoveVisualRecipeId.showdownInstruct,
        'quash': BattleMoveVisualRecipeId.showdownQuash,
        'swagger': BattleMoveVisualRecipeId.showdownSwagger,
        'encore': BattleMoveVisualRecipeId.showdownEncore,
        'babydolleyes': BattleMoveVisualRecipeId.showdownBabyDollEyes,
      };

      for (final entry in expectedRoutes.entries) {
        expect(
          BattleMoveVisualCatalog.recipeByShowdownMoveId[entry.key],
          equals(entry.value),
          reason: entry.key,
        );
      }
    });

    test('aliases point to existing ids', () {
      for (final aliasTarget
          in BattleMoveVisualCatalog.aliasByShowdownMoveId.values) {
        expect(
          BattleMoveVisualCatalog.recipeByShowdownMoveId.containsKey(
                aliasTarget,
              ) ||
              BattleMoveVisualCatalog.aliasByShowdownMoveId.containsKey(
                aliasTarget,
              ),
          isTrue,
          reason: aliasTarget,
        );
      }
    });

    test('no alias loop', () {
      for (final start in BattleMoveVisualCatalog.aliasByShowdownMoveId.keys) {
        final visited = <String>{};
        var current = start;
        while (true) {
          expect(visited.add(current), isTrue, reason: current);
          final next = BattleMoveVisualCatalog.aliasByShowdownMoveId[current];
          if (next == null) {
            break;
          }
          current = next;
        }
      }
    });

    test('explicit no-animation ids are disjoint from direct recipe ids', () {
      expect(
        BattleMoveVisualCatalog.explicitNoAnimationShowdownIds.any(
          BattleMoveVisualCatalog.recipeByShowdownMoveId.containsKey,
        ),
        isFalse,
      );
    });

    test('explicit no-animation list is empty after the bespoke final wave',
        () {
      expect(BattleMoveVisualCatalog.explicitNoAnimationShowdownIds, isEmpty);
    });
  });
}
