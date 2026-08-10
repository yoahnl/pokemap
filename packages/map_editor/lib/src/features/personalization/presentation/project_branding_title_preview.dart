import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../theme/theme.dart';
import '../../../ui/design_system/pokemap_badge.dart';
import '../../../ui/design_system/pokemap_card.dart';

/// Immediate title-screen composition driven by the current branding draft.
class ProjectBrandingTitlePreview extends StatelessWidget {
  const ProjectBrandingTitlePreview({
    super.key,
    required this.projectName,
    required this.projectRootPath,
    required this.branding,
    required this.theme,
    this.typography,
    this.aspectRatio = 16 / 9,
  });

  final String projectName;
  final String projectRootPath;
  final ProjectBrandingProfile branding;
  final ProjectSemanticThemeProfile theme;
  final ProjectTypographyProfile? typography;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final background = _parseHex(theme.titleSurface, colors.surfaceSubtle);
    final foreground = _parseHex(theme.textPrimary, colors.textPrimary);
    final accent = _parseHex(
      branding.accentColor ?? theme.primary,
      colors.brandPrimary,
    );
    final layout = _safeLayoutVariant(branding.layoutVariant);

    return PokeMapCard(
      key: const ValueKey<String>('branding-title-preview'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Aperçu immédiat du titre',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              PokeMapBadge(
                label: _layoutLabel(layout),
                variant: PokeMapBadgeVariant.info,
              ),
            ],
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: background,
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _ProjectBrandingImage(
                      key: const ValueKey<String>(
                        'branding-title-preview-cover',
                      ),
                      projectRootPath: projectRootPath,
                      relativePath: branding.coverPath,
                      fit: BoxFit.cover,
                      fallbackKey: const ValueKey<String>(
                        'branding-title-preview-cover-fallback',
                      ),
                      fallback: ColoredBox(color: background),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            colors.transparent,
                            colors.scrimSoft,
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: _TitleLayout(
                        key: ValueKey<String>(
                          'branding-title-preview-layout-$layout',
                        ),
                        layout: layout,
                        projectName: projectName,
                        projectRootPath: projectRootPath,
                        branding: branding,
                        foreground: foreground,
                        accent: accent,
                        fontFamily: typography?.display.family,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleLayout extends StatelessWidget {
  const _TitleLayout({
    super.key,
    required this.layout,
    required this.projectName,
    required this.projectRootPath,
    required this.branding,
    required this.foreground,
    required this.accent,
    required this.fontFamily,
  });

  final String layout;
  final String projectName;
  final String projectRootPath;
  final ProjectBrandingProfile branding;
  final Color foreground;
  final Color accent;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    final icon = SizedBox.square(
      dimension: 48,
      child: _ProjectBrandingImage(
        key: const ValueKey<String>('branding-title-preview-icon'),
        projectRootPath: projectRootPath,
        relativePath: branding.iconPath,
        fit: BoxFit.contain,
        fallbackKey: const ValueKey<String>(
          'branding-title-preview-icon-fallback',
        ),
        fallback: Icon(
          Icons.catching_pokemon_rounded,
          color: foreground,
          size: 34,
        ),
      ),
    );
    final hero = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280, maxHeight: 100),
      child: _ProjectBrandingImage(
        key: const ValueKey<String>('branding-title-preview-hero'),
        projectRootPath: projectRootPath,
        relativePath: branding.heroPath,
        fit: BoxFit.contain,
        fallbackKey: const ValueKey<String>(
          'branding-title-preview-hero-fallback',
        ),
        fallback: Icon(
          Icons.auto_awesome_outlined,
          color: foreground,
          size: 54,
        ),
      ),
    );
    final title = Text(
      projectName,
      textAlign: layout == 'standard' ? TextAlign.left : TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: foreground,
        fontFamily: fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
        shadows: <Shadow>[
          Shadow(
            color: context.pokeMapColors.scrimSoft,
            blurRadius: 8,
          ),
        ],
      ),
    );
    final accentRule = Container(
      width: 88,
      height: 4,
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(2),
      ),
    );

    return switch (layout) {
      'centered' => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              hero,
              const SizedBox(height: 12),
              title,
              const SizedBox(height: 10),
              accentRule,
              const SizedBox(height: 12),
              icon,
            ],
          ),
        ),
      'cinematic' => Column(
          children: <Widget>[
            Align(alignment: Alignment.topRight, child: icon),
            const Spacer(),
            hero,
            const SizedBox(height: 12),
            title,
            const SizedBox(height: 10),
            accentRule,
          ],
        ),
      _ => Align(
          alignment: Alignment.bottomLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              icon,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    hero,
                    const SizedBox(height: 10),
                    title,
                    const SizedBox(height: 8),
                    accentRule,
                  ],
                ),
              ),
            ],
          ),
        ),
    };
  }
}

class _ProjectBrandingImage extends StatelessWidget {
  const _ProjectBrandingImage({
    super.key,
    required this.projectRootPath,
    required this.relativePath,
    required this.fit,
    required this.fallbackKey,
    required this.fallback,
  });

  final String projectRootPath;
  final String? relativePath;
  final BoxFit fit;
  final Key fallbackKey;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _readProjectImage(projectRootPath, relativePath),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return KeyedSubtree(key: fallbackKey, child: fallback);
        }
        return Image.memory(
          bytes,
          fit: fit,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => KeyedSubtree(
            key: fallbackKey,
            child: fallback,
          ),
        );
      },
    );
  }
}

Future<Uint8List?> _readProjectImage(
  String projectRootPath,
  String? relativePath,
) async {
  if (projectRootPath.trim().isEmpty ||
      relativePath == null ||
      relativePath.trim().isEmpty ||
      p.isAbsolute(relativePath)) {
    return null;
  }
  final root = p.normalize(p.absolute(projectRootPath));
  final candidate = p.normalize(p.join(root, relativePath));
  if (!p.isWithin(root, candidate)) return null;
  try {
    if (await FileSystemEntity.type(candidate, followLinks: false) !=
        FileSystemEntityType.file) {
      return null;
    }
    return await File(candidate).readAsBytes();
  } on FileSystemException {
    return null;
  }
}

Color _parseHex(String value, Color fallback) {
  final normalized = value.trim();
  if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(normalized)) return fallback;
  return Color(
    0xff000000 | int.parse(normalized.substring(1), radix: 16),
  );
}

String _safeLayoutVariant(String value) =>
    const <String>{'standard', 'centered', 'cinematic'}.contains(value)
        ? value
        : 'standard';

String _layoutLabel(String value) => switch (value) {
      'centered' => 'Centrée',
      'cinematic' => 'Cinématique',
      _ => 'Standard',
    };
