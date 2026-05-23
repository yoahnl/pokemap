import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:map_core/map_core.dart';
import '../../theme/theme.dart';
import '../design_system/design_system.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_selectors.dart';
import 'top_toolbar/dialogs/top_toolbar_dialogs.dart';

class MapWorkspaceEmptyState extends ConsumerWidget {
  const MapWorkspaceEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.pokeMapColors;
    final project = ref.watch(editorProjectManifestProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final settings = project?.settings ?? const ProjectSettings();

    if (project == null) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(24),
          child: PokeMapPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
                      children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.brandPrimarySoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.brandPrimaryBorder, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    CupertinoIcons.folder,
                    color: colors.brandPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Aucun projet ouvert',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ouvrez un projet existant ou créez-en un nouveau pour commencer à travailler.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    PokeMapButton(
                      variant: PokeMapButtonVariant.primary,
                      onPressed: () => showTopToolbarNewProjectDialog(context, notifier),
                      child: const Text('Créer un projet'),
                    ),
                    PokeMapButton(
                      variant: PokeMapButtonVariant.secondary,
                      onPressed: () async {
                        final selectedDirectory = await FilePicker.platform.getDirectoryPath();
                        if (selectedDirectory != null) {
                          final manifestPath = p.join(selectedDirectory, 'project.json');
                          await notifier.loadProject(manifestPath);
                        }
                      },
                      child: const Text('Ouvrir un projet'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final maps = project.maps;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
                  const SizedBox(height: 20),
                  // Isometric Illustration
                  SizedBox(
                    width: 320,
                    height: 220,
                    child: CustomPaint(
                      painter: _IsometricLayersPainter(colors),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune carte ouverte',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ouvrez une carte existante ou créez-en une nouvelle pour commencer à éditer votre monde.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      PokeMapButton(
                        variant: PokeMapButtonVariant.primary,
                        leading: const Icon(CupertinoIcons.folder_open, size: 16),
                        onPressed: maps.isNotEmpty
                            ? () => _showMapsSelectionMenu(context, maps, notifier)
                            : null,
                        child: const Text('Ouvrir une carte'),
                      ),
                      PokeMapButton(
                        variant: PokeMapButtonVariant.secondary,
                        leading: const Icon(CupertinoIcons.plus, size: 16),
                        onPressed: () => showTopToolbarNewMapDialog(
                          context,
                          notifier,
                          defaultWidth: settings.defaultMapWidth,
                          defaultHeight: settings.defaultMapHeight,
                        ),
                        child: const Text('Créer une carte'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Sélectionnez une carte existante ou créez-en une nouvelle depuis ce projet.',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Recent Maps section header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.time,
                        size: 14,
                        color: colors.brandPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CARTES RÉCENTES',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (maps.isEmpty)
                    Text(
                      'Vos cartes récemment ouvertes apparaîtront ici.',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 12,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final map in maps)
                            PokeMapCard(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              onTap: () => notifier.loadMap(map.relativePath),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _roleIcon(map.role),
                                    size: 14,
                                    color: colors.brandPrimary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    map.name,
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
    );
  }

  IconData _roleIcon(MapRole role) {
    return switch (role) {
      MapRole.exterior => CupertinoIcons.sun_max,
      MapRole.interior => CupertinoIcons.house,
      MapRole.basement => CupertinoIcons.arrow_down_circle,
      MapRole.upper_floor => CupertinoIcons.arrow_up_circle,
      MapRole.connector => CupertinoIcons.link,
      MapRole.gate => CupertinoIcons.square_arrow_right,
      MapRole.section => CupertinoIcons.square_split_2x1,
      MapRole.room => CupertinoIcons.square_grid_2x2,
      MapRole.sub_area => CupertinoIcons.layers_alt,
    };
  }

  void _showMapsSelectionMenu(BuildContext context, List<ProjectMapEntry> maps, EditorNotifier notifier) {
    final colors = context.pokeMapColors;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Choisir une map à ouvrir'),
        actions: <CupertinoActionSheetAction>[
          for (final map in maps)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                notifier.loadMap(map.relativePath);
              },
              child: Text(
                map.name,
                style: TextStyle(color: colors.brandPrimary),
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Annuler'),
        ),
      ),
    );
  }
}

class _IsometricLayersPainter extends CustomPainter {
  final PokeMapColorTokens colors;

  _IsometricLayersPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    
    const w = 180.0;
    const h = 90.0;
    
    final dottedPaint = Paint()
      ..color = colors.brandPrimary.withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dyBottom = 30.0;
    const dyTop = -30.0;

    void drawDottedLine(double x, double yStart, double yEnd) {
      double y = yStart;
      const dash = 4.0;
      const gap = 3.0;
      while (y < yEnd) {
        canvas.drawLine(Offset(x, y), Offset(x, math.min(y + dash, yEnd)), dottedPaint);
        y += dash + gap;
      }
    }

    // Connect layer corners
    drawDottedLine(cx, cy + dyTop - h/2, cy + dyBottom - h/2); // Top corners
    drawDottedLine(cx + w/2, cy + dyTop, cy + dyBottom);       // Right corners
    drawDottedLine(cx, cy + dyTop + h/2, cy + dyBottom + h/2); // Bottom corners
    drawDottedLine(cx - w/2, cy + dyTop, cy + dyBottom);       // Left corners

    // 1. Bottom Layer (Collision / Ground layer representation)
    _drawLayer(canvas, cx, cy + dyBottom, w, h, colors.brandPrimary.withValues(alpha: 0.08), colors.brandPrimary.withValues(alpha: 0.35));

    // 2. Middle Layer (Tile/Terrain layers)
    _drawLayer(canvas, cx, cy, w, h, colors.brandPrimary.withValues(alpha: 0.12), colors.brandPrimary.withValues(alpha: 0.5));
    // Draw grid lines on middle layer
    final gridPath = Path();
    for (int i = -3; i <= 3; i++) {
      final offset = i * (w / 8);
      gridPath.moveTo(cx + offset - w/4, cy - h/4 + (offset * h / w));
      gridPath.lineTo(cx + offset + w/4, cy + h/4 + (offset * h / w));
      
      gridPath.moveTo(cx + offset + w/4, cy - h/4 - (offset * h / w));
      gridPath.lineTo(cx + offset - w/4, cy + h/4 - (offset * h / w));
    }
    canvas.drawPath(gridPath, Paint()
      ..color = colors.brandPrimary.withValues(alpha: 0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke);

    // 3. Top Layer (Entities / Spawns layer)
    _drawLayer(canvas, cx, cy + dyTop, w, h, colors.brandPrimary.withValues(alpha: 0.16), colors.brandPrimary);

    // Draw cursor selection on top layer
    const cursorSize = 18.0;
    final cursorCx = cx - 20;
    final cursorCy = cy + dyTop - 10;
    final cursorPath = Path()
      ..moveTo(cursorCx, cursorCy - cursorSize/2)
      ..lineTo(cursorCx + cursorSize, cursorCy)
      ..lineTo(cursorCx, cursorCy + cursorSize/2)
      ..lineTo(cursorCx - cursorSize, cursorCy)
      ..close();
    canvas.drawPath(cursorPath, Paint()
      ..color = colors.brandCyan.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill);
    canvas.drawPath(cursorPath, Paint()
      ..color = colors.brandCyan
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke);

    // Draw little isometric building on the middle layer
    final houseCx = cx + 20;
    final houseCy = cy - 5;
    final housePaint = Paint()
      ..color = colors.brandPrimary.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final houseStroke = Paint()
      ..color = colors.brandPrimary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
      
    const hw = 22.0;
    const hh = 15.0;
    const hDepth = 18.0;
    
    // Front face
    final frontFace = Path()
      ..moveTo(houseCx, houseCy)
      ..lineTo(houseCx + hw, houseCy + hw * h / w)
      ..lineTo(houseCx + hw, houseCy + hw * h / w - hh)
      ..lineTo(houseCx, houseCy - hh)
      ..close();
    canvas.drawPath(frontFace, housePaint);
    canvas.drawPath(frontFace, houseStroke);
    
    // Left face
    final leftFace = Path()
      ..moveTo(houseCx, houseCy)
      ..lineTo(houseCx - hDepth, houseCy + hDepth * h / w)
      ..lineTo(houseCx - hDepth, houseCy + hDepth * h / w - hh)
      ..lineTo(houseCx, houseCy - hh)
      ..close();
    canvas.drawPath(leftFace, housePaint);
    canvas.drawPath(leftFace, houseStroke);
    
    // Roof (triangular front gable + right plane)
    final roofPeakY = houseCy - hh - 8;
    final frontGable = Path()
      ..moveTo(houseCx - hDepth, houseCy + hDepth * h / w - hh)
      ..lineTo(houseCx, houseCy - hh)
      ..lineTo(houseCx - hDepth/2, roofPeakY + hDepth/2 * h / w)
      ..close();
    canvas.drawPath(frontGable, Paint()
      ..color = colors.brandCyan.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill);
    canvas.drawPath(frontGable, houseStroke);

    final roofRight = Path()
      ..moveTo(houseCx, houseCy - hh)
      ..lineTo(houseCx + hw, houseCy + hw * h / w - hh)
      ..lineTo(houseCx + hw - hDepth/2, roofPeakY + hw * h / w + hDepth/2 * h / w)
      ..lineTo(houseCx - hDepth/2, roofPeakY + hDepth/2 * h / w)
      ..close();
    canvas.drawPath(roofRight, Paint()
      ..color = colors.brandCyan.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill);
    canvas.drawPath(roofRight, houseStroke);
  }

  void _drawLayer(Canvas canvas, double cx, double cy, double w, double h, Color fill, Color border) {
    final path = Path()
      ..moveTo(cx, cy - h/2)
      ..lineTo(cx + w/2, cy)
      ..lineTo(cx, cy + h/2)
      ..lineTo(cx - w/2, cy)
      ..close();
      
    canvas.drawPath(path, Paint()..color = fill..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = border..strokeWidth = 1.2..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
