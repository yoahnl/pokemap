import 'package:flutter/material.dart';

import '../foundation/player_menu_components.dart';
import '../foundation/player_paged_layout.dart';
import '../theme/pokemap_player_menu_theme.dart';
import '../theme/pokemap_player_theme.dart';

enum PlayerMenuGalleryBackdrop { dark, light, contrast }

class PlayerMenuPrimitivesGallery extends StatefulWidget {
  const PlayerMenuPrimitivesGallery({
    super.key,
    this.opaque = false,
    this.highContrast = false,
    this.reducedMotion = false,
    this.textScale = 1,
    this.backdrop = PlayerMenuGalleryBackdrop.dark,
  });

  final bool opaque;
  final bool highContrast;
  final bool reducedMotion;
  final double textScale;
  final PlayerMenuGalleryBackdrop backdrop;

  @override
  State<PlayerMenuPrimitivesGallery> createState() =>
      _PlayerMenuPrimitivesGalleryState();
}

class _PlayerMenuPrimitivesGalleryState
    extends State<PlayerMenuPrimitivesGallery> {
  String _selectedId = 'selected';
  String _receipt = 'Aucune modification du projet.';

  void _select(String id) => setState(() {
    _selectedId = id;
    _receipt = 'Sélection locale : $id.';
  });

  @override
  Widget build(BuildContext context) => Theme(
    data: PokeMapPlayerTheme.dark(
      highContrast: widget.highContrast,
      reducedMotion: widget.reducedMotion,
    ),
    child: MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(widget.textScale),
        disableAnimations: widget.reducedMotion,
      ),
      child: PlayerMenuThemeScope(
        opaque: widget.opaque,
        child: Builder(builder: _buildGallery),
      ),
    ),
  );

  Widget _buildGallery(BuildContext context) {
    final tokens = context.playerMenuTheme;
    final viewport = MediaQuery.sizeOf(context);
    final compact =
        viewport.width < 700 ||
        viewport.height < 480 ||
        (viewport.width < 1000 &&
            MediaQuery.textScalerOf(context).scale(1) > 1.4);
    final background = switch (widget.backdrop) {
      PlayerMenuGalleryBackdrop.dark => tokens.backdrop,
      PlayerMenuGalleryBackdrop.light => tokens.backdropLight,
      PlayerMenuGalleryBackdrop.contrast => tokens.backdropContrast,
    };
    return PlayerMenuFrame(
      backdrop: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              background,
              if (widget.backdrop == PlayerMenuGalleryBackdrop.contrast)
                tokens.backdropPattern,
              background,
            ],
          ),
        ),
      ),
      header: PlayerMenuHeader(
        icon: Icons.palette_outlined,
        key: const ValueKey('gallery-header'),
        title: compact
            ? 'Galerie des menus'
            : 'Tous les menus et les états de votre aventure',
        secondary: compact ? null : const Text('Galerie de démonstration'),
      ),
      footer: PlayerMenuFooter(
        hints: compact
            ? const []
            : [
                const PlayerMenuKeyHint(glyph: '↑ ↓', label: 'Parcourir'),
                const PlayerMenuKeyHint(glyph: 'Entrée', label: 'Choisir'),
              ],
        returnAction: SizedBox(
          width: 100 + MediaQuery.textScalerOf(context).scale(60),
          child: PlayerMenuSelectableRow(
            id: 'gallery-return',
            label: 'Retour',
            leading: const Icon(Icons.arrow_back),
            onPressed: () => _select('selected'),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final states = _states(context);
          final details = <Widget>[
            ..._details(context, constraints.maxHeight < 220),
            if (compact)
              _heading(
                context,
                'Tous les menus et les états de votre aventure',
              ),
          ];
          if (constraints.maxWidth < 1000 || constraints.maxHeight < 400) {
            return PlayerPagedList(
              sideNavigation: true,
              key: const ValueKey('gallery-content'),
              revealChildKey: _selectedId == 'selected'
                  ? states.first.key
                  : ValueKey('gallery-$_selectedId'),
              children: [...states, ...details],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: PlayerPagedList(
                  sideNavigation: true,
                  key: const ValueKey('gallery-states'),
                  revealChildKey: _selectedId == 'selected'
                      ? states.first.key
                      : ValueKey('gallery-$_selectedId'),
                  children: states,
                ),
              ),
              const SizedBox(width: PlayerSpacing.lg),
              Expanded(
                child: PlayerPagedList(
                  sideNavigation: true,
                  key: const ValueKey('gallery-details'),
                  children: details,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _states(BuildContext context) => [
    _heading(context, 'Choisir, puis agir'),
    _row(
      'selected',
      'Sélection conservée',
      subtitle: 'Le focus peut atteindre une autre commande.',
    ),
    _row(
      'normal',
      'Un compagnon au nom particulièrement long',
      subtitle: 'Un nom sur deux lignes reste lisible.',
    ),
    _row('hovered', 'Survol discret', hovered: true),
    _row('focused', 'Focus clavier indépendant', focused: true),
    _row('pressed', 'Pression en cours', pressed: true),
    _row(
      'disabled',
      'Action indisponible',
      disabledReason: 'Une cible compatible est nécessaire.',
    ),
    _row('busy', 'Traitement en cours', busy: true),
  ];

  Widget _row(
    String id,
    String label, {
    String? subtitle,
    bool hovered = false,
    bool focused = false,
    bool pressed = false,
    bool busy = false,
    String? disabledReason,
  }) => Padding(
    key: ValueKey('gallery-$id'),
    padding: const EdgeInsets.only(bottom: PlayerSpacing.xs),
    child: PlayerMenuSelectableRow(
      id: 'gallery-$id',
      label: label,
      labelMaxLines: 4,
      subtitle: subtitle,
      selected: _selectedId == id,
      hovered: hovered,
      focused: focused,
      pressed: pressed,
      busy: busy,
      disabledReason: disabledReason,
      leading: const Icon(Icons.catching_pokemon),
      onPressed: () => _select(id),
    ),
  );

  List<Widget> _details(BuildContext context, bool short) => [
    _heading(context, 'Des informations lisibles'),
    const PlayerMenuPanel(
      child: Wrap(
        spacing: PlayerSpacing.md,
        runSpacing: PlayerSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          PlayerMenuPortrait(
            circular: true,
            semanticLabel: 'Portrait de démonstration',
            child: Icon(Icons.person_outline, size: 48),
          ),
          PlayerMenuBadge(label: 'Type', kind: PlayerMenuBadgeKind.type),
          PlayerMenuBadge(label: 'Statut', kind: PlayerMenuBadgeKind.status),
        ],
      ),
    ),
    const ExcludeSemantics(
      child: SizedBox(height: 96, child: Icon(Icons.pets_outlined, size: 88)),
    ),
    for (final value in [100.0, 50.0, 1.0, 0.0])
      PlayerMenuPanel(
        child: PlayerMenuGauge(
          value: value,
          maximum: 100,
          label: 'PV',
          status: value == 0 ? 'KO' : 'Normal',
          tone: value == 0
              ? PlayerMenuGaugeTone.danger
              : PlayerMenuGaugeTone.normal,
        ),
      ),
    const PlayerMenuPanel(
      child: PlayerMenuGauge(
        value: 20,
        maximum: 25,
        label: 'PP',
        kind: PlayerMenuGaugeKind.experience,
      ),
    ),
    ..._feedbackEntries(
      context,
      short: short,
      id: 'gallery-empty',
      title: 'Aucun élément',
      message: 'Le contenu apparaîtra lorsqu’il sera disponible.',
    ),
    ..._feedbackEntries(
      context,
      short: short,
      id: 'gallery-error',
      title: 'Ressource indisponible',
      message: 'Le nom et les actions restent accessibles.',
      kind: PlayerMenuFeedbackKind.error,
    ),
    ..._feedbackEntries(
      context,
      short: short,
      id: 'gallery-receipt',
      title: 'Aperçu sans sauvegarde',
      message: _receipt,
      kind: PlayerMenuFeedbackKind.receipt,
    ),
  ];

  List<Widget> _feedbackEntries(
    BuildContext context, {
    required bool short,
    required String id,
    required String title,
    required String message,
    PlayerMenuFeedbackKind kind = PlayerMenuFeedbackKind.empty,
  }) => [
    PlayerMenuDetailTransition(
      contentKey: ValueKey((id, message)),
      child: PlayerMenuFeedback(
        id: id,
        title: title,
        message: short ? null : message,
        kind: kind,
      ),
    ),
    if (short)
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: PlayerSpacing.sm),
        child: Text(message, style: context.playerMenuTheme.body),
      ),
  ];

  Widget _heading(BuildContext context, String label) => Padding(
    key: label == 'Choisir, puis agir'
        ? const ValueKey('gallery-start')
        : ValueKey(label),
    padding: const EdgeInsets.only(bottom: PlayerSpacing.md),
    child: Text(label, style: context.playerMenuTheme.subtitle),
  );
}
