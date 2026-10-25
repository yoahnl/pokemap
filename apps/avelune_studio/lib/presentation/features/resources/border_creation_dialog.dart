import '../../../features/resources/domain/resource_pack_port.dart';

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/resources/domain/resource_port.dart';
import '../../../features/resources/domain/border_sequence_primitives.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';
import '../map_workspace/map_workspace_visuals.dart';
import 'resource_navigation.dart';
import 'border_discard_dialog.dart';
import 'border_pattern_panel.dart';
import 'border_source_panel.dart';
import 'border_sequence_controls.dart';
import 'resource_catalog.dart';
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
  final _chosen = <String, ResourceItem>{};
  final _modifiedRoles = <String>{};
  final _selectedPrimitiveIds = <String, String>{};
  final _primitiveModelIds = <String, String>{};
  final _primitiveModelSettings = <String, BorderModelSettings>{};
  final _sequenceSourceModels = <String, String>{};
  String _settingsRole = 'lineStraight';
  late bool _straightOnly;
  late int _sequenceLength;
  late bool _horizontalFacade;
  late bool _followContourDirection;
  late bool _replacesGround;
  late bool _masksGroundCells;
  late double _groundBaseOffset;
  BorderBlueprintRecord? _expectedRecord;
  BorderLineSide? _jumpSide;
  ResourceItem? _activeElement;
  String? _pendingId;
  bool _saving = false;
  bool _confirmingClose = false;
  String? _error;
  List<String> _warningCodes = const [];
  late final bool Function() _dirtyOwner;
  late final ResourcePackBorderDraft Function() _exportOwner;

  @override
  void initState() {
    super.initState();
    final record = widget.initialRecord;
    _expectedRecord = record;
    _jumpSide = record?.draft.definition.jumpBehavior?.side;
    _name = TextEditingController(text: record?.draft.definition.name ?? '');
    _pendingId = record?.id;
    _straightOnly = record?.draft.definition.straightOnly ?? false;
    _sequenceLength = record?.draft.definition.sequenceLength ?? 1;
    _horizontalFacade =
        record?.draft.definition.template ==
        BorderBlueprintTemplate.horizontalFacade;
    _followContourDirection =
        record?.draft.definition.followContourDirection ?? false;
    _replacesGround = record?.draft.definition.replacesGround ?? false;
    _masksGroundCells = record?.draft.definition.masksGroundCells ?? false;
    _groundBaseOffset = record?.draft.definition.groundBaseOffset ?? 0;
    _dirtyOwner = () => _hasChanges || _saving;
    _exportOwner = () => ResourcePackBorderDraft(
      request: _currentRequest(),
      dirty: _hasChanges,
      saving: _saving,
    );
    if (_pendingId != null) {
      widget.navigation.borderEditorOwners[_pendingId!] = _dirtyOwner;
      widget.navigation.packBorderDraftOwners[_pendingId!] = _exportOwner;
    }
    for (final primitive
        in record?.draft.definition.primitives ?? <BorderPrimitiveDraft>[]) {
      final element = resourceCatalog(widget.project)
          .where(
            (candidate) =>
                candidate.canonicalKind ==
                    (primitive.isSpatial ? 'model3d' : 'element') &&
                candidate.id ==
                    (primitive.sourceModelId ?? primitive.sourceElementId),
          )
          .firstOrNull;
      final role = _roleKey(primitive);
      if (element != null && !_chosen.containsKey(role)) {
        _chosen[role] = element;
        if (primitive.isSpatial) {
          _selectedPrimitiveIds[role] = primitive.id;
        }
      }
    }
  }

  @override
  void dispose() {
    if (widget.navigation.borderEditorOwners[_pendingId] == _dirtyOwner) {
      widget.navigation.borderEditorOwners.remove(_pendingId);
    }
    if (widget.navigation.packBorderDraftOwners[_pendingId] == _exportOwner) {
      widget.navigation.packBorderDraftOwners.remove(_pendingId);
    }
    _name.dispose();
    super.dispose();
  }

  bool get _nativeLedge =>
      widget.initialRecord != null &&
      !widget.initialRecord!.draft.definition.isSpatial &&
      widget.initialRecord!.draft.definition.template ==
          BorderBlueprintTemplate.ledgeLine;

  bool get _hasChanges => _nativeLedge
      ? _name.text != _expectedRecord?.draft.definition.name ||
            _jumpSide != _expectedRecord?.draft.definition.jumpBehavior?.side
      : _name.text != (widget.initialRecord?.draft.definition.name ?? '') ||
            _horizontalFacade !=
                (widget.initialRecord?.draft.definition.template ==
                    BorderBlueprintTemplate.horizontalFacade) ||
            _straightOnly !=
                (widget.initialRecord?.draft.definition.straightOnly ??
                    false) ||
            _sequenceLength !=
                (widget.initialRecord?.draft.definition.sequenceLength ?? 1) ||
            _replacesGround !=
                (widget.initialRecord?.draft.definition.replacesGround ??
                    false) ||
            _masksGroundCells !=
                (widget.initialRecord?.draft.definition.masksGroundCells ??
                    false) ||
            _groundBaseOffset !=
                (widget.initialRecord?.draft.definition.groundBaseOffset ??
                    0) ||
            _followContourDirection !=
                (widget
                        .initialRecord
                        ?.draft
                        .definition
                        .followContourDirection ??
                    false) ||
            _primitiveModelIds.entries.any(
              (entry) =>
                  widget.initialRecord?.draft.definition.primitives
                      .where((primitive) => primitive.id == entry.key)
                      .firstOrNull
                      ?.sourceModelId !=
                  entry.value,
            ) ||
            _primitiveModelSettings.entries.any(
              (entry) => entry.value != _initialSettings(entry.key),
            ) ||
            _roles.any(
              (role) =>
                  !_selectedPrimitiveIds.containsKey(role) &&
                  _sourceId(role) !=
                      widget.initialRecord?.draft.definition.primitives
                          .where((primitive) => _roleKey(primitive) == role)
                          .map(
                            (primitive) =>
                                primitive.sourceModelId ??
                                primitive.sourceElementId,
                          )
                          .firstOrNull,
            );

  String _roleKey(BorderPrimitiveDraft primitive) =>
      primitive.cornerTurn == BorderCornerTurn.left
      ? 'lineCornerLeft'
      : primitive.role.name;

  List<String> get _roles => [
    'lineStraight',
    'lineCap',
    if (!_straightOnly && !_horizontalFacade) 'lineCorner',
    if (!_straightOnly && !_horizontalFacade && _followContourDirection)
      'lineCornerLeft',
  ];

  String? _sourceId(String role) => _modifiedRoles.contains(role)
      ? _chosen[role]?.id
      : _chosen[role]?.id ??
            widget.initialRecord?.draft.definition.primitives
                .where((primitive) => _roleKey(primitive) == role)
                .map(
                  (primitive) =>
                      primitive.sourceModelId ?? primitive.sourceElementId,
                )
                .firstOrNull;

  bool get _complete => _baseComplete && _sequenceProblem == null;

  String? get _sequenceProblem {
    if (_sequenceLength == 1) return null;
    final phases = <int, Set<BorderPrimitiveRole>>{};
    for (final primitive in _sequencePrimitives) {
      phases.putIfAbsent(primitive.sequenceIndex, () => {}).add(primitive.role);
    }
    if (phases.length != _sequenceLength ||
        phases.values.any(
          (roles) => !roles.containsAll({
            BorderPrimitiveRole.lineCap,
            BorderPrimitiveRole.lineStraight,
            if (!_straightOnly) BorderPrimitiveRole.lineCorner,
          }),
        )) {
      return _straightOnly
          ? 'Chaque étape doit contenir un corps et des extrémités avant publication.'
          : 'Chaque étape doit contenir un corps, des extrémités et des angles avant publication.';
    }
    if (!_straightOnly && _followContourDirection) {
      for (var phase = 0; phase < _sequenceLength; phase++) {
        final turns = _sequencePrimitives
            .where(
              (p) =>
                  p.sequenceIndex == phase &&
                  p.role == BorderPrimitiveRole.lineCorner,
            )
            .map((p) => p.cornerTurn)
            .toSet();
        if (!turns.containsAll(BorderCornerTurn.values)) {
          return 'Ajoutez les angles rentrants et sortants à chaque étape du motif.';
        }
      }
    }
    return null;
  }

  bool get _baseComplete => _nativeLedge
      ? NativeLedgePanel.sourcesAvailable(
          _expectedRecord!,
          widget.project,
          widget.visuals,
        )
      : _sourceId('lineCap') != null &&
            _sourceId('lineStraight') != null &&
            (_horizontalFacade ||
                _straightOnly ||
                (_sourceId('lineCorner') != null &&
                    (!_followContourDirection ||
                        _sourceId('lineCornerLeft') != null)));

  String _primitiveId(String role) => _selectedPrimitiveIds[role] ?? role;

  List<BorderPrimitiveDraft> get _sequencePrimitives =>
      borderSequencePrimitives(
        widget.initialRecord?.draft.definition.primitives ??
            borderSequenceModelPrimitives(
              straightModelId:
                  _sequenceSourceModels['lineStraight'] ??
                  _chosen['lineStraight']?.model3d?.id,
              capModelId:
                  _sequenceSourceModels['lineCap'] ??
                  _chosen['lineCap']?.model3d?.id,
              cornerModelId: _straightOnly
                  ? null
                  : _sequenceSourceModels['lineCorner'] ??
                        _chosen['lineCorner']?.model3d?.id,
              innerCornerModelId: _straightOnly || !_followContourDirection
                  ? null
                  : _sequenceSourceModels['lineCornerLeft'] ??
                        _chosen['lineCornerLeft']?.model3d?.id,
              directed: _followContourDirection,
            ),
        _sequenceLength,
        previousLength:
            widget.initialRecord?.draft.definition.sequenceLength ?? 1,
      );

  Widget _sequenceControls() => BorderSequenceControls(
    length: _sequenceLength,
    primitives: _sequencePrimitives,
    problem: _sequenceProblem,
    modelNames: {
      for (final model in widget.project.models3d) model.id: model.name,
    },
    activeModelId: _saving ? null : _activeElement?.model3d?.id,
    selections: _primitiveModelIds,
    onLength: (text) {
      final value = int.tryParse(text.trim());
      if (_saving || value == null || value < 1 || value > 64) {
        setState(() => _error = 'Le motif doit contenir de 1 à 64 étapes.');
        return false;
      }
      setState(() {
        if (widget.initialRecord == null) {
          if (value == 1) {
            _sequenceSourceModels.clear();
          } else {
            for (final role in _roles) {
              if (_chosen[role]?.model3d?.id case final id?) {
                _sequenceSourceModels.putIfAbsent(role, () => id);
              }
            }
          }
        }
        final previousLength = _sequenceLength;
        _sequenceLength = value;
        for (final primitive in _sequencePrimitives.where(
          (p) => p.sequenceIndex >= previousLength,
        )) {
          final prototype = _sequencePrimitives
              .where(
                (p) =>
                    p.sequenceIndex == 0 && _roleKey(p) == _roleKey(primitive),
              )
              .firstOrNull;
          final settings = prototype == null
              ? null
              : _primitiveModelSettings[prototype.id];
          if (settings != null) {
            _primitiveModelSettings.putIfAbsent(primitive.id, () => settings);
          }
        }
        final ids = _sequencePrimitives.map((p) => p.id).toSet();
        _primitiveModelIds.removeWhere((id, _) => !ids.contains(id));
        _primitiveModelSettings.removeWhere((id, _) => !ids.contains(id));
        for (final role in _roles) {
          if (ids.contains(_selectedPrimitiveIds[role])) continue;
          final first = _sequencePrimitives
              .where((p) => _roleKey(p) == role)
              .firstOrNull;
          if (first == null) {
            _selectedPrimitiveIds.remove(role);
          } else {
            _selectedPrimitiveIds[role] = first.id;
            final source = _primitiveModelIds[first.id] ?? first.sourceModelId;
            final item = resourceCatalog(widget.project)
                .where((item) => item.id == source && item.model3d != null)
                .firstOrNull;
            if (item != null) _chosen[role] = item;
          }
        }
        _error = null;
        _warningCodes = const [];
      });
      return true;
    },
    onSource: (id, modelId) => setState(() {
      _primitiveModelIds[id] = modelId;
      for (final role in _roles.where(
        (role) => _selectedPrimitiveIds[role] == id,
      )) {
        _chosen[role] = resourceCatalog(widget.project)
            .firstWhere((item) => item.id == modelId && item.model3d != null);
      }
      _warningCodes = const [];
    }),
  );

  BorderModelSettings _initialSettings(String id) {
    final primitive =
        (_sequenceLength > 1
                ? _sequencePrimitives
                : widget.initialRecord?.draft.definition.primitives)
            ?.where((primitive) => primitive.id == id)
            .firstOrNull;
    return BorderModelSettings(
      animationIndex: primitive?.animationIndex,
      animationLoop: primitive?.animationLoop ?? true,
      animationSpeed: primitive?.animationSpeed ?? 1,
      blocksMovement: primitive?.blocksMovement ?? true,
      cornerJoinCells: primitive?.cornerJoinCells ?? 0,
    );
  }

  BorderModelSettings _settingsFor(String role) =>
      _primitiveModelSettings[_primitiveId(role)] ??
      _initialSettings(_primitiveId(role));

  void _setSettings(String role, BorderModelSettings settings) => setState(() {
    _primitiveModelSettings[_primitiveId(role)] = settings;
    _warningCodes = const [];
  });

  String? get _settingsProblem {
    final primitives =
        (_sequenceLength > 1
            ? _sequencePrimitives
            : widget.initialRecord?.draft.definition.primitives) ??
        <BorderPrimitiveDraft>[];
    for (final primitive in primitives.where(
      (primitive) => primitive.isSpatial,
    )) {
      final modelId =
          _primitiveModelIds[primitive.id] ?? primitive.sourceModelId;
      final model = widget.project.models3d
          .where((model) => model.id == modelId)
          .firstOrNull;
      final settings =
          _primitiveModelSettings[primitive.id] ??
          _initialSettings(primitive.id);
      if (model != null &&
          settings.animationIndex != null &&
          !model.inspection.animations.any(
            (clip) => clip.index == settings.animationIndex,
          )) {
        return 'Le modèle choisi ne contient plus l’animation sélectionnée. Choisissez une animation disponible ou « Aucune ».';
      }
    }
    for (final role in _roles) {
      if (primitives.any((primitive) => _roleKey(primitive) == role)) continue;
      final settings = _settingsFor(role);
      final model = _chosen[role]?.model3d;
      if (model != null &&
          settings.animationIndex != null &&
          !model.inspection.animations.any(
            (clip) => clip.index == settings.animationIndex,
          )) {
        return 'Le modèle choisi ne contient plus l’animation sélectionnée. Choisissez une animation disponible ou « Aucune ».';
      }
    }
    return null;
  }

  Widget _modelSettings() {
    final roles = {
      'lineStraight': 'Corps',
      'lineCap': 'Extrémité',
      if (!_straightOnly)
        'lineCorner': _followContourDirection ? 'Angle sortant' : 'Angle',
      if (!_straightOnly && _followContourDirection)
        'lineCornerLeft': 'Angle rentrant',
    };
    final role = roles.containsKey(_settingsRole)
        ? _settingsRole
        : 'lineStraight';
    final settings = _settingsFor(role);
    final model = _chosen[role]?.model3d;
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
              key: ValueKey('border-settings-speed-${_primitiveId(role)}'),
              label: 'Vitesse de l’animation',
              value: settings.animationSpeed.toString(),
              tryCommit: (value) {
                final speed = double.tryParse(
                  value.trim().replaceAll(',', '.'),
                );
                if (speed == null ||
                    !speed.isFinite ||
                    speed <= 0 ||
                    speed > 16) {
                  setState(
                    () => _error = 'La vitesse doit être supérieure à 0 et au maximum égale à 16.',
                  );
                  return false;
                }
                _error = null;
                _setSettings(
                  role,
                  BorderModelSettings(
                    animationIndex: settings.animationIndex,
                    animationLoop: settings.animationLoop,
                    animationSpeed: speed,
                    blocksMovement: settings.blocksMovement,
                    cornerJoinCells: settings.cornerJoinCells,
                  ),
                );
                return true;
              },
            ),
          ],
          if (role == 'lineCorner' || role == 'lineCornerLeft')
            StudioCommitField(
              key: const ValueKey('border-settings-corner-join'),
              label: 'Raccord de l’angle · cases réservées de chaque côté',
              value: settings.cornerJoinCells.toString(),
              tryCommit: (text) {
                final cells = int.tryParse(text.trim());
                if (cells == null || cells < 0 || cells > 8) {
                  setState(
                    () => _error = 'Le raccord doit réserver de 0 à 8 cases de chaque côté.',
                  );
                  return false;
                }
                _error = null;
                _setSettings(
                  role,
                  BorderModelSettings(
                    animationIndex: settings.animationIndex,
                    animationLoop: settings.animationLoop,
                    animationSpeed: settings.animationSpeed,
                    blocksMovement: settings.blocksMovement,
                    cornerJoinCells: cells,
                  ),
                );
                return true;
              },
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
        if (_settingsProblem case final problem?)
          StudioNotice(problem, isError: true),
      ],
    );
  }

  Widget _variantSelector(String role) {
    final variants =
        (_sequenceLength > 1
                ? _sequencePrimitives
                : widget.initialRecord?.draft.definition.primitives)
            ?.where((primitive) => _roleKey(primitive) == role)
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
        value: _selectedPrimitiveIds[role] ?? variants.first.id,
        options: {
          for (var i = 0; i < variants.length; i++)
            variants[i].id:
                '${_sequenceLength > 1 ? 'Étape ${variants[i].sequenceIndex + 1}/$_sequenceLength · ' : ''}${i + 1} · ${switch (variants[i].authoredOrientation) {
                  BorderPrimitiveOrientation.north => 'vers le nord',
                  BorderPrimitiveOrientation.south => 'vers le sud',
                  BorderPrimitiveOrientation.east => 'vers l’est',
                  BorderPrimitiveOrientation.west => 'vers l’ouest',
                  _ => 'orientation d’origine',
                }}',
        },
        onChanged: (id) => setState(() {
          _selectedPrimitiveIds[role] = id;
          final primitive = variants.firstWhere(
            (primitive) => primitive.id == id,
          );
          final sourceId = _primitiveModelIds[id] ?? primitive.sourceModelId;
          final item = resourceCatalog(widget.project)
              .where(
                (item) =>
                    item.id == sourceId && item.canonicalKind == 'model3d',
              )
              .firstOrNull;
          if (item != null) _chosen[role] = item;
        }),
      ),
    );
  }

  Future<void> _close() async {
    if (_saving || _confirmingClose) return;
    if (!_hasChanges) {
      Navigator.of(context).pop(false);
      return;
    }
    _confirmingClose = true;
    final discard = await confirmBorderDiscard(context);
    _confirmingClose = false;
    if (discard == true && mounted) Navigator.of(context).pop(false);
  }

  BorderCreationRequest _currentRequest({bool publish = false}) => _nativeLedge
      ? BorderCreationRequest(
          name: _name.text.trim(),
          blueprintId: _pendingId,
          jumpSide: _jumpSide,
          expectedRecord: _expectedRecord,
          publish: publish,
          acceptedWarningCodes: List.unmodifiable(_warningCodes),
        )
      : BorderCreationRequest(
          name: _name.text.trim(),
          template: _horizontalFacade
              ? BorderBlueprintTemplate.horizontalFacade
              : null,
          capElementId:
              widget.project.settings.dimension == ProjectDimension.twoD
              ? _sourceId('lineCap')
              : null,
          straightElementId:
              widget.project.settings.dimension == ProjectDimension.twoD
              ? _sourceId('lineStraight')
              : null,
          cornerElementId:
              widget.project.settings.dimension == ProjectDimension.twoD &&
                  !_horizontalFacade
              ? _sourceId('lineCorner')
              : null,
          capModelId:
              widget.project.settings.dimension == ProjectDimension.threeD &&
                  (widget.initialRecord == null ||
                      !_selectedPrimitiveIds.containsKey('lineCap'))
              ? _sequenceSourceModels['lineCap'] ?? _sourceId('lineCap')
              : null,
          straightModelId:
              widget.project.settings.dimension == ProjectDimension.threeD &&
                  (widget.initialRecord == null ||
                      !_selectedPrimitiveIds.containsKey('lineStraight'))
              ? _sequenceSourceModels['lineStraight'] ??
                    _sourceId('lineStraight')
              : null,
          cornerModelId:
              widget.project.settings.dimension == ProjectDimension.threeD &&
                  (widget.initialRecord == null ||
                      !_selectedPrimitiveIds.containsKey('lineCorner'))
              ? _sourceId('lineCorner')
              : null,
          innerCornerModelId:
              _followContourDirection &&
                  (widget.initialRecord == null ||
                      !_selectedPrimitiveIds.containsKey('lineCornerLeft'))
              ? _sourceId('lineCornerLeft')
              : null,
          blueprintId: _pendingId,
          expectedRecord: _expectedRecord,
          primitiveModelIds: Map.unmodifiable(_primitiveModelIds),
          primitiveModelSettings: Map.unmodifiable(_primitiveModelSettings),
          sequenceLength: _sequenceLength,
          straightOnly: _straightOnly,
          followContourDirection: _followContourDirection,
          replacesGround: _replacesGround,
          masksGroundCells: _masksGroundCells,
          groundBaseOffset: _groundBaseOffset,
          publish: publish,
          acceptedWarningCodes: List.unmodifiable(_warningCodes),
        );

  Future<void> _save(bool publish) async {
    if (_saving ||
        _name.text.trim().isEmpty ||
        _settingsProblem != null ||
        (publish && !_complete)) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final request = _currentRequest(publish: publish);
    try {
      final receipt = await widget.navigation.port.createBorder(request);
      await widget.navigation.accept(receipt);
      if (mounted) Navigator.of(context).pop(true);
    } on ResourceFailure catch (failure) {
      if (failure.partialReceipt case final partial?) {
        _expectedRecord =
            partial.manifest.borderCatalog.recordById(
              failure.borderId ?? _pendingId ?? '',
            ) ??
            _expectedRecord;
        await widget.navigation.accept(partial);
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = failure.message;
        _pendingId = failure.borderId ?? _pendingId;
        if (_pendingId != null) {
          widget.navigation.borderEditorOwners[_pendingId!] = _dirtyOwner;
          widget.navigation.packBorderDraftOwners[_pendingId!] = _exportOwner;
        }
        _warningCodes = failure.warningCodes;
      });
    } catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = failure.toString();
      });
    }
  }

  Widget _sources() => BorderSourcePanel(
    project: widget.project,
    visuals: widget.visuals,
    active: _activeElement,
    onActive: (element) => setState(() => _activeElement = element),
    activeMapId: widget.project.resourceLibraryCatalog
        .entryFor('borderBlueprint', _pendingId ?? '')
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
                      _nativeLedge
                          ? 'Modifier le rebord natif'
                          : widget.initialRecord == null
                          ? 'Créer une bordure avec un patron'
                          : 'Modifier la bordure',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _nativeLedge
                          ? 'Les modules importés sont conservés. Le rebord publié sera disponible dans Carte › Bordures.'
                          : 'Déposez vos décors sur le patron. La bordure publiée sera disponible dans Carte › Bordures.',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _nativeLedge
                    ? StudioDraftField(
                        key: const ValueKey('border-name'),
                        label: 'Nom du rebord',
                        value: _name.text,
                        enabled: !_saving,
                        onChanged: (value) => setState(() {
                          _name.text = value;
                          _warningCodes = const [];
                        }),
                      )
                    : TextField(
                        key: const ValueKey('border-name'),
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Nom de la bordure',
                        ),
                        onChanged: (_) =>
                            setState(() => _warningCodes = const []),
                      ),
              ),
              if (_error != null)
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: size.height * .2),
                  child: SingleChildScrollView(
                    child: StudioNotice(_error!, isError: true),
                  ),
                ),
              if (_warningCodes.isNotEmpty)
                Text(
                  'Raccords à vérifier : ${_warningCodes.map(_warningLabel).join(', ')}.',
                ),
              const SizedBox(height: 12),
              if (widget.project.settings.dimension == ProjectDimension.twoD &&
                  widget.initialRecord == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: StudioToggleRow(
                    key: const ValueKey('border-horizontal-facade'),
                    label: 'Façade horizontale',
                    value: _horizontalFacade,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() {
                            _horizontalFacade = value;
                            _warningCodes = const [];
                          }),
                  ),
                ),
              if (_horizontalFacade)
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
                    value: _straightOnly,
                    onChanged: (value) => setState(() {
                      _straightOnly = value;
                      _error = null;
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
                    value: _followContourDirection,
                    onChanged: (value) =>
                        setState(() => _followContourDirection = value),
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
                          value: _replacesGround,
                          onChanged: (value) => setState(() {
                            _replacesGround = value;
                            if (!value) _groundBaseOffset = 0;
                            if (value) _masksGroundCells = false;
                          }),
                        ),
                        StudioToggleRow(
                          key: const ValueKey('border-masks-ground-cells'),
                          label: 'Masquer le sol sur les cases de la bordure',
                          value: _masksGroundCells,
                          onChanged: (value) => setState(() {
                            _masksGroundCells = value;
                            if (value) {
                              _replacesGround = false;
                              _groundBaseOffset = 0;
                            }
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
                  _replacesGround)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      StudioCommitField(
                        key: const ValueKey('border-ground-base-offset'),
                        label: 'Abaissement du sol sous les pièces',
                        value: (_groundBaseOffset == 0 ? 0 : -_groundBaseOffset)
                            .toString(),
                        tryCommit: (value) {
                          final amount = double.tryParse(
                            value.trim().replaceAll(',', '.'),
                          );
                          if (amount == null ||
                              !amount.isFinite ||
                              amount < 0) {
                            setState(
                              () => _error = 'L’abaissement doit être un nombre positif ou nul.',
                            );
                            return false;
                          }
                          setState(() {
                            _groundBaseOffset = amount == 0 ? 0 : -amount;
                            _error = null;
                          });
                          return true;
                        },
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
                      if (_nativeLedge) {
                        return SingleChildScrollView(
                          child: NativeLedgePanel(
                            record: _expectedRecord!,
                            project: widget.project,
                            visuals: widget.visuals,
                            jumpSide: _jumpSide,
                            onJumpSideChanged: _saving
                                ? null
                                : (side) => setState(() {
                                    _jumpSide = side;
                                    _warningCodes = const [];
                                  }),
                          ),
                        );
                      }
                      final pattern = BorderPatternPanel(
                        project: widget.project,
                        chosen: _chosen,
                        active: _activeElement,
                        visuals: widget.visuals,
                        straightOnly: _straightOnly || _horizontalFacade,
                        followContourDirection: _followContourDirection,
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
                        settingsForRole: _settingsFor,
                        onAssign: (role, element) => setState(() {
                          _modifiedRoles.add(role);
                          _chosen[role] = element;
                          if (widget.initialRecord == null &&
                              _sequenceLength > 1 &&
                              element.model3d != null) {
                            _sequenceSourceModels.putIfAbsent(
                              role,
                              () => element.id,
                            );
                          }
                          final primitiveId = _selectedPrimitiveIds[role];
                          if (primitiveId != null && element.model3d != null) {
                            _primitiveModelIds[primitiveId] = element.id;
                          }
                          _warningCodes = const [];
                        }),
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
                      onPressed: _saving ? null : _close,
                    ),
                    const SizedBox(width: 10),
                    StudioButton(
                      label: 'Enregistrer le brouillon',
                      icon: Icons.save_outlined,
                      secondary: true,
                      onPressed:
                          _saving ||
                              _name.text.trim().isEmpty ||
                              _settingsProblem != null
                          ? null
                          : () => _save(false),
                    ),
                    const SizedBox(width: 10),
                    StudioButton(
                      key: const ValueKey('border-publish'),
                      label: _saving
                          ? 'Publication en cours…'
                          : _warningCodes.isNotEmpty
                          ? 'Publier avec ces avertissements'
                          : 'Publier la bordure',
                      icon: Icons.check,
                      onPressed:
                          _saving ||
                              !_complete ||
                              _name.text.trim().isEmpty ||
                              _settingsProblem != null
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
