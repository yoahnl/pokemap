import 'dart:io';

import 'package:flutter/material.dart';

import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_catalog.dart';
import 'package:pokemap_hub/features/appearance/application/notifiers/avelune_appearance_notifier.dart';
import 'package:pokemap_hub/presentation/theme/avelune_theme.dart';

class AveluneAppearanceSettings extends StatelessWidget {
  const AveluneAppearanceSettings({
    super.key,
    required this.state,
    required this.onBackgroundSelected,
    required this.onFurnitureSelected,
    required this.onImportCustomBackground,
    required this.onRemoveCustomBackground,
  });

  final AveluneAppearanceState state;
  final ValueChanged<String> onBackgroundSelected;
  final ValueChanged<String> onFurnitureSelected;
  final VoidCallback onImportCustomBackground;
  final VoidCallback onRemoveCustomBackground;

  @override
  Widget build(BuildContext context) {
    final french = Localizations.localeOf(context).languageCode == 'fr';
    final prefs = state.preferences;
    final saving = state.status == AveluneAppearanceControllerStatus.saving;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AveluneSpacing.lg,
        AveluneSpacing.lg,
        AveluneSpacing.lg,
        AveluneSpacing.xxl,
      ),
      children: <Widget>[
        AveluneSectionLabel(
          icon: AveluneIcons.background,
          label: french ? 'Fond' : 'Background',
        ),
        const SizedBox(height: AveluneSpacing.md),
        _BackgroundGrid(
          backgrounds: AveluneAppearanceCatalog.backgrounds,
          selectedId: prefs.backgroundId,
          customThumbnailPath: state.customBackgroundThumbnailPath,
          saving: saving,
          onSelected: onBackgroundSelected,
        ),
        if (state.message case final message?)
          Padding(
            padding: const EdgeInsets.only(top: AveluneSpacing.md),
            child: AveluneStateMessage(
              kind: state.status == AveluneAppearanceControllerStatus.error
                  ? AveluneStateMessageKind.error
                  : AveluneStateMessageKind.info,
              title: french ? 'Information' : 'Notice',
              message: message,
            ),
          ),
        const SizedBox(height: AveluneSpacing.xl),
        AveluneSectionLabel(
          icon: AveluneIcons.furniture,
          label: french ? 'Commode' : 'Furniture',
        ),
        const SizedBox(height: AveluneSpacing.md),
        _FurnitureGrid(
          furniture: AveluneAppearanceCatalog.furniture,
          selectedId: prefs.furnitureId,
          saving: saving,
          onSelected: onFurnitureSelected,
        ),
        const SizedBox(height: AveluneSpacing.xl),
        AveluneSectionLabel(
          icon: AveluneIcons.background,
          label: french ? 'Mon image' : 'My image',
        ),
        const SizedBox(height: AveluneSpacing.md),
        _CustomBackgroundSection(
          state: state,
          onImport: onImportCustomBackground,
          onRemove: onRemoveCustomBackground,
        ),
      ],
    );
  }
}

class _BackgroundGrid extends StatelessWidget {
  const _BackgroundGrid({
    required this.backgrounds,
    required this.selectedId,
    required this.customThumbnailPath,
    required this.saving,
    required this.onSelected,
  });

  final List<AveluneAppearanceOption> backgrounds;
  final String selectedId;
  final String? customThumbnailPath;
  final bool saving;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AveluneSpacing.md,
      runSpacing: AveluneSpacing.md,
      children: [
        for (final bg in backgrounds)
          _PresetCard(
            key: ValueKey<String>('avelune-bg-${bg.id}'),
            label: bg.label,
            isSelected: bg.id == selectedId,
            saving: saving,
            thumbnail: bg.isCustom
                ? _customThumbnail(customThumbnailPath)
                : _assetThumbnail(bg.assetPath),
            onTap: saving ? null : () => onSelected(bg.id),
          ),
      ],
    );
  }

  Widget? _customThumbnail(String? path) {
    if (path == null) return null;
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  Widget? _assetThumbnail(String? assetPath) {
    if (assetPath == null) return null;
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}

class _FurnitureGrid extends StatelessWidget {
  const _FurnitureGrid({
    required this.furniture,
    required this.selectedId,
    required this.saving,
    required this.onSelected,
  });

  final List<AveluneAppearanceOption> furniture;
  final String selectedId;
  final bool saving;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AveluneSpacing.md,
      runSpacing: AveluneSpacing.md,
      children: [
        for (final f in furniture)
          _PresetCard(
            key: ValueKey<String>('avelune-furniture-${f.id}'),
            label: f.label,
            isSelected: f.id == selectedId,
            saving: saving,
            thumbnail: f.assetPath != null
                ? Image.asset(
                    f.assetPath!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  )
                : null,
            onTap: saving ? null : () => onSelected(f.id),
          ),
      ],
    );
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    super.key,
    required this.label,
    required this.isSelected,
    required this.saving,
    required this.onTap,
    this.thumbnail,
  });

  final String label;
  final bool isSelected;
  final bool saving;
  final VoidCallback? onTap;
  final Widget? thumbnail;

  static const double _cardWidth = 140;
  static const double _cardHeight = 100;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    return AvelunePressable(
      semanticLabel: label,
      selected: isSelected,
      enabled: onTap != null,
      onPressed: onTap ?? () {},
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: _cardWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: _cardWidth,
                height: _cardHeight,
                child: thumbnail != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          thumbnail!,
                          if (isSelected)
                            DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: colors.focus,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          if (isSelected)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colors.focus,
                                  shape: BoxShape.circle,
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(3),
                                  child: Icon(
                                    AveluneIcons.selected,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Icon(
                            AveluneIcons.ownImage,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AveluneSpacing.xs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? colors.textPrimary : colors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomBackgroundSection extends StatelessWidget {
  const _CustomBackgroundSection({
    required this.state,
    required this.onImport,
    required this.onRemove,
  });

  final AveluneAppearanceState state;
  final VoidCallback onImport;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final french = Localizations.localeOf(context).languageCode == 'fr';
    final hasCustom = state.customBackgroundPath != null;
    final isCustomSelected = state.preferences.backgroundId ==
        AveluneAppearanceCatalog.customBackgroundId;
    final saving = state.status == AveluneAppearanceControllerStatus.saving;

    return AveluneInsetPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (hasCustom && state.customBackgroundThumbnailPath != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AveluneSpacing.md),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Image.file(
                    File(state.customBackgroundThumbnailPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          AveluneIcons.missingImage,
                          color: colors.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (!hasCustom)
            Text(
              french
                  ? 'Importez une image personnelle pour l\'utiliser comme fond.'
                  : 'Import a personal image to use as background.',
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
          const SizedBox(height: AveluneSpacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: saving ? null : onImport,
                  icon: Icon(
                    hasCustom
                        ? AveluneIcons.exchange
                        : AveluneIcons.ownImage,
                  ),
                  label: Text(
                    hasCustom
                        ? (french ? 'Remplacer' : 'Replace')
                        : (french ? 'Choisir une image' : 'Choose image'),
                  ),
                ),
              ),
              if (hasCustom) ...<Widget>[
                const SizedBox(width: AveluneSpacing.sm),
                OutlinedButton.icon(
                  onPressed: saving ? null : onRemove,
                  icon: const Icon(AveluneIcons.remove),
                  label: Text(french ? 'Supprimer' : 'Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                  ),
                ),
              ],
            ],
          ),
          if (isCustomSelected && !hasCustom)
            Padding(
              padding: const EdgeInsets.only(top: AveluneSpacing.sm),
              child: Text(
                french
                    ? 'L\'image personnalisée est introuvable. Le fond Ambre a été restauré.'
                    : 'Custom image not found. Amber background was restored.',
                style: TextStyle(color: colors.error, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
