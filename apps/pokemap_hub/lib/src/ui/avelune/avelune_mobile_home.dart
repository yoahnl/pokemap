import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../hub_dashboard_controller.dart';
import '../hub_game_views.dart';
import 'avelune_cartridge.dart';
import 'avelune_console.dart';
import 'avelune_game_details.dart';
import 'avelune_game_presentation.dart';
import 'avelune_theme.dart';

const String kAveluneLogoAssetPath =
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/180.png';

class AveluneMobileHome extends StatefulWidget {
  const AveluneMobileHome({
    super.key,
    required this.productName,
    required this.snapshot,
    required this.actions,
    this.referenceTime,
  });

  final String productName;
  final HubDashboardSnapshot snapshot;
  final HubUiActions actions;
  final DateTime? referenceTime;

  @override
  State<AveluneMobileHome> createState() => _AveluneMobileHomeState();
}

class _AveluneMobileHomeState extends State<AveluneMobileHome> {
  String? _selectedGameId;

  @override
  void initState() {
    super.initState();
    _selectedGameId = _initialGame(widget.snapshot.games)?.game.gameId;
  }

  @override
  void didUpdateWidget(covariant AveluneMobileHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    final games = widget.snapshot.games;
    if (games.every((view) => view.game.gameId != _selectedGameId)) {
      _selectedGameId = _initialGame(games)?.game.gameId;
    }
  }

  HubGameView? get _selectedGame {
    for (final game in widget.snapshot.games) {
      if (game.game.gameId == _selectedGameId) return game;
    }
    return _initialGame(widget.snapshot.games);
  }

  void _selectGame(HubGameView game) {
    if (_selectedGameId == game.game.gameId) return;
    if (widget.snapshot.preferences.hapticsEnabled) {
      unawaited(HapticFeedback.selectionClick());
    }
    setState(() => _selectedGameId = game.game.gameId);
  }

  bool _canLaunch(HubGameView game) =>
      game.activity.installationHealthy &&
      (game.activity.canContinue
          ? widget.actions.onContinue != null
          : widget.actions.onNewGame != null);

  void _launch(HubGameView game) {
    if (!_canLaunch(game)) return;
    if (game.activity.canContinue) {
      widget.actions.onContinue!(game);
    } else {
      widget.actions.onNewGame!(game);
    }
  }

  void _openDetails(HubGameView game) {
    if (widget.snapshot.preferences.hapticsEnabled) {
      unawaited(HapticFeedback.mediumImpact());
    }
    final now = widget.referenceTime ?? DateTime.now();
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    unawaited(
      Navigator.of(context).push<void>(
        PageRouteBuilder<void>(
          settings: const RouteSettings(name: 'avelune-game-details'),
          transitionDuration:
              reducedMotion ? Duration.zero : const Duration(milliseconds: 420),
          reverseTransitionDuration:
              reducedMotion ? Duration.zero : const Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) => AveluneGameDetailsScreen(
            game: game,
            referenceTime: now,
          ),
          transitionsBuilder: (_, animation, __, child) {
            if (reducedMotion) return child;
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.025),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }

  void _openActivity(HubGameView game) {
    _selectGame(game);
    if (game.activity.installationHealthy && game.activity.canContinue) {
      widget.actions.onContinue?.call(game);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final selected = _selectedGame;
    final now = widget.referenceTime ?? DateTime.now();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        gradient: RadialGradient(
          center: const Alignment(0, -0.72),
          radius: 1.15,
          colors: <Color>[
            Color.lerp(colors.background, colors.woodHighlight, 0.11)!,
            colors.background,
            Color.lerp(colors.background, Colors.black, 0.24)!,
          ],
          stops: const <double>[0, 0.48, 1],
        ),
      ),
      child: CustomScrollView(
        key: const ValueKey<String>('avelune-home-scroll'),
        slivers: <Widget>[
          SliverSafeArea(
            bottom: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed(<Widget>[
                  AveluneHeader(
                    productName: widget.productName,
                    onImportRequested: widget.actions.onImportRequested,
                  ),
                  const SizedBox(height: 14),
                  AveluneHeroConsoleSection(
                    game: selected,
                    referenceTime: now,
                    onInsert: selected != null && _canLaunch(selected)
                        ? _launch
                        : null,
                    onDetailsRequested: _openDetails,
                    hapticsEnabled: widget.snapshot.preferences.hapticsEnabled,
                    clickSoundEnabled:
                        widget.snapshot.preferences.masterVolume > 0 &&
                            widget.snapshot.preferences.effectsVolume > 0,
                  ),
                  if (selected == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: _AveluneEmptyLibraryAction(
                        onPressed: widget.actions.onImportRequested,
                      ),
                    ),
                  const SizedBox(height: 26),
                  AveluneGameShelf(
                    games: widget.snapshot.games,
                    selectedGameId: selected?.game.gameId,
                    onGameSelected: _selectGame,
                    onAddGame: widget.actions.onImportRequested,
                  ),
                  const SizedBox(height: 26),
                  AveluneRecentActivitySection(
                    games: widget.snapshot.games,
                    referenceTime: now,
                    onActivitySelected: _openActivity,
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

HubGameView? _initialGame(List<HubGameView> games) {
  if (games.isEmpty) return null;
  final ordered = games.toList(growable: false)
    ..sort((left, right) {
      final leftSave = left.activity.lastSaveAt;
      final rightSave = right.activity.lastSaveAt;
      if (leftSave != null || rightSave != null) {
        if (leftSave == null) return 1;
        if (rightSave == null) return -1;
        final bySave = rightSave.compareTo(leftSave);
        if (bySave != 0) return bySave;
      }
      return right.game.currentVersion.installedAt.compareTo(
        left.game.currentVersion.installedAt,
      );
    });
  return ordered.first;
}

class AveluneHeader extends StatelessWidget {
  const AveluneHeader({
    super.key,
    required this.productName,
    required this.onImportRequested,
  });

  final String productName;
  final VoidCallback? onImportRequested;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final french = Localizations.localeOf(context).languageCode == 'fr';
    return SizedBox(
      height: 54,
      child: Row(
        children: <Widget>[
          const _AveluneLogo(),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                productName.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.fade,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4.5,
                ),
              ),
            ),
          ),
          IconButton(
            key: const ValueKey<String>('avelune-header-import'),
            tooltip: french ? 'Ajouter un jeu' : 'Add a game',
            onPressed: onImportRequested,
            color: colors.textPrimary,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

class _AveluneLogo extends StatelessWidget {
  const _AveluneLogo();

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    return Semantics(
      image: true,
      label: 'Avelune',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox.square(
          dimension: 48,
          child: Image.asset(
            kAveluneLogoAssetPath,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (_, __, ___) => DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.nightlight_round,
                color: colors.primaryBright,
                size: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AveluneHeroConsoleSection extends StatefulWidget {
  const AveluneHeroConsoleSection({
    super.key,
    required this.game,
    required this.referenceTime,
    required this.onInsert,
    required this.onDetailsRequested,
    required this.hapticsEnabled,
    required this.clickSoundEnabled,
  });

  final HubGameView? game;
  final DateTime referenceTime;
  final ValueChanged<HubGameView>? onInsert;
  final ValueChanged<HubGameView> onDetailsRequested;
  final bool hapticsEnabled;
  final bool clickSoundEnabled;

  @override
  State<AveluneHeroConsoleSection> createState() =>
      _AveluneHeroConsoleSectionState();
}

class _AveluneHeroConsoleSectionState extends State<AveluneHeroConsoleSection>
    with TickerProviderStateMixin {
  late final AnimationController _floatController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  late final AnimationController _insertionController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    reverseDuration: const Duration(milliseconds: 260),
  );
  bool _launching = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _floatController
        ..stop()
        ..value = 0.5;
    } else if (!_floatController.isAnimating && !_launching) {
      _floatController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AveluneHeroConsoleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game?.game.gameId != widget.game?.game.gameId) {
      _insertionController.value = 0;
      _launching = false;
    }
  }

  Future<void> _insertCartridge() async {
    final game = widget.game;
    final onInsert = widget.onInsert;
    if (game == null || onInsert == null || _launching) return;
    setState(() => _launching = true);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    _floatController.stop();
    if (reducedMotion) {
      _insertionController.value = 1;
    } else {
      await _insertionController.animateTo(
        0.72,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeInCubic,
      );
    }
    if (!mounted) return;
    if (widget.hapticsEnabled) {
      unawaited(HapticFeedback.mediumImpact());
    }
    if (widget.clickSoundEnabled) {
      unawaited(SystemSound.play(SystemSoundType.click));
    }
    if (!reducedMotion) {
      await _insertionController.animateTo(
        1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
      );
    }
    if (!mounted) return;
    onInsert(game);
    if (!mounted) return;
    if (reducedMotion) {
      _insertionController.value = 0;
    } else {
      await _insertionController.reverse();
    }
    if (mounted) {
      setState(() => _launching = false);
      if (!reducedMotion) {
        _floatController.repeat(reverse: true);
      }
    }
  }

  void _openDetails() {
    final game = widget.game;
    if (game == null || _launching) return;
    widget.onDetailsRequested(game);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _insertionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth;
          final cartridgeWidth = (available * 0.36).clamp(112.0, 148.0);
          final consoleWidth = (available * 0.88).clamp(260.0, 356.0);
          final reducedMotion = MediaQuery.disableAnimationsOf(context);
          return Column(
            children: <Widget>[
              SizedBox(
                width: cartridgeWidth,
                child: AnimatedBuilder(
                  animation: Listenable.merge(<Listenable>[
                    _floatController,
                    _insertionController,
                  ]),
                  builder: (context, _) => _heroCartridge(
                    context,
                    reducedMotion: reducedMotion,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: available,
                child: AnimatedBuilder(
                  animation: _insertionController,
                  builder: (context, _) => AveluneConsoleDock(
                    consoleWidth: consoleWidth,
                    insertionProgress: _insertionController.value,
                  ),
                ),
              ),
              if (widget.game case final game?) ...<Widget>[
                const SizedBox(height: 10),
                _AveluneInsertionHint(
                  game: game,
                  referenceTime: widget.referenceTime,
                  launchAvailable: widget.onInsert != null,
                ),
              ],
            ],
          );
        },
      );

  Widget _heroCartridge(
    BuildContext context, {
    required bool reducedMotion,
  }) {
    final game = widget.game;
    if (game == null) {
      return SizedBox(
        height: 54,
        child: Center(
          child: Text(
            Localizations.localeOf(context).languageCode == 'fr'
                ? 'Console prête'
                : 'Console ready',
            style: TextStyle(
              color: context.aveluneColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );
    }
    final colors = context.aveluneColors;
    final french = Localizations.localeOf(context).languageCode == 'fr';
    final floatOffset = reducedMotion ? 0.0 : -2 - _floatController.value * 4;
    final insertion = _insertionController.value;
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          bottom: -3,
          child: Opacity(
            opacity: 1 - insertion,
            child: Container(
              width: 86,
              height: 12,
              decoration: BoxDecoration(
                color: colors.glow.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(40),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: colors.glow.withValues(alpha: 0.58),
                    blurRadius: 24,
                    spreadRadius: 7,
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSwitcher(
          key: const ValueKey<String>('avelune-cartridge-exchange'),
          duration:
              reducedMotion ? Duration.zero : const Duration(milliseconds: 440),
          reverseDuration:
              reducedMotion ? Duration.zero : const Duration(milliseconds: 360),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.center,
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          ),
          transitionBuilder: (child, animation) {
            return AnimatedBuilder(
              animation: animation,
              child: child,
              builder: (context, animatedChild) {
                final progress = Curves.easeOutCubic.transform(animation.value);
                final currentKey = ValueKey<String>(game.game.gameId);
                final incoming = child.key == currentKey;
                final distance = 1 - progress;
                return Opacity(
                  opacity: progress,
                  child: FractionalTranslation(
                    translation: Offset(
                      (incoming ? 0.38 : -0.32) * distance,
                      0.18 * distance,
                    ),
                    child: Transform.scale(
                      scale: 0.9 + progress * 0.1,
                      alignment: Alignment.bottomCenter,
                      child: animatedChild,
                    ),
                  ),
                );
              },
            );
          },
          child: KeyedSubtree(
            key: ValueKey<String>(game.game.gameId),
            child: Transform.translate(
              key: const ValueKey<String>('avelune-inserting-cartridge'),
              offset: Offset(0, floatOffset + insertion * 82),
              child: Transform.scale(
                scale: 1 - insertion * 0.07,
                alignment: Alignment.bottomCenter,
                child: AveluneCartridge(
                  key: const ValueKey<String>('avelune-hero-cartridge'),
                  gameId: game.game.gameId,
                  title: game.game.title,
                  subtitle: game.game.authorName,
                  artwork: aveluneArtworkFor(game),
                  artworkHeroTag: aveluneArtworkHeroTag(game.game.gameId),
                  shellColor: aveluneShellColorFor(context, game),
                  selected: true,
                  invalid: !game.activity.installationHealthy,
                  displaySize: AveluneCartridgeDisplaySize.hero,
                  onPressed: widget.onInsert == null ? null : _insertCartridge,
                  onLongPress: _openDetails,
                  semanticsHint: _heroSemanticsHint(
                    game,
                    french: french,
                    launchAvailable: widget.onInsert != null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AveluneInsertionHint extends StatelessWidget {
  const _AveluneInsertionHint({
    required this.game,
    required this.referenceTime,
    required this.launchAvailable,
  });

  final HubGameView game;
  final DateTime referenceTime;
  final bool launchAvailable;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final french = Localizations.localeOf(context).languageCode == 'fr';
    final activity = game.activity;
    final invalid = !activity.installationHealthy;
    final label = invalid
        ? (french ? 'JEU INDISPONIBLE' : 'GAME UNAVAILABLE')
        : !launchAvailable
            ? (french ? 'LANCEMENT INDISPONIBLE' : 'LAUNCH UNAVAILABLE')
            : activity.canContinue
                ? (french ? 'Insérer pour continuer' : 'Insert to continue')
                : (french ? 'Insérer pour jouer' : 'Insert to play');
    final detail = invalid
        ? (french
            ? 'Certains fichiers nécessaires sont manquants.'
            : 'Some required files are missing.')
        : activity.canContinue && activity.lastSaveAt != null
            ? '${french ? 'Dernière partie' : 'Last game'} • '
                '${formatAveluneRelativeTime(activity.lastSaveAt!, referenceTime, french: french)}'
            : (french
                ? 'Appui long • Détails du jeu'
                : 'Long press • Game details');
    return Semantics(
      liveRegion: true,
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                invalid ? Icons.error_outline_rounded : Icons.south_rounded,
                size: 17,
                color: invalid ? colors.invalid : colors.primaryBright,
              ),
              const SizedBox(width: 7),
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: invalid ? colors.invalid : colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

String _heroSemanticsHint(
  HubGameView game, {
  required bool french,
  required bool launchAvailable,
}) {
  if (!game.activity.installationHealthy || !launchAvailable) {
    return french
        ? 'Appui long pour afficher les détails du jeu.'
        : 'Long press to show game details.';
  }
  final action = game.activity.canContinue
      ? (french ? 'CONTINUER' : 'CONTINUE')
      : (french ? 'JOUER' : 'PLAY');
  return french
      ? '$action. Touchez pour insérer la cartouche. Appui long pour les détails.'
      : '$action. Tap to insert the cartridge. Long press for details.';
}

class _AveluneEmptyLibraryAction extends StatelessWidget {
  const _AveluneEmptyLibraryAction({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final french = Localizations.localeOf(context).languageCode == 'fr';
    return Column(
      children: <Widget>[
        Text(
          french ? 'Aucun jeu installé' : 'No installed games',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.aveluneColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          french
              ? 'Ajoutez votre première cartouche Avelune.'
              : 'Add your first Avelune cartridge.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.aveluneColors.textSecondary),
        ),
        const SizedBox(height: 14),
        _AveluneActionSurface(
          key: const ValueKey<String>('avelune-empty-import'),
          label: french ? 'AJOUTER UN JEU' : 'ADD A GAME',
          detail: french
              ? 'Choisir un package compatible'
              : 'Choose a compatible package',
          onPressed: onPressed,
        ),
      ],
    );
  }
}

class _AveluneActionSurface extends StatelessWidget {
  const _AveluneActionSurface({
    super.key,
    required this.label,
    required this.detail,
    required this.onPressed,
  });

  final String label;
  final String detail;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final enabled = onPressed != null;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 58,
          minWidth: 216,
          maxWidth: 292,
        ),
        child: Semantics(
          button: true,
          enabled: enabled,
          label: '$label, $detail',
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: enabled ? colors.primaryBright : colors.outline,
                  ),
                  gradient: LinearGradient(
                    colors: <Color>[
                      enabled ? colors.primary : colors.surfaceElevated,
                      enabled
                          ? Color.lerp(colors.primary, colors.background, 0.4)!
                          : colors.surface,
                    ],
                  ),
                  boxShadow: <BoxShadow>[
                    if (enabled)
                      BoxShadow(
                        color: colors.glow.withValues(alpha: 0.42),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        enabled
                            ? Icons.play_arrow_rounded
                            : Icons.error_outline_rounded,
                        color:
                            enabled ? colors.textPrimary : colors.textSecondary,
                        size: 25,
                      ),
                      const SizedBox(width: 9),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: enabled
                                    ? colors.textPrimary
                                    : colors.textSecondary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              detail,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 11,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AveluneGameShelf extends StatelessWidget {
  const AveluneGameShelf({
    super.key,
    required this.games,
    required this.selectedGameId,
    required this.onGameSelected,
    required this.onAddGame,
  });

  final List<HubGameView> games;
  final String? selectedGameId;
  final ValueChanged<HubGameView> onGameSelected;
  final VoidCallback? onAddGame;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final french = Localizations.localeOf(context).languageCode == 'fr';
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          key: const ValueKey<String>('avelune-furniture-bridge'),
          left: 0,
          right: 0,
          top: -93,
          height: 138,
          child: _AveluneFurnitureBridge(colors: colors),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _SectionTitle(
                icon: Icons.sports_esports_rounded,
                label: french ? 'MES JEUX' : 'MY GAMES',
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth =
                    (constraints.maxWidth * 0.245).clamp(82.0, 98.0);
                final itemHeight = itemWidth / kAveluneCartridgeAspectRatio;
                return SizedBox(
                  height: itemHeight + 51,
                  child: DecoratedBox(
                    key: const ValueKey<String>('avelune-game-cabinet'),
                    decoration: BoxDecoration(
                      color: colors.wood,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colors.woodHighlight.withValues(alpha: 0.84),
                        width: 1.5,
                      ),
                      image: const DecorationImage(
                        image: AssetImage(kAveluneWalnutTextureAssetPath),
                        fit: BoxFit.cover,
                        opacity: 0.9,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: colors.background.withValues(alpha: 0.96),
                          blurRadius: 20,
                          offset: const Offset(0, 11),
                        ),
                        BoxShadow(
                          color: colors.woodHighlight.withValues(alpha: 0.22),
                          blurRadius: 5,
                          offset: const Offset(0, -1),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: <Widget>[
                          Positioned(
                            key: const ValueKey<String>(
                              'avelune-shelf-cavity',
                            ),
                            left: 10,
                            right: 10,
                            top: 11,
                            bottom: 31,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: colors.background,
                                  width: 2,
                                ),
                                gradient: RadialGradient(
                                  center: const Alignment(0, -0.7),
                                  radius: 1.25,
                                  colors: <Color>[
                                    colors.surface.withValues(alpha: 0.72),
                                    colors.background,
                                  ],
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: colors.background
                                        .withValues(alpha: 0.98),
                                    blurRadius: 13,
                                    spreadRadius: 3,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            key: const ValueKey<String>(
                              'avelune-shelf-top-rail',
                            ),
                            left: 0,
                            right: 0,
                            top: 0,
                            height: 12,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[
                                    colors.textPrimary.withValues(alpha: 0.12),
                                    colors.woodHighlight.withValues(alpha: 0.3),
                                    colors.background.withValues(alpha: 0.34),
                                  ],
                                ),
                                border: Border(
                                  bottom: BorderSide(
                                    color: colors.background
                                        .withValues(alpha: 0.78),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top: 10,
                            bottom: 28,
                            width: 11,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: <Color>[
                                    colors.textPrimary.withValues(alpha: 0.09),
                                    colors.background.withValues(alpha: 0.48),
                                  ],
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: colors.background
                                        .withValues(alpha: 0.88),
                                    blurRadius: 9,
                                    offset: const Offset(5, 0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 10,
                            bottom: 28,
                            width: 11,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: <Color>[
                                    colors.background.withValues(alpha: 0.55),
                                    colors.textPrimary.withValues(alpha: 0.07),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 36,
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                Image.asset(
                                  kAveluneWalnutTextureAssetPath,
                                  key: const ValueKey<String>(
                                    'avelune-shelf-wood-texture',
                                  ),
                                  fit: BoxFit.cover,
                                  alignment: Alignment.bottomCenter,
                                  excludeFromSemantics: true,
                                ),
                                DecoratedBox(
                                  key: const ValueKey<String>(
                                    'avelune-shelf-plinth',
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: <Color>[
                                        colors.textPrimary
                                            .withValues(alpha: 0.2),
                                        colors.woodHighlight
                                            .withValues(alpha: 0.14),
                                        colors.background
                                            .withValues(alpha: 0.52),
                                      ],
                                      stops: const <double>[0, 0.18, 1],
                                    ),
                                    border: Border(
                                      top: BorderSide(
                                        color: colors.woodHighlight,
                                        width: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 28,
                                  right: 28,
                                  bottom: 5,
                                  height: 15,
                                  child: _AveluneFurnitureDrawers(
                                    colors: colors,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 13,
                            bottom: 36,
                            child: ListView.separated(
                              key: const ValueKey<String>(
                                'avelune-game-shelf-list',
                              ),
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.fromLTRB(14, 2, 14, 0),
                              itemCount: games.length + 1,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                if (index == games.length) {
                                  return SizedBox(
                                    width: itemWidth,
                                    child: AveluneCartridge.addGame(
                                      key: const ValueKey<String>(
                                        'avelune-add-game-cartridge',
                                      ),
                                      displaySize:
                                          AveluneCartridgeDisplaySize.shelf,
                                      onPressed: onAddGame,
                                    ),
                                  );
                                }
                                final game = games[index];
                                return SizedBox(
                                  width: itemWidth,
                                  child: AveluneCartridge(
                                    key: ValueKey<String>(
                                      'avelune-shelf-${game.game.gameId}',
                                    ),
                                    gameId: game.game.gameId,
                                    title: game.game.title,
                                    subtitle: game.game.authorName,
                                    artwork: aveluneArtworkFor(game),
                                    shellColor:
                                        aveluneShellColorFor(context, game),
                                    selected:
                                        game.game.gameId == selectedGameId,
                                    invalid: !game.activity.installationHealthy,
                                    displaySize:
                                        AveluneCartridgeDisplaySize.shelf,
                                    onPressed: () => onGameSelected(game),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _AveluneFurnitureBridge extends StatelessWidget {
  const _AveluneFurnitureBridge({required this.colors});

  final AveluneColors colors;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Stack(
          children: <Widget>[
            for (final alignment in <Alignment>[
              Alignment.centerLeft,
              Alignment.centerRight,
            ])
              Align(
                alignment: alignment,
                child: SizedBox(
                  width: 18,
                  height: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage(kAveluneWalnutTextureAssetPath),
                        fit: BoxFit.cover,
                        opacity: 0.96,
                      ),
                      gradient: LinearGradient(
                        colors: <Color>[
                          colors.textPrimary.withValues(alpha: 0.12),
                          colors.background.withValues(alpha: 0.48),
                          colors.woodHighlight.withValues(alpha: 0.2),
                        ],
                      ),
                      border: Border.all(
                        color: colors.woodHighlight.withValues(alpha: 0.42),
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: colors.background.withValues(alpha: 0.92),
                          blurRadius: 10,
                          offset: alignment == Alignment.centerLeft
                              ? const Offset(5, 0)
                              : const Offset(-5, 0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage(kAveluneWalnutTextureAssetPath),
                    fit: BoxFit.cover,
                    opacity: 0.92,
                  ),
                  border: Border(
                    top: BorderSide(
                      color: colors.woodHighlight.withValues(alpha: 0.72),
                    ),
                    bottom: BorderSide(
                      color: colors.background.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _AveluneFurnitureDrawers extends StatelessWidget {
  const _AveluneFurnitureDrawers({required this.colors});

  final AveluneColors colors;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        key: const ValueKey<String>('avelune-furniture-drawers'),
        child: Row(
          children: <Widget>[
            for (var index = 0; index < 2; index++) ...<Widget>[
              if (index > 0) const SizedBox(width: 8),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: colors.background.withValues(alpha: 0.7),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        colors.woodHighlight.withValues(alpha: 0.18),
                        colors.background.withValues(alpha: 0.25),
                      ],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: colors.textPrimary.withValues(alpha: 0.06),
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 18,
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(
                          colors: <Color>[
                            colors.gold.withValues(alpha: 0.4),
                            colors.background.withValues(alpha: 0.7),
                            colors.gold.withValues(alpha: 0.52),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}

class AveluneRecentActivitySection extends StatelessWidget {
  const AveluneRecentActivitySection({
    super.key,
    required this.games,
    required this.referenceTime,
    required this.onActivitySelected,
  });

  final List<HubGameView> games;
  final DateTime referenceTime;
  final ValueChanged<HubGameView> onActivitySelected;

  @override
  Widget build(BuildContext context) {
    final french = Localizations.localeOf(context).languageCode == 'fr';
    final recent = games
        .where((game) => game.activity.lastSaveAt != null)
        .toList(growable: false)
      ..sort(
        (left, right) => right.activity.lastSaveAt!.compareTo(
          left.activity.lastSaveAt!,
        ),
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SectionTitle(
          icon: Icons.schedule_rounded,
          label: french ? 'ACTIVITÉ RÉCENTE' : 'RECENT ACTIVITY',
        ),
        const SizedBox(height: 10),
        _RecentCabinet(
          child: recent.isEmpty
              ? _RecentEmptyState(french: french)
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.aveluneColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.aveluneColors.outline,
                    ),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(7),
                    itemCount: recent.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 5),
                    itemBuilder: (context, index) {
                      final game = recent[index];
                      return _RecentActivityTile(
                        key: ValueKey<String>(
                          'avelune-activity-${game.game.gameId}',
                        ),
                        game: game,
                        referenceTime: referenceTime,
                        onPressed: () => onActivitySelected(game),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _RecentCabinet extends StatelessWidget {
  const _RecentCabinet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    return Container(
      key: const ValueKey<String>('avelune-recent-wood-frame'),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: colors.wood,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.woodHighlight.withValues(alpha: 0.72),
        ),
        image: const DecorationImage(
          image: AssetImage(kAveluneWalnutTextureAssetPath),
          fit: BoxFit.cover,
          opacity: 0.62,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.background.withValues(alpha: 0.9),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RecentEmptyState extends StatelessWidget {
  const _RecentEmptyState({required this.french});

  final bool french;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: context.aveluneColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.aveluneColors.outline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: <Widget>[
              Text(
                french ? 'Aucune activité récente' : 'No recent activity',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.aveluneColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                french
                    ? 'Lancez un jeu pour retrouver ici vos dernières parties.'
                    : 'Launch a game to find your latest sessions here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.aveluneColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
}

class _RecentActivityTile extends StatelessWidget {
  const _RecentActivityTile({
    super.key,
    required this.game,
    required this.referenceTime,
    required this.onPressed,
  });

  final HubGameView game;
  final DateTime referenceTime;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final french = Localizations.localeOf(context).languageCode == 'fr';
    return Semantics(
      button: true,
      label: '${game.game.title}, '
          '${french ? 'dernière sauvegarde' : 'latest save'}',
      child: Material(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(11),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 62),
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Row(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox.square(
                      dimension: 48,
                      child: _ActivityArtwork(game: game),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          game.game.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          french ? 'Dernière sauvegarde' : 'Latest save',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatAveluneRelativeTime(
                      game.activity.lastSaveAt!,
                      referenceTime,
                      french: french,
                      compact: true,
                    ),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityArtwork extends StatelessWidget {
  const _ActivityArtwork({required this.game});

  final HubGameView game;

  @override
  Widget build(BuildContext context) {
    final image = aveluneArtworkFor(game);
    if (image != null) {
      return Image(
        image: image,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }
    return _fallback(context);
  }

  Widget _fallback(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: aveluneShellColorFor(context, game),
        ),
        child: Icon(
          Icons.landscape_rounded,
          color: context.aveluneColors.textPrimary,
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          Icon(icon, size: 19, color: context.aveluneColors.gold),
          const SizedBox(width: 7),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                label,
                style: TextStyle(
                  color: context.aveluneColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      );
}
