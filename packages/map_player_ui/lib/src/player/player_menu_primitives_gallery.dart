import 'package:flutter/material.dart';

import '../foundation/player_menu_components.dart';
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
      header: const PlayerMenuHeader(
        icon: Icons.palette_outlined,
        title: 'Tous les menus et les états de votre aventure',
        secondary: Text('Galerie de démonstration · MENU-B'),
      ),
      footer: PlayerMenuFooter(
        hints: [
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
          final sections = [
            _states(context),
            PlayerMenuDetailTransition(
              contentKey: ValueKey(_selectedId),
              child: _details(context),
            ),
          ];
          if (constraints.maxWidth < 700) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sections.first,
                const SizedBox(height: PlayerSpacing.lg),
                sections.last,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: sections.first),
              const SizedBox(width: PlayerSpacing.lg),
              Expanded(child: sections.last),
            ],
          );
        },
      ),
    );
  }

  Widget _states(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading(context, 'Choisir, puis agir'),
          _row('selected', 'Sélection conservée',
              subtitle: 'Le focus peut atteindre une autre commande.'),
          _row('normal', 'Un compagnon au nom particulièrement long',
              subtitle: 'Un nom sur deux lignes reste lisible.'),
          _row('hovered', 'Survol discret', hovered: true),
          _row('focused', 'Focus clavier indépendant', focused: true),
          _row('pressed', 'Pression en cours', pressed: true),
          _row('disabled', 'Action indisponible',
              disabledReason: 'Une cible compatible est nécessaire.'),
          _row('busy', 'Traitement en cours', busy: true),
        ],
      );

  Widget _row(
    String id,
    String label, {
    String? subtitle,
    bool hovered = false,
    bool focused = false,
    bool pressed = false,
    bool busy = false,
    String? disabledReason,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: PlayerSpacing.xs),
        child: PlayerMenuSelectableRow(
          id: 'gallery-$id',
          label: label,
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

  Widget _details(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading(context, 'Des informations lisibles'),
          PlayerMenuPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Wrap(
                  spacing: PlayerSpacing.md,
                  runSpacing: PlayerSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PlayerMenuPortrait(
                      circular: true,
                      semanticLabel: 'Portrait de démonstration',
                      child: Icon(Icons.person_outline, size: 48),
                    ),
                    PlayerMenuBadge(
                      label: 'Type',
                      kind: PlayerMenuBadgeKind.type,
                    ),
                    PlayerMenuBadge(
                      label: 'Statut',
                      kind: PlayerMenuBadgeKind.status,
                    ),
                  ],
                ),
                const SizedBox(height: PlayerSpacing.md),
                const ExcludeSemantics(
                  child: SizedBox(
                    height: 96,
                    child: Icon(Icons.pets_outlined, size: 88),
                  ),
                ),
                const SizedBox(height: PlayerSpacing.md),
                for (final value in [100.0, 50.0, 1.0, 0.0])
                  Padding(
                    padding: const EdgeInsets.only(bottom: PlayerSpacing.sm),
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
                const PlayerMenuGauge(
                  value: 20,
                  maximum: 25,
                  label: 'PP',
                  kind: PlayerMenuGaugeKind.experience,
                ),
              ],
            ),
          ),
          const SizedBox(height: PlayerSpacing.md),
          const PlayerMenuFeedback(
            id: 'gallery-empty',
            title: 'Aucun élément',
            message: 'Le contenu apparaîtra lorsqu’il sera disponible.',
          ),
          const SizedBox(height: PlayerSpacing.md),
          const PlayerMenuFeedback(
            id: 'gallery-error',
            title: 'Ressource indisponible',
            message: 'Le nom et les actions restent accessibles.',
            kind: PlayerMenuFeedbackKind.error,
          ),
          const SizedBox(height: PlayerSpacing.md),
          PlayerMenuFeedback(
            id: 'gallery-receipt',
            title: 'Aperçu sans sauvegarde',
            message: _receipt,
            kind: PlayerMenuFeedbackKind.receipt,
          ),
        ],
      );

  Widget _heading(BuildContext context, String label) => Padding(
        padding: const EdgeInsets.only(bottom: PlayerSpacing.md),
        child: Text(label, style: context.playerMenuTheme.subtitle),
      );
}
