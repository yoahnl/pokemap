import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';

SourceInterpretationProfile? detectBuiltinSourceInterpretationProfile(
    SourceSnapshot snapshot) {
  if (snapshot.state != SourceScanState.complete) return null;
  final archives = snapshot.entries
      .where((entry) =>
          sourcePathCollisionKey(entry.relativePath) == 'data/scripts.rxdata')
      .toList();
  if (archives.length != 1 ||
      archives.single.relativePath != 'Data/Scripts.rxdata' ||
      archives.single.kind != SourceNodeKind.file) {
    return null;
  }
  return _essentialsStaticProfiles[archives.single.sha256?.value];
}

final _essentialsStaticProfiles = {
  for (final archiveHash in const [
    '3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d',
    '8b03301e71b12ba8cc84efb128534d0a7f17d02cf56c770e40c16be37b730940',
  ])
    archiveHash: SourceInterpretationProfile.fromJson({
      ...jsonDecode(_essentialsStaticProfileJson) as Map<String, dynamic>,
      'scriptsArchive': {
        'relativePath': 'Data/Scripts.rxdata',
        'sha256': archiveHash,
      },
    }),
};

const _essentialsStaticProfileJson = r'''
{
  "kind": "sourceInterpretationProfile",
  "schemaVersion": 2,
  "profileId": "essentials-static-walking-events-items",
  "semanticsId": "rmxp-essentials-static-v1",
  "scriptsArchive": {
    "relativePath": "Data/Scripts.rxdata",
    "sha256": "3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d"
  },
  "capabilities": [
    "autotiles",
    "encounters",
    "events",
    "walking"
  ],
  "sections": {
    "events.Battle": {
      "index": 147,
      "name": "Battle",
      "sha256": "d61fd2ce22cc27e9d9682c14ced068dca544f39921af9b1acaa18c9022325c5b",
      "lines": [131, 134]
    },
    "events.Overworld_BattleStarting": {
      "index": 256,
      "name": "Overworld_BattleStarting",
      "sha256": "7a0e305aad2f7939254b9e322bb86ee592e2da338b114cdec2a74e4cb1ff4b04",
      "lines": [492, 527]
    },
    "autotiles.AutotileExpander": {
      "index": 74,
      "sha256": "c40587686d2176794b79aa926e0adc5fdb67db102dd6f14a7e54a1618635e597",
      "name": "AutotileExpander"
    },
    "autotiles.TileDrawingHelper": {
      "index": 75,
      "sha256": "2a94034ce77b68faeb8c7620e4a9cf2ceea81580992db7c86424cc3b63393bc7",
      "name": "TileDrawingHelper"
    },
    "autotiles.TilemapRenderer": {
      "index": 72,
      "sha256": "321f334b2eeee0f1fa45d16f52117feb7ea765e17643b88c09a69285ada4bdef",
      "name": "TilemapRenderer"
    },
    "encounters.Item_Effects": {
      "index": 264,
      "sha256": "9f5bb1a5663c6ca9d34fc256f577a7918f5def7e76b2426a37116348af0bf1bc",
      "name": "Item_Effects"
    },
    "encounters.Overworld_Fishing": {
      "index": 245,
      "sha256": "0c49fbc54451e9e3e503c33ead66010e93d1a398849a244f4b67cfb0a4490618",
      "name": "Overworld_Fishing"
    },
    "events.DrawText": {
      "index": 87,
      "sha256": "c6053682189b093bd8ec8d7fa8f2ac074c301c311a5f452e6d178b0c7bc01bf7",
      "name": "DrawText"
    },
    "events.Game_Event": {
      "index": 45,
      "sha256": "8c11fb7f170df5ca2aff17725e1dbed031c94deebabdbbae69dd926e24acafa7",
      "name": "Game_Event"
    },
    "events.Game_Player": {
      "index": 46,
      "sha256": "7159cc172004da46b72a51b7d009df24de7a297bdb09599de31a4b5116dab373",
      "name": "Game_Player"
    },
    "events.Interpreter": {
      "index": 33,
      "sha256": "b2f4c542a1542a5908d1208b87eae05d8b6f6ec0d26df1835871595842ed0355",
      "name": "Interpreter"
    },
    "events.Interpreter_Commands": {
      "index": 34,
      "sha256": "ec927a007bee1889223dbc8b3de115f062a5308ab4410f87dab965eef3032561",
      "name": "Interpreter_Commands"
    },
    "events.Item": {
      "index": 127,
      "sha256": "b280015f15e892754c90728bdbf23a77c280ebb86413cb51c64793e0b997757a",
      "name": "Item"
    },
    "events.MessageConfig": {
      "index": 79,
      "sha256": "eacf78724bf5ab978b4b74d73149e3e556906d8f63d0ed380310bdddae7a6dad",
      "name": "MessageConfig"
    },
    "events.Messages": {
      "index": 88,
      "sha256": "82abdb33dfad9d735c4342ca63fa72483b1a34bb01bd2a1e034b03afa8207ec3",
      "name": "Messages"
    },
    "events.PokeMart": {
      "index": 312,
      "sha256": "484315201c01010b3978bcac6968834b2a60c7a8d6b348abd83b4c1a4c234b53",
      "name": "UI_PokeMart"
    },
    "events.Settings": {
      "index": 0,
      "sha256": "cc412c0b86e5ebbc121a91ca5efc2d7d6c7b398469cb0c7cd5be1b770531b06f",
      "name": "Settings"
    },
    "events.Utilities": {
      "index": 362,
      "sha256": "377ba5397ff74128812af4ef5089de7ae480f6ad7ff040adea91bb25b24671a4",
      "name": "Utilities"
    },
    "walking.Game_Character": {
      "index": 44,
      "sha256": "0cb6a5149f998c053055d3c7726d557fe1a1368fcabe14bb4a7c159f09a686b9",
      "name": "Game_Character"
    },
    "walking.Game_Map": {
      "index": 42,
      "sha256": "2e31060a4dc0ac036fecc510735f8a70f8cb8c7f33291b572e489e89c4f5b7f9",
      "name": "Game_Map"
    },
    "walking.TerrainTag": {
      "index": 113,
      "sha256": "6bcfb146b4ec27576d2c616392e4aa14f1f9baa135db85ac02b33e0139e7382e",
      "name": "TerrainTag"
    },
    "events.Audio_Play": {
      "index": 93,
      "name": "Audio_Play",
      "sha256": "e21c2f9b086f99777b7421c850e4b04cb8e5db574876b3fbb9c0fd9932e1d1fb"
    },
    "events.Pokemon": {
      "index": 273,
      "name": "Pokemon",
      "sha256": "2cc5db14ec402faedd355afddca951743a7723d1dc0724c45d3f230c2cb116ec"
    },
    "events.Species_files": {
      "index": 130,
      "name": "Species_files",
      "sha256": "b0d4786a3b33dbb06a68aa395e813ed21be46d826dab69b5c9ab41a99ae7e0d3"
    }
  },
  "declaredPrograms": [],
  "presentationBindings": {
    "pickupFeedbackByRegion": [
      {
        "regionId": 1,
        "windowskinPinnedAsset": {
          "relativePath": "Graphics/Windowskins/speech hgss 1.png",
          "sha256": "726a92a6c302f0db44625004a868b79b029fbc8ea491beb8e7ddad72b685b739"
        },
        "iconsByPocket": {
          "1": {
            "relativePath": "Graphics/Icons/bagPocket1.png",
            "sha256": "f30c7d013a4a1ec4db9e398e172e1b913bb9f2c818c8bf7fe5aa6709e92c78f7"
          },
          "2": {
            "relativePath": "Graphics/Icons/bagPocket2.png",
            "sha256": "501d3e66b9c7af52d9eb95be3a4780c61587aa0521c9a64aca6ba436a08b46f2"
          },
          "3": {
            "relativePath": "Graphics/Icons/bagPocket3.png",
            "sha256": "a0d4cfa066b745ac2cd3b163e26370cef1b94e64f7c9942630f5059883511296"
          },
          "4": {
            "relativePath": "Graphics/Icons/bagPocket4.png",
            "sha256": "fde41eca0e24cc0cc0a752641a6dc104297440b9090bcd76791a49fb7de2750e"
          },
          "5": {
            "relativePath": "Graphics/Icons/bagPocket5.png",
            "sha256": "d01d00e2cb7c87df2d938927bc6756b6f115840c1af7d6b9514659f23ad39220"
          },
          "6": {
            "relativePath": "Graphics/Icons/bagPocket6.png",
            "sha256": "908fc010c149d3fb2d7dd7ccaed5b04eb03a1cfe7bb93c40b6454f6953f31acc"
          },
          "7": {
            "relativePath": "Graphics/Icons/bagPocket7.png",
            "sha256": "37da64916455101c8c3fa6eb80ca479a49f71385215a5c8d5a70cacca1d2965c"
          },
          "8": {
            "relativePath": "Graphics/Icons/bagPocket8.png",
            "sha256": "320c5536bf8c46b5894c3f24161b8e6e2a9fb1cef66821c7a618a301a69cfb3d"
          }
        },
        "audioByItemKind": {
          "item": {
            "relativePath": "Audio/ME/FRLG Fanfare - Item (Fanfare Item Get 1).ogg",
            "sha256": "d3476d98cd2c27dc6de10a6479d0a9ca2f1bc5e820d9b962faeb4740759c6586"
          },
          "keyItem": {
            "relativePath": "Audio/ME/FRLG Fanfare - Item Key (Fanfare! Key Item).ogg",
            "sha256": "8a44ed2800dbc95581c784eb7b1ea293b4bf367e57bd023e06c3b6649fa72e9f"
          },
          "machine": {
            "relativePath": "Audio/ME/FRLG Fanfare - Item Machine (Fanfare! Item Obtained (Version 2)).ogg",
            "sha256": "2dfb30229ad35387979f24dfae7ec96d383fa8a7ba79b9c265db7f36a8ed15df"
          }
        }
      },
      {
        "regionId": 101,
        "windowskinPinnedAsset": {
          "relativePath": "Graphics/Windowskins/speech hgss 1.png",
          "sha256": "726a92a6c302f0db44625004a868b79b029fbc8ea491beb8e7ddad72b685b739"
        },
        "iconsByPocket": {
          "1": {
            "relativePath": "Graphics/Icons/bagPocket1.png",
            "sha256": "f30c7d013a4a1ec4db9e398e172e1b913bb9f2c818c8bf7fe5aa6709e92c78f7"
          },
          "2": {
            "relativePath": "Graphics/Icons/bagPocket2.png",
            "sha256": "501d3e66b9c7af52d9eb95be3a4780c61587aa0521c9a64aca6ba436a08b46f2"
          },
          "3": {
            "relativePath": "Graphics/Icons/bagPocket3.png",
            "sha256": "a0d4cfa066b745ac2cd3b163e26370cef1b94e64f7c9942630f5059883511296"
          },
          "4": {
            "relativePath": "Graphics/Icons/bagPocket4.png",
            "sha256": "fde41eca0e24cc0cc0a752641a6dc104297440b9090bcd76791a49fb7de2750e"
          },
          "5": {
            "relativePath": "Graphics/Icons/bagPocket5.png",
            "sha256": "d01d00e2cb7c87df2d938927bc6756b6f115840c1af7d6b9514659f23ad39220"
          },
          "6": {
            "relativePath": "Graphics/Icons/bagPocket6.png",
            "sha256": "908fc010c149d3fb2d7dd7ccaed5b04eb03a1cfe7bb93c40b6454f6953f31acc"
          },
          "7": {
            "relativePath": "Graphics/Icons/bagPocket7.png",
            "sha256": "37da64916455101c8c3fa6eb80ca479a49f71385215a5c8d5a70cacca1d2965c"
          },
          "8": {
            "relativePath": "Graphics/Icons/bagPocket8.png",
            "sha256": "320c5536bf8c46b5894c3f24161b8e6e2a9fb1cef66821c7a618a301a69cfb3d"
          }
        },
        "audioByItemKind": {
          "item": {
            "relativePath": "Audio/ME/FRLG Fanfare - Item (Fanfare Item Get 1).ogg",
            "sha256": "d3476d98cd2c27dc6de10a6479d0a9ca2f1bc5e820d9b962faeb4740759c6586"
          },
          "keyItem": {
            "relativePath": "Audio/ME/FRLG Fanfare - Item Key (Fanfare! Key Item).ogg",
            "sha256": "8a44ed2800dbc95581c784eb7b1ea293b4bf367e57bd023e06c3b6649fa72e9f"
          },
          "machine": {
            "relativePath": "Audio/ME/FRLG Fanfare - Item Machine (Fanfare! Item Obtained (Version 2)).ogg",
            "sha256": "2dfb30229ad35387979f24dfae7ec96d383fa8a7ba79b9c265db7f36a8ed15df"
          }
        }
      },
      {
        "regionId": 102,
        "windowskinPinnedAsset": {
          "relativePath": "Graphics/Windowskins/speech hgss 1.png",
          "sha256": "726a92a6c302f0db44625004a868b79b029fbc8ea491beb8e7ddad72b685b739"
        },
        "iconsByPocket": {
          "1": {
            "relativePath": "Graphics/Icons/bagPocket1.png",
            "sha256": "f30c7d013a4a1ec4db9e398e172e1b913bb9f2c818c8bf7fe5aa6709e92c78f7"
          },
          "2": {
            "relativePath": "Graphics/Icons/bagPocket2.png",
            "sha256": "501d3e66b9c7af52d9eb95be3a4780c61587aa0521c9a64aca6ba436a08b46f2"
          },
          "3": {
            "relativePath": "Graphics/Icons/bagPocket3.png",
            "sha256": "a0d4cfa066b745ac2cd3b163e26370cef1b94e64f7c9942630f5059883511296"
          },
          "4": {
            "relativePath": "Graphics/Icons/bagPocket4.png",
            "sha256": "fde41eca0e24cc0cc0a752641a6dc104297440b9090bcd76791a49fb7de2750e"
          },
          "5": {
            "relativePath": "Graphics/Icons/bagPocket5.png",
            "sha256": "d01d00e2cb7c87df2d938927bc6756b6f115840c1af7d6b9514659f23ad39220"
          },
          "6": {
            "relativePath": "Graphics/Icons/bagPocket6.png",
            "sha256": "908fc010c149d3fb2d7dd7ccaed5b04eb03a1cfe7bb93c40b6454f6953f31acc"
          },
          "7": {
            "relativePath": "Graphics/Icons/bagPocket7.png",
            "sha256": "37da64916455101c8c3fa6eb80ca479a49f71385215a5c8d5a70cacca1d2965c"
          },
          "8": {
            "relativePath": "Graphics/Icons/bagPocket8.png",
            "sha256": "320c5536bf8c46b5894c3f24161b8e6e2a9fb1cef66821c7a618a301a69cfb3d"
          }
        },
        "audioByItemKind": {
          "item": {
            "relativePath": "Audio/ME/FRLG Fanfare - Item (Fanfare Item Get 1).ogg",
            "sha256": "d3476d98cd2c27dc6de10a6479d0a9ca2f1bc5e820d9b962faeb4740759c6586"
          },
          "keyItem": {
            "relativePath": "Audio/ME/FRLG Fanfare - Item Key (Fanfare! Key Item).ogg",
            "sha256": "8a44ed2800dbc95581c784eb7b1ea293b4bf367e57bd023e06c3b6649fa72e9f"
          },
          "machine": {
            "relativePath": "Audio/ME/FRLG Fanfare - Item Machine (Fanfare! Item Obtained (Version 2)).ogg",
            "sha256": "2dfb30229ad35387979f24dfae7ec96d383fa8a7ba79b9c265db7f36a8ed15df"
          }
        }
      },
      {
        "regionId": 103,
        "windowskinPinnedAsset": {
          "relativePath": "Graphics/Windowskins/speech hgss 1.png",
          "sha256": "726a92a6c302f0db44625004a868b79b029fbc8ea491beb8e7ddad72b685b739"
        },
        "iconsByPocket": {
          "1": {
            "relativePath": "Graphics/Icons/bagPocket1.png",
            "sha256": "f30c7d013a4a1ec4db9e398e172e1b913bb9f2c818c8bf7fe5aa6709e92c78f7"
          },
          "2": {
            "relativePath": "Graphics/Icons/bagPocket2.png",
            "sha256": "501d3e66b9c7af52d9eb95be3a4780c61587aa0521c9a64aca6ba436a08b46f2"
          },
          "3": {
            "relativePath": "Graphics/Icons/bagPocket3.png",
            "sha256": "a0d4cfa066b745ac2cd3b163e26370cef1b94e64f7c9942630f5059883511296"
          },
          "4": {
            "relativePath": "Graphics/Icons/bagPocket4.png",
            "sha256": "fde41eca0e24cc0cc0a752641a6dc104297440b9090bcd76791a49fb7de2750e"
          },
          "5": {
            "relativePath": "Graphics/Icons/bagPocket5.png",
            "sha256": "d01d00e2cb7c87df2d938927bc6756b6f115840c1af7d6b9514659f23ad39220"
          },
          "6": {
            "relativePath": "Graphics/Icons/bagPocket6.png",
            "sha256": "908fc010c149d3fb2d7dd7ccaed5b04eb03a1cfe7bb93c40b6454f6953f31acc"
          },
          "7": {
            "relativePath": "Graphics/Icons/bagPocket7.png",
            "sha256": "37da64916455101c8c3fa6eb80ca479a49f71385215a5c8d5a70cacca1d2965c"
          },
          "8": {
            "relativePath": "Graphics/Icons/bagPocket8.png",
            "sha256": "320c5536bf8c46b5894c3f24161b8e6e2a9fb1cef66821c7a618a301a69cfb3d"
          }
        },
        "audioByItemKind": {
          "item": {
            "relativePath": "Audio/ME/FRLG Fanfare - Item (Fanfare Item Get 1).ogg",
            "sha256": "d3476d98cd2c27dc6de10a6479d0a9ca2f1bc5e820d9b962faeb4740759c6586"
          },
          "keyItem": {
            "relativePath": "Audio/ME/FRLG Fanfare - Item Key (Fanfare! Key Item).ogg",
            "sha256": "8a44ed2800dbc95581c784eb7b1ea293b4bf367e57bd023e06c3b6649fa72e9f"
          },
          "machine": {
            "relativePath": "Audio/ME/FRLG Fanfare - Item Machine (Fanfare! Item Obtained (Version 2)).ogg",
            "sha256": "2dfb30229ad35387979f24dfae7ec96d383fa8a7ba79b9c265db7f36a8ed15df"
          }
        }
      }
    ]
  },
  "customPluginPolicy": "excludeCustomBehavior"
}
''';
