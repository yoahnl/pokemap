import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/models/editor_workspace_mode.dart';
import '../../theme/theme.dart';

class StatusBar extends ConsumerStatefulWidget {
  const StatusBar({super.key});

  /// The standard height of the status bar.
  static const double defaultHeight = 48.0;

  @override
  ConsumerState<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends ConsumerState<StatusBar> {
  late DateTime _lastSaveTime;
  late String _lastSaveText;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _lastSaveTime = DateTime.now();
    _updateSaveText();
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() => _updateSaveText());
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _updateSaveText() {
    final diff = DateTime.now().difference(_lastSaveTime);
    if (diff.inMinutes < 1) {
      _lastSaveText = "Sauvegardé : à l'instant";
    } else {
      _lastSaveText = "Sauvegardé : il y a ${diff.inMinutes} min";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to transitions on isSaving to reset the last save timestamp.
    ref.listen<bool>(
      editorNotifierProvider.select((s) => s.isSaving),
      (prev, next) {
        if (prev == true && next == false) {
          setState(() {
            _lastSaveTime = DateTime.now();
            _updateSaveText();
          });
        }
      },
    );

    final state = ref.watch(editorNotifierProvider);
    final colors = context.pokeMapColors;
    final activeMap = state.activeMap;
    final isNarrativeOverview =
        state.workspaceMode == EditorWorkspaceMode.narrativeOverview;

    const pendingProjectSaveMessage =
        'Projet modifié en mémoire — sauvegardez le projet avec la disquette.';
    final hasError = state.errorMessage != null;
    final primaryMessage = hasError
        ? state.errorMessage!
        : state.isProjectDirty
            ? pendingProjectSaveMessage
            : state.statusMessage ?? 'Prêt';

    // Left status pill styling
    final pillBg = hasError
        ? colors.errorSoft
        : (state.isProjectDirty
            ? colors.warning.withValues(alpha: 0.15)
            : colors.brandPrimarySoft);
    final pillBorder = hasError
        ? colors.errorBorder
        : (state.isProjectDirty
            ? colors.warning.withValues(alpha: 0.4)
            : colors.brandPrimaryBorder);
    final pillText = hasError
        ? colors.error
        : (state.isProjectDirty
            ? colors.warning
            : colors.brandPrimary);
    final pillIcon = hasError
        ? CupertinoIcons.exclamationmark_triangle_fill
        : CupertinoIcons.sparkles;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1100;

        return Container(
          height: StatusBar.defaultHeight,
          decoration: BoxDecoration(
            color: colors.backgroundShell,
            border: Border(
              top: BorderSide(
                color: colors.divider,
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // 1. Status message pill
              Container(
                constraints: const BoxConstraints(maxWidth: 220),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: pillBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MacosIcon(
                      pillIcon,
                      size: 13,
                      color: pillText,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        primaryMessage,
                        style: TextStyle(
                          fontSize: 11,
                          color: pillText,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              if (isWide) ...[
                const SizedBox(width: 12),
                // 2. Sync state
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: state.isProjectDirty ? colors.warning : colors.success,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.isProjectDirty ? 'Non synchronisé' : 'Synchronisé',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                _verticalDivider(colors),
                // 3. Last save relative time
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MacosIcon(
                      CupertinoIcons.time,
                      size: 13,
                      color: colors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _lastSaveText,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                _verticalDivider(colors),
                // 4. Project status health
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasError
                            ? colors.error
                            : (state.isProjectDirty ? colors.warning : colors.success),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Projet : ${hasError ? 'Erreur' : (state.isProjectDirty ? 'Modifié' : 'Bon')}',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ],

              const Spacer(),

              // Right segments
              if (activeMap != null) ...[
                _rightSegment(
                  colors,
                  'Carte ${activeMap.id}',
                  CupertinoIcons.map,
                ),
                const SizedBox(width: 16),
                _rightSegment(
                  colors,
                  '${activeMap.size.width} x ${activeMap.size.height}',
                  CupertinoIcons.rectangle_grid_2x2,
                ),
                const SizedBox(width: 16),
              ],
              if (state.isProjectDirty) ...[
                _rightSegment(
                  colors,
                  'Projet non sauvegardé',
                  CupertinoIcons.floppy_disk,
                  key: const Key('status-bar-project-dirty-chip'),
                ),
                const SizedBox(width: 16),
              ],
              _rightSegment(
                colors,
                'Zoom ${(state.zoom * 100).toInt()} %',
                CupertinoIcons.search,
              ),
              if (isWide && !isNarrativeOverview) ...[
                const SizedBox(width: 16),
                _rightSegment(
                  colors,
                  'Locale : FR',
                  CupertinoIcons.globe,
                ),
                const SizedBox(width: 16),
                _rightSegment(
                  colors,
                  'v0.3.0',
                  CupertinoIcons.info,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _verticalDivider(PokeMapColorTokens colors) {
    return Container(
      height: 16,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: colors.divider.withValues(alpha: 0.5),
    );
  }

  Widget _rightSegment(
    PokeMapColorTokens colors,
    String label,
    IconData icon, {
    Key? key,
  }) {
    return Row(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        MacosIcon(
          icon,
          size: 13,
          color: colors.textMuted,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}
