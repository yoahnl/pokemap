import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';

enum CharacterStudioSection { identity, portraits, animations }

enum _CharacterStudioSidePanel { library, inspector }

class CharacterStudioWorkspaceShell extends StatefulWidget {
  const CharacterStudioWorkspaceShell({
    super.key,
    required this.project,
    required this.library,
    required this.canvas,
    required this.inspector,
    required this.isSaving,
    this.statusMessage,
  });

  final ProjectManifest project;
  final Widget library;
  final Widget canvas;
  final Widget inspector;
  final bool isSaving;
  final String? statusMessage;

  @override
  State<CharacterStudioWorkspaceShell> createState() =>
      _CharacterStudioWorkspaceShellState();
}

class _CharacterStudioWorkspaceShellState
    extends State<CharacterStudioWorkspaceShell> {
  static const _wideBreakpoint = 1480.0;
  static const _mediumBreakpoint = 1040.0;

  _CharacterStudioSidePanel _mediumPanel = _CharacterStudioSidePanel.library;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.pokeMapColors.contentSurface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: PokeMapPageSurface(
          padding: EdgeInsets.zero,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isWide = width >= _wideBreakpoint;
              final isMedium = width >= _mediumBreakpoint && !isWide;
              return FocusTraversalGroup(
                policy: ReadingOrderTraversalPolicy(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CharacterStudioHeader(
                      project: widget.project,
                      statusMessage: widget.statusMessage,
                      isSaving: widget.isSaving,
                      showPanelControls: !isWide,
                      selectedPanel: isMedium ? _mediumPanel : null,
                      onLibraryPressed: () => isMedium
                          ? setState(() {
                              _mediumPanel = _CharacterStudioSidePanel.library;
                            })
                          : _openLibrarySheet(),
                      onInspectorPressed: () => isMedium
                          ? setState(() {
                              _mediumPanel =
                                  _CharacterStudioSidePanel.inspector;
                            })
                          : _openInspectorSheet(),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: context.pokeMapColors.divider,
                    ),
                    Expanded(
                      child: isWide
                          ? _buildWideLayout()
                          : isMedium
                          ? _buildMediumLayout()
                          : _buildCompactLayout(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      key: const ValueKey<String>('character-studio-layout-wide'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 272, child: _libraryRegion()),
        const SizedBox(width: 12),
        Expanded(child: _canvasRegion()),
        const SizedBox(width: 12),
        SizedBox(width: 310, child: _inspectorRegion()),
      ],
    );
  }

  Widget _buildMediumLayout() {
    final side = switch (_mediumPanel) {
      _CharacterStudioSidePanel.library => _libraryRegion(),
      _CharacterStudioSidePanel.inspector => _inspectorRegion(),
    };
    return Row(
      key: const ValueKey<String>('character-studio-layout-medium'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 272, child: side),
        const SizedBox(width: 12),
        Expanded(child: _canvasRegion()),
      ],
    );
  }

  Widget _buildCompactLayout() {
    return KeyedSubtree(
      key: const ValueKey<String>('character-studio-layout-compact'),
      child: _canvasRegion(),
    );
  }

  Widget _libraryRegion() {
    return _CharacterStudioRegion(
      key: const ValueKey<String>('character-studio-library-region'),
      semanticLabel: 'Bibliothèque des personnages',
      child: widget.library,
    );
  }

  Widget _canvasRegion() {
    return _CharacterStudioRegion(
      key: const ValueKey<String>('character-studio-canvas-region'),
      semanticLabel: 'Espace d’édition du personnage',
      child: widget.canvas,
    );
  }

  Widget _inspectorRegion() {
    return _CharacterStudioRegion(
      key: const ValueKey<String>('character-studio-inspector-region'),
      semanticLabel: 'Inspecteur Character Studio',
      child: widget.inspector,
    );
  }

  void _openLibrarySheet() {
    unawaited(
      showPokeMapDesktopSideSheet<void>(
        context: context,
        title: 'Personnages',
        semanticLabel: 'Panneau de la bibliothèque des personnages',
        builder: (_) => _libraryRegion(),
      ),
    );
  }

  void _openInspectorSheet() {
    unawaited(
      showPokeMapDesktopSideSheet<void>(
        context: context,
        title: 'Inspecteur',
        semanticLabel: 'Panneau inspecteur Character Studio',
        builder: (_) => _inspectorRegion(),
      ),
    );
  }
}

class _CharacterStudioRegion extends StatelessWidget {
  const _CharacterStudioRegion({
    super.key,
    required this.semanticLabel,
    required this.child,
  });

  final String semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: PokeMapPanel(
          padding: EdgeInsets.zero,
          borderRadius: 8,
          expandChild: true,
          child: child,
        ),
      ),
    );
  }
}

class _CharacterStudioHeader extends StatelessWidget {
  const _CharacterStudioHeader({
    required this.project,
    required this.statusMessage,
    required this.isSaving,
    required this.showPanelControls,
    required this.selectedPanel,
    required this.onLibraryPressed,
    required this.onInspectorPressed,
  });

  final ProjectManifest project;
  final String? statusMessage;
  final bool isSaving;
  final bool showPanelControls;
  final _CharacterStudioSidePanel? selectedPanel;
  final VoidCallback onLibraryPressed;
  final VoidCallback onInspectorPressed;

  @override
  Widget build(BuildContext context) {
    final readiness = analyzeCharacterStudioReadiness(manifest: project);
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const PokeMapIconTile(
          icon: CupertinoIcons.person_2_fill,
          tone: PokeMapTone.cinematic,
          size: 42,
          iconSize: 20,
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Character Studio',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.pokeMapColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Personnages, portraits et animations du projet',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.pokeMapColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final actions = Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        if (showPanelControls) ...[
          PokeMapIconButton(
            key: const ValueKey<String>('character-studio-library-toggle'),
            onPressed: onLibraryPressed,
            icon: const Icon(CupertinoIcons.person_2),
            tooltip: 'Afficher les personnages',
            semanticLabel: 'Afficher la bibliothèque des personnages',
            variant: PokeMapIconButtonVariant.soft,
            isSelected: selectedPanel == _CharacterStudioSidePanel.library,
          ),
          PokeMapIconButton(
            key: const ValueKey<String>('character-studio-inspector-toggle'),
            onPressed: onInspectorPressed,
            icon: const Icon(CupertinoIcons.slider_horizontal_3),
            tooltip: 'Afficher l’inspecteur',
            semanticLabel: 'Afficher l’inspecteur Character Studio',
            variant: PokeMapIconButtonVariant.soft,
            isSelected: selectedPanel == _CharacterStudioSidePanel.inspector,
          ),
        ],
        PokeMapBadge(
          label: readiness.isReady
              ? 'Prêt pour le runtime'
              : '${readiness.diagnostics.length} points à corriger',
          variant: readiness.isReady
              ? PokeMapBadgeVariant.success
              : PokeMapBadgeVariant.warning,
          icon: Icon(
            readiness.isReady
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.exclamationmark_triangle_fill,
          ),
        ),
        PokeMapBadge(
          label: isSaving
              ? 'Sauvegarde…'
              : statusMessage ?? 'Sauvegardé automatiquement',
          variant: isSaving
              ? PokeMapBadgeVariant.info
              : PokeMapBadgeVariant.neutral,
          icon: Icon(
            isSaving
                ? CupertinoIcons.arrow_2_circlepath
                : CupertinoIcons.checkmark_alt_circle,
          ),
        ),
      ],
    );

    return Semantics(
      key: const ValueKey<String>('character-studio-header'),
      container: true,
      label: 'En-tête du Character Studio',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 900) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  title,
                  const SizedBox(height: 10),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: title),
                const SizedBox(width: 16),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class CharacterStudioCanvasFrame extends StatelessWidget {
  const CharacterStudioCanvasFrame({
    super.key,
    required this.characterName,
    required this.characterId,
    required this.tags,
    required this.activeSection,
    required this.onSectionChanged,
    required this.child,
  });

  final String? characterName;
  final String? characterId;
  final List<String> tags;
  final CharacterStudioSection activeSection;
  final ValueChanged<CharacterStudioSection> onSectionChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              const PokeMapIconTile(
                icon: CupertinoIcons.person_crop_circle,
                tone: PokeMapTone.cinematic,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      characterName ?? 'Aucun personnage sélectionné',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.pokeMapColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (characterId != null)
                      Text(
                        characterId!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.pokeMapColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              for (final tag in tags.take(2)) ...[
                const SizedBox(width: 6),
                PokeMapBadge(label: tag),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tab(
                key: const ValueKey<String>('character-studio-tab-identity'),
                label: 'Identité',
                icon: CupertinoIcons.person,
                section: CharacterStudioSection.identity,
              ),
              _tab(
                key: const ValueKey<String>('character-studio-tab-portraits'),
                label: 'Portraits',
                icon: CupertinoIcons.photo,
                section: CharacterStudioSection.portraits,
              ),
              _tab(
                key: const ValueKey<String>('character-studio-tab-animations'),
                label: 'Animations',
                icon: CupertinoIcons.play_rectangle,
                section: CharacterStudioSection.animations,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Divider(height: 1, color: context.pokeMapColors.divider),
        Expanded(child: child),
      ],
    );
  }

  Widget _tab({
    required Key key,
    required String label,
    required IconData icon,
    required CharacterStudioSection section,
  }) {
    return PokeMapButton(
      key: key,
      onPressed: () => onSectionChanged(section),
      variant: PokeMapButtonVariant.secondary,
      size: PokeMapButtonSize.small,
      leading: Icon(icon),
      isSelected: activeSection == section,
      semanticLabel: 'Onglet $label',
      child: Text(label),
    );
  }
}
