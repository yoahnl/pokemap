import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../theme/theme.dart';

class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final colors = context.pokeMapColors;
    final activeMap = state.activeMap;
    const pendingProjectSaveMessage =
        'Projet modifié en mémoire — sauvegardez le projet avec la disquette.';
    final hasError = state.errorMessage != null;
    final primaryMessage = hasError
        ? state.errorMessage!
        : state.isProjectDirty
            ? pendingProjectSaveMessage
            : state.statusMessage ?? 'Prêt';

    final leadingTint = hasError ? colors.error : colors.brandPrimary;
    final icon = hasError
        ? CupertinoIcons.exclamationmark_triangle_fill
        : CupertinoIcons.sparkles;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 2, 22, 18),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceBase,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: colors.borderSubtle,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: hasError ? colors.errorSoft : colors.brandPrimarySoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasError ? colors.errorBorder : colors.brandPrimaryBorder,
                    width: 1.1,
                  ),
                ),
                alignment: Alignment.center,
                child: MacosIcon(
                  icon,
                  size: 14,
                  color: leadingTint,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  primaryMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: hasError ? colors.error : colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (activeMap != null) ...[
                _statusChip(
                  context,
                  'Carte ${activeMap.id}',
                  CupertinoIcons.map,
                  colors,
                ),
                const SizedBox(width: 8),
                _statusChip(
                  context,
                  '${activeMap.size.width} x ${activeMap.size.height}',
                  CupertinoIcons.rectangle_grid_2x2,
                  colors,
                ),
                const SizedBox(width: 8),
              ],
              if (state.isProjectDirty) ...[
                _statusChip(
                  context,
                  'Projet non sauvegardé',
                  CupertinoIcons.floppy_disk,
                  colors,
                  key: const Key('status-bar-project-dirty-chip'),
                ),
                const SizedBox(width: 8),
              ],
              _statusChip(
                context,
                'Zoom ${(state.zoom * 100).toInt()} %',
                CupertinoIcons.search,
                colors,
                isZoom: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _statusChip(
      BuildContext context, String label, IconData icon, PokeMapColorTokens colors,
      {Key? key, bool isZoom = false}) {
    return Container(
      key: key,
      padding: EdgeInsets.symmetric(
        horizontal: isZoom ? 8 : 10,
        vertical: isZoom ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: isZoom ? colors.surfaceSubtle.withValues(alpha: 0.5) : colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colors.borderSubtle.withValues(alpha: isZoom ? 0.5 : 1.0),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MacosIcon(
            icon,
            size: isZoom ? 11 : 12,
            color: isZoom ? colors.textMuted : colors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: isZoom ? 10 : 11,
              color: isZoom ? colors.textMuted : colors.textSecondary,
              fontWeight: isZoom ? FontWeight.w500 : FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
