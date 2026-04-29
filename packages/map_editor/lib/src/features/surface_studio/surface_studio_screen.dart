import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

import 'atlas/surface_studio_atlas_panel.dart';
import 'preview/surface_studio_preview_panel.dart';
import 'schema/surface_studio_schema_panel.dart';
import 'shell/surface_studio_bottom_action_bar.dart';
import 'shell/surface_studio_header.dart';
import 'shell/surface_studio_shell.dart';
import 'shell/surface_studio_sidebar.dart';
import 'surface_studio_column_selection.dart';
import 'surface_studio_drag_payload.dart';
import 'surface_studio_role_assignment_draft.dart';
import 'surface_studio_step.dart';

class SurfaceStudioScreen extends StatefulWidget {
  const SurfaceStudioScreen({
    super.key,
    required this.readModel,
  });

  final SurfaceStudioReadModel readModel;

  @override
  State<SurfaceStudioScreen> createState() => _SurfaceStudioScreenState();
}

class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
  SurfaceStudioWizardStep _currentStep = SurfaceStudioWizardStep.map;
  bool _sidebarCollapsed = false;
  bool _rightPanelCollapsed = false;
  Set<String> _openSchemaGroups = const {
    'surfaceMain',
    'edges',
    'externalCorners',
    'internalCorners',
    'junctions',
  };
  SurfaceStudioColumnSelection _selectedColumns =
      const SurfaceStudioColumnSelection(<int>[4, 5]);
  SurfaceStudioRoleAssignmentDraft _assignmentDraft =
      const SurfaceStudioRoleAssignmentDraft.empty()
          .assignColumns(SurfaceVariantRole.isolated, const <int>[4, 5, 6]);
  double _zoomPercent = 100;
  bool _previewPlaying = false;
  int _previewFrameIndex = 0;
  bool _previewLoop = true;
  bool _previewGridVisible = true;
  int _previewSize = 10;
  String? _statusMessage;
  Timer? _previewTimer;

  @override
  void dispose() {
    _previewTimer?.cancel();
    super.dispose();
  }

  int get _columnCount {
    final atlases = widget.readModel.atlases;
    if (atlases.isEmpty) {
      return 12;
    }
    return atlases.first.columns.clamp(1, 48).toInt();
  }

  int get _frameCount {
    final atlases = widget.readModel.atlases;
    if (atlases.isEmpty) {
      return 32;
    }
    return atlases.first.rows.clamp(1, 128).toInt();
  }

  int get _tileWidth {
    final atlases = widget.readModel.atlases;
    if (atlases.isEmpty) {
      return 32;
    }
    return atlases.first.tileWidth;
  }

  int get _tileHeight {
    final atlases = widget.readModel.atlases;
    if (atlases.isEmpty) {
      return 32;
    }
    return atlases.first.tileHeight;
  }

  Set<SurfaceStudioWizardStep> get _completedSteps => {
        SurfaceStudioWizardStep.importAtlas,
        SurfaceStudioWizardStep.slice,
        if (_assignmentDraft.isAssigned(SurfaceVariantRole.isolated))
          SurfaceStudioWizardStep.map,
        if (_currentStep.index > SurfaceStudioWizardStep.preview.index)
          SurfaceStudioWizardStep.preview,
      };

  bool get _canGoNext =>
      _currentStep != SurfaceStudioWizardStep.save &&
      (_currentStep != SurfaceStudioWizardStep.map ||
          _assignmentDraft.isAssigned(SurfaceVariantRole.isolated));

  void _selectStep(SurfaceStudioWizardStep step) {
    if (step == _currentStep) {
      return;
    }
    if (step.index <= _currentStep.index || _completedSteps.contains(step)) {
      setState(() {
        _currentStep = step;
        _statusMessage = null;
      });
      return;
    }
    setState(() {
      _statusMessage = 'Terminez les étapes précédentes avant d’avancer.';
    });
  }

  void _nextStep() {
    if (!_canGoNext) {
      setState(() {
        _statusMessage =
            'Assignez au moins le rôle “Plein” avant de continuer.';
      });
      return;
    }
    final nextIndex = (_currentStep.index + 1)
        .clamp(0, SurfaceStudioWizardStep.values.length - 1)
        .toInt();
    setState(() {
      _currentStep = SurfaceStudioWizardStep.values[nextIndex];
      _statusMessage = null;
    });
  }

  void _previousStep() {
    if (_currentStep == SurfaceStudioWizardStep.importAtlas) {
      return;
    }
    setState(() {
      _currentStep = SurfaceStudioWizardStep.values[_currentStep.index - 1];
      _statusMessage = null;
    });
  }

  void _togglePreviewPlaying() {
    setState(() {
      _previewPlaying = !_previewPlaying;
    });
    _syncPreviewTimer();
  }

  void _syncPreviewTimer() {
    _previewTimer?.cancel();
    _previewTimer = null;
    if (!_previewPlaying) {
      return;
    }
    _previewTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (_previewFrameIndex >= _frameCount - 1) {
          _previewFrameIndex = _previewLoop ? 0 : _frameCount - 1;
          if (!_previewLoop) {
            _previewPlaying = false;
            _syncPreviewTimer();
          }
        } else {
          _previewFrameIndex += 1;
        }
      });
    });
  }

  void _autoSuggestMapping() {
    final roles = <SurfaceVariantRole>[
      SurfaceVariantRole.isolated,
      SurfaceVariantRole.endNorth,
      SurfaceVariantRole.endEast,
      SurfaceVariantRole.endSouth,
      SurfaceVariantRole.endWest,
      SurfaceVariantRole.cornerNW,
      SurfaceVariantRole.cornerNE,
      SurfaceVariantRole.cornerSW,
      SurfaceVariantRole.cornerSE,
    ];
    var draft = const SurfaceStudioRoleAssignmentDraft.empty();
    draft = draft.assignColumns(
      SurfaceVariantRole.isolated,
      <int>[for (var c = 4; c <= 6 && c <= _columnCount; c++) c],
    );
    var column = 1;
    for (final role in roles.skip(1)) {
      if (column <= _columnCount) {
        draft = draft.assignColumns(role, <int>[column]);
      }
      column += 1;
    }
    setState(() {
      _assignmentDraft = draft;
      _statusMessage = 'Suggestion auto appliquée au brouillon local.';
    });
  }

  void _applyMapping() {
    setState(() {
      _statusMessage =
          'Mapping appliqué au brouillon local — aucune sauvegarde disque.';
    });
  }

  void _acceptDrop(
    SurfaceVariantRole role,
    SurfaceStudioColumnDragPayload payload,
  ) {
    final validation = validateSurfaceStudioRoleDrop(
      role: role,
      payload: payload,
      draft: _assignmentDraft,
    );
    if (validation != SurfaceStudioDropValidation.valid) {
      setState(() {
        _statusMessage =
            validation == SurfaceStudioDropValidation.invalidNoColumn
                ? 'Aucune colonne à déposer.'
                : 'Ce rôle attend une seule colonne.';
      });
      return;
    }
    setState(() {
      _assignmentDraft = _assignmentDraft.assignColumns(role, payload.columns);
      _statusMessage = 'Colonnes déposées sur le rôle sélectionné.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final frameCount = _frameCount;
    return Stack(
      children: [
        SurfaceStudioShell(
          header: SurfaceStudioHeader(
            currentStep: _currentStep,
            completedSteps: _completedSteps,
            onStepSelected: _selectStep,
          ),
          sidebar: SurfaceStudioSidebar(
            collapsed: _sidebarCollapsed,
            currentStep: _currentStep,
            completedSteps: _completedSteps,
            onToggleCollapsed: () {
              setState(() => _sidebarCollapsed = !_sidebarCollapsed);
            },
            onStepSelected: _selectStep,
          ),
          atlasPanel: SurfaceStudioAtlasPanel(
            columnCount: _columnCount,
            frameCount: frameCount,
            tileWidth: _tileWidth,
            tileHeight: _tileHeight,
            selection: _selectedColumns,
            zoomPercent: _zoomPercent,
            onColumnSelectionChanged: (selection) {
              setState(() => _selectedColumns = selection);
            },
            onZoomChanged: (value) {
              setState(() => _zoomPercent = value.clamp(25, 400).toDouble());
            },
            onReset: () {
              setState(() {
                _selectedColumns = const SurfaceStudioColumnSelection.empty();
                _zoomPercent = 100;
                _statusMessage = 'Sélection et zoom réinitialisés.';
              });
            },
            onAutoSuggest: _autoSuggestMapping,
          ),
          schemaPanel: SurfaceStudioSchemaPanel(
            collapsed: _rightPanelCollapsed,
            openGroups: _openSchemaGroups,
            assignmentDraft: _assignmentDraft,
            onToggleCollapsed: () {
              setState(() => _rightPanelCollapsed = !_rightPanelCollapsed);
            },
            onToggleGroup: (id) {
              setState(() {
                final next = Set<String>.of(_openSchemaGroups);
                if (!next.add(id)) {
                  next.remove(id);
                }
                _openSchemaGroups = next;
              });
            },
            onDrop: _acceptDrop,
            onClearRole: (role) {
              setState(
                  () => _assignmentDraft = _assignmentDraft.clearRole(role));
            },
            onClearColumn: (role, column) {
              setState(
                () => _assignmentDraft =
                    _assignmentDraft.clearColumn(role, column),
              );
            },
          ),
          previewPanel: SurfaceStudioPreviewPanel(
            frameCount: frameCount,
            frameIndex: _previewFrameIndex.clamp(0, frameCount - 1).toInt(),
            playing: _previewPlaying,
            loop: _previewLoop,
            gridVisible: _previewGridVisible,
            previewSize: _previewSize,
            assignmentDraft: _assignmentDraft,
            onPrevious: () {
              setState(() {
                _previewPlaying = false;
                _previewFrameIndex =
                    (_previewFrameIndex - 1).clamp(0, frameCount - 1).toInt();
              });
              _syncPreviewTimer();
            },
            onNext: () {
              setState(() {
                _previewPlaying = false;
                _previewFrameIndex =
                    (_previewFrameIndex + 1).clamp(0, frameCount - 1).toInt();
              });
              _syncPreviewTimer();
            },
            onTogglePlaying: _togglePreviewPlaying,
            onFrameChanged: (value) {
              setState(() {
                _previewPlaying = false;
                _previewFrameIndex = value.clamp(0, frameCount - 1).toInt();
              });
              _syncPreviewTimer();
            },
            onLoopChanged: (value) => setState(() => _previewLoop = value),
            onGridChanged: (value) =>
                setState(() => _previewGridVisible = value),
            onPreviewSizeChanged: (value) =>
                setState(() => _previewSize = value),
          ),
          bottomBar: SurfaceStudioBottomActionBar(
            canGoBack: _currentStep != SurfaceStudioWizardStep.importAtlas,
            canAutoSuggest: _columnCount > 0 && frameCount > 0,
            canApplyMapping:
                _assignmentDraft.isAssigned(SurfaceVariantRole.isolated),
            canGoNext: _canGoNext,
            onBack: _previousStep,
            onAutoSuggest: _autoSuggestMapping,
            onApplyMapping: _applyMapping,
            onNext: _nextStep,
          ),
        ),
        if (_statusMessage != null)
          Positioned(
            left: 318,
            bottom: 86,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF202A3C),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF4A556D)),
              ),
              child: Text(
                _statusMessage!,
                style: const TextStyle(
                  color: Color(0xFFF2F5FA),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
