import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';

const Color _accent = Color(0xFF2DD4BF);

/// Liste lisible des animations Surface déjà présentes dans le catalogue.
///
/// Le panneau ne génère rien : il rend visible le résultat des opérations
/// d’auteur existantes pour que l’utilisateur sache quand passer aux surfaces
/// peignables.
class SurfaceStudioDetectedAnimationsPanel extends StatelessWidget {
  const SurfaceStudioDetectedAnimationsPanel({
    super.key,
    required this.readModel,
  });

  final SurfaceStudioReadModel readModel;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final animations = readModel.animations;

    return _PanelFrame(
      key: const ValueKey('surface_studio_detected_animations_panel'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Animations détectées',
            style: TextStyle(
              color: label,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            animations.isEmpty
                ? 'Aucune animation générée'
                : 'Aperçu des animations trouvées dans l’atlas source.',
            style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 10),
          if (animations.isEmpty)
            Text(
              'Mappez les colonnes puis générez les animations.',
              style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
            )
          else
            for (var i = 0; i < animations.length; i++) ...[
              _AnimationRow(index: i + 1, row: animations[i]),
              if (i != animations.length - 1) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _AnimationRow extends StatelessWidget {
  const _AnimationRow({
    required this.index,
    required this.row,
  });

  final int index;
  final SurfaceStudioAnimationReadModel row;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$index. ${row.name}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: label,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _TinyBadge('${row.frameCount} frame(s)'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            row.referencedAtlasIds.isEmpty
                ? 'Atlas source non renseigné'
                : 'Atlas lié : ${row.referencedAtlasIds.join(', ')}',
            style: TextStyle(
              color: subtle.withValues(alpha: 0.92),
              fontSize: 10.5,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _accent,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PanelFrame extends StatelessWidget {
  const _PanelFrame({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: child,
    );
  }
}
