import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../application/character_studio_media_resolver.dart';
import '../preview/character_studio_media_preview.dart';

typedef CharacterPortraitImportCallback = Future<bool> Function(String stateId);
typedef CharacterPortraitClearCallback = Future<bool> Function(String stateId);
typedef CharacterPortraitFitCallback =
    Future<bool> Function(String stateId, CharacterPortraitFitMode fitMode);

class CharacterStudioPortraitsTab extends StatefulWidget {
  const CharacterStudioPortraitsTab({
    super.key,
    required this.project,
    required this.character,
    required this.projectRootPath,
    required this.projectRevision,
    required this.mediaResolver,
    required this.isSaving,
    required this.onImport,
    required this.onClear,
    required this.onFitChanged,
    required this.onManageGlobalStates,
    this.selectedStateId,
    this.onSelectionChanged,
  });

  final ProjectManifest project;
  final ProjectCharacterEntry character;
  final String projectRootPath;
  final String projectRevision;
  final CharacterStudioMediaResolverContract mediaResolver;
  final bool isSaving;
  final CharacterPortraitImportCallback onImport;
  final CharacterPortraitClearCallback onClear;
  final CharacterPortraitFitCallback onFitChanged;
  final VoidCallback onManageGlobalStates;
  final String? selectedStateId;
  final ValueChanged<String>? onSelectionChanged;

  @override
  State<CharacterStudioPortraitsTab> createState() =>
      _CharacterStudioPortraitsTabState();
}

class _CharacterStudioPortraitsTabState
    extends State<CharacterStudioPortraitsTab> {
  String? _selectedStateId;
  bool _busy = false;
  bool _checkerboard = true;
  String? _feedback;
  bool _feedbackIsError = false;

  bool get _locked => widget.isSaving || _busy;

  List<CharacterPortraitStateDefinition> get _states {
    return widget.project.characterStudioCatalog.portraitStates.toList()
      ..sort((left, right) {
        final order = left.sortOrder.compareTo(right.sortOrder);
        return order != 0 ? order : left.id.compareTo(right.id);
      });
  }

  String? get _effectiveStateId {
    final states = _states;
    if (states.isEmpty) return null;
    final selected = widget.selectedStateId ?? _selectedStateId;
    if (selected != null && states.any((state) => state.id == selected)) {
      return selected;
    }
    return states.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final states = _states;
    final selectedStateId = _effectiveStateId;
    if (states.isEmpty || selectedStateId == null) {
      return PokeMapEmptyState(
        title: 'Aucune expression globale',
        description:
            'Créez une expression globale avant d’ajouter un portrait.',
        icon: const Icon(CupertinoIcons.photo_on_rectangle),
        action: PokeMapButton(
          key: const ValueKey<String>('portrait-manage-global-states'),
          onPressed: widget.onManageGlobalStates,
          leading: const Icon(CupertinoIcons.slider_horizontal_3),
          child: const Text('Gérer les expressions globales'),
        ),
      );
    }
    final definition = states.firstWhere(
      (state) => state.id == selectedStateId,
    );
    final portrait = _portraitFor(selectedStateId);
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_feedback case final message?)
            PokeMapActionBanner(
              title: _feedbackIsError ? 'Portrait non modifié' : message,
              message: _feedbackIsError
                  ? message
                  : 'La sélection ${definition.displayName} est conservée.',
              tone: _feedbackIsError ? PokeMapTone.danger : PokeMapTone.success,
              dismissLabel: 'Masquer',
              onDismiss: () => setState(() => _feedback = null),
            )
          else
            const PokeMapActionBanner(
              title: 'Expressions du personnage',
              message:
                  'Les expressions sont communes au projet. Chaque personnage fournit son propre portrait PNG.',
              tone: PokeMapTone.info,
            ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 720) {
                  return ListView(
                    children: [
                      SizedBox(
                        height: 430,
                        child: _buildSelectedPanel(definition, portrait),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 430,
                        child: _buildGridPanel(states, selectedStateId),
                      ),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildSelectedPanel(definition, portrait),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 6,
                      child: _buildGridPanel(states, selectedStateId),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPanel(
    CharacterPortraitStateDefinition definition,
    CharacterPortraitVariant? portrait,
  ) {
    final request = portrait == null
        ? null
        : CharacterStudioMediaRequest(
            projectRootPath: widget.projectRootPath,
            assetId: portrait.assetId,
            projectRevision: widget.projectRevision,
          );
    return PokeMapPanel(
      key: ValueKey<String>('portrait-selected-${definition.id}'),
      expandChild: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      definition.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.pokeMapColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      portrait == null
                          ? 'Portrait non défini'
                          : portrait.assetId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.pokeMapColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              PokeMapBadge(
                label: portrait == null ? 'Non défini' : 'Défini',
                variant: portrait == null
                    ? PokeMapBadgeVariant.neutral
                    : PokeMapBadgeVariant.success,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: CharacterStudioMediaPreview(
              resolver: widget.mediaResolver,
              request: request,
              semanticLabel:
                  'Aperçu du portrait ${definition.displayName} de ${widget.character.name}',
              fit: portrait?.fitMode == CharacterPortraitFitMode.cover
                  ? BoxFit.cover
                  : BoxFit.contain,
              checkerboard: _checkerboard,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: PokeMapButton(
                  key: ValueKey<String>(
                    portrait == null
                        ? 'portrait-import-${definition.id}'
                        : 'portrait-replace-${definition.id}',
                  ),
                  onPressed: _locked
                      ? null
                      : () => _import(definition.id, portrait),
                  isLoading: _busy,
                  leading: Icon(
                    portrait == null
                        ? CupertinoIcons.add
                        : CupertinoIcons.arrow_2_circlepath,
                  ),
                  child: Text(
                    portrait == null ? 'Ajouter un PNG' : 'Remplacer',
                  ),
                ),
              ),
              if (portrait != null) ...[
                const SizedBox(width: 8),
                PokeMapButton(
                  key: ValueKey<String>('portrait-clear-${definition.id}'),
                  onPressed: _locked ? null : () => _clear(definition.id),
                  variant: PokeMapButtonVariant.danger,
                  size: PokeMapButtonSize.medium,
                  leading: const Icon(CupertinoIcons.trash),
                  child: const Text('Retirer'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: PokeMapButton(
                  key: const ValueKey<String>('portrait-fit-contain'),
                  onPressed: portrait == null || _locked
                      ? null
                      : () => _setFit(
                          definition.id,
                          CharacterPortraitFitMode.contain,
                        ),
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  isSelected:
                      portrait?.fitMode != CharacterPortraitFitMode.cover,
                  leading: const Icon(
                    CupertinoIcons.arrow_down_right_arrow_up_left,
                  ),
                  child: const Text('Ajuster'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: PokeMapButton(
                  key: const ValueKey<String>('portrait-fit-cover'),
                  onPressed: portrait == null || _locked
                      ? null
                      : () => _setFit(
                          definition.id,
                          CharacterPortraitFitMode.cover,
                        ),
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  isSelected:
                      portrait?.fitMode == CharacterPortraitFitMode.cover,
                  leading: const Icon(
                    CupertinoIcons.arrow_up_left_arrow_down_right,
                  ),
                  child: const Text('Remplir'),
                ),
              ),
              const SizedBox(width: 8),
              PokeMapButton(
                key: const ValueKey<String>('portrait-background-toggle'),
                onPressed: () => setState(() => _checkerboard = !_checkerboard),
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                isSelected: _checkerboard,
                leading: const Icon(CupertinoIcons.square_grid_2x2),
                child: Text(_checkerboard ? 'Damier' : 'Fond'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridPanel(
    List<CharacterPortraitStateDefinition> states,
    String selectedStateId,
  ) {
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expressions du personnage',
                      style: TextStyle(
                        color: context.pokeMapColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${widget.character.portraits.length} sur ${states.length} définies',
                      style: TextStyle(
                        color: context.pokeMapColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              PokeMapButton(
                key: const ValueKey<String>('portrait-manage-global-states'),
                onPressed: _locked ? null : widget.onManageGlobalStates,
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.slider_horizontal_3),
                child: const Text('États globaux'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 450 ? 3 : 2;
                return GridView.builder(
                  itemCount: states.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    mainAxisExtent: 168,
                  ),
                  itemBuilder: (context, index) {
                    final state = states[index];
                    final portrait = _portraitFor(state.id);
                    return PokeMapCard(
                      key: ValueKey<String>('portrait-state-card-${state.id}'),
                      selected: state.id == selectedStateId,
                      keyboardInteractive: true,
                      semanticLabel:
                          '${state.displayName}, ${portrait == null ? 'non défini' : 'défini'}',
                      onTap: () {
                        setState(() => _selectedStateId = state.id);
                        widget.onSelectionChanged?.call(state.id);
                      },
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _PortraitThumbnail(
                              resolver: widget.mediaResolver,
                              request: portrait == null
                                  ? null
                                  : CharacterStudioMediaRequest(
                                      projectRootPath: widget.projectRootPath,
                                      assetId: portrait.assetId,
                                      projectRevision: widget.projectRevision,
                                    ),
                              fit:
                                  portrait?.fitMode ==
                                      CharacterPortraitFitMode.cover
                                  ? BoxFit.cover
                                  : BoxFit.contain,
                              label: state.displayName,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            state.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.pokeMapColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Align(
                            child: PokeMapBadge(
                              label: portrait == null ? 'Non défini' : 'Défini',
                              variant: portrait == null
                                  ? PokeMapBadgeVariant.neutral
                                  : PokeMapBadgeVariant.success,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  CharacterPortraitVariant? _portraitFor(String stateId) {
    return widget.character.portraits
        .where((portrait) => portrait.portraitStateId == stateId)
        .firstOrNull;
  }

  Future<void> _import(
    String stateId,
    CharacterPortraitVariant? portrait,
  ) async {
    await _run(
      () => widget.onImport(stateId),
      success: portrait == null ? 'Portrait importé' : 'Portrait remplacé',
      failure: 'Le portrait n’a pas pu être importé.',
    );
  }

  Future<void> _clear(String stateId) async {
    await _run(
      () => widget.onClear(stateId),
      success: 'Portrait retiré',
      failure: 'Le portrait n’a pas pu être retiré.',
    );
  }

  Future<void> _setFit(String stateId, CharacterPortraitFitMode fitMode) async {
    final portrait = _portraitFor(stateId);
    if (portrait == null || portrait.fitMode == fitMode) return;
    await _run(
      () => widget.onFitChanged(stateId, fitMode),
      success: 'Cadrage mis à jour',
      failure: 'Le cadrage n’a pas pu être modifié.',
    );
  }

  Future<void> _run(
    Future<bool> Function() operation, {
    required String success,
    required String failure,
  }) async {
    setState(() {
      _busy = true;
      _feedback = null;
    });
    try {
      final saved = await operation();
      if (!mounted) return;
      setState(() {
        _feedback = saved ? success : failure;
        _feedbackIsError = !saved;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _feedback = failure;
        _feedbackIsError = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _PortraitThumbnail extends StatelessWidget {
  const _PortraitThumbnail({
    required this.resolver,
    required this.request,
    required this.fit,
    required this.label,
  });

  final CharacterStudioMediaResolverContract resolver;
  final CharacterStudioMediaRequest? request;
  final BoxFit fit;
  final String label;

  @override
  Widget build(BuildContext context) {
    final currentRequest = request;
    return PokeMapMediaPreviewSurface(
      semanticLabel: 'Miniature $label',
      child: currentRequest == null
          ? Center(
              child: Icon(
                CupertinoIcons.nosign,
                color: context.pokeMapColors.textDisabled,
                size: 28,
              ),
            )
          : FutureBuilder<Uint8List>(
              future: resolver.resolve(currentRequest),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      color: context.pokeMapColors.warning,
                      size: 24,
                    ),
                  );
                }
                final bytes = snapshot.data;
                if (bytes == null) {
                  return Center(
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.pokeMapColors.brandPrimary,
                      ),
                    ),
                  );
                }
                return Image.memory(
                  bytes,
                  fit: fit,
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: false,
                );
              },
            ),
    );
  }
}
