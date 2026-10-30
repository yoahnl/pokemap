import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

@immutable
final class PokeMapPlayerBattleChrome
    extends ThemeExtension<PokeMapPlayerBattleChrome> {
  const PokeMapPlayerBattleChrome({
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSelected,
    required this.underplate,
    required this.textPrimary,
    required this.textSecondary,
    required this.outline,
    required this.focus,
    required this.water,
    required this.normal,
    required this.hudSurface,
    required this.hudText,
    required this.moveSurface,
    required this.moveSelected,
    required this.moveText,
    required this.dockSurface,
    required this.dockText,
    this.moveOutline = const Color(0xFFFD443E),
    this.moveFocus = const Color(0xFFFD443E),
    this.moveDisabled = const Color(0xFF3D4854),
    this.moveDisabledText = const Color(0xFFEEF0F4),
    this.moveMuted = const Color(0xFF727986),
    this.hudEdge = const Color(0xFFD6DBE0),
    this.hudHpLabel = const Color(0xFFFAFCF8),
    this.hudLevel = const Color(0xFFF3CC50),
    this.narrationSurface = const Color(0xFFFFFFFF),
    this.narrationText = const Color(0xFF070A10),
    this.hpHealthy = const Color(0xFF4DD968),
    this.hpWarning = const Color(0xFFF2BD37),
    this.hpDanger = const Color(0xFFEF6756),
    this.experience = const Color(0xFF36B8ED),
    this.typeGrass = const Color(0xFF438856),
    this.typePoison = const Color(0xFF91629A),
    this.typeWater = const Color(0xFF447C9B),
    this.typeFire = const Color(0xFFB85C3E),
    this.typeElectric = const Color(0xFFB28A22),
    this.typeNormal = const Color(0xFF7C7D86),
    this.commandFight = const Color(0xFFAE4D43),
    this.commandParty = const Color(0xFF3E705F),
    this.commandBag = const Color(0xFF81602A),
    this.commandRun = const Color(0xFF41596A),
  });

  static const darkFieldManual = PokeMapPlayerBattleChrome(
    surface: Color(0xFF111916),
    surfaceRaised: Color(0xFF1E2A25),
    surfaceSelected: Color(0xFF173229),
    underplate: Color(0xFF0B120F),
    textPrimary: Color(0xFFF3ECD9),
    textSecondary: Color(0xFF93A299),
    outline: Color(0xFF827866),
    focus: Color(0xFFFD443E),
    water: Color(0xFF3E9FE8),
    normal: Color(0xFFA99F8E),
    hudSurface: Color(0xFF171D23),
    hudText: Color(0xFFFFFFFF),
    moveSurface: Color(0xFFFFFFFF),
    moveSelected: Color(0xFF070A10),
    moveText: Color(0xFF070A10),
    dockSurface: Color(0x00000000),
    dockText: Color(0xFF070A10),
  );

  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSelected;
  final Color underplate;
  final Color textPrimary;
  final Color textSecondary;
  final Color outline;
  final Color focus;
  final Color water;
  final Color normal;
  final Color hudSurface;
  final Color hudText;
  final Color moveSurface;
  final Color moveSelected;
  final Color moveText;
  final Color dockSurface;
  final Color dockText;
  final Color moveOutline;
  final Color moveFocus;
  final Color moveDisabled;
  final Color moveDisabledText;
  final Color moveMuted;
  final Color hudEdge;
  final Color hudHpLabel;
  final Color hudLevel;
  final Color narrationSurface;
  final Color narrationText;
  final Color hpHealthy;
  final Color hpWarning;
  final Color hpDanger;
  final Color experience;
  final Color typeGrass;
  final Color typePoison;
  final Color typeWater;
  final Color typeFire;
  final Color typeElectric;
  final Color typeNormal;
  final Color commandFight;
  final Color commandParty;
  final Color commandBag;
  final Color commandRun;

  Color typeBadge(String typeId) => switch (typeId.trim().toLowerCase()) {
    'grass' || 'bug' => typeGrass,
    'water' || 'ice' => typeWater,
    'fire' => typeFire,
    'electric' => typeElectric,
    'poison' || 'psychic' || 'ghost' || 'fairy' => typePoison,
    _ => typeNormal,
  };

  @override
  PokeMapPlayerBattleChrome copyWith({
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceSelected,
    Color? underplate,
    Color? textPrimary,
    Color? textSecondary,
    Color? outline,
    Color? focus,
    Color? water,
    Color? normal,
    Color? hudSurface,
    Color? hudText,
    Color? moveSurface,
    Color? moveSelected,
    Color? moveText,
    Color? dockSurface,
    Color? dockText,
    Color? moveOutline,
    Color? moveFocus,
    Color? moveDisabled,
    Color? moveDisabledText,
    Color? moveMuted,
    Color? hudEdge,
    Color? hudHpLabel,
    Color? hudLevel,
    Color? narrationSurface,
    Color? narrationText,
    Color? hpHealthy,
    Color? hpWarning,
    Color? hpDanger,
    Color? experience,
    Color? typeGrass,
    Color? typePoison,
    Color? typeWater,
    Color? typeFire,
    Color? typeElectric,
    Color? typeNormal,
    Color? commandFight,
    Color? commandParty,
    Color? commandBag,
    Color? commandRun,
  }) => PokeMapPlayerBattleChrome(
    surface: surface ?? this.surface,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    surfaceSelected: surfaceSelected ?? this.surfaceSelected,
    underplate: underplate ?? this.underplate,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    outline: outline ?? this.outline,
    focus: focus ?? this.focus,
    water: water ?? this.water,
    normal: normal ?? this.normal,
    hudSurface: hudSurface ?? this.hudSurface,
    hudText: hudText ?? this.hudText,
    moveSurface: moveSurface ?? this.moveSurface,
    moveSelected: moveSelected ?? this.moveSelected,
    moveText: moveText ?? this.moveText,
    dockSurface: dockSurface ?? this.dockSurface,
    dockText: dockText ?? this.dockText,
    moveOutline: moveOutline ?? this.moveOutline,
    moveFocus: moveFocus ?? this.moveFocus,
    moveDisabled: moveDisabled ?? this.moveDisabled,
    moveDisabledText: moveDisabledText ?? this.moveDisabledText,
    moveMuted: moveMuted ?? this.moveMuted,
    hudEdge: hudEdge ?? this.hudEdge,
    hudHpLabel: hudHpLabel ?? this.hudHpLabel,
    hudLevel: hudLevel ?? this.hudLevel,
    narrationSurface: narrationSurface ?? this.narrationSurface,
    narrationText: narrationText ?? this.narrationText,
    hpHealthy: hpHealthy ?? this.hpHealthy,
    hpWarning: hpWarning ?? this.hpWarning,
    hpDanger: hpDanger ?? this.hpDanger,
    experience: experience ?? this.experience,
    typeGrass: typeGrass ?? this.typeGrass,
    typePoison: typePoison ?? this.typePoison,
    typeWater: typeWater ?? this.typeWater,
    typeFire: typeFire ?? this.typeFire,
    typeElectric: typeElectric ?? this.typeElectric,
    typeNormal: typeNormal ?? this.typeNormal,
    commandFight: commandFight ?? this.commandFight,
    commandParty: commandParty ?? this.commandParty,
    commandBag: commandBag ?? this.commandBag,
    commandRun: commandRun ?? this.commandRun,
  );

  @override
  PokeMapPlayerBattleChrome lerp(
    covariant ThemeExtension<PokeMapPlayerBattleChrome>? other,
    double t,
  ) {
    if (other is! PokeMapPlayerBattleChrome) return this;
    return PokeMapPlayerBattleChrome(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceSelected: Color.lerp(surfaceSelected, other.surfaceSelected, t)!,
      underplate: Color.lerp(underplate, other.underplate, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      water: Color.lerp(water, other.water, t)!,
      normal: Color.lerp(normal, other.normal, t)!,
      hudSurface: Color.lerp(hudSurface, other.hudSurface, t)!,
      hudText: Color.lerp(hudText, other.hudText, t)!,
      moveSurface: Color.lerp(moveSurface, other.moveSurface, t)!,
      moveSelected: Color.lerp(moveSelected, other.moveSelected, t)!,
      moveText: Color.lerp(moveText, other.moveText, t)!,
      dockSurface: Color.lerp(dockSurface, other.dockSurface, t)!,
      dockText: Color.lerp(dockText, other.dockText, t)!,
      moveOutline: Color.lerp(moveOutline, other.moveOutline, t)!,
      moveFocus: Color.lerp(moveFocus, other.moveFocus, t)!,
      moveDisabled: Color.lerp(moveDisabled, other.moveDisabled, t)!,
      moveDisabledText: Color.lerp(
        moveDisabledText,
        other.moveDisabledText,
        t,
      )!,
      moveMuted: Color.lerp(moveMuted, other.moveMuted, t)!,
      hudEdge: Color.lerp(hudEdge, other.hudEdge, t)!,
      hudHpLabel: Color.lerp(hudHpLabel, other.hudHpLabel, t)!,
      hudLevel: Color.lerp(hudLevel, other.hudLevel, t)!,
      narrationSurface: Color.lerp(
        narrationSurface,
        other.narrationSurface,
        t,
      )!,
      narrationText: Color.lerp(narrationText, other.narrationText, t)!,
      hpHealthy: Color.lerp(hpHealthy, other.hpHealthy, t)!,
      hpWarning: Color.lerp(hpWarning, other.hpWarning, t)!,
      hpDanger: Color.lerp(hpDanger, other.hpDanger, t)!,
      experience: Color.lerp(experience, other.experience, t)!,
      typeGrass: Color.lerp(typeGrass, other.typeGrass, t)!,
      typePoison: Color.lerp(typePoison, other.typePoison, t)!,
      typeWater: Color.lerp(typeWater, other.typeWater, t)!,
      typeFire: Color.lerp(typeFire, other.typeFire, t)!,
      typeElectric: Color.lerp(typeElectric, other.typeElectric, t)!,
      typeNormal: Color.lerp(typeNormal, other.typeNormal, t)!,
      commandFight: Color.lerp(commandFight, other.commandFight, t)!,
      commandParty: Color.lerp(commandParty, other.commandParty, t)!,
      commandBag: Color.lerp(commandBag, other.commandBag, t)!,
      commandRun: Color.lerp(commandRun, other.commandRun, t)!,
    );
  }
}

@immutable
final class PokeMapPlayerBattleTheme
    extends ThemeExtension<PokeMapPlayerBattleTheme> {
  const PokeMapPlayerBattleTheme(this.profile);

  final ProjectBattlePresentationProfile profile;

  @override
  PokeMapPlayerBattleTheme copyWith({
    ProjectBattlePresentationProfile? profile,
  }) => PokeMapPlayerBattleTheme(profile ?? this.profile);

  @override
  PokeMapPlayerBattleTheme lerp(
    covariant ThemeExtension<PokeMapPlayerBattleTheme>? other,
    double t,
  ) => t < .5 || other is! PokeMapPlayerBattleTheme ? this : other;
}

extension PokeMapPlayerBattleContext on BuildContext {
  ProjectBattlePresentationProfile? get playerBattleProfile =>
      Theme.of(this).extension<PokeMapPlayerBattleTheme>()?.profile;

  PokeMapPlayerBattleChrome get playerBattleChrome =>
      Theme.of(this).extension<PokeMapPlayerBattleChrome>() ??
      PokeMapPlayerBattleChrome.darkFieldManual;
}
