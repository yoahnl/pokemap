import 'package:flutter/material.dart';

@immutable
final class AveluneTypographyTokens
    extends ThemeExtension<AveluneTypographyTokens> {
  const AveluneTypographyTokens({
    required this.display,
    required this.title,
    required this.section,
    required this.gameTitle,
    required this.body,
    required this.metadata,
    required this.label,
    required this.caption,
  });

  static const AveluneTypographyTokens standard = AveluneTypographyTokens(
    display: TextStyle(
      fontSize: 32,
      height: 1.08,
      fontWeight: FontWeight.w600,
      letterSpacing: 4.8,
    ),
    title: TextStyle(
      fontSize: 24,
      height: 1.15,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
    section: TextStyle(
      fontSize: 13,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
    ),
    gameTitle: TextStyle(
      fontSize: 16,
      height: 1.16,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.15,
    ),
    body: TextStyle(
      fontSize: 15,
      height: 1.35,
      fontWeight: FontWeight.w400,
    ),
    metadata: TextStyle(
      fontSize: 13,
      height: 1.3,
      fontWeight: FontWeight.w500,
    ),
    label: TextStyle(
      fontSize: 12,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.7,
    ),
    caption: TextStyle(
      fontSize: 11,
      height: 1.25,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
    ),
  );

  final TextStyle display;
  final TextStyle title;
  final TextStyle section;
  final TextStyle gameTitle;
  final TextStyle body;
  final TextStyle metadata;
  final TextStyle label;
  final TextStyle caption;

  Map<String, TextStyle> get values => <String, TextStyle>{
        'display': display,
        'title': title,
        'section': section,
        'gameTitle': gameTitle,
        'body': body,
        'metadata': metadata,
        'label': label,
        'caption': caption,
      };

  TextTheme applyTo(TextTheme base) => base.copyWith(
        displaySmall: display,
        headlineSmall: title,
        titleMedium: gameTitle,
        bodyMedium: body,
        bodySmall: metadata,
        labelLarge: label,
        labelMedium: caption,
      );

  @override
  AveluneTypographyTokens copyWith({
    TextStyle? display,
    TextStyle? title,
    TextStyle? section,
    TextStyle? gameTitle,
    TextStyle? body,
    TextStyle? metadata,
    TextStyle? label,
    TextStyle? caption,
  }) =>
      AveluneTypographyTokens(
        display: display ?? this.display,
        title: title ?? this.title,
        section: section ?? this.section,
        gameTitle: gameTitle ?? this.gameTitle,
        body: body ?? this.body,
        metadata: metadata ?? this.metadata,
        label: label ?? this.label,
        caption: caption ?? this.caption,
      );

  @override
  AveluneTypographyTokens lerp(
    covariant AveluneTypographyTokens? other,
    double t,
  ) {
    if (other == null || t <= 0) return this;
    if (t >= 1) return other;
    return AveluneTypographyTokens(
      display: TextStyle.lerp(display, other.display, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      section: TextStyle.lerp(section, other.section, t)!,
      gameTitle: TextStyle.lerp(gameTitle, other.gameTitle, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      metadata: TextStyle.lerp(metadata, other.metadata, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
    );
  }
}
