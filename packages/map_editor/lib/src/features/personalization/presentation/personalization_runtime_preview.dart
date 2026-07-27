import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/personalization_preview_projection.dart';
import 'project_branding_title_preview.dart';

/// Runtime-shaped preview surface driven by the current presentation draft.
///
/// The preview reads the same `ProjectPresentationProfile` contract that is
/// packaged for the player. Simulation controls added around this widget stay
/// editor-local and never mutate that contract.
class PersonalizationRuntimePreview extends StatefulWidget {
  const PersonalizationRuntimePreview({
    super.key,
    required this.profile,
    required this.projectName,
    required this.projectRootPath,
    this.baselineProfile,
  });

  final ProjectPresentationProfile profile;
  final ProjectPresentationProfile? baselineProfile;
  final String projectName;
  final String projectRootPath;

  @override
  State<PersonalizationRuntimePreview> createState() =>
      _PersonalizationRuntimePreviewState();
}

class _PersonalizationRuntimePreviewState
    extends State<PersonalizationRuntimePreview> {
  PersonalizationPreviewSurface _surface = PersonalizationPreviewSurface.title;

  @override
  Widget build(BuildContext context) {
    final projection = PersonalizationPreviewProjection(widget.profile);
    final surfaceProjection = projection.surface(_surface);
    return PokeMapPanel(
      key: const ValueKey<String>('personalization-runtime-preview'),
      header: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'Aperçu dans le jeu',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            PokeMapBadge(
              label: surfaceProjection.fontFamily,
              variant: PokeMapBadgeVariant.info,
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final surface in PersonalizationPreviewSurface.values)
                PokeMapButton(
                  key: ValueKey<String>(
                    'personalization-preview-${surface.name}',
                  ),
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.secondary,
                  isSelected: _surface == surface,
                  onPressed: () => setState(() => _surface = surface),
                  child: Text(_surfaceLabel(surface)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: _surface == PersonalizationPreviewSurface.title
                ? ProjectBrandingTitlePreview(
                    key: const ValueKey<String>(
                      'personalization-title-composition',
                    ),
                    projectName: widget.projectName,
                    projectRootPath: widget.projectRootPath,
                    branding: widget.profile.branding,
                    theme: widget.profile.theme ?? safeProjectSemanticTheme,
                    typography: widget.profile.typography,
                  )
                : PokeMapSemanticColorPreview(
                    key: ValueKey<String>(
                      'personalization-preview-placeholder-${_surface.name}',
                    ),
                    label: _surfaceLabel(_surface),
                    backgroundHex: surfaceProjection.backgroundHex,
                    foregroundHex: surfaceProjection.textHex,
                    sample: surfaceProjection.fontFamily,
                  ),
          ),
        ],
      ),
    );
  }
}

String _surfaceLabel(PersonalizationPreviewSurface surface) => switch (surface) {
      PersonalizationPreviewSurface.title => 'Titre',
      PersonalizationPreviewSurface.dialogue => 'Dialogue',
      PersonalizationPreviewSurface.menu => 'Menu',
      PersonalizationPreviewSurface.overworldHud => 'HUD exploration',
      PersonalizationPreviewSurface.battleHud => 'HUD combat',
    };
