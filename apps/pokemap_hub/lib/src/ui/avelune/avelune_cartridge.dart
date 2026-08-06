import 'package:flutter/material.dart';

import 'assets/avelune_material_catalog.dart';
import 'avelune_game_presentation.dart';
import 'avelune_theme.dart';

const double kAveluneCartridgeAspectRatio = 0.7;
const int kAveluneCartridgeHeroArtworkCacheWidth = 512;
const int kAveluneCartridgeHeroArtworkCacheHeight = 640;
const int kAveluneCartridgeShelfArtworkCacheWidth = 256;
const int kAveluneCartridgeShelfArtworkCacheHeight = 320;

enum AveluneCartridgeDisplaySize { hero, shelf }

class AveluneCartridge extends StatelessWidget {
  const AveluneCartridge({
    super.key,
    required this.gameId,
    required this.title,
    required this.displaySize,
    this.subtitle,
    this.artwork,
    this.shellColor,
    this.selected = false,
    this.invalid = false,
    this.onPressed,
    this.onLongPress,
    this.semanticsLabel,
    this.semanticsHint,
    this.artworkHeroTag,
    this.connectorsOpacity = 1,
  }) : addSlot = false;

  const AveluneCartridge.addGame({
    super.key,
    required this.displaySize,
    this.onPressed,
  })  : gameId = 'avelune.add-game',
        title = '',
        subtitle = null,
        artwork = null,
        shellColor = null,
        selected = false,
        invalid = false,
        onLongPress = null,
        semanticsLabel = null,
        semanticsHint = null,
        artworkHeroTag = null,
        connectorsOpacity = 1,
        addSlot = true;

  final String gameId;
  final String title;
  final String? subtitle;
  final ImageProvider<Object>? artwork;
  final Color? shellColor;
  final bool selected;
  final bool invalid;
  final bool addSlot;
  final AveluneCartridgeDisplaySize displaySize;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final String? semanticsLabel;
  final String? semanticsHint;
  final Object? artworkHeroTag;
  final double connectorsOpacity;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final locale = Localizations.maybeLocaleOf(context)?.languageCode;
    final addLabel = locale == 'fr' ? 'Ajouter un jeu' : 'Add a game';
    final unavailable = locale == 'fr' ? 'indisponible' : 'unavailable';
    final resolvedSemanticsLabel = semanticsLabel ??
        (addSlot
            ? addLabel
            : <String>[
                title,
                if (subtitle case final value? when value.trim().isNotEmpty)
                  value,
                if (invalid) unavailable,
              ].join(', '));

    return Semantics(
      button: onPressed != null || onLongPress != null,
      selected: selected,
      label: resolvedSemanticsLabel,
      hint: semanticsHint,
      onTap: onPressed,
      onLongPress: onLongPress,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          onLongPress: onLongPress,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: AspectRatio(
            key: const ValueKey<String>('avelune-cartridge-aspect'),
            aspectRatio: kAveluneCartridgeAspectRatio,
            child: RepaintBoundary(
              key: ValueKey<String>(
                'avelune-cartridge-boundary-$gameId-${displaySize.name}',
              ),
              child: _AveluneCartridgeMold(
                gameId: gameId,
                title: addSlot ? addLabel : title,
                subtitle: subtitle,
                artwork: artwork,
                artworkHeroTag: artworkHeroTag,
                shellColor: shellColor ?? colors.shell,
                displaySize: displaySize,
                addSlot: addSlot,
                selected: selected,
                invalid: invalid,
                connectorsOpacity: connectorsOpacity,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AveluneCartridgeMold extends StatelessWidget {
  const _AveluneCartridgeMold({
    required this.gameId,
    required this.title,
    required this.subtitle,
    required this.artwork,
    required this.artworkHeroTag,
    required this.shellColor,
    required this.displaySize,
    required this.addSlot,
    required this.selected,
    required this.invalid,
    required this.connectorsOpacity,
  });

  final String gameId;
  final String title;
  final String? subtitle;
  final ImageProvider<Object>? artwork;
  final Object? artworkHeroTag;
  final Color shellColor;
  final AveluneCartridgeDisplaySize displaySize;
  final bool addSlot;
  final bool selected;
  final bool invalid;
  final double connectorsOpacity;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final materials = context.aveluneMaterials;
    final cache = _ArtworkCacheSize.from(displaySize);

    return DecoratedBox(
      key: const ValueKey<String>('avelune-cartridge-shell'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          if (selected)
            BoxShadow(
              color: colors.glow.withValues(alpha: 0.4),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          BoxShadow(
            color: colors.background.withValues(alpha: 0.78),
            blurRadius: 9,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final density =
              displaySize == AveluneCartridgeDisplaySize.hero ? 1.0 : 0.94;

          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                left: width * 0.07,
                right: width * 0.07,
                bottom: width * 0.005,
                height: width * 0.1,
                child: ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(
                        Radius.elliptical(width, width * 0.08),
                      ),
                      gradient: RadialGradient(
                        colors: <Color>[
                          colors.background.withValues(alpha: 0.82),
                          colors.background.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: ExcludeSemantics(
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Color.lerp(shellColor, colors.textPrimary, 0.16)!,
                      BlendMode.modulate,
                    ),
                    child: Image.asset(
                      AveluneMaterialCatalog.cartridgeShell.path,
                      key: const ValueKey<String>(
                        'avelune-cartridge-shell-layer',
                      ),
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: width * 0.125,
                right: width * 0.125,
                top: width * 0.25,
                bottom: width * 0.286,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _CartridgeLabel(
                      title: title,
                      subtitle: subtitle,
                      artwork: artwork,
                      artworkHeroTag: artworkHeroTag,
                      addSlot: addSlot,
                      titleSize: width * 0.095 * density,
                      cache: cache,
                      colors: colors,
                    ),
                    ExcludeSemantics(
                      child: Opacity(
                        opacity: materials.glassHighlightOpacity,
                        child: Image.asset(
                          AveluneMaterialCatalog.cartridgeLabelGlass.path,
                          key: const ValueKey<String>(
                            'avelune-cartridge-label-glass-layer',
                          ),
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.high,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: width * 0.15,
                right: width * 0.15,
                top: width * 0.05,
                height: width * 0.145,
                child: _CartridgeBrandBand(
                  fontSize: width * 0.082 * density,
                  colors: colors,
                ),
              ),
              Positioned.fill(
                child: ExcludeSemantics(
                  child: Image.asset(
                    AveluneMaterialCatalog.cartridgeHighlight.path,
                    key: const ValueKey<String>(
                      'avelune-cartridge-highlight-layer',
                    ),
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
              Positioned.fill(
                child: ExcludeSemantics(
                  child: Opacity(
                    opacity: materials.cartridgeWearOpacity,
                    child: Image.asset(
                      AveluneMaterialCatalog.cartridgeWear.path,
                      key: const ValueKey<String>(
                        'avelune-cartridge-wear-layer',
                      ),
                      fit: BoxFit.fill,
                      alignment: _wearAlignmentFor(gameId),
                      filterQuality: FilterQuality.high,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: width * 0.071,
                right: width * 0.071,
                bottom: 0,
                height: width * 0.179,
                child: ExcludeSemantics(
                  child: connectorsOpacity >= 1
                      ? _connectors()
                      : Opacity(
                          key: const ValueKey<String>(
                            'avelune-cartridge-connectors-opacity',
                          ),
                          opacity: connectorsOpacity.clamp(0, 1),
                          child: _connectors(),
                        ),
                ),
              ),
              if (selected)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      key: const ValueKey<String>(
                        'avelune-cartridge-selection-overlay',
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          width: 2,
                          color: colors.primaryBright.withValues(alpha: 0.76),
                        ),
                      ),
                    ),
                  ),
                ),
              if (invalid)
                Positioned(
                  right: width * 0.08,
                  top: width * 0.24,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.background.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.invalid.withValues(alpha: 0.64),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(width * 0.035),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: width * 0.16,
                        color: colors.invalid,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _connectors() => Image.asset(
        AveluneMaterialCatalog.cartridgeConnectors.path,
        key: const ValueKey<String>('avelune-cartridge-connectors'),
        fit: BoxFit.fill,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      );
}

Alignment _wearAlignmentFor(String gameId) {
  final signature = gameId.codeUnits.fold<int>(
    0,
    (value, codeUnit) => (value * 31 + codeUnit) & 0x7fffffff,
  );
  final x = ((signature % 5) - 2) / 2;
  final y = (((signature ~/ 5) % 5) - 2) / 2;
  return Alignment(x, y);
}

class _CartridgeBrandBand extends StatelessWidget {
  const _CartridgeBrandBand({
    required this.fontSize,
    required this.colors,
  });

  final double fontSize;
  final AveluneColors colors;

  @override
  Widget build(BuildContext context) => Center(
        key: const ValueKey<String>('avelune-cartridge-brand-band'),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'AVELUNE',
            maxLines: 1,
            style: TextStyle(
              color: colors.textPrimary.withValues(alpha: 0.76),
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              shadows: <Shadow>[
                Shadow(
                  color: colors.background.withValues(alpha: 0.9),
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      );
}

class _CartridgeLabel extends StatelessWidget {
  const _CartridgeLabel({
    required this.title,
    required this.subtitle,
    required this.artwork,
    required this.artworkHeroTag,
    required this.addSlot,
    required this.titleSize,
    required this.cache,
    required this.colors,
  });

  final String title;
  final String? subtitle;
  final ImageProvider<Object>? artwork;
  final Object? artworkHeroTag;
  final bool addSlot;
  final double titleSize;
  final _ArtworkCacheSize cache;
  final AveluneColors colors;

  @override
  Widget build(BuildContext context) {
    final image = artwork;
    final Widget artworkLayer;
    if (image == null) {
      artworkLayer = _LabelFallback(
        addSlot: addSlot,
        cache: cache,
        colors: colors,
      );
    } else {
      artworkLayer = Image(
        key: const ValueKey<String>('avelune-cartridge-artwork'),
        image: ResizeImage.resizeIfNeeded(
          cache.width,
          cache.height,
          image,
        ),
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
        errorBuilder: (_, __, ___) => _LabelFallback(
          addSlot: addSlot,
          cache: cache,
          colors: colors,
        ),
      );
    }
    final tag = artworkHeroTag;
    final presentedArtwork = tag == null
        ? artworkLayer
        : Hero(
            key: const ValueKey<String>('avelune-hero-artwork'),
            tag: tag,
            transitionOnUserGestures: true,
            flightShuttleBuilder: aveluneArtworkFlightShuttleBuilder,
            child: Material(
              type: MaterialType.transparency,
              child: artworkLayer,
            ),
          );

    return DecoratedBox(
      key: const ValueKey<String>('avelune-cartridge-cover'),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            presentedArtwork,
            Align(
              alignment: Alignment.bottomCenter,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      colors.background.withValues(alpha: 0.04),
                      colors.background.withValues(alpha: 0.9),
                      colors.background.withValues(alpha: 0.97),
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: titleSize * 0.35,
                    vertical: titleSize * 0.28,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        title.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: titleSize,
                          height: 0.98,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (subtitle case final value?
                          when value.trim().isNotEmpty) ...<Widget>[
                        SizedBox(height: titleSize * 0.16),
                        Text(
                          value.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: titleSize * 0.5,
                            height: 1,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabelFallback extends StatelessWidget {
  const _LabelFallback({
    required this.addSlot,
    required this.cache,
    required this.colors,
  });

  final bool addSlot;
  final _ArtworkCacheSize cache;
  final AveluneColors colors;

  @override
  Widget build(BuildContext context) {
    if (!addSlot) {
      return Image.asset(
        kAveluneFallbackArtworkAssetPath,
        key: const ValueKey<String>('avelune-fallback-artwork'),
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        cacheWidth: cache.width,
        cacheHeight: cache.height,
        excludeFromSemantics: true,
        errorBuilder: (_, __, ___) => _neutralFallback(),
      );
    }
    return _neutralFallback();
  }

  Widget _neutralFallback() => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              colors.surfaceElevated,
              colors.primary.withValues(alpha: addSlot ? 0.08 : 0.3),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            addSlot ? Icons.add_rounded : Icons.landscape_rounded,
            color: addSlot ? colors.textSecondary : colors.primaryBright,
            size: addSlot ? 38 : 32,
          ),
        ),
      );
}

class _ArtworkCacheSize {
  const _ArtworkCacheSize(this.width, this.height);

  factory _ArtworkCacheSize.from(AveluneCartridgeDisplaySize displaySize) =>
      switch (displaySize) {
        AveluneCartridgeDisplaySize.hero => const _ArtworkCacheSize(
            kAveluneCartridgeHeroArtworkCacheWidth,
            kAveluneCartridgeHeroArtworkCacheHeight,
          ),
        AveluneCartridgeDisplaySize.shelf => const _ArtworkCacheSize(
            kAveluneCartridgeShelfArtworkCacheWidth,
            kAveluneCartridgeShelfArtworkCacheHeight,
          ),
      };

  final int width;
  final int height;
}
