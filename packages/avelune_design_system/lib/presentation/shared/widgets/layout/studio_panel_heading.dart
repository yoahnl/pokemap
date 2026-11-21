import 'package:flutter/material.dart';

import '../../../theme/studio_tokens.dart';
import '../typography/studio_text.dart';

class StudioPanelHeading extends StatelessWidget {
  const StudioPanelHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
  }) : titleKey = null,
       descriptionGap = 0,
       _inspector = false;

  const StudioPanelHeading.inspector({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.titleKey,
    this.descriptionGap = 0,
  }) : _inspector = true;

  final String eyebrow;
  final String title;
  final String description;
  final Key? titleKey;
  final double descriptionGap;
  final bool _inspector;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final titleStyle = _inspector ? text.titleSmall : text.titleMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudioEyebrow(eyebrow),
        SizedBox(height: _inspector ? StudioSpacing.m : StudioSpacing.xs),
        Text(
          title,
          key: titleKey,
          style: titleStyle?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (descriptionGap > 0) SizedBox(height: descriptionGap),
        StudioCaption(description),
      ],
    );
  }
}
