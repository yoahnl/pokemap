import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import '../../theme/theme.dart';
import '../design_system/design_system.dart';

class MapInspectorEmptyState extends StatelessWidget {
  const MapInspectorEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;

    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header title
          Row(
            children: [
              Icon(
                CupertinoIcons.layers_fill,
                size: 15,
                color: colors.brandPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'CALQUES & SYSTÈMES DE CARTE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Dashed Box Container
          CustomPaint(
            painter: DashedBorderPainter(color: colors.borderSubtle, radius: 12),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surfaceSubtle.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Blue isometric stack icon
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: colors.brandPrimarySoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.brandPrimaryBorder,
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        CupertinoIcons.layers,
                        color: colors.brandPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ouvrez une carte pour voir ses calques et systèmes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Une fois une carte ouverte, vous pourrez :',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Capability List
                  _buildCapabilityItem(
                    context,
                    icon: CupertinoIcons.square_grid_2x2,
                    title: 'Gérer les calques de tuiles',
                    subtitle: 'Terrain, bâtiments et décors',
                  ),
                  const SizedBox(height: 14),
                  _buildCapabilityItem(
                    context,
                    icon: CupertinoIcons.person_2,
                    title: 'Placer des objets et PNJ',
                    subtitle: 'Interactions et événements',
                  ),
                  const SizedBox(height: 14),
                  _buildCapabilityItem(
                    context,
                    icon: CupertinoIcons.shield,
                    title: 'Définir les collisions',
                    subtitle: 'Zones de marche et obstacles',
                  ),
                  const SizedBox(height: 14),
                  _buildCapabilityItem(
                    context,
                    icon: CupertinoIcons.flag,
                    title: 'Créer des événements',
                    subtitle: 'Scripts et déclencheurs',
                  ),
                  const SizedBox(height: 14),
                  _buildCapabilityItem(
                    context,
                    icon: CupertinoIcons.cloud_sun,
                    title: "Ajuster l'ambiance",
                    subtitle: 'Lumière, météo et sons',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Récents Section
          Row(
            children: [
              Icon(
                CupertinoIcons.time,
                size: 13,
                color: colors.brandPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'RÉCENTS',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          PokeMapCard(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Aucune carte récente.\nOuvrez une carte pour les voir ici.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Astuces Section
          Row(
            children: [
              Icon(
                CupertinoIcons.lightbulb,
                size: 13,
                color: colors.brandPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'ASTUCES',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          PokeMapCard(
            padding: const EdgeInsets.all(12),
            child: Text(
              "Utilisez le sélecteur d'outils en haut pour basculer entre les modes.\nLe zoom et la grille vous aideront à placer vos éléments avec précision.",
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final colors = context.pokeMapColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: colors.surfaceSubtle,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colors.borderSubtle,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: colors.brandPrimary,
            size: 14,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double radius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 4.0,
    this.dash = 5.0,
    this.radius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    // Custom dash path computation
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = math.min(dash, metric.length - distance);
        canvas.drawPath(
          metric.extractPath(distance, distance + len),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
