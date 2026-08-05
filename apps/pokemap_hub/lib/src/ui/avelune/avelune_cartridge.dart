import 'package:flutter/material.dart';

import 'avelune_game_presentation.dart';
import 'avelune_theme.dart';

const double kAveluneCartridgeAspectRatio = 0.7;

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
    this.semanticsHint,
    this.artworkHeroTag,
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
        semanticsHint = null,
        artworkHeroTag = null,
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
  final String? semanticsHint;
  final Object? artworkHeroTag;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final locale = Localizations.maybeLocaleOf(context)?.languageCode;
    final addLabel = locale == 'fr' ? 'Ajouter un jeu' : 'Add a game';
    final unavailable = locale == 'fr' ? 'indisponible' : 'unavailable';
    final semanticsLabel = addSlot
        ? addLabel
        : <String>[
            title,
            if (subtitle case final value? when value.trim().isNotEmpty) value,
            if (invalid) unavailable,
          ].join(', ');
    final effectiveShell = shellColor ?? colors.shell;
    final wearAlignment = _wearAlignmentFor(gameId);

    return Semantics(
      button: onPressed != null || onLongPress != null,
      selected: selected,
      label: semanticsLabel,
      hint: semanticsHint,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            key: const ValueKey<String>('avelune-cartridge-aspect'),
            aspectRatio: kAveluneCartridgeAspectRatio,
            child: RepaintBoundary(
              child: DecoratedBox(
                key: const ValueKey<String>('avelune-cartridge-shell'),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    width: selected ? 2 : 1,
                    color: selected
                        ? colors.primaryBright.withValues(alpha: 0.78)
                        : colors.outline,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color.lerp(
                        effectiveShell,
                        colors.textPrimary,
                        0.16,
                      )!,
                      Color.lerp(
                        effectiveShell,
                        colors.shellHighlight,
                        0.16,
                      )!,
                      effectiveShell,
                      Color.lerp(effectiveShell, colors.background, 0.46)!,
                    ],
                    stops: const <double>[0, 0.16, 0.58, 1],
                  ),
                  boxShadow: <BoxShadow>[
                    if (selected)
                      BoxShadow(
                        color: colors.glow.withValues(alpha: 0.34),
                        blurRadius: 13,
                      ),
                    BoxShadow(
                      color: colors.background.withValues(alpha: 0.72),
                      blurRadius: 7,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final density =
                          displaySize == AveluneCartridgeDisplaySize.hero
                              ? 1.0
                              : 0.94;
                      return Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          ExcludeSemantics(
                            child: Opacity(
                              opacity: kAvelunePlasticTextureOpacity,
                              child: Image.asset(
                                kAveluneMatteAbsTextureAssetPath,
                                key: const ValueKey<String>(
                                  'avelune-cartridge-material-texture',
                                ),
                                fit: BoxFit.cover,
                                color: effectiveShell,
                                colorBlendMode: BlendMode.modulate,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ),
                          _CartridgeRim(colors: colors),
                          Positioned(
                            left: width * 0.035,
                            top: width * 0.035,
                            width: width * 0.055,
                            height: width * 0.23,
                            child: _CartridgeMoldedRail(colors: colors),
                          ),
                          Positioned(
                            right: width * 0.035,
                            top: width * 0.035,
                            width: width * 0.055,
                            height: width * 0.23,
                            child: _CartridgeMoldedRail(colors: colors),
                          ),
                          Positioned(
                            left: width * 0.08,
                            right: width * 0.08,
                            top: width * 0.07,
                            height: width * 0.17,
                            child: _CartridgeBrandBand(
                              fontSize: width * 0.085 * density,
                              colors: colors,
                            ),
                          ),
                          Positioned(
                            left: width * 0.1,
                            right: width * 0.1,
                            top: width * 0.3,
                            bottom: width * 0.34,
                            child: _artworkLabel(
                              title: addSlot ? addLabel : title,
                              titleSize: width * 0.105 * density,
                              colors: colors,
                            ),
                          ),
                          Positioned(
                            left: width * 0.12,
                            right: width * 0.12,
                            bottom: width * 0.17,
                            height: width * 0.08,
                            child: _CartridgeDetails(colors: colors),
                          ),
                          Positioned(
                            left: width * 0.075,
                            bottom: width * 0.205,
                            child: _CartridgeScrew(
                              colors: colors,
                              size: width * 0.035,
                            ),
                          ),
                          Positioned(
                            right: width * 0.075,
                            bottom: width * 0.205,
                            child: _CartridgeScrew(
                              colors: colors,
                              size: width * 0.035,
                            ),
                          ),
                          ExcludeSemantics(
                            child: Opacity(
                              opacity: kAveluneCartridgeWearOpacity,
                              child: Image.asset(
                                kAveluneAgedAbsWearAssetPath,
                                key: const ValueKey<String>(
                                  'avelune-cartridge-wear-texture',
                                ),
                                fit: BoxFit.cover,
                                alignment: wearAlignment,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ),
                          Positioned(
                            left: width * 0.08,
                            right: width * 0.08,
                            bottom: 0,
                            height: width * 0.15,
                            child: _CartridgeConnectors(colors: colors),
                          ),
                          if (invalid)
                            Positioned(
                              right: width * 0.08,
                              top: width * 0.27,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colors.background.withValues(
                                    alpha: 0.86,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(width * 0.035),
                                  child: Icon(
                                    Icons.error_outline_rounded,
                                    size: width * 0.17,
                                    color: colors.invalid,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _artworkLabel({
    required String title,
    required double titleSize,
    required AveluneColors colors,
  }) {
    return _CartridgeLabel(
      title: title,
      subtitle: subtitle,
      artwork: artwork,
      artworkHeroTag: artworkHeroTag,
      addSlot: addSlot,
      titleSize: titleSize,
      colors: colors,
    );
  }
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

class _CartridgeRim extends StatelessWidget {
  const _CartridgeRim({required this.colors});

  final AveluneColors colors;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(4),
        child: DecoratedBox(
          key: const ValueKey<String>('avelune-cartridge-bevel'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: colors.textPrimary.withValues(alpha: 0.15),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                colors.textPrimary.withValues(alpha: 0.08),
                colors.outline.withValues(alpha: 0.06),
                colors.background.withValues(alpha: 0.24),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: colors.background.withValues(alpha: 0.48),
                ),
              ),
            ),
          ),
        ),
      );
}

class _CartridgeMoldedRail extends StatelessWidget {
  const _CartridgeMoldedRail({required this.colors});

  final AveluneColors colors;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: colors.background.withValues(alpha: 0.44),
          ),
          gradient: LinearGradient(
            colors: <Color>[
              colors.textPrimary.withValues(alpha: 0.12),
              colors.outline.withValues(alpha: 0.24),
              colors.background.withValues(alpha: 0.34),
            ],
          ),
        ),
      );
}

class _CartridgeScrew extends StatelessWidget {
  const _CartridgeScrew({required this.colors, required this.size});

  final AveluneColors colors;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.background.withValues(alpha: 0.6),
          border: Border.all(
            color: colors.textPrimary.withValues(alpha: 0.18),
          ),
        ),
        child: Center(
          child: Container(
            width: size * 0.5,
            height: 1,
            color: colors.outline,
          ),
        ),
      );
}

class _CartridgeBrandBand extends StatelessWidget {
  const _CartridgeBrandBand({
    required this.fontSize,
    required this.colors,
  });

  final double fontSize;
  final AveluneColors colors;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        key: const ValueKey<String>('avelune-cartridge-brand-band'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              colors.textPrimary.withValues(alpha: 0.1),
              colors.background.withValues(alpha: 0.46),
            ],
          ),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'AVELUNE',
              maxLines: 1,
              style: TextStyle(
                color: colors.textPrimary.withValues(alpha: 0.72),
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
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
    required this.colors,
  });

  final String title;
  final String? subtitle;
  final ImageProvider<Object>? artwork;
  final Object? artworkHeroTag;
  final bool addSlot;
  final double titleSize;
  final AveluneColors colors;

  @override
  Widget build(BuildContext context) {
    final image = artwork;
    final Widget artworkLayer;
    if (image == null) {
      artworkLayer = _LabelFallback(addSlot: addSlot, colors: colors);
    } else {
      artworkLayer = Image(
        image: image,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        errorBuilder: (_, __, ___) => _LabelFallback(
          addSlot: addSlot,
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
        border: Border.all(color: colors.outline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            presentedArtwork,
            IgnorePointer(
              child: DecoratedBox(
                key: const ValueKey<String>(
                  'avelune-cartridge-cover-gloss',
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const <double>[0, 0.24, 0.5],
                    colors: <Color>[
                      colors.textPrimary.withValues(alpha: 0),
                      colors.textPrimary.withValues(alpha: 0.12),
                      colors.textPrimary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      colors.background.withValues(alpha: 0.08),
                      colors.background.withValues(alpha: 0.86),
                      colors.background.withValues(alpha: 0.96),
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: titleSize * 0.35,
                    vertical: titleSize * 0.25,
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
  const _LabelFallback({required this.addSlot, required this.colors});

  final bool addSlot;
  final AveluneColors colors;

  @override
  Widget build(BuildContext context) {
    if (!addSlot) {
      return Image.asset(
        kAveluneFallbackArtworkAssetPath,
        key: const ValueKey<String>('avelune-fallback-artwork'),
        fit: BoxFit.cover,
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

class _CartridgeDetails extends StatelessWidget {
  const _CartridgeDetails({required this.colors});

  final AveluneColors colors;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _detailLine(colors),
          Icon(
            Icons.change_history_rounded,
            color: colors.outline,
            size: 13,
          ),
          _detailLine(colors),
        ],
      );

  Widget _detailLine(AveluneColors colors) => Expanded(
        child: Container(
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          color: colors.outline.withValues(alpha: 0.74),
        ),
      );
}

class _CartridgeConnectors extends StatelessWidget {
  const _CartridgeConnectors({required this.colors});

  final AveluneColors colors;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        key: const ValueKey<String>('avelune-cartridge-connectors'),
        decoration: BoxDecoration(
          color: colors.background.withValues(alpha: 0.8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          border: Border(
            top: BorderSide(
              color: colors.textPrimary.withValues(alpha: 0.16),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 3, 5, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List<Widget>.generate(
              11,
              (index) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        index.isEven
                            ? colors.gold
                            : colors.gold.withValues(alpha: 0.76),
                        Color.lerp(colors.gold, colors.background, 0.34)!,
                      ],
                    ),
                    image: const DecorationImage(
                      image: AssetImage(kAveluneBrushedBrassTextureAssetPath),
                      fit: BoxFit.cover,
                      opacity: 0.2,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
