import 'package:flutter/material.dart';

/// Central color token system for PokeMap UI.
/// Exposes light and dark palettes as a [ThemeExtension] for seamless integration
/// with Flutter's Material 3 [ThemeData].
class PokeMapColorTokens extends ThemeExtension<PokeMapColorTokens> {
  const PokeMapColorTokens({
    // Neutrals
    required this.backgroundApp,
    required this.backgroundShell,
    required this.surfaceBase,
    required this.surfaceRaised,
    required this.surfaceSubtle,
    required this.surfaceHover,
    required this.surfaceSelected,
    required this.borderSubtle,
    required this.borderStrong,
    required this.divider,

    // Text
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.textInverse,

    // Brand / Actions
    required this.brandPrimary,
    required this.brandPrimaryHover,
    required this.brandPrimarySoft,
    required this.brandPrimaryBorder,
    required this.brandCyan,
    required this.brandCyanSoft,

    // Statuses
    required this.success,
    required this.successSoft,
    required this.successBorder,
    required this.warning,
    required this.warningSoft,
    required this.warningBorder,
    required this.error,
    required this.errorSoft,
    required this.errorBorder,
    required this.info,
    required this.infoSoft,

    // Business Colors (Couleurs Métier)
    required this.narrative,
    required this.narrativeSoft,
    required this.cinematic,
    required this.dialogue,
    required this.event,
    required this.combat,
    required this.reward,
    required this.worldRule,
    required this.fact,
    required this.map,

    // Graph / Nodes Colors
    required this.graphStartBg,
    required this.graphStartBorder,
    required this.graphDialogueBg,
    required this.graphDialogueBorder,
    required this.graphBranchBg,
    required this.graphBranchBorder,
    required this.graphCinematicBg,
    required this.graphCinematicBorder,
    required this.graphCombatBg,
    required this.graphCombatBorder,
    required this.graphActionBg,
    required this.graphActionBorder,
    required this.graphRewardBg,
    required this.graphRewardBorder,
    required this.graphMergeBg,
    required this.graphMergeBorder,
    required this.graphEndBg,
    required this.graphEndBorder,
  });

  // ==========================================
  // Properties - Neutrals
  // ==========================================
  
  /// Base application background color.
  final Color backgroundApp;

  /// Main shell panel/sidebar container background.
  final Color backgroundShell;

  /// Primary card/sheet surface background.
  final Color surfaceBase;

  /// Elevated surface (cards/modals in dark mode, defaults to base in light).
  final Color surfaceRaised;

  /// Secondary/subtle content section background.
  final Color surfaceSubtle;

  /// Background on item hover states.
  final Color surfaceHover;

  /// Background on selected item states.
  final Color surfaceSelected;

  /// Subtle border lines (between sections, table headers, etc.).
  final Color borderSubtle;

  /// Strong borders (active borders, search outlines, input fields).
  final Color borderStrong;

  /// Generic thin divider line color.
  final Color divider;

  // ==========================================
  // Properties - Text
  // ==========================================
  
  /// Main body/title text color (highest contrast).
  final Color textPrimary;

  /// Secondary/subtitle text color.
  final Color textSecondary;

  /// Muted labels, placeholders or helper text.
  final Color textMuted;

  /// Non-interactive or disabled text.
  final Color textDisabled;

  /// High contrast text that contrasts with the app theme background.
  final Color textInverse;

  // ==========================================
  // Properties - Brand / Actions
  // ==========================================
  
  /// Primary brand actions color (e.g. key buttons, primary highlight).
  final Color brandPrimary;

  /// Hover state for primary brand buttons.
  final Color brandPrimaryHover;

  /// Soft tint of primary brand for backdrops or tag backgrounds.
  final Color brandPrimarySoft;

  /// Border for primary brand action groups or selections.
  final Color brandPrimaryBorder;

  /// Cyan brand color used for secondary features or metrics.
  final Color brandCyan;

  /// Soft tint of cyan brand for backdrops.
  final Color brandCyanSoft;

  // ==========================================
  // Properties - Statuses
  // ==========================================
  
  /// General success indicator color (validation, checkmarks).
  final Color success;

  /// Soft green backdrop.
  final Color successSoft;

  /// Border for success cards or banners.
  final Color successBorder;

  /// Warning indicator (alerts, warnings, attention).
  final Color warning;

  /// Soft orange backdrop.
  final Color warningSoft;

  /// Border for warning banners or highlights.
  final Color warningBorder;

  /// Error/destruction indicator.
  final Color error;

  /// Soft red/pink backdrop.
  final Color errorSoft;

  /// Border for error banners/popups.
  final Color errorBorder;

  /// Info details indicator.
  final Color info;

  /// Soft blue backdrop.
  final Color infoSoft;

  // ==========================================
  // Properties - Business Colors (Couleurs Métier)
  // ==========================================
  
  /// Narrative sequence theme.
  final Color narrative;

  /// Soft narrative backdrop.
  final Color narrativeSoft;

  /// Cinematic timeline theme.
  final Color cinematic;

  /// Dialogue sequence theme.
  final Color dialogue;

  /// Story/overworld event theme.
  final Color event;

  /// Combat sequence theme.
  final Color combat;

  /// Reward/achievement theme.
  final Color reward;

  /// Overworld/map behavior rule theme.
  final Color worldRule;

  /// Database fact/encyclopedia theme.
  final Color fact;

  /// Grid map editor theme.
  final Color map;

  // ==========================================
  // Properties - Graph / Nodes Colors
  // ==========================================
  
  /// Narrative Graph Start Node background.
  final Color graphStartBg;

  /// Narrative Graph Start Node border.
  final Color graphStartBorder;

  /// Narrative Graph Dialogue Node background.
  final Color graphDialogueBg;

  /// Narrative Graph Dialogue Node border.
  final Color graphDialogueBorder;

  /// Narrative Graph Branch Node background.
  final Color graphBranchBg;

  /// Narrative Graph Branch Node border.
  final Color graphBranchBorder;

  /// Narrative Graph Cinematic Node background.
  final Color graphCinematicBg;

  /// Narrative Graph Cinematic Node border.
  final Color graphCinematicBorder;

  /// Narrative Graph Combat Node background.
  final Color graphCombatBg;

  /// Narrative Graph Combat Node border.
  final Color graphCombatBorder;

  /// Narrative Graph Action Node background.
  final Color graphActionBg;

  /// Narrative Graph Action Node border.
  final Color graphActionBorder;

  /// Narrative Graph Reward Node background.
  final Color graphRewardBg;

  /// Narrative Graph Reward Node border.
  final Color graphRewardBorder;

  /// Narrative Graph Merge Node background.
  final Color graphMergeBg;

  /// Narrative Graph Merge Node border.
  final Color graphMergeBorder;

  /// Narrative Graph End Node background.
  final Color graphEndBg;

  /// Narrative Graph End Node border.
  final Color graphEndBorder;

  // ==========================================
  // Static Constants - Light & Dark
  // ==========================================

  /// Static default configuration for PokeMap Light Mode palette.
  static const PokeMapColorTokens light = PokeMapColorTokens(
    // Neutrals
    backgroundApp: Color(0xFFF5F8FC),
    backgroundShell: Color(0xFFF8FAFE),
    surfaceBase: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF), // Defaults to base in light mode
    surfaceSubtle: Color(0xFFF8FAFD),
    surfaceHover: Color(0xFFF1F6FF),
    surfaceSelected: Color(0xFFEAF2FF),
    borderSubtle: Color(0xFFE2E8F3),
    borderStrong: Color(0xFFC7D3E6),
    divider: Color(0xFFEDF1F7),

    // Text
    textPrimary: Color(0xFF13213A),
    textSecondary: Color(0xFF43516B),
    textMuted: Color(0xFF748199),
    textDisabled: Color(0xFFA8B3C5),
    textInverse: Color(0xFFFFFFFF),

    // Brand / Actions
    brandPrimary: Color(0xFF256DFF),
    brandPrimaryHover: Color(0xFF1D5FE8),
    brandPrimarySoft: Color(0xFFEAF2FF),
    brandPrimaryBorder: Color(0xFF9EC3FF),
    brandCyan: Color(0xFF16B9D9),
    brandCyanSoft: Color(0xFFE6F8FC),

    // Statuses
    success: Color(0xFF2EAD5B),
    successSoft: Color(0xFFEAF8EF),
    successBorder: Color(0xFFA9E6BD),
    warning: Color(0xFFF59E0B),
    warningSoft: Color(0xFFFFF5DF),
    warningBorder: Color(0xFFF8D58B),
    error: Color(0xFFE5484D),
    errorSoft: Color(0xFFFFF0F1),
    errorBorder: Color(0xFFF5B4B8),
    info: Color(0xFF3B82F6),
    infoSoft: Color(0xFFEEF6FF),

    // Business Colors (Couleurs Métier)
    narrative: Color(0xFF7C5CFF),
    narrativeSoft: Color(0xFFF1EDFF),
    cinematic: Color(0xFF9B5CF6),
    dialogue: Color(0xFF3B82F6),
    event: Color(0xFF8B5CF6),
    combat: Color(0xFFEF4444),
    reward: Color(0xFFF59E0B),
    worldRule: Color(0xFF14B8A6),
    fact: Color(0xFFEAB308),
    map: Color(0xFF22A06B),

    // Graph / Nodes Colors
    graphStartBg: Color(0xFFEAF8EF),
    graphStartBorder: Color(0xFF2EAD5B),
    graphDialogueBg: Color(0xFFEEF6FF),
    graphDialogueBorder: Color(0xFF3B82F6),
    graphBranchBg: Color(0xFFF1EDFF),
    graphBranchBorder: Color(0xFF8B5CF6),
    graphCinematicBg: Color(0xFFF5EDFF),
    graphCinematicBorder: Color(0xFF9B5CF6),
    graphCombatBg: Color(0xFFFFF0F1),
    graphCombatBorder: Color(0xFFE5484D),
    graphActionBg: Color(0xFFFFF7E8),
    graphActionBorder: Color(0xFFF59E0B),
    graphRewardBg: Color(0xFFFEF9C3),
    graphRewardBorder: Color(0xFFEAB308),
    graphMergeBg: Color(0xFFEEF6FF),
    graphMergeBorder: Color(0xFF256DFF),
    graphEndBg: Color(0xFFFFF0F1),
    graphEndBorder: Color(0xFFE5484D),
  );

  /// Static default configuration for PokeMap Dark Mode palette.
  static const PokeMapColorTokens dark = PokeMapColorTokens(
    // Neutrals
    backgroundApp: Color(0xFF06111F),
    backgroundShell: Color(0xFF081525),
    surfaceBase: Color(0xFF0D1B2E),
    surfaceRaised: Color(0xFF11243A),
    surfaceSubtle: Color(0xFF0A1728),
    surfaceHover: Color(0xFF172D47),
    surfaceSelected: Color(0xFF102B57),
    borderSubtle: Color(0xFF1E314A),
    borderStrong: Color(0xFF334B68),
    divider: Color(0xFF17263A),

    // Text
    textPrimary: Color(0xFFEDF4FF),
    textSecondary: Color(0xFFB8C4D8),
    textMuted: Color(0xFF7F8DA6),
    textDisabled: Color(0xFF536176),
    textInverse: Color(0xFF06111F),

    // Brand / Actions
    brandPrimary: Color(0xFF4F8CFF),
    brandPrimaryHover: Color(0xFF75A6FF),
    brandPrimarySoft: Color(0xFF102B57),
    brandPrimaryBorder: Color(0xFF2F6FE8),
    brandCyan: Color(0xFF22D3EE),
    brandCyanSoft: Color(0xFF0C3441),

    // Statuses
    success: Color(0xFF3ED879),
    successSoft: Color(0xFF0E3320),
    successBorder: Color(0xFF237A46),
    warning: Color(0xFFFBBF24),
    warningSoft: Color(0xFF3A2A0A),
    warningBorder: Color(0xFF8A6412),
    error: Color(0xFFFF5D6C),
    errorSoft: Color(0xFF3A1118),
    errorBorder: Color(0xFF8A2D38),
    info: Color(0xFF60A5FA),
    infoSoft: Color(0xFF0D2747),

    // Business Colors (Couleurs Métier)
    narrative: Color(0xFFA78BFA),
    narrativeSoft: Color(0xFF251B46),
    cinematic: Color(0xFFC084FC),
    dialogue: Color(0xFF60A5FA),
    event: Color(0xFFA78BFA),
    combat: Color(0xFFFB7185),
    reward: Color(0xFFFBBF24),
    worldRule: Color(0xFF2DD4BF),
    fact: Color(0xFFFACC15),
    map: Color(0xFF4ADE80),

    // Graph / Nodes Colors
    graphStartBg: Color(0xFF0E3320),
    graphStartBorder: Color(0xFF3ED879),
    graphDialogueBg: Color(0xFF0D2747),
    graphDialogueBorder: Color(0xFF60A5FA),
    graphBranchBg: Color(0xFF251B46),
    graphBranchBorder: Color(0xFFA78BFA),
    graphCinematicBg: Color(0xFF2A1A42),
    graphCinematicBorder: Color(0xFFC084FC),
    graphCombatBg: Color(0xFF3A1118),
    graphCombatBorder: Color(0xFFFB7185),
    graphActionBg: Color(0xFF3A2A0A),
    graphActionBorder: Color(0xFFFBBF24),
    graphRewardBg: Color(0xFF332B08),
    graphRewardBorder: Color(0xFFFACC15),
    graphMergeBg: Color(0xFF0D2747),
    graphMergeBorder: Color(0xFF60A5FA),
    graphEndBg: Color(0xFF3A1118),
    graphEndBorder: Color(0xFFFF5D6C),
  );

  // ==========================================
  // ThemeExtension Overrides
  // ==========================================

  @override
  PokeMapColorTokens copyWith({
    Color? backgroundApp,
    Color? backgroundShell,
    Color? surfaceBase,
    Color? surfaceRaised,
    Color? surfaceSubtle,
    Color? surfaceHover,
    Color? surfaceSelected,
    Color? borderSubtle,
    Color? borderStrong,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textDisabled,
    Color? textInverse,
    Color? brandPrimary,
    Color? brandPrimaryHover,
    Color? brandPrimarySoft,
    Color? brandPrimaryBorder,
    Color? brandCyan,
    Color? brandCyanSoft,
    Color? success,
    Color? successSoft,
    Color? successBorder,
    Color? warning,
    Color? warningSoft,
    Color? warningBorder,
    Color? error,
    Color? errorSoft,
    Color? errorBorder,
    Color? info,
    Color? infoSoft,
    Color? narrative,
    Color? narrativeSoft,
    Color? cinematic,
    Color? dialogue,
    Color? event,
    Color? combat,
    Color? reward,
    Color? worldRule,
    Color? fact,
    Color? map,
    Color? graphStartBg,
    Color? graphStartBorder,
    Color? graphDialogueBg,
    Color? graphDialogueBorder,
    Color? graphBranchBg,
    Color? graphBranchBorder,
    Color? graphCinematicBg,
    Color? graphCinematicBorder,
    Color? graphCombatBg,
    Color? graphCombatBorder,
    Color? graphActionBg,
    Color? graphActionBorder,
    Color? graphRewardBg,
    Color? graphRewardBorder,
    Color? graphMergeBg,
    Color? graphMergeBorder,
    Color? graphEndBg,
    Color? graphEndBorder,
  }) {
    return PokeMapColorTokens(
      backgroundApp: backgroundApp ?? this.backgroundApp,
      backgroundShell: backgroundShell ?? this.backgroundShell,
      surfaceBase: surfaceBase ?? this.surfaceBase,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      surfaceSelected: surfaceSelected ?? this.surfaceSelected,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textDisabled: textDisabled ?? this.textDisabled,
      textInverse: textInverse ?? this.textInverse,
      brandPrimary: brandPrimary ?? this.brandPrimary,
      brandPrimaryHover: brandPrimaryHover ?? this.brandPrimaryHover,
      brandPrimarySoft: brandPrimarySoft ?? this.brandPrimarySoft,
      brandPrimaryBorder: brandPrimaryBorder ?? this.brandPrimaryBorder,
      brandCyan: brandCyan ?? this.brandCyan,
      brandCyanSoft: brandCyanSoft ?? this.brandCyanSoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      successBorder: successBorder ?? this.successBorder,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      warningBorder: warningBorder ?? this.warningBorder,
      error: error ?? this.error,
      errorSoft: errorSoft ?? this.errorSoft,
      errorBorder: errorBorder ?? this.errorBorder,
      info: info ?? this.info,
      infoSoft: infoSoft ?? this.infoSoft,
      narrative: narrative ?? this.narrative,
      narrativeSoft: narrativeSoft ?? this.narrativeSoft,
      cinematic: cinematic ?? this.cinematic,
      dialogue: dialogue ?? this.dialogue,
      event: event ?? this.event,
      combat: combat ?? this.combat,
      reward: reward ?? this.reward,
      worldRule: worldRule ?? this.worldRule,
      fact: fact ?? this.fact,
      map: map ?? this.map,
      graphStartBg: graphStartBg ?? this.graphStartBg,
      graphStartBorder: graphStartBorder ?? this.graphStartBorder,
      graphDialogueBg: graphDialogueBg ?? this.graphDialogueBg,
      graphDialogueBorder: graphDialogueBorder ?? this.graphDialogueBorder,
      graphBranchBg: graphBranchBg ?? this.graphBranchBg,
      graphBranchBorder: graphBranchBorder ?? this.graphBranchBorder,
      graphCinematicBg: graphCinematicBg ?? this.graphCinematicBg,
      graphCinematicBorder: graphCinematicBorder ?? this.graphCinematicBorder,
      graphCombatBg: graphCombatBg ?? this.graphCombatBg,
      graphCombatBorder: graphCombatBorder ?? this.graphCombatBorder,
      graphActionBg: graphActionBg ?? this.graphActionBg,
      graphActionBorder: graphActionBorder ?? this.graphActionBorder,
      graphRewardBg: graphRewardBg ?? this.graphRewardBg,
      graphRewardBorder: graphRewardBorder ?? this.graphRewardBorder,
      graphMergeBg: graphMergeBg ?? this.graphMergeBg,
      graphMergeBorder: graphMergeBorder ?? this.graphMergeBorder,
      graphEndBg: graphEndBg ?? this.graphEndBg,
      graphEndBorder: graphEndBorder ?? this.graphEndBorder,
    );
  }

  @override
  PokeMapColorTokens lerp(
    ThemeExtension<PokeMapColorTokens>? other,
    double t,
  ) {
    if (other is! PokeMapColorTokens) {
      return this;
    }
    return PokeMapColorTokens(
      backgroundApp: Color.lerp(backgroundApp, other.backgroundApp, t)!,
      backgroundShell: Color.lerp(backgroundShell, other.backgroundShell, t)!,
      surfaceBase: Color.lerp(surfaceBase, other.surfaceBase, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
      surfaceSelected: Color.lerp(surfaceSelected, other.surfaceSelected, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      brandPrimaryHover: Color.lerp(brandPrimaryHover, other.brandPrimaryHover, t)!,
      brandPrimarySoft: Color.lerp(brandPrimarySoft, other.brandPrimarySoft, t)!,
      brandPrimaryBorder: Color.lerp(brandPrimaryBorder, other.brandPrimaryBorder, t)!,
      brandCyan: Color.lerp(brandCyan, other.brandCyan, t)!,
      brandCyanSoft: Color.lerp(brandCyanSoft, other.brandCyanSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      successBorder: Color.lerp(successBorder, other.successBorder, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      warningBorder: Color.lerp(warningBorder, other.warningBorder, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorSoft: Color.lerp(errorSoft, other.errorSoft, t)!,
      errorBorder: Color.lerp(errorBorder, other.errorBorder, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoSoft: Color.lerp(infoSoft, other.infoSoft, t)!,
      narrative: Color.lerp(narrative, other.narrative, t)!,
      narrativeSoft: Color.lerp(narrativeSoft, other.narrativeSoft, t)!,
      cinematic: Color.lerp(cinematic, other.cinematic, t)!,
      dialogue: Color.lerp(dialogue, other.dialogue, t)!,
      event: Color.lerp(event, other.event, t)!,
      combat: Color.lerp(combat, other.combat, t)!,
      reward: Color.lerp(reward, other.reward, t)!,
      worldRule: Color.lerp(worldRule, other.worldRule, t)!,
      fact: Color.lerp(fact, other.fact, t)!,
      map: Color.lerp(map, other.map, t)!,
      graphStartBg: Color.lerp(graphStartBg, other.graphStartBg, t)!,
      graphStartBorder: Color.lerp(graphStartBorder, other.graphStartBorder, t)!,
      graphDialogueBg: Color.lerp(graphDialogueBg, other.graphDialogueBg, t)!,
      graphDialogueBorder: Color.lerp(graphDialogueBorder, other.graphDialogueBorder, t)!,
      graphBranchBg: Color.lerp(graphBranchBg, other.graphBranchBg, t)!,
      graphBranchBorder: Color.lerp(graphBranchBorder, other.graphBranchBorder, t)!,
      graphCinematicBg: Color.lerp(graphCinematicBg, other.graphCinematicBg, t)!,
      graphCinematicBorder: Color.lerp(graphCinematicBorder, other.graphCinematicBorder, t)!,
      graphCombatBg: Color.lerp(graphCombatBg, other.graphCombatBg, t)!,
      graphCombatBorder: Color.lerp(graphCombatBorder, other.graphCombatBorder, t)!,
      graphActionBg: Color.lerp(graphActionBg, other.graphActionBg, t)!,
      graphActionBorder: Color.lerp(graphActionBorder, other.graphActionBorder, t)!,
      graphRewardBg: Color.lerp(graphRewardBg, other.graphRewardBg, t)!,
      graphRewardBorder: Color.lerp(graphRewardBorder, other.graphRewardBorder, t)!,
      graphMergeBg: Color.lerp(graphMergeBg, other.graphMergeBg, t)!,
      graphMergeBorder: Color.lerp(graphMergeBorder, other.graphMergeBorder, t)!,
      graphEndBg: Color.lerp(graphEndBg, other.graphEndBg, t)!,
      graphEndBorder: Color.lerp(graphEndBorder, other.graphEndBorder, t)!,
    );
  }
}
