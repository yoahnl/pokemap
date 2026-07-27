import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';

typedef ProjectThemeTokenSelection = void Function(String token);

/// Guided semantic theme editor with player-surface previews.
class ProjectSemanticThemeEditor extends StatelessWidget {
  const ProjectSemanticThemeEditor({
    super.key,
    required this.profile,
    required this.onEditToken,
    required this.onUseSafeFallback,
  });

  final ProjectSemanticThemeProfile profile;
  final ProjectThemeTokenSelection onEditToken;
  final VoidCallback onUseSafeFallback;

  @override
  Widget build(BuildContext context) {
    final diagnostics = validateProjectSemanticTheme(profile);
    final blocked = diagnostics.any(
      (diagnostic) =>
          diagnostic.severity == ProjectPresentationDiagnosticSeverity.error,
    );
    final tokens = _tokens(profile);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PokeMapCard(
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              PokeMapBadge(
                label: blocked ? 'Publication bloquée' : 'Contrastes validés',
                variant: blocked
                    ? PokeMapBadgeVariant.error
                    : PokeMapBadgeVariant.success,
                icon: Icon(
                  blocked
                      ? Icons.error_outline_rounded
                      : Icons.verified_rounded,
                ),
              ),
              if (blocked)
                for (final diagnostic in diagnostics.take(3))
                  Text(diagnostic.message),
              PokeMapButton(
                key: const ValueKey<String>('theme-safe-fallback'),
                onPressed: onUseSafeFallback,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: const Icon(Icons.restart_alt_rounded),
                child: const Text('Palette sûre'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const PokeMapSectionHeader(
          title: 'Aperçu des surfaces joueur',
          description:
              'Chaque zone utilise un token de surface et le texte sémantique.',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _surfacePreview(
              'Écran titre',
              profile.titleSurface,
              profile.textPrimary,
            ),
            _surfacePreview(
              'Dialogues',
              profile.dialogueSurface,
              profile.textPrimary,
            ),
            _surfacePreview(
              'Menus',
              profile.menuSurface,
              profile.textPrimary,
            ),
            _surfacePreview(
              'HUD exploration',
              profile.overworldHudSurface,
              profile.textPrimary,
            ),
            _surfacePreview(
              'HUD combat',
              profile.battleHudSurface,
              profile.textPrimary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const PokeMapSectionHeader(
          title: 'Tokens sémantiques',
          description: 'La sélection ouvre le choix guidé de couleur du hub.',
        ),
        const SizedBox(height: 8),
        for (final token in tokens.entries) ...<Widget>[
          PokeMapCard(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _tokenLabel(token.key),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                PokeMapBadge(label: token.value),
                const SizedBox(width: 8),
                PokeMapButton(
                  key: ValueKey<String>('theme-edit-${token.key}'),
                  onPressed: () => onEditToken(token.key),
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(Icons.palette_outlined),
                  child: const Text('Modifier'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _surfacePreview(String label, String background, String foreground) =>
      PokeMapSemanticColorPreview(
        label: label,
        backgroundHex: background,
        foregroundHex: foreground,
      );
}

Map<String, String> _tokens(ProjectSemanticThemeProfile profile) =>
    <String, String>{
      'primary': profile.primary,
      'onPrimary': profile.onPrimary,
      'background': profile.background,
      'surface': profile.surface,
      'surfaceElevated': profile.surfaceElevated,
      'textPrimary': profile.textPrimary,
      'textSecondary': profile.textSecondary,
      'outline': profile.outline,
      'success': profile.success,
      'warning': profile.warning,
      'danger': profile.danger,
      'titleSurface': profile.titleSurface,
      'dialogueSurface': profile.dialogueSurface,
      'menuSurface': profile.menuSurface,
      'overworldHudSurface': profile.overworldHudSurface,
      'battleHudSurface': profile.battleHudSurface,
    };

String _tokenLabel(String token) => switch (token) {
      'primary' => 'Action principale',
      'onPrimary' => 'Texte sur action',
      'background' => 'Fond global',
      'surface' => 'Surface',
      'surfaceElevated' => 'Surface élevée',
      'textPrimary' => 'Texte principal',
      'textSecondary' => 'Texte secondaire',
      'outline' => 'Contours',
      'success' => 'Succès',
      'warning' => 'Avertissement',
      'danger' => 'Danger',
      'titleSurface' => 'Fond du titre',
      'dialogueSurface' => 'Fond des dialogues',
      'menuSurface' => 'Fond des menus',
      'overworldHudSurface' => 'Fond du HUD exploration',
      'battleHudSurface' => 'Fond du HUD combat',
      _ => token,
    };
