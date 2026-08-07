import 'package:flutter/material.dart';

import 'package:pokemap_hub/presentation/design_system/foundation/avelune_color_tokens.dart';
import 'package:pokemap_hub/presentation/design_system/foundation/avelune_depth_tokens.dart';
import 'package:pokemap_hub/presentation/design_system/foundation/avelune_material_tokens.dart';
import 'package:pokemap_hub/presentation/design_system/foundation/avelune_motion_tokens.dart';
import 'package:pokemap_hub/presentation/design_system/foundation/avelune_typography_tokens.dart';
import 'package:pokemap_hub/presentation/design_system/theme/avelune_theme_data.dart';

extension AveluneThemeContext on BuildContext {
  AveluneThemeData get aveluneTheme {
    final theme = Theme.of(this);
    final disableAnimations =
        MediaQuery.maybeOf(this)?.disableAnimations ?? false;
    return AveluneThemeData(
      colors: theme.extension<AveluneColors>() ?? AveluneColors.standard,
      typography: theme.extension<AveluneTypographyTokens>() ??
          AveluneTypographyTokens.standard,
      depth: theme.extension<AveluneDepthTokens>() ??
          AveluneThemeData.standard.depth,
      materials: theme.extension<AveluneMaterialTokens>() ??
          AveluneMaterialTokens.standard,
      motion: disableAnimations
          ? AveluneMotionTokens.reduced
          : theme.extension<AveluneMotionTokens>() ??
              AveluneMotionTokens.standard,
    );
  }

  AveluneColors get aveluneColors => aveluneTheme.colors;
  AveluneTypographyTokens get aveluneTypography => aveluneTheme.typography;
  AveluneDepthTokens get aveluneDepth => aveluneTheme.depth;
  AveluneMaterialTokens get aveluneMaterials => aveluneTheme.materials;
  AveluneMotionTokens get aveluneMotion => aveluneTheme.motion;
}
