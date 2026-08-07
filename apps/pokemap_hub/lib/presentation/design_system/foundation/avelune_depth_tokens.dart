import 'package:flutter/material.dart';

import 'avelune_color_tokens.dart';

@immutable
final class AveluneDepthTokens extends ThemeExtension<AveluneDepthTokens> {
  const AveluneDepthTokens({
    required this.ambient,
    required this.contact,
    required this.inset,
    required this.restingObject,
    required this.floatingObject,
    required this.selectedGlow,
  });

  factory AveluneDepthTokens.fromColors(AveluneColors colors) =>
      AveluneDepthTokens(
        ambient: <BoxShadow>[
          BoxShadow(
            color: colors.canvas.withValues(alpha: 0.42),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        contact: <BoxShadow>[
          BoxShadow(
            color: colors.canvas.withValues(alpha: 0.82),
            blurRadius: 8,
            spreadRadius: -2,
            offset: const Offset(0, 5),
          ),
        ],
        inset: <BoxShadow>[
          BoxShadow(
            color: colors.canvas.withValues(alpha: 0.76),
            blurRadius: 7,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
        restingObject: <BoxShadow>[
          BoxShadow(
            color: colors.canvas.withValues(alpha: 0.68),
            blurRadius: 12,
            spreadRadius: -3,
            offset: const Offset(0, 7),
          ),
        ],
        floatingObject: <BoxShadow>[
          BoxShadow(
            color: colors.canvas.withValues(alpha: 0.72),
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: colors.glow.withValues(alpha: 0.28),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
        selectedGlow: <BoxShadow>[
          BoxShadow(
            color: colors.glow.withValues(alpha: 0.48),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      );

  final List<BoxShadow> ambient;
  final List<BoxShadow> contact;
  final List<BoxShadow> inset;
  final List<BoxShadow> restingObject;
  final List<BoxShadow> floatingObject;
  final List<BoxShadow> selectedGlow;

  Map<String, List<BoxShadow>> get values => <String, List<BoxShadow>>{
        'ambient': ambient,
        'contact': contact,
        'inset': inset,
        'restingObject': restingObject,
        'floatingObject': floatingObject,
        'selectedGlow': selectedGlow,
      };

  @override
  AveluneDepthTokens copyWith({
    List<BoxShadow>? ambient,
    List<BoxShadow>? contact,
    List<BoxShadow>? inset,
    List<BoxShadow>? restingObject,
    List<BoxShadow>? floatingObject,
    List<BoxShadow>? selectedGlow,
  }) =>
      AveluneDepthTokens(
        ambient: ambient ?? this.ambient,
        contact: contact ?? this.contact,
        inset: inset ?? this.inset,
        restingObject: restingObject ?? this.restingObject,
        floatingObject: floatingObject ?? this.floatingObject,
        selectedGlow: selectedGlow ?? this.selectedGlow,
      );

  @override
  AveluneDepthTokens lerp(
    covariant AveluneDepthTokens? other,
    double t,
  ) {
    if (other == null || t <= 0) return this;
    if (t >= 1) return other;
    return AveluneDepthTokens(
      ambient: BoxShadow.lerpList(ambient, other.ambient, t)!,
      contact: BoxShadow.lerpList(contact, other.contact, t)!,
      inset: BoxShadow.lerpList(inset, other.inset, t)!,
      restingObject: BoxShadow.lerpList(restingObject, other.restingObject, t)!,
      floatingObject:
          BoxShadow.lerpList(floatingObject, other.floatingObject, t)!,
      selectedGlow: BoxShadow.lerpList(selectedGlow, other.selectedGlow, t)!,
    );
  }
}
