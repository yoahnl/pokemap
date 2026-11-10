import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/resources/domain/resource_port.dart';
import '../../../features/resources/application/border_creation_draft.dart';
import '../../../features/resources/coordination/border_creation_workflow.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';

import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';

import 'border_discard_dialog.dart';
import 'border_pattern_panel.dart';
import 'border_source_panel.dart';
import 'border_sequence_controls.dart';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';

import 'native_ledge_panel.dart';

class BorderCreationDialog extends StatefulWidget {
  const BorderCreationDialog({
    super.key,
    required this.navigation,
    required this.project,
    required this.visuals,
    this.initialRecord,
  });

  final ResourceNavigation navigation;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final BorderBlueprintRecord? initialRecord;

  @override
  State<BorderCreationDialog> createState() => _BorderCreationDialogState();
}

class _BorderCreationDialogState extends State<BorderCreationDialog> {
  late final TextEditingController _name;
  late final BorderCreationDraft _draft;
  String _settingsRole = 'lineStraight';
  ResourceItem? _activeElement;
  late final BorderCreationWorkflow _workflow;

  @override
  void initState() {
    super.initState();
    _draft = BorderCreationDraft(
      project: widget.project,
      initialRecord: widget.initialRecord,
      unavailableResourceIds: () => {
        for (final diagnostic in widget.visuals.diagnostics)
          diagnostic.resourceId,
      },
    );
    _name = TextEditingController(text: _draft.name);
    _workflow = BorderCreationWorkflow(
      navigation: widget.navigation,
      draft: _draft,
      isActive: () => mounted,
      confirmDiscard: () async => await confirmBorderDiscard(context) == true,
      confirmRepublication: _confirmRepublication,
    );
  }

  bool _commitDraft(bool Function() action) {
    var accepted = false;
    setState(() => accepted = action());
    return accepted;
  }

  @override
  void didUpdateWidget(BorderCreationDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    _draft.updateProject(widget.project);
  }

  @override
  void dispose() {
    _workflow.dispose();
    _name.dispose();
    super.dispose();
  }

  Widget _sequenceControls() => BorderSequenceControls(
    length: _draft.sequenceLength,
    primitives: _draft.sequencePrimitives,
    problem: _draft.sequenceProblem,
    modelNames: {
      for (final model in widget.project.models3d) model.id: model.name,
    },
    activeModelId: _draft.saving ? null : _activeElement?.model3d?.id,
    selections: _draft.primitiveModelIds,
    onLength: (text) => _commitDraft(() => _draft.setSequenceLength(text)),
    onSource: (id, modelId) =>
        setState(() => _draft.setPrimitiveSource(id, modelId)),
  );

  void _setSettings(String role, BorderModelSettings settings) =>
      setState(() => _draft.setSettings(role, settings));

  Widget _modelSettings() {
    final roles = {
      'lineStraight': 'Corps',
      'lineCap': 'Extrémité',
      if (!_draft.straightOnly)
        'lineCorner': _draft.followContourDirection ? 'Angle sortant' : 'Angle',
      if (!_draft.straightOnly && _draft.followContourDirection)
        'lineCornerLeft': 'Angle rentrant',
    };
    final role = roles.containsKey(_settingsRole)
        ? _settingsRole
        : 'lineStraight';
    final settings = _draft.settingsFor(role);
    final model = _draft.chosen[role]?.model3d;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSelect(
          key: const ValueKey('border-settings-piece'),
          label: 'Réglages de la pièce',
          value: role,
          options: roles,
          onChanged: (value) => setState(() => _settingsRole = value),
        ),
        if (model != null) ...[
          const SizedBox(height: 8),
          StudioSelect(
            key: const ValueKey('border-settings-animation'),
            label: 'Animation',
            value: settings.animationIndex?.toString() ?? 'none',
            options: {
              'none': 'Aucune',
              if (settings.animationIndex != null &&
                  !model.inspection.animations.any(
                    (clip) => clip.index == settings.animationIndex,
                  ))
                settings.animationIndex.toString(): 'Animation indisponible',
              for (final clip in model.inspection.animations)
                clip.index.toString(): clip.name,
            },
            onChanged: (value) => _setSettings(
              role,
              BorderModelSettings(
                animationIndex: value == 'none' ? null : int.parse(value),
                animationLoop: settings.animationLoop,
                animationSpeed: settings.animationSpeed,
                blocksMovement: settings.blocksMovement,
                cornerJoinCells: settings.cornerJoinCells,
              ),
            ),
          ),
          if (settings.animationIndex != null) ...[
            StudioToggleRow(
              key: const ValueKey('border-settings-loop'),
              label: 'Boucle',
              value: settings.animationLoop,
              onChanged: (value) => _setSettings(
                role,
                BorderModelSettings(
                  animationIndex: settings.animationIndex,
                  animationLoop: value,
                  animationSpeed: settings.animationSpeed,
                  blocksMovement: settings.blocksMovement,
                  cornerJoinCells: settings.cornerJoinCells,
                ),
              ),
            ),
            StudioCommitField(
              key: ValueKey(
                'border-settings-speed-${_draft.primitiveId(role)}',
              ),
              label: 'Vitesse de l’animation',
              value: settings.animationSpeed.toString(),
              tryCommit: (value) =>
                  _commitDraft(() => _draft.setAnimationSpeed(role, value)),
            ),
          ],
          if (role == 'lineCorner' || role == 'lineCornerLeft')
            StudioCommitField(
              key: const ValueKey('border-settings-corner-join'),
              label: 'Raccord de l’angle · cases réservées de chaque côté',
              value: settings.cornerJoinCells.toString(),
              tryCommit: (text) =>
                  _commitDraft(() => _draft.setCornerJoin(role, text)),
            ),
          StudioToggleRow(
            key: const ValueKey('border-settings-blocks-movement'),
            label: 'Bloque le passage',
            value: settings.blocksMovement,
            onChanged: (value) => _setSettings(
              role,
              BorderModelSettings(
                animationIndex: settings.animationIndex,
                animationLoop: settings.animationLoop,
                animationSpeed: settings.animationSpeed,
                blocksMovement: value,
                cornerJoinCells: settings.cornerJoinCells,
              ),
            ),
          ),
        ] else
          const Text(
            'Associez un modèle à cette pièce pour choisir ses réglages.',
          ),
        if (_draft.settingsProblem case final problem?)
          StudioNotice(problem, isError: true),
      ],
    );
  }

  Widget _variantSelector(String role) {
    final variants =
        (_draft.sequenceLength > 1
                ? _draft.sequencePrimitives
                : widget.initialRecord?.draft.definition.primitives)
            ?.where((primitive) => _draft.roleKey(primitive) == role)
            .toList() ??
        [];
    if (variants.length < 2) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: StudioSelect(
        key: ValueKey('border-variant-$role'),
        label: switch (role) {
          'lineCap' => 'Variante de l’extrémité',
          'lineStraight' => 'Variante du corps',
          'lineCornerLeft' => 'Variante de l’angle rentrant',
          _ => 'Variante de l’angle',
        },
        value: _draft.selectedPrimitiveIds[role] ?? variants.first.id,
        options: {
          for (var i = 0; i < variants.length; i++)
            variants[i].id:
                '${_draft.sequenceLength > 1 ? 'Étape ${variants[i].sequenceIndex + 1}/${_draft.sequenceLength} · ' : ''}${i + 1} · ${switch (variants[i].authoredOrientation) {
                  BorderPrimitiveOrientation.north => 'vers le nord',
                  BorderPrimitiveOrientation.south => 'vers le sud',
                  BorderPrimitiveOrientation.east => 'vers l’est',
                  BorderPrimitiveOrientation.west => 'vers l’ouest',
                  _ => 'orientation d’origine',
                }}',
        },
        onChanged: (id) => setState(() => _draft.selectPrimitive(role, id)),
      ),
    );
  }

  Future<void> _close() async {
    if (await _workflow.requestClose() && mounted) {
      Navigator.of(context).pop(false);
    }
  }

  Future<bool> _confirmRepublication(Map<String, int> traced) async {
    final total = traced.values.fold(0, (sum, count) => sum + count);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const ValueKey('border-scope-review'),
        title: const Text('Republier une bordure déjà tracée ?'),
        content: Text(
          'Cette bordure est tracée en $total contour${total == 1 ? '' : 's'} '
          'sur les cartes ouvertes : '
          '${traced.entries.map((entry) => '${entry.key} (${entry.value})').join(', ')}.\n\n'
          'Tous ses contours, y compris sur les cartes fermées, suivront la '
          'nouvelle révision et seront régénérés. Leur tracé et leur identité '
          'sont conservés. Si la publication échoue, la révision actuelle reste '
          'en place.',
        ),
        actions: [
          StudioButton(
            key: const ValueKey('border-scope-cancel'),
            label: 'Annuler',
            secondary: true,
            onPressed: () => Navigator.pop(context, false),
          ),
          StudioButton(
            key: const ValueKey('border-scope-confirm'),
            label: 'Republier pour tous les contours',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _save(bool publish) async {
    final saving = _workflow.save(publish: publish);
    setState(() {});
    final saved = await saving;
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {});
    }
  }

  Widget _sources() => BorderSourcePanel(
    project: widget.project,
    visuals: widget.visuals,
    active: _activeElement,
    onActive: (element) => setState(() => _activeElement = element),
    activeMapId: widget.project.resourceLibraryCatalog
        .entryFor('borderBlueprint', _draft.pendingId ?? '')
        ?.mapId,
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Dialog(
        child: SizedBox(
          width: (size.width - 48).clamp(300, 1320).toDouble(),
          height: (size.height - 48).clamp(300, 880).toDouble(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _draft.nativeLedge
                          ? 'Modifier le rebord natif'
                          : widget.initialRecord == null
                          ? 'Créer une bordure avec un patron'
                          : 'Modifier la bordure',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _draft.nativeLedge
                          ? 'Les modules importés sont conservés. Le rebord publié sera disponible dans Carte › Bordures.'
                          : 'Déposez vos décors sur le patron. La bordure publiée sera disponible dans Carte › Bordures.',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _draft.nativeLedge
                    ? StudioDraftField(
                        key: const ValueKey('border-name'),
                        label: 'Nom du rebord',
                        value: _name.text,
                        enabled: !_draft.saving,
                        onChanged: (value) => setState(() {
                          _name.text = value;
                          _draft.name = value;
                          _draft.warningCodes = const [];
                        }),
                      )
                    : TextField(
                        key: const ValueKey('border-name'),
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Nom de la bordure',
                        ),
                        onChanged: (value) => setState(() {
                          _draft.name = value;
                          _draft.warningCodes = const [];
                        }),
                      ),
              ),
              if (_draft.error != null)
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: size.height * .2),
                  child: SingleChildScrollView(
                    child: StudioNotice(_draft.error!, isError: true),
                  ),
                ),
              if (_draft.warningCodes.isNotEmpty)
                Text(
                  'Raccords à vérifier : ${_draft.warningCodes.map(_warningLabel).join(', ')}.',
                ),
              const SizedBox(height: 12),
              if (widget.project.settings.dimension == ProjectDimension.twoD &&
                  widget.initialRecord == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: StudioToggleRow(
                    key: const ValueKey('border-horizontal-facade'),
                    label: 'Façade horizontale',
                    value: _draft.horizontalFacade,
                    onChanged: _draft.saving
                        ? null
                        : (value) => setState(() {
                            _draft.horizontalFacade = value;
                            _draft.warningCodes = const [];
                          }),
                  ),
                ),
              if (_draft.horizontalFacade)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: StudioNotice(
                    'Façades sur des tracés ouverts horizontaux, sans rotation ni miroir. Séparez les tracés pour les ouvertures.',
                  ),
                ),
              if (widget.project.settings.dimension ==
                      ProjectDimension.threeD &&
                  widget.initialRecord == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: StudioToggleRow(
                    key: const ValueKey('border-straight-only'),
                    label: 'Tracés droits uniquement',
                    value: _draft.straightOnly,
                    onChanged: (value) => setState(() {
                      _draft.setStraightOnly(value);
                    }),
                  ),
                ),
              if (widget.project.settings.dimension ==
                      ProjectDimension.threeD &&
                  widget.initialRecord == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: StudioToggleRow(
                    key: const ValueKey('border-contour-direction'),
                    label: 'Falaise ou mur avec un côté extérieur',
                    value: _draft.followContourDirection,
                    onChanged: (value) =>
                        setState(() => _draft.followContourDirection = value),
                  ),
                ),
              if (widget.project.settings.dimension == ProjectDimension.threeD)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LayoutBuilder(
                    builder: (context, bounds) {
                      final controls = [
                        StudioToggleRow(
                          key: const ValueKey('border-replaces-ground'),
                          label: 'Les pièces contiennent le rebord du sol',
                          value: _draft.replacesGround,
                          onChanged: (value) => setState(() {
                            _draft.setReplacesGround(value);
                          }),
                        ),
                        StudioToggleRow(
                          key: const ValueKey('border-masks-ground-cells'),
                          label: 'Masquer le sol sur les cases de la bordure',
                          value: _draft.masksGroundCells,
                          onChanged: (value) => setState(() {
                            _draft.setMasksGroundCells(value);
                          }),
                        ),
                      ];
                      return bounds.maxWidth < 760
                          ? Column(children: controls)
                          : Row(
                              children: [
                                for (final control in controls)
                                  Expanded(child: control),
                              ],
                            );
                    },
                  ),
                ),
              if (widget.project.settings.dimension ==
                      ProjectDimension.threeD &&
                  _draft.replacesGround)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      StudioCommitField(
                        key: const ValueKey('border-ground-base-offset'),
                        label: 'Abaissement du sol sous les pièces',
                        value:
                            (_draft.groundBaseOffset == 0
                                    ? 0
                                    : -_draft.groundBaseOffset)
                                .toString(),
                        tryCommit: (value) =>
                            _commitDraft(() => _draft.setGroundLowering(value)),
                      ),
                      const StudioNotice(
                        'À 0, le sol rejoint le pied des pièces. L’abaissement utilise leur échelle et conserve leur position.',
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LayoutBuilder(
                    builder: (context, bounds) {
                      if (_draft.nativeLedge) {
                        return SingleChildScrollView(
                          child: NativeLedgePanel(
                            record: _draft.expectedRecord!,
                            project: widget.project,
                            visuals: widget.visuals,
                            jumpSide: _draft.jumpSide,
                            onJumpSideChanged: _draft.saving
                                ? null
                                : (side) => setState(() {
                                    _draft.jumpSide = side;
                                    _draft.warningCodes = const [];
                                  }),
                          ),
                        );
                      }
                      final pattern = BorderPatternPanel(
                        project: widget.project,
                        chosen: _draft.chosen,
                        active: _activeElement,
                        visuals: widget.visuals,
                        straightOnly:
                            _draft.straightOnly || _draft.horizontalFacade,
                        followContourDirection: _draft.followContourDirection,
                        variantSelector: _variantSelector,
                        sequenceSettings:
                            widget.project.settings.dimension ==
                                    ProjectDimension.threeD &&
                                (widget
                                            .initialRecord
                                            ?.draft
                                            .definition
                                            .template ??
                                        BorderBlueprintTemplate
                                            .connectedLine) ==
                                    BorderBlueprintTemplate.connectedLine
                            ? _sequenceControls()
                            : null,
                        modelSettings:
                            widget.project.settings.dimension ==
                                ProjectDimension.threeD
                            ? _modelSettings()
                            : null,
                        settingsForRole: _draft.settingsFor,
                        onAssign: (role, element) =>
                            setState(() => _draft.assignRole(role, element)),
                      );
                      if (bounds.maxWidth < 820) {
                        return ListView(
                          children: [
                            SizedBox(height: 450, child: _sources()),
                            const SizedBox(height: 12),
                            SizedBox(height: 680, child: pattern),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: 300, child: _sources()),
                          const SizedBox(width: 12),
                          Expanded(child: pattern),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  runSpacing: 8,
                  children: [
                    StudioButton(
                      label: 'Fermer',
                      secondary: true,
                      onPressed: _draft.saving ? null : _close,
                    ),
                    const SizedBox(width: 10),
                    StudioButton(
                      label: 'Enregistrer le brouillon',
                      icon: Icons.save_outlined,
                      secondary: true,
                      onPressed:
                          _draft.saving ||
                              _name.text.trim().isEmpty ||
                              _draft.settingsProblem != null
                          ? null
                          : () => _save(false),
                    ),
                    const SizedBox(width: 10),
                    StudioButton(
                      key: const ValueKey('border-publish'),
                      label: _draft.saving
                          ? 'Publication en cours…'
                          : _draft.warningCodes.isNotEmpty
                          ? 'Publier avec ces avertissements'
                          : 'Publier la bordure',
                      icon: Icons.check,
                      onPressed:
                          _draft.saving ||
                              !_draft.complete ||
                              _name.text.trim().isEmpty ||
                              _draft.settingsProblem != null
                          ? null
                          : () => _save(true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _warningLabel(String code) => switch (code) {
    'border.publication.coverage_gap_exceeded' => 'espaces entre les pièces',
    'border.publication.coverage_overlap_exceeded' =>
      'chevauchement entre les pièces',
    _ => code,
  };
}
