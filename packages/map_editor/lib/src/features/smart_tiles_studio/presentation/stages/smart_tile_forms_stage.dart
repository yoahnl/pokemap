import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../application/smart_tile_form_projection.dart';
import '../workbench/smart_tile_coverage_gallery.dart';

class SmartTileFormsStage extends StatelessWidget {
  const SmartTileFormsStage({
    super.key,
    required this.usage,
    required this.topology,
    required this.forms,
    required this.selectedMask,
    required this.pendingAtlasFrame,
    required this.selectedChannel,
    required this.animations,
    required this.atlasWorkbench,
    required this.onFormSelected,
    required this.onClearPendingFrame,
    required this.onChannelSelected,
    required this.onAnimationSelected,
    required this.onWeightChanged,
    required this.onMoveVariant,
    required this.onRemoveVariant,
    required this.onContinue,
    this.guideWorkbench,
  });

  final SmartTileUsage usage;
  final SmartTileTopology topology;
  final List<SmartTileFormReadModel> forms;
  final int? selectedMask;
  final SmartTileFrameRef? pendingAtlasFrame;
  final SmartTileRenderChannel selectedChannel;
  final List<ProjectSmartTileAnimation> animations;
  final Widget atlasWorkbench;
  final ValueChanged<int> onFormSelected;
  final VoidCallback onClearPendingFrame;
  final ValueChanged<SmartTileRenderChannel> onChannelSelected;
  final void Function(int mask, String animationId) onAnimationSelected;
  final void Function(int mask, String candidateId, int weight) onWeightChanged;
  final void Function(int mask, String candidateId, int newIndex) onMoveVariant;
  final void Function(int mask, String candidateId) onRemoveVariant;
  final VoidCallback? onContinue;
  final Widget? guideWorkbench;

  @override
  Widget build(BuildContext context) {
    final selected =
        forms.where((form) => form.mask == selectedMask).firstOrNull;
    final covered = forms.where((form) => !form.status.isBlocking).length;
    final ambiguous = forms
        .where((form) => form.status == SmartTileVisibleFormStatus.ambiguous)
        .length;
    final missing = forms
        .where((form) => form.status == SmartTileVisibleFormStatus.missing)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PokeMapSectionHeader(
          title: 'Formes de raccord',
          description:
              'Choisissez une forme puis sa cellule dans l’atlas. Vous pouvez aussi cliquer d’abord l’atlas : la prochaine forme choisie sera associée.',
          trailing: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              PokeMapBadge(
                label: '$covered couvertes ou générées',
                variant: PokeMapBadgeVariant.success,
              ),
              if (ambiguous > 0)
                PokeMapBadge(
                  label: '$ambiguous ambiguës',
                  variant: PokeMapBadgeVariant.error,
                ),
              if (missing > 0)
                PokeMapBadge(
                  label: '$missing manquantes',
                  variant: PokeMapBadgeVariant.warning,
                ),
            ],
          ),
        ),
        if (guideWorkbench case final guide?) ...[
          const SizedBox(height: 14),
          guide,
        ],
        const SizedBox(height: 14),
        SmartTileCoverageGallery(
          forms: forms,
          topology: topology,
          selectedMask: selectedMask,
          onSelected: onFormSelected,
        ),
        const SizedBox(height: 18),
        PokeMapSectionHeader(
          title: selected == null
              ? 'Cellules de l’atlas'
              : 'Source pour « ${selected.label} »',
          description: pendingAtlasFrame == null
              ? selected == null
                  ? 'Cliquez une cellule pour découvrir ou choisir son rôle.'
                  : 'Cliquez une cellule. Maintenez Maj pour ajouter une variante au lieu de remplacer la première.'
              : selected == null
                  ? 'Cellule mémorisée : choisissez maintenant une forme ci-dessus.'
                  : 'La cellule mémorisée va être associée à cette forme.',
          trailing: pendingAtlasFrame == null
              ? null
              : PokeMapButton(
                  key: const Key('smart-tiles-clear-pending-frame'),
                  onPressed: onClearPendingFrame,
                  variant: PokeMapButtonVariant.ghost,
                  size: PokeMapButtonSize.small,
                  child: const Text('Annuler la cellule'),
                ),
        ),
        const SizedBox(height: 10),
        if (usage == SmartTileUsage.forestSurface) ...[
          const PokeMapSectionHeader(
            title: 'Couche visuelle active',
            description:
                'Le sol est la variante principale ; les autres canaux composent le sous-bois et la canopée.',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final channel in SmartTileRenderChannel.values)
                PokeMapButton(
                  key: Key('smart-tiles-channel-${channel.name}'),
                  onPressed: () => onChannelSelected(channel),
                  variant: PokeMapButtonVariant.ghost,
                  size: PokeMapButtonSize.small,
                  isSelected: selectedChannel == channel,
                  child: Text(_channelLabel(channel)),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        atlasWorkbench,
        if (selected != null && animations.isNotEmpty) ...[
          const SizedBox(height: 12),
          const PokeMapSectionHeader(
            title: 'Ou utiliser une animation',
            description:
                'La boucle reste une ressource distincte ; son poids appartient à la variante.',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final animation in animations)
                PokeMapButton(
                  key: Key(
                    'smart-tiles-form-animation-${animation.id}',
                  ),
                  onPressed: () =>
                      onAnimationSelected(selected.mask, animation.id),
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(CupertinoIcons.play_circle, size: 14),
                  child: Text(animation.name),
                ),
            ],
          ),
        ],
        if (selected != null && selected.candidates.isNotEmpty) ...[
          const SizedBox(height: 18),
          PokeMapSectionHeader(
            title: 'Variantes de « ${selected.label} »',
            description:
                'Les pourcentages sont calculés pour l’aperçu ; les poids entiers restent enregistrés sans arrondi.',
          ),
          const SizedBox(height: 8),
          for (var index = 0;
              index < selected.candidates.length;
              index += 1) ...[
            _SmartTileVariantEditor(
              key: ValueKey<String>(selected.candidates[index].id),
              candidate: selected.candidates[index],
              animationNames: <String, String>{
                for (final animation in animations)
                  animation.id: animation.name,
              },
              percentage: _normalizedPercentage(
                selected.candidates[index],
                selected.candidates,
              ),
              canMoveUp: index > 0,
              canMoveDown: index + 1 < selected.candidates.length,
              onWeightChanged: (weight) => onWeightChanged(
                selected.mask,
                selected.candidates[index].id,
                weight,
              ),
              onMoveUp: () => onMoveVariant(
                selected.mask,
                selected.candidates[index].id,
                index - 1,
              ),
              onMoveDown: () => onMoveVariant(
                selected.mask,
                selected.candidates[index].id,
                index + 1,
              ),
              onRemove: () => onRemoveVariant(
                selected.mask,
                selected.candidates[index].id,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            key: const Key('smart-tiles-mapping-next-step'),
            onPressed: onContinue,
            trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
            child: const Text('Ouvrir le banc d’essai'),
          ),
        ),
      ],
    );
  }
}

class _SmartTileVariantEditor extends StatefulWidget {
  const _SmartTileVariantEditor({
    super.key,
    required this.candidate,
    required this.animationNames,
    required this.percentage,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onWeightChanged,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  final SmartTileCandidate candidate;
  final Map<String, String> animationNames;
  final String percentage;
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<int> onWeightChanged;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;

  @override
  State<_SmartTileVariantEditor> createState() =>
      _SmartTileVariantEditorState();
}

class _SmartTileVariantEditorState extends State<_SmartTileVariantEditor> {
  late final TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.candidate.weight.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _SmartTileVariantEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final persisted = widget.candidate.weight.toString();
    if (oldWidget.candidate.weight != widget.candidate.weight &&
        _weightController.text != persisted) {
      _weightController.text = persisted;
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      padding: const EdgeInsets.all(10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 230,
            child: Text(_candidateSourceLabel(widget.candidate)),
          ),
          PokeMapBadge(
            label: widget.percentage,
            variant: PokeMapBadgeVariant.info,
          ),
          SizedBox(
            width: 120,
            child: PokeMapTextField(
              label: 'Poids (1–1000)',
              fieldKey: Key('smart-tiles-weight-${widget.candidate.id}'),
              controller: _weightController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              onSubmitted: _submitWeight,
            ),
          ),
          PokeMapButton(
            key: Key('smart-tiles-variant-up-${widget.candidate.id}'),
            onPressed: widget.canMoveUp ? widget.onMoveUp : null,
            variant: PokeMapButtonVariant.ghost,
            size: PokeMapButtonSize.small,
            child: const Text('Monter'),
          ),
          PokeMapButton(
            key: Key('smart-tiles-variant-down-${widget.candidate.id}'),
            onPressed: widget.canMoveDown ? widget.onMoveDown : null,
            variant: PokeMapButtonVariant.ghost,
            size: PokeMapButtonSize.small,
            child: const Text('Descendre'),
          ),
          PokeMapButton(
            key: Key('smart-tiles-variant-remove-${widget.candidate.id}'),
            onPressed: widget.onRemove,
            variant: PokeMapButtonVariant.ghost,
            size: PokeMapButtonSize.small,
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }

  void _submitWeight(String value) {
    final weight = int.tryParse(value);
    if (weight == null || weight < 1 || weight > 1000) {
      _weightController.text = widget.candidate.weight.toString();
      return;
    }
    widget.onWeightChanged(weight);
  }

  String _candidateSourceLabel(SmartTileCandidate candidate) {
    final source = candidate.parts.firstOrNull?.source;
    return switch (source) {
      SmartTileFrameSource() => 'Cellule de l’atlas',
      SmartTileAnimationSource(:final animationId) =>
        'Animation « ${widget.animationNames[animationId] ?? 'indisponible'} »',
      null => 'Source manquante',
    };
  }
}

String _normalizedPercentage(
  SmartTileCandidate candidate,
  List<SmartTileCandidate> candidates,
) {
  final total = candidates.fold<int>(
    0,
    (sum, item) => sum + item.weight,
  );
  if (total <= 0) return '0 %';
  final value = candidate.weight * 100 / total;
  final rounded = value.roundToDouble() == value
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$rounded %';
}

String _channelLabel(SmartTileRenderChannel channel) => switch (channel) {
      SmartTileRenderChannel.ground => 'Sol principal',
      SmartTileRenderChannel.understory => 'Sous-bois',
      SmartTileRenderChannel.canopy => 'Canopée',
      SmartTileRenderChannel.foreground => 'Premier plan',
      SmartTileRenderChannel.shadow => 'Ombre',
    };
