import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../application/runtime_map_bundle.dart';

/// Une **zone d’occlusion** (toit / couronne) pour **un** [MapPlacedElement] :
/// redessine uniquement les pixels marqués dans [ElementCollisionProfile.occlusionMask]
/// **par-dessus** le joueur lorsque la priorité Flame le permet.
///
/// ## Rôle produit
/// - **Ne** gère **pas** la collision (voir masque collision / gameplay).
/// - Sert uniquement à l’effet « passer derrière » la partie haute d’un bâtiment.
///
/// ## Priorité de dessin
/// `priority ≈ 1000 + bas_du_sprite_en_pixels_monde` pour rester aligné avec
/// [OverworldActorComponent.depthSortY] / le joueur (`1000 + footY`).
///
/// ## Limites (honnêtes)
/// - La **base** du bâtiment reste peinte dans [MapLayersComponent] (priorité 0) :
///   tant qu’on ne duplique pas le rendu « base » en couche Y-sortée, le joueur
///   peut recouvrir la base quand il est au sud — comportement classique acceptable
///   pour une première itération ; la suite est documentée dans le rapport produit.
class PlacedElementOcclusionPatchComponent extends PositionComponent {
  PlacedElementOcclusionPatchComponent({
    required this.bundle,
    required this.instance,
    required this.element,
    required this.tileImage,
    required Vector2 mapOriginPx,
  })  : _mapOriginPx = mapOriginPx.clone(),
        super(
          anchor: Anchor.topLeft,
          position: _computeTopLeft(
            bundle: bundle,
            instance: instance,
            element: element,
            mapOriginPx: mapOriginPx,
          ),
          size: _computeSize(
            bundle: bundle,
            element: element,
          ),
        ) {
    final mask = element.collisionProfile?.occlusionMask;
    final tw = bundle.manifest.settings.tileWidth;
    final th = bundle.manifest.settings.tileHeight;
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    if (mask != null && tw > 0 && th > 0) {
      final sy = ch / th;
      final bottomWorld =
          mapOriginPx.y + instance.pos.y * ch + mask.heightPx * sy;
      priority = (1000 + bottomWorld).round().clamp(0, 2000000);
    } else {
      priority = -1;
    }
  }

  final RuntimeMapBundle bundle;
  final MapPlacedElement instance;
  final ProjectElementEntry element;
  final ui.Image tileImage;
  final Vector2 _mapOriginPx;

  static Vector2 _computeTopLeft({
    required RuntimeMapBundle bundle,
    required MapPlacedElement instance,
    required ProjectElementEntry element,
    required Vector2 mapOriginPx,
  }) {
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    return Vector2(
      mapOriginPx.x + instance.pos.x * cw,
      mapOriginPx.y + instance.pos.y * ch,
    );
  }

  static Vector2 _computeSize({
    required RuntimeMapBundle bundle,
    required ProjectElementEntry element,
  }) {
    final mask = element.collisionProfile?.occlusionMask;
    final tw = bundle.manifest.settings.tileWidth;
    final th = bundle.manifest.settings.tileHeight;
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    if (mask == null || tw <= 0 || th <= 0) {
      return Vector2.zero();
    }
    final sx = cw / tw;
    final sy = ch / th;
    return Vector2(mask.widthPx * sx, mask.heightPx * sy);
  }

  @override
  void render(Canvas canvas) {
    final profile = element.collisionProfile;
    final mask = profile?.occlusionMask;
    if (mask == null) {
      return;
    }
    List<bool> pixels;
    try {
      pixels = ElementCollisionMaskCodec.decodePackedBits(
        widthPx: mask.widthPx,
        heightPx: mask.heightPx,
        dataBase64: mask.dataBase64,
      );
    } catch (_) {
      return;
    }
    final frame = element.frames.primaryFrame;
    final tw = bundle.manifest.settings.tileWidth;
    final th = bundle.manifest.settings.tileHeight;
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    if (tw <= 0 || th <= 0) {
      return;
    }
    final scaleX = cw / tw;
    final scaleY = ch / th;
    final srcLeft = frame.source.x * tw;
    final srcTop = frame.source.y * th;
    final paint = Paint()..filterQuality = FilterQuality.none;
    for (var py = 0; py < mask.heightPx; py++) {
      for (var px = 0; px < mask.widthPx; px++) {
        final idx = py * mask.widthPx + px;
        if (idx < 0 || idx >= pixels.length || !pixels[idx]) {
          continue;
        }
        final ix = srcLeft + px;
        final iy = srcTop + py;
        if (ix < 0 ||
            iy < 0 ||
            ix >= tileImage.width ||
            iy >= tileImage.height) {
          continue;
        }
        final src = Rect.fromLTWH(ix.toDouble(), iy.toDouble(), 1, 1);
        final dst = Rect.fromLTWH(
          px * scaleX,
          py * scaleY,
          scaleX,
          scaleY,
        );
        canvas.drawImageRect(tileImage, src, dst, paint);
      }
    }
  }
}
