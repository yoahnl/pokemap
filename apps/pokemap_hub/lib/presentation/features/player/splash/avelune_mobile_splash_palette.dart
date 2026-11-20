import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter/painting.dart';

enum AveluneMobileSplashPalette {
  ios(
    background: Color(0xff070d1c),
    skyGlow: Color(0xff3d518d),
    moon: Color(0xff5488ec),
    moonLight: Color(0xffa4bbff),
    moonShadow: Color(0xff395ccb),
    wave: Color(0xff41d7c4),
    waveLight: Color(0xffa6ffe2),
    waveShadow: Color(0xff22a9b8),
    star: Color(0xffffbd99),
    starLight: Color(0xffffead4),
    starShadow: Color(0xfffda48f),
    wordmarkAsset: 'assets/avelune/splash/avelune-ios-lettrage-vague.png',
  ),
  android(
    background: Color(0xff091421),
    skyGlow: Color(0xff364d78),
    moon: Color(0xff5488ec),
    moonLight: Color(0xffa4bbff),
    moonShadow: Color(0xff395ccb),
    wave: Color(0xfff4cd7c),
    waveLight: Color(0xffffe5a6),
    waveShadow: Color(0xffdfb262),
    star: Color(0xff24c8d6),
    starLight: Color(0xffb0fcff),
    starShadow: Color(0xff13a9b8),
    wordmarkAsset: 'assets/avelune/splash/avelune-android-lettrage-vague.png',
  );

  const AveluneMobileSplashPalette({
    required this.background,
    required this.skyGlow,
    required this.moon,
    required this.moonLight,
    required this.moonShadow,
    required this.wave,
    required this.waveLight,
    required this.waveShadow,
    required this.star,
    required this.starLight,
    required this.starShadow,
    required this.wordmarkAsset,
  });

  final Color background;
  final Color skyGlow;
  final Color moon;
  final Color moonLight;
  final Color moonShadow;
  final Color wave;
  final Color waveLight;
  final Color waveShadow;
  final Color star;
  final Color starLight;
  final Color starShadow;
  final String wordmarkAsset;

  AssetImage get wordmark => AssetImage(wordmarkAsset, package: 'pokemap_hub');

  static AveluneMobileSplashPalette? forPlatform(TargetPlatform platform) =>
      switch (platform) {
        TargetPlatform.iOS => ios,
        TargetPlatform.android => android,
        _ => null,
      };
}
