import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/personalization_preview_surface_descriptor.dart';
import '../application/personalization_scene_presets.dart';

class PersonalizationSceneActions extends StatefulWidget {
  const PersonalizationSceneActions({
    super.key,
    required this.scene,
    required this.profile,
    required this.onProfileChanged,
    required this.onPreviewChanged,
  });

  final PersonalizationStudioScene scene;
  final ProjectPresentationProfile profile;
  final ValueChanged<ProjectPresentationProfile>? onProfileChanged;
  final ValueChanged<ProjectPresentationProfile?> onPreviewChanged;

  @override
  State<PersonalizationSceneActions> createState() =>
      _PersonalizationSceneActionsState();
}

class _PersonalizationSceneActionsState
    extends State<PersonalizationSceneActions> {
  PersonalizationScenePreset? _pendingPreset;
  PersonalizationScenePresetTransaction? _pendingTransaction;

  @override
  void didUpdateWidget(covariant PersonalizationSceneActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene != widget.scene ||
        oldWidget.profile != widget.profile) {
      _clearPreview(notify: oldWidget.scene != widget.scene);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presets = personalizationScenePresetsFor(widget.scene);
    final inheritedProfile = copyGlobalStyleToScene(
      scene: widget.scene,
      current: widget.profile,
    );
    final resetProfile = resetPersonalizationScene(
      widget.profile,
      widget.scene,
    );
    if (presets.isEmpty) return const SizedBox.shrink();
    return PokeMapCard(
      key: const ValueKey<String>('personalization-scene-actions'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Style de la scène',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final preset in presets)
                PokeMapButton(
                  key: ValueKey<String>('scene-preset-${preset.id}'),
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.secondary,
                  leading: const Icon(Icons.auto_awesome_outlined),
                  onPressed:
                      widget.onProfileChanged == null ||
                          !preset.preview(widget.profile).requiresConfirmation
                      ? null
                      : () => _previewPreset(preset),
                  child: Text(preset.label),
                ),
              PokeMapButton(
                key: ValueKey<String>('scene-copy-global-${widget.scene.name}'),
                size: PokeMapButtonSize.small,
                variant: PokeMapButtonVariant.ghost,
                leading: const Icon(Icons.copy_all_outlined),
                onPressed:
                    widget.onProfileChanged == null ||
                        inheritedProfile == widget.profile
                    ? null
                    : () => widget.onProfileChanged!(inheritedProfile),
                child: const Text('Copier le style global'),
              ),
              PokeMapButton(
                key: ValueKey<String>('scene-reset-${widget.scene.name}'),
                size: PokeMapButtonSize.small,
                variant: PokeMapButtonVariant.ghost,
                leading: const Icon(Icons.restart_alt_rounded),
                onPressed:
                    widget.onProfileChanged == null ||
                        resetProfile == widget.profile
                    ? null
                    : () => widget.onProfileChanged!(resetProfile),
                child: const Text('Réinitialiser cette scène'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_pendingPreset case final preset?)
            PokeMapActionBanner(
              key: const ValueKey<String>('scene-preset-confirmation'),
              title: 'Aperçu du preset « ${preset.label} »',
              message:
                  'Sections remplacées : ${_pendingTransaction!.replacedSections.join(', ')}. '
                  'Les assets référencés restent intacts.',
              tone: PokeMapTone.warning,
              actions: <PokeMapActionBannerAction>[
                PokeMapActionBannerAction(
                  key: const ValueKey<String>('scene-preset-apply'),
                  label: 'Appliquer le preset',
                  onPressed: _applyPendingPreset,
                ),
                PokeMapActionBannerAction(
                  key: const ValueKey<String>('scene-preset-cancel'),
                  label: 'Annuler',
                  variant: PokeMapButtonVariant.secondary,
                  onPressed: _clearPreview,
                ),
              ],
            )
          else
            Text(
              'Un preset est d’abord prévisualisé, puis crée une seule étape dans l’historique.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  void _previewPreset(PersonalizationScenePreset preset) {
    final transaction = preset.preview(widget.profile);
    if (!transaction.requiresConfirmation) return;
    setState(() {
      _pendingPreset = preset;
      _pendingTransaction = transaction;
    });
    widget.onPreviewChanged(transaction.profile);
  }

  void _applyPendingPreset() {
    final transaction = _pendingTransaction;
    if (transaction == null) return;
    widget.onProfileChanged?.call(transaction.profile);
    _clearPreview();
  }

  void _clearPreview({bool notify = true}) {
    if (_pendingTransaction == null) return;
    if (mounted) {
      setState(() {
        _pendingPreset = null;
        _pendingTransaction = null;
      });
    } else {
      _pendingPreset = null;
      _pendingTransaction = null;
    }
    if (notify) widget.onPreviewChanged(null);
  }
}
