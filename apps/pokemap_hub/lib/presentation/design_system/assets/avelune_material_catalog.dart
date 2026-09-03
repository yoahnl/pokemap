import 'package:flutter/widgets.dart';

enum AveluneMaterialAssetRole {
  roomBackground,
  furniture,
  console,
  cartridge,
  artwork,
  logo,
}

@immutable
final class AveluneMaterialAsset {
  const AveluneMaterialAsset({
    required this.id,
    required this.path,
    required this.role,
    required this.minimumSize,
    this.requiresTransparentCorners = false,
  });

  final String id;
  final String path;
  final AveluneMaterialAssetRole role;
  final Size minimumSize;
  final bool requiresTransparentCorners;
}

abstract final class AveluneMaterialCatalog {
  static const String manifestAssetPath =
      'assets/avelune/production_manifest.json';

  static const List<AveluneMaterialAsset> backgrounds = <AveluneMaterialAsset>[
    AveluneMaterialAsset(
      id: 'background.amber',
      path: 'assets/avelune/room/backgrounds/amber.webp',
      role: AveluneMaterialAssetRole.roomBackground,
      minimumSize: Size(768, 1200),
    ),
    AveluneMaterialAsset(
      id: 'background.dawn',
      path: 'assets/avelune/room/backgrounds/dawn.webp',
      role: AveluneMaterialAssetRole.roomBackground,
      minimumSize: Size(768, 1200),
    ),
    AveluneMaterialAsset(
      id: 'background.linen',
      path: 'assets/avelune/room/backgrounds/linen.webp',
      role: AveluneMaterialAssetRole.roomBackground,
      minimumSize: Size(768, 1200),
    ),
    AveluneMaterialAsset(
      id: 'background.violet',
      path: 'assets/avelune/room/backgrounds/violet.webp',
      role: AveluneMaterialAssetRole.roomBackground,
      minimumSize: Size(768, 1200),
    ),
    AveluneMaterialAsset(
      id: 'background.slate',
      path: 'assets/avelune/room/backgrounds/slate.webp',
      role: AveluneMaterialAssetRole.roomBackground,
      minimumSize: Size(768, 1200),
    ),
  ];

  static const List<AveluneMaterialAsset> furniture = <AveluneMaterialAsset>[
    AveluneMaterialAsset(
      id: 'furniture.walnut',
      path: 'assets/avelune/room/furniture/credenza_walnut.webp',
      role: AveluneMaterialAssetRole.furniture,
      minimumSize: Size(768, 700),
      requiresTransparentCorners: true,
    ),
    AveluneMaterialAsset(
      id: 'furniture.ivory',
      path: 'assets/avelune/room/furniture/credenza_ivory.webp',
      role: AveluneMaterialAssetRole.furniture,
      minimumSize: Size(768, 700),
      requiresTransparentCorners: true,
    ),
    AveluneMaterialAsset(
      id: 'furniture.oak',
      path: 'assets/avelune/room/furniture/credenza_oak.webp',
      role: AveluneMaterialAssetRole.furniture,
      minimumSize: Size(768, 700),
      requiresTransparentCorners: true,
    ),
    AveluneMaterialAsset(
      id: 'furniture.ash',
      path: 'assets/avelune/room/furniture/credenza_ash.webp',
      role: AveluneMaterialAssetRole.furniture,
      minimumSize: Size(768, 700),
      requiresTransparentCorners: true,
    ),
    AveluneMaterialAsset(
      id: 'furniture.mahogany',
      path: 'assets/avelune/room/furniture/credenza_mahogany.webp',
      role: AveluneMaterialAssetRole.furniture,
      minimumSize: Size(768, 700),
      requiresTransparentCorners: true,
    ),
    AveluneMaterialAsset(
      id: 'furniture.ebony',
      path: 'assets/avelune/room/furniture/credenza_ebony.webp',
      role: AveluneMaterialAssetRole.furniture,
      minimumSize: Size(768, 700),
      requiresTransparentCorners: true,
    ),
  ];

  static const AveluneMaterialAsset consoleBody = AveluneMaterialAsset(
    id: 'console.body',
    path: 'assets/avelune/objects/console/body.webp',
    role: AveluneMaterialAssetRole.console,
    minimumSize: Size(1200, 300),
    requiresTransparentCorners: true,
  );

  static const AveluneMaterialAsset consoleSlot = AveluneMaterialAsset(
    id: 'console.slot',
    path: 'assets/avelune/objects/console/slot.webp',
    role: AveluneMaterialAssetRole.console,
    minimumSize: Size(600, 80),
    requiresTransparentCorners: true,
  );

  static const AveluneMaterialAsset consoleWear = AveluneMaterialAsset(
    id: 'console.wear',
    path: 'assets/avelune/objects/console/wear.webp',
    role: AveluneMaterialAssetRole.console,
    minimumSize: Size(1024, 300),
    requiresTransparentCorners: true,
  );

  static const AveluneMaterialAsset consoleContactShadow = AveluneMaterialAsset(
    id: 'console.contactShadow',
    path: 'assets/avelune/objects/console/contact_shadow.webp',
    role: AveluneMaterialAssetRole.console,
    minimumSize: Size(1200, 100),
    requiresTransparentCorners: true,
  );

  static const List<AveluneMaterialAsset> consoleLayers =
      <AveluneMaterialAsset>[
    consoleBody,
    consoleSlot,
    consoleWear,
    consoleContactShadow,
  ];

  static const AveluneMaterialAsset cartridgeShell = AveluneMaterialAsset(
    id: 'cartridge.shell',
    path: 'assets/avelune/objects/cartridge/shell.webp',
    role: AveluneMaterialAssetRole.cartridge,
    minimumSize: Size(560, 800),
    requiresTransparentCorners: true,
  );

  static const AveluneMaterialAsset cartridgeHighlight = AveluneMaterialAsset(
    id: 'cartridge.highlight',
    path: 'assets/avelune/objects/cartridge/highlight.webp',
    role: AveluneMaterialAssetRole.cartridge,
    minimumSize: Size(560, 800),
    requiresTransparentCorners: true,
  );

  static const AveluneMaterialAsset cartridgeWear = AveluneMaterialAsset(
    id: 'cartridge.wear',
    path: 'assets/avelune/objects/cartridge/wear.webp',
    role: AveluneMaterialAssetRole.cartridge,
    minimumSize: Size(560, 800),
    requiresTransparentCorners: true,
  );

  static const AveluneMaterialAsset cartridgeConnectors = AveluneMaterialAsset(
    id: 'cartridge.connectors',
    path: 'assets/avelune/objects/cartridge/connectors.webp',
    role: AveluneMaterialAssetRole.cartridge,
    minimumSize: Size(480, 100),
    requiresTransparentCorners: true,
  );

  static const AveluneMaterialAsset cartridgeLabelGlass = AveluneMaterialAsset(
    id: 'cartridge.labelGlass',
    path: 'assets/avelune/objects/cartridge/label_glass.webp',
    role: AveluneMaterialAssetRole.cartridge,
    minimumSize: Size(440, 480),
    requiresTransparentCorners: true,
  );

  static const List<AveluneMaterialAsset> cartridgeLayers =
      <AveluneMaterialAsset>[
    cartridgeShell,
    cartridgeHighlight,
    cartridgeWear,
    cartridgeConnectors,
    cartridgeLabelGlass,
  ];

  static const AveluneMaterialAsset fallbackArtwork = AveluneMaterialAsset(
    id: 'artwork.fallbackMoonlitPath',
    path: 'assets/avelune/artwork/fallback_moonlit_path.webp',
    role: AveluneMaterialAssetRole.artwork,
    minimumSize: Size(512, 800),
  );

  static const AveluneMaterialAsset logo = AveluneMaterialAsset(
    id: 'logo.mark',
    path: 'assets/avelune/logo/avelune_symbol.png',
    role: AveluneMaterialAssetRole.logo,
    minimumSize: Size(512, 512),
    requiresTransparentCorners: true,
  );

  static const AveluneMaterialAsset wordmark = AveluneMaterialAsset(
    id: 'logo.wordmark',
    path: 'assets/avelune/logo/avelune_wordmark.png',
    role: AveluneMaterialAssetRole.logo,
    minimumSize: Size(602, 52),
  );

  static const List<AveluneMaterialAsset> all = <AveluneMaterialAsset>[
    ...backgrounds,
    ...furniture,
    ...consoleLayers,
    ...cartridgeLayers,
    fallbackArtwork,
    logo,
    wordmark,
  ];

  static AveluneMaterialAsset background(String id) =>
      _bySuffix(backgrounds, id, 'background');

  static AveluneMaterialAsset furnitureFinish(String id) =>
      _bySuffix(furniture, id, 'furniture finish');

  static AveluneMaterialAsset _bySuffix(
    List<AveluneMaterialAsset> assets,
    String suffix,
    String kind,
  ) {
    for (final asset in assets) {
      if (asset.id.endsWith('.$suffix')) return asset;
    }
    throw ArgumentError.value(suffix, 'id', 'Unknown Avelune $kind.');
  }
}
