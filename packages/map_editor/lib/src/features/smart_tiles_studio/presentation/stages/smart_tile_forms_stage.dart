import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../application/smart_tile_atlas_selection.dart';
import '../../application/smart_tile_authoring_controller.dart';
import '../../application/smart_tile_form_projection.dart';
import '../workbench/smart_tile_coverage_gallery.dart';

class SmartTileFormsStage extends StatelessWidget {
  const SmartTileFormsStage({
    super.key,
    required this.usage,
    required this.topology,
    required this.forms,
    required this.materials,
    required this.transitionCases,
    required this.selectedMask,
    required this.selectedTransitionCaseId,
    required this.pendingAtlasFrame,
    required this.atlasSelectionMode,
    required this.selectedChannel,
    required this.animations,
    required this.atlasWorkbench,
    required this.onFormSelected,
    required this.onCreateTransitionCase,
    required this.onTransitionCaseSelected,
    required this.onTransitionCaseRemoved,
    required this.onTransitionCaseCenterChanged,
    required this.onTransitionCaseSlotChanged,
    required this.onClearPendingFrame,
    required this.onAtlasSelectionModeChanged,
    required this.onChannelSelected,
    required this.onAnimationSelected,
    required this.onTransitionCaseAnimationSelected,
    required this.onWeightChanged,
    required this.onTransitionCaseWeightChanged,
    required this.onVisualPartChanged,
    required this.onTransitionCaseVisualPartChanged,
    required this.onMoveVariant,
    required this.onMoveTransitionCaseVariant,
    required this.onRemoveVariant,
    required this.onRemoveTransitionCaseVariant,
    required this.onContinue,
    this.guideWorkbench,
  });

  final SmartTileUsage usage;
  final SmartTileTopology topology;
  final List<SmartTileFormReadModel> forms;
  final List<ProjectSmartTileMaterial> materials;
  final List<SmartTileRule> transitionCases;
  final int? selectedMask;
  final String? selectedTransitionCaseId;
  final SmartTileFrameRef? pendingAtlasFrame;
  final SmartTileAtlasSelectionMode atlasSelectionMode;
  final SmartTileRenderChannel selectedChannel;
  final List<ProjectSmartTileAnimation> animations;
  final Widget atlasWorkbench;
  final ValueChanged<int> onFormSelected;
  final VoidCallback onCreateTransitionCase;
  final ValueChanged<String> onTransitionCaseSelected;
  final ValueChanged<String> onTransitionCaseRemoved;
  final void Function(String caseId, SmartTileSlotMatch match)
      onTransitionCaseCenterChanged;
  final void Function(
    String caseId,
    SmartTileAuthoringSlot slot,
    SmartTileSlotMatch match,
  ) onTransitionCaseSlotChanged;
  final VoidCallback onClearPendingFrame;
  final ValueChanged<SmartTileAtlasSelectionMode> onAtlasSelectionModeChanged;
  final ValueChanged<SmartTileRenderChannel> onChannelSelected;
  final void Function(int mask, String animationId) onAnimationSelected;
  final void Function(String caseId, String animationId)
      onTransitionCaseAnimationSelected;
  final void Function(int mask, String candidateId, int weight) onWeightChanged;
  final void Function(String caseId, String candidateId, int weight)
      onTransitionCaseWeightChanged;
  final void Function(
    int mask,
    String candidateId,
    int partIndex,
    SmartTileVisualPart part,
  ) onVisualPartChanged;
  final void Function(
    String caseId,
    String candidateId,
    int partIndex,
    SmartTileVisualPart part,
  ) onTransitionCaseVisualPartChanged;
  final void Function(int mask, String candidateId, int newIndex) onMoveVariant;
  final void Function(String caseId, String candidateId, int newIndex)
      onMoveTransitionCaseVariant;
  final void Function(int mask, String candidateId) onRemoveVariant;
  final void Function(String caseId, String candidateId)
      onRemoveTransitionCaseVariant;
  final VoidCallback? onContinue;
  final Widget? guideWorkbench;

  @override
  Widget build(BuildContext context) {
    final selected =
        forms.where((form) => form.mask == selectedMask).firstOrNull;
    final selectedTransition = transitionCases
        .where((rule) => rule.id == selectedTransitionCaseId)
        .firstOrNull;
    final covered = forms.where((form) => !form.status.isBlocking).length;
    final ambiguous = forms
        .where((form) => form.status == SmartTileVisibleFormStatus.ambiguous)
        .length;
    final missing = forms
        .where((form) => form.status == SmartTileVisibleFormStatus.missing)
        .length;
    final hasRelativeMapping = forms.any((form) => form.candidates.isNotEmpty);
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
              if (transitionCases.isNotEmpty)
                PokeMapBadge(
                  label: '${transitionCases.length} cas exact(s)',
                  variant: PokeMapBadgeVariant.info,
                ),
              if (ambiguous > 0)
                PokeMapBadge(
                  label: '$ambiguous ambiguës',
                  variant: PokeMapBadgeVariant.error,
                ),
              if (missing > 0 &&
                  (hasRelativeMapping || transitionCases.isEmpty))
                PokeMapBadge(
                  label: '$missing manquantes',
                  variant: PokeMapBadgeVariant.warning,
                ),
            ],
          ),
        ),
        if (guideWorkbench == null) ...[
          const SizedBox(height: 12),
          PokeMapPanel(
            padding: const EdgeInsets.all(10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                const SizedBox(
                  width: 220,
                  child: Text(
                    'Découpe de l’atlas : une cellule, ou un rectangle défini '
                    'par deux clics.',
                  ),
                ),
                for (final mode in SmartTileAtlasSelectionMode.values)
                  PokeMapButton(
                    key: Key('smart-tiles-atlas-selection-${mode.name}'),
                    onPressed: () => onAtlasSelectionModeChanged(mode),
                    variant: PokeMapButtonVariant.ghost,
                    size: PokeMapButtonSize.small,
                    isSelected: atlasSelectionMode == mode,
                    leading: Icon(
                      mode == SmartTileAtlasSelectionMode.singleCell
                          ? CupertinoIcons.square
                          : CupertinoIcons.rectangle_grid_2x2,
                      size: 14,
                    ),
                    child: Text(
                      mode == SmartTileAtlasSelectionMode.singleCell
                          ? 'Une cellule'
                          : 'Rectangle',
                    ),
                  ),
                if (pendingAtlasFrame case final frame?)
                  PokeMapBadge(
                    key: const Key('smart-tiles-atlas-selection-size'),
                    label: '${frame.columnSpan} × ${frame.rowSpan} cellule(s)',
                    variant: frame.columnSpan > 1 || frame.rowSpan > 1
                        ? PokeMapBadgeVariant.info
                        : PokeMapBadgeVariant.neutral,
                  ),
              ],
            ),
          ),
        ],
        if (materials.length > 1 || transitionCases.isNotEmpty) ...[
          const SizedBox(height: 14),
          _TransitionCasesEditor(
            topology: topology,
            materials: materials,
            cases: transitionCases,
            selectedCase: selectedTransition,
            onCreate: onCreateTransitionCase,
            onSelected: onTransitionCaseSelected,
            onRemoved: onTransitionCaseRemoved,
            onCenterChanged: onTransitionCaseCenterChanged,
            onSlotChanged: onTransitionCaseSlotChanged,
          ),
        ],
        if (guideWorkbench case final guide?) ...[
          const SizedBox(height: 14),
          guide,
        ],
        const SizedBox(height: 14),
        if (hasRelativeMapping || transitionCases.isEmpty)
          SmartTileCoverageGallery(
            forms: forms,
            topology: topology,
            selectedMask: selectedMask,
            onSelected: onFormSelected,
          )
        else
          const PokeMapPanel(
            padding: EdgeInsets.all(12),
            child: Text(
              'Ce preset utilise uniquement des cas multi-matières. Ajoutez des formes relatives seulement si plusieurs matières doivent partager le même dessin.',
            ),
          ),
        const SizedBox(height: 18),
        PokeMapSectionHeader(
          title: selectedTransition != null
              ? 'Source du cas de transition'
              : selected == null
                  ? 'Cellules de l’atlas'
                  : 'Source pour « ${selected.label} »',
          description: pendingAtlasFrame == null
              ? selectedTransition != null
                  ? 'Cliquez une cellule. Maintenez Maj pour ajouter une variante.'
                  : selected == null
                      ? 'Cliquez une cellule pour découvrir ou choisir son rôle.'
                      : 'Cliquez une cellule. Maintenez Maj pour ajouter une variante au lieu de remplacer la première.'
              : selectedTransition != null
                  ? 'La cellule mémorisée va être associée au cas de transition.'
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
        if ((selected != null || selectedTransition != null) &&
            animations.isNotEmpty) ...[
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
                  onPressed: () {
                    if (selectedTransition != null) {
                      onTransitionCaseAnimationSelected(
                        selectedTransition.id,
                        animation.id,
                      );
                    } else {
                      onAnimationSelected(selected!.mask, animation.id);
                    }
                  },
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(CupertinoIcons.play_circle, size: 14),
                  child: Text(animation.name),
                ),
            ],
          ),
        ],
        if (selectedTransition != null &&
            selectedTransition.candidates.isNotEmpty) ...[
          const SizedBox(height: 18),
          const PokeMapSectionHeader(
            title: 'Variantes du cas de transition',
            description:
                'Les poids et l’ordre restent déterministes, comme pour les formes guidées.',
          ),
          const SizedBox(height: 8),
          for (var index = 0;
              index < selectedTransition.candidates.length;
              index += 1) ...[
            _SmartTileVariantEditor(
              key: ValueKey<String>(
                'transition-${selectedTransition.candidates[index].id}',
              ),
              candidate: selectedTransition.candidates[index],
              animationNames: <String, String>{
                for (final animation in animations)
                  animation.id: animation.name,
              },
              percentage: _normalizedPercentage(
                selectedTransition.candidates[index],
                selectedTransition.candidates,
              ),
              canMoveUp: index > 0,
              canMoveDown: index + 1 < selectedTransition.candidates.length,
              onWeightChanged: (weight) => onTransitionCaseWeightChanged(
                selectedTransition.id,
                selectedTransition.candidates[index].id,
                weight,
              ),
              onVisualPartChanged: (partIndex, part) =>
                  onTransitionCaseVisualPartChanged(
                selectedTransition.id,
                selectedTransition.candidates[index].id,
                partIndex,
                part,
              ),
              onMoveUp: () => onMoveTransitionCaseVariant(
                selectedTransition.id,
                selectedTransition.candidates[index].id,
                index - 1,
              ),
              onMoveDown: () => onMoveTransitionCaseVariant(
                selectedTransition.id,
                selectedTransition.candidates[index].id,
                index + 1,
              ),
              onRemove: () => onRemoveTransitionCaseVariant(
                selectedTransition.id,
                selectedTransition.candidates[index].id,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ] else if (selected != null && selected.candidates.isNotEmpty) ...[
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
              onVisualPartChanged: (partIndex, part) => onVisualPartChanged(
                selected.mask,
                selected.candidates[index].id,
                partIndex,
                part,
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

class _TransitionCasesEditor extends StatelessWidget {
  const _TransitionCasesEditor({
    required this.topology,
    required this.materials,
    required this.cases,
    required this.selectedCase,
    required this.onCreate,
    required this.onSelected,
    required this.onRemoved,
    required this.onCenterChanged,
    required this.onSlotChanged,
  });

  final SmartTileTopology topology;
  final List<ProjectSmartTileMaterial> materials;
  final List<SmartTileRule> cases;
  final SmartTileRule? selectedCase;
  final VoidCallback onCreate;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onRemoved;
  final void Function(String caseId, SmartTileSlotMatch match) onCenterChanged;
  final void Function(
    String caseId,
    SmartTileAuthoringSlot slot,
    SmartTileSlotMatch match,
  ) onSlotChanged;

  @override
  Widget build(BuildContext context) {
    final selected = selectedCase;
    return PokeMapPanel(
      key: const Key('smart-tiles-transition-cases'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PokeMapSectionHeader(
            title: 'Cas de transition multi-matières',
            description:
                'Ajoutez un cas lorsque plusieurs matières doivent produire une image précise. Chaque bord et chaque coin peut être réglé sans identifiant Wang.',
            trailing: PokeMapButton(
              key: const Key('smart-tiles-transition-add'),
              onPressed: onCreate,
              size: PokeMapButtonSize.small,
              leading: const Icon(CupertinoIcons.add, size: 14),
              child: const Text('Nouveau cas'),
            ),
          ),
          const SizedBox(height: 10),
          if (cases.isEmpty)
            const Text(
              'Aucun cas exact. Les formes guidées ci-dessous restent adaptées aux raccords simples.',
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (var index = 0; index < cases.length; index += 1)
                  PokeMapButton(
                    key: Key('smart-tiles-transition-${cases[index].id}'),
                    onPressed: () => onSelected(cases[index].id),
                    variant: PokeMapButtonVariant.ghost,
                    size: PokeMapButtonSize.small,
                    isSelected: selected?.id == cases[index].id,
                    trailing: PokeMapBadge(
                      label: '${cases[index].candidates.length} image(s)',
                    ),
                    child: Text(
                      'Cas ${index + 1} · ${_centerMatchLabel(cases[index].centerMatch, materials)}',
                    ),
                  ),
              ],
            ),
          if (selected != null) ...[
            const SizedBox(height: 12),
            PokeMapPanel(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: <Widget>[
                      SizedBox(
                        width: 260,
                        child: PokeMapDropdownField<SmartTileSlotMatch>(
                          key: Key(
                            'smart-tiles-transition-center-${selected.id}',
                          ),
                          label: 'Matière au centre',
                          value: selected.centerMatch,
                          items: _centerItems(materials),
                          onChanged: (match) =>
                              onCenterChanged(selected.id, match),
                        ),
                      ),
                      PokeMapButton(
                        key: Key(
                          'smart-tiles-transition-remove-${selected.id}',
                        ),
                        onPressed: () => onRemoved(selected.id),
                        variant: PokeMapButtonVariant.ghost,
                        size: PokeMapButtonSize.small,
                        leading: const Icon(CupertinoIcons.trash, size: 14),
                        child: const Text('Supprimer le cas'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const PokeMapSectionHeader(
                    title: 'Matière attendue autour de la cellule',
                    description:
                        '« Même » et « différente » restent relatifs au centre ; une matière nommée crée un vrai raccord multi-couleurs.',
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      for (final slot in _activeSlots(topology))
                        SizedBox(
                          width: 250,
                          child: PokeMapDropdownField<SmartTileSlotMatch>(
                            key: Key(
                              'smart-tiles-transition-${selected.id}-${slot.name}',
                            ),
                            label: _slotLabel(slot),
                            value: _slotMatch(selected.signature, slot),
                            items: _slotItems(materials),
                            onChanged: (match) =>
                                onSlotChanged(selected.id, slot, match),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

List<PokeMapDropdownItem<SmartTileSlotMatch>> _centerItems(
  List<ProjectSmartTileMaterial> materials,
) =>
    <PokeMapDropdownItem<SmartTileSlotMatch>>[
      const PokeMapDropdownItem<SmartTileSlotMatch>(
        value: SmartTileSlotMatch.any(),
        label: 'N’importe quelle matière',
      ),
      const PokeMapDropdownItem<SmartTileSlotMatch>(
        value: SmartTileSlotMatch.empty(),
        label: 'Vide',
      ),
      for (final material in materials)
        PokeMapDropdownItem<SmartTileSlotMatch>(
          value: SmartTileSlotMatch.material(material.id),
          label: material.name,
        ),
    ];

List<PokeMapDropdownItem<SmartTileSlotMatch>> _slotItems(
  List<ProjectSmartTileMaterial> materials,
) =>
    <PokeMapDropdownItem<SmartTileSlotMatch>>[
      const PokeMapDropdownItem<SmartTileSlotMatch>(
        value: SmartTileSlotMatch.any(),
        label: 'Indifférent',
      ),
      const PokeMapDropdownItem<SmartTileSlotMatch>(
        value: SmartTileSlotMatch.same(),
        label: 'Même matière que le centre',
      ),
      const PokeMapDropdownItem<SmartTileSlotMatch>(
        value: SmartTileSlotMatch.different(),
        label: 'Matière différente',
      ),
      const PokeMapDropdownItem<SmartTileSlotMatch>(
        value: SmartTileSlotMatch.empty(),
        label: 'Vide',
      ),
      for (final material in materials)
        PokeMapDropdownItem<SmartTileSlotMatch>(
          value: SmartTileSlotMatch.material(material.id),
          label: material.name,
        ),
    ];

List<SmartTileAuthoringSlot> _activeSlots(SmartTileTopology topology) =>
    switch (topology) {
      SmartTileTopology.uniform => const <SmartTileAuthoringSlot>[],
      SmartTileTopology.cardinal4 ||
      SmartTileTopology.wangEdge4 =>
        const <SmartTileAuthoringSlot>[
          SmartTileAuthoringSlot.northEdge,
          SmartTileAuthoringSlot.eastEdge,
          SmartTileAuthoringSlot.southEdge,
          SmartTileAuthoringSlot.westEdge,
        ],
      SmartTileTopology.wangCorner4 => const <SmartTileAuthoringSlot>[
          SmartTileAuthoringSlot.northWestCorner,
          SmartTileAuthoringSlot.northEastCorner,
          SmartTileAuthoringSlot.southEastCorner,
          SmartTileAuthoringSlot.southWestCorner,
        ],
      SmartTileTopology.blob8 ||
      SmartTileTopology.wang8 =>
        SmartTileAuthoringSlot.values,
    };

SmartTileSlotMatch _slotMatch(
  SmartTileSignature signature,
  SmartTileAuthoringSlot slot,
) =>
    switch (slot) {
      SmartTileAuthoringSlot.northWestCorner => signature.northWestCorner,
      SmartTileAuthoringSlot.northEdge => signature.northEdge,
      SmartTileAuthoringSlot.northEastCorner => signature.northEastCorner,
      SmartTileAuthoringSlot.eastEdge => signature.eastEdge,
      SmartTileAuthoringSlot.southEastCorner => signature.southEastCorner,
      SmartTileAuthoringSlot.southEdge => signature.southEdge,
      SmartTileAuthoringSlot.southWestCorner => signature.southWestCorner,
      SmartTileAuthoringSlot.westEdge => signature.westEdge,
    };

String _centerMatchLabel(
  SmartTileSlotMatch match,
  List<ProjectSmartTileMaterial> materials,
) =>
    switch (match.kind) {
      SmartTileMatchKind.any => 'centre libre',
      SmartTileMatchKind.empty => 'centre vide',
      SmartTileMatchKind.material => materials
              .where((material) => material.id == match.materialId)
              .map((material) => material.name)
              .firstOrNull ??
          'matière supprimée',
      SmartTileMatchKind.same ||
      SmartTileMatchKind.different =>
        'centre invalide',
    };

String _slotLabel(SmartTileAuthoringSlot slot) => switch (slot) {
      SmartTileAuthoringSlot.northWestCorner => 'Coin nord-ouest',
      SmartTileAuthoringSlot.northEdge => 'Bord nord',
      SmartTileAuthoringSlot.northEastCorner => 'Coin nord-est',
      SmartTileAuthoringSlot.eastEdge => 'Bord est',
      SmartTileAuthoringSlot.southEastCorner => 'Coin sud-est',
      SmartTileAuthoringSlot.southEdge => 'Bord sud',
      SmartTileAuthoringSlot.southWestCorner => 'Coin sud-ouest',
      SmartTileAuthoringSlot.westEdge => 'Bord ouest',
    };

class _SmartTileVariantEditor extends StatefulWidget {
  const _SmartTileVariantEditor({
    super.key,
    required this.candidate,
    required this.animationNames,
    required this.percentage,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onWeightChanged,
    required this.onVisualPartChanged,
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
  final void Function(int partIndex, SmartTileVisualPart part)
      onVisualPartChanged;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
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
          if (widget.candidate.parts.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (var index = 0;
                index < widget.candidate.parts.length;
                index += 1) ...[
              _SmartTileVisualPartEditor(
                key: ValueKey<String>(
                  '${widget.candidate.id}-visual-part-$index',
                ),
                candidateId: widget.candidate.id,
                partIndex: index,
                part: widget.candidate.parts[index],
                onChanged: (part) => widget.onVisualPartChanged(index, part),
              ),
              if (index + 1 < widget.candidate.parts.length)
                const SizedBox(height: 8),
            ],
          ],
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

enum _VisualGeometryField {
  offsetX,
  offsetY,
  footprintWidth,
  footprintHeight,
  anchorX,
  anchorY,
  drawOrder,
}

class _SmartTileVisualPartEditor extends StatefulWidget {
  const _SmartTileVisualPartEditor({
    super.key,
    required this.candidateId,
    required this.partIndex,
    required this.part,
    required this.onChanged,
  });

  final String candidateId;
  final int partIndex;
  final SmartTileVisualPart part;
  final ValueChanged<SmartTileVisualPart> onChanged;

  @override
  State<_SmartTileVisualPartEditor> createState() =>
      _SmartTileVisualPartEditorState();
}

class _SmartTileVisualPartEditorState
    extends State<_SmartTileVisualPartEditor> {
  late final Map<_VisualGeometryField, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = <_VisualGeometryField, TextEditingController>{
      for (final field in _VisualGeometryField.values)
        field: TextEditingController(text: _value(field).toString()),
    };
  }

  @override
  void didUpdateWidget(covariant _SmartTileVisualPartEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.part == widget.part) return;
    for (final field in _VisualGeometryField.values) {
      final value = _value(field).toString();
      if (_controllers[field]!.text != value) {
        _controllers[field]!.text = value;
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = switch (widget.part.source) {
      SmartTileFrameSource(:final frame) => frame,
      SmartTileAnimationSource() => null,
    };
    return PokeMapPanel(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PokeMapSectionHeader(
            title: 'Géométrie visuelle ${widget.partIndex + 1}',
            description: frame == null
                ? 'Animation : la géométrie s’applique à toutes ses frames.'
                : 'Découpe atlas ${frame.columnSpan} × ${frame.rowSpan} · '
                    'colonne ${frame.column + 1}, ligne ${frame.row + 1}.',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              SizedBox(
                width: 210,
                child: PokeMapDropdownField<SmartTileRenderChannel>(
                  key: _key('channel'),
                  label: 'Canal de rendu',
                  value: widget.part.channel,
                  items: <PokeMapDropdownItem<SmartTileRenderChannel>>[
                    for (final channel in SmartTileRenderChannel.values)
                      PokeMapDropdownItem<SmartTileRenderChannel>(
                        value: channel,
                        label: _channelLabel(channel),
                      ),
                  ],
                  onChanged: (channel) =>
                      widget.onChanged(widget.part.copyWith(channel: channel)),
                ),
              ),
              SizedBox(
                width: 210,
                child: PokeMapDropdownField<SmartTileFrameSampling>(
                  key: _key('sampling'),
                  label: 'Échantillonnage',
                  value: widget.part.frameSampling,
                  items: <PokeMapDropdownItem<SmartTileFrameSampling>>[
                    for (final sampling in SmartTileFrameSampling.values)
                      PokeMapDropdownItem<SmartTileFrameSampling>(
                        value: sampling,
                        label: _samplingLabel(sampling),
                      ),
                  ],
                  onChanged: (sampling) => widget.onChanged(
                    widget.part.copyWith(frameSampling: sampling),
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                child: PokeMapDropdownField<SmartTileOffsetUnit>(
                  key: _key('offset-unit'),
                  label: 'Unité des décalages',
                  value: widget.part.offsetUnit,
                  items: const <PokeMapDropdownItem<SmartTileOffsetUnit>>[
                    PokeMapDropdownItem<SmartTileOffsetUnit>(
                      value: SmartTileOffsetUnit.pixel,
                      label: 'Pixels source',
                    ),
                    PokeMapDropdownItem<SmartTileOffsetUnit>(
                      value: SmartTileOffsetUnit.cell,
                      label: 'Cellules',
                    ),
                  ],
                  onChanged: (unit) => widget.onChanged(
                    widget.part.copyWith(offsetUnit: unit),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              for (final field in _VisualGeometryField.values)
                SizedBox(
                  width: 142,
                  child: PokeMapTextField(
                    label: _fieldLabel(field),
                    fieldKey: _key(field.name),
                    controller: _controllers[field],
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                    ),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'-?\d*')),
                      LengthLimitingTextInputFormatter(5),
                    ],
                    onSubmitted: (value) => _submit(field, value),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Key _key(String suffix) => Key(
        'smart-tiles-geometry-${widget.candidateId}-${widget.partIndex}-$suffix',
      );

  int _value(_VisualGeometryField field) => switch (field) {
        _VisualGeometryField.offsetX => widget.part.offsetX,
        _VisualGeometryField.offsetY => widget.part.offsetY,
        _VisualGeometryField.footprintWidth => widget.part.footprintWidth,
        _VisualGeometryField.footprintHeight => widget.part.footprintHeight,
        _VisualGeometryField.anchorX => widget.part.anchorX,
        _VisualGeometryField.anchorY => widget.part.anchorY,
        _VisualGeometryField.drawOrder => widget.part.drawOrder,
      };

  void _submit(_VisualGeometryField field, String raw) {
    final value = int.tryParse(raw);
    final valid = value != null &&
        switch (field) {
          _VisualGeometryField.footprintWidth ||
          _VisualGeometryField.footprintHeight =>
            value >= 1 && value <= 64,
          _VisualGeometryField.drawOrder => value.abs() <= 1000,
          _ => value.abs() <= 4096,
        };
    if (!valid) {
      _controllers[field]!.text = _value(field).toString();
      return;
    }
    final part = switch (field) {
      _VisualGeometryField.offsetX => widget.part.copyWith(offsetX: value),
      _VisualGeometryField.offsetY => widget.part.copyWith(offsetY: value),
      _VisualGeometryField.footprintWidth =>
        widget.part.copyWith(footprintWidth: value),
      _VisualGeometryField.footprintHeight =>
        widget.part.copyWith(footprintHeight: value),
      _VisualGeometryField.anchorX => widget.part.copyWith(anchorX: value),
      _VisualGeometryField.anchorY => widget.part.copyWith(anchorY: value),
      _VisualGeometryField.drawOrder => widget.part.copyWith(drawOrder: value),
    };
    widget.onChanged(part);
  }
}

String _fieldLabel(_VisualGeometryField field) => switch (field) {
      _VisualGeometryField.offsetX => 'Décalage X',
      _VisualGeometryField.offsetY => 'Décalage Y',
      _VisualGeometryField.footprintWidth => 'Largeur grille',
      _VisualGeometryField.footprintHeight => 'Hauteur grille',
      _VisualGeometryField.anchorX => 'Ancre X',
      _VisualGeometryField.anchorY => 'Ancre Y',
      _VisualGeometryField.drawOrder => 'Ordre de dessin',
    };

String _samplingLabel(SmartTileFrameSampling sampling) => switch (sampling) {
      SmartTileFrameSampling.fullFrame => 'Image complète',
      SmartTileFrameSampling.tessellated => 'Mosaïque stable',
      SmartTileFrameSampling.stableRandom => 'Cellule variée stable',
    };

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
      SmartTileRenderChannel.actorOcclusion => 'Devant les personnages',
      SmartTileRenderChannel.shadow => 'Ombre',
    };
