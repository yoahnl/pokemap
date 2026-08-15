import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/theme.dart';
import '../../../design_system/design_system.dart';

const presentationStudioShellKey = ValueKey<String>(
  'presentation-studio-shell',
);
const presentationStudioInspectorResizeKey = ValueKey<String>(
  'presentation-studio-inspector-resize',
);
const presentationStudioTimelineResizeKey = ValueKey<String>(
  'presentation-studio-timeline-resize',
);
const presentationStudioCanvasSlotKey = ValueKey<String>(
  'presentation-studio-canvas-slot',
);
const presentationStudioInspectorSlotKey = ValueKey<String>(
  'presentation-studio-inspector-slot',
);
const presentationStudioTimelineSlotKey = ValueKey<String>(
  'presentation-studio-timeline-slot',
);

@immutable
final class PresentationStudioLayout {
  const PresentationStudioLayout({
    required this.inspectorWidth,
    required this.timelineHeight,
  });

  static const defaults = PresentationStudioLayout(
    inspectorWidth: 340,
    timelineHeight: 240,
  );

  final double inspectorWidth;
  final double timelineHeight;

  PresentationStudioLayout copyWith({
    double? inspectorWidth,
    double? timelineHeight,
  }) => PresentationStudioLayout(
    inspectorWidth: inspectorWidth ?? this.inspectorWidth,
    timelineHeight: timelineHeight ?? this.timelineHeight,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationStudioLayout &&
          other.inspectorWidth == inspectorWidth &&
          other.timelineHeight == timelineHeight;

  @override
  int get hashCode => Object.hash(inspectorWidth, timelineHeight);
}

abstract interface class PresentationStudioLayoutStore {
  Future<PresentationStudioLayout?> read();
  Future<void> write(PresentationStudioLayout layout);
}

final class MemoryPresentationStudioLayoutStore
    implements PresentationStudioLayoutStore {
  MemoryPresentationStudioLayoutStore([PresentationStudioLayout? initial])
    : _layout = initial;

  PresentationStudioLayout? _layout;

  @override
  Future<PresentationStudioLayout?> read() async => _layout;

  @override
  Future<void> write(PresentationStudioLayout layout) async {
    _layout = layout;
  }
}

class PresentationStudioShell extends StatefulWidget {
  const PresentationStudioShell({
    super.key,
    required this.title,
    required this.documentState,
    required this.statusLabel,
    required this.layoutStore,
    required this.onExit,
    required this.onDiscard,
    required this.onSave,
    required this.previewToolbar,
    required this.canvas,
    required this.layersPanel,
    required this.propertiesPanel,
    required this.timeline,
    this.statusDetail,
    this.backButtonKey,
  });

  final String title;
  final PokeMapCinematicDocumentState documentState;
  final String statusLabel;
  final String? statusDetail;
  final Key? backButtonKey;
  final PresentationStudioLayoutStore layoutStore;
  final VoidCallback onExit;
  final Future<void> Function() onDiscard;
  final Future<bool> Function() onSave;
  final Widget previewToolbar;
  final Widget canvas;
  final Widget layersPanel;
  final Widget propertiesPanel;
  final Widget timeline;

  @override
  State<PresentationStudioShell> createState() =>
      _PresentationStudioShellState();
}

class _PresentationStudioShellState extends State<PresentationStudioShell> {
  PresentationStudioLayout _layout = PresentationStudioLayout.defaults;
  PokeMapCinematicPanelTab _selectedPanel = PokeMapCinematicPanelTab.layers;
  bool _exitGuardOpen = false;
  bool _savingFromGuard = false;

  @override
  void initState() {
    super.initState();
    unawaited(_restoreLayout());
  }

  @override
  void didUpdateWidget(covariant PresentationStudioShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layoutStore != widget.layoutStore) {
      unawaited(_restoreLayout());
    }
  }

  Future<void> _restoreLayout() async {
    try {
      final restored = await widget.layoutStore.read();
      if (mounted && restored != null) {
        setState(() => _layout = restored);
      }
    } on Object {
      return;
    }
  }

  Future<void> _persistLayout() async {
    try {
      await widget.layoutStore.write(_layout);
    } on Object {
      return;
    }
  }

  bool get _blocksNavigation =>
      widget.documentState != PokeMapCinematicDocumentState.clean &&
      widget.documentState != PokeMapCinematicDocumentState.saved;

  Future<void> _requestExit() async {
    if (!_blocksNavigation) {
      widget.onExit();
      return;
    }
    if (_exitGuardOpen) return;
    _exitGuardOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => PokeMapDialog(
          title: 'Enregistrer avant de quitter ?',
          message:
              'Cette cinématique contient des modifications qui ne sont pas encore enregistrées.',
          icon: Icons.save_outlined,
          footer: PokeMapCinematicExitGuardActions(
            cancelLabel: 'Annuler',
            discardLabel: 'Quitter sans enregistrer',
            saveLabel: 'Enregistrer et quitter',
            isSaving: _savingFromGuard,
            onCancel: () => Navigator.of(dialogContext).pop(),
            onDiscard: () {
              unawaited(_discardAndExit(dialogContext));
            },
            onSave: () {
              setDialogState(() => _savingFromGuard = true);
              unawaited(_saveAndExit(dialogContext, setDialogState));
            },
          ),
        ),
      ),
    );
    _exitGuardOpen = false;
    _savingFromGuard = false;
  }

  Future<void> _discardAndExit(BuildContext dialogContext) async {
    await widget.onDiscard();
    if (!dialogContext.mounted) return;
    Navigator.of(dialogContext).pop();
    widget.onExit();
  }

  Future<void> _saveAndExit(
    BuildContext dialogContext,
    StateSetter setDialogState,
  ) async {
    final saved = await widget.onSave();
    if (!dialogContext.mounted) return;
    if (saved) {
      Navigator.of(dialogContext).pop();
      widget.onExit();
      return;
    }
    setDialogState(() => _savingFromGuard = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () {
          unawaited(widget.onSave());
        },
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          unawaited(widget.onSave());
        },
      },
      child: Focus(
        autofocus: true,
        child: ColoredBox(
          key: presentationStudioShellKey,
          color: colors.backgroundApp,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PokeMapCinematicWorkspaceToolbar(
                backLabel: 'Retour à la bibliothèque',
                title: widget.title,
                contextLabel: 'Cinématique de présentation',
                backButtonKey: widget.backButtonKey,
                onBack: () => unawaited(_requestExit()),
                status: PokeMapCinematicDocumentStatus(
                  state: widget.documentState,
                  label: widget.statusLabel,
                  detail: widget.statusDetail,
                ),
                actions: [
                  PokeMapButton(
                    key: const ValueKey('presentation-studio-save'),
                    onPressed:
                        widget.documentState ==
                                PokeMapCinematicDocumentState.saving ||
                            widget.documentState ==
                                PokeMapCinematicDocumentState.saved
                        ? null
                        : () => unawaited(widget.onSave()),
                    size: PokeMapButtonSize.small,
                    leading: const Icon(Icons.save_outlined),
                    child: const Text('Enregistrer'),
                  ),
                ],
              ),
              PokeMapToolbarSurface(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: widget.previewToolbar,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final layout = _effectiveLayout(constraints);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                key: presentationStudioCanvasSlotKey,
                                child: widget.canvas,
                              ),
                              PokeMapCinematicResizeHandle(
                                key: presentationStudioInspectorResizeKey,
                                axis: PokeMapCinematicResizeAxis.horizontal,
                                tooltip: 'Redimensionner le panneau droit',
                                onResize: (delta) {
                                  setState(
                                    () => _layout = layout.copyWith(
                                      inspectorWidth:
                                          layout.inspectorWidth - delta,
                                    ),
                                  );
                                },
                                onResizeEnd: () => unawaited(_persistLayout()),
                              ),
                              SizedBox(
                                key: presentationStudioInspectorSlotKey,
                                width: layout.inspectorWidth,
                                child: PokeMapPanel(
                                  padding: EdgeInsets.zero,
                                  borderRadius: 0,
                                  expandChild: true,
                                  header: PokeMapCinematicPanelTabs(
                                    selected: _selectedPanel,
                                    layersLabel: 'Calques',
                                    propertiesLabel: 'Propriétés',
                                    onChanged: (panel) =>
                                        setState(() => _selectedPanel = panel),
                                  ),
                                  child: switch (_selectedPanel) {
                                    PokeMapCinematicPanelTab.layers =>
                                      widget.layersPanel,
                                    PokeMapCinematicPanelTab.properties =>
                                      widget.propertiesPanel,
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        PokeMapCinematicResizeHandle(
                          key: presentationStudioTimelineResizeKey,
                          axis: PokeMapCinematicResizeAxis.vertical,
                          tooltip: 'Redimensionner la timeline',
                          onResize: (delta) {
                            setState(
                              () => _layout = layout.copyWith(
                                timelineHeight: layout.timelineHeight - delta,
                              ),
                            );
                          },
                          onResizeEnd: () => unawaited(_persistLayout()),
                        ),
                        SizedBox(
                          key: presentationStudioTimelineSlotKey,
                          height: layout.timelineHeight,
                          child: PokeMapPanel(
                            padding: EdgeInsets.zero,
                            borderRadius: 0,
                            expandChild: true,
                            child: widget.timeline,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PresentationStudioLayout _effectiveLayout(BoxConstraints constraints) {
    final inspectorMax = math.max(
      280.0,
      math.min(520.0, constraints.maxWidth - 520),
    );
    final timelineMax = math.max(
      180.0,
      math.min(360.0, constraints.maxHeight - 280),
    );
    return PresentationStudioLayout(
      inspectorWidth: _layout.inspectorWidth
          .clamp(280, inspectorMax)
          .toDouble(),
      timelineHeight: _layout.timelineHeight.clamp(180, timelineMax).toDouble(),
    );
  }
}
